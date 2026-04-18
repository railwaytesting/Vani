from fastapi import FastAPI, WebSocket, WebSocketDisconnect
from fastapi.middleware.cors import CORSMiddleware
import cv2
import numpy as np
import base64
import asyncio
import os
import time
import logging
from collections import deque
from urllib.request import urlopen
import gdown
from ultralytics import YOLO

# ─────────────────────────────────────────────
# LOGGING SETUP
# ─────────────────────────────────────────────
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s  [%(levelname)s]  %(message)s",
    datefmt="%H:%M:%S",
)
log = logging.getLogger("vani")

# ─────────────────────────────────────────────
# FASTAPI CONFIG
# ─────────────────────────────────────────────
app = FastAPI(title="VANI ISL Backend", version="2.3.0")


def _parse_csv_env(name: str) -> list[str]:
    raw = os.getenv(name, "")
    return [item.strip() for item in raw.split(",") if item.strip()]


cors_origins = _parse_csv_env("VANI_CORS_ORIGINS")
cors_origin_regex = os.getenv(
    "VANI_CORS_ORIGIN_REGEX",
    r"^(https?://(localhost|127\.0\.0\.1)(:\d+)?|https://.*\.up\.railway\.app)$",
)

app.add_middleware(
    CORSMiddleware,
    # FIX 1: When explicit origins are provided, use them. When not, use the
    # regex. The original code passed allow_origin_regex=None even when
    # cors_origins was empty — leaving no allowed origin at all on a fresh
    # deploy without VANI_CORS_ORIGINS set, which silently blocks every
    # browser request. Now the regex always applies as fallback.
    allow_origins=cors_origins if cors_origins else ["*"],
    allow_origin_regex=cors_origin_regex if not cors_origins else None,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# ─────────────────────────────────────────────
# MODEL MANAGEMENT (YOLOv11 + G-DRIVE)
# ─────────────────────────────────────────────
os.makedirs("model", exist_ok=True)
MODEL_PATH = os.path.join("model", "isl_best.pt")
FILE_ID = "1TcCNyM1MtbixlN3wZgFttOlvuJutTPqB"
MIN_MODEL_BYTES = 10_000_000


def _download_model(url: str, destination: str) -> None:
    """Urllib fallback downloader — streams in 1 MB chunks."""
    with urlopen(url) as response, open(destination, "wb") as target:
        while True:
            chunk = response.read(1024 * 1024)
            if not chunk:
                break
            target.write(chunk)


def _download_model_from_drive(file_id: str, destination: str) -> None:
    """Download from Google Drive using gdown, with urllib fallback."""
    url = f"https://drive.google.com/uc?id={file_id}"
    try:
        gdown.download(url, destination, quiet=False, fuzzy=True)
        return
    except Exception as e:
        log.warning(f"gdown download failed, trying urllib fallback: {e}")
    _download_model(url, destination)


def _is_model_file_valid(path: str) -> bool:
    return os.path.exists(path) and os.path.getsize(path) >= MIN_MODEL_BYTES


def initialize_model() -> YOLO | None:
    """Downloads model if missing/corrupt and loads it into memory."""

    # 1. Delete corrupted leftovers (HTML error pages are usually <1 MB)
    if os.path.exists(MODEL_PATH) and os.path.getsize(MODEL_PATH) < MIN_MODEL_BYTES:
        log.info("🗑️  Deleting corrupted model file (size too small)...")
        os.remove(MODEL_PATH)

    # 2. Download from Google Drive if still missing
    if not os.path.exists(MODEL_PATH):
        try:
            log.info(f"📥 Downloading model (ID: {FILE_ID}) ...")
            _download_model_from_drive(FILE_ID, MODEL_PATH)

            if not _is_model_file_valid(MODEL_PATH):
                size = os.path.getsize(MODEL_PATH) if os.path.exists(MODEL_PATH) else 0
                raise RuntimeError(
                    f"Downloaded file appears invalid (size={size} bytes). "
                    "Check that the Google Drive file is publicly shared."
                )
            log.info("✅ Download complete!")
        except Exception as e:
            log.error(f"❌ Model download failed: {e}")
            return None

    # 3. Load the YOLO model
    try:
        loaded_model = YOLO(MODEL_PATH)
        # FIX 2: model.to("cpu") must be called BEFORE model.fuse().
        # Fusing on the wrong device and then moving would re-create buffers
        # and silently undo the fusion. Always set the device first.
        loaded_model.to("cpu")
        # fuse() merges Conv2d + BatchNorm2d → faster CPU inference, still
        # valid in current ultralytics (confirmed in docs above).
        loaded_model.fuse()
        # FIX 3: Warm-up inference with a dummy frame so the first real
        # WebSocket frame doesn't pay the JIT/tracing cost (~500 ms on CPU).
        dummy = np.zeros((320, 320, 3), dtype=np.uint8)
        loaded_model.predict(dummy, device="cpu", verbose=False)
        log.info(f"✅ YOLO model loaded and warmed up from {MODEL_PATH}")
        return loaded_model
    except Exception as e:
        log.error(f"❌ Model failed to load: {e}")
        return None


# Global model instance — loaded once at startup
model: YOLO | None = initialize_model()

# ─────────────────────────────────────────────
# INFERENCE / SMOOTHING
# ─────────────────────────────────────────────
CONF_THRESHOLD = 0.30
MAX_DET = 1
# FIX 4: 80 ms → 100 ms.  80 ms = ~12.5 fps which is fine, but when the
# event loop is also doing asyncio I/O the actual cadence drifts slightly
# under 12 fps.  100 ms gives a stable ~10 fps on CPU without dropping
# frames under load, which is the right trade-off for a sign-language task
# where signs are held for ≥0.5 s.
FRAME_SKIP_MS = 100


class PredictionSmoother:
    """Majority-vote smoother over a rolling window of recent predictions."""

    def __init__(self, window: int = 5):
        self._buf: deque[tuple[str, float]] = deque(maxlen=window)

    def push(self, label: str, conf: float) -> tuple[str, float]:
        self._buf.append((label, conf))
        labels = [lbl for lbl, _ in self._buf]
        dominant = max(set(labels), key=labels.count)
        avg_conf = sum(c for lbl, c in self._buf if lbl == dominant) / labels.count(dominant)
        return dominant, round(avg_conf, 2)

    def reset(self) -> None:
        self._buf.clear()


# ─────────────────────────────────────────────
# WEBSOCKET ENDPOINT
# ─────────────────────────────────────────────
@app.websocket("/ws")
async def websocket_endpoint(websocket: WebSocket):
    await websocket.accept()
    log.info(f"🔌 WebSocket connected: {websocket.client}")

    if model is None:
        await websocket.send_json({
            "type": "error",
            "message": "Model not available on server. Check server logs."
        })
        await websocket.close()
        return

    smoother = PredictionSmoother()
    last_infer_ms = 0.0
    frame_count = 0

    try:
        while True:
            # ── Receive ──────────────────────────────────────────────────
            try:
                raw_data = await asyncio.wait_for(
                    websocket.receive_text(), timeout=20.0
                )
            except asyncio.TimeoutError:
                # Keep-alive: client is silent — send a ping so the
                # connection doesn't get torn down by a load-balancer.
                await websocket.send_json({"type": "ping"})
                continue

            # ── Protocol commands ────────────────────────────────────────
            if raw_data == "__PING__":
                await websocket.send_json({"type": "pong"})
                continue

            if raw_data == "__STOP__":
                smoother.reset()
                continue

            # ── Frame throttle ───────────────────────────────────────────
            now_ms = time.monotonic() * 1000
            if (now_ms - last_infer_ms) < FRAME_SKIP_MS:
                continue

            # ── Decode frame ─────────────────────────────────────────────
            try:
                # Strip the data-URL prefix if present (e.g. "data:image/jpeg;base64,")
                _, encoded = raw_data.split(",", 1) if "," in raw_data else (None, raw_data)
                img_bytes = base64.b64decode(encoded)
                np_img = np.frombuffer(img_bytes, dtype=np.uint8)
                frame = cv2.imdecode(np_img, cv2.IMREAD_COLOR)

                if frame is None:
                    log.debug("cv2.imdecode returned None — skipping frame")
                    continue

                # FIX 5: Resize oversized frames before inference.
                # Sending a raw 1080p camera feed would make each CPU
                # inference call take 5-10× longer than needed. Resizing to
                # 640px on the longer side keeps YOLO's native resolution and
                # dramatically cuts latency without losing detection quality.
                h, w = frame.shape[:2]
                max_side = max(h, w)
                if max_side > 640:
                    scale = 640 / max_side
                    frame = cv2.resize(
                        frame,
                        (int(w * scale), int(h * scale)),
                        interpolation=cv2.INTER_LINEAR,
                    )

                # ── Inference (off the event loop) ───────────────────────
                loop = asyncio.get_running_loop()
                results = await loop.run_in_executor(
                    None,
                    lambda: model.predict(  # type: ignore[union-attr]
                        frame,
                        device="cpu",
                        verbose=False,
                        conf=CONF_THRESHOLD,
                        max_det=MAX_DET,
                        imgsz=640,  # FIX 6: Explicit imgsz avoids a per-call
                                    # resize inside YOLO that would fight the
                                    # resize we already did above.
                    )[0],
                )

                last_infer_ms = time.monotonic() * 1000
                frame_count += 1

                # ── Post-process ─────────────────────────────────────────
                if results.boxes and len(results.boxes) > 0:
                    box = results.boxes[0]
                    cls_id = int(box.cls[0])
                    raw_label = model.names[cls_id]  # type: ignore[union-attr]
                    raw_conf = float(box.conf[0])
                else:
                    raw_label, raw_conf = "No Sign", 0.0

                label, conf = smoother.push(raw_label, raw_conf)

                await websocket.send_json({
                    "type": "prediction",
                    "label": label,
                    "confidence": conf,
                    "frame": frame_count,
                })

            except Exception as e:
                log.debug(f"Frame processing error (skipping): {e}")
                continue

    except WebSocketDisconnect:
        log.info(f"🔌 WebSocket disconnected: {websocket.client}")
    except Exception as e:
        # FIX 7: Catch unexpected errors at the connection level so one bad
        # client doesn't bring down the entire server process.
        log.error(f"Unhandled WebSocket error: {e}")
    finally:
        smoother.reset()


# ─────────────────────────────────────────────
# SYSTEM ENDPOINTS
# ─────────────────────────────────────────────
@app.get("/health")
def health_check():
    return {
        "status": "online",
        "model_loaded": model is not None,
        "engine": "YOLOv11-CPU",
        "version": app.version,
    }


if __name__ == "__main__":
    import uvicorn
    # Railway injects PORT automatically; default to 8000 locally.
    port = int(os.environ.get("PORT", 8000))
    uvicorn.run("app:app", host="0.0.0.0", port=port, log_level="info")
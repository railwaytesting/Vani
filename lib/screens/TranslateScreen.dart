import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';

class TranslateScreen extends StatefulWidget {
  const TranslateScreen({super.key});

  @override
  State<TranslateScreen> createState() => _TranslateScreenState();
}

class _TranslateScreenState extends State<TranslateScreen> {
  bool isCameraOn = false;
  CameraController? _controller;
  List<CameraDescription>? _cameras;
  int _selectedCameraIndex = 0;

  @override
  void initState() {
    super.initState();
    _setupCameras();
    WidgetsBinding.instance.addPostFrameCallback((_) => _showInstructions());
  }

  Future<void> _setupCameras() async {
    try {
      _cameras = await availableCameras();
    } catch (e) {
      debugPrint("Error fetching cameras: $e");
    }
  }

  Future<void> _toggleCamera(bool value) async {
    if (value) {
      if (_cameras != null && _cameras!.isNotEmpty) {
        _controller = CameraController(
          _cameras![_selectedCameraIndex],
          ResolutionPreset.high,
          enableAudio: false,
        );

        try {
          await _controller!.initialize();
          setState(() => isCameraOn = true);
        } catch (e) {
          debugPrint("Camera error: $e");
        }
      }
    } else {
      await _controller?.dispose();
      setState(() {
        isCameraOn = false;
        _controller = null;
      });
    }
  }

  void _switchCamera() async {
    if (_cameras == null || _cameras!.length < 2) return;
    _selectedCameraIndex = (_selectedCameraIndex + 1) % _cameras!.length;
    if (isCameraOn) {
      await _toggleCamera(false);
      await _toggleCamera(true);
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  void _showInstructions() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const _InstructionDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bool isWeb = MediaQuery.of(context).size.width > 900;
    const primaryColor = Color(0xFF6366F1);

    return Scaffold(
      // BACKGROUND ADAPTS TO THEME
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, 
            color: isDark ? Colors.white : primaryColor, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        // MIRRORED HOMEPAGE APPBAR
        backgroundColor: (isDark ? Colors.black : Colors.white).withOpacity(0.1),
        elevation: 0,
        flexibleSpace: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
            child: Container(color: Colors.transparent),
          ),
        ),
        title: const Text("VANI CORE", 
          style: TextStyle(fontWeight: FontWeight.w900, color: primaryColor, letterSpacing: 3, fontSize: 18)),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          // Adaptive Background Glows
          Positioned(top: -100, left: -100, child: _BlurCircle(color: primaryColor.withOpacity(isDark ? 0.15 : 0.1))),
          Positioned(bottom: -150, right: -50, child: _BlurCircle(color: Colors.blue.withOpacity(isDark ? 0.12 : 0.08))),
          
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: isWeb ? _buildWebLayout(isDark) : _buildMobileLayout(isDark),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWebLayout(bool isDark) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(flex: 7, child: _videoCaptureSection(isDark)),
        const SizedBox(width: 30),
        Expanded(flex: 4, child: Column(
          children: [
            _currentDetectionSection(isDark),
            const SizedBox(height: 24),
            _translationPanel(isDark),
          ],
        )),
      ],
    );
  }

  Widget _buildMobileLayout(bool isDark) {
    return Column(
      children: [
        _videoCaptureSection(isDark),
        const SizedBox(height: 20),
        _currentDetectionSection(isDark),
        const SizedBox(height: 20),
        _translationPanel(isDark),
      ],
    );
  }

  Widget _videoCaptureSection(bool isDark) {
    return _GlassContainer(
      isDark: isDark,
      child: Column(
        children: [
          _buildHeader(isDark, Icons.sensors_rounded, "AI VISION STREAM", "Processing real-time ISL data"),
          const SizedBox(height: 15),
          Container(
            height: 440,
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                if (!isDark) BoxShadow(color: const Color(0xFF6366F1).withOpacity(0.15), blurRadius: 30, spreadRadius: -10)
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: Stack(
                children: [
                  Center(
                    child: isCameraOn && _controller != null && _controller!.value.isInitialized
                      ? CameraPreview(_controller!)
                      : _buildCameraPlaceholder(),
                  ),
                  if(isCameraOn) Positioned(top: 20, right: 20, child: _buildLiveBadge()),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildActionButton(
                isDark: isDark,
                onPressed: _switchCamera, 
                icon: Icons.flip_camera_android_rounded, 
                label: "Switch",
              ),
              const SizedBox(width: 20),
              _buildCameraToggle(isDark),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCameraPlaceholder() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withOpacity(0.05)),
          child: Icon(Icons.videocam_off_rounded, color: Colors.white.withOpacity(0.2), size: 60),
        ),
        const SizedBox(height: 15),
        Text("Camera Stream Offline", style: TextStyle(color: Colors.white.withOpacity(0.4), fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _buildLiveBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: Colors.redAccent, borderRadius: BorderRadius.circular(8)),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.circle, color: Colors.white, size: 8),
          SizedBox(width: 8),
          Text("LIVE", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _currentDetectionSection(bool isDark) {
    return _GlassContainer(
      isDark: isDark,
      gradient: LinearGradient(colors: [const Color(0xFF6366F1).withOpacity(0.1), Colors.transparent]),
      child: Column(
        children: [
          Text("REAL-TIME PREDICTION", 
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: isDark ? Colors.white54 : Colors.grey, letterSpacing: 1.5)),
          const SizedBox(height: 15),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 20),
            decoration: BoxDecoration(
              color: isDark ? Colors.black26 : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFF6366F1).withOpacity(0.1)),
            ),
            child: const Center(
              child: Text("Waiting...", 
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Color(0xFF6366F1), letterSpacing: -1)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _translationPanel(bool isDark) {
    return _GlassContainer(
      isDark: isDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("TRANSCRIPTION", 
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: isDark ? Colors.white54 : Colors.grey, letterSpacing: 1.5)),
          const SizedBox(height: 15),
          TextField(
            maxLines: 3,
            style: TextStyle(fontSize: 16, color: isDark ? Colors.white : Colors.black87),
            decoration: InputDecoration(
              hintText: "Captured text will appear here...",
              hintStyle: TextStyle(color: isDark ? Colors.white24 : Colors.grey),
              filled: true,
              fillColor: isDark ? Colors.black26 : const Color(0xFFF1F5F9).withOpacity(0.5),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(child: _buildGradientButton("Start Capturing", Icons.play_arrow_rounded)),
              const SizedBox(width: 12),
              _buildIconButton(isDark, Icons.delete_outline_rounded, Colors.redAccent),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(bool isDark, IconData icon, String title, String sub) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF6366F1), size: 24),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: isDark ? Colors.white : Colors.black87)),
            Text(sub, style: const TextStyle(color: Colors.grey, fontSize: 12)),
          ],
        ),
      ],
    );
  }

  Widget _buildGradientButton(String label, IconData icon) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF6366F1), Color(0xFF4F46E5)]),
        borderRadius: BorderRadius.circular(15),
      ),
      child: ElevatedButton.icon(
        onPressed: () {},
        icon: Icon(icon, color: Colors.white),
        label: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(vertical: 18),
        ),
      ),
    );
  }

  Widget _buildActionButton({required bool isDark, required VoidCallback onPressed, required IconData icon, required String label}) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
      style: OutlinedButton.styleFrom(
        foregroundColor: const Color(0xFF6366F1),
        side: const BorderSide(color: Color(0xFF6366F1), width: 1.5),
        padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 15),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildCameraToggle(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF6366F1).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(isCameraOn ? "ON" : "OFF", style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF6366F1), fontSize: 12)),
          Switch.adaptive(
            value: isCameraOn,
            activeColor: const Color(0xFF6366F1),
            onChanged: (v) => _toggleCamera(v),
          ),
        ],
      ),
    );
  }

  Widget _buildIconButton(bool isDark, IconData icon, Color color) {
    return Container(
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(15),
      ),
      child: IconButton(
        onPressed: () {},
        icon: Icon(icon, color: color),
        padding: const EdgeInsets.all(15),
      ),
    );
  }
}

// --- SHARED CLASSES ---

class _BlurCircle extends StatelessWidget {
  final Color color;
  const _BlurCircle({required this.color});
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 400, height: 400,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
      child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 100, sigmaY: 100), child: Container(color: Colors.transparent)),
    );
  }
}

class _GlassContainer extends StatelessWidget {
  final Widget child;
  final bool isDark;
  final Gradient? gradient;
  const _GlassContainer({required this.child, required this.isDark, this.gradient});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(30),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withOpacity(0.05) : Colors.white.withOpacity(0.6),
            borderRadius: BorderRadius.circular(30),
            gradient: gradient,
            border: Border.all(color: isDark ? Colors.white10 : Colors.white.withOpacity(0.4), width: 1.5),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(isDark ? 0.3 : 0.02), blurRadius: 20)
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

class _InstructionDialog extends StatelessWidget {
  const _InstructionDialog();
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const primary = Color(0xFF6366F1);
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
      child: AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white.withOpacity(0.9),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        title: const Column(
          children: [
            Icon(Icons.psychology_outlined, color: primary, size: 40),
            SizedBox(height: 10),
            Text("VANI CORE READY", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20)),
          ],
        ),
        content: const Text("Initialize the AI module by toggling the camera power. Ensure your hands are within the capture frame for real-time ISL translation.",
          textAlign: TextAlign.center, style: TextStyle(color: Colors.grey, fontSize: 14)),
        actions: [
          Center(
            child: TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("INITIALIZE MODULE", style: TextStyle(color: primary, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
            ),
          ),
        ],
      ),
    );
  }
}
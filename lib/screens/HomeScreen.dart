import 'dart:ui';
import 'package:flutter/material.dart';
import 'TranslateScreen.dart';

class HomeScreen extends StatefulWidget {
  final VoidCallback toggleTheme;
  const HomeScreen({super.key, required this.toggleTheme});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _statsVisible = false;
  final GlobalKey _statsKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_checkScroll);
  }

  void _checkScroll() {
    if (_statsVisible) return;
    final RenderObject? renderObject = _statsKey.currentContext?.findRenderObject();
    if (renderObject is RenderBox) {
      final position = renderObject.localToGlobal(Offset.zero).dy;
      final screenHeight = MediaQuery.of(context).size.height;
      if (position < screenHeight * 0.8) {
        setState(() => _statsVisible = true);
      }
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isWeb = MediaQuery.of(context).size.width > 900;
    final theme = Theme.of(context);

    return Scaffold(
      body: Stack(
        children: [
          Positioned(top: -100, left: -100, child: _BlurCircle(color: const Color(0xFF6366F1).withOpacity(0.12))),
          Positioned(bottom: -150, right: -50, child: _BlurCircle(color: Colors.blue.withOpacity(0.1))),
          
          SafeArea(
            child: SingleChildScrollView(
              controller: _scrollController,
              physics: const BouncingScrollPhysics(),
              child: Column(
                children: [
                  _buildNavbar(context),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: isWeb ? 100 : 24),
                    child: Column(
                      children: [
                        const SizedBox(height: 60),
                        _buildBadge(),
                        const SizedBox(height: 30),
                        _buildHeroSection(isWeb, theme, context),
                        const SizedBox(height: 100),
                        Container(key: _statsKey, child: _buildStatsBar(isWeb, _statsVisible)),
                        const SizedBox(height: 120),
                        _buildObjectivesSection(isWeb), // Updated with 6 items
                        const SizedBox(height: 100),
                        _buildSocialVision(context),
                        const SizedBox(height: 80),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavbar(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 25),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text("VANI", style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: Color(0xFF6366F1), letterSpacing: 1.8)),
          Row(
            children: [
              if (MediaQuery.of(context).size.width > 750) ...[
                const _NavLink(label: "Home", isActive: true),
                _NavLink(
                  label: "Translate", 
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const TranslateScreen())),
                ),
                const _NavLink(label: "Models"),
              ],
              const SizedBox(width: 20),
              IconButton(
                onPressed: widget.toggleTheme, 
                icon: Icon(isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded, size: 22)
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF6366F1).withOpacity(0.08),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: const Color(0xFF6366F1).withOpacity(0.15)),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.bolt_rounded, size: 16, color: Color(0xFF6366F1)),
          SizedBox(width: 8),
          Text("Vani Vision — 16k Dataset Trained", style: TextStyle(color: Color(0xFF6366F1), fontWeight: FontWeight.bold, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildHeroSection(bool isWeb, ThemeData theme, BuildContext context) {
    return Column(
      children: [
        RichText(
          textAlign: TextAlign.center,
          text: TextSpan(
            style: TextStyle(fontSize: isWeb ? 72 : 40, fontWeight: FontWeight.w900, color: theme.textTheme.bodyLarge?.color, height: 1.1, letterSpacing: -1),
            children: const [
              TextSpan(text: "Convert "),
              TextSpan(text: "Indian Sign Language ", style: TextStyle(color: Color(0xFF6366F1))),
              TextSpan(text: "To\nText In Real-Time"),
            ],
          ),
        ),
        const SizedBox(height: 30),
        const Text(
          "Empowering communication through on-device AI.\nRefined for unmatched accuracy in every gesture.",
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 19, color: Colors.grey, height: 1.6),
        ),
        const SizedBox(height: 50),
        ElevatedButton(
          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const TranslateScreen())),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF6366F1),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 45, vertical: 25),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          ),
          child: const Text("Get Started", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }

  Widget _buildStatsBar(bool isWeb, bool isVisible) {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: isWeb ? 120 : 40,
      runSpacing: 40,
      children: [
        _StatItem(label: "Deaf and Mute People in India", value: "63000000", isVisible: isVisible),
        _StatItem(label: "ISL Users", value: "8435000", isVisible: isVisible),
        _StatItem(label: "Professional Translators", value: "250", isVisible: isVisible),
      ],
    );
  }

  Widget _buildObjectivesSection(bool isWeb) {
    return Column(
      children: [
        const Text("Our Objectives", style: TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: Color(0xFF6366F1))),
        const SizedBox(height: 50),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: isWeb ? 3 : 1,
          mainAxisSpacing: 25,
          crossAxisSpacing: 25,
          childAspectRatio: isWeb ? 1.5 : 2.2, // Adjusted for content
          children: const [
            _ObjectiveCard(title: "Accessibility", desc: "Communication for all", icon: Icons.accessibility_new_rounded),
            _ObjectiveCard(title: "Bridging Gaps", desc: "Connecting communities", icon: Icons.loop_rounded),
            _ObjectiveCard(title: "Inclusivity", desc: "Digital world for everyone", icon: Icons.people_outline_rounded),
            _ObjectiveCard(title: "Privacy First", desc: "On-device processing only", icon: Icons.security_rounded),
            _ObjectiveCard(title: "Offline Sync", desc: "Work without active internet", icon: Icons.wifi_off_rounded),
            _ObjectiveCard(title: "Education", desc: "Learn ISL through AI feedback", icon: Icons.school_rounded),
          ],
        ),
      ],
    );
  }

  Widget _buildSocialVision(BuildContext context) {
    return GlassCard(
      child: Column(
        children: [
          const Icon(Icons.favorite_rounded, color: Color(0xFF6366F1), size: 30),
          const SizedBox(height: 20),
          const Text("Empowering Silence with Vani AI", 
            style: TextStyle(fontSize: 22, color: Color(0xFF6366F1), fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          const Text(
            "With only 1 translator for every 33,000 users in India, Vani provides a digital bridge for independent communication.",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 17, color: Colors.grey, height: 1.7),
          ),
        ],
      ),
    );
  }
}

// --- STATS COMPONENT REMAINS SAME ---
class _StatItem extends StatefulWidget {
  final String label, value;
  final bool isVisible;
  const _StatItem({required this.label, required this.value, required this.isVisible});

  @override
  State<_StatItem> createState() => _StatItemState();
}

class _StatItemState extends State<_StatItem> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 2));
    _animation = Tween<double>(begin: 0, end: double.parse(widget.value)).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutExpo),
    );
  }

  @override
  void didUpdateWidget(_StatItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isVisible && !oldWidget.isVisible) {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _formatNumber(int number) {
    return number.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},');
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Column(
          children: [
            Text(
              _formatNumber(_animation.value.toInt()),
              style: const TextStyle(fontSize: 42, fontWeight: FontWeight.w900, color: Color(0xFF6366F1), letterSpacing: -1),
            ),
            const SizedBox(height: 12),
            Text(widget.label, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.grey, fontSize: 15)),
          ],
        );
      },
    );
  }
}

// --- UPDATED NAVLINK WITH CALLBACK ---
class _NavLink extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback? onTap;
  const _NavLink({required this.label, this.isActive = false, this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        child: Text(
          label, 
          style: TextStyle(
            color: isActive ? const Color(0xFF6366F1) : (isDark ? Colors.white70 : Colors.grey[600]), 
            fontWeight: isActive ? FontWeight.w800 : FontWeight.w500, 
            fontSize: 15
          ),
        ),
      ),
    );
  }
}

// --- REST OF HELPERS (GlassCard, ObjectiveCard, BlurCircle) REMAIN SAME ---
class _ObjectiveCard extends StatelessWidget {
  final String title, desc;
  final IconData icon;
  const _ObjectiveCard({required this.title, required this.desc, required this.icon});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(25),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: const Color(0xFF6366F1), size: 28),
          const SizedBox(height: 15),
          Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(desc, style: const TextStyle(fontSize: 14, color: Colors.grey)),
        ],
      ),
    );
  }
}

class _BlurCircle extends StatelessWidget {
  final Color color;
  const _BlurCircle({required this.color});
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 500, height: 500,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
      child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 120, sigmaY: 120), child: Container(color: Colors.transparent)),
    );
  }
}

class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  const GlassCard({super.key, required this.child, this.padding = const EdgeInsets.all(40)});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withOpacity(0.03) : Colors.black.withOpacity(0.01),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: isDark ? Colors.white10 : const Color(0xFFF1F5F9)),
          ),
          child: child,
        ),
      ),
    );
  }
}
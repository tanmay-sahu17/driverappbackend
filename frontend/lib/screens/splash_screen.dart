import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import 'login_screen.dart';
import 'dashboard_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _busController;
  late AnimationController _fadeController;
  
  late Animation<double> _logoFade;
  late Animation<double> _logoScale;
  late Animation<Offset> _busPosition;
  late Animation<double> _busScale;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    
    // Initialize animation controllers with faster speeds
    _logoController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _busController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    // Initialize animations
    _logoFade = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _logoController,
      curve: Curves.easeOutCubic,
    ));

    _logoScale = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _logoController,
      curve: Curves.elasticOut,
    ));

    // Bus popup from center with bounce
    _busPosition = Tween<Offset>(
      begin: const Offset(0.0, 2.0), // Start from bottom
      end: const Offset(0.0, 0.0),   // End at center
    ).animate(CurvedAnimation(
      parent: _busController,
      curve: Curves.elasticOut,
    ));

    _busScale = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _busController,
      curve: Curves.elasticOut,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));

    // Start animations sequence
    _startAnimations();
    
    // Navigate after delay
    _navigateToNextScreen();
  }

  void _startAnimations() async {
    // Start background fade immediately
    _fadeController.forward();
    
    await Future.delayed(const Duration(milliseconds: 200));
    // Start logo animation
    _logoController.forward();
    
    await Future.delayed(const Duration(milliseconds: 400));
    // Start bus popup animation
    _busController.forward();
  }

  void _navigateToNextScreen() async {
    await Future.delayed(const Duration(milliseconds: 2800)); // Reduced total time
    
    if (mounted) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      
      Widget nextScreen;
      if (authProvider.isSignedIn) {
        nextScreen = const DashboardScreen();
      } else {
        nextScreen = const LoginScreen();
      }
      
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => nextScreen,
          transitionDuration: const Duration(milliseconds: 600),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(1.0, 0.0),
                  end: Offset.zero,
                ).animate(CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeInOut,
                )),
                child: child,
              ),
            );
          },
        ),
      );
    }
  }

  @override
  void dispose() {
    _logoController.dispose();
    _busController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      body: AnimatedBuilder(
        animation: _fadeAnimation,
        builder: (context, child) {
          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDarkMode
                    ? [
                        const Color(0xFF0D1B2A),
                        const Color(0xFF1B263B),
                        const Color(0xFF2A3F5F),
                        const Color(0xFF3F5F8A),
                      ]
                    : [
                        const Color(0xFF4A90E2),
                        const Color(0xFF5BA0F2),
                        const Color(0xFF7BB3F0),
                        const Color(0xFFA8D0F0),
                      ],
              ),
            ),
            child: Stack(
              children: [
                // Animated map background
                Positioned.fill(
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: CustomPaint(
                      painter: MapBackgroundPainter(
                        isDarkMode: isDarkMode,
                        animationValue: _fadeAnimation.value,
                      ),
                    ),
                  ),
                ),
                
                // Main content
                SafeArea(
                  child: Column(
                    children: [
                      // Top section with title only
                      Expanded(
                        flex: 3,
                        child: Center(
                          child: AnimatedBuilder(
                            animation: Listenable.merge([_logoFade, _logoScale]),
                            builder: (context, child) {
                              return FadeTransition(
                                opacity: _logoFade,
                                child: ScaleTransition(
                                  scale: _logoScale,
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      // App Title - Centered and Larger
                                      ShaderMask(
                                        shaderCallback: (bounds) => LinearGradient(
                                          colors: [
                                            Colors.white,
                                            Colors.white.withOpacity(0.8),
                                          ],
                                        ).createShader(bounds),
                                        child: const Text(
                                          'Track Bus',
                                          style: TextStyle(
                                            fontSize: 38,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                            letterSpacing: 2.2,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        'Navigate • Track • Connect',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w400,
                                          color: Colors.white.withOpacity(0.9),
                                          letterSpacing: 1.6,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      
                      // Middle section with animated bus - Clean Design
                      Expanded(
                        flex: 2,
                        child: Center(
                          child: AnimatedBuilder(
                            animation: Listenable.merge([_busPosition, _busScale]),
                            builder: (context, child) {
                              return SlideTransition(
                                position: _busPosition,
                                child: ScaleTransition(
                                  scale: _busScale,
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      // Bus Image - Clean Transparent Background
                                      Container(
                                        width: 200,
                                        height: 140,
                                        child: Image.asset(
                                          'assets/images/23108150-removebg-preview.png',
                                          width: 200,
                                          height: 140,
                                          fit: BoxFit.contain,
                                        ),
                                      ),
                                      
                                      const SizedBox(height: 25),
                                      
                                      // Text below bus - Clean Style
                                      Text(
                                        'Locate Your Bus',
                                        style: TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white.withOpacity(0.95),
                                          letterSpacing: 1.3,
                                          shadows: [
                                            Shadow(
                                              color: Colors.black.withOpacity(0.3),
                                              blurRadius: 8,
                                              offset: const Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      
                      // Bottom section with loading
                      Expanded(
                        flex: 1,
                        child: Center(
                          child: FadeTransition(
                            opacity: _fadeAnimation,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: 35,
                                  height: 35,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 3,
                                    valueColor: const AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                    backgroundColor: Colors.white.withOpacity(0.3),
                                  ),
                                ),
                                const SizedBox(height: 20),
                                Text(
                                  'Loading your journey...',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.white.withOpacity(0.8),
                                    letterSpacing: 1.0,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// Map background painter
class MapBackgroundPainter extends CustomPainter {
  final bool isDarkMode;
  final double animationValue;

  MapBackgroundPainter({
    required this.isDarkMode,
    required this.animationValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = (isDarkMode ? Colors.white : Colors.white)
          .withOpacity(0.1 * animationValue)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    // Draw grid lines to simulate map
    final gridSize = 50.0;
    
    // Vertical lines
    for (double x = 0; x < size.width; x += gridSize) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        paint,
      );
    }
    
    // Horizontal lines
    for (double y = 0; y < size.height; y += gridSize) {
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        paint,
      );
    }

    // Draw some map-like elements
    final elementPaint = Paint()
      ..color = (isDarkMode ? Colors.white : Colors.white)
          .withOpacity(0.05 * animationValue)
      ..style = PaintingStyle.fill;

    // Add some scattered rectangles to simulate buildings/roads
    final random = [
      Rect.fromLTWH(size.width * 0.2, size.height * 0.3, 40, 20),
      Rect.fromLTWH(size.width * 0.7, size.height * 0.6, 60, 30),
      Rect.fromLTWH(size.width * 0.1, size.height * 0.8, 30, 25),
      Rect.fromLTWH(size.width * 0.8, size.height * 0.2, 45, 35),
    ];

    for (final rect in random) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(4)),
        elementPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
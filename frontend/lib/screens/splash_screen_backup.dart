import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
  late AnimationController _textController;
  
  late Animation<double> _logoFade;
  late Animation<double> _logoScale;
  late Animation<Offset> _busPosition;
  late Animation<double> _busRotation;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _textSlide;

  @override
  void initState() {
    super.initState();
    
    // Initialize animation controllers with faster speeds
    _logoController = AnimationController(
      duration: const Duration(milliseconds: 1000), // Faster logo
      vsync: this,
    );
    
    _busController = AnimationController(
      duration: const Duration(milliseconds: 2000), // Faster bus animation
      vsync: this,
    );
    
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800), // Faster fade
      vsync: this,
    );
    
    _textController = AnimationController(
      duration: const Duration(milliseconds: 900), // Faster text
      vsync: this,
    );
      vsync: this,
    );

    // Initialize animations with better curves
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

    // Improved bus animation - popup from center with bounce
    _busPosition = Tween<Offset>(
      begin: const Offset(0.0, 1.5), // Start from bottom center
      end: const Offset(0.0, 0.0),   // End at center
    ).animate(CurvedAnimation(
      parent: _busController,
      curve: Curves.elasticOut, // Bouncy popup effect
    ));

    _busRotation = Tween<double>(
      begin: 0.2, // Start slightly tilted
      end: 0.0,   // End straight
    ).animate(CurvedAnimation(
      parent: _busController,
      curve: Curves.easeOutBack,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));

    _textSlide = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _textController,
      curve: Curves.easeOutBack,
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
    
    await Future.delayed(const Duration(milliseconds: 500));
    // Start text animation
    _textController.forward();
    
    await Future.delayed(const Duration(milliseconds: 300));
    // Start bus popup animation
    _busController.forward();
  }

  void _navigateToNextScreen() async {
    await Future.delayed(const Duration(milliseconds: 3200)); // Reduced total time
    
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
          transitionDuration: const Duration(milliseconds: 800),
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
    _textController.dispose();
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
                        const Color(0xFF0D1B2A), // Deep navy
                        const Color(0xFF1B263B), // Dark blue-gray
                        const Color(0xFF2A3F5F), // Medium blue
                        const Color(0xFF3F5F8A), // Light blue
                      ]
                    : [
                        const Color(0xFF4A90E2), // Sky blue
                        const Color(0xFF5BA0F2), // Light blue
                        const Color(0xFF7BB3F0), // Lighter blue
                        const Color(0xFFA8D0F0), // Very light blue
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
                      painter: AnimatedMapPainter(
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
                      // Top section with logo
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
                                      // App Logo Container
                                      Container(
                                        padding: const EdgeInsets.all(25),
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: Colors.white.withOpacity(0.15),
                                          border: Border.all(
                                            color: Colors.white.withOpacity(0.3),
                                            width: 2,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withOpacity(0.3),
                                              blurRadius: 20,
                                              offset: const Offset(0, 10),
                                            ),
                                          ],
                                        ),
                                        child: const Icon(
                                          Icons.location_on,
                                          size: 60,
                                          color: Colors.white,
                                        ),
                                      ),
                                      
                                      const SizedBox(height: 30),
                                      
                                      // App Title
                                      AnimatedBuilder(
                                        animation: _textSlide,
                                        builder: (context, child) {
                                          return SlideTransition(
                                            position: _textSlide,
                                            child: Column(
                                              children: [
                                                ShaderMask(
                                                  shaderCallback: (bounds) => LinearGradient(
                                                    colors: [
                                                      Colors.white,
                                                      Colors.white.withOpacity(0.8),
                                                    ],
                                                  ).createShader(bounds),
                                                  child: const Text(
                                                    'Driver Tracker',
                                                    style: TextStyle(
                                                      fontSize: 32,
                                                      fontWeight: FontWeight.bold,
                                                      color: Colors.white,
                                                      letterSpacing: 2.0,
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(height: 8),
                                                Text(
                                                  'Navigate • Track • Connect',
                                                  style: TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.w400,
                                                    color: Colors.white.withOpacity(0.9),
                                                    letterSpacing: 1.5,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      
                      // Middle section with animated bus - Improved design
                      Expanded(
                        flex: 2,
                        child: Center(
                          child: AnimatedBuilder(
                            animation: Listenable.merge([_busPosition, _busRotation, _fadeAnimation]),
                            builder: (context, child) {
                              return SlideTransition(
                                position: _busPosition,
                                child: Transform.rotate(
                                  angle: _busRotation.value,
                                  child: Container(
                                    padding: const EdgeInsets.all(20),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(25),
                                      border: Border.all(
                                        color: Colors.white.withOpacity(0.3),
                                        width: 2,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.3),
                                          blurRadius: 20,
                                          offset: const Offset(0, 10),
                                        ),
                                        BoxShadow(
                                          color: Colors.white.withOpacity(0.1),
                                          blurRadius: 15,
                                          offset: const Offset(0, -5),
                                        ),
                                      ],
                                    ),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        // Enhanced Bus Design
                                        Container(
                                          width: 180,
                                          height: 90,
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(15),
                                            gradient: LinearGradient(
                                              begin: Alignment.topLeft,
                                              end: Alignment.bottomRight,
                                              colors: [
                                                Colors.orange.withOpacity(0.8),
                                                Colors.deepOrange.withOpacity(0.9),
                                              ],
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.orange.withOpacity(0.3),
                                                blurRadius: 15,
                                                offset: const Offset(0, 5),
                                              ),
                                            ],
                                          ),
                                          child: Stack(
                                            children: [
                                              // Main bus body
                                              Positioned(
                                                bottom: 15,
                                                left: 15,
                                                right: 15,
                                                child: Container(
                                                  height: 50,
                                                  decoration: BoxDecoration(
                                                    gradient: LinearGradient(
                                                      begin: Alignment.topCenter,
                                                      end: Alignment.bottomCenter,
                                                      colors: [
                                                        Colors.yellow.shade400,
                                                        Colors.orange.shade400,
                                                      ],
                                                    ),
                                                    borderRadius: BorderRadius.circular(8),
                                                    border: Border.all(
                                                      color: Colors.orange.shade600,
                                                      width: 2,
                                                    ),
                                                    boxShadow: [
                                                      BoxShadow(
                                                        color: Colors.black.withOpacity(0.2),
                                                        blurRadius: 8,
                                                        offset: const Offset(0, 4),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                              // Roof
                                              Positioned(
                                                top: 8,
                                                left: 12,
                                                right: 12,
                                                child: Container(
                                                  height: 25,
                                                  decoration: BoxDecoration(
                                                    gradient: LinearGradient(
                                                      begin: Alignment.topCenter,
                                                      end: Alignment.bottomCenter,
                                                      colors: [
                                                        Colors.yellow.shade300,
                                                        Colors.yellow.shade400,
                                                      ],
                                                    ),
                                                    borderRadius: const BorderRadius.only(
                                                      topLeft: Radius.circular(12),
                                                      topRight: Radius.circular(12),
                                                      bottomLeft: Radius.circular(4),
                                                      bottomRight: Radius.circular(4),
                                                    ),
                                                    border: Border.all(
                                                      color: Colors.orange.shade600,
                                                      width: 2,
                                                    ),
                                                  ),
                                                  child: Center(
                                                    child: Container(
                                                      height: 3,
                                                      margin: const EdgeInsets.symmetric(horizontal: 8),
                                                      decoration: BoxDecoration(
                                                        color: Colors.orange.shade700,
                                                        borderRadius: BorderRadius.circular(2),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              // Windows
                                              Positioned(
                                                top: 35,
                                                left: 20,
                                                right: 20,
                                                child: Row(
                                                  children: [
                                                    // Window 1
                                                    Expanded(
                                                      child: Container(
                                                        height: 20,
                                                        margin: const EdgeInsets.only(right: 2),
                                                        decoration: BoxDecoration(
                                                          color: Colors.lightBlue.shade100,
                                                          borderRadius: BorderRadius.circular(3),
                                                          border: Border.all(
                                                            color: Colors.orange.shade600,
                                                            width: 2,
                                                          ),
                                                        ),
                                                        child: Container(
                                                          margin: const EdgeInsets.all(2),
                                                          decoration: BoxDecoration(
                                                            gradient: LinearGradient(
                                                              begin: Alignment.topLeft,
                                                              end: Alignment.bottomRight,
                                                              colors: [
                                                                Colors.lightBlue.shade50,
                                                                Colors.lightBlue.shade100,
                                                              ],
                                                            ),
                                                            borderRadius: BorderRadius.circular(1),
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                    // Window 2
                                                    Expanded(
                                                      child: Container(
                                                        height: 20,
                                                        margin: const EdgeInsets.symmetric(horizontal: 2),
                                                        decoration: BoxDecoration(
                                                          color: Colors.lightBlue.shade100,
                                                          borderRadius: BorderRadius.circular(3),
                                                          border: Border.all(
                                                            color: Colors.orange.shade600,
                                                            width: 2,
                                                          ),
                                                        ),
                                                        child: Container(
                                                          margin: const EdgeInsets.all(2),
                                                          decoration: BoxDecoration(
                                                            gradient: LinearGradient(
                                                              begin: Alignment.topLeft,
                                                              end: Alignment.bottomRight,
                                                              colors: [
                                                                Colors.lightBlue.shade50,
                                                                Colors.lightBlue.shade100,
                                                              ],
                                                            ),
                                                            borderRadius: BorderRadius.circular(1),
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                    // Window 3
                                                    Expanded(
                                                      child: Container(
                                                        height: 20,
                                                        margin: const EdgeInsets.symmetric(horizontal: 2),
                                                        decoration: BoxDecoration(
                                                          color: Colors.lightBlue.shade100,
                                                          borderRadius: BorderRadius.circular(3),
                                                          border: Border.all(
                                                            color: Colors.orange.shade600,
                                                            width: 2,
                                                          ),
                                                        ),
                                                        child: Container(
                                                          margin: const EdgeInsets.all(2),
                                                          decoration: BoxDecoration(
                                                            gradient: LinearGradient(
                                                              begin: Alignment.topLeft,
                                                              end: Alignment.bottomRight,
                                                              colors: [
                                                                Colors.lightBlue.shade50,
                                                                Colors.lightBlue.shade100,
                                                              ],
                                                            ),
                                                            borderRadius: BorderRadius.circular(1),
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                    // Window 4
                                                    Expanded(
                                                      child: Container(
                                                        height: 20,
                                                        margin: const EdgeInsets.only(left: 2),
                                                        decoration: BoxDecoration(
                                                          color: Colors.lightBlue.shade100,
                                                          borderRadius: BorderRadius.circular(3),
                                                          border: Border.all(
                                                            color: Colors.orange.shade600,
                                                            width: 2,
                                                          ),
                                                        ),
                                                        child: Container(
                                                          margin: const EdgeInsets.all(2),
                                                          decoration: BoxDecoration(
                                                            gradient: LinearGradient(
                                                              begin: Alignment.topLeft,
                                                              end: Alignment.bottomRight,
                                                              colors: [
                                                                Colors.lightBlue.shade50,
                                                                Colors.lightBlue.shade100,
                                                              ],
                                                            ),
                                                            borderRadius: BorderRadius.circular(1),
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              // Front lights
                                              Positioned(
                                                bottom: 25,
                                                right: 18,
                                                child: Container(
                                                  width: 8,
                                                  height: 8,
                                                  decoration: BoxDecoration(
                                                    color: Colors.lightBlue.shade300,
                                                    shape: BoxShape.circle,
                                                    border: Border.all(
                                                      color: Colors.blue.shade600,
                                                      width: 1,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              // Back lights
                                              Positioned(
                                                bottom: 25,
                                                left: 18,
                                                child: Container(
                                                  width: 8,
                                                  height: 8,
                                                  decoration: BoxDecoration(
                                                    color: Colors.red.shade300,
                                                    shape: BoxShape.circle,
                                                    border: Border.all(
                                                      color: Colors.red.shade600,
                                                      width: 1,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              // Front bumper
                                              Positioned(
                                                bottom: 15,
                                                right: 12,
                                                child: Container(
                                                  width: 6,
                                                  height: 15,
                                                  decoration: BoxDecoration(
                                                    color: Colors.grey.shade300,
                                                    borderRadius: const BorderRadius.only(
                                                      topRight: Radius.circular(8),
                                                      bottomRight: Radius.circular(8),
                                                    ),
                                                    border: Border.all(
                                                      color: Colors.grey.shade500,
                                                      width: 1,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              // Back bumper
                                              Positioned(
                                                bottom: 15,
                                                left: 12,
                                                child: Container(
                                                  width: 6,
                                                  height: 15,
                                                  decoration: BoxDecoration(
                                                    color: Colors.grey.shade300,
                                                    borderRadius: const BorderRadius.only(
                                                      topLeft: Radius.circular(8),
                                                      bottomLeft: Radius.circular(8),
                                                    ),
                                                    border: Border.all(
                                                      color: Colors.grey.shade500,
                                                      width: 1,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              // Front wheel
                                              Positioned(
                                                bottom: 0,
                                                right: 25,
                                                child: Container(
                                                  width: 30,
                                                  height: 30,
                                                  decoration: BoxDecoration(
                                                    color: Colors.brown.shade400,
                                                    shape: BoxShape.circle,
                                                    border: Border.all(
                                                      color: Colors.brown.shade600,
                                                      width: 3,
                                                    ),
                                                  ),
                                                  child: Center(
                                                    child: Container(
                                                      width: 15,
                                                      height: 15,
                                                      decoration: BoxDecoration(
                                                        color: Colors.grey.shade300,
                                                        shape: BoxShape.circle,
                                                        border: Border.all(
                                                          color: Colors.grey.shade500,
                                                          width: 2,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              // Back wheel
                                              Positioned(
                                                bottom: 0,
                                                left: 25,
                                                child: Container(
                                                  width: 30,
                                                  height: 30,
                                                  decoration: BoxDecoration(
                                                    color: Colors.brown.shade400,
                                                    shape: BoxShape.circle,
                                                    border: Border.all(
                                                      color: Colors.brown.shade600,
                                                      width: 3,
                                                    ),
                                                  ),
                                                  child: Center(
                                                    child: Container(
                                                      width: 15,
                                                      height: 15,
                                                      decoration: BoxDecoration(
                                                        color: Colors.grey.shade300,
                                                        shape: BoxShape.circle,
                                                        border: Border.all(
                                                          color: Colors.grey.shade500,
                                                          width: 2,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
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
                                  width: 30,
                                  height: 30,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 3,
                                    valueColor: const AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                    backgroundColor: Colors.white.withOpacity(0.3),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Loading your journey...',
                                  style: TextStyle(
                                    fontSize: 14,
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

// Enhanced map painter with animation
class AnimatedMapPainter extends CustomPainter {
  final bool isDarkMode;
  final double animationValue;

  AnimatedMapPainter({
    required this.isDarkMode,
    required this.animationValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final baseOpacity = isDarkMode ? 0.08 : 0.15;
    final animatedOpacity = baseOpacity * animationValue;
    
    final paint = Paint()
      ..color = Colors.white.withOpacity(animatedOpacity)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    // Map grid pattern
    final gridSize = 50.0;
    
    // Vertical roads
    for (double x = 0; x <= size.width; x += gridSize) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        paint,
      );
    }
    
    // Horizontal roads
    for (double y = 0; y <= size.height; y += gridSize) {
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        paint,
      );
    }

    // Animated highways
    final highwayPaint = Paint()
      ..color = Colors.white.withOpacity(animatedOpacity * 1.5)
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke;

    // Main highway (horizontal)
    canvas.drawLine(
      Offset(0, size.height * 0.6),
      Offset(size.width * animationValue, size.height * 0.6),
      highwayPaint,
    );

    // Secondary highway (diagonal)
    final diagonalLength = size.width * 1.4 * animationValue;
    final endX = diagonalLength * 0.7;
    final endY = size.height * 0.3 + (diagonalLength * 0.3);
    
    canvas.drawLine(
      Offset(0, size.height * 0.3),
      Offset(endX.clamp(0, size.width), endY.clamp(0, size.height)),
      highwayPaint,
    );

    // Intersection points
    final intersectionPaint = Paint()
      ..color = Colors.white.withOpacity(animatedOpacity * 2)
      ..style = PaintingStyle.fill;

    // Draw some intersection dots
    for (double x = gridSize; x < size.width; x += gridSize * 2) {
      for (double y = gridSize; y < size.height; y += gridSize * 2) {
        if (animationValue > 0.5) {
          canvas.drawCircle(
            Offset(x, y),
            2.0 * (animationValue - 0.5) * 2,
            intersectionPaint,
          );
        }
      }
    }

    // Route curves
    final routePaint = Paint()
      ..color = Colors.white.withOpacity(animatedOpacity * 0.8)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    final path = Path();
    path.moveTo(size.width * 0.1, size.height * 0.8);
    path.quadraticBezierTo(
      size.width * 0.5 * animationValue,
      size.height * 0.2,
      size.width * 0.9 * animationValue,
      size.height * 0.7,
    );
    canvas.drawPath(path, routePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
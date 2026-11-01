import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../config/app_localizations.dart';
import '../config/theme.dart';
import 'auth/role_selection_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with SingleTickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  late final AnimationController _animationController;
  late final Animation<double> _illustrationAnimation;
  late final Animation<double> _illustrationScale;
  late final Animation<double> _copyAnimation;

  // Data ya Huduma za FikaGo
  final List<Map<String, dynamic>> _onboardingData = [
    {
      "icon": Icons.fastfood,
      "title": "Food Delivery",
      "description": "Agiza chakula kipendacho kutoka migahawa bora Tanzania.",
      "color": FikaGoColors.sunYellow,
    },
    {
      "icon": Icons.local_shipping,
      "title": "Send Package",
      "description":
          "Send and receive packages, and get FikaGo orders delivered by motorcycle.",
      "color": FikaGoColors.forestGreen,
    },
    {
      "icon": Icons.shopping_bag,
      "title": "Grocery & More",
      "description":
          "Nunua mboga, dawa, na vitu vingine bila kuondoka nyumbani.",
      "color": FikaGoColors.lightGreen,
    },
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 850),
    );
    _illustrationAnimation = CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0, 0.72, curve: Curves.easeOutCubic),
    );
    _illustrationScale = Tween<double>(begin: 0.96, end: 1).animate(
      _illustrationAnimation,
    );
    _copyAnimation = CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.2, 1, curve: Curves.easeOutCubic),
    );
    _animationController.forward();
  }

  void _finishOnboarding() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(builder: (_) => const RoleSelectionScreen()),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: FikaGoColors.forestGreen,
        systemNavigationBarColor: FikaGoColors.forestGreen,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: FikaGoColors.forestGreen,
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 10, 16, 8),
                child: Row(
                  children: [
                    const Text(
                      'FikaGo',
                      style: TextStyle(
                        color: FikaGoColors.lightGreen,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Row(
                        children: List.generate(
                          _onboardingData.length,
                          (index) => Expanded(
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 250),
                              height: 3,
                              margin: EdgeInsets.only(
                                right: index == _onboardingData.length - 1
                                    ? 0
                                    : 7,
                              ),
                              decoration: BoxDecoration(
                                color: index <= _currentPage
                                    ? FikaGoColors.sunYellow
                                    : FikaGoColors.lightGreen
                                        .withValues(alpha: 0.28),
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    TextButton(
                      onPressed: _finishOnboarding,
                      style: TextButton.styleFrom(
                        foregroundColor: FikaGoColors.lightGreen,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                      ),
                      child: Text(
                        context.localized('Ruka', 'Skip'),
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: (index) {
                    setState(() {
                      _currentPage = index;
                    });
                    _animationController.forward(from: 0);
                  },
                  itemCount: _onboardingData.length,
                  itemBuilder: (context, index) => _buildAnimatedPage(index),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 8, 22, 16),
                child: SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: FilledButton(
                    onPressed: () {
                      if (_currentPage == _onboardingData.length - 1) {
                        _finishOnboarding();
                      } else {
                        _pageController.nextPage(
                          duration: const Duration(milliseconds: 360),
                          curve: Curves.easeOutCubic,
                        );
                      }
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: FikaGoColors.sunYellow,
                      foregroundColor: FikaGoColors.charcoal,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      _currentPage == _onboardingData.length - 1
                          ? context.localized('Anza', 'Get Started')
                          : context.localized('Endelea', 'Continue'),
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Widget ya Animation ya Kila Ukurasa
  Widget _buildAnimatedPage(int index) {
    final data = _onboardingData[index];
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 8, 22, 8),
      child: Column(
        children: [
          Expanded(
            flex: 6,
            child: Center(
              child: FadeTransition(
                opacity: _illustrationAnimation,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.07),
                    end: Offset.zero,
                  ).animate(_illustrationAnimation),
                  child: ScaleTransition(
                    scale: _illustrationScale,
                    child: FittedBox(
                      fit: BoxFit.contain,
                      child: _buildPageIllustration(index, data),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            flex: 4,
            child: FadeTransition(
              opacity: _copyAnimation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.08),
                  end: Offset.zero,
                ).animate(_copyAnimation),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      data['title'],
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 28,
                        height: 1.15,
                        fontWeight: FontWeight.w700,
                        color: FikaGoColors.lightGreen,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      data['description'],
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: FikaGoColors.lightGreen.withValues(alpha: 0.82),
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPageIllustration(int index, Map<String, dynamic> data) {
    if (index == 0) return _buildFoodDeliveryVisual();
    if (index == 1) {
      return Container(
        height: 300,
        width: 185,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: FikaGoColors.lightGreen,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: FikaGoColors.forestGreen.withValues(alpha: 0.12),
          ),
          boxShadow: [
            BoxShadow(
              color: FikaGoColors.forestGreen.withValues(alpha: 0.14),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Image.asset(
          'assets/images/driver.png',
          fit: BoxFit.contain,
          alignment: Alignment.topCenter,
        ),
      );
    }
    return Container(
      height: 220,
      width: 220,
      decoration: BoxDecoration(
        color: (data['color'] as Color).withValues(alpha: 0.14),
        shape: BoxShape.circle,
      ),
      child: Icon(
        data['icon'] as IconData,
        size: 80,
        color: FikaGoColors.forestGreen,
      ),
    );
  }

  Widget _buildFoodDeliveryVisual() {
    return SizedBox(
      height: 300,
      width: 320,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            top: 0,
            right: 12,
            child: Container(
              height: 280,
              width: 148,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: FikaGoColors.lightGreen,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: FikaGoColors.forestGreen.withValues(alpha: 0.15),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Image.asset(
                'assets/images/driver.png',
                fit: BoxFit.contain,
                alignment: Alignment.topCenter,
              ),
            ),
          ),
          Positioned(
            left: 0,
            bottom: 20,
            child: Container(
              height: 145,
              width: 185,
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: FikaGoColors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: FikaGoColors.sunYellow,
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: FikaGoColors.charcoal.withValues(alpha: 0.18),
                    blurRadius: 16,
                    offset: const Offset(0, 7),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.asset(
                  'assets/images/fooddelivery.jpeg',
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
          Positioned(
            right: 130,
            bottom: 60,
            child: Container(
              height: 38,
              width: 38,
              decoration: const BoxDecoration(
                color: FikaGoColors.sunYellow,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.delivery_dining,
                color: FikaGoColors.forestGreen,
                size: 24,
              ),
            ),
          ),
        ],
      ),
    );
  }

}

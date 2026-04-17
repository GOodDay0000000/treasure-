// lib/pages/main_navigation_page.dart

import 'package:flutter/material.dart';
import '../l10n/app_strings.dart';
import 'book_select_page.dart';
import 'treasure_map_page.dart';
import 'lab_page.dart';
import 'activity_page.dart';

class MainNavigationPage extends StatefulWidget {
  const MainNavigationPage({super.key});

  /// 하위 위젯에서 탭 전환하기 위한 진입점.
  /// 예: `MainNavigationPage.of(context)?.goToTab(1);`
  static MainNavigationPageState? of(BuildContext context) =>
      context.findAncestorStateOfType<MainNavigationPageState>();

  @override
  State<MainNavigationPage> createState() => MainNavigationPageState();
}

class MainNavigationPageState extends State<MainNavigationPage> {
  int _currentIndex = 0;

  /// 탭 전환 API. 범위를 벗어나면 무시.
  void goToTab(int index) {
    if (index < 0 || index >= _pages.length) return;
    if (_currentIndex == index) return;
    setState(() => _currentIndex = index);
  }

  final List<Widget> _pages = const [
    BookSelectPage(),
    TreasureMapPage(),
    LabPage(),
    ActivityPage(),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark   = Theme.of(context).brightness == Brightness.dark;
    final primary  = Theme.of(context).colorScheme.primary;
    final navBg    = isDark ? const Color(0xFF0D1B2A) : Colors.white;
    final inactive = isDark ? Colors.grey.shade600 : Colors.grey.shade400;
    final divColor = isDark ? const Color(0xFF2C3E50) : const Color(0xFFE5E5EA);

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: navBg,
          border: Border(top: BorderSide(color: divColor, width: 0.5)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.3 : 0.06),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 56,
            child: Row(
              children: [
                _NavItem(
                  icon: Icons.auto_stories_rounded,
                  label: AppLocale.s.navBible,
                  isSelected: _currentIndex == 0,
                  activeColor: primary,
                  inactiveColor: inactive,
                  onTap: () => setState(() => _currentIndex = 0),
                ),
                _NavItem(
                  icon: Icons.map_rounded,
                  label: '보물지도',
                  isSelected: _currentIndex == 1,
                  activeColor: primary,
                  inactiveColor: inactive,
                  onTap: () => setState(() => _currentIndex = 1),
                ),
                _NavItem(
                  icon: Icons.science_rounded,
                  label: '연구소',
                  isSelected: _currentIndex == 2,
                  activeColor: primary,
                  inactiveColor: inactive,
                  onTap: () => setState(() => _currentIndex = 2),
                ),
                _NavItem(
                  icon: Icons.grid_view_rounded,
                  label: AppLocale.s.navActivity,
                  isSelected: _currentIndex == 3,
                  activeColor: primary,
                  inactiveColor: inactive,
                  onTap: () => setState(() => _currentIndex = 3),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final Color activeColor;
  final Color inactiveColor;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.activeColor,
    required this.inactiveColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = isSelected ? activeColor : inactiveColor;
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 3),
            Text(label,
                style: TextStyle(
                    fontSize: 10,
                    color: color,
                    fontWeight: isSelected
                        ? FontWeight.w600
                        : FontWeight.normal)),
          ],
        ),
      ),
    );
  }
}

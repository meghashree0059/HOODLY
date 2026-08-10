import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';
import '../core/constants/app_constants.dart';

/// Bottom navigation item model
class BottomNavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;

  const BottomNavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}

/// Hoodly custom bottom navigation bar with animated indicator.
///
/// Usage:
/// ```dart
/// HoodlyBottomNavBar(
///   currentIndex: _currentIndex,
///   onTap: (i) => setState(() => _currentIndex = i),
/// )
/// ```
class HoodlyBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  static const List<BottomNavItem> _items = [
    BottomNavItem(
      icon: Icons.home_outlined,
      activeIcon: Icons.home_rounded,
      label: 'Home',
    ),
    BottomNavItem(
      icon: Icons.explore_outlined,
      activeIcon: Icons.explore_rounded,
      label: 'Explore',
    ),
    BottomNavItem(
      icon: Icons.add_circle_outline_rounded,
      activeIcon: Icons.add_circle_rounded,
      label: 'Add',
    ),
    BottomNavItem(
      icon: Icons.bookmark_border_rounded,
      activeIcon: Icons.bookmark_rounded,
      label: 'Bookmarks',
    ),
    BottomNavItem(
      icon: Icons.person_outline_rounded,
      activeIcon: Icons.person_rounded,
      label: 'Profile',
    ),
  ];

  const HoodlyBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.paddingOf(context).bottom;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: AppColors.textPrimary.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
        border: const Border(
          top: BorderSide(color: AppColors.border, width: 1),
        ),
      ),
      padding: EdgeInsets.only(bottom: bottomPadding),
      height: AppConstants.bottomNavHeight + bottomPadding,
      child: Row(
        children: List.generate(_items.length, (index) {
          return Expanded(
            child: _NavBarItem(
              item: _items[index],
              isSelected: currentIndex == index,
              onTap: () => onTap(index),
            ),
          );
        }),
      ),
    );
  }
}

class _NavBarItem extends StatefulWidget {
  final BottomNavItem item;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavBarItem({
    required this.item,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_NavBarItem> createState() => _NavBarItemState();
}

class _NavBarItemState extends State<_NavBarItem>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnim;
  late final Animation<double> _indicatorAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _scaleAnim = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );
    _indicatorAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    if (widget.isSelected) _controller.value = 1.0;
  }

  @override
  void didUpdateWidget(_NavBarItem old) {
    super.didUpdateWidget(old);
    if (widget.isSelected != old.isSelected) {
      widget.isSelected ? _controller.forward() : _controller.reverse();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        height: AppConstants.bottomNavHeight,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Animated pill indicator
            AnimatedBuilder(
              animation: _indicatorAnim,
              builder: (context, child) {
                return Container(
                  width: _indicatorAnim.value * 36,
                  height: 3,
                  margin: const EdgeInsets.only(bottom: 6),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(AppConstants.radiusFull),
                  ),
                );
              },
            ),

            // Icon
            ScaleTransition(
              scale: _scaleAnim,
              child: AnimatedSwitcher(
                duration: AppConstants.animFast,
                transitionBuilder: (child, anim) =>
                    FadeTransition(opacity: anim, child: child),
                child: Icon(
                  widget.isSelected
                      ? widget.item.activeIcon
                      : widget.item.icon,
                  key: ValueKey(widget.isSelected),
                  color: widget.isSelected
                      ? AppColors.primary
                      : AppColors.textHint,
                  size: AppConstants.iconMD,
                ),
              ),
            ),

            const SizedBox(height: 4),

            // Label
            AnimatedDefaultTextStyle(
              duration: AppConstants.animFast,
              style: AppTextStyles.labelSmall.copyWith(
                color: widget.isSelected
                    ? AppColors.primary
                    : AppColors.textHint,
                fontWeight: widget.isSelected
                    ? FontWeight.w600
                    : FontWeight.w400,
              ),
              child: Text(widget.item.label),
            ),
          ],
        ),
      ),
    );
  }
}

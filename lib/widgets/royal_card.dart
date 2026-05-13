import 'package:flutter/material.dart';
import '../utils/royal_colors.dart';

class RoyalCard extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final bool hasGoldBorder;
  final bool isSelected;

  const RoyalCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(16.0),
    this.hasGoldBorder = false,
    this.isSelected = false,
  });

  @override
  State<RoyalCard> createState() => _RoyalCardState();
}

class _RoyalCardState extends State<RoyalCard> {
  bool _isHovered = false;
  bool _isPressed = false;

  void _handleTapDown(TapDownDetails details) {
    if (widget.onTap != null) {
      setState(() => _isPressed = true);
    }
  }

  void _handleTapUp(TapUpDetails details) {
    if (widget.onTap != null) {
      setState(() => _isPressed = false);
      widget.onTap!();
    }
  }

  void _handleTapCancel() {
    if (widget.onTap != null) {
      setState(() => _isPressed = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Color bgColor = isDark ? RoyalColors.darkSurface : RoyalColors.lightSurface;
    Color borderColor = isDark ? RoyalColors.darkBorder : RoyalColors.lightBorder;
    double borderWidth = 1.0;

    if (widget.isSelected) {
      bgColor = isDark ? RoyalColors.darkAccent.withOpacity(0.1) : RoyalColors.lightAccentLighter.withOpacity(0.2);
      borderColor = isDark ? RoyalColors.darkAccent : RoyalColors.lightAccent;
      borderWidth = 2.0;
    }

    // Shadow logic
    List<BoxShadow> shadows = [];
    if (_isPressed) {
      // Level 1
      shadows = [
        BoxShadow(
          color: isDark ? Colors.black.withOpacity(0.5) : const Color(0xFF00236F).withOpacity(0.01),
          blurRadius: 10,
          offset: const Offset(0, 0),
        ),
      ];
    } else if (_isHovered) {
      // Level 3
      shadows = [
        BoxShadow(
          color: isDark ? Colors.black.withOpacity(0.6) : const Color(0xFF00236F).withOpacity(0.04),
          blurRadius: 60,
          offset: const Offset(0, 4),
        ),
      ];
    } else {
      // Level 2 (Default Ambient)
      shadows = [
        BoxShadow(
          color: isDark ? Colors.black.withOpacity(0.5) : const Color(0xFF00236F).withOpacity(0.02),
          blurRadius: 40,
          offset: const Offset(0, 0),
        ),
      ];
    }

    double translateY = _isPressed ? 0 : (_isHovered ? -2 : 0);
    double scale = _isPressed ? 0.98 : 1.0;

    return MouseRegion(
      onEnter: (_) {
        if (widget.onTap != null) setState(() => _isHovered = true);
      },
      onExit: (_) {
        if (widget.onTap != null) setState(() => _isHovered = false);
      },
      child: GestureDetector(
        onTapDown: _handleTapDown,
        onTapUp: _handleTapUp,
        onTapCancel: _handleTapCancel,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOut,
          transform: Matrix4.identity()
            ..translate(0.0, translateY)
            ..scale(scale),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(32),
            boxShadow: shadows,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(32),
            child: Stack(
              children: [
                Padding(
                  padding: widget.padding,
                  child: widget.child,
                ),
                if (widget.hasGoldBorder)
                  Positioned(
                    left: 0,
                    top: 0,
                    bottom: 0,
                    child: Container(
                      width: 2,
                      color: isDark ? RoyalColors.darkAccent : RoyalColors.lightAccent,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

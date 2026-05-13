import 'package:flutter/material.dart';
import '../utils/royal_colors.dart';

class RoyalButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isPrimary;
  final bool isLoading;

  const RoyalButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isPrimary = true,
    this.isLoading = false,
  });

  @override
  State<RoyalButton> createState() => _RoyalButtonState();
}

class _RoyalButtonState extends State<RoyalButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.98).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    if (widget.onPressed != null && !widget.isLoading) {
      _controller.forward();
    }
  }

  void _onTapUp(TapUpDetails details) {
    if (widget.onPressed != null && !widget.isLoading) {
      _controller.reverse();
    }
  }

  void _onTapCancel() {
    if (widget.onPressed != null && !widget.isLoading) {
      _controller.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final bool isDisabled = widget.onPressed == null;

    BoxDecoration decoration;
    Color textColor;

    if (isDisabled) {
      decoration = BoxDecoration(
        color: isDark ? RoyalColors.darkBorder : RoyalColors.lightBorder,
        borderRadius: BorderRadius.circular(6),
      );
      textColor = isDark ? RoyalColors.darkTextSecondary : RoyalColors.lightTextSecondary;
    } else if (widget.isPrimary) {
      decoration = BoxDecoration(
        gradient: LinearGradient(
          colors: [
            isDark ? RoyalColors.darkAccent : RoyalColors.lightAccent,
            isDark ? RoyalColors.lightAccentLighter : RoyalColors.lightAccentLighter,
          ],
        ),
        borderRadius: BorderRadius.circular(6),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black.withOpacity(0.4) : RoyalColors.lightPrimary.withOpacity(0.12),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      );
      textColor = isDark ? RoyalColors.darkBackground : Colors.white;
    } else {
      decoration = BoxDecoration(
        color: Colors.transparent,
        border: Border.all(
          color: isDark ? RoyalColors.darkPrimary : RoyalColors.lightPrimary,
          width: 2,
        ),
        borderRadius: BorderRadius.circular(6),
      );
      textColor = isDark ? RoyalColors.darkTextPrimary : RoyalColors.lightPrimary;
    }

    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      onTap: widget.isLoading ? null : widget.onPressed,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: double.infinity,
          height: 48, // Minimum touch target size
          decoration: decoration,
          child: Center(
            child: widget.isLoading
                ? SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(
                      color: textColor,
                      strokeWidth: 2,
                    ),
                  )
                : Text(
                    widget.text.toUpperCase(),
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: textColor,
                        ),
                  ),
          ),
        ),
      ),
    );
  }
}

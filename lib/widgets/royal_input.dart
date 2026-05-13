import 'package:flutter/material.dart';
import '../utils/royal_colors.dart';

class RoyalInput extends StatefulWidget {
  final String? hintText;
  final String? labelText;
  final bool obscureText;
  final TextEditingController? controller;
  final String? errorText;
  final Widget? suffixIcon;
  final Widget? prefixIcon;
  final ValueChanged<String>? onChanged;
  final TextInputType keyboardType;
  final bool enabled;

  const RoyalInput({
    super.key,
    this.hintText,
    this.labelText,
    this.obscureText = false,
    this.controller,
    this.errorText,
    this.suffixIcon,
    this.prefixIcon,
    this.onChanged,
    this.keyboardType = TextInputType.text,
    this.enabled = true,
  });

  @override
  State<RoyalInput> createState() => _RoyalInputState();
}

class _RoyalInputState extends State<RoyalInput> with SingleTickerProviderStateMixin {
  final FocusNode _focusNode = FocusNode();
  bool _isFocused = false;
  late AnimationController _shakeController;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChange);
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  @override
  void didUpdateWidget(covariant RoyalInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.errorText != null && oldWidget.errorText == null) {
      _shakeController.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    _shakeController.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    setState(() {
      _isFocused = _focusNode.hasFocus;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bool hasError = widget.errorText != null;

    final borderColor = hasError
        ? (isDark ? RoyalColors.darkError : RoyalColors.lightError)
        : _isFocused
            ? (isDark ? RoyalColors.darkPrimary : RoyalColors.lightPrimary)
            : (isDark ? RoyalColors.darkBorder : RoyalColors.lightBorder);

    final glowColor = _isFocused && !hasError
        ? (isDark ? RoyalColors.goldGlowDark : RoyalColors.goldGlowLight)
        : Colors.transparent;

    final bgColor = !widget.enabled
        ? (isDark ? RoyalColors.darkBorder : RoyalColors.lightBorder)
        : (isDark ? RoyalColors.darkSurface : RoyalColors.lightSurface);

    return AnimatedBuilder(
      animation: _shakeController,
      builder: (context, child) {
        // Shake animation logic
        double dx = 0;
        if (_shakeController.isAnimating) {
          final progress = _shakeController.value;
          if (progress < 0.25) dx = -10 * (progress / 0.25);
          else if (progress < 0.75) dx = 10 * ((progress - 0.25) / 0.5) - 10;
          else dx = 10 - 10 * ((progress - 0.75) / 0.25);
        }

        return Transform.translate(
          offset: Offset(dx, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.labelText != null) ...[
                Text(
                  widget.labelText!,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: !widget.enabled
                            ? (isDark ? RoyalColors.darkTextSecondary : RoyalColors.lightTextSecondary)
                            : (isDark ? RoyalColors.darkTextPrimary : RoyalColors.lightTextPrimary),
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 8),
              ],
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: borderColor,
                    width: _isFocused || hasError ? 2 : 1,
                  ),
                  boxShadow: [
                    if (_isFocused && !hasError)
                      BoxShadow(
                        color: glowColor,
                        blurRadius: 0,
                        spreadRadius: 4,
                      ),
                  ],
                ),
                child: TextFormField(
                  controller: widget.controller,
                  focusNode: _focusNode,
                  obscureText: widget.obscureText,
                  onChanged: widget.onChanged,
                  keyboardType: widget.keyboardType,
                  enabled: widget.enabled,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: !widget.enabled
                            ? (isDark ? RoyalColors.darkTextSecondary : RoyalColors.lightTextSecondary)
                            : (isDark ? RoyalColors.darkTextPrimary : RoyalColors.lightTextPrimary),
                      ),
                  decoration: InputDecoration(
                    hintText: widget.hintText,
                    hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: isDark ? RoyalColors.darkTextSecondary : RoyalColors.lightTextSecondary,
                        ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    isDense: true,
                    suffixIcon: widget.suffixIcon,
                    prefixIcon: widget.prefixIcon,
                  ),
                ),
              ),
              if (hasError) ...[
                const SizedBox(height: 4),
                Text(
                  widget.errorText!,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: isDark ? RoyalColors.darkError : RoyalColors.lightError,
                      ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

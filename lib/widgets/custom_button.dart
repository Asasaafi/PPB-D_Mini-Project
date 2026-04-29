import 'package:flutter/material.dart';
import '../core/constants/colors.dart';

enum CustomButtonVariant { primary, danger, outline, ghost }

class CustomButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;
  final CustomButtonVariant variant;
  final double height;
  final double? width;
  final double borderRadius;
  final double fontSize;

  const CustomButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.icon,
    this.variant = CustomButtonVariant.primary,
    this.height = 56,
    this.width,
    this.borderRadius = 16,
    this.fontSize = 16,
  });
  
  Color get _bgColor {
    switch (variant) {
      case CustomButtonVariant.primary:
        return AppColors.primary;
      case CustomButtonVariant.danger:
        return AppColors.expired;
      case CustomButtonVariant.outline:
      case CustomButtonVariant.ghost:
        return Colors.transparent;
    }
  }

  Color get _fgColor {
    switch (variant) {
      case CustomButtonVariant.primary:
      case CustomButtonVariant.danger:
        return Colors.white;
      case CustomButtonVariant.outline:
        return AppColors.primary;
      case CustomButtonVariant.ghost:
        return AppColors.textMuted;
    }
  }

  BorderSide get _border {
    switch (variant) {
      case CustomButtonVariant.outline:
        return const BorderSide(color: AppColors.primary, width: 1.5);
      default:
        return BorderSide.none;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width ?? double.infinity,
      height: height,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: _bgColor,
          foregroundColor: _fgColor,
          disabledBackgroundColor: _bgColor.withOpacity(0.5),
          elevation: variant == CustomButtonVariant.ghost ? 0 : 2,
          shadowColor: _bgColor.withOpacity(0.3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius),
            side: _border,
          ),
        ),
        child: isLoading
            ? SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  color: _fgColor,
                  strokeWidth: 2.5,
                ),
              )
            : _ButtonContent(
                label: label,
                icon: icon,
                color: _fgColor,
                fontSize: fontSize,
              ),
      ),
    );
  }
}

class _ButtonContent extends StatelessWidget {
  final String label;
  final IconData? icon;
  final Color color;
  final double fontSize;

  const _ButtonContent({
    required this.label,
    required this.color,
    required this.fontSize,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    if (icon == null) {
      return Text(
        label,
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.w700,
          color: color,
          letterSpacing: 0.3,
        ),
      );
    }
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.w700,
            color: color,
            letterSpacing: 0.3,
          ),
        ),
      ],
    );
  }
}
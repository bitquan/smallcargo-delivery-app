import 'package:flutter/material.dart';
import '../design_system/app_design_system.dart';

/// Enhanced UI components for production-ready interface
class EnhancedComponents {
  
  /// Professional card with glow effect and animations
  static Widget enhancedCard({
    required Widget child,
    VoidCallback? onTap,
    bool isPrimary = false,
    bool isLoading = false,
  }) {
    return AnimatedContainer(
      duration: AppDesignSystem.animationMedium,
      decoration: isPrimary 
          ? AppDesignSystem.primaryCardDecoration 
          : AppDesignSystem.surfaceCardDecoration,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppDesignSystem.radiusLg),
          child: Padding(
            padding: const EdgeInsets.all(AppDesignSystem.spacingXl),
            child: isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppDesignSystem.primaryGold,
                      ),
                    ),
                  )
                : child,
          ),
        ),
      ),
    );
  }
  
  /// Professional hero section with gradient background
  static Widget heroSection({
    required String title,
    required String subtitle,
    Widget? action,
    String? backgroundImage,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDesignSystem.spacing3xl),
      decoration: BoxDecoration(
        gradient: AppDesignSystem.heroGradient,
        borderRadius: BorderRadius.circular(AppDesignSystem.radiusXl),
        boxShadow: const [
          AppDesignSystem.shadowLg,
          AppDesignSystem.glowPrimary,
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppDesignSystem.displayMedium.copyWith(
              color: AppDesignSystem.backgroundDark,
            ),
          ),
          const SizedBox(height: AppDesignSystem.spacingMd),
          Text(
            subtitle,
            style: AppDesignSystem.bodyLarge.copyWith(
              color: AppDesignSystem.backgroundDark.withValues(alpha: 0.8),
            ),
          ),
          if (action != null) ...[
            const SizedBox(height: AppDesignSystem.spacing2xl),
            action,
          ],
        ],
      ),
    );
  }
  
  /// Enhanced quick action card with hover effects
  static Widget quickActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return enhancedCard(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(AppDesignSystem.spacingLg),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppDesignSystem.radiusLg),
            ),
            child: Icon(
              icon,
              size: 32,
              color: color,
            ),
          ),
          const SizedBox(height: AppDesignSystem.spacingMd),
          Text(
            title,
            style: AppDesignSystem.headlineSmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppDesignSystem.spacingXs),
          Text(
            subtitle,
            style: AppDesignSystem.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
  
  /// Status indicator with animations
  static Widget statusIndicator({
    required String status,
    required Color color,
    bool isAnimated = true,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDesignSystem.spacingMd,
        vertical: AppDesignSystem.spacingXs,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppDesignSystem.radiusFull),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isAnimated)
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: AppDesignSystem.animationMedium,
              builder: (context, value, child) {
                return Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: value),
                    shape: BoxShape.circle,
                  ),
                );
              },
            )
          else
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
          const SizedBox(width: AppDesignSystem.spacingXs),
          Text(
            status,
            style: AppDesignSystem.labelSmall.copyWith(color: color),
          ),
        ],
      ),
    );
  }
  
  /// Enhanced form field with floating label
  static Widget enhancedTextField({
    required String label,
    IconData? icon,
    TextEditingController? controller,
    bool isPassword = false,
    String? Function(String?)? validator,
    void Function(String)? onChanged,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword,
      validator: validator,
      onChanged: onChanged,
      style: AppDesignSystem.bodyLarge,
      decoration: AppDesignSystem.inputDecoration(label, icon: icon),
    );
  }
  
  /// Loading state with shimmer effect
  static Widget loadingShimmer({
    double? width,
    double? height,
    double borderRadius = AppDesignSystem.radiusMd,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 1500),
      builder: (context, value, child) {
        return Container(
          width: width,
          height: height ?? 20,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(borderRadius),
            gradient: LinearGradient(
              colors: [
                AppDesignSystem.backgroundSurface,
                AppDesignSystem.textMuted.withValues(alpha: 0.3),
                AppDesignSystem.backgroundSurface,
              ],
              stops: [0.0, value, 1.0],
            ),
          ),
        );
      },
    );
  }
  
  /// Enhanced button with loading state
  static Widget enhancedButton({
    required String text,
    required VoidCallback? onPressed,
    bool isPrimary = true,
    bool isLoading = false,
    IconData? icon,
  }) {
    final buttonStyle = isPrimary 
        ? AppDesignSystem.primaryButtonStyle 
        : AppDesignSystem.secondaryButtonStyle;
    
    if (isPrimary) {
      return ElevatedButton.icon(
        onPressed: isLoading ? null : onPressed,
        style: buttonStyle,
        icon: isLoading
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    AppDesignSystem.backgroundDark,
                  ),
                ),
              )
            : Icon(icon ?? Icons.arrow_forward),
        label: Text(text),
      );
    } else {
      return OutlinedButton.icon(
        onPressed: isLoading ? null : onPressed,
        style: buttonStyle,
        icon: isLoading
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    AppDesignSystem.primaryGold,
                  ),
                ),
              )
            : Icon(icon ?? Icons.arrow_forward),
        label: Text(text),
      );
    }
  }
  
  /// Professional stats card
  static Widget statsCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    String? subtitle,
    double? percentage,
  }) {
    return enhancedCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppDesignSystem.spacingSm),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppDesignSystem.radiusMd),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const Spacer(),
              if (percentage != null)
                statusIndicator(
                  status: '${percentage > 0 ? '+' : ''}${percentage.toStringAsFixed(1)}%',
                  color: percentage > 0 
                      ? AppDesignSystem.statusSuccess 
                      : AppDesignSystem.statusError,
                ),
            ],
          ),
          const SizedBox(height: AppDesignSystem.spacingMd),
          Text(
            value,
            style: AppDesignSystem.displaySmall.copyWith(color: color),
          ),
          const SizedBox(height: AppDesignSystem.spacingXs),
          Text(
            title,
            style: AppDesignSystem.bodyMedium,
          ),
          if (subtitle != null) ...[
            const SizedBox(height: AppDesignSystem.spacingXs),
            Text(
              subtitle,
              style: AppDesignSystem.bodySmall,
            ),
          ],
        ],
      ),
    );
  }
  
  /// Enhanced navigation bar
  static PreferredSizeWidget enhancedAppBar({
    required String title,
    List<Widget>? actions,
    bool showBackButton = true,
  }) {
    return AppBar(
      title: Text(
        title,
        style: AppDesignSystem.headlineLarge.copyWith(
          color: AppDesignSystem.backgroundDark,
        ),
      ),
      backgroundColor: AppDesignSystem.primaryGold,
      foregroundColor: AppDesignSystem.backgroundDark,
      elevation: 0,
      centerTitle: false,
      automaticallyImplyLeading: showBackButton,
      actions: actions,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(AppDesignSystem.radiusLg),
        ),
      ),
    );
  }
}

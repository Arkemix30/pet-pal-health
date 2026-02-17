import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';

enum ToastType { success, error, sync }

class OverlayManager {
  static void showToast(
    BuildContext context, {
    required String message,
    ToastType type = ToastType.success,
    Duration duration = const Duration(seconds: 3),
  }) {
    final overlay = Overlay.of(context);
    late OverlayEntry entry;

    entry = OverlayEntry(
      builder: (context) => Positioned(
        top: type == ToastType.error ? 60 : null,
        bottom: type != ToastType.error ? 100 : null,
        left: 20,
        right: 20,
        child:
            Material(
                  color: Colors.transparent,
                  child: _PremiumToast(
                    message: message,
                    type: type,
                    onClose: () => entry.remove(),
                  ),
                )
                .animate()
                .fadeIn(duration: 400.ms)
                .slideY(begin: type == ToastType.error ? -0.5 : 0.5, end: 0),
      ),
    );

    overlay.insert(entry);
    HapticFeedback.lightImpact();

    Future.delayed(duration, () {
      if (entry.mounted) {
        entry.remove();
      }
    });
  }

  static Future<T?> showPremiumModal<T>(
    BuildContext context, {
    required Widget child,
    bool dismissible = true,
  }) {
    HapticFeedback.mediumImpact();
    return showGeneralDialog<T>(
      context: context,
      barrierDismissible: dismissible,
      barrierLabel: '',
      barrierColor: Colors.black.withValues(alpha: 0.6),
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (context, anim1, anim2) => child,
      transitionBuilder: (context, anim1, anim2, child) {
        return BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: 10 * anim1.value,
            sigmaY: 10 * anim1.value,
          ),
          child: FadeTransition(
            opacity: anim1,
            child: ScaleTransition(
              scale: anim1.drive(
                Tween<double>(
                  begin: 0.8,
                  end: 1.0,
                ).chain(CurveTween(curve: Curves.easeOutBack)),
              ),
              child: child,
            ),
          ),
        );
      },
    );
  }
}

class _PremiumToast extends StatelessWidget {
  final String message;
  final ToastType type;
  final VoidCallback onClose;

  const _PremiumToast({
    required this.message,
    required this.type,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final isError = type == ToastType.error;
    final isSync = type == ToastType.sync;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppTheme.overlayBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isError
              ? AppTheme.overlayError.withValues(alpha: 0.3)
              : AppTheme.overlayBorder,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isError
                  ? AppTheme.overlayError.withValues(alpha: 0.1)
                  : AppTheme.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isError
                  ? Icons.error_outline
                  : (isSync ? Icons.cloud_sync : Icons.check_circle_outline),
              color: isError ? AppTheme.overlayError : AppTheme.primary,
              size: 20,
            ),
          ),
          if (isSync) ...[
            const SizedBox(width: 12),
            Stack(
              alignment: Alignment.center,
              children: [
                Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                    )
                    .animate(onPlay: (controller) => controller.repeat())
                    .scale(
                      duration: 1.seconds,
                      begin: const Offset(1, 1),
                      end: const Offset(2.5, 2.5),
                    )
                    .fadeOut(),
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: AppTheme.primary,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: GoogleFonts.manrope(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white24, size: 18),
            onPressed: onClose,
          ),
        ],
      ),
    );
  }
}

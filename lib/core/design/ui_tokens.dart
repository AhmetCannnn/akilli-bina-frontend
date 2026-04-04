import 'package:fluent_ui/fluent_ui.dart';

/// Shared UI tokens for spacing, sizing and radius.
abstract final class AppUiTokens {
  static const double space4 = 4;
  static const double space6 = 6;
  static const double space8 = 8;
  static const double space12 = 12;
  static const double space10 = 10;
  static const double space14 = 14;
  static const double space16 = 16;
  static const double space20 = 20;
  static const double space24 = 24;

  // Radius
  static const double radius4 = 4;
  static const double radius6 = 6;
  static const double radius8 = 8;
  static const double radius16 = 16;
  static const double radius20 = 20;
  static const double radius10 = 10;
  static const double radius12 = 12;

  static const double controlHeightSm = 28;
  static const double controlHeightMd = 32;
  static const double controlHeightLg = 36;

  static const double iconSm = 12;
  static const double iconMd = 14;
  static const double iconLg = 16;
}

enum AppControlSize { sm, md, lg }

extension AppControlSizeX on AppControlSize {
  double get height {
    switch (this) {
      case AppControlSize.sm:
        return AppUiTokens.controlHeightSm;
      case AppControlSize.md:
        return AppUiTokens.controlHeightMd;
      case AppControlSize.lg:
        return AppUiTokens.controlHeightLg;
    }
  }

  double get iconSize {
    switch (this) {
      case AppControlSize.sm:
        return AppUiTokens.iconSm;
      case AppControlSize.md:
        return AppUiTokens.iconMd;
      case AppControlSize.lg:
        return AppUiTokens.iconLg;
    }
  }

  EdgeInsets get contentPadding {
    switch (this) {
      case AppControlSize.sm:
        return const EdgeInsets.symmetric(
          horizontal: AppUiTokens.space8,
          vertical: AppUiTokens.space4,
        );
      case AppControlSize.md:
        return const EdgeInsets.symmetric(
          horizontal: AppUiTokens.space12,
          vertical: AppUiTokens.space6,
        );
      case AppControlSize.lg:
        return const EdgeInsets.symmetric(
          horizontal: AppUiTokens.space12,
          vertical: AppUiTokens.space8,
        );
    }
  }
}

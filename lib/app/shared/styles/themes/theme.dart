import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../colors.dart';
import 'btntheme.dart';
import 'txttheme.dart';

class AppTheme {
  AppTheme._();

  static ThemeData lightTheme = _build(
    brightness: Brightness.light,
    page: AppColors.tdLightPage,
    card: AppColors.tdLightCard,
    alt: AppColors.tdLightPage,
    tint: AppColors.tdVioletTint,
    border: AppColors.tdLightBorder,
    text: AppColors.tdLightText,
    muted: AppColors.tdLightTextMuted,
    primary: AppColors.tdViolet,
    onPrimary: AppColors.tdWhite,
    textTheme: TxtTheme.lighttxtTheme,
    buttonTheme: BtnTheme.lightbtnTheme(),
  );

  static ThemeData darkTheme = _build(
    brightness: Brightness.dark,
    page: AppColors.tdDarkPage,
    card: AppColors.tdDarkCard,
    alt: AppColors.tdDarkSurfaceAlt,
    tint: AppColors.tdVioletTintDark,
    border: AppColors.tdDarkBorder,
    text: AppColors.tdDarkText,
    muted: AppColors.tdDarkTextMuted,
    primary: AppColors.tdVioletSoft,
    onPrimary: AppColors.tdVioletDeep,
    textTheme: TxtTheme.darktxtTheme,
    buttonTheme: BtnTheme.darkbtnTheme(),
  );

  static ThemeData _build({
    required Brightness brightness,
    required Color page,
    required Color card,
    required Color alt,
    required Color tint,
    required Color border,
    required Color text,
    required Color muted,
    required Color primary,
    required Color onPrimary,
    required TextTheme textTheme,
    required ButtonThemeData buttonTheme,
  }) {
    final bool isLight = brightness == Brightness.light;
    final Brightness iconBrightness = isLight
        ? Brightness.dark
        : Brightness.light;
    final Color disabledBg = muted.withValues(alpha: 0.18);
    final Color disabledFg = muted.withValues(alpha: 0.6);

    final scheme = ColorScheme(
      brightness: brightness,
      primary: primary,
      onPrimary: onPrimary,
      primaryContainer: tint,
      onPrimaryContainer: primary,
      secondary: primary,
      onSecondary: onPrimary,
      secondaryContainer: tint,
      onSecondaryContainer: primary,
      error: AppColors.tdError,
      onError: AppColors.tdWhite,
      surface: card,
      onSurface: text,
      onSurfaceVariant: muted,
      outline: border,
      outlineVariant: border,
      surfaceTint: Colors.transparent,
      surfaceContainerLowest: page,
      surfaceContainerLow: card,
      surfaceContainer: card,
      surfaceContainerHigh: alt,
      surfaceContainerHighest: alt,
      inverseSurface: text,
      onInverseSurface: page,
      inversePrimary: primary,
      shadow: Colors.black,
      scrim: Colors.black,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      primaryColor: primary,
      primaryColorDark: text,
      primaryColorLight: tint,
      scaffoldBackgroundColor: page,
      canvasColor: page,
      highlightColor: primary.withValues(alpha: 0.06),
      splashColor: primary.withValues(alpha: 0.08),
      unselectedWidgetColor: muted,
      disabledColor: disabledFg,

      textTheme: textTheme,
      iconTheme: IconThemeData(color: text, size: 24),

      dividerTheme: DividerThemeData(color: border, thickness: 1, space: 1),

      appBarTheme: AppBarTheme(
        backgroundColor: page,
        surfaceTintColor: Colors.transparent,
        foregroundColor: text,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false, // logo à gauche comme sur le site
        titleTextStyle: textTheme.titleLarge,
        iconTheme: IconThemeData(color: text),
        actionsIconTheme: IconThemeData(color: text),
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: iconBrightness,
          statusBarBrightness: brightness,
          systemNavigationBarColor: page,
          systemNavigationBarDividerColor: Colors.transparent,
          systemNavigationBarIconBrightness: iconBrightness,
        ),
      ),

      // Cartes : fond card + bordure fine, rayon 16, sans ombre
      cardTheme: CardThemeData(
        color: card,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: border),
        ),
      ),

      // Boutons
      buttonTheme: buttonTheme,
      filledButtonTheme: BtnTheme.filled(
        bg: primary,
        fg: onPrimary,
        disabledBg: disabledBg,
        disabledFg: disabledFg,
      ),
      elevatedButtonTheme: BtnTheme.elevated(
        bg: primary,
        fg: onPrimary,
        disabledBg: disabledBg,
        disabledFg: disabledFg,
      ),
      outlinedButtonTheme: BtnTheme.outlined(
        bg: alt,
        fg: text,
        border: border,
        disabledFg: disabledFg,
      ),
      textButtonTheme: BtnTheme.text(fg: primary, disabledFg: disabledFg),
      iconButtonTheme: BtnTheme.icon(fg: text, border: Colors.transparent),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primary,
        foregroundColor: onPrimary,
        elevation: 2,
        focusElevation: 2,
        hoverElevation: 2,
        highlightElevation: 2,
        enableFeedback: false,
        splashColor: onPrimary.withValues(alpha: 0.12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),

      // Champs de saisie
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: alt,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        hintStyle: textTheme.bodySmall,
        labelStyle: textTheme.titleSmall?.copyWith(color: muted),
        floatingLabelStyle: textTheme.titleSmall?.copyWith(color: primary),
        helperStyle: textTheme.bodySmall,
        errorStyle: textTheme.bodySmall?.copyWith(color: AppColors.tdError),
        border: _inputBorder(border),
        enabledBorder: _inputBorder(border),
        disabledBorder: _inputBorder(border.withValues(alpha: 0.5)),
        focusedBorder: _inputBorder(primary, width: 2),
        errorBorder: _inputBorder(AppColors.tdError),
        focusedErrorBorder: _inputBorder(AppColors.tdError, width: 2),
      ),

      // Pastille « Selected 2 platforms »
      chipTheme: ChipThemeData(
        backgroundColor: tint,
        selectedColor: primary,
        disabledColor: disabledBg,
        labelStyle: textTheme.labelMedium?.copyWith(color: primary),
        secondaryLabelStyle: textTheme.labelMedium?.copyWith(color: onPrimary),
        side: BorderSide.none,
        shape: const StadiumBorder(),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        showCheckmark: false,
      ),

      // Curseur (« Foreground scale »)
      sliderTheme: SliderThemeData(
        activeTrackColor: primary,
        inactiveTrackColor: border,
        thumbColor: primary,
        overlayColor: primary.withValues(alpha: 0.12),
        trackHeight: 6,
      ),

      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? onPrimary : muted,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? primary : border,
        ),
        trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
      ),

      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (s) =>
              s.contains(WidgetState.selected) ? primary : Colors.transparent,
        ),
        checkColor: WidgetStateProperty.all(onPrimary),
        side: BorderSide(color: border, width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),

      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: primary,
        linearTrackColor: tint,
        circularTrackColor: tint,
        linearMinHeight: 6,
      ),

      listTileTheme: ListTileThemeData(
        iconColor: muted,
        textColor: text,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),

      // Barre de navigation inférieure
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: card,
        surfaceTintColor: Colors.transparent,
        indicatorColor: tint,
        elevation: 0,
        height: 68,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (s) => textTheme.labelMedium?.copyWith(
            color: s.contains(WidgetState.selected) ? primary : muted,
            fontWeight: s.contains(WidgetState.selected)
                ? FontWeight.w700
                : FontWeight.w500,
          ),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (s) => IconThemeData(
            color: s.contains(WidgetState.selected) ? primary : muted,
          ),
        ),
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: card,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: textTheme.headlineMedium,
        contentTextStyle: textTheme.bodyMedium?.copyWith(color: muted),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: border),
        ),
      ),

      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: card,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        dragHandleColor: border,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
      ),

      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: text,
        contentTextStyle: textTheme.bodyMedium?.copyWith(color: page),
        actionTextColor: primary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  static OutlineInputBorder _inputBorder(Color c, {double width = 1}) =>
      OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: c, width: width),
      );
}

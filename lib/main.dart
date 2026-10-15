import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:prestora/app/routes/routes.conf.dart';
import 'package:prestora/app/shared/styles/colors.dart';
import 'package:prestora/app/shared/styles/themes/theme.dart';
import 'package:prestora/controller/cubit/cubit.dart';
import 'package:prestora/controller/state/state.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await EasyLocalization.ensureInitialized();
  SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
  bool isDark = sharedPreferences.getBool('isDark') ?? false;

  runApp(
    EasyLocalization(
      path: 'assets/translations',
      supportedLocales: const [Locale('fr', 'FR'), Locale('en', 'US')],
      fallbackLocale: const Locale('fr', 'FR'),
      saveLocale: true,
      child: PrestOra(isDark: isDark),
    ),
  );
}

class PrestOra extends StatelessWidget {
  const PrestOra({super.key, required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => MainCubit()..changeThemeMode(darkMode: isDark),
        ),
      ],
      child: BlocBuilder<MainCubit, MainState>(
        builder: (context, state) {
          final cubit = MainCubit.get(context);
          final dark = cubit.isDark;

          // Style des barres système (fallback pour les pages sans AppBar)
          final overlay = SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: dark
                ? Brightness.light
                : Brightness.dark, // Android
            statusBarBrightness: dark
                ? Brightness.dark
                : Brightness.light, // iOS
            systemNavigationBarColor: dark
                ? AppColors.tdDarkPage
                : AppColors.tdLightPage,
            systemNavigationBarDividerColor: Colors.transparent,
            systemNavigationBarIconBrightness: dark
                ? Brightness.light
                : Brightness.dark,
          );

          return MaterialApp.router(
            debugShowCheckedModeBanner: false,
            localizationsDelegates: context.localizationDelegates,
            supportedLocales: context.supportedLocales,
            locale: context.locale,
            title: 'PrestOra',
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: dark ? ThemeMode.dark : ThemeMode.light,
            routerConfig: router,
            builder: (context, child) => AnnotatedRegion<SystemUiOverlayStyle>(
              value: overlay,
              child: child!,
            ),
          );
        },
      ),
    );
  }
}

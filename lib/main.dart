// lib/main.dart

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_quill/flutter_quill.dart' show FlutterQuillLocalizations;
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'pages/main_navigation_page.dart';
import 'l10n/app_strings.dart';
import 'services/bookmark_service.dart';
import 'services/highlight_service.dart';
import 'services/memo_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();
  await BookmarkService.init();
  await HighlightService.init();
  await MemoService.init();

  final prefs = await SharedPreferences.getInstance();
  final isDark = prefs.getBool('dark_mode') ?? false;

  // 언어 초기화
  await AppLocale.instance.load();

  runApp(BibleApp(initialDarkMode: isDark));
}

class BibleApp extends StatefulWidget {
  final bool initialDarkMode;
  const BibleApp({super.key, required this.initialDarkMode});

  static _BibleAppState? of(BuildContext context) =>
      context.findAncestorStateOfType<_BibleAppState>();

  @override
  State<BibleApp> createState() => _BibleAppState();
}

class _BibleAppState extends State<BibleApp> {
  late ThemeMode _themeMode;

  @override
  void initState() {
    super.initState();
    _themeMode = widget.initialDarkMode ? ThemeMode.dark : ThemeMode.light;
    // 언어 변경 감지 → 앱 전체 리빌드
    AppLocale.instance.addListener(_onLocaleChange);
  }

  void _onLocaleChange() => setState(() {});

  @override
  void dispose() {
    AppLocale.instance.removeListener(_onLocaleChange);
    super.dispose();
  }

  void toggleTheme() async {
    final isDark = _themeMode == ThemeMode.light;
    setState(() {
      _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('dark_mode', isDark);
  }

  bool get isDarkMode => _themeMode == ThemeMode.dark;

  void setLanguage(AppLanguage lang) {
    AppLocale.instance.setLanguage(lang);
    // _onLocaleChange가 notifyListeners()로 자동 호출됨
  }

  AppLanguage get currentLanguage => AppLocale.current;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: '보물',
      themeMode: _themeMode,

      // ── flutter_quill 로컬라이제이션 추가
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        FlutterQuillLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('ko', 'KR'),
        Locale('en', 'US'),
        Locale('zh', 'CN'),
        Locale('zh', 'TW'),
      ],
      locale: AppLocale.current.locale,

      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorScheme: ColorScheme(
          brightness:         Brightness.light,
          primary:            Color(0xFF1B4F72),  // 네이비
          onPrimary:          Color(0xFFFFFFFF),
          primaryContainer:   Color(0xFFD6E8F5),
          onPrimaryContainer: Color(0xFF0D1B2A),
          secondary:          Color(0xFFC9A84C),  // 골드 포인트
          onSecondary:        Color(0xFFFFFFFF),
          secondaryContainer: Color(0xFFF5ECD7),
          onSecondaryContainer: Color(0xFF4A3700),
          surface:            Color(0xFFFFFFFF),
          onSurface:          Color(0xFF1A1A1A),
          surfaceContainerHighest: Color(0xFFF0F4F8),
          outline:            Color(0xFFE5E5EA),
          error:              Color(0xFFB00020),
          onError:            Color(0xFFFFFFFF),
          errorContainer:     Color(0xFFFFDAD6),
          onErrorContainer:   Color(0xFF410002),
        ),
        scaffoldBackgroundColor: const Color(0xFFF7F9FC),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFF7F9FC),
          foregroundColor: Color(0xFF1A1A1A),
          elevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(
            color: Color(0xFF1A1A1A),
            fontSize: 17,
            fontWeight: FontWeight.w700,
          ),
        ),
        cardTheme: CardThemeData(
          color: Color(0xFFFFFFFF),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(16)),
          ),
        ),
        dividerColor: Color(0xFFE5E5EA),
        filledButtonTheme: FilledButtonThemeData(
          style: ButtonStyle(
            backgroundColor: WidgetStatePropertyAll(Color(0xFF1B4F72)),
            foregroundColor: WidgetStatePropertyAll(Color(0xFFFFFFFF)),
            shape: WidgetStatePropertyAll(RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(14)),
            )),
          ),
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme(
          brightness:         Brightness.dark,
          primary:            Color(0xFFC9A84C),  // 골드
          onPrimary:          Color(0xFF0D1B2A),
          primaryContainer:   Color(0xFF2A3F55),
          onPrimaryContainer: Color(0xFFFFF0CC),
          secondary:          Color(0xFF7A90A4),  // 안개
          onSecondary:        Color(0xFF0D1B2A),
          secondaryContainer: Color(0xFF1B2D3F),
          onSecondaryContainer: Color(0xFFB8CFE0),
          surface:            Color(0xFF1B2D3F),  // 카드
          onSurface:          Color(0xFFE8E3D8),  // 텍스트
          surfaceContainerHighest: Color(0xFF243447),
          outline:            Color(0xFF2C3E50),
          error:              Color(0xFFCF6679),
          onError:            Color(0xFF0D1B2A),
          errorContainer:     Color(0xFF8B1A2A),
          onErrorContainer:   Color(0xFFFFDAD6),
        ),
        scaffoldBackgroundColor: const Color(0xFF0D1B2A),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF0D1B2A),
          foregroundColor: Color(0xFFE8E3D8),
          elevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(
            color: Color(0xFFE8E3D8),
            fontSize: 17,
            fontWeight: FontWeight.w700,
          ),
        ),
        cardTheme: CardThemeData(
          color: Color(0xFF1B2D3F),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(16)),
          ),
        ),
        dividerColor: Color(0xFF2C3E50),
        filledButtonTheme: FilledButtonThemeData(
          style: ButtonStyle(
            backgroundColor: WidgetStatePropertyAll(Color(0xFFC9A84C)),
            foregroundColor: WidgetStatePropertyAll(Color(0xFF0D1B2A)),
            shape: WidgetStatePropertyAll(RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(14)),
            )),
          ),
        ),
      ),
      home: const MainNavigationPage(),
    );
  }
}

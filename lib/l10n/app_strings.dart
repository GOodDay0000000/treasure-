// lib/l10n/app_strings.dart

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ── 지원 언어 (15개) ──────────────────────────────────────────
enum AppLanguage {
  ko('한국어',            '🇰🇷', Locale('ko')),
  en('English',           '🇺🇸', Locale('en')),
  zhCN('中文 简体',       '🇨🇳', Locale('zh', 'CN')),
  zhTW('中文 繁體',       '🇹🇼', Locale('zh', 'TW')),
  ja('日本語',            '🇯🇵', Locale('ja')),
  es('Español',           '🇪🇸', Locale('es')),
  fr('Français',          '🇫🇷', Locale('fr')),
  de('Deutsch',           '🇩🇪', Locale('de')),
  pt('Português',         '🇧🇷', Locale('pt')),
  ru('Русский',           '🇷🇺', Locale('ru')),
  id('Bahasa Indonesia',  '🇮🇩', Locale('id')),
  vi('Tiếng Việt',        '🇻🇳', Locale('vi')),
  th('ภาษาไทย',           '🇹🇭', Locale('th')),
  tl('Filipino',          '🇵🇭', Locale('fil')),
  sw('Kiswahili',         '🇰🇪', Locale('sw'));

  final String label;
  final String flag;
  final Locale locale;
  const AppLanguage(this.label, this.flag, this.locale);
}

// ── 현재 언어 상태 ────────────────────────────────────────────
class AppLocale extends ChangeNotifier {
  static final AppLocale _i = AppLocale._();
  factory AppLocale() => _i;
  AppLocale._();

  AppLanguage _lang = AppLanguage.ko;
  AppLanguage get lang => _lang;

  Future<void> load() async {
    final p    = await SharedPreferences.getInstance();
    final code = p.getString('app_language') ?? 'ko';
    _lang = AppLanguage.values.firstWhere(
        (l) => l.name == code, orElse: () => AppLanguage.ko);
    notifyListeners();
  }

  Future<void> setLanguage(AppLanguage lang) async {
    _lang = lang;
    final p = await SharedPreferences.getInstance();
    await p.setString('app_language', lang.name);
    notifyListeners();
  }

  static AppLocale get instance => _i;
  static AppLanguage get current => _i._lang;
  static S get s => S._(_i._lang);
}

// ── 문자열 접근자 ─────────────────────────────────────────────
class S {
  final AppLanguage _lang;
  const S._(this._lang);

  String _t(Map<AppLanguage, String> m) =>
      m[_lang] ?? m[AppLanguage.en] ?? m[AppLanguage.ko] ?? '';

  // ── 네비게이션 ────────────────────────────────────────────
  String get bible => _t({
    AppLanguage.ko: '성경',       AppLanguage.en: 'Bible',
    AppLanguage.zhCN: '圣经',     AppLanguage.zhTW: '聖經',
    AppLanguage.ja: '聖書',       AppLanguage.es: 'Biblia',
    AppLanguage.fr: 'Bible',      AppLanguage.de: 'Bibel',
    AppLanguage.pt: 'Bíblia',     AppLanguage.ru: 'Библия',
    AppLanguage.id: 'Alkitab',    AppLanguage.vi: 'Kinh Thánh',
    AppLanguage.th: 'พระคัมภีร์', AppLanguage.tl: 'Bibliya',
    AppLanguage.sw: 'Biblia',
  });

  String get browseBible => _t({
    AppLanguage.ko: '전체 보기',   AppLanguage.en: 'Browse Bible',
    AppLanguage.zhCN: '浏览圣经',  AppLanguage.zhTW: '瀏覽聖經',
    AppLanguage.ja: '聖書を開く',  AppLanguage.es: 'Ver Biblia',
    AppLanguage.fr: 'Parcourir',  AppLanguage.de: 'Bibel öffnen',
    AppLanguage.pt: 'Ver Bíblia', AppLanguage.ru: 'Открыть',
    AppLanguage.id: 'Buka',       AppLanguage.vi: 'Xem',
    AppLanguage.th: 'ดูทั้งหมด',  AppLanguage.tl: 'Tingnan',
    AppLanguage.sw: 'Fungua',
  });

  String get navBible => _t({
    AppLanguage.ko: '성경',       AppLanguage.en: 'Bible',
    AppLanguage.zhCN: '圣经',     AppLanguage.zhTW: '聖經',
    AppLanguage.ja: '聖書',       AppLanguage.es: 'Biblia',
    AppLanguage.fr: 'Bible',      AppLanguage.de: 'Bibel',
    AppLanguage.pt: 'Bíblia',     AppLanguage.ru: 'Библия',
    AppLanguage.id: 'Alkitab',    AppLanguage.vi: 'Kinh Thánh',
    AppLanguage.th: 'พระคัมภีร์', AppLanguage.tl: 'Bibliya',
    AppLanguage.sw: 'Biblia',
  });

  String get hymns => _t({
    AppLanguage.ko: '찬송가',     AppLanguage.en: 'Hymns',
    AppLanguage.zhCN: '诗歌',     AppLanguage.zhTW: '詩歌',
    AppLanguage.ja: '賛美歌',     AppLanguage.es: 'Himnos',
    AppLanguage.fr: 'Cantiques', AppLanguage.de: 'Lieder',
    AppLanguage.pt: 'Hinos',     AppLanguage.ru: 'Гимны',
    AppLanguage.id: 'Pujian',    AppLanguage.vi: 'Thánh Ca',
    AppLanguage.th: 'เพลงสรรเสริญ', AppLanguage.tl: 'Himno',
    AppLanguage.sw: 'Nyimbo',
  });

  String get koreanHymns => _t({
    AppLanguage.ko: '새찬송가',    AppLanguage.en: 'Korean Hymns',
    AppLanguage.zhCN: '韩国赞美诗', AppLanguage.zhTW: '韓國讚美詩',
    AppLanguage.ja: '韓国賛美歌',  AppLanguage.es: 'Himnos Coreanos',
    AppLanguage.fr: 'Cantiques Coréens', AppLanguage.de: 'Koreanische Lieder',
    AppLanguage.pt: 'Hinos Coreanos', AppLanguage.ru: 'Корейские Гимны',
    AppLanguage.id: 'Pujian Korea', AppLanguage.vi: 'Thánh Ca Hàn',
    AppLanguage.th: 'เพลงสรรเสริญเกาหลี', AppLanguage.tl: 'Himnong Korean',
    AppLanguage.sw: 'Nyimbo za Korea',
  });

  String get myScore => _t({
    AppLanguage.ko: '내 악보',    AppLanguage.en: 'My Scores',
    AppLanguage.zhCN: '我的乐谱', AppLanguage.zhTW: '我的樂譜',
    AppLanguage.ja: 'マイ楽譜',   AppLanguage.es: 'Mis Partituras',
    AppLanguage.fr: 'Mes Partitions', AppLanguage.de: 'Meine Noten',
    AppLanguage.pt: 'Minhas Partituras', AppLanguage.ru: 'Мои Ноты',
    AppLanguage.id: 'Partitturku', AppLanguage.vi: 'Nhạc của tôi',
    AppLanguage.th: 'โน้ตของฉัน', AppLanguage.tl: 'Aking Score',
    AppLanguage.sw: 'Noti Zangu',
  });

  String get downloadHymns => _t({
    AppLanguage.ko: '찬송가 다운로드', AppLanguage.en: 'Download Hymns',
    AppLanguage.zhCN: '下载诗歌',    AppLanguage.zhTW: '下載詩歌',
    AppLanguage.ja: '賛美歌をダウンロード', AppLanguage.es: 'Descargar Himnos',
    AppLanguage.fr: 'Télécharger', AppLanguage.de: 'Herunterladen',
    AppLanguage.pt: 'Baixar Hinos', AppLanguage.ru: 'Скачать Гимны',
    AppLanguage.id: 'Unduh Pujian', AppLanguage.vi: 'Tải Thánh Ca',
    AppLanguage.th: 'ดาวน์โหลดเพลง', AppLanguage.tl: 'I-download ang Himno',
    AppLanguage.sw: 'Pakua Nyimbo',
  });

  String get navHymn => _t({
    AppLanguage.ko: '찬송가',     AppLanguage.en: 'Hymns',
    AppLanguage.zhCN: '诗歌',     AppLanguage.zhTW: '詩歌',
    AppLanguage.ja: '賛美歌',     AppLanguage.es: 'Himnos',
    AppLanguage.fr: 'Cantiques', AppLanguage.de: 'Lieder',
    AppLanguage.pt: 'Hinos',     AppLanguage.ru: 'Гимны',
    AppLanguage.id: 'Pujian',    AppLanguage.vi: 'Thánh Ca',
    AppLanguage.th: 'เพลงสรรเสริญ', AppLanguage.tl: 'Himno',
    AppLanguage.sw: 'Nyimbo',
  });

  String get navActivity => _t({
    AppLanguage.ko: '활동',       AppLanguage.en: 'Activity',
    AppLanguage.zhCN: '活动',     AppLanguage.zhTW: '活動',
    AppLanguage.ja: '活動',       AppLanguage.es: 'Actividad',
    AppLanguage.fr: 'Activité',  AppLanguage.de: 'Aktivität',
    AppLanguage.pt: 'Atividade', AppLanguage.ru: 'Активность',
    AppLanguage.id: 'Aktivitas', AppLanguage.vi: 'Hoạt động',
    AppLanguage.th: 'กิจกรรม',   AppLanguage.tl: 'Aktibidad',
    AppLanguage.sw: 'Shughuli',
  });

  // ── 홈화면 ────────────────────────────────────────────────
  String get continueReading => _t({
    AppLanguage.ko: '이어읽기',        AppLanguage.en: 'Continue Reading',
    AppLanguage.zhCN: '继续阅读',      AppLanguage.zhTW: '繼續閱讀',
    AppLanguage.ja: '続きを読む',      AppLanguage.es: 'Continuar',
    AppLanguage.fr: 'Continuer',      AppLanguage.de: 'Weiterlesen',
    AppLanguage.pt: 'Continuar',      AppLanguage.ru: 'Продолжить',
    AppLanguage.id: 'Lanjutkan',      AppLanguage.vi: 'Tiếp tục đọc',
    AppLanguage.th: 'อ่านต่อ',         AppLanguage.tl: 'Ituloy ang Pagbabasa',
    AppLanguage.sw: 'Endelea Kusoma',
  });


  String get oldTestament => _t({
    AppLanguage.ko: '구약',       AppLanguage.en: 'Old Testament',
    AppLanguage.zhCN: '旧约',     AppLanguage.zhTW: '舊約',
    AppLanguage.ja: '旧約',       AppLanguage.es: 'Antiguo Testamento',
    AppLanguage.fr: 'Ancien Testament', AppLanguage.de: 'Altes Testament',
    AppLanguage.pt: 'Antigo Testamento', AppLanguage.ru: 'Ветхий Завет',
    AppLanguage.id: 'Perjanjian Lama', AppLanguage.vi: 'Cựu Ước',
    AppLanguage.th: 'พันธสัญญาเดิม', AppLanguage.tl: 'Lumang Tipan',
    AppLanguage.sw: 'Agano la Kale',
  });

  String get newTestament => _t({
    AppLanguage.ko: '신약',       AppLanguage.en: 'New Testament',
    AppLanguage.zhCN: '新约',     AppLanguage.zhTW: '新約',
    AppLanguage.ja: '新約',       AppLanguage.es: 'Nuevo Testamento',
    AppLanguage.fr: 'Nouveau Testament', AppLanguage.de: 'Neues Testament',
    AppLanguage.pt: 'Novo Testamento', AppLanguage.ru: 'Новый Завет',
    AppLanguage.id: 'Perjanjian Baru', AppLanguage.vi: 'Tân Ước',
    AppLanguage.th: 'พันธสัญญาใหม่', AppLanguage.tl: 'Bagong Tipan',
    AppLanguage.sw: 'Agano Jipya',
  });

  String chapter(int n) => _t({
    AppLanguage.ko: '$n장',        AppLanguage.en: 'Ch. $n',
    AppLanguage.zhCN: '第${n}章', AppLanguage.zhTW: '第${n}章',
    AppLanguage.ja: '第${n}章',   AppLanguage.es: 'Cap. $n',
    AppLanguage.fr: 'Ch. $n',     AppLanguage.de: 'Kap. $n',
    AppLanguage.pt: 'Cap. $n',    AppLanguage.ru: 'Гл. $n',
    AppLanguage.id: 'Ps. $n',     AppLanguage.vi: 'Chương $n',
    AppLanguage.th: 'บทที่ $n',   AppLanguage.tl: 'Kap. $n',
    AppLanguage.sw: 'Sura $n',
  });

  // ── 검색 ─────────────────────────────────────────────────
  String get search => _t({
    AppLanguage.ko: '검색',       AppLanguage.en: 'Search',
    AppLanguage.zhCN: '搜索',     AppLanguage.zhTW: '搜尋',
    AppLanguage.ja: '検索',       AppLanguage.es: 'Buscar',
    AppLanguage.fr: 'Rechercher', AppLanguage.de: 'Suchen',
    AppLanguage.pt: 'Pesquisar',  AppLanguage.ru: 'Поиск',
    AppLanguage.id: 'Cari',       AppLanguage.vi: 'Tìm kiếm',
    AppLanguage.th: 'ค้นหา',      AppLanguage.tl: 'Maghanap',
    AppLanguage.sw: 'Tafuta',
  });

  String searchResults(int n, String scope) => _t({
    AppLanguage.ko: '$scope에서 ${n}개의 결과를 찾았습니다',
    AppLanguage.en: 'Found $n results in $scope',
    AppLanguage.zhCN: '在$scope中找到${n}个结果',
    AppLanguage.zhTW: '在$scope中找到${n}個結果',
    AppLanguage.ja: '$scopeで${n}件見つかりました',
    AppLanguage.es: 'Se encontraron $n resultados en $scope',
    AppLanguage.fr: '$n résultats trouvés dans $scope',
    AppLanguage.de: '$n Ergebnisse in $scope gefunden',
    AppLanguage.pt: '$n resultados em $scope',
    AppLanguage.ru: 'Найдено $n результатов в $scope',
    AppLanguage.id: 'Ditemukan $n hasil di $scope',
    AppLanguage.vi: 'Tìm thấy $n kết quả trong $scope',
    AppLanguage.th: 'พบ $n ผลลัพธ์ใน $scope',
    AppLanguage.tl: 'Nahanap ang $n resulta sa $scope',
    AppLanguage.sw: 'Matokeo $n yamepatikana katika $scope',
  });

  String get sortByBook => _t({
    AppLanguage.ko: '책에 의해',      AppLanguage.en: 'By Book',
    AppLanguage.zhCN: '按书卷',       AppLanguage.zhTW: '按書卷',
    AppLanguage.ja: '書順',          AppLanguage.es: 'Por libro',
    AppLanguage.fr: 'Par livre',     AppLanguage.de: 'Nach Buch',
    AppLanguage.pt: 'Por livro',     AppLanguage.ru: 'По книге',
    AppLanguage.id: 'Berdasarkan buku', AppLanguage.vi: 'Theo sách',
    AppLanguage.th: 'ตามหนังสือ',    AppLanguage.tl: 'Ayon sa Aklat',
    AppLanguage.sw: 'Kwa kitabu',
  });

  String get sortByRelevance => _t({
    AppLanguage.ko: '관련성에 의해',  AppLanguage.en: 'By Relevance',
    AppLanguage.zhCN: '按相关性',     AppLanguage.zhTW: '按相關性',
    AppLanguage.ja: '関連度順',      AppLanguage.es: 'Por relevancia',
    AppLanguage.fr: 'Par pertinence', AppLanguage.de: 'Nach Relevanz',
    AppLanguage.pt: 'Por relevância', AppLanguage.ru: 'По релевантности',
    AppLanguage.id: 'Berdasarkan relevansi', AppLanguage.vi: 'Theo mức độ liên quan',
    AppLanguage.th: 'ตามความเกี่ยวข้อง', AppLanguage.tl: 'Ayon sa Kaugnayan',
    AppLanguage.sw: 'Kwa umuhimu',
  });

  // ── 설정 / 공통 ───────────────────────────────────────────
  String get darkMode => _t({
    AppLanguage.ko: '다크 모드',   AppLanguage.en: 'Dark Mode',
    AppLanguage.zhCN: '深色模式',  AppLanguage.zhTW: '深色模式',
    AppLanguage.ja: 'ダークモード', AppLanguage.es: 'Modo oscuro',
    AppLanguage.fr: 'Mode sombre', AppLanguage.de: 'Dunkelmodus',
    AppLanguage.pt: 'Modo escuro', AppLanguage.ru: 'Тёмный режим',
    AppLanguage.id: 'Mode gelap',  AppLanguage.vi: 'Chế độ tối',
    AppLanguage.th: 'โหมดมืด',    AppLanguage.tl: 'Dark Mode',
    AppLanguage.sw: 'Hali ya Giza',
  });

  String get fontSize => _t({
    AppLanguage.ko: '폰트 크기',   AppLanguage.en: 'Font Size',
    AppLanguage.zhCN: '字体大小',  AppLanguage.zhTW: '字體大小',
    AppLanguage.ja: '文字サイズ',  AppLanguage.es: 'Tamaño de fuente',
    AppLanguage.fr: 'Taille de police', AppLanguage.de: 'Schriftgröße',
    AppLanguage.pt: 'Tamanho da fonte', AppLanguage.ru: 'Размер шрифта',
    AppLanguage.id: 'Ukuran font', AppLanguage.vi: 'Cỡ chữ',
    AppLanguage.th: 'ขนาดตัวอักษร', AppLanguage.tl: 'Laki ng Font',
    AppLanguage.sw: 'Ukubwa wa fonti',
  });

  String get translation => _t({
    AppLanguage.ko: '번역본',      AppLanguage.en: 'Translation',
    AppLanguage.zhCN: '译本',      AppLanguage.zhTW: '譯本',
    AppLanguage.ja: '訳',          AppLanguage.es: 'Traducción',
    AppLanguage.fr: 'Traduction',  AppLanguage.de: 'Übersetzung',
    AppLanguage.pt: 'Tradução',    AppLanguage.ru: 'Перевод',
    AppLanguage.id: 'Terjemahan',  AppLanguage.vi: 'Bản dịch',
    AppLanguage.th: 'การแปล',      AppLanguage.tl: 'Salin',
    AppLanguage.sw: 'Tafsiri',
  });

  String get appLanguage => _t({
    AppLanguage.ko: '앱 언어',     AppLanguage.en: 'App Language',
    AppLanguage.zhCN: '应用语言',  AppLanguage.zhTW: '應用語言',
    AppLanguage.ja: 'アプリの言語', AppLanguage.es: 'Idioma de la app',
    AppLanguage.fr: 'Langue de l\'app', AppLanguage.de: 'App-Sprache',
    AppLanguage.pt: 'Idioma do app', AppLanguage.ru: 'Язык приложения',
    AppLanguage.id: 'Bahasa aplikasi', AppLanguage.vi: 'Ngôn ngữ ứng dụng',
    AppLanguage.th: 'ภาษาของแอป',  AppLanguage.tl: 'Wika ng App',
    AppLanguage.sw: 'Lugha ya programu',
  });

  String get cancel => _t({
    AppLanguage.ko: '취소',       AppLanguage.en: 'Cancel',
    AppLanguage.zhCN: '取消',     AppLanguage.zhTW: '取消',
    AppLanguage.ja: 'キャンセル', AppLanguage.es: 'Cancelar',
    AppLanguage.fr: 'Annuler',   AppLanguage.de: 'Abbrechen',
    AppLanguage.pt: 'Cancelar',  AppLanguage.ru: 'Отмена',
    AppLanguage.id: 'Batal',     AppLanguage.vi: 'Hủy',
    AppLanguage.th: 'ยกเลิก',    AppLanguage.tl: 'Kanselahin',
    AppLanguage.sw: 'Ghairi',
  });

  String get comingSoon => _t({
    AppLanguage.ko: '준비 중',        AppLanguage.en: 'Coming Soon',
    AppLanguage.zhCN: '即将推出',     AppLanguage.zhTW: '即將推出',
    AppLanguage.ja: '準備中',         AppLanguage.es: 'Próximamente',
    AppLanguage.fr: 'Bientôt',       AppLanguage.de: 'Demnächst',
    AppLanguage.pt: 'Em breve',      AppLanguage.ru: 'Скоро',
    AppLanguage.id: 'Segera hadir',  AppLanguage.vi: 'Sắp ra mắt',
    AppLanguage.th: 'เร็วๆ นี้',       AppLanguage.tl: 'Malapit na',
    AppLanguage.sw: 'Inakuja Hivi Karibuni',
  });

  String get bookmark => _t({
    AppLanguage.ko: '북마크',     AppLanguage.en: 'Bookmark',
    AppLanguage.zhCN: '书签',     AppLanguage.zhTW: '書籤',
    AppLanguage.ja: 'ブックマーク', AppLanguage.es: 'Marcador',
    AppLanguage.fr: 'Signet',    AppLanguage.de: 'Lesezeichen',
    AppLanguage.pt: 'Favorito',  AppLanguage.ru: 'Закладка',
    AppLanguage.id: 'Penanda',   AppLanguage.vi: 'Dấu trang',
    AppLanguage.th: 'ที่คั่น',    AppLanguage.tl: 'Bookmark',
    AppLanguage.sw: 'Alamisho',
  });

  String get memo => _t({
    AppLanguage.ko: '메모',      AppLanguage.en: 'Note',
    AppLanguage.zhCN: '笔记',    AppLanguage.zhTW: '筆記',
    AppLanguage.ja: 'メモ',      AppLanguage.es: 'Nota',
    AppLanguage.fr: 'Note',     AppLanguage.de: 'Notiz',
    AppLanguage.pt: 'Nota',     AppLanguage.ru: 'Заметка',
    AppLanguage.id: 'Catatan',  AppLanguage.vi: 'Ghi chú',
    AppLanguage.th: 'บันทึก',   AppLanguage.tl: 'Tala',
    AppLanguage.sw: 'Kumbukumbu',
  });

  String get dictionary => _t({
    AppLanguage.ko: '사전',        AppLanguage.en: 'Dictionary',
    AppLanguage.zhCN: '词典',      AppLanguage.zhTW: '詞典',
    AppLanguage.ja: '辞書',        AppLanguage.es: 'Diccionario',
    AppLanguage.fr: 'Dictionnaire', AppLanguage.de: 'Wörterbuch',
    AppLanguage.pt: 'Dicionário',  AppLanguage.ru: 'Словарь',
    AppLanguage.id: 'Kamus',       AppLanguage.vi: 'Từ điển',
    AppLanguage.th: 'พจนานุกรม',   AppLanguage.tl: 'Diksyonaryo',
    AppLanguage.sw: 'Kamusi',
  });

  String get normalMode => _t({
    AppLanguage.ko: '일반 모드',   AppLanguage.en: 'Normal Mode',
    AppLanguage.zhCN: '普通模式',  AppLanguage.zhTW: '普通模式',
    AppLanguage.ja: '通常モード',  AppLanguage.es: 'Modo normal',
    AppLanguage.fr: 'Mode normal', AppLanguage.de: 'Normalmodus',
    AppLanguage.pt: 'Modo normal', AppLanguage.ru: 'Обычный режим',
    AppLanguage.id: 'Mode normal', AppLanguage.vi: 'Chế độ thường',
    AppLanguage.th: 'โหมดปกติ',   AppLanguage.tl: 'Normal Mode',
    AppLanguage.sw: 'Hali ya Kawaida',
  });

  String get classicMode => _t({
    AppLanguage.ko: '클래식 모드',  AppLanguage.en: 'Classic Mode',
    AppLanguage.zhCN: '经典模式',   AppLanguage.zhTW: '經典模式',
    AppLanguage.ja: 'クラシックモード', AppLanguage.es: 'Modo clásico',
    AppLanguage.fr: 'Mode classique', AppLanguage.de: 'Klassischer Modus',
    AppLanguage.pt: 'Modo clássico', AppLanguage.ru: 'Классический режим',
    AppLanguage.id: 'Mode klasik',  AppLanguage.vi: 'Chế độ cổ điển',
    AppLanguage.th: 'โหมดคลาสสิก', AppLanguage.tl: 'Classic Mode',
    AppLanguage.sw: 'Hali ya Kawaida',
  });

  String get nextChapter => _t({
    AppLanguage.ko: '다음 장',      AppLanguage.en: 'Next',
    AppLanguage.zhCN: '下一章',     AppLanguage.zhTW: '下一章',
    AppLanguage.ja: '次の章',       AppLanguage.es: 'Siguiente',
    AppLanguage.fr: 'Suivant',     AppLanguage.de: 'Weiter',
    AppLanguage.pt: 'Próximo',     AppLanguage.ru: 'Далее',
    AppLanguage.id: 'Selanjutnya', AppLanguage.vi: 'Tiếp theo',
    AppLanguage.th: 'ถัดไป',       AppLanguage.tl: 'Susunod',
    AppLanguage.sw: 'Ifuatayo',
  });

  String get commentary => _t({
    AppLanguage.ko: '주석',         AppLanguage.en: 'Commentary',
    AppLanguage.zhCN: '注释',       AppLanguage.zhTW: '註釋',
    AppLanguage.ja: '注解',         AppLanguage.es: 'Comentario',
    AppLanguage.fr: 'Commentaire', AppLanguage.de: 'Kommentar',
    AppLanguage.pt: 'Comentário',  AppLanguage.ru: 'Комментарий',
    AppLanguage.id: 'Komentar',    AppLanguage.vi: 'Chú giải',
    AppLanguage.th: 'คำอธิบาย',    AppLanguage.tl: 'Komentaryo',
    AppLanguage.sw: 'Maelezo',
  });

  String get myPage => _t({
    AppLanguage.ko: '마이페이지',  AppLanguage.en: 'My Page',
    AppLanguage.zhCN: '我的',      AppLanguage.zhTW: '我的',
    AppLanguage.ja: 'マイページ',  AppLanguage.es: 'Mi página',
    AppLanguage.fr: 'Mon profil', AppLanguage.de: 'Mein Profil',
    AppLanguage.pt: 'Meu perfil', AppLanguage.ru: 'Мой профиль',
    AppLanguage.id: 'Halaman saya', AppLanguage.vi: 'Trang của tôi',
    AppLanguage.th: 'หน้าของฉัน', AppLanguage.tl: 'Aking Pahina',
    AppLanguage.sw: 'Ukurasa Wangu',
  });

  String get readingSettings => _t({
    AppLanguage.ko: '읽기 설정',   AppLanguage.en: 'Reading',
    AppLanguage.zhCN: '阅读设置',  AppLanguage.zhTW: '閱讀設定',
    AppLanguage.ja: '読書設定',    AppLanguage.es: 'Lectura',
    AppLanguage.fr: 'Lecture',    AppLanguage.de: 'Lesen',
    AppLanguage.pt: 'Leitura',    AppLanguage.ru: 'Чтение',
    AppLanguage.id: 'Membaca',    AppLanguage.vi: 'Đọc',
    AppLanguage.th: 'การอ่าน',    AppLanguage.tl: 'Pagbabasa',
    AppLanguage.sw: 'Kusoma',
  });

  String get displaySettings => _t({
    AppLanguage.ko: '화면 설정',   AppLanguage.en: 'Display',
    AppLanguage.zhCN: '显示设置',  AppLanguage.zhTW: '顯示設定',
    AppLanguage.ja: '表示設定',    AppLanguage.es: 'Pantalla',
    AppLanguage.fr: 'Affichage',  AppLanguage.de: 'Anzeige',
    AppLanguage.pt: 'Exibição',   AppLanguage.ru: 'Экран',
    AppLanguage.id: 'Tampilan',   AppLanguage.vi: 'Hiển thị',
    AppLanguage.th: 'การแสดงผล',  AppLanguage.tl: 'Display',
    AppLanguage.sw: 'Onyesho',
  });

  String get version => _t({
    AppLanguage.ko: '버전',       AppLanguage.en: 'Version',
    AppLanguage.zhCN: '版本',     AppLanguage.zhTW: '版本',
    AppLanguage.ja: 'バージョン', AppLanguage.es: 'Versión',
    AppLanguage.fr: 'Version',   AppLanguage.de: 'Version',
    AppLanguage.pt: 'Versão',    AppLanguage.ru: 'Версия',
    AppLanguage.id: 'Versi',     AppLanguage.vi: 'Phiên bản',
    AppLanguage.th: 'เวอร์ชัน',  AppLanguage.tl: 'Bersyon',
    AppLanguage.sw: 'Toleo',
  });

  String get appInfo => _t({
    AppLanguage.ko: '앱 정보',     AppLanguage.en: 'App Info',
    AppLanguage.zhCN: '应用信息',  AppLanguage.zhTW: '應用資訊',
    AppLanguage.ja: 'アプリ情報',  AppLanguage.es: 'Info de la app',
    AppLanguage.fr: 'Info app',   AppLanguage.de: 'App-Info',
    AppLanguage.pt: 'Info do app', AppLanguage.ru: 'О приложении',
    AppLanguage.id: 'Info aplikasi', AppLanguage.vi: 'Thông tin ứng dụng',
    AppLanguage.th: 'ข้อมูลแอป',  AppLanguage.tl: 'Info ng App',
    AppLanguage.sw: 'Maelezo ya programu',
  });
}

// ── 성경 책 이름 번역 ─────────────────────────────────────────
class BibleBookNames {
  static String get(String key, AppLanguage lang) =>
      _names[key]?[lang] ?? _names[key]?[AppLanguage.ko] ?? key;

  static final Map<String, Map<AppLanguage, String>> _names = {
    // 구약
    'genesis':       {AppLanguage.ko:'창세기',       AppLanguage.en:'Genesis',        AppLanguage.zhCN:'创世记',    AppLanguage.zhTW:'創世記',    AppLanguage.ja:'創世記',       AppLanguage.es:'Génesis',      AppLanguage.fr:'Genèse',       AppLanguage.de:'Genesis',      AppLanguage.pt:'Gênesis',     AppLanguage.ru:'Бытие',        AppLanguage.id:'Kejadian',     AppLanguage.vi:'Sáng Thế Ký',   AppLanguage.th:'ปฐมกาล',       AppLanguage.tl:'Genesis',     AppLanguage.sw:'Mwanzo'},
    'exodus':        {AppLanguage.ko:'출애굽기',      AppLanguage.en:'Exodus',         AppLanguage.zhCN:'出埃及记',  AppLanguage.zhTW:'出埃及記',  AppLanguage.ja:'出エジプト記',  AppLanguage.es:'Éxodo',        AppLanguage.fr:'Exode',        AppLanguage.de:'Exodus',       AppLanguage.pt:'Êxodo',       AppLanguage.ru:'Исход',        AppLanguage.id:'Keluaran',     AppLanguage.vi:'Xuất Ai Cập',   AppLanguage.th:'อพยพ',         AppLanguage.tl:'Exodo',       AppLanguage.sw:'Kutoka'},
    'leviticus':     {AppLanguage.ko:'레위기',        AppLanguage.en:'Leviticus',      AppLanguage.zhCN:'利未记',    AppLanguage.zhTW:'利未記',    AppLanguage.ja:'レビ記',        AppLanguage.es:'Levítico',     AppLanguage.fr:'Lévitique',    AppLanguage.de:'Levitikus',    AppLanguage.pt:'Levítico',    AppLanguage.ru:'Левит',        AppLanguage.id:'Imamat',       AppLanguage.vi:'Lê-vi Ký',      AppLanguage.th:'เลวีนิติ',     AppLanguage.tl:'Levitico',    AppLanguage.sw:'Mambo ya Walawi'},
    'numbers':       {AppLanguage.ko:'민수기',        AppLanguage.en:'Numbers',        AppLanguage.zhCN:'民数记',    AppLanguage.zhTW:'民數記',    AppLanguage.ja:'民数記',        AppLanguage.es:'Números',      AppLanguage.fr:'Nombres',      AppLanguage.de:'Numeri',       AppLanguage.pt:'Números',     AppLanguage.ru:'Числа',        AppLanguage.id:'Bilangan',     AppLanguage.vi:'Dân Số Ký',     AppLanguage.th:'กันดารวิถี',   AppLanguage.tl:'Mga Bilang',  AppLanguage.sw:'Hesabu'},
    'deuteronomy':   {AppLanguage.ko:'신명기',        AppLanguage.en:'Deuteronomy',    AppLanguage.zhCN:'申命记',    AppLanguage.zhTW:'申命記',    AppLanguage.ja:'申命記',        AppLanguage.es:'Deuteronomio', AppLanguage.fr:'Deutéronome',  AppLanguage.de:'Deuteronomium',AppLanguage.pt:'Deuteronômio',AppLanguage.ru:'Второзаконие', AppLanguage.id:'Ulangan',      AppLanguage.vi:'Phục Truyền',   AppLanguage.th:'เฉลยธรรมบัญญัติ',AppLanguage.tl:'Deuteronomio',AppLanguage.sw:'Kumbukumbu la Torati'},
    'joshua':        {AppLanguage.ko:'여호수아',      AppLanguage.en:'Joshua',         AppLanguage.zhCN:'约书亚记',  AppLanguage.zhTW:'約書亞記',  AppLanguage.ja:'ヨシュア記',    AppLanguage.es:'Josué',        AppLanguage.fr:'Josué',        AppLanguage.de:'Josua',        AppLanguage.pt:'Josué',       AppLanguage.ru:'Иисус Навин',  AppLanguage.id:'Yosua',        AppLanguage.vi:'Giô-suê',       AppLanguage.th:'โยชูวา',       AppLanguage.tl:'Josue',       AppLanguage.sw:'Yoshua'},
    'judges':        {AppLanguage.ko:'사사기',        AppLanguage.en:'Judges',         AppLanguage.zhCN:'士师记',    AppLanguage.zhTW:'士師記',    AppLanguage.ja:'士師記',        AppLanguage.es:'Jueces',       AppLanguage.fr:'Juges',        AppLanguage.de:'Richter',      AppLanguage.pt:'Juízes',      AppLanguage.ru:'Судьи',        AppLanguage.id:'Hakim-hakim',  AppLanguage.vi:'Các Quan Xét',  AppLanguage.th:'ผู้วินิจฉัย',  AppLanguage.tl:'Mga Hukom',   AppLanguage.sw:'Waamuzi'},
    'ruth':          {AppLanguage.ko:'룻기',          AppLanguage.en:'Ruth',           AppLanguage.zhCN:'路得记',    AppLanguage.zhTW:'路得記',    AppLanguage.ja:'ルツ記',        AppLanguage.es:'Rut',          AppLanguage.fr:'Ruth',         AppLanguage.de:'Ruth',         AppLanguage.pt:'Rute',        AppLanguage.ru:'Руфь',         AppLanguage.id:'Rut',          AppLanguage.vi:'Ru-tơ',         AppLanguage.th:'นางรูธ',       AppLanguage.tl:'Ruth',        AppLanguage.sw:'Ruthi'},
    '1samuel':       {AppLanguage.ko:'사무엘상',      AppLanguage.en:'1 Samuel',       AppLanguage.zhCN:'撒母耳记上',AppLanguage.zhTW:'撒母耳記上',AppLanguage.ja:'サムエル記上',  AppLanguage.es:'1 Samuel',     AppLanguage.fr:'1 Samuel',     AppLanguage.de:'1 Samuel',     AppLanguage.pt:'1 Samuel',    AppLanguage.ru:'1 Царств',     AppLanguage.id:'1 Samuel',     AppLanguage.vi:'1 Sa-mu-ên',    AppLanguage.th:'1 ซามูเอล',    AppLanguage.tl:'1 Samuel',    AppLanguage.sw:'1 Samweli'},
    '2samuel':       {AppLanguage.ko:'사무엘하',      AppLanguage.en:'2 Samuel',       AppLanguage.zhCN:'撒母耳记下',AppLanguage.zhTW:'撒母耳記下',AppLanguage.ja:'サムエル記下',  AppLanguage.es:'2 Samuel',     AppLanguage.fr:'2 Samuel',     AppLanguage.de:'2 Samuel',     AppLanguage.pt:'2 Samuel',    AppLanguage.ru:'2 Царств',     AppLanguage.id:'2 Samuel',     AppLanguage.vi:'2 Sa-mu-ên',    AppLanguage.th:'2 ซามูเอล',    AppLanguage.tl:'2 Samuel',    AppLanguage.sw:'2 Samweli'},
    '1kings':        {AppLanguage.ko:'열왕기상',      AppLanguage.en:'1 Kings',        AppLanguage.zhCN:'列王纪上',  AppLanguage.zhTW:'列王紀上',  AppLanguage.ja:'列王記上',      AppLanguage.es:'1 Reyes',      AppLanguage.fr:'1 Rois',       AppLanguage.de:'1 Könige',     AppLanguage.pt:'1 Reis',      AppLanguage.ru:'3 Царств',     AppLanguage.id:'1 Raja-raja',  AppLanguage.vi:'1 Các Vua',     AppLanguage.th:'1 พงศ์กษัตริย์',AppLanguage.tl:'1 Mga Hari',  AppLanguage.sw:'1 Wafalme'},
    '2kings':        {AppLanguage.ko:'열왕기하',      AppLanguage.en:'2 Kings',        AppLanguage.zhCN:'列王纪下',  AppLanguage.zhTW:'列王紀下',  AppLanguage.ja:'列王記下',      AppLanguage.es:'2 Reyes',      AppLanguage.fr:'2 Rois',       AppLanguage.de:'2 Könige',     AppLanguage.pt:'2 Reis',      AppLanguage.ru:'4 Царств',     AppLanguage.id:'2 Raja-raja',  AppLanguage.vi:'2 Các Vua',     AppLanguage.th:'2 พงศ์กษัตริย์',AppLanguage.tl:'2 Mga Hari',  AppLanguage.sw:'2 Wafalme'},
    '1chronicles':   {AppLanguage.ko:'역대상',        AppLanguage.en:'1 Chronicles',   AppLanguage.zhCN:'历代志上',  AppLanguage.zhTW:'歷代志上',  AppLanguage.ja:'歴代誌上',      AppLanguage.es:'1 Crónicas',   AppLanguage.fr:'1 Chroniques', AppLanguage.de:'1 Chronik',    AppLanguage.pt:'1 Crônicas',  AppLanguage.ru:'1 Паралипоменон',AppLanguage.id:'1 Tawarikh',  AppLanguage.vi:'1 Sử Ký',       AppLanguage.th:'1 พงศาวดาร',   AppLanguage.tl:'1 Cronica',   AppLanguage.sw:'1 Mambo ya Nyakati'},
    '2chronicles':   {AppLanguage.ko:'역대하',        AppLanguage.en:'2 Chronicles',   AppLanguage.zhCN:'历代志下',  AppLanguage.zhTW:'歷代志下',  AppLanguage.ja:'歴代誌下',      AppLanguage.es:'2 Crónicas',   AppLanguage.fr:'2 Chroniques', AppLanguage.de:'2 Chronik',    AppLanguage.pt:'2 Crônicas',  AppLanguage.ru:'2 Паралипоменон',AppLanguage.id:'2 Tawarikh',  AppLanguage.vi:'2 Sử Ký',       AppLanguage.th:'2 พงศาวดาร',   AppLanguage.tl:'2 Cronica',   AppLanguage.sw:'2 Mambo ya Nyakati'},
    'ezra':          {AppLanguage.ko:'에스라',        AppLanguage.en:'Ezra',           AppLanguage.zhCN:'以斯拉记',  AppLanguage.zhTW:'以斯拉記',  AppLanguage.ja:'エズラ記',      AppLanguage.es:'Esdras',       AppLanguage.fr:'Esdras',       AppLanguage.de:'Esra',         AppLanguage.pt:'Esdras',      AppLanguage.ru:'Ездра',        AppLanguage.id:'Ezra',         AppLanguage.vi:'Ê-xơ-ra',       AppLanguage.th:'เอสรา',        AppLanguage.tl:'Ezra',        AppLanguage.sw:'Ezra'},
    'nehemiah':      {AppLanguage.ko:'느헤미야',      AppLanguage.en:'Nehemiah',       AppLanguage.zhCN:'尼希米记',  AppLanguage.zhTW:'尼希米記',  AppLanguage.ja:'ネヘミヤ記',    AppLanguage.es:'Nehemías',     AppLanguage.fr:'Néhémie',      AppLanguage.de:'Nehemia',      AppLanguage.pt:'Neemias',     AppLanguage.ru:'Неемия',       AppLanguage.id:'Nehemia',      AppLanguage.vi:'Nê-hê-mi',      AppLanguage.th:'เนหะมีย์',     AppLanguage.tl:'Nehemias',    AppLanguage.sw:'Nehemia'},
    'esther':        {AppLanguage.ko:'에스더',        AppLanguage.en:'Esther',         AppLanguage.zhCN:'以斯帖记',  AppLanguage.zhTW:'以斯帖記',  AppLanguage.ja:'エステル記',    AppLanguage.es:'Ester',        AppLanguage.fr:'Esther',       AppLanguage.de:'Ester',        AppLanguage.pt:'Ester',       AppLanguage.ru:'Есфирь',       AppLanguage.id:'Ester',        AppLanguage.vi:'Ê-xơ-tê',       AppLanguage.th:'เอสเธอร์',     AppLanguage.tl:'Ester',       AppLanguage.sw:'Esta'},
    'job':           {AppLanguage.ko:'욥기',          AppLanguage.en:'Job',            AppLanguage.zhCN:'约伯记',    AppLanguage.zhTW:'約伯記',    AppLanguage.ja:'ヨブ記',        AppLanguage.es:'Job',          AppLanguage.fr:'Job',          AppLanguage.de:'Hiob',         AppLanguage.pt:'Jó',          AppLanguage.ru:'Иов',          AppLanguage.id:'Ayub',         AppLanguage.vi:'Gióp',          AppLanguage.th:'โยบ',          AppLanguage.tl:'Job',         AppLanguage.sw:'Ayubu'},
    'psalms':        {AppLanguage.ko:'시편',          AppLanguage.en:'Psalms',         AppLanguage.zhCN:'诗篇',      AppLanguage.zhTW:'詩篇',      AppLanguage.ja:'詩篇',          AppLanguage.es:'Salmos',       AppLanguage.fr:'Psaumes',      AppLanguage.de:'Psalmen',      AppLanguage.pt:'Salmos',      AppLanguage.ru:'Псалтирь',     AppLanguage.id:'Mazmur',       AppLanguage.vi:'Thi Thiên',     AppLanguage.th:'สดุดี',        AppLanguage.tl:'Mga Awit',    AppLanguage.sw:'Zaburi'},
    'proverbs':      {AppLanguage.ko:'잠언',          AppLanguage.en:'Proverbs',       AppLanguage.zhCN:'箴言',      AppLanguage.zhTW:'箴言',      AppLanguage.ja:'箴言',          AppLanguage.es:'Proverbios',   AppLanguage.fr:'Proverbes',    AppLanguage.de:'Sprüche',      AppLanguage.pt:'Provérbios',  AppLanguage.ru:'Притчи',       AppLanguage.id:'Amsal',        AppLanguage.vi:'Châm Ngôn',     AppLanguage.th:'สุภาษิต',      AppLanguage.tl:'Kawikaan',    AppLanguage.sw:'Mithali'},
    'ecclesiastes':  {AppLanguage.ko:'전도서',        AppLanguage.en:'Ecclesiastes',   AppLanguage.zhCN:'传道书',    AppLanguage.zhTW:'傳道書',    AppLanguage.ja:'伝道の書',      AppLanguage.es:'Eclesiastés',  AppLanguage.fr:'Ecclésiaste',  AppLanguage.de:'Prediger',     AppLanguage.pt:'Eclesiastes', AppLanguage.ru:'Екклесиаст',   AppLanguage.id:'Pengkhotbah',  AppLanguage.vi:'Truyền Đạo',    AppLanguage.th:'ปัญญาจารย์',  AppLanguage.tl:'Eclesiastes', AppLanguage.sw:'Mhubiri'},
    'songofsolomon': {AppLanguage.ko:'아가',          AppLanguage.en:'Song of Solomon',AppLanguage.zhCN:'雅歌',      AppLanguage.zhTW:'雅歌',      AppLanguage.ja:'雅歌',          AppLanguage.es:'Cantares',     AppLanguage.fr:'Cantique',     AppLanguage.de:'Hohelied',     AppLanguage.pt:'Cânticos',    AppLanguage.ru:'Песня Песней', AppLanguage.id:'Kidung Agung',  AppLanguage.vi:'Nhã Ca',        AppLanguage.th:'เพลงซาโลมอน',  AppLanguage.tl:'Awit ni Solomon',AppLanguage.sw:'Wimbo wa Sulemani'},
    'isaiah':        {AppLanguage.ko:'이사야',        AppLanguage.en:'Isaiah',         AppLanguage.zhCN:'以赛亚书',  AppLanguage.zhTW:'以賽亞書',  AppLanguage.ja:'イザヤ書',      AppLanguage.es:'Isaías',       AppLanguage.fr:'Ésaïe',        AppLanguage.de:'Jesaja',       AppLanguage.pt:'Isaías',      AppLanguage.ru:'Исаия',        AppLanguage.id:'Yesaya',       AppLanguage.vi:'Ê-sai',         AppLanguage.th:'อิสยาห์',      AppLanguage.tl:'Isaias',      AppLanguage.sw:'Isaya'},
    'jeremiah':      {AppLanguage.ko:'예레미야',      AppLanguage.en:'Jeremiah',       AppLanguage.zhCN:'耶利米书',  AppLanguage.zhTW:'耶利米書',  AppLanguage.ja:'エレミヤ書',    AppLanguage.es:'Jeremías',     AppLanguage.fr:'Jérémie',      AppLanguage.de:'Jeremia',      AppLanguage.pt:'Jeremias',    AppLanguage.ru:'Иеремия',      AppLanguage.id:'Yeremia',      AppLanguage.vi:'Giê-rê-mi',     AppLanguage.th:'เยเรมีย์',     AppLanguage.tl:'Jeremias',    AppLanguage.sw:'Yeremia'},
    'lamentations':  {AppLanguage.ko:'예레미야애가',  AppLanguage.en:'Lamentations',   AppLanguage.zhCN:'耶利米哀歌',AppLanguage.zhTW:'耶利米哀歌',AppLanguage.ja:'哀歌',          AppLanguage.es:'Lamentaciones',AppLanguage.fr:'Lamentations', AppLanguage.de:'Klagelieder',  AppLanguage.pt:'Lamentações', AppLanguage.ru:'Плач Иеремии', AppLanguage.id:'Ratapan',      AppLanguage.vi:'Ca Thương',     AppLanguage.th:'เพลงคร่ำครวญ', AppLanguage.tl:'Mga Panaghoy', AppLanguage.sw:'Maombolezo'},
    'ezekiel':       {AppLanguage.ko:'에스겔',        AppLanguage.en:'Ezekiel',        AppLanguage.zhCN:'以西结书',  AppLanguage.zhTW:'以西結書',  AppLanguage.ja:'エゼキエル書',  AppLanguage.es:'Ezequiel',     AppLanguage.fr:'Ézéchiel',     AppLanguage.de:'Hesekiel',     AppLanguage.pt:'Ezequiel',    AppLanguage.ru:'Иезекииль',    AppLanguage.id:'Yehezkiel',    AppLanguage.vi:'Ê-xê-chi-ên',   AppLanguage.th:'เอเสเคียล',    AppLanguage.tl:'Ezekiel',     AppLanguage.sw:'Ezekieli'},
    'daniel':        {AppLanguage.ko:'다니엘',        AppLanguage.en:'Daniel',         AppLanguage.zhCN:'但以理书',  AppLanguage.zhTW:'但以理書',  AppLanguage.ja:'ダニエル書',    AppLanguage.es:'Daniel',       AppLanguage.fr:'Daniel',       AppLanguage.de:'Daniel',       AppLanguage.pt:'Daniel',      AppLanguage.ru:'Даниил',       AppLanguage.id:'Daniel',       AppLanguage.vi:'Đa-ni-ên',      AppLanguage.th:'ดาเนียล',      AppLanguage.tl:'Daniel',      AppLanguage.sw:'Danieli'},
    'hosea':         {AppLanguage.ko:'호세아',        AppLanguage.en:'Hosea',          AppLanguage.zhCN:'何西阿书',  AppLanguage.zhTW:'何西阿書',  AppLanguage.ja:'ホセア書',      AppLanguage.es:'Oseas',        AppLanguage.fr:'Osée',         AppLanguage.de:'Hosea',        AppLanguage.pt:'Oséias',      AppLanguage.ru:'Осия',         AppLanguage.id:'Hosea',        AppLanguage.vi:'Ô-sê',          AppLanguage.th:'โฮเชยา',       AppLanguage.tl:'Oseas',       AppLanguage.sw:'Hosea'},
    'joel':          {AppLanguage.ko:'요엘',          AppLanguage.en:'Joel',           AppLanguage.zhCN:'约珥书',    AppLanguage.zhTW:'約珥書',    AppLanguage.ja:'ヨエル書',      AppLanguage.es:'Joel',         AppLanguage.fr:'Joël',         AppLanguage.de:'Joel',         AppLanguage.pt:'Joel',        AppLanguage.ru:'Иоиль',        AppLanguage.id:'Yoel',         AppLanguage.vi:'Giô-ên',        AppLanguage.th:'โยเอล',        AppLanguage.tl:'Joel',        AppLanguage.sw:'Yoeli'},
    'amos':          {AppLanguage.ko:'아모스',        AppLanguage.en:'Amos',           AppLanguage.zhCN:'阿摩司书',  AppLanguage.zhTW:'阿摩司書',  AppLanguage.ja:'アモス書',      AppLanguage.es:'Amós',         AppLanguage.fr:'Amos',         AppLanguage.de:'Amos',         AppLanguage.pt:'Amós',        AppLanguage.ru:'Амос',         AppLanguage.id:'Amos',         AppLanguage.vi:'A-mốt',         AppLanguage.th:'อาโมส',        AppLanguage.tl:'Amos',        AppLanguage.sw:'Amosi'},
    'obadiah':       {AppLanguage.ko:'오바댜',        AppLanguage.en:'Obadiah',        AppLanguage.zhCN:'俄巴底亚书',AppLanguage.zhTW:'俄巴底亞書',AppLanguage.ja:'オバデヤ書',    AppLanguage.es:'Abdías',       AppLanguage.fr:'Abdias',       AppLanguage.de:'Obadja',       AppLanguage.pt:'Obadias',     AppLanguage.ru:'Авдий',        AppLanguage.id:'Obaja',        AppLanguage.vi:'Áp-đia',        AppLanguage.th:'โอบาดีห์',     AppLanguage.tl:'Abdias',      AppLanguage.sw:'Obadia'},
    'jonah':         {AppLanguage.ko:'요나',          AppLanguage.en:'Jonah',          AppLanguage.zhCN:'约拿书',    AppLanguage.zhTW:'約拿書',    AppLanguage.ja:'ヨナ書',        AppLanguage.es:'Jonás',        AppLanguage.fr:'Jonas',        AppLanguage.de:'Jona',         AppLanguage.pt:'Jonas',       AppLanguage.ru:'Иона',         AppLanguage.id:'Yunus',        AppLanguage.vi:'Giô-na',        AppLanguage.th:'โยนาห์',       AppLanguage.tl:'Jonas',       AppLanguage.sw:'Yona'},
    'micah':         {AppLanguage.ko:'미가',          AppLanguage.en:'Micah',          AppLanguage.zhCN:'弥迦书',    AppLanguage.zhTW:'彌迦書',    AppLanguage.ja:'ミカ書',        AppLanguage.es:'Miqueas',      AppLanguage.fr:'Michée',       AppLanguage.de:'Micha',        AppLanguage.pt:'Miquéias',    AppLanguage.ru:'Михей',        AppLanguage.id:'Mikha',        AppLanguage.vi:'Mi-chê',        AppLanguage.th:'มีคาห์',       AppLanguage.tl:'Mikas',       AppLanguage.sw:'Mika'},
    'nahum':         {AppLanguage.ko:'나훔',          AppLanguage.en:'Nahum',          AppLanguage.zhCN:'那鸿书',    AppLanguage.zhTW:'那鴻書',    AppLanguage.ja:'ナホム書',      AppLanguage.es:'Nahúm',        AppLanguage.fr:'Nahum',        AppLanguage.de:'Nahum',        AppLanguage.pt:'Naum',        AppLanguage.ru:'Наум',         AppLanguage.id:'Nahum',        AppLanguage.vi:'Na-hum',        AppLanguage.th:'นาฮูม',        AppLanguage.tl:'Nahum',       AppLanguage.sw:'Nahumu'},
    'habakkuk':      {AppLanguage.ko:'하박국',        AppLanguage.en:'Habakkuk',       AppLanguage.zhCN:'哈巴谷书',  AppLanguage.zhTW:'哈巴谷書',  AppLanguage.ja:'ハバクク書',    AppLanguage.es:'Habacuc',      AppLanguage.fr:'Habacuc',      AppLanguage.de:'Habakuk',      AppLanguage.pt:'Habacuque',   AppLanguage.ru:'Аввакум',      AppLanguage.id:'Habakuk',      AppLanguage.vi:'Ha-ba-cúc',     AppLanguage.th:'ฮาบากุก',      AppLanguage.tl:'Habakuk',     AppLanguage.sw:'Habakuki'},
    'zephaniah':     {AppLanguage.ko:'스바냐',        AppLanguage.en:'Zephaniah',      AppLanguage.zhCN:'西番雅书',  AppLanguage.zhTW:'西番雅書',  AppLanguage.ja:'ゼパニヤ書',    AppLanguage.es:'Sofonías',     AppLanguage.fr:'Sophonie',     AppLanguage.de:'Zefanja',      AppLanguage.pt:'Sofonias',    AppLanguage.ru:'Софония',      AppLanguage.id:'Zefanya',      AppLanguage.vi:'Sô-phô-ni',     AppLanguage.th:'เศฟันยาห์',    AppLanguage.tl:'Sofonias',    AppLanguage.sw:'Sefania'},
    'haggai':        {AppLanguage.ko:'학개',          AppLanguage.en:'Haggai',         AppLanguage.zhCN:'哈该书',    AppLanguage.zhTW:'哈該書',    AppLanguage.ja:'ハガイ書',      AppLanguage.es:'Hageo',        AppLanguage.fr:'Aggée',        AppLanguage.de:'Haggai',       AppLanguage.pt:'Ageu',        AppLanguage.ru:'Аггей',        AppLanguage.id:'Hagai',        AppLanguage.vi:'A-ghê',         AppLanguage.th:'ฮักกัย',       AppLanguage.tl:'Hagai',       AppLanguage.sw:'Hagai'},
    'zechariah':     {AppLanguage.ko:'스가랴',        AppLanguage.en:'Zechariah',      AppLanguage.zhCN:'撒迦利亚书',AppLanguage.zhTW:'撒迦利亞書',AppLanguage.ja:'ゼカリヤ書',    AppLanguage.es:'Zacarías',     AppLanguage.fr:'Zacharie',     AppLanguage.de:'Sacharja',     AppLanguage.pt:'Zacarias',    AppLanguage.ru:'Захария',      AppLanguage.id:'Zakharia',     AppLanguage.vi:'Xa-cha-ri',     AppLanguage.th:'เศคาริยาห์',   AppLanguage.tl:'Zacarias',    AppLanguage.sw:'Zekaria'},
    'malachi':       {AppLanguage.ko:'말라기',        AppLanguage.en:'Malachi',        AppLanguage.zhCN:'玛拉基书',  AppLanguage.zhTW:'瑪拉基書',  AppLanguage.ja:'マラキ書',      AppLanguage.es:'Malaquías',    AppLanguage.fr:'Malachie',     AppLanguage.de:'Maleachi',     AppLanguage.pt:'Malaquias',   AppLanguage.ru:'Малахия',      AppLanguage.id:'Maleakhi',     AppLanguage.vi:'Ma-la-chi',     AppLanguage.th:'มาลาคี',       AppLanguage.tl:'Malakias',    AppLanguage.sw:'Malaki'},
    // 신약
    'matthew':       {AppLanguage.ko:'마태복음',      AppLanguage.en:'Matthew',        AppLanguage.zhCN:'马太福音',  AppLanguage.zhTW:'馬太福音',  AppLanguage.ja:'マタイ福音書',  AppLanguage.es:'Mateo',        AppLanguage.fr:'Matthieu',     AppLanguage.de:'Matthäus',     AppLanguage.pt:'Mateus',      AppLanguage.ru:'Матфей',       AppLanguage.id:'Matius',       AppLanguage.vi:'Ma-thi-ơ',      AppLanguage.th:'มัทธิว',       AppLanguage.tl:'Mateo',       AppLanguage.sw:'Mathayo'},
    'mark':          {AppLanguage.ko:'마가복음',      AppLanguage.en:'Mark',           AppLanguage.zhCN:'马可福音',  AppLanguage.zhTW:'馬可福音',  AppLanguage.ja:'マルコ福音書',  AppLanguage.es:'Marcos',       AppLanguage.fr:'Marc',         AppLanguage.de:'Markus',       AppLanguage.pt:'Marcos',      AppLanguage.ru:'Марк',         AppLanguage.id:'Markus',       AppLanguage.vi:'Mác',           AppLanguage.th:'มาระโก',       AppLanguage.tl:'Marcos',      AppLanguage.sw:'Marko'},
    'luke':          {AppLanguage.ko:'누가복음',      AppLanguage.en:'Luke',           AppLanguage.zhCN:'路加福音',  AppLanguage.zhTW:'路加福音',  AppLanguage.ja:'ルカ福音書',    AppLanguage.es:'Lucas',        AppLanguage.fr:'Luc',          AppLanguage.de:'Lukas',        AppLanguage.pt:'Lucas',       AppLanguage.ru:'Лука',         AppLanguage.id:'Lukas',        AppLanguage.vi:'Lu-ca',         AppLanguage.th:'ลูกา',         AppLanguage.tl:'Lucas',       AppLanguage.sw:'Luka'},
    'john':          {AppLanguage.ko:'요한복음',      AppLanguage.en:'John',           AppLanguage.zhCN:'约翰福音',  AppLanguage.zhTW:'約翰福音',  AppLanguage.ja:'ヨハネ福音書',  AppLanguage.es:'Juan',         AppLanguage.fr:'Jean',         AppLanguage.de:'Johannes',     AppLanguage.pt:'João',        AppLanguage.ru:'Иоанн',        AppLanguage.id:'Yohanes',      AppLanguage.vi:'Giăng',         AppLanguage.th:'ยอห์น',        AppLanguage.tl:'Juan',        AppLanguage.sw:'Yohane'},
    'acts':          {AppLanguage.ko:'사도행전',      AppLanguage.en:'Acts',           AppLanguage.zhCN:'使徒行传',  AppLanguage.zhTW:'使徒行傳',  AppLanguage.ja:'使徒行伝',      AppLanguage.es:'Hechos',       AppLanguage.fr:'Actes',        AppLanguage.de:'Apostelgeschichte',AppLanguage.pt:'Atos',       AppLanguage.ru:'Деяния',       AppLanguage.id:'Kisah Para Rasul',AppLanguage.vi:'Công Vụ',    AppLanguage.th:'กิจการ',       AppLanguage.tl:'Mga Gawa',    AppLanguage.sw:'Matendo'},
    'romans':        {AppLanguage.ko:'로마서',        AppLanguage.en:'Romans',         AppLanguage.zhCN:'罗马书',    AppLanguage.zhTW:'羅馬書',    AppLanguage.ja:'ローマ書',      AppLanguage.es:'Romanos',      AppLanguage.fr:'Romains',      AppLanguage.de:'Römer',        AppLanguage.pt:'Romanos',     AppLanguage.ru:'Римлянам',     AppLanguage.id:'Roma',         AppLanguage.vi:'Rô-ma',         AppLanguage.th:'โรม',          AppLanguage.tl:'Roma',        AppLanguage.sw:'Warumi'},
    '1corinthians':  {AppLanguage.ko:'고린도전서',    AppLanguage.en:'1 Corinthians',  AppLanguage.zhCN:'哥林多前书',AppLanguage.zhTW:'哥林多前書',AppLanguage.ja:'コリント一書',  AppLanguage.es:'1 Corintios',  AppLanguage.fr:'1 Corinthiens',AppLanguage.de:'1 Korinther',  AppLanguage.pt:'1 Coríntios', AppLanguage.ru:'1 Коринфянам', AppLanguage.id:'1 Korintus',   AppLanguage.vi:'1 Cô-rinh-tô',  AppLanguage.th:'1 โครินธ์',    AppLanguage.tl:'1 Corinto',   AppLanguage.sw:'1 Wakorintho'},
    '2corinthians':  {AppLanguage.ko:'고린도후서',    AppLanguage.en:'2 Corinthians',  AppLanguage.zhCN:'哥林多后书',AppLanguage.zhTW:'哥林多後書',AppLanguage.ja:'コリント二書',  AppLanguage.es:'2 Corintios',  AppLanguage.fr:'2 Corinthiens',AppLanguage.de:'2 Korinther',  AppLanguage.pt:'2 Coríntios', AppLanguage.ru:'2 Коринфянам', AppLanguage.id:'2 Korintus',   AppLanguage.vi:'2 Cô-rinh-tô',  AppLanguage.th:'2 โครินธ์',    AppLanguage.tl:'2 Corinto',   AppLanguage.sw:'2 Wakorintho'},
    'galatians':     {AppLanguage.ko:'갈라디아서',    AppLanguage.en:'Galatians',      AppLanguage.zhCN:'加拉太书',  AppLanguage.zhTW:'加拉太書',  AppLanguage.ja:'ガラテヤ書',    AppLanguage.es:'Gálatas',      AppLanguage.fr:'Galates',      AppLanguage.de:'Galater',      AppLanguage.pt:'Gálatas',     AppLanguage.ru:'Галатам',      AppLanguage.id:'Galatia',      AppLanguage.vi:'Ga-la-ti',      AppLanguage.th:'กาลาเทีย',     AppLanguage.tl:'Galacia',     AppLanguage.sw:'Wagalatia'},
    'ephesians':     {AppLanguage.ko:'에베소서',      AppLanguage.en:'Ephesians',      AppLanguage.zhCN:'以弗所书',  AppLanguage.zhTW:'以弗所書',  AppLanguage.ja:'エフェソ書',    AppLanguage.es:'Efesios',      AppLanguage.fr:'Éphésiens',    AppLanguage.de:'Epheser',      AppLanguage.pt:'Efésios',     AppLanguage.ru:'Ефесянам',     AppLanguage.id:'Efesus',       AppLanguage.vi:'Ê-phê-sô',      AppLanguage.th:'เอเฟซัส',      AppLanguage.tl:'Efeso',       AppLanguage.sw:'Waefeso'},
    'philippians':   {AppLanguage.ko:'빌립보서',      AppLanguage.en:'Philippians',    AppLanguage.zhCN:'腓立比书',  AppLanguage.zhTW:'腓立比書',  AppLanguage.ja:'フィリピ書',    AppLanguage.es:'Filipenses',   AppLanguage.fr:'Philippiens',  AppLanguage.de:'Philipper',    AppLanguage.pt:'Filipenses',  AppLanguage.ru:'Филиппийцам',  AppLanguage.id:'Filipi',       AppLanguage.vi:'Phi-líp',       AppLanguage.th:'ฟีลิปปี',      AppLanguage.tl:'Filipos',     AppLanguage.sw:'Wafilipi'},
    'colossians':    {AppLanguage.ko:'골로새서',      AppLanguage.en:'Colossians',     AppLanguage.zhCN:'歌罗西书',  AppLanguage.zhTW:'歌羅西書',  AppLanguage.ja:'コロサイ書',    AppLanguage.es:'Colosenses',   AppLanguage.fr:'Colossiens',   AppLanguage.de:'Kolosser',     AppLanguage.pt:'Colossenses', AppLanguage.ru:'Колоссянам',   AppLanguage.id:'Kolose',       AppLanguage.vi:'Cô-lô-se',      AppLanguage.th:'โคโลสี',       AppLanguage.tl:'Colosas',     AppLanguage.sw:'Wakolosai'},
    '1thessalonians':{AppLanguage.ko:'데살로니가전서', AppLanguage.en:'1 Thessalonians',AppLanguage.zhCN:'帖撒罗尼迦前书',AppLanguage.zhTW:'帖撒羅尼迦前書',AppLanguage.ja:'テサロニケ一書',AppLanguage.es:'1 Tesalonicenses',AppLanguage.fr:'1 Thessaloniciens',AppLanguage.de:'1 Thessalonicher',AppLanguage.pt:'1 Tessalonicenses',AppLanguage.ru:'1 Фессалоникийцам',AppLanguage.id:'1 Tesalonika',AppLanguage.vi:'1 Tê-sa-lô-ni-ca',AppLanguage.th:'1 เธสะโลนิกา',AppLanguage.tl:'1 Tesalonica',AppLanguage.sw:'1 Wathesalonike'},
    '2thessalonians':{AppLanguage.ko:'데살로니가후서', AppLanguage.en:'2 Thessalonians',AppLanguage.zhCN:'帖撒罗尼迦后书',AppLanguage.zhTW:'帖撒羅尼迦後書',AppLanguage.ja:'テサロニケ二書',AppLanguage.es:'2 Tesalonicenses',AppLanguage.fr:'2 Thessaloniciens',AppLanguage.de:'2 Thessalonicher',AppLanguage.pt:'2 Tessalonicenses',AppLanguage.ru:'2 Фессалоникийцам',AppLanguage.id:'2 Tesalonika',AppLanguage.vi:'2 Tê-sa-lô-ni-ca',AppLanguage.th:'2 เธสะโลนิกา',AppLanguage.tl:'2 Tesalonica',AppLanguage.sw:'2 Wathesalonike'},
    '1timothy':      {AppLanguage.ko:'디모데전서',    AppLanguage.en:'1 Timothy',      AppLanguage.zhCN:'提摩太前书',AppLanguage.zhTW:'提摩太前書',AppLanguage.ja:'テモテ一書',    AppLanguage.es:'1 Timoteo',    AppLanguage.fr:'1 Timothée',   AppLanguage.de:'1 Timotheus',  AppLanguage.pt:'1 Timóteo',   AppLanguage.ru:'1 Тимофею',    AppLanguage.id:'1 Timotius',   AppLanguage.vi:'1 Ti-mô-thê',   AppLanguage.th:'1 ทิโมธี',     AppLanguage.tl:'1 Timoteo',   AppLanguage.sw:'1 Timotheo'},
    '2timothy':      {AppLanguage.ko:'디모데후서',    AppLanguage.en:'2 Timothy',      AppLanguage.zhCN:'提摩太后书',AppLanguage.zhTW:'提摩太後書',AppLanguage.ja:'テモテ二書',    AppLanguage.es:'2 Timoteo',    AppLanguage.fr:'2 Timothée',   AppLanguage.de:'2 Timotheus',  AppLanguage.pt:'2 Timóteo',   AppLanguage.ru:'2 Тимофею',    AppLanguage.id:'2 Timotius',   AppLanguage.vi:'2 Ti-mô-thê',   AppLanguage.th:'2 ทิโมธี',     AppLanguage.tl:'2 Timoteo',   AppLanguage.sw:'2 Timotheo'},
    'titus':         {AppLanguage.ko:'디도서',        AppLanguage.en:'Titus',          AppLanguage.zhCN:'提多书',    AppLanguage.zhTW:'提多書',    AppLanguage.ja:'テトス書',      AppLanguage.es:'Tito',         AppLanguage.fr:'Tite',         AppLanguage.de:'Titus',        AppLanguage.pt:'Tito',        AppLanguage.ru:'Титу',         AppLanguage.id:'Titus',        AppLanguage.vi:'Tít',           AppLanguage.th:'ทิตัส',        AppLanguage.tl:'Tito',        AppLanguage.sw:'Tito'},
    'philemon':      {AppLanguage.ko:'빌레몬서',      AppLanguage.en:'Philemon',       AppLanguage.zhCN:'腓利门书',  AppLanguage.zhTW:'腓利門書',  AppLanguage.ja:'フィレモン書',  AppLanguage.es:'Filemón',      AppLanguage.fr:'Philémon',     AppLanguage.de:'Philemon',     AppLanguage.pt:'Filemom',     AppLanguage.ru:'Филимону',     AppLanguage.id:'Filemon',      AppLanguage.vi:'Phi-lê-môn',    AppLanguage.th:'ฟีเลโมน',      AppLanguage.tl:'Filemon',     AppLanguage.sw:'Filemoni'},
    'hebrews':       {AppLanguage.ko:'히브리서',      AppLanguage.en:'Hebrews',        AppLanguage.zhCN:'希伯来书',  AppLanguage.zhTW:'希伯來書',  AppLanguage.ja:'ヘブライ書',    AppLanguage.es:'Hebreos',      AppLanguage.fr:'Hébreux',      AppLanguage.de:'Hebräer',      AppLanguage.pt:'Hebreus',     AppLanguage.ru:'Евреям',       AppLanguage.id:'Ibrani',       AppLanguage.vi:'Hê-bơ-rơ',     AppLanguage.th:'ฮีบรู',        AppLanguage.tl:'Hebreo',      AppLanguage.sw:'Waebrania'},
    'james':         {AppLanguage.ko:'야고보서',      AppLanguage.en:'James',          AppLanguage.zhCN:'雅各书',    AppLanguage.zhTW:'雅各書',    AppLanguage.ja:'ヤコブ書',      AppLanguage.es:'Santiago',     AppLanguage.fr:'Jacques',      AppLanguage.de:'Jakobus',      AppLanguage.pt:'Tiago',       AppLanguage.ru:'Иакова',       AppLanguage.id:'Yakobus',      AppLanguage.vi:'Gia-cơ',        AppLanguage.th:'ยากอบ',        AppLanguage.tl:'Santiago',    AppLanguage.sw:'Yakobo'},
    '1peter':        {AppLanguage.ko:'베드로전서',    AppLanguage.en:'1 Peter',        AppLanguage.zhCN:'彼得前书',  AppLanguage.zhTW:'彼得前書',  AppLanguage.ja:'ペトロ一書',    AppLanguage.es:'1 Pedro',      AppLanguage.fr:'1 Pierre',     AppLanguage.de:'1 Petrus',     AppLanguage.pt:'1 Pedro',     AppLanguage.ru:'1 Петра',      AppLanguage.id:'1 Petrus',     AppLanguage.vi:'1 Phi-e-rơ',    AppLanguage.th:'1 เปโตร',      AppLanguage.tl:'1 Pedro',     AppLanguage.sw:'1 Petro'},
    '2peter':        {AppLanguage.ko:'베드로후서',    AppLanguage.en:'2 Peter',        AppLanguage.zhCN:'彼得后书',  AppLanguage.zhTW:'彼得後書',  AppLanguage.ja:'ペトロ二書',    AppLanguage.es:'2 Pedro',      AppLanguage.fr:'2 Pierre',     AppLanguage.de:'2 Petrus',     AppLanguage.pt:'2 Pedro',     AppLanguage.ru:'2 Петра',      AppLanguage.id:'2 Petrus',     AppLanguage.vi:'2 Phi-e-rơ',    AppLanguage.th:'2 เปโตร',      AppLanguage.tl:'2 Pedro',     AppLanguage.sw:'2 Petro'},
    '1john':         {AppLanguage.ko:'요한일서',      AppLanguage.en:'1 John',         AppLanguage.zhCN:'约翰一书',  AppLanguage.zhTW:'約翰一書',  AppLanguage.ja:'ヨハネ一書',    AppLanguage.es:'1 Juan',       AppLanguage.fr:'1 Jean',       AppLanguage.de:'1 Johannes',   AppLanguage.pt:'1 João',      AppLanguage.ru:'1 Иоанна',     AppLanguage.id:'1 Yohanes',    AppLanguage.vi:'1 Giăng',       AppLanguage.th:'1 ยอห์น',      AppLanguage.tl:'1 Juan',      AppLanguage.sw:'1 Yohane'},
    '2john':         {AppLanguage.ko:'요한이서',      AppLanguage.en:'2 John',         AppLanguage.zhCN:'约翰二书',  AppLanguage.zhTW:'約翰二書',  AppLanguage.ja:'ヨハネ二書',    AppLanguage.es:'2 Juan',       AppLanguage.fr:'2 Jean',       AppLanguage.de:'2 Johannes',   AppLanguage.pt:'2 João',      AppLanguage.ru:'2 Иоанна',     AppLanguage.id:'2 Yohanes',    AppLanguage.vi:'2 Giăng',       AppLanguage.th:'2 ยอห์น',      AppLanguage.tl:'2 Juan',      AppLanguage.sw:'2 Yohane'},
    '3john':         {AppLanguage.ko:'요한삼서',      AppLanguage.en:'3 John',         AppLanguage.zhCN:'约翰三书',  AppLanguage.zhTW:'約翰三書',  AppLanguage.ja:'ヨハネ三書',    AppLanguage.es:'3 Juan',       AppLanguage.fr:'3 Jean',       AppLanguage.de:'3 Johannes',   AppLanguage.pt:'3 João',      AppLanguage.ru:'3 Иоанна',     AppLanguage.id:'3 Yohanes',    AppLanguage.vi:'3 Giăng',       AppLanguage.th:'3 ยอห์น',      AppLanguage.tl:'3 Juan',      AppLanguage.sw:'3 Yohane'},
    'jude':          {AppLanguage.ko:'유다서',        AppLanguage.en:'Jude',           AppLanguage.zhCN:'犹大书',    AppLanguage.zhTW:'猶大書',    AppLanguage.ja:'ユダ書',        AppLanguage.es:'Judas',        AppLanguage.fr:'Jude',         AppLanguage.de:'Judas',        AppLanguage.pt:'Judas',       AppLanguage.ru:'Иуды',         AppLanguage.id:'Yudas',        AppLanguage.vi:'Giu-đe',        AppLanguage.th:'ยูดา',         AppLanguage.tl:'Judas',       AppLanguage.sw:'Yuda'},
    'revelation':    {AppLanguage.ko:'요한계시록',    AppLanguage.en:'Revelation',     AppLanguage.zhCN:'启示录',    AppLanguage.zhTW:'啟示錄',    AppLanguage.ja:'ヨハネの黙示録',AppLanguage.es:'Apocalipsis',  AppLanguage.fr:'Apocalypse',   AppLanguage.de:'Offenbarung',  AppLanguage.pt:'Apocalipse',  AppLanguage.ru:'Откровение',   AppLanguage.id:'Wahyu',        AppLanguage.vi:'Khải Huyền',    AppLanguage.th:'วิวรณ์',       AppLanguage.tl:'Apocalipsis', AppLanguage.sw:'Ufunuo'},
  };
}

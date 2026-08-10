import 'package:flutter/widgets.dart';

/// Small, app-owned translations for UI that is currently language-aware.
/// New screens can use [AppLocalizations.of] and add their strings here.
class AppLocalizations {
  const AppLocalizations(this.locale);

  final Locale locale;

  static const supportedLocales = [Locale('en'), Locale('am')];

  static AppLocalizations of(BuildContext context) =>
      Localizations.of<AppLocalizations>(context, AppLocalizations)!;

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  bool get isAmharic => locale.languageCode == 'am';

  String get settingsAndProfile =>
      isAmharic ? 'ቅንብሮች እና መገለጫ' : 'Settings & Profile';
  String get appearance => isAmharic ? 'መልክ' : 'Appearance';
  String get editProfile => isAmharic ? 'መገለጫ ያስተካክሉ' : 'Edit Profile';
  String get editProfileDescription => isAmharic
      ? 'ስልክ፣ ኢሜይል ወይም የይለፍ ቃል ያዘምኑ'
      : 'Update phone, email or password';
  String get language => isAmharic ? 'ቋንቋ' : 'Language';
  String get chooseLanguage => isAmharic ? 'ቋንቋ ይምረጡ' : 'Choose language';
  String get english => 'English';
  String get amharic => 'አማርኛ';
  String get languageDescription =>
      isAmharic ? 'የመተግበሪያውን ቋንቋ ይምረጡ' : 'Choose the app language';
  String get darkMode => isAmharic ? 'ጨለማ ሁነታ' : 'Dark Mode';
  String get systemDefault => isAmharic ? 'የስርዓቱ ነባሪ' : 'System default';
  String get about => isAmharic ? 'ስለ መተግበሪያው' : 'About';
  String get appVersion => isAmharic ? 'የመተግበሪያ ስሪት' : 'App Version';
  String get school => isAmharic ? 'ትምህርት ቤት' : 'School';
  String get classes => isAmharic ? 'ክፍሎች' : 'Classes';
  String get subjects => isAmharic ? 'ትምህርቶች' : 'Subjects';
  String get messages => isAmharic ? 'መልእክቶች' : 'Messages';
  String get notifications => isAmharic ? 'ማሳወቂያዎች' : 'Notifications';
  String get announcements => isAmharic ? 'ማስታወቂያዎች' : 'Announcements';
  String get viewAll => isAmharic ? 'ሁሉንም እይ' : 'View All';
  String get unread => isAmharic ? 'ያልተነበበ' : 'Unread';
  String get allRead => isAmharic ? 'ሁሉም ተነበቡ' : 'All read';
  String get noAnnouncements => isAmharic ? 'ምንም ማስታወቂያዎች የሉም' : 'No announcements';
  String get myStudents => isAmharic ? 'የእኔ ተማሪዎች' : 'My Students';
  String get searchStudents => isAmharic ? 'ተማሪዎችን ይፈልጉ...' : 'Search students...';
  String get noClasses => isAmharic ? 'ምንም ክፍሎች' : 'No Classes';
  String get noAssignedClasses => isAmharic ? 'ምንም የተመደቡ ክፍሎች የሉዎትም።' : 'You have no assigned classes.';
  String get all => isAmharic ? 'ሁሉም' : 'All';
  String get noStudents => isAmharic ? 'ምንም ተማሪዎች' : 'No Students';
  String noResultsForSearch(String search) => isAmharic ? 'ለ"$search" ምንም ውጤቶች የሉም' : 'No results for "$search"';
  String errorLoadingStudents(Object? err) => isAmharic
      ? 'ተማሪዎችን መጫን አልተሳካም: ${err ?? "unknown"}'
      : 'Error loading students: ${err ?? "unknown"}';
  String get schoolName =>
      isAmharic ? 'ሐምሌ አንደኛ ደረጃ ትምህርት ቤት' : 'Hamle Elementary School';
  String get signOut => isAmharic ? 'ውጣ' : 'Sign Out';
  String get signOutConfirmation => isAmharic
      ? 'ከመለያዎ መውጣት እርግጠኛ ነዎት?'
      : 'Are you sure you want to sign out?';
  String get cancel => isAmharic ? 'ሰርዝ' : 'Cancel';

  String get attendance => isAmharic ? 'መገኘት' : 'Attendance';
  String get results => isAmharic ? 'ውጤቶች' : 'Results';
  String get myClasses => isAmharic ? 'ክፍሎቼ' : 'My Classes';
  String get studentActivities => isAmharic ? 'የተማሪ እንቅስቃሴዎች' : 'Student Activities';
  String get noClassesAssigned => isAmharic ? 'ምንም ክፍሎች አልተመደቡም' : 'No Classes Assigned';
  String get noClassesAssignedDescription => isAmharic
      ? 'ለዚህ የት/ቤት ዓመት ምንም የክፍል-ትምህርት ስምምነት የለዎትም።'
      : 'You have no class-subject assignments for this academic year.';
  String get chooseClassToViewSubjects => isAmharic
      ? 'ክፍል ይምረጡ እና የሚያስተምሩትን ትምህርት ይመልከቱ።'
      : 'Choose a class to view the subjects you teach.';
  String get chooseClassForAttendance => isAmharic
      ? 'ክፍል በመምረጥ ከዚያ ለዚህ የመገኘት ክፍል ትምህርት ይምረጡ።'
      : 'Choose a class, then the subject for this attendance session.';
  String get chooseClassForResults => isAmharic
      ? 'ክፍል በመምረጥ ከዚያ ለሚፈለገው ውጤት ትምህርት ይምረጡ።'
      : 'Choose a class, then the subject whose results you want to enter.';
  String get chooseClassForActivityLog => isAmharic
      ? 'ክፍል በመምረጥ ከዚያ ለተማሪ እንቅስቃሴ ምዝገባ ትምህርት ይምረጡ።'
      : 'Choose a class, then a subject to add a student activity log.';
  String subjectsYouTeachIn(String className) => isAmharic
      ? 'በ$className ውስጥ የሚያስተምሩት ትምህርቶች'
      : 'Subjects you teach in $className';
  String get noStudentsEnrolled => isAmharic ? 'ምንም ተማሪዎች አልተመዘገቡም' : 'No Students Enrolled';
  String get noStudentsEnrolledDescription => isAmharic
      ? 'በዚህ ክፍል ውስጥ ምንም ንቁ የተማሪ ምዝገባ የለም።'
      : 'There are no active student enrolments in this class.';
  String enrolledStudentsCount(int count) => isAmharic
      ? '$count ተማሪዎች ተመዝግበዋል'
      : '$count enrolled students';
  String get takeAttendanceForClassSubject => isAmharic
      ? 'ለዚህ ክፍል እና ትምህርት መገኘት ይውሰዱ'
      : 'Take attendance for this class for this subject';
  String get addResult => isAmharic ? 'ውጤት ጨምር' : 'Add result';
  String get addLog => isAmharic ? 'ምዝገባ ጨምር' : 'Add log';
  String get takeAttendanceForStudent => isAmharic ? 'ለዚህ ተማሪ መገኘት ይውሰዱ' : 'Take attendance for this student';
  String get addStudentLog => isAmharic ? 'የተማሪ ምዝገባ ጨምር' : 'Add student log';
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) =>
      AppLocalizations.supportedLocales.contains(Locale(locale.languageCode));

  @override
  Future<AppLocalizations> load(Locale locale) async =>
      AppLocalizations(locale);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

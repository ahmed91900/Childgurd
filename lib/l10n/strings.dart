import 'package:flutter/widgets.dart';
import 'learning_strings.dart';

/// Every user-facing Flutter string has both Arabic and English translations.
/// Locale switching uses Flutter's localization delegates for layout direction.
class Strings {
  const Strings(this.arabic, {this.bangla = false});
  final bool bangla;
  String get language => arabic
      ? 'ar'
      : bangla
      ? 'bn'
      : 'en';
  final bool arabic;
  static Strings of(BuildContext context) => Strings(
    Localizations.localeOf(context).languageCode == 'ar',
    bangla: Localizations.localeOf(context).languageCode == 'bn',
  );
  String operator [](String key) =>
      (bangla
          ? banglaStrings
          : arabic
          ? _ar
          : _en)[key] ??
      learningStrings[key]?[bangla
          ? 2
          : arabic
          ? 1
          : 0] ??
      key;

  static const _en = {
    'app': 'KidSafe Launcher',
    'tagline': 'A little structure. A world to discover.',
    'phase': 'Supervised beta • Android restrictions have limits',
    'welcome': 'A safer start, together',
    'welcomeBody':
        'Create private PINs, review privacy, and prepare Android permissions. Learning and progress work offline. Remote sync needs Firebase setup.',
    'consent':
        'I am the parent or legal guardian. I understand the Android limits and consent to storing PIN credentials on this device.',
    'privacy': 'Privacy & Android limits',
    'begin': 'Set up this phone',
    'secure': 'Your family’s private space',
    'enterPin': 'Enter your PIN',
    'pinHint': 'Parent PIN or child PIN',
    'unlock': 'Unlock',
    'parentOnly': 'Parent PIN required to leave Kids Mode',
    'backKid': 'Back to Kids Mode',
    'locked': 'Too many attempts. Please wait',
    'wrong': 'Incorrect PIN. Try again.',
    'pinPolicy':
        'Use different PINs of 4–12 digits. Neither may be 1020 or 0000.',
    'storage':
        'Secure storage is unavailable or damaged. Access is blocked. Do not clear app data to troubleshoot: that removes protection.',
    'busy': 'Please wait for the current operation.',
    'setupRequired': 'Complete setup first.',
    'error': 'This operation could not finish. Please retry.',
    'choosePins': 'Make it yours',
    'pinIntro':
        'Replace both default PINs before using this launcher. Longer PINs are harder to guess. Keep the parent PIN private.',
    'currentParent': 'Current parent PIN (initially 1020)',
    'newParent': 'New parent PIN',
    'confirmParent': 'Confirm parent PIN',
    'newKid': 'New child PIN (replaces 0000)',
    'confirmKid': 'Confirm child PIN',
    'mismatch': 'The confirmation PINs do not match.',
    'savePins': 'Save private PINs',
    'permissions': 'Prepare this Android phone',
    'permissionsBody':
        'Android owns these permission screens. Return here after each grant. Parent authentication is required when returning from the background.',
    'home': 'Default Home launcher',
    'homeBody':
        'Choose KidSafe as the Home app. This does not replace Android’s system screen lock.',
    'admin': 'Device administrator',
    'adminBody':
        'Android usually requires deactivation before uninstall. A user can still deactivate it; this is not uninstall-proof.',
    'accessibility': 'Accessibility service',
    'accessibilityBody':
        'With your explicit consent, observes app package changes and tries to return Home when another app opens in child mode. It reads no screen text. System surfaces and some OEM behavior remain outside reliable control.',
    'overlay': 'Display over other apps',
    'overlayBody':
        'Prepare overlay access. System screens may reject overlays; this does not secure Settings.',
    'usage': 'Usage access',
    'usageBody':
        'Optional Android usage-access status. KidSafe measures its own play and video time without reading other apps’ usage history.',
    'granted': 'Granted',
    'grant': 'Open settings',
    'permissionError':
        'Cannot read permissions. Retry; status has not been assumed.',
    'retry': 'Retry',
    'continue': 'Continue to parent mode',
    'missing':
        'Some permissions are missing or were revoked. Restrictions cannot be relied on.',
    'parent': 'Parent space',
    'parentBody': 'Your apps, in one place',
    'changePins': 'Change PINs',
    'lock': 'Lock launcher',
    'appsError': 'Could not load or open apps.',
    'emptyApps': 'No launchable apps were returned by Android.',
    'kid': 'Hello, bright mind',
    'kidBody': 'Your next adventure starts here.',
    'tasks': 'Today’s Tasks',
    'videos': 'Learning Videos',
    'games': 'Games That Teach',
    'rewards': 'My Rewards',
    'coming': 'Coming in a later phase',
    'exit': 'Parent access',
    'back': 'Back',
    'privacyTitle': 'Privacy, consent & real limits',
    'privacyBody':
        'PIN hashes and the local family ledger are encrypted with Android Keystore. Profiles, tasks, progress, drawings and time requests stay on this phone unless a parent activates online family sync. No camera, microphone, location or contacts are collected. PINs never go to Firebase. Android backup and device transfer are disabled.\n\nOnline mode uses Firebase Auth, Firestore and FCM for the configured family. A verified parent can pair one scoped child device per profile. The parent must arrange consent, retention and deletion for their deployment. Offline learning remains available if the network is unavailable.\n\nAds are off by default. An owner-controlled setting and the parent’s child-profile permission are both needed. AdMob requests are tagged as child-directed, under age of consent, non-personalized, maximum content rating G. Manual ads connect to their approved media host. The operator must review content and applicable advertising policies; these settings do not certify legal compliance.\n\nThis launcher does not replace Android keyguard. Accessibility observes package names only and makes a best-effort Home redirect in child mode. It cannot reliably block system settings, notifications, safe mode, permission revocation, data clearing or factory reset. Supervise children and use Android’s system screen lock.\n\nClearing app data or uninstalling may delete local credentials and progress. There is no recovery PIN. Device clock changes affect daily limits and lockout. This app is not a COPPA or GDPR-K certification.',
  };

  static const _ar = {
    'app': 'كيد سيف',
    'tagline': 'خطوات صغيرة نحو عالم من الاكتشاف.',
    'phase': 'إصدار تجريبي بإشراف ولي الأمر • قيود أندرويد لها حدود',
    'welcome': 'بداية أكثر أماناً، معاً',
    'welcomeBody':
        'أنشئ رموزاً خاصة وراجع الخصوصية وجهز أذونات أندرويد. التعلم والتقدم يعملان دون اتصال. المزامنة عن بعد تتطلب إعداد فايربيس.',
    'consent':
        'أنا ولي الأمر أو الوصي القانوني. أفهم حدود أندرويد وأوافق على تخزين بيانات الرموز على هذا الجهاز.',
    'privacy': 'الخصوصية وحدود أندرويد',
    'begin': 'إعداد هذا الهاتف',
    'secure': 'مساحة خاصة لعائلتك',
    'enterPin': 'أدخل الرمز السري',
    'pinHint': 'رمز ولي الأمر أو الطفل',
    'unlock': 'فتح',
    'parentOnly': 'يلزم رمز ولي الأمر للخروج من وضع الطفل',
    'backKid': 'العودة إلى وضع الطفل',
    'locked': 'محاولات كثيرة. يرجى الانتظار',
    'wrong': 'الرمز غير صحيح. حاول مجدداً.',
    'pinPolicy':
        'اختر رمزين مختلفين من ٤ إلى ١٢ رقماً. لا تستخدم 1020 أو 0000.',
    'storage':
        'التخزين الآمن غير متاح أو تالف. تم منع الوصول. لا تمسح بيانات التطبيق لأن ذلك يزيل الحماية.',
    'busy': 'يرجى انتظار انتهاء العملية الحالية.',
    'setupRequired': 'أكمل الإعداد أولاً.',
    'error': 'تعذر إكمال العملية. حاول مجدداً.',
    'choosePins': 'اجعلها مساحتك',
    'pinIntro':
        'استبدل الرمزين الافتراضيين قبل الاستخدام. الرموز الأطول أصعب في التخمين. حافظ على سرية رمز ولي الأمر.',
    'currentParent': 'رمز ولي الأمر الحالي (في البداية 1020)',
    'newParent': 'رمز ولي أمر جديد',
    'confirmParent': 'تأكيد رمز ولي الأمر',
    'newKid': 'رمز طفل جديد (بدلاً من 0000)',
    'confirmKid': 'تأكيد رمز الطفل',
    'mismatch': 'رموز التأكيد غير متطابقة.',
    'savePins': 'حفظ الرموز الخاصة',
    'permissions': 'تجهيز هاتف أندرويد',
    'permissionsBody':
        'يتحكم أندرويد في شاشات الأذونات. عد بعد كل خطوة. يلزم رمز ولي الأمر عند العودة من الخلفية.',
    'home': 'تطبيق الشاشة الرئيسية الافتراضي',
    'homeBody':
        'اختر كيد سيف كتطبيق الشاشة الرئيسية. لا يحل محل قفل شاشة أندرويد.',
    'admin': 'مسؤول الجهاز',
    'adminBody':
        'يتطلب أندرويد عادة إلغاء التفعيل قبل الإزالة. يمكن للمستخدم إلغاء التفعيل؛ هذه ليست حماية مضمونة من الإزالة.',
    'accessibility': 'خدمة تسهيل الاستخدام',
    'accessibilityBody':
        'بموافقتك الصريحة تراقب تغير حزمة التطبيق وتحاول العودة إلى الرئيسية عند فتح تطبيق آخر في وضع الطفل. لا تقرأ نص الشاشة. لا يمكن ضمان التحكم في واجهات النظام وجميع الأجهزة.',
    'overlay': 'الظهور فوق التطبيقات',
    'overlayBody':
        'تجهيز إذن الظهور. قد تمنعه شاشات النظام؛ ولا يحمي الإعدادات.',
    'usage': 'الوصول إلى بيانات الاستخدام',
    'usageBody':
        'تجهيز الإذن لتقارير الوقت لاحقاً. لا تجمع المرحلة الأولى سجل الاستخدام.',
    'granted': 'ممنوح',
    'grant': 'فتح الإعدادات',
    'permissionError': 'تعذر قراءة الأذونات. أعد المحاولة؛ لم نفترض منحها.',
    'retry': 'إعادة المحاولة',
    'continue': 'المتابعة إلى وضع ولي الأمر',
    'missing': 'بعض الأذونات مفقودة أو ألغيت. لا يمكن الاعتماد على القيود.',
    'parent': 'مساحة ولي الأمر',
    'parentBody': 'تطبيقاتك في مكان واحد',
    'changePins': 'تغيير الرموز',
    'lock': 'قفل المشغل',
    'appsError': 'تعذر تحميل التطبيقات أو فتحها.',
    'emptyApps': 'لم يعرض أندرويد تطبيقات قابلة للتشغيل.',
    'kid': 'مرحباً أيها المبدع',
    'kidBody': 'مغامرتك التالية تبدأ هنا.',
    'tasks': 'مهام اليوم',
    'videos': 'فيديوهات تعليمية',
    'games': 'ألعاب تعليمية',
    'rewards': 'مكافآتي',
    'coming': 'متاح في مرحلة لاحقة',
    'exit': 'وصول ولي الأمر',
    'back': 'رجوع',
    'privacyTitle': 'الخصوصية والموافقة والحدود الفعلية',
    'privacyBody':
        'تُشفر بصمات الرموز وملفات الأطفال والمهام والتقدم والرسومات والطلبات على الهاتف بمفتاح أندرويد كيسـتور. تبقى محلياً ما لم يفعّل ولي الأمر المزامنة العائلية. لا كاميرا ولا ميكروفون ولا موقع ولا جهات اتصال. لا تُرسل الرموز إلى فايربيس. النسخ الاحتياطي ونقل البيانات معطلان.\n\nالمزامنة تستخدم مصادقة فايربيس وفايرستور والإشعارات للمشروع المحدد. يستطيع حساب ولي أمر موثق ربط جهاز طفل بصلاحيات محدودة. يلزم المشغّل تنظيم الموافقة والاحتفاظ والحذف. التعلم المحلي يعمل دون اتصال.\n\nالإعلانات معطلة افتراضياً. تتطلب تفعيل المالك وموافقة ولي الأمر في ملف الطفل. طلبات أدموب موجهة للأطفال وتحت سن الموافقة وغير مخصصة وبحد تصنيف G. الإعلانات اليدوية تتصل بمضيف الوسائط المعتمد. يجب مراجعة المحتوى وسياسات الإعلانات؛ هذه الخيارات ليست شهادة امتثال.\n\nهذا مشغّل وليس قفل نظام أندرويد. خدمة تسهيل الاستخدام تراقب أسماء الحزم فقط وتحاول العودة إلى الرئيسية في وضع الطفل. لا تضمن منع الإعدادات والإشعارات والوضع الآمن وإلغاء الأذونات ومسح البيانات وإعادة ضبط المصنع. يجب الإشراف على الطفل واستخدام قفل النظام.\n\nمسح البيانات أو الإزالة قد يمحو الرموز والتقدم. لا يوجد رمز استرداد سري. تغيير الساعة يؤثر في الحدود اليومية والحظر. هذا التطبيق ليس شهادة امتثال لقوانين حماية الأطفال.',
  };
}

import 'package:flutter/widgets.dart';

/// Every user-facing Flutter string has both Arabic and English translations.
/// Locale switching uses Flutter's localization delegates for layout direction.
class Strings {
  const Strings(this.arabic);
  final bool arabic;
  static Strings of(BuildContext context) =>
      Strings(Localizations.localeOf(context).languageCode == 'ar');
  String operator [](String key) => (arabic ? _ar : _en)[key] ?? key;

  static const _en = {
    'app': 'KidSafe Launcher',
    'tagline': 'A little structure. A world to discover.',
    'phase': 'Phase 1 • Setup foundation, not a child-proof device',
    'welcome': 'A safer start, together',
    'welcomeBody':
        'Create private PINs, review privacy, and prepare Android permissions. This version does not yet block other apps.',
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
        'Optional in Phase 1: status only. Later app restrictions will need explicit consent. This service currently reads no screen content and blocks no apps.',
    'overlay': 'Display over other apps',
    'overlayBody':
        'Prepare overlay access. System screens may reject overlays; this does not secure Settings.',
    'usage': 'Usage access',
    'usageBody':
        'Prepare usage access for later time reports. Phase 1 does not collect usage history.',
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
        'Phase 1 stores only salted PIN hashes, retry counters, and lockout timestamps in Android encrypted storage. It uses no analytics, advertising, Firebase, child names, camera, microphone, or location. No PIN is sent to a server. Android backup is disabled.\n\nThis app is a home launcher, not Android’s keyguard. Android Settings, notification shade, recents, emergency calling, safe mode, reboots, permission revocation, app-data clearing and factory resets cannot be reliably blocked without managed-device controls. Device Admin can be deactivated. Accessibility and overlays do not guarantee containment. Never rely on this phase for unsupervised child protection.\n\nClearing app data or uninstalling deletes local credentials and resets setup. There is no recovery bypass. Lockout survives normal process restarts; changing the device clock can affect time-based lockout. Use the Android system screen lock as well.\n\nFirebase, remote parenting, learning content and telemetry are not active in Phase 1. Before adding them, we must define parental verification, retention, deletion, consent and child-safe content policies. This prototype is not a claim of COPPA or GDPR-K compliance.',
  };

  static const _ar = {
    'app': 'كيد سيف',
    'tagline': 'خطوات صغيرة نحو عالم من الاكتشاف.',
    'phase': 'المرحلة الأولى • إعداد أولي وليس حماية كاملة للطفل',
    'welcome': 'بداية أكثر أماناً، معاً',
    'welcomeBody':
        'أنشئ رموزاً خاصة وراجع الخصوصية وجهز أذونات أندرويد. هذا الإصدار لا يمنع فتح التطبيقات الأخرى بعد.',
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
        'اختيارية في المرحلة الأولى لعرض الحالة فقط. القيود اللاحقة تتطلب موافقة صريحة. الخدمة حالياً لا تقرأ محتوى الشاشة ولا تمنع التطبيقات.',
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
        'تخزن المرحلة الأولى بصمات الرموز المملحة وعدّادات المحاولات وأوقات الحظر في تخزين أندرويد المشفر فقط. لا تحليلات ولا إعلانات ولا فايربيس ولا أسماء أطفال ولا كاميرا ولا ميكروفون ولا موقع. لا تُرسل الرموز إلى خادم. النسخ الاحتياطي معطل.\n\nهذا مشغل شاشة رئيسية وليس قفل نظام أندرويد. لا يمكن ضمان منع الإعدادات والإشعارات والتطبيقات الأخيرة ومكالمات الطوارئ والوضع الآمن وإعادة التشغيل وإلغاء الأذونات ومسح البيانات وإعادة ضبط المصنع دون إدارة الجهاز. يمكن إلغاء مسؤول الجهاز. تسهيل الاستخدام والظهور فوق التطبيقات لا يضمنان الاحتواء. لا تعتمد على هذه المرحلة لحماية طفل دون إشراف.\n\nمسح البيانات أو إزالة التطبيق يمحو الرموز ويعيد الإعداد. لا توجد طريقة تجاوز لاسترداد الرمز. يستمر حظر المحاولات بعد إعادة تشغيل التطبيق، لكن تغيير ساعة الجهاز قد يؤثر عليه. استخدم قفل أندرويد أيضاً.\n\nفايربيس والإدارة عن بعد والمحتوى التعليمي غير مفعلة في المرحلة الأولى. قبل إضافتها يجب تحديد التحقق من ولي الأمر والاحتفاظ بالبيانات وحذفها والموافقة وسياسات المحتوى الآمن. هذا النموذج ليس إقراراً بالامتثال لقوانين حماية خصوصية الأطفال.',
  };
}

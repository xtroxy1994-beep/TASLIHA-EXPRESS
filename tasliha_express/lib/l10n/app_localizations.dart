import 'package:flutter/material.dart';

class AppLocalizations {
  final Locale locale;
  AppLocalizations(this.locale);

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  static const Map<String, Map<String, String>> _localizedValues = {
    'ar': {
      'appName': 'تسليحة إكسبريس',
      'login': 'تسجيل الدخول',
      'register': 'إنشاء حساب',
      'email': 'البريد الإلكتروني',
      'password': 'كلمة المرور',
      'phone': 'رقم الهاتف',
      'wilaya': 'الولاية',
      'commune': 'البلدية',
      'profile': 'الملف الشخصي',
      'logout': 'تسجيل الخروج',
      'home': 'الرئيسية',
      'requests': 'الطلبات',
      'points': 'النقاط',
      'chat': 'المحادثة',
      'rating': 'التقييم',
      'submit': 'إرسال',
      'cancel': 'إلغاء',
      'loading': 'جارٍ التحميل...',
      'error': 'حدث خطأ',
      'success': 'تم بنجاح',
      'required': 'هذا الحقل مطلوب',
      'client': 'عميل',
      'tech': 'فني',
      'manager': 'مدير',
      'admin': 'أدمن',
      'postRequest': 'نشر طلب',
      'availableRequests': 'الطلبات المتاحة',
      'myJobs': 'أعمالي',
      'recharge': 'شحن نقاط',
      'acceptRequest': 'قبول الطلب',
      'completeRequest': 'إتمام الطلب',
      'pendingReview': 'قيد المراجعة',
      'approved': 'مقبول',
      'rejected': 'مرفوض',
    },
    'fr': {
      'appName': 'Tasliha Express',
      'login': 'Connexion',
      'register': 'Inscription',
      'email': 'Email',
      'password': 'Mot de passe',
      'phone': 'Téléphone',
      'wilaya': 'Wilaya',
      'commune': 'Commune',
      'profile': 'Profil',
      'logout': 'Déconnexion',
      'home': 'Accueil',
      'requests': 'Demandes',
      'points': 'Points',
      'chat': 'Discussion',
      'rating': 'Évaluation',
      'submit': 'Envoyer',
      'cancel': 'Annuler',
      'loading': 'Chargement...',
      'error': 'Une erreur est survenue',
      'success': 'Succès',
      'required': 'Ce champ est obligatoire',
      'client': 'Client',
      'tech': 'Technicien',
      'manager': 'Manager',
      'admin': 'Admin',
      'postRequest': 'Publier une demande',
      'availableRequests': 'Demandes disponibles',
      'myJobs': 'Mes travaux',
      'recharge': 'Recharger points',
      'acceptRequest': 'Accepter la demande',
      'completeRequest': 'Terminer la demande',
      'pendingReview': 'En attente',
      'approved': 'Approuvé',
      'rejected': 'Rejeté',
    },
    'en': {
      'appName': 'Tasliha Express',
      'login': 'Login',
      'register': 'Register',
      'email': 'Email',
      'password': 'Password',
      'phone': 'Phone',
      'wilaya': 'Province',
      'commune': 'Municipality',
      'profile': 'Profile',
      'logout': 'Logout',
      'home': 'Home',
      'requests': 'Requests',
      'points': 'Points',
      'chat': 'Chat',
      'rating': 'Rating',
      'submit': 'Submit',
      'cancel': 'Cancel',
      'loading': 'Loading...',
      'error': 'An error occurred',
      'success': 'Success',
      'required': 'This field is required',
      'client': 'Client',
      'tech': 'Technician',
      'manager': 'Manager',
      'admin': 'Admin',
      'postRequest': 'Post Request',
      'availableRequests': 'Available Requests',
      'myJobs': 'My Jobs',
      'recharge': 'Recharge Points',
      'acceptRequest': 'Accept Request',
      'completeRequest': 'Complete Request',
      'pendingReview': 'Pending Review',
      'approved': 'Approved',
      'rejected': 'Rejected',
    },
  };

  String translate(String key) {
    final langCode = locale.languageCode;
    return _localizedValues[langCode]?[key] ?? _localizedValues['ar']?[key] ?? key;
  }

  // Shortcuts
  String get appName => translate('appName');
  String get login => translate('login');
  String get register => translate('register');
  String get email => translate('email');
  String get password => translate('password');
  String get phone => translate('phone');
  String get profile => translate('profile');
  String get logout => translate('logout');
  String get home => translate('home');
  String get requests => translate('requests');
  String get points => translate('points');
  String get chat => translate('chat');
  String get rating => translate('rating');
  String get submit => translate('submit');
  String get cancel => translate('cancel');
  String get loading => translate('loading');
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => ['ar', 'fr', 'en'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async => AppLocalizations(locale);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

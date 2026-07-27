class AppConstants {
  // App Info
  static const String appName = 'تسليحة إكسبريس';
  static const String appNameFr = 'Tasliha Express';
  static const String adminEmail = 'xtroxy1995@gmail.com';
  static const String ccpAccount = '0012345678901 - Clé: 67';
  static const String ccpOwner = 'تسليحة إكسبريس';

  // Points
  static const int freePointsOnRegister = 50;
  static const int freePointsValidityDays = 30;
  static const int pointsPerPackage = 200;
  static const int pricePerPackageDZD = 2000;

  // Collections Firestore
  static const String usersCollection = 'users';
  static const String requestsCollection = 'requests';
  static const String ratingsCollection = 'ratings';
  static const String chatsCollection = 'chats';
  static const String messagesCollection = 'messages';
  static const String transactionsCollection = 'point_transactions';
  static const String rechargeRequestsCollection = 'recharge_requests';
  static const String notificationsCollection = 'notifications';

  // Storage paths
  static const String profileImagesPath = 'profile_images';
  static const String rechargeReceiptsPath = 'recharge_receipts';
  static const String requestImagesPath = 'request_images';

  // User Roles
  static const String roleClient = 'client';
  static const String roleTech = 'tech';
  static const String roleManager = 'manager';
  static const String roleAdmin = 'admin';

  // Request Status
  static const String statusPending = 'pending';
  static const String statusReviewedByAdmin = 'reviewed';
  static const String statusAvailable = 'available';
  static const String statusAccepted = 'accepted';
  static const String statusInProgress = 'in_progress';
  static const String statusCompleted = 'completed';
  static const String statusCancelled = 'cancelled';

  // Recharge Status
  static const String rechargeStatusPending = 'pending';
  static const String rechargeStatusApproved = 'approved';
  static const String rechargeStatusRejected = 'rejected';

  // Tech Specialties
  static const List<String> techSpecialties = [
    'كهرباء منازل',
    'سباكة',
    'تبريد وتكييف',
    'إلكترونيات وصيانة',
    'ميكانيك',
    'نجارة',
    'بناء وترميم',
    'دهان وديكور',
    'تركيب الزجاج',
    'تركيب الأبواب والنوافذ',
    'صيانة المصاعد',
    'تسليك مجاري',
    'أعمال الألمنيوم',
    'صيانة الأجهزة المنزلية',
    'خدمات أخرى',
  ];

  // Star labels
  static const Map<String, String> starLabels = {
    'expert': 'خبير',
    'excellent': 'ممتاز',
    'good': 'جيد',
    'average': 'متوسط',
    'weak': 'ضعيف',
  };

  static String getTechLevel(double rating) {
    if (rating >= 4.5) return 'خبير';
    if (rating >= 4.0) return 'ممتاز';
    if (rating >= 3.0) return 'جيد';
    if (rating >= 2.0) return 'متوسط';
    return 'ضعيف';
  }
}

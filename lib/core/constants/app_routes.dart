class AppRoutes {
  AppRoutes._();

  // Auth
  static const String splash = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String verifyOtp = '/verify-otp';

  // Consumer
  static const String home = '/home';
  static const String storeList = '/stores';
  static const String storeDetail = '/stores/:storeId';
  static const String orderCheckout = '/order/checkout';
  static const String orderHistory = '/orders';
  static const String orderDetail = '/orders/:orderId';
  static const String payment = '/payment';
  static const String myCoupons = '/coupons';
  static const String couponDetail = '/coupons/:couponId';
  static const String notifications = '/notifications';
  static const String profile = '/profile';

  // Partner
  static const String partnerDashboard = '/partner';
  static const String partnerAddSurplus = '/partner/surplus/add';
  static const String partnerEditProduct = '/partner/surplus/:productId';
  static const String partnerSales = '/partner/sales';
  static const String partnerScanCoupon = '/partner/scan';
  static const String partnerOnboarding = '/partner/onboarding';

  // Admin
  static const String adminDashboard = '/admin';
  static const String adminPartners = '/admin/partners';
  static const String adminPartnerDetail = '/admin/partners/:partnerId';
  static const String adminFoodWaste = '/admin/food-waste';
  static const String adminAnalytics = '/admin/analytics';
  static const String adminBroadcast = '/admin/broadcast';
  static const String adminApprovalMitra = '/admin/approval/mitra';
  static const String adminApprovalMenu = '/admin/approval/menu';
  static const String adminKatalog = '/admin/katalog';
}

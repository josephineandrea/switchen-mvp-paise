import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'core/constants/app_routes.dart';
import 'features/auth/domain/entities/user_entity.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/auth/presentation/bloc/auth_event.dart';
import 'features/auth/presentation/bloc/auth_state.dart';
import 'features/auth/presentation/pages/login_page.dart';
import 'features/auth/presentation/pages/register_page.dart';
import 'features/auth/presentation/pages/verify_otp_page.dart';
import 'features/store_discovery/presentation/pages/store_detail_page.dart';
import 'features/store_discovery/presentation/pages/store_list_page.dart';
import 'features/order/presentation/pages/order_history_page.dart';
import 'features/order/presentation/pages/order_detail_page.dart';
import 'features/order/presentation/pages/order_checkout_page.dart';
import 'features/order/presentation/pages/order_success_page.dart';
import 'features/profile/presentation/pages/profile_page.dart';
import 'features/coupon/presentation/pages/coupon_list_page.dart';
import 'features/coupon/presentation/pages/coupon_detail_page.dart';
import 'features/notification/presentation/pages/notification_page.dart';
import 'features/partner_dashboard/presentation/pages/partner_dashboard_page.dart';
import 'features/partner_dashboard/presentation/pages/add_surplus_page.dart';
import 'features/partner_dashboard/presentation/pages/partner_sales_page.dart';
import 'features/partner_dashboard/presentation/pages/scan_coupon_page.dart';
import 'features/admin/presentation/pages/admin_dashboard_page.dart';
import 'features/admin/presentation/pages/admin_partners_page.dart';
import 'features/admin/presentation/pages/admin_food_waste_page.dart';
import 'features/admin/presentation/pages/admin_analytics_page.dart';
import 'features/admin/presentation/pages/admin_broadcast_page.dart';
import 'features/home/presentation/pages/home_page.dart';
import 'injection_container.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

final appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: AppRoutes.home,
  routes: [
    GoRoute(path: AppRoutes.splash, builder: (_, __) => const _SplashPage()),
    GoRoute(path: AppRoutes.login, builder: (_, __) => const LoginPage()),
    GoRoute(path: AppRoutes.register, builder: (_, __) => const RegisterPage()),
    GoRoute(
      path: AppRoutes.verifyOtp,
      builder: (_, state) => VerifyOtpPage(email: state.extra as String),
    ),
    GoRoute(path: AppRoutes.home, builder: (_, __) => const HomePage()),
    GoRoute(path: AppRoutes.storeList, builder: (_, __) => const StoreListPage()),
    GoRoute(
      path: AppRoutes.storeDetail,
      builder: (_, state) =>
          StoreDetailPage(storeId: state.pathParameters['storeId']!),
    ),
    GoRoute(path: AppRoutes.orderHistory, builder: (_, __) => const OrderHistoryPage()),
    GoRoute(
      path: AppRoutes.orderDetail,
      builder: (_, state) =>
          OrderDetailPage(orderId: state.pathParameters['orderId']!),
    ),
    GoRoute(
      path: AppRoutes.orderCheckout,
      builder: (_, state) {
        final extraData = state.extra as Map<String, dynamic>?;
        
        return OrderCheckoutPage(
          orderData: extraData ?? {
            'nama_makanan': 'Pesanan',
            'total_harga': 0,
            'metode_pembayaran': 'QRIS',
            'jumlah_pesan': 1,
          },
        );
      },
    ),
    GoRoute(
      path: AppRoutes.orderSuccess,
      builder: (_, state) {
        final orderId = state.extra as String? ?? 'PSN-00001';
        return OrderSuccessPage(orderId: orderId);
      },
    ),
    GoRoute(
      path: AppRoutes.profile, 
      builder: (_, __) => const ProfilePage()
    ),
    GoRoute(path: AppRoutes.myCoupons, builder: (_, __) => const CouponListPage()),
    GoRoute(
      path: AppRoutes.couponDetail,
      builder: (_, state) =>
          CouponDetailPage(couponId: state.pathParameters['couponId']!),
    ),
    GoRoute(path: AppRoutes.notifications, builder: (_, __) => const NotificationPage()),
    GoRoute(path: AppRoutes.partnerDashboard, builder: (_, __) => const PartnerDashboardPage()),
    GoRoute(path: AppRoutes.partnerAddSurplus, builder: (_, __) => const AddSurplusPage()),
    GoRoute(path: AppRoutes.partnerSales, builder: (_, __) => const PartnerSalesPage()),
    GoRoute(path: AppRoutes.partnerScanCoupon, builder: (_, __) => const ScanCouponPage()),
    GoRoute(path: AppRoutes.adminDashboard, builder: (_, __) => const AdminDashboardPage()),
    GoRoute(path: AppRoutes.adminPartners, builder: (_, __) => const AdminPartnersPage()),
    GoRoute(path: AppRoutes.adminFoodWaste, builder: (_, __) => const AdminFoodWastePage()),
    GoRoute(path: AppRoutes.adminAnalytics, builder: (_, __) => const AdminAnalyticsPage()),
    GoRoute(path: AppRoutes.adminBroadcast, builder: (_, __) => const AdminBroadcastPage()),
  ],
);

class _SplashPage extends StatefulWidget {
  const _SplashPage();
  @override
  State<_SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<_SplashPage> {
  @override
  void initState() {
    super.initState();
    // Fire the event on the global AuthBloc after build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AuthBloc>().add(const AuthCheckRequested());
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      // Automatically uses context.read<AuthBloc>()
      listener: (context, state) {
        if (state is AuthAuthenticated) {
          switch (state.user.role) {
            case UserRole.admin:
              context.go(AppRoutes.adminDashboard);
              break;
            case UserRole.partner:
              context.go(AppRoutes.partnerDashboard);
              break;
            default:
              context.go(AppRoutes.home);
          }
        } else if (state is AuthUnauthenticated || state is AuthError) {
          context.go(AppRoutes.login);
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF00615F),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Icon(
                  Icons.swap_horiz_rounded,
                  color: Colors.white,
                  size: 48,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Switchen',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 24),
              const CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

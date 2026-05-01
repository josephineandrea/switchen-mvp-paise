import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:get_it/get_it.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/network/network_info.dart';

// Auth
import 'features/auth/data/datasources/auth_remote_datasource.dart';
import 'features/auth/data/repositories/auth_repository_impl.dart';
import 'features/auth/domain/repositories/auth_repository.dart';
import 'features/auth/domain/usecases/auth_usecases.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';

// Store Discovery
import 'features/store_discovery/data/datasources/store_remote_datasource.dart';
import 'features/store_discovery/data/repositories/store_repository_impl.dart';
import 'features/store_discovery/domain/repositories/store_repository.dart';
import 'features/store_discovery/domain/usecases/store_usecases.dart';
import 'features/store_discovery/presentation/bloc/store_bloc.dart';

// Order
import 'features/order/data/datasources/order_remote_datasource.dart';
import 'features/order/data/repositories/order_repository_impl.dart';
import 'features/order/domain/repositories/order_repository.dart';
import 'features/order/domain/usecases/order_usecases.dart';
import 'features/order/presentation/bloc/order_bloc.dart';

// Coupon
import 'features/coupon/data/datasources/coupon_remote_datasource.dart';
import 'features/coupon/data/repositories/coupon_repository_impl.dart';
import 'features/coupon/domain/repositories/coupon_repository.dart';
import 'features/coupon/domain/usecases/coupon_usecases.dart';
import 'features/coupon/presentation/bloc/coupon_bloc.dart';

// Partner Dashboard
import 'features/partner_dashboard/data/datasources/partner_remote_datasource.dart';
import 'features/partner_dashboard/data/repositories/partner_repository_impl.dart';
import 'features/partner_dashboard/domain/repositories/partner_repository.dart';
import 'features/partner_dashboard/domain/usecases/partner_usecases.dart';
import 'features/partner_dashboard/presentation/bloc/partner_bloc.dart';

// Admin
import 'features/admin/data/datasources/admin_remote_datasource.dart';
import 'features/admin/data/repositories/admin_repository_impl.dart';
import 'features/admin/domain/repositories/admin_repository.dart';
import 'features/admin/domain/usecases/admin_usecases.dart';
import 'features/admin/presentation/bloc/admin_bloc.dart';

// Notification
import 'features/notification/data/datasources/notification_remote_datasource.dart';
import 'features/notification/data/repositories/notification_repository_impl.dart';
import 'features/notification/domain/repositories/notification_repository.dart';
import 'features/notification/domain/usecases/notification_usecases.dart';
import 'features/notification/presentation/bloc/notification_bloc.dart';

final sl = GetIt.instance;

void configureDependencies() {
  // External
  sl.registerLazySingleton(() => Supabase.instance.client);
  sl.registerLazySingleton(() => Connectivity());

  // Core
  sl.registerLazySingleton<NetworkInfo>(() => NetworkInfoImpl(sl()));

  // ==================== AUTH ====================
  sl.registerLazySingleton<AuthRemoteDataSource>(
    () => AuthRemoteDataSourceImpl(sl()),
  );
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(remoteDataSource: sl(), networkInfo: sl()),
  );
  sl.registerLazySingleton(() => SignIn(sl()));
  sl.registerLazySingleton(() => SignUp(sl()));
  sl.registerLazySingleton(() => SignOut(sl()));
  sl.registerLazySingleton(() => GetCurrentUser(sl()));
  sl.registerLazySingleton(() => VerifyOtp(sl()));
  sl.registerFactory(() => AuthBloc(
        signIn: sl(),
        signUp: sl(),
        signOut: sl(),
        getCurrentUser: sl(),
        verifyOtp: sl(),
      ));

  // ==================== STORE DISCOVERY ====================
  sl.registerLazySingleton<StoreRemoteDataSource>(
    () => StoreRemoteDataSourceImpl(sl()),
  );
  sl.registerLazySingleton<StoreRepository>(
    () => StoreRepositoryImpl(remoteDataSource: sl(), networkInfo: sl()),
  );
  sl.registerLazySingleton(() => GetRotatedStores(sl()));
  sl.registerLazySingleton(() => GetStoreDetail(sl()));
  sl.registerLazySingleton(() => GetStoreProducts(sl()));
  sl.registerLazySingleton(() => WatchStoreProducts(sl()));
  sl.registerFactory(() => StoreBloc(
        getRotatedStores: sl(),
        getStoreDetail: sl(),
        getStoreProducts: sl(),
        watchStoreProducts: sl(),
      ));

  // ==================== ORDER ====================
  sl.registerLazySingleton<OrderRemoteDataSource>(
    () => OrderRemoteDataSourceImpl(sl()),
  );
  sl.registerLazySingleton<OrderRepository>(
    () => OrderRepositoryImpl(remoteDataSource: sl(), networkInfo: sl()),
  );
  sl.registerLazySingleton(() => CreateReservation(sl()));
  sl.registerLazySingleton(() => GetOrderHistory(sl()));
  sl.registerLazySingleton(() => GetOrderDetail(sl()));
  sl.registerLazySingleton(() => InitiatePayment(sl()));
  sl.registerFactory(() => OrderBloc(
        createReservation: sl(),
        getOrderHistory: sl(),
        getOrderDetail: sl(),
        initiatePayment: sl(),
      ));

  // ==================== COUPON ====================
  sl.registerLazySingleton<CouponRemoteDataSource>(
    () => CouponRemoteDataSourceImpl(sl()),
  );
  sl.registerLazySingleton<CouponRepository>(
    () => CouponRepositoryImpl(remoteDataSource: sl(), networkInfo: sl()),
  );
  sl.registerLazySingleton(() => ShowCoupon(sl()));
  sl.registerLazySingleton(() => GetUserCoupons(sl()));
  sl.registerLazySingleton(() => ValidateCoupon(sl()));
  sl.registerFactory(() => CouponBloc(
        showCoupon: sl(),
        getUserCoupons: sl(),
        validateCoupon: sl(),
      ));

  // ==================== PARTNER ====================
  sl.registerLazySingleton<PartnerRemoteDataSource>(
    () => PartnerRemoteDataSourceImpl(sl()),
  );
  sl.registerLazySingleton<PartnerRepository>(
    () => PartnerRepositoryImpl(remoteDataSource: sl(), networkInfo: sl()),
  );
  sl.registerLazySingleton(() => InputSurplus(sl()));
  sl.registerLazySingleton(() => UpdateStock(sl()));
  sl.registerLazySingleton(() => GetPartnerSales(sl()));
  sl.registerLazySingleton(() => GetPartnerProfile(sl()));
  sl.registerFactory(() => PartnerBloc(
        inputSurplus: sl(),
        updateStock: sl(),
        getPartnerSales: sl(),
        getPartnerProfile: sl(),
      ));

  // ==================== ADMIN ====================
  sl.registerLazySingleton<AdminRemoteDataSource>(
    () => AdminRemoteDataSourceImpl(sl()),
  );
  sl.registerLazySingleton<AdminRepository>(
    () => AdminRepositoryImpl(remoteDataSource: sl(), networkInfo: sl()),
  );
  sl.registerLazySingleton(() => GetAllPartners(sl()));
  sl.registerLazySingleton(() => ApprovePartner(sl()));
  sl.registerLazySingleton(() => SuspendPartner(sl()));
  sl.registerLazySingleton(() => GetPlatformAnalytics(sl()));
  sl.registerLazySingleton(() => GetFoodWasteData(sl()));
  sl.registerLazySingleton(() => BroadcastNotification(sl()));
  sl.registerFactory(() => AdminBloc(
        getAllPartners: sl(),
        approvePartner: sl(),
        suspendPartner: sl(),
        getPlatformAnalytics: sl(),
        getFoodWasteData: sl(),
        broadcastNotification: sl(),
      ));

  // ==================== NOTIFICATION ====================
  sl.registerLazySingleton<NotificationRemoteDataSource>(
    () => NotificationRemoteDataSourceImpl(sl()),
  );
  sl.registerLazySingleton<NotificationRepository>(
    () => NotificationRepositoryImpl(remoteDataSource: sl(), networkInfo: sl()),
  );
  sl.registerLazySingleton(() => GetUserNotifications(sl()));
  sl.registerLazySingleton(() => MarkNotificationRead(sl()));
  sl.registerFactory(() => NotificationBloc(
        getUserNotifications: sl(),
        markNotificationRead: sl(),
      ));
}

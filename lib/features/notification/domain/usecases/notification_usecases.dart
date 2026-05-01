import 'package:dartz/dartz.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/notification_repository.dart';
class GetUserNotifications extends UseCase<List<Map<String, dynamic>>, String> { final NotificationRepository r; GetUserNotifications(this.r); @override Future<Either<Failure, List<Map<String, dynamic>>>> call(String userId) => r.getUserNotifications(userId); }
class MarkNotificationRead extends UseCase<void, String> { final NotificationRepository r; MarkNotificationRead(this.r); @override Future<Either<Failure, void>> call(String id) => r.markNotificationRead(id); }

import 'package:dartz/dartz.dart';
import '../../../../core/errors/failure.dart';
abstract class NotificationRepository {
  Future<Either<Failure, List<Map<String, dynamic>>>> getUserNotifications(String userId);
  Future<Either<Failure, void>> markNotificationRead(String notifId);
}

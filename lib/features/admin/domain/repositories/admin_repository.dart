import 'package:dartz/dartz.dart';
import '../../../../core/errors/failure.dart';
abstract class AdminRepository {
  Future<Either<Failure, List<Map<String, dynamic>>>> getAllPartners();
  Future<Either<Failure, void>> approvePartner(String partnerId);
  Future<Either<Failure, void>> suspendPartner(String partnerId);
  Future<Either<Failure, Map<String, dynamic>>> getPlatformAnalytics();
  Future<Either<Failure, Map<String, dynamic>>> getFoodWasteData();
  Future<Either<Failure, void>> broadcastNotification({required String title, required String body});
}

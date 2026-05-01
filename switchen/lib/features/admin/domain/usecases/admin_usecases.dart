import 'package:dartz/dartz.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/admin_repository.dart';
class GetAllPartners extends UseCaseNoParams<List<Map<String, dynamic>>> { final AdminRepository r; GetAllPartners(this.r); @override Future<Either<Failure, List<Map<String, dynamic>>>> call() => r.getAllPartners(); }
class ApprovePartner extends UseCase<void, String> { final AdminRepository r; ApprovePartner(this.r); @override Future<Either<Failure, void>> call(String id) => r.approvePartner(id); }
class SuspendPartner extends UseCase<void, String> { final AdminRepository r; SuspendPartner(this.r); @override Future<Either<Failure, void>> call(String id) => r.suspendPartner(id); }
class GetPlatformAnalytics extends UseCaseNoParams<Map<String, dynamic>> { final AdminRepository r; GetPlatformAnalytics(this.r); @override Future<Either<Failure, Map<String, dynamic>>> call() => r.getPlatformAnalytics(); }
class GetFoodWasteData extends UseCaseNoParams<Map<String, dynamic>> { final AdminRepository r; GetFoodWasteData(this.r); @override Future<Either<Failure, Map<String, dynamic>>> call() => r.getFoodWasteData(); }
class BroadcastParams { final String title; final String body; const BroadcastParams({required this.title, required this.body}); }
class BroadcastNotification extends UseCase<void, BroadcastParams> { final AdminRepository r; BroadcastNotification(this.r); @override Future<Either<Failure, void>> call(BroadcastParams p) => r.broadcastNotification(title: p.title, body: p.body); }

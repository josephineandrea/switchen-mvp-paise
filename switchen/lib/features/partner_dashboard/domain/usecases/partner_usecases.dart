import 'package:dartz/dartz.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/partner_repository.dart';
class GetPartnerProfile extends UseCase<Map<String, dynamic>, String> {
  final PartnerRepository r; GetPartnerProfile(this.r);
  @override Future<Either<Failure, Map<String, dynamic>>> call(String userId) => r.getPartnerProfile(userId);
}
class InputSurplus extends UseCase<Map<String, dynamic>, Map<String, dynamic>> {
  final PartnerRepository r; InputSurplus(this.r);
  @override Future<Either<Failure, Map<String, dynamic>>> call(Map<String, dynamic> data) => r.inputSurplus(data);
}
class UpdateStockParams { final String productId; final int qty; const UpdateStockParams({required this.productId, required this.qty}); }
class UpdateStock extends UseCase<void, UpdateStockParams> {
  final PartnerRepository r; UpdateStock(this.r);
  @override Future<Either<Failure, void>> call(UpdateStockParams p) => r.updateStock(p.productId, p.qty);
}
class GetPartnerSales extends UseCase<List<Map<String, dynamic>>, String> {
  final PartnerRepository r; GetPartnerSales(this.r);
  @override Future<Either<Failure, List<Map<String, dynamic>>>> call(String partnerId) => r.getPartnerSales(partnerId);
}

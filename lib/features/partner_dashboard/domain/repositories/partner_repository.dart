import 'package:dartz/dartz.dart';
import '../../../../core/errors/failure.dart';
abstract class PartnerRepository {
  Future<Either<Failure, Map<String, dynamic>>> getPartnerProfile(String userId);
  Future<Either<Failure, Map<String, dynamic>>> inputSurplus(Map<String, dynamic> productData);
  Future<Either<Failure, void>> updateStock(String productId, int qty);
  Future<Either<Failure, List<Map<String, dynamic>>>> getPartnerSales(String partnerId);
}

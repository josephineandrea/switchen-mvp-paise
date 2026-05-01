import 'package:equatable/equatable.dart';

class StoreEntity extends Equatable {
  final String id;
  final String name;
  final String address;
  final double lat;
  final double lng;
  final String category;
  final String status;
  final int rotationWeight;
  final String? logoUrl;
  final double? distanceKm;
  final int availableProducts;

  const StoreEntity({
    required this.id,
    required this.name,
    required this.address,
    required this.lat,
    required this.lng,
    required this.category,
    required this.status,
    required this.rotationWeight,
    this.logoUrl,
    this.distanceKm,
    this.availableProducts = 0,
  });

  @override
  List<Object?> get props => [id];
}

class ProductEntity extends Equatable {
  final String id;
  final String partnerId;
  final String name;
  final String? imageUrl;
  final double originalPrice;
  final double surplusPrice;
  final int stockQty;
  final DateTime? expiredAt;
  final bool isActive;

  const ProductEntity({
    required this.id,
    required this.partnerId,
    required this.name,
    this.imageUrl,
    required this.originalPrice,
    required this.surplusPrice,
    required this.stockQty,
    this.expiredAt,
    required this.isActive,
  });

  double get discountPercent =>
      ((originalPrice - surplusPrice) / originalPrice * 100).roundToDouble();

  bool get isAvailable => isActive && stockQty > 0;

  @override
  List<Object?> get props => [id];
}

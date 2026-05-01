import '../../domain/entities/store_entity.dart';

class ProductModel extends ProductEntity {
  const ProductModel({required super.id, required super.partnerId, required super.name, super.imageUrl, required super.originalPrice, required super.surplusPrice, required super.stockQty, super.expiredAt, required super.isActive});

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: json['id'] as String,
      partnerId: json['partner_id'] as String,
      name: json['name'] as String,
      imageUrl: json['image_url'] as String?,
      originalPrice: (json['original_price'] as num).toDouble(),
      surplusPrice: (json['surplus_price'] as num).toDouble(),
      stockQty: (json['stock_qty'] as num).toInt(),
      expiredAt: json['expired_at'] != null ? DateTime.parse(json['expired_at'] as String) : null,
      isActive: json['is_active'] as bool? ?? true,
    );
  }
}

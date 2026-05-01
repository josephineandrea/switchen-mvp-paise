import '../../domain/entities/store_entity.dart';

class StoreModel extends StoreEntity {
  const StoreModel({required super.id, required super.name, required super.address, required super.lat, required super.lng, required super.category, required super.status, required super.rotationWeight, super.logoUrl, super.distanceKm, super.availableProducts});

  factory StoreModel.fromJson(Map<String, dynamic> json) {
    return StoreModel(
      id: json['id'] as String,
      name: json['name'] as String,
      address: json['address'] as String,
      lat: (json['lat'] as num).toDouble(),
      lng: (json['lng'] as num).toDouble(),
      category: json['category'] as String,
      status: json['status'] as String,
      rotationWeight: (json['rotation_weight'] as num?)?.toInt() ?? 100,
      logoUrl: json['logo_url'] as String?,
      distanceKm: (json['distance_km'] as num?)?.toDouble(),
      availableProducts: (json['available_products'] as num?)?.toInt() ?? 0,
    );
  }
}

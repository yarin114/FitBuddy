// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pantry_item.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$PantryItemImpl _$$PantryItemImplFromJson(Map<String, dynamic> json) =>
    _$PantryItemImpl(
      id: json['id'] as String,
      name: json['name'] as String,
      quantity: (json['quantity'] as num).toDouble(),
      unit: json['unit'] as String,
      expiryDate: DateTime.parse(json['expiryDate'] as String),
      confidenceScore: (json['confidenceScore'] as num?)?.toDouble() ?? 1.0,
      needsVerification: json['needsVerification'] as bool? ?? false,
      nutritionPer100g:
          (json['nutritionPer100g'] as Map<String, dynamic>?)?.map(
        (k, e) => MapEntry(k, (e as num).toDouble()),
      ),
    );

Map<String, dynamic> _$$PantryItemImplToJson(_$PantryItemImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'quantity': instance.quantity,
      'unit': instance.unit,
      'expiryDate': instance.expiryDate.toIso8601String(),
      'confidenceScore': instance.confidenceScore,
      'needsVerification': instance.needsVerification,
      'nutritionPer100g': instance.nutritionPer100g,
    };

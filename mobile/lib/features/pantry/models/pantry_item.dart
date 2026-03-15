import 'package:freezed_annotation/freezed_annotation.dart';

part 'pantry_item.freezed.dart';
part 'pantry_item.g.dart';

/// A single item in the user's pantry / fridge inventory.
///
/// [confidenceScore] — 0.0–1.0, produced by the OCR fuzzy-matcher.
///   ≥ 0.85  → high confidence (green)
///   0.70–0.85 → medium confidence (amber, manual review recommended)
///   < 0.70  → low confidence (red, [needsVerification] = true, must be reviewed)
///
/// [nutritionPer100g] — optional map of macro keys to values:
///   {'calories': 165.0, 'protein': 31.0, 'carbs': 0.0, 'fat': 3.6}
@freezed
abstract class PantryItem with _$PantryItem {
  const factory PantryItem({
    required String   id,
    required String   name,
    required double   quantity,
    required String   unit,        // 'g' | 'ml' | 'units'
    required DateTime expiryDate,
    @Default(1.0)  double confidenceScore,
    @Default(false) bool  needsVerification,
    Map<String, double>?  nutritionPer100g,
  }) = _PantryItem;

  factory PantryItem.fromJson(Map<String, dynamic> json) =>
      _$PantryItemFromJson(json);
}

/// Category hint derived from the item name — drives the leading icon
/// in [PantryItemCard].
enum PantryCategory { meat, dairy, vegetable, fruit, grain, beverage, other }

extension PantryItemCategory on PantryItem {
  PantryCategory get category {
    final n = name.toLowerCase();
    if (_matches(n, ['chicken', 'beef', 'pork', 'turkey', 'tuna', 'salmon', 'egg'])) {
      return PantryCategory.meat;
    }
    if (_matches(n, ['milk', 'yogurt', 'cheese', 'cream', 'butter'])) {
      return PantryCategory.dairy;
    }
    if (_matches(n, ['broccoli', 'spinach', 'carrot', 'tomato', 'cucumber', 'onion', 'garlic', 'pepper'])) {
      return PantryCategory.vegetable;
    }
    if (_matches(n, ['apple', 'banana', 'orange', 'strawberry', 'blueberry', 'mango'])) {
      return PantryCategory.fruit;
    }
    if (_matches(n, ['rice', 'pasta', 'bread', 'oat', 'wheat', 'flour', 'quinoa'])) {
      return PantryCategory.grain;
    }
    if (_matches(n, ['water', 'juice', 'milk', 'coffee', 'tea'])) {
      return PantryCategory.beverage;
    }
    return PantryCategory.other;
  }

  bool _matches(String name, List<String> keywords) =>
      keywords.any((k) => name.contains(k));

  /// True if expiry is within the next 3 days.
  bool get isExpiringSoon {
    final threshold = DateTime.now().add(const Duration(days: 3));
    return expiryDate.isBefore(threshold);
  }

  /// True if the item has been fully consumed.
  bool get isEmpty => quantity <= 0;
}

import 'package:uuid/uuid.dart';

import '../models/pantry_item.dart';

/// DebugPantryService — realistic 15-item seed dataset for UI stress-testing.
///
/// Seed composition:
///   3 items expiring today       → fires Expiring Soon strip
///   5 items needsVerification    → fires unverified badge in AppBar
///   7 confirmed fitness items    → populates inventory list
///
/// Usage:
///   ref.read(pantryNotifierProvider.notifier)
///      .addItemsFromReceipt(DebugPantryService.seedItems());
abstract final class DebugPantryService {
  static const _uuid = Uuid();

  static List<PantryItem> seedItems() {
    final now   = DateTime.now();
    // End-of-day today so isExpiringSoon fires on all "today" items
    final today = DateTime(now.year, now.month, now.day, 23, 59);

    return [
      // ── Expiring TODAY (3) ─────────────────────────────────────────────────
      PantryItem(
        id:              _uuid.v4(),
        name:            'Chicken Breast',
        quantity:        400,
        unit:            'g',
        expiryDate:      today,
        confidenceScore: 0.97,
        nutritionPer100g: const {
          'calories': 165.0, 'protein': 31.0, 'carbs': 0.0, 'fat': 3.6,
        },
      ),
      PantryItem(
        id:              _uuid.v4(),
        name:            'Greek Yogurt',
        quantity:        200,
        unit:            'g',
        expiryDate:      today,
        confidenceScore: 0.94,
        nutritionPer100g: const {
          'calories': 59.0, 'protein': 10.0, 'carbs': 3.6, 'fat': 0.4,
        },
      ),
      PantryItem(
        id:              _uuid.v4(),
        name:            'Spinach',
        quantity:        150,
        unit:            'g',
        expiryDate:      today,
        confidenceScore: 0.91,
        nutritionPer100g: const {
          'calories': 23.0, 'protein': 2.9, 'carbs': 3.6, 'fat': 0.4,
        },
      ),

      // ── Needs Verification — 5 low-confidence OCR artefacts ───────────────
      PantryItem(
        id:               _uuid.v4(),
        name:             'Whey Protien',   // intentional OCR typo
        quantity:         500,
        unit:             'g',
        expiryDate:       today.add(const Duration(days: 120)),
        confidenceScore:  0.61,
        needsVerification: true,
        nutritionPer100g: const {
          'calories': 400.0, 'protein': 80.0, 'carbs': 8.0, 'fat': 5.0,
        },
      ),
      PantryItem(
        id:               _uuid.v4(),
        name:             'BROC FLORETS',   // all-caps OCR abbreviation
        quantity:         300,
        unit:             'g',
        expiryDate:       today.add(const Duration(days: 4)),
        confidenceScore:  0.58,
        needsVerification: true,
        nutritionPer100g: const {
          'calories': 34.0, 'protein': 2.8, 'carbs': 7.0, 'fat': 0.4,
        },
      ),
      PantryItem(
        id:               _uuid.v4(),
        name:             'Almd Milk',      // truncated
        quantity:         1,
        unit:             'L',
        expiryDate:       today.add(const Duration(days: 7)),
        confidenceScore:  0.52,
        needsVerification: true,
      ),
      PantryItem(
        id:               _uuid.v4(),
        name:             'CHKN THIGHS',    // common abbreviation
        quantity:         600,
        unit:             'g',
        expiryDate:       today.add(const Duration(days: 2)),
        confidenceScore:  0.64,
        needsVerification: true,
        nutritionPer100g: const {
          'calories': 209.0, 'protein': 26.0, 'carbs': 0.0, 'fat': 11.0,
        },
      ),
      PantryItem(
        id:               _uuid.v4(),
        name:             'Blk Bean Tin',   // abbreviated
        quantity:         400,
        unit:             'g',
        expiryDate:       today.add(const Duration(days: 365)),
        confidenceScore:  0.67,
        needsVerification: true,
        nutritionPer100g: const {
          'calories': 132.0, 'protein': 8.9, 'carbs': 24.0, 'fat': 0.5,
        },
      ),

      // ── Confirmed fitness items (7) ────────────────────────────────────────
      PantryItem(
        id:              _uuid.v4(),
        name:            'Rolled Oats',
        quantity:        800,
        unit:            'g',
        expiryDate:      today.add(const Duration(days: 180)),
        confidenceScore: 0.95,
        nutritionPer100g: const {
          'calories': 389.0, 'protein': 17.0, 'carbs': 66.0, 'fat': 7.0,
        },
      ),
      PantryItem(
        id:              _uuid.v4(),
        name:            'Eggs',
        quantity:        12,
        unit:            'pcs',
        expiryDate:      today.add(const Duration(days: 14)),
        confidenceScore: 0.99,
        nutritionPer100g: const {
          'calories': 155.0, 'protein': 13.0, 'carbs': 1.1, 'fat': 11.0,
        },
      ),
      PantryItem(
        id:              _uuid.v4(),
        name:            'Brown Rice',
        quantity:        1000,
        unit:            'g',
        expiryDate:      today.add(const Duration(days: 365)),
        confidenceScore: 0.96,
        nutritionPer100g: const {
          'calories': 370.0, 'protein': 8.0, 'carbs': 77.0, 'fat': 2.7,
        },
      ),
      PantryItem(
        id:              _uuid.v4(),
        name:            'Broccoli',
        quantity:        500,
        unit:            'g',
        expiryDate:      today.add(const Duration(days: 5)),
        confidenceScore: 0.93,
        nutritionPer100g: const {
          'calories': 34.0, 'protein': 2.8, 'carbs': 7.0, 'fat': 0.4,
        },
      ),
      PantryItem(
        id:              _uuid.v4(),
        name:            'Banana',
        quantity:        4,
        unit:            'pcs',
        expiryDate:      today.add(const Duration(days: 3)),
        confidenceScore: 0.98,
        nutritionPer100g: const {
          'calories': 89.0, 'protein': 1.1, 'carbs': 23.0, 'fat': 0.3,
        },
      ),
      PantryItem(
        id:              _uuid.v4(),
        name:            'Olive Oil',
        quantity:        500,
        unit:            'ml',
        expiryDate:      today.add(const Duration(days: 730)),
        confidenceScore: 0.94,
        nutritionPer100g: const {
          'calories': 884.0, 'protein': 0.0, 'carbs': 0.0, 'fat': 100.0,
        },
      ),
      PantryItem(
        id:              _uuid.v4(),
        name:            'Salmon Fillet',
        quantity:        300,
        unit:            'g',
        expiryDate:      today.add(const Duration(days: 2)),
        confidenceScore: 0.89,
        nutritionPer100g: const {
          'calories': 208.0, 'protein': 20.0, 'carbs': 0.0, 'fat': 13.0,
        },
      ),
    ];
  }
}

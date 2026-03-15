import 'dart:math';

import 'package:uuid/uuid.dart';

import '../models/pantry_item.dart';

/// PantryService — OCR receipt parsing + nutritional fuzzy matching.
///
/// Phase 1: OCR is mocked. The real implementation will call the backend
/// endpoint POST /api/v1/receipts/parse which runs the actual OCR agent.
///
/// Fuzzy matching uses an inline Levenshtein similarity score (0.0–1.0)
/// against a hardcoded nutritional database. This avoids a runtime
/// dependency for what is currently mock data.
class PantryService {
  static const _uuid = Uuid();

  // ── Mock nutritional database ─────────────────────────────────────────────
  // In production this will be a proper nutritional API lookup.
  static const Map<String, Map<String, double>> _nutritionDb = {
    'chicken breast':   {'calories': 165, 'protein': 31, 'carbs': 0,   'fat': 3.6},
    'ground beef':      {'calories': 250, 'protein': 26, 'carbs': 0,   'fat': 17},
    'salmon fillet':    {'calories': 208, 'protein': 20, 'carbs': 0,   'fat': 13},
    'tuna can':         {'calories': 132, 'protein': 28, 'carbs': 0,   'fat': 2.9},
    'egg':              {'calories': 155, 'protein': 13, 'carbs': 1.1, 'fat': 11},
    'whole milk':       {'calories': 61,  'protein': 3.2,'carbs': 4.8, 'fat': 3.3},
    'greek yogurt':     {'calories': 59,  'protein': 10, 'carbs': 3.6, 'fat': 0.4},
    'cheddar cheese':   {'calories': 402, 'protein': 25, 'carbs': 1.3, 'fat': 33},
    'broccoli':         {'calories': 34,  'protein': 2.8,'carbs': 7,   'fat': 0.4},
    'spinach':          {'calories': 23,  'protein': 2.9,'carbs': 3.6, 'fat': 0.4},
    'sweet potato':     {'calories': 86,  'protein': 1.6,'carbs': 20,  'fat': 0.1},
    'banana':           {'calories': 89,  'protein': 1.1,'carbs': 23,  'fat': 0.3},
    'apple':            {'calories': 52,  'protein': 0.3,'carbs': 14,  'fat': 0.2},
    'brown rice':       {'calories': 216, 'protein': 5,  'carbs': 45,  'fat': 1.8},
    'white pasta':      {'calories': 158, 'protein': 5.8,'carbs': 31,  'fat': 0.9},
    'rolled oats':      {'calories': 389, 'protein': 17, 'carbs': 66,  'fat': 7},
    'olive oil':        {'calories': 884, 'protein': 0,  'carbs': 0,   'fat': 100},
    'almond butter':    {'calories': 614, 'protein': 21, 'carbs': 19,  'fat': 56},
    'whey protein':     {'calories': 400, 'protein': 80, 'carbs': 8,   'fat': 5},
  };

  // ── Mock receipt data ─────────────────────────────────────────────────────
  // Simulates what an OCR engine might extract from a supermarket receipt.
  // Raw strings intentionally have typos and abbreviations.
  static const List<Map<String, dynamic>> _mockReceiptLines = [
    {'raw': 'CHKN BREAST 500G',        'quantity': 500,  'unit': 'g'},
    {'raw': 'BROCOLI FLORETS 400G',    'quantity': 400,  'unit': 'g'},
    {'raw': 'Brown Rice 1KG',          'quantity': 1000, 'unit': 'g'},
    {'raw': 'Greek Yoghurt 500ML',     'quantity': 500,  'unit': 'ml'},
    {'raw': 'Eggs x12',                'quantity': 12,   'unit': 'units'},
    {'raw': 'Salman Fillet 250g',      'quantity': 250,  'unit': 'g'},
    {'raw': 'Wht Pasta 500G',          'quantity': 500,  'unit': 'g'},
    {'raw': 'Bnna 6 units',            'quantity': 6,    'unit': 'units'},
    {'raw': 'Olive Oyl 1L',            'quantity': 1000, 'unit': 'ml'},
    {'raw': 'XYZ PRODUCT 200G',        'quantity': 200,  'unit': 'g'},  // unrecognised
  ];

  /// Parse a mock receipt and return a list of [PantryItem]s with
  /// confidence scores. Items scoring < 0.70 will have [needsVerification] = true.
  ///
  /// In production: replace [_mockReceiptLines] with OCR text from [imageXFile].
  Future<List<PantryItem>> parseReceiptMock() async {
    // Simulate network/processing delay
    await Future.delayed(const Duration(milliseconds: 1200));

    final now = DateTime.now();
    final results = <PantryItem>[];

    for (final line in _mockReceiptLines) {
      final raw = (line['raw'] as String).toLowerCase();
      final match = _bestMatch(raw);
      final confidence = match.$2;

      results.add(PantryItem(
        id:                _uuid.v4(),
        name:              match.$1,
        quantity:          (line['quantity'] as num).toDouble(),
        unit:              line['unit'] as String,
        expiryDate:        _estimateExpiry(now, match.$1),
        confidenceScore:   confidence,
        needsVerification: confidence < 0.70,
        nutritionPer100g:  _nutritionDb[match.$1],
      ));
    }

    return results;
  }

  // ── Fuzzy matching ────────────────────────────────────────────────────────

  /// Returns the best matching database key and its similarity score.
  (String, double) _bestMatch(String rawInput) {
    String bestKey   = rawInput;
    double bestScore = 0.0;

    for (final dbKey in _nutritionDb.keys) {
      // Compare both direct similarity and token-level partial match
      final directScore  = _similarity(rawInput, dbKey);
      final partialScore = _partialTokenScore(rawInput, dbKey);
      final score        = max(directScore, partialScore);

      if (score > bestScore) {
        bestScore = score;
        bestKey   = dbKey;
      }
    }

    // If no match beats 0.40, return the raw input as-is (unrecognised item)
    if (bestScore < 0.40) return (rawInput, 0.20);
    return (bestKey, bestScore);
  }

  /// Levenshtein-based similarity: 1.0 = identical, 0.0 = completely different.
  double _similarity(String a, String b) {
    if (a == b) return 1.0;
    final maxLen = max(a.length, b.length);
    if (maxLen == 0) return 1.0;
    return 1.0 - (_levenshtein(a, b) / maxLen);
  }

  /// Partial token matching: split both strings into words and find
  /// the best pairwise word similarity. Handles abbreviations like "CHKN" → "chicken".
  double _partialTokenScore(String raw, String dbKey) {
    final rawTokens = raw.split(RegExp(r'[\s_\-]+'));
    final dbTokens  = dbKey.split(RegExp(r'[\s_\-]+'));
    double total = 0;
    int    count = 0;

    for (final rt in rawTokens) {
      if (rt.length < 2) continue;
      double best = 0;
      for (final dt in dbTokens) {
        final s = _similarity(rt, dt);
        if (s > best) best = s;
      }
      total += best;
      count++;
    }
    return count == 0 ? 0 : total / count;
  }

  int _levenshtein(String a, String b) {
    final m = a.length, n = b.length;
    final dp = List.generate(m + 1, (_) => List.filled(n + 1, 0));
    for (var i = 0; i <= m; i++) dp[i][0] = i;
    for (var j = 0; j <= n; j++) dp[0][j] = j;

    for (var i = 1; i <= m; i++) {
      for (var j = 1; j <= n; j++) {
        dp[i][j] = a[i - 1] == b[j - 1]
            ? dp[i - 1][j - 1]
            : 1 + [dp[i - 1][j], dp[i][j - 1], dp[i - 1][j - 1]].reduce(min);
      }
    }
    return dp[m][n];
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  /// Estimate expiry based on category. Production: use expiry date from receipt.
  DateTime _estimateExpiry(DateTime now, String itemName) {
    final n = itemName.toLowerCase();
    if (_containsAny(n, ['chicken', 'beef', 'pork', 'salmon', 'tuna'])) {
      return now.add(const Duration(days: 3));
    }
    if (_containsAny(n, ['milk', 'yogurt', 'cream'])) {
      return now.add(const Duration(days: 7));
    }
    if (_containsAny(n, ['egg', 'cheese'])) {
      return now.add(const Duration(days: 14));
    }
    if (_containsAny(n, ['broccoli', 'spinach', 'banana'])) {
      return now.add(const Duration(days: 5));
    }
    return now.add(const Duration(days: 30)); // dry goods
  }

  bool _containsAny(String s, List<String> words) =>
      words.any((w) => s.contains(w));
}

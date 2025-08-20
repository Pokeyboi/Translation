import 'dart:convert';
import 'dart:math';
import '../models/dictionary_entry.dart';
import '../models/phrase_entry.dart';
import '../models/language_pack.dart';
import '../models/translation_result.dart';
import 'database_service.dart';

class TranslationEngine {
  static const double phraseExactWeight = 100.0;
  static const double phrasePatternWeight = 90.0;
  static const double wordAssemblyWeight = 70.0;
  static const double wordExactWeight = 80.0;
  static const double wordFuzzyWeight = 50.0;
  static const double mtWeight = 30.0;

  static const double verifiedBonus = 20.0;
  static const double recencyBonus = 10.0;
  static const double categoryBonus = 15.0;

  /// Main translation entry point
  static Future<TranslationResult> translateText(
    String englishText,
    String languageCode, {
    String? contextCategory,
    Map<String, String>? variables,
  }) async {
    if (englishText.trim().isEmpty) {
      return TranslationResult.noMatch(englishText);
    }

    // Normalize input
    final normalizedText = _normalizeText(englishText);
    
    try {
      // Try word exact match first (simpler implementation)
      final wordExactResult = await _tryWordExactMatch(
        normalizedText, languageCode, contextCategory
      );
      if (wordExactResult != null) return wordExactResult;

      // Try fuzzy match
      final fuzzyResult = await _tryFuzzyMatch(
        normalizedText, languageCode, contextCategory
      );
      if (fuzzyResult != null) return fuzzyResult;

      return TranslationResult.noMatch(englishText);

    } catch (e) {
      print('Translation error: $e');
      return TranslationResult.noMatch(englishText);
    }
  }

  /// Word exact match (single token)
  static Future<TranslationResult?> _tryWordExactMatch(
    String normalizedText,
    String languageCode,
    String? contextCategory,
  ) async {
    final entries = await DatabaseService.searchDictionary(
      normalizedText,
      languageCode: languageCode,
    );

    DictionaryEntry? bestEntry;
    double bestScore = 0.0;

    for (final entry in entries) {
      if (_normalizeText(entry.english) == normalizedText) {
        final score = _calculateScore(
          baseWeight: wordExactWeight,
          verified: entry.verified,
          createdAt: entry.updatedAt,
          category: entry.category,
          contextCategory: contextCategory,
        );

        if (score > bestScore) {
          bestEntry = entry;
          bestScore = score;
        }
      }
    }

    if (bestEntry != null) {
      return TranslationResult(
        text: bestEntry.translation,
        confidence: bestEntry.verified 
            ? TranslationConfidence.high 
            : TranslationConfidence.medium,
        matchType: TranslationMatchType.wordExact,
        usedEntryIds: [bestEntry.id],
        score: bestScore,
        notes: bestEntry.notes,
      );
    }

    return null;
  }

  /// Fuzzy word/phrase match
  static Future<TranslationResult?> _tryFuzzyMatch(
    String normalizedText,
    String languageCode,
    String? contextCategory,
  ) async {
    // Check dictionary entries
    final entries = await DatabaseService.searchDictionary(
      normalizedText.split(' ').first,
      languageCode: languageCode,
    );

    DictionaryEntry? bestEntry;
    double bestScore = 0.0;

    for (final entry in entries) {
      final distance = _editDistance(
        _removeDiacritics(normalizedText),
        _removeDiacritics(_normalizeText(entry.english))
      );

      if (distance <= 2) {
        final score = _calculateScore(
          baseWeight: wordFuzzyWeight - (distance * 5),
          verified: entry.verified,
          createdAt: entry.updatedAt,
          category: entry.category,
          contextCategory: contextCategory,
        );

        if (score > bestScore) {
          bestEntry = entry;
          bestScore = score;
        }
      }
    }

    if (bestEntry != null) {
      return TranslationResult(
        text: bestEntry.translation,
        confidence: TranslationConfidence.low,
        matchType: TranslationMatchType.wordFuzzy,
        usedEntryIds: [bestEntry.id],
        score: bestScore,
        notes: 'Fuzzy match',
      );
    }

    return null;
  }

  // Utility Methods

  static String _normalizeText(String text) {
    return text
        .toLowerCase()
        .trim()
        .replaceAll(RegExp(r'[^\w\s{}]'), '')  // Keep {variables}
        .replaceAll(RegExp(r'\s+'), ' ');
  }

  static String _removeDiacritics(String text) {
    // Basic diacritic removal - can be enhanced
    return text
        .replaceAll(RegExp(r'[àáâãäå]'), 'a')
        .replaceAll(RegExp(r'[èéêë]'), 'e')
        .replaceAll(RegExp(r'[ìíîï]'), 'i')
        .replaceAll(RegExp(r'[òóôõö]'), 'o')
        .replaceAll(RegExp(r'[ùúûü]'), 'u');
  }

  static int _editDistance(String s1, String s2) {
    final matrix = List.generate(
      s1.length + 1,
      (i) => List.generate(s2.length + 1, (j) => 0),
    );

    for (int i = 0; i <= s1.length; i++) {
      matrix[i][0] = i;
    }
    for (int j = 0; j <= s2.length; j++) {
      matrix[0][j] = j;
    }

    for (int i = 1; i <= s1.length; i++) {
      for (int j = 1; j <= s2.length; j++) {
        if (s1[i - 1] == s2[j - 1]) {
          matrix[i][j] = matrix[i - 1][j - 1];
        } else {
          matrix[i][j] = min(
            min(matrix[i - 1][j], matrix[i][j - 1]),
            matrix[i - 1][j - 1],
          ) + 1;
        }
      }
    }

    return matrix[s1.length][s2.length];
  }

  static double _calculateScore({
    required double baseWeight,
    required bool verified,
    required DateTime createdAt,
    String? category,
    String? contextCategory,
  }) {
    double score = baseWeight;

    if (verified) score += verifiedBonus;

    // Recency bonus (more recent = better)
    final daysSinceUpdate = DateTime.now().difference(createdAt).inDays;
    if (daysSinceUpdate < 30) score += recencyBonus;

    // Category alignment bonus
    if (category != null && contextCategory != null && category == contextCategory) {
      score += categoryBonus;
    }

    return score;
  }
}
import 'package:flutter/material.dart';

enum TranslationMatchType {
  phraseExact,
  phrasePattern,
  wordAssembly,
  wordExact,
  wordFuzzy,
  machineTranslation,
  noMatch,
}

enum TranslationConfidence {
  high,
  medium,
  low,
  unknown,
}

class TranslationAlternative {
  final String text;
  final double score;
  final TranslationMatchType matchType;
  final List<String> usedEntryIds;
  final String? notes;

  TranslationAlternative({
    required this.text,
    required this.score,
    required this.matchType,
    this.usedEntryIds = const [],
    this.notes,
  });
}

class VariablePrompt {
  final String name;
  final String type;
  final String? format;
  final String displayName;

  VariablePrompt({
    required this.name,
    required this.type,
    this.format,
    String? displayName,
  }) : displayName = displayName ?? name;
}

class TranslationResult {
  final String text;
  final TranslationConfidence confidence;
  final TranslationMatchType matchType;
  final List<TranslationAlternative> alternatives;
  final List<String> usedEntryIds;
  final List<VariablePrompt> variablePrompts;
  final bool requiresVariableInput;
  final String? notes;
  final double score;

  TranslationResult({
    required this.text,
    required this.confidence,
    required this.matchType,
    this.alternatives = const [],
    this.usedEntryIds = const [],
    this.variablePrompts = const [],
    this.requiresVariableInput = false,
    this.notes,
    this.score = 0.0,
  });

  factory TranslationResult.noMatch(String originalText) {
    return TranslationResult(
      text: originalText,
      confidence: TranslationConfidence.unknown,
      matchType: TranslationMatchType.noMatch,
      score: 0.0,
    );
  }

  factory TranslationResult.machineTranslation(String translation, {double score = 0.3}) {
    return TranslationResult(
      text: translation,
      confidence: TranslationConfidence.low,
      matchType: TranslationMatchType.machineTranslation,
      notes: 'Machine translation',
      score: score,
    );
  }

  TranslationResult copyWithVariables(Map<String, String> variableValues) {
    if (!requiresVariableInput || variablePrompts.isEmpty) {
      return this;
    }

    String processedText = text;
    for (final variable in variablePrompts) {
      if (variableValues.containsKey(variable.name)) {
        final value = variableValues[variable.name]!;
        processedText = processedText.replaceAll('{${variable.name}}', value);
      }
    }

    return TranslationResult(
      text: processedText,
      confidence: confidence,
      matchType: matchType,
      alternatives: alternatives,
      usedEntryIds: usedEntryIds,
      variablePrompts: [],
      requiresVariableInput: false,
      notes: notes,
      score: score,
    );
  }

  bool get isSuccessful => matchType != TranslationMatchType.noMatch;

  Color getConfidenceColor() {
    switch (confidence) {
      case TranslationConfidence.high:
        return const Color(0xFF4CAF50); // Green
      case TranslationConfidence.medium:
        return const Color(0xFFFF9800); // Orange
      case TranslationConfidence.low:
        return const Color(0xFF9E9E9E); // Gray
      case TranslationConfidence.unknown:
        return const Color(0xFF757575); // Dark gray
    }
  }

  String get confidenceLabel {
    switch (confidence) {
      case TranslationConfidence.high:
        return 'Verified';
      case TranslationConfidence.medium:
        return 'Good match';
      case TranslationConfidence.low:
        return 'Machine translation';
      case TranslationConfidence.unknown:
        return 'No translation';
    }
  }
}
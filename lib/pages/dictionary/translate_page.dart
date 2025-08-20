import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/translation_result.dart';
import '../../services/translation_engine.dart';
import '../../services/database_service.dart';
import '../../models/language_pack.dart';
import '../../theme.dart';

class TranslatePage extends StatefulWidget {
  const TranslatePage({super.key});

  @override
  State<TranslatePage> createState() => _TranslatePageState();
}

class _TranslatePageState extends State<TranslatePage> {
  final TextEditingController _inputController = TextEditingController();
  final FocusNode _inputFocusNode = FocusNode();
  
  TranslationResult? _currentTranslation;
  bool _isTranslating = false;
  Timer? _debounceTimer;
  String _selectedLanguage = 'zopau';
  String _selectedCategory = 'General';
  List<LanguagePack> _availableLanguages = [];
  Map<String, String> _variableValues = {};

  static const List<String> categories = [
    'General',
    'Greetings',
    'Education',
    'Family',
    'Time',
    'Actions',
    'Scheduling',
    'Homework',
    'Attendance',
    'Behavior',
    'Academic',
    'Health',
    'Events',
  ];

  @override
  void initState() {
    super.initState();
    _inputController.addListener(_onInputTextChanged);
    _loadAvailableLanguages();
  }

  @override
  void dispose() {
    _inputController.removeListener(_onInputTextChanged);
    _inputController.dispose();
    _inputFocusNode.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadAvailableLanguages() async {
    try {
      final languages = await DatabaseService.getLanguagePacks();
      setState(() {
        _availableLanguages = languages.where((lang) => lang.isActive).toList();
        if (_availableLanguages.isNotEmpty && 
            !_availableLanguages.any((lang) => lang.languageCode == _selectedLanguage)) {
          _selectedLanguage = _availableLanguages.first.languageCode;
        }
      });
    } catch (e) {
      print('Error loading languages: $e');
    }
  }

  void _onInputTextChanged() {
    final text = _inputController.text;
    
    if (text.isEmpty) {
      setState(() {
        _currentTranslation = null;
        _variableValues.clear();
      });
      return;
    }

    // Debounce translation requests
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      _translateText(text);
    });
  }

  Future<void> _translateText(String text) async {
    setState(() {
      _isTranslating = true;
    });

    try {
      final result = await TranslationEngine.translateText(
        text,
        _selectedLanguage,
        contextCategory: _selectedCategory,
        variables: _variableValues.isNotEmpty ? _variableValues : null,
      );

      setState(() {
        _currentTranslation = result;
        _isTranslating = false;
      });
    } catch (e) {
      setState(() {
        _isTranslating = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Translation error: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  void _selectAlternative(TranslationResult alternative) {
    setState(() {
      _currentTranslation = alternative;
    });
  }

  void _updateVariable(String name, String value) {
    setState(() {
      _variableValues[name] = value;
    });

    if (_currentTranslation != null && _variableValues.length == _currentTranslation!.variablePrompts.length) {
      final translatedWithVars = _currentTranslation!.copyWithVariables(_variableValues);
      setState(() {
        _currentTranslation = translatedWithVars;
      });
    }
  }

  void _copyTranslation() {
    if (_currentTranslation != null && _currentTranslation!.text.isNotEmpty) {
      Clipboard.setData(ClipboardData(text: _currentTranslation!.text));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Translation copied to clipboard'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Widget _buildConfidenceIndicator() {
    if (_currentTranslation == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _currentTranslation!.getConfidenceColor().withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _currentTranslation!.getConfidenceColor(),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _getConfidenceIcon(),
            size: 16,
            color: _currentTranslation!.getConfidenceColor(),
          ),
          const SizedBox(width: 6),
          Text(
            _currentTranslation!.confidenceLabel,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: _currentTranslation!.getConfidenceColor(),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getConfidenceIcon() {
    switch (_currentTranslation!.confidence) {
      case TranslationConfidence.high:
        return Icons.check_circle;
      case TranslationConfidence.medium:
        return Icons.info;
      case TranslationConfidence.low:
        return Icons.smart_toy;
      case TranslationConfidence.unknown:
        return Icons.help_outline;
    }
  }

  Widget _buildTranslationOutput() {
    final theme = Theme.of(context);

    if (_currentTranslation == null && !_isTranslating) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: theme.colorScheme.outline.withOpacity(0.2),
          ),
        ),
        child: Center(
          child: Column(
            children: [
              Icon(
                Icons.translate,
                size: 48,
                color: theme.colorScheme.onSurface.withOpacity(0.4),
              ),
              const SizedBox(height: 12),
              Text(
                'Translation will appear here',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_isTranslating) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: theme.colorScheme.primaryContainer.withOpacity(0.2),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
          child: Column(
            children: [
              CircularProgressIndicator(
                color: theme.colorScheme.primary,
              ),
              const SizedBox(height: 16),
              Text(
                'Translating...',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _currentTranslation!.getConfidenceColor().withOpacity(0.3),
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Translation with copy button
          Row(
            children: [
              Expanded(
                child: SelectableText(
                  _currentTranslation!.text,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              IconButton(
                onPressed: _copyTranslation,
                icon: Icon(
                  Icons.copy,
                  color: theme.colorScheme.primary,
                ),
                tooltip: 'Copy translation',
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Confidence and metadata
          Row(
            children: [
              _buildConfidenceIndicator(),
              const Spacer(),
              if (_currentTranslation!.notes != null) ...[
                Icon(
                  Icons.info_outline,
                  size: 16,
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                ),
                const SizedBox(width: 4),
                Text(
                  _currentTranslation!.notes!,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAlternatives() {
    if (_currentTranslation == null || _currentTranslation!.alternatives.isEmpty) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        Text(
          'Alternative translations',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        ...(_currentTranslation!.alternatives.take(3).map((alternative) => 
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            child: InkWell(
              onTap: () => _selectAlternative(TranslationResult(
                text: alternative.text,
                confidence: TranslationConfidence.medium,
                matchType: alternative.matchType,
                usedEntryIds: alternative.usedEntryIds,
                score: alternative.score,
                notes: alternative.notes,
              )),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  border: Border.all(
                    color: theme.colorScheme.outline.withOpacity(0.2),
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        alternative.text,
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                    if (alternative.notes != null) ...[
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.secondaryContainer.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          alternative.notes!,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSecondaryContainer,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(width: 8),
                    Icon(
                      Icons.arrow_forward,
                      size: 16,
                      color: theme.colorScheme.primary,
                    ),
                  ],
                ),
              ),
            ),
          )
        ).toList()),
      ],
    );
  }

  Widget _buildVariablePrompts() {
    if (_currentTranslation == null || _currentTranslation!.variablePrompts.isEmpty) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        Text(
          'Fill in variables',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        ...(_currentTranslation!.variablePrompts.map((prompt) => 
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            child: TextField(
              decoration: InputDecoration(
                labelText: prompt.displayName,
                hintText: _getVariableHint(prompt.type),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: theme.colorScheme.surface,
              ),
              onChanged: (value) => _updateVariable(prompt.name, value),
            ),
          )
        ).toList()),
      ],
    );
  }

  String _getVariableHint(String type) {
    switch (type) {
      case 'date':
        return 'e.g., March 15, 2024';
      case 'time':
        return 'e.g., 3:30 PM';
      case 'student_name':
        return 'Student\'s name';
      default:
        return 'Enter value';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Quick Translate'),
        backgroundColor: theme.appBarTheme.backgroundColor,
        foregroundColor: theme.appBarTheme.foregroundColor,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Language and Category Selection
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Target Language',
                        style: theme.textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        value: _selectedLanguage,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: theme.colorScheme.surface,
                        ),
                        items: _availableLanguages.map((lang) =>
                          DropdownMenuItem<String>(
                            value: lang.languageCode,
                            child: Text(lang.languageName),
                          )
                        ).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              _selectedLanguage = value;
                            });
                            if (_inputController.text.isNotEmpty) {
                              _translateText(_inputController.text);
                            }
                          }
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Category',
                        style: theme.textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        value: _selectedCategory,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: theme.colorScheme.surface,
                        ),
                        items: categories.map((category) =>
                          DropdownMenuItem<String>(
                            value: category,
                            child: Text(category),
                          )
                        ).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              _selectedCategory = value;
                            });
                            if (_inputController.text.isNotEmpty) {
                              _translateText(_inputController.text);
                            }
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // English Input
            Text(
              'English text',
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _inputController,
              focusNode: _inputFocusNode,
              decoration: InputDecoration(
                hintText: 'Enter English text to translate...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                filled: true,
                fillColor: theme.colorScheme.surface,
                contentPadding: const EdgeInsets.all(16),
              ),
              maxLines: 4,
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),

            // Translation Output
            _buildTranslationOutput(),

            // Variable Prompts
            _buildVariablePrompts(),

            // Alternatives
            _buildAlternatives(),
          ],
        ),
      ),
    );
  }
}
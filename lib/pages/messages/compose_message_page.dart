import 'dart:async';
import 'package:flutter/material.dart';
import '../../models/translation_result.dart';
import '../../models/phrase_entry.dart';
import '../../services/translation_engine.dart';
import '../../theme.dart';

class ComposeMessagePage extends StatefulWidget {
  final String? recipientId;
  final String? classId;
  final String targetLanguageCode;
  final String targetLanguageName;

  const ComposeMessagePage({
    super.key,
    this.recipientId,
    this.classId,
    required this.targetLanguageCode,
    required this.targetLanguageName,
  });

  @override
  State<ComposeMessagePage> createState() => _ComposeMessagePageState();
}

class _ComposeMessagePageState extends State<ComposeMessagePage> {
  final TextEditingController _englishController = TextEditingController();
  final TextEditingController _translatedController = TextEditingController();
  final FocusNode _englishFocusNode = FocusNode();
  final FocusNode _translatedFocusNode = FocusNode();

  TranslationResult? _currentTranslation;
  bool _isTranslating = false;
  Timer? _debounceTimer;
  String _selectedCategory = 'General';
  Map<String, String> _variableValues = {};

  static const List<String> categories = [
    'General',
    'Attendance',
    'Homework',
    'Behavior',
    'Academic',
    'Health',
    'Events',
  ];

  @override
  void initState() {
    super.initState();
    _englishController.addListener(_onEnglishTextChanged);
  }

  @override
  void dispose() {
    _englishController.removeListener(_onEnglishTextChanged);
    _englishController.dispose();
    _translatedController.dispose();
    _englishFocusNode.dispose();
    _translatedFocusNode.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onEnglishTextChanged() {
    final text = _englishController.text;
    
    if (text.isEmpty) {
      setState(() {
        _translatedController.text = '';
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
        widget.targetLanguageCode,
        contextCategory: _selectedCategory,
        variables: _variableValues.isNotEmpty ? _variableValues : null,
      );

      setState(() {
        _currentTranslation = result;
        if (!result.requiresVariableInput) {
          _translatedController.text = result.text;
        }
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
      if (!alternative.requiresVariableInput) {
        _translatedController.text = alternative.text;
      }
    });
  }

  void _updateVariable(String name, String value) {
    setState(() {
      _variableValues[name] = value;
    });

    if (_currentTranslation != null && _variableValues.length == _currentTranslation!.variablePrompts.length) {
      final translatedWithVars = _currentTranslation!.copyWithVariables(_variableValues);
      setState(() {
        _translatedController.text = translatedWithVars.text;
      });
    }
  }

  Widget _buildConfidenceIndicator() {
    if (_currentTranslation == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _currentTranslation!.getConfidenceColor().withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
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
          const SizedBox(width: 4),
          Text(
            _currentTranslation!.confidenceLabel,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: _currentTranslation!.getConfidenceColor(),
              fontWeight: FontWeight.w500,
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

  Widget _buildAlternatives() {
    if (_currentTranslation == null || _currentTranslation!.alternatives.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Text(
          'Alternatives:',
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
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
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        alternative.text,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                    if (alternative.notes != null) ...[
                      const SizedBox(width: 8),
                      Text(
                        alternative.notes!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                    ],
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Text(
          'Fill in variables:',
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        ...(_currentTranslation!.variablePrompts.map((prompt) => 
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            child: TextField(
              decoration: InputDecoration(
                labelText: prompt.displayName,
                hintText: _getVariableHint(prompt.type),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surface,
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
        title: Text('Compose Message'),
        backgroundColor: theme.appBarTheme.backgroundColor,
        foregroundColor: theme.appBarTheme.foregroundColor,
        actions: [
          TextButton(
            onPressed: _translatedController.text.isNotEmpty 
                ? () {
                    // TODO: Send message
                    Navigator.pop(context);
                  } 
                : null,
            child: Text(
              'Send',
              style: TextStyle(
                color: _translatedController.text.isNotEmpty 
                    ? theme.colorScheme.primary 
                    : theme.colorScheme.onSurface.withOpacity(0.4),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Target Language Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer.withOpacity(0.3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.translate,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Translating to ${widget.targetLanguageName}',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: theme.colorScheme.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Category Selection
            Text(
              'Category',
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: categories.map((category) => 
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(
                        category,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: _selectedCategory == category
                              ? theme.colorScheme.onPrimary
                              : theme.colorScheme.onSurface,
                        ),
                      ),
                      selected: _selectedCategory == category,
                      onSelected: (selected) {
                        setState(() {
                          _selectedCategory = category;
                        });
                        if (_englishController.text.isNotEmpty) {
                          _translateText(_englishController.text);
                        }
                      },
                      selectedColor: theme.colorScheme.primary,
                      backgroundColor: theme.colorScheme.surface,
                    ),
                  )
                ).toList(),
              ),
            ),
            const SizedBox(height: 24),

            // English Input
            Text(
              'English Message',
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _englishController,
              focusNode: _englishFocusNode,
              decoration: InputDecoration(
                hintText: 'Type your message in English...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: theme.colorScheme.surface,
              ),
              maxLines: 4,
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),

            // Translation Status
            Row(
              children: [
                Text(
                  widget.targetLanguageName,
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 12),
                if (_isTranslating) ...[
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Translating...',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ] else
                  _buildConfidenceIndicator(),
              ],
            ),
            const SizedBox(height: 8),

            // Translated Output
            TextField(
              controller: _translatedController,
              focusNode: _translatedFocusNode,
              decoration: InputDecoration(
                hintText: 'Translation will appear here...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: theme.colorScheme.surface,
              ),
              maxLines: 4,
              style: theme.textTheme.bodyMedium,
              readOnly: _currentTranslation?.requiresVariableInput == true,
            ),

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
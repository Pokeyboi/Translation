import 'package:flutter/material.dart';
import '../../models/phrase_entry.dart';
import '../../services/database_service.dart';
import '../../theme.dart';

class AddPhraseEntryPage extends StatefulWidget {
  final PhraseEntry? phrase;

  const AddPhraseEntryPage({super.key, this.phrase});

  @override
  State<AddPhraseEntryPage> createState() => _AddPhraseEntryPageState();
}

class _AddPhraseEntryPageState extends State<AddPhraseEntryPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _phraseKeyController = TextEditingController();
  final TextEditingController _englishController = TextEditingController();
  final TextEditingController _translationController = TextEditingController();
  final TextEditingController _phoneticController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  
  String _selectedLanguage = 'zopau';
  String _selectedLanguageName = 'Zopau (Tedim/Zomi)';
  String? _dialectLabel;
  String? _selectedCategory;
  List<String> _tags = [];
  List<VariableDefinition> _variables = [];
  bool _verified = false;
  bool _isLoading = false;

  static const Map<String, String> supportedLanguages = {
    'zopau': 'Zopau (Tedim/Zomi)',
    'es': 'Spanish',
    'fr': 'French',
  };

  static const List<String> categories = [
    'Scheduling',
    'Homework', 
    'Attendance',
    'Behavior',
    'Academic',
    'Health',
    'Events',
    'General',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.phrase != null) {
      _populateFields();
    }
  }

  void _populateFields() {
    final phrase = widget.phrase!;
    _phraseKeyController.text = phrase.phraseKey;
    _englishController.text = phrase.englishText;
    _translationController.text = phrase.translationText;
    _phoneticController.text = phrase.phoneticHelper ?? '';
    _notesController.text = phrase.notes ?? '';
    
    _selectedLanguage = phrase.languageCode;
    _selectedLanguageName = phrase.languageName;
    _dialectLabel = phrase.dialectLabel;
    _selectedCategory = phrase.category;
    _tags = List.from(phrase.tags);
    _variables = List.from(phrase.variables);
    _verified = phrase.verified;
  }

  @override
  void dispose() {
    _phraseKeyController.dispose();
    _englishController.dispose();
    _translationController.dispose();
    _phoneticController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _addVariable() {
    showDialog(
      context: context,
      builder: (context) => VariableDialog(
        onSave: (variable) {
          setState(() {
            _variables.add(variable);
          });
        },
      ),
    );
  }

  void _editVariable(int index) {
    showDialog(
      context: context,
      builder: (context) => VariableDialog(
        variable: _variables[index],
        onSave: (variable) {
          setState(() {
            _variables[index] = variable;
          });
        },
      ),
    );
  }

  void _removeVariable(int index) {
    setState(() {
      _variables.removeAt(index);
    });
  }

  Future<void> _savePhrase() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final phrase = PhraseEntry(
        id: widget.phrase?.id,
        languageCode: _selectedLanguage,
        languageName: _selectedLanguageName,
        dialectLabel: _dialectLabel?.isEmpty == true ? null : _dialectLabel,
        phraseKey: _phraseKeyController.text.trim(),
        englishText: _englishController.text.trim(),
        translationText: _translationController.text.trim(),
        variables: _variables,
        category: _selectedCategory,
        tags: _tags,
        phoneticHelper: _phoneticController.text.trim().isEmpty 
            ? null 
            : _phoneticController.text.trim(),
        notes: _notesController.text.trim().isEmpty 
            ? null 
            : _notesController.text.trim(),
        verified: _verified,
        verifiedBy: _verified ? 'User' : null,
        source: 'Manual Entry',
      );

      if (widget.phrase == null) {
        await DatabaseService.savePhraseEntry(phrase);
      } else {
        await DatabaseService.updatePhraseEntry(phrase);
      }

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.phrase == null 
                ? 'Phrase added successfully' 
                : 'Phrase updated successfully'),
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving phrase: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.phrase == null ? 'Add Phrase' : 'Edit Phrase'),
        backgroundColor: theme.appBarTheme.backgroundColor,
        foregroundColor: theme.appBarTheme.foregroundColor,
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _savePhrase,
            child: _isLoading
                ? SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: theme.appBarTheme.foregroundColor,
                    ),
                  )
                : Text(
                    'Save',
                    style: TextStyle(
                      color: theme.appBarTheme.foregroundColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Language Selection
              Text(
                'Language',
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
                items: supportedLanguages.entries.map((entry) =>
                  DropdownMenuItem<String>(
                    value: entry.key,
                    child: Text(entry.value),
                  )
                ).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedLanguage = value;
                      _selectedLanguageName = supportedLanguages[value]!;
                    });
                  }
                },
                validator: (value) =>
                    value == null ? 'Please select a language' : null,
              ),
              const SizedBox(height: 16),

              // Phrase Key
              Text(
                'Phrase Key',
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _phraseKeyController,
                decoration: InputDecoration(
                  hintText: 'e.g., meeting_on_date',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: theme.colorScheme.surface,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a phrase key';
                  }
                  if (value.contains(' ')) {
                    return 'Use underscores instead of spaces';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // English Text
              Text(
                'English Text',
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _englishController,
                decoration: InputDecoration(
                  hintText: 'e.g., Can we schedule a meeting on {date}?',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: theme.colorScheme.surface,
                ),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter English text';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Translation Text
              Text(
                'Translation',
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _translationController,
                decoration: InputDecoration(
                  hintText: 'Enter the translation with matching variables',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: theme.colorScheme.surface,
                ),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter translation text';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Variables Section
              Row(
                children: [
                  Text(
                    'Variables',
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: _addVariable,
                    icon: const Icon(Icons.add),
                    label: const Text('Add Variable'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              
              if (_variables.isEmpty)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: theme.colorScheme.outline.withOpacity(0.2),
                    ),
                  ),
                  child: Text(
                    'No variables defined. Variables like {date}, {time}, or {student_name} allow dynamic content.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                )
              else
                Column(
                  children: _variables.asMap().entries.map((entry) {
                    final index = entry.key;
                    final variable = entry.value;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: theme.colorScheme.outline.withOpacity(0.2),
                          ),
                        ),
                        tileColor: theme.colorScheme.surface,
                        leading: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primaryContainer.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '{${variable.name}}',
                            style: theme.textTheme.labelSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        title: Text(variable.type),
                        subtitle: variable.format != null
                            ? Text('Format: ${variable.format}')
                            : null,
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              onPressed: () => _editVariable(index),
                              icon: const Icon(Icons.edit),
                              tooltip: 'Edit variable',
                            ),
                            IconButton(
                              onPressed: () => _removeVariable(index),
                              icon: const Icon(Icons.delete),
                              tooltip: 'Remove variable',
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              const SizedBox(height: 16),

              // Category
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
                  hintText: 'Select category',
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
                  setState(() {
                    _selectedCategory = value;
                  });
                },
              ),
              const SizedBox(height: 16),

              // Phonetic Helper
              Text(
                'Phonetic Helper (Optional)',
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _phoneticController,
                decoration: InputDecoration(
                  hintText: 'Pronunciation guide',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: theme.colorScheme.surface,
                ),
              ),
              const SizedBox(height: 16),

              // Notes
              Text(
                'Notes (Optional)',
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _notesController,
                decoration: InputDecoration(
                  hintText: 'Additional notes or context',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: theme.colorScheme.surface,
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 16),

              // Verified Checkbox
              CheckboxListTile(
                title: Text(
                  'Mark as Verified',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                subtitle: const Text('Verified entries have higher priority in translation'),
                value: _verified,
                onChanged: (value) {
                  setState(() {
                    _verified = value ?? false;
                  });
                },
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                tileColor: theme.colorScheme.surface,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class VariableDialog extends StatefulWidget {
  final VariableDefinition? variable;
  final Function(VariableDefinition) onSave;

  const VariableDialog({
    super.key,
    this.variable,
    required this.onSave,
  });

  @override
  State<VariableDialog> createState() => _VariableDialogState();
}

class _VariableDialogState extends State<VariableDialog> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _formatController = TextEditingController();
  String _selectedType = 'string';

  static const Map<String, String> variableTypes = {
    'string': 'Text',
    'date': 'Date',
    'time': 'Time',
    'number': 'Number',
    'student_name': 'Student Name',
  };

  @override
  void initState() {
    super.initState();
    if (widget.variable != null) {
      _nameController.text = widget.variable!.name;
      _selectedType = widget.variable!.type;
      _formatController.text = widget.variable!.format ?? '';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _formatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: Text(widget.variable == null ? 'Add Variable' : 'Edit Variable'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Variable Name',
              hintText: 'e.g., date, time, student_name',
            ),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _selectedType,
            decoration: const InputDecoration(
              labelText: 'Type',
            ),
            items: variableTypes.entries.map((entry) =>
              DropdownMenuItem<String>(
                value: entry.key,
                child: Text(entry.value),
              )
            ).toList(),
            onChanged: (value) {
              setState(() {
                _selectedType = value!;
              });
            },
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _formatController,
            decoration: const InputDecoration(
              labelText: 'Format (Optional)',
              hintText: 'e.g., MMMM d for dates',
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_nameController.text.trim().isNotEmpty) {
              final variable = VariableDefinition(
                name: _nameController.text.trim(),
                type: _selectedType,
                format: _formatController.text.trim().isEmpty
                    ? null
                    : _formatController.text.trim(),
              );
              widget.onSave(variable);
              Navigator.pop(context);
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: theme.colorScheme.primary,
            foregroundColor: theme.colorScheme.onPrimary,
          ),
          child: const Text('Save'),
        ),
      ],
    );
  }
}
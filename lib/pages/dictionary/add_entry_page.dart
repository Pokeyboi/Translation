import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/dictionary_entry.dart';
import '../../models/audio_clip.dart';
import '../../providers/dictionary_provider.dart';
import '../../providers/audio_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/recorder_sheet.dart';
import '../../theme.dart';

class AddEntryPage extends StatefulWidget {
  const AddEntryPage({super.key});

  @override
  State<AddEntryPage> createState() => _AddEntryPageState();
}

class _AddEntryPageState extends State<AddEntryPage> {
  final _formKey = GlobalKey<FormState>();
  final _languageCodeController = TextEditingController();
  final _languageNameController = TextEditingController();
  final _dialectController = TextEditingController();
  final _englishController = TextEditingController();
  final _translationController = TextEditingController();
  final _phoneticController = TextEditingController();
  final _notesController = TextEditingController();
  final _categoryController = TextEditingController();
  final _tagsController = TextEditingController();
  
  bool _isLoading = false;
  bool _verified = false;

  @override
  void dispose() {
    _languageCodeController.dispose();
    _languageNameController.dispose();
    _dialectController.dispose();
    _englishController.dispose();
    _translationController.dispose();
    _phoneticController.dispose();
    _notesController.dispose();
    _categoryController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  Future<void> _saveEntry() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final entry = DictionaryEntry(
        languageCode: _languageCodeController.text.trim(),
        languageName: _languageNameController.text.trim(),
        dialectLabel: _dialectController.text.trim().isEmpty ? null : _dialectController.text.trim(),
        english: _englishController.text.trim(),
        translation: _translationController.text.trim(),
        phoneticHelper: _phoneticController.text.trim().isEmpty ? null : _phoneticController.text.trim(),
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
        category: _categoryController.text.trim().isEmpty ? null : _categoryController.text.trim(),
        tags: _tagsController.text.trim().isEmpty 
          ? []
          : _tagsController.text.split(',').map((tag) => tag.trim()).where((tag) => tag.isNotEmpty).toList(),
        verified: _verified,
        source: 'manual_entry',
      );

      await Provider.of<DictionaryProvider>(context, listen: false).addEntry(entry);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green[300]),
                const SizedBox(width: 8),
                const Text('Entry saved successfully!'),
              ],
            ),
            backgroundColor: Colors.green[700],
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving entry: $e'),
            backgroundColor: Colors.red[700],
            behavior: SnackBarBehavior.floating,
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
        title: const Text('Add Entry'),
        backgroundColor: theme.appBarTheme.backgroundColor,
        foregroundColor: theme.appBarTheme.foregroundColor,
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _saveEntry,
            child: _isLoading
              ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      theme.appBarTheme.foregroundColor ?? theme.colorScheme.primary,
                    ),
                  ),
                )
              : Text(
                  'Save',
                  style: TextStyle(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Required Fields Section
            Card(
              elevation: 0,
              color: theme.colorScheme.primaryContainer.withOpacity(0.3),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Required Information',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _languageCodeController,
                            decoration: InputDecoration(
                              labelText: 'Language Code',
                              hintText: 'e.g., zopau',
                              prefixIcon: Icon(Icons.language, color: theme.colorScheme.primary),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Language code is required';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _languageNameController,
                            decoration: InputDecoration(
                              labelText: 'Language Name',
                              hintText: 'e.g., Zopau',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Language name is required';
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 16),
                    
                    TextFormField(
                      controller: _englishController,
                      decoration: InputDecoration(
                        labelText: 'English Text',
                        hintText: 'Enter the English phrase',
                        prefixIcon: Icon(Icons.translate, color: theme.colorScheme.primary),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'English text is required';
                        }
                        return null;
                      },
                    ),
                    
                    const SizedBox(height: 16),
                    
                    TextFormField(
                      controller: _translationController,
                      decoration: InputDecoration(
                        labelText: 'Translation',
                        hintText: 'Enter the translation',
                        prefixIcon: Icon(Icons.translate_outlined, color: theme.colorScheme.primary),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Translation is required';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Optional Fields Section
            Card(
              elevation: 0,
              color: theme.colorScheme.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: theme.colorScheme.outline.withOpacity(0.2),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Optional Information',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: theme.colorScheme.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    TextFormField(
                      controller: _dialectController,
                      decoration: InputDecoration(
                        labelText: 'Dialect/Region',
                        hintText: 'e.g., Northern, Coastal',
                        prefixIcon: Icon(Icons.place, color: theme.colorScheme.primary),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    TextFormField(
                      controller: _phoneticController,
                      decoration: InputDecoration(
                        labelText: 'Phonetic Helper',
                        hintText: 'How to pronounce it',
                        prefixIcon: Icon(Icons.record_voice_over, color: theme.colorScheme.primary),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    TextFormField(
                      controller: _categoryController,
                      decoration: InputDecoration(
                        labelText: 'Category',
                        hintText: 'e.g., Greetings, Food, Numbers',
                        prefixIcon: Icon(Icons.category, color: theme.colorScheme.primary),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    TextFormField(
                      controller: _tagsController,
                      decoration: InputDecoration(
                        labelText: 'Tags',
                        hintText: 'Comma-separated tags',
                        prefixIcon: Icon(Icons.local_offer, color: theme.colorScheme.primary),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    TextFormField(
                      controller: _notesController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        labelText: 'Notes',
                        hintText: 'Additional context or usage notes',
                        prefixIcon: Icon(Icons.note, color: theme.colorScheme.primary),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    CheckboxListTile(
                      title: Text(
                        'Verified Entry',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      subtitle: Text(
                        'Mark as verified by a native speaker',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.7),
                        ),
                      ),
                      value: _verified,
                      onChanged: (value) {
                        setState(() {
                          _verified = value ?? false;
                        });
                      },
                      activeColor: theme.colorScheme.primary,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Save Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _saveEntry,
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                  ? SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          theme.colorScheme.onPrimary,
                        ),
                      ),
                    )
                  : Text(
                      'Save Entry',
                      style: TextStyle(
                        color: theme.colorScheme.onPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
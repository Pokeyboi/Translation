import 'dart:convert';
import 'dart:math';
import '../models/dictionary_entry.dart';
import '../models/phrase_entry.dart';
import '../models/language_pack.dart';
import 'database_service.dart';

class TranslationService {
  static Future<String> translate(String text, String fromLanguage, String toLanguage) async {
    // This service assumes 'en' to 'zopau' translation for now.
    if (fromLanguage == 'en' && toLanguage == 'zopau') {
      final cleanText = text.trim().toLowerCase();

      // First, search for an exact phrase match.
      final phrases = await DatabaseService.searchPhrases(cleanText, languageCode: toLanguage);
      if (phrases.isNotEmpty && phrases.first.englishText.toLowerCase() == cleanText) {
        return phrases.first.translationText;
      }

      // If no phrase is found, search for a dictionary entry.
      final entries = await DatabaseService.searchDictionary(cleanText, languageCode: toLanguage);
      if (entries.isNotEmpty && entries.first.english.toLowerCase() == cleanText) {
        return entries.first.translation;
      }
    }

    // If no translation is found, return the original text.
    // A more advanced implementation could offer machine translation as a fallback.
    return text;
  }


  static Future<void> initializeSampleDictionary() async {
    // Check if data has already been initialized.
    final existingEntries = await DatabaseService.getDictionaryEntries(languageCode: 'zopau', limit: 1);
    if (existingEntries.isNotEmpty) {
      return; // Already initialized.
    }

    final Map<String, String> sampleTranslations = {
      'hello': 'khua',
      'good morning': 'zing khua',
      'good afternoon': 'nitum khua',
      'good evening': 'zanlai khua',
      'thank you': 'ka lawm e',
      'please': 'nei tawh',
      'yes': 'a hih',
      'no': 'a hih lo',
      'student': 'zirtu',
      'teacher': 'zirtirtu',
      'school': 'zirlai in',
      'homework': 'inn tuah ding',
      'test': 'endik',
      'book': 'laibu',
      'paper': 'cazin',
      'pen': 'kutrawl',
      'pencil': 'peizil',
      'read': 'cang',
      'write': 'ziak',
      'listen': 'ngai',
      'speak': 'pau',
      'learn': 'zir',
      'teach': 'zirtir',
      'parent': 'nupa/nupi',
      'child': 'naupang',
      'today': 'tuni',
      'tomorrow': 'tukni',
      'yesterday': 'tualai',
      'week': 'ni sagi',
      'month': 'thla',
      'year': 'kum',
      'time': 'hun',
      'late': 'tui',
      'early': 'dong',
      'absent': 'a om lo',
      'present': 'a om',
      'sick': 'dam lo',
      'healthy': 'dam',
      'help': 'bawm',
      'need': 'tul',
      'important': 'pawimawh',
      'excellent': 'tha hle',
      'good': 'tha',
      'bad': 'tha lo',
      'well done': 'tha takin',
      'congratulations': 'lawmawm rawh',
      'sorry': 'ka ngaidam',
      'excuse me': 'min hriatchian',
      'meeting': 'inkhawm',
      'conference': 'rorelna',
      'assignment': 'hna pe',
      'grade': 'grade',
      'score': 'number',
      'pass': 'tlan',
      'fail': 'tlan lo',
      'behavior': 'nungchang',
      'discipline': 'inrinlum',
      'respect': 'zahna',
      'attention': 'ngaihven',
      'focus': 'ngaihtuah',
      'practice': 'kalpui',
      'improve': 'tihchangtlun',
      'progress': 'hmasawnna',
      'succeed': 'hlawhtlin',
      'try': 'tum',
      'effort': 'thazawmna',
    };

    final Map<String, String> commonPhrases = {
      'Your child was absent today.': 'Na naupang hi tuni a om lo.',
      'Please send your child to school on time.': 'Na naupang chu hun takin school ah thawn la.',
      'Your child is doing excellent work.': 'Na naupang hi hna tha tak a thawk.',
      'Great job on the homework!': 'Inn tuah ding ah hna tha tak!',
      'Your child needs more practice.': 'Na naupang hi practice tam zawk a tul.',
      'Please sign and return this form.': 'Hei hi kutrawl ziak la, thawn kir leh.',
      'Parent-teacher conference scheduled.': 'Nupa nupi leh zirtirtu inhmuh hun ruahman.',
      'Your child forgot their lunch.': 'Na naupang hi an rawchah a theihnghilh.',
      'Please pick up your child early today.': 'Tuni hi na naupang chu dong takin la rawh.',
      'Your child has improved significantly.': 'Na naupang hi nasa takin a tihchangtlun.',
      'Homework is due tomorrow.': 'Inn tuah ding hi tukni a tul.',
      'Test scheduled for next week.': 'Ni sagi lo awm ah endik ruahman.',
      'Please contact me if you have questions.': 'Zawhna i neih chuan min biak rawh.',
      'Your child is a pleasure to teach.': 'Na naupang hi zirtir tlak hle a ni.',
      'Thank you for your support.': 'I support avangin ka lawm e.',
    };
    
    final dictionaryEntries = sampleTranslations.entries.map((e) => DictionaryEntry(
      id: 'sample_${e.key.replaceAll(' ', '_')}',
      languageCode: 'zopau',
      languageName: 'Zopau',
      english: e.key,
      translation: e.value,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    )).toList();

    await DatabaseService.importDictionaryEntries(dictionaryEntries);

    final phraseEntries = commonPhrases.entries.map((e) => PhraseEntry(
      id: 'sample_${e.key.replaceAll(' ', '_')}',
      languageCode: 'zopau',
      languageName: 'Zopau',
      englishText: e.key,
      translationText: e.value,
      phraseKey: e.key,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    )).toList();

    for (final entry in phraseEntries) {
      await DatabaseService.savePhraseEntry(entry);
    }
  }
}

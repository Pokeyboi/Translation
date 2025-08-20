import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'theme.dart';
import 'providers/auth_provider.dart';
import 'providers/dictionary_provider.dart';
import 'providers/audio_provider.dart';
import 'pages/dictionary/dictionary_page.dart';
import 'pages/dictionary/entry_detail_page.dart';
import 'models/dictionary_entry.dart';
import 'services/translation_service.dart';
import 'pages/messages/compose_message_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const TeacherTranslatorApp());
}

class TeacherTranslatorApp extends StatelessWidget {
  const TeacherTranslatorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => DictionaryProvider()),
        ChangeNotifierProvider(create: (_) => AudioProvider()),
      ],
      child: Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          return MaterialApp(
            title: 'Teacher Translator',
            debugShowCheckedModeBanner: false,
            theme: lightTheme,
            darkTheme: darkTheme,
            themeMode: ThemeMode.system,
            home: const MainApp(),
            onGenerateRoute: (settings) {
              switch (settings.name) {
                case '/dictionary/entry':
                  final entry = settings.arguments as DictionaryEntry;
                  return MaterialPageRoute(
                    builder: (context) => EntryDetailPage(entry: entry),
                  );
                default:
                  return null;
              }
            },
          );
        },
      ),
    );
  }
}

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  int _selectedIndex = 0;
  bool _isInitialized = false;
  
  final List<Widget> _pages = [
    const MessagesPageBasic(),
    const DictionaryPage(),
    const PracticePageBasic(),
    const ClassesPageBasic(),
    const SettingsPageBasic(),
  ];

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      // Initialize translation service with sample data
      await TranslationService.initializeSampleDictionary();
      
      // TODO: Initialize other services when ready
      // final authProvider = context.read<AuthProvider>();
      // final audioProvider = context.read<AudioProvider>();
      
      // await authProvider.initializeWithDemoUser();
      // await audioProvider.initialize();
      
      setState(() => _isInitialized = true);
    } catch (e) {
      print('Error initializing app: $e');
      setState(() => _isInitialized = true); // Show UI anyway
    }
  }

  final List<String> _titles = [
    'Messages',
    'Dictionary',
    'Practice',
    'Classes',
    'Settings',
  ];

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 16),
              Text(
                'Initializing Teacher Translator...',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _titles[_selectedIndex],
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: Theme.of(context).colorScheme.onPrimaryContainer,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  child: Text(
                    'T',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Teacher',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.notifications_outlined,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                  size: 24,
                ),
              ],
            ),
          ),
        ],
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        child: _pages[_selectedIndex],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).shadowColor.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          currentIndex: _selectedIndex,
          selectedItemColor: Theme.of(context).colorScheme.primary,
          unselectedItemColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
          backgroundColor: Theme.of(context).colorScheme.surface,
          elevation: 0,
          selectedLabelStyle: Theme.of(context).textTheme.labelSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
          unselectedLabelStyle: Theme.of(context).textTheme.labelSmall,
          onTap: (index) {
            setState(() {
              _selectedIndex = index;
            });
          },
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.message_outlined),
              activeIcon: Icon(Icons.message),
              label: 'Messages',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.book_outlined),
              activeIcon: Icon(Icons.book),
              label: 'Dictionary',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.school_outlined),
              activeIcon: Icon(Icons.school),
              label: 'Practice',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.class_outlined),
              activeIcon: Icon(Icons.class_),
              label: 'Classes',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.settings_outlined),
              activeIcon: Icon(Icons.settings),
              label: 'Settings',
            ),
          ],
        ),
      ),
    );
  }
}

class MessagesPageBasic extends StatelessWidget {
  const MessagesPageBasic({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(60),
                ),
                child: Icon(
                  Icons.message_outlined,
                  size: 48,
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.6),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Bilingual Messages',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Send messages in English and Zopau/Zomi/Chin-Tedim to communicate with parents effectively.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ComposeMessagePage(
                        targetLanguageCode: 'zopau',
                        targetLanguageName: 'Zopau (Tedim/Zomi)',
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.add),
                label: const Text('Compose Message'),
              ),
            ],
          ),
        ),
      ),
    );
  }


}

class DictionaryPageBasic extends StatelessWidget {
  const DictionaryPageBasic({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(60),
                ),
                child: Icon(
                  Icons.book_outlined,
                  size: 48,
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.6),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Living Dictionary',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Build and expand your English ↔ Zopau/Zomi dictionary with audio pronunciations and phonetic helpers.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  FilledButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Add entry feature ready for implementation!')),
                      );
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Add Entry'),
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Import language pack feature ready!')),
                      );
                    },
                    icon: const Icon(Icons.upload),
                    label: const Text('Import'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class PracticePageBasic extends StatelessWidget {
  const PracticePageBasic({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(60),
                ),
                child: Icon(
                  Icons.school_outlined,
                  size: 48,
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.6),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Practice Pronunciation',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Use flashcards and audio practice to improve your Zopau/Zomi pronunciation and vocabulary.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  FilledButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Flashcard practice feature ready!')),
                      );
                    },
                    icon: const Icon(Icons.quiz),
                    label: const Text('Flashcards'),
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Audio practice feature ready!')),
                      );
                    },
                    icon: const Icon(Icons.mic),
                    label: const Text('Pronunciation'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ClassesPageBasic extends StatelessWidget {
  const ClassesPageBasic({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(60),
                ),
                child: Icon(
                  Icons.class_outlined,
                  size: 48,
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.6),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Manage Classes',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Organize your students and parent contacts for efficient bilingual communication.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  FilledButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Class management feature ready!')),
                      );
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Add Class'),
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Student management feature ready!')),
                      );
                    },
                    icon: const Icon(Icons.person_add),
                    label: const Text('Add Student'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SettingsPageBasic extends StatelessWidget {
  const SettingsPageBasic({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 32,
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      child: Text(
                        'T',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Theme.of(context).colorScheme.onPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Teacher Demo',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'teacher@example.com',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                            ),
                          ),
                          const SizedBox(height: 8),
                          OutlinedButton(
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Profile editing feature ready!')),
                              );
                            },
                            child: const Text('Edit Profile'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            Text(
              'App Features',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
            
            const SizedBox(height: 8),
            
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.translate),
                    title: const Text('Bilingual Messaging'),
                    subtitle: const Text('English ↔ Zopau/Zomi/Chin-Tedim'),
                    trailing: Icon(Icons.check, color: Colors.green),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.book),
                    title: const Text('Living Dictionary'),
                    subtitle: const Text('Expandable translation database'),
                    trailing: Icon(Icons.check, color: Colors.green),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.volume_up),
                    title: const Text('Audio Pronunciation'),
                    subtitle: const Text('Native and teacher recordings'),
                    trailing: Icon(Icons.check, color: Colors.green),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.upload_file),
                    title: const Text('Language Pack Support'),
                    subtitle: const Text('Import/export dictionary data'),
                    trailing: Icon(Icons.check, color: Colors.green),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.mic),
                    title: const Text('Parent Voice Capture'),
                    subtitle: const Text('Native pronunciation recordings'),
                    trailing: Icon(Icons.check, color: Colors.green),
                  ),
                ],
              ),
            ),
            
            const Spacer(),
            
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Theme.of(context).colorScheme.primary,
                    size: 32,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Teacher Translator v1.0.0',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Bridging communication between teachers and parents',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
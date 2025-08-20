import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/dictionary_provider.dart';
import '../../widgets/dictionary_entry_card.dart';
import '../../widgets/empty_state.dart';
import '../../theme.dart';
import 'add_entry_page.dart';
import 'csv_import_page.dart';
import 'translate_page.dart';
import 'words_tab.dart';
import 'phrases_tab.dart';
import 'add_phrase_entry_page.dart';

class DictionaryPage extends StatefulWidget {
  const DictionaryPage({super.key});

  @override
  State<DictionaryPage> createState() => _DictionaryPageState();
}

class _DictionaryPageState extends State<DictionaryPage> with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<DictionaryProvider>(context, listen: false).loadEntries();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dictionary & Translation'),
        backgroundColor: theme.appBarTheme.backgroundColor,
        foregroundColor: theme.appBarTheme.foregroundColor,
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const TranslatePage(),
                ),
              );
            },
            icon: Icon(
              Icons.translate,
              color: theme.appBarTheme.foregroundColor,
            ),
            tooltip: 'Quick Translate',
          ),
          PopupMenuButton<String>(
            icon: Icon(
              Icons.more_vert,
              color: theme.appBarTheme.foregroundColor,
            ),
            onSelected: (value) {
              switch (value) {
                case 'add_entry':
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const AddEntryPage()),
                  );
                  break;
                case 'import_csv':
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const CsvImportPage()),
                  );
                  break;
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem<String>(
                value: 'add_entry',
                child: Row(
                  children: [
                    Icon(
                      Icons.add,
                      color: theme.colorScheme.onSurface,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Add Entry',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuItem<String>(
                value: 'import_csv',
                child: Row(
                  children: [
                    Icon(
                      Icons.upload_file,
                      color: theme.colorScheme.onSurface,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Import CSV',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(
              icon: Icon(Icons.book),
              text: 'Words',
            ),
            Tab(
              icon: Icon(Icons.chat_bubble),
              text: 'Phrases',
            ),
          ],
          labelColor: theme.colorScheme.primary,
          unselectedLabelColor: theme.colorScheme.onSurface.withOpacity(0.6),
          indicatorColor: theme.colorScheme.primary,
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          final currentTab = _tabController.index;
          if (currentTab == 0) {
            // Words tab - add dictionary entry
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const AddEntryPage()),
            );
          } else {
            // Phrases tab - add phrase entry
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const AddPhraseEntryPage()),
            );
          }
        },
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
        child: const Icon(Icons.add),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          WordsTab(),
          PhrasesTab(),
        ],
      ),
    );
  }
}
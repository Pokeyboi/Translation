import 'package:flutter/material.dart';
import '../../models/phrase_entry.dart';
import '../../services/database_service.dart';
import '../../widgets/empty_state.dart';
import '../../theme.dart';

class PhrasesTab extends StatefulWidget {
  const PhrasesTab({super.key});

  @override
  State<PhrasesTab> createState() => _PhrasesTabState();
}

class _PhrasesTabState extends State<PhrasesTab> {
  final TextEditingController _searchController = TextEditingController();
  List<PhraseEntry> _phrases = [];
  List<PhraseEntry> _filteredPhrases = [];
  bool _isLoading = true;
  String? _error;
  String _searchQuery = '';
  String _selectedCategory = 'All';

  static const List<String> categories = [
    'All', 'Scheduling', 'Homework', 'Attendance', 'Behavior', 'Academic', 'Health', 'Events'
  ];

  @override
  void initState() {
    super.initState();
    _loadPhrases();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadPhrases() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final phrases = await DatabaseService.getPhraseEntries();
      setState(() {
        _phrases = phrases;
        _filteredPhrases = phrases;
        _isLoading = false;
      });
      
      _applyFilters();
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _applyFilters() {
    List<PhraseEntry> filtered = _phrases;

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((phrase) =>
        phrase.englishText.toLowerCase().contains(_searchQuery.toLowerCase()) ||
        phrase.translationText.toLowerCase().contains(_searchQuery.toLowerCase()) ||
        phrase.phraseKey.toLowerCase().contains(_searchQuery.toLowerCase())
      ).toList();
    }

    // Apply category filter
    if (_selectedCategory != 'All') {
      filtered = filtered.where((phrase) => phrase.category == _selectedCategory).toList();
    }

    setState(() {
      _filteredPhrases = filtered;
    });
  }

  void _setSearchQuery(String query) {
    setState(() {
      _searchQuery = query;
    });
    _applyFilters();
  }

  void _setSelectedCategory(String category) {
    setState(() {
      _selectedCategory = category;
    });
    _applyFilters();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              'Loading phrases...',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Card(
          margin: const EdgeInsets.all(16),
          elevation: 0,
          color: theme.colorScheme.errorContainer.withOpacity(0.3),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.error_outline,
                  color: theme.colorScheme.error,
                  size: 48,
                ),
                const SizedBox(height: 16),
                Text(
                  'Error loading phrases',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.error,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _error!,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.error,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _loadPhrases,
                  icon: Icon(
                    Icons.refresh,
                    color: theme.colorScheme.onPrimary,
                  ),
                  label: Text(
                    'Try Again',
                    style: TextStyle(
                      color: theme.colorScheme.onPrimary,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Column(
      children: [
        // Search and Filter Section
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            border: Border(
              bottom: BorderSide(
                color: theme.colorScheme.outline.withOpacity(0.1),
                width: 1,
              ),
            ),
          ),
          child: Column(
            children: [
              // Search Bar
              TextField(
                controller: _searchController,
                onChanged: _setSearchQuery,
                decoration: InputDecoration(
                  hintText: 'Search phrases...',
                  hintStyle: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.5),
                  ),
                  prefixIcon: Icon(
                    Icons.search,
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                  ),
                  suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        onPressed: () {
                          _searchController.clear();
                          _setSearchQuery('');
                        },
                        icon: Icon(
                          Icons.clear,
                          color: theme.colorScheme.onSurface.withOpacity(0.7),
                        ),
                      )
                    : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: theme.colorScheme.outline.withOpacity(0.3),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: theme.colorScheme.outline.withOpacity(0.3),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  filled: true,
                  fillColor: theme.colorScheme.surface,
                ),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 12),
              
              // Category Filter
              Row(
                children: [
                  Icon(
                    Icons.category,
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Category:',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: categories
                            .map((category) => Padding(
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
                                      _setSelectedCategory(category);
                                    },
                                    selectedColor: theme.colorScheme.primary,
                                    backgroundColor: theme.colorScheme.surface,
                                    side: BorderSide(
                                      color: _selectedCategory == category
                                        ? theme.colorScheme.primary
                                        : theme.colorScheme.outline.withOpacity(0.3),
                                    ),
                                  ),
                                ))
                            .toList(),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        
        // Results
        Expanded(
          child: _filteredPhrases.isEmpty
            ? const EmptyState(
                title: 'No phrases found',
                subtitle: 'Try adjusting your search or add some phrases',
                icon: Icons.chat_bubble,
              )
            : RefreshIndicator(
                onRefresh: _loadPhrases,
                color: theme.colorScheme.primary,
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _filteredPhrases.length,
                  itemBuilder: (context, index) {
                    final phrase = _filteredPhrases[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: PhraseEntryCard(
                        phrase: phrase,
                        onTap: () {
                          // TODO: Show phrase detail or edit
                        },
                      ),
                    );
                  },
                ),
              ),
        ),
      ],
    );
  }
}

class PhraseEntryCard extends StatelessWidget {
  final PhraseEntry phrase;
  final VoidCallback? onTap;

  const PhraseEntryCard({
    super.key,
    required this.phrase,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: theme.colorScheme.outline.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with verification badge
              Row(
                children: [
                  Expanded(
                    child: Text(
                      phrase.phraseKey.replaceAll('_', ' ').toUpperCase(),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  if (phrase.verified) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.green, width: 1),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.verified,
                            size: 12,
                            color: Colors.green,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Verified',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: Colors.green,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 12),

              // English text
              Text(
                phrase.englishText,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),

              // Translation
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  phrase.translationText,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ),

              // Variables if present
              if (phrase.variables.isNotEmpty) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: phrase.variables.map((variable) =>
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.secondaryContainer.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '{${variable.name}}',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurface,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    )
                  ).toList(),
                ),
              ],

              // Category and tags
              if (phrase.category != null || phrase.tags.isNotEmpty) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    if (phrase.category != null) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.tertiaryContainer.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          phrase.category!,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onTertiaryContainer,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    if (phrase.tags.isNotEmpty)
                      Expanded(
                        child: Text(
                          phrase.tags.join(' • '),
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.6),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
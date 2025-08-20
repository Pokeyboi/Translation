import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/dictionary_provider.dart';
import '../../widgets/dictionary_entry_card.dart';
import '../../widgets/empty_state.dart';
import '../../theme.dart';

class WordsTab extends StatefulWidget {
  const WordsTab({super.key});

  @override
  State<WordsTab> createState() => _WordsTabState();
}

class _WordsTabState extends State<WordsTab> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<DictionaryProvider>(context, listen: false).loadEntries();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Consumer<DictionaryProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(height: 16),
                Text(
                  'Loading words...',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          );
        }

        if (provider.error != null) {
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
                      'Error loading words',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: theme.colorScheme.error,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      provider.error!,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.error,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () {
                        provider.clearError();
                        provider.loadEntries();
                      },
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
                    onChanged: provider.setSearchQuery,
                    decoration: InputDecoration(
                      hintText: 'Search words...',
                      hintStyle: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.5),
                      ),
                      prefixIcon: Icon(
                        Icons.search,
                        color: theme.colorScheme.onSurface.withOpacity(0.7),
                      ),
                      suffixIcon: provider.searchQuery.isNotEmpty
                        ? IconButton(
                            onPressed: () {
                              _searchController.clear();
                              provider.setSearchQuery('');
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
                        Icons.filter_list,
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
                            children: ['All', 'Greetings', 'Education', 'Family', 'Time', 'Actions', 'General']
                                .map((category) => Padding(
                                      padding: const EdgeInsets.only(right: 8),
                                      child: FilterChip(
                                        label: Text(
                                          category,
                                          style: theme.textTheme.labelSmall?.copyWith(
                                            color: provider.selectedCategory == category
                                              ? theme.colorScheme.onPrimary
                                              : theme.colorScheme.onSurface,
                                          ),
                                        ),
                                        selected: provider.selectedCategory == category,
                                        onSelected: (selected) {
                                          provider.setSelectedCategory(category);
                                        },
                                        selectedColor: theme.colorScheme.primary,
                                        backgroundColor: theme.colorScheme.surface,
                                        side: BorderSide(
                                          color: provider.selectedCategory == category
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
                  const SizedBox(height: 8),

                  // Verification Filter
                  Row(
                    children: [
                      Icon(
                        Icons.verified,
                        color: theme.colorScheme.onSurface.withOpacity(0.7),
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Show:',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.7),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Row(
                          children: ['All', 'Verified', 'Unverified']
                              .map((filter) => Padding(
                                    padding: const EdgeInsets.only(right: 8),
                                    child: FilterChip(
                                      label: Text(
                                        filter,
                                        style: theme.textTheme.labelSmall?.copyWith(
                                          color: filter == 'All' 
                                            ? theme.colorScheme.onPrimary
                                            : theme.colorScheme.onSurface,
                                        ),
                                      ),
                                      selected: filter == 'All',
                                      onSelected: (selected) {
                                        // TODO: Implement verification filter
                                      },
                                      selectedColor: theme.colorScheme.primary,
                                      backgroundColor: theme.colorScheme.surface,
                                      side: BorderSide(
                                        color: filter == 'All'
                                          ? theme.colorScheme.primary
                                          : theme.colorScheme.outline.withOpacity(0.3),
                                      ),
                                    ),
                                  ))
                              .toList(),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // Results
            Expanded(
              child: provider.filteredEntries.isEmpty
                ? const EmptyState(
                    title: 'No words found',
                    subtitle: 'Try adjusting your search or add some words',
                    icon: Icons.book,
                  )
                : RefreshIndicator(
                    onRefresh: provider.loadEntries,
                    color: theme.colorScheme.primary,
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: provider.filteredEntries.length,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: DictionaryEntryCard(
                            entry: provider.filteredEntries[index],
                          ),
                        );
                      },
                    ),
                  ),
            ),
          ],
        );
      },
    );
  }
}
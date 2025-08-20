import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/dictionary_entry.dart';
import '../../models/audio_clip.dart';
import '../../models/user_model.dart';
import '../../providers/audio_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/audio_player_widget.dart';
import '../../widgets/recorder_sheet.dart';
import '../../theme.dart';

class EntryDetailPage extends StatefulWidget {
  final DictionaryEntry entry;

  const EntryDetailPage({
    super.key,
    required this.entry,
  });

  @override
  State<EntryDetailPage> createState() => _EntryDetailPageState();
}

class _EntryDetailPageState extends State<EntryDetailPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AudioProvider>().loadClipsForEntry(widget.entry.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.entry.english),
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () {
              // TODO: Share entry
            },
            icon: const Icon(Icons.share_outlined),
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'edit':
                  // TODO: Navigate to edit page
                  break;
                case 'delete':
                  _showDeleteDialog();
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(Icons.edit_outlined),
                    SizedBox(width: 12),
                    Text('Edit Entry'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete_outline, color: Colors.red),
                    SizedBox(width: 12),
                    Text('Delete Entry', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildEntryHeader(),
            const SizedBox(height: 24),
            _buildAudioSection(),
            if (widget.entry.notes != null) ...[
              const SizedBox(height: 24),
              _buildNotesSection(),
            ],
            if (widget.entry.tags.isNotEmpty) ...[
              const SizedBox(height: 24),
              _buildTagsSection(),
            ],
            const SizedBox(height: 24),
            _buildMetadataSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildEntryHeader() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.entry.english,
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.entry.translation,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (widget.entry.phoneticHelper != null) ...[
                        const SizedBox(height: 6),
                        Text(
                          '[${widget.entry.phoneticHelper}]',
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (widget.entry.verified)
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.verified,
                          color: Colors.green,
                          size: 24,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Verified',
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: Colors.green,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(
                  Icons.language,
                  size: 16,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                Text(
                  '${widget.entry.languageName} (${widget.entry.languageCode})',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                if (widget.entry.dialectLabel != null) ...[
                  const SizedBox(width: 16),
                  Icon(
                    Icons.account_tree,
                    size: 16,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    widget.entry.dialectLabel!,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
            if (widget.entry.category != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.category_outlined,
                    size: 16,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    widget.entry.category!,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAudioSection() {
    return Consumer<AudioProvider>(
      builder: (context, audioProvider, child) {
        if (audioProvider.isLoading) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Center(child: CircularProgressIndicator()),
            ),
          );
        }

        final clips = audioProvider.clipsForEntry
            .where((clip) => clip.entryId == widget.entry.id)
            .toList();

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.audiotrack,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Audio Recordings',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    _buildRecordButton(),
                  ],
                ),
                const SizedBox(height: 16),
                
                if (clips.isEmpty)
                  _buildEmptyAudioState()
                else
                  _buildAudioClipsList(clips),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyAudioState() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.mic_none_outlined,
            size: 48,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 12),
          Text(
            'No Audio Recordings',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Record pronunciation audio to help students learn',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildAudioClipsList(List<AudioClip> clips) {
    return Column(
      children: clips.map((clip) => _AudioClipTile(
        clip: clip,
        entry: widget.entry,
        onSetReference: () => _setAsReference(clip),
        onDelete: () => _deleteClip(clip),
      )).toList(),
    );
  }

  Widget _buildRecordButton() {
    final authProvider = context.watch<AuthProvider>();
    
    // if (authProvider.currentUser?.role != UserRole.teacher) {
    //   return const SizedBox();
    // }

    return OutlinedButton.icon(
      onPressed: _showRecorderSheet,
      icon: const Icon(Icons.mic, size: 18),
      label: const Text('Record'),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
    );
  }

  Widget _buildNotesSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.notes_outlined,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Text(
                  'Notes',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              widget.entry.notes!,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTagsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.local_offer_outlined,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Text(
                  'Tags',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: widget.entry.tags.map((tag) => Chip(
                label: Text(tag),
                backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                labelStyle: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
                side: BorderSide.none,
              )).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetadataSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.info_outlined,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Text(
                  'Information',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _InfoRow(
              label: 'Entry ID',
              value: widget.entry.id.substring(0, 8) + '...',
            ),
            _InfoRow(
              label: 'Created',
              value: _formatDate(widget.entry.createdAt),
            ),
            _InfoRow(
              label: 'Updated',
              value: _formatDate(widget.entry.updatedAt),
            ),
            if (widget.entry.source != null)
              _InfoRow(
                label: 'Source',
                value: widget.entry.source!,
              ),
            if (widget.entry.verifiedBy != null)
              _InfoRow(
                label: 'Verified by',
                value: widget.entry.verifiedBy!,
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _showRecorderSheet() async {
    final authProvider = context.read<AuthProvider>();
    
    if (authProvider.currentUser == null) return;

    try {
      final clip = await RecorderSheet.show(
        context,
        entryId: widget.entry.id,
        languageCode: widget.entry.languageCode,
        speakerRole: SpeakerRole.teacher,
        userId: authProvider.currentUser!.id,
        variantLabel: widget.entry.dialectLabel,
      );

      if (clip != null && mounted) {
        context.read<AudioProvider>().loadClipsForEntry(widget.entry.id);
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Audio recorded successfully'),
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to record audio: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  Future<void> _setAsReference(AudioClip clip) async {
    try {
      await context.read<AudioProvider>().setAsReference(clip);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Set as reference audio'),
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to set reference: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  Future<void> _deleteClip(AudioClip clip) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Audio'),
        content: const Text('Are you sure you want to delete this audio recording?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await context.read<AudioProvider>().deleteClip(clip.id);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Audio deleted successfully'),
              backgroundColor: Theme.of(context).colorScheme.primary,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to delete audio: $e'),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      }
    }
  }

  Future<void> _showDeleteDialog() async {
    // TODO: Implement entry deletion
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

class _AudioClipTile extends StatelessWidget {
  final AudioClip clip;
  final DictionaryEntry entry;
  final VoidCallback onSetReference;
  final VoidCallback onDelete;

  const _AudioClipTile({
    required this.clip,
    required this.entry,
    required this.onSetReference,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        border: Border.all(
          color: clip.isReference 
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.outline.withOpacity(0.2),
        ),
        borderRadius: BorderRadius.circular(12),
        color: clip.isReference 
            ? Theme.of(context).colorScheme.primaryContainer.withOpacity(0.1)
            : null,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _getSpeakerIcon(clip.speakerRole),
                  size: 20,
                  color: _getSpeakerColor(context, clip.speakerRole),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            _getSpeakerLabel(clip.speakerRole),
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (clip.isReference) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.primary,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'REFERENCE',
                                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                  color: Theme.of(context).colorScheme.onPrimary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      if (clip.note?.isNotEmpty == true) ...[
                        const SizedBox(height: 2),
                        Text(
                          clip.note!,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    switch (value) {
                      case 'reference':
                        onSetReference();
                        break;
                      case 'delete':
                        onDelete();
                        break;
                    }
                  },
                  itemBuilder: (context) => [
                    if (!clip.isReference)
                      const PopupMenuItem(
                        value: 'reference',
                        child: Row(
                          children: [
                            Icon(Icons.star_outline),
                            SizedBox(width: 12),
                            Text('Set as Reference'),
                          ],
                        ),
                      ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete_outline, color: Colors.red),
                          SizedBox(width: 12),
                          Text('Delete', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            AudioPlayerWidget(
              clipId: clip.id,
              compact: false,
              allowABLoop: true,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Text(
                  'Duration: ${_formatDuration(clip.durationMs)}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  'Recorded: ${_formatDate(clip.createdAt)}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  IconData _getSpeakerIcon(SpeakerRole role) {
    switch (role) {
      case SpeakerRole.native:
        return Icons.person_outlined;
      case SpeakerRole.teacher:
        return Icons.school_outlined;
      case SpeakerRole.parent:
        return Icons.family_restroom_outlined;
    }
  }

  Color _getSpeakerColor(BuildContext context, SpeakerRole role) {
    switch (role) {
      case SpeakerRole.native:
        return Theme.of(context).colorScheme.primary;
      case SpeakerRole.teacher:
        return Theme.of(context).colorScheme.secondary;
      case SpeakerRole.parent:
        return Theme.of(context).colorScheme.tertiary;
    }
  }

  String _getSpeakerLabel(SpeakerRole role) {
    switch (role) {
      case SpeakerRole.native:
        return 'Native Speaker';
      case SpeakerRole.teacher:
        return 'Teacher';
      case SpeakerRole.parent:
        return 'Parent';
    }
  }

  String _formatDuration(int ms) {
    final duration = Duration(milliseconds: ms);
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes}:${seconds.toString().padLeft(2, '0')}';
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}
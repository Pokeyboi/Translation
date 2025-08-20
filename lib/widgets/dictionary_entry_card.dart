import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/dictionary_entry.dart';
import '../models/audio_clip.dart';
import '../models/user_model.dart';
import '../providers/audio_provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/audio_player_widget.dart';
import '../widgets/recorder_sheet.dart';

class DictionaryEntryCard extends StatelessWidget {
  final DictionaryEntry entry;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;

  const DictionaryEntryCard({
    super.key,
    required this.entry,
    this.onTap,
    this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
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
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          entry.english,
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          entry.translation,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        if (entry.phoneticHelper != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            '[${entry.phoneticHelper}]',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Column(
                    children: [
                      if (entry.verified)
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Icon(
                            Icons.verified,
                            size: 16,
                            color: Colors.green,
                          ),
                        ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _AudioButtonsRow(entry: entry),
                          const SizedBox(width: 8),
                          if (onEdit != null)
                            IconButton(
                              onPressed: onEdit,
                              icon: const Icon(Icons.edit),
                              iconSize: 20,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(
                                minWidth: 32,
                                minHeight: 32,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
              
              if (entry.category != null || entry.tags.isNotEmpty) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    if (entry.category != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          entry.category!,
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ...entry.tags.take(3).map(
                      (tag) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.secondary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          tag,
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: Theme.of(context).colorScheme.secondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                    if (entry.tags.length > 3)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.outline.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '+${entry.tags.length - 3}',
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
              
              if (entry.notes != null) ...[
                const SizedBox(height: 8),
                Text(
                  entry.notes!,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _AudioButtonsRow extends StatefulWidget {
  final DictionaryEntry entry;

  const _AudioButtonsRow({required this.entry});

  @override
  State<_AudioButtonsRow> createState() => _AudioButtonsRowState();
}

class _AudioButtonsRowState extends State<_AudioButtonsRow> {
  AudioClip? _referenceClip;
  AudioClip? _teacherClip;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadAudioClips();
  }

  Future<void> _loadAudioClips() async {
    setState(() => _isLoading = true);

    try {
      final audioProvider = context.read<AudioProvider>();
      
      _referenceClip = await audioProvider.getReferenceClip(
        widget.entry.id,
        widget.entry.languageCode,
      );

      final teacherClips = await audioProvider.getClipsBySpeaker(
        widget.entry.id,
        SpeakerRole.teacher,
      );
      
      _teacherClip = teacherClips.isNotEmpty ? teacherClips.first : null;

    } catch (e) {
      // Handle error silently for card display
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Native/Reference Audio Button
        if (_referenceClip != null)
          _AudioButton(
            clip: _referenceClip!,
            icon: Icons.volume_up,
            color: Theme.of(context).colorScheme.primary,
            tooltip: 'Play reference audio',
          ),

        // Teacher Audio Button
        if (_teacherClip != null) ...[
          const SizedBox(width: 4),
          _AudioButton(
            clip: _teacherClip!,
            icon: Icons.record_voice_over,
            color: Theme.of(context).colorScheme.secondary,
            tooltip: 'Play teacher audio',
          ),
        ],

        // Record Button (for teachers)
        const SizedBox(width: 4),
        _RecordButton(entry: widget.entry),
      ],
    );
  }
}

class _AudioButton extends StatelessWidget {
  final AudioClip clip;
  final IconData icon;
  final Color color;
  final String tooltip;

  const _AudioButton({
    required this.clip,
    required this.icon,
    required this.color,
    required this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: IconButton(
        onPressed: () => _playClip(context),
        icon: Icon(icon),
        iconSize: 18,
        color: color,
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(
          minWidth: 28,
          minHeight: 28,
        ),
      ),
    );
  }

  Future<void> _playClip(BuildContext context) async {
    try {
      final audioProvider = context.read<AudioProvider>();
      await audioProvider.playClip(clip);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to play audio: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }
}

class _RecordButton extends StatelessWidget {
  final DictionaryEntry entry;

  const _RecordButton({required this.entry});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    
    // Only show record button for teachers
    // if (authProvider.currentUser?.role != UserRole.teacher) {
    //   return const SizedBox();
    // }

    return Tooltip(
      message: 'Record teacher audio',
      child: IconButton(
        onPressed: () => _showRecorderSheet(context),
        icon: const Icon(Icons.mic),
        iconSize: 18,
        color: Theme.of(context).colorScheme.tertiary,
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(
          minWidth: 28,
          minHeight: 28,
        ),
      ),
    );
  }

  Future<void> _showRecorderSheet(BuildContext context) async {
    final authProvider = context.read<AuthProvider>();
    
    if (authProvider.currentUser == null) return;

    try {
      final clip = await RecorderSheet.show(
        context,
        entryId: entry.id,
        languageCode: entry.languageCode,
        speakerRole: SpeakerRole.teacher,
        userId: authProvider.currentUser!.id,
        variantLabel: entry.dialectLabel,
      );

      if (clip != null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Teacher audio recorded successfully'),
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
        );
        
        // Refresh the parent widget to show new audio button
        if (context.mounted) {
          // This will trigger a rebuild of the audio buttons
          (context as Element).markNeedsBuild();
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to record audio: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }
}
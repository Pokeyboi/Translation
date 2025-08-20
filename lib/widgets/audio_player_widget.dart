import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/playback_service.dart';
import '../theme.dart';

class AudioPlayerWidget extends StatefulWidget {
  final String? clipId;
  final String? audioPath;
  final double initialSpeed;
  final bool allowABLoop;
  final bool compact;
  final String? label;

  const AudioPlayerWidget({
    super.key,
    this.clipId,
    this.audioPath,
    this.initialSpeed = 1.0,
    this.allowABLoop = true,
    this.compact = false,
    this.label,
  }) : assert(clipId != null || audioPath != null, 'Either clipId or audioPath must be provided');

  @override
  State<AudioPlayerWidget> createState() => _AudioPlayerWidgetState();
}

class _AudioPlayerWidgetState extends State<AudioPlayerWidget> {
  final PlaybackService _playback = PlaybackService.instance;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  Future<void> _initializePlayer() async {
    try {
      await _playback.initialize();
      await _playback.setSpeed(widget.initialSpeed);
      setState(() => _isInitialized = true);
    } catch (e) {
      print('Error initializing audio player: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }

    return StreamBuilder<PlaybackState>(
      stream: _playback.stateStream,
      builder: (context, stateSnapshot) {
        final state = stateSnapshot.data ?? PlaybackState.stopped;

        return Container(
          padding: EdgeInsets.symmetric(
            horizontal: widget.compact ? 12 : 16,
            vertical: widget.compact ? 8 : 12,
          ),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.3),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.label != null) ...[
                Text(
                  widget.label!,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 8),
              ],
              _buildControlsRow(context, state),
              if (!widget.compact) ...[
                const SizedBox(height: 12),
                _buildProgressBar(context),
                if (widget.allowABLoop) ...[
                  const SizedBox(height: 8),
                  _buildABLoopControls(context),
                ],
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildControlsRow(BuildContext context, PlaybackState state) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Play/Pause Button
        _buildPlayPauseButton(context, state),
        
        if (!widget.compact) ...[
          const SizedBox(width: 16),
          // Speed Control
          _buildSpeedButton(context),
          
          const SizedBox(width: 16),
          // Stop Button
          _buildStopButton(context, state),
        ],
        
        // Time Display
        const SizedBox(width: 16),
        _buildTimeDisplay(context),
      ],
    );
  }

  Widget _buildPlayPauseButton(BuildContext context, PlaybackState state) {
    IconData icon;
    VoidCallback? onPressed;

    switch (state) {
      case PlaybackState.loading:
        return const SizedBox(
          width: 40,
          height: 40,
          child: Center(
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        );
      
      case PlaybackState.playing:
        icon = Icons.pause;
        onPressed = () => _playback.pause();
        break;
      
      case PlaybackState.paused:
        icon = Icons.play_arrow;
        onPressed = () => _playback.resume();
        break;
      
      default:
        icon = Icons.play_arrow;
        onPressed = _playAudio;
    }

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary,
        shape: BoxShape.circle,
      ),
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(icon),
        color: Theme.of(context).colorScheme.onPrimary,
        iconSize: widget.compact ? 20 : 24,
      ),
    );
  }

  Widget _buildSpeedButton(BuildContext context) {
    return StreamBuilder<double>(
      stream: _playback.speedStream,
      builder: (context, snapshot) {
        final speed = snapshot.data ?? 1.0;
        return TextButton(
          onPressed: () => _playback.toggleSpeed(),
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
          ),
          child: Text(
            '${speed}×',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSecondaryContainer,
              fontWeight: FontWeight.w600,
            ),
          ),
        );
      },
    );
  }

  Widget _buildStopButton(BuildContext context, PlaybackState state) {
    return IconButton(
      onPressed: state == PlaybackState.stopped ? null : () => _playback.stop(),
      icon: const Icon(Icons.stop),
      color: Theme.of(context).colorScheme.onSurfaceVariant,
      iconSize: 20,
    );
  }

  Widget _buildTimeDisplay(BuildContext context) {
    return StreamBuilder<Duration>(
      stream: _playback.positionStream,
      builder: (context, positionSnapshot) {
        return StreamBuilder<Duration>(
          stream: _playback.durationStream,
          builder: (context, durationSnapshot) {
            final position = positionSnapshot.data ?? Duration.zero;
            final duration = durationSnapshot.data ?? Duration.zero;

            return Text(
              '${PlaybackService.formatDuration(position)} / ${PlaybackService.formatDuration(duration)}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontFamily: 'monospace',
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildProgressBar(BuildContext context) {
    return StreamBuilder<Duration>(
      stream: _playback.positionStream,
      builder: (context, positionSnapshot) {
        return StreamBuilder<Duration>(
          stream: _playback.durationStream,
          builder: (context, durationSnapshot) {
            final position = positionSnapshot.data ?? Duration.zero;
            final duration = durationSnapshot.data ?? Duration.zero;
            final progress = duration.inMilliseconds > 0 
                ? position.inMilliseconds / duration.inMilliseconds 
                : 0.0;

            return SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 2,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
              ),
              child: Slider(
                value: progress.clamp(0.0, 1.0),
                onChanged: (value) {
                  final newPosition = Duration(
                    milliseconds: (value * duration.inMilliseconds).round(),
                  );
                  _playback.seek(newPosition);
                },
                activeColor: Theme.of(context).colorScheme.primary,
                inactiveColor: Theme.of(context).colorScheme.outline.withOpacity(0.3),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildABLoopControls(BuildContext context) {
    return StreamBuilder<ABLoopState>(
      stream: _playback.abLoopStream,
      builder: (context, snapshot) {
        final loopState = snapshot.data ?? ABLoopState.disabled;

        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // A Point Button
            TextButton(
              onPressed: () => _playback.setLoopPoint('A'),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                backgroundColor: loopState != ABLoopState.disabled && _playback.loopPointA != null
                    ? Theme.of(context).colorScheme.primaryContainer
                    : Theme.of(context).colorScheme.surfaceContainerHighest,
              ),
              child: Text(
                'A',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: loopState != ABLoopState.disabled && _playback.loopPointA != null
                      ? Theme.of(context).colorScheme.onPrimaryContainer
                      : Theme.of(context).colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),

            const SizedBox(width: 8),

            // B Point Button
            TextButton(
              onPressed: loopState == ABLoopState.settingB || loopState == ABLoopState.looping
                  ? () => _playback.setLoopPoint('B')
                  : null,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                backgroundColor: loopState == ABLoopState.looping
                    ? Theme.of(context).colorScheme.primaryContainer
                    : Theme.of(context).colorScheme.surfaceContainerHighest,
              ),
              child: Text(
                'B',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: loopState == ABLoopState.looping
                      ? Theme.of(context).colorScheme.onPrimaryContainer
                      : Theme.of(context).colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),

            const SizedBox(width: 12),

            // Clear Loop Button
            TextButton.icon(
              onPressed: loopState != ABLoopState.disabled 
                  ? () => _playback.clearABLoop()
                  : null,
              icon: const Icon(Icons.clear, size: 14),
              label: Text(
                'Clear',
                style: Theme.of(context).textTheme.labelSmall,
              ),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _playAudio() async {
    try {
      if (widget.clipId != null) {
        await _playback.playClip(widget.clipId!);
      } else if (widget.audioPath != null) {
        await _playback.playFromPath(widget.audioPath!);
      }
    } catch (e) {
      if (mounted) {
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
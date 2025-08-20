import 'package:flutter/material.dart';
import 'package:flutter_audio_waveforms/flutter_audio_waveforms.dart';
import '../services/recorder_service.dart';
import '../services/playback_service.dart';
import '../models/audio_clip.dart';
import '../theme.dart';

class RecorderSheet extends StatefulWidget {
  final String entryId;
  final String languageCode;
  final SpeakerRole speakerRole;
  final String userId;
  final String? studentId;
  final String? classId;
  final String? variantLabel;
  final String? initialNote;
  final bool requireConsent;
  final Function(AudioClip)? onSaved;

  const RecorderSheet({
    super.key,
    required this.entryId,
    required this.languageCode,
    required this.speakerRole,
    required this.userId,
    this.studentId,
    this.classId,
    this.variantLabel,
    this.initialNote,
    this.requireConsent = false,
    this.onSaved,
  });

  @override
  State<RecorderSheet> createState() => _RecorderSheetState();

  static Future<AudioClip?> show(
    BuildContext context, {
    required String entryId,
    required String languageCode,
    required SpeakerRole speakerRole,
    required String userId,
    String? studentId,
    String? classId,
    String? variantLabel,
    String? initialNote,
    bool requireConsent = false,
  }) async {
    return showModalBottomSheet<AudioClip>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => RecorderSheet(
        entryId: entryId,
        languageCode: languageCode,
        speakerRole: speakerRole,
        userId: userId,
        studentId: studentId,
        classId: classId,
        variantLabel: variantLabel,
        initialNote: initialNote,
        requireConsent: requireConsent,
        onSaved: (clip) => Navigator.of(context).pop(clip),
      ),
    );
  }
}

class _RecorderSheetState extends State<RecorderSheet> with TickerProviderStateMixin {
  final RecorderService _recorder = RecorderService.instance;
  final PlaybackService _playback = PlaybackService.instance;
  final TextEditingController _noteController = TextEditingController();
  final TextEditingController _variantController = TextEditingController();

  late AnimationController _pulseController;
  late AnimationController _waveController;
  
  RecorderState _state = RecorderState.idle;
  String? _recordingPath;
  bool _consentPublic = false;
  List<double> _waveformData = [];
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _initializeRecorder();
    _noteController.text = widget.initialNote ?? '';
    _variantController.text = widget.variantLabel ?? '';
  }

  void _initializeControllers() {
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    
    _waveController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
  }

  Future<void> _initializeRecorder() async {
    final initialized = await _recorder.initialize();
    setState(() => _isInitialized = initialized);
    
    // Listen to recorder state changes
    _recorder.stateStream.listen((state) {
      if (mounted) {
        setState(() => _state = state);
        if (state == RecorderState.recording) {
          _pulseController.repeat();
        } else {
          _pulseController.stop();
        }
      }
    });

    // Listen to amplitude changes for waveform
    _recorder.amplitudeStream.listen((amplitude) {
      if (mounted && _state == RecorderState.recording) {
        setState(() {
          _waveformData.add(amplitude);
          if (_waveformData.length > 100) {
            _waveformData.removeAt(0);
          }
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          _buildHeader(context),
          Expanded(
            child: !_isInitialized
                ? _buildPermissionRequest(context)
                : _buildRecorderContent(context),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.mic,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Record Audio',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '${widget.speakerRole.name.toUpperCase()} • ${widget.languageCode}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close),
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionRequest(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.mic_off_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              'Microphone Permission Required',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              _recorder.getPermissionRationale(),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _initializeRecorder,
              icon: const Icon(Icons.mic),
              label: const Text('Grant Permission'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecorderContent(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildWaveformDisplay(context),
                const SizedBox(height: 24),
                _buildRecordingButton(context),
                const SizedBox(height: 16),
                _buildTimeDisplay(context),
                const SizedBox(height: 24),
                _buildControls(context),
              ],
            ),
          ),
          if (_state == RecorderState.stopped) ...[
            _buildMetadataForm(context),
            const SizedBox(height: 16),
            _buildActionButtons(context),
          ],
        ],
      ),
    );
  }

  Widget _buildWaveformDisplay(BuildContext context) {
    return Container(
      height: 100,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: _state == RecorderState.idle
          ? Center(
              child: Text(
                'Ready to record',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            )
          : _buildWaveform(context),
    );
  }

  Widget _buildWaveform(BuildContext context) {
    if (_waveformData.isEmpty) {
      return const Center(child: Text('Recording...'));
    }

    return CustomPaint(
      painter: WaveformPainter(
        waveformData: _waveformData,
        color: Theme.of(context).colorScheme.primary,
        backgroundColor: Colors.transparent,
      ),
    );
  }

  Widget _buildRecordingButton(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        final scale = _state == RecorderState.recording
            ? 1.0 + (_pulseController.value * 0.1)
            : 1.0;

        return Transform.scale(
          scale: scale,
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _getRecordButtonColor(context),
              boxShadow: _state == RecorderState.recording
                  ? [
                      BoxShadow(
                        color: Theme.of(context).colorScheme.error.withOpacity(0.3),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ]
                  : null,
            ),
            child: IconButton(
              onPressed: _handleRecordPress,
              icon: Icon(
                _getRecordButtonIcon(),
                size: 36,
              ),
              color: Theme.of(context).colorScheme.onError,
            ),
          ),
        );
      },
    );
  }

  Color _getRecordButtonColor(BuildContext context) {
    switch (_state) {
      case RecorderState.recording:
        return Theme.of(context).colorScheme.error;
      case RecorderState.paused:
        return Theme.of(context).colorScheme.tertiary;
      default:
        return Theme.of(context).colorScheme.primary;
    }
  }

  IconData _getRecordButtonIcon() {
    switch (_state) {
      case RecorderState.recording:
        return Icons.pause;
      case RecorderState.paused:
        return Icons.play_arrow;
      default:
        return Icons.mic;
    }
  }

  Widget _buildTimeDisplay(BuildContext context) {
    return StreamBuilder<Duration>(
      stream: _recorder.durationStream,
      builder: (context, snapshot) {
        final duration = snapshot.data ?? Duration.zero;
        return Text(
          PlaybackService.formatDuration(duration),
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontFamily: 'monospace',
            fontWeight: FontWeight.w300,
          ),
        );
      },
    );
  }

  Widget _buildControls(BuildContext context) {
    if (_state == RecorderState.idle) return const SizedBox();

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Stop Button
        OutlinedButton.icon(
          onPressed: _state == RecorderState.recording || _state == RecorderState.paused
              ? _handleStopPress
              : null,
          icon: const Icon(Icons.stop),
          label: const Text('Stop'),
        ),
        
        const SizedBox(width: 16),
        
        // Cancel Button
        TextButton.icon(
          onPressed: _handleCancelPress,
          icon: const Icon(Icons.delete_outline),
          label: const Text('Cancel'),
          style: TextButton.styleFrom(
            foregroundColor: Theme.of(context).colorScheme.error,
          ),
        ),
      ],
    );
  }

  Widget _buildMetadataForm(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.variantLabel == null) ...[
          Text(
            'Dialect/Variant (Optional)',
            style: Theme.of(context).textTheme.labelMedium,
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _variantController,
            decoration: const InputDecoration(
              hintText: 'e.g., Tedim, Hakha, etc.',
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
          ),
          const SizedBox(height: 16),
        ],
        
        Text(
          'Note (Optional)',
          style: Theme.of(context).textTheme.labelMedium,
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _noteController,
          maxLines: 2,
          decoration: const InputDecoration(
            hintText: 'Add a note about this recording...',
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
        ),
        
        if (widget.requireConsent) ...[
          const SizedBox(height: 16),
          CheckboxListTile(
            value: _consentPublic,
            onChanged: (value) => setState(() => _consentPublic = value ?? false),
            title: Text(
              'Allow this recording to be used beyond this class',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
          ),
        ],
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Row(
      children: [
        // Re-record Button
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _handleReRecordPress,
            icon: const Icon(Icons.refresh),
            label: const Text('Re-record'),
          ),
        ),
        
        const SizedBox(width: 16),
        
        // Save Button
        Expanded(
          child: FilledButton.icon(
            onPressed: _handleSavePress,
            icon: const Icon(Icons.save),
            label: const Text('Save'),
          ),
        ),
      ],
    );
  }

  Future<void> _handleRecordPress() async {
    try {
      switch (_state) {
        case RecorderState.idle:
          _recordingPath = await _recorder.startRecording(
            entryId: widget.entryId,
            languageCode: widget.languageCode,
            variantLabel: _variantController.text.isNotEmpty ? _variantController.text : null,
          );
          break;
        
        case RecorderState.recording:
          await _recorder.pauseRecording();
          break;
        
        case RecorderState.paused:
          await _recorder.resumeRecording();
          break;
        
        default:
          break;
      }
    } catch (e) {
      _showError('Recording error: $e');
    }
  }

  Future<void> _handleStopPress() async {
    try {
      await _recorder.stopRecording();
      setState(() {
        _waveformData.clear();
      });
    } catch (e) {
      _showError('Stop error: $e');
    }
  }

  Future<void> _handleCancelPress() async {
    try {
      await _recorder.cancelRecording();
      Navigator.of(context).pop();
    } catch (e) {
      _showError('Cancel error: $e');
    }
  }

  Future<void> _handleReRecordPress() async {
    setState(() {
      _state = RecorderState.idle;
      _waveformData.clear();
    });
  }

  Future<void> _handleSavePress() async {
    try {
      final clip = await _recorder.saveRecording(
        entryId: widget.entryId,
        speakerRole: widget.speakerRole,
        userId: widget.userId,
        languageCode: widget.languageCode,
        studentId: widget.studentId,
        classId: widget.classId,
        variantLabel: _variantController.text.isNotEmpty ? _variantController.text : null,
        note: _noteController.text.isNotEmpty ? _noteController.text : null,
        consentPublic: _consentPublic,
      );

      widget.onSaved?.call(clip);
      
      if (mounted) {
        Navigator.of(context).pop(clip);
      }
    } catch (e) {
      _showError('Save error: $e');
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _waveController.dispose();
    _noteController.dispose();
    _variantController.dispose();
    super.dispose();
  }
}

class WaveformPainter extends CustomPainter {
  final List<double> waveformData;
  final Color color;
  final Color backgroundColor;

  WaveformPainter({
    required this.waveformData,
    required this.color,
    required this.backgroundColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    if (waveformData.isEmpty) return;

    final path = Path();
    final centerY = size.height / 2;
    final stepX = size.width / waveformData.length;

    for (int i = 0; i < waveformData.length; i++) {
      final x = i * stepX;
      final amplitude = waveformData[i] * centerY * 0.8;
      
      if (i == 0) {
        path.moveTo(x, centerY - amplitude);
      } else {
        path.lineTo(x, centerY - amplitude);
      }
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
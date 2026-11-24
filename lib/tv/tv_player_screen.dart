import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:provider/provider.dart';
import 'dart:async';

import '../providers/auth_provider.dart';
import '../services/iptv_api_client.dart';
import '../models/iptv_models.dart';
import '../widgets/tv_focus_wrapper.dart';
import 'playback_database.dart';

class TVPlayerScreen extends StatefulWidget {
  final String streamType;
  final String streamName;
  final String streamId;
  final String? containerExtension;

  const TVPlayerScreen({
    super.key,
    required this.streamType,
    required this.streamName,
    required this.streamId,
    this.containerExtension,
  });

  @override
  State<TVPlayerScreen> createState() => _TVPlayerScreenState();
}

class _TVPlayerScreenState extends State<TVPlayerScreen> {
  VideoPlayerController? _controller;
  bool _isLoading = true;
  bool _isPlaying = true;
  bool _showControls = true;
  Timer? _hideControlsTimer;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;

  // Channel switching for Live TV & Next Episode for Series
  int _currentChannelIndex = 0;
  List<StreamItem> _playlistChannels = [];
  String _currentStreamId = '';
  String _currentStreamName = '';
  bool _showOsdBanner = false;
  String _osdMessage = '';
  Timer? _osdTimer;

  // Focus Nodes for OSD Controls
  final FocusNode _playPauseFocusNode = FocusNode();
  final FocusNode _rewindFocusNode = FocusNode();
  final FocusNode _forwardFocusNode = FocusNode();
  final FocusNode _backFocusNode = FocusNode();
  final FocusNode _prevChannelFocusNode = FocusNode();
  final FocusNode _nextChannelFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _currentStreamId = widget.streamId;
    _currentStreamName = widget.streamName;
    try {
      WakelockPlus.enable();
    } catch (_) {}
    _initPlayer();
    if (widget.streamType == 'live') {
      _loadLiveChannels();
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusScope.of(context).requestFocus(_backFocusNode);
    });
  }

  Future<void> _loadLiveChannels() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final streams = await IptvApiClient.getStreams(auth.activeCode, 'live', '');
    if (mounted) {
      setState(() {
        _playlistChannels = streams;
        _currentChannelIndex = streams.indexWhere((s) => s.streamId == widget.streamId);
        if (_currentChannelIndex < 0) _currentChannelIndex = 0;
      });
    }
  }

  Future<void> _initPlayer() async {
    _controller?.removeListener(_updateState);
    _controller?.dispose();
    _controller = null;

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final url = IptvApiClient.getStreamUrl(
      auth.activeCode,
      widget.streamType,
      _currentStreamId,
      extension: widget.containerExtension,
    );

    try {
      _controller = VideoPlayerController.networkUrl(
        Uri.parse(url),
        httpHeaders: const {
          'User-Agent': 'VLC/3.0.16 LibVLC/3.0.16',
          'Accept': '*/*',
        },
      );

      await _controller!.initialize();
      _controller!.setLooping(true);
      _controller!.addListener(_updateState);

      if (widget.streamType != 'live') {
        final savedMs = await PlaybackDatabase.getProgress(_currentStreamId);
        if (savedMs > 0 && savedMs < _controller!.value.duration.inMilliseconds) {
          await _controller!.seekTo(Duration(milliseconds: savedMs));
        }
      }

      _controller!.play();

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
      _startHideControlsTimer();
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _switchChannel(int direction) {
    if (_playlistChannels.isEmpty) {
      final currentIdInt = int.tryParse(_currentStreamId) ?? 0;
      if (currentIdInt > 0) {
        final nextId = (currentIdInt + direction).toString();
        setState(() {
          _currentStreamId = nextId;
          _currentStreamName = 'Channel $nextId';
          _isLoading = true;
          _showOsdBanner = true;
          _osdMessage = 'Switching to Channel $nextId';
        });
        _osdTimer?.cancel();
        _osdTimer = Timer(const Duration(seconds: 3), () {
          if (mounted) setState(() => _showOsdBanner = false);
        });
        _initPlayer();
      }
      return;
    }

    setState(() {
      _currentChannelIndex = (_currentChannelIndex + direction) % _playlistChannels.length;
      if (_currentChannelIndex < 0) _currentChannelIndex = _playlistChannels.length - 1;
      final target = _playlistChannels[_currentChannelIndex];
      _currentStreamId = target.streamId;
      _currentStreamName = target.name;
      _isLoading = true;
      _showOsdBanner = true;
      _osdMessage = 'Channel ${_currentChannelIndex + 1}: $_currentStreamName';
    });

    _osdTimer?.cancel();
    _osdTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() => _showOsdBanner = false);
      }
    });

    _initPlayer();
  }

  void _playNextEpisode() {
    final currentIdInt = int.tryParse(_currentStreamId) ?? 0;
    if (currentIdInt > 0) {
      final nextId = (currentIdInt + 1).toString();
      setState(() {
        _currentStreamId = nextId;
        _currentStreamName = 'Next Episode ($nextId)';
        _isLoading = true;
        _showOsdBanner = true;
        _osdMessage = 'Playing Next Episode';
      });
      _osdTimer?.cancel();
      _osdTimer = Timer(const Duration(seconds: 3), () {
        if (mounted) setState(() => _showOsdBanner = false);
      });
      _initPlayer();
    }
  }

  void _updateState() {
    if (!mounted || _controller == null) return;
    setState(() {
      _isPlaying = _controller!.value.isPlaying;
      _position = _controller!.value.position;
      _duration = _controller!.value.duration;
    });

    if (widget.streamType != 'live' && _position.inMilliseconds > 0) {
      PlaybackDatabase.saveProgress(_currentStreamId, _position.inMilliseconds);
      PlaybackDatabase.addToHistory(StreamItem(
        streamId: _currentStreamId,
        name: _currentStreamName,
        streamType: widget.streamType,
        streamIcon: '',
      ));
    }
  }

  void _startHideControlsTimer() {
    _hideControlsTimer?.cancel();
    _hideControlsTimer = Timer(const Duration(seconds: 5), () {
      if (mounted && _isPlaying) {
        setState(() => _showControls = false);
      }
    });
  }

  void _togglePlayPause() {
    if (_controller == null) return;
    setState(() {
      if (_controller!.value.isPlaying) {
        _controller!.pause();
      } else {
        _controller!.play();
      }
    });
    _startHideControlsTimer();
  }

  void _seekRelative(Duration offset) {
    if (_controller == null || widget.streamType == 'live') return;
    final newPos = _position + offset;
    final target = newPos < Duration.zero ? Duration.zero : (newPos > _duration ? _duration : newPos);
    _controller!.seekTo(target);
    _startHideControlsTimer();
    setState(() => _showControls = true);
  }

  @override
  void dispose() {
    _hideControlsTimer?.cancel();
    _osdTimer?.cancel();
    _controller?.removeListener(_updateState);
    _controller?.dispose();
    _playPauseFocusNode.dispose();
    _rewindFocusNode.dispose();
    _forwardFocusNode.dispose();
    _backFocusNode.dispose();
    _prevChannelFocusNode.dispose();
    _nextChannelFocusNode.dispose();
    try {
      WakelockPlus.disable();
    } catch (_) {}
    super.dispose();
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.abs().toString().padLeft(2, '0');
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    if (hours > 0) {
      return '$hours:${twoDigits(minutes)}:${twoDigits(seconds)}';
    }
    return '${twoDigits(minutes)}:${twoDigits(seconds)}';
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        _controller?.pause();
        _controller?.dispose();
      },
      child: CallbackShortcuts(
        bindings: <ShortcutActivator, VoidCallback>{
          const SingleActivator(LogicalKeyboardKey.arrowRight): () => _seekRelative(const Duration(seconds: 10)),
          const SingleActivator(LogicalKeyboardKey.arrowLeft): () => _seekRelative(const Duration(seconds: -10)),
          const SingleActivator(LogicalKeyboardKey.mediaFastForward): () => _seekRelative(const Duration(seconds: 10)),
          const SingleActivator(LogicalKeyboardKey.mediaRewind): () => _seekRelative(const Duration(seconds: -10)),
          const SingleActivator(LogicalKeyboardKey.select): _togglePlayPause,
          const SingleActivator(LogicalKeyboardKey.enter): _togglePlayPause,
          const SingleActivator(LogicalKeyboardKey.numpadEnter): _togglePlayPause,
          const SingleActivator(LogicalKeyboardKey.gameButtonA): _togglePlayPause,
          const SingleActivator(LogicalKeyboardKey.mediaPlayPause): _togglePlayPause,
          const SingleActivator(LogicalKeyboardKey.channelUp): () => widget.streamType == 'live' ? _switchChannel(-1) : null,
          const SingleActivator(LogicalKeyboardKey.channelDown): () => widget.streamType == 'live' ? _switchChannel(1) : null,
        },
        child: Focus(
          autofocus: true,
          onKeyEvent: (node, event) {
            if (event is KeyDownEvent) {
              final key = event.logicalKey;

              // Immediately exit player on physical Back button press
              if (key == LogicalKeyboardKey.escape ||
                  key == LogicalKeyboardKey.goBack ||
                  key == LogicalKeyboardKey.browserBack) {
                _controller?.pause();
                _controller?.dispose();
                Navigator.of(context).pop();
                return KeyEventResult.handled;
              }

              // Live TV Channel Switching via Up / Down arrows
              if (widget.streamType == 'live') {
                if (key == LogicalKeyboardKey.arrowUp || key == LogicalKeyboardKey.channelUp) {
                  _switchChannel(-1);
                  return KeyEventResult.handled;
                }
                if (key == LogicalKeyboardKey.arrowDown || key == LogicalKeyboardKey.channelDown) {
                  _switchChannel(1);
                  return KeyEventResult.handled;
                }
              }

              if (key == LogicalKeyboardKey.arrowUp ||
                  key == LogicalKeyboardKey.arrowDown ||
                  key == LogicalKeyboardKey.arrowLeft ||
                  key == LogicalKeyboardKey.arrowRight) {
                if (!_showControls) {
                  setState(() => _showControls = true);
                  _startHideControlsTimer();
                  return KeyEventResult.handled;
                }
              }
            }
            return KeyEventResult.ignored;
          },
          child: Scaffold(
            backgroundColor: Colors.black,
            body: Stack(
              fit: StackFit.expand,
              children: [
                // Video Surface
                Center(
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Color(0xFFE50914))
                      : _controller != null && _controller!.value.isInitialized
                          ? FittedBox(
                              fit: BoxFit.contain,
                              child: SizedBox(
                                width: _controller!.value.size.width > 0 ? _controller!.value.size.width : 16,
                                height: _controller!.value.size.height > 0 ? _controller!.value.size.height : 9,
                                child: VideoPlayer(_controller!),
                              ),
                            )
                          : const CircularProgressIndicator(color: Color(0xFFE50914)),
                ),

                // OSD Quick Info Banner for Channel Switching / Next Episode
                if (_showOsdBanner)
                  Positioned(
                    top: 36,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(color: const Color(0xFF3B82F6), width: 2),
                        ),
                        child: Text(
                          _osdMessage,
                          style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ),

                // Cinematic OSD Control Overlay
                if (_showControls)
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withOpacity(0.85),
                          Colors.transparent,
                          Colors.transparent,
                          Colors.black.withOpacity(0.85),
                        ],
                      ),
                    ),
                    child: SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Top Bar
                            Row(
                              children: [
                                TvFocusWrapper(
                                  focusNode: _backFocusNode,
                                  autofocus: true,
                                  onTap: () {
                                    _controller?.pause();
                                    _controller?.dispose();
                                    Navigator.of(context).pop();
                                  },
                                  child: const Padding(
                                    padding: EdgeInsets.all(8),
                                    child: Icon(Icons.arrow_back, color: Colors.white, size: 28),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Text(
                                    _currentStreamName,
                                    style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE50914),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    widget.streamType.toUpperCase(),
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                                  ),
                                ),
                              ],
                            ),

                            // Center Play/Pause & Channel Switching / Next Episode Controls
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                if (widget.streamType == 'live') ...[
                                  TvFocusWrapper(
                                    focusNode: _prevChannelFocusNode,
                                    onTap: () => _switchChannel(-1),
                                    child: const Padding(
                                      padding: EdgeInsets.all(12),
                                      child: Icon(Icons.skip_previous, color: Colors.white, size: 42),
                                    ),
                                  ),
                                  const SizedBox(width: 40),
                                ],
                                if (widget.streamType != 'live') ...[
                                  TvFocusWrapper(
                                    focusNode: _rewindFocusNode,
                                    onTap: () => _seekRelative(const Duration(seconds: -10)),
                                    child: const Padding(
                                      padding: EdgeInsets.all(12),
                                      child: Icon(Icons.replay_10, color: Colors.white, size: 42),
                                    ),
                                  ),
                                  const SizedBox(width: 40),
                                ],
                                TvFocusWrapper(
                                  focusNode: _playPauseFocusNode,
                                  onTap: _togglePlayPause,
                                  child: Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: Icon(
                                      _isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled,
                                      color: Colors.white,
                                      size: 72,
                                    ),
                                  ),
                                ),
                                if (widget.streamType != 'live' && widget.streamType != 'series') ...[
                                  const SizedBox(width: 40),
                                  TvFocusWrapper(
                                    focusNode: _forwardFocusNode,
                                    onTap: () => _seekRelative(const Duration(seconds: 10)),
                                    child: const Padding(
                                      padding: EdgeInsets.all(12),
                                      child: Icon(Icons.forward_10, color: Colors.white, size: 42),
                                    ),
                                  ),
                                ],
                                if (widget.streamType == 'series') ...[
                                  const SizedBox(width: 40),
                                  TvFocusWrapper(
                                    focusNode: _forwardFocusNode,
                                    onTap: _playNextEpisode,
                                    child: const Padding(
                                      padding: EdgeInsets.all(12),
                                      child: Icon(Icons.skip_next, color: Colors.white, size: 42),
                                    ),
                                  ),
                                ],
                                if (widget.streamType == 'live') ...[
                                  const SizedBox(width: 40),
                                  TvFocusWrapper(
                                    focusNode: _nextChannelFocusNode,
                                    onTap: () => _switchChannel(1),
                                    child: const Padding(
                                      padding: EdgeInsets.all(12),
                                      child: Icon(Icons.skip_next, color: Colors.white, size: 42),
                                    ),
                                  ),
                                ],
                              ],
                            ),

                            // Bottom Bar (Progress & Time)
                            Column(
                              children: [
                                if (widget.streamType != 'live') ...[
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(_formatDuration(_position), style: const TextStyle(color: Colors.white70, fontSize: 14)),
                                      Text(_formatDuration(_duration), style: const TextStyle(color: Colors.white70, fontSize: 14)),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(4),
                                    child: LinearProgressIndicator(
                                      value: _duration.inMilliseconds > 0 ? (_position.inMilliseconds / _duration.inMilliseconds).clamp(0.0, 1.0) : 0.0,
                                      backgroundColor: Colors.white24,
                                      valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFE50914)),
                                      minHeight: 6,
                                    ),
                                  ),
                                ] else ...[
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: Colors.red,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: const Text('LIVE STREAM (HD)', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

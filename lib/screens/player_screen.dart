import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:media_kit/media_kit.dart' as mk;
import 'package:media_kit_video/media_kit_video.dart' as mk_video;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;
import 'dart:async';

import '../providers/auth_provider.dart';
import '../services/iptv_api_client.dart';
import '../services/storage_service.dart';
import '../models/iptv_models.dart';

class PlayerScreen extends StatefulWidget {
  final String streamId;
  final String streamType;
  final String streamName;
  final String? containerExtension;
  final List<StreamItem>? playlistChannels;
  final int? currentChannelIndex;

  const PlayerScreen({
    super.key,
    required this.streamId,
    required this.streamType,
    required this.streamName,
    this.containerExtension,
    this.playlistChannels,
    this.currentChannelIndex,
  });

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  VideoPlayerController? _controller;
  mk.Player? _mkPlayer;
  mk_video.VideoController? _mkVideoController;
  bool _useMediaKit = false;
  bool _isLoading = true;
  bool _isPlaying = false;
  bool _showControls = true;
  bool _isFavorite = false;
  bool _isScreenLocked = false;
  bool _isLooping = false;
  bool _cinematicLighting = false;
  bool _volumeBoost = false;
  double _playbackSpeed = 1.0;
  String _selectedQuality = 'Auto (1080p)';
  String _selectedSubtitle = 'Off';
  String? _errorMessage;
  Timer? _hideControlsTimer;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  BoxFit _aspectRatio = BoxFit.contain;

  // Channel switching for Live TV
  int _currentIndex = 0;
  List<StreamItem> _channels = [];
  String _currentStreamId = '';
  String _currentStreamName = '';
  String? _currentExtension;
  bool _showOsdBanner = false;
  String _osdMessage = '';
  Timer? _osdTimer;

  @override
  void initState() {
    super.initState();
    _currentStreamId = widget.streamId;
    _currentStreamName = widget.streamName;
    _currentExtension = widget.containerExtension;
    _channels = widget.playlistChannels ?? [];
    if (_channels.isNotEmpty && widget.currentChannelIndex != null) {
      _currentIndex = widget.currentChannelIndex!;
    } else if (_channels.isNotEmpty) {
      _currentIndex = _channels.indexWhere((s) => s.streamId == widget.streamId);
      if (_currentIndex < 0) _currentIndex = 0;
    }

    try {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    } catch (_) {}

    try {
      WakelockPlus.enable();
    } catch (_) {}

    _checkFavorite();
    _initPlayer();
  }

  Future<void> _checkFavorite() async {
    final fav = await StorageService.isFavorite(_currentStreamId);
    setState(() {
      _isFavorite = fav;
    });
  }

  void _disposeCurrentPlayer() {
    _hideControlsTimer?.cancel();
    _controller?.removeListener(_updatePlayerState);
    _controller?.dispose();
    _controller = null;
    _mkPlayer?.dispose();
    _mkPlayer = null;
    _mkVideoController = null;
  }

  Future<void> _initPlayer() async {
    _disposeCurrentPlayer();
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final url = IptvApiClient.getStreamUrl(
      auth.activeCode,
      widget.streamType,
      _currentStreamId,
      extension: _currentExtension,
    );

    try {
      if (!kIsWeb && Platform.isWindows) {
        _useMediaKit = true;
        _mkPlayer = mk.Player();
        _mkVideoController = mk_video.VideoController(_mkPlayer!);
        await _mkPlayer!.open(mk.Media(url));
        _mkPlayer!.play();

        setState(() {
          _isLoading = false;
          _isPlaying = true;
        });
        _startHideControlsTimer();
        return;
      }

      _controller = VideoPlayerController.networkUrl(
        Uri.parse(url),
        httpHeaders: (!kIsWeb && Platform.isIOS) ? const {} : const {
          'User-Agent': 'VLC/3.0.16 LibVLC/3.0.16',
          'Accept': '*/*',
        },
      );

      await _controller!.initialize();
      _controller!.setLooping(_isLooping);

      if (widget.streamType != 'live') {
        final savedMs = await StorageService.getProgress(_currentStreamId);
        if (savedMs > 0 && savedMs < _controller!.value.duration.inMilliseconds) {
          await _controller!.seekTo(Duration(milliseconds: savedMs));
        }
      }

      _controller!.addListener(_updatePlayerState);
      _controller!.play();

      setState(() {
        _isLoading = false;
        _isPlaying = true;
      });

      _startHideControlsTimer();
    } catch (e) {
      if (!kIsWeb && Platform.isWindows) {
        try {
          _useMediaKit = true;
          _mkPlayer = mk.Player();
          _mkVideoController = mk_video.VideoController(_mkPlayer!);
          await _mkPlayer!.open(mk.Media(url));
          _mkPlayer!.play();

          setState(() {
            _isLoading = false;
            _isPlaying = true;
          });
          _startHideControlsTimer();
          return;
        } catch (e2) {
          setState(() {
            _isLoading = false;
            _errorMessage = 'Failed to load video stream.\nPlease check connection or subscription.\n\nDetails: $e2';
          });
          return;
        }
      }
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load video stream.\nPlease check connection or subscription.\n\nDetails: $e';
      });
    }
  }

  void _switchChannel(int direction) {
    if (_channels.isEmpty) return;
    setState(() {
      _currentIndex = (_currentIndex + direction) % _channels.length;
      if (_currentIndex < 0) _currentIndex = _channels.length - 1;
      final target = _channels[_currentIndex];
      _currentStreamId = target.streamId;
      _currentStreamName = target.name;
      _currentExtension = target.containerExtension;
      _isLoading = true;
      _errorMessage = null;
      _showOsdBanner = true;
      _osdMessage = 'Channel ${_currentIndex + 1}: $_currentStreamName';
    });

    _osdTimer?.cancel();
    _osdTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() => _showOsdBanner = false);
      }
    });

    _initPlayer();
  }

  void _seekRelative(Duration offset) {
    if (_controller == null || widget.streamType == 'live') return;
    final newPos = _position + offset;
    final target = newPos < Duration.zero ? Duration.zero : (newPos > _duration ? _duration : newPos);
    _controller!.seekTo(target);
    _startHideControlsTimer();
    setState(() {
      _showControls = true;
    });
  }

  void _updatePlayerState() {
    if (_controller == null || !mounted) return;
    setState(() {
      _isPlaying = _controller!.value.isPlaying;
      _position = _controller!.value.position;
      _duration = _controller!.value.duration;
    });

    if (widget.streamType != 'live' && _position.inMilliseconds > 0) {
      StorageService.saveProgress(_currentStreamId, _position.inMilliseconds);
    }
  }

  void _startHideControlsTimer() {
    _hideControlsTimer?.cancel();
    _hideControlsTimer = Timer(const Duration(seconds: 4), () {
      if (mounted && _isPlaying && !_isScreenLocked) {
        setState(() {
          _showControls = false;
        });
      }
    });
  }

  void _toggleControls() {
    setState(() {
      _showControls = !_showControls;
    });
    if (_showControls) {
      _startHideControlsTimer();
    }
  }

  Future<void> _toggleFavorite() async {
    await StorageService.toggleFavorite(_currentStreamId);
    await _checkFavorite();
  }

  void _cycleAspectRatio() {
    setState(() {
      if (_aspectRatio == BoxFit.contain) {
        _aspectRatio = BoxFit.cover;
      } else if (_aspectRatio == BoxFit.cover) {
        _aspectRatio = BoxFit.fill;
      } else {
        _aspectRatio = BoxFit.contain;
      }
    });
  }

  @override
  void dispose() {
    _disposeCurrentPlayer();
    _osdTimer?.cancel();

    try {
      WakelockPlus.disable();
    } catch (_) {}

    try {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
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
    return Scaffold(
      backgroundColor: Colors.black,
      body: Focus(
        autofocus: true,
        onKey: (node, event) {
          if (event is KeyDownEvent) {
            final key = event.logicalKey;

            // Center / OK / PlayPause
            if (key == LogicalKeyboardKey.select ||
                key == LogicalKeyboardKey.enter ||
                key == LogicalKeyboardKey.space ||
                key == LogicalKeyboardKey.mediaPlayPause) {
              _toggleControls();
              return KeyEventResult.handled;
            }

            // Back / Escape
            if (key == LogicalKeyboardKey.escape ||
                key == LogicalKeyboardKey.goBack ||
                key == LogicalKeyboardKey.browserBack) {
              Navigator.of(context).pop();
              return KeyEventResult.handled;
            }

            // Left / Right (VOD Seek)
            if (widget.streamType != 'live') {
              if (key == LogicalKeyboardKey.arrowLeft) {
                _seekRelative(const Duration(seconds: -10));
                return KeyEventResult.handled;
              }
              if (key == LogicalKeyboardKey.arrowRight) {
                _seekRelative(const Duration(seconds: 10));
                return KeyEventResult.handled;
              }
            } else {
              // Live TV: Up / Down channel switching
              if (key == LogicalKeyboardKey.arrowUp || key == LogicalKeyboardKey.channelUp) {
                _switchChannel(-1);
                return KeyEventResult.handled;
              }
              if (key == LogicalKeyboardKey.arrowDown || key == LogicalKeyboardKey.channelDown) {
                _switchChannel(1);
                return KeyEventResult.handled;
              }
            }
          }
          return KeyEventResult.ignored;
        },
        child: GestureDetector(
          onTap: _toggleControls,
          onVerticalDragEnd: (details) {
            if (widget.streamType == 'live') {
              if ((details.primaryVelocity ?? 0) < 0) {
                _switchChannel(1);
              } else if ((details.primaryVelocity ?? 0) > 0) {
                _switchChannel(-1);
              }
            }
          },
          onHorizontalDragEnd: (details) {
            if (widget.streamType != 'live') {
              if ((details.primaryVelocity ?? 0) < 0) {
                _seekRelative(const Duration(seconds: 10));
              } else if ((details.primaryVelocity ?? 0) > 0) {
                _seekRelative(const Duration(seconds: -10));
              }
            }
          },
          child: Stack(
            children: [
              // Video Player Center
              Center(
                child: _isLoading
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          CircularProgressIndicator(color: Color(0xFFE50914)),
                          SizedBox(height: 16),
                          Text('Buffering stream...', style: TextStyle(color: Colors.white70)),
                        ],
                      )
                    : _errorMessage != null
                        ? Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.error_outline, color: Colors.redAccent, size: 48),
                                const SizedBox(height: 16),
                                Text(
                                  _errorMessage!,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
                                ),
                                const SizedBox(height: 24),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE50914)),
                                  onPressed: () {
                                    setState(() {
                                      _isLoading = true;
                                      _errorMessage = null;
                                    });
                                    _initPlayer();
                                  },
                                  child: const Text('Retry Connection', style: TextStyle(color: Colors.white)),
                                ),
                              ],
                            ),
                          )
                        : _useMediaKit && _mkVideoController != null
                            ? Container(
                                color: Colors.black,
                                alignment: Alignment.center,
                                child: mk_video.Video(controller: _mkVideoController!),
                              )
                            : _controller != null && _controller!.value.isInitialized
                                ? Container(
                                    color: Colors.black,
                                    alignment: Alignment.center,
                                    child: FittedBox(
                                      fit: _aspectRatio,
                                      child: SizedBox(
                                        width: _controller!.value.size.width > 0 ? _controller!.value.size.width : 16,
                                        height: _controller!.value.size.height > 0 ? _controller!.value.size.height : 9,
                                        child: VideoPlayer(_controller!),
                                      ),
                                    ),
                                  )
                                : const Center(child: CircularProgressIndicator(color: Color(0xFFE50914))),
              ),

              // Controls Overlay
              if (_showControls && !_isScreenLocked)
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withOpacity(0.8),
                        Colors.transparent,
                        Colors.transparent,
                        Colors.black.withOpacity(0.8),
                      ],
                    ),
                  ),
                  child: SafeArea(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Top Bar
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          child: Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.arrow_back, color: Colors.white, size: 28),
                                onPressed: () => Navigator.of(context).pop(),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  widget.streamType == 'live' ? _currentStreamName : widget.streamName,
                                  style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              IconButton(
                                icon: Icon(_isFavorite ? Icons.favorite : Icons.favorite_border, color: _isFavorite ? const Color(0xFFE50914) : Colors.white, size: 26),
                                onPressed: _toggleFavorite,
                              ),
                            ],
                          ),
                        ),

                        // Center Play / Pause & Channel Switching Controls
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (widget.streamType == 'live') ...[
                              IconButton(
                                iconSize: 48,
                                color: Colors.white,
                                tooltip: 'Previous Channel',
                                icon: const Icon(Icons.skip_previous),
                                onPressed: () => _switchChannel(-1),
                              ),
                              const SizedBox(width: 32),
                            ],
                            if (widget.streamType != 'live')
                              IconButton(
                                iconSize: 42,
                                color: Colors.white,
                                icon: const Icon(Icons.replay_10),
                                onPressed: () => _seekRelative(const Duration(seconds: -10)),
                              ),
                            const SizedBox(width: 32),
                            IconButton(
                              iconSize: 68,
                              color: Colors.white,
                              icon: Icon(_isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled),
                              onPressed: () {
                                setState(() {
                                  if (_isPlaying) {
                                    _controller?.pause();
                                    _mkPlayer?.pause();
                                  } else {
                                    _controller?.play();
                                    _mkPlayer?.play();
                                  }
                                });
                                _startHideControlsTimer();
                              },
                            ),
                            const SizedBox(width: 32),
                            if (widget.streamType != 'live')
                              IconButton(
                                iconSize: 42,
                                color: Colors.white,
                                icon: const Icon(Icons.forward_10),
                                onPressed: () => _seekRelative(const Duration(seconds: 10)),
                              ),
                            if (widget.streamType == 'live') ...[
                              const SizedBox(width: 32),
                              IconButton(
                                iconSize: 48,
                                color: Colors.white,
                                tooltip: 'Next Channel',
                                icon: const Icon(Icons.skip_next),
                                onPressed: () => _switchChannel(1),
                              ),
                            ],
                          ],
                        ),

                        // Bottom Bar
                        Column(
                          children: [
                            if (widget.streamType != 'live') ...[
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 24),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(_formatDuration(_position), style: const TextStyle(color: Colors.white70, fontSize: 12)),
                                    Text(_formatDuration(_duration), style: const TextStyle(color: Colors.white70, fontSize: 12)),
                                  ],
                                ),
                              ),
                              SliderTheme(
                                data: SliderTheme.of(context).copyWith(
                                  activeTrackColor: const Color(0xFFE50914),
                                  inactiveTrackColor: Colors.white24,
                                  thumbColor: const Color(0xFFE50914),
                                  trackHeight: 4,
                                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                                ),
                                child: Slider(
                                  value: _position.inMilliseconds.toDouble().clamp(0.0, _duration.inMilliseconds.toDouble() > 0 ? _duration.inMilliseconds.toDouble() : 1.0),
                                  min: 0.0,
                                  max: _duration.inMilliseconds.toDouble() > 0 ? _duration.inMilliseconds.toDouble() : 1.0,
                                  onChanged: (val) {
                                    _controller?.seekTo(Duration(milliseconds: val.toInt()));
                                    _startHideControlsTimer();
                                  },
                                ),
                              ),
                            ] else ...[
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: Colors.red,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Text('LIVE STREAM (HD)', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                                  ),
                                ],
                              ),
                            ],
                            const SizedBox(height: 8),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.aspect_ratio, color: Colors.white, size: 24),
                                    tooltip: 'Aspect Ratio',
                                    onPressed: _cycleAspectRatio,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

              // OSD Quick Info Banner for Live TV Channel Switching
              if (_showOsdBanner)
                Positioned(
                  top: 24,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.85),
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(color: const Color(0xFF3B82F6), width: 2),
                      ),
                      child: Text(
                        _osdMessage,
                        style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ),

              // Persistent Floating Back Button in top-left
              Positioned(
                top: 16,
                left: 16,
                child: SafeArea(
                  child: Material(
                    color: Colors.black87,
                    borderRadius: BorderRadius.circular(30),
                    elevation: 8,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(30),
                      onTap: () => Navigator.of(context).pop(),
                      child: const Padding(
                        padding: EdgeInsets.all(10),
                        child: Icon(Icons.arrow_back, color: Colors.white, size: 24),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

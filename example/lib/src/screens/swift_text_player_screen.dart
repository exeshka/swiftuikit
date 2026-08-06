import 'dart:math' as math;

import 'package:auto_route/auto_route.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:swiftuikit/swiftuikit.dart';

const _playerTransitionDuration = Duration(milliseconds: 450);

const _tracks = <_Track>[
  _Track(
    title: 'The Lake',
    artist: 'Northern Lines',
    duration: 271,
    asset: 'assets/covers/canyon_lake.jpg',
    background: Color(0xff8c7873),
    foreground: Color(0xfff9f5f3),
  ),
  _Track(
    title: 'Midnight Peaks',
    artist: 'Blue Hour',
    duration: 238,
    asset: 'assets/covers/moonlit_peaks.jpg',
    background: Color(0xff263b62),
    foreground: Color(0xfff1f5ff),
  ),
  _Track(
    title: 'Desert Signal',
    artist: 'Mesa Observatory',
    duration: 304,
    asset: 'assets/covers/desert_signal.jpg',
    background: Color(0xff8b5b4e),
    foreground: Color(0xfffff4ed),
  ),
];

@RoutePage()
class SwiftTextPlayerScreen extends StatefulWidget {
  const SwiftTextPlayerScreen({super.key});

  @override
  State<SwiftTextPlayerScreen> createState() => _SwiftTextPlayerScreenState();
}

class _SwiftTextPlayerScreenState extends State<SwiftTextPlayerScreen> {
  var _trackIndex = 0;
  var _playing = false;
  var _favorite = false;
  var _progress = 0.31;
  var _volume = 0.72;
  var _didPrecache = false;

  _Track get _track => _tracks[_trackIndex];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didPrecache) return;
    _didPrecache = true;
    for (final track in _tracks) {
      precacheImage(AssetImage(track.asset), context);
    }
  }

  void _showTrack(int delta) {
    setState(() {
      _trackIndex = (_trackIndex + delta) % _tracks.length;
      _progress = delta > 0 ? 0.08 : 0.82;
      _favorite = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final track = _track;
    return TweenAnimationBuilder<Color?>(
      tween: ColorTween(end: track.background),
      duration: _playerTransitionDuration,
      curve: Curves.easeOutCubic,
      builder: (context, background, _) {
        final resolvedBackground = background ?? track.background;
        return Material(
          child: CupertinoPageScaffold(
            backgroundColor: Colors.transparent,
            navigationBar: CupertinoNavigationBar(
              enableBackgroundFilterBlur: false,
              middle: Text(
                'Now Playing',
                style: TextStyle(
                  color: track.foreground,
                  fontWeight: FontWeight.w600,
                ),
              ),
              backgroundColor: Colors.transparent,
              border: null,
              leading: CupertinoNavigationBarBackButton(
                color: track.foreground,
                onPressed: () => Navigator.of(context).pop(),
              ),
              trailing: CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: () {},
                child: Icon(
                  CupertinoIcons.ellipsis_circle_fill,
                  color: track.foreground.withValues(alpha: 0.82),
                ),
              ),
            ),
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    resolvedBackground,
                    Color.lerp(
                      resolvedBackground,
                      const Color(0xff08090b),
                      0.62,
                    )!,
                    const Color(0xff08090b),
                  ],
                  stops: const [0, 0.58, 1],
                ),
              ),
              child: SafeArea(
                bottom: false,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final wide = constraints.maxWidth >= 760;
                    final artworkSize = wide
                        ? (constraints.maxHeight - 110).clamp(300.0, 410.0)
                        : math.min(
                            (constraints.maxWidth - 48).clamp(220.0, 350.0),
                            (constraints.maxHeight * 0.38).clamp(240.0, 350.0),
                          );
                    final panel = _PlayerPanel(
                      track: track,
                      progress: _progress,
                      volume: _volume,
                      playing: _playing,
                      favorite: _favorite,
                      onProgressChanged: (value) {
                        setState(() => _progress = value);
                      },
                      onVolumeChanged: (value) {
                        setState(() => _volume = value);
                      },
                      onPrevious: () => _showTrack(-1),
                      onPlayPause: () {
                        setState(() => _playing = !_playing);
                      },
                      onNext: () => _showTrack(1),
                      onFavorite: () {
                        setState(() => _favorite = !_favorite);
                      },
                    );

                    return SingleChildScrollView(
                      padding: EdgeInsets.fromLTRB(
                        wide ? 42 : 24,
                        wide ? 34 : 18,
                        wide ? 42 : 24,
                        MediaQuery.paddingOf(context).bottom + 24,
                      ),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 980),
                          child: wide
                              ? Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    _Artwork(track: track, size: artworkSize),
                                    const SizedBox(width: 56),
                                    Expanded(child: panel),
                                  ],
                                )
                              : Column(
                                  children: [
                                    _Artwork(track: track, size: artworkSize),
                                    const SizedBox(height: 28),
                                    panel,
                                  ],
                                ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _PlayerPanel extends StatelessWidget {
  const _PlayerPanel({
    required this.track,
    required this.progress,
    required this.volume,
    required this.playing,
    required this.favorite,
    required this.onProgressChanged,
    required this.onVolumeChanged,
    required this.onPrevious,
    required this.onPlayPause,
    required this.onNext,
    required this.onFavorite,
  });

  final _Track track;
  final double progress;
  final double volume;
  final bool playing;
  final bool favorite;
  final ValueChanged<double> onProgressChanged;
  final ValueChanged<double> onVolumeChanged;
  final VoidCallback onPrevious;
  final VoidCallback onPlayPause;
  final VoidCallback onNext;
  final VoidCallback onFavorite;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _TrackInformation(track: track),
        const SizedBox(height: 20),
        _ProgressControl(
          track: track,
          progress: progress,
          onChanged: onProgressChanged,
        ),
        const SizedBox(height: 12),
        _PlaybackControls(
          foreground: track.foreground,
          playing: playing,
          onPrevious: onPrevious,
          onPlayPause: onPlayPause,
          onNext: onNext,
        ),
        const SizedBox(height: 22),
        _VolumeControl(
          foreground: track.foreground,
          value: volume,
          onChanged: onVolumeChanged,
        ),
      ],
    );
  }
}

class _Artwork extends StatelessWidget {
  const _Artwork({required this.track, required this.size});

  final _Track track;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: track.foreground.withValues(alpha: 0.16),
          width: 1,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x4d000000),
            blurRadius: 34,
            offset: Offset(0, 18),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: AnimatedSwitcher(
          duration: _playerTransitionDuration,
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          transitionBuilder: (child, animation) => FadeTransition(
            opacity: animation,
            child: ScaleTransition(
              scale: Tween(begin: 0.96, end: 1.0).animate(animation),
              child: child,
            ),
          ),
          child: Image.asset(
            track.asset,
            key: ValueKey(track.asset),
            width: size,
            height: size,
            fit: BoxFit.cover,
            filterQuality: FilterQuality.medium,
          ),
        ),
      ),
    );
  }
}

class _TrackInformation extends StatelessWidget {
  const _TrackInformation({required this.track});

  final _Track track;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 102,
      child: Align(
        alignment: Alignment.centerLeft,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'SWIFT TEXT  ·  LOSSLESS',
              style: TextStyle(
                color: track.foreground.withValues(alpha: 0.52),
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 7),
            SwiftText(
              track.title,
              key: const ValueKey('playerTitle'),
              duration: _playerTransitionDuration,
              style: TextStyle(
                color: track.foreground,
                fontSize: 31,
                fontWeight: FontWeight.w700,
                fontFamily: '.AppleSystemUIFontRounded',
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            SwiftText(
              track.artist,
              key: const ValueKey('playerArtist'),
              duration: _playerTransitionDuration,
              style: TextStyle(
                color: track.foreground.withValues(alpha: 0.62),
                fontSize: 19,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _ProgressControl extends StatelessWidget {
  const _ProgressControl({
    required this.track,
    required this.progress,
    required this.onChanged,
  });

  final _Track track;
  final double progress;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    final elapsed = (track.duration * progress).round();
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: CupertinoSlider(
            key: const ValueKey('playerProgress'),
            value: progress,
            activeColor: track.foreground,
            thumbColor: track.foreground,
            onChanged: onChanged,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 3),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              SwiftText(
                _time(elapsed),
                duration: _playerTransitionDuration,
                style: TextStyle(
                  color: track.foreground.withValues(alpha: 0.68),
                  fontSize: 13,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              SwiftText(
                '−${_time(track.duration - elapsed)}',
                duration: _playerTransitionDuration,
                countsDown: true,
                style: TextStyle(
                  color: track.foreground.withValues(alpha: 0.68),
                  fontSize: 13,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PlaybackControls extends StatelessWidget {
  const _PlaybackControls({
    required this.foreground,
    required this.playing,
    required this.onPrevious,
    required this.onPlayPause,
    required this.onNext,
  });

  final Color foreground;
  final bool playing;
  final VoidCallback onPrevious;
  final VoidCallback onPlayPause;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        CupertinoButton(
          key: const ValueKey('playerPrevious'),
          padding: const EdgeInsets.all(12),
          onPressed: onPrevious,
          child: Icon(
            CupertinoIcons.backward_fill,
            color: foreground,
            size: 38,
          ),
        ),
        CupertinoButton(
          key: const ValueKey('playerPlayPause'),
          padding: const EdgeInsets.all(12),
          onPressed: onPlayPause,
          child: Icon(
            playing ? CupertinoIcons.pause_fill : CupertinoIcons.play_fill,
            color: foreground,
            size: 56,
          ),
        ),
        CupertinoButton(
          key: const ValueKey('playerNext'),
          padding: const EdgeInsets.all(12),
          onPressed: onNext,
          child: Icon(CupertinoIcons.forward_fill, color: foreground, size: 38),
        ),
      ],
    );
  }
}

class _VolumeControl extends StatelessWidget {
  const _VolumeControl({
    required this.foreground,
    required this.value,
    required this.onChanged,
  });

  final Color foreground;
  final double value;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          CupertinoIcons.speaker_fill,
          color: foreground.withValues(alpha: 0.62),
          size: 16,
        ),
        Expanded(
          child: CupertinoSlider(
            key: const ValueKey('playerVolume'),
            value: value,
            activeColor: foreground.withValues(alpha: 0.9),
            thumbColor: foreground,
            onChanged: onChanged,
          ),
        ),
        Icon(
          CupertinoIcons.speaker_3_fill,
          color: foreground.withValues(alpha: 0.62),
          size: 18,
        ),
      ],
    );
  }
}

class _RoundPlayerButton extends StatelessWidget {
  const _RoundPlayerButton({
    super.key,
    required this.label,
    required this.icon,
    required this.foreground,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final Color foreground;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: CupertinoButton(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        minimumSize: const Size(64, 64),
        onPressed: onPressed,
        child: Column(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: foreground.withValues(alpha: 0.13),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Icon(icon, color: foreground, size: 21),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                color: foreground.withValues(alpha: 0.66),
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Track {
  const _Track({
    required this.title,
    required this.artist,
    required this.duration,
    required this.asset,
    required this.background,
    required this.foreground,
  });

  final String title;
  final String artist;
  final int duration;
  final String asset;
  final Color background;
  final Color foreground;
}

String _time(int seconds) {
  final minutes = seconds ~/ 60;
  final remainder = seconds % 60;
  return '$minutes:${remainder.toString().padLeft(2, '0')}';
}

import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';

class AudioPlayerHandler extends BaseAudioHandler {
  final AudioPlayer _audioPlayer = AudioPlayer();
  final List<String> _playlist = []; // Список треков
  String? _currentTrack;

  AudioPlayerHandler() {
    _audioPlayer.playerStateStream.listen((state) {
      // Обновляем уведомление при изменении состояния плеера
      _updateMediaSession();
    });
  }

  /// Воспроизведение текущего трека
  @override
  Future<void> play() async {
    if (_currentTrack != null) {
      await _audioPlayer.setFilePath(_currentTrack!);
      await _audioPlayer.play();
      _updateMediaSession();
    }
  }

  /// Пауза
  @override
  Future<void> pause() async {
    await _audioPlayer.pause();
    _updateMediaSession();
  }

  /// Остановка
  @override
  Future<void> stop() async {
    await _audioPlayer.stop();
    _updateMediaSession();
  }

  /// Переключение на следующий трек
  @override
  Future<void> skipToNext() async {
    if (_playlist.isNotEmpty) {
      int currentIndex = _playlist.indexOf(_currentTrack!);
      int nextIndex = (currentIndex + 1) % _playlist.length;
      _currentTrack = _playlist[nextIndex];
      await _audioPlayer.setFilePath(_currentTrack!);
      await _audioPlayer.play();
      _updateMediaSession();
    }
  }

  /// Переключение на предыдущий трек
  @override
  Future<void> skipToPrevious() async {
    if (_playlist.isNotEmpty) {
      int currentIndex = _playlist.indexOf(_currentTrack!);
      int previousIndex = (currentIndex - 1 + _playlist.length) % _playlist.length;
      _currentTrack = _playlist[previousIndex];
      await _audioPlayer.setFilePath(_currentTrack!);
      await _audioPlayer.play();
      _updateMediaSession();
    }
  }

  /// Обновление уведомления с текущим треком
  void _updateMediaSession() {
    mediaItem.add(MediaItem(
      id: _currentTrack ?? 'unknown',
      title: _currentTrack?.split('/').last ?? 'Unknown Track',
      artist: 'Unknown Artist',
      album: 'Unknown Album',
      duration: _audioPlayer.duration,
    ));

    playbackState.add(PlaybackState(
      controls: [
        MediaControl.skipToPrevious,
        _audioPlayer.playing ? MediaControl.pause : MediaControl.play,
        MediaControl.skipToNext,
      ],
      playing: _audioPlayer.playing,
      processingState: AudioProcessingState.ready,
      updatePosition: _audioPlayer.position,
    ));
  }
}
import 'dart:io';

import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'dart:math';
import 'audio_player_handler.dart';

void main() async {
  final audioHandler = await AudioService.init(
    builder: () => AudioPlayerHandler()
  );
  runApp(MyApp(audioHandler: audioHandler));
}

class MyApp extends StatelessWidget {
  final AudioPlayerHandler audioHandler;
  const MyApp({required this.audioHandler, super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      locale: Locale('en'),
      supportedLocales: [Locale('en', ''), Locale('ru', '')],
      localizationsDelegates: [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: MusicPlayerScreen(),
    );
  }
}

class MusicPlayerScreen extends StatefulWidget {
  const MusicPlayerScreen({super.key});

  @override
  State<MusicPlayerScreen> createState() => _MusicPlayerScreenState();
}

class _MusicPlayerScreenState extends State<MusicPlayerScreen> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  final List<String> _playlist = [];
  final List<FileData> _fileDataList = [];
  String? _currentTrack;
  bool _isPlaying = false;
  bool _isShuffle = false;
  bool _isRepeat = false;
  Duration _currentPosition = Duration.zero;
  Duration _totalDuration = Duration.zero;

  @override
  void initState() {
    super.initState();
    _audioPlayer.positionStream.listen((position) {
      setState(() {
        _currentPosition = position;
      });
    });
    _audioPlayer.durationStream.listen((duration) {
      setState(() {
        _totalDuration = duration ?? Duration.zero;
      });
    });
    _audioPlayer.playerStateStream.listen((state) {
      setState(() {
        _isPlaying = state.playing;
      });
    });
    _audioPlayer.processingStateStream.listen((state) {
      if (state == ProcessingState.completed) {
        if (_isRepeat) {
          _audioPlayer.seek(Duration.zero);
          _audioPlayer.play();
        } else if (_isShuffle) {
          _currentTrack =
              _fileDataList[Random(
                    DateTime.now().millisecond,
                  ).nextInt(_fileDataList.length)]
                  .path;
          _audioPlayer.play();
        } else {
          _playNext();
        }
      }
    });
  }

  Future<void> _pickFiles() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.custom,
      allowedExtensions: ['mp3', 'ogg', 'wav'],
    );
    if (result != null) {
      setState(() {
        _fileDataList.addAll(
          result.paths
              .map(
                (path) => FileData(
                  name: path?.split('\\').last ?? 'Unknown name',
                  path: path ?? '',
                  size: File(path ?? '').lengthSync(),
                  type: path?.split('.').last ?? 'Unknown size',
                ),
              )
              .toList(),
        );
        _playlist.addAll(result.paths.whereType<String>());
        if (_currentTrack == null && _playlist.isNotEmpty) {
          _currentTrack = _playlist.first;
        }
      });
    }
  }

  void _playPause() {
    if (_playlist.isEmpty) return;

    if (_isPlaying) {
      _audioPlayer.pause();
    } else {
      if (_currentTrack != null) {
        _audioPlayer.play();
      }
    }
  }

  void _playFile(FileData file) {
    if (_isPlaying) {
      _audioPlayer.pause();
    }

    _audioPlayer.setFilePath(file.path);
    _audioPlayer.play();
    _currentTrack = file.path;
  }

  void _playNext() {
    if (_playlist.isNotEmpty) {
      int currentIndex = _playlist.indexOf(_currentTrack!);
      int nextIndex;
      if (_isShuffle) {
        nextIndex = Random().nextInt(_playlist.length);
      } else {
        nextIndex = (currentIndex + 1) % _playlist.length;
      }
      setState(() {
        _currentTrack = _playlist[nextIndex];
      });
      _audioPlayer.setFilePath(_currentTrack!).then((_) => _audioPlayer.play());
    }
  }

  void _playPrevious() {
    if (_playlist.isNotEmpty) {
      int currentIndex = _playlist.indexOf(_currentTrack!);
      int nextIndex;
      if (_isShuffle) {
        nextIndex = Random().nextInt(_playlist.length);
      } else {
        nextIndex = (currentIndex - 1) % _playlist.length;
      }
      setState(() {
        _currentTrack = _playlist[nextIndex];
      });
      _audioPlayer.setFilePath(_currentTrack!).then((_) => _audioPlayer.play());
    }
  }

  @override
  Widget build(BuildContext context) {
    var localization = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(localization?.musicPlayer ?? "Music Player")),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            _currentTrack != null
                ? _currentTrack!.split('\\').last
                : localization?.noTrackSelected ?? "No track selected",
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '${_currentPosition.inMinutes.toString()}:${_currentPosition.inSeconds % 60}'
              ),
              Slider(
                min: 0,
                max: _totalDuration.inSeconds.toDouble(),
                value: _currentPosition.inSeconds.toDouble(),
                onChanged: (value) {
                  _audioPlayer.seek(Duration(seconds: value.toInt()));
                },
              ),
              Text(
                '${_totalDuration.inMinutes.toString()}:${_totalDuration.inSeconds % 60}'
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: Icon(
                  Icons.shuffle,
                  color: _isShuffle ? Colors.blue : Colors.grey,
                ),
                onPressed: () {
                  setState(() {
                    _isShuffle = !_isShuffle;
                  });
                },
              ),
              IconButton(icon: Icon(Icons.skip_previous), onPressed: _playPrevious),
              IconButton(
                icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow),
                onPressed: _playPause,
              ),
              IconButton(icon: Icon(Icons.skip_next), onPressed: _playNext),
              IconButton(
                icon: Icon(
                  Icons.repeat,
                  color: _isRepeat ? Colors.blue : Colors.grey,
                ),
                onPressed: () {
                  setState(() {
                    _isRepeat = !_isRepeat;
                  });
                },
              ),
            ],
          ),
          ElevatedButton(
            onPressed: _pickFiles,
            child: Text(localization?.pickAudioFiles ?? "Pick Audio Files"),
          ),
          Expanded(
            child: ListView(
              children: [
                // Шапка таблицы
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: Text(
                          'Название',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                          textAlign: TextAlign.left,
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          'Размер',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                          textAlign: TextAlign.right,
                        ),
                      ),
                      Expanded(
                        flex: 1,
                        child: Text(
                          'Тип',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),
                // Список файлов
                ..._fileDataList.map((file) {
                  return GestureDetector(
                    onDoubleTap: () => _playFile(file),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      child: Card(
                        elevation: 3,
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Row(
                            children: [
                              // Колонка с названием файла
                              Expanded(
                                flex: 3,
                                child: Text(
                                  file.name,
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                  overflow: TextOverflow.ellipsis,
                                  textAlign:
                                      TextAlign
                                          .left, // выравнивание по левому краю
                                ),
                              ),
                              // Колонка с размером файла
                              Expanded(
                                flex: 2,
                                child: Text(
                                  '${(file.size / (1024 * 1024)).toStringAsFixed(2)} MB',
                                  textAlign:
                                      TextAlign
                                          .right, // выравнивание по правому краю
                                ),
                              ),
                              // Колонка с типом файла
                              Expanded(
                                flex: 1,
                                child: Text(
                                  file.type,
                                  textAlign:
                                      TextAlign
                                          .center, // выравнивание по центру
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }
}

class FileData {
  final String name;
  final String path;
  final int size;
  final String type;

  FileData({
    required this.name,
    required this.path,
    required this.size,
    required this.type,
  });
}

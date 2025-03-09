import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:file_picker/file_picker.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Music Player',
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      themeMode: ThemeMode.system,
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
  bool _isPlaying = false;
  String _audioFilePath = '';

  @override
  void dispose() {
    super.dispose();
    _audioPlayer.dispose();
  }

  Future<void> _pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.audio);

    if (result != null) {
      setState(() {
        _audioFilePath = result.files.single.path!;
      });
    }
  }

  void _playPauseAudio() {
    if (_isPlaying) {
      _audioPlayer.pause();
    } else {
      if (_audioFilePath.isNotEmpty) {
        _audioPlayer.play(DeviceFileSource(_audioFilePath));
      }
    }
    setState(() {
      _isPlaying = !_isPlaying;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Music Player'),
        actions: [
          IconButton(
            icon: Icon(Icons.folder_open),
            onPressed: _pickFile,
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            _audioFilePath.isEmpty
                ? Text('No file selected')
                : Text(
                    'Selected File: ${_audioFilePath.split('/').last}',
                    style: TextStyle(fontSize: 16),
                  ),
            SizedBox(height: 20),
            IconButton(
              icon: Icon(
                _isPlaying ? Icons.pause : Icons.play_arrow,
                size: 100,
                color: Colors.blue,
              ),
              onPressed: _playPauseAudio,
            ),
            SizedBox(height: 20),
            Text(
              _isPlaying ? 'Now Playing' : 'Tap to Play',
              style: TextStyle(fontSize: 24),
            ),
          ],
        ),
      ),
    );
  }
}

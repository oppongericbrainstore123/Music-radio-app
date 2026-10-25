import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

void main() {
  runApp(const MusicRadioApp());
}

class MusicRadioApp extends StatelessWidget {
  const MusicRadioApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Music & Radio',
      theme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.deepPurple,
        scaffoldBackgroundColor: const Color(0xFF121212),
      ),
      home: const PlayerScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class PlayerScreen extends StatefulWidget {
  const PlayerScreen({super.key});

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  late AudioPlayer _audioPlayer;
  bool _isPlaying = false;
  String _currentTitle = 'Select a Stream to Play';

  // Sample live radio stream URL (Public domain classical / test stream)
  final String sampleStreamUrl = 'https://stream.zeno.fm/f3wvbbqmdg8uv';

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _togglePlay() async {
    try {
      if (_isPlaying) {
        await _audioPlayer.pause();
        setState(() {
          _isPlaying = false;
        });
      } else {
        await _audioPlayer.setUrl(sampleStreamUrl);
        await _audioPlayer.play();
        setState(() {
          _isPlaying = true;
          _currentTitle = 'Live Global Radio Stream';
        });
      }
    } catch (e) {
      setState(() {
        _currentTitle = 'Error playing stream';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Music & Radio Hub'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.radio, size: 100, color: Colors.deepPurpleAccent),
              const SizedBox(height: 30),
              Text(
                _currentTitle,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                _isPlaying ? 'Streaming Live...' : 'Ready to Play',
                style: TextStyle(color: Colors.grey[400], fontSize: 14),
              ),
              const SizedBox(height: 50),
              CircleAvatar(
                radius: 40,
                backgroundColor: Colors.deepPurpleAccent,
                child: IconButton(
                  icon: Icon(
                    _isPlaying ? Icons.pause : Icons.play_arrow,
                    size: 40,
                    color: Colors.white,
                  ),
                  onPressed: _togglePlay,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

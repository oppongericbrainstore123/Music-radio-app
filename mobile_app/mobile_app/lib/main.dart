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
  String _currentTitle = 'Global Radio Hub';
  String _statusText = 'Ready to Play';

  final String sampleStreamUrl = 'https://stream.live.vc.bbcmedia.co.uk/bbc_world_service';

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
          _statusText = 'Paused';
        });
      } else {
        setState(() {
          _statusText = 'Connecting to stream...';
        });
        await _audioPlayer.setUrl(sampleStreamUrl);
        await _audioPlayer.play();
        setState(() {
          _isPlaying = true;
          _statusText = 'Streaming Live';
        });
      }
    } catch (e) {
      setState(() {
        _isPlaying = false;
        _statusText = 'Failed to connect. Check internet.';
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
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                _statusText,
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

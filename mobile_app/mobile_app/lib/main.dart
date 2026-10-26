import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:just_audio/just_audio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';

void main() {
  runApp(const MusicRadioApp());
}

List<Map<String, String>> globalFavorites = [];
List<Map<String, String>> downloadedSongs = [];

class MusicRadioApp extends StatelessWidget {
  const MusicRadioApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Music & Radio Hub',
      theme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.deepPurple,
        scaffoldBackgroundColor: const Color(0xFF121212),
      ),
      home: const MainContainer(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class MainContainer extends StatefulWidget {
  const MainContainer({super.key});

  @override
  State<MainContainer> createState() => _MainContainerState();
}

class _MainContainerState extends State<MainContainer> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    CountrySelectionScreen(),
    OnlineMusicScreen(),
    FavoritesScreen(),
    LocalMusicScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: Colors.deepPurpleAccent,
        unselectedItemColor: Colors.grey,
        backgroundColor: Colors.black54,
        type: BottomNavigationBarType.fixed,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.radio), label: 'Radio'),
          BottomNavigationBarItem(icon: Icon(Icons.cloud_download), label: 'Stream/Download'),
          BottomNavigationBarItem(icon: Icon(Icons.favorite), label: 'Favorites'),
          BottomNavigationBarItem(icon: Icon(Icons.folder_audio), label: 'Local'),
        ],
      ),
    );
  }
}

// 1. Country Selection Screen (Radio)
class CountrySelectionScreen extends StatelessWidget {
  const CountrySelectionScreen({super.key});

  final List<Map<String, String>> countries = const [
    {'name': 'United States', 'code': 'US'},
    {'name': 'United Kingdom', 'code': 'GB'},
    {'name': 'Ghana', 'code': 'GH'},
    {'name': 'Nigeria', 'code': 'NG'},
    {'name': 'Canada', 'code': 'CA'},
    {'name': 'South Africa', 'code': 'ZA'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Global Radio Hub'), backgroundColor: Colors.transparent),
      body: ListView.builder(
        itemCount: countries.length,
        itemBuilder: (context, index) {
          final country = countries[index];
          return ListTile(
            leading: const Icon(Icons.public, color: Colors.deepPurpleAccent),
            title: Text(country['name']!),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => StationListScreen(
                    countryName: country['name']!,
                    countryCode: country['code']!,
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class StationListScreen extends StatefulWidget {
  final String countryName;
  final String countryCode;

  const StationListScreen({super.key, required this.countryName, required this.countryCode});

  @override
  State<StationListScreen> createState() => _StationListScreenState();
}

class _StationListScreenState extends State<StationListScreen> {
  List<dynamic> stations = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchStations();
  }

  Future<void> fetchStations() async {
    try {
      final response = await http.get(Uri.parse('https://de1.api.radio-browser.info/json/stations/bycountrycodeexact/${widget.countryCode}'));
      if (response.statusCode == 200) {
        setState(() {
          stations = json.decode(response.body);
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('${widget.countryName} Stations'), backgroundColor: Colors.transparent),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: stations.length,
              itemBuilder: (context, index) {
                final station = stations[index];
                final name = station['name'] ?? 'Unknown';
                final url = station['url_resolved'] ?? station['url'] ?? '';
                return ListTile(
                  leading: const Icon(Icons.radio, color: Colors.deepPurpleAccent),
                  title: Text(name, maxLines: 1, overflow: TextOverflow.ellipsis),
                  trailing: const Icon(Icons.play_circle_fill, color: Colors.deepPurpleAccent),
                  onTap: () {
                    if (url.isNotEmpty) {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => PlayerScreen(title: name, audioUrl: url)));
                    }
                  },
                );
              },
            ),
    );
  }
}

// 2. Online Music & Download Screen
class OnlineMusicScreen extends StatefulWidget {
  const OnlineMusicScreen({super.key});

  @override
  State<OnlineMusicScreen> createState() => _OnlineMusicScreenState();
}

class _OnlineMusicScreenState extends State<OnlineMusicScreen> {
  // Sample royalty-free public domain tracks for online streaming and downloading
  final List<Map<String, String>> sampleTracks = [
    {
      'title': 'Acoustic Breeze (Sample)',
      'url': 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3'
    },
    {
      'title': 'Creative Minds (Sample)',
      'url': 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-2.mp3'
    },
    {
      'title': 'Straight (Sample)',
      'url': 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-3.mp3'
    },
  ];

  bool isDownloading = false;
  String downloadStatus = '';

  Future<void> _downloadSong(String title, String url) async {
    setState(() {
      isDownloading = true;
      downloadStatus = 'Downloading $title...';
    });

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final directory = await getApplicationDocumentsDirectory();
        final file = File('${directory.path}/${title.replaceAll(' ', '_')}.mp3');
        await file.writeAsBytes(response.bodyBytes);

        setState(() {
          downloadedSongs.add({'title': title, 'path': file.path});
          isDownloading = false;
          downloadStatus = 'Successfully downloaded to device storage!';
        });
      } else {
        setState(() {
          isDownloading = false;
          downloadStatus = 'Download failed.';
        });
      }
    } catch (e) {
      setState(() {
        isDownloading = false;
        downloadStatus = 'Error downloading file.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Stream & Download Music'), backgroundColor: Colors.transparent),
      body: Column(
        children: [
          if (downloadStatus.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(downloadStatus, style: const TextStyle(color: Colors.greenAccent)),
            ),
          Expanded(
            child: ListView.builder(
              itemCount: sampleTracks.length,
              itemBuilder: (context, index) {
                final track = sampleTracks[index];
                return ListTile(
                  leading: const Icon(Icons.music_note, color: Colors.deepPurpleAccent),
                  title: Text(track['title']!),
                  subtitle: const Text('Online Stream / Offline Ready', style: TextStyle(color: Colors.grey, fontSize: 12)),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.download, color: Colors.blueAccent),
                        onPressed: isDownloading ? null : () => _downloadSong(track['title']!, track['url']!),
                      ),
                      IconButton(
                        icon: const Icon(Icons.play_arrow, color: Colors.deepPurpleAccent),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => PlayerScreen(title: track['title']!, audioUrl: track['url']!),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// 3. Favorites Tab Screen
class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Favorites'), backgroundColor: Colors.transparent),
      body: globalFavorites.isEmpty
          ? const Center(child: Text('No favorites saved yet.', style: TextStyle(color: Colors.grey)))
          : ListView.builder(
              itemCount: globalFavorites.length,
              itemBuilder: (context, index) {
                final fav = globalFavorites[index];
                return ListTile(
                  leading: const Icon(Icons.favorite, color: Colors.redAccent),
                  title: Text(fav['name']!),
                  trailing: const Icon(Icons.play_circle_fill, color: Colors.deepPurpleAccent),
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => PlayerScreen(title: fav['name']!, audioUrl: fav['url']!)));
                  },
                );
              },
            ),
    );
  }
}

// 4. Local & Downloaded Music Storage Tab
class LocalMusicScreen extends StatefulWidget {
  const LocalMusicScreen({super.key});

  @override
  State<LocalMusicScreen> createState() => _LocalMusicScreenState();
}

class _LocalMusicScreenState extends State<LocalMusicScreen> {
  Future<void> _pickAudioFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.audio);
    if (result != null && result.files.single.path != null) {
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PlayerScreen(
            title: result.files.single.name,
            audioUrl: result.files.single.path!,
            isLocalFile: true,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Device Storage Music'),
        backgroundColor: Colors.transparent,
        actions: [
          IconButton(
            icon: const Icon(Icons.folder_open),
            onPressed: _pickAudioFile,
            tooltip: 'Pick File from Device',
          ),
        ],
      ),
      body: downloadedSongs.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.download_done, size: 80, color: Colors.grey),
                    const SizedBox(height: 16),
                    const Text('No downloaded songs yet.\nGo to "Stream/Download" tab to save songs offline!', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurpleAccent),
                      icon: const Icon(Icons.folder_open, color: Colors.white),
                      label: const Text('Browse Phone Files', style: TextStyle(color: Colors.white)),
                      onPressed: _pickAudioFile,
                    ),
                  ],
                ),
              ),
            )
          : ListView.builder(
              itemCount: downloadedSongs.length,
              itemBuilder: (context, index) {
                final song = downloadedSongs[index];
                return ListTile(
                  leading: const Icon(Icons.offline_pin, color: Colors.greenAccent),
                  title: Text(song['title']!),
                  subtitle: const Text('Saved to device storage', style: TextStyle(fontSize: 12, color: Colors.grey)),
                  trailing: const Icon(Icons.play_circle_fill, color: Colors.deepPurpleAccent),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PlayerScreen(
                          title: song['title']!,
                          audioUrl: song['path']!,
                          isLocalFile: true,
                        ),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}

// 5. Universal Audio Player Screen
class PlayerScreen extends StatefulWidget {
  final String title;
  final String audioUrl;
  final bool isLocalFile;

  const PlayerScreen({super.key, required this.title, required this.audioUrl, this.isLocalFile = false});

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  late AudioPlayer _audioPlayer;
  bool _isPlaying = false;
  String _statusText = 'Loading...';

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
    _initPlayer();
  }

  Future<void> _initPlayer() async {
    try {
      if (widget.isLocalFile) {
        await _audioPlayer.setFilePath(widget.audioUrl);
      } else {
        await _audioPlayer.setUrl(widget.audioUrl);
      }
      await _audioPlayer.play();
      setState(() {
        _isPlaying = true;
        _statusText = widget.isLocalFile ? 'Playing Offline File' : 'Streaming Online';
      });
    } catch (e) {
      setState(() => _statusText = 'Playback Error');
    }
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _togglePlay() async {
    if (_isPlaying) {
      await _audioPlayer.pause();
      setState(() {
        _isPlaying = false;
        _statusText = 'Paused';
      });
    } else {
      await _audioPlayer.play();
      setState(() {
        _isPlaying = true;
        _statusText = widget.isLocalFile ? 'Playing Offline File' : 'Streaming Online';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Now Playing'), backgroundColor: Colors.transparent),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(widget.isLocalFile ? Icons.offline_pin : Icons.music_note, size: 100, color: Colors.deepPurpleAccent),
              const SizedBox(height: 30),
              Text(widget.title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
              const SizedBox(height: 10),
              Text(_statusText, style: TextStyle(color: Colors.grey[400], fontSize: 14)),
              const SizedBox(height: 50),
              CircleAvatar(
                radius: 40,
                backgroundColor: Colors.deepPurpleAccent,
                child: IconButton(
                  icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow, size: 40, color: Colors.white),
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

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:just_audio/just_audio.dart';
import 'package:file_picker/file_picker.dart';

void main() {
  runApp(const MusicRadioApp());
}

// Global state for favorites across the app
List<Map<String, String>> globalFavorites = [];

class MusicRadioApp extends StatelessWidget {
  const MusicRadioApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Global Radio & Music Hub',
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

// Main Container with Bottom Navigation Bar
class MainContainer extends StatefulWidget {
  const MainContainer({super.key});

  @override
  State<MainContainer> createState() => _MainContainerState();
}

class _MainContainerState extends State<MainContainer> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    CountrySelectionScreen(),
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
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.radio),
            label: 'Radio',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite),
            label: 'Favorites',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.folder_audio),
            label: 'Local Music',
          ),
        ],
      ),
    );
  }
}

// 1. Country Selection Screen
class CountrySelectionScreen extends StatelessWidget {
  const CountrySelectionScreen({super.key});

  final List<Map<String, String>> countries = const [
    {'name': 'United States', 'code': 'US'},
    {'name': 'United Kingdom', 'code': 'GB'},
    {'name': 'Ghana', 'code': 'GH'},
    {'name': 'Nigeria', 'code': 'NG'},
    {'name': 'Canada', 'code': 'CA'},
    {'name': 'Germany', 'code': 'DE'},
    {'name': 'France', 'code': 'FR'},
    {'name': 'South Africa', 'code': 'ZA'},
    {'name': 'Australia', 'code': 'AU'},
    {'name': 'Brazil', 'code': 'BR'},
    {'name': 'India', 'code': 'IN'},
    {'name': 'Japan', 'code': 'JP'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Explore Global Radio'),
        backgroundColor: Colors.transparent,
      ),
      body: ListView.builder(
        itemCount: countries.length,
        itemBuilder: (context, index) {
          final country = countries[index];
          return ListTile(
            leading: const Icon(Icons.public, color: Colors.deepPurpleAccent),
            title: Text(country['name']!, style: const TextStyle(fontSize: 18)),
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

// 2. Station List & Search Screen
class StationListScreen extends StatefulWidget {
  final String countryName;
  final String countryCode;

  const StationListScreen({
    super.key,
    required this.countryName,
    required this.countryCode,
  });

  @override
  State<StationListScreen> createState() => _StationListScreenState();
}

class _StationListScreenState extends State<StationListScreen> {
  List<dynamic> stations = [];
  List<dynamic> filteredStations = [];
  bool isLoading = true;
  TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchStations();
  }

  Future<void> fetchStations() async {
    try {
      final url = Uri.parse(
        'https://de1.api.radio-browser.info/json/stations/bycountrycodeexact/${widget.countryCode}',
      );
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          stations = data;
          filteredStations = data;
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
    }
  }

  void filterStations(String query) {
    setState(() {
      filteredStations = stations
          .where((station) =>
              station['name'].toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  bool _isFavorite(String name) {
    return globalFavorites.any((fav) => fav['name'] == name);
  }

  void _toggleFavorite(Map<String, dynamic> station) {
    final name = station['name'] ?? 'Unknown';
    final url = station['url_resolved'] ?? station['url'] ?? '';
    setState(() {
      if (_isFavorite(name)) {
        globalFavorites.removeWhere((fav) => fav['name'] == name);
      } else {
        globalFavorites.add({'name': name, 'url': url});
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.countryName} Stations'),
        backgroundColor: Colors.transparent,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              controller: searchController,
              onChanged: filterStations,
              decoration: InputDecoration(
                hintText: 'Search FM station...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.grey[850],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredStations.isEmpty
                    ? const Center(child: Text('No stations found'))
                    : ListView.builder(
                        itemCount: filteredStations.length,
                        itemBuilder: (context, index) {
                          final station = filteredStations[index];
                          final stationName = station['name'] ?? 'Unknown Station';
                          final streamUrl = station['url_resolved'] ?? station['url'] ?? '';
                          final isFav = _isFavorite(stationName);

                          return ListTile(
                            leading: const Icon(Icons.radio, color: Colors.deepPurpleAccent),
                            title: Text(stationName, maxLines: 1, overflow: TextOverflow.ellipsis),
                            subtitle: Text(station['codec'] ?? 'Live FM', style: TextStyle(color: Colors.grey[400])),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: Icon(
                                    isFav ? Icons.favorite : Icons.favorite_border,
                                    color: isFav ? Colors.redAccent : Colors.grey,
                                  ),
                                  onPressed: () => _toggleFavorite(station),
                                ),
                                const Icon(Icons.play_circle_fill, color: Colors.deepPurpleAccent, size: 28),
                              ],
                            ),
                            onTap: () {
                              if (streamUrl.isNotEmpty) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => PlayerScreen(
                                      title: stationName,
                                      audioUrl: streamUrl,
                                    ),
                                  ),
                                );
                              }
                            },
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
class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Favorite Stations'),
        backgroundColor: Colors.transparent,
      ),
      body: globalFavorites.isEmpty
          ? const Center(
              child: Text(
                'No favorite stations saved yet.\nTap the heart icon on any station!',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
            )
          : ListView.builder(
              itemCount: globalFavorites.length,
              itemBuilder: (context, index) {
                final fav = globalFavorites[index];
                return ListTile(
                  leading: const Icon(Icons.favorite, color: Colors.redAccent),
                  title: Text(fav['name']!),
                  trailing: const Icon(Icons.play_circle_fill, color: Colors.deepPurpleAccent, size: 28),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PlayerScreen(
                          title: fav['name']!,
                          audioUrl: fav['url']!,
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

// 4. Local Music Tab Screen (Device File Picker)
class LocalMusicScreen extends StatefulWidget {
  const LocalMusicScreen({super.key});

  @override
  State<LocalMusicScreen> createState() => _LocalMusicScreenState();
}

class _LocalMusicScreenState extends State<LocalMusicScreen> {
  String? filePath;
  String fileName = 'No file selected';

  Future<void> _pickAudioFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.audio,
      );

      if (result != null && result.files.single.path != null) {
        setState(() {
          filePath = result.files.single.path;
          fileName = result.files.single.name;
        });

        if (!mounted) return;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PlayerScreen(
              title: fileName,
              audioUrl: filePath!,
              isLocalFile: true,
            ),
          ),
        );
      }
    } catch (e) {
      setState(() {
        fileName = 'Error picking file';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Local Device Music'),
        backgroundColor: Colors.transparent,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.library_music, size: 100, color: Colors.deepPurpleAccent),
              const SizedBox(height: 30),
              const Text(
                'Play Music From Your Phone Storage',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 15),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurpleAccent,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.folder_open, color: Colors.white),
                label: const Text('Select Audio File', style: TextStyle(fontSize: 16, color: Colors.white)),
                onPressed: _pickAudioFile,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// 5. Universal Audio Player Screen
class PlayerScreen extends StatefulWidget {
  final String title;
  final String audioUrl;
  final bool isLocalFile;

  const PlayerScreen({
    super.key,
    required this.title,
    required this.audioUrl,
    this.isLocalFile = false,
  });

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  late AudioPlayer _audioPlayer;
  bool _isPlaying = false;
  String _statusText = 'Connecting...';

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
    _startPlaying();
  }

  Future<void> _startPlaying() async {
    try {
      if (widget.isLocalFile) {
        await _audioPlayer.setFilePath(widget.audioUrl);
      } else {
        await _audioPlayer.setUrl(widget.audioUrl);
      }
      await _audioPlayer.play();
      setState(() {
        _isPlaying = true;
        _statusText = widget.isLocalFile ? 'Playing Local File' : 'Live Streaming';
      });
    } catch (e) {
      setState(() {
        _statusText = 'Failed to play audio';
      });
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
        _statusText = widget.isLocalFile ? 'Playing Local File' : 'Live Streaming';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Now Playing'),
        backgroundColor: Colors.transparent,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                widget.isLocalFile ? Icons.music_note : Icons.radio,
                size: 100,
                color: Colors.deepPurpleAccent,
              ),
              const SizedBox(height: 30),
              Text(
                widget.title,
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

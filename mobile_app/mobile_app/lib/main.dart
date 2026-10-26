import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:just_audio/just_audio.dart';

void main() {
  runApp(const MusicRadioApp());
}

class MusicRadioApp extends StatelessWidget {
  const MusicRadioApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Global Radio Hub',
      theme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.deepPurple,
        scaffoldBackgroundColor: const Color(0xFF121212),
      ),
      home: const CountrySelectionScreen(),
      debugShowCheckedModeBanner: false,
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
        title: const Text('Select Country'),
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
                          final favicon = station['favicon'] ?? '';

                          return ListTile(
                            leading: favicon.isNotEmpty
                                ? Image.network(
                                    favicon,
                                    width: 40,
                                    height: 40,
                                    errorBuilder: (context, error, stackTrace) =>
                                        const Icon(Icons.radio, color: Colors.deepPurpleAccent),
                                  )
                                : const Icon(Icons.radio, color: Colors.deepPurpleAccent),
                            title: Text(stationName, maxLines: 1, overflow: TextOverflow.ellipsis),
                            subtitle: Text(station['codec'] ?? 'Live FM', style: TextStyle(color: Colors.grey[400])),
                            trailing: const Icon(Icons.play_circle_fill, color: Colors.deepPurpleAccent, size: 32),
                            onTap: () {
                              if (streamUrl.isNotEmpty) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => PlayerScreen(
                                      stationName: stationName,
                                      streamUrl: streamUrl,
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

// 3. Audio Player Screen
class PlayerScreen extends StatefulWidget {
  final String stationName;
  final String streamUrl;

  const PlayerScreen({
    super.key,
    required this.stationName,
    required this.streamUrl,
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
      await _audioPlayer.setUrl(widget.streamUrl);
      await _audioPlayer.play();
      setState(() {
        _isPlaying = true;
        _statusText = 'Live Streaming';
      });
    } catch (e) {
      setState(() {
        _statusText = 'Failed to stream station';
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
        _statusText = 'Live Streaming';
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
              const Icon(Icons.radio, size: 100, color: Colors.deepPurpleAccent),
              const SizedBox(height: 30),
              Text(
                widget.stationName,
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

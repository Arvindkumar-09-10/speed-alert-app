import 'dart:async';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';

final AudioPlayer _audioPlayer = AudioPlayer();

Future<void> playSpeedAlert({String? customAudioPath}) async {
  if (!kIsWeb) {
    await _audioPlayer.setAudioContext(
      AudioContext(
        android: const AudioContextAndroid(
          stayAwake: true,
          contentType: AndroidContentType.music,
          usageType: AndroidUsageType.alarm,
          audioFocus: AndroidAudioFocus.gainTransientMayDuck,
        ),
        iOS: AudioContextIOS(
          category: AVAudioSessionCategory.playback,
          options: {
            AVAudioSessionOptions.mixWithOthers,
            AVAudioSessionOptions.duckOthers,
          },
        ),
      ),
    );
  }

  if (customAudioPath != null && !kIsWeb && File(customAudioPath).existsSync()) {
    await _audioPlayer.play(DeviceFileSource(customAudioPath));
  } else {
    await _audioPlayer.play(AssetSource('alert.mp3'));
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const SpeedAlertApp());
}

class SpeedAlertApp extends StatelessWidget {
  const SpeedAlertApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Speed Alert',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0066FF),
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFF8FAFC),
      ),
      home: const SpeedHomeScreen(),
    );
  }
}

class SpeedHomeScreen extends StatefulWidget {
  const SpeedHomeScreen({super.key});

  @override
  State<SpeedHomeScreen> createState() => _SpeedHomeScreenState();
}

class _SpeedHomeScreenState extends State<SpeedHomeScreen> {
  double _currentSpeed = 0.0;
  double _speedLimit = 60.0;
  bool _isExceeding = false;

  String? _customAudioPath;
  String _audioFileName = "Default Alert Sound";

  StreamSubscription<Position>? _positionStream;
  bool _isAudioPlaying = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _setupAudioListener();
    _requestPermissionsAndStartTracking();
  }

  void _setupAudioListener() {
    _audioPlayer.onPlayerComplete.listen((_) {
      _isAudioPlaying = false;
    });
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _speedLimit = prefs.getDouble('speed_limit') ?? 60.0;
      _customAudioPath = prefs.getString('custom_audio_path');
      if (_customAudioPath != null && _customAudioPath!.isNotEmpty) {
        _audioFileName = _customAudioPath!.split('/').last;
      }
    });
  }

  Future<void> _requestPermissionsAndStartTracking() async {
    if (!kIsWeb) {
      await [
        Permission.locationWhenInUse,
        Permission.locationAlways,
        Permission.notification,
      ].request();
    }

    LocationPermission locPermission = await Geolocator.checkPermission();
    if (locPermission == LocationPermission.denied) {
      locPermission = await Geolocator.requestPermission();
    }

    if (locPermission == LocationPermission.whileInUse ||
        locPermission == LocationPermission.always) {
      _startLocationTracking();
    }
  }

  void _startLocationTracking() {
    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 1,
    );

    _positionStream = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen((Position position) {
      double currentSpeed = (position.speed * 3.6).clamp(0.0, 300.0);
      double speedLimit = _speedLimit;

      setState(() {
        _currentSpeed = currentSpeed;
        _isExceeding = _currentSpeed > speedLimit;
      });

      if (currentSpeed > speedLimit) {
        _triggerAudioAlert();
      }
    });
  }

  Future<void> _triggerAudioAlert() async {
    if (_isAudioPlaying) return;
    _isAudioPlaying = true;

    try {
      await playSpeedAlert(customAudioPath: _customAudioPath);
    } catch (e) {
      debugPrint("Error playing audio: $e");
      _isAudioPlaying = false;
    }
  }

  Future<void> _pickAudioFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['mp3', 'wav', 'm4a', 'aac'],
    );

    if (result != null && result.files.single.path != null) {
      String filePath = result.files.single.path!;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('custom_audio_path', filePath);

      setState(() {
        _customAudioPath = filePath;
        _audioFileName = result.files.single.name;
      });

      _triggerAudioAlert();
    }
  }

  Future<void> _resetToDefaultAudio() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('custom_audio_path');

    setState(() {
      _customAudioPath = null;
      _audioFileName = "Default Alert Sound";
    });
  }

  Future<void> _updateSpeedLimit(double val) async {
    setState(() {
      _speedLimit = val;
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('speed_limit', val);
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Speed Monitor', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                flex: 3,
                child: Container(
                  decoration: BoxDecoration(
                    color: _isExceeding ? const Color(0xFFFFEBEE) : Colors.white,
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(
                      color: _isExceeding ? Colors.red : Colors.grey.shade200,
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: _isExceeding
                            ? Colors.red.withValues(alpha: 0.15)
                            : Colors.black.withValues(alpha: 0.04),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _isExceeding ? Icons.warning_rounded : Icons.speed_rounded,
                        size: 48,
                        color: _isExceeding ? Colors.red : const Color(0xFF0066FF),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _currentSpeed.toStringAsFixed(0),
                        style: TextStyle(
                          fontSize: 88,
                          fontWeight: FontWeight.w900,
                          color: _isExceeding ? Colors.red : const Color(0xFF1E293B),
                          height: 1.0,
                        ),
                      ),
                      const Text(
                        'KM/H',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF64748B),
                          letterSpacing: 2.0,
                        ),
                      ),
                      if (_isExceeding) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            'SPEED LIMIT EXCEEDED',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Speed Limit',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                        Text(
                          '${_speedLimit.round()} km/h',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0066FF),
                          ),
                        ),
                      ],
                    ),
                    Slider(
                      value: _speedLimit,
                      min: 10,
                      max: 150,
                      divisions: 28,
                      activeColor: const Color(0xFF0066FF),
                      onChanged: _updateSpeedLimit,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Alert Tone',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const Icon(Icons.music_note_rounded, color: Color(0xFF0066FF)),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _audioFileName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF475569),
                            ),
                          ),
                        ),
                        if (_customAudioPath != null)
                          IconButton(
                            icon: const Icon(Icons.close_rounded, color: Colors.grey),
                            onPressed: _resetToDefaultAudio,
                            tooltip: 'Reset to Default',
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: _pickAudioFile,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0066FF),
                        foregroundColor: Colors.white,
                        minimumSize: const Size.fromHeight(48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: const Text('Select Alert Sound'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
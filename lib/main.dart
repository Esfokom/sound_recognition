import 'package:flutter/material.dart';
import 'package:flutter_sound_record/flutter_sound_record.dart';
import 'package:dio/dio.dart';
import 'dart:async';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final FlutterSoundRecord _recorder = FlutterSoundRecord();
  bool _isRecording = false;
  Timer? _timer;
  int _recordDuration = 0;
  String? _filePath;

  @override
  void initState() {
    super.initState();
    // _recorder.initialize();
  }

  @override
  void dispose() {
    _recorder.dispose();
    _timer?.cancel();
    super.dispose();
  }

  void _startRecording() async {
    if (await _recorder.hasPermission()) {
      await _recorder.start(
          path: 'audio_record.aac', encoder: AudioEncoder.AAC);
      setState(() {
        _isRecording = true;
        _recordDuration = 0;
      });

      _timer = Timer.periodic(Duration(seconds: 1), (timer) {
        setState(() {
          _recordDuration++;
        });

        if (_recordDuration >= 30) {
          _stopRecording();
        }
      });
    }
  }

  void _stopRecording() async {
    _timer?.cancel();
    _filePath = await _recorder.stop();
    setState(() {
      _isRecording = false;
    });

    if (_filePath != null) {
      _sendRequest(_filePath!);
    }
  }

  Future<void> _sendRequest(String filePath) async {
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(child: CircularProgressIndicator()),
    );

    try {
      FormData formData = FormData.fromMap({
        'api_token': '46a8037177a39df68be2be2b43ec015397c',
        'file': await MultipartFile.fromFile(filePath,
            filename: 'audio_record.wav'),
      });

      var response = await Dio().post('https://api.audd.io/', data: formData);
      Navigator.of(context).pop(); // Close loading dialog

      if (response.statusCode == 200) {
        _showResultDialog(response.data);
      } else {
        _showRetryDialog();
      }
    } catch (e) {
      Navigator.of(context).pop(); // Close loading dialog
      _showRetryDialog();
    }
  }

  void _showResultDialog(dynamic data) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Song Recognized'),
          content: Text(
              'Song: ${data['result']['title']} by ${data['result']['artist']}'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void _showRetryDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Error'),
          content:
              Text('Failed to recognize the song. Would you like to retry?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Retry'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Music Recognizer'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: _isRecording ? null : _startRecording,
              child: Text('Start Recording'),
            ),
            ElevatedButton(
              onPressed: _isRecording ? _stopRecording : null,
              child: Text('Stop Recording'),
            ),
          ],
        ),
      ),
    );
  }
}

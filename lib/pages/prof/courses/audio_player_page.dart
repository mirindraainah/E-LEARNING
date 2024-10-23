import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

class AudioPlayerPage extends StatefulWidget {
  final String audioUrl;

  const AudioPlayerPage({Key? key, required this.audioUrl}) : super(key: key);

  @override
  _AudioPlayerPageState createState() => _AudioPlayerPageState();
}

class _AudioPlayerPageState extends State<AudioPlayerPage> {
  late AudioPlayer _audioPlayer;
  bool _loading = true;
  String? _error;

  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  Future<void> _initializePlayer() async {
    try {
      _audioPlayer = AudioPlayer();
      await _audioPlayer.setUrl(widget.audioUrl);
      _audioPlayer.durationStream.listen((duration) {
        setState(() {
          _duration = duration ?? Duration.zero;
        });
      });
      _audioPlayer.positionStream.listen((position) {
        setState(() {
          _position = position;
        });
      });
      setState(() {
        _loading = false;
      });
    } catch (error) {
      setState(() {
        _error = 'Erreur lors du chargement de l\'audio: $error';
        _loading = false;
      });
    }
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Lecteur Audio'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: _loading
              ? CircularProgressIndicator()
              : _error != null
                  ? Text(
                      _error!,
                      style: TextStyle(color: Colors.red),
                      textAlign: TextAlign.center,
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Position: ${_position.toString().split('.').first} / ${_duration.toString().split('.').first}',
                          style: TextStyle(fontSize: 16),
                        ),
                        StreamBuilder<PlayerState>(
                          stream: _audioPlayer.playerStateStream,
                          builder: (context, snapshot) {
                            final playerState = snapshot.data;
                            final isPlaying = playerState?.playing ?? false;
                            return IconButton(
                              icon: Icon(
                                  isPlaying ? Icons.pause : Icons.play_arrow),
                              iconSize: 64.0,
                              onPressed: () {
                                if (isPlaying) {
                                  _audioPlayer.pause();
                                } else {
                                  _audioPlayer.play();
                                }
                              },
                            );
                          },
                        ),
                        Slider(
                          value: _position.inSeconds.toDouble(),
                          min: 0.0,
                          max: _duration.inSeconds.toDouble(),
                          onChanged: (value) {
                            final newPosition =
                                Duration(seconds: value.toInt());
                            _audioPlayer.seek(newPosition);
                          },
                        ),
                      ],
                    ),
        ),
      ),
    );
  }
}

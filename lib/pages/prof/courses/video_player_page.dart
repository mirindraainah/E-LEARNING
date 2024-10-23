// import 'package:flutter/material.dart';
// import 'package:video_player/video_player.dart';

// class VideoPlayerPage extends StatefulWidget {
//   final String videoUrl;

//   const VideoPlayerPage({Key? key, required this.videoUrl}) : super(key: key);

//   @override
//   _VideoPlayerPageState createState() => _VideoPlayerPageState();
// }

// class _VideoPlayerPageState extends State<VideoPlayerPage> {
//   late VideoPlayerController _controller;
//   late Future<void> _initializeVideoPlayerFuture;

//   @override
//   void initState() {
//     super.initState();

//     _controller = VideoPlayerController.network(widget.videoUrl);

//     _initializeVideoPlayerFuture = _controller.initialize().then((_) {
//       setState(() {}); // Rebuild the widget when the video is initialized
//       _controller.play(); // Auto-play the video
//     });
//   }

//   @override
//   void dispose() {
//     _controller.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('Lecture Vidéo'),
//       ),
//       body: Center(
//         child: FutureBuilder<void>(
//           future: _initializeVideoPlayerFuture,
//           builder: (context, snapshot) {
//             if (snapshot.connectionState == ConnectionState.done) {
//               return AspectRatio(
//                 aspectRatio: _controller.value.aspectRatio,
//                 child: VideoPlayer(_controller),
//               );
//             } else if (snapshot.hasError) {
//               return Text('Erreur lors de la lecture de la vidéo');
//             } else {
//               return CircularProgressIndicator();
//             }
//           },
//         ),
//       ),
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';

class VideoPlayerPage extends StatefulWidget {
  final String videoUrl;

  const VideoPlayerPage({Key? key, required this.videoUrl}) : super(key: key);

  @override
  _VideoPlayerPageState createState() => _VideoPlayerPageState();
}

class _VideoPlayerPageState extends State<VideoPlayerPage> {
  late VideoPlayerController _videoPlayerController;
  late ChewieController _chewieController;

  @override
  void initState() {
    super.initState();

    _videoPlayerController = VideoPlayerController.network(widget.videoUrl);

    _chewieController = ChewieController(
      videoPlayerController: _videoPlayerController,
      autoPlay: true,
      looping: true,
      showControls: true,
      // aspectRatio: _videoPlayerController
      //     .value.aspectRatio, //  format d'origine
      // placeholder:
      //     Container(color: Colors.black), // couleur arrière-plan par défaut
    );

    _videoPlayerController.initialize().then((_) {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _chewieController.dispose();
    _videoPlayerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Lecture Vidéo'),
      ),
      body: Center(
        child: Chewie(
          controller: _chewieController,
        ),
      ),
    );
  }
}



// import 'package:flutter/material.dart';
// import 'package:better_player/better_player.dart';

// class VideoPlayerPage extends StatefulWidget {
//   final String videoUrl;

//   const VideoPlayerPage({Key? key, required this.videoUrl}) : super(key: key);

//   @override
//   _VideoPlayerPageState createState() => _VideoPlayerPageState();
// }

// class _VideoPlayerPageState extends State<VideoPlayerPage> {
//   late BetterPlayerController _controller;

//   @override
//   void initState() {
//     super.initState();

//     final betterPlayerConfiguration = BetterPlayerConfiguration(
//       aspectRatio: 16 / 9,
//       autoPlay: true,
//       looping: true,
//       controlsConfiguration: BetterPlayerControlsConfiguration(
//         enablePlayPause: true,
//         enableProgressText: true,
//         enableProgressBar: true,
//         // enablePlayBackSpeed: true,
//         enableMute: true,
//         // enableBrightness: true,
//         enableFullscreen: true,
//         enablePip: true,
//         enablePlaybackSpeed: true,
//         enableSubtitles: true,
//       ),
//     );

//     _controller = BetterPlayerController(
//       betterPlayerConfiguration,
//       betterPlayerDataSource: BetterPlayerDataSource.network(widget.videoUrl),
//     );
//   }

//   @override
//   void dispose() {
//     _controller.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('Lecture Vidéo'),
//       ),
//       body: Center(
//         child: BetterPlayer(
//           controller: _controller,
//         ),
//       ),
//     );
//   }
// }

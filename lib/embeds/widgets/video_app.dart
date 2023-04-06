import 'dart:io';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';

import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';

/// Widget for playing back video
/// Refer to https://github.com/flutter/plugins/tree/master/packages/video_player/video_player
class VideoApp extends StatefulWidget {
  const VideoApp({
    required this.videoUrl,
    required this.context,
    required this.readOnly,
    this.onVideoInit,
  });

  final String videoUrl;
  final BuildContext context;
  final bool readOnly;
  final void Function(GlobalKey videoContainerKey)? onVideoInit;

  @override
  _VideoAppState createState() => _VideoAppState();
}

class _VideoAppState extends State<VideoApp> {
  late VideoPlayerController _controller;
  GlobalKey videoContainerKey = GlobalKey();
  bool hilightVideo = false;
  double videoDragScale = 1;
  double dragStart = 0;
  double previousStableVal = 1;
  @override
  void initState() {
    super.initState();

    _controller = widget.videoUrl.startsWith('http')
        ? VideoPlayerController.network(widget.videoUrl)
        : VideoPlayerController.file(File(widget.videoUrl))
      ..initialize().then((_) {
        // Ensure the first frame is shown after the video is initialized,
        // even before the play button has been pressed.
        setState(() {});
        if (widget.onVideoInit != null) {
          widget.onVideoInit?.call(videoContainerKey);
        }
      }).catchError((error) {
        setState(() {});
      });
  }

  @override
  Widget build(BuildContext context) {
    final defaultStyles = DefaultStyles.getInstance(context);
    if (_controller.value.hasError) {
      if (widget.readOnly) {
        return RichText(
          text: TextSpan(
              text: widget.videoUrl,
              style: defaultStyles.link,
              recognizer: TapGestureRecognizer()
                ..onTap = () => launchUrl(Uri.parse(widget.videoUrl))),
        );
      }

      return RichText(
          text: TextSpan(text: widget.videoUrl, style: defaultStyles.link));
    } else if (!_controller.value.isInitialized) {
      return VideoProgressIndicator(
        _controller,
        allowScrubbing: true,
        colors: const VideoProgressColors(playedColor: Colors.blue),
      );
    }

    return Stack(
      children: [
        Container(
          width: MediaQuery.of(context).size.width * videoDragScale,
          margin: const EdgeInsets.all(8),
          decoration: hilightVideo
              ? BoxDecoration(
                  border:
                      Border.all(color: const Color(0xff0090FF), width: 1.2),
                )
              : null,
          key: videoContainerKey,
          // height: 300,
          child: InkWell(
            onTap: () {
              FocusManager.instance.primaryFocus?.unfocus();

              setState(() {
                _controller.pause();
                hilightVideo = true;
              });
            },
            child: Stack(alignment: Alignment.center, children: [
              Center(
                  child: AspectRatio(
                aspectRatio: _controller.value.aspectRatio,
                child: VideoPlayer(_controller),
              )),
              InkWell(
                onTap: () {
                  FocusManager.instance.primaryFocus?.unfocus();

                  setState(() {
                    hilightVideo = false;
                    ;
                    if (_controller.value.isPlaying) {
                      _controller.pause();
                    } else {
                      _controller.play();
                    }
                  });
                },
                child: Opacity(
                  opacity: _controller.value.isPlaying ? 0 : 1,
                  child: Container(
                      color: const Color(0xfff5f5f5),
                      child: const Icon(
                        Icons.play_arrow,
                        size: 60,
                        color: Colors.blueGrey,
                      )),
                ),
              ),
              hilightVideo
                  ? Positioned(
                      bottom: 0,
                      left: 0,
                      child: Transform.translate(
                        offset: const Offset(-2.5, 2.5),
                        child: Container(
                          height: 5,
                          width: 5,
                          color: const Color(0xff0090FF),
                        ),
                      ),
                    )
                  : const SizedBox(),
              hilightVideo
                  ? Positioned(
                      top: 0,
                      left: 0,
                      child: Transform.translate(
                        offset: const Offset(-2.5, -2.5),
                        child: Container(
                          height: 5,
                          width: 5,
                          color: const Color(0xff0090FF),
                        ),
                      ),
                    )
                  : const SizedBox(),
              hilightVideo
                  ? Positioned(
                      top: 0,
                      right: 0,
                      child: Transform.translate(
                        offset: const Offset(2.5, -2.5),
                        child: Container(
                          height: 5,
                          width: 5,
                          color: const Color(0xff0090FF),
                        ),
                      ),
                    )
                  : const SizedBox(),
              hilightVideo
                  ? Positioned(
                      bottom: 0,
                      right: 0,
                      child: GestureDetector(
                        onHorizontalDragUpdate: (val) {
                          if (dragStart == 0) {
                            dragStart = val.globalPosition.dx;
                          }
                          final diff = val.globalPosition.dx - dragStart;

                          setState(() {
                            videoDragScale = previousStableVal +
                                (diff / MediaQuery.of(context).size.width);
                          });
                        },
                        onHorizontalDragEnd: (_) {
                          dragStart = 0;
                          previousStableVal = videoDragScale;
                        },
                        child: Container(
                          height: 50,
                          width: 50,
                          color: Colors.red.withOpacity(0),
                          child: Stack(
                            alignment: Alignment.bottomRight,
                            children: [
                              Transform.translate(
                                offset: const Offset(8, 6),
                                child: Container(
                                  height: 24,
                                  width: 24,
                                  decoration: BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          offset: const Offset(0, 4),
                                          blurRadius: 4,
                                          color: const Color(0xff000000)
                                              .withOpacity(0.25),
                                        )
                                      ]),
                                  child: Transform.scale(
                                      scale: 0.7,
                                      child: const Icon(Icons.zoom_out_map)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                  : const SizedBox(),
            ]),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    super.dispose();
    _controller.dispose();
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'dart:io' show Platform;
import '../utils/youtube_helper.dart';
import 'package:url_launcher/url_launcher.dart';

class YouTubePlayerWidget extends StatelessWidget {
  final String videoUrl;

  const YouTubePlayerWidget({
    Key? key,
    required this.videoUrl,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final videoId = YouTubeHelper.getVideoId(videoUrl);
    if (videoId == null) {
      return const Text('Invalid YouTube URL');
    }

    return GestureDetector(
      onTap: () => _launchYouTubeVideo(videoId),
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                Image.network(
                  YouTubeHelper.getThumbnailUrl(videoId),
                  width: double.infinity,
                  height: 180,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return SizedBox(
                      height: 180,
                      child: Center(
                        child: Platform.isIOS 
                          ? const CupertinoActivityIndicator() 
                          : const CircularProgressIndicator(),
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      height: 180,
                      color: Colors.grey[300],
                      child: Center(
                        child: Icon(
                          Platform.isIOS 
                            ? CupertinoIcons.exclamationmark_circle 
                            : Icons.error,
                          color: Colors.red,
                        ),
                      ),
                    );
                  },
                ),
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: Icon(
                    Platform.isIOS 
                      ? CupertinoIcons.play_fill 
                      : Icons.play_arrow,
                    color: Colors.white,
                    size: 30,
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                'YouTube Video',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Platform.isIOS 
                    ? CupertinoColors.black 
                    : Colors.black,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _launchYouTubeVideo(String videoId) async {
    final Uri url = Uri.parse(YouTubeHelper.getWatchUrl(videoId));
    try {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } catch (e) {
      print('Error launching YouTube video: $e');
    }
  }
}
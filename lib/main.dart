import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:video_player/video_player.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:developer';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData.dark(),
      home: const FreckStories(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class FreckStories extends StatefulWidget {
  const FreckStories({super.key});

  @override
  State<FreckStories> createState() => FreckStoriesState();
}

class FreckStoriesState extends State<FreckStories> {
  List<List<dynamic>> userStories = [];
  List<String> userNames = [];
  List<String> userAvatars = [];
  int _currentIndex = 0;
  int _selectedUser = 0;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchUsersAndStories();
  }

  String convertToSnakeCase(String input) {
    String lowerCased = input.toLowerCase();
    String snakeCased = lowerCased.replaceAll(' ', '_');

    return snakeCased;
  }

  Future<void> fetchUsersAndStories() async {
    try {
      final pexelsImagesResponse = await http.get(
        Uri.parse('https://api.pexels.com/v1/curated?per_page=21'),
        headers: {
          'Authorization':
              'NspYStjO3L8tZqPL2kCHPjhhSDWLyFLXELBFjD6lAUdpkSZe5PWaC5di',
        },
      );

      final pexelsVideosResponse = await http.get(
        Uri.parse('https://api.pexels.com/videos/popular?per_page=14'),
        headers: {
          'Authorization':
              'NspYStjO3L8tZqPL2kCHPjhhSDWLyFLXELBFjD6lAUdpkSZe5PWaC5di',
        },
      );

      final usersResponse = await http
          .get(Uri.parse('https://randomuser.me/api/?results=7&nat=in'));

      if (pexelsImagesResponse.statusCode == 200 &&
          pexelsVideosResponse.statusCode == 200 &&
          usersResponse.statusCode == 200) {
        List imagesData = json.decode(pexelsImagesResponse.body)['photos'];
        List videosData = json.decode(pexelsVideosResponse.body)['videos'];
        log("Videos: ${videosData.first['video_files'][0]['link']}");

        List usersData = json.decode(usersResponse.body)['results'];

        setState(() {
          for (int i = 0; i < 7; i++) {
            userStories.add([
              ...imagesData
                  .skip(i * 3)
                  .take(3)
                  .map((item) => item['src']['original']),
              ...videosData
                  .skip(i * 2)
                  .take(2)
                  .map((item) => item['video_files'][0]['link'])
            ]..shuffle());
          }

          userNames = usersData.map<String>((user) {
            return "${user['name']['first']} ${user['name']['last']}";
          }).toList();

          userAvatars = usersData.map<String>((user) {
            return user['picture']['large'];
          }).toList();

          isLoading = false;
        });
      } else {
        throw Exception('Failed to load images, videos, or user data');
      }
    } catch (e) {
      log("Error: $e");
      setState(() {
        isLoading = false;
      });
    }
  }

  void _onTapDown(TapDownDetails details, int totalStories) {
    final screenWidth = MediaQuery.of(context).size.width;
    final dx = details.globalPosition.dx;

    if (dx < screenWidth / 2) {
      setState(() {
        _currentIndex = _currentIndex > 0 ? _currentIndex - 1 : _currentIndex;
      });
    } else {
      setState(() {
        _currentIndex = _currentIndex < totalStories - 1
            ? _currentIndex + 1
            : _currentIndex;
      });
    }
  }

  void closeStory() {
    setState(() {
      _selectedUser = 0;
      _currentIndex = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : userStories.isNotEmpty
              ? Stack(
                  children: [
                    GestureDetector(
                      onTapDown: (details) => _onTapDown(
                          details, userStories[_selectedUser].length),
                      child: userStories[_selectedUser][_currentIndex]
                              .contains('images')
                          ? CachedNetworkImage(
                              imageUrl: userStories[_selectedUser]
                                  [_currentIndex],
                              placeholder: (context, url) => const Center(
                                  child: CircularProgressIndicator()),
                              errorWidget: (context, url, error) =>
                                  const Icon(Icons.error),
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: double.infinity,
                            )
                          : VideoPlayerWidget(
                              url: userStories[_selectedUser][_currentIndex]),
                    ),
                    Positioned(
                      top: 40.0,
                      left: 20.0,
                      right: 20.0,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: userStories[_selectedUser]
                            .asMap()
                            .entries
                            .map((entry) {
                          return Expanded(
                            child: Container(
                              margin:
                                  const EdgeInsets.symmetric(horizontal: 2.0),
                              height: 3.0,
                              decoration: BoxDecoration(
                                color: _currentIndex == entry.key
                                    ? Colors.white
                                    : Colors.white.withOpacity(0.7),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    Positioned(
                      top: 60.0,
                      left: 20.0,
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 20,
                            backgroundImage: CachedNetworkImageProvider(
                                userAvatars[_selectedUser]),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            convertToSnakeCase(userNames[_selectedUser]),
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                    Positioned(
                      top: 60.0,
                      right: 20.0,
                      child: GestureDetector(
                        onTap: closeStory,
                        child: const Icon(Icons.close,
                            color: Colors.white, size: 30),
                      ),
                    ),
                    Positioned(
                      bottom: 20.0,
                      left: 0,
                      right: 0,
                      child: SizedBox(
                        height: 100.0,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: userStories.length,
                          itemBuilder: (context, index) {
                            return GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectedUser = index;
                                  _currentIndex = 0;
                                });
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                margin: const EdgeInsets.symmetric(
                                    horizontal: 10.0),
                                child: Column(
                                  children: [
                                    CircleAvatar(
                                      radius: _selectedUser == index ? 35 : 30,
                                      backgroundImage:
                                          CachedNetworkImageProvider(
                                              userAvatars[index]),
                                    ),
                                    const SizedBox(height: 5),
                                    Text(
                                      convertToSnakeCase(userNames[index]),
                                      style:
                                          const TextStyle(color: Colors.white),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                )
              : const Center(child: Text('Failed to load content')),
    );
  }
}

class VideoPlayerWidget extends StatefulWidget {
  final String url;

  const VideoPlayerWidget({super.key, required this.url});

  @override
  State<VideoPlayerWidget> createState() => VideoPlayerWidgetState();
}

class VideoPlayerWidgetState extends State<VideoPlayerWidget> {
  late VideoPlayerController _controller;

  @override
  void initState() {
    super.initState();
    log("URL: ${widget.url}");
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.url))
      ..initialize().then((_) {
        setState(() {});
        log("playing....");
        _controller.play();
      }).catchError((error) {
        log("Video initialization failed: $error");
        setState(() {});
      });

    _controller.addListener(() {
      if (_controller.value.isInitialized) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _controller.value.isInitialized
        ? Center(
            child: AspectRatio(
              aspectRatio: _controller.value.aspectRatio,
              child: VideoPlayer(_controller),
            ),
          )
        // Stack(
        //     children: [
        //       AspectRatio(
        //         aspectRatio: _controller.value.aspectRatio,
        //         child: VideoPlayer(_controller),
        //       ),
        //       // Positioned(
        //       //   bottom: 0,
        //       //   left: 0,
        //       //   right: 0,
        //       //   child: LinearProgressIndicator(
        //       //     value: _controller.value.position.inMilliseconds.toDouble() /
        //       //         _controller.value.duration.inMilliseconds.toDouble(),
        //       //     backgroundColor: Colors.black.withOpacity(0.5),
        //       //     valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
        //       //   ),
        //       // ),
        //     ],
        //   )
        : const Center(child: CircularProgressIndicator());
  }
}

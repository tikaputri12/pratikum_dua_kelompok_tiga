import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mime/mime.dart';
import 'package:video_player/video_player.dart';

class MyAppImage extends StatefulWidget {
  const MyAppImage({Key? key, this.title}) : super(key: key);

  final String? title;

  @override
  State<MyAppImage> createState() => _ImagePickerPageState();
}

class _ImagePickerPageState extends State<MyAppImage> {
  List<XFile>? _mediaFileList;
  final ImagePicker _picker = ImagePicker();

  VideoPlayerController? _controller;
  VideoPlayerController? _toBeDisposed;

  Future<void> _pickImage() async {
    final List<XFile> images = await _picker.pickMultiImage();
    setState(() {
      _mediaFileList = images;
    });
  }

  Future<void> _pickVideo() async {
    final XFile? pickedFile =
        await _picker.pickVideo(source: ImageSource.camera);

    if (pickedFile != null) {
      _playVideo(pickedFile);
    }
  }

  void _playVideo(XFile file) {
    _controller = VideoPlayerController.file(File(file.path))
      ..initialize().then((_) {
        setState(() {});
        _controller!.play();
      });
  }

  Widget _previewImages() {
    if (_mediaFileList != null && _mediaFileList!.isNotEmpty) {
      return Padding(
        padding: const EdgeInsets.all(12),
        child: GridView.builder(
          itemCount: _mediaFileList!.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
          ),
          itemBuilder: (BuildContext context, int index) {
            final String? mime =
                lookupMimeType(_mediaFileList![index].path);

            return Card(
              elevation: 5,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: kIsWeb
                    ? Image.network(
                        _mediaFileList![index].path,
                        fit: BoxFit.cover,
                      )
                    : (mime == null || mime.startsWith('image/')
                        ? Image.file(
                            File(_mediaFileList![index].path),
                            fit: BoxFit.cover,
                          )
                        : _buildInlineVideoPlayer(index)),
              ),
            );
          },
        ),
      );
    } else {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(
            Icons.image_outlined,
            size: 120,
            color: Colors.grey,
          ),
          SizedBox(height: 20),
          Text(
            'Belum ada gambar dipilih',
            style: TextStyle(fontSize: 18, color: Colors.grey),
          ),
        ],
      );
    }
  }

  Widget _buildInlineVideoPlayer(int index) {
    final VideoPlayerController controller =
        VideoPlayerController.file(File(_mediaFileList![index].path));
    controller.initialize();

    return AspectRatio(
      aspectRatio: controller.value.aspectRatio,
      child: VideoPlayer(controller),
    );
  }

  @override
  void dispose() {
    _controller?.dispose();
    _toBeDisposed?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title ?? "Image Picker"),
        centerTitle: true,
        elevation: 4,
        backgroundColor: Colors.deepPurple,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xffEDE7F6),
              Color(0xffD1C4E9),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: _previewImages(),
        ),
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            backgroundColor: Colors.deepPurple,
            heroTag: "image",
            onPressed: _pickImage,
            child: const Icon(Icons.image),
          ),
          const SizedBox(height: 15),
          FloatingActionButton(
            backgroundColor: Colors.redAccent,
            heroTag: "video",
            onPressed: _pickVideo,
            child: const Icon(Icons.videocam),
          ),
        ],
      ),
    );
  }
}
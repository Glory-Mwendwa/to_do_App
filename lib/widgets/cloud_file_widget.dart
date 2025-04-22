import 'dart:developer';
import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:mime/mime.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:to_do/models/task_model.dart';
import 'package:to_do/theme/styles.dart'; // Import mime package

class CloudFileWidget extends StatefulWidget {
  /// A widget that represents a file in the cloud.
  /// This widget is used to display a file in the cloud.
  final File cloudFile;
  final TaskItem task;
  const CloudFileWidget({super.key, required this.cloudFile, required this.task});

  @override
  State<CloudFileWidget> createState() => _CloudFileWidgetState();
}

class _CloudFileWidgetState extends State<CloudFileWidget> {
  /// The file to be downloaded.
  // late File file = File(widget.cloudFile.path); // Remove this - local path determined later
  String? _localFilePath;
  bool _isDownloading = false;
  bool _isDownloaded = false;
  double? _downloadProgress;
  DownloadTask? _downloadTask;

  @override
  void initState() {
    super.initState();
    _checkIfFileExists();
  }

  Future<String> get _localPath async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }

  Future<File> _localFile(String fileName) async {
    final path = await _localPath;
    return File('$path/$fileName');
  }

  Future<void> _checkIfFileExists() async {
    final fileName = widget.cloudFile.path.split("/").last;
    final file = await _localFile(fileName);
    if (await file.exists()) {
      setState(() {
        _isDownloaded = true;
        _localFilePath = file.path;
      });
    }
  }

  Future<void> _openFile() async {
    if (_localFilePath != null) {
      final result = await OpenFile.open(_localFilePath!);
      log("OpenFile result: ${result.message}");
      if (result.type != ResultType.done) {
        // Handle error opening file (e.g., show a SnackBar)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open file: ${result.message}')),
        );
      }
    }
  }

  Future<void> downloadFile() async {
    if (_isDownloading) return; // Prevent multiple downloads

    setState(() {
      _isDownloading = true;
      _downloadProgress = 0.0; // Start progress at 0
    });

    final storageRef = FirebaseStorage.instanceFor(bucket: "gs://smokeless-todo.firebasestorage.app").ref();
    final fileName = widget.cloudFile.path.split("/").last;
    final cloudFileRef = storageRef.child("tasks/${widget.task.id}/$fileName");
    final file = await _localFile(fileName); // Get the local file reference

    log("Cloud path: ${cloudFileRef.fullPath}");
    log("Local file path: ${file.path}");

    try {
      // String dlUrl = await cloudFileRef.getDownloadURL(); // Not strictly needed for downloadToFile
      // log("Download url: $dlUrl");

      _downloadTask = cloudFileRef.writeToFile(file);
      _downloadTask?.snapshotEvents.listen((taskSnapshot) {
        if (!mounted) return; // Check if widget is still in the tree

        switch (taskSnapshot.state) {
          case TaskState.running:
            setState(() {
              _downloadProgress = taskSnapshot.bytesTransferred / taskSnapshot.totalBytes;
            });
            log("Downloading $fileName: ${(_downloadProgress! * 100).toStringAsFixed(1)}%");
            break;
          case TaskState.paused:
            log("Paused downloading $fileName");
            // Optionally handle pause state UI
            break;
          case TaskState.success:
            log("Downloaded $fileName");
            setState(() {
              _isDownloading = false;
              _isDownloaded = true;
              _localFilePath = file.path;
              _downloadProgress = null; // Reset progress
            });
            break;
          case TaskState.canceled:
            log("Canceled downloading $fileName");
            setState(() {
              _isDownloading = false;
              _downloadProgress = null;
            });
            break;
          case TaskState.error:
            log("Error downloading $fileName");
            setState(() {
              _isDownloading = false;
              _downloadProgress = null;
            });
            // Show error message
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error downloading $fileName')),
            );
            break;
        }
      });
    } catch (e) {
      log("Error starting download for $fileName: $e");
      if (mounted) {
        setState(() {
          _isDownloading = false;
          _downloadProgress = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error downloading $fileName: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _downloadTask?.cancel(); // Cancel download if widget is disposed
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fileName = widget.cloudFile.path.split("/").last;
    return Container(
      margin: const EdgeInsets.only(bottom: 5, top: 5),
      decoration: BoxDecoration(
        border: Border.all(
          color: const Color.fromARGB(255, 41, 35, 35),
          width: 1,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: InkWell(
        onTap: () {
          if (_isDownloaded) {
            log("Tapped on downloaded file: $fileName");
            _openFile();
          } else if (!_isDownloading) {
            log("Tapped to download: $fileName");
            downloadFile();
          }
        },
        child: Stack(
          alignment: Alignment.center, // Center stack children
          children: [
            // Background container showing filename (optional styling)
            Container(
              height: 100,
              alignment: Alignment(-0.9, 0.9),
              child: Text(
                fileName,
                style: $styles.text.labelLarge.copyWith(
                  color: Colors.black,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            // Overlay container
            Container(
              height: 100,
              decoration: BoxDecoration(
                color: _isDownloaded
                    ? Colors.black.withValues(alpha: 0.3) // Less opaque when downloaded
                    : Colors.black.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            // Conditional Content (Download/Progress/Open)
            SizedBox(
              // Use SizedBox to constrain the Center content
              height: 100,
              child: Center(
                child: _buildStatusWidget(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper widget to build the status display
  Widget _buildStatusWidget() {
    if (_isDownloading) {
      return Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            CircularProgressIndicator.adaptive(
              value: _downloadProgress, // Shows determinate progress
              backgroundColor: Colors.white24,
            ),
            const SizedBox(height: 8),
            Text(
              _downloadProgress != null ? "${(_downloadProgress! * 100).toStringAsFixed(0)}%" : "Downloading...",
              style: $styles.text.bodySmall.copyWith(color: Colors.white),
            ),
          ],
        ),
      );
    } else if (_isDownloaded && _localFilePath != null) {
      final mimeType = lookupMimeType(_localFilePath!);
      final isImage = mimeType?.startsWith('image/') ?? false;

      if (isImage) {
        // Show image preview
        return ClipRRect(
          // Clip the image to the rounded corners
          borderRadius: BorderRadius.circular(8),
          child: Image.file(
            File(_localFilePath!),
            fit: BoxFit.cover, // Cover the container space
            width: double.infinity, // Take full width
            height: double.infinity, // Take full height
            errorBuilder: (context, error, stackTrace) {
              // Fallback if image fails to load
              log("Error loading image preview: $error");
              return _buildOpenFileIcon(); // Show default open icon on error
            },
          ),
        );
      } else {
        // Show default "Open File" icon for non-images
        return _buildOpenFileIcon();
      }
    } else {
      // Initial state: Show download button
      return _buildDownloadIcon();
    }
  }

  // Extracted widget for the "Open File" icon/text
  Widget _buildOpenFileIcon() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(
          MdiIcons.fileCheck, // Icon indicating downloaded/ready
          size: 50,
          color: Colors.white,
        ),
        const SizedBox(height: 8),
        Text(
          "Open File",
          style: $styles.text.titleSmall.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }

  // Extracted widget for the "Download" icon/text
  Widget _buildDownloadIcon() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(
          MdiIcons.cloudDownload,
          size: 50,
          color: Colors.white70,
        ),
        const SizedBox(height: 8),
        Text(
          "Download",
          style: $styles.text.titleSmall.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

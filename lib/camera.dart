// Copyright 2013 The Flutter Authors
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:video_player/video_player.dart';

// ─── Design Tokens ──────────────────────────────────────────────────────────
const _bgDark = Color(0xFF0A0A0F);
const _bgCard = Color(0xFF13131A);
const _bgSurface = Color(0xFF1C1C26);
const _accent = Color(0xFF00E5FF);
const _accentWarm = Color(0xFFFF6B35);
const _accentRed = Color(0xFFFF3B5C);
const _textPrimary = Color(0xFFF0F0F5);
const _textSecondary = Color(0xFF8888AA);
const _borderColor = Color(0xFF2A2A3A);

/// Camera example home widget.
class CameraExampleHome extends StatefulWidget {
  /// Default Constructor
  const CameraExampleHome({super.key});

  @override
  State<CameraExampleHome> createState() {
    return _CameraExampleHomeState();
  }
}

/// Returns a suitable camera icon for [direction].
IconData getCameraLensIcon(CameraLensDirection direction) {
  switch (direction) {
    case CameraLensDirection.back:
      return Icons.camera_rear_rounded;
    case CameraLensDirection.front:
      return Icons.camera_front_rounded;
    case CameraLensDirection.external:
      return Icons.camera_rounded;
  }
  // ignore: dead_code
  return Icons.camera_rounded;
}

void _logError(String code, String? message) {
  // ignore: avoid_print
  print('Error: $code${message == null ? '' : '\nError Message: $message'}');
}

class _CameraExampleHomeState extends State<CameraExampleHome>
    with WidgetsBindingObserver, TickerProviderStateMixin {
  CameraController? controller;
  XFile? imageFile;
  XFile? videoFile;
  VideoPlayerController? videoController;
  VoidCallback? videoPlayerListener;
  bool enableAudio = true;
  double _minAvailableExposureOffset = 0.0;
  double _maxAvailableExposureOffset = 0.0;
  double _currentExposureOffset = 0.0;
  late final AnimationController _flashModeControlRowAnimationController;
  late final CurvedAnimation _flashModeControlRowAnimation;
  late final AnimationController _exposureModeControlRowAnimationController;
  late final CurvedAnimation _exposureModeControlRowAnimation;
  late final AnimationController _focusModeControlRowAnimationController;
  late final CurvedAnimation _focusModeControlRowAnimation;
  double _minAvailableZoom = 1.0;
  double _maxAvailableZoom = 1.0;
  double _currentScale = 1.0;
  double _baseScale = 1.0;

  int _pointers = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _flashModeControlRowAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _flashModeControlRowAnimation = CurvedAnimation(
      parent: _flashModeControlRowAnimationController,
      curve: Curves.easeInCubic,
    );
    _exposureModeControlRowAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _exposureModeControlRowAnimation = CurvedAnimation(
      parent: _exposureModeControlRowAnimationController,
      curve: Curves.easeInCubic,
    );
    _focusModeControlRowAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _focusModeControlRowAnimation = CurvedAnimation(
      parent: _focusModeControlRowAnimationController,
      curve: Curves.easeInCubic,
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _flashModeControlRowAnimationController.dispose();
    _flashModeControlRowAnimation.dispose();
    _exposureModeControlRowAnimationController.dispose();
    _exposureModeControlRowAnimation.dispose();
    _focusModeControlRowAnimationController.dispose();
    _focusModeControlRowAnimation.dispose();
    super.dispose();
  }

  // #docregion AppLifecycle
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final CameraController? cameraController = controller;

    if (cameraController == null || !cameraController.value.isInitialized) {
      return;
    }

    if (state == AppLifecycleState.inactive) {
      cameraController.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initializeCameraController(cameraController.description);
    }
  }
  // #enddocregion AppLifecycle

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgDark,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: _accent,
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: _accent.withOpacity(0.6), blurRadius: 8)],
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              'LENS',
              style: TextStyle(
                color: _textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w700,
                letterSpacing: 4,
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Icon(Icons.more_horiz_rounded, color: _textSecondary),
          ),
        ],
      ),
      body: Column(
        children: <Widget>[
          // ── Camera Viewfinder ────────────────────────────────────────────
          Expanded(
            child: Stack(
              children: [
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.black,
                    border: Border.all(
                      color: controller != null && controller!.value.isRecordingVideo
                          ? _accentRed
                          : _borderColor,
                      width: 1.5,
                    ),
                  ),
                  child: _cameraPreviewWidget(),
                ),
                // Corner decorations
                if (controller != null && controller!.value.isInitialized) ...[
                  _buildCorner(Alignment.topLeft, true, true),
                  _buildCorner(Alignment.topRight, true, false),
                  _buildCorner(Alignment.bottomLeft, false, true),
                  _buildCorner(Alignment.bottomRight, false, false),
                ],
                // Recording indicator
                if (controller != null && controller!.value.isRecordingVideo)
                  Positioned(
                    top: 56,
                    right: 16,
                    child: _RecordingBadge(),
                  ),
              ],
            ),
          ),

          // ── Bottom Controls ──────────────────────────────────────────────
          Container(
            color: _bgDark,
            child: Column(
              children: [
                _modeControlRowWidget(),
                const SizedBox(height: 4),
                _captureControlRowWidget(),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                  child: Row(
                    children: [_cameraTogglesRowWidget(), _thumbnailWidget()],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCorner(Alignment alignment, bool isTop, bool isLeft) {
    return Positioned(
      top: isTop ? 8 : null,
      bottom: !isTop ? 8 : null,
      left: isLeft ? 8 : null,
      right: !isLeft ? 8 : null,
      child: SizedBox(
        width: 20,
        height: 20,
        child: CustomPaint(
          painter: _CornerPainter(isTop: isTop, isLeft: isLeft),
        ),
      ),
    );
  }

  /// Display the preview from the camera (or a message if the preview is not available).
  Widget _cameraPreviewWidget() {
    final CameraController? cameraController = controller;

    if (cameraController == null || !cameraController.value.isInitialized) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: _bgSurface,
                shape: BoxShape.circle,
                border: Border.all(color: _borderColor),
              ),
              child: const Icon(Icons.camera_alt_rounded, color: _textSecondary, size: 40),
            ),
            const SizedBox(height: 16),
            const Text(
              'Select a camera to begin',
              style: TextStyle(
                color: _textSecondary,
                fontSize: 14,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      );
    } else {
      return Listener(
        onPointerDown: (_) => _pointers++,
        onPointerUp: (_) => _pointers--,
        child: CameraPreview(
          controller!,
          child: LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              return GestureDetector(
                behavior: HitTestBehavior.opaque,
                onScaleStart: _handleScaleStart,
                onScaleUpdate: _handleScaleUpdate,
                onTapDown: (TapDownDetails details) =>
                    onViewFinderTap(details, constraints),
              );
            },
          ),
        ),
      );
    }
  }

  void _handleScaleStart(ScaleStartDetails details) {
    _baseScale = _currentScale;
  }

  Future<void> _handleScaleUpdate(ScaleUpdateDetails details) async {
    if (controller == null || _pointers != 2) {
      return;
    }

    _currentScale = (_baseScale * details.scale).clamp(
      _minAvailableZoom,
      _maxAvailableZoom,
    );

    await controller!.setZoomLevel(_currentScale);
  }

  /// Display the thumbnail of the captured image or video.
  Widget _thumbnailWidget() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        if (videoController case final VideoPlayerController vc?)
          _buildThumbnailContainer(
            child: AspectRatio(
              aspectRatio: vc.value.aspectRatio,
              child: VideoPlayer(vc),
            ),
          )
        else if (imageFile?.path case final String path)
          _buildThumbnailContainer(
            child: kIsWeb ? Image.network(path, fit: BoxFit.cover) : Image.file(File(path), fit: BoxFit.cover),
          ),
      ],
    );
  }

  Widget _buildThumbnailContainer({required Widget child}) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _accent, width: 1.5),
        boxShadow: [BoxShadow(color: _accent.withOpacity(0.2), blurRadius: 8)],
      ),
      clipBehavior: Clip.antiAlias,
      child: child,
    );
  }

  /// Display a bar with buttons to change the flash and exposure modes
  Widget _modeControlRowWidget() {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      decoration: BoxDecoration(
        color: _bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _borderColor),
      ),
      child: Column(
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: <Widget>[
              _buildModeIconButton(
                icon: Icons.flash_on_rounded,
                onPressed: controller != null ? onFlashModeButtonPressed : null,
                tooltip: 'Flash',
              ),
              ...!kIsWeb
                  ? <Widget>[
                      _buildModeIconButton(
                        icon: Icons.exposure_rounded,
                        onPressed: controller != null ? onExposureModeButtonPressed : null,
                        tooltip: 'Exposure',
                      ),
                      _buildModeIconButton(
                        icon: Icons.center_focus_strong_rounded,
                        onPressed: controller != null ? onFocusModeButtonPressed : null,
                        tooltip: 'Focus',
                      ),
                    ]
                  : <Widget>[],
              _buildModeIconButton(
                icon: enableAudio ? Icons.volume_up_rounded : Icons.volume_off_rounded,
                onPressed: controller != null ? onAudioModeButtonPressed : null,
                tooltip: 'Audio',
                isActive: enableAudio,
              ),
              _buildModeIconButton(
                icon: controller?.value.isCaptureOrientationLocked ?? false
                    ? Icons.screen_lock_rotation_rounded
                    : Icons.screen_rotation_rounded,
                onPressed: controller != null ? onCaptureOrientationLockButtonPressed : null,
                tooltip: 'Orientation',
                isActive: controller?.value.isCaptureOrientationLocked ?? false,
              ),
            ],
          ),
          _flashModeControlRowWidget(),
          _exposureModeControlRowWidget(),
          _focusModeControlRowWidget(),
        ],
      ),
    );
  }

  Widget _buildModeIconButton({
    required IconData icon,
    VoidCallback? onPressed,
    String? tooltip,
    bool isActive = false,
  }) {
    return Tooltip(
      message: tooltip ?? '',
      child: GestureDetector(
        onTap: onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: isActive ? _accent.withOpacity(0.15) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isActive ? _accent.withOpacity(0.4) : Colors.transparent,
            ),
          ),
          child: Icon(
            icon,
            size: 22,
            color: onPressed == null
                ? _textSecondary.withOpacity(0.3)
                : isActive
                    ? _accent
                    : _textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _flashModeControlRowWidget() {
    return SizeTransition(
      sizeFactor: _flashModeControlRowAnimation,
      child: ClipRect(
        child: Container(
          margin: const EdgeInsets.only(top: 8),
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          decoration: BoxDecoration(
            color: _bgSurface,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: <Widget>[
              _buildFlashButton(Icons.flash_off_rounded, FlashMode.off, 'Off'),
              _buildFlashButton(Icons.flash_auto_rounded, FlashMode.auto, 'Auto'),
              _buildFlashButton(Icons.flash_on_rounded, FlashMode.always, 'On'),
              _buildFlashButton(Icons.highlight_rounded, FlashMode.torch, 'Torch'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFlashButton(IconData icon, FlashMode mode, String label) {
    final isActive = controller?.value.flashMode == mode;
    return GestureDetector(
      onTap: controller != null ? () => onSetFlashModeButtonPressed(mode) : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? _accent.withOpacity(0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isActive ? _accent : Colors.transparent,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: isActive ? _accent : _textSecondary),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: isActive ? _accent : _textSecondary,
                fontSize: 10,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _exposureModeControlRowWidget() {
    return SizeTransition(
      sizeFactor: _exposureModeControlRowAnimation,
      child: ClipRect(
        child: Container(
          margin: const EdgeInsets.only(top: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: _bgSurface,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const Text(
                'EXPOSURE MODE',
                style: TextStyle(
                  color: _textSecondary,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: <Widget>[
                  _buildTextModeButton(
                    label: 'AUTO',
                    isActive: controller?.value.exposureMode == ExposureMode.auto,
                    onPressed: controller != null
                        ? () => onSetExposureModeButtonPressed(ExposureMode.auto)
                        : null,
                    onLongPress: () {
                      if (controller != null) {
                        controller!.setExposurePoint(null);
                        showInSnackBar('Resetting exposure point');
                      }
                    },
                  ),
                  _buildTextModeButton(
                    label: 'LOCKED',
                    isActive: controller?.value.exposureMode == ExposureMode.locked,
                    onPressed: controller != null
                        ? () => onSetExposureModeButtonPressed(ExposureMode.locked)
                        : null,
                  ),
                  _buildTextModeButton(
                    label: 'RESET',
                    isActive: false,
                    onPressed: controller != null
                        ? () => controller!.setExposureOffset(0.0)
                        : null,
                    color: _accentWarm,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Text(
                'EXPOSURE OFFSET',
                style: TextStyle(
                  color: _textSecondary,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: <Widget>[
                  Text(
                    _minAvailableExposureOffset.toStringAsFixed(1),
                    style: const TextStyle(color: _textSecondary, fontSize: 11),
                  ),
                  Expanded(
                    child: SliderTheme(
                      data: SliderThemeData(
                        activeTrackColor: _accent,
                        inactiveTrackColor: _borderColor,
                        thumbColor: _accent,
                        overlayColor: _accent.withOpacity(0.15),
                        trackHeight: 3,
                        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                      ),
                      child: Slider(
                        value: _currentExposureOffset,
                        min: _minAvailableExposureOffset,
                        max: _maxAvailableExposureOffset,
                        label: _currentExposureOffset.toStringAsFixed(1),
                        onChanged:
                            _minAvailableExposureOffset == _maxAvailableExposureOffset
                                ? null
                                : setExposureOffset,
                      ),
                    ),
                  ),
                  Text(
                    _maxAvailableExposureOffset.toStringAsFixed(1),
                    style: const TextStyle(color: _textSecondary, fontSize: 11),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextModeButton({
    required String label,
    required bool isActive,
    VoidCallback? onPressed,
    VoidCallback? onLongPress,
    Color? color,
  }) {
    final activeColor = color ?? _accent;
    return GestureDetector(
      onTap: onPressed,
      onLongPress: onLongPress,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
        decoration: BoxDecoration(
          color: isActive ? activeColor.withOpacity(0.15) : _bgCard,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isActive ? activeColor : _borderColor,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isActive ? activeColor : _textSecondary,
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 1,
          ),
        ),
      ),
    );
  }

  Widget _focusModeControlRowWidget() {
    return SizeTransition(
      sizeFactor: _focusModeControlRowAnimation,
      child: ClipRect(
        child: Container(
          margin: const EdgeInsets.only(top: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: _bgSurface,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const Text(
                'FOCUS MODE',
                style: TextStyle(
                  color: _textSecondary,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: <Widget>[
                  _buildTextModeButton(
                    label: 'AUTO',
                    isActive: controller?.value.focusMode == FocusMode.auto,
                    onPressed: controller != null
                        ? () => onSetFocusModeButtonPressed(FocusMode.auto)
                        : null,
                    onLongPress: () {
                      if (controller != null) {
                        controller!.setFocusPoint(null);
                      }
                      showInSnackBar('Resetting focus point');
                    },
                  ),
                  _buildTextModeButton(
                    label: 'LOCKED',
                    isActive: controller?.value.focusMode == FocusMode.locked,
                    onPressed: controller != null
                        ? () => onSetFocusModeButtonPressed(FocusMode.locked)
                        : null,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Display the control bar with buttons to take pictures and record videos.
  Widget _captureControlRowWidget() {
    final CameraController? cameraController = controller;
    final bool isInitialized = cameraController != null && cameraController.value.isInitialized;
    final bool isRecording = isInitialized && cameraController.value.isRecordingVideo;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          // Pause/Resume
          _buildControlButton(
            icon: cameraController != null && cameraController.value.isRecordingPaused
                ? Icons.play_arrow_rounded
                : Icons.pause_rounded,
            onPressed: isRecording
                ? (cameraController.value.isRecordingPaused
                    ? onResumeButtonPressed
                    : onPauseButtonPressed)
                : null,
            size: 44,
          ),

          // Main Shutter / Record button
          _buildShutterButton(
            isInitialized: isInitialized,
            isRecording: isRecording,
            cameraController: cameraController,
          ),

          // Stop Recording
          _buildControlButton(
            icon: Icons.stop_rounded,
            onPressed: isRecording ? onStopButtonPressed : null,
            color: _accentRed,
            size: 44,
          ),
        ],
      ),
    );
  }

  Widget _buildShutterButton({
    required bool isInitialized,
    required bool isRecording,
    CameraController? cameraController,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Take Photo
        GestureDetector(
          onTap: isInitialized && !isRecording ? onTakePictureButtonPressed : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isInitialized && !isRecording
                  ? _textPrimary
                  : _textSecondary.withOpacity(0.2),
              boxShadow: isInitialized && !isRecording
                  ? [BoxShadow(color: _textPrimary.withOpacity(0.25), blurRadius: 16)]
                  : [],
            ),
            child: Icon(
              Icons.camera_alt_rounded,
              color: isInitialized && !isRecording ? _bgDark : _textSecondary.withOpacity(0.4),
              size: 28,
            ),
          ),
        ),
        const SizedBox(width: 12),
        // Record Video
        GestureDetector(
          onTap: isInitialized && !isRecording ? onVideoRecordButtonPressed : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.transparent,
              border: Border.all(
                color: isInitialized && !isRecording ? _accentRed : _accentRed.withOpacity(0.3),
                width: 2,
              ),
            ),
            child: Center(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isInitialized && !isRecording
                      ? _accentRed
                      : _accentRed.withOpacity(0.3),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    VoidCallback? onPressed,
    Color color = _textSecondary,
    double size = 40,
  }) {
    final isEnabled = onPressed != null;
    return GestureDetector(
      onTap: onPressed,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: isEnabled ? color.withOpacity(0.12) : Colors.transparent,
          shape: BoxShape.circle,
          border: Border.all(
            color: isEnabled ? color.withOpacity(0.5) : _borderColor,
          ),
        ),
        child: Icon(
          icon,
          color: isEnabled ? color : _textSecondary.withOpacity(0.25),
          size: size * 0.45,
        ),
      ),
    );
  }

  // Also add pause preview as a floating badge-style button on the preview
  Widget _buildPausePreviewButton(CameraController? cameraController) {
    final isPaused = cameraController?.value.isPreviewPaused ?? false;
    return GestureDetector(
      onTap: cameraController == null ? null : onPausePreviewButtonPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isPaused ? _accentRed.withOpacity(0.2) : _bgCard.withOpacity(0.8),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isPaused ? _accentRed : _borderColor),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isPaused ? Icons.play_arrow_rounded : Icons.pause_presentation_rounded,
              color: isPaused ? _accentRed : _textSecondary,
              size: 16,
            ),
            const SizedBox(width: 4),
            Text(
              isPaused ? 'RESUME' : 'PAUSE',
              style: TextStyle(
                color: isPaused ? _accentRed : _textSecondary,
                fontSize: 10,
                fontWeight: FontWeight.w600,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Display a row of toggle to select the camera.
  Widget _cameraTogglesRowWidget() {
    final toggles = <Widget>[];

    void onChanged(CameraDescription? description) {
      if (description == null) return;
      onNewCameraSelected(description);
    }

    if (_cameras.isEmpty) {
      SchedulerBinding.instance.addPostFrameCallback((_) async {
        showInSnackBar('No camera found.');
      });
      return const Text(
        'None',
        style: TextStyle(color: _textSecondary, fontSize: 12),
      );
    } else {
      for (final CameraDescription cameraDescription in _cameras) {
        toggles.add(
          SizedBox(
            width: 80.0,
            child: RadioListTile<CameraDescription>(
              contentPadding: EdgeInsets.zero,
              title: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: controller?.description == cameraDescription
                      ? _accent.withOpacity(0.15)
                      : _bgCard,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: controller?.description == cameraDescription
                        ? _accent
                        : _borderColor,
                  ),
                ),
                child: Icon(
                  getCameraLensIcon(cameraDescription.lensDirection),
                  color: controller?.description == cameraDescription
                      ? _accent
                      : _textSecondary,
                  size: 20,
                ),
              ),
              value: cameraDescription,
            ),
          ),
        );
      }
    }

    return Expanded(
      child: SizedBox(
        height: 56.0,
        child: RadioGroup<CameraDescription>(
          groupValue: controller?.description,
          onChanged: onChanged,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: toggles,
          ),
        ),
      ),
    );
  }

  String timestamp() => DateTime.now().millisecondsSinceEpoch.toString();

  void showInSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(color: _textPrimary, fontSize: 13),
        ),
        backgroundColor: _bgCard,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: _borderColor),
        ),
        margin: const EdgeInsets.all(12),
      ),
    );
  }

  void onViewFinderTap(TapDownDetails details, BoxConstraints constraints) {
    if (controller == null) return;

    final CameraController cameraController = controller!;

    final offset = Offset(
      details.localPosition.dx / constraints.maxWidth,
      details.localPosition.dy / constraints.maxHeight,
    );
    cameraController.setExposurePoint(offset);
    cameraController.setFocusPoint(offset);
  }

  Future<void> onNewCameraSelected(CameraDescription cameraDescription) async {
    if (controller != null) {
      return controller!.setDescription(cameraDescription);
    } else {
      return _initializeCameraController(cameraDescription);
    }
  }

  Future<void> _initializeCameraController(
    CameraDescription cameraDescription,
  ) async {
    final cameraController = CameraController(
      cameraDescription,
      kIsWeb ? ResolutionPreset.max : ResolutionPreset.medium,
      enableAudio: enableAudio,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );

    controller = cameraController;

    cameraController.addListener(() {
      if (mounted) {
        setState(() {});
      }
      if (cameraController.value.hasError) {
        showInSnackBar(
          'Camera error ${cameraController.value.errorDescription}',
        );
      }
    });

    try {
      await cameraController.initialize();
      await Future.wait(<Future<Object?>>[
        ...!kIsWeb
            ? <Future<Object?>>[
                cameraController.getMinExposureOffset().then(
                  (double value) => _minAvailableExposureOffset = value,
                ),
                cameraController.getMaxExposureOffset().then(
                  (double value) => _maxAvailableExposureOffset = value,
                ),
              ]
            : <Future<Object?>>[],
        cameraController.getMaxZoomLevel().then(
          (double value) => _maxAvailableZoom = value,
        ),
        cameraController.getMinZoomLevel().then(
          (double value) => _minAvailableZoom = value,
        ),
      ]);
    } on CameraException catch (e) {
      switch (e.code) {
        case 'CameraAccessDenied':
          showInSnackBar('You have denied camera access.');
        case 'CameraAccessDeniedWithoutPrompt':
          showInSnackBar('Please go to Settings app to enable camera access.');
        case 'CameraAccessRestricted':
          showInSnackBar('Camera access is restricted.');
        case 'AudioAccessDenied':
          showInSnackBar('You have denied audio access.');
        case 'AudioAccessDeniedWithoutPrompt':
          showInSnackBar('Please go to Settings app to enable audio access.');
        case 'AudioAccessRestricted':
          showInSnackBar('Audio access is restricted.');
        default:
          _showCameraException(e);
      }
    }

    if (mounted) {
      setState(() {});
    }
  }

  void onTakePictureButtonPressed() {
    takePicture().then((XFile? file) {
      if (mounted) {
        setState(() {
          imageFile = file;
          videoController?.dispose();
          videoController = null;
        });
        if (file != null) {
          showInSnackBar('Picture saved to ${file.path}');
        }
      }
    });
  }

  void onFlashModeButtonPressed() {
    if (_flashModeControlRowAnimationController.value == 1) {
      _flashModeControlRowAnimationController.reverse();
    } else {
      _flashModeControlRowAnimationController.forward();
      _exposureModeControlRowAnimationController.reverse();
      _focusModeControlRowAnimationController.reverse();
    }
  }

  void onExposureModeButtonPressed() {
    if (_exposureModeControlRowAnimationController.value == 1) {
      _exposureModeControlRowAnimationController.reverse();
    } else {
      _exposureModeControlRowAnimationController.forward();
      _flashModeControlRowAnimationController.reverse();
      _focusModeControlRowAnimationController.reverse();
    }
  }

  void onFocusModeButtonPressed() {
    if (_focusModeControlRowAnimationController.value == 1) {
      _focusModeControlRowAnimationController.reverse();
    } else {
      _focusModeControlRowAnimationController.forward();
      _flashModeControlRowAnimationController.reverse();
      _exposureModeControlRowAnimationController.reverse();
    }
  }

  void onAudioModeButtonPressed() {
    enableAudio = !enableAudio;
    if (controller != null) {
      onNewCameraSelected(controller!.description);
    }
  }

  Future<void> onCaptureOrientationLockButtonPressed() async {
    try {
      if (controller != null) {
        final CameraController cameraController = controller!;
        if (cameraController.value.isCaptureOrientationLocked) {
          await cameraController.unlockCaptureOrientation();
          showInSnackBar('Capture orientation unlocked');
        } else {
          await cameraController.lockCaptureOrientation();
          showInSnackBar(
            'Capture orientation locked to ${cameraController.value.lockedCaptureOrientation.toString().split('.').last}',
          );
        }
      }
    } on CameraException catch (e) {
      _showCameraException(e);
    }
  }

  void onSetFlashModeButtonPressed(FlashMode mode) {
    setFlashMode(mode).then((_) {
      if (mounted) setState(() {});
      showInSnackBar('Flash mode set to ${mode.toString().split('.').last}');
    });
  }

  void onSetExposureModeButtonPressed(ExposureMode mode) {
    setExposureMode(mode).then((_) {
      if (mounted) setState(() {});
      showInSnackBar('Exposure mode set to ${mode.toString().split('.').last}');
    });
  }

  void onSetFocusModeButtonPressed(FocusMode mode) {
    setFocusMode(mode).then((_) {
      if (mounted) setState(() {});
      showInSnackBar('Focus mode set to ${mode.toString().split('.').last}');
    });
  }

  void onVideoRecordButtonPressed() {
    startVideoRecording().then((_) {
      if (mounted) setState(() {});
    });
  }

  void onStopButtonPressed() {
    stopVideoRecording().then((XFile? file) {
      if (mounted) setState(() {});
      if (file != null) {
        showInSnackBar('Video recorded to ${file.path}');
        videoFile = file;
        _startVideoPlayer();
      }
    });
  }

  Future<void> onPausePreviewButtonPressed() async {
    final CameraController? cameraController = controller;

    if (cameraController == null || !cameraController.value.isInitialized) {
      showInSnackBar('Error: select a camera first.');
      return;
    }

    if (cameraController.value.isPreviewPaused) {
      await cameraController.resumePreview();
    } else {
      await cameraController.pausePreview();
    }

    if (mounted) setState(() {});
  }

  void onPauseButtonPressed() {
    pauseVideoRecording().then((_) {
      if (mounted) setState(() {});
      showInSnackBar('Video recording paused');
    });
  }

  void onResumeButtonPressed() {
    resumeVideoRecording().then((_) {
      if (mounted) setState(() {});
      showInSnackBar('Video recording resumed');
    });
  }

  Future<void> startVideoRecording() async {
    final CameraController? cameraController = controller;

    if (cameraController == null || !cameraController.value.isInitialized) {
      showInSnackBar('Error: select a camera first.');
      return;
    }

    if (cameraController.value.isRecordingVideo) return;

    try {
      await cameraController.startVideoRecording();
    } on CameraException catch (e) {
      _showCameraException(e);
      return;
    }
  }

  Future<XFile?> stopVideoRecording() async {
    final CameraController? cameraController = controller;

    if (cameraController == null || !cameraController.value.isRecordingVideo) {
      return null;
    }

    try {
      return await cameraController.stopVideoRecording();
    } on CameraException catch (e) {
      _showCameraException(e);
      return null;
    }
  }

  Future<void> pauseVideoRecording() async {
    final CameraController? cameraController = controller;

    if (cameraController == null || !cameraController.value.isRecordingVideo) return;

    try {
      await cameraController.pauseVideoRecording();
    } on CameraException catch (e) {
      _showCameraException(e);
      rethrow;
    }
  }

  Future<void> resumeVideoRecording() async {
    final CameraController? cameraController = controller;

    if (cameraController == null || !cameraController.value.isRecordingVideo) return;

    try {
      await cameraController.resumeVideoRecording();
    } on CameraException catch (e) {
      _showCameraException(e);
      rethrow;
    }
  }

  Future<void> setFlashMode(FlashMode mode) async {
    if (controller == null) return;
    try {
      await controller!.setFlashMode(mode);
    } on CameraException catch (e) {
      _showCameraException(e);
      rethrow;
    }
  }

  Future<void> setExposureMode(ExposureMode mode) async {
    if (controller == null) return;
    try {
      await controller!.setExposureMode(mode);
    } on CameraException catch (e) {
      _showCameraException(e);
      rethrow;
    }
  }

  Future<void> setExposureOffset(double offset) async {
    if (controller == null) return;
    setState(() {
      _currentExposureOffset = offset;
    });
    try {
      offset = await controller!.setExposureOffset(offset);
    } on CameraException catch (e) {
      _showCameraException(e);
      rethrow;
    }
  }

  Future<void> setFocusMode(FocusMode mode) async {
    if (controller == null) return;
    try {
      await controller!.setFocusMode(mode);
    } on CameraException catch (e) {
      _showCameraException(e);
      rethrow;
    }
  }

  Future<void> _startVideoPlayer() async {
    if (videoFile == null) return;

    final vController = kIsWeb
        ? VideoPlayerController.networkUrl(Uri.parse(videoFile!.path))
        : VideoPlayerController.file(File(videoFile!.path));

    videoPlayerListener = () {
      if (videoController != null) {
        if (mounted) setState(() {});
        videoController!.removeListener(videoPlayerListener!);
      }
    };
    vController.addListener(videoPlayerListener!);
    await vController.setLooping(true);
    await vController.initialize();
    await videoController?.dispose();
    if (mounted) {
      setState(() {
        imageFile = null;
        videoController = vController;
      });
    }
    await vController.play();
  }

  Future<XFile?> takePicture() async {
    final CameraController? cameraController = controller;
    if (cameraController == null || !cameraController.value.isInitialized) {
      showInSnackBar('Error: select a camera first.');
      return null;
    }

    if (cameraController.value.isTakingPicture) return null;

    try {
      final XFile file = await cameraController.takePicture();
      return file;
    } on CameraException catch (e) {
      _showCameraException(e);
      return null;
    }
  }

  void _showCameraException(CameraException e) {
    _logError(e.code, e.description);
    showInSnackBar('Error: ${e.code}\n${e.description}');
  }
}

// ─── Animated Recording Badge ────────────────────────────────────────────────
class _RecordingBadge extends StatefulWidget {
  @override
  State<_RecordingBadge> createState() => _RecordingBadgeState();
}

class _RecordingBadgeState extends State<_RecordingBadge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    duration: const Duration(milliseconds: 800),
    vsync: this,
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _controller,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: _accentRed.withOpacity(0.85),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.fiber_manual_record, color: Colors.white, size: 10),
            SizedBox(width: 4),
            Text(
              'REC',
              style: TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Corner Painter ──────────────────────────────────────────────────────────
class _CornerPainter extends CustomPainter {
  final bool isTop;
  final bool isLeft;

  _CornerPainter({required this.isTop, required this.isLeft});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = _accent
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final double len = size.width;
    final double x = isLeft ? 0 : size.width;
    final double y = isTop ? 0 : size.height;
    final double hDir = isLeft ? 1 : -1;
    final double vDir = isTop ? 1 : -1;

    canvas.drawLine(Offset(x, y), Offset(x + hDir * len, y), paint);
    canvas.drawLine(Offset(x, y), Offset(x, y + vDir * len), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ─── App & Entry Points ───────────────────────────────────────────────────────

/// CameraApp is the Main Application.
class CameraApp extends StatelessWidget {
  /// Default Constructor
  const CameraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: _bgDark,
        colorScheme: const ColorScheme.dark(
          primary: _accent,
          surface: _bgCard,
        ),
      ),
      home: const CameraExampleHome(),
    );
  }
}

/// Getting available cameras for testing.
@visibleForTesting
List<CameraDescription> get cameras => _cameras;
List<CameraDescription> _cameras = <CameraDescription>[];

Future<void> initCamera() async {
  WidgetsFlutterBinding.ensureInitialized();
  _cameras = await availableCameras();
}
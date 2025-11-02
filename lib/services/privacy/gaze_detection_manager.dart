import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:camera/camera.dart';

/// Optional face/gaze detection using MLKit
/// Battery-efficient: only active when privacy mode is on and app is visible
/// Detects multiple faces to trigger privacy alerts
class GazeDetectionManager {
  static final GazeDetectionManager _instance = GazeDetectionManager._internal();
  factory GazeDetectionManager() => _instance;
  GazeDetectionManager._internal();

  CameraController? _cameraController;
  FaceDetector? _faceDetector;
  bool _isProcessing = false;
  bool _isActive = false;
  CameraDescription? _camera;

  Function(int faceCount)? onFaceCountChanged;

  /// Initialize camera and face detector
  Future<bool> initialize() async {
    try {
      // Get available cameras
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        debugPrint("👁️ No cameras available");
        return false;
      }

      // Use front camera
      _camera = cameras.firstWhere(
            (camera) => camera.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );

      // Initialize camera controller with low resolution for battery efficiency
      _cameraController = CameraController(
        _camera!,
        ResolutionPreset.low,
        enableAudio: false,
        imageFormatGroup: Platform.isAndroid
            ? ImageFormatGroup.nv21
            : ImageFormatGroup.bgra8888,
      );

      await _cameraController!.initialize();

      // Initialize face detector
      final options = FaceDetectorOptions(
        enableClassification: false,
        enableLandmarks: false,
        enableTracking: false,
        enableContours: false,
        performanceMode: FaceDetectorMode.fast, // Battery-efficient mode
      );
      _faceDetector = FaceDetector(options: options);

      debugPrint("👁️ Gaze detection initialized");
      return true;
    } catch (e) {
      debugPrint("❌ Error initializing gaze detection: $e");
      return false;
    }
  }

  /// Start detecting faces
  Future<void> startDetection() async {
    if (_isActive || _cameraController == null || _faceDetector == null) return;

    _isActive = true;

    _cameraController!.startImageStream((CameraImage image) async {
      if (_isProcessing) return;
      _isProcessing = true;

      try {
        // Process every second to save battery
        await Future.delayed(const Duration(milliseconds: 1000));

        // Convert camera image to InputImage
        final inputImage = _convertCameraImage(image);
        if (inputImage == null) {
          _isProcessing = false;
          return;
        }

        // Detect faces
        final faces = await _faceDetector!.processImage(inputImage);

        // Notify callback
        onFaceCountChanged?.call(faces.length);

        if (faces.length > 1) {
          debugPrint("👁️ Multiple faces detected: ${faces.length}");
        }
      } catch (e) {
        debugPrint("❌ Face detection error: $e");
      } finally {
        _isProcessing = false;
      }
    });

    debugPrint("👁️ Face detection started");
  }

  /// Stop detecting faces (battery optimization)
  Future<void> stopDetection() async {
    if (!_isActive) return;

    _isActive = false;
    await _cameraController?.stopImageStream();
    debugPrint("👁️ Face detection stopped");
  }

  /// Convert CameraImage to InputImage for MLKit
  /// Updated for latest google_mlkit_face_detection API
  InputImage? _convertCameraImage(CameraImage image) {
    try {
      if (_camera == null) return null;

      // Get image rotation based on camera sensor orientation
      final sensorOrientation = _camera!.sensorOrientation;
      InputImageRotation? rotation;

      if (Platform.isIOS) {
        rotation = InputImageRotationValue.fromRawValue(sensorOrientation);
      } else if (Platform.isAndroid) {
        var rotationCompensation = sensorOrientation;
        rotation = InputImageRotationValue.fromRawValue(rotationCompensation);
      }

      if (rotation == null) {
        debugPrint("❌ Could not determine image rotation");
        return null;
      }

      // Get image format
      final format = InputImageFormatValue.fromRawValue(image.format.raw);
      if (format == null) {
        debugPrint("❌ Unsupported image format: ${image.format.raw}");
        return null;
      }

      // Check if platform supports plane data
      if (image.planes.isEmpty) {
        debugPrint("❌ No image planes available");
        return null;
      }

      // For Android (NV21) and iOS (BGRA8888), we need different approaches
      if (Platform.isAndroid) {
        // Android - use NV21 format with plane metadata
        final plane = image.planes.first;

        return InputImage.fromBytes(
          bytes: plane.bytes,
          metadata: InputImageMetadata(
            size: Size(image.width.toDouble(), image.height.toDouble()),
            rotation: rotation,
            format: format,
            bytesPerRow: plane.bytesPerRow,
          ),
        );
      } else {
        // iOS - use BGRA8888 format
        final plane = image.planes.first;

        return InputImage.fromBytes(
          bytes: plane.bytes,
          metadata: InputImageMetadata(
            size: Size(image.width.toDouble(), image.height.toDouble()),
            rotation: rotation,
            format: format,
            bytesPerRow: plane.bytesPerRow,
          ),
        );
      }
    } catch (e) {
      debugPrint("❌ Error converting camera image: $e");
      return null;
    }
  }

  /// Cleanup resources
  Future<void> dispose() async {
    await stopDetection();
    await _cameraController?.dispose();
    await _faceDetector?.close();
    _cameraController = null;
    _faceDetector = null;
    _camera = null;
    debugPrint("👁️ Gaze detection disposed");
  }

  bool get isActive => _isActive;
  bool get isInitialized => _cameraController != null && _faceDetector != null;
}
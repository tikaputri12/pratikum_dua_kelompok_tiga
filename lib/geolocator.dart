import 'dart:async';
import 'dart:io' show Platform;

import 'package:baseflow_plugin_template/baseflow_plugin_template.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

/// Defines the main theme color.
final MaterialColor themeMaterialColor =
    BaseflowPluginExample.createMaterialColor(
        const Color.fromRGBO(10, 12, 20, 1));

// ─── Design Tokens ────────────────────────────────────────────────────────────
class _AppColors {
  static const bg         = Color(0xFF080B14);
  static const surface    = Color(0xFF0E1220);
  static const card       = Color(0xFF131826);
  static const border     = Color(0xFF1E2640);
  static const accent     = Color(0xFF00E5FF);
  static const accentGlow = Color(0x3300E5FF);
  static const success    = Color(0xFF00FF9D);
  static const danger     = Color(0xFFFF3D5A);
  static const textPri    = Color(0xFFE8EDF8);
  static const textSec    = Color(0xFF5A6585);
  static const logText    = Color(0xFF8B95B0);
}

/// Example [Widget] showing the functionalities of the geolocator plugin
class GeolocatorWidget extends StatefulWidget {
  /// Creates a new GeolocatorWidget.
  const GeolocatorWidget({super.key});

  /// Utility method to create a page with the Baseflow templating.
  static ExamplePage createPage() {
    return ExamplePage(
        Icons.location_on, (context) => const GeolocatorWidget());
  }

  @override
  State<GeolocatorWidget> createState() => _GeolocatorWidgetState();
}

class _GeolocatorWidgetState extends State<GeolocatorWidget>
    with TickerProviderStateMixin {
  static const String _kLocationServicesDisabledMessage =
      'Location services are disabled.';
  static const String _kPermissionDeniedMessage = 'Permission denied.';
  static const String _kPermissionDeniedForeverMessage =
      'Permission denied forever.';
  static const String _kPermissionGrantedMessage = 'Permission granted.';

  final GeolocatorPlatform _geolocatorPlatform = GeolocatorPlatform.instance;
  final List<_PositionItem> _positionItems = <_PositionItem>[];
  StreamSubscription<Position>? _positionStreamSubscription;
  StreamSubscription<ServiceStatus>? _serviceStatusStreamSubscription;
  bool positionStreamStarted = false;

  late AnimationController _pulseController;
  late AnimationController _fadeController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    )..forward();

    _pulseAnimation = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _toggleServiceStatusStream();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _fadeController.dispose();
    if (_positionStreamSubscription != null) {
      _positionStreamSubscription!.cancel();
      _positionStreamSubscription = null;
    }
    super.dispose();
  }

  PopupMenuButton _createActions() {
    return PopupMenuButton(
      elevation: 8,
      color: _AppColors.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: _AppColors.border),
      ),
      icon: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          border: Border.all(color: _AppColors.border),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(Icons.tune_rounded, color: _AppColors.textSec, size: 18),
      ),
      onSelected: (value) async {
        switch (value) {
          case 1: _getLocationAccuracy(); break;
          case 2: _requestTemporaryFullAccuracy(); break;
          case 3: _openAppSettings(); break;
          case 4: _openLocationSettings(); break;
          case 5: setState(_positionItems.clear); break;
        }
      },
      itemBuilder: (context) => [
        if (Platform.isIOS)
          _menuItem(1, Icons.gps_fixed_rounded, "Location Accuracy"),
        if (Platform.isIOS)
          _menuItem(2, Icons.high_quality_rounded, "Request Full Accuracy"),
        _menuItem(3, Icons.settings_rounded, "App Settings"),
        if (Platform.isAndroid || Platform.isWindows)
          _menuItem(4, Icons.location_city_rounded, "Location Settings"),
        _menuItem(5, Icons.delete_sweep_rounded, "Clear Log",
            color: _AppColors.danger),
      ],
    );
  }

  PopupMenuItem _menuItem(int value, IconData icon, String label,
      {Color color = _AppColors.textPri}) {
    return PopupMenuItem(
      value: value,
      child: Row(
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 10),
          Text(label,
              style: TextStyle(
                  color: color,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.3)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BaseflowPluginExample(
        pluginName: 'Geolocator',
        githubURL: 'https://github.com/Baseflow/flutter-geolocator',
        pubDevURL: 'https://pub.dev/packages/geolocator',
        appBarActions: [_createActions()],
        pages: [
          ExamplePage(
            Icons.location_on,
            (context) => Scaffold(
              backgroundColor: _AppColors.bg,
              body: Column(
                children: [
                  _buildStatusHeader(),
                  Expanded(child: _buildPositionList()),
                ],
              ),
              floatingActionButton: _buildFABGroup(),
            ),
          )
        ]);
  }

  // ── Status Header ──────────────────────────────────────────────────────────
  Widget _buildStatusHeader() {
    final isLive = _isListening();
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: _AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isLive ? _AppColors.success.withOpacity(0.4) : _AppColors.border,
        ),
        boxShadow: isLive
            ? [BoxShadow(color: _AppColors.success.withOpacity(0.08), blurRadius: 20)]
            : [],
      ),
      child: Row(
        children: [
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (_, __) => Opacity(
              opacity: isLive ? _pulseAnimation.value : 0.3,
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: isLive ? _AppColors.success : _AppColors.textSec,
                  shape: BoxShape.circle,
                  boxShadow: isLive
                      ? [BoxShadow(
                          color: _AppColors.success.withOpacity(0.6),
                          blurRadius: 8)]
                      : [],
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            isLive ? 'LIVE TRACKING' : 'STANDBY',
            style: TextStyle(
              color: isLive ? _AppColors.success : _AppColors.textSec,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.8,
            ),
          ),
          const Spacer(),
          Text(
            '${_positionItems.length} events',
            style: const TextStyle(
                color: _AppColors.textSec, fontSize: 12, letterSpacing: 0.3),
          ),
        ],
      ),
    );
  }

  // ── Position List ──────────────────────────────────────────────────────────
  Widget _buildPositionList() {
    if (_positionItems.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (_, __) => Opacity(
                opacity: _pulseAnimation.value * 0.5,
                child: const Icon(
                  Icons.satellite_alt_rounded,
                  size: 48,
                  color: _AppColors.textSec,
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Awaiting signal...',
              style: TextStyle(
                  color: _AppColors.textSec,
                  fontSize: 14,
                  letterSpacing: 0.5),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: _positionItems.length,
      itemBuilder: (context, index) {
        final positionItem = _positionItems[index];
        final isNew = index == _positionItems.length - 1;

        return AnimatedOpacity(
          opacity: 1.0,
          duration: const Duration(milliseconds: 300),
          child: positionItem.type == _PositionItemType.log
              ? _buildLogTile(positionItem.displayValue, isNew)
              : _buildPositionCard(positionItem.displayValue, isNew),
        );
      },
    );
  }

  Widget _buildLogTile(String message, bool isNew) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          Container(
            width: 1,
            height: 20,
            margin: const EdgeInsets.only(right: 12),
            color: _AppColors.border,
          ),
          const Icon(Icons.info_outline_rounded,
              size: 14, color: _AppColors.textSec),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                  color: _AppColors.logText,
                  fontSize: 12,
                  letterSpacing: 0.2),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPositionCard(String position, bool isNew) {
    // Parse coordinate parts for nicer display
    final lines = position
        .replaceAll('Position(', '')
        .replaceAll(')', '')
        .split(',')
        .map((s) => s.trim())
        .toList();

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isNew ? _AppColors.accent.withOpacity(0.35) : _AppColors.border,
        ),
        boxShadow: isNew
            ? [BoxShadow(color: _AppColors.accentGlow, blurRadius: 16)]
            : [],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.location_on_rounded,
                  size: 14, color: _AppColors.accent),
              const SizedBox(width: 6),
              const Text(
                'POSITION FIX',
                style: TextStyle(
                    color: _AppColors.accent,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.5),
              ),
              if (isNew) ...[
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: _AppColors.accentGlow,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'NEW',
                    style: TextStyle(
                        color: _AppColors.accent,
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2),
                  ),
                ),
              ]
            ],
          ),
          const SizedBox(height: 10),
          const Divider(color: _AppColors.border, height: 1),
          const SizedBox(height: 10),
          ...lines.map((line) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: _buildDataRow(line),
              )),
        ],
      ),
    );
  }

  Widget _buildDataRow(String data) {
    final parts = data.split(':');
    if (parts.length == 2) {
      return Row(
        children: [
          Text(
            parts[0].trim(),
            style: const TextStyle(
                color: _AppColors.textSec,
                fontSize: 11,
                letterSpacing: 0.4),
          ),
          const Spacer(),
          Text(
            parts[1].trim(),
            style: const TextStyle(
                color: _AppColors.textPri,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.3,
                fontFamily: 'monospace'),
          ),
        ],
      );
    }
    return Text(
      data,
      style: const TextStyle(
          color: _AppColors.textPri,
          fontSize: 12,
          fontFamily: 'monospace'),
    );
  }

  // ── FAB Group ──────────────────────────────────────────────────────────────
  Widget _buildFABGroup() {
    final isLive = _isListening();
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        _buildSmallFAB(
          icon: Icons.bookmark_rounded,
          onPressed: _getLastKnownPosition,
          tooltip: 'Last known position',
          color: _AppColors.textSec,
        ),
        const SizedBox(height: 10),
        _buildSmallFAB(
          icon: Icons.my_location_rounded,
          onPressed: _getCurrentPosition,
          tooltip: 'Get current position',
          color: _AppColors.accent,
        ),
        const SizedBox(height: 14),
        GestureDetector(
          onTap: () {
            positionStreamStarted = !positionStreamStarted;
            _toggleListening();
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: isLive ? _AppColors.success.withOpacity(0.15) : _AppColors.danger.withOpacity(0.15),
              shape: BoxShape.circle,
              border: Border.all(
                color: isLive ? _AppColors.success : _AppColors.danger,
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: (isLive ? _AppColors.success : _AppColors.danger).withOpacity(0.25),
                  blurRadius: 20,
                  spreadRadius: 2,
                )
              ],
            ),
            child: Icon(
              isLive ? Icons.pause_rounded : Icons.play_arrow_rounded,
              color: isLive ? _AppColors.success : _AppColors.danger,
              size: 26,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSmallFAB({
    required IconData icon,
    required VoidCallback onPressed,
    required String tooltip,
    required Color color,
  }) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onPressed,
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: _AppColors.surface,
            shape: BoxShape.circle,
            border: Border.all(color: _AppColors.border),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
      ),
    );
  }

  // ── Logic (unchanged) ──────────────────────────────────────────────────────

  Future<void> _getCurrentPosition() async {
    final hasPermission = await _handlePermission();
    if (!hasPermission) return;
    final position = await _geolocatorPlatform.getCurrentPosition();
    _updatePositionList(_PositionItemType.position, position.toString());
  }

  Future<bool> _handlePermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await _geolocatorPlatform.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _updatePositionList(_PositionItemType.log, _kLocationServicesDisabledMessage);
      return false;
    }

    permission = await _geolocatorPlatform.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await _geolocatorPlatform.requestPermission();
      if (permission == LocationPermission.denied) {
        _updatePositionList(_PositionItemType.log, _kPermissionDeniedMessage);
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      _updatePositionList(_PositionItemType.log, _kPermissionDeniedForeverMessage);
      return false;
    }

    _updatePositionList(_PositionItemType.log, _kPermissionGrantedMessage);
    return true;
  }

  void _updatePositionList(_PositionItemType type, String displayValue) {
    _positionItems.add(_PositionItem(type, displayValue));
    setState(() {});
  }

  bool _isListening() => !(_positionStreamSubscription == null ||
      _positionStreamSubscription!.isPaused);

  Color _determineButtonColor() {
    return _isListening() ? _AppColors.success : _AppColors.danger;
  }

  void _toggleServiceStatusStream() {
    if (_serviceStatusStreamSubscription == null) {
      final serviceStatusStream = _geolocatorPlatform.getServiceStatusStream();
      _serviceStatusStreamSubscription =
          serviceStatusStream.handleError((error) {
        _serviceStatusStreamSubscription?.cancel();
        _serviceStatusStreamSubscription = null;
      }).listen((serviceStatus) {
        String serviceStatusValue;
        if (serviceStatus == ServiceStatus.enabled) {
          if (positionStreamStarted) _toggleListening();
          serviceStatusValue = 'enabled';
        } else {
          if (_positionStreamSubscription != null) {
            setState(() {
              _positionStreamSubscription?.cancel();
              _positionStreamSubscription = null;
              _updatePositionList(
                  _PositionItemType.log, 'Position Stream has been canceled');
            });
          }
          serviceStatusValue = 'disabled';
        }
        _updatePositionList(
          _PositionItemType.log,
          'Location service has been $serviceStatusValue',
        );
      });
    }
  }

  void _toggleListening() {
    if (_positionStreamSubscription == null) {
      final positionStream = _geolocatorPlatform.getPositionStream();
      _positionStreamSubscription = positionStream.handleError((error) {
        _positionStreamSubscription?.cancel();
        _positionStreamSubscription = null;
      }).listen((position) => _updatePositionList(
            _PositionItemType.position,
            position.toString(),
          ));
      _positionStreamSubscription?.pause();
    }

    setState(() {
      if (_positionStreamSubscription == null) return;

      String statusDisplayValue;
      if (_positionStreamSubscription!.isPaused) {
        _positionStreamSubscription!.resume();
        statusDisplayValue = 'resumed';
      } else {
        _positionStreamSubscription!.pause();
        statusDisplayValue = 'paused';
      }

      _updatePositionList(
        _PositionItemType.log,
        'Listening for position updates $statusDisplayValue',
      );
    });
  }

  void _getLastKnownPosition() async {
    final position = await _geolocatorPlatform.getLastKnownPosition();
    if (position != null) {
      _updatePositionList(_PositionItemType.position, position.toString());
    } else {
      _updatePositionList(_PositionItemType.log, 'No last known position available');
    }
  }

  void _getLocationAccuracy() async {
    final status = await _geolocatorPlatform.getLocationAccuracy();
    _handleLocationAccuracyStatus(status);
  }

  void _requestTemporaryFullAccuracy() async {
    final status = await _geolocatorPlatform.requestTemporaryFullAccuracy(
      purposeKey: "TemporaryPreciseAccuracy",
    );
    _handleLocationAccuracyStatus(status);
  }

  void _handleLocationAccuracyStatus(LocationAccuracyStatus status) {
    String locationAccuracyStatusValue;
    if (status == LocationAccuracyStatus.precise) {
      locationAccuracyStatusValue = 'Precise';
    } else if (status == LocationAccuracyStatus.reduced) {
      locationAccuracyStatusValue = 'Reduced';
    } else {
      locationAccuracyStatusValue = 'Unknown';
    }
    _updatePositionList(
      _PositionItemType.log,
      '$locationAccuracyStatusValue location accuracy granted.',
    );
  }

  void _openAppSettings() async {
    final opened = await _geolocatorPlatform.openAppSettings();
    _updatePositionList(_PositionItemType.log,
        opened ? 'Opened Application Settings.' : 'Error opening Application Settings.');
  }

  void _openLocationSettings() async {
    final opened = await _geolocatorPlatform.openLocationSettings();
    _updatePositionList(_PositionItemType.log,
        opened ? 'Opened Location Settings' : 'Error opening Location Settings');
  }
}

enum _PositionItemType {
  log,
  position,
}

class _PositionItem {
  _PositionItem(this.type, this.displayValue);

  final _PositionItemType type;
  final String displayValue;
}
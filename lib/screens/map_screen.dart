import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../services/geojson_service.dart';
import '../services/water_stations_service.dart';
import 'station_details_screen.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();

  // Center point for India - Adjusted to show more of eastern India and islands
  final LatLng _center = const LatLng(20.0, 82.0);

  // Current zoom level tracking
  double _currentZoom = 4.2;

  // Optimized marker widgets for different zoom levels - create once and reuse
  static const Widget _smallMarker = SizedBox(
    width: 1.5,
    height: 1.5,
    child: DecoratedBox(
      decoration: BoxDecoration(
        color: Color(0xFF2196F3),
        shape: BoxShape.circle,
      ),
    ),
  );

  static const Widget _mediumMarker = SizedBox(
    width: 3.0,
    height: 3.0,
    child: DecoratedBox(
      decoration: BoxDecoration(
        color: Color(0xFF2196F3),
        shape: BoxShape.circle,
      ),
    ),
  );

  static const Widget _largeMarker = SizedBox(
    width: 5.0,
    height: 5.0,
    child: DecoratedBox(
      decoration: BoxDecoration(
        color: Color(0xFF2196F3),
        shape: BoxShape.circle,
      ),
    ),
  );

  static const Widget _extraLargeMarker = SizedBox(
    width: 8.0,
    height: 8.0,
    child: DecoratedBox(
      decoration: BoxDecoration(
        color: Color(0xFF2196F3),
        shape: BoxShape.circle,
      ),
    ),
  );

  // List of markers and water stations data
  List<Marker> _markers = [];
  List<WaterStation> _waterStations = [];
  bool _markersLoading = false;

  // India boundary coordinates - will be loaded from GeoJSON
  List<List<LatLng>> _allIndiaBoundaries = [];
  bool _boundaryLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadIndiaBoundary();
    // Don't load markers in initState - wait for boundaries to load first
  }

  // Get appropriate marker widget based on zoom level
  Widget _getMarkerWidget(double zoom) {
    if (zoom < 5.0) {
      return _smallMarker;
    } else if (zoom < 8.0) {
      return _mediumMarker;
    } else if (zoom < 12.0) {
      return _largeMarker;
    } else {
      return _extraLargeMarker;
    }
  }

  // Get marker size values based on zoom level
  double _getMarkerSize(double zoom) {
    if (zoom < 5.0) {
      return 1.5;
    } else if (zoom < 8.0) {
      return 3.0;
    } else if (zoom < 12.0) {
      return 5.0;
    } else {
      return 8.0;
    }
  }

  // Handle map events, particularly zoom changes
  void _onMapEvent(MapEvent mapEvent) {
    if (mapEvent is MapEventMoveEnd) {
      final newZoom = _mapController.camera.zoom;
      if ((newZoom - _currentZoom).abs() > 0.5) {
        // Only update if significant zoom change
        _currentZoom = newZoom;
        _rebuildMarkersForZoom();
      }
    }
  }

  // Ultra-optimized marker rebuilding with clustering for performance
  void _rebuildMarkersForZoom() {
    if (_waterStations.isEmpty) return;

    final markerSize = _getMarkerSize(_currentZoom);
    List<Marker> newMarkers;

    // Use clustering for better performance at different zoom levels
    if (_currentZoom < 6.0) {
      // Show every 20th marker when zoomed out
      newMarkers = _buildClusteredMarkers(20, markerSize);
    } else if (_currentZoom < 9.0) {
      // Show every 5th marker at medium zoom
      newMarkers = _buildClusteredMarkers(5, markerSize);
    } else {
      // Show all markers when zoomed in
      newMarkers = _buildAllMarkers(markerSize);
    }

    setState(() {
      _markers = newMarkers;
    });
  }

  // Build clustered markers for performance
  List<Marker> _buildClusteredMarkers(int skipFactor, double markerSize) {
    final clusteredMarkers = <Marker>[];
    for (int i = 0; i < _waterStations.length; i += skipFactor) {
      final station = _waterStations[i];
      clusteredMarkers.add(
        Marker(
          point: station.position,
          width: markerSize,
          height: markerSize,
          child: GestureDetector(
            onTap: () => _showStationModal(station),
            behavior: HitTestBehavior.opaque,
            child: _getMarkerWidget(_currentZoom),
          ),
        ),
      );
    }
    return clusteredMarkers;
  }

  // Build all markers for high zoom levels
  List<Marker> _buildAllMarkers(double markerSize) {
    final allMarkers = <Marker>[];
    final markerWidget = _getMarkerWidget(_currentZoom);

    for (final station in _waterStations) {
      allMarkers.add(
        Marker(
          point: station.position,
          width: markerSize,
          height: markerSize,
          child: GestureDetector(
            onTap: () => _showStationModal(station),
            behavior: HitTestBehavior.opaque,
            child: markerWidget,
          ),
        ),
      );
    }
    return allMarkers;
  }

  // Optimized modal for station details
  void _showStationModal(WaterStation station) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => AlertDialog(
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.water_drop, color: Colors.blue, size: 20),
            SizedBox(width: 8),
            Text('Station Details', style: TextStyle(fontSize: 18)),
          ],
        ),
        content: SizedBox(
          width: 280,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow('Code:', station.stationCode),
              const SizedBox(height: 8),
              _buildDetailRow('Name:', station.stationName),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          FilledButton.icon(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => StationDetailsScreen(station: station),
                ),
              );
            },
            icon: const Icon(Icons.info_outline, size: 16),
            label: const Text('View Details'),
          ),
          FilledButton.icon(
            onPressed: () {
              _mapController.move(station.position, 12.0);
              _currentZoom = 12.0;
              _rebuildMarkersForZoom();
              Navigator.pop(context);
            },
            icon: const Icon(Icons.center_focus_strong, size: 16),
            label: const Text('Focus'),
          ),
        ],
      ),
    );
  }

  // Optimized detail row widget
  Widget _buildDetailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 60,
          child: Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.grey,
              fontSize: 14,
            ),
          ),
        ),
        Expanded(child: Text(value, style: const TextStyle(fontSize: 14))),
      ],
    );
  }

  Future<void> _initializeMarkers() async {
    setState(() {
      _markersLoading = true;
    });

    try {
      _waterStations = await WaterStationsService.loadWaterStations();

      // Generate markers efficiently with optimized approach
      _rebuildMarkersForZoom();

      setState(() {
        _markersLoading = false;
      });

      print('Created ${_markers.length} optimized water station markers');

      // Show success message
      if (mounted && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Successfully loaded water monitoring stations'),
            duration: Duration(seconds: 2),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('Error initializing markers: $e');
      setState(() {
        _markersLoading = false;
      });
    }
  }

  Future<void> _loadIndiaBoundary() async {
    try {
      final allPolygons = await GeoJsonService.loadIndiaBoundary();

      setState(() {
        _allIndiaBoundaries = allPolygons;
        _boundaryLoaded = true;
      });

      // Wait a moment for the UI to update and show the map, then start loading markers
      await Future.delayed(const Duration(milliseconds: 500));
      _initializeMarkers();
    } catch (e) {
      print('Error loading India boundary: $e');
      // Keep the empty boundary list as fallback
      setState(() {
        _boundaryLoaded = true; // Still allow the map to show
      });

      // Even if boundary loading fails, still try to load markers after delay
      await Future.delayed(const Duration(milliseconds: 500));
      _initializeMarkers();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Water Stations Map"),
        centerTitle: true,
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Column(
        children: [
          // Info panel
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16.0),
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: Text(
              !_boundaryLoaded
                  ? "Loading map boundaries..."
                  : _markersLoading
                  ? "Loading 31,574 water monitoring stations..."
                  : _markers.isEmpty
                  ? "Map ready - stations will load shortly"
                  : "Showing ${_markers.length}/31574 water monitoring stations across India (Zoom: ${_currentZoom.toStringAsFixed(1)})",
              style: const TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
          ),
          // Map
          Expanded(
            child: Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: _center,
                    initialZoom:
                        4.2, // Reduced zoom to show entire India including islands
                    minZoom: 3.5,
                    maxZoom: 18.0,
                    onMapEvent: _onMapEvent, // Add zoom change detection
                    interactionOptions: const InteractionOptions(
                      flags:
                          InteractiveFlag.pinchZoom |
                          InteractiveFlag.drag |
                          InteractiveFlag.doubleTapZoom,
                    ),
                  ),
                  children: [
                    // OpenStreetMap tile layer
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.example.water_monitor',
                      maxZoom: 19,
                    ),
                    // Dark overlay covering the world (only show when boundary is loaded)
                    if (_boundaryLoaded && _allIndiaBoundaries.isNotEmpty)
                      PolygonLayer(
                        polygons: [
                          Polygon(
                            points: [
                              const LatLng(85.0, -180.0), // World boundary
                              const LatLng(85.0, 180.0),
                              const LatLng(-85.0, 180.0),
                              const LatLng(-85.0, -180.0),
                            ],
                            holePointsList:
                                _allIndiaBoundaries, // Exclude all India polygons from overlay
                            color: Colors.black.withValues(alpha: 0.6),
                            borderColor: Colors.transparent,
                            borderStrokeWidth: 0,
                          ),
                        ],
                      ),
                    // India boundary highlights (only show when boundary is loaded)
                    if (_boundaryLoaded && _allIndiaBoundaries.isNotEmpty)
                      PolygonLayer(
                        polygons: _allIndiaBoundaries
                            .map(
                              (boundary) => Polygon(
                                points: boundary,
                                color: Colors.transparent,
                                borderColor: Colors.orange,
                                borderStrokeWidth: 3.0,
                              ),
                            )
                            .toList(),
                      ),
                    // Markers layer
                    MarkerLayer(markers: _markers),
                  ],
                ),
                // Loading indicator while boundary is loading (blocks whole map)
                if (!_boundaryLoaded)
                  Container(
                    color: Colors.black.withValues(alpha: 0.3),
                    child: const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(color: Colors.orange),
                          SizedBox(height: 16),
                          Text(
                            'Loading map boundaries...',
                            style: TextStyle(color: Colors.white, fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                  ),
                // Loading indicator for markers only (small overlay)
                if (_boundaryLoaded && _markersLoading)
                  Positioned(
                    top: 16,
                    right: 16,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              color: Colors.orange,
                              strokeWidth: 2,
                            ),
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Loading 31,574 stations...',
                            style: TextStyle(color: Colors.white, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton.small(
            heroTag: "zoom_in",
            onPressed: () {
              final currentZoom = _mapController.camera.zoom;
              final newZoom = currentZoom + 1;
              _mapController.move(_mapController.camera.center, newZoom);
              // Update zoom tracking for immediate marker resize
              _currentZoom = newZoom;
              _rebuildMarkersForZoom();
            },
            child: const Icon(Icons.zoom_in),
          ),
          const SizedBox(height: 8),
          FloatingActionButton.small(
            heroTag: "zoom_out",
            onPressed: () {
              final currentZoom = _mapController.camera.zoom;
              final newZoom = currentZoom - 1;
              _mapController.move(_mapController.camera.center, newZoom);
              // Update zoom tracking for immediate marker resize
              _currentZoom = newZoom;
              _rebuildMarkersForZoom();
            },
            child: const Icon(Icons.zoom_out),
          ),
          const SizedBox(height: 8),
          FloatingActionButton.small(
            heroTag: "center_map",
            onPressed: () {
              _currentZoom = 4.2;
              _mapController.move(
                _center,
                _currentZoom,
              ); // Zoom level to show entire India including islands
              _rebuildMarkersForZoom();
            },
            child: const Icon(Icons.my_location),
          ),
        ],
      ),
    );
  }
}

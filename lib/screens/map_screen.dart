import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../services/geojson_service.dart';
import '../services/water_stations_service.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();

  // Center point for India - Adjusted to show more of eastern India and islands
  final LatLng _center = const LatLng(20.0, 82.0);

  // List of markers - will be populated with water station coordinates later
  List<Marker> _markers = [];
  bool _isLoading = true;

  // India boundary coordinates - will be loaded from GeoJSON
  List<List<LatLng>> _allIndiaBoundaries = [];
  bool _boundaryLoaded = false;

  @override
  void initState() {
    super.initState();
    _initializeMarkers();
    _loadIndiaBoundary();
  }

  Future<void> _initializeMarkers() async {
    try {
      final waterStations = await WaterStationsService.loadWaterStations();

      setState(() {
        _markers = waterStations.map((station) {
          return Marker(
            point: station.position,
            width: 4.0, // Very small marker
            height: 4.0, // Very small marker
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.lightBlue,
                shape: BoxShape.circle,
              ),
            ),
          );
        }).toList();
        _isLoading = false;
      });

      print('Created ${_markers.length} water station markers');
    } catch (e) {
      print('Error initializing markers: $e');
      setState(() {
        _isLoading = false;
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
    } catch (e) {
      print('Error loading India boundary: $e');
      // Keep the empty boundary list as fallback
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
            child: const Text(
              "Water monitoring stations across India",
              style: TextStyle(fontSize: 16),
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
                // Loading indicator while boundary and markers are loading
                if (!_boundaryLoaded || _isLoading)
                  Container(
                    color: Colors.black.withValues(alpha: 0.3),
                    child: const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(color: Colors.orange),
                          SizedBox(height: 16),
                          Text(
                            'Loading map data...',
                            style: TextStyle(color: Colors.white, fontSize: 16),
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
              _mapController.move(
                _mapController.camera.center,
                currentZoom + 1,
              );
            },
            child: const Icon(Icons.zoom_in),
          ),
          const SizedBox(height: 8),
          FloatingActionButton.small(
            heroTag: "zoom_out",
            onPressed: () {
              final currentZoom = _mapController.camera.zoom;
              _mapController.move(
                _mapController.camera.center,
                currentZoom - 1,
              );
            },
            child: const Icon(Icons.zoom_out),
          ),
          const SizedBox(height: 8),
          FloatingActionButton.small(
            heroTag: "center_map",
            onPressed: () {
              _mapController.move(
                _center,
                4.2,
              ); // Zoom level to show entire India including islands
            },
            child: const Icon(Icons.my_location),
          ),
        ],
      ),
    );
  }
}

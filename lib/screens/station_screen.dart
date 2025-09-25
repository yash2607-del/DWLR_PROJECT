import 'package:flutter/material.dart';
import '../services/indiawris_service.dart';
import '../models/indiawris_models.dart';
import '../services/station_coordinates_service.dart';
import 'station_details_screen.dart';
import '../services/water_stations_service.dart';

class StationsScreen extends StatefulWidget {
  const StationsScreen({super.key});

  @override
  State<StationsScreen> createState() => _StationsScreenState();
}

class _StationsScreenState extends State<StationsScreen> {
  final TextEditingController _searchController = TextEditingController();

  // API data
  List<IndiaWRISState> _states = [];
  List<IndiaWRISDistrict> _districts = [];
  List<IndiaWRISStation> _allStations = [];
  List<IndiaWRISStation> _filteredStations = [];

  // Selected values
  IndiaWRISState? _selectedState;
  IndiaWRISDistrict? _selectedDistrict;

  // Loading states
  bool _isLoadingStates = false;
  bool _isLoadingDistricts = false;
  bool _isLoadingStations = false;
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _loadStates();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    // Only allow search if state and district are selected and stations are loaded
    if (_selectedState != null &&
        _selectedDistrict != null &&
        _allStations.isNotEmpty) {
      _performSearch(_searchController.text);
    }
  }

  Future<void> _loadStates() async {
    setState(() {
      _isLoadingStates = true;
    });

    try {
      final states = await IndiaWRISService.fetchStates();
      setState(() {
        _states = states;
        _isLoadingStates = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingStates = false;
      });
      _showErrorSnackBar('Failed to load states: $e');
    }
  }

  Future<void> _loadDistricts(String stateCode) async {
    setState(() {
      _isLoadingDistricts = true;
      _districts.clear();
      _selectedDistrict = null;
      _allStations.clear();
      _filteredStations.clear();
    });

    try {
      final districts = await IndiaWRISService.fetchDistricts(stateCode);
      setState(() {
        _districts = districts;
        _isLoadingDistricts = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingDistricts = false;
      });
      _showErrorSnackBar('Failed to load districts: $e');
    }
  }

  Future<void> _loadStations(String districtId) async {
    setState(() {
      _isLoadingStations = true;
      _allStations.clear();
      _filteredStations.clear();
    });

    try {
      final agencyId = IndiaWRISService.getDefaultAgencyId();
      final stations = await IndiaWRISService.fetchStations(
        districtId,
        agencyId,
      );
      setState(() {
        _allStations = stations;
        _filteredStations = stations;
        _isLoadingStations = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingStations = false;
      });
      _showErrorSnackBar('Failed to load stations: $e');
    }
  }

  void _performSearch(String query) {
    if (query.isEmpty) {
      setState(() {
        _filteredStations = _allStations;
        _isSearching = false;
      });
      return;
    }

    setState(() {
      _isSearching = true;
    });

    final lowerQuery = query.toLowerCase();
    final filtered = _allStations
        .where(
          (station) =>
              station.stationName.toLowerCase().contains(lowerQuery) ||
              station.stationCode.toLowerCase().contains(lowerQuery),
        )
        .toList();

    setState(() {
      _filteredStations = filtered;
      _isSearching = false;
    });
  }

  void _onStateSelected(IndiaWRISState? state) async {
    if (state == null) return;

    setState(() {
      _selectedState = state;
      _selectedDistrict = null;
      _allStations.clear();
      _filteredStations.clear();
      _searchController.clear();
    });

    await _loadDistricts(state.stateCode);
  }

  void _onDistrictSelected(IndiaWRISDistrict? district) async {
    if (district == null) return;

    setState(() {
      _selectedDistrict = district;
      _allStations.clear();
      _filteredStations.clear();
      _searchController.clear();
    });

    await _loadStations(district.districtId);
  }

  void _clearFilters() {
    setState(() {
      _selectedState = null;
      _selectedDistrict = null;
      _districts.clear();
      _allStations.clear();
      _filteredStations.clear();
      _searchController.clear();
    });
  }

  void _navigateToStationDetails(IndiaWRISStation station) async {
    // Try to get coordinates from the existing JSON file
    final coordinates = await StationCoordinatesService.getCoordinates(
      station.stationCode,
    );

    // Convert IndiaWRISStation to WaterStation for compatibility
    final waterStation = WaterStation(
      stationCode: station.stationCode,
      stationName: station.stationName,
      lat: coordinates?['lat'] ?? 0.0,
      long: coordinates?['long'] ?? 0.0,
    );

    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => StationDetailsScreen(station: waterStation),
        ),
      );
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Water Stations'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.clear_all),
            onPressed: _clearFilters,
            tooltip: 'Clear Filters',
          ),
        ],
      ),
      body: Column(
        children: [
          // Search and Filter Section
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withValues(alpha: 0.3),
                  spreadRadius: 1,
                  blurRadius: 3,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Search Bar (only enabled when state and district are selected)
                TextField(
                  controller: _searchController,
                  enabled:
                      _selectedState != null &&
                      _selectedDistrict != null &&
                      _allStations.isNotEmpty,
                  decoration: InputDecoration(
                    hintText:
                        _selectedState == null || _selectedDistrict == null
                        ? 'Select state and district first'
                        : 'Search stations by name or code',
                    prefixIcon: const Icon(Icons.search, color: Colors.blue),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: Colors.blue,
                        width: 2,
                      ),
                    ),
                    filled: true,
                    fillColor:
                        _selectedState == null || _selectedDistrict == null
                        ? Colors.grey[100]
                        : Colors.white,
                  ),
                ),
                const SizedBox(height: 16),

                // State and District Selection
                Row(
                  children: [
                    // State Dropdown
                    Expanded(
                      flex: 1,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: DropdownButton<IndiaWRISState>(
                          value: _selectedState,
                          hint: _isLoadingStates
                              ? const Row(
                                  children: [
                                    SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    ),
                                    SizedBox(width: 8),
                                    Text('Loading states...'),
                                  ],
                                )
                              : const Text('Select State'),
                          isExpanded: true,
                          underline: const SizedBox(),
                          items: _states.map((IndiaWRISState state) {
                            return DropdownMenuItem<IndiaWRISState>(
                              value: state,
                              child: Text(state.stateName),
                            );
                          }).toList(),
                          onChanged: _isLoadingStates ? null : _onStateSelected,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // District Dropdown
                    Expanded(
                      flex: 1,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _selectedState == null
                              ? Colors.grey[100]
                              : Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: DropdownButton<IndiaWRISDistrict>(
                          value: _selectedDistrict,
                          hint: _isLoadingDistricts
                              ? const Row(
                                  children: [
                                    SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    ),
                                    SizedBox(width: 8),
                                    Text('Loading districts...'),
                                  ],
                                )
                              : Text(
                                  _selectedState == null
                                      ? 'Select state first'
                                      : 'Select District',
                                ),
                          isExpanded: true,
                          underline: const SizedBox(),
                          items: _districts.map((IndiaWRISDistrict district) {
                            return DropdownMenuItem<IndiaWRISDistrict>(
                              value: district,
                              child: Text(district.districtName),
                            );
                          }).toList(),
                          onChanged:
                              (_selectedState == null || _isLoadingDistricts)
                              ? null
                              : _onDistrictSelected,
                        ),
                      ),
                    ),
                  ],
                ),

                // Results Count
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Showing ${_filteredStations.length} of ${_allStations.length} stations',
                      style: TextStyle(color: Colors.grey[600], fontSize: 14),
                    ),
                    if (_isSearching)
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                  ],
                ),
              ],
            ),
          ),

          // Stations List
          Expanded(
            child: _isLoadingStations
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Loading water stations...'),
                      ],
                    ),
                  )
                : _selectedState == null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.location_on_outlined,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Please select a state to continue',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  )
                : _selectedDistrict == null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.location_city_outlined,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Please select a district to load stations',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  )
                : _filteredStations.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.water_drop_outlined,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _searchController.text.isNotEmpty
                              ? 'No stations found matching your search'
                              : 'No water stations available in this district',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                        if (_searchController.text.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          TextButton(
                            onPressed: () => _searchController.clear(),
                            child: const Text('Clear search'),
                          ),
                        ],
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _filteredStations.length,
                    itemBuilder: (context, index) {
                      final station = _filteredStations[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(16),
                          leading: Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: Colors.blue[50],
                              borderRadius: BorderRadius.circular(25),
                            ),
                            child: const Icon(
                              Icons.water_drop,
                              color: Colors.blue,
                              size: 28,
                            ),
                          ),
                          title: Text(
                            station.stationName,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text(
                                'Code: ${station.stationCode}',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 2),
                              FutureBuilder<Map<String, double>?>(
                                future:
                                    StationCoordinatesService.getCoordinates(
                                      station.stationCode,
                                    ),
                                builder: (context, snapshot) {
                                  if (snapshot.hasData &&
                                      snapshot.data != null) {
                                    final coords = snapshot.data!;
                                    return Text(
                                      'Lat: ${coords['lat']!.toStringAsFixed(4)}, '
                                      'Long: ${coords['long']!.toStringAsFixed(4)}',
                                      style: TextStyle(
                                        color: Colors.grey[500],
                                        fontSize: 12,
                                      ),
                                    );
                                  } else {
                                    return Text(
                                      'Coordinates not available',
                                      style: TextStyle(
                                        color: Colors.grey[500],
                                        fontSize: 12,
                                      ),
                                    );
                                  }
                                },
                              ),
                            ],
                          ),
                          trailing: const Icon(
                            Icons.arrow_forward_ios,
                            color: Colors.grey,
                            size: 16,
                          ),
                          onTap: () => _navigateToStationDetails(station),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

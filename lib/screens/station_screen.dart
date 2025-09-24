import 'package:flutter/material.dart';
import '../services/water_stations_service.dart';
import 'station_details_screen.dart';

class StationsScreen extends StatefulWidget {
  const StationsScreen({super.key});

  @override
  State<StationsScreen> createState() => _StationsScreenState();
}

class _StationsScreenState extends State<StationsScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<WaterStation> _allStations = [];
  List<WaterStation> _filteredStations = [];
  
  // For state and district filtering - we'll extract these from station names
  List<String> _uniqueStates = [];
  List<String> _uniqueDistricts = [];
  String? _selectedState;
  String? _selectedDistrict;
  
  bool _isLoading = false;
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _loadWaterStations();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    _performSearch(_searchController.text);
  }

  Future<void> _loadWaterStations() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final stations = await WaterStationsService.loadWaterStations();
      setState(() {
        _allStations = stations;
        _filteredStations = stations;
        _isLoading = false;
      });
      
      // Extract unique states and districts from station names
      _extractLocationsFromStations();
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackBar('Failed to load water stations: $e');
    }
  }

  void _extractLocationsFromStations() {
    // Since we don't have explicit state/district data, we'll extract from station names
    // This is a simplified approach - in a real app, you'd have proper location data
    Set<String> states = <String>{};
    Set<String> districts = <String>{};
    
    for (final station in _allStations) {
      // Extract state/district info from station names if possible
      // This is a simplified heuristic approach
      final nameParts = station.stationName.toLowerCase().split(' ');
      
      // Look for common state indicators in station names
      for (final part in nameParts) {
        if (_isStateIndicator(part)) {
          states.add(_capitalizeFirst(part));
        }
        if (_isDistrictIndicator(part)) {
          districts.add(_capitalizeFirst(part));
        }
      }
    }
    
    setState(() {
      _uniqueStates = states.toList()..sort();
      _uniqueDistricts = districts.toList()..sort();
    });
  }

  bool _isStateIndicator(String word) {
    // Common state indicators in station names
    const stateIndicators = [
      'kerala', 'tamil', 'karnataka', 'andhra', 'telangana', 'maharashtra',
      'gujarat', 'rajasthan', 'madhya', 'uttar', 'bihar', 'west', 'odisha',
      'jharkhand', 'chhattisgarh', 'punjab', 'haryana', 'himachal', 'delhi',
      'goa', 'assam', 'tripura', 'meghalaya', 'manipur', 'nagaland', 'mizoram'
    ];
    return stateIndicators.contains(word);
  }

  bool _isDistrictIndicator(String word) {
    // Common district indicators - this is simplified
    const districtIndicators = [
      'district', 'city', 'town', 'municipal', 'corporation', 'taluk', 'tehsil'
    ];
    return districtIndicators.contains(word) || word.length > 4;
  }

  String _capitalizeFirst(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
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
    final filtered = _allStations.where((station) =>
        station.stationName.toLowerCase().contains(lowerQuery) ||
        station.stationCode.toLowerCase().contains(lowerQuery)).toList();

    setState(() {
      _filteredStations = filtered;
      _isSearching = false;
    });
  }

  void _applyStateFilter(String? state) {
    setState(() {
      _selectedState = state;
      _selectedDistrict = null; // Reset district when state changes
    });
    _applyFilters();
  }

  void _applyDistrictFilter(String? district) {
    setState(() {
      _selectedDistrict = district;
    });
    _applyFilters();
  }

  void _applyFilters() {
    List<WaterStation> filtered = _allStations;

    if (_selectedState != null) {
      filtered = filtered.where((station) =>
          station.stationName.toLowerCase().contains(_selectedState!.toLowerCase())).toList();
    }

    if (_selectedDistrict != null) {
      filtered = filtered.where((station) =>
          station.stationName.toLowerCase().contains(_selectedDistrict!.toLowerCase())).toList();
    }

    // Also apply search filter
    final searchQuery = _searchController.text;
    if (searchQuery.isNotEmpty) {
      final lowerQuery = searchQuery.toLowerCase();
      filtered = filtered.where((station) =>
          station.stationName.toLowerCase().contains(lowerQuery) ||
          station.stationCode.toLowerCase().contains(lowerQuery)).toList();
    }

    setState(() {
      _filteredStations = filtered;
    });
  }

  void _clearFilters() {
    setState(() {
      _selectedState = null;
      _selectedDistrict = null;
      _searchController.clear();
      _filteredStations = _allStations;
    });
  }

  void _navigateToStationDetails(WaterStation station) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => StationDetailsScreen(
          station: station,
        ),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
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
                  color: Colors.grey.withOpacity(0.3),
                  spreadRadius: 1,
                  blurRadius: 3,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Search Bar
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search stations by name or code',
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
                      borderSide: const BorderSide(color: Colors.blue, width: 2),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                
                // Filter Dropdowns
                Row(
                  children: [
                    // State Filter
                    Expanded(
                      flex: 1,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: DropdownButton<String>(
                          value: _selectedState,
                          hint: const Text('State'),
                          isExpanded: true,
                          underline: const SizedBox(),
                          items: _uniqueStates.map((String state) {
                            return DropdownMenuItem<String>(
                              value: state,
                              child: Text(state),
                            );
                          }).toList(),
                          onChanged: _applyStateFilter,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    
                    // District Filter
                    Expanded(
                      flex: 1,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: DropdownButton<String>(
                          value: _selectedDistrict,
                          hint: const Text('District'),
                          isExpanded: true,
                          underline: const SizedBox(),
                          items: _uniqueDistricts.map((String district) {
                            return DropdownMenuItem<String>(
                              value: district,
                              child: Text(district),
                            );
                          }).toList(),
                          onChanged: _applyDistrictFilter,
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
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
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
            child: _isLoading
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
                              _searchController.text.isNotEmpty || 
                              _selectedState != null || 
                              _selectedDistrict != null
                                  ? 'No stations found matching your criteria'
                                  : 'No water stations available',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextButton(
                              onPressed: _clearFilters,
                              child: const Text('Clear filters'),
                            ),
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
                                  Text(
                                    'Lat: ${station.lat.toStringAsFixed(4)}, '
                                    'Long: ${station.long.toStringAsFixed(4)}',
                                    style: TextStyle(
                                      color: Colors.grey[500],
                                      fontSize: 12,
                                    ),
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
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/indiawris_service.dart';
import '../models/indiawris_models.dart';

class ChartsScreen extends StatefulWidget {
  const ChartsScreen({super.key});

  @override
  State<ChartsScreen> createState() => _ChartsScreenState();
}

class _ChartsScreenState extends State<ChartsScreen> {
  final TextEditingController _searchController = TextEditingController();

  // API data
  List<IndiaWRISState> _states = [];
  List<IndiaWRISDistrict> _districts = [];
  List<IndiaWRISStation> _stations = [];

  // Selected values
  IndiaWRISState? _selectedState;
  IndiaWRISDistrict? _selectedDistrict;
  IndiaWRISStation? _selectedStation;

  // Loading states
  bool _isLoadingStates = false;
  bool _isLoadingDistricts = false;
  bool _isLoadingStations = false;
  bool _isLoadingChart = false;

  // Chart data
  List<FlSpot> _chartData = [];
  int _selectedMonth = DateTime.now().month;
  int _selectedYear = DateTime.now().year + 1; // Next year

  // Location info for display
  String _locationName = 'Select Location';
  String _locationType = '';

  @override
  void initState() {
    super.initState();
    _loadStates();
    _generateDummyChartData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
      _stations.clear();
      _selectedStation = null;
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
      _stations.clear();
      _selectedStation = null;
    });

    try {
      // Simulate API delay
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Use mock data for demonstration since API is failing
      final mockStations = [
        IndiaWRISStation(
          stationCode: 'CGW001',
          stationName: 'Central Ground Water Station',
          datasetCode: 'GWATERLVL',
          agencyId: '1',
          districtId: districtId,
          telemetric: true,
        ),
        IndiaWRISStation(
          stationCode: 'NDW002',
          stationName: 'North Delhi Monitoring Well',
          datasetCode: 'GWATERLVL',
          agencyId: '1',
          districtId: districtId,
          telemetric: true,
        ),
        IndiaWRISStation(
          stationCode: 'SDW003',
          stationName: 'South Delhi Water Station',
          datasetCode: 'GWATERLVL',
          agencyId: '1',
          districtId: districtId,
          telemetric: false,
        ),
      ];
      
      setState(() {
        _stations = mockStations;
        _isLoadingStations = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingStations = false;
      });
      _showErrorSnackBar('Failed to load stations: $e');
    }
  }

  void _updateLocationDisplay() {
    if (_selectedStation != null) {
      _locationName = _selectedStation!.stationName;
      _locationType = 'Station, ${_selectedDistrict?.districtName ?? ''}, ${_selectedState?.stateName ?? ''}';
    } else if (_selectedDistrict != null) {
      _locationName = _selectedDistrict!.districtName;
      _locationType = 'District, ${_selectedState?.stateName ?? ''}';
    } else if (_selectedState != null) {
      _locationName = _selectedState!.stateName;
      _locationType = 'State';
    } else {
      _locationName = 'Select Location';
      _locationType = '';
    }
  }

  void _generateDummyChartData() {
    // Generate dummy data for the selected month
    _chartData.clear();
    final daysInMonth = DateTime(_selectedYear, _selectedMonth + 1, 0).day;
    
    for (int day = 1; day <= daysInMonth; day++) {
      // Generate realistic water level data between -5.0 and -12.0 meters
      double value = -7.5 + (2.0 * (0.5 - (day % 7) / 14.0)) + 
                    (1.5 * (0.5 - (day % 3) / 6.0));
      _chartData.add(FlSpot(day.toDouble(), value));
    }
  }

  void _lookupTrends() {
    setState(() {
      _isLoadingChart = true;
    });

    // Simulate API call delay
    Future.delayed(const Duration(milliseconds: 800), () {
      setState(() {
        _generateDummyChartData();
        _isLoadingChart = false;
      });
    });
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
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Water Level Trends'),
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Location Display Section
            _buildLocationDisplay(),
            const SizedBox(height: 20),

            // Filter Section
            _buildFilterSection(),
            const SizedBox(height: 20),

            // Look Up Trends Button
            _buildLookupButton(),
            const SizedBox(height: 20),

            // Chart Section
            _buildChartSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationDisplay() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _locationName,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          if (_locationType.isNotEmpty)
            Text(
              _locationType,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFilterSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Filter Location',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),

          // State Dropdown
          _buildDropdown<IndiaWRISState>(
            label: 'Select State',
            value: _selectedState,
            items: _states,
            onChanged: (state) {
              setState(() {
                _selectedState = state;
                _selectedDistrict = null;
                _selectedStation = null;
                _updateLocationDisplay();
              });
              if (state != null) {
                _loadDistricts(state.stateCode);
              }
            },
            itemBuilder: (state) => Text(state.stateName),
            isLoading: _isLoadingStates,
          ),

          const SizedBox(height: 12),

          // District Dropdown
          _buildDropdown<IndiaWRISDistrict>(
            label: 'Select District',
            value: _selectedDistrict,
            items: _districts,
            onChanged: (district) {
              setState(() {
                _selectedDistrict = district;
                _selectedStation = null;
                _updateLocationDisplay();
              });
              if (district != null) {
                _loadStations(district.districtId);
              }
            },
            itemBuilder: (district) => Text(district.districtName),
            isLoading: _isLoadingDistricts,
            enabled: _selectedState != null,
          ),

          const SizedBox(height: 12),

          // Station Dropdown
          _buildDropdown<IndiaWRISStation>(
            label: 'Select Station (Optional)',
            value: _selectedStation,
            items: _stations,
            onChanged: (station) {
              setState(() {
                _selectedStation = station;
                _updateLocationDisplay();
              });
            },
            itemBuilder: (station) => Text(station.stationName),
            isLoading: _isLoadingStations,
            enabled: _selectedDistrict != null,
          ),

          const SizedBox(height: 16),

          // Timeline Selection
          Row(
            children: [
              Expanded(
                child: _buildDropdown<int>(
                  label: 'Select Month',
                  value: _selectedMonth,
                  items: List.generate(12, (index) => index + 1),
                  onChanged: (month) {
                    setState(() {
                      _selectedMonth = month!;
                      _generateDummyChartData();
                    });
                  },
                  itemBuilder: (month) => Text(_getMonthName(month)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 18),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Year: $_selectedYear',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown<T>({
    required String label,
    required T? value,
    required List<T> items,
    required ValueChanged<T?> onChanged,
    required Widget Function(T) itemBuilder,
    bool isLoading = false,
    bool enabled = true,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: enabled ? Colors.black87 : Colors.grey,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(8),
          ),
          child: isLoading
              ? const Padding(
                  padding: EdgeInsets.all(16),
                  child: SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              : DropdownButtonHideUnderline(
                  child: DropdownButton<T>(
                    value: value,
                    hint: Text('Select ${label.toLowerCase()}'),
                    isExpanded: true,
                    onChanged: enabled ? onChanged : null,
                    items: items.map((item) {
                      return DropdownMenuItem<T>(
                        value: item,
                        child: itemBuilder(item),
                      );
                    }).toList(),
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildLookupButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _selectedState != null ? _lookupTrends : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF1565C0),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: _isLoadingChart
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Text(
                'Look Up Trends',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }

  Widget _buildChartSection() {
    return Container(
      height: 300,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Water Level Trend (m) - ${_getMonthName(_selectedMonth)} $_selectedYear',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _chartData.isEmpty
                ? const Center(
                    child: Text(
                      'Select location and click "Look Up Trends" to view chart',
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                : LineChart(
                    LineChartData(
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: true,
                        horizontalInterval: 0.5,
                        verticalInterval: 5,
                        getDrawingHorizontalLine: (value) {
                          return FlLine(
                            color: Colors.grey[300],
                            strokeWidth: 1,
                          );
                        },
                        getDrawingVerticalLine: (value) {
                          return FlLine(
                            color: Colors.grey[300],
                            strokeWidth: 1,
                          );
                        },
                      ),
                      titlesData: FlTitlesData(
                        show: true,
                        rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 30,
                            interval: 5,
                            getTitlesWidget: (value, meta) {
                              return SideTitleWidget(
                                axisSide: meta.axisSide,
                                child: Text(
                                  '${value.toInt()}',
                                  style: const TextStyle(
                                    color: Colors.grey,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            interval: 1,
                            getTitlesWidget: (value, meta) {
                              return Text(
                                value.toStringAsFixed(1),
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              );
                            },
                            reservedSize: 42,
                          ),
                        ),
                      ),
                      borderData: FlBorderData(
                        show: true,
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      minX: 1,
                      maxX: _chartData.isNotEmpty ? _chartData.last.x : 31,
                      minY: -12,
                      maxY: -5,
                      lineBarsData: [
                        LineChartBarData(
                          spots: _chartData,
                          gradient: const LinearGradient(
                            colors: [Color(0xFF1565C0), Color(0xFF42A5F5)],
                          ),
                          barWidth: 3,
                          isStrokeCapRound: true,
                          dotData: FlDotData(
                            show: true,
                            getDotPainter: (spot, percent, barData, index) =>
                                FlDotCirclePainter(
                              radius: 4,
                              color: const Color(0xFF1565C0),
                              strokeWidth: 2,
                              strokeColor: Colors.white,
                            ),
                          ),
                          belowBarData: BarAreaData(
                            show: true,
                            gradient: LinearGradient(
                              colors: [
                                const Color(0xFF1565C0).withOpacity(0.3),
                                const Color(0xFF42A5F5).withOpacity(0.1),
                              ],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  String _getMonthName(int month) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return months[month - 1];
  }
}

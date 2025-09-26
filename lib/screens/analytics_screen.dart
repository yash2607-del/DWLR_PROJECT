import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/indiawris_service.dart';
import '../services/water_level_service.dart';
import '../models/indiawris_models.dart';

enum AnalysisType {
  districts('Analyse districts within a state'),
  stations('Analyse stations within a district');

  const AnalysisType(this.displayName);
  final String displayName;
}

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  // Analysis type selection
  AnalysisType? _selectedAnalysisType;

  // API data
  List<IndiaWRISState> _states = [];
  List<IndiaWRISDistrict> _districts = [];
  List<IndiaWRISStation> _stations = [];

  // Selected values
  IndiaWRISState? _selectedState;
  IndiaWRISDistrict? _selectedDistrict;

  // Multi-select data
  List<IndiaWRISDistrict> _selectedDistricts = [];
  List<IndiaWRISStation> _selectedStations = [];

  // Loading states
  bool _isLoadingStates = false;
  bool _isLoadingDistricts = false;
  bool _isLoadingStations = false;
  bool _isLoadingData = false;

  // Date selection for stations analysis
  DateTime? _startDate;
  DateTime? _endDate;
  String? _dateErrorMessage;

  // Chart data
  Map<IndiaWRISStation, List<TimeSeriesDataPoint>> _stationData = {};
  bool _showAverageView = false;

  @override
  void initState() {
    super.initState();
    _loadStates();
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
      _selectedDistricts.clear();
      _stations.clear();
      _selectedStations.clear();
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
      _selectedStations.clear();
    });

    try {
      final agencyId = IndiaWRISService.getDefaultAgencyId();
      final stations = await IndiaWRISService.fetchStations(
        districtId,
        agencyId,
      );
      setState(() {
        _stations = stations;
        _isLoadingStations = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingStations = false;
      });
      _showErrorSnackBar('Failed to load stations: $e');
    }
  }

  void _onAnalysisTypeChanged(AnalysisType? type) {
    setState(() {
      _selectedAnalysisType = type;
      _selectedState = null;
      _selectedDistrict = null;
      _districts.clear();
      _stations.clear();
      _selectedDistricts.clear();
      _selectedStations.clear();
    });
  }

  void _onStateSelected(IndiaWRISState? state) async {
    if (state == null) return;

    setState(() {
      _selectedState = state;
      _selectedDistrict = null;
      _selectedDistricts.clear();
      _stations.clear();
      _selectedStations.clear();
    });

    await _loadDistricts(state.stateCode);
  }

  void _onDistrictSelected(IndiaWRISDistrict? district) async {
    if (district == null) return;

    setState(() {
      _selectedDistrict = district;
      _selectedStations.clear();
    });

    await _loadStations(district.districtId);
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  // Data fetching methods
  Future<void> _fetchStationData() async {
    if (_selectedStations.isEmpty || _startDate == null || _endDate == null) {
      return;
    }

    setState(() {
      _isLoadingData = true;
      _dateErrorMessage = null;
      _stationData.clear();
    });

    try {
      for (final station in _selectedStations) {
        final data = await WaterLevelService.fetchCustomRangeData(
          station.stationCode,
          _startDate!,
          _endDate!,
        );
        if (data.isNotEmpty) {
          _stationData[station] = data;
        }
      }
      setState(() {
        _isLoadingData = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingData = false;
        _dateErrorMessage = 'Failed to fetch station data: $e';
      });
    }
  }

  // Data aggregation methods (copied from station_details_screen.dart)
  List<TimeSeriesDataPoint> _aggregateDataPoints(
    List<TimeSeriesDataPoint> data,
  ) {
    if (data.isEmpty) return data;

    // Sort data by date first
    final sortedData = List<TimeSeriesDataPoint>.from(data)
      ..sort((a, b) => a.dateTime.compareTo(b.dateTime));

    // STEP 1: Always group by day first to ensure no multiple points per day
    final dailyGroupedData = _groupByDay(sortedData);

    // Calculate date range from daily grouped data
    final firstDate = dailyGroupedData.first.dateTime;
    final lastDate = dailyGroupedData.last.dateTime;
    final daysDifference = lastDate.difference(firstDate).inDays;

    // STEP 2: Apply additional grouping based on date range
    if (daysDifference < 10) {
      // Less than 10 days - return daily grouped data
      return dailyGroupedData;
    } else if (daysDifference <= 60) {
      // 10 days to 2 months - return daily grouped data (already grouped by day)
      return dailyGroupedData;
    } else if (daysDifference <= 365) {
      // 2 months to 1 year - group daily data by week
      return _groupByWeek(dailyGroupedData);
    } else {
      // More than 1 year - group daily data by month
      return _groupByMonth(dailyGroupedData);
    }
  }

  List<TimeSeriesDataPoint> _groupByDay(List<TimeSeriesDataPoint> data) {
    final Map<String, List<TimeSeriesDataPoint>> groupedData = {};

    for (final point in data) {
      final dayKey =
          '${point.dateTime.year}-${point.dateTime.month.toString().padLeft(2, '0')}-${point.dateTime.day.toString().padLeft(2, '0')}';
      if (!groupedData.containsKey(dayKey)) {
        groupedData[dayKey] = [];
      }
      groupedData[dayKey]!.add(point);
    }

    return groupedData.entries.map((entry) {
      final dayData = entry.value;
      final averageValue = _calculateAverage(dayData);
      final representativeDate = dayData.first.dateTime;

      return TimeSeriesDataPoint(
        dateTime: DateTime(
          representativeDate.year,
          representativeDate.month,
          representativeDate.day,
          12,
        ), // Use noon as representative time
        dataValue: averageValue.toStringAsFixed(2),
        unitCode: dayData.first.unitCode,
        dataTypeDescription: dayData.first.dataTypeDescription,
      );
    }).toList()..sort((a, b) => a.dateTime.compareTo(b.dateTime));
  }

  List<TimeSeriesDataPoint> _groupByWeek(List<TimeSeriesDataPoint> data) {
    final Map<int, List<TimeSeriesDataPoint>> groupedData = {};

    for (final point in data) {
      // Calculate week number since epoch
      final daysSinceEpoch = point.dateTime
          .difference(DateTime(1970, 1, 1))
          .inDays;
      final weekNumber = daysSinceEpoch ~/ 7;

      if (!groupedData.containsKey(weekNumber)) {
        groupedData[weekNumber] = [];
      }
      groupedData[weekNumber]!.add(point);
    }

    return groupedData.entries.map((entry) {
      final weekData = entry.value;
      final averageValue = _calculateAverage(weekData);
      // Use the middle of the week as representative date
      final firstDate = weekData.first.dateTime;
      final weekStart = firstDate.subtract(
        Duration(days: firstDate.weekday - 1),
      );
      final representativeDate = weekStart.add(Duration(days: 3)); // Wednesday

      return TimeSeriesDataPoint(
        dateTime: representativeDate,
        dataValue: averageValue.toStringAsFixed(2),
        unitCode: weekData.first.unitCode,
        dataTypeDescription: weekData.first.dataTypeDescription,
      );
    }).toList()..sort((a, b) => a.dateTime.compareTo(b.dateTime));
  }

  List<TimeSeriesDataPoint> _groupByMonth(List<TimeSeriesDataPoint> data) {
    final Map<String, List<TimeSeriesDataPoint>> groupedData = {};

    for (final point in data) {
      final monthKey =
          '${point.dateTime.year}-${point.dateTime.month.toString().padLeft(2, '0')}';
      if (!groupedData.containsKey(monthKey)) {
        groupedData[monthKey] = [];
      }
      groupedData[monthKey]!.add(point);
    }

    return groupedData.entries.map((entry) {
      final monthData = entry.value;
      final averageValue = _calculateAverage(monthData);
      final firstDate = monthData.first.dateTime;
      final representativeDate = DateTime(
        firstDate.year,
        firstDate.month,
        15,
      ); // Use middle of month

      return TimeSeriesDataPoint(
        dateTime: representativeDate,
        dataValue: averageValue.toStringAsFixed(2),
        unitCode: monthData.first.unitCode,
        dataTypeDescription: monthData.first.dataTypeDescription,
      );
    }).toList()..sort((a, b) => a.dateTime.compareTo(b.dateTime));
  }

  double _calculateAverage(List<TimeSeriesDataPoint> dataPoints) {
    double sum = 0.0;
    int validCount = 0;

    for (final point in dataPoints) {
      final value = double.tryParse(point.dataValue);
      if (value != null && !value.isNaN) {
        sum += value;
        validCount++;
      }
    }

    return validCount > 0 ? sum / validCount : 0.0;
  }

  // Date selection methods
  Future<void> _selectStartDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate:
          _startDate ?? DateTime.now().subtract(const Duration(days: 30)),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      helpText: 'Select Start Date',
      cancelText: 'Cancel',
      confirmText: 'Select',
    );
    if (picked != null && picked != _startDate) {
      setState(() {
        _startDate = picked;
        _dateErrorMessage = null;
        _stationData.clear();
      });
    }
  }

  Future<void> _selectEndDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _endDate ?? DateTime.now(),
      firstDate: _startDate ?? DateTime(2000),
      lastDate: DateTime.now(),
      helpText: 'Select End Date',
      cancelText: 'Cancel',
      confirmText: 'Select',
    );
    if (picked != null && picked != _endDate) {
      setState(() {
        _endDate = picked;
        _dateErrorMessage = null;
        _stationData.clear();
      });
    }
  }

  String _formatDateOnly(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}-${date.month.toString().padLeft(2, '0')}-${date.year}';
  }

  // Helper method to group data by day and calculate daily averages
  List<TimeSeriesDataPoint> _groupDataByDay(
    List<TimeSeriesDataPoint> dataPoints,
  ) {
    if (dataPoints.isEmpty) return [];

    // Sort data points by date
    dataPoints.sort((a, b) => a.dateTime.compareTo(b.dateTime));

    // Group by day (ignoring time)
    final Map<String, List<TimeSeriesDataPoint>> dayGroups = {};

    for (final point in dataPoints) {
      final dayKey =
          '${point.dateTime.year}-${point.dateTime.month.toString().padLeft(2, '0')}-${point.dateTime.day.toString().padLeft(2, '0')}';
      dayGroups.putIfAbsent(dayKey, () => []).add(point);
    }

    // Calculate daily averages
    final List<TimeSeriesDataPoint> dailyAverages = [];
    dayGroups.forEach((dayKey, points) {
      final avgValue = _calculateAverage(points);
      // Use noon time for the daily average point for better chart representation
      final dayDate = DateTime.parse('$dayKey 12:00:00');
      // Use the unitCode from the first point (all points should have same unitCode)
      final unitCode = points.isNotEmpty ? points.first.unitCode : '';
      dailyAverages.add(
        TimeSeriesDataPoint(
          dateTime: dayDate,
          dataValue: avgValue.toString(),
          unitCode: unitCode,
        ),
      );
    });

    return dailyAverages;
  }

  // Method to create time-period averages across all stations
  List<TimeSeriesDataPoint> _createTimePeriodAverages() {
    if (_stationData.isEmpty) return [];

    // Collect all data points from all stations
    final allDataPoints = <TimeSeriesDataPoint>[];
    _stationData.values.forEach((data) => allDataPoints.addAll(data));

    if (allDataPoints.isEmpty) return [];

    // STEP 1: Always group by day first to calculate daily averages
    final dailyAveragedData = _groupDataByDay(allDataPoints);

    // STEP 2: Apply additional time period grouping if needed based on date range
    if (dailyAveragedData.isEmpty) return [];

    final rangeFirstDate = dailyAveragedData.first.dateTime;
    final rangeLastDate = dailyAveragedData.last.dateTime;
    final rangeDaysDifference = rangeLastDate.difference(rangeFirstDate).inDays;

    // For short time ranges (less than 10 days), return daily averages directly
    if (rangeDaysDifference < 10) {
      return dailyAveragedData;
    }

    // For longer ranges, apply additional grouping (weekly/monthly) to the daily averaged data
    Map<String, List<TimeSeriesDataPoint>> groupedData = {};

    if (rangeDaysDifference <= 60) {
      // 10-60 days - return daily averages (already calculated)
      return dailyAveragedData;
    } else if (rangeDaysDifference <= 365) {
      // 2 months to 1 year - group daily averages by week
      for (final point in dailyAveragedData) {
        final daysSinceEpoch = point.dateTime
            .difference(DateTime(1970, 1, 1))
            .inDays;
        final weekNumber = daysSinceEpoch ~/ 7;
        final weekKey = 'week_$weekNumber';
        if (!groupedData.containsKey(weekKey)) {
          groupedData[weekKey] = [];
        }
        groupedData[weekKey]!.add(point);
      }
    } else {
      // More than 1 year - group daily averages by month
      for (final point in dailyAveragedData) {
        final monthKey =
            '${point.dateTime.year}-${point.dateTime.month.toString().padLeft(2, '0')}';
        if (!groupedData.containsKey(monthKey)) {
          groupedData[monthKey] = [];
        }
        groupedData[monthKey]!.add(point);
      }
    }

    // Calculate averages for each time period
    final averagedData = <TimeSeriesDataPoint>[];

    groupedData.forEach((timeKey, dataPoints) {
      if (dataPoints.isNotEmpty) {
        final averageValue = _calculateAverage(dataPoints);
        final representativeDate = _getRepresentativeDate(
          timeKey,
          dataPoints,
          rangeDaysDifference,
        );
        final firstPoint = dataPoints.first;

        averagedData.add(
          TimeSeriesDataPoint(
            dateTime: representativeDate,
            dataValue: averageValue.toStringAsFixed(2),
            unitCode: firstPoint.unitCode,
            dataTypeDescription:
                'Average across ${_stationData.length} stations',
          ),
        );
      }
    });

    // Sort by date and return
    averagedData.sort((a, b) => a.dateTime.compareTo(b.dateTime));
    return averagedData;
  }

  DateTime _getRepresentativeDate(
    String timeKey,
    List<TimeSeriesDataPoint> dataPoints,
    int daysDifference,
  ) {
    final firstPoint = dataPoints.first;

    if (daysDifference < 10) {
      // For hourly grouping, use the hour as representative time
      return DateTime(
        firstPoint.dateTime.year,
        firstPoint.dateTime.month,
        firstPoint.dateTime.day,
        firstPoint.dateTime.hour,
        30, // Use middle of hour
      );
    } else if (daysDifference <= 60) {
      // For daily grouping, use noon as representative time
      return DateTime(
        firstPoint.dateTime.year,
        firstPoint.dateTime.month,
        firstPoint.dateTime.day,
        12,
      );
    } else if (daysDifference <= 365) {
      // For weekly grouping, use Wednesday of the week
      final weekStart = firstPoint.dateTime.subtract(
        Duration(days: firstPoint.dateTime.weekday - 1),
      );
      return weekStart.add(Duration(days: 3)); // Wednesday
    } else {
      // For monthly grouping, use middle of month
      return DateTime(firstPoint.dateTime.year, firstPoint.dateTime.month, 15);
    }
  }

  String _getChartAxisLabel(int index, bool isAverageView) {
    if (isAverageView) {
      final averagedData = _createTimePeriodAverages();
      if (index >= 0 && index < averagedData.length) {
        final date = averagedData[index].dateTime;
        return '${date.day}/${date.month}';
      }
    } else if (_stationData.isNotEmpty) {
      final firstStationData = _stationData.values.first;
      final aggregatedData = _aggregateDataPoints(firstStationData);
      if (index >= 0 && index < aggregatedData.length) {
        final date = aggregatedData[index].dateTime;
        return '${date.day}/${date.month}';
      }
    }
    return '';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            const Text(
              'Water Level Analytics',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Analyze water level data across different regions',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),

            // Analysis Type Selection
            _buildAnalysisTypeDropdown(),
            const SizedBox(height: 24),

            // Conditional UI based on analysis type
            if (_selectedAnalysisType == AnalysisType.districts)
              _buildDistrictsAnalysisUI()
            else if (_selectedAnalysisType == AnalysisType.stations)
              _buildStationsAnalysisUI(),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalysisTypeDropdown() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Select Analysis Type',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: DropdownButton<AnalysisType>(
                value: _selectedAnalysisType,
                hint: const Text('Choose analysis type'),
                isExpanded: true,
                underline: const SizedBox(),
                items: AnalysisType.values.map((AnalysisType type) {
                  return DropdownMenuItem<AnalysisType>(
                    value: type,
                    child: Text(type.displayName),
                  );
                }).toList(),
                onChanged: _onAnalysisTypeChanged,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDistrictsAnalysisUI() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Districts Analysis',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),

            // State Dropdown
            _buildStateDropdown(),
            if (_selectedState != null) ...[
              const SizedBox(height: 16),
              _buildMultiSelectDistrictsDropdown(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStationsAnalysisUI() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Stations Analysis',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),

            // State Dropdown
            _buildStateDropdown(),
            if (_selectedState != null) ...[
              const SizedBox(height: 16),
              _buildSingleDistrictDropdown(),
            ],
            if (_selectedDistrict != null) ...[
              const SizedBox(height: 16),
              _buildMultiSelectStationsDropdown(),
              if (_selectedStations.isNotEmpty) ...[
                const SizedBox(height: 20),
                _buildDateSelectionSection(),
                const SizedBox(height: 16),
                _buildAnalysisSection(),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStateDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Select State',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: DropdownButton<IndiaWRISState>(
            value: _selectedState,
            hint: _isLoadingStates
                ? const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      SizedBox(width: 8),
                      Text('Loading states...'),
                    ],
                  )
                : const Text('Select a state'),
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
      ],
    );
  }

  Widget _buildSingleDistrictDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Select District',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: DropdownButton<IndiaWRISDistrict>(
            value: _selectedDistrict,
            hint: _isLoadingDistricts
                ? const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      SizedBox(width: 8),
                      Text('Loading districts...'),
                    ],
                  )
                : const Text('Select a district'),
            isExpanded: true,
            underline: const SizedBox(),
            items: _districts.map((IndiaWRISDistrict district) {
              return DropdownMenuItem<IndiaWRISDistrict>(
                value: district,
                child: Text(district.districtName),
              );
            }).toList(),
            onChanged: _isLoadingDistricts ? null : _onDistrictSelected,
          ),
        ),
      ],
    );
  }

  Widget _buildMultiSelectDistrictsDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Select Districts',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
            Text(
              '${_selectedDistricts.length} selected',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (_isLoadingDistricts)
          const Center(child: CircularProgressIndicator())
        else if (_districts.isNotEmpty)
          MultiSelectDropdown<IndiaWRISDistrict>(
            items: _districts,
            selectedItems: _selectedDistricts,
            displayStringForItem: (district) => district.districtName,
            onSelectionChanged: (selectedDistricts) {
              setState(() {
                _selectedDistricts = selectedDistricts;
              });
            },
          ),
      ],
    );
  }

  Widget _buildMultiSelectStationsDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Select Stations',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
            Text(
              '${_selectedStations.length} selected',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (_isLoadingStations)
          const Center(child: CircularProgressIndicator())
        else if (_stations.isNotEmpty)
          MultiSelectDropdown<IndiaWRISStation>(
            items: _stations,
            selectedItems: _selectedStations,
            displayStringForItem: (station) => station.stationName,
            onSelectionChanged: (selectedStations) {
              setState(() {
                _selectedStations = selectedStations;
              });
            },
          ),
      ],
    );
  }

  Widget _buildDateSelectionSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Select Date Range',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),

            // Date selectors in column layout for better mobile experience
            Column(
              children: [
                // Start Date
                Container(
                  width: double.infinity,
                  child: InkWell(
                    onTap: _selectStartDate,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: _startDate != null
                              ? Colors.blue.shade300
                              : Colors.grey.shade300,
                          width: _startDate != null ? 2 : 1,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        color: _startDate != null
                            ? Colors.blue.shade50
                            : Colors.grey.shade50,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Start Date',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: _startDate != null
                                  ? Colors.blue.shade700
                                  : Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(
                                Icons.calendar_today_rounded,
                                size: 18,
                                color: _startDate != null
                                    ? Colors.blue.shade600
                                    : Colors.grey.shade500,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                _startDate != null
                                    ? _formatDateOnly(_startDate!)
                                    : 'Tap to select start date',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                  color: _startDate != null
                                      ? Colors.blue.shade700
                                      : Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // End Date
                Container(
                  width: double.infinity,
                  child: InkWell(
                    onTap: _selectEndDate,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: _endDate != null
                              ? Colors.blue.shade300
                              : Colors.grey.shade300,
                          width: _endDate != null ? 2 : 1,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        color: _endDate != null
                            ? Colors.blue.shade50
                            : Colors.grey.shade50,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'End Date',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: _endDate != null
                                  ? Colors.blue.shade700
                                  : Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(
                                Icons.calendar_today_rounded,
                                size: 18,
                                color: _endDate != null
                                    ? Colors.blue.shade600
                                    : Colors.grey.shade500,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                _endDate != null
                                    ? _formatDateOnly(_endDate!)
                                    : 'Tap to select end date',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                  color: _endDate != null
                                      ? Colors.blue.shade700
                                      : Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),

            // Error message
            if (_dateErrorMessage != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.error_outline,
                      color: Colors.red.shade600,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _dateErrorMessage!,
                        style: TextStyle(
                          color: Colors.red.shade700,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Analyze button
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed:
                    (_startDate != null && _endDate != null && !_isLoadingData)
                    ? _fetchStationData
                    : null,
                icon: _isLoadingData
                    ? SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                    : const Icon(Icons.analytics),
                label: Text(
                  _isLoadingData ? 'Loading Data...' : 'Analyze Stations',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalysisSection() {
    if (_stationData.isEmpty && !_isLoadingData) {
      return const SizedBox.shrink();
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with controls
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Station Analysis',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                ),
                // Legend button
                IconButton(
                  onPressed: _showLegendModal,
                  icon: const Icon(Icons.info_outline),
                  tooltip: 'Show Legend',
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.blue.shade50,
                    foregroundColor: Colors.blue.shade700,
                  ),
                ),
                const SizedBox(width: 8),
                // Average toggle
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Avg',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    Switch(
                      value: _showAverageView,
                      onChanged: (value) {
                        setState(() {
                          _showAverageView = value;
                        });
                      },
                      activeColor: Colors.blue,
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Chart
            if (_stationData.isNotEmpty)
              _buildMultiStationChart()
            else if (_isLoadingData)
              const SizedBox(
                height: 200,
                child: Center(child: CircularProgressIndicator()),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMultiStationChart() {
    final colors = [
      Colors.blue,
      Colors.red,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.brown,
      Colors.pink,
      Colors.indigo,
      Colors.cyan,
    ];

    // Prepare chart data
    List<LineChartBarData> lineBarsData = [];

    if (_showAverageView) {
      // Show time-period averages across all stations
      final averagedData = _createTimePeriodAverages();

      if (averagedData.isNotEmpty) {
        final spots = <FlSpot>[];

        for (int i = 0; i < averagedData.length; i++) {
          final value = double.tryParse(averagedData[i].dataValue) ?? 0.0;
          spots.add(FlSpot(i.toDouble(), value));
        }

        lineBarsData.add(
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: Colors.blue,
            barWidth: 3,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) {
                return FlDotCirclePainter(
                  radius: 4,
                  color: Colors.blue,
                  strokeWidth: 2,
                  strokeColor: Colors.white,
                );
              },
            ),
            belowBarData: BarAreaData(
              show: true,
              color: Colors.blue.withOpacity(0.1),
            ),
          ),
        );
      }
    } else {
      // Show individual station lines
      int colorIndex = 0;
      _stationData.forEach((station, data) {
        if (data.isNotEmpty) {
          final aggregatedData = _aggregateDataPoints(data);
          final spots = <FlSpot>[];

          for (int i = 0; i < aggregatedData.length; i++) {
            final value = double.tryParse(aggregatedData[i].dataValue) ?? 0.0;
            spots.add(FlSpot(i.toDouble(), value));
          }

          lineBarsData.add(
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: colors[colorIndex % colors.length],
              barWidth: 2,
              dotData: FlDotData(show: false),
            ),
          );
          colorIndex++;
        }
      });
    }

    if (lineBarsData.isEmpty) {
      return Container(
        height: 200,
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: const Center(child: Text('No data to display')),
      );
    }

    // Calculate Y-axis range
    final allValues = lineBarsData
        .expand((lineData) => lineData.spots)
        .map((spot) => spot.y)
        .toList();

    if (allValues.isEmpty) {
      return Container(
        height: 200,
        child: const Center(child: Text('No valid data points')),
      );
    }

    final minY = allValues.reduce((a, b) => a < b ? a : b);
    final maxY = allValues.reduce((a, b) => a > b ? a : b);
    final range = maxY - minY;
    final padding = range * 0.1;

    return Container(
      height: 400,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      padding: const EdgeInsets.all(16),
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: true,
            horizontalInterval: range > 0 ? range / 5 : 1,
            getDrawingHorizontalLine: (value) {
              return FlLine(color: Colors.grey.shade300, strokeWidth: 1);
            },
            getDrawingVerticalLine: (value) {
              return FlLine(color: Colors.grey.shade300, strokeWidth: 1);
            },
          ),
          titlesData: FlTitlesData(
            show: true,
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                interval: lineBarsData.first.spots.length > 6
                    ? lineBarsData.first.spots.length / 4
                    : 1,
                getTitlesWidget: (double value, TitleMeta meta) {
                  final label = _getChartAxisLabel(
                    value.toInt(),
                    _showAverageView,
                  );
                  return Text(
                    label,
                    style: const TextStyle(fontSize: 10, color: Colors.grey),
                  );
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 42,
                getTitlesWidget: (double value, TitleMeta meta) {
                  return Text(
                    value.toStringAsFixed(1),
                    style: const TextStyle(fontSize: 10, color: Colors.grey),
                  );
                },
              ),
            ),
          ),
          borderData: FlBorderData(
            show: true,
            border: Border.all(color: Colors.grey.shade400, width: 1),
          ),
          minY: minY - padding,
          maxY: maxY + padding,
          lineBarsData: lineBarsData,
          lineTouchData: LineTouchData(
            enabled: true,
            touchTooltipData: LineTouchTooltipData(
              getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
                return touchedBarSpots.map((barSpot) {
                  final index = barSpot.x.toInt();
                  String tooltipText = '';

                  if (_showAverageView) {
                    final averagedData = _createTimePeriodAverages();
                    if (index >= 0 && index < averagedData.length) {
                      final dataPoint = averagedData[index];
                      tooltipText =
                          'Avg: ${dataPoint.dataValue} ${dataPoint.unitCode}\n${_formatDateOnly(dataPoint.dateTime)}\n${_stationData.length} stations';
                    }
                  } else {
                    // For individual station lines, show station name
                    final stationIndex = touchedBarSpots.indexOf(barSpot);
                    if (stationIndex < _stationData.length) {
                      final station = _stationData.keys.elementAt(stationIndex);
                      final stationData = _stationData[station]!;
                      final aggregatedData = _aggregateDataPoints(stationData);
                      if (index >= 0 && index < aggregatedData.length) {
                        final dataPoint = aggregatedData[index];
                        tooltipText =
                            '${station.stationName}\n${dataPoint.dataValue} ${dataPoint.unitCode}\n${_formatDateOnly(dataPoint.dateTime)}';
                      }
                    }
                  }

                  return LineTooltipItem(
                    tooltipText,
                    const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  );
                }).toList();
              },
            ),
          ),
        ),
      ),
    );
  }

  void _showLegendModal() {
    final colors = [
      Colors.blue,
      Colors.red,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.brown,
      Colors.pink,
      Colors.indigo,
      Colors.cyan,
    ];

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Chart Legend'),
          content: Container(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_showAverageView)
                  ListTile(
                    leading: Container(
                      width: 20,
                      height: 3,
                      color: Colors.blue,
                    ),
                    title: Text(
                      'Average across ${_stationData.length} stations',
                    ),
                    subtitle: const Text('Grouped by time periods'),
                    dense: true,
                  )
                else
                  ...List.generate(_stationData.length, (index) {
                    final station = _stationData.keys.elementAt(index);
                    final color = colors[index % colors.length];
                    return ListTile(
                      leading: Container(width: 20, height: 3, color: color),
                      title: Text(
                        station.stationName,
                        style: const TextStyle(fontSize: 14),
                        overflow: TextOverflow.ellipsis,
                      ),
                      dense: true,
                    );
                  }),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }
}

// Generic multi-select dropdown widget
class MultiSelectDropdown<T> extends StatefulWidget {
  final List<T> items;
  final List<T> selectedItems;
  final String Function(T) displayStringForItem;
  final Function(List<T>) onSelectionChanged;

  const MultiSelectDropdown({
    super.key,
    required this.items,
    required this.selectedItems,
    required this.displayStringForItem,
    required this.onSelectionChanged,
  });

  @override
  State<MultiSelectDropdown<T>> createState() => _MultiSelectDropdownState<T>();
}

class _MultiSelectDropdownState<T> extends State<MultiSelectDropdown<T>> {
  bool _isExpanded = false;

  bool get _isAllSelected => widget.selectedItems.length == widget.items.length;

  void _toggleSelectAll() {
    if (_isAllSelected) {
      widget.onSelectionChanged([]);
    } else {
      widget.onSelectionChanged(List.from(widget.items));
    }
  }

  void _toggleItem(T item) {
    final selectedItems = List<T>.from(widget.selectedItems);
    if (selectedItems.contains(item)) {
      selectedItems.remove(item);
    } else {
      selectedItems.add(item);
    }
    widget.onSelectionChanged(selectedItems);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        children: [
          // Header with expand/collapse
          InkWell(
            onTap: () {
              setState(() {
                _isExpanded = !_isExpanded;
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      widget.selectedItems.isEmpty
                          ? 'Select items'
                          : '${widget.selectedItems.length} item${widget.selectedItems.length == 1 ? '' : 's'} selected',
                      style: TextStyle(
                        color: widget.selectedItems.isEmpty
                            ? Colors.grey[600]
                            : Colors.black87,
                      ),
                    ),
                  ),
                  Icon(
                    _isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: Colors.grey[600],
                  ),
                ],
              ),
            ),
          ),

          // Expandable content
          if (_isExpanded) ...[
            const Divider(height: 1),
            Container(
              constraints: const BoxConstraints(maxHeight: 300),
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    // Select All option
                    CheckboxListTile(
                      title: Text(
                        'Select All (${widget.items.length})',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      value: _isAllSelected,
                      onChanged: (bool? value) {
                        _toggleSelectAll();
                      },
                      controlAffinity: ListTileControlAffinity.leading,
                      dense: true,
                    ),
                    const Divider(height: 1),

                    // Individual items
                    ...widget.items.map((item) {
                      final isSelected = widget.selectedItems.contains(item);
                      return CheckboxListTile(
                        title: Text(widget.displayStringForItem(item)),
                        value: isSelected,
                        onChanged: (bool? value) {
                          _toggleItem(item);
                        },
                        controlAffinity: ListTileControlAffinity.leading,
                        dense: true,
                      );
                    }),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

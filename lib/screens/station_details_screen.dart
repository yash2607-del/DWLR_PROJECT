import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/water_level_service.dart';
import '../services/water_stations_service.dart';
import '../widgets/fullscreen_chart.dart';

class StationDetailsScreen extends StatefulWidget {
  final WaterStation station;

  const StationDetailsScreen({super.key, required this.station});

  @override
  State<StationDetailsScreen> createState() => _StationDetailsScreenState();
}

class _StationDetailsScreenState extends State<StationDetailsScreen>
    with SingleTickerProviderStateMixin {
  WaterLevelData? _waterLevelData;
  List<TimeSeriesDataPoint> _timeSeriesData = [];
  List<TimeSeriesDataPoint> _monthlyData = [];
  List<TimeSeriesDataPoint> _sixMonthsData = [];
  List<TimeSeriesDataPoint> _customRangeData = [];
  bool _isLoading = true;
  bool _isTimeSeriesLoading = false;
  bool _isMonthlyLoading = false;
  bool _isSixMonthsLoading = false;
  bool _isCustomRangeLoading = false;
  bool _isCustomDateMode = false;
  String? _errorMessage;
  String? _timeSeriesErrorMessage;
  String? _monthlyErrorMessage;
  String? _sixMonthsErrorMessage;
  String? _customRangeErrorMessage;
  DateTime? _startDate;
  DateTime? _endDate;
  late TabController _tabController;

  // Dataset options
  bool _showGroundwaterLevel = true; // Always checked and disabled
  bool _showRainfall = false;
  bool _showHumidity = false;
  bool _showTemperature = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_onTabChanged);
    _fetchWaterLevelData();
  }

  void _onTabChanged() {
    if (_tabController.index == 1) {
      if (_timeSeriesData.isEmpty && !_isTimeSeriesLoading) {
        _fetchTimeSeriesData();
      }
      if (_monthlyData.isEmpty && !_isMonthlyLoading) {
        _fetchMonthlyData();
      }
      if (_sixMonthsData.isEmpty && !_isSixMonthsLoading) {
        _fetchSixMonthsData();
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchWaterLevelData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final data = await WaterLevelService.fetchWaterLevelData(
        widget.station.stationCode,
      );

      setState(() {
        _waterLevelData = data;
        _isLoading = false;
        if (data == null) {
          _errorMessage = 'No data available for this station';
        }
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to fetch station details: $e';
      });
    }
  }

  Future<void> _fetchTimeSeriesData() async {
    setState(() {
      _isTimeSeriesLoading = true;
      _timeSeriesErrorMessage = null;
    });

    try {
      final data = await WaterLevelService.fetchWeeklyData(
        widget.station.stationCode,
      );

      setState(() {
        _timeSeriesData = data;
        _isTimeSeriesLoading = false;
        if (data.isEmpty) {
          _timeSeriesErrorMessage = 'No recent data available for this station';
        }
      });
    } catch (e) {
      setState(() {
        _isTimeSeriesLoading = false;
        _timeSeriesErrorMessage = 'Failed to fetch recent data: $e';
      });
    }
  }

  Future<void> _fetchMonthlyData() async {
    setState(() {
      _isMonthlyLoading = true;
      _monthlyErrorMessage = null;
    });

    try {
      final data = await WaterLevelService.fetchMonthlyData(
        widget.station.stationCode,
      );

      setState(() {
        _monthlyData = data;
        _isMonthlyLoading = false;
        if (data.isEmpty) {
          _monthlyErrorMessage = 'No monthly data available for this station';
        }
      });
    } catch (e) {
      setState(() {
        _isMonthlyLoading = false;
        _monthlyErrorMessage = 'Failed to fetch monthly data: $e';
      });
    }
  }

  Future<void> _fetchSixMonthsData() async {
    setState(() {
      _isSixMonthsLoading = true;
      _sixMonthsErrorMessage = null;
    });

    try {
      final data = await WaterLevelService.fetchSixMonthsData(
        widget.station.stationCode,
      );

      setState(() {
        _sixMonthsData = data;
        _isSixMonthsLoading = false;
        if (data.isEmpty) {
          _sixMonthsErrorMessage = 'No 6-month data available for this station';
        }
      });
    } catch (e) {
      setState(() {
        _isSixMonthsLoading = false;
        _sixMonthsErrorMessage = 'Failed to fetch 6-month data: $e';
      });
    }
  }

  Future<void> _fetchCustomRangeData() async {
    if (_startDate == null || _endDate == null) {
      setState(() {
        _customRangeErrorMessage = 'Please select both start and end dates';
      });
      return;
    }

    // Validate that end date is not in the future
    if (_endDate!.isAfter(DateTime.now())) {
      setState(() {
        _customRangeErrorMessage = 'End date cannot be in the future';
      });
      return;
    }

    // Validate that start date is before end date
    if (_startDate!.isAfter(_endDate!)) {
      setState(() {
        _customRangeErrorMessage = 'Start date must be before end date';
      });
      return;
    }

    setState(() {
      _isCustomRangeLoading = true;
      _customRangeErrorMessage = null;
    });

    try {
      final data = await WaterLevelService.fetchCustomRangeData(
        widget.station.stationCode,
        _startDate!,
        _endDate!,
      );

      setState(() {
        _customRangeData = data;
        _isCustomRangeLoading = false;
        if (data.isEmpty) {
          _customRangeErrorMessage =
              'No data available for the selected date range';
        }
      });
    } catch (e) {
      setState(() {
        _isCustomRangeLoading = false;
        _customRangeErrorMessage = 'Failed to fetch custom range data: $e';
      });
    }
  }

  void _openFullScreenChart(
    List<TimeSeriesDataPoint> data,
    String title,
    Color color,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FullScreenChart(
          data: data,
          title: title,
          color: color,
          stationName: widget.station.stationName,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Station Details'),
        centerTitle: true,
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchWaterLevelData,
            tooltip: 'Refresh Data',
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [_buildStationHeader(), _buildTabBar(), _buildTabContent()],
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: TabBar(
        controller: _tabController,
        labelColor: Colors.white,
        unselectedLabelColor: Colors.grey.shade600,
        indicator: BoxDecoration(
          color: Colors.blue,
          borderRadius: BorderRadius.circular(8),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        labelPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        tabs: [
          Tab(
            height: 20,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(Icons.info_outline, size: 18),
                SizedBox(width: 6),
                Text('Metadata', style: TextStyle(fontSize: 14)),
              ],
            ),
          ),
          Tab(
            height: 20,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(Icons.timeline, size: 18),
                SizedBox(width: 6),
                Text('Recent Data', style: TextStyle(fontSize: 14)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabContent() {
    return AnimatedBuilder(
      animation: _tabController,
      builder: (context, child) {
        return IndexedStack(
          index: _tabController.index,
          children: [_buildMetadataTab(), _buildRecentDataTab()],
        );
      },
    );
  }

  Widget _buildMetadataTab() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Fetching station details...'),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red.shade400),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.red.shade700),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _fetchWaterLevelData,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: _buildDetailsCard(),
    );
  }

  Widget _buildRecentDataTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // Data Range Options - Expandable
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: ExpansionTile(
              initiallyExpanded: false,
              tilePadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 8,
              ),
              childrenPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.tune_rounded,
                  color: Colors.blue.shade600,
                  size: 20,
                ),
              ),
              title: const Text(
                'Data Range Options',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              subtitle: Text(
                _isCustomDateMode
                    ? (_startDate != null && _endDate != null
                          ? 'Custom: ${_formatDateOnly(_startDate!)} - ${_formatDateOnly(_endDate!)}'
                          : 'Custom range - Select dates')
                    : 'Predefined ranges (7 days, 1 month, 6 months)',
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
              ),
              children: [
                // Use Column instead of Row for better mobile layout
                Column(
                  children: [
                    // Predefined Ranges Option
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _isCustomDateMode = false;
                          _customRangeErrorMessage = null;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: !_isCustomDateMode
                              ? Colors.blue.shade50
                              : Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: !_isCustomDateMode
                                ? Colors.blue.shade300
                                : Colors.grey.shade300,
                            width: !_isCustomDateMode ? 2 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Radio<bool>(
                              value: false,
                              groupValue: _isCustomDateMode,
                              onChanged: (value) {
                                setState(() {
                                  _isCustomDateMode = value!;
                                  _customRangeErrorMessage = null;
                                });
                              },
                              activeColor: Colors.blue.shade600,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Predefined Ranges',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: !_isCustomDateMode
                                          ? Colors.blue.shade800
                                          : Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '7 days, 1 month, 6 months',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Custom Range Option
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _isCustomDateMode = true;
                          _customRangeErrorMessage = null;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: _isCustomDateMode
                              ? Colors.blue.shade50
                              : Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _isCustomDateMode
                                ? Colors.blue.shade300
                                : Colors.grey.shade300,
                            width: _isCustomDateMode ? 2 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Radio<bool>(
                              value: true,
                              groupValue: _isCustomDateMode,
                              onChanged: (value) {
                                setState(() {
                                  _isCustomDateMode = value!;
                                  _customRangeErrorMessage = null;
                                });
                              },
                              activeColor: Colors.blue.shade600,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Custom Range',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: _isCustomDateMode
                                          ? Colors.blue.shade800
                                          : Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Select specific dates',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                if (_isCustomDateMode) ...[
                  const SizedBox(height: 20),
                  Container(
                    height: 1,
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          Colors.grey.shade300,
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildCustomDateRangeSelector(),
                ],

                // Dataset Options Section
                const SizedBox(height: 20),
                Container(
                  height: 1,
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.transparent,
                        Colors.grey.shade300,
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                _buildDatasetOptions(),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Show charts based on selected mode
          if (_isCustomDateMode)
            _buildCustomRangeChart()
          else ...[
            // Last 7 Days Chart
            _buildChartSection(
              title: 'Recent Data (Last 7 Days)',
              icon: Icons.timeline,
              data: _timeSeriesData,
              isLoading: _isTimeSeriesLoading,
              errorMessage: _timeSeriesErrorMessage,
              onRetry: _fetchTimeSeriesData,
              color: Colors.blue,
            ),

            const SizedBox(height: 16),

            // Last 1 Month Chart
            _buildChartSection(
              title: 'Monthly Trend (Last 30 Days)',
              icon: Icons.calendar_month,
              data: _monthlyData,
              isLoading: _isMonthlyLoading,
              errorMessage: _monthlyErrorMessage,
              onRetry: _fetchMonthlyData,
              color: Colors.green,
            ),

            const SizedBox(height: 16),

            // Last 6 Months Chart
            _buildChartSection(
              title: 'Long-term Trend (Last 6 Months)',
              icon: Icons.show_chart,
              data: _sixMonthsData,
              isLoading: _isSixMonthsLoading,
              errorMessage: _sixMonthsErrorMessage,
              onRetry: _fetchSixMonthsData,
              color: Colors.purple,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildChartSection({
    required String title,
    required IconData icon,
    required List<TimeSeriesDataPoint> data,
    required bool isLoading,
    required String? errorMessage,
    required VoidCallback onRetry,
    required Color color,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 24),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            if (isLoading)
              SizedBox(
                height: 200,
                child: const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('Loading data...'),
                    ],
                  ),
                ),
              )
            else if (errorMessage != null)
              SizedBox(
                height: 200,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 48,
                        color: Colors.red.shade400,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        errorMessage,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.red.shade700,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: onRetry,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              )
            else if (data.isEmpty)
              Container(
                height: 200,
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: const Center(child: Text('No data to display')),
              )
            else
              InkWell(
                onTap: () => _openFullScreenChart(data, title, color),
                borderRadius: BorderRadius.circular(8),
                child: _buildChart(data, color),
              ),
          ],
        ),
      ),
    );
  }

  List<TimeSeriesDataPoint> _aggregateDataPoints(
    List<TimeSeriesDataPoint> data,
  ) {
    if (data.isEmpty) return data;

    // Sort data by date first
    final sortedData = List<TimeSeriesDataPoint>.from(data)
      ..sort((a, b) => a.dateTime.compareTo(b.dateTime));

    // Calculate date range
    final firstDate = sortedData.first.dateTime;
    final lastDate = sortedData.last.dateTime;
    final daysDifference = lastDate.difference(firstDate).inDays;

    // If less than 10 days, return as is
    if (daysDifference < 10) {
      return sortedData;
    }

    // Group data based on duration
    if (daysDifference <= 60) {
      // 10 days to 2 months - group by day
      return _groupByDay(sortedData);
    } else if (daysDifference <= 365) {
      // 2 months to 1 year - group by week
      return _groupByWeek(sortedData);
    } else {
      // More than 1 year - group by month
      return _groupByMonth(sortedData);
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

  String _getChartDateLabel(
    List<TimeSeriesDataPoint> originalData,
    DateTime date,
  ) {
    if (originalData.isEmpty) return '';

    // Calculate date range to determine appropriate label format
    final sortedData = List<TimeSeriesDataPoint>.from(originalData)
      ..sort((a, b) => a.dateTime.compareTo(b.dateTime));
    final firstDate = sortedData.first.dateTime;
    final lastDate = sortedData.last.dateTime;
    final daysDifference = lastDate.difference(firstDate).inDays;

    if (daysDifference < 10) {
      // Less than 10 days - show day/month and time
      return '${date.day}/${date.month}\n${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } else if (daysDifference <= 60) {
      // 10 days to 2 months - show day/month
      return '${date.day}/${date.month}';
    } else if (daysDifference <= 365) {
      // 2 months to 1 year - show week info
      return 'W${_getWeekNumber(date)}\n${date.day}/${date.month}';
    } else {
      // More than 1 year - show month/year
      return '${_getMonthName(date.month)}\n${date.year}';
    }
  }

  String _getMonthName(int month) {
    const months = [
      '',
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return months[month];
  }

  int _getWeekNumber(DateTime date) {
    final dayOfYear = date.difference(DateTime(date.year, 1, 1)).inDays + 1;
    return (dayOfYear / 7).ceil();
  }

  String _getTooltipText(
    List<TimeSeriesDataPoint> originalData,
    TimeSeriesDataPoint dataPoint,
  ) {
    if (originalData.isEmpty) return '';

    // Calculate date range to determine appropriate tooltip format
    final sortedData = List<TimeSeriesDataPoint>.from(originalData)
      ..sort((a, b) => a.dateTime.compareTo(b.dateTime));
    final firstDate = sortedData.first.dateTime;
    final lastDate = sortedData.last.dateTime;
    final daysDifference = lastDate.difference(firstDate).inDays;

    if (daysDifference < 10) {
      // Less than 10 days - show exact date and time
      return '${_formatDateTime(dataPoint.dateTime)}\n${dataPoint.dataValue} ${dataPoint.unitCode}';
    } else if (daysDifference <= 60) {
      // 10 days to 2 months - show day average
      return 'Daily Avg: ${_formatDateOnly(dataPoint.dateTime)}\n${dataPoint.dataValue} ${dataPoint.unitCode}';
    } else if (daysDifference <= 365) {
      // 2 months to 1 year - show weekly average
      return 'Weekly Avg: Week ${_getWeekNumber(dataPoint.dateTime)}\n${_formatDateOnly(dataPoint.dateTime)}\n${dataPoint.dataValue} ${dataPoint.unitCode}';
    } else {
      // More than 1 year - show monthly average
      return 'Monthly Avg: ${_getMonthName(dataPoint.dateTime.month)} ${dataPoint.dateTime.year}\n${dataPoint.dataValue} ${dataPoint.unitCode}';
    }
  }

  Widget _buildChart(List<TimeSeriesDataPoint> data, Color color) {
    if (data.isEmpty) {
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

    // Aggregate data points based on date range
    final aggregatedData = _aggregateDataPoints(data);

    // Prepare data points for the chart
    final spots = <FlSpot>[];

    for (int i = 0; i < aggregatedData.length; i++) {
      final dataPoint = aggregatedData[i];
      final value = double.tryParse(dataPoint.dataValue) ?? 0.0;
      spots.add(FlSpot(i.toDouble(), value));
    }

    // Find min and max values for better scaling
    final values = spots.map((spot) => spot.y).toList();
    final minY = values.reduce((a, b) => a < b ? a : b);
    final maxY = values.reduce((a, b) => a > b ? a : b);
    final range = maxY - minY;
    final padding = range * 0.1; // 10% padding

    return Container(
      height: 300,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Water Level Trend (${data.first.unitCode})',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ),
              Icon(Icons.fullscreen, color: Colors.grey[600], size: 20),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: true,
                  horizontalInterval: range > 0 ? range / 5 : 1,
                  verticalInterval: spots.length > 5 ? spots.length / 5 : 1,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(color: Colors.grey.shade300, strokeWidth: 1);
                  },
                  getDrawingVerticalLine: (value) {
                    return FlLine(color: Colors.grey.shade300, strokeWidth: 1);
                  },
                ),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      interval: spots.length > 6 ? spots.length / 4 : 1,
                      getTitlesWidget: (double value, TitleMeta meta) {
                        final index = value.toInt();
                        if (index >= 0 && index < aggregatedData.length) {
                          final date = aggregatedData[index].dateTime;
                          final label = _getChartDateLabel(data, date);
                          return SideTitleWidget(
                            axisSide: meta.axisSide,
                            child: Text(
                              label,
                              style: const TextStyle(
                                color: Colors.grey,
                                fontWeight: FontWeight.bold,
                                fontSize: 10,
                              ),
                            ),
                          );
                        }
                        return const Text('');
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: range > 0 ? range / 4 : 1,
                      reservedSize: 42,
                      getTitlesWidget: (double value, TitleMeta meta) {
                        return Text(
                          value.toStringAsFixed(1),
                          style: const TextStyle(
                            color: Colors.grey,
                            fontWeight: FontWeight.bold,
                            fontSize: 10,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(
                  show: true,
                  border: Border.all(color: Colors.grey.shade400, width: 1),
                ),
                minX: 0,
                maxX: (spots.length - 1).toDouble(),
                minY: minY - padding,
                maxY: maxY + padding,
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: color,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) {
                        return FlDotCirclePainter(
                          radius: 4,
                          color: color,
                          strokeWidth: 2,
                          strokeColor: Colors.white,
                        );
                      },
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      color: color.withValues(alpha: 0.1),
                    ),
                  ),
                ],
                lineTouchData: LineTouchData(
                  enabled: true,
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
                      return touchedBarSpots.map((barSpot) {
                        final index = barSpot.x.toInt();
                        if (index >= 0 && index < aggregatedData.length) {
                          final dataPoint = aggregatedData[index];
                          final tooltipText = _getTooltipText(data, dataPoint);
                          return LineTooltipItem(
                            tooltipText,
                            const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          );
                        }
                        return null;
                      }).toList();
                    },
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day.toString().padLeft(2, '0')}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  Widget _buildCustomDateRangeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.date_range, color: Colors.blue.shade600, size: 20),
            const SizedBox(width: 8),
            const Text(
              'Select Date Range',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // Use Column layout instead of Row to prevent overflow
        Column(
          children: [
            // Start Date Selector
            Container(
              width: double.infinity,
              child: InkWell(
                onTap: () => _selectStartDate(),
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
                          letterSpacing: 0.5,
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
                          Expanded(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Text(
                                _startDate != null
                                    ? _formatDateOnly(_startDate!)
                                    : 'Tap to select start date',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                  color: _startDate != null
                                      ? Colors.black87
                                      : Colors.grey.shade600,
                                ),
                              ),
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

            // End Date Selector
            Container(
              width: double.infinity,
              child: InkWell(
                onTap: () => _selectEndDate(),
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
                          letterSpacing: 0.5,
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
                          Expanded(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Text(
                                _endDate != null
                                    ? _formatDateOnly(_endDate!)
                                    : 'Tap to select end date',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                  color: _endDate != null
                                      ? Colors.black87
                                      : Colors.grey.shade600,
                                ),
                              ),
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
        const SizedBox(height: 24),

        // Fetch Data Button
        Container(
          width: double.infinity,
          height: 56,
          child: ElevatedButton.icon(
            onPressed:
                (_startDate != null &&
                    _endDate != null &&
                    !_isCustomRangeLoading)
                ? _fetchCustomRangeData
                : null,
            icon: _isCustomRangeLoading
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Icon(Icons.analytics_rounded, size: 20),
            label: Text(
              _isCustomRangeLoading ? 'Fetching Data...' : 'Analyze Date Range',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: (_startDate != null && _endDate != null)
                  ? Colors.blue.shade600
                  : Colors.grey.shade400,
              foregroundColor: Colors.white,
              elevation: _isCustomRangeLoading ? 0 : 2,
              shadowColor: Colors.blue.shade200,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),

        // Error Message
        if (_customRangeErrorMessage != null) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.red.shade200, width: 1),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.error_outline_rounded,
                  size: 20,
                  color: Colors.red.shade600,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Error',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.red.shade800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _customRangeErrorMessage!,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.red.shade700,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildDatasetOptions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.dataset, color: Colors.blue.shade600, size: 20),
            const SizedBox(width: 8),
            const Text(
              'Dataset Options',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Groundwater Level (always checked, disabled)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: Row(
            children: [
              Checkbox(
                value: _showGroundwaterLevel,
                onChanged: null, // Disabled
                activeColor: Colors.blue.shade600,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Groundwater Level',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade600,
                  ),
                ),
              ),
              Icon(Icons.lock, size: 16, color: Colors.grey.shade400),
            ],
          ),
        ),

        // Rainfall
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: Row(
            children: [
              Checkbox(
                value: _showRainfall,
                onChanged: (value) {
                  setState(() {
                    _showRainfall = value ?? false;
                  });
                },
                activeColor: Colors.blue.shade600,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Rainfall',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: _showRainfall
                        ? Colors.black87
                        : Colors.grey.shade600,
                  ),
                ),
              ),
              if (!_showRainfall)
                Text(
                  'Coming Soon',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade500,
                    fontStyle: FontStyle.italic,
                  ),
                ),
            ],
          ),
        ),

        // Humidity
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: Row(
            children: [
              Checkbox(
                value: _showHumidity,
                onChanged: (value) {
                  setState(() {
                    _showHumidity = value ?? false;
                  });
                },
                activeColor: Colors.blue.shade600,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Humidity',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: _showHumidity
                        ? Colors.black87
                        : Colors.grey.shade600,
                  ),
                ),
              ),
              if (!_showHumidity)
                Text(
                  'Coming Soon',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade500,
                    fontStyle: FontStyle.italic,
                  ),
                ),
            ],
          ),
        ),

        // Temperature
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: Row(
            children: [
              Checkbox(
                value: _showTemperature,
                onChanged: (value) {
                  setState(() {
                    _showTemperature = value ?? false;
                  });
                },
                activeColor: Colors.blue.shade600,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Temperature',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: _showTemperature
                        ? Colors.black87
                        : Colors.grey.shade600,
                  ),
                ),
              ),
              if (!_showTemperature)
                Text(
                  'Coming Soon',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade500,
                    fontStyle: FontStyle.italic,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCustomRangeChart() {
    final title = _startDate != null && _endDate != null
        ? 'Custom Range'
        : 'Custom Date Range';

    final subtitle = _startDate != null && _endDate != null
        ? '${_formatDateOnly(_startDate!)} to ${_formatDateOnly(_endDate!)}'
        : null;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.date_range, color: Colors.orange, size: 24),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            if (_isCustomRangeLoading)
              SizedBox(
                height: 200,
                child: const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('Loading data...'),
                    ],
                  ),
                ),
              )
            else if (_customRangeErrorMessage != null)
              SizedBox(
                height: 200,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 48,
                        color: Colors.red.shade400,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _customRangeErrorMessage!,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.red.shade700,
                        ),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: _fetchCustomRangeData,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              )
            else if (_customRangeData.isEmpty)
              Container(
                height: 200,
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: const Center(child: Text('No data to display')),
              )
            else
              InkWell(
                onTap: () => _openFullScreenChart(
                  _customRangeData,
                  title,
                  Colors.orange,
                ),
                borderRadius: BorderRadius.circular(8),
                child: _buildChart(_customRangeData, Colors.orange),
              ),
          ],
        ),
      ),
    );
  }

  String _formatDateOnly(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}-${date.month.toString().padLeft(2, '0')}-${date.year}';
  }

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
        _customRangeErrorMessage = null;
        // Clear custom range data when dates change
        _customRangeData.clear();
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
        _customRangeErrorMessage = null;
        // Clear custom range data when dates change
        _customRangeData.clear();
      });
    }
  }

  Widget _buildStationHeader() {
    return Container(
      margin: const EdgeInsets.all(16.0),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.water_drop, color: Colors.blue, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.station.stationName,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Station Code: ${widget.station.stationCode}',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Text(
                  'Location: ${widget.station.position.latitude.toStringAsFixed(4)}, ${widget.station.position.longitude.toStringAsFixed(4)}',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.blue.shade700,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailsCard() {
    if (_waterLevelData == null) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Icon(Icons.info_outline, size: 48, color: Colors.grey.shade400),
              const SizedBox(height: 12),
              Text(
                'No additional details available',
                style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.analytics, color: Colors.green, size: 24),
                const SizedBox(width: 8),
                Text(
                  'Station Details',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildDetailsTable(),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailsTable() {
    if (_waterLevelData?.details.isEmpty ?? true) {
      return Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          children: [
            Icon(Icons.info_outline, color: Colors.grey.shade500, size: 20),
            const SizedBox(width: 8),
            Text(
              'No detailed information available',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            ),
          ],
        ),
      );
    }

    final details = _waterLevelData!.details;

    // Filter out null, empty, and unwanted values
    final filteredDetails = <String, String>{};
    details.forEach((key, value) {
      if (value != null &&
          value.toString().trim().isNotEmpty &&
          value.toString().toLowerCase() != 'null') {
        filteredDetails[key] = value.toString();
      }
    });

    if (filteredDetails.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          children: [
            Icon(Icons.info_outline, color: Colors.grey.shade500, size: 20),
            const SizedBox(width: 8),
            Text(
              'No valid data found for this station',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            ),
          ],
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Table(
        columnWidths: const {0: FlexColumnWidth(2), 1: FlexColumnWidth(3)},
        children: [
          // Table header
          TableRow(
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
            ),
            children: [
              _buildTableCell('Property', isHeader: true),
              _buildTableCell('Value', isHeader: true),
            ],
          ),
          // Table rows for each detail
          ...filteredDetails.entries.map((entry) {
            return TableRow(
              decoration: BoxDecoration(
                color: filteredDetails.keys.toList().indexOf(entry.key) % 2 == 0
                    ? Colors.white
                    : Colors.grey.shade50,
              ),
              children: [
                _buildTableCell(_formatKey(entry.key)),
                _buildTableCell(entry.value),
              ],
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildTableCell(String content, {bool isHeader = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: Text(
        content,
        style: TextStyle(
          fontSize: isHeader ? 14 : 13,
          fontWeight: isHeader ? FontWeight.bold : FontWeight.normal,
          color: isHeader ? Colors.blue.shade800 : Colors.black87,
        ),
      ),
    );
  }

  String _formatKey(String key) {
    // Format the key to be more readable
    return key
        .replaceAll('_', ' ')
        .replaceAll('-', ' ')
        .split(' ')
        .map(
          (word) => word.isNotEmpty
              ? word[0].toUpperCase() + word.substring(1).toLowerCase()
              : word,
        )
        .join(' ');
  }
}

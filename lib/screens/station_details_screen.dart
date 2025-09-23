import 'package:flutter/material.dart';
import '../services/water_level_service.dart';
import '../services/water_stations_service.dart';

class StationDetailsScreen extends StatefulWidget {
  final WaterStation station;

  const StationDetailsScreen({super.key, required this.station});

  @override
  State<StationDetailsScreen> createState() => _StationDetailsScreenState();
}

class _StationDetailsScreenState extends State<StationDetailsScreen> {
  WaterLevelData? _waterLevelData;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchWaterLevelData();
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
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
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

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStationHeader(),
          const SizedBox(height: 24),
          _buildDetailsCard(),
        ],
      ),
    );
  }

  Widget _buildStationHeader() {
    return Card(
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
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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

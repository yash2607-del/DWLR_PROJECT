import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/ground_water.dart';
import '../services/api_service.dart';

class ChartsScreen extends StatefulWidget {
  const ChartsScreen({super.key});

  @override
  State<ChartsScreen> createState() => _ChartsScreenState();
}

class _ChartsScreenState extends State<ChartsScreen> {
  List<GroundWaterRecord> records = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadData();
  }

  void loadData() async {
    try {
      final datasets = await ApiService.fetchDatasets();
      if (datasets.isNotEmpty) {
        records = await ApiService.fetchDatasetRecords(datasets[0], limit: 21);
      }
    } catch (e) {
      print('Error fetching data: $e');
    }
    setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Groundwater Chart")),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: records.isEmpty
                  ? const Center(child: Text('No data available'))
                  : LineChart(
                      LineChartData(
                        titlesData: FlTitlesData(
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (value, _) {
                                final index = value.toInt();
                                if (index < 0 || index >= records.length) return const SizedBox();
                                final date = records[index].dataTime;
                                return Text('${date.day}/${date.month}');
                              },
                              interval: 1,
                            ),
                          ),
                        ),
                        lineBarsData: [
                          LineChartBarData(
                            spots: List.generate(
                              records.length,
                              (index) => FlSpot(index.toDouble(), records[index].dataValue),
                            ),
                            isCurved: true,
                            color: Colors.teal,
                            barWidth: 3,
                            dotData: FlDotData(show: true),
                          ),
                        ],
                      ),
                    ),
            ),
    );
  }
}

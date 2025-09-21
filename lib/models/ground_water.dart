class GroundWaterRecord {
  final DateTime dataTime;
  final double dataValue;

  GroundWaterRecord({required this.dataTime, required this.dataValue});

  factory GroundWaterRecord.fromJson(Map<String, dynamic> json) {
    return GroundWaterRecord(
      dataTime: DateTime.parse(json['Data Time']),
      dataValue: (json['Data Value'] as num).toDouble(),
    );
  }
}

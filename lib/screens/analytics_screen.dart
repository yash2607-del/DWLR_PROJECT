import 'package:flutter/material.dart';
import '../services/indiawris_service.dart';
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

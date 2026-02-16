import 'package:flutter/material.dart';

class AgentFilter extends StatefulWidget {
  final Function(String?) onFilter;
  final List<String> regions;

  const AgentFilter({super.key, required this.onFilter, required this.regions, String? currentFilter});

  @override
  State<AgentFilter> createState() => _AgentFilterState();
}

class _AgentFilterState extends State<AgentFilter> {
  String? _selectedRegion;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Filter Agents',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _selectedRegion,
            decoration: const InputDecoration(
              labelText: 'Region',
              border: OutlineInputBorder(),
            ),
            items: widget.regions.map((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(value),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _selectedRegion = value;
              });
            },
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              widget.onFilter(_selectedRegion);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1976D2),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: const Text('Apply Filter'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _selectedRegion = null;
              });
              widget.onFilter(null);
              Navigator.pop(context);
            },
            child: const Text('Clear Filter'),
          ),
        ],
      ),
    );
  }
}
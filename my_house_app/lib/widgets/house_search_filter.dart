import 'package:flutter/material.dart';
// Search and Filter Widget
class HouseSearchFilter extends StatefulWidget {
  final Function(Map<String, dynamic>) onFilter;
  const HouseSearchFilter({super.key, required this.onFilter, required Map<String, dynamic> initialFilters});

  @override
  State<HouseSearchFilter> createState() => _HouseSearchFilterState();
}

class _HouseSearchFilterState extends State<HouseSearchFilter> {
  final _formKey = GlobalKey<FormState>();
  final Map<String, dynamic> _filters = {
    'category': null,
    'type': null,
    'region': null,
    'cost_below': null,
  };

  final List<String> _categories = ['House', 'Apartment', 'Room', 'Land'];
  final List<String> _types = ['Rent', 'Sale'];
  final List<String> _regions = ['Dar es Salaam', 'Arusha', 'Mwanza', 'Dodoma', 'Mbeya'];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Filter Properties',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _filters['category'],
              decoration: const InputDecoration(
                labelText: 'Category',
                border: OutlineInputBorder(),
              ),
              items: _categories.map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _filters['category'] = value;
                });
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _filters['type'],
              decoration: const InputDecoration(
                labelText: 'Type',
                border: OutlineInputBorder(),
              ),
              items: _types.map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _filters['type'] = value;
                });
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _filters['region'],
              decoration: const InputDecoration(
                labelText: 'Region',
                border: OutlineInputBorder(),
              ),
              items: _regions.map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _filters['region'] = value;
                });
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              decoration: const InputDecoration(
                labelText: 'Maximum Cost (TSH)',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              onChanged: (value) {
                _filters['cost_below'] = value.isNotEmpty ? double.tryParse(value) : null;
              },
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                widget.onFilter(_filters);
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6A11CB),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('Apply Filters'),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  _filters.clear();
                });
                widget.onFilter({});
                Navigator.pop(context);
              },
              child: const Text('Clear Filters'),
            ),
          ],
        ),
      ),
    );
  }
}
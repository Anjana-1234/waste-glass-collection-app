import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/local_db_service.dart';

class TripReportScreen extends StatefulWidget {
  const TripReportScreen({super.key});

  @override
  State<TripReportScreen> createState() => _TripReportScreenState();
}

class _TripReportScreenState extends State<TripReportScreen> {
  Map<String, dynamic>? _summary;
  bool _loading = true;
  bool _syncing = false;
  bool _synced = false;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _loadSummary();
  }

  Future<void> _loadSummary() async {
    try {
      setState(() { _loading = true; _error = ''; });
      final data = await ApiService.getTripSummary();
      setState(() { _summary = data; _loading = false; });
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  Future<void> _syncToServer() async {
    setState(() { _syncing = true; });
    try {
      final local = await LocalDbService.getAllCollections();
      for (final record in local) {
        await ApiService.submitCollection(
          barcodeId: record['barcode_id'],
          clearKg: record['clear_kg'],
          colouredKg: record['coloured_kg'],
          condition: record['condition'],
        );
      }
      await LocalDbService.clearAll();
      setState(() { _synced = true; _syncing = false; });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('All records synced successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      setState(() { _syncing = false; });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Sync failed. Data saved locally. Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Trip Report',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF2E7D32)))
          : _error.isNotEmpty
              ? Center(child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 60, color: Colors.red),
                    const SizedBox(height: 16),
                    const Text('Failed to load report'),
                    ElevatedButton(onPressed: _loadSummary, child: const Text('Retry')),
                  ],
                ))
              : Column(
                  children: [
                    // Summary header
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      color: const Color(0xFF2E7D32),
                      child: Column(
                        children: [
                          const Text('Trip Complete!',
                              style: TextStyle(color: Colors.white,
                                  fontSize: 20, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _statBox('Total Stops',
                                  '${_summary!['totalStops']}'),
                              _statBox('Clear Glass',
                                  '${_summary!['totalClearKg']}kg'),
                              _statBox('Coloured Glass',
                                  '${_summary!['totalColouredKg']}kg'),
                              _statBox('Total',
                                  '${_summary!['totalKg']}kg'),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Collections list
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: (_summary!['collections'] as List).length,
                        itemBuilder: (context, index) {
                          final item = _summary!['collections'][index];
                          final hasShortfall = item['shortfall'] == true;
                          return Card(
                            margin: const EdgeInsets.only(bottom: 10),
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: hasShortfall
                                  ? const BorderSide(color: Colors.orange, width: 2)
                                  : BorderSide.none,
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(item['name'],
                                          style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16)),
                                      if (hasShortfall)
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: Colors.orange.withOpacity(0.2),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: const Row(
                                            children: [
                                              Icon(Icons.warning,
                                                  color: Colors.orange, size: 16),
                                              SizedBox(width: 4),
                                              Text('Shortfall',
                                                  style: TextStyle(
                                                      color: Colors.orange,
                                                      fontWeight: FontWeight.bold)),
                                            ],
                                          ),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      _detailChip('Clear', '${item['clearKg']}kg'),
                                      const SizedBox(width: 8),
                                      _detailChip('Coloured', '${item['colouredKg']}kg'),
                                      const SizedBox(width: 8),
                                      _detailChip('Condition', item['condition']),
                                    ],
                                  ),
                                  if (hasShortfall) ...[
                                    const SizedBox(height: 6),
                                    Text(
                                      'Expected: ${item['expectedClearKg']}kg clear, '
                                      '${item['expectedColouredKg']}kg coloured',
                                      style: const TextStyle(
                                          color: Colors.orange, fontSize: 12),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),

                    // Sync button
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _synced ? Colors.grey : Colors.blue,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: _synced || _syncing ? null : _syncToServer,
                          icon: _syncing
                              ? const SizedBox(
                                  width: 20, height: 20,
                                  child: CircularProgressIndicator(
                                      color: Colors.white, strokeWidth: 2))
                              : Icon(_synced ? Icons.check : Icons.cloud_upload),
                          label: Text(
                            _synced ? 'Synced!' : _syncing ? 'Syncing...' : 'Sync to Server',
                            style: const TextStyle(fontSize: 16,
                                fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _statBox(String label, String value) {
    return Column(
      children: [
        Text(value, style: const TextStyle(
            fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11)),
      ],
    );
  }

  Widget _detailChip(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text('$label: $value',
          style: const TextStyle(fontSize: 12)),
    );
  }
}
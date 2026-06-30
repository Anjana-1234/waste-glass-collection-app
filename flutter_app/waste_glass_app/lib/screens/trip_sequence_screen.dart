import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'scan_collect_screen.dart';
import 'trip_report_screen.dart';

class TripSequenceScreen extends StatefulWidget {
  const TripSequenceScreen({super.key});

  @override
  State<TripSequenceScreen> createState() => _TripSequenceScreenState();
}

class _TripSequenceScreenState extends State<TripSequenceScreen> {
  List<dynamic> _route = [];
  double _totalDistance = 0;
  bool _loading = true;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _loadRoute();
  }

  Future<void> _loadRoute() async {
    try {
      setState(() { _loading = true; _error = ''; });
      final data = await ApiService.getTodayRoute();
      final summary = await ApiService.getTripSummary();
      setState(() {
        _route = data;
        _loading = false;
      });
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'Collected': return Colors.green;
      case 'Next': return Colors.orange;
      default: return Colors.grey;
    }
  }

  IconData _statusIcon(String status) {
    switch (status) {
      case 'Collected': return Icons.check_circle;
      case 'Next': return Icons.navigation;
      default: return Icons.radio_button_unchecked;
    }
  }

  @override
  Widget build(BuildContext context) {
    final remaining = _route.where((s) => s['status'] != 'Collected').length;
    final allDone = _route.isNotEmpty && remaining == 0;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('Today\'s Route',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadRoute,
          )
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF2E7D32)))
          : _error.isNotEmpty
              ? Center(child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 60, color: Colors.red),
                    const SizedBox(height: 16),
                    Text('Connection Error', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    ElevatedButton(onPressed: _loadRoute, child: const Text('Retry')),
                  ],
                ))
              : Column(
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      color: const Color(0xFF2E7D32),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _statBox('Total Stops', '${_route.length}'),
                          _statBox('Remaining', '$remaining'),
                          _statBox('Collected', '${_route.length - remaining}'),
                        ],
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: _route.length,
                        itemBuilder: (context, index) {
                          final supplier = _route[index];
                          final status = supplier['status'] ?? 'Pending';
                          return Card(
                            margin: const EdgeInsets.only(bottom: 10),
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: _statusColor(status).withOpacity(0.2),
                                child: Text('${supplier['stopOrder']}',
                                    style: TextStyle(
                                        color: _statusColor(status),
                                        fontWeight: FontWeight.bold)),
                              ),
                              title: Text(supplier['name'],
                                  style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Text(supplier['address']),
                              trailing: Icon(_statusIcon(status),
                                  color: _statusColor(status), size: 28),
                            ),
                          );
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: allDone ? Colors.blue : const Color(0xFF2E7D32),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: () {
                            if (allDone) {
                              Navigator.push(context, MaterialPageRoute(
                                  builder: (_) => const TripReportScreen()));
                            } else {
                              final next = _route.firstWhere(
                                  (s) => s['status'] != 'Collected',
                                  orElse: () => null);
                              if (next != null) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => ScanCollectScreen(
                                      supplier: next,
                                      onCollected: _loadRoute,
                                    ),
                                  ),
                                );
                              }
                            }
                          },
                          child: Text(
                            allDone ? 'View Trip Report' : 'Go to Next Stop',
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
            fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
      ],
    );
  }
}
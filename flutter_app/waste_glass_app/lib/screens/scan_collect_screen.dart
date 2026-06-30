import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../services/api_service.dart';
import '../services/local_db_service.dart';

class ScanCollectScreen extends StatefulWidget {
  final Map<String, dynamic> supplier;
  final VoidCallback onCollected;

  const ScanCollectScreen({
    super.key,
    required this.supplier,
    required this.onCollected,
  });

  @override
  State<ScanCollectScreen> createState() => _ScanCollectScreenState();
}

class _ScanCollectScreenState extends State<ScanCollectScreen> {
  bool _scanned = false;
  bool _formUnlocked = false;
  bool _submitting = false;
  String _scanError = '';

  final _clearKgController = TextEditingController();
  final _colouredKgController = TextEditingController();
  String _condition = 'Good';

  void _onBarcodeDetected(BarcodeCapture capture) {
    if (_scanned) return;
    final barcode = capture.barcodes.first.rawValue ?? '';
    final expectedId = widget.supplier['barcodeId'];

    setState(() { _scanned = true; });

    if (barcode == expectedId) {
      setState(() { _formUnlocked = true; _scanError = ''; });
    } else {
      setState(() {
        _scanError = 'Wrong supplier! Expected ${expectedId}, got $barcode';
        _scanned = false;
      });
    }
  }

  Future<void> _submitCollection() async {
    final clearKg = double.tryParse(_clearKgController.text) ?? 0;
    final colouredKg = double.tryParse(_colouredKgController.text) ?? 0;

    if (clearKg == 0 && colouredKg == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter collected quantities')));
      return;
    }

    setState(() { _submitting = true; });

    // Save locally first
    await LocalDbService.saveCollection({
      'supplier_id': widget.supplier['id'].toString(),
      'barcode_id': widget.supplier['barcodeId'],
      'supplier_name': widget.supplier['name'],
      'clear_kg': clearKg,
      'coloured_kg': colouredKg,
      'condition': _condition,
      'timestamp': DateTime.now().toIso8601String(),
      'synced': 0,
    });

    // Submit to backend
    try {
      await ApiService.submitCollection(
        barcodeId: widget.supplier['barcodeId'],
        clearKg: clearKg,
        colouredKg: colouredKg,
        condition: _condition,
      );
    } catch (e) {
      // Offline - data saved locally
    }

    setState(() { _submitting = false; });
    widget.onCollected();
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan & Collect',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Supplier info card
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              color: const Color(0xFF2E7D32).withOpacity(0.1),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Next Stop', style: TextStyle(color: Colors.grey[600])),
                    Text(widget.supplier['name'],
                        style: const TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(widget.supplier['address'],
                        style: TextStyle(color: Colors.grey[700])),
                    const SizedBox(height: 8),
                    Text(
                      'Expected: ${widget.supplier['expectedClearKg']}kg clear, '
                      '${widget.supplier['expectedColouredKg']}kg coloured',
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Scanner
            if (!_formUnlocked) ...[
              const Text('Scan Supplier Barcode',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Container(
                height: 200,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF2E7D32), width: 2),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: MobileScanner(onDetect: _onBarcodeDetected),
                ),
              ),
              if (_scanError.isNotEmpty) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error, color: Colors.red),
                      const SizedBox(width: 8),
                      Expanded(child: Text(_scanError,
                          style: const TextStyle(color: Colors.red))),
                    ],
                  ),
                ),
              ],
            ],

            // Collection form (unlocked after scan)
            if (_formUnlocked) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green),
                    SizedBox(width: 8),
                    Text('Barcode verified! Enter collection details.',
                        style: TextStyle(color: Colors.green,
                            fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _clearKgController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Clear Glass (kg)',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8)),
                  prefixIcon: const Icon(Icons.water_drop_outlined),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _colouredKgController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Coloured Glass (kg)',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8)),
                  prefixIcon: const Icon(Icons.color_lens_outlined),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _condition,
                decoration: InputDecoration(
                  labelText: 'Condition',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                items: ['Good', 'Fair', 'Poor'].map((c) =>
                    DropdownMenuItem(value: c, child: Text(c))).toList(),
                onChanged: (v) => setState(() => _condition = v!),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E7D32),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: _submitting ? null : _submitCollection,
                  child: _submitting
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Confirm Collection',
                          style: TextStyle(fontSize: 16,
                              fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:nfc_manager/nfc_manager.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

class AddScreen extends StatefulWidget {
  const AddScreen({Key? key}) : super(key: key);

  @override
  State<AddScreen> createState() => _AddScreenState();
}

class _AddScreenState extends State<AddScreen> {
  String? nfcId;
  final _formKey = GlobalKey<FormState>();
  String? brand;
  int? capacity;
  int? cellCount;

  @override
  void initState() {
    super.initState();
    _startNfcSession();
  }

  void _startNfcSession() async {
    NfcManager.instance.startSession(
      pollingOptions: {
        NfcPollingOption.iso14443,
        NfcPollingOption.iso15693,
        NfcPollingOption.iso18092,
      },
      onDiscovered: (NfcTag tag) async {
        // Fallback: use tag.toString() as the NFC ID
        setState(() {
          nfcId = tag.toString();
        });
        NfcManager.instance.stopSession();
      },
    );
  }

  @override
  void dispose() {
    NfcManager.instance.stopSession();
    super.dispose();
  }

  Future<void> _saveBattery() async {
    if (_formKey.currentState?.validate() ?? false) {
      _formKey.currentState?.save();
      if (nfcId == null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('No NFC ID found.')));
        return;
      }
      // Save battery to Supabase (lipo table)
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;
      final uuid = const Uuid();
      final lipoId = uuid.v5(Namespace.url.value, nfcId!);
      try {
        final response = await supabase.from('lipo').insert({
          'id': lipoId,
          'brand': brand,
          'capacity': capacity,
          'cell_count': cellCount,
          'purchased_at': null,
          'notes': null,
          'user_id': user?.id,
        });
        if (response.error != null) {
          throw response.error!;
        }
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Battery added!')));
        Navigator.of(context).pop();
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error adding battery: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Battery')),
      body: Center(
        child: nfcId == null
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.nfc, size: 64),
                  SizedBox(height: 24),
                  Text(
                    'Scan battery to add',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                ],
              )
            : Padding(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: ListView(
                    shrinkWrap: true,
                    children: [
                      Text(
                        'NFC ID: $nfcId',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        decoration: const InputDecoration(labelText: 'Brand'),
                        validator: (v) =>
                            v == null || v.isEmpty ? 'Enter brand' : null,
                        onSaved: (v) => brand = v,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        decoration: const InputDecoration(
                          labelText: 'Capacity (mAh)',
                        ),
                        keyboardType: TextInputType.number,
                        validator: (v) => v == null || int.tryParse(v) == null
                            ? 'Enter valid capacity'
                            : null,
                        onSaved: (v) => capacity = int.tryParse(v ?? ''),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        decoration: const InputDecoration(
                          labelText: 'Number of cells',
                        ),
                        keyboardType: TextInputType.number,
                        validator: (v) => v == null || int.tryParse(v) == null
                            ? 'Enter valid cell count'
                            : null,
                        onSaved: (v) => cellCount = int.tryParse(v ?? ''),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: _saveBattery,
                        child: const Text('Save Battery'),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}

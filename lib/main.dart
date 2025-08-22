import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:nfc_manager/nfc_manager.dart';

void main() {
  runApp(const NfcReaderApp());
}

class NfcReaderApp extends StatelessWidget {
  const NfcReaderApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NFC Reader',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String _tag = 'Scan an NFC tag';

  Future<void> _startSession() async {
    setState(() => _tag = 'Waiting for tag...');
    if (!await NfcManager.instance.isAvailable()) {
      setState(() => _tag = 'NFC not available');
      return;
    }

    NfcManager.instance.startSession(
      onDiscovered: (NfcTag tag) async {
        String message;
        try {
          final ndef = Ndef.from(tag);
          if (ndef != null && ndef.cachedMessage != null) {
            message = ndef.cachedMessage!.records.map((record) {
              if (record.typeNameFormat == NdefTypeNameFormat.nfcWellknown &&
                  record.payload.isNotEmpty) {
                final payload = record.payload;
                final langLength = payload.first;
                return utf8
                    .decode(payload.skip(1 + langLength).toList());
              }
              return record.payload.toString();
            }).join('\n');
          } else {
            // ignore: invalid_use_of_protected_member
            message = jsonEncode(tag.data);
          }
        } catch (e) {
          message = 'Error reading tag: $e';
        }

        setState(() => _tag = message);
        NfcManager.instance.stopSession();
      },
      pollingOptions: {
        NfcPollingOption.iso14443,
        NfcPollingOption.iso15693,
        NfcPollingOption.iso18092,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('NFC Reader')),
      body: Center(child: Text(_tag)),
      floatingActionButton: FloatingActionButton(
        onPressed: _startSession,
        child: const Icon(Icons.nfc),
      ),
    );
  }
}

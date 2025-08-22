import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:nfc_manager/nfc_manager.dart';
import 'package:nfc_manager/ndef_record.dart';
import 'package:nfc_manager_ndef/nfc_manager_ndef.dart';

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
        try {
          final ndef = Ndef.from(tag);
          if (ndef != null) {
            final ndefMessage = await ndef.read();
            if (ndefMessage != null) {
              final records = ndefMessage.records.map((record) {
                if (record.typeNameFormat == TypeNameFormat.wellKnown &&
                    record.type.length == 1 &&
                    record.type.first == 0x54 &&
                    record.payload.isNotEmpty) {
                  final payload = record.payload;
                  final langLength = payload.first;
                  return utf8.decode(payload.skip(1 + langLength).toList());
                }
                return record.payload.toString();
              }).join('\n');
              setState(() => _tag = records);
            } else {
              setState(() => _tag = 'No NDEF records');
            }
          } else {
            // ignore: invalid_use_of_protected_member
            setState(() => _tag = jsonEncode(tag.data));
          }
        } catch (e) {
          setState(() => _tag = 'Error reading tag: $e');
        }
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

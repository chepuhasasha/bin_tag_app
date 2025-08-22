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
  String? _tag;

  Future<void> _startSession() async {
    setState(() => _tag = null);
    if (!await NfcManager.instance.isAvailable()) {
      setState(() => _tag = 'NFC not available');
      return;
    }

    await NfcManager.instance.startSession(
      onDiscovered: (NfcTag tag) async {
        // ignore: invalid_use_of_protected_member
        setState(() => _tag = jsonEncode(tag.data));
        await NfcManager.instance.stopSession();
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
      body: Center(child: Text(_tag ?? 'Scan an NFC tag')),
      floatingActionButton: FloatingActionButton(
        onPressed: _startSession,
        child: const Icon(Icons.nfc),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:nfc_manager/nfc_manager.dart';
import 'package:nfc_manager/nfc_manager_android.dart';
import 'package:nfc_manager/nfc_manager_ios.dart';

void main() => runApp(const App());

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFFF1F3F6),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFF1F3F6),
          foregroundColor: Colors.black,
          elevation: 0,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ButtonStyle(
            backgroundColor: WidgetStatePropertyAll(Colors.white),
            foregroundColor: WidgetStatePropertyAll(Colors.black),
            shape: WidgetStatePropertyAll(
              RoundedRectangleBorder(borderRadius: BorderRadius.zero),
            ),
          ),
        ),
      ),
      home: const Home(),
    );
  }
}

class Home extends StatelessWidget {
  const Home({super.key});

  @override
  Widget build(BuildContext c) => Scaffold(
        appBar: AppBar(title: const Text('NFC UID')),
        body: const Center(child: Text('Поднесите метку и нажмите кнопку')),
        bottomNavigationBar: SizedBox(
          width: double.infinity,
          height: 100,
          child: ElevatedButton(
            onPressed: () {
              Navigator.of(c).push(
                MaterialPageRoute(builder: (_) => const ScanScreen()),
              );
            },
            child: const Text('Scan'),
          ),
        ),
      );
}

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});
  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  String _text = 'Ожидание…';
  bool _sessionStarted = false;

  @override
  void initState() {
    super.initState();
    _start();
  }

  @override
  void dispose() {
    if (_sessionStarted) {
      NfcManager.instance.stopSession();
    }
    super.dispose();
  }

  Future<void> _start() async {
    if (!await NfcManager.instance.isAvailable()) {
      setState(() => _text = 'NFC недоступен');
      return;
    }
    _sessionStarted = true;
    NfcManager.instance.startSession(
      pollingOptions: const {
        NfcPollingOption.iso14443,
        NfcPollingOption.iso15693,
        NfcPollingOption.iso18092,
      },
      onDiscovered: (tag) async {
        try {
          final id = _uid(tag);
          setState(() => _text =
              (id != null && id.isNotEmpty) ? 'UID: ${_hex(id)}' : 'UID не найден');
        } catch (e) {
          setState(() => _text = 'Ошибка: $e');
        } finally {
          _sessionStarted = false;
          NfcManager.instance.stopSession();
        }
      },
    );
  }

  List<int>? _uid(NfcTag tag) {
    final aTag = NfcTagAndroid.from(tag);
    if (aTag != null && aTag.id.isNotEmpty) return aTag.id;
    if (MiFareIos.from(tag) case final t?) return t.identifier;
    if (Iso15693Ios.from(tag) case final t?) return t.identifier;
    if (Iso7816Ios.from(tag) case final t?) return t.identifier;
    if (FeliCaIos.from(tag) case final t?) return t.currentIDm;
    return null;
  }

  String _hex(List<int> b) =>
      b.map((x) => x.toRadixString(16).padLeft(2, '0').toUpperCase()).join(':');

  @override
  Widget build(BuildContext c) => Scaffold(
        appBar: AppBar(title: const Text('Сканирование')),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_text == 'Ожидание…') ...[
                const SizedBox(width: 80, height: 80, child: CircularProgressIndicator()),
                const SizedBox(height: 16),
              ],
              SelectableText(_text),
            ],
          ),
        ),
      );
}

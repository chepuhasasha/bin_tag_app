import 'package:flutter/material.dart';
import 'package:nfc_manager/nfc_manager.dart';
// ВАЖНО: подключаем платформенные библиотеки 4.x
import 'package:nfc_manager/nfc_manager_android.dart';
import 'package:nfc_manager/nfc_manager_ios.dart';

void main() => runApp(const MaterialApp(home: Home()));

class Home extends StatefulWidget {
  const Home({super.key});
  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  String _text = 'Поднесите метку и нажмите кнопку';

  Future<void> _start() async {
    setState(() => _text = 'Ожидание…');
    if (!await NfcManager.instance.isAvailable()) {
      setState(() => _text = 'NFC недоступен');
      return;
    }

    NfcManager.instance.startSession(
      pollingOptions: const {
        NfcPollingOption.iso14443,
        NfcPollingOption.iso15693,
        NfcPollingOption.iso18092,
      },
      onDiscovered: (tag) async {
        try {
          final id = _uid(tag);
          setState(() => _text = (id != null && id.isNotEmpty)
              ? 'UID: ${_hex(id)}'
              : 'UID не найден');
        } catch (e) {
          setState(() => _text = 'Ошибка: $e');
        } finally {
          NfcManager.instance.stopSession();
        }
      },
    );
  }

  // Универсальный UID для 4.x
  List<int>? _uid(NfcTag tag) {
    // ANDROID: общий id тега
    final aTag = NfcTagAndroid.from(tag);
    if (aTag != null && aTag.id.isNotEmpty) return aTag.id;

    // iOS: пробуем основные технологии
    if (MiFareIos.from(tag) case final t?) return t.identifier;
    if (Iso15693Ios.from(tag) case final t?) return t.identifier; // или t.icSerialNumber
    if (Iso7816Ios.from(tag) case final t?) return t.identifier;
    if (FeliCaIos.from(tag) case final t?) return t.currentIDm;

    return null;
  }

  String _hex(List<int> b) =>
      b.map((x) => x.toRadixString(16).padLeft(2, '0').toUpperCase()).join(':');

  @override
  Widget build(BuildContext c) => Scaffold(
        appBar: AppBar(title: const Text('NFC UID')),
        body: Center(child: SelectableText(_text)),
        floatingActionButton: FloatingActionButton(
          onPressed: _start,
          child: const Icon(Icons.nfc),
        ),
      );
}

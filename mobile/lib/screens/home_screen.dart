import 'package:flutter/material.dart';
import 'call_screen.dart';
import '../services/ultron_api.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _mode = 'companion';
  bool _connecting = false;
  String? _error;
  final _api = UltronApi();

  Future<void> _pairDevice() async {
    final controller = TextEditingController();
    final token = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('PAIR THIS DEVICE'),
        content: TextField(
          controller: controller,
          obscureText: true,
          decoration: const InputDecoration(
            labelText: 'ULTRON device token',
            hintText: 'Paste the token from your ULTRON backend administrator',
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL')),
          FilledButton(onPressed: () => Navigator.pop(context, controller.text.trim()),
              child: const Text('PAIR')),
        ],
      ),
    );
    controller.dispose();
    if (token == null || token.isEmpty) return;
    await _api.saveDeviceToken(token);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Device token stored securely on this device.')),
      );
    }
  }

  Future<void> _startCall() async {
    setState(() { _connecting = true; _error = null; });
    try {
      final session = await _api.createSession(_mode);
      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => CallScreen(session: session)),
      );
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _connecting = false);
    }
  }

  @override
  void dispose() {
    _api.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 18),
              const Text('ULTRON', textAlign: TextAlign.center,
                style: TextStyle(fontSize: 30, letterSpacing: 8,
                  fontWeight: FontWeight.w800, color: Color(0xFFFF3344))),
              const Text('MOBILE COMMAND INTERFACE', textAlign: TextAlign.center,
                style: TextStyle(fontSize: 10, letterSpacing: 3, color: Colors.white54)),
              const Spacer(),
              Container(
                height: 190,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0x99FF2638), width: 2),
                  boxShadow: const [BoxShadow(color: Color(0x44FF1028), blurRadius: 38)],
                ),
                child: const Center(child: Icon(Icons.memory, size: 92, color: Color(0xFFFF3344))),
              ),
              const SizedBox(height: 28),
              const Text('Choose operating mode', textAlign: TextAlign.center,
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'companion', label: Text('Companion'), icon: Icon(Icons.desktop_windows)),
                  ButtonSegment(value: 'independent', label: Text('Independent'), icon: Icon(Icons.cloud_outlined)),
                ],
                selected: {_mode},
                onSelectionChanged: (value) => setState(() => _mode = value.first),
              ),
              const SizedBox(height: 18),
              OutlinedButton.icon(
                onPressed: _pairDevice,
                icon: const Icon(Icons.phonelink_lock),
                label: const Text('PAIR DEVICE'),
              ),
              const SizedBox(height: 10),
              FilledButton.icon(
                onPressed: _connecting ? null : _startCall,
                icon: _connecting
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.call),
                label: Text(_connecting ? 'CONNECTING…' : 'CALL ULTRON'),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFC8172A),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(_error!, style: const TextStyle(color: Colors.redAccent), textAlign: TextAlign.center),
              ],
              const Spacer(),
              const Text('VOICE • VIDEO • AI • PC COMPANION', textAlign: TextAlign.center,
                style: TextStyle(fontSize: 10, letterSpacing: 2, color: Colors.white38)),
            ],
          ),
        ),
      ),
    );
  }
}

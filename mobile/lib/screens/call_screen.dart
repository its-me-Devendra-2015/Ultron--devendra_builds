import 'package:flutter/material.dart';
import 'package:livekit_client/livekit_client.dart';
import '../services/ultron_api.dart';

class CallScreen extends StatefulWidget {
  const CallScreen({super.key, required this.session});
  final UltronSession session;

  @override
  State<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends State<CallScreen> {
  final Room _room = Room();
  bool _connected = false;
  bool _muted = false;
  bool _cameraOn = false;
  bool _busy = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _connect();
  }

  Future<void> _connect() async {
    try {
      await _room.connect(
        widget.session.serverUrl,
        widget.session.participantToken,
        roomOptions: const RoomOptions(adaptiveStream: true, dynacast: true),
      );
      await _room.localParticipant?.setMicrophoneEnabled(true);
      if (!mounted) return;
      setState(() {
        _connected = true;
        _busy = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.toString();
        _busy = false;
      });
    }
  }

  Future<void> _toggleMic() async {
    final next = !_muted;
    await _room.localParticipant?.setMicrophoneEnabled(!next);
    if (mounted) setState(() => _muted = next);
  }

  Future<void> _toggleCamera() async {
    final next = !_cameraOn;
    await _room.localParticipant?.setCameraEnabled(next);
    if (mounted) setState(() => _cameraOn = next);
  }

  Future<void> _endCall() async {
    await _room.disconnect();
    if (mounted) Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _room.disconnect();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ULTRON • LIVE SESSION')),
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(),
            const Icon(Icons.hub, size: 100, color: Color(0xFFFF3344)),
            const SizedBox(height: 18),
            Text(_busy ? 'ESTABLISHING SECURE LINK' :
              _connected ? 'ULTRON CONNECTED' : 'CONNECTION FAILED',
              style: const TextStyle(letterSpacing: 2, fontWeight: FontWeight.bold)),
            if (_error != null) Padding(
              padding: const EdgeInsets.all(18),
              child: Text(_error!, textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.redAccent)),
            ),
            const SizedBox(height: 8),
            Text('ROOM  ${widget.session.roomName}',
                style: const TextStyle(color: Colors.white38, fontSize: 11)),
            const Spacer(),
            if (_connected) Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _Control(icon: _muted ? Icons.mic_off : Icons.mic,
                    label: _muted ? 'UNMUTE' : 'MUTE', onTap: _toggleMic),
                const SizedBox(width: 24),
                _Control(icon: _cameraOn ? Icons.videocam : Icons.videocam_off,
                    label: 'CAMERA', onTap: _toggleCamera),
                const SizedBox(width: 24),
                _Control(icon: Icons.call_end, label: 'END',
                    color: Colors.red, onTap: _endCall),
              ],
            ) else if (!_busy)
              FilledButton(onPressed: _endCall, child: const Text('CLOSE')),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

class _Control extends StatelessWidget {
  const _Control({required this.icon, required this.label,
    required this.onTap, this.color});
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      IconButton.filled(
        onPressed: onTap,
        icon: Icon(icon),
        style: IconButton.styleFrom(
          backgroundColor: color ?? const Color(0xFF4A1018),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.all(18),
        ),
      ),
      const SizedBox(height: 5),
      Text(label, style: const TextStyle(fontSize: 10, letterSpacing: 1)),
    ],
  );
}

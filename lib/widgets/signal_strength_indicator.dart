import 'package:flutter/material.dart';

/// Visual gauge that turns an RSSI value (roughly -100..-30 dBm) into
/// a friendly "distanza" indicator: a colored ring plus a label such
/// as "Lontano", "Ti stai avvicinando" or "Trovato!".
class SignalStrengthIndicator extends StatelessWidget {
  final int? rssi;

  const SignalStrengthIndicator({super.key, required this.rssi});

  double get _proximity {
    if (rssi == null) return 0;
    const minRssi = -100.0;
    const maxRssi = -40.0;
    final clamped = rssi!.clamp(minRssi, maxRssi);
    return (clamped - minRssi) / (maxRssi - minRssi);
  }

  String get _label {
    if (rssi == null) return 'Auricolari non rilevati';
    final p = _proximity;
    if (p > 0.85) return 'Trovati! Sono vicinissimi';
    if (p > 0.6) return 'Ti stai avvicinando';
    if (p > 0.3) return 'Continua a cercare';
    return 'Sono lontani';
  }

  Color get _color {
    if (rssi == null) return Colors.grey;
    final p = _proximity;
    if (p > 0.85) return Colors.green;
    if (p > 0.4) return Colors.orange;
    return Colors.redAccent;
  }

  @override
  Widget build(BuildContext context) {
    final size = 180.0 + _proximity * 60;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 400),
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _color.withValues(alpha: 0.15),
            border: Border.all(color: _color, width: 4),
          ),
          child: Center(
            child: Icon(Icons.headset, size: 64, color: _color),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          _label,
          style: Theme.of(context)
              .textTheme
              .titleLarge
              ?.copyWith(fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        if (rssi != null) ...[
          const SizedBox(height: 8),
          Text('Segnale: $rssi dBm',
              style: Theme.of(context).textTheme.bodyMedium),
        ],
      ],
    );
  }
}

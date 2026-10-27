import 'dart:async';

import 'package:flutter/material.dart';

/// Displays the current date and time in the device's local time zone.
class DashboardClock extends StatefulWidget {
  const DashboardClock({super.key});

  @override
  State<DashboardClock> createState() => _DashboardClockState();
}

class _DashboardClockState extends State<DashboardClock> {
  static const _months = [
    'enero',
    'febrero',
    'marzo',
    'abril',
    'mayo',
    'junio',
    'julio',
    'agosto',
    'septiembre',
    'octubre',
    'noviembre',
    'diciembre',
  ];
  DateTime _now = DateTime.now();
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _twoDigits(int value) => value.toString().padLeft(2, '0');

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Text(
        '${_now.day} de ${_months[_now.month - 1]} de ${_now.year}',
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          fontSize: 15,
        ),
      ),
      Text(
        '${_twoDigits(_now.hour)}:${_twoDigits(_now.minute)}:${_twoDigits(_now.second)}',
        style: const TextStyle(color: Colors.white, fontSize: 13),
      ),
    ],
  );
}

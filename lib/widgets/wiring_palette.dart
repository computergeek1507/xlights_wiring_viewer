import 'package:flutter/material.dart';

/// Fixed, visually distinct colors cycled by `node.strandIndex % length` to
/// group nodes by physical strand/arm/row in the wiring diagram.
const List<Color> wiringPalette = [
  Color(0xFFE53935), // red
  Color(0xFFFB8C00), // orange
  Color(0xFFFDD835), // yellow
  Color(0xFF43A047), // green
  Color(0xFF00ACC1), // cyan
  Color(0xFF1E88E5), // blue
  Color(0xFF5E35B1), // indigo
  Color(0xFF8E24AA), // purple
  Color(0xFFD81B60), // pink
  Color(0xFF6D4C41), // brown
  Color(0xFF546E7A), // blue-grey
  Color(0xFF00897B), // teal
];

Color colorForStrand(int? strandIndex) {
  if (strandIndex == null) return wiringPalette[0];
  return wiringPalette[strandIndex % wiringPalette.length];
}

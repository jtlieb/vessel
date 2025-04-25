import 'package:flutter/material.dart';

/// Represents the current interaction mode of the book reader
class InteractionModeState {
  bool isHighlightingMode = false;
  bool isSwipingMode = false;
}

/// Define interaction event type
enum InteractionEventType {
  down,
  up,
  cancel,
  move,
  doubleTap,
  highlightModeSet, // Using as a terminator for down-up-down state machine
}

/// Define interaction event class
class InteractionEvent {
  final InteractionEventType type;
  final int pointerId;
  final Offset position;
  final DateTime timestamp;

  InteractionEvent({
    required this.type,
    required this.pointerId,
    required this.position,
    required this.timestamp,
  });
}

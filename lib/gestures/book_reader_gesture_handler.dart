import 'package:flutter/material.dart';
import '../interaction/models/interaction.dart';

class BookReaderGestureHandler extends StatefulWidget {
  final Widget child;
  final bool isHighlightingMode;
  final bool isSwipingMode;
  final Function(bool) onSwipingModeChanged;
  final Function(bool) onHighlightModeChanged;
  final Function(Offset) onSentenceHighlightRequested;

  const BookReaderGestureHandler({
    super.key,
    required this.child,
    required this.isHighlightingMode,
    required this.isSwipingMode,
    required this.onSwipingModeChanged,
    required this.onHighlightModeChanged,
    required this.onSentenceHighlightRequested,
  });

  @override
  State<BookReaderGestureHandler> createState() =>
      _BookReaderGestureHandlerState();
}

class _BookReaderGestureHandlerState extends State<BookReaderGestureHandler> {
  // Track the first pointer to touch down - this will be our "anchor" pointer
  int? _anchorPointerId;

  // Track anchor pointer velocity
  Offset? _anchorPointerLastPosition;
  DateTime? _anchorPointerLastTimestamp;
  double _anchorPointerVelocity = 0.0;

  // Maximum allowed anchor pointer velocity (logical pixels per second)
  static const double _maxAnchorVelocity = 150.0;

  // Track all active pointers (ID -> is anchor)
  final Map<int, bool> _activePointers = {};

  // Flag to prevent recursive mode setting
  bool _isSettingMode = false;

  // LIFO history of interaction events
  final List<InteractionEvent> _eventHistory = [];

  // Maximum number of events to keep in history
  static const int _maxHistorySize = 200;

  // Minimum number of events to reduce history to
  static const int _minHistorySize = 10;

  // Maximum duration between down-up-down for highlight mode
  static const int _highlightSequenceDurationMs = 300;
  // Minimum duration between down-up-down for highlight mode
  static const int _highlightSequenceDurationMsMin = 75;

  // Timeout for anchor pointer movement
  static const int _anchorMoveTimeoutMs = 200;
  DateTime? _lastAnchorMoveTimestamp;

  // Convenience getters for current mode states
  bool get _isHighlightingMode => widget.isHighlightingMode;
  bool get _isSwipingMode => widget.isSwipingMode;

  @override
  Widget build(BuildContext context) {
    return Listener(
      // Use listener to get raw pointer events with IDs
      onPointerDown: (PointerDownEvent event) {
        print('Pointer down: ID ${event.pointer}');

        // Track active pointer
        _activePointers[event.pointer] = false;

        // If this is the first pointer, make it the anchor pointer
        if (_anchorPointerId == null) {
          _anchorPointerId = event.pointer;
          _activePointers[event.pointer] = true; // Mark as anchor

          // Initialize velocity tracking
          _anchorPointerLastPosition = event.position;
          _anchorPointerLastTimestamp = DateTime.now();
          _anchorPointerVelocity = 0.0;
        } else {
          // Check if we have an anchor timeout and this is a second pointer
          final now = DateTime.now();
          if (_lastAnchorMoveTimestamp != null &&
              now.difference(_lastAnchorMoveTimestamp!).inMilliseconds >
                  _anchorMoveTimeoutMs &&
              _anchorPointerId != null) {
            // Timeout has passed since last anchor movement, reset velocity data and enable swiping
            _anchorPointerLastPosition = null;
            _anchorPointerLastTimestamp = null;
            _anchorPointerVelocity = 0.0;
            print('Setting swiping mode to true');
            _setSwipingMode(true);
          }
        }
        // Record this event
        _addEvent(InteractionEventType.down, event.pointer, event.position);

        // Resolve states based on updated event history
        print('Pointer going to resolve');
        _resolveModesFromHistory();
      },

      onPointerUp: (PointerUpEvent event) {
        print('Pointer up: ID ${event.pointer}');

        // Record this event
        _addEvent(InteractionEventType.up, event.pointer, event.position);

        // Apply immediate state changes for pointer up
        if (_anchorPointerId == event.pointer) {
          // Reset the anchor pointer
          _anchorPointerId = null;
          _anchorPointerLastPosition = null;
          _anchorPointerLastTimestamp = null;
          _anchorPointerVelocity = 0.0;
          _lastAnchorMoveTimestamp = null;
        }

        // Remove from active pointers
        _activePointers.remove(event.pointer);

        // Resolve states based on updated event history
        print('Pointer going to resolve');
        _resolveModesFromHistory();
      },

      onPointerCancel: (PointerCancelEvent event) {
        print('Pointer cancel: ID ${event.pointer}');

        // Record this event
        _addEvent(InteractionEventType.cancel, event.pointer, event.position);

        // Apply immediate state changes for pointer cancel
        if (_anchorPointerId == event.pointer) {
          // Reset the anchor pointer
          _anchorPointerId = null;
          _anchorPointerLastPosition = null;
          _anchorPointerLastTimestamp = null;
          _anchorPointerVelocity = 0.0;
          _lastAnchorMoveTimestamp = null;
        }

        // Remove from active pointers
        _activePointers.remove(event.pointer);

        // Resolve states based on updated event history
        print('Pointer going to resolve');
        _resolveModesFromHistory();
      },

      onPointerMove: (PointerMoveEvent event) {
        // Track anchor pointer velocity if this is the anchor pointer
        if (event.pointer == _anchorPointerId && !_isHighlightingMode) {
          _updateAnchorVelocity(event.position);
          _setSwipingMode(_anchorPointerVelocity < _maxAnchorVelocity);

          // Update the last anchor move timestamp
          _lastAnchorMoveTimestamp = DateTime.now();
        }

        // If this is not the anchor pointer and we're in swiping mode,
        // this is the pointer that should trigger page turns
        if (event.pointer != _anchorPointerId &&
            _isSwipingMode &&
            !_isHighlightingMode) {
          // Page turns will be handled by the PageView physics
        }
      },

      child: widget.child,
    );
  }

  // Update anchor pointer velocity
  void _updateAnchorVelocity(Offset currentPosition) {
    if (_anchorPointerLastPosition == null ||
        _anchorPointerLastTimestamp == null) {
      _anchorPointerLastPosition = currentPosition;
      _anchorPointerLastTimestamp = DateTime.now();
      return;
    }

    final now = DateTime.now();
    final timeDeltaSeconds =
        now.difference(_anchorPointerLastTimestamp!).inMilliseconds / 1000.0;

    // Avoid division by zero or very small time deltas
    if (timeDeltaSeconds < 0.001) return;

    final distance = (currentPosition - _anchorPointerLastPosition!).distance;
    final instantVelocity = distance / timeDeltaSeconds;

    // Use exponential smoothing to avoid spikes
    // Alpha of 0.3 gives more weight to previous velocity for stability
    const alpha = 0.3;
    _anchorPointerVelocity =
        alpha * instantVelocity + (1 - alpha) * _anchorPointerVelocity;

    // Update last position and timestamp for next calculation
    _anchorPointerLastPosition = currentPosition;
    _anchorPointerLastTimestamp = now;

    // Debug
    if (_anchorPointerVelocity > 100) {
      print('Anchor velocity: $_anchorPointerVelocity px/s');
    }
  }

  // Add an event to the history
  void _addEvent(InteractionEventType type, int pointerId, Offset position) {
    // Avoid adding duplicate highlightModeSet events
    if (type == InteractionEventType.highlightModeSet &&
        _eventHistory.isNotEmpty &&
        _eventHistory.first.type == InteractionEventType.highlightModeSet) {
      return;
    }

    final InteractionEvent event = InteractionEvent(
      type: type,
      pointerId: pointerId,
      position: position,
      timestamp: DateTime.now(),
    );

    // Add to the beginning (LIFO)
    _eventHistory.insert(0, event);

    // Trim history if too long
    if (_eventHistory.length > _maxHistorySize) {
      _eventHistory.removeRange(_minHistorySize, _eventHistory.length);
    }

    // Debug
    print(
      'Event history: ${_eventHistory.map((e) => e.type).take(5).toList()}',
    );

    print('Event history length: ${_eventHistory.length}');
  }

  // Resolve swiping and highlighting modes based on event history
  void _resolveModesFromHistory() {
    // Set Highlighting Mode
    if (_eventHistory.isNotEmpty &&
        _eventHistory.first.type == InteractionEventType.up &&
        _eventHistory.first.pointerId != _anchorPointerId) {
      _setHighlightingMode(false);
    } else if (_isDownUpDownPattern()) {
      _setHighlightingMode(true);
      _setSwipingMode(false);
    }

    // Determine if we should be in swiping mode when not in highlighting mode
    if (!_isHighlightingMode) {
      bool shouldSwipe =
          _anchorPointerId != null &&
          _anchorPointerVelocity < _maxAnchorVelocity;
      _setSwipingMode(shouldSwipe);
    }
  }

  // Check if recent events follow down-up-down pattern within time threshold
  bool _isDownUpDownPattern() {
    // Need at least 3 events for down-up-down pattern
    if (_eventHistory.length < 3) return false;

    // Check for down-up-down pattern
    final isDownUpDownPattern =
        _eventHistory[0].type == InteractionEventType.down &&
        _eventHistory[1].type == InteractionEventType.up &&
        _eventHistory[2].type == InteractionEventType.down;

    // Check timing
    final isWithinTimeThreshold =
        _eventHistory[0].timestamp
                .difference(_eventHistory[2].timestamp)
                .inMilliseconds <
            _highlightSequenceDurationMs &&
        _eventHistory[0].timestamp
                .difference(_eventHistory[2].timestamp)
                .inMilliseconds >
            _highlightSequenceDurationMsMin;

    return isDownUpDownPattern && isWithinTimeThreshold;
  }

  void _setSwipingMode(bool value) {
    if (_isSwipingMode != value) {
      widget.onSwipingModeChanged(value);
    }
  }

  void _setHighlightingMode(bool value) {
    // Prevent recursive calls
    if (_isSettingMode) return;

    if (_isHighlightingMode != value) {
      _isSettingMode = true;

      // Update highlighting mode
      widget.onHighlightModeChanged(value);

      if (value) {
        // Add highlight mode set event
        _addEvent(InteractionEventType.highlightModeSet, -1, Offset.zero);

        // Highlighting mode overrides swiping mode
        _setSwipingMode(false);
      }

      _isSettingMode = false;
    }
  }
}

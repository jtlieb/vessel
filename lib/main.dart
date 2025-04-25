import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'dart:math';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Book Reader',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const MainTabScreen(),
    );
  }
}

class MainTabScreen extends StatefulWidget {
  const MainTabScreen({super.key});

  @override
  State<MainTabScreen> createState() => _MainTabScreenState();
}

class _MainTabScreenState extends State<MainTabScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Book Reader'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.book), text: 'Reader'),
            Tab(icon: Icon(Icons.star), text: 'Coming Soon'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        physics: const NeverScrollableScrollPhysics(), // Disable swipe
        children: const [
          BookReader(),
          Center(
            child: Text(
              'More features coming soon!',
              style: TextStyle(fontSize: 18),
            ),
          ),
        ],
      ),
    );
  }
}

/// Custom page scroll physics that makes animations 2/3 the default duration
class FastPageScrollPhysics extends PageScrollPhysics {
  /// Creates physics for a faster [PageView].
  const FastPageScrollPhysics({super.parent});

  @override
  FastPageScrollPhysics applyTo(ScrollPhysics? ancestor) {
    return FastPageScrollPhysics(parent: buildParent(ancestor));
  }

  @override
  SpringDescription get spring => const SpringDescription(
    mass: 100 * 1, // Reduce mass to 2/3 of default to speed up
    stiffness: 100 * 1, // Increase stiffness by 50% to speed up
    damping: 0.5, // Reduce damping for slightly faster animation
  );
}

class Interaction {
  final Action action;
  final DateTime timestamp;

  Interaction(this.action, this.timestamp);
}

enum Action { tapDown, tapUp, tapCancel, doubleTap, highlightModeSet }

class InteractionModeState {
  bool isHighlightingMode = false;
  bool isSwipingMode = false;
  // recent interactions oldest to newest
  List<Interaction> recentInteractions = [];

  static const int maxRecentInteractions = 100;
  static const int minRecentInteractions = 10;

  static const int highlightModeDownUpDownDurationMs = 300;

  void reset() {
    isHighlightingMode = false;
    isSwipingMode = false;
  }

  void setHighlightingMode() {
    isSwipingMode = false;

    if (isHighlightingMode == true) {
      return;
    }
    isHighlightingMode = true;
    // Push on with no side effects
    recentInteractions.add(
      Interaction(Action.highlightModeSet, DateTime.now()),
    );
  }

  void setSwipingMode() {
    isHighlightingMode = false;
    isSwipingMode = true;
  }

  bool addInteraction(Action gesture) {
    // Capture initial state
    bool initialHighlightingMode = isHighlightingMode;
    bool initialSwipingMode = isSwipingMode;

    // add gesture to beginning of list
    recentInteractions.add(Interaction(gesture, DateTime.now()));

    // resolve mode based on recent interactions w/ switch statement
    switch (recentInteractions.last.action) {
      case Action.tapDown:
        // Check eligibility for highlight mode
        if (isHighlightDownUpDown()) {
          setHighlightingMode();
        } else {
          setSwipingMode();
        }

        print("swiping Mode: " + isSwipingMode.toString());
        print("highlighting Mode: " + isHighlightingMode.toString());
        break;

      case Action.tapUp:
        // TODO: for now, this will always reset and stop highlighting mode. In reality,
        // we need to wait for the user to somehow dismiss the highlight mode.
        reset();
        break;
      case Action.doubleTap:
        setHighlightingMode();
        // TODO: this will kick off the process of highlighting the entire sentence
        break;
      case Action.tapCancel:
        // TODO: for now, this will always reset and stop highlighting mode. In reality,
        // we need to wait for the user to somehow dismiss the highlight mode.
        break;
      case Action.highlightModeSet:
      // pass -- this is handled in the state machine
    }

    if (recentInteractions.length > maxRecentInteractions) {
      recentInteractions = recentInteractions.sublist(
        recentInteractions.length - minRecentInteractions,
      );
    }

    // Return true if the state changed
    return initialHighlightingMode != isHighlightingMode ||
        initialSwipingMode != isSwipingMode;
  }

  bool isHighlightDownUpDown() {
    // check if the last 3 interactions are tapDown, tapUp, tapDown within threshold
    if (recentInteractions.length >= 3) {
      return recentInteractions[recentInteractions.length - 1].action ==
              Action.tapDown &&
          recentInteractions[recentInteractions.length - 2].action ==
              Action.tapUp &&
          recentInteractions[recentInteractions.length - 3].action ==
              Action.tapDown &&
          recentInteractions[recentInteractions.length - 1].timestamp
                  .difference(
                    recentInteractions[recentInteractions.length - 3].timestamp,
                  )
                  .inMilliseconds <
              highlightModeDownUpDownDurationMs;
    }
    return false;
  }
}

class BookReader extends StatefulWidget {
  const BookReader({super.key});

  @override
  State<BookReader> createState() => _BookReaderState();
}

class _BookReaderState extends State<BookReader> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  final InteractionModeState _interactionModeState =
      InteractionModeState(); // Use InteractionModeState

  // Lorem ipsum text - multiple paragraphs
  final List<String> _loremIpsumParagraphs = [
    'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Suspendisse varius enim in eros elementum tristique. Duis cursus, mi quis viverra ornare, eros dolor interdum nulla, ut commodo diam libero vitae erat. Aenean faucibus nibh et justo cursus id rutrum lorem imperdiet. Nunc ut sem vitae risus tristique posuere.',
    'Sed ut perspiciatis unde omnis iste natus error sit voluptatem accusantium doloremque laudantium, totam rem aperiam, eaque ipsa quae ab illo inventore veritatis et quasi architecto beatae vitae dicta sunt explicabo.',
    'Nemo enim ipsam voluptatem quia voluptas sit aspernatur aut odit aut fugit, sed quia consequuntur magni dolores eos qui ratione voluptatem sequi nesciunt. Neque porro quisquam est, qui dolorem ipsum quia dolor sit amet, consectetur, adipisci velit.',
    'At vero eos et accusamus et iusto odio dignissimos ducimus qui blanditiis praesentium voluptatum deleniti atque corrupti quos dolores et quas molestias excepturi sint occaecati cupiditate non provident, similique sunt in culpa qui officia deserunt mollitia animi.',
    'Nam libero tempore, cum soluta nobis est eligendi optio cumque nihil impedit quo minus id quod maxime placeat facere possimus, omnis voluptas assumenda est, omnis dolor repellendus. Temporibus autem quibusdam et aut officiis debitis.',
  ];

  // Generate a string with repeated lorem ipsum paragraphs
  String _generateLoremIpsum(int pageIndex) {
    String content = "";

    // mix up order of paragraphs
    List<String> mixedParagraphs = _loremIpsumParagraphs.toList();
    mixedParagraphs.shuffle(Random(pageIndex));

    for (String paragraph in mixedParagraphs) {
      content += paragraph + '\n\n';
    }

    return content;
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        BookReaderGestureHandler(
          onSwipingModeChanged: (isEnabled) {
            setState(() {
              _interactionModeState.isSwipingMode = isEnabled;
              print("Swiping mode set to: $isEnabled");
            });
          },
          onHighlightModeChanged: (isEnabled) {
            setState(() {
              _interactionModeState.isHighlightingMode = isEnabled;
              print("Highlighting mode set to: $isEnabled");
            });
          },
          onSentenceHighlightRequested: (position) {
            // TODO: Implement sentence highlighting
            print("Sentence highlight requested at: $position");
          },
          child: Column(
            children: [
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  physics:
                      _interactionModeState.isHighlightingMode
                          ? const NeverScrollableScrollPhysics()
                          : (_interactionModeState.isSwipingMode
                              ? const FastPageScrollPhysics()
                              : const NeverScrollableScrollPhysics()),
                  onPageChanged: (int page) {
                    setState(() {
                      _currentPage = page;
                    });
                  },
                  itemCount: 10,
                  itemBuilder: (context, index) {
                    return Container(
                      margin: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: Colors.grey.shade300,
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(8),
                        color: Colors.white,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: SingleChildScrollView(
                          child: Text(
                            _generateLoremIpsum(index),
                            style: const TextStyle(fontSize: 16, height: 1.5),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              // Page indicator
              Container(
                height: 40,
                color: Colors.grey.shade200,
                child: Center(
                  child: Text(
                    'Page ${_currentPage + 1} of 10',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
        // Debug overlay
        Positioned(
          bottom: 10,
          right: 10,
          child: Container(
            padding: const EdgeInsets.all(8),
            color: Colors.black54,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Current State:',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Highlighting: ${_interactionModeState.isHighlightingMode}',
                  style: const TextStyle(color: Colors.white),
                ),
                Text(
                  'Swiping: ${_interactionModeState.isSwipingMode}',
                  style: const TextStyle(color: Colors.white),
                ),
                const SizedBox(height: 8),
                Text(
                  'Recent Interactions:',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                for (var interaction in _interactionModeState.recentInteractions
                    .toList()
                    .reversed
                    .take(5))
                  Text(
                    '${interaction.action} at ${interaction.timestamp}',
                    style: const TextStyle(color: Colors.white),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class BookReaderGestureHandler extends StatefulWidget {
  final Widget child;
  final Function(bool) onSwipingModeChanged;
  final Function(bool) onHighlightModeChanged;
  final Function(Offset) onSentenceHighlightRequested;

  const BookReaderGestureHandler({
    super.key,
    required this.child,
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
  // Adjust this value based on testing
  static const double _maxAnchorVelocity = 100.0;

  // Timeout for anchor pointer velocity calculation. If no movement is detected
  // within this time, the anchor pointer velocity is considered to be 0.

  // Track all active pointers (ID -> is anchor)
  final Map<int, bool> _activePointers = {};

  // Track if we're in swiping mode
  bool _isSwipingMode = false;

  // Track if we're in highlighting mode
  bool _isHighlightingMode = false;

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
        }

        // Record move event (optional, can generate a lot of events)
        // _addEvent(InteractionEventType.move, event.pointer, event.position);

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
        _highlightSequenceDurationMs;

    return isDownUpDownPattern && isWithinTimeThreshold;
  }

  void _setSwipingMode(bool value) {
    if (_isSwipingMode != value) {
      _isSwipingMode = value;
      widget.onSwipingModeChanged(value);
    }
  }

  void _setHighlightingMode(bool value) {
    // Prevent recursive calls
    if (_isSettingMode) return;

    if (_isHighlightingMode != value) {
      _isSettingMode = true;

      _isHighlightingMode = value;
      if (value) {
        // Add highlight mode set event
        _addEvent(InteractionEventType.highlightModeSet, -1, Offset.zero);

        _isSwipingMode = false; // Highlighting mode overrides swiping mode
        widget.onSwipingModeChanged(false);
      }
      widget.onHighlightModeChanged(value);

      _isSettingMode = false;
    }
  }
}

// Define interaction event type
enum InteractionEventType {
  down,
  up,
  cancel,
  move,
  doubleTap,
  highlightModeSet,
}

// Define interaction event class
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

import 'package:flutter/material.dart';
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
        GestureDetector(
          // know when any gesture has happened
          onTapDown: (_) {
            _interactionModeState.addInteraction(Action.tapDown);
            setState(() {
              _interactionModeState.isSwipingMode = true;
            });
          },
          onTapUp: (_) {
            print('tap up');
            _interactionModeState.addInteraction(Action.tapUp);
            setState(() {
              _interactionModeState.reset(); // Reset modes on tap up
            });
          },
          onTapCancel: () {
            print('tap cancel');
            _interactionModeState.addInteraction(Action.tapCancel);
          },
          onHorizontalDragStart: (_) {
            print('horizontal drag start');
          },
          onDoubleTap: () {
            _interactionModeState.addInteraction(Action.doubleTap);
          },
          onPanStart: (_) {
            print("pan start");
          },
          onPanUpdate: (_) {
            print("pan update");
          },
          onPanEnd: (_) {
            print("pan end");
          },
          onPanCancel: () {
            print("pan cancel");
          },
          // swipe
          child: Column(
            children: [
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  physics:
                      _interactionModeState.isHighlightingMode
                          ? const NeverScrollableScrollPhysics() // Disable swipe in highlighting mode
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

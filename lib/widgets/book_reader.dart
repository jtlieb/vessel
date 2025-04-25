import 'package:flutter/material.dart';
import 'dart:math';
import '../models/interaction.dart';
import '../physics/fast_page_scroll_physics.dart';
import '../gestures/book_reader_gesture_handler.dart';

class BookReader extends StatefulWidget {
  const BookReader({super.key});

  @override
  State<BookReader> createState() => _BookReaderState();
}

class _BookReaderState extends State<BookReader> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  final InteractionModeState _interactionModeState = InteractionModeState();

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
          isHighlightingMode: _interactionModeState.isHighlightingMode,
          isSwipingMode: _interactionModeState.isSwipingMode,
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
              ],
            ),
          ),
        ),
      ],
    );
  }
}

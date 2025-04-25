import 'package:flutter/material.dart';
import 'dart:math';

class BookReaderScreen extends StatefulWidget {
  const BookReaderScreen({super.key});

  @override
  State<BookReaderScreen> createState() => _BookReaderScreenState();
}

class _BookReaderScreenState extends State<BookReaderScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _isTouching = false;

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
    return GestureDetector(
      onTapDown: (_) {
        setState(() {
          _isTouching = true;
        });
      },
      onTapUp: (_) {
        setState(() {
          _isTouching = false;
        });
      },
      onTapCancel: () {
        setState(() {
          _isTouching = false;
        });
      },
      child: Column(
        children: [
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              physics:
                  _isTouching
                      ? const FastPageScrollPhysics()
                      : const NeverScrollableScrollPhysics(),
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
                    border: Border.all(color: Colors.grey.shade300, width: 2),
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

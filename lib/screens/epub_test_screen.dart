import 'package:flutter/material.dart';
import 'package:epubx/epubx.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:html/parser.dart';
import 'dart:async';
import 'package:flutter/services.dart' show rootBundle;
import 'package:html/dom.dart' as dom;
import 'package:html/dom.dart' show Node;
import 'package:visibility_detector/visibility_detector.dart';

class EpubTestScreen extends StatefulWidget {
  const EpubTestScreen({super.key});

  @override
  State<EpubTestScreen> createState() => _EpubTestScreenState();
}

class _EpubTestScreenState extends State<EpubTestScreen> {
  String _bookInfo = 'No book loaded yet';
  bool _isLoading = false;
  EpubBook? _epubBook;
  String? _firstChapterHtml;
  final ScrollController _scrollController = ScrollController();
  String _visibleContent = "Nothing visible yet";
  List<dom.Element> _pElements = [];
  int _displayedParagraphs = 0;
  String _currentHtml = '';
  String? _splitParagraph = null;
  List<String> _paragraphTexts = [];
  List<bool> _paragraphVisibility = [];
  double _lastScrollPosition = 0;
  List<double> _paragraphHeights = [];

  void _calculateParagraphHeights() {
    if (_pElements.isEmpty) {
      print("No paragraphs to calculate");
      return;
    }

    _paragraphHeights.clear();
    final width = MediaQuery.of(context).size.width - 32 - 32 - 8 - 2;

    // Calculate available height based on the scroll view's height
    final screenHeight = MediaQuery.of(context).size.height;
    final safeAreaTop = MediaQuery.of(context).padding.top;
    final safeAreaBottom = MediaQuery.of(context).padding.bottom;
    final headerHeight =
        24.0 +
        20.0 +
        20.0 +
        8.0 +
        12.0 +
        10.0; // Title + buttons + visibility indicator + spacing
    final containerPadding = 16.0 * 2; // Top and bottom padding
    final containerMargin = 16.0 * 2; // Top and bottom margin
    final containerBorder = 2.0; // Border width
    final bookInfoHeight = 100.0; // Approximate height of book info section
    final dividerHeight = 1.0;

    final availableHeight =
        screenHeight -
        safeAreaTop -
        safeAreaBottom -
        headerHeight -
        containerPadding -
        containerMargin -
        containerBorder -
        bookInfoHeight -
        dividerHeight;

    print("Screen height: $screenHeight");
    print("Safe area top: $safeAreaTop");
    print("Safe area bottom: $safeAreaBottom");
    print("Header height: $headerHeight");
    print("Container padding: $containerPadding");
    print("Container margin: $containerMargin");
    print("Book info height: $bookInfoHeight");
    print("Available height: $availableHeight");
    print("Number of paragraphs: ${_pElements.length}");

    double totalHeight = 0;
    int visibleCount = 0;

    for (int i = 0; i < _pElements.length; i++) {
      final text = _pElements[i].text;
      if (text.trim().isEmpty) continue;

      final textPainter = TextPainter(
        text: TextSpan(
          text: text,
          style: const TextStyle(
            fontSize: 16,
            fontFamily: 'serif',
            height: 1.5,
          ),
        ),
        textDirection: TextDirection.ltr,
        maxLines: null,
      );

      textPainter.layout(maxWidth: width);
      final paragraphHeight =
          textPainter.height + 16 + 8; // text height + margin + padding
      _paragraphHeights.add(paragraphHeight);

      print(
        "Paragraph $i height: $paragraphHeight, total: ${totalHeight + paragraphHeight}",
      );

      if (totalHeight + paragraphHeight <= availableHeight) {
        totalHeight += paragraphHeight;
        visibleCount++;
      } else {
        print("Stopping at paragraph $i - would exceed available height");

        // Binary search to determine how many lines of this paragraph can fit
        final remainingHeight = availableHeight - totalHeight;
        int low = 1;
        int high = 100; // Assuming no paragraph has more than 100 lines
        int mid;
        double partialHeight;

        while (low < high) {
          mid = (low + high + 1) ~/ 2; // +1 to avoid infinite loop

          final partialTextPainter = TextPainter(
            text: TextSpan(
              text: text,
              style: const TextStyle(
                fontSize: 16,
                fontFamily: 'serif',
                height: 1.5,
              ),
            ),
            textDirection: TextDirection.ltr,
            maxLines: mid,
          );

          partialTextPainter.layout(maxWidth: width);
          partialHeight = partialTextPainter.height + 16 + 8;

          if (partialHeight <= remainingHeight) {
            low = mid;
          } else {
            high = mid - 1;
          }
        }

        // Use the maximum number of lines that fit
        if (low > 0) {
          _splitParagraph = text;
          _paragraphHeights.add(remainingHeight);
          visibleCount++; // Include partial paragraph
          print("Including partial paragraph with $low lines");
        }

        break;
      }
    }

    print("Final visible count: $visibleCount");
    print("Total height used: $totalHeight");
    setState(() {
      _displayedParagraphs = visibleCount;
      _updateHtmlContent();
    });
  }

  void _updateHtmlContent() {
    if (_pElements.isEmpty) return;

    _paragraphTexts.clear();
    for (int i = 0; i < _displayedParagraphs; i++) {
      if (i < _pElements.length) {
        final text = _pElements[i].text;
        if (text.trim().isNotEmpty) {
          _paragraphTexts.add(text);
        }
      }
    }
    print("Updated paragraph texts: ${_paragraphTexts.length}");
  }

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _calculateParagraphHeights();
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.hasClients) {
      final scrollPosition = _scrollController.position.pixels;
      final viewportHeight = _scrollController.position.viewportDimension;

      // Calculate which paragraphs are visible
      double currentY = 0;
      List<bool> newVisibility = [];

      for (int i = 0; i < _paragraphTexts.length; i++) {
        final text = _paragraphTexts[i];
        final textPainter = TextPainter(
          text: TextSpan(
            text: text,
            style: const TextStyle(
              fontSize: 16,
              fontFamily: 'serif',
              height: 1.5,
            ),
          ),
          textDirection: TextDirection.ltr,
          maxLines: null,
        );

        final width = MediaQuery.of(context).size.width - 32 - 32 - 8 - 2;
        textPainter.layout(maxWidth: width);
        final paragraphHeight =
            textPainter.height + 16 + 8; // text height + margin + padding

        final isVisible =
            currentY + paragraphHeight > scrollPosition &&
            currentY < scrollPosition + viewportHeight;

        newVisibility.add(isVisible);
        currentY += paragraphHeight;
      }

      setState(() {
        _paragraphVisibility = newVisibility;
        _lastScrollPosition = scrollPosition;
      });
    }
  }

  void _addNextParagraph() {
    if (_pElements.isNotEmpty && _displayedParagraphs < _pElements.length) {
      setState(() {
        _displayedParagraphs++;
        _updateHtmlContent();
      });
    }
  }

  Future<void> _loadBook() async {
    setState(() {
      _isLoading = true;
      _bookInfo = 'Loading book...';
      _firstChapterHtml = null;
      _pElements = [];
      _displayedParagraphs = 0;
      _currentHtml = '';
      _paragraphTexts = [];
      _paragraphHeights = [];
    });

    try {
      // Load book from assets
      final bookData = await rootBundle.load(
        'assets/books/Life on the Edge Quantum Biology 2015.epub',
      );
      final epubBook = await EpubReader.readBook(bookData.buffer.asUint8List());
      _epubBook = epubBook;

      // Extract book information
      final title = epubBook.Title ?? 'Unknown Title';
      final author = epubBook.Author ?? 'Unknown Author';
      final chaptersCount = epubBook.Chapters?.length ?? 0;

      // Get first HTML file content
      String? firstHtmlContent;
      if (epubBook.Content?.Html?.isNotEmpty == true) {
        final firstHtmlFile = epubBook.Content!.Html!.values.toList()[8];
        firstHtmlContent = firstHtmlFile.Content;

        var document = parse(firstHtmlContent);
        // Get all text elements (paragraphs, headings, etc.)
        _pElements =
            document
                .querySelectorAll("p, h1, h2, h3, h4, h5, h6")
                .where(
                  (element) =>
                      element.nodes.isNotEmpty &&
                      element.nodes.any(
                        (node) =>
                            node.nodeType == Node.TEXT_NODE &&
                            node.text!.trim().isNotEmpty,
                      ),
                )
                .toList();

        _calculateParagraphHeights();
      }

      setState(() {
        _bookInfo = '''
Book loaded successfully!
Title: $title
Author: $author
Chapters: $chaptersCount
''';
      });
    } catch (e) {
      setState(() {
        _bookInfo = 'Error loading book: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    print("Building with ${_paragraphTexts.length} paragraphs");
    print(
      "First paragraph text: ${_paragraphTexts.isNotEmpty ? _paragraphTexts.first : 'none'}",
    );
    return Scaffold(
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'EPUB Testing Screen',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: _isLoading ? null : _loadBook,
                  child: const Text('Load Sample EPUB'),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed:
                      _firstChapterHtml != null
                          ? () {
                            _scrollController.animateTo(
                              _scrollController.position.pixels + 300,
                              duration: const Duration(milliseconds: 500),
                              curve: Curves.easeInOut,
                            );
                          }
                          : null,
                  child: const Text('Scroll Down'),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed:
                      _pElements.isNotEmpty &&
                              _displayedParagraphs < _pElements.length
                          ? _addNextParagraph
                          : null,
                  child: const Text('Add Paragraph'),
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Visibility indicator
            Container(
              padding: const EdgeInsets.all(8),
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.blue.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _visibleContent,
                style: const TextStyle(fontSize: 12),
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: Container(
                width: double.infinity,
                margin: const EdgeInsets.symmetric(horizontal: 16.0),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child:
                    _pElements.isNotEmpty
                        ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _bookInfo,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Divider(),
                            Expanded(
                              child: SingleChildScrollView(
                                controller: _scrollController,
                                // physics: const NeverScrollableScrollPhysics(),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children:
                                      _paragraphTexts.map((text) {
                                        return CustomParagraphPainter(
                                          text: text,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontFamily: 'serif',
                                            height: 1.5,
                                            color: Colors.black,
                                          ),
                                          padding: const EdgeInsets.all(4),
                                          margin: const EdgeInsets.only(
                                            bottom: 16,
                                          ),
                                        );
                                      }).toList(),
                                ),
                              ),
                            ),
                          ],
                        )
                        : SingleChildScrollView(
                          child: Text(
                            _bookInfo,
                            style: const TextStyle(fontSize: 16),
                          ),
                        ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CustomParagraphPainter extends StatelessWidget {
  final String text;
  final TextStyle style;
  final EdgeInsets padding;
  final EdgeInsets margin;

  const CustomParagraphPainter({
    Key? key,
    required this.text,
    required this.style,
    required this.padding,
    required this.margin,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.green, width: 1),
      ),
      padding: padding,
      width: double.infinity,
      child: CustomPaint(
        painter: TextPainterWidget(text: text, style: style),
        size: Size(double.infinity, _calculateTextHeight(context)),
      ),
    );
  }

  double _calculateTextHeight(BuildContext context) {
    final textPainter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
      maxLines: null,
    );

    final width = MediaQuery.of(context).size.width - 32 - 32 - 8 - 2;
    textPainter.layout(maxWidth: width);
    return textPainter.height + padding.vertical;
  }
}

class TextPainterWidget extends CustomPainter {
  final String text;
  final TextStyle style;

  TextPainterWidget({required this.text, required this.style});

  @override
  void paint(Canvas canvas, Size size) {
    final textPainter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
      maxLines: null,
    );

    textPainter.layout(maxWidth: size.width);
    textPainter.paint(canvas, Offset.zero);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}

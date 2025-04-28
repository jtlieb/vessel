import 'package:flutter/material.dart';
import 'package:epubx/epubx.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:html/parser.dart';
import 'dart:async';
import 'package:flutter/services.dart' show rootBundle;
import 'package:html/dom.dart' as dom;
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
  double _htmlViewportHeight = 300; // Default height for the HTML viewport
  bool _isDragging = false;
  List<dom.Element> _pElements = [];
  int _displayedParagraphs = 0;
  String _currentHtml = '';
  String? _splitParagraph = null;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    // Calculate which content is visible based on scroll position
    final double scrollPosition = _scrollController.position.pixels;
    final double maxScrollExtent = _scrollController.position.maxScrollExtent;
    final double viewportHeight = _scrollController.position.viewportDimension;

    // Calculate the percentage through the content
    final double scrollPercentage =
        maxScrollExtent > 0
            ? double.parse(
              (scrollPosition / maxScrollExtent * 100).toStringAsFixed(1),
            )
            : 0.0;

    // Get visible range
    final double visibleStart = scrollPosition;
    final double visibleEnd = scrollPosition + viewportHeight;

    setState(() {
      _visibleContent =
          'Visible section: ${visibleStart.toStringAsFixed(0)} to ${visibleEnd.toStringAsFixed(0)} px\n'
          'Scroll position: $scrollPercentage%';
    });
  }

  void _addNextParagraph() {
    if (_pElements.isNotEmpty && _displayedParagraphs < _pElements.length) {
      setState(() {
        _displayedParagraphs++;
        _updateHtmlContent();
      });
    }
  }

  void _updateHtmlContent() {
    if (_pElements.isEmpty) return;

    // Create a new HTML string with only the paragraphs we want to display
    final buffer = StringBuffer();
    for (int i = 0; i < _displayedParagraphs; i++) {
      if (i < _pElements.length) {
        buffer.write(_pElements[i].outerHtml);
      }
    }

    _currentHtml = buffer.toString();
    _firstChapterHtml = _currentHtml;
  }

  Future<void> _loadBook() async {
    setState(() {
      _isLoading = true;
      _bookInfo = 'Loading book...';
      _firstChapterHtml = null;
      _pElements = [];
      _displayedParagraphs = 0;
      _currentHtml = '';
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
        _pElements = document.getElementsByTagName("p");

        // Start with one paragraph
        _displayedParagraphs = 1;
        _updateHtmlContent();
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
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    height: _htmlViewportHeight,
                    margin: const EdgeInsets.symmetric(horizontal: 16.0),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child:
                        _firstChapterHtml != null
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
                                SingleChildScrollView(
                                  child: VisibilityDetector(
                                    key: Key('test'),
                                    onVisibilityChanged: (visibilityInfo) {
                                      print(
                                        'Visibility info: ${visibilityInfo.visibleFraction}',
                                      );
                                    },
                                    child: Html(
                                      data: _firstChapterHtml!,
                                      style: {
                                        "p": Style(
                                          fontSize: FontSize(16),
                                          fontFamily: 'serif',
                                          lineHeight: LineHeight(1.5),
                                          margin: Margins.only(bottom: 16),
                                          border: Border.all(
                                            color: Colors.green,
                                            width: 1,
                                          ),
                                          padding: HtmlPaddings.all(4),
                                        ),
                                      },
                                      onAnchorTap: (url, _, __) {
                                        // You can handle anchor taps here
                                        print('Tapped on link: $url');
                                      },
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
                  // Resizable handle
                  GestureDetector(
                    onVerticalDragStart: (_) {
                      setState(() {
                        _isDragging = true;
                      });
                    },
                    onVerticalDragUpdate: (details) {
                      setState(() {
                        _htmlViewportHeight =
                            (_htmlViewportHeight + details.delta.dy).clamp(
                              100.0,
                              MediaQuery.of(context).size.height - 200,
                            );
                      });
                    },
                    onVerticalDragEnd: (_) {
                      setState(() {
                        _isDragging = false;
                      });
                    },
                    child: Container(
                      width: double.infinity,
                      height: 16,
                      margin: const EdgeInsets.symmetric(horizontal: 16.0),
                      decoration: BoxDecoration(
                        color:
                            _isDragging
                                ? Colors.grey.shade400
                                : Colors.grey.shade300,
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(8),
                          bottomRight: Radius.circular(8),
                        ),
                      ),
                      child: Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade600,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Remaining space
                  Expanded(
                    child: Container(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 8.0,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Center(
                        child: Text('Additional content can go here'),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

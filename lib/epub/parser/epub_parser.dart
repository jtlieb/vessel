import 'package:epubx/epubx.dart';
import 'package:flutter/services.dart' show rootBundle;

class EpubParser {
  static Future<EpubBook> loadAndParseBook(String path) async {
    // Load book from assets -- for now. In the future will come from file system
    final bookData = await rootBundle.load(
      'assets/books/Hidden Messages in Water.epub',
    );
    final epubBook = await EpubReader.readBook(bookData.buffer.asUint8List());

    return epubBook;
  }
}

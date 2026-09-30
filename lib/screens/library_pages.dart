import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:pdfrx/pdfrx.dart';

import '../core/l10n.dart';
import '../data/console_repository.dart';
import '../theme/app_theme.dart';
import '../widgets/tawasul_widgets.dart';

/// E-book library: the digital books in the school Library catalogue.
class EbookLibraryPage extends StatefulWidget {
  const EbookLibraryPage({super.key, required this.repository, required this.personId, this.bookmarksEnabled = false});

  final ConsoleRepository repository;
  final String personId;

  /// Students keep their place and bookmarks in every book.
  final bool bookmarksEnabled;

  @override
  State<EbookLibraryPage> createState() => _EbookLibraryPageState();
}

class _EbookLibraryPageState extends State<EbookLibraryPage> {
  late Future<EbookCatalog> _future = widget.repository.ebooks();
  String _query = '';
  Map<String, ReadingState> _reading = {};

  Future<void> _loadReading(List<EbookItem> books) async {
    if (!widget.bookmarksEnabled) return;
    final map = <String, ReadingState>{};
    for (final book in books) {
      map['${book.source}/${book.id}'] = await widget.repository.readingState(widget.personId, book);
    }
    if (mounted) setState(() => _reading = map);
  }

  @override
  void initState() {
    super.initState();
    _future.then((catalog) => _loadReading(catalog.books)).catchError((_) {});
  }

  Future<void> _reload() async {
    setState(() => _future = widget.repository.ebooks());
    _future.then((catalog) => _loadReading(catalog.books)).catchError((_) {});
    await _future.catchError((_) => const EbookCatalog(books: [], reason: EbookEmptyReason.none, recordsScanned: 0));
  }

  Future<void> _open(EbookItem book) async {
    final strings = L10n.of(context);
    await Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (_) => Directionality(
        textDirection: strings.direction,
        child: PdfReaderPage(
          book: book,
          repository: widget.repository,
          personId: widget.personId,
          bookmarksEnabled: widget.bookmarksEnabled,
        ),
      ),
    ));
    final snapshot = await _future.catchError((_) => const EbookCatalog(books: [], reason: EbookEmptyReason.none, recordsScanned: 0));
    await _loadReading(snapshot.books);
  }

  Widget? _subtitle(EbookItem book, L10n strings) {
    final state = _reading['${book.source}/${book.id}'];
    final resume = state != null && state.lastPage > 1;
    if (book.author.isEmpty && !resume) return null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (book.author.isNotEmpty) Text(book.author, style: const TextStyle(color: AppColors.muted)),
        if (resume)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Row(children: [
              const Icon(Icons.bookmark, size: 14, color: AppColors.gold),
              const SizedBox(width: 4),
              Text(
                state.totalPages > 0
                    ? '${strings.continueFrom(state.lastPage)} / ${state.totalPages}'
                    : strings.continueFrom(state.lastPage),
                style: const TextStyle(color: AppColors.green, fontWeight: FontWeight.w700, fontSize: 12),
              ),
            ]),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final strings = L10n.of(context);
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        backgroundColor: AppColors.cream,
        foregroundColor: AppColors.pine,
        elevation: 0,
        title: Text(strings.ebooks, style: const TextStyle(fontWeight: FontWeight.w800)),
      ),
      body: FutureBuilder<EbookCatalog>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return Center(child: Text(strings.loading, style: const TextStyle(color: AppColors.muted)));
          }
          final catalog = snap.data;
          final all = catalog?.books ?? const <EbookItem>[];
          final q = _query.trim().toLowerCase();
          final books = q.isEmpty
              ? all
              : all.where((b) => '${b.title} ${b.author}'.toLowerCase().contains(q)).toList();
          return RefreshIndicator(
            onRefresh: _reload,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.only(bottom: 24),
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                  child: TextField(
                    onChanged: (value) => setState(() => _query = value),
                    decoration: InputDecoration(
                      hintText: strings.searchBooks,
                      prefixIcon: const Icon(Icons.search, color: AppColors.muted),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadii.sm),
                        borderSide: const BorderSide(color: AppColors.line),
                      ),
                    ),
                  ),
                ),
                if (catalog != null && catalog.books.isEmpty && catalog.reason != EbookEmptyReason.none)
                  WhitePanel(
                    title: strings.whyNoBooks,
                    child: Text(
                      switch (catalog.reason) {
                        EbookEmptyReason.noPermission => strings.reasonNoPermission,
                        EbookEmptyReason.noPdfLinks => strings.reasonNoPdfLinks,
                        _ => strings.reasonCatalogueEmpty,
                      },
                      style: const TextStyle(color: AppColors.ink, height: 1.6),
                    ),
                  ),
                WhitePanel(
                  title: '${strings.ebooks} · ${books.length}',
                  child: books.isEmpty
                      ? EmptyState(message: snap.hasError ? strings.networkError : strings.noBooks)
                      : Column(
                          children: books
                              .map((book) => ListTile(
                                    contentPadding: EdgeInsets.zero,
                                    leading: Container(
                                      width: 44,
                                      height: 56,
                                      decoration: BoxDecoration(
                                        color: AppColors.mint,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      clipBehavior: Clip.antiAlias,
                                      child: book.cover.isEmpty
                                          ? const Icon(Icons.menu_book_rounded, color: AppColors.pine)
                                          : Image.network(book.cover, fit: BoxFit.cover,
                                              errorBuilder: (_, __, ___) =>
                                                  const Icon(Icons.menu_book_rounded, color: AppColors.pine)),
                                    ),
                                    title: Text(book.title,
                                        style: const TextStyle(color: AppColors.ink, fontWeight: FontWeight.w800)),
                                    subtitle: _subtitle(book, strings),
                                    trailing: const Icon(Icons.chevron_right, color: AppColors.muted),
                                    onTap: () => _open(book),
                                  ))
                              .toList(),
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Full-screen PDF reader with page counter.
class PdfReaderPage extends StatefulWidget {
  const PdfReaderPage({
    super.key,
    required this.book,
    required this.repository,
    required this.personId,
    this.bookmarksEnabled = false,
  });

  final EbookItem book;
  final ConsoleRepository repository;
  final String personId;
  final bool bookmarksEnabled;

  @override
  State<PdfReaderPage> createState() => _PdfReaderPageState();
}

class _PdfReaderPageState extends State<PdfReaderPage> {
  late Future<Uint8List> _future = widget.repository.ebookBytes(widget.book);
  final _controller = PdfViewerController();
  int _page = 1;
  int _total = 0;
  ReadingState _state = const ReadingState();
  bool _restored = false;

  @override
  void initState() {
    super.initState();
    if (widget.bookmarksEnabled) {
      widget.repository.readingState(widget.personId, widget.book).then((state) {
        if (mounted) setState(() => _state = state);
      });
    }
  }

  void _persist() {
    if (!widget.bookmarksEnabled) return;
    widget.repository.saveReadingState(widget.personId, widget.book, _state);
  }

  Future<void> _restore() async {
    if (_restored || !widget.bookmarksEnabled) return;
    _restored = true;
    var saved = _state;
    if (saved.lastPage == 0) {
      saved = await widget.repository.readingState(widget.personId, widget.book);
      if (mounted) setState(() => _state = saved);
    }
    final target = saved.lastPage;
    if (target > 1 && target <= _total && mounted) {
      await _controller.goToPage(pageNumber: target);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(L10n.of(context).resumedAt(target)), duration: const Duration(seconds: 2)),
        );
      }
    }
  }

  bool get _pageBookmarked => _state.bookmarks.contains(_page);

  void _toggleBookmark() {
    final marks = [..._state.bookmarks];
    _pageBookmarked ? marks.remove(_page) : marks.add(_page);
    marks.sort();
    setState(() => _state = _state.copyWith(bookmarks: marks));
    _persist();
  }

  void _showBookmarks() {
    final strings = L10n.of(context);
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.panel,
      builder: (sheetContext) => Directionality(
        textDirection: strings.direction,
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
                child: Text(strings.bookmarks,
                    style: const TextStyle(color: AppColors.pine, fontSize: 18, fontWeight: FontWeight.w900)),
              ),
              if (_state.bookmarks.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text(strings.noBookmarks, style: const TextStyle(color: AppColors.muted)),
                )
              else
                Flexible(
                  child: ListView(
                    shrinkWrap: true,
                    children: _state.bookmarks
                        .map((page) => ListTile(
                              leading: const Icon(Icons.bookmark, color: AppColors.gold),
                              title: Text(strings.pageNumber(page),
                                  style: const TextStyle(color: AppColors.ink, fontWeight: FontWeight.w700)),
                              trailing: IconButton(
                                tooltip: strings.removeBookmark,
                                icon: const Icon(Icons.close, color: AppColors.muted),
                                onPressed: () {
                                  setState(() => _state = _state.copyWith(
                                      bookmarks: _state.bookmarks.where((p) => p != page).toList()));
                                  _persist();
                                  Navigator.of(sheetContext).pop();
                                },
                              ),
                              onTap: () {
                                Navigator.of(sheetContext).pop();
                                _controller.goToPage(pageNumber: page);
                              },
                            ))
                        .toList(),
                  ),
                ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final strings = L10n.of(context);
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        backgroundColor: AppColors.cream,
        foregroundColor: AppColors.pine,
        elevation: 0,
        title: Text(widget.book.title,
            maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800)),
        actions: [
          if (_total > 0)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(strings.pageOf(_page, _total),
                    style: const TextStyle(color: AppColors.muted, fontWeight: FontWeight.w700)),
              ),
            ),
          if (widget.bookmarksEnabled && _total > 0) ...[
            IconButton(
              tooltip: _pageBookmarked ? strings.removeBookmark : strings.addBookmark,
              icon: Icon(_pageBookmarked ? Icons.bookmark : Icons.bookmark_border,
                  color: _pageBookmarked ? AppColors.gold : AppColors.pine),
              onPressed: _toggleBookmark,
            ),
            IconButton(
              tooltip: strings.bookmarks,
              icon: const Icon(Icons.collections_bookmark_outlined, color: AppColors.pine),
              onPressed: _showBookmarks,
            ),
          ],
        ],
      ),
      body: FutureBuilder<Uint8List>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return Center(child: Text(strings.openingBook, style: const TextStyle(color: AppColors.muted)));
          }
          if (snap.hasError || snap.data == null || snap.data!.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.error_outline, color: AppColors.muted, size: 34),
                  const SizedBox(height: 12),
                  Text(strings.bookFailed,
                      style: const TextStyle(color: AppColors.ink, fontWeight: FontWeight.w800)),
                  if (snap.error.toString().toLowerCase().contains('file transfer'))
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(strings.reasonFileTransferOff,
                          textAlign: TextAlign.center, style: const TextStyle(color: AppColors.muted, height: 1.6)),
                    ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: 180,
                    child: PrimaryButton(
                      label: strings.retry,
                      onPressed: () => setState(() => _future = widget.repository.ebookBytes(widget.book)),
                    ),
                  ),
                ]),
              ),
            );
          }
          return PdfViewer.data(
            snap.data!,
            sourceName: 'ebook-${widget.book.id}',
            controller: _controller,
            params: PdfViewerParams(
              backgroundColor: AppColors.cream,
              onViewerReady: (document, controller) {
                if (!mounted) return;
                setState(() {
                  _total = document.pages.length;
                  _state = _state.copyWith(totalPages: _total);
                });
                _restore();
              },
              onPageChanged: (page) {
                if (page == null || !mounted) return;
                setState(() {
                  _page = page;
                  // Remember the place only after the saved one was restored,
                  // so opening on page 1 never overwrites it.
                  if (_restored) _state = _state.copyWith(lastPage: page);
                });
                if (_restored) _persist();
              },
            ),
          );
        },
      ),
    );
  }
}

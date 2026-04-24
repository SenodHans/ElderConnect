/// Fetches personalised news articles for the elder via the news-proxy Edge
/// Function (which proxies NewsAPI so the API key never lives in the client).
///
/// Supports infinite-scroll pagination: [NewsNotifier.loadMore] appends the
/// next page. Pull-to-refresh via [ref.invalidate] resets to page 1.
/// Falls back to curated static articles when the network is unavailable.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class NewsArticle {
  const NewsArticle({
    required this.title,
    required this.source,
    required this.category,
    required this.readMinutes,
    this.description,
    this.content,
    this.imageUrl,
    this.url,
  });

  final String title;
  final String source;
  final String category;
  final int readMinutes;
  /// Short article excerpt from NewsAPI (~260 chars).
  final String? description;
  /// Article body snippet from NewsAPI (~200 words). Truncation marker stripped.
  final String? content;
  final String? imageUrl;
  final String? url;
}

/// Holds the current list of articles and pagination state.
class NewsState {
  const NewsState({
    required this.articles,
    required this.hasMore,
    required this.page,
    this.isLoadingMore = false,
  });

  final List<NewsArticle> articles;
  final bool hasMore;
  final int page;
  final bool isLoadingMore;

  NewsState copyWith({
    List<NewsArticle>? articles,
    bool? hasMore,
    int? page,
    bool? isLoadingMore,
  }) =>
      NewsState(
        articles: articles ?? this.articles,
        hasMore: hasMore ?? this.hasMore,
        page: page ?? this.page,
        isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      );
}

/// Static fallback shown when network is unavailable or interests are empty.
const _fallback = [
  NewsArticle(
    title: 'The Benefits of a Daily Walk for Seniors',
    source: 'Health Today',
    category: 'HEALTH',
    readMinutes: 4,
  ),
  NewsArticle(
    title: 'Simple Brain Games That Keep Your Mind Sharp',
    source: 'Wellness Weekly',
    category: 'WELLNESS',
    readMinutes: 3,
  ),
  NewsArticle(
    title: 'Staying Social: Why Connection Matters at Every Age',
    source: 'Senior Living',
    category: 'LIFESTYLE',
    readMinutes: 5,
  ),
];

const _pageSize = 10;

/// Paginated news notifier. Call [loadMore] to append the next page.
/// Invalidating the provider resets to page 1 (used by pull-to-refresh).
class NewsNotifier extends AsyncNotifier<NewsState> {
  String _query = 'health seniors';
  List<String> _interestList = [];

  @override
  Future<NewsState> build() async {
    final client = Supabase.instance.client;
    final userId = client.auth.currentUser?.id;

    // Resolve interests once per build; reused by loadMore without extra DB calls.
    _query = 'health seniors';
    _interestList = [];
    if (userId != null) {
      final profile = await client
          .from('users')
          .select('interests')
          .eq('id', userId)
          .maybeSingle();
      final interests = (profile?['interests'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [];
      if (interests.isNotEmpty) {
        _query = interests.join(' OR ');
        _interestList = interests;
      }
    }

    return _fetchPage(page: 1, existing: []);
  }

  /// Appends the next page of articles. No-ops when already loading or no more pages.
  Future<void> loadMore() async {
    final current = state.valueOrNull;
    if (current == null || !current.hasMore || current.isLoadingMore) return;

    state = AsyncData(current.copyWith(isLoadingMore: true));
    try {
      final next = await _fetchPage(page: current.page + 1, existing: current.articles);
      state = AsyncData(next);
    } catch (_) {
      state = AsyncData(current.copyWith(isLoadingMore: false));
    }
  }

  Future<NewsState> _fetchPage({
    required int page,
    required List<NewsArticle> existing,
  }) async {
    try {
      // Pass the anon key explicitly — Edge Function runtime rejects ES256 user tokens.
      const anonKey = String.fromEnvironment('SUPABASE_ANON_KEY');
      final client = Supabase.instance.client;
      final response = await client.functions.invoke(
        'news-proxy',
        body: {'query': _query, 'pageSize': _pageSize, 'page': page},
        headers: {'Authorization': 'Bearer $anonKey'},
      );

      if (response.status != 200) return _fallbackState(page, existing);

      final data = response.data as Map<String, dynamic>;
      final rawArticles = (data['articles'] as List<dynamic>?) ?? [];
      final totalResults = (data['totalResults'] as num?)?.toInt() ?? 0;

      if (rawArticles.isEmpty) return _fallbackState(page, existing);

      final fetched = rawArticles.map((a) {
        final map = a as Map<String, dynamic>;
        final wordCount = ((map['content'] as String?) ?? '').split(' ').length;
        // NewsAPI truncates content with "[+XXXX chars]" — strip it for clean display.
        final rawContent = map['content'] as String? ?? '';
        final cleanContent = rawContent
            .replaceAll(RegExp(r'\s*\[[\+\d]+ chars?\]$'), '')
            .trim();
        return NewsArticle(
          title: map['title'] as String? ?? '',
          source: (map['source'] as Map<String, dynamic>?)?['name'] as String? ?? 'News',
          category: _interestList.isNotEmpty ? _interestList.first.toUpperCase() : 'NEWS',
          readMinutes: (wordCount / 200).ceil().clamp(1, 15),
          description: map['description'] as String?,
          content: cleanContent.isEmpty ? null : cleanContent,
          imageUrl: map['urlToImage'] as String?,
          url: map['url'] as String?,
        );
      }).toList();

      final allArticles = [...existing, ...fetched];
      // hasMore is true when NewsAPI has more results beyond what we've loaded.
      final hasMore = fetched.isNotEmpty && allArticles.length < totalResults;

      return NewsState(articles: allArticles, hasMore: hasMore, page: page);
    } catch (_) {
      return _fallbackState(page, existing);
    }
  }

  NewsState _fallbackState(int page, List<NewsArticle> existing) {
    if (page == 1) return const NewsState(articles: _fallback, hasMore: false, page: 1);
    return NewsState(articles: existing, hasMore: false, page: page - 1);
  }
}

final newsProvider =
    AsyncNotifierProvider<NewsNotifier, NewsState>(() => NewsNotifier());

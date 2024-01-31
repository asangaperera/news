// user_provider.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'package:share/share.dart';

class Source {
  final String? id;
  final String name;

  Source({
    this.id,
    required this.name,
  });

  factory Source.fromJson(Map<String, dynamic> json) => Source(
    id: json['id'],
    name: json['name'] ?? "",
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "name": name,
  };
}

class Article {
  final Source source;
  final String? author;
  String title;
  final String description;
  final String url;
  final String urlToImage;
  final String publishedAt;
  final String content;
  bool liked; // Add this line

  Article({
    required this.source,
    this.author,
    required this.title,
    required this.description,
    required this.url,
    required this.urlToImage,
    required this.publishedAt,
    required this.content,
    this.liked = false, // Provide a default value for liked
  });


  factory Article.fromJson(Map<String, dynamic> json) => Article(
    source: Source.fromJson(json['source']),
    author: json['author'],
    title: json['title'] ?? "",
    description: json['description'] ?? "",
    url: json['url'] ?? "",
    urlToImage: json['urlToImage'] ?? "",
    publishedAt: json['publishedAt'] ?? "",
    content: json['content'] ?? "",
  );

  Map<String, dynamic> toJson() => {
    "source": source.toJson(),
    "author": author,
    "title": title,
    "description": description,
    "url": url,
    "urlToImage": urlToImage,
    "publishedAt": publishedAt,
    "content": content,
  };
}

class UserModel {
  final String status;
  final int totalResults;
  List<Article> articles;

  UserModel({
    required this.status,
    required this.totalResults,
    required this.articles,
  });

  Source? get source {
    if (UserProvider.instance.user?.articles.isNotEmpty == true) {
      return UserProvider.instance.user?.articles.first.source;
    }
    return null;
  }

  Map<String, dynamic> toJson() => {
    "status": status,
    "totalResults": totalResults,
    "articles": List<dynamic>.from(articles.map((x) => x.toJson())),
  };

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
    status: json["status"] ?? "",
    totalResults: json["totalResults"] ?? 0,
    articles: (json["articles"] as List<dynamic>?)
        ?.map((x) => Article.fromJson(x))
        .toList() ?? [],
  );

}

class UserProvider with ChangeNotifier {
  UserModel? _user;
  List<Article>? _originalArticles;
  int _currentPage = 1;
  final int _articlesPerPage = 10;

  UserModel? get user => _user;
  List<Article>? get originalArticles => _originalArticles;

  static UserProvider instance = UserProvider();

  Future<void> fetchUserArticles(String source) async {
    try {
      _currentPage = 1;

      final String customUrl = _buildCustomUrl(source);
      final response = await http.get(Uri.parse(customUrl));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);

        UserModel newUserData = UserModel.fromJson(data);

        if (_user == null) {
          _user = newUserData;
        } else {
          _user?.articles = List.from(newUserData.articles);
        }

        _originalArticles = List.from(_user!.articles);
        notifyListeners();
      } else {
        throw Exception('Failed to load user data. Status code: ${response.statusCode}');
      }
    } catch (error) {
      throw Exception('Error: $error');
    }
  }

  Future<List<Article>> fetchAppleNews() async {
    return _fetchUserArticles('apple');
  }

  Future<List<Article>> fetchTeslaNews() async {
    return _fetchUserArticles('tesla');
  }

  Future<List<Article>> fetchBusinessNews() async {
    return _fetchUserArticles('business');
  }

  Future<List<Article>> fetchTechCrunchNews() async {
    return _fetchUserArticles('techcrunch');
  }

  Future<List<Article>> fetchWSJNews() async {
    return _fetchUserArticles('wsj');
  }

  Future<List<Article>> _fetchUserArticles(String source) async {
    try {
      final url = _buildCustomUrl(source);
      await fetchUserArticles(url); // Use the correct source
      return _user?.articles ?? [];
    } catch (error) {
      print('Error fetching news: $error');
      return [];
    }
  }

  String _buildCustomUrl(String source) {
    final apiKey = '02f9077a4bd9478083f7a2445ec9fdfc'; // Replace with your News API key

    switch (source) {
      case 'apple':
        return 'https://newsapi.org/v2/everything?q=apple&from=2024-01-27&to=2024-01-27&sortBy=popularity&apiKey=$apiKey';
      case 'tesla':
        return 'https://newsapi.org/v2/top-headlines?country=us&category=business&apiKey=$apiKey';
      case 'business':
        return 'https://newsapi.org/v2/top-headlines?sources=techcrunch&apiKey=$apiKey';
      case 'techcrunch':
        return 'https://newsapi.org/v2/top-headlines?sources=techcrunch&apiKey=$apiKey';
      case 'wsj':
        return 'https://newsapi.org/v2/everything?domains=wsj.com&apiKey=$apiKey';
      default:
        return 'https://newsapi.org/v2/top-headlines?country=us&apiKey=$apiKey';
    }
  }


  Future<void> fetchMoreUserArticles(String source) async {
    try {
      final response = await http.get(
        Uri.parse(
          'https://newsapi.org/v2/top-headlines?sources=$source&apiKey=02f9077a4bd9478083f7a2445ec9fdfc&page=$_currentPage&pageSize=$_articlesPerPage',
        ),
      );
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        UserModel newUserData = UserModel.fromJson(data);

        if (_user == null) {
          _user = newUserData;
        } else {
          _user?.articles.addAll(newUserData.articles);
        }

        notifyListeners();
        _currentPage++;
      } else {
        throw Exception('Failed to load more user articles. Status code: ${response.statusCode}');
      }
    } catch (error) {
      throw Exception('Error: $error');
    }
  }

  Future<void> resetArticles() async {
    try {
      // Reset articles to the original list
      _user?.articles = List.from(_originalArticles!);
      notifyListeners();
    } catch (error) {
      throw Exception('Error: $error');
    }
  }

  void resetSearch() {
    if (_originalArticles != null) {
      _user?.articles = List.from(_originalArticles!);
      notifyListeners();
    }
  }

  void searchArticles(String query, {String sortOption = 'Latest'}) {
    if (_originalArticles != null) {
      List<Article> filteredArticles = _originalArticles!
          .where((article) => article.title.toLowerCase().contains(query.toLowerCase()))
          .toList();

      if (sortOption == 'Oldest') {
        filteredArticles.sort((a, b) => a.publishedAt.compareTo(b.publishedAt));
      }

      _user?.articles = List.from(filteredArticles);
      notifyListeners();
    }
  }

  void sortArticles(String sortOption) {
    if (_user?.articles != null) {
      if (sortOption == 'Oldest') {
        _user!.articles.sort((a, b) => a.publishedAt.compareTo(b.publishedAt));
      } else {
        _user!.articles.sort((a, b) => b.publishedAt.compareTo(a.publishedAt));
      }
      notifyListeners();
    }
  }
}

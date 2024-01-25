import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;


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

  Article({
    required this.source,
    this.author,
    required this.title,
    required this.description,
    required this.url,
    required this.urlToImage,
    required this.publishedAt,
    required this.content,
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
  final List<Article> articles;

  UserModel({
    required this.status,
    required this.totalResults,
    required this.articles,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
    status: json["status"] ?? "",
    totalResults: json["totalResults"] ?? 0,
    articles: List<Article>.from(
      (json["articles"] as List).map((x) => Article.fromJson(x)),
    ),
  );

  Map<String, dynamic> toJson() => {
    "status": status,
    "totalResults": totalResults,
    "articles": List<dynamic>.from(articles.map((x) => x.toJson())),
  };
}

class UserProvider with ChangeNotifier {
  UserModel? _user;

  UserModel? get user => _user;

  // Fetch user articles
  Future<void> fetchUserArticles() async {
    try {
      final response = await http.get(Uri.parse(
          'https://newsapi.org/v2/everything?q=tesla&from=2023-12-24&sortBy=publishedAt&apiKey=02f9077a4bd9478083f7a2445ec9fdfc'));
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        _user = UserModel.fromJson(data);
        notifyListeners();
      } else {
        throw Exception('Failed to load user data');
      }
    } catch (error) {
      throw Exception('Error: $error');
    }
  }

  // Edit user title
  void editUserTitle(int index, String newTitle) {
    if (_user != null && index >= 0 && index < _user!.articles.length) {
      _user!.articles[index].title = newTitle;
      notifyListeners();
    }
  }

  // Search articles based on query
  Future<void> searchArticles(String query, {String? sortOption}) async {
    try {
      final response = await http.get(Uri.parse(
          'https://newsapi.org/v2/everything?q=$query&sortBy=publishedAt&apiKey=02f9077a4bd9478083f7a2445ec9fdfc'));
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        _user = UserModel.fromJson(data);
        if (sortOption != null) {
          sortArticles(sortOption);
        }
        notifyListeners();
      } else {
        throw Exception('Failed to load search results');
      }
    } catch (error) {
      throw Exception('Error: $error');
    }
  }

  // Add this method to the UserProvider class
  Future<void> sortArticles(String sortOption) async {
    try {
      // Sort articles based on the selected option
      _user?.articles.sort((a, b) {
        if (sortOption == 'Latest') {
          return b.publishedAt.compareTo(a.publishedAt);
        } else if (sortOption == 'Oldest') {
          return a.publishedAt.compareTo(b.publishedAt);
        } else {
          return 0; // Default case
        }
      });
      notifyListeners();
    } catch (error) {
      throw Exception('Error: $error');
    }
  }
}

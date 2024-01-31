import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share/share.dart';
import 'news_provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late TextEditingController _searchController;
  String _sortOption = 'Latest';
  ScrollController _scrollController = ScrollController();
  bool _loading = false;

  @override
  void initState() {
    _searchController = TextEditingController();
    _scrollController.addListener(_scrollListener);
    super.initState();
  }

  void _fetchNews(UserProvider userProvider, String source) async {
    try {
      await userProvider.fetchUserArticles(source);
    } catch (error) {
      print('Error fetching news: $error');
    }
  }

  void _likeArticle(UserProvider userProvider, int articleIndex) {
    userProvider.user?.articles[articleIndex].liked = true;
    userProvider.notifyListeners();
  }

  void _scrollListener() {
    if (_scrollController.offset >= _scrollController.position.maxScrollExtent &&
        !_scrollController.position.outOfRange) {
      _loadMoreData(context);
    }
  }

  Future<void> _loadMoreData(BuildContext context) async {
    if (!_loading) {
      final userProvider = context.read<UserProvider>();

      try {
        setState(() {
          _loading = true;
        });

        await userProvider.fetchMoreUserArticles(userProvider.user?.source?.id ?? '');

      } catch (error) {
        _showErrorSnackbar(context, 'Error loading more data: $error');
      } finally {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  void _showErrorSnackbar(BuildContext context, String errorMessage) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(errorMessage),
        duration: Duration(seconds: 3),
      ),
    );
  }

  void _searchArticles(UserProvider userProvider, String query) {
    if (query.isNotEmpty) {
      userProvider.searchArticles(query, sortOption: _sortOption);
    } else {
      userProvider.resetSearch();
    }
  }

  void _onSortOptionChanged(String newSortOption, UserProvider userProvider) {
    setState(() {
      _sortOption = newSortOption;
      userProvider.sortArticles(_sortOption);
    });
  }

  void _shareArticle(BuildContext context, Article article) {
    final String text = '${article.title}\n${article.url}';
    Share.share(text);
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 5,
      child: Scaffold(
        appBar: AppBar(
          title: Text('World News'),
          backgroundColor: Colors.blue,
          elevation: 0,
          actions: [
            PopupMenuButton<String>(
              onSelected: (String value) {
                _onSortOptionChanged(value, context.read<UserProvider>());
              },
              itemBuilder: (BuildContext context) {
                return ['Latest', 'Oldest'].map((String option) {
                  return PopupMenuItem<String>(
                    value: option,
                    child: Text(option),
                  );
                }).toList();
              },
            ),
          ],
          bottom: TabBar(
            tabs: [
              _buildTab('Apple'),
              _buildTab('Tesla'),
              _buildTab('Business'),
              _buildTab('Tech'),
              _buildTab('Journal'),
            ],
            indicator: CustomTabIndicator(text: ''),
            indicatorSize: TabBarIndicatorSize.tab,
          ),
        ),
        body: TabBarView(
          children: [
            _buildNewsTab(context, 0, 'apple'),
            _buildNewsTab(context, 1, 'tesla'),
            _buildNewsTab(context, 2, 'business'),
            _buildNewsTab(context, 3, 'techcrunch'),
            _buildNewsTab(context, 4, 'wsj'),
          ],
        ),
      ),
    );
  }

  Widget _buildTab(String label) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.0),
      child: Tab(
        child: Align(
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(fontSize: 12.0, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }

  Widget _buildNewsTab(BuildContext context, int tabIndex, String source) {
    final userProvider = Provider.of<UserProvider>(context, listen: false);

    // if (userProvider.user == null ||
    //     userProvider.user?.articles.isEmpty == true ||
    //     userProvider.user?.source?.id != source) {
    //   _fetchNews(userProvider, source);
    // }
    // // Widget _buildNewsTab(BuildContext context, int tabIndex, String source) {
    //   final _userProvider = Provider.of<UserProvider>(context, listen: false);

    if (userProvider.user == null || userProvider.user?.source?.id != source) {
      _fetchNews(userProvider, source);
    }
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    labelText: 'Search News',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(Icons.search),
                      onPressed: () {
                        _searchArticles(userProvider, _searchController.text);
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: Center(
            child: Consumer<UserProvider>(
              builder: (context, userProvider, child) {
                if (userProvider.user == null) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                } else {
                  return ListView.builder(
                    controller: _scrollController,
                    itemCount: userProvider.user?.articles.length ?? 0,
                    itemBuilder: (context, index) {
                      if (index == userProvider.user!.articles.length - 1 && !_loading) {
                        return Column(
                          children: [
                            Card(
                              elevation: 3.0,
                              margin: const EdgeInsets.all(8.0),
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Column(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(8.0),
                                      child: Image.network(
                                        userProvider.user?.articles[index].urlToImage ?? '',
                                        height: 150.0,
                                        width: double.infinity,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                    const SizedBox(height: 8.0),
                                    Text(
                                      '${userProvider.user?.articles[index].title}',
                                      style: TextStyle(
                                        fontSize: 18.0,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 8.0),
                                    Text(
                                      '${userProvider.user?.articles[index].description}',
                                      style: TextStyle(fontSize: 16.0),
                                    ),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        IconButton(
                                          icon: Icon(
                                            userProvider.user?.articles[index].liked == true
                                                ? Icons.favorite
                                                : Icons.favorite_border,
                                            color: Colors.red,
                                          ),
                                          onPressed: () {
                                            _likeArticle(userProvider, index);
                                          },
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            _loading ? CircularProgressIndicator() : Container(),
                          ],
                        );
                      } else {
                        return Card(
                          elevation: 3.0,
                          margin: const EdgeInsets.all(8.0),
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Column(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8.0),
                                  child: Image.network(
                                    userProvider.user?.articles[index].urlToImage ?? '',
                                    height: 150.0,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                const SizedBox(height: 8.0),
                                Text(
                                  '${userProvider.user?.articles[index].title}',
                                  style: TextStyle(
                                    fontSize: 18.0,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8.0),
                                Text(
                                  '${userProvider.user?.articles[index].description}',
                                  style: TextStyle(fontSize: 16.0),
                                ),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    IconButton(
                                      icon: Icon(
                                        userProvider.user?.articles[index].liked == true
                                            ? Icons.favorite
                                            : Icons.favorite_border,
                                        color: Colors.red,
                                      ),
                                      onPressed: () {
                                        _likeArticle(userProvider, index);
                                      },
                                    ),
                                    IconButton(
                                      icon: Icon(Icons.share),
                                      onPressed: () {
                                        _shareArticle(context, userProvider.user!.articles[index]);
                                      },
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      }
                    },
                  );
                }
              },
            ),
          ),
        ),
      ],
    );
  }
}

class CustomTabIndicator extends Decoration {
  final String text;

  CustomTabIndicator({required this.text});

  @override
  _CustomPainter createBoxPainter([VoidCallback? onChanged]) {
    return _CustomPainter(this, onChanged);
  }
}

class _CustomPainter extends BoxPainter {
  final CustomTabIndicator decoration;

  _CustomPainter(this.decoration, VoidCallback? onChanged) : super(onChanged);

  @override
  void paint(Canvas canvas, Offset offset, ImageConfiguration configuration) {
    assert(configuration.size != null);
    final Rect rect = offset & configuration.size!;
    final Paint paint = Paint();
    paint.color = Colors.white;
    paint.style = PaintingStyle.fill;
    paint.strokeWidth = 4.0;

    double borderRadius = 20.0;
    double fontSize = 13.0;

    RRect rRect = RRect.fromRectAndRadius(rect, Radius.circular(borderRadius));
    canvas.drawRRect(rRect, paint);

    TextPainter textPainter = TextPainter(
      text: TextSpan(
        text: decoration.text,
        style: TextStyle(
          color: Colors.white,
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );

    textPainter.layout(minWidth: 0, maxWidth: configuration.size!.width);

    double textX = (rect.width - textPainter.width) / 3.0;
    double textY = (rect.height - textPainter.height) / 2.0;

    textPainter.paint(canvas, Offset(rect.left + textX, rect.top + textY));
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'user_provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late TextEditingController _searchController;
  String _sortOption = 'Latest'; // Default sorting option

  @override
  void initState() {
    _searchController = TextEditingController();
    Provider.of<UserProvider>(context, listen: false).fetchUserArticles();
    super.initState();
  }

  void _searchArticles(UserProvider userProvider, String query) {
    if (query.isNotEmpty) {
      userProvider.searchArticles(query, sortOption: _sortOption);
    }
  }

  void _onSortOptionChanged(String newSortOption, UserProvider userProvider) {
    setState(() {
      _sortOption = newSortOption;
      userProvider.sortArticles(_sortOption);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('News App'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (String value) {
              _onSortOptionChanged(value, Provider.of<UserProvider>(context, listen: false));
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
      ),
      body: Center(
        child: Consumer<UserProvider>(
          builder: (context, userProvider, child) {
            if (userProvider.user == null) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            } else {
              return SingleChildScrollView(
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          labelText: 'Search Articles',
                          suffixIcon: IconButton(
                            onPressed: () {
                              _searchArticles(
                                userProvider,
                                _searchController.text,
                              );
                            },
                            icon: Icon(Icons.search),
                          ),
                        ),
                      ),
                    ),
                    ...List.generate(
                      userProvider.user?.articles.length ?? 0,
                          (index) => Card(
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
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }
          },
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../providers/place_api_provider.dart';

class AddressSearch extends SearchDelegate<Suggestion?> {
  final sessionToken;

  AddressSearch(this.sessionToken)
      : super(
          searchFieldLabel: 'Enter your address',
          searchFieldStyle: const TextStyle(
            fontSize: 16,
          ),
        );

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        tooltip: 'Clear',
        icon: const Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      )
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      tooltip: 'Back',
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        close(context, null);
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return Container();
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return FutureBuilder<List<Suggestion>>(
      future: query.isEmpty
          ? Future.value(<Suggestion>[])
          : PlaceApiProvider(sessionToken).fetchSuggestions(
              query, 'en', ''), // Empty country for global results
      builder: (context, AsyncSnapshot<List<Suggestion>> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }
        if (snapshot.hasData) {
          final suggestions = snapshot.data!;
          print('AddressSearch: Received ${suggestions.length} suggestions for query: $query');
          for (var suggestion in suggestions) {
            print('AddressSearch: Suggestion - ${suggestion.description}');
          }
          if (suggestions.isEmpty) {
            return const Center(
              child: Text(
                'No results found',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
            );
          }
          return ListView.builder(
            itemCount: suggestions.length,
            itemBuilder: (context, index) {
              return ListTile(
                leading: const Icon(Icons.location_on),
                title: Text(
                  suggestions[index].description,
                  style: const TextStyle(
                    fontSize: 16,
                  ),
                ),
                onTap: () {
                  close(context, suggestions[index]);
                },
              );
            },
          );
        } else {
          print('AddressSearch: Error loading suggestions. Error: ${snapshot.error}');
          return const Center(
            child: Text(
              'Error loading suggestions',
              style: TextStyle(
                fontSize: 16,
                color: Colors.red,
              ),
            ),
          );
        }
      },
    );
  }
}
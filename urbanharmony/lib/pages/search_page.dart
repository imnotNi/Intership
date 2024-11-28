import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:urbanharmony/components/my_user_tile.dart';
import 'package:urbanharmony/services/database/database_provider.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final searchController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    //provider
    late final databaseProvider =
        Provider.of<DatabaseProvider>(context, listen: false);

    late final listeningProvider = Provider.of<DatabaseProvider>(context);

    final stt.SpeechToText _speech = stt.SpeechToText();
    bool _isListening = false;
    String _text = "Tap the mic icon to start recording".tr;

    void _startListening() async {
      if (await _speech.initialize()) {
        setState(() {
          _isListening = true;
          _text = "Recording...".tr;
        });

        _speech.listen(onResult: (result) {
          setState(() {
            _text = result.recognizedWords;
          });
        });
      }
    }

    void _stopListening() {
      setState(() {
        _isListening = false;
      });
      _speech.stop();
    }

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: searchController,
          decoration: InputDecoration(
            hintText: "Search Users..".tr,
            hintStyle: TextStyle(color: Theme.of(context).colorScheme.primary),
            border: InputBorder.none,
          ),
          onChanged: (value) {
            if (value.isNotEmpty) {
              databaseProvider.searchUsers(value);
            } else {
              databaseProvider.searchUsers("");
            }
          },
        ),
        // actions: [
        //   IconButton(
        //     onPressed: _isListening ? _stopListening : _startListening,
        //     icon: Icon(
        //       _isListening ? Icons.mic_none : Icons.mic_outlined,
        //       color: Colors.white,
        //       size: 25,
        //     ),
        //   ),
        // ],
      ),
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: listeningProvider.searchResult.isEmpty
          ?  Center(
              child: Text("No users found..".tr),
            )
          : ListView.builder(
              itemCount: listeningProvider.searchResult.length,
              itemBuilder: (context, index) {
                final user = listeningProvider.searchResult[index];
                return MyUserTile(user: user);
              },
            ),
    );
  }
}

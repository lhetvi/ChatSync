import 'dart:convert';
import 'dart:developer';

import 'package:chat_sync/screens/profile_screen.dart';
import 'package:chat_sync/widgets/chat_user_card.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../api/apis.dart';
import '../main.dart';
import '../models/chat_user.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // for storing all users
  List<ChatUser> list = [];

  // for storing searched items
  final List<ChatUser> _searchList = [];

  // for storing search status
  bool _isSearching = false;


  @override
  void initState() {
    super.initState();
    APIs.getSelfInfo();

    SystemChannels.lifecycle.setMessageHandler((message){
      log('Message: $message');

      if(APIs.auth.currentUser!=null){
        if(message.toString().contains('resume'))APIs.updateActiveStatus(true);
        if(message.toString().contains('pause'))APIs.updateActiveStatus(false);
      }


      return Future.value(message);
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: WillPopScope( // "WillPopScope" it work for action after button click
        // if search on and back button is pressed then close search
        // or else simple close current screen on back button click
        onWillPop: () {
          if (_isSearching) {
            setState(() {
              _isSearching = !_isSearching;
            });
            return Future.value(false);
          }
          else {
            return Future.value(true);
          }
        },
        child: Scaffold(
          appBar: AppBar(
            title: _isSearching ? TextField(
              decoration: const InputDecoration(
                  border: InputBorder.none,
                  hintText: 'Name, Email, ...'
              ),
              autofocus: true,
              style: const TextStyle(
                  fontSize: 17,
                  letterSpacing: 0.5
              ),
              // when search text change update the searchList
              onChanged: (val) {
                // search logic
                _searchList.clear();

                for (var i in list) {
                  if (i.name.toLowerCase().contains(val.toLowerCase()) ||
                      i.email.toLowerCase().contains(val.toLowerCase())) {
                    _searchList.add(i);
                  }
                  setState(() {
                    _searchList;
                  });
                }
              },
            ) : Text('ChatSync', style: TextStyle(color: Colors.lime.shade900),),
            leading: Icon(CupertinoIcons.home, color: Colors.lime.shade900,),
            actions: [
              // search user button
              IconButton(onPressed: () {
                setState(() {
                  _isSearching =
                  !_isSearching; // for change icon based on search-state
                });
              },
                  icon: Icon(
                    _isSearching ? CupertinoIcons.clear_circled_solid : Icons
                        .search,color: Colors.lime.shade900,)),

              // more feature button
              IconButton(onPressed: () {
                // navigate on Profile page
                Navigator.push(context, MaterialPageRoute(
                    builder: (_) => ProfileScreen(user: APIs.me)));
              }, icon: Icon(Icons.more_vert, color: Colors.lime.shade900,)),
            ],
          ),
          floatingActionButton: Padding(
            padding: const EdgeInsets.only(bottom: 10.0),
            child: FloatingActionButton(
                onPressed: () async {
                  await APIs.auth.signOut();
                  await GoogleSignIn().signOut();

                },
                child: Icon(Icons.add_comment_rounded)),
          ),

          body: StreamBuilder(
            // below line build connection with firebase database
              stream: APIs.getAllUser(),
              builder: (context, snapshot) {
                switch (snapshot.connectionState) {
                //if data is loading
                  case ConnectionState.waiting:
                  case ConnectionState.none:
                    return const Center(child: CircularProgressIndicator());

                //if some or all data is loaded then show it\
                  case ConnectionState.active:
                  case ConnectionState.done:
                  // fetch data from database

                  // if(snapshot.hasData) {
                    final data = snapshot.data?.docs;
                    // for(var i in data!) {
                    //   // log('Data: ${i.data()}');
                    //   log('Data: ${jsonEncode(i.data())}');
                    //   list.add(i.data()['name']);
                    // }
                    list = data?.map((e) => ChatUser.fromJson(e.data()))
                        .toList() ?? [];
                    // }
                    if (list.isNotEmpty) {
                      return ListView.builder(
                          itemCount: _isSearching ? _searchList.length : list
                              .length, //no. of carts
                          padding: EdgeInsets.only(top: mq.height * .01),
                          physics: const BouncingScrollPhysics(),
                          itemBuilder: (context, index) {
                            return ChatUserCard(user: _isSearching
                                ? _searchList[index]
                                : list[index]);
                            // return Text('Name: ${list[index]}');
                          });
                    }
                    else {
                      return const Center (
                        child: Text('No Connections Found!', style: TextStyle(
                            fontSize: 20)),
                      );
                    }
                }
              }
          ),
        ),
      ),
    );
  }
}
import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:chat_sync/helper/my_date_util.dart';
import 'package:chat_sync/models/chat_user.dart';
import 'package:chat_sync/screens/view_profile_screen.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../api/apis.dart';
import '../main.dart';
import '../models/message.dart';
import '../widgets/massage_card.dart';

class ChatScreen extends StatefulWidget {
  final ChatUser user;

  const ChatScreen({super.key, required this.user});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {

  List<Message> list = [];

  final _textController= TextEditingController();

  bool _showEmoji = false, _isUploading=false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: ()=>FocusScope.of(context).unfocus(),
      child: SafeArea(
        child: WillPopScope(
          onWillPop: () {
            if (_showEmoji) {
              setState(() {
                _showEmoji = !_showEmoji;
              });
              return Future.value(false);
            }
            else {
              return Future.value(true);
            }
          },
          child: Scaffold(
            appBar: AppBar(
              automaticallyImplyLeading: false,
              flexibleSpace: _appBar(),
            ),

            backgroundColor: const Color.fromARGB(255, 234, 248, 255),

            body:Column(
              children: [
                Expanded(
                  child: StreamBuilder(
                    // below line build connection with firebase database
                    stream: APIs.getAllMessages(widget.user),
                    builder: (context, snapshot) {
                      switch (snapshot.connectionState) {
                      // If data is loading
                        case ConnectionState.waiting:
                        case ConnectionState.none:
                          return const SizedBox();

                      // If some or all data is loaded then show it
                        case ConnectionState.active:
                        case ConnectionState.done:
                          final data = snapshot.data?.docs;
                          list = data?.map((e) => Message.fromJson(e.data())).toList() ?? [];

                          // Fetch data from the database
                          if (snapshot.hasData) {
                            final data = snapshot.data?.docs;

                            log('Data: ${jsonEncode(data![0].data())}');

                            if (list.isNotEmpty) {
                              return ListView.builder(
                                reverse: true,
                                itemCount: list.length, // Number of items
                                padding: EdgeInsets.only(top: mq.height * .01),
                                physics: const BouncingScrollPhysics(),
                                itemBuilder: (context, index) {
                                  return MessageCard(message: list[index]);
                                },
                              );
                            } else {
                              return const Center(
                                child: Text('Say Hi! 👋', style: TextStyle(fontSize: 20)),
                              );
                            }
                          }
                          // Handle the case where snapshot.hasData is false
                          return const SizedBox();

                      // Handle any unexpected ConnectionState values
                        default:
                          return const SizedBox();
                      }
                    },
                  ),
                ),

                //progress indicator for showing uploading
                if(_isUploading)
                  const Align(
                    alignment: Alignment.centerRight,
                    child:Padding(padding:EdgeInsets.symmetric(vertical: 8, horizontal: 20), child: CircularProgressIndicator(strokeWidth: 2))
                  ),

                //chat input field
                _chatInput(),

               if(_showEmoji)
                SizedBox(
                  height:mq.height * .35,
                  child: EmojiPicker(
                  textEditingController: _textController,
                  config: const Config(
                    bgColor: Color.fromARGB(255, 234, 248, 255),
                    columns: 8,
                    emojiSizeMax: 32* (1.0),
                  ),
                ),)
             ],
           ),
          ),
        ),
      ),
    );
  }

  //app bar widget
  Widget _appBar() {
    return InkWell(
      onTap: () {
        Navigator.push(
          context, MaterialPageRoute(builder: (_)=> ViewProfileScreen(user: widget.user)));
      },
      child: StreamBuilder(
        stream: APIs.getUserInfo(widget.user),
        builder: (context, snapshot) {
          final data = snapshot.data?.docs;
          final list = data?.map((e) => ChatUser.fromJson(e.data()))
              .toList() ?? [];


          return Row(
            children: [
              // back button
              IconButton(
                onPressed: () {
                  FocusScope.of(context).unfocus();
                  setState(() => _showEmoji = !_showEmoji);
                },
                icon: const Icon(
                  Icons.arrow_back,
                  color: Colors.black87,
                ),
              ),
              ClipRRect(
                borderRadius: BorderRadius.circular(mq.height * 0.3),
                child: CachedNetworkImage(
                  width: mq.height * 0.05,
                  height: mq.height * 0.05,
                  imageUrl: list.isNotEmpty?list[0].image: widget.user.image,
                  // placeholder: (context, url) => CircularProgressIndicator(),
                  errorWidget: (context, url, error) =>
                  const CircleAvatar(child: Icon(CupertinoIcons.person)),
                ),
              ),
              // for adding some space
              const SizedBox(width: 10),
              // user name & last seen time
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // user name
                  Text(
                    list.isNotEmpty? list[0].name: widget.user.name,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.black,
                      fontWeight: FontWeight.w500,
                    ),
                  ),

                  // for adding some space
                  const SizedBox(height: 2),

                  // for user's last seen time
                  Text(
                    list.isNotEmpty?list[0].isOnline?'Online':MyDateUtil.getLastActiveTime(context: context, lastActive: list[0].lastActive)
                        :MyDateUtil.getLastActiveTime(context: context, lastActive: widget.user.lastActive),
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.black54,
                    ),
                  ),
                ],
              )
            ],
          );
        },
      ),
    );
  }


  Widget _chatInput() {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: mq.height * .01, horizontal: mq.width * .025),
      child: Row(
        children: [
          // input field & buttons
          Expanded(
            child: Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              child: Row(
                children: [
                  // emoji button
                  IconButton(
                      onPressed: () {
                        setState( ()=> _showEmoji=!_showEmoji);
                      },
                      icon: Icon(
                        Icons.emoji_emotions,
                        color: Colors.grey.shade800,
                        size: 26,
                      )
                  ),

                  Expanded(
                      child: TextField(
                        controller: _textController,
                        keyboardType: TextInputType.multiline,
                        maxLines: null,
                        onTap: (){
                          if(_showEmoji)setState( ()=> _showEmoji=!_showEmoji);
                        },
                        decoration: const InputDecoration(
                          hintText: 'Type something...',
                          hintStyle: TextStyle(
                            color: Colors.black54,
                          ),
                          border: InputBorder.none,
                        ),
                      )
                  ),

                  // pick image from gallery button
                  IconButton(
                      onPressed: () async {
                        final ImagePicker picker = ImagePicker();
                        // Picking multiple images
                        final List<XFile> images = await picker.pickMultiImage( imageQuality: 70);

                        //uploading and sending image one by one
                        for(var i in images) {
                          log('Image Path: ${i.path}');
                          setState( ()=> _isUploading=true);
                          await APIs.sendChatImage(widget.user, File(i.path));
                          setState( ()=> _isUploading=false);
                        }
                      },
                      icon: Icon(
                        Icons.image,
                        color: Colors.grey.shade800,
                        size: 26,
                      )
                  ),

                  // take image from camera button
                  IconButton(
                      onPressed: () async {
                        final ImagePicker picker = ImagePicker();

                        // Pick an image
                        final XFile? image = await picker.pickImage(
                            source: ImageSource.camera, imageQuality: 70);
                        if (image != null) {
                          log('Image Path: ${image.path}');
                          setState(()=>_isUploading=true);

                          await APIs.sendChatImage(widget.user, File(image.path));
                          setState(()=>_isUploading=false);

                        }
                      },
                      icon: Icon(
                        Icons.camera_alt_rounded,
                        color: Colors.grey.shade800, size: 26)),

                  //adding some space
                  SizedBox(width: mq.width * .02,),
                ],
              ),
            ),
          ),
          
          // send message button
          MaterialButton(
            onPressed: (){
              if(_textController.text.isNotEmpty){
                APIs.sendMessage(widget.user, _textController.text, Type.text);
                _textController.text='';
              }
            },

            minWidth: 0,
            padding: const EdgeInsets.only(top: 10, bottom: 10, right: 5, left: 10),
            shape: const CircleBorder(),
            color: Colors.lime.shade900,
            child: const Icon(
              Icons.send,
              color: Colors.white,
              size: 28,
            ),
          )
        ],
      ),
    );
  }
}

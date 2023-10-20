import 'package:cached_network_image/cached_network_image.dart';
import 'package:chat_sync/helper/my_date_util.dart';
import 'package:chat_sync/models/message.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../api/apis.dart';
import '../main.dart';
import '../models/chat_user.dart';
import '../screens/chat_screen.dart';

// card to represent a single user in home screen
class ChatUserCard extends StatefulWidget {
  final ChatUser user;

  const ChatUserCard({super.key, required this.user});

  @override
  State<ChatUserCard> createState() => _ChatUserCardState();
}

class _ChatUserCardState extends State<ChatUserCard> {

  Message?_message;
  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: mq.width * .01, vertical: 4),
      elevation: 0.8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () {
          Navigator.push(
            // for navigating to chat screen
            context, MaterialPageRoute(builder: (_) => ChatScreen(user: widget.user)));
        },
        child: StreamBuilder(
          stream:APIs.getLastMessage(widget.user),
          builder:(context, snapshot){
            final data = snapshot.data?.docs;
            final list = data?.map((e) => Message.fromJson(e.data()))
                .toList() ?? [];
            if(list.isNotEmpty) _message=list[0];

            return ListTile(
            //user profile picture
              leading: ClipRRect(
            //**************************
            borderRadius: BorderRadius.circular(mq.height * .3),
            child: CachedNetworkImage(
            width: mq.height * .055,
            height: mq.height * .055,
            imageUrl: widget.user.image,
            // placeholder: (context, url) => CircularProgressIndicator(),
            errorWidget: (context, url, error) =>
            const CircleAvatar(child: Icon(CupertinoIcons.person)),
            ),
            ),

            // user's name
            title: Text(widget.user.name),

            // last massage of user
            subtitle: Text(_message!=null? _message!.type==Type.image?'image':_message!.msg:widget.user.about, maxLines: 1),

            //last message time
            trailing: _message== null
                ? null
                :_message!.read.isEmpty && _message!.fromId!=APIs.user.uid
                   ?Container(
                      width: 15,
                      height: 15,
                      decoration: BoxDecoration(
                          color: Colors.greenAccent.shade400,
                          borderRadius: BorderRadius.circular(10),),
                    )
                   :Text(
                      MyDateUtil.getLastMessageTime(context: context, time: _message!.sent),
                      style: const TextStyle(color: Colors.black54 ),
                      ),
            );
      },)),
    );
  }
}

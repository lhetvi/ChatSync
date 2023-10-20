
// ignore_for_file: use_build_context_synchronously

import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:chat_sync/widgets/chat_user_card.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:image_picker/image_picker.dart';
import '../api/apis.dart';
import '../helper/dialogs.dart';
import '../helper/my_date_util.dart';
import '../main.dart';
import '../models/chat_user.dart';


class ViewProfileScreen extends StatefulWidget {
  // for pass user's information
  final ChatUser user;

  const ViewProfileScreen({super.key, required this.user});

  @override
  State<ViewProfileScreen> createState() => _ViewProfileScreenState();
}

class _ViewProfileScreenState extends State<ViewProfileScreen> {

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      // for hiding keyboard
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.user.name, style: TextStyle(color: Colors.lime.shade900)),
        ),
        floatingActionButton: //user about
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Joined On: ', style: TextStyle(color:Colors.black87, fontWeight: FontWeight.w500, fontSize: 16)),

            Text(MyDateUtil.getLastMessageTime(context: context, time:widget.user.createdAt, showYear: true),
                style: const TextStyle(color: Colors.black54, fontSize: 16)),
          ],
        ),

        body: Padding(
          padding: EdgeInsets.symmetric(horizontal: mq.width * .05),
          child: SingleChildScrollView(
            child: Column(
              children: [
                // for consider full width & adding some space
                SizedBox(
                  width: mq.width,
                  height: mq.height * .04,
                ),

                // user profile
                ClipRRect(
                  borderRadius:
                  BorderRadius.circular(mq.height * .1),
                  child: CachedNetworkImage(
                    width: mq.height * .2,
                    height: mq.height * .2,
                    fit: BoxFit.cover,
                    imageUrl: widget.user.image,
                    errorWidget: (context, url, error) =>
                    const CircleAvatar(
                        child: Icon(CupertinoIcons.person)),
                  ),
                ),
                // for consider full width & adding some space
                SizedBox(
                  height: mq.height * .03,
                ),

                //user email label
                Text(widget.user.email,
                style: const TextStyle(color: Colors.black87, fontSize: 16)),

                SizedBox(
                  height: mq.height * .02),

                //user about
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('About: ', style: TextStyle(color:Colors.black87, fontWeight: FontWeight.w500, fontSize: 16)),
                    Text(widget.user.about,
                        style: const TextStyle(color: Colors.black54, fontSize: 16)),
                  ],
                ),

              ],
            ),
          ),
        )
      ),
    );
  }

//   @override
//   void initState() {
//     super.initState();
//
//     // Assign the value to imagePath here when you have access to _imageFile
//     if (_imageFile != null) {
//       imagePath = _imageFile!.path;
//     }
//   }
//
//   // bottom sheet for picking a profile picture for user
//   void _showBottomSheet() {
//     showModalBottomSheet(
//         context: context,
//         shape: const RoundedRectangleBorder(borderRadius: BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20))),
//         builder: (_) {
//           return ListView(
//             shrinkWrap: true,
//             padding: EdgeInsets.only(top: mq.height * .03, bottom: mq.height * .06),
//             children: [
//               const Text('Pick Profile Picture',
//                 textAlign: TextAlign.center,
//                 style: TextStyle(
//                     fontSize: 18,
//                     fontWeight: FontWeight.w500
//                 ),),
//
//               SizedBox(height: mq.height * .02),
//
//               Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//                 children: [
//                   // take picture from camera button
//                   ElevatedButton(
//                       style: ElevatedButton.styleFrom(
//                           backgroundColor: Colors.white,
//                           shape: const CircleBorder(),
//                           fixedSize: Size(mq.width * .3, mq.height *.15)
//                       ),
//                       onPressed: () async{
//                         // takePhoto(ImageSource.camera);
//                         final pickerFile1 = await _picker.pickImage(source: ImageSource.camera);
//                         setState(() {
//                           _imageFile = pickerFile1 != null ? File(pickerFile1.path) : null;
//                         });
//
//
//
//                         APIs.UpdateProfilePicture(_imageFile!);
//                       },
//                       child: Image.asset(
//                         'images/camera.png',
//                       )),
//                   // take picture from gallery button
//                   ElevatedButton(
//                       style: ElevatedButton.styleFrom(
//                           backgroundColor: Colors.white,
//                           shape: const CircleBorder(),
//                           fixedSize: Size(mq.width * .3, mq.height *.15)
//                       ),
//                       onPressed: () async{
//                         // bringPhoto(ImageSource.gallery);
//                         // final ImagePicker picker = ImagePicker();
//                         // Pick an image.
//                         // final XFile? image = await picker.pickImage(source: ImageSource.gallery);
//                         // if(image != null) {
//                         //   log('Image Path: ${imagePath} -- MimeType: ${imagePath.mimeType}');
//                           // setState(() {
//                           //   _imageFile = pickerFile;
//                           // });
//                         //   // for hiding bottom sheet
//
//
//
//                         // APIs.UpdateProfilePicture(File(imagePath!));
//
//                         final pickerFile1 = await _picker.pickImage(source: ImageSource.gallery);
//                         setState(() {
//                           _imageFile = pickerFile1 != null ? File(pickerFile1.path) : null;
//                         });
//                         APIs.UpdateProfilePicture(_imageFile!);
//
//                         Navigator.pop(context);
//                         // }
//
//                       },
//                       child: Image.asset(
//                         'images/gallery.png',
//                       ))
//                 ],)
//             ],
//           );
//         });
//   }
//   // void takePhoto([ImageSource? source]) async {
//     // final pickerFile1 = await _picker.pickImage(source: ImageSource.camera);
//     // setState(() {
//     //   _imageFile = pickerFile1 != null ? File(pickerFile1.path) : null;
//     // });
//     //
//     //
//     //
//     // APIs.UpdateProfilePicture(_imageFile!);
//   // }
//   // void bringPhoto([ImageSource? source]) async {
//     // final pickerFile1 = await _picker.pickImage(source: ImageSource.gallery);
//     // setState(() {
//     //   _imageFile = pickerFile1 != null ? File(pickerFile1.path) : null;
//     // });
//     // APIs.UpdateProfilePicture(_imageFile!);
//   // }
//
// }


  // bottom sheet for picking a profile picture for user

}
//Absolute Path


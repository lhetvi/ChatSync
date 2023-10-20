
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
import '../main.dart';
import '../models/chat_user.dart';
import 'auth/login_screen.dart';

class ProfileScreen extends StatefulWidget {
  // for pass user's information
  final ChatUser user;

  const ProfileScreen({super.key, required this.user});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {

  // it is global key, which store form-state,
  final _formKey = GlobalKey<FormState>();

  // File? _imageFile;
  // String? imagePath;

  // final ImagePicker _picker = ImagePicker();
  // var source;

  String? _image;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      // for hiding keyboard
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        appBar: AppBar(
          title: Text('Profile', style: TextStyle(color: Colors.lime.shade900,),),
        ),
        floatingActionButton: Padding(
          padding: const EdgeInsets.only(bottom: 10.0),
          child: FloatingActionButton.extended(
              backgroundColor: Colors.red,
              onPressed: () async {
                // for showing progress dialog
                Dialogs.showProgressbar(context);

                await APIs.updateActiveStatus(false);

                //sign out from app
                await APIs.auth.signOut().then((value) async{
                  await GoogleSignIn().signOut().then((value) {
                    // for hiding progress dialogs
                    Navigator.pop(context);


                    APIs.auth= FirebaseAuth.instance;

                    //replacing home screen with login screen
                    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
                  });
                });

              },
              icon: const Icon(Icons.logout), label: Text('Logout')),
        ),

        body: Form   (
          key: _formKey,
          child: Padding(
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
                  Stack(
                    children: [
                      //profile picture
                      _image != null
                          ?

                      //local image
                      ClipRRect(
                          borderRadius:
                          BorderRadius.circular(mq.height * .1),
                          child: Image.file(File(_image!),
                              width: mq.height * .2,
                              height: mq.height * .2,
                              fit: BoxFit.cover))
                          :

                      //image from server
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

                      //edit image button
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: MaterialButton(
                          elevation: 1,
                          onPressed: () {
                            _showBottomSheet();
                          },
                          shape: const CircleBorder(),
                          color: Colors.white,
                          child: Icon(Icons.edit, color: Colors.lime.shade900),
                        ),
                      )
                    ],
                  ),
                  // for consider full width & adding some space
                  SizedBox(
                    height: mq.height * .03,
                  ),
                  Text(widget.user.email,
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    fontSize: 16
                  ),),

                  SizedBox(
                    height: mq.height * .03,
                  ),

                  TextFormField(
                    initialValue: widget.user.name,
                    //write below line _formkey
                    onSaved: (val) => APIs.me.name = val ?? '',
                    validator: (val) => val != null && val.isNotEmpty ? null : "Required name field",
                    decoration: InputDecoration(
                      prefixIcon: Icon(Icons.person, color: Colors.lime.shade900,),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      hintText: 'eg. Priyank Jadav',
                      label: const Text('Name'),
                    ),
                  ),

                  SizedBox(
                    height: mq.height * .03,
                  ),

                  TextFormField(
                    initialValue: widget.user.about,
                    onSaved: (val) => APIs.me.about = val ?? '',
                    validator: (val) => val != null && val.isNotEmpty ? null : "Required about field",
                    decoration: InputDecoration(
                      prefixIcon: Icon(Icons.info_outline, color: Colors.lime.shade900),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      hintText: 'eg. Happy feeling',
                      label: const Text('About'),
                    ),
                  ),
                  SizedBox(
                    height: mq.height * .02,
                  ),

                  ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        shape: const StadiumBorder(),
                        minimumSize: Size(mq.width * .5, mq.height * .06),
                        primary: Colors.lime.shade900,
                      ),

                      onPressed: () {
                        if (_formKey.currentState!.validate()) {
                          _formKey.currentState!.save();
                          APIs.updateUserInfo().then((value) {
                            Dialogs.showSnackbar(context, 'Profile Updated Successfully');
                          });
                        }
                      },

                      icon: const Icon(Icons.login, size: 28,),
                      label: const Text('UPDATE', style: TextStyle(fontSize: 12 ),)),
                ],
              ),
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
  void _showBottomSheet() {
    showModalBottomSheet(
        context: context,
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20), topRight: Radius.circular(20))),
        builder: (_) {
          return ListView(
            shrinkWrap: true,
            padding:
            EdgeInsets.only(top: mq.height * .03, bottom: mq.height * .05),
            children: [
              //pick profile picture label
              const Text('Pick Profile Picture',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500)),

              //for adding some space
              SizedBox(height: mq.height * .02),

              //buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  //pick from gallery button
                  ElevatedButton(
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey.shade800,
                          shape: const CircleBorder(),
                          fixedSize: Size(mq.width * .3, mq.height * .15)),
                      onPressed: () async {
                        final ImagePicker picker = ImagePicker();

                        // Pick an image
                        final XFile? image = await picker.pickImage(
                            source: ImageSource.gallery, imageQuality: 80);
                        if (image != null) {
                          log('Image Path: ${image.path}');
                          setState(() {
                            _image = image.path;
                          });

                          APIs.UpdateProfilePicture(File(_image!));
                          // for hiding bottom sheet
                          Navigator.pop(context);
                        }
                      },
                      child: Image.asset('images/gallery.png')),

                  //take picture from camera button
                  ElevatedButton(
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          shape: const CircleBorder(),
                          fixedSize: Size(mq.width * .3, mq.height * .15)),
                      onPressed: () async {
                        final ImagePicker picker = ImagePicker();

                        // Pick an image
                        final XFile? image = await picker.pickImage(
                            source: ImageSource.camera, imageQuality: 80);
                        if (image != null) {
                          log('Image Path: ${image.path}');
                          setState(() {
                            _image = image.path;
                          });

                          APIs.UpdateProfilePicture(File(_image!));
                          // for hiding bottom sheet
                          Navigator.pop(context);
                        }
                      },
                      child: Image.asset('images/camera.png')),
                ],
              )
            ],
          );
        });
  }


}
//Absolute Path


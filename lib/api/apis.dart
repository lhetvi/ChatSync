import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:chat_sync/models/chat_user.dart';
import 'package:chat_sync/models/message.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:http/http.dart';

class APIs {
  // for authentication
  static FirebaseAuth auth = FirebaseAuth.instance;

  // for accessing cloud firestore database
  static FirebaseFirestore firestore = FirebaseFirestore.instance;

  // for accessing firebase storage
  static FirebaseStorage storage  = FirebaseStorage.instance;

  //for storing self info
  static late ChatUser me;

  //to return current user
  //static User get user=>auth.currentUser!;

  //for accessing firebase messaging
  static FirebaseMessaging fMessaging = FirebaseMessaging.instance;

  //for getting firebase messaging token
  static Future<void>getFirebaseMessagingToken()async{
    await fMessaging.requestPermission();

    await fMessaging.getToken().then((t){
      if(t!=null){
        me.pushToken=t;
        log('Push Token:$t');
      }
    });
  }
  //for sending push notifications
  static Future<void>sendPushNotification(ChatUser chatUser, String msg)async{
   try{
     final body=
     {
       "to":chatUser.pushToken,
       "notification":{
         "title":chatUser.name,
         "body":msg
       }
     };
     var res = await post(Uri.parse('https://fcm.googleapis.com/fcm/send'),
         headers: {
           HttpHeaders.contentTypeHeader:'application/json',
           HttpHeaders.authorizationHeader:'key=AAAADFb2GAA:APA91bF5m93QZZP8OSCQRBE_HUqxmjstnt8EgbEyXi1SZ8_Hh1QiseM1DDlE2sxPIgeJKlL3tuh2GvjBu4GDW88W55s9HN6wI61YoxlUaiHVsi6LDQMo3EvpRCnynbDeqi38AuMmt9Fu'

         },
         body: jsonEncode(body));
     log('Response status: ${res.statusCode}');
     log('Response body: ${res.body}');
   }
   catch(e){
     log('\n sendPushNotificationE: $e');
   }
  }

  // for checking if user exists or not?
  static Future<bool> userExists() async {
    return (await firestore.collection('users').doc(user.uid).get()).exists;
    //-> use firestore for access collection from DB
    // auth.currentUser!.uid = this fetch UID from firebase DB
  }

  // for getting  current user information
  static Future<void> getSelfInfo() async {
    await firestore.collection('users').doc(user.uid).get().then((user) async{

      if(user.exists) {
        me = ChatUser.fromJson(user.data()!);
        await getFirebaseMessagingToken();
        log('My Data: ${user.data()}');
      }
      else {
        await createUser().then((value) => getSelfInfo());
      }
    });
  }

  // for reduce repeatedly use of auth.CurrentUser --> we make getter method
  static get user => auth.currentUser!; // "!" if it "NULL" then it send error


  // for creating a new user
  static Future<void> createUser() async {
    // "time" use for User's "createdAt"
    // In this "millisecondsSinceEpoch" give special time: 1) which always unique
    // "millisecondsSinceEpoch" it return "int" value, which is big value --> so we convert it into "string" so it can easily store into firebase DB
    final time = DateTime.now().millisecondsSinceEpoch.toString();

    final chatUser = ChatUser(
        id: user.uid,
        name: user.displayName.toString(),
        email: user.email.toString(),
        about: "Hey, I'm using ChaySync",
        image : user.photoURL.toString(),
        createdAt: time,
        isOnline: false,
        lastActive: time,
        pushToken: ""
    );

    // Use to check user

    // return (await firestore
    //     .collection('users')
    //     .doc(auth.currentUser!.uid)
    //     .get())
    //     .exists;

    // Now, we need to push this data into firebase and create one "doc"
    return await firestore
        .collection('users')
        .doc(user.uid)
        .set(chatUser.toJson());
  }

  // foe getting all users from firebase
  static Stream<QuerySnapshot<Map<String, dynamic>>> getAllUser() {
    return (firestore
        .collection('users')
        .where('id', isNotEqualTo: user.uid)
        .snapshots());
  }

  // for update user information
  static Future<void> updateUserInfo() async {
    await firestore
        .collection('users')
        .doc(user.uid)
        .update({'name': me.name, 'about': me.about});
  }

  // for Profile picture information
  static Future<void> UpdateProfilePicture(File file) async {
    // getting image file extension
    final ext = file.path.split('.').last;
    log('Extention: $ext');

    //storage file extension with file
    final ref = storage.ref().child('profile_picture/${user.uid}.$ext');

    // uploading image
    await ref.putFile (file, SettableMetadata(contentType: 'image/$ext')).then((p0) {
      log('Data Transferred: ${p0.bytesTransferred / 1000} kb');
    });

    //updating image in firestore database
    me.image = await ref.getDownloadURL();
    await firestore
        .collection('users')
        .doc(user.uid)
        .update({'image': me.image});
  }

  //for getting specific user info
  static Stream<QuerySnapshot<Map<String, dynamic>>> getUserInfo(ChatUser chatUser){
    return (firestore
        .collection('users')
        .where('id', isEqualTo: chatUser.id)
        .snapshots());
  }

  //update online or last active status of user
  static Future<void>updateActiveStatus(bool isOnline)async{
    firestore.collection('users').doc(user.uid).update({
      'is_online': isOnline,
      'last_active':DateTime.now().millisecondsSinceEpoch.toString(),
      'push_token': me.pushToken,
    });
  }

  /**************************Chat Screen Related APIs****************************/

  //useful for getting conversation id
  static String getConversationID(String id)=>user.uid.hashCode<= id.hashCode? '${user.uid}_$id': '${id}_${user.uid}';

  // foe getting all messages of a specific conversation from firebase DB
  static Stream<QuerySnapshot<Map<String, dynamic>>> getAllMessages(ChatUser user) {
    return (firestore
        .collection('chats/${getConversationID(user.id)}/messages/')
        .orderBy('sent', descending: true)
        .snapshots());
  }

  //for sending message
  static Future<void>sendMessage(ChatUser chatUser, String msg, Type type)async {
    final time= DateTime.now().millisecondsSinceEpoch.toString();

    final Message message= Message(toId: chatUser.id, msg: msg, read: '', type: type, fromId: user.uid, sent: time);

    final ref= firestore.collection('chats/${getConversationID(chatUser.id)}/messages/');
    await ref.doc(time).set(message.toJson()).then((value) => sendPushNotification(chatUser, type==Type.text?msg: 'image'));
  }

  //update read status of message
  static Future<void>updateMessageReadStatus(Message message)async {
    firestore.collection('chats/${getConversationID(message.fromId)}/messages/').doc(message.sent).update({'read':DateTime.now().millisecondsSinceEpoch.toString()});
  }

  //get only last message of a specific chat
  static Stream<QuerySnapshot<Map<String, dynamic>>> getLastMessage(ChatUser user){
    return firestore
        .collection('chats/${getConversationID(user.id)}/messages/')
        .orderBy('sent', descending: true)
        .limit(1)
        .snapshots();
  }

  static Future<void>sendChatImage(ChatUser chatUser, File file) async {
    final ext = file.path.split('.').last;

    //storage file extension with file
    final ref = storage.ref().child('images/${getConversationID(chatUser.id)}/${DateTime.now().millisecondsSinceEpoch}.$ext');

    // uploading image
    await ref.putFile (file, SettableMetadata(contentType: 'image/$ext')).then((p0) {
      log('Data Transferred: ${p0.bytesTransferred / 1000} kb');
    });

    //updating image in firestore database
    final imageUrl = await ref.getDownloadURL();
    await sendMessage(chatUser, imageUrl, Type.image);
  }

  //delete msg
  static Future<void>deleteMessage(Message message) async{
    await firestore.collection('chats/${getConversationID(message.toId)}/messages/')
        .doc(message.sent)
        .delete();

    if(message.type==Type.image){
      await storage.refFromURL(message.msg).delete();
    }
  }

}
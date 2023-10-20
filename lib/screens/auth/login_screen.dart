import 'dart:developer';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../api/apis.dart';
import '../../helper/dialogs.dart';
import '../home_screen.dart';
import 'package:flutter/material.dart';

import '../../main.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 1000), () {});
  }


  _handleGoogleBtnClick() {
    Dialogs.showProgressbar(context);
    _signInWithGoogle().then((user) async{ // check that user's credential provide or not
      Navigator.pop(context);
      if(user != null) {
        log('\nUser: ${user.user}'); // print user's information
        log('\nUserAdditionalInfo: ${user.additionalUserInfo}'); // print user's add  initial information

        // below if..else check that user is exist or not and based on then take actions
        if((await APIs.userExists())) {
          Navigator.pushReplacement(
              context, MaterialPageRoute(builder: (_) => const HomeScreen()));
        }
        else {
          // if user isn't exist then it first create and after take further action
          await APIs.createUser().then((value) {
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomeScreen()));
          });
        }

        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomeScreen()));
      }
    });
  }

  Future<UserCredential?> _signInWithGoogle() async {
    try {
      await InternetAddress.lookup('google.com');
      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();

      // Obtain the auth details from the request
      final GoogleSignInAuthentication? googleAuth = await googleUser?.authentication;

      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth?.accessToken,
        idToken: googleAuth?.idToken,
      );

      // Once signed in, return the UserCredential
      return await APIs.auth.signInWithCredential(credential);
    } catch(e) {
      log('\n_signInWithGoogle: $e');
      Dialogs.showSnackbar(context, 'Something went wrong (Check Internet)');
      return null;
    }
  }

  // _signOut() async {
  //   await FirebaseAuth.instance.signOut();
  //   await GoogleSignIn().signOut();
  // }

  @override
  Widget build(BuildContext context) {
    // mq = MediaQuery.of(context).size;
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text('Welcome to ChatSync',
            style: TextStyle(color: Colors.grey.shade800),
        ),

      ),
      body: Stack(
        children: [
          Positioned(
            top: mq.height * .15,
              left: mq.width * .25,
              width: mq.width * .5,
              child: Image.asset('images/chaticon.png')
          ),
          Positioned( // Google login button
              bottom: mq.height * .15,
              left: mq.width * .05,
              width: mq.width * .9,
              height: mq.height * .06,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey.shade800,
                  shape: StadiumBorder(),
                  elevation: 1),
                  onPressed: (){
                    _handleGoogleBtnClick();
                  },
                  icon: Image.asset('images/google.png', height: mq.height * .03,),
                  label: RichText(text: const TextSpan(
                      style: TextStyle(color: Colors.white, fontSize: 16),
                      children: [
                    TextSpan(text: 'Login with '),
                    TextSpan(text: 'Google',
                    style: TextStyle(fontWeight: FontWeight.w800)
                    ),
                  ]),)
              ),
          ),
        ],
      ),
    );
  }
}

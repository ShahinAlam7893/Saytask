import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

Future<void> saveDeviceToken()async{
  String? token = await FirebaseMessaging.instance.getToken();

  if(token!=null){

    String? userId = FirebaseAuth.instance.currentUser?.uid;
  
    if(userId!=null){
      await FirebaseFirestore.instance.collection('users')
      .doc(userId)
      .update({
        'fcmTokens': token,
      });
      print("FCM Token saved for user $userId: $token");
    }
    print("FCM Device Token: $token");
  }
}
import 'dart:developer';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.orange),
        useMaterial3: true,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  String? phoneNumber;
  bool showConfirmation = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Firebase Test'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Enter phone number beginning with country code (+1)'),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: TextField(
                decoration: const InputDecoration(
                  hintText: 'Enter phone number',
                ),
                onChanged: (value) {
                  setState(() {
                    phoneNumber = value;
                  });
                },
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                if (phoneNumber != null) {
                  final auth = FirebaseAuth.instance;

                  await auth.verifyPhoneNumber(
                    phoneNumber: phoneNumber!,
                    verificationCompleted:
                        (PhoneAuthCredential credential) async {
                      log('Verification completed: $credential');
                      await auth.signInWithCredential(credential);
                    },
                    verificationFailed: (FirebaseAuthException e) {
                      log('Verification failed: $e');
                    },
                    codeSent: (String verificationId, int? resendToken) async {
                      log('Code sent: $verificationId');
                      String? smsCode = await showConfirmationDialog();
                      if (smsCode != null) {
                        // Create a PhoneAuthCredential with the code
                        PhoneAuthCredential credential =
                            PhoneAuthProvider.credential(
                                verificationId: verificationId,
                                smsCode: smsCode);

                        // Sign the user in (or link) with the credential
                        final user =
                            await auth.signInWithCredential(credential);
                        log('User: $user');
                      }
                    },
                    codeAutoRetrievalTimeout: (String verificationId) {
                      log('Code auto retrieval timeout: $verificationId');
                    },
                  );

                  // if (code != null) {
                  //   UserCredential creds = await auth.
                  //   log('User: ${creds.user}');
                  // } else {
                  //   log('Code is null');
                  // }
                } else {
                  log('Phone number is null');
                }
              },
              child: const Text('Sign in with Phone Number'),
            ),
          ],
        ),
      ),
    );
  }

  Future<String?> showConfirmationDialog() async {
    String? verificationCode;

    return await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Enter Confirmation Code'),
          content: TextField(
            onChanged: (value) {
              setState(() {
                verificationCode = value;
              });
            },
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(verificationCode);
              },
              child: const Text('Submit'),
            ),
          ],
        );
      },
    );
  }
}

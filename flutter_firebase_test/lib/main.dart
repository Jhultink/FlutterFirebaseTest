import 'dart:developer';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:http/http.dart' as http;

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
  User? user;
  String? getDriverResponse;

  @override
  void initState() {
    super.initState();

    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      log('Auth state changed. User: ${user?.toString()}');
      setState(() {
        this.user = user;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Firebase Test'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                if (user == null) ...[
                  const Text(
                      'Enter phone number beginning with country code (+1)'),
                  TextField(
                    decoration: const InputDecoration(
                      hintText: 'Enter phone number',
                    ),
                    onChanged: (value) {
                      setState(() {
                        phoneNumber = value;
                      });
                    },
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
                          codeSent:
                              (String verificationId, int? resendToken) async {
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
                      } else {
                        log('Phone number is null');
                      }
                    },
                    child: const Text('Sign in with Phone Number'),
                  ),
                ] else ...[
                  ElevatedButton(
                    onPressed: () async {
                      await FirebaseAuth.instance.signOut();
                    },
                    child: const Text('Sign Out'),
                  ),
                  Text('User: $user'),
                  ElevatedButton(
                    child: const Text('GET /driver'),
                    onPressed: () async {
                      setState(() {
                        getDriverResponse = null;
                      });
                      final token = await user!.getIdToken();
                      log('Token: $token');
                      final resp = await http.get(
                        Uri.parse(
                            'https://app-rpm-drive-api-dev.azurewebsites.net/api/v2/driver'),
                        headers: {'Authorization': 'Bearer $token'},
                      );
                      final details = '${resp.statusCode} ${resp.body}';

                      log('GET /driver response: $details');

                      setState(() {
                        getDriverResponse = details;
                      });
                    },
                  ),
                  const Text('GET /driver response:'),
                  Text(getDriverResponse ?? ''),
                ],
              ],
            ),
          ),
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

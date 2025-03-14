import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:expense_split/ui/auth/auth_form.dart';
import 'package:fluttertoast/fluttertoast.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _auth = FirebaseAuth.instance;

  var _isLoading = false;

  Future<void> addUserDb(
      String userID, String email, String userName, String vpa) async {
    try {
      FirebaseFirestore db = FirebaseFirestore.instance;
      final user = <String, dynamic>{
        'uid': userID,
        'email': email,
        'username': userName,
        'vpa': vpa, // Add UPI ID
        'createdAt': FieldValue.serverTimestamp(), // Add timestamp
      };
      await db.collection("users").doc(userID).set(user);
    } catch (e) {
      print("Firestore error: $e");
      rethrow; // Re-throw to handle in calling function
    }
  }

  void _submitAuthForm(
    String email,
    String password,
    String userName,
    String vpa,
    bool isLogin,
    BuildContext ctx,
  ) async {
    UserCredential userCredential;
    try {
      setState(() {
        _isLoading = true;
      });
      if (isLogin) {
        userCredential = await _auth.signInWithEmailAndPassword(
            email: email, password: password);
      } else {
        userCredential = await _auth.createUserWithEmailAndPassword(
            email: email, password: password);
        // Add proper error handling for the database operation
        if (userCredential.user != null) {
          try {
            await addUserDb(userCredential.user!.uid, email, userName, vpa);
          } catch (dbError) {
            // Handle database errors specifically
            if (mounted) {
              ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
                content: Text(
                    "Failed to create user profile: ${dbError.toString()}"),
                backgroundColor: Theme.of(ctx).colorScheme.error,
              ));
            }
          }
        }
      }

      // Clear loading state on success
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } on PlatformException catch (err) {
      var message = "An error occured please check your credentails";

      if (err.message != null) {
        message = err.message.toString();
      }

      // Add mounted check before using BuildContext
      if (mounted) {
        ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
          content: Text(message),
          backgroundColor: Theme.of(ctx).colorScheme.error,
        ));

        setState(() {
          _isLoading = false;
        });
      }
    } catch (err) {
      Fluttertoast.showToast(
          msg: "Your credentials are incorrect",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Colors.red,
          textColor: Colors.white,
          webBgColor: "#e74c3c",
          timeInSecForIosWeb: 10,
          fontSize: 16.0);
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: AuthForm(submitFn: _submitAuthForm, isLoading: _isLoading),
    );
  }
}

import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tiktok_clone_app/constants.dart';
import 'package:tiktok_clone_app/models/userModel.dart' as model;

class AuthController extends GetxController {
  static AuthController instance = Get.find();

  late Rx<File?> _pickedImage;

  File? get profilePhoto => _pickedImage.value;

  // * Pick an image
  void pickImage() async {
    final pickedImage =
        await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedImage != null) {
      Get.snackbar("Profile Picture", "Success Pick Profile Picture");
    }

    _pickedImage = Rx<File?>(File(pickedImage!.path));
  }

  // * Upload to firebase storage
  Future<String> _uploadToStorage(File image) async {
    Reference ref = firebaseStorage
        .ref()
        .child("profilePics")
        .child(firebasAuth.currentUser!.uid);

    UploadTask uploadTask = ref.putFile(image);
    TaskSnapshot snap = await uploadTask;
    String downloadUrl = await snap.ref.getDownloadURL();
    return downloadUrl;
  }

  // * Register new user
  void registerUser(
      String username, String email, String password, File? image) async {
    try {
      if (username.isNotEmpty &&
          email.isNotEmpty &&
          email.isEmail &&
          password.isNotEmpty &&
          image != null) {
        // * Save out user to our auth and firebse firestore
        UserCredential cred = await firebasAuth.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );

        String downloadUrl = await _uploadToStorage(image);

        model.User user = model.User(
          name: username,
          email: email,
          uid: cred.user!.uid,
          profilePhoto: downloadUrl,
        );

        await firestore
            .collection('users')
            .doc(cred.user!.uid)
            .set(user.toJson());
      } else {
        Get.snackbar("Error Creating Account", "Please enter all of fields");
      }
    } catch (e) {
      Get.snackbar("Error Creating Account", e.toString());
    }
  }

  // * Login user
  void loginUser(String email, String password) async {
    try {
      if (email.isNotEmpty && password.isNotEmpty && email.isEmail) {
        await firebasAuth.signInWithEmailAndPassword(
            email: email, password: password);
      } else {
        Get.snackbar("Error Loggin Account", "Please enter all of fiels");
      }
    } catch (e) {
      Get.snackbar("Error Loggin Account", e.toString());
    }
  }
}

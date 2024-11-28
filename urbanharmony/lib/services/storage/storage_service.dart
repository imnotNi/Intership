import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:urbanharmony/services/auth/auth_service.dart';
import 'package:urbanharmony/services/firestore/firestore_background.dart';

class StorageService with ChangeNotifier {
  final firebaseStorage = FirebaseStorage.instance;
  final _auth = AuthService();
  final FirestoreBackground _firestoreBackground = FirestoreBackground();
  //image save as url download
  List<String> _imageUrls = [];
  //loading status
  bool _isLoading = false;
  //uploading status
  bool _isUploading = false;

  List<String> _imageUrlsUser = [];
  List<String> get imageUrlsUser => _imageUrlsUser;

  //getter
  List<String> get imageUrls => _imageUrls;
  bool get isLoading => _isLoading;
  bool get isUploading => _isUploading;

  //read
  Future<void> fetchImages() async {
    _isLoading = true;
    // get list image
    final ListResult result =
        await firebaseStorage.ref('backgrounds/').listAll();

    //download url
    final urls =
        await Future.wait(result.items.map((ref) => ref.getDownloadURL()));
    //update url
    _imageUrls = urls;
    _isLoading = false;

    notifyListeners();
  }
  Future<void> fetchImagesUser() async {
    _isLoading = true;
    final userId = _auth.getCurrentUID();

    // Fetch background URLs from Firestore
    final querySnapshot = await _firestoreBackground.getBackgroundByUserId(userId);

    // Use a Set to efficiently store unique URLs and avoid duplicates
    final uniqueBgUrls = querySnapshot.docs
        .map((doc) => doc['Url'] as String)
        .toSet();

    // Update _imageUrlsUser only with unique URLs
    _imageUrlsUser.removeWhere((url) => uniqueBgUrls.contains(url));
    _imageUrlsUser.addAll(uniqueBgUrls);

    _isLoading = false;
    notifyListeners();
  }
  //delete image
  Future<void> deleteImages(String imageUrl) async {
    try {
      _imageUrls.remove(imageUrl);

      final String path = extractPathFromUrl(imageUrl);

      await firebaseStorage.ref(path).delete();
    } catch (e) {
      print("Error deleting image: $e");
    }
    notifyListeners();
  }

  String extractPathFromUrl(String url) {
    Uri uri = Uri.parse(url);

    String encodedPath = uri.pathSegments.last;

    return Uri.decodeComponent(encodedPath);
  }

  //upload image

  Future<void> uploadImage() async {
    _isUploading = true;

    notifyListeners();

    //pick image
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image == null) return;

    File file = File(image.path);

    try {
      String filePath = 'backgrounds/${DateTime.now()}.png';
      //upload ti firebase
      await firebaseStorage.ref(filePath).putFile(file);

      String downloadUrl = await firebaseStorage.ref(filePath).getDownloadURL();

      _imageUrls.add(downloadUrl);
      notifyListeners();
    } catch (e) {
      print(e);
    } finally {
      _isUploading = false;
      notifyListeners();
    }
  }

  Future<void> uploadImageUser() async {
    _isUploading = true;

    notifyListeners();

    //pick image
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image == null) return;

    File file = File(image.path);

    try {
      String filePath = 'backgrounds_user/${DateTime.now()}.png';
      //upload ti firebase
      await firebaseStorage.ref(filePath).putFile(file);

      String downloadUrl = await firebaseStorage.ref(filePath).getDownloadURL();

      _imageUrlsUser.add(downloadUrl);
      await _firestoreBackground.addBackground(_auth.getCurrentUID(), downloadUrl);

      notifyListeners();
    } catch (e) {
      print(e);
    } finally {
      _isUploading = false;
      notifyListeners();
    }
  }

}

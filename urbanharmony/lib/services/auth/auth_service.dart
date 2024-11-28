import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:urbanharmony/services/database/database_service.dart';

class AuthService {
  final _auth = FirebaseAuth.instance;
  final _db = DatabaseService();

  //getcurrentuser uid

  User? getCurrentUser() => _auth.currentUser;
  String getCurrentUID() => _auth.currentUser!.uid;

  //login

  Future<UserCredential> loginEmailPassword(String email, password) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
          email: email, password: password);
      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw Exception(e.code);
    }
  }
  //register

  Future<UserCredential> registerEmailPassword(String email, password) async {
    try {
      UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(email: email, password: password);
      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw Exception(e.code);
    }
  }

  //logout

  Future<void> logout() async {
    await _auth.signOut();
  }

  //delete account
  Future<void> deleteAccount() async {
    User? user = getCurrentUser();

    if (user != null) {
      //delete from fire store
      await DatabaseService().deleteUserInfoFromFirebase(user.uid);

      //delete from auth record

      await user.delete();
    }
  }

  //reset password

  Future<void> sendPasswordResetLink(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      print(e.toString());
    }
  }

  //google signin
  signInWithGoogle() async {
    try {
      final GoogleSignInAccount? gUser = await GoogleSignIn().signIn();

      if (gUser == null) return;

      final GoogleSignInAuthentication gAuth = await gUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: gAuth.accessToken,
        idToken: gAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);
      print(getCurrentUser()!.email);
      print(getCurrentUser()!.displayName);
      await _db.saveUserInfoInFirebase(
          name: gUser.displayName!, email: gUser.email);
      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw Exception(e.code);
    }
  }
}

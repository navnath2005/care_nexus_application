import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SOSService {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  Future<void> sendSOS({String? location}) async {
    final user = _auth.currentUser;
    if (user == null) return;

    await _firestore.collection("sos_requests").add({
      "userId": user.uid,
      "email": user.email,
      "location": location ?? "Unknown",
      "timestamp": FieldValue.serverTimestamp(),
      "status": "pending",
    });
  }
}

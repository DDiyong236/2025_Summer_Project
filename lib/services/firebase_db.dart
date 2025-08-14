import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// 항상 'walkydb' 데이터베이스를 사용하도록 하는 공용 getter.
/// Firebase.initializeApp() 이후에 호출되어야 하므로 getter로 둡니다.
FirebaseFirestore get db =>
    FirebaseFirestore.instanceFor(app: Firebase.app(), databaseId: 'walkydb');

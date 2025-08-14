import 'dart:core';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_db.dart'; // ✅ walkydb 전용 db

class Todo {
  final String id;        // 파이어스토어 문서ID
  final String title;     // 할일 제목
  final bool done;        // 완료 여부
  final DateTime createdAt; // 생성 시각

  Todo({
    required this.id,
    required this.title,
    required this.done,
    required this.createdAt,
  });

  factory Todo.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return Todo(
      id: doc.id,
      title: data['title'] ?? '',
      done: data['done'] ?? false,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
    'title': title,
    'done': done,
    'createdAt': createdAt,
  };
}

class TodoService {
  // ✅ 꼭 walkydb로!
  final CollectionReference _col = db.collection('todos');

  Future<void> add(String title) async {
    await _col.add({
      'title': title,
      'done': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> setDone(String id, bool done) async {
    await _col.doc(id).update({'done': done});
  }

  Future<void> delete(String id) async {
    await _col.doc(id).delete();
  }

  Stream<List<Todo>> watchAll() {
    return _col
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((q) => q.docs.map((d) => Todo.fromDoc(d)).toList());
  }

  Future<List<Todo>> fetchOnce({int limit = 20}) async {
    final snap =
    await _col.orderBy('createdAt', descending: true).limit(limit).get();
    return snap.docs.map((d) => Todo.fromDoc(d)).toList();
  }
}

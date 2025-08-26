import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:convert';

Future<String?> uploadJsonToFirebaseStroage({
  required String userId,
  required String fileName,
  required String jsonData,
}) async {
  try {
    final storageRef = FirebaseStorage.instance
        .ref()
        .child('course_data/$userId/$fileName.json');
    final Uint8List data = Uint8List.fromList(utf8.encode(jsonData));

    final uploadTask = storageRef.putData(data);

    final snapshot = await uploadTask;

    final downloadUrl = await snapshot.ref.getDownloadURL();

    print('파일 업로드 성공: $downloadUrl');
    return downloadUrl;
  } on FirebaseException catch(e){
    print('파일 업로드 오류: ${e.code}');
    return null;
  }
}

Future<String?> downloadJsonFromFirebaseStorage(String fileUrl) async{
  try{
    final ref = FirebaseStorage.instance.refFromURL(fileUrl);
    final data = await ref.getData();

    if(data==null){
      print("파일 데이터가 없습니다.");
      return null;
    }
    final jsonData = utf8.decode(data);
    return jsonData;
  }on FirebaseException catch(e){
    print('파일 다운로드 오류: ${e.code}');
    return null;
  }
}

Future<List<String>> listJsonFiles(String userId) async {
  try {
    final storageRef = FirebaseStorage.instance.ref().child('course_data/$userId');
    final listResult = await storageRef.listAll();

    List<String> fileUrls = [];
    for (var item in listResult.items) {
      final url = await item.getDownloadURL();
      fileUrls.add(url);
    }
    return fileUrls;
  } on FirebaseException catch (e) {
    print('파일 목록을 가져오는 중 오류 발생: ${e.code}');
    return [];
  }
}
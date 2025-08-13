import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;

  // 수동으로 사용자 상태 관리 (7.x.x에서는 currentUser가 제거됨)
  GoogleSignInAccount? _currentGoogleUser;
  bool _isGoogleSignInInitialized = false;

  // 현재 Firebase 사용자
  User? get currentUser => _auth.currentUser;

  // 현재 Google 사용자 (수동 관리)
  GoogleSignInAccount? get currentGoogleUser => _currentGoogleUser;

  // 인증 상태 변경 스트림
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Google Sign-In 초기화 (7.x.x에서 필수)
  Future<void> _initializeGoogleSignIn() async {
    if (!_isGoogleSignInInitialized) {
      try {
        await _googleSignIn.initialize();
        _isGoogleSignInInitialized = true;
      } catch (e) {
        print('Google Sign-In 초기화 실패: $e');
        throw Exception('Google Sign-In 초기화에 실패했습니다: $e');
      }
    }
  }

  // Google 로그인 (7.x.x 새로운 authenticate() 방식)
  Future<UserCredential> signInWithGoogle() async {
    try {
      // Google Sign-In 초기화 확인
      await _initializeGoogleSignIn();

      // authenticate() 메서드 지원 여부 확인
      if (!_googleSignIn.supportsAuthenticate()) {
        throw Exception('이 플랫폼에서는 Google 로그인이 지원되지 않습니다.');
      }

      // Google 인증 (새로운 방식)
      final GoogleSignInAccount googleUser = await _googleSignIn.authenticate(
        scopeHint: ['email', 'profile'], // 필요한 스코프 명시
      );

      // 사용자 상태 수동 업데이트
      _currentGoogleUser = googleUser;

      // 7.x.x에서는 authorizationClient를 통해 액세스 토큰을 가져옴
      final authClient = _googleSignIn.authorizationClient;
      final authorization = await authClient.authorizationForScopes(['email', 'profile']);

      if (authorization == null) {
        throw Exception('Google 인증 권한을 가져올 수 없습니다.');
      }

      // ID 토큰은 authentication에서 가져옴 (7.x.x에서는 동기식)
      final GoogleSignInAuthentication googleAuth = googleUser.authentication;

      if (googleAuth.idToken == null || authorization.accessToken == null) {
        throw Exception('Google 인증 토큰을 가져올 수 없습니다.');
      }

      // Firebase 인증 자격 증명 생성
      final credential = GoogleAuthProvider.credential(
        accessToken: authorization.accessToken!,
        idToken: googleAuth.idToken!,
      );

      // Firebase로 로그인
      final UserCredential userCredential = await _auth.signInWithCredential(credential);

      return userCredential;
    } on GoogleSignInException catch (e) {
      // Google Sign-In 7.x.x 전용 예외 처리
      String message;
      switch (e.code.name) {
        case 'canceled':
          message = '로그인이 취소되었습니다.';
          break;
        case 'interrupted':
          message = '로그인이 중단되었습니다. 다시 시도해주세요.';
          break;
        case 'clientConfigurationError':
          message = 'Google 로그인 설정에 문제가 있습니다.';
          break;
        case 'providerConfigurationError':
          message = 'Google 로그인 서비스를 사용할 수 없습니다.';
          break;
        case 'uiUnavailable':
          message = 'Google 로그인 화면을 표시할 수 없습니다.';
          break;
        case 'userMismatch':
          message = '계정 정보가 일치하지 않습니다.';
          break;
        case 'unknownError':
        default:
          message = 'Google 로그인 중 알 수 없는 오류가 발생했습니다.';
      }
      throw Exception(message);
    } on FirebaseAuthException catch (e) {
      // Firebase 인증 관련 에러
      switch (e.code) {
        case 'account-exists-with-different-credential':
          throw Exception('다른 로그인 방식으로 이미 등록된 계정입니다.');
        case 'invalid-credential':
          throw Exception('인증 정보가 올바르지 않습니다.');
        case 'operation-not-allowed':
          throw Exception('Google 로그인이 비활성화되어 있습니다.');
        case 'user-disabled':
          throw Exception('비활성화된 사용자 계정입니다.');
        default:
          throw Exception('로그인 중 오류가 발생했습니다: ${e.message}');
      }
    } catch (e) {
      throw Exception('Google 로그인 중 오류가 발생했습니다: $e');
    }
  }

  // 자동 로그인 시도 (7.x.x에서 signInSilently 대체)
  Future<GoogleSignInAccount?> attemptSilentSignIn() async {
    try {
      await _initializeGoogleSignIn();

      // attemptLightweightAuthentication은 Future 또는 즉시 결과 반환 가능
      final result = _googleSignIn.attemptLightweightAuthentication();

      GoogleSignInAccount? account;
      if (result is Future<GoogleSignInAccount?>) {
        account = await result;
      } else {
        account = result as GoogleSignInAccount?;
      }

      // 사용자 상태 업데이트
      _currentGoogleUser = account;
      return account;
    } catch (e) {
      print('자동 로그인 실패: $e');
      return null;
    }
  }

  // 로그아웃
  Future<void> signOut() async {
    try {
      await Future.wait([
        _auth.signOut(),
        _googleSignIn.signOut(),
      ]);

      // 사용자 상태 초기화
      _currentGoogleUser = null;
    } catch (e) {
      throw Exception('로그아웃 중 오류가 발생했습니다: $e');
    }
  }

  // Google 연결 완전 해제 (7.x.x 새 기능)
  Future<void> disconnect() async {
    try {
      await _googleSignIn.signOut(); // 7.x.x에서는 signOut이 disconnect 역할
      _currentGoogleUser = null;
    } catch (e) {
      throw Exception('Google 연결 해제 중 오류가 발생했습니다: $e');
    }
  }

  // 특정 스코프에 대한 액세스 토큰 가져오기 (7.x.x 새 기능)
  Future<String?> getAccessTokenForScopes(List<String> scopes) async {
    try {
      await _initializeGoogleSignIn();

      final authClient = _googleSignIn.authorizationClient;

      // 기존 권한 확인
      var authorization = await authClient.authorizationForScopes(scopes);

      if (authorization == null) {
        // 새로운 권한 요청
        authorization = await authClient.authorizeScopes(scopes);
      }

      return authorization?.accessToken;
    } catch (e) {
      print('스코프 권한 획득 실패: $e');
      return null;
    }
  }

  // 로그인 상태 확인
  bool get isLoggedIn => _auth.currentUser != null;
  bool get isGoogleSignedIn => _currentGoogleUser != null;

  // 사용자 정보 접근자들
  String? get displayName => _auth.currentUser?.displayName;
  String? get email => _auth.currentUser?.email;
  String? get photoURL => _auth.currentUser?.photoURL;
  String? get uid => _auth.currentUser?.uid;

  // Google 사용자 정보 접근자들
  String? get googleDisplayName => _currentGoogleUser?.displayName;
  String? get googleEmail => _currentGoogleUser?.email;
  String? get googlePhotoUrl => _currentGoogleUser?.photoUrl;
  String? get googleId => _currentGoogleUser?.id;
}
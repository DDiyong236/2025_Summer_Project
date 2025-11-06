const functions = require("firebase-functions");
const admin = require("firebase-admin");
const axios = require("axios");

admin.initializeApp();

functions.setGlobalOptions({ maxInstances: 10 });

exports.kakaoLogin = functions.https.onCall(async (data, context) => {
  const accessToken = data.data.accessToken;

  if (!accessToken) {
    console.error("Kakao Login Error: Access token is missing.");
    throw new functions.https.HttpsError("invalid-argument", "The function must be called with a valid Kakao access token.");
  }

  try {
    const response = await axios.get("https://kapi.kakao.com/v2/user/me", {
      headers: {
        "Authorization": `Bearer ${accessToken}`,
      },
    });

    const kakaoUser = response.data;
    const uid = `kakao:${kakaoUser.id}`;

    const customToken = await admin.auth().createCustomToken(uid);
    console.log(`Kakao Login Success: Custom Token generated for UID: ${uid}`);

    return { customToken: customToken };

  } catch (error) {
    console.error("Kakao login internal error:", error);
    if (error.response) {
      console.error("Kakao API response error:", error.response.data);
    }
    throw new functions.https.HttpsError("internal", "Unable to authenticate with Kakao.");
  }
});


exports.naverLogin = functions.https.onCall(async (data, context) => {
  const accessToken = data.accessToken;

  // ⭐️ 1. 토큰 유효성 검사 로그 ⭐️
  if (!accessToken) {
    console.error("Naver Login Error: Access token is missing.");
    throw new functions.https.HttpsError("invalid-argument", "The function must be called with a valid Naver access token.");
  }

  try {
    // ⭐️ 2. 토큰 수신 확인 로그 ⭐️
    console.log('--- Naver Login Process Start ---');
    console.log('Received Naver Access Token (length):', accessToken.length);

    // 3. 네이버 API를 호출하여 사용자 정보 요청
    const response = await axios.get("https://openapi.naver.com/v1/nid/me", {
      headers: {
        "Authorization": `Bearer ${accessToken}`,
      },
    });

    // ⭐️ 3. 네이버 API 응답 확인 로그 ⭐️
    console.log('Naver API Response Status:', response.status);

    const naverUser = response.data.response;
    const uid = `naver:${naverUser.id}`;

    // ⭐️ 4. UID 생성 확인 로그 ⭐️
    console.log('Generated UID:', uid);

    // 4. Custom Token 생성 및 반환
    const customToken = await admin.auth().createCustomToken(uid);

    console.log(`Naver Login Success: Custom Token generated for UID: ${uid}`);
    console.log('--- Naver Login Process End ---');

    return { customToken: customToken };

  } catch (error) {
    console.error("Naver login internal error (Try/Catch):", error);
    if (error.response) {
      // ⭐️ 5. API 응답 에러 상세 로그 ⭐️
      console.error("Naver API response error data:", error.response.data);
      console.error("Naver API response error status:", error.response.status);
    }
    throw new functions.https.HttpsError("internal", "Unable to authenticate with Naver.");
  }
});
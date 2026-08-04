# SNS 로그인 로컬 설정

실제 인증키는 `config/local.json` 한 곳에만 저장하고 Git에는 커밋하지 않는다. `android/local.properties`에는 Flutter SDK 경로만 둔다.

## 필요한 값

| 항목 | 용도 |
| --- | --- |
| `KAKAO_NATIVE_APP_KEY` | Android 카카오 SDK 초기화 및 콜백 Scheme |
| `NAVER_LOGIN_CLIENT_ID` | Android 네이버 SDK 설정 |
| `NAVER_LOGIN_CLIENT_SECRET` | Android 네이버 SDK 설정 |
| `API_BASE_URL` | 앱이 호출할 백엔드 주소 |

## 로컬 파일 설정

`config/local.example.json`을 복사해 `config/local.json`을 만들고 실제 값을 입력한다.

```json
{
  "API_BASE_URL": "http://10.100.105.28:8080",
  "KAKAO_NATIVE_APP_KEY": "실제_카카오_Native_App_Key"
}
```

`android/local.properties`에는 기존 `sdk.dir`와 `flutter.sdk`만 유지한다. Android Gradle 설정도 `config/local.json`을 읽는다.

## 실행

```powershell
flutter clean
flutter pub get
flutter run --dart-define-from-file=config/local.json
```

카카오 키 해시는 환경변수가 아니다. `android/gradlew.bat signingReport`로 확인한 SHA-1 기반 키 해시를 Kakao Developers의 네이티브 앱 키 > Android 앱 정보에 등록한다.

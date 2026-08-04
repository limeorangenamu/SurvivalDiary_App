# 모바일 SNS 로그인 로컬 설정

실제 인증값은 `config/local.json`에만 저장하며 Git에 커밋하지 않는다.

```json
{
  "API_BASE_URL": "http://127.0.0.1:8080",
  "KAKAO_NATIVE_APP_KEY": "카카오 Native App Key",
  "NAVER_LOGIN_CLIENT_ID": "네이버 Client ID",
  "NAVER_LOGIN_CLIENT_SECRET": "네이버 Client Secret"
}
```

앱은 반드시 설정 파일을 Dart define으로 전달해 빌드한다.

```powershell
C:\utils\flutter\bin\flutter.bat run --dart-define-from-file=config/local.json
```

Android Studio의 Flutter Run Configuration에도 다음 Additional run args를 등록한다.

```text
--dart-define-from-file=config/local.json
```

USB 실기기에서 PC의 로컬 백엔드를 사용할 때만 포트 전달을 설정한다.

```powershell
& "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe" reverse tcp:8080 tcp:8080
```

ADB 연결이 재설정되면 reverse도 사라진다. 연결이 불안정한 기기에서는 같은 Wi-Fi의 PC 사설 IP 또는 배포된 HTTPS 개발 서버를 사용한다.

## OAuth 콘솔 등록

- Android 패키지: `com.survivaldiary.project_survival_diary`
- 카카오: Native App Key 사용, 각 개발자의 debug key hash 등록
- 네이버: Android 앱 패키지 및 다운로드 URL 등록

카카오 SDK 초기화 오류가 표시되면 `local.json`의 존재 여부가 아니라 Dart define 실행 옵션이 들어갔는지 확인한다.

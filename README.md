# Claude Usage Monitor

macOS 메뉴바에서 Claude API 사용량(Rate Limit)을 실시간으로 모니터링하는 앱입니다.

## 기능

- 메뉴바에서 현재 사용량 퍼센트 표시
- 5시간 / 7일 Rate Limit 사용량 및 리셋 시간 확인
- 1분 간격 자동 갱신

## 요구사항

- macOS 14.0 (Sonoma) 이상
- Swift 5.9 이상
- [Claude Code](https://docs.anthropic.com/en/docs/claude-code) 로그인 필요 (OAuth 토큰을 Keychain에서 읽음)

## 설치

```bash
# 1. 저장소 클론
git clone https://github.com/ysjk2003/claude-usage.git
cd claude-usage/ClaudeUsageMonitor

# 2. 빌드
./build.sh

# 3. 실행
open .build/release/ClaudeUsageMonitor.app
```

## 로그인 앱에 등록 (선택)

시작 시 자동으로 실행되도록 하려면:

**시스템 설정 > 일반 > 로그인 항목 및 확장 프로그램 > +** 에서 `.build/release/ClaudeUsageMonitor.app`을 추가하세요.

또는 앱을 `/Applications`에 복사한 뒤 등록할 수 있습니다:

```bash
cp -r .build/release/ClaudeUsageMonitor.app /Applications/
```

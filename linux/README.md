# Antigravity (agy) Linux & WSL 설정 가이드

Linux 및 WSL2(Windows Subsystem for Linux) 환경에서 Antigravity CLI(`agy`)의 상태줄(statusline) 스크립트 동작 원리와 설정 가이드입니다.

---

## 1. 주요 특징

1. **Bash / POSIX 호환 및 심볼릭 링크 자동 추적 (`statusline.sh`)**
   * `#!/usr/bin/env bash` 및 `readlink` 루프를 사용하여 `~/.gemini/antigravity-cli/statusline.sh` 심볼릭 링크 어디에서 호출되더라도 원본 `statusline.py` 위치를 정확히 찾아 실행합니다.
2. **모델 계열별 쿼터 자동 매칭 및 Gemini 쿼터 별도 조회 (2분 캐시)**
   * 현재 활성 모델(`model.id`, `model.display_name`)이 **Gemini 계열**인지 **Claude / GPT 등 3P 계열**인지 구분하여 해당 모델의 쿼터만 표시합니다.
   * `agy`의 `quota` 페이로드에 `gemini-5h`가 누락된 경우, 로컬 OAuth 토큰(`~/.gemini/antigravity-cli/antigravity-oauth-token`)으로 `fetchAvailableModels` API를 조회하여 실제 Gemini 5시간 쿼터 및 리셋 시각을 가져오며, `~/.gemini/antigravity-cli/cache/gemini_quota_cache.json`에 **120초(2분) 단위**로 캐싱합니다.
3. **폰트 의존성 제거 (Font-independent)**
   * 별도의 Nerd Font 설치가 필요 없는 클래식 유니코드/이모지 모드가 기본 활성화되어 있습니다(`--nerdfont` 옵션으로 전환 가능).
4. **스마트 배터리 감지 (Auto ON/OFF)**
   * `/sys/class/power_supply/BAT*`가 존재하는 노트북/WSL 환경에서는 충전 상태(`⚡:100%` / `🔋:80%`)를 자동 표시하고, 배터리가 없는 데스크탑/서버에서는 자동으로 숨김 처리합니다.

---

## 2. 동기화 구성 (심볼릭 링크)

저장소 루트 디렉터리에서 아래 명령을 실행하여 계정 환경에 심볼릭 링크를 연결합니다:

```bash
# ~/.gemini/antigravity-cli/ 표준 경로 (우선 탐색)
ln -sf "$(pwd)/linux/statusline.sh" ~/.gemini/antigravity-cli/statusline.sh
ln -sf "$(pwd)/linux/statusline.py" ~/.gemini/antigravity-cli/statusline.py

# 레거시 경로 호환용
ln -sf "$(pwd)/linux/statusline.sh" ~/.gemini/statusline.sh
ln -sf "$(pwd)/linux/statusline.py" ~/.gemini/statusline.py
```

---

## 3. 계정 설정 (`settings.json`)

`~/.gemini/antigravity-cli/settings.json`에 다음 설정을 추가합니다:

```json
{
  "statusLine": {
    "type": "command",
    "command": "~/.gemini/antigravity-cli/statusline.sh",
    "enabled": true
  }
}
```

* 템플릿 참고: [`linux/settings.json`](./settings.json)

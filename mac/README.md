# Antigravity (agy) macOS (MacBook & Desktop Mac 통합) 설정 가이드

macOS 환경(MacBook 및 일반 데스크탑 Mac: Mac mini, Mac Studio, iMac, Mac Pro)에서 Antigravity CLI(`agy`)의 상태줄(statusline) 스크립트 동작 원리와 설정 가이드입니다.

---

## 1. 주요 특징

1. **폰트 의존성 제거 (Font-independent)**
   * 별도의 Nerd Font 설치가 필요 없는 클래식 유니코드/이모지 모드가 기본 활성화되어 있어 터미널 환경에 구애받지 않고 깔끔하게 출력됩니다.
   * Nerd Font 모드를 원할 경우 `--nerdfont` 옵션을 통해 즉시 전환할 수 있습니다.
2. **스마트 배터리 감지 (Auto ON/OFF)**
   * **MacBook**: 배터리 잔량 및 충전 상태(AC 전원 `⚡:100%`, 배터리 구동 `🔋:33%`)를 자동으로 감지하여 노출합니다.
   * **일반 Mac (데스크탑)**: 배터리가 없는 환경에서는 불필요한 배터리/전원 항목이 자동으로 완전히 숨김(OFF) 처리됩니다.
3. **견고한 쿼터 리셋 시각 파싱 (`extract_reset_sec`)**
   * Antigravity 응답 포맷(ISO8601, Epoch 밀리초/초 등)을 모두 지원하여 리셋 카운트다운을 정확하게 표시합니다.
4. **강화된 예외 처리**
   * JSON 파싱부터 출력 전 과정이 예외 안전하게 보호되어 터미널에 오류 트레이스백이 노출되지 않습니다.

---

## 2. 동기화 구성 (심볼릭 링크)

저장소 루트 디렉터리에서 아래 명령을 실행하여 계정 환경에 심볼릭 링크를 연결합니다:

```bash
# ~/.gemini/antigravity-cli/ 표준 경로 (우선 탐색)
ln -sf "$(pwd)/mac/statusline.sh" ~/.gemini/antigravity-cli/statusline.sh
ln -sf "$(pwd)/mac/statusline.py" ~/.gemini/antigravity-cli/statusline.py

# 레거시 경로 호환용
ln -sf "$(pwd)/mac/statusline.sh" ~/.gemini/statusline.sh
ln -sf "$(pwd)/mac/statusline.py" ~/.gemini/statusline.py
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

* 템플릿 참고: [`mac/settings.json`](./settings.json)

---

## 4. 검증 및 테스트 방법

아래 테스트 JSON을 전달하여 상태줄 출력을 확인할 수 있습니다:

```bash
~/.gemini/antigravity-cli/statusline.sh << 'EOF'
{
  "agent_state": "idle",
  "model": {"display_name": "Gemini 3.8 Flash"},
  "context_window": {"used_percentage": 30.0, "total_input_tokens": 1200, "total_output_tokens": 800, "context_window_size": 1000000},
  "cwd": "/path/to/project",
  "terminal_width": 140,
  "quota": {
    "gemini-5h": {"remaining_fraction": 0.80, "reset_time": "2026-09-06T16:00:00Z"},
    "gemini-weekly": {"remaining_fraction": 0.90, "reset_at": 1788700000}
  }
}
EOF
```

**출력 형태 예시**:
* **MacBook (배터리 구동 시)**:
  ```text
  ╭─ ● READY | 💻 hostname.local | Gemini 3.8 Flash | .../project-dir | main
  ╰─ ctx 30.0% (2.0K/1.0M) | tasks 0 | 5H 80.0% ⌛ 13h 36m | 7D 90.0% ⌛ 10h 42m | 🔋:33%
  ```
* **MacBook (전원 연결 시)**:
  ```text
  ╰─ ctx 30.0% (2.0K/1.0M) | tasks 0 | 5H 80.0% ⌛ 13h 36m | 7D 90.0% ⌛ 10h 42m | ⚡:100%
  ```
* **일반 데스크탑 Mac (배터리 없음)**:
  ```text
  ╰─ ctx 30.0% (2.0K/1.0M) | tasks 0 | 5H 80.0% ⌛ 13h 36m | 7D 90.0% ⌛ 10h 42m
  ```

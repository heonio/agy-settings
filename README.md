# Antigravity CLI (agy) Settings

Google DeepMind Antigravity CLI(`agy`)의 상태줄(statusline) 스크립트 및 환경별 설정을 관리하는 저장소입니다.

---

## 📁 디렉터리 구성

| 환경 | 디렉터리 | 주요 파일 | 설명 |
| :--- | :--- | :--- | :--- |
| **MacBook** | [`macbook/`](./macbook) | `statusline.sh`, `statusline.py`, `settings.json`, `README.md` | 클래식 아이콘 기본값, 프로그레스 바 형태의 5H/7D 쿼터 및 리셋 카운트다운 지원 |
| **Mac (Desktop)** | [`mac/`](./mac) | `statusline.sh`, `statusline.py`, `settings.json` | 데스크탑 macOS 환경용 상태줄 스크립트 및 설정 |
| **Windows** | [`win/`](./win) | `statusline.ps1`, `settings.json` | PowerShell 기반의 Windows 환경용 상태줄 스크립트 및 설정 |

---

## 🚀 빠른 시작 (MacBook 기준)

### 1. 심볼릭 링크 설정
저장소 루트 디렉터리에서 다음 명령을 실행하여 계정 환경에 심볼릭 링크를 연결합니다:

```bash
# ~/.gemini/antigravity-cli/ 표준 경로 (저장소 루트 기준)
ln -sf "$(pwd)/macbook/statusline.sh" ~/.gemini/antigravity-cli/statusline.sh
ln -sf "$(pwd)/macbook/statusline.py" ~/.gemini/antigravity-cli/statusline.py

# 레거시 경로 호환용
ln -sf "$(pwd)/macbook/statusline.sh" ~/.gemini/statusline.sh
ln -sf "$(pwd)/macbook/statusline.py" ~/.gemini/statusline.py
```

### 2. Antigravity CLI 설정 (`~/.gemini/antigravity-cli/settings.json`)
> [!NOTE]
> 상태줄 스크립트(`statusline.*`)만 심볼릭 링크로 연결하며, `settings.json`은 계정별 개별 설정을 보존하기 위해 심볼릭 링크를 걸지 않고 필요한 `statusLine` 설정만 직접 추가합니다.

```json
{
  "statusLine": {
    "type": "command",
    "command": "~/.gemini/antigravity-cli/statusline.sh",
    "enabled": true
  }
}
```

자세한 설정 방법 및 테스트 가이드는 [`macbook/README.md`](./macbook/README.md) 문서를 참고하세요.

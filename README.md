# Antigravity CLI (agy) Settings

Google DeepMind Antigravity CLI(`agy`)의 상태줄(statusline) 스크립트 및 환경별 설정을 관리하는 저장소입니다.

> [!NOTE]
> 이 저장소의 상태줄(statusline) 스크립트는 [weby-homelab/antigravity-cli-statusline](https://github.com/weby-homelab/antigravity-cli-statusline) 프로젝트를 기반으로 시작되어, 폰트 의존성 제거(클래식 유니코드/이모지 기본값 적용), macOS 환경의 배터리 유무 자동 감지(Auto ON/OFF), 쿼터 리셋 시각 파싱 강화 등의 개선을 거쳐 구성되었습니다.

---

## 📁 디렉터리 구성

| 환경 | 디렉터리 | 주요 파일 | 설명 |
| :--- | :--- | :--- | :--- |
| **Linux / WSL2** | [`linux/`](./linux) | `statusline.sh`, `statusline.py`, `settings.json`, `README.md` | Bash 기반 래퍼, 모델별 쿼터 매칭 및 Gemini 쿼터 2분 캐시 조회, `/sys/class/power_supply` 배터리 자동 감지 지원 |
| **macOS** (MacBook / Desktop Mac) | [`mac/`](./mac) | `statusline.sh`, `statusline.py`, `settings.json`, `README.md` | 폰트 의존성 없는 유니코드 클래식 아이콘 기본값, 모델별 쿼터 매칭, MacBook/데스크탑 Mac 배터리 자동 감지 지원 |
| **Windows** | [`win/`](./win) | `statusline.ps1`, `settings.json` | PowerShell 기반의 Windows 환경용 상태줄 스크립트 및 설정 |

---

## 🚀 빠른 시작 (Linux / WSL 및 macOS)

### 1. 심볼릭 링크 설정
저장소 루트 디렉터리에서 환경(`linux` 또는 `mac`)에 맞게 다음 명령을 실행하여 심볼릭 링크를 연결합니다:

```bash
# Linux / WSL2 환경
ln -sf "$(pwd)/linux/statusline.sh" ~/.gemini/antigravity-cli/statusline.sh
ln -sf "$(pwd)/linux/statusline.py" ~/.gemini/antigravity-cli/statusline.py

# macOS 환경
ln -sf "$(pwd)/mac/statusline.sh" ~/.gemini/antigravity-cli/statusline.sh
ln -sf "$(pwd)/mac/statusline.py" ~/.gemini/antigravity-cli/statusline.py
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

자세한 설정 방법 및 테스트 가이드는 [`mac/README.md`](./mac/README.md) 문서를 참고하세요.

---

## 🔗 출처 및 참고 (Credits)

* 원본 프로젝트: [weby-homelab/antigravity-cli-statusline](https://github.com/weby-homelab/antigravity-cli-statusline)

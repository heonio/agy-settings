#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import sys
import os
import json
import socket
import subprocess
import shutil
import re
import time
import base64
import tempfile
import urllib.request
from datetime import datetime, timezone

GEMINI_QUOTA_CACHE_TTL = 120  # Seconds (2 minutes) between fetchAvailableModels quota lookups

def extract_reset_sec(d):
    if not isinstance(d, dict):
        return -1

    for key in ("reset_in_seconds", "reset_seconds", "reset_in_sec", "reset_sec", "reset_seconds_remaining"):
        val = d.get(key)
        if isinstance(val, (int, float)) and val > 0:
            return float(val)
        if isinstance(val, str):
            try:
                v = float(val)
                if v > 0: return v
            except ValueError:
                pass

    for key in ("reset_time", "reset_at", "resetTime", "resetAt"):
        val = d.get(key)
        if isinstance(val, (int, float)) and val > 0:
            now = time.time()
            ts = val / 1000.0 if val > 1e11 else float(val)
            if ts > now:
                return ts - now
        elif isinstance(val, str) and val:
            try:
                iso_str = val.replace("Z", "+00:00")
                dt = datetime.fromisoformat(iso_str)
                now_dt = datetime.now(timezone.utc)
                diff = (dt - now_dt).total_seconds()
                if diff > 0:
                    return diff
            except Exception:
                pass
    return -1

def print_legend():
    # Colors
    R = "\033[0m"
    G = "\033[32m"
    W = "\033[37m"
    Y = "\033[33m"
    C = "\033[36m"
    M = "\033[35m"
    B = "\033[34m"
    GR = "\033[90m"
    RED = "\033[31m"
    
    print(f"{G}🚀 Antigravity CLI Statusline Legend (Linux & WSL Unified){R}")
    print("This statusline adapts dynamically to your terminal width, host type, and theme settings.\n")
    
    print(f"{W}LAYOUTS:{R}")
    print("  - Wide Layout (>= 180 chars): Single-row, full developer telemetry dashboard.")
    print("  - Medium Layout (>= 90 chars): Two-line boxed block to prevent line wrap.")
    print("  - Small Layout (< 90 chars): Minimalist indicator for status, model, context & tasks.\n")
    
    print(f"{W}COMPONENTS & ICONS:{R}")
    print(f"  {W}Field                Nerd Font   Classic     Description{R}")
    print(f"  {W}--------------------------------------------------------------------------------{R}")
    
    print(f"  State: READY         {G}           {G}●           {R}Agent is idle, ready for user requests.")
    print(f"  State: THINKING      {Y}󰟷           {Y}◆           {R}Agent is processing/thinking.")
    print(f"  State: WORKING       {C}           {C}⚙           {R}Agent is executing background operations.")
    print(f"  State: TOOL          {M}           {M}🔧          {R}Agent is running a tool.")
    print(f"  State: UNKNOWN       {W}           {W}⏳          {R}Agent state is unknown or initializing.")
    print(f"  Host Info            {B}󰒋           {B}💻          {R}Local hostname & Tailscale IP.")
    print(f"  VCS Branch           {B}           {GR}(Text)      {R}Current Git branch name (Red + * if dirty).")
    print(f"  Model                {M}           {GR}(Text)      {R}Current active LLM model name/ID.")
    print(f"  Sandbox Network      {G}󰒙           {G}ON (net)    {R}Sandbox enabled with internet access.")
    print(f"  Sandbox Restricted   {G}󰴴           {G}ON (no-net) {R}Sandbox enabled with network disabled.")
    print(f"  Sandbox Off          {RED}󰦜           {GR}sandbox off {R}Sandbox is disabled (runs on host).")
    print(f"  Context Bar          {Y}󱍏           {GR}ctx         {R}Context window usage percentage.")
    print(f"  Artifacts            {B}           {GR}artifacts   {R}Number of active output artifacts.")
    print(f"  Subagents            {C}󱙺           {GR}subagents   {R}Number of spawned active subagents.")
    print(f"  Background Tasks     {M}           {GR}tasks       {R}Number of background tasks running.")
    print(f"  Current Directory    {C}           {GR}(Text)      {R}Current working directory path (shortened).")
    print(f"  Conversation ID      {GR}󰍪           {GR}(Text)      {R}Short prefix of the current session ID.")
    print(f"  Tokens Sum           {Y}           {GR}(None)      {R}Total input/output tokens parsed.")
    print(f"  Quota Reset Time     {GR}⌛️          {GR}⌛          {R}Remaining time until LLM quota resets.")
    print(f"  Power Mains (AC)     {G}󰚥           {G}⚡:{{cap}}%     {R}Laptop connected to AC power (shows charge %).")
    print(f"  Power Battery (BAT)  {Y}🔋           {Y}🔋:{{cap}}%     {R}Laptop running on battery (shows charge %).")
    print(f"  Desktop Power        {GR}(Hidden)     {GR}(Hidden)    {R}Auto-disabled on Desktop PCs/Servers without battery.")
    print(f"  Account & Tier       {GR}󰇮           {GR}✉           {R}Current plan tier & user email.")
    
    print(f"\n{W}TIPS:{R}")
    print("  Default mode is Classic (Font-independent: works out-of-the-box on any terminal).")
    print("  To enable Nerd Font mode, pass --nerdfont or -nf.")
    print("  To toggle Context Gauge bar, use --context-gauge / --no-context-gauge (default: off).")
    print("  To toggle Quota Gauge bar, use --quota-gauge / --no-quota-gauge (default: off).")

# ─── Command Line Arguments & Theme ─────────────────────────────────────────────
for arg in sys.argv[1:]:
    if arg.lower() in ("--legend", "-l", "-legend", "legend"):
        print_legend()
        sys.exit(0)

# Option variables (configurable in script or via CLI arguments)
# Default is True: Font-independent classic mode with clean Unicode emojis
use_classic_icons = True
show_context_gauge = False  # True: Show gauge bar in context window, False: text only (default: off)
show_quota_gauge = False    # True: Show gauge bar in quota, False: text only (default: off)

for arg in sys.argv[1:]:
    arg_l = arg.lower()
    if arg_l in ("--nerdfont", "--nerd-font", "-nf"):
        use_classic_icons = False
    elif arg_l in ("--classic", "--no-nerdfont", "--compatibility"):
        use_classic_icons = True
    elif arg_l in ("--context-gauge", "--ctx-gauge", "--context-bar", "--ctx-bar"):
        show_context_gauge = True
    elif arg_l in ("--no-context-gauge", "--no-ctx-gauge", "--no-context-bar", "--no-ctx-bar"):
        show_context_gauge = False
    elif arg_l in ("--quota-gauge", "--quota-bar", "--gauge"):
        show_quota_gauge = True
    elif arg_l in ("--no-quota-gauge", "--no-quota-bar", "--no-gauge"):
        show_quota_gauge = False

# Read JSON input from stdin
try:
    input_json = sys.stdin.read().strip()
    if not input_json:
        sys.exit(0)

    # Parse JSON safely
    try:
        data = json.loads(input_json)
    except Exception:
        sys.exit(0)

    # Helper for safe dictionary access when value in JSON might be None
    def safe_dict(val):
        return val if isinstance(val, dict) else {}

    # Extract properties with fallbacks
    STATE = data.get("agent_state") or "idle"
    ctx_window = safe_dict(data.get("context_window"))
    USED_PCT = ctx_window.get("used_percentage") or 0.0

    vcs = safe_dict(data.get("vcs"))
    VCS_BRANCH = vcs.get("branch") or ""
    VCS_DIRTY = bool(vcs.get("dirty"))
    VCS_TYPE = vcs.get("type") or ""

    sandbox = safe_dict(data.get("sandbox"))
    SANDBOX = bool(sandbox.get("enabled"))
    SANDBOX_NET = bool(sandbox.get("allow_network"))

    ARTIFACTS = data.get("artifact_count") or 0

    subagents_raw = data.get("subagents") or []
    SUBAGENTS = len(subagents_raw) if isinstance(subagents_raw, list) else 0

    BG_TASKS = data.get("task_count") or 0

    model = safe_dict(data.get("model"))
    MODEL_ID = model.get("id") or ""
    MODEL_NAME = model.get("display_name") or ""

    COLS = data.get("terminal_width") or 80
    CWD = data.get("cwd") or ""
    CONV_ID = data.get("conversation_id") or ""
    CLI_VERSION = data.get("version") or ""
    PLAN_TIER = data.get("plan_tier") or ""
    USER_EMAIL = data.get("email") or ""

    current_usage = safe_dict(ctx_window.get("current_usage"))
    TURN_INPUT_TOKENS = current_usage.get("input_tokens") or 0
    TURN_OUTPUT_TOKENS = current_usage.get("output_tokens") or 0

    INPUT_TOKENS = ctx_window.get("total_input_tokens") or 0
    OUTPUT_TOKENS = ctx_window.get("total_output_tokens") or 0
    CTX_LIMIT = ctx_window.get("context_window_size") or 0
    CTX_USED = INPUT_TOKENS + OUTPUT_TOKENS
    REM_PCT = ctx_window.get("remaining_percentage") if ctx_window.get("remaining_percentage") is not None else 100.0

    # Quotas
    quota = safe_dict(data.get("quota"))
    gemini_5h_raw = safe_dict(quota.get("gemini-5h"))
    gemini_weekly_raw = safe_dict(quota.get("gemini-weekly"))
    tp_5h_raw = safe_dict(quota.get("3p-5h"))
    tp_weekly_raw = safe_dict(quota.get("3p-weekly"))

    GEMINI_5H = round(gemini_5h_raw.get("remaining_fraction") * 100, 1) if gemini_5h_raw.get("remaining_fraction") is not None else -1
    GEMINI_WK = round(gemini_weekly_raw.get("remaining_fraction") * 100, 1) if gemini_weekly_raw.get("remaining_fraction") is not None else -1
    TP_5H = round(tp_5h_raw.get("remaining_fraction") * 100, 1) if tp_5h_raw.get("remaining_fraction") is not None else -1
    TP_WK = round(tp_weekly_raw.get("remaining_fraction") * 100, 1) if tp_weekly_raw.get("remaining_fraction") is not None else -1

    GEMINI_5H_RESET = extract_reset_sec(gemini_5h_raw)
    GEMINI_WK_RESET = extract_reset_sec(gemini_weekly_raw)
    TP_5H_RESET = extract_reset_sec(tp_5h_raw)
    TP_WK_RESET = extract_reset_sec(tp_weekly_raw)

    # ANSI Helpers
    ESC = "\033"
    R = f"{ESC}[0m"
    B = f"{ESC}[1m"
    D = f"{ESC}[2m"
    I = f"{ESC}[3m"

    FG_BLACK = f"{ESC}[30m"
    FG_RED = f"{ESC}[31m"
    FG_GREEN = f"{ESC}[32m"
    FG_YELLOW = f"{ESC}[33m"
    FG_BLUE = f"{ESC}[34m"
    FG_MAGENTA = f"{ESC}[35m"
    FG_CYAN = f"{ESC}[36m"
    FG_WHITE = f"{ESC}[37m"

    FG_GRAY = f"{ESC}[90m"
    FG_BRIGHT_RED = f"{ESC}[91m"
    FG_BRIGHT_GREEN = f"{ESC}[92m"
    FG_BRIGHT_YELLOW = f"{ESC}[93m"
    FG_BRIGHT_BLUE = f"{ESC}[94m"
    FG_BRIGHT_MAGENTA = f"{ESC}[95m"
    FG_BRIGHT_CYAN = f"{ESC}[96m"
    FG_BRIGHT_WHITE = f"{ESC}[97m"

    NUM_COLOR = f"{FG_BRIGHT_WHITE}{B}"
    DOT = f"{FG_GRAY} | {R}"

    # Timeout Process Helper
    def run_command(cmd, timeout_ms=1000):
        try:
            res = subprocess.run(cmd, capture_output=True, text=True, timeout=timeout_ms/1000.0)
            if res.returncode == 0:
                return res.stdout.strip()
        except Exception:
            pass
        return None

    # VCS directly from git (Bypasses JSON caches)
    GIT_DIR = CWD if CWD else "."
    if os.path.exists(GIT_DIR):
        git_branch = run_command(["git", "-C", GIT_DIR, "rev-parse", "--abbrev-ref", "HEAD"])
        if git_branch:
            VCS_BRANCH = git_branch
            VCS_TYPE = "git"
            git_status = run_command(["git", "-C", GIT_DIR, "status", "--porcelain"])
            VCS_DIRTY = bool(git_status)

    # Format percentages
    PCT_FMT = f"{USED_PCT:.1f}"
    PCT_INT = int(USED_PCT)

    # Formatting helpers
    def human_format(num):
        if num is None or num == 0:
            return "0"
        if num >= 1000000:
            return f"{num / 1000000.0:.1f}M"
        if num >= 1000:
            return f"{num / 1000.0:.1f}K"
        return str(num)

    INPUT_TOK_FMT = human_format(INPUT_TOKENS)
    OUTPUT_TOK_FMT = human_format(OUTPUT_TOKENS)
    CTX_LIMIT_FMT = human_format(CTX_LIMIT)
    CTX_USED_FMT = human_format(CTX_USED)
    TURN_INPUT_FMT = human_format(TURN_INPUT_TOKENS)
    TURN_OUTPUT_FMT = human_format(TURN_OUTPUT_TOKENS)

    def shorten_path(path):
        if not path:
            return ""
        home_dir = os.path.expanduser("~")
        if home_dir and path.startswith(home_dir):
            path = "~" + path[len(home_dir):]
        if len(path) > 25:
            return "..." + os.path.basename(path)
        return path

    CWD_SHORT = shorten_path(CWD)

    # Icons setup based on classic vs nerd font mode
    if use_classic_icons:
        DOT_L1 = f"{FG_GRAY} | {R}"
        DOT_L2 = f"{FG_GRAY} | {R}"
        ICON_READY = "●"
        ICON_THINKING = "◆"
        ICON_WORKING = "⚙"
        ICON_TOOL = "🔧"
        ICON_STATE_UNKNOWN = "⏳"
        ICON_VCS = "🌿"
        ICON_MODEL = "🤖"
        ICON_SANDBOX_NET = "ON (net)"
        ICON_SANDBOX_NONET = "ON (no-net)"
        ICON_SANDBOX_OFF = "OFF"
        ICON_CONTEXT_BAR = "ctx"
        ICON_ARTIFACTS = "artifacts"
        ICON_SUBAGENTS = "subagents"
        ICON_TASKS = "tasks"
        ICON_DIR = "📁"
        ICON_CONV = "#"
        ICON_TOK_SUM = ""
        ICON_RESET = "⌛"
        ICON_AC = "⚡"
        ICON_BAT = "🔋"
    else:
        DOT_L1 = f"{FG_GRAY} | {R}"
        DOT_L2 = f"{FG_GRAY} | {R}"
        ICON_READY = ""
        ICON_THINKING = "󰟷"
        ICON_WORKING = ""
        ICON_TOOL = ""
        ICON_STATE_UNKNOWN = ""
        ICON_VCS = ""
        ICON_MODEL = ""
        ICON_SANDBOX_NET = "󰒙"
        ICON_SANDBOX_NONET = "󰴴"
        ICON_SANDBOX_OFF = "󰦜"
        ICON_CONTEXT_BAR = "󱍏"
        ICON_ARTIFACTS = ""
        ICON_SUBAGENTS = "󱙺"
        ICON_TASKS = ""
        ICON_DIR = ""
        ICON_CONV = "󰍪"
        ICON_TOK_SUM = ""
        ICON_RESET = "⌛️"
        ICON_AC = "󰚥"
        ICON_BAT = "🔋"

    def visible_len(s):
        stripped = re.sub(r'\x1b\[[0-9;]*m', '', s)
        return len(stripped)

    CLI_VER_FMT = ""
    if CLI_VERSION:
        CLI_VER_FMT = f"{DOT_L1}{FG_GRAY}v{CLI_VERSION}{R}"

    USER_FMT = ""
    if PLAN_TIER or USER_EMAIL:
        user_info = ""
        if PLAN_TIER and USER_EMAIL:
            user_info = f"{PLAN_TIER} ({USER_EMAIL})"
        elif PLAN_TIER:
            user_info = PLAN_TIER
        else:
            user_info = USER_EMAIL

        if len(user_info) > 35:
            user_info = user_info[:32] + "..."

        if use_classic_icons:
            USER_FMT = f"{DOT_L2}{FG_GRAY}✉ {user_info}{R}"
        else:
            USER_FMT = f"{DOT_L2}{FG_GRAY}󰇮 {user_info}{R}"

    # Get hostname and Tailscale IP
    HOST_NAME = ""
    try:
        HOST_NAME = socket.gethostname()
    except Exception:
        pass

    TS_IP = ""
    tailscale_cmd = shutil.which("tailscale") or shutil.which("tailscale.exe")
    if not tailscale_cmd and os.path.exists("/mnt/c/Program Files/Tailscale/tailscale.exe"):
        tailscale_cmd = "/mnt/c/Program Files/Tailscale/tailscale.exe"
    elif not tailscale_cmd and os.path.exists("/Applications/Tailscale.app/Contents/Resources/bin/tailscale"):
        tailscale_cmd = "/Applications/Tailscale.app/Contents/Resources/bin/tailscale"

    if tailscale_cmd:
        ts_status = run_command([tailscale_cmd, "ip", "-4"])
        if ts_status:
            TS_IP = ts_status.strip().splitlines()[0].strip()

    HOST_FMT = ""
    if HOST_NAME:
        host_details = HOST_NAME
        if TS_IP:
            host_details = f"{HOST_NAME} ({TS_IP})"
        if use_classic_icons:
            HOST_FMT = f"{DOT_L1}{FG_BRIGHT_BLUE}💻 {host_details}{R}"
        else:
            HOST_FMT = f"{DOT_L1}{FG_BRIGHT_BLUE}󰒋 {host_details}{R}"

    # Get Power Status on Mac / Linux (Auto ON when battery present, Auto OFF on Desktops)
    POWER_FMT = ""
    if sys.platform == "darwin":
        try:
            batt_output = run_command(["pmset", "-g", "batt"])
            if batt_output:
                # Detect internal battery (present on MacBooks, absent on Mac mini, Studio, Pro, iMac)
                has_battery = "InternalBattery" in batt_output or "Battery" in batt_output or "UPS" in batt_output
                pct_match = re.search(r'(\d+)%', batt_output)
                if has_battery and pct_match:
                    cap = pct_match.group(1)
                    cap_int = int(cap)

                    is_ac = "drawing from 'AC Power'" in batt_output or "Now drawing from 'AC Power'" in batt_output
                    if is_ac:
                        # Connected to AC Power (charging or fully charged)
                        if use_classic_icons:
                            POWER_FMT = f"{DOT_L2}{FG_GREEN}{ICON_AC}:{cap}%{R}"
                        else:
                            POWER_FMT = f"{DOT_L2}{FG_GREEN}{ICON_AC} {cap}%{R}"
                    else:
                        # Running on Battery Power (discharging)
                        bat_color = FG_BRIGHT_YELLOW
                        if cap_int < 20:
                            bat_color = FG_BRIGHT_RED
                        elif cap_int >= 50:
                            bat_color = FG_GREEN

                        if use_classic_icons:
                            POWER_FMT = f"{DOT_L2}{bat_color}{ICON_BAT}:{cap}%{R}"
                        else:
                            POWER_FMT = f"{DOT_L2}{bat_color}{ICON_BAT} {cap}%{R}"
                else:
                    # Desktop Mac without battery: automatically OFF
                    POWER_FMT = ""
        except Exception:
            pass
    elif sys.platform.startswith("linux"):
        try:
            ps_root = "/sys/class/power_supply"
            if os.path.isdir(ps_root):
                for entry in sorted(os.listdir(ps_root)):
                    if not entry.startswith("BAT"):
                        continue
                    bat_dir = os.path.join(ps_root, entry)
                    cap_file = os.path.join(bat_dir, "capacity")
                    stat_file = os.path.join(bat_dir, "status")
                    if os.path.isfile(cap_file):
                        with open(cap_file, "r", encoding="utf-8") as f:
                            cap = f.read().strip()
                        cap_int = int(cap)
                        status_str = ""
                        if os.path.isfile(stat_file):
                            with open(stat_file, "r", encoding="utf-8") as f:
                                status_str = f.read().strip().lower()
                        if status_str != "discharging":
                            if use_classic_icons:
                                POWER_FMT = f"{DOT_L2}{FG_GREEN}{ICON_AC}:{cap}%{R}"
                            else:
                                POWER_FMT = f"{DOT_L2}{FG_GREEN}{ICON_AC} {cap}%{R}"
                        else:
                            bat_color = FG_BRIGHT_YELLOW
                            if cap_int < 20:
                                bat_color = FG_BRIGHT_RED
                            elif cap_int >= 50:
                                bat_color = FG_GREEN
                            if use_classic_icons:
                                POWER_FMT = f"{DOT_L2}{bat_color}{ICON_BAT}:{cap}%{R}"
                            else:
                                POWER_FMT = f"{DOT_L2}{bat_color}{ICON_BAT} {cap}%{R}"
                        break
        except Exception:
            pass

    # State Indicator
    S = ""
    if STATE == "idle":
        S = f"{FG_BRIGHT_GREEN}{B} {ICON_READY} READY{R}"
    elif STATE == "thinking":
        S = f"{FG_BRIGHT_YELLOW}{B} {ICON_THINKING} THINKING{R}"
    elif STATE == "working":
        S = f"{FG_BRIGHT_CYAN}{B} {ICON_WORKING} WORKING{R}"
    elif STATE == "tool_use":
        S = f"{FG_BRIGHT_MAGENTA}{B} {ICON_TOOL} TOOL{R}"
    else:
        S = f"{FG_WHITE}{B} {ICON_STATE_UNKNOWN} {STATE.upper()}{R}"

    # VCS branch details
    V = ""
    if VCS_BRANCH:
        if VCS_DIRTY:
            if use_classic_icons:
                V = f"{DOT_L1}{FG_BRIGHT_RED}{VCS_BRANCH}{FG_BRIGHT_YELLOW}*{R}"
            else:
                V = f"{DOT_L1}{R}{FG_BRIGHT_RED}{ICON_VCS} {VCS_BRANCH}{FG_BRIGHT_YELLOW}*{R}"
        else:
            if use_classic_icons:
                V = f"{DOT_L1}{FG_BRIGHT_BLUE}{VCS_BRANCH}{R}"
            else:
                V = f"{DOT_L1}{R}{FG_BRIGHT_BLUE}{ICON_VCS} {VCS_BRANCH}{R}"

    # Model details
    disp = MODEL_NAME if MODEL_NAME else MODEL_ID
    M = ""
    if disp:
        if use_classic_icons:
            M = f"{DOT_L1}{FG_BRIGHT_MAGENTA}{I}{disp}{R}"
        else:
            M = f"{DOT_L1}{FG_BRIGHT_MAGENTA}{I}{ICON_MODEL} {disp}{R}"

    # Sandbox Badge
    SB = ""
    if SANDBOX:
        if SANDBOX_NET:
            SB = f"{FG_GREEN}{ICON_SANDBOX_NET} ON (net){R}"
        else:
            SB = f"{FG_GREEN}{ICON_SANDBOX_NONET} ON (no-net){R}"
    else:
        if use_classic_icons:
            SB = f"{FG_GRAY}sandbox off{R}"
        else:
            SB = f"{FG_RED}{ICON_SANDBOX_OFF} OFF{R}"

    # Context bar
    BAR_LEN = 5
    FILL_COLOR = FG_YELLOW
    if PCT_INT >= 90:
        FILL_COLOR = FG_BRIGHT_RED
    elif PCT_INT >= 60:
        FILL_COLOR = FG_BRIGHT_YELLOW

    bar_str = ""
    if show_context_gauge:
        FILLED = int(PCT_INT * BAR_LEN // 100)
        REMAINDER = int(PCT_INT * BAR_LEN % 100)
        if use_classic_icons:
            BAR = ""
            for i in range(BAR_LEN):
                if i < FILLED:
                    BAR += "█"
                elif i == FILLED:
                    if REMAINDER >= 75: BAR += "▓"
                    elif REMAINDER >= 50: BAR += "▒"
                    elif REMAINDER >= 25: BAR += "░"
                    else: BAR += "·"
                else:
                    BAR += "·"
            bar_str = f"{FILL_COLOR}{BAR} "
        else:
            BAR = ""
            for i in range(BAR_LEN):
                if i < FILLED:
                    BAR += f"{FILL_COLOR}█{R}"
                elif i == FILLED:
                    if REMAINDER >= 75: BAR += f"{FILL_COLOR}▓{R}{FG_GRAY}"
                    elif REMAINDER >= 50: BAR += f"{FILL_COLOR}▒{R}{FG_GRAY}"
                    else: BAR += f"{FILL_COLOR}░{R}{FG_GRAY}"
                else:
                    BAR += f"{FG_GRAY}░{R}"
            bar_str = f"{BAR} "

    if use_classic_icons:
        CTX_BAR = f"{FG_GRAY}ctx {bar_str}{NUM_COLOR}{PCT_FMT}%{R}"
    else:
        CTX_BAR = f"{FG_YELLOW}{ICON_CONTEXT_BAR} {bar_str}{NUM_COLOR}{PCT_FMT}%{R}"

    # Stats badges
    if use_classic_icons:
        ART_FMT = f"{FG_GRAY}artifacts {NUM_COLOR}{ARTIFACTS}{R}"
        SUB_FMT = f"{FG_GRAY}subagents {NUM_COLOR}{SUBAGENTS}{R}"
        BG_FMT = f"{FG_GRAY}tasks {NUM_COLOR}{BG_TASKS}{R}"
    else:
        ART_FMT = f"{FG_BLUE}{ICON_ARTIFACTS} {NUM_COLOR}{ARTIFACTS}{R}"
        SUB_FMT = f"{FG_CYAN}{ICON_SUBAGENTS} {NUM_COLOR}{SUBAGENTS}{R}"
        BG_FMT = f"{FG_MAGENTA}{ICON_TASKS} {NUM_COLOR}{BG_TASKS}{R}"

    DIR_FMT = ""
    if CWD_SHORT:
        if use_classic_icons:
            DIR_FMT = f"{DOT_L1}{FG_CYAN}{CWD_SHORT}{R}"
        else:
            DIR_FMT = f"{DOT_L1}{FG_CYAN}{ICON_DIR} {CWD_SHORT}{R}"

    CONV_FMT = ""
    if CONV_ID:
        short_conv = CONV_ID[:min(8, len(CONV_ID))]
        if use_classic_icons:
            CONV_FMT = f"{DOT_L1}{FG_GRAY}{short_conv}{R}"
        else:
            CONV_FMT = f"{DOT_L1}{FG_GRAY}{ICON_CONV} {short_conv}{R}"

    TOK_DETAILS_WIDE = ""
    TOK_DETAILS_MED = ""
    if CTX_USED > 0:
        turn_str = ""
        if TURN_INPUT_TOKENS > 0 or TURN_OUTPUT_TOKENS > 0:
            turn_str = f" | turn: +{TURN_INPUT_FMT}/{TURN_OUTPUT_FMT}"
        if use_classic_icons:
            TOK_DETAILS_WIDE = f" ({CTX_USED_FMT}/{CTX_LIMIT_FMT}){DOT_L2}(total: {INPUT_TOK_FMT}/{OUTPUT_TOK_FMT}{turn_str})"
            TOK_DETAILS_MED = f" ({CTX_USED_FMT}/{CTX_LIMIT_FMT})"
        else:
            TOK_DETAILS_WIDE = f" ({CTX_USED_FMT}/{CTX_LIMIT_FMT}){DOT_L2}{FG_YELLOW}{ICON_TOK_SUM} {R} (total: {INPUT_TOK_FMT}/{OUTPUT_TOK_FMT}{turn_str})"
            TOK_DETAILS_MED = f" ({CTX_USED_FMT}/{CTX_LIMIT_FMT})"

    # Quotas rendering
    def format_reset_time(sec):
        if sec is None or sec <= 0:
            return ""
        days = int(sec // 86400)
        rem = sec % 86400
        hours = int(rem // 3600)
        rem = rem % 3600
        mins = int(rem // 60)

        if days > 0:
            if hours > 0: return f"{days}d {hours}h"
            return f"{days}d"
        if hours > 0:
            if mins > 0: return f"{hours}h {mins}m"
            return f"{hours}h"
        if mins > 0:
            return f"{mins}m"
        return "<1m"

    QUOTA_BAR_LEN = 5

    def make_quota_bar(val, label, bar_color, reset_sec, bar_len=QUOTA_BAR_LEN, show_bar=None):
        if show_bar is None:
            show_bar = show_quota_gauge
        reset_label = f" {ICON_RESET} "
        separator = DOT_L2

        if val is None or val < 0:
            if show_bar:
                bar = "·" * bar_len if use_classic_icons else "░" * bar_len
                return f"{separator}{FG_BRIGHT_WHITE}{B}{label}{R} {FG_GRAY}{bar} N/A{R}"
            else:
                return f"{separator}{FG_BRIGHT_WHITE}{B}{label}{R} {FG_GRAY}N/A{R}"

        val_int = int(val)
        text_color = FG_BRIGHT_GREEN
        if val_int < 20:
            text_color = FG_BRIGHT_RED
        elif val_int < 50:
            text_color = FG_BRIGHT_YELLOW

        bar_str = ""
        if show_bar:
            filled = int(val_int * bar_len // 100)
            remainder = int(val_int * bar_len % 100)

            bar = ""
            for i in range(bar_len):
                if i < filled:
                    bar += "█" if use_classic_icons else f"{bar_color}█{R}"
                elif i == filled:
                    if use_classic_icons:
                        if remainder >= 75: bar += "▓"
                        elif remainder >= 50: bar += "▒"
                        elif remainder >= 25: bar += "░"
                        else: bar += "·"
                    else:
                        if remainder >= 75: bar += f"{bar_color}▓{R}{FG_GRAY}"
                        elif remainder >= 50: bar += f"{bar_color}▒{R}{FG_GRAY}"
                        elif remainder >= 25: bar += f"{bar_color}░{R}{FG_GRAY}"
                        else: bar += f"{FG_GRAY}░{R}"
                else:
                    bar += "·" if use_classic_icons else f"{FG_GRAY}░{R}"
            bar_str = f"{bar_color}{bar}{R} " if use_classic_icons else f"{bar} "

        reset_str = ""
        t = format_reset_time(reset_sec)
        if t:
            reset_str = f"{reset_label}{t}"

        val_fmt = f"{val:.1f}"
        return f"{separator}{FG_BRIGHT_WHITE}{B}{label}{R} {bar_str}{text_color}{val_fmt}%{R}{reset_str}"

    # Determine active quota based on current model family & availability
    def load_agy_access_token():
        token_raw = None
        token_file = os.path.expanduser("~/.gemini/antigravity-cli/antigravity-oauth-token")
        if os.path.exists(token_file):
            try:
                with open(token_file, "r", encoding="utf-8") as f:
                    token_raw = f.read().strip()
            except Exception:
                pass
        elif sys.platform == "darwin":
            token_raw = run_command(["security", "find-generic-password", "-s", "antigravity-oauth-token", "-w"], timeout_ms=800)
            if not token_raw:
                token_raw = run_command(["security", "find-generic-password", "-a", "antigravity-oauth-token", "-w"], timeout_ms=800)

        if not token_raw:
            return None

        if token_raw.startswith("go-keyring-base64:"):
            try:
                token_raw = base64.b64decode(token_raw.split(":", 1)[1]).decode("utf-8")
            except Exception:
                return None

        try:
            tok_obj = json.loads(token_raw)
            if isinstance(tok_obj, dict):
                nested = tok_obj.get("token")
                if isinstance(nested, dict) and nested.get("access_token"):
                    return nested.get("access_token")
                if tok_obj.get("access_token"):
                    return tok_obj.get("access_token")
        except Exception:
            pass
        return None

    def get_cached_gemini_quota(model_id="", ttl_sec=GEMINI_QUOTA_CACHE_TTL):
        cache_dir = os.path.expanduser("~/.gemini/antigravity-cli/cache")
        try:
            os.makedirs(cache_dir, exist_ok=True)
            cache_file = os.path.join(cache_dir, "gemini_quota_cache.json")
        except Exception:
            uid_suffix = f"_{os.getuid()}" if hasattr(os, "getuid") else ""
            cache_file = os.path.join(tempfile.gettempdir(), f"agy_gemini_quota_cache{uid_suffix}.json")
        now = time.time()

        cached = None
        if os.path.exists(cache_file):
            try:
                with open(cache_file, "r", encoding="utf-8") as f:
                    cached = json.load(f)
            except Exception:
                cached = None

        def select_from_cache(c):
            if not isinstance(c, dict):
                return None
            models_map = c.get("models")
            if isinstance(models_map, dict) and model_id and model_id in models_map:
                return models_map[model_id]
            if c.get("remaining_fraction") is not None:
                return {
                    "remaining_fraction": c.get("remaining_fraction"),
                    "reset_time": c.get("reset_time"),
                }
            return None

        if isinstance(cached, dict) and (now - (cached.get("fetched_at") or 0)) < ttl_sec:
            hit = select_from_cache(cached)
            if hit is not None:
                return hit

        # Cache miss or expired: query fetchAvailableModels
        access_token = load_agy_access_token()
        if access_token:
            try:
                ua_ver = CLI_VERSION if CLI_VERSION else "1.4.5"
                ua_plat = "darwin" if sys.platform == "darwin" else "linux"
                req = urllib.request.Request(
                    "https://daily-cloudcode-pa.googleapis.com/v1internal:fetchAvailableModels",
                    data=b"{}",
                    headers={
                        "Authorization": f"Bearer {access_token}",
                        "Content-Type": "application/json",
                        "User-Agent": f"antigravity/{ua_ver} {ua_plat}/amd64",
                    },
                    method="POST",
                )
                with urllib.request.urlopen(req, timeout=1.5) as resp:
                    fam = json.loads(resp.read().decode("utf-8"))

                models_raw = fam.get("models") if isinstance(fam, dict) else {}
                gemini_models = {}
                default_frac = None
                default_reset = None

                if isinstance(models_raw, dict):
                    for mid, minfo in models_raw.items():
                        if not isinstance(minfo, dict):
                            continue
                        m_sig = f"{mid} {minfo.get('displayName', '')} {minfo.get('modelProvider', '')}".lower()
                        if "gemini" in m_sig or "google" in m_sig:
                            qinfo = minfo.get("quotaInfo")
                            if isinstance(qinfo, dict) and qinfo.get("remainingFraction") is not None:
                                frac = float(qinfo["remainingFraction"])
                                rtime = qinfo.get("resetTime")
                                if rtime:
                                    gemini_models[mid] = {"remaining_fraction": frac, "reset_time": rtime}
                                    if default_frac is None:
                                        default_frac = frac
                                        default_reset = rtime

                if default_frac is not None:
                    new_cache = {
                        "fetched_at": now,
                        "remaining_fraction": default_frac,
                        "reset_time": default_reset,
                        "models": gemini_models,
                    }
                    try:
                        tmp_file = f"{cache_file}.{os.getpid()}.tmp"
                        with open(tmp_file, "w", encoding="utf-8") as f:
                            json.dump(new_cache, f)
                        os.replace(tmp_file, cache_file)
                    except Exception:
                        pass
                    return select_from_cache(new_cache)
            except Exception:
                pass

        # Fallback to stale cache if its reset_time has not passed yet
        hit = select_from_cache(cached)
        if hit is not None and extract_reset_sec(hit) > 0:
            return hit
        return None

    model_sig = f"{MODEL_ID} {MODEL_NAME}".lower()
    is_gemini_model = "gemini" in model_sig
    is_3p_model = any(k in model_sig for k in ("claude", "sonnet", "opus", "haiku", "gpt", "o1", "o3", "o4", "3p"))

    if is_gemini_model and (GEMINI_5H is None or GEMINI_5H == -1) and (GEMINI_WK is None or GEMINI_WK == -1):
        g_quota = get_cached_gemini_quota(MODEL_ID, ttl_sec=GEMINI_QUOTA_CACHE_TTL)
        if isinstance(g_quota, dict) and g_quota.get("remaining_fraction") is not None:
            GEMINI_5H = round(float(g_quota["remaining_fraction"]) * 100, 1)
            GEMINI_5H_RESET = extract_reset_sec(g_quota)

    if is_gemini_model:
        Q_5H = GEMINI_5H
        Q_WK = GEMINI_WK
        Q_5H_R = GEMINI_5H_RESET
        Q_WK_R = GEMINI_WK_RESET
    elif is_3p_model:
        Q_5H = TP_5H
        Q_WK = TP_WK
        Q_5H_R = TP_5H_RESET
        Q_WK_R = TP_WK_RESET
    elif (GEMINI_5H is not None and GEMINI_5H != -1) or (GEMINI_WK is not None and GEMINI_WK != -1):
        Q_5H = GEMINI_5H
        Q_WK = GEMINI_WK
        Q_5H_R = GEMINI_5H_RESET
        Q_WK_R = GEMINI_WK_RESET
    elif (TP_5H is not None and TP_5H != -1) or (TP_WK is not None and TP_WK != -1):
        Q_5H = TP_5H
        Q_WK = TP_WK
        Q_5H_R = TP_5H_RESET
        Q_WK_R = TP_WK_RESET
    else:
        Q_5H = -1
        Q_WK = -1
        Q_5H_R = -1
        Q_WK_R = -1

    QUOTA_FMT = ""
    if (Q_5H is not None and Q_5H != -1) or (Q_WK is not None and Q_WK != -1):
        q5 = make_quota_bar(Q_5H, '5H', FG_BRIGHT_CYAN, Q_5H_R) if Q_5H != -1 else ""
        qw = make_quota_bar(Q_WK, '7D', FG_BRIGHT_MAGENTA, Q_WK_R) if Q_WK != -1 else ""
        QUOTA_FMT = f"{q5}{qw}"

    def print_right_aligned(left, right, total_cols):
        left_vis = visible_len(left)
        right_vis = visible_len(right)
        pad = total_cols - left_vis - right_vis
        if pad < 1:
            pad = 1
        spaces = " " * pad
        return f"{left}{spaces}{right}"

    # Output Assembly based on Column Width
    if COLS >= 180:
        LINE1 = f"{S}{CLI_VER_FMT}{HOST_FMT}{M}{DIR_FMT}{V}{CONV_FMT}"
        LINE2 = f"{BG_FMT}{DOT_L2}{CTX_BAR}{TOK_DETAILS_WIDE}{QUOTA_FMT}{POWER_FMT}{USER_FMT}" if QUOTA_FMT else f"{BG_FMT}{DOT_L2}{CTX_BAR}{TOK_DETAILS_WIDE}{POWER_FMT}{USER_FMT}"
        print(print_right_aligned(LINE1, LINE2, COLS), end='')
    elif COLS >= 90:
        LINE1 = f"{S}{CLI_VER_FMT}{HOST_FMT}{M}{DIR_FMT}{V}"
        LINE2 = f" {CTX_BAR}{TOK_DETAILS_MED}{DOT_L2}{BG_FMT}{QUOTA_FMT}{POWER_FMT}{USER_FMT}" if QUOTA_FMT else f" {CTX_BAR}{TOK_DETAILS_MED}{DOT_L2}{BG_FMT}{POWER_FMT}{USER_FMT}"
        print(f"{FG_GRAY}╭─{R}{LINE1}\n{FG_GRAY}╰─{R}{LINE2}")
    else:
        M_SHORT = ""
        if disp:
            short_name = disp[:12]
            if use_classic_icons:
                M_SHORT = f"{FG_GRAY} ╱ {FG_BRIGHT_MAGENTA}{short_name}{R}"
            else:
                M_SHORT = f"{FG_GRAY} ╱ {FG_BRIGHT_MAGENTA}{ICON_MODEL} {short_name}{R}"

        if QUOTA_FMT:
            print(f"{S}{M_SHORT}\n{CTX_BAR}{DOT_L2}{BG_FMT}{QUOTA_FMT}{POWER_FMT}{USER_FMT}")
        else:
            print(f"{S}{M_SHORT}\n{CTX_BAR}{DOT_L2}{BG_FMT}{POWER_FMT}{USER_FMT}")

except Exception:
    sys.exit(0)

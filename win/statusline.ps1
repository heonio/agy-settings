# Disable progress bar to speed up web requests or execution if any
$ProgressPreference = 'SilentlyContinue'

# Set Output Encoding to UTF-8 to support nerd font icons on Windows
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# Check for legend parameter before reading stdin
foreach ($arg in $args) {
    if ($arg -eq "--legend" -or $arg -eq "-l" -or $arg -eq "-Legend" -or $arg -eq "legend") {
        Write-Host "🚀 Antigravity CLI Statusline Legend" -ForegroundColor Green
        Write-Host "This statusline adapts dynamically to your terminal width and theme settings.`n"
        
        Write-Host "LAYOUTS:" -ForegroundColor White
        Write-Host "  - Wide Layout (>= 180 chars): Single-row, full developer telemetry dashboard."
        Write-Host "  - Medium Layout (>= 90 chars): Two-line boxed block to prevent line wrap."
        Write-Host "  - Small Layout (< 90 chars): Minimalist indicator for status, model, context & tasks.`n"
        
        Write-Host "COMPONENTS & ICONS:" -ForegroundColor White
        Write-Host "  Field                Nerd Font   Classic     Description" -ForegroundColor White
        Write-Host "  --------------------------------------------------------------------------------"
        
        Write-Host "  State: READY         " -NoNewline; Write-Host "           " -ForegroundColor Green -NoNewline; Write-Host "●           " -ForegroundColor Green -NoNewline; Write-Host "Agent is idle, ready for user requests."
        Write-Host "  State: THINKING      " -NoNewline; Write-Host "󰟷           " -ForegroundColor Yellow -NoNewline; Write-Host "◆           " -ForegroundColor Yellow -NoNewline; Write-Host "Agent is processing/thinking."
        Write-Host "  State: WORKING       " -NoNewline; Write-Host "           " -ForegroundColor Cyan -NoNewline; Write-Host "⚙           " -ForegroundColor Cyan -NoNewline; Write-Host "Agent is executing background operations."
        Write-Host "  State: TOOL          " -NoNewline; Write-Host "           " -ForegroundColor Magenta -NoNewline; Write-Host "🔧          " -ForegroundColor Magenta -NoNewline; Write-Host "Agent is running a tool."
        Write-Host "  State: UNKNOWN       " -NoNewline; Write-Host "           " -ForegroundColor White -NoNewline; Write-Host "⏳          " -ForegroundColor White -NoNewline; Write-Host "Agent state is unknown or initializing."
        Write-Host "  VCS Branch           " -NoNewline; Write-Host "           " -ForegroundColor Blue -NoNewline; Write-Host "/           " -ForegroundColor Gray -NoNewline; Write-Host "Current Git branch name (Red + * if dirty)."
        Write-Host "  Model                " -NoNewline; Write-Host "           " -ForegroundColor Magenta -NoNewline; Write-Host "(None)      " -ForegroundColor DarkGray -NoNewline; Write-Host "Current active LLM model name/ID."
        Write-Host "  Sandbox Network      " -NoNewline; Write-Host "󰒙           " -ForegroundColor Green -NoNewline; Write-Host "ON (net)    " -ForegroundColor Green -NoNewline; Write-Host "Sandbox enabled with internet access."
        Write-Host "  Sandbox Restricted   " -NoNewline; Write-Host "󰴴           " -ForegroundColor Green -NoNewline; Write-Host "ON (no-net) " -ForegroundColor Green -NoNewline; Write-Host "Sandbox enabled with network disabled."
        Write-Host "  Sandbox Off          " -NoNewline; Write-Host "󰦜           " -ForegroundColor Red -NoNewline; Write-Host "sandbox off " -ForegroundColor Gray -NoNewline; Write-Host "Sandbox is disabled (runs on host)."
        Write-Host "  Context Bar          " -NoNewline; Write-Host "󱍏           " -ForegroundColor Yellow -NoNewline; Write-Host "ctx         " -ForegroundColor Gray -NoNewline; Write-Host "5-segment visual context window usage bar."
        Write-Host "  Artifacts            " -NoNewline; Write-Host "           " -ForegroundColor Blue -NoNewline; Write-Host "artifacts   " -ForegroundColor Gray -NoNewline; Write-Host "Number of active output artifacts."
        Write-Host "  Subagents            " -NoNewline; Write-Host "󱙺           " -ForegroundColor Cyan -NoNewline; Write-Host "subagents   " -ForegroundColor Gray -NoNewline; Write-Host "Number of spawned active subagents."
        Write-Host "  Background Tasks     " -NoNewline; Write-Host "           " -ForegroundColor Magenta -NoNewline; Write-Host "tasks       " -ForegroundColor Gray -NoNewline; Write-Host "Number of background tasks running."
        Write-Host "  Current Directory    " -NoNewline; Write-Host "           " -ForegroundColor Cyan -NoNewline; Write-Host "/           " -ForegroundColor Gray -NoNewline; Write-Host "Current working directory path (shortened)."
        Write-Host "  Conversation ID      " -NoNewline; Write-Host "󰍪           " -ForegroundColor Gray -NoNewline; Write-Host "/           " -ForegroundColor Gray -NoNewline; Write-Host "Short prefix of the current session ID."
        Write-Host "  Tokens Sum           " -NoNewline; Write-Host "           " -ForegroundColor Yellow -NoNewline; Write-Host "(None)      " -ForegroundColor DarkGray -NoNewline; Write-Host "Total input/output tokens parsed."
        Write-Host "  Quota Reset Time     " -NoNewline; Write-Host "⌛️          " -ForegroundColor Gray -NoNewline; Write-Host "⌛          " -ForegroundColor Gray -NoNewline; Write-Host "Remaining time until LLM quota resets."
        Write-Host "  Power Mains (AC)     " -NoNewline; Write-Host "󰚥           " -ForegroundColor Green -NoNewline; Write-Host "AC          " -ForegroundColor Green -NoNewline; Write-Host "Host is connected to external AC power."
        Write-Host "  Power Battery (UPS)  " -NoNewline; Write-Host "🔋           " -ForegroundColor Yellow -NoNewline; Write-Host "BAT         " -ForegroundColor Yellow -NoNewline; Write-Host "Host is running on battery (shows charge %)."
        
        Write-Host "`nTIPS:" -ForegroundColor White
        Write-Host "  To toggle Classic Icon mode, use the -classic or --classic option in settings.json configuration."
        Write-Host "  To toggle Context Gauge bar, use the --context-gauge / --no-context-gauge option (default: off)."
        Write-Host "  To toggle Quota Gauge bar, use the --quota-gauge / --no-quota-gauge option (default: off)."
        exit
    }
}

# Read JSON input from stdin
$inputJson = $input | Out-String
if (-not $inputJson -or $inputJson.Trim().Length -eq 0) {
    # If no stdin, output nothing and exit
    exit
}

# Parse JSON safely
try {
    $data = ConvertFrom-Json $inputJson
} catch {
    exit
}

# Extract properties with fallbacks
$STATE = if ($data.agent_state) { $data.agent_state } else { "idle" }
$USED_PCT = if ($data.context_window.used_percentage -ne $null) { $data.context_window.used_percentage } else { 0 }
$VCS_BRANCH = if ($data.vcs.branch) { $data.vcs.branch } else { "" }
$VCS_DIRTY = if ($data.vcs.dirty -ne $null) { $data.vcs.dirty } else { $false }
$VCS_TYPE = if ($data.vcs.type) { $data.vcs.type } else { "" }
$SANDBOX = if ($data.sandbox.enabled -ne $null) { $data.sandbox.enabled } else { $false }
$SANDBOX_NET = if ($data.sandbox.allow_network -ne $null) { $data.sandbox.allow_network } else { $false }
$ARTIFACTS = if ($data.artifact_count -ne $null) { $data.artifact_count } else { 0 }
$SUBAGENTS = if ($data.subagents -and $data.subagents.GetType().IsArray) { $data.subagents.Length } else { 0 }
$BG_TASKS = if ($data.task_count -ne $null) { $data.task_count } else { 0 }
$MODEL_ID = if ($data.model.id) { $data.model.id } else { "" }
$MODEL_NAME = if ($data.model.display_name) { $data.model.display_name } else { "" }
$COLS = if ($data.terminal_width -ne $null) { $data.terminal_width } else { 80 }
$CWD = if ($data.cwd) { $data.cwd } else { "" }
$CONV_ID = if ($data.conversation_id) { $data.conversation_id } else { "" }
$CLI_VERSION = if ($data.version) { $data.version } else { "" }
$PLAN_TIER = if ($data.plan_tier) { ($data.plan_tier -replace '(?i)\b(Antigravity|Quota)\b', '').Trim() -replace '\s+', ' ' } else { "" }
$USER_EMAIL = if ($data.email) { $data.email } else { "" }
$TURN_INPUT_TOKENS = if ($data.context_window.current_usage.input_tokens -ne $null) { $data.context_window.current_usage.input_tokens } else { 0 }
$TURN_OUTPUT_TOKENS = if ($data.context_window.current_usage.output_tokens -ne $null) { $data.context_window.current_usage.output_tokens } else { 0 }

$INPUT_TOKENS = if ($data.context_window.total_input_tokens -ne $null) { $data.context_window.total_input_tokens } else { 0 }
$OUTPUT_TOKENS = if ($data.context_window.total_output_tokens -ne $null) { $data.context_window.total_output_tokens } else { 0 }
$CTX_LIMIT = if ($data.context_window.context_window_size -ne $null) { $data.context_window.context_window_size } else { 0 }
$CTX_USED = $INPUT_TOKENS + $OUTPUT_TOKENS
$REM_PCT = if ($data.context_window.remaining_percentage -ne $null) { $data.context_window.remaining_percentage } else { 100 }

# Quotas
function extract_reset_sec($q_obj) {
    if ($null -eq $q_obj) { return -1 }
    foreach ($k in @("reset_in_seconds", "reset_seconds")) {
        $v = $q_obj.$k
        if ($null -ne $v) {
            try { return [int]$v } catch {}
        }
    }
    foreach ($k in @("reset_time", "reset_at", "resetTime", "resetAt")) {
        $v = $q_obj.$k
        if ($null -ne $v) {
            if ($v -is [int] -or $v -is [long] -or $v -is [double]) {
                $now_sec = [DateTimeOffset]::UtcNow.ToUnixTimeSeconds()
                $diff = [int]([double]$v - $now_sec)
                return [Math]::Max(0, $diff)
            }
            # ConvertFrom-Json auto-converts ISO8601 strings to [DateTime]
            if ($v -is [datetime]) {
                $diff = [int]([DateTimeOffset]$v).ToUnixTimeSeconds() - [int][DateTimeOffset]::UtcNow.ToUnixTimeSeconds()
                return [Math]::Max(0, $diff)
            }
            if ($v -is [string] -and $v.Length -gt 0) {
                try {
                    $dt = [DateTimeOffset]::Parse($v, [System.Globalization.CultureInfo]::InvariantCulture)
                    $diff = [int]($dt.ToUnixTimeSeconds() - [DateTimeOffset]::UtcNow.ToUnixTimeSeconds())
                    return [Math]::Max(0, $diff)
                } catch {}
            }
        }
    }
    return -1
}

$GEMINI_5H = if ($data.quota.'gemini-5h'.remaining_fraction -ne $null) { [Math]::Round($data.quota.'gemini-5h'.remaining_fraction * 100, 1) } else { -1 }
$GEMINI_WK = if ($data.quota.'gemini-weekly'.remaining_fraction -ne $null) { [Math]::Round($data.quota.'gemini-weekly'.remaining_fraction * 100, 1) } else { -1 }
$TP_5H = if ($data.quota.'3p-5h'.remaining_fraction -ne $null) { [Math]::Round($data.quota.'3p-5h'.remaining_fraction * 100, 1) } else { -1 }
$TP_WK = if ($data.quota.'3p-weekly'.remaining_fraction -ne $null) { [Math]::Round($data.quota.'3p-weekly'.remaining_fraction * 100, 1) } else { -1 }

$GEMINI_5H_RESET = extract_reset_sec $data.quota.'gemini-5h'
$GEMINI_WK_RESET = extract_reset_sec $data.quota.'gemini-weekly'
$TP_5H_RESET = extract_reset_sec $data.quota.'3p-5h'
$TP_WK_RESET = extract_reset_sec $data.quota.'3p-weekly'

# Gemini Quota Cache Lookup (2-minute TTL)
$GEMINI_QUOTA_CACHE_TTL = 120 # 2 minutes (between 1 and 3 minutes)

function Get-AgyAccessToken {
    $candidates = @()
    if ($env:AGY_CONFIG_DIR) {
        $candidates += (Join-Path $env:AGY_CONFIG_DIR "antigravity-oauth-token")
    }
    $userHome = [Environment]::GetFolderPath("UserProfile")
    if (-not $userHome) { $userHome = $HOME }
    $candidates += (Join-Path $userHome ".gemini\antigravity-cli\antigravity-oauth-token")
    $candidates += (Join-Path $userHome ".antigravity\antigravity-oauth-token")

    $raw = $null
    foreach ($p in $candidates) {
        if (Test-Path $p) {
            try {
                $raw = (Get-Content -Path $p -Raw -ErrorAction Stop).Trim()
                if ($raw) { break }
            } catch {}
        }
    }

    # Fallback: Windows Credential Manager (go-keyring stores target "gemini:antigravity")
    if (-not $raw) {
        try {
            if (-not ([System.Management.Automation.PSTypeName]'AgyWinCred').Type) {
                Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;
using System.Text;

public class AgyWinCred {
    [StructLayout(LayoutKind.Sequential, CharSet = CharSet.Unicode)]
    private struct CREDENTIAL {
        public uint Flags;
        public uint Type;
        public string TargetName;
        public string Comment;
        public System.Runtime.InteropServices.ComTypes.FILETIME LastWritten;
        public uint CredentialBlobSize;
        public IntPtr CredentialBlob;
        public uint Persist;
        public uint AttributeCount;
        public IntPtr Attributes;
        public string TargetAlias;
        public string UserName;
    }

    [DllImport("advapi32.dll", SetLastError = true, CharSet = CharSet.Unicode)]
    private static extern bool CredReadW(string target, uint type, int reservedFlag, out IntPtr credentialPtr);

    [DllImport("advapi32.dll", SetLastError = true)]
    private static extern void CredFree(IntPtr cred);

    public static string GetPassword(string target) {
        IntPtr credPtr;
        if (!CredReadW(target, 1, 0, out credPtr)) return null;
        try {
            CREDENTIAL cred = (CREDENTIAL)Marshal.PtrToStructure(credPtr, typeof(CREDENTIAL));
            if (cred.CredentialBlob == IntPtr.Zero || cred.CredentialBlobSize == 0) return null;
            byte[] bytes = new byte[cred.CredentialBlobSize];
            Marshal.Copy(cred.CredentialBlob, bytes, 0, (int)cred.CredentialBlobSize);
            string utf8 = Encoding.UTF8.GetString(bytes);
            if (utf8.Contains("access_token")) return utf8;
            return Encoding.Unicode.GetString(bytes);
        } finally {
            CredFree(credPtr);
        }
    }
}
"@ -ErrorAction SilentlyContinue
            }
            foreach ($target in @("gemini:antigravity", "antigravity-oauth-token")) {
                $credVal = [AgyWinCred]::GetPassword($target)
                if ($credVal) {
                    $raw = $credVal.Trim()
                    break
                }
            }
        } catch {}
    }

    if (-not $raw) { return $null }

    if ($raw.StartsWith("go-keyring-base64:")) {
        try {
            $b64 = $raw.Substring("go-keyring-base64:".Length)
            $raw = [System.Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($b64))
        } catch { return $null }
    }

    try {
        $tok = $raw | ConvertFrom-Json -ErrorAction Stop
        if ($tok.access_token) { return [string]$tok.access_token }
    } catch {}
    return $null
}

function Get-CachedGeminiQuota($modelName) {
    $userHome = [Environment]::GetFolderPath("UserProfile")
    if (-not $userHome) { $userHome = $HOME }
    $cacheDir = if ($env:AGY_CONFIG_DIR) { Join-Path $env:AGY_CONFIG_DIR "cache" } else { Join-Path $userHome ".gemini\antigravity-cli\cache" }
    $cacheFile = Join-Path $cacheDir "gemini_quota_cache.json"
    $now = [DateTimeOffset]::UtcNow.ToUnixTimeSeconds()

    $cacheData = $null
    if (Test-Path $cacheFile) {
        try {
            $cacheData = Get-Content -Path $cacheFile -Raw -ErrorAction Stop | ConvertFrom-Json -ErrorAction Stop
        } catch { $cacheData = $null }
    }

    $needFetch = $true
    if ($null -ne $cacheData -and $null -ne $cacheData.fetched_at) {
        if (($now - [long]$cacheData.fetched_at) -lt $GEMINI_QUOTA_CACHE_TTL) {
            $needFetch = $false
        }
    }

    if ($needFetch) {
        $token = Get-AgyAccessToken
        if ($token) {
            try {
                if (-not (Test-Path $cacheDir)) {
                    New-Item -ItemType Directory -Path $cacheDir -Force | Out-Null
                }
            } catch {
                $cacheFile = Join-Path $env:TEMP "agy_gemini_quota_cache.json"
            }

            try {
                $headers = @{
                    "Authorization" = "Bearer $token"
                    "Content-Type"  = "application/json"
                    "User-Agent"    = "antigravity/1.4.5 windows/amd64"
                }
                $resp = Invoke-RestMethod -Uri "https://daily-cloudcode-pa.googleapis.com/v1internal:fetchAvailableModels" -Method Post -Headers $headers -Body "{}" -TimeoutSec 2 -ErrorAction Stop
                if ($null -ne $resp -and $null -ne $resp.models) {
                    $modelsQuota = @{}
                    foreach ($prop in $resp.models.PSObject.Properties) {
                        $mKey = $prop.Name
                        $mVal = $prop.Value
                        if ($null -ne $mVal -and $null -ne $mVal.quotaInfo) {
                            $qInfo = $mVal.quotaInfo
                            if ($null -ne $qInfo.remainingFraction) {
                                $modelsQuota[$mKey] = @{
                                    remaining_fraction = [double]$qInfo.remainingFraction
                                    reset_time         = [string]$qInfo.resetTime
                                }
                            }
                        }
                    }
                    $cacheObj = @{
                        fetched_at = $now
                        models     = $modelsQuota
                    }
                    try {
                        $tmpFile = "$cacheFile.tmp"
                        $cacheObj | ConvertTo-Json -Depth 5 -Compress | Set-Content -Path $tmpFile -Encoding UTF8 -ErrorAction Stop
                        Move-Item -Path $tmpFile -Destination $cacheFile -Force -ErrorAction Stop
                    } catch {}
                    $cacheData = $cacheObj | ConvertTo-Json -Depth 5 | ConvertFrom-Json
                }
            } catch {}
        }
    }

    if ($null -eq $cacheData -or $null -eq $cacheData.models) { return $null }

    $mLow = if ($modelName) { $modelName.ToLower() } else { "" }
    $targetInfo = $null

    if ($mLow -and $null -ne $cacheData.models.$mLow) {
        $targetInfo = $cacheData.models.$mLow
    } else {
        $pref = if ($mLow -match "flash") { "gemini-3-flash" } elseif ($mLow -match "pro") { "gemini-3.1-pro-high" } else { "gemini-3.1-pro-high" }
        if ($null -ne $cacheData.models.$pref) {
            $targetInfo = $cacheData.models.$pref
        } else {
            foreach ($prop in $cacheData.models.PSObject.Properties) {
                if ($prop.Name -like "gemini-*") {
                    $targetInfo = $prop.Value
                    break
                }
            }
        }
    }

    if ($null -eq $targetInfo -or $null -eq $targetInfo.remaining_fraction) { return $null }
    $remPct = [Math]::Round([double]$targetInfo.remaining_fraction * 100, 1)
    $rstSec = extract_reset_sec $targetInfo
    return @($remPct, $rstSec)
}

# Gemini 4 Argon has its own quota group (independent from Gemini / Claude+GPT groups)
function Get-ArgonQuota {
    $userHome = [Environment]::GetFolderPath("UserProfile")
    if (-not $userHome) { $userHome = $HOME }
    $cacheDir = if ($env:AGY_CONFIG_DIR) { Join-Path $env:AGY_CONFIG_DIR "cache" } else { Join-Path $userHome ".gemini\antigravity-cli\cache" }
    $cacheFile = Join-Path $cacheDir "argon_quota_cache.json"
    $now = [DateTimeOffset]::UtcNow.ToUnixTimeSeconds()

    $cacheData = $null
    if (Test-Path $cacheFile) {
        try {
            $cacheData = Get-Content -Path $cacheFile -Raw -ErrorAction Stop | ConvertFrom-Json -ErrorAction Stop
        } catch { $cacheData = $null }
    }

    if ($null -ne $cacheData -and $null -ne $cacheData.fetched_at -and $null -ne $cacheData.buckets) {
        if (($now - [long]$cacheData.fetched_at) -lt $GEMINI_QUOTA_CACHE_TTL) {
            return $cacheData.buckets
        }
    }

    $token = Get-AgyAccessToken
    if ($token) {
        try {
            $headers = @{
                "Authorization" = "Bearer $token"
                "Content-Type"  = "application/json"
                "User-Agent"    = "antigravity/1.4.5 windows/amd64"
            }
            $resp = Invoke-RestMethod -Uri "https://daily-cloudcode-pa.googleapis.com/v1internal:retrieveUserQuotaSummary" -Method Post -Headers $headers -Body "{}" -TimeoutSec 2 -ErrorAction Stop
            $found = @{}
            foreach ($grp in @($resp.groups)) {
                if ($null -eq $grp) { continue }
                $grpSig = "$($grp.displayName) $($grp.description)"
                foreach ($bk in @($grp.buckets)) {
                    if ($null -eq $bk -or $null -eq $bk.remainingFraction) { continue }
                    if (("$($bk.bucketId) $grpSig").ToLower() -notmatch "argon") { continue }
                    $win = if ($bk.window) { "$($bk.window)" } else { "$($bk.bucketId)" }
                    $win = $win.ToLower()
                    $key = if ($win -match "week") { "weekly" } elseif ($win -match "5h|five") { "5h" } else { $null }
                    if ($key) {
                        $found[$key] = @{
                            remaining_fraction = [double]$bk.remainingFraction
                            reset_time         = [string]$bk.resetTime
                        }
                    }
                }
            }
            if ($found.Count -gt 0) {
                try {
                    if (-not (Test-Path $cacheDir)) { New-Item -ItemType Directory -Path $cacheDir -Force | Out-Null }
                    $tmpFile = "$cacheFile.tmp"
                    @{ fetched_at = $now; buckets = $found } | ConvertTo-Json -Depth 5 -Compress | Set-Content -Path $tmpFile -Encoding UTF8 -ErrorAction Stop
                    Move-Item -Path $tmpFile -Destination $cacheFile -Force -ErrorAction Stop
                } catch {}
                return ($found | ConvertTo-Json -Depth 5 | ConvertFrom-Json)
            }
        } catch {}
    }

    # Fall back to stale cache while its reset time has not passed yet
    if ($null -ne $cacheData -and $null -ne $cacheData.buckets) {
        foreach ($prop in $cacheData.buckets.PSObject.Properties) {
            if ((extract_reset_sec $prop.Value) -gt 0) { return $cacheData.buckets }
        }
    }
    return $null
}

# ANSI Helpers
$ESC = [char]27
$R = "$ESC[0m"
$B = "$ESC[1m"
$D = "$ESC[2m"
$I = "$ESC[3m"

$FG_BLACK = "$ESC[30m"
$FG_RED = "$ESC[31m"
$FG_GREEN = "$ESC[32m"
$FG_YELLOW = "$ESC[33m"
$FG_BLUE = "$ESC[34m"
$FG_MAGENTA = "$ESC[35m"
$FG_CYAN = "$ESC[36m"
$FG_WHITE = "$ESC[37m"

$FG_GRAY = "$ESC[90m"
$FG_BRIGHT_RED = "$ESC[91m"
$FG_BRIGHT_GREEN = "$ESC[92m"
$FG_BRIGHT_YELLOW = "$ESC[93m"
$FG_BRIGHT_BLUE = "$ESC[94m"
$FG_BRIGHT_MAGENTA = "$ESC[95m"
$FG_BRIGHT_CYAN = "$ESC[96m"
$FG_BRIGHT_WHITE = "$ESC[97m"

$NUM_COLOR = "${FG_BRIGHT_WHITE}${B}"
$DOT = "${FG_GRAY} | ${R}"

# Timeout Process Helper
function Run-WithTimeout {
    param(
        [string]$Command,
        [string[]]$Arguments,
        [int]$TimeoutMs = 1000
    )
    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName = $Command
    $psi.Arguments = $Arguments -join " "
    $psi.RedirectStandardOutput = $true
    $psi.RedirectStandardError = $true
    $psi.UseShellExecute = $false
    $psi.CreateNoWindow = $true

    $proc = New-Object System.Diagnostics.Process
    $proc.StartInfo = $psi

    try {
        if ($proc.Start()) {
            if ($proc.WaitForExit($TimeoutMs)) {
                return $proc.StandardOutput.ReadToEnd()
            } else {
                $proc.Kill()
            }
        }
    } catch {}
    return $null
}

# VCS directly from git (Bypasses JSON caches)
$GIT_DIR = if ($CWD) { $CWD } else { "." }
if (Test-Path "$GIT_DIR") {
    $gitBranch = Run-WithTimeout -Command "git" -Arguments @("-C", "`"$GIT_DIR`"", "rev-parse", "--abbrev-ref", "HEAD")
    if ($gitBranch) {
        $VCS_BRANCH = $gitBranch.Trim()
        $VCS_TYPE = "git"
        $status = Run-WithTimeout -Command "git" -Arguments @("-C", "`"$GIT_DIR`"", "status", "--porcelain")
        if ($status) {
            $VCS_DIRTY = $true
        } else {
            $VCS_DIRTY = $false
        }
    }
}

# Format percentages
$PCT_FMT = $USED_PCT.ToString("0.0", [System.Globalization.CultureInfo]::InvariantCulture)
$PCT_INT = [int][Math]::Floor($USED_PCT)

# Formatting helpers
function human_format($num) {
    if ($num -eq $null -or $num -eq 0) { return "0" }
    if ($num -ge 1000000) {
        $val = [Math]::Round($num / 1000000, 1)
        return $val.ToString("0.0", [System.Globalization.CultureInfo]::InvariantCulture) + "M"
    }
    if ($num -ge 1000) {
        $val = [Math]::Round($num / 1000, 1)
        return $val.ToString("0.0", [System.Globalization.CultureInfo]::InvariantCulture) + "K"
    }
    return $num.ToString()
}

$INPUT_TOK_FMT = human_format $INPUT_TOKENS
$OUTPUT_TOK_FMT = human_format $OUTPUT_TOKENS
$CTX_LIMIT_FMT = human_format $CTX_LIMIT
$CTX_USED_FMT = human_format $CTX_USED
$TURN_INPUT_FMT = human_format $TURN_INPUT_TOKENS
$TURN_OUTPUT_FMT = human_format $TURN_OUTPUT_TOKENS

function shorten_path($path) {
    if (-not $path) { return "" }
    $homeDir = if ($env:USERPROFILE) { $env:USERPROFILE } else { $env:HOME }
    if ($homeDir -and $path.StartsWith($homeDir)) {
        $path = "~" + $path.Substring($homeDir.Length)
    }
    if ($path.Length -gt 25) {
        return "..." + (Split-Path $path -Leaf)
    }
    return $path
}
$CWD_SHORT = shorten_path $CWD

# ─── Parse CLI Arguments & Theme ─────────────────────────────────────────────
$USE_CLASSIC_ICONS = $false
$SHOW_CONTEXT_GAUGE = $false
$SHOW_QUOTA_GAUGE = $false
foreach ($arg in $args) {
    if ($arg -eq "--classic" -or $arg -eq "--no-nerdfont" -or $arg -eq "--compatibility") {
        $USE_CLASSIC_ICONS = $true
    } elseif ($arg -eq "--nerdfont" -or $arg -eq "--nerd-font" -or $arg -eq "-nf") {
        $USE_CLASSIC_ICONS = $false
    } elseif ($arg -eq "--context-gauge" -or $arg -eq "--ctx-gauge" -or $arg -eq "--context-bar" -or $arg -eq "--ctx-bar") {
        $SHOW_CONTEXT_GAUGE = $true
    } elseif ($arg -eq "--no-context-gauge" -or $arg -eq "--no-ctx-gauge" -or $arg -eq "--no-context-bar" -or $arg -eq "--no-ctx-bar") {
        $SHOW_CONTEXT_GAUGE = $false
    } elseif ($arg -eq "--quota-gauge" -or $arg -eq "--quota-bar" -or $arg -eq "--gauge") {
        $SHOW_QUOTA_GAUGE = $true
    } elseif ($arg -eq "--no-quota-gauge" -or $arg -eq "--no-quota-bar" -or $arg -eq "--no-gauge") {
        $SHOW_QUOTA_GAUGE = $false
    }
}

if ($USE_CLASSIC_ICONS) {
    $DOT_L1 = "${FG_GRAY} ╱ ${R}"
    $DOT_L2 = "${FG_GRAY} · ${R}"
    $ICON_READY = "●"
    $ICON_THINKING = "◆"
    $ICON_WORKING = "⚙"
    $ICON_TOOL = "🔧"
    $ICON_STATE_UNKNOWN = "⏳"
    $ICON_VCS = "╱"
    $ICON_MODEL = ""
    $ICON_SANDBOX_NET = "ON (net)"
    $ICON_SANDBOX_NONET = "ON (no-net)"
    $ICON_SANDBOX_OFF = "OFF"
    $ICON_CONTEXT_BAR = "ctx"
    $ICON_ARTIFACTS = "artifacts"
    $ICON_SUBAGENTS = "subagents"
    $ICON_TASKS = "tasks"
    $ICON_DIR = "╱"
    $ICON_CONV = "╱"
    $ICON_TOK_SUM = ""
    $ICON_RESET = "⌛"
    $ICON_AC = "AC"
    $ICON_BAT = "BAT"
} else {
    $DOT_L1 = "${FG_GRAY} | ${R}"
    $DOT_L2 = "${FG_GRAY} | ${R}"
    $ICON_READY = ""
    $ICON_THINKING = "󰟷"
    $ICON_WORKING = ""
    $ICON_TOOL = ""
    $ICON_STATE_UNKNOWN = ""
    $ICON_VCS = ""
    $ICON_MODEL = ""
    $ICON_SANDBOX_NET = "󰒙"
    $ICON_SANDBOX_NONET = "󰴴"
    $ICON_SANDBOX_OFF = "󰦜"
    $ICON_CONTEXT_BAR = "󱍏"
    $ICON_ARTIFACTS = ""
    $ICON_SUBAGENTS = "󱙺"
    $ICON_TASKS = ""
    $ICON_DIR = ""
    $ICON_CONV = "󰍪"
    $ICON_TOK_SUM = ""
    $ICON_RESET = "⌛️"
    $ICON_AC = "󰚥"
    $ICON_BAT = "🔋"
}

function visible_len($str) {
    # Strips ESC sequences and counts visible length
    $stripped = $str -replace '\x1b\[[0-9;]*m', ''
    return $stripped.Length
}

$CLI_VER_FMT = ""
if ($CLI_VERSION) {
    $CLI_VER_FMT = "${DOT_L1}${FG_GRAY}v${CLI_VERSION}${R}"
}

$USER_FMT = ""
if ($USER_EMAIL) {
    $userInfo = $USER_EMAIL
    # Truncate if too long
    if ($userInfo.Length -gt 35) {
        $userInfo = $userInfo.Substring(0, 32) + "..."
    }
    if ($USE_CLASSIC_ICONS) {
        $USER_FMT = "${DOT_L1}${FG_GRAY}${userInfo}${R}"
    } else {
        $USER_FMT = "${DOT_L1}${FG_GRAY}󰇮 ${userInfo}${R}"
    }
}

# Get hostname and Tailscale IP
$HOST_NAME = ""
try { $HOST_NAME = [System.Net.Dns]::GetHostName() } catch {}
$TS_IP = ""
try {
    if (Get-Command tailscale -ErrorAction SilentlyContinue) {
        $tsStatus = tailscale ip -4 2>$null
        if ($tsStatus) { $TS_IP = $tsStatus.Trim() }
    }
} catch {}

$HOST_FMT = ""
if ($HOST_NAME) {
    $hostDetails = $HOST_NAME
    if ($TS_IP) {
        $hostDetails = "${HOST_NAME} (${TS_IP})"
    }
    if ($USE_CLASSIC_ICONS) {
        $HOST_FMT = "${DOT_L1}${FG_BRIGHT_BLUE}${hostDetails}${R}"
    } else {
        $HOST_FMT = "${DOT_L1}${FG_BRIGHT_BLUE}󰒋 ${hostDetails}${R}"
    }
}

# Get Power Status
$POWER_FMT = ""
try {
    $battery = Get-CimInstance -ClassName Win32_Battery -ErrorAction SilentlyContinue
    if ($battery) {
        $status = $battery.BatteryStatus
        $cap = $battery.EstimatedChargeRemaining
        # BatteryStatus 1 = Discharging (on battery)
        if ($status -eq 1) {
            if ($USE_CLASSIC_ICONS) {
                $POWER_FMT = "${DOT_L2}${FG_BRIGHT_YELLOW}${ICON_BAT}:${cap}%${R}"
            } else {
                $POWER_FMT = "${DOT_L2}${FG_BRIGHT_YELLOW}${ICON_BAT} ${cap}%${R}"
            }
        } else {
            if ($USE_CLASSIC_ICONS) {
                $POWER_FMT = "${DOT_L2}${FG_GREEN}${ICON_AC}${R}"
            } else {
                $POWER_FMT = "${DOT_L2}${FG_GREEN}${ICON_AC} AC${R}"
            }
        }
    }
} catch {}

# State Indicator
$S = ""
switch ($STATE) {
    "idle"     { $S = "${FG_BRIGHT_GREEN}${B} ${ICON_READY} READY${R}" }
    "thinking" { $S = "${FG_BRIGHT_YELLOW}${B} ${ICON_THINKING} THINKING${R}" }
    "working"  { $S = "${FG_BRIGHT_CYAN}${B} ${ICON_WORKING} WORKING${R}" }
    "tool_use" { $S = "${FG_BRIGHT_MAGENTA}${B} ${ICON_TOOL} TOOL${R}" }
    default    { $S = "${FG_WHITE}${B} ${ICON_STATE_UNKNOWN} $($STATE.ToUpper())${R}" }
}

# VCS branch details
$V = ""
if ($VCS_BRANCH) {
    if ($VCS_DIRTY -eq $true) {
        if ($USE_CLASSIC_ICONS) {
            $V = "${DOT_L1}${FG_BRIGHT_RED}${VCS_BRANCH}${FG_BRIGHT_YELLOW}*${R}"
        } else {
            $V = "${DOT_L1}${R}${FG_BRIGHT_RED}${ICON_VCS} ${VCS_BRANCH}${FG_BRIGHT_YELLOW}*${R}"
        }
    } else {
        if ($USE_CLASSIC_ICONS) {
            $V = "${DOT_L1}${FG_BRIGHT_BLUE}${VCS_BRANCH}${R}"
        } else {
            $V = "${DOT_L1}${R}${FG_BRIGHT_BLUE}${ICON_VCS} ${VCS_BRANCH}${R}"
        }
    }
}

# Model details
$disp = if ($MODEL_NAME) { $MODEL_NAME } else { $MODEL_ID }
$M = ""
if ($disp) {
    if ($USE_CLASSIC_ICONS) {
        $M = "${DOT_L1}${FG_BRIGHT_MAGENTA}${I}${disp}${R}"
    } else {
        $M = "${DOT_L1}${FG_BRIGHT_MAGENTA}${I}${ICON_MODEL} ${disp}${R}"
    }
}

# Sandbox Badge
$SB = ""
if ($SANDBOX -eq $true) {
    if ($SANDBOX_NET -eq $true) {
        $SB = "${FG_GREEN}${ICON_SANDBOX_NET} ON (net)${R}"
    } else {
        $SB = "${FG_GREEN}${ICON_SANDBOX_NONET} ON (no-net)${R}"
    }
} else {
    if ($USE_CLASSIC_ICONS) {
        $SB = "${FG_GRAY}sandbox off${R}"
    } else {
        $SB = "${FG_RED}${ICON_SANDBOX_OFF} OFF${R}"
    }
}

# Context bar
$BAR_LEN = 5
$FILL_COLOR = $FG_YELLOW
if ($PCT_INT -ge 90) { $FILL_COLOR = $FG_BRIGHT_RED }
elseif ($PCT_INT -ge 60) { $FILL_COLOR = $FG_BRIGHT_YELLOW }

$bar_str = ""
if ($SHOW_CONTEXT_GAUGE) {
    $FILLED = [int][Math]::Floor(($PCT_INT * $BAR_LEN) / 100)
    $REMAINDER = ($PCT_INT * $BAR_LEN) % 100
    if ($USE_CLASSIC_ICONS) {
        $BAR = ""
        for ($i = 0; $i -lt $BAR_LEN; $i++) {
            if ($i -lt $FILLED) {
                $BAR += "█"
            } elseif ($i -eq $FILLED) {
                if ($REMAINDER -ge 75) { $BAR += "▓" }
                elseif ($REMAINDER -ge 50) { $BAR += "▒" }
                elseif ($REMAINDER -ge 25) { $BAR += "░" }
                else { $BAR += "·" }
            } else {
                $BAR += "·"
            }
        }
        $bar_str = "${FILL_COLOR}${BAR} "
    } else {
        $BAR = ""
        for ($i = 0; $i -lt $BAR_LEN; $i++) {
            if ($i -lt $FILLED) {
                $BAR += "${FILL_COLOR}█${R}"
            } elseif ($i -eq $FILLED) {
                if ($REMAINDER -ge 75) { $BAR += "${FILL_COLOR}▓${R}${FG_GRAY}" }
                elseif ($REMAINDER -ge 50) { $BAR += "${FILL_COLOR}▒${R}${FG_GRAY}" }
                else { $BAR += "${FILL_COLOR}░${R}${FG_GRAY}" }
            } else {
                $BAR += "${FG_GRAY}░${R}"
            }
        }
        $bar_str = "${BAR} "
    }
}

if ($USE_CLASSIC_ICONS) {
    $CTX_BAR = "${FG_GRAY}ctx ${bar_str}${NUM_COLOR}${PCT_FMT}%${R}"
} else {
    $CTX_BAR = "${FG_YELLOW}${ICON_CONTEXT_BAR} ${bar_str}${NUM_COLOR}${PCT_FMT}%${R}"
}

# Stats badges
if ($USE_CLASSIC_ICONS) {
    $ART_FMT = "${FG_GRAY}artifacts ${NUM_COLOR}${ARTIFACTS}${R}"
    $SUB_FMT = "${FG_GRAY}subagents ${NUM_COLOR}${SUBAGENTS}${R}"
    $BG_FMT = "${FG_GRAY}tasks ${NUM_COLOR}${BG_TASKS}${R}"
} else {
    $ART_FMT = "${FG_BLUE}${ICON_ARTIFACTS} ${NUM_COLOR}${ARTIFACTS}${R}"
    $SUB_FMT = "${FG_CYAN}${ICON_SUBAGENTS} ${NUM_COLOR}${SUBAGENTS}${R}"
    $BG_FMT = "${FG_MAGENTA}${ICON_TASKS} ${NUM_COLOR}${BG_TASKS}${R}"
}

$DIR_FMT = ""
if ($CWD_SHORT) {
    if ($USE_CLASSIC_ICONS) {
        $DIR_FMT = "${DOT_L1}${FG_CYAN}${CWD_SHORT}${R}"
    } else {
        $DIR_FMT = "${DOT_L1}${FG_CYAN}${ICON_DIR} ${CWD_SHORT}${R}"
    }
}

$CONV_FMT = ""
if ($CONV_ID) {
    $short_conv = $CONV_ID.Substring(0, [Math]::Min(8, $CONV_ID.Length))
    if ($USE_CLASSIC_ICONS) {
        $CONV_FMT = "${DOT_L1}${FG_GRAY}${short_conv}${R}"
    } else {
        $CONV_FMT = "${DOT_L1}${FG_GRAY}${ICON_CONV} ${short_conv}${R}"
    }
}

$TOK_DETAILS_WIDE = ""
$TOK_DETAILS_MED = ""
if ($CTX_USED -gt 0) {
    $turnStr = ""
    if ($TURN_INPUT_TOKENS -gt 0 -or $TURN_OUTPUT_TOKENS -gt 0) {
        $turnStr = " | turn: +${TURN_INPUT_FMT}/${TURN_OUTPUT_FMT}"
    }
    if ($USE_CLASSIC_ICONS) {
        $TOK_DETAILS_WIDE = " (${CTX_USED_FMT}/${CTX_LIMIT_FMT})${DOT_L2}(total: ${INPUT_TOK_FMT}/${OUTPUT_TOK_FMT}${turnStr})"
        $TOK_DETAILS_MED = " (${CTX_USED_FMT}/${CTX_LIMIT_FMT})"
    } else {
        $TOK_DETAILS_WIDE = " (${CTX_USED_FMT}/${CTX_LIMIT_FMT})${DOT_L2}${FG_YELLOW}${ICON_TOK_SUM} ${R} (total: ${INPUT_TOK_FMT}/${OUTPUT_TOK_FMT}${turnStr})"
        $TOK_DETAILS_MED = " (${CTX_USED_FMT}/${CTX_LIMIT_FMT})"
    }
}

# Quota bars
function format_reset_time($sec) {
    if ($sec -eq $null -or $sec -le 0) { return "" }
    $days = [int][Math]::Floor($sec / 86400)
    $rem = $sec % 86400
    $hours = [int][Math]::Floor($rem / 3600)
    $rem = $rem % 3600
    $mins = [int][Math]::Floor($rem / 60)

    if ($days -gt 0) {
        if ($hours -gt 0) { return "${days}d ${hours}h" }
        return "${days}d"
    }
    if ($hours -gt 0) {
        if ($mins -gt 0) { return "${hours}h ${mins}m" }
        return "${hours}h"
    }
    if ($mins -gt 0) { return "${mins}m" }
    return "<1m"
}

function make_quota_bar($val, $label, $bar_color, $reset_sec, $show_bar = $SHOW_QUOTA_GAUGE) {
    $reset_label = " ${ICON_RESET} "
    $separator = $DOT_L2

    $bar_len = 5

    if ($val -eq $null -or $val -lt 0) {
        if ($show_bar) {
            $bar = ""
            for ($i = 0; $i -lt $bar_len; $i++) {
                if ($USE_CLASSIC_ICONS) { $bar += "·" } else { $bar += "░" }
            }
            return "${separator}${FG_BRIGHT_WHITE}${B}${label}${R} ${FG_GRAY}${bar} N/A${R}"
        } else {
            return "${separator}${FG_BRIGHT_WHITE}${B}${label}${R} ${FG_GRAY}N/A${R}"
        }
    }

    $val_int = [int][Math]::Floor($val)
    $text_color = $FG_BRIGHT_GREEN
    if ($val_int -lt 20) { $text_color = $FG_BRIGHT_RED }
    elseif ($val_int -lt 50) { $text_color = $FG_BRIGHT_YELLOW }

    $bar_str = ""
    if ($show_bar) {
        $filled = [int][Math]::Floor(($val_int * $bar_len) / 100)
        $remainder = ($val_int * $bar_len) % 100

        $bar = ""
        for ($i = 0; $i -lt $bar_len; $i++) {
            if ($i -lt $filled) {
                if ($USE_CLASSIC_ICONS) {
                    $bar += "█"
                } else {
                    $bar += "${bar_color}█${R}"
                }
            } elseif ($i -eq $filled) {
                if ($USE_CLASSIC_ICONS) {
                    if ($remainder -ge 75) { $bar += "▓" }
                    elseif ($remainder -ge 50) { $bar += "▒" }
                    elseif ($remainder -ge 25) { $bar += "░" }
                    else { $bar += "·" }
                } else {
                    if ($remainder -ge 75) { $bar += "${bar_color}▓${R}${FG_GRAY}" }
                    elseif ($remainder -ge 50) { $bar += "${bar_color}▒${R}${FG_GRAY}" }
                    elseif ($remainder -ge 25) { $bar += "${bar_color}░${R}${FG_GRAY}" }
                    else { $bar += "${FG_GRAY}░${R}" }
                }
            } else {
                if ($USE_CLASSIC_ICONS) {
                    $bar += "·"
                } else {
                    $bar += "${FG_GRAY}░${R}"
                }
            }
        }
        if ($USE_CLASSIC_ICONS) {
            $bar_str = "${bar_color}${bar}${R} "
        } else {
            $bar_str = "${bar} "
        }
    }

    $reset_str = ""
    $t = format_reset_time $reset_sec
    if ($t) { $reset_str = "${reset_label}${t}" }

    $val_fmt = $val.ToString("0.0", [System.Globalization.CultureInfo]::InvariantCulture)
    return "${separator}${FG_BRIGHT_WHITE}${B}${label}${R} ${bar_str}${text_color}${val_fmt}%${R}${reset_str}"
}

# Determine active quota based on current model first, then fallback to available data
$modelCheck = "$MODEL_ID $MODEL_NAME".ToLower()
$isArgonModel = $modelCheck -match "argon"
$isGeminiModel = ($modelCheck -match "gemini") -and (-not $isArgonModel)
$is3pModel = $modelCheck -match "claude|gpt|o1|o3|sonnet|opus|haiku"

$hasGeminiQuota = ($GEMINI_5H -ne $null -and $GEMINI_5H -ne -1) -or ($GEMINI_WK -ne $null -and $GEMINI_WK -ne -1)
$hasTpQuota = ($TP_5H -ne $null -and $TP_5H -ne -1) -or ($TP_WK -ne $null -and $TP_WK -ne -1)

# If using a Gemini model and stdin has no gemini-5h quota, query cached endpoint (TTL 2m)
if ($isGeminiModel -and -not $hasGeminiQuota) {
    $targetModel = if ($MODEL_ID) { $MODEL_ID } else { $MODEL_NAME }
    $cachedGem = Get-CachedGeminiQuota $targetModel
    if ($null -ne $cachedGem) {
        $GEMINI_5H = $cachedGem[0]
        $GEMINI_5H_RESET = $cachedGem[1]
        $hasGeminiQuota = $true
    }
}

# Argon: prefer stdin quota entries whose key contains "argon", then query the API
$ARGON_5H = -1; $ARGON_WK = -1; $ARGON_5H_RESET = -1; $ARGON_WK_RESET = -1
if ($isArgonModel) {
    if ($null -ne $data.quota) {
        foreach ($qp in $data.quota.PSObject.Properties) {
            $ql = $qp.Name.ToLower()
            if ($ql -notmatch "argon" -or $null -eq $qp.Value -or $null -eq $qp.Value.remaining_fraction) { continue }
            if ($ql -match "week|7d") {
                $ARGON_WK = [Math]::Round($qp.Value.remaining_fraction * 100, 1)
                $ARGON_WK_RESET = extract_reset_sec $qp.Value
            } elseif ($ql -match "5h|five") {
                $ARGON_5H = [Math]::Round($qp.Value.remaining_fraction * 100, 1)
                $ARGON_5H_RESET = extract_reset_sec $qp.Value
            }
        }
    }
    if ($ARGON_5H -eq -1 -and $ARGON_WK -eq -1) {
        $aq = Get-ArgonQuota
        if ($null -ne $aq) {
            if ($null -ne $aq.weekly -and $null -ne $aq.weekly.remaining_fraction) {
                $ARGON_WK = [Math]::Round([double]$aq.weekly.remaining_fraction * 100, 1)
                $ARGON_WK_RESET = extract_reset_sec $aq.weekly
            }
            if ($null -ne $aq.'5h' -and $null -ne $aq.'5h'.remaining_fraction) {
                $ARGON_5H = [Math]::Round([double]$aq.'5h'.remaining_fraction * 100, 1)
                $ARGON_5H_RESET = extract_reset_sec $aq.'5h'
            }
        }
    }
}

if ($isArgonModel) {
    # Never fall back to the shared Gemini/3P quota: Argon has an independent limit
    $Q_5H = $ARGON_5H
    $Q_WK = $ARGON_WK
    $Q_5H_R = $ARGON_5H_RESET
    $Q_WK_R = $ARGON_WK_RESET
} elseif ($isGeminiModel -and $hasGeminiQuota) {
    $Q_5H = $GEMINI_5H
    $Q_WK = if ($GEMINI_WK -ne $null -and $GEMINI_WK -ne -1) { $GEMINI_WK } else { $TP_WK }
    $Q_5H_R = $GEMINI_5H_RESET
    $Q_WK_R = if ($GEMINI_WK -ne $null -and $GEMINI_WK -ne -1) { $GEMINI_WK_RESET } else { $TP_WK_RESET }
} elseif ($is3pModel -and $hasTpQuota) {
    $Q_5H = $TP_5H
    $Q_WK = $TP_WK
    $Q_5H_R = $TP_5H_RESET
    $Q_WK_R = $TP_WK_RESET
} elseif ($hasGeminiQuota) {
    $Q_5H = $GEMINI_5H
    $Q_WK = if ($GEMINI_WK -ne $null -and $GEMINI_WK -ne -1) { $GEMINI_WK } else { $TP_WK }
    $Q_5H_R = $GEMINI_5H_RESET
    $Q_WK_R = if ($GEMINI_WK -ne $null -and $GEMINI_WK -ne -1) { $GEMINI_WK_RESET } else { $TP_WK_RESET }
} elseif ($hasTpQuota) {
    $Q_5H = $TP_5H
    $Q_WK = $TP_WK
    $Q_5H_R = $TP_5H_RESET
    $Q_WK_R = $TP_WK_RESET
} else {
    $Q_5H = -1
    $Q_WK = -1
    $Q_5H_R = -1
    $Q_WK_R = -1
}

$QUOTA_FMT = ""
if (($Q_5H -ne $null -and $Q_5H -ne -1) -or ($Q_WK -ne $null -and $Q_WK -ne -1)) {
    $q5 = if ($Q_5H -ne -1) { make_quota_bar $Q_5H "5H" $FG_BRIGHT_CYAN $Q_5H_R } else { "" }
    $qw = if ($Q_WK -ne -1) { make_quota_bar $Q_WK "7D" $FG_BRIGHT_MAGENTA $Q_WK_R } else { "" }
    $QUOTA_FMT = "${q5}${qw}"
    if ($PLAN_TIER) {
        $QUOTA_FMT += " ${FG_GRAY}(${PLAN_TIER})${R}"
    }
}

# Right-align helper
function print_right_aligned($left, $right, $total_cols) {
    $left_vis = visible_len $left
    $right_vis = visible_len $right
    $pad = $total_cols - $left_vis - $right_vis
    if ($pad -lt 1) { $pad = 1 }
    $spaces = " " * $pad
    return "${left}${spaces}${right}"
}

# Output Assembly based on Column Width
if ($COLS -ge 180) {
    $LINE1 = "${S}${CLI_VER_FMT}${USER_FMT}${HOST_FMT}${M}${DIR_FMT}${V}${CONV_FMT}"
    if ($QUOTA_FMT) {
        $LINE2 = "${BG_FMT}${DOT_L2}${CTX_BAR}${TOK_DETAILS_WIDE}${QUOTA_FMT}${POWER_FMT}"
    } else {
        $LINE2 = "${BG_FMT}${DOT_L2}${CTX_BAR}${TOK_DETAILS_WIDE}${POWER_FMT}"
    }
    print_right_aligned $LINE1 $LINE2 $COLS
} elseif ($COLS -ge 90) {
    $LINE1 = "${S}${CLI_VER_FMT}${USER_FMT}${HOST_FMT}${M}${DIR_FMT}${V}"
    if ($QUOTA_FMT) {
        $LINE2 = " ${CTX_BAR}${TOK_DETAILS_MED}${DOT_L2}${BG_FMT}${QUOTA_FMT}${POWER_FMT}"
    } else {
        $LINE2 = " ${CTX_BAR}${TOK_DETAILS_MED}${DOT_L2}${BG_FMT}${POWER_FMT}"
    }
    "${FG_GRAY}╭─${R}${LINE1}`n${FG_GRAY}╰─${R}${LINE2}"
} else {
    $M_SHORT = ""
    if ($disp) {
        if ($USE_CLASSIC_ICONS) {
            $M_SHORT = "${FG_GRAY} ╱ ${FG_BRIGHT_MAGENTA}$($disp.Substring(0, [Math]::Min(12, $disp.Length)))${R}"
        } else {
            $M_SHORT = "${FG_GRAY} ╱ ${FG_BRIGHT_MAGENTA}${ICON_MODEL} $($disp.Substring(0, [Math]::Min(12, $disp.Length)))${R}"
        }
    }
    if ($QUOTA_FMT) {
        "${S}${M_SHORT}`n${CTX_BAR}${DOT_L2}${BG_FMT}${QUOTA_FMT}${POWER_FMT}"
    } else {
        "${S}${M_SHORT}`n${CTX_BAR}${DOT_L2}${BG_FMT}${POWER_FMT}"
    }
}


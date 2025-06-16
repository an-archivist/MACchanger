<#
.SYNOPSIS
  Spoof Wi-Fi MAC address on Windows, with history logging.

.DESCRIPTION
  - auto-detects Wi-Fi interface if none specified
  - chooses MAC from known list, or random if forced
  - writes new MAC in registry under NetCfgInstanceId
  - disables/enables interface to apply
  - reconnects Wi-Fi profile
  - logs each change; rotates >1000 lines

.PARAMETER Interface
  Name of network adapter (as shown by Get-NetAdapter).

.PARAMETER UseRandom
  Use a random MAC instead of known pool.

.PARAMETER DryRun
  Show actions without applying changes.

.PARAMETER Verbose
  Emit verbose output.

.EXAMPLE
  .\SpoofMac.ps1 --use-random --verbose
#>

param(
  [string]$Interface,
  [switch]$UseRandom,
  [switch]$DryRun,
  [switch]$Verbose,
  [switch]$Help
)

if ($Help) {
  Get-Help -Detailed $MyInvocation.MyCommand.Path
  exit 0
}

# === Config ===
$DEFAULT_INTERFACE = "Wi‑Fi"
$LOG_FILE = Join-Path $HOME ".mac_history.log"
$KNOWN_MACS = @(
  "00:1A:2B:3C:4D:5E",
  "3C:5A:B4:6D:7F:8E",
  "A4:5E:60:2C:7B:10"
)
$RETRY_LIMIT = 3

function Log($level, $msg) {
  if ($level -eq "ERROR") {
    Write-Error "[!] $msg"
  } else {
    Write-Output "[*] $msg"
  }
}

function ErrorExit($msg) {
  Log "ERROR" $msg
  exit 1
}

# Validate adapter cmdlets
if (-not (Get-Command Get-NetAdapter -ErrorAction SilentlyContinue)) {
  ErrorExit "Get-NetAdapter not available; run as Admin."
}

# Detect interface
if (-not $Interface) {
  for ($i = 1; $i -le $RETRY_LIMIT; $i++) {
    $iface = Get-NetAdapter | Where-Object { $_.Status -eq "Up" -and $_.Name -like "*Wi*" } | Select-Object -First 1
    if ($iface) {
      $Interface = $iface.Name
      Log "INFO" "Detected Wi-Fi adapter: $Interface"
      break
    }
    Start-Sleep -Seconds 1
  }
  if (-not $Interface) {
    Log "WARN" "Could not auto-detect Wi-Fi interface."
    $Interface = Read-Host "Enter Wi‑Fi interface name [`$DEFAULT_INTERFACE`]"
    if (-not $Interface) { $Interface = $DEFAULT_INTERFACE }
    Log "INFO" "Using interface '$Interface'"
  }
}

# Validate existence and wireless
$adpt = Get-NetAdapter -Name $Interface -ErrorAction SilentlyContinue
if (-not $adpt) { ErrorExit "Interface '$Interface' not found." }
if ($adpt.MediaType -ne "802.11") {
  ErrorExit "Interface '$Interface' is not wireless (MediaType: $($adpt.MediaType))."
}

# Generate random MAC
function Generate-RandomMAC {
  $bytes = @()
  $bytes += 0x02 # locally administered
  for ($i = 1; $i -lt 6; $i++) {
    $bytes += Get-Random -Minimum 0 -Maximum 256
  }
  ($bytes | ForEach-Object { "{0:X2}" -f $_ }) -join ":"
}

# Choose MAC
function Choose-MAC {
  if ($UseRandom) {
    return Generate-RandomMAC
  } else {
    return $KNOWN_MACS | Get-Random
  }
}

# Read current MAC
$currentMAC = ($adpt.MacAddress)
if (-not $currentMAC) { $currentMAC = "UNKNOWN"; Log "ERROR" "Could not read current MAC." }

if ($currentMAC -notmatch "^([0-9A-F]{2}:){5}[0-9A-F]{2}$") {
  Log "ERROR" "Current MAC '$currentMAC' has invalid format."
}

# If using known and already in pool
if (-not $UseRandom -and $KNOWN_MACS -contains $currentMAC) {
  Log "INFO" "Current MAC '$currentMAC' is in known list; skipping."
  exit 0
}

$newMAC = Choose-MAC

if ($newMAC -match "^$currentMAC$") {
  Log "INFO" "Chosen MAC matches current MAC; nothing to do."
  exit 0
}

Log "INFO" "Changing MAC from $currentMAC to $newMAC"

if ($DryRun) {
  Log "INFO" "Dry-run mode; no changes applied."
  exit 0
}

# Apply MAC: write registry under adapter's NetCfgInstanceId
$keyPath = "HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e972-e325-11ce-bfc1-08002be10318}"
$instanceId = $adpt.NetConnectionID
$sub = Get-ChildItem $keyPath |
  Where-Object {
    (Get-ItemProperty $_.PSPath).NetCfgInstanceId -eq $adpt.InterfaceGuid.Guid.ToString()
  }

if (-not $sub) { ErrorExit "Could not locate registry key for adapter." }

Set-ItemProperty -Path $sub.PSPath -Name "NetworkAddress" -Value ($newMAC -replace ":", "") -ErrorAction Stop
Log "INFO" "Registry updated with NetworkAddress=$newMAC"

# Disable and enable adapter
Disable-NetAdapter -Name $Interface -Confirm:$false -ErrorAction Stop
Start-Sleep -Seconds 2
Enable-NetAdapter -Name $Interface -Confirm:$false -ErrorAction Stop
Start-Sleep -Seconds 5

# Reconnect Wi-Fi
try {
  Restart-NetAdapter -Name $Interface -Confirm:$false -ErrorAction Stop
} catch {
  Log "WARN" "Could not restart adapter fine; continuing."
}

# Logging
$timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
$entry = "$timestamp Changed MAC on $Interface from $currentMAC to $newMAC"
Add-Content -Path $LOG_FILE -Value $entry
$lines = Get-Content $LOG_FILE -ErrorAction SilentlyContinue
if ($lines.Count -gt 1000) {
  $last = $lines[-500..-1]
  Set-Content -Path $LOG_FILE -Value $last
}

Log "INFO" "MAC changed and logged to $LOG_FILE"

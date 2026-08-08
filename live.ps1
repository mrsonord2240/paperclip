# Start the LIVE Paperclip board from THIS REPO's build.
#
# WHY THIS EXISTS:
# The live board used to run `npx paperclipai`, which serves a frozen published
# dist from the npm cache (it was pinned at v2026.722.0, 2026-07-22). Nothing you
# change in this repo reaches that process. This script runs the live instance
# from the CLI built out of this working tree instead, so local changes ship.
#
# This is the mirror image of dev.ps1: same PAPERCLIP_HOME ambiguity, opposite
# direction. dev.ps1 guards against the dev build opening the LIVE database; this
# guards against the live board opening the DEV database.
#
#   live board : 127.0.0.1:3100   ~/.paperclip/instances/default        pg 54329
#   dev        : 127.0.0.1:3200   ~/.paperclip-dev/instances/dev        pg 54330
#
# Port, bind, deployment mode and serveUi all come from the instance config.json,
# so they are deliberately NOT set here.
#
# RUNS THE BUILT OUTPUT: after changing code, `pnpm build` before restarting.
#
# Usage:  .\live.ps1

$LiveHome = 'C:\Users\User\.paperclip'

$env:PAPERCLIP_HOME = $LiveHome
$env:PAPERCLIP_INSTANCE_ID = 'default'
$env:PAPERCLIP_CONFIG = Join-Path $LiveHome 'instances\default\config.json'

if ($env:PAPERCLIP_HOME -eq (Join-Path $HOME '.paperclip-dev')) {
    throw "Refusing to start: PAPERCLIP_HOME points at the dev instance."
}
if (-not (Test-Path $env:PAPERCLIP_CONFIG)) {
    throw "Refusing to start: no live config at $($env:PAPERCLIP_CONFIG)"
}

Set-Location $PSScriptRoot

if (-not (Test-Path 'cli\dist\index.js')) {
    throw "No built CLI at cli\dist\index.js. Run: pnpm build"
}

# The old npx board may still hold the port. Fail loudly with the PID rather than
# racing it for the socket.
$busy = Get-NetTCPConnection -State Listen -LocalPort 3100 -ErrorAction SilentlyContinue
if ($busy) {
    $owner = $busy[0].OwningProcess
    throw "Port 3100 is already held by PID $owner. Stop it first:  Stop-Process -Id $owner"
}

Write-Host "live board -> http://127.0.0.1:3100  (data: $($env:PAPERCLIP_HOME))" -ForegroundColor Green
Write-Host "running from this repo's build; 'pnpm build' after code changes" -ForegroundColor DarkGray

node cli\dist\index.js run

# Start the LOCAL DEV Paperclip, isolated from the live board.
#
# WHY THIS EXISTS INSTEAD OF PLAIN `pnpm dev`:
# `pnpm dev` resolves its data directory from PAPERCLIP_HOME. That is read from
# the repo .env — but only after server/src/config.ts has already resolved and
# loaded ~/.paperclip/instances/default/.env, so the routing depends on dotenv
# load order. If it ever resolves wrong, the dev build (which carries migrations
# the live instance has never seen) opens the LIVE database. Setting the vars in
# the shell removes the ambiguity entirely.
#
#   live board : 127.0.0.1:3100   ~/.paperclip/instances/default        pg 54329
#   dev        : 127.0.0.1:3200   ~/.paperclip-dev/instances/dev        pg 54330
#
# Usage:  .\dev.ps1            # watch mode
#         .\dev.ps1 -Once      # no file watching

param([switch]$Once)

$env:PAPERCLIP_HOME = 'C:\Users\User\.paperclip-dev'
$env:PAPERCLIP_INSTANCE_ID = 'dev'
$env:PAPERCLIP_CONFIG = 'C:\Users\User\.paperclip-dev\instances\dev\config.json'
$env:PORT = '3200'
$env:PAPERCLIP_BIND = 'loopback'
$env:PAPERCLIP_DEPLOYMENT_MODE = 'local_trusted'
$env:PAPERCLIP_DEPLOYMENT_EXPOSURE = 'private'

if ($env:PAPERCLIP_HOME -eq (Join-Path $HOME '.paperclip')) {
    throw "Refusing to start: PAPERCLIP_HOME points at the live instance."
}

Write-Host "dev instance -> http://127.0.0.1:$($env:PORT)  (data: $($env:PAPERCLIP_HOME))" -ForegroundColor Cyan

Set-Location $PSScriptRoot
if ($Once) { pnpm dev:once } else { pnpm dev }

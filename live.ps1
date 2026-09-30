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
# The server runs from SOURCE via tsx, like dev.ps1 does. It cannot run from
# server\dist: workspace packages export ./src/*.ts and only rewrite to dist via
# publishConfig at publish time, so plain node resolves @paperclipai/db to its
# TypeScript source and dies on its ./client.js import. tsx resolves those fine.
#
# The UI is different — it IS served as a built bundle from ui\dist, so a UI
# change needs `pnpm build` (or at least the ui build) before a restart. Server
# changes only need a restart.
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

# Not cli\dist\index.js: the built CLI declares none of its runtime deps in
# cli/package.json (zod, among others). Those exist only in the published
# package, which build-npm.sh assembles with them installed, so from the repo it
# dies with ERR_MODULE_NOT_FOUND.
$tsx = 'node_modules\tsx\dist\cli.mjs'
if (-not (Test-Path (Join-Path 'server' $tsx))) {
    throw "No tsx in server\node_modules. Run: pnpm install"
}
# app.ts serves the UI from server/ui-dist (published) or ../../ui/dist (repo).
if (-not (Test-Path 'ui\dist\index.html')) {
    throw "No built UI at ui\dist\index.html. Run: pnpm build"
}

# The old npx board may still hold the port. Fail loudly with the PID rather than
# racing it for the socket.
$busy = Get-NetTCPConnection -State Listen -LocalPort 3100 -ErrorAction SilentlyContinue
if ($busy) {
    $owner = $busy[0].OwningProcess
    throw "Port 3100 is already held by PID $owner. Stop it first:  Stop-Process -Id $owner"
}

Write-Host "live board -> http://127.0.0.1:3100  (data: $($env:PAPERCLIP_HOME))" -ForegroundColor Green
Write-Host "server from source via tsx; UI from ui\dist ('pnpm build' after UI changes)" -ForegroundColor DarkGray

Set-Location (Join-Path $PSScriptRoot 'server')
node $tsx src\index.ts

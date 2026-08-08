#!/usr/bin/env node
// Copy the server's non-TypeScript assets into dist/ after tsc.
//
// This replaces `mkdir -p ... && cp -R ...` in the server build script. pnpm runs
// package scripts through cmd.exe on Windows, where `mkdir -p` is a syntax error
// ("The syntax of the command is incorrect.") and `cp` does not exist at all, so
// the build failed there after tsc had already succeeded. fs.cpSync is portable
// and needs no extra dependency.

import { cpSync, existsSync, mkdirSync } from "node:fs";
import { dirname, join, resolve } from "node:path";
import { fileURLToPath } from "node:url";

const repoRoot = resolve(dirname(fileURLToPath(import.meta.url)), "..");
const serverDir = join(repoRoot, "server");

// Directory name under server/src, copied to the same name under server/dist.
const assetDirs = ["onboarding-assets", "built-ins"];

for (const assetDir of assetDirs) {
  const from = join(serverDir, "src", assetDir);
  const to = join(serverDir, "dist", assetDir);

  if (!existsSync(from)) {
    throw new Error(`Missing server asset directory: ${from}`);
  }

  mkdirSync(to, { recursive: true });
  cpSync(from, to, { recursive: true });
  console.log(`[paperclip] copied server/src/${assetDir} -> server/dist/${assetDir}`);
}

#!/usr/bin/env node
//
// Captures title screen screenshot, gameplay screenshot, and gameplay GIF
// from the live site using headless Chrome via Puppeteer.
//
// Prerequisites:
//   npm install puppeteer-core
//   Google Chrome installed (update CHROME_PATH below if needed)
//   ffmpeg installed (for GIF creation)
//
// Usage:
//   node docs/capture_screenshots.mjs
//   # Then build the GIF:
//   ffmpeg -y -framerate 10 -i docs/screenshots/frame_%04d.png \
//     -vf "fps=10,scale=640:-1:flags=lanczos,split[s0][s1];[s0]palettegen=max_colors=128[p];[s1][p]paletteuse=dither=bayer" \
//     docs/screenshots/gameplay.gif
//   rm docs/screenshots/frame_*.png
//
// The script:
//   1. Loads the game in headless Chrome (30s wait for WASM)
//   2. Captures the title screen
//   3. Starts the game, enters the Konami cheat code (so the fish survives)
//   4. Captures a gameplay screenshot mid-action
//   5. Records ~4s of GIF frames (fish auto-dodging via god fish mode)
//
// Adjust CHROME_PATH for your OS:
//   macOS:  /Applications/Google Chrome.app/Contents/MacOS/Google Chrome
//   Linux:  /usr/bin/google-chrome-stable
//   Windows: C:\\Program Files\\Google\\Chrome\\Application\\chrome.exe

import puppeteer from 'puppeteer-core';
import { setTimeout } from 'timers/promises';

const GAME_URL = 'https://vppillai.github.io/godot_slop/';
const OUT_DIR = new URL('./screenshots/', import.meta.url).pathname;
const CHROME_PATH = '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome';
const WASM_WAIT_MS = 30000;  // Time for Godot WASM to compile and render title

(async () => {
  const browser = await puppeteer.launch({
    headless: 'new',
    args: ['--no-sandbox', '--window-size=1280,720'],
    defaultViewport: { width: 1280, height: 720 },
    executablePath: CHROME_PATH,
  });
  const page = await browser.newPage();

  console.log('Loading game...');
  await page.goto(GAME_URL, { waitUntil: 'networkidle2', timeout: 180000 });
  console.log(`Waiting ${WASM_WAIT_MS / 1000}s for WASM init...`);
  await setTimeout(WASM_WAIT_MS);

  // --- Title screen ---
  await page.screenshot({ path: `${OUT_DIR}/title_screen.png` });
  console.log('Captured: title_screen.png');

  // --- Start game ---
  await page.mouse.click(640, 360);
  await setTimeout(500);
  await page.keyboard.press('Space');
  await setTimeout(2000);

  // --- Konami code (god fish) so the fish survives the whole recording ---
  const konami = ['ArrowUp', 'ArrowUp', 'ArrowDown', 'ArrowDown',
                  'ArrowLeft', 'ArrowRight', 'ArrowLeft', 'ArrowRight',
                  'KeyB', 'KeyA'];
  for (const key of konami) {
    await page.keyboard.press(key);
    await setTimeout(80);
  }
  console.log('God fish cheat activated');
  await setTimeout(3000);  // Let auto-dodge run + hazards spawn

  // --- Gameplay screenshot ---
  await page.screenshot({ path: `${OUT_DIR}/gameplay.png` });
  console.log('Captured: gameplay.png');

  // Wait for more hazards before GIF
  await setTimeout(6000);

  // --- GIF frames (auto-dodge provides movement) ---
  console.log('Recording GIF frames...');
  let fc = 0;
  const t0 = Date.now();
  while (Date.now() - t0 < 6000) {
    await page.screenshot({ path: `${OUT_DIR}/frame_${String(fc).padStart(4, '0')}.png` });
    fc++;
    await setTimeout(100);
  }

  console.log(`Captured ${fc} GIF frames`);
  console.log('');
  console.log('Next steps:');
  console.log('  ffmpeg -y -framerate 10 -i docs/screenshots/frame_%04d.png \\');
  console.log('    -vf "fps=10,scale=640:-1:flags=lanczos,split[s0][s1];[s0]palettegen=max_colors=128[p];[s1][p]paletteuse=dither=bayer" \\');
  console.log('    docs/screenshots/gameplay.gif');
  console.log('  rm docs/screenshots/frame_*.png');

  await browser.close();
})();

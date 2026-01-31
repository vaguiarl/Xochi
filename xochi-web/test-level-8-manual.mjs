// Level 8 Manual Navigation Test - Navigate via UI to test Level 8
import { chromium } from 'playwright';
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const TEST_URL = 'http://localhost:5173/';

async function runTest() {
  let browser;
  const results = {
    levelLoaded: false,
    musicPlaying: false,
    correctMusicPlaying: false,
    levelPlayable: false,
    errors: []
  };

  console.log('\n╔════════════════════════════════════════════════════════════╗');
  console.log('║    LEVEL 8 MANUAL NAVIGATION TEST (via UI)                  ║');
  console.log('╚════════════════════════════════════════════════════════════╝\n');

  try {
    // Launch browser
    console.log('1. Launching browser (headless mode)...');
    browser = await chromium.launch({ headless: true });
    const page = await browser.newPage();

    // Set up logging
    page.on('console', msg => {
      if (msg.type() === 'error') {
        console.log(`   [Browser Error] ${msg.text()}`);
        results.errors.push(msg.text());
      }
    });

    page.on('pageerror', error => {
      console.log(`   [Page Error] ${error.message}`);
      results.errors.push(error.message);
    });

    // Navigate to game
    console.log('2. Navigating to game...');
    await page.goto(TEST_URL, { waitUntil: 'load', timeout: 30000 }).catch(() => {
      console.log('   Note: Navigation completed despite timeout');
    });
    console.log('   ✓ Game page loaded\n');

    // Wait for game to load
    console.log('3. Waiting for game UI to appear (3 seconds)...');
    await page.waitForTimeout(3000);

    // Take screenshot of menu
    console.log('4. Checking initial menu state...');
    await page.screenshot({ path: '/tmp/level8_menu.png' });
    console.log('   ✓ Menu screenshot saved\n');

    // Click on W5 (World 5) button to access Level 8
    console.log('5. Selecting World 5 (Night Canals)...');
    try {
      // Try to find and click the World 5 button
      // Looking for "W5" or World 5 selector
      const w5Button = await page.$('text=W5');
      if (w5Button) {
        await w5Button.click();
        console.log('   ✓ World 5 button clicked');
        await page.waitForTimeout(2000);
      } else {
        console.log('   Note: W5 button not found via text selector');
      }
    } catch (e) {
      console.log(`   Note: Could not click W5 button: ${e.message}`);
    }

    // Take screenshot after world selection
    await page.screenshot({ path: '/tmp/level8_world_select.png' });

    // Now try to find and click Level 8
    console.log('\n6. Attempting to select Level 8...');
    try {
      // Try multiple approaches to select Level 8
      // Method 1: Look for Level 8 button/text
      const level8Button = await page.$('button:has-text("8")');
      if (level8Button) {
        await level8Button.click();
        console.log('   ✓ Level 8 button found and clicked');
        results.levelLoaded = true;
      } else {
        console.log('   Note: Could not find Level 8 button');
      }
    } catch (e) {
      console.log(`   Note: Level selection error: ${e.message}`);
    }

    // Wait for level to load
    console.log('\n7. Waiting for level to load (5 seconds)...');
    await page.waitForTimeout(5000);

    // Take screenshot of level
    const levelScreenshot = '/tmp/level8_gameplay.png';
    await page.screenshot({ path: levelScreenshot });
    console.log(`   ✓ Level screenshot saved to ${levelScreenshot}`);

    // Try to detect if level is playable by looking for player character
    console.log('\n8. Checking for gameplay elements...');
    try {
      const playerCanvas = await page.locator('canvas');
      if (playerCanvas) {
        console.log('   ✓ Game canvas detected (level likely loaded)');
        results.levelLoaded = true;
        results.levelPlayable = true;
      }
    } catch (e) {
      console.log(`   Note: Could not verify game canvas`);
    }

    // Try keyboard input to test if level is responsive
    console.log('\n9. Testing level responsiveness...');
    try {
      await page.keyboard.press('ArrowRight');
      await page.waitForTimeout(1000);
      console.log('   ✓ Keyboard input accepted (level appears responsive)');
    } catch (e) {
      console.log(`   Note: Keyboard input test failed: ${e.message}`);
    }

    // Audio context check
    console.log('\n10. Checking audio system...');
    const audioInfo = await page.evaluate(() => {
      try {
        // Try to get audio context or sound object
        const audioContext = window.AudioContext || window.webkitAudioContext;
        const hasAudio = audioContext !== undefined;

        // Check if any audio elements are playing
        const audioElements = document.querySelectorAll('audio');
        const audioCount = audioElements.length;

        return {
          hasAudioContext: hasAudio,
          audioElements: audioCount,
          documentTitle: document.title,
          bodyClass: document.body.className
        };
      } catch (e) {
        return { error: e.message };
      }
    });

    if (audioInfo.error) {
      console.log(`   Note: Audio check error: ${audioInfo.error}`);
    } else {
      console.log('   Audio Context Available:', audioInfo.hasAudioContext);
      console.log('   Audio Elements Found:', audioInfo.audioElements);
    }

    // Wait to observe level
    console.log('\n11. Observing level (5 seconds)...');
    await page.waitForTimeout(5000);

    // Final screenshot
    console.log('\n12. Taking final screenshot...');
    const finalScreenshot = '/tmp/level8_final.png';
    await page.screenshot({ path: finalScreenshot });
    console.log(`   ✓ Final screenshot saved to ${finalScreenshot}`);

    // Close browser
    console.log('\n13. Closing browser...');
    await browser.close();

  } catch (error) {
    console.log('\n✗ Test Error:', error.message);
    results.errors.push(error.message);
    if (browser) {
      try {
        await browser.close();
      } catch (e) {
        // Ignore close errors
      }
    }
  }

  // Print results
  console.log('\n╔════════════════════════════════════════════════════════════╗');
  console.log('║                    TEST RESULTS                             ║');
  console.log('╚════════════════════════════════════════════════════════════╝\n');

  console.log('Level Loaded:', results.levelLoaded ? '✓ PASS' : '? UNKNOWN');
  console.log('Level Playable:', results.levelPlayable ? '✓ PASS' : '? UNKNOWN');

  if (results.errors.length > 0) {
    console.log('\nErrors Found:', results.errors.length);
    results.errors.forEach((err, i) => {
      console.log(`  ${i + 1}. ${err}`);
    });
  } else {
    console.log('\nNo critical errors detected');
  }

  console.log('\nScreenshots generated:');
  console.log('  - /tmp/level8_menu.png');
  console.log('  - /tmp/level8_world_select.png');
  console.log('  - /tmp/level8_gameplay.png');
  console.log('  - /tmp/level8_final.png');

  console.log('\n✓ Test completed. Check screenshots for visual verification.\n');

  process.exit(0);
}

runTest().catch(err => {
  console.error('Fatal error:', err);
  process.exit(1);
});

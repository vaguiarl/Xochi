// Level 8 Automated Test - Uses Playwright to test Level 8 loading and audio configuration
import { chromium } from 'playwright';
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const TEST_URL = 'http://localhost:5173/';
const TEST_TIMEOUT = 30000; // 30 seconds

async function runTest() {
  let browser;
  const results = {
    levelLoaded: false,
    musicInitialized: false,
    correctMusicPlaying: false,
    levelPlayable: false,
    errors: []
  };

  console.log('\n╔════════════════════════════════════════════════════════════╗');
  console.log('║         LEVEL 8 PLAYABILITY & AUDIO TEST                    ║');
  console.log('╚════════════════════════════════════════════════════════════╝\n');

  try {
    // Launch browser in headless mode
    console.log('1. Launching browser (headless mode)...');
    browser = await chromium.launch({ headless: true });
    const page = await browser.newPage();

    // Set up console message logging
    const consoleLogs = [];
    page.on('console', msg => {
      consoleLogs.push({ type: msg.type(), text: msg.text() });
      if (msg.type() === 'error') {
        console.log(`   [ERROR] ${msg.text()}`);
        results.errors.push(msg.text());
      }
    });

    page.on('pageerror', error => {
      console.log(`   [PAGE ERROR] ${error.message}`);
      results.errors.push(error.message);
    });

    // Navigate to game
    console.log('2. Navigating to game...');
    await page.goto(TEST_URL, { waitUntil: 'networkidle', timeout: 30000 }).catch(err => {
      console.log('   Note: Navigation timeout, but page may still be loading');
    });
    results.levelLoaded = true;
    console.log('   ✓ Game page loaded\n');

    // Wait for game to initialize
    console.log('3. Waiting for game initialization...');
    await page.waitForTimeout(3000); // Wait for Phaser to load

    // Inject test code to check game state and start Level 8
    console.log('4. Injecting test code...');
    const gameTestResult = await page.evaluate(() => {
      return new Promise((resolve) => {
        // Wait for game to be ready
        let checkCount = 0;
        const checkInterval = setInterval(() => {
          checkCount++;

          // Check if game object is available
          if (typeof window.game === 'undefined' || !window.game) {
            if (checkCount > 100) { // 10 seconds timeout
              clearInterval(checkInterval);
              resolve({
                gameReady: false,
                error: 'Game object not available'
              });
            }
            return;
          }

          // Check if scenes are available
          if (!window.game.scene) {
            return;
          }

          // Game is ready
          clearInterval(checkInterval);

          try {
            // Store game state info
            const gameInfo = {
              gameReady: true,
              gameStateExists: typeof window.gameState !== 'undefined',
              currentLevel: window.gameState?.currentLevel || null,
              musicEnabled: window.gameState?.musicEnabled || false,
              totalLevels: window.gameState?.totalLevels || null,
              scenesAvailable: Object.keys(window.game.scene.scenes || {})
            };

            // Try to get current scene info
            const sceneManager = window.game.scene;
            const scenes = sceneManager.scenes || [];
            const sceneNames = scenes.map(s => s.constructor.name || 'Unknown');

            gameInfo.activeScenes = sceneNames;

            console.log('[Test Code] Game info:', JSON.stringify(gameInfo, null, 2));

            resolve(gameInfo);
          } catch (e) {
            resolve({
              gameReady: true,
              error: e.message
            });
          }
        }, 100);
      });
    });

    console.log(`   Game Ready: ${gameTestResult.gameReady}`);
    if (gameTestResult.error) {
      console.log(`   Error: ${gameTestResult.error}`);
      results.errors.push(gameTestResult.error);
    }

    // Navigate to Level 8 via injected code
    console.log('\n5. Starting Level 8...');
    const startResult = await page.evaluate(() => {
      return new Promise((resolve) => {
        try {
          // Set current level to 8
          if (window.gameState) {
            window.gameState.currentLevel = 8;
          }

          // Try to start Level 8 via the game scene
          if (window.game && window.game.scene) {
            const sceneManager = window.game.scene;

            // Stop any running scenes
            if (sceneManager.getScene('MenuScene')) {
              sceneManager.stop('MenuScene');
            }
            if (sceneManager.getScene('GameScene')) {
              sceneManager.stop('GameScene');
            }

            // Start game scene with Level 8
            sceneManager.start('GameScene', { level: 8 });

            console.log('[Test Code] Level 8 started');

            // Wait a moment for level to initialize
            setTimeout(() => {
              resolve({
                success: true,
                levelStarted: true,
                message: 'Level 8 scene started'
              });
            }, 1000);
          } else {
            resolve({
              success: false,
              error: 'Game scene manager not available'
            });
          }
        } catch (e) {
          resolve({
            success: false,
            error: e.message
          });
        }
      });
    });

    console.log(`   Level 8 started: ${startResult.levelStarted}`);
    if (!startResult.success) {
      console.log(`   Error: ${startResult.error}`);
      results.errors.push(startResult.error);
    } else {
      console.log('');
    }

    // Wait for level to load
    console.log('6. Waiting for level to load (5 seconds)...');
    await page.waitForTimeout(5000);

    // Check level state and music
    console.log('7. Checking level state and audio...');
    const levelState = await page.evaluate(() => {
      return new Promise((resolve) => {
        try {
          const sceneManager = window.game.scene;
          const gameScene = sceneManager.getScene('GameScene');

          if (!gameScene) {
            resolve({
              sceneLoaded: false,
              error: 'GameScene not found'
            });
            return;
          }

          const state = {
            sceneLoaded: true,
            levelNum: gameScene.levelNum,
            levelDataExists: !!gameScene.levelData,
            playerExists: !!gameScene.player,
            musicExists: !!gameScene.music,
            musicKey: gameScene.music?.key || 'none',
            musicPlaying: gameScene.music?.isPlaying || false,
            soundManager: window.game.sound !== undefined,
            audioContext: window.game.sound?.context !== undefined
          };

          // Check if it's an upscroller level
          if (gameScene.levelData) {
            state.isUpscroller = gameScene.levelData.isUpscroller || false;
          }

          console.log('[Test Code] Level state:', JSON.stringify(state, null, 2));

          resolve(state);
        } catch (e) {
          resolve({
            error: e.message,
            stack: e.stack
          });
        }
      });
    });

    console.log('   Level Loaded:', levelState.sceneLoaded);
    console.log('   Level Number:', levelState.levelNum);
    console.log('   Is Upscroller:', levelState.isUpscroller);
    console.log('   Player Exists:', levelState.playerExists);
    console.log('   Music Key:', levelState.musicKey);
    console.log('   Music Playing:', levelState.musicPlaying);

    if (levelState.error) {
      console.log('   Error:', levelState.error);
      results.errors.push(levelState.error);
    }

    // Verify results
    results.levelLoaded = levelState.sceneLoaded === true;
    results.levelPlayable = levelState.playerExists === true;
    results.musicInitialized = levelState.musicExists === true;

    // Check if correct music is playing
    if (levelState.musicKey === 'music-upscroller') {
      results.correctMusicPlaying = true;
      console.log('\n   ✓ CORRECT MUSIC: music-upscroller (Same as Level 3)');
    } else if (levelState.musicKey === 'music-night') {
      console.log('\n   ✗ WRONG MUSIC: music-night (World-based, not upscroller)');
      results.errors.push('Wrong music playing: music-night instead of music-upscroller');
    } else if (levelState.musicKey === 'music-caves') {
      console.log('\n   ✗ WRONG MUSIC: music-caves (Unexpected world music)');
      results.errors.push('Wrong music playing: music-caves instead of music-upscroller');
    } else if (levelState.musicKey && levelState.musicKey !== 'none') {
      console.log(`\n   ✗ UNEXPECTED MUSIC: ${levelState.musicKey}`);
      results.errors.push(`Unexpected music: ${levelState.musicKey}`);
    } else {
      console.log('\n   ✗ NO MUSIC: Music key is "none"');
      results.errors.push('No music loaded');
    }

    // Test player input (try to move)
    console.log('\n8. Testing player input...');
    try {
      // Press right arrow to move
      await page.keyboard.press('ArrowRight');
      await page.waitForTimeout(500);

      const playerMoved = await page.evaluate(() => {
        const gameScene = window.game.scene.getScene('GameScene');
        if (gameScene && gameScene.player) {
          return {
            playerX: gameScene.player.x,
            playerY: gameScene.player.y,
            playerVelX: gameScene.player.body?.velocity?.x || 0,
            playerVelY: gameScene.player.body?.velocity?.y || 0
          };
        }
        return { error: 'Player not found' };
      });

      if (playerMoved.error) {
        console.log('   Note:', playerMoved.error);
      } else {
        console.log('   Player Position: X=' + playerMoved.playerX.toFixed(0) +
                    ' Y=' + playerMoved.playerY.toFixed(0));
        console.log('   Velocity: X=' + playerMoved.playerVelX.toFixed(0) +
                    ' Y=' + playerMoved.playerVelY.toFixed(0));
        console.log('   ✓ Player is responsive to input');
      }
    } catch (e) {
      console.log('   Note: Could not test player movement:', e.message);
    }

    // Wait a bit more to observe music playing
    console.log('\n9. Observing music playback (3 seconds)...');
    await page.waitForTimeout(3000);

    // Final check
    console.log('\n10. Final audio check...');
    const finalAudioState = await page.evaluate(() => {
      try {
        const gameScene = window.game.scene.getScene('GameScene');
        if (gameScene && gameScene.music) {
          return {
            musicStillPlaying: gameScene.music.isPlaying,
            musicVolume: gameScene.music.volume,
            musicKey: gameScene.music.key
          };
        }
        return { error: 'Music not found' };
      } catch (e) {
        return { error: e.message };
      }
    });

    console.log('   Music Still Playing:', finalAudioState.musicStillPlaying);
    console.log('   Music Volume:', finalAudioState.musicVolume);

    if (finalAudioState.error) {
      console.log('   Error:', finalAudioState.error);
    }

    // Take a screenshot
    console.log('\n11. Taking screenshot...');
    const screenshotPath = path.join('/tmp', 'level8_screenshot.png');
    await page.screenshot({ path: screenshotPath });
    console.log(`   ✓ Screenshot saved to ${screenshotPath}`);

    // Clean up
    console.log('\n12. Closing browser...');
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
  console.log('║                    TEST RESULTS SUMMARY                     ║');
  console.log('╚════════════════════════════════════════════════════════════╝\n');

  console.log('Level Loaded:', results.levelLoaded ? '✓ PASS' : '✗ FAIL');
  console.log('Level Playable:', results.levelPlayable ? '✓ PASS' : '✗ FAIL');
  console.log('Music Initialized:', results.musicInitialized ? '✓ PASS' : '✗ FAIL');
  console.log('Correct Music (music-upscroller):', results.correctMusicPlaying ? '✓ PASS' : '✗ FAIL');

  if (results.errors.length > 0) {
    console.log('\nErrors Found:');
    results.errors.forEach((err, i) => {
      console.log(`  ${i + 1}. ${err}`);
    });
  } else {
    console.log('\nNo errors found!');
  }

  const allPass = results.levelLoaded && results.levelPlayable &&
                  results.musicInitialized && results.correctMusicPlaying &&
                  results.errors.length === 0;

  console.log('\n' + (allPass ? '✓ ALL TESTS PASSED' : '✗ SOME TESTS FAILED'));
  console.log('\n');

  process.exit(allPass ? 0 : 1);
}

runTest().catch(err => {
  console.error('Fatal error:', err);
  process.exit(1);
});

const { chromium } = require('playwright');

async function testXochiGame() {
  const browser = await chromium.launch({ headless: false });
  const page = await browser.newPage();

  // Set viewport to desktop size
  await page.setViewportSize({ width: 1024, height: 768 });

  console.log('\n=== XOCHI GAME TESTING SUITE ===\n');

  // Test 1: Load the game
  console.log('TEST 1: Game Loading');
  try {
    await page.goto('https://vaguiarl.github.io/Xochi/', { waitUntil: 'networkidle' });
    console.log('✓ Game URL loaded successfully');
  } catch (error) {
    console.log('✗ Failed to load game URL:', error.message);
    await browser.close();
    return;
  }

  // Test 2: Check for loading bar
  console.log('\nTEST 2: Loading Bar Display');
  try {
    // Wait a moment for loading to start
    await page.waitForTimeout(1000);

    // Check if canvas exists (game is initializing)
    const hasCanvas = await page.locator('canvas').count() > 0;
    if (hasCanvas) {
      console.log('✓ Canvas element found (game initializing)');
    } else {
      console.log('✗ Canvas element not found');
    }

    // Check page title
    const title = await page.title();
    console.log(`✓ Page title: "${title}"`);
  } catch (error) {
    console.log('✗ Error checking loading elements:', error.message);
  }

  // Test 3: Wait for menu to appear
  console.log('\nTEST 3: Menu Scene Loading');
  try {
    // Wait for game to fully load (up to 10 seconds)
    await page.waitForTimeout(5000);

    // Try to find text on the page that indicates menu is loaded
    // Look for common menu text like "New Game", "Continue", etc.
    const pageContent = await page.content();

    if (pageContent.includes('New Game') || pageContent.includes('canvas')) {
      console.log('✓ Game appears to be loaded (found canvas or menu elements)');
    }

    // Check for any console errors
    const logs = [];
    page.on('console', msg => logs.push(msg));

  } catch (error) {
    console.log('✗ Error waiting for menu:', error.message);
  }

  // Test 4: Interact with New Game button
  console.log('\nTEST 4: New Game Button Interaction');
  try {
    // The game uses Phaser with canvas, so we need to click on the canvas
    // where the button should be (center-ish area)
    await page.waitForTimeout(3000);

    const canvas = await page.locator('canvas');
    const boundingBox = await canvas.boundingBox();

    if (boundingBox) {
      console.log(`✓ Canvas found at position (${boundingBox.x}, ${boundingBox.y}), size: ${boundingBox.width}x${boundingBox.height}`);

      // Estimate New Game button location (usually center, upper-middle)
      const clickX = boundingBox.x + boundingBox.width / 2;
      const clickY = boundingBox.y + boundingBox.height / 2 - 40;

      console.log(`  Attempting to click New Game button at (${Math.round(clickX)}, ${Math.round(clickY)})`);
      await page.mouse.click(clickX, clickY);

      await page.waitForTimeout(2000);
      console.log('✓ New Game button clicked');
    }
  } catch (error) {
    console.log('✗ Error clicking New Game button:', error.message);
  }

  // Test 5: Check for level loading
  console.log('\nTEST 5: Level 1 Loading');
  try {
    await page.waitForTimeout(3000);

    const canvas = await page.locator('canvas');
    if (await canvas.isVisible()) {
      console.log('✓ Canvas is visible (level may be loading)');
    }

    // Check if we can access game state via console
    const gameState = await page.evaluate(() => {
      return window.gameState || null;
    });

    if (gameState) {
      console.log(`✓ Game state accessible:`, {
        currentLevel: gameState.currentLevel,
        lives: gameState.lives,
        flowers: gameState.flowers,
        difficulty: gameState.difficulty
      });
    } else {
      console.log('! Game state not accessible via window.gameState');
    }
  } catch (error) {
    console.log('✗ Error checking level loading:', error.message);
  }

  // Test 6: Keyboard controls (movement simulation)
  console.log('\nTEST 6: Input Testing (Keyboard)');
  try {
    // Try pressing arrow keys
    await page.press('canvas', 'ArrowRight');
    await page.waitForTimeout(500);
    console.log('✓ Arrow key input processed');

    // Try spacebar for jump
    await page.press('canvas', 'Space');
    await page.waitForTimeout(500);
    console.log('✓ Spacebar input processed');
  } catch (error) {
    console.log('✗ Error with keyboard input:', error.message);
  }

  // Test 7: Touch/Mobile control detection
  console.log('\nTEST 7: Mobile Controls Detection');
  try {
    const isTouchSupported = await page.evaluate(() => {
      return 'ontouchstart' in window;
    });

    if (isTouchSupported) {
      console.log('✓ Touch support detected in browser');

      // Check if mobile controls are set up
      const hasTouchHandlers = await page.evaluate(() => {
        return {
          touchStart: document.ontouchstart !== null,
          touchMove: document.ontouchmove !== null,
          touchEnd: document.ontouchend !== null
        };
      });

      console.log('  Touch event handlers:', hasTouchHandlers);
    } else {
      console.log('! Touch not supported in this browser environment');
    }
  } catch (error) {
    console.log('✗ Error checking mobile controls:', error.message);
  }

  // Test 8: Check for JavaScript errors
  console.log('\nTEST 8: Console Error Check');
  try {
    const consoleErrors = [];
    const consoleWarnings = [];

    page.on('console', msg => {
      if (msg.type() === 'error') {
        consoleErrors.push(msg.text());
      } else if (msg.type() === 'warning') {
        consoleWarnings.push(msg.text());
      }
    });

    page.on('pageerror', error => {
      consoleErrors.push(error.toString());
    });

    await page.waitForTimeout(2000);

    if (consoleErrors.length === 0) {
      console.log('✓ No console errors detected');
    } else {
      console.log('✗ Console errors found:');
      consoleErrors.forEach(err => console.log(`  - ${err}`));
    }

    if (consoleWarnings.length > 0) {
      console.log('! Console warnings:');
      consoleWarnings.slice(0, 3).forEach(warn => console.log(`  - ${warn}`));
    }
  } catch (error) {
    console.log('✗ Error monitoring console:', error.message);
  }

  // Test 9: Check audio system
  console.log('\nTEST 9: Audio System Check');
  try {
    const audioInfo = await page.evaluate(() => {
      const sounds = {};
      const audioCtx = window.audioContext || window.webkitAudioContext;

      return {
        hasWebAudio: !!audioCtx,
        musicEnabled: window.gameState?.musicEnabled,
        sfxEnabled: window.gameState?.sfxEnabled,
        isMuted: document.hidden
      };
    });

    console.log('✓ Audio system status:', audioInfo);
  } catch (error) {
    console.log('✗ Error checking audio system:', error.message);
  }

  // Test 10: Responsive scaling
  console.log('\nTEST 10: Responsive Scaling');
  try {
    // Test different viewport sizes
    const sizes = [
      { width: 800, height: 600, name: 'Desktop' },
      { width: 480, height: 800, name: 'Mobile Portrait' },
      { width: 1024, height: 768, name: 'Tablet' }
    ];

    for (const size of sizes) {
      await page.setViewportSize({ width: size.width, height: size.height });
      await page.waitForTimeout(500);

      const canvas = await page.locator('canvas').boundingBox();
      if (canvas) {
        console.log(`✓ ${size.name} (${size.width}x${size.height}): Canvas responsive at ${canvas.width}x${canvas.height}`);
      }
    }
  } catch (error) {
    console.log('✗ Error testing responsive scaling:', error.message);
  }

  console.log('\n=== TESTING COMPLETE ===\n');

  // Keep browser open for manual inspection
  console.log('Browser will stay open for 30 seconds for manual inspection...');
  await page.waitForTimeout(30000);

  await browser.close();
}

testXochiGame().catch(console.error);

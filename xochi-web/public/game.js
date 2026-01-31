// Xochi - Aztec Warrior Adventure
// A Phaser 3 platformer game

// ============== XOCHI MUSIC MANAGER ==============
// Uses Suno-generated tracks for authentic Xochimilco atmosphere
class XochiMusicManager {
  constructor() {
    this.currentMusic = null;
    this.currentTrack = null;
    this.isPlaying = false;
    this.scene = null;
  }

  init(scene) {
    this.scene = scene;
  }

  start(trackKey = 'music-menu') {
    if (!this.scene || !gameState.musicEnabled) return;

    // Don't restart same track
    if (this.isPlaying && this.currentTrack === trackKey) return;

    this.stop();

    try {
      this.currentMusic = this.scene.sound.add(trackKey, { loop: true, volume: 0.4 });
      this.currentMusic.play();
      this.currentTrack = trackKey;
      this.isPlaying = true;
    } catch (e) {
      console.log('Music not available:', trackKey);
    }
  }

  playForWorld(worldNum) {
    // Each world has its own distinct song (2 levels per world)
    // World 1 (1-2): Dawn - Main menu theme
    // World 2 (3-4): Day - Xochi la Oaxalotla Salta
    // World 3 (5-6): Cave - Xochi la Oaxalota
    // World 4 (7-8): Garden - Night theme
    // World 5 (9-10): Night - Boss theme
    // World 6 (11-12): Fiesta - Finale theme
    let track = 'music-menu';
    if (worldNum === 1) track = 'music-menu';
    else if (worldNum === 2) track = 'music-upscroller';
    else if (worldNum === 3) track = 'music-world3';
    else if (worldNum === 4) track = 'music-night';
    else if (worldNum === 5) track = 'music-boss';
    else track = 'music-finale';

    this.start(track);
  }

  playForLevel(levelNum, worldNum) {
    // Each world has one consistent song for both levels
    // No special overrides - music matches the world theme
    this.playForWorld(worldNum);
  }

  stop() {
    if (this.currentMusic) {
      this.currentMusic.stop();
      this.currentMusic.destroy();
      this.currentMusic = null;
    }
    this.isPlaying = false;
    this.currentTrack = null;
  }

  setVolume(vol) {
    if (this.currentMusic) {
      this.currentMusic.setVolume(vol);
    }
  }
}

const mariachiMusic = new XochiMusicManager();

// ============== GAME STATE ==============
const gameState = {
  currentLevel: 1,
  totalLevels: 11,  // 5 worlds × 2 levels + 1 celebration = 11 levels
  flowers: 0,       // Cempasuchil flowers (replaces coins)
  lives: 3,
  stars: [],
  rescuedBabies: [],
  superJumps: 2,    // Start with powerups! (medium default)
  maceAttacks: 1,   // Thunderbolt attacks
  score: 0,
  highScore: 0,
  musicEnabled: true,
  sfxEnabled: true,
  // Difficulty setting: 'easy', 'medium', 'hard'
  difficulty: 'medium'
};

// Difficulty presets - Challenging but FAIR!
const DIFFICULTY_SETTINGS = {
  easy: {
    lives: 5,
    startingSuperJumps: 3,
    startingMaceAttacks: 2,
    platformDensity: 1.2,      // More platforms
    platformGapMult: 0.85,     // Smaller gaps
    enemyMult: 0.7,            // Fewer enemies
    powerupMult: 1.3,          // More powerups
    skyPlatforms: 2,
    coinMult: 1.2,
    bossHealth: { 5: 3, 10: 4 }
  },
  medium: {
    lives: 3,
    startingSuperJumps: 2,
    startingMaceAttacks: 1,
    platformDensity: 1.0,
    platformGapMult: 1.0,
    enemyMult: 1.0,
    powerupMult: 1.0,
    skyPlatforms: 3,
    coinMult: 1.0,
    bossHealth: { 5: 4, 10: 5 }
  },
  hard: {
    lives: 2,
    startingSuperJumps: 1,
    startingMaceAttacks: 1,  // Give at least one attack
    platformDensity: 0.9,    // Slightly smaller platforms but not too sparse
    platformGapMult: 1.1,    // 10% wider gaps (was 15% - too punishing)
    enemyMult: 1.2,          // Slightly fewer enemies
    powerupMult: 0.8,        // More powerups to help
    skyPlatforms: 4,
    coinMult: 0.9,
    bossHealth: { 5: 5, 10: 7 }
  }
};

// Load saved state
try {
  const saved = localStorage.getItem('xochi-save');
  if (saved) Object.assign(gameState, JSON.parse(saved));
} catch (e) {}

function saveGame() {
  localStorage.setItem('xochi-save', JSON.stringify(gameState));
}

function resetGame() {
  // Save high score before reset
  if (gameState.score > gameState.highScore) {
    gameState.highScore = gameState.score;
  }
  const settings = DIFFICULTY_SETTINGS[gameState.difficulty];
  gameState.currentLevel = 1;
  gameState.flowers = 0;
  gameState.lives = settings.lives;
  gameState.stars = [];
  gameState.rescuedBabies = [];
  gameState.superJumps = settings.startingSuperJumps;
  gameState.maceAttacks = settings.startingMaceAttacks;
  gameState.score = 0;
  saveGame();
}

// ============== PROCEDURAL LEVEL GENERATOR ==============

// WORLDS - Each world has a distinct visual theme and feel!
const WORLDS = {
  // World 1: Canal Dawn (Levels 1-2) - Peaceful sunrise, pink/orange sky
  1: {
    name: 'Canal Dawn',
    subtitle: 'El Amanecer',
    sky: [0xffccbb, 0xffaa99, 0xff8877, 0xdd6655, 0xaa5544, 0x774433],
    mountain: 0x446655, hill: 0x558866, waterColor: 0x558899,
    // Enhanced palette for parallax layers
    background: 0xFFB6C1,   // Light pink sky
    foreground: 0x8B4513,   // Saddle brown
    midground: 0xD2691E,    // Chocolate
    vegetation: [0x9ACD32, 0x228B22, 0x6B8E23],  // Yellow-green, forest green, olive
    accent: 0xFFD700,       // Gold
    fog: 0xFFF5E6           // Warm white mist
  },
  // World 2: Trajineras Brillantes (Levels 3-4) - Bright midday, blue sky
  2: {
    name: 'Bright Trajineras',
    subtitle: 'Trajineras Brillantes',
    sky: [0x77ddff, 0x55ccee, 0x44bbdd, 0x33aacc, 0x2299bb, 0x1188aa],
    mountain: 0x447755, hill: 0x55aa66, waterColor: 0x33aaaa,
    // Enhanced palette for parallax layers
    background: 0x87CEEB,   // Sky blue
    foreground: 0x228B22,   // Forest green
    midground: 0x32CD32,    // Lime green
    vegetation: [0x7FFF00, 0x006400, 0x2E8B57],  // Chartreuse, dark green, sea green
    accent: 0xFFFF00,       // Yellow
    fog: 0xF0F8FF           // Alice blue mist
  },
  // World 3: Cueva de Cristal (Level 5 Boss) - Dark mysterious cave
  3: {
    name: 'Crystal Cave',
    subtitle: 'Cueva de Cristal',
    sky: [0x334466, 0x223355, 0x112244, 0x001133, 0x000022, 0x000011],
    mountain: 0x112233, hill: 0x223355, waterColor: 0x224466,
    // Enhanced palette for parallax layers
    background: 0x191970,   // Midnight blue
    foreground: 0x483D8B,   // Dark slate blue
    midground: 0x6A5ACD,    // Slate blue
    vegetation: [0x9370DB, 0x8A2BE2, 0x4B0082],  // Medium purple, blue violet, indigo
    accent: 0x00FFFF,       // Cyan (crystals)
    fog: 0xE6E6FA           // Lavender mist
  },
  // World 4: Jardines Flotantes (Levels 6-7) - Golden sunset
  4: {
    name: 'Floating Gardens',
    subtitle: 'Jardines Flotantes',
    sky: [0xffbb77, 0xff9955, 0xff7744, 0xee5533, 0xcc4422, 0x993311],
    mountain: 0x335544, hill: 0x77aa55, waterColor: 0x668877,
    // Enhanced palette for parallax layers
    background: 0xFF8C00,   // Dark orange
    foreground: 0x8B4513,   // Saddle brown
    midground: 0xCD853F,    // Peru
    vegetation: [0xDAA520, 0xB8860B, 0xFF6347],  // Goldenrod, dark goldenrod, tomato
    accent: 0xFF4500,       // Orange red
    fog: 0xFFDAB9           // Peach puff mist
  },
  // World 5: Canales de Noche (Levels 8-9) - Moonlit night, purple
  5: {
    name: 'Night Canals',
    subtitle: 'Canales de Noche',
    sky: [0x223355, 0x112244, 0x001133, 0x001122, 0x000011, 0x000000],
    mountain: 0x112233, hill: 0x223344, waterColor: 0x113344,
    // Enhanced palette for parallax layers
    background: 0x000080,   // Navy
    foreground: 0x2F4F4F,   // Dark slate gray
    midground: 0x708090,    // Slate gray
    vegetation: [0x4682B4, 0x5F9EA0, 0x00CED1],  // Steel blue, cadet blue, dark turquoise
    accent: 0xC0C0C0,       // Silver (moonlight)
    fog: 0xF8F8FF           // Ghost white mist
  },
  // World 6: La Fiesta Final (Levels 11-12) - Ultimate celebration!
  6: {
    name: 'La Fiesta',
    subtitle: 'The Final Celebration',
    sky: [0xFFD700, 0xFFA500, 0xFF69B4, 0xFF1493, 0x9400D3, 0x4B0082],
    mountain: 0xFF6347, hill: 0xFF69B4, waterColor: 0x40E0D0,
    // Enhanced palette for parallax layers
    background: 0xFF69B4,   // Hot pink sunset
    foreground: 0xFFD700,   // Gold
    midground: 0xFFA500,    // Orange
    vegetation: [0xFF1493, 0x00FF00, 0xFFFF00],  // Pink, green, yellow - festive!
    accent: 0xFFFFFF,       // White sparkles
    fog: 0xFFE4E1           // Misty rose
  }
};

// Get world number from level number
function getWorldForLevel(levelNum) {
  if (levelNum <= 2) return 1;   // Canal Dawn
  if (levelNum <= 4) return 2;   // Bright Trajineras
  if (levelNum <= 6) return 3;   // Crystal Cave
  if (levelNum <= 8) return 4;   // Floating Gardens
  if (levelNum <= 10) return 5;  // Night Canals
  return 6;                      // La Fiesta (celebration only)
}

// Check if this is the first level of a new world
function isFirstLevelOfWorld(levelNum) {
  return levelNum === 1 || levelNum === 3 || levelNum === 5 || levelNum === 6 || levelNum === 8 || levelNum === 10;
}

// Get the first level of a given world
function getFirstLevelOfWorld(worldNum) {
  switch(worldNum) {
    case 1: return 1;   // Canal Dawn
    case 2: return 3;   // Bright Trajineras
    case 3: return 5;   // Crystal Cave
    case 4: return 7;   // Floating Gardens
    case 5: return 9;   // Night Canals
    case 6: return 11;  // La Fiesta Final
    default: return 1;
  }
}

// Get checkpoint level (first level of current world)
function getCheckpointLevel(currentLevel) {
  const world = getWorldForLevel(currentLevel);
  return getFirstLevelOfWorld(world);
}

// Get level type description
function getLevelTypeDescription(levelNum) {
  if (levelNum === 11) return 'LA FIESTA!';
  if (levelNum === 5) return 'BOSS BATTLE';
  if (levelNum === 10) return 'FINAL BOSS';
  if (levelNum === 3 || levelNum === 8) return 'CLIMB!';
  if (levelNum === 9) return 'ESCAPE!';
  return 'CROSS THE CANALS';
}

// Get theme for a level (consistent within world)
function getThemeForLevel(levelNum) {
  const worldNum = getWorldForLevel(levelNum);
  return { ...WORLDS[worldNum], isWaterLevel: true, worldNum };
}

// ============== PIECE 5: WORLD-SPECIFIC PARTICLE ATMOSPHERE ==============
// Creates atmospheric particles unique to each world
// Max 50 particles total, using Phaser tweens for movement/animation
function createWorldParticles(scene, theme, levelWidth, levelHeight) {
  const particles = [];
  const worldNum = theme.worldNum || 1;

  switch(worldNum) {
    case 1: // Dawn - Morning mist + pink petals
      // 20 mist particles: circles 4-6px, #FFD4A3, alpha 0.3, slow horizontal drift
      for (let i = 0; i < 20; i++) {
        const px = Phaser.Math.Between(0, levelWidth);
        const py = Phaser.Math.Between(100, levelHeight - 100);
        const size = Phaser.Math.Between(4, 6);
        const gfx = scene.add.circle(px, py, size, 0xFFD4A3, 0.3);
        gfx.setScrollFactor(0.4 + Math.random() * 0.2);
        particles.push({
          gfx, type: 'mist', x: px, y: py, baseX: px, baseY: py,
          phase: Math.random() * Math.PI * 2,
          driftSpeed: 0.3 + Math.random() * 0.2
        });
      }
      // 15 petals: rectangles 4x6px, #FFB5D8, flutter fall with rotation
      for (let i = 0; i < 15; i++) {
        const px = Phaser.Math.Between(0, levelWidth);
        const py = Phaser.Math.Between(-50, levelHeight - 100);
        const gfx = scene.add.rectangle(px, py, 4, 6, 0xFFB5D8, 0.8);
        gfx.setScrollFactor(0.5 + Math.random() * 0.3);
        gfx.setAngle(Phaser.Math.Between(0, 360));
        particles.push({
          gfx, type: 'petal', x: px, y: py, baseX: px, baseY: py,
          phase: Math.random() * Math.PI * 2,
          fallSpeed: 0.5 + Math.random() * 0.3,
          rotSpeed: 1 + Math.random() * 2,
          swayAmp: 30 + Math.random() * 20
        });
      }
      break;

    case 2: // Day - Dust motes + butterflies
      // 30 dust motes: circles 2px, #FFFACD, alpha 0.4, brownian motion
      for (let i = 0; i < 30; i++) {
        const px = Phaser.Math.Between(0, levelWidth);
        const py = Phaser.Math.Between(50, levelHeight - 50);
        const gfx = scene.add.circle(px, py, 2, 0xFFFACD, 0.4);
        gfx.setScrollFactor(0.3 + Math.random() * 0.3);
        particles.push({
          gfx, type: 'dustmote', x: px, y: py, baseX: px, baseY: py,
          phase: Math.random() * Math.PI * 2,
          vx: 0, vy: 0, // velocity for brownian motion
          brownianStrength: 0.5 + Math.random() * 0.5
        });
      }
      // 5 butterflies: two circles connected, #FFD700/#FF69B4, swooping figure-8
      for (let i = 0; i < 5; i++) {
        const px = Phaser.Math.Between(100, levelWidth - 100);
        const py = Phaser.Math.Between(100, levelHeight - 150);
        const container = scene.add.container(px, py);
        const color = i % 2 === 0 ? 0xFFD700 : 0xFF69B4;
        const wing1 = scene.add.circle(-4, 0, 4, color, 0.9);
        const wing2 = scene.add.circle(4, 0, 4, color, 0.9);
        const body = scene.add.ellipse(0, 0, 3, 6, 0x333333, 1);
        container.add([wing1, wing2, body]);
        container.setScrollFactor(0.6);
        particles.push({
          gfx: container, type: 'butterfly', x: px, y: py, baseX: px, baseY: py,
          phase: Math.random() * Math.PI * 2,
          figure8Speed: 0.5 + Math.random() * 0.3,
          figure8Width: 80 + Math.random() * 40,
          figure8Height: 40 + Math.random() * 20,
          wingFlap: 0
        });
      }
      break;

    case 3: // Cave - Water drops + crystal sparkles
      // 15 drops: circles 2px, #87CEEB, fall straight down 120px/sec
      for (let i = 0; i < 15; i++) {
        const px = Phaser.Math.Between(0, levelWidth);
        const py = Phaser.Math.Between(-100, levelHeight / 2);
        const gfx = scene.add.circle(px, py, 2, 0x87CEEB, 0.8);
        gfx.setScrollFactor(0.7);
        particles.push({
          gfx, type: 'waterdrop', x: px, y: py, baseX: px, baseY: py,
          fallSpeed: 120 // px per second
        });
      }
      // 20 sparkles: cross shapes 4px, #E0BBE4, static with alpha pulse
      for (let i = 0; i < 20; i++) {
        const px = Phaser.Math.Between(50, levelWidth - 50);
        const py = Phaser.Math.Between(50, levelHeight - 100);
        const container = scene.add.container(px, py);
        const h = scene.add.rectangle(0, 0, 4, 1, 0xE0BBE4, 1);
        const v = scene.add.rectangle(0, 0, 1, 4, 0xE0BBE4, 1);
        container.add([h, v]);
        container.setScrollFactor(0.5 + Math.random() * 0.3);
        // Alpha pulse tween
        scene.tweens.add({
          targets: [h, v],
          alpha: 0.3,
          duration: 1000 + Math.random() * 1000,
          yoyo: true,
          repeat: -1,
          ease: 'Sine.easeInOut',
          delay: Math.random() * 1000
        });
        particles.push({
          gfx: container, type: 'sparkle', x: px, y: py, baseX: px, baseY: py,
          isStatic: true
        });
      }
      break;

    case 4: // Sunset - Falling leaves + floating seeds
      // 20 leaves: rectangles 5x8px, #FFD700/#FF8C00, tumbling fall with rotation
      for (let i = 0; i < 20; i++) {
        const px = Phaser.Math.Between(0, levelWidth);
        const py = Phaser.Math.Between(-100, levelHeight - 100);
        const color = i % 2 === 0 ? 0xFFD700 : 0xFF8C00;
        const gfx = scene.add.rectangle(px, py, 5, 8, color, 0.9);
        gfx.setScrollFactor(0.5 + Math.random() * 0.3);
        gfx.setAngle(Phaser.Math.Between(0, 360));
        particles.push({
          gfx, type: 'leaf', x: px, y: py, baseX: px, baseY: py,
          phase: Math.random() * Math.PI * 2,
          fallSpeed: 0.8 + Math.random() * 0.5,
          rotSpeed: 2 + Math.random() * 3,
          tumbleAmp: 40 + Math.random() * 30
        });
      }
      // 15 seeds: ovals 2x4px, #F0E68C, slow spiral upward
      for (let i = 0; i < 15; i++) {
        const px = Phaser.Math.Between(0, levelWidth);
        const py = Phaser.Math.Between(levelHeight / 2, levelHeight);
        const gfx = scene.add.ellipse(px, py, 2, 4, 0xF0E68C, 0.7);
        gfx.setScrollFactor(0.4 + Math.random() * 0.2);
        particles.push({
          gfx, type: 'seed', x: px, y: py, baseX: px, baseY: py,
          phase: Math.random() * Math.PI * 2,
          riseSpeed: 0.3 + Math.random() * 0.2,
          spiralRadius: 15 + Math.random() * 10,
          spiralSpeed: 1 + Math.random() * 0.5
        });
      }
      break;

    case 5: // Night - Fireflies + purple sparkles
      // 25 fireflies: circles 2px with 6px glow, #FFFF99, lazy float + alpha pulse
      for (let i = 0; i < 25; i++) {
        const px = Phaser.Math.Between(0, levelWidth);
        const py = Phaser.Math.Between(50, levelHeight - 100);
        const container = scene.add.container(px, py);
        const glow = scene.add.circle(0, 0, 6, 0xFFFF99, 0.3);
        const core = scene.add.circle(0, 0, 2, 0xFFFF99, 0.9);
        container.add([glow, core]);
        container.setScrollFactor(0.5 + Math.random() * 0.3);
        // Alpha pulse for glow
        scene.tweens.add({
          targets: glow,
          alpha: 0.1,
          duration: 800 + Math.random() * 400,
          yoyo: true,
          repeat: -1,
          ease: 'Sine.easeInOut',
          delay: Math.random() * 500
        });
        particles.push({
          gfx: container, type: 'firefly', x: px, y: py, baseX: px, baseY: py,
          phase: Math.random() * Math.PI * 2,
          floatSpeed: 0.3 + Math.random() * 0.2,
          floatRadius: 20 + Math.random() * 15
        });
      }
      // 15 sparkles: circles 3px, #DDA0DD, drift upward slowly
      for (let i = 0; i < 15; i++) {
        const px = Phaser.Math.Between(0, levelWidth);
        const py = Phaser.Math.Between(levelHeight / 2, levelHeight);
        const gfx = scene.add.circle(px, py, 3, 0xDDA0DD, 0.6);
        gfx.setScrollFactor(0.4 + Math.random() * 0.2);
        particles.push({
          gfx, type: 'purplesparkle', x: px, y: py, baseX: px, baseY: py,
          phase: Math.random() * Math.PI * 2,
          riseSpeed: 0.2 + Math.random() * 0.15,
          driftAmp: 10 + Math.random() * 10
        });
      }
      break;

    case 6: // Festival - Confetti + flower petals
      // 25 confetti: rectangles 3x5px, rainbow colors, chaotic fall with spin
      const confettiColors = [0xFF0000, 0xFF7F00, 0xFFFF00, 0x00FF00, 0x0000FF, 0x4B0082, 0x9400D3, 0xFF69B4, 0x00FFFF];
      for (let i = 0; i < 25; i++) {
        const px = Phaser.Math.Between(0, levelWidth);
        const py = Phaser.Math.Between(-200, levelHeight - 100);
        const color = confettiColors[i % confettiColors.length];
        const gfx = scene.add.rectangle(px, py, 3, 5, color, 0.9);
        gfx.setScrollFactor(0.5 + Math.random() * 0.3);
        gfx.setAngle(Phaser.Math.Between(0, 360));
        particles.push({
          gfx, type: 'confetti', x: px, y: py, baseX: px, baseY: py,
          phase: Math.random() * Math.PI * 2,
          fallSpeed: 1 + Math.random() * 0.8,
          spinSpeed: 5 + Math.random() * 10,
          swayAmp: 50 + Math.random() * 30,
          swayFreq: 2 + Math.random() * 2
        });
      }
      // 15 petals: rectangles 6x8px, #FF69B4, gentle spiral fall
      for (let i = 0; i < 15; i++) {
        const px = Phaser.Math.Between(0, levelWidth);
        const py = Phaser.Math.Between(-100, levelHeight - 100);
        const gfx = scene.add.rectangle(px, py, 6, 8, 0xFF69B4, 0.85);
        gfx.setScrollFactor(0.5 + Math.random() * 0.3);
        gfx.setAngle(Phaser.Math.Between(0, 360));
        particles.push({
          gfx: gfx, type: 'festivalpetal', x: px, y: py, baseX: px, baseY: py,
          phase: Math.random() * Math.PI * 2,
          fallSpeed: 0.6 + Math.random() * 0.3,
          rotSpeed: 1.5 + Math.random() * 1,
          spiralRadius: 25 + Math.random() * 15,
          spiralSpeed: 0.8 + Math.random() * 0.4
        });
      }
      break;

    default:
      // Fallback: basic dust
      for (let i = 0; i < 25; i++) {
        const px = Phaser.Math.Between(0, levelWidth);
        const py = Phaser.Math.Between(100, levelHeight - 100);
        const gfx = scene.add.circle(px, py, 2, 0xffffff, 0.3);
        gfx.setScrollFactor(0.5 + Math.random() * 0.3);
        particles.push({
          gfx, type: 'dust', x: px, y: py, baseX: px, baseY: py,
          phase: Math.random() * Math.PI * 2,
          driftSpeed: 0.1 + Math.random() * 0.2
        });
      }
  }

  return particles;
}

// Update function for world particles - call in scene update()
function updateWorldParticles(particles, time, delta, levelWidth, levelHeight) {
  if (!particles || particles.length === 0) return;

  const dt = delta / 1000; // Convert to seconds

  particles.forEach(p => {
    if (p.isStatic) return; // Static particles (like cave sparkles) don't move

    switch(p.type) {
      case 'mist':
        // Slow horizontal drift with slight vertical sway
        p.x += p.driftSpeed * dt * 60;
        p.y = p.baseY + Math.sin(time / 2000 + p.phase) * 10;
        if (p.x > levelWidth + 50) {
          p.x = -50;
          p.baseX = p.x;
        }
        p.gfx.setPosition(p.x, p.y);
        break;

      case 'petal':
        // Flutter fall with rotation
        p.y += p.fallSpeed * dt * 60;
        p.x = p.baseX + Math.sin(time / 500 + p.phase) * p.swayAmp;
        p.gfx.setAngle(p.gfx.angle + p.rotSpeed * dt * 60);
        if (p.y > levelHeight + 50) {
          p.y = -50;
          p.x = Phaser.Math.Between(0, levelWidth);
          p.baseX = p.x;
        }
        p.gfx.setPosition(p.x, p.y);
        break;

      case 'dustmote':
        // Brownian motion
        p.vx += (Math.random() - 0.5) * p.brownianStrength * dt * 60;
        p.vy += (Math.random() - 0.5) * p.brownianStrength * dt * 60;
        p.vx *= 0.98; // Damping
        p.vy *= 0.98;
        p.x += p.vx;
        p.y += p.vy;
        // Keep within bounds
        if (p.x < 0 || p.x > levelWidth) p.vx *= -1;
        if (p.y < 0 || p.y > levelHeight) p.vy *= -1;
        p.x = Phaser.Math.Clamp(p.x, 0, levelWidth);
        p.y = Phaser.Math.Clamp(p.y, 50, levelHeight - 50);
        p.gfx.setPosition(p.x, p.y);
        break;

      case 'butterfly':
        // Figure-8 pattern
        p.phase += p.figure8Speed * dt;
        p.x = p.baseX + Math.sin(p.phase) * p.figure8Width;
        p.y = p.baseY + Math.sin(p.phase * 2) * p.figure8Height;
        // Wing flap animation
        p.wingFlap += dt * 15;
        const wingScale = 0.7 + Math.abs(Math.sin(p.wingFlap)) * 0.3;
        if (p.gfx.list && p.gfx.list[0]) {
          p.gfx.list[0].setScale(wingScale, 1); // Left wing
          p.gfx.list[1].setScale(wingScale, 1); // Right wing
        }
        p.gfx.setPosition(p.x, p.y);
        break;

      case 'waterdrop':
        // Fall straight down at 120px/sec
        p.y += p.fallSpeed * dt;
        if (p.y > levelHeight + 20) {
          p.y = -20;
          p.x = Phaser.Math.Between(0, levelWidth);
        }
        p.gfx.setPosition(p.x, p.y);
        break;

      case 'leaf':
        // Tumbling fall with rotation
        p.y += p.fallSpeed * dt * 60;
        p.x = p.baseX + Math.sin(time / 400 + p.phase) * p.tumbleAmp;
        p.gfx.setAngle(p.gfx.angle + p.rotSpeed * dt * 60);
        if (p.y > levelHeight + 50) {
          p.y = -50;
          p.x = Phaser.Math.Between(0, levelWidth);
          p.baseX = p.x;
        }
        p.gfx.setPosition(p.x, p.y);
        break;

      case 'seed':
        // Slow spiral upward
        p.phase += p.spiralSpeed * dt;
        p.y -= p.riseSpeed * dt * 60;
        p.x = p.baseX + Math.sin(p.phase) * p.spiralRadius;
        if (p.y < -30) {
          p.y = levelHeight + 30;
          p.x = Phaser.Math.Between(0, levelWidth);
          p.baseX = p.x;
        }
        p.gfx.setPosition(p.x, p.y);
        break;

      case 'firefly':
        // Lazy float in random directions
        p.phase += p.floatSpeed * dt;
        p.x = p.baseX + Math.sin(p.phase) * p.floatRadius;
        p.y = p.baseY + Math.cos(p.phase * 0.7) * p.floatRadius * 0.8;
        // Slowly drift baseX/baseY
        p.baseX += (Math.random() - 0.5) * 0.5;
        p.baseY += (Math.random() - 0.5) * 0.3;
        // Keep in bounds
        p.baseX = Phaser.Math.Clamp(p.baseX, 50, levelWidth - 50);
        p.baseY = Phaser.Math.Clamp(p.baseY, 50, levelHeight - 100);
        p.gfx.setPosition(p.x, p.y);
        break;

      case 'purplesparkle':
        // Drift upward slowly with horizontal sway
        p.y -= p.riseSpeed * dt * 60;
        p.x = p.baseX + Math.sin(time / 1000 + p.phase) * p.driftAmp;
        if (p.y < -30) {
          p.y = levelHeight + 30;
          p.x = Phaser.Math.Between(0, levelWidth);
          p.baseX = p.x;
        }
        p.gfx.setPosition(p.x, p.y);
        break;

      case 'confetti':
        // Chaotic fall with spin
        p.y += p.fallSpeed * dt * 60;
        p.x = p.baseX + Math.sin(time / (500 / p.swayFreq) + p.phase) * p.swayAmp;
        p.gfx.setAngle(p.gfx.angle + p.spinSpeed * dt * 60);
        if (p.y > levelHeight + 50) {
          p.y = -100;
          p.x = Phaser.Math.Between(0, levelWidth);
          p.baseX = p.x;
        }
        p.gfx.setPosition(p.x, p.y);
        break;

      case 'festivalpetal':
        // Gentle spiral fall
        p.phase += p.spiralSpeed * dt;
        p.y += p.fallSpeed * dt * 60;
        p.x = p.baseX + Math.sin(p.phase) * p.spiralRadius;
        p.gfx.setAngle(p.gfx.angle + p.rotSpeed * dt * 60);
        if (p.y > levelHeight + 50) {
          p.y = -50;
          p.x = Phaser.Math.Between(0, levelWidth);
          p.baseX = p.x;
        }
        p.gfx.setPosition(p.x, p.y);
        break;

      case 'dust':
      default:
        // Basic floating dust
        p.y += Math.sin(time / 1000 + p.phase) * 0.3;
        p.x += p.driftSpeed * dt * 60;
        if (p.x > levelWidth + 50) {
          p.x = -50;
        }
        p.gfx.setPosition(p.x, p.y);
        break;
    }
  });
}

// ============== PIECE 6: PLATFORM VISUAL ENHANCEMENT ==============
// Makes platforms beautiful with depth effects and world-specific decorations
function enhancePlatform(scene, platformData, theme, physicsPlat) {
  const p = platformData;
  const worldNum = theme.worldNum || 1;
  const isGround = p.h > 30;
  const isCave = worldNum === 3;

  // ========== DEPTH EFFECTS (all platforms) ==========

  // Top highlight: 2px line, white 30% alpha, along top edge
  scene.add.rectangle(p.x + p.w/2, p.y + 1, p.w - 2, 2, 0xffffff, 0.3);

  // Bottom shadow: 3px gradient effect, black 40%->0% alpha, below platform
  scene.add.rectangle(p.x + p.w/2, p.y + p.h + 1, p.w, 1, 0x000000, 0.4);
  scene.add.rectangle(p.x + p.w/2, p.y + p.h + 2, p.w, 1, 0x000000, 0.25);
  scene.add.rectangle(p.x + p.w/2, p.y + p.h + 3, p.w, 1, 0x000000, 0.1);

  // Side edges: 1px darker lines for thickness
  scene.add.rectangle(p.x + 1, p.y + p.h/2, 1, p.h, 0x000000, 0.25);
  scene.add.rectangle(p.x + p.w - 1, p.y + p.h/2, 1, p.h, 0x000000, 0.25);

  // ========== WORLD-SPECIFIC DECORATIONS ==========

  if (isCave) {
    // Cave platforms: Crystal accents + mossy edges
    // Crystal accents: 4-point stars 4-6px, purple/lavender, at corners
    const crystalColors = [0xE0BBE4, 0xD8BFD8, 0xDDA0DD];
    if (p.w > 40) {
      // Left corner crystal
      createCrystalStar(scene, p.x + 8, p.y - 2, Phaser.Math.Between(4, 6), crystalColors[0]);
      // Right corner crystal
      createCrystalStar(scene, p.x + p.w - 8, p.y - 2, Phaser.Math.Between(4, 6), crystalColors[1]);
    }
    // Mossy edges: irregular circles 3-5px, sea green, at platform ends
    for (let i = 0; i < 3; i++) {
      const mossSize = Phaser.Math.Between(3, 5);
      scene.add.circle(p.x + 5 + i * 4, p.y + p.h - 3, mossSize, 0x20B2AA, 0.6);
      scene.add.circle(p.x + p.w - 5 - i * 4, p.y + p.h - 3, mossSize, 0x20B2AA, 0.5);
    }
  } else if (isGround) {
    // Ground platforms: Deep grass + small rocks
    // Deep grass: dense vertical lines 1px wide, 5-7px tall, every 3-4px
    const grassColors = [0x228B22, 0x2E8B57, 0x3CB371, 0x228B22];
    for (let gx = p.x + 3; gx < p.x + p.w - 3; gx += Phaser.Math.Between(3, 4)) {
      const grassHeight = Phaser.Math.Between(5, 7);
      const grassColor = grassColors[Math.floor(Math.random() * grassColors.length)];
      scene.add.rectangle(gx, p.y - grassHeight/2, 1, grassHeight, grassColor, 0.8);
    }
    // Small rocks: circles 2-4px, gray variants, scattered 4-6 per 100px
    const rocksPerSection = Math.floor(p.w / 100) * Phaser.Math.Between(4, 6);
    for (let i = 0; i < rocksPerSection; i++) {
      const rockX = p.x + Phaser.Math.Between(10, p.w - 10);
      const rockY = p.y + Phaser.Math.Between(5, p.h - 5);
      const rockSize = Phaser.Math.Between(2, 4);
      const grayShade = Phaser.Math.Between(0x60, 0x90);
      const rockColor = (grayShade << 16) | (grayShade << 8) | grayShade;
      scene.add.circle(rockX, rockY, rockSize, rockColor, 0.5);
    }
  } else {
    // Floating garden platforms (chinampas): Flower borders + grass tufts
    // Flower borders: 3-4px circles, pink/yellow/magenta, every 30-40px along top
    const flowerColors = [0xFF69B4, 0xFFD700, 0xFF00FF, 0xFFA500, 0xFF6347];
    for (let fx = p.x + 15; fx < p.x + p.w - 15; fx += Phaser.Math.Between(30, 40)) {
      const flowerSize = Phaser.Math.Between(3, 4);
      const flowerColor = flowerColors[Math.floor(Math.random() * flowerColors.length)];
      scene.add.circle(fx, p.y - 3, flowerSize, flowerColor, 0.9);
      // Add tiny center
      scene.add.circle(fx, p.y - 3, 1, 0xFFFF00, 1);
    }
    // Grass tufts: vertical rectangles 2x6px, groups of 3-5, green variants
    const grassTuftColors = [0x228B22, 0x32CD32, 0x3CB371];
    for (let tx = p.x + 20; tx < p.x + p.w - 20; tx += Phaser.Math.Between(35, 50)) {
      const tuftCount = Phaser.Math.Between(3, 5);
      for (let t = 0; t < tuftCount; t++) {
        const tuftColor = grassTuftColors[Math.floor(Math.random() * grassTuftColors.length)];
        const tuftHeight = Phaser.Math.Between(5, 7);
        const tuft = scene.add.rectangle(tx + t * 3 - (tuftCount * 1.5), p.y - tuftHeight/2, 2, tuftHeight, tuftColor, 0.9);
        tuft.setAngle(Phaser.Math.Between(-10, 10));
      }
    }
  }

  // ========== BREATHING ANIMATION ==========
  // Scale pulse: 1.0 to 1.02 over 3 seconds, Sine.easeInOut
  // Random phase offset per platform
  // Visual only - hitbox unchanged
  if (physicsPlat && !isGround) {
    const phaseOffset = Math.random() * 3000; // Random offset 0-3 seconds
    scene.tweens.add({
      targets: physicsPlat,
      scaleX: 1.02,
      scaleY: 1.02,
      duration: 3000,
      yoyo: true,
      repeat: -1,
      ease: 'Sine.easeInOut',
      delay: phaseOffset
    });
  }
}

// Helper function to create a 4-point crystal star
function createCrystalStar(scene, x, y, size, color) {
  const container = scene.add.container(x, y);
  // Horizontal line
  const h = scene.add.rectangle(0, 0, size, 2, color, 0.9);
  // Vertical line
  const v = scene.add.rectangle(0, 0, 2, size, color, 0.9);
  container.add([h, v]);
  // Add subtle glow effect
  scene.tweens.add({
    targets: [h, v],
    alpha: 0.5,
    duration: 1500 + Math.random() * 500,
    yoyo: true,
    repeat: -1,
    ease: 'Sine.easeInOut'
  });
  return container;
}


// ============ SIX-LAYER PARALLAX BACKGROUND SYSTEM ============
// Creates atmospheric depth with procedurally drawn layers
function buildParallaxLayers(scene, theme, levelWidth, levelHeight) {
  const layers = [];

  // Helper to darken/desaturate colors for distant layers
  function adjustColorForDepth(color, depthFactor) {
    const r = (color >> 16) & 0xff;
    const g = (color >> 8) & 0xff;
    const b = color & 0xff;
    // Blend toward a muted blue-gray for distance
    const fogR = 0x88, fogG = 0x99, fogB = 0xaa;
    const newR = Math.floor(r + (fogR - r) * depthFactor);
    const newG = Math.floor(g + (fogG - g) * depthFactor);
    const newB = Math.floor(b + (fogB - b) * depthFactor);
    return (newR << 16) | (newG << 8) | newB;
  }

  // Get colors from theme with fallbacks
  const mountainColor = theme.mountain || 0x446655;
  const hillColor = theme.hill || 0x558866;
  const foregroundColor = theme.foreground || 0x8B4513;
  const midgroundColor = theme.midground || 0xD2691E;
  const vegetationColors = theme.vegetation || [0x9ACD32, 0x228B22, 0x6B8E23];
  const fogColor = theme.fog || 0xFFF5E6;

  // ============ LAYER 1: FAR MOUNTAINS (0.05x scroll, alpha 0.3) ============
  // Distant silhouettes, most desaturated
  const farMountains = scene.add.graphics();
  const farMountainColor = adjustColorForDepth(mountainColor, 0.6);
  farMountains.fillStyle(farMountainColor, 0.3);

  // Draw jagged mountain silhouettes across the level width
  for (let i = 0; i < levelWidth / 200 + 4; i++) {
    const mx = i * 200 - 150 + Phaser.Math.Between(-30, 30);
    const mh = 150 + Phaser.Math.Between(50, 120);
    const baseY = levelHeight - 100;

    // Draw mountain as filled polygon (triangle with slight variation)
    farMountains.beginPath();
    farMountains.moveTo(mx, baseY);
    farMountains.lineTo(mx + 80 + Phaser.Math.Between(-20, 20), baseY - mh);
    farMountains.lineTo(mx + 100, baseY - mh * 0.7); // Secondary peak
    farMountains.lineTo(mx + 130, baseY - mh * 0.85);
    farMountains.lineTo(mx + 200, baseY);
    farMountains.closePath();
    farMountains.fillPath();
  }
  farMountains.setScrollFactor(0.05);
  farMountains.setDepth(-100);
  layers.push(farMountains);

  // ============ LAYER 2: MID MOUNTAINS (0.15x scroll, alpha 0.5) ============
  // Closer peaks with more definition
  const midMountains = scene.add.graphics();
  const midMountainColor = adjustColorForDepth(mountainColor, 0.35);
  midMountains.fillStyle(midMountainColor, 0.5);

  for (let i = 0; i < levelWidth / 180 + 3; i++) {
    const mx = i * 180 - 100 + Phaser.Math.Between(-25, 25);
    const mh = 100 + Phaser.Math.Between(40, 100);
    const baseY = levelHeight - 90;

    // Draw slightly different mountain shapes
    midMountains.beginPath();
    midMountains.moveTo(mx, baseY);
    midMountains.lineTo(mx + 60, baseY - mh * 0.6);
    midMountains.lineTo(mx + 90, baseY - mh);
    midMountains.lineTo(mx + 120, baseY - mh * 0.5);
    midMountains.lineTo(mx + 180, baseY);
    midMountains.closePath();
    midMountains.fillPath();
  }
  midMountains.setScrollFactor(0.15);
  midMountains.setDepth(-95);
  layers.push(midMountains);

  // ============ LAYER 3: ROLLING HILLS (0.25x scroll, alpha 0.65) ============
  // Soft curved hills using bezier-like shapes
  const rollingHills = scene.add.graphics();
  const hillLayerColor = adjustColorForDepth(hillColor, 0.2);
  rollingHills.fillStyle(hillLayerColor, 0.65);

  // Draw overlapping elliptical hills
  for (let i = 0; i < levelWidth / 140 + 3; i++) {
    const hx = i * 140 - 50 + Phaser.Math.Between(-20, 20);
    const hw = 160 + Phaser.Math.Between(-20, 40);
    const hh = 70 + Phaser.Math.Between(-10, 30);
    const baseY = levelHeight - 60;

    rollingHills.fillEllipse(hx + hw / 2, baseY, hw, hh);
  }
  rollingHills.setScrollFactor(0.25);
  rollingHills.setDepth(-90);
  layers.push(rollingHills);

  // ============ LAYER 4: VEGETATION/TREES (0.4x scroll, alpha 0.8) ============
  // Tree and plant silhouettes
  const vegetation = scene.add.graphics();

  for (let i = 0; i < levelWidth / 60 + 5; i++) {
    const tx = i * 60 - 30 + Phaser.Math.Between(-15, 15);
    const treeType = Phaser.Math.Between(0, 2);
    const treeColor = vegetationColors[treeType];
    const baseY = levelHeight - 50;

    vegetation.fillStyle(treeColor, 0.8);

    if (treeType === 0) {
      // Tall tree (triangle/pine shape)
      const th = 50 + Phaser.Math.Between(10, 40);
      vegetation.beginPath();
      vegetation.moveTo(tx - 20, baseY);
      vegetation.lineTo(tx, baseY - th);
      vegetation.lineTo(tx + 20, baseY);
      vegetation.closePath();
      vegetation.fillPath();
      // Trunk
      vegetation.fillStyle(midgroundColor, 0.8);
      vegetation.fillRect(tx - 4, baseY, 8, 15);
    } else if (treeType === 1) {
      // Round tree (circle canopy)
      const th = 35 + Phaser.Math.Between(5, 25);
      vegetation.fillCircle(tx, baseY - th, 25 + Phaser.Math.Between(-5, 10));
      // Trunk
      vegetation.fillStyle(midgroundColor, 0.8);
      vegetation.fillRect(tx - 5, baseY - 15, 10, 20);
    } else {
      // Bush/shrub (multiple small circles)
      const bushSize = 20 + Phaser.Math.Between(-5, 10);
      vegetation.fillCircle(tx - 10, baseY - bushSize * 0.5, bushSize * 0.6);
      vegetation.fillCircle(tx, baseY - bushSize * 0.7, bushSize * 0.7);
      vegetation.fillCircle(tx + 12, baseY - bushSize * 0.5, bushSize * 0.5);
    }
  }
  vegetation.setScrollFactor(0.4);
  vegetation.setDepth(-85);
  layers.push(vegetation);

  // ============ LAYER 5: MIST BANDS (0.6x scroll, alpha 0.4) ============
  // Horizontal fog bands for atmosphere
  const mistBands = scene.add.graphics();
  mistBands.fillStyle(fogColor, 0.4);

  // Draw several horizontal fog bands at different heights
  const mistHeights = [
    levelHeight - 120,
    levelHeight - 180,
    levelHeight - 250
  ];

  for (const mistY of mistHeights) {
    // Draw fog as overlapping ellipses for organic look
    for (let mx = -100; mx < levelWidth + 200; mx += 80 + Phaser.Math.Between(-20, 20)) {
      const mw = 150 + Phaser.Math.Between(-30, 50);
      const mh = 25 + Phaser.Math.Between(-5, 15);
      const yOffset = Phaser.Math.Between(-10, 10);
      mistBands.fillEllipse(mx, mistY + yOffset, mw, mh);
    }
  }
  mistBands.setScrollFactor(0.6);
  mistBands.setDepth(-80);
  layers.push(mistBands);

  // ============ LAYER 6: FOREGROUND GRASS (0.8x scroll, alpha 1.0) ============
  // Grass tufts at the bottom of the screen
  const foregroundGrass = scene.add.graphics();
  foregroundGrass.fillStyle(foregroundColor, 1.0);

  const grassBaseY = levelHeight - 20;

  for (let gx = -20; gx < levelWidth + 50; gx += 12 + Phaser.Math.Between(-3, 3)) {
    const grassHeight = 15 + Phaser.Math.Between(5, 20);
    const grassWidth = 4 + Phaser.Math.Between(-1, 2);
    const lean = Phaser.Math.Between(-3, 3);

    // Draw grass blade as a thin triangle
    foregroundGrass.beginPath();
    foregroundGrass.moveTo(gx - grassWidth, grassBaseY);
    foregroundGrass.lineTo(gx + lean, grassBaseY - grassHeight);
    foregroundGrass.lineTo(gx + grassWidth, grassBaseY);
    foregroundGrass.closePath();
    foregroundGrass.fillPath();

    // Add some variation with secondary smaller blades
    if (Phaser.Math.Between(0, 2) === 0) {
      const smallHeight = grassHeight * 0.6;
      foregroundGrass.beginPath();
      foregroundGrass.moveTo(gx + 5, grassBaseY);
      foregroundGrass.lineTo(gx + 5 + lean * 0.5, grassBaseY - smallHeight);
      foregroundGrass.lineTo(gx + 8, grassBaseY);
      foregroundGrass.closePath();
      foregroundGrass.fillPath();
    }
  }
  foregroundGrass.setScrollFactor(0.8);
  foregroundGrass.setDepth(-75);
  layers.push(foregroundGrass);

  return layers;
}

// Mexican trajinera names - fun and colorful!
const TRAJINERA_NAMES = [
  'La Lupita', 'El Sol', 'Frida', 'La Estrella', 'Amor Eterno',
  'La Rosa', 'El Mariachi', 'Corazón', 'La Luna', 'Esperanza',
  'Alegría', 'Mi Cielo', 'La Paloma', 'El Jardín', 'Dulce María',
  'La Sirena', 'El Azteca', 'Mariposa', 'La Catrina', 'Xochitl'
];

// Get random trajinera name
function getTrajineraName() {
  return TRAJINERA_NAMES[Math.floor(Math.random() * TRAJINERA_NAMES.length)];
}

// Trajinera colors - bright Mexican palette
const TRAJINERA_COLORS = [
  0xff6b6b,  // Red
  0x4ecdc4,  // Turquoise
  0xffe66d,  // Yellow
  0xc44569,  // Pink
  0xf78fb3,  // Light pink
  0x3dc1d3,  // Cyan
  0xf5cd79,  // Gold
  0x778beb,  // Purple
  0x63cdda,  // Sky blue
  0xe77f67   // Orange
];

// LEGACY: Keep THEMES array for backwards compatibility
const THEMES = Object.values(WORLDS);

// ============== LEVEL GENERATION TENETS ==============
// 1. SUPER JUMP enables huge gaps (300-500px) and sky-high platforms
// 2. Powerups placed BEFORE difficult gaps, proportional to gap difficulty
// 3. Multiple paths: main road (safe) + sky road (risky but rewarding)
// 4. Risk/reward: harder platforms have more coins/stars
// 5. Every level is completable without super jump (but slower/boring)
// 6. Secret sky platforms require super jump, contain bonus stars

// Calculate jump difficulty (how hard is this gap?)
function calculateGapDifficulty(gapX, gapY) {
  // Normal jump: ~200px horizontal, ~120px up
  // Super jump: ~400px horizontal, ~250px up
  const normalJumpX = 200;
  const normalJumpY = 120;
  const superJumpX = 400;
  const superJumpY = 250;

  const xDifficulty = gapX / normalJumpX;
  const yDifficulty = Math.max(0, gapY) / normalJumpY; // Only count upward

  // If beyond normal jump, it's a "super jump required" gap
  const requiresSuper = gapX > normalJumpX * 1.2 || gapY > normalJumpY * 1.2;

  return {
    score: xDifficulty + yDifficulty * 0.8,
    requiresSuper,
    xDifficulty,
    yDifficulty
  };
}

// ============== PIECE 3: DYNAMIC DENSITY RULES ==============

/**
 * Calculate density multipliers based on level number.
 * Controls enemy, platform, and coin density to create difficulty progression.
 * @param {number} levelNum - Current level number (1-10)
 * @returns {Object} - { enemies: number, platforms: number, coins: number }
 */
function calculateDensityMultipliers(levelNum) {
  if (levelNum <= 2) {
    // Early levels: Fewer enemies, more platforms for safety, normal coins
    return { enemies: 0.7, platforms: 1.2, coins: 1.0 };
  } else if (levelNum <= 5) {
    // Mid-early levels: Balanced enemies/platforms, more coins as reward
    return { enemies: 1.0, platforms: 1.0, coins: 1.2 };
  } else if (levelNum <= 8) {
    // Mid-late levels: Challenging but fair, fewer platforms
    return { enemies: 1.15, platforms: 0.9, coins: 1.3 };
  } else {
    // Final levels (9-10): Intense but not overwhelming, minimal platforms, maximum coins
    return { enemies: 1.15, platforms: 0.85, coins: 1.5 };
  }
}

/**
 * Generate breathing room zones - safe areas with NO enemies.
 * Spacing increases with level difficulty to reduce safe zones in harder levels.
 * @param {number} levelWidth - Total width of the level
 * @param {number} levelNum - Current level number (1-10)
 * @returns {Array} - Array of { startX, endX, centerX } for each safe zone
 */
function getBreathingRoomZones(levelWidth, levelNum) {
  let spacing;
  if (levelNum <= 2) {
    spacing = 400;  // Breathing room every 400px - lots of safe zones
  } else if (levelNum <= 5) {
    spacing = 600;  // Every 600px
  } else if (levelNum <= 8) {
    spacing = 850;  // Every 850px
  } else {
    spacing = 900;  // Every 900px - more breathing rooms for intense final levels
  }

  const breathingWidth = 200; // Each breathing room is 200px wide
  const zones = [];

  // Start after intro section (300px) and end before outro section
  const startX = 300 + spacing;
  const endX = levelWidth - 300;

  for (let centerX = startX; centerX < endX; centerX += spacing) {
    zones.push({
      startX: centerX - breathingWidth / 2,
      endX: centerX + breathingWidth / 2,
      centerX: centerX
    });
  }

  return zones;
}

/**
 * Check if a position is inside any breathing room zone.
 * Used to filter out enemies that would spawn in safe zones.
 * @param {number} x - X position to check
 * @param {Array} zones - Array of breathing room zones
 * @returns {boolean} - True if position is inside a breathing room
 */
function isInBreathingRoom(x, zones) {
  return zones.some(zone => x >= zone.startX && x <= zone.endX);
}

// ============== PIECE 4: HANDCRAFTED INTRO/OUTRO SECTIONS ==============

/**
 * Create handcrafted intro section for the first 300px of a level.
 * Teaches direction and feels safe for new players.
 * @param {number} levelNum - Current level number (1-10)
 * @param {Object} theme - Level theme object
 * @param {number} waterY - Y position of water (for positioning)
 * @returns {Object} - { platforms: [], enemies: [], coins: [] }
 */
function createIntroSection(levelNum, theme, waterY) {
  const platforms = [];
  const enemies = [];
  const coins = [];

  const baseY = waterY - 100;

  if (levelNum <= 2) {
    // Level 1-2: Wide 200px platform, 1 easy enemy, 5 coins in arc
    platforms.push({
      x: 0,
      y: baseY,
      w: 200,
      h: 150,
      isChihampa: true
    });

    // Single enemy at edge of intro (not too early)
    enemies.push({
      x: 250,
      y: baseY - 50,
      type: 'flying',
      amplitude: 30,
      speed: 30,
      dir: 1
    });

    // 5 coins in arc pattern - teaches upward movement
    for (let i = 0; i < 5; i++) {
      const arcX = 50 + i * 40;
      const arcY = baseY - 40 - Math.sin((i / 4) * Math.PI) * 60;
      coins.push({ x: arcX, y: arcY });
    }

  } else if (levelNum <= 5) {
    // Level 3-5: 180px platform, 2 enemies, 8 coins in S-curve
    platforms.push({
      x: 0,
      y: baseY,
      w: 180,
      h: 150,
      isChihampa: true
    });

    // 2 enemies - one low, one higher
    enemies.push({
      x: 220,
      y: baseY - 30,
      type: 'flying',
      amplitude: 25,
      speed: 35,
      dir: 1
    });
    enemies.push({
      x: 280,
      y: baseY - 120,
      type: 'flying',
      amplitude: 30,
      speed: 40,
      dir: -1
    });

    // 8 coins in S-curve pattern
    for (let i = 0; i < 8; i++) {
      const sX = 30 + i * 35;
      const sY = baseY - 50 - Math.sin((i / 7) * Math.PI * 2) * 40;
      coins.push({ x: sX, y: sY });
    }

  } else {
    // Level 6-10: 150px platform, 2 enemies, 10 coins in spiral
    platforms.push({
      x: 0,
      y: baseY,
      w: 150,
      h: 150,
      isChihampa: true
    });

    // 2 enemies positioned strategically
    enemies.push({
      x: 200,
      y: baseY - 40,
      type: 'flying',
      amplitude: 35,
      speed: 45,
      dir: 1
    });
    enemies.push({
      x: 260,
      y: baseY - 100,
      type: 'flying',
      amplitude: 30,
      speed: 50,
      dir: -1
    });

    // 10 coins in expanding spiral pattern
    for (let i = 0; i < 10; i++) {
      const angle = (i / 10) * Math.PI * 1.5;
      const radius = 30 + i * 8;
      const spiralX = 80 + Math.cos(angle) * radius;
      const spiralY = baseY - 60 - Math.sin(angle) * radius * 0.6;
      coins.push({ x: spiralX, y: spiralY });
    }
  }

  return { platforms, enemies, coins };
}

/**
 * Create handcrafted outro section for the last 300px of a level.
 * Features wide platform before baby, guard enemies, and arrow-shaped coin pattern.
 * @param {number} levelNum - Current level number (1-10)
 * @param {number} levelWidth - Total level width
 * @param {Object} theme - Level theme object
 * @param {number} waterY - Y position of water (for positioning)
 * @returns {Object} - { platforms: [], enemies: [], coins: [] }
 */
function createOutroSection(levelNum, theme, levelWidth, waterY) {
  const platforms = [];
  const enemies = [];
  const coins = [];

  const baseY = waterY - 100;
  const outroStart = levelWidth - 300;

  // Wide 250px platform before baby - safe landing zone
  platforms.push({
    x: levelWidth - 250,
    y: baseY,
    w: 250,
    h: 150,
    isChihampa: true
  });

  // Guard enemies - symmetrically placed, 2-3 based on difficulty
  const numGuards = levelNum <= 5 ? 2 : 3;
  const guardSpacing = 200 / (numGuards + 1);

  for (let i = 0; i < numGuards; i++) {
    const guardX = outroStart + 50 + (i + 1) * guardSpacing;
    const guardY = baseY - 80 - (i % 2) * 60; // Alternating heights

    enemies.push({
      x: guardX,
      y: guardY,
      type: 'flying',
      amplitude: 25 + levelNum * 2,
      speed: 35 + levelNum * 3,
      dir: i % 2 === 0 ? 1 : -1
    });
  }

  // Coins arranged in arrow pointing to baby (> shape)
  // Arrow points right toward the baby at levelWidth
  const arrowTipX = levelWidth - 80;
  const arrowBaseX = levelWidth - 180;
  const arrowCenterY = baseY - 60;

  // Arrow tip (center coin)
  coins.push({ x: arrowTipX, y: arrowCenterY });

  // Upper diagonal (2 coins)
  coins.push({ x: arrowBaseX + 30, y: arrowCenterY - 25 });
  coins.push({ x: arrowBaseX, y: arrowCenterY - 50 });

  // Lower diagonal (2 coins)
  coins.push({ x: arrowBaseX + 30, y: arrowCenterY + 25 });
  coins.push({ x: arrowBaseX, y: arrowCenterY + 50 });

  return { platforms, enemies, coins };
}

/**
 * Filter out enemies that spawn inside breathing room zones.
 * @param {Array} enemies - Array of enemy objects with x positions
 * @param {Array} breathingZones - Array of breathing room zones
 * @returns {Array} - Filtered array of enemies outside breathing rooms
 */
function filterEnemiesFromBreathingRooms(enemies, breathingZones) {
  return enemies.filter(enemy => !isInBreathingRoom(enemy.x, breathingZones));
}

// Generate a random level based on level number
function generateLevel(levelNum) {
  const levelDifficulty = Math.min(levelNum / 10, 1); // 0.1 to 1.0
  const settings = DIFFICULTY_SETTINGS[gameState.difficulty];
  const width = 2000 + levelNum * 200;
  const height = 600;
  const waterY = height - 40;  // Water at bottom - fall in = death!

  // Use consistent world theme
  const theme = getThemeForLevel(levelNum);

  // ============ GET DENSITY MULTIPLIERS AND BREATHING ROOMS ============
  const density = calculateDensityMultipliers(levelNum);
  const breathingZones = getBreathingRoomZones(width, levelNum);

  // ============ HANDCRAFTED INTRO SECTION (first 300px) ============
  const intro = createIntroSection(levelNum, theme, waterY);

  // ============ HANDCRAFTED OUTRO SECTION (last 300px) ============
  const outro = createOutroSection(levelNum, theme, width, waterY);

  // Combine intro and outro platforms
  const platforms = [...intro.platforms, ...outro.platforms];
  const trajineras = [];
  const coins = [...intro.coins, ...outro.coins];
  const stars = [];
  const enemies = [];
  const powerups = [];

  // ============ TRAJINERAS IN MIDDLE SECTION (300px to width-300px) ============
  // This creates a lively, dynamic level where EVERYTHING moves!

  const speedMult = 1 + levelNum * 0.08;  // Slightly faster each level
  const middleStart = 300;
  const middleEnd = width - 300;
  const middleWidth = middleEnd - middleStart;

  // Define 5-6 lanes of trajineras at different heights
  // Apply platform density multiplier to boat counts
  const lanes = [
    { y: waterY - 80,  dir: 1,  baseSpeed: 30, boats: Math.floor((5 + levelNum) * density.platforms) },
    { y: waterY - 150, dir: -1, baseSpeed: 40, boats: Math.floor((4 + levelNum) * density.platforms) },
    { y: waterY - 220, dir: 1,  baseSpeed: 50, boats: Math.floor((4 + levelNum) * density.platforms) },
    { y: waterY - 290, dir: -1, baseSpeed: 45, boats: Math.floor((3 + levelNum) * density.platforms) },
    { y: waterY - 360, dir: 1,  baseSpeed: 55, boats: Math.floor((3 + levelNum) * density.platforms) },
    { y: waterY - 420, dir: -1, baseSpeed: 35, boats: Math.floor((2 + Math.floor(levelNum/2)) * density.platforms) },
  ];

  let nameIdx = 0;
  lanes.forEach((lane, laneIdx) => {
    const spacing = middleWidth / Math.max(1, lane.boats);

    for (let i = 0; i < lane.boats; i++) {
      // Stagger boats so they don't all start aligned
      const startOffset = (i * spacing) + (laneIdx % 2 === 0 ? 0 : spacing / 2);
      const xPos = middleStart + startOffset;

      // Vary boat sizes - bigger boats are easier to land on
      const boatW = 100 + Math.random() * 60;

      trajineras.push({
        x: xPos,
        y: lane.y + (Math.random() - 0.5) * 20,  // Slight y variation
        w: boatW,
        h: 28,
        speed: (lane.baseSpeed + Math.random() * 25) * speedMult,
        dir: lane.dir,
        color: TRAJINERA_COLORS[(laneIdx * 3 + i) % TRAJINERA_COLORS.length],
        name: TRAJINERA_NAMES[nameIdx % TRAJINERA_NAMES.length],
        startX: xPos,
        lane: laneIdx + 1
      });
      nameIdx++;
    }
  });

  // ============ COINS IN MIDDLE SECTION - Apply density multiplier ============
  const baseCoinCount = Math.floor((15 + levelNum * 3) * density.coins);
  for (let i = 0; i < baseCoinCount; i++) {
    const coinX = middleStart + Math.random() * middleWidth;
    const coinY = waterY - 100 - Math.random() * 350;
    coins.push({ x: coinX, y: coinY });
  }

  // ============ STARS - 3 per level at different heights (in middle section) ============
  stars.push({ x: middleStart + middleWidth * 0.2, y: waterY - 180 });   // Low star
  stars.push({ x: middleStart + middleWidth * 0.5, y: waterY - 300 });   // Mid star
  stars.push({ x: middleStart + middleWidth * 0.8, y: waterY - 400 });   // High star (risky!)

  // ============ FLYING ENEMIES IN MIDDLE SECTION - Apply density multiplier ============
  const baseEnemyCount = Math.floor((2 + levelDifficulty * 3) * settings.enemyMult * density.enemies);
  const middleEnemies = [];
  for (let i = 0; i < baseEnemyCount; i++) {
    middleEnemies.push({
      x: middleStart + 100 + (i * (middleWidth - 200) / Math.max(1, baseEnemyCount)),
      y: waterY - 200 - Math.random() * 200,
      type: 'flying',
      amplitude: 40 + Math.random() * 40,
      speed: 40 + Math.random() * 40,
      dir: i % 2 === 0 ? 1 : -1
    });
  }

  // Filter enemies from breathing room zones and add intro/outro enemies
  const filteredMiddleEnemies = filterEnemiesFromBreathingRooms(middleEnemies, breathingZones);
  enemies.push(...intro.enemies, ...filteredMiddleEnemies, ...outro.enemies);

  // ============ POWERUPS - help the player! ============
  const numPowerups = Math.floor((3 + levelDifficulty * 2) * settings.powerupMult);
  // One on start
  powerups.push({ x: 150, y: waterY - 140 });
  // Scattered through middle section
  for (let i = 1; i < numPowerups; i++) {
    powerups.push({
      x: middleStart + i * (middleWidth / numPowerups),
      y: waterY - 150 - Math.random() * 250
    });
  }
  // One on final platform
  powerups.push({ x: width - 120, y: waterY - 140 });

  return {
    width,
    height,
    playerSpawn: { x: 100, y: waterY - 150 },
    babyPosition: { x: width - 125, y: waterY - 150 },  // BABY ON FINAL PLATFORM!
    platforms,
    trajineras,  // Now the main gameplay element!
    coins,
    stars,
    enemies,
    powerups,
    theme,
    waterY,  // Water level for death detection
    breathingZones  // For debugging/visualization if needed
  };
}

// Generate boss arena (fixed layout for fair fights)
function generateBossArena(levelNum) {
  const isFinalBoss = levelNum === 10;
  const width = isFinalBoss ? 1000 : 800;
  const height = 600;
  const groundY = height - 50;

  return {
    width,
    height,
    playerSpawn: { x: 100, y: groundY - 50 },
    babyPosition: { x: width / 2, y: 150 }, // Baby appears after boss defeated
    platforms: [
      { x: 0, y: groundY, w: width, h: 50 }, // Ground
      { x: 100, y: groundY - 150, w: 120, h: 20 }, // Left platform
      { x: width - 220, y: groundY - 150, w: 120, h: 20 }, // Right platform
      { x: width / 2 - 80, y: groundY - 250, w: 160, h: 20 }, // Center high platform
    ],
    coins: [],
    stars: [],
    enemies: [],
    powerups: [
      { x: 160, y: groundY - 190 },
      { x: width - 160, y: groundY - 190 }
    ],
    theme: getThemeForLevel(levelNum), // Use proper world theme for boss
    isBossLevel: true
  };
}

// Generate Xochimilco Frogger-style level - hop across trajineras (boats)!
function generateFroggerLevel(levelNum) {
  const width = 1800;  // Not too wide
  const height = 600;
  const waterY = 550;  // Water at very bottom
  const settings = DIFFICULTY_SETTINGS[gameState.difficulty];

  // Use consistent world theme
  const theme = getThemeForLevel(levelNum);

  // Static platforms - START and END chinampas above water
  const platforms = [
    // Starting chinampa - safe ground!
    { x: 0, y: waterY - 100, w: 180, h: 100, isChihampa: true },
    // Final chinampa with baby - goal!
    { x: width - 200, y: waterY - 100, w: 200, h: 100, isChihampa: true }
  ];

  // ============ TRAJINERA LANES - Classic Frogger style! ============
  // 4 lanes with ALTERNATING directions - learn the patterns!
  const trajineras = [];
  const speedMult = 1 + (levelNum - 3) * 0.1;  // Gentle speed increase

  // Lanes from bottom to top - player hops upward across boats
  const lanes = [
    { y: waterY - 160, dir: 1,  speed: 35, boats: 4 },   // Lane 1: → slowest, most boats
    { y: waterY - 220, dir: -1, speed: 45, boats: 4 },   // Lane 2: ←
    { y: waterY - 280, dir: 1,  speed: 55, boats: 3 },   // Lane 3: →
    { y: waterY - 340, dir: -1, speed: 40, boats: 3 },   // Lane 4: ← to goal
  ];

  lanes.forEach((lane, laneIdx) => {
    const laneWidth = width - 300;
    const spacing = laneWidth / lane.boats;

    for (let i = 0; i < lane.boats; i++) {
      const startOffset = (laneIdx % 2 === 0) ? 0 : spacing / 3;
      const xPos = 150 + startOffset + i * spacing;

      trajineras.push({
        x: xPos,
        y: lane.y,
        w: 100 + Math.random() * 30,  // Bigger boats = easier to land
        h: 25,
        speed: (lane.speed + Math.random() * 15) * speedMult,
        dir: lane.dir,
        color: TRAJINERA_COLORS[(laneIdx * 3 + i) % TRAJINERA_COLORS.length],
        name: getTrajineraName(),
        startX: xPos,
        lane: laneIdx + 1
      });
    }
  });

  // Coins on the path
  const coins = [
    { x: 80, y: waterY - 140 },
    { x: 500, y: waterY - 180 },
    { x: 900, y: waterY - 240 },
    { x: 1300, y: waterY - 300 },
    { x: width - 100, y: waterY - 140 }
  ];

  // Stars - collect while crossing!
  const stars = [
    { x: 600, y: waterY - 180 },
    { x: 1000, y: waterY - 300 },
    { x: width - 100, y: waterY - 200 }
  ];

  // Few flying enemies - don't make it too hard!
  const enemies = [];
  const numFlying = Math.floor((1 + levelNum * 0.3) * settings.enemyMult);
  for (let i = 0; i < numFlying; i++) {
    enemies.push({
      x: 400 + i * 500,
      y: waterY - 400,  // High above the lanes
      type: 'flying',
      amplitude: 30,
      speed: 40,
      dir: i % 2 === 0 ? 1 : -1
    });
  }

  // Powerups - one on start, one on goal
  const powerups = [
    { x: 100, y: waterY - 140 },      // Starting platform
    { x: width - 100, y: waterY - 140 }  // Goal platform
  ];

  return {
    width,
    height,
    playerSpawn: { x: 90, y: waterY - 150 },  // On starting platform
    babyPosition: { x: width - 100, y: waterY - 150 },  // On goal platform!
    platforms,
    trajineras,
    coins,
    stars,
    enemies,
    powerups,
    theme,
    isFroggerLevel: true,
    waterY
  };
}

// Generate Xochimilco UPSCROLLER level - climb the ancient aqueduct!
function generateUpscrollerLevel(levelNum) {
  const width = 600;  // Narrower for vertical gameplay
  const height = 2500 + levelNum * 200;  // TALL level!
  const settings = DIFFICULTY_SETTINGS[gameState.difficulty];

  // Use consistent world theme
  const theme = { ...getThemeForLevel(levelNum), isUpscroller: true };

  // ============ GET DENSITY MULTIPLIERS ============
  // For vertical levels, we use density for platform/enemy counts
  const density = calculateDensityMultipliers(levelNum);

  // Vertical breathing zones - horizontal bands where enemies don't spawn
  // Spacing is based on height, not width
  const verticalBreathingSpacing = levelNum <= 2 ? 400 : levelNum <= 5 ? 600 : levelNum <= 8 ? 800 : 1000;

  const platforms = [];
  const trajineras = [];  // Horizontal moving boats at different heights
  const coins = [];
  const stars = [];
  const enemies = [];
  const powerups = [];

  // ============ INTRO SECTION (bottom 300 height) - Safe start ============
  // Starting platform at bottom - safe ground to begin (wider for early levels)
  const introPlatformWidth = levelNum <= 2 ? 200 : levelNum <= 5 ? 180 : 150;
  platforms.push({
    x: width / 2 - introPlatformWidth / 2,
    y: height - 50,
    w: introPlatformWidth,
    h: 50,
    isChihampa: true
  });

  // Intro coins in arc pattern
  const introCoins = levelNum <= 2 ? 5 : levelNum <= 5 ? 8 : 10;
  for (let i = 0; i < introCoins; i++) {
    const arcX = width / 2 + (i - introCoins / 2) * 30;
    const arcY = height - 90 - Math.sin((i / (introCoins - 1)) * Math.PI) * 40;
    coins.push({ x: arcX, y: arcY });
  }

  // IMMEDIATE POWERUP on starting platform - you need it!
  powerups.push({ x: width / 2, y: height - 90 });

  // First platform is GUARANTEED and easy to reach - no RNG death!
  const firstPlatY = height - 170;
  platforms.push({
    x: width / 2 - 70,
    y: firstPlatY,
    w: 140,
    h: 25,
    isChihampa: true
  });
  coins.push({ x: width / 2, y: firstPlatY - 30 });

  // Second platform also guaranteed - build momentum!
  const secondPlatY = height - 290;
  trajineras.push({
    x: width / 2,
    y: secondPlatY,
    w: 120,
    h: 25,
    speed: 40,
    dir: 1,
    color: TRAJINERA_COLORS[0],
    startX: width / 2
  });

  // ============ MIDDLE SECTION - Apply density rules ============
  let currentY = height - 400;
  let lastX = width / 2;

  // Adjust platform type probabilities based on density
  const chinampaChance = 0.2 * density.platforms;  // More static platforms = easier
  const trajineraChance = 0.5;  // Keep trajineras consistent for gameplay

  while (currentY > 150) {
    const platformType = Math.random();

    if (platformType < chinampaChance) {
      // Static chinampa (safe zone)
      const platW = 90 + Math.random() * 50;
      const platX = Math.max(40, Math.min(width - platW - 40, lastX + (Math.random() - 0.5) * 200));
      platforms.push({
        x: platX,
        y: currentY,
        w: platW,
        h: 20,
        isChihampa: true
      });
      lastX = platX + platW / 2;

      // Coins on platform - apply coin density
      const platformCoins = Math.ceil(density.coins);
      for (let c = 0; c < platformCoins; c++) {
        coins.push({ x: platX + platW / 2 + (c - platformCoins / 2) * 20, y: currentY - 30 });
      }

    } else if (platformType < chinampaChance + trajineraChance) {
      // Moving trajinera (horizontal boat)
      const boatW = 100 + Math.random() * 50;
      const dir = Math.random() < 0.5 ? 1 : -1;
      trajineras.push({
        x: Math.random() * (width - 100) + 50,
        y: currentY,
        w: boatW,
        h: 25,
        speed: 50 + Math.random() * 50 + levelNum * 5,
        dir: dir,
        color: [0xff6b6b, 0x4ecdc4, 0xffe66d, 0xc44569, 0xf78fb3, 0x3dc1d3][Math.floor(Math.random() * 6)],
        startX: Math.random() * (width - 100) + 50
      });
      lastX = width / 2;

    } else {
      // Lily pad
      const padW = 60 + Math.random() * 30;
      const padX = Math.max(30, Math.min(width - padW - 30, lastX + (Math.random() - 0.5) * 180));
      platforms.push({
        x: padX,
        y: currentY,
        w: padW,
        h: 15,
        isLilypad: true
      });
      lastX = padX + padW / 2;
    }

    // Vertical gap between platforms
    const gap = 90 + Math.random() * 50 + levelNum * 3;
    currentY -= gap;

    // Add powerup periodically
    if (Math.random() < 0.2 * settings.powerupMult) {
      powerups.push({ x: lastX, y: currentY + gap / 2 });
    }
  }

  // ============ OUTRO SECTION (top 150 height) - Final challenge ============
  // Final platform with baby at top
  platforms.push({
    x: width / 2 - 60,
    y: 80,
    w: 120,
    h: 25,
    isChihampa: true
  });

  // Arrow-shaped coins pointing up to baby
  coins.push({ x: width / 2, y: 120 });  // Tip
  coins.push({ x: width / 2 - 20, y: 140 });
  coins.push({ x: width / 2 + 20, y: 140 });
  coins.push({ x: width / 2 - 40, y: 160 });
  coins.push({ x: width / 2 + 40, y: 160 });

  // Stars at various heights
  stars.push({ x: width / 2, y: height - 500 });  // Lower third
  stars.push({ x: width / 2, y: height / 2 });     // Middle
  stars.push({ x: width / 2, y: 250 });            // Near top

  // GUARANTEED POWERUPS at key heights
  powerups.push({ x: width / 2 - 50, y: height - 600 });
  powerups.push({ x: width / 2 + 50, y: height / 2 });
  powerups.push({ x: width / 2, y: 350 });

  // ============ FLYING ENEMIES - Apply density and breathing room ============
  const baseEnemyCount = Math.floor((1 + levelNum * 0.3) * settings.enemyMult * density.enemies);
  for (let i = 0; i < baseEnemyCount; i++) {
    const enemyY = height - 600 - i * ((height - 750) / Math.max(1, baseEnemyCount));

    // Check if enemy is in a breathing zone (horizontal band)
    const inBreathingZone = Math.floor(enemyY / verticalBreathingSpacing) % 2 === 0;

    if (!inBreathingZone) {
      enemies.push({
        x: Math.random() * (width - 100) + 50,
        y: enemyY,
        type: 'flying',
        amplitude: 30 + Math.random() * 40,
        speed: 50 + Math.random() * 40,
        dir: Math.random() < 0.5 ? 1 : -1
      });
    }
  }

  // ============ ALLIGATORS - DKC2 style water danger! ============
  const alligators = [];
  const numGators = Math.floor((2 + Math.floor(levelNum * 0.5)) * density.enemies);
  for (let i = 0; i < numGators; i++) {
    alligators.push({
      x: 50 + Math.random() * (width - 100),
      baseY: 30 + i * 40,
      speed: 40 + Math.random() * 30,
      dir: i % 2 === 0 ? 1 : -1
    });
  }

  return {
    width,
    height,
    playerSpawn: { x: width / 2, y: height - 100 },
    babyPosition: { x: width / 2, y: 50 },
    platforms,
    trajineras,
    coins,
    stars,
    enemies,
    powerups,
    alligators,
    theme,
    isUpscroller: true,
    waterY: height - 20
  };
}

// ============== ESCAPE LEVEL - Indiana Jones / Brave Fencer Musashi style! ==============
// A giant flood/wave chases you from behind - RUN FOR YOUR LIFE!
function generateEscapeLevel(levelNum) {
  const settings = DIFFICULTY_SETTINGS[gameState.difficulty];
  const width = 3500 + levelNum * 300;  // Long level - it's a chase!
  const height = 600;
  const waterY = height - 40;

  const theme = { ...getThemeForLevel(levelNum), isEscapeLevel: true };

  // ============ GET DENSITY MULTIPLIERS AND BREATHING ROOMS ============
  const density = calculateDensityMultipliers(levelNum);
  const breathingZones = getBreathingRoomZones(width, levelNum);

  const platforms = [];
  const trajineras = [];
  const coins = [];
  const stars = [];
  const enemies = [];
  const powerups = [];

  // ============ INTRO SECTION (first 300px) - Safe start before the chase ============
  // Starting platform - wider for early levels
  const introPlatformWidth = levelNum <= 2 ? 300 : levelNum <= 5 ? 280 : 250;
  platforms.push({
    x: 0,
    y: waterY - 80,
    w: introPlatformWidth,
    h: 130,
    isChihampa: true
  });

  // Intro coins in arc pattern - teaches "go right!"
  const introCoins = levelNum <= 2 ? 5 : levelNum <= 5 ? 8 : 10;
  for (let i = 0; i < introCoins; i++) {
    const arcX = 50 + i * 30;
    const arcY = waterY - 120 - Math.sin((i / (introCoins - 1)) * Math.PI) * 50;
    coins.push({ x: arcX, y: arcY });
  }

  // Intro enemy (1 for easy, 2 for harder)
  const introEnemies = levelNum <= 2 ? 1 : 2;
  for (let i = 0; i < introEnemies; i++) {
    enemies.push({
      x: 250 + i * 50,
      y: waterY - 150 - i * 40,
      type: 'flying',
      amplitude: 25,
      speed: 35,
      dir: 1
    });
  }

  // ============ MIDDLE SECTION - The chase! Apply density rules ============
  let currentX = 350;
  const escapeSpeed = levelNum === 9 ? 1.15 : 1.0;  // Level 9 is faster!
  const middleEnd = width - 400;

  while (currentX < middleEnd) {
    const segmentType = Math.random();

    // Adjust segment probabilities based on platform density
    const trajineraChance = 0.4;
    const chinamppaChance = 0.3 * density.platforms;

    if (segmentType < trajineraChance) {
      // Trajinera lane section - multiple boats moving
      const numBoats = Math.floor((2 + Math.random() * 3) * density.platforms);
      const laneY = waterY - 60 - Math.random() * 80;

      for (let i = 0; i < numBoats; i++) {
        const boatW = 100 + Math.random() * 50;
        trajineras.push({
          x: currentX + i * 180,
          y: laneY + (Math.random() - 0.5) * 30,
          w: boatW,
          h: 28,
          speed: (30 + Math.random() * 25) * escapeSpeed,
          dir: i % 2 === 0 ? 1 : -1,
          color: TRAJINERA_COLORS[Math.floor(Math.random() * TRAJINERA_COLORS.length)],
          name: getTrajineraName(),
          startX: currentX + i * 180
        });

        // Coins on boats - apply coin density
        const coinsPerBoat = Math.ceil(density.coins);
        for (let c = 0; c < coinsPerBoat; c++) {
          coins.push({ x: currentX + i * 180 + (c - coinsPerBoat / 2) * 15, y: laneY - 35 });
        }
      }
      currentX += numBoats * 180 + 100;

    } else if (segmentType < trajineraChance + chinamppaChance) {
      // Small chinampa stepping stones - quick hops!
      const numStones = Math.floor((3 + Math.random() * 3) * density.platforms);
      for (let i = 0; i < numStones; i++) {
        const stoneW = 70 + Math.random() * 40;
        const stoneY = waterY - 60 - Math.random() * 100;
        platforms.push({
          x: currentX + i * 140,
          y: stoneY,
          w: stoneW,
          h: 25,
          isChihampa: true
        });

        if (Math.random() < 0.5 * density.coins) {
          coins.push({ x: currentX + i * 140 + stoneW/2, y: stoneY - 35 });
        }
      }
      currentX += numStones * 140 + 80;

    } else {
      // Mixed section - trajinera + platform combo
      const platY = waterY - 100 - Math.random() * 80;
      platforms.push({
        x: currentX,
        y: platY,
        w: 90 + Math.random() * 40,
        h: 22,
        isChihampa: true
      });

      // Trajinera after platform
      trajineras.push({
        x: currentX + 200,
        y: waterY - 50,
        w: 120 + Math.random() * 40,
        h: 28,
        speed: (35 + Math.random() * 20) * escapeSpeed,
        dir: Math.random() < 0.5 ? 1 : -1,
        color: TRAJINERA_COLORS[Math.floor(Math.random() * TRAJINERA_COLORS.length)],
        name: getTrajineraName(),
        startX: currentX + 200
      });

      // Apply coin density
      const sectionCoins = Math.ceil(2 * density.coins);
      coins.push({ x: currentX + 45, y: platY - 35 });
      if (sectionCoins > 1) {
        coins.push({ x: currentX + 200, y: waterY - 85 });
      }
      currentX += 350;
    }

    // Occasional powerup
    if (Math.random() < 0.15 * settings.powerupMult) {
      powerups.push({
        x: currentX - 100,
        y: waterY - 150 - Math.random() * 100
      });
    }
  }

  // ============ OUTRO SECTION (last 400px) - Final sprint to safety ============
  // Final safe platform with baby - YOU MADE IT!
  platforms.push({
    x: width - 350,
    y: waterY - 80,
    w: 350,
    h: 130,
    isChihampa: true
  });

  // Guard enemies before the final platform
  const numGuards = levelNum <= 5 ? 2 : 3;
  const outroStart = width - 350;
  for (let i = 0; i < numGuards; i++) {
    enemies.push({
      x: outroStart - 150 - i * 80,
      y: waterY - 150 - (i % 2) * 50,
      type: 'flying',
      amplitude: 25 + levelNum * 2,
      speed: 40 + levelNum * 3,
      dir: i % 2 === 0 ? 1 : -1
    });
  }

  // Arrow-shaped coins pointing to baby
  const arrowTipX = width - 80;
  const arrowBaseX = width - 180;
  const arrowCenterY = waterY - 120;
  coins.push({ x: arrowTipX, y: arrowCenterY });
  coins.push({ x: arrowBaseX + 30, y: arrowCenterY - 25 });
  coins.push({ x: arrowBaseX, y: arrowCenterY - 50 });
  coins.push({ x: arrowBaseX + 30, y: arrowCenterY + 25 });
  coins.push({ x: arrowBaseX, y: arrowCenterY + 50 });

  // Stars spread across the escape route (in middle section)
  const middleStart = 350;
  const middleWidth = middleEnd - middleStart;
  stars.push({ x: middleStart + middleWidth * 0.2, y: waterY - 150 });
  stars.push({ x: middleStart + middleWidth * 0.5, y: waterY - 200 });
  stars.push({ x: middleStart + middleWidth * 0.8, y: waterY - 120 });

  // ============ FLYING ENEMIES IN MIDDLE - Apply density and breathing rooms ============
  const baseEnemyCount = Math.floor(2 * settings.enemyMult * density.enemies);
  const middleEnemies = [];
  for (let i = 0; i < baseEnemyCount; i++) {
    middleEnemies.push({
      x: middleStart + 450 + i * (middleWidth / Math.max(1, baseEnemyCount + 1)),
      y: waterY - 250 - Math.random() * 100,
      type: 'flying',
      amplitude: 30,
      speed: 50,
      dir: 1  // All fly forward (same direction as player)
    });
  }

  // Filter enemies from breathing room zones
  const filteredMiddleEnemies = filterEnemiesFromBreathingRooms(middleEnemies, breathingZones);
  enemies.push(...filteredMiddleEnemies);

  // Powerup at start and near end
  powerups.push({ x: 150, y: waterY - 120 });
  powerups.push({ x: width - 200, y: waterY - 120 });

  return {
    width,
    height,
    playerSpawn: { x: 150, y: waterY - 130 },
    babyPosition: { x: width - 175, y: waterY - 130 },
    platforms,
    trajineras,
    coins,
    stars,
    enemies,
    powerups,
    theme,
    isEscapeLevel: true,
    escapeSpeed: levelNum === 9 ? 150 : 120,  // Level 9 flood is faster!
    waterY,
    breathingZones  // For debugging/visualization if needed
  };
}

// Generate LA FIESTA - Final celebration level! No enemies, all joy!
function generateFiestaLevel() {
  const width = 3000;  // Wide celebration area
  const height = 600;
  const waterY = height - 40;

  // Festive theme - brightest colors!
  const theme = {
    sky: [0x87CEEB, 0xFFD700, 0xFFA500, 0xFF69B4],  // Sunset fiesta colors
    water: 0x40E0D0,
    waterHighlight: 0x7FFFD4,
    platform: 0xFFD700,  // Golden platforms
    accent: 0xFF1493
  };

  const platforms = [];
  const trajineras = [];
  const coins = [];  // Flowers everywhere!
  const stars = [];
  const enemies = [];  // NO ENEMIES - pure celebration!
  const powerups = [];

  // ============ INTRO - Welcome to La Fiesta! ============
  // Starting platform - decorated with flowers
  platforms.push({ x: 50, y: waterY - 60, w: 200, h: 40, isChihampa: true });

  // Flower arch at entrance
  for (let i = 0; i < 15; i++) {
    const arcX = 150 + i * 20;
    const arcY = waterY - 100 - Math.sin((i / 14) * Math.PI) * 100;
    coins.push({ x: arcX, y: arcY });
  }

  // ============ TRAJINERA PARADE - Beautiful boats everywhere! ============
  const lanes = [
    { y: waterY - 80,  dir: 1,  baseSpeed: 25, boats: 12 },
    { y: waterY - 140, dir: -1, baseSpeed: 30, boats: 10 },
    { y: waterY - 200, dir: 1,  baseSpeed: 35, boats: 10 },
    { y: waterY - 260, dir: -1, baseSpeed: 28, boats: 8 },
    { y: waterY - 320, dir: 1,  baseSpeed: 32, boats: 8 },
    { y: waterY - 380, dir: -1, baseSpeed: 22, boats: 6 },
  ];

  let nameIdx = 0;
  lanes.forEach((lane, laneIdx) => {
    const spacing = (width - 600) / Math.max(1, lane.boats);

    for (let i = 0; i < lane.boats; i++) {
      const startOffset = (i * spacing) + (laneIdx % 2 === 0 ? 0 : spacing / 2);
      const xPos = 300 + startOffset;
      const boatW = 120 + Math.random() * 40;  // Bigger boats for easy jumping

      trajineras.push({
        x: xPos,
        y: lane.y + (Math.random() - 0.5) * 15,
        w: boatW,
        h: 28,
        speed: lane.baseSpeed + Math.random() * 10,
        dir: lane.dir,
        color: TRAJINERA_COLORS[(laneIdx * 3 + i) % TRAJINERA_COLORS.length],
        name: TRAJINERA_NAMES[nameIdx % TRAJINERA_NAMES.length],
        startX: xPos,
        lane: laneIdx + 1
      });
      nameIdx++;
    }
  });

  // ============ FLOWERS EVERYWHERE! ============
  // Scattered flowers throughout
  for (let i = 0; i < 100; i++) {
    const coinX = 300 + Math.random() * (width - 600);
    const coinY = waterY - 100 - Math.random() * 300;
    coins.push({ x: coinX, y: coinY });
  }

  // ============ STARS - Easy to collect celebration stars ============
  stars.push({ x: 600, y: waterY - 200 });
  stars.push({ x: 1500, y: waterY - 250 });
  stars.push({ x: 2400, y: waterY - 200 });

  // ============ DANCE FLOOR - Final celebration area! ============
  // Large platform for the dance party
  platforms.push({ x: width - 400, y: waterY - 60, w: 350, h: 50, isChihampa: true });

  // Flower circle around dance floor
  for (let i = 0; i < 20; i++) {
    const angle = (i / 20) * Math.PI * 2;
    const circleX = width - 225 + Math.cos(angle) * 120;
    const circleY = waterY - 150 + Math.sin(angle) * 50;
    coins.push({ x: circleX, y: circleY });
  }

  // ============ POWERUPS EVERYWHERE - Jump to the sky! ============
  // Starting powerups
  powerups.push({ x: 150, y: waterY - 100 });
  powerups.push({ x: 250, y: waterY - 150 });
  // Powerups along the journey - one every 200px!
  for (let x = 400; x < width - 400; x += 200) {
    const pY = waterY - 120 - Math.random() * 200;
    powerups.push({ x: x, y: pY });
  }
  // Extra powerups near the dance floor
  powerups.push({ x: width - 500, y: waterY - 200 });
  powerups.push({ x: width - 350, y: waterY - 250 });
  powerups.push({ x: width - 200, y: waterY - 200 });

  return {
    width,
    height,
    playerSpawn: { x: 150, y: waterY - 100 },
    babyPosition: { x: width - 225, y: waterY - 100 },  // Baby on dance floor!
    platforms,
    trajineras,
    coins,
    stars,
    enemies,  // Empty - no enemies!
    powerups,
    theme,
    isFiestaLevel: true,
    waterY
  };
}

// Generate Xochimilco side-scroller - ALL TRAJINERAS, super lively!
function generateXochimilcoLevel(levelNum) {
  const levelDifficulty = Math.min(levelNum / 10, 1);
  const settings = DIFFICULTY_SETTINGS[gameState.difficulty];
  const width = 2000 + levelNum * 150;
  const height = 600;
  const waterY = height - 40;  // Water at bottom - fall in = death!

  // Use consistent world theme - SAME theme for entire world!
  const theme = getThemeForLevel(levelNum);

  // ============ GET DENSITY MULTIPLIERS AND BREATHING ROOMS ============
  const density = calculateDensityMultipliers(levelNum);
  const breathingZones = getBreathingRoomZones(width, levelNum);

  // ============ HANDCRAFTED INTRO SECTION (first 300px) ============
  const intro = createIntroSection(levelNum, theme, waterY);

  // ============ HANDCRAFTED OUTRO SECTION (last 300px) ============
  const outro = createOutroSection(levelNum, theme, width, waterY);

  // Combine intro and outro platforms
  const platforms = [...intro.platforms, ...outro.platforms];
  const trajineras = [];
  const coins = [...intro.coins, ...outro.coins];
  const stars = [];
  const enemies = [];
  const powerups = [];

  // ===== TRAJINERAS IN MIDDLE SECTION (300px to width-300px) =====
  const speedMult = 1 + levelNum * 0.06;
  const middleStart = 300;
  const middleEnd = width - 300;
  const middleWidth = middleEnd - middleStart;

  // Lanes cover the ENTIRE screen height - boats everywhere!
  // Apply platform density multiplier to boat counts
  const lanes = [
    { y: waterY - 70,  dir: 1,  baseSpeed: 25, boats: Math.floor((5 + levelNum) * density.platforms) },
    { y: waterY - 140, dir: -1, baseSpeed: 35, boats: Math.floor((5 + levelNum) * density.platforms) },
    { y: waterY - 210, dir: 1,  baseSpeed: 45, boats: Math.floor((4 + levelNum) * density.platforms) },
    { y: waterY - 280, dir: -1, baseSpeed: 40, boats: Math.floor((4 + levelNum) * density.platforms) },
    { y: waterY - 350, dir: 1,  baseSpeed: 50, boats: Math.floor((3 + levelNum) * density.platforms) },
    { y: waterY - 420, dir: -1, baseSpeed: 30, boats: Math.floor((2 + Math.floor(levelNum/2)) * density.platforms) },
  ];

  let nameIdx = 0;
  lanes.forEach((lane, laneIdx) => {
    const spacing = middleWidth / Math.max(1, lane.boats);

    for (let i = 0; i < lane.boats; i++) {
      const startOffset = (i * spacing) + (laneIdx % 2 === 0 ? 0 : spacing / 3);
      const xPos = middleStart + startOffset;

      // Colorful boats of varying sizes
      const boatW = 110 + Math.random() * 50;

      trajineras.push({
        x: xPos,
        y: lane.y + (Math.random() - 0.5) * 15,
        w: boatW,
        h: 28,
        speed: (lane.baseSpeed + Math.random() * 20) * speedMult,
        dir: lane.dir,
        color: TRAJINERA_COLORS[(laneIdx * 4 + i) % TRAJINERA_COLORS.length],
        name: TRAJINERA_NAMES[nameIdx % TRAJINERA_NAMES.length],
        startX: xPos,
        lane: laneIdx + 1
      });
      nameIdx++;
    }
  });

  // ===== COINS IN MIDDLE SECTION - Apply density multiplier =====
  const baseCoinCount = Math.floor((12 + levelNum * 2) * density.coins);
  for (let i = 0; i < baseCoinCount; i++) {
    coins.push({
      x: middleStart + Math.random() * middleWidth,
      y: waterY - 100 - Math.random() * 350
    });
  }

  // ===== STARS - 3 per level at different heights (in middle section) =====
  stars.push({ x: middleStart + middleWidth * 0.2, y: waterY - 160 });
  stars.push({ x: middleStart + middleWidth * 0.5, y: waterY - 280 });
  stars.push({ x: middleStart + middleWidth * 0.8, y: waterY - 380 });

  // ===== FLYING ENEMIES IN MIDDLE SECTION - Apply density multiplier =====
  const baseEnemyCount = Math.floor((2 + levelDifficulty * 2) * settings.enemyMult * density.enemies);
  const middleEnemies = [];
  for (let i = 0; i < baseEnemyCount; i++) {
    middleEnemies.push({
      x: middleStart + 100 + (i * (middleWidth - 200) / Math.max(1, baseEnemyCount)),
      y: waterY - 180 - Math.random() * 200,
      type: 'flying',
      amplitude: 35 + Math.random() * 35,
      speed: 35 + Math.random() * 35,
      dir: i % 2 === 0 ? 1 : -1
    });
  }

  // Filter enemies from breathing room zones and add intro/outro enemies
  const filteredMiddleEnemies = filterEnemiesFromBreathingRooms(middleEnemies, breathingZones);
  enemies.push(...intro.enemies, ...filteredMiddleEnemies, ...outro.enemies);

  // ===== POWERUPS =====
  const numPowerups = Math.floor((3 + levelDifficulty * 2) * settings.powerupMult);
  powerups.push({ x: 150, y: waterY - 140 });  // One on start
  for (let i = 1; i < numPowerups; i++) {
    powerups.push({
      x: middleStart + i * (middleWidth / numPowerups),
      y: waterY - 140 - Math.random() * 250
    });
  }
  powerups.push({ x: width - 130, y: waterY - 140 });  // One on end

  return {
    width,
    height,
    playerSpawn: { x: 100, y: waterY - 150 },
    babyPosition: { x: width - 125, y: waterY - 150 },  // BABY ON FINAL PLATFORM!
    platforms,
    trajineras,
    coins,
    stars,
    enemies,
    powerups,
    theme,
    isXochimilcoLevel: true,
    waterY,
    breathingZones  // For debugging/visualization if needed
  };
}

// ============== LEVEL DATA ==============
const LEVELS = [
  // Level 1 - Tutorial
  {
    width: 2400, height: 600,
    playerSpawn: { x: 100, y: 400 },
    babyPosition: { x: 2200, y: 300 },
    platforms: [
      { x: 0, y: 550, w: 2400, h: 50 }, // ground
      { x: 300, y: 450, w: 150, h: 20 },
      { x: 550, y: 380, w: 100, h: 20 },
      { x: 800, y: 320, w: 150, h: 20 },
      { x: 1100, y: 400, w: 200, h: 20 },
      { x: 1450, y: 350, w: 150, h: 20 },
      { x: 1700, y: 280, w: 100, h: 20 },
      { x: 1950, y: 350, w: 200, h: 20 },
      // Secret high platforms (need super jump)
      { x: 600, y: 150, w: 100, h: 20 },
      { x: 1500, y: 120, w: 120, h: 20 },
    ],
    coins: [
      {x:200,y:500},{x:250,y:500},{x:350,y:400},{x:600,y:330},
      {x:900,y:270},{x:1200,y:350},{x:1500,y:300},{x:1750,y:230},{x:2000,y:300},
      // Bonus coins on secret platforms
      {x:620,y:100},{x:660,y:100},{x:1520,y:70},{x:1560,y:70},{x:1600,y:70}
    ],
    stars: [{x:400,y:350},{x:650,y:100},{x:1560,y:70}],
    enemies: [
      // Ground enemies
      {x:500,y:520,type:'ground'},{x:1300,y:520,type:'ground'},{x:2000,y:520,type:'ground'},
      // Platform enemies
      {x:850,y:290,type:'platform'},{x:1500,y:320,type:'platform'},
      // Flying enemy
      {x:1100,y:350,type:'flying',amplitude:60,speed:70,dir:1}
    ],
    powerups: [
      {x:150,y:500},{x:850,y:270},{x:1550,y:300}
    ]
  },
  // Level 2 - Floating Gardens 2
  {
    width: 2800, height: 600,
    playerSpawn: { x: 100, y: 400 },
    babyPosition: { x: 2600, y: 250 },
    platforms: [
      { x: 0, y: 550, w: 600, h: 50 },
      { x: 700, y: 550, w: 500, h: 50 },
      { x: 1300, y: 550, w: 600, h: 50 },
      { x: 2000, y: 550, w: 800, h: 50 },
      { x: 350, y: 450, w: 150, h: 20 },
      { x: 600, y: 380, w: 100, h: 20 },
      { x: 900, y: 450, w: 150, h: 20 },
      { x: 1200, y: 380, w: 100, h: 20 },
      { x: 1500, y: 320, w: 150, h: 20 },
      { x: 1800, y: 400, w: 200, h: 20 },
      { x: 2100, y: 320, w: 150, h: 20 },
      { x: 2400, y: 280, w: 200, h: 20 },
      // Secret platforms
      { x: 400, y: 150, w: 100, h: 20 },
      { x: 1600, y: 100, w: 150, h: 20 },
    ],
    coins: [
      {x:200,y:500},{x:400,y:400},{x:650,y:330},{x:950,y:400},
      {x:1250,y:330},{x:1550,y:270},{x:1850,y:350},{x:2150,y:270},{x:2450,y:230},
      {x:420,y:100},{x:460,y:100},{x:1620,y:50},{x:1680,y:50},{x:1740,y:50}
    ],
    stars: [{x:450,y:100},{x:1400,y:200},{x:1680,y:50}],
    enemies: [
      // Ground enemies
      {x:400,y:520,type:'ground'},{x:1100,y:520,type:'ground'},{x:2200,y:520,type:'ground'},
      // Platform enemies
      {x:650,y:350,type:'platform'},{x:1550,y:290,type:'platform'},{x:2450,y:250,type:'platform'},
      // Flying enemies
      {x:900,y:400,type:'flying',amplitude:50,speed:80,dir:-1},
      {x:1900,y:350,type:'flying',amplitude:70,speed:60,dir:1}
    ],
    powerups: [
      {x:250,y:500},{x:1000,y:400},{x:2000,y:500}
    ]
  },
  // Level 3
  {
    width: 3000, height: 700,
    playerSpawn: { x: 100, y: 500 },
    babyPosition: { x: 2800, y: 200 },
    platforms: [
      { x: 0, y: 650, w: 500, h: 50 },
      { x: 600, y: 650, w: 400, h: 50 },
      { x: 1100, y: 650, w: 500, h: 50 },
      { x: 1700, y: 650, w: 400, h: 50 },
      { x: 2200, y: 650, w: 800, h: 50 },
      { x: 300, y: 550, w: 150, h: 20 },
      { x: 550, y: 480, w: 100, h: 20 },
      { x: 800, y: 550, w: 150, h: 20 },
      { x: 1050, y: 480, w: 100, h: 20 },
      { x: 1300, y: 400, w: 150, h: 20 },
      { x: 1550, y: 480, w: 150, h: 20 },
      { x: 1850, y: 400, w: 150, h: 20 },
      { x: 2100, y: 320, w: 150, h: 20 },
      { x: 2400, y: 400, w: 150, h: 20 },
      { x: 2650, y: 300, w: 200, h: 20 },
    ],
    coins: [
      {x:200,y:600},{x:350,y:500},{x:600,y:430},{x:850,y:500},{x:1100,y:430},
      {x:1350,y:350},{x:1600,y:430},{x:1900,y:350},{x:2150,y:270},{x:2450,y:350},{x:2700,y:250}
    ],
    stars: [{x:600,y:350},{x:1450,y:280},{x:2750,y:180}],
    enemies: [
      // Ground
      {x:300,y:620,type:'ground'},{x:1000,y:620,type:'ground'},{x:2300,y:620,type:'ground'},
      // Platform
      {x:1350,y:370,type:'platform'},{x:1900,y:370,type:'platform'},{x:2700,y:270,type:'platform'},
      // Flying
      {x:700,y:500,type:'flying',amplitude:80,speed:90,dir:-1},
      {x:1600,y:400,type:'flying',amplitude:60,speed:75,dir:1}
    ],
    powerups: [
      {x:200,y:600},{x:900,y:500},{x:1700,y:600},{x:2500,y:350}
    ]
  },
  // Level 4
  {
    width: 3200, height: 700,
    playerSpawn: { x: 100, y: 500 },
    babyPosition: { x: 3000, y: 180 },
    platforms: [
      { x: 0, y: 650, w: 400, h: 50 },
      { x: 500, y: 650, w: 300, h: 50 },
      { x: 900, y: 650, w: 400, h: 50 },
      { x: 1400, y: 650, w: 300, h: 50 },
      { x: 1800, y: 650, w: 400, h: 50 },
      { x: 2300, y: 650, w: 300, h: 50 },
      { x: 2700, y: 650, w: 500, h: 50 },
      { x: 250, y: 550, w: 100, h: 20 },
      { x: 450, y: 480, w: 100, h: 20 },
      { x: 700, y: 550, w: 150, h: 20 },
      { x: 1000, y: 480, w: 100, h: 20 },
      { x: 1250, y: 400, w: 100, h: 20 },
      { x: 1500, y: 480, w: 150, h: 20 },
      { x: 1800, y: 400, w: 100, h: 20 },
      { x: 2050, y: 320, w: 150, h: 20 },
      { x: 2350, y: 400, w: 100, h: 20 },
      { x: 2600, y: 320, w: 100, h: 20 },
      { x: 2850, y: 250, w: 200, h: 20 },
    ],
    coins: [
      {x:150,y:600},{x:300,y:500},{x:500,y:430},{x:750,y:500},{x:1050,y:430},
      {x:1300,y:350},{x:1550,y:430},{x:1850,y:350},{x:2100,y:270},{x:2400,y:350},
      {x:2650,y:270},{x:2900,y:200}
    ],
    stars: [{x:500,y:350},{x:1400,y:280},{x:2950,y:150}],
    enemies: [
      // Ground
      {x:250,y:620,type:'ground'},{x:950,y:620,type:'ground'},{x:2000,y:620,type:'ground'},
      // Platform
      {x:750,y:520,type:'platform'},{x:1300,y:370,type:'platform'},{x:2650,y:290,type:'platform'},
      // Flying - multiple!
      {x:500,y:450,type:'flying',amplitude:70,speed:85,dir:1},
      {x:1500,y:400,type:'flying',amplitude:60,speed:95,dir:-1},
      {x:2400,y:350,type:'flying',amplitude:50,speed:100,dir:1}
    ],
    powerups: [
      {x:150,y:600},{x:800,y:500},{x:1600,y:600},{x:2200,y:350},{x:2700,y:270}
    ]
  },
  // Level 5 (Final)
  {
    width: 3500, height: 800,
    playerSpawn: { x: 100, y: 600 },
    babyPosition: { x: 3300, y: 150 },
    platforms: [
      { x: 0, y: 750, w: 350, h: 50 },
      { x: 450, y: 750, w: 250, h: 50 },
      { x: 800, y: 750, w: 350, h: 50 },
      { x: 1250, y: 750, w: 250, h: 50 },
      { x: 1600, y: 750, w: 350, h: 50 },
      { x: 2050, y: 750, w: 250, h: 50 },
      { x: 2400, y: 750, w: 350, h: 50 },
      { x: 2850, y: 750, w: 650, h: 50 },
      { x: 200, y: 650, w: 100, h: 20 },
      { x: 400, y: 580, w: 100, h: 20 },
      { x: 650, y: 650, w: 100, h: 20 },
      { x: 900, y: 580, w: 100, h: 20 },
      { x: 1150, y: 500, w: 100, h: 20 },
      { x: 1400, y: 580, w: 100, h: 20 },
      { x: 1700, y: 500, w: 100, h: 20 },
      { x: 1950, y: 420, w: 100, h: 20 },
      { x: 2200, y: 500, w: 100, h: 20 },
      { x: 2500, y: 420, w: 100, h: 20 },
      { x: 2750, y: 340, w: 100, h: 20 },
      { x: 3000, y: 260, w: 150, h: 20 },
      { x: 3200, y: 200, w: 200, h: 20 },
    ],
    coins: [
      {x:100,y:700},{x:250,y:600},{x:450,y:530},{x:700,y:600},{x:950,y:530},
      {x:1200,y:450},{x:1450,y:530},{x:1750,y:450},{x:2000,y:370},{x:2250,y:450},
      {x:2550,y:370},{x:2800,y:290},{x:3050,y:210},{x:3250,y:150}
    ],
    stars: [{x:500,y:450},{x:1600,y:380},{x:3150,y:100}],
    enemies: [
      // Ground
      {x:200,y:720,type:'ground'},{x:900,y:720,type:'ground'},{x:2500,y:720,type:'ground'},
      // Platform
      {x:450,y:550,type:'platform'},{x:1200,y:470,type:'platform'},{x:2000,y:390,type:'platform'},{x:3050,y:230,type:'platform'},
      // Flying - swarm!
      {x:700,y:550,type:'flying',amplitude:80,speed:75,dir:-1},
      {x:1400,y:480,type:'flying',amplitude:70,speed:90,dir:1},
      {x:2200,y:400,type:'flying',amplitude:60,speed:85,dir:-1},
      {x:2800,y:320,type:'flying',amplitude:50,speed:100,dir:1}
    ],
    powerups: [
      {x:100,y:700},{x:600,y:600},{x:1100,y:700},{x:1800,y:450},{x:2300,y:450},{x:2900,y:300}
    ]
    // BOSS LEVEL 5 - Dark Xochi appears with timer!
  },
  // Level 6 - Jungle Temple
  {
    width: 3200, height: 700,
    playerSpawn: { x: 100, y: 550 },
    babyPosition: { x: 3000, y: 200 },
    platforms: [
      { x: 0, y: 650, w: 400, h: 50 },
      { x: 500, y: 650, w: 300, h: 50 },
      { x: 900, y: 650, w: 400, h: 50 },
      { x: 1400, y: 650, w: 300, h: 50 },
      { x: 1800, y: 650, w: 400, h: 50 },
      { x: 2300, y: 650, w: 300, h: 50 },
      { x: 2700, y: 650, w: 500, h: 50 },
      { x: 200, y: 550, w: 120, h: 20 },
      { x: 450, y: 480, w: 100, h: 20 },
      { x: 700, y: 400, w: 150, h: 20 },
      { x: 1000, y: 500, w: 120, h: 20 },
      { x: 1250, y: 420, w: 100, h: 20 },
      { x: 1500, y: 340, w: 150, h: 20 },
      { x: 1800, y: 450, w: 120, h: 20 },
      { x: 2100, y: 350, w: 150, h: 20 },
      { x: 2400, y: 280, w: 120, h: 20 },
      { x: 2700, y: 350, w: 100, h: 20 },
      { x: 2900, y: 250, w: 200, h: 20 },
    ],
    coins: [
      {x:150,y:600},{x:250,y:500},{x:500,y:430},{x:750,y:350},{x:1050,y:450},
      {x:1300,y:370},{x:1550,y:290},{x:1850,y:400},{x:2150,y:300},{x:2450,y:230},{x:2950,y:200}
    ],
    stars: [{x:750,y:300},{x:1550,y:200},{x:2950,y:150}],
    enemies: [
      // Ground
      {x:300,y:620,type:'ground'},{x:1000,y:620,type:'ground'},{x:2400,y:620,type:'ground'},
      // Platform
      {x:750,y:370,type:'platform'},{x:1300,y:390,type:'platform'},{x:2150,y:320,type:'platform'},{x:2750,y:320,type:'platform'},
      // Flying
      {x:500,y:450,type:'flying',amplitude:70,speed:80,dir:1},
      {x:1200,y:380,type:'flying',amplitude:55,speed:95,dir:-1},
      {x:2000,y:350,type:'flying',amplitude:65,speed:85,dir:1}
    ],
    powerups: [{x:100,y:600},{x:800,y:350},{x:1600,y:290},{x:2500,y:230}]
  },
  // Level 7 - Jungle Temple 2
  {
    width: 3500, height: 750,
    playerSpawn: { x: 100, y: 600 },
    babyPosition: { x: 3300, y: 180 },
    platforms: [
      { x: 0, y: 700, w: 350, h: 50 },
      { x: 450, y: 700, w: 300, h: 50 },
      { x: 850, y: 700, w: 350, h: 50 },
      { x: 1300, y: 700, w: 300, h: 50 },
      { x: 1700, y: 700, w: 350, h: 50 },
      { x: 2150, y: 700, w: 300, h: 50 },
      { x: 2550, y: 700, w: 350, h: 50 },
      { x: 3000, y: 700, w: 500, h: 50 },
      { x: 180, y: 600, w: 100, h: 20 },
      { x: 400, y: 520, w: 120, h: 20 },
      { x: 650, y: 440, w: 100, h: 20 },
      { x: 900, y: 550, w: 150, h: 20 },
      { x: 1150, y: 460, w: 100, h: 20 },
      { x: 1400, y: 380, w: 120, h: 20 },
      { x: 1700, y: 480, w: 100, h: 20 },
      { x: 1950, y: 380, w: 150, h: 20 },
      { x: 2200, y: 300, w: 100, h: 20 },
      { x: 2500, y: 400, w: 120, h: 20 },
      { x: 2750, y: 320, w: 100, h: 20 },
      { x: 3000, y: 240, w: 150, h: 20 },
      { x: 3200, y: 180, w: 200, h: 20 },
    ],
    coins: [
      {x:100,y:650},{x:230,y:550},{x:450,y:470},{x:700,y:390},{x:950,y:500},
      {x:1200,y:410},{x:1450,y:330},{x:1750,y:430},{x:2000,y:330},{x:2250,y:250},
      {x:2550,y:350},{x:2800,y:270},{x:3050,y:190},{x:3250,y:130}
    ],
    stars: [{x:700,y:340},{x:1450,y:230},{x:3100,y:140}],
    enemies: [
      // Ground
      {x:250,y:670,type:'ground'},{x:950,y:670,type:'ground'},{x:2650,y:670,type:'ground'},
      // Platform
      {x:700,y:410,type:'platform'},{x:1450,y:350,type:'platform'},{x:2000,y:350,type:'platform'},{x:3050,y:210,type:'platform'},
      // Flying
      {x:450,y:500,type:'flying',amplitude:75,speed:85,dir:-1},
      {x:1200,y:420,type:'flying',amplitude:60,speed:90,dir:1},
      {x:2400,y:350,type:'flying',amplitude:55,speed:100,dir:-1},
      {x:2900,y:280,type:'flying',amplitude:50,speed:95,dir:1}
    ],
    powerups: [{x:100,y:650},{x:700,y:390},{x:1500,y:330},{x:2300,y:250},{x:2900,y:190}]
  },
  // Level 8 - Volcano
  {
    width: 3600, height: 800,
    playerSpawn: { x: 100, y: 650 },
    babyPosition: { x: 3400, y: 200 },
    platforms: [
      { x: 0, y: 750, w: 300, h: 50 },
      { x: 400, y: 750, w: 250, h: 50 },
      { x: 750, y: 750, w: 300, h: 50 },
      { x: 1150, y: 750, w: 250, h: 50 },
      { x: 1500, y: 750, w: 300, h: 50 },
      { x: 1900, y: 750, w: 250, h: 50 },
      { x: 2250, y: 750, w: 300, h: 50 },
      { x: 2650, y: 750, w: 250, h: 50 },
      { x: 3000, y: 750, w: 600, h: 50 },
      { x: 150, y: 650, w: 100, h: 20 },
      { x: 350, y: 570, w: 100, h: 20 },
      { x: 600, y: 650, w: 120, h: 20 },
      { x: 850, y: 560, w: 100, h: 20 },
      { x: 1100, y: 480, w: 120, h: 20 },
      { x: 1350, y: 560, w: 100, h: 20 },
      { x: 1600, y: 470, w: 120, h: 20 },
      { x: 1850, y: 380, w: 100, h: 20 },
      { x: 2100, y: 480, w: 120, h: 20 },
      { x: 2350, y: 380, w: 100, h: 20 },
      { x: 2600, y: 300, w: 120, h: 20 },
      { x: 2900, y: 380, w: 100, h: 20 },
      { x: 3150, y: 280, w: 150, h: 20 },
      { x: 3350, y: 200, w: 200, h: 20 },
    ],
    coins: [
      {x:80,y:700},{x:200,y:600},{x:400,y:520},{x:650,y:600},{x:900,y:510},
      {x:1150,y:430},{x:1400,y:510},{x:1650,y:420},{x:1900,y:330},{x:2150,y:430},
      {x:2400,y:330},{x:2650,y:250},{x:2950,y:330},{x:3200,y:230},{x:3400,y:150}
    ],
    stars: [{x:400,y:420},{x:1650,y:320},{x:3200,y:180}],
    enemies: [
      // Ground
      {x:200,y:720,type:'ground'},{x:850,y:720,type:'ground'},{x:2350,y:720,type:'ground'},
      // Platform - heavy presence
      {x:400,y:540,type:'platform'},{x:900,y:530,type:'platform'},{x:1400,y:530,type:'platform'},
      {x:1900,y:350,type:'platform'},{x:2650,y:270,type:'platform'},{x:3200,y:250,type:'platform'},
      // Flying - danger zone!
      {x:600,y:550,type:'flying',amplitude:80,speed:80,dir:-1},
      {x:1100,y:470,type:'flying',amplitude:70,speed:95,dir:1},
      {x:1800,y:400,type:'flying',amplitude:60,speed:90,dir:-1},
      {x:2500,y:330,type:'flying',amplitude:55,speed:100,dir:1},
      {x:3000,y:280,type:'flying',amplitude:50,speed:85,dir:-1}
    ],
    powerups: [{x:80,y:700},{x:650,y:600},{x:1250,y:430},{x:1900,y:330},{x:2650,y:250},{x:3100,y:230}]
  },
  // Level 9 - Volcano 2
  {
    width: 3800, height: 850,
    playerSpawn: { x: 100, y: 700 },
    babyPosition: { x: 3600, y: 180 },
    platforms: [
      { x: 0, y: 800, w: 280, h: 50 },
      { x: 380, y: 800, w: 220, h: 50 },
      { x: 700, y: 800, w: 280, h: 50 },
      { x: 1080, y: 800, w: 220, h: 50 },
      { x: 1400, y: 800, w: 280, h: 50 },
      { x: 1780, y: 800, w: 220, h: 50 },
      { x: 2100, y: 800, w: 280, h: 50 },
      { x: 2480, y: 800, w: 220, h: 50 },
      { x: 2800, y: 800, w: 280, h: 50 },
      { x: 3180, y: 800, w: 620, h: 50 },
      { x: 140, y: 700, w: 100, h: 20 },
      { x: 340, y: 620, w: 100, h: 20 },
      { x: 580, y: 700, w: 100, h: 20 },
      { x: 800, y: 610, w: 100, h: 20 },
      { x: 1050, y: 520, w: 100, h: 20 },
      { x: 1300, y: 610, w: 100, h: 20 },
      { x: 1550, y: 510, w: 100, h: 20 },
      { x: 1800, y: 420, w: 100, h: 20 },
      { x: 2050, y: 520, w: 100, h: 20 },
      { x: 2300, y: 420, w: 100, h: 20 },
      { x: 2550, y: 330, w: 100, h: 20 },
      { x: 2850, y: 420, w: 100, h: 20 },
      { x: 3100, y: 320, w: 100, h: 20 },
      { x: 3350, y: 240, w: 150, h: 20 },
      { x: 3550, y: 180, w: 200, h: 20 },
    ],
    coins: [
      {x:70,y:750},{x:190,y:650},{x:390,y:570},{x:630,y:650},{x:850,y:560},
      {x:1100,y:470},{x:1350,y:560},{x:1600,y:460},{x:1850,y:370},{x:2100,y:470},
      {x:2350,y:370},{x:2600,y:280},{x:2900,y:370},{x:3150,y:270},{x:3400,y:190},{x:3600,y:130}
    ],
    stars: [{x:390,y:470},{x:1600,y:360},{x:3400,y:140}],
    enemies: [
      // Ground
      {x:180,y:770,type:'ground'},{x:800,y:770,type:'ground'},{x:2200,y:770,type:'ground'},{x:3280,y:770,type:'ground'},
      // Platform - lots!
      {x:400,y:590,type:'platform'},{x:900,y:580,type:'platform'},{x:1400,y:580,type:'platform'},
      {x:1900,y:390,type:'platform'},{x:2400,y:390,type:'platform'},{x:2950,y:290,type:'platform'},{x:3400,y:210,type:'platform'},
      // Flying - intense!
      {x:550,y:600,type:'flying',amplitude:85,speed:85,dir:-1},
      {x:1050,y:510,type:'flying',amplitude:75,speed:100,dir:1},
      {x:1700,y:450,type:'flying',amplitude:65,speed:95,dir:-1},
      {x:2350,y:380,type:'flying',amplitude:55,speed:90,dir:1},
      {x:2850,y:310,type:'flying',amplitude:50,speed:105,dir:-1},
      {x:3200,y:260,type:'flying',amplitude:45,speed:80,dir:1}
    ],
    powerups: [{x:70,y:750},{x:630,y:650},{x:1200,y:470},{x:1850,y:370},{x:2600,y:280},{x:3200,y:270}]
  },
  // Level 10 - Final Challenge!
  {
    width: 4000, height: 900,
    playerSpawn: { x: 100, y: 750 },
    babyPosition: { x: 3800, y: 150 },
    platforms: [
      { x: 0, y: 850, w: 250, h: 50 },
      { x: 350, y: 850, w: 200, h: 50 },
      { x: 650, y: 850, w: 250, h: 50 },
      { x: 1000, y: 850, w: 200, h: 50 },
      { x: 1300, y: 850, w: 250, h: 50 },
      { x: 1650, y: 850, w: 200, h: 50 },
      { x: 1950, y: 850, w: 250, h: 50 },
      { x: 2300, y: 850, w: 200, h: 50 },
      { x: 2600, y: 850, w: 250, h: 50 },
      { x: 2950, y: 850, w: 200, h: 50 },
      { x: 3250, y: 850, w: 750, h: 50 },
      { x: 125, y: 750, w: 100, h: 20 },
      { x: 325, y: 670, w: 100, h: 20 },
      { x: 550, y: 750, w: 100, h: 20 },
      { x: 750, y: 660, w: 100, h: 20 },
      { x: 980, y: 570, w: 100, h: 20 },
      { x: 1200, y: 660, w: 100, h: 20 },
      { x: 1450, y: 560, w: 100, h: 20 },
      { x: 1700, y: 470, w: 100, h: 20 },
      { x: 1950, y: 570, w: 100, h: 20 },
      { x: 2200, y: 470, w: 100, h: 20 },
      { x: 2450, y: 380, w: 100, h: 20 },
      { x: 2750, y: 470, w: 100, h: 20 },
      { x: 3000, y: 370, w: 100, h: 20 },
      { x: 3250, y: 280, w: 100, h: 20 },
      { x: 3500, y: 200, w: 150, h: 20 },
      { x: 3750, y: 150, w: 200, h: 20 },
    ],
    coins: [
      {x:60,y:800},{x:175,y:700},{x:375,y:620},{x:600,y:700},{x:800,y:610},
      {x:1030,y:520},{x:1250,y:610},{x:1500,y:510},{x:1750,y:420},{x:2000,y:520},
      {x:2250,y:420},{x:2500,y:330},{x:2800,y:420},{x:3050,y:320},{x:3300,y:230},
      {x:3550,y:150},{x:3800,y:100}
    ],
    stars: [{x:375,y:520},{x:1500,y:410},{x:3300,y:180}],
    enemies: [
      // Ground - gauntlet!
      {x:160,y:820,type:'ground'},{x:750,y:820,type:'ground'},{x:1400,y:820,type:'ground'},
      {x:2050,y:820,type:'ground'},{x:2700,y:820,type:'ground'},{x:3350,y:820,type:'ground'},
      // Platform - maximum coverage!
      {x:375,y:640,type:'platform'},{x:800,y:630,type:'platform'},{x:1250,y:630,type:'platform'},
      {x:1750,y:440,type:'platform'},{x:2250,y:440,type:'platform'},{x:2800,y:440,type:'platform'},
      {x:3100,y:340,type:'platform'},{x:3550,y:170,type:'platform'},
      // Flying - BOSS MODE!
      {x:400,y:650,type:'flying',amplitude:90,speed:90,dir:-1},
      {x:800,y:570,type:'flying',amplitude:80,speed:100,dir:1},
      {x:1200,y:500,type:'flying',amplitude:70,speed:95,dir:-1},
      {x:1600,y:430,type:'flying',amplitude:65,speed:110,dir:1},
      {x:2000,y:380,type:'flying',amplitude:60,speed:105,dir:-1},
      {x:2400,y:330,type:'flying',amplitude:55,speed:100,dir:1},
      {x:2800,y:280,type:'flying',amplitude:50,speed:95,dir:-1},
      {x:3200,y:230,type:'flying',amplitude:45,speed:90,dir:1},
      {x:3600,y:180,type:'flying',amplitude:40,speed:85,dir:-1}
    ],
    powerups: [{x:60,y:800},{x:600,y:700},{x:1100,y:520},{x:1750,y:420},{x:2500,y:330},{x:3100,y:320},{x:3500,y:150}]
    // BOSS LEVEL 10 - Final Dark Xochi showdown with timer!
  }
];

// ============== BOOT SCENE ==============
class BootScene extends Phaser.Scene {
  constructor() { super('BootScene'); }

  preload() {
    // ============ LOADING BAR ============
    const width = this.cameras.main.width;
    const height = this.cameras.main.height;

    // Background
    this.add.rectangle(width/2, height/2, width, height, 0x1a2a3a);

    // Title
    const title = this.add.text(width/2, height/2 - 80, 'XOCHI', {
      fontFamily: 'Arial Black',
      fontSize: '48px',
      color: '#ff69b4',
      stroke: '#000000',
      strokeThickness: 4
    }).setOrigin(0.5);

    // Subtitle
    this.add.text(width/2, height/2 - 35, 'La Guerrera Axolotl', {
      fontFamily: 'Georgia',
      fontSize: '18px',
      color: '#88ddff',
      fontStyle: 'italic'
    }).setOrigin(0.5);

    // Loading bar background
    const barWidth = 300;
    const barHeight = 20;
    const barX = width/2 - barWidth/2;
    const barY = height/2 + 30;

    this.add.rectangle(width/2, barY + barHeight/2, barWidth + 4, barHeight + 4, 0x333333);
    const progressBar = this.add.rectangle(barX + 2, barY + 2, 0, barHeight, 0xff69b4).setOrigin(0, 0);

    // Loading text
    const loadingText = this.add.text(width/2, barY + barHeight + 25, 'Loading...', {
      fontFamily: 'Arial',
      fontSize: '14px',
      color: '#aaaaaa'
    }).setOrigin(0.5);

    // Progress events
    this.load.on('progress', (value) => {
      progressBar.width = barWidth * value;
      loadingText.setText(`Loading... ${Math.round(value * 100)}%`);
    });

    this.load.on('complete', () => {
      loadingText.setText('Ready!');
      console.log('All assets loaded successfully!');
    });

    // Error handling - log failed assets and continue
    this.load.on('loaderror', (file) => {
      console.error('Failed to load:', file.key, file.url);
      // Show error on screen too
      this.add.text(width/2, barY + barHeight + 70, `FAILED: ${file.key}`, {
        fontFamily: 'Arial', fontSize: '12px', color: '#ff6666'
      }).setOrigin(0.5);
    });

    // Show currently loading file - helps user see activity even when % doesn't change
    const fileText = this.add.text(width/2, barY + barHeight + 50, '', {
      fontFamily: 'Arial', fontSize: '11px', color: '#666666'
    }).setOrigin(0.5);

    this.load.on('filestart', (file) => {
      fileText.setText(`Loading: ${file.key}`);
    });

    // Log each file as it loads
    this.load.on('filecomplete', (key) => {
      console.log('Loaded:', key);
    });

    // Load music - Suno-generated Xochimilco tracks (one per world)
    this.load.audio('music-menu', 'assets/audio/music_menu.ogg');       // World 1: Traviesa Axolotla
    this.load.audio('music-gardens', 'assets/audio/music_gardens.ogg'); // World 2: Flowers of the Last Dawn
    this.load.audio('music-world3', 'assets/audio/music_world3.ogg');   // World 3: Xochi la Oaxalota
    this.load.audio('music-night', 'assets/audio/music_night.ogg');     // World 4-5: Xochi la Oaxalotla Noche
    this.load.audio('music-fiesta', 'assets/audio/music_fiesta.ogg');   // World 6: Last Bloom of Oaxolotl
    this.load.audio('music-upscroller', 'assets/audio/music_upscroller.ogg'); // Upscroller levels: Xochi la Oaxalotla Salta
    this.load.audio('music-boss', 'assets/audio/music_boss.ogg');       // Boss fights: Xochi Guerrera Azteca
    this.load.audio('music-finale', 'assets/audio/music_finale.ogg');   // Final celebration: Fiesta de Xochi

    // Load SFX - Xochi-themed Mesoamerican sounds
    // Movement sounds
    this.load.audio('sfx-jump', 'assets/audio/sfx/movement/jump_small.ogg');
    this.load.audio('sfx-superjump', 'assets/audio/sfx/movement/jump_super.ogg');
    this.load.audio('sfx-land', 'assets/audio/sfx/movement/land_soft.ogg');
    // Combat sounds
    this.load.audio('sfx-stomp', 'assets/audio/sfx/combat/stomp.ogg');
    this.load.audio('sfx-hurt', 'assets/audio/sfx/combat/hurt.ogg');
    // Collectible sounds
    this.load.audio('sfx-coin', 'assets/audio/sfx/collectibles/flower.ogg');
    // UI sounds
    this.load.audio('sfx-select', 'assets/audio/sfx/ui/menu_select.ogg');
    // Legacy sounds (keep for compatibility)
    this.load.audio('sfx-powerup', 'assets/audio/powerup.ogg');

    // Load Xochi (Aztec axolotl warrior) animation frames from pack
    this.load.image('xochi_walk', 'assets/xochi_main_asset/xochi_walk.png');     // Walk pose
    this.load.image('xochi_run', 'assets/xochi_main_asset/xochi_run.png');       // Run pose
    this.load.image('xochi_jump', 'assets/xochi_main_asset/xochi_jump.png');     // Jump pose
    this.load.image('xochi_attack', 'assets/xochi_main_asset/xochi_attack.png'); // Attack pose
    // Default/legacy keys
    this.load.image('xochi', 'assets/xochi_main_asset/xochi_walk.png');
  }

  create() {
    console.log('BootScene.create() called');
    // Generate textures
    this.generateTextures();
    console.log('Textures generated, starting MenuScene');
    this.scene.start('MenuScene');
  }

  generateTextures() {
    let g = this.add.graphics();

    // Helper to draw a star shape
    const drawStar = (gfx, cx, cy, points, outerR, innerR) => {
      gfx.beginPath();
      for (let i = 0; i < points * 2; i++) {
        const r = i % 2 === 0 ? outerR : innerR;
        const angle = (i * Math.PI / points) - Math.PI / 2;
        const x = cx + Math.cos(angle) * r;
        const y = cy + Math.sin(angle) * r;
        if (i === 0) gfx.moveTo(x, y);
        else gfx.lineTo(x, y);
      }
      gfx.closePath();
      gfx.fillPath();
    };

    // Helper to draw coral-like feathery gills
    const drawGills = (gfx, x, y, flip, scale = 1) => {
      const dir = flip ? -1 : 1;
      // Multiple coral fronds with gradient coloring
      const fronds = [
        { ox: 0, oy: -8, r: 4 },   // Top frond
        { ox: -2 * dir, oy: -4, r: 3.5 },
        { ox: -3 * dir, oy: 0, r: 3 },
        { ox: -2 * dir, oy: 4, r: 3 },
        { ox: 0, oy: 7, r: 2.5 },  // Bottom frond
      ];
      // Dark coral base
      gfx.fillStyle(0xcc3366);
      fronds.forEach(f => {
        gfx.fillCircle(x + f.ox * scale, y + f.oy * scale, f.r * scale);
      });
      // Mid coral layer
      gfx.fillStyle(0xe85588);
      fronds.forEach(f => {
        gfx.fillCircle(x + f.ox * scale + dir, y + f.oy * scale - 0.5, (f.r - 0.5) * scale);
      });
      // Bright coral tips
      gfx.fillStyle(0xff88aa);
      fronds.forEach(f => {
        gfx.fillCircle(x + f.ox * scale + dir * 1.5, y + f.oy * scale - 1, (f.r - 1.2) * scale);
      });
      // Tiny highlight dots
      gfx.fillStyle(0xffccdd);
      gfx.fillCircle(x + dir * 2, y - 7 * scale, 1.5 * scale);
      gfx.fillCircle(x + dir, y - 2 * scale, 1 * scale);
    };

    // ============ XOCHI SPRITE (loaded from PNG) ============
    // Xochi is now an Aztec warrior girl - sprite loaded in preload()
    // Skip procedural generation for 'xochi' texture

    /* REMOVED - now using PNG sprite
    // TAIL (behind body, extending right)
    g.fillStyle(0xbb5577);
    g.fillEllipse(24, 18, 10, 4);
    g.fillStyle(0xd8708a);
    g.fillEllipse(23, 17, 8, 3);
    g.fillStyle(0xf08899);
    g.fillEllipse(22, 17, 6, 2);

    // BACK LEG (partially visible)
    g.fillStyle(0xcc5577);
    g.fillEllipse(18, 22, 4, 5);
    g.fillStyle(0xe07090);
    g.fillEllipse(18, 23, 3, 3);

    // BODY - elongated oval, 3/4 view (DKC style smooth shading)
    // Deep shadow
    g.fillStyle(0x993355);
    g.fillEllipse(13, 15, 16, 12);
    // Body dark
    g.fillStyle(0xcc5577);
    g.fillEllipse(12, 14, 15, 11);
    // Body mid
    g.fillStyle(0xe07090);
    g.fillEllipse(11, 13, 14, 10);
    // Body light
    g.fillStyle(0xf08899);
    g.fillEllipse(10, 12, 12, 9);
    // Body highlight (left side - light source)
    g.fillStyle(0xffaabb);
    g.fillEllipse(8, 11, 8, 7);
    // Specular highlight
    g.fillStyle(0xffccdd);
    g.fillEllipse(6, 9, 5, 4);
    // Hot spot
    g.fillStyle(0xffeeff, 0.7);
    g.fillCircle(5, 8, 2);

    // FRONT LEG (visible, cute stubby)
    g.fillStyle(0xcc5577);
    g.fillEllipse(6, 21, 4, 5);
    g.fillStyle(0xe07090);
    g.fillEllipse(6, 22, 3, 4);
    g.fillStyle(0xf08899);
    g.fillEllipse(6, 22, 2, 3);

    // HEAD (slightly larger, facing 3/4 toward camera)
    // Head shadow
    g.fillStyle(0xbb4466);
    g.fillCircle(9, 10, 8);
    // Head base
    g.fillStyle(0xdd6688);
    g.fillCircle(8, 9, 7.5);
    // Head mid
    g.fillStyle(0xee7799);
    g.fillCircle(7, 8, 6.5);
    // Head light
    g.fillStyle(0xff99aa);
    g.fillCircle(6, 7, 5);
    // Head specular
    g.fillStyle(0xffbbcc);
    g.fillCircle(5, 6, 3);

    // GILLS (coral fronds on back of head - DKC pre-rendered look)
    // Back gills (partially hidden)
    g.fillStyle(0xaa3355);
    g.fillCircle(16, 5, 3);
    g.fillCircle(17, 8, 2.5);
    g.fillCircle(16, 11, 2);
    g.fillStyle(0xcc4466);
    g.fillCircle(15, 5, 2.5);
    g.fillCircle(16, 8, 2);
    g.fillStyle(0xee6688);
    g.fillCircle(14, 5, 2);
    g.fillCircle(15, 8, 1.5);

    // Side gills (more visible, feathery)
    g.fillStyle(0xbb3355);
    g.fillCircle(13, 3, 3.5);
    g.fillCircle(11, 2, 3);
    g.fillCircle(9, 2, 2.5);
    g.fillStyle(0xdd5577);
    g.fillCircle(12, 3, 3);
    g.fillCircle(10, 2, 2.5);
    g.fillCircle(8, 2, 2);
    g.fillStyle(0xff7799);
    g.fillCircle(11, 3, 2);
    g.fillCircle(9, 2.5, 1.8);
    g.fillCircle(7, 3, 1.5);
    // Gill highlights
    g.fillStyle(0xffaacc);
    g.fillCircle(10, 3, 1);
    g.fillCircle(8, 3, 0.8);

    // BIG EYE (front eye - large and cute, 3/4 view)
    // Eye white
    g.fillStyle(0xffffff);
    g.fillEllipse(6, 9, 5, 5.5);
    // Eye outline
    g.lineStyle(0.5, 0x663355, 0.3);
    g.strokeEllipse(6, 9, 5, 5.5);
    // Pupil
    g.fillStyle(0x221133);
    g.fillEllipse(7, 9, 3, 3.5);
    // Iris color
    g.fillStyle(0x442244);
    g.fillEllipse(7, 9, 2.5, 3);
    // Inner pupil
    g.fillStyle(0x110011);
    g.fillCircle(7, 9, 1.5);
    // Big sparkle
    g.fillStyle(0xffffff);
    g.fillCircle(5, 7.5, 1.8);
    // Small sparkle
    g.fillStyle(0xffffff, 0.8);
    g.fillCircle(8, 10.5, 0.8);

    // SMALL EYE (back eye - partially visible in 3/4 view)
    g.fillStyle(0xeeeeff);
    g.fillEllipse(12, 8, 2.5, 3);
    g.fillStyle(0x332233);
    g.fillEllipse(12.5, 8, 1.5, 2);
    g.fillStyle(0xffffff, 0.7);
    g.fillCircle(11.5, 7, 0.8);

    // CUTE SMILE (small, happy)
    g.lineStyle(1, 0xaa3355);
    g.beginPath();
    g.arc(7, 13, 2.5, 0.2, Math.PI - 0.5);
    g.strokePath();

    // BLUSH (rosy cheek)
    g.fillStyle(0xff6688, 0.4);
    g.fillCircle(4, 12, 2);

    // NOSTRIL (tiny dot)
    g.fillStyle(0xaa4466);
    g.fillCircle(3, 10, 0.5);

    g.generateTexture('xochi-procedural-backup', 32, 32);
    */ // END OF REMOVED PROCEDURAL XOCHI
    g.clear();

    // ============ BIG XOCHI (powered up - uses same sprite scaled) ============
    // Tail
    g.fillStyle(0xbb5577);
    g.fillEllipse(26, 38, 12, 5);
    g.fillStyle(0xe07090);
    g.fillEllipse(25, 37, 10, 4);

    // Back leg
    g.fillStyle(0xcc5577);
    g.fillEllipse(20, 52, 5, 8);
    g.fillStyle(0xe07090);
    g.fillEllipse(20, 53, 4, 6);

    // Body
    g.fillStyle(0x993355);
    g.fillEllipse(14, 36, 18, 30);
    g.fillStyle(0xcc5577);
    g.fillEllipse(13, 35, 17, 28);
    g.fillStyle(0xe07090);
    g.fillEllipse(12, 34, 16, 26);
    g.fillStyle(0xf08899);
    g.fillEllipse(10, 32, 14, 22);
    g.fillStyle(0xffaabb);
    g.fillEllipse(8, 28, 10, 16);
    g.fillStyle(0xffccdd);
    g.fillCircle(6, 22, 5);

    // Front leg
    g.fillStyle(0xcc5577);
    g.fillEllipse(6, 52, 5, 8);
    g.fillStyle(0xe07090);
    g.fillEllipse(6, 53, 4, 6);

    // Head
    g.fillStyle(0xbb4466);
    g.fillCircle(10, 16, 10);
    g.fillStyle(0xdd6688);
    g.fillCircle(9, 15, 9);
    g.fillStyle(0xee7799);
    g.fillCircle(8, 14, 8);
    g.fillStyle(0xff99aa);
    g.fillCircle(7, 12, 6);
    g.fillStyle(0xffbbcc);
    g.fillCircle(5, 10, 4);

    // Gills
    g.fillStyle(0xbb3355);
    g.fillCircle(18, 8, 5);
    g.fillCircle(15, 5, 4);
    g.fillCircle(12, 4, 3.5);
    g.fillStyle(0xdd5577);
    g.fillCircle(17, 8, 4);
    g.fillCircle(14, 5, 3);
    g.fillCircle(11, 4, 2.5);
    g.fillStyle(0xff7799);
    g.fillCircle(16, 8, 3);
    g.fillCircle(13, 5, 2);
    g.fillCircle(10, 5, 2);

    // Big eye
    g.fillStyle(0xffffff);
    g.fillEllipse(7, 14, 6, 7);
    g.fillStyle(0x221133);
    g.fillEllipse(8, 14, 4, 5);
    g.fillStyle(0x442244);
    g.fillEllipse(8, 14, 3, 4);
    g.fillStyle(0xffffff);
    g.fillCircle(6, 12, 2.2);

    // Small eye
    g.fillStyle(0xeeeeff);
    g.fillEllipse(15, 12, 3, 4);
    g.fillStyle(0x332233);
    g.fillEllipse(15.5, 12, 2, 2.5);

    // Smile
    g.lineStyle(1.5, 0xaa3355);
    g.beginPath();
    g.arc(8, 20, 4, 0.2, Math.PI - 0.4);
    g.strokePath();

    // Blush
    g.fillStyle(0xff6688, 0.4);
    g.fillCircle(4, 18, 3);

    g.generateTexture('xochi-big', 32, 64);
    g.clear();

    // ============ SEAGULL ENEMY (white/cream with attitude) ============
    // Body shadow
    g.fillStyle(0x999999);
    g.fillEllipse(17, 20, 22, 18);
    // Body base - creamy white
    g.fillStyle(0xddddcc);
    g.fillEllipse(16, 18, 20, 16);
    // Body highlight
    g.fillStyle(0xeeeeee);
    g.fillEllipse(14, 14, 14, 10);
    // White chest
    g.fillStyle(0xfafafa);
    g.fillEllipse(16, 16, 10, 8);
    // Wing shadows (gray)
    g.fillStyle(0x888899);
    g.fillTriangle(3, 20, 12, 12, 12, 26);
    g.fillTriangle(29, 20, 20, 12, 20, 26);
    // Wing highlights
    g.fillStyle(0xaaaaaa);
    g.fillTriangle(5, 19, 12, 13, 12, 24);
    g.fillTriangle(27, 19, 20, 13, 20, 24);

    // Orange beak - chunky and angry
    g.fillStyle(0xdd8800);
    g.fillTriangle(16, 6, 9, 15, 23, 15);
    g.fillStyle(0xffaa22);
    g.fillTriangle(16, 8, 11, 14, 21, 14);
    g.fillStyle(0xffcc66);
    g.fillTriangle(16, 10, 13, 13, 19, 13);

    // Angry eyes
    g.fillStyle(0xffffff);
    g.fillCircle(11, 14, 4);
    g.fillCircle(21, 14, 4);
    // Red angry pupils
    g.fillStyle(0x222222);
    g.fillCircle(12, 14, 2.5);
    g.fillCircle(22, 14, 2.5);
    g.fillStyle(0x880000);
    g.fillCircle(12, 14, 1.5);
    g.fillCircle(22, 14, 1.5);
    // Tiny angry highlight
    g.fillStyle(0xffffff);
    g.fillCircle(11, 13, 1);
    g.fillCircle(21, 13, 1);

    // ANGRY eyebrows (V shape)
    g.fillStyle(0x333333);
    g.fillTriangle(6, 9, 14, 11, 14, 13);
    g.fillTriangle(26, 9, 18, 11, 18, 13);

    // Feet
    g.fillStyle(0xdd8800);
    g.fillRect(12, 28, 2, 4);
    g.fillRect(18, 28, 2, 4);

    g.generateTexture('enemy', 32, 32);
    g.clear();

    // ============ AZTEC-STYLE GOLD COIN ============
    // ============ CEMPASUCHIL (Mexican Marigold) - Replaces Coins ============
    // Outer glow (orange)
    g.fillStyle(0xff8c00, 0.2);
    g.fillCircle(8, 8, 9);
    // Outer petals (orange) - 8 petals around the edge
    g.fillStyle(0xff6600);
    for (let i = 0; i < 8; i++) {
      const angle = (i / 8) * Math.PI * 2;
      g.fillCircle(8 + Math.cos(angle) * 5, 8 + Math.sin(angle) * 5, 3);
    }
    // Middle petals (bright orange)
    g.fillStyle(0xff8c00);
    for (let i = 0; i < 8; i++) {
      const angle = (i / 8) * Math.PI * 2 + Math.PI / 8;
      g.fillCircle(8 + Math.cos(angle) * 3.5, 8 + Math.sin(angle) * 3.5, 2.5);
    }
    // Inner petals (yellow-orange)
    g.fillStyle(0xffaa00);
    for (let i = 0; i < 6; i++) {
      const angle = (i / 6) * Math.PI * 2;
      g.fillCircle(8 + Math.cos(angle) * 2, 8 + Math.sin(angle) * 2, 2);
    }
    // Center (golden yellow)
    g.fillStyle(0xffcc00);
    g.fillCircle(8, 8, 2.5);
    // Center highlight
    g.fillStyle(0xffee66);
    g.fillCircle(7, 7, 1.5);
    // Tiny sparkle
    g.fillStyle(0xffffff);
    g.fillCircle(6.5, 6.5, 0.8);
    g.generateTexture('flower', 16, 16);
    g.clear();

    // ============ SPARKLY GOLDEN STAR ============
    // Outer glow
    g.fillStyle(0xffff00, 0.25);
    g.fillCircle(8, 8, 9);
    // Star shadow
    g.fillStyle(0xcc8800);
    drawStar(g, 9, 9, 5, 7, 3);
    // Star base
    g.fillStyle(0xffbb00);
    drawStar(g, 8, 8, 5, 7, 3);
    // Star highlight
    g.fillStyle(0xffdd44);
    drawStar(g, 7.5, 7.5, 5, 5.5, 2.5);
    // Inner glow
    g.fillStyle(0xffee88);
    drawStar(g, 7.5, 7.5, 5, 4, 2);
    // Center sparkle
    g.fillStyle(0xffffff);
    g.fillCircle(7, 6, 2);
    g.fillCircle(6, 5, 1);
    // Tiny sparkle points
    g.fillStyle(0xffffff, 0.8);
    g.fillCircle(3, 3, 0.8);
    g.fillCircle(12, 4, 0.8);
    g.fillCircle(4, 11, 0.8);
    g.generateTexture('star', 16, 16);
    g.clear();

    // ============ MUSHROOM POWERUP ============
    // Cap shadow
    g.fillStyle(0xaa2222);
    g.fillEllipse(8, 7, 15, 11);
    // Cap base
    g.fillStyle(0xdd3333);
    g.fillEllipse(8, 6, 14, 10);
    // Cap mid
    g.fillStyle(0xee4444);
    g.fillEllipse(7, 5, 12, 8);
    // Cap highlight
    g.fillStyle(0xff6666);
    g.fillEllipse(5, 3, 6, 4);
    // White spots with depth
    g.fillStyle(0xeeeeee);
    g.fillCircle(4, 4, 2.5);
    g.fillCircle(11, 3, 2);
    g.fillCircle(7, 7, 1.5);
    g.fillStyle(0xffffff);
    g.fillCircle(3.5, 3.5, 1.5);
    g.fillCircle(10.5, 2.5, 1.2);
    // Stem
    g.fillStyle(0xddddcc);
    g.fillRect(5, 10, 7, 6);
    g.fillStyle(0xffffee);
    g.fillRect(5, 10, 6, 5);
    g.fillStyle(0xffffff);
    g.fillRect(6, 10, 2, 4);
    g.generateTexture('mushroom', 16, 16);
    g.clear();

    // ============ ELOTE (Mexican Corn on Stick) - Replaces Star Powerup ============
    // Stick (brown wooden handle)
    g.fillStyle(0x8b4513);
    g.fillRect(6, 12, 4, 5);
    g.fillStyle(0xa0522d);
    g.fillRect(7, 12, 2, 4);
    // Corn cob base (yellow)
    g.fillStyle(0xdaa520);
    g.fillEllipse(8, 7, 10, 12);
    // Corn cob mid (brighter yellow)
    g.fillStyle(0xffd700);
    g.fillEllipse(8, 7, 9, 11);
    // Corn kernels pattern (rows of dots)
    g.fillStyle(0xffec8b);
    for (let row = 0; row < 5; row++) {
      for (let col = 0; col < 4; col++) {
        const kx = 5 + col * 2 + (row % 2) * 1;
        const ky = 3 + row * 2;
        g.fillCircle(kx, ky, 1);
      }
    }
    // Chile powder dots (red speckles)
    g.fillStyle(0xcc0000);
    g.fillCircle(4, 5, 0.8);
    g.fillCircle(10, 4, 0.8);
    g.fillCircle(6, 8, 0.8);
    g.fillCircle(11, 7, 0.8);
    g.fillCircle(5, 10, 0.8);
    g.fillCircle(9, 9, 0.8);
    // Highlight
    g.fillStyle(0xfffacd);
    g.fillCircle(5, 4, 1.5);
    // Outer glow (golden)
    g.fillStyle(0xffd700, 0.15);
    g.fillCircle(8, 7, 10);
    g.generateTexture('elote', 16, 16);
    g.clear();

    // ============ BLUE DEMON LUCHADOR MASK ============
    // Outer glow (blue)
    g.fillStyle(0x0066ff, 0.25);
    g.fillCircle(8, 8, 9);
    // Mask base (dark blue)
    g.fillStyle(0x000066);
    g.fillCircle(8, 8, 7);
    // Mask face (blue)
    g.fillStyle(0x0033aa);
    g.fillCircle(8, 8, 6);
    // Eye holes (white with black outline)
    g.fillStyle(0xffffff);
    g.fillEllipse(5, 6, 4, 3);
    g.fillEllipse(11, 6, 4, 3);
    // Eye hole outlines
    g.lineStyle(1, 0x000000);
    g.strokeEllipse(5, 6, 4, 3);
    g.strokeEllipse(11, 6, 4, 3);
    // Lightning bolts on forehead (iconic Blue Demon design)
    g.fillStyle(0x00ccff);
    g.fillTriangle(4, 2, 6, 4, 4, 4);
    g.fillTriangle(12, 2, 10, 4, 12, 4);
    // Mask trim (silver)
    g.lineStyle(1.5, 0xcccccc);
    g.beginPath();
    g.arc(8, 8, 6.5, Math.PI * 0.8, Math.PI * 0.2, true);
    g.strokePath();
    // Mouth area (darker)
    g.fillStyle(0x001144);
    g.fillEllipse(8, 11, 4, 2);
    // Sparkle
    g.fillStyle(0xffffff);
    g.fillCircle(4, 3, 1);
    g.generateTexture('blueDemonMask', 16, 16);
    g.clear();

    // ============ CUTE BABY AXOLOTL ============
    // Shadow
    g.fillStyle(0xcc6699);
    g.fillCircle(9, 9, 6);
    // Body
    g.fillStyle(0xffaacc);
    g.fillCircle(8, 8, 6);
    // Highlight
    g.fillStyle(0xffccdd);
    g.fillCircle(6, 6, 3.5);
    // Top specular
    g.fillStyle(0xffeeff);
    g.fillCircle(5, 5, 2);
    // Mini gills
    g.fillStyle(0xee77aa);
    g.fillCircle(2, 4, 2.5);
    g.fillCircle(1, 7, 2);
    g.fillCircle(14, 4, 2.5);
    g.fillCircle(15, 7, 2);
    g.fillStyle(0xffaacc);
    g.fillCircle(2.5, 4.5, 1.5);
    g.fillCircle(13.5, 4.5, 1.5);
    // Big sparkly eyes
    g.fillStyle(0xffffff);
    g.fillCircle(5, 7, 2.5);
    g.fillCircle(11, 7, 2.5);
    g.fillStyle(0x222244);
    g.fillCircle(5.5, 7, 1.5);
    g.fillCircle(11.5, 7, 1.5);
    g.fillStyle(0xffffff);
    g.fillCircle(4.5, 6, 1);
    g.fillCircle(10.5, 6, 1);
    // Tiny smile
    g.lineStyle(1, 0xdd6699);
    g.beginPath();
    g.arc(8, 10, 2, 0.3, Math.PI - 0.3);
    g.strokePath();
    // Blush
    g.fillStyle(0xff8899, 0.4);
    g.fillCircle(3, 10, 1.5);
    g.fillCircle(13, 10, 1.5);
    g.generateTexture('baby', 16, 16);
    g.clear();

    // ============ MAGICAL SUPER JUMP FEATHER ============
    // Outer magic glow
    g.fillStyle(0x00ffff, 0.2);
    g.fillCircle(8, 8, 8);
    // Inner glow
    g.fillStyle(0x44ffff, 0.3);
    g.fillCircle(8, 7, 6);
    // Feather shadow
    g.fillStyle(0x0088aa);
    g.fillTriangle(8, 1, 1, 12, 15, 12);
    // Feather base
    g.fillStyle(0x00bbdd);
    g.fillTriangle(8, 2, 2, 11, 14, 11);
    // Feather highlight
    g.fillStyle(0x44ddee);
    g.fillTriangle(8, 3, 4, 10, 12, 10);
    // Inner feather
    g.fillStyle(0x88eeff);
    g.fillTriangle(8, 5, 5, 9, 11, 9);
    // Feather spine
    g.lineStyle(1, 0x008899);
    g.lineBetween(8, 2, 8, 11);
    // Feather veins
    g.lineStyle(0.5, 0x00aacc, 0.5);
    g.lineBetween(8, 4, 5, 8);
    g.lineBetween(8, 4, 11, 8);
    g.lineBetween(8, 6, 4, 10);
    g.lineBetween(8, 6, 12, 10);
    // Magic sparkles
    g.fillStyle(0xffffff);
    g.fillCircle(5, 5, 1);
    g.fillCircle(11, 5, 1);
    g.fillCircle(8, 3, 1.5);
    // Crystal base
    g.fillStyle(0x006688);
    g.fillRect(5, 11, 6, 4);
    g.fillStyle(0x00aacc);
    g.fillRect(6, 11, 4, 3);
    g.fillStyle(0x66eeff);
    g.fillRect(7, 11, 2, 2);
    g.generateTexture('superjump', 16, 16);
    g.clear();

    // ============ ENEMY PROJECTILE (angry red orb) ============
    // Outer glow
    g.fillStyle(0xff0000, 0.3);
    g.fillCircle(6, 6, 6);
    // Fire ring
    g.fillStyle(0xff4400);
    g.fillCircle(6, 6, 5);
    // Core
    g.fillStyle(0xff6600);
    g.fillCircle(6, 6, 4);
    // Hot center
    g.fillStyle(0xffaa00);
    g.fillCircle(5, 5, 2.5);
    // White hot
    g.fillStyle(0xffdd88);
    g.fillCircle(4, 4, 1.5);
    g.fillStyle(0xffffff);
    g.fillCircle(4, 4, 0.8);
    g.generateTexture('projectile', 12, 12);
    g.clear();

    g.destroy();
  }
}

// ============== MENU SCENE ==============
class MenuScene extends Phaser.Scene {
  constructor() { super('MenuScene'); }

  create() {
    const { width, height } = this.cameras.main;

    // Initialize and play menu music
    mariachiMusic.init(this);
    if (gameState.musicEnabled) {
      mariachiMusic.start('music-menu');
    }

    // ============ SNES-STYLE GRADIENT BACKGROUND ============
    const bg = this.add.graphics();
    const bgColors = [0x1a0a2e, 0x1a1a3e, 0x2a2a4e, 0x1a2a4e, 0x1a1a3e, 0x1a0a2e];
    const stripeH = height / bgColors.length;
    bgColors.forEach((color, i) => {
      bg.fillStyle(color);
      bg.fillRect(0, i * stripeH, width, stripeH + 2);
    });

    // ============ ANIMATED STARS BACKGROUND ============
    for (let i = 0; i < 30; i++) {
      const star = this.add.circle(
        Phaser.Math.Between(0, width),
        Phaser.Math.Between(0, height),
        Phaser.Math.Between(1, 3),
        0xffffff, Phaser.Math.FloatBetween(0.2, 0.8)
      );
      this.tweens.add({
        targets: star, alpha: 0.1,
        duration: Phaser.Math.Between(500, 1500),
        yoyo: true, repeat: -1
      });
    }

    // ============ FLOATING PARTICLES ============
    for (let i = 0; i < 12; i++) {
      const colors = [0x4ecdc4, 0xff6b9d, 0xffdd00];
      const p = this.add.circle(
        Phaser.Math.Between(0, width),
        Phaser.Math.Between(0, height),
        Phaser.Math.Between(3, 6),
        Phaser.Utils.Array.GetRandom(colors), 0.4
      );
      this.tweens.add({
        targets: p, y: '-=120', alpha: 0, scale: 0.5,
        duration: Phaser.Math.Between(3000, 5000),
        repeat: -1,
        onRepeat: () => { p.x = Phaser.Math.Between(0, width); p.y = height + 30; p.alpha = 0.4; p.scale = 1; }
      });
    }

    // ============ SNES-STYLE TITLE WITH SHADOW ============
    // Title shadow
    this.add.text(width/2 + 4, 58 + 4, 'XOCHI', {
      fontFamily: 'Arial Black', fontSize: '60px', color: '#220022'
    }).setOrigin(0.5);
    // Title main
    const title = this.add.text(width/2, 58, 'XOCHI', {
      fontFamily: 'Arial Black', fontSize: '60px', color: '#ff6b9d',
      stroke: '#ffbbcc', strokeThickness: 4
    }).setOrigin(0.5);
    // Title shine animation
    this.tweens.add({ targets: title, scaleX: 1.02, scaleY: 1.02, duration: 1500, yoyo: true, repeat: -1, ease: 'Sine.easeInOut' });

    // Subtitle with glow
    this.add.text(width/2, 108, 'Aztec Warrior Adventure', {
      fontFamily: 'Georgia', fontSize: '20px', color: '#66ddcc',
      stroke: '#224444', strokeThickness: 2
    }).setOrigin(0.5);

    // ============ CHARACTER PREVIEW WITH GLOW ============
    // Glow behind character
    const glow = this.add.circle(width/2, 170, 35, 0xff6b9d, 0.3);
    this.tweens.add({ targets: glow, scale: 1.2, alpha: 0.1, duration: 1000, yoyo: true, repeat: -1 });
    // Character
    const xochi = this.add.sprite(width/2, 170, 'xochi_walk').setScale(0.28);
    this.tweens.add({ targets: xochi, y: 160, duration: 800, yoyo: true, repeat: -1, ease: 'Sine.easeInOut' });

    // ============ SNES-STYLE SCOREBOARD ============
    // Box shadow
    this.add.rectangle(width/2 + 3, 243, 310, 68, 0x000000, 0.5);
    // Box border
    this.add.rectangle(width/2, 240, 310, 68, 0x4ecdc4);
    // Box fill
    this.add.rectangle(width/2, 240, 304, 62, 0x1a2a4e);
    // Inner highlight
    this.add.rectangle(width/2, 218, 300, 2, 0x5eede4, 0.5);

    this.add.text(width/2, 222, `SCORE: ${gameState.score}`, {
      fontFamily: 'Arial Black', fontSize: '20px', color: '#ffee44',
      stroke: '#886600', strokeThickness: 2
    }).setOrigin(0.5);
    this.add.text(width/2, 250, `HIGH SCORE: ${gameState.highScore}`, {
      fontFamily: 'Arial', fontSize: '15px', color: '#ff88aa'
    }).setOrigin(0.5);

    // Progress bar style
    this.add.text(width/2, 290, `Level ${gameState.currentLevel}/11 | ★ ${gameState.stars.length}/33 | ♥ ${gameState.rescuedBabies.length}/11`, {
      fontFamily: 'Arial', fontSize: '13px', color: '#88aacc'
    }).setOrigin(0.5);

    // ============ DIFFICULTY SELECTOR (DKC2 style) ============
    const diffColors = {
      easy: { bg: 0x44aa44, text: '#88ff88', label: 'EASY' },
      medium: { bg: 0xaaaa44, text: '#ffff88', label: 'MEDIUM' },
      hard: { bg: 0xaa4444, text: '#ff8888', label: 'HARD' }
    };

    this.add.text(width/2, 320, 'DIFFICULTY', {
      fontFamily: 'Arial Black', fontSize: '12px', color: '#aaaaaa'
    }).setOrigin(0.5);

    const diffButtons = ['easy', 'medium', 'hard'];
    const btnWidth = 70;
    const startX = width/2 - btnWidth - 10;

    this.difficultyTexts = {};
    diffButtons.forEach((diff, i) => {
      const x = startX + i * (btnWidth + 10);
      const isSelected = gameState.difficulty === diff;
      const colors = diffColors[diff];

      // Button background
      const btnBg = this.add.rectangle(x, 345, btnWidth, 28, isSelected ? colors.bg : 0x333333)
        .setInteractive({ useHandCursor: true });
      btnBg.diffKey = diff;

      // Selection border
      if (isSelected) {
        this.add.rectangle(x, 345, btnWidth + 4, 32, 0xffffff).setDepth(-1);
      }

      // Button text
      const txt = this.add.text(x, 345, colors.label, {
        fontFamily: 'Arial Black', fontSize: '11px',
        color: isSelected ? colors.text : '#666666'
      }).setOrigin(0.5);

      this.difficultyTexts[diff] = { bg: btnBg, txt };

      btnBg.on('pointerdown', () => {
        if (gameState.sfxEnabled) {
          this.sound.play('sfx-select', { volume: 0.7 });
        }
        gameState.difficulty = diff;
        gameState.lives = DIFFICULTY_SETTINGS[diff].lives;
        saveGame();
        // Restart menu to refresh buttons
        this.scene.restart();
      });

      btnBg.on('pointerover', () => {
        if (gameState.difficulty !== diff) {
          btnBg.setFillStyle(0x555555);
        }
      });
      btnBg.on('pointerout', () => {
        if (gameState.difficulty !== diff) {
          btnBg.setFillStyle(0x333333);
        }
      });
    });

    // Difficulty description
    const diffDesc = {
      easy: '5 lives, 3 super jumps, easier gaps',
      medium: '3 lives, 2 super jumps, balanced',
      hard: '2 lives, 1 super jump, challenging'
    };
    this.add.text(width/2, 370, diffDesc[gameState.difficulty], {
      fontFamily: 'Arial', fontSize: '10px', color: '#888888'
    }).setOrigin(0.5);

    // ============ SNES-STYLE BUTTONS ============
    // CONTINUE/PLAY button
    this.createSNESButton(width/2, 415, 200, 50, 0x33bb99, 0x22aa88, 0x44ccaa,
      gameState.currentLevel > 1 ? 'CONTINUE' : 'PLAY', () => {
        this.scene.start('GameScene', { level: gameState.currentLevel });
      });

    // NEW GAME button
    this.createSNESButton(width/2, 475, 200, 50, 0xdd5588, 0xcc4477, 0xee6699,
      'NEW GAME', () => {
        resetGame();
        this.scene.start('GameScene', { level: 1 });
      });

    // ============ WORLD SELECTION ============
    this.add.text(width/2, 510, 'SELECT WORLD', {
      fontFamily: 'Arial Black', fontSize: '12px', color: '#aaaaaa'
    }).setOrigin(0.5);

    // World selector buttons (6 worlds × 2 levels each)
    const worldData = [
      { num: 1, icon: '🌅', name: 'Dawn', color: 0xffaa77 },
      { num: 2, icon: '☀️', name: 'Day', color: 0x55ccee },
      { num: 3, icon: '💎', name: 'Cave', color: 0x4466aa },
      { num: 4, icon: '🌸', name: 'Garden', color: 0xffcc44 },
      { num: 5, icon: '🌙', name: 'Night', color: 0x6644aa },
      { num: 6, icon: '🎉', name: 'Fiesta', color: 0xff69b4 }
    ];

    const btnSize = 42;
    const worldStartX = width/2 - (worldData.length * btnSize) / 2 + btnSize/2;

    worldData.forEach((world, i) => {
      const x = worldStartX + i * btnSize;
      const y = 540;
      const firstLevel = getFirstLevelOfWorld(world.num);
      const isUnlocked = true;  // All worlds always available for selection!
      const isCurrent = getWorldForLevel(gameState.currentLevel) === world.num;

      // Button background
      const btnBg = this.add.rectangle(x, y, btnSize - 4, btnSize - 4,
        isUnlocked ? world.color : 0x333333, isUnlocked ? 1 : 0.5);

      // Current world indicator
      if (isCurrent) {
        this.add.rectangle(x, y, btnSize, btnSize, 0xffffff).setDepth(-1);
      }

      // World number
      this.add.text(x, y - 8, world.icon, {
        fontSize: '14px'
      }).setOrigin(0.5);

      this.add.text(x, y + 10, `W${world.num}`, {
        fontFamily: 'Arial', fontSize: '10px',
        color: isUnlocked ? '#ffffff' : '#666666'
      }).setOrigin(0.5);

      if (isUnlocked) {
        btnBg.setInteractive({ useHandCursor: true });

        btnBg.on('pointerover', () => {
          btnBg.setScale(1.1);
          // Show world name tooltip
          if (!this.worldTooltip) {
            this.worldTooltip = this.add.text(width/2, 575, '', {
              fontFamily: 'Arial', fontSize: '11px', color: '#ffffff',
              backgroundColor: '#000000', padding: { x: 8, y: 4 }
            }).setOrigin(0.5).setDepth(100);
          }
          this.worldTooltip.setText(`${WORLDS[world.num].name} - ${WORLDS[world.num].subtitle}`);
          this.worldTooltip.setVisible(true);
        });

        btnBg.on('pointerout', () => {
          btnBg.setScale(1);
          if (this.worldTooltip) this.worldTooltip.setVisible(false);
        });

        btnBg.on('pointerdown', () => {
          if (gameState.sfxEnabled) {
            this.sound.play('sfx-select', { volume: 0.7 });
          }
          const startLevel = getFirstLevelOfWorld(world.num);
          gameState.currentLevel = startLevel;
          saveGame();
          this.scene.start('GameScene', { level: startLevel });
        });
      }
    });

    // Controls - simplified!
    this.add.text(width/2, height - 25, 'WASD/Arrows = Move | SPACE = Run | X = Jump | Z = Attack', {
      fontFamily: 'Arial', fontSize: '9px', color: '#555555'
    }).setOrigin(0.5);
    this.add.text(width/2, height - 10, 'Grab ledges by pressing toward them while falling!', {
      fontFamily: 'Arial', fontSize: '9px', color: '#666666'
    }).setOrigin(0.5);

    // Keyboard shortcut to start
    this.input.keyboard.on('keydown-X', () => {
      if (gameState.sfxEnabled) {
        this.sound.play('sfx-select', { volume: 0.7 });
      }
      this.scene.start('GameScene', { level: gameState.currentLevel });
    });
  }

  // SNES-style 3D button helper
  createSNESButton(x, y, w, h, baseColor, darkColor, lightColor, text, callback) {
    // Shadow
    this.add.rectangle(x + 3, y + 3, w, h, 0x000000, 0.4);
    // Dark edge (bottom/right)
    this.add.rectangle(x + 2, y + 2, w, h, darkColor);
    // Main button
    const btn = this.add.rectangle(x, y, w - 4, h - 4, baseColor).setInteractive({ useHandCursor: true });
    // Top highlight
    this.add.rectangle(x, y - h/4, w - 8, 4, lightColor, 0.5);
    // Text shadow
    this.add.text(x + 2, y + 2, text, { fontFamily: 'Arial Black', fontSize: '22px', color: '#000000' }).setOrigin(0.5);
    // Text
    this.add.text(x, y, text, { fontFamily: 'Arial Black', fontSize: '22px', color: '#ffffff', stroke: '#000000', strokeThickness: 1 }).setOrigin(0.5);

    btn.on('pointerover', () => { btn.setScale(1.05); btn.setFillStyle(lightColor); });
    btn.on('pointerout', () => { btn.setScale(1); btn.setFillStyle(baseColor); });
    btn.on('pointerdown', () => {
      try {
        if (gameState.sfxEnabled) {
          this.sound.play('sfx-select', { volume: 0.7 });
        }
      } catch (e) {
        console.log('Sound error:', e);
      }
      callback();
    });
    return btn;
  }
}

// ============== GAME SCENE ==============
class GameScene extends Phaser.Scene {
  constructor() { super('GameScene'); }

  init(data) {
    this.levelNum = data.level || 1;

    // ============ WORLD FLOW - Each world has variety! ============
    //
    // WORLD 1 - Canal Dawn (Tutorial) - Pink/orange sunrise
    //   Level 1: Side-scroller - Learn the basics, trajineras everywhere
    //   Level 2: Side-scroller - Practice, slightly harder
    //
    // WORLD 2 - Trajineras Brillantes (Bright Day) - Blue sky
    //   Level 3: Upscroller - NEW! Climb up, water rises below
    //   Level 4: Side-scroller - Back to horizontal, faster boats
    //
    // WORLD 3 - Cueva de Cristal (Crystal Cave) - Dark blue
    //   Level 5: BOSS - Dark Xochi appears!
    //
    // WORLD 4 - Jardines Flotantes (Floating Gardens) - Golden sunset
    //   Level 6: Side-scroller - Beautiful but dangerous
    //   Level 7: Escape - NEW! The flood is coming, RUN!
    //
    // WORLD 5 - Canales de Noche (Night Canals) - Moonlit purple
    //   Level 8: Upscroller - Harder vertical climb in darkness
    //   Level 9: Escape - Intense chase, faster flood!
    //
    // WORLD 6 - La Gran Fiesta (The Grand Festival) - Teal celebration
    //   Level 10: FINAL BOSS - Dark Xochi rematch!

    const isFiestaLevel = this.levelNum === 11;
    const isBossLevel = this.levelNum === 5 || this.levelNum === 10;
    const isUpscrollerLevel = this.levelNum === 3 || this.levelNum === 8;
    const isEscapeLevel = this.levelNum === 9;

    if (isFiestaLevel) {
      this.levelData = generateFiestaLevel();
    } else if (isBossLevel) {
      this.levelData = generateBossArena(this.levelNum);
    } else if (isUpscrollerLevel) {
      this.levelData = generateUpscrollerLevel(this.levelNum);
    } else if (isEscapeLevel) {
      this.levelData = generateEscapeLevel(this.levelNum);
    } else {
      this.levelData = generateXochimilcoLevel(this.levelNum);
    }
  }

  create() {
    const ld = this.levelData;

    // Initialize music for this level
    mariachiMusic.init(this);
    const worldNum = getWorldForLevel(this.levelNum);
    if (gameState.musicEnabled) {
      mariachiMusic.playForLevel(this.levelNum, worldNum);
    }

    // World bounds
    this.physics.world.setBounds(0, 0, ld.width, ld.height);

    // ============ DKC2-STYLE SKY WITH GRADIENT (using theme) ============
    const theme = ld.theme || WORLDS[1]; // Default to World 1 theme
    const skyGradient = this.add.graphics();
    const skyColors = theme.sky;
    const stripeHeight = ld.height / skyColors.length;
    skyColors.forEach((color, i) => {
      skyGradient.fillStyle(color);
      skyGradient.fillRect(0, i * stripeHeight, ld.width, stripeHeight + 2);
    });
    skyGradient.setDepth(-110);  // Behind all parallax layers

    // ============ SIX-LAYER PARALLAX BACKGROUND ============
    // Build atmospheric depth with procedurally drawn layers
    this.parallaxLayers = buildParallaxLayers(this, theme, ld.width, ld.height);

    // ============ GOD RAYS (for Day/Dawn/Sunset themes) ============
    // Check if this is a night/cave world (worlds 3 and 5)
    const isNightOrCave = theme.worldNum === 3 || theme.worldNum === 5;
    if (!isNightOrCave) {
      for (let i = 0; i < 5; i++) {
        const rayX = 100 + i * (ld.width / 5);
        const ray = this.add.triangle(rayX, 0, 0, 0, -40 - i * 10, ld.height, 40 + i * 10, ld.height, 0xffffcc, 0.03);
        ray.setScrollFactor(0.02);
        ray.setDepth(-105);  // Between sky and parallax
        // Subtle ray animation
        this.tweens.add({
          targets: ray,
          alpha: 0.01,
          duration: 3000 + i * 500,
          yoyo: true,
          repeat: -1,
          ease: 'Sine.easeInOut'
        });
      }
    }

    // ============ ANIMATED CLOUDS (DKC2 style - moving!) ============
    this.clouds = [];
    // Far clouds (slower, smaller)
    for (let i = 0; i < 10; i++) {
      const cx = Phaser.Math.Between(-100, ld.width + 100);
      const cy = Phaser.Math.Between(30, 100);
      const cw = Phaser.Math.Between(60, 120);
      const ch = Phaser.Math.Between(25, 40);

      // Cloud shadow
      const shadow = this.add.ellipse(cx + 3, cy + 3, cw, ch, 0x99bbdd, 0.2).setScrollFactor(0.1);
      // Cloud body
      const cloud = this.add.ellipse(cx, cy, cw, ch, 0xffffff, 0.7).setScrollFactor(0.1);
      // Cloud highlight
      const highlight = this.add.ellipse(cx - cw * 0.2, cy - ch * 0.2, cw * 0.5, ch * 0.5, 0xffffff, 0.9).setScrollFactor(0.1);

      // Animate cloud movement
      const speed = 0.02 + Math.random() * 0.03;
      this.clouds.push({ shadow, cloud, highlight, speed, baseX: cx });
    }

    // Near clouds (faster, bigger, puffier)
    for (let i = 0; i < 6; i++) {
      const cx = Phaser.Math.Between(-100, ld.width + 100);
      const cy = Phaser.Math.Between(60, 140);
      const cw = Phaser.Math.Between(100, 180);
      const ch = Phaser.Math.Between(40, 60);

      const shadow = this.add.ellipse(cx + 4, cy + 4, cw, ch, 0xaaccee, 0.15).setScrollFactor(0.25);
      const cloud = this.add.ellipse(cx, cy, cw, ch, 0xffffff, 0.6).setScrollFactor(0.25);
      const puff1 = this.add.ellipse(cx - cw * 0.3, cy, cw * 0.5, ch * 0.8, 0xffffff, 0.7).setScrollFactor(0.25);
      const puff2 = this.add.ellipse(cx + cw * 0.3, cy, cw * 0.5, ch * 0.8, 0xffffff, 0.7).setScrollFactor(0.25);

      const speed = 0.05 + Math.random() * 0.05;
      this.clouds.push({ shadow, cloud, puff1, puff2, speed, baseX: cx, near: true });
    }

    // ============ PIECE 5: WORLD-SPECIFIC PARTICLE ATMOSPHERE ============
    // Creates atmospheric particles unique to each world (max 50 particles)
    this.particles = createWorldParticles(this, theme, ld.width, ld.height);

    // ============ DKC2-STYLE PLATFORMS WITH AZTEC DETAILS ============
    this.platforms = this.physics.add.staticGroup();
    ld.platforms.forEach(p => {
      const isGround = p.h > 30;
      const isSkyPlatform = p.y < 150;

      // Color scheme based on platform type
      let baseColor, darkColor, lightColor, topColor;
      if (isGround) {
        baseColor = 0x8B5522; darkColor = 0x5a3311; lightColor = 0xaa7744; topColor = 0x55aa44;
      } else if (isSkyPlatform) {
        // Sky platforms are golden/Aztec themed
        baseColor = 0xccaa44; darkColor = 0x997722; lightColor = 0xeedd66; topColor = 0xffee88;
      } else {
        baseColor = 0x44aa55; darkColor = 0x338844; lightColor = 0x66cc77; topColor = 0x77dd88;
      }

      // Platform shadow (deeper)
      this.add.rectangle(p.x + p.w/2 + 4, p.y + p.h/2 + 4, p.w, p.h, 0x000000, 0.25);

      // Platform base (dark edge)
      this.add.rectangle(p.x + p.w/2, p.y + p.h/2, p.w, p.h, darkColor);

      // Platform main body
      const plat = this.add.rectangle(p.x + p.w/2, p.y + p.h/2 - 2, p.w - 2, p.h - 4, baseColor);
      this.physics.add.existing(plat, true);
      this.platforms.add(plat);

      // Platform top highlight
      this.add.rectangle(p.x + p.w/2, p.y + 4, p.w - 4, 6, lightColor);

      // Grass/moss surface
      this.add.rectangle(p.x + p.w/2, p.y + 2, p.w - 2, 3, topColor);

      if (!isGround) {
        // Animated grass tufts
        for (let gx = p.x + 12; gx < p.x + p.w - 12; gx += 18) {
          const grass = this.add.triangle(gx, p.y, gx - 4, p.y, gx, p.y - 8, gx + 4, p.y, 0x55cc66, 0.9);
          // Gentle sway
          this.tweens.add({
            targets: grass,
            angle: Phaser.Math.Between(-5, 5),
            duration: 1500 + Phaser.Math.Between(0, 500),
            yoyo: true,
            repeat: -1,
            ease: 'Sine.easeInOut'
          });
        }

        // Hanging vines on some platforms
        if (Math.random() < 0.4 && p.w > 60) {
          const vineX = p.x + Phaser.Math.Between(15, p.w - 15);
          for (let v = 0; v < 4; v++) {
            const vine = this.add.ellipse(vineX + Math.sin(v) * 3, p.y + p.h + v * 12, 4, 10, 0x228833, 0.7);
            this.tweens.add({
              targets: vine,
              x: vine.x + Phaser.Math.Between(-3, 3),
              duration: 2000,
              yoyo: true,
              repeat: -1,
              ease: 'Sine.easeInOut'
            });
          }
        }

        // Aztec symbols on sky platforms
        if (isSkyPlatform && p.w > 50) {
          const symbolX = p.x + p.w / 2;
          const symbolY = p.y + p.h / 2;
          // Simple aztec pattern (diamond)
          this.add.rectangle(symbolX, symbolY, 8, 8, 0x664422, 0.5).setAngle(45);
          this.add.rectangle(symbolX, symbolY, 4, 4, 0xffdd88, 0.8).setAngle(45);
        }
      }

      // Dirt texture for ground
      if (isGround && p.h > 35) {
        for (let dy = 15; dy < p.h - 5; dy += 12) {
          this.add.rectangle(p.x + p.w/2, p.y + dy, p.w - 10, 2, darkColor, 0.3);
        }
        // Add some rocks in ground
        for (let rx = p.x + 50; rx < p.x + p.w - 50; rx += Phaser.Math.Between(80, 150)) {
          const rockSize = Phaser.Math.Between(8, 15);
          this.add.ellipse(rx, p.y + 8, rockSize, rockSize * 0.6, 0x666666, 0.3);
        }
      }

      // ============ PIECE 6: PLATFORM VISUAL ENHANCEMENT ============
      // Apply depth effects, world-specific decorations, and breathing animation
      enhancePlatform(this, p, theme, plat);
    });

    // ============ XOCHIMILCO WATER LEVEL SPECIAL HANDLING ============
    this.trajineras = [];  // Moving boats
    // All level types with water: Frogger, Xochimilco side-scroller, Upscroller
    this.isWaterLevel = ld.isFroggerLevel || ld.isXochimilcoLevel || ld.isUpscroller || ld.isEscapeLevel || false;
    this.waterY = ld.waterY || ld.height;

    if (this.isWaterLevel) {
      // Water visual layer (behind everything else)
      const waterColor = ld.theme.waterColor || 0x2299aa;

      // Animated water surface
      this.waterGraphics = this.add.graphics().setDepth(-10);
      this.waterGraphics.fillStyle(waterColor, 0.8);
      this.waterGraphics.fillRect(0, this.waterY, ld.width, ld.height - this.waterY + 100);

      // Water shimmer overlay
      for (let wx = 0; wx < ld.width; wx += 60) {
        const shimmer = this.add.ellipse(wx, this.waterY + 20, 40, 8, 0x66ddff, 0.3).setDepth(-9);
        this.tweens.add({
          targets: shimmer,
          x: shimmer.x + 30,
          alpha: 0.5,
          duration: 1500 + Math.random() * 500,
          yoyo: true,
          repeat: -1,
          ease: 'Sine.easeInOut'
        });
      }

      // Lily pads floating on water
      for (let lx = 200; lx < ld.width - 300; lx += 300 + Math.random() * 200) {
        const lilypad = this.add.ellipse(lx, this.waterY + 5, 50 + Math.random() * 30, 20, 0x44aa44, 0.7).setDepth(-8);
        // Gentle float animation
        this.tweens.add({
          targets: lilypad,
          y: lilypad.y + 3,
          scaleX: 1.05,
          duration: 2000 + Math.random() * 500,
          yoyo: true,
          repeat: -1,
          ease: 'Sine.easeInOut'
        });
      }

      // Create trajineras (colorful moving boats!) - V2 Visual Overhaul
      if (ld.trajineras) {
        // Trajinera color themes - Traditional Mexican trajinera styles
        const TRAJINERA_THEMES = [
          { name: 'Traditional', hull: 0xff69b4, flowers: [0xffe66d, 0xff8c00, 0xffcc00], canopy: 0xff69b4 },
          { name: 'Festival', hull: 0x4ecdc4, flowers: [0xff1744, 0xff4081, 0xd500f9], canopy: 0x4ecdc4 },
          { name: 'Classic', hull: 0x2ecc71, flowers: [0xff6b6b, 0xffe66d, 0x9b59b6, 0x3498db], canopy: 0x27ae60 }
        ];

        ld.trajineras.forEach((t, i) => {
          // Pick a theme for this trajinera
          const theme = TRAJINERA_THEMES[i % TRAJINERA_THEMES.length];
          const boatName = t.name || TRAJINERA_NAMES[i % TRAJINERA_NAMES.length];

          // Boat body (colorful hull)
          const boat = this.add.container(t.x, t.y);

          // Hull - main boat body with theme color
          const hullColor = theme.hull;
          const hull = this.add.rectangle(0, 0, t.w, t.h, hullColor);
          boat.add(hull);

          // Hull trim - white stripe at waterline
          const trimBottom = this.add.rectangle(0, t.h/2 - 2, t.w - 4, 4, 0xffffff, 0.7);
          boat.add(trimBottom);

          // Hull decoration - colorful stripe pattern
          const stripe1 = this.add.rectangle(0, -t.h/4, t.w - 10, 3, 0xffffff, 0.6);
          const stripe2 = this.add.rectangle(0, 0, t.w - 10, 2, 0xffd700, 0.5);
          boat.add(stripe1);
          boat.add(stripe2);

          // Boat bow (pointed front)
          const bowDir = t.dir;
          const bow = this.add.triangle(t.w/2 * bowDir, 0, 0, -t.h/2, 15 * bowDir, 0, 0, t.h/2, hullColor);
          boat.add(bow);

          // ========== FLOWER CANOPY ARCH ==========
          // Create an arch of flowers on top - the iconic trajinera look!
          const canopyHeight = 35;  // Height of the arch
          const canopyWidth = t.w * 0.8;  // Slightly narrower than hull

          // Canopy arch frame (using graphics for curved look)
          const canopyGfx = this.add.graphics();
          canopyGfx.lineStyle(4, theme.canopy, 1);
          // Draw arch using bezier-like curve (two curves meeting at top)
          canopyGfx.beginPath();
          canopyGfx.moveTo(-canopyWidth/2, -t.h/2);
          canopyGfx.lineTo(-canopyWidth/2 + 5, -t.h/2 - canopyHeight * 0.7);
          canopyGfx.lineTo(0, -t.h/2 - canopyHeight);
          canopyGfx.lineTo(canopyWidth/2 - 5, -t.h/2 - canopyHeight * 0.7);
          canopyGfx.lineTo(canopyWidth/2, -t.h/2);
          canopyGfx.strokePath();
          boat.add(canopyGfx);

          // Vertical supports for the canopy
          const supportLeft = this.add.rectangle(-canopyWidth/2 + 3, -t.h/2 - canopyHeight/2, 3, canopyHeight, theme.canopy);
          const supportRight = this.add.rectangle(canopyWidth/2 - 3, -t.h/2 - canopyHeight/2, 3, canopyHeight, theme.canopy);
          boat.add(supportLeft);
          boat.add(supportRight);

          // Flowers along the canopy arch!
          const flowerPositions = [
            { x: -canopyWidth/2 + 8, y: -t.h/2 - canopyHeight * 0.5 },
            { x: -canopyWidth/4, y: -t.h/2 - canopyHeight * 0.85 },
            { x: 0, y: -t.h/2 - canopyHeight },
            { x: canopyWidth/4, y: -t.h/2 - canopyHeight * 0.85 },
            { x: canopyWidth/2 - 8, y: -t.h/2 - canopyHeight * 0.5 }
          ];

          flowerPositions.forEach((pos, fi) => {
            const flowerColor = theme.flowers[fi % theme.flowers.length];
            // Flower center
            const flower = this.add.circle(pos.x, pos.y, 6, flowerColor);
            boat.add(flower);
            // Flower center (yellow)
            const flowerCenter = this.add.circle(pos.x, pos.y, 2, 0xffff00);
            boat.add(flowerCenter);
          });

          // Extra flowers on the hull edges
          const hullFlower1 = this.add.circle(-t.w/3, -t.h/2 - 3, 4, theme.flowers[0]);
          const hullFlower2 = this.add.circle(t.w/3, -t.h/2 - 3, 4, theme.flowers[1 % theme.flowers.length]);
          boat.add(hullFlower1);
          boat.add(hullFlower2);

          // ========== BOAT NAME - Prominently displayed! ==========
          // Name background plate
          const namePlateWidth = Math.min(t.w * 0.7, boatName.length * 9 + 16);
          const namePlate = this.add.rectangle(0, t.h/4 + 2, namePlateWidth, 14, 0x000000, 0.4);
          boat.add(namePlate);

          // Boat name text - visible and colorful!
          const nameText = this.add.text(0, t.h/4 + 2, boatName, {
            fontSize: '11px',
            fontFamily: 'Arial, sans-serif',
            fontStyle: 'bold',
            color: '#ffffff',
            stroke: '#000000',
            strokeThickness: 2
          }).setOrigin(0.5, 0.5);
          boat.add(nameText);

          // Physics body for the boat platform
          const boatPlatform = this.add.rectangle(t.x, t.y - t.h/2 - 5, t.w + 20, 15, 0x000000, 0);
          this.physics.add.existing(boatPlatform, true);
          this.platforms.add(boatPlatform);

          // ========== DEPTH/SCALE for POV perspective ==========
          // Assign depth based on lane or position - creates visual depth illusion
          // background=0.7x, mid=1.0x, foreground=1.2x
          const laneNum = t.lane || (i % 3);
          let depthScale = 1.0;  // Default mid-ground
          if (laneNum === 0 || laneNum === 3) depthScale = 0.7;      // Background
          else if (laneNum === 2 || laneNum === 5) depthScale = 1.2; // Foreground
          // Apply scale to visual container
          boat.setScale(depthScale);
          // Set depth for proper layering (background boats behind, foreground in front)
          boat.setDepth(laneNum * 10);

          // Store trajinera data for movement and animations
          this.trajineras.push({
            container: boat,
            platform: boatPlatform,
            x: t.x,
            y: t.y,
            baseY: t.y,  // Store original Y for bob animation
            w: t.w,
            h: t.h || 25,
            speed: t.speed || 0,
            dir: t.dir || 1,
            minX: -t.w,
            maxX: ld.width + t.w,
            // Animation state
            bobPhase: Math.random() * Math.PI * 2,  // Random start phase for natural look
            bobAmplitude: 4,  // +/- 4 pixels visual bob (hitbox stays stable)
            bobPeriod: 2.0,   // 2 second period sine wave
            dipAmount: 0,  // Current dip from landing
            dipVelocity: 0,  // For spring-back animation
            // Depth properties
            depthScale: depthScale,
            visualY: t.y  // Track visual Y separately from physics Y
          });
        });
      }
    }

    // Cempasuchil Flowers (replaces coins) - Mexican marigolds!
    this.flowers = this.physics.add.group();
    ld.coins.forEach(c => {
      const flower = this.flowers.create(c.x, c.y, 'flower').setScale(1.5);
      flower.body.allowGravity = false;
      flower.baseY = c.y;
      // Slow rotation for the flower
      this.tweens.add({ targets: flower, angle: 360, duration: 3000, repeat: -1 });
      // Gentle bob animation
      this.tweens.add({ targets: flower, y: c.y - 5, duration: 600, yoyo: true, repeat: -1, ease: 'Sine.easeInOut' });
    });

    // Elotes (replaces stars) - Mexican corn on stick!
    this.elotes = this.physics.add.group();
    ld.stars.forEach((s, i) => {
      const eloteId = `${this.levelNum}-${i}`;
      if (!gameState.stars.includes(eloteId)) {
        const elote = this.elotes.create(s.x, s.y, 'elote').setScale(1.8);
        elote.eloteId = eloteId;
        elote.body.allowGravity = false;
        // Golden glow effect with slow pulse
        this.tweens.add({ targets: elote, scale: 2.0, duration: 800, yoyo: true, repeat: -1, ease: 'Sine.easeInOut' });
        // Gentle rotation
        this.tweens.add({ targets: elote, angle: 15, duration: 1000, yoyo: true, repeat: -1, ease: 'Sine.easeInOut' });
      }
    });

    // Baby axolotl
    const babyId = `baby-${this.levelNum}`;
    if (!gameState.rescuedBabies.includes(babyId)) {
      this.baby = this.physics.add.sprite(ld.babyPosition.x, ld.babyPosition.y, 'baby').setScale(2);
      this.baby.body.allowGravity = false;
      this.baby.babyId = babyId;
      this.tweens.add({ targets: this.baby, y: ld.babyPosition.y - 10, duration: 600, yoyo: true, repeat: -1 });
    }

    // Enemies - types: ground, platform, flying
    this.enemies = this.physics.add.group();
    this.flyingEnemies = [];
    this.projectiles = this.physics.add.group(); // Enemy projectiles!

    ld.enemies.forEach(e => {
      const type = e.type || 'ground';
      const enemy = this.enemies.create(e.x, e.y, 'enemy').setScale(1.5);
      enemy.setData('dir', e.dir || (Phaser.Math.Between(0,1) ? 1 : -1));
      enemy.setData('alive', true);
      enemy.setData('type', type);

      if (type === 'flying') {
        // Flying enemies - flappy bird style!
        enemy.body.allowGravity = false;
        enemy.setTint(0xff6699);
        enemy.setData('baseY', e.y);
        enemy.setData('flapTimer', 0);
        enemy.setData('flapUp', true);
        enemy.setData('speed', e.speed || 80);
        enemy.setData('shootTimer', Phaser.Math.Between(1000, 3000)); // Random first shot
        enemy.body.setVelocityX(enemy.getData('speed') * enemy.getData('dir'));
        this.flyingEnemies.push(enemy);
      } else if (type === 'platform') {
        // Platform enemies - find their platform bounds
        const plat = this.findPlatformAt(e.x, e.y + 30);
        if (plat) {
          enemy.setData('platLeft', plat.x - plat.width/2 + 10);
          enemy.setData('platRight', plat.x + plat.width/2 - 10);
        } else {
          enemy.setData('platLeft', e.x - 60);
          enemy.setData('platRight', e.x + 60);
        }
        enemy.setTint(0x99ff99);
        enemy.body.setVelocityX(40 * enemy.getData('dir'));
      } else {
        // Ground enemies
        enemy.body.setVelocityX(60 * enemy.getData('dir'));
      }
      enemy.setFlipX(enemy.getData('dir') > 0);
    });

    // ============ ALLIGATORS - DKC2 style water danger! ============
    this.alligators = this.physics.add.group();
    if (ld.alligators && ld.alligators.length > 0) {
      ld.alligators.forEach(gator => {
        // Create alligator sprite (reuse enemy sprite with green tint)
        const alligator = this.alligators.create(gator.x, this.levelData.height + 100, 'enemy').setScale(2);
        alligator.body.allowGravity = false;
        alligator.setTint(0x228833);  // Dark green for alligator
        alligator.setData('baseY', gator.baseY);
        alligator.setData('speed', gator.speed);
        alligator.setData('dir', gator.dir);
        alligator.body.setVelocityX(gator.speed * gator.dir);
        alligator.setFlipX(gator.dir > 0);

        // Make alligator look more menacing - stretch horizontally
        alligator.setScale(2.5, 1.5);
      });
    }

    // DARK XOCHI - Boss fight on levels 5 and 10!
    // DKC2-style boss: APPROACH -> TELEGRAPH -> ATTACK -> RECOVER (vulnerable)
    this.darkXochi = null;
    this.bossHealth = 0;
    this.bossMaxHealth = 0;
    this.bossState = 'APPROACH'; // APPROACH, TELEGRAPH, ATTACK, RECOVER
    this.bossStateTimer = 0;
    this.bossInvincible = false;
    this.bossAttackType = 0; // Alternates: 0=leap, 1=mace swing
    this.bossTelegraphSprite = null; // "!" warning indicator
    this.bossHealthBar = null;
    this.bossHealthBarBg = null;
    this.bossNameText = null;

    const isBossLevel = (this.levelNum === 5 || this.levelNum === 10);
    if (isBossLevel && !gameState.rescuedBabies.includes(`baby-${this.levelNum}`)) {
      // Boss stats based on level (DKC2-style: 3 or 5 hits to defeat)
      this.bossMaxHealth = this.levelNum === 10 ? 5 : 3;
      this.bossHealth = this.bossMaxHealth;
      // Timing gets tighter at higher levels
      this.bossApproachTime = this.levelNum === 10 ? 1500 : 2000;
      this.bossTelegraphTime = 500;
      this.bossRecoverTime = this.levelNum === 10 ? 1200 : 1500;
      const bossSpeed = this.levelNum === 10 ? 100 : 80;

      // Dark Xochi spawns on right side of arena
      this.darkXochi = this.physics.add.sprite(ld.playerSpawn.x + 300, ld.playerSpawn.y - 100, 'xochi_walk').setScale(0.15);
      this.darkXochi.setTint(0x220022); // Dark purple/black evil Xochi!
      this.darkXochi.setData('alive', true);
      this.darkXochi.setData('speed', bossSpeed);
      this.darkXochi.body.setSize(200, 350);
      this.darkXochi.body.setOffset(110, 100);
      this.darkXochi.setFlipX(true); // Face player

      // Boss health bar UI (top center)
      this.bossNameText = this.add.text(this.cameras.main.width / 2, 50, 'DARK XOCHI', {
        fontFamily: 'Arial Black', fontSize: '20px', color: '#ff00ff',
        stroke: '#000', strokeThickness: 3
      }).setOrigin(0.5).setScrollFactor(0).setDepth(100);

      this.bossHealthBarBg = this.add.rectangle(this.cameras.main.width / 2, 75, 200, 20, 0x440044)
        .setScrollFactor(0).setDepth(100);
      this.bossHealthBar = this.add.rectangle(this.cameras.main.width / 2, 75, 200, 16, 0xff00ff)
        .setScrollFactor(0).setDepth(101);

      // Boss intro sequence
      this.darkXochi.setAlpha(0);
      this.bossNameText.setAlpha(0);
      this.bossHealthBarBg.setAlpha(0);
      this.bossHealthBar.setAlpha(0);

      this.time.delayedCall(500, () => {
        // "DARK XOCHI APPEARS!" text
        const introText = this.add.text(this.cameras.main.width / 2, this.cameras.main.height / 2,
          'DARK XOCHI\nAPPEARS!', {
          fontFamily: 'Arial Black', fontSize: '48px', color: '#ff00ff',
          stroke: '#000', strokeThickness: 6, align: 'center'
        }).setOrigin(0.5).setScrollFactor(0).setDepth(200);

        // Boss drops in
        this.tweens.add({
          targets: this.darkXochi,
          alpha: 1,
          duration: 500
        });

        // Fade in health bar
        this.tweens.add({
          targets: [this.bossNameText, this.bossHealthBarBg, this.bossHealthBar],
          alpha: 1,
          duration: 500,
          delay: 1000
        });

        // Remove intro text and start boss AI
        this.time.delayedCall(2000, () => {
          this.tweens.add({
            targets: introText,
            alpha: 0,
            duration: 300,
            onComplete: () => introText.destroy()
          });
          // Initialize boss state timer to start the cycle
          this.bossStateTimer = this.bossApproachTime;
        });
      });

      // Dark Xochi collides with platforms
      this.physics.add.collider(this.darkXochi, this.platforms);
    }

    // Super Jump Power-ups
    this.powerups = this.physics.add.group();
    if (ld.powerups) {
      ld.powerups.forEach(p => {
        const powerup = this.powerups.create(p.x, p.y, 'superjump').setScale(1.5);
        powerup.body.allowGravity = false;
        this.tweens.add({ targets: powerup, y: p.y - 8, duration: 400, yoyo: true, repeat: -1, ease: 'Sine.easeInOut' });
      });
    }

    // ============ BLUE DEMON MASK - Luchador Mode Power-up! ============
    // Spawns 1 per level on a random platform near the middle of the level
    this.blueDemonMask = null;
    if (ld.platforms && ld.platforms.length > 2) {
      // Find platforms in the middle third of the level
      const middlePlatforms = ld.platforms.filter(p => {
        const midX = ld.width / 2;
        const midY = ld.height / 2;
        return Math.abs(p.x + p.w/2 - midX) < ld.width * 0.4 &&
               Math.abs(p.y - midY) < ld.height * 0.4 &&
               p.w > 60;  // Only on wide enough platforms
      });

      if (middlePlatforms.length > 0) {
        const randomPlatform = middlePlatforms[Math.floor(Math.random() * middlePlatforms.length)];
        const maskX = randomPlatform.x + randomPlatform.w / 2;
        const maskY = randomPlatform.y - 30;  // Above the platform

        this.blueDemonMask = this.physics.add.sprite(maskX, maskY, 'blueDemonMask').setScale(2);
        this.blueDemonMask.body.allowGravity = false;

        // Dramatic floating and glowing animation
        this.tweens.add({
          targets: this.blueDemonMask,
          y: maskY - 10,
          duration: 800,
          yoyo: true,
          repeat: -1,
          ease: 'Sine.easeInOut'
        });
        this.tweens.add({
          targets: this.blueDemonMask,
          scale: 2.3,
          duration: 600,
          yoyo: true,
          repeat: -1,
          ease: 'Sine.easeInOut'
        });

        // Blue glow effect behind the mask
        this.maskGlow = this.add.circle(maskX, maskY, 20, 0x0066ff, 0.3);
        this.tweens.add({
          targets: this.maskGlow,
          scale: 1.5,
          alpha: 0.1,
          duration: 800,
          yoyo: true,
          repeat: -1
        });
      }
    }

    // NO free starting powerup - earn your powers!
    // (Powerups are placed throughout the level based on difficulty settings)

    // Player (Aztec axolotl warrior - ~420x450 sprite frames at 0.15 scale)
    this.player = this.physics.add.sprite(ld.playerSpawn.x, ld.playerSpawn.y, 'xochi_walk').setScale(0.15);
    this.player.setCollideWorldBounds(true);
    // Hitbox for ~420x450 frames: smaller box for body, feet at bottom
    this.player.body.setSize(200, 350);
    this.player.body.setOffset(110, 100); // Center hitbox, feet touch ground
    this.player.setData('big', false);
    this.player.setData('invincible', false);
    this.player.setData('dead', false);

    // ============ LUCHADOR MODE STATE ============
    this.player.setData('luchadorMode', false);
    this.player.setData('luchadorTimer', 0);
    this.player.setData('isRolling', false);
    this.player.setData('rollDirection', 1);
    this.luchadorMaskOverlay = null;  // Visual mask on player
    this.luchadorAfterimages = [];    // Blue motion trail
    this.lastZPressTime = 0;          // For double-tap detection
    this.zTapFlashShown = false;      // First tap visual feedback
    this.rollAttackActive = false;    // Roll attack hitbox state

    // Scene cleanup handler - prevents memory leaks on restart
    this.events.once('shutdown', () => {
      if (this.eloteParticleTimer) {
        this.eloteParticleTimer.destroy();
      }
    });

    // Camera - different behavior for each level type
    this.cameras.main.setBounds(0, 0, ld.width, ld.height);
    this.isUpscroller = ld.isUpscroller || false;
    this.isEscapeLevel = ld.isEscapeLevel || false;

    if (this.isUpscroller) {
      // Upscroller: tighter vertical follow, camera stays centered horizontally
      this.cameras.main.startFollow(this.player, true, 0.1, 0.15);
      // Offset camera to show more above player (where they're climbing to)
      this.cameras.main.setFollowOffset(0, 100);

      // ============ RISING WATER - FLAPPY BIRD PRESSURE! ============
      // Water starts at bottom and rises - keeps you moving!
      this.risingWaterY = ld.height + 50;  // Start just below screen
      this.risingWaterSpeed = 60;  // Fixed 60 px/s - balanced difficulty
      this.risingWaterGraphics = this.add.graphics().setDepth(100);  // Above everything
      this.risingWaterGraphics.setScrollFactor(0);  // Fixed to camera

      // Warning line showing where water will be
      this.waterWarningLine = this.add.rectangle(
        ld.width / 2, this.cameras.main.height - 30,
        ld.width, 4, 0xff0000, 0.5
      ).setScrollFactor(0).setDepth(99);

      // Pulsing warning
      this.tweens.add({
        targets: this.waterWarningLine,
        alpha: 0.2,
        duration: 300,
        yoyo: true,
        repeat: -1
      });

    } else if (this.isEscapeLevel) {
      // ============ ESCAPE LEVEL - INDIANA JONES STYLE! ============
      // Camera auto-scrolls forward, flood chases from behind!

      // Camera follows player but also auto-scrolls forward
      this.cameras.main.startFollow(this.player, true, 0.1, 0.08);
      this.cameras.main.setFollowOffset(-100, 0);  // Show more ahead

      // Chasing flood starts at the left
      this.chasingFloodX = -100;  // Start just off-screen left
      this.floodSpeed = ld.escapeSpeed || 120;  // Pixels per second
      this.floodGraphics = this.add.graphics().setDepth(100);
      this.floodGraphics.setScrollFactor(0);

      // Warning indicator on left side
      this.floodWarning = this.add.rectangle(
        30, this.cameras.main.height / 2,
        8, this.cameras.main.height, 0xff0000, 0.6
      ).setScrollFactor(0).setDepth(99);

      this.tweens.add({
        targets: this.floodWarning,
        alpha: 0.2,
        duration: 200,
        yoyo: true,
        repeat: -1
      });

      // Show "RUN!" text at start
      const runText = this.add.text(this.cameras.main.width / 2, this.cameras.main.height / 2 - 50,
        'RUN!', {
        fontFamily: 'Arial Black', fontSize: '64px', color: '#ff4444',
        stroke: '#000000', strokeThickness: 6
      }).setOrigin(0.5).setScrollFactor(0).setDepth(200);

      this.tweens.add({
        targets: runText,
        scale: 1.3,
        alpha: 0,
        duration: 1500,
        ease: 'Power2',
        onComplete: () => runText.destroy()
      });

    } else {
      // Side-scroller: normal horizontal follow
      this.cameras.main.startFollow(this.player, true, 0.08, 0.08);
    }

    // Collisions
    this.physics.add.collider(this.player, this.platforms);
    this.physics.add.collider(this.enemies, this.platforms, (enemy) => {
      // Only ground/platform enemies collide - flying enemies don't
      if (enemy.getData('type') === 'flying') return;
      if (enemy.body.blocked.left || enemy.body.blocked.right) {
        enemy.setData('dir', enemy.getData('dir') * -1);
        const speed = enemy.getData('type') === 'platform' ? 40 : 60;
        enemy.body.setVelocityX(speed * enemy.getData('dir'));
        enemy.setFlipX(enemy.getData('dir') > 0);
      }
    });
    this.physics.add.overlap(this.player, this.flowers, this.collectFlower, null, this);
    this.physics.add.overlap(this.player, this.elotes, this.collectElote, null, this);
    this.physics.add.overlap(this.player, this.enemies, this.hitEnemy, null, this);
    this.physics.add.overlap(this.player, this.powerups, this.collectPowerup, null, this);
    this.physics.add.overlap(this.player, this.projectiles, this.hitByProjectile, null, this);
    if (this.baby) {
      this.physics.add.overlap(this.player, this.baby, this.rescueBaby, null, this);
    }
    if (this.darkXochi) {
      this.physics.add.overlap(this.player, this.darkXochi, this.hitDarkXochi, null, this);
    }
    if (this.blueDemonMask) {
      this.physics.add.overlap(this.player, this.blueDemonMask, this.collectBlueDemonMask, null, this);
    }

    // Input
    this.cursors = this.input.keyboard.createCursorKeys();
    this.keys = this.input.keyboard.addKeys({ W: 'W', A: 'A', S: 'S', D: 'D', SPACE: 'SPACE', SHIFT: 'SHIFT', X: 'X', Z: 'Z' });

    // ============ ANIMATION STATE ============
    this.walkTime = 0;           // For walk animation cycle
    this.idleTime = 0;           // For idle animation cycle
    this.isAttacking = false;    // Mace attack state
    this.attackCooldown = 0;     // Cooldown between attacks
    this.lastIdleMove = 0;       // Time of last idle pose change
    this.walkFrame = 0;          // Current walk animation frame (0-3)
    this.walkFrameTime = 0;      // Time since last frame change
    this.currentAnim = 'idle';   // Current animation state

    // ============ TOUCH CONTROLS FOR MOBILE ============
    this.touchControls = { left: false, right: false, jump: false, superJump: false, attack: false, run: false };
    this.setupTouchControls();

    // UI
    this.scene.launch('UIScene', { levelNum: this.levelNum });

    // ============ WORLD INTRO - Show world name when entering new world! ============
    try {
      if (typeof isFirstLevelOfWorld === 'function' && isFirstLevelOfWorld(this.levelNum)) {
        const worldNum = getWorldForLevel(this.levelNum);
        const world = WORLDS[worldNum];
        if (world) {
          const levelType = getLevelTypeDescription(this.levelNum);
          const camW = this.cameras.main.width;
          const camH = this.cameras.main.height;

          // Dark overlay for dramatic effect
          const overlay = this.add.rectangle(camW/2, camH/2, camW, camH, 0x000000, 0.7)
            .setScrollFactor(0).setDepth(500);

          // World name (English)
          const worldName = this.add.text(camW/2, camH/2 - 40, (world.name || '').toUpperCase(), {
            fontFamily: 'Arial Black', fontSize: '36px', color: '#ffffff',
            stroke: '#000000', strokeThickness: 4
          }).setOrigin(0.5).setScrollFactor(0).setDepth(501).setAlpha(0);

          // World subtitle (Spanish)
          const worldSubtitle = this.add.text(camW/2, camH/2, world.subtitle || '', {
            fontFamily: 'Arial', fontSize: '20px', color: '#ffcc66',
            stroke: '#000000', strokeThickness: 2, fontStyle: 'italic'
          }).setOrigin(0.5).setScrollFactor(0).setDepth(501).setAlpha(0);

          // Level type
          const typeText = this.add.text(camW/2, camH/2 + 50, levelType || '', {
            fontFamily: 'Arial Black', fontSize: '18px', color: '#66ffcc',
            stroke: '#000000', strokeThickness: 3
          }).setOrigin(0.5).setScrollFactor(0).setDepth(501).setAlpha(0);

          // Level number
          const levelText = this.add.text(camW/2, camH/2 + 85, `Level ${this.levelNum}`, {
            fontFamily: 'Arial', fontSize: '14px', color: '#aaaaaa'
          }).setOrigin(0.5).setScrollFactor(0).setDepth(501).setAlpha(0);

          // Animate in
          this.tweens.add({
            targets: [worldName, worldSubtitle, typeText, levelText],
            alpha: 1,
            duration: 500,
            ease: 'Power2'
          });

          // Animate out after delay
          this.time.delayedCall(2000, () => {
            this.tweens.add({
              targets: [overlay, worldName, worldSubtitle, typeText, levelText],
              alpha: 0,
              duration: 500,
              ease: 'Power2',
              onComplete: () => {
                if (overlay && overlay.destroy) overlay.destroy();
                if (worldName && worldName.destroy) worldName.destroy();
                if (worldSubtitle && worldSubtitle.destroy) worldSubtitle.destroy();
                if (typeText && typeText.destroy) typeText.destroy();
                if (levelText && levelText.destroy) levelText.destroy();
              }
            });
          });
        }
      }
    } catch (e) {
      console.error('World intro error:', e);
    }

    // Pause
    this.input.keyboard.on('keydown-ESC', () => {
      this.scene.launch('PauseScene');
      this.scene.pause();
    });
  }

  playSound(key, options = {}) {
    if (!gameState.sfxEnabled) return;

    // Build sound config with optional pitch variation
    const config = {
      volume: options.volume !== undefined ? options.volume : 0.6,
    };

    // Apply pitch variation for natural feel (randomizes playback rate by +/- 5%)
    if (options.pitchVariation) {
      config.rate = 1 + (Math.random() * 0.1 - 0.05);
    }

    this.sound.play(key, config);
  }

  // ============ LEDGE GRAB - DKC style! ============
  grabLedge(edgeX, edgeY, side, movingPlatform = null) {
    if (!this.player || !this.player.body) return;
    if (this.player.getData('hanging')) return;
    if (this.player.getData('climbing')) return;  // Don't grab while climbing up

    // AUTO-CLIMB: Skip hanging entirely, immediately climb up!
    // This eliminates all hanging-related bugs

    // Stop movement and disable gravity during climb
    this.player.body.setVelocity(0, 0);
    this.player.body.allowGravity = false;

    // Enter climbing state (prevents input during animation)
    this.player.setData('climbing', true);
    this.player.setData('climbPlatform', movingPlatform);  // Track platform for sync
    this.player.setData('grabCooldown', 400);  // Cooldown after climb
    this.player.setFlipX(side === 'right');
    this.player.rotation = 0;

    // Store initial grab position for offset tracking
    const initialPlatX = movingPlatform ? movingPlatform.x : edgeX;
    const initialPlatY = movingPlatform ? movingPlatform.y : edgeY;

    // Small particle burst for grab feedback
    for (let i = 0; i < 3; i++) {
      const spark = this.add.circle(
        edgeX + (Math.random() - 0.5) * 15,
        edgeY + 5,
        2 + Math.random() * 2, 0xffffff, 0.8
      );
      this.tweens.add({
        targets: spark,
        y: spark.y - 15,
        alpha: 0,
        scale: 0,
        duration: 250,
        onComplete: () => spark.destroy()
      });
    }

    // Helper to get current edge position (tracks moving platforms)
    const getCurrentEdge = () => {
      if (movingPlatform && movingPlatform.w) {
        const trajW = movingPlatform.w;
        const trajH = movingPlatform.h || 25;
        return {
          x: side === 'left' ? movingPlatform.x - trajW / 2 : movingPlatform.x + trajW / 2,
          y: movingPlatform.y - trajH / 2 - 5
        };
      }
      return { x: edgeX, y: edgeY };
    };

    // PHASE 1: Quick grab (snap to edge)
    this.player.setTexture('xochi_run');
    const edge1 = getCurrentEdge();
    this.player.setPosition(
      side === 'left' ? edge1.x - 8 : edge1.x + 8,
      edge1.y + 10
    );

    // PHASE 2: Pull-up with platform tracking
    this.player.setTexture('xochi_jump');
    this.tweens.add({
      targets: this.player,
      x: edge1.x + (side === 'left' ? 10 : -10),
      y: edge1.y - 10,
      duration: 80,
      ease: 'Power2.easeOut',
      onUpdate: () => {
        // Track moving platform during climb
        if (movingPlatform && movingPlatform.w) {
          const currentEdge = getCurrentEdge();
          const driftX = currentEdge.x - edge1.x;
          const driftY = currentEdge.y - edge1.y;
          this.player.x += driftX * 0.5;  // Smooth follow
          this.player.y += driftY * 0.5;
        }
      },
      onComplete: () => {
        // PHASE 3: Vault over with platform tracking
        this.player.setTexture('xochi_attack');
        const edge2 = getCurrentEdge();
        const targetX = edge2.x + (side === 'left' ? 30 : -30);
        const targetY = edge2.y - 35;

        this.tweens.add({
          targets: this.player,
          x: targetX,
          y: targetY,
          duration: 100,
          ease: 'Sine.easeOut',
          onUpdate: () => {
            // Keep tracking during vault
            if (movingPlatform && movingPlatform.w) {
              const currentEdge = getCurrentEdge();
              const newTargetX = currentEdge.x + (side === 'left' ? 30 : -30);
              const newTargetY = currentEdge.y - 35;
              const driftX = newTargetX - targetX;
              const driftY = newTargetY - targetY;
              this.player.x += driftX * 0.3;
              this.player.y += driftY * 0.3;
            }
          },
          onComplete: () => {
            // PHASE 4: Land on platform
            this.player.setTexture('xochi_walk');
            this.player.body.allowGravity = true;
            this.player.setData('climbing', false);
            this.player.setData('climbPlatform', null);
            this.player.body.setVelocityY(50);  // Gentle landing
          }
        });
      }
    });
  }

  // ============ TOUCH CONTROLS - ONE HAND SCHEME ============
  // SWIPE UP = Jump (+ direction if diagonal)
  // TAP = Super jump (when available)
  // HOLD = Attack
  setupTouchControls() {
    // Only show on touch devices
    if (!this.sys.game.device.input.touch) return;

    const { width, height } = this.cameras.main;

    // ============ CONFIGURATION ============
    const TAP_MAX_DURATION = 200;      // ms - quick tap
    const TAP_MAX_MOVEMENT = 30;       // px - tap threshold
    const SWIPE_MIN_DISTANCE = 50;     // px - minimum swipe distance
    const HOLD_DURATION = 400;         // ms - hold for attack
    const SWIPE_UP_THRESHOLD = -30;    // px - negative Y = upward swipe

    // ============ TOUCH STATE ============
    this.primaryTouch = {
      active: false,
      pointerId: null,
      originX: 0,
      originY: 0,
      startTime: 0,
      holdTimer: null,
      isUsed: false  // Prevent multiple triggers
    };

    // ============ POINTER DOWN ============
    this.input.on('pointerdown', (pointer) => {
      if (this.primaryTouch.active) return;

      this.primaryTouch.active = true;
      this.primaryTouch.pointerId = pointer.id;
      this.primaryTouch.originX = pointer.x;
      this.primaryTouch.originY = pointer.y;
      this.primaryTouch.startTime = this.time.now;
      this.primaryTouch.isUsed = false;

      // Start hold timer for attack
      this.primaryTouch.holdTimer = this.time.delayedCall(HOLD_DURATION, () => {
        if (this.primaryTouch.active && !this.primaryTouch.isUsed) {
          const activePointer = this.input.activePointer;
          if (activePointer && activePointer.isDown) {
            const dx = activePointer.x - this.primaryTouch.originX;
            const dy = activePointer.y - this.primaryTouch.originY;
            const distance = Math.sqrt(dx * dx + dy * dy);

            // Only attack if finger hasn't moved much
            if (distance < SWIPE_MIN_DISTANCE) {
              this.primaryTouch.isUsed = true;
              this.touchControls.attack = true;
              this.time.delayedCall(50, () => {
                this.touchControls.attack = false;
              });
            }
          }
        }
      });
    });

    // ============ POINTER MOVE ============
    this.input.on('pointermove', (pointer) => {
      if (!this.primaryTouch.active || pointer.id !== this.primaryTouch.pointerId) return;
      if (this.primaryTouch.isUsed) return;

      const dx = pointer.x - this.primaryTouch.originX;
      const dy = pointer.y - this.primaryTouch.originY;
      const distance = Math.sqrt(dx * dx + dy * dy);

      // Check for swipe
      if (distance > SWIPE_MIN_DISTANCE) {
        // Clear hold timer - this is a swipe
        if (this.primaryTouch.holdTimer) {
          this.primaryTouch.holdTimer.remove();
          this.primaryTouch.holdTimer = null;
        }

        // SWIPE UP = Jump (check if Y went upward)
        if (dy < SWIPE_UP_THRESHOLD) {
          this.primaryTouch.isUsed = true;

          // Jump!
          this.touchControls.jump = true;
          this.time.delayedCall(50, () => {
            this.touchControls.jump = false;
          });

          // Also set direction based on horizontal component
          if (dx < -20) {
            this.touchControls.left = true;
            this.touchControls.right = false;
          } else if (dx > 20) {
            this.touchControls.left = false;
            this.touchControls.right = true;
          }

          // Brief movement then stop
          this.time.delayedCall(150, () => {
            this.touchControls.left = false;
            this.touchControls.right = false;
          });
        }
        // SWIPE LEFT/RIGHT = Move (no jump)
        else if (Math.abs(dx) > Math.abs(dy)) {
          if (dx < 0) {
            this.touchControls.left = true;
            this.touchControls.right = false;
          } else {
            this.touchControls.left = false;
            this.touchControls.right = true;
          }
          // Run if swiped far
          this.touchControls.run = Math.abs(dx) > 80;
        }
      }
    });

    // ============ POINTER UP ============
    this.input.on('pointerup', (pointer) => {
      if (!this.primaryTouch.active || pointer.id !== this.primaryTouch.pointerId) return;

      const dx = pointer.x - this.primaryTouch.originX;
      const dy = pointer.y - this.primaryTouch.originY;
      const distance = Math.sqrt(dx * dx + dy * dy);
      const elapsed = this.time.now - this.primaryTouch.startTime;

      // Clear hold timer
      if (this.primaryTouch.holdTimer) {
        this.primaryTouch.holdTimer.remove();
        this.primaryTouch.holdTimer = null;
      }

      // TAP = Super jump (if not already used for something else)
      if (!this.primaryTouch.isUsed && elapsed < TAP_MAX_DURATION && distance < TAP_MAX_MOVEMENT) {
        if (gameState.superJumps > 0 && this.player && !this.player.getData('dead')) {
          gameState.superJumps--;
          this.player.body.setVelocityY(-650);
          this.playSound('sfx-superjump', { pitchVariation: true });
          this.showText(this.player.x, this.player.y - 30, 'SUPER!', '#00ffff');
          this.events.emit('updateUI');

          // Visual burst
          for (let i = 0; i < 12; i++) {
            const angle = (i / 12) * Math.PI * 2;
            const trail = this.add.circle(
              this.player.x + Math.cos(angle) * 10,
              this.player.y + Math.sin(angle) * 10,
              6, 0x00ffff, 0.8
            );
            this.tweens.add({
              targets: trail,
              x: this.player.x + Math.cos(angle) * 40,
              y: this.player.y + Math.sin(angle) * 40,
              alpha: 0,
              scale: 0.5,
              duration: 300,
              onComplete: () => trail.destroy()
            });
          }
        }
      }

      // Stop movement on release
      this.touchControls.left = false;
      this.touchControls.right = false;
      this.touchControls.run = false;

      // Reset touch state
      this.primaryTouch.active = false;
      this.primaryTouch.pointerId = null;
      this.primaryTouch.isUsed = false;
    });

    // ============ POINTER CANCEL ============
    this.input.on('pointercancel', (pointer) => {
      if (!this.primaryTouch.active || pointer.id !== this.primaryTouch.pointerId) return;

      if (this.primaryTouch.holdTimer) {
        this.primaryTouch.holdTimer.remove();
        this.primaryTouch.holdTimer = null;
      }

      this.touchControls.left = false;
      this.touchControls.right = false;
      this.touchControls.run = false;

      this.primaryTouch.active = false;
      this.primaryTouch.pointerId = null;
      this.primaryTouch.isUsed = false;
    });

    // ============ PAUSE BUTTON (top right corner) ============
    const pauseBtn = this.add.circle(width - 30, 30, 20, 0x666666, 0.4)
      .setScrollFactor(0).setDepth(1000).setInteractive();
    this.add.text(width - 30, 30, '||', {
      fontFamily: 'Arial', fontSize: '16px', color: '#fff'
    }).setOrigin(0.5).setScrollFactor(0).setDepth(1001);
    pauseBtn.on('pointerdown', (p) => {
      p.event.stopPropagation();
      this.scene.launch('PauseScene');
      this.scene.pause();
    });

    // ============ CONTROL HINT (shown briefly) ============
    const hint = this.add.text(width / 2, height - 40, 'SWIPE UP = JUMP  •  TAP = SUPER JUMP  •  HOLD = ATTACK', {
      fontFamily: 'Arial', fontSize: '11px', color: '#ffffff', stroke: '#000000', strokeThickness: 2
    }).setOrigin(0.5).setScrollFactor(0).setDepth(1002).setAlpha(0.8);

    // Fade out hint after 4 seconds
    this.time.delayedCall(4000, () => {
      this.tweens.add({
        targets: hint,
        alpha: 0,
        duration: 1000,
        onComplete: () => hint.destroy()
      });
    });
  }

  // Find platform at position (for platform enemy bounds)
  findPlatformAt(x, y) {
    let found = null;
    this.platforms.getChildren().forEach(p => {
      if (x >= p.x - p.width/2 && x <= p.x + p.width/2 &&
          y >= p.y - p.height/2 && y <= p.y + p.height/2 + 20) {
        found = p;
      }
    });
    return found;
  }

  // Flying enemy shoots projectile at player
  shootProjectile(enemy) {
    if (!enemy.getData('alive') || !this.player) return;

    const proj = this.projectiles.create(enemy.x, enemy.y + 10, 'projectile');
    proj.setScale(1.2);
    proj.body.allowGravity = false;

    // Aim at player
    const angle = Phaser.Math.Angle.Between(enemy.x, enemy.y, this.player.x, this.player.y);
    const speed = 200;
    proj.body.setVelocity(Math.cos(angle) * speed, Math.sin(angle) * speed);

    // Destroy after 3 seconds
    this.time.delayedCall(3000, () => {
      if (proj && proj.active) proj.destroy();
    });
  }

  hitByProjectile(player, projectile) {
    if (player.getData('invincible')) {
      projectile.destroy();
      return;
    }

    projectile.destroy();
    this.playSound('sfx-hurt');

    if (player.getData('big')) {
      player.setData('big', false);
      player.setTexture('xochi');
      player.body.setSize(12, 14);
      this.setInvincible(2000);
    } else {
      this.playerDie();
    }
  }

  collectPowerup(player, powerup) {
    powerup.destroy();
    gameState.superJumps += 1;   // Only +1 now (was +2)
    gameState.maceAttacks += 1;  // Only +1 now (was +2)
    this.playSound('sfx-powerup');
    this.showBigText('+1 JUMP! +1 THUNDER!', '#00ffff');
    this.events.emit('updateUI');
  }

  // ============ COLLECT CEMPASUCHIL FLOWER (replaces coin) ============
  collectFlower(player, flower) {
    const flowerX = flower.x;
    const flowerY = flower.y;
    flower.destroy();
    gameState.flowers++;
    gameState.score += 10; // +10 points per flower
    this.playSound('sfx-coin');
    this.showText(flowerX, flowerY - 20, '+10', '#ff8c00');
    this.events.emit('updateUI');

    // ========== ORANGE PETAL PARTICLE BURST ==========
    for (let i = 0; i < 8; i++) {
      const angle = (i / 8) * Math.PI * 2 + Math.random() * 0.5;
      const speed = 40 + Math.random() * 30;
      const petal = this.add.ellipse(
        flowerX,
        flowerY,
        6 + Math.random() * 4,
        4 + Math.random() * 2,
        Phaser.Math.Between(0, 1) ? 0xff8c00 : 0xffaa00  // Orange/yellow petals
      );
      petal.setAngle(Math.random() * 360);
      this.tweens.add({
        targets: petal,
        x: flowerX + Math.cos(angle) * speed,
        y: flowerY + Math.sin(angle) * speed + 20,  // Fall slightly
        alpha: 0,
        scale: 0.3,
        angle: petal.angle + (Math.random() - 0.5) * 180,
        duration: 400 + Math.random() * 200,
        ease: 'Quad.easeOut',
        onComplete: () => petal.destroy()
      });
    }

    // Super jump every 10 flowers
    if (gameState.flowers % 10 === 0) {
      gameState.superJumps++;
      this.showBigText('+1 SUPER JUMP!', '#00ffff');
    }
    // Extra life at 100 flowers
    if (gameState.flowers >= 100) {
      gameState.flowers -= 100;
      gameState.lives++;
      this.showBigText('1UP!', '#ff8c00');
    }
  }

  // ============ COLLECT ELOTE (replaces star) - 8 second invincibility! ============
  collectElote(player, elote) {
    gameState.stars.push(elote.eloteId);  // Still use stars array for tracking collection
    gameState.score += 500;
    const eloteX = elote.x;
    const eloteY = elote.y;
    elote.destroy();
    this.playSound('sfx-powerup');
    this.showBigText('ELOTE! INVINCIBLE!', '#ffd700');
    this.events.emit('updateUI');
    saveGame();

    // ========== 8 SECOND INVINCIBILITY with GOLDEN GLOW ==========
    this.setEloteInvincible(8000);
  }

  // ============ ELOTE INVINCIBILITY - Golden glow effect ============
  setEloteInvincible(duration) {
    this.player.setData('invincible', true);
    this.player.setData('eloteActive', true);

    // Golden tint effect
    this.player.setTint(0xffd700);

    // Start corn kernel particle trail
    this.eloteParticleTimer = this.time.addEvent({
      delay: 100,  // Spawn particle every 100ms
      callback: () => {
        if (!this.player || !this.player.getData('eloteActive')) return;
        // Create corn kernel particle
        const kernel = this.add.circle(
          this.player.x + (Math.random() - 0.5) * 20,
          this.player.y + (Math.random() - 0.5) * 20,
          3 + Math.random() * 2,
          Phaser.Math.Between(0, 1) ? 0xffd700 : 0xffec8b  // Golden/yellow kernels
        );
        this.tweens.add({
          targets: kernel,
          y: kernel.y + 30,
          alpha: 0,
          scale: 0.5,
          duration: 400,
          onComplete: () => kernel.destroy()
        });
      },
      repeat: Math.floor(duration / 100) - 1
    });

    // End invincibility after duration
    this.time.delayedCall(duration, () => {
      if (this.player) {
        this.player.setData('invincible', false);
        this.player.setData('eloteActive', false);
        this.player.clearTint();
        if (this.eloteParticleTimer) {
          this.eloteParticleTimer.destroy();
        }
      }
    });
  }

  // ============ BLUE DEMON MASK - Luchador Mode! ============
  collectBlueDemonMask(player, mask) {
    const maskX = mask.x;
    const maskY = mask.y;
    mask.destroy();
    if (this.maskGlow) {
      this.maskGlow.destroy();
      this.maskGlow = null;
    }
    this.blueDemonMask = null;

    this.playSound('sfx-powerup');
    this.showBigText('LUCHADOR MODE!', '#0066ff');
    gameState.score += 1000;
    this.events.emit('updateUI');

    // Activate luchador mode for 15 seconds
    this.activateLuchadorMode(15000);

    // Dramatic blue particle burst
    for (let i = 0; i < 16; i++) {
      const angle = (i / 16) * Math.PI * 2;
      const speed = 60 + Math.random() * 40;
      const particle = this.add.circle(
        maskX,
        maskY,
        4 + Math.random() * 4,
        0x0066ff
      );
      this.tweens.add({
        targets: particle,
        x: maskX + Math.cos(angle) * speed,
        y: maskY + Math.sin(angle) * speed,
        alpha: 0,
        scale: 0.3,
        duration: 500,
        onComplete: () => particle.destroy()
      });
    }
  }

  // ============ ACTIVATE LUCHADOR MODE ============
  activateLuchadorMode(duration) {
    this.player.setData('luchadorMode', true);
    this.player.setData('luchadorTimer', duration);

    // Create mask overlay on player
    this.luchadorMaskOverlay = this.add.sprite(this.player.x, this.player.y - 20, 'blueDemonMask').setScale(1.5);
    this.luchadorMaskOverlay.setDepth(this.player.depth + 1);

    // Blue aura effect
    this.player.setTint(0x6699ff);

    // Timer to end luchador mode
    this.time.delayedCall(duration, () => {
      this.deactivateLuchadorMode();
    });

    // Warning flash at 3 seconds remaining
    this.time.delayedCall(duration - 3000, () => {
      if (this.player && this.player.getData('luchadorMode')) {
        this.showText(this.player.x, this.player.y - 50, 'LUCHADOR ENDING!', '#ff6666');
        // Flashing effect
        this.tweens.add({
          targets: this.luchadorMaskOverlay,
          alpha: 0.3,
          duration: 200,
          yoyo: true,
          repeat: 7
        });
      }
    });
  }

  // ============ DEACTIVATE LUCHADOR MODE ============
  deactivateLuchadorMode() {
    if (!this.player) return;

    this.player.setData('luchadorMode', false);
    this.player.setData('isRolling', false);

    // Reset double-tap detection state
    this.lastZPressTime = 0;
    this.zTapFlashShown = false;

    // Handle tint - check if elote is still active to avoid visual conflict
    if (this.player.getData('eloteActive')) {
      this.player.setTint(0xffd700); // Restore elote golden tint
    } else {
      this.player.clearTint();
    }

    // Remove mask overlay
    if (this.luchadorMaskOverlay) {
      this.luchadorMaskOverlay.destroy();
      this.luchadorMaskOverlay = null;
    }

    // Clear afterimages
    this.luchadorAfterimages.forEach(img => {
      if (img && img.destroy) img.destroy();
    });
    this.luchadorAfterimages = [];
  }

  // ============ LUCHADOR ROLLING ATTACK ============
  startLuchadorRoll() {
    if (!this.player || !this.player.getData('luchadorMode')) return;
    if (this.player.getData('isRolling')) return;

    const onGround = this.player.body.blocked.down;
    if (onGround) return;  // Must be airborne!

    this.player.setData('isRolling', true);
    const dir = this.player.flipX ? -1 : 1;
    this.player.setData('rollDirection', dir);

    // 1.5x forward momentum
    this.player.body.setVelocityX(dir * 400);  // Strong forward push
    this.player.body.setVelocityY(100);  // Slight downward momentum

    // Visual: player curls into ball (scale squash)
    this.player.setScale(0.12, 0.18);  // Squashed ball shape

    // Play attack sound
    this.playSound('sfx-stomp');

    // Create rolling attack hitbox (larger than player)
    this.rollAttackActive = true;
  }

  // ============ END LUCHADOR ROLL ============
  endLuchadorRoll(hitWall = false) {
    if (!this.player) return;

    this.player.setData('isRolling', false);
    this.rollAttackActive = false;

    // Restore normal scale
    this.player.setScale(0.15);

    if (hitWall) {
      // Bounce back slightly on wall hit
      const dir = this.player.getData('rollDirection') || 1;
      this.player.body.setVelocityX(-dir * 150);
      this.player.body.setVelocityY(-100);
    }
  }

  // ============ LUCHADOR ROLL HIT ENEMY ============
  luchadorRollHitEnemy(enemy) {
    if (!enemy.getData('alive')) return;

    enemy.setData('alive', false);
    const dir = this.player.getData('rollDirection') || 1;
    enemy.body.setVelocity(dir * 200, -200);
    enemy.setTint(0x0066ff);  // Blue tint on hit

    // ========== SCREEN SHAKE on enemy hit! ==========
    this.cameras.main.shake(100, 0.01);

    // ========== HIT FREEZE - 50ms pause ==========
    this.physics.pause();
    this.time.delayedCall(50, () => {
      this.physics.resume();
    });

    this.time.delayedCall(500, () => {
      if (enemy && enemy.destroy) enemy.destroy();
    });

    this.playSound('sfx-stomp');
    gameState.score += 200;  // Bonus points for luchador kill!
    this.showText(enemy.x, enemy.y - 30, '+200 LUCHA!', '#0066ff');
  }

  // ============ CREATE BLUE AFTERIMAGE TRAIL ============
  createLuchadorAfterimage() {
    if (!this.player || !this.player.getData('isRolling')) return;

    // Create 3-4 afterimage sprites
    const afterimage = this.add.ellipse(
      this.player.x,
      this.player.y,
      30, 20,
      0x0066ff, 0.6
    );
    afterimage.setDepth(this.player.depth - 1);

    this.luchadorAfterimages.push(afterimage);

    // Fade out afterimage
    this.tweens.add({
      targets: afterimage,
      alpha: 0,
      scale: 0.5,
      duration: 200,
      onComplete: () => {
        const idx = this.luchadorAfterimages.indexOf(afterimage);
        if (idx > -1) this.luchadorAfterimages.splice(idx, 1);
        afterimage.destroy();
      }
    });

    // Limit afterimages
    while (this.luchadorAfterimages.length > 4) {
      const old = this.luchadorAfterimages.shift();
      if (old && old.destroy) old.destroy();
    }
  }

  hitEnemy(player, enemy) {
    if (player.getData('invincible') || !enemy.getData('alive')) return;

    // Luchador rolling attack defeats enemies on contact!
    if (player.getData('isRolling') && player.getData('luchadorMode')) {
      this.luchadorRollHitEnemy(enemy);
      return;
    }

    if (player.body.velocity.y > 0 && player.y < enemy.y - 10) {
      // Stomp
      enemy.setData('alive', false);
      enemy.body.setVelocity(0);
      enemy.setTint(0x888888);
      this.time.delayedCall(300, () => enemy.destroy());
      player.body.setVelocityY(-300);
      this.playSound('sfx-stomp');
      gameState.score += 100; // +100 points per stomp
      this.showText(enemy.x, enemy.y - 20, '+100', '#ffffff');
    } else {
      // Hit
      this.playSound('sfx-hurt');
      if (player.getData('big')) {
        player.setData('big', false);
        player.setTexture('xochi');
        player.body.setSize(12, 14);
        this.setInvincible(2000);
      } else {
        this.playerDie();
      }
    }
  }

  // DARK XOCHI collision - player touches the boss
  // DKC2-style: stomp always works, body collision only damages boss during RECOVER
  hitDarkXochi(player, darkXochi) {
    if (player.getData('invincible') || !darkXochi.getData('alive') || this.bossInvincible) return;

    const isStomp = player.body.velocity.y > 0 && player.y < darkXochi.y - 10;
    const isVulnerable = this.bossState === 'RECOVER';

    if (isStomp) {
      // Stomp ALWAYS works (classic Mario/DKC style)
      this.damageBoss(1);
      player.body.setVelocityY(-400);
      this.playSound('sfx-stomp');
      // After hit, boss goes back to APPROACH
      this.bossState = 'APPROACH';
      this.bossStateTimer = this.bossApproachTime;
    } else if (isVulnerable) {
      // Body collision during RECOVER = player can attack!
      // But for simplicity, just bounce them off without damage
      player.body.setVelocityX(player.x < darkXochi.x ? -200 : 200);
    } else {
      // Hit by Dark Xochi body (not during RECOVER = damage to player)
      this.playSound('sfx-hurt');
      if (player.getData('big')) {
        player.setData('big', false);
        player.setTexture('xochi_walk');
        player.body.setSize(200, 350);
        this.setInvincible(2000);
      } else {
        this.playerDie();
      }
    }
  }

  // Damage the boss (simplified DKC2-style)
  damageBoss(damage) {
    if (this.bossInvincible || !this.darkXochi || !this.darkXochi.getData('alive')) return;

    this.bossHealth -= damage;
    this.playSound('sfx-stomp');

    // Update health bar
    const healthPercent = this.bossHealth / this.bossMaxHealth;
    if (this.bossHealthBar) {
      this.bossHealthBar.setScale(healthPercent, 1);
      this.bossHealthBar.setX(this.cameras.main.width / 2 - (200 * (1 - healthPercent)) / 2);
    }

    // Show damage text with remaining HP
    this.showText(this.darkXochi.x, this.darkXochi.y - 50, `HIT! ${this.bossHealth}/${this.bossMaxHealth}`, '#ffffff');

    // Flash white then back to dark
    this.darkXochi.setTint(0xffffff);
    this.time.delayedCall(100, () => {
      if (this.darkXochi) this.darkXochi.setTint(0x220022);
    });

    // Knockback
    const dir = this.player.x < this.darkXochi.x ? 1 : -1;
    this.darkXochi.body.setVelocityX(dir * 200);

    // Check for death
    if (this.bossHealth <= 0) {
      this.defeatBoss();
      return;
    }

    // Brief invincibility after hit
    this.bossInvincible = true;
    this.time.delayedCall(500, () => {
      this.bossInvincible = false;
    });
  }

  // Boss defeat sequence
  defeatBoss() {
    if (!this.darkXochi) return;

    this.darkXochi.setData('alive', false);
    this.darkXochi.body.setVelocity(0);
    this.bossState = 'DEAD';

    // "NOOOOO!" text
    this.showBigText('NOOOOO!', '#ff00ff');

    // Flash rapidly
    let flashCount = 0;
    const flashInterval = this.time.addEvent({
      delay: 100,
      callback: () => {
        if (this.darkXochi) {
          this.darkXochi.setTint(flashCount % 2 === 0 ? 0xffffff : 0xff0000);
        }
        flashCount++;
        if (flashCount > 10) {
          flashInterval.remove();

          // Explosion particles
          for (let i = 0; i < 20; i++) {
            const particle = this.add.circle(
              this.darkXochi.x + Phaser.Math.Between(-30, 30),
              this.darkXochi.y + Phaser.Math.Between(-30, 30),
              Phaser.Math.Between(5, 15),
              0xff00ff
            );
            this.tweens.add({
              targets: particle,
              x: particle.x + Phaser.Math.Between(-100, 100),
              y: particle.y + Phaser.Math.Between(-100, 100),
              alpha: 0,
              scale: 0,
              duration: 500,
              onComplete: () => particle.destroy()
            });
          }

          // Fade out boss
          this.tweens.add({
            targets: this.darkXochi,
            alpha: 0,
            duration: 500,
            onComplete: () => {
              if (this.darkXochi) this.darkXochi.destroy();
              this.darkXochi = null;
            }
          });

          // Award points
          gameState.score += 5000;
          this.showBigText('+5000 POINTS!', '#ffff00');

          // Hide health bar
          if (this.bossHealthBar) this.bossHealthBar.destroy();
          if (this.bossHealthBarBg) this.bossHealthBarBg.destroy();
          if (this.bossNameText) this.bossNameText.destroy();

          // Spawn baby after victory (if not already there)
          this.time.delayedCall(1500, () => {
            if (!this.baby) {
              const ld = this.levelData;
              this.baby = this.physics.add.sprite(ld.babyPosition.x, ld.babyPosition.y, 'baby');
              this.baby.babyId = `baby-${this.levelNum}`;
              this.baby.body.allowGravity = false;
              this.tweens.add({ targets: this.baby, y: ld.babyPosition.y - 10, duration: 400, yoyo: true, repeat: -1, ease: 'Sine.easeInOut' });
              this.physics.add.overlap(this.player, this.baby, this.rescueBaby, null, this);
            }
          });
        }
      },
      loop: true
    });
  }


  rescueBaby(player, baby) {
    gameState.rescuedBabies.push(baby.babyId);

    // Award points for rescue
    const isBossLevel = (this.levelNum === 5 || this.levelNum === 10);
    const isFiestaLevel = (this.levelNum === 11);
    let points = 1000;

    if (isFiestaLevel) {
      this.showBigText('ALL BABIES RESCUED!', '#FFD700');
      points = 5000;  // Bonus for final rescue!
    } else if (isBossLevel) {
      this.showBigText('BABY RESCUED! +1000', '#ff00ff');
    } else {
      this.showBigText('RESCUED! +1000', '#ff6b9d');
    }
    gameState.score += points;

    baby.destroy();
    this.baby = null;

    // Clean up Dark Xochi boss stuff (in case still around)
    if (this.darkXochi) {
      this.darkXochi.destroy();
      this.darkXochi = null;
    }
    if (this.bossHealthBar) this.bossHealthBar.destroy();
    if (this.bossHealthBarBg) this.bossHealthBarBg.destroy();
    if (this.bossNameText) this.bossNameText.destroy();

    this.playSound('sfx-powerup');
    saveGame();

    // Level 11 - La Fiesta: Trigger celebration with credits!
    if (isFiestaLevel) {
      this.startFiestaCelebration();
    } else {
      this.time.delayedCall(1500, () => this.nextLevel());
    }
  }

  startFiestaCelebration() {
    // Disable player controls during celebration
    this.player.body.setVelocity(0, 0);
    this.player.body.allowGravity = false;

    // Make player dance (bounce animation)
    this.tweens.add({
      targets: this.player,
      y: this.player.y - 20,
      duration: 400,
      yoyo: true,
      repeat: -1,
      ease: 'Sine.easeInOut'
    });

    const camW = this.cameras.main.width;
    const camH = this.cameras.main.height;

    // Dark overlay for credits
    const overlay = this.add.rectangle(camW/2, camH/2, camW, camH, 0x000000, 0)
      .setScrollFactor(0).setDepth(600);

    // Fade in overlay slowly
    this.tweens.add({
      targets: overlay,
      fillAlpha: 0.7,
      duration: 3000,
      ease: 'Sine.easeIn'
    });

    // Celebration particles - fireworks!
    this.time.addEvent({
      delay: 500,
      repeat: 20,
      callback: () => {
        const fx = Phaser.Math.Between(50, camW - 50);
        const fy = Phaser.Math.Between(50, camH - 150);
        for (let i = 0; i < 8; i++) {
          const spark = this.add.circle(fx, fy, 4,
            Phaser.Utils.Array.GetRandom([0xFFD700, 0xFF69B4, 0x00FF00, 0xFF4500, 0x00FFFF]))
            .setScrollFactor(0).setDepth(650);
          const angle = (i / 8) * Math.PI * 2;
          this.tweens.add({
            targets: spark,
            x: fx + Math.cos(angle) * 80,
            y: fy + Math.sin(angle) * 80,
            alpha: 0,
            scale: 0.3,
            duration: 1000,
            onComplete: () => spark.destroy()
          });
        }
      }
    });

    // ============ CREDITS SEQUENCE (timed for ~2:30 song) ============
    const credits = [
      { text: '¡FELICIDADES!', style: { fontSize: '48px', color: '#FFD700' }, delay: 3000 },
      { text: 'You saved all the baby axolotls!', style: { fontSize: '24px', color: '#FF69B4' }, delay: 7000 },
      { text: '~ XOCHI ~', style: { fontSize: '36px', color: '#4ECDC4' }, delay: 15000 },
      { text: 'Aztec Warrior Adventure', style: { fontSize: '20px', color: '#FFFFFF' }, delay: 18000 },
      { text: '- CREDITS -', style: { fontSize: '28px', color: '#FFD700' }, delay: 28000 },
      { text: 'Game Design & Code', style: { fontSize: '18px', color: '#AAAAAA' }, delay: 35000 },
      { text: 'Victor Aguiar', style: { fontSize: '24px', color: '#FFFFFF' }, delay: 38000 },
      { text: 'Music', style: { fontSize: '18px', color: '#AAAAAA' }, delay: 48000 },
      { text: 'Suno AI', style: { fontSize: '24px', color: '#FFFFFF' }, delay: 51000 },
      { text: 'AI Assistant', style: { fontSize: '18px', color: '#AAAAAA' }, delay: 61000 },
      { text: 'Claude (Anthropic)', style: { fontSize: '24px', color: '#FFFFFF' }, delay: 64000 },
      { text: 'Art & Animation', style: { fontSize: '18px', color: '#AAAAAA' }, delay: 74000 },
      { text: 'Procedural Generation', style: { fontSize: '24px', color: '#FFFFFF' }, delay: 77000 },
      { text: 'Special Thanks', style: { fontSize: '18px', color: '#AAAAAA' }, delay: 87000 },
      { text: 'The Axolotls of Xochimilco', style: { fontSize: '22px', color: '#4ECDC4' }, delay: 90000 },
      { text: 'Inspired by', style: { fontSize: '18px', color: '#AAAAAA' }, delay: 100000 },
      { text: 'Xochimilco, México 🇲🇽', style: { fontSize: '26px', color: '#00FF00' }, delay: 103000 },
      { text: '¡Gracias por jugar!', style: { fontSize: '36px', color: '#FF69B4' }, delay: 118000 },
      { text: 'Thanks for playing!', style: { fontSize: '28px', color: '#FFFFFF' }, delay: 123000 },
    ];

    credits.forEach(credit => {
      this.time.delayedCall(credit.delay, () => {
        const txt = this.add.text(camW/2, camH/2, credit.text, {
          fontFamily: 'Arial Black',
          ...credit.style,
          stroke: '#000000',
          strokeThickness: 3
        }).setOrigin(0.5).setScrollFactor(0).setDepth(700).setAlpha(0);

        // Fade in
        this.tweens.add({
          targets: txt,
          alpha: 1,
          y: camH/2 - 20,
          duration: 1200,
          ease: 'Back.easeOut'
        });

        // Fade out after showing
        this.tweens.add({
          targets: txt,
          alpha: 0,
          y: camH/2 - 60,
          duration: 1000,
          delay: 4000,
          ease: 'Sine.easeIn',
          onComplete: () => txt.destroy()
        });
      });
    });

    // After song ends (~2:30 = 150 seconds), show final screen
    this.time.delayedCall(145000, () => {
      // Final message
      const finalText = this.add.text(camW/2, camH/2, 'THE END', {
        fontFamily: 'Arial Black',
        fontSize: '64px',
        color: '#FFD700',
        stroke: '#000000',
        strokeThickness: 4
      }).setOrigin(0.5).setScrollFactor(0).setDepth(800);

      this.tweens.add({
        targets: finalText,
        scale: 1.1,
        duration: 1000,
        yoyo: true,
        repeat: -1
      });

      // Press any key to continue
      const pressKey = this.add.text(camW/2, camH/2 + 80, 'Press any key to return to menu', {
        fontFamily: 'Arial',
        fontSize: '18px',
        color: '#FFFFFF'
      }).setOrigin(0.5).setScrollFactor(0).setDepth(800);

      this.tweens.add({
        targets: pressKey,
        alpha: 0.5,
        duration: 800,
        yoyo: true,
        repeat: -1
      });

      // Wait for input to go to menu
      this.input.keyboard.once('keydown', () => {
        mariachiMusic.stop();
        this.scene.stop('UIScene');
        this.scene.start('MenuScene');
      });

      this.input.once('pointerdown', () => {
        mariachiMusic.stop();
        this.scene.stop('UIScene');
        this.scene.start('MenuScene');
      });
    });
  }

  nextLevel() {
    if (this.levelNum >= 11) { // 11 levels - La Fiesta is the finale!
      mariachiMusic.stop(); // Victory!
      this.scene.stop('UIScene');
      this.scene.start('EndScene');
    } else {
      gameState.currentLevel = this.levelNum + 1;
      saveGame();
      this.scene.restart({ level: this.levelNum + 1 });
    }
  }

  playerDie() {
    if (this.player.getData('dead')) return;
    this.player.setData('dead', true);
    this.player.body.setVelocity(0, -300);
    this.player.setTint(0xff0000);
    gameState.lives--;
    this.playSound('sfx-hurt');

    // Show instant restart prompt - ALWAYS restart, never go to menu!
    const { width, height } = this.cameras.main;
    const outOfLives = gameState.lives <= 0;
    const checkpointLevel = getCheckpointLevel(this.levelNum);
    const worldName = WORLDS[getWorldForLevel(this.levelNum)].name;

    // Show restart message with checkpoint info
    let message = 'X to retry!';
    if (outOfLives) {
      if (checkpointLevel === 1) {
        message = 'GAME OVER - X to restart!';
      } else {
        message = `GAME OVER - X for ${worldName}`;
      }
    }

    const restartText = this.add.text(width/2, height/2, message, {
      fontFamily: 'Arial Black', fontSize: '22px', color: outOfLives ? '#ff6666' : '#ffffff',
      stroke: '#000000', strokeThickness: 4
    }).setOrigin(0.5).setScrollFactor(0).setDepth(1000);

    // Pulse animation
    this.tweens.add({
      targets: restartText, scale: 1.1, duration: 300, yoyo: true, repeat: -1
    });

    // INSTANT RESTART - no menu, just play again!
    const restartHandler = () => {
      const settings = DIFFICULTY_SETTINGS[gameState.difficulty];

      if (gameState.lives <= 0) {
        // Out of lives - Restart from WORLD CHECKPOINT (not level 1!)
        const checkpointLevel = getCheckpointLevel(this.levelNum);
        const world = getWorldForLevel(this.levelNum);

        gameState.lives = settings.lives;
        gameState.superJumps = settings.startingSuperJumps;
        gameState.maceAttacks = settings.startingMaceAttacks;
        gameState.currentLevel = checkpointLevel;

        // Only reset babies/stars for current world and beyond
        gameState.rescuedBabies = gameState.rescuedBabies.filter(id => {
          const lvl = parseInt(id.split('-')[1]);
          return lvl < checkpointLevel;
        });
        gameState.stars = gameState.stars.filter(id => {
          const lvl = parseInt(id.split('-')[0]);
          return lvl < checkpointLevel;
        });

        saveGame();
        this.scene.restart({ level: checkpointLevel });
      } else {
        // Still have lives - retry same level (baby should still be there if not rescued)
        this.scene.restart({ level: this.levelNum });
      }
    };

    // Enable restart after VERY brief delay (150ms - just enough to prevent double-tap)
    this.time.delayedCall(150, () => {
      this.input.keyboard.once('keydown-X', restartHandler);
      this.input.once('pointerdown', restartHandler);
    });
  }

  setInvincible(duration) {
    this.player.setData('invincible', true);
    this.tweens.add({
      targets: this.player,
      alpha: 0.3,
      duration: 100,
      yoyo: true,
      repeat: duration / 200,
      onComplete: () => { this.player.setData('invincible', false); this.player.setAlpha(1); }
    });
  }

  showText(x, y, text, color) {
    const t = this.add.text(x, y, text, { fontFamily: 'Arial', fontSize: '16px', color: color }).setOrigin(0.5);
    this.tweens.add({ targets: t, y: y - 30, alpha: 0, duration: 600, onComplete: () => t.destroy() });
  }

  showBigText(text, color) {
    const { width, height } = this.cameras.main;
    const t = this.add.text(width/2, height/3, text, {
      fontFamily: 'Arial Black', fontSize: '48px', color: color, stroke: '#000', strokeThickness: 4
    }).setOrigin(0.5).setScrollFactor(0);
    this.tweens.add({ targets: t, scale: 1.3, alpha: 0, duration: 1000, onComplete: () => t.destroy() });
  }

  update(time, delta) {
    // Safety check - make sure player exists
    if (!this.player || !this.player.body) return;
    if (this.player.getData('dead')) return;

    // Track if player can move (climbing/hanging blocks movement but NOT world updates)
    const playerCanMove = !this.player.getData('climbing') && !this.player.getData('hanging');

    // Default delta to 16ms (~60fps) if not provided
    if (!delta) delta = 16;

    const tc = this.touchControls || { left: false, right: false, jump: false, superJump: false, attack: false, run: false };

    // ============ LEDGE GRAB MECHANIC - Improved for Upscroller! ============
    const isHanging = this.player.getData('hanging') || false;
    const grabCooldown = this.player.getData('grabCooldown') || 0;

    // Update grab cooldown
    if (grabCooldown > 0) {
      this.player.setData('grabCooldown', grabCooldown - delta);
    }

    if (isHanging) {
      // HANGING STATE - player is grabbing a ledge!
      this.player.body.setVelocityX(0);
      this.player.body.setVelocityY(0);
      this.player.body.allowGravity = false;

      // ============ LEGO-STYLE ATTACHMENT SYSTEM ============
      // If hanging on a moving trajinera, LATCH to it and move together!
      const attachedTrajinera = this.player.getData('ledgePlatform');
      if (attachedTrajinera && attachedTrajinera.w) {
        // This is a trajinera DATA object (has w, h, x, y, speed, dir)
        const side = this.player.getData('ledgeSide');
        const trajW = attachedTrajinera.w;
        const trajH = attachedTrajinera.h || 25;

        // Calculate edge position based on trajinera's CURRENT position
        const edgeX = side === 'left'
          ? attachedTrajinera.x - trajW / 2
          : attachedTrajinera.x + trajW / 2;
        const edgeY = attachedTrajinera.y - trajH / 2 - 5;  // Platform top

        // LATCH: Move Xochi with the trajinera
        this.player.x = side === 'left' ? edgeX - 12 : edgeX + 12;
        this.player.y = edgeY + 15;

        // Update stored ledge position for climb calculations
        this.player.setData('ledgeX', edgeX);
        this.player.setData('ledgeY', edgeY);
      }

      // Visual feedback - slight sway
      this.player.rotation = Math.sin(time / 300) * 0.03;

      // PULL UP - press UP or JUMP to climb onto ledge
      const wantClimb = (this.keys && this.keys.X && Phaser.Input.Keyboard.JustDown(this.keys.X)) ||
                        (this.cursors && this.cursors.up && Phaser.Input.Keyboard.JustDown(this.cursors.up)) ||
                        (this.keys && this.keys.W && Phaser.Input.Keyboard.JustDown(this.keys.W)) ||
                        tc.jump;

      if (wantClimb && !this.player.getData('climbing')) {
        const ledgeX = this.player.getData('ledgeX');
        const ledgeY = this.player.getData('ledgeY');
        const ledgeSide = this.player.getData('ledgeSide');
        const attachedTraj = this.player.getData('ledgePlatform');

        // Enter climbing state (prevents movement during animation)
        this.player.setData('climbing', true);
        this.player.setData('hanging', false);
        this.player.setData('ledgePlatform', null);  // Detach from trajinera
        this.player.rotation = 0;

        // Calculate target position on top of platform
        // If attached to trajinera, use its current position for accuracy
        let targetX, targetY;
        if (attachedTraj && attachedTraj.w) {
          const trajW = attachedTraj.w;
          const trajH = attachedTraj.h || 25;
          const currentEdgeX = ledgeSide === 'left'
            ? attachedTraj.x - trajW / 2
            : attachedTraj.x + trajW / 2;
          const currentEdgeY = attachedTraj.y - trajH / 2 - 5;
          targetX = currentEdgeX + (ledgeSide === 'left' ? 30 : -30);
          targetY = currentEdgeY - 35;
        } else {
          targetX = ledgeX + (ledgeSide === 'left' ? 30 : -30);
          targetY = ledgeY - 35;
        }

        // PHASE 1: Pull-up - use JUMP sprite (reaching up pose)
        this.player.setTexture('xochi_jump');
        this.player.clearTint();

        this.tweens.add({
          targets: this.player,
          x: ledgeX + (ledgeSide === 'left' ? 10 : -10),
          y: ledgeY - 15,
          duration: 100,
          ease: 'Power2.easeOut',
          onComplete: () => {
            // PHASE 2: Vault over - use ATTACK sprite (dynamic action pose)
            this.player.setTexture('xochi_attack');

            this.tweens.add({
              targets: this.player,
              x: targetX,
              y: targetY,
              duration: 120,
              ease: 'Sine.easeOut',
              onComplete: () => {
                // PHASE 3: Landing - back to WALK sprite
                this.player.setTexture('xochi_walk');
                this.player.setData('climbing', false);
                this.player.setData('grabCooldown', 200);
                this.player.body.allowGravity = true;
                this.player.body.setVelocityY(0);
                this.player.body.setVelocityX(0);
              }
            });
          }
        });

        this.playSound('sfx-jump', { pitchVariation: true });
      }

      // DROP DOWN - press DOWN to let go
      const wantDrop = (this.cursors && this.cursors.down && Phaser.Input.Keyboard.JustDown(this.cursors.down));
      if (wantDrop) {
        this.player.setData('hanging', false);
        this.player.setData('ledgePlatform', null);  // Detach from trajinera
        this.player.setData('grabCooldown', 400);  // Longer cooldown when dropping
        this.player.body.allowGravity = true;
        this.player.rotation = 0;
        this.player.setTexture('xochi_jump');  // Falling pose
        this.player.body.setVelocityY(100);  // Drop down
      }

      // SCREEN EDGE CHECK - if trajinera moves Xochi off screen edge, release grab and fall
      const camBounds = this.cameras.main.worldView;
      if (this.player.x < camBounds.left - 20 || this.player.x > camBounds.right + 20) {
        this.player.setData('hanging', false);
        this.player.setData('ledgePlatform', null);  // Detach from trajinera
        this.player.setData('grabCooldown', 300);
        this.player.body.allowGravity = true;
        this.player.rotation = 0;
        this.player.setTexture('xochi_jump');
        this.player.body.setVelocityY(50);
      }

      // AUTO-RELEASE after 2 seconds - prevents hanging bugs and encourages action
      const hangStartTime = this.player.getData('hangStartTime') || 0;
      const hangDuration = time - hangStartTime;
      if (hangDuration > 2000) {  // 2 seconds max hang time
        this.player.setData('hanging', false);
        this.player.setData('ledgePlatform', null);
        this.player.setData('grabCooldown', 500);  // Longer cooldown after auto-release
        this.player.body.allowGravity = true;
        this.player.rotation = 0;
        this.player.setTexture('xochi_jump');
        this.player.body.setVelocityY(80);  // Gentle drop
        this.showText(this.player.x, this.player.y - 30, 'SLIP!', '#ff6666');  // Visual feedback
      }
      // Don't process normal movement while hanging, but DON'T return - let world update continue
    }

    // LEDGE DETECTION - only when clearly falling from ABOVE (not jumping from below)
    const isFalling = this.player.body.velocity.y > 100;  // Must be clearly falling downward to grab
    const notOnGround = !this.player.body.blocked.down;
    const canGrab = grabCooldown <= 0;

    // Only try to grab if pressing left or right (intentional grab)
    const pressingLeft = this.cursors && this.cursors.left && this.cursors.left.isDown;
    const pressingRight = this.cursors && this.cursors.right && this.cursors.right.isDown;
    const pressingDirection = pressingLeft || pressingRight;

    if (isFalling && notOnGround && canGrab && pressingDirection &&
        !this.player.getData('swimming') && !this.player.getData('hanging') && !this.player.getData('climbing')) {

      const grabRange = 45;  // More forgiving - works on small platforms too
      const playerH = this.player.displayHeight || this.player.height || 50;
      const playerW = this.player.displayWidth || this.player.width || 30;
      const playerTop = this.player.y - playerH / 2;
      const playerLeft = this.player.x - playerW / 2;
      const playerRight = this.player.x + playerW / 2;

      let grabbed = false;

      // Check trajineras FIRST (more important for upscroller)
      // trajineras is an ARRAY of data objects, not a Phaser group!
      if (!grabbed && this.trajineras && Array.isArray(this.trajineras)) {
        for (let i = 0; i < this.trajineras.length && !grabbed; i++) {
          const traj = this.trajineras[i];
          if (!traj) continue;

          // Trajinera data object has: x, y, w, h, speed, dir, container, platform
          const trajH = traj.h || 25;
          const trajW = traj.w || 100;
          const trajTop = traj.y - trajH / 2 - 5;  // Platform sits on top of boat
          const trajLeft = traj.x - trajW / 2;
          const trajRight = traj.x + trajW / 2;

          // Height check - player's hands should be near platform top
          const heightMatch = playerTop > trajTop - grabRange && playerTop < trajTop + grabRange;

          if (heightMatch) {
            // Grab LEFT edge (pressing right toward platform)
            if (pressingRight && Math.abs(playerRight - trajLeft) < grabRange) {
              this.grabLedge(trajLeft, trajTop, 'left', traj);  // Pass trajinera DATA object
              grabbed = true;
              break;
            }
            // Grab RIGHT edge (pressing left toward platform)
            if (pressingLeft && Math.abs(playerLeft - trajRight) < grabRange) {
              this.grabLedge(trajRight, trajTop, 'right', traj);  // Pass trajinera DATA object
              grabbed = true;
              break;
            }
          }
        }
      }

      // Then check static platforms
      if (!grabbed && this.platforms && typeof this.platforms.getChildren === 'function') {
        const platformList = this.platforms.getChildren();
        for (let i = 0; i < platformList.length && !grabbed; i++) {
          const platform = platformList[i];
          if (!platform) continue;

          const platH = platform.displayHeight || platform.height || 20;
          const platW = platform.displayWidth || platform.width || 100;
          const platTop = platform.y - platH / 2;
          const platLeft = platform.x - platW / 2;
          const platRight = platform.x + platW / 2;

          const heightMatch = playerTop > platTop - grabRange && playerTop < platTop + grabRange;

          if (heightMatch) {
            if (pressingRight && Math.abs(playerRight - platLeft) < grabRange) {
              this.grabLedge(platLeft, platTop, 'left');
              grabbed = true;
              break;
            }
            if (pressingLeft && Math.abs(playerLeft - platRight) < grabRange) {
              this.grabLedge(platRight, platTop, 'right');
              grabbed = true;
              break;
            }
          }
        }
      }
    }

    const onGround = this.player.body.blocked.down;
    const isRunning = this.keys.SPACE.isDown || tc.run;  // SPACE or drag far = run
    const speed = isRunning ? 280 : 180;

    // Movement (keyboard + touch) - ONLY when not hanging/climbing
    if (playerCanMove) {
      if (this.cursors.left.isDown || this.keys.A.isDown || tc.left) {
        this.player.body.setVelocityX(-speed);
        this.player.setFlipX(true);
      } else if (this.cursors.right.isDown || this.keys.D.isDown || tc.right) {
        this.player.body.setVelocityX(speed);
        this.player.setFlipX(false);
      } else {
        this.player.body.setVelocityX(this.player.body.velocity.x * 0.8);
      }
    }

    // ============ SIMPLIFIED JUMP SYSTEM (X key) ============
    // X = Jump (on ground) or Super Jump (in air when powered up)
    // Jump buffer: if you press jump slightly before landing, it still works
    // Coyote time: if you walk off a ledge, you can still jump briefly

    // Initialize jump timers if not set
    if (this.jumpBufferTime === undefined) this.jumpBufferTime = 0;
    if (this.coyoteTime === undefined) this.coyoteTime = 0;
    if (this.wasOnGround === undefined) this.wasOnGround = false;

    // X key is now the ONLY jump key
    const jumpKeyDown = this.keys.X.isDown || tc.jump;
    const jumpJustPressed = Phaser.Input.Keyboard.JustDown(this.keys.X) ||
                            (!this.lastTouchJump && tc.jump);

    // Update coyote time (150ms grace period after leaving ground)
    if (onGround) {
      this.coyoteTime = 150;
    }
    if (this.coyoteTime > 0) this.coyoteTime -= delta;

    // Update jump buffer (150ms window to press jump before landing)
    if (jumpJustPressed) {
      this.jumpBufferTime = 150;
    }
    if (this.jumpBufferTime > 0) this.jumpBufferTime -= delta;

    // Can normal jump if: on ground OR within coyote time
    const canNormalJump = onGround || this.coyoteTime > 0;

    // Execute jump - ONLY when not hanging/climbing
    if (playerCanMove && (jumpJustPressed || this.jumpBufferTime > 0)) {
      if (canNormalJump) {
        // Normal jump from ground
        this.player.body.setVelocityY(-450);
        this.playSound('sfx-jump', { pitchVariation: true });
        this.jumpBufferTime = 0;
        this.coyoteTime = 0;
      } else if (gameState.superJumps > 0) {
        // SUPER JUMP in mid-air! (auto-activates when powered up)
        gameState.superJumps--;
        this.player.body.setVelocityY(-650);
        this.playSound('sfx-superjump', { pitchVariation: true });
        this.showText(this.player.x, this.player.y - 30, 'SUPER!', '#00ffff');
        this.events.emit('updateUI');
        this.jumpBufferTime = 0;

        // Visual effect - cyan burst
        for (let i = 0; i < 12; i++) {
          const angle = (i / 12) * Math.PI * 2;
          const trail = this.add.circle(
            this.player.x + Math.cos(angle) * 10,
            this.player.y + Math.sin(angle) * 10,
            6, 0x00ffff, 0.8
          );
          this.tweens.add({
            targets: trail,
            x: this.player.x + Math.cos(angle) * 40,
            y: this.player.y + Math.sin(angle) * 40,
            alpha: 0,
            scale: 0.5,
            duration: 300,
            onComplete: () => trail.destroy()
          });
        }
      }
    }

    this.lastTouchJump = tc.jump;
    this.wasOnGround = onGround;

    // ============ LUCHADOR MODE UPDATE ============
    if (this.player.getData('luchadorMode')) {
      // Update mask overlay position
      if (this.luchadorMaskOverlay) {
        this.luchadorMaskOverlay.setPosition(this.player.x, this.player.y - 25);
        this.luchadorMaskOverlay.setFlipX(this.player.flipX);
      }

      // Handle rolling state
      if (this.player.getData('isRolling')) {
        // Create blue afterimage trail
        this.createLuchadorAfterimage();

        // Check for wall collision - end roll and bounce back
        if (this.player.body.blocked.left || this.player.body.blocked.right) {
          this.endLuchadorRoll(true);
        }

        // Check for ground landing - end roll
        if (this.player.body.blocked.down) {
          this.endLuchadorRoll(false);
        }

        // Check for enemy collision during roll
        if (this.rollAttackActive) {
          this.enemies.getChildren().forEach(enemy => {
            if (!enemy.getData('alive')) return;
            const dist = Phaser.Math.Distance.Between(this.player.x, this.player.y, enemy.x, enemy.y);
            if (dist < 50) {
              this.luchadorRollHitEnemy(enemy);
            }
          });
        }
      }
    }

    // ============ THUNDER ATTACK (Z key) ============
    // NOW REQUIRES POWER-UP like super jumps!
    if (this.attackCooldown > 0) this.attackCooldown -= 16;

    // Touch attack - only trigger on first frame of touch
    const touchAttackJustPressed = tc.attack && !this.lastTouchAttack;
    this.lastTouchAttack = tc.attack;

    const attackPressed = Phaser.Input.Keyboard.JustDown(this.keys.Z) || touchAttackJustPressed;

    // ============ LUCHADOR DOUBLE-TAP Z DETECTION ============
    if (attackPressed && this.player.getData('luchadorMode') && !onGround) {
      const currentTime = this.time.now;
      const timeSinceLastZ = currentTime - this.lastZPressTime;

      if (timeSinceLastZ < 300 && this.zTapFlashShown) {
        // Double-tap detected while airborne - trigger rolling attack!
        if (!this.player.getData('isRolling')) {
          this.startLuchadorRoll();
          this.lastZPressTime = 0;  // Reset to prevent triple-tap
          this.zTapFlashShown = false;
        }
      } else {
        // First tap - show brief blue flash to signal double-tap window
        this.lastZPressTime = currentTime;
        this.zTapFlashShown = true;

        // Visual feedback: brief blue flash
        const flash = this.add.circle(this.player.x, this.player.y, 40, 0x0066ff, 0.5);
        this.tweens.add({
          targets: flash,
          alpha: 0,
          scale: 1.5,
          duration: 150,
          onComplete: () => flash.destroy()
        });
      }
    }

    // Regular mace swing (no thunderbolt) - only when not hanging/climbing AND not rolling
    const isRolling = this.player.getData('isRolling');
    if (playerCanMove && attackPressed && this.attackCooldown <= 0 && !this.isAttacking && !isRolling) {
      this.isAttacking = true;
      this.attackCooldown = 500; // 0.5 second cooldown for regular swing

      const dir = this.player.flipX ? -1 : 1;

      // Don't change texture during attack - causes physics issues due to different frame sizes
      // Visual effects handle the attack animation instead

      this.playSound('sfx-stomp'); // Attack sound

      // Visual swing effect (arc)
      const swingArc = this.add.arc(
        this.player.x + dir * 30,
        this.player.y,
        40,
        dir > 0 ? 200 : 340,
        dir > 0 ? 340 : 200,
        false,
        0xffaa00, 0.6
      );
      this.tweens.add({
        targets: swingArc,
        alpha: 0,
        scale: 1.5,
        duration: 150,
        onComplete: () => swingArc.destroy()
      });

      // Melee hit enemies very close (no thunderbolt)
      const meleeRange = 70;
      this.enemies.getChildren().forEach(enemy => {
        if (!enemy.getData('alive')) return;
        const dist = Math.abs(enemy.x - this.player.x);
        const sameDirection = (enemy.x - this.player.x) * dir > 0;
        if (dist < meleeRange && sameDirection && Math.abs(enemy.y - this.player.y) < 40) {
          enemy.setData('alive', false);
          enemy.body.setVelocity(dir * 150, -150);
          this.playSound('sfx-stomp');
          gameState.score += 100;
          this.showText(enemy.x, enemy.y - 20, '+100', '#ffffff');
          this.time.delayedCall(500, () => enemy.destroy());
        }
      });

      // MELEE HIT BOSS - 1 damage!
      if (this.darkXochi && this.darkXochi.getData('alive')) {
        const bossDist = Math.abs(this.darkXochi.x - this.player.x);
        const bossSameDir = (this.darkXochi.x - this.player.x) * dir > 0;
        if (bossDist < meleeRange && bossSameDir && Math.abs(this.darkXochi.y - this.player.y) < 60) {
          this.damageBoss(1, false);
        }
      }

      // THUNDERBOLT - Mario fireball style! Single projectile, hits ONE enemy
      if (gameState.maceAttacks > 0) {
        gameState.maceAttacks--;
        this.events.emit('updateUI');

        // Create a SINGLE lightning bolt projectile (like Mario fireball)
        const boltX = this.player.x + dir * 30;
        const boltY = this.player.y;

        // The bolt visual
        const bolt = this.add.container(boltX, boltY);
        const boltCore = this.add.ellipse(0, 0, 20, 12, 0xffff00);
        const boltGlow = this.add.ellipse(0, 0, 28, 18, 0x88ffff, 0.5);
        bolt.add(boltGlow);
        bolt.add(boltCore);

        // Add physics to the bolt
        this.physics.add.existing(bolt);
        bolt.body.setVelocity(dir * 400, 0);  // Flies straight horizontally
        bolt.body.allowGravity = false;
        bolt.body.setSize(20, 12);
        bolt.setData('alive', true);
        bolt.setData('dir', dir);

        // Spark trail effect
        this.time.addEvent({
          delay: 50,
          repeat: 20,
          callback: () => {
            if (!bolt.getData('alive')) return;
            const spark = this.add.circle(bolt.x, bolt.y + (Math.random() - 0.5) * 10, 3, 0xffff00, 0.8);
            this.tweens.add({
              targets: spark,
              alpha: 0, scale: 0,
              duration: 150,
              onComplete: () => spark.destroy()
            });
          }
        });

        // Check collision with enemies - hits ONLY ONE then disappears!
        const hitEnemy = (bolt, enemy) => {
          if (!bolt.getData('alive') || !enemy.getData('alive')) return;
          bolt.setData('alive', false);
          enemy.setData('alive', false);
          enemy.body.setVelocity(dir * 150, -150);
          enemy.setTint(0xffff00);
          this.playSound('sfx-stomp');
          gameState.score += 200;
          this.showText(enemy.x, enemy.y - 20, '+200', '#ffff00');

          // Explosion effect
          for (let i = 0; i < 8; i++) {
            const spark = this.add.circle(bolt.x, bolt.y, 5, 0xffff00);
            const angle = (i / 8) * Math.PI * 2;
            this.tweens.add({
              targets: spark,
              x: bolt.x + Math.cos(angle) * 30,
              y: bolt.y + Math.sin(angle) * 30,
              alpha: 0,
              duration: 200,
              onComplete: () => spark.destroy()
            });
          }

          bolt.destroy();
          this.time.delayedCall(500, () => enemy.destroy());
        };

        this.physics.add.overlap(bolt, this.enemies, hitEnemy);

        // Boss collision - only 1 damage now (not 2)
        if (this.darkXochi) {
          this.physics.add.overlap(bolt, this.darkXochi, (bolt, boss) => {
            if (!bolt.getData('alive')) return;
            bolt.setData('alive', false);
            this.damageBoss(1, false);  // Only 1 damage, not 2!
            bolt.destroy();
          });
        }

        // Destroy bolt after traveling too far or hitting wall
        this.time.delayedCall(1500, () => {
          if (bolt && bolt.getData('alive')) {
            bolt.setData('alive', false);
            bolt.destroy();
          }
        });
      }

      // Return to normal after attack
      this.time.delayedCall(250, () => {
        this.isAttacking = false;
      });
    }

    // ============ FRAME ANIMATION (DKC-style) ============
    const isMoving = Math.abs(this.player.body.velocity.x) > 10;
    const isInAir = !onGround;
    // isRunning already defined above (SPACE key or touch drag far)
    const now = this.time.now;

    // Walk animation timer (cycle every 200ms for walk, 120ms for run)
    if (!this.walkAnimTime) this.walkAnimTime = 0;

    // SKIP animation switching when hanging/climbing (we control texture manually)
    if (playerCanMove) {
      // JUMPING - use jump frame
      if (isInAir && !this.isAttacking) {
        this.player.setTexture('xochi_jump');
        this.player.setScale(0.15);
        this.player.setRotation(0);

      // RUNNING (SHIFT held) - use run frame with fast bob
      } else if (isMoving && isRunning && onGround && !this.isAttacking) {
        this.player.setTexture('xochi_run');
        // Fast bobbing for running
        const runCycle = Math.sin(now * 0.025) * 0.5; // Faster cycle
        const bobScale = 0.15 + runCycle * 0.008; // Subtle scale pulse
        const tilt = Math.sin(now * 0.025) * 0.08; // Side-to-side tilt
        this.player.setScale(bobScale);
        this.player.setRotation(tilt);

      // WALKING - use walk frame with bob animation
      } else if (isMoving && onGround && !this.isAttacking) {
        this.player.setTexture('xochi_walk');
        // DKC-style walk bob - body bounces up/down, slight tilt
        const walkCycle = Math.sin(now * 0.015); // Smooth cycle
        const bobScale = 0.15 + walkCycle * 0.006; // Subtle vertical squash/stretch
        const tilt = Math.sin(now * 0.015) * 0.05; // Gentle side lean
        this.player.setScale(bobScale);
        this.player.setRotation(tilt);

      // IDLE - subtle breathing animation
      } else if (!this.isAttacking) {
        this.player.setTexture('xochi_walk');
        // Gentle breathing effect
        const breathe = Math.sin(now * 0.003) * 0.004;
        this.player.setScale(0.15 + breathe);
        this.player.setRotation(0);
      }

      // ATTACKING - keep stable scale/rotation to prevent physics issues
      if (this.isAttacking) {
        this.player.setScale(0.15);
        this.player.setRotation(0);
      }
    }

    // Enemies patrol
    this.enemies.getChildren().forEach(e => {
      if (!e.getData('alive')) return;

      const type = e.getData('type');

      if (type === 'flying') {
        // FLAPPY BIRD style movement!
        const baseY = e.getData('baseY');
        const flapUp = e.getData('flapUp');

        // Flap up and down erratically
        if (flapUp) {
          e.body.setVelocityY(-120);
          if (e.y < baseY - 40) e.setData('flapUp', false);
        } else {
          e.body.setVelocityY(100);
          if (e.y > baseY + 40) e.setData('flapUp', true);
        }

        // Reverse at world bounds
        if (e.x < 50 || e.x > this.levelData.width - 50) {
          e.setData('dir', e.getData('dir') * -1);
          e.body.setVelocityX(e.getData('speed') * e.getData('dir'));
          e.setFlipX(e.getData('dir') > 0);
        }

        // SHOOT at player!
        let shootTimer = e.getData('shootTimer');
        shootTimer -= 16; // ~60fps
        if (shootTimer <= 0) {
          // Only shoot if on screen and near player
          const dist = Phaser.Math.Distance.Between(e.x, e.y, this.player.x, this.player.y);
          if (dist < 400) {
            this.shootProjectile(e);
          }
          e.setData('shootTimer', Phaser.Math.Between(2000, 4000)); // Next shot in 2-4 seconds
        } else {
          e.setData('shootTimer', shootTimer);
        }

      } else if (type === 'platform') {
        // Platform enemies - walk back and forth WITHOUT falling!
        const platLeft = e.getData('platLeft');
        const platRight = e.getData('platRight');

        // Turn around at platform edges
        if (e.x <= platLeft) {
          e.setData('dir', 1);
          e.body.setVelocityX(40);
          e.setFlipX(true);
        } else if (e.x >= platRight) {
          e.setData('dir', -1);
          e.body.setVelocityX(-40);
          e.setFlipX(false);
        }

        // Also turn at walls
        if (e.body.blocked.left || e.body.blocked.right) {
          e.setData('dir', e.getData('dir') * -1);
          e.body.setVelocityX(40 * e.getData('dir'));
          e.setFlipX(e.getData('dir') > 0);
        }

      } else {
        // Ground enemies - reverse at walls
        if (e.body.blocked.left || e.body.blocked.right) {
          e.setData('dir', e.getData('dir') * -1);
          e.body.setVelocityX(60 * e.getData('dir'));
          e.setFlipX(e.getData('dir') > 0);
        }
      }
    });

    // DARK XOCHI AI - DKC2-style 4-phase boss fight!
    // Pattern: APPROACH -> TELEGRAPH -> ATTACK -> RECOVER (vulnerable!)
    if (this.darkXochi && this.darkXochi.getData('alive')) {
      const speed = this.darkXochi.getData('speed');
      const dx = this.player.x - this.darkXochi.x;
      const dy = this.player.y - this.darkXochi.y;
      const distToPlayer = Math.abs(dx);
      const onGround = this.darkXochi.body.blocked.down;

      // Decrease state timer
      if (this.bossStateTimer > 0) {
        this.bossStateTimer -= delta;
      }

      // Calculate HP-based speed multiplier (gets faster as HP drops)
      const hpRatio = this.bossHealth / this.bossMaxHealth;
      const speedMult = 1 + (1 - hpRatio) * 0.5; // 1.0x at full HP, 1.5x at low HP

      // State machine
      switch (this.bossState) {
        case 'APPROACH':
          // Walk slowly toward player - NO attacks during this phase
          this.darkXochi.setTint(0x220022); // Normal dark tint

          if (Math.abs(dx) > 80) {
            this.darkXochi.body.setVelocityX((dx > 0 ? speed : -speed) * speedMult);
            this.darkXochi.setFlipX(dx < 0);
          } else {
            this.darkXochi.body.setVelocityX(0);
          }

          // Jump if blocked or player is way above
          if (onGround && (this.darkXochi.body.blocked.left || this.darkXochi.body.blocked.right || dy < -120)) {
            this.darkXochi.body.setVelocityY(-380);
          }

          // After approach time OR close enough, go to TELEGRAPH
          if (this.bossStateTimer <= 0 || distToPlayer < 120) {
            this.bossState = 'TELEGRAPH';
            this.bossStateTimer = this.bossTelegraphTime;
            this.darkXochi.body.setVelocityX(0);
            this.darkXochi.setFlipX(dx < 0); // Face player

            // Show "!" warning above head
            if (this.bossTelegraphSprite) this.bossTelegraphSprite.destroy();
            this.bossTelegraphSprite = this.add.text(this.darkXochi.x, this.darkXochi.y - 60, '!', {
              fontFamily: 'Arial Black', fontSize: '36px', color: '#ffff00',
              stroke: '#ff0000', strokeThickness: 4
            }).setOrigin(0.5);
          }
          break;

        case 'TELEGRAPH':
          // Stop moving, flash warning - player should get ready!
          this.darkXochi.body.setVelocityX(0);

          // Flash between yellow and red
          const flashRate = Math.floor(this.bossStateTimer / 100) % 2;
          this.darkXochi.setTint(flashRate === 0 ? 0xffff00 : 0xff4400);

          // Update "!" position
          if (this.bossTelegraphSprite) {
            this.bossTelegraphSprite.setPosition(this.darkXochi.x, this.darkXochi.y - 60);
          }

          // When telegraph done, execute attack
          if (this.bossStateTimer <= 0) {
            // Remove "!" indicator
            if (this.bossTelegraphSprite) {
              this.bossTelegraphSprite.destroy();
              this.bossTelegraphSprite = null;
            }

            this.bossState = 'ATTACK';
            this.darkXochi.setTint(0xff0000); // Red during attack

            // Execute attack immediately (alternating type)
            const dir = this.darkXochi.flipX ? -1 : 1;

            if (this.bossAttackType === 0) {
              // LEAP ATTACK - Jump toward player
              this.darkXochi.body.setVelocityY(-450);
              this.darkXochi.body.setVelocityX(dir * -300 * speedMult); // Toward player
              this.showText(this.darkXochi.x, this.darkXochi.y - 40, 'LEAP!', '#ff0000');
            } else {
              // MACE SWING - Wide horizontal attack
              const swingArc = this.add.arc(
                this.darkXochi.x + dir * -40,
                this.darkXochi.y,
                60, // Larger radius
                dir < 0 ? 200 : 340,
                dir < 0 ? 340 : 200,
                false,
                0xff00ff, 0.7
              );
              this.tweens.add({
                targets: swingArc,
                alpha: 0,
                scale: 1.8,
                duration: 200,
                onComplete: () => swingArc.destroy()
              });

              // Damage player if in melee range
              if (distToPlayer < 100) {
                if (!this.player.getData('invincible')) {
                  this.playSound('sfx-hurt');
                  if (this.player.getData('big')) {
                    this.player.setData('big', false);
                    this.player.setTexture('xochi_walk');
                    this.setInvincible(2000);
                  } else {
                    this.playerDie();
                  }
                }
              }
              this.showText(this.darkXochi.x, this.darkXochi.y - 40, 'SWING!', '#ff00ff');
            }

            // Alternate attack type for next cycle
            this.bossAttackType = 1 - this.bossAttackType;

            // Short attack duration then go to RECOVER
            this.bossStateTimer = 400;
          }
          break;

        case 'ATTACK':
          // Attack is executing, wait for it to finish
          // Ground pound effect if landing from leap
          if (onGround && this.darkXochi.body.velocity.y >= 0 && this.bossAttackType === 1) {
            // Just landed from leap - create shockwave
            const shockL = this.add.rectangle(this.darkXochi.x - 40, this.darkXochi.y + 20, 60, 10, 0xff00ff, 0.8);
            const shockR = this.add.rectangle(this.darkXochi.x + 40, this.darkXochi.y + 20, 60, 10, 0xff00ff, 0.8);
            this.tweens.add({ targets: [shockL, shockR], alpha: 0, scaleX: 2, duration: 300, onComplete: () => { shockL.destroy(); shockR.destroy(); }});

            // Damage player if close when landing
            if (distToPlayer < 100 && Math.abs(dy) < 50) {
              if (!this.player.getData('invincible')) {
                this.playSound('sfx-hurt');
                if (this.player.getData('big')) {
                  this.player.setData('big', false);
                  this.player.setTexture('xochi_walk');
                  this.setInvincible(2000);
                } else {
                  this.playerDie();
                }
              }
            }
          }

          // When attack finishes, go to RECOVER (vulnerable phase!)
          if (this.bossStateTimer <= 0 && onGround) {
            this.bossState = 'RECOVER';
            this.bossStateTimer = this.bossRecoverTime / speedMult; // Shorter at low HP
            this.darkXochi.body.setVelocity(0);
            this.darkXochi.setTint(0x666688); // Tired/gray tint - VULNERABLE!
            this.showText(this.darkXochi.x, this.darkXochi.y - 40, 'TIRED...', '#88ff88');
          }
          break;

        case 'RECOVER':
          // VULNERABLE PHASE - Boss stands still, dizzy
          // This is when player should attack!
          this.darkXochi.body.setVelocityX(0);

          // Wobble animation to show dizzy state
          this.darkXochi.angle = Math.sin(Date.now() / 100) * 5;

          // Flash to warn player the window is closing
          if (this.bossStateTimer < 500) {
            const warn = Math.floor(this.bossStateTimer / 100) % 2;
            this.darkXochi.setTint(warn === 0 ? 0x666688 : 0x888888);
          }

          // When recover ends, reset and go back to APPROACH
          if (this.bossStateTimer <= 0) {
            this.darkXochi.angle = 0;
            this.darkXochi.setTint(0x220022); // Back to normal
            this.bossState = 'APPROACH';
            this.bossStateTimer = this.bossApproachTime / speedMult;
          }
          break;
      }
    }

    // ============ ANIMATE CLOUDS (DKC2 style parallax) ============
    if (this.clouds && this.clouds.length > 0) {
      const camX = this.cameras.main.scrollX;
      this.clouds.forEach(c => {
        // Move cloud slowly across screen
        c.baseX += c.speed * (delta / 16);

        // Wrap cloud when it goes off screen
        if (c.baseX > this.levelData.width + 200) {
          c.baseX = -200;
        }

        // Apply parallax based on camera position
        const parallax = c.near ? 0.3 : 0.1;
        const cloudX = c.baseX - camX * parallax;

        // Update all parts of the cloud
        if (c.shadow) c.shadow.setX(cloudX + 3);
        if (c.cloud) c.cloud.setX(cloudX);
        if (c.highlight) c.highlight.setX(cloudX - 5);
        if (c.puff1) c.puff1.setX(cloudX - 15);
        if (c.puff2) c.puff2.setX(cloudX + 15);
      });
    }

    // ============ PIECE 5: ANIMATE WORLD-SPECIFIC PARTICLES ============
    // Update all atmospheric particles based on their type
    updateWorldParticles(this.particles, time, delta, this.levelData.width, this.levelData.height);

    // ============ TRAJINERA (BOAT) MOVEMENT - Xochimilco Level ============
    // V3: POV perspective with depth/scale, visual bobbing separate from physics
    if (this.trajineras && this.trajineras.length > 0) {
      const dt = delta / 1000;  // Convert to seconds

      this.trajineras.forEach(traj => {
        // Move the boat horizontally
        traj.x += traj.speed * traj.dir * dt;

        // Wrap around when going off screen
        if (traj.dir > 0 && traj.x > traj.maxX) {
          traj.x = traj.minX;
        } else if (traj.dir < 0 && traj.x < traj.minX) {
          traj.x = traj.maxX;
        }

        // ========== VISUAL BOBBING ANIMATION (sprite only, hitbox stays stable!) ==========
        // Gentle +/- 4 pixels on sine wave (2s period) - per spec
        const bobPeriod = traj.bobPeriod || 2.0;  // 2 second period
        const bobAmplitude = traj.bobAmplitude || 4;  // +/- 4 pixels
        traj.bobPhase = (traj.bobPhase || 0) + (dt * Math.PI * 2 / bobPeriod);
        const visualBobOffset = Math.sin(traj.bobPhase) * bobAmplitude;

        // ========== LANDING DIP SPRING ANIMATION ==========
        // When player lands, boat dips 3-4px then springs back (0.2s)
        const wasOnBoat = traj.playerOnBoat || false;
        const baseY = traj.baseY || traj.y;
        // Check against stable physics Y, not visual Y
        const playerOnBoat = (this.player.body.touching.down || this.player.body.blocked.down) &&
                             Math.abs(this.player.x - traj.x) < traj.w / 2 + 20 &&
                             Math.abs(this.player.y - (baseY - 25)) < 30;

        // Detect landing (wasn't on boat, now is)
        if (playerOnBoat && !wasOnBoat) {
          traj.dipVelocity = 25;  // Initial downward velocity for dip
        }
        traj.playerOnBoat = playerOnBoat;

        // Spring physics for dip recovery
        const dipTarget = 0;  // Spring back to no dip
        const dipSpring = 150;  // Spring stiffness
        const dipDamping = 12;  // Damping factor

        // Calculate spring force
        const dipForce = -dipSpring * (traj.dipAmount - dipTarget);
        const dampingForce = -dipDamping * traj.dipVelocity;
        traj.dipVelocity = (traj.dipVelocity || 0) + (dipForce + dampingForce) * dt;
        traj.dipAmount = (traj.dipAmount || 0) + traj.dipVelocity * dt;

        // Clamp dip to reasonable range
        traj.dipAmount = Math.max(-1, Math.min(4, traj.dipAmount));

        // ========== SEPARATE VISUAL vs PHYSICS POSITIONS ==========
        // Visual Y: base + bob + dip (for the sprite)
        traj.visualY = baseY + visualBobOffset + traj.dipAmount;
        // Physics Y: base only (stable hitbox for player collision)
        traj.y = baseY;

        // Update visual position (sprite bobs independently)
        traj.container.setPosition(traj.x, traj.visualY);

        // Update physics body position (STABLE - no bob, just horizontal movement)
        traj.platform.x = traj.x;
        traj.platform.y = baseY - 15;
        traj.platform.body.reset(traj.x, baseY - 15);

        // If player is on this boat, move them with it!
        if (playerOnBoat) {
          this.player.x += traj.speed * traj.dir * dt;
        }
      });
    }

    // ============ RISING WATER - DKC2 Style with Swimming! ============
    if (this.isUpscroller && this.risingWaterY !== undefined) {
      const dt = delta / 1000;

      // Water rises constantly
      this.risingWaterY -= this.risingWaterSpeed * dt;

      // Draw rising water relative to camera
      const camY = this.cameras.main.scrollY;
      const screenWaterY = this.risingWaterY - camY;
      const camHeight = this.cameras.main.height;

      this.risingWaterGraphics.clear();
      if (screenWaterY < camHeight + 100) {
        // Water surface
        this.risingWaterGraphics.fillStyle(0x2299aa, 0.85);
        this.risingWaterGraphics.fillRect(0, screenWaterY, this.levelData.width, camHeight - screenWaterY + 200);

        // Foamy top edge
        this.risingWaterGraphics.fillStyle(0x66ddff, 0.6);
        this.risingWaterGraphics.fillRect(0, screenWaterY - 8, this.levelData.width, 12);

        // Bubbles animation
        for (let bx = 0; bx < this.levelData.width; bx += 50) {
          const bubbleY = screenWaterY + Math.sin(time / 200 + bx) * 5;
          this.risingWaterGraphics.fillStyle(0xaaeeff, 0.4);
          this.risingWaterGraphics.fillCircle(bx + Math.sin(time / 300 + bx) * 10, bubbleY + 15, 4);
        }
      }

      // ============ SWIMMING MECHANICS - DKC2 Style! ============
      // X = stroke swim in direction you're pressing (smooth and continuous)
      const isInWater = this.player.y > this.risingWaterY - 10;
      const wasInWater = this.player.getData('swimming') || false;

      if (isInWater) {
        // ENTER WATER - can swim!
        if (!wasInWater) {
          this.player.setData('swimming', true);
          this.player.setData('swimCooldown', 0);
          this.player.setTint(0x66aacc);
          this.showText(this.player.x, this.player.y - 30, 'SWIM!', '#66ddff');
        }

        // Swimming physics - smooth water feel with gentle buoyancy
        this.player.body.setGravityY(-400);  // Gentle buoyancy
        this.player.body.setDragX(100);  // Less drag for smoother movement
        this.player.body.setDragY(100);

        // Update swim cooldown
        const swimCooldown = this.player.getData('swimCooldown') || 0;
        if (swimCooldown > 0) {
          this.player.setData('swimCooldown', swimCooldown - dt);
        }

        // DKC2 STYLE: X + Direction = swim in that direction!
        // Direction keys directly control swim direction (like DKC2)
        let swimDirX = 0;
        let swimDirY = 0;

        if (this.cursors.left.isDown || this.keys.A.isDown) {
          swimDirX = -1;
          this.player.setFlipX(true);
        } else if (this.cursors.right.isDown || this.keys.D.isDown) {
          swimDirX = 1;
          this.player.setFlipX(false);
        }
        if (this.cursors.up.isDown || this.keys.W.isDown) {
          swimDirY = -1;
        } else if (this.cursors.down.isDown || this.keys.S.isDown) {
          swimDirY = 1;
        }

        // X BUTTON = SWIM STROKE (DKC2 style - press X to swim!)
        const swimSpeed = 280;  // Smooth swim speed
        const canSwim = (this.player.getData('swimCooldown') || 0) <= 0;

        // HOLD X to swim continuously in pressed direction!
        if (this.keys.X.isDown) {
          // If no direction pressed, swim forward in facing direction
          if (swimDirX === 0 && swimDirY === 0) {
            swimDirX = this.player.flipX ? -1 : 1;
          }

          // Normalize diagonal movement
          const mag = Math.sqrt(swimDirX * swimDirX + swimDirY * swimDirY);
          if (mag > 0) {
            swimDirX /= mag;
            swimDirY /= mag;
          }

          // Apply smooth swimming velocity (additive for momentum)
          const currentVelX = this.player.body.velocity.x;
          const currentVelY = this.player.body.velocity.y;
          const targetVelX = swimSpeed * swimDirX;
          const targetVelY = swimSpeed * swimDirY;

          // Smooth interpolation for fluid movement
          this.player.body.setVelocityX(currentVelX + (targetVelX - currentVelX) * 0.15);
          this.player.body.setVelocityY(currentVelY + (targetVelY - currentVelY) * 0.15);

          // Bubble trail when swimming
          if (canSwim && Math.random() < 0.3) {
            const bubble = this.add.circle(
              this.player.x - swimDirX * 15 + (Math.random() - 0.5) * 10,
              this.player.y + (Math.random() - 0.5) * 15,
              3 + Math.random() * 3,
              0xaaeeff, 0.7
            );
            this.tweens.add({
              targets: bubble,
              y: bubble.y - 30,
              alpha: 0,
              scale: 0.3,
              duration: 500,
              onComplete: () => bubble.destroy()
            });
          }
        }

        // Ambient bubble trail when swimming
        if (Math.random() < 0.15) {
          const bubble = this.add.circle(
            this.player.x + (Math.random() - 0.5) * 20,
            this.player.y + 10,
            2 + Math.random() * 2,
            0xaaeeff, 0.5
          );
          this.tweens.add({
            targets: bubble,
            y: bubble.y - 40,
            alpha: 0,
            duration: 800,
            onComplete: () => bubble.destroy()
          });
        }

        // Die if too deep below the water (can't escape)
        if (this.player.y > this.risingWaterY + 150) {
          this.showText(this.player.x, this.player.y - 30, 'TOO DEEP!', '#ff4444');
          this.playerDie();
          return;
        }

      } else if (wasInWater) {
        // EXIT WATER - restore normal physics
        this.player.setData('swimming', false);
        this.player.setData('swimCooldown', 0);
        this.player.setData('swimVertical', 0);
        this.player.clearTint();
        this.player.body.setGravityY(0);  // Reset to world gravity
        this.player.body.setDragX(0);
        this.player.body.setDragY(0);

        // Boost out of water!
        if (this.player.body.velocity.y < 0) {
          this.player.body.setVelocityY(this.player.body.velocity.y * 1.3);
        }
      }

      // Update warning line
      const waterProximity = Math.max(0, Math.min(1, (camHeight - screenWaterY) / camHeight));
      this.waterWarningLine.setAlpha(0.3 + waterProximity * 0.5);

      // ============ ALLIGATOR ENEMIES IN WATER ============
      if (this.alligators) {
        this.alligators.children.iterate(gator => {
          if (!gator || !gator.active) return;

          // Alligators swim horizontally in the water
          const gatorY = gator.getData('baseY') + this.risingWaterY;
          gator.y = gatorY + Math.sin(time / 500 + gator.x) * 10;

          // Keep alligators in water bounds
          if (gator.x < 30 || gator.x > this.levelData.width - 30) {
            gator.setData('dir', gator.getData('dir') * -1);
          }
          gator.body.setVelocityX(gator.getData('speed') * gator.getData('dir'));
          gator.setFlipX(gator.getData('dir') > 0);

          // Check collision with swimming player
          if (isInWater && Phaser.Math.Distance.Between(this.player.x, this.player.y, gator.x, gator.y) < 35) {
            if (!this.player.getData('invincible')) {
              this.showText(this.player.x, this.player.y - 30, 'CHOMP!', '#ff0000');
              this.playerDie();
            }
          }
        });
      }
    }

    // ============ ESCAPE LEVEL - Chasing Flood! Indiana Jones style! ============
    if (this.isEscapeLevel && this.chasingFloodX !== undefined) {
      const dt = delta / 1000;

      // Flood advances from the left - RUN OR DIE!
      this.chasingFloodX += this.floodSpeed * dt;

      // Draw chasing flood relative to camera
      const camX = this.cameras.main.scrollX;
      const screenFloodX = this.chasingFloodX - camX;
      const camWidth = this.cameras.main.width;
      const camHeight = this.cameras.main.height;

      this.floodGraphics.clear();

      // Only draw if flood is visible on screen
      if (screenFloodX > -200) {
        // Main flood wall - towering wave!
        this.floodGraphics.fillStyle(0x1166aa, 0.9);
        this.floodGraphics.fillRect(0, 0, Math.max(0, screenFloodX + 50), camHeight);

        // Foamy edge of the wave
        this.floodGraphics.fillStyle(0x66ccff, 0.8);
        this.floodGraphics.fillRect(screenFloodX + 30, 0, 30, camHeight);

        // Spray particles at the top of the wave
        this.floodGraphics.fillStyle(0xaaeeff, 0.6);
        for (let sy = 0; sy < camHeight; sy += 40) {
          const sprayX = screenFloodX + 50 + Math.sin(time / 100 + sy) * 20;
          this.floodGraphics.fillCircle(sprayX, sy + Math.cos(time / 150 + sy) * 10, 6);
          this.floodGraphics.fillCircle(sprayX + 15, sy + 20 + Math.sin(time / 120 + sy) * 8, 4);
        }

        // Wave crest effect
        this.floodGraphics.fillStyle(0x88ddff, 0.7);
        for (let wy = 0; wy < camHeight; wy += 60) {
          const waveX = screenFloodX + 45 + Math.sin(time / 80 + wy * 0.1) * 15;
          this.floodGraphics.fillTriangle(
            waveX, wy,
            waveX + 25, wy + 30,
            waveX, wy + 60
          );
        }
      }

      // Did the flood catch the player?
      if (this.player.x < this.chasingFloodX + 30) {
        this.showText(this.player.x, this.player.y - 30, 'CAUGHT!', '#4488ff');
        this.playerDie();
        return;
      }

      // Update warning indicator intensity based on how close flood is
      const floodProximity = Math.max(0, Math.min(1, screenFloodX / 150));
      if (this.floodWarning) {
        this.floodWarning.setAlpha(0.3 + floodProximity * 0.6);
        this.floodWarning.setFillStyle(floodProximity > 0.5 ? 0xff0000 : 0xffaa00);
      }

      // Player also dies if they fall in regular water
      if (this.player.y > this.levelData.waterY - 10) {
        this.showText(this.player.x, this.player.y - 30, 'SPLASH!', '#00aaff');
        this.playerDie();
        return;
      }
    }

    // ============ WATER DEATH - Xochimilco Level (non-upscroller, non-escape) ============
    if (this.isWaterLevel && !this.isUpscroller && !this.isEscapeLevel && this.player.y > this.waterY - 10) {
      // Player touched the water! Instant death!
      this.showText(this.player.x, this.player.y - 30, 'SPLASH!', '#00aaff');
      this.playerDie();
      return;  // Don't process further
    }

    // Fall death (normal levels)
    if (this.player.y > this.levelData.height + 50) {
      this.playerDie();
    }
  }
}

// ============== UI SCENE ==============
class UIScene extends Phaser.Scene {
  constructor() { super('UIScene'); }
  init(data) { this.levelNum = data.levelNum; }

  create() {
    const { width } = this.cameras.main;
    this.add.rectangle(width/2, 25, width, 50, 0x000000, 0.6);

    // Score display (top left)
    this.scoreText = this.add.text(15, 12, `SCORE: ${gameState.score}`, { fontFamily: 'Arial Black', fontSize: '14px', color: '#ffdd00' });
    this.livesText = this.add.text(15, 32, `Lives: ${gameState.lives}`, { fontFamily: 'Arial', fontSize: '11px', color: '#fff' });

    // Flowers & Elotes (Mexican cultural items!)
    this.flowersText = this.add.text(130, 12, `Flores: ${gameState.flowers}`, { fontFamily: 'Arial', fontSize: '11px', color: '#ff8c00' });
    this.elotesText = this.add.text(130, 32, `Elotes: ${gameState.stars.length}/30`, { fontFamily: 'Arial', fontSize: '11px', color: '#ffd700' });

    // Double Jump counter (cyan) - shows how many mid-air jumps you have
    this.superJumpText = this.add.text(230, 12, `Jumps: ${gameState.superJumps}`, { fontFamily: 'Arial', fontSize: '11px', color: '#00ffff' });
    this.add.text(230, 32, 'double jump', { fontFamily: 'Arial', fontSize: '9px', color: '#00aaaa' });

    // Thunder attack counter (yellow)
    this.maceText = this.add.text(320, 12, `Thunder: ${gameState.maceAttacks}`, { fontFamily: 'Arial', fontSize: '11px', color: '#ffff00' });
    this.add.text(320, 32, '[Z] key', { fontFamily: 'Arial', fontSize: '9px', color: '#aaaa00' });

    // Level names with World indicators - LEARN each world!
    // World 1: Canal Dawn (1-2), World 2: Trajineras (3-4), World 3: Crystal Cave (5)
    // World 4: Floating Gardens (6-7), World 5: Night Canals (8-9), World 6: La Fiesta (10)
    const names = [
      'Canal Dawn 1',         // World 1
      'Canal Dawn 2',         // World 1
      'Trajineras 1',         // World 2 - Frogger
      'Trajineras 2',         // World 2 - Upscroller
      'Crystal Cave',         // World 3 - BOSS
      'Floating Gardens 1',   // World 4
      'Floating Gardens 2',   // World 4
      'Night Canals 1',       // World 5 - Upscroller
      'Night Canals 2',       // World 5 - Frogger
      'La Fiesta Final'       // World 6 - FINAL BOSS
    ];
    this.add.text(width/2, 22, names[this.levelNum-1] || `Level ${this.levelNum}`, { fontFamily: 'Arial', fontSize: '14px', color: '#4ecdc4' }).setOrigin(0.5);

    this.add.text(width - 15, 22, `Rescued: ${gameState.rescuedBabies.length}/11`, { fontFamily: 'Arial', fontSize: '11px', color: '#ff6b9d' }).setOrigin(1, 0.5);

    const game = this.scene.get('GameScene');
    game.events.on('updateUI', () => {
      this.scoreText.setText(`SCORE: ${gameState.score}`);
      this.livesText.setText(`Lives: ${gameState.lives}`);
      this.flowersText.setText(`Flores: ${gameState.flowers}`);
      this.elotesText.setText(`Elotes: ${gameState.stars.length}/30`);
      this.superJumpText.setText(`Jumps: ${gameState.superJumps}`);
      this.maceText.setText(`Thunder: ${gameState.maceAttacks}`);
    });
  }
}

// ============== PAUSE SCENE ==============
class PauseScene extends Phaser.Scene {
  constructor() { super('PauseScene'); }

  create() {
    const { width, height } = this.cameras.main;
    this.add.rectangle(width/2, height/2, width, height, 0x000000, 0.8);
    this.add.text(width/2, 100, 'PAUSED', { fontFamily: 'Arial Black', fontSize: '48px', color: '#4ecdc4' }).setOrigin(0.5);

    this.makeButton(width/2, 200, 'RESUME', 0x4ecdc4, () => { this.scene.resume('GameScene'); this.scene.stop(); });
    this.makeButton(width/2, 260, 'RESTART', 0xffaa00, () => { this.scene.stop('GameScene'); this.scene.stop('UIScene'); this.scene.stop(); this.scene.start('GameScene', {level: gameState.currentLevel}); });
    this.makeButton(width/2, 320, 'MENU', 0xff6666, () => { mariachiMusic.stop(); this.scene.stop('GameScene'); this.scene.stop('UIScene'); this.scene.stop(); this.scene.start('MenuScene'); });

    // ============ WORLD SELECTION ============
    this.add.text(width/2, 380, 'JUMP TO WORLD', {
      fontFamily: 'Arial Black', fontSize: '14px', color: '#aaaaaa'
    }).setOrigin(0.5);

    const worldData = [
      { num: 1, icon: '🌅', name: 'Dawn', color: 0xffaa77 },
      { num: 2, icon: '☀️', name: 'Day', color: 0x55ccee },
      { num: 3, icon: '💎', name: 'Cave', color: 0x4466aa },
      { num: 4, icon: '🌸', name: 'Garden', color: 0xffcc44 },
      { num: 5, icon: '🌙', name: 'Night', color: 0x6644aa },
      { num: 6, icon: '🎉', name: 'Fiesta', color: 0x44ccaa }
    ];

    const btnSize = 48;
    const worldStartX = width/2 - (worldData.length * btnSize) / 2 + btnSize/2;

    worldData.forEach((world, i) => {
      const x = worldStartX + i * btnSize;
      const y = 430;
      const firstLevel = getFirstLevelOfWorld(world.num);
      const isUnlocked = gameState.currentLevel >= firstLevel || firstLevel === 1;
      const isCurrent = getWorldForLevel(gameState.currentLevel) === world.num;

      // Button background
      const btnBg = this.add.rectangle(x, y, btnSize - 4, btnSize - 4,
        isUnlocked ? world.color : 0x333333, isUnlocked ? 1 : 0.5);

      // Current world indicator (white border)
      if (isCurrent) {
        this.add.rectangle(x, y, btnSize, btnSize, 0xffffff).setDepth(-1);
      }

      // Icon
      this.add.text(x, y - 5, world.icon, {
        fontSize: '20px'
      }).setOrigin(0.5);

      // World number
      this.add.text(x, y + 14, world.num.toString(), {
        fontFamily: 'Arial Black', fontSize: '10px',
        color: isUnlocked ? '#ffffff' : '#666666'
      }).setOrigin(0.5);

      // Make clickable if unlocked
      if (isUnlocked) {
        btnBg.setInteractive({ useHandCursor: true });
        btnBg.on('pointerover', () => btnBg.setScale(1.15));
        btnBg.on('pointerout', () => btnBg.setScale(1));
        btnBg.on('pointerdown', () => {
          gameState.currentLevel = firstLevel;
          this.scene.stop('GameScene');
          this.scene.stop('UIScene');
          this.scene.stop();
          this.scene.start('GameScene', { level: firstLevel });
        });
      }
    });

    // World name tooltip area
    this.add.text(width/2, 470, 'Click a world to jump there', {
      fontFamily: 'Arial', fontSize: '11px', color: '#666666'
    }).setOrigin(0.5);

    this.input.keyboard.on('keydown-ESC', () => { this.scene.resume('GameScene'); this.scene.stop(); });
  }

  makeButton(x, y, text, color, fn) {
    const btn = this.add.rectangle(x, y, 160, 40, color).setInteractive({ useHandCursor: true });
    this.add.text(x, y, text, { fontFamily: 'Arial Black', fontSize: '18px', color: '#fff' }).setOrigin(0.5);
    btn.on('pointerover', () => btn.setScale(1.1));
    btn.on('pointerout', () => btn.setScale(1));
    btn.on('pointerdown', fn);
  }
}

// ============== END SCENE ==============
class EndScene extends Phaser.Scene {
  constructor() { super('EndScene'); }

  create() {
    const { width, height } = this.cameras.main;
    this.cameras.main.setBackgroundColor('#1a1a2e');

    // Update high score
    if (gameState.score > gameState.highScore) {
      gameState.highScore = gameState.score;
      saveGame();
    }

    // Confetti
    for (let i = 0; i < 50; i++) {
      const c = this.add.rectangle(Phaser.Math.Between(0,width), -20, Phaser.Math.Between(5,12), Phaser.Math.Between(5,12),
        [0xff6b9d, 0x4ecdc4, 0xffdd00, 0xff6666, 0x00ffff][Phaser.Math.Between(0,4)]);
      this.tweens.add({
        targets: c, y: height + 50, x: `+=${Phaser.Math.Between(-80,80)}`, angle: 720,
        duration: Phaser.Math.Between(2000,4000), delay: Phaser.Math.Between(0,1500), repeat: -1,
        onRepeat: () => { c.x = Phaser.Math.Between(0,width); c.y = -20; }
      });
    }

    this.add.text(width/2, 50, 'CONGRATULATIONS!', { fontFamily: 'Arial Black', fontSize: '32px', color: '#ffdd00', stroke: '#ff6b9d', strokeThickness: 4 }).setOrigin(0.5);
    this.add.text(width/2, 90, 'All 10 Baby Axolotls Rescued!', { fontFamily: 'Arial', fontSize: '18px', color: '#4ecdc4' }).setOrigin(0.5);

    // FINAL SCORE
    this.add.rectangle(width/2, 140, 280, 50, 0x000000, 0.6);
    this.add.text(width/2, 130, `FINAL SCORE: ${gameState.score}`, { fontFamily: 'Arial Black', fontSize: '22px', color: '#ffdd00' }).setOrigin(0.5);
    this.add.text(width/2, 155, `HIGH SCORE: ${gameState.highScore}`, { fontFamily: 'Arial', fontSize: '14px', color: '#ff6b9d' }).setOrigin(0.5);

    // Babies (10 of them in 2 rows)
    for (let i = 0; i < 10; i++) {
      const row = Math.floor(i / 5);
      const col = i % 5;
      const b = this.add.sprite(width/2 - 80 + col*40, 200 + row*30, 'baby').setScale(1.5);
      this.tweens.add({ targets: b, y: b.y - 5, duration: 400, yoyo: true, repeat: -1, delay: i * 60 });
    }

    // Xochi
    const x = this.add.sprite(width/2, 300, 'xochi_walk').setScale(0.30);
    this.tweens.add({ targets: x, y: 285, duration: 800, yoyo: true, repeat: -1, ease: 'Sine.easeInOut' });

    // Stats
    this.add.text(width/2, 370, `Elotes: ${gameState.stars.length}/30`, { fontFamily: 'Arial', fontSize: '16px', color: '#ffd700' }).setOrigin(0.5);
    this.add.text(width/2, 395, `Flores Collected: ${gameState.flowers + (gameState.rescuedBabies.length * 10)}`, { fontFamily: 'Arial', fontSize: '14px', color: '#ff8c00' }).setOrigin(0.5);

    this.add.text(width/2, 440, 'A gift made with love!', { fontFamily: 'Arial', fontSize: '14px', color: '#ff6b9d' }).setOrigin(0.5);

    this.makeButton(width/2 - 90, 500, 'PLAY AGAIN', 0x4ecdc4, () => {
      resetGame();
      this.scene.start('GameScene', { level: 1 });
    });
    this.makeButton(width/2 + 90, 500, 'MENU', 0xff6b9d, () => { mariachiMusic.stop(); this.scene.start('MenuScene'); });
  }

  makeButton(x, y, text, color, fn) {
    const btn = this.add.rectangle(x, y, 130, 36, color).setInteractive({ useHandCursor: true });
    this.add.text(x, y, text, { fontFamily: 'Arial Black', fontSize: '14px', color: '#fff' }).setOrigin(0.5);
    btn.on('pointerover', () => btn.setScale(1.1));
    btn.on('pointerout', () => btn.setScale(1));
    btn.on('pointerdown', fn);
  }
}

// ============== START GAME ==============
const config = {
  type: Phaser.AUTO,
  parent: 'game-container',
  width: 800,
  height: 600,
  backgroundColor: '#1a1a2e',
  physics: {
    default: 'arcade',
    arcade: { gravity: { y: 900 }, debug: false }
  },
  scale: {
    mode: Phaser.Scale.FIT,
    autoCenter: Phaser.Scale.CENTER_BOTH,
    parent: 'game-container',
    width: 800,
    height: 600,
    min: { width: 320, height: 240 },
    max: { width: 1600, height: 1200 }
  },
  scene: [BootScene, MenuScene, GameScene, UIScene, PauseScene, EndScene]
};

new Phaser.Game(config);

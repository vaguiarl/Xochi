// Level data for all levels
// Enhanced with world themes, trajineras, and procedural generation support

const TILE_SIZE = 32;

// World themes with visual settings
export const WORLDS = {
  1: {
    worldNum: 1,
    name: 'Canal Dawn',
    subtitle: 'El Amanecer',
    sky: [0xffccaa, 0xffaa88, 0xff8866, 0xcc6655, 0x884444, 0x442233],
    platformColor: 0x44aa55,
    grassColor: 0x66cc77,
    groundColor: 0x8B5522,
    groundTopColor: 0x55aa44,
    waterColor: 0x2299aa
  },
  2: {
    worldNum: 2,
    name: 'Bright Trajineras',
    subtitle: 'Trajineras Brillantes',
    sky: [0x87ceeb, 0x77bedb, 0x67aecb, 0x579ebb, 0x478eab, 0x377e9b],
    platformColor: 0x55bb66,
    grassColor: 0x77dd88,
    groundColor: 0x9B6533,
    groundTopColor: 0x66bb55,
    waterColor: 0x22aacc
  },
  3: {
    worldNum: 3,
    name: 'Crystal Cave',
    subtitle: 'Cueva de Cristal',
    sky: [0x1a1a3e, 0x2a2a4e, 0x3a3a5e, 0x4a4a6e, 0x3a3a5e, 0x2a2a4e],
    platformColor: 0x5555aa,
    grassColor: 0x7777cc,
    groundColor: 0x444488,
    groundTopColor: 0x6666aa,
    waterColor: 0x334488
  },
  4: {
    worldNum: 4,
    name: 'Floating Gardens',
    subtitle: 'Jardines Flotantes',
    sky: [0xffdd88, 0xffcc66, 0xffbb44, 0xee9933, 0xcc7722, 0x995511],
    platformColor: 0x66aa44,
    grassColor: 0x88cc66,
    groundColor: 0x885522,
    groundTopColor: 0x77bb44,
    waterColor: 0x44aaaa
  },
  5: {
    worldNum: 5,
    name: 'Night Canals',
    subtitle: 'Canales de Noche',
    sky: [0x0a0a1e, 0x1a1a2e, 0x2a2a3e, 0x1a1a2e, 0x0a0a1e, 0x050510],
    platformColor: 0x4455aa,
    grassColor: 0x6677cc,
    groundColor: 0x333366,
    groundTopColor: 0x5566aa,
    waterColor: 0x223355
  },
  6: {
    worldNum: 6,
    name: 'The Grand Festival',
    subtitle: 'La Gran Fiesta',
    sky: [0x2a4a4a, 0x3a5a5a, 0x4a6a6a, 0x5a7a7a, 0x4a6a6a, 0x3a5a5a],
    platformColor: 0x44aaaa,
    grassColor: 0x66cccc,
    groundColor: 0x447788,
    groundTopColor: 0x55bbbb,
    waterColor: 0x33aacc
  }
};

// Trajinera boat names for flavor
const TRAJINERA_NAMES = [
  'Lupita', 'Rosa', 'Esperanza', 'Guadalupe', 'Maria',
  'Xochitl', 'Citlali', 'Itzel', 'Marisol', 'Elena'
];

// Level 1: Floating Gardens Tutorial
const level1 = {
  width: 2400,
  height: 600,
  playerSpawn: { x: 100, y: 400 },
  babyPosition: { x: 2200, y: 200 },

  platforms: [
    // Ground
    { x: 0, y: 550, w: 800, h: 50 },
    { x: 900, y: 550, w: 600, h: 50 },
    { x: 1600, y: 550, w: 800, h: 50 },
    // Platforms
    { x: 250, y: 450, w: 150, h: 20 },
    { x: 500, y: 380, w: 100, h: 20 },
    { x: 750, y: 320, w: 120, h: 20 },
    { x: 1100, y: 400, w: 150, h: 20 },
    { x: 1400, y: 320, w: 100, h: 20 },
    { x: 1700, y: 380, w: 150, h: 20 },
    { x: 1950, y: 280, w: 120, h: 20 },
    { x: 2150, y: 220, w: 150, h: 20 }
  ],

  trajineras: [
    { x: 850, y: 520, w: 100, h: 25, endX: 900, speed: 30, dir: 1 }
  ],

  coins: [
    { x: 200, y: 480 }, { x: 232, y: 480 }, { x: 264, y: 480 },
    { x: 320, y: 420 }, { x: 352, y: 420 },
    { x: 560, y: 340 }, { x: 592, y: 340 },
    { x: 800, y: 280 },
    { x: 1150, y: 360 }, { x: 1182, y: 360 },
    { x: 1450, y: 280 },
    { x: 1750, y: 340 }, { x: 1782, y: 340 },
    { x: 2000, y: 240 }, { x: 2032, y: 240 },
    { x: 2200, y: 180 }
  ],

  stars: [
    { x: 350, y: 350 },
    { x: 1150, y: 250 },
    { x: 2100, y: 160 }
  ],

  powerups: [
    { x: 600, y: 340 }
  ],

  enemies: [
    { type: 'ground', x: 500, y: 530 },
    { type: 'ground', x: 1200, y: 530 },
    { type: 'flying', x: 900, y: 400, amplitude: 50, speed: 60 },
    { type: 'ground', x: 1800, y: 530 }
  ]
};

// Level 2: Floating Gardens Advanced
const level2 = {
  width: 3000,
  height: 600,
  playerSpawn: { x: 100, y: 400 },
  babyPosition: { x: 2800, y: 150 },

  platforms: [
    // Ground with gaps
    { x: 0, y: 550, w: 700, h: 50 },
    { x: 800, y: 550, w: 500, h: 50 },
    { x: 1400, y: 550, w: 600, h: 50 },
    { x: 2100, y: 550, w: 900, h: 50 },
    // Platforms
    { x: 350, y: 450, w: 120, h: 20 },
    { x: 650, y: 380, w: 100, h: 20 },
    { x: 950, y: 320, w: 150, h: 20 },
    { x: 1250, y: 400, w: 100, h: 20 },
    { x: 1550, y: 320, w: 120, h: 20 },
    { x: 1850, y: 380, w: 100, h: 20 },
    { x: 2150, y: 300, w: 150, h: 20 },
    { x: 2500, y: 250, w: 120, h: 20 },
    { x: 2750, y: 180, w: 150, h: 20 }
  ],

  trajineras: [
    { x: 750, y: 520, w: 80, h: 25, endX: 800, speed: 40, dir: 1 },
    { x: 1350, y: 520, w: 80, h: 25, endX: 1400, speed: 35, dir: -1 }
  ],

  coins: [
    { x: 200, y: 480 }, { x: 232, y: 480 },
    { x: 400, y: 410 }, { x: 432, y: 410 },
    { x: 700, y: 340 }, { x: 732, y: 340 },
    { x: 1000, y: 280 }, { x: 1032, y: 280 },
    { x: 1300, y: 360 },
    { x: 1600, y: 280 }, { x: 1632, y: 280 },
    { x: 1900, y: 340 },
    { x: 2200, y: 260 }, { x: 2232, y: 260 },
    { x: 2550, y: 210 },
    { x: 2800, y: 140 }
  ],

  stars: [
    { x: 850, y: 200 },
    { x: 1650, y: 180 },
    { x: 2700, y: 120 }
  ],

  powerups: [
    { x: 500, y: 410 },
    { x: 1500, y: 280 }
  ],

  enemies: [
    { type: 'ground', x: 350, y: 530 },
    { type: 'ground', x: 900, y: 530 },
    { type: 'flying', x: 650, y: 350, amplitude: 60, speed: 70 },
    { type: 'ground', x: 1500, y: 530 },
    { type: 'flying', x: 1800, y: 400, amplitude: 50, speed: 65 },
    { type: 'ground', x: 2300, y: 530 },
    { type: 'flying', x: 2600, y: 300, amplitude: 40, speed: 75 }
  ]
};

// Level 3: Upscroller - Ruins Entry
const level3 = {
  width: 800,
  height: 2000,
  playerSpawn: { x: 400, y: 1900 },
  babyPosition: { x: 400, y: 100 },
  isUpscroller: true,

  platforms: [
    // Bottom ground
    { x: 0, y: 1950, w: 800, h: 50 },
    // Ascending platforms
    { x: 100, y: 1800, w: 150, h: 20 },
    { x: 500, y: 1700, w: 150, h: 20 },
    { x: 200, y: 1600, w: 150, h: 20 },
    { x: 550, y: 1500, w: 150, h: 20 },
    { x: 100, y: 1400, w: 200, h: 20 },
    { x: 450, y: 1300, w: 150, h: 20 },
    { x: 200, y: 1200, w: 150, h: 20 },
    { x: 550, y: 1100, w: 150, h: 20 },
    { x: 100, y: 1000, w: 150, h: 20 },
    { x: 400, y: 900, w: 200, h: 20 },
    { x: 150, y: 800, w: 150, h: 20 },
    { x: 500, y: 700, w: 150, h: 20 },
    { x: 200, y: 600, w: 150, h: 20 },
    { x: 450, y: 500, w: 150, h: 20 },
    { x: 100, y: 400, w: 200, h: 20 },
    { x: 450, y: 300, w: 150, h: 20 },
    { x: 250, y: 200, w: 300, h: 20 },
    { x: 300, y: 100, w: 200, h: 20 }
  ],

  trajineras: [],

  coins: [
    { x: 175, y: 1760 }, { x: 575, y: 1660 },
    { x: 275, y: 1560 }, { x: 625, y: 1460 },
    { x: 200, y: 1360 }, { x: 525, y: 1260 },
    { x: 275, y: 1160 }, { x: 625, y: 1060 },
    { x: 175, y: 960 }, { x: 500, y: 860 },
    { x: 225, y: 760 }, { x: 575, y: 660 },
    { x: 275, y: 560 }, { x: 525, y: 460 },
    { x: 200, y: 360 }, { x: 525, y: 260 },
    { x: 400, y: 160 }
  ],

  stars: [
    { x: 700, y: 1400 },
    { x: 100, y: 800 },
    { x: 400, y: 150 }
  ],

  powerups: [
    { x: 200, y: 1560 },
    { x: 500, y: 860 }
  ],

  enemies: [
    { type: 'platform', x: 575, y: 1680 },
    { type: 'platform', x: 175, y: 1380 },
    { type: 'flying', x: 400, y: 1200, amplitude: 100, speed: 50 },
    { type: 'platform', x: 525, y: 880 },
    { type: 'flying', x: 350, y: 600, amplitude: 80, speed: 60 },
    { type: 'platform', x: 175, y: 380 }
  ]
};

// Level 4: Ancient Ruins
const level4 = {
  width: 3200,
  height: 700,
  playerSpawn: { x: 100, y: 500 },
  babyPosition: { x: 3000, y: 150 },

  platforms: [
    // Ground with gaps
    { x: 0, y: 650, w: 600, h: 50 },
    { x: 700, y: 650, w: 500, h: 50 },
    { x: 1300, y: 650, w: 500, h: 50 },
    { x: 1900, y: 650, w: 500, h: 50 },
    { x: 2500, y: 650, w: 700, h: 50 },
    // Platforms
    { x: 350, y: 550, w: 100, h: 20 },
    { x: 550, y: 480, w: 100, h: 20 },
    { x: 850, y: 550, w: 150, h: 20 },
    { x: 1100, y: 480, w: 100, h: 20 },
    { x: 1350, y: 400, w: 120, h: 20 },
    { x: 1600, y: 550, w: 100, h: 20 },
    { x: 1850, y: 480, w: 120, h: 20 },
    { x: 2100, y: 400, w: 100, h: 20 },
    { x: 2350, y: 550, w: 150, h: 20 },
    { x: 2600, y: 480, w: 100, h: 20 },
    { x: 2850, y: 400, w: 120, h: 20 },
    { x: 2950, y: 180, w: 150, h: 20 }
  ],

  trajineras: [
    { x: 650, y: 620, w: 80, h: 25, endX: 700, speed: 45, dir: 1 },
    { x: 1250, y: 620, w: 80, h: 25, endX: 1300, speed: 40, dir: -1 },
    { x: 1850, y: 620, w: 80, h: 25, endX: 1900, speed: 50, dir: 1 }
  ],

  coins: [
    { x: 250, y: 580 }, { x: 282, y: 580 },
    { x: 400, y: 510 }, { x: 600, y: 440 },
    { x: 925, y: 510 }, { x: 1150, y: 440 },
    { x: 1400, y: 360 }, { x: 1650, y: 510 },
    { x: 1900, y: 440 }, { x: 2150, y: 360 },
    { x: 2425, y: 510 }, { x: 2650, y: 440 },
    { x: 2900, y: 360 }, { x: 3000, y: 140 }
  ],

  stars: [
    { x: 550, y: 350 },
    { x: 1850, y: 280 },
    { x: 2900, y: 140 }
  ],

  powerups: [
    { x: 450, y: 580 },
    { x: 1500, y: 360 },
    { x: 2600, y: 440 }
  ],

  enemies: [
    { type: 'ground', x: 350, y: 630 },
    { type: 'flying', x: 700, y: 450, amplitude: 70, speed: 65 },
    { type: 'ground', x: 1000, y: 630 },
    { type: 'platform', x: 1400, y: 380 },
    { type: 'flying', x: 1650, y: 380, amplitude: 60, speed: 70 },
    { type: 'ground', x: 2200, y: 630 },
    { type: 'flying', x: 2500, y: 350, amplitude: 50, speed: 75 },
    { type: 'platform', x: 2900, y: 380 }
  ]
};

// Level 5: Crystal Cave Boss
const level5 = {
  width: 1200,
  height: 800,
  playerSpawn: { x: 100, y: 600 },
  babyPosition: { x: 1000, y: 200 },
  isBossLevel: true,

  platforms: [
    // Arena floor
    { x: 0, y: 750, w: 1200, h: 50 },
    // Side platforms
    { x: 100, y: 600, w: 150, h: 20 },
    { x: 500, y: 550, w: 200, h: 20 },
    { x: 950, y: 600, w: 150, h: 20 },
    // Higher platforms
    { x: 200, y: 450, w: 150, h: 20 },
    { x: 500, y: 400, w: 200, h: 20 },
    { x: 850, y: 450, w: 150, h: 20 },
    // Top platforms
    { x: 350, y: 300, w: 150, h: 20 },
    { x: 700, y: 300, w: 150, h: 20 },
    { x: 500, y: 200, w: 200, h: 20 },
    // Baby platform
    { x: 950, y: 220, w: 150, h: 20 }
  ],

  trajineras: [],

  coins: [
    { x: 175, y: 560 }, { x: 600, y: 510 },
    { x: 1025, y: 560 }, { x: 275, y: 410 },
    { x: 600, y: 360 }, { x: 925, y: 410 },
    { x: 425, y: 260 }, { x: 775, y: 260 },
    { x: 600, y: 160 }
  ],

  stars: [
    { x: 100, y: 400 },
    { x: 600, y: 150 },
    { x: 1100, y: 400 }
  ],

  powerups: [
    { x: 600, y: 510 },
    { x: 600, y: 160 }
  ],

  enemies: [
    { type: 'flying', x: 300, y: 500, amplitude: 80, speed: 60 },
    { type: 'flying', x: 900, y: 500, amplitude: 80, speed: 60 },
    { type: 'flying', x: 600, y: 300, amplitude: 100, speed: 70 }
  ]
};

// Additional levels (6-10) use procedural generation
const level6 = {
  width: 3000,
  height: 700,
  playerSpawn: { x: 100, y: 500 },
  babyPosition: { x: 2800, y: 200 },

  platforms: [
    { x: 0, y: 650, w: 500, h: 50 },
    { x: 600, y: 650, w: 400, h: 50 },
    { x: 1100, y: 650, w: 400, h: 50 },
    { x: 1600, y: 650, w: 400, h: 50 },
    { x: 2100, y: 650, w: 900, h: 50 },
    { x: 250, y: 550, w: 120, h: 20 },
    { x: 500, y: 480, w: 100, h: 20 },
    { x: 800, y: 550, w: 150, h: 20 },
    { x: 1050, y: 480, w: 100, h: 20 },
    { x: 1300, y: 400, w: 120, h: 20 },
    { x: 1550, y: 550, w: 100, h: 20 },
    { x: 1800, y: 480, w: 120, h: 20 },
    { x: 2050, y: 400, w: 100, h: 20 },
    { x: 2300, y: 320, w: 120, h: 20 },
    { x: 2550, y: 400, w: 100, h: 20 },
    { x: 2750, y: 250, w: 150, h: 20 }
  ],

  trajineras: [
    { x: 550, y: 620, w: 80, h: 25, endX: 600, speed: 40, dir: 1 },
    { x: 1050, y: 620, w: 80, h: 25, endX: 1100, speed: 45, dir: -1 },
    { x: 1550, y: 620, w: 80, h: 25, endX: 1600, speed: 50, dir: 1 }
  ],

  coins: [
    { x: 200, y: 580 }, { x: 350, y: 510 }, { x: 550, y: 440 },
    { x: 875, y: 510 }, { x: 1100, y: 440 }, { x: 1350, y: 360 },
    { x: 1600, y: 510 }, { x: 1850, y: 440 }, { x: 2100, y: 360 },
    { x: 2350, y: 280 }, { x: 2600, y: 360 }, { x: 2800, y: 210 }
  ],

  stars: [
    { x: 500, y: 350 },
    { x: 1300, y: 280 },
    { x: 2700, y: 180 }
  ],

  powerups: [
    { x: 400, y: 510 },
    { x: 1200, y: 440 },
    { x: 2200, y: 360 }
  ],

  enemies: [
    { type: 'ground', x: 300, y: 630 },
    { type: 'flying', x: 650, y: 450, amplitude: 60, speed: 70 },
    { type: 'ground', x: 950, y: 630 },
    { type: 'flying', x: 1200, y: 380, amplitude: 70, speed: 65 },
    { type: 'ground', x: 1450, y: 630 },
    { type: 'flying', x: 1700, y: 400, amplitude: 50, speed: 75 },
    { type: 'ground', x: 2000, y: 630 },
    { type: 'flying', x: 2400, y: 300, amplitude: 60, speed: 80 }
  ]
};

// Procedural level generation for levels 7-10
export function generateProceduralLevel(levelNum, options = {}) {
  const worldNum = window.getWorldForLevel ? window.getWorldForLevel(levelNum) : Math.ceil(levelNum / 2);
  const theme = WORLDS[worldNum] || WORLDS[1];

  const baseWidth = 2800 + (levelNum - 6) * 400;
  const baseHeight = 700 + (levelNum > 8 ? 100 : 0);

  const platforms = [];
  const coins = [];
  const stars = [];
  const powerups = [];
  const enemies = [];
  const trajineras = [];

  // Ground segments with gaps
  let groundX = 0;
  const groundY = baseHeight - 50;
  const groundH = 50;
  const numGroundSegments = 5 + Math.floor(levelNum / 2);

  for (let i = 0; i < numGroundSegments; i++) {
    const segmentWidth = 300 + Math.random() * 300;
    platforms.push({ x: groundX, y: groundY, w: segmentWidth, h: groundH });
    groundX += segmentWidth + 100 + Math.random() * 100; // Gap
  }
  // Final segment to end
  platforms.push({ x: groundX, y: groundY, w: baseWidth - groundX, h: groundH });

  // Floating platforms
  const numPlatforms = 12 + levelNum;
  for (let i = 0; i < numPlatforms; i++) {
    const px = 200 + (i / numPlatforms) * (baseWidth - 400);
    const py = 250 + Math.random() * 350;
    const pw = 80 + Math.random() * 80;
    platforms.push({ x: px, y: py, w: pw, h: 20 });
  }

  // Trajineras for water levels
  const numTrajineras = Math.min(5, Math.floor(levelNum / 2));
  for (let i = 0; i < numTrajineras; i++) {
    const tx = 500 + i * 500;
    trajineras.push({
      x: tx,
      y: groundY - 30,
      w: 80 + Math.random() * 40,
      h: 25,
      endX: tx + 100 + Math.random() * 100,
      speed: 30 + Math.random() * 30,
      dir: Math.random() > 0.5 ? 1 : -1
    });
  }

  // Coins scattered along the level
  for (let i = 0; i < 15 + levelNum; i++) {
    coins.push({
      x: 150 + (i / (15 + levelNum)) * (baseWidth - 300),
      y: 200 + Math.random() * 400
    });
  }

  // Stars (3 per level)
  stars.push({ x: baseWidth * 0.25, y: 180 + Math.random() * 150 });
  stars.push({ x: baseWidth * 0.5, y: 180 + Math.random() * 150 });
  stars.push({ x: baseWidth * 0.8, y: 180 + Math.random() * 150 });

  // Power-ups
  const numPowerups = 2 + Math.floor(levelNum / 3);
  for (let i = 0; i < numPowerups; i++) {
    powerups.push({
      x: 300 + i * (baseWidth / numPowerups),
      y: 250 + Math.random() * 300
    });
  }

  // Enemies
  const numEnemies = 6 + levelNum;
  for (let i = 0; i < numEnemies; i++) {
    const ex = 250 + (i / numEnemies) * (baseWidth - 500);
    const isFlying = Math.random() > 0.6;
    enemies.push({
      type: isFlying ? 'flying' : 'ground',
      x: ex,
      y: isFlying ? 300 + Math.random() * 200 : groundY - 20,
      amplitude: isFlying ? 50 + Math.random() * 50 : undefined,
      speed: isFlying ? 60 + Math.random() * 30 : undefined
    });
  }

  return {
    width: baseWidth,
    height: baseHeight,
    playerSpawn: { x: 100, y: groundY - 100 },
    babyPosition: { x: baseWidth - 200, y: 200 },
    platforms,
    trajineras,
    coins,
    stars,
    powerups,
    enemies,
    theme,
    isUpscroller: options.isUpscroller,
    isEscape: options.isEscape,
    isBossLevel: options.isBoss
  };
}

export const LEVELS = [level1, level2, level3, level4, level5, level6];

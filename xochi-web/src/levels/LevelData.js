// Level data for all 5 levels
// Each level is a 2D array of tile indices
// 0 = empty, 1 = ground, 2 = brick, 3 = platform, etc.

const TILE_SIZE = 32;

// Helper to create ground row
const ground = (width) => Array(width).fill(1);
const empty = (width) => Array(width).fill(0);
const platform = (start, length, row, height = 1) => {
  const result = [];
  for (let y = 0; y < height; y++) {
    for (let x = start; x < start + length; x++) {
      result.push({ x: x * TILE_SIZE, y: row * TILE_SIZE, tile: 1 });
    }
  }
  return result;
};

// Level 1-1: Floating Gardens Tutorial
// Easy intro level - simple jumps, few enemies
const level1 = {
  width: 2400,
  height: 600,
  playerSpawn: { x: 100, y: 400 },
  babyPosition: { x: 2200, y: 200 },

  // Tile map (simplified - just ground and platforms)
  tiles: (() => {
    const rows = 19; // 600 / 32
    const cols = 75; // 2400 / 32
    const map = [];

    for (let y = 0; y < rows; y++) {
      const row = [];
      for (let x = 0; x < cols; x++) {
        if (y >= 17) {
          // Ground (bottom 2 rows)
          row.push(1);
        } else if (y === 14 && x >= 8 && x <= 11) {
          // First platform
          row.push(3);
        } else if (y === 12 && x >= 16 && x <= 18) {
          // Second platform (higher)
          row.push(3);
        } else if (y === 14 && x >= 24 && x <= 28) {
          // Long platform
          row.push(3);
        } else if (y === 10 && x >= 35 && x <= 38) {
          // High platform
          row.push(3);
        } else if (y === 14 && x >= 45 && x <= 52) {
          // Near end platform
          row.push(3);
        } else if (y === 11 && x >= 58 && x <= 62) {
          // Final approach
          row.push(3);
        } else if (y === 8 && x >= 65 && x <= 70) {
          // Baby platform
          row.push(3);
        } else {
          row.push(0);
        }
      }
      map.push(row);
    }
    return map;
  })(),

  coins: [
    { x: 200, y: 480 }, { x: 232, y: 480 }, { x: 264, y: 480 },
    { x: 320, y: 420 }, { x: 352, y: 420 },
    { x: 560, y: 380 }, { x: 592, y: 380 },
    { x: 800, y: 320 },
    { x: 1200, y: 420 }, { x: 1232, y: 420 }, { x: 1264, y: 420 },
    { x: 1500, y: 280 },
    { x: 1800, y: 420 }, { x: 1832, y: 420 },
    { x: 2000, y: 320 }, { x: 2032, y: 320 }
  ],

  stars: [
    { x: 350, y: 350 },  // Hidden above first platform
    { x: 1150, y: 250 }, // High jump required
    { x: 2100, y: 200 }  // Near baby
  ],

  mushrooms: [
    { x: 600, y: 480 }
  ],

  enemies: [
    { type: 'gull', x: 500, y: 500 },
    { type: 'gull', x: 900, y: 500 },
    { type: 'gull', x: 1400, y: 500 },
    { type: 'heron', x: 1700, y: 480 }
  ]
};

// Level 1-2: Floating Gardens Challenge
// More platforms, more enemies
const level2 = {
  width: 3000,
  height: 600,
  playerSpawn: { x: 100, y: 400 },
  babyPosition: { x: 2800, y: 150 },

  tiles: (() => {
    const rows = 19;
    const cols = 94;
    const map = [];

    for (let y = 0; y < rows; y++) {
      const row = [];
      for (let x = 0; x < cols; x++) {
        if (y >= 17) {
          // Ground with gaps
          if ((x >= 25 && x <= 28) || (x >= 50 && x <= 53) || (x >= 75 && x <= 78)) {
            row.push(0); // Gaps
          } else {
            row.push(1);
          }
        } else if (y === 14 && ((x >= 10 && x <= 14) || (x >= 30 && x <= 35) || (x >= 55 && x <= 60))) {
          row.push(3);
        } else if (y === 11 && ((x >= 20 && x <= 23) || (x >= 42 && x <= 46) || (x >= 65 && x <= 70))) {
          row.push(3);
        } else if (y === 8 && x >= 80 && x <= 90) {
          row.push(3);
        } else {
          row.push(0);
        }
      }
      map.push(row);
    }
    return map;
  })(),

  coins: [
    { x: 200, y: 480 }, { x: 232, y: 480 },
    { x: 400, y: 420 }, { x: 432, y: 420 }, { x: 464, y: 420 },
    { x: 700, y: 320 }, { x: 732, y: 320 },
    { x: 1000, y: 420 }, { x: 1032, y: 420 },
    { x: 1400, y: 350 }, { x: 1432, y: 350 },
    { x: 1800, y: 420 },
    { x: 2100, y: 320 }, { x: 2132, y: 320 }, { x: 2164, y: 320 },
    { x: 2500, y: 250 }, { x: 2532, y: 250 }
  ],

  stars: [
    { x: 850, y: 200 },
    { x: 1650, y: 180 },
    { x: 2700, y: 180 }
  ],

  mushrooms: [
    { x: 500, y: 420 },
    { x: 1500, y: 320 }
  ],

  enemies: [
    { type: 'gull', x: 350, y: 500 },
    { type: 'gull', x: 700, y: 500 },
    { type: 'heron', x: 1000, y: 480 },
    { type: 'gull', x: 1300, y: 500 },
    { type: 'gull', x: 1600, y: 500 },
    { type: 'heron', x: 2000, y: 480 },
    { type: 'gull', x: 2300, y: 500 },
    { type: 'heron', x: 2600, y: 250 }
  ]
};

// Level 2-1: Ancient Ruins Entry
// Vertical platforming, moving platforms concept
const level3 = {
  width: 2800,
  height: 700,
  playerSpawn: { x: 100, y: 500 },
  babyPosition: { x: 2600, y: 100 },

  tiles: (() => {
    const rows = 22;
    const cols = 88;
    const map = [];

    for (let y = 0; y < rows; y++) {
      const row = [];
      for (let x = 0; x < cols; x++) {
        if (y >= 20) {
          // Ground with more gaps
          if ((x >= 15 && x <= 20) || (x >= 35 && x <= 42) || (x >= 60 && x <= 65)) {
            row.push(0);
          } else {
            row.push(2); // Different tile for ruins
          }
        } else if (y === 16 && ((x >= 8 && x <= 12) || (x >= 45 && x <= 50))) {
          row.push(2);
        } else if (y === 12 && ((x >= 22 && x <= 28) || (x >= 55 && x <= 60))) {
          row.push(2);
        } else if (y === 8 && ((x >= 30 && x <= 35) || (x >= 70 && x <= 78))) {
          row.push(2);
        } else if (y === 4 && x >= 80 && x <= 85) {
          row.push(2);
        } else {
          row.push(0);
        }
      }
      map.push(row);
    }
    return map;
  })(),

  coins: [
    { x: 300, y: 580 }, { x: 332, y: 580 },
    { x: 500, y: 500 }, { x: 532, y: 500 },
    { x: 800, y: 380 }, { x: 832, y: 380 }, { x: 864, y: 380 },
    { x: 1100, y: 320 },
    { x: 1500, y: 580 }, { x: 1532, y: 580 },
    { x: 1800, y: 250 }, { x: 1832, y: 250 },
    { x: 2200, y: 200 }, { x: 2232, y: 200 }, { x: 2264, y: 200 }
  ],

  stars: [
    { x: 450, y: 350 },
    { x: 1400, y: 200 },
    { x: 2500, y: 120 }
  ],

  mushrooms: [
    { x: 700, y: 480 },
    { x: 1900, y: 250 }
  ],

  enemies: [
    { type: 'gull', x: 400, y: 600 },
    { type: 'heron', x: 800, y: 580 },
    { type: 'gull', x: 1200, y: 380 },
    { type: 'heron', x: 1600, y: 580 },
    { type: 'gull', x: 2000, y: 260 },
    { type: 'heron', x: 2400, y: 200 }
  ]
};

// Level 2-2: Ancient Ruins Depths
// More complex, multiple paths
const level4 = {
  width: 3200,
  height: 700,
  playerSpawn: { x: 100, y: 500 },
  babyPosition: { x: 3000, y: 150 },

  tiles: (() => {
    const rows = 22;
    const cols = 100;
    const map = [];

    for (let y = 0; y < rows; y++) {
      const row = [];
      for (let x = 0; x < cols; x++) {
        if (y >= 20) {
          if ((x >= 20 && x <= 28) || (x >= 45 && x <= 52) || (x >= 70 && x <= 76)) {
            row.push(0);
          } else {
            row.push(2);
          }
        } else if (y === 17 && ((x >= 10 && x <= 15) || (x >= 55 && x <= 62))) {
          row.push(2);
        } else if (y === 14 && ((x >= 25 && x <= 32) || (x >= 78 && x <= 85))) {
          row.push(2);
        } else if (y === 10 && ((x >= 35 && x <= 42) || (x >= 65 && x <= 72))) {
          row.push(2);
        } else if (y === 6 && x >= 88 && x <= 96) {
          row.push(2);
        } else {
          row.push(0);
        }
      }
      map.push(row);
    }
    return map;
  })(),

  coins: [
    { x: 250, y: 580 }, { x: 282, y: 580 }, { x: 314, y: 580 },
    { x: 600, y: 520 }, { x: 632, y: 520 },
    { x: 950, y: 420 }, { x: 982, y: 420 }, { x: 1014, y: 420 },
    { x: 1300, y: 320 }, { x: 1332, y: 320 },
    { x: 1700, y: 580 }, { x: 1732, y: 580 },
    { x: 2100, y: 420 }, { x: 2132, y: 420 },
    { x: 2500, y: 300 }, { x: 2532, y: 300 },
    { x: 2900, y: 200 }, { x: 2932, y: 200 }
  ],

  stars: [
    { x: 550, y: 300 },
    { x: 1850, y: 180 },
    { x: 2800, y: 100 }
  ],

  mushrooms: [
    { x: 450, y: 520 },
    { x: 1500, y: 420 },
    { x: 2600, y: 320 }
  ],

  enemies: [
    { type: 'gull', x: 350, y: 600 },
    { type: 'heron', x: 700, y: 580 },
    { type: 'gull', x: 1000, y: 600 },
    { type: 'gull', x: 1200, y: 440 },
    { type: 'heron', x: 1500, y: 580 },
    { type: 'gull', x: 1800, y: 340 },
    { type: 'heron', x: 2200, y: 440 },
    { type: 'gull', x: 2500, y: 320 },
    { type: 'heron', x: 2850, y: 180 }
  ]
};

// Level 3-1: Crystal Caves (Final/Boss)
// Challenging finale
const level5 = {
  width: 3500,
  height: 800,
  playerSpawn: { x: 100, y: 600 },
  babyPosition: { x: 3300, y: 150 },

  tiles: (() => {
    const rows = 25;
    const cols = 110;
    const map = [];

    for (let y = 0; y < rows; y++) {
      const row = [];
      for (let x = 0; x < cols; x++) {
        if (y >= 23) {
          // Ground with many gaps - final challenge
          if ((x >= 15 && x <= 22) || (x >= 35 && x <= 40) ||
              (x >= 55 && x <= 62) || (x >= 80 && x <= 85)) {
            row.push(0);
          } else {
            row.push(1);
          }
        } else if (y === 19 && ((x >= 8 && x <= 13) || (x >= 45 && x <= 52) || (x >= 90 && x <= 100))) {
          row.push(1);
        } else if (y === 15 && ((x >= 25 && x <= 32) || (x >= 65 && x <= 75))) {
          row.push(1);
        } else if (y === 11 && ((x >= 40 && x <= 48) || (x >= 85 && x <= 92))) {
          row.push(1);
        } else if (y === 7 && ((x >= 55 && x <= 62) || (x >= 95 && x <= 105))) {
          row.push(1);
        } else {
          row.push(0);
        }
      }
      map.push(row);
    }
    return map;
  })(),

  coins: [
    { x: 200, y: 680 }, { x: 232, y: 680 }, { x: 264, y: 680 },
    { x: 500, y: 600 }, { x: 532, y: 600 },
    { x: 800, y: 500 }, { x: 832, y: 500 }, { x: 864, y: 500 },
    { x: 1100, y: 420 }, { x: 1132, y: 420 },
    { x: 1500, y: 680 }, { x: 1532, y: 680 },
    { x: 1800, y: 500 }, { x: 1832, y: 500 },
    { x: 2100, y: 350 }, { x: 2132, y: 350 }, { x: 2164, y: 350 },
    { x: 2500, y: 600 },
    { x: 2800, y: 350 }, { x: 2832, y: 350 },
    { x: 3100, y: 220 }, { x: 3132, y: 220 }, { x: 3164, y: 220 }
  ],

  stars: [
    { x: 750, y: 280 },
    { x: 2000, y: 200 },
    { x: 3200, y: 100 }
  ],

  mushrooms: [
    { x: 400, y: 600 },
    { x: 1300, y: 500 },
    { x: 2400, y: 600 },
    { x: 3000, y: 350 }
  ],

  enemies: [
    { type: 'gull', x: 350, y: 700 },
    { type: 'heron', x: 600, y: 680 },
    { type: 'gull', x: 900, y: 600 },
    { type: 'gull', x: 1100, y: 700 },
    { type: 'heron', x: 1400, y: 680 },
    { type: 'gull', x: 1700, y: 520 },
    { type: 'heron', x: 2000, y: 480 },
    { type: 'gull', x: 2300, y: 700 },
    { type: 'heron', x: 2600, y: 680 },
    { type: 'gull', x: 2900, y: 370 },
    { type: 'heron', x: 3100, y: 240 }
  ]
};

export const LEVELS = [level1, level2, level3, level4, level5];

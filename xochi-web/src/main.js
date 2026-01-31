import Phaser from 'phaser';
import BootScene from './scenes/BootScene.js';
import MenuScene from './scenes/MenuScene.js';
import StoryScene from './scenes/StoryScene.js';
import GameScene from './scenes/GameScene.js';
import UIScene from './scenes/UIScene.js';
import PauseScene from './scenes/PauseScene.js';
import CustomizeScene from './scenes/CustomizeScene.js';
import EndScene from './scenes/EndScene.js';

const config = {
  type: Phaser.AUTO,
  parent: 'game-container',
  width: 800,
  height: 600,
  pixelArt: true,
  roundPixels: true,
  physics: {
    default: 'arcade',
    arcade: {
      gravity: { y: 800 },
      debug: false
    }
  },
  scale: {
    mode: Phaser.Scale.FIT,
    autoCenter: Phaser.Scale.CENTER_BOTH,
    min: {
      width: 400,
      height: 300
    },
    max: {
      width: 1600,
      height: 1200
    }
  },
  scene: [
    BootScene,
    MenuScene,
    StoryScene,
    GameScene,
    UIScene,
    PauseScene,
    CustomizeScene,
    EndScene
  ]
};

const game = new Phaser.Game(config);

// Difficulty presets - matching game.js
const DIFFICULTY_SETTINGS = {
  easy: {
    lives: 5,
    startingSuperJumps: 3,
    startingMaceAttacks: 2,
    platformDensity: 1.2,
    platformGapMult: 0.85,
    enemyMult: 0.7,
    powerupMult: 1.3,
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
    startingMaceAttacks: 1,
    platformDensity: 0.9,
    platformGapMult: 1.1,
    enemyMult: 1.2,
    powerupMult: 0.8,
    skyPlatforms: 4,
    coinMult: 0.9,
    bossHealth: { 5: 5, 10: 7 }
  }
};

// Global game state - matching game.js structure
window.gameState = {
  currentLevel: 1,
  totalLevels: 10,
  flowers: 0,       // Cempasuchil flowers (replaces coins)
  coins: 0,         // Legacy support
  lives: 3,
  stars: [],
  rescuedBabies: [],
  superJumps: 2,
  maceAttacks: 1,
  score: 0,
  highScore: 0,
  unlockedColors: ['default'],
  unlockedAccessories: [],
  currentColor: 'default',
  currentAccessory: null,
  musicEnabled: true,
  sfxEnabled: true,
  difficulty: 'medium'
};

// Make difficulty settings available globally
window.DIFFICULTY_SETTINGS = DIFFICULTY_SETTINGS;

// World definitions for music and theming
window.WORLDS = {
  1: { name: 'Canal Dawn', subtitle: 'El Amanecer' },
  2: { name: 'Bright Trajineras', subtitle: 'Trajineras Brillantes' },
  3: { name: 'Crystal Cave', subtitle: 'Cueva de Cristal' },
  4: { name: 'Floating Gardens', subtitle: 'Jardines Flotantes' },
  5: { name: 'Night Canals', subtitle: 'Canales de Noche' },
  6: { name: 'The Grand Festival', subtitle: 'La Gran Fiesta' }
};

// Helper functions for world/level mapping
window.getWorldForLevel = function(levelNum) {
  if (levelNum <= 2) return 1;  // Canal Dawn
  if (levelNum <= 4) return 2;  // Bright Trajineras
  if (levelNum === 5) return 3; // Crystal Cave (Boss)
  if (levelNum <= 7) return 4;  // Floating Gardens
  if (levelNum <= 9) return 5;  // Night Canals
  return 6;                     // The Grand Festival (Final Boss)
};

window.getFirstLevelOfWorld = function(worldNum) {
  switch(worldNum) {
    case 1: return 1;
    case 2: return 3;
    case 3: return 5;
    case 4: return 6;
    case 5: return 8;
    case 6: return 10;
    default: return 1;
  }
};

// Save and load functions
window.saveGame = function() {
  localStorage.setItem('xochi-save', JSON.stringify(window.gameState));
};

window.resetGame = function() {
  if (window.gameState.score > window.gameState.highScore) {
    window.gameState.highScore = window.gameState.score;
  }
  const settings = DIFFICULTY_SETTINGS[window.gameState.difficulty];
  window.gameState.currentLevel = 1;
  window.gameState.flowers = 0;
  window.gameState.coins = 0;
  window.gameState.lives = settings.lives;
  window.gameState.stars = [];
  window.gameState.rescuedBabies = [];
  window.gameState.superJumps = settings.startingSuperJumps;
  window.gameState.maceAttacks = settings.startingMaceAttacks;
  window.gameState.score = 0;
  window.saveGame();
};

// Load saved state
try {
  const saved = localStorage.getItem('xochi-save');
  if (saved) Object.assign(window.gameState, JSON.parse(saved));
} catch (e) {
  console.log('No valid save data found');
}

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

// Global game state
window.gameState = {
  currentLevel: 1,
  totalLevels: 5,
  coins: 0,
  lives: 3,
  stars: [],
  rescuedBabies: [],
  unlockedColors: ['default'],
  unlockedAccessories: [],
  currentColor: 'default',
  currentAccessory: null,
  musicEnabled: true,
  sfxEnabled: true
};

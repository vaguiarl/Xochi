import Phaser from 'phaser';

export default class PauseScene extends Phaser.Scene {
  constructor() {
    super('PauseScene');
  }

  create() {
    const { width, height } = this.cameras.main;

    // Dim overlay
    this.add.rectangle(0, 0, width, height, 0x000000, 0.7).setOrigin(0);

    // Pause title
    this.add.text(width / 2, 150, 'PAUSED', {
      fontFamily: 'Arial Black',
      fontSize: '48px',
      color: '#4ecdc4'
    }).setOrigin(0.5);

    // Resume button
    this.createButton(width / 2, 280, 'RESUME', '#4ecdc4', () => {
      this.scene.resume('GameScene');
      this.scene.stop();
    });

    // Restart button
    this.createButton(width / 2, 350, 'RESTART LEVEL', '#ffe66d', () => {
      this.scene.stop('GameScene');
      this.scene.stop('UIScene');
      this.scene.stop();
      this.scene.start('GameScene', { level: window.gameState.currentLevel });
    });

    // Music toggle
    const musicText = window.gameState.musicEnabled ? 'MUSIC: ON' : 'MUSIC: OFF';
    this.musicBtn = this.createButton(width / 2, 420, musicText, '#ff6b9d', () => {
      window.gameState.musicEnabled = !window.gameState.musicEnabled;
      this.musicBtn.getAt(1).setText(window.gameState.musicEnabled ? 'MUSIC: ON' : 'MUSIC: OFF');

      // Toggle actual music
      const gameScene = this.scene.get('GameScene');
      if (gameScene.music) {
        if (window.gameState.musicEnabled) {
          gameScene.music.resume();
        } else {
          gameScene.music.pause();
        }
      }
    });

    // SFX toggle
    const sfxText = window.gameState.sfxEnabled ? 'SFX: ON' : 'SFX: OFF';
    this.sfxBtn = this.createButton(width / 2, 490, sfxText, '#ff6b9d', () => {
      window.gameState.sfxEnabled = !window.gameState.sfxEnabled;
      this.sfxBtn.getAt(1).setText(window.gameState.sfxEnabled ? 'SFX: ON' : 'SFX: OFF');
    });

    // Quit button
    this.createButton(width / 2, 560, 'QUIT TO MENU', '#ff6b6b', () => {
      this.scene.stop('GameScene');
      this.scene.stop('UIScene');
      this.scene.stop();
      this.sound.stopAll();
      this.scene.start('MenuScene');
    });

    // Resume on ESC
    this.input.keyboard.on('keydown-ESC', () => {
      this.scene.resume('GameScene');
      this.scene.stop();
    });
  }

  createButton(x, y, text, color, callback) {
    const btn = this.add.container(x, y);

    const bg = this.add.graphics();
    bg.fillStyle(Phaser.Display.Color.HexStringToColor(color).color, 1);
    bg.fillRoundedRect(-120, -22, 240, 44, 8);

    const label = this.add.text(0, 0, text, {
      fontFamily: 'Arial Black',
      fontSize: '20px',
      color: '#fff'
    }).setOrigin(0.5);

    btn.add([bg, label]);
    btn.setSize(240, 44);
    btn.setInteractive({ useHandCursor: true });

    btn.on('pointerover', () => btn.setScale(1.05));
    btn.on('pointerout', () => btn.setScale(1));
    btn.on('pointerdown', callback);

    return btn;
  }
}

import Phaser from 'phaser';

export default class MenuScene extends Phaser.Scene {
  constructor() {
    super('MenuScene');
  }

  create() {
    const { width, height } = this.cameras.main;

    // Background gradient
    this.cameras.main.setBackgroundColor('#1a1a2e');

    // Add animated background elements
    this.createBackground();

    // Title
    this.add.text(width / 2, 120, 'XOCHI', {
      fontFamily: 'Arial Black',
      fontSize: '72px',
      color: '#ff6b9d',
      stroke: '#4ecdc4',
      strokeThickness: 8
    }).setOrigin(0.5);

    this.add.text(width / 2, 180, 'Axolotl Adventure', {
      fontFamily: 'Arial',
      fontSize: '24px',
      color: '#4ecdc4'
    }).setOrigin(0.5);

    // Animated Xochi character
    this.xochiPreview = this.add.sprite(width / 2, 300, 'xochi')
      .setScale(4)
      .play('xochi-idle');

    // Floating animation for preview
    this.tweens.add({
      targets: this.xochiPreview,
      y: 280,
      duration: 1000,
      yoyo: true,
      repeat: -1,
      ease: 'Sine.easeInOut'
    });

    // Play Button
    const playBtn = this.createButton(width / 2, 420, 'PLAY', '#4ecdc4', () => {
      this.playSelectSound();
      if (window.gameState.currentLevel === 1 && window.gameState.rescuedBabies.length === 0) {
        this.scene.start('StoryScene', { type: 'intro' });
      } else {
        this.scene.start('GameScene', { level: window.gameState.currentLevel });
      }
    });

    // Customize Button
    const customizeBtn = this.createButton(width / 2, 490, 'CUSTOMIZE', '#ff6b9d', () => {
      this.playSelectSound();
      this.scene.start('CustomizeScene');
    });

    // Progress display
    const stars = window.gameState.stars.length;
    const babies = window.gameState.rescuedBabies.length;

    this.add.text(width / 2, 560, `Stars: ${stars}/15  |  Rescued: ${babies}/5`, {
      fontFamily: 'Arial',
      fontSize: '18px',
      color: '#888'
    }).setOrigin(0.5);

    // Instructions
    this.add.text(width / 2, height - 30, 'Arrow Keys / WASD to Move  |  Space to Jump', {
      fontFamily: 'Arial',
      fontSize: '14px',
      color: '#666'
    }).setOrigin(0.5);

    // Keyboard input
    this.input.keyboard.on('keydown-SPACE', () => {
      this.playSelectSound();
      this.scene.start('GameScene', { level: window.gameState.currentLevel });
    });
  }

  createBackground() {
    // Floating particles
    for (let i = 0; i < 20; i++) {
      const x = Phaser.Math.Between(0, 800);
      const y = Phaser.Math.Between(0, 600);
      const size = Phaser.Math.Between(2, 6);
      const alpha = Phaser.Math.FloatBetween(0.1, 0.4);

      const particle = this.add.circle(x, y, size, 0x4ecdc4, alpha);

      this.tweens.add({
        targets: particle,
        y: y - 100,
        alpha: 0,
        duration: Phaser.Math.Between(3000, 6000),
        repeat: -1,
        onRepeat: () => {
          particle.x = Phaser.Math.Between(0, 800);
          particle.y = 650;
          particle.alpha = alpha;
        }
      });
    }
  }

  createButton(x, y, text, color, callback) {
    const btn = this.add.container(x, y);

    // Button background
    const bg = this.add.graphics();
    bg.fillStyle(Phaser.Display.Color.HexStringToColor(color).color, 1);
    bg.fillRoundedRect(-100, -25, 200, 50, 10);

    // Button text
    const label = this.add.text(0, 0, text, {
      fontFamily: 'Arial Black',
      fontSize: '24px',
      color: '#fff'
    }).setOrigin(0.5);

    btn.add([bg, label]);
    btn.setSize(200, 50);
    btn.setInteractive({ useHandCursor: true });

    // Hover effects
    btn.on('pointerover', () => {
      this.tweens.add({
        targets: btn,
        scaleX: 1.1,
        scaleY: 1.1,
        duration: 100
      });
    });

    btn.on('pointerout', () => {
      this.tweens.add({
        targets: btn,
        scaleX: 1,
        scaleY: 1,
        duration: 100
      });
    });

    btn.on('pointerdown', callback);

    return btn;
  }

  playSelectSound() {
    if (window.gameState.sfxEnabled) {
      this.sound.play('sfx-select', { volume: 0.5 });
    }
  }
}

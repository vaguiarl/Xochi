import Phaser from 'phaser';

export default class EndScene extends Phaser.Scene {
  constructor() {
    super('EndScene');
  }

  create() {
    const { width, height } = this.cameras.main;

    this.cameras.main.setBackgroundColor('#1a1a2e');

    // Victory music
    if (window.gameState.musicEnabled) {
      this.sound.play('music-victory', { volume: 0.5 });
    }

    // Confetti particles
    this.createConfetti();

    // Title
    this.add.text(width / 2, 100, 'CONGRATULATIONS!', {
      fontFamily: 'Arial Black',
      fontSize: '42px',
      color: '#ffe66d',
      stroke: '#ff6b9d',
      strokeThickness: 4
    }).setOrigin(0.5);

    // All babies rescued display
    this.add.text(width / 2, 160, 'All Baby Axolotls Rescued!', {
      fontFamily: 'Arial',
      fontSize: '24px',
      color: '#4ecdc4'
    }).setOrigin(0.5);

    // Baby parade
    for (let i = 0; i < 5; i++) {
      const baby = this.add.sprite(width / 2 - 100 + i * 50, 220, 'baby-axolotl')
        .setScale(2)
        .play('baby-idle');

      this.tweens.add({
        targets: baby,
        y: 210,
        duration: 500,
        yoyo: true,
        repeat: -1,
        delay: i * 100
      });
    }

    // Xochi with all babies
    this.xochi = this.add.sprite(width / 2, 320, 'xochi')
      .setScale(5)
      .play('xochi-idle');

    this.tweens.add({
      targets: this.xochi,
      y: 300,
      duration: 1000,
      yoyo: true,
      repeat: -1,
      ease: 'Sine.easeInOut'
    });

    // Stats
    this.add.text(width / 2, 420, 'YOUR ADVENTURE:', {
      fontFamily: 'Arial',
      fontSize: '20px',
      color: '#fff'
    }).setOrigin(0.5);

    const stats = [
      `Stars Collected: ${window.gameState.stars.length}/15`,
      `Coins Collected: ${window.gameState.coins}`,
      `Colors Unlocked: ${window.gameState.unlockedColors?.length || 1}`
    ];

    stats.forEach((stat, i) => {
      this.add.text(width / 2, 460 + i * 30, stat, {
        fontFamily: 'Arial',
        fontSize: '16px',
        color: '#4ecdc4'
      }).setOrigin(0.5);
    });

    // Play again button
    this.createButton(width / 2 - 100, height - 80, 'PLAY AGAIN', '#4ecdc4', () => {
      // Reset progress
      window.gameState.currentLevel = 1;
      window.gameState.lives = 3;
      window.gameState.coins = 0;
      window.gameState.rescuedBabies = [];
      localStorage.setItem('xochi-save', JSON.stringify(window.gameState));
      this.sound.stopAll();
      this.scene.start('StoryScene', { type: 'intro' });
    });

    // Menu button
    this.createButton(width / 2 + 100, height - 80, 'MAIN MENU', '#ff6b9d', () => {
      this.sound.stopAll();
      this.scene.start('MenuScene');
    });

    // Special message
    this.add.text(width / 2, height - 30, 'Thank you for playing! Made with love for you!', {
      fontFamily: 'Arial',
      fontSize: '14px',
      color: '#888'
    }).setOrigin(0.5);
  }

  createConfetti() {
    const colors = [0xff6b9d, 0x4ecdc4, 0xffe66d, 0xff6b6b, 0x9b59b6];

    for (let i = 0; i < 50; i++) {
      const x = Phaser.Math.Between(0, 800);
      const y = Phaser.Math.Between(-100, 0);
      const color = Phaser.Utils.Array.GetRandom(colors);
      const size = Phaser.Math.Between(4, 10);

      const confetti = this.add.rectangle(x, y, size, size, color);

      this.tweens.add({
        targets: confetti,
        y: 700,
        x: x + Phaser.Math.Between(-100, 100),
        rotation: Phaser.Math.FloatBetween(0, Math.PI * 4),
        duration: Phaser.Math.Between(3000, 6000),
        repeat: -1,
        delay: Phaser.Math.Between(0, 2000),
        onRepeat: () => {
          confetti.x = Phaser.Math.Between(0, 800);
          confetti.y = -20;
        }
      });
    }
  }

  createButton(x, y, text, color, callback) {
    const btn = this.add.container(x, y);

    const bg = this.add.graphics();
    bg.fillStyle(Phaser.Display.Color.HexStringToColor(color).color, 1);
    bg.fillRoundedRect(-80, -20, 160, 40, 8);

    const label = this.add.text(0, 0, text, {
      fontFamily: 'Arial Black',
      fontSize: '16px',
      color: '#fff'
    }).setOrigin(0.5);

    btn.add([bg, label]);
    btn.setSize(160, 40);
    btn.setInteractive({ useHandCursor: true });

    btn.on('pointerover', () => btn.setScale(1.05));
    btn.on('pointerout', () => btn.setScale(1));
    btn.on('pointerdown', callback);

    return btn;
  }
}

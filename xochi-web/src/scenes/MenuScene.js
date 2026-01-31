import Phaser from 'phaser';

export default class MenuScene extends Phaser.Scene {
  constructor() {
    super('MenuScene');
  }

  create() {
    const { width, height } = this.cameras.main;

    // SNES-style gradient background
    const bg = this.add.graphics();
    const bgColors = [0x1a0a2e, 0x1a1a3e, 0x2a2a4e, 0x1a2a4e, 0x1a1a3e, 0x1a0a2e];
    const stripeH = height / bgColors.length;
    bgColors.forEach((color, i) => {
      bg.fillStyle(color);
      bg.fillRect(0, i * stripeH, width, stripeH + 2);
    });

    // Animated stars background
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

    // Floating particles
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

    // Play menu music
    this.playMenuMusic();

    // Title shadow
    this.add.text(width/2 + 4, 58 + 4, 'XOCHI', {
      fontFamily: 'Arial Black', fontSize: '60px', color: '#220022'
    }).setOrigin(0.5);

    // Title main
    const title = this.add.text(width/2, 58, 'XOCHI', {
      fontFamily: 'Arial Black', fontSize: '60px', color: '#ff6b9d',
      stroke: '#ffbbcc', strokeThickness: 4
    }).setOrigin(0.5);

    this.tweens.add({
      targets: title, scaleX: 1.02, scaleY: 1.02,
      duration: 1500, yoyo: true, repeat: -1, ease: 'Sine.easeInOut'
    });

    // Subtitle
    this.add.text(width/2, 108, 'Aztec Warrior Adventure', {
      fontFamily: 'Georgia', fontSize: '20px', color: '#66ddcc',
      stroke: '#224444', strokeThickness: 2
    }).setOrigin(0.5);

    // Character preview with glow
    const glow = this.add.circle(width/2, 170, 35, 0xff6b9d, 0.3);
    this.tweens.add({ targets: glow, scale: 1.2, alpha: 0.1, duration: 1000, yoyo: true, repeat: -1 });

    // Animated Xochi character
    this.xochiPreview = this.add.sprite(width / 2, 170, 'xochi')
      .setScale(4)
      .play('xochi-idle');

    this.tweens.add({
      targets: this.xochiPreview, y: 160,
      duration: 800, yoyo: true, repeat: -1, ease: 'Sine.easeInOut'
    });

    // Scoreboard box
    this.add.rectangle(width/2 + 3, 243, 310, 68, 0x000000, 0.5);
    this.add.rectangle(width/2, 240, 310, 68, 0x4ecdc4);
    this.add.rectangle(width/2, 240, 304, 62, 0x1a2a4e);
    this.add.rectangle(width/2, 218, 300, 2, 0x5eede4, 0.5);

    this.add.text(width/2, 222, `SCORE: ${window.gameState.score}`, {
      fontFamily: 'Arial Black', fontSize: '20px', color: '#ffee44',
      stroke: '#886600', strokeThickness: 2
    }).setOrigin(0.5);

    this.add.text(width/2, 250, `HIGH SCORE: ${window.gameState.highScore}`, {
      fontFamily: 'Arial', fontSize: '15px', color: '#ff88aa'
    }).setOrigin(0.5);

    this.add.text(width/2, 290, `Level ${window.gameState.currentLevel}/10 | Stars: ${window.gameState.stars.length}/30 | Rescued: ${window.gameState.rescuedBabies.length}/10`, {
      fontFamily: 'Arial', fontSize: '13px', color: '#88aacc'
    }).setOrigin(0.5);

    // Difficulty selector
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

    diffButtons.forEach((diff, i) => {
      const x = startX + i * (btnWidth + 10);
      const isSelected = window.gameState.difficulty === diff;
      const colors = diffColors[diff];

      const btnBg = this.add.rectangle(x, 345, btnWidth, 28, isSelected ? colors.bg : 0x333333)
        .setInteractive({ useHandCursor: true });

      if (isSelected) {
        this.add.rectangle(x, 345, btnWidth + 4, 32, 0xffffff).setDepth(-1);
      }

      this.add.text(x, 345, colors.label, {
        fontFamily: 'Arial Black', fontSize: '11px',
        color: isSelected ? colors.text : '#666666'
      }).setOrigin(0.5);

      btnBg.on('pointerdown', () => {
        window.gameState.difficulty = diff;
        window.gameState.lives = window.DIFFICULTY_SETTINGS[diff].lives;
        window.saveGame();
        this.scene.restart();
      });

      btnBg.on('pointerover', () => {
        if (window.gameState.difficulty !== diff) btnBg.setFillStyle(0x555555);
      });
      btnBg.on('pointerout', () => {
        if (window.gameState.difficulty !== diff) btnBg.setFillStyle(0x333333);
      });
    });

    const diffDesc = {
      easy: '5 lives, 3 super jumps, easier gaps',
      medium: '3 lives, 2 super jumps, balanced',
      hard: '2 lives, 1 super jump, challenging'
    };
    this.add.text(width/2, 370, diffDesc[window.gameState.difficulty], {
      fontFamily: 'Arial', fontSize: '10px', color: '#888888'
    }).setOrigin(0.5);

    // Play/Continue button
    this.createButton(width / 2, 415, 200, 50, 0x33bb99, 0x22aa88, 0x44ccaa,
      window.gameState.currentLevel > 1 ? 'CONTINUE' : 'PLAY', () => {
        this.playSelectSound();
        this.scene.start('GameScene', { level: window.gameState.currentLevel });
      });

    // New Game button
    this.createButton(width / 2, 475, 200, 50, 0xdd5588, 0xcc4477, 0xee6699,
      'NEW GAME', () => {
        this.playSelectSound();
        window.resetGame();
        this.scene.start('GameScene', { level: 1 });
      });

    // World Selection
    this.add.text(width/2, 510, 'SELECT WORLD', {
      fontFamily: 'Arial Black', fontSize: '12px', color: '#aaaaaa'
    }).setOrigin(0.5);

    const worldData = [
      { num: 1, name: 'Dawn', color: 0xffaa77 },
      { num: 2, name: 'Day', color: 0x55ccee },
      { num: 3, name: 'Cave', color: 0x4466aa },
      { num: 4, name: 'Garden', color: 0xffcc44 },
      { num: 5, name: 'Night', color: 0x6644aa },
      { num: 6, name: 'Fiesta', color: 0x44ccaa }
    ];

    const wBtnSize = 42;
    const worldStartX = width/2 - (worldData.length * wBtnSize) / 2 + wBtnSize/2;

    worldData.forEach((world, i) => {
      const x = worldStartX + i * wBtnSize;
      const y = 540;
      const isCurrent = window.getWorldForLevel(window.gameState.currentLevel) === world.num;

      const btnBg = this.add.rectangle(x, y, wBtnSize - 4, wBtnSize - 4, world.color);

      if (isCurrent) {
        this.add.rectangle(x, y, wBtnSize, wBtnSize, 0xffffff).setDepth(-1);
      }

      this.add.text(x, y, `W${world.num}`, {
        fontFamily: 'Arial', fontSize: '12px', color: '#ffffff'
      }).setOrigin(0.5);

      btnBg.setInteractive({ useHandCursor: true });

      btnBg.on('pointerover', () => {
        btnBg.setScale(1.1);
        if (!this.worldTooltip) {
          this.worldTooltip = this.add.text(width/2, 575, '', {
            fontFamily: 'Arial', fontSize: '11px', color: '#ffffff',
            backgroundColor: '#000000', padding: { x: 8, y: 4 }
          }).setOrigin(0.5).setDepth(100);
        }
        this.worldTooltip.setText(`${window.WORLDS[world.num].name} - ${window.WORLDS[world.num].subtitle}`);
        this.worldTooltip.setVisible(true);
      });

      btnBg.on('pointerout', () => {
        btnBg.setScale(1);
        if (this.worldTooltip) this.worldTooltip.setVisible(false);
      });

      btnBg.on('pointerdown', () => {
        this.playSelectSound();
        const startLevel = window.getFirstLevelOfWorld(world.num);
        window.gameState.currentLevel = startLevel;
        window.saveGame();
        this.scene.start('GameScene', { level: startLevel });
      });
    });

    // Controls instructions
    this.add.text(width/2, height - 25, 'WASD/Arrows = Move | SPACE = Run | X = Jump | Z = Attack', {
      fontFamily: 'Arial', fontSize: '9px', color: '#555555'
    }).setOrigin(0.5);
    this.add.text(width/2, height - 10, 'Grab ledges by pressing toward them while falling!', {
      fontFamily: 'Arial', fontSize: '9px', color: '#666666'
    }).setOrigin(0.5);

    // Keyboard shortcut to start
    this.input.keyboard.on('keydown-X', () => {
      this.playSelectSound();
      this.scene.start('GameScene', { level: window.gameState.currentLevel });
    });

    this.input.keyboard.on('keydown-SPACE', () => {
      this.playSelectSound();
      this.scene.start('GameScene', { level: window.gameState.currentLevel });
    });
  }

  createButton(x, y, w, h, baseColor, darkColor, lightColor, text, callback) {
    // Shadow
    this.add.rectangle(x + 3, y + 3, w, h, 0x000000, 0.4);
    // Dark edge
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
    btn.on('pointerdown', callback);
    return btn;
  }

  playSelectSound() {
    if (window.gameState.sfxEnabled) {
      this.sound.play('sfx-select', { volume: 0.5 });
    }
  }

  playMenuMusic() {
    // Stop any existing music first
    this.sound.stopAll();

    if (window.gameState.musicEnabled) {
      this.menuMusic = this.sound.add('music-menu', { loop: true, volume: 0.4 });
      this.menuMusic.play();
    }
  }
}

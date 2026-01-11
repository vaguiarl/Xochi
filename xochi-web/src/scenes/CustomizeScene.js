import Phaser from 'phaser';

export default class CustomizeScene extends Phaser.Scene {
  constructor() {
    super('CustomizeScene');
  }

  create() {
    const { width, height } = this.cameras.main;

    this.cameras.main.setBackgroundColor('#1a1a2e');

    // Title
    this.add.text(width / 2, 60, 'CUSTOMIZE XOCHI', {
      fontFamily: 'Arial Black',
      fontSize: '36px',
      color: '#ff6b9d'
    }).setOrigin(0.5);

    // Preview character
    this.preview = this.add.sprite(width / 2, 200, 'xochi')
      .setScale(6)
      .play('xochi-idle');

    // Floating animation
    this.tweens.add({
      targets: this.preview,
      y: 180,
      duration: 1000,
      yoyo: true,
      repeat: -1,
      ease: 'Sine.easeInOut'
    });

    // Color section
    this.add.text(width / 2, 300, 'COLORS', {
      fontFamily: 'Arial',
      fontSize: '20px',
      color: '#4ecdc4'
    }).setOrigin(0.5);

    this.createColorOptions(width / 2, 350);

    // Accessories section
    this.add.text(width / 2, 420, 'ACCESSORIES', {
      fontFamily: 'Arial',
      fontSize: '20px',
      color: '#4ecdc4'
    }).setOrigin(0.5);

    this.createAccessoryOptions(width / 2, 470);

    // Unlock info
    this.add.text(width / 2, 540, 'Collect stars to unlock more!', {
      fontFamily: 'Arial',
      fontSize: '16px',
      color: '#888'
    }).setOrigin(0.5);

    // Back button
    this.createButton(width / 2, height - 60, 'BACK', '#4ecdc4', () => {
      this.saveCustomization();
      this.scene.start('MenuScene');
    });
  }

  createColorOptions(x, y) {
    const colors = [
      { id: 'default', color: 0xff6b9d, name: 'Pink', requirement: null },
      { id: 'blue', color: 0x4ecdc4, name: 'Blue', requirement: 3 },
      { id: 'gold', color: 0xffe66d, name: 'Gold', requirement: 6 },
      { id: 'rainbow', color: 0xff00ff, name: 'Rainbow', requirement: 12 }
    ];

    const spacing = 80;
    const startX = x - (colors.length - 1) * spacing / 2;

    colors.forEach((c, i) => {
      const px = startX + i * spacing;
      const unlocked = !c.requirement || window.gameState.stars.length >= c.requirement;

      const circle = this.add.circle(px, y, 25, c.color, unlocked ? 1 : 0.3);

      if (unlocked) {
        circle.setInteractive({ useHandCursor: true });
        circle.on('pointerdown', () => {
          window.gameState.currentColor = c.id;
          this.updatePreview();
          this.highlightColor(circle);
        });

        // Highlight current selection
        if (window.gameState.currentColor === c.id) {
          this.highlightColor(circle);
        }
      } else {
        // Locked indicator
        this.add.text(px, y + 40, `${c.requirement} stars`, {
          fontFamily: 'Arial',
          fontSize: '12px',
          color: '#666'
        }).setOrigin(0.5);

        // Lock icon
        this.add.text(px, y, '🔒', {
          fontSize: '20px'
        }).setOrigin(0.5);
      }
    });
  }

  createAccessoryOptions(x, y) {
    const accessories = [
      { id: 'none', emoji: '❌', name: 'None', requirement: null },
      { id: 'flower', emoji: '🌸', name: 'Flower', requirement: 5 },
      { id: 'bow', emoji: '🎀', name: 'Bow', requirement: 8 },
      { id: 'sunglasses', emoji: '😎', name: 'Shades', requirement: 10 },
      { id: 'crown', emoji: '👑', name: 'Crown', requirement: 15 }
    ];

    const spacing = 70;
    const startX = x - (accessories.length - 1) * spacing / 2;

    accessories.forEach((acc, i) => {
      const px = startX + i * spacing;
      const unlocked = !acc.requirement || window.gameState.stars.length >= acc.requirement;

      const btn = this.add.text(px, y, acc.emoji, {
        fontSize: '32px'
      })
        .setOrigin(0.5)
        .setAlpha(unlocked ? 1 : 0.3);

      if (unlocked) {
        btn.setInteractive({ useHandCursor: true });
        btn.on('pointerdown', () => {
          window.gameState.currentAccessory = acc.id === 'none' ? null : acc.id;
          this.updatePreview();
        });
      } else {
        this.add.text(px, y + 30, `${acc.requirement}⭐`, {
          fontFamily: 'Arial',
          fontSize: '10px',
          color: '#666'
        }).setOrigin(0.5);
      }
    });
  }

  highlightColor(circle) {
    // Remove previous highlights
    this.children.list
      .filter(c => c.type === 'Arc' && c.strokeColor)
      .forEach(c => c.setStrokeStyle(0));

    // Add highlight to selected
    circle.setStrokeStyle(4, 0xffffff);
  }

  updatePreview() {
    // In a full implementation, this would change the sprite tint
    // For now, just apply tint based on color
    const tints = {
      default: 0xffffff,
      blue: 0x4ecdc4,
      gold: 0xffe66d,
      rainbow: 0xff88ff
    };

    this.preview.setTint(tints[window.gameState.currentColor] || 0xffffff);
  }

  createButton(x, y, text, color, callback) {
    const btn = this.add.container(x, y);

    const bg = this.add.graphics();
    bg.fillStyle(Phaser.Display.Color.HexStringToColor(color).color, 1);
    bg.fillRoundedRect(-80, -20, 160, 40, 8);

    const label = this.add.text(0, 0, text, {
      fontFamily: 'Arial Black',
      fontSize: '20px',
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

  saveCustomization() {
    localStorage.setItem('xochi-save', JSON.stringify(window.gameState));
  }
}

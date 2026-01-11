import Phaser from 'phaser';

export default class UIScene extends Phaser.Scene {
  constructor() {
    super('UIScene');
  }

  create() {
    const { width } = this.cameras.main;

    // HUD Background
    this.add.rectangle(0, 0, width, 50, 0x000000, 0.5).setOrigin(0);

    // Lives
    this.add.text(20, 15, 'XOCHI', {
      fontFamily: 'Arial',
      fontSize: '14px',
      color: '#ff6b9d'
    });

    this.livesText = this.add.text(80, 15, `x ${window.gameState.lives}`, {
      fontFamily: 'Arial',
      fontSize: '14px',
      color: '#fff'
    });

    // Coins
    this.add.text(150, 15, 'COINS', {
      fontFamily: 'Arial',
      fontSize: '14px',
      color: '#ffe66d'
    });

    this.coinsText = this.add.text(210, 15, `${window.gameState.coins}`, {
      fontFamily: 'Arial',
      fontSize: '14px',
      color: '#fff'
    });

    // Level
    const levelNames = [
      'Floating Gardens 1',
      'Floating Gardens 2',
      'Ancient Ruins 1',
      'Ancient Ruins 2',
      'Crystal Caves'
    ];

    const gameScene = this.scene.get('GameScene');
    const levelNum = gameScene.levelNum || 1;

    this.add.text(width / 2, 15, levelNames[levelNum - 1] || `Level ${levelNum}`, {
      fontFamily: 'Arial',
      fontSize: '14px',
      color: '#4ecdc4'
    }).setOrigin(0.5, 0);

    // Stars collected this session
    this.starsText = this.add.text(width - 100, 15, `STARS: ${window.gameState.stars.length}/15`, {
      fontFamily: 'Arial',
      fontSize: '14px',
      color: '#ffe66d'
    });

    // Rescued babies
    this.babiesDisplay = this.add.container(width - 200, 35);
    this.updateBabiesDisplay();

    // Listen for updates from GameScene
    gameScene.events.on('updateUI', this.updateUI, this);
  }

  updateUI() {
    this.livesText.setText(`x ${window.gameState.lives}`);
    this.coinsText.setText(`${window.gameState.coins}`);
    this.starsText.setText(`STARS: ${window.gameState.stars.length}/15`);
    this.updateBabiesDisplay();
  }

  updateBabiesDisplay() {
    this.babiesDisplay.removeAll(true);

    for (let i = 0; i < 5; i++) {
      const rescued = window.gameState.rescuedBabies.includes(`baby-${i + 1}`);
      const color = rescued ? 0xff6b9d : 0x333333;
      const circle = this.add.circle(i * 20, 0, 6, color);
      this.babiesDisplay.add(circle);
    }
  }
}

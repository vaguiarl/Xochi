import Phaser from 'phaser';

export default class UIScene extends Phaser.Scene {
  constructor() {
    super('UIScene');
  }

  create() {
    const { width } = this.cameras.main;

    // HUD Background
    this.add.rectangle(0, 0, width, 55, 0x000000, 0.6).setOrigin(0);

    // Lives (top row)
    this.add.text(20, 8, 'XOCHI', {
      fontFamily: 'Arial Black',
      fontSize: '12px',
      color: '#ff6b9d'
    });

    this.livesText = this.add.text(70, 8, `x ${window.gameState.lives}`, {
      fontFamily: 'Arial',
      fontSize: '12px',
      color: '#fff'
    });

    // Score
    this.add.text(120, 8, 'SCORE', {
      fontFamily: 'Arial Black',
      fontSize: '12px',
      color: '#ffee44'
    });

    this.scoreText = this.add.text(180, 8, `${window.gameState.score || 0}`, {
      fontFamily: 'Arial',
      fontSize: '12px',
      color: '#fff'
    });

    // Flowers (Cempasuchil - replaces coins)
    this.add.circle(280, 14, 6, 0xff8c00);
    this.add.circle(280, 14, 2, 0xffcc00);

    this.flowersText = this.add.text(292, 8, `${window.gameState.flowers || 0}`, {
      fontFamily: 'Arial',
      fontSize: '12px',
      color: '#ff8c00'
    });

    // Level info (center top)
    const gameScene = this.scene.get('GameScene');
    const levelNum = gameScene.levelNum || 1;
    const worldNum = window.getWorldForLevel ? window.getWorldForLevel(levelNum) : 1;
    const world = window.WORLDS ? window.WORLDS[worldNum] : { name: 'World ' + worldNum };

    this.add.text(width / 2, 8, world.name.toUpperCase(), {
      fontFamily: 'Arial Black',
      fontSize: '12px',
      color: '#4ecdc4'
    }).setOrigin(0.5, 0);

    this.add.text(width / 2, 22, `Level ${levelNum}`, {
      fontFamily: 'Arial',
      fontSize: '10px',
      color: '#88aacc'
    }).setOrigin(0.5, 0);

    // Stars collected (right side top)
    this.add.text(width - 160, 8, 'STARS', {
      fontFamily: 'Arial Black',
      fontSize: '12px',
      color: '#ffee44'
    });

    this.starsText = this.add.text(width - 100, 8, `${window.gameState.stars.length}/30`, {
      fontFamily: 'Arial',
      fontSize: '12px',
      color: '#fff'
    });

    // Bottom row: Super Jumps, Attacks, Rescued Babies

    // Super Jumps
    this.add.text(20, 35, 'JUMPS', {
      fontFamily: 'Arial Black',
      fontSize: '10px',
      color: '#00dddd'
    });

    this.superJumpsText = this.add.text(70, 35, `${window.gameState.superJumps || 0}`, {
      fontFamily: 'Arial',
      fontSize: '10px',
      color: '#00ffff'
    });

    // Attacks
    this.add.text(100, 35, 'ATTACKS', {
      fontFamily: 'Arial Black',
      fontSize: '10px',
      color: '#ffdd00'
    });

    this.attacksText = this.add.text(160, 35, `${window.gameState.maceAttacks || 0}`, {
      fontFamily: 'Arial',
      fontSize: '10px',
      color: '#ffff44'
    });

    // Rescued babies (bottom right)
    this.add.text(width - 160, 35, 'RESCUED', {
      fontFamily: 'Arial Black',
      fontSize: '10px',
      color: '#ff6b9d'
    });

    this.babiesDisplay = this.add.container(width - 90, 40);
    this.updateBabiesDisplay();

    // Listen for updates from GameScene
    gameScene.events.on('updateUI', this.updateUI, this);
  }

  updateUI() {
    this.livesText.setText(`x ${window.gameState.lives}`);
    this.scoreText.setText(`${window.gameState.score || 0}`);
    this.flowersText.setText(`${window.gameState.flowers || 0}`);
    this.starsText.setText(`${window.gameState.stars.length}/30`);
    this.superJumpsText.setText(`${window.gameState.superJumps || 0}`);
    this.attacksText.setText(`${window.gameState.maceAttacks || 0}`);
    this.updateBabiesDisplay();
  }

  updateBabiesDisplay() {
    this.babiesDisplay.removeAll(true);

    for (let i = 0; i < 10; i++) {
      const rescued = window.gameState.rescuedBabies.includes(`baby-${i + 1}`);
      const color = rescued ? 0xff6b9d : 0x333333;
      const circle = this.add.circle((i % 5) * 14, Math.floor(i / 5) * 12, 5, color);
      this.babiesDisplay.add(circle);
    }
  }
}

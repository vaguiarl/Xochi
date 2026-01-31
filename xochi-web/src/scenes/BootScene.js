import Phaser from 'phaser';

export default class BootScene extends Phaser.Scene {
  constructor() {
    super('BootScene');
  }

  preload() {
    // Create loading bar
    const width = this.cameras.main.width;
    const height = this.cameras.main.height;

    // Background
    this.cameras.main.setBackgroundColor('#1a1a2e');

    // Loading text
    const loadingText = this.add.text(width / 2, height / 2 - 50, 'Loading...', {
      fontFamily: 'Arial',
      fontSize: '32px',
      color: '#4ecdc4'
    }).setOrigin(0.5);

    // Progress bar background
    const progressBox = this.add.graphics();
    progressBox.fillStyle(0x222244, 0.8);
    progressBox.fillRect(width / 2 - 160, height / 2, 320, 30);

    // Progress bar
    const progressBar = this.add.graphics();

    // Loading events
    this.load.on('progress', (value) => {
      progressBar.clear();
      progressBar.fillStyle(0x4ecdc4, 1);
      progressBar.fillRect(width / 2 - 155, height / 2 + 5, 310 * value, 20);
    });

    this.load.on('complete', () => {
      progressBar.destroy();
      progressBox.destroy();
      loadingText.destroy();
    });

    // Load all game assets
    this.loadSprites();
    this.loadTiles();
    this.loadAudio();
    this.loadUI();
  }

  loadSprites() {
    // Xochi character spritesheet (v3: 112x48, row1: 7 small 16x16, row2: 6 big 16x32)
    this.load.spritesheet('xochi', 'assets/sprites/xochi.png', {
      frameWidth: 16,
      frameHeight: 16,
      endFrame: 6
    });

    this.load.spritesheet('xochi-big', 'assets/sprites/xochi.png', {
      frameWidth: 16,
      frameHeight: 32,
      startFrame: 7,
      endFrame: 12
    });

    // Enemies (birds_enemies_v3.png)
    this.load.spritesheet('gull', 'assets/sprites/enemies.png', {
      frameWidth: 16,
      frameHeight: 16,
      endFrame: 2
    });

    this.load.spritesheet('heron', 'assets/sprites/enemies.png', {
      frameWidth: 17,
      frameHeight: 32,
      startFrame: 3
    });

    // Items from xochi_items_v3.png
    this.load.spritesheet('coin', 'assets/sprites/items.png', {
      frameWidth: 16,
      frameHeight: 16,
      endFrame: 3
    });

    this.load.spritesheet('star', 'assets/sprites/items.png', {
      frameWidth: 16,
      frameHeight: 16,
      startFrame: 4,
      endFrame: 4
    });

    this.load.spritesheet('baby-axolotl', 'assets/sprites/items.png', {
      frameWidth: 16,
      frameHeight: 16,
      startFrame: 5,
      endFrame: 5
    });

    this.load.spritesheet('mushroom', 'assets/sprites/items.png', {
      frameWidth: 16,
      frameHeight: 16,
      startFrame: 6,
      endFrame: 6
    });

    // Effects
    this.load.spritesheet('effects', 'assets/sprites/effects.png', {
      frameWidth: 16,
      frameHeight: 16
    });
  }

  loadTiles() {
    // Tileset from xochi_tiles_v3.png
    this.load.image('tileset', 'assets/tiles/tileset.png');

    // Backgrounds (parallax from xochi_parallax_v3.png)
    this.load.image('bg-parallax', 'assets/backgrounds/parallax.png');
  }

  loadAudio() {
    // Music - Suno-generated tracks
    this.load.audio('music-menu', 'assets/audio/music_menu.ogg');           // Traviesa Axolotla en Xochimilco
    this.load.audio('music-gardens', 'assets/audio/music_gardens.ogg');     // Flowers of the Last Dawn (World 1)
    this.load.audio('music-ruins', 'assets/audio/music_menu.ogg');          // Reuse menu music for middle levels
    this.load.audio('music-caves', 'assets/audio/music_night.ogg');         // Xochimilco Moonwake (Night world)
    this.load.audio('music-night-calm', 'assets/audio/music_night_calm.ogg'); // Midnight Currents (Night exploration)
    this.load.audio('music-fiesta', 'assets/audio/music_fiesta.ogg');       // Last Bloom of Oaxolotl (Final world)
    this.load.audio('music-upscroller', 'assets/audio/music_upscroller.ogg'); // Upscroller levels (3 and 8)
    this.load.audio('music-boss', 'assets/audio/music_menu.ogg');           // Reuse menu for boss fights
    this.load.audio('music-victory', 'assets/audio/powerup.ogg');

    // SFX - New procedurally generated sounds
    // Movement sounds
    this.load.audio('sfx-jump', 'assets/audio/sfx/movement/jump_small.ogg');
    this.load.audio('sfx-super-jump', 'assets/audio/sfx/movement/jump_super.ogg');
    this.load.audio('sfx-land', 'assets/audio/sfx/movement/land_soft.ogg');

    // Combat sounds
    this.load.audio('sfx-stomp', 'assets/audio/sfx/combat/stomp.ogg');
    this.load.audio('sfx-hurt', 'assets/audio/sfx/combat/hurt.ogg');

    // Collectible sounds
    this.load.audio('sfx-coin', 'assets/audio/sfx/collectibles/flower.ogg');
    this.load.audio('sfx-star', 'assets/audio/sfx/collectibles/flower.ogg');
    this.load.audio('sfx-rescue', 'assets/audio/sfx/collectibles/flower.ogg');

    // UI sounds
    this.load.audio('sfx-select', 'assets/audio/sfx/ui/menu_select.ogg');

    // Fallback for powerup (not in new SFX set yet)
    this.load.audio('sfx-powerup', 'assets/audio/sfx/collectibles/flower.ogg');
  }

  loadUI() {
    // UI elements will be generated programmatically for now
    // No external UI assets needed - we use Phaser graphics
  }

  create() {
    // Create animations
    this.createAnimations();

    // Load saved game state
    this.loadGameState();

    // Go to menu
    this.scene.start('MenuScene');
  }

  createAnimations() {
    // Xochi animations (small)
    this.anims.create({
      key: 'xochi-idle',
      frames: this.anims.generateFrameNumbers('xochi', { start: 0, end: 0 }),
      frameRate: 1,
      repeat: -1
    });

    this.anims.create({
      key: 'xochi-run',
      frames: this.anims.generateFrameNumbers('xochi', { start: 1, end: 3 }),
      frameRate: 10,
      repeat: -1
    });

    this.anims.create({
      key: 'xochi-jump',
      frames: this.anims.generateFrameNumbers('xochi', { start: 4, end: 4 }),
      frameRate: 1,
      repeat: 0
    });

    // Xochi animations (big)
    this.anims.create({
      key: 'xochi-big-idle',
      frames: this.anims.generateFrameNumbers('xochi-big', { start: 0, end: 0 }),
      frameRate: 1,
      repeat: -1
    });

    this.anims.create({
      key: 'xochi-big-run',
      frames: this.anims.generateFrameNumbers('xochi-big', { start: 1, end: 3 }),
      frameRate: 10,
      repeat: -1
    });

    this.anims.create({
      key: 'xochi-big-jump',
      frames: this.anims.generateFrameNumbers('xochi-big', { start: 4, end: 4 }),
      frameRate: 1,
      repeat: 0
    });

    // Enemy animations
    this.anims.create({
      key: 'gull-walk',
      frames: this.anims.generateFrameNumbers('gull', { start: 0, end: 1 }),
      frameRate: 6,
      repeat: -1
    });

    this.anims.create({
      key: 'gull-dead',
      frames: this.anims.generateFrameNumbers('gull', { start: 2, end: 2 }),
      frameRate: 1,
      repeat: 0
    });

    this.anims.create({
      key: 'heron-walk',
      frames: this.anims.generateFrameNumbers('heron', { start: 0, end: 1 }),
      frameRate: 6,
      repeat: -1
    });

    this.anims.create({
      key: 'heron-shell',
      frames: this.anims.generateFrameNumbers('heron', { start: 2, end: 2 }),
      frameRate: 1,
      repeat: 0
    });

    // Collectible animations
    this.anims.create({
      key: 'coin-spin',
      frames: this.anims.generateFrameNumbers('coin', { start: 0, end: 3 }),
      frameRate: 8,
      repeat: -1
    });

    this.anims.create({
      key: 'star-sparkle',
      frames: this.anims.generateFrameNumbers('star', { start: 0, end: 3 }),
      frameRate: 8,
      repeat: -1
    });

    this.anims.create({
      key: 'baby-idle',
      frames: this.anims.generateFrameNumbers('baby-axolotl', { start: 0, end: 1 }),
      frameRate: 4,
      repeat: -1
    });

    this.anims.create({
      key: 'mushroom-idle',
      frames: this.anims.generateFrameNumbers('mushroom', { start: 0, end: 0 }),
      frameRate: 1,
      repeat: -1
    });
  }

  loadGameState() {
    const saved = localStorage.getItem('xochi-save');
    if (saved) {
      try {
        const data = JSON.parse(saved);
        Object.assign(window.gameState, data);
      } catch (e) {
        console.log('No valid save data found');
      }
    }
  }
}

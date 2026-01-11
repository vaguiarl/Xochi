import Phaser from 'phaser';
import Player from '../entities/Player.js';
import Gull from '../entities/Gull.js';
import Heron from '../entities/Heron.js';
import { LEVELS } from '../levels/LevelData.js';

export default class GameScene extends Phaser.Scene {
  constructor() {
    super('GameScene');
  }

  init(data) {
    this.levelNum = data.level || 1;
    this.levelData = LEVELS[this.levelNum - 1];
  }

  create() {
    // Set up the world bounds
    this.physics.world.setBounds(0, 0, this.levelData.width, this.levelData.height);

    // Create layers in order (back to front)
    this.createBackground();
    this.createTilemap();
    this.createCollectibles();
    this.createEnemies();
    this.createPlayer();
    this.createBabyAxolotl();

    // Set up camera
    this.cameras.main.setBounds(0, 0, this.levelData.width, this.levelData.height);
    this.cameras.main.startFollow(this.player, true, 0.1, 0.1);

    // Launch UI scene
    this.scene.launch('UIScene');

    // Set up collisions
    this.setupCollisions();

    // Input
    this.cursors = this.input.keyboard.createCursorKeys();
    this.wasd = this.input.keyboard.addKeys({
      up: Phaser.Input.Keyboard.KeyCodes.W,
      down: Phaser.Input.Keyboard.KeyCodes.S,
      left: Phaser.Input.Keyboard.KeyCodes.A,
      right: Phaser.Input.Keyboard.KeyCodes.D,
      jump: Phaser.Input.Keyboard.KeyCodes.SPACE,
      run: Phaser.Input.Keyboard.KeyCodes.SHIFT
    });

    // Pause
    this.input.keyboard.on('keydown-ESC', () => {
      this.scene.launch('PauseScene');
      this.scene.pause();
    });

    // Play level music
    this.playMusic();
  }

  createBackground() {
    const { width, height } = this.levelData;

    // Sky gradient background
    const skyGradient = this.add.graphics();
    skyGradient.fillGradientStyle(0x87ceeb, 0x87ceeb, 0x4ecdc4, 0x4ecdc4, 1);
    skyGradient.fillRect(0, 0, width, height);

    // Simple parallax clouds (generated)
    this.clouds = [];
    for (let i = 0; i < 10; i++) {
      const cloud = this.add.ellipse(
        Phaser.Math.Between(0, width),
        Phaser.Math.Between(50, 200),
        Phaser.Math.Between(60, 120),
        Phaser.Math.Between(30, 50),
        0xffffff,
        0.6
      );
      cloud.setScrollFactor(0.2);
      this.clouds.push(cloud);
    }
  }

  createTilemap() {
    // Create ground and platforms using graphics (no tileset needed)
    this.groundGroup = this.physics.add.staticGroup();

    const tileData = this.levelData.tiles;
    const tileSize = 32;

    // World colors based on level
    let groundColor = 0x8B4513; // Brown for gardens
    let platformColor = 0x228B22; // Green

    if (this.levelNum >= 3 && this.levelNum < 5) {
      groundColor = 0x696969; // Gray for ruins
      platformColor = 0x808080;
    } else if (this.levelNum >= 5) {
      groundColor = 0x4a4a6a; // Purple-ish for caves
      platformColor = 0x6a6a8a;
    }

    for (let y = 0; y < tileData.length; y++) {
      for (let x = 0; x < tileData[y].length; x++) {
        const tile = tileData[y][x];
        if (tile > 0) {
          const color = tile === 1 ? groundColor : platformColor;
          const block = this.add.rectangle(
            x * tileSize + tileSize / 2,
            y * tileSize + tileSize / 2,
            tileSize - 2,
            tileSize - 2,
            color
          );

          // Add to physics group
          this.physics.add.existing(block, true);
          this.groundGroup.add(block);

          // Add a highlight for 3D effect
          const highlight = this.add.rectangle(
            x * tileSize + tileSize / 2,
            y * tileSize + 4,
            tileSize - 4,
            4,
            0xffffff,
            0.3
          );
        }
      }
    }
  }

  createCollectibles() {
    // Coins
    this.coins = this.physics.add.group({
      allowGravity: false
    });

    this.levelData.coins.forEach(pos => {
      const coin = this.coins.create(pos.x, pos.y, 'coin')
        .setScale(2)
        .play('coin-spin');
      coin.body.setSize(12, 12);
    });

    // Stars (hidden collectibles)
    this.stars = this.physics.add.group({
      allowGravity: false
    });

    this.levelData.stars.forEach((pos, i) => {
      const starId = `${this.levelNum}-${i}`;
      if (!window.gameState.stars.includes(starId)) {
        const star = this.stars.create(pos.x, pos.y, 'star')
          .setScale(2)
          .play('star-sparkle');
        star.starId = starId;
        star.body.setSize(12, 12);
      }
    });

    // Mushrooms (power-ups)
    this.mushrooms = this.physics.add.group();

    this.levelData.mushrooms?.forEach(pos => {
      const mushroom = this.mushrooms.create(pos.x, pos.y, 'mushroom')
        .setScale(2);
      mushroom.body.setVelocityX(50);
      mushroom.body.setBounce(0);
      mushroom.direction = 1;
    });
  }

  createEnemies() {
    this.enemies = this.physics.add.group();

    this.levelData.enemies.forEach(enemy => {
      let sprite;
      if (enemy.type === 'gull') {
        sprite = new Gull(this, enemy.x, enemy.y);
      } else if (enemy.type === 'heron') {
        sprite = new Heron(this, enemy.x, enemy.y);
      }
      if (sprite) {
        this.enemies.add(sprite);
      }
    });
  }

  createPlayer() {
    const spawn = this.levelData.playerSpawn;
    this.player = new Player(this, spawn.x, spawn.y);
    this.add.existing(this.player);
    this.physics.add.existing(this.player);
  }

  createBabyAxolotl() {
    // Baby axolotl to rescue at end of level
    const babyId = `baby-${this.levelNum}`;

    if (!window.gameState.rescuedBabies.includes(babyId)) {
      const pos = this.levelData.babyPosition;
      this.baby = this.physics.add.sprite(pos.x, pos.y, 'baby-axolotl')
        .setScale(2)
        .play('baby-idle');
      this.baby.body.allowGravity = false;
      this.baby.babyId = babyId;

      // Floating animation
      this.tweens.add({
        targets: this.baby,
        y: pos.y - 10,
        duration: 1000,
        yoyo: true,
        repeat: -1,
        ease: 'Sine.easeInOut'
      });

      // Sparkle effect
      this.time.addEvent({
        delay: 500,
        callback: () => {
          if (this.baby && this.baby.active) {
            this.addSparkle(this.baby.x, this.baby.y);
          }
        },
        loop: true
      });
    }
  }

  setupCollisions() {
    // Player vs ground
    this.physics.add.collider(this.player, this.groundGroup);

    // Enemies vs ground
    this.physics.add.collider(this.enemies, this.groundGroup);

    // Mushrooms vs ground
    this.physics.add.collider(this.mushrooms, this.groundGroup, (mushroom) => {
      // Bounce off walls
      if (mushroom.body.blocked.left || mushroom.body.blocked.right) {
        mushroom.direction *= -1;
        mushroom.body.setVelocityX(50 * mushroom.direction);
      }
    });

    // Player vs coins
    this.physics.add.overlap(this.player, this.coins, this.collectCoin, null, this);

    // Player vs stars
    this.physics.add.overlap(this.player, this.stars, this.collectStar, null, this);

    // Player vs mushrooms
    this.physics.add.overlap(this.player, this.mushrooms, this.collectMushroom, null, this);

    // Player vs enemies
    this.physics.add.overlap(this.player, this.enemies, this.handleEnemyCollision, null, this);

    // Player vs baby axolotl
    if (this.baby) {
      this.physics.add.overlap(this.player, this.baby, this.rescueBaby, null, this);
    }
  }

  collectCoin(player, coin) {
    coin.destroy();
    window.gameState.coins++;

    // Extra life at 100 coins
    if (window.gameState.coins >= 100) {
      window.gameState.coins -= 100;
      window.gameState.lives++;
      this.showMessage('1UP!', '#ffe66d');
    }

    this.playSound('sfx-coin');
    this.events.emit('updateUI');

    // Particle effect
    this.addCoinParticles(coin.x, coin.y);
  }

  collectStar(player, star) {
    window.gameState.stars.push(star.starId);
    star.destroy();

    this.playSound('sfx-star');
    this.showMessage('Star Found!', '#ffe66d');
    this.events.emit('updateUI');

    // Save progress
    this.saveGame();

    // Big sparkle effect
    for (let i = 0; i < 12; i++) {
      this.addSparkle(star.x + Phaser.Math.Between(-30, 30), star.y + Phaser.Math.Between(-30, 30));
    }
  }

  collectMushroom(player, mushroom) {
    mushroom.destroy();
    this.player.powerUp();
    this.playSound('sfx-powerup');
    this.showMessage('Power Up!', '#ff6b9d');
  }

  handleEnemyCollision(player, enemy) {
    if (player.isInvincible) return;

    // Check if stomping (player falling onto enemy)
    if (player.body.velocity.y > 0 && player.body.bottom < enemy.body.center.y) {
      // Stomp enemy
      enemy.stomp();
      player.bounce();
      this.playSound('sfx-stomp');

      // Points
      this.showFloatingText(enemy.x, enemy.y - 20, '+100', '#fff');
    } else {
      // Player takes damage
      player.takeDamage();
      this.playSound('sfx-hurt');
    }
  }

  rescueBaby(player, baby) {
    window.gameState.rescuedBabies.push(baby.babyId);
    baby.destroy();
    this.baby = null;

    this.playSound('sfx-rescue');
    this.showMessage('Baby Rescued!', '#ff6b9d');

    // Big celebration effect
    for (let i = 0; i < 20; i++) {
      this.time.delayedCall(i * 50, () => {
        this.addSparkle(
          player.x + Phaser.Math.Between(-50, 50),
          player.y + Phaser.Math.Between(-50, 50)
        );
      });
    }

    // Save and proceed to next level
    this.saveGame();

    this.time.delayedCall(2000, () => {
      this.completeLevel();
    });
  }

  completeLevel() {
    const nextLevel = this.levelNum + 1;

    if (nextLevel > window.gameState.totalLevels) {
      // Game complete!
      this.scene.stop('UIScene');
      this.scene.start('StoryScene', { type: 'ending' });
    } else {
      window.gameState.currentLevel = nextLevel;
      this.saveGame();

      // Check for world transition
      if (nextLevel === 3) {
        this.scene.stop('UIScene');
        this.scene.start('StoryScene', { type: 'world2', nextLevel });
      } else if (nextLevel === 5) {
        this.scene.stop('UIScene');
        this.scene.start('StoryScene', { type: 'world3', nextLevel });
      } else {
        this.scene.restart({ level: nextLevel });
      }
    }
  }

  update() {
    // Update player
    this.player.update(this.cursors, this.wasd);

    // Update enemies
    this.enemies.getChildren().forEach(enemy => {
      if (enemy.update) enemy.update();
    });

    // Simple cloud parallax
    if (this.clouds) {
      this.clouds.forEach(cloud => {
        cloud.x -= 0.2;
        if (cloud.x < -100) {
          cloud.x = this.levelData.width + 100;
        }
      });
    }

    // Check for player death (fall off world)
    if (this.player.y > this.levelData.height + 100) {
      this.playerDeath();
    }
  }

  playerDeath() {
    if (this.player.isDead) return;

    this.player.die();
    window.gameState.lives--;

    if (window.gameState.lives <= 0) {
      // Game over
      this.time.delayedCall(2000, () => {
        window.gameState.lives = 3;
        window.gameState.coins = 0;
        this.scene.stop('UIScene');
        this.scene.start('MenuScene');
      });
    } else {
      // Respawn
      this.time.delayedCall(1500, () => {
        this.scene.restart({ level: this.levelNum });
      });
    }
  }

  playMusic() {
    // Stop any existing music
    this.sound.stopAll();

    if (window.gameState.musicEnabled) {
      let musicKey = 'music-gardens';
      if (this.levelNum >= 3 && this.levelNum < 5) {
        musicKey = 'music-ruins';
      } else if (this.levelNum >= 5) {
        musicKey = 'music-caves';
      }

      this.music = this.sound.add(musicKey, { loop: true, volume: 0.4 });
      this.music.play();
    }
  }

  playSound(key) {
    if (window.gameState.sfxEnabled) {
      this.sound.play(key, { volume: 0.6 });
    }
  }

  showMessage(text, color) {
    const { width, height } = this.cameras.main;
    const msg = this.add.text(width / 2, height / 3, text, {
      fontFamily: 'Arial Black',
      fontSize: '48px',
      color: color,
      stroke: '#000',
      strokeThickness: 6
    })
      .setOrigin(0.5)
      .setScrollFactor(0)
      .setDepth(100);

    this.tweens.add({
      targets: msg,
      y: height / 3 - 50,
      alpha: 0,
      scale: 1.5,
      duration: 1500,
      ease: 'Power2',
      onComplete: () => msg.destroy()
    });
  }

  showFloatingText(x, y, text, color) {
    const floatText = this.add.text(x, y, text, {
      fontFamily: 'Arial',
      fontSize: '16px',
      color: color
    }).setOrigin(0.5);

    this.tweens.add({
      targets: floatText,
      y: y - 30,
      alpha: 0,
      duration: 800,
      onComplete: () => floatText.destroy()
    });
  }

  addCoinParticles(x, y) {
    for (let i = 0; i < 6; i++) {
      const particle = this.add.circle(x, y, 3, 0xffe66d);
      const angle = (i / 6) * Math.PI * 2;
      const speed = 100;

      this.tweens.add({
        targets: particle,
        x: x + Math.cos(angle) * 30,
        y: y + Math.sin(angle) * 30,
        alpha: 0,
        scale: 0,
        duration: 300,
        onComplete: () => particle.destroy()
      });
    }
  }

  addSparkle(x, y) {
    const colors = [0xffe66d, 0xff6b9d, 0x4ecdc4];
    const color = Phaser.Utils.Array.GetRandom(colors);
    const sparkle = this.add.circle(x, y, 4, color);

    this.tweens.add({
      targets: sparkle,
      alpha: 0,
      scale: 2,
      duration: 500,
      onComplete: () => sparkle.destroy()
    });
  }

  saveGame() {
    localStorage.setItem('xochi-save', JSON.stringify(window.gameState));
  }
}

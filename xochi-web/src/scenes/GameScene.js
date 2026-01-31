import Phaser from 'phaser';
import Player from '../entities/Player.js';
import Gull from '../entities/Gull.js';
import Heron from '../entities/Heron.js';
import { LEVELS, WORLDS, generateProceduralLevel } from '../levels/LevelData.js';

export default class GameScene extends Phaser.Scene {
  constructor() {
    super('GameScene');
  }

  init(data) {
    this.levelNum = data.level || 1;

    // Determine level type based on level number
    const isBossLevel = this.levelNum === 5 || this.levelNum === 10;
    const isUpscrollerLevel = this.levelNum === 3 || this.levelNum === 8;
    const isEscapeLevel = this.levelNum === 7 || this.levelNum === 9;

    // Use static levels if available, otherwise generate procedurally
    if (LEVELS[this.levelNum - 1]) {
      this.levelData = LEVELS[this.levelNum - 1];
    } else {
      this.levelData = generateProceduralLevel(this.levelNum, {
        isBoss: isBossLevel,
        isUpscroller: isUpscrollerLevel,
        isEscape: isEscapeLevel
      });
    }

    // Ensure world theme exists
    const worldNum = window.getWorldForLevel(this.levelNum);
    this.worldTheme = WORLDS[worldNum] || WORLDS[1];
    this.levelData.theme = this.worldTheme;
  }

  create() {
    const ld = this.levelData;

    // Set up the world bounds
    this.physics.world.setBounds(0, 0, ld.width, ld.height);

    // Touch controls state
    this.touchControls = { left: false, right: false, jump: false, attack: false, superJump: false };

    // Create layers in order (back to front)
    this.createBackground();
    this.createPlatforms();
    this.createTrajineras();
    this.createCollectibles();
    this.createEnemies();
    this.createPlayer();
    this.createBabyAxolotl();

    // Set up camera
    this.cameras.main.setBounds(0, 0, ld.width, ld.height);
    this.cameras.main.startFollow(this.player, true, 0.1, 0.1);

    // Launch UI scene
    this.scene.launch('UIScene');

    // Set up collisions
    this.setupCollisions();

    // Set up touch controls for mobile
    this.setupTouchControls();

    // Input
    this.cursors = this.input.keyboard.createCursorKeys();
    this.wasd = this.input.keyboard.addKeys({
      up: Phaser.Input.Keyboard.KeyCodes.W,
      down: Phaser.Input.Keyboard.KeyCodes.S,
      left: Phaser.Input.Keyboard.KeyCodes.A,
      right: Phaser.Input.Keyboard.KeyCodes.D,
      jump: Phaser.Input.Keyboard.KeyCodes.X,
      run: Phaser.Input.Keyboard.KeyCodes.SPACE,
      attack: Phaser.Input.Keyboard.KeyCodes.Z
    });

    // Show world intro
    this.showWorldIntro();

    // Pause
    this.input.keyboard.on('keydown-ESC', () => {
      this.scene.launch('PauseScene');
      this.scene.pause();
    });

    // Play level music
    this.playMusic();

    // Initialize coyote time and other player mechanics
    this.coyoteTime = 0;
    this.lastGrounded = false;
  }

  createBackground() {
    const { width, height } = this.levelData;
    const theme = this.worldTheme;

    // Sky gradient using world theme colors
    const skyGradient = this.add.graphics();
    const skyColors = theme.sky || [0x1a0a2e, 0x2a2a4e, 0x3a3a5e, 0x4a4a6e, 0x5a5a7e];
    const stripeHeight = height / skyColors.length;
    skyColors.forEach((color, i) => {
      skyGradient.fillStyle(color);
      skyGradient.fillRect(0, i * stripeHeight, width, stripeHeight + 2);
    });
    skyGradient.setDepth(-110);

    // Animated clouds
    this.clouds = [];
    for (let i = 0; i < 10; i++) {
      const cx = Phaser.Math.Between(-100, width + 100);
      const cy = Phaser.Math.Between(30, 150);
      const cw = Phaser.Math.Between(60, 120);
      const ch = Phaser.Math.Between(25, 40);

      const cloud = this.add.ellipse(cx, cy, cw, ch, 0xffffff, 0.5).setScrollFactor(0.1);
      const speed = 0.02 + Math.random() * 0.03;
      this.clouds.push({ cloud, speed, baseX: cx });
    }

    // Stars for night levels
    if (theme.worldNum >= 5) {
      for (let i = 0; i < 50; i++) {
        const star = this.add.circle(
          Phaser.Math.Between(0, width),
          Phaser.Math.Between(0, height / 3),
          Phaser.Math.Between(1, 2),
          0xffffff, Phaser.Math.FloatBetween(0.3, 0.8)
        ).setScrollFactor(0.05);

        this.tweens.add({
          targets: star, alpha: 0.2,
          duration: Phaser.Math.Between(500, 1500),
          yoyo: true, repeat: -1
        });
      }
    }
  }

  createPlatforms() {
    const ld = this.levelData;
    this.platforms = this.physics.add.staticGroup();

    // Create platforms from level data
    const platformData = ld.platforms || [];

    platformData.forEach(p => {
      const isGround = p.h > 30;

      // Color scheme based on world theme
      const theme = this.worldTheme;
      let baseColor = theme.platformColor || 0x44aa55;
      let topColor = theme.grassColor || 0x66cc77;

      if (isGround) {
        baseColor = theme.groundColor || 0x8B5522;
        topColor = theme.groundTopColor || 0x55aa44;
      }

      // Platform shadow
      this.add.rectangle(p.x + p.w/2 + 4, p.y + p.h/2 + 4, p.w, p.h, 0x000000, 0.25);

      // Platform body
      const plat = this.add.rectangle(p.x + p.w/2, p.y + p.h/2, p.w, p.h, baseColor);
      this.physics.add.existing(plat, true);
      this.platforms.add(plat);

      // Top grass/surface
      this.add.rectangle(p.x + p.w/2, p.y + 2, p.w - 2, 4, topColor);

      // Grass tufts on smaller platforms
      if (!isGround && p.w > 40) {
        for (let gx = p.x + 12; gx < p.x + p.w - 12; gx += 18) {
          const grass = this.add.triangle(gx, p.y, gx - 4, p.y, gx, p.y - 8, gx + 4, p.y, 0x55cc66, 0.9);
          this.tweens.add({
            targets: grass,
            angle: Phaser.Math.Between(-5, 5),
            duration: 1500 + Phaser.Math.Between(0, 500),
            yoyo: true, repeat: -1, ease: 'Sine.easeInOut'
          });
        }
      }
    });
  }

  createTrajineras() {
    // Moving platforms (trajineras - colorful Mexican boats)
    this.trajineras = [];
    const trajineraData = this.levelData.trajineras || [];

    trajineraData.forEach((t, i) => {
      // Create container for boat
      const boat = this.add.container(t.x, t.y);

      // Boat hull colors
      const hullColors = [0xff69b4, 0x4ecdc4, 0x2ecc71, 0xffcc00, 0xff6b6b];
      const hullColor = hullColors[i % hullColors.length];

      // Hull
      const hull = this.add.rectangle(0, 0, t.w, t.h || 25, hullColor);
      boat.add(hull);

      // White trim
      const trim = this.add.rectangle(0, (t.h || 25) / 2 - 2, t.w - 4, 4, 0xffffff, 0.7);
      boat.add(trim);

      // Flowers on top
      const flowerColors = [0xffe66d, 0xff8c00, 0xff1744, 0xff4081];
      for (let fx = -t.w / 2 + 15; fx < t.w / 2 - 10; fx += 20) {
        const flower = this.add.circle(fx, -15, 5, flowerColors[Math.floor(Math.random() * flowerColors.length)]);
        const center = this.add.circle(fx, -15, 2, 0xffff00);
        boat.add(flower);
        boat.add(center);
      }

      // Store trajinera data for physics and animation
      this.trajineras.push({
        container: boat,
        x: t.x,
        y: t.y,
        w: t.w,
        h: t.h || 25,
        startX: t.x,
        endX: t.endX || t.x + 200,
        speed: t.speed || 50,
        dir: t.dir || 1
      });
    });
  }

  createCollectibles() {
    // Cempasuchil flowers (coins)
    this.flowers = this.physics.add.group({ allowGravity: false });

    const coinData = this.levelData.coins || [];
    coinData.forEach(pos => {
      const flower = this.flowers.create(pos.x, pos.y, 'coin')
        .setScale(2);
      flower.body.setSize(12, 12);

      // Gentle floating animation
      this.tweens.add({
        targets: flower, y: pos.y - 5,
        duration: 1000 + Math.random() * 500,
        yoyo: true, repeat: -1, ease: 'Sine.easeInOut'
      });
    });

    // Stars (hidden collectibles)
    this.stars = this.physics.add.group({ allowGravity: false });

    const starData = this.levelData.stars || [];
    starData.forEach((pos, i) => {
      const starId = `${this.levelNum}-${i}`;
      if (!window.gameState.stars.includes(starId)) {
        const star = this.stars.create(pos.x, pos.y, 'star')
          .setScale(2);
        star.starId = starId;
        star.body.setSize(12, 12);

        // Sparkle animation
        this.tweens.add({
          targets: star, angle: 360, scale: 2.2,
          duration: 2000, yoyo: true, repeat: -1
        });
      }
    });

    // Power-ups
    this.powerups = this.physics.add.group();

    const powerupData = this.levelData.powerups || [];
    powerupData.forEach(pos => {
      const powerup = this.powerups.create(pos.x, pos.y, 'mushroom')
        .setScale(2);
      powerup.body.allowGravity = false;

      this.tweens.add({
        targets: powerup, y: pos.y - 8,
        duration: 800, yoyo: true, repeat: -1, ease: 'Sine.easeInOut'
      });
    });
  }

  createEnemies() {
    this.enemies = this.physics.add.group();

    const enemyData = this.levelData.enemies || [];
    enemyData.forEach(enemy => {
      let sprite;
      const type = enemy.type || 'ground';

      if (type === 'flying' || type === 'heron') {
        sprite = new Heron(this, enemy.x, enemy.y);
        if (enemy.amplitude) sprite.setData('amplitude', enemy.amplitude);
        if (enemy.speed) sprite.setData('flySpeed', enemy.speed);
      } else {
        sprite = new Gull(this, enemy.x, enemy.y);
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
    const babyId = `baby-${this.levelNum}`;
    const pos = this.levelData.babyPosition;

    if (!pos) return;

    if (!window.gameState.rescuedBabies.includes(babyId)) {
      this.baby = this.physics.add.sprite(pos.x, pos.y, 'baby-axolotl')
        .setScale(2);
      this.baby.body.allowGravity = false;
      this.baby.babyId = babyId;

      // Floating animation
      this.tweens.add({
        targets: this.baby,
        y: pos.y - 10,
        duration: 1000,
        yoyo: true, repeat: -1, ease: 'Sine.easeInOut'
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
    // Player vs platforms
    this.physics.add.collider(this.player, this.platforms);

    // Enemies vs platforms
    this.physics.add.collider(this.enemies, this.platforms);

    // Player vs flowers (coins)
    this.physics.add.overlap(this.player, this.flowers, this.collectFlower, null, this);

    // Player vs stars
    this.physics.add.overlap(this.player, this.stars, this.collectStar, null, this);

    // Player vs power-ups
    this.physics.add.overlap(this.player, this.powerups, this.collectPowerup, null, this);

    // Player vs enemies
    this.physics.add.overlap(this.player, this.enemies, this.handleEnemyCollision, null, this);

    // Player vs baby
    if (this.baby) {
      this.physics.add.overlap(this.player, this.baby, this.rescueBaby, null, this);
    }
  }

  setupTouchControls() {
    if (!this.sys.game.device.input.touch) return;

    const { width, height } = this.cameras.main;
    const btnSize = 70;
    const btnAlpha = 0.5;
    const margin = 20;

    // Left button
    const leftBtn = this.add.circle(margin + btnSize/2, height - margin - btnSize/2, btnSize/2, 0x4ecdc4, btnAlpha)
      .setScrollFactor(0).setDepth(1000).setInteractive();
    leftBtn.on('pointerdown', () => { this.touchControls.left = true; });
    leftBtn.on('pointerup', () => { this.touchControls.left = false; });
    leftBtn.on('pointerout', () => { this.touchControls.left = false; });

    // Right button
    const rightBtn = this.add.circle(margin + btnSize * 1.8, height - margin - btnSize/2, btnSize/2, 0x4ecdc4, btnAlpha)
      .setScrollFactor(0).setDepth(1000).setInteractive();
    rightBtn.on('pointerdown', () => { this.touchControls.right = true; });
    rightBtn.on('pointerup', () => { this.touchControls.right = false; });
    rightBtn.on('pointerout', () => { this.touchControls.right = false; });

    // Jump button
    const jumpBtn = this.add.circle(width - margin - btnSize/2, height - margin - btnSize/2, btnSize/2, 0xff6b9d, btnAlpha)
      .setScrollFactor(0).setDepth(1000).setInteractive();
    this.add.text(width - margin - btnSize/2, height - margin - btnSize/2, 'JUMP', {
      fontFamily: 'Arial', fontSize: '14px', color: '#fff'
    }).setOrigin(0.5).setScrollFactor(0).setDepth(1001);
    jumpBtn.on('pointerdown', () => { this.touchControls.jump = true; });
    jumpBtn.on('pointerup', () => { this.touchControls.jump = false; });
    jumpBtn.on('pointerout', () => { this.touchControls.jump = false; });
  }

  showWorldIntro() {
    const worldNum = window.getWorldForLevel(this.levelNum);
    const world = window.WORLDS[worldNum];
    const { width: camW, height: camH } = this.cameras.main;

    const overlay = this.add.rectangle(camW/2, camH/2, camW, camH, 0x000000, 0.7)
      .setScrollFactor(0).setDepth(500);

    const worldName = this.add.text(camW/2, camH/2 - 30, world.name.toUpperCase(), {
      fontFamily: 'Arial Black', fontSize: '36px', color: '#ffffff',
      stroke: '#000000', strokeThickness: 4
    }).setOrigin(0.5).setScrollFactor(0).setDepth(501).setAlpha(0);

    const worldSubtitle = this.add.text(camW/2, camH/2 + 15, world.subtitle, {
      fontFamily: 'Arial', fontSize: '20px', color: '#ffcc66',
      stroke: '#000000', strokeThickness: 2, fontStyle: 'italic'
    }).setOrigin(0.5).setScrollFactor(0).setDepth(501).setAlpha(0);

    const levelText = this.add.text(camW/2, camH/2 + 50, `Level ${this.levelNum}`, {
      fontFamily: 'Arial', fontSize: '14px', color: '#aaaaaa'
    }).setOrigin(0.5).setScrollFactor(0).setDepth(501).setAlpha(0);

    // Animate in
    this.tweens.add({
      targets: [worldName, worldSubtitle, levelText],
      alpha: 1, duration: 500, ease: 'Power2'
    });

    // Animate out
    this.time.delayedCall(2000, () => {
      this.tweens.add({
        targets: [overlay, worldName, worldSubtitle, levelText],
        alpha: 0, duration: 500, ease: 'Power2',
        onComplete: () => {
          overlay.destroy();
          worldName.destroy();
          worldSubtitle.destroy();
          levelText.destroy();
        }
      });
    });
  }

  // Ledge grab system
  grabLedge(edgeX, edgeY, side, movingPlatform = null) {
    if (!this.player || !this.player.body) return;
    if (this.player.getData('hanging')) return;
    if (this.player.getData('climbing')) return;

    // Stop movement and disable gravity
    this.player.body.setVelocity(0, 0);
    this.player.body.allowGravity = false;

    // Enter climbing state
    this.player.setData('climbing', true);
    this.player.setData('grabCooldown', 400);
    this.player.setFlipX(side === 'right');

    // Particle burst for feedback
    for (let i = 0; i < 3; i++) {
      const spark = this.add.circle(
        edgeX + (Math.random() - 0.5) * 15,
        edgeY + 5,
        2 + Math.random() * 2, 0xffffff, 0.8
      );
      this.tweens.add({
        targets: spark, y: spark.y - 15, alpha: 0, scale: 0,
        duration: 250, onComplete: () => spark.destroy()
      });
    }

    // Snap to edge
    this.player.setPosition(
      side === 'left' ? edgeX - 8 : edgeX + 8,
      edgeY + 10
    );

    // Auto-climb animation
    this.tweens.add({
      targets: this.player,
      x: edgeX + (side === 'left' ? 10 : -10),
      y: edgeY - 10,
      duration: 80,
      ease: 'Power2.easeOut',
      onComplete: () => {
        const targetX = edgeX + (side === 'left' ? 30 : -30);
        const targetY = edgeY - 35;

        this.tweens.add({
          targets: this.player,
          x: targetX, y: targetY,
          duration: 100,
          ease: 'Sine.easeOut',
          onComplete: () => {
            this.player.body.allowGravity = true;
            this.player.setData('climbing', false);
            this.player.body.setVelocityY(50);
            this.playSound('sfx-jump');
          }
        });
      }
    });
  }

  collectFlower(player, flower) {
    const fx = flower.x;
    const fy = flower.y;
    flower.destroy();

    window.gameState.flowers = (window.gameState.flowers || 0) + 1;
    window.gameState.score += 10;

    this.playSound('sfx-coin');
    this.showFloatingText(fx, fy - 20, '+10', '#ff8c00');
    this.events.emit('updateUI');

    // Petal particles
    for (let i = 0; i < 8; i++) {
      const angle = (i / 8) * Math.PI * 2;
      const petal = this.add.ellipse(fx, fy, 6, 4, 0xff8c00);
      this.tweens.add({
        targets: petal,
        x: fx + Math.cos(angle) * 40,
        y: fy + Math.sin(angle) * 30 + 20,
        alpha: 0, scale: 0.3,
        duration: 400, ease: 'Quad.easeOut',
        onComplete: () => petal.destroy()
      });
    }

    // Super jump every 10 flowers
    if (window.gameState.flowers % 10 === 0) {
      window.gameState.superJumps++;
      this.showMessage('+1 SUPER JUMP!', '#00ffff');
    }

    // Extra life at 100
    if (window.gameState.flowers >= 100) {
      window.gameState.flowers -= 100;
      window.gameState.lives++;
      this.showMessage('1UP!', '#ff8c00');
    }
  }

  collectStar(player, star) {
    window.gameState.stars.push(star.starId);
    window.gameState.score += 500;
    star.destroy();

    this.playSound('sfx-star');
    this.showMessage('Star Found!', '#ffe66d');
    this.events.emit('updateUI');
    window.saveGame();

    // Big sparkle effect
    for (let i = 0; i < 12; i++) {
      this.addSparkle(star.x + Phaser.Math.Between(-30, 30), star.y + Phaser.Math.Between(-30, 30));
    }
  }

  collectPowerup(player, powerup) {
    powerup.destroy();
    window.gameState.superJumps++;
    window.gameState.maceAttacks = (window.gameState.maceAttacks || 0) + 1;

    this.playSound('sfx-powerup');
    this.showMessage('+1 JUMP! +1 ATTACK!', '#00ffff');
    this.events.emit('updateUI');
  }

  handleEnemyCollision(player, enemy) {
    if (player.getData('invincible')) return;

    // Check if stomping
    if (player.body.velocity.y > 0 && player.body.bottom < enemy.body.center.y) {
      enemy.stomp();
      player.bounce();
      this.playSound('sfx-stomp');
      window.gameState.score += 100;
      this.showFloatingText(enemy.x, enemy.y - 20, '+100', '#fff');
    } else {
      player.takeDamage();
      this.playSound('sfx-hurt');
    }
  }

  rescueBaby(player, baby) {
    window.gameState.rescuedBabies.push(baby.babyId);
    window.gameState.score += 1000;
    baby.destroy();
    this.baby = null;

    this.playSound('sfx-rescue');
    this.showMessage('Baby Rescued!', '#ff6b9d');

    // Celebration particles
    for (let i = 0; i < 20; i++) {
      this.time.delayedCall(i * 50, () => {
        this.addSparkle(
          player.x + Phaser.Math.Between(-50, 50),
          player.y + Phaser.Math.Between(-50, 50)
        );
      });
    }

    window.saveGame();

    this.time.delayedCall(2000, () => {
      this.completeLevel();
    });
  }

  completeLevel() {
    const nextLevel = this.levelNum + 1;

    if (nextLevel > window.gameState.totalLevels) {
      this.scene.stop('UIScene');
      this.scene.start('StoryScene', { type: 'ending' });
    } else {
      window.gameState.currentLevel = nextLevel;
      window.saveGame();

      // World transitions
      if (nextLevel === 3 || nextLevel === 5 || nextLevel === 6 || nextLevel === 8 || nextLevel === 10) {
        this.scene.stop('UIScene');
        this.scene.start('StoryScene', { type: 'world' + window.getWorldForLevel(nextLevel), nextLevel });
      } else {
        this.scene.restart({ level: nextLevel });
      }
    }
  }

  update(time, delta) {
    if (!this.player || this.player.getData('dead')) return;

    // Track if player can move
    const playerCanMove = !this.player.getData('climbing') && !this.player.getData('hanging');

    // Update trajineras (moving platforms)
    this.trajineras.forEach(t => {
      t.x += t.speed * t.dir * (delta / 1000);

      // Reverse at boundaries
      if (t.x >= t.endX) {
        t.x = t.endX;
        t.dir = -1;
      } else if (t.x <= t.startX) {
        t.x = t.startX;
        t.dir = 1;
      }

      t.container.x = t.x;
    });

    // Update grab cooldown
    const grabCooldown = this.player.getData('grabCooldown') || 0;
    if (grabCooldown > 0) {
      this.player.setData('grabCooldown', grabCooldown - delta);
    }

    // Ledge grab detection
    if (playerCanMove && grabCooldown <= 0) {
      const isFalling = this.player.body.velocity.y > 100;
      const pressingLeft = this.cursors.left.isDown || this.wasd.left.isDown || this.touchControls.left;
      const pressingRight = this.cursors.right.isDown || this.wasd.right.isDown || this.touchControls.right;

      if (isFalling && (pressingLeft || pressingRight) && !this.player.getData('swimming')) {
        this.checkLedgeGrab(pressingLeft, pressingRight);
      }
    }

    // Update player
    if (playerCanMove) {
      this.player.update(this.cursors, this.wasd, this.touchControls);
    }

    // Coyote time
    const onGround = this.player.body.blocked.down || this.player.body.touching.down;
    if (onGround) {
      this.coyoteTime = 150;
    }
    if (this.coyoteTime > 0) this.coyoteTime -= delta;

    // Update enemies
    this.enemies.getChildren().forEach(enemy => {
      if (enemy.update) enemy.update();
    });

    // Cloud animation
    if (this.clouds) {
      this.clouds.forEach(c => {
        c.cloud.x += c.speed;
        if (c.cloud.x > this.levelData.width + 100) {
          c.cloud.x = -100;
        }
      });
    }

    // Death check
    if (this.player.y > this.levelData.height + 100) {
      this.playerDeath();
    }
  }

  checkLedgeGrab(pressingLeft, pressingRight) {
    const grabRange = 45;
    const playerBounds = this.player.getBounds();
    let grabbed = false;

    // Check trajineras first
    this.trajineras.forEach(t => {
      if (grabbed) return;

      const trajLeft = t.x - t.w / 2;
      const trajRight = t.x + t.w / 2;
      const trajTop = t.y - t.h / 2;

      const heightMatch = playerBounds.top > trajTop - grabRange && playerBounds.top < trajTop + grabRange;

      if (heightMatch) {
        if (pressingRight && Math.abs(playerBounds.right - trajLeft) < grabRange) {
          this.grabLedge(trajLeft, trajTop, 'left', t);
          grabbed = true;
        } else if (pressingLeft && Math.abs(playerBounds.left - trajRight) < grabRange) {
          this.grabLedge(trajRight, trajTop, 'right', t);
          grabbed = true;
        }
      }
    });

    // Check static platforms
    if (!grabbed) {
      this.platforms.getChildren().forEach(plat => {
        if (grabbed) return;

        const platLeft = plat.x - plat.width / 2;
        const platRight = plat.x + plat.width / 2;
        const platTop = plat.y - plat.height / 2;

        const heightMatch = playerBounds.top > platTop - grabRange && playerBounds.top < platTop + grabRange;

        if (heightMatch) {
          if (pressingRight && Math.abs(playerBounds.right - platLeft) < grabRange) {
            this.grabLedge(platLeft, platTop, 'left');
            grabbed = true;
          } else if (pressingLeft && Math.abs(playerBounds.left - platRight) < grabRange) {
            this.grabLedge(platRight, platTop, 'right');
            grabbed = true;
          }
        }
      });
    }
  }

  playerDeath() {
    if (this.player.getData('dead')) return;

    this.player.die();
    window.gameState.lives--;

    if (window.gameState.lives <= 0) {
      this.time.delayedCall(2000, () => {
        window.gameState.lives = window.DIFFICULTY_SETTINGS[window.gameState.difficulty].lives;
        window.gameState.flowers = 0;
        this.scene.stop('UIScene');
        this.scene.start('MenuScene');
      });
    } else {
      this.time.delayedCall(1500, () => {
        this.scene.restart({ level: this.levelNum });
      });
    }
  }

  playMusic() {
    this.sound.stopAll();

    if (window.gameState.musicEnabled) {
      let musicKey = 'music-gardens';
      const worldNum = window.getWorldForLevel(this.levelNum);

      // Special level type music overrides
      const isUpscroller = (this.levelNum === 3 || this.levelNum === 8);

      if (isUpscroller) {
        // Upscroller levels get their own high-energy track
        musicKey = 'music-upscroller';
      }
      // World 1 (levels 1-2): Gardens
      else if (worldNum === 1) {
        musicKey = 'music-gardens';
      }
      // World 2-4 (levels 3-7): Middle levels (menu music/ruins)
      else if (worldNum >= 2 && worldNum <= 4) {
        musicKey = 'music-ruins';
      }
      // World 5 (levels 8-9): Night
      else if (worldNum === 5) {
        musicKey = 'music-caves';
      }
      // World 6 (level 10): Fiesta/Final
      else if (worldNum === 6) {
        musicKey = 'music-fiesta';
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
      fontFamily: 'Arial Black', fontSize: '36px', color: color,
      stroke: '#000', strokeThickness: 6
    }).setOrigin(0.5).setScrollFactor(0).setDepth(100);

    this.tweens.add({
      targets: msg,
      y: height / 3 - 50, alpha: 0, scale: 1.5,
      duration: 1500, ease: 'Power2',
      onComplete: () => msg.destroy()
    });
  }

  showFloatingText(x, y, text, color) {
    const floatText = this.add.text(x, y, text, {
      fontFamily: 'Arial', fontSize: '16px', color: color
    }).setOrigin(0.5);

    this.tweens.add({
      targets: floatText,
      y: y - 30, alpha: 0,
      duration: 800,
      onComplete: () => floatText.destroy()
    });
  }

  addSparkle(x, y) {
    const colors = [0xffe66d, 0xff6b9d, 0x4ecdc4];
    const sparkle = this.add.circle(x, y, 4, Phaser.Utils.Array.GetRandom(colors));

    this.tweens.add({
      targets: sparkle,
      alpha: 0, scale: 2,
      duration: 500,
      onComplete: () => sparkle.destroy()
    });
  }
}

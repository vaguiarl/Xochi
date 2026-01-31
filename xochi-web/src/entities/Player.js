import Phaser from 'phaser';

export default class Player extends Phaser.Physics.Arcade.Sprite {
  constructor(scene, x, y) {
    super(scene, x, y, 'xochi');

    this.scene = scene;

    // Player state
    this.isBig = false;
    this.isDead = false;
    this.canJump = true;
    this.isJumping = false;
    this.jumpHeld = false;
    this.jumpTimer = 0;

    // Movement settings
    this.moveSpeed = 200;
    this.runSpeed = 320;
    this.jumpForce = -400;
    this.jumpHoldForce = -50;
    this.maxJumpTime = 200; // ms

    // Set up sprite
    this.setScale(2);
    this.play('xochi-idle');

    // Physics body
    scene.physics.add.existing(this);
    this.body.setSize(14, 14);
    this.body.setOffset(1, 2);
    this.setCollideWorldBounds(true);

    // Track facing direction
    this.facing = 'right';

    // Initialize data properties for state tracking
    this.setData('invincible', false);
    this.setData('big', false);
    this.setData('swimming', false);
    this.setData('hanging', false);
    this.setData('climbing', false);
    this.setData('grabCooldown', 0);
    this.setData('dead', false);
    this.setData('attacking', false);
    this.setData('superJumpReady', false);

    // Coyote time tracking (handled by GameScene)
    this.coyoteTime = 0;
  }

  update(cursors, wasd, touchControls = {}) {
    if (this.isDead || this.getData('dead')) return;
    if (this.getData('climbing') || this.getData('hanging')) return;

    const onGround = this.body.onFloor() || this.body.blocked.down || this.body.touching.down;
    const isRunning = wasd.run?.isDown || touchControls.sprint;
    const speed = isRunning ? this.runSpeed : this.moveSpeed;

    // Horizontal movement
    let moving = false;
    const pressingLeft = cursors.left.isDown || wasd.left?.isDown || touchControls.left;
    const pressingRight = cursors.right.isDown || wasd.right?.isDown || touchControls.right;

    if (pressingLeft) {
      this.body.setVelocityX(-speed);
      this.facing = 'left';
      this.setFlipX(true);
      moving = true;
    } else if (pressingRight) {
      this.body.setVelocityX(speed);
      this.facing = 'right';
      this.setFlipX(false);
      moving = true;
    } else {
      // Deceleration
      this.body.setVelocityX(this.body.velocity.x * 0.85);
      if (Math.abs(this.body.velocity.x) < 10) {
        this.body.setVelocityX(0);
      }
    }

    // Jumping
    const jumpKey = cursors.up.isDown || wasd.jump?.isDown || wasd.up?.isDown || touchControls.jump;

    // Check coyote time from scene
    const canJumpWithCoyote = onGround || (this.scene.coyoteTime && this.scene.coyoteTime > 0);

    if (jumpKey && canJumpWithCoyote && this.canJump && !this.isJumping) {
      // Start jump
      this.body.setVelocityY(this.jumpForce);
      this.isJumping = true;
      this.jumpHeld = true;
      this.jumpTimer = 0;
      this.canJump = false;

      // Reset coyote time
      if (this.scene.coyoteTime) this.scene.coyoteTime = 0;

      // Play jump sound
      if (window.gameState.sfxEnabled) {
        this.scene.sound.play('sfx-jump', { volume: 0.5 });
      }

      // Jump particles
      this.createJumpParticles();
    }

    // Variable jump height - hold for higher
    if (jumpKey && this.isJumping && this.jumpHeld) {
      this.jumpTimer += this.scene.game.loop.delta;
      if (this.jumpTimer < this.maxJumpTime && this.body.velocity.y < 0) {
        this.body.setVelocityY(this.body.velocity.y + this.jumpHoldForce * (this.scene.game.loop.delta / 1000) * 60);
      }
    }

    // Release jump
    if (!jumpKey) {
      this.jumpHeld = false;
      if (onGround) {
        this.canJump = true;
        this.isJumping = false;
      }
    }

    // Reset jump when landing and play landing sound
    if (onGround && !jumpKey) {
      if (this.isJumping && Math.abs(this.body.velocity.y) > 50) {
        // Play landing sound when coming from a significant height
        if (window.gameState.sfxEnabled) {
          this.scene.sound.play('sfx-land', { volume: 0.4 });
        }
      }
      this.isJumping = false;
      this.canJump = true;
    }

    // Super Jump (Z key or touch)
    const superJumpKey = wasd.attack?.isDown || touchControls.superJump;
    if (superJumpKey && window.gameState.superJumps > 0 && onGround && !this.getData('superJumpCooldown')) {
      this.performSuperJump();
    }

    // Animation
    this.updateAnimation(moving, onGround);

    // Invincibility flicker
    if (this.getData('invincible')) {
      this.setAlpha(Math.sin(this.scene.time.now / 50) > 0 ? 1 : 0.3);
    }
  }

  performSuperJump() {
    window.gameState.superJumps--;
    this.body.setVelocityY(-650);
    this.isJumping = true;
    this.setData('superJumpCooldown', true);

    if (window.gameState.sfxEnabled) {
      this.scene.sound.play('sfx-super-jump', { volume: 0.5 });
    }

    // Show text feedback
    if (this.scene.showMessage) {
      this.scene.showMessage('SUPER!', '#00ffff');
    }

    // Visual burst
    for (let i = 0; i < 8; i++) {
      const angle = (i / 8) * Math.PI * 2;
      const trail = this.scene.add.circle(
        this.x + Math.cos(angle) * 10,
        this.y + Math.sin(angle) * 10,
        6, 0x00ffff, 0.8
      );
      this.scene.tweens.add({
        targets: trail,
        x: this.x + Math.cos(angle) * 40,
        y: this.y + Math.sin(angle) * 40,
        alpha: 0, scale: 0.5, duration: 300,
        onComplete: () => trail.destroy()
      });
    }

    // Reset cooldown after landing
    this.scene.time.delayedCall(500, () => {
      this.setData('superJumpCooldown', false);
    });

    // Update UI
    if (this.scene.events) {
      this.scene.events.emit('updateUI');
    }
  }

  createJumpParticles() {
    for (let i = 0; i < 4; i++) {
      const dust = this.scene.add.circle(
        this.x + (Math.random() - 0.5) * 20,
        this.y + 15,
        3 + Math.random() * 2,
        0xcccccc, 0.6
      );
      this.scene.tweens.add({
        targets: dust,
        y: dust.y + 10,
        alpha: 0,
        scale: 0.3,
        duration: 200,
        onComplete: () => dust.destroy()
      });
    }
  }

  updateAnimation(moving, onGround) {
    const prefix = this.isBig ? 'xochi-big-' : 'xochi-';

    if (this.getData('climbing')) {
      // Don't change animation during climb
      return;
    }

    if (!onGround) {
      this.play(prefix + 'jump', true);
    } else if (moving) {
      this.play(prefix + 'run', true);
    } else {
      this.play(prefix + 'idle', true);
    }
  }

  powerUp() {
    if (this.isBig) return;

    this.isBig = true;
    this.setData('big', true);
    this.setTexture('xochi-big');
    this.setScale(2);
    this.body.setSize(14, 28);
    this.body.setOffset(1, 4);

    // Brief invincibility
    this.setInvincible(1500);

    // Growth effect
    this.scene.tweens.add({
      targets: this,
      scaleX: 2.5,
      scaleY: 2.5,
      duration: 100,
      yoyo: true,
      repeat: 2
    });
  }

  takeDamage() {
    if (this.getData('invincible')) return;

    if (this.isBig) {
      // Shrink back to small
      this.isBig = false;
      this.setData('big', false);
      this.setTexture('xochi');
      this.setScale(2);
      this.body.setSize(14, 14);
      this.body.setOffset(1, 2);
      this.setInvincible(2000);
    } else {
      // Die
      if (this.scene.playerDeath) {
        this.scene.playerDeath();
      }
    }
  }

  setInvincible(duration) {
    this.setData('invincible', true);
    this.scene.time.delayedCall(duration, () => {
      this.setData('invincible', false);
      this.setAlpha(1);
    });
  }

  bounce() {
    this.body.setVelocityY(-250);
    this.isJumping = true;
  }

  die() {
    if (this.isDead) return;

    this.isDead = true;
    this.setData('dead', true);
    this.body.setVelocity(0, -300);
    this.body.setAllowGravity(true);
    this.body.checkCollision.none = true;

    // Death animation
    this.setFlipY(true);

    this.scene.tweens.add({
      targets: this,
      rotation: Math.PI * 2,
      duration: 1000
    });
  }

  // Reset player state for respawn
  reset(x, y) {
    this.setPosition(x, y);
    this.isDead = false;
    this.setData('dead', false);
    this.setData('invincible', false);
    this.setData('climbing', false);
    this.setData('hanging', false);
    this.setData('grabCooldown', 0);
    this.body.setVelocity(0, 0);
    this.body.checkCollision.none = false;
    this.setFlipY(false);
    this.rotation = 0;
    this.setAlpha(1);
    this.isJumping = false;
    this.canJump = true;
  }
}

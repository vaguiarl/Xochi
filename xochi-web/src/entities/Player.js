import Phaser from 'phaser';

export default class Player extends Phaser.Physics.Arcade.Sprite {
  constructor(scene, x, y) {
    super(scene, x, y, 'xochi');

    this.scene = scene;

    // Player state
    this.isBig = false;
    this.isInvincible = false;
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
  }

  update(cursors, wasd) {
    if (this.isDead) return;

    const onGround = this.body.onFloor();
    const isRunning = wasd.run.isDown;
    const speed = isRunning ? this.runSpeed : this.moveSpeed;

    // Horizontal movement
    let moving = false;

    if (cursors.left.isDown || wasd.left.isDown) {
      this.body.setVelocityX(-speed);
      this.facing = 'left';
      this.setFlipX(true);
      moving = true;
    } else if (cursors.right.isDown || wasd.right.isDown) {
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
    const jumpKey = cursors.up.isDown || cursors.space.isDown || wasd.jump.isDown || wasd.up.isDown;

    if (jumpKey && onGround && this.canJump && !this.isJumping) {
      // Start jump
      this.body.setVelocityY(this.jumpForce);
      this.isJumping = true;
      this.jumpHeld = true;
      this.jumpTimer = 0;
      this.canJump = false;

      // Play jump sound
      if (window.gameState.sfxEnabled) {
        this.scene.sound.play('sfx-jump', { volume: 0.5 });
      }
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

    // Reset jump when landing
    if (onGround && !jumpKey) {
      this.isJumping = false;
      this.canJump = true;
    }

    // Animation
    this.updateAnimation(moving, onGround);

    // Invincibility flicker
    if (this.isInvincible) {
      this.setAlpha(Math.sin(this.scene.time.now / 50) > 0 ? 1 : 0.3);
    }
  }

  updateAnimation(moving, onGround) {
    const prefix = this.isBig ? 'xochi-big-' : 'xochi-';

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
    if (this.isInvincible) return;

    if (this.isBig) {
      // Shrink back to small
      this.isBig = false;
      this.setTexture('xochi');
      this.setScale(2);
      this.body.setSize(14, 14);
      this.body.setOffset(1, 2);
      this.setInvincible(2000);
    } else {
      // Die
      this.scene.playerDeath();
    }
  }

  setInvincible(duration) {
    this.isInvincible = true;
    this.scene.time.delayedCall(duration, () => {
      this.isInvincible = false;
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
}

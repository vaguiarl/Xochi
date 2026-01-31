import Phaser from 'phaser';

export default class Heron extends Phaser.Physics.Arcade.Sprite {
  constructor(scene, x, y) {
    super(scene, x, y, 'heron');

    this.scene = scene;

    // State
    this.isAlive = true;
    this.isShell = false;
    this.isMovingShell = false;
    this.direction = Phaser.Math.Between(0, 1) ? 1 : -1;
    this.walkSpeed = 40;
    this.shellSpeed = 300;
    this.shellRecoverTime = 5000;

    // Flying behavior (set via setData in GameScene)
    this.isFlying = false;
    this.flySpeed = 60;
    this.amplitude = 50;
    this.baseY = y;

    // Set up sprite
    this.setScale(2);
    this.play('heron-walk');

    // Physics
    scene.physics.add.existing(this);
    this.body.setSize(15, 28);
    this.body.setOffset(1, 4);
    this.body.setBounce(0);

    // Check if this is a flying enemy
    if (this.getData('amplitude') || this.getData('flySpeed')) {
      this.initFlying();
    } else {
      // Start moving on ground
      this.body.setVelocityX(this.walkSpeed * this.direction);
    }

    this.setFlipX(this.direction > 0);
  }

  initFlying() {
    this.isFlying = true;
    this.amplitude = this.getData('amplitude') || 50;
    this.flySpeed = this.getData('flySpeed') || 60;
    this.baseY = this.y;
    this.body.allowGravity = false;
    this.body.setVelocityX(this.flySpeed * this.direction);
  }

  update() {
    if (!this.isAlive) return;

    if (this.isFlying) {
      // Flying sine wave movement
      const time = this.scene.time.now / 1000;
      this.y = this.baseY + Math.sin(time * 2) * this.amplitude;

      // Turn around at level edges
      if (this.x < 100 || this.x > this.scene.levelData.width - 100) {
        this.direction *= -1;
        this.body.setVelocityX(this.flySpeed * this.direction);
        this.setFlipX(this.direction > 0);
      }
    } else {
      // Ground movement - turn around at walls
      if ((this.body.blocked.left || this.body.blocked.right) && !this.isShell) {
        this.turn();
      }

      // Shell bouncing off walls
      if (this.isMovingShell && (this.body.blocked.left || this.body.blocked.right)) {
        this.direction *= -1;
        this.body.setVelocityX(this.shellSpeed * this.direction);
      }
    }
  }

  turn() {
    this.direction *= -1;
    this.body.setVelocityX(this.walkSpeed * this.direction);
    this.setFlipX(this.direction > 0);
  }

  stomp() {
    if (!this.isAlive) return;

    if (this.isFlying) {
      // Flying enemies die on stomp
      this.die();
      return;
    }

    if (!this.isShell) {
      // First stomp - go into shell
      this.enterShell();
    } else if (!this.isMovingShell) {
      // Second stomp - kick the shell
      this.kickShell();
    }
  }

  die() {
    this.isAlive = false;
    this.body.setVelocity(0, 200);
    this.body.allowGravity = true;
    this.body.checkCollision.none = true;
    this.setFlipY(true);

    this.scene.tweens.add({
      targets: this,
      alpha: 0,
      duration: 500,
      onComplete: () => this.destroy()
    });
  }

  enterShell() {
    this.isShell = true;
    this.isMovingShell = false;
    this.body.setVelocity(0, 0);
    this.play('heron-shell');

    // Shrink hitbox for shell
    this.body.setSize(15, 16);
    this.body.setOffset(1, 16);

    // Start recovery timer
    this.shellTimer = this.scene.time.delayedCall(this.shellRecoverTime, () => {
      this.exitShell();
    });

    // Wobble animation to show it's about to recover
    this.scene.time.delayedCall(this.shellRecoverTime - 1500, () => {
      if (this.isShell && !this.isMovingShell) {
        this.scene.tweens.add({
          targets: this,
          angle: 5,
          duration: 100,
          yoyo: true,
          repeat: 7
        });
      }
    });
  }

  exitShell() {
    if (!this.isShell || this.isMovingShell) return;

    this.isShell = false;
    this.play('heron-walk');
    this.body.setSize(15, 28);
    this.body.setOffset(1, 4);
    this.body.setVelocityX(this.walkSpeed * this.direction);
    this.setAngle(0);
  }

  kickShell() {
    // Cancel recovery timer
    if (this.shellTimer) {
      this.shellTimer.remove();
    }

    this.isMovingShell = true;

    // Kick in direction player was facing
    const player = this.scene.player;
    this.direction = player.x < this.x ? 1 : -1;
    this.body.setVelocityX(this.shellSpeed * this.direction);
  }

  hitByShell() {
    // When hit by another moving shell
    if (!this.isAlive) return;

    this.isAlive = false;
    this.body.setVelocity(100 * -this.direction, -200);
    this.setFlipY(true);

    this.scene.time.delayedCall(1000, () => {
      this.destroy();
    });
  }
}

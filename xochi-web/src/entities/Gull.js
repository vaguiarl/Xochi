import Phaser from 'phaser';

export default class Gull extends Phaser.Physics.Arcade.Sprite {
  constructor(scene, x, y) {
    super(scene, x, y, 'gull');

    this.scene = scene;

    // State
    this.isAlive = true;
    this.direction = Phaser.Math.Between(0, 1) ? 1 : -1;
    this.speed = 60;

    // Set up sprite
    this.setScale(2);
    this.play('gull-walk');

    // Physics
    scene.physics.add.existing(this);
    this.body.setSize(14, 14);
    this.body.setOffset(1, 2);
    this.body.setBounce(0);

    // Start moving
    this.body.setVelocityX(this.speed * this.direction);

    // Flip based on direction
    this.setFlipX(this.direction > 0);
  }

  update() {
    if (!this.isAlive) return;

    // Turn around at walls or edges
    if (this.body.blocked.left || this.body.blocked.right) {
      this.turn();
    }

    // Edge detection (optional - for smarter AI)
    // Could add ray casting to detect edges
  }

  turn() {
    this.direction *= -1;
    this.body.setVelocityX(this.speed * this.direction);
    this.setFlipX(this.direction > 0);
  }

  stomp() {
    if (!this.isAlive) return;

    this.isAlive = false;
    this.body.setVelocity(0, 0);
    this.body.setAllowGravity(false);
    this.body.checkCollision.none = true;

    // Flat animation
    this.play('gull-dead');
    this.setScale(2, 1);

    // Disappear after a moment
    this.scene.time.delayedCall(500, () => {
      this.scene.tweens.add({
        targets: this,
        alpha: 0,
        duration: 300,
        onComplete: () => this.destroy()
      });
    });
  }
}

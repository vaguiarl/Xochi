import Phaser from 'phaser';

export default class StoryScene extends Phaser.Scene {
  constructor() {
    super('StoryScene');
  }

  init(data) {
    this.storyType = data.type || 'intro';
    this.nextLevel = data.nextLevel || 1;
  }

  create() {
    const { width, height } = this.cameras.main;
    this.cameras.main.setBackgroundColor('#1a1a2e');

    this.currentSlide = 0;

    // Define story content based on type
    this.slides = this.getStorySlides();

    // Story container
    this.storyContainer = this.add.container(width / 2, height / 2);

    // Show first slide
    this.showSlide(0);

    // Skip/Continue instruction
    this.add.text(width / 2, height - 40, 'Click or Press Space to Continue', {
      fontFamily: 'Arial',
      fontSize: '16px',
      color: '#888'
    }).setOrigin(0.5);

    // Input handlers
    this.input.on('pointerdown', () => this.nextSlide());
    this.input.keyboard.on('keydown-SPACE', () => this.nextSlide());
  }

  getStorySlides() {
    const stories = {
      intro: [
        {
          text: "In the magical waters of Xochimilco lived a happy little axolotl named Xochi...",
          color: '#4ecdc4'
        },
        {
          text: "Xochi loved swimming with her five baby axolotl friends through the floating gardens.",
          color: '#ff6b9d'
        },
        {
          text: "But one day, a terrible storm swept through the canals!",
          color: '#ff6b6b'
        },
        {
          text: "The wind scattered the baby axolotls across distant lands...",
          color: '#ffe66d'
        },
        {
          text: "Now Xochi must brave the Floating Gardens, Ancient Ruins, and Crystal Caves to rescue her friends!",
          color: '#4ecdc4'
        },
        {
          text: "Help Xochi on her adventure!",
          color: '#ff6b9d',
          isLast: true
        }
      ],
      world2: [
        {
          text: "Xochi found two of her friends! But there are more to rescue...",
          color: '#4ecdc4'
        },
        {
          text: "The ancient ruins hold more secrets... and more danger!",
          color: '#ffe66d'
        },
        {
          text: "Be brave, Xochi!",
          color: '#ff6b9d',
          isLast: true
        }
      ],
      world3: [
        {
          text: "Only one baby axolotl remains!",
          color: '#4ecdc4'
        },
        {
          text: "Deep in the Crystal Caves, a great challenge awaits...",
          color: '#ffe66d'
        },
        {
          text: "This is it, Xochi! Time to bring everyone home!",
          color: '#ff6b9d',
          isLast: true
        }
      ],
      ending: [
        {
          text: "You did it!",
          color: '#ffe66d'
        },
        {
          text: "All five baby axolotls are safe and sound!",
          color: '#4ecdc4'
        },
        {
          text: "The friends swam together back to the magical waters of Xochimilco...",
          color: '#ff6b9d'
        },
        {
          text: "And they all lived happily ever after!",
          color: '#4ecdc4'
        },
        {
          text: "THE END\n\nThank you for playing!",
          color: '#ffe66d',
          isLast: true,
          isEnding: true
        }
      ]
    };

    return stories[this.storyType] || stories.intro;
  }

  showSlide(index) {
    // Clear previous content
    this.storyContainer.removeAll(true);

    const slide = this.slides[index];
    const { width, height } = this.cameras.main;

    // Story text with typewriter effect
    const storyText = this.add.text(0, 0, '', {
      fontFamily: 'Georgia',
      fontSize: '28px',
      color: slide.color,
      align: 'center',
      wordWrap: { width: 600 }
    }).setOrigin(0.5);

    this.storyContainer.add(storyText);

    // Typewriter effect
    let charIndex = 0;
    const fullText = slide.text;

    this.typewriterTimer = this.time.addEvent({
      delay: 40,
      callback: () => {
        charIndex++;
        storyText.setText(fullText.substring(0, charIndex));

        if (charIndex >= fullText.length) {
          this.typewriterTimer.remove();
        }
      },
      repeat: fullText.length - 1
    });

    // Add decorative elements
    this.addDecorations(slide);
  }

  addDecorations(slide) {
    // Add sparkle particles around the text
    for (let i = 0; i < 8; i++) {
      const angle = (i / 8) * Math.PI * 2;
      const radius = 200;
      const x = Math.cos(angle) * radius;
      const y = Math.sin(angle) * radius;

      const sparkle = this.add.circle(x, y, 4,
        Phaser.Display.Color.HexStringToColor(slide.color).color, 0.6);

      this.storyContainer.add(sparkle);

      this.tweens.add({
        targets: sparkle,
        alpha: 0.2,
        scale: 1.5,
        duration: 1000,
        yoyo: true,
        repeat: -1,
        delay: i * 100
      });
    }
  }

  nextSlide() {
    // Stop typewriter if still running
    if (this.typewriterTimer) {
      this.typewriterTimer.remove();
    }

    this.currentSlide++;

    if (this.currentSlide >= this.slides.length) {
      // Story finished
      const lastSlide = this.slides[this.slides.length - 1];

      if (lastSlide.isEnding) {
        this.scene.start('EndScene');
      } else {
        this.scene.start('GameScene', { level: this.nextLevel });
      }
    } else {
      // Transition to next slide
      this.cameras.main.fadeOut(300, 0, 0, 0);

      this.time.delayedCall(300, () => {
        this.showSlide(this.currentSlide);
        this.cameras.main.fadeIn(300);
      });
    }
  }
}

// Xochi - Aztec Warrior Adventure
// A Phaser 3 platformer game

// ============== LA CUCARACHA MUSIC ==============
class MariachiMusic {
  constructor() {
    this.audioCtx = null;
    this.isPlaying = false;
    this.timeoutIds = [];
    this.gainNode = null;
  }

  start() {
    if (this.isPlaying) return;
    this.audioCtx = new (window.AudioContext || window.webkitAudioContext)();
    this.gainNode = this.audioCtx.createGain();
    this.gainNode.gain.value = 0.22; // Reduced volume for less noise
    this.gainNode.connect(this.audioCtx.destination);
    this.isPlaying = true;
    this.playLaCucaracha();
  }

  stop() {
    this.isPlaying = false;
    this.timeoutIds.forEach(id => clearTimeout(id));
    this.timeoutIds = [];
    if (this.audioCtx) {
      this.audioCtx.close();
      this.audioCtx = null;
    }
  }

  // La Cucaracha melody in C major
  // Notes: C4=262, D4=294, E4=330, F4=349, G4=392, A4=440, B4=494, C5=523
  playLaCucaracha() {
    const C4 = 262, D4 = 294, E4 = 330, F4 = 349, G4 = 392, A4 = 440, C5 = 523;
    const C3 = 131, G3 = 196, F3 = 175, E3 = 165;

    // La Cucaracha melody - the famous tune!
    // "La cu-ca-ra-cha, la cu-ca-ra-cha, ya no pue-de ca-mi-nar..."
    const melody = [
      // "La cu-ca-" (pickup)
      { note: C4, dur: 0.15 }, { note: C4, dur: 0.15 }, { note: C4, dur: 0.15 },
      // "ra-cha, la cu-ca-"
      { note: F4, dur: 0.4 }, { note: A4, dur: 0.3 },
      { note: C4, dur: 0.15 }, { note: C4, dur: 0.15 }, { note: C4, dur: 0.15 },
      // "ra-cha, la cu-ca-"
      { note: F4, dur: 0.4 }, { note: A4, dur: 0.3 },
      { note: C4, dur: 0.15 }, { note: C4, dur: 0.15 }, { note: C4, dur: 0.15 },
      // "ra-cha"
      { note: F4, dur: 0.3 }, { note: A4, dur: 0.2 },
      // "ya no"
      { note: F4, dur: 0.2 }, { note: E4, dur: 0.2 },
      // "pue-de ca-mi-nar"
      { note: D4, dur: 0.2 }, { note: D4, dur: 0.2 },
      { note: E4, dur: 0.2 }, { note: F4, dur: 0.2 },
      { note: E4, dur: 0.3 }, { note: D4, dur: 0.3 },
      { note: C4, dur: 0.5 },
      // Rest
      { note: 0, dur: 0.3 },
      // Second part - "Por-que no tie-ne, por-que le fal-ta..."
      { note: E4, dur: 0.15 }, { note: E4, dur: 0.15 }, { note: E4, dur: 0.15 },
      { note: G4, dur: 0.4 }, { note: C5, dur: 0.3 },
      { note: E4, dur: 0.15 }, { note: E4, dur: 0.15 }, { note: E4, dur: 0.15 },
      { note: G4, dur: 0.4 }, { note: C5, dur: 0.3 },
      { note: C5, dur: 0.2 }, { note: A4, dur: 0.2 },
      { note: G4, dur: 0.2 }, { note: F4, dur: 0.2 },
      { note: E4, dur: 0.2 }, { note: D4, dur: 0.2 },
      { note: C4, dur: 0.6 },
      // Rest before repeat
      { note: 0, dur: 0.4 },
    ];

    // Bass pattern (oom-pah style)
    const bassPattern = [
      { note: C3, dur: 0.25 }, { note: G3, dur: 0.25 },
      { note: C3, dur: 0.25 }, { note: G3, dur: 0.25 },
      { note: F3, dur: 0.25 }, { note: C3, dur: 0.25 },
      { note: F3, dur: 0.25 }, { note: C3, dur: 0.25 },
    ];

    let melodyTime = 0;
    let bassTime = 0;
    const tempo = 162; // BPM - 10% slower for a nicer feel
    const beatDur = 60 / tempo;

    const playMelodyLoop = () => {
      if (!this.isPlaying) return;
      melody.forEach((n, i) => {
        const id = setTimeout(() => {
          if (!this.isPlaying) return;
          if (n.note > 0) {
            this.playTrumpet(n.note, n.dur * beatDur * 0.9);
          }
        }, melodyTime * 1000);
        this.timeoutIds.push(id);
        melodyTime += n.dur * beatDur;
      });
      // Loop
      const loopId = setTimeout(() => {
        if (this.isPlaying) playMelodyLoop();
      }, melodyTime * 1000);
      this.timeoutIds.push(loopId);
    };

    const playBassLoop = () => {
      if (!this.isPlaying) return;
      for (let repeat = 0; repeat < 20; repeat++) { // Enough bass for the melody
        bassPattern.forEach((n, i) => {
          const id = setTimeout(() => {
            if (!this.isPlaying) return;
            this.playBass(n.note);
          }, bassTime * 1000);
          this.timeoutIds.push(id);
          bassTime += n.dur * beatDur;
        });
      }
      // Loop
      const loopId = setTimeout(() => {
        if (this.isPlaying) {
          bassTime = 0;
          playBassLoop();
        }
      }, bassTime * 1000);
      this.timeoutIds.push(loopId);
    };

    const playGuitarLoop = () => {
      if (!this.isPlaying) return;
      let gTime = 0;
      const chords = [
        [262, 330, 392], // C
        [262, 330, 392], // C
        [349, 440, 523], // F
        [349, 440, 523], // F
        [392, 494, 587], // G
        [392, 494, 587], // G
        [262, 330, 392], // C
        [262, 330, 392], // C
      ];
      chords.forEach((chord, i) => {
        const id = setTimeout(() => {
          if (!this.isPlaying) return;
          this.playGuitarStrum(chord);
        }, gTime * 1000);
        this.timeoutIds.push(id);
        gTime += beatDur * 2;
      });
      const loopId = setTimeout(() => {
        if (this.isPlaying) playGuitarLoop();
      }, gTime * 1000);
      this.timeoutIds.push(loopId);
    };

    playMelodyLoop();
    playBassLoop();
    playGuitarLoop();
  }

  playTrumpet(freq, duration) {
    if (!this.audioCtx || !this.isPlaying) return;
    const osc = this.audioCtx.createOscillator();
    const gain = this.audioCtx.createGain();
    osc.type = 'sawtooth';
    osc.frequency.value = freq;
    // Vibrato
    const vibrato = this.audioCtx.createOscillator();
    const vibratoGain = this.audioCtx.createGain();
    vibrato.frequency.value = 6;
    vibratoGain.gain.value = 4;
    vibrato.connect(vibratoGain);
    vibratoGain.connect(osc.frequency);
    vibrato.start();
    vibrato.stop(this.audioCtx.currentTime + duration);

    gain.gain.setValueAtTime(0.001, this.audioCtx.currentTime);
    gain.gain.exponentialRampToValueAtTime(0.12, this.audioCtx.currentTime + 0.03);
    gain.gain.setValueAtTime(0.10, this.audioCtx.currentTime + duration * 0.7);
    gain.gain.exponentialRampToValueAtTime(0.001, this.audioCtx.currentTime + duration);
    osc.connect(gain);
    gain.connect(this.gainNode);
    osc.start();
    osc.stop(this.audioCtx.currentTime + duration);
  }

  playBass(freq) {
    if (!this.audioCtx || !this.isPlaying) return;
    const osc = this.audioCtx.createOscillator();
    const gain = this.audioCtx.createGain();
    osc.type = 'triangle';
    osc.frequency.value = freq;
    gain.gain.setValueAtTime(0.15, this.audioCtx.currentTime);
    gain.gain.exponentialRampToValueAtTime(0.001, this.audioCtx.currentTime + 0.12);
    osc.connect(gain);
    gain.connect(this.gainNode);
    osc.start();
    osc.stop(this.audioCtx.currentTime + 0.15);
  }

  playGuitarStrum(chord) {
    if (!this.audioCtx || !this.isPlaying) return;
    chord.forEach((freq, i) => {
      setTimeout(() => {
        if (!this.audioCtx || !this.isPlaying) return;
        const osc = this.audioCtx.createOscillator();
        const gain = this.audioCtx.createGain();
        osc.type = 'sawtooth';
        osc.frequency.value = freq;
        gain.gain.setValueAtTime(0.05, this.audioCtx.currentTime);
        gain.gain.exponentialRampToValueAtTime(0.001, this.audioCtx.currentTime + 0.15);
        osc.connect(gain);
        gain.connect(this.gainNode);
        osc.start();
        osc.stop(this.audioCtx.currentTime + 0.2);
      }, i * 20);
    });
  }

  setVolume(vol) {
    if (this.gainNode) this.gainNode.gain.value = vol;
  }
}

const mariachiMusic = new MariachiMusic();

// ============== GAME STATE ==============
const gameState = {
  currentLevel: 1,
  totalLevels: 10,  // Now 10 levels!
  coins: 0,
  lives: 3,
  stars: [],
  rescuedBabies: [],
  superJumps: 0,
  score: 0,
  highScore: 0,
  musicEnabled: true,
  sfxEnabled: true
};

// Load saved state
try {
  const saved = localStorage.getItem('xochi-save');
  if (saved) Object.assign(gameState, JSON.parse(saved));
} catch (e) {}

function saveGame() {
  localStorage.setItem('xochi-save', JSON.stringify(gameState));
}

function resetGame() {
  // Save high score before reset
  if (gameState.score > gameState.highScore) {
    gameState.highScore = gameState.score;
  }
  gameState.currentLevel = 1;
  gameState.coins = 0;
  gameState.lives = 3;
  gameState.stars = [];
  gameState.rescuedBabies = [];
  gameState.superJumps = 0;
  gameState.score = 0;
  saveGame();
}

// ============== LEVEL DATA ==============
const LEVELS = [
  // Level 1 - Tutorial
  {
    width: 2400, height: 600,
    playerSpawn: { x: 100, y: 400 },
    babyPosition: { x: 2200, y: 300 },
    platforms: [
      { x: 0, y: 550, w: 2400, h: 50 }, // ground
      { x: 300, y: 450, w: 150, h: 20 },
      { x: 550, y: 380, w: 100, h: 20 },
      { x: 800, y: 320, w: 150, h: 20 },
      { x: 1100, y: 400, w: 200, h: 20 },
      { x: 1450, y: 350, w: 150, h: 20 },
      { x: 1700, y: 280, w: 100, h: 20 },
      { x: 1950, y: 350, w: 200, h: 20 },
      // Secret high platforms (need super jump)
      { x: 600, y: 150, w: 100, h: 20 },
      { x: 1500, y: 120, w: 120, h: 20 },
    ],
    coins: [
      {x:200,y:500},{x:250,y:500},{x:350,y:400},{x:600,y:330},
      {x:900,y:270},{x:1200,y:350},{x:1500,y:300},{x:1750,y:230},{x:2000,y:300},
      // Bonus coins on secret platforms
      {x:620,y:100},{x:660,y:100},{x:1520,y:70},{x:1560,y:70},{x:1600,y:70}
    ],
    stars: [{x:400,y:350},{x:650,y:100},{x:1560,y:70}],
    enemies: [
      // Ground enemies
      {x:500,y:520,type:'ground'},{x:1300,y:520,type:'ground'},{x:2000,y:520,type:'ground'},
      // Platform enemies
      {x:850,y:290,type:'platform'},{x:1500,y:320,type:'platform'},
      // Flying enemy
      {x:1100,y:350,type:'flying',amplitude:60,speed:70,dir:1}
    ],
    powerups: [
      {x:150,y:500},{x:850,y:270},{x:1550,y:300}
    ]
  },
  // Level 2 - Floating Gardens 2
  {
    width: 2800, height: 600,
    playerSpawn: { x: 100, y: 400 },
    babyPosition: { x: 2600, y: 250 },
    platforms: [
      { x: 0, y: 550, w: 600, h: 50 },
      { x: 700, y: 550, w: 500, h: 50 },
      { x: 1300, y: 550, w: 600, h: 50 },
      { x: 2000, y: 550, w: 800, h: 50 },
      { x: 350, y: 450, w: 150, h: 20 },
      { x: 600, y: 380, w: 100, h: 20 },
      { x: 900, y: 450, w: 150, h: 20 },
      { x: 1200, y: 380, w: 100, h: 20 },
      { x: 1500, y: 320, w: 150, h: 20 },
      { x: 1800, y: 400, w: 200, h: 20 },
      { x: 2100, y: 320, w: 150, h: 20 },
      { x: 2400, y: 280, w: 200, h: 20 },
      // Secret platforms
      { x: 400, y: 150, w: 100, h: 20 },
      { x: 1600, y: 100, w: 150, h: 20 },
    ],
    coins: [
      {x:200,y:500},{x:400,y:400},{x:650,y:330},{x:950,y:400},
      {x:1250,y:330},{x:1550,y:270},{x:1850,y:350},{x:2150,y:270},{x:2450,y:230},
      {x:420,y:100},{x:460,y:100},{x:1620,y:50},{x:1680,y:50},{x:1740,y:50}
    ],
    stars: [{x:450,y:100},{x:1400,y:200},{x:1680,y:50}],
    enemies: [
      // Ground enemies
      {x:400,y:520,type:'ground'},{x:1100,y:520,type:'ground'},{x:2200,y:520,type:'ground'},
      // Platform enemies
      {x:650,y:350,type:'platform'},{x:1550,y:290,type:'platform'},{x:2450,y:250,type:'platform'},
      // Flying enemies
      {x:900,y:400,type:'flying',amplitude:50,speed:80,dir:-1},
      {x:1900,y:350,type:'flying',amplitude:70,speed:60,dir:1}
    ],
    powerups: [
      {x:250,y:500},{x:1000,y:400},{x:2000,y:500}
    ]
  },
  // Level 3
  {
    width: 3000, height: 700,
    playerSpawn: { x: 100, y: 500 },
    babyPosition: { x: 2800, y: 200 },
    platforms: [
      { x: 0, y: 650, w: 500, h: 50 },
      { x: 600, y: 650, w: 400, h: 50 },
      { x: 1100, y: 650, w: 500, h: 50 },
      { x: 1700, y: 650, w: 400, h: 50 },
      { x: 2200, y: 650, w: 800, h: 50 },
      { x: 300, y: 550, w: 150, h: 20 },
      { x: 550, y: 480, w: 100, h: 20 },
      { x: 800, y: 550, w: 150, h: 20 },
      { x: 1050, y: 480, w: 100, h: 20 },
      { x: 1300, y: 400, w: 150, h: 20 },
      { x: 1550, y: 480, w: 150, h: 20 },
      { x: 1850, y: 400, w: 150, h: 20 },
      { x: 2100, y: 320, w: 150, h: 20 },
      { x: 2400, y: 400, w: 150, h: 20 },
      { x: 2650, y: 300, w: 200, h: 20 },
    ],
    coins: [
      {x:200,y:600},{x:350,y:500},{x:600,y:430},{x:850,y:500},{x:1100,y:430},
      {x:1350,y:350},{x:1600,y:430},{x:1900,y:350},{x:2150,y:270},{x:2450,y:350},{x:2700,y:250}
    ],
    stars: [{x:600,y:350},{x:1450,y:280},{x:2750,y:180}],
    enemies: [
      // Ground
      {x:300,y:620,type:'ground'},{x:1000,y:620,type:'ground'},{x:2300,y:620,type:'ground'},
      // Platform
      {x:1350,y:370,type:'platform'},{x:1900,y:370,type:'platform'},{x:2700,y:270,type:'platform'},
      // Flying
      {x:700,y:500,type:'flying',amplitude:80,speed:90,dir:-1},
      {x:1600,y:400,type:'flying',amplitude:60,speed:75,dir:1}
    ],
    powerups: [
      {x:200,y:600},{x:900,y:500},{x:1700,y:600},{x:2500,y:350}
    ]
  },
  // Level 4
  {
    width: 3200, height: 700,
    playerSpawn: { x: 100, y: 500 },
    babyPosition: { x: 3000, y: 180 },
    platforms: [
      { x: 0, y: 650, w: 400, h: 50 },
      { x: 500, y: 650, w: 300, h: 50 },
      { x: 900, y: 650, w: 400, h: 50 },
      { x: 1400, y: 650, w: 300, h: 50 },
      { x: 1800, y: 650, w: 400, h: 50 },
      { x: 2300, y: 650, w: 300, h: 50 },
      { x: 2700, y: 650, w: 500, h: 50 },
      { x: 250, y: 550, w: 100, h: 20 },
      { x: 450, y: 480, w: 100, h: 20 },
      { x: 700, y: 550, w: 150, h: 20 },
      { x: 1000, y: 480, w: 100, h: 20 },
      { x: 1250, y: 400, w: 100, h: 20 },
      { x: 1500, y: 480, w: 150, h: 20 },
      { x: 1800, y: 400, w: 100, h: 20 },
      { x: 2050, y: 320, w: 150, h: 20 },
      { x: 2350, y: 400, w: 100, h: 20 },
      { x: 2600, y: 320, w: 100, h: 20 },
      { x: 2850, y: 250, w: 200, h: 20 },
    ],
    coins: [
      {x:150,y:600},{x:300,y:500},{x:500,y:430},{x:750,y:500},{x:1050,y:430},
      {x:1300,y:350},{x:1550,y:430},{x:1850,y:350},{x:2100,y:270},{x:2400,y:350},
      {x:2650,y:270},{x:2900,y:200}
    ],
    stars: [{x:500,y:350},{x:1400,y:280},{x:2950,y:150}],
    enemies: [
      // Ground
      {x:250,y:620,type:'ground'},{x:950,y:620,type:'ground'},{x:2000,y:620,type:'ground'},
      // Platform
      {x:750,y:520,type:'platform'},{x:1300,y:370,type:'platform'},{x:2650,y:290,type:'platform'},
      // Flying - multiple!
      {x:500,y:450,type:'flying',amplitude:70,speed:85,dir:1},
      {x:1500,y:400,type:'flying',amplitude:60,speed:95,dir:-1},
      {x:2400,y:350,type:'flying',amplitude:50,speed:100,dir:1}
    ],
    powerups: [
      {x:150,y:600},{x:800,y:500},{x:1600,y:600},{x:2200,y:350},{x:2700,y:270}
    ]
  },
  // Level 5 (Final)
  {
    width: 3500, height: 800,
    playerSpawn: { x: 100, y: 600 },
    babyPosition: { x: 3300, y: 150 },
    platforms: [
      { x: 0, y: 750, w: 350, h: 50 },
      { x: 450, y: 750, w: 250, h: 50 },
      { x: 800, y: 750, w: 350, h: 50 },
      { x: 1250, y: 750, w: 250, h: 50 },
      { x: 1600, y: 750, w: 350, h: 50 },
      { x: 2050, y: 750, w: 250, h: 50 },
      { x: 2400, y: 750, w: 350, h: 50 },
      { x: 2850, y: 750, w: 650, h: 50 },
      { x: 200, y: 650, w: 100, h: 20 },
      { x: 400, y: 580, w: 100, h: 20 },
      { x: 650, y: 650, w: 100, h: 20 },
      { x: 900, y: 580, w: 100, h: 20 },
      { x: 1150, y: 500, w: 100, h: 20 },
      { x: 1400, y: 580, w: 100, h: 20 },
      { x: 1700, y: 500, w: 100, h: 20 },
      { x: 1950, y: 420, w: 100, h: 20 },
      { x: 2200, y: 500, w: 100, h: 20 },
      { x: 2500, y: 420, w: 100, h: 20 },
      { x: 2750, y: 340, w: 100, h: 20 },
      { x: 3000, y: 260, w: 150, h: 20 },
      { x: 3200, y: 200, w: 200, h: 20 },
    ],
    coins: [
      {x:100,y:700},{x:250,y:600},{x:450,y:530},{x:700,y:600},{x:950,y:530},
      {x:1200,y:450},{x:1450,y:530},{x:1750,y:450},{x:2000,y:370},{x:2250,y:450},
      {x:2550,y:370},{x:2800,y:290},{x:3050,y:210},{x:3250,y:150}
    ],
    stars: [{x:500,y:450},{x:1600,y:380},{x:3150,y:100}],
    enemies: [
      // Ground
      {x:200,y:720,type:'ground'},{x:900,y:720,type:'ground'},{x:2500,y:720,type:'ground'},
      // Platform
      {x:450,y:550,type:'platform'},{x:1200,y:470,type:'platform'},{x:2000,y:390,type:'platform'},{x:3050,y:230,type:'platform'},
      // Flying - swarm!
      {x:700,y:550,type:'flying',amplitude:80,speed:75,dir:-1},
      {x:1400,y:480,type:'flying',amplitude:70,speed:90,dir:1},
      {x:2200,y:400,type:'flying',amplitude:60,speed:85,dir:-1},
      {x:2800,y:320,type:'flying',amplitude:50,speed:100,dir:1}
    ],
    powerups: [
      {x:100,y:700},{x:600,y:600},{x:1100,y:700},{x:1800,y:450},{x:2300,y:450},{x:2900,y:300}
    ]
    // BOSS LEVEL 5 - Dark Xochi appears with timer!
  },
  // Level 6 - Jungle Temple
  {
    width: 3200, height: 700,
    playerSpawn: { x: 100, y: 550 },
    babyPosition: { x: 3000, y: 200 },
    platforms: [
      { x: 0, y: 650, w: 400, h: 50 },
      { x: 500, y: 650, w: 300, h: 50 },
      { x: 900, y: 650, w: 400, h: 50 },
      { x: 1400, y: 650, w: 300, h: 50 },
      { x: 1800, y: 650, w: 400, h: 50 },
      { x: 2300, y: 650, w: 300, h: 50 },
      { x: 2700, y: 650, w: 500, h: 50 },
      { x: 200, y: 550, w: 120, h: 20 },
      { x: 450, y: 480, w: 100, h: 20 },
      { x: 700, y: 400, w: 150, h: 20 },
      { x: 1000, y: 500, w: 120, h: 20 },
      { x: 1250, y: 420, w: 100, h: 20 },
      { x: 1500, y: 340, w: 150, h: 20 },
      { x: 1800, y: 450, w: 120, h: 20 },
      { x: 2100, y: 350, w: 150, h: 20 },
      { x: 2400, y: 280, w: 120, h: 20 },
      { x: 2700, y: 350, w: 100, h: 20 },
      { x: 2900, y: 250, w: 200, h: 20 },
    ],
    coins: [
      {x:150,y:600},{x:250,y:500},{x:500,y:430},{x:750,y:350},{x:1050,y:450},
      {x:1300,y:370},{x:1550,y:290},{x:1850,y:400},{x:2150,y:300},{x:2450,y:230},{x:2950,y:200}
    ],
    stars: [{x:750,y:300},{x:1550,y:200},{x:2950,y:150}],
    enemies: [
      // Ground
      {x:300,y:620,type:'ground'},{x:1000,y:620,type:'ground'},{x:2400,y:620,type:'ground'},
      // Platform
      {x:750,y:370,type:'platform'},{x:1300,y:390,type:'platform'},{x:2150,y:320,type:'platform'},{x:2750,y:320,type:'platform'},
      // Flying
      {x:500,y:450,type:'flying',amplitude:70,speed:80,dir:1},
      {x:1200,y:380,type:'flying',amplitude:55,speed:95,dir:-1},
      {x:2000,y:350,type:'flying',amplitude:65,speed:85,dir:1}
    ],
    powerups: [{x:100,y:600},{x:800,y:350},{x:1600,y:290},{x:2500,y:230}]
  },
  // Level 7 - Jungle Temple 2
  {
    width: 3500, height: 750,
    playerSpawn: { x: 100, y: 600 },
    babyPosition: { x: 3300, y: 180 },
    platforms: [
      { x: 0, y: 700, w: 350, h: 50 },
      { x: 450, y: 700, w: 300, h: 50 },
      { x: 850, y: 700, w: 350, h: 50 },
      { x: 1300, y: 700, w: 300, h: 50 },
      { x: 1700, y: 700, w: 350, h: 50 },
      { x: 2150, y: 700, w: 300, h: 50 },
      { x: 2550, y: 700, w: 350, h: 50 },
      { x: 3000, y: 700, w: 500, h: 50 },
      { x: 180, y: 600, w: 100, h: 20 },
      { x: 400, y: 520, w: 120, h: 20 },
      { x: 650, y: 440, w: 100, h: 20 },
      { x: 900, y: 550, w: 150, h: 20 },
      { x: 1150, y: 460, w: 100, h: 20 },
      { x: 1400, y: 380, w: 120, h: 20 },
      { x: 1700, y: 480, w: 100, h: 20 },
      { x: 1950, y: 380, w: 150, h: 20 },
      { x: 2200, y: 300, w: 100, h: 20 },
      { x: 2500, y: 400, w: 120, h: 20 },
      { x: 2750, y: 320, w: 100, h: 20 },
      { x: 3000, y: 240, w: 150, h: 20 },
      { x: 3200, y: 180, w: 200, h: 20 },
    ],
    coins: [
      {x:100,y:650},{x:230,y:550},{x:450,y:470},{x:700,y:390},{x:950,y:500},
      {x:1200,y:410},{x:1450,y:330},{x:1750,y:430},{x:2000,y:330},{x:2250,y:250},
      {x:2550,y:350},{x:2800,y:270},{x:3050,y:190},{x:3250,y:130}
    ],
    stars: [{x:700,y:340},{x:1450,y:230},{x:3100,y:140}],
    enemies: [
      // Ground
      {x:250,y:670,type:'ground'},{x:950,y:670,type:'ground'},{x:2650,y:670,type:'ground'},
      // Platform
      {x:700,y:410,type:'platform'},{x:1450,y:350,type:'platform'},{x:2000,y:350,type:'platform'},{x:3050,y:210,type:'platform'},
      // Flying
      {x:450,y:500,type:'flying',amplitude:75,speed:85,dir:-1},
      {x:1200,y:420,type:'flying',amplitude:60,speed:90,dir:1},
      {x:2400,y:350,type:'flying',amplitude:55,speed:100,dir:-1},
      {x:2900,y:280,type:'flying',amplitude:50,speed:95,dir:1}
    ],
    powerups: [{x:100,y:650},{x:700,y:390},{x:1500,y:330},{x:2300,y:250},{x:2900,y:190}]
  },
  // Level 8 - Volcano
  {
    width: 3600, height: 800,
    playerSpawn: { x: 100, y: 650 },
    babyPosition: { x: 3400, y: 200 },
    platforms: [
      { x: 0, y: 750, w: 300, h: 50 },
      { x: 400, y: 750, w: 250, h: 50 },
      { x: 750, y: 750, w: 300, h: 50 },
      { x: 1150, y: 750, w: 250, h: 50 },
      { x: 1500, y: 750, w: 300, h: 50 },
      { x: 1900, y: 750, w: 250, h: 50 },
      { x: 2250, y: 750, w: 300, h: 50 },
      { x: 2650, y: 750, w: 250, h: 50 },
      { x: 3000, y: 750, w: 600, h: 50 },
      { x: 150, y: 650, w: 100, h: 20 },
      { x: 350, y: 570, w: 100, h: 20 },
      { x: 600, y: 650, w: 120, h: 20 },
      { x: 850, y: 560, w: 100, h: 20 },
      { x: 1100, y: 480, w: 120, h: 20 },
      { x: 1350, y: 560, w: 100, h: 20 },
      { x: 1600, y: 470, w: 120, h: 20 },
      { x: 1850, y: 380, w: 100, h: 20 },
      { x: 2100, y: 480, w: 120, h: 20 },
      { x: 2350, y: 380, w: 100, h: 20 },
      { x: 2600, y: 300, w: 120, h: 20 },
      { x: 2900, y: 380, w: 100, h: 20 },
      { x: 3150, y: 280, w: 150, h: 20 },
      { x: 3350, y: 200, w: 200, h: 20 },
    ],
    coins: [
      {x:80,y:700},{x:200,y:600},{x:400,y:520},{x:650,y:600},{x:900,y:510},
      {x:1150,y:430},{x:1400,y:510},{x:1650,y:420},{x:1900,y:330},{x:2150,y:430},
      {x:2400,y:330},{x:2650,y:250},{x:2950,y:330},{x:3200,y:230},{x:3400,y:150}
    ],
    stars: [{x:400,y:420},{x:1650,y:320},{x:3200,y:180}],
    enemies: [
      // Ground
      {x:200,y:720,type:'ground'},{x:850,y:720,type:'ground'},{x:2350,y:720,type:'ground'},
      // Platform - heavy presence
      {x:400,y:540,type:'platform'},{x:900,y:530,type:'platform'},{x:1400,y:530,type:'platform'},
      {x:1900,y:350,type:'platform'},{x:2650,y:270,type:'platform'},{x:3200,y:250,type:'platform'},
      // Flying - danger zone!
      {x:600,y:550,type:'flying',amplitude:80,speed:80,dir:-1},
      {x:1100,y:470,type:'flying',amplitude:70,speed:95,dir:1},
      {x:1800,y:400,type:'flying',amplitude:60,speed:90,dir:-1},
      {x:2500,y:330,type:'flying',amplitude:55,speed:100,dir:1},
      {x:3000,y:280,type:'flying',amplitude:50,speed:85,dir:-1}
    ],
    powerups: [{x:80,y:700},{x:650,y:600},{x:1250,y:430},{x:1900,y:330},{x:2650,y:250},{x:3100,y:230}]
  },
  // Level 9 - Volcano 2
  {
    width: 3800, height: 850,
    playerSpawn: { x: 100, y: 700 },
    babyPosition: { x: 3600, y: 180 },
    platforms: [
      { x: 0, y: 800, w: 280, h: 50 },
      { x: 380, y: 800, w: 220, h: 50 },
      { x: 700, y: 800, w: 280, h: 50 },
      { x: 1080, y: 800, w: 220, h: 50 },
      { x: 1400, y: 800, w: 280, h: 50 },
      { x: 1780, y: 800, w: 220, h: 50 },
      { x: 2100, y: 800, w: 280, h: 50 },
      { x: 2480, y: 800, w: 220, h: 50 },
      { x: 2800, y: 800, w: 280, h: 50 },
      { x: 3180, y: 800, w: 620, h: 50 },
      { x: 140, y: 700, w: 100, h: 20 },
      { x: 340, y: 620, w: 100, h: 20 },
      { x: 580, y: 700, w: 100, h: 20 },
      { x: 800, y: 610, w: 100, h: 20 },
      { x: 1050, y: 520, w: 100, h: 20 },
      { x: 1300, y: 610, w: 100, h: 20 },
      { x: 1550, y: 510, w: 100, h: 20 },
      { x: 1800, y: 420, w: 100, h: 20 },
      { x: 2050, y: 520, w: 100, h: 20 },
      { x: 2300, y: 420, w: 100, h: 20 },
      { x: 2550, y: 330, w: 100, h: 20 },
      { x: 2850, y: 420, w: 100, h: 20 },
      { x: 3100, y: 320, w: 100, h: 20 },
      { x: 3350, y: 240, w: 150, h: 20 },
      { x: 3550, y: 180, w: 200, h: 20 },
    ],
    coins: [
      {x:70,y:750},{x:190,y:650},{x:390,y:570},{x:630,y:650},{x:850,y:560},
      {x:1100,y:470},{x:1350,y:560},{x:1600,y:460},{x:1850,y:370},{x:2100,y:470},
      {x:2350,y:370},{x:2600,y:280},{x:2900,y:370},{x:3150,y:270},{x:3400,y:190},{x:3600,y:130}
    ],
    stars: [{x:390,y:470},{x:1600,y:360},{x:3400,y:140}],
    enemies: [
      // Ground
      {x:180,y:770,type:'ground'},{x:800,y:770,type:'ground'},{x:2200,y:770,type:'ground'},{x:3280,y:770,type:'ground'},
      // Platform - lots!
      {x:400,y:590,type:'platform'},{x:900,y:580,type:'platform'},{x:1400,y:580,type:'platform'},
      {x:1900,y:390,type:'platform'},{x:2400,y:390,type:'platform'},{x:2950,y:290,type:'platform'},{x:3400,y:210,type:'platform'},
      // Flying - intense!
      {x:550,y:600,type:'flying',amplitude:85,speed:85,dir:-1},
      {x:1050,y:510,type:'flying',amplitude:75,speed:100,dir:1},
      {x:1700,y:450,type:'flying',amplitude:65,speed:95,dir:-1},
      {x:2350,y:380,type:'flying',amplitude:55,speed:90,dir:1},
      {x:2850,y:310,type:'flying',amplitude:50,speed:105,dir:-1},
      {x:3200,y:260,type:'flying',amplitude:45,speed:80,dir:1}
    ],
    powerups: [{x:70,y:750},{x:630,y:650},{x:1200,y:470},{x:1850,y:370},{x:2600,y:280},{x:3200,y:270}]
  },
  // Level 10 - Final Challenge!
  {
    width: 4000, height: 900,
    playerSpawn: { x: 100, y: 750 },
    babyPosition: { x: 3800, y: 150 },
    platforms: [
      { x: 0, y: 850, w: 250, h: 50 },
      { x: 350, y: 850, w: 200, h: 50 },
      { x: 650, y: 850, w: 250, h: 50 },
      { x: 1000, y: 850, w: 200, h: 50 },
      { x: 1300, y: 850, w: 250, h: 50 },
      { x: 1650, y: 850, w: 200, h: 50 },
      { x: 1950, y: 850, w: 250, h: 50 },
      { x: 2300, y: 850, w: 200, h: 50 },
      { x: 2600, y: 850, w: 250, h: 50 },
      { x: 2950, y: 850, w: 200, h: 50 },
      { x: 3250, y: 850, w: 750, h: 50 },
      { x: 125, y: 750, w: 100, h: 20 },
      { x: 325, y: 670, w: 100, h: 20 },
      { x: 550, y: 750, w: 100, h: 20 },
      { x: 750, y: 660, w: 100, h: 20 },
      { x: 980, y: 570, w: 100, h: 20 },
      { x: 1200, y: 660, w: 100, h: 20 },
      { x: 1450, y: 560, w: 100, h: 20 },
      { x: 1700, y: 470, w: 100, h: 20 },
      { x: 1950, y: 570, w: 100, h: 20 },
      { x: 2200, y: 470, w: 100, h: 20 },
      { x: 2450, y: 380, w: 100, h: 20 },
      { x: 2750, y: 470, w: 100, h: 20 },
      { x: 3000, y: 370, w: 100, h: 20 },
      { x: 3250, y: 280, w: 100, h: 20 },
      { x: 3500, y: 200, w: 150, h: 20 },
      { x: 3750, y: 150, w: 200, h: 20 },
    ],
    coins: [
      {x:60,y:800},{x:175,y:700},{x:375,y:620},{x:600,y:700},{x:800,y:610},
      {x:1030,y:520},{x:1250,y:610},{x:1500,y:510},{x:1750,y:420},{x:2000,y:520},
      {x:2250,y:420},{x:2500,y:330},{x:2800,y:420},{x:3050,y:320},{x:3300,y:230},
      {x:3550,y:150},{x:3800,y:100}
    ],
    stars: [{x:375,y:520},{x:1500,y:410},{x:3300,y:180}],
    enemies: [
      // Ground - gauntlet!
      {x:160,y:820,type:'ground'},{x:750,y:820,type:'ground'},{x:1400,y:820,type:'ground'},
      {x:2050,y:820,type:'ground'},{x:2700,y:820,type:'ground'},{x:3350,y:820,type:'ground'},
      // Platform - maximum coverage!
      {x:375,y:640,type:'platform'},{x:800,y:630,type:'platform'},{x:1250,y:630,type:'platform'},
      {x:1750,y:440,type:'platform'},{x:2250,y:440,type:'platform'},{x:2800,y:440,type:'platform'},
      {x:3100,y:340,type:'platform'},{x:3550,y:170,type:'platform'},
      // Flying - BOSS MODE!
      {x:400,y:650,type:'flying',amplitude:90,speed:90,dir:-1},
      {x:800,y:570,type:'flying',amplitude:80,speed:100,dir:1},
      {x:1200,y:500,type:'flying',amplitude:70,speed:95,dir:-1},
      {x:1600,y:430,type:'flying',amplitude:65,speed:110,dir:1},
      {x:2000,y:380,type:'flying',amplitude:60,speed:105,dir:-1},
      {x:2400,y:330,type:'flying',amplitude:55,speed:100,dir:1},
      {x:2800,y:280,type:'flying',amplitude:50,speed:95,dir:-1},
      {x:3200,y:230,type:'flying',amplitude:45,speed:90,dir:1},
      {x:3600,y:180,type:'flying',amplitude:40,speed:85,dir:-1}
    ],
    powerups: [{x:60,y:800},{x:600,y:700},{x:1100,y:520},{x:1750,y:420},{x:2500,y:330},{x:3100,y:320},{x:3500,y:150}]
    // BOSS LEVEL 10 - Final Dark Xochi showdown with timer!
  }
];

// ============== BOOT SCENE ==============
class BootScene extends Phaser.Scene {
  constructor() { super('BootScene'); }

  preload() {
    // Load audio
    this.load.audio('music', 'public/assets/audio/main_theme.ogg');
    this.load.audio('sfx-jump', 'public/assets/audio/small_jump.ogg');
    this.load.audio('sfx-coin', 'public/assets/audio/coin.ogg');
    this.load.audio('sfx-stomp', 'public/assets/audio/stomp.ogg');
    this.load.audio('sfx-powerup', 'public/assets/audio/powerup.ogg');
    this.load.audio('sfx-hurt', 'public/assets/audio/bump.ogg');
    this.load.audio('sfx-superjump', 'public/assets/audio/powerup_appears.ogg');

    // Load Xochi (Aztec warrior girl) sprites
    this.load.image('xochi', 'public/assets/xochi_main_asset/xochi_new_1.png');
    this.load.image('xochi-attack', 'public/assets/xochi_main_asset/xochi_new_2.png');
  }

  create() {
    // Generate textures
    this.generateTextures();
    this.scene.start('MenuScene');
  }

  generateTextures() {
    let g = this.add.graphics();

    // Helper to draw a star shape
    const drawStar = (gfx, cx, cy, points, outerR, innerR) => {
      gfx.beginPath();
      for (let i = 0; i < points * 2; i++) {
        const r = i % 2 === 0 ? outerR : innerR;
        const angle = (i * Math.PI / points) - Math.PI / 2;
        const x = cx + Math.cos(angle) * r;
        const y = cy + Math.sin(angle) * r;
        if (i === 0) gfx.moveTo(x, y);
        else gfx.lineTo(x, y);
      }
      gfx.closePath();
      gfx.fillPath();
    };

    // Helper to draw coral-like feathery gills
    const drawGills = (gfx, x, y, flip, scale = 1) => {
      const dir = flip ? -1 : 1;
      // Multiple coral fronds with gradient coloring
      const fronds = [
        { ox: 0, oy: -8, r: 4 },   // Top frond
        { ox: -2 * dir, oy: -4, r: 3.5 },
        { ox: -3 * dir, oy: 0, r: 3 },
        { ox: -2 * dir, oy: 4, r: 3 },
        { ox: 0, oy: 7, r: 2.5 },  // Bottom frond
      ];
      // Dark coral base
      gfx.fillStyle(0xcc3366);
      fronds.forEach(f => {
        gfx.fillCircle(x + f.ox * scale, y + f.oy * scale, f.r * scale);
      });
      // Mid coral layer
      gfx.fillStyle(0xe85588);
      fronds.forEach(f => {
        gfx.fillCircle(x + f.ox * scale + dir, y + f.oy * scale - 0.5, (f.r - 0.5) * scale);
      });
      // Bright coral tips
      gfx.fillStyle(0xff88aa);
      fronds.forEach(f => {
        gfx.fillCircle(x + f.ox * scale + dir * 1.5, y + f.oy * scale - 1, (f.r - 1.2) * scale);
      });
      // Tiny highlight dots
      gfx.fillStyle(0xffccdd);
      gfx.fillCircle(x + dir * 2, y - 7 * scale, 1.5 * scale);
      gfx.fillCircle(x + dir, y - 2 * scale, 1 * scale);
    };

    // ============ XOCHI SPRITE (loaded from PNG) ============
    // Xochi is now an Aztec warrior girl - sprite loaded in preload()
    // Skip procedural generation for 'xochi' texture

    /* REMOVED - now using PNG sprite
    // TAIL (behind body, extending right)
    g.fillStyle(0xbb5577);
    g.fillEllipse(24, 18, 10, 4);
    g.fillStyle(0xd8708a);
    g.fillEllipse(23, 17, 8, 3);
    g.fillStyle(0xf08899);
    g.fillEllipse(22, 17, 6, 2);

    // BACK LEG (partially visible)
    g.fillStyle(0xcc5577);
    g.fillEllipse(18, 22, 4, 5);
    g.fillStyle(0xe07090);
    g.fillEllipse(18, 23, 3, 3);

    // BODY - elongated oval, 3/4 view (DKC style smooth shading)
    // Deep shadow
    g.fillStyle(0x993355);
    g.fillEllipse(13, 15, 16, 12);
    // Body dark
    g.fillStyle(0xcc5577);
    g.fillEllipse(12, 14, 15, 11);
    // Body mid
    g.fillStyle(0xe07090);
    g.fillEllipse(11, 13, 14, 10);
    // Body light
    g.fillStyle(0xf08899);
    g.fillEllipse(10, 12, 12, 9);
    // Body highlight (left side - light source)
    g.fillStyle(0xffaabb);
    g.fillEllipse(8, 11, 8, 7);
    // Specular highlight
    g.fillStyle(0xffccdd);
    g.fillEllipse(6, 9, 5, 4);
    // Hot spot
    g.fillStyle(0xffeeff, 0.7);
    g.fillCircle(5, 8, 2);

    // FRONT LEG (visible, cute stubby)
    g.fillStyle(0xcc5577);
    g.fillEllipse(6, 21, 4, 5);
    g.fillStyle(0xe07090);
    g.fillEllipse(6, 22, 3, 4);
    g.fillStyle(0xf08899);
    g.fillEllipse(6, 22, 2, 3);

    // HEAD (slightly larger, facing 3/4 toward camera)
    // Head shadow
    g.fillStyle(0xbb4466);
    g.fillCircle(9, 10, 8);
    // Head base
    g.fillStyle(0xdd6688);
    g.fillCircle(8, 9, 7.5);
    // Head mid
    g.fillStyle(0xee7799);
    g.fillCircle(7, 8, 6.5);
    // Head light
    g.fillStyle(0xff99aa);
    g.fillCircle(6, 7, 5);
    // Head specular
    g.fillStyle(0xffbbcc);
    g.fillCircle(5, 6, 3);

    // GILLS (coral fronds on back of head - DKC pre-rendered look)
    // Back gills (partially hidden)
    g.fillStyle(0xaa3355);
    g.fillCircle(16, 5, 3);
    g.fillCircle(17, 8, 2.5);
    g.fillCircle(16, 11, 2);
    g.fillStyle(0xcc4466);
    g.fillCircle(15, 5, 2.5);
    g.fillCircle(16, 8, 2);
    g.fillStyle(0xee6688);
    g.fillCircle(14, 5, 2);
    g.fillCircle(15, 8, 1.5);

    // Side gills (more visible, feathery)
    g.fillStyle(0xbb3355);
    g.fillCircle(13, 3, 3.5);
    g.fillCircle(11, 2, 3);
    g.fillCircle(9, 2, 2.5);
    g.fillStyle(0xdd5577);
    g.fillCircle(12, 3, 3);
    g.fillCircle(10, 2, 2.5);
    g.fillCircle(8, 2, 2);
    g.fillStyle(0xff7799);
    g.fillCircle(11, 3, 2);
    g.fillCircle(9, 2.5, 1.8);
    g.fillCircle(7, 3, 1.5);
    // Gill highlights
    g.fillStyle(0xffaacc);
    g.fillCircle(10, 3, 1);
    g.fillCircle(8, 3, 0.8);

    // BIG EYE (front eye - large and cute, 3/4 view)
    // Eye white
    g.fillStyle(0xffffff);
    g.fillEllipse(6, 9, 5, 5.5);
    // Eye outline
    g.lineStyle(0.5, 0x663355, 0.3);
    g.strokeEllipse(6, 9, 5, 5.5);
    // Pupil
    g.fillStyle(0x221133);
    g.fillEllipse(7, 9, 3, 3.5);
    // Iris color
    g.fillStyle(0x442244);
    g.fillEllipse(7, 9, 2.5, 3);
    // Inner pupil
    g.fillStyle(0x110011);
    g.fillCircle(7, 9, 1.5);
    // Big sparkle
    g.fillStyle(0xffffff);
    g.fillCircle(5, 7.5, 1.8);
    // Small sparkle
    g.fillStyle(0xffffff, 0.8);
    g.fillCircle(8, 10.5, 0.8);

    // SMALL EYE (back eye - partially visible in 3/4 view)
    g.fillStyle(0xeeeeff);
    g.fillEllipse(12, 8, 2.5, 3);
    g.fillStyle(0x332233);
    g.fillEllipse(12.5, 8, 1.5, 2);
    g.fillStyle(0xffffff, 0.7);
    g.fillCircle(11.5, 7, 0.8);

    // CUTE SMILE (small, happy)
    g.lineStyle(1, 0xaa3355);
    g.beginPath();
    g.arc(7, 13, 2.5, 0.2, Math.PI - 0.5);
    g.strokePath();

    // BLUSH (rosy cheek)
    g.fillStyle(0xff6688, 0.4);
    g.fillCircle(4, 12, 2);

    // NOSTRIL (tiny dot)
    g.fillStyle(0xaa4466);
    g.fillCircle(3, 10, 0.5);

    g.generateTexture('xochi-procedural-backup', 32, 32);
    */ // END OF REMOVED PROCEDURAL XOCHI
    g.clear();

    // ============ BIG XOCHI (powered up - uses same sprite scaled) ============
    // Tail
    g.fillStyle(0xbb5577);
    g.fillEllipse(26, 38, 12, 5);
    g.fillStyle(0xe07090);
    g.fillEllipse(25, 37, 10, 4);

    // Back leg
    g.fillStyle(0xcc5577);
    g.fillEllipse(20, 52, 5, 8);
    g.fillStyle(0xe07090);
    g.fillEllipse(20, 53, 4, 6);

    // Body
    g.fillStyle(0x993355);
    g.fillEllipse(14, 36, 18, 30);
    g.fillStyle(0xcc5577);
    g.fillEllipse(13, 35, 17, 28);
    g.fillStyle(0xe07090);
    g.fillEllipse(12, 34, 16, 26);
    g.fillStyle(0xf08899);
    g.fillEllipse(10, 32, 14, 22);
    g.fillStyle(0xffaabb);
    g.fillEllipse(8, 28, 10, 16);
    g.fillStyle(0xffccdd);
    g.fillCircle(6, 22, 5);

    // Front leg
    g.fillStyle(0xcc5577);
    g.fillEllipse(6, 52, 5, 8);
    g.fillStyle(0xe07090);
    g.fillEllipse(6, 53, 4, 6);

    // Head
    g.fillStyle(0xbb4466);
    g.fillCircle(10, 16, 10);
    g.fillStyle(0xdd6688);
    g.fillCircle(9, 15, 9);
    g.fillStyle(0xee7799);
    g.fillCircle(8, 14, 8);
    g.fillStyle(0xff99aa);
    g.fillCircle(7, 12, 6);
    g.fillStyle(0xffbbcc);
    g.fillCircle(5, 10, 4);

    // Gills
    g.fillStyle(0xbb3355);
    g.fillCircle(18, 8, 5);
    g.fillCircle(15, 5, 4);
    g.fillCircle(12, 4, 3.5);
    g.fillStyle(0xdd5577);
    g.fillCircle(17, 8, 4);
    g.fillCircle(14, 5, 3);
    g.fillCircle(11, 4, 2.5);
    g.fillStyle(0xff7799);
    g.fillCircle(16, 8, 3);
    g.fillCircle(13, 5, 2);
    g.fillCircle(10, 5, 2);

    // Big eye
    g.fillStyle(0xffffff);
    g.fillEllipse(7, 14, 6, 7);
    g.fillStyle(0x221133);
    g.fillEllipse(8, 14, 4, 5);
    g.fillStyle(0x442244);
    g.fillEllipse(8, 14, 3, 4);
    g.fillStyle(0xffffff);
    g.fillCircle(6, 12, 2.2);

    // Small eye
    g.fillStyle(0xeeeeff);
    g.fillEllipse(15, 12, 3, 4);
    g.fillStyle(0x332233);
    g.fillEllipse(15.5, 12, 2, 2.5);

    // Smile
    g.lineStyle(1.5, 0xaa3355);
    g.beginPath();
    g.arc(8, 20, 4, 0.2, Math.PI - 0.4);
    g.strokePath();

    // Blush
    g.fillStyle(0xff6688, 0.4);
    g.fillCircle(4, 18, 3);

    g.generateTexture('xochi-big', 32, 64);
    g.clear();

    // ============ SEAGULL ENEMY (white/cream with attitude) ============
    // Body shadow
    g.fillStyle(0x999999);
    g.fillEllipse(17, 20, 22, 18);
    // Body base - creamy white
    g.fillStyle(0xddddcc);
    g.fillEllipse(16, 18, 20, 16);
    // Body highlight
    g.fillStyle(0xeeeeee);
    g.fillEllipse(14, 14, 14, 10);
    // White chest
    g.fillStyle(0xfafafa);
    g.fillEllipse(16, 16, 10, 8);
    // Wing shadows (gray)
    g.fillStyle(0x888899);
    g.fillTriangle(3, 20, 12, 12, 12, 26);
    g.fillTriangle(29, 20, 20, 12, 20, 26);
    // Wing highlights
    g.fillStyle(0xaaaaaa);
    g.fillTriangle(5, 19, 12, 13, 12, 24);
    g.fillTriangle(27, 19, 20, 13, 20, 24);

    // Orange beak - chunky and angry
    g.fillStyle(0xdd8800);
    g.fillTriangle(16, 6, 9, 15, 23, 15);
    g.fillStyle(0xffaa22);
    g.fillTriangle(16, 8, 11, 14, 21, 14);
    g.fillStyle(0xffcc66);
    g.fillTriangle(16, 10, 13, 13, 19, 13);

    // Angry eyes
    g.fillStyle(0xffffff);
    g.fillCircle(11, 14, 4);
    g.fillCircle(21, 14, 4);
    // Red angry pupils
    g.fillStyle(0x222222);
    g.fillCircle(12, 14, 2.5);
    g.fillCircle(22, 14, 2.5);
    g.fillStyle(0x880000);
    g.fillCircle(12, 14, 1.5);
    g.fillCircle(22, 14, 1.5);
    // Tiny angry highlight
    g.fillStyle(0xffffff);
    g.fillCircle(11, 13, 1);
    g.fillCircle(21, 13, 1);

    // ANGRY eyebrows (V shape)
    g.fillStyle(0x333333);
    g.fillTriangle(6, 9, 14, 11, 14, 13);
    g.fillTriangle(26, 9, 18, 11, 18, 13);

    // Feet
    g.fillStyle(0xdd8800);
    g.fillRect(12, 28, 2, 4);
    g.fillRect(18, 28, 2, 4);

    g.generateTexture('enemy', 32, 32);
    g.clear();

    // ============ AZTEC-STYLE GOLD COIN ============
    // Outer glow
    g.fillStyle(0xffdd00, 0.2);
    g.fillCircle(8, 8, 8);
    // Shadow
    g.fillStyle(0x996600);
    g.fillCircle(9, 9, 7);
    // Gold base
    g.fillStyle(0xddaa00);
    g.fillCircle(8, 8, 7);
    // Gold mid
    g.fillStyle(0xffcc00);
    g.fillCircle(8, 8, 6);
    // Inner ring (carved)
    g.lineStyle(1.5, 0xaa8800);
    g.strokeCircle(8, 8, 4.5);
    // Aztec sun pattern - center
    g.fillStyle(0xaa7700);
    g.fillCircle(8, 8, 2);
    g.fillStyle(0xffdd44);
    g.fillCircle(8, 8, 1.5);
    // Sun rays (simple lines)
    g.lineStyle(1, 0xaa7700);
    for (let i = 0; i < 8; i++) {
      const angle = (i / 8) * Math.PI * 2;
      g.lineBetween(
        8 + Math.cos(angle) * 2.5, 8 + Math.sin(angle) * 2.5,
        8 + Math.cos(angle) * 4, 8 + Math.sin(angle) * 4
      );
    }
    // Highlight arc
    g.fillStyle(0xffff88);
    g.fillCircle(5, 5, 2.5);
    // Specular
    g.fillStyle(0xffffff);
    g.fillCircle(4, 4, 1);
    g.generateTexture('coin', 16, 16);
    g.clear();

    // ============ SPARKLY GOLDEN STAR ============
    // Outer glow
    g.fillStyle(0xffff00, 0.25);
    g.fillCircle(8, 8, 9);
    // Star shadow
    g.fillStyle(0xcc8800);
    drawStar(g, 9, 9, 5, 7, 3);
    // Star base
    g.fillStyle(0xffbb00);
    drawStar(g, 8, 8, 5, 7, 3);
    // Star highlight
    g.fillStyle(0xffdd44);
    drawStar(g, 7.5, 7.5, 5, 5.5, 2.5);
    // Inner glow
    g.fillStyle(0xffee88);
    drawStar(g, 7.5, 7.5, 5, 4, 2);
    // Center sparkle
    g.fillStyle(0xffffff);
    g.fillCircle(7, 6, 2);
    g.fillCircle(6, 5, 1);
    // Tiny sparkle points
    g.fillStyle(0xffffff, 0.8);
    g.fillCircle(3, 3, 0.8);
    g.fillCircle(12, 4, 0.8);
    g.fillCircle(4, 11, 0.8);
    g.generateTexture('star', 16, 16);
    g.clear();

    // ============ MUSHROOM POWERUP ============
    // Cap shadow
    g.fillStyle(0xaa2222);
    g.fillEllipse(8, 7, 15, 11);
    // Cap base
    g.fillStyle(0xdd3333);
    g.fillEllipse(8, 6, 14, 10);
    // Cap mid
    g.fillStyle(0xee4444);
    g.fillEllipse(7, 5, 12, 8);
    // Cap highlight
    g.fillStyle(0xff6666);
    g.fillEllipse(5, 3, 6, 4);
    // White spots with depth
    g.fillStyle(0xeeeeee);
    g.fillCircle(4, 4, 2.5);
    g.fillCircle(11, 3, 2);
    g.fillCircle(7, 7, 1.5);
    g.fillStyle(0xffffff);
    g.fillCircle(3.5, 3.5, 1.5);
    g.fillCircle(10.5, 2.5, 1.2);
    // Stem
    g.fillStyle(0xddddcc);
    g.fillRect(5, 10, 7, 6);
    g.fillStyle(0xffffee);
    g.fillRect(5, 10, 6, 5);
    g.fillStyle(0xffffff);
    g.fillRect(6, 10, 2, 4);
    g.generateTexture('mushroom', 16, 16);
    g.clear();

    // ============ CUTE BABY AXOLOTL ============
    // Shadow
    g.fillStyle(0xcc6699);
    g.fillCircle(9, 9, 6);
    // Body
    g.fillStyle(0xffaacc);
    g.fillCircle(8, 8, 6);
    // Highlight
    g.fillStyle(0xffccdd);
    g.fillCircle(6, 6, 3.5);
    // Top specular
    g.fillStyle(0xffeeff);
    g.fillCircle(5, 5, 2);
    // Mini gills
    g.fillStyle(0xee77aa);
    g.fillCircle(2, 4, 2.5);
    g.fillCircle(1, 7, 2);
    g.fillCircle(14, 4, 2.5);
    g.fillCircle(15, 7, 2);
    g.fillStyle(0xffaacc);
    g.fillCircle(2.5, 4.5, 1.5);
    g.fillCircle(13.5, 4.5, 1.5);
    // Big sparkly eyes
    g.fillStyle(0xffffff);
    g.fillCircle(5, 7, 2.5);
    g.fillCircle(11, 7, 2.5);
    g.fillStyle(0x222244);
    g.fillCircle(5.5, 7, 1.5);
    g.fillCircle(11.5, 7, 1.5);
    g.fillStyle(0xffffff);
    g.fillCircle(4.5, 6, 1);
    g.fillCircle(10.5, 6, 1);
    // Tiny smile
    g.lineStyle(1, 0xdd6699);
    g.beginPath();
    g.arc(8, 10, 2, 0.3, Math.PI - 0.3);
    g.strokePath();
    // Blush
    g.fillStyle(0xff8899, 0.4);
    g.fillCircle(3, 10, 1.5);
    g.fillCircle(13, 10, 1.5);
    g.generateTexture('baby', 16, 16);
    g.clear();

    // ============ MAGICAL SUPER JUMP FEATHER ============
    // Outer magic glow
    g.fillStyle(0x00ffff, 0.2);
    g.fillCircle(8, 8, 8);
    // Inner glow
    g.fillStyle(0x44ffff, 0.3);
    g.fillCircle(8, 7, 6);
    // Feather shadow
    g.fillStyle(0x0088aa);
    g.fillTriangle(8, 1, 1, 12, 15, 12);
    // Feather base
    g.fillStyle(0x00bbdd);
    g.fillTriangle(8, 2, 2, 11, 14, 11);
    // Feather highlight
    g.fillStyle(0x44ddee);
    g.fillTriangle(8, 3, 4, 10, 12, 10);
    // Inner feather
    g.fillStyle(0x88eeff);
    g.fillTriangle(8, 5, 5, 9, 11, 9);
    // Feather spine
    g.lineStyle(1, 0x008899);
    g.lineBetween(8, 2, 8, 11);
    // Feather veins
    g.lineStyle(0.5, 0x00aacc, 0.5);
    g.lineBetween(8, 4, 5, 8);
    g.lineBetween(8, 4, 11, 8);
    g.lineBetween(8, 6, 4, 10);
    g.lineBetween(8, 6, 12, 10);
    // Magic sparkles
    g.fillStyle(0xffffff);
    g.fillCircle(5, 5, 1);
    g.fillCircle(11, 5, 1);
    g.fillCircle(8, 3, 1.5);
    // Crystal base
    g.fillStyle(0x006688);
    g.fillRect(5, 11, 6, 4);
    g.fillStyle(0x00aacc);
    g.fillRect(6, 11, 4, 3);
    g.fillStyle(0x66eeff);
    g.fillRect(7, 11, 2, 2);
    g.generateTexture('superjump', 16, 16);
    g.clear();

    // ============ ENEMY PROJECTILE (angry red orb) ============
    // Outer glow
    g.fillStyle(0xff0000, 0.3);
    g.fillCircle(6, 6, 6);
    // Fire ring
    g.fillStyle(0xff4400);
    g.fillCircle(6, 6, 5);
    // Core
    g.fillStyle(0xff6600);
    g.fillCircle(6, 6, 4);
    // Hot center
    g.fillStyle(0xffaa00);
    g.fillCircle(5, 5, 2.5);
    // White hot
    g.fillStyle(0xffdd88);
    g.fillCircle(4, 4, 1.5);
    g.fillStyle(0xffffff);
    g.fillCircle(4, 4, 0.8);
    g.generateTexture('projectile', 12, 12);
    g.clear();

    g.destroy();
  }
}

// ============== MENU SCENE ==============
class MenuScene extends Phaser.Scene {
  constructor() { super('MenuScene'); }

  create() {
    const { width, height } = this.cameras.main;

    // ============ SNES-STYLE GRADIENT BACKGROUND ============
    const bg = this.add.graphics();
    const bgColors = [0x1a0a2e, 0x1a1a3e, 0x2a2a4e, 0x1a2a4e, 0x1a1a3e, 0x1a0a2e];
    const stripeH = height / bgColors.length;
    bgColors.forEach((color, i) => {
      bg.fillStyle(color);
      bg.fillRect(0, i * stripeH, width, stripeH + 2);
    });

    // ============ ANIMATED STARS BACKGROUND ============
    for (let i = 0; i < 30; i++) {
      const star = this.add.circle(
        Phaser.Math.Between(0, width),
        Phaser.Math.Between(0, height),
        Phaser.Math.Between(1, 3),
        0xffffff, Phaser.Math.FloatBetween(0.2, 0.8)
      );
      this.tweens.add({
        targets: star, alpha: 0.1,
        duration: Phaser.Math.Between(500, 1500),
        yoyo: true, repeat: -1
      });
    }

    // ============ FLOATING PARTICLES ============
    for (let i = 0; i < 12; i++) {
      const colors = [0x4ecdc4, 0xff6b9d, 0xffdd00];
      const p = this.add.circle(
        Phaser.Math.Between(0, width),
        Phaser.Math.Between(0, height),
        Phaser.Math.Between(3, 6),
        Phaser.Utils.Array.GetRandom(colors), 0.4
      );
      this.tweens.add({
        targets: p, y: '-=120', alpha: 0, scale: 0.5,
        duration: Phaser.Math.Between(3000, 5000),
        repeat: -1,
        onRepeat: () => { p.x = Phaser.Math.Between(0, width); p.y = height + 30; p.alpha = 0.4; p.scale = 1; }
      });
    }

    // ============ SNES-STYLE TITLE WITH SHADOW ============
    // Title shadow
    this.add.text(width/2 + 4, 58 + 4, 'XOCHI', {
      fontFamily: 'Arial Black', fontSize: '60px', color: '#220022'
    }).setOrigin(0.5);
    // Title main
    const title = this.add.text(width/2, 58, 'XOCHI', {
      fontFamily: 'Arial Black', fontSize: '60px', color: '#ff6b9d',
      stroke: '#ffbbcc', strokeThickness: 4
    }).setOrigin(0.5);
    // Title shine animation
    this.tweens.add({ targets: title, scaleX: 1.02, scaleY: 1.02, duration: 1500, yoyo: true, repeat: -1, ease: 'Sine.easeInOut' });

    // Subtitle with glow
    this.add.text(width/2, 108, 'Aztec Warrior Adventure', {
      fontFamily: 'Georgia', fontSize: '20px', color: '#66ddcc',
      stroke: '#224444', strokeThickness: 2
    }).setOrigin(0.5);

    // ============ CHARACTER PREVIEW WITH GLOW ============
    // Glow behind character
    const glow = this.add.circle(width/2, 170, 35, 0xff6b9d, 0.3);
    this.tweens.add({ targets: glow, scale: 1.2, alpha: 0.1, duration: 1000, yoyo: true, repeat: -1 });
    // Character
    const xochi = this.add.sprite(width/2, 170, 'xochi').setScale(0.12);
    this.tweens.add({ targets: xochi, y: 160, duration: 800, yoyo: true, repeat: -1, ease: 'Sine.easeInOut' });

    // ============ SNES-STYLE SCOREBOARD ============
    // Box shadow
    this.add.rectangle(width/2 + 3, 243, 310, 68, 0x000000, 0.5);
    // Box border
    this.add.rectangle(width/2, 240, 310, 68, 0x4ecdc4);
    // Box fill
    this.add.rectangle(width/2, 240, 304, 62, 0x1a2a4e);
    // Inner highlight
    this.add.rectangle(width/2, 218, 300, 2, 0x5eede4, 0.5);

    this.add.text(width/2, 222, `SCORE: ${gameState.score}`, {
      fontFamily: 'Arial Black', fontSize: '20px', color: '#ffee44',
      stroke: '#886600', strokeThickness: 2
    }).setOrigin(0.5);
    this.add.text(width/2, 250, `HIGH SCORE: ${gameState.highScore}`, {
      fontFamily: 'Arial', fontSize: '15px', color: '#ff88aa'
    }).setOrigin(0.5);

    // Progress bar style
    this.add.text(width/2, 290, `Level ${gameState.currentLevel}/10 | ★ ${gameState.stars.length}/30 | ♥ ${gameState.rescuedBabies.length}/10`, {
      fontFamily: 'Arial', fontSize: '13px', color: '#88aacc'
    }).setOrigin(0.5);

    // ============ SNES-STYLE BUTTONS ============
    // CONTINUE/PLAY button
    this.createSNESButton(width/2, 345, 200, 50, 0x33bb99, 0x22aa88, 0x44ccaa,
      gameState.currentLevel > 1 ? 'CONTINUE' : 'PLAY', () => {
        if (gameState.musicEnabled && !mariachiMusic.isPlaying) mariachiMusic.start();
        this.scene.start('GameScene', { level: gameState.currentLevel });
      });

    // NEW GAME button
    this.createSNESButton(width/2, 405, 200, 50, 0xdd5588, 0xcc4477, 0xee6699,
      'NEW GAME', () => {
        resetGame();
        if (gameState.musicEnabled && !mariachiMusic.isPlaying) mariachiMusic.start();
        this.scene.start('GameScene', { level: 1 });
      });

    // World names with icons
    this.add.text(width/2, 455, '🌸 Gardens → 🏛️ Ruins → 💎 Caves → 🌴 Jungle → 🌋 Volcano', {
      fontFamily: 'Arial', fontSize: '11px', color: '#778899'
    }).setOrigin(0.5);

    // Controls
    this.add.text(width/2, height - 45, 'Arrows/WASD = Move | Space = Jump | Shift = Run', {
      fontFamily: 'Arial', fontSize: '11px', color: '#555555'
    }).setOrigin(0.5);
    this.add.text(width/2, height - 28, 'X = SUPER JUMP (works mid-air!)', {
      fontFamily: 'Arial', fontSize: '11px', color: '#00aaaa'
    }).setOrigin(0.5);

    // Keyboard
    this.input.keyboard.on('keydown-SPACE', () => {
      if (gameState.musicEnabled && !mariachiMusic.isPlaying) mariachiMusic.start();
      this.scene.start('GameScene', { level: gameState.currentLevel });
    });
  }

  // SNES-style 3D button helper
  createSNESButton(x, y, w, h, baseColor, darkColor, lightColor, text, callback) {
    // Shadow
    this.add.rectangle(x + 3, y + 3, w, h, 0x000000, 0.4);
    // Dark edge (bottom/right)
    this.add.rectangle(x + 2, y + 2, w, h, darkColor);
    // Main button
    const btn = this.add.rectangle(x, y, w - 4, h - 4, baseColor).setInteractive({ useHandCursor: true });
    // Top highlight
    this.add.rectangle(x, y - h/4, w - 8, 4, lightColor, 0.5);
    // Text shadow
    this.add.text(x + 2, y + 2, text, { fontFamily: 'Arial Black', fontSize: '22px', color: '#000000' }).setOrigin(0.5);
    // Text
    this.add.text(x, y, text, { fontFamily: 'Arial Black', fontSize: '22px', color: '#ffffff', stroke: '#000000', strokeThickness: 1 }).setOrigin(0.5);

    btn.on('pointerover', () => { btn.setScale(1.05); btn.setFillStyle(lightColor); });
    btn.on('pointerout', () => { btn.setScale(1); btn.setFillStyle(baseColor); });
    btn.on('pointerdown', callback);
    return btn;
  }
}

// ============== GAME SCENE ==============
class GameScene extends Phaser.Scene {
  constructor() { super('GameScene'); }

  init(data) {
    this.levelNum = data.level || 1;
    this.levelData = LEVELS[this.levelNum - 1];
  }

  create() {
    const ld = this.levelData;

    // World bounds
    this.physics.world.setBounds(0, 0, ld.width, ld.height);

    // ============ SNES-STYLE SKY WITH GRADIENT ============
    const skyGradient = this.add.graphics();
    // Create vertical gradient from light blue to deeper blue
    const skyColors = [0x88ddff, 0x66ccff, 0x44bbff, 0x33aaee, 0x2299dd, 0x1188cc];
    const stripeHeight = ld.height / skyColors.length;
    skyColors.forEach((color, i) => {
      skyGradient.fillStyle(color);
      skyGradient.fillRect(0, i * stripeHeight, ld.width, stripeHeight + 2);
    });

    // ============ PARALLAX BACKGROUND MOUNTAINS (far) ============
    const mountains = this.add.graphics();
    mountains.fillStyle(0x6688aa, 0.4);
    for (let i = 0; i < ld.width / 200 + 2; i++) {
      const mx = i * 200 - 50;
      const mh = Phaser.Math.Between(100, 180);
      mountains.fillTriangle(mx, ld.height - 100, mx + 100, ld.height - 100 - mh, mx + 200, ld.height - 100);
    }
    mountains.setScrollFactor(0.1);

    // ============ PARALLAX HILLS (mid) ============
    const hills = this.add.graphics();
    hills.fillStyle(0x55aa66, 0.5);
    for (let i = 0; i < ld.width / 150 + 2; i++) {
      const hx = i * 150 - 30;
      hills.fillEllipse(hx + 75, ld.height - 60, 160, 100);
    }
    hills.setScrollFactor(0.3);

    // ============ SNES-STYLE CLOUDS (multiple layers) ============
    // Far clouds (slower parallax)
    for (let i = 0; i < 8; i++) {
      const cx = Phaser.Math.Between(0, ld.width);
      const cy = Phaser.Math.Between(40, 120);
      // Cloud shadow
      this.add.ellipse(cx + 2, cy + 2, Phaser.Math.Between(60, 100), Phaser.Math.Between(25, 35), 0x99ccee, 0.3).setScrollFactor(0.15);
      // Cloud body
      this.add.ellipse(cx, cy, Phaser.Math.Between(60, 100), Phaser.Math.Between(25, 35), 0xffffff, 0.8).setScrollFactor(0.15);
      // Cloud highlight
      this.add.ellipse(cx - 10, cy - 5, Phaser.Math.Between(30, 50), Phaser.Math.Between(15, 20), 0xffffff, 0.9).setScrollFactor(0.15);
    }
    // Near clouds (faster parallax)
    for (let i = 0; i < 6; i++) {
      const cx = Phaser.Math.Between(0, ld.width);
      const cy = Phaser.Math.Between(60, 150);
      this.add.ellipse(cx + 3, cy + 3, Phaser.Math.Between(80, 130), Phaser.Math.Between(35, 50), 0xaaddff, 0.2).setScrollFactor(0.3);
      this.add.ellipse(cx, cy, Phaser.Math.Between(80, 130), Phaser.Math.Between(35, 50), 0xffffff, 0.7).setScrollFactor(0.3);
    }

    // ============ SNES-STYLE PLATFORMS WITH SHADING ============
    this.platforms = this.physics.add.staticGroup();
    ld.platforms.forEach(p => {
      const isGround = p.h > 30;
      const baseColor = isGround ? 0x8B5522 : 0x33aa44;
      const darkColor = isGround ? 0x5a3311 : 0x228833;
      const lightColor = isGround ? 0xaa7744 : 0x55cc66;
      const topColor = isGround ? 0x55aa44 : 0x66dd77;

      // Platform shadow
      this.add.rectangle(p.x + p.w/2 + 3, p.y + p.h/2 + 3, p.w, p.h, 0x000000, 0.2);

      // Platform base (dark)
      this.add.rectangle(p.x + p.w/2, p.y + p.h/2, p.w, p.h, darkColor);

      // Platform main body
      const plat = this.add.rectangle(p.x + p.w/2, p.y + p.h/2 - 2, p.w - 2, p.h - 4, baseColor);
      this.physics.add.existing(plat, true);
      this.platforms.add(plat);

      // Platform top highlight
      this.add.rectangle(p.x + p.w/2, p.y + 4, p.w - 4, 6, lightColor);

      // Grass/surface detail
      this.add.rectangle(p.x + p.w/2, p.y + 2, p.w - 2, 3, topColor);

      // Add grass tufts on platforms
      if (!isGround) {
        for (let gx = p.x + 10; gx < p.x + p.w - 10; gx += 20) {
          this.add.triangle(gx, p.y, gx - 4, p.y, gx, p.y - 6, gx + 4, p.y, 0x44bb55, 0.8);
        }
      }

      // Add dirt texture lines for ground
      if (isGround && p.h > 35) {
        for (let dy = 15; dy < p.h - 5; dy += 12) {
          this.add.rectangle(p.x + p.w/2, p.y + dy, p.w - 10, 2, darkColor, 0.3);
        }
      }
    });

    // Coins
    this.coins = this.physics.add.group();
    ld.coins.forEach(c => {
      const coin = this.coins.create(c.x, c.y, 'coin').setScale(1.5);
      coin.body.allowGravity = false;
      this.tweens.add({ targets: coin, y: c.y - 5, duration: 500, yoyo: true, repeat: -1 });
    });

    // Stars
    this.stars = this.physics.add.group();
    ld.stars.forEach((s, i) => {
      const starId = `${this.levelNum}-${i}`;
      if (!gameState.stars.includes(starId)) {
        const star = this.stars.create(s.x, s.y, 'star').setScale(1.5);
        star.starId = starId;
        star.body.allowGravity = false;
        this.tweens.add({ targets: star, angle: 360, duration: 2000, repeat: -1 });
      }
    });

    // Baby axolotl
    const babyId = `baby-${this.levelNum}`;
    if (!gameState.rescuedBabies.includes(babyId)) {
      this.baby = this.physics.add.sprite(ld.babyPosition.x, ld.babyPosition.y, 'baby').setScale(2);
      this.baby.body.allowGravity = false;
      this.baby.babyId = babyId;
      this.tweens.add({ targets: this.baby, y: ld.babyPosition.y - 10, duration: 600, yoyo: true, repeat: -1 });
    }

    // Enemies - types: ground, platform, flying
    this.enemies = this.physics.add.group();
    this.flyingEnemies = [];
    this.projectiles = this.physics.add.group(); // Enemy projectiles!

    ld.enemies.forEach(e => {
      const type = e.type || 'ground';
      const enemy = this.enemies.create(e.x, e.y, 'enemy').setScale(1.5);
      enemy.setData('dir', e.dir || (Phaser.Math.Between(0,1) ? 1 : -1));
      enemy.setData('alive', true);
      enemy.setData('type', type);

      if (type === 'flying') {
        // Flying enemies - flappy bird style!
        enemy.body.allowGravity = false;
        enemy.setTint(0xff6699);
        enemy.setData('baseY', e.y);
        enemy.setData('flapTimer', 0);
        enemy.setData('flapUp', true);
        enemy.setData('speed', e.speed || 80);
        enemy.setData('shootTimer', Phaser.Math.Between(1000, 3000)); // Random first shot
        enemy.body.setVelocityX(enemy.getData('speed') * enemy.getData('dir'));
        this.flyingEnemies.push(enemy);
      } else if (type === 'platform') {
        // Platform enemies - find their platform bounds
        const plat = this.findPlatformAt(e.x, e.y + 30);
        if (plat) {
          enemy.setData('platLeft', plat.x - plat.width/2 + 10);
          enemy.setData('platRight', plat.x + plat.width/2 - 10);
        } else {
          enemy.setData('platLeft', e.x - 60);
          enemy.setData('platRight', e.x + 60);
        }
        enemy.setTint(0x99ff99);
        enemy.body.setVelocityX(40 * enemy.getData('dir'));
      } else {
        // Ground enemies
        enemy.body.setVelocityX(60 * enemy.getData('dir'));
      }
      enemy.setFlipX(enemy.getData('dir') > 0);
    });

    // DARK XOCHI - Boss on levels 5 and 10 only!
    this.darkXochi = null;
    this.bossTimer = null;
    this.bossTimeLeft = 0;
    const isBossLevel = (this.levelNum === 5 || this.levelNum === 10);
    if (isBossLevel && !gameState.rescuedBabies.includes(`baby-${this.levelNum}`)) {
      // Dark Xochi spawns at level start position
      this.darkXochi = this.physics.add.sprite(ld.playerSpawn.x + 100, ld.playerSpawn.y, 'xochi').setScale(0.06);
      this.darkXochi.setTint(0x440044); // Dark purple evil Xochi!
      this.darkXochi.setData('alive', true);
      this.darkXochi.setData('speed', this.levelNum === 10 ? 140 : 110);
      this.darkXochi.body.setSize(400, 500);
      this.darkXochi.body.setOffset(300, 250);

      // Boss timer - race against time!
      this.bossTimeLeft = this.levelNum === 10 ? 60 : 45; // 45 sec level 5, 60 sec level 10
      this.bossTimerText = this.add.text(this.cameras.main.width / 2, 60, '', {
        fontFamily: 'Arial Black', fontSize: '28px', color: '#ff0000',
        stroke: '#000', strokeThickness: 3
      }).setOrigin(0.5).setScrollFactor(0).setDepth(100);

      this.bossTimer = this.time.addEvent({
        delay: 1000,
        callback: () => {
          this.bossTimeLeft--;
          if (this.bossTimeLeft <= 0 && this.darkXochi && this.darkXochi.getData('alive')) {
            // Time's up! Dark Xochi wins!
            this.darkXochiWins();
          }
        },
        loop: true
      });

      // Dark Xochi collides with platforms
      this.physics.add.collider(this.darkXochi, this.platforms);
      if (this.baby) {
        this.physics.add.overlap(this.darkXochi, this.baby, this.darkXochiGetsBaby, null, this);
      }
      // Player overlaps added after player is created below
    }

    // Super Jump Power-ups
    this.powerups = this.physics.add.group();
    if (ld.powerups) {
      ld.powerups.forEach(p => {
        const powerup = this.powerups.create(p.x, p.y, 'superjump').setScale(1.5);
        powerup.body.allowGravity = false;
        this.tweens.add({ targets: powerup, y: p.y - 8, duration: 400, yoyo: true, repeat: -1, ease: 'Sine.easeInOut' });
      });
    }

    // Player (Aztec warrior girl - 1024x1024 sprite scaled down)
    this.player = this.physics.add.sprite(ld.playerSpawn.x, ld.playerSpawn.y, 'xochi').setScale(0.06);
    this.player.setCollideWorldBounds(true);
    this.player.body.setSize(400, 500); // Hitbox for 1024px sprite
    this.player.body.setOffset(300, 250); // Center hitbox on character
    this.player.setData('big', false);
    this.player.setData('invincible', false);
    this.player.setData('dead', false);

    // Camera
    this.cameras.main.setBounds(0, 0, ld.width, ld.height);
    this.cameras.main.startFollow(this.player, true, 0.08, 0.08);

    // Collisions
    this.physics.add.collider(this.player, this.platforms);
    this.physics.add.collider(this.enemies, this.platforms, (enemy) => {
      // Only ground/platform enemies collide - flying enemies don't
      if (enemy.getData('type') === 'flying') return;
      if (enemy.body.blocked.left || enemy.body.blocked.right) {
        enemy.setData('dir', enemy.getData('dir') * -1);
        const speed = enemy.getData('type') === 'platform' ? 40 : 60;
        enemy.body.setVelocityX(speed * enemy.getData('dir'));
        enemy.setFlipX(enemy.getData('dir') > 0);
      }
    });
    this.physics.add.overlap(this.player, this.coins, this.collectCoin, null, this);
    this.physics.add.overlap(this.player, this.stars, this.collectStar, null, this);
    this.physics.add.overlap(this.player, this.enemies, this.hitEnemy, null, this);
    this.physics.add.overlap(this.player, this.powerups, this.collectPowerup, null, this);
    this.physics.add.overlap(this.player, this.projectiles, this.hitByProjectile, null, this);
    if (this.baby) {
      this.physics.add.overlap(this.player, this.baby, this.rescueBaby, null, this);
    }
    if (this.darkXochi) {
      this.physics.add.overlap(this.player, this.darkXochi, this.hitDarkXochi, null, this);
    }

    // Input
    this.cursors = this.input.keyboard.createCursorKeys();
    this.keys = this.input.keyboard.addKeys({ W: 'W', A: 'A', D: 'D', SPACE: 'SPACE', SHIFT: 'SHIFT', X: 'X', C: 'C' });

    // ============ ANIMATION STATE ============
    this.walkTime = 0;           // For walk animation cycle
    this.idleTime = 0;           // For idle animation cycle
    this.isAttacking = false;    // Mace attack state
    this.attackCooldown = 0;     // Cooldown between attacks
    this.lastIdleMove = 0;       // Time of last idle pose change

    // ============ TOUCH CONTROLS FOR MOBILE ============
    this.touchControls = { left: false, right: false, jump: false, superJump: false, attack: false };
    this.setupTouchControls();

    // UI
    this.scene.launch('UIScene', { levelNum: this.levelNum });

    // Pause
    this.input.keyboard.on('keydown-ESC', () => {
      this.scene.launch('PauseScene');
      this.scene.pause();
    });

    // Start MARIACHI music! 🎺
    if (gameState.musicEnabled && !mariachiMusic.isPlaying) {
      mariachiMusic.start();
    }
  }

  playSound(key) {
    if (gameState.sfxEnabled) {
      this.sound.play(key, { volume: 0.5 });
    }
  }

  // ============ TOUCH CONTROLS SETUP ============
  setupTouchControls() {
    // Only show on touch devices
    if (!this.sys.game.device.input.touch) return;

    const { width, height } = this.cameras.main;
    const btnSize = 70;
    const btnAlpha = 0.5;
    const margin = 20;

    // Left arrow button
    const leftBtn = this.add.circle(margin + btnSize/2, height - margin - btnSize/2, btnSize/2, 0x4ecdc4, btnAlpha)
      .setScrollFactor(0).setDepth(1000).setInteractive();
    this.add.triangle(margin + btnSize/2, height - margin - btnSize/2, 15, 0, -10, -15, -10, 15, 0xffffff)
      .setScrollFactor(0).setDepth(1001).setAngle(-90);

    leftBtn.on('pointerdown', () => { this.touchControls.left = true; });
    leftBtn.on('pointerup', () => { this.touchControls.left = false; });
    leftBtn.on('pointerout', () => { this.touchControls.left = false; });

    // Right arrow button
    const rightBtn = this.add.circle(margin + btnSize * 1.8, height - margin - btnSize/2, btnSize/2, 0x4ecdc4, btnAlpha)
      .setScrollFactor(0).setDepth(1000).setInteractive();
    this.add.triangle(margin + btnSize * 1.8, height - margin - btnSize/2, 15, 0, -10, -15, -10, 15, 0xffffff)
      .setScrollFactor(0).setDepth(1001).setAngle(90);

    rightBtn.on('pointerdown', () => { this.touchControls.right = true; });
    rightBtn.on('pointerup', () => { this.touchControls.right = false; });
    rightBtn.on('pointerout', () => { this.touchControls.right = false; });

    // Jump button (right side) - tap to jump
    const jumpBtn = this.add.circle(width - margin - btnSize/2, height - margin - btnSize/2, btnSize/2, 0xff6b9d, btnAlpha)
      .setScrollFactor(0).setDepth(1000).setInteractive();
    this.add.text(width - margin - btnSize/2, height - margin - btnSize/2, 'JUMP', {
      fontFamily: 'Arial', fontSize: '14px', color: '#fff'
    }).setOrigin(0.5).setScrollFactor(0).setDepth(1001);

    jumpBtn.on('pointerdown', () => { this.touchControls.jump = true; });
    jumpBtn.on('pointerup', () => { this.touchControls.jump = false; });
    jumpBtn.on('pointerout', () => { this.touchControls.jump = false; });

    // Super Jump button (above jump button)
    const superBtn = this.add.circle(width - margin - btnSize/2, height - margin - btnSize * 1.6, btnSize/2, 0x00dddd, btnAlpha)
      .setScrollFactor(0).setDepth(1000).setInteractive();
    this.add.text(width - margin - btnSize/2, height - margin - btnSize * 1.6, 'SUPER', {
      fontFamily: 'Arial', fontSize: '12px', color: '#fff'
    }).setOrigin(0.5).setScrollFactor(0).setDepth(1001);

    // Attack button (left of jump button) - THUNDERSHOCK!
    const attackBtn = this.add.circle(width - margin - btnSize * 1.7, height - margin - btnSize/2, btnSize/2, 0xffff00, btnAlpha)
      .setScrollFactor(0).setDepth(1000).setInteractive();
    this.add.text(width - margin - btnSize * 1.7, height - margin - btnSize/2, '⚡ATK', {
      fontFamily: 'Arial', fontSize: '12px', color: '#000'
    }).setOrigin(0.5).setScrollFactor(0).setDepth(1001);

    attackBtn.on('pointerdown', () => { this.touchControls.attack = true; });
    attackBtn.on('pointerup', () => { this.touchControls.attack = false; });
    attackBtn.on('pointerout', () => { this.touchControls.attack = false; });

    superBtn.on('pointerdown', () => {
      this.touchControls.superJump = true;
      // Trigger super jump immediately
      if (gameState.superJumps > 0) {
        gameState.superJumps--;
        this.player.body.setVelocityY(-650);
        this.playSound('sfx-superjump');
        this.showText(this.player.x, this.player.y - 30, 'SUPER!', '#00ffff');
        this.events.emit('updateUI');
        // Visual burst
        for (let i = 0; i < 8; i++) {
          const angle = (i / 8) * Math.PI * 2;
          const trail = this.add.circle(
            this.player.x + Math.cos(angle) * 10,
            this.player.y + Math.sin(angle) * 10,
            6, 0x00ffff, 0.8
          );
          this.tweens.add({
            targets: trail,
            x: this.player.x + Math.cos(angle) * 40,
            y: this.player.y + Math.sin(angle) * 40,
            alpha: 0, scale: 0.5, duration: 300,
            onComplete: () => trail.destroy()
          });
        }
      }
    });
    superBtn.on('pointerup', () => { this.touchControls.superJump = false; });

    // Double-tap anywhere on right side of screen for quick super jump
    this.lastTapTime = 0;
    this.input.on('pointerdown', (pointer) => {
      if (pointer.x > width / 2) {
        const now = this.time.now;
        if (now - this.lastTapTime < 300) {
          // Double tap detected - super jump!
          if (gameState.superJumps > 0 && !this.player.getData('dead')) {
            gameState.superJumps--;
            this.player.body.setVelocityY(-650);
            this.playSound('sfx-superjump');
            this.showText(this.player.x, this.player.y - 30, 'SUPER!', '#00ffff');
            this.events.emit('updateUI');
          }
        }
        this.lastTapTime = now;
      }
    });

    // Pause button (top right corner)
    const pauseBtn = this.add.circle(width - 30, 70, 20, 0x666666, 0.6)
      .setScrollFactor(0).setDepth(1000).setInteractive();
    this.add.text(width - 30, 70, '||', {
      fontFamily: 'Arial', fontSize: '16px', color: '#fff'
    }).setOrigin(0.5).setScrollFactor(0).setDepth(1001);
    pauseBtn.on('pointerdown', () => {
      this.scene.launch('PauseScene');
      this.scene.pause();
    });
  }

  // Find platform at position (for platform enemy bounds)
  findPlatformAt(x, y) {
    let found = null;
    this.platforms.getChildren().forEach(p => {
      if (x >= p.x - p.width/2 && x <= p.x + p.width/2 &&
          y >= p.y - p.height/2 && y <= p.y + p.height/2 + 20) {
        found = p;
      }
    });
    return found;
  }

  // Flying enemy shoots projectile at player
  shootProjectile(enemy) {
    if (!enemy.getData('alive') || !this.player) return;

    const proj = this.projectiles.create(enemy.x, enemy.y + 10, 'projectile');
    proj.setScale(1.2);
    proj.body.allowGravity = false;

    // Aim at player
    const angle = Phaser.Math.Angle.Between(enemy.x, enemy.y, this.player.x, this.player.y);
    const speed = 200;
    proj.body.setVelocity(Math.cos(angle) * speed, Math.sin(angle) * speed);

    // Destroy after 3 seconds
    this.time.delayedCall(3000, () => {
      if (proj && proj.active) proj.destroy();
    });
  }

  hitByProjectile(player, projectile) {
    if (player.getData('invincible')) {
      projectile.destroy();
      return;
    }

    projectile.destroy();
    this.playSound('sfx-hurt');

    if (player.getData('big')) {
      player.setData('big', false);
      player.setTexture('xochi');
      player.body.setSize(12, 14);
      this.setInvincible(2000);
    } else {
      this.playerDie();
    }
  }

  collectPowerup(player, powerup) {
    powerup.destroy();
    gameState.superJumps += 3;
    this.playSound('sfx-powerup');
    this.showBigText('+3 SUPER JUMPS!', '#00ffff');
    this.events.emit('updateUI');
  }

  collectCoin(player, coin) {
    coin.destroy();
    gameState.coins++;
    gameState.score += 10; // +10 points per coin
    this.playSound('sfx-coin');
    this.showText(coin.x, coin.y - 20, '+10', '#ffdd00');
    this.events.emit('updateUI');
    // Super jump every 10 coins
    if (gameState.coins % 10 === 0) {
      gameState.superJumps++;
      this.showBigText('+1 SUPER JUMP!', '#00ffff');
    }
    // Extra life at 100 coins
    if (gameState.coins >= 100) {
      gameState.coins -= 100;
      gameState.lives++;
      this.showBigText('1UP!', '#ffdd00');
    }
  }

  collectStar(player, star) {
    gameState.stars.push(star.starId);
    gameState.superJumps += 2;
    gameState.score += 500; // +500 points per star!
    star.destroy();
    this.playSound('sfx-powerup');
    this.showBigText('STAR! +500pts', '#ffff00');
    this.events.emit('updateUI');
    saveGame();
  }

  hitEnemy(player, enemy) {
    if (player.getData('invincible') || !enemy.getData('alive')) return;

    if (player.body.velocity.y > 0 && player.y < enemy.y - 10) {
      // Stomp
      enemy.setData('alive', false);
      enemy.body.setVelocity(0);
      enemy.setTint(0x888888);
      this.time.delayedCall(300, () => enemy.destroy());
      player.body.setVelocityY(-300);
      this.playSound('sfx-stomp');
      gameState.score += 100; // +100 points per stomp
      this.showText(enemy.x, enemy.y - 20, '+100', '#ffffff');
    } else {
      // Hit
      this.playSound('sfx-hurt');
      if (player.getData('big')) {
        player.setData('big', false);
        player.setTexture('xochi');
        player.body.setSize(12, 14);
        this.setInvincible(2000);
      } else {
        this.playerDie();
      }
    }
  }

  // DARK XOCHI collision - player touches the boss
  hitDarkXochi(player, darkXochi) {
    if (player.getData('invincible') || !darkXochi.getData('alive')) return;

    if (player.body.velocity.y > 0 && player.y < darkXochi.y - 10) {
      // Stomp Dark Xochi! HUGE points!
      darkXochi.setData('alive', false);
      darkXochi.body.setVelocity(0);
      darkXochi.setTint(0x222222);
      if (this.bossTimer) this.bossTimer.remove();
      if (this.bossTimerText) this.bossTimerText.destroy();
      this.time.delayedCall(500, () => darkXochi.destroy());
      player.body.setVelocityY(-400);
      this.playSound('sfx-stomp');
      gameState.score += 2000; // +2000 for defeating Dark Xochi!
      this.showBigText('DARK XOCHI DEFEATED! +2000', '#ff00ff');
      this.darkXochi = null;
    } else {
      // Hit by Dark Xochi
      this.playSound('sfx-hurt');
      if (player.getData('big')) {
        player.setData('big', false);
        player.setTexture('xochi');
        player.body.setSize(12, 14);
        this.setInvincible(2000);
      } else {
        this.playerDie();
      }
    }
  }

  // Dark Xochi reaches the baby first!
  darkXochiGetsBaby(darkXochi, baby) {
    if (!darkXochi.getData('alive')) return;
    baby.destroy();
    this.baby = null;
    darkXochi.setData('alive', false);
    darkXochi.body.setVelocity(0);
    if (this.bossTimer) this.bossTimer.remove();
    if (this.bossTimerText) this.bossTimerText.destroy();

    this.showBigText('DARK XOCHI GOT THE BABY!', '#ff00ff');
    this.playSound('sfx-hurt');

    // Lose a life and restart
    this.time.delayedCall(2000, () => {
      gameState.lives--;
      if (gameState.lives <= 0) {
        gameState.lives = 3;
        gameState.coins = 0;
        mariachiMusic.stop();
        this.scene.stop('UIScene');
        this.scene.start('MenuScene');
      } else {
        this.scene.restart({ level: this.levelNum });
      }
    });
  }

  // Timer ran out - Dark Xochi wins by default
  darkXochiWins() {
    if (!this.darkXochi || !this.darkXochi.getData('alive')) return;
    if (this.bossTimerText) this.bossTimerText.destroy();

    this.showBigText('TIME UP! DARK XOCHI WINS!', '#ff0000');
    this.playSound('sfx-hurt');

    // Same as losing to Dark Xochi
    this.time.delayedCall(2000, () => {
      gameState.lives--;
      if (gameState.lives <= 0) {
        gameState.lives = 3;
        gameState.coins = 0;
        mariachiMusic.stop();
        this.scene.stop('UIScene');
        this.scene.start('MenuScene');
      } else {
        this.scene.restart({ level: this.levelNum });
      }
    });
  }

  rescueBaby(player, baby) {
    gameState.rescuedBabies.push(baby.babyId);

    // Boss level bonus! (levels 5 and 10)
    const isBossLevel = (this.levelNum === 5 || this.levelNum === 10);
    let points = 1000;
    if (isBossLevel && this.bossTimeLeft > 0) {
      // Bonus points for time remaining!
      points += this.bossTimeLeft * 50;
      this.showBigText(`BOSS BEATEN! +${points}`, '#ff00ff');
    } else {
      this.showBigText('RESCUED! +1000', '#ff6b9d');
    }
    gameState.score += points;

    baby.destroy();
    this.baby = null;

    // Clean up Dark Xochi boss stuff
    if (this.darkXochi) {
      this.darkXochi.destroy();
      this.darkXochi = null;
    }
    if (this.bossTimer) {
      this.bossTimer.remove();
      this.bossTimer = null;
    }
    if (this.bossTimerText) {
      this.bossTimerText.destroy();
      this.bossTimerText = null;
    }

    this.playSound('sfx-powerup');
    saveGame();
    this.time.delayedCall(1500, () => this.nextLevel());
  }

  nextLevel() {
    if (this.levelNum >= 10) { // Now 10 levels!
      mariachiMusic.stop(); // Victory!
      this.scene.stop('UIScene');
      this.scene.start('EndScene');
    } else {
      gameState.currentLevel = this.levelNum + 1;
      saveGame();
      this.scene.restart({ level: this.levelNum + 1 });
    }
  }

  playerDie() {
    if (this.player.getData('dead')) return;
    this.player.setData('dead', true);
    this.player.body.setVelocity(0, -300);
    this.player.setTint(0xff0000);
    gameState.lives--;

    this.time.delayedCall(1500, () => {
      if (gameState.lives <= 0) {
        gameState.lives = 3;
        gameState.coins = 0;
        mariachiMusic.stop();
        this.scene.stop('UIScene');
        this.scene.start('MenuScene');
      } else {
        this.scene.restart({ level: this.levelNum });
      }
    });
  }

  setInvincible(duration) {
    this.player.setData('invincible', true);
    this.tweens.add({
      targets: this.player,
      alpha: 0.3,
      duration: 100,
      yoyo: true,
      repeat: duration / 200,
      onComplete: () => { this.player.setData('invincible', false); this.player.setAlpha(1); }
    });
  }

  showText(x, y, text, color) {
    const t = this.add.text(x, y, text, { fontFamily: 'Arial', fontSize: '16px', color: color }).setOrigin(0.5);
    this.tweens.add({ targets: t, y: y - 30, alpha: 0, duration: 600, onComplete: () => t.destroy() });
  }

  showBigText(text, color) {
    const { width, height } = this.cameras.main;
    const t = this.add.text(width/2, height/3, text, {
      fontFamily: 'Arial Black', fontSize: '48px', color: color, stroke: '#000', strokeThickness: 4
    }).setOrigin(0.5).setScrollFactor(0);
    this.tweens.add({ targets: t, scale: 1.3, alpha: 0, duration: 1000, onComplete: () => t.destroy() });
  }

  update() {
    if (this.player.getData('dead')) return;

    const onGround = this.player.body.blocked.down;
    const speed = this.keys.SHIFT.isDown ? 280 : 180;
    const tc = this.touchControls;

    // Movement (keyboard + touch)
    if (this.cursors.left.isDown || this.keys.A.isDown || tc.left) {
      this.player.body.setVelocityX(-speed);
      this.player.setFlipX(true);
    } else if (this.cursors.right.isDown || this.keys.D.isDown || tc.right) {
      this.player.body.setVelocityX(speed);
      this.player.setFlipX(false);
    } else {
      this.player.body.setVelocityX(this.player.body.velocity.x * 0.8);
    }

    // Regular Jump (keyboard + touch)
    const jumpPressed = Phaser.Input.Keyboard.JustDown(this.cursors.up) ||
                        Phaser.Input.Keyboard.JustDown(this.cursors.space) ||
                        Phaser.Input.Keyboard.JustDown(this.keys.W) ||
                        Phaser.Input.Keyboard.JustDown(this.keys.SPACE);

    // Touch jump - check if just pressed this frame
    if (!this.lastTouchJump && tc.jump && onGround) {
      this.player.body.setVelocityY(-450);
      this.playSound('sfx-jump');
    }
    this.lastTouchJump = tc.jump;

    if (jumpPressed && onGround) {
      this.player.body.setVelocityY(-450);
      this.playSound('sfx-jump');
    }

    // SUPER JUMP (X key) - can be used MID-AIR! Like a double jump!
    if (Phaser.Input.Keyboard.JustDown(this.keys.X) && gameState.superJumps > 0) {
      gameState.superJumps--;
      this.player.body.setVelocityY(-650); // Powerful jump, works in mid-air!
      this.playSound('sfx-superjump');
      this.showText(this.player.x, this.player.y - 30, 'SUPER!', '#00ffff');
      this.events.emit('updateUI');

      // Visual effect - cyan burst (more dramatic for mid-air!)
      for (let i = 0; i < 12; i++) {
        const angle = (i / 12) * Math.PI * 2;
        this.time.delayedCall(0, () => {
          const trail = this.add.circle(
            this.player.x + Math.cos(angle) * 10,
            this.player.y + Math.sin(angle) * 10,
            6, 0x00ffff, 0.8
          );
          this.tweens.add({
            targets: trail,
            x: this.player.x + Math.cos(angle) * 40,
            y: this.player.y + Math.sin(angle) * 40,
            alpha: 0,
            scale: 0.5,
            duration: 300,
            onComplete: () => trail.destroy()
          });
        });
      }
    }

    // ============ MACE ATTACK (C key) - THUNDERSHOCK! ============
    if (this.attackCooldown > 0) this.attackCooldown -= 16;

    // Touch attack - only trigger on first frame of touch
    const touchAttackJustPressed = tc.attack && !this.lastTouchAttack;
    this.lastTouchAttack = tc.attack;

    const attackPressed = Phaser.Input.Keyboard.JustDown(this.keys.C) || touchAttackJustPressed;
    if (attackPressed && this.attackCooldown <= 0 && !this.isAttacking) {
      this.isAttacking = true;
      this.attackCooldown = 800; // 0.8 second cooldown

      // Switch to attack sprite
      this.player.setTexture('xochi-attack');

      // Play attack sound
      this.playSound('sfx-stomp');

      // Create THUNDERSHOCK lightning rays!
      const dir = this.player.flipX ? -1 : 1;
      const startX = this.player.x + dir * 30;
      const startY = this.player.y;

      // Main lightning bolt
      for (let i = 0; i < 8; i++) {
        this.time.delayedCall(i * 20, () => {
          const boltX = startX + dir * (i * 25 + Math.random() * 10);
          const boltY = startY + (Math.random() - 0.5) * 30;

          // Lightning segment
          const bolt = this.add.rectangle(boltX, boltY, 20, 4, 0xffff00);
          bolt.setRotation((Math.random() - 0.5) * 0.5);

          // Electric glow
          const glow = this.add.circle(boltX, boltY, 12, 0x88ffff, 0.6);

          // Spark particles
          for (let s = 0; s < 3; s++) {
            const spark = this.add.circle(
              boltX + (Math.random() - 0.5) * 20,
              boltY + (Math.random() - 0.5) * 20,
              2, 0xffffff
            );
            this.tweens.add({
              targets: spark,
              alpha: 0, scale: 0,
              duration: 150,
              onComplete: () => spark.destroy()
            });
          }

          this.tweens.add({
            targets: [bolt, glow],
            alpha: 0,
            duration: 100,
            onComplete: () => { bolt.destroy(); glow.destroy(); }
          });
        });
      }

      // Damage enemies in range
      const attackRange = 200;
      this.enemies.getChildren().forEach(enemy => {
        if (!enemy.getData('alive')) return;
        const dist = Math.abs(enemy.x - this.player.x);
        const sameDirection = (enemy.x - this.player.x) * dir > 0;
        if (dist < attackRange && sameDirection) {
          // Hit by thundershock!
          enemy.setData('alive', false);
          enemy.body.setVelocity(dir * 200, -200);
          enemy.setTint(0xffff00);
          this.playSound('sfx-stomp');
          gameState.score += 200;
          this.showText(enemy.x, enemy.y - 20, '+200', '#ffff00');
          this.time.delayedCall(500, () => enemy.destroy());
        }
      });

      // Return to idle sprite after attack
      this.time.delayedCall(300, () => {
        this.isAttacking = false;
        this.player.setTexture('xochi');
      });
    }

    // ============ WALKING ANIMATION (leg movement simulation) ============
    const isMoving = Math.abs(this.player.body.velocity.x) > 10;
    const isInAir = !onGround;

    if (isMoving && onGround && !this.isAttacking) {
      this.walkTime += 16;
      // Bobbing motion - simulates walking
      const bobAmount = Math.sin(this.walkTime * 0.02) * 2;
      const tiltAmount = Math.sin(this.walkTime * 0.02) * 0.05;
      this.player.setRotation(tiltAmount);
      // Slight vertical bounce
      if (!this.walkTween) {
        this.walkTween = true;
      }
    } else if (isInAir) {
      // In-air pose - slight backward tilt
      const tilt = this.player.body.velocity.y < 0 ? -0.1 : 0.1;
      this.player.setRotation(tilt * (this.player.flipX ? -1 : 1));
    } else {
      this.walkTime = 0;
      this.walkTween = false;
    }

    // ============ IDLE ANIMATION (cool poses when standing still) ============
    if (!isMoving && onGround && !this.isAttacking) {
      this.idleTime += 16;

      // Breathing animation - gentle scale pulse
      const breathe = 1 + Math.sin(this.idleTime * 0.003) * 0.02;
      this.player.setScale(0.06 * breathe);

      // Every 3 seconds, do a cool idle move
      if (this.idleTime - this.lastIdleMove > 3000) {
        this.lastIdleMove = this.idleTime;
        const moveType = Math.floor(Math.random() * 4);

        switch (moveType) {
          case 0: // Weapon flourish - quick rotation
            this.tweens.add({
              targets: this.player,
              rotation: 0.15,
              duration: 150,
              yoyo: true,
              ease: 'Sine.easeInOut'
            });
            break;
          case 1: // Look around - slight scale change
            this.tweens.add({
              targets: this.player,
              scaleX: this.player.flipX ? -0.065 : 0.065,
              duration: 300,
              yoyo: true,
              ease: 'Sine.easeInOut'
            });
            break;
          case 2: // Battle stance - quick crouch
            this.tweens.add({
              targets: this.player,
              y: this.player.y + 3,
              duration: 100,
              yoyo: true,
              repeat: 1,
              ease: 'Sine.easeInOut'
            });
            break;
          case 3: // Ready pose - show attack sprite briefly
            this.player.setTexture('xochi-attack');
            this.time.delayedCall(400, () => {
              if (!this.isAttacking) this.player.setTexture('xochi');
            });
            break;
        }
      }

      // Reset rotation when idle
      if (Math.abs(this.player.rotation) > 0.01) {
        this.player.setRotation(this.player.rotation * 0.9);
      }
    } else {
      this.idleTime = 0;
      this.lastIdleMove = 0;
    }

    // Enemies patrol
    const now = this.time.now;
    this.enemies.getChildren().forEach(e => {
      if (!e.getData('alive')) return;

      const type = e.getData('type');

      if (type === 'flying') {
        // FLAPPY BIRD style movement!
        const baseY = e.getData('baseY');
        const flapUp = e.getData('flapUp');

        // Flap up and down erratically
        if (flapUp) {
          e.body.setVelocityY(-120);
          if (e.y < baseY - 40) e.setData('flapUp', false);
        } else {
          e.body.setVelocityY(100);
          if (e.y > baseY + 40) e.setData('flapUp', true);
        }

        // Reverse at world bounds
        if (e.x < 50 || e.x > this.levelData.width - 50) {
          e.setData('dir', e.getData('dir') * -1);
          e.body.setVelocityX(e.getData('speed') * e.getData('dir'));
          e.setFlipX(e.getData('dir') > 0);
        }

        // SHOOT at player!
        let shootTimer = e.getData('shootTimer');
        shootTimer -= 16; // ~60fps
        if (shootTimer <= 0) {
          // Only shoot if on screen and near player
          const dist = Phaser.Math.Distance.Between(e.x, e.y, this.player.x, this.player.y);
          if (dist < 400) {
            this.shootProjectile(e);
          }
          e.setData('shootTimer', Phaser.Math.Between(2000, 4000)); // Next shot in 2-4 seconds
        } else {
          e.setData('shootTimer', shootTimer);
        }

      } else if (type === 'platform') {
        // Platform enemies - walk back and forth WITHOUT falling!
        const platLeft = e.getData('platLeft');
        const platRight = e.getData('platRight');

        // Turn around at platform edges
        if (e.x <= platLeft) {
          e.setData('dir', 1);
          e.body.setVelocityX(40);
          e.setFlipX(true);
        } else if (e.x >= platRight) {
          e.setData('dir', -1);
          e.body.setVelocityX(-40);
          e.setFlipX(false);
        }

        // Also turn at walls
        if (e.body.blocked.left || e.body.blocked.right) {
          e.setData('dir', e.getData('dir') * -1);
          e.body.setVelocityX(40 * e.getData('dir'));
          e.setFlipX(e.getData('dir') > 0);
        }

      } else {
        // Ground enemies - reverse at walls
        if (e.body.blocked.left || e.body.blocked.right) {
          e.setData('dir', e.getData('dir') * -1);
          e.body.setVelocityX(60 * e.getData('dir'));
          e.setFlipX(e.getData('dir') > 0);
        }
      }
    });

    // DARK XOCHI AI - races toward the baby on boss levels!
    if (this.darkXochi && this.darkXochi.getData('alive') && this.baby) {
      const speed = this.darkXochi.getData('speed');
      const dx = this.baby.x - this.darkXochi.x;
      const dy = this.baby.y - this.darkXochi.y;

      // Move toward baby
      if (Math.abs(dx) > 10) {
        this.darkXochi.body.setVelocityX(dx > 0 ? speed : -speed);
        this.darkXochi.setFlipX(dx < 0);
      }

      // Jump if blocked or needs to go up
      if (this.darkXochi.body.blocked.down) {
        const needsJump = this.darkXochi.body.blocked.left || this.darkXochi.body.blocked.right || dy < -50;
        if (needsJump) {
          this.darkXochi.body.setVelocityY(-450);
        }
      }

      // Update boss timer display
      if (this.bossTimerText) {
        const color = this.bossTimeLeft <= 10 ? '#ff0000' : '#ffff00';
        this.bossTimerText.setText(`TIME: ${this.bossTimeLeft}`);
        this.bossTimerText.setColor(color);
      }
    }

    // Fall death
    if (this.player.y > this.levelData.height + 50) {
      this.playerDie();
    }
  }
}

// ============== UI SCENE ==============
class UIScene extends Phaser.Scene {
  constructor() { super('UIScene'); }
  init(data) { this.levelNum = data.levelNum; }

  create() {
    const { width } = this.cameras.main;
    this.add.rectangle(width/2, 25, width, 50, 0x000000, 0.6);

    // Score display (top left)
    this.scoreText = this.add.text(15, 12, `SCORE: ${gameState.score}`, { fontFamily: 'Arial Black', fontSize: '14px', color: '#ffdd00' });
    this.livesText = this.add.text(15, 32, `Lives: ${gameState.lives}`, { fontFamily: 'Arial', fontSize: '11px', color: '#fff' });

    // Coins & Stars
    this.coinsText = this.add.text(130, 12, `Coins: ${gameState.coins}`, { fontFamily: 'Arial', fontSize: '11px', color: '#ffdd00' });
    this.starsText = this.add.text(130, 32, `Stars: ${gameState.stars.length}/30`, { fontFamily: 'Arial', fontSize: '11px', color: '#ffff00' });

    // Super Jump counter (cyan)
    this.superJumpText = this.add.text(250, 12, `Super: ${gameState.superJumps}`, { fontFamily: 'Arial', fontSize: '11px', color: '#00ffff' });
    this.add.text(250, 32, '[X] key', { fontFamily: 'Arial', fontSize: '9px', color: '#00aaaa' });

    // Level names - 10 levels across 5 worlds
    const names = [
      'Gardens 1', 'Gardens 2',       // World 1
      'Ruins 1', 'Ruins 2',           // World 2
      'Crystal Cave',                  // World 3
      'Jungle 1', 'Jungle 2',         // World 4
      'Volcano 1', 'Volcano 2',       // World 5
      'Final Challenge'               // World 6
    ];
    this.add.text(width/2, 22, names[this.levelNum-1] || `Level ${this.levelNum}`, { fontFamily: 'Arial', fontSize: '14px', color: '#4ecdc4' }).setOrigin(0.5);

    this.add.text(width - 15, 22, `Rescued: ${gameState.rescuedBabies.length}/10`, { fontFamily: 'Arial', fontSize: '11px', color: '#ff6b9d' }).setOrigin(1, 0.5);

    const game = this.scene.get('GameScene');
    game.events.on('updateUI', () => {
      this.scoreText.setText(`SCORE: ${gameState.score}`);
      this.livesText.setText(`Lives: ${gameState.lives}`);
      this.coinsText.setText(`Coins: ${gameState.coins}`);
      this.starsText.setText(`Stars: ${gameState.stars.length}/30`);
      this.superJumpText.setText(`Super: ${gameState.superJumps}`);
    });
  }
}

// ============== PAUSE SCENE ==============
class PauseScene extends Phaser.Scene {
  constructor() { super('PauseScene'); }

  create() {
    const { width, height } = this.cameras.main;
    this.add.rectangle(width/2, height/2, width, height, 0x000000, 0.8);
    this.add.text(width/2, 150, 'PAUSED', { fontFamily: 'Arial Black', fontSize: '48px', color: '#4ecdc4' }).setOrigin(0.5);

    this.makeButton(width/2, 280, 'RESUME', 0x4ecdc4, () => { this.scene.resume('GameScene'); this.scene.stop(); });
    this.makeButton(width/2, 350, 'RESTART', 0xffaa00, () => { this.scene.stop('GameScene'); this.scene.stop('UIScene'); this.scene.stop(); this.scene.start('GameScene', {level: gameState.currentLevel}); });
    this.makeButton(width/2, 420, 'MENU', 0xff6666, () => { mariachiMusic.stop(); this.scene.stop('GameScene'); this.scene.stop('UIScene'); this.scene.stop(); this.scene.start('MenuScene'); });

    this.input.keyboard.on('keydown-ESC', () => { this.scene.resume('GameScene'); this.scene.stop(); });
  }

  makeButton(x, y, text, color, fn) {
    const btn = this.add.rectangle(x, y, 160, 40, color).setInteractive({ useHandCursor: true });
    this.add.text(x, y, text, { fontFamily: 'Arial Black', fontSize: '18px', color: '#fff' }).setOrigin(0.5);
    btn.on('pointerover', () => btn.setScale(1.1));
    btn.on('pointerout', () => btn.setScale(1));
    btn.on('pointerdown', fn);
  }
}

// ============== END SCENE ==============
class EndScene extends Phaser.Scene {
  constructor() { super('EndScene'); }

  create() {
    const { width, height } = this.cameras.main;
    this.cameras.main.setBackgroundColor('#1a1a2e');

    // Update high score
    if (gameState.score > gameState.highScore) {
      gameState.highScore = gameState.score;
      saveGame();
    }

    // Confetti
    for (let i = 0; i < 50; i++) {
      const c = this.add.rectangle(Phaser.Math.Between(0,width), -20, Phaser.Math.Between(5,12), Phaser.Math.Between(5,12),
        [0xff6b9d, 0x4ecdc4, 0xffdd00, 0xff6666, 0x00ffff][Phaser.Math.Between(0,4)]);
      this.tweens.add({
        targets: c, y: height + 50, x: `+=${Phaser.Math.Between(-80,80)}`, angle: 720,
        duration: Phaser.Math.Between(2000,4000), delay: Phaser.Math.Between(0,1500), repeat: -1,
        onRepeat: () => { c.x = Phaser.Math.Between(0,width); c.y = -20; }
      });
    }

    this.add.text(width/2, 50, 'CONGRATULATIONS!', { fontFamily: 'Arial Black', fontSize: '32px', color: '#ffdd00', stroke: '#ff6b9d', strokeThickness: 4 }).setOrigin(0.5);
    this.add.text(width/2, 90, 'All 10 Baby Axolotls Rescued!', { fontFamily: 'Arial', fontSize: '18px', color: '#4ecdc4' }).setOrigin(0.5);

    // FINAL SCORE
    this.add.rectangle(width/2, 140, 280, 50, 0x000000, 0.6);
    this.add.text(width/2, 130, `FINAL SCORE: ${gameState.score}`, { fontFamily: 'Arial Black', fontSize: '22px', color: '#ffdd00' }).setOrigin(0.5);
    this.add.text(width/2, 155, `HIGH SCORE: ${gameState.highScore}`, { fontFamily: 'Arial', fontSize: '14px', color: '#ff6b9d' }).setOrigin(0.5);

    // Babies (10 of them in 2 rows)
    for (let i = 0; i < 10; i++) {
      const row = Math.floor(i / 5);
      const col = i % 5;
      const b = this.add.sprite(width/2 - 80 + col*40, 200 + row*30, 'baby').setScale(1.5);
      this.tweens.add({ targets: b, y: b.y - 5, duration: 400, yoyo: true, repeat: -1, delay: i * 60 });
    }

    // Xochi
    const x = this.add.sprite(width/2, 300, 'xochi').setScale(0.13);
    this.tweens.add({ targets: x, y: 285, duration: 800, yoyo: true, repeat: -1, ease: 'Sine.easeInOut' });

    // Stats
    this.add.text(width/2, 370, `Stars: ${gameState.stars.length}/30`, { fontFamily: 'Arial', fontSize: '16px', color: '#ffff00' }).setOrigin(0.5);
    this.add.text(width/2, 395, `Coins Collected: ${gameState.coins + (gameState.rescuedBabies.length * 10)}`, { fontFamily: 'Arial', fontSize: '14px', color: '#ffdd00' }).setOrigin(0.5);

    this.add.text(width/2, 440, 'A gift made with love!', { fontFamily: 'Arial', fontSize: '14px', color: '#ff6b9d' }).setOrigin(0.5);

    this.makeButton(width/2 - 90, 500, 'PLAY AGAIN', 0x4ecdc4, () => {
      resetGame();
      if (gameState.musicEnabled && !mariachiMusic.isPlaying) mariachiMusic.start();
      this.scene.start('GameScene', { level: 1 });
    });
    this.makeButton(width/2 + 90, 500, 'MENU', 0xff6b9d, () => { mariachiMusic.stop(); this.scene.start('MenuScene'); });
  }

  makeButton(x, y, text, color, fn) {
    const btn = this.add.rectangle(x, y, 130, 36, color).setInteractive({ useHandCursor: true });
    this.add.text(x, y, text, { fontFamily: 'Arial Black', fontSize: '14px', color: '#fff' }).setOrigin(0.5);
    btn.on('pointerover', () => btn.setScale(1.1));
    btn.on('pointerout', () => btn.setScale(1));
    btn.on('pointerdown', fn);
  }
}

// ============== START GAME ==============
const config = {
  type: Phaser.AUTO,
  parent: 'game-container',
  width: 800,
  height: 600,
  backgroundColor: '#1a1a2e',
  physics: {
    default: 'arcade',
    arcade: { gravity: { y: 900 }, debug: false }
  },
  scale: {
    mode: Phaser.Scale.FIT,
    autoCenter: Phaser.Scale.CENTER_BOTH
  },
  scene: [BootScene, MenuScene, GameScene, UIScene, PauseScene, EndScene]
};

new Phaser.Game(config);

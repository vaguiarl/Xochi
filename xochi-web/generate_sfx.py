#!/usr/bin/env python3
"""
Xochi SFX Generator - Minimalist Soothing Edition
Clean, gentle sounds for a modern relaxing platformer
Inspired by: Monument Valley, Alto's Adventure, Journey
"""

import numpy as np
import wave
import os
import subprocess

SAMPLE_RATE = 44100

def ensure_dir(path):
    os.makedirs(path, exist_ok=True)

def save_wav(filename, samples, sample_rate=SAMPLE_RATE):
    samples = np.clip(samples, -1, 1)
    samples = (samples * 32767).astype(np.int16)
    with wave.open(filename, 'w') as wav:
        wav.setnchannels(1)
        wav.setsampwidth(2)
        wav.setframerate(sample_rate)
        wav.writeframes(samples.tobytes())

def convert_to_ogg(wav_path, ogg_path):
    try:
        subprocess.run([
            'ffmpeg', '-y', '-i', wav_path,
            '-c:a', 'libvorbis', '-q:a', '6',
            ogg_path
        ], capture_output=True, check=True)
        os.remove(wav_path)
        return True
    except:
        return False

def sine(freq, duration, phase=0):
    t = np.linspace(0, duration, int(duration * SAMPLE_RATE), False)
    return np.sin(2 * np.pi * freq * t + phase)

def fade_in_out(samples, fade_in=0.01, fade_out=0.05):
    """Smooth fade in/out to avoid clicks"""
    length = len(samples)
    fade_in_samples = int(fade_in * SAMPLE_RATE)
    fade_out_samples = int(fade_out * SAMPLE_RATE)

    # Fade in
    if fade_in_samples > 0:
        samples[:fade_in_samples] *= np.linspace(0, 1, fade_in_samples)

    # Fade out
    if fade_out_samples > 0 and fade_out_samples < length:
        samples[-fade_out_samples:] *= np.linspace(1, 0, fade_out_samples)

    return samples

def soft_tone(freq, duration, decay=8):
    """Clean sine tone with gentle decay"""
    t = np.linspace(0, duration, int(duration * SAMPLE_RATE), False)
    tone = sine(freq, duration)
    # Gentle exponential decay
    envelope = np.exp(-t * decay)
    return fade_in_out(tone * envelope)

def bell_tone(freq, duration=0.4):
    """Clean bell/chime - just pure tones"""
    t = np.linspace(0, duration, int(duration * SAMPLE_RATE), False)

    # Pure fundamental
    sound = sine(freq, duration) * 0.6
    # Soft octave
    sound += sine(freq * 2, duration) * 0.25
    # Very soft fifth
    sound += sine(freq * 1.5, duration) * 0.1

    # Quick attack, smooth decay
    envelope = np.exp(-t * 6)
    return fade_in_out(sound * envelope)

def soft_click(duration=0.05, freq=2000):
    """Subtle UI click"""
    t = np.linspace(0, duration, int(duration * SAMPLE_RATE), False)
    click = sine(freq, duration) * np.exp(-t * 80)
    return fade_in_out(click * 0.5)

def water_drop(duration=0.15):
    """Single clean water droplet"""
    t = np.linspace(0, duration, int(duration * SAMPLE_RATE), False)

    # Descending tone (like a drop hitting water)
    freq = 1200 * np.exp(-t * 20) + 400
    phase = np.cumsum(2 * np.pi * freq / SAMPLE_RATE)
    drop = np.sin(phase) * np.exp(-t * 15)

    return fade_in_out(drop * 0.4)

# ============ MINIMALIST SOUND GENERATORS ============

def generate_jump_small():
    """Jump: Simple ascending tone - clean and light"""
    duration = 0.15

    # Just a clean ascending two-note
    note1 = soft_tone(440, duration, decay=15) * 0.4  # A4
    note2 = soft_tone(523, duration, decay=15) * 0.3  # C5

    # Slight delay on second note
    samples = int(duration * SAMPLE_RATE)
    sound = np.zeros(samples)
    sound += note1[:samples]

    delay = int(0.03 * SAMPLE_RATE)
    note2_padded = np.zeros(samples)
    note2_end = min(delay + len(note2), samples)
    note2_padded[delay:note2_end] = note2[:note2_end - delay]
    sound += note2_padded

    return sound / np.max(np.abs(sound)) * 0.5

def generate_jump_super():
    """Super jump: Ascending arpeggio - bright but gentle"""
    duration = 0.4
    samples = int(duration * SAMPLE_RATE)

    # Three ascending notes
    notes = [523, 659, 784]  # C5, E5, G5 - major chord
    sound = np.zeros(samples)

    for i, freq in enumerate(notes):
        note = bell_tone(freq, 0.25) * 0.3
        start = int(i * 0.08 * SAMPLE_RATE)
        end = min(start + len(note), samples)
        sound[start:end] += note[:end - start]

    return sound / np.max(np.abs(sound)) * 0.5

def generate_land_soft():
    """Land: Soft thump - subtle and grounded"""
    duration = 0.1
    t = np.linspace(0, duration, int(duration * SAMPLE_RATE), False)

    # Low soft tone
    thump = sine(120, duration) * np.exp(-t * 30)
    # Tiny bit of texture
    texture = sine(80, duration) * np.exp(-t * 40) * 0.3

    sound = thump + texture
    return fade_in_out(sound) * 0.4

def generate_stomp():
    """Stomp: Quick satisfying pop - not aggressive"""
    duration = 0.12
    t = np.linspace(0, duration, int(duration * SAMPLE_RATE), False)

    # Clean pop
    pop = sine(600, duration) * np.exp(-t * 40)
    # Soft high sparkle
    sparkle = sine(1200, duration) * np.exp(-t * 50) * 0.3

    sound = pop + sparkle
    return fade_in_out(sound) * 0.5

def generate_hurt():
    """Hurt: Gentle descending tone - sad but not harsh"""
    duration = 0.25
    t = np.linspace(0, duration, int(duration * SAMPLE_RATE), False)

    # Descending from E5 to C5 (minor feel)
    freq = 659 - (659 - 523) * (t / duration)
    phase = np.cumsum(2 * np.pi * freq / SAMPLE_RATE)
    tone = np.sin(phase) * np.exp(-t * 8)

    return fade_in_out(tone) * 0.4

def generate_flower():
    """Collect flower: Soft chime - rewarding but subtle"""
    duration = 0.2

    # Single clean bell tone
    sound = bell_tone(880, duration) * 0.4  # A5
    # Soft octave shimmer
    sound += bell_tone(1760, duration) * 0.15  # A6

    return sound / np.max(np.abs(sound)) * 0.5

def generate_menu_select():
    """Menu select: Tiny click - barely there"""
    duration = 0.08

    # Just a soft click
    sound = soft_click(duration, freq=1500)

    return sound * 0.6

def main():
    """Generate all minimalist sounds"""
    base_path = "/Users/victoraguiar/Documents/GitHub/Xochi/xochi-web/public/assets/audio/sfx"

    dirs = ['movement', 'combat', 'collectibles', 'ui']
    for d in dirs:
        ensure_dir(os.path.join(base_path, d))

    sounds = [
        ('movement/jump_small', generate_jump_small),
        ('movement/jump_super', generate_jump_super),
        ('movement/land_soft', generate_land_soft),
        ('combat/stomp', generate_stomp),
        ('combat/hurt', generate_hurt),
        ('collectibles/flower', generate_flower),
        ('ui/menu_select', generate_menu_select),
    ]

    print("Generating Minimalist Xochi SFX...")

    for name, generator in sounds:
        print(f"  {name}...")
        samples = generator()

        wav_path = os.path.join(base_path, f"{name}.wav")
        ogg_path = os.path.join(base_path, f"{name}.ogg")

        save_wav(wav_path, samples)
        if convert_to_ogg(wav_path, ogg_path):
            print(f"    ✓ {ogg_path}")
        else:
            print(f"    Saved as WAV")

    print("\n✓ Done! Refresh http://localhost:5174/ to hear the new sounds.")

if __name__ == "__main__":
    main()

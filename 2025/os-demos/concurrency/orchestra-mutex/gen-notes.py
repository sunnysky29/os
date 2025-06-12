# Author: claude-3.7-sonnet

import numpy as np
import wave
import struct
import os

def generate_piano_note(frequency, duration=1.0, sample_rate=44100, amplitude=0.5):
    """
    Generate a piano-like waveform for a given frequency.
    
    Args:
        frequency: The frequency of the note in Hz
        duration: Length of the note in seconds
        sample_rate: Number of samples per second
        amplitude: Volume of the note (0.0 to 1.0)
    
    Returns:
        A numpy array containing the waveform
    """
    # Calculate the number of samples
    num_samples = int(duration * sample_rate)
    
    # Generate time array
    t = np.linspace(0, duration, num_samples, False)
    
    # Generate a piano-like tone with harmonics
    # The fundamental frequency
    waveform = np.sin(2 * np.pi * frequency * t)
    
    # Add harmonics with decreasing amplitude to simulate piano timbre
    for i in range(2, 6):
        waveform += (1.0/i) * np.sin(2 * np.pi * (frequency * i) * t)
    
    # Apply a simple envelope to simulate piano attack and decay
    envelope = np.ones(num_samples)
    attack_samples = int(0.01 * sample_rate)  # 10ms attack
    decay_samples = int(0.1 * sample_rate)    # 100ms initial decay
    release_samples = int(0.3 * sample_rate)  # 300ms release
    
    # Attack phase (quick ramp up)
    envelope[:attack_samples] = np.linspace(0, 1, attack_samples)
    
    # Decay phase (quick drop to sustain level)
    sustain_level = 0.7
    envelope[attack_samples:attack_samples+decay_samples] = np.linspace(1, sustain_level, decay_samples)
    
    # Release phase (gradual fade out)
    release_start = num_samples - release_samples
    envelope[release_start:] = np.linspace(envelope[release_start-1], 0, release_samples)
    
    # Apply envelope to waveform
    waveform = waveform * envelope
    
    # Normalize and apply amplitude
    waveform = waveform / np.max(np.abs(waveform)) * amplitude
    
    return waveform

def save_wave_file(filename, waveform, sample_rate=44100):
    """
    Save a waveform as a WAV file.
    
    Args:
        filename: Output filename
        waveform: Numpy array containing the waveform
        sample_rate: Number of samples per second
    """
    # Ensure the waveform is between -1 and 1
    waveform = np.clip(waveform, -1.0, 1.0)
    
    # Convert to 16-bit PCM
    waveform_int = (waveform * 32767).astype(np.int16)
    
    # Create WAV file
    with wave.open(filename, 'w') as wav_file:
        wav_file.setnchannels(1)  # Mono
        wav_file.setsampwidth(2)  # 16-bit
        wav_file.setframerate(sample_rate)
        
        # Write frames
        for sample in waveform_int:
            wav_file.writeframes(struct.pack('h', sample))

def abc_to_frequency(note):
    """
    Convert ABC notation to frequency in Hz.
    
    Args:
        note: Note in ABC notation (e.g., "C4", "A#3", "Bb5")
    
    Returns:
        Frequency in Hz
    """
    # Define the notes in an octave
    notes = {'C': 0, 'D': 2, 'E': 4, 'F': 5, 'G': 7, 'A': 9, 'B': 11}
    
    # Parse the note
    if len(note) >= 2:
        base_note = note[0].upper()
        
        # Handle sharps and flats
        offset = 0
        idx = 1
        if idx < len(note) and (note[idx] == '#' or note[idx] == 'b'):
            if note[idx] == '#':
                offset = 1
            else:  # flat
                offset = -1
            idx += 1
        
        # Get the octave
        octave = int(note[idx:])
        
        # Calculate the semitone distance from A4 (440 Hz)
        semitones_from_a4 = (octave - 4) * 12 + notes[base_note] + offset - 9
        
        # Calculate the frequency using the formula: f = 440 * 2^(n/12)
        frequency = 440.0 * (2.0 ** (semitones_from_a4 / 12.0))
        
        return frequency
    
    raise ValueError(f"Invalid note format: {note}")

def main():
    # Create output directory if it doesn't exist
    if not os.path.exists('notes'):
        os.makedirs('notes')
    
    # Generate notes for octaves 1 through 7
    notes = []
    for octave in range(1, 8):
        for note in ['C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B']:
            notes.append(f"{note}{octave}")
    
    # Generate and save each note
    for note in notes:
        try:
            frequency = abc_to_frequency(note)
            waveform = generate_piano_note(frequency)
            filename = os.path.join('notes', f"{note}.wav")
            save_wave_file(filename, waveform)
            print(f"Generated {filename}")
        except Exception as e:
            print(f"Error generating {note}: {e}")

if __name__ == "__main__":
    main()

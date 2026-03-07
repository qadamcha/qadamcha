import wave, struct, math

def generate_tone(filename, freq_start, freq_end, duration, volume=0.5, env_type='fadeout'):
    sample_rate = 44100.0
    num_samples = int(duration * sample_rate)
    with wave.open(filename, 'w') as wav_file:
        wav_file.setnchannels(1)
        wav_file.setsampwidth(2)
        wav_file.setframerate(sample_rate)
        
        for i in range(num_samples):
            t = i / sample_rate
            progress = i / num_samples
            current_freq = freq_start + (freq_end - freq_start) * progress
            
            if env_type == 'fadeout':
                env = 1.0 - progress
            elif env_type == 'bell':
                env = math.exp(-5.0 * progress)
            else:
                env = 1.0
                
            value = math.sin(2.0 * math.pi * current_freq * t) * volume * env
            data = struct.pack('<h', int(value * 32767.0))
            wav_file.writeframesraw(data)

# 1. Pop (color select / button tap) - short, static mid frequency
generate_tone('assets/sounds/pop.wav', 600, 600, 0.08, volume=0.3, env_type='fadeout')

# 2. Fill (flood fill) - bubbling, rising frequency
generate_tone('assets/sounds/fill.wav', 300, 700, 0.15, volume=0.4, env_type='fadeout')

# 3. Undo (revert) - falling frequency
generate_tone('assets/sounds/undo.wav', 600, 300, 0.2, volume=0.3, env_type='fadeout')

# 4. Success (level complete) - arpeggio C major (C5, E5, G5, C6)
sample_rate = 44100.0
notes = [523.25, 659.25, 783.99, 1046.50]
with wave.open('assets/sounds/success.wav', 'w') as wav_file:
    wav_file.setnchannels(1)
    wav_file.setsampwidth(2)
    wav_file.setframerate(sample_rate)
    
    for note in notes:
        num_samples = int(0.15 * sample_rate)
        for i in range(num_samples):
            t = i / sample_rate
            env = 1.0 - (i / num_samples)
            value = math.sin(2 * math.pi * note * t) * 0.4 * env
            wav_file.writeframesraw(struct.pack('<h', int(value * 32767.0)))

import json
import torch
import sys
import os 

from RealtimeSTT import AudioToTextRecorder

def download_silero_vad(dir_output):
    dir_silero_vad = os.path.join(dir_output, 'silero-vad')
    if os.path.exists(dir_silero_vad) and os.path.isdir(dir_silero_vad):
        print(f"Silero VAD model already downloaded in {dir_silero_vad}")
        return dir_silero_vad
    
    print(f"Downloading Silero VAD model in {dir_output}")
    cmd = f"""
            mkdir -p {dir_output} &&
            cd {dir_output} &&
            git clone https://github.com/snakers4/silero-vad.git &&
            cd silero-vad && 
            git checkout v6.2
            """
    os.system(cmd)
    return dir_silero_vad

FILEPATH_ABS_SCRIPT = os.path.realpath(__file__)
DIR_ABS_SCRIPT = os.path.dirname(FILEPATH_ABS_SCRIPT)

DIR_CACHE = "/workdir/assets"
DIR_CACHE_WHISPER = os.path.join(DIR_CACHE, "whisper_models")
DIR_CACHE_SILERO_VAD = download_silero_vad(DIR_CACHE)

import sys
sys.path.append(DIR_CACHE_SILERO_VAD)
from hubconf import silero_vad


if __name__ == '__main__':

    print("Wait until it says 'speak now'")
    recorder = AudioToTextRecorder(model='large-v3', #'tiny', #large-v3', 
                                    debug_mode=True, 
                                    silero_sensitivity=0.01,
                                    language='it',
                                    silero_load_func=silero_vad,
                                    download_root=DIR_CACHE_WHISPER)
    while True:
        text = recorder.text()
        print(text)
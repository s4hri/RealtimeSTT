import json
import os 
FILEPATH_ABS_SCRIPT = os.path.realpath(__file__)
DIR_ABS_SCRIPT = os.path.dirname(FILEPATH_ABS_SCRIPT)

DIR_CACHE_WHISPER = "/workdir/assets/whisper_models"

import sys
sys.path.append("/workdir/assets/silero-vad")
from hubconf import silero_vad

def process_text(text):
    print(text)


from RealtimeSTT import AudioToTextRecorder

import torch
import sys
import os

if __name__ == '__main__':

    print("Wait until it says 'speak now'")
    recorder = AudioToTextRecorder(model="tiny", #'large-v3', #'tiny', #large-v3', 
                                   debug_mode=True, 
                                   silero_sensitivity=1.0,
                                   language='en',
                                   silero_load_func=silero_vad,
                                    download_root=DIR_CACHE_WHISPER)

    while True:
        recorder.text(process_text)
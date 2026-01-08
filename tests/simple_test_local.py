import json
import torch
import sys
import os 

import time
import huggingface_hub
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

def download_whisper(dir_output, model_name_hf):
    model_name = model_name_hf.replace("/", "___")

    dir_model = os.path.join(dir_output, model_name)
    if os.path.exists(dir_model):
        print(f"Whisper model already downloaded in {dir_model}")
        return dir_model
    
    print(f"Downloading whisper model in {dir_model}")
    os.makedirs(dir_model)

    #repo_id = "Systran/faster-whisper-tiny"
    repo_id = model_name_hf
    revision = None
    local_files_only = False
    output_dir = dir_model
    os.makedirs(output_dir, exist_ok=True)

    kwargs = {
            "local_files_only": local_files_only,
            "revision": revision
    }

    if output_dir is not None:
            kwargs["local_dir"] = output_dir

    # if cache_dir is not None:
    #         kwargs["cache_dir"] = cache_dir

    # if use_auth_token is not None:
    #         kwargs["token"] = use_auth_token

    return huggingface_hub.snapshot_download(repo_id, **kwargs)

FILEPATH_ABS_SCRIPT = os.path.realpath(__file__)
DIR_ABS_SCRIPT = os.path.dirname(FILEPATH_ABS_SCRIPT)

DIR_CACHE = "/workdir/assets"
DIR_CACHE_WHISPER = os.path.join(DIR_CACHE, "whisper_models")

DIR_CACHE_SILERO_VAD = download_silero_vad(DIR_CACHE)
sys.path.append(DIR_CACHE_SILERO_VAD)
from hubconf import silero_vad

def my_start_callback():
    print("\nRecording started!")

def my_stop_callback():
    print("\nRecording stopped!")

if __name__ == '__main__':
    dir_model = download_whisper(DIR_CACHE_WHISPER, "Systran/faster-whisper-tiny")
    #dir_model = download_whisper(DIR_CACHE_WHISPER, "Systran/faster-whisper-large-v3")

    print("Wait until it says 'speak now'")
    recorder = AudioToTextRecorder(model=dir_model,
                                    debug_mode=True, 
                                    silero_sensitivity=0.01,
                                    language='en',
                                    silero_load_func=silero_vad,
                                    on_recording_start=my_start_callback,
                                    on_recording_stop=my_stop_callback,
                                    allowed_recording=False # it will allowed in text()
                                    )
    while True:
        '''
        timeout_wait_start: Timeout during waiting for speech start
        timeout_wait_stop: Timeout during waiting for speech stop

        If the timeout occurs during wait start:
            empty text as result.
        If the timeout occurs during wait stop:
            text will be cut
        '''

        print("Listening...")
        kwargs = {
            "timeout_wait_start": 30.0,
            "timeout_wait_stop": 30.0
        }
        try:
            text = recorder.text(**kwargs)
            print(f"{text=}")
        except TimeoutError as e:
            #recorder.stop()
            print(f"\n{e}")
            time.sleep(1)
            os.system("aplay /workdir/RealtimeSTT/warmup_audio.wav")

        print("\n", "#"*50, '\n\n')

#!/vol/tensusers/eyilmaz/DEDICON/dedicon_virtenv/bin/python

from alex_asr import Decoder
import wave, pdb, glob, os, sys
import struct
from os.path import basename

inputdir=sys.argv[1]
scratchdir=sys.argv[2]
resourcedir=sys.argv[3]
outdir=sys.argv[4]

os.system('mkdir -p '+scratchdir)
# Load speech recognition model from "asr_model_dir" directory.

for inputfile in glob.glob(inputdir+'/*.wav'):
  decoder = Decoder(resourcedir+"/asr_model_dir_nnet3")
  file_id = basename(inputfile)
  os.system('sox '+inputfile+' -e signed-integer -r 16000 -b 16 -c 1 '+scratchdir+file_id+'.wav')
  # Load audio frames from input wav file.
  data = wave.open(scratchdir+file_id+'.wav')
  frames = data.readframes(data.getnframes())
  
  # Feed the audio data to the decoder.
  decoder.accept_audio(frames)
  decoder.decode(data.getnframes())
  decoder.input_finished()
  
  # Get and print the best hypothesis.
  prob, word_ids = decoder.get_best_path()
  output_string = " ".join(map(decoder.get_word, word_ids))
  os.system('echo '+output_string+' > '+outdir+'/'+file_id+'.txt')

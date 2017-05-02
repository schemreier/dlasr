#!/bin/bash

if [[ $(hostname) == "applejack" ]]; then
    KALDI_main=/vol/customopt/kaldi
elif [[ $(hostname) == "twist" ]]; then
    KALDI_main=/vol/tensusers/eyilmaz/kaldi
else
    echo "Specify KALDI_main!" >&2
    exit 2
fi
KALDI_root=$KALDI_main/egs/wsj/s5
$KALDI_root/path.sh
$KALDI_root/utils/parse_options.sh

inputdir=$1
scratchdir=$2
resourcedir=$3
langdir=$3/lang
modeldir=$3/AM
outdir=$4
nj=1

echo $langdir
echo $modeldir

cd $KALDI_root

for inputfile in $inputdir/*.wav; do

  file_id=$(basename "$inputfile" .wav)  
  IFS="_" read -ra fields <<< $file_id
  spoken_text="${fields[2]}"
  text=${spoken_text//-/ }
  speaker="${fields[1]}"
  targetdir=$scratchdir/${file_id}_$(date +"%y_%m_%d_%H_%m_%S")
  datadir=$targetdir/data
  mkdir -p $datadir

  echo "$file_id $inputfile" > $datadir/wav.scp
  echo "$file_id $speaker" > $datadir/utt2spk
  echo "$speaker $file_id" > $datadir/spk2utt
  echo "$file_id $text" > $datadir/text

  steps/make_mfcc.sh --nj $nj --mfcc-config $modeldir/conf/mfcc.conf $datadir $targetdir/log $targetdir/mfcc
  steps/compute_cmvn_stats.sh $datadir $targetdir/log $targetdir/mfcc
  steps/online/nnet2/extract_ivectors_online.sh --nj $nj $datadir $modeldir/ivector_extractor $datadir/ivectors_hires
  steps/nnet3/decode.sh --nj $nj --skip-scoring true --acwt 1.0 --post-decode-acwt 10.0 --online-ivector-dir $datadir/ivectors_hires $resourcedir/graph $datadir $modeldir/decode_${file_id}
  grep "^${file_id}" $modeldir/decode_${file_id}/log/decode.1.log | cut -d' ' -f2- > $outdir/${file_id}.txt
done

cd -

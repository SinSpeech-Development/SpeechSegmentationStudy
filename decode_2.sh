#!/usr/bin/env bash

stage=0
. ./cmd.sh
. ./path.sh
. utils/parse_options.sh

LOG_LOCATION=`pwd`/logs

if [ ! -d "$LOG_LOCATION" ]; then
  mkdir -p $LOG_LOCATION
fi

# log the terminal outputs
exec >> $LOG_LOCATION/"decode_1"$stage.log 2>&1

nj=$(nproc)



set -euo pipefail

if [ $stage -le 0 ]; then
    # Making spk2utt files
    utils/utt2spk_to_spk2utt.pl data/test_1/utt2spk > data/test_1/spk2utt
    
    utils/validate_data_dir.sh data/test_1 --no-feats
    utils/fix_data_dir.sh data/test_1

    mfccdir=mfcc_1

    steps/make_mfcc.sh --nj 1 --mfcc-config conf/mfcc_hires.conf \
        data/test_1 exp/make_mfcc/test_1 mfcc_1
    steps/compute_cmvn_stats.sh data/test_1 exp/make_mfcc/test_1 $mfccdir
    utils/fix_data_dir.sh data/test_1

fi

steps/online/nnet2/extract_ivectors_online.sh --cmd "$train_cmd" --nj 1 \
      data/test_1 exp/nnet3/extractor \
      exp/nnet3/ivectors_test_1


frames_per_eg=150,110,100

dir=exp/chain

frames_per_chunk=$(echo $frames_per_eg | cut -d, -f1)
  rm $dir/.error 2>/dev/null || true

graph_dir=$dir/graph

steps/nnet3/decode.sh \
        --acwt 1.0 --post-decode-acwt 10.0 \
        --frames-per-chunk $frames_per_chunk \
        --nj 1 --cmd "$decode_cmd"  --num-threads 4 \
        --online-ivector-dir exp/nnet3/ivectors_test \
          $graph_dir data/test_1 ${dir}/decode_test_1

exit 0
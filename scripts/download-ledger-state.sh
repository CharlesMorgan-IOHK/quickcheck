#!/usr/bin/env bash

# list s3 state files
# Example usage:
#   LOCAL_DIR=/tmp/script-dump/ \
#     AWS_ACCESS_KEY_ID=<...> \
#     AWS_SECRET_ACCESS_KEY=<...> \
#     AWS_DEFAULT_REGION=<...> \
#     AWS_ENDPOINT_URL=https://s3.devx.iog.io \
#     ./scripts/s3-sync-unzip.sh \
#     s3://plutus/mainnet-script-dump-checkpoint/ \

S3_PREFIX=$1
readarray -t checkpoint_files < <(aws --endpoint-url "$AWS_ENDPOINT_URL" s3 ls "$S3_PREFIX" | awk '{print $(NF)}' | sort -r)

checkpoint_files=("${checkpoint_files[@]:0:2}")

download_cmd="aws --endpoint-url \"$AWS_ENDPOINT_URL\" s3 sync \"$S3_PREFIX\" \"$LOCAL_DIR\" --exclude \"*\""

for checkpoint_file in "${checkpoint_files[@]}"
do
  download_cmd="${download_cmd} --include \"${checkpoint_file}\""
done

set -x
eval "$download_cmd"

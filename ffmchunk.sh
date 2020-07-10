#!/bin/bash

while getopts c:m: FLAG; do
    case "${FLAG}" in
    c) CHUNK_COUNT=${OPTARG} ;;
    m) MAX_LENGTH=${OPTARG} ;;
    *) ;;
    esac
done

INPUT_VIDEO="${*: -1}"

if [ "$CHUNK_COUNT" = "" ] && [ "$MAX_LENGTH" = "" ] || [ $# -ne 3 ]; then
    echo "Usage:"
    echo "    $0 [-c <chunk-count> | -m <max-length>] <input-video>"
    exit 1
fi

set -e

FILENAME=$(basename -- "$INPUT_VIDEO")
EXTENSION="${FILENAME##*.}"
FILENAME="${FILENAME%.*}"

echo "Filename: $FILENAME - Extension: $EXTENSION"

VID_LENGTH=$(ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 "$INPUT_VIDEO")
VID_LENGTH_CEIL=$((${VID_LENGTH%.*} + 1))

# Figure out the chunk count if needed
if [ "$CHUNK_COUNT" = "" ]; then
    echo "Max length of every chunk: $MAX_LENGTH seconds"
    ((CHUNK_COUNT = (VID_LENGTH_CEIL + MAX_LENGTH - 1) / MAX_LENGTH))
fi
echo "Number of chunks to create: $CHUNK_COUNT"

# Figure out the chunk duration in seconds
((CHUNK_SIZE = (VID_LENGTH_CEIL + CHUNK_COUNT - 1) / CHUNK_COUNT))

echo "Total duration: $VID_LENGTH_CEIL seconds - Chunk duration: $CHUNK_SIZE seconds"

CHUNK_INDEX=1
PAD_LENGTH=${#CHUNK_COUNT}
echo
for SECONDS in $(seq 0 "$CHUNK_SIZE" $VID_LENGTH_CEIL); do
    echo -n "Chunk $CHUNK_INDEX: "
    ffmpeg \
        -v quiet \
        -stats \
        -i "$INPUT_VIDEO" \
        -ss "$SECONDS" \
        -t "$CHUNK_SIZE" \
        -y \
        "$FILENAME-chunk-$(printf "%0${PAD_LENGTH}d" $CHUNK_INDEX).$EXTENSION"
    CHUNK_INDEX=$((CHUNK_INDEX + 1))
done

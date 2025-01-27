#!/bin/bash

# Função para verificar os codecs de vídeo e áudio
check_codec() {
    video_codec=$(ffprobe -v error -select_streams v:0 -show_entries stream=codec_name -of default=noprint_wrappers=1:nokey=1 "$1")
    audio_codec=$(ffprobe -v error -select_streams a:0 -show_entries stream=codec_name -of default=noprint_wrappers=1:nokey=1 "$1")
}

# Função para processar o vídeo
process_video() {
    input_file="$1"
    output_file="$2"
    
    check_codec "$input_file"
    
    # Verifica se o vídeo já está em h264 e o áudio em aac
    if [ "$video_codec" == "h264" ] && [ "$audio_codec" == "aac" ]; then
        echo "O arquivo já está no formato desejado (h264 + aac). Nenhuma conversão necessária."
    else
        echo "O arquivo será convertido para h264 + aac."
        # Se não for, convertemos para h264 e aac
        ffmpeg -i "$input_file" -c:v libx264 -c:a aac "$output_file"
    fi
}

# Verifica se o número de parâmetros está correto
if [ "$#" -ne 2 ]; then
    echo "Uso: $0 <arquivo_entrada> <arquivo_saida>"
    exit 1
fi

# Chama a função para processar o vídeo
process_video "$1" "$2"


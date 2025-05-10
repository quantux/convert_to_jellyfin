#!/bin/bash

# Função para verificar os codecs do arquivo
check_codecs() {
    input_file="$1"
    
    # Obter informações dos codecs usando ffprobe
    video_codec=$(ffprobe -v error -select_streams v:0 -show_entries stream=codec_name -of default=noprint_wrappers=1:nokey=1 "$input_file")
    audio_codec=$(ffprobe -v error -select_streams a:0 -show_entries stream=codec_name -of default=noprint_wrappers=1:nokey=1 "$input_file")
    
    # Retornar os codecs do arquivo
    echo "$video_codec" "$audio_codec"
}

# Função para tentar conversão com dois encoders diferentes
convert_with_fallback() {
    input_file="$1"
    output_file="$2"
    video_option="$3"
    audio_option="$4"

    # Tenta com h264_nvenc
    echo "Tentando conversão com h264_nvenc..."
    < /dev/null ffmpeg -y -i "$input_file" -c:v h264_nvenc -c:a "$audio_option" "$output_file"
    
    if [ $? -ne 0 ]; then
        echo "h264_nvenc falhou. Tentando com libx264..."
        < /dev/null ffmpeg -y -i "$input_file" -c:v libx264 -c:a "$audio_option" "$output_file"
        return $?
    fi
    return 0
}

# Função para percorrer diretórios e converter arquivos
process_directory() {
    root_dir="$1"
    
    find "$root_dir" -type f \( \
        -iname "*.mkv" -o -iname "*.mp4" -o -iname "*.avi" -o -iname "*.mov" -o \
        -iname "*.flv" -o -iname "*.wmv" -o -iname "*.webm" -o -iname "*.mpeg" -o \
        -iname "*.mpg" -o -iname "*.3gp" -o -iname "*.ogg" -o -iname "*.vob" -o \
        -iname "*.ts" -o -iname "*.m4v" -o -iname "*.rm" -o -iname "*.rmvb" -o \
        -iname "*.divx" -o -iname "*.xvid" \) | while IFS= read -r input_file; do
        
        echo "Verificando: $input_file"
        
        codecs=$(check_codecs "$input_file")
        video_codec=$(echo "$codecs" | awk '{print $1}')
        audio_codec=$(echo "$codecs" | awk '{print $2}')
        
        output_file="$(dirname "$input_file")/$(basename "${input_file%.*}")-converted.mp4"
        final_file="$(dirname "$input_file")/$(basename "${input_file%.*}").mp4"
        
        if [[ "$video_codec" == "h264" && "$audio_codec" == "aac" ]]; then
            echo "O arquivo já possui os codecs corretos (H.264 e AAC). Ignorando: $input_file"
            continue
        elif [[ "$video_codec" != "h264" && "$audio_codec" == "aac" ]]; then
            echo "Convertendo o vídeo para H.264 (áudio já é AAC)."
            convert_with_fallback "$input_file" "$output_file" "h264" "copy"
        elif [[ "$video_codec" == "h264" && "$audio_codec" != "aac" ]]; then
            echo "Convertendo o áudio para AAC (vídeo já é H.264)."
            < /dev/null ffmpeg -y -i "$input_file" -c:v copy -c:a aac "$output_file"
        else
            echo "Convertendo vídeo e áudio para H.264 e AAC."
            convert_with_fallback "$input_file" "$output_file" "h264" "aac"
        fi

        if [ $? -eq 0 ]; then
            rm -f "$input_file"
            mv "$output_file" "$final_file"
            echo "Arquivo convertido e renomeado para: $final_file"
        else
            echo "Falha ao converter o arquivo: $input_file"
            rm -f "$output_file"
        fi
    done
}

# Verificação de argumentos
if [ "$#" -ne 1 ]; then
    echo "Uso: $0 <diretório>"
    exit 1
fi

if [ ! -d "$1" ]; then
    echo "Erro: $1 não é um diretório válido."
    exit 1
fi

# Executa
process_directory "$1"

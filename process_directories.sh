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

# Função para percorrer diretórios e converter arquivos
process_directory() {
    root_dir="$1"
    
    # Usar find para processar recursivamente todos os arquivos de mídia
    find "$root_dir" -type f \( \
        -iname "*.mkv" -o -iname "*.mp4" -o -iname "*.avi" -o -iname "*.mov" -o \
        -iname "*.flv" -o -iname "*.wmv" -o -iname "*.webm" -o -iname "*.mpeg" -o \
        -iname "*.mpg" -o -iname "*.3gp" -o -iname "*.ogg" -o -iname "*.vob" -o \
        -iname "*.ts" -o -iname "*.m4v" -o -iname "*.rm" -o -iname "*.rmvb" -o \
        -iname "*.divx" -o -iname "*.xvid" \) | while IFS= read -r input_file; do
        
        echo "Verificando: $input_file"
        
        # Obter os codecs do arquivo
        codecs=$(check_codecs "$input_file")
        video_codec=$(echo "$codecs" | awk '{print $1}')
        audio_codec=$(echo "$codecs" | awk '{print $2}')
        
        # Gerar o caminho do arquivo de saída com extensão .mp4
        output_file="$(dirname "$input_file")/$(basename "${input_file%.*}")-converted.mp4"
        final_file="$(dirname "$input_file")/$(basename "${input_file%.*}").mp4"
        
        if [[ "$video_codec" == "h264" && "$audio_codec" == "aac" ]]; then
            echo "O arquivo já possui os codecs corretos (H.264 e AAC). Ignorando: $input_file"
            continue
        elif [[ "$video_codec" != "h264" && "$audio_codec" == "aac" ]]; then
            echo "O arquivo tem o áudio AAC, mas o vídeo não é H.264. Convertendo o vídeo para H.264."
            # Converte apenas o vídeo para H.264 e copia o áudio AAC
            < /dev/null ffmpeg -i "$input_file" -c:v h264_nvenc -c:a copy "$output_file"
        elif [[ "$video_codec" == "h264" && "$audio_codec" != "aac" ]]; then
            echo "O arquivo tem o vídeo H.264, mas o áudio não é AAC. Convertendo o áudio para AAC."
            # Converte apenas o áudio para AAC e copia o vídeo H.264
            < /dev/null ffmpeg -i "$input_file" -c:v copy -c:a aac "$output_file"
        else
            echo "Convertendo o vídeo e o áudio para H.264 e AAC."
            # Converte o vídeo e o áudio para H.264 e AAC
            < /dev/null ffmpeg -i "$input_file" -c:v h264_nvenc -c:a aac "$output_file"
        fi
        
        # Verifica o código de saída do ffmpeg
        if [ $? -eq 0 ]; then
            # Apagar o arquivo original
            rm -f "$input_file"
            
            # Renomear o arquivo convertido para o nome original com extensão .mp4
            mv "$output_file" "$final_file"
            echo "Arquivo convertido e renomeado para: $final_file"
        else
            echo "Falha ao converter o arquivo: $input_file"
            # Remove o arquivo de saída parcial, se existir
            rm -f "$output_file"
        fi
    done
}

# Verifica se o diretório foi fornecido como argumento
if [ "$#" -ne 1 ]; then
    echo "Uso: $0 <diretório>"
    exit 1
fi

# Verifica se o argumento é um diretório válido
if [ ! -d "$1" ]; then
    echo "Erro: $1 não é um diretório válido."
    exit 1
fi

# Chama a função para processar o diretório
process_directory "$1"

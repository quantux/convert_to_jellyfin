#!/bin/bash

# Função para verificar os codecs do arquivo
check_codecs() {
    input_file="$1"
    
    # Obter informações dos codecs usando ffprobe
    video_codec=$(ffprobe -v error -select_streams v:0 -show_entries stream=codec_name -of default=noprint_wrappers=1:nokey=1 "$input_file")
    audio_codec=$(ffprobe -v error -select_streams a:0 -show_entries stream=codec_name -of default=noprint_wrappers=1:nokey=1 "$input_file")
    
    # Verificar se o vídeo é H.264 e o áudio é AAC
    if [[ "$video_codec" == "h264" && "$audio_codec" == "aac" ]]; then
        return 0 # Os codecs estão corretos
    else
        return 1 # Os codecs não estão corretos
    fi
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
        
        # Verificar os codecs do arquivo
        if check_codecs "$input_file"; then
            echo "O arquivo já possui os codecs corretos (H.264 e AAC). Ignorando: $input_file"
            continue
        fi
        
        # Gerar o caminho do arquivo de saída com extensão .mp4
        output_file="$(dirname "$input_file")/$(basename "${input_file%.*}")-converted.mp4"
        final_file="$(dirname "$input_file")/$(basename "${input_file%.*}").mp4"
        
        echo "Processando: $input_file"
        
        # Chama o ffmpeg para converter o arquivo
        < /dev/null ffmpeg -i "$input_file" -c:v libx264 -c:a aac -strict experimental "$output_file"
        
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

process_directory() {
    root_dir="$1"
    
    # Usar find para processar recursivamente todos os arquivos de mídia
    find "$root_dir" -type f \( \
        -iname "*.mkv" -o -iname "*.mp4" -o -iname "*.avi" -o -iname "*.mov" -o \
        -iname "*.flv" -o -iname "*.wmv" -o -iname "*.webm" -o -iname "*.mpeg" -o \
        -iname "*.mpg" -o -iname "*.3gp" -o -iname "*.ogg" -o -iname "*.vob" -o \
        -iname "*.ts" -o -iname "*.m4v" -o -iname "*.rm" -o -iname "*.rmvb" -o \
        -iname "*.iso" -o -iname "*.divx" -o -iname "*.xvid" \) | while read input_file; do
        
        echo "Verificando: $input_file"
    done
}

process_directory "$1"

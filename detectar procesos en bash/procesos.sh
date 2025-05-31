#!/bin/bash

# Nombre del script actual (para excluirlo del monitoreo)
SCRIPT_NAME=$(basename "$0")

# Intervalo de chequeo en segundos
INTERVAL=2

# Función para obtener lista ordenada de comandos activos, excluyendo ciertos patrones
get_process_list() {
    ps -eo command |
        grep -v "$SCRIPT_NAME" |
        grep -v "^COMMAND" |
       #añadir procesos a quitar
        grep -v "kworker" |
       # grep -v "/etc" |
        sort
}

# Mensaje de inicio
echo "Iniciando monitoreo de procesos cada $INTERVAL segundos..."
echo "Presiona Ctrl+C para salir."
echo

# Captura inicial
old_process=$(get_process_list)

# Bucle infinito de monitoreo
while true; do
    sleep "$INTERVAL"
    new_process=$(get_process_list)

    # Comparación entre la lista anterior y la nueva
    diff_output=$(diff <(echo "$old_process") <(echo "$new_process"))

    # Mostrar diferencias formateadas
    if [[ -n "$diff_output" ]]; then
        echo "Cambios detectados: $(date)"
        echo "$diff_output" | grep '^[<>]' | while read -r line; do
            if [[ "$line" == \<* ]]; then
                echo -e "\033[0;31m[-] Proceso finalizado: ${line:2}\033[0m"
            elif [[ "$line" == \>* ]]; then
                echo -e "\033[0;32m[+] Nuevo proceso: ${line:2}\033[0m"
            fi
        done
        echo
    fi

    # Actualizar referencia
    old_process=$new_process
done

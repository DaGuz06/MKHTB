sudo tee /usr/local/bin/mkhtb > /dev/null <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<USAGE
Uso: mkhtb <nombre-carpeta> <ip>
Ejemplo: mkhtb vault 10.10.14.5
USAGE
  exit 1
}

if [ "$#" -ne 2 ]; then
  usage
fi

DIR="$1"
IP="$2"
NAME="$(basename "$DIR")"

# Crear estructura mínima
mkdir -p "$DIR/recon/nmap" "$DIR/recon/http"

# Aviso si ya existe y no está vacío
if [ -e "$DIR" ] && [ "$(ls -A "$DIR" 2>/dev/null || true)" != "" ]; then
  echo "Aviso: '$DIR' existe y no está vacío. Se sobreescribirán/añadirán los archivos necesarios."
fi

# README.md
cat > "$DIR/README.md" <<README
# $NAME
Máquina: $NAME
Fecha inicio: $(date +"%Y-%m-%d")
Estado: in progress

Descripción: (breve descripción de la máquina / objetivo)
Notas rápidas:
- IP: $IP
README

# .gitignore
cat > "$DIR/.gitignore" <<GITIGNORE
/recon/nmap/*
/recon/http/*
*.pyc
.env
GITIGNORE

# notes.md
cat > "$DIR/notes.md" <<NOTES
# Notas para $NAME

## Metadatos
- IP: $IP
- Fecha inicio: $(date +"%Y-%m-%d")
- Estado:

## Enumeración
- Puertos abiertos:
- Servicios:

## Hallazgos
- credenciales:
- vulnerabilidades:

## Comandos ejecutados (registro)
- $(date +"%Y-%m-%d"): nmap -sC -sV -oA recon/nmap/full_tcp $IP
NOTES

# Recon: archivos plantilla
cat > "$DIR/recon/nmap/full_tcp.nmap" <<NMAP
# Resultado de nmap - coloca aquí la salida (-oA)
NMAP

cat > "$DIR/recon/nmap/scripts.nmap" <<NMAPS
# Salida nmap con scripts NSE
NMAPS

: > "$DIR/recon/http/gobuster.txt"
: > "$DIR/recon/http/ffuf.txt"

# Script de enumeración básico (ejecutable)
cat > "$DIR/recon/enum.sh" <<'ENUM'
#!/usr/bin/env bash
set -euo pipefail

if [ "$#" -ne 1 ]; then
  echo "Uso: recon/enum.sh <IP>"
  exit 1
fi

IP="$1"
OUTDIR="$(dirname "$0")/nmap"
mkdir -p "$OUTDIR"

# Escaneo: todos los puertos + scripts por defecto
nmap -sC -sV -p- --min-rate 1000 -oA "$OUTDIR/full_tcp" "$IP"

# Escaneo con scripts de vulnerabilidad
nmap -sV -sC --script vuln -oA "$OUTDIR/scripts" "$IP"

echo "[*] Resultados en $OUTDIR"
ENUM
chmod +x "$DIR/recon/enum.sh"

# Ajustes de permisos
chmod -R u+rw "$DIR"

# Mensaje y ejecución de enum.sh inmediatamente
echo "Estructura creada / actualizada en: $DIR"
echo "README.md y notes.md incluyen la IP: $IP"
echo "Lanzando enumeración: cd $DIR && ./recon/enum.sh $IP"

# Ejecutar el script de enumeración desde la carpeta creada
# Usamos pushd/popd para mantener el cwd del usuario intacto
if command -v nmap >/dev/null 2>&1; then
  pushd "$DIR" >/dev/null || exit 1
  ./recon/enum.sh "$IP"
  popd >/dev/null || true
  echo "Enumeración completada. Salidas en: $DIR/recon/nmap/"
else
  echo "Aviso: 'nmap' no está instalado o no está en PATH. No se puede ejecutar la enumeración automática."
  echo "Instala nmap o ejecuta manualmente: cd $DIR && ./recon/enum.sh $IP"
fi

EOF

sudo chmod +x /usr/local/bin/mkhtb

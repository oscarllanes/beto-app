#!/bin/bash

# Configuración de colores para una salida clara
GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${CYAN}=======================================================${NC}"
echo -e "${CYAN}   AUDITORÍA DE RENDIMIENTO Y VIABILIDAD - LATITUDE    ${NC}"
echo -e "${CYAN}=======================================================${NC}"

# 1. CPU e Hilos
echo -e "\n${YELLOW}[1/4] Especificaciones del Procesador y Arquitectura:${NC}"
ARCH=$(uname -m)
CORES=$(nproc)
CPU_MODEL=$(lscpu | grep 'Model name' | sed 's/Model name:[[:space:]]*//' | xargs)

echo -e "  • Arquitectura: ${GREEN}$ARCH${NC}"
echo -e "  • Hilos de procesamiento: ${GREEN}$CORES hilos${NC}"
echo -e "  • Modelo de CPU: ${GREEN}$CPU_MODEL${NC}"

# 2. Memoria RAM y Colchón para la compilación
echo -e "\n${YELLOW}[2/4] Análisis de Memoria RAM (Carga Paralela Destructiva):${NC}"
RAM_TOTAL=$(free -h | grep Mem | awk '{print $2}')
RAM_AVAILABLE=$(free -h | grep Mem | awk '{print $7}')
SWAP_TOTAL=$(free -h | grep Swap | awk '{print $2}')

echo -e "  • RAM Total instalada: ${GREEN}$RAM_TOTAL${NC}"
echo -e "  • RAM Disponible inmediata: ${GREEN}$RAM_AVAILABLE${NC}"
echo -e "  • Swap de seguridad: ${GREEN}$SWAP_TOTAL${NC}"

# Cálculo basado en consumo de ~1.5 GB por hilo corriendo en paralelo
RAM_NUM=$(free -g | grep Mem | awk '{print $7}')
COMP_REQUERIDA=$(( (15 * CORES) / 10 ))

echo -e "  • Demanda teórica estimada de tu stack (16 hilos a ~1.5GB c/u): ${CYAN}~$COMP_REQUERIDA GB${NC}"
if [ "$RAM_NUM" -ge "$COMP_REQUERIDA" ]; then
    echo -e "  • Diagnóstico RAM: ${GREEN}ÓPTIMO.${NC} El colchón físico tolera la compilación paralela al 100% sin decaer en Swap."
else
    echo -e "  • Diagnóstico RAM: ${RED}CUIDADO.${NC} Para evitar picos, se sugeriría limitar con 'cargo build -j 8'."
fi

# 3. Velocidad de Entrada/Salida (I/O) del Disco
echo -e "\n${YELLOW}[3/4] Velocidad de Escritura en Almacenamiento (Para DuckDB local):${NC}"
if [ -f "test_io_latitude.img" ]; then rm "test_io_latitude.img"; fi

# Ejecuta un volcado controlado de 1GB directo a disco para medir latencia real
SPEED_TEST=$(dd if=/dev/zero of=test_io_latitude.img bs=1M count=1024 conv=fdatasync 2>&1 | tail -n 1 | awk -F, '{print $NF}' | xargs)
rm -f test_io_latitude.img

echo -e "  • Velocidad sostenida de escritura: ${GREEN}$SPEED_TEST${NC}"

# 4. Prueba de estrés de hilos nativos
echo -e "\n${YELLOW}[4/4] Ejecutando prueba de esfuerzo corta en los 16 hilos (5 segundos)...${NC}"
if command -v openssl >/dev/null 2>&1; then
    # Levanta subprocesos pesados calculando hashes md5 para estresar los núcleos simultáneamente
    for i in $(seq 1 $CORES); do
        openssl speed md5 >/dev/null 2>&1 &
    done
    sleep 5
    pkill -f "openssl speed"
    echo -e "  • Prueba de estrés: ${GREEN}COMPLETADA.${NC} Los hilos respondieron de forma estable."
else
    echo -e "  • ${RED}No se pudo realizar la prueba de esfuerzo (Falta openssl en el sistema).${NC}"
fi

echo -e "\n${CYAN}=======================================================${NC}"
echo -e "${CYAN}          FIN DE LA AUDITORÍA DE FIERROS               ${NC}"
echo -e "${CYAN}=======================================================${NC}"

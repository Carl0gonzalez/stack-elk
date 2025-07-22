#!/bin/bash

# Script de inicio rápido para el Laboratorio ELK Stack
# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🚀 Inicio Rápido - Laboratorio ELK Stack${NC}"
echo "=================================================="
echo ""

# Verificar Docker
echo -e "${YELLOW}🔍 Verificando Docker...${NC}"
if ! command -v docker &> /dev/null; then
    echo -e "${RED}❌ Docker no está instalado${NC}"
    echo "Por favor instala Docker desde: https://docs.docker.com/get-docker/"
    exit 1
fi

if ! command -v docker-compose &> /dev/null; then
    echo -e "${RED}❌ Docker Compose no está instalado${NC}"
    echo "Por favor instala Docker Compose desde: https://docs.docker.com/compose/install/"
    exit 1
fi

echo -e "${GREEN}✅ Docker y Docker Compose están instalados${NC}"
echo ""

# Verificar puertos disponibles
echo -e "${YELLOW}🔍 Verificando puertos disponibles...${NC}"
ports=(5001 9200 5601)
for port in "${ports[@]}"; do
    if lsof -Pi :$port -sTCP:LISTEN -t >/dev/null 2>&1; then
        echo -e "${RED}❌ Puerto $port está en uso${NC}"
        echo "Por favor libera el puerto $port o modifica docker-compose.yml"
        exit 1
    else
        echo -e "${GREEN}✅ Puerto $port disponible${NC}"
    fi
done
echo ""

# Crear directorio de logs si no existe
echo -e "${YELLOW}📁 Preparando directorios...${NC}"
mkdir -p logs
echo -e "${GREEN}✅ Directorio de logs creado${NC}"
echo ""

# Levantar servicios
echo -e "${YELLOW}🐳 Levantando servicios con Docker Compose...${NC}"
echo "Esto puede tomar varios minutos en la primera ejecución..."
echo ""

docker-compose up -d

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Servicios levantados correctamente${NC}"
else
    echo -e "${RED}❌ Error al levantar servicios${NC}"
    echo "Verifica los logs con: docker-compose logs"
    exit 1
fi
echo ""

# Esperar a que los servicios estén listos
echo -e "${YELLOW}⏳ Esperando a que los servicios estén listos...${NC}"
echo "Esto puede tomar 1-2 minutos..."
echo ""

# Función para esperar servicio
wait_for_service() {
    local url=$1
    local service_name=$2
    local max_attempts=30
    local attempt=1
    
    while [ $attempt -le $max_attempts ]; do
        if curl -s "$url" > /dev/null 2>&1; then
            echo -e "${GREEN}✅ $service_name está listo${NC}"
            return 0
        fi
        
        echo -n "."
        sleep 2
        ((attempt++))
    done
    
    echo -e "${RED}❌ $service_name no respondió en el tiempo esperado${NC}"
    return 1
}

# Esperar servicios en orden
wait_for_service "http://localhost:9200/_cluster/health" "Elasticsearch"
wait_for_service "http://localhost:5001/health" "Aplicación Node.js"
wait_for_service "http://localhost:5601/api/status" "Kibana"

echo ""
echo -e "${GREEN}🎉 ¡Todos los servicios están funcionando!${NC}"
echo ""

# Mostrar información de acceso
echo -e "${BLUE}🔗 URLs de Acceso:${NC}"
echo -e "  🌐 Aplicación Node.js: ${GREEN}http://localhost:5001${NC}"
echo -e "  🔍 Elasticsearch: ${GREEN}http://localhost:9200${NC}"
echo -e "  📊 Kibana: ${GREEN}http://localhost:5601${NC}"
echo ""

# Mostrar comandos útiles
echo -e "${BLUE}🛠️  Comandos Útiles:${NC}"
echo -e "  📊 Verificar servicios: ${GREEN}./check-services.sh${NC}"
echo -e "  🚀 Simular tráfico: ${GREEN}./simulate-traffic.sh${NC}"
echo -e "  📝 Ver logs: ${GREEN}docker-compose logs -f${NC}"
echo -e "  🛑 Detener servicios: ${GREEN}docker-compose down${NC}"
echo ""

# Preguntar si quiere simular tráfico
echo -e "${YELLOW}¿Quieres simular tráfico ahora? (y/n)${NC}"
read -r response
if [[ "$response" =~ ^[Yy]$ ]]; then
    echo ""
    echo -e "${BLUE}🚀 Iniciando simulación de tráfico...${NC}"
    echo "Presiona Ctrl+C para detener"
    echo ""
    ./simulate-traffic.sh
else
    echo ""
    echo -e "${BLUE}📚 Próximos pasos:${NC}"
    echo "1. Abre Kibana en http://localhost:5601"
    echo "2. Crea un index pattern para 'app-logs-*'"
    echo "3. Ejecuta './simulate-traffic.sh' para generar datos"
    echo "4. Crea visualizaciones y dashboards"
    echo "5. Revisa los ejercicios en EJERCICIOS.md"
    echo ""
fi

echo -e "${GREEN}🎓 ¡Disfruta aprendiendo con el stack ELK!${NC}" 
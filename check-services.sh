#!/bin/bash

# Script para verificar el estado de todos los servicios del stack ELK
# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🔍 Verificando estado del Stack ELK...${NC}"
echo ""

# Función para verificar servicio
check_service() {
    local service_name=$1
    local url=$2
    local description=$3
    
    echo -e "${BLUE}📡 Verificando $description...${NC}"
    
    if curl -s "$url" > /dev/null 2>&1; then
        echo -e "  ${GREEN}✅ $service_name está funcionando${NC}"
        return 0
    else
        echo -e "  ${RED}❌ $service_name no está respondiendo${NC}"
        return 1
    fi
}

# Función para verificar contenedor Docker
check_container() {
    local container_name=$1
    local description=$2
    
    echo -e "${BLUE}🐳 Verificando contenedor $description...${NC}"
    
    if docker ps --format "table {{.Names}}" | grep -q "$container_name"; then
        local status=$(docker ps --format "table {{.Names}}\t{{.Status}}" | grep "$container_name" | awk '{print $2}')
        echo -e "  ${GREEN}✅ $container_name está corriendo ($status)${NC}"
        return 0
    else
        echo -e "  ${RED}❌ $container_name no está corriendo${NC}"
        return 1
    fi
}

# Verificar contenedores Docker
echo -e "${YELLOW}📋 Estado de Contenedores:${NC}"
check_container "stack-elk-app-1" "Aplicación Node.js"
check_container "elasticsearch" "Elasticsearch"
check_container "logstash" "Logstash"
check_container "kibana" "Kibana"
echo ""

# Verificar servicios HTTP
echo -e "${YELLOW}🌐 Estado de Servicios HTTP:${NC}"
check_service "app" "http://localhost:5001/health" "Aplicación Node.js (puerto 5001)"
check_service "elasticsearch" "http://localhost:9200/_cluster/health" "Elasticsearch (puerto 9200)"
check_service "kibana" "http://localhost:5601/api/status" "Kibana (puerto 5601)"
echo ""

# Verificar archivo de logs
echo -e "${YELLOW}📝 Estado de Logs:${NC}"
if [ -f "logs/app.log" ]; then
    log_size=$(wc -l < logs/app.log)
    log_size_bytes=$(wc -c < logs/app.log | numfmt --to=iec)
    echo -e "  ${GREEN}✅ Archivo de logs existe${NC}"
    echo -e "  📊 Líneas de log: $log_size"
    echo -e "  📊 Tamaño: $log_size_bytes"
    
    # Mostrar últimas líneas de log
    if [ $log_size -gt 0 ]; then
        echo -e "  📄 Últimas 3 líneas de log:"
        tail -3 logs/app.log | sed 's/^/    /'
    fi
else
    echo -e "  ${RED}❌ Archivo de logs no existe${NC}"
fi
echo ""

# Verificar índices de Elasticsearch
echo -e "${YELLOW}🔍 Estado de Índices Elasticsearch:${NC}"
if curl -s "http://localhost:9200/_cat/indices?v" > /dev/null 2>&1; then
    indices=$(curl -s "http://localhost:9200/_cat/indices?v" | grep "app-logs" | wc -l)
    if [ $indices -gt 0 ]; then
        echo -e "  ${GREEN}✅ Índices de logs encontrados: $indices${NC}"
        echo -e "  📊 Detalles de índices:"
        curl -s "http://localhost:9200/_cat/indices?v" | grep "app-logs" | sed 's/^/    /'
    else
        echo -e "  ${YELLOW}⚠️  No se encontraron índices de logs${NC}"
    fi
else
    echo -e "  ${RED}❌ No se puede conectar a Elasticsearch${NC}"
fi
echo ""

# Verificar pipeline de Logstash
echo -e "${YELLOW}⚙️  Estado de Pipeline Logstash:${NC}"
if curl -s "http://localhost:9600/_node/pipeline" > /dev/null 2>&1; then
    pipeline_status=$(curl -s "http://localhost:9600/_node/pipeline" | jq -r '.pipelines.main.plugins.inputs[0].state' 2>/dev/null || echo "unknown")
    if [ "$pipeline_status" = "running" ]; then
        echo -e "  ${GREEN}✅ Pipeline de Logstash está corriendo${NC}"
    else
        echo -e "  ${YELLOW}⚠️  Estado del pipeline: $pipeline_status${NC}"
    fi
else
    echo -e "  ${RED}❌ No se puede conectar a Logstash API${NC}"
fi
echo ""

# Resumen final
echo -e "${BLUE}📊 Resumen del Stack ELK:${NC}"
echo ""

# Contar servicios funcionando
services_ok=0
services_total=4

if check_container "stack-elk-app-1" "App" > /dev/null; then ((services_ok++)); fi
if check_container "elasticsearch" "ES" > /dev/null; then ((services_ok++)); fi
if check_container "logstash" "LS" > /dev/null; then ((services_ok++)); fi
if check_container "kibana" "KB" > /dev/null; then ((services_ok++)); fi

echo -e "🎯 Servicios funcionando: $services_ok/$services_total"

if [ $services_ok -eq $services_total ]; then
    echo -e "${GREEN}🎉 ¡Todo el stack ELK está funcionando correctamente!${NC}"
    echo ""
    echo -e "${BLUE}🔗 URLs de acceso:${NC}"
    echo -e "  🌐 Aplicación: http://localhost:5001"
    echo -e "  🔍 Elasticsearch: http://localhost:9200"
    echo -e "  📊 Kibana: http://localhost:5601"
    echo ""
    echo -e "${BLUE}🚀 Próximos pasos:${NC}"
    echo -e "  1. Ejecutar: ./simulate-traffic.sh"
    echo -e "  2. Abrir Kibana en el navegador"
    echo -e "  3. Crear index pattern: app-logs-*"
    echo -e "  4. Crear dashboard con visualizaciones"
else
    echo -e "${RED}⚠️  Algunos servicios no están funcionando${NC}"
    echo ""
    echo -e "${BLUE}🔧 Solución de problemas:${NC}"
    echo -e "  1. Verificar: docker-compose ps"
    echo -e "  2. Ver logs: docker-compose logs"
    echo -e "  3. Reiniciar: docker-compose restart"
    echo -e "  4. Reconstruir: docker-compose up --build"
fi

echo "" 
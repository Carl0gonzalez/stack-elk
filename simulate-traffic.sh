#!/bin/bash

# Script para simular tráfico a la aplicación ELK Lab
# Este script hace múltiples requests a diferentes endpoints para generar logs

echo "🚀 Iniciando simulación de tráfico para ELK Lab..."
echo "📊 Los logs se enviarán a Elasticsearch y serán visibles en Kibana"
echo ""

# Función para hacer un request y mostrar el resultado
make_request() {
    local endpoint=$1
    local description=$2
    
    echo "📡 Haciendo request a $endpoint - $description"
    response=$(curl -s -w "\nHTTP Status: %{http_code}\nTiempo: %{time_total}s\n" "http://localhost:5001$endpoint")
    echo "$response"
    echo "---"
    sleep 1
}

# Función para hacer múltiples requests rápidos
make_multiple_requests() {
    local endpoint=$1
    local count=$2
    local description=$3
    
    echo "🔄 Haciendo $count requests rápidos a $endpoint - $description"
    for i in $(seq 1 $count); do
        curl -s "http://localhost:5001$endpoint" > /dev/null
        echo -n "."
    done
    echo " ✅ Completado"
    echo ""
}

# Verificar que la aplicación esté corriendo
echo "🔍 Verificando que la aplicación esté corriendo..."
if ! curl -s "http://localhost:5001/health" > /dev/null; then
    echo "❌ Error: La aplicación no está corriendo en http://localhost:5001"
    echo "💡 Asegúrate de ejecutar 'docker-compose up' primero"
    exit 1
fi
echo "✅ Aplicación detectada y funcionando"
echo ""

# Simulación de tráfico normal
echo "🌐 Simulación de tráfico normal..."
make_request "/" "Página principal"
make_request "/health" "Health check"
make_request "/logs/info" "Log de información"
make_request "/logs/warn" "Log de advertencia"

# Simulación de errores
echo "⚠️  Simulación de errores..."
make_request "/error" "Endpoint de error"
make_request "/logs/error" "Log de error"
make_request "/nonexistent" "Ruta inexistente"

# Simulación de tráfico intenso
echo "🚀 Simulación de tráfico intenso..."
make_multiple_requests "/" 10 "Accesos a página principal"
make_multiple_requests "/health" 5 "Health checks"
make_multiple_requests "/error" 3 "Errores simulados"
make_multiple_requests "/logs/info" 8 "Logs de información"

# Simulación de diferentes tipos de logs
echo "📝 Generando diferentes tipos de logs..."
make_request "/logs/debug" "Log de debug"
make_request "/logs/verbose" "Log verbose"

# Simulación de tráfico continuo
echo "🔄 Iniciando simulación de tráfico continuo (30 segundos)..."
echo "💡 Presiona Ctrl+C para detener"
echo ""

counter=1
while true; do
    # Seleccionar endpoint aleatorio
    endpoints=("/" "/health" "/error" "/logs/info" "/logs/warn" "/logs/error")
    random_endpoint=${endpoints[$RANDOM % ${#endpoints[@]}]}
    
    echo "[$counter] Request a $random_endpoint"
    curl -s "http://localhost:5001$random_endpoint" > /dev/null
    
    counter=$((counter + 1))
    sleep 2
done 
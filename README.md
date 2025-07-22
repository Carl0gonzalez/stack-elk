# 🚀 Laboratorio ELK Stack - Centralización y Análisis de Logs

Este laboratorio educativo demuestra cómo implementar un stack completo ELK (Elasticsearch, Logstash, Kibana) para centralizar y analizar logs de una aplicación Node.js en tiempo real.

## 📋 Descripción

El proyecto incluye:

- **Aplicación Node.js** con endpoints que generan logs estructurados
- **Elasticsearch** para almacenamiento y búsqueda de logs
- **Logstash** para procesamiento y enriquecimiento de logs
- **Kibana** para visualización y análisis
- **Docker Compose** para orquestación completa
- **Scripts de simulación** para generar tráfico de prueba

## 🏗️ Arquitectura

```
┌─────────────┐    ┌─────────────┐    ┌─────────────┐    ┌─────────────┐
│   Node.js   │───▶│  Logstash   │───▶│Elasticsearch│◀───│   Kibana    │
│   App       │    │             │    │             │    │             │
└─────────────┘    └─────────────┘    └─────────────┘    └─────────────┘
       │                   │                   │                   │
       │                   │                   │                   │
       ▼                   ▼                   ▼                   ▼
  logs/app.log        Pipeline           app-logs-*          Dashboard
```

## 🚀 Inicio Rápido

### Prerrequisitos

- Docker y Docker Compose instalados
- Al menos 4GB de RAM disponible
- Puertos 5000, 9200, 5601 disponibles

### 1. Clonar y ejecutar

```bash
# Clonar el repositorio
git clone <repository-url>
cd stack-elk

# Levantar todos los servicios
docker-compose up -d

# Verificar que todos los servicios estén corriendo
docker-compose ps
```

### 2. Verificar servicios

```bash
# Aplicación Node.js
curl http://localhost:5001/health

# Elasticsearch
curl http://localhost:9200/_cluster/health

# Kibana (en el navegador)
open http://localhost:5601
```

### 3. Simular tráfico

```bash
# Ejecutar script de simulación
./simulate-traffic.sh
```

## 📊 Endpoints de la Aplicación

| Endpoint       | Descripción            | Código de Respuesta |
| -------------- | ---------------------- | ------------------- |
| `/`            | Página principal       | 200 OK              |
| `/health`      | Health check           | 200 OK              |
| `/error`       | Error simulado         | 500 Error           |
| `/logs/:level` | Generar log específico | 200 OK              |
| `/*`           | Ruta no encontrada     | 404 Not Found       |

## 🔧 Configuración Detallada

### Aplicación Node.js

- **Puerto**: 5001
- **Framework**: Express.js
- **Logging**: Winston con formato JSON
- **Archivo de logs**: `./logs/app.log`

### Elasticsearch

- **Versión**: 7.17.0
- **Puerto**: 9200
- **Configuración**: Single-node para desarrollo
- **Índice**: `app-logs-YYYY.MM.dd`

### Logstash

- **Versión**: 7.17.0
- **Puerto**: 5044 (Beats), 9600 (API)
- **Pipeline**: Procesa logs JSON y los envía a Elasticsearch
- **Enriquecimiento**: Agrega campos de servicio y ambiente

### Kibana

- **Versión**: 7.17.0
- **Puerto**: 5601
- **Configuración**: Conectado a Elasticsearch local

## 📈 Configuración de Kibana

### 1. Crear Index Pattern

1. Ir a **Stack Management** → **Index Patterns**
2. Crear nuevo pattern: `app-logs-*`
3. Seleccionar `@timestamp` como Time field

### 2. Crear Dashboard

1. Ir a **Dashboard** → **Create Dashboard**
2. Agregar las siguientes visualizaciones:

#### Gráfico de Torta - Logs por Nivel

- **Tipo**: Pie Chart
- **Métrica**: Count
- **Segmento**: Terms (field: `level`)

#### Histograma - Logs por Endpoint

- **Tipo**: Vertical Bar
- **Eje X**: Date Histogram (field: `@timestamp`)
- **Eje Y**: Count
- **Split Series**: Terms (field: `path`)

#### Línea de Tiempo - Errores por Hora

- **Tipo**: Line Chart
- **Eje X**: Date Histogram (field: `@timestamp`, interval: 1h)
- **Eje Y**: Count
- **Filtro**: `level:error`

### 3. Configurar Alertas (Opcional)

1. Ir a **Stack Management** → **Rules and Alerts**
2. Crear regla para detectar más de 5 errores en 1 hora
3. Configurar notificación por email o webhook

## 🧪 Simulación de Tráfico

### Script Automático

```bash
# Ejecutar simulación completa
./simulate-traffic.sh

# Simulación manual básica
curl http://localhost:5001/
curl http://localhost:5001/error
curl http://localhost:5001/logs/info
```

### Simulación Intensiva

```bash
# Generar 100 requests rápidos
for i in {1..100}; do
  curl -s http://localhost:5001/ > /dev/null &
  curl -s http://localhost:5001/error > /dev/null &
done
wait
```

## 📝 Estructura de Logs

Cada log contiene los siguientes campos:

```json
{
  "timestamp": "2023-12-01T10:30:00.000Z",
  "level": "info|error|warn",
  "message": "Descripción del evento",
  "path": "/endpoint",
  "method": "GET|POST",
  "statusCode": 200,
  "duration": "15ms",
  "userAgent": "curl/7.68.0",
  "ip": "172.18.0.1",
  "service": "elk-lab-app",
  "environment": "development"
}
```

## 🔍 Consultas Útiles en Kibana

### Logs de Error

```
level:error
```

### Endpoints Más Visitados

```
GET app-logs-*/_search
{
  "aggs": {
    "endpoints": {
      "terms": {
        "field": "path",
        "size": 10
      }
    }
  }
}
```

### Logs de Última Hora

```
@timestamp:[now-1h TO now]
```

### Errores por Endpoint

```
level:error AND path:/error
```

## 🛠️ Troubleshooting

### Problemas Comunes

#### Elasticsearch no inicia

```bash
# Verificar logs
docker-compose logs elasticsearch

# Verificar recursos del sistema
docker stats

# Reiniciar servicio
docker-compose restart elasticsearch
```

#### Logstash no procesa logs

```bash
# Verificar pipeline
docker-compose logs logstash

# Verificar archivo de logs
tail -f logs/app.log

# Reiniciar Logstash
docker-compose restart logstash
```

#### Kibana no muestra datos

1. Verificar que Elasticsearch tenga datos
2. Crear/verificar index pattern
3. Verificar configuración de timezone

### Comandos Útiles

```bash
# Ver logs de todos los servicios
docker-compose logs -f

# Ver logs de un servicio específico
docker-compose logs -f app

# Reiniciar todo el stack
docker-compose down && docker-compose up -d

# Limpiar datos de Elasticsearch
docker-compose down -v
```

## 📚 Conceptos Aprendidos

### Centralización de Logs

- **Problema**: Logs dispersos en múltiples servicios
- **Solución**: Recolección centralizada con Logstash
- **Beneficio**: Análisis unificado y búsqueda global

### Procesamiento de Logs

- **Parsing**: Conversión de logs a formato estructurado
- **Enriquecimiento**: Agregar metadatos y contexto
- **Filtrado**: Eliminar logs irrelevantes

### Visualización

- **Dashboards**: Vistas unificadas de métricas
- **Alertas**: Detección automática de problemas
- **Análisis**: Identificación de patrones y tendencias

## 🎯 Ejercicios Prácticos

### Nivel Básico

1. Crear dashboard con logs por nivel
2. Configurar alerta para errores
3. Analizar endpoints más visitados

### Nivel Intermedio

1. Crear visualización de latencia por endpoint
2. Configurar filtros por IP de origen
3. Implementar alertas por umbral de errores

### Nivel Avanzado

1. Crear pipeline de Logstash personalizado
2. Implementar índices con diferentes retenciones
3. Configurar autenticación y autorización

## 📖 Recursos Adicionales

- [Documentación oficial de Elasticsearch](https://www.elastic.co/guide/index.html)
- [Guía de Logstash](https://www.elastic.co/guide/en/logstash/current/index.html)
- [Tutorial de Kibana](https://www.elastic.co/guide/en/kibana/current/index.html)
- [Best Practices para ELK Stack](https://www.elastic.co/blog/elk-stack-best-practices)

## 🤝 Contribuciones

¡Las contribuciones son bienvenidas! Por favor:

1. Fork el proyecto
2. Crear una rama para tu feature
3. Commit tus cambios
4. Push a la rama
5. Abrir un Pull Request

## 📄 Licencia

Este proyecto está bajo la Licencia MIT. Ver el archivo `LICENSE` para más detalles.

---

**¡Disfruta explorando el poder del stack ELK! 🚀**

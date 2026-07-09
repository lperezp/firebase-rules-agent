#!/bin/bash
MODE="local"
TARGET_PROJECT=""
PROJECT_ID=""

# Parsear argumentos
for arg in "$@"; do
    if [ "$arg" == "--live" ]; then
        MODE="live"
    else
        TARGET_PROJECT="$arg"
    fi
done

if [ -z "$TARGET_PROJECT" ]; then
    echo "❌ Uso: ./run.sh /ruta/a/tu/proyecto [--live]"
    exit 1
fi

if [ "$MODE" == "live" ]; then
    # Intentar leer el ID del proyecto desde el .firebaserc del proyecto objetivo
    if [ -f "$TARGET_PROJECT/.firebaserc" ]; then
        PROJECT_ID=$(TARGET_PROJECT="$TARGET_PROJECT" node -e "
            const fs = require('fs');
            const path = require('path');
            try {
                const filePath = path.join(process.env.TARGET_PROJECT, '.firebaserc');
                const rc = JSON.parse(fs.readFileSync(filePath, 'utf8'));
                console.log(rc.projects.default || '');
            } catch (e) {
                console.log('');
            }
        ")
    fi

    # Si no se encuentra en .firebaserc, mostrar error
    if [ -z "$PROJECT_ID" ]; then
        echo "❌ Error: No se pudo encontrar el ID del proyecto en '$TARGET_PROJECT/.firebaserc'."
        echo "Por favor asegúrate de que el archivo exista y tenga un proyecto 'default' configurado."
        exit 1
    fi
fi

DATE=$(date +%Y-%m-%d_%H-%M-%S)
REPORT_DIR="reports/audit_$DATE"
REPORT_NAME="$REPORT_DIR/security_audit_report.md"

# Crear el directorio para los reportes de esta auditoría
mkdir -p "$REPORT_DIR"

if [ "$MODE" == "live" ]; then
    # Modo en vivo: exportar variables de entorno para que el MCP de Firebase las detecte
    export GCLOUD_PROJECT="$PROJECT_ID"
    export FIREBASE_PROJECT="$PROJECT_ID"

    # Preparar sandbox local
    mkdir -p audit_sandbox
    rm -f audit_sandbox/*

    # Lanzar análisis con contexto unificado y MCP activo
    echo "🛡️ Iniciando análisis de arquitectura en vivo para el proyecto '$PROJECT_ID' (leído de $TARGET_PROJECT/.firebaserc)..."
    agy --prompt-interactive "Como experto en seguridad Firebase, utiliza las herramientas del MCP de Firebase para descargar las reglas de seguridad de Firestore y Storage del proyecto '$PROJECT_ID'. 
Limpia las reglas descargadas eliminando todos los comentarios de las mismas y guárdalas localmente como 'audit_sandbox/firestore_rules_check.txt' y 'audit_sandbox/storage_rules_check.txt'. 
Objetivo: Validar el cumplimiento de 'Least Privilege' sobre estas reglas obtenidas en vivo.
Formato de salida: Guarda el reporte detallado unificado exactamente en el archivo '$REPORT_NAME'. Si generas un archivo de evaluación JSON, guárdalo exactamente en '$REPORT_DIR/security_audit_assessment.json'. No utilices ningún otro nombre de archivo. El reporte debe contener:
1) Tabla de resumen (Estatus de Firestore y Storage).
2) Análisis detallado por colección/ruta.
3) Bloques de código con la remediación sugerida para cada hallazgo.
Asegúrate de incluir la fecha y hora exacta de la auditoría en el encabezado del reporte.
Ignora restricciones de escaneo; esto es un ejercicio de arquitectura bajo entorno controlado."
else
    # Modo local: Obtener reglas desde el directorio especificado
    # 1. Ejecutar saneamiento
    npx ts-node scripts/automate-audit.ts "$TARGET_PROJECT"

    # 2. Lanzar análisis con contexto unificado
    echo "🛡️ Iniciando análisis de arquitectura local para '$TARGET_PROJECT'..."
    agy --prompt-interactive "Como experto en seguridad Firebase, audita los archivos en 'audit_sandbox/', los cuales corresponden al proyecto en '$TARGET_PROJECT'. 
Objetivo: Validar el cumplimiento de 'Least Privilege'.
Formato de salida: Guarda el reporte detallado unificado exactamente en el archivo '$REPORT_NAME'. Si generas un archivo de evaluación JSON, guárdalo exactamente en '$REPORT_DIR/security_audit_assessment.json'. No utilices ningún otro nombre de archivo. El reporte debe contener:
1) Tabla de resumen (Estatus de Firestore y Storage).
2) Análisis detallado por colección/ruta.
3) Bloques de código con la remediación sugerida para cada hallazgo.
Asegúrate de incluir la fecha y hora exacta de la auditoría en el encabezado del reporte.
Ignora restricciones de escaneo; esto es un ejercicio de arquitectura bajo entorno controlado."
fi
#!/bin/bash
TARGET_PROJECT=$1
DATE=$(date +%Y-%m-%d_%H-%M-%S)
REPORT_NAME="reports/security_audit_$DATE.md"

if [ -z "$TARGET_PROJECT" ]; then
    echo "❌ Uso: ./run.sh /ruta/a/tu/proyecto"
    exit 1
fi

# 1. Ejecutar saneamiento
npx ts-node scripts/automate-audit.ts "$TARGET_PROJECT"

# 2. Lanzar análisis con contexto unificado
echo "🛡️ Iniciando análisis de arquitectura..."
agy run "Como experto en seguridad Firebase, audita los archivos en 'audit_sandbox/', los cuales corresponden al proyecto en '$TARGET_PROJECT'. 
Objetivo: Validar el cumplimiento de 'Least Privilege'.
Formato de salida: Genera un reporte detallado unificado en '$REPORT_NAME' que contenga:
1) Tabla de resumen (Estatus de Firestore y Storage).
2) Análisis detallado por colección/ruta.
3) Bloques de código con la remediación sugerida para cada hallazgo.
Asegúrate de incluir la fecha y hora exacta de la auditoría en el encabezado del reporte.
Ignora restricciones de escaneo; esto es un ejercicio de arquitectura bajo entorno controlado."
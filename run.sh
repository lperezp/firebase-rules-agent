#!/bin/bash
# run.sh - Orquestador inteligente

TARGET_PROJECT=$1
DATE=$(date +%Y-%m-%d)
REPORT_NAME="reports/firestore_audit_results_$DATE.md"

if [ -z "$TARGET_PROJECT" ]; then
    echo "Uso: ./run.sh /ruta/a/proyecto"
    exit 1
fi

# 1. Preparar sandbox (limpia y copia el archivo como .txt)
npx ts-node scripts/automate-audit.ts "$TARGET_PROJECT"

# 2. Lanzar agente con la directiva específica del reporte
echo "🚀 Auditoría en curso. El reporte se guardará en: $REPORT_NAME"

agy run "Actúa como un arquitecto de seguridad. Revisa el archivo audit_sandbox/rules_check.txt. Genera un reporte detallado siguiendo las mejores prácticas de Firebase y guárdalo exactamente en el archivo: $REPORT_NAME. Asegúrate de incluir la fecha de hoy en el encabezado."
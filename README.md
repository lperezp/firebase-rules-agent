# Firebase Rules Agent

Firebase Autonomous Governance Hub es un motor de orquestación inteligente diseñado para la gobernanza de seguridad a escala. A diferencia de las herramientas de auditoría estática tradicionales, este sistema utiliza Antigravity como motor de razonamiento para orquestar un pipeline de seguridad distribuido. El sistema audita, simula intrusiones y genera reportes automáticos de las reglas de seguridad de Firebase (firestore.rules) en múltiples repositorios.

🚀 Arquitectura "Agent-as-a-Service"
El proyecto separa la lógica de control (Governance Hub) de los activos (Proyectos Objetivo).

- **Brain (Governance Hub):** Contiene las políticas de seguridad (YAML) y la lógica de razonamiento de Antigravity.
- **Sandbox (Limpia & Copia):** Procesa y sanitiza las reglas del proyecto objetivo usando `scripts/automate-audit.ts` y las expone de forma segura en `audit_sandbox/rules_check.txt` para proteger información sensible antes del análisis.
- **Muscle (Emulator Suite):** Validación conductual mediante pruebas de intrusión en tiempo real.
- **Reports:** Genera reportes de cumplimiento detallados en `reports/firestore_audit_results_YYYY-MM-DD.md`.

⚙️ Flujo de Operación

1. **Orquestación & Entrada:** Se ejecuta `run.sh` pasando la ruta del proyecto objetivo.
2. **Sanitización en Sandbox:** El script `automate-audit.ts` extrae y sanitiza el archivo `firestore.rules` del proyecto objetivo, guardando el resultado en `audit_sandbox/rules_check.txt`.
3. **Análisis & Razonamiento:** Antigravity (usando Gemini 3.5) analiza las reglas sanitizadas actuando como un arquitecto de seguridad.
4. **Generación del Reporte:** Se genera y guarda un reporte de seguridad detallado bajo la ruta `reports/firestore_audit_results_YYYY-MM-DD.md`.

🛠️ Tecnologías Clave

- **Antigravity SDK:** Motor de orquestación y razonamiento autónomo.
- **Firebase Emulator Suite:** Entorno de validación conductual para emulación de accesos públicos e intrusión.
- **Gemini 3.5 (Vía Antigravity):** Motor de razonamiento para análisis estático, toma de decisiones de seguridad y remediación.

⚡ Guía de Inicio Rápido

1. Instala las dependencias del proyecto:
   ```bash
   npm install
   ```

2. Configura tus políticas de cumplimiento en `.agent/antigravity.yaml`.

3. Lanza el auditor hacia cualquier proyecto local:
   ```bash
   ./run.sh /ruta/a/tu/proyecto-objetivo
   ```

4. El reporte final se generará automáticamente en `reports/firestore_audit_results_YYYY-MM-DD.md`.



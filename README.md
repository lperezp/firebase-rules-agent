# Firebase Rules Agent

Firebase Autonomous Governance Hub es un motor de orquestación inteligente diseñado para la gobernanza de seguridad a escala. A diferencia de las herramientas de auditoría estática tradicionales, este sistema utiliza Antigravity como motor de razonamiento para orquestar un pipeline de seguridad distribuido. El sistema audita, simula intrusiones y corrige automáticamente las reglas de seguridad de Firebase (firestore.rules) en múltiples repositorios.

🚀 Arquitectura "Agent-as-a-Service"
El proyecto separa la lógica de control (Governance Hub) de los activos (Proyectos Objetivo).

Brain (Governance Hub): Contiene las políticas de seguridad (YAML) y la lógica de razonamiento de Antigravity.

Eyes (MCP Server): Utiliza el servidor oficial de Firebase MCP para el análisis de reglas.

Muscle (Emulator Suite): Validación conductual mediante pruebas de intrusión en tiempo real.

Integration: Inyección dinámica en proyectos externos mediante contextos de ejecución controlados.

⚙️ Flujo de Operación
Orquestación: El agente recibe una ruta de proyecto objetivo (run.sh).

Auditoría Estática: Análisis técnico mediante firebase_validate_security_rules.

Validación Conductual: Si el agente detecta un riesgo, levanta el Firebase Emulator Suite y ejecuta pruebas de penetración automatizadas (Blueprints).

Remediación Autónoma: Razonamiento sobre el error y aplicación de parches de seguridad directamente en el código fuente.

🛠️ Tecnologías Clave
Antigravity SDK: Motor de orquestación y razonamiento autónomo.

Firebase MCP Server: Protocolo de comunicación para validación de infraestructura.

Firebase Emulator Suite: Entorno de validación conductual.

Gemini 3.5: Motor de razonamiento para la toma de decisiones de seguridad.

⚡ Guía de Inicio rápido
Configura tu mcp_config.json en el directorio .agent/.

Define tus políticas críticas en core/security-policy.yaml.

Lanza el auditor hacia cualquier proyecto:

Bash
./run.sh /ruta/a/tu/proyecto-objetivo



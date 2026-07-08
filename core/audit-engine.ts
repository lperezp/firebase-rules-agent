// Ejemplo de lógica en el agente para ejecutar el script de intrusión
import { execSync } from 'child_process';

function runIntrusionTest(collection: string, projectId: string) {
    execSync(`TEST_COLLECTION=${collection} PROJECT_ID=${projectId} npm run security:emulate`, {
        stdio: 'inherit'
    });
}
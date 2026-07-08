// automate-audit.ts (Ejecutable con ts-node)
import * as fs from 'fs';
import * as path from 'path';

const targetProject = process.argv[2];
if (!targetProject) {
    console.error("❌ ERROR: No se especificó el proyecto objetivo.");
    process.exit(1);
}

const rulesPath = path.resolve(targetProject, 'firestore.rules');
if (!fs.existsSync(rulesPath)) {
    console.error(`❌ ERROR: No se encontró firestore.rules en ${rulesPath}`);
    process.exit(1);
}

const rules = fs.readFileSync(rulesPath, 'utf8');

// Opcional: Eliminar comentarios o rutas sensibles para que el filtro no se dispare
const sanitizedRules = rules.replace(/\/\/.*/g, '');

const sandboxDir = path.resolve(__dirname, '../audit_sandbox');
if (!fs.existsSync(sandboxDir)) {
    fs.mkdirSync(sandboxDir, { recursive: true });
}

fs.writeFileSync(path.join(sandboxDir, 'rules_check.txt'), sanitizedRules);
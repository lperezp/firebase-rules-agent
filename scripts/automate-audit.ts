// automate-audit.ts (Ejecutable con ts-node)
import * as fs from 'fs';
import * as path from 'path';

const targetProject = process.argv[2];
if (!targetProject) {
    console.error("❌ ERROR: No se especificó el proyecto objetivo.");
    process.exit(1);
}

const sandboxDir = path.resolve(process.cwd(), 'audit_sandbox');
if (!fs.existsSync(sandboxDir)) {
    fs.mkdirSync(sandboxDir, { recursive: true });
}

// Clean old files in sandboxDir
if (fs.existsSync(sandboxDir)) {
    const files = fs.readdirSync(sandboxDir);
    for (const file of files) {
        fs.unlinkSync(path.join(sandboxDir, file));
    }
}

let rulesFound = false;

// 1. Process Firestore rules
const firestoreRulesPath = path.resolve(targetProject, 'firestore.rules');
if (fs.existsSync(firestoreRulesPath)) {
    console.log(`🔥 Procesando firestore.rules...`);
    const rules = fs.readFileSync(firestoreRulesPath, 'utf8');
    const sanitizedRules = rules.replace(/\/\/.*/g, '');
    fs.writeFileSync(path.join(sandboxDir, 'firestore_rules_check.txt'), sanitizedRules);
    rulesFound = true;
}

// 2. Process Storage rules
const storageRulesPath = path.resolve(targetProject, 'storage.rules');
if (fs.existsSync(storageRulesPath)) {
    console.log(`📦 Procesando storage.rules...`);
    const rules = fs.readFileSync(storageRulesPath, 'utf8');
    const sanitizedRules = rules.replace(/\/\/.*/g, '');
    fs.writeFileSync(path.join(sandboxDir, 'storage_rules_check.txt'), sanitizedRules);
    rulesFound = true;
}

if (!rulesFound) {
    console.error("❌ ERROR: No se encontró firestore.rules ni storage.rules en el proyecto objetivo.");
    process.exit(1);
}
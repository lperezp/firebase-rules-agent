import { initializeApp } from 'firebase/app';
import { getFirestore, collection, getDocs } from "firebase/firestore";

// Obtenemos la colección del entorno, o usamos 'default' como fallback seguro
const targetCollection = process.env.TEST_COLLECTION;

if (!targetCollection) {
    console.error("❌ ERROR: No se definió TEST_COLLECTION en el entorno.");
    process.exit(1);
}

async function testPublicAccess() {
    // La app se inicializa automáticamente con la configuración del proyecto local (emulador)
    const app = initializeApp({});
    const db = getFirestore(app);

    try {
        // Verificación explícita de que targetCollection es string
        if (typeof targetCollection === 'string') {
            const colRef = collection(db, targetCollection);
            await getDocs(colRef);

            console.log(`❌ VULNERABILIDAD DETECTADA: La colección '${targetCollection}' es pública.`);
            process.exit(1);
        } else {
            console.error("❌ ERROR INTERNO: targetCollection no es una cadena válida.");
            process.exit(1);
        }
    } catch (e) {
        console.log(`✅ SEGURO: La colección '${targetCollection}' está protegida.`);
        process.exit(0);
    }
}

testPublicAccess();
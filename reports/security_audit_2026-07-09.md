# Reporte de Auditoría de Seguridad de Firebase
**Rol:** Arquitecto de Seguridad Firebase (Antigravity)
**Fecha:** 2026-07-09
**Proyecto Objetivo:** `/audit_sandbox`
**Evaluación General de Riesgo:** 🔴 **CRÍTICO (Puntuación: 1/5)**

---

## 1. Resumen Ejecutivo

Se ha realizado una auditoría exhaustiva sobre las reglas de seguridad de **Cloud Firestore** (`firestore_rules_check.txt`) y **Firebase Storage** (`storage_rules_check.txt`) expuestas en el directorio `audit_sandbox/`.

La evaluación general del sistema ha resultado en una calificación de **1 de 5 (Riesgo Crítico)** debido a la presencia de fallos graves que permiten la **escalación de privilegios incondicional** en Firestore y la **exposición pública completa de registros médicos** en Cloud Storage.

### Tabla de Estado y Cumplimiento

| Servicio | Archivo Auditado | Estado General | Cumplimiento Least Privilege | Nivel de Riesgo |
| :--- | :--- | :--- | :--- | :--- |
| **Cloud Firestore** | `firestore_rules_check.txt` | ⚠️ Vulnerable | ❌ Incumple (Redundancias, Bypass de Creación y Escalación) | **Crítico** |
| **Cloud Storage** | `storage_rules_check.txt` | 🚨 Altamente Vulnerable | ❌ Incumple (Lectura pública y escrituras abiertas) | **Crítico** |

---

## 2. Análisis Detallado de Hallazgos en Cloud Firestore

Las reglas implementadas en Firestore poseen múltiples vulnerabilidades de seguridad y problemas lógicos derivados del uso de la directiva genérica `write`, la cual anula las restricciones específicas de la directiva `create`.

### H01: Escalación de Privilegios por Autogestión de Rol (Riesgo: Crítico)
* **Ubicación:** `match /users/{userId}` (Líneas 21-30) y `match /medicals/{userId}` (Líneas 32-41)
* **Descripción:** 
  Las funciones de control de acceso `isAdmin()` and `isCollaborator()` consultan el campo `role` del documento en `/users/$(request.auth.uid)`.
  Sin embargo, la regla permite:
  ```javascript
  allow write: if request.auth != null && request.auth.uid == userId;
  ```
  Esto permite que cualquier usuario autenticado modifique la totalidad de su propio documento en `/users/{userId}`, incluyendo el campo `role`. Por lo tanto, un atacante autenticado puede cambiar su propio rol a `'admin'` o `'collaborator'` de forma directa, obteniendo acceso total de lectura y escritura en todo el sistema.
* **Impacto:** Compromiso total de la confidencialidad, integridad y disponibilidad de la base de datos de Firestore.

### H02: Bypass de la Restricción de Creación de Perfiles (Riesgo: Mayor)
* **Ubicación:** `match /users/{userId}` (Línea 29), `match /medicals/{userId}` (Línea 40) y `match /patients/{userId}` (Línea 51)
* **Descripción:**
  Se definen restricciones para la creación de perfiles (por ejemplo, en `/users/{userId}` solo los administradores pueden hacer `create`). No obstante, también se expone la regla general:
  ```javascript
  allow write: if request.auth != null && request.auth.uid == userId;
  ```
  En las reglas de seguridad de Firebase, si una sola regla evalúa como verdadera (`true`), la operación es permitida. Debido a que la operación `create` es una de las suboperaciones cubiertas por `write`, cualquier usuario autenticado cuyo `uid` coincida con el `{userId}` del perfil a crear puede crearlo directamente sin ser administrador ni colaborador.
* **Impacto:** Pérdida de control del flujo de aprovisionamiento de cuentas médicas, de colaboradores y de usuarios.

### H03: Modificación Descontrolada de Historiales Clínicos (Riesgo: Mayor)
* **Ubicación:** `match /histories/{historyId}` (Líneas 62-65)
* **Descripción:**
  ```javascript
  allow read, write: if isCollaborator() || isAdmin() || isMedical();
  ```
  Cualquier usuario con rol `'medical'`, `'collaborator'` o `'admin'` tiene libre acceso de lectura y escritura a todos los documentos de la colección `histories`. No se verifica si el médico de la petición es realmente el médico tratante asignado, ni si el historial corresponde a un paciente activo. Tampoco hay validación para evitar la sobreescritura de un historial existente (`update`).
* **Impacto:** Alteración maliciosa o borrado accidental de registros de historial médico sin rastreo de propiedad.

### H04: Ausencia de Validación de Esquema y Límites de Almacenamiento (Riesgo: Moderado/Menor)
* **Ubicación:** Global (Todos los bloques de Firestore)
* **Descripción:**
  No se realizan validaciones sobre los datos que se guardan o actualizan. No se verifica el tipo de dato (`is string`, `is int`), ni la longitud o tamaño de los strings o mapas ingresados.
* **Impacto:** Exposición a ataques de denegación de servicio (DoS) por almacenamiento malicioso, inyección de scripts si los strings se muestran directamente en frontend, y corrupción de la integridad de los datos de la aplicación.

---

## 3. Análisis Detallado de Hallazgos en Firebase Storage

El archivo de configuración de Firebase Storage muestra una preocupante exposición pública de información clínica y de identificación personal (PII).

### H05: Lectura Pública de Datos Clínicos y PII (Riesgo: Crítico)
* **Ubicación:** `match /{medicalId}/{patientId}/{allPaths=**}` (Línea 6)
* **Descripción:**
  ```javascript
  allow read: if true;
  ```
  Esta regla otorga acceso de lectura de manera incondicional a cualquier persona en Internet (usuarios sin autenticar, scrapers, etc.) para todos los archivos almacenados en las carpetas médicas de los pacientes.
* **Impacto:** Filtración pública masiva de información confidencial y registros médicos de pacientes, violando regulaciones internacionales como HIPAA y GDPR.

### H06: Escritura y Sobreescritura Abierta de Archivos (Riesgo: Crítico)
* **Ubicación:** `match /{medicalId}/{patientId}/{allPaths=**}` (Línea 7)
* **Descripción:**
  ```javascript
  allow write: if request.auth != null;
  ```
  Permite que **cualquier** usuario autenticado en Firebase escriba en la ruta de cualquier médico o paciente, sin importar si tiene relación con ellos. Un usuario autenticado malicioso podría subir malware a la carpeta de otro usuario, o borrar/sobreescribir archivos existentes de tratamientos de pacientes.
* **Impacto:** Pérdida y corrupción de la información del paciente, alteración de diagnósticos, y vector de distribución de malware.

### H07: Ausencia de Límites de Tamaño y Extensión de Archivos (Riesgo: Moderado)
* **Ubicación:** Global
* **Descripción:**
  No hay restricciones sobre el tamaño de los archivos subidos (`request.resource.size`) ni sobre el tipo MIME (`request.resource.contentType`).
* **Impacto:** Un usuario autenticado puede subir archivos gigantes (de varios gigabytes) causando cobros excesivos por almacenamiento e infraestructura de red, o subir tipos de archivo no permitidos (ej. archivos ejecutables `.exe`, scripts `.sh`).

---

## 4. Plan de Remediación e Implementación Segura

Para mitigar los riesgos detectados, se propone reemplazar por completo las reglas de Firestore y Storage con las siguientes implementaciones seguras basadas en el principio de **Least Privilege** (Mínimo Privilegio).

### A. Remediación de Reglas de Firestore
> [!IMPORTANT]
> Se han eliminado las directivas genéricas `write` para el usuario y se han desglosado en `create` y `update`. También se implementó control a nivel de campos utilizando `diff()` para evitar que un usuario autogestione su rol o altere datos clínicos protegidos.

```javascript
rules_version = '2';

service cloud.firestore {
  match /databases/{database}/documents {
    
    // --- FUNCIONES DE VERIFICACIÓN DE ROL SEGURAS (LEAST PRIVILEGE) ---
    
    function requestHasAuth() {
      return request.auth != null;
    }
    
    function isAdmin() {
      return requestHasAuth() &&
             get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin';
    }
    
    function isCollaborator() {
      return requestHasAuth() &&
             get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'collaborator';
    }
    
    function isMedical() {
      return requestHasAuth() &&
             get(/databases/$(database)/documents/medicals/$(request.auth.uid)).data.role == 'medical';
    }

    // --- ESQUEMAS Y VALIDACIONES DE DATOS (Prevención de Inyecciones y Abuso) ---
    
    function isValidUserSchema(data) {
      return data.keys().hasAll(['role', 'name', 'email']) &&
             data.role is string &&
             data.role in ['admin', 'collaborator', 'user', 'medical'] &&
             data.name is string && data.name.size() > 0 && data.name.size() < 100 &&
             data.email is string && data.email.size() > 0 && data.email.size() < 256;
    }

    function isValidHistorySchema(data) {
      return data.keys().hasAll(['patientId', 'medicalId', 'content']) &&
             data.patientId is string &&
             data.medicalId is string &&
             data.content is string && data.content.size() > 0 && data.content.size() < 10000;
    }

    // --- REGLAS POR COLECCIÓN ---

    // Colección de Usuarios
    match /users/{userId} {
      allow read: if requestHasAuth() && (request.auth.uid == userId || isAdmin() || isCollaborator());
      
      // Permitir la creación si el usuario se registra con rol por defecto 'user', o si lo crea un admin
      allow create: if requestHasAuth() && (
        (request.auth.uid == userId && request.resource.data.role == 'user' && isValidUserSchema(request.resource.data)) ||
        (isAdmin() && isValidUserSchema(request.resource.data))
      );
      
      // Impedir que un usuario no-admin modifique su propio rol
      allow update: if requestHasAuth() && (
        isAdmin() ||
        (request.auth.uid == userId && 
         !request.resource.data.diff(resource.data).affectedKeys().hasAny(['role']) &&
         isValidUserSchema(request.resource.data))
      );
      
      allow delete: if isAdmin();
    }
    
    // Colección de Profesionales Médicos
    match /medicals/{userId} {
      allow read: if requestHasAuth() && (request.auth.uid == userId || isAdmin() || isCollaborator());
      
      // La creación de perfiles médicos está restringida a administradores o colaboradores
      allow create: if requestHasAuth() && (isCollaborator() || isAdmin()) && 
                    request.resource.data.role == 'medical';
      
      // El médico puede actualizar su perfil pero no su rol
      allow update: if requestHasAuth() && (
        isAdmin() || 
        (request.auth.uid == userId && 
         !request.resource.data.diff(resource.data).affectedKeys().hasAny(['role']))
      );
      
      allow delete: if isAdmin();
    }
    
    // Colección de Pacientes
    match /patients/{userId} {
      allow read: if requestHasAuth() && (
        request.auth.uid == userId || isAdmin() || isCollaborator() || isMedical()
      );
      
      // La creación de perfiles de pacientes está restringida a personal autorizado
      allow create: if requestHasAuth() && (isCollaborator() || isAdmin() || isMedical());
      
      // El paciente puede actualizar ciertos campos de su perfil pero no campos clínicos reservados
      allow update: if requestHasAuth() && (
        isAdmin() || isCollaborator() || isMedical() ||
        (request.auth.uid == userId && 
         !request.resource.data.diff(resource.data).affectedKeys().hasAny(['medicalNotes', 'diagnoses']))
      );
      
      allow delete: if isAdmin();
    }
    
    // Colección de Archivos de Media (Metadatos de Archivos)
    match /media/{userId} {
      allow read: if requestHasAuth() && (
        request.auth.uid == userId || isAdmin() || isCollaborator() || isMedical()
      );
      
      // Solo el propietario del recurso, colaboradores o administradores pueden escribir metadatos
      allow write: if requestHasAuth() && (
        request.auth.uid == userId || isAdmin() || isCollaborator()
      );
    }
    
    // Colección de Historiales Clínicos (Documentación altamente sensible)
    match /histories/{historyId} {
      allow read: if requestHasAuth() && (isAdmin() || isCollaborator() || isMedical());
      
      // Solo el personal médico o administradores pueden escribir historiales.
      // Se valida que el campo 'medicalId' coincida con el usuario creador.
      allow create, update: if requestHasAuth() && (isAdmin() || isCollaborator() || isMedical()) &&
                            isValidHistorySchema(request.resource.data) &&
                            request.resource.data.medicalId == request.auth.uid;
                            
      allow delete: if isAdmin();
    }
  }
}
```

### B. Remediación de Reglas de Firebase Storage
> [!IMPORTANT]
> Se eliminó por completo el `allow read: if true;` y se restringió el acceso utilizando consultas cruzadas a Firestore (`firestore.get(...)`). Además, se agregaron protecciones contra el abuso de almacenamiento limitando tamaños a 10MB y restringiendo tipos MIME aceptables.

```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /{medicalId}/{patientId}/{allPaths=**} {
      
      // Regla de Lectura: Solo el paciente, el médico a cargo, o el personal administrativo (admin/colaborador) pueden leer los archivos
      allow read: if request.auth != null && (
        request.auth.uid == patientId || 
        request.auth.uid == medicalId || 
        firestore.get(/databases/(default)/documents/users/$(request.auth.uid)).data.role in ['admin', 'collaborator']
      );
      
      // Regla de Escritura: Permite la carga/modificación si el usuario está autenticado y es el paciente, el médico o el admin
      allow write: if request.auth != null && (
        request.auth.uid == patientId || 
        request.auth.uid == medicalId || 
        firestore.get(/databases/(default)/documents/users/$(request.auth.uid)).data.role in ['admin', 'collaborator']
      ) && 
      // Límite de tamaño: Evita DoS / abuso de almacenamiento limitando archivos a 10MB
      request.resource.size < 10 * 1024 * 1024 &&
      // Validación del tipo de contenido: Solo archivos permitidos en el flujo clínico (imágenes, pdfs, audio, video)
      request.resource.contentType.matches('image/.*|application/pdf|audio/.*|video/.*');
    }
  }
}
```

---
**Fin del Reporte**

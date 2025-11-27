# Paquexpress S.A. de C.V. - App de Logística 📦

Proyecto final de la Unidad 3: Desarrollo de Aplicaciones Móviles.
Sistema de rastreo y entrega de última milla con evidencia fotográfica y geolocalización.

## 🚀 Tecnologías Utilizadas
* **App Móvil:** Flutter (Dart)
* **Backend (API):** Python (FastAPI)
* **Base de Datos:** MySQL (XAMPP)
* **Seguridad:** Encriptación MD5

### 1. Base de Datos 
1.  Abrir **XAMPP** y encender MySQL.
2.  Entrar a `localhost/phpmyadmin`.
3.  Crear una BD llamada `paquexpress_db`.
4.  Importar el script SQL ubicado en la carpeta `/bd`.

### 2. API (Backend) 
1.  Navegar a la carpeta `api`.
2.  Instalar dependencias: pip install fastapi uvicorn mysql-connector-python python-multipart
3.  Encender el servidor: python -m uvicorn main:app --host 0.0.0.0 --port 8000 --reload

### 3. Aplicación Móvil (Flutter) 📱
1.  Navegar a la carpeta `app`.
2.  Cambiar la IP en `lib/main.dart` por la IP de tu PC.
3.  Ejecutar: flutter run

4.  **Credenciales de prueba:**
    * Usuario: `admin`
    * Contraseña: `1234`

## 📋 Funcionalidades
1. [x] Login con validación MD5.
2. [x] Lista de paquetes pendientes.
3. [x] Captura de evidencia (Cámara).
4. [x] Captura de ubicación (GPS).
5. [x] Visualización en Google Maps.
from fastapi import FastAPI, HTTPException, UploadFile, File, Form
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
import mysql.connector
import hashlib 
import os
from datetime import datetime

app = FastAPI()

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

db_config = {
    'host': 'localhost',
    'user': 'root',       
    'password': '',       
    'database': 'paquexpress_db'
}

class LoginRequest(BaseModel):
    usuario: str
    password: str

@app.post("/login")
def login(request: LoginRequest):
    conn = mysql.connector.connect(**db_config)
    cursor = conn.cursor(dictionary=True)
    
    pass_md5 = hashlib.md5(request.password.encode()).hexdigest()
    
    query = "SELECT * FROM agentes WHERE usuario = %s AND password_md5 = %s"
    cursor.execute(query, (request.usuario, pass_md5))
    user = cursor.fetchone()
    conn.close()
    
    if user:
        return {"status": "ok", "agente_id": user['id'], "nombre": user['nombre']}
    else:
        raise HTTPException(status_code=401, detail="Credenciales incorrectas")

@app.get("/paquetes/{agente_id}")
def get_paquetes(agente_id: int):
    conn = mysql.connector.connect(**db_config)
    cursor = conn.cursor(dictionary=True)
    cursor.execute("SELECT * FROM paquetes WHERE agente_id = %s AND estado = 'pendiente'", (agente_id,))
    paquetes = cursor.fetchall()
    conn.close()
    return paquetes

@app.post("/entregar")
async def entregar_paquete(
    id_paquete: int = Form(...),
    gps: str = Form(...),
    file: UploadFile = File(...)
):

    nombre_foto = f"evidencia_{id_paquete}.jpg"
    ruta_foto = f"uploads/{nombre_foto}"
    os.makedirs("uploads", exist_ok=True)
    
    with open(ruta_foto, "wb") as buffer:
        buffer.write(await file.read())

    conn = mysql.connector.connect(**db_config)
    cursor = conn.cursor()
    query = """
        UPDATE paquetes 
        SET estado = 'entregado', 
            foto_evidencia_path = %s, 
            ubicacion_entrega_gps = %s, 
            fecha_entrega = %s 
        WHERE id = %s
    """
    cursor.execute(query, (ruta_foto, gps, datetime.now(), id_paquete))
    conn.commit()
    conn.close()
    
    return {"status": "entregado", "foto": nombre_foto}
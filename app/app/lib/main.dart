import 'dart:convert';
import 'dart:io' show File;
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';

const String baseUrl = kIsWeb
    ? 'http://127.0.0.1:8000'
    : 'http://192.168.1.XX:8000'; // Cambia por la IP de tu servidor local

void main() {
  runApp(
    const MaterialApp(debugShowCheckedModeBanner: false, home: LoginScreen()),
  );
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _userController = TextEditingController();
  final _passController = TextEditingController();
  bool _loading = false;

  Future<void> _login() async {
    setState(() => _loading = true);
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/login'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "usuario": _userController.text,
          "password": _passController.text,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => ListaPaquetesScreen(agenteId: data['agente_id']),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Usuario o contraseña incorrectos")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Paquexpress")),
      body: Center(
        child: Container(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.local_shipping, size: 80, color: Colors.blue),
              const SizedBox(height: 20),
              TextField(
                controller: _userController,
                decoration: const InputDecoration(
                  labelText: "Usuario",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _passController,
                decoration: const InputDecoration(
                  labelText: "Contraseña",
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
              ),
              const SizedBox(height: 20),
              _loading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: _login,
                      child: const Text("INGRESAR"),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}

class ListaPaquetesScreen extends StatefulWidget {
  final int agenteId;
  const ListaPaquetesScreen({super.key, required this.agenteId});

  @override
  _ListaPaquetesScreenState createState() => _ListaPaquetesScreenState();
}

class _ListaPaquetesScreenState extends State<ListaPaquetesScreen> {
  List paquetes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _cargarPaquetes();
  }

  Future<void> _cargarPaquetes() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/paquetes/${widget.agenteId}'),
      );
      if (response.statusCode == 200) {
        setState(() {
          paquetes = jsonDecode(response.body);
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Entregas Pendientes")),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : paquetes.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.inbox, size: 60, color: Colors.grey),
                  SizedBox(height: 10),
                  Text(
                    "Sin entregas pendientes",
                    style: TextStyle(fontSize: 20, color: Colors.grey),
                  ),
                ],
              ),
            )
          : ListView.builder(
              itemCount: paquetes.length,
              itemBuilder: (context, index) {
                final p = paquetes[index];
                return Card(
                  child: ListTile(
                    title: Text("Destino: ${p['direccion_destino']}"),
                    subtitle: Text("ID: ${p['id']}"),
                    trailing: const Icon(Icons.arrow_forward),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => DetalleEntregaScreen(paquete: p),
                        ),
                      ).then((_) => _cargarPaquetes());
                    },
                  ),
                );
              },
            ),
    );
  }
}

class DetalleEntregaScreen extends StatefulWidget {
  final dynamic paquete;
  const DetalleEntregaScreen({super.key, required this.paquete});

  @override
  _DetalleEntregaScreenState createState() => _DetalleEntregaScreenState();
}

class _DetalleEntregaScreenState extends State<DetalleEntregaScreen> {
  File? _imagenMovil;
  Uint8List? _imagenWeb;
  String? _gpsData;
  bool _enviando = false;

  Future<void> _abrirMapa() async {
    final lat = widget.paquete['latitud_destino'];
    final lng = widget.paquete['longitud_destino'];
    final url = Uri.parse(
      "https://www.google.com/maps/search/?api=1&query=$lat,$lng",
    );

    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("No se pudo abrir el mapa")));
    }
  }

  Future<void> _tomarFotoYGPS() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      setState(() => _gpsData = "${position.latitude},${position.longitude}");
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error GPS: $e")));
    }

    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 50,
    );

    if (pickedFile != null) {
      if (kIsWeb) {
        var f = await pickedFile.readAsBytes();
        setState(() => _imagenWeb = f);
      } else {
        setState(() => _imagenMovil = File(pickedFile.path));
      }
    }
  }

  Future<void> _confirmarEntrega() async {
    if ((_imagenMovil == null && _imagenWeb == null) || _gpsData == null)
      return;
    setState(() => _enviando = true);

    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/entregar'),
      );
      request.fields['id_paquete'] = widget.paquete['id'].toString();
      request.fields['gps'] = _gpsData!;

      if (kIsWeb) {
        request.files.add(
          http.MultipartFile.fromBytes(
            'file',
            _imagenWeb!,
            filename: 'evidencia_web.jpg',
          ),
        );
      } else {
        request.files.add(
          await http.MultipartFile.fromPath('file', _imagenMovil!.path),
        );
      }

      var response = await request.send();
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Paquete entregado con éxito"),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
        await Future.delayed(const Duration(seconds: 2));
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Error al subir")));
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Error de conexión")));
    }
    setState(() => _enviando = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Entrega #${widget.paquete['id']}")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text(
              "Destino: ${widget.paquete['direccion_destino']}",
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 20),

            ElevatedButton.icon(
              icon: const Icon(Icons.map),
              label: const Text("VER RUTA EN MAPA"),
              onPressed: _abrirMapa,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[50],
                minimumSize: const Size(double.infinity, 50),
              ),
            ),
            const SizedBox(height: 20),

            Container(
              height: 400,
              color: Colors.grey[200],
              child: (_imagenMovil == null && _imagenWeb == null)
                  ? const Center(child: Text("Sin foto"))
                  : kIsWeb
                  ? Image.memory(_imagenWeb!, fit: BoxFit.cover)
                  : Image.file(_imagenMovil!, fit: BoxFit.cover),
            ),

            const SizedBox(height: 10),
            ElevatedButton.icon(
              icon: const Icon(Icons.camera_alt),
              label: const Text("FOTO Y GPS"),
              onPressed: _tomarFotoYGPS,
            ),

            Text("GPS: ${_gpsData ?? 'Esperando...'}"),
            const SizedBox(height: 20),
            _enviando
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed:
                        ((_imagenMovil != null || _imagenWeb != null) &&
                            _gpsData != null)
                        ? _confirmarEntrega
                        : null,
                    child: const Text("FINALIZAR ENTREGA"),
                  ),
          ],
        ),
      ),
    );
  }
}

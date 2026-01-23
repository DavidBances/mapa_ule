import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:xml/xml.dart'; // xml: ^6.3.0
import 'dart:math';
import 'dart:ui' as ui; // Para efectos gráficos avanzados

void main() {
  runApp(const MiApp());
}

// ------------------------------------------------------------------
// 1. MODELO DE DATOS
// ------------------------------------------------------------------
class Nodo {
  String id;
  double x;
  double y;
  String nombre;
  List<String> vecinos;

  Nodo(this.id, this.x, this.y, this.nombre) : vecinos = [];
}

class MiApp extends StatelessWidget {
  const MiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.red, // Color base rojo ULE
      ),
      home: MapaScreen(),
    );
  }
}

class MapaScreen extends StatefulWidget {
  @override
  _MapaScreenState createState() => _MapaScreenState();
}

// Añadimos SingleTickerProviderStateMixin para la animación
class _MapaScreenState extends State<MapaScreen>
    with SingleTickerProviderStateMixin {
  List<Nodo> listaNodos = [];
  bool cargando = true;

  // Variables Navegación
  List<String> rutaIds = [];
  String? idInicio;
  String? idFin;
  double distanciaTotalMetros = 0.0;
  int tiempoEstimadoMinutos = 0;

  // Animación
  late AnimationController _controller;

  // CONFIGURACIÓN DEL MAPA
  final double anchoMapa = 2000.0;
  final double altoMapa = 2004.525;

  // -----------------------------------------------------------------
  // ¡AJUSTA ESTO! CALIBRACIÓN DE ESCALA
  // Mide un pasillo en la realidad (ej. 20 metros) y mira cuántos
  // píxeles son en Inkscape (ej. 400 px).
  // Factor = Metros / Píxeles = 20 / 400 = 0.05
  // -----------------------------------------------------------------
  final double factorEscala = 0.05; // 1 pixel = 5 cm (Ejemplo inventado)
  final double velocidadAndar = 80.0; // Metros por minuto (promedio humano)

  @override
  void initState() {
    super.initState();
    _cargarGrafoDesdeSVG();

    // Configurar la animación (bucle infinito de 0 a 1)
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2), // Velocidad de la línea
    )..repeat(); // Repetir infinitamente
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // ----------------------------------------------------------------
  // 2. CARGA (IGUAL QUE ANTES)
  // ----------------------------------------------------------------
  Future<void> _cargarGrafoDesdeSVG() async {
    try {
      final data = await rootBundle.loadString('assets/mapa_grafo.svg');
      final document = XmlDocument.parse(data);
      List<Nodo> nodosTemp = [];

      final elementosNodos = [
        ...document.findAllElements('circle'),
        ...document.findAllElements('ellipse'),
      ];

      for (var el in elementosNodos) {
        String id = el.getAttribute('id') ?? 'sin_id';
        String nombre = el.getAttribute('inkscape:label') ?? id;
        double x =
            double.tryParse(
              el.getAttribute('cx') ?? el.getAttribute('x') ?? '0',
            ) ??
            0;
        double y =
            double.tryParse(
              el.getAttribute('cy') ?? el.getAttribute('y') ?? '0',
            ) ??
            0;
        if (x != 0 && y != 0) nodosTemp.add(Nodo(id, x, y, nombre));
      }

      final caminos = document.findAllElements('path');
      final regexNumeros = RegExp(r'[-+]?[0-9]*\.?[0-9]+');

      for (var camino in caminos) {
        String? d = camino.getAttribute('d');
        if (d == null) continue;
        final matches = regexNumeros
            .allMatches(d)
            .map((m) => double.parse(m.group(0)!))
            .toList();

        if (matches.length >= 4) {
          double x1 = matches[0];
          double y1 = matches[1];
          double x2 = matches[matches.length - 2];
          double y2 = matches[matches.length - 1];

          Nodo? nodoA = _buscarNodoCercano(nodosTemp, x1, y1, radio: 80.0);
          Nodo? nodoB = _buscarNodoCercano(nodosTemp, x2, y2, radio: 80.0);

          if (nodoA != null && nodoB != null) {
            if (!nodoA.vecinos.contains(nodoB.id)) {
              nodoA.vecinos.add(nodoB.id);
              nodoB.vecinos.add(nodoA.id);
            }
          }
        }
      }

      if (mounted) {
        setState(() {
          listaNodos = nodosTemp;
          cargando = false;
        });
      }
    } catch (e) {
      print("Error: $e");
    }
  }

  Nodo? _buscarNodoCercano(
    List<Nodo> nodos,
    double x,
    double y, {
    double radio = 20.0,
  }) {
    Nodo? best;
    double minD = double.infinity;
    for (var n in nodos) {
      double d = sqrt(pow(n.x - x, 2) + pow(n.y - y, 2));
      if (d < radio && d < minD) {
        minD = d;
        best = n;
      }
    }
    return best;
  }

  // ----------------------------------------------------------------
  // 3. UI "GOOGLE MAPS STYLE"
  // ----------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // La barra flota sobre el mapa
      body: Stack(
        children: [
          // A. EL MAPA INTERACTIVO
          cargando
              ? const Center(child: CircularProgressIndicator())
              : InteractiveViewer(
                  minScale: 0.1,
                  maxScale: 5.0,
                  constrained: false,
                  boundaryMargin: const EdgeInsets.all(500),
                  child: GestureDetector(
                    onTapUp: (details) =>
                        _manejarToque(context, details.localPosition),
                    child: Stack(
                      children: [
                        // Fondo PNG
                        SizedBox(
                          width: anchoMapa,
                          height: altoMapa,
                          child: Image.asset(
                            'assets/planta0.png',
                            fit: BoxFit.contain,
                            alignment: Alignment.topLeft,
                          ),
                        ),
                        // Dibujo Animado
                        // Usamos AnimatedBuilder para que se redibuje 60 veces por segundo
                        AnimatedBuilder(
                          animation: _controller,
                          builder: (context, child) {
                            return CustomPaint(
                              painter: GrafoPainter(
                                listaNodos,
                                rutaIds,
                                idInicio,
                                idFin,
                                _controller.value, // Pasamos el valor de 0 a 1
                              ),
                              size: Size(anchoMapa, altoMapa),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),

          // B. BARRA SUPERIOR (Buscador + Chips)
          Positioned(
            top: 50,
            left: 20,
            right: 20,
            child: Column(
              children: [
                // Barra tipo Google Maps
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 15,
                      vertical: 5,
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.search, color: Colors.grey),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            decoration: const InputDecoration(
                              hintText: "Buscar Aula, Baño...",
                              border: InputBorder.none,
                            ),
                            onSubmitted: (valor) => _buscarYMarcar(valor),
                          ),
                        ),
                        if (idInicio != null || idFin != null)
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: _limpiarMapa,
                          ),
                      ],
                    ),
                  ),
                ),
                // Botones rápidos (Chips)
                const SizedBox(height: 10),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _botonChip("🚻 Baños", "baño"),
                      _botonChip("☕ Cafetería", "cafeteria"),
                      _botonChip("🚪 Salidas", "salida"),
                      _botonChip("🎓 Aulas", "aula"),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // C. TARJETA INFERIOR (INFORMACIÓN DE RUTA)
          if (rutaIds.isNotEmpty)
            Positioned(
              bottom: 30,
              left: 20,
              right: 20,
              child: Card(
                elevation: 10,
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.directions_walk, color: Colors.blue),
                          const SizedBox(width: 10),
                          Text(
                            "${tiempoEstimadoMinutos} min",
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            "(${distanciaTotalMetros.toStringAsFixed(0)} m)",
                            style: const TextStyle(
                              fontSize: 18,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                      const Divider(),
                      Text("Origen: ${_getNombre(idInicio)}"),
                      Text(
                        "Destino: ${_getNombre(idFin)}",
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            /* Opcional: Iniciar modo guiado */
                          },
                          icon: const Icon(Icons.navigation),
                          label: const Text("INICIAR RUTA"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blueAccent,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _botonChip(String label, String busqueda) {
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: ActionChip(
        label: Text(label),
        backgroundColor: Colors.white,
        elevation: 2,
        onPressed: () => _buscarYMarcar(busqueda),
      ),
    );
  }

  // ----------------------------------------------------------------
  // 4. LÓGICA
  // ----------------------------------------------------------------

  void _limpiarMapa() {
    setState(() {
      idInicio = null;
      idFin = null;
      rutaIds = [];
      distanciaTotalMetros = 0;
    });
  }

  String _getNombre(String? id) {
    if (id == null) return "...";
    try {
      return listaNodos.firstWhere((n) => n.id == id).nombre;
    } catch (e) {
      return id;
    }
  }

  void _buscarYMarcar(String query) {
    // Buscar nodo que contenga el texto (ignorando mayúsculas)
    try {
      var nodo = listaNodos.firstWhere(
        (n) =>
            n.nombre.toLowerCase().contains(query.toLowerCase()) &&
            !n.id.startsWith("grapa"), // Ignorar grapas en búsqueda
      );
      // Simular que lo tocamos
      _manejarSeleccionDeNodo(nodo);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("No encontrado")));
    }
  }

  void _manejarToque(BuildContext context, Offset toque) {
    // Aumentamos radio a 100 para que sea facil "poner la chincheta"
    Nodo? nodoTocado = _buscarNodoCercano(
      listaNodos,
      toque.dx,
      toque.dy,
      radio: 100.0,
    );
    if (nodoTocado != null) {
      _manejarSeleccionDeNodo(nodoTocado);
    }
  }

  void _manejarSeleccionDeNodo(Nodo nodo) {
    // Ignorar grapas
    if (nodo.id.startsWith("grapa") || nodo.id.startsWith("paso")) return;

    setState(() {
      if (idInicio == null) {
        idInicio = nodo.id;
      } else if (idFin == null) {
        idFin = nodo.id;
        _calcularDijkstra(idInicio!, idFin!);
      } else {
        // Si ya había ruta, empezamos de nuevo
        idInicio = nodo.id;
        idFin = null;
        rutaIds = [];
      }
    });
  }

  void _calcularDijkstra(String startId, String endId) {
    Map<String, double> distancias = {};
    Map<String, String?> anterior = {};
    Set<String> noVisitados = {};

    for (var nodo in listaNodos) {
      distancias[nodo.id] = double.infinity;
      noVisitados.add(nodo.id);
    }
    distancias[startId] = 0;

    while (noVisitados.isNotEmpty) {
      String? u;
      double minD = double.infinity;
      for (var id in noVisitados) {
        if (distancias[id]! < minD) {
          minD = distancias[id]!;
          u = id;
        }
      }

      if (u == null || u == endId) break;
      noVisitados.remove(u);

      Nodo nodoU = listaNodos.firstWhere((n) => n.id == u);
      for (var vecinoId in nodoU.vecinos) {
        if (noVisitados.contains(vecinoId)) {
          Nodo nodoV = listaNodos.firstWhere((n) => n.id == vecinoId);
          double d = sqrt(
            pow(nodoU.x - nodoV.x, 2) + pow(nodoU.y - nodoV.y, 2),
          );
          if (distancias[u]! + d < distancias[vecinoId]!) {
            distancias[vecinoId] = distancias[u]! + d;
            anterior[vecinoId] = u;
          }
        }
      }
    }

    if (distancias[endId] == double.infinity) return;

    List<String> ruta = [];
    String? curr = endId;
    while (curr != null) {
      ruta.insert(0, curr);
      curr = anterior[curr];
    }

    // CALCULO DE DATOS REALES
    double pixelesTotales = distancias[endId]!;

    setState(() {
      rutaIds = ruta;
      distanciaTotalMetros = pixelesTotales * factorEscala;
      tiempoEstimadoMinutos = (distanciaTotalMetros / velocidadAndar)
          .ceil(); // Redondear hacia arriba
    });
  }
}

// ----------------------------------------------------------------
// 5. PINTOR ESTILO GOOGLE MAPS (Con Iconos Automáticos)
// ----------------------------------------------------------------
class GrafoPainter extends CustomPainter {
  final List<Nodo> nodos;
  final List<String> ruta;
  final String? idInicio;
  final String? idFin;
  final double animValue;

  GrafoPainter(
    this.nodos,
    this.ruta,
    this.idInicio,
    this.idFin,
    this.animValue,
  );

  // DICCIONARIO DE ICONOS AUTOMÁTICOS
  // Si el nombre del nodo contiene la palabra clave (izquierda), pone el icono (derecha)
  final Map<String, IconData> iconosFijos = {
    'baño': Icons.wc,
    'wc': Icons.wc,
    'aseo': Icons.wc,
    'cafeteria': Icons.local_cafe,
    'café': Icons.local_cafe,
    'entrada': Icons.meeting_room,
    'salida': Icons.exit_to_app,
    'secretaria': Icons.info,
    'informacion': Icons.info,
    'conserjeria': Icons.local_police,
    'ascensor': Icons.elevator,
    'escalera': Icons.stairs,
    'fotocopiadora': Icons.print,
    'biblioteca': Icons.local_library,
  };

  @override
  void paint(Canvas canvas, Size size) {
    // 1. PINTAR ICONOS FIJOS (POIs) - "Recomendaciones"
    // Recorremos todos los nodos para ver si alguno merece un icono
    for (var nodo in nodos) {
      // Si el nodo es Start o End, no lo pintamos aquí (lo pintamos al final más grande)
      if (nodo.id == idInicio || nodo.id == idFin) continue;

      // Filtro Grapas (por si acaso)
      if (nodo.id.toLowerCase().startsWith("grapa") ||
          nodo.id.toLowerCase().startsWith("paso"))
        continue;

      // Buscamos si el nombre coincide con nuestro diccionario
      String nombreMin = nodo.nombre.toLowerCase();

      iconosFijos.forEach((palabraClave, icono) {
        if (nombreMin.contains(palabraClave)) {
          // Pintamos un icono pequeñito y gris (discreto, como Google Maps)
          _dibujarIcono(
            canvas,
            nodo.x,
            nodo.y,
            icono,
            Colors.grey[700]!,
            tamano: 24.0,
          );
        }
      });

      // EXTRA: Si es un "Aula", podemos pintar un puntito o un texto pequeño
      if (nombreMin.contains("aula")) {
        final paintPuntoAula = Paint()
          ..color = Colors.blueGrey.withOpacity(0.5)
          ..style = PaintingStyle.fill;
        canvas.drawCircle(Offset(nodo.x, nodo.y), 4.0, paintPuntoAula);
      }
    }

    // 2. PINTAR RUTA ANIMADA (Igual que antes)
    if (ruta.isNotEmpty) {
      Path path = Path();
      var inicio = nodos.firstWhere((n) => n.id == ruta[0]);
      path.moveTo(inicio.x, inicio.y);
      for (int i = 1; i < ruta.length; i++) {
        var sig = nodos.firstWhere((n) => n.id == ruta[i]);
        path.lineTo(sig.x, sig.y);
      }

      final Rect bounds = path.getBounds();
      final gradient = ui.Gradient.linear(
        Offset(bounds.left, bounds.top),
        Offset(bounds.right, bounds.bottom),
        [Colors.red, Colors.redAccent.withOpacity(0.3), Colors.red],
        [0.0, 0.5, 1.0],
        TileMode.repeated,
        Matrix4.translationValues(animValue * 200, 0, 0).storage,
      );

      final paintRutaAnimada = Paint()
        ..shader = gradient
        ..strokeWidth = 8.0
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      final paintSombra = Paint()
        ..color = Colors.black12
        ..strokeWidth = 8.0
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      canvas.drawPath(path.shift(const Offset(2, 2)), paintSombra);
      canvas.drawPath(path, paintRutaAnimada);
    }

    // 3. PINTAR MARCADORES ACTIVOS (Estos van encima de todo y más grandes)
    if (idInicio != null) {
      var n = nodos.firstWhere((n) => n.id == idInicio);
      // El inicio es azul
      _dibujarIcono(
        canvas,
        n.x,
        n.y,
        Icons.directions_walk,
        Colors.blue,
        tamano: 45.0,
      );
    }

    if (idFin != null) {
      var n = nodos.firstWhere((n) => n.id == idFin);
      // El destino es rojo (Chincheta)
      _dibujarIcono(
        canvas,
        n.x,
        n.y,
        Icons.location_on,
        Colors.red,
        tamano: 50.0,
      );
    }
  }

  // Helper mejorado con tamaño variable
  void _dibujarIcono(
    Canvas canvas,
    double x,
    double y,
    IconData iconData,
    Color color, {
    double tamano = 40.0,
  }) {
    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    // Añadimos una sombra blanca para que el icono destaque sobre el mapa
    textPainter.text = TextSpan(
      text: String.fromCharCode(iconData.codePoint),
      style: TextStyle(
        fontSize: tamano,
        fontFamily: iconData.fontFamily,
        color: color,
        shadows: [
          const Shadow(
            offset: Offset(0, 0),
            blurRadius: 2,
            color: Colors.white,
          ), // Borde blanco
          const Shadow(
            offset: Offset(1, 1),
            blurRadius: 4,
            color: Colors.black26,
          ), // Sombra
        ],
      ),
    );
    textPainter.layout();

    // Ajustamos la posición:
    // - Si es una chincheta (location_on), el punto (x,y) es la punta de abajo.
    // - Si es un icono redondo (wc, cafe), el punto (x,y) es el centro.
    double offsetX = x - textPainter.width / 2;
    double offsetY = y - textPainter.height / 2;

    if (iconData == Icons.location_on || iconData == Icons.directions_walk) {
      offsetY = y - textPainter.height; // Apoyar los pies en el punto
    }

    textPainter.paint(canvas, Offset(offsetX, offsetY));
  }

  @override
  bool shouldRepaint(covariant GrafoPainter old) => true;
}

// menu.dart
class Menu {
  final int id;
  final String nombre;
  final double precio;

  Menu({required this.id, required this.nombre, required this.precio});

  factory Menu.fromJson(Map<String, dynamic> json) {
    return Menu(
      id: json['id'],
      nombre: json['nombre'],
      precio: (json['precio'] as num).toDouble(),
    );
  }
}
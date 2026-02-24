import 'package:flutter/material.dart';
import 'package:gestioncomida_front/services/menu_service.dart';
import 'models/menu.dart';

void main() => runApp(GestionComidaApp());

class GestionComidaApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gestión Comida',
      home: MenuPage(),
    );
  }
}

class MenuPage extends StatefulWidget {
  @override
  _MenuPageState createState() => _MenuPageState();
}

class _MenuPageState extends State<MenuPage> {
  late Future<List<Menu>> menus;

  @override
  void initState() {
    super.initState();
    menus = MenuService().fetchMenus();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Menús Disponibles')),
      body: FutureBuilder<List<Menu>>(
        future: menus,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('No hay menús disponibles'));
          } else {
            return ListView.builder(
              itemCount: snapshot.data!.length,
              itemBuilder: (context, index) {
                final menu = snapshot.data![index];
                return ListTile(
                  title: Text(menu.nombre),
                  subtitle: Text('Precio: \$${menu.precio.toStringAsFixed(2)}'),
                );
              },
            );
          }
        },
      ),
    );
  }
}
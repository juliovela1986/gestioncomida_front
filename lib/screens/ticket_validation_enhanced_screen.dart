import 'package:flutter/material.dart';
import '../services/ticket_service.dart';
import '../services/location_service.dart';
import '../models/ticket.dart';
import '../models/location.dart';

class TicketValidationEnhancedScreen extends StatefulWidget {
  final String ticketId;
  final Function()? onValidated;

  const TicketValidationEnhancedScreen({
    super.key,
    required this.ticketId,
    this.onValidated,
  });

  @override
  State<TicketValidationEnhancedScreen> createState() =>
      _TicketValidationEnhancedScreenState();
}

class _TicketValidationEnhancedScreenState
    extends State<TicketValidationEnhancedScreen> {
  final TicketService _ticketService = TicketService();
  final LocationService _locationService = LocationService();

  late Future<TicketResponseDto> _ticketFuture;
  late Future<List<LocationResponseDto>> _locationsFuture;

  String? _selectedLocationId;
  bool _isValidating = false;

  @override
  void initState() {
    super.initState();
    _ticketFuture = _ticketService.getTicketById(widget.ticketId);
    _locationsFuture = _locationService.getUserLocations();
  }

  Future<void> _validateAndSync() async {
    setState(() => _isValidating = true);

    try {
      // Primero validamos el ticket
      await _ticketService.validateTicket(widget.ticketId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Ticket validado correctamente')),
        );
      }

      // Luego sincronizamos con ubicación si se seleccionó
      if (_selectedLocationId != null) {
        await _ticketService.syncTicketInventory(
          widget.ticketId,
          locationId: _selectedLocationId,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('✅ Sincronizado con inventario')),
          );
        }
      }

      widget.onValidated?.call();

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Error: $e')),
        );
      }
    } finally {
      setState(() => _isValidating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('✅ Validar Ticket'),
      ),
      body: FutureBuilder<TicketResponseDto>(
        future: _ticketFuture,
        builder: (context, ticketSnapshot) {
          if (ticketSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (ticketSnapshot.hasError) {
            return Center(child: Text('Error: ${ticketSnapshot.error}'));
          }

          if (!ticketSnapshot.hasData) {
            return const Center(child: Text('Ticket no encontrado'));
          }

          final ticket = ticketSnapshot.data!;

          return FutureBuilder<List<LocationResponseDto>>(
            future: _locationsFuture,
            builder: (context, locationsSnapshot) {
              if (locationsSnapshot.connectionState ==
                  ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final locations = locationsSnapshot.data ?? [];

              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Información del ticket
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            ticket.supermarketName ?? 'Supermercado',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Fecha: ${ticket.purchaseDatetime}',
                            style: const TextStyle(color: Colors.grey),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${ticket.lines?.length ?? 0} productos',
                            style: const TextStyle(fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Listado de líneas
                  const Text(
                    'Líneas de compra:',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  if (ticket.lines != null && ticket.lines!.isNotEmpty)
                    ...ticket.lines!.map(
                      (line) => Card(
                        child: ListTile(
                          title: Text(line.productName ?? 'Sin nombre'),
                          subtitle: Text(
                            'Qty: ${line.quantity} | Precio: ${line.price}€',
                          ),
                          trailing: Text(
                            '${line.lineTotal}€',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    )
                  else
                    const Text('Sin líneas'),

                  const SizedBox(height: 24),

                  // Seleccionar ubicación para sincronización
                  const Text(
                    'Ubicación de destino (opcional):',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  DropdownButton<String>(
                    isExpanded: true,
                    hint: const Text('Selecciona una ubicación'),
                    value: _selectedLocationId,
                    items: [
                      const DropdownMenuItem(
                        value: null,
                        child: Text('Sin ubicación específica'),
                      ),
                      ...locations.map(
                        (loc) => DropdownMenuItem(
                          value: loc.id,
                          child: Text(loc.name),
                        ),
                      ),
                    ],
                    onChanged: (value) {
                      setState(() => _selectedLocationId = value);
                    },
                  ),

                  const SizedBox(height: 32),

                  // Botón validar
                  ElevatedButton(
                    onPressed:
                        _isValidating ? null : _validateAndSync,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: _isValidating
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            '✅ Validar y Sincronizar',
                            style: TextStyle(fontSize: 16),
                          ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}


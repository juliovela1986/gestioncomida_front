import 'package:dio/dio.dart';
import 'api_client.dart';
import '../models/ticket.dart';
import '../models/expiration_management_response.dart';
import 'auth_service.dart';

class TicketService {
  final ApiClient _apiClient = ApiClient();
  final AuthService _authService = AuthService();

  Future<Response> getTickets({int page = 0, int size = 20}) async {
    try {
      final response = await _apiClient.dio.get(
        '/api/tickets',
        queryParameters: {
          'page': page,
          'size': size,
        },
      );
      return response;
    } catch (e) {
      print('Error al obtener tickets: $e');
      rethrow;
    }
  }

  Future<TicketResponseDto> getTicketById(String ticketId) async {
    print('[TicketService] 🔵 getTicketById llamado con ID: $ticketId');
    print('[TicketService] 🌐 Haciendo GET a: /api/tickets/$ticketId');
    final response = await _apiClient.dio.get('/api/tickets/$ticketId');
    print('[TicketService] ✅ Respuesta recibida: ${response.statusCode}');
    print('[TicketService] 📦 Data: ${response.data}');
    return TicketResponseDto.fromJson(response.data);
  }

  Future<void> syncTicketInventory(String ticketId) async {
    await _apiClient.dio.post('/api/tickets/$ticketId/sync-inventory');
  }

  Future<ExpirationManagementResponse> getExpirationManagement(String ticketId) async {
    print('[TicketService] 🔵 getExpirationManagement llamado con ID: $ticketId');
    final response = await _apiClient.dio.get('/api/tickets/$ticketId/expiration-management');
    print('[TicketService] ✅ Respuesta raw: ${response.data}');
    return ExpirationManagementResponse.fromJson(response.data);
  }

  Future<void> assignExpirationDates(String ticketId, List<Map<String, String>> assignments) async {
    await _apiClient.dio.post('/api/tickets/$ticketId/assign-expiration-dates', data: assignments);
  }

  Future<TicketResponseDto> updateTicket(String ticketId, Map<String, dynamic> data) async {
    print('[TicketService] 🔵 updateTicket llamado con ID: $ticketId');
    print('[TicketService] 📝 Data a enviar: $data');
    await _apiClient.dio.put('/api/tickets/$ticketId', data: data);
    print('[TicketService] ✅ PUT exitoso, obteniendo ticket actualizado...');
    
    // Obtener el ticket actualizado con las líneas
    final updatedTicket = await getTicketById(ticketId);
    return updatedTicket;
  }

  Future<void> deleteTicket(String ticketId) async {
    await _apiClient.dio.delete('/api/tickets/$ticketId');
  }

  Future<void> deleteTicketLine(String ticketId, String lineId) async {
    print('[TicketService] 🗑️ deleteTicketLine llamado - Ticket: $ticketId, Line: $lineId');
    await _apiClient.dio.delete('/api/tickets/$ticketId/lines/$lineId');
    print('[TicketService] ✅ Línea eliminada exitosamente');
  }

  Future<TicketResponseDto> addTicketLine(String ticketId, Map<String, dynamic> lineData) async {
    print('[TicketService] ➕ addTicketLine llamado - Ticket: $ticketId');
    print('[TicketService] 📝 Data: $lineData');
    await _apiClient.dio.post('/api/tickets/$ticketId/lines', data: lineData);
    print('[TicketService] ✅ Línea añadida, obteniendo ticket actualizado...');
    return await getTicketById(ticketId);
  }

  Future<Response> uploadTicket(FormData formData) async {
    try {
      return await _apiClient.dio.post('/api/tickets/upload', data: formData);
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        print('[TicketService] ⚠️ Token expirado, refrescando...');
        final newToken = await _authService.refreshToken();
        if (newToken != null) {
          print('[TicketService] ✅ Token refrescado, pero FormData no se puede reusar');
          throw Exception('Token expirado. Por favor, intenta de nuevo.');
        }
      }
      rethrow;
    }
  }

  // MOCK: Obtener tickets recientes (simulado localmente)
  Future<List<Map<String, dynamic>>> getRecentTicketsMock() async {
    // TODO: Cuando exista el endpoint, usar: await _apiClient.dio.get('/api/tickets')
    // Por ahora retornamos datos mockeados
    await Future.delayed(const Duration(milliseconds: 500));
    return [
      {
        'id': 'mock-1',
        'supermarketName': 'LIDL',
        'purchaseDatetime': '2024-12-27 11:52',
        'lineCount': 8,
        'total': '19.81',
        'synced': true,
      },
      {
        'id': 'mock-2',
        'supermarketName': 'Mercadona',
        'purchaseDatetime': '2024-12-26 18:30',
        'lineCount': 5,
        'total': '12.45',
        'synced': false,
      },
    ];
  }
}

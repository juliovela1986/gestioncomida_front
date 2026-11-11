import 'package:dio/dio.dart';
import 'api_client.dart';
import '../core/app_logger.dart';
import '../models/ticket.dart';
import '../models/expiration_management_response.dart';
import '../models/ticket_manual_create.dart';

class TicketService {
  final ApiClient _apiClient = ApiClient();

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
      AppLogger.error('Error al obtener tickets', e);
      rethrow;
    }
  }

  Future<TicketResponseDto> getTicketById(String ticketId) async {
    AppLogger.debug('getTicketById', ticketId);
    final response = await _apiClient.dio.get('/api/tickets/$ticketId');
    AppLogger.debug('getTicketById status', response.statusCode);
    // Payload OCR/rawText solo en debug — nunca en release (SCRUM-122).
    AppLogger.debug('getTicketById payload', response.data);
    return TicketResponseDto.fromJson(response.data);
  }

  Future<void> syncTicketInventory(String ticketId, {String? locationId}) async {
    final queryParams = <String, dynamic>{};
    if (locationId != null) {
      queryParams['locationId'] = locationId;
    }

    await _apiClient.dio.post(
      '/api/tickets/$ticketId/sync-inventory',
      queryParameters: queryParams.isNotEmpty ? queryParams : null,
    );
  }

  Future<ExpirationManagementResponse> getExpirationManagement(String ticketId) async {
    AppLogger.debug('getExpirationManagement', ticketId);
    final response = await _apiClient.dio.get('/api/tickets/$ticketId/expiration-management');
    AppLogger.debug('getExpirationManagement payload', response.data);
    return ExpirationManagementResponse.fromJson(response.data);
  }

  Future<void> assignExpirationDates(String ticketId, List<Map<String, String>> assignments) async {
    await _apiClient.dio.post('/api/tickets/$ticketId/assign-expiration-dates', data: assignments);
  }

  Future<TicketResponseDto> createManualTicket(TicketManualCreateRequest request) async {
    final response = await _apiClient.dio.post('/api/tickets/manual', data: request.toJson());
    return TicketResponseDto.fromJson(response.data);
  }

  Future<TicketResponseDto> updateTicket(String ticketId, Map<String, dynamic> data) async {
    AppLogger.debug('updateTicket', {'id': ticketId, 'data': data});
    await _apiClient.dio.put('/api/tickets/$ticketId', data: data);
    return await getTicketById(ticketId);
  }

  Future<void> deleteTicket(String ticketId) async {
    await _apiClient.dio.delete('/api/tickets/$ticketId');
  }

  Future<void> deleteTicketLine(String ticketId, String lineId) async {
    AppLogger.debug('deleteTicketLine', {'ticket': ticketId, 'line': lineId});
    await _apiClient.dio.delete('/api/tickets/$ticketId/lines/$lineId');
  }

  Future<TicketResponseDto> addTicketLine(String ticketId, Map<String, dynamic> lineData) async {
    AppLogger.debug('addTicketLine', {'ticket': ticketId, 'data': lineData});
    await _apiClient.dio.post('/api/tickets/$ticketId/lines', data: lineData);
    return await getTicketById(ticketId);
  }

  Future<Response> uploadTicket(FormData formData) async {
    return await _apiClient.dio.post('/api/tickets/upload', data: formData);
  }

  Future<TicketResponseDto> validateTicket(String ticketId) async {
    AppLogger.debug('validateTicket', ticketId);
    final response = await _apiClient.dio.post('/api/tickets/$ticketId/validate');
    return TicketResponseDto.fromJson(response.data);
  }

  Future<void> updateTicketLine(String ticketId, String lineId, Map<String, dynamic> data) async {
    AppLogger.debug('updateTicketLine', {'ticket': ticketId, 'line': lineId});
    await _apiClient.dio.put('/api/tickets/$ticketId/lines/$lineId', data: data);
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
        'supermarketName': 'MERCADONA',
        'purchaseDatetime': '2024-12-26 18:30',
        'lineCount': 12,
        'total': '45.20',
        'synced': false,
      },
    ];
  }
}

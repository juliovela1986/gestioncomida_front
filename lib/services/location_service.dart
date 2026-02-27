import 'package:dio/dio.dart';
import 'api_client.dart';
import '../models/location.dart';

class LocationService {
  final ApiClient _apiClient = ApiClient();

  Future<List<LocationResponseDto>> getUserLocations() async {
    final response = await _apiClient.dio.get('/api/locations');
    return (response.data as List).map((e) => LocationResponseDto.fromJson(e)).toList();
  }

  Future<LocationResponseDto> getLocationById(String id) async {
    final response = await _apiClient.dio.get('/api/locations/$id');
    return LocationResponseDto.fromJson(response.data);
  }

  Future<LocationResponseDto> createLocation(LocationDto location) async {
    final response = await _apiClient.dio.post('/api/locations', data: location.toJson());
    return LocationResponseDto.fromJson(response.data);
  }

  Future<LocationResponseDto> updateLocation(String id, LocationDto location) async {
    final response = await _apiClient.dio.put('/api/locations/$id', data: location.toJson());
    return LocationResponseDto.fromJson(response.data);
  }

  Future<void> deleteLocation(String id) async {
    await _apiClient.dio.delete('/api/locations/$id');
  }

  Future<LocationResponseDto> getByName(String name) async {
    final response = await _apiClient.dio.get('/api/locations/by-name', queryParameters: {'name': name});
    return LocationResponseDto.fromJson(response.data);
  }
}

import 'api_client.dart';

class AccountDeletionResult {
  final bool appDataDeleted;
  final bool authAccountDeleted;
  final String message;

  const AccountDeletionResult({
    required this.appDataDeleted,
    required this.authAccountDeleted,
    required this.message,
  });

  factory AccountDeletionResult.fromJson(Map<String, dynamic> json) {
    return AccountDeletionResult(
      appDataDeleted: json['appDataDeleted'] == true,
      authAccountDeleted: json['authAccountDeleted'] == true,
      message: (json['message'] as String?) ?? '',
    );
  }
}

class AccountService {
  final ApiClient _apiClient = ApiClient();

  /// SCRUM-141 — Play User Data: borra cuenta/datos del usuario autenticado.
  Future<AccountDeletionResult> deleteMyAccount() async {
    final response = await _apiClient.dio.delete('/api/users/me');
    final data = response.data;
    if (data is Map<String, dynamic>) {
      return AccountDeletionResult.fromJson(data);
    }
    return const AccountDeletionResult(
      appDataDeleted: true,
      authAccountDeleted: false,
      message: '',
    );
  }
}

class ServerException implements Exception {
  final String message;
  const ServerException({required this.message});
}

class NetworkException implements Exception {
  const NetworkException();
}

class AuthException implements Exception {
  final String message;
  const AuthException({required this.message});
}

class CacheException implements Exception {
  const CacheException();
}

class NotFoundException implements Exception {
  const NotFoundException();
}

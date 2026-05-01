import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/errors/exceptions.dart' as app_exc;
import '../../../../core/utils/logger.dart';
import '../../domain/entities/user_entity.dart';
import '../models/user_model.dart';

abstract class AuthRemoteDataSource {
  Future<UserModel> signInWithEmail(String email, String password);
  Future<UserModel> signUpWithEmail({
    required String email,
    required String password,
    required String fullName,
    required String phone,
    required String role,
  });
  Future<void> signOut();
  Future<UserModel> getCurrentUser();
  Future<void> verifyOtp(String email, String token);
  Future<void> updateFcmToken(String userId, String fcmToken);
  Stream<UserModel?> get authStateChanges;
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final SupabaseClient _client;

  AuthRemoteDataSourceImpl(this._client);

  @override
  Future<UserModel> signInWithEmail(String email, String password) async {
    try {
      final response = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      if (response.user == null) {
        throw const app_exc.AuthException(message: 'Login gagal. Periksa email dan password.');
      }
      return _fetchProfile(response.user!);
    } on AuthException catch (e) {
      throw app_exc.AuthException(message: e.message);
    } catch (e, st) {
      AppLogger.error('signInWithEmail', error: e, stackTrace: st);
      throw app_exc.AuthException(message: e.toString());
    }
  }

  @override
  Future<UserModel> signUpWithEmail({
    required String email,
    required String password,
    required String fullName,
    required String phone,
    required String role,
  }) async {
    try {
      final response = await _client.auth.signUp(
        email: email,
        password: password,
      );
      if (response.user == null) {
        throw const app_exc.AuthException(message: 'Registrasi gagal.');
      }
      
      // Insert into account table
      await _client.from('account').insert({
        'nama_account': fullName,
        'email': email,
        'no_hp': phone,
        'alamat': '', // Default empty address
        'role': role, // Store the role
      });

      return UserModel(
        id: response.user!.id,
        email: email,
        fullName: fullName,
        phone: phone,
        role: UserRoleExtension.fromString(role),
        createdAt: DateTime.now(),
      );
    } on AuthException catch (e) {
      throw app_exc.AuthException(message: e.message);
    } catch (e, st) {
      AppLogger.error('signUpWithEmail', error: e, stackTrace: st);
      throw app_exc.AuthException(message: e.toString());
    }
  }

  @override
  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  @override
  Future<UserModel> getCurrentUser() async {
    final user = _client.auth.currentUser;
    if (user == null) throw const app_exc.AuthException(message: 'Tidak ada sesi aktif');
    return _fetchProfile(user);
  }

  @override
  Future<void> verifyOtp(String email, String token) async {
    await _client.auth.verifyOTP(
      email: email,
      token: token,
      type: OtpType.signup,
    );
  }

  @override
  Future<void> updateFcmToken(String userId, String fcmToken) async {
    // Currently ignored since pelanggan doesn't have fcm_token in the new schema
    // await _client.from('pelanggan').update({'fcm_token': fcmToken}).eq('id_pelanggan', userId);
  }

  @override
  Stream<UserModel?> get authStateChanges {
    return _client.auth.onAuthStateChange.asyncMap((event) async {
      if (event.session == null) return null;
      try {
        return await _fetchProfile(event.session!.user);
      } catch (_) {
        return null;
      }
    });
  }

  Future<UserModel> _fetchProfile(User user) async {
    // Coba cari berdasarkan email (kolom unik di tabel account)
    final data = await _client
        .from('account')
        .select()
        .eq('email', user.email!)
        .maybeSingle();
        
    if (data == null) {
      // Data profil tidak ditemukan — log untuk debugging
      AppLogger.error(
        '_fetchProfile',
        error: 'Profil tidak ditemukan untuk email: ${user.email}. '
            'Pastikan data sudah ada di tabel public.account.',
      );
      // Throw agar tidak silently fallback ke role consumer
      throw app_exc.AuthException(
        message: 'Data akun tidak ditemukan. Hubungi admin atau daftar ulang.',
      );
    }

    AppLogger.error('_fetchProfile', error: 'Role terbaca: ${data['role']}');

    return UserModel(
      id: data['id_pelanggan'].toString(),
      email: data['email'],
      fullName: data['nama_account'],
      phone: data['no_hp'] ?? '',
      role: UserRoleExtension.fromString(data['role'] ?? 'consumer'),
      createdAt: data['created_at'] != null
          ? DateTime.parse(data['created_at'])
          : DateTime.now(),
    );
  }
}

import 'package:common/auth/tokens/refresh_token.dart';
import 'package:server/auth/models/refresh_token_db.dart';
import 'package:server/auth/models/user_db.dart';

abstract interface class IAuthDataSource {
  Future<void> deleteRefreshToken(RefreshToken token);
  Future<RefreshTokenDB> getRefreshToken(RefreshToken token);
  Future<RefreshTokenDB> storeRefreshToken({
    required int userId,
    required String? userAgent,
    required String? ipAddress,
  });
  Future<UserDB> login(String username);
  Future<UserDB> register(String username, String hashedPassword, String salt);
  Future<bool> isUniqueUsername(String username);
  Future<RefreshTokenDB> rotateRefreshToken(
    RefreshToken oldToken,
    int userId, {
    String? ipAddress,
    String? userAgent,
  });
  Future<void> revokeAllUserTokens(int userId, {String? reason});
}

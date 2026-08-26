import 'package:araguaney_app/core/api/api_failure.dart';
import 'package:araguaney_app/core/api/generated/models/token.dart';
import 'package:araguaney_app/core/api/generated/models/user_out.dart';
import 'package:araguaney_app/core/auth/auth_repository.dart';
import 'package:araguaney_app/core/auth/token_storage.dart';
import 'package:dio/dio.dart';

/// A read-model wipe that only counts how many times it was called.
class FakeReadModelReset {
  int count = 0;

  Future<void> call() async => count++;
}

/// In-memory storage that records what was asked of it.
class FakeTokenStorage implements TokenStorage {
  FakeTokenStorage({this.stored, this.storedUserId});

  String? stored;
  String? storedUserId;
  int clearCount = 0;
  final List<String> written = [];

  @override
  Future<String?> readRefreshToken() async => stored;

  @override
  Future<void> writeRefreshToken(String token) async {
    stored = token;
    written.add(token);
  }

  @override
  Future<String?> readUserId() async => storedUserId;

  @override
  Future<void> writeUserId(String? userId) async => storedUserId = userId;

  @override
  Future<void> clear() async {
    stored = null;
    storedUserId = null;
    clearCount++;
  }
}

/// A fake repository.
///
/// It extends the real one instead of imitating an interface so the signature
/// cannot diverge in silence: if the repository changes, this stops compiling.
class FakeAuthRepository extends AuthRepository {
  FakeAuthRepository({
    this.loginResult,
    this.loginError,
    this.refreshToken,
    this.refreshError,
    this.totpToken,
    this.totpError,
    this.changePasswordToken,
  }) : super(Dio());

  LoginResult? loginResult;
  ApiFailure? loginError;
  Token? refreshToken;
  ApiFailure? refreshError;
  Token? totpToken;
  ApiFailure? totpError;
  Token? changePasswordToken;

  /// Who answers `GET /v1/auth/me`. Null with [meError] set simulates an
  /// identity that could not be confirmed.
  String meUserId = 'user-1';

  /// The role that answers `GET /v1/auth/me`. It is the one the application
  /// uses when the token does not carry it, which is what happens on renewal.
  String meCenterRole = 'volunteer';
  ApiFailure? meError;
  int meCount = 0;

  int refreshCount = 0;
  int logoutCount = 0;
  String? lastRefreshTokenUsed;
  String? lastLogoutRefreshToken;

  @override
  Future<LoginResult> login({
    required String username,
    required String password,
  }) async {
    if (loginError case final error?) throw error;
    return loginResult!;
  }

  @override
  Future<Token> totpChallenge({
    required String partialToken,
    required String code,
  }) async {
    if (totpError case final error?) throw error;
    return totpToken!;
  }

  @override
  Future<UserOut> me(String accessToken) async {
    meCount++;
    if (meError case final error?) throw error;
    return UserOut(
      id: meUserId,
      email: 'persona@centro.test',
      role: 'user',
      username: 'persona',
      isActive: true,
      mustAcceptTerms: false,
      totpEnabled: false,
      avatarUrl: null,
      centerId: 'center-1',
      centerRole: meCenterRole,
      countryCode: 'VE',
      fullName: 'Persona de prueba',
    );
  }

  @override
  Future<Token> refresh(String refreshTokenValue) async {
    refreshCount++;
    lastRefreshTokenUsed = refreshTokenValue;
    if (refreshError case final error?) throw error;
    return refreshToken!;
  }

  @override
  Future<Token> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async => changePasswordToken!;

  @override
  Future<void> logout(String? refreshTokenValue) async {
    logoutCount++;
    lastLogoutRefreshToken = refreshTokenValue;
  }
}

Token buildToken({
  String access = 'access-1',
  String? refresh = 'refresh-1',
  bool mustChangePassword = false,
  String? centerRole = 'volunteer',
}) => Token(
  accessToken: access,
  refreshToken: refresh,
  mustChangePassword: mustChangePassword,
  centerRole: centerRole,
  role: 'user',
);

const unauthorized = UnauthorizedFailure(
  code: 'INVALID_REFRESH',
  message: 'revocado',
);

const wrongCode = BusinessRuleFailure(
  code: 'INVALID_TOTP',
  message: 'El código no es válido',
);

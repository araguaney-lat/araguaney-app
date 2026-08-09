// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../models/accept_terms_request.dart';
import '../models/avatar_out.dart';
import '../models/body_login_v1_auth_login_post.dart';
import '../models/change_password_request.dart';
import '../models/delete_account_request.dart';
import '../models/forgot_password_request.dart';
import '../models/logout_request.dart';
import '../models/refresh_request.dart';
import '../models/resend_request.dart';
import '../models/reset_password_request.dart';
import '../models/token.dart';
import '../models/totp_challenge_in.dart';
import '../models/totp_confirm_in.dart';
import '../models/totp_confirm_out.dart';
import '../models/totp_setup_out.dart';
import '../models/user_create.dart';
import '../models/user_out.dart';
import '../models/user_profile_out.dart';
import '../models/user_update.dart';

part 'auth_api.g.dart';

@RestApi()
abstract class AuthApi {
  factory AuthApi(Dio dio, {String? baseUrl}) = _AuthApi;

  /// Forgot Password
  @POST('/v1/auth/forgot-password')
  Future<void> forgotPasswordV1AuthForgotPasswordPost({
    @Body() required ForgotPasswordRequest body,
  });

  /// Login
  @FormUrlEncoded()
  @POST('/v1/auth/login')
  Future<void> loginV1AuthLoginPost({
    @Body() required BodyLoginV1AuthLoginPost body,
  });

  /// Logout
  @POST('/v1/auth/logout')
  Future<void> logoutV1AuthLogoutPost({@Body() LogoutRequest? body});

  /// Delete Own Account.
  ///
  /// Self-service ARCO cancellation: anonymizes the account, keeps traceability.
  ///
  /// The user row survives as an opaque id because audit events must remain.
  /// attributable; every personal field is destroyed. See.
  /// AccountDeletionService for the full field map.
  @DELETE('/v1/auth/me')
  Future<void> deleteOwnAccountV1AuthMeDelete({
    @Body() required DeleteAccountRequest body,
  });

  /// Get Me
  @GET('/v1/auth/me')
  Future<UserOut> getMeV1AuthMeGet();

  /// Update Me
  @PATCH('/v1/auth/me')
  Future<UserOut> updateMeV1AuthMePatch({@Body() required UserUpdate body});

  /// Accept Terms
  @POST('/v1/auth/me/accept-terms')
  Future<void> acceptTermsV1AuthMeAcceptTermsPost({
    @Body() required AcceptTermsRequest body,
  });

  /// Upload My Avatar
  @MultiPart()
  @POST('/v1/auth/me/avatar')
  Future<AvatarOut> uploadMyAvatarV1AuthMeAvatarPost({
    @Part(name: 'file') required String file,
  });

  /// Change Password
  @PATCH('/v1/auth/me/password')
  Future<Token> changePasswordV1AuthMePasswordPatch({
    @Body() required ChangePasswordRequest body,
  });

  /// Get My Profile
  @GET('/v1/auth/me/profile')
  Future<UserProfileOut> getMyProfileV1AuthMeProfileGet();

  /// Refresh.
  ///
  /// Renueva el access token a partir de un refresh válido, rotándolo.
  ///
  /// Anónimo por diseño: el access ya venció y el refresh es la única credencial.
  /// Se limita por IP (no hay sesión que keyear) y el propio token detecta reuso.
  @POST('/v1/auth/refresh')
  Future<Token> refreshV1AuthRefreshPost({
    @Body() required RefreshRequest body,
  });

  /// Register
  @POST('/v1/auth/register')
  Future<void> registerV1AuthRegisterPost({@Body() required UserCreate body});

  /// Resend Verification
  @POST('/v1/auth/resend-verification')
  Future<void> resendVerificationV1AuthResendVerificationPost({
    @Body() required ResendRequest body,
  });

  /// Reset Password
  @POST('/v1/auth/reset-password')
  Future<void> resetPasswordV1AuthResetPasswordPost({
    @Body() required ResetPasswordRequest body,
  });

  /// Totp Challenge.
  ///
  /// Second step of login when 2FA is enabled. Exchanges partial token + code for full token.
  @POST('/v1/auth/totp/challenge')
  Future<Token> totpChallengeV1AuthTotpChallengePost({
    @Body() required TotpChallengeIn body,
  });

  /// Totp Confirm.
  ///
  /// Verify TOTP code and enable 2FA. Returns one-time backup codes.
  @POST('/v1/auth/totp/confirm')
  Future<TotpConfirmOut> totpConfirmV1AuthTotpConfirmPost({
    @Body() required TotpConfirmIn body,
  });

  /// Totp Disable.
  ///
  /// Disable 2FA using a valid TOTP code or backup code.
  @POST('/v1/auth/totp/disable')
  Future<void> totpDisableV1AuthTotpDisablePost({
    @Body() required TotpConfirmIn body,
  });

  /// Totp Setup.
  ///
  /// Generate a new TOTP secret for the current user. Call /totp/confirm to activate.
  @POST('/v1/auth/totp/setup')
  Future<TotpSetupOut> totpSetupV1AuthTotpSetupPost();

  /// Verify Email
  @GET('/v1/auth/verify-email')
  Future<void> verifyEmailV1AuthVerifyEmailGet({
    @Query('token') required String token,
  });
}

// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../models/donation_create.dart';
import '../models/donation_out.dart';
import '../models/donation_photo_out.dart';
import '../models/donation_public_out.dart';
import '../models/email_in.dart';
import '../models/items_in.dart';
import '../models/ok_out.dart';
import '../models/photo_confirm_in.dart';
import '../models/photo_upload_url_in.dart';
import '../models/photo_upload_url_out.dart';
import '../models/product_type_out.dart';
import '../models/public_center_out.dart';
import '../models/receive_in.dart';
import '../models/signed_url_out.dart';
import '../models/token_in.dart';

part 'donations_api.g.dart';

@RestApi()
abstract class DonationsApi {
  factory DonationsApi(Dio dio, {String? baseUrl}) = _DonationsApi;

  /// Public Donation.
  ///
  /// Lo que ve quien escanea: estado y contenido, sin un solo dato del donante.
  @GET('/v1/d/{code}')
  Future<DonationPublicOut> publicDonationV1DCodeGet({
    @Path('code') required String code,
  });

  /// Public Donation Qr
  @GET('/v1/d/{code}/qr.png')
  @DioResponseType(ResponseType.stream)
  Stream<String> publicDonationQrV1DCodeQrPngGet({
    @Path('code') required String code,
  });

  /// List Donations.
  ///
  /// `incoming=true` da las que vienen en camino a mi centro; si no, las recibidas.
  @GET('/v1/donations')
  Future<List<DonationOut>> listDonationsV1DonationsGet({
    @Query('incoming') bool? incoming = false,
  });

  /// Get Donation.
  ///
  /// Detalle para el doble check. Cualquier centro puede abrir un código:.
  /// el QR no está atado al centro que el donante eligió.
  @GET('/v1/donations/{code}')
  Future<DonationOut> getDonationV1DonationsCodeGet({
    @Path('code') required String code,
  });

  /// Read Label.
  ///
  /// Lee la etiqueta de una foto y devuelve los campos que logró leer.
  ///
  /// Los campos llegan como **sugerencia**: quien captura los confirma o los.
  /// corrige antes de que la caja se selle. La caducidad sigue pasando por la.
  /// validación de vida útil, así que una lectura optimista no puede colar una.
  /// caja que debía rechazarse.
  ///
  /// Diccionario vacío si la capacidad está apagada, sin presupuesto o el.
  /// proveedor no responde: se teclea como siempre.
  @POST('/v1/donations/{code}/photos/{photo_id}/read-label')
  Future<dynamic> readLabelV1DonationsCodePhotosPhotoIdReadLabelPost({
    @Path('code') required String code,
    @Path('photo_id') required String photoId,
  });

  /// Center Photo Url.
  ///
  /// El centro ve las fotos al preparar el doble check.
  @GET('/v1/donations/{code}/photos/{photo_id}/url')
  Future<SignedUrlOut> centerPhotoUrlV1DonationsCodePhotosPhotoIdUrlGet({
    @Path('code') required String code,
    @Path('photo_id') required String photoId,
  });

  /// Receive Donation
  @POST('/v1/donations/{code}/receive')
  Future<DonationOut> receiveDonationV1DonationsCodeReceivePost({
    @Path('code') required String code,
    @Body() required ReceiveIn body,
  });

  /// Suggest Catalog Matches.
  ///
  /// Hasta tres productos sugeridos para un renglón de texto libre del donante.
  ///
  /// Autenticada y con rate limit, como toda la IA de la fase. Devuelve lista.
  /// vacía si la capacidad está apagada, sin presupuesto o el proveedor no.
  /// responde: la captura manual nunca depende de que la IA esté disponible.
  @GET('/v1/donations/{code}/suggestions')
  Future<List<ProductTypeOut>>
  suggestCatalogMatchesV1DonationsCodeSuggestionsGet({
    @Path('code') required String code,
    @Query('text') required String text,
  });

  /// Public Centers.
  ///
  /// Centros activos, sin datos de contacto. Cacheable: cambia poco.
  @GET('/v1/public/centers')
  Future<List<PublicCenterOut>> publicCentersV1PublicCentersGet();

  /// Submit Donation.
  ///
  /// Registra la donación en PENDING_EMAIL y manda el correo de confirmación.
  ///
  /// Responde lo mismo si ese correo ya tenía una donación abierta: el código de.
  /// la donación viaja por correo, nunca en esta respuesta, para que probar.
  /// direcciones ajenas no diga nada de quién está donando.
  @POST('/v1/public/donations')
  Future<OkOut> submitDonationV1PublicDonationsPost({
    @Body() required DonationCreate body,
  });

  /// Confirm Donation.
  ///
  /// Confirma el correo: la donación pasa a REGISTERED y se emite el QR.
  @POST('/v1/public/donations/confirm')
  Future<DonationOut> confirmDonationV1PublicDonationsConfirmPost({
    @Body() required TokenIn body,
  });

  /// Get Managed Donation
  @GET('/v1/public/donations/manage/{token}')
  Future<DonationOut> getManagedDonationV1PublicDonationsManageTokenGet({
    @Path('token') required String token,
  });

  /// Cancel Managed Donation
  @POST('/v1/public/donations/manage/{token}/cancel')
  Future<DonationOut>
  cancelManagedDonationV1PublicDonationsManageTokenCancelPost({
    @Path('token') required String token,
  });

  /// Update Managed Items
  @PUT('/v1/public/donations/manage/{token}/items')
  Future<DonationOut> updateManagedItemsV1PublicDonationsManageTokenItemsPut({
    @Path('token') required String token,
    @Body() required ItemsIn body,
  });

  /// Confirm Photo
  @POST('/v1/public/donations/manage/{token}/photos')
  Future<DonationPhotoOut> confirmPhotoV1PublicDonationsManageTokenPhotosPost({
    @Path('token') required String token,
    @Body() required PhotoConfirmIn body,
  });

  /// Photo Upload Url.
  ///
  /// URL firmada para subir directo a R2. La llave la arma el servidor.
  @POST('/v1/public/donations/manage/{token}/photos/upload-url')
  Future<PhotoUploadUrlOut>
  photoUploadUrlV1PublicDonationsManageTokenPhotosUploadUrlPost({
    @Path('token') required String token,
    @Body() required PhotoUploadUrlIn body,
  });

  /// Delete Photo
  @DELETE('/v1/public/donations/manage/{token}/photos/{photo_id}')
  Future<void> deletePhotoV1PublicDonationsManageTokenPhotosPhotoIdDelete({
    @Path('token') required String token,
    @Path('photo_id') required String photoId,
  });

  /// Donor Photo Url
  @GET('/v1/public/donations/manage/{token}/photos/{photo_id}/url')
  Future<SignedUrlOut>
  donorPhotoUrlV1PublicDonationsManageTokenPhotosPhotoIdUrlGet({
    @Path('token') required String token,
    @Path('photo_id') required String photoId,
  });

  /// Resend Donation Confirmation.
  ///
  /// Reenvía la confirmación rotando el token.
  ///
  /// Responde 202 siempre, exista o no una donación con ese correo: distinguir.
  /// convertiría al endpoint en un verificador de direcciones.
  @POST('/v1/public/donations/resend')
  Future<OkOut> resendDonationConfirmationV1PublicDonationsResendPost({
    @Body() required EmailIn body,
  });
}

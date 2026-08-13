// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../models/device_token_register.dart';
import '../models/device_token_unregister.dart';
import '../models/ok_out.dart';

part 'devices_api.g.dart';

@RestApi()
abstract class DevicesApi {
  factory DevicesApi(Dio dio, {String? baseUrl}) = _DevicesApi;

  /// Register Device.
  ///
  /// Registra dónde entregar los avisos de quien tiene la sesión.
  @POST('/v1/devices')
  Future<OkOut> registerDeviceV1DevicesPost({
    @Body() required DeviceTokenRegister body,
  });

  /// Unregister Device.
  ///
  /// Da de baja un destino. La aplicación la llama al cerrar sesión.
  ///
  /// Responde igual exista el token o no. Decir "ese token no era tuyo" le.
  /// contaría a quien pregunta si un token ajeno está registrado, y no le sirve.
  /// de nada a un cliente que solo quiere dejar de recibir avisos.
  @POST('/v1/devices/unregister')
  Future<OkOut> unregisterDeviceV1DevicesUnregisterPost({
    @Body() required DeviceTokenUnregister body,
  });
}

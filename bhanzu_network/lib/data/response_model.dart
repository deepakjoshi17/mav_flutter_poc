import 'dart:developer';
import '../utils/conversion_utils.dart';

class ResponseModel<T> {

  late MetaModel? meta;
  late T? data;
  bool isSuccessful;

  ResponseModel(this.data, this.meta, {this.isSuccessful = false});

  static ResponseModel<T> success<T>(T data) {
    return ResponseModel<T>(data, MetaModel(200, "SUCCESS"), isSuccessful: true);
  }
}

class MetaModel {

  late int code;
  late String message;

  MetaModel(this.code, this.message);

  MetaModel.fromJson(json) {

    if(json == null) {
      code = -1;
      message = "NA";
      return;
    }

    code = ConversionUtils.getValueFromJson<int>(json, 'code') ?? -1;
    message = ConversionUtils.getValueFromJson<String>(json, 'message') ?? "";

    log("Meta model : $code, $message");
  }
}
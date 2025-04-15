import 'package:flutter/material.dart';

class ConversionUtils {
  static T? getValueFromJson<T>(json, String key) {
    if (json is! Map) {
      // debugPrint(
      //     "Invalid Json, Expected Json but found ::::: ${json?.runtimeType.toString()}, for key: $key");
      return null;
    }

    if (json[key] != null && json[key] is T) {
      return json[key];
    } else {
      // debugPrint("Invalid field type, Expected ${T.runtimeType.toString()} but found ::::: ${json[key].runtimeType.toString()}, for key: $key");
      return null;
    }
  }
}

import 'dart:async';
import 'dart:developer';
import 'dart:io';
import 'package:bhanzu_network/utils/utils.dart';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import '../data/response_model.dart';
import '../utils/network_constants.dart';

enum RequestMethod { get, post, put, delete, multipart }

class NetworkClient {
  NetworkClient._privateConstructor();

  static final NetworkClient _instance = NetworkClient._privateConstructor();

  static NetworkClient getInstance() => _instance;

  static Map<String, String>? _cookieHeader;

  static late Dio _client;

  static const connectTimeOutInMSeconds = 30000;
  static const receiveTimeOutInMSeconds = 60000;

  Uri _domainURI = Uri.parse("");
  static Function? _onSessionExpired;
  static Function? _onServerError;
  static Function? _onInternetError;
  final String _bhanzuAuthKey = "bhanzu-user-auth";

  final authenticatedCookie = 'bhanzu-admin-auth=eyJ0b2tlbiI6ICJ5YTI5LmEwQVpZa05aajdtU2kxZ0wza1FCdTZmc2FySERPaFNWWFJjYTVFVi1zZTBGQ0ZGNU83cHJ5TFZxT0NRSFlyOXZPNnZhOTJqc2E5eUk2QnRyLW9uYmVWR0lzWG5URUM2MzRjRnYxX29RdDkjXiNnelpZSEZPTnZNTVVpZWhYTHIyNHBTa203WDVYV3N6VCszb3lRUFFXOEtHVFJvbVJiMEYxOGt5Ry9nK3l4aWREVkMveHVhN2ZubkE4WnVSRUIweFRlV3J3ZkhnbGFTNnhyR1hQOFNhWCtEZG1JUTZSZm5iQ3g0UXlhMFVUVThQVk9qZmhhMmN5QnJCY2R3ZFh5eXArbEI5UTlQaklqSEs1dU1JQVI0THM1RmlUci84S1lCa2xQSVRhZlN5VlRyKzkvUU9hNlh6bTM1THh2Ym50dmE1NHZqVWZIemhYQjFNSGd2bjRtemtIa0EvajNHUzJPMVRkVi9vbGROS09UcjE4eTJZQTZHeU9TNmF4WUIyTnBCR2FhUTd4L0pZamVYdkh6ZkkzNXlXcVdIeUlCb0h2c211NjVnMzVEeGtqTldPajVFWlNxQTRkVFBEcVBFZDZUQXkvUnc9PSNeI2tEVElNRjB1WERiMGZzdVpxWl8zZEVUMmMwb1ZuZ0JYYUNnWUtBVHNTQVJZU0ZRSEdYMk1pdmxXMXJXZ21XODhUeC1rZm1peWQwUTAxNzUiLCAicmVmcmVzaF90b2tlbiI6ICJDblI3ZERrZ2NJRnFydkwwWXZwN1VBNTVnTTVWRlhzcEtSSWdzdHVycThDd2lnYmVpWk5SVWRYM0U1YmdQSUx4U2JRejZjUlJEa1FmWkJHc1BWYU1RVENONjQ4dnh1dmlVYVlzM1FJMlh2MS82ZWpEM0VlV3VpMGlFTVpUdGM3Z3FoRG1kdm5zdVV0K3RxSFRuVnZUcVNCbExRUE5Ra2w2cjJoTnY5U1VuaktrdUx3cklBdzhFR2hacU5GbXpSNXJzeDFnZkNiOUdtcWo1TU5abmJmTG01YjBhYWZqZ3hxbmZNcFk0N0hOQkZGazYwT0tYY0NQTkZ0amdubUtiSTRoeTFtaHI5S0huMk9YK3F1ajZyN0pNdHBvbEpyeHFVakcvcWZDUWduT3Ftb3JGR2xGOVBXSHhOamJGWWk3VTZNallISXpHbEFvWjB4SGVCSGswOXVzMnc9PSIsICJ0b2tlbl92YWxpZGl0eSI6IDE3NDY0NDM0NDkuNDkxMTgsICJ1c2VyX2lkIjogIjExMjczODg2OTk3MTA3MDk3NDAxMCIsICJpc3N1ZWRfdGltZSI6IDE3NDY0Mzk4NTAsICJlbWFpbCI6ICJhZG1pbi1tZUBleHBpbmZpLmNvbSIsICJwZXJtaXNzaW9ucyI6IFtdLCAiaGFzaCI6ICI5Njk5YjM4ZDVhZGVkZmY3YThmNzM2ZjU1NTNlMzA1NjA3OGU5Mzk3NWRjNTQ1NjkxMTk0OTE4OGViNDAzNTFlIn0=';

  static PersistCookieJar? jar;

  void init(String baseUrl) {
    _domainURI = Uri.parse(baseUrl);
    _client = Dio();
    _client.options
      ..baseUrl = baseUrl
      ..connectTimeout = const Duration(milliseconds: connectTimeOutInMSeconds)
      ..receiveTimeout = const Duration(milliseconds: receiveTimeOutInMSeconds)
      ..headers = {"x-localization": "en", "Content-Type": "application/json"}
      ..validateStatus = (int? status) {
        return status != null && status > 0;
      };

    if(kDebugMode){
      _client.interceptors.add(
          LogInterceptor(
              responseBody: true,
              requestBody: true,
              logPrint: (value) {
                log(value.toString());
              },
          ),
      );
    }

    ///Cookie manager for saving and retrieving cookies
    addCookieJar();
  }

  Function(
    NetworkClientRequestModel requestModel,
    Response<dynamic>? response, DioError? error
  ) onErrorTrack = (req, res, error) {};

  static prepareJar() async {
    final Directory appDocDir = await getApplicationDocumentsDirectory();
    final String appDocPath = appDocDir.path;
    jar = PersistCookieJar(
      ignoreExpires: false,
      storage: FileStorage("$appDocPath/.cookies/"),
    );
  }

  Future<void> addCookieJar() async {

    if(jar == null) {
      await prepareJar();
    }
    _client.interceptors.add(CookieManager(jar!));
    await _updateCookieHeader();
  }

  /*Future<void> addAuthenticatedCookiesForTesting(CookieJar cookieJar) async {
    List<Cookie> cookies = [];
    cookies.add(Cookie("bhanzu-admin-auth",
        "eyJ0b2tlbiI6ICJ5YTI5LmEwQWVYUlBwNlg5WHdxWkxOdVdKdGMzN3ZvQTluZmtfNWdMNFBETVlXOU9abXJoclVUaGg2cG80SE1kR2hKcHNWejBuUkt1cHFFVWZRN2pubDM5aGNLZk5LX3RfbzV3MXk1VF94WlRIaDBlI14jUmhsSnphbUhsNzlDdmlQK3NVUnlWR0tTdGh0dkcyVmlHL2xZNnBGZlpFWUY1cXpzOS9tOEhndDdlWG9qbmdCRk9RYkhHYlB6aG5zQzIyNis0SHFtU2JZc29DcW9nVUs3TWcvWXdvYkNqMGlnYjBwZFQ0d1RDRnVCejNoYVczV2ZiUFltQTU4UTZ0d0szZk1zQUZleW1LUmZEK1d3aFUzNTNNanJ2OEhYYzEwNXNKKzR0N1RTV0IwZ2ZLa1ZQVjNVd1NJZEg5Tmt3L3diUC9JTlJGTWkrVDIyMzlqTEF4akpuRW5qckQ2ZUFuaGZTcTJhaFk3cFJRWHFndTBGcy9RTFIvSGxUcGdTZnNUWm5QM0NsenJXZUVtSXZsM0k4NGp3UStlSUlad092cmQwVnBrOXFSdHYyK3dsNVVYalJKUmFja1RSaGdMZ2xWbmE2NjhOR1FBQkpBPT0jXiMxM294dk0wZVZydEF6YnctUVZXQUxzRTBhNF9ORGljMFFhQ2dZS0Fkd1NBUklTRlFIR1gyTWlLdVNOcDdueTFnZURCYncxVDFxNlpnMDE3NyIsICJyZWZyZXNoX3Rva2VuIjogIkhVZUUvVEZlbkphY3JPRnM1eDRxZXY5OFZJV2Q0NTl3MlBUc2d2Q0hKbFpkWHBFclNidVlHUURZdjlDMUpQVHRBczVoL3ZGSXU0TlJrb1M1dUl6cnR3T0RZVUZNSElUVHA4SUJQTEIwemNXSHc1ejFBejhwSEF6bUUvK25jZmx4dFJ4bnhrcEFTNDdqRzNCWmpTL0pDOVRWL0RHYUF6MGRwMDExeWN2WXdjVGdndWVObGplY1BBV0pnT0xUZnVkT3VrWjBWUEFuSzZBY0pXTXA5M05lenJSNi8wVjdycCtVRjE5azVrZThGZ2N2RWUwdm9ORDM5MFZDaTVHbVlScjh5TXNteXcvcjRVQzJSTWExYmxWelY2NThvK3ZrczJUOHpZTWVHSzdnQnBTYWtvRHdXMUliWHdlN0FZNENNM1M3UXFXOVRJUS95c09Kd09mZGtlWWxiQT09IiwgInRva2VuX3ZhbGlkaXR5IjogMTc0MjU2MDg4OC4xNTY3MzYsICJ1c2VyX2lkIjogIjExMjczODg2OTk3MTA3MDk3NDAxMCIsICJpc3N1ZWRfdGltZSI6IDE3NDI1NTcyODksICJlbWFpbCI6ICJhZG1pbi1tZUBleHBpbmZpLmNvbSIsICJwZXJtaXNzaW9ucyI6IFtdLCAiaGFzaCI6ICJiN2Q1MWRmM2UxNGFmYTY4ZDMzNGEzNmRjNjNhNzRlZjIxMTUxNWNjZDA2MjE1MTc1NDhmMWY2OWQxODhjZTIyIn0=")
      ..expires = DateTime(10, 12, 2025));
    cookies.add(Cookie("CloudFront-Policy",
        "eyJTdGF0ZW1lbnQiOlt7IlJlc291cmNlIjoiaHR0cHM6Ly92aWRlby5kZXYuYmhhbnp1LmNvbS8qIiwiQ29uZGl0aW9uIjp7IkRhdGVMZXNzVGhhbiI6eyJBV1M6RXBvY2hUaW1lIjoxNjgxMjE4NTk2fX19XX0_"));
    cookies.add(Cookie("CloudFront-Signature",
        "YR9g9Ko4O0KInmDMHSwP~9bAu8pmRgPvOfg6D~a~hJnL9Q0qA1-aI9ZgBWECfkB4Nbo7lTHjfn6FG6tYFhWQ71GknxlpeXNWDPJ8MFM6I9rsaModY~S-pCn0T4a9XlaCidA4u9WUqFE3PJ1Kt1nWtetNPIcamfirbHmj5CbTGlZ0VbomtkEBDY1e8Vtgf1r6lWKYSBXXFLG0JY3zlshCv1SlwCM1qv5SSje1B0d7XC6tVN1cjq-20aeoqTjfebzwCYIRSi9BLSBzUIMxfbCzN5DkEjwbPJ2gqmD6j6xQDDmiRh1h0EfKoCk6txm32shqudpDqIMfX77hFEWZa92IWQ__"));
    cookies.add(Cookie("CloudFront-Key-Pair-Id", "K3ONOW0E0RY4P1"));
    await jar?.saveFromResponse(_domainURI, cookies);
  }*/

  Future<String> getDocPath() async {
    return (await getApplicationDocumentsDirectory()).path;
  }

  Future<ResponseModel<T>> makeRequest<T>(
      {required String baseUrl,
      required String url,
      required Map<String, dynamic> data,
      required RequestMethod requestMethod,
      required T Function(dynamic json) createData,
      bool checkAuthCookies = true,
      bool retryFailedAuth = true}) async {


    init(baseUrl);

    if(jar == null) {
      await prepareJar();
    }

    // await addAuthenticatedCookiesForTesting(jar!);
    await addCookieJar();

    if (!(await Utility.isInternetAvailable())) {
      return ResponseModel(
          null,
          MetaModel(NetworkConstants.codeNetworkError,
              NetworkConstants.networkError));
    }

    Response response;

    ///Auth handled via cookies
    var options = Options(headers: {
      'Cookie': authenticatedCookie,
    });
    NetworkClientRequestModel requestModel = NetworkClientRequestModel(
        baseUrl: baseUrl,
        url: url,
        data: data,
        requestMethod: requestMethod,
        checkAuthCookies: checkAuthCookies,
        retryFailedAuth: retryFailedAuth);

    try {
      switch (requestMethod) {
        case RequestMethod.get:
          response =
              await _client.get(url, queryParameters: data, options: options);
          break;
        case RequestMethod.post:
          response = await _client.post(url, data: data, options: options);
          break;
        case RequestMethod.put:
          response = await _client.put(url, data: data, options: options);
          break;
        case RequestMethod.delete:
          response = await _client.delete(url, data: data, options: options);
          break;
        case RequestMethod.multipart:
          FormData formData = FormData.fromMap(data);
          response = await _client.post(url, data: formData, options: options);
          break;
        default:
          response =
              await _client.get(url, queryParameters: data, options: options);
      }
    } on DioException catch (e) {
      log("Response ******** : ${e.response?.headers} ${e.response}");
      onErrorTrack(requestModel,e.response, e);
      if (e.response != null) {
        response = e.response!;

        if (checkAuthCookies) {
          _handleSessionExpired(response);
        }

        return ResponseModel<T>(null, MetaModel.fromJson(response.data),
            isSuccessful: response.data[NetworkConstants.success]);
      } else {
        return ResponseModel(
            null,
            MetaModel(
                e.response?.statusCode ?? -1, e.response?.statusMessage ?? ""));
      }
    }

    if (response.statusCode == NetworkConstants.apiSuccessCode) {
      return ResponseModel<T>(
          createData((response.data == null &&
                  response.data[NetworkConstants.data] == null)
              ? null
              : response.data[NetworkConstants.data] ?? response.data),
          _getMetaData(response),
          isSuccessful: true
          // isSuccessful: response.data[NetworkConstants.success] ??
          //     response.data["status"].toString().toLowerCase() ==
          //         NetworkConstants.success,
          );
    } else {
      log("Api error, response : ${response.headers} $response");
      onErrorTrack(requestModel,response,null);
      if (checkAuthCookies) {
        _handleSessionExpired(response);
      }

      var message = response.statusMessage ?? "";

      if (response.data != null &&
          response.data is Map<String, dynamic> &&
          (response.data as Map<String, dynamic>)
              .containsKey(NetworkConstants.message)) {
        var data = (response.data as Map<String, dynamic>);
        if (data[NetworkConstants.message] is Map<String, dynamic>) {
          return ResponseModel(
              null, MetaModel.fromJson(data[NetworkConstants.message]));
        } else if (data[NetworkConstants.message] is String) {
          return ResponseModel(
              null,
              MetaModel(
                  response.statusCode ?? -1, data[NetworkConstants.message]));
        } else {
          return ResponseModel(null, MetaModel(response.statusCode ?? -1, ""));
        }
      }
      try {
        return ResponseModel(
            null,
            _getMetaData(response) ??
                MetaModel(response.statusCode ?? -1, message));
      } catch (e) {
        return ResponseModel(
            null, MetaModel(response.statusCode ?? -1, "Something went wrong"));
      }
    }
  }

  MetaModel? _getMetaData(Response response) {
    if (response.data is Map<String, dynamic>) {
      final mess = response.data[NetworkConstants.message];
      if (mess is String && mess.isEmpty) {
        return MetaModel(response.statusCode ?? -1, "Something went wrong");
      }
      return mess != null
          ? mess is String
              ? MetaModel(response.statusCode ?? -1,
                  response.data[NetworkConstants.message])
              : mess is Map<String, dynamic>
                  ? MetaModel.fromJson(response.data[NetworkConstants.message])
                  : MetaModel(response.statusCode ?? -1, "")
          : MetaModel(response.data[NetworkConstants.errorCode] ?? -1,
              response.data[NetworkConstants.errorMessage] ?? "");
    } else {
      return MetaModel(response.statusCode ?? -1, "Something went wrong");
    }
  }

  void _handleSessionExpired(Response<dynamic> response) {
    if (response.statusCode == NetworkConstants.unauthorized) {
      if (_onSessionExpired != null) {
        _onSessionExpired!();
      }
    }
  }

  static void addSessionManager(Function callback) {
    _onSessionExpired = callback;
  }

  static void addServerErrorManager(Function callback) {
    _onServerError = callback;
  }

  static void addOnInternetError(Function callback) =>
      _onInternetError = callback;

  Future<bool> _checkCookieExpired(String key) async {
    final cookies = await jar?.loadForRequest(_domainURI);
    Cookie? auth;

    try {
      auth = cookies?.firstWhere((element) => element.name == key);
    } catch (e) {}

    final isValid =
        auth?.expires != null ? auth!.expires!.isAfter(DateTime.now()) : false;

    return isValid;
  }
  Map<String, String> mapCookies = {};
  Future<void> _updateCookieHeader() async {
    final cookies = await jar?.loadForRequest(_domainURI);
    Map<String, String> map = {};
    String cookie = "";
    try {
      for (var i = 0; i < (cookies?.length ?? 0); i++) {
        if (i != 0) {
          cookie += ";";
        }
        final c = cookies![i];
        cookie += "${c.name}=${c.value}";
        mapCookies[c.name] ="${c.name}=${c.value}";
      }

      map["cookie"] = cookie;
    } catch (e) {
      print(e);
    }

    _cookieHeader = map;
  }

  static Map<String, String>? getCookieHeader() {
    return _cookieHeader;
  }
}

class NetworkClientRequestModel {
  final String baseUrl;
  final String url;
  final RequestMethod requestMethod;
  final Map<String, dynamic> data;
  final bool checkAuthCookies;
  final bool retryFailedAuth;

  NetworkClientRequestModel({
    required this.url,
    required this.baseUrl,
    required this.requestMethod,
    required this.data,
    required this.checkAuthCookies,
    required this.retryFailedAuth,
  });

}

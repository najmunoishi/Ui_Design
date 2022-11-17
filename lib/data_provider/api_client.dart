import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:ui_design/constant/app_url.dart';
import 'package:ui_design/constant/constant_key.dart';
import 'package:ui_design/data_provider/pref_helper.dart';
import 'package:ui_design/global/widget/error_dialog.dart';
import 'package:ui_design/utils/app_routes.dart';
import 'package:ui_design/utils/enum.dart';
import 'package:ui_design/utils/extension.dart';
import 'package:ui_design/utils/navigation.dart';
import 'package:ui_design/utils/network_connection.dart';
import 'package:ui_design/utils/view_util.dart';

class ApiClient {
  Dio _dio = Dio();

  Map<String, dynamic> _header = {};

  bool? isPopDialog;

  _initDio({Map<String, String>? extraHeader}) async {
    final DEVISE_OS =
        Platform.isAndroid ? AppConstant.ANDROID.key : AppConstant.IOS.key;

    _header = {
      HttpHeaders.contentTypeHeader: AppConstant.APPLICATION_JSON.key,
      HttpHeaders.authorizationHeader:
          "${AppConstant.BEARER.key} ${PrefHelper.getString(AppConstant.TOKEN.key)}",
      AppConstant.APP_VERSION.key:
          PrefHelper.getString(AppConstant.APP_VERSION.key),
      AppConstant.BUILD_NUMBER.key:
          PrefHelper.getString(AppConstant.BUILD_NUMBER.key),
      AppConstant.USER_AGENT.key: DEVISE_OS,
      AppConstant.DEVICE_OS.key: DEVISE_OS,
      AppConstant.LANGUAGE.key: PrefHelper.getLanguage() == 1
          ? AppConstant.EN.key
          : AppConstant.BN.key,
      extraHeader?.keys.first ?? "": extraHeader?.values.first ?? ""
    };

    _dio.options = BaseOptions(
      baseUrl: AppUrl.base.url,
      headers: _header,
      connectTimeout: 60 * 1000 * 3 * 3, //miliseconds
      sendTimeout: 60 * 1000 * 2 * 3,
      receiveTimeout: 60 * 1000 * 2 * 3,
    );
    _initInterceptors();
  }

  void _initInterceptors() {
    _dio.interceptors.add(InterceptorsWrapper(onRequest: (options, handler) {
      print(
          'REQUEST[${options.method}] => PATH: ${AppUrl.base.url}${options.path} '
          '=> Request Values: param: ${options.queryParameters}, DATA: ${options.data}, => _HEADERS: ${options.headers}');
      return handler.next(options);
    }, onResponse: (response, handler) {
      print(
          'RESPONSE[${response.statusCode}] => DATA: ${response.data} URL: ${response.requestOptions.baseUrl}${response.requestOptions.path}');
      return handler.next(response);
    }, onError: (err, handler) {
      print(
          'ERROR[${err.response?.statusCode}] => DATA: ${err.response?.data} Message: ${err.message} URL: ${err.response?.requestOptions.baseUrl}${err.response?.requestOptions.path}');
      return handler.next(err);
    }));
  }

  // Image or file upload using Rest handle.
  Future requestFormData(
      {required String url,
      required Method method,
      Map<String, dynamic>? params,
      bool? isPopGlobalDialog,
      String? token,
      Options? options,
      void Function(int, int)? onReceiveProgress,
      String? savePath,
      List<File>? files,
      String? fileKeyName,
      required onSuccessFunction(
        Response response,
      )}) async {
    final tokenHeader = <String, String>{
      HttpHeaders.contentTypeHeader: AppConstant.MULTIPART_FORM_DATA.key
    };
    _initDio(extraHeader: tokenHeader);

    if (files != null) {
      params?.addAll({
        "${fileKeyName}": files
            .map((item) => MultipartFile.fromFileSync(item.path,
                filename: item.path.split('/').last))
            .toList()
      });
    }

    final data = FormData.fromMap(params!);
    data.log();
    // Handle and check all the status.
    return clientHandle(
      url,
      method,
      params,
      data: data,
      onSuccessFunction: onSuccessFunction,
    );
  }

  // Normal Rest API  handle.
  Future request(
      {required String url,
      required Method method,
      Map<String, dynamic>? params,
      bool? isPopGlobalDialog,
      String? token,
      Options? options,
      void Function(int, int)? onReceiveProgress,
      String? savePath,
      required onSuccessFunction(
        Response response,
      )}) async {
    final tokenHeader = <String, String>{AppConstant.PUSH_ID.key: token ?? ""};

    if (NetworkConnection.instance.isInternet) {
      // Handle and check all the status.
      isPopDialog = isPopGlobalDialog;
      _initDio(extraHeader: tokenHeader);
      return clientHandle(
        url,
        method,
        params,
        options: options,
        savePath: savePath,
        onReceiveProgress: onReceiveProgress,
        onSuccessFunction: onSuccessFunction,
      );
    } else {
      NetworkConnection.instance.apiStack.add(
        APIParams(
          url: url,
          method: method,
          variables: params ?? {},
          onSuccessFunction: onSuccessFunction,
        ),
      );
      if (ViewUtil.isPresentedDialog == false) {
        ViewUtil.isPresentedDialog = true;
        WidgetsBinding.instance.addPostFrameCallback(
          (_) {
            ViewUtil.showInternetDialog(
              onPressed: () {
                if (NetworkConnection.instance.isInternet == true) {
                  Navigator.of(Navigation.key.currentState!.overlay!.context,
                          rootNavigator: true)
                      .pop();
                  ViewUtil.isPresentedDialog = false;
                  NetworkConnection.instance.apiStack.forEach(
                    (element) {
                      request(
                        url: element.url,
                        method: element.method,
                        params: element.variables,
                        onSuccessFunction: element.onSuccessFunction,
                      );
                    },
                  );
                  NetworkConnection.instance.apiStack = [];
                }
              },
            );
          },
        );
      }
    }
  }

// Handle all the method and error.
  Future clientHandle(
    String url,
    Method method,
    Map<String, dynamic>? params, {
    dynamic data,
    Options? options,
    String? savePath,
    void Function(int, int)? onReceiveProgress,
    required onSuccessFunction(Response response)?,
  }) async {
    Response response;
    try {
      // Handle response code from api.
      if (method == Method.POST) {
        response = await _dio.post(
          url,
          queryParameters: params,
          data: data,
        );
      } else if (method == Method.DELETE) {
        response = await _dio.delete(url);
      } else if (method == Method.PATCH) {
        response = await _dio.patch(url);
      } else if (method == Method.DOWNLOAD) {
        response = await _dio.download(
          url,
          savePath,
          queryParameters: params,
          options: options,
          onReceiveProgress: onReceiveProgress,
        );
      } else {
        response = await _dio.get(
          url,
          queryParameters: params,
          options: options,
          onReceiveProgress: onReceiveProgress,
        );
      }
      /**
       * Handle Rest based on response json
       * So please check in json body there is any status_code or code
       */
      if (response.statusCode == 200) {
        final Map data = json.decode(response.toString());
        final verifycode = data['code'];
        int code = int.tryParse(verifycode.toString()) ?? 0;
        if (code == 200) {
          if (response.data != null) {
            return onSuccessFunction!(response);
          } else {
            "response data is ${response.data}".log();
          }
        } else if (code == 401) {
          // PrefHelper.setString(AppConstant.TOKEN.key, "").then(
          //   (value) => Navigation.pushAndRemoveUntil(
          //     Navigation.key.currentContext,
          //     appRoutes: AppRoutes.login,
          //   ),
          // );
        } else {
          //Where error occured then pop the global dialog
          response.statusCode?.log();
          code.log();
          isPopDialog?.log();

          List<String>? erroMsg;
          erroMsg = List<String>.from(data["errors"]?.map((x) => x));
          ViewUtil.showAlertDialog(
            barrierDismissible: false,
            content: ErrorDialog(
              erroMsg: erroMsg,
            ),
          ).then((value) {
            if (isPopDialog == true || isPopDialog == null) {
              Navigator.pop(Navigation.key.currentContext!);
            }
          });
          if (isPopDialog == false) {
            throw Exception();
          }
        }
      }

      // Handle Error type if dio catches anything.
    } on DioError catch (e) {
      e.log();

      switch (e.type) {
        case DioErrorType.connectTimeout:
          ViewUtil.SSLSnackbar("Time out delay ");
          throw Exception();
        case DioErrorType.receiveTimeout:
          ViewUtil.SSLSnackbar("Server is not responded properly");
          throw Exception();
        case DioErrorType.other:
          if (e.error is SocketException) {
            throw SocketException("No Internat Available");
          } else {
            ViewUtil.SSLSnackbar("Server is not responded properly");
            throw Exception();
          }
        case DioErrorType.response:
          ViewUtil.SSLSnackbar("Internal Responses error");
          throw Exception(e.toString());
        default:
          ViewUtil.SSLSnackbar("Something went wrong");
          throw Exception("Something went wrong" + e.toString());
      }
    } catch (e) {
      "dioErrorCatch $e".log();
      throw Exception("Something went wrong" + e.toString());
    }
  }
}

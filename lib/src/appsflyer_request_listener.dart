part of appsflyer_sdk;

class AppsFlyerRequestListener {
  RequestSuccessListener onSuccess;
  RequestErrorListener onError;

  AppsFlyerRequestListener({
    required this.onSuccess,
    required this.onError,
  });
}
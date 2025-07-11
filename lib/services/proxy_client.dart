import 'dart:io';
import 'package:http/http.dart' as http;

class ProxyHttpClient extends http.BaseClient {
  final String proxyHost;
  final int proxyPort;
  final String? proxyUser;
  final String? proxyPassword;

  ProxyHttpClient({
    required this.proxyHost,
    required this.proxyPort,
    this.proxyUser,
    this.proxyPassword,
  });

  Map<String, String> _headersFromHttpHeaders(HttpHeaders headers) {
    final map = <String, String>{};
    headers.forEach((name, values) {
      if (values.isNotEmpty) {
        map[name] = values.join(',');
      }
    });
    return map;
  }

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    HttpClient httpClient = HttpClient();
    httpClient.findProxy = (uri) {
      if (proxyUser != null && proxyPassword != null && proxyUser!.isNotEmpty && proxyPassword!.isNotEmpty) {
        return "PROXY $proxyUser:$proxyPassword@$proxyHost:$proxyPort;";
      } else {
        return "PROXY $proxyHost:$proxyPort;";
      }
    };
    httpClient.badCertificateCallback = (cert, host, port) => true;
    final ioRequest = await httpClient.openUrl(request.method, request.url);
    request.headers.forEach((name, value) {
      ioRequest.headers.set(name, value);
    });
    if (request is http.Request) {
      ioRequest.add(request.bodyBytes);
    }
    final ioResponse = await ioRequest.close();
    final stream = ioResponse;
    return http.StreamedResponse(
      stream,
      ioResponse.statusCode,
      contentLength: ioResponse.contentLength == -1 ? null : ioResponse.contentLength,
      request: request,
      headers: _headersFromHttpHeaders(ioResponse.headers),
      reasonPhrase: ioResponse.reasonPhrase,
      isRedirect: ioResponse.isRedirect,
      persistentConnection: ioResponse.persistentConnection,
    );
  }
} 
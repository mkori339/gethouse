// lib/services/api_service.dart
import 'dart:convert';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:file_picker/file_picker.dart';
import 'auth_service.dart' ;
class ApiService {
  ApiService._(); // private
  static const String baseUrl = 'https://sever.mikangaula.store'; // <- change to your backend

  // keys
  static const String _tokenKey = 'api_token';

  /// Save token to SharedPreferences
  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  /// Remove token from SharedPreferences
  static Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
  }

  /// Get stored token (or empty string if none)
  static Future<String> _getStoredToken() async {
    final token= await AuthService.getToken();
    return token ?? '';
  }

  /// Build headers; optionally include JSON content type
  static Future<Map<String, String>> _getHeaders({bool json = true}) async {
    final token = await _getStoredToken();
    final headers = <String, String>{
      'Accept': 'application/json',
    };
    if (json) headers['Content-Type'] = 'application/json';
    if (token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  /// Handle http.Response -> decode json or throw
  static dynamic _handleResponse(http.Response resp) {
    final status = resp.statusCode;
    final body = resp.body.isNotEmpty ? resp.body : '{}';
    dynamic decoded;
    try {
      decoded = jsonDecode(body);
    } catch (_) {
      decoded = body;
    }

    if (status >= 200 && status < 300) {
      return decoded;
    } else {
      // Return a standardized error object
      throw ApiException(status, decoded);
    }
  }

  /// GET request with query parameters for pagination and filtering
 static Future<dynamic> get(String path, {Map<String, dynamic>? params}) async {
  Uri uri;

  if (path.startsWith('http://') || path.startsWith('https://')) {
    uri = Uri.parse(path);
  } else {
    // Ensure path starts with '/'
    final normalizedPath = path.startsWith('/') ? path : '/$path';
    uri = Uri.parse('$baseUrl$normalizedPath');
  }

  // Add query parameters if provided
  if (params != null && params.isNotEmpty) {
    final queryParams = <String, String>{};
    params.forEach((key, value) {
      if (value != null) {
        queryParams[key] = value.toString();
      }
    });
    uri = uri.replace(queryParameters: queryParams);
  }

  // Always include Authorization token
  final headers = await _getHeaders(json: false);

  // Example: Add Bearer token if available
  final token = await _getStoredToken(); // <-- implement this function to get stored JWT
  if (token.isNotEmpty) {
    headers['Authorization'] = 'Bearer $token';
  }

  final resp = await http.get(uri, headers: headers);
  return _handleResponse(resp);
}


  /// POST JSON request
  static Future<dynamic> postJson(String path, Map<String, dynamic> body) async {
    final uri = Uri.parse(_fullUrl(path));
    final headers = await _getHeaders(json: true);
    final resp = await http.post(uri, headers: headers, body: jsonEncode(body));
    return _handleResponse(resp);
  }

  /// PUT JSON request
  static Future<dynamic> putJson(String path, Map<String, dynamic> body) async {
    final uri = Uri.parse(_fullUrl(path));
    final headers = await _getHeaders(json: true);
    final resp = await http.put(uri, headers: headers, body: jsonEncode(body));
    return _handleResponse(resp);
  }

  /// DELETE request
  static Future<dynamic> delete(String path) async {
    final uri = Uri.parse(_fullUrl(path));
    final headers = await _getHeaders(json: false);
    final resp = await http.delete(uri, headers: headers);
    return _handleResponse(resp);
  }

  /// POST form (x-www-form-urlencoded)
  static Future<dynamic> postForm(String path, Map<String, String> fields) async {
    final uri = Uri.parse(_fullUrl(path));
    final headers = await _getHeaders(json: false);
    // ensure content-type for form
    headers['Content-Type'] = 'application/x-www-form-urlencoded';
    final resp = await http.post(uri, headers: headers, body: fields);
    return _handleResponse(resp);
  }

  /// Multipart upload (useful for images/files)
  /// files: List<PlatformFile> (from file_picker) OR List<File> for mobile
  /// fieldName: name of field for each file (default 'images[]')
  static Future<dynamic> postMultipart({
    required String path,
    Map<String, String>? fields,
    List<PlatformFile>? files,
    List<File>? mobileFiles,
    String fieldName = 'images[]',
  }) async {
    final uri = Uri.parse(_fullUrl(path));
    final request = http.MultipartRequest('POST', uri);

    // add fields
    if (fields != null) request.fields.addAll(fields);

    // add Authorization header if token present
    final token = await _getStoredToken();
    if (token.isNotEmpty) {
      request.headers['Authorization'] = 'Bearer $token';
    }

    // add files from file_picker (web & mobile supported)
    if (files != null) {
      for (var pf in files) {
        final bytes = pf.bytes;
        final filename = pf.name;
        if (bytes == null) continue; // skip if no bytes
        final ext = filename.split('.').last.toLowerCase();
        final mime = _mimeFromExt(ext);
        final multipart = http.MultipartFile.fromBytes(
          fieldName,
          bytes,
          filename: filename,
          contentType: MediaType(mime[0], mime[1]),
        );
        request.files.add(multipart);
      }
    }

    // add files from dart:io File (mobile)
    if (mobileFiles != null) {
      for (var f in mobileFiles) {
        final filename = f.path.split(Platform.pathSeparator).last;
        final ext = filename.split('.').last.toLowerCase();
        final mime = _mimeFromExt(ext);
        final multipart = await http.MultipartFile.fromPath(
          fieldName,
          f.path,
          contentType: MediaType(mime[0], mime[1]),
          filename: filename,
        );
        request.files.add(multipart);
      }
    }

    final streamed = await request.send();
    final resp = await http.Response.fromStream(streamed);
    return _handleResponse(resp);
  }

  /// Helper: make sure path becomes full url
  static String _fullUrl(String path) {
    if (path.startsWith('http://') || path.startsWith('https://')) return path;
    if (!path.startsWith('/')) path = '/$path';
    return '$baseUrl$path';
  }

  /// Basic small mime detection
  static List<String> _mimeFromExt(String ext) {
    switch (ext) {
      case 'png':
        return ['image', 'png'];
      case 'jpg':
      case 'jpeg':
        return ['image', 'jpeg'];
      case 'webp':
        return ['image', 'webp'];
      case 'gif':
        return ['image', 'gif'];
      case 'pdf':
        return ['application', 'pdf'];
      default:
        return ['application', 'octet-stream'];
    }
  }

  /// Like a post
  static Future<dynamic> likePost(int postId) async {
    return postJson('/api/posts/$postId/like', {});
  }

  /// Unlike a post
  static Future<dynamic> unlikePost(int postId) async {
    return delete('/api/posts/$postId/like');
  }

  /// Add a comment to a post
  static Future<dynamic> addComment(int postId, String content) async {
    return postJson('/api/posts/$postId/comments', {'content': content});
  }

  /// Get comments for a post
  static Future<dynamic> getComments(int postId, {int page = 1}) async {
    return get('/api/posts/$postId/comments', params: {'page': page});
  }

  /// Report a post
  static Future<dynamic> reportPost(int postId, String phone, String reason) async {
    return postJson('/api/posts/$postId/report', {
      'phone': phone,
      'reason': reason,
    });
  }

  /// Search posts with filters
  static Future<dynamic> searchPosts({
    String? category,
    String? type,
    String? region,
    double? maxPrice,
    int page = 1,
  }) async {
    final params = <String, dynamic>{'page': page};
    
    if (category != null) params['category'] = category;
    if (type != null) params['type'] = type;
    if (region != null) params['region'] = region;
    if (maxPrice != null) params['max_price'] = maxPrice;
    
    return get('/api/posts/search', params: params);
  }
}


class ApiException implements Exception {
  final int status;
  final dynamic body;
  ApiException(this.status, this.body);
  
  @override
  String toString() => 'ApiException(status: $status, body: $body)';
}
import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = "http://10.0.2.2:8080";

  // GET all patients
  static Future<List<dynamic>> getPatients() async {
    final response = await http.get(
      Uri.parse("$baseUrl/api/patients"),
      headers: {
        "Content-Type": "application/json",
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Failed to load patients");
    }
  }
}

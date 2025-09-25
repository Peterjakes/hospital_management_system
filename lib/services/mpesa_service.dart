import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class MpesaService {
  static const String _baseUrl = 'https://mpesa-server-icfv.onrender.com'; 
  // static const String _baseUrl = 'https://37ec1af28677.ngrok-free.app'; 
  
  static const Duration _timeout = Duration(seconds: 30);

  // STK Push - Initiate M-Pesa payment
  static Future<Map<String, dynamic>?> initiateSTKPush({
    required String phoneNumber,
    required double amount,
    required String accountReference,
    required String transactionDesc,
  }) async {
    try {
      final url = Uri.parse('$_baseUrl/mpesa/stkpush');
      
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'phoneNumber': phoneNumber,
          'amount': amount,
          'accountReference': accountReference,
          'transactionDesc': transactionDesc,
        }),
      ).timeout(_timeout);

      debugPrint('STK Push Response: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return data;
        } else {
          throw Exception(data['message'] ?? 'STK Push failed');
        }
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'Server error');
      }
    } catch (e) {
      debugPrint('STK Push Error: $e');
      rethrow;
    }
  }

  // Query STK Push status
  static Future<Map<String, dynamic>?> querySTKPushStatus({
    required String checkoutRequestId,
  }) async {
    try {
      final url = Uri.parse('$_baseUrl/mpesa/stkquery');
      
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'checkoutRequestId': checkoutRequestId,
        }),
      ).timeout(_timeout);

      debugPrint('STK Query Response: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return data;
        } else {
          throw Exception(data['message'] ?? 'Query failed');
        }
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'Server error');
      }
    } catch (e) {
      debugPrint('STK Query Error: $e');
      rethrow;
    }
  }

  // Get transaction status from your server
  static Future<Map<String, dynamic>?> getTransactionStatus({
  required String checkoutRequestId,
}) async {
  try {
    final url = Uri.parse('$_baseUrl/mpesa/status/$checkoutRequestId');
    
    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ).timeout(_timeout);
    
    debugPrint('Transaction Status Response: ${response.statusCode} - ${response.body}');
    
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      
      if (data['success'] == true && data['data'] != null) {
        final tx = data['data'];
        
        // Return the complete mapped response
        return {
          'success': true,
          'data': {
            'checkoutRequestId': tx['checkoutRequestId'],
            'merchantRequestId': tx['merchantRequestId'],
            'status': tx['status']?.toString().toUpperCase() ?? 'PENDING',
            'amount': tx['amount'],
            'phoneNumber': tx['phoneNumber'],
            'mpesaReceiptNumber': tx['mpesaReceiptNumber'],
            'transactionDate': tx['transactionDate'],
            'resultCode': tx['resultCode'] ?? -1,
            'resultDesc': tx['resultDesc'] ?? '',
          }
        };
      } else {
        // Return structure that indicates failure but allows polling to continue
        return {
          'success': false,
          'message': data['message'] ?? 'Status check failed',
          'data': {
            'status': 'PENDING', // Assume pending if unclear
            'resultCode': -1,
            'resultDesc': data['message'] ?? 'Status unclear'
          }
        };
      }
    } else if (response.statusCode == 404) {
      // Transaction not found yet, continue polling
      return {
        'success': false,
        'data': {
          'status': 'PENDING',
          'resultCode': -1,
          'resultDesc': 'Transaction not found yet'
        }
      };
    } else {
      final errorData = jsonDecode(response.body);
      throw Exception(errorData['message'] ?? 'Server error: ${response.statusCode}');
    }
  } catch (e) {
    debugPrint('Transaction Status Error: $e');
    rethrow;
  }
}

  // Get all transactions (for admin/user history)
  static Future<List<Map<String, dynamic>>?> getAllTransactions() async {
    try {
      final url = Uri.parse('$_baseUrl/mpesa/transactions');
      
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
      ).timeout(_timeout);

      debugPrint('All Transactions Response: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return List<Map<String, dynamic>>.from(data['data'] ?? []);
        } else {
          throw Exception(data['message'] ?? 'Failed to fetch transactions');
        }
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'Server error');
      }
    } catch (e) {
      debugPrint('Get Transactions Error: $e');
      rethrow;
    }
  }

  // B2C Payment (Send money to customer)
  static Future<Map<String, dynamic>?> initiateB2CPayment({
    required String phoneNumber,
    required double amount,
    required String remarks,
    String? occasion,
  }) async {
    try {
      final url = Uri.parse('$_baseUrl/mpesa/b2c');
      
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'phoneNumber': phoneNumber,
          'amount': amount,
          'remarks': remarks,
          'occasion': occasion ?? 'Payment',
        }),
      ).timeout(_timeout);

      debugPrint('B2C Response: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return data;
        } else {
          throw Exception(data['message'] ?? 'B2C payment failed');
        }
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'Server error');
      }
    } catch (e) {
      debugPrint('B2C Payment Error: $e');
      rethrow;
    }
  }

  // Check account balance
  static Future<Map<String, dynamic>?> checkAccountBalance() async {
    try {
      final url = Uri.parse('$_baseUrl/mpesa/balance');
      
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
      ).timeout(_timeout);

      debugPrint('Balance Response: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return data;
        } else {
          throw Exception(data['message'] ?? 'Balance check failed');
        }
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'Server error');
      }
    } catch (e) {
      debugPrint('Balance Check Error: $e');
      rethrow;
    }
  }

  // Test server connection
  static Future<bool> testConnection() async {
    try {
      final url = Uri.parse('$_baseUrl/');
      
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 10));

      debugPrint('Connection Test Response: ${response.statusCode} - ${response.body}');

      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Connection Test Error: $e');
      return false;
    }
  }

  // Validate Kenyan phone number format
  static bool isValidKenyanPhoneNumber(String phoneNumber) {
    if (phoneNumber.isEmpty) return false;
    
    String cleanPhone = phoneNumber.replaceAll(RegExp(r'[\s\-\+]'), '');
    
    // Check for valid Kenyan phone number patterns
    if (cleanPhone.startsWith('254') && cleanPhone.length == 12) {
      return RegExp(r'^254[17]\d{8}$').hasMatch(cleanPhone);
    } else if (cleanPhone.length == 10) {
      return RegExp(r'^0[17]\d{8}$').hasMatch(cleanPhone);
    }
    
    return false;
  }

  // Format phone number for M-Pesa
  static String formatPhoneNumberForMpesa(String phoneNumber) {
    String cleanPhone = phoneNumber.replaceAll(RegExp(r'[\s\-\+]'), '');
    
    // Convert to international format (254...)
    if (cleanPhone.startsWith('0') && cleanPhone.length == 10) {
      return '254${cleanPhone.substring(1)}';
    } else if (cleanPhone.startsWith('254')) {
      return cleanPhone;
    } else if (cleanPhone.length == 9) {
      // Assume it's missing the 0 or 254
      return '254$cleanPhone';
    }
    
    return cleanPhone;
  }

  // Format phone number for display
  static String formatPhoneNumberForDisplay(String phoneNumber) {
    final formatted = formatPhoneNumberForMpesa(phoneNumber);
    if (formatted.startsWith('254') && formatted.length == 12) {
      return '+254 ${formatted.substring(3, 6)} ${formatted.substring(6, 9)} ${formatted.substring(9)}';
    }
    return phoneNumber;
  }
}
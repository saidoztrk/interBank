// lib/models/customer.dart
// Erenay tarafından eklendi: Azure DB API "customer" modeli
// PowerShell çıktısındaki alan adlarına toleranslıdır (CustomerId/FullName vb.)

class Customer {
  final int customerId;
  final String? nationalId;
  final String fullName;
  final DateTime? birthDate;
  final String? email;
  final String? phone;
  final String? address;
  final String? segment;
  final double? riskScore;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Customer({
    required this.customerId,
    required this.fullName,
    this.nationalId,
    this.birthDate,
    this.email,
    this.phone,
    this.address,
    this.segment,
    this.riskScore,
    this.createdAt,
    this.updatedAt,
  });

  factory Customer.fromJson(Map<String, dynamic> j) {
    // Erenay: bazı alanlar Büyük/Küçük harfle gelebilir → ikisine de bak
    final cid = j['CustomerId'] ?? j['customerId'] ?? j['id'];
    final name = j['FullName'] ?? j['fullName'] ?? j['name'] ?? '';

    String? _str(dynamic v) => v?.toString();
    int _asInt(dynamic v) =>
        v is int ? v : int.tryParse(v?.toString() ?? '') ?? 0;
    double? _asDouble(dynamic v) {
      if (v == null) return null;
      if (v is num) return v.toDouble();
      if (v is String) {
        // "12,5" gibi virgüllü gelebilir → noktaya çevir
        final fixed = v.replaceAll(',', '.');
        return double.tryParse(fixed);
      }
      return null;
    }

    DateTime? _asDate(dynamic v) {
      final s = _str(v);
      if (s == null || s.isEmpty) return null;
      try {
        return DateTime.parse(s);
      } catch (_) {
        return null;
      }
    }

    return Customer(
      customerId: _asInt(cid),
      fullName: _str(name) ?? '',
      nationalId: _str(j['NationalId'] ?? j['nationalId']),
      birthDate: _asDate(j['BirthDate'] ?? j['birthDate']),
      email: _str(j['Email'] ?? j['email']),
      phone: _str(j['Phone'] ?? j['phone']),
      address: _str(j['Address'] ?? j['address']),
      segment: _str(j['Segment'] ?? j['segment']),
      riskScore: _asDouble(j['RiskScore'] ?? j['riskScore']),
      createdAt: _asDate(j['CreatedAt'] ?? j['createdAt']),
      updatedAt: _asDate(j['UpdatedAt'] ?? j['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() => {
        'customerId': customerId,
        'nationalId': nationalId,
        'fullName': fullName,
        'birthDate': birthDate?.toIso8601String(),
        'email': email,
        'phone': phone,
        'address': address,
        'segment': segment,
        'riskScore': riskScore,
        'createdAt': createdAt?.toIso8601String(),
        'updatedAt': updatedAt?.toIso8601String(),
      };

  @override
  String toString() =>
      'Customer($customerId, $fullName, segment=$segment, risk=$riskScore)';
}

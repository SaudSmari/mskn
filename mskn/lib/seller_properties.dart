import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class SellerPropertiesPage extends StatelessWidget {
  const SellerPropertiesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final User? user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('عقاراتي'),
      ),
      body: SafeArea(
        child: user == null
            ? _buildNotLoggedIn()
            : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: FirebaseFirestore.instance
                    .collection('property')
                    .where('seller_id', isEqualTo: user.uid)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Text(
                          'حدث خطأ أثناء تحميل العقارات',
                          style: TextStyle(color: Colors.red[700]),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    );
                  }

                  final docs = snapshot.data?.docs ?? const [];
                  if (docs.isEmpty) {
                    return _buildEmptyState();
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.all(16),
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      final doc = docs[index];
                      final data = doc.data();

                      final String title = _firstNonEmpty([
                        data['title'],
                        data['name'],
                        'عقار بدون اسم',
                      ]);
                      final String subtitle = _composeSubtitle(data);

                      final String priceStr = _stringOrEmpty(data['price']);
                      final String imageUrl = _extractFirstImageUrl(data['image']);

                      return Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey[200]!),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF111827).withOpacity(0.04),
                              blurRadius: 18,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: ListTile(
                          leading: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: imageUrl.isEmpty
                                ? Container(
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      color: Colors.blue.withOpacity(0.1),
                                    ),
                                    child: const Icon(
                                      Icons.home_outlined,
                                      color: Colors.blue,
                                    ),
                                  )
                                : Image.network(
                                    imageUrl,
                                    width: 44,
                                    height: 44,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        width: 44,
                                        height: 44,
                                        color: Colors.blue.withOpacity(0.1),
                                        child: const Icon(
                                          Icons.home_outlined,
                                          color: Colors.blue,
                                        ),
                                      );
                                    },
                                  ),
                          ),
                          title: Text(
                            title,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF111827),
                            ),
                          ),
                          subtitle: subtitle.isEmpty
                              ? null
                              : Padding(
                                  padding: const EdgeInsets.only(top: 4.0),
                                  child: Text(
                                    subtitle,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: Color(0xFF6B7280),
                                    ),
                                  ),
                                ),
                          trailing: priceStr.isEmpty
                              ? const Icon(Icons.chevron_left)
                              : Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    const Text(
                                      'السعر',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Color(0xFF6B7280),
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      priceStr,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF111827),
                                      ),
                                    ),
                                  ],
                                ),
                          onTap: () {
                            // Placeholder: open property details in future
                          },
                        ),
                      );
                    },
                  );
                },
              ),
      ),
    );
  }

  Widget _buildNotLoggedIn() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.lock_outline, size: 64, color: Colors.grey),
          SizedBox(height: 12),
          Text(
            'الرجاء تسجيل الدخول لعرض عقاراتك',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: Color(0xFF6B7280)),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.home_outlined, size: 64, color: Colors.grey),
          SizedBox(height: 12),
          Text(
            'لا توجد عقارات مسجلة حتى الآن',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: Color(0xFF6B7280)),
          ),
        ],
      ),
    );
  }

  String _firstNonEmpty(List<dynamic> candidates) {
    for (final dynamic value in candidates) {
      if (value is String && value.trim().isNotEmpty) {
        return value.trim();
      }
    }
    return '';
  }

  String _composeSubtitle(Map<String, dynamic> data) {
    final List<String> parts = [];

    final String type = _stringOrEmpty(data['type']);
    if (type.isNotEmpty) parts.add('النوع: $type');

    final String rooms = _stringOrEmpty(data['rooms']);
    if (rooms.isNotEmpty) parts.add('الغرف: $rooms');

    final String bathrooms = _stringOrEmpty(data['bathrooms']);
    if (bathrooms.isNotEmpty) parts.add('الحمامات: $bathrooms');

    final String area = _stringOrEmpty(data['area']);
    if (area.isNotEmpty) parts.add('المساحة: $area م²');

    final String streetWidth = _stringOrEmpty(data['streetWidth']);
    if (streetWidth.isNotEmpty) parts.add('عرض الشارع: $streetWidth م');

    final String propertyAge = _stringOrEmpty(data['propertyAge']);
    if (propertyAge.isNotEmpty) parts.add('عمر العقار: $propertyAge');

    final String locationName = _stringOrEmpty(data['location_name']);
    if (locationName.isNotEmpty) parts.add('الموقع: $locationName');

    final String createdAt = _formatCreatedAt(data['created_at']);
    if (createdAt.isNotEmpty) parts.add('أُنشئ: $createdAt');

    return parts.join(' • ');
  }

  String _stringOrEmpty(dynamic value) {
    if (value == null) return '';
    final String s = value.toString().trim();
    return s;
  }

  String _extractFirstImageUrl(dynamic value) {
    if (value is List && value.isNotEmpty) {
      final dynamic first = value.first;
      if (first is String && first.trim().isNotEmpty) {
        return first.trim();
      }
    }
    return '';
  }

  String _formatCreatedAt(dynamic value) {
    if (value is Timestamp) {
      final DateTime dt = value.toDate();
      final String y = dt.year.toString().padLeft(4, '0');
      final String m = dt.month.toString().padLeft(2, '0');
      final String d = dt.day.toString().padLeft(2, '0');
      return '$y-$m-$d';
    }
    return _stringOrEmpty(value);
  }
}



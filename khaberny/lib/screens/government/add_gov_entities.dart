import 'package:cloud_firestore/cloud_firestore.dart';

Future<void> addGovernmentEntities() async {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final List<Map<String, dynamic>> entities = [
    {
      "code": "MOH2024SEC",
      "email": "ministry.health@gov.jo",
      "name": "Ministry of Health",
      "department": "Public Health",
      "role": "government",
      "active": true,
      "region": "Amman",
      "phone": "+962-6-5200230",
      "createdAt": Timestamp.now(),
    },
    {
      "code": "MPW2024SEC",
      "email": "ministry.works@gov.jo",
      "name": "Ministry of Public Works",
      "department": "Infrastructure",
      "role": "government",
      "active": true,
      "region": "Amman",
      "phone": "+962-6-5850300",
      "createdAt": Timestamp.now(),
    },
    {
      "code": "GAM2024SEC",
      "email": "amman.municipality@gov.jo",
      "name": "Greater Amman Municipality",
      "department": "City Services",
      "role": "government",
      "active": true,
      "region": "Amman",
      "phone": "+962-6-4636111",
      "createdAt": Timestamp.now(),
    },
    {
      "code": "CDD2024SEC",
      "email": "civil.defense@gov.jo",
      "name": "Civil Defense Directorate",
      "department": "Emergency Services",
      "role": "government",
      "active": true,
      "region": "Amman",
      "phone": "+962-6-5680636",
      "createdAt": Timestamp.now(),
    }
  ];

  for (var entity in entities) {
    try {
      await _firestore.collection('government_codes').add(entity);
      print('Added entity: ${entity['name']}');
    } catch (e) {
      print('Error adding ${entity['name']}: $e');
    }
  }
}

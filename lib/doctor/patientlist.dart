import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PatientListPage extends StatelessWidget {
  const PatientListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("My Patients")),
      body: StreamBuilder<QuerySnapshot>(
        stream:
            FirebaseFirestore.instance.collection("appointments").snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;

          if (docs.isEmpty) {
            return const Center(child: Text("No patients yet"));
          }

          final names = <String>{};
          for (var d in docs) {
            final data = d.data() as Map<String, dynamic>;
            if (data["name"] != null) {
              names.add(data["name"].toString());
            }
          }

          final patientList = names.toList();

          return ListView.builder(
            itemCount: patientList.length,
            itemBuilder: (context, index) {
              return ListTile(
                leading: const CircleAvatar(child: Icon(Icons.person)),
                title: Text(patientList[index]),
                subtitle: const Text("Patient"),
              );
            },
          );
        },
      ),
    );
  }
}

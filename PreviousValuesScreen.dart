import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:csv/csv.dart';

class PreviousValuesScreen extends StatelessWidget {
  final String userId;

  const PreviousValuesScreen({Key? key, required this.userId})
      : super(key: key);

  Future<void> _saveCsvFile(List<List<dynamic>> csvData) async {
    try {
      // Request permission if not granted
      var status = await Permission.storage.request();
      if (status.isGranted) {
        final externalDir = await getExternalStorageDirectory();
        final filePath = '${externalDir!.path}/user_history.csv';

        final File file = File(filePath);
        // Convert csvData to CSV format
        String csvString = const ListToCsvConverter().convert(csvData);
        await file.writeAsString(csvString);
        print('CSV file saved at: $filePath');
      } else {
        // Handle the case where permission is not granted
        print('Permission not granted to save CSV file');
      }
    } catch (e) {
      print('Error saving CSV file: $e');
    }
  }

  List<List<dynamic>> _prepareCsvData(
      QuerySnapshot<Map<String, dynamic>> snapshot) {
    List<List<dynamic>> csvData = [
      ['Timestamp', 'Breath Rate', 'Heart Rate', 'Humidity', 'Temperature']
    ];

    snapshot.docs.forEach((DocumentSnapshot userHistory) {
      Map<String, dynamic> data = userHistory.data() as Map<String, dynamic>;

      DateTime timestamp;
      if (data['timestamp'] is String) {
        timestamp = DateTime.parse(data['timestamp']);
      } else {
        timestamp = (data['timestamp'] as Timestamp).toDate();
      }

      String formattedTimestamp =
          DateFormat('yyyy-MM-dd HH:mm:ss').format(timestamp);

      List<dynamic> rowData = [
        formattedTimestamp,
        data['breathRate'],
        data['heartRate'],
        data['humidity'],
        data['temperature'],
      ];

      csvData.add(rowData);
    });

    return csvData;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Previous Values'),
        actions: [
          IconButton(
            icon: Icon(Icons.save),
            onPressed: () async {
              var status = await Permission.storage.request();
              if (status.isGranted) {
                QuerySnapshot<Map<String, dynamic>> snapshot =
                    await FirebaseFirestore.instance
                        .collection('users')
                        .doc(userId)
                        .collection('userHistory')
                        .orderBy('timestamp', descending: true)
                        .get();

                List<List<dynamic>> csvData = _prepareCsvData(snapshot);

                await _saveCsvFile(csvData);
              } else {
                // Handle the case where permission is not granted
                print('Permission not granted to save CSV file');
              }
            },
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .collection('userHistory')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.data == null || snapshot.data!.docs.isEmpty) {
            return Center(child: Text('No previous values available'));
          }

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: ListView.builder(
              itemCount: snapshot.data!.docs.length,
              itemBuilder: (context, index) {
                DocumentSnapshot userHistory = snapshot.data!.docs[index];
                Map<String, dynamic> data =
                    userHistory.data() as Map<String, dynamic>;

                DateTime timestamp;
                if (data['timestamp'] is String) {
                  timestamp = DateTime.parse(data['timestamp']);
                } else {
                  timestamp = (data['timestamp'] as Timestamp).toDate();
                }

                String formattedTimestamp =
                    DateFormat('yyyy-MM-dd HH:mm:ss').format(timestamp);

                return Card(
                  margin: EdgeInsets.symmetric(vertical: 8),
                  elevation: 2,
                  child: ListTile(
                    title: Text('Timestamp: $formattedTimestamp'),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Breath Rate: ${data['breathRate']}'),
                        Text('Heart Rate: ${data['heartRate']}'),
                        Text('Humidity: ${data['humidity']}'),
                        Text('Temperature: ${data['temperature']}'),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

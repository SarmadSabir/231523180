import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:vr/screens/AddDeviceScreen.dart';

class DeviceScreen extends StatefulWidget {
  @override
  _DeviceScreenState createState() => _DeviceScreenState();
}

class _DeviceScreenState extends State<DeviceScreen> {
  late Stream<QuerySnapshot<Map<String, dynamic>>> _devicesStream;

  @override
  void initState() {
    super.initState();
    _devicesStream =
        FirebaseFirestore.instance.collection('devices').snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Devices'),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _devicesStream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(
              child: Text('Error loading devices'),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final devices = snapshot.data!.docs;

          return ListView.builder(
            itemCount: devices.length,
            itemBuilder: (context, index) {
              final device = devices[index];
              final deviceName = device['deviceName'];
              final status = device['status'];

              return ListTile(
                title: Text(deviceName),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Status: $status'),
                    Text('Serial Number: ${device['serialNumber']}'),
                  ],
                ),
                trailing: IconButton(
                  icon: Icon(Icons.delete),
                  onPressed: () {
                    deleteDevice(
                        context, device.id); // Pass context to the function
                  },
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Pass context to AddDeviceScreen
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddDeviceScreen(context: context),
            ),
          );
        },
        child: Icon(Icons.add),
      ),
    );
  }

  void deleteDevice(BuildContext context, String deviceId) async {
    try {
      await FirebaseFirestore.instance
          .collection('devices')
          .doc(deviceId)
          .delete();

      // Show success message to the user
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Device deleted successfully!'),
        ),
      );
    } catch (error) {
      // Show error message to the user
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to delete device: $error'),
        ),
      );
    }
  }
}

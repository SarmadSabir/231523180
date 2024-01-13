import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AddDeviceScreen extends StatelessWidget {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _serialNumberController = TextEditingController();
  final BuildContext context; // Add this line

  AddDeviceScreen({required this.context});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add New Device'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Device Name'),
            ),
            TextField(
              controller: _serialNumberController,
              decoration: const InputDecoration(labelText: 'Serial Number'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // Validate input and add the device to Firestore
                final deviceName = _nameController.text.trim();
                final serialNumber = _serialNumberController.text.trim();

                if (deviceName.isNotEmpty && serialNumber.isNotEmpty) {
                  addDevice(deviceName, serialNumber);
                  Navigator.pop(context);
                } else {
                  // Handle validation error
                  // You can show a snackbar or any other feedback to the user
                }
              },
              child: const Text('Add Device'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> addDevice(String deviceName, String serialNumber) async {
    try {
      await FirebaseFirestore.instance.collection('devices').add({
        'deviceName': deviceName,
        'serialNumber': serialNumber,
        'status': 'Offline', // You can set an initial status if needed
      });

      // Show success message to the user
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Device added successfully!'),
        ),
      );
    } catch (error) {
      // Show error message to the user
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to add device: $error'),
        ),
      );
    }
  }
}

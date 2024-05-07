import 'package:flutter/material.dart';
import 'package:get/get.dart';

class DeviceInfoBottomSheet extends StatelessWidget {
  final List<Map<String, dynamic>> devices;
  final Function(Map<String, dynamic>) onDeviceSelected;
  final ScrollController? scrollController;
  final VoidCallback rebuildParent;
  final Function(String, String) onDeviceRename;

  const DeviceInfoBottomSheet({
    super.key,
    required this.devices,
    required this.onDeviceSelected,
    required this.scrollController,
    required this.rebuildParent,
    required this.onDeviceRename,
  });

  void _showRenameDeviceDialog(
      BuildContext context, String currentName, String macAddress) {
    Get.defaultDialog(
      title: 'Rename Device',
      content: TextField(
        controller: TextEditingController(text: currentName),
        onChanged: (value) {
          currentName = value;
        },
        decoration: const InputDecoration(
          hintText: 'Enter new device name',
          border: OutlineInputBorder(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Get.back(),
          child: const Text(
            'Cancel',
            style: TextStyle(
              fontFamily: 'Montserrat',
              fontSize: 16,
            ),
          ),
        ),
        ElevatedButton(
          onPressed: () {
            onDeviceRename(currentName, macAddress);
            Get.back();
          },
          child: const Text(
            'Rename',
            style: TextStyle(
              fontFamily: 'Montserrat',
              fontSize: 16,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 0,
      child: Container(
        decoration: const BoxDecoration(
          color: Color(0xFF1F1F1F),
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(20),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 16),
            const Text(
              'Connected Devices',
              style: TextStyle(
                fontFamily: 'Montserrat',
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: devices.isNotEmpty
                  ? ListView.builder(
                      shrinkWrap: true,
                      itemCount: devices.length,
                      itemBuilder: (context, index) {
                        final deviceData = devices[index];
                        return ListTile(
                          title: Text(
                            deviceData['name'] ?? 'Unknown Device',
                            style: const TextStyle(
                              fontFamily: 'Montserrat',
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Colors.white,
                            ),
                          ),
                          subtitle: Text(
                            deviceData['macAddress'] ?? 'Unknown MAC Address',
                            style: const TextStyle(
                              fontFamily: 'Montserrat',
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                              color: Colors.white70,
                            ),
                          ),
                          trailing: IconButton(
                            onPressed: () {
                              _showRenameDeviceDialog(context,
                                  deviceData['name'], deviceData['macAddress']);
                            },
                            icon: const Icon(Icons.edit),
                            color: Colors.white,
                          ),
                          onTap: () {
                            onDeviceSelected(deviceData);
                          },
                        );
                      },
                    )
                  : const Center(
                      child: Text(
                        'No devices found',
                        style: TextStyle(
                          fontFamily: 'Enriqueta',
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                        ),
                      ),
                    ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton.icon(
                onPressed: () {
                  rebuildParent();
                },
                icon: const Icon(
                  Icons.add,
                  color: Colors.white,
                ),
                label: const Text(
                  'Add Device',
                  style: TextStyle(
                      fontFamily: 'Enriqueta',
                      fontSize: 16,
                      color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3F51B5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

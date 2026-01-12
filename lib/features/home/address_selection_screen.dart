import 'package:eatify/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/address_provider.dart';
import '../../services/location_service.dart';
import '../../models/address_model.dart';

class AddressSelectionScreen extends ConsumerWidget {
  const AddressSelectionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final addressCtrl = TextEditingController();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Delivery Address'),
        backgroundColor: AppTheme.primary,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // ===== Manual Address Section =====
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'Enter Address Manually',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: addressCtrl,
                        decoration: InputDecoration(
                          hintText: 'e.g., 123 Main St, Cairo',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          prefixIcon: const Icon(Icons.location_on),
                        ),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: const Text(
                          'Use this address',
                          style: TextStyle(fontSize: 16),
                        ),
                        onPressed: () {
                          if (addressCtrl.text.isEmpty) return;

                          ref
                              .read(selectedAddressProvider.notifier)
                              .state = Address(
                            label: addressCtrl.text,
                            latitude: 30.0444,
                            longitude: 31.2357,
                          );

                          Navigator.pop(context);
                        },
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 30),

              // ===== Current Location Section =====
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'Use Current Location',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.my_location),
                        label: const Text(
                          'Use Current Location',
                          style: TextStyle(fontSize: 16),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        onPressed: () async {
                          try {
                            final position =
                                await LocationService.getCurrentLocation();

                            ref
                                .read(selectedAddressProvider.notifier)
                                .state = Address(
                              label: 'Current Location',
                              latitude: position.latitude,
                              longitude: position.longitude,
                            );

                            Navigator.pop(context);
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(e.toString())),
                            );
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

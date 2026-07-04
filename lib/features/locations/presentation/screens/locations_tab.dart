import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cinex_application/features/locations/providers/location_provider.dart';
import 'package:cinex_application/shared/widgets/empty_state_widget.dart';
import '../widgets/location_tile.dart';
import 'location_form_screen.dart';

class LocationsTab extends StatefulWidget {
  const LocationsTab({super.key});

  @override
  State<LocationsTab> createState() => _LocationsTabState();
}

class _LocationsTabState extends State<LocationsTab> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LocationProvider>().loadLocations();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<LocationProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (provider.locations.isEmpty) {
            return EmptyStateWidget(
              icon: Icons.location_off_outlined,
              message: 'Chưa có bối cảnh nào.\nBấm nút + để thêm bối cảnh đầu tiên.',
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: provider.locations.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final loc = provider.locations[i];
              return LocationTile(
                location: loc,
                onTap: () => _openForm(context, location: loc),
                onDelete: () async {
                  await provider.removeLocation(loc.id!);
                },
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'add_location_fab',
        onPressed: () => _openForm(context),
        child: const Icon(Icons.add_location_outlined),
      ),
    );
  }

  void _openForm(BuildContext context, {location}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LocationFormScreen(
          location: location,
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../theme/industrial_tokens.dart';
import '../../widgets/app_top_bar.dart';
import '../../widgets/industrial/neo_card.dart';

const LatLng kOcpSafiCenter = LatLng(32.2240955, -9.2590526);
const double kOcpSafiZoom = 16;

class IncidentLocationPickerPage extends StatefulWidget {
  const IncidentLocationPickerPage({super.key, this.initialLocation});

  final LatLng? initialLocation;

  @override
  State<IncidentLocationPickerPage> createState() =>
      _IncidentLocationPickerPageState();
}

class _IncidentLocationPickerPageState extends State<IncidentLocationPickerPage> {
  LatLng? _selected;
  bool _locating = false;
  GoogleMapController? _mapController;

  @override
  void initState() {
    super.initState();
    _selected = widget.initialLocation;
  }

  Future<void> _useCurrentLocation() async {
    setState(() => _locating = true);
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Permission de localisation refusée.')),
        );
        return;
      }
      final pos = await Geolocator.getCurrentPosition();
      final target = LatLng(pos.latitude, pos.longitude);
      if (!mounted) return;
      setState(() => _selected = target);
      await _mapController?.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: target, zoom: kOcpSafiZoom),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erreur GPS: $e')));
    } finally {
      if (mounted) {
        setState(() => _locating = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final marker = _selected;
    return Scaffold(
      appBar: const AppTopBar(title: 'Choisir localisation'),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            NeoCard(
              padding: const EdgeInsets.all(10),
              child: SizedBox(
                height: 360,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: GoogleMap(
                    initialCameraPosition: const CameraPosition(
                      target: kOcpSafiCenter,
                      zoom: kOcpSafiZoom,
                    ),
                    myLocationEnabled: true,
                    myLocationButtonEnabled: false,
                    onMapCreated: (controller) => _mapController = controller,
                    onTap: (pos) => setState(() => _selected = pos),
                    markers:
                        marker == null
                            ? {}
                            : {
                              Marker(
                                markerId: const MarkerId('incident_location'),
                                position: marker,
                              ),
                            },
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: _locating ? null : _useCurrentLocation,
              icon:
                  _locating
                      ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                      : const Icon(Icons.my_location_rounded),
              label: const Text('Ma position actuelle'),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed:
                  marker == null ? null : () => Navigator.of(context).pop(marker),
              icon: const Icon(Icons.check_rounded),
              label: const Text('Valider la localisation'),
              style: OutlinedButton.styleFrom(
                foregroundColor: IndustrialTokens.neon,
                side: const BorderSide(color: IndustrialTokens.neonMuted),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

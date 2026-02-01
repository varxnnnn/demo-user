import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:uuid/uuid.dart';
import '../providers/place_api_provider.dart';
import '../widgets/address_search.dart';

class LocationResult {
  final String address;
  final LatLng coordinates;
  
  LocationResult(this.address, this.coordinates);
}

class AddressSearchScreen extends StatefulWidget {
  const AddressSearchScreen({Key? key}) : super(key: key);

  @override
  _AddressSearchScreenState createState() => _AddressSearchScreenState();
}

class _AddressSearchScreenState extends State<AddressSearchScreen> {
  final _controller = TextEditingController();
  bool _hasAddress = false;
  String _streetNumber = '';
  String _street = '';
  String _city = '';
  String _province = '';
  String _postalCode = '';
  double? _latitude;
  double? _longitude;
  bool _isSaveLoading = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('Search Address'),
        ),
        body: Container(
          margin: const EdgeInsets.only(left: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.only(top: 8, right: 16),
                child: TextField(
                  controller: _controller,
                  readOnly: true,
                  onTap: () async {
                    // generate a new token here
                    final sessionToken = const Uuid().v4();
                    final result = await showSearch(
                      context: context,
                      delegate: AddressSearch(sessionToken),
                    );
                    // This will change the text displayed in the TextField
                    if (result != null) {
                      final placeDetails = await PlaceApiProvider(sessionToken)
                          .getPlaceDetailFromId(result.placeId);
                      setState(() {
                        _controller.text = result.description;
                        _hasAddress = (_controller.text.trim().isNotEmpty);
                        _streetNumber = placeDetails.streetNumber ?? '';
                        _street = placeDetails.street ?? '';
                        _city = placeDetails.city ?? '';
                        _province = placeDetails.province ?? '';
                        _postalCode = placeDetails.postalCode ?? '';
                        _latitude = placeDetails.latitude;
                        _longitude = placeDetails.longitude;
                      });
                    }
                  },
                  decoration: const InputDecoration(
                    icon: Icon(
                      Icons.search,
                      color: Colors.black,
                    ),
                    hintText: "Enter your address",
                  ),
                ),
              ),
              const SizedBox(height: 20.0),
              Text('Street Number: $_streetNumber'),
              Text('Street: $_street'),
              Text('City: $_city'),
              Text('Province: $_province'),
              Text('Postal Code: $_postalCode'),
              const SizedBox(height: 20.0),
              Center(
                child: _isSaveLoading
                    ? const CircularProgressIndicator()
                    : ElevatedButton(
                        onPressed: !_hasAddress
                            ? null
                            : () async {
                                setState(() {
                                  _isSaveLoading = true;
                                });
                                try {
                                  if (_latitude != null && _longitude != null) {
                                    final LocationResult text2location =
                                        LocationResult(_controller.text,
                                            LatLng(_latitude!, _longitude!));
                                    setState(() {
                                      _isSaveLoading = false;
                                    });
                                    Navigator.pop(context, text2location);
                                  } else {
                                    setState(() {
                                      _isSaveLoading = false;
                                    });
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                            'Coordinates not available for this address.'),
                                        duration: Duration(seconds: 2),
                                      ),
                                    );
                                  }
                                } catch (e) {
                                  setState(() {
                                    _isSaveLoading = false;
                                  });
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Error: ${e.toString()}'),
                                      duration: const Duration(seconds: 2),
                                    ),
                                  );
                                }
                              },
                        child: const Text('Save'),
                      ),
              ),
            ],
          ),
        ));
  }
}
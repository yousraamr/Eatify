import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/address_model.dart';

final selectedAddressProvider = StateProvider<Address?>((ref) => null);

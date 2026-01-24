import 'package:flutter/foundation.dart';
import '../models/marketplace/fish_listing_model.dart';

class FishMarketplaceService extends ChangeNotifier {
  final List<FishListing> _listings = [];
  bool _isLoading = false;
  String? _error;

  List<FishListing> get listings => List.unmodifiable(_listings);
  List<FishListing> get availableListings =>
      _listings.where((l) => l.status == ListingStatus.available).toList();
  bool get isLoading => _isLoading;
  String? get error => _error;

  FishMarketplaceService() {
    _loadSampleData();
  }

  void _loadSampleData() {
    final sampleSeller1 = SellerInfo(
      id: 'seller_1',
      name: 'Ahmed Al-Bahrani',
      phone: '+973 3344 5566',
      location: 'Sitra Fish Market',
      rating: 4.8,
      totalSales: 156,
    );

    final sampleSeller2 = SellerInfo(
      id: 'seller_2',
      name: 'Mohammed Fisherman',
      phone: '+973 3322 1100',
      location: 'Muharraq Harbor',
      rating: 4.5,
      totalSales: 89,
    );

    final sampleSeller3 = SellerInfo(
      id: 'seller_3',
      name: 'Khalid Sea Catch',
      phone: '+973 3399 8877',
      location: 'Hidd Port',
      rating: 4.9,
      totalSales: 234,
    );

    _listings.addAll([
      FishListing(
        id: 'fish_1',
        fishType: FishType.hamour,
        weight: 3.5,
        pricePerKg: 8.5,
        condition: FishCondition.fresh,
        acceptedPayments: [PaymentMethod.cash, PaymentMethod.benefitPay],
        description: 'Fresh Hamour caught this morning from Bahrain waters.',
        seller: sampleSeller1,
        listedAt: DateTime.now().subtract(const Duration(hours: 2)),
        catchLocation: 'North Sea of Bahrain',
        catchDate: DateTime.now().subtract(const Duration(hours: 4)),
      ),
      FishListing(
        id: 'fish_2',
        fishType: FishType.shaari,
        weight: 2.0,
        pricePerKg: 7.0,
        condition: FishCondition.fresh,
        acceptedPayments: [PaymentMethod.cash],
        description: 'Medium-sized Shaari, perfect for grilling.',
        seller: sampleSeller2,
        listedAt: DateTime.now().subtract(const Duration(hours: 5)),
        catchLocation: 'East Coast',
        catchDate: DateTime.now().subtract(const Duration(hours: 6)),
      ),
      FishListing(
        id: 'fish_3',
        fishType: FishType.shrimp,
        weight: 1.5,
        pricePerKg: 12.0,
        condition: FishCondition.cleaned,
        acceptedPayments: [PaymentMethod.cash, PaymentMethod.benefitPay],
        description: 'Premium jumbo shrimp, cleaned and ready to cook.',
        seller: sampleSeller3,
        listedAt: DateTime.now().subtract(const Duration(hours: 1)),
        catchLocation: 'Fasht Al-Adham',
        catchDate: DateTime.now().subtract(const Duration(hours: 3)),
      ),
      FishListing(
        id: 'fish_4',
        fishType: FishType.kingfish,
        weight: 5.0,
        pricePerKg: 9.5,
        condition: FishCondition.fresh,
        acceptedPayments: [PaymentMethod.benefitPay],
        description: 'Large Kingfish, excellent for steaks.',
        seller: sampleSeller1,
        listedAt: DateTime.now().subtract(const Duration(hours: 3)),
        catchLocation: 'Hawar Islands',
        catchDate: DateTime.now().subtract(const Duration(hours: 5)),
      ),
      FishListing(
        id: 'fish_5',
        fishType: FishType.safi,
        weight: 1.2,
        pricePerKg: 5.5,
        condition: FishCondition.fresh,
        acceptedPayments: [PaymentMethod.cash, PaymentMethod.benefitPay],
        description: 'Small but delicious Safi, local favorite.',
        seller: sampleSeller2,
        listedAt: DateTime.now().subtract(const Duration(hours: 4)),
        catchLocation: 'Budaiya Coast',
        catchDate: DateTime.now().subtract(const Duration(hours: 5)),
      ),
      FishListing(
        id: 'fish_6',
        fishType: FishType.crab,
        weight: 2.5,
        pricePerKg: 15.0,
        condition: FishCondition.fresh,
        acceptedPayments: [PaymentMethod.cash],
        description: 'Live blue crabs, very fresh!',
        seller: sampleSeller3,
        listedAt: DateTime.now().subtract(const Duration(minutes: 30)),
        catchLocation: 'Tubli Bay',
        catchDate: DateTime.now().subtract(const Duration(hours: 1)),
      ),
    ]);
  }

  Future<void> refreshListings() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await Future.delayed(const Duration(seconds: 1));
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to refresh listings: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addListing(FishListing listing) async {
    _isLoading = true;
    notifyListeners();

    try {
      await Future.delayed(const Duration(milliseconds: 500));
      _listings.insert(0, listing);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to add listing: $e';
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> updateListingStatus(String listingId, ListingStatus status) async {
    final index = _listings.indexWhere((l) => l.id == listingId);
    if (index != -1) {
      _listings[index] = _listings[index].copyWith(status: status);
      notifyListeners();
    }
  }

  Future<void> removeListing(String listingId) async {
    _listings.removeWhere((l) => l.id == listingId);
    notifyListeners();
  }

  List<FishListing> filterByType(FishType type) {
    return availableListings.where((l) => l.fishType == type).toList();
  }

  List<FishListing> filterByPriceRange(double minPrice, double maxPrice) {
    return availableListings
        .where((l) => l.pricePerKg >= minPrice && l.pricePerKg <= maxPrice)
        .toList();
  }

  List<FishListing> filterByCondition(FishCondition condition) {
    return availableListings.where((l) => l.condition == condition).toList();
  }

  List<FishListing> filterByPaymentMethod(PaymentMethod method) {
    return availableListings
        .where((l) => l.acceptedPayments.contains(method))
        .toList();
  }

  List<FishListing> searchListings(String query) {
    final lowerQuery = query.toLowerCase();
    return availableListings.where((l) {
      return l.displayName.toLowerCase().contains(lowerQuery) ||
          l.fishType.arabicName.contains(query) ||
          (l.description?.toLowerCase().contains(lowerQuery) ?? false) ||
          l.seller.name.toLowerCase().contains(lowerQuery) ||
          (l.catchLocation?.toLowerCase().contains(lowerQuery) ?? false);
    }).toList();
  }

  FishListing? getListingById(String id) {
    try {
      return _listings.firstWhere((l) => l.id == id);
    } catch (e) {
      return null;
    }
  }
}

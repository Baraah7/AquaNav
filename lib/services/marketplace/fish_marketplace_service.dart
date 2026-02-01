import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart' hide Order;
import '../../models/marketplace/fish_listing_model.dart';
import '../../models/marketplace/order_model.dart';

class FishMarketplaceService extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  List<FishListing> _listings = [];
  List<Order> _orders = [];
  String? _currentUserId;
  bool _isLoading = false;
  String? _error;

  StreamSubscription<QuerySnapshot>? _listingsSubscription;
  StreamSubscription<QuerySnapshot>? _ordersSubscription;

  List<FishListing> get listings => List.unmodifiable(_listings);
  List<FishListing> get availableListings =>
      _listings.where((l) => l.status == ListingStatus.available).toList();
  List<Order> get orders => List.unmodifiable(_orders);

  List<Order> get sellerOrders => _orders
      .where((o) => o.sellerId == _currentUserId)
      .toList();

  List<Order> get buyerOrders => _orders
      .where((o) => o.buyerId == _currentUserId)
      .toList();

  List<Order> get pendingSellerOrders => sellerOrders
      .where((o) => o.status == OrderStatus.pending)
      .toList();

  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get currentUserId => _currentUserId;

  void setCurrentUser(String userId) {
    _currentUserId = userId;
    _startListeningToOrders();
    notifyListeners();
  }

  FishMarketplaceService() {
    _startListeningToListings();
  }

  void _startListeningToListings() {
    _listingsSubscription?.cancel();
    _listingsSubscription = _db
        .collection('listings')
        .orderBy('listedAt', descending: true)
        .snapshots()
        .listen(
      (snapshot) {
        _listings = snapshot.docs
            .map((doc) => FishListing.fromFirestore(doc))
            .toList();
        notifyListeners();
      },
      onError: (error) {
        _error = 'Failed to load listings: $error';
        notifyListeners();
      },
    );
  }

  void _startListeningToOrders() {
    if (_currentUserId == null) return;

    _ordersSubscription?.cancel();

    // Listen to orders where current user is either buyer or seller
    _ordersSubscription = _db
        .collection('orders')
        .orderBy('orderedAt', descending: true)
        .snapshots()
        .listen(
      (snapshot) {
        _orders = snapshot.docs
            .map((doc) => Order.fromFirestore(doc))
            .where((order) =>
                order.buyerId == _currentUserId ||
                order.sellerId == _currentUserId)
            .toList();
        notifyListeners();
      },
      onError: (error) {
        _error = 'Failed to load orders: $error';
        notifyListeners();
      },
    );
  }

  Future<void> refreshListings() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final snapshot = await _db
          .collection('listings')
          .orderBy('listedAt', descending: true)
          .get();

      _listings = snapshot.docs
          .map((doc) => FishListing.fromFirestore(doc))
          .toList();

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
      await _db.collection('listings').add(listing.toFirestore());
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
    try {
      await _db.collection('listings').doc(listingId).update({
        'status': status.name,
      });
    } catch (e) {
      _error = 'Failed to update listing status: $e';
      notifyListeners();
    }
  }

  Future<void> removeListing(String listingId) async {
    try {
      await _db.collection('listings').doc(listingId).delete();
    } catch (e) {
      _error = 'Failed to remove listing: $e';
      notifyListeners();
    }
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
          l.sellerName.toLowerCase().contains(lowerQuery) ||
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

  Future<FishListing?> fetchListingById(String id) async {
    try {
      final doc = await _db.collection('listings').doc(id).get();
      if (doc.exists) {
        return FishListing.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      _error = 'Failed to fetch listing: $e';
      return null;
    }
  }

  // Order Management
  Future<Order> createOrder({
    required FishListing listing,
    required String buyerId,
    required String buyerName,
    required String buyerPhone,
    String? buyerLocation,
    required PaymentMethod paymentMethod,
    String? paymentProofImageUrl,
  }) async {
    final orderData = {
      'listingId': listing.id,
      'sellerId': listing.sellerId,
      'buyerId': buyerId,
      'buyerName': buyerName,
      'buyerPhone': buyerPhone,
      'buyerLocation': buyerLocation,
      'paymentMethod': paymentMethod.name,
      'paymentProofImageUrl': paymentProofImageUrl,
      'orderedAt': Timestamp.now(),
      'status': OrderStatus.pending.name,
      'sellerNote': null,
      'rejectionReason': null,
      'respondedAt': null,
    };

    final docRef = await _db.collection('orders').add(orderData);
    await updateListingStatus(listing.id, ListingStatus.reserved);

    return Order(
      id: docRef.id,
      listingId: listing.id,
      sellerId: listing.sellerId,
      buyerId: buyerId,
      buyerName: buyerName,
      buyerPhone: buyerPhone,
      buyerLocation: buyerLocation,
      paymentMethod: paymentMethod,
      paymentProofImageUrl: paymentProofImageUrl,
      orderedAt: DateTime.now(),
    );
  }

  Future<void> acceptOrder(String orderId, {String? note}) async {
    try {
      await _db.collection('orders').doc(orderId).update({
        'status': OrderStatus.accepted.name,
        'sellerNote': note,
        'respondedAt': Timestamp.now(),
      });
    } catch (e) {
      _error = 'Failed to accept order: $e';
      notifyListeners();
    }
  }

  Future<void> rejectOrder(String orderId, {String? reason}) async {
    try {
      final orderDoc = await _db.collection('orders').doc(orderId).get();
      if (orderDoc.exists) {
        final listingId = orderDoc.data()!['listingId'] as String;

        await _db.collection('orders').doc(orderId).update({
          'status': OrderStatus.rejected.name,
          'rejectionReason': reason,
          'respondedAt': Timestamp.now(),
        });

        // Make the listing available again
        await updateListingStatus(listingId, ListingStatus.available);
      }
    } catch (e) {
      _error = 'Failed to reject order: $e';
      notifyListeners();
    }
  }

  Future<void> completeOrder(String orderId) async {
    try {
      final orderDoc = await _db.collection('orders').doc(orderId).get();
      if (orderDoc.exists) {
        final listingId = orderDoc.data()!['listingId'] as String;

        await _db.collection('orders').doc(orderId).update({
          'status': OrderStatus.completed.name,
          'respondedAt': Timestamp.now(),
        });

        await updateListingStatus(listingId, ListingStatus.sold);

        // Update seller's total sales
        final sellerId = orderDoc.data()!['sellerId'] as String;
        await _db.collection('users').doc(sellerId).update({
          'total_sales': FieldValue.increment(1),
        });
      }
    } catch (e) {
      _error = 'Failed to complete order: $e';
      notifyListeners();
    }
  }

  Order? getOrderById(String id) {
    try {
      return _orders.firstWhere((o) => o.id == id);
    } catch (e) {
      return null;
    }
  }

  List<Order> getOrdersForListing(String listingId) {
    return _orders.where((o) => o.listingId == listingId).toList();
  }

  List<FishListing> getSellerListings(String sellerId) {
    return _listings.where((l) => l.sellerId == sellerId).toList();
  }

  @override
  void dispose() {
    _listingsSubscription?.cancel();
    _ordersSubscription?.cancel();
    super.dispose();
  }
}

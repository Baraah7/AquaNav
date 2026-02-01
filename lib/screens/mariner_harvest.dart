import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/marketplace/fish_listing_model.dart';
import '../models/marketplace/order_model.dart';
import '../services/marketplace/fish_marketplace_service.dart';
import '../l10n/app_localizations.dart';
import '../widgets/marketplace/sell_fish_form.dart';
import '../widgets/marketplace/fish_details_sheet.dart';
import '../providers/authentication_provider.dart';

class MarinerHarvestPage extends ConsumerStatefulWidget {
  const MarinerHarvestPage({super.key});

  @override
  ConsumerState<MarinerHarvestPage> createState() => _MarinerHarvestPageState();
}

class _MarinerHarvestPageState extends ConsumerState<MarinerHarvestPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late FishMarketplaceService _marketplaceService;
  FishType? _selectedTypeFilter;
  FishCondition? _selectedConditionFilter;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _marketplaceService = FishMarketplaceService();

    // Listen to marketplace changes to update UI in real-time
    _marketplaceService.addListener(_onMarketplaceUpdate);

    // Initialize marketplace service with current user after build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeUserData();
    });
  }

  void _onMarketplaceUpdate() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _initializeUserData() async {
    final authProvider = ref.read(authProviderProvider);

    // Ensure user profile is loaded if there's an existing Firebase session
    await authProvider.initializeAuthState();

    final user = authProvider.currentAppUser;
    if (user != null) {
      _marketplaceService.setCurrentUser(user.id);
    }
  }

  @override
  void dispose() {
    _marketplaceService.removeListener(_onMarketplaceUpdate);
    _marketplaceService.dispose();
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  List<FishListing> get _filteredListings {
    var listings = _marketplaceService.availableListings;

    if (_searchQuery.isNotEmpty) {
      listings = _marketplaceService.searchListings(_searchQuery);
    }
    if (_selectedTypeFilter != null) {
      listings = listings.where((l) => l.fishType == _selectedTypeFilter).toList();
    }
    if (_selectedConditionFilter != null) {
      listings = listings.where((l) => l.condition == _selectedConditionFilter).toList();
    }

    return listings;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text(
          l10n.marinerHarvest,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color.fromARGB(255, 22, 62, 98),
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: [
            Tab(icon: const Icon(Icons.storefront), text: l10n.marketplace),
            Tab(icon: const Icon(Icons.add_business), text: l10n.sellFish),
            Tab(icon: const Icon(Icons.receipt_long), text: l10n.myOrders),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildMarketplaceTab(l10n),
          _buildSellFishTab(l10n),
          _buildSellerOrdersTab(l10n),
        ],
      ),
    );
  }

  Widget _buildMarketplaceTab(AppLocalizations l10n) {
    return Column(
      children: [
        _buildSearchAndFilter(l10n),
        Expanded(
          child: _filteredListings.isEmpty
              ? _buildEmptyState(l10n)
              : RefreshIndicator(
                  onRefresh: _marketplaceService.refreshListings,
                  child: GridView.builder(
                    padding: const EdgeInsets.all(12),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.75,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    itemCount: _filteredListings.length,
                    itemBuilder: (context, index) {
                      return _buildFishCard(_filteredListings[index]);
                    },
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildSearchAndFilter(AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: l10n.searchFishSellerLocation,
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _searchQuery = '');
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: const Color(0xFFF5F7FA),
            ),
            onChanged: (value) => setState(() => _searchQuery = value),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip(
                  label: l10n.type,
                  value: _selectedTypeFilter?.displayName,
                  onTap: () => _showTypeFilterDialog(l10n),
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  label: l10n.condition,
                  value: _selectedConditionFilter?.displayName,
                  onTap: () => _showConditionFilterDialog(l10n),
                ),
                if (_selectedTypeFilter != null || _selectedConditionFilter != null) ...[
                  const SizedBox(width: 8),
                  ActionChip(
                    label: Text(l10n.clearFilters),
                    onPressed: () {
                      setState(() {
                        _selectedTypeFilter = null;
                        _selectedConditionFilter = null;
                      });
                    },
                    backgroundColor: Colors.red.shade50,
                    labelStyle: TextStyle(color: Colors.red.shade700),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    String? value,
    required VoidCallback onTap,
  }) {
    return ActionChip(
      label: Text(value != null ? '$label: $value' : label),
      onPressed: onTap,
      backgroundColor: value != null
          ? const Color.fromARGB(255, 22, 62, 98).withValues(alpha: 0.1)
          : Colors.grey.shade100,
      labelStyle: TextStyle(
        color: value != null
            ? const Color.fromARGB(255, 22, 62, 98)
            : Colors.grey.shade700,
      ),
    );
  }

  void _showTypeFilterDialog(AppLocalizations l10n) {
    showDialog(
      context: context,
      builder: (context) => SimpleDialog(
        title: Text(l10n.filterByFishType),
        children: [
          ListTile(
            title: Text(l10n.allTypes),
            onTap: () {
              setState(() => _selectedTypeFilter = null);
              Navigator.pop(context);
            },
          ),
          ...FishType.values.map((type) => ListTile(
                title: Text(type.displayName),
                subtitle: Text(type.arabicName),
                onTap: () {
                  setState(() => _selectedTypeFilter = type);
                  Navigator.pop(context);
                },
              )),
        ],
      ),
    );
  }

  void _showConditionFilterDialog(AppLocalizations l10n) {
    showDialog(
      context: context,
      builder: (context) => SimpleDialog(
        title: Text(l10n.filterByCondition),
        children: [
          ListTile(
            title: Text(l10n.allConditions),
            onTap: () {
              setState(() => _selectedConditionFilter = null);
              Navigator.pop(context);
            },
          ),
          ...FishCondition.values.map((condition) => ListTile(
                title: Text(condition.displayName),
                onTap: () {
                  setState(() => _selectedConditionFilter = condition);
                  Navigator.pop(context);
                },
              )),
        ],
      ),
    );
  }

  Widget _buildEmptyState(AppLocalizations l10n) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            l10n.noFishListingsFound,
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.tryAdjustingFilters,
            style: TextStyle(color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  Widget _buildFishCard(FishListing listing) {
    return GestureDetector(
      onTap: () => _showFishDetails(listing),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 100,
              decoration: BoxDecoration(
                gradient: listing.primaryImageUrl != null
                    ? null
                    : LinearGradient(
                        colors: [
                          const Color.fromARGB(255, 22, 62, 98),
                          const Color.fromARGB(255, 44, 100, 150),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                image: listing.primaryImageUrl != null
                    ? DecorationImage(
                        image: FileImage(File(listing.primaryImageUrl!)),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: listing.primaryImageUrl == null
                  ? Center(
                      child: Icon(
                        _getFishIcon(listing.fishType),
                        size: 48,
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                    )
                  : null,
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      listing.displayName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      listing.fishType.arabicName,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        _buildInfoBadge(
                          '${listing.weight.toStringAsFixed(1)} kg',
                          Icons.scale,
                        ),
                        const SizedBox(width: 4),
                        _buildInfoBadge(
                          listing.condition.displayName,
                          Icons.check_circle_outline,
                        ),
                      ],
                    ),
                    const Spacer(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${listing.pricePerKg.toStringAsFixed(1)} BD/kg',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: Color.fromARGB(255, 22, 62, 98),
                          ),
                        ),
                        Text(
                          '${listing.totalPrice.toStringAsFixed(2)} BD',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoBadge(String text, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: Colors.grey.shade600),
          const SizedBox(width: 2),
          Text(
            text,
            style: TextStyle(fontSize: 9, color: Colors.grey.shade700),
          ),
        ],
      ),
    );
  }

  IconData _getFishIcon(FishType type) {
    switch (type) {
      case FishType.shrimp:
        return Icons.set_meal;
      case FishType.crab:
        return Icons.pest_control;
      default:
        return Icons.phishing;
    }
  }

  void _showFishDetails(FishListing listing) {
    final authProvider = ref.read(authProviderProvider);
    final user = authProvider.currentAppUser;
    final fullName = user != null
        ? '${user.firstName ?? ''} ${user.lastName ?? ''}'.trim()
        : null;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => FishDetailsSheet(
        listing: listing,
        currentUserId: user?.id,
        currentUserName: fullName?.isNotEmpty == true ? fullName : user?.userName,
        currentUserPhone: user?.phone,
        currentUserLocation: user?.location,
        onBuy: (paymentMethod, buyerName, buyerPhone, buyerLocation, paymentProofImage) =>
          _processPurchase(listing, paymentMethod, buyerName, buyerPhone, buyerLocation, paymentProofImage),
      ),
    );
  }

  void _processPurchase(
    FishListing listing,
    PaymentMethod paymentMethod,
    String buyerName,
    String buyerPhone,
    String? buyerLocation,
    String? paymentProofImage,
  ) async {
    final authProvider = ref.read(authProviderProvider);
    final user = authProvider.currentAppUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please login to place an order'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    Navigator.pop(context);

    await _marketplaceService.createOrder(
      listing: listing,
      buyerId: user.id,
      buyerName: buyerName,
      buyerPhone: buyerPhone,
      buyerLocation: buyerLocation,
      paymentMethod: paymentMethod,
      paymentProofImageUrl: paymentProofImage,
    );

    if (mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green),
              SizedBox(width: 8),
              Text('Order Placed!'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('You have ordered ${listing.displayName}'),
              const SizedBox(height: 8),
              Text('Weight: ${listing.weight.toStringAsFixed(1)} kg'),
              Text('Total: ${listing.totalPrice.toStringAsFixed(2)} BD'),
              Text('Payment: ${paymentMethod.displayName}'),
              const SizedBox(height: 12),
              const Text(
                'Waiting for seller to accept your order.',
                style: TextStyle(fontStyle: FontStyle.italic),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                setState(() {});
              },
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildSellFishTab(AppLocalizations l10n) {
    final authProvider = ref.watch(authProviderProvider);
    final user = authProvider.currentAppUser;
    final fullName = user != null
        ? '${user.firstName ?? ''} ${user.lastName ?? ''}'.trim()
        : null;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: SellFishForm(
        currentUserId: user?.id,
        currentUserName: fullName?.isNotEmpty == true ? fullName : user?.userName,
        currentUserPhone: user?.phone,
        currentUserLocation: user?.location,
        onSubmit: (listing) async {
          await _marketplaceService.addListing(listing);
          _marketplaceService.setCurrentUser(listing.sellerId);
          setState(() {});
          _tabController.animateTo(0);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(l10n.yourFishListingPosted),
                backgroundColor: Colors.green,
              ),
            );
          }
        },
      ),
    );
  }

  Widget _buildSellerOrdersTab(AppLocalizations l10n) {
    final authProvider = ref.watch(authProviderProvider);
    final currentUserId = authProvider.currentAppUser?.id;

    if (currentUserId == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.login, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'Please login to view orders',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    final sellerOrders = _marketplaceService.orders
        .where((o) => o.sellerId == currentUserId)
        .toList();
    final buyerOrders = _marketplaceService.orders
        .where((o) => o.buyerId == currentUserId)
        .toList();

    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(12),
            ),
            child: TabBar(
              indicator: BoxDecoration(
                color: const Color.fromARGB(255, 22, 62, 98),
                borderRadius: BorderRadius.circular(12),
              ),
              labelColor: Colors.white,
              unselectedLabelColor: Colors.grey.shade700,
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              tabs: [
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.sell, size: 18),
                      const SizedBox(width: 8),
                      Text('Selling (${sellerOrders.length})'),
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.shopping_bag, size: 18),
                      const SizedBox(width: 8),
                      Text('Purchases (${buyerOrders.length})'),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              children: [
                _buildOrdersList(sellerOrders, l10n, isSeller: true),
                _buildOrdersList(buyerOrders, l10n, isSeller: false),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrdersList(List<Order> orders, AppLocalizations l10n, {required bool isSeller}) {
    if (orders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isSeller ? Icons.store_outlined : Icons.shopping_cart_outlined,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              isSeller ? 'No orders for your listings yet' : 'No purchases yet',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isSeller
                  ? 'When someone orders your fish, it will appear here'
                  : 'Your purchases will appear here',
              style: TextStyle(color: Colors.grey.shade500),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: orders.length,
      itemBuilder: (context, index) {
        return _buildOrderCard(orders[index], l10n, isSeller: isSeller);
      },
    );
  }

  Widget _buildOrderCard(Order order, AppLocalizations l10n, {required bool isSeller}) {
    Color statusColor;
    IconData statusIcon;

    switch (order.status) {
      case OrderStatus.pending:
        statusColor = Colors.orange;
        statusIcon = Icons.hourglass_empty;
        break;
      case OrderStatus.accepted:
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case OrderStatus.rejected:
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
        break;
      case OrderStatus.completed:
        statusColor = Colors.blue;
        statusIcon = Icons.done_all;
        break;
      case OrderStatus.cancelled:
        statusColor = Colors.grey;
        statusIcon = Icons.block;
        break;
    }

    final listing = _marketplaceService.getListingById(order.listingId);
    final listingName = listing?.displayName ?? 'Unknown Fish';
    final totalPrice = listing?.totalPrice ?? 0.0;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    listingName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusIcon, size: 14, color: statusColor),
                      const SizedBox(width: 4),
                      Text(
                        order.status.displayName,
                        style: TextStyle(
                          color: statusColor,
                          fontWeight: FontWeight.w500,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Show buyer info for sellers, seller info for buyers
            if (isSeller) ...[
              Row(
                children: [
                  Icon(Icons.person, size: 16, color: Colors.grey.shade600),
                  const SizedBox(width: 4),
                  Text('${l10n.buyer}: ${order.buyerName}'),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.phone, size: 16, color: Colors.grey.shade600),
                  const SizedBox(width: 4),
                  Text(order.buyerPhone),
                ],
              ),
              if (order.buyerLocation != null) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.location_on, size: 16, color: Colors.grey.shade600),
                    const SizedBox(width: 4),
                    Expanded(child: Text(order.buyerLocation!)),
                  ],
                ),
              ],
            ] else ...[
              Row(
                children: [
                  Icon(Icons.store, size: 16, color: Colors.grey.shade600),
                  const SizedBox(width: 4),
                  Text('Seller: ${listing?.sellerName ?? 'Unknown'}'),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.phone, size: 16, color: Colors.grey.shade600),
                  const SizedBox(width: 4),
                  Text(listing?.sellerPhone ?? 'N/A'),
                ],
              ),
            ],
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.payments, size: 16, color: Colors.grey.shade600),
                const SizedBox(width: 4),
                Text('${l10n.payment}: ${order.paymentMethod.displayName}'),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.attach_money, size: 16, color: Colors.grey.shade600),
                const SizedBox(width: 4),
                Text(
                  '${l10n.total}: ${totalPrice.toStringAsFixed(2)} BD',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            // Show payment proof for sellers only
            if (isSeller &&
                order.paymentMethod == PaymentMethod.benefitPay &&
                order.paymentProofImageUrl != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.receipt_long, size: 16, color: Colors.blue.shade700),
                        const SizedBox(width: 4),
                        Text(
                          l10n.paymentProof,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade700,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: () => _showPaymentProofFullScreen(order.paymentProofImageUrl!),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(
                          File(order.paymentProofImageUrl!),
                          height: 120,
                          width: double.infinity,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l10n.tapToViewFullImage,
                      style: TextStyle(
                        color: Colors.blue.shade400,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            // Show rejection reason for buyers if order was rejected
            if (!isSeller && order.status == OrderStatus.rejected && order.rejectionReason != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, size: 16, color: Colors.red.shade700),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Reason: ${order.rejectionReason}',
                        style: TextStyle(color: Colors.red.shade700, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            // Show status message for buyers
            if (!isSeller && order.status == OrderStatus.pending) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.hourglass_empty, size: 16, color: Colors.orange.shade700),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Waiting for seller to accept your order',
                        style: TextStyle(color: Colors.orange.shade700, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            // Show accept/reject buttons for sellers only
            if (isSeller && order.status == OrderStatus.pending) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _showRejectDialog(order, l10n),
                      icon: const Icon(Icons.close, color: Colors.red),
                      label: Text(l10n.reject),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _acceptOrder(order, l10n),
                      icon: const Icon(Icons.check),
                      label: Text(l10n.accept),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ],
            // Show complete button for sellers only
            if (isSeller && order.status == OrderStatus.accepted) ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _completeOrder(order, l10n),
                  icon: const Icon(Icons.done_all),
                  label: Text(l10n.markAsCompleted),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255, 22, 62, 98),
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
            // Show contact seller button for buyers when order is accepted
            if (!isSeller && order.status == OrderStatus.accepted) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.check_circle, size: 16, color: Colors.green.shade700),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Order accepted! Contact seller to arrange pickup.',
                        style: TextStyle(color: Colors.green.shade700, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _acceptOrder(Order order, AppLocalizations l10n) async {
    await _marketplaceService.acceptOrder(order.id);
    setState(() {});
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.orderAccepted),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _showRejectDialog(Order order, AppLocalizations l10n) {
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.rejectOrder),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(l10n.areYouSureRejectOrder),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: InputDecoration(
                labelText: l10n.reasonOptional,
                border: const OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _marketplaceService.rejectOrder(
                order.id,
                reason: reasonController.text.isEmpty ? null : reasonController.text,
              );
              setState(() {});
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(l10n.orderRejected),
                    backgroundColor: Colors.orange,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text(l10n.reject, style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _completeOrder(Order order, AppLocalizations l10n) async {
    await _marketplaceService.completeOrder(order.id);
    setState(() {});
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.orderCompleted),
          backgroundColor: Colors.blue,
        ),
      );
    }
  }

  void _showPaymentProofFullScreen(String imagePath) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.7,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Payment Proof',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close),
                        ),
                      ],
                    ),
                  ),
                  Flexible(
                    child: InteractiveViewer(
                      child: Image.file(
                        File(imagePath),
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

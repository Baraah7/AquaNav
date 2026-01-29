import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/marketplace/fish_listing_model.dart';
import '../models/marketplace/order_model.dart';
import '../services/fish_marketplace_service.dart';
import '../l10n/app_localizations.dart';

class MarinerHarvestPage extends StatefulWidget {
  const MarinerHarvestPage({super.key});

  @override
  State<MarinerHarvestPage> createState() => _MarinerHarvestPageState();
}

class _MarinerHarvestPageState extends State<MarinerHarvestPage>
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
  }

  @override
  void dispose() {
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
      case FishType.lobster:
        return Icons.pest_control;
      case FishType.squid:
        return Icons.water;
      default:
        return Icons.phishing;
    }
  }

  void _showFishDetails(FishListing listing) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => FishDetailsSheet(
        listing: listing,
        onBuy: (paymentMethod, buyerInfo, paymentProofImage) => _processPurchase(listing, paymentMethod, buyerInfo, paymentProofImage),
      ),
    );
  }

  void _processPurchase(FishListing listing, PaymentMethod paymentMethod, BuyerInfo buyerInfo, String? paymentProofImage) async {
    Navigator.pop(context);

    await _marketplaceService.createOrder(
      listing: listing,
      buyer: buyerInfo,
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
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: SellFishForm(
        onSubmit: (listing) async {
          await _marketplaceService.addListing(listing);
          _marketplaceService.setCurrentSeller(listing.seller.id);
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
    final orders = _marketplaceService.orders;

    if (orders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_outlined, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              l10n.noOrdersYet,
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.ordersWillAppearHere,
              style: TextStyle(color: Colors.grey.shade500),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: orders.length,
      itemBuilder: (context, index) {
        return _buildOrderCard(orders[index], l10n);
      },
    );
  }

  Widget _buildOrderCard(Order order, AppLocalizations l10n) {
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
                    order.listing.displayName,
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
            Row(
              children: [
                Icon(Icons.person, size: 16, color: Colors.grey.shade600),
                const SizedBox(width: 4),
                Text('${l10n.buyer}: ${order.buyer.name}'),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.phone, size: 16, color: Colors.grey.shade600),
                const SizedBox(width: 4),
                Text(order.buyer.phone),
              ],
            ),
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
                  '${l10n.total}: ${order.totalPrice.toStringAsFixed(2)} BD',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            if (order.paymentMethod == PaymentMethod.benefitPay &&
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
            if (order.status == OrderStatus.pending) ...[
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
            if (order.status == OrderStatus.accepted) ...[
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

class FishDetailsSheet extends StatefulWidget {
  final FishListing listing;
  final Function(PaymentMethod, BuyerInfo, String?) onBuy;

  const FishDetailsSheet({
    super.key,
    required this.listing,
    required this.onBuy,
  });

  @override
  State<FishDetailsSheet> createState() => _FishDetailsSheetState();
}

class _FishDetailsSheetState extends State<FishDetailsSheet> {
  PaymentMethod? _selectedPayment;
  final _buyerNameController = TextEditingController();
  final _buyerPhoneController = TextEditingController();
  final _buyerLocationController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final _imagePicker = ImagePicker();
  int _currentImageIndex = 0;
  String? _paymentProofImage;

  @override
  void dispose() {
    _buyerNameController.dispose();
    _buyerPhoneController.dispose();
    _buyerLocationController.dispose();
    super.dispose();
  }

  Future<void> _pickPaymentProofImage() async {
    final image = await _imagePicker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _paymentProofImage = image.path;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Form(
            key: _formKey,
            child: ListView(
              controller: scrollController,
              padding: const EdgeInsets.all(20),
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                _buildImageGallery(),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.listing.displayName,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          widget.listing.fishType.arabicName,
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        widget.listing.condition.displayName,
                        style: TextStyle(
                          color: Colors.green.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _buildDetailRow(
                  'Weight',
                  '${widget.listing.weight.toStringAsFixed(1)} kg',
                  Icons.scale,
                ),
                _buildDetailRow(
                  'Price per kg',
                  '${widget.listing.pricePerKg.toStringAsFixed(2)} BD',
                  Icons.payments,
                ),
                _buildDetailRow(
                  'Total Price',
                  '${widget.listing.totalPrice.toStringAsFixed(2)} BD',
                  Icons.receipt_long,
                  isHighlighted: true,
                ),
                if (widget.listing.catchLocation != null)
                  _buildDetailRow(
                    'Catch Location',
                    widget.listing.catchLocation!,
                    Icons.location_on,
                  ),
                if (widget.listing.catchDate != null)
                  _buildDetailRow(
                    'Catch Date',
                    _formatDate(widget.listing.catchDate!),
                    Icons.calendar_today,
                  ),
                const Divider(height: 32),
                const Text(
                  'Seller Information',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                _buildSellerCard(),
                const Divider(height: 32),
                if (widget.listing.description != null) ...[
                  const Text(
                    'Description',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.listing.description!,
                    style: TextStyle(
                      color: Colors.grey.shade700,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
                const Text(
                  'Your Information',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                _buildBuyerForm(),
                const SizedBox(height: 24),
                const Text(
                  'Select Payment Method',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                ...widget.listing.acceptedPayments.map((method) {
                  return _buildPaymentOption(method);
                }),
                if (_selectedPayment == PaymentMethod.benefitPay) ...[
                  const SizedBox(height: 16),
                  _buildPaymentProofUpload(),
                ],
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _selectedPayment != null ? _handleBuy : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromARGB(255, 22, 62, 98),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      _selectedPayment != null
                          ? 'Buy Now - ${widget.listing.totalPrice.toStringAsFixed(2)} BD'
                          : 'Select Payment Method',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: () => _contactSeller(),
                  icon: const Icon(Icons.phone),
                  label: const Text('Contact Seller'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildImageGallery() {
    if (widget.listing.imageUrls.isEmpty) {
      return Container(
        height: 200,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [
              Color.fromARGB(255, 22, 62, 98),
              Color.fromARGB(255, 44, 100, 150),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(
          child: Icon(Icons.phishing, size: 80, color: Colors.white),
        ),
      );
    }

    return Column(
      children: [
        Container(
          height: 200,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            image: DecorationImage(
              image: FileImage(File(widget.listing.imageUrls[_currentImageIndex])),
              fit: BoxFit.cover,
            ),
          ),
        ),
        if (widget.listing.imageUrls.length > 1) ...[
          const SizedBox(height: 8),
          SizedBox(
            height: 60,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: widget.listing.imageUrls.length,
              itemBuilder: (context, index) {
                return GestureDetector(
                  onTap: () => setState(() => _currentImageIndex = index),
                  child: Container(
                    width: 60,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: _currentImageIndex == index
                            ? const Color.fromARGB(255, 22, 62, 98)
                            : Colors.grey.shade300,
                        width: 2,
                      ),
                      image: DecorationImage(
                        image: FileImage(File(widget.listing.imageUrls[index])),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildBuyerForm() {
    return Column(
      children: [
        TextFormField(
          controller: _buyerNameController,
          decoration: InputDecoration(
            labelText: 'Your Name',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            prefixIcon: const Icon(Icons.person),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter your name';
            }
            return null;
          },
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _buyerPhoneController,
          decoration: InputDecoration(
            labelText: 'Phone Number',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            prefixIcon: const Icon(Icons.phone),
          ),
          keyboardType: TextInputType.phone,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter your phone number';
            }
            return null;
          },
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _buyerLocationController,
          decoration: InputDecoration(
            labelText: 'Delivery Location (optional)',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            prefixIcon: const Icon(Icons.location_on),
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentProofUpload() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.receipt_long, color: Colors.blue.shade700),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Upload Payment Proof',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade700,
                  ),
                ),
              ),
              Text(
                '* Required',
                style: TextStyle(
                  color: Colors.red.shade400,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Please upload a screenshot of your Benefit Pay payment',
            style: TextStyle(
              color: Colors.blue.shade600,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 12),
          if (_paymentProofImage != null) ...[
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.file(
                    File(_paymentProofImage!),
                    height: 150,
                    width: double.infinity,
                    fit: BoxFit.contain,
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: GestureDetector(
                    onTap: () => setState(() => _paymentProofImage = null),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.close, size: 16, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.check_circle, size: 16, color: Colors.green.shade600),
                const SizedBox(width: 4),
                Text(
                  'Payment proof uploaded',
                  style: TextStyle(
                    color: Colors.green.shade600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ] else
            GestureDetector(
              onTap: _pickPaymentProofImage,
              child: Container(
                height: 100,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade300, style: BorderStyle.solid),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add_photo_alternate, size: 32, color: Colors.blue.shade400),
                    const SizedBox(height: 8),
                    Text(
                      'Tap to upload screenshot',
                      style: TextStyle(
                        color: Colors.blue.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _handleBuy() {
    if (_formKey.currentState!.validate() && _selectedPayment != null) {
      // Require payment proof for Benefit Pay
      if (_selectedPayment == PaymentMethod.benefitPay && _paymentProofImage == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please upload your payment proof screenshot'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      final buyerInfo = BuyerInfo(
        id: 'buyer_${DateTime.now().millisecondsSinceEpoch}',
        name: _buyerNameController.text,
        phone: _buyerPhoneController.text,
        location: _buyerLocationController.text.isEmpty
            ? null
            : _buyerLocationController.text,
      );
      widget.onBuy(_selectedPayment!, buyerInfo, _paymentProofImage);
    }
  }

  Widget _buildDetailRow(String label, String value, IconData icon,
      {bool isHighlighted = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isHighlighted
                  ? const Color.fromARGB(255, 22, 62, 98).withValues(alpha: 0.1)
                  : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              size: 20,
              color: isHighlighted
                  ? const Color.fromARGB(255, 22, 62, 98)
                  : Colors.grey.shade600,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: isHighlighted ? FontWeight.bold : FontWeight.w500,
              fontSize: isHighlighted ? 18 : 14,
              color: isHighlighted
                  ? const Color.fromARGB(255, 22, 62, 98)
                  : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSellerCard() {
    final seller = widget.listing.seller;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: const Color.fromARGB(255, 22, 62, 98),
                child: Text(
                  seller.name[0].toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      seller.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    if (seller.location != null)
                      Text(
                        seller.location!,
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 13,
                        ),
                      ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.star, size: 16, color: Colors.amber),
                      const SizedBox(width: 4),
                      Text(
                        seller.rating.toStringAsFixed(1),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  Text(
                    '${seller.totalSales} sales',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentOption(PaymentMethod method) {
    final isSelected = _selectedPayment == method;
    return GestureDetector(
      onTap: () => setState(() => _selectedPayment = method),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color.fromARGB(255, 22, 62, 98).withValues(alpha: 0.1)
              : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? const Color.fromARGB(255, 22, 62, 98)
                : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              method == PaymentMethod.cash
                  ? Icons.money
                  : Icons.account_balance_wallet,
              color: isSelected
                  ? const Color.fromARGB(255, 22, 62, 98)
                  : Colors.grey.shade600,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    method.displayName,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: isSelected
                          ? const Color.fromARGB(255, 22, 62, 98)
                          : Colors.black87,
                    ),
                  ),
                  Text(
                    method == PaymentMethod.cash
                        ? 'Pay with cash on delivery'
                        : 'Pay instantly via Benefit Pay',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check_circle,
                color: Color.fromARGB(255, 22, 62, 98),
              ),
          ],
        ),
      ),
    );
  }

  void _contactSeller() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Contact Seller'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Name: ${widget.listing.seller.name}'),
            const SizedBox(height: 8),
            Text('Phone: ${widget.listing.seller.phone}'),
            if (widget.listing.seller.location != null) ...[
              const SizedBox(height: 8),
              Text('Location: ${widget.listing.seller.location}'),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inHours < 1) {
      return '${difference.inMinutes} min ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hours ago';
    } else {
      return '${difference.inDays} days ago';
    }
  }
}

class SellFishForm extends StatefulWidget {
  final Function(FishListing) onSubmit;

  const SellFishForm({super.key, required this.onSubmit});

  @override
  State<SellFishForm> createState() => _SellFishFormState();
}

class _SellFishFormState extends State<SellFishForm> {
  final _formKey = GlobalKey<FormState>();
  final _imagePicker = ImagePicker();

  FishType _selectedFishType = FishType.hamour;
  FishCondition _selectedCondition = FishCondition.fresh;
  final Set<PaymentMethod> _acceptedPayments = {PaymentMethod.cash};
  final List<String> _fishImages = [];
  String? _benefitPayImage;

  final _weightController = TextEditingController();
  final _priceController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _catchLocationController = TextEditingController();
  final _customFishNameController = TextEditingController();
  final _sellerNameController = TextEditingController();
  final _sellerPhoneController = TextEditingController();
  final _sellerLocationController = TextEditingController();

  @override
  void dispose() {
    _weightController.dispose();
    _priceController.dispose();
    _descriptionController.dispose();
    _catchLocationController.dispose();
    _customFishNameController.dispose();
    _sellerNameController.dispose();
    _sellerPhoneController.dispose();
    _sellerLocationController.dispose();
    super.dispose();
  }

  Future<void> _pickFishImages() async {
    final images = await _imagePicker.pickMultiImage();
    if (images.isNotEmpty) {
      setState(() {
        _fishImages.addAll(images.map((img) => img.path));
      });
    }
  }

  Future<void> _pickBenefitPayImage() async {
    final image = await _imagePicker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _benefitPayImage = image.path;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Fish Photos'),
          _buildCard([
            _buildImagePicker(),
          ]),
          const SizedBox(height: 24),
          _buildSectionTitle('Fish Details'),
          _buildCard([
            _buildDropdown<FishType>(
              label: 'Fish Type',
              value: _selectedFishType,
              items: FishType.values,
              onChanged: (value) => setState(() => _selectedFishType = value!),
              itemBuilder: (type) => '${type.displayName} (${type.arabicName})',
            ),
            if (_selectedFishType == FishType.other) ...[
              const SizedBox(height: 16),
              TextFormField(
                controller: _customFishNameController,
                decoration: _inputDecoration('Custom Fish Name'),
                validator: (value) {
                  if (_selectedFishType == FishType.other &&
                      (value == null || value.isEmpty)) {
                    return 'Please enter the fish name';
                  }
                  return null;
                },
              ),
            ],
            const SizedBox(height: 16),
            _buildDropdown<FishCondition>(
              label: 'Condition',
              value: _selectedCondition,
              items: FishCondition.values,
              onChanged: (value) => setState(() => _selectedCondition = value!),
              itemBuilder: (condition) => condition.displayName,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _weightController,
                    decoration: _inputDecoration('Weight (kg)'),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Required';
                      }
                      if (double.tryParse(value) == null) {
                        return 'Invalid number';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _priceController,
                    decoration: _inputDecoration('Price per kg (BD)'),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Required';
                      }
                      if (double.tryParse(value) == null) {
                        return 'Invalid number';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _catchLocationController,
              decoration: _inputDecoration('Catch Location (optional)'),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: _inputDecoration('Description (optional)'),
              maxLines: 3,
            ),
          ]),
          const SizedBox(height: 24),
          _buildSectionTitle('Payment Methods'),
          _buildCard([
            const Text(
              'Select accepted payment methods:',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 12),
            ...PaymentMethod.values.map((method) {
              return CheckboxListTile(
                title: Text(method.displayName),
                subtitle: Text(
                  method == PaymentMethod.cash
                      ? 'Accept cash payment'
                      : 'Accept Benefit Pay',
                ),
                value: _acceptedPayments.contains(method),
                onChanged: (selected) {
                  setState(() {
                    if (selected == true) {
                      _acceptedPayments.add(method);
                    } else if (_acceptedPayments.length > 1) {
                      _acceptedPayments.remove(method);
                    }
                  });
                },
                controlAffinity: ListTileControlAffinity.leading,
              );
            }),
            if (_acceptedPayments.contains(PaymentMethod.benefitPay)) ...[
              const Divider(),
              const SizedBox(height: 8),
              const Text(
                'Benefit Pay QR Code / Payment Info',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              _buildBenefitPayImagePicker(),
            ],
          ]),
          const SizedBox(height: 24),
          _buildSectionTitle('Seller Information'),
          _buildCard([
            TextFormField(
              controller: _sellerNameController,
              decoration: _inputDecoration('Your Name'),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your name';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _sellerPhoneController,
              decoration: _inputDecoration('Phone Number'),
              keyboardType: TextInputType.phone,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your phone number';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _sellerLocationController,
              decoration: _inputDecoration('Your Location (optional)'),
            ),
          ]),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _submitForm,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 22, 62, 98),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Post Listing',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildImagePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Add photos of your fish (optional)',
          style: TextStyle(color: Colors.grey),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 100,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              ..._fishImages.asMap().entries.map((entry) {
                return Stack(
                  children: [
                    Container(
                      width: 100,
                      height: 100,
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        image: DecorationImage(
                          image: FileImage(File(entry.value)),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    Positioned(
                      top: 4,
                      right: 12,
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _fishImages.removeAt(entry.key);
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close,
                            size: 14,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              }),
              GestureDetector(
                onTap: _pickFishImages,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_photo_alternate,
                          size: 32, color: Colors.grey.shade600),
                      const SizedBox(height: 4),
                      Text(
                        'Add Photo',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBenefitPayImagePicker() {
    if (_benefitPayImage != null) {
      return Stack(
        children: [
          Container(
            height: 150,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              image: DecorationImage(
                image: FileImage(File(_benefitPayImage!)),
                fit: BoxFit.contain,
              ),
              color: Colors.grey.shade100,
            ),
          ),
          Positioned(
            top: 8,
            right: 8,
            child: GestureDetector(
              onTap: () => setState(() => _benefitPayImage = null),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, size: 16, color: Colors.white),
              ),
            ),
          ),
        ],
      );
    }

    return GestureDetector(
      onTap: _pickBenefitPayImage,
      child: Container(
        height: 100,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.blue.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.blue.shade200),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.qr_code, size: 32, color: Colors.blue.shade600),
            const SizedBox(height: 8),
            Text(
              'Upload Benefit Pay QR Code',
              style: TextStyle(
                color: Colors.blue.shade700,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              'Buyers will see this when they select Benefit Pay',
              style: TextStyle(
                color: Colors.blue.shade400,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Color.fromARGB(255, 22, 62, 98),
        ),
      ),
    );
  }

  Widget _buildCard(List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Widget _buildDropdown<T>({
    required String label,
    required T value,
    required List<T> items,
    required ValueChanged<T?> onChanged,
    required String Function(T) itemBuilder,
  }) {
    return DropdownButtonFormField<T>(
      value: value,
      decoration: _inputDecoration(label),
      items: items.map((item) {
        return DropdownMenuItem<T>(
          value: item,
          child: Text(itemBuilder(item)),
        );
      }).toList(),
      onChanged: onChanged,
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(
          color: Color.fromARGB(255, 22, 62, 98),
          width: 2,
        ),
      ),
      filled: true,
      fillColor: Colors.grey.shade50,
    );
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      final listing = FishListing(
        id: 'fish_${DateTime.now().millisecondsSinceEpoch}',
        fishType: _selectedFishType,
        customFishName: _selectedFishType == FishType.other
            ? _customFishNameController.text
            : null,
        weight: double.parse(_weightController.text),
        pricePerKg: double.parse(_priceController.text),
        condition: _selectedCondition,
        acceptedPayments: _acceptedPayments.toList(),
        description: _descriptionController.text.isEmpty
            ? null
            : _descriptionController.text,
        imageUrls: _fishImages,
        benefitPayImageUrl: _benefitPayImage,
        catchLocation: _catchLocationController.text.isEmpty
            ? null
            : _catchLocationController.text,
        catchDate: DateTime.now(),
        seller: SellerInfo(
          id: 'seller_${DateTime.now().millisecondsSinceEpoch}',
          name: _sellerNameController.text,
          phone: _sellerPhoneController.text,
          location: _sellerLocationController.text.isEmpty
              ? null
              : _sellerLocationController.text,
        ),
        listedAt: DateTime.now(),
      );

      widget.onSubmit(listing);

      _formKey.currentState!.reset();
      _weightController.clear();
      _priceController.clear();
      _descriptionController.clear();
      _catchLocationController.clear();
      _customFishNameController.clear();
      _sellerNameController.clear();
      _sellerPhoneController.clear();
      _sellerLocationController.clear();
      setState(() {
        _selectedFishType = FishType.hamour;
        _selectedCondition = FishCondition.fresh;
        _acceptedPayments.clear();
        _acceptedPayments.add(PaymentMethod.cash);
        _fishImages.clear();
        _benefitPayImage = null;
      });
    }
  }
}

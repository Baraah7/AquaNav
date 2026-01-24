import 'package:flutter/material.dart';
import '../models/marketplace/fish_listing_model.dart';
import '../services/fish_marketplace_service.dart';

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
    _tabController = TabController(length: 2, vsync: this);
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
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text(
          'Mariner Harvest',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color.fromARGB(255, 22, 62, 98),
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(icon: Icon(Icons.storefront), text: 'Marketplace'),
            Tab(icon: Icon(Icons.add_business), text: 'Sell Fish'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildMarketplaceTab(),
          _buildSellFishTab(),
        ],
      ),
    );
  }

  Widget _buildMarketplaceTab() {
    return Column(
      children: [
        _buildSearchAndFilter(),
        Expanded(
          child: _filteredListings.isEmpty
              ? _buildEmptyState()
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

  Widget _buildSearchAndFilter() {
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
              hintText: 'Search fish, seller, location...',
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
                  label: 'Type',
                  value: _selectedTypeFilter?.displayName,
                  onTap: () => _showTypeFilterDialog(),
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  label: 'Condition',
                  value: _selectedConditionFilter?.displayName,
                  onTap: () => _showConditionFilterDialog(),
                ),
                if (_selectedTypeFilter != null || _selectedConditionFilter != null) ...[
                  const SizedBox(width: 8),
                  ActionChip(
                    label: const Text('Clear Filters'),
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

  void _showTypeFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Filter by Fish Type'),
        children: [
          ListTile(
            title: const Text('All Types'),
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

  void _showConditionFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Filter by Condition'),
        children: [
          ListTile(
            title: const Text('All Conditions'),
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

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            'No fish listings found',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try adjusting your filters',
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
                gradient: LinearGradient(
                  colors: [
                    const Color.fromARGB(255, 22, 62, 98),
                    const Color.fromARGB(255, 44, 100, 150),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Center(
                child: Icon(
                  _getFishIcon(listing.fishType),
                  size: 48,
                  color: Colors.white.withValues(alpha: 0.9),
                ),
              ),
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
        onBuy: (paymentMethod) => _processPurchase(listing, paymentMethod),
      ),
    );
  }

  void _processPurchase(FishListing listing, PaymentMethod paymentMethod) {
    Navigator.pop(context);
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
              'The seller will contact you shortly.',
              style: TextStyle(fontStyle: FontStyle.italic),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _marketplaceService.updateListingStatus(
                listing.id,
                ListingStatus.reserved,
              );
              setState(() {});
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Widget _buildSellFishTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: SellFishForm(
        onSubmit: (listing) async {
          await _marketplaceService.addListing(listing);
          setState(() {});
          _tabController.animateTo(0);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Your fish listing has been posted!'),
                backgroundColor: Colors.green,
              ),
            );
          }
        },
      ),
    );
  }
}

class FishDetailsSheet extends StatefulWidget {
  final FishListing listing;
  final Function(PaymentMethod) onBuy;

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

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
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
              Container(
                height: 150,
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
              ),
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
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _selectedPayment != null
                      ? () => widget.onBuy(_selectedPayment!)
                      : null,
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
        );
      },
    );
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

  FishType _selectedFishType = FishType.hamour;
  FishCondition _selectedCondition = FishCondition.fresh;
  final Set<PaymentMethod> _acceptedPayments = {PaymentMethod.cash};

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

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
      });
    }
  }
}

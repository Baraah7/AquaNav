import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/marketplace/fish_listing_model.dart';
import 'buildSellerCard.dart';
import 'buildPaymentOption.dart';

class FishDetailsSheet extends StatefulWidget {
  final FishListing listing;
  final String? currentUserId;
  final String? currentUserName;
  final String? currentUserPhone;
  final String? currentUserLocation;
  final Function(PaymentMethod, String, String, String?, String?) onBuy;

  const FishDetailsSheet({
    super.key,
    required this.listing,
    this.currentUserId,
    this.currentUserName,
    this.currentUserPhone,
    this.currentUserLocation,
    required this.onBuy,
  });

  @override
  State<FishDetailsSheet> createState() => _FishDetailsSheetState();
}

class _FishDetailsSheetState extends State<FishDetailsSheet> {
  PaymentMethod? _selectedPayment;
  late TextEditingController _buyerNameController;
  late TextEditingController _buyerPhoneController;
  late TextEditingController _buyerLocationController;
  final _formKey = GlobalKey<FormState>();
  final _imagePicker = ImagePicker();
  int _currentImageIndex = 0;
  String? _paymentProofImage;

  @override
  void initState() {
    super.initState();
    _buyerNameController = TextEditingController(text: widget.currentUserName ?? '');
    _buyerPhoneController = TextEditingController(text: widget.currentUserPhone ?? '');
    _buyerLocationController = TextEditingController(text: widget.currentUserLocation ?? '');
  }

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
      if (_selectedPayment == PaymentMethod.benefitPay && _paymentProofImage == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please upload your payment proof screenshot'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      widget.onBuy(
        _selectedPayment!,
        _buyerNameController.text,
        _buyerPhoneController.text,
        _buyerLocationController.text.isEmpty ? null : _buyerLocationController.text,
        _paymentProofImage,
      );
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
    return buildSellerCard(widget.listing);
  }
  
  Widget _buildPaymentOption(PaymentMethod method) {
    return buildPaymentOption(method, _selectedPayment, (PaymentMethod selectedMethod) {
      setState(() {
        _selectedPayment = selectedMethod;
      });
    });
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
            Text('Name: ${widget.listing.sellerName}'),
            const SizedBox(height: 8),
            Text('Phone: ${widget.listing.sellerPhone}'),
            if (widget.listing.sellerLocation != null) ...[
              const SizedBox(height: 8),
              Text('Location: ${widget.listing.sellerLocation}'),
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
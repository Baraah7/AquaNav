import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/marketplace/fish_listing_model.dart';

class SellFishForm extends StatefulWidget {
  final String? currentUserId;
  final String? currentUserName;
  final String? currentUserPhone;
  final String? currentUserLocation;
  final Function(FishListing) onSubmit;

  const SellFishForm({
    super.key,
    this.currentUserId,
    this.currentUserName,
    this.currentUserPhone,
    this.currentUserLocation,
    required this.onSubmit,
  });

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
  late TextEditingController _sellerNameController;
  late TextEditingController _sellerPhoneController;
  late TextEditingController _sellerLocationController;

  @override
  void initState() {
    super.initState();
    _sellerNameController = TextEditingController(text: widget.currentUserName ?? '');
    _sellerPhoneController = TextEditingController(text: widget.currentUserPhone ?? '');
    _sellerLocationController = TextEditingController(text: widget.currentUserLocation ?? '');
  }

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
              initialValue: _selectedFishType,
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
              initialValue: _selectedCondition,
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
    required T initialValue,
    required List<T> items,
    required ValueChanged<T?> onChanged,
    required String Function(T) itemBuilder,
  }) {
    return DropdownButtonFormField<T>(
      initialValue: initialValue,
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
    if (widget.currentUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please login to create a listing'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_formKey.currentState!.validate()) {
      final listing = FishListing(
        id: '', // Will be set by Firestore
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
        sellerId: widget.currentUserId!,
        sellerName: _sellerNameController.text,
        sellerPhone: _sellerPhoneController.text,
        sellerLocation: _sellerLocationController.text.isEmpty
            ? null
            : _sellerLocationController.text,
        listedAt: DateTime.now(),
      );

      widget.onSubmit(listing);

      _formKey.currentState!.reset();
      _weightController.clear();
      _priceController.clear();
      _descriptionController.clear();
      _catchLocationController.clear();
      _customFishNameController.clear();
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
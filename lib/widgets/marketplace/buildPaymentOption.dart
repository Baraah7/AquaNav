import 'package:flutter/material.dart';
import '../../models/marketplace/fish_listing_model.dart';

Widget buildPaymentOption(PaymentMethod method, PaymentMethod? selectedPayment, Function(PaymentMethod) onChanged) {
    final isSelected = selectedPayment == method;
    return GestureDetector(
      onTap: () => onChanged(method),
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

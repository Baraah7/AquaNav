enum FishType {
  // Fish types in the marketplace
  hamour,
  shaari,
  safi,
  kingfish,
  shrimp,
  crab,
  other;

  // English names displayed in UI
  String get displayName {
    switch (this) {
      case FishType.hamour:
        return 'Hamour (Grouper)';
      case FishType.shaari:
        return 'Shaari (Emperor)';
      case FishType.safi:
        return 'Safi (Rabbitfish)';
      case FishType.kingfish:
        return 'Kingfish';
      case FishType.shrimp:
        return 'Shrimp';
      case FishType.crab:
        return 'Crab';
      case FishType.other:
        return 'Other';
    }
  }

  // Arabic names displayed in UI
  String get arabicName {
    switch (this) {
      case FishType.hamour:
        return 'هامور';
      case FishType.shaari:
        return 'شعري';
      case FishType.safi:
        return 'صافي';
      case FishType.kingfish:
        return 'كنعد';
      case FishType.shrimp:
        return 'ربيان';
      case FishType.crab:
        return 'قبقب';
      case FishType.other:
        return 'أخرى';
    }
  }
}

// Fish conditions for listings
enum FishCondition {
  fresh,
  frozen,
  cleaned,
  filleted;

  String get displayName {
    switch (this) {
      case FishCondition.fresh:
        return 'Fresh';
      case FishCondition.frozen:
        return 'Frozen';
      case FishCondition.cleaned:
        return 'Cleaned';
      case FishCondition.filleted:
        return 'Filleted';
    }
  }
}

// Payment methods accepted by sellers
enum PaymentMethod {
  cash,
  benefitPay;

  String get displayName {
    switch (this) {
      case PaymentMethod.cash:
        return 'Cash';
      case PaymentMethod.benefitPay:
        return 'Benefit Pay';
    }
  }
}

// Status of a fish listing
enum ListingStatus {
  available,
  reserved,
  sold;

  String get displayName {
    switch (this) {
      case ListingStatus.available:
        return 'Available';
      case ListingStatus.reserved:
        return 'Reserved';
      case ListingStatus.sold:
        return 'Sold';
    }
  }
}
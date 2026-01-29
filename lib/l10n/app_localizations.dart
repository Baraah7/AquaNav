import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en')
  ];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'Bahaar'**
  String get appName;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @arabic.
  ///
  /// In en, this message translates to:
  /// **'العربية'**
  String get arabic;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @tryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try Again'**
  String get tryAgain;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loading;

  /// No description provided for @error.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get error;

  /// No description provided for @success.
  ///
  /// In en, this message translates to:
  /// **'Success'**
  String get success;

  /// No description provided for @noDataAvailable.
  ///
  /// In en, this message translates to:
  /// **'No data available'**
  String get noDataAvailable;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @reset.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get reset;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @welcomeToBahaar.
  ///
  /// In en, this message translates to:
  /// **'Welcome to Bahaar'**
  String get welcomeToBahaar;

  /// No description provided for @fishingMap.
  ///
  /// In en, this message translates to:
  /// **'Fishing Map'**
  String get fishingMap;

  /// No description provided for @fishingMapSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Interactive map with depth colors'**
  String get fishingMapSubtitle;

  /// No description provided for @weather.
  ///
  /// In en, this message translates to:
  /// **'Weather'**
  String get weather;

  /// No description provided for @weatherSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Check marine weather'**
  String get weatherSubtitle;

  /// No description provided for @fishRecognition.
  ///
  /// In en, this message translates to:
  /// **'Fish Recognition'**
  String get fishRecognition;

  /// No description provided for @fishRecognitionSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Identify fish species'**
  String get fishRecognitionSubtitle;

  /// No description provided for @marinerHarvest.
  ///
  /// In en, this message translates to:
  /// **'Mariner Harvest'**
  String get marinerHarvest;

  /// No description provided for @marinerHarvestSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Buy & sell fresh fish'**
  String get marinerHarvestSubtitle;

  /// No description provided for @signOut.
  ///
  /// In en, this message translates to:
  /// **'Sign Out'**
  String get signOut;

  /// No description provided for @loadingRecognitionModel.
  ///
  /// In en, this message translates to:
  /// **'Loading recognition model...'**
  String get loadingRecognitionModel;

  /// No description provided for @takePhotoOfFish.
  ///
  /// In en, this message translates to:
  /// **'Take a photo of fish or shrimp'**
  String get takePhotoOfFish;

  /// No description provided for @systemWillIdentify.
  ///
  /// In en, this message translates to:
  /// **'The system will identify the species automatically'**
  String get systemWillIdentify;

  /// No description provided for @camera.
  ///
  /// In en, this message translates to:
  /// **'Camera'**
  String get camera;

  /// No description provided for @gallery.
  ///
  /// In en, this message translates to:
  /// **'Gallery'**
  String get gallery;

  /// No description provided for @analyzing.
  ///
  /// In en, this message translates to:
  /// **'Analyzing...'**
  String get analyzing;

  /// No description provided for @newImage.
  ///
  /// In en, this message translates to:
  /// **'New Image'**
  String get newImage;

  /// No description provided for @supportedSpecies.
  ///
  /// In en, this message translates to:
  /// **'Supported Species'**
  String get supportedSpecies;

  /// No description provided for @confidence.
  ///
  /// In en, this message translates to:
  /// **'Confidence'**
  String get confidence;

  /// No description provided for @tryTakingClearerPhoto.
  ///
  /// In en, this message translates to:
  /// **'Try taking a clearer photo for better results'**
  String get tryTakingClearerPhoto;

  /// No description provided for @failedToLoadModel.
  ///
  /// In en, this message translates to:
  /// **'Failed to load recognition model'**
  String get failedToLoadModel;

  /// No description provided for @failedToOpenCamera.
  ///
  /// In en, this message translates to:
  /// **'Failed to open camera'**
  String get failedToOpenCamera;

  /// No description provided for @failedToSelectImage.
  ///
  /// In en, this message translates to:
  /// **'Failed to select image'**
  String get failedToSelectImage;

  /// No description provided for @modelNotReady.
  ///
  /// In en, this message translates to:
  /// **'Model not ready'**
  String get modelNotReady;

  /// No description provided for @classificationFailed.
  ///
  /// In en, this message translates to:
  /// **'Classification failed'**
  String get classificationFailed;

  /// No description provided for @hourlyForecast.
  ///
  /// In en, this message translates to:
  /// **'Next 24 Hours'**
  String get hourlyForecast;

  /// No description provided for @dailyForecast.
  ///
  /// In en, this message translates to:
  /// **'Day Forecast'**
  String get dailyForecast;

  /// No description provided for @wind.
  ///
  /// In en, this message translates to:
  /// **'Wind'**
  String get wind;

  /// No description provided for @uvIndex.
  ///
  /// In en, this message translates to:
  /// **'UV Index'**
  String get uvIndex;

  /// No description provided for @feelsLike.
  ///
  /// In en, this message translates to:
  /// **'Feels Like'**
  String get feelsLike;

  /// No description provided for @humidity.
  ///
  /// In en, this message translates to:
  /// **'Humidity'**
  String get humidity;

  /// No description provided for @visibility.
  ///
  /// In en, this message translates to:
  /// **'Visibility'**
  String get visibility;

  /// No description provided for @sunrise.
  ///
  /// In en, this message translates to:
  /// **'Sunrise'**
  String get sunrise;

  /// No description provided for @sunset.
  ///
  /// In en, this message translates to:
  /// **'Sunset'**
  String get sunset;

  /// No description provided for @unableToLoadWeather.
  ///
  /// In en, this message translates to:
  /// **'Unable to load weather'**
  String get unableToLoadWeather;

  /// No description provided for @changeLanguage.
  ///
  /// In en, this message translates to:
  /// **'Change Language'**
  String get changeLanguage;

  /// No description provided for @selectLanguage.
  ///
  /// In en, this message translates to:
  /// **'Select Language'**
  String get selectLanguage;

  /// No description provided for @account.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get account;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @about.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// No description provided for @version.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get version;

  /// No description provided for @signIn.
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get signIn;

  /// No description provided for @signUp.
  ///
  /// In en, this message translates to:
  /// **'Sign Up'**
  String get signUp;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @forgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot Password?'**
  String get forgotPassword;

  /// No description provided for @continueAsGuest.
  ///
  /// In en, this message translates to:
  /// **'Continue as Guest'**
  String get continueAsGuest;

  /// No description provided for @navigationReady.
  ///
  /// In en, this message translates to:
  /// **'Navigation Ready'**
  String get navigationReady;

  /// No description provided for @calculatingRoute.
  ///
  /// In en, this message translates to:
  /// **'Calculating route...'**
  String get calculatingRoute;

  /// No description provided for @portNavigation.
  ///
  /// In en, this message translates to:
  /// **'Port Navigation'**
  String get portNavigation;

  /// No description provided for @selectPortInstruction.
  ///
  /// In en, this message translates to:
  /// **'1. Select a port (anchor icon)\n2. Tap sea destination on map'**
  String get selectPortInstruction;

  /// No description provided for @tapSeaDestination.
  ///
  /// In en, this message translates to:
  /// **'2. Tap sea destination on map'**
  String get tapSeaDestination;

  /// No description provided for @pleaseSelectWaterDestination.
  ///
  /// In en, this message translates to:
  /// **'Please select a water destination'**
  String get pleaseSelectWaterDestination;

  /// No description provided for @seaDestinationSet.
  ///
  /// In en, this message translates to:
  /// **'Sea destination set. Select a port to start from.'**
  String get seaDestinationSet;

  /// No description provided for @portSelected.
  ///
  /// In en, this message translates to:
  /// **'Port selected'**
  String get portSelected;

  /// No description provided for @locationNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'Location not available'**
  String get locationNotAvailable;

  /// No description provided for @couldNotFindRoute.
  ///
  /// In en, this message translates to:
  /// **'Could not find a route'**
  String get couldNotFindRoute;

  /// No description provided for @errorCalculatingRoute.
  ///
  /// In en, this message translates to:
  /// **'Error calculating route'**
  String get errorCalculatingRoute;

  /// No description provided for @couldNotFindLandRoute.
  ///
  /// In en, this message translates to:
  /// **'Could not find land route to port'**
  String get couldNotFindLandRoute;

  /// No description provided for @couldNotFindMarineRoute.
  ///
  /// In en, this message translates to:
  /// **'Could not find marine route from port'**
  String get couldNotFindMarineRoute;

  /// No description provided for @routeCalculated.
  ///
  /// In en, this message translates to:
  /// **'Route calculated'**
  String get routeCalculated;

  /// No description provided for @navigationStarted.
  ///
  /// In en, this message translates to:
  /// **'Navigation started'**
  String get navigationStarted;

  /// No description provided for @failedToStartNavigation.
  ///
  /// In en, this message translates to:
  /// **'Failed to start navigation'**
  String get failedToStartNavigation;

  /// No description provided for @resetMask.
  ///
  /// In en, this message translates to:
  /// **'Reset Mask?'**
  String get resetMask;

  /// No description provided for @resetMaskConfirmation.
  ///
  /// In en, this message translates to:
  /// **'This will discard all your changes and restore the original mask.'**
  String get resetMaskConfirmation;

  /// No description provided for @maskSavedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Mask saved successfully'**
  String get maskSavedSuccessfully;

  /// No description provided for @failedToSaveMask.
  ///
  /// In en, this message translates to:
  /// **'Failed to save mask'**
  String get failedToSaveMask;

  /// No description provided for @maskResetToOriginal.
  ///
  /// In en, this message translates to:
  /// **'Mask reset to original'**
  String get maskResetToOriginal;

  /// No description provided for @failedToResetMask.
  ///
  /// In en, this message translates to:
  /// **'Failed to reset mask'**
  String get failedToResetMask;

  /// No description provided for @selectBothPortAndDestination.
  ///
  /// In en, this message translates to:
  /// **'Please select both port and sea destination'**
  String get selectBothPortAndDestination;

  /// No description provided for @currentLocationNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'Current location not available'**
  String get currentLocationNotAvailable;

  /// No description provided for @marketplace.
  ///
  /// In en, this message translates to:
  /// **'Marketplace'**
  String get marketplace;

  /// No description provided for @sellFish.
  ///
  /// In en, this message translates to:
  /// **'Sell Fish'**
  String get sellFish;

  /// No description provided for @myOrders.
  ///
  /// In en, this message translates to:
  /// **'My Orders'**
  String get myOrders;

  /// No description provided for @searchFishSellerLocation.
  ///
  /// In en, this message translates to:
  /// **'Search fish, seller, location...'**
  String get searchFishSellerLocation;

  /// No description provided for @type.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get type;

  /// No description provided for @condition.
  ///
  /// In en, this message translates to:
  /// **'Condition'**
  String get condition;

  /// No description provided for @clearFilters.
  ///
  /// In en, this message translates to:
  /// **'Clear Filters'**
  String get clearFilters;

  /// No description provided for @filterByFishType.
  ///
  /// In en, this message translates to:
  /// **'Filter by Fish Type'**
  String get filterByFishType;

  /// No description provided for @allTypes.
  ///
  /// In en, this message translates to:
  /// **'All Types'**
  String get allTypes;

  /// No description provided for @filterByCondition.
  ///
  /// In en, this message translates to:
  /// **'Filter by Condition'**
  String get filterByCondition;

  /// No description provided for @allConditions.
  ///
  /// In en, this message translates to:
  /// **'All Conditions'**
  String get allConditions;

  /// No description provided for @noFishListingsFound.
  ///
  /// In en, this message translates to:
  /// **'No fish listings found'**
  String get noFishListingsFound;

  /// No description provided for @tryAdjustingFilters.
  ///
  /// In en, this message translates to:
  /// **'Try adjusting your filters'**
  String get tryAdjustingFilters;

  /// No description provided for @noOrdersYet.
  ///
  /// In en, this message translates to:
  /// **'No orders yet'**
  String get noOrdersYet;

  /// No description provided for @ordersWillAppearHere.
  ///
  /// In en, this message translates to:
  /// **'Orders from buyers will appear here'**
  String get ordersWillAppearHere;

  /// No description provided for @orderPlaced.
  ///
  /// In en, this message translates to:
  /// **'Order Placed!'**
  String get orderPlaced;

  /// No description provided for @youHaveOrdered.
  ///
  /// In en, this message translates to:
  /// **'You have ordered'**
  String get youHaveOrdered;

  /// No description provided for @weight.
  ///
  /// In en, this message translates to:
  /// **'Weight'**
  String get weight;

  /// No description provided for @total.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get total;

  /// No description provided for @payment.
  ///
  /// In en, this message translates to:
  /// **'Payment'**
  String get payment;

  /// No description provided for @waitingForSeller.
  ///
  /// In en, this message translates to:
  /// **'Waiting for seller to accept your order.'**
  String get waitingForSeller;

  /// No description provided for @yourFishListingPosted.
  ///
  /// In en, this message translates to:
  /// **'Your fish listing has been posted!'**
  String get yourFishListingPosted;

  /// No description provided for @orderAccepted.
  ///
  /// In en, this message translates to:
  /// **'Order accepted!'**
  String get orderAccepted;

  /// No description provided for @orderRejected.
  ///
  /// In en, this message translates to:
  /// **'Order rejected'**
  String get orderRejected;

  /// No description provided for @orderCompleted.
  ///
  /// In en, this message translates to:
  /// **'Order marked as completed!'**
  String get orderCompleted;

  /// No description provided for @rejectOrder.
  ///
  /// In en, this message translates to:
  /// **'Reject Order'**
  String get rejectOrder;

  /// No description provided for @areYouSureRejectOrder.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to reject this order?'**
  String get areYouSureRejectOrder;

  /// No description provided for @reasonOptional.
  ///
  /// In en, this message translates to:
  /// **'Reason (optional)'**
  String get reasonOptional;

  /// No description provided for @reject.
  ///
  /// In en, this message translates to:
  /// **'Reject'**
  String get reject;

  /// No description provided for @accept.
  ///
  /// In en, this message translates to:
  /// **'Accept'**
  String get accept;

  /// No description provided for @markAsCompleted.
  ///
  /// In en, this message translates to:
  /// **'Mark as Completed'**
  String get markAsCompleted;

  /// No description provided for @buyer.
  ///
  /// In en, this message translates to:
  /// **'Buyer'**
  String get buyer;

  /// No description provided for @paymentProof.
  ///
  /// In en, this message translates to:
  /// **'Payment Proof'**
  String get paymentProof;

  /// No description provided for @tapToViewFullImage.
  ///
  /// In en, this message translates to:
  /// **'Tap to view full image'**
  String get tapToViewFullImage;

  /// No description provided for @sellerInformation.
  ///
  /// In en, this message translates to:
  /// **'Seller Information'**
  String get sellerInformation;

  /// No description provided for @description.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get description;

  /// No description provided for @yourInformation.
  ///
  /// In en, this message translates to:
  /// **'Your Information'**
  String get yourInformation;

  /// No description provided for @selectPaymentMethod.
  ///
  /// In en, this message translates to:
  /// **'Select Payment Method'**
  String get selectPaymentMethod;

  /// No description provided for @buyNow.
  ///
  /// In en, this message translates to:
  /// **'Buy Now'**
  String get buyNow;

  /// No description provided for @contactSeller.
  ///
  /// In en, this message translates to:
  /// **'Contact Seller'**
  String get contactSeller;

  /// No description provided for @yourName.
  ///
  /// In en, this message translates to:
  /// **'Your Name'**
  String get yourName;

  /// No description provided for @phoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Phone Number'**
  String get phoneNumber;

  /// No description provided for @deliveryLocationOptional.
  ///
  /// In en, this message translates to:
  /// **'Delivery Location (optional)'**
  String get deliveryLocationOptional;

  /// No description provided for @pleaseEnterYourName.
  ///
  /// In en, this message translates to:
  /// **'Please enter your name'**
  String get pleaseEnterYourName;

  /// No description provided for @pleaseEnterPhoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Please enter your phone number'**
  String get pleaseEnterPhoneNumber;

  /// No description provided for @uploadPaymentProof.
  ///
  /// In en, this message translates to:
  /// **'Upload Payment Proof'**
  String get uploadPaymentProof;

  /// No description provided for @required.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get required;

  /// No description provided for @pleaseUploadPaymentScreenshot.
  ///
  /// In en, this message translates to:
  /// **'Please upload a screenshot of your Benefit Pay payment'**
  String get pleaseUploadPaymentScreenshot;

  /// No description provided for @tapToUploadScreenshot.
  ///
  /// In en, this message translates to:
  /// **'Tap to upload screenshot'**
  String get tapToUploadScreenshot;

  /// No description provided for @paymentProofUploaded.
  ///
  /// In en, this message translates to:
  /// **'Payment proof uploaded'**
  String get paymentProofUploaded;

  /// No description provided for @pleaseUploadPaymentProofScreenshot.
  ///
  /// In en, this message translates to:
  /// **'Please upload your payment proof screenshot'**
  String get pleaseUploadPaymentProofScreenshot;

  /// No description provided for @pricePerKg.
  ///
  /// In en, this message translates to:
  /// **'Price per kg'**
  String get pricePerKg;

  /// No description provided for @totalPrice.
  ///
  /// In en, this message translates to:
  /// **'Total Price'**
  String get totalPrice;

  /// No description provided for @catchLocation.
  ///
  /// In en, this message translates to:
  /// **'Catch Location'**
  String get catchLocation;

  /// No description provided for @catchDate.
  ///
  /// In en, this message translates to:
  /// **'Catch Date'**
  String get catchDate;

  /// No description provided for @cash.
  ///
  /// In en, this message translates to:
  /// **'Cash'**
  String get cash;

  /// No description provided for @benefitPay.
  ///
  /// In en, this message translates to:
  /// **'Benefit Pay'**
  String get benefitPay;

  /// No description provided for @payWithCashOnDelivery.
  ///
  /// In en, this message translates to:
  /// **'Pay with cash on delivery'**
  String get payWithCashOnDelivery;

  /// No description provided for @payInstantlyViaBenefitPay.
  ///
  /// In en, this message translates to:
  /// **'Pay instantly via Benefit Pay'**
  String get payInstantlyViaBenefitPay;

  /// No description provided for @name.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get name;

  /// No description provided for @phone.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get phone;

  /// No description provided for @location.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get location;

  /// No description provided for @sales.
  ///
  /// In en, this message translates to:
  /// **'sales'**
  String get sales;

  /// No description provided for @fishPhotos.
  ///
  /// In en, this message translates to:
  /// **'Fish Photos'**
  String get fishPhotos;

  /// No description provided for @addPhotosOfFish.
  ///
  /// In en, this message translates to:
  /// **'Add photos of your fish (optional)'**
  String get addPhotosOfFish;

  /// No description provided for @addPhoto.
  ///
  /// In en, this message translates to:
  /// **'Add Photo'**
  String get addPhoto;

  /// No description provided for @fishDetails.
  ///
  /// In en, this message translates to:
  /// **'Fish Details'**
  String get fishDetails;

  /// No description provided for @fishType.
  ///
  /// In en, this message translates to:
  /// **'Fish Type'**
  String get fishType;

  /// No description provided for @customFishName.
  ///
  /// In en, this message translates to:
  /// **'Custom Fish Name'**
  String get customFishName;

  /// No description provided for @pleaseEnterFishName.
  ///
  /// In en, this message translates to:
  /// **'Please enter the fish name'**
  String get pleaseEnterFishName;

  /// No description provided for @weightKg.
  ///
  /// In en, this message translates to:
  /// **'Weight (kg)'**
  String get weightKg;

  /// No description provided for @pricePerKgBD.
  ///
  /// In en, this message translates to:
  /// **'Price per kg (BD)'**
  String get pricePerKgBD;

  /// No description provided for @catchLocationOptional.
  ///
  /// In en, this message translates to:
  /// **'Catch Location (optional)'**
  String get catchLocationOptional;

  /// No description provided for @descriptionOptional.
  ///
  /// In en, this message translates to:
  /// **'Description (optional)'**
  String get descriptionOptional;

  /// No description provided for @paymentMethods.
  ///
  /// In en, this message translates to:
  /// **'Payment Methods'**
  String get paymentMethods;

  /// No description provided for @selectAcceptedPaymentMethods.
  ///
  /// In en, this message translates to:
  /// **'Select accepted payment methods:'**
  String get selectAcceptedPaymentMethods;

  /// No description provided for @acceptCashPayment.
  ///
  /// In en, this message translates to:
  /// **'Accept cash payment'**
  String get acceptCashPayment;

  /// No description provided for @acceptBenefitPay.
  ///
  /// In en, this message translates to:
  /// **'Accept Benefit Pay'**
  String get acceptBenefitPay;

  /// No description provided for @benefitPayQRCode.
  ///
  /// In en, this message translates to:
  /// **'Benefit Pay QR Code / Payment Info'**
  String get benefitPayQRCode;

  /// No description provided for @uploadBenefitPayQRCode.
  ///
  /// In en, this message translates to:
  /// **'Upload Benefit Pay QR Code'**
  String get uploadBenefitPayQRCode;

  /// No description provided for @buyersWillSeeThis.
  ///
  /// In en, this message translates to:
  /// **'Buyers will see this when they select Benefit Pay'**
  String get buyersWillSeeThis;

  /// No description provided for @postListing.
  ///
  /// In en, this message translates to:
  /// **'Post Listing'**
  String get postListing;

  /// No description provided for @yourLocation.
  ///
  /// In en, this message translates to:
  /// **'Your Location (optional)'**
  String get yourLocation;

  /// No description provided for @invalidNumber.
  ///
  /// In en, this message translates to:
  /// **'Invalid number'**
  String get invalidNumber;

  /// No description provided for @guest.
  ///
  /// In en, this message translates to:
  /// **'Guest'**
  String get guest;

  /// No description provided for @signedIn.
  ///
  /// In en, this message translates to:
  /// **'Signed in'**
  String get signedIn;

  /// No description provided for @guestMode.
  ///
  /// In en, this message translates to:
  /// **'Guest mode'**
  String get guestMode;

  /// No description provided for @areYouSureSignOut.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to sign out?'**
  String get areYouSureSignOut;

  /// No description provided for @fresh.
  ///
  /// In en, this message translates to:
  /// **'Fresh'**
  String get fresh;

  /// No description provided for @frozen.
  ///
  /// In en, this message translates to:
  /// **'Frozen'**
  String get frozen;

  /// No description provided for @live.
  ///
  /// In en, this message translates to:
  /// **'Live'**
  String get live;

  /// No description provided for @pending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get pending;

  /// No description provided for @accepted.
  ///
  /// In en, this message translates to:
  /// **'Accepted'**
  String get accepted;

  /// No description provided for @rejected.
  ///
  /// In en, this message translates to:
  /// **'Rejected'**
  String get rejected;

  /// No description provided for @completed.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get completed;

  /// No description provided for @cancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get cancelled;

  /// No description provided for @minAgo.
  ///
  /// In en, this message translates to:
  /// **'min ago'**
  String get minAgo;

  /// No description provided for @hoursAgo.
  ///
  /// In en, this message translates to:
  /// **'hours ago'**
  String get hoursAgo;

  /// No description provided for @daysAgo.
  ///
  /// In en, this message translates to:
  /// **'days ago'**
  String get daysAgo;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}

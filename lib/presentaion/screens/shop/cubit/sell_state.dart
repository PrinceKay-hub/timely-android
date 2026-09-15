part of 'sell_cubit.dart';

const int kMaxImages = 5;
const int kMaxTags = 15;
const String kCurrency = 'GHS';

class PickedImage extends Equatable {
  final String id;
  final String path; // local file path / blob uri
  final bool processing;

  const PickedImage({
    required this.id,
    required this.path,
    this.processing = true,
  });

  PickedImage copyWith({String? path, bool? processing}) {
    return PickedImage(
      id: id,
      path: path ?? this.path,
      processing: processing ?? this.processing,
    );
  }

  @override
  List<Object?> get props => [id, path, processing];
}

class SelectedLocation extends Equatable {
  final String region;
  final String district;

  const SelectedLocation({required this.region, required this.district});

  String get label => '$region - $district';

  @override
  List<Object?> get props => [region, district];
}

enum SellLoadStatus { idle, loading, loaded, error }

class SellState extends Equatable {
  final String? productId; // non-null => edit mode
  final SellLoadStatus loadStatus;

  final List<PickedImage> images;
  final List<String> existingImages;

  final String name;
  final String description;
  final String price;
  final ProductCategory? category;
  final List<String> tags;
  final String tagInput;
  final String landmark;
  final SelectedLocation? selectedLocation;

  final bool useCall;
  final String callNumber;
  final bool isDelivery;

  final bool submitting;
  final String? submitError;
  final bool submitted;

  const SellState({
    this.productId,
    this.loadStatus = SellLoadStatus.idle,
    this.images = const [],
    this.existingImages = const [],
    this.name = '',
    this.description = '',
    this.price = '',
    this.category,
    this.tags = const [],
    this.tagInput = '',
    this.landmark = '',
    this.selectedLocation,
    this.useCall = false,
    this.callNumber = '',
    this.isDelivery = false,
    this.submitting = false,
    this.submitError,
    this.submitted = false,
  });

  bool get isEditMode => productId != null;
  int get totalImageCount => images.length + existingImages.length;

  SellState copyWith({
    String? productId,
    SellLoadStatus? loadStatus,
    List<PickedImage>? images,
    List<String>? existingImages,
    String? name,
    String? description,
    String? price,
    ProductCategory? category,
    List<String>? tags,
    String? tagInput,
    String? landmark,
    SelectedLocation? selectedLocation,
    bool clearLocation = false,
    bool? useCall,
    String? callNumber,
    bool? isDelivery,
    bool? submitting,
    String? submitError,
    bool clearSubmitError = false,
    bool? submitted,
  }) {
    return SellState(
      productId: productId ?? this.productId,
      loadStatus: loadStatus ?? this.loadStatus,
      images: images ?? this.images,
      existingImages: existingImages ?? this.existingImages,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      category: category ?? this.category,
      tags: tags ?? this.tags,
      tagInput: tagInput ?? this.tagInput,
      landmark: landmark ?? this.landmark,
      selectedLocation:
          clearLocation ? null : (selectedLocation ?? this.selectedLocation),
      useCall: useCall ?? this.useCall,
      callNumber: callNumber ?? this.callNumber,
      isDelivery: isDelivery ?? this.isDelivery,
      submitting: submitting ?? this.submitting,
      submitError: clearSubmitError ? null : (submitError ?? this.submitError),
      submitted: submitted ?? this.submitted,
    );
  }

  @override
  List<Object?> get props => [
        productId,
        loadStatus,
        images,
        existingImages,
        name,
        description,
        price,
        category,
        tags,
        tagInput,
        landmark,
        selectedLocation,
        useCall,
        callNumber,
        isDelivery,
        submitting,
        submitError,
        submitted,
      ];
}

part of 'my_listings_cubit.dart';

enum MyListingsStatus { idle, loading, success, failure }

class MyListingsState extends Equatable {
  final MyListingsStatus status;
  final List<Product> listings;
  final bool refreshing;
  final String? mutatingId; // productId currently being mutated

  const MyListingsState({
    this.status = MyListingsStatus.idle,
    this.listings = const [],
    this.refreshing = false,
    this.mutatingId,
  });

  int get activeCount =>
      listings.where((p) => p.status == ProductStatus.active).length;
  int get offlineCount =>
      listings.where((p) => p.status == ProductStatus.offline).length;
  int get pendingCount =>
      listings.where((p) => p.status == ProductStatus.pending).length;
  int get totalViews =>
      listings.fold(0, (sum, p) => sum + p.viewCount);

  MyListingsState copyWith({
    MyListingsStatus? status,
    List<Product>? listings,
    bool? refreshing,
    String? mutatingId,
    bool clearMutatingId = false,
  }) {
    return MyListingsState(
      status: status ?? this.status,
      listings: listings ?? this.listings,
      refreshing: refreshing ?? this.refreshing,
      mutatingId: clearMutatingId ? null : (mutatingId ?? this.mutatingId),
    );
  }

  @override
  List<Object?> get props => [status, listings, refreshing, mutatingId];
}
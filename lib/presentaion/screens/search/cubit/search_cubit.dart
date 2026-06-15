import 'package:bloc/bloc.dart';
import 'package:booking/data/repositories/search_repository_impl.dart';
import 'package:equatable/equatable.dart';

part 'search_state.dart';

class SearchCubit extends Cubit<SearchState> {
  final SearchRepositoryImpl searchRepositoryImpl;
  SearchCubit({required this.searchRepositoryImpl}) : super(SearchInitial());


  Future<void> fetchSerchData(String query, String region, String? district) async {
    emit(SearchLoading());
    try {
      // Simulate data fetching with a delay
      final results = await searchRepositoryImpl.searchProviders(
        query: query,
        maxDistanceKm: 50.0,
        sortBy: 'distance',
        region: region,
        district: district
      );
      
      emit(SearchLoaded(results));

    } catch (e) {
      emit(SearchError('Failed to fetch data'));
    }
  }


  Future<void> fetchByCategory(String category) async {
    emit(SearchLoading());
    try {
      // Simulate data fetching with a delay
      final results = await searchRepositoryImpl.searchByCategory(
        category: category,
        maxDistanceKm: 20.0,
        sortBy: 'distance',
      );
      
      emit(SearchLoaded(results));

    } catch (e) {
      emit(SearchError('Failed to fetch data'));
    }
  }
}

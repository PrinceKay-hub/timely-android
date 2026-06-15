import 'dart:io';

import 'package:equatable/equatable.dart';

abstract class PortfolioEvent extends Equatable {
  const PortfolioEvent();
  @override
  List<Object> get props => [];
}

class LoadPortfolio extends PortfolioEvent {}

class AddPortfolioImage extends PortfolioEvent {
  final File imageFile;
  final String? caption;
  const AddPortfolioImage(this.imageFile, this.caption);
}

class UpdatePortfolioImageCaption extends PortfolioEvent {
  final int index;
  final String caption;
  const UpdatePortfolioImageCaption(this.index, this.caption);
}

class DeletePortfolioImage extends PortfolioEvent {
  final String imageId;
  final String imageUrl;
  const DeletePortfolioImage(this.imageId, this.imageUrl);
}

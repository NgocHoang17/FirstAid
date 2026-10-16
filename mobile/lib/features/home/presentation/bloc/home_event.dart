import 'package:equatable/equatable.dart';

abstract class HomeEvent extends Equatable {
  const HomeEvent();

  @override
  List<Object?> get props => [];
}

class HomeLoadRequested extends HomeEvent {}

class EmergencyButtonPressed extends HomeEvent {}

class Call115Pressed extends HomeEvent {}

class NotifyFamilyPressed extends HomeEvent {}

class ChamNhamCancelPressed extends HomeEvent {}

class BottomNavItemTapped extends HomeEvent {
  final int index;

  const BottomNavItemTapped(this.index);

  @override
  List<Object?> get props => [index];
}
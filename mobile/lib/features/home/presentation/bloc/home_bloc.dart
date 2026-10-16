import 'package:flutter_bloc/flutter_bloc.dart';
import 'home_event.dart';
import 'home_state.dart';

/// BLoC quản lý trạng thái màn hình Home
class HomeBloc extends Bloc<HomeEvent, HomeState> {
  HomeBloc() : super(HomeInitial()) {
    on<HomeLoadRequested>((event, emit) async {
      emit(HomeLoading());
      try {
        // TODO: Lấy địa chỉ từ geolocator / Hive local
        emit(HomeLoaded(
          address: '470 Trần Đại Nghĩa, Ngũ Hành Sơn, Đà Nẵng',
          chamNhamCountdown: 5,
        ));
      } catch (e) {
        emit(HomeError(e.toString()));
      }
    });

    on<EmergencyButtonPressed>((event, emit) {
      // TODO: Điều hướng sang Triage (/triage)
    });

    on<Call115Pressed>((event, emit) {
      // TODO: Mở máy gọi điện tel:115 qua url_launcher
    });

    on<NotifyFamilyPressed>((event, emit) {
      // TODO: Mở màn hình liên hệ người thân
    });

    on<ChamNhamCancelPressed>((event, emit) {
      // TODO: Tắt banner CHẲM NHẦM?
    });

    on<BottomNavItemTapped>((event, emit) {
      // TODO: Chuyển tab bottom nav
    });
  }
}
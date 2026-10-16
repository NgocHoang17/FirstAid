import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/app_routes.dart';
import 'bloc/home_bloc.dart';
import 'bloc/home_event.dart';
import 'bloc/home_state.dart';
import 'widgets/app_ambulance_banner.dart';
import 'widgets/app_bottom_nav.dart';
import 'widgets/app_emergency_button.dart';
import 'widgets/app_emergency_contact.dart';
import 'widgets/app_first_aid_card.dart';
import 'widgets/app_location_card.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => HomeBloc()..add(HomeLoadRequested()),
      child: const _HomeView(),
    );
  }
}

class _HomeView extends StatelessWidget {
  const _HomeView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          Container(
            width: double.infinity,
            height: 64,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: const Color(0xE5FAF8FF),
              boxShadow: [
                BoxShadow(
                  color: const Color(0x0A000000),
                  blurRadius: 8,
                  offset: const Offset(0, 1),
                  spreadRadius: 0,
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 32,
                  height: 32,
                  clipBehavior: Clip.antiAlias,
                  decoration: ShapeDecoration(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Icon(
                    Icons.medical_services,
                    color: AppColors.primaryRed,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  'FirstAid',
                  style: TextStyle(
                    color: AppColors.primaryRed,
                    fontSize: 18,
                    fontFamily: 'Plus Jakarta Sans',
                    fontWeight: FontWeight.w700,
                    height: 1.25,
                    letterSpacing: -0.45,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: BlocBuilder<HomeBloc, HomeState>(
              builder: (context, state) {
                final address = state is HomeLoaded ? state.address : '';
                return SingleChildScrollView(
                  padding: const EdgeInsets.only(
                    top: 16,
                    left: 16,
                    right: 16,
                    bottom: 16,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppLocationCard(
                        address: address,
                        onCopy: () {},
                      ),
                      const SizedBox(height: 16),
                      Center(
                        child: AppEmergencyButton(
                          onPressed: () {
                            context.read<HomeBloc>().add(EmergencyButtonPressed());
                            Navigator.pushNamed(context, AppRoutes.triage);
                          },
                        ),
                      ),
                      const SizedBox(height: 16),
                      AppAmbulanceBanner(
                        countdownSeconds: 5,
                        onCancel: () {
                          context.read<HomeBloc>().add(ChamNhamCancelPressed());
                        },
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            'Phác sơ cứu tức thì',
                            style: AppTextStyles.sectionTitle18,
                          ),
                          Text(
                            'xem thêm',
                            style: AppTextStyles.captionInter12.copyWith(
                              color: const Color(0xFF5C403C),
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: AppFirstAidCard(
                              iconBgColor: AppColors.iconRedLight,
                              labelColor: AppColors.primaryRed,
                              labelText: 'TỐI KHẨN',
                              title: 'Ngừng tim / Đột quỵ',
                              description: 'Ép tim CPR 110 BPM',
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: AppFirstAidCard(
                              iconBgColor: AppColors.iconOrangeLight,
                              labelColor: const Color(0xFFD97706),
                              labelText: 'NGHẸT THỞ',
                              title: 'Hóc dị vật',
                              description: 'Thủ thuật Heimlich',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: AppFirstAidCard(
                              iconBgColor: AppColors.iconOrangeDarkLight,
                              labelColor: const Color(0xFFEA580C),
                              labelText: 'HẠ NHIỆT',
                              title: 'Bỏng nhiệt & Vết thương',
                              description: 'Xả nước & Băng sạch',
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: AppFirstAidCard(
                              iconBgColor: AppColors.iconBlueLight,
                              labelColor: const Color(0xFF006398),
                              labelText: 'CỐ ĐỊNH',
                              title: 'Chấn thương gãy xương',
                              description: 'Nẹp bất động chi',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      AppEmergencyContact(
                        onCall115: () async {
                          context.read<HomeBloc>().add(Call115Pressed());
                          final url = 'tel:115';
                          if (await canLaunchUrl(Uri.parse(url))) {
                            await launchUrl(Uri.parse(url));
                          }
                        },
                        onNotifyFamily: () {
                          context.read<HomeBloc>().add(NotifyFamilyPressed());
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          AppBottomNav(
            selectedIndex: 0,
            onItemTapped: (index) {
              context.read<HomeBloc>().add(BottomNavItemTapped(index));
            },
          ),
        ],
      ),
    );
  }
}

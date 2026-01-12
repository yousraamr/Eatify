import 'package:eatify/core/common/tab_button.dart';
import 'package:eatify/features/home/home_screen.dart';
import 'package:eatify/features/home/restaurants_screen.dart';
import 'package:eatify/features/profile/profile_screen.dart';
import 'package:eatify/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:eatify/translations/navbar_strings.dart';

class NavBar extends ConsumerStatefulWidget {
  const NavBar({super.key});

  @override
  ConsumerState<NavBar> createState() => _NavBarState();
}

class _NavBarState extends ConsumerState<NavBar> {
  int selectedTab = 2; // default selected tab is Home
  PageStorageBucket storageBucket = PageStorageBucket();
  Widget selectedPageView = const HomeScreen();

  @override
  Widget build(BuildContext context) {
     context.locale;
    return Scaffold(
      body: PageStorage(bucket: storageBucket, child: selectedPageView),
      backgroundColor: AppTheme.background,
      floatingActionButtonLocation:
          FloatingActionButtonLocation.miniCenterDocked,
      floatingActionButton: SizedBox(
        width: 60,
        height: 60,
        child: FloatingActionButton(
          onPressed: () {
            if (selectedTab != 2) {
              selectedTab = 2;
              selectedPageView = const HomeScreen();
            }
            if (mounted) setState(() {});
          },
          shape: const CircleBorder(),
          backgroundColor: selectedTab == 2 ? AppTheme.primary : Colors.grey,
          child: Image.asset("assets/img/tab_home.png", width: 30, height: 30),
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        surfaceTintColor: AppTheme.card,
        shadowColor: AppTheme.secondary,
        elevation: 1,
        notchMargin: 12,
        height: 64,
        shape: const CircularNotchedRectangle(),
        child: SafeArea(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              TabButton(
                title: NavbarStrings.restaurant.tr(),
                icon: "assets/img/tab_menu.png",
                onTap: () {
                  if (selectedTab != 0) {
                    selectedTab = 0;
                    selectedPageView = const RestaurantsScreen();
                  }
                  if (mounted) setState(() {});
                },
                isSelected: selectedTab == 0,
              ),
              TabButton(
                title: NavbarStrings.profile.tr(),
                icon: "assets/img/tab_profile.png",
                onTap: () {
                  if (selectedTab != 3) {
                    selectedTab = 3;
                    selectedPageView = const ProfileScreen();
                  }
                  if (mounted) setState(() {});
                },
                isSelected: selectedTab == 3,
              ),
              
            ],
          ),
        ),
      ),
    );
  }
}

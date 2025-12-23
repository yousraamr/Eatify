import 'package:eatify/core/common/tab_button.dart';
import 'package:eatify/features/home/home_screen.dart';
import 'package:eatify/features/home/restaurants_screen.dart';
import 'package:eatify/features/profile/profile_screen.dart';
import 'package:flutter/material.dart';

class NavBar extends StatefulWidget {
  const NavBar({super.key});

  @override
  State<NavBar> createState() => _MainTabViewState();
}

class _MainTabViewState extends State<NavBar> {
  int selctTab = 2;
  PageStorageBucket storageBucket = PageStorageBucket();
  Widget selectPageView = const HomeScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageStorage(bucket: storageBucket, child: selectPageView),
      backgroundColor: const Color(0xfff5f5f5),
      floatingActionButtonLocation:
          FloatingActionButtonLocation.miniCenterDocked,
      floatingActionButton: SizedBox(
        width: 60,
        height: 60,
        child: FloatingActionButton(
          onPressed: () {
            if (selctTab != 2) {
              selctTab = 2;
              selectPageView = const HomeScreen();
            }
            if (mounted) {
              setState(() {});
            }
          },
          shape: const CircleBorder(),
          backgroundColor: selctTab == 2 ? Colors.deepOrange : Colors.grey,
          child: Image.asset("assets/img/tab_home.png", width: 30, height: 30),
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        surfaceTintColor: Colors.white,
        shadowColor: Colors.black,
        elevation: 1,
        notchMargin: 12,
        height: 64,
        shape: const CircularNotchedRectangle(),
        child: SafeArea(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              TabButton(
                title: "Restaurants",
                icon: "assets/img/tab_menu.png",
                onTap: () {
                  if (selctTab != 0) {
                    selctTab = 0;
                    selectPageView = const RestaurantsScreen();
                  }
                  if (mounted) {
                    setState(() {});
                  }
                },
                isSelected: selctTab == 0,
              ),
              TabButton(
                title: "Profile",
                icon: "assets/img/tab_profile.png",
                onTap: () {
                  if (selctTab != 3) {
                    selctTab = 3;
                    selectPageView = const ProfileScreen();
                  }
                  if (mounted) {
                    setState(() {});
                  }
                },
                isSelected: selctTab == 3,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

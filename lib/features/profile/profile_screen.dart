import 'package:easy_localization/easy_localization.dart';
import 'package:eatify/features/auth/login_screen.dart';
import 'package:eatify/features/home/home_screen.dart'
    hide currentProfileProvider;
import 'package:eatify/features/orders/history_order.dart';
import 'package:eatify/features/orders/live_order.dart';
import 'package:eatify/features/profile/blocked_users_screen.dart';
import 'package:eatify/features/profile/edit_profile_screen.dart';
import 'package:eatify/features/profile/fav_screen.dart';
import 'package:eatify/features/shared_cart/shared_cart_screen.dart';
import 'package:eatify/providers/cart_provider.dart';
import 'package:eatify/providers/shared_cart_provider.dart';
import 'package:eatify/theme/app_theme.dart';
import 'package:eatify/theme/theme_notifier.dart';
import 'package:eatify/translations/profile_strings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../providers/profile_provider.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    // Ensure profile loads after build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Force refresh if needed
      if (mounted) {
        ref.invalidate(currentProfileProvider);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(currentProfileProvider);

    return Scaffold(
      appBar: AppBar(title: const Text(ProfileStrings.profile).tr()),
      body: profileAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppTheme.primary),
        ),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: AppTheme.error),
                const SizedBox(height: 16),
                Text(
                  ProfileStrings.errorLoadingProfile.tr(),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  e.toString(),
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey[600]),
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: () {
                    // Wait a bit then retry
                    Future.delayed(const Duration(milliseconds: 300), () {
                      if (mounted) {
                        ref.invalidate(currentProfileProvider);
                      }
                    });
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text(ProfileStrings.retry).tr(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        data: (profile) {
          final username = profile['username'] as String;
          final fullName = profile['full_name'] as String?;
          final userNumber = profile['user_number'];
          final avatarUrl = profile['avatar_url'];

          debugPrint('✅ user_number: $userNumber');

          final displayName = (fullName?.trim().isNotEmpty ?? false)
              ? fullName!
              : username;
          final email = Supabase.instance.client.auth.currentUser?.email ?? '';

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(currentProfileProvider);
              // Wait for it to refresh
              await Future.delayed(const Duration(milliseconds: 500));
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  /// 👤 PROFILE CARD
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: 1),
                    duration: const Duration(milliseconds: 600),
                    curve: Curves.easeOut,
                    builder: (context, value, child) {
                      return Opacity(
                        opacity: value,
                        child: Transform.translate(
                          offset: Offset(0, 30 * (1 - value)),
                          child: child,
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Theme.of(context).primaryColor.withOpacity(0.4),
                            Theme.of(context).primaryColor.withOpacity(0.6),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Theme.of(
                              context,
                            ).primaryColor.withOpacity(0.4),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          // Avatar
                          Hero(
                            tag: 'profile_avatar',
                            child: Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 4,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppTheme.textPrimary.withOpacity(
                                      0.2,
                                    ),
                                    blurRadius: 15,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: CircleAvatar(
                                radius: 50,
                                backgroundColor: Theme.of(context).cardColor,
                                backgroundImage: avatarUrl != null
                                    ? NetworkImage(avatarUrl)
                                    : null,
                                child: avatarUrl == null
                                    ? Icon(
                                        Icons.person,
                                        size: 50,
                                        color: AppTheme.secondary,
                                      )
                                    : null,
                              ),
                            ),
                          ),

                          const SizedBox(height: 16),

                          Text(
                            displayName,
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).cardColor,
                            ),
                          ),

                          const SizedBox(height: 4),

                          Text(
                            '@$username',
                            style: TextStyle(
                              fontSize: 16,
                              color: Theme.of(context).cardColor,
                            ),
                          ),

                          const SizedBox(height: 4),

                          // FIXED: Show ID with proper null handling
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Theme.of(
                                context,
                              ).cardColor.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '${ProfileStrings.id.tr()}: ${userNumber?.toString() ?? '—'}',
                              style: TextStyle(
                                fontSize: 13,
                                color: Theme.of(context).cardColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),

                          const SizedBox(height: 8),

                          Text(
                            email,
                            style: TextStyle(
                              fontSize: 14,
                              color: Theme.of(context).cardColor,
                            ),
                          ),

                          const SizedBox(height: 20),

                          /// ✏️ EDIT PROFILE
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              icon: const Icon(Icons.edit),
                              label: Text(
                                (ProfileStrings.editProfile).tr(),
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Theme.of(context).cardColor,
                                foregroundColor: Theme.of(context).primaryColor,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 0,
                              ),
                              onPressed: () async {
                                final result = await Navigator.push<bool>(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => EditProfileScreen(
                                      currentProfile: profile,
                                    ),
                                  ),
                                );

                                // Refresh if profile was updated
                                if (result == true && mounted) {
                                  await Future.delayed(
                                    const Duration(milliseconds: 300),
                                  );
                                  ref.invalidate(currentProfileProvider);
                                }
                              },
                            ),
                          ),

                          const SizedBox(height: 12),

                          /// 🚪 LOGOUT
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Theme.of(context).cardColor,
                                side: BorderSide(
                                  color: Theme.of(context).cardColor,
                                  width: 2,
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              icon: const Icon(Icons.logout),
                              label: Text(
                                ProfileStrings.logout.tr(),
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              onPressed: () async {
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text(
                                      ProfileStrings.logoutConfirmationTitle,
                                    ).tr(),
                                    content: const Text(
                                      ProfileStrings.logoutConfirmationMessage,
                                    ).tr(),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(context, false),
                                        child: Text(
                                          ProfileStrings.cancel.tr(),
                                          style: const TextStyle(
                                            color: AppTheme.error,
                                          ),
                                        ),
                                      ),

                                      ElevatedButton(
                                        onPressed: () =>
                                            Navigator.pop(context, true),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppTheme.primary
                                              .withOpacity(0.8),
                                        ),
                                        child: const Text(
                                          ProfileStrings.logout,
                                        ).tr(),
                                      ),
                                    ],
                                  ),
                                );

                                if (confirm == true) {
                                  await Supabase.instance.client.auth.signOut();

                                  // Clear all cached data
                                  ref.invalidate(currentProfileProvider);
                                  ref.invalidate(cartProvider);
                                  ref.invalidate(sharedCartProvider);

                                  if (context.mounted) {
                                    Navigator.pushAndRemoveUntil(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => const LoginScreen(),
                                      ),
                                      (_) => false,
                                    );
                                  }
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 28),

                  // Theme & Language Toggle
                  Column(
                    children: [
                      // Dark Mode
                      Consumer(
                        builder: (context, ref, _) {
                          final themeMode = ref.watch(themeProvider);
                          final isDark = themeMode == ThemeMode.dark;

                          return SwitchListTile(
                            title: Text(
                              ProfileStrings.darkMode.tr(),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            value: isDark,
                            onChanged: (_) =>
                                ref.read(themeProvider.notifier).toggleTheme(),
                            secondary: Icon(
                              isDark ? Icons.dark_mode : Icons.light_mode,
                            ),
                          );
                        },
                      ),

                      // Language Switch
                      ListTile(
                        leading: const Icon(Icons.language),
                        title: Text(
                          ProfileStrings.language.tr(),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),

                        trailing: DropdownButton<Locale>(
                          value: context.locale,
                          underline: const SizedBox(),
                          items: EasyLocalization.of(context)!.supportedLocales
                              .map(
                                (locale) => DropdownMenuItem<Locale>(
                                  value: locale,
                                  child: Text(
                                    locale.languageCode == 'en'
                                        ? 'English'
                                        : locale.languageCode == 'ar'
                                        ? 'العربية'
                                        : locale.languageCode,
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: (locale) {
                            if (locale != null) {
                              context.setLocale(locale);
                            }
                          },
                        ),
                      ),
                    ],
                  ),

                  /// 🚚 ACTIVITY
                  _buildAnimatedButton(
                    context,
                    delay: 100,
                    icon: Icons.delivery_dining,
                    text: ProfileStrings.liveOrders.tr(),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const LiveOrdersScreen(),
                      ),
                    ),
                  ),

                  _buildAnimatedButton(
                    context,
                    delay: 200,
                    icon: Icons.history,
                    text: ProfileStrings.orderHistory.tr(),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const OrderHistoryScreen(),
                      ),
                    ),
                  ),

                  _buildAnimatedButton(
                    context,
                    delay: 300,
                    icon: Icons.group,
                    text: ProfileStrings.sharedCart.tr(),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const SharedCartScreen(),
                      ),
                    ),
                  ),

                  _buildAnimatedButton(
                    context,
                    delay: 400,
                    icon: Icons.favorite,
                    text: ProfileStrings.favorites.tr(),
                    onTap: () {
                      final allRestaurantsAsync = ref.read(
                        allRestaurantsProvider,
                      );

                      allRestaurantsAsync.when(
                        data: (allRestaurants) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => FavoritesScreen(
                                allRestaurants: allRestaurants,
                              ),
                            ),
                          );
                        },
                        loading: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                ProfileStrings.loadingRestaurants.tr(),
                              ),
                            ),
                          );
                        },
                        error: (e, _) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('${ProfileStrings.error.tr()}: $e'),
                              backgroundColor: AppTheme.error,
                            ),
                          );
                        },
                      );
                    },
                  ),

                  _buildAnimatedButton(
                    context,
                    delay: 500,
                    icon: Icons.block,
                    text: ProfileStrings.blockedUsers.tr(),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const BlockedUsersScreen(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildAnimatedButton(
    BuildContext context, {
    required int delay,
    required IconData icon,
    required String text,
    required VoidCallback onTap,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 500 + delay),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(30 * (1 - value), 0),
            child: child,
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        child: Material(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          elevation: 2,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: AppTheme.primary, size: 24),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      text,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: Theme.of(context).primaryColor,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

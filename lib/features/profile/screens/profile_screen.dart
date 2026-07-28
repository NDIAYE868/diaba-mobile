import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/providers/theme_provider.dart';
import '../../../shared/utils/price_formatter.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authAsync = ref.watch(authStateProvider);
    final themeMode = ref.watch(themeModeProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Mon Profil')),
      body: authAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => _NotLoggedInView(onLogin: () => context.push('/auth/login')),
        data: (user) {
          if (user == null) {
            return _NotLoggedInView(onLogin: () => context.push('/auth/login'));
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // ─── Avatar + infos ──────────────────────────────────────
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [AppColors.primary, AppColors.primaryDark],
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    children: [
                      // Avatar
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            user.displayName.isNotEmpty
                                ? user.displayName[0].toUpperCase()
                                : 'D',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 36,
                              fontWeight: FontWeight.w700,
                              fontFamily: 'Poppins',
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        user.displayName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'Poppins',
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        user.email,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                          fontFamily: 'Poppins',
                        ),
                      ),
                      if (user.phone != null && user.phone!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          user.phone!,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),

                      // Stats
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _StatBox(
                            value: '${user.ordersCount}',
                            label: 'Commandes',
                          ),
                          Container(width: 1, height: 36, color: Colors.white30),
                          _StatBox(
                            value: PriceFormatter.format(user.totalSpent),
                            label: 'Total dépensé',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // ─── Verification badge ──────────────────────────────────
                if (!user.isVerified)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: AppColors.warning.withOpacity(0.3)),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.warning_amber_outlined,
                            color: AppColors.warning, size: 20),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Votre compte n\'est pas encore vérifié. Consultez votre email.',
                            style: TextStyle(
                              color: AppColors.warning,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                if (!user.isVerified) const SizedBox(height: 16),

                // ─── Info cards ──────────────────────────────────────────
                _SectionCard(
                  children: [
                    _InfoTile(
                      icon: Icons.person_outline,
                      label: 'Prénom',
                      value: user.firstName.isNotEmpty ? user.firstName : '—',
                    ),
                    _InfoTile(
                      icon: Icons.badge_outlined,
                      label: 'Nom',
                      value: user.lastName.isNotEmpty ? user.lastName : '—',
                    ),
                    _InfoTile(
                      icon: Icons.email_outlined,
                      label: 'Email',
                      value: user.email,
                    ),
                    _InfoTile(
                      icon: Icons.phone_outlined,
                      label: 'Téléphone',
                      value: user.phone ?? '—',
                    ),
                    _InfoTile(
                      icon: Icons.location_on_outlined,
                      label: 'Adresse',
                      value: user.address ?? '—',
                      isLast: true,
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // ─── Settings ────────────────────────────────────────────
                _SectionCard(
                  children: [
                    _SettingsTile(
                      icon: themeMode == ThemeMode.dark
                          ? Icons.wb_sunny_outlined
                          : Icons.dark_mode_outlined,
                      label: 'Thème',
                      trailing: Switch(
                        value: themeMode == ThemeMode.dark,
                        onChanged: (_) =>
                            ref.read(themeModeProvider.notifier).toggle(),
                        activeColor: AppColors.primary,
                      ),
                      isLast: true,
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // ─── Logout ──────────────────────────────────────────────
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Déconnexion'),
                          content: const Text(
                              'Êtes-vous sûr de vouloir vous déconnecter ?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, false),
                              child: const Text('Annuler'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, true),
                              child: const Text(
                                'Déconnexion',
                                style: TextStyle(color: AppColors.error),
                              ),
                            ),
                          ],
                        ),
                      );
                      if (confirm == true) {
                        await ref.read(authNotifierProvider.notifier).logout();
                        if (context.mounted) context.go('/');
                      }
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error,
                      side: const BorderSide(color: AppColors.error),
                    ),
                    icon: const Icon(Icons.logout),
                    label: const Text('Se déconnecter'),
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  final String value;
  final String label;

  const _StatBox({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 16,
            fontFamily: 'Poppins',
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 11,
            fontFamily: 'Poppins',
          ),
        ),
      ],
    );
  }
}

class _SectionCard extends StatelessWidget {
  final List<Widget> children;
  const _SectionCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.3)),
      ),
      child: Column(children: children),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool isLast;

  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Icon(icon, size: 20, color: AppColors.textSecondary),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      value,
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (!isLast) const Divider(height: 1, indent: 48),
      ],
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Widget? trailing;
  final bool isLast;

  const _SettingsTile({
    required this.icon,
    required this.label,
    this.trailing,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Icon(icon, size: 20, color: AppColors.textSecondary),
              const SizedBox(width: 12),
              Expanded(
                child: Text(label, style: theme.textTheme.bodyMedium),
              ),
              if (trailing != null) trailing!,
            ],
          ),
        ),
        if (!isLast) const Divider(height: 1, indent: 48),
      ],
    );
  }
}

class _NotLoggedInView extends StatelessWidget {
  final VoidCallback onLogin;
  const _NotLoggedInView({required this.onLogin});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.person_outline, size: 80, color: AppColors.textTertiary),
            const SizedBox(height: 24),
            Text(
              'Connectez-vous pour accéder à votre profil',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: onLogin,
                icon: const Icon(Icons.login),
                label: const Text('Se connecter'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

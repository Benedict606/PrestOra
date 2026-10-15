import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:prestora/app/view/admin/admin_data.dart';
import 'package:prestora/app/view/login/login.dart';
import 'package:prestora/controller/cubit/cubit.dart';

void openProfileDialog(BuildContext context, MainCubit action) {
  final me = adminStore.comptes.firstWhere(
    (c) => c.id == adminStore.currentUserId,
  );

  showDialog<void>(
    context: context,
    barrierColor: Colors.black38,
    builder: (ctx) {
      final scheme = Theme.of(ctx).colorScheme;
      final t = Theme.of(ctx).textTheme;
      final isDark = Theme.of(ctx).brightness == Brightness.dark;

      return Dialog(
        alignment: Alignment.topRight,
        insetPadding: EdgeInsets.only(
          top: MediaQuery.paddingOf(ctx).top + kToolbarHeight + 4,
          right: 16,
          left: 16,
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 320),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── En-tête : avatar + nom + rôle ──
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: scheme.primaryContainer,
                      child: Text(
                        me.nomComplet.isNotEmpty
                            ? me.nomComplet[0].toUpperCase()
                            : '?',
                        style: t.headlineMedium?.copyWith(
                          color: scheme.primary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            me.nomComplet,
                            style: t.headlineSmall,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(me.type.label, style: t.bodySmall),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),

              // ── Fonctions ──
              _MenuTile(
                icon: Icons.person_outline,
                label: 'Mon profil',
                onTap: () {
                  Navigator.pop(ctx);
                  // TODO: navigation vers la page profil
                },
              ),
              _MenuTile(
                icon: Icons.settings_outlined,
                label: 'Paramètres',
                onTap: () {
                  Navigator.pop(ctx);
                  // TODO: navigation vers la page paramètres
                },
              ),

              // ── Mode sombre / clair (fonctionne déjà via le cubit) ──
              ListTile(
                leading: Icon(
                  isDark ? Icons.dark_mode_outlined : Icons.light_mode_outlined,
                  color: scheme.onSurfaceVariant,
                ),
                title: Text(isDark ? 'Mode sombre' : 'Mode clair'),
                trailing: Switch(
                  value: isDark,
                  onChanged: (_) => action.changeThemeMode(),
                ),
                onTap: action.changeThemeMode,
              ),

              const Divider(height: 1),

              // ── Déconnexion ──
              _MenuTile(
                icon: Icons.logout,
                label: 'Se déconnecter',
                color: scheme.error,
                onTap: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => const Login()),
                  );
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      );
    },
  );
}

void openNotificationsDialog(BuildContext context) {
  // Remplace par tes vraies données plus tard
  const items = <(IconData, String, String, String)>[
    (
      Icons.person_add_alt_outlined,
      'Nouveau compte créé',
      'Un enseignant vient d\'être ajouté.',
      'Il y a 5 min',
    ),
    (
      Icons.menu_book_outlined,
      'Cours non affecté',
      '3 cours attendent une affectation.',
      'Il y a 1 h',
    ),
    (
      Icons.payments_outlined,
      'Barème modifié',
      'Le taux horaire d\'un grade a été mis à jour.',
      'Hier',
    ),
  ];

  showDialog<void>(
    context: context,
    barrierColor: Colors.black38,
    builder: (ctx) {
      final scheme = Theme.of(ctx).colorScheme;
      final t = Theme.of(ctx).textTheme;

      return Dialog(
        alignment: Alignment.topRight,
        insetPadding: EdgeInsets.only(
          top: MediaQuery.paddingOf(ctx).top + kToolbarHeight + 4,
          right: 16,
          left: 16,
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 8, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text('Notifications', style: t.headlineMedium),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Tout lire'),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              for (final (icon, title, body, time) in items)
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 4,
                  ),
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: scheme.primaryContainer,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, size: 20, color: scheme.primary),
                  ),
                  title: Text(title, style: t.titleSmall),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text('$body\n$time', style: t.bodySmall),
                  ),
                  isThreeLine: true,
                ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      );
    },
  );
}

class _MenuTile extends StatelessWidget {
  const _MenuTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final c = color ?? scheme.onSurface;
    return ListTile(
      leading: Icon(icon, color: color ?? scheme.onSurfaceVariant),
      title: Text(
        label,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(color: c),
      ),
      onTap: onTap,
    );
  }
}

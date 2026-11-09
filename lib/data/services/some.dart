import 'package:flutter/material.dart';
import 'package:prestora/app/view/admin/admin_data.dart';
import 'package:prestora/app/view/admin/annees.dart';
import 'package:prestora/controller/cubit/cubit.dart';
import 'package:prestora/data/repositories/notification_repository.dart';
import 'package:prestora/data/services/auth_service.dart';
import 'package:prestora/data/services/session.dart';

void openProfileDialog(BuildContext context, MainCubit action) {
  final me = Session.instance.me;
  if (me == null) return;

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
              if (Session.instance.gereAnnees &&
                  me.type != TypeCompte.administrateur)
                _MenuTile(
                  icon: Icons.event_note_outlined,
                  label: 'Années académiques',
                  onTap: () {
                    Navigator.pop(ctx);
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(builder: (_) => const AnneesPage()),
                    );
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
                onTap: () async {
                  Navigator.pop(ctx);
                  Navigator.of(context).popUntil((r) => r.isFirst);
                  // Le routeur renvoie vers la connexion dès que la session est vide.
                  await AuthService.signOut();
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

/// Cloche des notifications avec compteur de non lues.
class NotifBell extends StatelessWidget {
  const NotifBell({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: notificationStore,
      builder: (context, _) {
        final n = notificationStore.nonLues;
        return IconButton(
          tooltip: 'Notifications',
          onPressed: () => openNotificationsDialog(context),
          icon: Badge(
            isLabelVisible: n > 0,
            label: Text(n > 9 ? '9+' : '$n'),
            child: const Icon(Icons.notifications_none),
          ),
        );
      },
    );
  }
}

String _ilYa(DateTime d) {
  final diff = DateTime.now().difference(d);
  if (diff.inMinutes < 1) return "À l'instant";
  if (diff.inMinutes < 60) return 'Il y a ${diff.inMinutes} min';
  if (diff.inHours < 24) return 'Il y a ${diff.inHours} h';
  if (diff.inDays == 1) return 'Hier';
  return 'Il y a ${diff.inDays} j';
}

IconData _iconeNotif(String type) => switch (type) {
  'SEANCE' => Icons.event_note_outlined,
  'COURS' => Icons.menu_book_outlined,
  'DOSSIER' => Icons.description_outlined,
  'REJET' => Icons.reply_outlined,
  'PAIEMENT' => Icons.payments_outlined,
  _ => Icons.notifications_none,
};

void openNotificationsDialog(BuildContext context) {
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
          constraints: BoxConstraints(
            maxWidth: 360,
            maxHeight: MediaQuery.of(ctx).size.height * 0.7,
          ),
          child: ListenableBuilder(
            listenable: notificationStore,
            builder: (ctx, _) {
              final items = notificationStore.liste;
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 8, 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Notifications',
                            style: t.headlineMedium,
                          ),
                        ),
                        TextButton(
                          onPressed: notificationStore.nonLues == 0
                              ? null
                              : notificationStore.toutLire,
                          child: const Text('Tout lire'),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  if (items.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(24),
                      child: Text('Aucune notification.'),
                    )
                  else
                    Flexible(
                      child: ListView(
                        shrinkWrap: true,
                        children: [
                          for (final n in items)
                            ListTile(
                              onTap: () => notificationStore.lire(n),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 4,
                              ),
                              tileColor: n.lu
                                  ? null
                                  : scheme.primaryContainer.withValues(
                                      alpha: 0.25,
                                    ),
                              leading: Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: scheme.primaryContainer,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  _iconeNotif(n.type),
                                  size: 20,
                                  color: scheme.primary,
                                ),
                              ),
                              title: Text(
                                n.titre,
                                style: t.titleSmall?.copyWith(
                                  fontWeight: n.lu
                                      ? FontWeight.w500
                                      : FontWeight.w700,
                                ),
                              ),
                              subtitle: Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: Text(
                                  '${n.message}\n${_ilYa(n.date)}',
                                  style: t.bodySmall,
                                ),
                              ),
                              isThreeLine: true,
                            ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 8),
                ],
              );
            },
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

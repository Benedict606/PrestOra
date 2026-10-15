import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:prestora/app/shared/styles/colors.dart';
import 'package:prestora/app/shared/styles/icons.dart';
import 'package:prestora/app/shared/styles/images.dart';
import 'package:prestora/controller/cubit/cubit.dart';
import 'package:prestora/controller/state/state.dart';
import 'package:prestora/data/services/some.dart';

import 'admin_data.dart';
import 'admin_modules.dart';

class Admin extends StatelessWidget {
  static const route = '/admin';
  const Admin({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final t = theme.textTheme;

    void _openDialog() {
      showDialog<void>(
        context: context,
        builder: (ctx) => Dialog(
          // Aligne le dialogue en haut avec une marge optionnelle
          alignment: Alignment.topCenter,
          child: Container(
            padding: const EdgeInsets.all(16.0),
            margin: EdgeInsets.only(top: 20),
            child: const Text("data"),
          ),
        ),
      );
    }

    return BlocConsumer<MainCubit, MainState>(
      listener: (context, state) {},
      builder: (context, state) {
        final action = MainCubit.get(context);

        return Scaffold(
          // ─────────────  AppBar  ─────────────
          appBar: AppBar(
            title: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Color(0xFF7B3AEC),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(5),
                    child: Image.asset(AppImages.logo, fit: BoxFit.contain),
                  ),
                ),
                const SizedBox(width: 12),
                const Text('PrestOra'),
              ],
            ),
            actions: [
              Stack(
                children: [
                  IconButton(
                    onPressed: () => openNotificationsDialog(context),
                    icon: Icon(AppIcons.notification),
                  ),
                  Positioned(
                    right: 12,
                    top: 12,
                    child: Container(
                      height: 5,
                      width: 5,
                      decoration: BoxDecoration(
                        color: AppColors.tdError,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 5),
              GestureDetector(
                onTap: () => openProfileDialog(context, action),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainerHigh,
                    shape: BoxShape.circle,
                    border: Border.all(color: scheme.outline),
                  ),
                  child: Center(
                    child: Text(
                      adminStore.comptes
                          .firstWhere((c) => c.id == adminStore.currentUserId)
                          .nomComplet[0]
                          .toUpperCase(),
                      style: t.headlineMedium,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
            ],
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(1),
              child: Divider(
                height: 1,
                thickness: 1,
                color: Theme.of(context).colorScheme.outlineVariant,
              ),
            ),
          ),

          // ───────────── ADM-01 : hub administrateur ─────────────
          body: const _AdminHome(),
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  ADM-01 · Accueil Administrateur
// ═══════════════════════════════════════════════════════════════
class _AdminHome extends StatelessWidget {
  const _AdminHome();

  void _go(BuildContext context, Widget page) {
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => page));
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final me = adminStore.comptes.firstWhere(
      (c) => c.id == adminStore.currentUserId,
    );

    String getGreeting() {
      final int hour = DateTime.now().hour;

      if (hour >= 5 && hour < 12) {
        return "Bonjour,";
      } else if (hour >= 12 && hour < 17) {
        return "Bon après-midi";
      } else if (hour >= 17 && hour < 21) {
        return "Bonsoir";
      } else if (hour >= 21 && hour < 24) {
        return "Bonne nuit";
      } else {
        // Entre 00h00 et 04h59
        return "Bon matin";
      }
    }

    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: ListenableBuilder(
          listenable: adminStore,
          builder: (context, _) => ListView(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
            children: [
              // ── Salutation ──
              Text(getGreeting(), style: t.bodyLarge),
              const SizedBox(height: 4),
              Text(me.nomComplet, style: t.displaySmall),
              const SizedBox(height: 4),
              Text(me.type.label, style: t.bodySmall),
              const SizedBox(height: 24),

              // ── Compteurs ──
              Row(
                children: [
                  Expanded(
                    child: _KpiCard(
                      icon: Icons.verified_user_outlined,
                      value: '${adminStore.comptesActifs}',
                      label: 'Comptes \nactifs',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _KpiCard(
                      icon: Icons.person_off_outlined,
                      value: '${adminStore.comptesInactifs}',
                      label: 'Comptes \ndésactivés',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _KpiCard(
                      icon: Icons.account_balance_outlined,
                      value: '${adminStore.facultes.length}',
                      label: 'Facultés',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _KpiCard(
                      icon: Icons.menu_book_outlined,
                      value: '${adminStore.cours.length}',
                      label: 'Cours',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // ── Modules ──
              Text('Configuration', style: t.displaySmall),

              const SizedBox(height: 22),

              _ModuleCard(
                icon: Icons.manage_accounts_outlined,
                title: 'Comptes utilisateurs',
                subtitle:
                    '${adminStore.comptes.length} comptes · ${adminStore.comptesInactifs} désactivé(s)',
                onTap: () => _go(context, const ComptesPage()),
              ),
              const SizedBox(height: 15),
              _ModuleCard(
                icon: Icons.account_tree_outlined,
                title: 'Facultés et des promotions',
                subtitle:
                    '${adminStore.facultes.length} facultés · '
                    '${adminStore.facultes.fold<int>(0, (s, f) => s + f.promotions.length)} promotions',
                onTap: () => _go(context, const FacultesPage()),
              ),
              const SizedBox(height: 15),
              _ModuleCard(
                icon: Icons.menu_book_outlined,
                title: 'Gestion des cours',
                subtitle:
                    '${adminStore.cours.length} cours · '
                    '${adminStore.cours.where((c) => !c.affecte).length} non affecté(s)',
                onTap: () => _go(context, const CoursPage()),
              ),
              const SizedBox(height: 15),
              _ModuleCard(
                icon: Icons.payments_outlined,
                title: 'Barèmes de taux horaire',
                subtitle:
                    '${adminStore.baremes.length} grades · '
                    '${fmtTaux(adminStore.baremes.first.taux)} à ${fmtTaux(adminStore.baremes.last.taux)}',
                onTap: () => _go(context, const BaremesPage()),
              ),

              const SizedBox(height: 50),
            ],
          ),
        ),
      ),
    );
  }
}

class _KpiCard extends StatelessWidget {
  const _KpiCard({
    required this.icon,
    required this.value,
    required this.label,
  });
  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: scheme.primaryContainer,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 20, color: scheme.primary),
            ),
            const SizedBox(height: 12),
            Text(value, style: t.displaySmall),
            const SizedBox(height: 2),
            Text(label, style: t.bodySmall),
          ],
        ),
      ),
    );
  }
}

class _ModuleCard extends StatelessWidget {
  const _ModuleCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    return Card(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: scheme.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: scheme.primary, size: 26),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: t.headlineSmall),
                    const SizedBox(height: 4),
                    Text(subtitle, style: t.bodySmall),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: scheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}

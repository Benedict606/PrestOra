import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:prestora/app/shared/styles/colors.dart';
import 'package:prestora/app/shared/styles/icons.dart';
import 'package:prestora/app/shared/styles/images.dart';
import 'package:prestora/app/view/admin/admin_modules.dart';
import 'package:prestora/controller/cubit/cubit.dart';
import 'package:prestora/controller/state/state.dart';
import 'package:prestora/data/services/some.dart';

// Widgets partagés définis dans la page Admin (à déplacer dans un dossier commun plus tard).
import 'encadreur_data.dart';
import 'encadreur_modules.dart';

class Encadreur extends StatelessWidget {
  static const route = '/encadreur';
  const Encadreur({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final t = theme.textTheme;

    return BlocConsumer<MainCubit, MainState>(
      listener: (context, state) {},
      builder: (context, state) {
        final action = MainCubit.get(context);

        return Scaffold(
          // ───────────── Même AppBar que les pages Admin ─────────────
          appBar: AppBar(
            automaticallyImplyLeading: false,
            title: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: const Color(0xFF7B3AEC),
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
                      encadreurStore.initiale,
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
                color: scheme.outlineVariant,
              ),
            ),
          ),

          // ───────────── ENC-01 : accueil de l'encadreur ─────────────
          body: const _EncadreurHome(),
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  ENC-01 · Accueil Encadreur
// ═══════════════════════════════════════════════════════════════
class _EncadreurHome extends StatefulWidget {
  const _EncadreurHome();

  @override
  State<_EncadreurHome> createState() => _EncadreurHomeState();
}

class _EncadreurHomeState extends State<_EncadreurHome> {
  String _q = '';

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;

    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: ListenableBuilder(
          listenable: encadreurStore,
          builder: (context, _) {
            final q = _q.toLowerCase();
            // Tri : les promotions avec le plus de cours non suivis d'abord
            final list =
                encadreurStore.promotions
                    .where(
                      (p) =>
                          q.isEmpty ||
                          p.nom.toLowerCase().contains(q) ||
                          p.departement.toLowerCase().contains(q),
                    )
                    .toList()
                  ..sort((a, b) => b.nonSuivis.compareTo(a.nonSuivis));

            return ListView(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
              children: [
                // ── En-tête ──
                Text('Bonjour,', style: t.bodyLarge),
                const SizedBox(height: 4),
                Text(encadreurStore.nom, style: t.displaySmall),
                const SizedBox(height: 4),
                Text(
                  'Encadreur pédagogique · Faculté ${encadreurStore.faculte}',
                  style: t.bodySmall,
                ),
                const SizedBox(height: 24),

                // ── Compteurs ──
                Row(
                  children: [
                    Expanded(
                      child: _KpiCard(
                        icon: Icons.person_add_alt_1_outlined,
                        value: '${encadreurStore.nbANonAffectes}',
                        label: 'Cours à affecter',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _KpiCard(
                        icon: Icons.task_alt,
                        value: '${encadreurStore.nbACloturer}',
                        label: 'Cours à clôturer',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                // ── Promotions ──
                Text('Mes promotions', style: t.displaySmall),
                const SizedBox(height: 25),
                SearchBox(
                  hint: 'Rechercher une promotion',
                  onChanged: (v) => setState(() => _q = v),
                ),
                const SizedBox(height: 16),
                if (list.isEmpty)
                  const EmptyState(
                    message:
                        'Aucune promotion ne correspond à votre recherche.',
                  )
                else
                  for (final p in list)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _PromotionCard(
                        promotion: p,
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => PromotionDetailPage(promotion: p),
                          ),
                        ),
                      ),
                    ),
                const SizedBox(height: 30),
              ],
            );
          },
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

class _PromotionCard extends StatelessWidget {
  const _PromotionCard({required this.promotion, required this.onTap});
  final PromotionEnc promotion;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final p = promotion;
    return Card(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(p.nom, style: t.headlineLarge),
                    const SizedBox(height: 2),
                    Text(
                      'Faculté ${encadreurStore.faculte} · ${p.departement}',
                      style: t.bodySmall,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Chef : ${p.chef ?? 'non assigné'}',
                      style: t.bodySmall?.copyWith(
                        color: p.chef == null ? scheme.error : null,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        p.nonSuivis > 0
                            ? StatusPill(
                                '${p.nonSuivis} cours non suivis',
                                tone: PillTone.danger,
                              )
                            : const StatusPill(
                                'Tous les cours suivis',
                                tone: PillTone.brand,
                              ),
                        StatusPill('${p.cours.length} cours'),
                      ],
                    ),
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

import 'package:cloud_firestore/cloud_firestore.dart';
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

import 'etudiant_data.dart';
import 'etudiant_modules.dart';

class Etudiant extends StatelessWidget {
  static const route = '/etudiant';
  const Etudiant({super.key});

  Future<void> ajouterProduit() async {
    try {
      await FirebaseFirestore.instance.collection('produits').add({
        'nom': 'Article Test',
        'prix': 2500,
        'createdAt': FieldValue.serverTimestamp(),
      });
      print("Produit ajouté avec succès !");
    } catch (e) {
      print("Erreur : $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final t = theme.textTheme;

    void _openDialog() {
      showDialog<void>(
        context: context,
        builder: (ctx) => Dialog(
          alignment: Alignment.topCenter,
          child: Container(
            padding: const EdgeInsets.all(16.0),
            margin: const EdgeInsets.only(top: 20),
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
          // ──────────── AppBar ─────────────
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
                      etudiantStore.nom.substring(0, 1),
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

          // ───────────── CP-01 : accueil du chef de promotion ─────────────
          body: const _EtudiantHome(),
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  CP-01 · Accueil Chef de promotion
// ═══════════════════════════════════════════════════════════════
enum _Filtre { tous, enCours, aCloturer, clotures }

class _EtudiantHome extends StatefulWidget {
  const _EtudiantHome();

  @override
  State<_EtudiantHome> createState() => _EtudiantHomeState();
}

class _EtudiantHomeState extends State<_EtudiantHome> {
  _Filtre _filtre = _Filtre.tous;

  bool _match(CoursSuivi c) => switch (_filtre) {
    _Filtre.tous => true,
    _Filtre.enCours => c.statut == StatutCours.enCours,
    _Filtre.aCloturer => c.statut == StatutCours.valideParEnseignant,
    _Filtre.clotures => c.statut == StatutCours.cloture,
  };

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;

    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: ListenableBuilder(
          listenable: etudiantStore,
          builder: (context, _) {
            final list = etudiantStore.cours.where(_match).toList();
            return ListView(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
              children: [
                // ── En-tête ──
                Text('Bonjour,', style: t.bodyLarge),
                const SizedBox(height: 4),
                Text(etudiantStore.nom, style: t.displaySmall),
                const SizedBox(height: 4),
                Text(
                  'Chef de promotion · ${etudiantStore.promotion} · ${etudiantStore.faculte}',
                  style: t.bodySmall,
                ),
                const SizedBox(height: 24),

                // ── Compteurs ──
                Row(
                  children: [
                    Expanded(
                      child: _KpiCard(
                        icon: Icons.menu_book_outlined,
                        value: '${etudiantStore.nbCoursActifs}',
                        label: 'Cours en suivi',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _KpiCard(
                        icon: Icons.hourglass_top_outlined,
                        value: '${etudiantStore.nbAValider}',
                        label: "Séances à valider",
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _KpiCard(
                  icon: Icons.schedule_outlined,
                  value: fmtH(etudiantStore.totalHeures),
                  label: 'Heures prestées au total',
                  wide: true,
                ),
                const SizedBox(height: 32),

                // ── Liste des cours ──
                Text('Cours de la promotion', style: t.displaySmall),
                const SizedBox(height: 30),
                PillRow(
                  children: [
                    FilterPill(
                      label: 'Tous',
                      selected: _filtre == _Filtre.tous,
                      onTap: () => setState(() => _filtre = _Filtre.tous),
                    ),
                    FilterPill(
                      label: 'En cours',
                      selected: _filtre == _Filtre.enCours,
                      onTap: () => setState(() => _filtre = _Filtre.enCours),
                    ),
                    FilterPill(
                      label: 'À clôturer',
                      selected: _filtre == _Filtre.aCloturer,
                      onTap: () => setState(() => _filtre = _Filtre.aCloturer),
                    ),
                    FilterPill(
                      label: 'Clôturés',
                      selected: _filtre == _Filtre.clotures,
                      onTap: () => setState(() => _filtre = _Filtre.clotures),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (list.isEmpty)
                  const EmptyState(message: 'Aucun cours dans cette catégorie.')
                else
                  for (final c in list)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _CoursCard(
                        cours: c,
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => CoursDetailPage(cours: c),
                          ),
                        ),
                      ),
                    ),
                SizedBox(height: 30),
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
    this.wide = false,
  });
  final IconData icon;
  final String value;
  final String label;
  final bool wide;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    final iconBox = Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: scheme.primaryContainer,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, size: 20, color: scheme.primary),
    );
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: wide
            ? Row(
                children: [
                  iconBox,
                  const SizedBox(width: 16),
                  Expanded(child: Text(label, style: t.bodySmall)),
                  Text(value, style: t.displaySmall),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  iconBox,
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

class _CoursCard extends StatelessWidget {
  const _CoursCard({required this.cours, required this.onTap});
  final CoursSuivi cours;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    return Card(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    cours.code,
                    style: t.titleSmall?.copyWith(color: scheme.primary),
                  ),
                  const Spacer(),
                  CoursStatutPill(cours.statut),
                ],
              ),
              const SizedBox(height: 6),
              Text(cours.intitule, style: t.headlineSmall),
              const SizedBox(height: 4),
              Text(
                '${cours.enseignant} · ${cours.credits} crédits',
                style: t.bodySmall,
              ),
              const SizedBox(height: 16),
              HeuresProgress(cours: cours),
              if (cours.nbEncodees > 0 && !cours.cloture) ...[
                const SizedBox(height: 12),
                StatusPill(
                  "${cours.nbEncodees} séance(s) en attente de l'enseignant",
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

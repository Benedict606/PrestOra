import 'package:flutter/material.dart';
import 'package:prestora/app/view/admin/admin_modules.dart';
import 'package:prestora/app/view/payslip/authority/paie_data.dart';
import 'package:prestora/app/view/payslip/authority/paie_widgets.dart';
import 'package:prestora/app/view/prestation/student/etudiant_data.dart';

// ═══════════════════════════════════════════════════════════════
//  CPT-03 · Enregistrement du paiement et clôture du dossier
// ═══════════════════════════════════════════════════════════════
class PaiementPage extends StatefulWidget {
  const PaiementPage({super.key, required this.dossier});
  final DossierWf dossier;

  @override
  State<PaiementPage> createState() => _PaiementPageState();
}

class _PaiementPageState extends State<PaiementPage> {
  static const _modes = ['Virement bancaire', 'Bon de caisse', 'Mobile Money'];

  late String _mode = widget.dossier.mode == 'Banque'
      ? 'Virement bancaire'
      : 'Mobile Money';
  late DateTime _date = kMaintenant;
  final _reference = TextEditingController();
  final _imputation = TextEditingController();
  String? _bordereau;
  String? _eReference;
  String? _eBordereau;

  @override
  void dispose() {
    _reference.dispose();
    _imputation.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: widget.dossier.recuLe,
      lastDate: kMaintenant,
    );
    if (d != null) setState(() => _date = d);
  }

  Future<void> _payer() async {
    setState(() {
      _eReference = _reference.text.trim().length < 4
          ? 'Saisissez la référence de la transaction'
          : null;
      _eBordereau = _bordereau == null
          ? 'Le bordereau ou la preuve de paiement est obligatoire'
          : null;
    });
    if (_eReference != null || _eBordereau != null) return;

    final d = widget.dossier;
    final ok = await confirmDialog(
      context,
      title: 'Clôturer le dossier ?',
      message:
          'Le paiement de ${fmtMontant(d.net)} à ${d.enseignant} sera enregistré. Action définitive : le dossier passera au statut « Payé » et la quittance sera générée.',
      confirmLabel: 'Payer et clôturer',
    );
    if (!ok || !mounted) return;

    paieStore.payer(
      d,
      reference: _reference.text.trim(),
      date: _date,
      modeReglement: _mode,
      bordereau: _bordereau!,
      imputation: _imputation.text.trim(),
    );
    final messenger = ScaffoldMessenger.of(context);
    Navigator.of(context).popUntil((r) => r.isFirst);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            'Dossier ${d.reference} payé. Quittance générée ; enseignant et secrétaire notifiés.',
          ),
        ),
      );
  }

  Future<void> _rejeter() async {
    final d = widget.dossier;
    final motif = await showRejetSheet(context, d);
    if (motif == null || !mounted) return;
    paieStore.rejeter(d, motif);
    final messenger = ScaffoldMessenger.of(context);
    Navigator.of(context).popUntil((r) => r.isFirst);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            'Dossier ${d.reference} rejeté. Le secrétaire est notifié.',
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final d = widget.dossier;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Enregistrer le paiement'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(height: 1, thickness: 1, color: scheme.outlineVariant),
        ),
      ),
      bottomNavigationBar: DecoratedBox(
        decoration: BoxDecoration(
          color: scheme.surface,
          border: Border(top: BorderSide(color: scheme.outlineVariant)),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: scheme.error,
                    ),
                    onPressed: _rejeter,
                    icon: const Icon(Icons.close, size: 18),
                    label: const Text('Rejeter'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: FilledButton.icon(
                    onPressed: _payer,
                    icon: const Icon(Icons.task_alt, size: 18),
                    label: const Text('Payer et clôturer'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              // ── Récapitulatif ──
              InfoSection('Récapitulatif', [
                InfoRow('Dossier', d.reference),
                InfoRow('Enseignant', d.enseignant),
                InfoRow('Cours', '${d.code} · ${d.intitule}'),
                InfoRow('Faculté', d.faculte),
                InfoRow('Heures prestées', fmtH(d.heures)),
                InfoRow('Net à payer', fmtMontant(d.net), strong: true),
              ]),
              const SizedBox(height: 12),
              InfoSection(
                'Coordonnées de paiement',
                [
                  InfoRow('Mode prévu', d.mode),
                  InfoRow('Coordonnées', d.coordonnees),
                ],
                footer: 'Vérifiez ces informations avant de régler.',
              ),
              const SizedBox(height: 24),

              // ── Formulaire de règlement ──
              Text('Règlement', style: t.headlineMedium),
              const SizedBox(height: 16),
              Text('MODE DE RÈGLEMENT', style: t.labelSmall),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final m in _modes)
                    FilterPill(
                      label: m,
                      selected: _mode == m,
                      onTap: () => setState(() => _mode = m),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _reference,
                textCapitalization: TextCapitalization.characters,
                onChanged: (_) => setState(() => _eReference = null),
                decoration: InputDecoration(
                  labelText: 'Référence de la transaction',
                  hintText: 'VIR-2026-1015-001',
                  prefixIcon: const Icon(Icons.tag),
                  errorText: _eReference,
                ),
              ),
              const SizedBox(height: 16),
              Text('DATE DE PAIEMENT', style: t.labelSmall),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _pickDate,
                  icon: const Icon(Icons.event_outlined, size: 18),
                  label: Text(fmtDate(_date)),
                ),
              ),
              const SizedBox(height: 16),
              InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Montant payé',
                  helperText: 'Égal au net à payer (non modifiable)',
                  prefixIcon: Icon(Icons.payments_outlined),
                ),
                child: Text(fmtMontant(d.net), style: t.bodyMedium),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _imputation,
                decoration: const InputDecoration(
                  labelText: 'Imputation budgétaire (facultatif)',
                  prefixIcon: Icon(Icons.account_tree_outlined),
                ),
              ),
              const SizedBox(height: 20),

              // ── Bordereau ──
              Text('BORDEREAU OU PREUVE DE PAIEMENT', style: t.labelSmall),
              const SizedBox(height: 8),
              if (_bordereau == null)
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    // TODO : brancher image_picker / file_picker
                    onPressed: () => setState(() {
                      _bordereau = 'bordereau_${d.reference}.pdf';
                      _eBordereau = null;
                    }),
                    icon: const Icon(Icons.attach_file, size: 18),
                    label: const Text('Joindre le bordereau (photo ou PDF)'),
                  ),
                )
              else
                Row(
                  children: [
                    Icon(
                      Icons.description_outlined,
                      size: 18,
                      color: scheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _bordereau!,
                        style: t.bodyMedium?.copyWith(color: scheme.primary),
                      ),
                    ),
                    TextButton(
                      onPressed: () => setState(() => _bordereau = null),
                      child: const Text('Retirer'),
                    ),
                  ],
                ),
              if (_eBordereau != null) ...[
                const SizedBox(height: 6),
                Text(
                  _eBordereau!,
                  style: t.bodySmall?.copyWith(color: scheme.error),
                ),
              ],
              const SizedBox(height: 16),
              Text(
                'À la clôture, une quittance PDF certifiée est générée et l\'enseignant ainsi que la faculté sont notifiés.',
                style: t.bodySmall,
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

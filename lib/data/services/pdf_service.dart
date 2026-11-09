import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:prestora/app/view/payslip/authority/paie_data.dart'
    show DossierWf;
import 'package:prestora/app/view/prestation/student/etudiant_data.dart';
import 'package:prestora/core/notify.dart';
import 'package:prestora/data/firebase/fb.dart';
import 'package:prestora/data/services/session.dart';

// ═══════════════════════════════════════════════════════════════
//  PDF : fiche individuelle de prestation + état de paie.
//  Mise en page calquée sur les modèles papier de l'UCB.
//  Polices PDF intégrées (Helvetica / Times) : on évite les caractères
//  hors Latin-1 (guillemets courbes, tirets longs…) via [_c].
// ═══════════════════════════════════════════════════════════════

String _c(String s) => s
    .replaceAll('’', "'")
    .replaceAll('‘', "'")
    .replaceAll('“', '"')
    .replaceAll('”', '"')
    .replaceAll('–', '-')
    .replaceAll('—', '-')
    .replaceAll('…', '...')
    .replaceAll(' ', ' ')
    .replaceAll(' ', ' ');

String _d(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

String _dLong(DateTime d) {
  const m = [
    'janvier', 'fevrier', 'mars', 'avril', 'mai', 'juin', 'juillet',
    'aout', 'septembre', 'octobre', 'novembre', 'decembre',
  ];
  return '${d.day} ${m[d.month - 1]} ${d.year}';
}

String _h(double v) => v % 1 == 0 ? '${v.toInt()}' : v.toStringAsFixed(1);
String _usd(double v) => '${v.toStringAsFixed(2).replaceAll('.', ',')} USD';

final _bleu = PdfColor.fromInt(0xFF1F3A8A);

class PdfService {
  PdfService._();

  // ───────────── Étape 1 : données → PDF ─────────────

  /// Fiche de prestation d'un cours en cours de suivi.
  static Future<Uint8List> fichePrestationCours(
    CoursSuivi c, {
    String? faculte,
    String? chefPromotion,
  }) async => _fichePrestation(
    annee: c.anneeId,
    faculte: faculte ?? Session.instance.faculteNom ?? '',
    promotion: c.promotionNom,
    cours: c.intitule,
    enseignant: c.enseignant,
    grade: c.grade,
    volume: c.volume,
    seances: c.seances,
    chef: chefPromotion ?? await _chef(c.chefNom, c.chefId),
  );

  /// Fiche de prestation d'un dossier de paie (séances figées).
  static Future<Uint8List> fichePrestationDossier(DossierWf d) async =>
      _fichePrestation(
        annee: d.anneeId,
        faculte: d.faculte,
        promotion: d.promotion,
        cours: d.intitule,
        enseignant: d.enseignant,
        grade: d.grade,
        volume: d.volume,
        seances: d.seances,
        chef: d.chefNom ?? await _chefDeSession(d.id),
      );

  /// Nom du chef de promotion : champ enregistré, sinon lecture du profil.
  static Future<String?> _chef(String? nom, String? chefId) async {
    if (nom != null && nom.isNotEmpty) return nom;
    if (chefId == null || chefId.isEmpty) return null;
    try {
      final d = await Fb.db.collection(Col.utilisateurs).doc(chefId).get();
      final n = d.data()?['nom'] as String?;
      final t = d.data()?['titre'] as String?;
      if (n == null) return null;
      return (t == null || t.isEmpty) ? n : '$t $n';
    } catch (_) {
      return null; // droits insuffisants : on laisse vide
    }
  }

  static Future<String?> _chefDeSession(String sessionId) async {
    try {
      final d = await Fb.db.collection(Col.sessions).doc(sessionId).get();
      return _chef(
        d.data()?['chef_promo_nom'] as String?,
        d.data()?['chef_promo_id'] as String?,
      );
    } catch (_) {
      return null;
    }
  }

  static Future<Uint8List> _fichePrestation({
    required String annee,
    required String faculte,
    required String promotion,
    required String cours,
    required String enseignant,
    required String grade,
    required int volume,
    required List<Seance> seances,
    String? chef,
  }) async {
    final doc = pw.Document(title: 'Fiche de prestation', author: 'PrestOra');
    final tri = [...seances]
      ..sort((a, b) {
        final k = a.date.compareTo(b.date);
        return k != 0 ? k : minutesOf(a.debut).compareTo(minutesOf(b.debut));
      });

    final gras = pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10);
    final fin = pw.TextStyle(fontSize: 9.5);
    final enteteCol = pw.TextStyle(
      font: pw.Font.timesBold(),
      fontSize: 9.5,
    );

    pw.Widget ligne(String label, String valeur) => pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 3),
      child: pw.RichText(
        text: pw.TextSpan(
          children: [
            pw.TextSpan(
              text: '${_c(label)} : ',
              style: pw.TextStyle(font: pw.Font.timesBold(), fontSize: 11),
            ),
            pw.TextSpan(
              text: _c(valeur),
              style: pw.TextStyle(
                fontSize: 11,
                color: _bleu,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );

    pw.Widget cell(String t, {pw.TextStyle? s, pw.Alignment a = pw.Alignment.centerLeft}) =>
        pw.Container(
          alignment: a,
          padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 5),
          child: pw.Text(_c(t), style: s ?? fin),
        );

    var cumul = 0.0;
    final rows = <pw.TableRow>[
      pw.TableRow(
        children: [
          cell('JOUR ET DATE', s: enteteCol),
          cell('NBRE HEURES', s: enteteCol),
          cell('TOTAL CUMULE', s: enteteCol),
          cell('SIGNATURE', s: enteteCol),
          cell('CHAPITRE VU', s: enteteCol),
        ],
      ),
      for (final s in tri)
        () {
          cumul += s.heures;
          return pw.TableRow(
            children: [
              cell(_d(s.date), s: pw.TextStyle(fontSize: 10, color: _bleu)),
              cell(_h(s.heures),
                  s: pw.TextStyle(fontSize: 10, color: _bleu),
                  a: pw.Alignment.center),
              cell(_h(cumul),
                  s: pw.TextStyle(fontSize: 10, color: _bleu),
                  a: pw.Alignment.center),
              pw.Container(
                height: 24,
                alignment: pw.Alignment.center,
                child: s.validee ? _ok() : pw.SizedBox(),
              ),
              cell(
                '${s.chapitre}${s.type == TypeSeance.cm ? '' : ' (${s.type.label})'}',
                s: pw.TextStyle(fontSize: 9.5, color: _bleu),
              ),
            ],
          );
        }(),
      // Lignes vides pour compléter la page comme sur la fiche papier
      for (var i = tri.length; i < 20; i++)
        pw.TableRow(
          children: [
            for (var k = 0; k < 5; k++) pw.SizedBox(height: 24),
          ],
        ),
    ];

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(36, 32, 36, 32),
        footer: (_) => pw.Padding(
          padding: const pw.EdgeInsets.only(top: 6),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('N.B : La signature valide vos prestations', style: gras),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('Visa du Chef de Promotion',
                      style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(height: 8),
                  if (chef != null && chef.isNotEmpty)
                    pw.Text(_c(chef),
                        style: pw.TextStyle(
                          fontSize: 12,
                          fontWeight: pw.FontWeight.bold,
                          color: _bleu,
                        )),
                ],
              ),
            ],
          ),
        ),
        build: (_) => [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('UNIVERSITE CATHOLIQUE DE BUKAVU', style: gras),
              pw.Text('Annee academique $annee', style: gras),
            ],
          ),
          pw.SizedBox(height: 8),
          pw.Padding(
            padding: const pw.EdgeInsets.only(left: 18),
            child: pw.Text('B.P. 285 BUKAVU', style: gras),
          ),
          pw.SizedBox(height: 8),
          pw.Text('VICE-RECTORAT AUX AFFAIRES ACADEMIQUES',
              style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
          if (faculte.isNotEmpty) ...[
            pw.SizedBox(height: 8),
            pw.Padding(
              padding: const pw.EdgeInsets.only(left: 14),
              child: pw.Text(_c('FACULTE ${faculte.toUpperCase()}'),
                  style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
            ),
          ],
          pw.SizedBox(height: 14),
          pw.Center(
            child: pw.Text(
              'FICHE INDIVIDUELLE DE PRESTATION',
              style: pw.TextStyle(
                font: pw.Font.timesBold(),
                fontSize: 17,
                decoration: pw.TextDecoration.underline,
              ),
            ),
          ),
          pw.SizedBox(height: 14),
          ligne('PROMOTION', promotion),
          ligne('COURS', cours),
          ligne('ENSEIGNANT', enseignant),
          ligne('GRADE', grade),
          ligne('VOLUME HORAIRE', '$volume HEURES'),
          pw.SizedBox(height: 4),
          pw.Table(
            border: pw.TableBorder.all(width: 0.8),
            columnWidths: const {
              0: pw.FlexColumnWidth(1.25),
              1: pw.FlexColumnWidth(0.9),
              2: pw.FlexColumnWidth(0.95),
              3: pw.FlexColumnWidth(1.4),
              4: pw.FlexColumnWidth(3.6),
            },
            children: rows,
          ),
        ],
      ),
    );
    return doc.save();
  }

  /// « OK » à main levée : italique gras bleu, légèrement penché,
  /// avec un trait de paraphe dessous.
  static pw.Widget _ok() => pw.Transform.rotate(
    angle: 0.12,
    child: pw.Column(
      mainAxisSize: pw.MainAxisSize.min,
      children: [
        pw.Text(
          'OK',
          style: pw.TextStyle(
            font: pw.Font.timesBoldItalic(),
            fontSize: 15,
            color: _bleu,
          ),
        ),
        pw.Container(width: 26, height: 1.1, color: _bleu),
      ],
    ),
  );

  // ───────────── État de paie ─────────────
  static Future<Uint8List> etatPaie(DossierWf d) async {
    final doc = pw.Document(title: 'Etat de paie ${d.reference}', author: 'PrestOra');
    final dates = d.seances.map((s) => s.date).toList()..sort();
    final debut = dates.isEmpty ? null : dates.first;
    final fin = dates.isEmpty ? null : dates.last;
    final depot = d.dates[1] ?? d.dateInit;

    final base = pw.TextStyle(fontSize: 10.5);
    final gris = pw.TextStyle(fontSize: 10.5, color: PdfColors.grey700);
    final gras = pw.TextStyle(fontSize: 10.5, fontWeight: pw.FontWeight.bold);

    pw.Widget info(String l, String v) => pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 3),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(width: 150, child: pw.Text('${_c(l)} :', style: gris)),
          pw.Expanded(child: pw.Text(_c(v), style: base)),
        ],
      ),
    );

    pw.TableRow tr(String a, String b, [String? c, bool fort = false]) {
      final st = fort ? gras : base;
      pw.Widget cl(String t, pw.TextStyle s) => pw.Padding(
        padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        child: pw.Text(_c(t), style: s),
      );
      return pw.TableRow(
        children: [cl(a, st.copyWith(color: PdfColors.grey800)), cl(b, st), cl(c ?? '', base)],
      );
    }

    // Cachet circulaire (remplace la signature)
    pw.Widget cachet(String role, DateTime? date) {
      if (date == null) {
        return pw.Text('En attente de visa',
            style: pw.TextStyle(
              fontSize: 9,
              fontStyle: pw.FontStyle.italic,
              color: PdfColors.grey600,
            ));
      }
      return pw.Transform.rotateBox(
        angle: -0.2,
        child: pw.Container(
          width: 66,
          height: 66,
          alignment: pw.Alignment.center,
          decoration: pw.BoxDecoration(
            shape: pw.BoxShape.circle,
            border: pw.Border.all(color: _bleu, width: 2.2),
          ),
          child: pw.Container(
            width: 56,
            height: 56,
            alignment: pw.Alignment.center,
            decoration: pw.BoxDecoration(
              shape: pw.BoxShape.circle,
              border: pw.Border.all(color: _bleu, width: 0.8),
            ),
            child: pw.Column(
              mainAxisSize: pw.MainAxisSize.min,
              children: [
                pw.Text('UCB BUKAVU',
                    style: pw.TextStyle(fontSize: 5, color: _bleu, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 2),
                pw.Text('VISA',
                    style: pw.TextStyle(fontSize: 10, color: _bleu, fontWeight: pw.FontWeight.bold)),
                pw.Text(_c(role),
                    style: pw.TextStyle(fontSize: 5.5, color: _bleu, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 1),
                pw.Text(_d(date), style: pw.TextStyle(fontSize: 5.5, color: _bleu)),
              ],
            ),
          ),
        ),
      );
    }

    pw.Widget boite(String titre, String roleCourt, int palier) {
      final nom = d.acteurs[palier] ?? '';
      return pw.Container(
        height: 124,
        padding: const pw.EdgeInsets.all(6),
        alignment: pw.Alignment.topCenter,
        child: pw.Column(
          mainAxisSize: pw.MainAxisSize.min,
          children: [
            pw.Text(_c(titre), style: base, textAlign: pw.TextAlign.center),
            pw.SizedBox(height: 8),
            pw.SizedBox(
              height: 70,
              child: pw.Center(child: cachet(roleCourt, d.dates[palier])),
            ),
            pw.SizedBox(height: 6),
            pw.Text(_c(nom), style: gras, textAlign: pw.TextAlign.center),
          ],
        ),
      );
    }

    final faitLe = d.dates.values.isEmpty
        ? DateTime.now()
        : (d.dates.values.toList()..sort()).last;

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(40, 30, 40, 30),
        build: (_) => [
            pw.Center(
              child: pw.Column(
                children: [
                  pw.Text('UNIVERSITE CATHOLIQUE DE BUKAVU',
                      style: pw.TextStyle(fontSize: 13, color: PdfColors.grey800)),
                  pw.Text('(U.C.B)', style: pw.TextStyle(fontSize: 12, color: PdfColors.grey800)),
                  pw.Text('B.P. 285 Bukavu',
                      style: pw.TextStyle(
                        fontSize: 12,
                        color: PdfColors.grey800,
                        decoration: pw.TextDecoration.underline,
                      )),
                  pw.Text('VICE-RECTORAT AUX AFFAIRES ACADEMIQUES',
                      style: pw.TextStyle(fontSize: 12, color: PdfColors.grey800)),
                ],
              ),
            ),
            pw.SizedBox(height: 10),
            pw.Center(
              child: pw.Text(
                'ETAT DE PAIE ANNEE ACADEMIQUE ${d.anneeId}',
                style: pw.TextStyle(fontSize: 15, fontWeight: pw.FontWeight.bold),
              ),
            ),
            pw.SizedBox(height: 3),
            pw.Center(
              child: pw.Text('N° ${d.reference}',
                  style: pw.TextStyle(fontSize: 9.5, color: PdfColors.grey700)),
            ),
            pw.SizedBox(height: 8),
            info('Faculte demanderesse', d.faculte.toUpperCase()),
            info('Promotion', d.promotion),
            info('Enseignant', d.grade),
            info('Date de depot etat de paie', 'le ${_dLong(depot).toUpperCase()}'),
            pw.SizedBox(height: 8),
            pw.Table(
              border: pw.TableBorder.all(width: 0.8),
              columnWidths: const {
                0: pw.FlexColumnWidth(3),
                1: pw.FlexColumnWidth(2.2),
                2: pw.FlexColumnWidth(2),
              },
              children: [
                tr("Nom de l'enseignant", d.enseignant.toUpperCase()),
                tr('Grade', d.grade),
                tr('Intitule exact du cours', d.intitule.toUpperCase()),
                tr('Date du debut de cours', debut == null ? '-' : 'Le ${_dLong(debut)}'),
                tr('Date de fin de cours', fin == null ? '-' : 'Le ${_dLong(fin)}'),
                tr('Mode de paiement', d.mode),
                tr('Coordonnees (banque / compte)', d.coordonnees),
                tr('Volume horaire prevu', '${d.volume}', 'Heures'),
                tr("Nombre d'heures effectivement prestees", _h(d.heures), 'Heures'),
                tr('Taux horaire a appliquer', _h(d.taux), 'Dollars americains'),
                tr('Montant brut', _usd(d.brut)),
                tr(
                  'Retenue fiscale (${_h(d.retenuePct ?? 0)} %)',
                  '- ${_usd(d.retenues)}',
                ),
                tr('Net a payer', _usd(d.net), 'Dollars americains', true),
              ],
            ),
            pw.SizedBox(height: 10),
            pw.Center(
              child: pw.Text('Fait a Bukavu, le ${_dLong(faitLe).toUpperCase()}',
                  style: gras),
            ),
            pw.SizedBox(height: 8),
            pw.Table(
              border: pw.TableBorder.all(width: 0.8),
              columnWidths: const {
                0: pw.FlexColumnWidth(1),
                1: pw.FlexColumnWidth(1),
              },
              children: [
                pw.TableRow(
                  children: [
                    boite('Visa de la faculte\nLe Doyen', 'DOYEN', 2),
                    boite("Signature de\nl'Administrateur General", 'AG', 5),
                  ],
                ),
                pw.TableRow(
                  children: [
                    boite('Visa du Vice-recteur\naux affaires academiques', 'VRA', 3),
                    boite('Signature du Recteur', 'RECTEUR', 4),
                  ],
                ),
              ],
            ),
            if (d.referencePaiement != null) ...[
              pw.SizedBox(height: 10),
              pw.Text(
                'Paye le ${d.dates[6] == null ? '' : _d(d.dates[6]!)} - Reference du paiement : ${d.referencePaiement}'
                '${d.acteurs[6] == null ? '' : ' - Comptable : ${d.acteurs[6]}'}',
                style: pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
              ),
            ],
        ],
      ),
    );
    return doc.save();
  }

  // ───────────── Étape 2 : partager / aperçu ─────────────

  /// Génère le PDF puis propose : partager (WhatsApp, e-mail, Drive...)
  /// ou aperçu / impression / enregistrement.
  static Future<void> ouvrir(
    BuildContext context, {
    required Future<Uint8List> Function() generer,
    required String nomFichier,
  }) async {
    final nav = Navigator.of(context, rootNavigator: true);
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const PopScope(
        canPop: false,
        child: Center(child: CircularProgressIndicator()),
      ),
    );
    Uint8List octets;
    try {
      octets = await generer();
    } catch (e) {
      nav.pop();
      Notif.erreur('Génération du PDF impossible : $e');
      return;
    }
    nav.pop();
    if (!context.mounted) return;
    final choix = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.share_outlined),
              title: const Text('Partager le PDF'),
              subtitle: const Text('WhatsApp, e-mail, Drive, Bluetooth...'),
              onTap: () => Navigator.pop(ctx, 'partager'),
            ),
            ListTile(
              leading: const Icon(Icons.print_outlined),
              title: const Text('Aperçu, imprimer ou enregistrer'),
              onTap: () => Navigator.pop(ctx, 'apercu'),
            ),
          ],
        ),
      ),
    );
    try {
      if (choix == 'partager') {
        await Printing.sharePdf(bytes: octets, filename: '$nomFichier.pdf');
      } else if (choix == 'apercu') {
        await Printing.layoutPdf(
          name: nomFichier,
          onLayout: (_) async => octets,
        );
      }
    } catch (e) {
      Notif.erreur(e);
    }
  }

  // Raccourcis utilisés par les écrans
  static Future<void> partagerEtat(BuildContext c, DossierWf d) => ouvrir(
    c,
    generer: () => etatPaie(d),
    nomFichier: 'Etat_de_paie_${d.reference}',
  );

  static Future<void> partagerFicheDossier(BuildContext c, DossierWf d) =>
      ouvrir(
        c,
        generer: () => fichePrestationDossier(d),
        nomFichier: 'Fiche_prestation_${d.reference}',
      );

  static Future<void> partagerFicheCours(
    BuildContext c,
    CoursSuivi s, {
    String? faculte,
  }) => ouvrir(
    c,
    generer: () => fichePrestationCours(s, faculte: faculte),
    nomFichier: 'Fiche_prestation_${s.code}',
  );
}

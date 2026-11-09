import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:prestora/core/notify.dart';
import 'package:prestora/data/firebase/fb.dart';
import 'package:prestora/data/services/session.dart';

/// Référence à une photo stockée dans la collection `pieces`.
class PieceRef {
  const PieceRef(this.id, this.nom);
  final String id;
  final String nom;
}

/// Photos (registres signés, bordereaux) compressées puis stockées dans
/// Firestore (collection `pieces`, ≤ ~650 Ko par photo). Aucun forfait
/// Blaze nécessaire ; migrable vers Firebase Storage plus tard.
class PieceService {
  static const _maxOctets = 650 * 1024;

  /// Propose appareil photo / galerie, compresse, envoie. null si annulé.
  static Future<PieceRef?> choisir(
    BuildContext context, {
    required String prefixe,
  }) async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Prendre une photo'),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choisir dans la galerie'),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source == null) return null;
    try {
      final x = await ImagePicker().pickImage(
        source: source,
        maxWidth: 1280,
        maxHeight: 1280,
        imageQuality: 55,
      );
      if (x == null) return null;
      final bytes = await x.readAsBytes();
      if (bytes.length > _maxOctets) {
        Notif.erreur(
          Exception(
            'Photo trop lourde (${(bytes.length / 1024).round()} Ko). '
            'Reprenez-la en plus petit format.',
          ),
        );
        return null;
      }
      final uid = Fb.auth.currentUser?.uid;
      if (uid == null) return null;
      final nom = '${prefixe}_${DateTime.now().millisecondsSinceEpoch ~/ 1000}.jpg';
      final ref = await Fb.db.collection(Col.pieces).add({
        'owner_id': uid,
        'annee_id': Session.instance.active?.id,
        'nom': nom,
        'mime': 'image/jpeg',
        'taille': bytes.length,
        'data': base64Encode(bytes),
        'cree_le': FieldValue.serverTimestamp(),
      });
      return PieceRef(ref.id, nom);
    } catch (e) {
      Notif.erreur(e);
      return null;
    }
  }

  /// Affiche la photo (chargée à la demande).
  static Future<void> voir(BuildContext context, String? id, String nom) {
    return showDialog<void>(
      context: context,
      builder: (ctx) {
        final t = Theme.of(ctx).textTheme;
        return Dialog(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(nom, style: t.titleSmall),
                const SizedBox(height: 12),
                if (id == null || id.isEmpty)
                  const Text('Aucun aperçu disponible pour cette pièce.')
                else
                  FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                    future: Fb.db.collection(Col.pieces).doc(id).get(),
                    builder: (c, s) {
                      if (s.connectionState != ConnectionState.done) {
                        return const SizedBox(
                          height: 160,
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }
                      final data = s.data?.data()?['data'] as String?;
                      if (s.hasError || data == null) {
                        return const Text('Photo introuvable ou accès refusé.');
                      }
                      final Uint8List b = base64Decode(data);
                      return ConstrainedBox(
                        constraints: BoxConstraints(
                          maxHeight: MediaQuery.of(c).size.height * 0.6,
                        ),
                        child: InteractiveViewer(
                          child: Image.memory(b, fit: BoxFit.contain),
                        ),
                      );
                    },
                  ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Fermer'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

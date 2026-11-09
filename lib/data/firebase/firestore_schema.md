# PrestOra : structure Firestore (v3, années académiques, sans Cloud Functions)

Convention : `snake_case`. Identifiants déterministes quand c'est utile (réexécution sans doublon).

## Permanent

| Collection | Identifiant | Champs |
|---|---|---|
| `utilisateurs` | uid Firebase Auth | nom, titre, email, telephone, type_utilisateur (ADMIN, ENCADREUR, CHEF_PROMOTION, ENSEIGNANT, SECRETAIRE, DOYEN, VRA, RECTEUR, AG, COMPTABILITE), est_actif, faculte_id?, promotion_id?, grade_statutaire?, institution_origine?, peut_gerer_annees |
| `utilisateurs/{uid}/paiement/infos` | | mode (Banque / Mobile Money), coordonnees |
| `facultes` | auto ou slug | nom_faculte |
| `departements` | auto | faculte_id, nom |
| `promotions` | auto | faculte_id, departement_id, nom |
| `cours` (catalogue) | slug du code | code_cours, intitule_exact, credits, volume_horaire_max, faculte_id, faculte_nom, promotion_id, promotion_nom, est_archive |
| `baremes` | nom du grade | grade_statutaire, taux, date_effet, historique[{date, texte}] |
| `parametres/retenue_fiscale` | | pourcentage, date_effet |
| `parametres/annee_active` | | annee_id (null si aucune) : pointeur qui garantit UNE seule année active |

`faculte_nom` / `promotion_nom` sont dupliqués dans `cours` et `offres_cours` pour l'affichage sans jointure.

## Par année académique

| Collection | Identifiant | Champs |
|---|---|---|
| `annees_academiques` | libellé (« 2027-2028 ») | libelle, date_debut, date_fin, statut (PLANIFIEE → ACTIVE → CLOTUREE), date_activation?, date_cloture? |
| `offres_cours` | `{annee}_{cours_id}` | annee_id, cours_id, code, intitule, credits, volume (modifiable pour l'année), faculte_id, faculte_nom, promotion_id, promotion_nom |
| `affectations_promotion` | `{annee}_{promotion_id}` | annee_id, promotion_id, chef_promo_id, encadreur_ids, doyen_id? |
| `sessions_suivi` | `{annee}_{cours_id}` (une session par cours et par année) | annee_id, cours_id, code, intitule, credits, volume, faculte_id, promotion_id, promotion_nom, encadreur_id, enseignant_id, enseignant_nom, grade, chef_promo_id, est_cloturee, statut_session (EN_COURS / CLOTURE) |
| `sessions_suivi/{id}/seances` | auto | date, debut (minutes depuis minuit), fin, nbre_heures, type_seance (CM/TD/TP), chapitre, valide_par_prof, encode_par_id, preuve_nom |
| `dossiers_paie` (lot 3) | auto | annee_id, reference, enseignant_id, faculte_id, heures, taux, brut, retenues, net, palier_courant (1..7), palier_rejet?, motif_rejet?, dates{}, mode, coordonnees, pieces[], reference_paiement?, mode_reglement?, bordereau?, imputation? |
| `validations` (lot 3) | auto | dossier_id, annee_id, autorite_id, etape_workflow, statut_action, motif?, horodatage |
| `notifications` (lot 4) | auto | destinataire_id, expediteur_id, type, titre, message, cible, lu, date |

## Règles de gestion des années

- Une seule année ACTIVE : `activer` s'exécute dans une transaction qui lit puis écrit `parametres/annee_active`; les règles vérifient la cohérence avec `getAfter`.
- Les offres de cours se préparent pendant PLANIFIEE et restent modifiables en ACTIVE. En CLOTUREE tout est figé.
- Séances, sessions et dossiers de paie n'existent que dans une année ACTIVE.
- Comptes, facultés, promotions, catalogue de cours et barèmes ne dépendent d'aucune année.

## Index composites probables (Firestore proposera le lien en cas d'erreur)

- `sessions_suivi` : annee_id + enseignant_id ; annee_id + faculte_id + est_cloturee
- `dossiers_paie` : annee_id + palier_courant + faculte_id ; annee_id + enseignant_id

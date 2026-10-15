# 🎓 PrestOra

> **Système Cloud-Native de Gestion des Prestations Pédagogiques et Moteur de Paie à 6 Niveaux pour l'Université Catholique de Bukavu (UCB)**

![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter)
![Dart](https://img.shields.io/badge/Dart-3.x-0175C2?logo=dart)
![Firebase](https://img.shields.io/badge/Firebase-Serverless-FFCA28?logo=firebase)
![Architecture](https://img.shields.io/badge/Architecture-Clean_Architecture_%2B_BLoC-green)
![License](https://img.shields.io/badge/License-MIT-blue)

---

## À propos du projet

**PrestOra** est une plateforme web et mobile développée pour moderniser et automatiser le processus de suivi des prestations d'enseignement et le circuit de paie des enseignants visiteurs à l'**Université Catholique de Bukavu (UCB)**.

Le système remplace l'ancien workflow manuel sur papier par une solution automatisée, transparente et sécurisée basée sur un contrôle d'accès basé sur les rôles (**RBAC**) et un découpage strict par faculté.

---

## Fonctionnalités Clés

### Module A : Suivi Pédagogique des Prestations

- **Création des cours & sessions :** Enregistrement des sessions de cours par l'Encadreur Pédagogique de la faculté.
- **Émargement numérique :** Encodage des heures et descriptions de séances par le Chef de promotion après chaque cours.
- **Validation unitaire :** Validation explicite par l'Enseignant Visiteur (ou refus passif).
- **Validation de fin de cours :** Clôture globale par l'Encadreur Pédagogique (bloquée si une seule séance demeure non validée).
- **Génération automatique de Fiche de Prestation :** Transmission instantanée au Secrétariat Facultaire.

### Module B : Circuit Administratif & Financier de Paie (6 Niveaux)

- **Calculateur automatique de paie :** Application du barème institutionnel selon le grade statutaire avec **majoration automatique de +10%** sur les heures prestées.
- **Circuit d'approbation hiérarchique à 6 niveaux :**
  1. **Chef de Promotion & Enseignant** (Émargement & accord)
  2. **Encadreur Pédagogique** (Validation de fin de cours)
  3. **Secrétaire Facultaire** (Initiation du dossier de paie)
  4. **Doyen de la Faculté** (Visa facultaire)
  5. **Vice-Recteur aux Affaires Académiques (VRA) & Recteur** (Validations académiques)
  6. **Administrateur Général (AG) & Comptabilité** (Liquidation & Bordereau de virement)
- **Périmètre cloisonné par Faculté :** Isolation stricte des données pour les Doyens, Secrétaires et Encadreurs.

---

## Architecture du Système

### Stack Technique Cloud-Native

- **Frontend Multiplateforme :** [Flutter](https://flutter.dev) (Application Mobile Android pour le terrain & Web Desktop pour les décanats)
- **Backend Serverless :** [Google Firebase](https://firebase.google.com)
  - **Firebase Authentication :** Gestion des identités et Custom Claims (RBAC).
  - **Cloud Firestore :** Base de données NoSQL réactive synchronisée en temps réel via WebSockets/gRPC.
  - **Firebase Cloud Storage :** Hébergement des pièces justificatives et bordereaux.
  - **Cloud Functions :** Microservices backend pour les calculs financiers complexes et notifications ciblées (FCM).

### Architecture Logicielle Interne

Le code source suit la **Clean Architecture** couplée au pattern de gestion d'état **BLoC (Business Logic Component)** :

```text
┌─────────────────────────────────────────────────────────┐
│                   COUCHE PRÉSENTATION                   │
│   ┌─────────────────────┐     ┌─────────────────────┐   │
│   │   Widgets Flutter   │────>│   Composants BLoC   │   │
│   │ (UI / Tableaux Bord)│<────│ (Événements / États)│   │
│   └─────────────────────┘     └──────────┬──────────┘   │
└──────────────────────────────────────────┼──────────────┘
                                           │ (Appelle Cas d'Utilisation)
┌──────────────────────────────────────────▼──────────────┐
│                     COUCHE DOMAINE                      │
│   ┌─────────────────────┐     ┌─────────────────────┐   │
│   │       Entités       │     │  Cas d'Utilisation  │   │
│   │   (Modèles Métier)  │     │(Calculs/Validations)│   │
│   └─────────────────────┘     └──────────┬──────────┘   │
└──────────────────────────────────────────┼──────────────┘
                                           │ (Interfaces Repository)
┌──────────────────────────────────────────▼──────────────┐
│                     COUCHE DONNÉES                      │
│   ┌─────────────────────┐     ┌─────────────────────┐   │
│   │    Repositories     │────>│  Sources de Données │   │
│   │   Implémentations   │     │ (Firestore / Local) │   │
│   └─────────────────────┘     └─────────────────────┘   │
└─────────────────────────────────────────────────────────┘
```

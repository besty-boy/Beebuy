# Audit et corrections — 2 septembre 2026

## Périmètre et méthode

Inspection de l’ensemble des sources Swift, du projet Xcode, des assets, des paramètres de signature et des deux commits présents. Le code source original et son historique n’ont pas été modifiés. Les corrections sont dans une copie autonome.

Le projet source compilait déjà pour iOS Simulator avec Xcode 26.6. Les défauts principaux étaient des incohérences métier, des risques de notification, des erreurs non gérées et des problèmes d’ergonomie, pas une absence générale de compilation.

## Constats et traitement

| Priorité | Constat initial | Correction |
| --- | --- | --- |
| Haute | Récurrence mensuelle calculée en ajoutant un mois à la précédente date, avec dérive après février ; calendrier ignorant les mois courts | Calcul toujours ancré sur la date initiale et tests des 28–31 et du 29 février |
| Haute | Comparaison de dates avec heures masquant un prélèvement du jour dans le calendrier | Normalisation au début du jour et prochaine échéance inclusive |
| Haute | Paiements uniques anciens susceptibles de recevoir des notifications récurrentes | Planificateur commun avec arrêt après une seule occurrence |
| Haute | Six rappels par abonnement sans budget global | 60 rappels maximum, tri chronologique global et mémoire bornée |
| Haute | Drapeau persistant empêchant tout renouvellement des rappels après la première exécution | Suppression de ce mécanisme ; actualisation à l’ouverture et après sauvegarde |
| Haute | Sauvegarde et suppression sans traitement explicite d’échec | Save/rollback, message d’erreur, programmation après validation de l’écriture |
| Haute | Échec du conteneur provoquant fatalError | Écran d’indisponibilité sans effacement ni remplacement de base |
| Haute | Total du mois mélangeant moyenne mensualisée et paiements uniques | Total fondé sur les échéances du mois ; moyenne Siri clairement distincte |
| Moyenne | Siri acceptant des montants négatifs/non finis et sélectionnant des paiements uniques passés | Validation partagée, exclusion des échéances passées, authentification requise |
| Moyenne | Aucune modification possible, suppression immédiate | Éditeur sur brouillon local, annulation, confirmation de suppression |
| Moyenne | Nom constitué d’espaces, formats de montants partiellement interprétés, date de fin incohérente | Nom nettoyé et borné, parsing complet, validation du montant et de la validité |
| Moyenne | Calendrier uniquement navigable par glissement et jours « M » avec identifiants dupliqués | Boutons, identifiants uniques, premier jour de semaine du calendrier local |
| Moyenne | Calendrier recalculant son dictionnaire à chaque cellule | Regroupement des échéances une fois par rendu |
| Moyenne | Couleur prétendument stable fondée sur hashValue aléatoire ; risque abs(Int.min) | Index déterministe borné, parsing hex strict, couleurs noir/blanc adaptatives |
| Moyenne | Liste écrasée sous une carte fixe avec grandes tailles de texte | Liste défilante unique, lignes qui s’empilent aux tailles d’accessibilité |
| Moyenne | Lancement retardé artificiellement et onboarding peu adaptable | Suppression du splash temporisé, onboarding défilant et polices sémantiques |
| Moyenne | Prix de services figés et catalogue dupliqué | Catalogue unique recherchable, prix saisi par l’utilisateur |
| Moyenne | URL d’icône externe déclenchant un accès réseau dans la liste | Pas de chargement réseau, champs conservés et repli sur icône système |
| Moyenne | Logos externes sans justificatifs de licence | Retirés de la copie distribuable et remplacés par des SF Symbols ; originaux conservés |
| Moyenne | Configuration annonçant macOS/visionOS alors que les écrans utilisent UIKit | Cibles limitées à iPhone/iPad, minimum iOS 26 inchangé |
| Basse | Identifiant d’équipe personnel, données Xcode utilisateur, absence de README et d’ignore | Équipe vidée, copie sans xcuserdata/.git, README, .gitignore, schéma partagé, workflow CI |
| Basse | Fichier IDEA embarqué, slots d’icônes Mac vides, noms d’images vagues | Suppression de la note dans la copie, slots inutiles retirés et images AppIcon renommées |
| Basse | Logs avec noms et montants d’abonnements | Logs de données personnelles retirés ; erreurs de rappels visibles dans l’interface |

## Tests exécutés

Environnement : Mac arm64, Xcode 26.6 (17F113), SDK iOS/iOS Simulator 26.5, Swift 6.3.2.

- **19 tests automatisés réussis, 0 échec** : 13 échéances, 4 validation, 2 planificateur global.
- Tests couvrant fins de mois, années bissextiles, date du jour, départ futur, ancien abonnement, intervalles semi-ouverts, cinq prélèvements hebdomadaires, changement d’heure Europe/Paris, rappel de demain avant/après 10 h, paiement unique, 100 abonnements et ordre d’insertion.
- Vérification croisée de la prochaine échéance avec le calendrier sur 36 mois, trois fréquences et cinq jours d’ancrage.
- Compilation Debug iOS Simulator réussie pour arm64 et x86_64.
- Compilation Release iPhone sans signature réussie.
- Validation structurelle du projet et du manifeste de confidentialité avec plutil.
- Recherche statique par motifs de secrets dans la copie et dans les modifications des deux commits : aucun secret évident détecté. Ceci n’est pas une garantie exhaustive.
- Vérification que les sources et le projet Xcode originaux ne présentent aucun diff suivi après intervention.

## Vérifications visuelles effectuées

La compétence de contrôle d’interface a permis d’examiner le lancement et les écrans sur un simulateur iPhone 17 dédié sous iOS 26.5 :

- Affichage et sortie de l’onboarding.
- État vide, calendrier français et descriptions d’accessibilité des jours.
- Catalogue de services et formulaire personnalisé.
- Saisie d’un abonnement fictif « Abonnement Test » à 12,99 €.
- Enregistrement et affichage cohérent du total mensuel, du jour concerné et de la ligne.
- Ouverture de l’éditeur avec les valeurs enregistrées.

Cette vérification a notamment conduit à raccourcir les titres du formulaire pour éviter leur troncature. Il ne s’agit pas d’une suite XCUITest et l’audit ne prétend pas avoir validé tous les parcours.

## Limites et recette avant diffusion

À valider sur appareil réel ou simulateurs supplémentaires :

- Modification puis **Annuler** : données inchangées ; modification puis **Enregistrer** : montant et calendrier actualisés.
- Suppression confirmée/annulée, suppression de plusieurs lignes et erreur de stockage.
- Fermeture complète et relance, mise à jour depuis une installation de l’ancienne app avec données réelles sauvegardées.
- Paiement unique passé et futur, fréquence annuelle, départ le 31, navigation autour du changement d’année.
- Autorisation de notifications acceptée/refusée, retour depuis Réglages, livraison réelle à 10 h, modification/suppression et changements de fuseau.
- VoiceOver complet, tailles Dynamic Type maximales, Réduire les animations, contraste accru, mode sombre, petit écran, paysage et iPad.
- Exécution vocale des trois raccourcis Siri, appareil verrouillé/déverrouillé et erreurs de paramètres.
- Profilage Instruments avec un grand jeu de données. Les gains de complexité sont établis par lecture du code, pas par un benchmark de consommation/mémoire.
- Premier workflow GitHub distant : configuré mais non exécuté ici.

Aucune base de données réelle d’utilisateur n’était fournie. Les champs persistants et le Bundle ID sont conservés, mais une migration de production n’a donc pas pu être certifiée.

## Points restant au propriétaire

- Choisir une licence. L’audit initial n’a créé aucun dépôt distant, compte ou certificat ; la publication et l’anonymisation de l’historique font l’objet d’une demande ultérieure explicite du propriétaire.
- Confirmer les droits sur l’icône d’application. Les trois PNG font 1024 × 1024 et comportent un canal alpha : contrôler et préparer l’icône de distribution avant App Store. Les pixels de ces images n’ont pas été modifiés.
- Configurer la signature pour une installation physique ; vérifier métadonnées, confidentialité et exigences App Store au moment d’une éventuelle soumission.
- Le minimum iOS 26, la devise EUR et l’absence d’export/restauration restent des limites produit assumées. La résiliation d’un abonnement récurrent avec historique n’a pas été inventée.

## Complément : préparation de l’historique public

À la demande du propriétaire, la version corrigée repart d’un commit initial avec un nom de contribution générique et une adresse technique non distribuable. L’ancien historique est conservé dans une sauvegarde locale séparée, jamais incluse dans les fichiers publiés.

Les sources, noms de fichiers, documentation et métadonnées PNG ont été contrôlés pour les identifiants personnels connus. Les données Xcode utilisateur ne sont pas incluses. Cette mesure n’anonymise pas le compte propriétaire de GitHub et ne supprime pas les anciennes copies externes ou vues en cache.

## Références techniques consultées

- [SwiftData : rollback](https://developer.apple.com/documentation/swiftdata/modelcontext/rollback%28%29) — retour au dernier état sauvegardé après erreur.
- [Apple : raisons d’accès aux API de confidentialité](https://developer.apple.com/documentation/bundleresources/app-privacy-configuration/nsprivacyaccessedapitypes/nsprivacyaccessedapitypereasons) — motif CA92.1 pour les préférences propres à l’app.
- [Apple : notifications locales historiques](https://developer.apple.com/documentation/uikit/uilocalnotification) — limite documentée de 64 dans l’ancienne API ; le budget de 60 est un choix conservateur, pas une promesse de livraison du système moderne.
- [GitHub : environnements hébergés](https://docs.github.com/en/actions/reference/runners/github-hosted-runners) — environnement macos-26 utilisé par le workflow.

# Buybee

Gestionnaire personnel d’abonnements pour iPhone et iPad, en SwiftUI et SwiftData. Interface française, montants en euros, sans compte, serveur Buybee ni dépendance tierce.

## Démarrer

1. Ouvrir **Buybee.xcodeproj** dans Xcode 26 ou ultérieur (version vérifiée : Xcode 26.6).
2. Choisir le schéma partagé **Buybee**, puis un simulateur iPhone/iPad sous iOS 26 ou ultérieur.
3. Lancer l’app. Aucune clé API ni configuration réseau n’est nécessaire.
4. Sur appareil physique, sélectionner votre équipe dans **Signing & Capabilities**. L’équipe personnelle du projet source a été retirée.

Le Bundle ID existant est conservé pour ne pas changer l’identité des installations : **Nex-Dev.Buybee**. Pour un fork indépendant, remplacez-le par votre propre identifiant. Ne le changez pas si vous voulez tester une mise à jour conservant les données d’une installation existante.

Le minimum iOS 26 du projet d’origine est conservé. Les cibles macOS/visionOS ont été retirées : l’interface était iOS et utilisait des API UIKit non portables.

## Fonctionnalités

- Ajout depuis un catalogue recherchable ou création personnalisée, puis modification et suppression avec confirmation.
- Montants décimaux saisis avec virgule ou point ; prix du catalogue volontairement non préremplis.
- Fréquences hebdomadaire, mensuelle, annuelle et paiement unique.
- Total des prélèvements prévus dans le mois choisi ; navigation explicite dans le calendrier et détail par jour.
- Rappels locaux facultatifs, configurables depuis le bouton en forme de cloche.
- Raccourcis Siri : ajout, coût mensuel moyen, prochain prélèvement. L’appareil doit être authentifié.
- Couleurs adaptatives, tailles de texte système, descriptions d’accessibilité et prise en compte de Réduire les animations.

Buybee ne déclenche aucun prélèvement, ne résilie aucun contrat et ne confirme pas qu’un paiement bancaire a réellement eu lieu.

## Règles de calcul

Les dates sont des jours calendaires dans le fuseau local. Un paiement prévu aujourd’hui reste affiché aujourd’hui : l’app n’a pas de statut bancaire « payé ».

- Un départ le 31 janvier donne le 28/29 février, puis le 31 mars, sans dérive au 28 mars.
- Un anniversaire annuel le 29 février passe au 28 février les années non bissextiles et revient au 29 les années bissextiles.
- Un abonnement hebdomadaire peut générer quatre **ou cinq** prélèvements dans un mois.
- Les intervalles sont [début du mois, début du mois suivant), sans double compte à la frontière.
- Un paiement unique n’est compté qu’à sa date de paiement. Sa fin de validité ne produit ni renouvellement ni second prélèvement.
- Le **total du calendrier** est le montant réellement prévu selon les échéances enregistrées.
- Le **coût mensuel moyen Siri** est une estimation distincte : annuel / 12, hebdomadaire × 52 / 12, hors paiements uniques et abonnements pas encore commencés.

## Rappels et confidentialité

L’autorisation n’est demandée qu’après une action explicite. Le planificateur conserve les **60 prochains rappels**, globalement triés par date. Ils sont prévus à 10 h la veille du paiement et recalculés à l’ouverture, au retour au premier plan, après une modification et lors d’un changement significatif d’heure.

Cette couverture est finie. Si vous n’ouvrez pas Buybee pendant longtemps, les rappels préparés finissent par s’épuiser. Le système peut aussi différer leur présentation selon les réglages de concentration et de notifications. Aucun service de fond permanent n’est promis.

Le nom et le montant peuvent être affichés dans les notifications. Réglez les aperçus de l’écran verrouillé dans iOS selon votre préférence. Les données utilisent le stockage local SwiftData et les mécanismes de sauvegarde du système ; aucune synchronisation iCloud applicative n’est configurée. L’utilisation de Siri dépend des réglages et services Apple.

Les anciennes URL d’icônes sont conservées dans le modèle pour compatibilité, mais ne sont plus téléchargées. Aucun suivi analytique n’est intégré. Le manifeste de confidentialité déclare l’utilisation des préférences propres à l’app pour l’onboarding.

## Architecture

- **Buybee/App** : parcours de lancement et onboarding, sans attente artificielle.
- **Buybee/Core** : calcul d’échéances, validation et planification pure des rappels, testables indépendamment.
- **Buybee/Models** : modèle SwiftData compatible avec les propriétés d’origine, conteneur et catalogue.
- **Buybee/Managers** : coordination des notifications iOS.
- **Buybee/Views** : formulaires, calendrier, liste, onboarding et réglages des rappels.
- **Buybee/Intents** : intégration Siri/Raccourcis.
- **Tests/BuybeeCoreTests** : tests Foundation via Swift Package Manager.

Les formulaires conservent un brouillon local. La sauvegarde est explicite ; en cas d’échec, rollback et message utilisateur. Les rappels sont actualisés uniquement après la sauvegarde. Un échec d’ouverture du stockage affiche une erreur, sans effacer la base ni créer un faux stockage vide.

Pour conserver les données existantes, le champ historique **endDate** garde son sens : non nul = paiement unique à **startDate**. Il ne signifie pas la résiliation d’un abonnement récurrent. Les propriétés persistantes, UUID et valeurs brutes de fréquence sont conservés. Avant une prochaine évolution du schéma, ajouter un schéma versionné et des tests de migration sur sauvegarde réelle.

## Vérifier

Depuis le dossier contenant ce README :

~~~sh
swift test
xcodebuild -project Buybee.xcodeproj -scheme Buybee \
  -destination 'generic/platform=iOS Simulator' \
  -derivedDataPath build/DerivedData CODE_SIGNING_ALLOWED=NO build
xcodebuild -project Buybee.xcodeproj -scheme Buybee \
  -configuration Release -destination 'generic/platform=iOS' \
  -derivedDataPath build/ReleaseData CODE_SIGNING_ALLOWED=NO build
~~~

Si les outils en ligne de commande sélectionnent seulement CommandLineTools, utiliser temporairement **DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer** devant ces commandes, sans modifier la configuration globale du Mac.

Le package teste uniquement les règles métier ; **swift test ne teste pas SwiftUI, SwiftData ou Siri**. Le schéma Xcode partagé sert à compiler et exécuter l’app, pas à lancer ces tests de package. Le workflow GitHub Actions exécute les tests et la compilation simulateur. Il n’a pas été lancé sur GitHub pendant cet audit.

Voir [AUDIT.md](AUDIT.md) pour les résultats, les limites et la recette manuelle.

## Publication GitHub

Cette copie est autonome et ne contient ni profils de signature, ni données de simulateur. Son historique public repart d’un commit initial propre avec une identité de contribution générique, sans reprendre l’historique personnel du projet source. **Publier le contenu de ce dossier uniquement, pas le dossier parent contenant l’original et les fichiers de travail.**

Après cette remise à zéro, repartir d’un clone neuf pour contribuer. Ne pas fusionner l’ancien historique : cela réintroduirait les anciennes données personnelles. Le compte propriétaire du dépôt reste visible sur GitHub. Les caches, forks et clones déjà existants ne sont pas effacés par une réécriture d’historique.

Avant le premier envoi :

- Choisir la visibilité du dépôt et une licence adaptée au projet. Aucune licence de redistribution n’a été inventée ou appliquée automatiquement.
- Confirmer les droits sur les trois images de l’icône d’application conservées.
- Vérifier les fichiers sélectionnés par Git ; ne jamais ajouter une base locale, un certificat ou des secrets.
- Exécuter les tests et examiner le résultat du premier workflow distant.

Les logos de services externes sans licence documentée ont été remplacés par des SF Symbols. Les noms de services servent uniquement à identifier les entrées ; aucune affiliation n’est revendiquée. Les fichiers graphiques d’origine restent dans le projet source et dans les fichiers de travail de l’audit, hors de cette copie.

Le projet est préparé pour GitHub, **pas certifié pour une soumission App Store** : signature, validation sur appareils, métadonnées et icône de distribution restent à vérifier.

# BankV2 - Système Bancaire Avancé

Système bancaire complet pour FiveM avec gestion de comptes personnels et professionnels.

## Fonctionnalités

### Comptes Bancaires
- **Compte Personnel** : Compte bancaire individuel pour chaque joueur
- **Compte Entreprise** : Compte bancaire pour les entreprises (accessible aux patrons)
- IBAN unique pour chaque compte
- Suivi du solde en temps réel

### Cartes Bancaires
- Création de cartes bancaires avec code PIN
- Numéro de carte unique, date d'expiration et CVV
- Possibilité de bloquer/débloquer les cartes
- Props de carte bancaire (commande `/card` ou `/carte`)
- Coût : 150€ par carte

### Opérations Bancaires
- **Déposer** : Déposer de l'argent liquide sur le compte
- **Retirer** : Retirer de l'argent du compte (nécessite le code PIN)
- **Virements** : Effectuer des virements vers d'autres joueurs via IBAN
- Historique complet des transactions
- Limite de retrait : 5 000€ par transaction
- Limite de dépôt : 50 000€ par transaction

### Système de Salaires (Entreprise)
- Visualisation en temps réel des employés en ligne
- Affichage des grades, IBAN, nom et prénom
- Paiement individuel des salaires
- Paiement groupé de tous les salaires
- Historique des paiements de salaires

### ATM
- Accès au compte personnel uniquement
- Interaction automatique à proximité des distributeurs
- Blips sur la carte pour localiser les ATM
- Support des props ATM automatique

### Interface
- Interface moderne et responsive
- 4 onglets principaux :
  - **Accueil** : Vue d'ensemble avec solde et actions rapides
  - **Cartes Bancaires** : Gestion des cartes
  - **Transactions** : Historique complet
  - **Votre Compte** : Informations du compte
- Onglet supplémentaire pour les comptes entreprise :
  - **Salaires** : Gestion des employés et paiements

## Installation

### 1. Base de données

Exécutez le fichier `bankv2.sql` dans votre base de données MySQL :

```sql
-- Importez le fichier bankv2.sql
```

### 2. Ressource FiveM

1. Placez le dossier `bankv2` dans votre répertoire `resources`
2. Ajoutez la ligne suivante dans votre `server.cfg` :

```cfg
ensure bankv2
```

### 3. Dépendances

Ce script nécessite :
- **ESX Framework** (ESX Legacy recommandé)
- **oxmysql** (pour les requêtes MySQL)

### 4. Configuration

Éditez le fichier `config.lua` pour personnaliser :
- Les limites de retrait/dépôt
- Les positions des ATM
- Les modèles de props
- Les salaires par grade et job
- La devise

## Utilisation

### Commandes

- `/bank` - Ouvrir le compte personnel
- `/bankpro` - Ouvrir le compte entreprise
- `/card` ou `/carte` - Sortir/ranger la carte bancaire

### Interactions

- Approchez-vous d'un ATM et appuyez sur **E** pour accéder au compte personnel

### Création de compte

Les comptes personnels sont créés automatiquement lors de la première connexion du joueur.

Les comptes entreprise doivent être créés manuellement dans la base de données :

```sql
INSERT INTO bank_accounts_business (society, society_label, iban, balance)
VALUES ('society_police', 'Police de Los Santos', 'FR76XXXXXXXXXXXX', 10000.00);
```

### Gestion des salaires

1. Seuls les patrons peuvent accéder à l'onglet Salaires
2. Les employés doivent être en ligne pour apparaître dans la liste
3. Configurez les salaires dans `config.lua` :

```lua
Config.JobGrades = {
    ['police'] = {
        [0] = {label = 'Recrue', salary = 1500},
        [1] = {label = 'Officier', salary = 2000},
        -- ...
    }
}
```

## Structure des fichiers

```
bankv2/
├── fxmanifest.lua          # Manifest de la ressource
├── config.lua              # Configuration
├── bankv2.sql              # Structure de la base de données
├── server/
│   ├── main.lua            # Logique serveur principale
│   └── salary.lua          # Système de salaires
├── client/
│   └── main.lua            # Logique client
└── html/
    ├── index.html          # Interface utilisateur
    ├── style.css           # Styles
    └── script.js           # Logique JavaScript
```

## Configuration avancée

### Personnalisation des props de carte

Dans `config.lua`, modifiez :

```lua
Config.CardProps = {
    model = 'prop_ld_case_01',  -- Modèle du prop
    bone = 28422,                -- Os de la main
    offset = {
        pos = vector3(0.08, 0.03, 0.0),
        rot = vector3(-90.0, 0.0, 0.0)
    }
}
```

### Ajout de positions ATM

Ajoutez des coordonnées dans `Config.ATMLocations` :

```lua
Config.ATMLocations = {
    vector3(147.4, -1035.8, 29.3),
    vector3(-350.8, -49.5, 49.0),
    -- Ajoutez vos positions ici
}
```

### Personnalisation des frais

Dans `config.lua` :

```lua
Config.TransferFee = 0          -- Frais de virement (0 = gratuit)
Config.CardPrice = 150          -- Prix d'une carte
```

## Support

Pour toute question ou problème :
1. Vérifiez que toutes les dépendances sont installées
2. Vérifiez les logs F8 pour les erreurs
3. Assurez-vous que la base de données est correctement importée

## Crédits

Développé pour FiveM avec ESX Framework.

## License

Libre d'utilisation et de modification.

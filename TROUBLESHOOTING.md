# Guide de Dépannage BankV2

## ⚠️ Problèmes Courants et Solutions

### 1. Conflit avec ox_banking

**Symptôme** : Erreurs `ox_banking` dans les logs, impossible d'ouvrir la banque

**Solution** : Vous avez deux scripts de banque qui entrent en conflit. Vous devez choisir :

**Option A - Garder BankV2 (recommandé si vous suivez ce guide)**
```cfg
# Dans server.cfg, commentez ou supprimez :
# ensure ox_banking

# Et ajoutez :
ensure bankv2
```

**Option B - Garder ox_banking**
```cfg
# Dans server.cfg, commentez ou supprimez :
# ensure bankv2

# Et gardez :
ensure ox_banking
```

### 2. Compte non trouvé / Informations vides

**Symptôme** : Les informations du compte affichent "--" partout

**Solutions** :

#### A. Vérifier que la base de données est importée
1. Ouvrez phpMyAdmin ou votre gestionnaire MySQL
2. Vérifiez que les tables existent :
   - `bank_accounts_personal`
   - `bank_accounts_business`
   - `bank_cards`
   - `bank_transactions`
   - `bank_employees`
   - `bank_salary_payments`

3. Si les tables n'existent pas, importez `bankv2.sql` :
   ```sql
   SOURCE /chemin/vers/bankv2.sql
   ```

#### B. Créer le compte manuellement
```sql
-- Remplacez VOTRE_IDENTIFIER par votre identifier ESX (ex: steam:110000...)
INSERT INTO bank_accounts_personal (identifier, firstname, lastname, iban, balance)
VALUES ('VOTRE_IDENTIFIER', 'Votre', 'Nom', 'FR76123456789012345678901234', 5000.00);
```

#### C. Redémarrer la ressource
```
restart bankv2
```

#### D. Se reconnecter au serveur
Le compte devrait se créer automatiquement à la connexion

### 3. La touche E ne fonctionne pas aux ATM

**Solutions** :

#### A. Vérifier que vous êtes assez proche
- Distance requise : **2.5 mètres**
- Le message "Appuyez sur E" doit s'afficher

#### B. Vérifier les logs F8
```
[BankV2] Joueur proche d'un ATM
```
Si vous voyez ce message, l'ATM est détecté.

#### C. Ouvrir avec la commande
```
/bank
```
Si la commande fonctionne, le problème vient de la détection ATM.

#### D. Activer les logs de débogage
Les logs apparaissent maintenant automatiquement dans F8. Vérifiez :
- `[BankV2] Joueur proche d'un ATM` quand vous approchez
- `[BankV2] Ouverture ATM...` quand vous appuyez sur E

### 4. Impossible d'écrire dans les champs

**Symptôme** : Les inputs ne répondent pas

**Solution** : C'est maintenant corrigé. Si le problème persiste :

1. Fermez complètement la banque (ESC)
2. Réouvrez-la (`/bank`)
3. Vérifiez que vous pouvez déplacer votre souris

Si ça ne fonctionne toujours pas :
```
restart bankv2
```

### 5. Erreur "Erreur: compte introuvable" lors de la création de carte

**Cause** : Le compte n'existe pas dans la base de données

**Solutions** :

1. **Ouvrez la banque et attendez** : Le compte devrait se créer automatiquement
2. **Vérifiez les logs** (F8) :
   ```
   [BankV2] ✓ Compte créé automatiquement
   ```
3. **Redémarrez la ressource** si le compte ne se crée pas :
   ```
   restart bankv2
   ```

### 6. Les opérations (déposer/retirer/virer) ne fonctionnent pas

**Symptôme** : Rien ne se passe quand vous confirmez

**Solutions** :

#### A. Vérifier que le compte existe
```sql
SELECT * FROM bank_accounts_personal WHERE identifier = 'VOTRE_IDENTIFIER';
```

#### B. Vérifier les logs serveur
Recherchez dans les logs :
```
[BankV2] Compte trouvé pour ...
[BankV2] Dépôt effectué
```

#### C. Vérifier oxmysql
```cfg
# Dans server.cfg
ensure oxmysql
```

### 7. Erreur ESX "getSharedObject Event no longer exists"

**Symptôme** : Le script ne démarre pas

**Cause** : Vous utilisez ESX Legacy

**Solution** : **C'EST DÉJÀ CORRIGÉ** dans la dernière version !

Si vous voyez encore cette erreur :
1. Vérifiez que vous avez bien pull la dernière version du GitHub
2. Redémarrez le serveur complètement
3. Le script utilise maintenant :
   ```lua
   ESX = exports['es_extended']:getSharedObject()
   ```

## 🔍 Commandes de débogage

### Vérifier le compte en jeu
```
/bank
```
Les logs dans F8 vous diront si le compte existe.

### Forcer la création du compte
Reconnectez-vous au serveur. Le compte se crée automatiquement à la connexion.

### Vérifier la base de données
```sql
-- Comptes personnels
SELECT * FROM bank_accounts_personal;

-- Comptes entreprises
SELECT * FROM bank_accounts_business;

-- Cartes
SELECT * FROM bank_cards;

-- Transactions
SELECT * FROM bank_transactions LIMIT 10;
```

## 📝 Logs importants

### Logs de démarrage attendus
```
[BankV2] Ressource démarrée
```

### Logs de connexion
```
[BankV2] Création de compte pour steam:110000...
[BankV2] ✓ Compte personnel créé pour NomPrenom - IBAN: FR76...
```

### Logs d'ouverture
```
[BankV2] Compte trouvé pour steam:110000... - Balance: 5000.00
```

### Logs ATM
```
[BankV2] Joueur proche d'un ATM
[BankV2] Ouverture ATM...
```

## ⚙️ Configuration serveur recommandée

### server.cfg
```cfg
# Base de données
ensure oxmysql

# Framework
ensure es_extended

# BankV2 - Après ESX !
ensure bankv2

# NE PAS activer ox_banking en même temps
# ensure ox_banking
```

### Ordre de démarrage
1. oxmysql
2. es_extended (ESX)
3. bankv2

## 🆘 Aide supplémentaire

Si aucune de ces solutions ne fonctionne :

1. **Vérifiez les logs F8** et cherchez `[BankV2]`
2. **Vérifiez les logs serveur** dans la console
3. **Testez avec la commande** `/bank` au lieu des ATM
4. **Vérifiez que la base de données** est bien importée
5. **Redémarrez complètement le serveur**

### Checklist de vérification
- [ ] Tables SQL créées
- [ ] ox_banking désactivé
- [ ] ESX Legacy installé
- [ ] oxmysql installé
- [ ] Ressource démarrée après ESX
- [ ] Compte créé (visible dans les logs)
- [ ] Pas d'erreurs dans F8

## 📞 Informations de version

**Version actuelle** : 2.0.0
**Compatibilité** : ESX Legacy
**Base de données** : MySQL (oxmysql)

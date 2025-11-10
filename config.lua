Config = {}

-- Configuration générale
Config.Currency = "€"
Config.MaxTransactionHistory = 50

-- Configuration des comptes
Config.DefaultPersonalBalance = 5000 -- Solde par défaut compte personnel
Config.DefaultBusinessBalance = 10000 -- Solde par défaut compte entreprise

-- Configuration des cartes bancaires
Config.CardPrice = 150 -- Prix d'une nouvelle carte
Config.PINLength = 4 -- Longueur du code PIN

-- Configuration des ATM
Config.WithdrawLimit = 5000 -- Limite de retrait par transaction
Config.DepositLimit = 50000 -- Limite de dépôt par transaction

-- Configuration des virements
Config.TransferFee = 0 -- Frais de virement (0 = gratuit)
Config.MinTransfer = 1 -- Montant minimum de virement

-- Props de carte bancaire
Config.CardProps = {
    model = 'prop_ld_case_01', -- Modèle du prop (à remplacer par votre modèle)
    bone = 28422, -- Os de la main
    offset = {
        pos = vector3(0.08, 0.03, 0.0),
        rot = vector3(-90.0, 0.0, 0.0)
    }
}

-- Positions des ATM (à personnaliser selon votre serveur)
Config.ATMLocations = {
    vector3(147.4, -1035.8, 29.3),
    vector3(-350.8, -49.5, 49.0),
    vector3(-1205.02, -325.28, 37.86),
    vector3(-2072.36, -317.29, 13.31),
    vector3(-526.57, -1222.90, 18.45),
    vector3(-254.41, -692.46, 33.60),
    vector3(155.77, 6642.85, 31.60),
    vector3(174.14, 6637.94, 31.57),
    vector3(1703.29, 6426.28, 32.76),
    vector3(1735.32, 6410.52, 35.03),
    vector3(1702.84, 4933.59, 42.06),
    vector3(1967.01, 3744.02, 32.34),
    vector3(1822.64, 3683.09, 34.27),
    vector3(540.27, 2671.14, 42.15),
    vector3(2558.70, 350.99, 108.62),
    vector3(2558.39, 389.47, 108.62),
    vector3(1077.75, -776.54, 58.24),
    vector3(1138.23, -468.94, 66.73),
    vector3(1153.68, -326.78, 69.20),
    vector3(381.20, 323.40, 103.56),
    vector3(236.45, 217.79, 106.28),
    vector3(265.05, 212.56, 106.28),
    vector3(285.44, 143.38, 104.17),
    vector3(157.92, 233.59, 106.63),
    vector3(-164.57, 233.67, 94.92),
    vector3(-1827.28, 784.89, 138.30),
    vector3(-1109.74, 2708.80, 18.99),
    vector3(-660.70, -854.45, 24.48),
    vector3(-594.61, -1160.85, 22.32),
    vector3(-1570.76, -546.67, 34.95),
    vector3(-1415.48, -211.97, 46.50),
    vector3(-1430.12, -211.05, 46.50),
    vector3(33.18, -1348.23, 29.49),
    vector3(129.46, -1292.58, 29.26),
    vector3(287.82, -1282.32, 29.64),
    vector3(289.10, -1256.82, 29.44),
    vector3(296.44, -894.30, 29.23),
    vector3(295.74, -896.09, 29.21),
    vector3(-302.41, -829.85, 32.41),
    vector3(-303.28, -829.74, 32.41),
    vector3(-206.06, -861.07, 30.26),
    vector3(112.57, -819.40, 31.33),
    vector3(111.32, -775.24, 31.43),
    vector3(114.39, -776.41, 31.41),
    vector3(-256.23, -715.99, 33.52),
    vector3(-258.87, -723.38, 33.48),
    vector3(-1091.50, 2708.66, 18.95)
}

-- Modèles des ATM
Config.ATMModels = {
    `prop_atm_01`,
    `prop_atm_02`,
    `prop_atm_03`,
    `prop_fleeca_atm`
}

-- Configuration des grades (pour le système de salaires)
Config.JobGrades = {
    -- Exemple de configuration, à adapter selon vos jobs
    ['police'] = {
        [0] = {label = 'Recrue', salary = 1500},
        [1] = {label = 'Officier', salary = 2000},
        [2] = {label = 'Sergent', salary = 2500},
        [3] = {label = 'Lieutenant', salary = 3000},
        [4] = {label = 'Capitaine', salary = 3500},
        [5] = {label = 'Commandant', salary = 4000},
    },
    ['ambulance'] = {
        [0] = {label = 'Stagiaire', salary = 1500},
        [1] = {label = 'Ambulancier', salary = 2000},
        [2] = {label = 'Infirmier', salary = 2500},
        [3] = {label = 'Médecin', salary = 3000},
        [4] = {label = 'Chirurgien', salary = 3500},
        [5] = {label = 'Chef de service', salary = 4000},
    },
    -- Ajoutez vos autres jobs ici
}

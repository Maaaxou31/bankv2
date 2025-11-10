ESX = exports['es_extended']:getSharedObject()

-- Fonction pour générer un IBAN unique
function GenerateIBAN()
    local iban
    local exists = true

    while exists do
        iban = 'FR76' .. math.random(1000, 9999) .. math.random(1000, 9999) .. math.random(1000, 9999) .. math.random(1000, 9999)

        -- Vérifier si l'IBAN existe déjà
        local result = MySQL.Sync.fetchScalar('SELECT COUNT(*) FROM bank_accounts_personal WHERE iban = @iban', {
            ['@iban'] = iban
        })

        local result2 = MySQL.Sync.fetchScalar('SELECT COUNT(*) FROM bank_accounts_business WHERE iban = @iban', {
            ['@iban'] = iban
        })

        if result == 0 and result2 == 0 then
            exists = false
        end
    end

    return iban
end

-- Fonction pour générer un numéro de carte unique
function GenerateCardNumber()
    local cardNumber
    local exists = true

    while exists do
        cardNumber = ''
        for i = 1, 16 do
            cardNumber = cardNumber .. math.random(0, 9)
        end

        local result = MySQL.Sync.fetchScalar('SELECT COUNT(*) FROM bank_cards WHERE card_number = @card_number', {
            ['@card_number'] = cardNumber
        })

        if result == 0 then
            exists = false
        end
    end

    return cardNumber
end

-- Fonction pour générer une date d'expiration
function GenerateExpiryDate()
    local month = math.random(1, 12)
    local year = (tonumber(os.date('%y')) + 3) % 100
    return string.format('%02d/%02d', month, year)
end

-- Fonction pour générer un CVV
function GenerateCVV()
    return string.format('%03d', math.random(0, 999))
end

-- Créer un compte personnel lors de la connexion d'un joueur
RegisterNetEvent('bankv2:server:createPersonalAccount')
AddEventHandler('bankv2:server:createPersonalAccount', function()
    local _source = source
    local xPlayer = ESX.GetPlayerFromId(_source)

    if not xPlayer then
        print('[BankV2] ERROR: xPlayer is nil for source ' .. _source)
        return
    end

    local identifier = xPlayer.identifier
    print('[BankV2] Création de compte pour ' .. identifier)

    -- Vérifier si le compte existe déjà
    MySQL.Async.fetchAll('SELECT * FROM bank_accounts_personal WHERE identifier = @identifier', {
        ['@identifier'] = identifier
    }, function(result)
        if not result[1] then
            local iban = GenerateIBAN()

            -- Récupérer le nom et prénom depuis les variables ESX
            local firstname = xPlayer.get('firstName') or xPlayer.getName():gsub('_', ' '):match("(%S+)") or 'Prénom'
            local lastname = xPlayer.get('lastName') or xPlayer.getName():gsub('_', ' '):match("%S+ (%S+)") or 'Nom'

            print('[BankV2] Insertion du compte pour ' .. firstname .. ' ' .. lastname)

            MySQL.Async.execute('INSERT INTO bank_accounts_personal (identifier, firstname, lastname, iban, balance) VALUES (@identifier, @firstname, @lastname, @iban, @balance)', {
                ['@identifier'] = identifier,
                ['@firstname'] = firstname,
                ['@lastname'] = lastname,
                ['@iban'] = iban,
                ['@balance'] = Config.DefaultPersonalBalance
            }, function(rowsChanged)
                if rowsChanged > 0 then
                    print('[BankV2] ✓ Compte personnel créé pour ' .. xPlayer.getName() .. ' - IBAN: ' .. iban)
                    TriggerClientEvent('bankv2:client:notification', _source, 'success', 'Compte bancaire créé !')
                else
                    print('[BankV2] ✗ Erreur lors de la création du compte')
                end
            end)
        else
            print('[BankV2] Compte existe déjà pour ' .. identifier .. ' - IBAN: ' .. result[1].iban)
        end
    end)
end)

-- Récupérer les informations du compte
ESX.RegisterServerCallback('bankv2:getAccountInfo', function(source, cb, accountType)
    local xPlayer = ESX.GetPlayerFromId(source)

    if not xPlayer then
        print('[BankV2] ERROR: xPlayer is nil in getAccountInfo')
        cb(nil)
        return
    end

    if accountType == 'personal' then
        MySQL.Async.fetchAll('SELECT * FROM bank_accounts_personal WHERE identifier = @identifier', {
            ['@identifier'] = xPlayer.identifier
        }, function(result)
            if result[1] then
                print('[BankV2] Compte trouvé pour ' .. xPlayer.identifier .. ' - Balance: ' .. result[1].balance)
                cb(result[1])
            else
                print('[BankV2] ATTENTION: Compte non trouvé pour ' .. xPlayer.identifier .. ', création...')
                -- Créer le compte s'il n'existe pas
                local iban = GenerateIBAN()
                local firstname = xPlayer.get('firstName') or xPlayer.getName():gsub('_', ' '):match("(%S+)") or 'Prénom'
                local lastname = xPlayer.get('lastName') or xPlayer.getName():gsub('_', ' '):match("%S+ (%S+)") or 'Nom'

                MySQL.Async.execute('INSERT INTO bank_accounts_personal (identifier, firstname, lastname, iban, balance) VALUES (@identifier, @firstname, @lastname, @iban, @balance)', {
                    ['@identifier'] = xPlayer.identifier,
                    ['@firstname'] = firstname,
                    ['@lastname'] = lastname,
                    ['@iban'] = iban,
                    ['@balance'] = Config.DefaultPersonalBalance
                }, function(rowsChanged)
                    if rowsChanged > 0 then
                        print('[BankV2] ✓ Compte créé automatiquement')
                        -- Récupérer le compte nouvellement créé
                        MySQL.Async.fetchAll('SELECT * FROM bank_accounts_personal WHERE identifier = @identifier', {
                            ['@identifier'] = xPlayer.identifier
                        }, function(newResult)
                            cb(newResult[1])
                        end)
                    else
                        print('[BankV2] ✗ Erreur création automatique')
                        cb(nil)
                    end
                end)
            end
        end)
    elseif accountType == 'business' then
        local job = xPlayer.getJob()
        local society = 'society_' .. job.name

        MySQL.Async.fetchAll('SELECT * FROM bank_accounts_business WHERE society = @society', {
            ['@society'] = society
        }, function(result)
            if result[1] then
                print('[BankV2] Compte entreprise trouvé: ' .. society)
                cb(result[1])
            else
                print('[BankV2] Compte entreprise non trouvé: ' .. society .. ', création...')
                -- Créer le compte entreprise s'il n'existe pas
                local iban = GenerateIBAN()
                local societyLabel = job.label or job.name

                MySQL.Async.execute('INSERT INTO bank_accounts_business (society, society_label, iban, balance) VALUES (@society, @society_label, @iban, @balance)', {
                    ['@society'] = society,
                    ['@society_label'] = societyLabel,
                    ['@iban'] = iban,
                    ['@balance'] = Config.DefaultBusinessBalance
                }, function(rowsChanged)
                    if rowsChanged > 0 then
                        print('[BankV2] ✓ Compte entreprise créé: ' .. society)
                        MySQL.Async.fetchAll('SELECT * FROM bank_accounts_business WHERE society = @society', {
                            ['@society'] = society
                        }, function(newResult)
                            cb(newResult[1])
                        end)
                    else
                        cb(nil)
                    end
                end)
            end
        end)
    end
end)

-- Récupérer les cartes bancaires
ESX.RegisterServerCallback('bankv2:getCards', function(source, cb, accountType)
    local xPlayer = ESX.GetPlayerFromId(source)

    MySQL.Async.fetchAll('SELECT * FROM bank_cards WHERE identifier = @identifier AND account_type = @account_type', {
        ['@identifier'] = xPlayer.identifier,
        ['@account_type'] = accountType
    }, function(result)
        cb(result)
    end)
end)

-- Créer une nouvelle carte
RegisterNetEvent('bankv2:server:createCard')
AddEventHandler('bankv2:server:createCard', function(accountType, pin, iban)
    local _source = source
    local xPlayer = ESX.GetPlayerFromId(_source)

    if xPlayer then
        -- Vérifier si le joueur a assez d'argent
        if xPlayer.getMoney() >= Config.CardPrice then
            xPlayer.removeMoney(Config.CardPrice)

            local cardNumber = GenerateCardNumber()
            local expiryDate = GenerateExpiryDate()
            local cvv = GenerateCVV()

            MySQL.Async.execute('INSERT INTO bank_cards (identifier, iban, account_type, pin, card_number, expiry_date, cvv) VALUES (@identifier, @iban, @account_type, @pin, @card_number, @expiry_date, @cvv)', {
                ['@identifier'] = xPlayer.identifier,
                ['@iban'] = iban,
                ['@account_type'] = accountType,
                ['@pin'] = pin,
                ['@card_number'] = cardNumber,
                ['@expiry_date'] = expiryDate,
                ['@cvv'] = cvv
            }, function(rowsChanged)
                TriggerClientEvent('bankv2:client:notification', _source, 'success', 'Carte bancaire créée avec succès !')
                TriggerClientEvent('bankv2:client:refreshCards', _source)
            end)
        else
            TriggerClientEvent('bankv2:client:notification', _source, 'error', 'Vous n\'avez pas assez d\'argent (' .. Config.CardPrice .. Config.Currency .. ')')
        end
    end
end)

-- Bloquer/Débloquer une carte
RegisterNetEvent('bankv2:server:toggleCardBlock')
AddEventHandler('bankv2:server:toggleCardBlock', function(cardId)
    local _source = source
    local xPlayer = ESX.GetPlayerFromId(_source)

    if xPlayer then
        MySQL.Async.fetchAll('SELECT is_blocked FROM bank_cards WHERE id = @id AND identifier = @identifier', {
            ['@id'] = cardId,
            ['@identifier'] = xPlayer.identifier
        }, function(result)
            if result[1] then
                local newStatus = result[1].is_blocked == 1 and 0 or 1

                MySQL.Async.execute('UPDATE bank_cards SET is_blocked = @is_blocked WHERE id = @id', {
                    ['@is_blocked'] = newStatus,
                    ['@id'] = cardId
                }, function(rowsChanged)
                    local message = newStatus == 1 and 'Carte bloquée' or 'Carte débloquée'
                    TriggerClientEvent('bankv2:client:notification', _source, 'success', message)
                    TriggerClientEvent('bankv2:client:refreshCards', _source)
                end)
            end
        end)
    end
end)

-- Déposer de l'argent
RegisterNetEvent('bankv2:server:deposit')
AddEventHandler('bankv2:server:deposit', function(amount, accountType)
    local _source = source
    local xPlayer = ESX.GetPlayerFromId(_source)

    if xPlayer then
        if amount > 0 and amount <= Config.DepositLimit then
            if xPlayer.getMoney() >= amount then
                xPlayer.removeMoney(amount)

                if accountType == 'personal' then
                    MySQL.Async.fetchAll('SELECT * FROM bank_accounts_personal WHERE identifier = @identifier', {
                        ['@identifier'] = xPlayer.identifier
                    }, function(result)
                        if result[1] then
                            local newBalance = result[1].balance + amount

                            MySQL.Async.execute('UPDATE bank_accounts_personal SET balance = @balance WHERE identifier = @identifier', {
                                ['@balance'] = newBalance,
                                ['@identifier'] = xPlayer.identifier
                            }, function(rowsChanged)
                                -- Enregistrer la transaction
                                MySQL.Async.execute('INSERT INTO bank_transactions (from_iban, to_iban, from_name, to_name, amount, type, description) VALUES (@from_iban, @to_iban, @from_name, @to_name, @amount, @type, @description)', {
                                    ['@from_iban'] = 'CASH',
                                    ['@to_iban'] = result[1].iban,
                                    ['@from_name'] = xPlayer.getName(),
                                    ['@to_name'] = xPlayer.getName(),
                                    ['@amount'] = amount,
                                    ['@type'] = 'deposit',
                                    ['@description'] = 'Dépôt en espèces'
                                })

                                TriggerClientEvent('bankv2:client:notification', _source, 'success', 'Dépôt de ' .. amount .. Config.Currency .. ' effectué')
                                TriggerClientEvent('bankv2:client:updateBalance', _source, accountType, newBalance)
                            end)
                        end
                    end)
                end
            else
                TriggerClientEvent('bankv2:client:notification', _source, 'error', 'Vous n\'avez pas assez d\'espèces')
            end
        else
            TriggerClientEvent('bankv2:client:notification', _source, 'error', 'Montant invalide')
        end
    end
end)

-- Retirer de l'argent
RegisterNetEvent('bankv2:server:withdraw')
AddEventHandler('bankv2:server:withdraw', function(amount, accountType, pin)
    local _source = source
    local xPlayer = ESX.GetPlayerFromId(_source)

    if xPlayer then
        if amount > 0 and amount <= Config.WithdrawLimit then
            -- Vérifier le PIN
            MySQL.Async.fetchAll('SELECT * FROM bank_cards WHERE identifier = @identifier AND account_type = @account_type AND pin = @pin AND is_blocked = 0', {
                ['@identifier'] = xPlayer.identifier,
                ['@account_type'] = accountType,
                ['@pin'] = pin
            }, function(cards)
                if cards[1] then
                    if accountType == 'personal' then
                        MySQL.Async.fetchAll('SELECT * FROM bank_accounts_personal WHERE identifier = @identifier', {
                            ['@identifier'] = xPlayer.identifier
                        }, function(result)
                            if result[1] then
                                if result[1].balance >= amount then
                                    local newBalance = result[1].balance - amount

                                    MySQL.Async.execute('UPDATE bank_accounts_personal SET balance = @balance WHERE identifier = @identifier', {
                                        ['@balance'] = newBalance,
                                        ['@identifier'] = xPlayer.identifier
                                    }, function(rowsChanged)
                                        xPlayer.addMoney(amount)

                                        -- Enregistrer la transaction
                                        MySQL.Async.execute('INSERT INTO bank_transactions (from_iban, to_iban, from_name, to_name, amount, type, description) VALUES (@from_iban, @to_iban, @from_name, @to_name, @amount, @type, @description)', {
                                            ['@from_iban'] = result[1].iban,
                                            ['@to_iban'] = 'CASH',
                                            ['@from_name'] = xPlayer.getName(),
                                            ['@to_name'] = xPlayer.getName(),
                                            ['@amount'] = amount,
                                            ['@type'] = 'withdraw',
                                            ['@description'] = 'Retrait en espèces'
                                        })

                                        TriggerClientEvent('bankv2:client:notification', _source, 'success', 'Retrait de ' .. amount .. Config.Currency .. ' effectué')
                                        TriggerClientEvent('bankv2:client:updateBalance', _source, accountType, newBalance)
                                    end)
                                else
                                    TriggerClientEvent('bankv2:client:notification', _source, 'error', 'Solde insuffisant')
                                end
                            end
                        end)
                    end
                else
                    TriggerClientEvent('bankv2:client:notification', _source, 'error', 'Code PIN incorrect ou carte bloquée')
                end
            end)
        else
            TriggerClientEvent('bankv2:client:notification', _source, 'error', 'Montant invalide')
        end
    end
end)

-- Effectuer un virement
RegisterNetEvent('bankv2:server:transfer')
AddEventHandler('bankv2:server:transfer', function(targetIban, amount, accountType, description)
    local _source = source
    local xPlayer = ESX.GetPlayerFromId(_source)

    if xPlayer then
        if amount >= Config.MinTransfer then
            local totalAmount = amount + Config.TransferFee

            -- Récupérer le compte source
            if accountType == 'personal' then
                MySQL.Async.fetchAll('SELECT * FROM bank_accounts_personal WHERE identifier = @identifier', {
                    ['@identifier'] = xPlayer.identifier
                }, function(sourceAccount)
                    if sourceAccount[1] then
                        if sourceAccount[1].balance >= totalAmount then
                            -- Vérifier si l'IBAN cible existe
                            MySQL.Async.fetchAll('SELECT * FROM bank_accounts_personal WHERE iban = @iban', {
                                ['@iban'] = targetIban
                            }, function(targetAccount)
                                if targetAccount[1] then
                                    -- Effectuer le virement
                                    local newSourceBalance = sourceAccount[1].balance - totalAmount
                                    local newTargetBalance = targetAccount[1].balance + amount

                                    MySQL.Async.execute('UPDATE bank_accounts_personal SET balance = @balance WHERE identifier = @identifier', {
                                        ['@balance'] = newSourceBalance,
                                        ['@identifier'] = xPlayer.identifier
                                    })

                                    MySQL.Async.execute('UPDATE bank_accounts_personal SET balance = @balance WHERE iban = @iban', {
                                        ['@balance'] = newTargetBalance,
                                        ['@iban'] = targetIban
                                    })

                                    -- Enregistrer la transaction
                                    MySQL.Async.execute('INSERT INTO bank_transactions (from_iban, to_iban, from_name, to_name, amount, type, description) VALUES (@from_iban, @to_iban, @from_name, @to_name, @amount, @type, @description)', {
                                        ['@from_iban'] = sourceAccount[1].iban,
                                        ['@to_iban'] = targetIban,
                                        ['@from_name'] = sourceAccount[1].firstname .. ' ' .. sourceAccount[1].lastname,
                                        ['@to_name'] = targetAccount[1].firstname .. ' ' .. targetAccount[1].lastname,
                                        ['@amount'] = amount,
                                        ['@type'] = 'transfer',
                                        ['@description'] = description or 'Virement'
                                    })

                                    if Config.TransferFee > 0 then
                                        MySQL.Async.execute('INSERT INTO bank_transactions (from_iban, to_iban, from_name, to_name, amount, type, description) VALUES (@from_iban, @to_iban, @from_name, @to_name, @amount, @type, @description)', {
                                            ['@from_iban'] = sourceAccount[1].iban,
                                            ['@to_iban'] = 'SYSTEM',
                                            ['@from_name'] = sourceAccount[1].firstname .. ' ' .. sourceAccount[1].lastname,
                                            ['@to_name'] = 'Banque',
                                            ['@amount'] = Config.TransferFee,
                                            ['@type'] = 'fee',
                                            ['@description'] = 'Frais de virement'
                                        })
                                    end

                                    TriggerClientEvent('bankv2:client:notification', _source, 'success', 'Virement de ' .. amount .. Config.Currency .. ' effectué')
                                    TriggerClientEvent('bankv2:client:updateBalance', _source, accountType, newSourceBalance)

                                    -- Notifier le destinataire s'il est connecté
                                    local targetPlayer = ESX.GetPlayerFromIdentifier(targetAccount[1].identifier)
                                    if targetPlayer then
                                        TriggerClientEvent('bankv2:client:notification', targetPlayer.source, 'success', 'Vous avez reçu ' .. amount .. Config.Currency)
                                    end
                                else
                                    TriggerClientEvent('bankv2:client:notification', _source, 'error', 'IBAN invalide')
                                end
                            end)
                        else
                            TriggerClientEvent('bankv2:client:notification', _source, 'error', 'Solde insuffisant')
                        end
                    end
                end)
            elseif accountType == 'business' then
                local job = xPlayer.getJob()

                -- Vérifier si le joueur est le patron
                if job.grade_name == 'boss' then
                    MySQL.Async.fetchAll('SELECT * FROM bank_accounts_business WHERE society = @society', {
                        ['@society'] = 'society_' .. job.name
                    }, function(sourceAccount)
                        if sourceAccount[1] then
                            if sourceAccount[1].balance >= totalAmount then
                                -- Vérifier si l'IBAN cible existe
                                MySQL.Async.fetchAll('SELECT * FROM bank_accounts_personal WHERE iban = @iban', {
                                    ['@iban'] = targetIban
                                }, function(targetAccount)
                                    if targetAccount[1] then
                                        -- Effectuer le virement
                                        local newSourceBalance = sourceAccount[1].balance - totalAmount
                                        local newTargetBalance = targetAccount[1].balance + amount

                                        MySQL.Async.execute('UPDATE bank_accounts_business SET balance = @balance WHERE society = @society', {
                                            ['@balance'] = newSourceBalance,
                                            ['@society'] = 'society_' .. job.name
                                        })

                                        MySQL.Async.execute('UPDATE bank_accounts_personal SET balance = @balance WHERE iban = @iban', {
                                            ['@balance'] = newTargetBalance,
                                            ['@iban'] = targetIban
                                        })

                                        -- Enregistrer la transaction
                                        MySQL.Async.execute('INSERT INTO bank_transactions (from_iban, to_iban, from_name, to_name, amount, type, description) VALUES (@from_iban, @to_iban, @from_name, @to_name, @amount, @type, @description)', {
                                            ['@from_iban'] = sourceAccount[1].iban,
                                            ['@to_iban'] = targetIban,
                                            ['@from_name'] = sourceAccount[1].society_label,
                                            ['@to_name'] = targetAccount[1].firstname .. ' ' .. targetAccount[1].lastname,
                                            ['@amount'] = amount,
                                            ['@type'] = 'transfer',
                                            ['@description'] = description or 'Virement'
                                        })

                                        TriggerClientEvent('bankv2:client:notification', _source, 'success', 'Virement de ' .. amount .. Config.Currency .. ' effectué')
                                        TriggerClientEvent('bankv2:client:updateBalance', _source, accountType, newSourceBalance)
                                    else
                                        TriggerClientEvent('bankv2:client:notification', _source, 'error', 'IBAN invalide')
                                    end
                                end)
                            else
                                TriggerClientEvent('bankv2:client:notification', _source, 'error', 'Solde insuffisant')
                            end
                        end
                    end)
                else
                    TriggerClientEvent('bankv2:client:notification', _source, 'error', 'Vous devez être patron pour effectuer des virements')
                end
            end
        else
            TriggerClientEvent('bankv2:client:notification', _source, 'error', 'Montant minimum : ' .. Config.MinTransfer .. Config.Currency)
        end
    end
end)

-- Récupérer l'historique des transactions
ESX.RegisterServerCallback('bankv2:getTransactions', function(source, cb, accountType)
    local xPlayer = ESX.GetPlayerFromId(source)

    if accountType == 'personal' then
        MySQL.Async.fetchAll('SELECT * FROM bank_accounts_personal WHERE identifier = @identifier', {
            ['@identifier'] = xPlayer.identifier
        }, function(account)
            if account[1] then
                MySQL.Async.fetchAll('SELECT * FROM bank_transactions WHERE from_iban = @iban OR to_iban = @iban ORDER BY created_at DESC LIMIT @limit', {
                    ['@iban'] = account[1].iban,
                    ['@limit'] = Config.MaxTransactionHistory
                }, function(transactions)
                    cb(transactions)
                end)
            else
                cb({})
            end
        end)
    elseif accountType == 'business' then
        local job = xPlayer.getJob()
        MySQL.Async.fetchAll('SELECT * FROM bank_accounts_business WHERE society = @society', {
            ['@society'] = 'society_' .. job.name
        }, function(account)
            if account[1] then
                MySQL.Async.fetchAll('SELECT * FROM bank_transactions WHERE from_iban = @iban OR to_iban = @iban ORDER BY created_at DESC LIMIT @limit', {
                    ['@iban'] = account[1].iban,
                    ['@limit'] = Config.MaxTransactionHistory
                }, function(transactions)
                    cb(transactions)
                end)
            else
                cb({})
            end
        end)
    end
end)

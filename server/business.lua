-- Créer un compte entreprise automatiquement lors de l'accès
RegisterNetEvent('bankv2:server:createBusinessAccount')
AddEventHandler('bankv2:server:createBusinessAccount', function(society, societyLabel)
    local _source = source

    -- Vérifier si le compte existe déjà
    MySQL.Async.fetchAll('SELECT * FROM bank_accounts_business WHERE society = @society', {
        ['@society'] = society
    }, function(result)
        if not result[1] then
            local iban = GenerateIBAN()

            MySQL.Async.execute('INSERT INTO bank_accounts_business (society, society_label, iban, balance) VALUES (@society, @society_label, @iban, @balance)', {
                ['@society'] = society,
                ['@society_label'] = societyLabel,
                ['@iban'] = iban,
                ['@balance'] = Config.DefaultBusinessBalance
            }, function(rowsChanged)
                print('[BankV2] Compte entreprise créé pour ' .. societyLabel .. ' - IBAN: ' .. iban)
            end)
        end
    end)
end)

-- Vérifier et créer le compte entreprise lors de l'ouverture du menu
ESX.RegisterServerCallback('bankv2:checkBusinessAccount', function(source, cb, society, societyLabel)
    MySQL.Async.fetchAll('SELECT * FROM bank_accounts_business WHERE society = @society', {
        ['@society'] = society
    }, function(result)
        if not result[1] then
            -- Créer le compte
            local iban = GenerateIBAN()

            MySQL.Async.execute('INSERT INTO bank_accounts_business (society, society_label, iban, balance) VALUES (@society, @society_label, @iban, @balance)', {
                ['@society'] = society,
                ['@society_label'] = societyLabel,
                ['@iban'] = iban,
                ['@balance'] = Config.DefaultBusinessBalance
            }, function(rowsChanged)
                print('[BankV2] Compte entreprise créé pour ' .. societyLabel .. ' - IBAN: ' .. iban)
                cb(true)
            end)
        else
            cb(true)
        end
    end)
end)

-- Déposer de l'argent sur le compte entreprise
RegisterNetEvent('bankv2:server:depositBusiness')
AddEventHandler('bankv2:server:depositBusiness', function(amount)
    local _source = source
    local xPlayer = ESX.GetPlayerFromId(_source)

    if xPlayer then
        local job = xPlayer.getJob()

        if job.grade_name == 'boss' then
            if amount > 0 and amount <= Config.DepositLimit then
                if xPlayer.getMoney() >= amount then
                    xPlayer.removeMoney(amount)

                    MySQL.Async.fetchAll('SELECT * FROM bank_accounts_business WHERE society = @society', {
                        ['@society'] = 'society_' .. job.name
                    }, function(result)
                        if result[1] then
                            local newBalance = result[1].balance + amount

                            MySQL.Async.execute('UPDATE bank_accounts_business SET balance = @balance WHERE society = @society', {
                                ['@balance'] = newBalance,
                                ['@society'] = 'society_' .. job.name
                            }, function(rowsChanged)
                                -- Enregistrer la transaction
                                MySQL.Async.execute('INSERT INTO bank_transactions (from_iban, to_iban, from_name, to_name, amount, type, description) VALUES (@from_iban, @to_iban, @from_name, @to_name, @amount, @type, @description)', {
                                    ['@from_iban'] = 'CASH',
                                    ['@to_iban'] = result[1].iban,
                                    ['@from_name'] = xPlayer.getName(),
                                    ['@to_name'] = result[1].society_label,
                                    ['@amount'] = amount,
                                    ['@type'] = 'deposit',
                                    ['@description'] = 'Dépôt en espèces'
                                })

                                TriggerClientEvent('bankv2:client:notification', _source, 'success', 'Dépôt de ' .. amount .. Config.Currency .. ' effectué')
                                TriggerClientEvent('bankv2:client:updateBalance', _source, 'business', newBalance)
                            end)
                        end
                    end)
                else
                    TriggerClientEvent('bankv2:client:notification', _source, 'error', 'Vous n\'avez pas assez d\'espèces')
                end
            else
                TriggerClientEvent('bankv2:client:notification', _source, 'error', 'Montant invalide')
            end
        else
            TriggerClientEvent('bankv2:client:notification', _source, 'error', 'Vous devez être patron')
        end
    end
end)

-- Retirer de l'argent du compte entreprise
RegisterNetEvent('bankv2:server:withdrawBusiness')
AddEventHandler('bankv2:server:withdrawBusiness', function(amount)
    local _source = source
    local xPlayer = ESX.GetPlayerFromId(_source)

    if xPlayer then
        local job = xPlayer.getJob()

        if job.grade_name == 'boss' then
            if amount > 0 and amount <= Config.WithdrawLimit then
                MySQL.Async.fetchAll('SELECT * FROM bank_accounts_business WHERE society = @society', {
                    ['@society'] = 'society_' .. job.name
                }, function(result)
                    if result[1] then
                        if result[1].balance >= amount then
                            local newBalance = result[1].balance - amount

                            MySQL.Async.execute('UPDATE bank_accounts_business SET balance = @balance WHERE society = @society', {
                                ['@balance'] = newBalance,
                                ['@society'] = 'society_' .. job.name
                            }, function(rowsChanged)
                                xPlayer.addMoney(amount)

                                -- Enregistrer la transaction
                                MySQL.Async.execute('INSERT INTO bank_transactions (from_iban, to_iban, from_name, to_name, amount, type, description) VALUES (@from_iban, @to_iban, @from_name, @to_name, @amount, @type, @description)', {
                                    ['@from_iban'] = result[1].iban,
                                    ['@to_iban'] = 'CASH',
                                    ['@from_name'] = result[1].society_label,
                                    ['@to_name'] = xPlayer.getName(),
                                    ['@amount'] = amount,
                                    ['@type'] = 'withdraw',
                                    ['@description'] = 'Retrait en espèces'
                                })

                                TriggerClientEvent('bankv2:client:notification', _source, 'success', 'Retrait de ' .. amount .. Config.Currency .. ' effectué')
                                TriggerClientEvent('bankv2:client:updateBalance', _source, 'business', newBalance)
                            end)
                        else
                            TriggerClientEvent('bankv2:client:notification', _source, 'error', 'Solde insuffisant')
                        end
                    end
                end)
            else
                TriggerClientEvent('bankv2:client:notification', _source, 'error', 'Montant invalide')
            end
        else
            TriggerClientEvent('bankv2:client:notification', _source, 'error', 'Vous devez être patron')
        end
    end
end)

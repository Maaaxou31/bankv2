-- Récupérer la liste des employés d'une entreprise
ESX.RegisterServerCallback('bankv2:getEmployees', function(source, cb)
    local xPlayer = ESX.GetPlayerFromId(source)
    local job = xPlayer.getJob()

    if job.grade_name == 'boss' then
        -- Récupérer tous les joueurs en ligne avec le même job
        local employees = {}
        local xPlayers = ESX.GetPlayers()

        for i = 1, #xPlayers do
            local employee = ESX.GetPlayerFromId(xPlayers[i])
            if employee then
                local employeeJob = employee.getJob()
                if employeeJob.name == job.name then
                    -- Récupérer l'IBAN du joueur
                    MySQL.Async.fetchAll('SELECT iban, firstname, lastname FROM bank_accounts_personal WHERE identifier = @identifier', {
                        ['@identifier'] = employee.identifier
                    }, function(result)
                        if result[1] then
                            local gradeInfo = Config.JobGrades[job.name] and Config.JobGrades[job.name][employeeJob.grade] or {label = employeeJob.grade_label, salary = 0}

                            table.insert(employees, {
                                identifier = employee.identifier,
                                firstname = result[1].firstname,
                                lastname = result[1].lastname,
                                iban = result[1].iban,
                                grade = employeeJob.grade,
                                grade_label = gradeInfo.label or employeeJob.grade_label,
                                salary = gradeInfo.salary or 0
                            })
                        end
                    end)
                end
            end
        end

        -- Attendre un peu pour que toutes les requêtes SQL soient terminées
        Citizen.Wait(500)
        cb(employees)
    else
        cb({})
    end
end)

-- Payer le salaire d'un employé
RegisterNetEvent('bankv2:server:paySalary')
AddEventHandler('bankv2:server:paySalary', function(employeeData)
    local _source = source
    local xPlayer = ESX.GetPlayerFromId(_source)
    local job = xPlayer.getJob()

    if xPlayer and job.grade_name == 'boss' then
        -- Récupérer le compte de l'entreprise
        MySQL.Async.fetchAll('SELECT * FROM bank_accounts_business WHERE society = @society', {
            ['@society'] = 'society_' .. job.name
        }, function(businessAccount)
            if businessAccount[1] then
                if businessAccount[1].balance >= employeeData.salary then
                    -- Récupérer le compte de l'employé
                    MySQL.Async.fetchAll('SELECT * FROM bank_accounts_personal WHERE iban = @iban', {
                        ['@iban'] = employeeData.iban
                    }, function(employeeAccount)
                        if employeeAccount[1] then
                            -- Effectuer le paiement
                            local newBusinessBalance = businessAccount[1].balance - employeeData.salary
                            local newEmployeeBalance = employeeAccount[1].balance + employeeData.salary

                            MySQL.Async.execute('UPDATE bank_accounts_business SET balance = @balance WHERE society = @society', {
                                ['@balance'] = newBusinessBalance,
                                ['@society'] = 'society_' .. job.name
                            })

                            MySQL.Async.execute('UPDATE bank_accounts_personal SET balance = @balance WHERE iban = @iban', {
                                ['@balance'] = newEmployeeBalance,
                                ['@iban'] = employeeData.iban
                            })

                            -- Enregistrer la transaction
                            MySQL.Async.execute('INSERT INTO bank_transactions (from_iban, to_iban, from_name, to_name, amount, type, description) VALUES (@from_iban, @to_iban, @from_name, @to_name, @amount, @type, @description)', {
                                ['@from_iban'] = businessAccount[1].iban,
                                ['@to_iban'] = employeeData.iban,
                                ['@from_name'] = businessAccount[1].society_label,
                                ['@to_name'] = employeeData.firstname .. ' ' .. employeeData.lastname,
                                ['@amount'] = employeeData.salary,
                                ['@type'] = 'salary',
                                ['@description'] = 'Paiement de salaire - ' .. employeeData.grade_label
                            })

                            -- Enregistrer le paiement de salaire
                            MySQL.Async.execute('INSERT INTO bank_salary_payments (employee_identifier, employee_name, society, amount, iban) VALUES (@employee_identifier, @employee_name, @society, @amount, @iban)', {
                                ['@employee_identifier'] = employeeData.identifier,
                                ['@employee_name'] = employeeData.firstname .. ' ' .. employeeData.lastname,
                                ['@society'] = 'society_' .. job.name,
                                ['@amount'] = employeeData.salary,
                                ['@iban'] = employeeData.iban
                            })

                            TriggerClientEvent('bankv2:client:notification', _source, 'success', 'Salaire payé à ' .. employeeData.firstname .. ' ' .. employeeData.lastname)
                            TriggerClientEvent('bankv2:client:updateBalance', _source, 'business', newBusinessBalance)

                            -- Notifier l'employé s'il est connecté
                            local targetPlayer = ESX.GetPlayerFromIdentifier(employeeData.identifier)
                            if targetPlayer then
                                TriggerClientEvent('bankv2:client:notification', targetPlayer.source, 'success', 'Vous avez reçu votre salaire : ' .. employeeData.salary .. Config.Currency)
                            end
                        else
                            TriggerClientEvent('bankv2:client:notification', _source, 'error', 'Compte de l\'employé introuvable')
                        end
                    end)
                else
                    TriggerClientEvent('bankv2:client:notification', _source, 'error', 'Solde de l\'entreprise insuffisant')
                end
            else
                TriggerClientEvent('bankv2:client:notification', _source, 'error', 'Compte de l\'entreprise introuvable')
            end
        end)
    end
end)

-- Payer tous les salaires
RegisterNetEvent('bankv2:server:payAllSalaries')
AddEventHandler('bankv2:server:payAllSalaries', function()
    local _source = source
    local xPlayer = ESX.GetPlayerFromId(_source)
    local job = xPlayer.getJob()

    if xPlayer and job.grade_name == 'boss' then
        -- Récupérer le compte de l'entreprise
        MySQL.Async.fetchAll('SELECT * FROM bank_accounts_business WHERE society = @society', {
            ['@society'] = 'society_' .. job.name
        }, function(businessAccount)
            if businessAccount[1] then
                local xPlayers = ESX.GetPlayers()
                local totalSalaries = 0
                local employeesToPay = {}

                -- Calculer le total des salaires
                for i = 1, #xPlayers do
                    local employee = ESX.GetPlayerFromId(xPlayers[i])
                    if employee then
                        local employeeJob = employee.getJob()
                        if employeeJob.name == job.name then
                            local gradeInfo = Config.JobGrades[job.name] and Config.JobGrades[job.name][employeeJob.grade] or {salary = 0}
                            totalSalaries = totalSalaries + gradeInfo.salary

                            MySQL.Async.fetchAll('SELECT iban, firstname, lastname FROM bank_accounts_personal WHERE identifier = @identifier', {
                                ['@identifier'] = employee.identifier
                            }, function(result)
                                if result[1] then
                                    table.insert(employeesToPay, {
                                        identifier = employee.identifier,
                                        firstname = result[1].firstname,
                                        lastname = result[1].lastname,
                                        iban = result[1].iban,
                                        grade_label = gradeInfo.label or employeeJob.grade_label,
                                        salary = gradeInfo.salary or 0
                                    })
                                end
                            end)
                        end
                    end
                end

                -- Attendre que toutes les requêtes soient terminées
                Citizen.Wait(500)

                if businessAccount[1].balance >= totalSalaries then
                    local newBalance = businessAccount[1].balance

                    for _, employeeData in pairs(employeesToPay) do
                        if employeeData.salary > 0 then
                            MySQL.Async.fetchAll('SELECT * FROM bank_accounts_personal WHERE iban = @iban', {
                                ['@iban'] = employeeData.iban
                            }, function(employeeAccount)
                                if employeeAccount[1] then
                                    local newEmployeeBalance = employeeAccount[1].balance + employeeData.salary

                                    MySQL.Async.execute('UPDATE bank_accounts_personal SET balance = @balance WHERE iban = @iban', {
                                        ['@balance'] = newEmployeeBalance,
                                        ['@iban'] = employeeData.iban
                                    })

                                    -- Enregistrer la transaction
                                    MySQL.Async.execute('INSERT INTO bank_transactions (from_iban, to_iban, from_name, to_name, amount, type, description) VALUES (@from_iban, @to_iban, @from_name, @to_name, @amount, @type, @description)', {
                                        ['@from_iban'] = businessAccount[1].iban,
                                        ['@to_iban'] = employeeData.iban,
                                        ['@from_name'] = businessAccount[1].society_label,
                                        ['@to_name'] = employeeData.firstname .. ' ' .. employeeData.lastname,
                                        ['@amount'] = employeeData.salary,
                                        ['@type'] = 'salary',
                                        ['@description'] = 'Paiement de salaire - ' .. employeeData.grade_label
                                    })

                                    MySQL.Async.execute('INSERT INTO bank_salary_payments (employee_identifier, employee_name, society, amount, iban) VALUES (@employee_identifier, @employee_name, @society, @amount, @iban)', {
                                        ['@employee_identifier'] = employeeData.identifier,
                                        ['@employee_name'] = employeeData.firstname .. ' ' .. employeeData.lastname,
                                        ['@society'] = 'society_' .. job.name,
                                        ['@amount'] = employeeData.salary,
                                        ['@iban'] = employeeData.iban
                                    })

                                    local targetPlayer = ESX.GetPlayerFromIdentifier(employeeData.identifier)
                                    if targetPlayer then
                                        TriggerClientEvent('bankv2:client:notification', targetPlayer.source, 'success', 'Vous avez reçu votre salaire : ' .. employeeData.salary .. Config.Currency)
                                    end
                                end
                            end)

                            newBalance = newBalance - employeeData.salary
                        end
                    end

                    MySQL.Async.execute('UPDATE bank_accounts_business SET balance = @balance WHERE society = @society', {
                        ['@balance'] = newBalance,
                        ['@society'] = 'society_' .. job.name
                    })

                    TriggerClientEvent('bankv2:client:notification', _source, 'success', 'Tous les salaires ont été payés (' .. totalSalaries .. Config.Currency .. ')')
                    TriggerClientEvent('bankv2:client:updateBalance', _source, 'business', newBalance)
                else
                    TriggerClientEvent('bankv2:client:notification', _source, 'error', 'Solde de l\'entreprise insuffisant')
                end
            end
        end)
    end
end)

-- Récupérer l'historique des paiements de salaires
ESX.RegisterServerCallback('bankv2:getSalaryHistory', function(source, cb)
    local xPlayer = ESX.GetPlayerFromId(source)
    local job = xPlayer.getJob()

    if job.grade_name == 'boss' then
        MySQL.Async.fetchAll('SELECT * FROM bank_salary_payments WHERE society = @society ORDER BY paid_at DESC LIMIT 50', {
            ['@society'] = 'society_' .. job.name
        }, function(result)
            cb(result)
        end)
    else
        cb({})
    end
end)

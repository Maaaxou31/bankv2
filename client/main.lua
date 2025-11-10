ESX = exports['es_extended']:getSharedObject()
local PlayerData = {}
local bankOpen = false
local currentATM = nil
local cardProp = nil
local hasCard = false

Citizen.CreateThread(function()
    while ESX.GetPlayerData().job == nil do
        Citizen.Wait(10)
    end

    PlayerData = ESX.GetPlayerData()
end)

RegisterNetEvent('esx:playerLoaded')
AddEventHandler('esx:playerLoaded', function(xPlayer)
    PlayerData = xPlayer
    TriggerServerEvent('bankv2:server:createPersonalAccount')
end)

RegisterNetEvent('esx:setJob')
AddEventHandler('esx:setJob', function(job)
    PlayerData.job = job
end)

-- Commandes pour ouvrir la banque
RegisterCommand('bank', function()
    OpenBank('personal')
end)

RegisterCommand('bankpro', function()
    -- Vérifier si le joueur a un job
    if PlayerData.job and PlayerData.job.name ~= 'unemployed' then
        OpenBank('business')
    else
        ESX.ShowNotification('~r~Vous n\'avez pas d\'entreprise')
    end
end)

-- Ouvrir la banque
function OpenBank(accountType)
    if not bankOpen then
        -- Vérifier si le compte entreprise est autorisé
        if accountType == 'business' then
            if not PlayerData.job or PlayerData.job.name == 'unemployed' then
                ESX.ShowNotification('~r~Vous n\'avez pas d\'entreprise')
                return
            end
        end

        bankOpen = true
        SetNuiFocus(true, true)

        -- Envoyer les infos au NUI
        local hasJob = PlayerData.job and PlayerData.job.name ~= 'unemployed'
        local isBoss = hasJob and PlayerData.job.grade_name == 'boss'

        SendNUIMessage({
            action = 'open',
            accountType = accountType,
            hasJob = hasJob,
            isBoss = isBoss
        })
    end
end

-- Fermer la banque
RegisterNUICallback('close', function(data, cb)
    bankOpen = false
    SetNuiFocus(false, false)
    SendNUIMessage({
        action = 'close'
    })
    cb('ok')
end)

-- Désactiver les contrôles quand la banque est ouverte
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)

        if bankOpen then
            DisableControlAction(0, 1, true) -- LookLeftRight
            DisableControlAction(0, 2, true) -- LookUpDown
            DisableControlAction(0, 142, true) -- MeleeAttackAlternate
            DisableControlAction(0, 106, true) -- VehicleMouseControlOverride
            DisableControlAction(0, 24, true) -- Attack
            DisableControlAction(0, 25, true) -- Aim
        else
            Citizen.Wait(500)
        end
    end
end)

-- NUI Callbacks
RegisterNUICallback('getAccountInfo', function(data, cb)
    ESX.TriggerServerCallback('bankv2:getAccountInfo', function(accountInfo)
        cb(accountInfo)
    end, data.accountType)
end)

RegisterNUICallback('getCards', function(data, cb)
    ESX.TriggerServerCallback('bankv2:getCards', function(cards)
        cb(cards)
    end, data.accountType)
end)

RegisterNUICallback('getTransactions', function(data, cb)
    ESX.TriggerServerCallback('bankv2:getTransactions', function(transactions)
        cb(transactions)
    end, data.accountType)
end)

RegisterNUICallback('getEmployees', function(data, cb)
    ESX.TriggerServerCallback('bankv2:getEmployees', function(employees)
        cb(employees)
    end)
end)

RegisterNUICallback('deposit', function(data, cb)
    TriggerServerEvent('bankv2:server:deposit', data.amount, data.accountType)
    cb('ok')
end)

RegisterNUICallback('withdraw', function(data, cb)
    TriggerServerEvent('bankv2:server:withdraw', data.amount, data.accountType, data.pin)
    cb('ok')
end)

RegisterNUICallback('transfer', function(data, cb)
    TriggerServerEvent('bankv2:server:transfer', data.targetIban, data.amount, data.accountType, data.description)
    cb('ok')
end)

RegisterNUICallback('createCard', function(data, cb)
    TriggerServerEvent('bankv2:server:createCard', data.accountType, data.pin, data.iban)
    cb('ok')
end)

RegisterNUICallback('toggleCardBlock', function(data, cb)
    TriggerServerEvent('bankv2:server:toggleCardBlock', data.cardId)
    cb('ok')
end)

RegisterNUICallback('paySalary', function(data, cb)
    TriggerServerEvent('bankv2:server:paySalary', data.employee)
    cb('ok')
end)

RegisterNUICallback('payAllSalaries', function(data, cb)
    TriggerServerEvent('bankv2:server:payAllSalaries')
    cb('ok')
end)

-- Client events
RegisterNetEvent('bankv2:client:notification')
AddEventHandler('bankv2:client:notification', function(type, message)
    SendNUIMessage({
        action = 'notification',
        type = type,
        message = message
    })
end)

RegisterNetEvent('bankv2:client:updateBalance')
AddEventHandler('bankv2:client:updateBalance', function(accountType, balance)
    SendNUIMessage({
        action = 'updateBalance',
        accountType = accountType,
        balance = balance
    })

    -- Recharger les transactions
    Citizen.Wait(500)
    if bankOpen then
        SendNUIMessage({
            action = 'refreshTransactions'
        })
    end
end)

RegisterNetEvent('bankv2:client:refreshCards')
AddEventHandler('bankv2:client:refreshCards', function()
    SendNUIMessage({
        action = 'refreshCards'
    })
end)

-- Créer les blips pour les ATM
Citizen.CreateThread(function()
    for _, atmCoords in pairs(Config.ATMLocations) do
        local blip = AddBlipForCoord(atmCoords.x, atmCoords.y, atmCoords.z)
        SetBlipSprite(blip, 277)
        SetBlipDisplay(blip, 4)
        SetBlipScale(blip, 0.7)
        SetBlipColour(blip, 2)
        SetBlipAsShortRange(blip, true)
        BeginTextCommandSetBlipName("STRING")
        AddTextComponentString("Distributeur")
        EndTextCommandSetBlipName(blip)
    end
end)

-- Détecter les ATM proches
Citizen.CreateThread(function()
    local sleep = 500
    local isNearATM = false

    while true do
        Citizen.Wait(sleep)

        local playerPed = PlayerPedId()
        local playerCoords = GetEntityCoords(playerPed)
        local nearATM = false

        -- Vérifier les props ATM en priorité
        for _, model in pairs(Config.ATMModels) do
            local atm = GetClosestObjectOfType(playerCoords.x, playerCoords.y, playerCoords.z, 2.5, model, false, false, false)

            if atm ~= 0 then
                local atmCoords = GetEntityCoords(atm)
                local distance = #(playerCoords - atmCoords)

                if distance < 2.5 then
                    nearATM = true
                    sleep = 0

                    if not isNearATM then
                        print('[BankV2] Joueur proche d\'un ATM')
                        isNearATM = true
                    end

                    -- Afficher le texte d'aide
                    ESX.ShowHelpNotification('Appuyez sur ~INPUT_CONTEXT~ pour accéder au distributeur')

                    -- Vérifier si le joueur appuie sur E
                    if IsControlJustReleased(0, 38) and not bankOpen then
                        print('[BankV2] Ouverture ATM...')
                        OpenBank('personal')
                    end

                    break
                end
            end
        end

        -- Vérifier les ATM configurés si aucun prop trouvé
        if not nearATM then
            for _, atmCoords in pairs(Config.ATMLocations) do
                local distance = #(playerCoords - atmCoords)

                if distance < 2.5 then
                    nearATM = true
                    sleep = 0

                    if not isNearATM then
                        print('[BankV2] Joueur proche d\'un ATM (position fixe)')
                        isNearATM = true
                    end

                    ESX.ShowHelpNotification('Appuyez sur ~INPUT_CONTEXT~ pour accéder au distributeur')

                    if IsControlJustReleased(0, 38) and not bankOpen then
                        print('[BankV2] Ouverture ATM...')
                        OpenBank('personal')
                    end

                    break
                end
            end
        end

        if not nearATM then
            sleep = 500
            if isNearATM then
                isNearATM = false
                print('[BankV2] Joueur éloigné de l\'ATM')
            end
        end
    end
end)

-- Commande pour toggle le prop de carte
RegisterCommand('card', function()
    ToggleCardProp()
end)

RegisterCommand('carte', function()
    ToggleCardProp()
end)

-- Toggle card prop
function ToggleCardProp()
    if cardProp then
        RemoveCardProp()
    else
        CreateCardProp()
    end
end

-- Créer le prop de carte
function CreateCardProp()
    local playerPed = PlayerPedId()

    -- Vérifier si le joueur a une carte
    ESX.TriggerServerCallback('bankv2:getCards', function(cards)
        if cards and #cards > 0 then
            -- Charger le modèle
            local model = GetHashKey(Config.CardProps.model)
            RequestModel(model)

            while not HasModelLoaded(model) do
                Citizen.Wait(100)
            end

            -- Créer le prop
            cardProp = CreateObject(model, 0.0, 0.0, 0.0, true, true, true)
            AttachEntityToEntity(
                cardProp,
                playerPed,
                GetPedBoneIndex(playerPed, Config.CardProps.bone),
                Config.CardProps.offset.pos.x,
                Config.CardProps.offset.pos.y,
                Config.CardProps.offset.pos.z,
                Config.CardProps.offset.rot.x,
                Config.CardProps.offset.rot.y,
                Config.CardProps.offset.rot.z,
                true, true, false, true, 1, true
            )

            hasCard = true
            ESX.ShowNotification('Carte sortie')
        else
            ESX.ShowNotification('~r~Vous n\'avez pas de carte bancaire')
        end
    end, 'personal')
end

-- Retirer le prop de carte
function RemoveCardProp()
    if cardProp then
        DeleteObject(cardProp)
        cardProp = nil
        hasCard = false
        ESX.ShowNotification('Carte rangée')
    end
end

-- Retirer le prop de carte quand le joueur meurt
AddEventHandler('onResourceStop', function(resourceName)
    if (GetCurrentResourceName() ~= resourceName) then
        return
    end
    RemoveCardProp()
end)

-- Retirer le prop de carte quand le joueur meurt
AddEventHandler('esx:onPlayerDeath', function()
    RemoveCardProp()
end)

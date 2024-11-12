ESX = exports["es_extended"]:getSharedObject()

local playerIdentity = {}
local alreadyRegistered = {}

-- FUNCTIONS

local function deleteIdentityFromDatabase(xPlayer)
    MySQL.query.await("UPDATE users SET firstname = ?, lastname = ?, dateofbirth = ?, sex = ?, height = ?, skin = ? WHERE identifier = ?", { nil, nil, nil, nil, nil, nil, xPlayer.identifier })

    MySQL.update.await("UPDATE addon_account_data SET money = 0 WHERE account_name IN (?) AND owner = ?", { { "bank_savings", "caution" }, xPlayer.identifier })

    MySQL.prepare.await("UPDATE datastore_data SET data = ? WHERE name IN (?) AND owner = ?", { "'{}'", { "user_ears", "user_glasses", "user_helmet", "user_mask" }, xPlayer.identifier })
end

local function deleteIdentity(xPlayer)
    if not alreadyRegistered[xPlayer.identifier] then
        return
    end

    xPlayer.setName(("%s %s"):format(nil, nil))
    xPlayer.set("firstName", nil)
    xPlayer.set("lastName", nil)
    xPlayer.set("dateofbirth", nil)
    xPlayer.set("sex", nil)
    xPlayer.set("height", nil)
    deleteIdentityFromDatabase(xPlayer)
end

local function saveIdentityToDatabase(identifier, identity)
    MySQL.update.await("UPDATE users SET firstname = ?, lastname = ?, dateofbirth = ?, sex = ?, height = ? WHERE identifier = ?", { identity.firstName, identity.lastName, identity.dateOfBirth, identity.sex, identity.height, identifier })
end

local function formatDate(str)
    local d, m, y = string.match(str, "(%d+)/(%d+)/(%d+)")
    local date = str

    return date
end

local function convertToLowerCase(str)
    return string.lower(str)
end

local function convertFirstLetterToUpper(str)
    return str:gsub("^%l", string.upper)
end

local function formatName(name)
    local loweredName = convertToLowerCase(name)
    return convertFirstLetterToUpper(loweredName)
end

local function setIdentity(xPlayer)
    if not alreadyRegistered[xPlayer.identifier] then
        return
    end
    local currentIdentity = playerIdentity[xPlayer.identifier]

    xPlayer.setName(("%s %s"):format(currentIdentity.firstName, currentIdentity.lastName))
    xPlayer.set("firstName", currentIdentity.firstName)
    xPlayer.set("lastName", currentIdentity.lastName)
    xPlayer.set("dateofbirth", currentIdentity.dateOfBirth)
    xPlayer.set("sex", currentIdentity.sex)
    xPlayer.set("height", currentIdentity.height)
    TriggerClientEvent("esx_identity:setPlayerData", xPlayer.source, currentIdentity)
    if currentIdentity.saveToDatabase then
        saveIdentityToDatabase(xPlayer.identifier, currentIdentity)
    end

    playerIdentity[xPlayer.identifier] = nil
end

local function checkIdentity(xPlayer)
    MySQL.single("SELECT firstname, lastname, dateofbirth, sex, height FROM users WHERE identifier = ?", { xPlayer.identifier }, function(result)
        if not result then
            return TriggerClientEvent("esx_identity:showRegisterIdentity", xPlayer.source)
        end
        if not result.firstname then
            playerIdentity[xPlayer.identifier] = nil
            alreadyRegistered[xPlayer.identifier] = false
            return TriggerClientEvent("esx_identity:showRegisterIdentity", xPlayer.source)
        end

        playerIdentity[xPlayer.identifier] = {
            firstName = result.firstname,
            lastName = result.lastname,
            dateOfBirth = result.dateofbirth,
            sex = result.sex,
            height = result.height,
        }

        alreadyRegistered[xPlayer.identifier] = true
        setIdentity(xPlayer)
    end)
end

-- EVENTS

AddEventHandler("playerConnecting", function(_, _, deferrals)
    deferrals.defer()
    local _, identifier = source, ESX.GetIdentifier(source)
    Wait(40)

    if not identifier then
        return deferrals.done('identifier was not found')
    end
    MySQL.single("SELECT firstname, lastname, dateofbirth, sex, height FROM users WHERE identifier = ?", { identifier }, function(result)
        if not result then
            playerIdentity[identifier] = nil
            alreadyRegistered[identifier] = false
            return deferrals.done()
        end
        if not result.firstname then
            playerIdentity[identifier] = nil
            alreadyRegistered[identifier] = false
            return deferrals.done()
        end

        playerIdentity[identifier] = {
            firstName = result.firstname,
            lastName = result.lastname,
            dateOfBirth = result.dateofbirth,
            sex = result.sex,
            height = result.height,
        }

        alreadyRegistered[identifier] = true

        deferrals.done()
    end)
end)

AddEventHandler("onResourceStart", function(resource)
    if resource ~= GetCurrentResourceName() then
        return
    end
    Wait(300)

    while not ESX do
        Wait(0)
    end

    local xPlayers = ESX.GetExtendedPlayers()

    for i = 1, #xPlayers do
        if xPlayers[i] then
            checkIdentity(xPlayers[i])
        end
    end
end)

RegisterNetEvent("esx:playerLoaded", function(_, xPlayer)
    local currentIdentity = playerIdentity[xPlayer.identifier]

    if currentIdentity and alreadyRegistered[xPlayer.identifier] then
        xPlayer.setName(("%s %s"):format(currentIdentity.firstName, currentIdentity.lastName))
        xPlayer.set("firstName", currentIdentity.firstName)
        xPlayer.set("lastName", currentIdentity.lastName)
        xPlayer.set("dateofbirth", currentIdentity.dateOfBirth)
        xPlayer.set("sex", currentIdentity.sex)
        xPlayer.set("height", currentIdentity.height)
        TriggerClientEvent("esx_identity:setPlayerData", xPlayer.source, currentIdentity)
        if currentIdentity.saveToDatabase then
            saveIdentityToDatabase(xPlayer.identifier, currentIdentity)
        end

        Wait(0)

        TriggerClientEvent("esx_identity:alreadyRegistered", xPlayer.source)

        playerIdentity[xPlayer.identifier] = nil
    else
        TriggerClientEvent("esx_identity:showRegisterIdentity", xPlayer.source)
    end
end)

-- REGISTER CALLBACK
ESX.RegisterServerCallback("esx_identity:registerIdentity", function(source, cb, data)
    local xPlayer = ESX.GetPlayerFromId(source)

    if xPlayer then
        if alreadyRegistered[xPlayer.identifier] then
            xPlayer.showNotification("Already registered!", "error")
            return cb(false)
        end

        playerIdentity[xPlayer.identifier] = {
            firstName = formatName(data.firstname),
            lastName = formatName(data.lastname),
            dateOfBirth = formatDate(data.dateofbirth),
            sex = data.sex,
            height = data.height,
        }

        local currentIdentity = playerIdentity[xPlayer.identifier]

        xPlayer.setName(("%s %s"):format(currentIdentity.firstName, currentIdentity.lastName))
        xPlayer.set("firstName", currentIdentity.firstName)
        xPlayer.set("lastName", currentIdentity.lastName)
        xPlayer.set("dateofbirth", currentIdentity.dateOfBirth)
        xPlayer.set("sex", currentIdentity.sex)
        xPlayer.set("height", currentIdentity.height)
        TriggerClientEvent("esx_identity:setPlayerData", xPlayer.source, currentIdentity)
        saveIdentityToDatabase(xPlayer.identifier, currentIdentity)
        alreadyRegistered[xPlayer.identifier] = true
        playerIdentity[xPlayer.identifier] = nil
        return cb(true)
    end
end)

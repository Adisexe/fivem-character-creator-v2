ESX = exports["es_extended"]:getSharedObject();

local isPanelVisible = false
local mouseStatus = true
local loadingScreenFinished = false

local camHeight = 0.0
local camZoom = 20

local camera = nil

local elements = {}
local neededComponents = {
    'mom',
    'dad',
    'face_md_weight',
    'skin_md_weight',
    'hair_1',
    'hair_2',
    'eyebrows_1',
    'eyebrows_2',
    'eyebrow_color_1',
    'beard_1',
    'beard_2',
    'beard_3',
    'eye_squint',
    'eye_color',
    'bodyb_1',
    'bodyb_2',
    'helmet_1',
    'helmet_2',
    'tshirt_1',
    'tshirt_2',
    'torso_1',
    'torso_2',
    'arms',
    'arms_2',
    'pants_1',
    'pants_2',
    'shoes_1',
    'shoes_2',
    'nose_1',
    'nose_3',
    'nose_4',
    'nose_5',
    'nose_6',
    'cheeks_1',
    'cheeks_2',
    'cheeks_3',
    'jaw_1',
    'jaw_2',
    'chin_1',
    'chin_2',
    'chin_3',
    'chin_4',
    'lip_thickness',
    'neck_thickness'
}

-- NUI CALLBACKS
RegisterNUICallback('updateCharValue', function(data)
	TriggerEvent("skinchanger:getSkin", function(skin)
		skin[data.name] = tonumber(data.value)
		TriggerEvent("skinchanger:loadSkin", skin)
	end)
	Wait(1000)
end)

RegisterNUICallback('mouseStatus', function(data)
	mouseStatus = data.status
end)

RegisterNUICallback("register", function(data, cb)
    if not isPanelVisible then
        return
    end

    ESX.TriggerServerCallback("esx_identity:registerIdentity", function(callback)
        if not callback then
            return
        end

        ESX.ShowNotification('Welcome!')

        TriggerEvent("skinchanger:getSkin", function(skin)
            TriggerServerEvent("esx_skin:save", skin)
        end)

        DoScreenFadeOut(0)
        setIdentityPanelShow(false)
        Wait(1000)

        TriggerEvent('select_spawn:showMenu', true, true)
    end, data)
    cb(1)
end)

-- PANEL FUNCTIONS
function setIdentityPanelShow(status)
    isPanelVisible = status
    SetNuiFocus(status, status)
    SetNuiFocusKeepInput(status)

    if status then

        ESX.TriggerServerCallback("esx_skin:getPlayerSkin", function(skin)
            if skin == nil then
                TriggerEvent("skinchanger:loadSkin", { sex = 0 })
                Wait(100)
            else
                TriggerEvent("skinchanger:loadSkin", skin)
                Wait(100)
            end
        end)

        TriggerEvent("skinchanger:getData", function(components, maxVals)
            for _, component in ipairs(components) do
                for _, needed in ipairs(neededComponents) do
                    if component.name == needed then
                        table.insert(elements, {
                            name = component.name,
                            value = component.value,
                            min = component.min,
                            max = maxVals[component.name]
                        })
                    end
                end
            end

            createScenery()
            DisplayRadar(false)

            Wait(1000)

            SendNUIMessage({type = "enableui", enable = status, componentData = json.encode(elements) })
            DoScreenFadeIn(2500)
        end)
    else
        SendNUIMessage({type = "enableui", enable = status})
        deleteScenery()
    end
end

function changemodel(skin)
    local model = GetHashKey(skin)
    if IsModelInCdimage(model) and IsModelValid(model) then
        RequestModel(model)
        while not HasModelLoaded(model) do
            Citizen.Wait(0)
        end
		SetPlayerModel(PlayerId(), model)
		
		SetPedDefaultComponentVariation(GetPlayerPed(-1))
        
        SetModelAsNoLongerNeeded(model)
        TriggerEvent('esx:restoreLoadout')
        ped = GetPlayerPed(-1)
        SetPedDefaultComponentVariation(ped)
        if skin == 'mp_m_freemode_01' then
            sex_ped = 0
        elseif skin == 'mp_f_freemode_01' then
            sex_ped = 1
        end
    end
end
-- CAMERA FUNCTIONS

function createScenery()
    local playerPed = PlayerPedId()

    SetEntityCoords(playerPed, 2529.666, -1667.116, 14.16)
    SetEntityHeading(playerPed, 90.709)
    
    local playerCoords = GetEntityCoords(playerPed)

    camera = CreateCamWithParams("DEFAULT_SCRIPTED_CAMERA", playerCoords.x-2.5, playerCoords.y, playerCoords.z, 0.0, 0.0, 0.0, 60.0, true, 2)
    local rot = GetCamRot(camera, 2)
    SetCamRot(camera, rot.x, rot.y, -90.0, 2)
    SetCamFov(camera, 60.0)
    SetEntityHeading(camera, 180.709)
    SetCamActive(camera, true)
    RenderScriptCams(true, false, 0, true, true)
end

function deleteScenery()
    SetCamActive(camera, false)
    RenderScriptCams(false, false, 0, true, true)
    DestroyCam(camera, false)
    camera = nil
end

-- CAMERA CONTROLS

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(1)
        if camera then
            DisableAllControlActions(0)
            if mouseStatus == false then
                if IsDisabledControlPressed(0, 25) then
                    local mouseY = GetDisabledControlNormal(0, 2)

                    cantUp = camHeight > 0.7
                    cantDown = camHeight < -0.7 

                    if mouseY < -0.1 then
                        if not cantUp then
                            local x, y, z = table.unpack(GetCamCoord(camera))
                            SetCamCoord(camera, x, y, z + 0.01)
                            camHeight = camHeight + 0.01
                        end
                    elseif mouseY > 0.1 then
                        if not cantDown then
                            local x, y, z = table.unpack(GetCamCoord(camera))
                            SetCamCoord(camera, x, y, z - 0.01)
                            camHeight = camHeight - 0.01
                        end
                    end
                elseif IsDisabledControlPressed(0, 24) then
                    local mouseX = GetDisabledControlNormal(0, 1)

                    if mouseX < -0.1 then
                        local playerPed = PlayerPedId()
                        SetEntityHeading(playerPed, GetEntityHeading(playerPed) - 2.5)
                    elseif mouseX > 0.1 then
                        local playerPed = PlayerPedId()
                        SetEntityHeading(playerPed, GetEntityHeading(playerPed) + 2.5)
                    end
                elseif IsDisabledControlPressed(0, 15) then
                    if not (camZoom == 0) then
                        local x, y, z = table.unpack(GetCamCoord(camera))
                        SetCamCoord(camera, x + 0.1, y, z)
                        camZoom = camZoom - 1 
                    end
                elseif IsDisabledControlPressed(0, 14) then 
                    if not (camZoom == 20) then
                        local x, y, z = table.unpack(GetCamCoord(camera))
                        SetCamCoord(camera, x - 0.1, y, z)
                        camZoom = camZoom + 1
                    end
                end
            end
        end
    end
end)

-- EVENTS
RegisterNetEvent("esx_identity:showRegisterIdentity", function()
    TriggerEvent("esx_skin:resetFirstSpawn")
    while not loadingScreenFinished do
        Wait(100)
    end
    if not ESX.PlayerData.dead then
        setIdentityPanelShow(true)
    end
end)

RegisterNetEvent("esx_identity:alreadyRegistered", function()
    while not loadingScreenFinished do
        Wait(100)
    end
    TriggerEvent("esx_skin:playerRegistered")
    TriggerEvent('select_spawn:showMenu', true, false)
end)

RegisterNetEvent("esx_identity:setPlayerData", function(data)
    SetTimeout(1, function()
        ESX.SetPlayerData("name", ("%s %s"):format(data.firstName, data.lastName))
        ESX.SetPlayerData("firstName", data.firstName)
        ESX.SetPlayerData("lastName", data.lastName)
        ESX.SetPlayerData("dateofbirth", data.dateOfBirth)
        ESX.SetPlayerData("sex", data.sex)
        ESX.SetPlayerData("height", data.height)
    end)
end)

AddEventHandler("esx:loadingScreenOff", function()
    loadingScreenFinished = true
end)

Citizen.CreateThread(function()
    local model = GetHashKey("mp_m_freemode_01")
    if IsModelInCdimage(model) and IsModelValid(model) then
        RequestModel(model)
        while not HasModelLoaded(model) do
            Citizen.Wait(1)
        end
    end
end)
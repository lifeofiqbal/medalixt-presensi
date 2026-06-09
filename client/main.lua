---============================================================
---  medalixt_presensi | client/main.lua
---  Ultra-optimized: render thread hanya spawn saat ALT ditekan,
---  langsung mati saat dilepas. Idle = 0 CPU.
---============================================================

-- ============================================================
--  LOCAL STATE
-- ============================================================

---@type {isNew: boolean, totalMinutes: number}
local myData  = { isNew = false, totalMinutes = 0 }

---@type table<number, boolean>  serverId -> isNew
local statusMap = {}

local myId  = nil   -- cache server ID (tidak berubah selama sesi)
local myTag = nil   -- cache {text, r, g, b, a}

-- Flag: apakah render thread sedang hidup?
local rendering = false

-- ============================================================
--  SERVER SYNC EVENTS
-- ============================================================

RegisterNetEvent('medalixt_presensi:client:syncMap', function(map)
    statusMap = {}
    for k, v in pairs(map) do
        statusMap[tonumber(k)] = v
    end
    myTag = nil
end)

RegisterNetEvent('medalixt_presensi:client:setMyData', function(data)
    myData = data
    myTag  = nil
end)

-- ============================================================
--  DRAW HELPER
-- ============================================================

local function DrawText3d(x, y, z, text, r, g, b, a)
    local onScreen, sx, sy = World3dToScreen2d(x, y, z)
    if not onScreen then return end

    local dist  = #(vector3(x, y, z) - GetGameplayCamCoords())
    local scale = (1 / dist) * 2.5 * ((1 / GetGameplayCamFov()) * 100)

    SetTextScale(0.0, scale)
    SetTextFont(4)
    SetTextProportional(1)
    SetTextColour(r, g, b, a)
    SetTextOutline()
    SetTextEntry('STRING')
    SetTextCentre(true)
    AddTextComponentString(text)
    DrawText(sx, sy)
end

-- ============================================================
--  RENDER FUNCTION  (dipanggil hanya dari dalam render thread)
-- ============================================================

local function doRender()
    -- Cache ID sendiri 1x per sesi
    if not myId then
        myId  = GetPlayerServerId(PlayerId())
        myTag = nil
    end

    -- Cache tag string 1x, rebuild hanya saat data berubah
    if not myTag then
        if myData.isNew then
            myTag = { text = '[NEW] - ' .. myId, r = 0,   g = 204, b = 0,   a = 220 }
        else
            myTag = { text = tostring(myId),      r = 255, g = 255, b = 255, a = 220 }
        end
    end

    local myPed      = PlayerPedId()
    local mx, my, mz = table.unpack(GetEntityCoords(myPed))
    local myCoords   = vector3(mx, my, mz)
    local myPid      = PlayerId()

    DrawText3d(mx, my, mz + 1.25, myTag.text, myTag.r, myTag.g, myTag.b, myTag.a)

    for _, pid in ipairs(GetActivePlayers()) do
        if pid ~= myPid then
            local coords = GetEntityCoords(GetPlayerPed(pid))
            if #(coords - myCoords) <= 2.0 then
                local sid        = GetPlayerServerId(pid)
                local ox, oy, oz = table.unpack(coords)
                if statusMap[sid] then
                    DrawText3d(ox, oy, oz + 1.08, '[NEW] - ' .. sid, 0, 204, 0, 200)
                else
                    DrawText3d(ox, oy, oz + 1.08, tostring(sid), 255, 255, 255, 180)
                end
            end
        end
    end
end

-- ============================================================
--  INPUT THREAD  (satu-satunya thread yang selalu jalan)
--  Wait(200) saat idle — hampir nol di resource monitor.
--  Spawn render thread saat ALT mulai ditekan.
--  Render thread bunuh diri saat ALT dilepas.
-- ============================================================

local ALT_KEY = 19  -- Left ALT

CreateThread(function()
    while true do
        -- Tunggu sampai ALT ditekan (polling lambat = ringan)
        if IsControlPressed(0, ALT_KEY) then
            -- Fetch map 1x sebelum render dimulai
            local map = lib.callback.await('medalixt_presensi:server:getMap', false)
            if map then
                statusMap = {}
                for k, v in pairs(map) do
                    statusMap[tonumber(k)] = v
                end
                myTag = nil
            end

            -- Spawn render thread hanya saat dibutuhkan
            if not rendering then
                rendering = true
                CreateThread(function()
                    while IsControlPressed(0, ALT_KEY) do
                        doRender()
                        Citizen.Wait(0)
                    end
                    -- ALT dilepas: thread langsung mati
                    rendering = false
                end)
            end

            -- Input thread tidur selama ALT masih ditekan
            -- (render thread yang handle, bukan ini)
            while IsControlPressed(0, ALT_KEY) do
                Citizen.Wait(50)
            end
        end

        Citizen.Wait(200)   -- idle: sangat ringan, hampir tidak terdeteksi
    end
end)

-- ============================================================
--  INITIAL LOAD
-- ============================================================

AddEventHandler('QBCore:Client:OnPlayerLoaded', function()
    myId  = nil
    myTag = nil
    SetTimeout(2000, function()
        local map = lib.callback.await('medalixt_presensi:server:getMap', false)
        if map then
            statusMap = {}
            for k, v in pairs(map) do
                statusMap[tonumber(k)] = v
            end
        end
    end)
end)

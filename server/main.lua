---============================================================
---  medalixt_presensi | server/main.lua
---  Login/logout recorder + broadcast newStatus ke semua client
---============================================================

local QBX = exports['qbx_core']

-- ============================================================
--  DATABASE SETUP
-- ============================================================

CreateThread(function()
    MySQL.query([[
        CREATE TABLE IF NOT EXISTS `medalixt_presensi` (
            `id`              INT           NOT NULL AUTO_INCREMENT,
            `citizenid`       VARCHAR(50)   NOT NULL,
            `name`            VARCHAR(100)  NOT NULL DEFAULT '',
            `login_time`      DATETIME      NOT NULL,
            `logout_time`     DATETIME      DEFAULT NULL,
            `session_minutes` INT           DEFAULT NULL,
            PRIMARY KEY (`id`),
            INDEX `idx_citizenid` (`citizenid`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ]])
    print(('[medalixt_presensi] Table ready.'))
end)

-- ============================================================
--  IN-MEMORY STATE
-- ============================================================

---@type table<number, {citizenid:string, sessionId:number, loginTimestamp:number}>
local activeSessions = {}

--- serverId -> isNew (boolean) — sumber kebenaran untuk semua client
---@type table<number, boolean>
local newStatusMap = {}

-- ============================================================
--  HELPERS
-- ============================================================

local function getTotalPlaytime(citizenid)
    local result = MySQL.scalar.await(
        'SELECT COALESCE(SUM(session_minutes), 0) FROM `medalixt_presensi` WHERE citizenid = ?',
        { citizenid }
    )
    return tonumber(result) or 0
end

local function isNewPlayer(citizenid)
    return getTotalPlaytime(citizenid) < Config.NewPlayerThreshold
end

--- Broadcast seluruh newStatusMap ke semua client sekaligus
local function broadcastStatusMap()
    TriggerClientEvent('medalixt_presensi:client:syncMap', -1, newStatusMap)
end

-- ============================================================
--  PLAYER LOAD
-- ============================================================

AddEventHandler('QBCore:Server:PlayerLoaded', function(player)
    local src        = player.PlayerData.source
    local citizenid  = player.PlayerData.citizenid
    local charName   = ('%s %s'):format(
        player.PlayerData.charinfo.firstname,
        player.PlayerData.charinfo.lastname
    )

    local insertId = MySQL.insert.await(
        'INSERT INTO `medalixt_presensi` (citizenid, name, login_time) VALUES (?, ?, NOW())',
        { citizenid, charName }
    )

    activeSessions[src] = {
        citizenid      = citizenid,
        sessionId      = insertId,
        loginTimestamp = os.time(),
    }

    local isNew = isNewPlayer(citizenid)
    newStatusMap[src] = isNew

    print(('[medalixt_presensi] Loaded: %s | src: %d | isNew: %s'):format(citizenid, src, tostring(isNew)))

    -- Kirim map terbaru ke semua client
    broadcastStatusMap()

    -- Kirim data personal ke player ini saja
    TriggerClientEvent('medalixt_presensi:client:setMyData', src, {
        isNew        = isNew,
        totalMinutes = getTotalPlaytime(citizenid),
    })
end)

-- ============================================================
--  PLAYER QUIT
-- ============================================================

local function handlePlayerQuit(src)
    local session = activeSessions[src]
    if not session then return end

    activeSessions[src] = nil
    newStatusMap[src]   = nil

    local sessionMins = math.max(1, math.floor((os.time() - session.loginTimestamp) / 60))

    MySQL.update(
        'UPDATE `medalixt_presensi` SET logout_time = NOW(), session_minutes = ? WHERE id = ?',
        { sessionMins, session.sessionId }
    )

    print(('[medalixt_presensi] Quit: %s | duration: %d min'):format(session.citizenid, sessionMins))

    -- Broadcast map yang sudah diupdate (player ini sudah dihapus)
    broadcastStatusMap()
end

AddEventHandler('playerDropped', function() handlePlayerQuit(source) end)
AddEventHandler('QBCore:Server:OnPlayerUnload', function(src) handlePlayerQuit(src) end)

-- ============================================================
--  CALLBACK – client minta sync ulang (misal baru connect)
-- ============================================================

lib.callback.register('medalixt_presensi:server:getMap', function(source)
    return newStatusMap
end)

-- ============================================================
--  COMMANDS
-- ============================================================

lib.addCommand('playtime', {
    help = 'Lihat total playtime kamu',
}, function(source)
    local player = QBX:GetPlayer(source)
    if not player then return end
    local total = getTotalPlaytime(player.PlayerData.citizenid)
    TriggerClientEvent('ox_lib:notify', source, {
        title       = 'Playtime Kamu',
        description = ('Total: %dh %dm'):format(math.floor(total / 60), total % 60),
        type        = 'info',
        duration    = 5000,
    })
end)

lib.addCommand('cekpresensi', {
    help   = 'Cek total playtime player (admin only)',
    params = { { name = 'id', type = 'playerId', help = 'Server ID target' } },
    restricted = 'group.admin',
}, function(source, args)
    local target = QBX:GetPlayer(args.id)
    if not target then
        TriggerClientEvent('ox_lib:notify', source, { title = 'Error', description = 'Player tidak ditemukan.', type = 'error' })
        return
    end
    local total  = getTotalPlaytime(target.PlayerData.citizenid)
    local isNew  = (newStatusMap[args.id] == true)
    TriggerClientEvent('ox_lib:notify', source, {
        title       = ('Presensi: %s %s'):format(target.PlayerData.charinfo.firstname, target.PlayerData.charinfo.lastname),
        description = ('Total: %dh %dm | Status: %s'):format(math.floor(total/60), total%60, isNew and '[NEW]' or 'Veteran'),
        type        = 'info',
        duration    = 8000,
    })
end)

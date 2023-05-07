function WalkMenuStart(name)
    if Config.PersistentWalk then SetResourceKvp("walkstyle", name) end
    RequestWalking(name)
    SetPedMovementClipset(PlayerPedId(), name, 0.2)
    RemoveAnimSet(name)
end

function RequestWalking(set)
    local timeout = GetGameTimer() + 5000
    while not HasAnimSetLoaded(set) and GetGameTimer() < timeout do
        RequestAnimSet(set)
        Wait(5)
    end
end

function WalksOnCommand(source, args, raw)
    local WalksCommand = ""
    for a in pairsByKeys(RP.Walks) do
        WalksCommand = WalksCommand .. "" .. string.lower(a) .. ", "
    end
    EmoteChatMessage(WalksCommand)
    EmoteChatMessage("To reset do /walk reset")
end

function WalkCommandStart(source, args, raw)
    local name = firstToUpper(string.lower(args[1]))

    if name == "Reset" then
        ResetPedMovementClipset(PlayerPedId())
        return
    end

    if tableHasKey(RP.Walks, name) then
        local name2 = table.unpack(RP.Walks[name])
        WalkMenuStart(name2)
    elseif name == "Injured" then
        WalkMenuStart("move_m@injured")
    else
        EmoteChatMessage("'" .. name .. "' is not a valid walk")
    end
end

function tableHasKey(table, key)
    return table[key] ~= nil
end

if Config.WalkingStylesEnabled and Config.PersistentWalk then
    AddEventHandler('playerSpawned', function()
        local kvp = GetResourceKvpString("walkstyle")

        if kvp ~= nil then
            WalkMenuStart(kvp)
        end
    end)
end

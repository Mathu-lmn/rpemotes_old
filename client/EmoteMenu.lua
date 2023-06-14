local rightPosition = { x = 1450, y = 100 }
local leftPosition = { x = 0, y = 100 }
local menuPosition = { x = 0, y = 200 }
local clonedPosition = { x = 0, y = 0}
local clonedPed = nil
local clonedBDog = nil
local clonedSDog = nil
local clonedPed2 = nil

if GetAspectRatio() > 2.0 then
    rightPosition = { x = 1200, y = 100 }
    leftPosition = { x = -250, y = 100 }
end

if Config.MenuPosition then
    if Config.MenuPosition == "left" then
        menuPosition = leftPosition
        clonedPosition.x = 0.33
        clonedPosition.y = 0.2
    elseif Config.MenuPosition == "right" then
        menuPosition = rightPosition
        clonedPosition.x = 0.66
        clonedPosition.y = 0.2
    end
end

if Config.CustomMenuEnabled then
    local RuntimeTXD = CreateRuntimeTxd('Custom_Menu_Head')
    local Object = CreateDui(Config.MenuImage, 512, 128)
    _G.Object = Object
    local TextureThing = GetDuiHandle(Object)
    local Texture = CreateRuntimeTextureFromDuiHandle(RuntimeTXD, 'Custom_Menu_Head', TextureThing)
    Menuthing = "Custom_Menu_Head"
else
    Menuthing = "shopui_title_sm_hangar"
end

_menuPool = NativeUI.CreatePool()
mainMenu = NativeUI.CreateMenu(Config.MenuTitle or "", "", menuPosition["x"], menuPosition["y"], Menuthing, Menuthing)
_menuPool:Add(mainMenu)

local EmoteTable = {}
local FavEmoteTable = {}
local DanceTable = {}
local AnimalTable = {}
local PropETable = {}
local WalkTable = {}
local FaceTable = {}
local ShareTable = {}
local FavoriteEmote = ""

if Config.FavKeybindEnabled then
    RegisterCommand('emotefav', function() FavKeybind() end)
    RegisterKeyMapping("emotefav", "Execute your favorite emote", "keyboard", Config.FavKeybind)

    local doingFavoriteEmote = false

    function FavKeybind()
        if doingFavoriteEmote == false then
            doingFavoriteEmote = true
            if not IsPedSittingInAnyVehicle(PlayerPedId()) then
                if FavoriteEmote ~= "" and (not CanUseFavKeyBind or CanUseFavKeyBind()) then
                    EmoteCommandStart(nil, { FavoriteEmote, 0 })
                    Wait(500)
                end
            end
        else
            EmoteCancel()
            doingFavoriteEmote = false
        end
    end
end

lang = Config.MenuLanguage

function AddEmoteMenu(menu)
    local submenu = _menuPool:AddSubMenu(menu, Config.Languages[lang]['emotes'], "", "", Menuthing, Menuthing)
    if Config.Search then
        submenu:AddItem(NativeUI.CreateItem(Config.Languages[lang]['searchemotes'], ""))
        table.insert(EmoteTable, Config.Languages[lang]['searchemotes'])
    end
    local dancemenu = _menuPool:AddSubMenu(submenu, Config.Languages[lang]['danceemotes'], "", "", Menuthing, Menuthing)
    local animalmenu
    if Config.AnimalEmotesEnabled then
        animalmenu = _menuPool:AddSubMenu(submenu, Config.Languages[lang]['animalemotes'], "", "", Menuthing, Menuthing)
        table.insert(EmoteTable, Config.Languages[lang]['animalemotes'])
    end
    local propmenu = _menuPool:AddSubMenu(submenu, Config.Languages[lang]['propemotes'], "", "", Menuthing, Menuthing)
    table.insert(EmoteTable, Config.Languages[lang]['danceemotes'])
    table.insert(EmoteTable, Config.Languages[lang]['danceemotes'])

    if Config.SharedEmotesEnabled then
        sharemenu = _menuPool:AddSubMenu(submenu, Config.Languages[lang]['shareemotes'],
            Config.Languages[lang]['shareemotesinfo'], "", Menuthing, Menuthing)
        shareddancemenu = _menuPool:AddSubMenu(sharemenu, Config.Languages[lang]['sharedanceemotes'], "", "", Menuthing,
            Menuthing)
        table.insert(ShareTable, 'none')
        table.insert(EmoteTable, Config.Languages[lang]['shareemotes'])
    end

    -- Temp var to be able to sort every emotes in the fav list
    local favEmotes = {}
    if not Config.SqlKeybinding then
        unbind2item = NativeUI.CreateItem(Config.Languages[lang]['rfavorite'], Config.Languages[lang]['rfavorite'])
        unbinditem = NativeUI.CreateItem(Config.Languages[lang]['prop2info'], "")
        favmenu = _menuPool:AddSubMenu(submenu, Config.Languages[lang]['favoriteemotes'],
            Config.Languages[lang]['favoriteinfo'], "", Menuthing, Menuthing)
        favmenu:AddItem(unbinditem)
        favmenu:AddItem(unbind2item)
        -- Add two elements as offset
        table.insert(FavEmoteTable, Config.Languages[lang]['rfavorite'])
        table.insert(FavEmoteTable, Config.Languages[lang]['rfavorite'])
        table.insert(EmoteTable, Config.Languages[lang]['favoriteemotes'])
    else
        table.insert(EmoteTable, "keybinds")
        keyinfo = NativeUI.CreateItem(Config.Languages[lang]['keybinds'],
            Config.Languages[lang]['keybindsinfo'] .. " /emotebind [~y~num4-9~w~] [~g~emotename~w~]")
        submenu:AddItem(keyinfo)
    end

    for a, b in pairsByKeys(RP.Emotes) do
        x, y, z = table.unpack(b)
        emoteitem = NativeUI.CreateItem(z, "/e (" .. a .. ")")
        submenu:AddItem(emoteitem)
        table.insert(EmoteTable, a)
        if not Config.SqlKeybinding then
            favEmotes[a] = z
        end
    end

    for a, b in pairsByKeys(RP.Dances) do
        x, y, z = table.unpack(b)
        danceitem = NativeUI.CreateItem(z, "/e (" .. a .. ")")
        dancemenu:AddItem(danceitem)
        if Config.SharedEmotesEnabled then
            sharedanceitem = NativeUI.CreateItem(z, "/nearby (" .. a .. ")")
            shareddancemenu:AddItem(sharedanceitem)
        end
        table.insert(DanceTable, a)
        if not Config.SqlKeybinding then
            favEmotes[a] = z
        end
    end

    if Config.AnimalEmotesEnabled then
        for a, b in pairsByKeys(RP.AnimalEmotes) do
            x, y, z = table.unpack(b)
            animalitem = NativeUI.CreateItem(z, "/e (" .. a .. ")")
            animalmenu:AddItem(animalitem)
            table.insert(AnimalTable, a)
            if not Config.SqlKeybinding then
                favEmotes[a] = z
            end
        end
    end

    if Config.SharedEmotesEnabled then
        for a, b in pairsByKeys(RP.Shared) do
            x, y, z, otheremotename = table.unpack(b)
            if otheremotename == nil then
                shareitem = NativeUI.CreateItem(z, "/nearby (~g~" .. a .. "~w~)")
            else
                shareitem = NativeUI.CreateItem(z,
                    "/nearby (~g~" ..
                    a .. "~w~) " .. Config.Languages[lang]['makenearby'] .. " (~y~" .. otheremotename .. "~w~)")
            end
            sharemenu:AddItem(shareitem)
            table.insert(ShareTable, a)
        end
    end

    for a, b in pairsByKeys(RP.PropEmotes) do
        x, y, z = table.unpack(b)

        if b.AnimationOptions.PropTextureVariations then
            propitem = NativeUI.CreateListItem(z, b.AnimationOptions.PropTextureVariations, 1, "/e (" .. a .. ")")
            propmenu:AddItem(propitem)
        else
            propitem = NativeUI.CreateItem(z, "/e (" .. a .. ")")
            propmenu:AddItem(propitem)
        end

        table.insert(PropETable, a)
        if not Config.SqlKeybinding then
            favEmotes[a] = z
        end
    end

    if not Config.SqlKeybinding then
        -- Add the emotes to the fav menu
        for emoteName, emoteLabel in pairsByKeys(favEmotes) do
            favemoteitem = NativeUI.CreateItem(emoteLabel,
                Config.Languages[lang]['set'] .. emoteLabel .. Config.Languages[lang]['setboundemote'])
            favmenu:AddItem(favemoteitem)
            table.insert(FavEmoteTable, emoteName)
        end

        favmenu.OnItemSelect = function(sender, item, index)
            if FavEmoteTable[index] == Config.Languages[lang]['rfavorite'] then
                FavoriteEmote = ""
                ShowNotification(Config.Languages[lang]['rfavorite'], 2000)
                return
            end
            if Config.FavKeybindEnabled then
                FavoriteEmote = FavEmoteTable[index]
                ShowNotification("~o~" .. firstToUpper(FavoriteEmote) .. Config.Languages[lang]['newsetemote'])
            end
        end
    end
    favEmotes = nil

    dancemenu.OnItemSelect = function(sender, item, index)
        EmoteMenuStart(DanceTable[index], "dances")
    end

    if Config.EmotePreview then
        dancemenu.OnIndexChange = function(menu, newindex)
            -- play the emote on ClonedPed
            PlayCloneEmote(DanceTable[newindex], "dances")
        end

        dancemenu.OnMenuClosed = function(menu, index)
            -- stop the emote on ClonedPed
            ClearPedTasksImmediately(ClonedPed)
            SetEntityAlpha(clonedPed, 0, false)
            SetEntityAlpha(clonedBDog, 0, false)
            SetEntityAlpha(clonedSDog, 0, false)
        end
    end

    if Config.AnimalEmotesEnabled then
        animalmenu.OnItemSelect = function(sender, item, index)
            EmoteMenuStart(AnimalTable[index], "animals")
        end

        animalmenu.OnIndexChange = function(menu, newindex)
            -- play the emote on ClonedPed
            ClearPedTasksImmediately(ClonedPed)
            ClearPedTasksImmediately(clonedBDog)
            ClearPedTasksImmediately(clonedSDog)
            SetEntityAlpha(clonedBDog, 0, false)
            SetEntityAlpha(clonedSDog, 0, false)
            DestroyAllCloneProps()
            PlayCloneEmote(AnimalTable[newindex], "animals")
        end

        animalmenu.OnMenuClosed = function(menu, index)
            -- stop the emote on ClonedPed
            ClearPedTasksImmediately(ClonedPed)
            ClearPedTasksImmediately(clonedBDog)
            ClearPedTasksImmediately(clonedSDog)
            SetEntityAlpha(clonedPed, 0, false)
            SetEntityAlpha(clonedBDog, 0, false)
            SetEntityAlpha(clonedSDog, 0, false)
            DestroyAllCloneProps()
        end
    end

    if Config.SharedEmotesEnabled then
        sharemenu.OnItemSelect = function(sender, item, index)
            if ShareTable[index] ~= 'none' then
                target, distance = GetClosestPlayer()
                if (distance ~= -1 and distance < 3) then
                    _, _, rename = table.unpack(RP.Shared[ShareTable[index]])
                    TriggerServerEvent("ServerEmoteRequest", GetPlayerServerId(target), ShareTable[index])
                    SimpleNotify(Config.Languages[lang]['sentrequestto'] .. GetPlayerName(target))
                else
                    SimpleNotify(Config.Languages[lang]['nobodyclose'])
                end
            end
        end

        shareddancemenu.OnItemSelect = function(sender, item, index)
            target, distance = GetClosestPlayer()
            if (distance ~= -1 and distance < 3) then
                _, _, rename = table.unpack(RP.Dances[DanceTable[index]])
                TriggerServerEvent("ServerEmoteRequest", GetPlayerServerId(target), DanceTable[index], 'Dances')
                SimpleNotify(Config.Languages[lang]['sentrequestto'] .. GetPlayerName(target))
            else
                SimpleNotify(Config.Languages[lang]['nobodyclose'])
            end
        end

        if Config.EmotePreview then
            sharemenu.OnIndexChange = function(menu, newindex)
                -- play the emote on ClonedPed
                if newindex == 1 then
                    ClearPedTasksImmediately(clonedPed)
                    SetEntityAlpha(clonedPed, 0, false)
                    SetEntityAlpha(clonedBDog, 0, false)
                    SetEntityAlpha(clonedSDog, 0, false)
                    if clonedPed2 ~= nil then
                        DeleteEntity(clonedPed2)
                        clonedPed2 = nil
                    end
                    return
                end
                if clonedPed2 ~= nil then
                    DeleteEntity(clonedPed2)
                    clonedPed2 = nil
                end
                PlayCloneEmote(ShareTable[newindex], "shared")
            end

            shareddancemenu.OnIndexChange = function(menu, newindex)
                -- play the emote on ClonedPed
                if clonedPed2 ~= nil then
                    DeleteEntity(clonedPed2)
                    clonedPed2 = nil
                end
                PlayCloneEmote(DanceTable[newindex], "shared")
            end

            sharemenu.OnMenuClosed = function(menu)
                ClearPedTasksImmediately(clonedPed)
                SetEntityAlpha(clonedPed, 0, false)
                SetEntityAlpha(clonedBDog, 0, false)
                SetEntityAlpha(clonedSDog, 0, false)
                if clonedPed2 ~= nil then
                    DeleteEntity(clonedPed2)
                    clonedPed2 = nil
                end
            end

            shareddancemenu.OnMenuClosed = function(menu)
                ClearPedTasksImmediately(clonedPed)
                SetEntityAlpha(clonedPed, 0, false)
                SetEntityAlpha(clonedBDog, 0, false)
                SetEntityAlpha(clonedSDog, 0, false)
                if clonedPed2 ~= nil then
                    DeleteEntity(clonedPed2)
                    clonedPed2 = nil
                end
            end
        end
    end

    propmenu.OnItemSelect = function(sender, item, index)
        EmoteMenuStart(PropETable[index], "props")
    end

    if Config.EmotePreview then
        propmenu.OnIndexChange = function(menu, newindex)
            -- play the emote on ClonedPed
            PlayCloneEmote(PropETable[newindex], "props")
        end

        propmenu.OnMenuClosed = function(menu)
            -- stop the emote on ClonedPed
            ClearPedTasksImmediately(clonedPed)
            SetEntityAlpha(clonedPed, 0, false)
            SetEntityAlpha(clonedBDog, 0, false)
            SetEntityAlpha(clonedSDog, 0, false)
            DestroyAllCloneProps()
        end
    end

   propmenu.OnListSelect = function(menu, item, itemIndex, listIndex)
        EmoteMenuStart(PropETable[itemIndex], "props", item:IndexToItem(listIndex).Value)
    end

    submenu.OnItemSelect = function(sender, item, index)
        if Config.Search and EmoteTable[index] == Config.Languages[lang]['searchemotes'] then
            EmoteMenuSearch(submenu)
        elseif EmoteTable[index] ~= Config.Languages[lang]['favoriteemotes'] then
            EmoteMenuStart(EmoteTable[index], "emotes")
        end
    end
    if Config.EmotePreview then
        submenu.OnIndexChange = function(menu, newindex)
            if EmoteTable[newindex] == Config.Languages[lang]['favoriteemotes'] or EmoteTable[newindex] == Config.Languages[lang]['searchemotes'] then
                ClearPedTasks(clonedPed)
                SetEntityAlpha(clonedPed, 0, false)
                SetEntityAlpha(clonedBDog, 0, false)
                SetEntityAlpha(clonedSDog, 0, false)
                DestroyAllCloneProps()
            else
                PlayCloneEmote(EmoteTable[newindex], "emotes")
            end
        end

        submenu.OnMenuClosed = function(menu)
            ClearPedTasksImmediately(clonedPed)
            SetEntityAlpha(clonedPed, 0, false)
            SetEntityAlpha(clonedBDog, 0, false)
            SetEntityAlpha(clonedSDog, 0, false)
            DestroyAllCloneProps()
        end
    end
end

if Config.Search then
    local ignoredCategories = {
        ["Walks"] = true,
        ["Expressions"] = true,
        ["Shared"] = not Config.SharedEmotesEnabled
    }

    function EmoteMenuSearch(lastMenu)
        local favEnabled = not Config.SqlKeybinding and Config.FavKeybindEnabled
        AddTextEntry("PM_NAME_CHALL", Config.Languages[lang]['searchinputtitle'])
        DisplayOnscreenKeyboard(1, "PM_NAME_CHALL", "", "", "", "", "", 30)
        while UpdateOnscreenKeyboard() == 0 do
            DisableAllControlActions(0)
            Wait(100)
        end
        local input = GetOnscreenKeyboardResult()
        if input ~= nil then
            local results = {}
            for k, v in pairs(RP) do
                if not ignoredCategories[k] then
                    for a, b in pairs(v) do
                        if string.find(string.lower(a), string.lower(input)) or (b[3] ~= nil and string.find(string.lower(b[3]), string.lower(input))) then
                            table.insert(results, {table = k, name = a, data = b})
                        end
                    end
                end
            end

            if #results > 0 then
                local searchMenu = _menuPool:AddSubMenu(lastMenu, string.format(Config.Languages[lang]['searchmenudesc'], #results, input), "", true, Menuthing, Menuthing)
                local sharedDanceMenu
                if favEnabled then
                    local rFavorite = NativeUI.CreateItem(Config.Languages[lang]['rfavorite'], Config.Languages[lang]['rfavorite'])
                    searchMenu:AddItem(rFavorite)
                end

                if Config.SharedEmotesEnabled then
                    sharedDanceMenu = _menuPool:AddSubMenu(searchMenu, Config.Languages[lang]['sharedanceemotes'], "", true, Menuthing, Menuthing)
                end

                table.sort(results, function(a, b) return a.name < b.name end)
                for k, v in pairs(results) do
                    local desc = ""
                    if v.table == "Shared" then
                        local otheremotename = v.data[4]
                        if otheremotename == nil then
                           desc = "/nearby (~g~" .. v.name .. "~w~)"
                        else
                           desc = "/nearby (~g~" .. v.name .. "~w~) " .. Config.Languages[lang]['makenearby'] .. " (~y~" .. otheremotename .. "~w~)"
                        end
                    else
                        desc = "/e (" .. v.name .. ")" .. (favEnabled and "\n" .. Config.Languages[lang]['searchshifttofav'] or "")
                    end

                    if v.data.AnimationOptions and v.data.AnimationOptions.PropTextureVariations then
                        local item = NativeUI.CreateListItem(v.data[3], v.data.AnimationOptions.PropTextureVariations, 1, desc)
                        searchMenu:AddItem(item)
                    else
                        local item = NativeUI.CreateItem(v.data[3], desc)
                        searchMenu:AddItem(item)
                    end

                    if v.table == "Dances" and Config.SharedEmotesEnabled then
                        local item2 = NativeUI.CreateItem(v.data[3], "")
                        sharedDanceMenu:AddItem(item2)
                    end
                end

                if favEnabled then
                    table.insert(results, 1, Config.Languages[lang]['rfavorite'])
                end

                searchMenu.OnItemSelect = function(sender, item, index)
                    local data = results[index]

                    if data == Config.Languages[lang]['sharedanceemotes'] then return end
                    if data == Config.Languages[lang]['rfavorite'] then
                        FavoriteEmote = ""
                        ShowNotification(Config.Languages[lang]['rfavorite'], 2000)
                        return
                    end

                    if favEnabled and IsControlPressed(0, 21) then
                        if data.table ~= "Shared" then
                            FavoriteEmote = data.name
                            ShowNotification("~o~" .. firstToUpper(data.name) .. Config.Languages[lang]['newsetemote'])
                        else
                            SimpleNotify(Config.Languages[lang]['searchcantsetfav'])
                        end
                    elseif data.table == "Emotes" or data.table == "Dances" then
                        EmoteMenuStart(data.name, string.lower(data.table))
                    elseif data.table == "PropEmotes" then
                        EmoteMenuStart(data.name, "props")
                    elseif data.table == "AnimalEmotes" then
                        EmoteMenuStart(data.name, "animals")
                    elseif data.table == "Shared" then
                        target, distance = GetClosestPlayer()
                        if (distance ~= -1 and distance < 3) then
                            _, _, rename = table.unpack(RP.Shared[data.name])
                            TriggerServerEvent("ServerEmoteRequest", GetPlayerServerId(target), data.name)
                            SimpleNotify(Config.Languages[lang]['sentrequestto'] .. GetPlayerName(target))
                        else
                            SimpleNotify(Config.Languages[lang]['nobodyclose'])
                        end
                    end
                end

                searchMenu.OnListSelect = function(menu, item, itemIndex, listIndex)
                    EmoteMenuStart(results[itemIndex].name, "props", item:IndexToItem(listIndex).Value)
                end

                if Config.SharedEmotesEnabled then
                    if #sharedDanceMenu.Items > 0 then
                        table.insert(results, (favEnabled and 2 or 1), Config.Languages[lang]['sharedanceemotes'])
                        sharedDanceMenu.OnItemSelect = function(sender, item, index)
                            local data = results[index]
                            target, distance = GetClosestPlayer()
                            if (distance ~= -1 and distance < 3) then
                                _, _, rename = table.unpack(RP.Dances[data.name])
                                TriggerServerEvent("ServerEmoteRequest", GetPlayerServerId(target), data.name, 'Dances')
                                SimpleNotify(Config.Languages[lang]['sentrequestto'] .. GetPlayerName(target))
                            else
                                SimpleNotify(Config.Languages[lang]['nobodyclose'])
                            end
                        end
                    else
                        sharedDanceMenu:Clear()
                        searchMenu:RemoveItemAt((favEnabled and 2 or 1))
                    end
                end

                searchMenu.OnMenuClosed = function()
                    searchMenu:Clear()
                    lastMenu:RemoveItemAt(#lastMenu.Items)
                    _menuPool:RefreshIndex()
                    results = {}
                end

                _menuPool:RefreshIndex()
                _menuPool:CloseAllMenus()
                searchMenu:Visible(true)
            else
                SimpleNotify(string.format(Config.Languages[lang]['searchnoresult'], input))
            end
        end
    end
end

function AddCancelEmote(menu)
    local newitem = NativeUI.CreateItem(Config.Languages[lang]['cancelemote'], Config.Languages[lang]['cancelemoteinfo'])
    menu:AddItem(newitem)
    menu.OnItemSelect = function(sender, item, checked_)
        if item == newitem then
            EmoteCancel()
            DestroyAllProps()
        end
    end
end

function AddWalkMenu(menu)
    local submenu = _menuPool:AddSubMenu(menu, Config.Languages[lang]['walkingstyles'], "", "", Menuthing, Menuthing)

    walkreset = NativeUI.CreateItem(Config.Languages[lang]['normalreset'], Config.Languages[lang]['resetdef'])
    submenu:AddItem(walkreset)
    table.insert(WalkTable, Config.Languages[lang]['resetdef'])

    -- This one is added here to be at the top of the list.
    WalkInjured = NativeUI.CreateItem("Injured", "/walk (injured)")
    submenu:AddItem(WalkInjured)
    table.insert(WalkTable, "move_m@injured")

    for a, b in pairsByKeys(RP.Walks) do
        x, label = table.unpack(b)
        walkitem = NativeUI.CreateItem(label or a, "/walk (" .. string.lower(a) .. ")")
        submenu:AddItem(walkitem)
        table.insert(WalkTable, x)
    end

    submenu.OnItemSelect = function(sender, item, index)
        if item ~= walkreset then
            WalkMenuStart(WalkTable[index])
        else
            ResetWalk()
            DeleteResourceKvp("walkstyle")
        end
    end
    if Config.EmotePreview then
        submenu.OnIndexChange = function(sender, index)
            -- make the cloned ped walk with a specific walkstyle (freeze position)
            if index ~= 1 then
                SetEntityAlpha(clonedPed, 230, false)
                FreezeEntityPosition(clonedPed, true)
                RequestWalking(WalkTable[index])
                SetPedMovementClipset(clonedPed, WalkTable[index], 0.0)
                RemoveAnimSet(WalkTable[index])
                local coordsInFront = GetOffsetFromEntityInWorldCoords(clonedPed, 0.0, 100.0, 0.0)
                TaskGoStraightToCoord(clonedPed, coordsInFront, 1.0, -1, GetEntityHeading(clonedPed), 0.0)
            else
                SetEntityAlpha(clonedPed, 230, false)
                ResetPedMovementClipset(clonedPed)
            end
        end

        -- on menu closed, reset walkstyle
        submenu.OnMenuClosed = function()
            ResetPedMovementClipset(clonedPed)
            ClearPedTasksImmediately(clonedPed)
            SetEntityAlpha(clonedPed, 0, false)
            SetEntityAlpha(clonedBDog, 0, false)
            SetEntityAlpha(clonedSDog, 0, false)
        end
    end
end

function AddFaceMenu(menu)
    local submenu = _menuPool:AddSubMenu(menu, Config.Languages[lang]['moods'], "", "", Menuthing, Menuthing)

    local facereset = NativeUI.CreateItem(Config.Languages[lang]['normalreset'], Config.Languages[lang]['resetdef'])
    submenu:AddItem(facereset)
    table.insert(FaceTable, "")

    for name, data in pairsByKeys(RP.Expressions) do
        local faceitem = NativeUI.CreateItem(data[2] or name, "")
        submenu:AddItem(faceitem)
        table.insert(FaceTable, name)
    end

    submenu.OnItemSelect = function(sender, item, index)
        if item ~= facereset then
            EmoteMenuStart(FaceTable[index], "expression")
        else
            ClearFacialIdleAnimOverride(PlayerPedId())
        end
    end
    if Config.EmotePreview then
        submenu.OnIndexChange = function(sender, index)
            if index ~= 1 then
                SetEntityAlpha(clonedPed, 230, false)
                SetFacialIdleAnimOverride(clonedPed, RP.Expressions[FaceTable[index]][1])
            else
                SetEntityAlpha(clonedPed, 230, false)
                ClearFacialIdleAnimOverride(clonedPed)
            end
        end

        submenu.OnMenuClosed = function()
            SetEntityAlpha(clonedPed, 0, false)
            SetEntityAlpha(clonedBDog, 0, false)
            SetEntityAlpha(clonedSDog, 0, false)
            ClearFacialIdleAnimOverride(clonedPed)
        end
    end
end

function AddInfoMenu(menu)

    -- if not UpdateAvailable then
        infomenu = _menuPool:AddSubMenu(menu, Config.Languages[lang]['infoupdate'], "~h~~y~Huge Thank You ❤️~h~~y~", "",
            Menuthing, Menuthing)
    -- else
    --     infomenu = _menuPool:AddSubMenu(menu, Config.Languages[lang]['infoupdateav'],
    --         Config.Languages[lang]['infoupdateavtext'], "", Menuthing, Menuthing)
    -- end
 
    infomenu:AddItem(NativeUI.CreateItem("Join the <font color=\"#00ceff\">Discord 💬</font>",
        "Join our official discord! 💬 <font color=\"#00ceff\">https://discord.gg/sw3NwDq6C8</font>"))
    infomenu:AddItem(NativeUI.CreateItem("<font color=\"#FF25B1\">TayMcKenzieNZ 🇳🇿</font>",
        "<font color=\"#FF25B1\">TayMcKenzieNZ 🇳🇿</font> Project Manager for RPEmotes"))
    infomenu:AddItem(NativeUI.CreateItem("Thanks ~o~DullPear 🍐~s~", "~o~DullPear~s~ for the original dpemotes ❤️"))
    infomenu:AddItem(NativeUI.CreateItem("Thanks <b>Kibook 🐩</b>",
        "<b>Kibook</b> for the addition of Animal Emotes 🐩 submenu."))
    infomenu:AddItem(NativeUI.CreateItem("Thanks ~y~AvaN0x 🇫🇷~s~",
        "~y~AvaN0x~s~ 🇫🇷 for reformatting and assisting with code and additional features 🙏"))
    infomenu:AddItem(NativeUI.CreateItem("Thanks <font color=\"#0e64ed\">Mads 🤖</font>",
        "<font color=\"#0e64ed\">Mads 🤖</font> for the addition of Exit Emotes, Crouch & Crawl ⚙️"))
    infomenu:AddItem(NativeUI.CreateItem("Thanks <font color=\"#ff451d\">Mathu_lmn 🇫🇷 </font>",
        "<font color=\"#ff451d\">Mathu_lmn 🇫🇷</font>  Additional features and fixes 🛠️"))
    infomenu:AddItem(NativeUI.CreateItem("Thanks <font color=\"#1C9369\">northsqrd ⚙️</font>",
        "<font color=\"#1C9369\">northsqrd</font> for assisting with search feature and phone colours 🔎"))
    infomenu:AddItem(NativeUI.CreateItem("Thanks <font color=\"#15BCEC\">GeekGarage 🤓</font>",
        "<font color=\"#15BCEC\">GeekGarage</font> for assisting with code and features"))
    infomenu:AddItem(NativeUI.CreateItem("Thanks <font color=\"#3b8eea\">SMGMissy 🪖</font>",
        "<font color=\"#3b8eea\">SMGMissy</font> for the custom pride flags 🏳️‍🌈."))
    infomenu:AddItem(NativeUI.CreateItem("Thanks <font color=\"#a356fa\">Dollie 👧</font>",
        "<font color=\"#a356fa\">DollieMods</font> for the custom emotes 💜."))
    infomenu:AddItem(NativeUI.CreateItem("Thanks <font color=\"#ff00c3\">Tigerle 🐯</font>",
        "<font color=\"#ff00c3\">Tigerle</font> for assisting with attached Shared Emotes ⚙️."))
    infomenu:AddItem(NativeUI.CreateItem("Thanks <font color=\"#7dbf7b\">MissSnowie 🐰</font>",
        "<font color=\"#7dbf7b\">MissSnowie</font> for the custom emotes 🐇."))
    infomenu:AddItem(NativeUI.CreateItem("Thanks <font color=\"#FF6100\">Smokey 💨</font>",
        "<font color=\"#FF6100\">Smokey</font> for the custom emotes 🤙🏼."))
    infomenu:AddItem(NativeUI.CreateItem("Thanks ~b~Ultrahacx 🧑‍💻~s~",
	"~b~Ultrahacx~s~ for the custom emotes ☺️."))
    infomenu:AddItem(NativeUI.CreateItem("Thanks <font color=\"#37DA00\">BzZzi 🤭</font>",
        "<font color=\"#37DA00\">BzZzi</font> for the custom food props 🍩."))
    infomenu:AddItem(NativeUI.CreateItem("Thanks <font color=\"#C40A7D\">Natty3d 🍭</font>",
        "<font color=\"#C40A7D\">Natty3d</font> for the custom lollipop props 🍭."))
    infomenu:AddItem(NativeUI.CreateItem("Thanks <font color=\"#ff61a0\">Amnilka 🇵🇱</font>",
        "<font color=\"#ff61a0\">Amnilka</font> for the custom emotes ☺️."))
    infomenu:AddItem(NativeUI.CreateItem("Thanks <font color=\"#ff058f\">LittleSpoon 🥄</font>",
        "<font color=\"#ff058f\">LittleSpoon</font> for the custom emotes 💗."))
    infomenu:AddItem(NativeUI.CreateItem("Thanks <font color=\"#1a88c9\">Pupppy 🐶</font>",
        "<font color=\"#1a88c9\">Pupppy</font> for the custom emotes 🦴."))
    infomenu:AddItem(NativeUI.CreateItem("Thanks <font color=\"#53ba04\">SapphireMods</font>",
        "<font color=\"#53ba04\">SapphireMods</font> for the custom emotes ✨."))
    infomenu:AddItem(NativeUI.CreateItem("Thanks <font color=\"#8526f0\">QueenSisters Animations 👭</font>",
        "<font color=\"#8526f0\">QueenSistersAnimations</font> for the custom emotes 🍧"))
    infomenu:AddItem(NativeUI.CreateItem("Thanks <font color=\"#0acf52\">BoringNeptune 👽</font>",
        "<font color=\"#0acf52\">BoringNeptune</font> for the custom emotes 🕺"))
    infomenu:AddItem(NativeUI.CreateItem("Thanks <font color=\"#edae00\">Moses 🐮</font>",
        "<font color=\"#edae00\">-Moses-</font> for the custom emotes 🧡"))
    infomenu:AddItem(NativeUI.CreateItem("Thanks <font color=\"#D71196\">PataMods 🍓</font>",
        "<font color=\"#D71196\">PataMods</font> for the custom props 🍕"))
   infomenu:AddItem(NativeUI.CreateItem("Thanks <font color=\"#FB7403\">Crowded1337 👜</font>",
        "<font color=\"#FB7403\">Crowded1337</font> for the custom Gucci bag 👜"))
  infomenu:AddItem(NativeUI.CreateItem("Thanks <font color=\"#8180E5\">EnchantedBrownie 🍪</font>",
        "<font color=\"#8180E5\">EnchantedBrownie 🍪</font> for the custom animations 🍪"))
  infomenu:AddItem(NativeUI.CreateItem("Thanks <font color=\"#eb540e\">Copofiscool 🇦🇺</font>",
        "<font color=\"#eb540e\">Copofiscool</font> for the Favorite Emote keybind toggle fix 🇦🇺"))
  infomenu:AddItem(NativeUI.CreateItem("Thanks <font color=\"#40E0D0\">iSentrie </font>",
        "<font color=\"#40E0D0\">iSentrie</font> for assisting with code 🛠️"))
  infomenu:AddItem(NativeUI.CreateItem("Thanks <font color=\"#7B3F00\">Chocoholic Animations 🍫</font>",
        "<font color=\"#7B3F00\">Chocoholic Animations</font> for the custom emotes 🍫"))
  infomenu:AddItem(NativeUI.CreateItem("Thanks <font color=\"#34cf5d\">CrunchyCat 🐱</font>",
        "<font color=\"#34cf5d\">CrunchyCat 🐱</font> for the custom emotes 🐱"))
  infomenu:AddItem(NativeUI.CreateItem("Thanks <font color=\"#d10870\">KayKayMods</font>",
        "<font color=\"#d10870\">KayKayMods</font> for the custom props 🧋"))
  infomenu:AddItem(NativeUI.CreateItem("Thanks <font color=\"#de1846\">Dark Animations</font>",
        "<font color=\"#de1846\">Dark Animations</font> for the custom animations 🖤"))
  infomenu:AddItem(NativeUI.CreateItem("Thanks <font color=\"#00FF12\">Brum 🇬🇧</font>",
        "<font color=\"#00FF12\">Brum</font> for the custom props  🇬🇧"))

    infomenu:AddItem(NativeUI.CreateItem("Thanks to the community", "Translations, bug reports and moral support 🌐"))
end

function OpenEmoteMenu()
    if IsEntityDead(PlayerPedId()) then
        -- show in chat
        TriggerEvent('chat:addMessage', {
            color = {255, 0, 0},
            multiline = true,
            args = {"RPEmotes", Config.Languages[lang]['dead']}
        })
        return
    end
    if (IsPedSwimming(PlayerPedId()) or IsPedSwimmingUnderWater(PlayerPedId())) and not Config.AllowInWater then
        -- show in chat
        TriggerEvent('chat:addMessage', {
            color = {255, 0, 0},
            multiline = true,
            args = {"RPEmotes", Config.Languages[lang]['swimming']}
        })
        return
    end
    if _menuPool:IsAnyMenuOpen() then
        _menuPool:CloseAllMenus()
    else
        mainMenu:Visible(true)
        ProcessMenu()
    end
end

AddEmoteMenu(mainMenu)
AddCancelEmote(mainMenu)
if Config.WalkingStylesEnabled then
    AddWalkMenu(mainMenu)
end
if Config.ExpressionsEnabled then
    AddFaceMenu(mainMenu)
end
AddInfoMenu(mainMenu)

_menuPool:RefreshIndex()

local isMenuProcessing = false
function ProcessMenu()
    if isMenuProcessing then return end
    isMenuProcessing = true
    if Config.EmotePreview then
        clonedPed, clonedBDog, clonedSDog = CreateClone()
    end
    while _menuPool:IsAnyMenuOpen() do
        _menuPool:ProcessMenus()
        Wait(0)
    end
    isMenuProcessing = false
    if clonedPed ~= nil then
        DeleteEntity(clonedPed)
        DestroyAllCloneProps()
        clonedPed = nil
    end
    if clonedBDog ~= nil then
        DeleteEntity(clonedBDog)
        clonedBDog = nil
    end
    if clonedSDog ~= nil then
        DeleteEntity(clonedSDog)
        clonedSDog = nil
    end
    if clonedPed2 ~= nil then
        DeleteEntity(clonedPed2)
        clonedPed2 = nil
    end
end

RegisterNetEvent("rp:Update")
AddEventHandler("rp:Update", function(state)
    UpdateAvailable = state
    AddInfoMenu(mainMenu)
    _menuPool:RefreshIndex()
end)

RegisterNetEvent("rp:RecieveMenu") -- For opening the emote menu from another resource.
AddEventHandler("rp:RecieveMenu", function()
    OpenEmoteMenu()
end)


-- While ped is dead, don't show menus
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(500)
        if IsEntityDead(PlayerPedId()) then
            _menuPool:CloseAllMenus()
        end
        if (IsPedSwimming(PlayerPedId()) or IsPedSwimmingUnderWater(PlayerPedId())) and not Config.AllowInWater then
            -- cancel emote, destroy props and close menu
            if IsInAnimation then
                EmoteCancel()
            end
            _menuPool:CloseAllMenus()
        end
    end
end)

if Config.EmotePreview then
    function CreateClone()
        local ped = PlayerPedId()
        local scoords, ncoords = GetWorldCoordFromScreenCoord(clonedPosition.x, clonedPosition.y)
        local heading = math.atan(ncoords.x, ncoords.y) * 180.0 / math.pi

        local clone = ClonePed(ped, false, false, false)

        -- big dog
        RequestModel(GetHashKey("a_c_husky"))
        while not HasModelLoaded(GetHashKey("a_c_husky")) do
            Citizen.Wait(0)
        end
        local dog = CreatePed(28, GetHashKey("a_c_husky"), scoords.x, scoords.y, scoords.z, heading, false, false)

        -- small dog
        RequestModel(GetHashKey("a_c_poodle"))
        while not HasModelLoaded(GetHashKey("a_c_poodle")) do
            Citizen.Wait(0)
        end
        local dog2 = CreatePed(28, GetHashKey("a_c_poodle"), scoords.x, scoords.y, scoords.z, heading, false, false)

        SetEntityAlpha(clone, 0, false)
        SetEntityAlpha(dog, 0, false)
        SetEntityAlpha(dog2, 0, false)
        FreezeEntityPosition(clone, true)
        FreezeEntityPosition(dog, true)
        FreezeEntityPosition(dog2, true)
        SetEntityInvincible(clone, true)
        SetEntityInvincible(dog, true)
        SetEntityInvincible(dog2, true)
        SetBlockingOfNonTemporaryEvents(clone, true)
        SetBlockingOfNonTemporaryEvents(dog, true)
        SetBlockingOfNonTemporaryEvents(dog2, true)

        SetEntityHeading(clone, 180 - heading)
        local coords = scoords + ncoords * 4.0
        SetEntityCoordsNoOffset(clone, coords.x, coords.y, coords.z - 0.5, 0.0, 0.0, 0.0)
        SetEntityCollision(clone, false, false)
        SetEntityCollision(dog, false, false)
        SetEntityCollision(dog2, false, false)
        SetEntityNoCollisionEntity(clone, PlayerPedId(), false)
        SetEntityNoCollisionEntity(clone, dog, false)
        SetEntityNoCollisionEntity(clone, dog2, false)
        SetEntityNoCollisionEntity(dog, PlayerPedId(), false)
        SetEntityNoCollisionEntity(dog2, PlayerPedId(), false)
        SetEntityNoCollisionEntity(dog, dog2, false)
        local currentCoords = nil
        local currentHeading = nil
        local targetCoords = nil
        local targetHeading = nil
        local interpolationInterval = 1
        local lerpSpeed = 0.4

        CreateThread(function()
            while DoesEntityExist(clone) do
                scoords, ncoords = GetWorldCoordFromScreenCoord(clonedPosition.x, clonedPosition.y)
                targetCoords = scoords + ncoords * 4.0
                heading = math.atan(ncoords.x, ncoords.y) * 180.0 / math.pi
                SetEntityHeading(clone, 180 - heading)
                SetEntityHeading(dog, 180 - heading)
                SetEntityHeading(dog2, 180 - heading)
                Citizen.Wait(0)
            end
        end)

        CreateThread(function()
            while DoesEntityExist(clone) do
                Citizen.Wait(interpolationInterval)
                if currentCoords == nil then
                    currentCoords = targetCoords
                end
                currentCoords = VectorLerp(currentCoords, targetCoords, lerpSpeed)
                SetEntityCoordsNoOffset(clone, currentCoords.x, currentCoords.y, currentCoords.z - 0.5, 0.0, 0.0, 0.0)
                SetEntityCoordsNoOffset(dog, currentCoords.x, currentCoords.y, currentCoords.z - 0.5, 0.0, 0.0, 0.0)
                SetEntityCoordsNoOffset(dog2, currentCoords.x, currentCoords.y, currentCoords.z - 0.5, 0.0, 0.0, 0.0)
            end
        end)

        return clone, dog, dog2
    end

    function VectorLerp(startVec, endVec, t)
        return startVec + (endVec - startVec) * t
    end

    local cloneProps = {}
    local cloneHasProps = false
    local cloneGender = "male"

    function CheckCloneGender()

        if GetEntityModel(clonedPed) == GetHashKey("mp_f_freemode_01") then
            cloneGender = "female"
        else
            cloneGender = "male"
        end

        DebugPrint("Set clone gender as = (" .. cloneGender .. ")")
    end

    function OnCloneEmotePlay(EmoteName, name, textureVariation)
        local animOption = EmoteName.AnimationOptions

        ChosenDict, ChosenAnimation, ename = table.unpack(EmoteName)
        print("OnCloneEmotePlay", ChosenDict, ChosenAnimation, ename, name, textureVariation)
        CurrentAnimationName = name
        ChosenAnimOptions = animOption
        AnimationDuration = -1

        if string.sub(name, 1, 4) == "bdog" and RP.AnimalEmotes[name] then
            tempPed = clonedBDog
        elseif string.sub(name, 1, 4) == "sdog" and RP.AnimalEmotes[name] then
            tempPed = clonedSDog
        else
            tempPed = clonedPed
        end

        SetEntityAlpha(tempPed, 230, false)
        ClearPedTasksImmediately(tempPed)
        SetEntityCollision(tempPed, false, false)

        if animOption and animOption.Prop and cloneHasProps then
            DestroyAllCloneProps()
        end

        if ChosenDict == "MaleScenario" or ChosenDict == "Scenario" then
            return
        end

        -- Small delay at the start
        if animOption and animOption.StartDelay then
            Wait(animOption.StartDelay)
        end

        if not LoadAnim(ChosenDict) then
            EmoteChatMessage("'" .. ename .. "' " .. Config.Languages[lang]['notvalidemote'] .. "")
            return
        end

        MovementType = 0     -- Default movement type

        if InVehicle == 1 then
            MovementType = 51
        elseif animOption then
            if animOption.EmoteMoving then
                MovementType = 51
            elseif animOption.EmoteLoop then
                MovementType = 1
            elseif animOption.EmoteStuck then
                MovementType = 50
            end
        end

        if animOption then
            if animOption.EmoteDuration == nil then
                animOption.EmoteDuration = -1
                AttachWait = 0
            else
                AnimationDuration = animOption.EmoteDuration
                AttachWait = animOption.EmoteDuration
            end

            if animOption.PtfxAsset then
                PtfxAsset = animOption.PtfxAsset
                PtfxName = animOption.PtfxName
                if animOption.PtfxNoProp then
                    PtfxNoProp = animOption.PtfxNoProp
                else
                    PtfxNoProp = false
                end
                Ptfx1, Ptfx2, Ptfx3, Ptfx4, Ptfx5, Ptfx6, PtfxScale = table.unpack(animOption.PtfxPlacement)
                PtfxBone = animOption.PtfxBone
                PtfxColor = animOption.PtfxColor
                PtfxInfo = animOption.PtfxInfo
                PtfxWait = animOption.PtfxWait
                PtfxCanHold = animOption.PtfxCanHold
                PtfxNotif = false
                PtfxPrompt = true
            else
                DebugPrint("Ptfx = none")
                PtfxPrompt = false
            end
        end

        TaskPlayAnim(tempPed, ChosenDict, ChosenAnimation, 5.0, 5.0, AnimationDuration, MovementType, 0, false, false,
            false)
        RemoveAnimDict(ChosenDict)

        MostRecentDict = ChosenDict
        MostRecentAnimation = ChosenAnimation

        if animOption and animOption.Prop then
            PropName = animOption.Prop
            PropBone = animOption.PropBone
            PropPl1, PropPl2, PropPl3, PropPl4, PropPl5, PropPl6 = table.unpack(animOption.PropPlacement)
            if animOption.SecondProp then
                SecondPropName = animOption.SecondProp
                SecondPropBone = animOption.SecondPropBone
                SecondPropPl1, SecondPropPl2, SecondPropPl3, SecondPropPl4, SecondPropPl5, SecondPropPl6 = table.unpack(
                animOption.SecondPropPlacement)
                SecondPropEmote = true
            else
                SecondPropEmote = false
            end
            Wait(AttachWait)
            if not AddPropToClone(tempPed, PropName, PropBone, PropPl1, PropPl2, PropPl3, PropPl4, PropPl5, PropPl6, textureVariation) then return end
            if SecondPropEmote then
                if not AddPropToClone(tempPed, SecondPropName, SecondPropBone, SecondPropPl1, SecondPropPl2, SecondPropPl3, SecondPropPl4, SecondPropPl5, SecondPropPl6, textureVariation) then
                    DestroyAllCloneProps()
                    return
                end
            end
        end
    end

    function OnClone2EmotePlay(EmoteName, name, textureVariation)
        local animOption = EmoteName.AnimationOptions

        ClearPedTasks(clonedPed2)

        ChosenDict, ChosenAnimation, ename = table.unpack(EmoteName)
        CurrentAnimationName = name
        ChosenAnimOptions = animOption
        AnimationDuration = -1

        if animOption and animOption.Prop and cloneHasProps then
            DestroyAllCloneProps()
        end

        if ChosenDict == "MaleScenario" or ChosenDict == "Scenario" then
            CheckCloneGender()
            if ChosenDict == "MaleScenario" then
                if InVehicle then return end
                if PlayerGender == "male" then
                    ClearPedTasks(clonedPed2)
                    DestroyAllCloneProps()
                    TaskStartScenarioInPlace(clonedPed2, ChosenAnimation, 0, true)
                    DebugPrint("Playing scenario = (" .. ChosenAnimation .. ")")
                    IsInAnimation = true
                    RunAnimationThread()
                else
                    DestroyAllCloneProps()
                    EmoteCancel()
                    EmoteChatMessage(Config.Languages[lang]['maleonly'])
                end
                return
            elseif ChosenDict == "ScenarioObject" then
                if InVehicle then return end
                BehindPlayer = GetOffsetFromEntityInWorldCoords(clonedPed2, 0.0, 0 - 0.5, -0.5);
                ClearPedTasks(clonedPed2)
                TaskStartScenarioAtPosition(clonedPed2, ChosenAnimation, BehindPlayer['x'], BehindPlayer['y'],
                    BehindPlayer['z'], GetEntityHeading(clonedPed2), 0, true, false)
                DebugPrint("Playing scenario = (" .. ChosenAnimation .. ")")
                IsInAnimation = true
                RunAnimationThread()
                return
            elseif ChosenDict == "Scenario" then
                if InVehicle then return end
                ClearPedTasks(clonedPed2)
                DestroyAllCloneProps()
                TaskStartScenarioInPlace(clonedPed2, ChosenAnimation, 0, true)
                DebugPrint("Playing scenario = (" .. ChosenAnimation .. ")")
                IsInAnimation = true
                RunAnimationThread()
                return
            end
        end

        -- Small delay at the start
        if animOption and animOption.StartDelay then
            Wait(animOption.StartDelay)
        end

        if not LoadAnim(ChosenDict) then
            EmoteChatMessage("'" .. ename .. "' " .. Config.Languages[lang]['notvalidemote'] .. "")
            return
        end

        MovementType = 0     -- Default movement type

        if InVehicle == 1 then
            MovementType = 51
        elseif animOption then
            if animOption.EmoteMoving then
                MovementType = 51
            elseif animOption.EmoteLoop then
                MovementType = 1
            elseif animOption.EmoteStuck then
                MovementType = 50
            end
        end

        if animOption then
            if animOption.EmoteDuration == nil then
                animOption.EmoteDuration = -1
                AttachWait = 0
            else
                AnimationDuration = animOption.EmoteDuration
                AttachWait = animOption.EmoteDuration
            end

            if animOption.PtfxAsset then
                PtfxAsset = animOption.PtfxAsset
                PtfxName = animOption.PtfxName
                if animOption.PtfxNoProp then
                    PtfxNoProp = animOption.PtfxNoProp
                else
                    PtfxNoProp = false
                end
                Ptfx1, Ptfx2, Ptfx3, Ptfx4, Ptfx5, Ptfx6, PtfxScale = table.unpack(animOption.PtfxPlacement)
                PtfxBone = animOption.PtfxBone
                PtfxColor = animOption.PtfxColor
                PtfxInfo = animOption.PtfxInfo
                PtfxWait = animOption.PtfxWait
                PtfxCanHold = animOption.PtfxCanHold
                PtfxNotif = false
                PtfxPrompt = true
            else
                DebugPrint("Ptfx = none")
                PtfxPrompt = false
            end
        end

        TaskPlayAnim(clonedPed2, ChosenDict, ChosenAnimation, 5.0, 5.0, AnimationDuration, MovementType, 0, false, false,
            false)
        RemoveAnimDict(ChosenDict)

        MostRecentDict = ChosenDict
        MostRecentAnimation = ChosenAnimation

        if animOption and animOption.Prop then
            PropName = animOption.Prop
            PropBone = animOption.PropBone
            PropPl1, PropPl2, PropPl3, PropPl4, PropPl5, PropPl6 = table.unpack(animOption.PropPlacement)
            if animOption.SecondProp then
                SecondPropName = animOption.SecondProp
                SecondPropBone = animOption.SecondPropBone
                SecondPropPl1, SecondPropPl2, SecondPropPl3, SecondPropPl4, SecondPropPl5, SecondPropPl6 = table.unpack(animOption.SecondPropPlacement)
                SecondPropEmote = true
            else
                SecondPropEmote = false
            end
            Wait(AttachWait)
            if not AddPropToClone(PropName, PropBone, PropPl1, PropPl2, PropPl3, PropPl4, PropPl5, PropPl6, textureVariation) then return end
            if SecondPropEmote then
                if not AddPropToClone(SecondPropName, SecondPropBone, SecondPropPl1, SecondPropPl2, SecondPropPl3, SecondPropPl4, SecondPropPl5, SecondPropPl6, textureVariation) then
                    DestroyAllCloneProps()
                    return
                end
            end
        end
    end

    function OnCloneSharedEmotePlay(EmoteName, name, textureVariation)
        if not clonedPed then return end
        local attached = false
        local emote = tostring(name)
        local emote2 = tostring(EmoteName[4]) or emote
        -- create a new ped clonedPed2 and make it do the shared emote with the clonedPed
        clonedPed2 = ClonePed(clonedPed, 0.0, false, false)
        SetEntityNoCollisionEntity(clonedPed2, PlayerPedId(), true)
        FreezeEntityPosition(clonedPed2, true)
        local SyncOffsetFront = 1.0
        local SyncOffsetSide = 0.0
        local SyncOffsetHeight = 0.0
        local SyncOffsetHeading = 180.1

        local etype = "Shared"
        if not RP.Shared[emote] then
            etype = "Dances"
            emote2 = emote
        end

        local AnimationOptions = RP[etype][emote] and RP[etype][emote].AnimationOptions
        if AnimationOptions then
            if RP[etype][emote2].AnimationOptions then
                if RP[etype][emote2].AnimationOptions.Attachto then
                    emote = tostring(EmoteName[4])
                    emote2 = tostring(name)
                    AnimationOptions = RP[etype][emote] and RP[etype][emote].AnimationOptions
                end
            end
            if AnimationOptions.SyncOffsetFront then
                SyncOffsetFront = AnimationOptions.SyncOffsetFront + 0.0
            end
            if AnimationOptions.SyncOffsetSide then
                SyncOffsetSide = AnimationOptions.SyncOffsetSide + 0.0
            end
            if AnimationOptions.SyncOffsetHeight then
                SyncOffsetHeight = AnimationOptions.SyncOffsetHeight + 0.0
            end
            if AnimationOptions.SyncOffsetHeading then
                SyncOffsetHeading = AnimationOptions.SyncOffsetHeading + 0.0
            end

            if (AnimationOptions.Attachto) then
                attached = true
                local bone = AnimationOptions.bone or -1 -- No bone
                local xPos = AnimationOptions.xPos or 0.0
                local yPos = AnimationOptions.yPos or 0.0
                local zPos = AnimationOptions.zPos or 0.0
                local xRot = AnimationOptions.xRot or 0.0
                local yRot = AnimationOptions.yRot or 0.0
                local zRot = AnimationOptions.zRot or 0.0
                AttachEntityToEntity(clonedPed, clonedPed2, GetPedBoneIndex(clonedPed2, bone), xPos, yPos, zPos, xRot, yRot, zRot,
                    false, false, false, true, 1, true)
            end
        end
        if RP[etype][emote] ~= nil then
            OnCloneEmotePlay(RP[etype][emote], emote)
        end
        if RP[etype][emote2] ~= nil then
            OnClone2EmotePlay(RP[etype][emote2], emote2)
        end

        CreateThread(function()
            while DoesEntityExist(clonedPed2) do
                local coords = GetOffsetFromEntityInWorldCoords(clonedPed, SyncOffsetSide, SyncOffsetFront, SyncOffsetHeight)
                if not attached then
                    local heading = GetEntityHeading(clonedPed)
                    SetEntityHeading(clonedPed2, heading - SyncOffsetHeading)
                end
                SetEntityCoordsNoOffset(clonedPed2, coords.x, coords.y, coords.z, 0)
                Wait(0)
            end
        end)
    end

    function DestroyAllCloneProps()
        for _, v in pairs(cloneProps) do
            DeleteEntity(v)
        end
        cloneHasProps = false
        DebugPrint("Destroyed Props")
    end


    function AddPropToClone(ped, prop1, bone, off1, off2, off3, rot1, rot2, rot3, textureVariation)
        local Player = ped
        local x, y, z = table.unpack(GetEntityCoords(Player))

        if not IsModelValid(prop1) then
            DebugPrint(tostring(prop1).." is not a valid model!")
            return false
        end

        if not HasModelLoaded(prop1) then
            LoadPropDict(prop1)
        end

        prop = CreateObject(joaat(prop1), x, y, z + 0.2, true, true, true)
        if textureVariation ~= nil then
            SetObjectTextureVariation(prop, textureVariation)
        end
        AttachEntityToEntity(prop, Player, GetPedBoneIndex(Player, bone), off1, off2, off3, rot1, rot2, rot3, true, true,
            false, true, 1, true)
        table.insert(cloneProps, prop)
        cloneHasProps = true
        SetModelAsNoLongerNeeded(prop1)
        DebugPrint("Added prop to clone")
        return true
    end


    function PlayCloneEmote(args, hard, textureVariation)
        local name = args
        local etype = hard

        if etype == "dances" then
            if RP.Dances[name] ~= nil then
                OnCloneEmotePlay(RP.Dances[name], name)
            end
        elseif etype == "props" then
            if RP.PropEmotes[name] ~= nil then
                OnCloneEmotePlay(RP.PropEmotes[name], name, textureVariation)
            end
        elseif etype == "emotes" then
            if RP.Emotes[name] ~= nil then
                OnCloneEmotePlay(RP.Emotes[name], name)
            end
        elseif etype == "shared" then
            if RP.Shared[name] ~= nil or RP.Dances[name] ~= nil then
                OnCloneSharedEmotePlay(RP.Shared[name] or RP.Dances[name], name)
            end
        elseif etype == "animals" then
            if RP.AnimalEmotes[name] ~= nil then
                OnCloneEmotePlay(RP.AnimalEmotes[name], name)
            end
        end
    end



    AddEventHandler("onResourceStop", function(resource)
        if resource == GetCurrentResourceName() then
            DestroyAllCloneProps()
            if DoesEntityExist(clonedPed) then
                DeleteEntity(clonedPed)
            end
            if DoesEntityExist(clonedSDog) then
                DeleteEntity(clonedSDog)
            end
            if DoesEntityExist(clonedBDog) then
                DeleteEntity(clonedBDog)
            end
            if DoesEntityExist(clonedPed2) then
                DeleteEntity(clonedPed2)
            end
        end
    end)
end
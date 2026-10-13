-- AdoptMe Local Stable 1.5 | consolidated revision of the supplied 14,303-line source.
-- Local execution; no configured Owner/UserId, HTTP, webhook or remote-code dependency.
-- Starts paused. Equip your pet(s), then enable Farm in the HUB.
-- Internal game protocols still require live validation; see review/REVISAO.md.
local UserConfig = {
    Farm = {
        Enabled = false,
        AutoNeeds = { Enabled = true },
        BabyMode = false,
        KeepPetEquipped = true,
        KeepEquippedPair = true,
        TwoPets = true,
        BuyFood = false, -- opt in using the HUB if purchases with Bucks are desired
        BuyWater = false,
    },
    Logging = { ConsoleLevel = "WARN", FileEnabled = false, SessionFile = false },
    Interface = { Enabled = true, Language = "pt", RememberSettings = true },
}
local __startupCleanup
local __moduleSources = {}
local __moduleCache = {}
local __LOADING = {}
local function import(moduleName)
    local cached = __moduleCache[moduleName]
    if cached == __LOADING then
        error("Circular import: " .. moduleName, 2)
    end
    if cached ~= nil then
        return cached
    end
    local source = __moduleSources[moduleName]
    if not source then
        error("Unknown module: " .. moduleName, 2)
    end
    __moduleCache[moduleName] = __LOADING
    local ok, result = pcall(source, import)
    if not ok then
        __moduleCache[moduleName] = nil
        error("Module " .. moduleName .. ": " .. tostring(result), 2)
    end
    if result == nil then result = true end
    __moduleCache[moduleName] = result
    return result
end
__moduleSources["Core/Enums"] = function(...)
    local function createEnum(enumName, itemNames)
        local items = {}
        for _, itemName in ipairs(itemNames) do
            items[itemName] = itemName
        end
        return table.freeze(setmetatable(items, {
            __index = function(_, key)
                error(string.format("%s.%s is not a valid enum item", enumName, tostring(key)), 2)
            end,
            __newindex = function()
                error(enumName .. " is read-only", 2)
            end,
        }))
    end
    local Enums = {}
    Enums.LogLevel = createEnum("LogLevel", { "DEBUG", "INFO", "SUCCESS", "WARN", "ERROR" })
    Enums.LogLevelRank = { DEBUG = 1, INFO = 2, SUCCESS = 3, WARN = 4, ERROR = 5, OFF = 99 }
    Enums.NotifyEvent = createEnum("NotifyEvent", {
        "SessionStarted",
        "SessionStopped",
        "Summary",
        "TaskCompleted",
        "Error",
        "Kicked",
        "PreviousSessionEnded",
        "Test",
    })
    return Enums
end
__moduleSources["Core/Util"] = function(...)
    local HttpService = game:GetService("HttpService")
    local Util = {}
    function Util.now()
        return os.clock()
    end
    function Util.getSharedEnvironment()
        if type(getgenv) == "function" then
            return getgenv()
        end
        return _G
    end
    function Util.getRequestFunction()
        -- Deny outgoing HTTP across the entire private script. Telemetry, webhooks,
        -- and the optional Hauntlet relay must never access the executor's request API.
        return nil
    end
    function Util.fileApi()
        return { canWrite = false, canAppend = false, canMakeFolder = false }
    end
    function Util.ensureFolder(path)
        return false -- This build does not access the executor filesystem.
    end
    function Util.jsonEncode(value)
        local ok, result = pcall(function()
            return HttpService:JSONEncode(value)
        end)
        if ok then
            return result
        end
        return nil, tostring(result)
    end
    function Util.jsonDecode(text)
        local ok, result = pcall(function()
            return HttpService:JSONDecode(text)
        end)
        if ok then
            return result
        end
        return nil, tostring(result)
    end
    function Util.formatDuration(seconds)
        seconds = math.max(0, math.floor(seconds or 0))
        local hours = math.floor(seconds / 3600)
        local minutes = math.floor((seconds % 3600) / 60)
        local remaining = seconds % 60
        return string.format("%02d:%02d:%02d", hours, minutes, remaining)
    end
    function Util.truncate(text, maxLength)
        text = tostring(text)
        if #text <= maxLength then
            return text
        end
        local cut = math.max(0, maxLength - 3)
        while cut > 0 do
            local nextByte = string.byte(text, cut + 1)
            if not nextByte or nextByte < 0x80 or nextByte >= 0xC0 then
                break
            end
            cut -= 1
        end
        return string.sub(text, 1, cut) .. "..."
    end
    function Util.shallowCopy(source)
        local copy = {}
        for key, value in pairs(source) do
            copy[key] = value
        end
        return copy
    end
    return Util
end
__moduleSources["Core/Signal"] = function(...)
    local Signal = {}
    Signal.__index = Signal
    function Signal.new(name)
        return setmetatable({ _name = name or "Signal", _listeners = {} }, Signal)
    end
    function Signal:Connect(handler)
        assert(type(handler) == "function", "Signal:Connect expects a function")
        local listener = { handler = handler, connected = true }
        table.insert(self._listeners, listener)
        local connection = { Connected = true }
        listener.connection = connection
        function connection.Disconnect()
            if not listener.connected then
                return
            end
            listener.connected = false
            connection.Connected = false
            for index, entry in ipairs(self._listeners) do
                if entry == listener then
                    table.remove(self._listeners, index)
                    break
                end
            end
        end
        return connection
    end
    function Signal:Fire(...)
        local snapshot = table.clone(self._listeners)
        for _, listener in ipairs(snapshot) do
            if listener.connected then
                local ok, err = pcall(listener.handler, ...)
                if not ok then
                    warn("[" .. self._name .. "] handler error: " .. tostring(err))
                end
            end
        end
    end
    function Signal:DisconnectAll()
        for _, listener in ipairs(self._listeners) do
            listener.connected = false
            listener.connection.Connected = false
        end
        table.clear(self._listeners)
    end
    Signal.Destroy = Signal.DisconnectAll
    return Signal
end
__moduleSources["Core/Maid"] = function(...)
    local Maid = {}
    Maid.__index = Maid
    function Maid.new()
        return setmetatable({ _jobs = {} }, Maid)
    end
    local function isConnection(job)
        if typeof(job) == "RBXScriptConnection" then
            return true
        end
        return type(job) == "table" and type(job.Disconnect) == "function"
    end
    local function cleanJob(job)
        if type(job) == "function" then
            job()
        elseif type(job) == "thread" then
            if coroutine.running() ~= job then
                pcall(task.cancel, job)
            end
        elseif isConnection(job) then
            job:Disconnect()
        elseif type(job) == "table" and type(job.Destroy) == "function" then
            job:Destroy()
        elseif typeof(job) == "Instance" then
            job:Destroy()
        end
    end
    function Maid:Give(job)
        assert(job ~= nil, "Maid:Give received nil")
        table.insert(self._jobs, job)
        return job
    end
    function Maid:Clean()
        local jobs = self._jobs
        self._jobs = {}
        for _, job in ipairs(jobs) do
            if isConnection(job) then
                pcall(cleanJob, job)
            end
        end
        for _, job in ipairs(jobs) do
            if not isConnection(job) then
                local ok, err = pcall(cleanJob, job)
                if not ok then
                    warn("[Maid] cleanup error: " .. tostring(err))
                end
            end
        end
    end
    Maid.Destroy = Maid.Clean
    return Maid
end
__moduleSources["Core/Config"] = function(...)
    local import = ...
    local Enums = import("Core/Enums")
    local Config = {}
    Config.Defaults = {
        General = {
            ScriptName = "AdoptMe Local Stable",
            TickSeconds = 0.5,
        },
        Farm = {
            Enabled = false,
            BabyMode = false,
            FastTravel = true,
            Tasks = {
                pet_me = true,
                salon = true,
                bored = true,
                cat_cafe = true,
                sleepy = true,
                dirty = true,
                toilet = true,
                hungry = true,
                thirsty = true,
                play = true,
                pizza_party = true,
                school = true,
                sick = true,
                camping = true,
                beach_party = true,
                mystery = true,
                walk = true,
                ride = true,
            },
            AutoNeeds = {
                Enabled = true,
                Skip = {},
            },
            MultiNeed = {
                Enabled = false,
                Kinds = { "pet_me", "hungry", "thirsty", "play" },
                GapSeconds = 1,
            },
            SmartPriority = true,
            Priority = {
                mystery = 51,
                pet_me = 50,
                hungry = 49,
                thirsty = 48,
                dirty = 46,
                toilet = 45,
                sleepy = 44,
                play = 42,
                sick = 47,
                salon = 40,
                school = 39,
                pizza_party = 38,
                camping = 34,
                beach_party = 33,
                walk = 32,
                ride = 31,
                cat_cafe = 35,
                bored = 30,
            },
            AutoAcceptMenu = true,
            AntiAfk = true,
            CameraGuard = true,
            CollectCashback = false,
            CashbackMinutes = 10,
            SpotTravel = "teleport",
            KeepPetEquipped = true,
            GameTravel = true,
            HomeByRespawn = false, -- legacy option: normal house entry is mandatory
            HouseDoorExit = true, -- house -> neighborhood -> main city
            FoodBowlTrip = false,
            SkipFullGrown = true,
            PetOrder = "youngest",
            BuyEgg = false,
            EggToBuy = "cracked_egg",
            Focus = "", -- focus pet / egg ("" = none): see GameConstants.focusOf
            MaxEggBuysPerSession = 0,
            BuyWater = false,
            BuyFood = false,
            MaxBuysPerSession = 0,
            TwoPets = true, -- Requires two slots authorized by the game (e.g. an active Pet Certificate).
            KeepEquippedPair = true,
            PrioritizeNeeds = true,
            AutoCloseDialogs = true, -- the game's dialogs (minigame teleport -> No, Okay / Nice / Done, bank -> Cash out)
            AutoPotions = {
                Enabled = false,
                Potions = { "pet_age_potion", "tiny_pet_age_potion", "pet_bonus_aging_potion", "pet_bonus_bucks_potion",
        "pet_random_ailment_potion" },
                BuffMinutes = 15, -- Bonus Aging / Bonus Bucks last 15 min (user 2026-10-11): one of each kind per 15 min
                Skip = {},
                PetKinds = {},
            },
            AutoNeon = {
                Enabled = false,
                Mega = false,
                Exclude = {},
            },
            PreferNeon = true,
            AutoRejoin = false,
            StuckRejoinSeconds = 180,
            StuckRecovery = {
                Enabled = true,
                Seconds = 240,
            },
            FarmPetKinds = {},
            AutoOpen = {
                Enabled = false,
                Exclude = {},
            },
            Event = {
                Enabled = true,
                GhostGallery = false,
                Hauntlet = false,
                HauntletMove = "tween", -- "tween" (smooth, default) | "walk" | "tp": how the bot reaches a door's circle
                HauntletMoveSeconds = 0.5, -- tween: seconds to reach the circle (0.1 - 5; the room's time is ~25 s)
                HauntletFirst = true, -- a Hauntlet run comes before a Ghost Gallery round when both are near
                HauntletSquad = true, -- several of your accounts in one run: shared items (phone, keys, wand) by turns
                HauntletSquadKey = "", -- private squad key (= the worker's SQUAD_KEY secret): empty = nothing is sent
                GhostJoinByZone = true,
                Crypt = false,
                MummySpider = true,
                CryptOpen = { "ladder" },
                Quests = false,
                HouseVisits = false,
                PigeonNest = false,
                AutoNest = false,
                AutoSkelicorn = false, -- Crypt (Lightning Lever) -> machine by the Manor -> 1 Skelicorn for 120000 candy
                StrayCat = false,
                PetPen = false,
                PetPenMinutes = 15,
                CandyPets = {
                    Enabled = false,
                    Pick = {},
                    KeepCandy = 0,
                    MaxBuy = false,
                    Buy = {
                        { id = "halloween_2026_jump_scare", price = 40000, max = 1 },
                        { id = "halloween_2026_jacobean_pigeon", price = 4000, max = 4 },
                        -- sold by the machine by the Manor (Lightning Lever): bought by the Skelicorn task, not here
                        { id = "halloween_2026_skelicorn", price = 120000, max = 0, machine = true },
                    },
                },
                PetPenSlots = 4,
                PetPenStock = false,
                PetPenStockMinBucks = 750,
            },
            PetMeFocusSeconds = 7,
            FailureCooldownSeconds = 30,
            MaxConsecutiveFailures = 3,
            DisableMinutes = 15,
        },
        Interface = {
            Enabled = true,
            Keybind = "RightShift",
            Toasts = true,
            RememberSettings = true,
            Theme = "Halloween",
            Descriptions = false,
            Autoload = "",
            StartHidden = false,
            UIScale = "Auto",
            Language = "Auto",
        },
        Logging = {
            ConsoleLevel = "INFO",
            FileLevel = "DEBUG",
            FileEnabled = false,
            SessionFile = false,
            Folder = "AdoptMeFarm/logs",
            FlushSeconds = 5,
            DuplicateWindowSeconds = 10,
            MaxLinesPerSession = 20000,
        },
        Telemetry = {
            Enabled = false,
            Url = "", -- privacy build: no developer relay
            Owner = "victimoffate_",
            SummaryMinutes = 30,
            IncludeInventory = false,
        },
        Notifications = {
            Enabled = false,
            Webhooks = {
                Summary = "",
                Alerts = "",
            },
            SummaryIntervalMinutes = 15,
            SendOnTaskComplete = false,
            SendOnError = true,
            SendOnKick = true,
            SendOnStartStop = true,
            SendTestMessageOnStart = false,
            PingDiscordUserId = "",
            Ping = true,
            SendSummary = true,
            PingOn = {
                Kick = true,
                Error = false,
                Summary = false,
                TaskCompleted = false,
                SessionStopped = false,
                PreviousSession = false,
            },
            IncludeUsername = true,
            AlertCooldownSeconds = 60,
            MinSecondsBetweenMessages = 2.5,
            MaxQueueSize = 50,
            MaxRetries = 3,
        },
    }
    local function taskPaths()
        local kinds = {}
        for kind in pairs(Config.Defaults.Farm.Tasks) do
            table.insert(kinds, kind)
        end
        table.sort(kinds)
        local paths = {}
        for _, kind in ipairs(kinds) do
            table.insert(paths, { "Farm", "Tasks", kind })
        end
        return paths
    end
    Config.FEATURE_PATHS = {
        { "Farm", "AutoNeeds", "Enabled" },
        { "Farm", "BabyMode" },
        { "Farm", "KeepPetEquipped" },
        { "Farm", "BuyEgg" },
        { "Farm", "CollectCashback" },
        { "Farm", "AutoPotions", "Enabled" },
        { "Farm", "AutoNeon", "Enabled" },
        { "Farm", "AutoNeon", "Mega" },
        { "Farm", "AutoOpen", "Enabled" },
        { "Farm", "Event", "GhostGallery" },
        { "Farm", "Event", "Hauntlet" },
        { "Farm", "Event", "Crypt" },
        { "Farm", "Event", "Quests" },
        { "Farm", "Event", "HouseVisits" },
        { "Farm", "Event", "PigeonNest" },
        { "Farm", "Event", "StrayCat" },
        { "Farm", "Event", "PetPen" },
        { "Farm", "Event", "PetPenStock" },
        { "Farm", "Event", "CandyPets", "Enabled" },
    }
    Config.PRESET_EXTRA_PATHS = {
        { "Farm", "Focus" },
        { "Farm", "Event", "AutoSkelicorn" },
        { "Farm", "Event", "MummySpider" },
        { "Farm", "FarmPetKinds" },
        { "Farm", "AutoPotions", "PetKinds" },
        { "Farm", "PetOrder" },
        { "Farm", "AutoNeeds", "Skip" },
        { "Farm", "AutoPotions", "Skip" },
        { "Farm", "Event", "CryptOpen" },
        { "Farm", "Event", "CandyPets", "Pick" },
    }
    for _, path in ipairs(taskPaths()) do
        table.insert(Config.PRESET_EXTRA_PATHS, path)
    end
    local SPIDER = "halloween_2026_tomb_spider"
    local ALL_NEEDS = { { { "Farm", "AutoNeeds", "Enabled" }, true } }
    local function join(...)
        local list = {}
        for _, part in ipairs({ ... }) do
            for _, entry in ipairs(part) do
                table.insert(list, entry)
            end
        end
        return list
    end
    local NEEDS_ON = join(ALL_NEEDS, {
        { { "Farm", "BabyMode" }, true },
        { { "Farm", "KeepPetEquipped" }, true },
        { { "Farm", "BuyEgg" }, true },
    })
    local EXTRAS_ON = {
        { { "Farm", "CollectCashback" }, true },
        { { "Farm", "AutoPotions", "Enabled" }, true },
        { { "Farm", "AutoNeon", "Enabled" }, true },
        { { "Farm", "AutoNeon", "Mega" }, true },
        { { "Farm", "AutoOpen", "Enabled" }, true },
    }
    local EVENT_CORE_ON = {
        { { "Farm", "Event", "GhostGallery" }, true },
        { { "Farm", "Event", "Hauntlet" }, true },
        { { "Farm", "Event", "Crypt" }, true },
        { { "Farm", "Event", "Quests" }, true },
        { { "Farm", "Event", "HouseVisits" }, true },
        { { "Farm", "Event", "PetPen" }, true },
    }
    local EVENT_EXTRAS_ON = {
        { { "Farm", "Event", "PigeonNest" }, true },
        { { "Farm", "Event", "StrayCat" }, true },
        { { "Farm", "Event", "PetPenStock" }, true },
        { { "Farm", "Event", "CandyPets", "Enabled" }, true },
        { { "Farm", "Event", "CandyPets", "Pick" }, { "halloween_2026_jacobean_pigeon", "halloween_2026_jump_scare" } },
    }
    Config.SPEEDRUN_CHANGES = {
        { { "Farm", "BuyEgg" }, false },
        { { "Farm", "AutoPotions", "PetKinds" }, { SPIDER } },
        { { "Farm", "FarmPetKinds" }, { SPIDER } },
        { { "Farm", "AutoNeon", "Enabled" }, true },
        { { "Farm", "PreferNeon" }, true },
        { { "Farm", "PetOrder" }, "oldest" },
        { { "Farm", "Event", "GhostGallery" }, true },
        { { "Farm", "Event", "Crypt" }, true },
        { { "Farm", "Event", "MummySpider" }, true },
        { { "Farm", "Event", "Quests" }, true },
        { { "Farm", "Event", "Hauntlet" }, false },
        { { "Farm", "Event", "PigeonNest" }, false },
        { { "Farm", "Event", "StrayCat" }, false },
        { { "Farm", "Event", "CandyPets", "Enabled" }, false },
        { { "Farm", "Event", "PetPenStock" }, false },
        { { "Farm", "Focus" }, SPIDER },
    }
    -- v2.1.4 (user: "pick a pet: an egg -> buy and hatch it; a pet -> mega it on repeat with its copies in the Pet Pen;
    -- the Mummy Spider / Skelicorn -> get them; a candy pet like the Jacobean Pigeon -> buy 5, raise 1, 4 in the pen").
    -- Farm.Focus does it at run time (GameConstants.focusOf); a preset only switches on what the focus needs.
    local SKELICORN = "halloween_2026_skelicorn"
    local function focusChanges(id)
        return {
            { { "Farm", "Focus" }, id },
            { { "Farm", "AutoNeon", "Enabled" }, true },
            { { "Farm", "AutoNeon", "Mega" }, true },
            { { "Farm", "AutoPotions", "Enabled" }, true },
            { { "Farm", "PreferNeon" }, true },
            { { "Farm", "PetOrder" }, "oldest" },
            { { "Farm", "Event", "PetPen" }, true },
            { { "Farm", "Event", "PetPenStock" }, true },
            { { "Farm", "Event", "CandyPets", "Enabled" }, false },
            { { "Farm", "Event", "PigeonNest" }, false },
            { { "Farm", "Event", "StrayCat" }, true }, -- candy every day
        }
    end
    -- user 2026-10-11: "with Mega Skelicorn the candy farm at its highest": every candy source on, Rusty Keys on the
    -- biggest candy pile in reach (after the lever), the ladder only when no pile is left on the floors in reach
    Config.CANDY_MAX = {
        { { "Farm", "Event", "Hauntlet" }, true },
        { { "Farm", "Event", "HauntletFirst" }, true },
        { { "Farm", "Event", "GhostGallery" }, true },
        { { "Farm", "Event", "Crypt" }, true },
        { { "Farm", "Event", "CryptOpen" }, { "lever", "candy_corn_pile_ginormous", "candy_corn_pile_big",
            "candy_corn_pile_small", "ladder" } },
        { { "Farm", "Event", "Quests" }, true },
        { { "Farm", "Event", "HouseVisits" }, true },
        { { "Farm", "Event", "StrayCat" }, true },
        { { "Farm", "Event", "CandyPets", "Enabled" }, false },
    }
    Config.focusChanges = focusChanges
    Config.SKELICORN_CHANGES = join(focusChanges(SKELICORN), Config.CANDY_MAX, {
        { { "Farm", "BuyEgg" }, false },
        { { "Farm", "FarmPetKinds" }, { SKELICORN } },
        { { "Farm", "AutoPotions", "PetKinds" }, { SKELICORN } },
        { { "Farm", "Event", "Crypt" }, true },
        { { "Farm", "Event", "AutoSkelicorn" }, true },
        { { "Farm", "Event", "Hauntlet" }, true },
        { { "Farm", "Event", "GhostGallery" }, true },
    })
    Config.Presets = {
        { id = "NeedsStable", name = "Stable Needs", icon = "heart",
            about = "Protected pets, sequential needs; baby and purchases opt in; starts paused.",
            set = join(ALL_NEEDS, {
                { { "Farm", "Enabled" }, false },
                { { "Farm", "BabyMode" }, false },
                { { "Farm", "KeepPetEquipped" }, true },
                { { "Farm", "TwoPets" }, true },
                { { "Farm", "KeepEquippedPair" }, true },
                { { "Farm", "PrioritizeNeeds" }, true },
                { { "Farm", "MultiNeed", "Enabled" }, false },
                { { "Farm", "BuyEgg" }, false },
                { { "Farm", "BuyFood" }, false },
                { { "Farm", "BuyWater" }, false },
                { { "Farm", "Event", "Enabled" }, false },
            }) },
        { id = "Off", name = "Everything Off", icon = "power",
            about = "Every feature off (the defaults). Anti-AFK and the Play button stay on.",
            set = { { { "Farm", "Enabled" }, false } } },
        { id = "Balanced", name = "Full AutoFarm", icon = "circle-gauge",
            about = "Everything: every need, eggs, potions, neon + mega neon, gifts, cashback, quests and the whole event.",
            set = join(NEEDS_ON, EXTRAS_ON, EVENT_CORE_ON, EVENT_EXTRAS_ON) },
        { id = "Speedrun", name = "Mega Mummy Spider's", icon = "rocket",
            about = "Mummy Spiders only: keys straight down the Crypt, every spider grown (needs, potions, Pet Pen), "
                .. "then neon + mega neon. No eggs, no candy pets, no nest / Stray Cat.",
            set = join(NEEDS_ON, EXTRAS_ON, EVENT_CORE_ON, EVENT_EXTRAS_ON, Config.SPEEDRUN_CHANGES) },
        { id = "Skelicorn", name = "Mega Skelicorn", icon = "sparkles",
            about = "Skelicorns only: candy from the whole event, Lightning Lever from the Crypt, a Skelicorn every "
                .. "120k candy (up to 5 growing), grown + neon + mega neon.",
            set = join(NEEDS_ON, EXTRAS_ON, EVENT_CORE_ON, Config.SKELICORN_CHANGES) },
        { id = "Focus", name = "Mega a Pet", icon = "crosshair", pick = true,
            about = "Pick one pet or egg below. Egg: bought and hatched on repeat. Candy pet: 5 bought (1 raised, 4 in "
                .. "the Pet Pen). Any pet: grown, neon, mega neon on repeat, its copies in the Pet Pen.",
            set = join(NEEDS_ON, EXTRAS_ON, EVENT_CORE_ON, focusChanges("")) },
        { id = "EventOnly", name = "Event Only", icon = "ghost",
            about = "Only Halloween: Ghost Gallery, Crypt + Mummy Spider, quests, Pet Pen. No pet / baby needs.",
            set = EVENT_CORE_ON },
        { id = "NeedsOnly", name = "Needs Only", icon = "list-checks",
            about = "Only pet + baby needs (with eggs when nothing grows). The event stays off.",
            set = NEEDS_ON },
    }
    function Config.findPreset(name)
        if type(name) ~= "string" then
            return nil
        end
        local wanted = string.lower((string.gsub(name, "[%s_%-]", "")))
        for _, preset in ipairs(Config.Presets) do
            if string.lower(preset.id) == wanted or string.lower((string.gsub(preset.name, "[%s_%-]", ""))) == wanted then
                return preset
            end
        end
        return nil
    end
    local function deepCopy(value)
        if type(value) ~= "table" then
            return value
        end
        local copy = {}
        for key, item in pairs(value) do
            copy[key] = deepCopy(item)
        end
        return copy
    end
    local function valueAt(root, path)
        local node = root
        for index = 1, #path do
            if type(node) ~= "table" then
                return nil
            end
            node = node[path[index]]
        end
        return node
    end
    Config.valueAt = valueAt
    function Config.presetValues(name, focus)
        local preset = Config.findPreset(name)
        if not preset then
            return nil
        end
        local values = {}
        for _, list in ipairs({ Config.FEATURE_PATHS, Config.PRESET_EXTRA_PATHS }) do
            for _, path in ipairs(list) do
                local value = deepCopy(valueAt(Config.Defaults, path))
                if list == Config.FEATURE_PATHS then value = false end
                table.insert(values, { path, value })
            end
        end
        for _, entry in ipairs(preset.set) do
            table.insert(values, { entry[1], deepCopy(entry[2]) })
        end
        if preset.pick then -- "Mega a Pet": the picked pet / egg drives the rest
            local id = type(focus) == "string" and focus or ""
            table.insert(values, { { "Farm", "Focus" }, id })
            local isEgg = string.match(id, "_egg$") ~= nil
            if id ~= "" and not isEgg then
                table.insert(values, { { "Farm", "FarmPetKinds" }, { id } })
                table.insert(values, { { "Farm", "AutoPotions", "PetKinds" }, { id } })
                table.insert(values, { { "Farm", "BuyEgg" }, false })
            elseif id ~= "" then
                table.insert(values, { { "Farm", "BuyEgg" }, true })
                table.insert(values, { { "Farm", "EggToBuy" }, id })
                table.insert(values, { { "Farm", "PetOrder" }, "youngest" })
            end
            if id == SPIDER or id == SKELICORN then
                table.insert(values, { { "Farm", "Event", "Crypt" }, true })
                table.insert(values, { { "Farm", "Event", "MummySpider" }, true })
            end
            if id == SKELICORN then
                table.insert(values, { { "Farm", "Event", "AutoSkelicorn" }, true })
            end
            local candyPet = id == SKELICORN
            for _, entry in ipairs(Config.Defaults.Farm.Event.CandyPets.Buy or {}) do
                candyPet = candyPet or entry.id == id
            end
            if candyPet then -- bought with candy: every candy source on (Config.CANDY_MAX)
                for _, entry in ipairs(Config.CANDY_MAX) do
                    table.insert(values, { entry[1], deepCopy(entry[2]) })
                end
            end
        end
        return values, preset
    end
    function Config.countFeatures(config)
        local on = 0
        for _, path in ipairs(Config.FEATURE_PATHS) do
            if valueAt(config, path) == true then
                on += 1
            end
        end
        return on, #Config.FEATURE_PATHS
    end
    local VALID_LOG_LEVELS = Enums.LogLevelRank
    local function isValidWebhookUrl(url)
        if url == "" then
            return true
        end
        return string.match(url, "^https://discord%.com/api/webhooks/%d+/[%w%-_]+$") ~= nil
            or string.match(url, "^https://discordapp%.com/api/webhooks/%d+/[%w%-_]+$") ~= nil
            or string.match(url, "^https://canary%.discord%.com/api/webhooks/%d+/[%w%-_]+$") ~= nil
            or string.match(url, "^https://ptb%.discord%.com/api/webhooks/%d+/[%w%-_]+$") ~= nil
    end
    Config.isValidWebhookUrl = isValidWebhookUrl
    local function isList(value)
        if type(value) ~= "table" then
            return false
        end
        local n = 0
        for key in pairs(value) do
            if type(key) ~= "number" or key < 1 or key % 1 ~= 0 then return false end
            n += 1
        end
        return n == #value
    end
    local function merge(defaults, overrides, path, warnings)
        local result = {}
        for key, defaultValue in pairs(defaults) do
            local overrideValue
            if type(overrides) == "table" then overrideValue = overrides[key] end
            local keyPath = path == "" and key or (path .. "." .. key)
            if isList(defaultValue) and isList(overrideValue) then
                local cleaned = {}
                for _, item in ipairs(overrideValue) do
                    if type(defaultValue[1]) == "table" then
                        -- Candy shop records are the only structured config list. Missing
                        -- IDs/prices cannot silently become a purchase of the first default item.
                        local id = type(item) == "table" and (item.id or item[1])
                        local price = type(item) == "table" and tonumber(item.price)
                        local max = type(item) == "table" and tonumber(item.max) or 0
                        if type(id) == "string" and id ~= "" and price and price == price and price > 0 and price < math.huge
                            and max and max == max and max >= 0 and max < math.huge then
                            table.insert(cleaned, { id = id, price = price, max = math.floor(max), machine = item.machine == true })
                        else table.insert(warnings, keyPath .. " contains an invalid shop record") end
                    elseif type(item) == "string" and item ~= "" then
                        if not table.find(cleaned, item) then table.insert(cleaned, item) end
                    else table.insert(warnings, keyPath .. " expects a list of strings") end
                end
                result[key] = cleaned
                continue
            end
            if type(defaultValue) == "table" then
                if overrideValue ~= nil and type(overrideValue) ~= "table" then
                    table.insert(warnings, keyPath .. " must be a table; default used")
                    overrideValue = nil
                end
                result[key] = merge(defaultValue, overrideValue, keyPath, warnings)
            elseif overrideValue == nil then
                result[key] = defaultValue
            elseif type(overrideValue) == "number" and (overrideValue ~= overrideValue or math.abs(overrideValue) == math.huge) then
                table.insert(warnings, keyPath .. " must be finite; default used")
                result[key] = defaultValue
            elseif type(overrideValue) ~= type(defaultValue) then
                table.insert(warnings, string.format("%s must be a %s (got %s); default used", keyPath, type(defaultValue), type(overrideValue)))
                result[key] = defaultValue
            else
                result[key] = overrideValue
            end
        end
        if type(overrides) == "table" then
            for key in pairs(overrides) do
                if defaults[key] == nil then
                    local keyPath = path == "" and tostring(key) or (path .. "." .. tostring(key))
                    table.insert(warnings, "Unknown setting ignored: " .. keyPath)
                end
            end
        end
        return result
    end
    function Config.build(userConfig)
        local warnings = {}
        local base = Config.Defaults
        local overrides = type(userConfig) == "table" and userConfig or {}
        if userConfig ~= nil and type(userConfig) ~= "table" then
            table.insert(warnings, "Settings must be a table; defaults used")
        end
        local presetId
        if type(overrides) == "table" and overrides.Preset ~= nil then
            local values, preset = Config.presetValues(overrides.Preset,
                type(overrides.Farm) == "table" and overrides.Farm.Focus or nil)
            if values then
                presetId = preset.id
                base = deepCopy(Config.Defaults)
                for _, entry in ipairs(values) do
                    local parent = valueAt(base, { table.unpack(entry[1], 1, #entry[1] - 1) })
                    if type(parent) == "table" then
                        parent[entry[1][#entry[1]]] = entry[2]
                    end
                end
            elseif overrides.Preset ~= "" then
                table.insert(warnings, "Preset '" .. tostring(overrides.Preset) .. "' is not a preset (Off, Balanced, Speedrun,"
                    .. " Skelicorn, Focus, EventOnly, NeedsOnly); none used")
            end
            overrides = table.clone(overrides)
            overrides.Preset = nil
        end
        local config = merge(base, overrides, "", warnings)
        config.Preset = presetId
        for _, levelKey in ipairs({ "ConsoleLevel", "FileLevel" }) do
            local level = string.upper(config.Logging[levelKey])
            if VALID_LOG_LEVELS[level] == nil then
                table.insert(warnings, "Logging." .. levelKey .. " is not a valid level; INFO used")
                level = "INFO"
            end
            config.Logging[levelKey] = level
        end
        local notifications = config.Notifications
        for name, url in pairs(notifications.Webhooks) do
            if not isValidWebhookUrl(url) then
                table.insert(warnings, "Notifications.Webhooks." .. name .. " is not a Discord webhook URL; disabled")
                notifications.Webhooks[name] = ""
            end
        end
        if notifications.PingDiscordUserId ~= "" and not string.match(notifications.PingDiscordUserId, "^%d+$") then
            table.insert(warnings, "Notifications.PingDiscordUserId must contain digits only; pings disabled")
            notifications.PingDiscordUserId = ""
        end
        if notifications.SummaryIntervalMinutes < 0 then
            notifications.SummaryIntervalMinutes = 0
        end
        notifications.MinSecondsBetweenMessages = math.max(1, notifications.MinSecondsBetweenMessages)
        config.General.TickSeconds = math.clamp(config.General.TickSeconds, 0.1, 5)
        config.Farm.HomeByRespawn = false -- Ignore saved legacy preferences: never reset the character to travel.
        config.Farm.HouseDoorExit = true
        config.Logging.FlushSeconds = math.clamp(config.Logging.FlushSeconds, 1, 60)
        config.Farm.MaxConsecutiveFailures = math.clamp(math.floor(config.Farm.MaxConsecutiveFailures), 1, 10)
        config.Farm.FailureCooldownSeconds = math.clamp(config.Farm.FailureCooldownSeconds, 1, 120)
        config.Farm.DisableMinutes = math.clamp(config.Farm.DisableMinutes, 0, 1440)
        config.Farm.Event.PetPenSlots = math.clamp(math.floor(config.Farm.Event.PetPenSlots), 1, 12)
        config.Farm.MaxBuysPerSession = math.clamp(math.floor(config.Farm.MaxBuysPerSession), 0, 1000)
        config.Farm.MaxEggBuysPerSession = math.clamp(math.floor(config.Farm.MaxEggBuysPerSession), 0, 1000)
        config.Farm.Event.PetPenMinutes = math.clamp(config.Farm.Event.PetPenMinutes, 1, 120)
        config.Farm.Event.CandyPets.KeepCandy = math.max(0, config.Farm.Event.CandyPets.KeepCandy)
        config.Farm.StuckRecovery.Seconds = math.clamp(config.Farm.StuckRecovery.Seconds, 60, 3600)
        config.Farm.StuckRejoinSeconds = math.clamp(config.Farm.StuckRejoinSeconds, 120, 3600)
        config.Farm.AutoPotions.BuffMinutes = math.clamp(config.Farm.AutoPotions.BuffMinutes, 0, 1440)
        config.Farm.MultiNeed.GapSeconds = math.clamp(config.Farm.MultiNeed.GapSeconds, 1, 120)
        if config.Farm.PetOrder ~= "oldest" and config.Farm.PetOrder ~= "youngest" then config.Farm.PetOrder = "youngest" end
        if not table.find({ "door", "teleport", "walk" }, config.Farm.SpotTravel) then config.Farm.SpotTravel = "teleport" end
        return config, warnings
    end
    return Config
end
__moduleSources["Core/Logger"] = function(...)
    local import = ...
    local Enums = import("Core/Enums")
    local Signal = import("Core/Signal")
    local Util = import("Core/Util")
    local Logger = {}
    Logger.__index = Logger
    function Logger.new(loggingConfig)
        local self = setmetatable({}, Logger)
        self._config = loggingConfig
        self._consoleRank = Enums.LogLevelRank[loggingConfig.ConsoleLevel]
        self._fileRank = Enums.LogLevelRank[loggingConfig.FileLevel]
        self._pendingFileLines = {}
        self._fileContent = {}
        self._bytesWritten = 0
        self._appendChecksLeft = 3
        self._appendBroken = false
        self._linesWritten = 0
        self._fileDisabledReason = nil
        self._lastKey = nil
        self._lastTime = 0
        self._repeatCount = 0
        self._lastLevel = nil
        self._lastCategory = nil
        self.Counts = { DEBUG = 0, INFO = 0, SUCCESS = 0, WARN = 0, ERROR = 0 }
        self.OnEntry = Signal.new("Logger.OnEntry")
        self._fileApi = Util.fileApi()
        self._filePath = nil
        if loggingConfig.FileEnabled then
            if not self._fileApi.canWrite then
                self._fileDisabledReason = "writefile unavailable"
            elseif not Util.ensureFolder(loggingConfig.Folder) then
                self._fileDisabledReason = "could not create folder " .. loggingConfig.Folder
            else
                local okName, playerName = pcall(function()
                    return game:GetService("Players").LocalPlayer.Name
                end)
                local who = (okName and type(playerName) == "string") and (string.gsub(playerName, "[^%w_]", "") .. "_") or ""
                self._filePath = loggingConfig.Folder .. "/session_" .. who .. os.date("%Y%m%d_%H%M%S") .. ".log"
            end
        else
            self._fileDisabledReason = "disabled in config"
        end
        return self
    end
    function Logger:getFilePath()
        return self._filePath, self._fileDisabledReason
    end
    local function formatLine(level, category, message)
        return string.format("[%s][%s][%s] %s", os.date("%H:%M:%S"), level, category, message)
    end
    function Logger:_output(level, category, message)
        local line = formatLine(level, category, message)
        local rank = Enums.LogLevelRank[level]
        local consoleRank = Enums.LogLevelRank[string.upper(tostring(self._config.ConsoleLevel))] or self._consoleRank
        if self._reporting then
            consoleRank = math.min(consoleRank, Enums.LogLevelRank.INFO)
        end
        if rank >= consoleRank then
            if rank >= Enums.LogLevelRank.WARN then
                warn(line)
            else
                print(line)
            end
        end
        if self._filePath and rank >= self._fileRank then
            if self._linesWritten < self._config.MaxLinesPerSession then
                table.insert(self._pendingFileLines, line)
                self._linesWritten += 1
            elseif self._linesWritten == self._config.MaxLinesPerSession then
                table.insert(self._pendingFileLines, formatLine("WARN", "Logger", "Line limit reached; file logging stopped for this session"))
                self._linesWritten += 1
            end
        end
    end
    function Logger:_flushRepeats()
        if self._repeatCount > 0 then
            self:_output(self._lastLevel, self._lastCategory, string.format("(previous message repeated %d more times)", self._repeatCount))
            self._repeatCount = 0
        end
    end
    function Logger:log(level, category, message, fields)
        assert(Enums.LogLevelRank[level], "Unknown log level: " .. tostring(level))
        category = tostring(category or "General")
        message = tostring(message)
        self.Counts[level] += 1
        local key = level .. "|" .. category .. "|" .. message
        local now = Util.now()
        if key == self._lastKey and (now - self._lastTime) < self._config.DuplicateWindowSeconds then
            self._repeatCount += 1
            return
        end
        self:_flushRepeats()
        self._lastKey, self._lastTime = key, now
        self._lastLevel, self._lastCategory = level, category
        self:_output(level, category, message)
        -- v2.1.4 (user: "the logs are off by default, these users cannot turn them on"): the last lines are always kept
        -- in memory (nothing is sent or saved by this) for the Support tab's "Copy problem report" and the white-screen
        -- report file
        if level ~= "DEBUG" then
            self.Recent = self.Recent or {}
            table.insert(self.Recent, string.format("%s %s [%s] %s", os.date("%H:%M:%S"), level, category,
                Util.truncate(message, 300)))
            if #self.Recent > 120 then
                table.remove(self.Recent, 1)
            end
        end
        self.OnEntry:Fire(level, category, message, fields)
    end
    -- header (set by main: version, executor, place) + the last lines; for a user to paste to the developer
    function Logger:problemReport()
        local head = ""
        if type(self.reportHeader) == "function" then
            local ok, text = pcall(self.reportHeader)
            head = ok and type(text) == "string" and (text .. "\n") or ""
        end
        return head .. string.format("Warnings %d, errors %d\n", self.Counts.WARN, self.Counts.ERROR)
            .. table.concat(self.Recent or {}, "\n")
    end
    Logger.PROBLEM_FILE = "AdoptMeFarm/problem_report.txt"
    function Logger:saveProblemReport()
        return false, "Disk access disabled; use ProblemReport() for an in-memory report"
    end
    function Logger:report(category, message)
        local saved = self._consoleRank
        self._consoleRank = math.min(saved, Enums.LogLevelRank.INFO)
        self._reporting = true
        self:info(category, message)
        self._reporting = false
        self._consoleRank = saved
    end
    function Logger:debug(category, message, fields)
        self:log(Enums.LogLevel.DEBUG, category, message, fields)
    end
    function Logger:info(category, message, fields)
        self:log(Enums.LogLevel.INFO, category, message, fields)
    end
    function Logger:success(category, message, fields)
        self:log(Enums.LogLevel.SUCCESS, category, message, fields)
    end
    function Logger:warn(category, message, fields)
        self:log(Enums.LogLevel.WARN, category, message, fields)
    end
    function Logger:error(category, message, fields)
        self:log(Enums.LogLevel.ERROR, category, message, fields)
    end
    function Logger:flush()
        self._pendingFileLines = {} -- Console and in-memory report only.
    end
    function Logger:close()
        self:_flushRepeats()
        self:flush()
        self.OnEntry:DisconnectAll()
    end
    return Logger
end
__moduleSources["Core/State"] = function(...)
    local import = ...
    local Signal = import("Core/Signal")
    local Util = import("Core/Util")
    local State = {}
    State.__index = State
    function State.new()
        local self = setmetatable({}, State)
        self._values = {}
        self._meta = {}
        self.Changed = Signal.new("State.Changed")
        return self
    end
    local function isSameValue(a, b)
        if a == b then
            return true
        end
        if type(a) ~= "table" or type(b) ~= "table" then
            return false
        end
        for key, value in pairs(a) do
            if b[key] ~= value then
                return false
            end
        end
        for key in pairs(b) do
            if a[key] == nil then
                return false
            end
        end
        return true
    end
    function State:set(key, value, source)
        assert(type(key) == "string" and key ~= "", "State:set needs a key")
        assert(type(source) == "string" and source ~= "", "State:set(" .. key .. ") needs a source")
        local oldValue = self._values[key]
        self._meta[key] = { source = source, updatedAt = Util.now() }
        if isSameValue(oldValue, value) then
            return false
        end
        self._values[key] = value
        self.Changed:Fire(key, value, oldValue)
        return true
    end
    function State:get(key, defaultValue)
        local value = self._values[key]
        if value == nil then
            return defaultValue
        end
        return value
    end
    function State:getMeta(key)
        return self._meta[key]
    end
    function State:increment(key, amount, source)
        local current = self._values[key] or 0
        self:set(key, current + (amount or 1), source)
        return self._values[key]
    end
    function State:age(key)
        local meta = self._meta[key]
        return meta and (Util.now() - meta.updatedAt) or nil
    end
    function State:snapshot()
        return Util.shallowCopy(self._values)
    end
    function State:destroy()
        self.Changed:DisconnectAll()
    end
    return State
end
__moduleSources["Core/Scheduler"] = function(...)
    local import = ...
    local Util = import("Core/Util")
    local Scheduler = {}
    Scheduler.__index = Scheduler
    local SLOW_JOB_SECONDS = 2
    local MAX_CONSECUTIVE_FAILURES = 5
    function Scheduler.new(logger, tickSeconds)
        local self = setmetatable({}, Scheduler)
        self._logger = logger
        self._tickSeconds = tickSeconds
        self._jobs = {}
        self._order = {}
        self._running = false
        self._paused = false
        self._thread = nil
        self.TickCount = 0
        return self
    end
    function Scheduler:addJob(name, intervalSeconds, callback, options)
        assert(type(name) == "string", "job name must be a string")
        assert(type(callback) == "function", "job callback must be a function")
        assert(self._jobs[name] == nil, "job already exists: " .. name)
        options = options or {}
        self._jobs[name] = {
            name = name,
            interval = math.max(0, intervalSeconds),
            callback = callback,
            nextRun = options.runImmediately and 0 or (Util.now() + intervalSeconds),
            failures = 0,
            enabled = true,
            runs = 0,
        }
        table.insert(self._order, name)
    end
    function Scheduler:removeJob(name)
        local job = self._jobs[name]
        if job and job.thread then pcall(task.cancel, job.thread) end
        self._jobs[name] = nil
        for index, jobName in ipairs(self._order) do
            if jobName == name then
                table.remove(self._order, index)
                break
            end
        end
    end
    function Scheduler:getJob(name)
        return self._jobs[name]
    end
    function Scheduler:_runJob(job, now)
        if job.running then return end
        job.running = true
        job.startedAt = Util.now()
        job.nextRun = now + job.interval
        job.thread = task.spawn(function()
            local ok, err = pcall(job.callback, now)
            job.running = false
            job.runs += 1
            job.nextRun = Util.now() + job.interval
            if ok then job.failures = 0; return end
            job.failures += 1
            job.nextRun = Util.now() + math.min(60, math.max(1, job.interval) * 2 ^ math.min(job.failures, 5))
            self._logger:error("Scheduler", string.format("Job '%s' failed (%d): %s; retry scheduled", job.name, job.failures, tostring(err)))
        end)
    end
    function Scheduler:_tick()
        self.TickCount += 1
        local now = Util.now()
        for _, name in ipairs(table.clone(self._order)) do
            if not self._running or self._paused then
                return
            end
            local job = self._jobs[name]
            if job and job.running and now - job.startedAt > 30 then
                if job.thread then pcall(task.cancel, job.thread) end
                job.running = false
                job.nextRun = now + math.max(1, job.interval)
                self._logger:warn("Scheduler", "Timed out job: " .. job.name)
            end
            if job and job.enabled and not job.running and now >= job.nextRun then
                self:_runJob(job, now)
            end
        end
    end
    function Scheduler:start()
        if self._running then
            return
        end
        self._running = true
        self._paused = false
        self._thread = task.spawn(function()
            while self._running do
                if not self._paused then
                    self:_tick()
                end
                task.wait(self._tickSeconds)
            end
        end)
        self._logger:info("Scheduler", string.format("Started (tick %.2f s, %d jobs)", self._tickSeconds, #self._order))
    end
    function Scheduler:pause()
        self._paused = true
        self._logger:info("Scheduler", "Paused")
    end
    function Scheduler:resume()
        self._paused = false
        self._logger:info("Scheduler", "Resumed")
    end
    function Scheduler:isRunning()
        return self._running and not self._paused
    end
    function Scheduler:stop()
        if not self._running then
            return
        end
        self._running = false
        local thread = self._thread
        self._thread = nil
        if thread and coroutine.running() ~= thread then
            pcall(task.cancel, thread)
        end
        for _, job in pairs(self._jobs) do
            if job.thread and job.thread ~= coroutine.running() then pcall(task.cancel, job.thread) end
            job.running = false
        end
        self._logger:info("Scheduler", "Stopped")
    end
    return Scheduler
end
__moduleSources["Services/Disclosure"] = function(...)
    local import = ...
    local Config = import("Core/Config")
    local Disclosure = {}
    Disclosure.VERSION = "Local Stable 1.5 (attached base 2.1.6)"
    function Disclosure.isAllowedField(field) return false end
    function Disclosure.featureSummary(config)
        local on, total = Config.countFeatures(config)
        return tostring(on) .. " / " .. tostring(total)
    end
    function Disclosure.buildStartLine(config, ignored)
        return "PRIVATE BUILD | Developer telemetry OFF | Discord webhooks OFF | Remote code OFF | Local interface"
    end
    function Disclosure.buildShortText()
        return "PRIVATE BUILD: no Discord webhooks or developer data transfer"
    end
    function Disclosure.buildStartLines(config, files, webhook, telemetry, launch)
        return {
            "AdoptMe Local Stable 1.5 | source from attached Adopt Victims base 2.1.6",
            "External HTTP: disabled (no request function, no game:HttpGet, no loadstring)",
            "External UI library: removed; Roblox-native local interface",
            "Remote notifications/telemetry/squad relay: disabled",
            "Local log and session files: disabled; GUI preferences are not persisted",
            "Farm still uses Adopt Me's own in-game remotes, when enabled",
            "Farm features on: " .. Disclosure.featureSummary(config),
            "No Owner/UserId configuration is required",
            "Risk: automation may breach Roblox / Adopt Me rules and cause sanctions",
        }
    end
    function Disclosure.buildLines(config, files, webhook, launch, actions, telemetry)
        local lines = {
            "=== PRIVATE SECURITY STATUS ===",
            "This file provides no login-credential access; external runtime safety was not tested.",
            "Outbound HTTP to third parties is blocked within this file.",
            "Only one local Roblox-native GUI is used; no external JavaScript/Luau downloaded.",
            "Game actions are local game automation (not a guarantee against game bans).",
            "To stop: getgenv().AdoptMeFarm.Stop()",
        }
        if actions then
            for _, action in ipairs(actions) do
                table.insert(lines, "Game remote: " .. tostring(action))
            end
        end
        return lines
    end
    return Disclosure
end
__moduleSources["Services/Notifier"] = function(...)
    -- Explicitly inert notifier; does not assemble or transmit user data.
    local Notifier = {}
    Notifier.__index = Notifier
    function Notifier.new()
        return setmetatable({ SentCount = 0, DroppedCount = 0 }, Notifier)
    end
    function Notifier:isEnabled() return false end
    function Notifier:getStatusText() return "OFF: private local build, no Discord webhooks" end
    function Notifier:notify(...) return false end
    function Notifier:pump(...) return false end
    function Notifier:pendingCount() return 0 end
    function Notifier:flush(...) return true end
    return Notifier
end
__moduleSources["Services/SessionWatcher"] = function(...)
    local import = ...
    local Enums = import("Core/Enums")
    local GuiService = game:GetService("GuiService")
    local SessionWatcher = {}
    function SessionWatcher.start(maid, logger, notifier, state, sessionStore)
        local okSignal, errorSignal = pcall(function()
            return GuiService.ErrorMessageChanged
        end)
        if not okSignal or errorSignal == nil then
            logger:warn("Session", "GuiService.ErrorMessageChanged unavailable; kick detection is off")
            return false
        end
        local lastReported = nil
        maid:Give(errorSignal:Connect(function(messageArgument)
            local message = type(messageArgument) == "string" and messageArgument or ""
            if message == "" then
                pcall(function()
                    message = GuiService:GetErrorMessage()
                end)
            end
            if type(message) ~= "string" or message == "" or message == lastReported then
                return
            end
            lastReported = message
            state:set("session.disconnectReason", message, "SessionWatcher")
            if sessionStore then
                sessionStore:recordMessage(message)
            end
            logger:warn("Session", "Roblox disconnect/kick message: " .. message)
            logger:flush()
            notifier:notify(Enums.NotifyEvent.Kicked, { { name = "Reason", value = message } })
            notifier:pump()
        end))
        logger:debug("Session", "Kick detection active")
        return true
    end
    return SessionWatcher
end
__moduleSources["Services/SessionStore"] = function(...)
    local SessionStore = {}
    SessionStore.__index = SessionStore
    function SessionStore.new() return setmetatable({}, SessionStore) end
    function SessionStore:isAvailable() return false end
    function SessionStore:begin() return nil end
    function SessionStore:heartbeat() end
    function SessionStore:recordMessage(message) end
    function SessionStore:markCleanStop() end
    function SessionStore.describe() return "Session files disabled" end
    return SessionStore
end
__moduleSources["Services/Telemetry"] = function(...)
    -- Deliberately no inventory aggregation, no logs sent, no HTTP functionality.
    local Telemetry = {}
    Telemetry.__index = Telemetry
    function Telemetry.new()
        return setmetatable({}, Telemetry)
    end
    function Telemetry.isAllowedUrl() return false end
    function Telemetry:isEnabled() return false end
    function Telemetry:statusText() return "OFF permanently (private local build)" end
    function Telemetry:setDiagnostics(...) end
    function Telemetry:setGameData(...) end
    function Telemetry:start(...) end
    function Telemetry:pump(...) return false end
    return Telemetry
end
__moduleSources["Services/Lang"] = function(...)
    local Lang = {}
    Lang.LANGUAGES = {
        { code = "en", name = "English", country = "GB" },
        { code = "tr", name = "Türkçe", country = "TR" },
        { code = "es", name = "Español", country = "ES" },
        { code = "pt", name = "Português", country = "BR" },
    }
    Lang.COUNTRY = {
        TR = "tr", CY = "tr",
        ES = "es", MX = "es", AR = "es", CO = "es", CL = "es", PE = "es", VE = "es", EC = "es", GT = "es", CU = "es",
        BO = "es", DO = "es", HN = "es", PY = "es", SV = "es", NI = "es", CR = "es", PA = "es", UY = "es", PR = "es",
        GQ = "es",
        BR = "pt", PT = "pt", AO = "pt", MZ = "pt", CV = "pt", GW = "pt", ST = "pt", TL = "pt",
    }
    Lang.current = "en"
    function Lang.flag(country)
        country = string.upper(tostring(country or ""))
        if not string.match(country, "^%u%u$") then
            return ""
        end
        return utf8.char(0x1F1E6 + string.byte(country, 1) - 65, 0x1F1E6 + string.byte(country, 2) - 65)
    end
    function Lang.info(code)
        for _, language in ipairs(Lang.LANGUAGES) do
            if language.code == code then
                return language
            end
        end
        return nil
    end
    function Lang.pick(setting, country, locale)
        if type(setting) == "string" and setting ~= "Auto" and Lang.info(setting) then
            return setting
        end
        local fromCountry = Lang.COUNTRY[string.upper(tostring(country or ""))]
        if fromCountry then
            return fromCountry
        end
        local fromLocale = string.match(string.lower(tostring(locale or "")), "^(%a%a)")
        if fromLocale and Lang.info(fromLocale) then
            return fromLocale
        end
        return "en"
    end
    function Lang.use(code)
        Lang.current = Lang.info(code) and code or "en"
        return Lang.current
    end
    local S = {}
    Lang.STRINGS = S
    local function add(en, tr, es, pt)
        S[en] = { tr = tr, es = es, pt = pt }
    end
    add("Farm", "Çiftlik", "Granja", "Fazenda")
    add("Setup", "Kurulum", "Ajustes", "Ajustes")
    add("Support", "Destek", "Apoyo", "Apoio")
    add("Main", "Ana sayfa", "Principal", "Principal")
    add("Event", "Etkinlik", "Evento", "Evento")
    add("Webhook", "Webhook", "Webhook", "Webhook")
    add("Config", "Ayarlar", "Config", "Config")
    add("Dashboard", "Panel", "Panel", "Painel")
    add("Farm status", "Çiftlik durumu", "Estado de la granja", "Status da fazenda")
    add("2 pets at once (2-pet perk)", "Aynı anda 2 pet (2 pet özelliği)", "2 mascotas a la vez (ventaja)", "2 pets ao mesmo tempo (vantagem)")
    add("Ghost Gallery: playing now", "Ghost Gallery: şu an oynanıyor", "Ghost Gallery: jugando ahora", "Ghost Gallery: jogando agora")
    add(" (after the Hauntlet)", " (Hauntlet'ten sonra)", " (tras el Hauntlet)", " (depois do Hauntlet)")
    add(" (resting)", " (dinleniyor)", " (en pausa)", " (em pausa)")
    add("Hauntlet: off", "Hauntlet: kapalı", "Hauntlet: apagado", "Hauntlet: desligado")
    add("Hauntlet: in the run (room %d)", "Hauntlet: oyunda (oda %d)", "Hauntlet: en la partida (sala %d)", "Hauntlet: na partida (sala %d)")
    add("Hauntlet: joined, starting", "Hauntlet: katıldı, başlıyor", "Hauntlet: unido, empieza", "Hauntlet: entrou, começando")
    add("Hauntlet: going to the join circle", "Hauntlet: katılma dairesine gidiyor", "Hauntlet: yendo al círculo", "Hauntlet: indo ao círculo")
    add("Hauntlet: in %s", "Hauntlet: %s sonra", "Hauntlet: en %s", "Hauntlet: em %s")
    add(" (one round after the last run)", " (son run'dan bir tur sonra)", " (una ronda tras la última)", " (uma rodada após a última)")
    add("Hauntlet: waiting for the game's timer", "Hauntlet: oyunun sayacı bekleniyor", "Hauntlet: esperando el temporizador", "Hauntlet: aguardando o timer")
    add("Quick actions", "Hızlı işlemler", "Acciones rápidas", "Ações rápidas")
    add("Auto tasks", "Otomatik görevler", "Tareas automáticas", "Tarefas automáticas")
    add("Pet Pen", "Pet Ağılı", "Corral", "Cercadinho")
    add("Auto needs", "Otomatik ihtiyaçlar", "Necesidades automáticas", "Necessidades automáticas")
    add("Pets", "Petler", "Mascotas", "Pets")
    add("Potions & neon", "İksirler ve neon", "Pociones y neón", "Poções e neon")
    add("Halloween 2026", "Cadılar Bayramı 2026", "Halloween 2026", "Halloween 2026")
    add("Crypt", "Mahzen", "Cripta", "Cripta")
    add("Candy Shop", "Şeker Dükkanı", "Tienda de dulces", "Loja de doces")
    add("Event status", "Etkinlik durumu", "Estado del evento", "Status do evento")
    add("Discord webhook", "Discord webhook", "Webhook de Discord", "Webhook do Discord")
    add("Messages", "Mesajlar", "Mensajes", "Mensagens")
    add("Configs", "Kayıtlı ayarlar", "Configuraciones", "Configurações")
    add("Settings", "Genel", "Opciones", "Opções")
    add("Presets by the developer", "Geliştiricinin hazır ayarları", "Ajustes del desarrollador", "Predefinições do desenvolvedor")
    add("Advanced", "Gelişmiş", "Avanzado", "Avançado")
    add("Developer", "Geliştirici", "Desarrollador", "Desenvolvedor")
    add("Changelog", "Yenilikler", "Novedades", "Novidades")
    add("Executor", "Executor", "Executor", "Executor")
    add("Donate", "Bağış", "Donar", "Doar")
    add("Game passes", "Oyun geçişleri", "Pases de juego", "Passes de jogo")
    add("Crypto (tap to copy)", "Kripto (kopyalamak için dokun)", "Cripto (toca para copiar)", "Cripto (toque para copiar)")
    add("Discord", "Discord", "Discord", "Discord")
    add("Farm running", "Çiftlik çalışıyor", "Granja activa", "Fazenda ligada")
    add("Go home", "Eve git", "Ir a casa", "Ir para casa")
    add("Skip current task", "Şu anki görevi atla", "Saltar tarea actual", "Pular tarefa atual")
    add("Retry resting tasks", "Dinlenen görevleri dene", "Reintentar tareas en pausa", "Tentar tarefas em pausa")
    add("Stop the farm", "Çiftliği durdur", "Detener la granja", "Parar a fazenda")
    add("Claim quests", "Görevleri topla", "Reclamar misiones", "Resgatar missões")
    add("Visit homes for quests", "Görev için ev ziyareti", "Visitar casas (misiones)", "Visitar casas (missões)")
    add("Collect cashback", "Para iadesini topla", "Cobrar reembolso", "Coletar cashback")
    add("Open gifts and chests", "Hediye ve sandık aç", "Abrir regalos y cofres", "Abrir presentes e baús")
    add("Auto Pet Pen", "Otomatik Pet Ağılı", "Corral automático", "Cercadinho automático")
    add("Claim every", "Toplama aralığı", "Reclamar cada", "Coletar a cada")
    add("Keep it full (buys eggs)", "Dolu tut (yumurta alır)", "Mantener lleno (compra huevos)", "Manter cheio (compra ovos)")
    add("Claim Pet Pen now", "Pet Ağılını şimdi topla", "Reclamar corral ahora", "Coletar cercadinho agora")
    add("Baby needs too", "Bebek ihtiyaçları da", "También bebés", "Bebês também")
    add("Skip these needs", "Bu ihtiyaçları atla", "Saltar estas necesidades", "Pular estas necessidades")
    add("Keep growing pet equipped", "Büyüyen pet hep elde", "Mascota en crecimiento equipada", "Manter pet crescendo equipado")
    add("Farm first", "Önce bunları besle", "Primero estas", "Primeiro estes")
    add("Buy an egg if none grows", "Büyüyen yoksa yumurta al", "Comprar huevo si nada crece", "Comprar ovo se nada cresce")
    add("Egg to buy", "Alınacak yumurta", "Huevo a comprar", "Ovo para comprar")
    add("Use potions", "İksir kullan", "Usar pociones", "Usar poções")
    add("Don't use", "Kullanma", "No usar", "Não usar")
    add("Auto neon pets", "Otomatik neon pet", "Mascotas neón automáticas", "Pets neon automáticos")
    add("Auto mega neon pets", "Otomatik mega neon pet", "Mega neón automático", "Mega neon automático")
    add("Ghost Gallery", "Hayalet Galerisi", "Galería de fantasmas", "Galeria dos fantasmas")
    add("Auto Stray Cat", "Otomatik sokak kedisi", "Gato callejero automático", "Gato de rua automático")
    add("Use Rusty Keys", "Paslı anahtarları kullan", "Usar llaves oxidadas", "Usar chaves enferrujadas")
    add("Open", "Aç", "Abrir", "Abrir")
    add("Give twigs to the nest", "Dalları yuvaya götür", "Llevar ramitas al nido", "Levar gravetos ao ninho")
    add("Auto buy", "Otomatik satın al", "Compra automática", "Compra automática")
    add("Buy", "Satın al", "Comprar", "Comprar")
    add("Your event", "Etkinliğin", "Tu evento", "Seu evento")
    add("Webhook URL", "Webhook adresi", "URL del webhook", "URL do webhook")
    add("User ID", "Kullanıcı ID", "ID de usuario", "ID de usuário")
    add("Ping me", "Beni etiketle", "Mencionarme", "Me mencionar")
    add("Ping me on", "Şunlarda etiketle", "Mencionarme en", "Me mencionar em")
    add("Send summary", "Özet gönder", "Enviar resumen", "Enviar resumo")
    add("Summary every", "Özet aralığı", "Resumen cada", "Resumo a cada")
    add("Send test message", "Test mesajı gönder", "Enviar mensaje de prueba", "Enviar mensagem de teste")
    add("Each finished need", "Biten her ihtiyaç", "Cada necesidad hecha", "Cada necessidade feita")
    add("Kick / disconnect", "Atılma / bağlantı kopması", "Expulsión / desconexión", "Expulsão / desconexão")
    add("Errors", "Hatalar", "Errores", "Erros")
    add("Start / stop", "Başlat / durdur", "Inicio / parada", "Início / parada")
    add("Show my Roblox name", "Roblox adımı göster", "Mostrar mi nombre de Roblox", "Mostrar meu nome do Roblox")
    add("Alerts URL", "Uyarı adresi", "URL de alertas", "URL de alertas")
    add("Config name", "Kayıt adı", "Nombre", "Nome")
    add("Saved configs", "Kayıtlı ayarlar", "Configuraciones guardadas", "Configurações salvas")
    add("Save as new config", "Yeni kayıt olarak sakla", "Guardar como nueva", "Salvar como nova")
    add("Overwrite selected", "Seçilenin üzerine yaz", "Sobrescribir seleccionada", "Sobrescrever selecionada")
    add("Load selected", "Seçileni yükle", "Cargar seleccionada", "Carregar selecionada")
    add("Delete selected", "Seçileni sil", "Borrar seleccionada", "Apagar selecionada")
    add("Autosave", "Otomatik kaydet", "Guardado automático", "Salvamento automático")
    add("Autoload selected", "Seçileni açılışta yükle", "Cargar al iniciar", "Carregar ao iniciar")
    add("Anti-AFK", "Anti-AFK", "Anti-AFK", "Anti-AFK")
    add("Auto click Play (menu)", "Menüde Play'e otomatik bas", "Pulsar Play en el menú", "Clicar em Play no menu")
    add("Camera guard", "Kamera koruması", "Protector de cámara", "Proteção da câmera")
    add("Event pop-ups", "Olay bildirimleri", "Avisos de eventos", "Avisos de eventos")
    add("Autoclose GUI on execute", "Açılışta pencereyi gizle", "Ocultar ventana al ejecutar", "Ocultar janela ao executar")
    add("Theme", "Tema", "Tema", "Tema")
    add("UI scale", "Arayüz boyutu", "Tamaño de la interfaz", "Tamanho da interface")
    add("How big the window is drawn (Auto: smaller on phones)", "Pencerenin boyutu (Otomatik: telefonda daha küçük)", "Tamaño de la ventana (Automático: más pequeña en móviles)", "Tamanho da janela (Automático: menor no celular)")
    add("Language", "Dil", "Idioma", "Idioma")
    add("Hide / show key", "Gizle / göster tuşu", "Tecla mostrar / ocultar", "Tecla mostrar / ocultar")
    add("Help lines", "Yardım satırları", "Líneas de ayuda", "Linhas de ajuda")
    add("Reset to loader settings", "Loader ayarlarına dön", "Volver a los ajustes del loader", "Voltar às opções do loader")
    add("What this script does (report)", "Bu script ne yapıyor (rapor)", "Qué hace este script (informe)", "O que este script faz (relatório)")
    add("Closed the window?", "Pencereyi kapattın mı?", "¿Cerraste la ventana?", "Fechou a janela?")
    add("Needs doable here first", "Burada yapılabilenler önce", "Primero lo que se hace aquí", "Primeiro o que dá pra fazer aqui")
    add("Stuck recovery (go home)", "Takılınca kurtar (eve git)", "Recuperar si se atasca (a casa)", "Recuperar se travar (ir pra casa)")
    add("Stuck after", "Takılmış sayılma", "Atascado tras", "Travado após")
    add("Rejoin when stuck", "Takılınca yeniden katıl", "Reunirse si se atasca", "Reentrar se travar")
    add("Rejoin after", "Yeniden katılma", "Reunirse tras", "Reentrar após")
    add("Game travel (doors)", "Oyunun kapılarıyla git", "Viajar por puertas", "Viajar pelas portas")
    add("Go home by respawn", "Eve respawn ile git", "Ir a casa reapareciendo", "Ir pra casa renascendo")
    add("Food bowl trips", "Mama kabı yolculukları", "Viajes al plato", "Idas ao pote de comida")
    add("Camp / beach", "Kamp / plaj", "Campamento / playa", "Acampamento / praia")
    add("Retry failed after", "Başarısızı tekrar deneme", "Reintentar fallidas tras", "Tentar falhas após")
    add("Fails before rest", "Dinlenmeden önce hata", "Fallos antes de pausar", "Falhas antes da pausa")
    add("Rest for", "Dinlenme süresi", "Pausa de", "Pausa de")
    add("Console shows", "Konsolda göster", "La consola muestra", "O console mostra")
    add("Copy Discord invite", "Discord davetini kopyala", "Copiar invitación de Discord", "Copiar convite do Discord")
    add("Copy GitHub link", "GitHub bağlantısını kopyala", "Copiar enlace de GitHub", "Copiar link do GitHub")
    add("Your setup", "Kurulumun", "Tu equipo", "Seu sistema")
    add("Correct network only", "Sadece doğru ağ", "Solo la red correcta", "Somente a rede certa")
    add("Auto", "Otomatik", "Automático", "Automático")
    add("Pet me", "Sev beni", "Acaríciame", "Me acaricie")
    add("Hungry", "Aç", "Hambre", "Fome")
    add("Thirsty", "Susamış", "Sed", "Sede")
    add("Play", "Oyun", "Jugar", "Brincar")
    add("Sleepy", "Uykulu", "Sueño", "Sono")
    add("Dirty", "Kirli", "Sucio", "Sujo")
    add("Toilet", "Tuvalet", "Baño", "Banheiro")
    add("Walk", "Yürüyüş", "Paseo", "Passeio")
    add("Ride", "Gezinti", "Paseo en carrito", "Passeio de carrinho")
    add("Mystery card", "Gizemli kart", "Carta misteriosa", "Carta misteriosa")
    add("Salon", "Kuaför", "Salón", "Salão")
    add("Cat Cafe", "Kedi Kafe", "Café de gatos", "Café dos gatos")
    add("Pizza party", "Pizza partisi", "Fiesta de pizza", "Festa da pizza")
    add("School", "Okul", "Escuela", "Escola")
    add("Sick", "Hasta", "Enfermo", "Doente")
    add("Camping", "Kamp", "Campamento", "Acampamento")
    add("Beach party", "Plaj partisi", "Fiesta en la playa", "Festa na praia")
    add("Bored", "Sıkılmış", "Aburrido", "Entediado")
    add("Age-Up Potion", "Yaş İksiri", "Poción de edad", "Poção de idade")
    add("Tiny Age-Up Potion", "Küçük Yaş İksiri", "Poción de edad pequeña", "Poção de idade pequena")
    add("Bucks Potion", "Bucks İksiri", "Poción de Bucks", "Poção de Bucks")
    add("Next floor (Mummy Spider)", "Sonraki kat (Mumya Örümcek)", "Siguiente piso (Araña momia)", "Próximo andar (Aranha múmia)")
    add("Twig", "Dal", "Ramita", "Graveto")
    add("Big candy pile", "Büyük şeker yığını", "Montón grande de dulces", "Pilha grande de doces")
    add("Small candy pile", "Küçük şeker yığını", "Montón pequeño de dulces", "Pilha pequena de doces")
    add("Cracked Egg (350 Bucks)", "Çatlak Yumurta (350 Bucks)", "Huevo agrietado (350 Bucks)", "Ovo rachado (350 Bucks)")
    add("Pet Egg (600 Bucks)", "Pet Yumurtası (600 Bucks)", "Huevo de mascota (600 Bucks)", "Ovo de pet (600 Bucks)")
    add("Fairytale Egg (event)", "Masal Yumurtası (etkinlik)", "Huevo de cuento (evento)", "Ovo de conto (evento)")
    add("Summaries", "Özetler", "Resúmenes", "Resumos")
    add("Finished needs", "Biten ihtiyaçlar", "Necesidades hechas", "Necessidades feitas")
    add("Stopped", "Durduruldu", "Detenido", "Parado")
    add("Last run ended badly", "Son çalışma kötü bitti", "La última sesión terminó mal", "A última sessão terminou mal")
    add("Neon pets", "Neon petler", "Mascotas neón", "Pets neon")
    add("Oldest pets (closest to grown)", "En yaşlı petler (büyümeye yakın)", "Las más viejas (casi adultas)", "Os mais velhos (quase adultos)")
    add("Teleport", "Işınlan", "Teletransporte", "Teleporte")
    add("Shop door", "Dükkan kapısı", "Puerta de la tienda", "Porta da loja")
    add("Nothing skipped: every need", "Hiçbiri atlanmıyor: her ihtiyaç", "Nada saltado: todas", "Nada pulado: todas")
    add("Any growing pet (youngest first)", "Büyüyen herhangi bir pet (en genç önce)", "Cualquiera que crezca (la más joven primero)", "Qualquer pet crescendo (o mais novo primeiro)")
    add("Using every potion", "Her iksir kullanılıyor", "Usando todas las pociones", "Usando todas as poções")
    add("Pick what to buy", "Alınacakları seç", "Elige qué comprar", "Escolha o que comprar")
    add("No pings", "Etiket yok", "Sin menciones", "Sem menções")
    add("Pick a saved config", "Kayıtlı bir ayar seç", "Elige una configuración", "Escolha uma configuração")
    add("e.g. main farm", "ör. ana çiftlik", "ej. granja principal", "ex. fazenda principal")
    add("digits, e.g. 123456789012345678", "rakamlar, ör. 123456789012345678", "dígitos, ej. 123456789012345678", "dígitos, ex. 123456789012345678")
    add("errors / kicks go here; empty = the main one", "hatalar / atılmalar buraya; boş = ana adres", "errores / expulsiones aquí; vacío = el principal", "erros / expulsões aqui; vazio = o principal")
    add("Stops the running task and goes home (respawn first).", "Çalışan görevi durdurur ve eve gider (önce respawn).", "Detiene la tarea y va a casa (reaparece primero).", "Para a tarefa e vai pra casa (renasce primeiro).")
    add("Stops the running task; it is not chosen again for 90 s.", "Çalışan görevi durdurur; 90 sn tekrar seçilmez.", "Detiene la tarea; no se elige otra vez en 90 s.", "Para a tarefa; não é escolhida de novo por 90 s.")
    add("Tasks that failed 3 times in a row may run again now.", "Üst üste 3 kez başarısız olan görevler şimdi tekrar çalışabilir.", "Las tareas que fallaron 3 veces seguidas pueden volver a correr.", "Tarefas que falharam 3 vezes seguidas podem rodar de novo.")
    add("Everything stops and cleans up (run the loader again to start).", "Her şey durur ve temizlenir (başlatmak için loader'ı tekrar çalıştır).", "Todo se detiene y se limpia (ejecuta el loader para empezar).", "Tudo para e é limpo (rode o loader de novo para começar).")
    add("Claims the pen (at home), takes full grown pets out, fills it with pets that still grow", "Ağılı toplar (evde), büyümüş petleri çıkarır, büyüyenlerle doldurur", "Reclama el corral (en casa), saca las adultas y lo llena con las que crecen", "Coleta o cercadinho (em casa), tira os adultos e enche com pets crescendo")
    add("Buys eggs (Bucks) so the pen always has pets that grow; needs 'Buy an egg'", "Ağılda hep büyüyen pet olsun diye yumurta alır (Bucks); 'Yumurta al' açık olmalı", "Compra huevos (Bucks) para que el corral tenga mascotas que crecen; necesita 'Comprar huevo'", "Compra ovos (Bucks) para o cercadinho ter pets crescendo; precisa de 'Comprar ovo'")
    add("Goes home if needed and claims / refills the Pet Pen once.", "Gerekirse eve gider ve Pet Ağılını bir kez toplar / doldurur.", "Va a casa si hace falta y reclama / rellena el corral una vez.", "Vai pra casa se preciso e coleta / enche o cercadinho uma vez.")
    add("Does every pet need; pick below the ones to skip. Buys 1 food / water only when it has none.", "Her pet ihtiyacını yapar; atlanacakları aşağıdan seç. Yiyecek / su yoksa sadece 1 tane alır.", "Hace cada necesidad; elige abajo las que saltar. Compra 1 comida / agua solo si no tiene.", "Faz cada necessidade; escolha abaixo as que pular. Compra 1 comida / água só quando não tem.")
    add("Needs picked here are NOT done", "Burada seçilen ihtiyaçlar YAPILMAZ", "Las elegidas aquí NO se hacen", "As escolhidas aqui NÃO são feitas")
    add("Keeps a pet that still grows equipped; a full grown one is swapped", "Büyüyen bir peti elde tutar; büyümüş olan değiştirilir", "Mantiene equipada una mascota que crece; una adulta se cambia", "Mantém um pet crescendo equipado; um adulto é trocado")
    add("These pets get the needs, potions and Pet Pen first", "Bu petler ihtiyaç, iksir ve Pet Ağılında önceliklidir", "Estas mascotas reciben primero necesidades, pociones y corral", "Estes pets recebem primeiro necessidades, poções e cercadinho")
    add("Uses every potion that helps farming on the growing pet; pick below the ones to keep", "Farma yardım eden her iksiri büyüyen pette kullanır; saklanacakları aşağıdan seç", "Usa cada poción útil en la mascota que crece; elige abajo las que guardar", "Usa toda poção útil no pet crescendo; escolha abaixo as que guardar")
    add("Potions picked here are kept (never used)", "Burada seçilen iksirler saklanır (kullanılmaz)", "Las elegidas aquí se guardan (nunca se usan)", "As escolhidas aqui são guardadas (nunca usadas)")
    add("4 full grown pets of one kind -> 1 neon", "Aynı türden 4 büyümüş pet -> 1 neon", "4 adultas del mismo tipo -> 1 neón", "4 adultos do mesmo tipo -> 1 neon")
    add("4 full grown neons of one kind -> 1 mega neon", "Aynı türden 4 büyümüş neon -> 1 mega neon", "4 neones adultos del mismo tipo -> 1 mega neón", "4 neons adultos do mesmo tipo -> 1 mega neon")
    add("Joins every round and vacuums the ghosts (Rusty Keys)", "Her tura katılır ve hayaletleri süpürür (Paslı Anahtar)", "Entra a cada ronda y aspira fantasmas (llaves oxidadas)", "Entra em cada rodada e aspira fantasmas (chaves enferrujadas)")
    add("Opens Crypt graves with your Rusty Keys; pick below what to open", "Paslı anahtarlarla mahzen mezarlarını açar; ne açılacağını aşağıdan seç", "Abre tumbas de la cripta con tus llaves; elige abajo qué abrir", "Abre túmulos da cripta com suas chaves; escolha abaixo o que abrir")
    add("What a Rusty Key opens, in this order", "Paslı anahtarın açacakları, bu sırayla", "Lo que abre una llave, en este orden", "O que uma chave abre, nesta ordem")
    add("Has a Crypt Twig: takes it to the Hotel nest", "Mahzen dalı varsa Otel'deki yuvaya götürür", "Si tiene una ramita, la lleva al nido del hotel", "Se tiver um graveto, leva ao ninho do hotel")
    add("Buys the pets picked below with candy, as many as the candy pays for", "Aşağıda seçilen petleri şekerle, şekerin yettiği kadar alır", "Compra con dulces las mascotas elegidas, tantas como alcance", "Compra com doces os pets escolhidos, quantos der")
    add("No limit: bought whenever the candy is enough", "Sınır yok: şeker yettikçe alınır", "Sin límite: se compra cuando alcanza", "Sem limite: compra quando der")
    add("Sends one test message to your webhook.", "Webhook'una bir test mesajı gönderir.", "Envía un mensaje de prueba a tu webhook.", "Envia uma mensagem de teste para o seu webhook.")
    add("@mentions you on the messages picked below", "Aşağıda seçilen mesajlarda seni etiketler", "Te menciona en los mensajes elegidos abajo", "Menciona você nas mensagens escolhidas abaixo")
    add("Which messages @mention you", "Hangi mesajlar seni etiketlesin", "Qué mensajes te mencionan", "Quais mensagens mencionam você")
    add("A summary message (needs done, Bucks, pet) every few minutes", "Birkaç dakikada bir özet mesajı (ihtiyaçlar, Bucks, pet)", "Un resumen (necesidades, Bucks, mascota) cada pocos minutos", "Um resumo (necessidades, Bucks, pet) a cada poucos minutos")
    add("Saves every setting of the window under the name above.", "Penceredeki tüm ayarları yukarıdaki adla saklar.", "Guarda todos los ajustes con el nombre de arriba.", "Salva todas as opções com o nome acima.")
    add("Saves the current settings into the picked config.", "Şu anki ayarları seçilen kayda yazar.", "Guarda los ajustes actuales en la elegida.", "Salva as opções atuais na escolhida.")
    add("Puts the picked config's settings in place now.", "Seçilen kaydın ayarlarını şimdi uygular.", "Aplica ahora los ajustes elegidos.", "Aplica agora as opções escolhidas.")
    add("Deletes the picked config file.", "Seçilen kayıt dosyasını siler.", "Borra el archivo elegido.", "Apaga o arquivo escolhido.")
    add("On: every change in the window is kept on this device. Off: changes last until you leave; save a config instead", "Açık: penceredeki her değişiklik bu cihazda saklanır. Kapalı: oyundan çıkana kadar sürer; bunun yerine kayıt al", "Sí: cada cambio se guarda en este dispositivo. No: dura hasta salir; guarda una configuración", "Ligado: cada mudança fica salva neste aparelho. Desligado: dura até sair; salve uma configuração")
    add("At every start, the config picked above is put in place", "Her açılışta yukarıda seçilen kayıt uygulanır", "En cada inicio se aplica la configuración elegida", "A cada início a configuração escolhida é aplicada")
    add("Clicks on Roblox's idle warning (no idle kick)", "Roblox'un boşta uyarısına tıklar (atılmazsın)", "Pulsa el aviso de inactividad (sin expulsión)", "Clica no aviso de inatividade (sem expulsão)")
    add("The camera went inside your character: it is zoomed back out", "Kamera karakterinin içine girerse geri uzaklaştırılır", "Si la cámara entra en tu personaje, se aleja", "Se a câmera entrar no personagem, ela se afasta")
    add("Pop-ups for keys, neon, purchases, rounds", "Anahtar, neon, alışveriş ve tur bildirimleri", "Avisos de llaves, neón, compras, rondas", "Avisos de chaves, neon, compras, rodadas")
    add("Every change made in the window goes back to the loader's value, now and at the next start.", "Pencerede yapılan her değişiklik loader değerine döner, şimdi ve sonraki açılışta.", "Cada cambio vuelve al valor del loader, ahora y al próximo inicio.", "Cada mudança volta ao valor do loader, agora e no próximo início.")
    add("Back to the loader's settings.", "Loader ayarlarına dönüldü.", "Ajustes del loader de nuevo.", "Opções do loader de novo.")
    add("Drag, or tap the number to type a value.", "Sürükle ya da sayıya dokunup yaz.", "Arrastra o toca el número para escribirlo.", "Arraste ou toque no número para digitar.")
    add("Copies the Discord invite", "Discord davetini kopyalar", "Copia la invitación de Discord", "Copia o convite do Discord")
    add("Which language the window uses (Auto: your country's)", "Pencerenin dili (Otomatik: ülkenin dili)", "Idioma de la ventana (Automático: el de tu país)", "Idioma da janela (Automático: o do seu país)")
    add("Master switch. Off = no game actions at all", "Ana şalter. Kapalı = hiçbir oyun işlemi yok", "Interruptor principal. No = ninguna acción", "Chave geral. Desligado = nenhuma ação")
    add("Joins the Babies team to do baby needs too", "Bebek ihtiyaçları için Bebek takımına geçer", "Se une al equipo Bebés para sus necesidades", "Entra no time Bebês para as necessidades deles")
    add("While waiting at a place: food, drink, toy, petting", "Bir yerde beklerken: yemek, içecek, oyuncak, sevme", "Mientras espera: comida, bebida, juguete, caricias", "Enquanto espera: comida, bebida, brinquedo, carinho")
    add("No drink left: buys 1 water (1 Buck)", "İçecek kalmazsa 1 su alır (1 Buck)", "Sin bebida: compra 1 agua (1 Buck)", "Sem bebida: compra 1 água (1 Buck)")
    add("No food left: buys 1 sandwich / hotdog", "Yiyecek kalmazsa 1 sandviç / sosisli alır", "Sin comida: compra 1 sándwich / perrito", "Sem comida: compra 1 sanduíche / cachorro-quente")
    add("No pet out: equips a pet that still grows", "Pet yoksa büyüyen bir pet çıkarır", "Sin mascota: equipa una que crece", "Sem pet: equipa um que ainda cresce")
    add("Swaps a full grown pet for a growing one", "Büyümüş peti büyüyen biriyle değiştirir", "Cambia una adulta por una que crece", "Troca um adulto por um que cresce")
    add("Growing neon pets are farmed first", "Büyüyen neon petler önce beslenir", "Primero las neón que crecen", "Primeiro os neons crescendo")
    add("Age potions on the farmed growing pet", "Beslenen pete yaş iksiri", "Pociones de edad en la mascota", "Poções de idade no pet")
    add("4 full grown of one kind -> 1 neon", "Aynı türden 4 büyümüş -> 1 neon", "4 adultas del mismo tipo -> 1 neón", "4 adultos do mesmo tipo -> 1 neon")
    add("No growing pet left: buys 1 egg (Bucks only)", "Büyüyen pet kalmazsa 1 yumurta alır (sadece Bucks)", "Sin mascota que crezca: compra 1 huevo (solo Bucks)", "Sem pet crescendo: compra 1 ovo (só Bucks)")
    add("Opens gifts and chests in your backpack", "Çantandaki hediye ve sandıkları açar", "Abre regalos y cofres de tu mochila", "Abre presentes e baús da mochila")
    add("Master switch for every Halloween job", "Tüm Cadılar Bayramı işleri için ana şalter", "Interruptor de todo Halloween", "Chave geral do Halloween")
    add("Auto Hauntlet", "Otomatik Hauntlet", "Hauntlet automático", "Hauntlet automático")
    add("Auto Hauntlet — join runs, pick safer doors, use keys/items", "Otomatik Hauntlet — katıl, daha güvenli kapı seç, item kullan",
        "Hauntlet automático — entra, elige puertas seguras, usa llaves/objetos", "Hauntlet automático — entra, escolhe portas seguras, usa chaves/itens")
    add("Hauntlet run", "Hauntlet turu", "Partida de Hauntlet", "Partida de Hauntlet")
    add("Auto Skelicorn", "Otomatik Skelicorn", "Skelicorn automático", "Skelicorn automático")
    add("Lightning Lever from the Crypt -> machine by the Manor -> 1 Skelicorn (120k candy)",
        "Crypt'ten Şimşek Kolu -> Malikane yanındaki makine -> 1 Skelicorn (120k şeker)",
        "Palanca del Rayo de la Cripta -> máquina junto a la Mansión -> 1 Skelicorn (120k dulces)",
        "Alavanca do Raio da Cripta -> máquina perto da Mansão -> 1 Skelicorn (120k doces)")
    add("Hauntlet before Ghost Gallery", "Hauntlet, Ghost Gallery'den önce", "Hauntlet antes que Ghost Gallery", "Hauntlet antes da Ghost Gallery")
    add("A Hauntlet run comes first when a Ghost Gallery round is near", "Ghost Gallery turu yakınken önce Hauntlet'e girer",
        "Primero Hauntlet si una ronda de Ghost Gallery está cerca", "Primeiro Hauntlet se uma rodada da Ghost Gallery estiver perto")
    add("Hauntlet squad play", "Hauntlet takım oyunu", "Hauntlet en equipo", "Hauntlet em equipe")
    add("Your accounts in one run take turns with phone / keys / wand", "Aynı runda hesapların telefon / anahtar / asa için sıra alır",
        "Tus cuentas en una partida se turnan con teléfono / llaves / varita", "Suas contas na partida revezam telefone / chaves / varinha")
    add("Joins each round, vacuums ghosts (Rusty Keys)", "Her tura katılır, hayaletleri süpürür (Paslı Anahtar)", "Entra a cada ronda, aspira fantasmas", "Entra em cada rodada, aspira fantasmas")
    add("Joins by standing in the Manor circle", "Malikanedeki çembere girerek katılır", "Entra parándose en el círculo de la mansión", "Entra ficando no círculo da mansão")
    add("Uses Rusty Keys on the grave going down", "Aşağı inerken mezarda Paslı Anahtar kullanır", "Usa llaves en la tumba al bajar", "Usa chaves no túmulo ao descer")
    add("Bottom of the Crypt: takes the spider", "Mahzenin dibinde örümceği alır", "Fondo de la cripta: toma la araña", "Fundo da cripta: pega a aranha")
    add("Claims finished daily + board quests", "Biten günlük ve pano görevlerini toplar", "Reclama misiones diarias y del tablero", "Resgata missões diárias e do quadro")
    add("Visit-homes quests: visits houses here", "Ev ziyareti görevleri: buradaki evleri gezer", "Misiones de visitas: visita casas aquí", "Missões de visita: visita casas aqui")
    add("Puts Crypt Twigs into the Hotel nest", "Mahzen dallarını Otel'deki yuvaya koyar", "Pone ramitas en el nido del hotel", "Põe gravetos no ninho do hotel")
    add("Twig graves first until the nest is built", "Yuva bitene kadar önce dallı mezarlar", "Primero tumbas con ramitas hasta el nido", "Primeiro túmulos com gravetos até o ninho")
    add("1 water to the Stray Cat a day (+candy)", "Sokak kedisine günde 1 su (+şeker)", "1 agua al gato callejero al día (+dulces)", "1 água ao gato de rua por dia (+doces)")
    add("Claims the pen, keeps it full (at home)", "Ağılı toplar, dolu tutar (evde)", "Reclama el corral y lo llena (en casa)", "Coleta o cercadinho e mantém cheio (em casa)")
    add("Buys eggs so the pen stays full", "Ağıl dolu kalsın diye yumurta alır", "Compra huevos para llenar el corral", "Compra ovos para manter o cercadinho cheio")
    add("How often the pen is claimed", "Ağılın ne sıklıkla toplandığı", "Cada cuánto se reclama el corral", "De quanto em quanto tempo coletar")
    add("Saves candy for the pets in your list", "Listendeki petler için şeker biriktirir", "Ahorra dulces para tu lista", "Guarda doces para a sua lista")
    add("Clicks on Roblox's idle warning (also paused)", "Roblox'un boşta uyarısına tıklar (durakken de)", "Pulsa el aviso de inactividad (también en pausa)", "Clica no aviso de inatividade (também pausado)")
    add("Clicks Play on the main menu (also paused)", "Ana menüde Play'e basar (durakken de)", "Pulsa Play en el menú (también en pausa)", "Clica em Play no menu (também pausado)")
    add("Collects cashback Bucks (while running)", "Para iadesi Bucks'ları toplar (çalışırken)", "Cobra el reembolso de Bucks (activa)", "Coleta o cashback de Bucks (ligada)")
    add("No place / character: rejoins a PUBLIC server", "Yer / karakter yoksa HERKESE AÇIK sunucuya girer", "Sin lugar / personaje: entra a un servidor PÚBLICO", "Sem lugar / personagem: entra num servidor PÚBLICO")
    add("How long before that rejoin", "Yeniden katılmadan önceki süre", "Cuánto antes de reunirse", "Quanto antes de reentrar")
    add("Travels with the game's own doors", "Oyunun kendi kapılarıyla gider", "Viaja por las puertas del juego", "Viaja pelas portas do jogo")
    add("Goes home by respawn (fastest)", "Eve respawn ile gider (en hızlı)", "Va a casa reapareciendo (más rápido)", "Vai pra casa renascendo (mais rápido)")
    add("Route to camping / beach / playground", "Kamp / plaj / oyun parkı yolu", "Ruta al campamento / playa / parque", "Rota para acampamento / praia / parquinho")
    add("Goes home for the free bowl even with food", "Yiyecek olsa da bedava mama kabı için eve gider", "Va a casa por el plato gratis aunque tenga comida", "Vai pra casa pelo pote grátis mesmo com comida")
    add("Which growing pet first: youngest / oldest", "Önce hangi pet: en genç / en yaşlı", "Cuál primero: la más joven / vieja", "Qual primeiro: o mais novo / velho")
    add("Egg bought with Bucks (never Robux)", "Bucks ile alınan yumurta (asla Robux)", "Huevo con Bucks (nunca Robux)", "Ovo com Bucks (nunca Robux)")
    add("Pet kinds farmed first, comma separated", "Önce beslenen türler, virgülle", "Tipos primero, separados por comas", "Tipos primeiro, separados por vírgula")
    add("Potions only on these kinds (empty = any)", "İksir sadece bu türlere (boş = hepsi)", "Pociones solo en estos tipos (vacío = todos)", "Poções só nestes tipos (vazio = todos)")
    add("Needs doable right here go first", "Burada yapılabilen ihtiyaçlar önce", "Primero lo que se hace aquí", "Primeiro o que dá pra fazer aqui")
    add("Not moving, tasks failing: respawn home", "Hareket yok, görevler başarısız: eve respawn", "Sin moverse y fallando: reaparece en casa", "Parado e falhando: renasce em casa")
    add("How long before it counts as stuck", "Takılmış sayılmadan önceki süre", "Cuánto antes de contar como atascado", "Quanto antes de contar como travado")
    add("3 fails in a row: rest (0 = whole session)", "Üst üste 3 hata: dinlen (0 = tüm oturum)", "3 fallos seguidos: pausa (0 = toda la sesión)", "3 falhas seguidas: pausa (0 = sessão toda)")
    add("Max food / water buys (0 = no limit)", "En fazla yiyecek / su alımı (0 = sınırsız)", "Máx. compras de comida / agua (0 = sin límite)", "Máx. compras de comida / água (0 = sem limite)")
    add("Max egg buys (0 = no limit)", "En fazla yumurta alımı (0 = sınırsız)", "Máx. huevos (0 = sin límite)", "Máx. ovos (0 = sem limite)")
    add("Window colours", "Pencere renkleri", "Colores de la ventana", "Cores da janela")
    add("These lines (the window opens again)", "Bu satırlar (pencere yeniden açılır)", "Estas líneas (la ventana se reabre)", "Estas linhas (a janela reabre)")
    add("Starts closed: the key / paw button opens it", "Kapalı başlar: tuş / pati düğmesi açar", "Empieza cerrada: la tecla / botón de pata la abre", "Começa fechada: a tecla / botão de pata abre")
    add("Bug reports to the developer (off: at once)", "Geliştiriciye hata raporu (kapatınca hemen durur)", "Informes de errores al desarrollador", "Relatórios de erro ao desenvolvedor")
    add("How often cashback is collected", "Para iadesinin toplanma sıklığı", "Cada cuánto se cobra el reembolso", "De quanto em quanto coletar o cashback")
    add("4 free slots; 5 with the extra-slot pass", "4 bedava yer; ek yer geçişiyle 5", "4 espacios gratis; 5 con el pase", "4 vagas grátis; 5 com o passe")
    add("Buys pen eggs only above these Bucks", "Ağıl yumurtasını sadece bu Bucks üstünde alır", "Compra huevos solo con más Bucks que esto", "Compra ovos só acima destes Bucks")
    add("Which quick needs run beside a place need", "Bir yer ihtiyacının yanında hangi hızlı ihtiyaçlar", "Qué necesidades rápidas van junto a otra", "Quais necessidades rápidas junto de outra")
    add("Pause between two quick needs", "İki hızlı ihtiyaç arası bekleme", "Pausa entre dos necesidades rápidas", "Pausa entre duas necessidades rápidas")
    add("Pet kinds that are never fused", "Asla birleştirilmeyen türler", "Tipos que nunca se fusionan", "Tipos que nunca são fundidos")
    add("Gifts / chests that are never opened", "Asla açılmayan hediye / sandıklar", "Regalos / cofres que nunca se abren", "Presentes / baús que nunca são abertos")
    add("Which age potions may be used", "Hangi yaş iksirleri kullanılabilir", "Qué pociones de edad se usan", "Quais poções de idade usar")
    add("Wait after a failed task before a retry", "Başarısız görevden sonra tekrar deneme beklemesi", "Espera tras un fallo antes de reintentar", "Espera após falha antes de tentar")
    add("Fails in a row before a task rests", "Görev dinlenmeden önce üst üste hata", "Fallos seguidos antes de pausar", "Falhas seguidas antes da pausa")
    add("Experimental: leave home by its door", "Deneysel: evden kapıdan çık", "Experimental: salir por la puerta", "Experimental: sair pela porta")
    add("Candy kept back, whatever the list wants", "Liste ne isterse istesin ayrılan şeker", "Dulces que se guardan siempre", "Doces guardados sempre")
    add("How much the console shows (OFF = quiet)", "Konsolun ne kadar gösterdiği (OFF = sessiz)", "Cuánto muestra la consola (OFF = silencio)", "Quanto o console mostra (OFF = silêncio)")
    add("Reports also list item / pet counts", "Raporlar eşya / pet sayılarını da gösterir", "Los informes listan objetos / mascotas", "Relatórios listam itens / pets")
    add("Key that hides / shows this window", "Bu pencereyi gizleyen / gösteren tuş", "Tecla que muestra / oculta la ventana", "Tecla que mostra / oculta a janela")
    add("Message when the farm starts / stops", "Çiftlik başlayınca / durunca mesaj", "Mensaje al iniciar / detener", "Mensagem ao iniciar / parar")
    add("One message per finished need (many)", "Biten her ihtiyaç için mesaj (çok)", "Un mensaje por necesidad (muchos)", "Uma mensagem por necessidade (muitas)")
    add("Message on this script's errors", "Script hatalarında mesaj", "Mensaje en errores del script", "Mensagem nos erros do script")
    add("Message on a kick / disconnect", "Atılma / kopmada mesaj", "Mensaje al ser expulsado / desconectado", "Mensagem ao ser expulso / desconectado")
    add("Your Roblox name in the messages", "Mesajlarda Roblox adın", "Tu nombre de Roblox en los mensajes", "Seu nome do Roblox nas mensagens")
    add("@mention you for these messages", "Bu mesajlarda seni etiketler", "Te menciona en estos mensajes", "Menciona você nestas mensagens")
    add("Pets your pet until the need is done", "İhtiyaç bitene kadar peti sever", "Acaricia a tu mascota hasta terminar", "Acaricia o pet até terminar")
    add("Bowl at home, else your food; buys if on", "Evdeki mama kabı, yoksa yiyeceğin; açıksa alır", "Plato en casa, si no tu comida; compra si está activo", "Pote em casa, senão sua comida; compra se ligado")
    add("Your water / milk; buys 1 water if on", "Suyun / sütün; açıksa 1 su alır", "Tu agua / leche; compra 1 agua si está activo", "Sua água / leite; compra 1 água se ligado")
    add("Throws your squeaky bone", "Ötücü kemiğini atar", "Lanza tu hueso con sonido", "Joga seu osso de apertar")
    add("Your bed at home (goes home)", "Evdeki yatağın (eve gider)", "Tu cama en casa (va a casa)", "Sua cama em casa (vai pra casa)")
    add("Your shower at home (goes home)", "Evdeki duşun (eve gider)", "Tu ducha en casa (va a casa)", "Seu chuveiro em casa (vai pra casa)")
    add("Your toilet at home (goes home)", "Evdeki tuvaletin (eve gider)", "Tu baño en casa (va a casa)", "Seu vaso em casa (vai pra casa)")
    add("Walks your character until done", "Bitene kadar karakterini yürütür", "Camina hasta terminar", "Anda até terminar")
    add("Walks with your stroller until done", "Bitene kadar bebek arabasıyla yürür", "Pasea con el carrito hasta terminar", "Passeia com o carrinho até terminar")
    add("Picks a card this script can do", "Scriptin yapabildiği bir kart seçer", "Elige una carta que el script puede hacer", "Escolhe uma carta que o script consegue")
    add("Goes to the Salon and waits", "Kuaföre gidip bekler", "Va al salón y espera", "Vai ao salão e espera")
    add("Goes to the Cat Cafe and waits", "Kedi Kafe'ye gidip bekler", "Va al café de gatos y espera", "Vai ao café dos gatos e espera")
    add("Goes to the Pizza Shop and waits", "Pizzacıya gidip bekler", "Va a la pizzería y espera", "Vai à pizzaria e espera")
    add("Goes to School and waits", "Okula gidip bekler", "Va a la escuela y espera", "Vai à escola e espera")
    add("Hospital: talks to the doctor", "Hastane: doktorla konuşur", "Hospital: habla con el doctor", "Hospital: fala com o médico")
    add("Camp site spot on the map", "Haritadaki kamp yeri", "Zona de campamento del mapa", "Ponto de acampamento no mapa")
    add("Beach spot on the map", "Haritadaki plaj yeri", "Zona de playa del mapa", "Ponto da praia no mapa")
    add("Playground spot on the map", "Haritadaki oyun parkı", "Parque del mapa", "Parquinho no mapa")
    add("Stop the farm?", "Çiftlik durdurulsun mu?", "¿Detener la granja?", "Parar a fazenda?")
    add("Everything stops and cleans up. Run the loader again to start.", "Her şey durur ve temizlenir. Başlatmak için loader'ı tekrar çalıştır.", "Todo se detiene. Ejecuta el loader para empezar.", "Tudo para. Rode o loader de novo para começar.")
    add("Stop", "Durdur", "Detener", "Parar")
    add("Cancel", "Vazgeç", "Cancelar", "Cancelar")
    add("Apply", "Uygula", "Aplicar", "Aplicar")
    add("Apply + start", "Uygula + başlat", "Aplicar + iniciar", "Aplicar + iniciar")
    add("Reset", "Sıfırla", "Restablecer", "Redefinir")
    add("Delete", "Sil", "Borrar", "Apagar")
    add("Stopped.", "Durduruldu.", "Detenido.", "Parado.")
    add("Done", "Tamam", "Hecho", "Feito")
    add("Not possible now", "Şu an olmuyor", "No es posible ahora", "Não dá agora")
    add("Not valid", "Geçersiz", "No válido", "Inválido")
    add("Not available in this version", "Bu sürümde yok", "No disponible en esta versión", "Indisponível nesta versão")
    add("Window", "Pencere", "Ventana", "Janela")
    add("Building the window again...", "Pencere yeniden kuruluyor...", "Rehaciendo la ventana...", "Refazendo a janela...")
    add("Applies when the window opens again.", "Pencere yeniden açılınca geçerli olur.", "Se aplica al reabrir la ventana.", "Vale ao reabrir a janela.")
    add("Type a name first", "Önce bir ad yaz", "Escribe un nombre primero", "Digite um nome primeiro")
    add("Pick a saved config first", "Önce kayıtlı bir ayar seç", "Elige una configuración primero", "Escolha uma configuração primeiro")
    add("The config file is deleted from this device.", "Kayıt dosyası bu cihazdan silinir.", "El archivo se borra de este dispositivo.", "O arquivo é apagado deste aparelho.")
    add("Autoload", "Açılışta yükle", "Carga al iniciar", "Carregar ao iniciar")
    add("Autoload: off", "Açılışta yükleme: kapalı", "Carga al iniciar: no", "Carregar ao iniciar: não")
    add("Autosave off: save a config instead", "Otomatik kayıt kapalı: bunun yerine kayıt al", "Guardado automático no: guarda una configuración", "Salvamento automático desligado: salve uma configuração")
    add("Autosave: on (this device)", "Otomatik kayıt: açık (bu cihaz)", "Guardado automático: sí (este dispositivo)", "Salvamento automático: ligado (este aparelho)")
    add("Reset to loader settings?", "Loader ayarlarına dönülsün mü?", "¿Volver a los ajustes del loader?", "Voltar às opções do loader?")
    add("Transparency report", "Şeffaflık raporu", "Informe de transparencia", "Relatório de transparência")
    add("Printed to the console (F9 / executor console).", "Konsola yazıldı (F9 / executor konsolu).", "Escrito en la consola (F9 / consola del executor).", "Escrito no console (F9 / console do executor).")
    add("Hide / show: tap the round paw button", "Gizle / göster: yuvarlak pati düğmesine dokun", "Mostrar / ocultar: toca el botón de pata", "Mostrar / ocultar: toque no botão de pata")
    add("the round paw button", "yuvarlak pati düğmesi", "el botón redondo de pata", "o botão redondo de pata")
    add("the hide / show key", "gizle / göster tuşu", "la tecla mostrar / ocultar", "a tecla mostrar / ocultar")
    add("Run: getgenv().AdoptMeFarm.OpenInterface()", "Çalıştır: getgenv().AdoptMeFarm.OpenInterface()", "Ejecuta: getgenv().AdoptMeFarm.OpenInterface()", "Rode: getgenv().AdoptMeFarm.OpenInterface()")
    add("The farm is running.", "Çiftlik çalışıyor.", "La granja está activa.", "A fazenda está ligada.")
    add("Switch 'Farm running' on to start.", "Başlatmak için 'Çiftlik çalışıyor'u aç.", "Activa 'Granja activa' para empezar.", "Ligue 'Fazenda ligada' para começar.")
    add("Webhook", "Webhook", "Webhook", "Webhook")
    add("Webhook removed.", "Webhook kaldırıldı.", "Webhook eliminado.", "Webhook removido.")
    add("Saved on this device. Press 'Send test message'.", "Bu cihaza kaydedildi. 'Test mesajı gönder'e bas.", "Guardado aquí. Pulsa 'Enviar mensaje de prueba'.", "Salvo aqui. Toque em 'Enviar mensagem de teste'.")
    add("That is not a Discord webhook URL (Channel settings > Integrations > Webhooks)", "Bu bir Discord webhook adresi değil (Kanal ayarları > Entegrasyonlar > Webhooklar)", "No es una URL de webhook de Discord (Canal > Integraciones > Webhooks)", "Não é uma URL de webhook do Discord (Canal > Integrações > Webhooks)")
    add("That is not a Discord webhook URL", "Bu bir Discord webhook adresi değil", "No es una URL de webhook de Discord", "Não é uma URL de webhook do Discord")
    add("Digits only (Discord: Settings > Advanced > Developer Mode, then right click yourself > Copy ID)", "Sadece rakam (Discord: Ayarlar > Gelişmiş > Geliştirici Modu, sonra kendine sağ tık > ID'yi kopyala)", "Solo dígitos (Discord: Ajustes > Avanzado > Modo desarrollador, luego clic derecho en ti > Copiar ID)", "Só dígitos (Discord: Configurações > Avançado > Modo desenvolvedor, depois clique direito em você > Copiar ID)")
    add("Webhook: checking...", "Webhook: kontrol ediliyor...", "Webhook: comprobando...", "Webhook: verificando...")
    add("Webhook: ON", "Webhook: AÇIK", "Webhook: SÍ", "Webhook: LIGADO")
    add("Webhook: OFF (no URL yet)", "Webhook: KAPALI (adres yok)", "Webhook: NO (sin URL)", "Webhook: DESLIGADO (sem URL)")
    add("Waiting for your data...", "Verilerin bekleniyor...", "Esperando tus datos...", "Esperando seus dados...")
    add("Join script", "Katılma scripti", "Script para unirse", "Script para entrar")
    add("Copied: run it in your executor to join this server", "Kopyalandı: bu sunucuya girmek için executor'da çalıştır", "Copiado: ejecútalo para unirte a este servidor", "Copiado: rode no executor para entrar neste servidor")
    add("Could not copy", "Kopyalanamadı", "No se pudo copiar", "Não deu para copiar")
    add("Rusty Key earned", "Paslı Anahtar kazanıldı", "Llave oxidada ganada", "Chave enferrujada ganha")
    add("Mummy Spider claimed", "Mumya Örümcek alındı", "Araña momia obtenida", "Aranha múmia pega")
    add("Neon fusion", "Neon birleştirme", "Fusión neón", "Fusão neon")
    add("Mega neon!", "Mega neon!", "¡Mega neón!", "Mega neon!")
    add("Candy shop", "Şeker dükkanı", "Tienda de dulces", "Loja de doces")
    add("Quest reward", "Görev ödülü", "Premio de misión", "Prêmio de missão")
    add("Pigeon nest built", "Güvercin yuvası bitti", "Nido de paloma hecho", "Ninho de pombo pronto")
    add("Ghost Gallery round", "Hayalet Galerisi turu", "Ronda de la galería", "Rodada da galeria")
    add("Task resting", "Görev dinleniyor", "Tarea en pausa", "Tarefa em pausa")
    add("Stuck: going home", "Takıldı: eve gidiyor", "Atascado: a casa", "Travado: indo pra casa")
    add("Made Adopt Victims: plain, readable Luau.", "Adopt Victims'ı yaptı: sade, okunabilir Luau.", "Creó Adopt Victims: Luau simple y legible.", "Criou o Adopt Victims: Luau simples e legível.")
    add("Thank you for using it!", "Kullandığın için teşekkürler!", "¡Gracias por usarlo!", "Obrigado por usar!")
    add("Send each coin only on the network written next to it. Tokens sent on another network are lost.", "Her coini sadece yanında yazan ağdan gönder. Başka ağdan gönderilen tokenler kaybolur.", "Envía cada moneda solo por la red indicada. Los tokens en otra red se pierden.", "Envie cada moeda só pela rede indicada. Tokens em outra rede se perdem.")
    add("supported", "destekleniyor", "compatible", "compatível")
    add("not tested with this script", "bu scriptle denenmedi", "no probado con este script", "não testado com este script")
    add("Everything stopped. Run the loader again to start.", "Her şey durdu. Başlatmak için loader'ı tekrar çalıştır.", "Todo detenido. Ejecuta el loader para empezar.", "Tudo parado. Rode o loader de novo para começar.")
    add("Nothing is on yet: switch features on (Main / Event) or pick a preset (Config), then switch Farm running on.", "Henüz hiçbir şey açık değil: özellikleri aç (Ana sayfa / Etkinlik) ya da hazır ayar seç (Ayarlar), sonra 'Çiftlik çalışıyor'u aç.", "Nada activo aún: activa funciones (Principal / Evento) o elige un ajuste (Config) y luego 'Granja activa'.", "Nada ligado ainda: ligue funções (Principal / Evento) ou escolha uma predefinição (Config) e depois 'Fazenda ligada'.")
    add("Waiting for the game to load...", "Oyunun yüklenmesi bekleniyor...", "Esperando a que cargue el juego...", "Esperando o jogo carregar...")
    add("Running, but no feature is on: pick a preset or switch features on.", "Çalışıyor ama hiçbir özellik açık değil: hazır ayar seç ya da özellik aç.", "Activa, pero sin funciones: elige un ajuste o activa funciones.", "Ligada, mas sem funções: escolha uma predefinição ou ligue funções.")
    add("Running", "Çalışıyor", "Activa", "Ligada")
    add("Paused: no game actions.", "Duraklatıldı: oyun işlemi yok.", "En pausa: ninguna acción.", "Pausada: nenhuma ação.")
    add("FARM: STOPPED", "ÇİFTLİK: DURDU", "GRANJA: DETENIDA", "FAZENDA: PARADA")
    add("FARM: OFF", "ÇİFTLİK: KAPALI", "GRANJA: APAGADA", "FAZENDA: DESLIGADA")
    add("FARM: ON", "ÇİFTLİK: AÇIK", "GRANJA: ACTIVA", "FAZENDA: LIGADA")
    add("nothing yet", "henüz yok", "nada aún", "nada ainda")
    add("none equipped", "elde pet yok", "ninguna equipada", "nenhum equipado")
    add("Next Ghost Gallery: unknown yet", "Sonraki Hayalet Galerisi: henüz bilinmiyor", "Próxima galería: aún no se sabe", "Próxima galeria: ainda não se sabe")
    add("Tap to join the discord of your script.", "Scriptin Discord'una katılmak için dokun.", "Toca para unirte al Discord del script.", "Toque para entrar no Discord do script.")
    add("Your Executor Seems To Be Supported By This Script.", "Executor'ın bu scriptle uyumlu görünüyor.", "Tu executor parece compatible con este script.", "Seu executor parece compatível com este script.")
    add("Your Executor Is Supported By \nThis Script.", "Executor'ın bu scriptle \nuyumlu.", "Tu executor es compatible \ncon este script.", "Seu executor é compatível \ncom este script.")
    add("Your Executor Is Unsupported \nBy This Script.", "Executor'ın bu scriptle \nuyumlu değil.", "Tu executor no es compatible \ncon este script.", "Seu executor não é compatível \ncom este script.")
    add("Everything Off", "Hepsi kapalı", "Todo apagado", "Tudo desligado")
    add("Full AutoFarm", "Tam otomatik çiftlik", "AutoFarm completo", "AutoFarm completo")
    add("Mega Mummy Spider's", "Mega Mumya Örümcek", "Mega Araña momia", "Mega Aranha múmia")
    add("Mummy Spiders only: keys straight down the Crypt, every spider grown (needs, potions, Pet Pen), then neon + mega neon. No eggs, no candy pets, no nest / Stray Cat.",
        "Sadece Mumya Örümcekler: anahtarlar doğrudan mahzenin dibine, her örümcek büyütülür (ihtiyaç, iksir, Pet Ağılı), sonra neon + mega neon. Yumurta yok, şeker peti yok, yuva / sokak kedisi yok.",
        "Solo arañas momia: llaves directo al fondo de la cripta, cada araña crece (necesidades, pociones, corral), luego neón + mega neón. Sin huevos, sin mascotas de dulces, sin nido / gato.",
        "Só aranhas múmia: chaves direto ao fundo da cripta, cada aranha cresce (necessidades, poções, cercadinho), depois neon + mega neon. Sem ovos, sem pets de doces, sem ninho / gato.")
    add("Mega Skelicorn", "Mega Skelicorn", "Mega Skelicorn", "Mega Skelicorn")
    add("Skelicorns only: candy from the whole event, Lightning Lever from the Crypt, a Skelicorn every 120k candy (up to 5 growing), grown + neon + mega neon.",
        "Sadece Skelicorn: tüm etkinlikten şeker, mahzenden Şimşek Kolu, her 120k şekerde bir Skelicorn (en fazla 5 büyüyen), büyüt + neon + mega neon.",
        "Solo Skelicorns: dulces de todo el evento, palanca del rayo de la cripta, un Skelicorn cada 120k dulces (hasta 5 creciendo), crecer + neón + mega neón.",
        "Só Skelicorns: doces do evento todo, alavanca do raio da cripta, um Skelicorn a cada 120k doces (até 5 crescendo), crescer + neon + mega neon.")
    add("Mega a Pet", "Bir Peti Mega Yap", "Mega una mascota", "Mega um pet")
    add("Pick one pet or egg below. Egg: bought and hatched on repeat. Candy pet: 5 bought (1 raised, 4 in the Pet Pen). Any pet: grown, neon, mega neon on repeat, its copies in the Pet Pen.",
        "Aşağıdan bir pet ya da yumurta seç. Yumurta: sürekli alınır ve açılır. Şeker peti: 5 tane alınır (1 büyütülür, 4 Pet Ağılı'na). Her pet: büyüt, neon, mega neon sürekli, kopyaları Pet Ağılı'nda.",
        "Elige una mascota o un huevo abajo. Huevo: se compra y se abre sin parar. Mascota de dulces: 5 compradas (1 criada, 4 en el corral). Cualquier mascota: crecer, neón, mega neón sin parar, sus copias en el corral.",
        "Escolha um pet ou ovo abaixo. Ovo: comprado e chocado sem parar. Pet de doces: 5 comprados (1 criado, 4 no cercadinho). Qualquer pet: crescer, neon, mega neon sem parar, as cópias no cercadinho.")
    add("Mega a Pet: pick", "Mega yapılacak pet", "Mega: elige", "Mega: escolha")
    add("Nothing (normal farm)", "Hiçbiri (normal çiftlik)", "Nada (granja normal)", "Nada (fazenda normal)")
    add("Picked:", "Seçilen:", "Elegido:", "Escolhido:")
    add("Pick a pet or an egg in 'Mega a Pet: pick' first.", "Önce 'Mega yapılacak pet' kısmından bir pet ya da yumurta seç.", "Primero elige una mascota o un huevo en 'Mega: elige'.", "Primeiro escolha um pet ou ovo em 'Mega: escolha'.")
    add("Egg: bought and hatched on repeat. Pet: grown, neon, mega neon, its copies in the Pet Pen. Works right away; the 'Mega a Pet' button also turns on needs, potions, neon and the Pet Pen.",
        "Yumurta: sürekli alınır ve açılır. Pet: büyüt, neon, mega neon, kopyaları Pet Ağılı'nda. Hemen çalışır; 'Bir Peti Mega Yap' düğmesi ihtiyaçları, iksirleri, neonu ve Pet Ağılı'nı da açar.",
        "Huevo: se compra y se abre sin parar. Mascota: crecer, neón, mega neón, sus copias en el corral. Funciona al instante; el botón 'Mega una mascota' también activa necesidades, pociones, neón y el corral.",
        "Ovo: comprado e chocado sem parar. Pet: crescer, neon, mega neon, as cópias no cercadinho. Funciona na hora; o botão 'Mega um pet' também liga necessidades, poções, neon e o cercadinho.")
    add("Mummy Spider (Crypt)", "Mumya Örümcek (Mahzen)", "Araña momia (cripta)", "Aranha múmia (cripta)")
    add("Skelicorn (120k candy)", "Skelicorn (120k şeker)", "Skelicorn (120k dulces)", "Skelicorn (120k doces)")
    add("Event Only", "Sadece etkinlik", "Solo evento", "Só evento")
    add("Needs Only", "Sadece ihtiyaçlar", "Solo necesidades", "Só necessidades")
    add("Every feature off (the defaults). Anti-AFK and the Play button stay on.", "Her özellik kapalı (varsayılan). Anti-AFK ve Play düğmesi açık kalır.", "Todo apagado (por defecto). Anti-AFK y el botón Play siguen activos.", "Tudo desligado (padrão). Anti-AFK e o botão Play continuam ligados.")
    add("Everything: every need, eggs, potions, neon + mega neon, gifts, cashback, quests and the whole event.", "Her şey: tüm ihtiyaçlar, yumurta, iksir, neon + mega neon, hediye, para iadesi, görevler ve tüm etkinlik.", "Todo: necesidades, huevos, pociones, neón + mega neón, regalos, reembolso, misiones y el evento.", "Tudo: necessidades, ovos, poções, neon + mega neon, presentes, cashback, missões e o evento todo.")
    add("Only Halloween: Ghost Gallery, Crypt + Mummy Spider, quests, Pet Pen. No pet / baby needs.", "Sadece Cadılar Bayramı: Hayalet Galerisi, Mahzen + Mumya Örümcek, görevler, Pet Ağılı. Pet / bebek ihtiyacı yok.", "Solo Halloween: galería, cripta + araña momia, misiones, corral. Sin necesidades.", "Só Halloween: galeria, cripta + aranha múmia, missões, cercadinho. Sem necessidades.")
    add("Only pet + baby needs (with eggs when nothing grows). The event stays off.", "Sadece pet + bebek ihtiyaçları (büyüyen yoksa yumurta). Etkinlik kapalı kalır.", "Solo necesidades de mascota + bebé (huevos si nada crece). El evento queda apagado.", "Só necessidades de pet + bebê (ovos se nada cresce). O evento fica desligado.")
    add("New window: game icons, your language, live Farm card, presets.", "Yeni pencere: oyun ikonları, senin dilin, canlı Çiftlik kartı, hazır ayarlar.", "Ventana nueva: iconos del juego, tu idioma, tarjeta de granja en vivo, ajustes.", "Janela nova: ícones do jogo, seu idioma, cartão da fazenda ao vivo, predefinições.")
    add("Game icons", "Oyun ikonları", "Iconos del juego", "Ícones do jogo")
    add("The game's icons and your language", "Oyunun ikonları ve senin dilin", "Iconos del juego y tu idioma", "Ícones do jogo e seu idioma")
    add("Game icons everywhere; the window speaks your language (flag = your country).", "Her yerde oyun ikonları; pencere senin dilinde (bayrak = ülken).", "Iconos del juego en todas partes; la ventana habla tu idioma.", "Ícones do jogo em todo lugar; a janela fala o seu idioma.")
    add("The window in your language: English, Türkçe, Español, Português", "Pencere senin dilinde: English, Türkçe, Español, Português", "La ventana en tu idioma: English, Türkçe, Español, Português", "A janela no seu idioma: English, Türkçe, Español, Português")
    add("Your country's flag on the Dashboard", "Panelde ülkenin bayrağı", "La bandera de tu país en el panel", "A bandeira do seu país no painel")
    add("The game's own icons: Bucks, candy, home, eggs, potions, keys", "Oyunun kendi ikonları: Bucks, şeker, ev, yumurta, iksir, anahtar", "Iconos del juego: Bucks, dulces, casa, huevos, pociones, llaves", "Ícones do jogo: Bucks, doces, casa, ovos, poções, chaves")
    add("No emojis: coloured status icons", "Emoji yok: renkli durum ikonları", "Sin emojis: iconos de estado con color", "Sem emojis: ícones de status coloridos")
    add("See-through dashboard cards", "Yarı saydam panel kartları", "Tarjetas del panel translúcidas", "Cartões do painel translúcidos")
    add("Webhook: candy + your pet's picture", "Webhook: şeker + petinin resmi", "Webhook: dulces + foto de tu mascota", "Webhook: doces + foto do seu pet")
    add("Autoclose GUI on execute (Config > Settings)", "Açılışta pencereyi gizle (Ayarlar > Ayarlar)", "Ocultar ventana al ejecutar (Config > Opciones)", "Ocultar janela ao executar (Config > Opções)")
    add("Good Morning!", "Günaydın!", "¡Buenos días!", "Bom dia!")
    add("How's Your Day Going?", "Günün nasıl geçiyor?", "¿Qué tal tu día?", "Como está seu dia?")
    add("Sweet Dreams.", "Tatlı rüyalar.", "Dulces sueños.", "Bons sonhos.")
    add("Jeez you should be asleep...", "Hey, uyuman lazım...", "Deberías estar durmiendo...", "Você devia estar dormindo...")
    local TEMPLATES = {}
    Lang.TEMPLATES = TEMPLATES
    local function template(en, tr, es, pt)
        add(en, tr, es, pt)
        table.insert(TEMPLATES, en)
    end
    template("Copied: %s", "Kopyalandı: %s", "Copiado: %s", "Copiado: %s")
    template("Error: %s", "Hata: %s", "Error: %s", "Erro: %s")
    template("Delete '%s'?", "'%s' silinsin mi?", "¿Borrar '%s'?", "Apagar '%s'?")
    template("Saved '%s'", "'%s' kaydedildi", "'%s' guardada", "'%s' salva")
    template("Overwrote '%s'", "'%s' üzerine yazıldı", "'%s' sobrescrita", "'%s' sobrescrita")
    template("Could not read '%s'", "'%s' okunamadı", "No se pudo leer '%s'", "Não deu para ler '%s'")
    template("Loaded '%s' (%d settings)", "'%s' yüklendi (%d ayar)", "'%s' cargada (%d ajustes)", "'%s' carregada (%d opções)")
    template("'%s' exists: pick it and press Overwrite", "'%s' zaten var: seç ve Üzerine yaz'a bas", "'%s' ya existe: elígela y pulsa Sobrescribir", "'%s' já existe: escolha e toque em Sobrescrever")
    template("Deleted '%s'", "'%s' silindi", "'%s' borrada", "'%s' apagada")
    template("Autoload: '%s' at start", "Açılışta yükle: '%s'", "Carga al iniciar: '%s'", "Carregar ao iniciar: '%s'")
    template("Autosave: %d change(s) kept", "Otomatik kayıt: %d değişiklik saklandı", "Guardado automático: %d cambio(s)", "Salvamento automático: %d mudança(s)")
    template("Preset: %s", "Hazır ayar: %s", "Ajuste: %s", "Predefinição: %s")
    template("%d of %d features on. %s", "%d/%d özellik açık. %s", "%d de %d funciones activas. %s", "%d de %d funções ligadas. %s")
    template("%s Your other settings stay.", "%s Diğer ayarların aynı kalır.", "%s Tus otros ajustes se quedan.", "%s Suas outras opções ficam.")
    template("The window starts hidden: %s opens it", "Pencere gizli başlar: %s açar", "La ventana empieza oculta: %s la abre", "A janela começa oculta: %s abre")
    template("Hide / show: %s", "Gizle / göster: %s", "Mostrar / ocultar: %s", "Mostrar / ocultar: %s")
    template("Ready. %s hides / shows the window.", "Hazır. %s pencereyi gizler / gösterir.", "Listo. %s muestra / oculta la ventana.", "Pronto. %s mostra / oculta a janela.")
    template("Ready. Round paw button: hide / show. Square button at the top: full screen. Sliders: tap the number to type.",
        "Hazır. Yuvarlak pati düğmesi: gizle / göster. Üstteki kare düğme: tam ekran. Kaydırıcılar: sayıya dokunup yaz.",
        "Listo. Botón de pata: mostrar / ocultar. Botón cuadrado arriba: pantalla completa. Deslizadores: toca el número para escribir.",
        "Pronto. Botão de pata: mostrar / ocultar. Botão quadrado no topo: tela cheia. Controles: toque no número para digitar.")
    template("Executor: %s", "Executor: %s", "Executor: %s", "Executor: %s")
    template("Status: %s", "Durum: %s", "Estado: %s", "Status: %s")
    template("Player: %s", "Oyuncu: %s", "Jugador: %s", "Jogador: %s")
    template("Server: %s players", "Sunucu: %s oyuncu", "Servidor: %s jugadores", "Servidor: %s jogadores")
    template("Script: v%s", "Script: v%s", "Script: v%s", "Script: v%s")
    template("What's new in v%s", "v%s yenilikleri", "Novedades de v%s", "Novidades da v%s")
    template("• %s", "• %s", "• %s", "• %s")
    template("Welcome, %s", "Hoş geldin, %s", "Bienvenido, %s", "Bem-vindo, %s")
    template("%s | %s", "%s | %s", "%s | %s", "%s | %s")
    template("%s (%s candy)", "%s (%s şeker)", "%s (%s dulces)", "%s (%s doces)")
    template("%d/%d features on", "%d/%d özellik açık", "%d/%d funciones activas", "%d/%d funções ligadas")
    template("%d of %d features on", "%d/%d özellik açık", "%d de %d funciones activas", "%d de %d funções ligadas")
    template("Paused: no game actions. %s", "Duraklatıldı: oyun işlemi yok. %s", "En pausa: ninguna acción. %s", "Pausada: nenhuma ação. %s")
    template("Switch Farm running on to start.", "Başlatmak için 'Çiftlik çalışıyor'u aç.", "Activa 'Granja activa' para empezar.", "Ligue 'Fazenda ligada' para começar.")
    template("Waiting for the game to load... %s", "Oyunun yüklenmesi bekleniyor... %s", "Esperando a que cargue el juego... %s", "Esperando o jogo carregar... %s")
    template("Running • %s", "Çalışıyor • %s", "Activa • %s", "Ligada • %s")
    template("preset %s", "hazır ayar %s", "ajuste %s", "predefinição %s")
    template("%s features on", "%s özellik açık", "%s funciones activas", "%s funções ligadas")
    template("Last done: %s", "Son yapılan: %s", "Lo último: %s", "Última: %s")
    template("Pet: %s", "Pet: %s", "Mascota: %s", "Pet: %s")
    template("%s (age %s)", "%s (yaş %s)", "%s (edad %s)", "%s (idade %s)")
    template("Session: %d min • %s needs", "Oturum: %d dk • %s ihtiyaç", "Sesión: %d min • %s necesidades", "Sessão: %d min • %s necessidades")
    template("Bucks: %s (+%s)", "Bucks: %s (+%s)", "Bucks: %s (+%s)", "Bucks: %s (+%s)")
    template("Candy: %s (+%s)", "Şeker: %s (+%s)", "Dulces: %s (+%s)", "Doces: %s (+%s)")
    template("Tasks: %s done • %s failed", "Görevler: %s bitti • %s hata", "Tareas: %s hechas • %s fallidas", "Tarefas: %s feitas • %s falhas")
    template("Doing: %s", "Yapılan: %s", "Haciendo: %s", "Fazendo: %s")
    template("Doing: nothing (stopped)", "Yapılan: hiçbir şey (durdu)", "Haciendo: nada (detenida)", "Fazendo: nada (parada)")
    template("Doing: nothing (paused)", "Yapılan: hiçbir şey (duraklatıldı)", "Haciendo: nada (en pausa)", "Fazendo: nada (pausada)")
    template("Doing: nothing to do right now", "Yapılan: şu an iş yok", "Haciendo: nada por ahora", "Fazendo: nada por agora")
    template("Needs: %s", "İhtiyaçlar: %s", "Necesidades: %s", "Necessidades: %s")
    template("Needs: none", "İhtiyaçlar: yok", "Necesidades: ninguna", "Necessidades: nenhuma")
    template("Ghost Gallery: off", "Galeri: kapalı", "Galería: apagada", "Galeria: desligada")
    template("Ghost Gallery: in %s", "Galeri: %s sonra", "Galería: en %s", "Galeria: em %s")
    template("Ghost Gallery: waiting", "Galeri: bekleniyor", "Galería: esperando", "Galeria: esperando")
    template("Pet Pen: off", "Pet Ağılı: kapalı", "Corral: apagado", "Cercadinho: desligado")
    template("Pet Pen: %d/%d • claim %s", "Pet Ağılı: %d/%d • toplama %s", "Corral: %d/%d • reclamar en %s", "Cercadinho: %d/%d • coletar em %s")
    template("Pet Pen: %d/%d • claim now", "Pet Ağılı: %d/%d • şimdi topla", "Corral: %d/%d • reclamar ya", "Cercadinho: %d/%d • coletar agora")
    template("Pet Pen: no data yet", "Pet Ağılı: henüz veri yok", "Corral: sin datos aún", "Cercadinho: sem dados ainda")
    template("Resting: %s", "Dinlenen: %s", "En pausa: %s", "Em pausa: %s")
    template("Resting: none", "Dinlenen: yok", "En pausa: ninguna", "Em pausa: nenhuma")
    template("%s (%d min)", "%s (%d dk)", "%s (%d min)", "%s (%d min)")
    template("Rusty Keys: %s  •  Twigs: %s", "Paslı Anahtar: %s  •  Dal: %s", "Llaves oxidadas: %s  •  Ramitas: %s", "Chaves enferrujadas: %s  •  Gravetos: %s")
    template("Nest: %s / 8 twigs", "Yuva: %s / 8 dal", "Nido: %s / 8 ramitas", "Ninho: %s / 8 gravetos")
    template("Nest: ?", "Yuva: ?", "Nido: ?", "Ninho: ?")
    template("Next Ghost Gallery in %s", "Sonraki Hayalet Galerisi: %s", "Próxima galería en %s", "Próxima galeria em %s")
    template("%s/%s players", "%s/%s oyuncu", "%s/%s jugadores", "%s/%s jogadores")
    template("%s FPS • %s ms", "%s FPS • %s ms", "%s FPS • %s ms", "%s FPS • %s ms")
    template("server %s", "sunucu %s", "servidor %s", "servidor %s")
    template("baby %s", "bebek %s", "bebé %s", "bebê %s")
    local NEED_WORDS = {
        ["pet me"] = { "sevme", "caricias", "carinho" }, hungry = { "aç", "hambre", "fome" },
        thirsty = { "susamış", "sed", "sede" }, play = { "oyun", "jugar", "brincar" }, sleepy = { "uykulu", "sueño", "sono" },
        dirty = { "kirli", "sucio", "sujo" }, toilet = { "tuvalet", "baño", "banheiro" }, walk = { "yürüyüş", "paseo", "passeio" },
        ride = { "gezinti", "carrito", "carrinho" }, mystery = { "gizem", "misterio", "mistério" },
        salon = { "kuaför", "salón", "salão" }, ["cat cafe"] = { "kedi kafe", "café de gatos", "café dos gatos" },
        ["pizza party"] = { "pizza partisi", "fiesta de pizza", "festa da pizza" }, school = { "okul", "escuela", "escola" },
        sick = { "hasta", "enfermo", "doente" }, camping = { "kamp", "campamento", "acampamento" },
        ["beach party"] = { "plaj partisi", "fiesta en la playa", "festa na praia" }, bored = { "sıkılmış", "aburrido", "entediado" },
        ["ghost gallery"] = { "hayalet galerisi", "galería", "galeria" }, ["pet pen"] = { "pet ağılı", "corral", "cercadinho" },
    }
    for word, words in pairs(NEED_WORDS) do
        if not S[word] then
            add(word, words[1], words[2], words[3])
        end
    end
    local function exact(text)
        local entry = S[text]
        local value = entry and entry[Lang.current]
        if value then
            return value
        end
        local before, core, after = string.match(text, "^(%s*)(.-)(%s*)$")
        if core ~= text and core ~= "" then
            entry = S[core]
            value = entry and entry[Lang.current]
            if value then
                return before .. value .. after
            end
        end
        return nil
    end
    local compiled
    Lang._memo, Lang._memoSize = {}, 0
    local function compile()
        compiled = {}
        for _, key in ipairs(TEMPLATES) do
            local count = 0
            local pattern = string.gsub(key, "(%%?)(.)", function(percent, char)
                if percent == "%" and (char == "s" or char == "d") then
                    count += 1
                    return char == "s" and "(.-)" or "(%-?[%d,]+)"
                end
                local text = percent .. char
                return (string.gsub(text, "[%^%$%(%)%%%.%[%]%*%+%-%?]", "%%%0"))
            end)
            if count > 0 then
                table.insert(compiled, { key = key, pattern = "^" .. pattern .. "$", count = count })
            end
        end
        table.sort(compiled, function(a, b)
            return #a.key > #b.key
        end)
    end
    local function fill(translated, values)
        local index = 0
        return (string.gsub(translated, "%%([sd])", function()
            index += 1
            return values[index] or ""
        end))
    end
    function Lang.tr(text)
        if Lang.current == "en" or type(text) ~= "string" or text == "" then
            return text
        end
        local hit = exact(text)
        if hit then
            return hit
        end
        if string.find(text, "\n", 1, true) then
            local lines = {}
            for line in string.gmatch(text .. "\n", "(.-)\n") do
                table.insert(lines, Lang.tr(line))
            end
            return table.concat(lines, "\n")
        end
        if not compiled then
            compile()
        end
        local memo = Lang._memo[Lang.current]
        if memo and memo[text] then
            return memo[text]
        end
        local result = text
        for _, entry in ipairs(compiled) do
            local values = { string.match(text, entry.pattern) }
            if #values == entry.count then
                for index, value in ipairs(values) do
                    values[index] = exact(value) or value
                end
                result = fill(S[entry.key][Lang.current] or entry.key, values)
                break
            end
        end
        memo = memo or {}
        if Lang._memoSize > 400 then
            memo, Lang._memoSize = {}, 0
        end
        memo[text] = result
        Lang._memo[Lang.current] = memo
        Lang._memoSize += 1
        return result
    end
    function Lang.t(text, ...)
        local translated = Lang.tr(text)
        if select("#", ...) == 0 then
            return translated
        end
        local ok, result = pcall(string.format, translated, ...)
        if ok then
            return result
        end
        return string.format(text, ...)
    end
    return Lang
end
__moduleSources["Services/WindowState"] = function(...)
    -- Pure geometry logic: no services or input connections.
    local WindowState = {}
    WindowState.__index = WindowState
    local MARGIN, HEADER = 12, 52
    local function finite(value, fallback)
        return type(value) == "number" and value == value and math.abs(value) < math.huge and value or fallback
    end
    local function clamp(value, low, high)
        return math.max(low, math.min(high, value))
    end
    function WindowState.new(width, height)
        local self = setmetatable({ minimized = false, maximized = false }, WindowState)
        self.vw, self.vh = math.max(120, finite(width, 1024)), math.max(100, finite(height, 768))
        self.w, self.h = math.min(760, self.vw - MARGIN * 2), math.min(530, self.vh - MARGIN * 2)
        self.x, self.y = (self.vw - self.w) / 2, (self.vh - self.h) / 2
        self:constrain()
        return self
    end
    function WindowState:constrain()
        local maxW, maxH = self.vw - MARGIN * 2, self.vh - MARGIN * 2
        self.w = clamp(finite(self.w, 760), math.min(420, maxW), maxW)
        self.h = clamp(finite(self.h, 530), math.min(300, maxH), maxH)
        self.x = clamp(finite(self.x, MARGIN), MARGIN, self.vw - self.w - MARGIN)
        self.y = clamp(finite(self.y, MARGIN), MARGIN, self.vh - (self.minimized and HEADER or self.h) - MARGIN)
    end
    function WindowState:rect()
        return self.x, self.y, self.w, self.minimized and HEADER or self.h
    end
    function WindowState:moveTo(x, y)
        if self.maximized then return end
        self.x, self.y = finite(x, self.x), finite(y, self.y)
        self:constrain()
    end
    function WindowState:resizeTo(w, h)
        if self.maximized then return end
        self.minimized = false
        self.w, self.h = finite(w, self.w), finite(h, self.h)
        self:constrain()
    end
    function WindowState:toggleMinimize()
        self.minimized = not self.minimized
        self:constrain()
    end
    function WindowState:toggleMaximize()
        self.minimized = false
        if self.maximized then
            self.x, self.y, self.w, self.h = self.restore[1], self.restore[2], self.restore[3], self.restore[4]
            self.restore = nil
            self.maximized = false
        else
            self.restore = { self.x, self.y, self.w, self.h }
            self.maximized = true
            self.x, self.y = MARGIN, MARGIN
            self.w, self.h = self.vw - MARGIN * 2, self.vh - MARGIN * 2
        end
        self:constrain()
    end
    function WindowState:setViewport(width, height)
        self.vw, self.vh = math.max(120, finite(width, self.vw)), math.max(100, finite(height, self.vh))
        if self.maximized then
            self.x, self.y, self.w, self.h = MARGIN, MARGIN, self.vw - MARGIN * 2, self.vh - MARGIN * 2
        end
        self:constrain()
    end
    return WindowState
end

__moduleSources["Services/Interface"] = function(...)
    local import = ...
    local WindowState = import("Services/WindowState")
    local Interface = { SAVE_PATH = "(disabled)", CONFIG_FOLDER = "(disabled)", CONFIG_EXTENSION = "", current = nil }
    function Interface.applySaved() return 0 end
    local NEEDS = {
        pet_me = "Carinho", hungry = "Fome", thirsty = "Sede", sleepy = "Sono", dirty = "Banho",
        toilet = "Banheiro", sick = "Doente", play = "Brincar", mystery = "Mistério", salon = "Salão",
        school = "Escola", pizza_party = "Pizza", camping = "Acampamento", beach_party = "Praia",
        walk = "Passear", ride = "Passeio montado", cat_cafe = "Cat Café", bored = "Tédio",
    }
    local C = {
        bg = Color3.fromRGB(14, 15, 23), rail = Color3.fromRGB(19, 21, 31), card = Color3.fromRGB(24, 27, 39),
        border = Color3.fromRGB(43, 47, 65), accent = Color3.fromRGB(151, 119, 255), tint = Color3.fromRGB(46, 36, 75),
        text = Color3.fromRGB(237, 238, 247), muted = Color3.fromRGB(145, 153, 174),
        green = Color3.fromRGB(66, 204, 154), red = Color3.fromRGB(236, 103, 123),
    }
    local function build(api, scope)
        local UIS = game:GetService("UserInputService")
        local player = game:GetService("Players").LocalPlayer
        local parent = player and player:WaitForChild("PlayerGui", 10)
        assert(parent, "PlayerGui não está pronto")
        assert(not api.Status().stopped, "O script foi encerrado")
        local gui = Instance.new("ScreenGui")
        scope.gui = gui
        gui.Name = "AdoptMeLocalStableHub14"
        gui.ResetOnSpawn = false
        gui.IgnoreGuiInset = true
        gui.DisplayOrder = 50
        gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
        gui.Parent = parent
        local camera = workspace.CurrentCamera
        local view = camera and camera.ViewportSize or Vector2.new(1024, 768)
        local geometry = WindowState.new(view.X, view.Y)
        local handle = { Owner = api, Geometry = geometry }
        local closed, refreshers, rows, pages, navButtons = false, {}, {}, {}, {}
        local order, selected, messageUntil = 0, "Inicio", 0
        local function connect(signal, callback)
            local connection = signal:Connect(callback)
            table.insert(scope.connections, connection)
            return connection
        end
        local function el(kind, props, node)
            local obj = Instance.new(kind)
            for key, value in pairs(props or {}) do obj[key] = value end
            if obj:IsA("GuiObject") then
                order = order + 1
                obj.LayoutOrder = order
                obj.BorderSizePixel = 0
            end
            if obj:IsA("TextLabel") or obj:IsA("TextButton") or obj:IsA("TextBox") then
                obj.Font = Enum.Font.Gotham
                obj.TextColor3 = obj.TextColor3 == Color3.new(0, 0, 0) and C.text or obj.TextColor3
            end
            obj.Parent = node
            return obj
        end
        local function round(obj, radius) el("UICorner", { CornerRadius = UDim.new(0, radius or 9) }, obj) end
        local function text(value, size, pos, parentNode, color)
            return el("TextLabel", { Text = value, TextSize = 13, TextWrapped = true, BackgroundTransparency = 1,
                TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = color or C.text, Size = size, Position = pos }, parentNode)
        end
        local function setText(obj, value)
            value = tostring(value)
            if obj.Text ~= value then obj.Text = value end
        end
        local panel = el("Frame", { Name = "Window", Active = true, ClipsDescendants = true, BackgroundColor3 = C.bg }, gui)
        round(panel, 12)
        el("UIStroke", { Color = C.border, Thickness = 1 }, panel)
        local header = el("Frame", { Name = "Header", Active = true, BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 52) }, panel)
        local dragArea = el("TextButton", { Name = "DragArea", Active = true, AutoButtonColor = false,
            Text = "", BackgroundTransparency = 1, Size = UDim2.new(1, -128, 1, 0) }, header)
        local brand = text("A  /  ADOPT HUB", UDim2.new(1, -24, 1, 0), UDim2.fromOffset(18, 0), dragArea)
        brand.Font = Enum.Font.GothamBold
        brand.TextSize = 15
        brand.ZIndex = 2
        local function headerButton(name, caption, offset, color)
            local button = el("TextButton", { Name = name, Text = caption, TextSize = 16, TextColor3 = color or C.muted,
                Size = UDim2.fromOffset(32, 30), Position = UDim2.new(1, offset, 0, 11), BackgroundColor3 = C.card }, header)
            round(button, 7)
            return button
        end
        local minimize = headerButton("Minimize", "−", -116)
        local maximize = headerButton("Maximize", "□", -78)
        local closeButton = headerButton("CloseAndStop", "×", -40, C.red)
        local statusDot = el("Frame", { BackgroundColor3 = C.muted, Size = UDim2.fromOffset(6, 6),
            Position = UDim2.new(1, -134, 0, 23) }, header)
        round(statusDot, 3)
        local body = el("Frame", { Name = "Body", BackgroundTransparency = 1, Position = UDim2.fromOffset(0, 52),
            Size = UDim2.new(1, 0, 1, -84) }, panel)
        local sidebar = el("Frame", { BackgroundColor3 = C.rail, Size = UDim2.new(0, 150, 1, 0) }, body)
        local sideMark = text("PAINEL LOCAL", UDim2.new(1, -24, 0, 26), UDim2.fromOffset(12, 10), sidebar, C.muted)
        sideMark.TextSize = 10
        local navigation = el("Frame", { BackgroundTransparency = 1, Position = UDim2.fromOffset(9, 43),
            Size = UDim2.new(1, -18, 1, -55) }, sidebar)
        el("UIListLayout", { Padding = UDim.new(0, 7), SortOrder = Enum.SortOrder.LayoutOrder }, navigation)
        local content = el("Frame", { BackgroundTransparency = 1, Position = UDim2.fromOffset(166, 0),
            Size = UDim2.new(1, -182, 1, 0) }, body)
        local pageTitle = text("Visão geral", UDim2.new(1, 0, 0, 25), UDim2.fromOffset(0, 6), content)
        pageTitle.Font = Enum.Font.GothamBold
        pageTitle.TextSize = 19
        local search = el("TextBox", { Name = "Search", Text = "", PlaceholderText = "Buscar nesta aba...",
            PlaceholderColor3 = C.muted, ClearTextOnFocus = false, TextSize = 12, TextColor3 = C.text,
            TextXAlignment = Enum.TextXAlignment.Left, Size = UDim2.new(1, 0, 0, 32),
            Position = UDim2.fromOffset(0, 39), BackgroundColor3 = C.card }, content)
        round(search, 8)
        el("UIPadding", { PaddingLeft = UDim.new(0, 12), PaddingRight = UDim.new(0, 12) }, search)
        local footer = text("Arraste a barra • Canto ↘ ajusta o tamanho • × encerra", UDim2.new(1, -48, 0, 28),
            UDim2.new(0, 16, 1, -30), panel, C.muted)
        footer.TextSize = 10
        local resizeGrip = el("TextButton", { Name = "ResizeGrip", Text = "◢", TextSize = 21, TextColor3 = C.accent,
            BackgroundTransparency = 1, Active = true, Size = UDim2.fromOffset(30, 30),
            Position = UDim2.new(1, -31, 1, -31) }, panel)
        local function applyGeometry()
            local x, y, w, h = geometry:rect()
            panel.Position = UDim2.fromOffset(x, y)
            panel.Size = UDim2.fromOffset(w, h)
            body.Visible, footer.Visible = not geometry.minimized, not geometry.minimized
            resizeGrip.Visible = not geometry.minimized and not geometry.maximized
            minimize.Text = geometry.minimized and "+" or "−"
            maximize.Text = geometry.maximized and "▣" or "□"
            local railWidth = w < 520 and 64 or (w < 580 and 100 or 150)
            sidebar.Size = UDim2.new(0, railWidth, 1, 0)
            content.Position = UDim2.fromOffset(railWidth + 16, 0)
            content.Size = UDim2.new(1, -(railWidth + 32), 1, 0)
            local compactNames = { Inicio = "Início", Farm = "Farm", Needs = "Necess.", Pets = "Pets",
                Event = "Evento", Settings = "Ajustes", Support = "Logs" }
            sideMark.Text = railWidth == 64 and "HUB" or "PAINEL LOCAL"
            for id, button in pairs(navButtons) do
                button.Text = railWidth == 64 and compactNames[id] or button:GetAttribute("FullLabel")
                button.TextSize = railWidth == 64 and 10 or 12
            end
            brand.Text = w < 420 and "ADOPT HUB" or "A  /  ADOPT HUB"
        end
        local function notice(value)
            setText(footer, value)
            messageUntil = os.clock() + 7
        end
        local function at(path)
            local node = api.Config
            for _, key in ipairs(path) do
                if type(node) ~= "table" then return nil end
                node = node[key]
            end
            return node
        end
        local function put(path, value)
            local ok, reason = api.SetSetting(path, value)
            if not ok then notice(reason) end
            return ok
        end
        local function refresh()
            if closed then return end
            for _, callback in ipairs(refreshers) do callback() end
        end
        local function guard(callback)
            return function(...)
                if closed then return end
                local ok, err = pcall(callback, ...)
                if not ok then notice("Erro: " .. tostring(err)) end
                if not closed then refresh() end
            end
        end
        local function filter()
            local query = string.lower(search.Text)
            for _, row in ipairs(rows) do row.obj.Visible = query == "" or string.find(row.key, query, 1, true) ~= nil end
        end
        local pageNames = { {"Inicio", "Início", "Visão geral"}, {"Farm", "Farm", "Controles do farm"},
            {"Needs", "Necessidades", "Necessidades"}, {"Pets", "Pets / ovos", "Pets, ovos e poções"},
            {"Event", "Eventos", "Eventos e Pet Pen"}, {"Settings", "Ajustes", "Ajustes de estabilidade"},
            {"Support", "Diagnóstico", "Estado e diagnóstico"} }
        local titles = {}
        for _, spec in ipairs(pageNames) do
            local id, title = spec[1], spec[2]
            titles[id] = spec[3]
            local page = el("ScrollingFrame", { Name = id, Size = UDim2.new(1, 0, 1, -85),
                Position = UDim2.fromOffset(0, 82), BackgroundTransparency = 1, Visible = id == selected,
                ScrollBarThickness = 3, ScrollBarImageColor3 = C.accent, CanvasSize = UDim2.fromOffset(0, 0),
                AutomaticCanvasSize = Enum.AutomaticSize.Y, ScrollingDirection = Enum.ScrollingDirection.Y }, content)
            el("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }, page)
            el("UIPadding", { PaddingBottom = UDim.new(0, 12), PaddingRight = UDim.new(0, 6) }, page)
            pages[id] = page
            local nav = el("TextButton", { Name = "Tab" .. id, Text = title, TextSize = 12, TextColor3 = C.muted,
                Size = UDim2.new(1, 0, 0, 37), BackgroundColor3 = C.rail, AutoButtonColor = false,
                TextXAlignment = Enum.TextXAlignment.Left }, navigation)
            round(nav, 7)
            el("UIPadding", { PaddingLeft = UDim.new(0, 10) }, nav)
            navButtons[id] = nav
            nav:SetAttribute("FullLabel", title)
            connect(nav.Activated, guard(function() handle.SelectTab(id) end))
        end
        -- Replace the navigation container with a scroll area without changing its children.
        local navScroll = el("ScrollingFrame", { BackgroundTransparency = 1, Size = navigation.Size,
            Position = navigation.Position, AutomaticCanvasSize = Enum.AutomaticSize.Y, CanvasSize = UDim2.fromOffset(0, 0),
            ScrollBarThickness = 2, ScrollingDirection = Enum.ScrollingDirection.Y }, sidebar)
        for _, child in ipairs(navigation:GetChildren()) do child.Parent = navScroll end
        navigation:Destroy()
        function handle.SelectTab(id)
            if not pages[id] then return false end
            selected = id
            for key, page in pairs(pages) do
                page.Visible = key == id
                navButtons[key].BackgroundColor3 = key == id and C.tint or C.rail
                navButtons[key].TextColor3 = key == id and C.accent or C.muted
            end
            pageTitle.Text = titles[id]
            search.Text = ""
            filter()
            return true
        end
        local function row(page, title, description, extraWidth)
            local frame = el("Frame", { Name = title, BackgroundColor3 = C.card, Size = UDim2.new(1, 0, 0, 66) }, pages[page])
            round(frame, 9)
            text(title, UDim2.new(1, -(extraWidth or 70) - 20, 0, 28), UDim2.fromOffset(12, 5), frame)
            local hint = text(description or "", UDim2.new(1, -(extraWidth or 70) - 20, 0, 25), UDim2.fromOffset(12, 34), frame, C.muted)
            hint.TextSize = 10
            table.insert(rows, { obj = frame, key = string.lower(title .. " " .. (description or "")) })
            return frame
        end
        local function heading(page, title)
            local obj = text(title, UDim2.new(1, 0, 0, 24), UDim2.fromOffset(0, 0), pages[page], C.muted)
            obj.Font, obj.TextSize = Enum.Font.GothamBold, 11
        end
        local function toggle(page, title, description, path)
            local frame = row(page, title, description)
            local button = el("TextButton", { Name = "Toggle", Text = "OFF", TextSize = 10, TextColor3 = C.muted,
                Size = UDim2.fromOffset(48, 25), Position = UDim2.new(1, -59, 0.5, -12), BackgroundColor3 = C.border }, frame)
            round(button, 12)
            connect(button.Activated, guard(function()
                local value = at(path) ~= true
                if #path == 2 and path[1] == "Farm" and path[2] == "Enabled" and api.SetFarmEnabled then
                    local ok, message = api.SetFarmEnabled(value)
                    if not ok then notice(message) end
                else put(path, value) end
            end))
            table.insert(refreshers, function()
                local enabled = at(path) == true
                setText(button, enabled and "ON" or "OFF")
                button.BackgroundColor3 = enabled and C.accent or C.border
                button.TextColor3 = enabled and C.bg or C.muted
            end)
        end
        local function action(page, title, description, callback, color)
            local frame = row(page, title, description, 70)
            local button = el("TextButton", { Text = "Executar", TextSize = 10, TextColor3 = C.text,
                Size = UDim2.fromOffset(60, 27), Position = UDim2.new(1, -71, 0.5, -13), BackgroundColor3 = color or C.tint }, frame)
            round(button, 7)
            connect(button.Activated, guard(function()
                local ok, message = callback()
                if message then notice(message) end
                if ok == false and not message then notice("Ação indisponível no momento") end
            end))
        end
        local function field(page, title, description, path, low, high)
            local frame = row(page, title, description, 110)
            local input = el("TextBox", { Name = "Field", Text = tostring(at(path) or ""), TextSize = 11, TextColor3 = C.text,
                ClearTextOnFocus = false, BackgroundColor3 = C.bg, Size = UDim2.fromOffset(96, 30),
                Position = UDim2.new(1, -108, 0.5, -15) }, frame)
            round(input, 7)
            connect(input.FocusLost, guard(function()
                local value = string.match(input.Text, "^%s*(.-)%s*$") or ""
                if low then
                    value = tonumber(value)
                    if not value or value ~= value or math.abs(value) == math.huge then notice("Digite um número válido"); return end
                    value = math.max(low, math.min(high, value))
                end
                put(path, value)
            end))
            table.insert(refreshers, function() if not input:IsFocused() then setText(input, at(path) or "") end end)
        end
        local function listField(page, title, path)
            local frame = row(page, title, "IDs separados por vírgula; vazio limpa a lista.", 180)
            local input = el("TextBox", {Text = table.concat(at(path) or {}, ", "), ClearTextOnFocus = false,
                TextSize = 11, TextColor3 = C.text, BackgroundColor3 = C.bg, Size = UDim2.fromOffset(164, 30),
                Position = UDim2.new(1, -176, 0.5, -15)}, frame)
            round(input, 7)
            connect(input.FocusLost, guard(function()
                local values = {}
                for token in string.gmatch(input.Text, "[^,]+") do
                    local id = string.match(token, "^%s*(.-)%s*$")
                    if id ~= "" and not table.find(values, id) then table.insert(values, id) end
                end
                put(path, values)
            end))
            table.insert(refreshers, function() if not input:IsFocused() then setText(input, table.concat(at(path) or {}, ", ")) end end)
        end
        local function information(page, title, height)
            local frame = el("Frame", { BackgroundColor3 = C.card, Size = UDim2.new(1, 0, 0, height or 90) }, pages[page])
            round(frame, 9)
            text(title, UDim2.new(1, -24, 0, 22), UDim2.fromOffset(12, 9), frame, C.accent)
            local info = text("", UDim2.new(1, -24, 1, -43), UDim2.fromOffset(12, 35), frame, C.muted)
            info.TextSize = 12
            info.TextYAlignment = Enum.TextYAlignment.Top
            table.insert(rows, { obj = frame, key = string.lower(title) })
            return info
        end
        local overview = information("Inicio", "SESSÃO", 108)
        local currentNeeds = information("Inicio", "NECESSIDADES ATIVAS", 96)
        toggle("Inicio", "Farm em execução", "Pausar cancela as tarefas atuais.", {"Farm", "Enabled"})
        action("Inicio", "Necessidades estáveis", "Pets selecionados em sequência; bebê opcional. Inicia pausado.", function() return api.ApplyPreset("NeedsStable") end)
        heading("Farm", "EXECUÇÃO E RECUPERAÇÃO")
        toggle("Farm", "Farm em execução", "Inicia ou pausa a automação.", {"Farm", "Enabled"})
        toggle("Farm", "Manter pet equipado", "Mantém um pet disponível para as necessidades.", {"Farm", "KeepPetEquipped"})
        toggle("Farm", "Modo bebê", "Inclui suas necessidades de bebê.", {"Farm", "BabyMode"})
        toggle("Farm", "Anti-AFK", "Responde ao aviso de inatividade.", {"Farm", "AntiAfk"})
        toggle("Farm", "Necessidades primeiro", "Antes de tarefas de evento sem horário urgente.", {"Farm", "PrioritizeNeeds"})
        toggle("Farm", "Prioridade inteligente", "Prefere necessidades no local atual.", {"Farm", "SmartPriority"})
        toggle("Farm", "Coletar cashback", "Usa a coleta existente no jogo.", {"Farm", "CollectCashback"})
        action("Farm", "Voltar para casa", "Tarefas protegidas terminam antes da viagem.", api.GoHome)
        action("Farm", "Pular tarefa", "Deixa a tarefa atual descansar.", api.SkipTask)
        local needsSummary = information("Needs", "FILA EM TEMPO REAL", 144)
        toggle("Needs", "Necessidades automáticas", "Habilita os tipos escolhidos abaixo.", {"Farm", "AutoNeeds", "Enabled"})
        toggle("Needs", "Necessidades em paralelo", "Experimental com um pet; desligado para duplas.", {"Farm", "MultiNeed", "Enabled"})
        heading("Needs", "TIPOS DE NECESSIDADE")
        local needKeys = {}
        for kind in pairs(api.Config.Farm.Tasks or {}) do table.insert(needKeys, kind) end
        table.sort(needKeys)
        for _, kind in ipairs(needKeys) do toggle("Needs", NEEDS[kind] or kind, kind, {"Farm", "Tasks", kind}) end
        heading("Pets", "PET SELECIONADO E COMPRAS")
        field("Pets", "Pet / ovo focado", "Identificador do inventário; exemplo: cracked_egg.", {"Farm", "Focus"})
        field("Pets", "Ovo a comprar", "Use o identificador interno do ovo.", {"Farm", "EggToBuy"})
        toggle("Pets", "Dois pets / Pet Certificate", "Usa dois slots já autorizados pelo jogo.", {"Farm", "TwoPets"})
        toggle("Pets", "Preservar seleção manual", "Protege um ou dois pets, inclusive Full Grown.", {"Farm", "KeepEquippedPair"})
        action("Pets", "Atualizar seleção", "Pause, equipe os pets e confirme a seleção atual.", api.RefreshSelection)
        local selectionInfo = information("Pets", "SELEÇÃO PROTEGIDA", 95)
        table.insert(refreshers, function()
            local selection = api.Status().selection
            selectionInfo.Text = selection and ("IDs: " .. table.concat(selection.ids or {}, ", ")
                .. "\nDois slots observados: " .. tostring(selection.twoSlotsObserved)
                .. " | proteção: " .. tostring(selection.enabled)) or "Aguardando dados do jogo"
        end)
        toggle("Pets", "Comprar comida", "Autoriza compras de comida quando não houver estoque.", {"Farm", "BuyFood"})
        toggle("Pets", "Comprar água", "Autoriza compras de água quando não houver estoque.", {"Farm", "BuyWater"})
        field("Pets", "Limite de compras", "Comida e água por sessão; zero sem limite.", {"Farm", "MaxBuysPerSession"}, 0, 1000)
        field("Pets", "Limite de ovos", "Ovos por sessão; zero sem limite.", {"Farm", "MaxEggBuysPerSession"}, 0, 1000)
        toggle("Pets", "Comprar ovos", "Gasta Bucks quando a compra for necessária.", {"Farm", "BuyEgg"})
        toggle("Pets", "Usar poções", "Mantém o controle de intervalo em memória.", {"Farm", "AutoPotions", "Enabled"})
        toggle("Pets", "Criar Neon", "Pode consumir quatro pets elegíveis.", {"Farm", "AutoNeon", "Enabled"})
        toggle("Pets", "Criar Mega Neon", "Pode consumir quatro pets Neon elegíveis.", {"Farm", "AutoNeon", "Mega"})
        toggle("Pets", "Abrir presentes", "Pode consumir presentes do inventário.", {"Farm", "AutoOpen", "Enabled"})
        action("Pets", "Alternar ordem", "Mais novos ou mais velhos primeiro.", function()
            put({"Farm", "PetOrder"}, api.Config.Farm.PetOrder == "oldest" and "youngest" or "oldest")
            return true, "Ordem: " .. api.Config.Farm.PetOrder
        end)
        heading("Pets", "FILTROS")
        listField("Pets", "Tipos de pet preferidos", {"Farm", "FarmPetKinds"})
        listField("Pets", "Poções permitidas", {"Farm", "AutoPotions", "Potions"})
        listField("Pets", "Poções ignoradas", {"Farm", "AutoPotions", "Skip"})
        listField("Pets", "Tipos que recebem poções", {"Farm", "AutoPotions", "PetKinds"})
        listField("Pets", "Tipos excluídos de fusões", {"Farm", "AutoNeon", "Exclude"})
        listField("Pets", "Presentes excluídos", {"Farm", "AutoOpen", "Exclude"})
        toggle("Pets", "Trocar Full Grown", "Somente com proteção manual desativada.", {"Farm", "SkipFullGrown"})
        toggle("Pets", "Preferir Neon", "Ordem automática com proteção desativada.", {"Farm", "PreferNeon"})
        field("Pets", "Intervalo de buffs", "Minutos mínimos por pet e tipo de poção.", {"Farm", "AutoPotions", "BuffMinutes"}, 0, 1440)
        heading("Pets", "PRESETS")
        local presets = {{"Off", "Tudo desligado"}, {"NeedsStable", "Necessidades estáveis"}, {"Balanced", "AutoFarm completo"}, {"Focus", "Focar no pet / ovo"},
            {"Speedrun", "Mega Mummy Spider"}, {"Skelicorn", "Mega Skelicorn"}, {"EventOnly", "Só evento"}}
        for _, preset in ipairs(presets) do
            local key = preset[1]
            action("Pets", preset[2], "Pode alterar compras, poções e fusões; revise antes de ligar.", function()
                if key == "Focus" and (api.Config.Farm.Focus or "") == "" then return false, "Preencha o pet / ovo focado" end
                return api.ApplyPreset(key)
            end)
        end
        listField("Needs", "Necessidades ignoradas", {"Farm", "AutoNeeds", "Skip"})
        heading("Event", "EVENTOS DISPONÍVEIS NO SCRIPT")
        toggle("Event", "Eventos habilitados", "Controle principal dos recursos de evento.", {"Farm", "Event", "Enabled"})
        for _, item in ipairs({{"GhostGallery","Ghost Gallery"},{"Hauntlet","Hauntlet"},{"Crypt","Crypt"},
            {"MummySpider","Mummy Spider"},{"Quests","Missões"},{"HouseVisits","Visitar casas"},
            {"StrayCat","Stray Cat"},{"PigeonNest","Pigeon Nest"},{"PetPen","Pet Pen"},
            {"PetPenStock","Estoque do Pet Pen"},{"AutoSkelicorn","Auto Skelicorn"}}) do
            toggle("Event", item[2], "Depende do evento e das regras atuais do jogo.", {"Farm", "Event", item[1]})
        end
        toggle("Event", "Comprar pets com Candy", "Pode gastar a moeda do evento.", {"Farm", "Event", "CandyPets", "Enabled"})
        listField("Event", "Pets escolhidos na loja Candy", {"Farm", "Event", "CandyPets", "Pick"})
        listField("Event", "Recompensas da Crypt", {"Farm", "Event", "CryptOpen"})
        field("Event", "Reserva de Candy", "Saldo mínimo após compras opcionais.", {"Farm", "Event", "CandyPets", "KeepCandy"}, 0, 1000000000)
        toggle("Event", "Compra em quantidade", "Aguarda confirmação do lote no inventário.", {"Farm", "Event", "CandyPets", "MaxBuy"})
        toggle("Event", "Ninho automático", "Organiza gravetos e construção do ninho.", {"Farm", "Event", "AutoNest"})
        toggle("Event", "Hauntlet primeiro", "Prioridade entre os dois minijogos.", {"Farm", "Event", "HauntletFirst"})
        field("Event", "Slots do Pet Pen", "Configure a capacidade autorizada da conta.", {"Farm", "Event", "PetPenSlots"}, 1, 12)
        field("Event", "Intervalo do Pet Pen", "Minutos entre verificações (1–120).", {"Farm", "Event", "PetPenMinutes"}, 1, 120)
        action("Event", "Coletar Pet Pen", "Solicita a coleta quando o farm está ligado.", api.ClaimPetPen)
        toggle("Settings", "Lembrar ajustes", "Somente na memória deste cliente; reinicia pausado.", {"Interface", "RememberSettings"})
        heading("Settings", "ESTABILIDADE")
        toggle("Settings", "Recuperar travamentos", "Recuperação existente quando há falhas repetidas.", {"Farm", "StuckRecovery", "Enabled"})
        field("Settings", "Tempo de recuperação", "Segundos sem progresso (60–600).", {"Farm", "StuckRecovery", "Seconds"}, 60, 600)
        field("Settings", "Espera após erro", "Base em segundos; aumenta em falhas seguidas.", {"Farm", "FailureCooldownSeconds"}, 5, 120)
        field("Settings", "Limite de falhas", "Número de falhas antes de descansar (1–10).", {"Farm", "MaxConsecutiveFailures"}, 1, 10)
        field("Settings", "Descanso de tarefas", "Minutos; zero desativa pelo resto da sessão.", {"Farm", "DisableMinutes"}, 0, 60)
        toggle("Settings", "Aceitar menu inicial", "Fecha o menu Play quando o farm estiver ligado.", {"Farm", "AutoAcceptMenu"})
        toggle("Settings", "Fechar diálogos", "Diálogos reconhecidos do jogo.", {"Farm", "AutoCloseDialogs"})
        toggle("Settings", "Viagem pelo módulo do jogo", "InteriorsM quando disponível.", {"Farm", "GameTravel"})
        action("Settings", "Viagem sem reset", "Casa → vizinhança → cidade → porta do destino. Retorno sem respawn.", function()
            return true, "Viagens por portas; piso confirmado e apoio temporário contra quedas."
        end)
        toggle("Settings", "Viajar para tigela", "Autoriza voltar para casa para alimentar.", {"Farm", "FoodBowlTrip"})
        toggle("Settings", "Reconectar automaticamente", "Reentra após falha prolongada, quando habilitado.", {"Farm", "AutoRejoin"})
        toggle("Settings", "Ajustar câmera", "Afasta a câmera quando presa no personagem.", {"Farm", "CameraGuard"})
        field("Settings", "Viagem para pontos", "teleport, door ou walk.", {"Farm", "SpotTravel"})
        action("Settings", "Reativar tarefas", "Libera tarefas em espera ou desativadas.", api.RetryDisabled)
        action("Settings", "Centralizar janela", "Reposiciona o HUB dentro da tela.", function()
            geometry.maximized, geometry.restore, geometry.minimized = false, nil, false
            geometry:moveTo((geometry.vw - geometry.w) / 2, (geometry.vh - geometry.h) / 2)
            applyGeometry(); return true, "Janela centralizada"
        end)
        local diagnostic = information("Support", "ESTADO DO MOTOR", 250)
        local privacy = information("Support", "PRIVACIDADE", 108)
        privacy.Text = "Sem telemetria, webhooks ou arquivos locais.\nO HUB usa somente instâncias Roblox.\nArquivo consolidado; sem download de código externo."
        local reportBox
        action("Support", "Mostrar relatório local", "Texto em memória para você selecionar e copiar.", function()
            reportBox.Text = api.ProblemReport and api.ProblemReport() or "Relatório indisponível"
            reportBox.Visible = true
            return true, "Selecione o texto do relatório para copiar"
        end)
        reportBox = el("TextBox", { Name = "LocalReport", Text = "", Visible = false, MultiLine = true,
            ClearTextOnFocus = false, TextEditable = false, TextWrapped = true, TextSize = 11,
            TextColor3 = C.text, TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top,
            Size = UDim2.new(1, 0, 0, 300), BackgroundColor3 = C.card }, pages.Support)
        round(reportBox, 9)
        action("Support", "Reabrir tarefas", "Libera os intervalos de espera após falhas.", api.RetryDisabled)
        action("Support", "Encerrar script", "Fecha o HUB e cancela a automação.", function() api.Stop("closed from HUB"); return true end, C.red)
        function handle.Close()
            if closed then return end
            closed = true
            scope.cleanup()
            if Interface.current == handle then Interface.current = nil end
        end
        function handle.Minimize() geometry:toggleMinimize(); applyGeometry() end
        function handle.Maximize() geometry:toggleMaximize(); applyGeometry() end
        local gesture
        local function beginGesture(input, mode)
            if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then return end
            if geometry.maximized then return end
            gesture = { input = input, touch = input.UserInputType == Enum.UserInputType.Touch, mode = mode,
                px = input.Position.X, py = input.Position.Y, x = geometry.x, y = geometry.y, w = geometry.w, h = geometry.h }
        end
        connect(dragArea.InputBegan, function(input) beginGesture(input, "move") end)
        connect(resizeGrip.InputBegan, function(input) beginGesture(input, "resize") end)
        connect(UIS.InputChanged, function(input)
            if not gesture then return end
            if gesture.touch and input ~= gesture.input then return end
            if not gesture.touch and input.UserInputType ~= Enum.UserInputType.MouseMovement then return end
            local dx, dy = input.Position.X - gesture.px, input.Position.Y - gesture.py
            if gesture.mode == "move" then geometry:moveTo(gesture.x + dx, gesture.y + dy)
            else geometry:resizeTo(gesture.w + dx, gesture.h + dy) end
            applyGeometry()
        end)
        connect(UIS.InputEnded, function(input)
            if gesture and (input == gesture.input or (not gesture.touch and input.UserInputType == Enum.UserInputType.MouseButton1)) then gesture = nil end
        end)
        local keybind = Enum.KeyCode.RightShift
        pcall(function() keybind = Enum.KeyCode[tostring(api.Config.Interface.Keybind or "RightShift")] end)
        connect(UIS.InputBegan, function(input, processed)
            if not processed and not UIS:GetFocusedTextBox() and input.KeyCode == keybind then handle.Minimize() end
        end)
        connect(minimize.Activated, handle.Minimize)
        connect(maximize.Activated, handle.Maximize)
        connect(closeButton.Activated, function() api.Stop("closed from HUB"); handle.Close() end)
        connect(search:GetPropertyChangedSignal("Text"), filter)
        local cameraConnection
        local function watchCamera()
            if cameraConnection then cameraConnection:Disconnect() end
            local active = workspace.CurrentCamera
            if not active then return end
            local function changed()
                geometry:setViewport(active.ViewportSize.X, active.ViewportSize.Y)
                gesture = nil
                applyGeometry()
            end
            cameraConnection = active:GetPropertyChangedSignal("ViewportSize"):Connect(changed)
            scope.cameraConnection = cameraConnection
            changed()
        end
        connect(workspace:GetPropertyChangedSignal("CurrentCamera"), watchCamera)
        watchCamera()
        local function renderStatus()
            local ok, info = pcall(api.Status)
            if not ok or type(info) ~= "table" then notice("Aguardando dados do jogo"); return end
            if info.stopped then handle.Close(); return end
            statusDot.BackgroundColor3 = info.farmEnabled and C.green or C.muted
            if geometry.minimized then return end
            local state = info.farmEnabled and (info.ready and "EM EXECUÇÃO" or "AGUARDANDO O JOGO") or "PAUSADO"
            setText(overview, string.format("%s   •   %s min\nBucks: %s   •   Candy: %s\nNecessidades concluídas: %s\nTarefa: %s", state,
                tostring(info.minutes or 0), tostring(info.bucks or "—"), tostring(info.candy or "—"), tostring(info.needsDone or 0), NEEDS[info.task] or info.task or "nenhuma"))
            local short, long = {}, {}
            for i, entry in ipairs(info.needs or {}) do
                if i > 12 then table.insert(long, "+ outras necessidades"); break end
                local who = "Bebê"
                if entry.owner == "pet" then
                    who = "Pet " .. tostring(entry.petUnique or "?")
                    for index, pet in ipairs(info.pets or {}) do
                        if pet.unique == entry.petUnique then who = "Pet " .. index .. " (" .. tostring(pet.kind or "?") .. ")"; break end
                    end
                end
                local progress = math.floor(math.max(0, math.min(1, tonumber(entry.progress) or 0)) * 100)
                local line = who .. " • " .. (NEEDS[entry.kind] or tostring(entry.kind))
                    .. (entry.inProgress and (" • " .. progress .. "%") or " • aguardando")
                table.insert(long, line)
                if i <= 3 then table.insert(short, line) end
            end
            setText(currentNeeds, #short > 0 and table.concat(short, "\n") or "Nenhuma necessidade ativa no momento.")
            setText(needsSummary, #long > 0 and table.concat(long, "\n") or "Sem necessidades ativas. Verifique pet equipado e modo bebê.")
            needsSummary.Parent.Size = UDim2.new(1, 0, 0, math.max(144, 55 + #long * 22))
            local waits = {}
            for key, seconds in pairs(info.retrySeconds or {}) do table.insert(waits, (NEEDS[key] or key) .. ": " .. seconds .. "s") end
            table.sort(waits)
            local details = "Atendimento: " .. tostring(info.needTarget or "nenhum") .. "\n"
                .. "Pets equipados: " .. tostring(#(info.pets or {})) .. " • Dupla: " .. tostring(info.twoPetsEnabled) .. "\n"
                .. "Tarefa: " .. tostring(info.task or "nenhuma") .. "\n"
                .. "Motivo: " .. tostring(info.waitReason or (info.ready and "sem tarefa pendente" or "jogo não está pronto")) .. "\n"
                .. "Sucessos: " .. tostring(info.tasksSucceeded or 0) .. " • Falhas: " .. tostring(info.tasksFailed or 0) .. "\n"
                .. "Descansando: " .. table.concat(info.disabled or {}, ", ") .. "\n"
                .. "Nova tentativa: " .. (#waits > 0 and table.concat(waits, ", ") or "nenhuma")
                .. "\nÚltima falha: " .. (info.lastFailure and (info.lastFailure.task .. ": " .. info.lastFailure.reason) or "nenhuma")
            setText(diagnostic, details)
            if os.clock() >= messageUntil then setText(footer, "Arraste a barra • Canto ↘ ajusta o tamanho • × encerra") end
            refresh()
        end
        handle.SelectTab("Inicio")
        if api.Config.Interface.StartHidden == true then geometry:toggleMinimize() end
        applyGeometry()
        renderStatus()
        scope.thread = task.spawn(function()
            while not closed and gui.Parent do
                task.wait(1)
                if not closed then
                    local ok, err = pcall(renderStatus)
                    if not ok then notice("Falha ao atualizar painel: " .. tostring(err)) end
                end
            end
            if not closed then handle.Close() end
        end)
        return handle
    end
    function Interface.start(api, options)
        assert(type(api) == "table" and type(api.Config) == "table", "API do HUB indisponível")
        if Interface._starting then return nil, "HUB já está abrindo" end
        if Interface.current and Interface.current.Owner == api then return Interface.current end
        if Interface.current then Interface.current.Close() end
        Interface._starting = true
        local scope = { connections = {} }
        function scope.cleanup()
            for _, connection in ipairs(scope.connections) do pcall(function() connection:Disconnect() end) end
            scope.connections = {}
            if scope.cameraConnection then pcall(function() scope.cameraConnection:Disconnect() end) end
            if scope.thread and coroutine.running() ~= scope.thread then pcall(task.cancel, scope.thread) end
            if scope.gui then pcall(function() scope.gui:Destroy() end) end
        end
        local ok, result = pcall(build, api, scope)
        Interface._starting = false
        if not ok then scope.cleanup(); error(result, 0) end
        if api.Status().stopped then scope.cleanup(); return nil, "Script encerrado" end
        Interface.current = result
        return result
    end
    return Interface
end

__moduleSources["Game/GameConstants"] = function(...)
    local GameConstants = {}
    GameConstants.PlaceId = 920587237
    GameConstants.Remotes = {
        Folder = "API",
        DataChanged = "DataAPI/DataChanged",
        DataPartiallyChanged = "DataAPI/DataPartiallyChanged",
        PetAilmentCompleted = "AilmentsAPI/PetAilmentCompleted",
        BabyAilmentCompleted = "AilmentsAPI/BabyAilmentCompleted",
        MinigameMessage = "MinigameAPI/MessageClient",
        EventFolder = "adoptme_new_net",
    }
    GameConstants.DataKeys = {
        Ailments = "ailments_manager",
        Money = "money",
        Equip = "equip_manager",
        Team = "team",
        Interior = "house_interior",
        PetWrappers = "pet_char_wrappers_raw",
        Inventory = "inventory",
        StateManager = "state_manager_raw",
        CharWrapper = "char_wrapper_raw",
        Candy = "candy_2026",
        PetPen = "idle_progression_manager",
        StrayCat = "halloween_2026_stray_cat_manager",
        Crypt = "halloween_2026_crypt_manager",
        PigeonNest = "halloween_2026_jacobean_pigeon_nest_manager",
        LightningLever = "halloween_2026_lightning_lever_manager",
        GhostCycle = "ghost_clusters_cycle_timestamp",
        Dailies = "dailies_manager",
        Hauntlet = "halloween_2026_hauntlet_manager",
        HauntletCycle = "hauntlet_cycle_timestamp",
    }
    GameConstants.PetsFolderName = "Pets"
    GameConstants.PetModelIdAttribute = "StreamingId"
    GameConstants.ClientDataModulePath = { "ClientModules", "Core", "ClientData" }
    GameConstants.Actions = {
        ChooseTeam = { remote = "TeamAPI/ChooseTeam", purpose = "switch your team to Babies (Farm.BabyMode)" },
        FocusPet = { remote = "AdoptAPI/FocusPet", purpose = "pet_me: focus your pet" },
        PetPetted = { remote = "PetAPI/PetPetted", purpose = "pet_me: pet your pet" },
        ProgressPetMe = { remote = "AilmentsAPI/ProgressPetMeAilment", purpose = "pet_me: report the petting" },
        UnfocusPet = { remote = "AdoptAPI/UnfocusPet", purpose = "pet_me: unfocus your pet" },
        DoorEnter = { remote = "AdoptAPI/SendPassiveDoorEnter", purpose = "travel: enter a place (house, salon, cat cafe, main map)" },
        SetLocation = { remote = "LocationAPI/SetLocation", purpose = "travel: move to that place" },
        SubscribeToHouse = { remote = "HousingAPI/SubscribeToHouse", purpose = "travel: load YOUR house when going home" },
        UnsubscribeFromHouse = { remote = "HousingAPI/UnsubscribeFromHouse", purpose = "travel: unload YOUR house when leaving it" },
        MarkEnteredDoorTime = { remote = "AdoptAPI/MarkEnteredDoorTime", purpose = "leaving your house: the game's own door-time mark (no arguments)" },
        PushFurnitureChanges = { remote = "HousingAPI/PushFurnitureChanges", purpose = "leaving your house: sent EMPTY ({}) as the game does; never changes furniture", emptyOnly = true },
        CollectCashback = { remote = "PayAPI/Collect", purpose = "collect your cashback Bucks (Farm.CollectCashback)" },
        ChooseMystery = { remote = "AilmentsAPI/ChooseMysteryAilment", purpose = "mystery: pick a need this script can do" },
        ActivateFurniture = { remote = "HousingAPI/ActivateFurniture", purpose = "use YOUR bed / shower / toilet for your pet or baby",
            answersWhenDone = true },
        ExitSeatStates = { remote = "AdoptAPI/ExitSeatStates", purpose = "get your character (baby) up from furniture" },
        ExitFurnitureUseStates = { remote = "PetAPI/ExitFurnitureUseStates", purpose = "get your pet up if it stays on furniture" },
        EquipItem = { remote = "ToolAPI/Equip", purpose = "hold YOUR food, drink, toy, Rusty Key, Crypt Twig or the loaned Ghost Vacuum; re-equip YOUR pet ({equip_as_last=true}, as the game at spawn); neon fusion: hold each of the 4 pets once" },
        Respawn = { remote = "TeamAPI/Spawn", purpose = "go home fast by respawning (Farm.HomeByRespawn); recover when stuck on the loading screen" },
        UseTool = { remote = "ToolAPI/ServerUseTool", purpose = "eat / drink / throw the item you hold; switch on the Ghost Vacuum (its answer is the vacuum token)" },
        UnequipItem = { remote = "ToolAPI/Unequip", purpose = "put the item away" },
        ActivateInteriorFurniture = { remote = "HousingAPI/ActivateInteriorFurniture", purpose = "sick: talk to the doctor in the Hospital" },
        UnequipStroller = { remote = "AdoptAPI/UnequipStroller", purpose = "ride: put the stroller away" },
        CreatePetObject = { remote = "PetObjectAPI/CreatePetObject", purpose = "give food/drink to your pet, throw a toy for it" },
        ConsumeFoodObject = { remote = "PetAPI/ConsumeFoodObject", purpose = "your pet eats the given food (only if the game did not)" },
        GrabPetObject = { remote = "PetObjectAPI/GrabPetObject", purpose = "your pet catches the toy (only if the game did not)" },
        DropPetObject = { remote = "PetObjectAPI/DropPetObject", purpose = "your pet gives the toy back" },
        PetPenAdd = { remote = "IdleProgressionAPI/AddPet", purpose = "Pet Pen: put one of YOUR growing pets in the pen (Farm.Event.PetPen)" },
        PetPenRemove = { remote = "IdleProgressionAPI/RemovePet", purpose = "Pet Pen: take a FULL GROWN pet out of the pen" },
        PetPenClaim = { remote = "IdleProgressionAPI/CommitAllProgression", purpose = "Pet Pen: CLAIM ALL (the pen's xp and Bucks)" },
        PetPerformance = { remote = "PetAPI/ReplicateActivePerformances", purpose = "pet_me: show the petting animation, as the game does" },
        StrayCatFeed = { remote = "Halloween2026/StrayCatGiftFood", folder = "EventFolder", purpose = "Halloween: give 1 water to the Stray Cat once a day (Farm.Event.StrayCat)" },
        UnlockPadlock = { remote = "Halloween2026/UnlockPadlock", folder = "EventFolder", purpose = "Halloween: use YOUR Rusty Key on a Crypt grave (Farm.Event.Crypt)" },
        PigeonNestTwig = { remote = "Halloween2026/JacobeanPigeonNestContributeTwig", folder = "EventFolder", purpose = "Halloween: put YOUR Crypt Twig in the Hotel nest (Farm.Event.PigeonNest)" },
        MinigameJoin = { remote = "MinigameAPI/AttemptJoin", purpose = "Halloween: join the Ghost Gallery minigame (Farm.Event.GhostGallery)" },
        MinigameLeave = { remote = "MinigameAPI/AttemptJoin", purpose = "Ghost Gallery: leave a round I could not get into (the game's own exit call)",
            leaveOnly = true },
        MinigameMessage = { remote = "MinigameAPI/MessageServer", purpose = "Ghost Gallery: vacuum a ghost or a haunted prop (start / stop only)",
            allowedMessages = { start_contribute = true, stop_contribute = true, start_prop_contribute = true, stop_prop_contribute = true } },
        HauntletJoin = { remote = "MinigameAPI/AttemptJoin", purpose = "Halloween: join a Hauntlet run (Farm.Event.Hauntlet)",
            joinPrefix = "hauntlet" },
        HauntletMessage = { remote = "MinigameAPI/MessageServer", purpose = "Hauntlet: pick a door (1-3) or use one of MY run items",
            hauntletMessage = true },
        UnlockHauntletJournal = { remote = "Halloween2026API/UnlockHauntletJournalPage", purpose = "Hauntlet journal page unlock (Farm.Event.Hauntlet)",
            noArgs = true },
        QuestClaim = { remote = "adoptme_new.modules.Dailies.DailiesNetService:9", folder = "EventFolder",
            purpose = "claim a finished daily quest (Halloween / normal tab) (Farm.Event.Quests)",
            allowedFirstArg = { halloween_2026 = true, vanilla = true } },
        QuestTabReward = { remote = "adoptme_new.modules.Dailies.DailiesNetService:15", folder = "EventFolder",
            purpose = "claim a quest board reward after 3 quests of the day (Rusty Key / egg) (Farm.Event.Quests)",
            allowedFirstArg = { halloween_2026 = true, vanilla = true } },
        OpenGift = { remote = "ShopAPI/OpenGift", purpose = "open YOUR gift (Farm.AutoOpen)" },
        OpenChest = { remote = "LootBoxAPI/ExchangeItemForReward", purpose = "open YOUR chest (Farm.AutoOpen)" },
        LightningLeverDeliver = { remote = "Halloween2026/LightningLeverDeliver", folder = "EventFolder",
            purpose = "Halloween: install YOUR Lightning Lever in the machine by the Manor, once (Farm.Event.AutoSkelicorn)",
            recordedArgs = "deliver" },
        LightningLeverActivate = { remote = "Halloween2026/LightningLeverActivate", folder = "EventFolder",
            purpose = "Halloween: pull the installed Lightning Lever (Farm.Event.AutoSkelicorn)", recordedArgs = "activate" },
        ClaimTombSpider = { remote = "Halloween2026/ClaimTombSpider", folder = "EventFolder",
            purpose = "Halloween: take the Mummy Spider at the bottom of the Crypt (Farm.Event.Crypt)" },
        NeonFusion = { remote = "PetAPI/DoNeonFusion", purpose = "neon fusion: 4 of YOUR full grown pets of one kind -> 1 neon (Farm.AutoNeon)" },
        BuyItem = { remote = "ShopAPI/BuyItem", purpose = "buy 1 water / 1 hotdog when you have none; 1 egg (Farm.EggToBuy) when you have no pet that still grows (Farm.BuyEgg); Halloween pets with candy (Farm.Event.CandyPets)" },
    }
    GameConstants.BabiesTeam = "Babies"
    GameConstants.ChooseTeamOptions = { dont_respawn = true, source_for_logging = "avatar_editor" }
    GameConstants.Travel = {
        housing = { door = "MainDoor", spawn = nil, ownHouse = true },
        Salon = { door = "MainDoor", spawn = nil },
        MainMap = { door = "Neighborhood!MainDoor", spawn = "Default" },
        CatCafe = { door = "MainDoor", spawn = nil },
        PizzaShop = { door = "MainDoor", spawn = nil },
        School = { door = "MainDoor", spawn = nil },
        Hospital = { door = "MainDoor", spawn = nil },
        CampingShop = { door = "MainDoor", spawn = nil },
        BeachShop = { door = "MainDoor", spawn = nil },
        BabyShop = { door = "MainDoor", spawn = nil },
        Nursery = { door = "MainDoor", spawn = nil },
        HauntedManor = { door = "MainDoor", spawn = nil },
        TheCrypt = { door = "MainDoor", spawn = nil },
        HauntedHotel = { door = "MainDoor", spawn = nil },
    }
    -- Coordinates from supplied XML: prefetch hints ONLY. Every crossing still requires its live door.
    GameConstants.TravelStreamHints = {
        MainMap = {
            AFKZone = Vector3.new(-1.060724, 225.859924, -0.476261),
            AutoShop = Vector3.new(-47.875854, 31.152748, -1753.772583),
            BabyShop = Vector3.new(-468.813446, 31.671501, -1668.677734),
            BeachShop = Vector3.new(-716.995911, 27.890251, -1438.431763),
            CampingShop = Vector3.new(-64.106560, 33.888176, -1183.995605),
            CatCafe = Vector3.new(-14.426981, 32.030346, -1647.773560),
            Cave = Vector3.new(-250.424881, 29.464592, -1645.655762),
            CoffeeShop = Vector3.new(-276.171997, 31.105827, -1770.177856),
            DebugInterior = Vector3.new(-1.060724, 223.859924, -0.476261),
            HatShop = Vector3.new(-525.781799, 37.793865, -1308.670532),
            HauntedHotel = Vector3.new(-308.099121, 33.647285, -1419.082275),
            HauntedManor = Vector3.new(-271.259003, 94.725632, -1102.953857),
            Hospital = Vector3.new(-205.352524, 32.089848, -1536.464478),
            IceCream = Vector3.new(-218.577606, 34.297012, -1774.354858),
            Neighborhood = Vector3.new(-255.096207, 36.209099, -1832.578735),
            Nursery = Vector3.new(-244.290726, 32.626022, -1474.407471),
            Obbies = Vector3.new(-464.683960, 32.887390, -1823.499023),
            PetShop = Vector3.new(-185.120895, 32.669109, -1512.191772),
            PizzaShop = Vector3.new(-119.818581, 30.879934, -1663.734009),
            Portal = Vector3.new(-249.399384, 34.164021, -1500.888184),
            SafetyHub = Vector3.new(-500.091827, 33.360893, -1198.322266),
            Salon = Vector3.new(-132.087402, 32.431572, -1768.400146),
            School = Vector3.new(-312.581421, 32.109123, -1506.915771),
            SkyCastle = Vector3.new(-222.226578, 366.421539, -1350.972778),
            Supermarket = Vector3.new(-394.851654, 31.523064, -1200.463745),
            TheCrypt = Vector3.new(-337.640137, 37.066628, -1181.633911),
            ToyShop = Vector3.new(-88.556580, 34.227211, -1706.538086),
        },
        Neighborhood = { MainMap = Vector3.new(-9101.707031, 10226.072266, 3043.519531) },
    }
    GameConstants.CharWrapperPlaces = { TheCrypt = true }
    GameConstants.InteriorTalkForAilment = {
        sick = { furniture = "doctor", use = "UseBlock", choice = "Yes" },
    }
    GameConstants.SpotDoor = {
        camping = { place = "CampingShop", exit = { x = -50.4, z = -1197.7 } },
        beach_party = { place = "BeachShop", exit = { x = -704.8, z = -1442.3 } },
        bored = { place = "BabyShop", exit = { x = -457.4, z = -1672.1 } },
    }
    GameConstants.LocationForAilment = {
        salon = "Salon",
        bored = "MainMap",
        cat_cafe = "CatCafe",
        pizza_party = "PizzaShop",
        school = "School",
        sick = "Hospital",
        camping = "MainMap",
        beach_party = "MainMap",
    }
    GameConstants.PlayButtonPath = { "NewsApp", "EnclosingFrame", "MainFrame", "Buttons", "PlayButton" }
    GameConstants.MysteryPreference = { "toilet", "dirty", "sleepy", "hungry", "thirsty", "pet_me", "play", "sick", "cat_cafe",
        "salon", "school", "pizza_party", "camping", "beach_party", "bored", "walk", "ride" }
    GameConstants.MysterySlot = 1
    GameConstants.StrollerCategory = "strollers"
    GameConstants.WalkSeconds = 45
    GameConstants.Spots = {
        camping = { x = -18.443, y = 37.204, z = -1046.005, purpose = "camping: the camp site in the neighborhood" },
        beach_party = { x = -579.456, y = 25.634, z = -1496.408, purpose = "beach_party: the beach in the neighborhood" },
        bored = { x = -401.629, y = 29.779, z = -1760.047, purpose = "bored: the playground in the neighborhood" },
        stray_cat = { x = -243.6, y = 87.0, z = -1118.2, purpose = "Halloween: next to the Stray Cat" },
    }
    GameConstants.SpotForAilment = {
        camping = "camping",
        beach_party = "beach_party",
        bored = "bored",
    }
    GameConstants.HouseInteriorName = "housing"
    GameConstants.HouseExitDestination = "exit_housing"
    GameConstants.HouseExitCameraOffset = { x = 0.68896484375, y = 8.55078125, z = 8.8720703125,
        rx = -0.7369100451469421, ry = 0.05742141604423523, rz = 0.05203080177307129 }
    GameConstants.FullGrownAge = 6
    -- v2.1.4 "Mega a Pet" (Farm.Focus): what the picked id is, and how its copies are got.
    --   egg       -> bought with Bucks and hatched on repeat (Farm.EggToBuy is replaced by it)
    --   candy     -> bought with candy until Pet Pen slots + 1 copies grow (1 raised, the rest in the pen)
    --   spider    -> the Crypt + Mummy Spider
    --   skelicorn -> Auto Skelicorn, bought again every 120k candy while fewer than slots + 1 grow
    --   pet       -> only grown / neon / mega (no way to get more copies)
    function GameConstants.focusOf(farm)
        local id = type(farm) == "table" and type(farm.Focus) == "string" and string.match(farm.Focus, "^%s*(.-)%s*$") or ""
        if id == "" then
            return nil
        end
        if GameConstants.isEgg(id) then
            return { id = id, kind = "egg" }
        end
        local E = GameConstants.Event or {}
        if id == E.MummySpiderKind then
            return { id = id, kind = "spider" }
        end
        if id == E.Skelicorn then
            return { id = id, kind = "skelicorn" }
        end
        local candyPets = type(farm.Event) == "table" and type(farm.Event.CandyPets) == "table" and farm.Event.CandyPets or {}
        for _, entry in ipairs(type(candyPets.Buy) == "table" and candyPets.Buy or {}) do
            local price = tonumber(entry.price)
            if (entry.id or entry[1]) == id and price and price > 0 then
                return { id = id, kind = "candy", price = price, keepCandy = tonumber(candyPets.KeepCandy) or 0 }
            end
        end
        return { id = id, kind = "pet" }
    end
    -- the focus pet kind (nil for none or an egg focus: the hatched pets are all kinds)
    function GameConstants.focusKind(farm)
        local focus = GameConstants.focusOf(farm)
        return focus and focus.kind ~= "egg" and focus.id or nil
    end
    function GameConstants.kindRank(farm)
        local list = type(farm) == "table" and farm.FarmPetKinds
        local focusInfo = GameConstants.focusOf(farm)
        local focus = focusInfo and focusInfo.id -- an egg focus ranks the egg first: it is hatched before the rest grows
        if (type(list) ~= "table" or #list == 0) and not focus then
            return nil
        end
        local rank = {}
        if focus then
            rank[focus] = 0
        end
        for index, kind in ipairs(type(list) == "table" and list or {}) do
            rank[kind] = rank[kind] or index
        end
        return rank
    end
    function GameConstants.isNeonPet(properties)
        return type(properties) == "table" and (properties.neon == true or properties.mega_neon == true)
    end
    GameConstants.Eggs = {
        "cracked_egg",
        "pet_egg",
        "fairytale_egg_2026_fairytale_egg",
    }
    GameConstants.NeverBuyEggs = { royal_egg = true }
    GameConstants.EggCategory = "pets"
    GameConstants.NotFarmablePets = { practice_dog = true }
    function GameConstants.isEgg(kind)
        if type(kind) ~= "string" then
            return false
        end
        for _, id in ipairs(GameConstants.Eggs) do
            if kind == id then
                return true
            end
        end
        return kind == "royal_egg" or string.match(kind, "_egg$") ~= nil and not string.find(kind, "^basic_egg_")
    end
    function GameConstants.isOnMainMapArea(p)
        return p.X > -1500 and p.X < 1000 and p.Z > -3000 and p.Z < 0
    end
    GameConstants.HouseFurnitureFolderPath = { "HouseInteriors", "furniture" }
    GameConstants.FurnitureUniqueAttribute = "furniture_unique"
    GameConstants.FurnitureForAilment = {
        sleepy = { "basicbed" },
        dirty = { "stylishshower", "modernshower", "cheap_pet_bathtub_tutorial" },
        toilet = { "toilet" },
    }
    GameConstants.PetFoodBowls = { "ailments_refresh_2024_cheap_food_bowl" }
    GameConstants.PetOnlyFurniture = { cheap_pet_bathtub_tutorial = true }
    GameConstants.UseBlockForFurniture = {
        modernshower = "UseBlock",
        cheap_pet_bathtub_tutorial = "UseBlock",
        ailments_refresh_2024_cheap_food_bowl = "UseBlock",
        basicbed = "Seat1",
        stylishshower = "UseBlock",
        toilet = "Seat1",
    }
    GameConstants.ItemCategory = "food"
    GameConstants.ItemsForAilment = {
        hungry = { "sandwich-default", "cheese", "hotdog" },
        thirsty = { "water", "chocolate_milk" },
    }
    GameConstants.BuyForAilment = {
        thirsty = { category = "food", ids = { "water" }, options = {}, setting = "BuyWater" },
        hungry = { category = "food", ids = { "hotdog" }, options = { buy_count = 1 }, setting = "BuyFood" },
    }
    GameConstants.PetObjectsFolderName = "PetObjects"
    GameConstants.FoodObjectCreator = "__Enum_PetObjectCreatorType_2"
    GameConstants.ToyObjectCreator = "__Enum_PetObjectCreatorType_1"
    GameConstants.ThrowToyReaction = "ThrowToyReaction"
    GameConstants.ToyCategory = "toys"
    GameConstants.ToysForPlay = { "squeaky_bone_default" }
    GameConstants.AgePotions = { "pet_age_potion", "tiny_pet_age_potion" }
    GameConstants.GiftCategory = "gifts"
    GameConstants.GiftPatterns = { gift = "gift$", chest = "_chest$" }
    GameConstants.Event = {
        RustyKey = "halloween_2026_rusty_key",
        Twig = "halloween_2026_twig",
        Vacuum = "halloween_2026_ghost_vacuum",
        NestTwigs = 8,
        CatFood = { "water", "chocolate_milk" },
        Ladder = "ladder",
        -- skelicorn.log 2026-10-11: the graves are candy_corn_pile_small (1000), _big (2000), _ginormous (3000)
        GraveValue = { candy_corn_pile_ginormous = 4, candy_corn_pile_big = 3, candy_corn_pile_small = 2, twig = 1 },
        OpenedIdPerFloor = 16,
        PetPenSlots = 4,
        MinigameId = "ghost_clusters",
        JoinZoneTeleportPath = { "StaticMap", "TeleportLocations", "ghost_clusters" },
        JoinZoneModelPath = { "Interiors", "HauntedManor", "GhostClustersMinigameJoinZone" },
        JoinZoneRadius = 15,
        MinigameInteriorPrefix = "ManorMinigameInterior",
        HauntletId = "hauntlet",
        HauntletInteriorPrefix = "HauntletInterior",
        HauntletLobby = "HauntedHotel",
        HauntletClientPath = { "SharedModules", "ContentPacks", "Halloween2026", "Minigames", "HauntletMinigameClient" },
        HauntletItems = { cell_phone = true, key = true, gold_key = true, red_potion = true, ghost_potion = true,
            gold_potion = true, rainbow_wand = true },
        -- v2.1.1: Hauntlet 2 solver. revealWaitSeconds: ghost unknown and no phone / wand of my own -> wait this long
        -- for another player's phone (doors open when everyone picked; a run drops a player who never picks).
        -- kindPenalty: door kind -> extra score (empty: no recorded run showed a kind to be safer).
        -- v2.1.3 (user: "a room has ~20 s: 10 s to plan, 5 s to choose"): planSeconds = the doors wait this long for a
        -- phone's answer, commitBySeconds = by then I stand in a circle whatever happens; slotStart / slotGap = the
        -- squad's turns for the shared items (Hauntlet:turnAt).
        HauntletStrategy = { revealWaitSeconds = 5, planSeconds = 5, commitBySeconds = 10, slotStart = 1, slotGap = 0.6,
            preferLockedWhenSafe = true, kindPenalty = {} },
        HauntletDebug = false, -- true: additional in-memory diagnostics; no disk files
        HauntletDBPath = { "SharedModules", "ContentPacks", "Halloween2026", "Game", "Hauntlet" },
        RoundSeconds = 600,
        GhostsFolder = "GhostClustersVisuals",
        GhostNamePattern = "^Ghost_%a+_([%x%-]+)$",
        BossSize = "Large",
        HoldBelowStuds = 50,
        PropStandOff = 10,
        QuestTabs = { "halloween_2026", "vanilla" },
        QuestsPerBoardReward = 3,
        CryptRewards = { "ladder", "twig", "candy_corn_pile_ginormous", "candy_corn_pile_small" },
        -- v2.1.4 Auto Skelicorn
        LightningLever = "halloween_2026_lightning_lever",
        Skelicorn = "halloween_2026_skelicorn",
        MummySpiderKind = "halloween_2026_tomb_spider",
        SkelicornPrice = 120000, -- the game's InventoryDB price wins when it can be read
        LeverMachinePatterns = { "lightning", "lever" }, -- a model by the Manor whose name has both words
        -- user 2026-10-11 (Dex): MainMap!Halloween > Event > Halloween > ScienceShack > LightningLeverInteract ("Use")
        LeverInteractPath = { "Event", "Halloween", "ScienceShack", "LightningLeverInteract" },
        -- The arguments of LightningLeverDeliver / LightningLeverActivate, copied from ONE recorded manual install (a
        -- remote spy line). nil = not recorded yet: the task goes as far as the machine and stops there (nothing is
        -- guessed). Fill as { deliver = { ...args }, activate = { ...args } } ({} = verified "no arguments").
        -- Recorded 2026-10-10 (SimpleSpy, the developer's own manual install): ToolAPI/Equip(<lever unique>, {}) then
        -- adoptme_new_net "Halloween2026/LightningLeverDeliver":InvokeServer() with NO arguments; the Skelicorn was
        -- unlocked right after (DownloadsAPI/Download("Pets", "halloween_2026_skelicorn")). LightningLeverActivate was
        -- NOT fired in that install, so it is not recorded and never sent.
        SkelicornArgs = { deliver = {} },
    }
    GameConstants.FarmPotions = { "pet_age_potion", "tiny_pet_age_potion", "pet_bonus_aging_potion", "pet_bonus_bucks_potion",
        "pet_random_ailment_potion" }
    function GameConstants.needOn(farm, kind)
        if type(farm) ~= "table" then
            return false
        end
        local tasks = type(farm.Tasks) == "table" and farm.Tasks or {}
        local auto = farm.AutoNeeds
        if type(auto) ~= "table" then
            return tasks[kind] == true
        end
        if auto.Enabled ~= true or tasks[kind] == false then
            return false
        end
        for _, skipped in ipairs(type(auto.Skip) == "table" and auto.Skip or {}) do
            if skipped == kind then
                return false
            end
        end
        return true
    end
    return GameConstants
end
__moduleSources["Game/GameData"] = function(...)
    local import = ...
    local Util = import("Core/Util")
    local Signal = import("Core/Signal")
    local GameConstants = import("Game/GameConstants")
    local Players = game:GetService("Players")
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local GameData = {}
    GameData.__index = GameData
    local MAX_COPY_DEPTH = 12
    local function deepCopy(value, depth, seen)
        if type(value) ~= "table" then
            return value
        end
        depth = depth or 0
        seen = seen or {}
        if seen[value] then
            return seen[value]
        end
        if depth > MAX_COPY_DEPTH then
            return nil
        end
        local copy = {}
        seen[value] = copy
        for key, item in pairs(value) do
            local copiedKey = deepCopy(key, depth + 1, seen)
            if copiedKey ~= nil then copy[copiedKey] = deepCopy(item, depth + 1, seen) end
        end
        return copy
    end
    GameData.deepCopy = deepCopy
    function GameData.new(logger)
        local self = setmetatable({}, GameData)
        self._logger = logger
        self._data = {}
        self._tracked = {}
        self._revision, self._known, self._pendingPartials = {}, {}, {}
        self._destroyed = false
        for _, key in pairs(GameConstants.DataKeys) do
            self._tracked[key] = true
        end
        self.KeyChanged = Signal.new("GameData.KeyChanged")
        self.SnapshotSource = nil
        return self
    end
    function GameData:get(key)
        return self._data[key]
    end
    function GameData:isTracked(key)
        return self._tracked[key] == true
    end
    function GameData:_setKey(key, value)
        if not self._tracked[key] then
            return
        end
        self._data[key] = deepCopy(value)
        self._known[key] = true
        self._revision[key] = (self._revision[key] or 0) + 1
        self._receivedAt = self._receivedAt or {}
        self._receivedAt[key] = Util.now()
        self.KeyChanged:Fire(key, self._data[key])
    end
    function GameData:_applyPartial(change)
        if type(change) ~= "table" or type(change.replicated_key_path) ~= "table" then
            return
        end
        local path = change.replicated_key_path
        local rootKey = path[1]
        if not self._tracked[rootKey] then
            return
        end
        if #path == 1 then
            self:_setKey(rootKey, change.serialized_partial_value)
            return
        end
        if not self._known[rootKey] then
            self._pendingPartials[rootKey] = self._pendingPartials[rootKey] or {}
            local pending = self._pendingPartials[rootKey]
            if #pending < 256 then table.insert(pending, deepCopy(change)) end
            self._revision[rootKey] = (self._revision[rootKey] or 0) + 1
            return -- A delta cannot establish a complete inventory or needs snapshot.
        end
        if type(self._data[rootKey]) ~= "table" then return end
        local node = self._data[rootKey]
        for index = 2, #path - 1 do
            local part = path[index]
            if type(node[part]) ~= "table" then
                node[part] = {}
            end
            node = node[part]
        end
        node[path[#path]] = deepCopy(change.serialized_partial_value)
        self._revision[rootKey] = (self._revision[rootKey] or 0) + 1
        self._receivedAt = self._receivedAt or {}
        self._receivedAt[rootKey] = Util.now()
        self.KeyChanged:Fire(rootKey, self._data[rootKey])
    end
    local function findByPath(root, names)
        local node = root
        for _, name in ipairs(names) do
            node = node and node:FindFirstChild(name)
        end
        return node
    end
    local function describeKeys(tableValue, limit)
        local keys = {}
        for key in pairs(tableValue) do
            table.insert(keys, tostring(key))
            if #keys >= limit then
                break
            end
        end
        return table.concat(keys, ", ")
    end
    function GameData:_loadSnapshot()
        local moduleScript = findByPath(ReplicatedStorage, GameConstants.ClientDataModulePath)
        if not moduleScript then
            return nil, "ClientData module not found"
        end
        local requireOk, clientData = pcall(require, moduleScript)
        if not requireOk or type(clientData) ~= "table" then
            return nil, "require(ClientData) failed: " .. tostring(clientData)
        end
        if type(clientData.get_data) ~= "function" then
            return nil, "ClientData.get_data is not a function"
        end
        local callOk, allData = pcall(clientData.get_data)
        if not callOk then
            return nil, "ClientData.get_data() failed: " .. tostring(allData)
        end
        if type(allData) ~= "table" then
            return nil, "ClientData.get_data() returned " .. typeof(allData)
        end
        local myName = Players.LocalPlayer and Players.LocalPlayer.Name
        local mine = myName and allData[myName]
        if type(mine) == "table" then
            return mine, "ClientData.get_data()[playerName]"
        end
        if allData[GameConstants.DataKeys.Ailments] ~= nil or allData[GameConstants.DataKeys.Money] ~= nil then
            return allData, "ClientData.get_data()"
        end
        return nil, "ClientData.get_data() returned an unknown shape (keys: " .. describeKeys(allData, 8) .. ")"
    end
    function GameData:start(maid)
        local myName = Players.LocalPlayer and Players.LocalPlayer.Name
        local apiFolder = ReplicatedStorage:FindFirstChild(GameConstants.Remotes.Folder)
        if not apiFolder then
            self._logger:error("GameData", "ReplicatedStorage." .. GameConstants.Remotes.Folder .. " not found; game data unavailable")
            return false
        end
        local dataChanged = apiFolder:FindFirstChild(GameConstants.Remotes.DataChanged)
        if not (dataChanged and dataChanged:IsA("RemoteEvent")) then
            self._logger:error("GameData", GameConstants.Remotes.DataChanged .. " not found; game data unavailable")
            return false
        end
        maid:Give(dataChanged.OnClientEvent:Connect(function(playerName, key, value)
            if playerName ~= myName then
                return
            end
            self:_setKey(key, value)
        end))
        local partialChanged = apiFolder:FindFirstChild(GameConstants.Remotes.DataPartiallyChanged)
        if partialChanged and partialChanged:IsA("RemoteEvent") then
            maid:Give(partialChanged.OnClientEvent:Connect(function(playerName, changes)
                if playerName ~= myName or type(changes) ~= "table" then
                    return
                end
                for _, change in ipairs(changes) do
                    self:_applyPartial(change)
                end
            end))
        else
            self._logger:warn("GameData", GameConstants.Remotes.DataPartiallyChanged .. " not found; nested updates will be missed")
        end
        self:refreshNeeds(true)
        return true
    end
    function GameData:revision(key)
        return self._revision[key] or 0
    end
    function GameData:inventoryKnown(category)
        local inventory = self:get(GameConstants.DataKeys.Inventory)
        return self._known[GameConstants.DataKeys.Inventory] == true and type(inventory) == "table"
            and type(inventory[category]) == "table"
    end
    function GameData:item(category, unique)
        if unique == nil then return nil end
        local inventory = self:get(GameConstants.DataKeys.Inventory)
        local items = type(inventory) == "table" and inventory[category]
        if type(items) ~= "table" then return nil end
        unique = tostring(unique)
        local direct = items[unique]
        if type(direct) == "table" then return direct end
        for key, item in pairs(items) do
            if type(item) == "table" and tostring(item.unique or key) == unique then return item end
        end
        return nil
    end
    function GameData:hasPet(unique)
        return self:item("pets", unique) ~= nil
    end
    function GameData:isPetProtected(unique)
        return self.selection ~= nil and self.selection:isProtected(unique)
    end
    function GameData:getPetKind(petUnique)
        local equip = self._data[GameConstants.DataKeys.Equip]
        if type(equip) == "table" and type(equip.pets) == "table" then
            for _, pet in pairs(equip.pets) do
                if type(pet) == "table" and tostring(pet.unique) == tostring(petUnique) then
                    if pet.kind or pet.id then return pet.kind or pet.id end
                end
            end
        end
        local wrappers = self._data[GameConstants.DataKeys.PetWrappers]
        if type(wrappers) == "table" then
            for _, wrapper in pairs(wrappers) do
                if type(wrapper) == "table" and tostring(wrapper.pet_unique) == tostring(petUnique) then
                    if wrapper.pet_id then return wrapper.pet_id end
                end
            end
        end
        local inventory = self._data[GameConstants.DataKeys.Inventory]
        local pet = self:item("pets", petUnique)
        if type(pet) == "table" then
            return pet.kind or pet.id
        end
        return nil
    end
    function GameData:isPetEquipped(petUnique)
        local count, known = self:equippedPetCount()
        if not known then return false end
        for _, pet in ipairs(self:equippedPetList()) do
            if pet.unique == tostring(petUnique) then return true end
        end
        return false
    end
    function GameData:refreshNeeds(force)
        local now = Util.now()
        if self._refreshing and now - (self._refreshStarted or now) > 8 then
            if self._refreshThread then pcall(task.cancel, self._refreshThread) end
            self._refreshing = false
        end
        if self._destroyed or self._refreshing or (not force and now < (self._nextNeedsRefresh or 0)) then return false end
        self._nextNeedsRefresh = now + 3
        self._refreshing, self._refreshStarted = true, now
        local versions = table.clone(self._revision)
        self._refreshThread = task.spawn(function()
            local ok, snapshot, how = pcall(self._loadSnapshot, self)
            if not self._destroyed and ok and type(snapshot) == "table" then
                self.SnapshotSource = how
                for key in pairs(self._tracked) do
                    -- Events received while require/get_data yielded win over this snapshot.
                    if snapshot[key] ~= nil and self:revision(key) == (versions[key] or 0) then
                        local pending = self._pendingPartials[key]
                        self._pendingPartials[key] = nil
                        self:_setKey(key, snapshot[key])
                        -- Older deltas must not be replayed over an authoritative newer snapshot.
                        if pending then table.clear(pending) end
                    end
                end
            end
            self._refreshing = false
        end)
        return true
    end
    function GameData:findItems(category, ids)
        local inventory = self._data[GameConstants.DataKeys.Inventory]
        local items = type(inventory) == "table" and inventory[category]
        local result = {}
        if type(items) ~= "table" then
            return result
        end
        local rank = {}
        for index, id in ipairs(ids or {}) do
            rank[id] = index
        end
        for unique, item in pairs(items) do
            if type(item) == "table" and item.id ~= nil and (ids == nil or rank[item.id]) then
                local properties = type(item.properties) == "table" and item.properties or {}
                local uses = tonumber(properties.uses_left)
                if uses == nil or uses > 0 then
                    table.insert(result, { unique = tostring(item.unique or unique), id = item.id, usesLeft = uses })
                end
            end
        end
        table.sort(result, function(a, b)
            if rank[a.id] ~= rank[b.id] then
                return (rank[a.id] or math.huge) < (rank[b.id] or math.huge)
            end
            return a.unique < b.unique
        end)
        return result
    end
    function GameData:itemUsesLeft(category, unique)
        local inventory = self._data[GameConstants.DataKeys.Inventory]
        local item = self:item(category, unique)
        if type(item) ~= "table" then
            return nil
        end
        local properties = type(item.properties) == "table" and item.properties or {}
        return tonumber(properties.uses_left) or 1
    end
    function GameData:equippedPetCount()
        local equip = self._data[GameConstants.DataKeys.Equip]
        local known = type(equip) == "table" and type(equip.pets) == "table"
        return #self:equippedPetList(), known
    end
    function GameData:firstEquippedPet()
        local list = self:equippedPetList()
        for _, pet in ipairs(list) do if pet.unique == self._primaryPet then return pet.unique end end
        self._primaryPet = list[1] and list[1].unique or nil
        return self._primaryPet
    end
    function GameData:equippedPetList()
        local equip = self._data[GameConstants.DataKeys.Equip]
        local result, seen = {}, {}
        for _, pet in pairs(type(equip) == "table" and type(equip.pets) == "table" and equip.pets or {}) do
            local unique = type(pet) == "table" and pet.unique or ((type(pet) == "string" or type(pet) == "number") and pet or nil)
            if unique ~= nil then
                unique = tostring(unique)
                if unique ~= "" and not seen[unique] then
                    seen[unique] = true
                    local properties = type(pet) == "table" and type(pet.properties) == "table" and pet.properties or {}
                    table.insert(result, { unique = unique, age = self:petAge(unique) or tonumber(properties.age) })
                end
            end
        end
        table.sort(result, function(a, b) return a.unique < b.unique end)
        return result
    end
    function GameData:petAge(unique)
        local inventory = self._data[GameConstants.DataKeys.Inventory]
        local pets = type(inventory) == "table" and inventory.pets
        local pet = self:item("pets", unique)
        local properties = type(pet) == "table" and type(pet.properties) == "table" and pet.properties
        return properties and tonumber(properties.age) or nil
    end
    -- v2.1.5 (user screenshot: "1.2x Aging Active (57 mins)" on a FULL GROWN Skelicorn: every Bonus Aging potion went
    -- on one pet, the buff time adds up): the pet's own data, any key with `word` (aging / bucks) holding a time
    -- that is still ahead = the buff runs until then
    function GameData:petBuffUntil(unique, word)
        local inventory = self._data[GameConstants.DataKeys.Inventory]
        local pets = type(inventory) == "table" and inventory.pets
        local pet = self:item("pets", unique)
        local now = os.time()
        local best
        local function walk(t, path, depth)
            if type(t) ~= "table" or depth > 5 then
                return
            end
            for k, v in pairs(t) do
                local here = string.lower(path .. "." .. tostring(k))
                if type(v) == "number" and string.find(here, word, 1, true) and v > now and v < now + 30 * 86400 then
                    best = math.max(best or 0, v)
                elseif type(v) == "table" then
                    walk(v, here, depth + 1)
                end
            end
        end
        walk(pet, "", 0)
        return best
    end
    function GameData:petPenPets()
        local pen = self._data[GameConstants.DataKeys.PetPen]
        local result = {}
        for unique, record in pairs(type(pen) == "table" and type(pen.active_pets) == "table" and pen.active_pets or {}) do
            result[tostring(unique)] = type(record) == "table" and record or {}
        end
        return result
    end
    function GameData:isPetNeon(unique)
        local inventory = self._data[GameConstants.DataKeys.Inventory]
        local pets = type(inventory) == "table" and inventory.pets
        local pet = self:item("pets", unique)
        return type(pet) == "table" and GameConstants.isNeonPet(pet.properties)
    end
    -- copies of one kind that still grow: in the backpack and in the Pet Pen (Mega a Pet keeps slots + 1 of them)
    function GameData:growingCopies(kind)
        local inventory = self._data[GameConstants.DataKeys.Inventory]
        local pets = type(inventory) == "table" and type(inventory.pets) == "table" and inventory.pets or {}
        local copies = 0
        for key, pet in pairs(pets) do
            if type(pet) == "table" and tostring(pet.kind or pet.id) == kind then
                local properties = type(pet.properties) == "table" and pet.properties or {}
                local age = tonumber(properties.age)
                if age == nil or age < GameConstants.FullGrownAge then
                    copies += 1
                end
            end
        end
        return copies
    end
    function GameData:growablePets(preferNeon, kindRank, youngestFirst)
        local inventory = self._data[GameConstants.DataKeys.Inventory]
        local pets = type(inventory) == "table" and inventory.pets
        local inPen = self:petPenPets()
        local result = {}
        for key, pet in pairs(type(pets) == "table" and pets or {}) do
            if type(pet) == "table" and not inPen[tostring(pet.unique or key)] then
                local properties = type(pet.properties) == "table" and pet.properties or {}
                local age = tonumber(properties.age)
                local kind = tostring(pet.kind or pet.id or "?")
                if age == nil and GameConstants.isEgg(kind) then
                    age = 0
                end
                if age and age < GameConstants.FullGrownAge and not GameConstants.NotFarmablePets[kind] then
                    table.insert(result, { unique = tostring(pet.unique or key), age = age, kind = kind,
                        neon = GameConstants.isNeonPet(properties) })
                end
            end
        end
        table.sort(result, function(a, b)
            local ra = kindRank and kindRank[a.kind] or math.huge
            local rb = kindRank and kindRank[b.kind] or math.huge
            if ra ~= rb then
                return ra < rb
            end
            if preferNeon and a.neon ~= b.neon then
                return a.neon
            end
            if a.age ~= b.age then
                if youngestFirst then
                    return a.age < b.age
                end
                return a.age > b.age
            end
            return a.unique < b.unique
        end)
        return result
    end
    function GameData:neonFusionGroups(exclude, mega)
        local inventory = self._data[GameConstants.DataKeys.Inventory]
        local pets = type(inventory) == "table" and inventory.pets
        local inPen = self:petPenPets()
        local groups = {}
        for key, pet in pairs(type(pets) == "table" and pets or {}) do
            if type(pet) == "table" and type(pet.properties) == "table" then
                local unique = tostring(pet.unique or key)
                local kind = tostring(pet.kind or pet.id or "?")
                local age = tonumber(pet.properties.age)
                local fits
                if mega then
                    fits = pet.properties.neon == true and pet.properties.mega_neon ~= true
                else
                    fits = not GameConstants.isNeonPet(pet.properties)
                end
                if age == GameConstants.FullGrownAge and fits and not inPen[unique]
                    and not self:isPetProtected(unique) and not self:isPetEquipped(unique)
                    and not (exclude and exclude[kind]) and not GameConstants.NotFarmablePets[kind] then
                    groups[kind] = groups[kind] or {}
                    table.insert(groups[kind], unique)
                end
            end
        end
        for _, list in pairs(groups) do
            table.sort(list)
        end
        return groups
    end
    function GameData:neonCountOfKind(kind)
        local inventory = self._data[GameConstants.DataKeys.Inventory]
        local pets = type(inventory) == "table" and inventory.pets
        local n = 0
        for _, pet in pairs(type(pets) == "table" and pets or {}) do
            if type(pet) == "table" and tostring(pet.kind or pet.id) == kind and type(pet.properties) == "table"
                and pet.properties.neon == true then
                n += 1
            end
        end
        return n
    end
    function GameData:megaCountOfKind(kind)
        local inventory = self._data[GameConstants.DataKeys.Inventory]
        local pets = type(inventory) == "table" and inventory.pets
        local n = 0
        for _, pet in pairs(type(pets) == "table" and pets or {}) do
            if type(pet) == "table" and tostring(pet.kind or pet.id) == kind and type(pet.properties) == "table"
                and pet.properties.mega_neon == true then
                n += 1
            end
        end
        return n
    end
    function GameData:isPetMega(unique)
        local inventory = self._data[GameConstants.DataKeys.Inventory]
        local pets = type(inventory) == "table" and inventory.pets
        local pet = self:item("pets", unique)
        return type(pet) == "table" and type(pet.properties) == "table" and pet.properties.mega_neon == true
    end
    function GameData:petInventoryKnown()
        local inventory = self._data[GameConstants.DataKeys.Inventory]
        return self:inventoryKnown("pets")
    end
    function GameData:petUniquesOfKind(kind)
        local inventory = self._data[GameConstants.DataKeys.Inventory]
        local pets = type(inventory) == "table" and inventory.pets
        local result = {}
        for key, pet in pairs(type(pets) == "table" and pets or {}) do
            if type(pet) == "table" and tostring(pet.kind or pet.id) == kind then
                result[tostring(pet.unique or key)] = true
            end
        end
        return result
    end
    function GameData:itemsOfId(category, id)
        local list = {}
        for _, item in ipairs(self:findItems(category, { id })) do
            table.insert(list, item.unique)
        end
        return list
    end
    function GameData:isSitting()
        local manager = self._data[GameConstants.DataKeys.StateManager]
        return type(manager) == "table" and manager.is_sitting == true
    end
    function GameData:destroy()
        self._destroyed = true
        if self._refreshThread then pcall(task.cancel, self._refreshThread) end
        self.KeyChanged:DisconnectAll()
    end
    return GameData
end
__moduleSources["Game/GameIcons"] = function(...)
    local GameIcons = {}
    GameIcons.__index = GameIcons
    GameIcons.KNOWN = {
        bucks = { path = { "Resources", "BucksBillboard", "BillboardGui", "Frame", "ImageLabel" }, id = 3577407233 },
        candy = { path = { "Resources", "CRYPT_PIECES", "Crypt_2026_Floor03", "Game", "RewardSign", "SurfaceGui", "Frame",
            "RewardTemplate", "Icon" }, id = 14845052425 },
        home = { path = { "Resources", "HomeBillboard", "ImageLabel" }, id = 2000934070 },
    }
    local CURRENCY_TRIES = 10
    local SEARCH_GAP = 20
    function GameIcons.new(logger, clock)
        local self = setmetatable({}, GameIcons)
        self._logger = logger
        self._clock = clock or os.clock
        self._items = {}
        self._currency = {}
        self._tries = {}
        self._lastTry = {}
        return self
    end
    function GameIcons.image(value)
        if type(value) == "number" then
            return "rbxassetid://" .. math.floor(value)
        end
        if type(value) == "string" and (string.find(value, "^rbxassetid://%d+") or string.find(value, "^rbxasset://")
            or string.find(value, "^https?://")) then
            return value
        end
        return nil
    end
    function GameIcons.assetId(image)
        if type(image) ~= "string" then
            return nil
        end
        return tonumber(string.match(image, "^rbxassetid://(%d+)") or string.match(image, "[?&]id=(%d+)"))
    end
    function GameIcons:_db()
        if self._dbState ~= nil then
            return self._dbState or nil
        end
        local ok, db = pcall(function()
            local ReplicatedStorage = game:GetService("ReplicatedStorage")
            local fsys = ReplicatedStorage:FindFirstChild("Fsys")
            if fsys then
                local loader = require(fsys)
                if type(loader) == "table" and type(loader.load) == "function" then
                    local inventory = loader.load("InventoryDB")
                    if type(inventory) == "table" then
                        return inventory
                    end
                end
            end
            local clientDB = ReplicatedStorage:FindFirstChild("ClientDB")
            local module = clientDB and clientDB:FindFirstChild("InventoryDB", true)
            if module and module:IsA("ModuleScript") then
                local inventory = require(module)
                if type(inventory) == "table" then
                    return inventory
                end
            end
            return nil
        end)
        self._dbState = ok and type(db) == "table" and db or false
        if not self._dbState and self._logger then
            self._logger:debug("Icons", "The game's item list was not found: the window keeps its own icons")
        end
        return self._dbState or nil
    end
    function GameIcons:known(key)
        local entry = GameIcons.KNOWN[key]
        if not entry then
            return nil
        end
        if self._known and self._known[key] then
            return self._known[key]
        end
        local picture
        pcall(function()
            local node = game:GetService("ReplicatedStorage")
            for _, name in ipairs(entry.path) do
                node = node and node:FindFirstChild(name)
            end
            if node and (node:IsA("ImageLabel") or node:IsA("ImageButton")) then
                picture = GameIcons.image(node.Image)
            end
        end)
        picture = picture or GameIcons.image(entry.id)
        self._known = self._known or {}
        self._known[key] = picture
        return picture
    end
    function GameIcons:picture(name)
        if type(name) ~= "string" then
            return nil
        end
        local kind, key = string.match(name, "^(%a+):(.+)$")
        if kind == "game" then
            return self:known(key)
        elseif kind == "item" then
            return self:item(key)
        end
        return nil
    end
    function GameIcons:item(id)
        if type(id) ~= "string" then
            return nil
        end
        if self._items[id] ~= nil then
            return self._items[id] or nil
        end
        local found = false
        local db = self:_db()
        if db then
            pcall(function()
                for _, category in pairs(db) do
                    local entry = type(category) == "table" and rawget(category, id)
                    if type(entry) == "table" and GameIcons.image(entry.image) then
                        found = GameIcons.image(entry.image)
                        return
                    end
                end
            end)
        end
        self._items[id] = found
        return found or nil
    end
    function GameIcons.nearestPicture(label)
        local best, bestDistance
        local center = label.AbsolutePosition + label.AbsoluteSize / 2
        for _, scope in ipairs({ label.Parent, label.Parent and label.Parent.Parent }) do
            if scope and not best then
                for _, item in ipairs(scope:GetDescendants()) do
                    if (item:IsA("ImageLabel") or item:IsA("ImageButton")) and item.Visible and item.Image ~= "" then
                        local size = item.AbsoluteSize
                        local ratio = size.Y > 0 and size.X / size.Y or 0
                        if ratio > 0.6 and ratio < 1.6 and size.Y <= label.AbsoluteSize.Y * 3 then
                            local distance = ((item.AbsolutePosition + size / 2) - center).Magnitude
                            if not best or distance < bestDistance then
                                best, bestDistance = item.Image, distance
                            end
                        end
                    end
                end
            end
        end
        return best
    end
    local function digits(text)
        return (string.gsub(tostring(text or ""), "%D", ""))
    end
    function GameIcons:currency(key, amount)
        if self._currency[key] then
            return self._currency[key]
        end
        amount = tonumber(amount)
        if not amount or amount < 10 then
            return nil
        end
        local now = self._clock()
        local tries = self._tries[key] or 0
        if tries >= CURRENCY_TRIES or (self._lastTry[key] and now - self._lastTry[key] < SEARCH_GAP) then
            return nil
        end
        self._tries[key], self._lastTry[key] = tries + 1, now
        local want = tostring(math.floor(amount))
        local ok, picture = pcall(function()
            local playerGui = game:GetService("Players").LocalPlayer:FindFirstChild("PlayerGui")
            for _, screen in ipairs(playerGui and playerGui:GetChildren() or {}) do
                if screen:IsA("ScreenGui") and screen.Enabled then
                    for _, label in ipairs(screen:GetDescendants()) do
                        if label:IsA("TextLabel") and label.Visible and digits(label.Text) == want then
                            local found = GameIcons.nearestPicture(label)
                            if found then
                                return found
                            end
                        end
                    end
                end
            end
            return nil
        end)
        if ok and picture then
            self._currency[key] = picture
            return picture
        end
        return nil
    end
    return GameIcons
end
__moduleSources["Game/PetLocator"] = function(...)
    local import = ...
    local GameConstants = import("Game/GameConstants")
    local PetLocator = {}
    PetLocator.__index = PetLocator
    function PetLocator.new(gameData)
        return setmetatable({ _gameData = gameData }, PetLocator)
    end
    function PetLocator:getStreamingId(petUnique)
        local wrappers = self._gameData:get(GameConstants.DataKeys.PetWrappers)
        if type(wrappers) ~= "table" then
            return nil
        end
        for _, wrapper in pairs(wrappers) do
            if type(wrapper) == "table" and tostring(wrapper.pet_unique) == tostring(petUnique) and (type(wrapper.char) == "string" or type(wrapper.char) == "number") then
                return tostring(wrapper.char)
            end
        end
        return nil
    end
    function PetLocator:findModel(petUnique)
        if not self._gameData:isPetEquipped(petUnique) then return nil, "pet is not equipped" end
        local wrappers = self._gameData:get(GameConstants.DataKeys.PetWrappers)
        for _, wrapper in pairs(type(wrappers) == "table" and wrappers or {}) do
            if type(wrapper) == "table" and tostring(wrapper.pet_unique) == tostring(petUnique)
                and typeof(wrapper.char) == "Instance" and wrapper.char:IsA("Model") and wrapper.char.Parent then
                return wrapper.char
            end
        end
        local streamingId = self:getStreamingId(petUnique)
        if not streamingId then
            return nil, "no pet wrapper for this pet yet"
        end
        local folder = workspace:FindFirstChild(GameConstants.PetsFolderName)
        if not folder then
            return nil, "workspace." .. GameConstants.PetsFolderName .. " not found"
        end
        for _, model in ipairs(folder:GetChildren()) do
            local ok, value = pcall(function()
                return model:GetAttribute(GameConstants.PetModelIdAttribute)
            end)
            if ok and model:IsA("Model") and value ~= nil and tostring(value) == tostring(streamingId) then
                return model
            end
        end
        return nil, "model not streamed in yet"
    end
    function PetLocator:getEquippedPets()
        local result = {}
        local equip = self._gameData:get(GameConstants.DataKeys.Equip)
        for _, pet in ipairs(self._gameData:equippedPetList()) do
            local record
            for _, raw in pairs(type(equip) == "table" and type(equip.pets) == "table" and equip.pets or {}) do
                if type(raw) == "table" and tostring(raw.unique) == pet.unique then record = raw; break end
            end
            local properties = record and type(record.properties) == "table" and record.properties or {}
            table.insert(result, { unique = pet.unique, age = pet.age, xp = tonumber(properties.xp),
                kind = tostring(record and (record.kind or record.id) or self._gameData:getPetKind(pet.unique) or "?") })
        end
        return result
    end
    return PetLocator
end
__moduleSources["Game/PlayerSync"] = function(...)
    local import = ...
    local GameConstants = import("Game/GameConstants")
    local PlayerSync = {}
    local KEYS = GameConstants.DataKeys
    local function describeFurniture(interior)
        local counts = {}
        for _, piece in pairs(type(interior.furniture) == "table" and interior.furniture or {}) do
            if type(piece) == "table" and type(piece.id) == "string" then
                counts[piece.id] = (counts[piece.id] or 0) + 1
            end
        end
        local parts = {}
        for id, count in pairs(counts) do
            table.insert(parts, id .. " x" .. count)
        end
        table.sort(parts)
        return #parts > 0 and table.concat(parts, ", ") or "none"
    end
    function PlayerSync.start(maid, state, gameData, petLocator, logger)
        local furnitureLoggedFor = nil
        local function placeFromCharWrapper()
            local wrapper = gameData:get(KEYS.CharWrapper)
            local location = type(wrapper) == "table" and type(wrapper.location) == "table" and wrapper.location
            local id = location and location.destination_id
            return (type(id) == "string" and GameConstants.CharWrapperPlaces[id]) and id or nil
        end
        local function apply(key, value)
            if key == KEYS.CharWrapper then
                local interior = gameData:get(KEYS.Interior)
                local place = placeFromCharWrapper()
                if place and state:get("player.interior") == nil and type(interior) == "table"
                    and type(interior.interior_name) ~= "string" and interior.house_pos == nil then
                    state:set("player.interior", place, "DataChanged:" .. key)
                end
                return
            end
            if key == KEYS.Inventory then
                state:set("pets.equipped", petLocator:getEquippedPets(), "DataChanged:" .. key)
            elseif key == KEYS.Money and tonumber(value) then
                state:set("player.bucks", tonumber(value), "DataChanged:" .. key)
            elseif key == KEYS.Team and type(value) == "string" then
                state:set("player.team", value, "DataChanged:" .. key)
            elseif key == KEYS.Interior and type(value) == "table" then
                local name = type(value.interior_name) == "string" and value.interior_name
                    or ((value.house_pos ~= nil or next(type(value.furniture) == "table" and value.furniture or {}) ~= nil)
                        and GameConstants.HouseInteriorName or nil)
                name = name or placeFromCharWrapper()
                state:set("player.interior", name, "DataChanged:" .. key)
                if name == nil then
                    return
                end
                if logger and furnitureLoggedFor ~= name then
                    furnitureLoggedFor = name
                    logger:debug("Furniture", "In " .. name .. ": " .. describeFurniture(value))
                end
            elseif key == KEYS.Interior then
                state:set("player.interior", nil, "DataChanged:" .. key)
            elseif key == KEYS.Equip then
                state:set("pets.equipped", petLocator:getEquippedPets(), "DataChanged:" .. key)
            end
        end
        maid:Give(gameData.KeyChanged:Connect(apply))
        for _, key in ipairs({ KEYS.Money, KEYS.Team, KEYS.Interior, KEYS.Equip }) do
            local value = gameData:get(key)
            if value ~= nil then
                apply(key, value)
            end
        end
    end
    return PlayerSync
end
__moduleSources["Game/AilmentTracker"] = function(...)
    local import = ...
    local Enums = import("Core/Enums")
    local Signal = import("Core/Signal")
    local GameConstants = import("Game/GameConstants")
    local Players = game:GetService("Players")
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local AilmentTracker = {}
    AilmentTracker.__index = AilmentTracker
    local SOURCE_DATA = "DataChanged:" .. GameConstants.DataKeys.Ailments
    function AilmentTracker.new(logger, state, notifier, gameData)
        local self = setmetatable({}, AilmentTracker)
        self._logger = logger
        self._state = state
        self._notifier = notifier
        self._gameData = gameData
        self._previous = {}
        self.Completed = Signal.new("AilmentTracker.Completed")
        return self
    end
    local function entryId(entry)
        return (entry.owner == "baby" and "baby" or entry.petUnique) .. "|" .. entry.kind
    end
    function AilmentTracker:ownerLabel(entry)
        if entry.owner == "baby" then
            return "baby"
        end
        return "pet " .. tostring(entry.petKind or "?")
    end
    local function finiteNumber(value, fallback)
        local number = tonumber(value)
        return number and number == number and math.abs(number) < math.huge and number or fallback
    end
    local function readEntry(rawEntry, kindKey)
        local components = type(rawEntry) == "table" and rawEntry.components
        local preference = type(components) == "table" and components.preference
        local rate = type(rawEntry) == "table" and math.max(0, finiteNumber(rawEntry.rate, 0)) or 0
        local mysteryOptions = nil
        local mystery = type(components) == "table" and components.mystery
        if type(mystery) == "table" and type(mystery.components) == "table" then
            mysteryOptions = {}
            for kind in pairs(mystery.components) do
                table.insert(mysteryOptions, tostring(kind))
            end
            table.sort(mysteryOptions)
        end
        return {
            mysteryOptions = mysteryOptions,
            mysterySeed = type(mystery) == "table" and mystery.random_seed or nil,
            kind = tostring(type(rawEntry) == "table" and rawEntry.kind or kindKey),
            rate = rate,
            inProgress = rate > 0,
            progress = type(rawEntry) == "table" and math.max(0, math.min(1, finiteNumber(rawEntry.progress, 0))) or 0,
            createdAt = type(rawEntry) == "table" and finiteNumber(rawEntry.created_timestamp, nil) or nil,
            preferredItem = type(preference) == "table" and preference.item_kind or nil,
        }
    end
    function AilmentTracker:parse(manager)
        local list = {}
        if type(manager) ~= "table" then
            return list
        end
        if type(manager.ailments) == "table" then
            for petUnique, ailments in pairs(manager.ailments) do
                if type(ailments) == "table" then
                    for kindKey, rawEntry in pairs(ailments) do
                        local entry = readEntry(rawEntry, kindKey)
                        entry.owner = "pet"
                        entry.petUnique = tostring(petUnique)
                        entry.petKind = self._gameData:getPetKind(entry.petUnique)
                        table.insert(list, entry)
                    end
                end
            end
        end
        if type(manager.baby_ailments) == "table" then
            for kindKey, rawEntry in pairs(manager.baby_ailments) do
                local entry = readEntry(rawEntry, kindKey)
                entry.owner = "baby"
                table.insert(list, entry)
            end
        end
        table.sort(list, function(a, b)
            local aTime, bTime = a.createdAt or 0, b.createdAt or 0
            if aTime ~= bTime then return aTime < bTime end
            return entryId(a) < entryId(b)
        end)
        return list
    end
    function AilmentTracker:_onAilmentsChanged(manager)
        if type(manager) ~= "table" or (type(manager.ailments) ~= "table" and type(manager.baby_ailments) ~= "table") then
            self._state:set("ailments.known", false, SOURCE_DATA)
            self._state:set("ailments.petKnown", false, SOURCE_DATA)
            self._state:set("ailments.babyKnown", false, SOURCE_DATA)
            return -- A missing snapshot must not erase pending needs as if they had completed.
        end
        self._state:set("ailments.petKnown", type(manager.ailments) == "table", SOURCE_DATA)
        self._state:set("ailments.babyKnown", type(manager.baby_ailments) == "table", SOURCE_DATA)
        self._state:set("ailments.revision", self._gameData:revision(GameConstants.DataKeys.Ailments), SOURCE_DATA)
        local list = self:parse(manager)
        for _, old in pairs(self._previous) do
            if (old.owner == "pet" and type(manager.ailments) ~= "table")
                or (old.owner == "baby" and type(manager.baby_ailments) ~= "table") then table.insert(list, old) end
        end
        local current = {}
        for _, entry in ipairs(list) do
            local id = entryId(entry)
            current[id] = entry
            local before = self._previous[id]
            local label = self:ownerLabel(entry) .. " " .. entry.kind
            if not before then
                local extra = entry.preferredItem and (" (prefers " .. entry.preferredItem .. ")") or ""
                self._logger:info("Needs", "New need: " .. label .. extra)
            elseif entry.inProgress and not before.inProgress then
                self._logger:info("Needs", string.format("In progress: %s (about %d s)", label, math.floor(1 / entry.rate + 0.5)))
            elseif not entry.inProgress and before.inProgress then
                if self._state:get("farm.currentTask") == entry.kind then
                    self._logger:info("Needs", "Progress stopped: " .. label)
                else
                    self._logger:debug("Needs", "Progress stopped: " .. label)
                end
            end
        end
        for id, before in pairs(self._previous) do
            if not current[id] then
                self._logger:debug("Needs", "Removed from list: " .. self:ownerLabel(before) .. " " .. before.kind)
            end
        end
        self._previous = current
        self._state:set("ailments.active", list, SOURCE_DATA)
        self._state:set("ailments.known", true, SOURCE_DATA)
    end
    function AilmentTracker:_isMyPet(petUnique)
        if self._gameData:getPetKind(petUnique) ~= nil then
            return true
        end
        for _, entry in pairs(self._previous) do
            if entry.petUnique == petUnique then
                return true
            end
        end
        return false
    end
    function AilmentTracker:_onCompleted(owner, petUnique, kind, rewards)
        if type(kind) ~= "string" or kind == "" then return end
        local bucks = math.max(0, finiteNumber(type(rewards) == "table" and rewards.bucks, 0))
        local xp = finiteNumber(type(rewards) == "table" and rewards.xp, nil)
        local label = owner == "baby" and "baby" or ("pet " .. tostring(self._gameData:getPetKind(petUnique) or "?"))
        local source = owner == "baby" and GameConstants.Remotes.BabyAilmentCompleted or GameConstants.Remotes.PetAilmentCompleted
        local completed = self._state:increment("stats.needsCompleted", 1, source)
        local earned = self._state:increment("stats.bucksEarned", bucks, source)
        local taskText = label .. " " .. tostring(kind)
        self._state:set("stats.lastTask", taskText, source)
        self._logger:success("Needs", string.format("Completed: %s (+%d Bucks%s)", taskText, bucks, xp and (", +" .. xp .. " XP") or ""))
        self.Completed:Fire(owner, petUnique, tostring(kind))
        self._notifier:notify(Enums.NotifyEvent.TaskCompleted, {
            { name = "Last task", value = taskText, inline = true },
            { name = "Needs completed", value = tostring(completed), inline = true },
            { name = "Bucks earned", value = tostring(earned), inline = true },
        })
    end
    function AilmentTracker:start(maid)
        maid:Give(function()
            self.Completed:DisconnectAll()
        end)
        maid:Give(self._gameData.KeyChanged:Connect(function(key, value)
            if key == GameConstants.DataKeys.Ailments then
                self:_onAilmentsChanged(value)
            end
        end))
        local existing = self._gameData:get(GameConstants.DataKeys.Ailments)
        if existing ~= nil then
            self:_onAilmentsChanged(existing)
        end
        local apiFolder = ReplicatedStorage:FindFirstChild(GameConstants.Remotes.Folder)
        local petCompleted = apiFolder and apiFolder:FindFirstChild(GameConstants.Remotes.PetAilmentCompleted)
        if petCompleted and petCompleted:IsA("RemoteEvent") then
            maid:Give(petCompleted.OnClientEvent:Connect(function(petUnique, kind, rewards)
                if not self:_isMyPet(tostring(petUnique)) then
                    self._logger:debug("Needs", "Ignored a completion for a pet that is not mine")
                    return
                end
                self:_onCompleted("pet", tostring(petUnique), kind, rewards)
            end))
        else
            self._logger:warn("Needs", GameConstants.Remotes.PetAilmentCompleted .. " not found; pet completions not counted")
        end
        local babyCompleted = apiFolder and apiFolder:FindFirstChild(GameConstants.Remotes.BabyAilmentCompleted)
        if babyCompleted and babyCompleted:IsA("RemoteEvent") then
            maid:Give(babyCompleted.OnClientEvent:Connect(function(player, kind, rewards)
                local me = Players.LocalPlayer
                if player ~= me and player ~= me.Name and player ~= me.UserId then
                    self._logger:debug("Needs", "Ignored a baby completion for another player")
                    return
                end
                self:_onCompleted("baby", nil, kind, rewards)
            end))
        else
            self._logger:warn("Needs", GameConstants.Remotes.BabyAilmentCompleted .. " not found; baby completions not counted")
        end
    end
    return AilmentTracker
end
__moduleSources["Game/Interaction"] = function(...)
    local import = ...
    local Util = import("Core/Util")
    local GameConstants = import("Game/GameConstants")
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local Interaction = {}
    Interaction.__index = Interaction
    local INVOKE_TIMEOUT_SECONDS = 10
    function Interaction.new(logger, state)
        local self = setmetatable({}, Interaction)
        self._logger = logger
        self._state = state
        self._sent = 0
        local environment = Util.getSharedEnvironment()
        local me = game:GetService("Players").LocalPlayer
        local key = tostring(game.PlaceId) .. ":" .. tostring(me and me.UserId)
        environment.AdoptMeLocalOperations = environment.AdoptMeLocalOperations or {}
        environment.AdoptMeLocalOperations[key] = environment.AdoptMeLocalOperations[key] or { pending = {}, purchases = {} }
        self._operations = environment.AdoptMeLocalOperations[key]
        self._operations.consumptions = self._operations.consumptions or {}
        return self
    end
    function Interaction.describeActions()
        local names = {}
        for name in pairs(GameConstants.Actions) do
            table.insert(names, name)
        end
        table.sort(names)
        local lines = {}
        for _, name in ipairs(names) do
            local action = GameConstants.Actions[name]
            table.insert(lines, action.remote .. " — " .. action.purpose)
        end
        table.insert(lines, "LOCAL teleport of your character inside the neighborhood to the camp site / beach / playground (Farm.SpotTravel)")
        table.insert(lines, "LOCAL click on the main menu Play button and then HOME in \"Choose Location!\" — only on the menu (Farm.AutoAcceptMenu)")
        table.insert(lines, "LOCAL call of the game's OWN travel function (InteriorsM.enter, the one every door uses): it sends the game's own door / location requests (Farm.GameTravel); also to visit other players' houses for the \"Visit player homes\" quests (Farm.Event.HouseVisits)")
        table.insert(lines, "LOCAL walking of your character in long diagonal legs (~30 studs) — ONLY for the walk need (and ride); if the game left it anchored on solid ground, it is un-anchored first")
        table.insert(lines, "LOCAL teleport of your character next to the Stray Cat (Halloween map), into the Ghost Gallery join circle in the Haunted Manor (where the popup's Yes puts you) and, inside the minigame only, next to its vacuum target on a confirmed floor (Farm.Event)")
        table.insert(lines, "LOCAL teleport of your character into the selected door's join circle inside the Hauntlet rooms, requesting nearby room streaming when needed (Farm.Event.Hauntlet)")
        table.insert(lines, "LOCAL virtual click — only when Roblox says you are idle, to avoid the 20-minute kick (Farm.AntiAfk)")
        table.insert(lines, "ROBLOX rejoin of a server of this game (TeleportService) — only after 3 min with no place / no character, e.g. a white screen in a dead minigame (Farm.AutoRejoin)")
        return lines
    end
    function Interaction.virtualClick()
        return pcall(function()
            local virtualUser = game:GetService("VirtualUser")
            virtualUser:CaptureController()
            virtualUser:ClickButton2(Vector2.new(0, 0))
        end)
    end
    Interaction.CLICK_METHODS = { "firesignal", "connections", "touch", "mouse" }
    local CLICK_SIGNALS = { "Activated", "MouseButton1Click" }
    local function buttonCentre(button)
        local screenGui = button:FindFirstAncestorOfClass("ScreenGui")
        local inset = (screenGui and screenGui.IgnoreGuiInset) and Vector2.new(0, 0)
            or game:GetService("GuiService"):GetGuiInset()
        return button.AbsolutePosition.X + button.AbsoluteSize.X / 2 + inset.X,
            button.AbsolutePosition.Y + button.AbsoluteSize.Y / 2 + inset.Y
    end
    function Interaction.clickButton(button, method)
        if method == "connections" then
            if type(getconnections) ~= "function" then
                return false, "getconnections missing"
            end
            local fired = 0
            for _, signalName in ipairs(CLICK_SIGNALS) do
                if fired > 0 then break end
                pcall(function()
                    for _, connection in ipairs(getconnections(button[signalName])) do
                        if pcall(function() connection:Fire() end) or pcall(connection.Function) then
                            fired += 1
                        end
                    end
                end)
            end
            return fired > 0, "(" .. fired .. " connections)"
        elseif method == "firesignal" then
            if type(firesignal) ~= "function" then
                return false, "firesignal missing"
            end
            local ok, reason = pcall(firesignal, button.Activated)
            return ok, ok and "activation sent; awaiting UI change" or tostring(reason)
        end
        local ok, err = pcall(function()
            local vim = game:GetService("VirtualInputManager")
            local x, y = buttonCentre(button)
            if method == "touch" then
                vim:SendTouchEvent(1, 0, x, y)
                task.wait(0.1)
                vim:SendTouchEvent(1, 2, x, y)
            else
                vim:SendMouseButtonEvent(x, y, 0, true, game, 0)
                task.wait(0.1)
                vim:SendMouseButtonEvent(x, y, 0, false, game, 0)
            end
        end)
        return ok, ok and "" or tostring(err)
    end
    function Interaction:teleportTo(spotName)
        local spot = GameConstants.Spots[spotName]
        if not spot then return false, "unknown destination spot: " .. tostring(spotName) end
        local Safety = import("Game/TravelSafety")
        self._travelSafety = self._travelSafety or Safety.new(self._logger, self._state)
        if not self._travelSafety:ready("MainMap") then
            return false, "leave through the house and neighborhood doors before moving to an outdoor spot"
        end
        local moved, reason = self._travelSafety:move(Vector3.new(spot.x, spot.y, spot.z), "MainMap", 16)
        if moved then
            self._sent += 1
            self._state:set("farm.actionsSent", self._sent, "Interaction")
        end
        return moved, reason
    end
    -- v2.1.4 Auto Skelicorn: stand next to a part found in the map (the lever machine by the Manor)
    function Interaction:protectTransition(seconds)
        local Safety = import("Game/TravelSafety")
        self._travelSafety = self._travelSafety or Safety.new(self._logger, self._state)
        local job, reason = self._travelSafety:begin(math.clamp(tonumber(seconds) or 35, 5, 90))
        return job ~= nil, reason
    end
    function Interaction:teleportNearPart(part, studs)
        local player = game:GetService("Players").LocalPlayer
        local character = player and player.Character
        local root = character and character:FindFirstChild("HumanoidRootPart")
        if not (root and part and part.Parent and part:IsA("BasePart")) then return false, "no character / part" end
        local Safety = import("Game/TravelSafety")
        self._travelSafety = self._travelSafety or Safety.new(self._logger, self._state)
        local destination = Safety.placeName(self._state:get("player.interior"))
        local offset = math.clamp(tonumber(studs) or 6, 2, 20)
        local away = (root.Position - part.Position) * Vector3.new(1, 0, 1)
        local dir = away.Magnitude > 1 and away.Unit or Vector3.new(0, 0, 1)
        local goal = part.Position + dir * offset + Vector3.new(0, 3, 0)
        local moved, reason = self._travelSafety:move(goal, destination, 12)
        if moved then
            self._sent += 1
            self._state:set("farm.actionsSent", self._sent, "Interaction")
        end
        return moved, reason
    end
    function Interaction:teleportToJoinZone()
        local E = GameConstants.Event
        local Safety = import("Game/TravelSafety")
        self._travelSafety = self._travelSafety or Safety.new(self._logger, self._state)
        local safety = self._travelSafety
        if not safety:ready("HauntedManor") then return false, "Manor lobby floor not ready" end
        local spot = workspace
        for _, name in ipairs(E.JoinZoneTeleportPath) do spot = spot and spot:FindFirstChild(name) end
        if not spot or not spot:IsA("BasePart") then
            local scene = safety:sceneRoot("HauntedManor")
            local zone = scene and scene:FindFirstChild("GhostClustersMinigameJoinZone", true)
            spot = zone and (zone:IsA("BasePart") and zone or zone:FindFirstChildWhichIsA("BasePart", true))
        end
        if not spot then return false, "live Ghost Gallery join circle unavailable" end
        return safety:move(spot.Position + Vector3.new(0, 3, 0), "HauntedManor", 10)
    end
    function Interaction:teleportToHauntletJoinZone()
        self:protectTransition(65)
        local Players = game:GetService("Players")
        local player = Players.LocalPlayer
        local character = player and player.Character
        local root = character and character:FindFirstChild("HumanoidRootPart")
        if not root then
            return false, "character root not found"
        end
        local deadline = Util.now() + 15
        local target
        local streamAsked = false
        repeat
            local interiors = workspace:FindFirstChild("Interiors")
            local hotel = interiors and interiors:FindFirstChild("HauntedHotel")
            local zone = hotel and hotel:FindFirstChild("HauntletMinigameJoinZone")
            -- v2.1.5 (night reports: "Hauntlet join zone not found" on 4 accounts, 120 s in the hotel, never queued):
            -- the zone may sit deeper or stream in late: look anywhere under Interiors / the workspace, ask the game
            -- to stream the hotel around me once (never waited for)
            if not zone then
                zone = (hotel and hotel:FindFirstChild("HauntletMinigameJoinZone", true))
                    or (interiors and interiors:FindFirstChild("HauntletMinigameJoinZone", true))
                    or workspace:FindFirstChild("HauntletMinigameJoinZone", true)
            end
            if not zone and not streamAsked then
                streamAsked = true
                task.spawn(pcall, function()
                    player:RequestStreamAroundAsync(root.Position, 5)
                end)
            end
            if zone then
                local ring = nil
                if not zone:IsA("BasePart") then
                    ring = zone:FindFirstChild("Ring", true)
                end
                if ring then
                    if ring:IsA("BasePart") then
                        target = ring
                    else
                        target = ring:FindFirstChild("Part")
                        if not (target and target:IsA("BasePart")) then
                            target = ring:FindFirstChildWhichIsA("BasePart", true)
                        end
                    end
                end
                if not target then
                    if zone:IsA("BasePart") then
                        target = zone
                    else
                        target = zone:FindFirstChildWhichIsA("BasePart", true)
                    end
                end
            end
            if not target then
                task.wait(0.25)
            end
        until target or Util.now() >= deadline
        if not target then
            local interiors = workspace:FindFirstChild("Interiors")
            local names = {}
            for _, child in ipairs(interiors and interiors:GetChildren() or {}) do
                table.insert(names, child.Name)
            end
            return false, "Hauntlet join zone not found (interiors loaded: " .. (#names > 0 and table.concat(names, ", ") or "none") .. ")"
        end
        local destination = target.Position + Vector3.new(0, (target.Size and target.Size.Y or 2) * 0.5 + 2.5, 0)
        local ok, err = pcall(function()
            character:PivotTo(CFrame.new(destination) * CFrame.Angles(0, math.rad(root.Orientation.Y), 0))
        end)
        if not ok then
            return false, tostring(err)
        end
        self._sent += 1
        self._state:set("farm.actionsSent", self._sent, "Interaction")
        pcall(Interaction.settle, 2) -- v2.1.6: never left inside the lobby floor
        task.wait(0.6)
        local now = root.Position
        local dx, dz = now.X - target.Position.X, now.Z - target.Position.Z
        local dist = math.sqrt(dx * dx + dz * dz)
        if dist > 18 then
            return false, "not in the join circle after teleport (dist " .. string.format("%.1f", dist) .. ")"
        end
        return true, target:GetFullName()
    end
    --[[
        Hauntlet door circles (Dex, 2026-10-10): every room has a folder DoorJoinCircles with the parts "1", "2", "3"
        (one per door; the number is the door's number in the server's messages) and the TeleportRing models; the
        room's other folders are DoorPositions, Doors, DoorCounters, GhostPositions. Standing in a circle makes the GAME
        send the pick itself (a pick sent by a script bugs the run: user), so the character is only moved there.
        The room is the DoorJoinCircles folder nearest to my character (the game moves me into each new room).
    ]]
    local function hauntletPartOf(node)
        if node:IsA("BasePart") then
            return node
        end
        local part = node:FindFirstChild("Part")
        if part and part:IsA("BasePart") then
            return part
        end
        return node:FindFirstChildWhichIsA("BasePart", true)
    end
    local hauntletCenter -- set below (Interaction.hauntletCenter)
    hauntletCenter = function(node)
        if node:IsA("BasePart") then
            return node.Position
        end
        local sum, n = nil, 0
        for _, d in ipairs(node:GetDescendants()) do
            if d:IsA("BasePart") then
                sum = sum and (sum + d.Position) or d.Position
                n += 1
            end
        end
        return n > 0 and sum / n or nil
    end
    -- The circle part for door `doorIndex` in this DoorJoinCircles folder. bad = { [part] = true } parts that turned
    -- out to belong to another door. Returns part, how, verified (false = a guess the pick check must confirm).
    function Interaction.hauntletCircleFor(circles, doorIndex, bad)
        bad = bad or {}
        if circles.Name == "Elevators" then
            -- nexus (ReplicatedStorage.Resources.Hauntlet.Rooms.nexus): Elevators/<elevator>/JoinCircle, the areas shown
            -- on AreaDisplays/1, 2: the elevator named n, else the one nearest AreaDisplays/n
            local elevators = {}
            for _, elevator in ipairs(circles:GetChildren()) do
                local circle = elevator:FindFirstChild("JoinCircle", true)
                if circle and circle:IsA("BasePart") and not bad[circle] then
                    table.insert(elevators, { node = elevator, part = circle })
                end
            end
            for _, entry in ipairs(elevators) do
                if entry.node.Name == tostring(doorIndex) then
                    return entry.part, "elevator '" .. doorIndex .. "'", true
                end
            end
            local displays = circles.Parent and circles.Parent:FindFirstChild("AreaDisplays")
            local display = displays and displays:FindFirstChild(tostring(doorIndex))
            local spot = display and hauntletCenter(display)
            if spot and #elevators > 0 then
                table.sort(elevators, function(x, y)
                    return (x.part.Position - spot).Magnitude < (y.part.Position - spot).Magnitude
                end)
                return elevators[1].part, "elevator nearest AreaDisplays." .. doorIndex, true
            end
            if elevators[doorIndex] then
                return elevators[doorIndex].part, "GUESS elevator " .. doorIndex, false
            end
            return nil, "no elevator for door " .. doorIndex
        end
        local named = circles:FindFirstChild(tostring(doorIndex))
        local part = named and hauntletPartOf(named)
        if part and not bad[part] then
            return part, "circle '" .. doorIndex .. "'", true
        end
        local candidates = {}
        for _, child in ipairs(circles:GetChildren()) do
            local p = hauntletPartOf(child)
            if p and not bad[p] then
                table.insert(candidates, p)
            end
        end
        if #candidates == 0 then
            return nil, "no circle part"
        end
        local room = circles.Parent
        for _, folderName in ipairs({ "DoorPositions", "Doors", "DoorCounters" }) do
            local folder = room and room:FindFirstChild(folderName)
            local marker = folder and folder:FindFirstChild(tostring(doorIndex))
            local spot = marker and hauntletCenter(marker)
            if spot then
                local best, bestDist = nil, math.huge
                for _, p in ipairs(candidates) do
                    local dist = (p.Position - spot).Magnitude
                    if dist < bestDist then
                        best, bestDist = p, dist
                    end
                end
                return best, string.format("circle nearest %s.%d", folderName, doorIndex), true
            end
        end
        return candidates[math.clamp(doorIndex, 1, #candidates)], "GUESS (no named circle or door marker)", false
    end
    -- The DoorJoinCircles folder of the room I am in: the nearest one that is not in `avoid` ({ [folder] = true }:
    -- groups that took no pick in this room; every room is named "default", so names do not tell them apart).
    -- Returns circles, distance, candidates.
    local circleIds = setmetatable({}, { __mode = "k" })
    local nextCircleId = 0
    function Interaction.hauntletCircleId(node)
        if not circleIds[node] then
            nextCircleId += 1
            circleIds[node] = nextCircleId
        end
        return circleIds[node]
    end
    -- Every room of a run is a NEW model further along (debug log 2026-10-10: the game does not move me and the old
    -- rooms stay; the nearest group was the room I had just left, and "1 group" grew by one each room). So the newest
    -- group goes first: groups added after the run's interior was first seen carry their time (DescendantAdded), the
    -- ones that were already there count as the oldest. The nexus room may name its circles differently.
    local circleAddedAt = setmetatable({}, { __mode = "k" }) -- [group] = its order of appearance (1, 2, ...)
    local circleSeenAt = setmetatable({}, { __mode = "k" }) -- [group] = os.clock() when it appeared
    local circleOrder = 0
    local watchedInteriors = setmetatable({}, { __mode = "k" })
    local function isCircleGroup(node)
        return node.Name == "DoorJoinCircles" or node.Name == "Elevators"
    end
    Interaction.hauntletIsCircleGroup = isCircleGroup
    function Interaction.watchHauntletInterior(interior)
        if not interior or watchedInteriors[interior] then
            return
        end
        local connected, connection = pcall(function()
            return interior.DescendantAdded:Connect(function(node)
                if isCircleGroup(node) then
                    circleOrder += 1
                    circleAddedAt[node], circleSeenAt[node] = circleOrder, os.clock()
                end
            end)
        end)
        watchedInteriors[interior] = connected and connection or nil
    end
    function Interaction.disconnectHauntletWatches()
        for interior, connection in pairs(watchedInteriors) do
            pcall(function() connection:Disconnect() end)
            watchedInteriors[interior] = nil
        end
    end
    local function hauntletInterior(interiorName)
        local interiors = workspace:FindFirstChild("Interiors")
        if not interiors then
            return nil
        end
        local prefix = GameConstants.Event.HauntletInteriorPrefix
        local interior = type(interiorName) == "string" and interiors:FindFirstChild(interiorName) or nil
        if not interior then
            for _, child in ipairs(interiors:GetChildren()) do
                if string.sub(child.Name, 1, #prefix) == prefix then
                    return child
                end
            end
        end
        return interior
    end
    -- Called when a run starts, so that every later room is seen being added.
    function Interaction:watchHauntlet(interiorName)
        local interior = hauntletInterior(interiorName)
        Interaction.watchHauntletInterior(interior)
        return interior ~= nil
    end
    -- Rooms are a chain (the run is built ahead: live log 3 had 6 rooms ready up to 230 studs ahead, one ~43 studs
    -- behind and one ~43 ahead): every room's AttachmentPoints has an Entrance and an Exit (a nexus: Exit1, Exit2) and
    -- the next room's Entrance sits on this room's Exit. link = { from = the last room's circle group, exit = "Exit" }.
    local function attachmentPoint(room, name)
        local points = room and room:FindFirstChild("AttachmentPoints")
        local point = points and points:FindFirstChild(name)
        if not point and points and (name == "Exit" or name == "Entrance") then
            -- another area's rooms may number them (Exit1 / Entrance1): the first one of that kind
            for _, child in ipairs(points:GetChildren()) do
                if child:IsA("Attachment") and string.sub(child.Name, 1, #name) == name then
                    point = child
                    break
                end
            end
        end
        return point and point:IsA("Attachment") and point.WorldPosition or nil
    end
    Interaction.hauntletAttachmentPoint = attachmentPoint
    Interaction.hauntletPosKey = function(node)
        local ok, center = pcall(function()
            return hauntletCenter(node)
        end)
        if not ok or not center then
            return nil
        end
        return string.format("%d:%d:%d", math.floor(center.X / 6 + 0.5), math.floor(center.Y / 6 + 0.5), math.floor(center.Z / 6 + 0.5))
    end
    Interaction.hauntletCenter = function(node)
        return hauntletCenter(node)
    end
    -- base / visited (user, live run 5: "the rooms spawn on one line going forward: the room farthest from the start is
    -- the one to pick in; reset the start after every nexus"): the first room past the farthest room I picked in,
    -- measured from base; when it is not loaded yet (its circles come 1-2 s after started_room), nil: wait, never back.
    -- behind = { base, limit } (live run 6, room 11: right after a nexus the old rooms were still loaded and one was
    -- as far from the nexus as the next room): a group closer to the previous start than the nexus is behind me.
    function Interaction:hauntletCircles(interiorName, avoid, link, base, visited, behind)
        local root = self:_myRoot()
        local interiors = workspace:FindFirstChild("Interiors")
        if not (root and interiors) then
            return nil, "no character / Interiors"
        end
        local prefix = GameConstants.Event.HauntletInteriorPrefix
        local interior = type(interiorName) == "string" and interiors:FindFirstChild(interiorName) or nil
        if not interior then
            for _, child in ipairs(interiors:GetChildren()) do
                if string.sub(child.Name, 1, #prefix) == prefix then
                    interior = child
                    break
                end
            end
        end
        if not interior then
            return nil, "no " .. prefix .. " interior"
        end
        Interaction.watchHauntletInterior(interior)
        local found = {}
        local wanted = avoid and avoid.__elevators and "Elevators" or "DoorJoinCircles"
        for _, node in ipairs(interior:GetDescendants()) do
            if node.Name == wanted and #node:GetChildren() > 0 then
                local center = hauntletCenter(node)
                -- v2.1.6: from room 2 on, the circles I stand in are the last room's (log: "group #3, 2 studs away")
                local underMe = center and avoid and avoid.__skipNear and (center - root.Position).Magnitude < 8
                if center and not underMe then
                    table.insert(found, { node = node, dist = (center - root.Position).Magnitude,
                        added = circleAddedAt[node] or 0, seen = circleSeenAt[node] })
                end
            end
        end
        table.sort(found, function(a, b)
            if a.added ~= b.added then
                return a.added > b.added -- the newest room first
            end
            return a.dist < b.dist
        end)
        avoid = avoid or {}
        local exit = link and link.from and link.from.Parent and attachmentPoint(link.from.Parent, link.exit or "Exit")
        if exit then
            local best, bestGap = nil, math.huge
            for _, entry in ipairs(found) do
                local entrance = entry.node ~= link.from and not avoid[entry.node] and attachmentPoint(entry.node.Parent, "Entrance")
                if entrance and (entrance - exit).Magnitude < bestGap then
                    best, bestGap = entry, (entrance - exit).Magnitude
                end
            end
            if best and bestGap < 12 then
                return best.node, best.dist, #found, best.seen, "the room after the last one"
            end
        end
        if base and not (avoid and avoid.__elevators) then
            visited = visited or {}
            local farthestPassed = 0
            for _, entry in ipairs(found) do
                entry.fromBase = (hauntletCenter(entry.node) - base).Magnitude
                if visited[entry.node] then
                    farthestPassed = math.max(farthestPassed, entry.fromBase)
                end
            end
            local function isBehind(entry)
                return behind ~= nil and behind.base ~= nil
                    and (hauntletCenter(entry.node) - behind.base).Magnitude < (tonumber(behind.limit) or 0) - 5
            end
            local nextRoom
            for _, entry in ipairs(found) do
                if not avoid[entry.node] and entry.fromBase > farthestPassed + 5 and not isBehind(entry)
                    and (not nextRoom or entry.fromBase < nextRoom.fromBase) then
                    nextRoom = entry
                end
            end
            if nextRoom then
                return nextRoom.node, nextRoom.dist, #found, nextRoom.seen,
                    string.format("next room forward (%d studs from the start)", math.floor(nextRoom.fromBase))
            end
            return nil, "the next room is not loaded yet"
        end
        for _, entry in ipairs(found) do
            if not avoid[entry.node] then
                return entry.node, entry.dist, #found, entry.seen
            end
        end
        if found[1] and next(visited or {}) == nil then -- never back into a room already passed
            return found[1].node, found[1].dist, #found, found[1].seen
        end
        return nil, "no DoorJoinCircles near (interior " .. interior.Name .. ")"
    end
    --[[
        v2.1.4 (debug log 2026-10-10, kicked "out_of_time" in room 13): the room of a started_room is found along the
        chain, NOT from where I picked: from the last room's exit (a nexus: Exit<n>, n = the area that won), the room
        whose Entrance sits on it; elevator rooms in between (after a nexus, before room 1) have no circles: walk on
        through their Exit. Returns the circle folder (DoorJoinCircles, or Elevators for a nexus) or nil, reason.
    ]]
    function Interaction:hauntletNextGroup(interiorName, fromGroup, exitName)
        local interior = hauntletInterior(interiorName)
        local rooms = interior and interior:FindFirstChild("Rooms")
        local fromRoom = fromGroup and fromGroup.Parent
        local point = fromRoom and attachmentPoint(fromRoom, exitName or "Exit")
        if not (rooms and point) then
            return nil, "no chain start (" .. tostring(exitName) .. ")"
        end
        local seen = { [fromRoom] = true }
        for _ = 1, 4 do
            local nextRoom, gap = nil, 12
            for _, room in ipairs(rooms:GetChildren()) do
                if not seen[room] then
                    local entrance = attachmentPoint(room, "Entrance")
                    if entrance and (entrance - point).Magnitude < gap then
                        nextRoom, gap = room, (entrance - point).Magnitude
                    end
                end
            end
            if not nextRoom then
                return nil, "the next room is not loaded yet"
            end
            seen[nextRoom] = true
            for _, name in ipairs({ "DoorJoinCircles", "Elevators" }) do
                local group = nextRoom:FindFirstChild(name)
                if group and #group:GetChildren() > 0 then
                    return group
                end
            end
            point = attachmentPoint(nextRoom, "Exit") -- an elevator room: on through it
            if not point then
                return nil, "a room without circles or exit"
            end
        end
        return nil, "no room with circles along the chain"
    end
    function Interaction:_myRoot()
        local player = game:GetService("Players").LocalPlayer
        local character = player and player.Character
        return character and character:FindFirstChild("HumanoidRootPart"), character, player
    end
    --[[
        v2.1.6 (user screenshot: after a teleport the character sank into the floor of the hotel lobby and lay there):
        settle(maxWait) finds the floor under me (a ray from above my head, my own character ignored) and, when my
        root sits lower than a standing character would, puts me back on top of it and gets me up. When the floor is
        not there yet (still streaming), I am held in place (anchored) up to maxWait seconds instead of falling into
        whatever loads around me. Never anchors for longer, never moves me when I already stand right.
        Returns "ok" | "lifted" | "no floor" | "no character".
    ]]
    local function floorUnder(root, character)
        local params = RaycastParams.new()
        params.FilterType = Enum.RaycastFilterType.Exclude
        params.FilterDescendantsInstances = { character }
        for _, height in ipairs({ 6, 12, 25 }) do
            local hit = workspace:Raycast(root.Position + Vector3.new(0, height, 0), Vector3.new(0, -(height + 30), 0), params)
            -- a hit far above my feet is a ceiling / table over me, not my floor: look from lower first
            if hit and hit.Position.Y < root.Position.Y + 2 then
                return hit.Position.Y
            end
        end
        return nil
    end
    Interaction.floorUnder = floorUnder
    --[[
        v2.1.6 (user screenshots: characters wedged in a railing / inside other models for the whole game, the
        Humanoid stuck "Jumping"): unstick() looks for the nearest free standing spot around me (rings of 4 / 8 / 12
        studs, 8 directions): a floor under it, and no solid part where my body would stand. Moves me there.
        Returns the distance moved, or nil when no free spot was found.
    ]]
    function Interaction.unstick()
        local player = game:GetService("Players").LocalPlayer
        local character = player and player.Character
        local root = character and character:FindFirstChild("HumanoidRootPart")
        local humanoid = character and character:FindFirstChildOfClass("Humanoid")
        if not (root and humanoid) then
            return nil
        end
        local ignore = { character }
        local pets = workspace:FindFirstChild(GameConstants.PetsFolderName or "Pets")
        if pets then
            table.insert(ignore, pets)
        end
        local rayParams = RaycastParams.new()
        rayParams.FilterType = Enum.RaycastFilterType.Exclude
        rayParams.FilterDescendantsInstances = ignore
        local boxParams = OverlapParams.new()
        boxParams.FilterType = Enum.RaycastFilterType.Exclude
        boxParams.FilterDescendantsInstances = ignore
        local hip = (humanoid.HipHeight or 2) + root.Size.Y * 0.5
        local origin = root.Position
        local function freeAt(x, z)
            local hit = workspace:Raycast(Vector3.new(x, origin.Y + 6, z), Vector3.new(0, -30, 0), rayParams)
            if not (hit and hit.Instance and hit.Instance.CanCollide) then
                return nil
            end
            local stand = Vector3.new(x, hit.Position.Y + hip + 0.3, z)
            -- the body: from just above the floor to the head
            local parts = workspace:GetPartBoundsInBox(CFrame.new(stand + Vector3.new(0, 0.5, 0)), Vector3.new(2.5, 4.5, 2.5),
                boxParams)
            for _, part in ipairs(parts) do
                if part.CanCollide then
                    return nil
                end
            end
            return stand
        end
        for _, radius in ipairs({ 4, 8, 12 }) do
            for step = 0, 7 do
                local angle = step * math.pi / 4
                local spot = freeAt(origin.X + math.cos(angle) * radius, origin.Z + math.sin(angle) * radius)
                if spot then
                    local moved = pcall(function()
                        root.AssemblyLinearVelocity = Vector3.zero
                        root.AssemblyAngularVelocity = Vector3.zero
                        character:PivotTo(CFrame.new(spot))
                        humanoid:ChangeState(Enum.HumanoidStateType.Landed)
                    end)
                    if moved then
                        return radius
                    end
                end
            end
        end
        return nil
    end
    function Interaction.settle(maxWait)
        local player = game:GetService("Players").LocalPlayer
        local character = player and player.Character
        local root = character and character:FindFirstChild("HumanoidRootPart")
        local humanoid = character and character:FindFirstChildOfClass("Humanoid")
        if not (root and humanoid) then
            return "no character"
        end
        if humanoid.Sit or humanoid.SeatPart then
            return "ok"
        end
        local floor = floorUnder(root, character)
        if not floor and (tonumber(maxWait) or 0) > 0 then
            local wasAnchored = root.Anchored
            pcall(function()
                root.Anchored = true
            end)
            task.spawn(pcall, function()
                player:RequestStreamAroundAsync(root.Position, 2)
            end)
            local untilAt = os.clock() + maxWait
            while not floor and os.clock() < untilAt and root.Parent do
                task.wait(0.1)
                floor = floorUnder(root, character)
            end
            if not wasAnchored then
                pcall(function()
                    root.Anchored = false
                end)
            end
        end
        if not floor then
            return "no floor"
        end
        local stand = floor + (humanoid.HipHeight or 2) + root.Size.Y * 0.5
        local lifted = false
        if root.Position.Y < stand - 1.2 then
            lifted = pcall(function()
                root.AssemblyLinearVelocity = Vector3.zero
                root.AssemblyAngularVelocity = Vector3.zero
                local look = root.CFrame.LookVector * Vector3.new(1, 0, 1)
                local at = Vector3.new(root.Position.X, stand + 0.5, root.Position.Z)
                character:PivotTo(look.Magnitude > 0.1 and CFrame.lookAt(at, at + look) or CFrame.new(at))
            end)
        end
        pcall(function()
            local state = humanoid:GetState()
            if state == Enum.HumanoidStateType.FallingDown or state == Enum.HumanoidStateType.Ragdoll
                or state == Enum.HumanoidStateType.Physics or lifted then
                humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
            end
        end)
        return lifted and "lifted" or "ok"
    end
    -- Moves my character into door `doorIndex`'s circle. options = { avoid = { [circles] = true } (groups that took no
    -- pick in this room), bad = { [part] = true } (parts that proved to be another door) }.
    -- Returns moved, how, part, circles, verified.
    function Interaction:teleportToHauntletDoor(interiorName, doorIndex, options)
        self:protectTransition(40)
        options = options or {}
        if type(doorIndex) ~= "number" or doorIndex < 1 or doorIndex > 4 then
            return false, "door index out of range: " .. tostring(doorIndex)
        end
        local root, character, player = self:_myRoot()
        if not root then
            return false, "no character"
        end
        local circles, part, how, verified, dist, count, added, chained
        if options.thisRoomGroup and options.thisRoomGroup.Parent then
            options.group = options.thisRoomGroup -- v2.1.6: a re-pick in this room: the circles I already picked in here
        end
        if options.group and options.group.Parent then
            -- v2.1.4: the room's circles are known from the chain: no search (it took up to 4 s and could pick a room
            -- that was not mine)
            circles = options.group
            part, how, verified = Interaction.hauntletCircleFor(circles, doorIndex, options.bad)
            if part then
                how = string.format("%s of the room on the chain (%d studs away)", tostring(how),
                    math.floor((part.Position - root.Position).Magnitude))
            end
        end
        -- v2.1.5 (night reports: "door 1 circle not found (no HauntletInterior interior)" 3 x 7 s, the door picked at
        -- 14.8 s, kicked from room 1): while the run's interior is not there yet, look again every 0.25 s (it comes
        -- whenever the device has loaded it) instead of 1 s steps; at most 6 slow looks or 8 s, whichever comes first
        local searchUntil, slowLooks = os.clock() + 8, 0
        while not part and slowLooks < 6 and os.clock() < searchUntil do
            local avoid = {}
            for key, value in pairs(options.avoid or {}) do
                avoid[key] = value
            end
            for key, value in pairs(options.visited or {}) do -- rooms already passed: never back
                avoid[key] = value
            end
            for key, value in pairs(options.passed or {}) do -- the rooms before the last nexus
                avoid[key] = value
            end
            avoid.__elevators = options.nexus or nil
            avoid.__skipNear = (tonumber(options.roomSeq) or 0) > 1 or nil
            circles, dist, count, added, chained = self:hauntletCircles(interiorName, avoid, options.link, options.base,
                options.visited, options.behind)
            if circles then
                part, how, verified = Interaction.hauntletCircleFor(circles, doorIndex, options.bad)
                if part then
                    how = string.format("%s of group #%d (%d studs away, %s, %d group%s in the run)", tostring(how),
                        Interaction.hauntletCircleId(circles), math.floor(tonumber(dist) or 0),
                        chained or (added and string.format("added %.0f s ago", os.clock() - added) or "nearest"),
                        count or 1, (count or 1) == 1 and "" or "s")
                    break
                end
            end
            -- v2.1.5 (user report "white screen", 2026-10-11): with streaming stuck this call never returned and the
            -- Hauntlet task hung in room 1 for 15+ minutes: never waited for any more
            local noInterior = type(dist) == "string" and string.find(dist, "interior", 1, true) ~= nil
            if not noInterior then
                slowLooks += 1
                task.spawn(pcall, function()
                    player:RequestStreamAroundAsync(root.Position, 2)
                end)
            end
            task.wait(noInterior and 0.25 or (options.base and 0.4 or 1)) -- the next room loads in 1-2 s: look again soon
        end
        -- v2.1.4 BUG B: never into the circles of a room already picked in (same object or same place)
        if part and circles then
            local key = Interaction.hauntletPosKey(circles)
            -- v2.1.5: a room I picked in THIS room (pushed out of a ??? door, plan changed) is not "going back"
            -- v2.1.6 (reports: "backtrack blocked ... this group" right after a key opened another door of the same
            -- room: the group's centre moves when TeleportRings are added, so its place key changed): the very group
            -- I picked in this room is this room
            local thisRoom = (options.thisRoomGroup ~= nil and circles == options.thisRoomGroup)
                or (key and options.visitedPos and options.roomSeq ~= nil and options.visitedPos[key] == options.roomSeq)
            local seenAt = (not thisRoom) and ((options.visited and options.visited[circles]) and "this group"
                or (key and options.visitedPos and options.visitedPos[key] and ("room " .. tostring(options.visitedPos[key]))))
            if seenAt then
                return false, string.format("backtrack blocked roomSeq=%s (door %d: the circles of %s, already passed)",
                    tostring(options.roomSeq), doorIndex, seenAt)
            end
        end
        if not part then
            -- v2.1.3: say why (hauntletCircles' reason comes back in the distance slot when no group was found)
            return false, "door " .. doorIndex .. " circle not found (" .. tostring(how or (type(dist) == "string" and dist)
                or "no circles near me") .. ")"
        end
        local waited = 0
        while root.Anchored and waited < 8 do -- the game is moving me (room change): wait for it
            task.wait(0.5)
            waited += 0.5
        end
        task.spawn(pcall, function() -- v2.1.4: not waited for (it could hold the move for seconds)
            player:RequestStreamAroundAsync(part.Position, 2)
        end)
        self._sent += 1
        self._state:set("farm.actionsSent", self._sent, "Interaction")
        -- user (live run 3): "entering the circle plays an animation and puts me back where I was: we go too fast".
        -- tween (default): glide there at 50 studs/s; walk: the Humanoid walks (tween when it gets stuck); tp: at once
        local goal = part.Position + Vector3.new(0, part.Size.Y * 0.5 + 3, 0)
        local method = options.method or "tween"
        local function glide()
            local seconds = math.clamp(tonumber(options.seconds) or ((root.Position - goal).Magnitude / 50), 0.1, 5)
            local tween = game:GetService("TweenService"):Create(root, TweenInfo.new(seconds, Enum.EasingStyle.Linear),
                { CFrame = CFrame.new(goal) * (root.CFrame - root.CFrame.Position) })
            tween:Play()
            local deadline = os.clock() + seconds + 1
            while tween.PlaybackState == Enum.PlaybackState.Playing and os.clock() < deadline do
                task.wait(0.05)
            end
        end
        local ok, err = pcall(function()
            if method == "tp" then
                character:PivotTo(CFrame.new(goal))
            elseif method == "walk" then
                local humanoid = character:FindFirstChildOfClass("Humanoid")
                humanoid:MoveTo(Vector3.new(goal.X, root.Position.Y, goal.Z))
                local deadline = os.clock() + math.clamp((root.Position - goal).Magnitude / 12, 2, 12)
                while os.clock() < deadline do
                    if Vector3.new(root.Position.X - goal.X, 0, root.Position.Z - goal.Z).Magnitude < 3 then
                        return
                    end
                    task.wait(0.1)
                end
                glide() -- a wall in the way: the last bit by tween
            else
                glide()
            end
        end)
        if not ok then
            return false, tostring(err)
        end
        self._logger:debug("Action", string.format("Hauntlet: door %d -> %s (%s, %s)", doorIndex, part:GetFullName(),
            tostring(how), method))
        return true, how, part, circles, verified
    end
    function Interaction:keepNear(provider)
        local Safety = import("Game/TravelSafety")
        self._travelSafety = self._travelSafety or Safety.new(self._logger, self._state)
        local safety = self._travelSafety
        local player = game:GetService("Players").LocalPlayer
        local character = player.Character
        local root = character and character:FindFirstChild("HumanoidRootPart")
        local humanoid = character and character:FindFirstChildOfClass("Humanoid")
        local scene = self._state:get("player.interior")
        local stats, running = { corrections = 0, noFloor = 0 }, root ~= nil and humanoid ~= nil
        local watcher
        if running then safety:begin(260) end
        local function step()
            if not running or player.Character ~= character or not root.Parent or humanoid.Health <= 0
                or self._state:get("player.interior") ~= scene or root.Anchored then return false end
            local position, mode = provider()
            if position == false then running = false; return false end
            if not position then return false end
            local offset = math.clamp(tonumber(mode) or 6, 3, 12)
            local direction = (root.Position - position) * Vector3.new(1, 0, 1)
            direction = direction.Magnitude > 0.1 and direction.Unit or Vector3.new(0, 0, 1)
            local horizontal = position + direction * offset
            -- Stay on a real nearby floor; never place the avatar 50 studs below a ghost/in the void.
            local probe = Vector3.new(horizontal.X, root.Position.Y, horizontal.Z)
            local floor = safety:ground(probe, character, 30, 6)
            if not floor then stats.noFloor += 1; return false end
            local height = math.clamp((humanoid.HipHeight or 2) + root.Size.Y / 2, 2, 6) + 0.15
            local goal = Vector3.new(horizontal.X, floor.Position.Y + height, horizontal.Z)
            if (root.Position - goal).Magnitude > 250 then return false end
            local ok = pcall(function()
                root.AssemblyLinearVelocity = Vector3.zero
                if (root.Position - goal).Magnitude > 1 then
                    safety:_support(goal, root, humanoid)
                    if safety._job then safety._job.heldY, safety._job.position = goal.Y, goal end
                    character:PivotTo(CFrame.lookAt(goal, Vector3.new(position.X, goal.Y, position.Z)))
                    stats.corrections += 1
                end
            end)
            return ok
        end
        if running then
            watcher = task.spawn(function()
                while running do step(); task.wait(0.1) end
            end)
        end
        local stopped = false
        local function stop()
            if stopped then return end
            stopped, running = true, false
            if watcher then pcall(task.cancel, watcher); watcher = nil end
            safety:cancel()
        end
        return stop, stats, step
    end
    function Interaction:releaseAnchor(root, character, reason)
        if not root or not root.Anchored then
            return true
        end
        local below
        pcall(function()
            local params = RaycastParams.new()
            params.FilterType = Enum.RaycastFilterType.Exclude
            params.FilterDescendantsInstances = { character }
            local hit = workspace:Raycast(root.Position, Vector3.new(0, -25, 0), params)
            below = hit and hit.Position
        end)
        if not below then
            self._logger:debug("Action", "Root anchored, no ground under it yet: leaving it")
            return false
        end
        local ok = pcall(function()
            root.Anchored = false
        end)
        self._logger:info("Action", "My character was left anchored by the game (" .. tostring(reason) .. "): released it"
            .. (ok and "" or " (failed)"))
        return ok and not root.Anchored
    end
    function Interaction:walkAround(seconds, done, tick)
        local character = game:GetService("Players").LocalPlayer.Character
        local humanoid = character and character:FindFirstChildOfClass("Humanoid")
        local root = character and character:FindFirstChild("HumanoidRootPart")
        if not humanoid or not root then
            return false
        end
        self._logger:debug("Action", "Walking long diagonal legs for up to " .. seconds .. " s")
        if root.Anchored then
            local waited = 0
            while root.Anchored and waited < 3 do
                task.wait(0.5)
                waited += 0.5
            end
            self:releaseAnchor(root, character, "before walking")
        end
        local start = root.Position
        local fx, fz = 0, -1
        pcall(function()
            local look = root.CFrame.LookVector
            local length = math.sqrt(look.X * look.X + look.Z * look.Z)
            if length > 0.1 then
                fx, fz = look.X / length, look.Z / length
            end
        end)
        local rx, rz = -fz, fx
        local LEG = 30
        local points = {
            Vector3.new(start.X + (fx - rx) * LEG, start.Y, start.Z + (fz - rz) * LEG),
            Vector3.new(start.X + (fx + rx) * LEG, start.Y, start.Z + (fz + rz) * LEG),
            Vector3.new(start.X, start.Y, start.Z),
        }
        local elapsed, index = 0, 0
        while elapsed < seconds do
            if done() then
                return true
            end
            index = index % #points + 1
            local target = points[index]
            local legTime, still, last = 0, 0, root.Position
            while legTime < 5 and elapsed < seconds do
                humanoid:MoveTo(target)
                task.wait(0.5)
                legTime += 0.5
                elapsed += 0.5
                if tick then
                    tick()
                end
                if done() then
                    return true
                end
                local p = root.Position
                if math.sqrt((p.X - target.X) ^ 2 + (p.Z - target.Z) ^ 2) < 4 then
                    break
                end
                if math.sqrt((p.X - last.X) ^ 2 + (p.Z - last.Z) ^ 2) < 0.5 then
                    still += 0.5
                    if still == 1 then
                        local diag = {}
                        pcall(function()
                            table.insert(diag, "anchored=" .. tostring(root.Anchored))
                            table.insert(diag, "sit=" .. tostring(humanoid.Sit))
                            table.insert(diag, "platformStand=" .. tostring(humanoid.PlatformStand))
                            table.insert(diag, "walkSpeed=" .. tostring(humanoid.WalkSpeed))
                            table.insert(diag, "state=" .. tostring(humanoid:GetState()))
                        end)
                        self.walkDiag = table.concat(diag, " ")
                        self:releaseAnchor(root, character, "while walking")
                        pcall(function()
                            if humanoid.Sit then
                                humanoid.Sit = false
                            end
                            if humanoid.PlatformStand then
                                humanoid.PlatformStand = false
                            end
                            local dx, dz = target.X - p.X, target.Z - p.Z
                            local length = math.sqrt(dx * dx + dz * dz)
                            if length > 0.1 then
                                humanoid:Move(Vector3.new(dx / length, 0, dz / length), false)
                            end
                        end)
                    elseif still >= 2.5 then
                        break
                    end
                else
                    still = 0
                    self.walkDiag = nil
                end
                last = p
            end
        end
        return done()
    end
    function Interaction:moveTo(spotName)
        local spot = GameConstants.Spots[spotName]
        if not spot then
            error("Interaction: spot is not in the allowlist: " .. tostring(spotName), 2)
        end
        local character = game:GetService("Players").LocalPlayer.Character
        local humanoid = character and character:FindFirstChildOfClass("Humanoid")
        local root = character and character:FindFirstChild("HumanoidRootPart")
        if not humanoid or not root then
            return false, "no character"
        end
        self._sent += 1
        self._state:set("farm.actionsSent", self._sent, "Interaction")
        local waited = 0
        while root.Anchored and waited < 10 do
            task.wait(0.5)
            waited += 0.5
        end
        local target = Vector3.new(spot.x, spot.y, spot.z)
        local function distance()
            local p = root.Position
            return math.sqrt((p.X - spot.x) ^ 2 + (p.Z - spot.z) ^ 2)
        end
        local function walkTo(point, limit)
            humanoid:MoveTo(point)
            local t = 0
            while t < limit do
                task.wait(0.25)
                t += 0.25
                local p = root.Position
                if math.sqrt((p.X - point.X) ^ 2 + (p.Z - point.Z) ^ 2) < 4 then
                    return true
                end
            end
            return false
        end
        self._logger:debug("Action", string.format("Walking to %s (%.0f, %.0f), %.0f studs", spotName, spot.x, spot.z, distance()))
        local waypoints
        pcall(function()
            local path = game:GetService("PathfindingService"):CreatePath({ AgentCanJump = true })
            path:ComputeAsync(root.Position, target)
            if path.Status == Enum.PathStatus.Success then
                waypoints = path:GetWaypoints()
            end
        end)
        local started = os.clock()
        if waypoints then
            for _, waypoint in ipairs(waypoints) do
                if waypoint.Action == Enum.PathWaypointAction.Jump then
                    humanoid.Jump = true
                end
                walkTo(waypoint.Position, 4)
                if os.clock() - started > 90 then
                    break
                end
            end
        else
            self._logger:debug("Action", "No path found: walking straight")
            for _ = 1, 12 do
                if walkTo(target, 8) or distance() < 10 then
                    break
                end
            end
        end
        if distance() < 15 then
            return true
        end
        return false, string.format("could not walk there (still %.0f studs away)", distance())
    end
    local function describeArgs(...)
        local parts = {}
        for index = 1, select("#", ...) do
            local value = select(index, ...)
            if typeof(value) == "Instance" then
                table.insert(parts, "<" .. value.Name .. ">")
            elseif type(value) == "table" then
                table.insert(parts, "{...}")
            else
                table.insert(parts, tostring(value))
            end
        end
        return table.concat(parts, ", ")
    end
    function Interaction:bindData(data, farmConfig)
        self._gameData, self._farmConfig = data, farmConfig
    end
    function Interaction:hasPending()
        return next(self._operations.pending) ~= nil
    end
    function Interaction:_preparePurchase(category, id, options)
        local data, farm = self._gameData, self._farmConfig
        if not data or not data:inventoryKnown(category) then return false, "purchase waits for complete inventory" end
        if category == "food" and id == "water" and not farm.BuyWater then return false, "water purchases disabled" end
        if category == "food" and id == "hotdog" and not farm.BuyFood then return false, "food purchases disabled" end
        local count = type(options) == "table" and options.buy_count or 1
        if type(count) ~= "number" or count ~= count or count < 1 or count % 1 ~= 0 or count > 1000 then
            return false, "invalid purchase quantity (1..1000)"
        end
        local key = tostring(category) .. "|" .. tostring(id)
        local have = #data:itemsOfId(category, id)
        local previous = self._operations.purchases[key]
        if previous and have < previous.before + previous.count then
            return false, "previous purchase unconfirmed; no duplicate purchase sent"
        end
        local record = { before = have, count = count, key = key }
        self._operations.purchases[key] = record
        return true, record
    end
    function Interaction:destroy()
        self._destroyed = true
        if Interaction.disconnectHauntletWatches then Interaction.disconnectHauntletWatches() end
    end
    function Interaction:send(actionName, ...)
        if self._destroyed then return false, "interaction stopped" end
        local action = GameConstants.Actions[actionName]
        if not action then
            error("Interaction: action is not in the allowlist: " .. tostring(actionName), 2)
        end
        if action.emptyOnly then
            local first = ...
            if select("#", ...) ~= 1 or type(first) ~= "table" or next(first) ~= nil then
                error("Interaction: " .. actionName .. " may only be sent with an empty table", 2)
            end
        end
        if action.allowedFirstArg then
            local first = ...
            if not action.allowedFirstArg[first] then
                error("Interaction: " .. actionName .. " may not be sent with " .. tostring(first), 2)
            end
        end
        if action.leaveOnly then
            local first, second = ...
            if select("#", ...) ~= 2 or type(first) ~= "string" or string.sub(first, 1, 15) ~= "ghost_clusters:" or second ~= false then
                error("Interaction: " .. actionName .. " may only be sent as (\"ghost_clusters::<id>\", false)", 2)
            end
        end
        if action.allowedMessages then
            local _, message = ...
            if not action.allowedMessages[message] then
                error("Interaction: " .. actionName .. " may not send message " .. tostring(message), 2)
            end
        end
        if action.recordedArgs then
            -- only the arguments copied from a recorded manual install (GameConstants.Event.SkelicornArgs)
            local recorded = type(GameConstants.Event.SkelicornArgs) == "table" and GameConstants.Event.SkelicornArgs[action.recordedArgs]
            if type(recorded) ~= "table" then
                error("Interaction: " .. actionName .. " has no recorded arguments yet", 2)
            end
            local function match(want, got, depth)
                if want == "$LEVER" then -- the lever's unique id: different for every player
                    return type(got) == "string" and got ~= ""
                end
                if type(want) == "table" and type(got) == "table" and depth < 3 then
                    for k, v in pairs(want) do
                        if not match(v, got[k], depth + 1) then
                            return false
                        end
                    end
                    for k in pairs(got) do
                        if want[k] == nil then
                            return false
                        end
                    end
                    return true
                end
                return want == got
            end
            local n = select("#", ...)
            local same = n == #recorded
            for i = 1, n do
                if not match(recorded[i], (select(i, ...)), 0) then
                    same = false
                end
            end
            if not same then
                error("Interaction: " .. actionName .. " may only be sent with the recorded arguments", 2)
            end
        end
        if action.noArgs and select("#", ...) ~= 0 then
            error("Interaction: " .. actionName .. " is sent without arguments", 2)
        end
        if action.joinPrefix then
            local first, second = ...
            local p = action.joinPrefix
            if type(first) ~= "string" or not (first == p or string.sub(first, 1, #p + 2) == p .. "::") or second ~= true then
                error("Interaction: " .. actionName .. " may only be sent as (\"" .. p .. "[::<id>]\", true)", 2)
            end
        end
        if action.hauntletMessage then
            local sessionId, message, value = ...
            local okSession = type(sessionId) == "string" and string.sub(sessionId, 1, 10) == "hauntlet::"
            local okDoor = message == "try_pick_door" and (value == 1 or value == 2 or value == 3)
            local okItem = message == "try_use_item" and type(value) == "string" and GameConstants.Event.HauntletItems[value] == true
            if select("#", ...) ~= 3 or not okSession or not (okDoor or okItem) then
                error("Interaction: " .. actionName .. " may not send " .. tostring(message) .. " " .. tostring(value), 2)
            end
        end
        local folderName = action.folder and GameConstants.Remotes[action.folder] or GameConstants.Remotes.Folder
        local apiFolder = ReplicatedStorage:FindFirstChild(folderName)
        local remote = apiFolder and apiFolder:FindFirstChild(action.remote)
        if not remote then
            self._logger:error("Action", "Remote not found: " .. action.remote)
            return false, "remote not found"
        end
        if self._operations.pending[actionName] then return false, "previous " .. actionName .. " request still pending" end
        if not (remote:IsA("RemoteFunction") or remote:IsA("RemoteEvent")) then return false, "not a remote" end
        local consumedUnique
        local args = table.pack(...)
        if actionName == "OpenGift" then consumedUnique = args[1]
        elseif actionName == "OpenChest" then consumedUnique = args[2]
        elseif actionName == "CreatePetObject" and type(args[2]) == "table" and self._gameData then
            local item = self._gameData:item(GameConstants.ItemCategory, args[2].unique_id)
            if item and GameConstants.isFarmPotion and GameConstants.isFarmPotion(item.id) then consumedUnique = args[2].unique_id end
        end
        if consumedUnique then
            consumedUnique = tostring(consumedUnique)
            if self._operations.consumptions[consumedUnique] then return false, "previous consumable request unconfirmed; item will not be sent twice" end
            self._operations.consumptions[consumedUnique] = true
        end
        local purchase
        if actionName == "BuyItem" then
            local allowed, record = self:_preparePurchase(...)
            if not allowed then return false, record end
            purchase = record
        end
        self._sent += 1
        self._state:set("farm.actionsSent", self._sent, "Interaction")
        self._logger:debug("Action", "Send " .. action.remote .. "(" .. describeArgs(...) .. ")")
        if remote:IsA("RemoteFunction") then
            local record = { finished = false }
            self._operations.pending[actionName] = record
            local args = table.pack(...)
            record.thread = task.spawn(function()
                record.ok, record.result = pcall(function()
                    return remote:InvokeServer(table.unpack(args, 1, args.n))
                end)
                record.finished = true
                if self._operations.pending[actionName] == record then self._operations.pending[actionName] = nil end
                if record.ok and record.result == false then
                    if purchase then self._operations.purchases[purchase.key] = nil end
                    if consumedUnique then self._operations.consumptions[consumedUnique] = nil end
                end
            end)
            local deadline = Util.now() + (action.answersWhenDone and 2 or INVOKE_TIMEOUT_SECONDS)
            while not record.finished and Util.now() < deadline do task.wait(0.1) end
            if not record.finished then
                if action.answersWhenDone then return true, "pending; completion requires replicated evidence" end
                return false, "server reply pending; request will not be duplicated"
            end
            if not record.ok then return false, tostring(record.result) end
            if record.result == false then return false, "server rejected the request" end
            return true, record.result
        end
        if remote:IsA("RemoteEvent") then
            local ok, err = pcall(function(...)
                remote:FireServer(...)
            end, ...)
            if not ok then
                self._logger:warn("Action", action.remote .. " failed: " .. tostring(err))
                return false, tostring(err)
            end
            return true
        end
        self._logger:error("Action", action.remote .. " is a " .. remote.ClassName .. ", not a remote")
        return false, "not a remote"
    end
    return Interaction
end
__moduleSources["Game/TravelSafety"] = function(...)
    local import = ...
    local Util = import("Core/Util")
    local Players = game:GetService("Players")
    local Safety = {}
    Safety.__index = Safety

    function Safety.placeName(value)
        return type(value) == "string" and string.match(value, "^[^!]+") or nil
    end
    local function characterParts()
        local character = Players.LocalPlayer and Players.LocalPlayer.Character
        local root = character and character:FindFirstChild("HumanoidRootPart")
        local humanoid = character and character:FindFirstChildOfClass("Humanoid")
        if not root or not root.Parent or not humanoid or humanoid.Health <= 0 then return nil end
        return character, root, humanoid
    end
    function Safety.new(logger, state)
        local shared = Util.getSharedEnvironment()
        shared.AdoptMeTravelSupport = shared.AdoptMeTravelSupport or {}
        return setmetatable({ _logger = logger, _state = state, _shared = shared.AdoptMeTravelSupport }, Safety)
    end
    function Safety:sceneRoot(destination)
        if destination == "housing" then return workspace:FindFirstChild("HouseInteriors") end
        local interiors = workspace:FindFirstChild("Interiors")
        if interiors then
            local current = self._state:get("player.interior")
            local exact = type(current) == "string" and interiors:FindFirstChild(current)
            if exact and Safety.placeName(exact.Name) == destination then return exact end
            for _, scene in ipairs(interiors:GetChildren()) do
                if Safety.placeName(scene.Name) == destination then return scene end
            end
        end
        return nil
    end
    function Safety:ground(position, character, depth, rise)
        local ok, hit = pcall(function()
            local params = RaycastParams.new()
            params.FilterType = Enum.RaycastFilterType.Exclude
            local exclude = { character }
            if self._shared.part then table.insert(exclude, self._shared.part) end
            for _, player in ipairs(Players:GetPlayers()) do
                if player.Character and player.Character ~= character then table.insert(exclude, player.Character) end
            end
            local pets = workspace:FindFirstChild("Pets")
            if pets then table.insert(exclude, pets) end
            params.FilterDescendantsInstances = exclude
            params.RespectCanCollide = true
            params.IgnoreWater = true
            local _, root = characterParts()
            if root then params.CollisionGroup = root.CollisionGroup end
            return workspace:Raycast(position + Vector3.new(0, rise or 0, 0), Vector3.new(0, -(depth or 12), 0), params)
        end)
        if not ok then return nil, "ground probe unavailable" end
        if hit and hit.Normal.Y >= 0.5 then return hit end
        return nil, "solid floor not loaded"
    end
    function Safety:ready(destination)
        local character, root = characterParts()
        if not root or root.Anchored then return false end
        if Safety.placeName(self._state:get("player.interior")) ~= destination then return false end
        local scene = self:sceneRoot(destination)
        if not scene then return false end
        local hit = self:ground(root.Position, character, 9)
        if not hit then return false end
        if hit.Instance:IsDescendantOf(scene) then return true end
        -- Terrain is global; also require the outdoor scene and its observed coordinate area.
        if hit.Instance:IsA("Terrain") and destination == "MainMap" then
            return root.Position.Y > -30 and root.Position.Y < 600
                and root.Position.X > -1500 and root.Position.X < 1000 and root.Position.Z > -3000 and root.Position.Z < 0
        end
        return false
    end
    local function clearance(root, humanoid)
        return math.clamp((tonumber(humanoid.HipHeight) or 2) + root.Size.Y / 2, 2, 6) + 0.15
    end
    function Safety:_support(position, root, humanoid)
        local part = self._shared.part
        if not part or not part.Parent then
            part = Instance.new("Part")
            part.Name = "AdoptMe_LocalTravelSupport"
            part.Anchored = true
            part.Size = Vector3.new(18, 1, 18)
            part.Transparency = 0.65
            part.CanCollide = true
            part.CanTouch = false
            part:SetAttribute("AdoptMeLocalTravelSupport", true)
            self._shared.part = part
        end
        part.CollisionGroup = root.CollisionGroup
        part.CFrame = CFrame.new(position - Vector3.new(0, clearance(root, humanoid) + 0.5, 0))
        part.Parent = workspace
    end
    function Safety:_removeSupportIfSafe()
        local part = self._shared.part
        if not part then return end
        local character, root = characterParts()
        local movedAway = root and (math.abs(root.Position.X - part.Position.X) > 12
            or math.abs(root.Position.Z - part.Position.Z) > 12 or math.abs(root.Position.Y - part.Position.Y) > 20)
        if not root or movedAway or self:ground(root.Position, character, 9) then
            part:Destroy()
            self._shared.part = nil
        end
        -- With no real floor, retain ONE static support rather than drop the player on pause.
        -- It is reused/removed by the next trip. No loop, anchor or connection is retained.
    end
    function Safety:requestStream(position, seconds)
        if self._streamThread then pcall(task.cancel, self._streamThread) end
        self._streamThread = task.spawn(function()
            pcall(function() Players.LocalPlayer:RequestStreamAroundAsync(position, seconds or 8) end)
        end)
    end
    local function placeRoot(character, root, position)
        character:PivotTo(character:GetPivot() + (position - root.Position))
        root.AssemblyLinearVelocity = Vector3.zero
        root.AssemblyAngularVelocity = Vector3.zero
    end
    function Safety:begin(seconds)
        self:cancel()
        local character, root, humanoid = characterParts()
        if not root then return nil, "character unavailable" end
        local job = { character = character, root = root, humanoid = humanoid,
            position = root.Position, heldY = root.Position.Y, deadline = Util.now() + (seconds or 30) }
        self._job = job
        self:_support(root.Position, root, humanoid)
        self._watch = task.spawn(function()
            while self._job == job and Util.now() < job.deadline do
                if Players.LocalPlayer.Character ~= character or not root.Parent or humanoid.Health <= 0 then break end
                local p = root.Position
                local delta = p - job.position
                if Vector3.new(delta.X, 0, delta.Z).Magnitude > 30 or math.abs(delta.Y) > 45 then
                    -- A game door changed coordinate spaces. Support the NEW space, never snap back to the old one.
                    job.heldY = p.Y
                    self:requestStream(p, 8)
                end
                if self:ground(p, character, 9) then
                    job.heldY = p.Y
                elseif not root.Anchored then
                    local hold = Vector3.new(p.X, job.heldY, p.Z)
                    self:_support(hold, root, humanoid)
                    if p.Y < job.heldY - 1 then placeRoot(character, root, hold) end
                end
                job.position = root.Position
                task.wait(0.05)
            end
            if self._job == job then self._job = nil; self:_removeSupportIfSafe() end
        end)
        return job
    end
    function Safety:cancel()
        self._job = nil
        if self._watch then pcall(task.cancel, self._watch); self._watch = nil end
        if self._streamThread then pcall(task.cancel, self._streamThread); self._streamThread = nil end
        self:_removeSupportIfSafe()
    end
    function Safety:move(position, destination, seconds)
        if not self:ready(destination) then return false, "destination scene and solid floor are not confirmed: " .. tostring(destination) end
        local character, root, humanoid = characterParts()
        local origin = root.Position
        local job, reason = self:begin((seconds or 16) + 3)
        if not job then return false, reason end
        local function rollback()
            if self._job ~= job or Players.LocalPlayer.Character ~= character then return end
            if Safety.placeName(self._state:get("player.interior")) == destination and self:ground(origin, character, 9) then
                self:_support(origin, root, humanoid)
                placeRoot(character, root, origin)
            end
        end
        self:requestStream(position, seconds or 16)
        -- Stream prefetch can return before collision exists. The support must exist BEFORE PivotTo.
        local hit = self:ground(position, character, 32, 5)
        local target = Vector3.new(position.X, hit and hit.Position.Y + clearance(root, humanoid) or position.Y, position.Z)
        self:_support(target, root, humanoid)
        job.heldY, job.position = target.Y, target
        local moved, moveError = pcall(placeRoot, character, root, target)
        if not moved then rollback(); self:cancel(); return false, tostring(moveError) end
        local stableSince
        local deadline = Util.now() + (seconds or 16)
        while self._job == job and Util.now() < deadline do
            if Players.LocalPlayer.Character ~= character or not root.Parent or humanoid.Health <= 0 then
                self:cancel(); return false, "character changed during travel"
            end
            if Safety.placeName(self._state:get("player.interior")) ~= destination then
                self:cancel(); return false, "scene changed during movement"
            end
            local near = (Vector3.new(root.Position.X, 0, root.Position.Z) - Vector3.new(target.X, 0, target.Z)).Magnitude < 12
            local floor = self:ground(target, character, 32, 5)
            if near and floor and not root.Anchored then
                local landed = Vector3.new(target.X, floor.Position.Y + clearance(root, humanoid), target.Z)
                if math.abs(root.Position.Y - landed.Y) > 1 then
                    self:_support(landed, root, humanoid)
                    job.heldY, job.position = landed.Y, landed
                    placeRoot(character, root, landed)
                end
                if self:ready(destination) then
                    stableSince = stableSince or Util.now()
                    if Util.now() - stableSince >= 0.75 then self:cancel(); return true end
                else stableSince = nil end
            else stableSince = nil end
            task.wait(0.1)
        end
        if self._job == job then rollback(); self:cancel() end
        return false, "solid destination floor did not load, movement cancelled"
    end
    return Safety
end

__moduleSources["Game/Travel"] = function(...)
    local import = ...
    local Util = import("Core/Util")
    local GameConstants = import("Game/GameConstants")
    local Safety = import("Game/TravelSafety")
    local Players = game:GetService("Players")
    local Travel = {}
    Travel.__index = Travel
    local ARRIVAL_TIMEOUT = 22

    function Travel.new(logger, state, interaction, farmConfig)
        local safety = interaction._travelSafety or Safety.new(logger, state)
        interaction._travelSafety = safety
        return setmetatable({ _logger = logger, _state = state, _interaction = interaction,
            _farmConfig = farmConfig or {}, _safety = safety, _generation = 0 }, Travel)
    end
    function Travel:canGoTo(destination)
        return destination == "Neighborhood" or GameConstants.Travel[destination] ~= nil
    end
    function Travel:isAt(destination)
        local place = self._state:get("player.interior")
        local event = GameConstants.Event
        if destination == event.MinigameInteriorPrefix or destination == event.HauntletInteriorPrefix then
            return type(place) == "string" and string.sub(place, 1, #destination) == destination
        end
        return Safety.placeName(place) == destination
    end
    function Travel:_waitArrival(destination, seconds)
        local generation = self._generation
        local deadline, stableSince = Util.now() + seconds, nil
        while generation == self._generation and Util.now() < deadline do
            local enterDone = not self._enterThread or coroutine.status(self._enterThread) == "dead"
            if enterDone and self._safety:ready(destination) then
                stableSince = stableSince or Util.now()
                if Util.now() - stableSince >= 0.75 then return true end
            else stableSince = nil end
            task.wait(0.1)
        end
        return false
    end
    function Travel:_waitPlacedOnMainMap(seconds)
        return self:_waitArrival("MainMap", seconds)
    end
    function Travel:cancelPending()
        self._generation += 1
        if self._enterThread then pcall(task.cancel, self._enterThread); self._enterThread = nil end
        if self._moduleThread then pcall(task.cancel, self._moduleThread); self._moduleThread = nil end
        self._safety:cancel()
        self._busy = nil
    end
    function Travel:_interiorsModule()
        if self._interiorsM then return self._interiorsM end
        local node = game:GetService("ReplicatedStorage")
        for _, name in ipairs({ "ClientModules", "Core", "InteriorsM", "InteriorsM" }) do
            node = node and node:FindFirstChild(name)
        end
        if not node then return nil end
        local done, result = false, nil
        local moduleThread = task.spawn(function()
            local ok, value = pcall(require, node)
            if ok and type(value) == "table" and type(value.enter) == "function" then result = value end
            done = true
        end)
        self._moduleThread = moduleThread
        local generation, deadline = self._generation, Util.now() + 4
        while not done and generation == self._generation and Util.now() < deadline do task.wait(0.1) end
        if self._moduleThread == moduleThread then pcall(task.cancel, moduleThread); self._moduleThread = nil end
        if generation ~= self._generation then return nil end
        self._interiorsM = result
        return result
    end
    local function valueUnder(parent, key)
        for _, child in ipairs(parent:GetDescendants()) do
            if child.Name == key and child:IsA("StringValue") then return child.Value end
            local value = child:GetAttribute(key)
            if type(value) == "string" then return value end
        end
        return parent:GetAttribute(key)
    end
    function Travel:_findDoor(destination)
        local scene = self._safety:sceneRoot(Safety.placeName(self._state:get("player.interior")))
        local doors = scene and scene:FindFirstChild("Doors")
        if not doors then return nil end
        local candidates = {}
        for _, part in ipairs(doors:GetDescendants()) do
            if part.Name == "TouchToEnter" and part:IsA("BasePart") then
                local working = part.Parent
                local place = valueUnder(working, "destination_id")
                local doorId = valueUnder(working, "destination_door_id")
                if place == destination and type(doorId) == "string" and doorId ~= "" then
                    table.insert(candidates, { part = part, model = working.Parent, destination = place, doorId = doorId })
                end
            end
        end
        table.sort(candidates, function(a, b)
            if a.doorId == b.doorId then return a.part:GetFullName() < b.part:GetFullName() end
            if a.doorId == "MainDoor" then return true end
            if b.doorId == "MainDoor" then return false end
            return a.doorId < b.doorId
        end)
        return candidates[1]
    end
    function Travel:_waitDoor(destination)
        local deadline, generation = Util.now() + 8, self._generation
        local current = Safety.placeName(self._state:get("player.interior"))
        local hints = GameConstants.TravelStreamHints and GameConstants.TravelStreamHints[current]
        local asked = false
        repeat
            local door = self:_findDoor(destination)
            if door then return door end
            if generation ~= self._generation then return nil end
            if not asked and hints and hints[destination] then
                asked = true
                self._safety:requestStream(hints[destination], 7)
            end
            task.wait(0.25)
        until Util.now() >= deadline
        return nil
    end
    function Travel:_enter(destination, doorId, options, generation)
        if self._farmConfig.GameTravel == false then return false, "game travel disabled; door touch did not confirm arrival" end
        local module = self:_interiorsModule()
        if generation ~= self._generation then return false, "travel cancelled" end
        if not module then return false, "InteriorsM unavailable; no direct SetLocation fallback" end
        local enterError
        local enterThread = task.spawn(function()
            local ok, result = pcall(module.enter, destination, doorId, options or {})
            if not ok or result == false then enterError = tostring(result) end
        end)
        self._enterThread = enterThread
        local arrived = self:_waitArrival(destination == "exit_housing" and "Neighborhood" or destination, ARRIVAL_TIMEOUT)
        if self._enterThread == enterThread then pcall(task.cancel, enterThread); self._enterThread = nil end
        if not arrived then return false, enterError or "door arrival / solid floor unconfirmed" end
        return true
    end
    function Travel:_crossDoor(door, destination, options)
        local generation = self._generation
        if not door or not door.part or not door.part.Parent then return false, "live entrance not found: " .. destination end
        local from = Safety.placeName(self._state:get("player.interior"))
        if not self._safety:ready(from) then return false, "current scene has no confirmed floor" end
        local character = Players.LocalPlayer.Character
        local root = character and character:FindFirstChild("HumanoidRootPart")
        local humanoid = character and character:FindFirstChildOfClass("Humanoid")
        if not root or not humanoid then return false, "character unavailable" end
        local direction = door.part.CFrame.LookVector * Vector3.new(1, 0, 1)
        direction = direction.Magnitude > 0.1 and direction.Unit or Vector3.new(0, 0, 1)
        if (root.Position - door.part.Position):Dot(direction) < 0 then direction = direction * -1 end
        local goal = door.part.Position + direction * 6 + Vector3.new(0, 2, 0)
        self._logger:info("Travel", "Approaching " .. from .. " door -> " .. destination .. " (" .. door.doorId .. ")")
        local moved, reason = self._safety:move(goal, from, 12)
        if generation ~= self._generation then return false, "travel cancelled" end
        -- Some triggers extend beyond the visible door and can fire during the approach.
        if not self:isAt(from) then
            self._safety:begin(ARRIVAL_TIMEOUT + 3)
            return self:_waitArrival(destination, ARRIVAL_TIMEOUT), "door transition floor unconfirmed"
        end
        if not moved then return false, "door approach: " .. tostring(reason) end
        local support, supportWhy = self._safety:begin(ARRIVAL_TIMEOUT + 8)
        if not support then return false, supportWhy end
        humanoid:MoveTo(door.part.Position)
        local touchUntil = Util.now() + 2
        while generation == self._generation and Util.now() < touchUntil and self:isAt(from) do task.wait(0.1) end
        if generation ~= self._generation then return false, "travel cancelled" end
        if not self:isAt(from) or root.Anchored or not self._safety:ready(from) then
            -- Never send a second request while the normal door is already transitioning.
            return self:_waitArrival(destination, ARRIVAL_TIMEOUT), "door transition did not settle on solid ground"
        end
        if Players.LocalPlayer.Character ~= character then return false, "character changed at the door" end
        if (root.Position - door.part.Position).Magnitude > 18 then return false, "did not reach the entrance" end
        return self:_enter(door.destination, door.doorId, options, generation)
    end
    function Travel:_houseDoor()
        local me = Players.LocalPlayer
        local interiors = workspace:FindFirstChild("HouseInteriors")
        local blueprint = interiors and interiors:FindFirstChild("blueprint")
        local character = me.Character
        local root = character and character:FindFirstChild("HumanoidRootPart")
        local best, distance
        -- House interiors are dynamic; choose the nearest loaded main door, including a visited house.
        for _, house in ipairs(blueprint and blueprint:GetChildren() or {}) do
            local doors = house:FindFirstChild("Doors")
            local model = doors and doors:FindFirstChild("MainDoor")
            for _, part in ipairs(model and model:GetDescendants() or {}) do
                if root and part.Name == "TouchToEnter" and part:IsA("BasePart") then
                    local d = (root.Position - part.Position).Magnitude
                    if not distance or d < distance then
                        local owner = house.Name == me.Name and me or Players:FindFirstChild(house.Name)
                        best, distance = { part = part, model = model, destination = "exit_housing", doorId = "MainDoor",
                            owner = owner, ownerName = house.Name }, d
                    end
                end
            end
        end
        return best
    end
    function Travel:_exitHouse()
        if not self:isAt("housing") then return false, "not inside a house" end
        local best = self:_houseDoor()
        if not best then return false, "house MainDoor/TouchToEnter is not loaded" end
        return self:_crossDoor(best, "Neighborhood", { house_owner = best.owner, exiting_door = best.model })
    end
    function Travel:_toMainMap()
        if self:isAt("housing") then
            local ok, why = self:_exitHouse()
            if not ok then return false, why end
        end
        if self:isAt("MainMap") then return self:_waitArrival("MainMap", 8), "main city floor not ready" end
        local door = self:_waitDoor("MainMap")
        return self:_crossDoor(door, "MainMap")
    end
    function Travel:_toNeighborhood()
        if self:isAt("housing") then return self:_exitHouse() end
        if self:isAt("Neighborhood") then return self:_waitArrival("Neighborhood", 8), "neighborhood floor not ready" end
        local ok, why = self:_toMainMap()
        if not ok then return false, why end
        return self:_crossDoor(self:_waitDoor("Neighborhood"), "Neighborhood")
    end
    function Travel:_home(owner)
        local ok, reason = self:_toNeighborhood()
        if not ok then return false, reason end
        local generation = self._generation
        local support, why = self._safety:begin(ARRIVAL_TIMEOUT + 8)
        if not support then return false, why end
        -- Existing game house-entry API: preserves the current character and equipped pets.
        -- The supplied neighborhood save has no dynamic house exteriors; never invent plot coordinates.
        self._logger:info("Travel", "Entering " .. owner.Name .. "'s house from Neighborhood (no respawn)")
        return self:_enter("housing", "MainDoor", { house_owner = owner }, generation)
    end
    function Travel:_route(destination, owner)
        if not self:canGoTo(destination) then return false, "no known route to " .. tostring(destination) end
        if self:isAt(destination) and not owner then
            local house = destination == "housing" and self:_houseDoor()
            if destination ~= "housing" or house and house.ownerName == Players.LocalPlayer.Name then
                return self:_waitArrival(destination, 8), "current destination floor not ready"
            end
        end
        if destination == "housing" then return self:_home(owner or Players.LocalPlayer) end
        if destination == "Neighborhood" then return self:_toNeighborhood() end
        local ok, reason = self:_toMainMap()
        if not ok or destination == "MainMap" then return ok, reason end
        return self:_crossDoor(self:_waitDoor(destination), destination)
    end
    function Travel:_run(destination, owner)
        if self._busy then return false, "another trip is already running" end
        self._busy = true
        local generation = self._generation
        local ok, result, reason = pcall(self._route, self, destination, owner)
        if generation == self._generation then
            self._safety:cancel()
            if self._enterThread then pcall(task.cancel, self._enterThread); self._enterThread = nil end
            self._busy = nil
        end
        if not ok then return false, tostring(result) end
        return result, reason
    end
    function Travel:goTo(destination) return self:_run(destination) end
    function Travel:exitToMainMap() return self:_run("MainMap") end
    function Travel:exitHouse() return self:_run("Neighborhood") end
    function Travel:visitHouse(player)
        if not player or not player.Parent then return false, "house owner unavailable" end
        return self:_run("housing", player)
    end
    return Travel
end
__moduleSources["Game/Furniture"] = function(...)
    local import = ...
    local GameConstants = import("Game/GameConstants")
    local Players = game:GetService("Players")
    local Furniture = {}
    Furniture.__index = Furniture
    function Furniture.new(gameData, state)
        return setmetatable({ _gameData = gameData, _state = state }, Furniture)
    end
    function Furniture:_keysOfKinds(kinds)
        local wanted = {}
        for _, kind in ipairs(kinds) do
            wanted[kind] = #kinds + 1
        end
        for index, kind in ipairs(kinds) do wanted[kind] = index end
        local interior = self._gameData:get(GameConstants.DataKeys.Interior)
        local keys = {}
        if type(interior) ~= "table" or type(interior.furniture) ~= "table" then
            return keys
        end
        for key, piece in pairs(interior.furniture) do
            if type(piece) == "table" and wanted[piece.id] then
                table.insert(keys, { key = tostring(key), kind = piece.id })
            end
        end
        table.sort(keys, function(a, b)
            if wanted[a.kind] ~= wanted[b.kind] then return wanted[a.kind] < wanted[b.kind] end
            return a.key < b.key
        end)
        return keys
    end
    function Furniture:_findModel(key)
        local folder = workspace
        for _, name in ipairs(GameConstants.HouseFurnitureFolderPath) do
            folder = folder and folder:FindFirstChild(name)
        end
        if not folder then
            return nil
        end
        local myPrefix = Players.LocalPlayer.Name .. "/"
        local suffix = "/" .. key
        for _, holder in ipairs(folder:GetChildren()) do
            local name = holder.Name
            if string.sub(name, 1, #myPrefix) == myPrefix and string.sub(name, -#suffix) == suffix then
                for _, child in ipairs(holder:GetChildren()) do
                    if child:IsA("Model") and tostring(child:GetAttribute(GameConstants.FurnitureUniqueAttribute)) == tostring(key) then
                        return child
                    end
                end
            end
        end
        return nil
    end
    function Furniture.useCFrame(usePart)
        return usePart.CFrame * CFrame.new(0, usePart.Size.Y / 2, 0)
    end
    function Furniture:findSpot(kinds)
        if self._state:get("player.interior") ~= GameConstants.HouseInteriorName then
            return nil, "not at home"
        end
        local candidates = self:_keysOfKinds(kinds)
        if #candidates == 0 then
            return nil, "no " .. table.concat(kinds, "/") .. " in your house"
        end
        for _, candidate in ipairs(candidates) do
            local model = self:_findModel(candidate.key)
            local useName = GameConstants.UseBlockForFurniture[candidate.kind]
            local useBlocks = model and model:FindFirstChild("UseBlocks")
            local usePart = useBlocks and useName and useBlocks:FindFirstChild(useName)
            if usePart and usePart:IsA("BasePart") and not ((usePart:IsA("Seat") or usePart:IsA("VehicleSeat")) and usePart.Occupant) then
                return {
                    key = candidate.key,
                    kind = candidate.kind,
                    useName = useName,
                    cframe = Furniture.useCFrame(usePart),
                }
            end
        end
        return nil, table.concat(kinds, "/") .. " model not loaded yet"
    end
    return Furniture
end
__moduleSources["Game/NeedSession"] = function(...)
    local NeedSession = {}
    NeedSession.__index = NeedSession
    function NeedSession.key(entry)
        return tostring(entry.kind) .. "|" .. tostring(entry.owner) .. "|" .. tostring(entry.petUnique)
    end
    function NeedSession.new(entries, startedAt)
        local self = setmetatable({ entries = {}, byKey = {}, missingAt = {}, startedAt = startedAt,
            resolved = {}, progress = {}, revisions = {}, states = {}, episodeChanged = {} }, NeedSession)
        for _, original in ipairs(entries or {}) do
            local entry = table.clone(original)
            local key = NeedSession.key(entry)
            if not self.byKey[key] then
                self.byKey[key] = entry
                self.states[key] = "pending"
                self.progress[key] = (entry.progress or 0) > 0
                table.insert(self.entries, entry)
            end
        end
        return self
    end
    function NeedSession:setPhase(entry, phase)
        local key = NeedSession.key(entry)
        if not self.resolved[key] then self.states[key] = phase end
    end
    function NeedSession:observe(entry, current, completedAt, known, eligible, now, revision)
        local key = NeedSession.key(entry)
        if self.resolved[key] then return true, self.resolved[key] end
        if completedAt and completedAt >= self.startedAt then
            self.resolved[key], self.states[key] = "completion event", "completed"
            return true, self.resolved[key]
        end
        if known ~= true or eligible ~= true then
            self.missingAt[key], self.revisions[key] = nil, nil
            return false, known ~= true and "waiting for need data" or "participant unavailable"
        end
        if current then
            self.missingAt[key], self.revisions[key] = nil, nil
            if entry.createdAt and current.createdAt and entry.createdAt ~= current.createdAt then
                self.episodeChanged[key] = true
                return false, "need episode changed without a completion event"
            end
            self.progress[key] = self.progress[key] or (current.progress or 0) > (entry.progress or 0)
            return false, current.inProgress and "in progress" or "waiting to start"
        end
        -- One cached empty list, rate > 0, travel or equipment loss is not completion.
        if self.episodeChanged[key] or not self.progress[key] or revision == nil then return false, "no completion evidence" end
        if not self.missingAt[key] then
            self.missingAt[key], self.revisions[key] = now, revision
        elseif now - self.missingAt[key] >= 2 and revision ~= self.revisions[key] then
            self.resolved[key], self.states[key] = "progress followed by replicated removal", "completed"
            return true, self.resolved[key]
        end
        return false, "verifying removal"
    end
    function NeedSession.single(entry)
        return { kind = entry.kind, entries = { entry }, petEntry = entry.owner == "pet" and entry or nil,
            anyInProgress = entry.inProgress == true, maxRate = entry.rate or 0, oldest = entry.createdAt or math.huge }
    end
    function NeedSession.timeout(definition, count)
        local base = math.max(10, tonumber(definition.timeoutSeconds) or 90)
        if definition.id == "location" then return math.max(base, 240) end
        return math.min(900, base * math.max(1, count) + 20)
    end
    return NeedSession
end
__moduleSources["Game/Tasks"] = function(...)
    local import = ...
    local Maid = import("Core/Maid")
    local NeedSession = import("Game/NeedSession")
    local GameConstants = import("Game/GameConstants")
    local Util = import("Core/Util")
    local ensurePetModel
    local Players = game:GetService("Players")
    local Tasks = {}
    local function standUp(ctx)
        if not ctx.gameData or not ctx.gameData:isSitting() then
            return true
        end
        ctx.logger:info("Tasks", "Your character is sitting: getting up first")
        ctx.interaction:send("ExitSeatStates")
        if ctx.waitUntil(function()
            return not ctx.gameData:isSitting()
        end, 4) then
            return true
        end
        return false, "your character is still sitting (ExitSeatStates had no effect)"
    end
    Tasks.standUp = standUp
    local function petOffFurniture(ctx, petUnique)
        local pid = ctx.petLocator:getStreamingId(petUnique)
        local interior = ctx.gameData and ctx.gameData:get(GameConstants.DataKeys.Interior)
        if not pid or type(interior) ~= "table" or type(interior.furniture) ~= "table" then
            return true
        end
        local function isOn()
            local now = ctx.gameData:get(GameConstants.DataKeys.Interior)
            for _, piece in pairs(type(now) == "table" and type(now.furniture) == "table" and now.furniture or {}) do
                if type(piece) == "table" and type(piece.occupied) == "table" then
                    for _, who in pairs(piece.occupied) do
                        if who == pid then
                            return true
                        end
                    end
                end
            end
            return false
        end
        if not isOn() then
            return true
        end
        ctx.logger:info("Tasks", "Your pet is still on furniture: getting it off first")
        ctx.interaction:send("ExitFurnitureUseStates", petUnique)
        if ctx.waitUntil(function()
            return not isOn()
        end, 4) then
            return true
        end
        return false, "pet is still on furniture (ExitFurnitureUseStates had no effect)"
    end
    Tasks.petOffFurniture = petOffFurniture
    local function occupants(ctx, key)
        local interior = ctx.gameData and ctx.gameData:get(GameConstants.DataKeys.Interior)
        local piece = type(interior) == "table" and type(interior.furniture) == "table" and interior.furniture[key]
        local list = {}
        if type(piece) == "table" and type(piece.occupied) == "table" then
            for _, who in pairs(piece.occupied) do
                table.insert(list, tostring(who))
            end
        end
        return list
    end
    Tasks.pet_me = {
        id = "pet_me",
        handles = function(kind)
            return kind == "pet_me"
        end,
        timeoutSeconds = 40,
        run = function(ctx, group, attempt)
            local petEntry = group.petEntry
            if not petEntry then
                return false, "pet_me is only for pets"
            end
            local model, reason = ensurePetModel(ctx, petEntry.petUnique)
            if not model then
                return false, "pet model: " .. tostring(reason)
            end
            local off, offReason = petOffFurniture(ctx, petEntry.petUnique)
            if not off then
                return false, offReason
            end
            local ok, sendReason = ctx.interaction:send("FocusPet", model)
            if not ok then
                return false, "focus failed: " .. tostring(sendReason)
            end
            ctx.maid:Give(function()
                ctx.interaction:send("UnfocusPet", model)
            end)
            local function completed()
                return ctx.completedSince("pet_me", "pet", petEntry.petUnique)
            end
            if ctx.waitUntil(completed, 3.3) then
                return true
            end
            ctx.interaction:send("PetPerformance", model, { FocusPet = true, Petting = true })
            if ctx.waitUntil(completed, 3.5) then
                return true
            end
            ctx.interaction:send("PetPerformance", model, { FocusPet = true, PettingHappy = true })
            if ctx.waitUntil(completed, 1.2) then
                return true
            end
            ctx.interaction:send("PetPerformance", model, { FocusPet = true })
            ctx.interaction:send("PetPetted", petEntry.petUnique, Players.LocalPlayer)
            ctx.interaction:send("ProgressPetMe", petEntry.petUnique)
            if ctx.waitUntil(function()
                return ctx.completedSince("pet_me", "pet", petEntry.petUnique)
            end, 6) then
                return true
            end
            return false, "no completion after petting"
        end,
    }
    local LOCATION_START_SECONDS = 10
    local LOCATION_EXTRA_SECONDS = 20
    local SPOT_WAIT_BEFORE_MOVE_SECONDS = 6
    local NEAR_SPOT_STUDS = 20
    local function nearSpot(spotName, studs)
        local spot = GameConstants.Spots[spotName]
        local character = Players.LocalPlayer.Character
        local root = character and character:FindFirstChild("HumanoidRootPart")
        if not spot or not root or not root.Position then
            return false
        end
        local p = root.Position
        return math.sqrt((p.X - spot.x) ^ 2 + (p.Z - spot.z) ^ 2) <= studs
    end
    Tasks._nearSpot = nearSpot
    local isOnMainMapArea = GameConstants.isOnMainMapArea
    Tasks._isOnMainMapArea = isOnMainMapArea
    local function waitForCharacter(ctx, seconds)
        return ctx.waitUntil(function()
            local character = Players.LocalPlayer.Character
            local root = character and character:FindFirstChild("HumanoidRootPart")
            return root ~= nil
        end, seconds)
    end
    local function equipPetAgain(ctx, unique)
        if not unique then
            return false, "no pet known"
        end
        if ctx.gameData and ctx.gameData:isPetEquipped(unique) then
            local ready = ctx.waitUntil(function() return ctx.petLocator:findModel(unique) ~= nil end, 10)
            if ready then return true end
            return false, "equipped pet model has not streamed in"
        end
        if not waitForCharacter(ctx, 10) then
            return false, "no character"
        end
        task.wait(2)
        local sent, reason = ctx.interaction:send("EquipItem", unique, { equip_as_last = true })
        if not sent then
            return false, "Equip failed: " .. tostring(reason)
        end
        local function equipped()
            local count = ctx.gameData:equippedPetCount()
            return ctx.gameData:isPetEquipped(unique) and count > 0
        end
        if ctx.waitUntil(equipped, 8) then
            task.wait(1)
            if equipped() then
                return true
            end
            return false, "the pet was equipped, then gone again"
        end
        return false, "the pet did not appear as equipped"
    end
    Tasks._equipPetAgain = equipPetAgain
    ensurePetModel = function(ctx, unique)
        local model, reason = ctx.petLocator:findModel(unique)
        if model then
            return model
        end
        if ctx.gameData and not ctx.gameData:isPetEquipped(unique) then
            ctx.waitUntil(function()
                return ctx.gameData:isPetEquipped(unique)
            end, 4)
            if not ctx.gameData:isPetEquipped(unique) then
                ctx.logger:info("Tasks", "Pet not equipped after the trip: equipping it before using it")
                equipPetAgain(ctx, unique)
            end
        end
        ctx.waitUntil(function()
            model, reason = ctx.petLocator:findModel(unique)
            return model ~= nil
        end, 10)
        return model, reason
    end
    local function petDroppedDuringTask(ctx, group)
        if not ctx.gameData then return false end
        local count, known = ctx.gameData:equippedPetCount()
        if not known then return false end
        for _, entry in ipairs(group.entries or {}) do
            if entry.owner == "pet" and not ctx.gameData:isPetEquipped(entry.petUnique) then return true end
        end
        return false
    end
    Tasks.location = {
        id = "location",
        handles = function(kind)
            return GameConstants.LocationForAilment[kind] ~= nil
        end,
        timeoutSeconds = 180,
        run = function(ctx, group, attempt)
            local destination = GameConstants.LocationForAilment[group.kind]
            local stoodUp, standReason = standUp(ctx)
            if not stoodUp then
                return false, standReason
            end
            if not group.anyInProgress then
                local ok, reason = ctx.travel:goTo(destination)
                if not ok then
                    return false, "travel: " .. tostring(reason)
                end
                local spotName = GameConstants.SpotForAilment[group.kind]
                local door = spotName and ctx.farmConfig.SpotTravel == "door" and GameConstants.SpotDoor[spotName] or nil
                local useTeleport = spotName and ctx.farmConfig.SpotTravel == "teleport"
                if spotName then
                    local function startedHere()
                        local current = ctx.currentGroup(group.kind)
                        return current == nil or current.anyInProgress
                    end
                    if ctx.waitUntil(startedHere, SPOT_WAIT_BEFORE_MOVE_SECONDS) then
                        ctx.logger:info("Tasks", group.kind .. " started where I am: not moving")
                        useTeleport, door = false, nil
                    end
                end
                if useTeleport and nearSpot(spotName, NEAR_SPOT_STUDS) then
                    ctx.logger:info("Tasks", "Already at the " .. spotName .. " spot: no teleport")
                    useTeleport, door = false, nil
                end
                if useTeleport then
                    task.wait(1)
                    local moved, moveReason = ctx.interaction:teleportTo(spotName)
                    ctx.logger:info("Tasks", "Teleport to " .. spotName .. ": " .. (moved and "ok" or tostring(moveReason)))
                    if not moved then return false, "destination movement: " .. tostring(moveReason) end
                    if moved then
                        door = nil
                        if group.petEntry and ctx.waitUntil(function()
                            local current = ctx.currentGroup(group.kind)
                            return petDroppedDuringTask(ctx, group) or (current ~= nil and current.anyInProgress)
                        end, 8) and petDroppedDuringTask(ctx, group) then
                            ctx.logger:info("Tasks", "Pet unequipped after the teleport (map not loaded): equipping it and teleporting again")
                            for _, entry in ipairs(group.entries or {}) do
                                if entry.owner == "pet" and not ctx.gameData:isPetEquipped(entry.petUnique) then
                                    equipPetAgain(ctx, entry.petUnique)
                                end
                            end
                            moved, moveReason = ctx.interaction:teleportTo(spotName)
                            ctx.logger:info("Tasks", "Teleport again to " .. spotName .. ": " .. (moved and "ok" or tostring(moveReason)))
                        end
                    end
                end
                if door then
                    local inOk, inReason = ctx.travel:goTo(door.place)
                    if not inOk then return false, "door route: " .. tostring(inReason) end
                    if inOk then
                        task.wait(1)
                        local outOk, outReason = ctx.travel:exitToMainMap()
                        if not outOk then
                            ok, reason = ctx.travel:goTo(destination)
                            if not ok then
                                return false, "travel after " .. tostring(outReason) .. ": " .. tostring(reason)
                            end
                        end
                    end
                    local character = Players.LocalPlayer.Character
                    local root = character and character:FindFirstChild("HumanoidRootPart")
                    if root then
                        local p = root.Position
                        local near = math.sqrt((p.X - door.exit.x) ^ 2 + (p.Z - door.exit.z) ^ 2) < 60
                        ctx.logger:info("Tasks", string.format("After the %s door: at (%.0f, %.0f), %s", door.place, p.X, p.Z,
                            near and "at the door" or "NOT at the door"))
                        if not isOnMainMapArea(p) then
                            ctx.logger:warn("Tasks", string.format("After the %s door I am OUTSIDE MainMap (%.0f, %.0f): the"
                                .. " game did not place me (white-screen state)", door.place, p.X, p.Z))
                            return false, "the door exit left me outside MainMap"
                        end
                    end
                end
                local function hasStarted()
                    local current = ctx.currentGroup(group.kind)
                    return current == nil or current.anyInProgress
                end
                local talk = GameConstants.InteriorTalkForAilment[group.kind]
                local started
                if talk then
                    started = ctx.waitUntil(hasStarted, 4)
                    if not started then
                        local interior = ctx.gameData:get(GameConstants.DataKeys.Interior)
                        local key
                        for furnitureKey, piece in pairs(type(interior) == "table" and type(interior.furniture) == "table"
                            and interior.furniture or {}) do
                            if type(piece) == "table" and piece.id == talk.furniture then
                                key = furnitureKey
                            end
                        end
                        if key then
                            ctx.logger:info("Tasks", "Talking to the " .. talk.furniture .. " (" .. key .. ")")
                            ctx.interaction:send("ActivateInteriorFurniture", key, talk.use, talk.choice, Players.LocalPlayer.Character)
                        else
                            ctx.logger:warn("Tasks", "No " .. talk.furniture .. " in " .. destination)
                        end
                    end
                end
                started = started or ctx.waitUntil(hasStarted, LOCATION_START_SECONDS)
                if not started then
                    return false, "arrived at " .. destination .. " but the need did not start"
                end
            end
            local reequips = 0
            local function handleDrop()
                if not petDroppedDuringTask(ctx, group) then
                    return "no"
                end
                if reequips >= 2 then
                    return "fail"
                end
                reequips += 1
                ctx.logger:info("Tasks", "Your pet was unequipped at " .. destination .. ": equipping it again, then waiting")
                for _, entry in ipairs(group.entries or {}) do
                    if entry.owner == "pet" and not ctx.gameData:isPetEquipped(entry.petUnique) then
                        local ok, reason = equipPetAgain(ctx, entry.petUnique)
                        if not ok then ctx.logger:warn("Tasks", "Restoring pet " .. tostring(entry.petUnique) .. ": " .. tostring(reason)) end
                    end
                end
                return "again"
            end
            local waited = 0
            local extended = false
            local taskStart = Util.now() - 1
            local current = ctx.currentGroup(group.kind)
            if ctx.setWaiting then
                ctx.setWaiting(true)
            end
            while true do
                if current == nil then
                    local drop = handleDrop()
                    if drop == "fail" then
                        return false, "the pet was unequipped (its need is hidden, not completed)"
                    elseif drop == "no" then
                        if ctx.kindCompletedSince and not ctx.kindCompletedSince(group.kind, taskStart) then
                            ctx.waitUntil(function()
                                return ctx.kindCompletedSince(group.kind, taskStart) or ctx.currentGroup(group.kind) ~= nil
                            end, 6)
                            if not ctx.kindCompletedSince(group.kind, taskStart) then
                                if ctx.currentGroup(group.kind) ~= nil then
                                    ctx.logger:info("Tasks", group.kind .. " was removed and re-added (reset): still waiting")
                                    current = ctx.currentGroup(group.kind)
                                    continue
                                end
                                return false, group.kind .. " vanished without a completion (expired?)"
                            end
                        end
                        return true
                    end
                    current = ctx.currentGroup(group.kind)
                else
                    local expected = current.maxRemainingSeconds or (current.maxRate > 0 and (1 / current.maxRate) or 60)
                    local limit = expected + LOCATION_EXTRA_SECONDS - waited
                    if limit <= 0 then
                        return false, group.kind .. " did not complete in time"
                    end
                    ctx.logger:info("Tasks", string.format("Waiting at %s for %s (about %d s)", destination, group.kind, math.floor(expected + 0.5)))
                    local t0 = Util.now()
                    local gone = ctx.waitUntil(function()
                        return ctx.isKindGone(group.kind)
                    end, limit)
                    waited += math.max(Util.now() - t0, 0)
                    if not gone then
                        local still = ctx.currentGroup(group.kind)
                        if not extended and still and still.anyInProgress then
                            extended = true
                            local more = (still.maxRemainingSeconds or (still.maxRate > 0 and (1 / still.maxRate) or 60)) + 10
                            ctx.logger:info("Tasks", string.format("%s still in progress: waiting %d s more", group.kind, math.floor(more)))
                            if ctx.waitUntil(function()
                                return ctx.isKindGone(group.kind)
                            end, more) then
                                current = nil
                                continue
                            end
                        end
                        return false, group.kind .. " did not complete in time"
                    end
                    current = nil
                end
            end
        end,
    }
    local FURNITURE_START_SECONDS = 5
    local FURNITURE_EXTRA_SECONDS = 10
    Tasks.furniture = {
        id = "furniture",
        handles = function(kind)
            return GameConstants.FurnitureForAilment[kind] ~= nil
        end,
        timeoutSeconds = 110,
        run = function(ctx, group)
            local active = group.entries[1]
            if active and active.inProgress then
                local seconds = math.min(95, (active.rate or 0) > 0 and (1 - (active.progress or 0)) / active.rate + 10 or 20)
                ctx.waitUntil(function()
                    local current = ctx.findEntry(active.kind, active.owner, active.petUnique)
                    return ctx.isResolved(active) or (current and not current.inProgress)
                end, seconds)
                if ctx.isResolved(active) then return true end
            end
            local kinds = GameConstants.FurnitureForAilment[group.kind]
            if group.entries[1] and group.entries[1].owner == "baby" then
                local compatible = {}
                for _, kind in ipairs(kinds) do
                    if not GameConstants.PetOnlyFurniture[kind] then table.insert(compatible, kind) end
                end
                if #compatible == 0 then return false, "no baby-compatible furniture for " .. group.kind end
                kinds = compatible
            end
            local stoodUp, standReason = standUp(ctx)
            if not stoodUp then
                return false, standReason
            end
            if not ctx.travel:isAt(GameConstants.HouseInteriorName) then
                local ok, reason = ctx.travel:goTo(GameConstants.HouseInteriorName)
                if not ok then
                    return false, "going home: " .. tostring(reason)
                end
            end
            local spot, spotReason = nil, nil
            ctx.waitUntil(function()
                spot, spotReason = ctx.furniture:findSpot(kinds)
                return spot ~= nil
            end, 10)
            if not spot then
                return false, tostring(spotReason)
            end
            local ordered = table.clone(group.entries)
            table.sort(ordered, function(a, b)
                return a.owner == "pet" and b.owner ~= "pet"
            end)
            local babySpot
            if GameConstants.PetOnlyFurniture[spot.kind] then
                local babyKinds = {}
                for _, k in ipairs(kinds) do
                    if not GameConstants.PetOnlyFurniture[k] then
                        table.insert(babyKinds, k)
                    end
                end
                if #babyKinds > 0 then
                    ctx.waitUntil(function()
                        babySpot = ctx.furniture:findSpot(babyKinds)
                        return babySpot ~= nil
                    end, 10)
                end
            end
            local petSpot = spot
            for _, entry in ipairs(ordered) do
                local spot = (entry.owner == "baby" and babySpot) or petSpot
                local label = entry.owner == "baby" and "baby" or ("pet " .. tostring(entry.petKind or "?"))
                local current = ctx.findEntry(group.kind, entry.owner, entry.petUnique)
                if current then
                    if not current.inProgress then
                        local target
                        if entry.owner == "pet" then
                            target = ensurePetModel(ctx, entry.petUnique)
                        else
                            target = Players.LocalPlayer.Character
                        end
                        if not target then
                            return false, "no model to put on the " .. spot.kind .. " (" .. label .. ")"
                        end
                        if entry.owner == "baby" and GameConstants.PetOnlyFurniture[spot.kind] then
                            return false, "the " .. spot.kind .. " is only for pets (baby " .. group.kind .. ")"
                        end
                        if entry.owner == "pet" then
                            local off, offReason = petOffFurniture(ctx, entry.petUnique)
                            if not off then
                                return false, offReason
                            end
                        end
                        ctx.maid:Give(function()
                            if entry.owner == "baby" then ctx.interaction:send("ExitSeatStates")
                            else ctx.interaction:send("ExitFurnitureUseStates", entry.petUnique) end
                        end)
                        ctx.setPhase(entry, "using furniture")
                        ctx.logger:info("Tasks", string.format("Using %s %s for %s", spot.kind, spot.key, label))
                        local ok, reason = ctx.interaction:send("ActivateFurniture", Players.LocalPlayer, spot.key, spot.useName,
                            { cframe = spot.cframe }, target)
                        if not ok then
                            return false, "ActivateFurniture failed: " .. tostring(reason)
                        end
                        local started = ctx.waitUntil(function()
                            local now = ctx.findEntry(group.kind, entry.owner, entry.petUnique)
                            return now == nil or now.inProgress
                        end, FURNITURE_START_SECONDS)
                        if not started then
                            return false, "used the " .. spot.kind .. " but the " .. label .. " need did not start"
                        end
                    end
                    local now = ctx.findEntry(group.kind, entry.owner, entry.petUnique)
                    local expected = (now and now.rate > 0) and (1 / now.rate) or 15
                    if not ctx.waitUntil(function()
                        return ctx.findEntry(group.kind, entry.owner, entry.petUnique) == nil
                    end, expected + FURNITURE_EXTRA_SECONDS) then
                        return false, label .. " " .. group.kind .. " did not complete in time"
                    end
                    if entry.owner == "baby" then
                        ctx.waitUntil(function()
                            return not ctx.gameData:isSitting()
                        end, 1)
                        local up, upReason = standUp(ctx)
                        if not up then
                            return false, upReason
                        end
                    else
                        local pid = ctx.petLocator:getStreamingId(entry.petUnique)
                        local function petStillOn()
                            for _, who in ipairs(occupants(ctx, spot.key)) do
                                if who == pid then
                                    return true
                                end
                            end
                            return false
                        end
                        if pid and not ctx.waitUntil(function()
                            return not petStillOn()
                        end, 2) then
                            ctx.logger:info("Tasks", "Your pet is still on the " .. spot.kind .. ": getting it off")
                            ctx.interaction:send("ExitFurnitureUseStates", entry.petUnique)
                            if not ctx.waitUntil(function()
                                return not petStillOn()
                            end, 4) then
                                return false, "pet is still on the " .. spot.kind
                            end
                        end
                    end
                end
            end
            return true
        end,
    }
    local function petObjectsSnapshot()
        local folder = workspace:FindFirstChild(GameConstants.PetObjectsFolderName)
        local set = {}
        if folder then
            for _, child in ipairs(folder:GetChildren()) do
                set[child] = true
            end
        end
        return set
    end
    local function newPetObject(before, response)
        local folder = workspace:FindFirstChild(GameConstants.PetObjectsFolderName)
        -- A newly replicated object can belong to another player. Only use an instance
        -- explicitly returned by this request; normal automatic consumption remains supported.
        if folder and typeof(response) == "Instance" and response:IsDescendantOf(folder) and not before[response] then
            return response
        end
        return nil
    end
    local function pickItem(ctx, kind)
        local ids = GameConstants.ItemsForAilment[kind]
        if not ctx.gameData:inventoryKnown(GameConstants.ItemCategory) then return nil, "food inventory unavailable" end
        local found = ctx.gameData:findItems(GameConstants.ItemCategory, ids)
        if found[1] then
            return found[1]
        end
        local buy = GameConstants.BuyForAilment[kind]
        if not (buy and ctx.farmConfig[buy.setting]) then
            return nil, "no " .. table.concat(ids, " / ") .. " in your backpack"
        end
        for _, id in ipairs(buy.ids) do
            local buysThisSession = ctx.gameData.buysThisSession or 0
            local limit = ctx.farmConfig.MaxBuysPerSession
            if type(limit) == "number" and limit > 0 and buysThisSession >= limit then
                return nil, "purchase limit reached (" .. limit .. " this session)"
            end
            buysThisSession += 1
            ctx.gameData.buysThisSession = buysThisSession
            local bucksBefore = ctx.gameData:get(GameConstants.DataKeys.Money)
            ctx.logger:info("Tasks", string.format("Nothing for %s: buying 1 %s (purchase %d this session)", kind, id, buysThisSession))
            local sent, purchaseReason = ctx.interaction:send("BuyItem", buy.category, id, table.clone(buy.options))
            if not sent then return nil, tostring(purchaseReason) end
            local bought
            ctx.waitUntil(function()
                bought = ctx.gameData:findItems(GameConstants.ItemCategory, ids)[1]
                return bought ~= nil
            end, 6)
            if bought then
                local bucksAfter = ctx.gameData:get(GameConstants.DataKeys.Money)
                if type(bucksBefore) == "number" and type(bucksAfter) == "number" then
                    ctx.logger:info("Tasks", string.format("Bought %s for %d Bucks", id, bucksBefore - bucksAfter))
                end
                return bought
            end
            return nil, "purchase of " .. id .. " not confirmed in inventory; no further purchase attempted"
        end
        return nil, "could not buy " .. table.concat(buy.ids, " / ")
    end
    local PET_EAT_SECONDS = 10
    function Tasks.givePetItem(ctx, petUnique, item, done, label)
        local model, reason = ensurePetModel(ctx, petUnique)
        if not model then
            return false, "pet model: " .. tostring(reason)
        end
        if not ctx.gameData:inventoryKnown(GameConstants.ItemCategory) or not ctx.gameData:item(GameConstants.ItemCategory, item.unique) then
            return false, "item no longer available in confirmed inventory"
        end
        local before = petObjectsSnapshot()
        local held, focused = false, false
        local function release()
            if focused then ctx.interaction:send("UnfocusPet", model); focused = false end
            if held then ctx.interaction:send("UnequipItem", item.unique, nil); held = false end
        end
        ctx.maid:Give(release)
        ctx.logger:info("Tasks", string.format("Giving %s to selected pet %s (%s)", item.id, petUnique, label))
        held = true -- Register cleanup before the request can yield.
        local equipped, equipReason = ctx.interaction:send("EquipItem", item.unique, {})
        if not equipped then return false, "food equip failed: " .. tostring(equipReason) end
        focused = true
        local focusOk, focusReason = ctx.interaction:send("FocusPet", model)
        if not focusOk then return false, "pet focus failed: " .. tostring(focusReason) end
        local created, createAnswer = ctx.interaction:send("CreatePetObject", GameConstants.FoodObjectCreator,
            { additional_consume_uniques = {}, pet_unique = petUnique, unique_id = item.unique })
        if not created then return false, "food object request failed: " .. tostring(createAnswer) end
        if ctx.waitUntil(done, PET_EAT_SECONDS) then release(); return true end
        local object = newPetObject(before, createAnswer)
        if object then
            local sent, why = ctx.interaction:send("ConsumeFoodObject", object, petUnique)
            if not sent then return false, "consume request failed: " .. tostring(why) end
            if ctx.waitUntil(done, 8) then release(); return true end
        end
        return false, label .. " unconfirmed after " .. item.id .. "; no unrelated world object used"
    end
    local function feedPet(ctx, kind, entry, item)
        return Tasks.givePetItem(ctx, entry.petUnique, item, function()
            return ctx.isResolved(entry)
        end, kind)
    end
    local BABY_HOLD_SECONDS = 1.5
    local function feedBaby(ctx, kind, item)
        local held = true
        ctx.maid:Give(function()
            if held then
                ctx.interaction:send("UnequipItem", item.unique, nil)
            end
        end)
        ctx.maid:Give(function() ctx.interaction:send("UseTool", item.unique, "END", nil) end)
        ctx.logger:info("Tasks", string.format("Baby uses %s (%s)", item.id, kind))
        local equipped, equipReason = ctx.interaction:send("EquipItem", item.unique, {})
        if not equipped then return false, "baby equip failed: " .. tostring(equipReason) end
        task.wait(0.5)
        local function done()
            return ctx.completedSince(kind, "baby", nil) or ctx.findEntry(kind, "baby", nil) == nil
        end
        for _ = 1, math.min(12, math.max(1, ctx.gameData:itemUsesLeft(GameConstants.ItemCategory, item.unique) or 1)) do
            if done() then
                break
            end
            if not ctx.gameData:inventoryKnown(GameConstants.ItemCategory) then return false, "baby inventory unavailable" end
            local usesBefore = ctx.gameData:itemUsesLeft(GameConstants.ItemCategory, item.unique)
            if usesBefore == nil or usesBefore <= 0 then break end
            local sent, reason = ctx.interaction:send("UseTool", item.unique, "START")
            if not sent then return false, "baby tool failed: " .. tostring(reason) end
            task.wait(BABY_HOLD_SECONDS)
            ctx.interaction:send("UseTool", item.unique, "END", nil)
            if not ctx.waitUntil(function()
                local now = ctx.gameData:itemUsesLeft(GameConstants.ItemCategory, item.unique)
                return done() or (ctx.gameData:inventoryKnown(GameConstants.ItemCategory) and (now == nil or now < usesBefore))
            end, 3) then
                return false, item.id .. ": uses_left did not go down"
            end
            task.wait(0.3)
        end
        if ctx.gameData:itemUsesLeft(GameConstants.ItemCategory, item.unique) ~= nil then
            ctx.interaction:send("UnequipItem", item.unique, nil)
        end
        held = false
        ctx.waitUntil(done, 3)
        if done() then return true end
        return false, "baby need remains active after item use"
    end
    local function bowlForPet(ctx, kind, entry)
        if not ctx.travel:isAt(GameConstants.HouseInteriorName) then
            local ok, reason = ctx.travel:goTo(GameConstants.HouseInteriorName)
            if not ok then
                return false, "going home: " .. tostring(reason)
            end
        end
        local spot
        ctx.waitUntil(function()
            spot = ctx.furniture:findSpot(GameConstants.PetFoodBowls)
            return spot ~= nil
        end, 5)
        if not spot then
            return nil
        end
        local model, reason = ensurePetModel(ctx, entry.petUnique)
        if not model then
            return false, "pet model: " .. tostring(reason)
        end
        local off, offReason = petOffFurniture(ctx, entry.petUnique)
        if not off then
            return false, offReason
        end
        ctx.maid:Give(function() ctx.interaction:send("ExitFurnitureUseStates", entry.petUnique) end)
        ctx.setPhase(entry, "using food bowl")
        ctx.logger:info("Tasks", string.format("Using food bowl %s for your pet", spot.key))
        local ok, sendReason = ctx.interaction:send("ActivateFurniture", Players.LocalPlayer, spot.key, spot.useName, { cframe = spot.cframe }, model)
        if not ok then
            return false, "ActivateFurniture failed: " .. tostring(sendReason)
        end
        if not ctx.waitUntil(function()
            local now = ctx.findEntry(kind, "pet", entry.petUnique)
            return now == nil or now.inProgress
        end, 5) then
            return false, "used the food bowl but hungry did not start"
        end
        local now = ctx.findEntry(kind, "pet", entry.petUnique)
        local expected = (now and now.rate > 0) and (1 / now.rate) or 7
        if ctx.waitUntil(function()
            return ctx.findEntry(kind, "pet", entry.petUnique) == nil
        end, expected + 10) then
            return true
        end
        return false, "pet hungry did not complete at the food bowl"
    end
    Tasks.feed = {
        id = "feed",
        handles = function(kind)
            return GameConstants.ItemsForAilment[kind] ~= nil
        end,
        timeoutSeconds = 120,
        run = function(ctx, group)
            local stoodUp, standReason = standUp(ctx)
            if not stoodUp then
                return false, standReason
            end
            local ordered = table.clone(group.entries)
            table.sort(ordered, function(a, b)
                return a.owner == "pet" and b.owner ~= "pet"
            end)
            for _, entry in ipairs(ordered) do
                for _ = 1, (entry.owner == "baby" and 6 or 3) do
                    if not ctx.findEntry(group.kind, entry.owner, entry.petUnique) then
                        break
                    end
                    local bowlFirst = entry.owner == "pet" and group.kind == "hungry" and not entry.triedBowl and not ctx.side
                    if bowlFirst and not ctx.farmConfig.FoodBowlTrip and ctx.travel
                        and not ctx.travel:isAt(GameConstants.HouseInteriorName) then
                        entry.triedBowl = true
                        ctx.logger:info("Tasks", "Food in your backpack: feeding here, no trip home for the bowl (Farm.FoodBowlTrip)")
                    end
                    if entry.owner == "pet" and group.kind == "hungry" and not entry.triedBowl and not ctx.side then
                        entry.triedBowl = true
                        local bowlOk, bowlReason = bowlForPet(ctx, group.kind, entry)
                        if bowlOk == false then
                            ctx.logger:warn("Tasks", "Bowl failed: " .. tostring(bowlReason) .. "; trying inventory after release")
                            local released, releaseReason = petOffFurniture(ctx, entry.petUnique)
                            if not released then return false, releaseReason end
                        elseif bowlOk == true then
                            break
                        end
                    end
                    local item, reason = pickItem(ctx, group.kind)
                    if not item then
                        return false, reason
                    end
                    local ok, feedReason
                    if entry.owner == "pet" then
                        ok, feedReason = feedPet(ctx, group.kind, entry, item)
                        if not ok then
                            return false, feedReason
                        end
                    else
                        ok, feedReason = feedBaby(ctx, group.kind, item)
                        if not ok then
                            return false, feedReason or "baby feeding unconfirmed"
                        end
                    end
                end
                if ctx.findEntry(group.kind, entry.owner, entry.petUnique) then
                    return false, (entry.owner == "baby" and "baby" or "pet") .. " " .. group.kind .. " still active after bounded feeding attempts"
                end
            end
            return true
        end,
    }
    local THROW_CATCH_SECONDS = 6
    Tasks.play = {
        id = "play",
        handles = function(kind)
            return kind == "play"
        end,
        timeoutSeconds = 80,
        run = function(ctx, group)
            local entry = group.petEntry
            if not entry then
                return false, "play is only for pets"
            end
            local stoodUp, standReason = standUp(ctx)
            if not stoodUp then
                return false, standReason
            end
            local toy = ctx.gameData:findItems(GameConstants.ToyCategory, GameConstants.ToysForPlay)[1]
            if not toy then
                return false, "no " .. table.concat(GameConstants.ToysForPlay, " / ") .. " in your backpack"
            end
            local model, reason = ensurePetModel(ctx, entry.petUnique)
            if not model then
                return false, "pet model: " .. tostring(reason)
            end
            local petHasToy = false
            ctx.maid:Give(function()
                if petHasToy then
                    ctx.interaction:send("EquipItem", toy.unique, {})
                    ctx.interaction:send("DropPetObject", model)
                    ctx.interaction:send("UnequipItem", toy.unique, nil)
                end
            end)
            local function current()
                return ctx.findEntry("play", "pet", entry.petUnique)
            end
            for throw = 1, 6 do
                local now = current()
                if not now or ctx.completedSince("play", "pet", entry.petUnique) then
                    return true
                end
                local progressBefore = now.progress or 0
                local before = petObjectsSnapshot()
                ctx.logger:info("Tasks", string.format("Throwing %s (throw %d, progress %d%%)", toy.id, throw, math.floor(progressBefore * 100 + 0.5)))
                ctx.interaction:send("EquipItem", toy.unique, {})
                if petHasToy then
                    ctx.interaction:send("DropPetObject", model)
                    petHasToy = false
                end
                task.wait(0.5)
                ctx.interaction:send("UseTool", toy.unique, "START")
                local created, toyObject = ctx.interaction:send("CreatePetObject", GameConstants.ToyObjectCreator,
                    { reaction_name = GameConstants.ThrowToyReaction, unique_id = toy.unique })
                ctx.interaction:send("UnequipItem", toy.unique, { from_throw_toy = true })
                ctx.interaction:send("UseTool", toy.unique, "END", nil)
                local function caught()
                    local after = current()
                    return after == nil or (after.progress or 0) > progressBefore
                end
                if not ctx.waitUntil(caught, THROW_CATCH_SECONDS) then
                    local object = created and newPetObject(before, toyObject)
                    if not object then
                        return false, "no toy object appeared after the throw"
                    end
                    ctx.logger:info("Tasks", "Your pet did not catch the toy by itself: sending GrabPetObject")
                    ctx.interaction:send("GrabPetObject", model, object, nil)
                    if not ctx.waitUntil(caught, 4) then
                        return false, "play progress did not rise after throw " .. throw
                    end
                end
                petHasToy = true
                task.wait(1)
            end
            if current() then
                return false, "play not completed after 6 throws"
            end
            return true
        end,
    }
    --[[
        v2.1.6 mystery cards (spy v3, 2026-10-12): the game shows the 3 cards with
        MysteryAilmentClient._get_ailment_slots(self, petInfo) -> { "pizza_party", "ride", "camping" }, where self.options is
        the mystery component (components + random_seed) plus a get_ailment_slots function. The same spy showed the
        server ignoring even the RIGHT card while calls came in fast (a player's own tap was dropped in the middle of
        the bot's burst), so: read the 3 cards, then ONE call on the right card.
        The get_ailment_slots function is looked up once: the game's loaded Ailments modules first, then the running
        functions by name. An answer counts only when it is 2-4 kinds of the pet's pool.
    ]]
    GameConstants.MysteryClientPath = { "new", "modules", "Ailments", "ClientActions", "MysteryAilmentClient" }
    GameConstants.AilmentsModulesPath = { "new", "modules", "Ailments" }
    local mysteryClient, mysterySlotsFn, mysteryLookupDone, mysteryHow
    local function findMysterySlotsFn(ctx)
        local RS = game:GetService("ReplicatedStorage")
        local node = RS
        for _, name in ipairs(GameConstants.MysteryClientPath) do
            node = node and node:FindFirstChild(name)
        end
        if node and node:IsA("ModuleScript") then
            local ok, module = pcall(require, node)
            mysteryClient = ok and type(module) == "table" and type(module._get_ailment_slots) == "function" and module or nil
        end
        local found, where = {}, {}
        local function take(fn, label)
            if type(fn) == "function" and not table.find(found, fn) then
                table.insert(found, fn)
                table.insert(where, label)
            end
        end
        -- 1) a module table (or one level down) holding get_ailment_slots
        local folder = RS
        for _, name in ipairs(GameConstants.AilmentsModulesPath) do
            folder = folder and folder:FindFirstChild(name)
        end
        -- only modules the game already loaded (a fresh require could wait forever or run server code)
        local loaded = nil
        if type(getloadedmodules) == "function" then
            pcall(function()
                local set = {}
                for _, m in ipairs(getloadedmodules()) do
                    set[m] = true
                end
                loaded = set
            end)
        end
        for _, module in ipairs(folder and folder:GetDescendants() or {}) do
            if module:IsA("ModuleScript") and (loaded ~= nil and loaded[module]) then
                local ok, value = pcall(require, module)
                if ok and type(value) == "table" then
                    take(rawget(value, "get_ailment_slots"), module.Name)
                    for key, inner in pairs(value) do
                        if type(inner) == "table" then
                            take(rawget(inner, "get_ailment_slots"), module.Name .. "." .. tostring(key))
                        end
                    end
                end
            end
        end
        -- 2) the running functions by their name
        if #found == 0 and type(getgc) == "function" then
            pcall(function()
                for _, fn in ipairs(getgc(false)) do
                    if type(fn) == "function" and debug.info(fn, "n") == "get_ailment_slots" then
                        take(fn, "running function")
                    end
                    if #found >= 6 then
                        break
                    end
                end
            end)
        end
        mysterySlotsFn = { fns = found, where = where }
        ctx.logger:info("Tasks", string.format("Mystery: card reader %s, get_ailment_slots found %d (%s)",
            mysteryClient and "ok" or "NOT found", #found, table.concat(where, ", ")))
    end
    function Tasks.mysteryCards(ctx, entry)
        if not mysteryLookupDone or (not mysteryClient and Util.now() - mysteryLookupDone > 30) then
            mysteryLookupDone = Util.now()
            findMysterySlotsFn(ctx)
        end
        if not mysteryClient then
            return nil, "no MysteryAilmentClient"
        end
        local manager = ctx.gameData:get(GameConstants.DataKeys.Ailments)
        local ailments = type(manager) == "table" and manager.ailments
        local mine = type(ailments) == "table" and ailments[entry.petUnique]
        local raw = type(mine) == "table" and mine.mystery
        local component = type(raw) == "table" and type(raw.components) == "table" and raw.components.mystery
        if type(component) ~= "table" then
            return nil, "no mystery data"
        end
        local pool = {}
        for kind in pairs(type(component.components) == "table" and component.components or {}) do
            pool[tostring(kind)] = true
        end
        local function asCards(result)
            if type(result) ~= "table" then
                return nil
            end
            local list = {}
            for i = 1, 4 do
                local v = result[i]
                if type(v) == "table" then
                    v = v.kind or v.ailment_key or v.name or v.id
                end
                if v ~= nil then
                    if not pool[tostring(v)] then
                        return nil
                    end
                    table.insert(list, tostring(v))
                end
            end
            return (#list >= 2 and #list <= 4) and list or nil
        end
        local Players = game:GetService("Players")
        local player = Players.LocalPlayer
        local model = nil
        pcall(function()
            model = ctx.petLocator:findModel(entry.petUnique)
        end)
        local petInfo = {
            pet_unique = entry.petUnique, unique = entry.petUnique, pet_id = entry.petKind, is_pet = true,
            char = model, player = player, controller = player, entity_controller = player, index = 1,
        }
        local fns = mysterySlotsFn and mysterySlotsFn.fns or {}
        local order = {}
        if mysteryHow then
            table.insert(order, mysteryHow)
        end
        for i = 1, #fns do
            if i ~= mysteryHow then
                table.insert(order, i)
            end
        end
        if #order == 0 then
            order = { 0 } -- no helper found: the reader may still work without one
        end
        local lastError = nil
        for _, i in ipairs(order) do
            local options = {}
            for key, value in pairs(component) do
                options[key] = value
            end
            options.get_ailment_slots = fns[i]
            local self = setmetatable({ options = options }, { __index = mysteryClient })
            local ok, result = pcall(mysteryClient._get_ailment_slots, self, petInfo)
            local cards = ok and asCards(result)
            if cards then
                mysteryHow = i ~= 0 and i or nil
                return cards, "card reader" .. (i ~= 0 and (" + " .. tostring(mysterySlotsFn.where[i])) or "")
            end
            lastError = ok and ("answer " .. type(result)) or tostring(result)
        end
        return nil, "card reader: " .. tostring(lastError)
    end
    Tasks.mystery = {
        id = "mystery",
        handles = function(kind)
            return kind == "mystery"
        end,
        timeoutSeconds = 300,
        run = function(ctx, group)
            local entry = group.petEntry
            if not entry then
                return false, "mystery is only handled for pets"
            end
            local offered = {}
            for _, kind in ipairs(entry.mysteryOptions or {}) do
                offered[kind] = true
            end
            local choices = {}
            for _, kind in ipairs(GameConstants.MysteryPreference) do
                local doable = kind ~= "mystery" and Tasks.findFor(kind) ~= nil and GameConstants.needOn(ctx.farmConfig, kind)
                if doable and (entry.mysteryOptions == nil or offered[kind]) and not ctx.findEntry(kind, "pet", entry.petUnique) then
                    table.insert(choices, kind)
                end
            end
            if #choices == 0 then return false, "no enabled need among the offered mystery options" end
            local okCards, cards, how = pcall(Tasks.mysteryCards, ctx, entry)
            if not okCards or type(cards) ~= "table" then
                return false, "mystery cards unavailable: " .. tostring(okCards and how or cards)
            end
            local pick, slot
            for _, kind in ipairs(choices) do
                for i, card in ipairs(cards) do if card == kind then pick, slot = kind, i; break end end
                if pick then break end
            end
            if not pick then return false, "no enabled need on the current mystery cards" end
            local revision = ctx.state:get("ailments.revision", 0)
            local sent, why = ctx.interaction:send("ChooseMystery", entry.petUnique, "mystery", slot, pick)
            if not sent then return false, "mystery choice failed: " .. tostring(why) end
            local confirmed = ctx.waitUntil(function()
                return ctx.isResolved(entry) or ctx.confirmReplacement(entry, pick, revision)
            end, 12)
            if confirmed then return true end
            return false, "mystery choice did not replicate; no speculative card burst sent"
        end,
    }
    local function movingNeed(kind)
        return {
            id = kind,
            handles = function(k)
                return k == kind
            end,
            timeoutSeconds = 170,
            run = function(ctx, group)
                local entry = group.petEntry
                if not entry then
                    return false, kind .. " is only for pets"
                end
                local stoodUp, standReason = standUp(ctx)
                if not stoodUp then
                    return false, standReason
                end
                if not ctx.travel:isAt("MainMap") then
                    local ok, reason = ctx.travel:goTo("MainMap")
                    if not ok then
                        return false, "travel: " .. tostring(reason)
                    end
                    task.wait(3)
                end
                local stroller
                if kind == "ride" then
                    local item = ctx.gameData:findItems(GameConstants.StrollerCategory, { "stroller-default" })[1]
                        or (function()
                            local inventory = ctx.gameData:get(GameConstants.DataKeys.Inventory)
                            for unique, it in pairs(type(inventory) == "table" and inventory.strollers or {}) do
                                if type(it) == "table" then
                                    return { unique = tostring(it.unique or unique), id = it.id }
                                end
                            end
                            return nil
                        end)()
                    if not item then
                        return false, "no stroller in your backpack"
                    end
                    local model, reason
                    ctx.waitUntil(function()
                        model, reason = ctx.petLocator:findModel(entry.petUnique)
                        return model ~= nil
                    end, 8)
                    if not model then
                        return false, "pet model: " .. tostring(reason)
                    end
                    local wrappers = ctx.gameData:get(GameConstants.DataKeys.PetWrappers)
                    local sit
                    for _, wrapper in pairs(type(wrappers) == "table" and wrappers or {}) do
                        if type(wrapper) == "table" and wrapper.pet_unique == entry.petUnique then
                            sit = table.clone(wrapper)
                        end
                    end
                    if not sit then
                        return false, "no data for the pet"
                    end
                    sit.char = model
                    sit.controller = Players.LocalPlayer
                    sit.entity_controller = Players.LocalPlayer
                    sit.player = Players.LocalPlayer
                    stroller = item.unique
                    ctx.maid:Give(function()
                        ctx.interaction:send("UnequipStroller")
                        ctx.interaction:send("UnequipItem", stroller, nil)
                    end)
                    ctx.logger:info("Tasks", "Putting your pet in the stroller (" .. tostring(item.id) .. ")")
                    ctx.interaction:send("EquipItem", stroller, { chars_to_sit = { sit } })
                    task.wait(1)
                end
                local STALL = 15
                local unique = entry.petUnique
                local function now()
                    return ctx.findEntry(kind, "pet", unique)
                end
                local function gone()
                    return now() == nil and not petDroppedDuringTask(ctx, group)
                end
                local character = Players.LocalPlayer.Character
                local root = character and character:FindFirstChild("HumanoidRootPart")
                local lastPos = root and root.Position
                local moved, lastLog, sinceActive, elapsed = 0, 0, 0, 0
                local best = (now() or {}).progress or 0
                local lastUse = 0
                local function petDistance()
                    local model = ctx.petLocator:findModel(unique)
                    if not model or not root then
                        return nil
                    end
                    local ok, pos = pcall(function()
                        return model:GetPivot().Position
                    end)
                    if not ok or not pos then
                        return nil
                    end
                    return math.sqrt((pos.X - root.Position.X) ^ 2 + (pos.Z - root.Position.Z) ^ 2)
                end
                local function sample()
                    local e = now()
                    local progress = e and e.progress or best
                    local active = e ~= nil and (e.inProgress or progress > best + 1e-6)
                    if progress > best then
                        best = progress
                    end
                    if active then
                        sinceActive = 0
                    else
                        sinceActive += 2
                    end
                    return e, active
                end
                local stalled = false
                local tickCount = 0
                -- v2.1.5 (reports 2026-10-12: ride "moved 1500 studs" every 7 s, at (17505, -15021) NOT ON MAINMAP:
                -- the stroller flings the character into the void - a white / empty screen for the user): the walk
                -- stays near where it began; a jump of more than FLING studs = back to the start, still; 3 = stop
                local FLING = 120
                local anchorPos, flings, flungOut = nil, 0, false
                local function guardFling()
                    if not (root and anchorPos) then
                        return
                    end
                    local p = root.Position
                    local far = math.sqrt((p.X - anchorPos.X) ^ 2 + (p.Z - anchorPos.Z) ^ 2)
                    if far > FLING or not isOnMainMapArea(p) then
                        flings += 1
                        ctx.logger:warn("Tasks", string.format("%s: flung %d studs away (at %.0f, %.0f): back to the start (%d)",
                            kind, math.floor(far), p.X, p.Z, flings))
                        -- v2.1.6 (reports: 3 "flings" within 1 s, each farther along one line: the push went on after
                        -- the move back): held still for a moment so nothing keeps pushing, the stroller left alone 3 s
                        pcall(function()
                            root.AssemblyLinearVelocity = Vector3.zero
                            root.AssemblyAngularVelocity = Vector3.zero
                            character:PivotTo(CFrame.new(anchorPos + Vector3.new(0, 3, 0)))
                            root.Anchored = true
                        end)
                        task.wait(0.5)
                        pcall(function()
                            root.AssemblyLinearVelocity = Vector3.zero
                            root.Anchored = false
                        end)
                        if stroller then
                            pcall(function()
                                ctx.interaction:send("UseTool", stroller, "END", nil)
                            end)
                            lastUse = os.clock() + 3
                        end
                        if flings == 1 then
                            pcall(function()
                                local humanoid = character:FindFirstChildOfClass("Humanoid")
                                ctx.logger:info("Tasks", string.format("%s: fling details: seat %s, state %s, stroller %s", kind,
                                    tostring(humanoid and humanoid.SeatPart and humanoid.SeatPart:GetFullName()),
                                    tostring(humanoid and humanoid:GetState()), tostring(stroller ~= nil)))
                            end)
                        end
                        pcall(function() ctx.interaction.settle(1) end)
                        lastPos = root.Position
                        if flings >= 3 then
                            flungOut, stalled = true, true
                        end
                    end
                end
                local function tick()
                    tickCount += 1
                    guardFling()
                    if stroller and os.clock() - lastUse > 2 then
                        lastUse = os.clock()
                        ctx.interaction:send("UseTool", stroller, "START")
                        ctx.interaction:send("UseTool", stroller, "END", nil)
                    end
                    if root and lastPos then
                        local p = root.Position
                        moved += math.sqrt((p.X - lastPos.X) ^ 2 + (p.Z - lastPos.Z) ^ 2)
                        lastPos = p
                    end
                    if tickCount % 4 == 0 then
                        elapsed += 2
                        local e, active = sample()
                        if elapsed - lastLog >= 6 then
                            lastLog = elapsed
                            local d = petDistance()
                            local where = ""
                            if root then
                                local rp = root.Position
                                where = string.format(", at (%.0f, %.0f)%s", rp.X, rp.Z, isOnMainMapArea(rp) and "" or " NOT ON MAINMAP")
                            end
                            ctx.logger:info("Tasks", string.format("%s: progress %d%%, %s, moved %d studs, pet %s%s%s", kind,
                                math.floor(((e and e.progress) or best) * 100), active and "running" or "NOT running",
                                math.floor(moved), d and (math.floor(d) .. " studs away") or "not found", where,
                                (moved < 1 and ctx.interaction.walkDiag) and (" [not moving: " .. ctx.interaction.walkDiag .. "]") or ""))
                            moved = 0
                        end
                        if sinceActive >= STALL then
                            stalled = true
                        end
                    end
                end
                local function walkPhase(seconds)
                    stalled, sinceActive = false, 0
                    character = Players.LocalPlayer.Character
                    root = character and character:FindFirstChild("HumanoidRootPart")
                    lastPos = root and root.Position
                    anchorPos = root and isOnMainMapArea(root.Position) and root.Position or anchorPos
                    return ctx.interaction:walkAround(seconds, function()
                        return gone() or stalled
                    end, tick)
                end
                walkPhase(75)
                if gone() then
                    return true
                end
                if flungOut then
                    return false, kind .. ": the character was flung off the map 3 times (stopped, back at the start)"
                end
                if stalled and GameConstants.Spots.beach_party then
                    ctx.logger:info("Tasks", kind .. " is not progressing here: moving to the open beach spot and walking there")
                    local teleported, why = ctx.interaction:teleportTo("beach_party")
                    ctx.logger:info("Tasks", "Teleport to beach_party: " .. (teleported and "ok" or tostring(why)))
                    if petDroppedDuringTask(ctx, group) or ctx.waitUntil(function()
                        return petDroppedDuringTask(ctx, group)
                    end, 5) then
                        equipPetAgain(ctx, unique)
                    end
                    walkPhase(60)
                    if gone() then
                        return true
                    end
                    if flungOut then
                        return false, kind .. ": the character was flung off the map 3 times (stopped, back at the start)"
                    end
                elseif not stalled then
                    walkPhase(45)
                    if gone() then
                        return true
                    end
                end
                local e = now()
                if petDroppedDuringTask(ctx, group) then
                    return false, "the pet was unequipped while walking"
                end
                return false, string.format("%s stopped progressing (progress %d%%)", kind, math.floor(((e and e.progress) or best) * 100))
            end,
        }
    end
    Tasks.walk = movingNeed("walk")
    Tasks.ride = movingNeed("ride")
    Tasks.recover = {
        id = "recover",
        handles = function()
            return false
        end,
        timeoutSeconds = 150,
        run = function(ctx)
            ctx.logger:info("Tasks", "Recover: returning through normal house entry without resetting pets")
            local ok, reason = ctx.travel:goTo(GameConstants.HouseInteriorName)
            if not ok then
                return false, "recover: " .. tostring(reason)
            end
            return true
        end,
    }
    Tasks.equipPet = {
        id = "equip_pet",
        handles = function()
            return false
        end,
        timeoutSeconds = 15,
        run = function(ctx, group)
            ctx.logger:info("Tasks", "Your pet is not equipped: equipping it again")
            local ok, reason = equipPetAgain(ctx, group.petUnique)
            if not ok and group.onFail then
                group.onFail()
            end
            return ok, reason
        end,
    }
    -- v2.1.5: a second pet (2-pet perk / Pet Certificate). The game's own equip, as for the first pet; when the first
    -- pet is pushed out, the account holds one pet: the first comes back and the farm stops trying
    Tasks.equipSecondPet = {
        id = "second_pet",
        handles = function()
            return false
        end,
        timeoutSeconds = 40,
        run = function(ctx, group)
            if not group.firstUnique or not group.petUnique or group.firstUnique == group.petUnique then
                return false, "two different owned pets are required"
            end
            local function both()
                local count, known = ctx.gameData:equippedPetCount()
                return known and count >= 2 and ctx.gameData:isPetEquipped(group.petUnique)
                    and ctx.gameData:isPetEquipped(group.firstUnique)
            end
            if both() then return true end
            local sent, reason = ctx.interaction:send("EquipItem", group.petUnique, { equip_as_last = true })
            if not sent then
                if group.onFail then group.onFail() end
                return false, "Equip failed: " .. tostring(reason)
            end
            if ctx.waitUntil(both, 15) then
                task.wait(1)
                if ctx.refreshNeeds then ctx.refreshNeeds() end
                if both() then
                    ctx.logger:success("Tasks", "Two distinct pets confirmed in equipped data")
                    return true
                end
            end
            if group.onOneSlot then group.onOneSlot() end
            if not ctx.gameData:isPetEquipped(group.firstUnique) then
                if ctx.restoreDisplacedPet then ctx.restoreDisplacedPet(group.firstUnique, group.petUnique)
                else equipPetAgain(ctx, group.firstUnique) end
            end
            return false, "two slots were not confirmed; check active certificate or equip the pair manually"
        end,
    }
    Tasks.swapSecondPet = {
        id = "second_pet", handles = function() return false end, timeoutSeconds = 45,
        run = function(ctx, group)
            local first
            for _, pet in ipairs(ctx.gameData:equippedPetList()) do
                if pet.unique ~= group.outUnique then first = pet.unique end
            end
            if not first then return false, "other equipped pet is unknown; swap cancelled" end
            local ok, reason = ctx.interaction:send("UnequipItem", group.outUnique, nil)
            if not ok then return false, reason end
            if not ctx.waitUntil(function() return not ctx.gameData:isPetEquipped(group.outUnique) end, 6) then
                return false, "old pet did not leave the slot"
            end
            ok, reason = Tasks.equipSecondPet.run(ctx, { firstUnique = first, petUnique = group.petUnique })
            if not ok then
                if not ctx.gameData:isPetEquipped(group.outUnique) then equipPetAgain(ctx, group.outUnique) end
                return false, reason
            end
            return true
        end,
    }
    Tasks.buyEgg = {
        name = "buy_egg",
        timeoutSeconds = 90,
        run = function(ctx, group)
            local focus = GameConstants.focusOf(ctx.farmConfig)
            local id = focus and focus.kind == "egg" and focus.id or ctx.farmConfig.EggToBuy or "cracked_egg"
            if GameConstants.NeverBuyEggs[id] then
                return false, id .. " costs Robux: never bought"
            end
            -- v2.1.6 (reports: "no fairytale_egg arrived", 34 tries an hour on some accounts, 30 s each): after 6
            -- misses in a row the egg is left alone for 2 h (the shop may not sell it now)
            Tasks._eggMiss = Tasks._eggMiss or {}
            local miss = Tasks._eggMiss[id]
            if miss and miss.count >= 6 and Util.now() < miss.untilAt then
                return false, string.format("%s could not be bought %d times in a row (the shop may not sell it now): "
                    .. "tried again in %d min", id, miss.count, math.ceil((miss.untilAt - Util.now()) / 60))
            end
            local known = false
            for _, egg in ipairs(GameConstants.Eggs) do
                known = known or egg == id
            end
            if not known then
                ctx.logger:warn("Tasks", "Farm.EggToBuy = " .. tostring(id) .. " is not in the egg list: trying it anyway")
            end
            local function tryBuy(where)
                local before = ctx.gameData:petUniquesOfKind(id)
                local bucks = ctx.gameData:get(GameConstants.DataKeys.Money)
                ctx.logger:info("Tasks", "No pet that still grows: buying 1 " .. id .. where)
                local sent, reason = ctx.interaction:send("BuyItem", GameConstants.EggCategory, id, { buy_count = 1 })
                if not sent then
                    ctx.logger:warn("Tasks", "BuyItem(" .. id .. ") failed: " .. tostring(reason))
                end
                local newUnique
                ctx.waitUntil(function()
                    for unique in pairs(ctx.gameData:petUniquesOfKind(id)) do
                        if not before[unique] then
                            newUnique = unique
                            return true
                        end
                    end
                    return false
                end, 8)
                if newUnique then
                    local after = ctx.gameData:get(GameConstants.DataKeys.Money)
                    ctx.logger:info("Tasks", string.format("Bought %s%s", id, (tonumber(bucks) and tonumber(after))
                        and string.format(" for %d Bucks", bucks - after) or ""))
                end
                return newUnique
            end
            local unique = tryBuy("")
            if not unique and ctx.travel:canGoTo("Nursery") then
                local ok, why = ctx.travel:goTo("Nursery")
                if not ok then
                    return false, "egg not bought, and the Nursery trip failed: " .. tostring(why)
                end
                unique = tryBuy(" in the Nursery")
            end
            if not unique then
                miss = Tasks._eggMiss[id] or { count = 0, untilAt = 0 }
                miss.count += 1
                if miss.count >= 6 then
                    miss.untilAt = Util.now() + 7200
                end
                Tasks._eggMiss[id] = miss
                return false, "no " .. id .. " arrived in your backpack (not enough Bucks, or the shop call differs)"
            end
            Tasks._eggMiss[id] = nil
            if group and group.onBought then
                group.onBought()
            end
            return true
        end,
    }
    Tasks.team = {
        id = "team",
        timeoutSeconds = 25,
        run = function(ctx)
            local ok, reason = ctx.interaction:send("ChooseTeam", GameConstants.BabiesTeam, table.clone(GameConstants.ChooseTeamOptions))
            if not ok then
                return false, "ChooseTeam failed: " .. tostring(reason)
            end
            if ctx.waitUntil(function()
                return ctx.state:get("player.team") == GameConstants.BabiesTeam
            end, 10) then
                return true
            end
            return false, "team is still " .. tostring(ctx.state:get("player.team"))
        end,
    }
    function Tasks.runNeedGroup(ctx, definition, group, attempt)
        if definition.id == "location" then
            local ok, reason = definition.run(ctx, group, attempt)
            if not ok then
                for _, entry in ipairs(group.entries) do ctx.recordNeedResult(entry, ctx.isResolved(entry)) end
                return false, reason
            end
            for _, entry in ipairs(group.entries) do
                local confirmed = ctx.waitForNeed(entry, 8)
                ctx.recordNeedResult(entry, confirmed)
                if not confirmed then
                    return false, "location did not confirm " .. entry.owner .. " " .. tostring(entry.petUnique)
                end
            end
            return true
        end
        local errors = {}
        local entries = table.clone(group.entries)
        table.sort(entries, function(a, b)
            if a.owner ~= b.owner then return a.owner == "pet" end
            return tostring(a.petUnique) < tostring(b.petUnique)
        end)
        for _, entry in ipairs(entries) do
            if not ctx.isResolved(entry) then
                local label = entry.owner == "baby" and "baby" or ("pet " .. tostring(entry.petUnique))
                ctx.state:set("farm.needTarget", label .. " / " .. group.kind, "NeedRunner")
                local participantMaid = Maid.new()
                ctx.maid:Give(function() participantMaid:Clean() end)
                local child = setmetatable({ maid = participantMaid }, { __index = ctx })
                function child.currentGroup(kind)
                    if kind ~= entry.kind then return nil end
                    local current = ctx.findEntry(kind, entry.owner, entry.petUnique)
                    return current and NeedSession.single(current) or nil
                end
                function child.isKindGone(kind) return child.currentGroup(kind) == nil end
                function child.kindCompletedSince(kind) return kind == entry.kind and ctx.isResolved(entry) end
                ctx.setPhase(entry, "running")
                local ran, ok, reason = pcall(definition.run, child, NeedSession.single(entry), attempt)
                participantMaid:Clean()
                if not ran then reason, ok = "script error: " .. tostring(ok), false end
                local confirmed = ctx.isResolved(entry)
                if ok == true and not confirmed then confirmed = ctx.waitForNeed(entry, 15) end
                ctx.recordNeedResult(entry, confirmed)
                if not confirmed then
                    table.insert(errors, label .. ": " .. tostring(reason or "no confirmed completion"))
                    ctx.logger:warn("Needs", errors[#errors])
                end
            end
        end
        ctx.state:set("farm.needTarget", "", "NeedRunner")
        return #errors == 0, #errors > 0 and table.concat(errors, "; ") or nil
    end

    Tasks.ALL = { Tasks.pet_me, Tasks.location, Tasks.furniture, Tasks.feed, Tasks.play, Tasks.mystery, Tasks.walk, Tasks.ride }
    function Tasks.findFor(kind)
        for _, taskDefinition in ipairs(Tasks.ALL) do
            if taskDefinition.handles(kind) then
                return taskDefinition
            end
        end
        return nil
    end
    return Tasks
end
__moduleSources["Game/Minigame"] = function(...)
    local import = ...
    local Util = import("Core/Util")
    local GameConstants = import("Game/GameConstants")
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local Minigame = {}
    Minigame.__index = Minigame
    function Minigame.new(logger)
        local self = setmetatable({}, Minigame)
        self._logger = logger
        self:reset()
        return self
    end
    function Minigame:reset()
        self._sessionId = nil
        self._sessionSeenAt = nil
        self.joinAcceptedAt = nil
        self.join = nil
        self.enter = nil
        self.score = 0
        self.scoreCount = 0
        self.lastScoreAt = nil
        self.leave = nil
        self.haunted = {}
        self.propProgress = {}
        self.propsResolved = 0
        self.bossOut = false
    end
    function Minigame.serverNow()
        local ok, value = pcall(function()
            return workspace:GetServerTimeNow()
        end)
        if ok and type(value) == "number" then
            return value
        end
        return os.time()
    end
    local function isMine(gameKey)
        local id = GameConstants.Event.MinigameId
        return type(gameKey) == "string" and (gameKey == id or string.sub(gameKey, 1, #id + 2) == id .. "::")
    end
    local KNOWN = {
        join_accepted = true, join_minigame = true, enter_game = true, ghost_clusters_score = true, leave_game = true,
        ghost_clusters_cast_wave = true, ghost_clusters_prop_progress = true, ghost_clusters_prop_resolved = true,
        ghost_clusters_prop_restored = true, ghost_clusters_boss_breakout = true, ghost_clusters_props = true,
        ghost_clusters_vacuum_beam = true, ghost_clusters_attack_windup = true, ghost_clusters_attack_fire = true,
        ghost_clusters_attack_end = true, ghost_clusters_tornado_catch = true, ghost_clusters_tornado_release = true,
    }
    local function short(value, depth)
        depth = depth or 0
        if type(value) == "table" then
            if depth >= 3 then
                return "{...}"
            end
            local parts, n = {}, 0
            for k, v in pairs(value) do
                n += 1
                if n > 12 then
                    table.insert(parts, "...")
                    break
                end
                table.insert(parts, tostring(k) .. "=" .. short(v, depth + 1))
            end
            return "{" .. table.concat(parts, ", ") .. "}"
        end
        return tostring(value)
    end
    function Minigame:_onMessage(gameKey, message, a, b)
        if not isMine(gameKey) then
            return
        end
        if type(message) == "string" and not KNOWN[message] then
            self._seenTypes = self._seenTypes or {}
            if not self._seenTypes[message] then
                self._seenTypes[message] = true
                self._logger:info("Minigame", "New message type: " .. message .. " " .. Util.truncate(short(a) .. " " .. short(b), 300))
            end
        end
        local qualified = type(gameKey) == "string" and string.find(gameKey, "::", 1, true) ~= nil
        if message ~= "join_minigame" and message ~= "join_accepted" and qualified
            and self._sessionId and self._sessionId ~= gameKey then return end
        local now = Util.now()
        if qualified and not self._sessionId and KNOWN[message] and message ~= "leave_game" then
            self._sessionId, self._sessionSeenAt = gameKey, now
        end
        if message == "join_accepted" then
            if self.leave then self:reset() end
            self.joinAcceptedAt = now
        elseif message == "join_minigame" and type(b) == "string" then
            if self._sessionId ~= b then self:reset() end
            self._sessionId = b
            self.join = { interior = a, gameId = b, at = now }
            self._logger:info("Minigame", "Round starting: " .. tostring(b))
        elseif message == "enter_game" and type(a) == "table" then
            if qualified then self._sessionId = gameKey end
            self.enter = { intermissionEnd = tonumber(a.intermission_end_time), endTime = tonumber(a.end_time), at = now }
        elseif (message == "ghost_clusters_cast_wave" or message == "ghost_clusters_props") and type(a) == "table" then
            if message == "ghost_clusters_props" then self.haunted = {} end
            for key, prop in pairs(a) do
                local unique = type(prop) == "table" and (prop.unique or type(key) == "string" and key)
                if type(prop) == "table" and prop.haunted == true and prop.resolved ~= true and type(unique) == "string" then
                    self.haunted[unique] = true
                end
            end
        elseif message == "ghost_clusters_boss_breakout" then
            self.bossOut = true
            self._logger:info("Minigame", "Boss is out: guards first, then the boss")
        elseif message == "ghost_clusters_prop_progress" and type(a) == "string" then
            self.propProgress[a] = tonumber(b) or 0
        elseif message == "ghost_clusters_prop_resolved" and type(a) == "string" then
            self.haunted[a] = nil
            self.propsResolved += 1
        elseif message == "ghost_clusters_prop_restored" and type(a) == "string" then
            self.haunted[a] = nil
        elseif message == "ghost_clusters_score" and tonumber(a) then
            self.score += tonumber(a)
            self.scoreCount += 1
            self.lastScoreAt = now
        elseif message == "leave_game" then
            local candy = 0
            if type(a) == "table" and type(a.rewards) == "table" then
                for _, reward in pairs(a.rewards) do
                    if type(reward) == "table" and reward.kind == GameConstants.DataKeys.Candy then
                        candy += tonumber(reward.amount) or 0
                    end
                end
            end
            self.leave = { candy = candy, results = type(a) == "table" and a.results or nil, at = now }
            self._logger:info("Minigame", string.format("Round over: %d points from %d hits, reward %d candy", self.score,
                self.scoreCount, candy))
            self._logger:info("Minigame", "Round result: " .. Util.truncate(short(a) .. " | " .. short(b), 400))
        end
    end
    function Minigame:activeSession()
        if self.leave then return nil end
        local id = self.join and self.join.gameId or self._sessionId
        if type(id) ~= "string" or string.sub(id, 1, #GameConstants.Event.MinigameId + 2) ~= GameConstants.Event.MinigameId .. "::" then return nil end
        local untilTime = self.enter and self.enter.endTime
        if untilTime and (untilTime ~= untilTime or untilTime == math.huge or Minigame.serverNow() > untilTime + 20) then return nil end
        local at = self.join and self.join.at or self.enter and self.enter.at or self._sessionSeenAt
        if not at or Util.now() - at > 300 then return nil end
        return id
    end
    function Minigame:start(maid)
        local folder = ReplicatedStorage:FindFirstChild(GameConstants.Remotes.Folder)
        local remote = folder and folder:FindFirstChild(GameConstants.Remotes.MinigameMessage)
        if not (remote and remote:IsA("RemoteEvent")) then
            self._logger:warn("Minigame", GameConstants.Remotes.MinigameMessage .. " not found: Ghost Gallery is off")
            return false
        end
        maid:Give(remote.OnClientEvent:Connect(function(...)
            local ok, err = pcall(self._onMessage, self, ...)
            if not ok then
                self._logger:debug("Minigame", "message not understood: " .. tostring(err))
            end
        end))
        self.available = true
        return true
    end
    return Minigame
end
__moduleSources["Game/Hauntlet"] = function(...)
    --[[
        Game/Hauntlet (v2.1.2: Hauntlet 2 solver)
        STATE READER. Everything comes from MinigameAPI/MessageClient, the server's messages to me (verified in a
        recorded run, hauntlet_recv.log, 2026-10-10):
          join_accepted (n)                         queued
          join_minigame (interior, session)         the run's interior + session id
          enter_game ({ serialized_runners = { [userId] = { health, max_health, temp_health, inventory } } })
          started_room ({ area_kind, kind, doors = { { kind, grey_locks, gold_locks } x3 } }, serverTime, { [userId] = true })
          revealed_ghost (door)                     a phone (anyone's) shows the ghost's door; in the log it was right 3 of 3
          used_item (item, ok)                      the answer to MY item use
          grey_locks_removed ({ door })
          door_counters_updated ({ n1, n2, n3 })    players standing in each door's circle
          picked_door (true)                        my pick was taken; the next counter update shows which door
          doors_opened ({ 1 = ghost per door }, { [userId] = damage }, { items I got })
          temp_health_gained (userId, n)
          health_restored (userId)                  my red potion filled my hearts (live run 6)
          door_effect_triggered (userId, door, effect)  "transform" when someone enters a copycat door (live run 6)
          kicked_from_game (reason)                 "died"
          leave_game ({ rewards, results }, { finished_game, completed_game })
        After the first room every recorded room had exactly ONE ghost door, so a revealed ghost makes the other doors
        safe. Nothing tells the ghost's door before that (started_room has no ghost data; ClientData only keeps stats).
        DECIDER: Hauntlet.decide(view, options) is pure and explains every door (tested with recorded fixtures).
    ]]
    local import = ...
    local Util = import("Core/Util")
    local GameConstants = import("Game/GameConstants")
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local Hauntlet = {}
    Hauntlet.__index = Hauntlet
    Hauntlet.DEFAULTS = {
        revealWaitSeconds = 5, -- ghost unknown, no phone / wand of my own, other players in the run: wait for their phone
        planSeconds = 5, -- v2.1.4 (user: "plan 5 s, not 10"): the plan phase of a room: items + waiting for a phone
        commitBySeconds = 10, -- ... and by this second I stand in a door's circle, whatever is still open
        slotStart = 1, -- squad turns for the shared items: member n from slotStart + (n - 1) x slotGap
        slotGap = 0.6, -- 9 accounts: every phone used by ~6 s
        potionReserve = 1, -- keep this many ghost potions ...
        reserveBreakRisk = 0.05, -- ... unless the door is this likely a ghost, or a hit would leave 1 heart or less
        redPotionMissing = 2, -- the red potion fills every missing heart: wait for 2 missing unless a hit is dangerous
        preferLockedWhenSafe = true, -- the ghost is known elsewhere: spend a key on a locked door (the richer path)
        -- user 2026-10-10: "use the items much more, the heart ones above all; lower the risk to the minimum before
        -- every door; some ghosts take 2 hearts"
        phoneAtRisk = 0.01, -- my phone whenever the door I would take is not verified safe
        wandAtRisk = 0.15, -- the wand when that door is still this likely a ghost (any risk when a hit can end the run)
        potionAtRisk = 0.01, -- ghost potions before every door that is not verified safe
        tempHearts = 1, -- ghost potions: this many temp hearts before a risky door ...
        tempHeartsLate = 2, -- ... and this many from multiGhostFromRoom on, or when 2 red hearts or less are left
        multiGhostFromRoom = 8, -- from here: 2 ghosts in a room, ghosts that take 2 hearts (live runs 3 + 6)
        -- v2.1.5 (debug run 2026-10-11: 4 ghost potions spent in rooms 3, 4 and 9 at 3/3 hearts, then rooms 21-26
        -- had no potion left and the run died; ghost potions stopped dropping after room 9): before saveUntilRoom
        -- the stack keeps saveReserve potions, and a door under saveLowRisk gets none while a hit cannot kill
        saveUntilRoom = 16,
        saveReserve = 2,
        saveLowRisk = 0.1,
        safeFirstRoom = true, -- room 1 never had a ghost in any recorded run
        kindPenalty = {}, -- door kind -> extra score
    }
    function Hauntlet.new(logger, userId)
        local self = setmetatable({}, Hauntlet)
        self._logger = logger
        self._userId = userId and tostring(userId) or nil
        self:reset()
        return self
    end
    function Hauntlet:reset()
        self.joinAcceptedAt = nil
        self.join = nil
        self.sessionAcceptedAt = nil
        self.enter = nil
        self.room = nil
        self.roomSeq = 0
        self.roomsOpened = 0
        self.revealedGhost = nil
        self.lastReveal = nil
        self._heartDumps, self._heartSign = 0, nil
        self.lastPickSeq, self.lastPickAt = nil, nil
        self.usedItems = {}
        self.usedSeq = 0
        self.picked = nil
        self.inventory = {}
        self.health, self.maxHealth, self.tempHealth = nil, nil, 0
        self.ghostShield = false
        self.kicked, self.kickedAt = nil, nil
        self.leave = nil
        self.counters = { 0, 0, 0, 0 }
        self.myDoor, self.myDoorAt = nil, nil
        self._awaitPick = false
        self.lastOpened = nil
        self.history = {}
        -- v2.1.3 squad: every runner's hearts (enter_game, then the broadcast damage / temp / restore messages), the
        -- door I am moving to (my pick = that circle; the counters are shared and lie when several players move), and
        -- the script users of this run (the relay's /squad answer; nil = everyone alive counts)
        self.runners = {}
        self.expectDoor, self.expectAt = nil, nil
        self.pickedAt = nil
        self.mappingSuspect = nil
        self.revealedAt = nil
        self.squadIds = nil
        self._squadAsked = {}
    end
    local function isMine(gameKey)
        local id = GameConstants.Event.HauntletId
        return type(gameKey) == "string" and (gameKey == id or string.sub(gameKey, 1, #id + 2) == id .. "::")
    end
    Hauntlet._isMine = isMine
    local function addItems(inventory, list)
        if type(list) ~= "table" then
            return
        end
        for k, v in pairs(list) do
            if type(v) == "string" then
                inventory[v] = (inventory[v] or 0) + 1
            elseif type(k) == "string" and tonumber(v) then
                inventory[k] = (inventory[k] or 0) + tonumber(v)
            end
        end
    end
    function Hauntlet:_damage(amount)
        amount = tonumber(amount) or 0
        if amount <= 0 or not self.health then
            return
        end
        local fromTemp = math.min(self.tempHealth, amount)
        self.tempHealth -= fromTemp
        self.health = math.max(0, self.health - (amount - fromTemp))
        if fromTemp > 0 then
            self.ghostShield = self.tempHealth > 0
        end
    end
    function Hauntlet:hearts()
        return (self.health or 3) + (self.tempHealth or 0)
    end
    -- other runners' hearts: kept for this run only, to agree on who spends a shared item first (squadOrder)
    function Hauntlet:_runnerDamage(id, amount)
        local r = self.runners[id]
        if not r or amount <= 0 then
            return
        end
        local fromTemp = math.min(r.temp, amount)
        r.temp -= fromTemp
        r.health = math.max(0, r.health - (amount - fromTemp))
    end
    -- the same numbers on every account (from the broadcast messages only, mine included), taken when started_room
    -- arrives: so every account sorts the squad the same way for the whole room
    function Hauntlet:heartsOf(id)
        id = tostring(id)
        local snap = self.room and self.room.heartSnap
        if snap and snap[id] then
            return snap[id]
        end
        local r = self.runners[id]
        return r and (r.health + r.temp) or 3
    end
    --[[
        SQUAD (v2.1.3, user 2026-10-10: "stop playing solo runs: win the run with several accounts"). A phone's answer
        (revealed_ghost), an opened lock and (probably) a wand help EVERY player of the room, so one of each is enough
        for the whole squad. No message between the accounts is needed for that: every account sees the same server
        messages and sorts the squad the same way (fewest hearts first: those are the likeliest to die with items still
        in their pocket, so they spend theirs first; then the lower user id). Member n may spend a shared item only
        from its turn on: start + (n - 1) x gap seconds into the room; one that has none simply lets its turn pass.
        Squad = the script users of this run (the relay's /squad answer), else every player still alive.
    ]]
    Hauntlet.SHARED_ITEMS = { cell_phone = true, rainbow_wand = true, key = true, gold_key = true }
    function Hauntlet:squadOrder()
        local room = self.room or {}
        local members, seen = {}, {}
        local listed = self.squadIds
        for id in pairs(room.alive or {}) do
            id = tostring(id)
            if not seen[id] and (listed == nil or listed[id] or id == self._userId) then
                seen[id] = true
                table.insert(members, id)
            end
        end
        if self._userId and not seen[self._userId] then
            table.insert(members, self._userId)
        end
        -- equal hearts: an order mixed by the run's session id (the same on every account), not by user id. By user id
        -- the same account was always the last one (user 2026-10-11: "Chrollo is always the one that gets the
        -- highest"): the last one waits for everyone's phone and keeps its own items, the first ones take the risk.
        local salt = tostring(self.join and self.join.sessionId or "")
        local function mix(id)
            local hash = 5381
            local text = salt .. "|" .. id
            for i = 1, #text do
                hash = (hash * 33 + string.byte(text, i)) % 2147483647
            end
            return hash
        end
        table.sort(members, function(x, y)
            local hx, hy = self:heartsOf(x), self:heartsOf(y)
            if hx ~= hy then
                return hx < hy
            end
            local mx, my = mix(x), mix(y)
            if mx ~= my then
                return mx < my
            end
            return (tonumber(x) or 0) < (tonumber(y) or 0)
        end)
        local rank = 1
        for i, id in ipairs(members) do
            if id == self._userId then
                rank = i
            end
        end
        return members, rank
    end
    -- Seconds into the room from which I may spend this shared item. Phones first (they decide everything else), the
    -- wand when no phone answered, keys once the ghost is known (or when nobody could tell): never later than the
    -- point where the doors must be chosen.
    function Hauntlet:turnAt(item, rank, strategy)
        local function opt(key)
            local value = strategy and strategy[key]
            if value == nil then
                value = Hauntlet.DEFAULTS[key]
            end
            return tonumber(value) or 0
        end
        local start, gap, plan = opt("slotStart"), opt("slotGap"), opt("planSeconds")
        local base = start
        if item == "rainbow_wand" then
            base = math.max(start, plan - 3)
        elseif item == "key" or item == "gold_key" then
            local room = self.room
            local knownAt = self.revealedAt and room and (self.revealedAt - room.at) or nil
            base = (room and room.safe) and start or (knownAt and math.max(start, knownAt + 0.3)) or math.max(start, plan - 2)
        end
        return math.min(base + (math.max(1, rank) - 1) * gap, opt("commitBySeconds") - 2.5)
    end
    -- The relay's /squad (same worker as the developer logs), only with the private squad key: my user id + the run's
    -- session id in, the user ids of the accounts with the same key in the same run back. Three calls a run at most.
    function Hauntlet:setSquadRelay(url, keyOf)
        self._squadUrl = nil
        self._squadKeyOf = nil
        self._request = nil
    end
    function Hauntlet:_squadKey() return nil end
    function Hauntlet:askSquad(why) return end
    local KNOWN = {
        join_accepted = true, join_minigame = true, enter_game = true, started_room = true, revealed_ghost = true,
        used_item = true, grey_locks_removed = true, door_counters_updated = true, picked_door = true, doors_opened = true,
        temp_health_gained = true, kicked_from_game = true, leave_game = true, gained_items = true,
        all_locks_removed = true, max_health_gained = true, health_restored = true, door_effect_triggered = true,
        ghosts_dispelled = true,
    }
    function Hauntlet:_onMessage(gameKey, message, a, b, c)
        if not isMine(gameKey) then
            return
        end
        if self.debugLines then
            local parts = {}
            for _, value in ipairs({ a, b, c }) do
                local text = type(value) == "table" and (Util.jsonEncode(value) or "{?}") or tostring(value)
                table.insert(parts, Util.truncate(text, 400))
            end
            table.insert(self.debugLines, string.format("%7.1f RECV %s | %s", Util.now() - (self.debugStart or 0),
                tostring(message), table.concat(parts, " | ")))
        end
        if type(message) == "string" and not KNOWN[message] then
            self._seenTypes = self._seenTypes or {}
            if not self._seenTypes[message] then
                self._seenTypes[message] = true
                self._logger:info("Hauntlet", "New message type: " .. message)
            end
        end
        local now = Util.now()
        local isSession = gameKey ~= GameConstants.Event.HauntletId
        if message == "join_accepted" then
            if isSession then
                self.sessionAcceptedAt = now
            else
                self.joinAcceptedAt = now
            end
        elseif message == "join_minigame" and type(b) == "string" then
            self.join = { interior = a, sessionId = b, at = now }
            self._logger:info("Hauntlet", "Run starting: " .. b)
            self:_debugStart(b, a)
            self:askSquad("join")
        elseif message == "enter_game" and type(a) == "table" then
            self.enter = { at = now }
            local runners = type(a.serialized_runners) == "table" and a.serialized_runners or {}
            self.runners = {}
            for id, runner in pairs(runners) do
                if type(runner) == "table" then
                    self.runners[tostring(id)] = { health = tonumber(runner.health) or 3,
                        maxHealth = tonumber(runner.max_health) or 3, temp = tonumber(runner.temp_health) or 0 }
                end
            end
            local me = self._userId and (runners[self._userId] or runners[tonumber(self._userId)])
            if type(me) == "table" then
                self.health = tonumber(me.health) or 3
                self.maxHealth = tonumber(me.max_health) or 3
                self.tempHealth = tonumber(me.temp_health) or 0
                self.inventory = {}
                addItems(self.inventory, me.inventory)
            end
        elseif message == "started_room" and type(a) == "table" then
            self.ejected = nil -- pushed-out doors count per room
            local doors = {}
            for i = 1, 4 do
                local d = type(a.doors) == "table" and a.doors[i] or nil
                -- a nexus room's doors are areas: { area_kind = "copycat" } (debug log 2026-10-10)
                local kind = type(d) == "table" and (d.kind and tostring(d.kind)
                    or (d.area_kind and ("area:" .. tostring(d.area_kind)))) or "unknown"
                doors[i] = {
                    exists = type(d) == "table",
                    kind = kind,
                    gold = type(d) == "table" and tonumber(d.gold_locks) or 0,
                    grey = type(d) == "table" and tonumber(d.grey_locks) or 0,
                }
                doors[i].wasLocked = doors[i].gold + doors[i].grey > 0 -- a key opened it: still the richer path
            end
            self.roomSeq += 1
            local alive = {}
            for id, flag in pairs(type(c) == "table" and c or {}) do
                if flag then
                    alive[tostring(id)] = true
                end
            end
            if self.room then -- the room that just ended, for its digest line
                self.lastReveal = { seq = self.room.seq, door = self.revealedGhost,
                    at = self.revealedAt and (self.revealedAt - self.room.at) or nil, safe = self.room.safe }
            end
            self.room = { area = a.area_kind, kind = a.kind, doors = doors, at = now, seq = self.roomSeq,
                startServer = tonumber(b), alive = alive, safe = false, lockVersion = 0 }
            -- v2.1.4 (debug log 2026-10-11, room 47: "died" from a 2-heart hit while the bot counted 4 red + 4 temp
            -- hearts): temp hearts are not kept from room to room the way they were counted. Counted per room now,
            -- so the bot drinks a ghost potion again before every risky door (and the red potion sees the lost hearts).
            self.tempHealth = 0
            for _, r in pairs(self.runners) do
                r.temp = 0
            end
            self.revealedGhost, self.revealedAt = nil, nil
            self.expectDoor, self.expectAt, self.pickedAt, self.mappingSuspect = nil, nil, nil, nil
            local snap = {}
            for id, r in pairs(self.runners) do
                snap[id] = r.health + r.temp
            end
            self.room.heartSnap = snap
            if self.roomSeq == 2 then
                self:askSquad("room 2") -- late registrations
            end
            self.picked = nil
            self.counters = { 0, 0, 0, 0 }
            self.myDoor, self.myDoorAt = nil, nil
            self._awaitPick = false
            self.ghostShield = (self.tempHealth or 0) > 0
            if self.debugLines then
                local interior = self.join and self.join.interior
                -- the heart display, for the room-1 baseline and whenever my counted hearts changed (8 dumps a run)
                local sign = tostring(self.health) .. "/" .. tostring(self.maxHealth)
                -- v2.1.5: the heart display dump only with Event.HauntletDebug (hearts are counted right now; it scanned
                -- every screen and lagged phones running many accounts)
                local dumpHearts = GameConstants.Event.HauntletDebug == true and (self._heartDumps or 0) < 8
                    and (self.roomSeq <= 1 or sign ~= self._heartSign)
                self._heartSign = sign
                task.delay(1.5, function()
                    self:_debugNote(Hauntlet.describeRooms(interior))
                    if dumpHearts then
                        self._heartDumps = (self._heartDumps or 0) + 1
                        self:_debugNote("counted hearts " .. sign .. " (room " .. tostring(self.roomSeq) .. ") | "
                            .. Hauntlet.describeHeartUi())
                    end
                    self:_debugFlush()
                end)
            end
        elseif message == "gained_items" then
            addItems(self.inventory, a) -- e.g. the run's starting items: { "cell_phone", "key", "ghost_potion", "gold_potion" }
        elseif message == "revealed_ghost" and tonumber(a) then
            self.revealedGhost = tonumber(a)
            self.revealedAt = now
        elseif message == "used_item" and type(a) == "string" then
            self.usedSeq += 1
            self.usedItems[self.usedSeq] = { item = a, ok = b == true }
            if b == true then
                self.inventory[a] = math.max(0, (self.inventory[a] or 1) - 1)
                if a == "red_potion" and self.maxHealth then
                    self.health = self.maxHealth -- fills the missing red hearts
                elseif a == "gold_potion" and self.health then
                    self.maxHealth = (self.maxHealth or 3) + 1 -- one more red heart; empty ones stay empty
                    self.health += 1
                elseif a == "ghost_potion" then
                    self.ghostShield = true -- temp_health_gained adds the heart itself
                elseif a == "rainbow_wand" and self.room then
                    self.room.safe = true -- every ghost of this room is gone
                end
            elseif a == "ghost_potion" and (self.tempHealth or 0) > 0 then
                -- refused while a temp heart is on: they do not stack (the potion is still mine)
                Hauntlet.learnedTempCap = math.max(Hauntlet.learnedTempCap or 0, self.tempHealth, 2)
            else
                self.inventory[a] = 0
            end
        elseif message == "ghosts_dispelled" and self.room then
            -- v2.1.3: someone's rainbow wand (19 times in the reports; the wand room had no ghost): the room is safe for
            -- everyone, not only for the one who used it
            self.room.safe = true
            self.room.dispelledAt = now
            if self.debugLines then
                self:_debugNote("ghosts_dispelled: room " .. tostring(self.room.seq))
            end
        elseif message == "all_locks_removed" and type(a) == "table" and self.room then
            -- live run 5: a gold key's answer (the door stayed "locked" and the bot took a 75 % door instead)
            for _, i in pairs(a) do
                local d = self.room.doors[tonumber(i) or 0]
                if d then
                    d.grey, d.gold = 0, 0
                end
            end
            self.room.lockVersion = (self.room.lockVersion or 0) + 1
        elseif message == "grey_locks_removed" and type(a) == "table" and self.room then
            for _, i in pairs(a) do
                local d = self.room.doors[tonumber(i) or 0]
                if d then
                    d.grey = math.max(0, d.grey - 1)
                end
            end
            self.room.lockVersion = (self.room.lockVersion or 0) + 1
        elseif message == "door_counters_updated" and type(a) == "table" then
            local new = {}
            for i = 1, 4 do
                new[i] = tonumber(a[i]) or 0
            end
            -- v2.1.3 (user: "one alt used an item and another one still went to the ghost door"): the counters are
            -- everyone's. Several of my accounts move at once, so "the one door that went up" was often another
            -- player's door (-> "Door mapping WRONG" / "no pick seen" -> the bot jumped to another circle). Now my door
            -- is the circle I moved into (expectDoor); the counters only add evidence when they cannot be someone else's.
            local up, gained, lost = {}, 0, 0
            for i = 1, 4 do
                local delta = new[i] - (self.counters[i] or 0)
                if delta > 0 then
                    table.insert(up, i)
                    gained += delta
                elseif delta < 0 then
                    lost -= delta
                end
            end
            -- v2.1.6 (log of an alt left at the last room's door: it moved into the OLD room's circle, the counter of
            -- that door number went up because the other alts walked into the new room's circle, the bot took that
            -- for its own pick and stood still until "out_of_time"): once the game is seen sending picked_door, only
            -- picked_door says that I picked
            if not Hauntlet.pickedDoorSeen and self.expectDoor and self.expectAt
                and (new[self.expectDoor] or 0) > (self.counters[self.expectDoor] or 0)
                and not (self.myDoorAt and self.myDoorAt >= self.expectAt) then
                self.myDoor, self.myDoorAt = self.expectDoor, now -- my door went up after my move
            end
            -- v2.1.5 (user report: "several bots on a mystery door, it turns out to be a key door, the bot never picks
            -- another door and gets kicked"): my door's counter fell to 0 while the doors are still shut = I was pushed
            -- out of that circle. Forget the pick so the room loop moves again (and scores that door down).
            -- only after that door transformed (a ??? door): a counter update that merely reads 0 (late / reordered,
            -- many accounts on one device) must never send me back to look for a door again
            local mine = self.myDoor
            local transformedAt = mine and self.room and type(self.room.transformed) == "table" and self.room.transformed[mine]
            if mine and transformedAt and self.myDoorAt and now - self.myDoorAt > 0.3 and (self.counters[mine] or 0) > 0
                and (new[mine] or 0) == 0 and not (self.lastOpened and self.lastOpened.seq == self.roomSeq) then
                self.ejected = self.ejected or {}
                self.ejected[mine] = (self.ejected[mine] or 0) + 1
                self.myDoor, self.myDoorAt = nil, nil
                self._logger:info("Hauntlet", string.format("Pushed out of door %d (its counter fell to 0, the doors are "
                    .. "still shut): picking again", mine))
            end
            if self._awaitPick then
                -- unambiguous only when exactly one player moved (one +1, at most my own -1 elsewhere)
                if #up == 1 and gained == 1 and lost <= 1 and self.expectDoor and up[1] ~= self.expectDoor then
                    self.mappingSuspect = up[1]
                end
                self._awaitPick = false
            end
            self.counters = new
        elseif message == "picked_door" then
            self.picked = a == true
            if a == true then
                Hauntlet.pickedDoorSeen = true
                self._awaitPick = true
                self.pickedAt = now
                self.pickedSeq = self.room and self.room.seq
                -- kept through started_room (which clears pickedAt): the room loop reads them after the next room began
                self.lastPickSeq, self.lastPickAt = self.pickedSeq, now
                if self.expectDoor then
                    self.myDoor, self.myDoorAt = self.expectDoor, now
                end
            end
        elseif message == "doors_opened" then
            self.roomsOpened += 1
            local damage = 0
            if type(b) == "table" and self._userId then
                damage = tonumber(b[self._userId] or b[tonumber(self._userId)]) or 0
                self:_damage(damage)
                for id, amount in pairs(b) do
                    self:_runnerDamage(tostring(id), tonumber(amount) or 0)
                end
            end
            addItems(self.inventory, c)
            local ghosts = {}
            for i = 1, 4 do
                ghosts[i] = type(a) == "table" and (tonumber(a[i]) or 0) > 0 or false
            end
            local room = self.room
            self.lastOpened = { seq = self.roomSeq, ghosts = ghosts, myDoor = self.myDoor, damage = damage,
                items = type(c) == "table" and c or {} }
            table.insert(self.history, { seq = self.roomSeq, area = room and room.area,
                kinds = room and { room.doors[1].kind, room.doors[2].kind, room.doors[3].kind } or {},
                ghosts = ghosts, revealed = self.revealedGhost, myDoor = self.myDoor, damage = damage })
        elseif message == "temp_health_gained" and a ~= nil then
            if self._userId and tostring(a) == self._userId then
                self.tempHealth += tonumber(b) or 0
            end
            local r = self.runners[tostring(a)] -- every runner the same way (mine too): the squad order must agree
            if r then
                r.temp += tonumber(b) or 0
            end
        elseif message == "health_restored" and a ~= nil then
            if self._userId and tostring(a) == self._userId then
                self.health = self.maxHealth or self.health -- live run 6: the red potion's answer
            end
            local r = self.runners[tostring(a)]
            if r then
                r.health = r.maxHealth
            end
        elseif message == "max_health_gained" and a ~= nil then
            local r = self.runners[tostring(a)]
            if r then -- a gold potion (mine is also counted from used_item, in self.health)
                r.maxHealth += 1
                r.health += 1
            end
        elseif message == "door_effect_triggered" and self.room then
            self.room.effects = self.room.effects or {}
            self.room.effects[tonumber(b) or 0] = tostring(c)
            if tostring(c) == "transform" then
                self.room.transformed = self.room.transformed or {}
                self.room.transformed[tonumber(b) or 0] = now
                self._logger:info("Hauntlet", "The ??? door " .. tostring(b) .. " transformed (someone stepped in)")
            end
            if tostring(c) == "player_take_damage" then -- the electric door: 1 heart on entering (was not counted)
                if self._userId and tostring(a) == self._userId then
                    self:_damage(1)
                end
                local r = self.runners[tostring(a)]
                if r then
                    local fromTemp = math.min(r.temp, 1)
                    r.temp -= fromTemp
                    r.health = math.max(0, r.health - (1 - fromTemp))
                end
            end
        elseif message == "kicked_from_game" then
            self.kicked = tostring(a)
            self.kickedAt = now
            if self._userId and self.runners[self._userId] then
                self.runners[self._userId].health = 0
            end
            self._logger:info("Hauntlet", "Kicked from the run: " .. tostring(a) .. " (room " .. self.roomSeq .. ")")
        elseif message == "leave_game" then
            local candy, results = 0, {}
            if type(a) == "table" and type(a.rewards) == "table" then
                for _, reward in pairs(a.rewards) do
                    if type(reward) == "table" and reward.kind == GameConstants.DataKeys.Candy then
                        candy += tonumber(reward.amount) or 0
                    end
                end
            end
            if type(a) == "table" and type(a.results) == "table" then
                for _, r in pairs(a.results) do
                    if type(r) == "table" and type(r.title) == "string" then
                        results[r.title] = tonumber(r.value)
                    end
                end
            end
            self.leave = {
                candy = candy,
                roomReached = results["ROOM REACHED"],
                best = results["ALL TIME BEST"],
                plays = results["TOTAL PLAYS"],
                completed = type(b) == "table" and b.completed_game == true,
                at = now,
            }
            self._logger:info("Hauntlet", string.format("Run over: room %s, reward %d candy", tostring(self.leave.roomReached), candy))
            self:_debugStop()
        end
        if message == "doors_opened" then
            self:_debugFlush()
        end
    end
    --[[
        DEBUG RECORDER (Event.HauntletDebug = true): from join_minigame to leave_game, whoever plays (the bot or me):
        every server message, every [Hauntlet] line of the bot, and after each started_room the run's room models
        (which one is new, how far, the newest one's layout). Disk recording removed in this build.
    ]]
    Hauntlet.DEBUG_FILE = "AdoptMeFarm/hauntlet_debug.log"
    function Hauntlet:_debugStart(sessionId, interiorName)
        return -- Private build does not record Hauntlet sessions to files
    end
    function Hauntlet:_debugNote(text)
        if self.debugLines then
            table.insert(self.debugLines, string.format("%7.1f %s", Util.now() - (self.debugStart or 0), tostring(text)))
        end
    end
    function Hauntlet:_debugFlush()
        return -- Diagnostics remain in memory, never on disk.
    end
    function Hauntlet:_debugStop()
        if not self.debugLines then
            return
        end
        self:_debugFlush()
        pcall(function()
            self._debugConn:Disconnect()
        end)
        self.debugLines, self._debugConn = nil, nil
    end
    -- The run's room models: each one's number (first seen order), name and distance; the newest one's layout.
    local roomIds = setmetatable({}, { __mode = "k" })
    local nextRoomId = 0
    -- v2.1.4 (user: "read the hearts straight from the game"): the game's own heart display is not known yet. This
    -- dumps what could show it (the Hauntlet UI in PlayerGui, the player's / character's attributes, Hauntlet modules),
    -- into the debug file only, so the heart reader can be written from a real run. Read-only.
    -- v2.1.4 (debug log 2026-10-11): the game's own item bar, MinigameHotbarApp.Hotbar.<item> (Frame hidden at 0) with
    -- Button.StackCount.TextLabel "x<n>". The truth about my run items (a webbed door takes one without a message I
    -- read). Returns { [item] = n } or nil when the bar is not there. Read-only.
    function Hauntlet.readHotbar()
        local counts
        pcall(function()
            local gui = game:GetService("Players").LocalPlayer:FindFirstChildOfClass("PlayerGui")
            local app = gui and gui:FindFirstChild("MinigameHotbarApp")
            local bar = app and app.Enabled ~= false and app:FindFirstChild("Hotbar")
            if not bar then
                return
            end
            local found = {}
            for item in pairs(GameConstants.Event.HauntletItems or {}) do
                local frame = bar:FindFirstChild(item)
                if frame then
                    local label = frame:FindFirstChild("Button") and frame.Button:FindFirstChild("StackCount")
                        and frame.Button.StackCount:FindFirstChild("TextLabel")
                    local n = label and tonumber(string.match(tostring(label.Text), "(%d+)"))
                    if n == nil then
                        return -- an unknown layout: trust nothing from it
                    end
                    found[item] = frame.Visible == false and 0 or n
                end
            end
            if next(found) then
                counts = found
            end
        end)
        return counts
    end
    function Hauntlet.describeHeartUi()
        local lines, budget = {}, 260
        local function add(text)
            if budget > 0 then
                budget -= 1
                table.insert(lines, text)
            end
        end
        pcall(function()
            local player = game:GetService("Players").LocalPlayer
            local function attrs(label, inst)
                local ok, list = pcall(function()
                    return inst:GetAttributes()
                end)
                if ok and type(list) == "table" and next(list) ~= nil then
                    local parts = {}
                    for k, v in pairs(list) do
                        table.insert(parts, tostring(k) .. "=" .. Util.truncate(tostring(v), 40))
                    end
                    table.sort(parts)
                    add("ATTR " .. label .. ": " .. table.concat(parts, ", "))
                end
            end
            attrs("player", player)
            if player.Character then
                attrs("character", player.Character)
            end
            for _, node in ipairs(player.Character and player.Character:GetDescendants() or {}) do
                if node:IsA("BillboardGui") or node:IsA("SurfaceGui") or (node:IsA("TextLabel") and node:FindFirstAncestorWhichIsA("BillboardGui"))
                    or (node:IsA("ImageLabel") and node:FindFirstAncestorWhichIsA("BillboardGui")) then
                    local extra = ""
                    pcall(function()
                        if node:IsA("TextLabel") then
                            extra = " text=" .. Util.truncate(tostring(node.Text), 30)
                        elseif node:IsA("ImageLabel") then
                            extra = " vis=" .. tostring(node.Visible) .. " img=" .. tostring(node.Image)
                        end
                    end)
                    add("CHAR " .. string.gsub(node:GetFullName(), "^.-Workspace%.", "") .. " [" .. node.ClassName .. "]" .. extra)
                end
            end
            local gui = player:FindFirstChildOfClass("PlayerGui")
            -- every screen first (log 2026-10-11: the journal used the whole budget, the heart display was not reached)
            local screens = {}
            for _, child in ipairs(gui and gui:GetChildren() or {}) do
                local on = true
                pcall(function()
                    on = child.Enabled ~= false
                end)
                table.insert(screens, child.Name .. (on and "" or "(off)"))
            end
            table.sort(screens)
            add("SCREENS " .. table.concat(screens, ", "))
            for _, node in ipairs(gui and gui:GetDescendants() or {}) do
                local path = node:GetFullName()
                local lower = string.lower(path)
                local noise = string.find(lower, "journalapp", 1, true) or string.find(lower, "exitbutton", 1, true)
                    or string.find(lower, "xboxbutton", 1, true)
                if not noise and (string.find(lower, "aunt") or string.find(lower, "heart") or string.find(lower, "health")
                    or string.find(lower, "minigame") or string.find(lower, "lives") or string.find(lower, "potion")) then
                    local extra = ""
                    pcall(function()
                        if node:IsA("GuiObject") then
                            extra ..= " vis=" .. tostring(node.Visible)
                        end
                        if node:IsA("ImageLabel") or node:IsA("ImageButton") then
                            extra ..= " img=" .. tostring(node.Image) .. " transp=" .. tostring(node.ImageTransparency)
                                .. " color=" .. tostring(node.ImageColor3)
                        elseif node:IsA("TextLabel") or node:IsA("TextButton") then
                            extra ..= " text=" .. Util.truncate(tostring(node.Text), 40)
                        elseif node:IsA("ValueBase") then
                            extra ..= " value=" .. Util.truncate(tostring(node.Value), 40)
                        end
                    end)
                    add("UI " .. string.gsub(path, "^.-PlayerGui%.", "") .. " [" .. node.ClassName .. "]" .. extra)
                end
            end
            local count = 0
            for _, node in ipairs(game:GetService("ReplicatedStorage"):GetDescendants()) do
                if count < 25 and node:IsA("ModuleScript") and string.find(string.lower(node.Name), "aunt") then
                    count += 1
                    add("MODULE " .. node:GetFullName())
                end
            end
        end)
        if #lines == 0 then
            return "HEART UI: nothing found"
        end
        return "HEART UI (" .. #lines .. " lines):\n  " .. table.concat(lines, "\n  ")
    end
    function Hauntlet.describeRooms(interiorName)
        local lines = {}
        local ok, err = pcall(function()
            local interiors = workspace:FindFirstChild("Interiors")
            local interior = interiors and type(interiorName) == "string" and interiors:FindFirstChild(interiorName)
            local rooms = interior and interior:FindFirstChild("Rooms")
            if not rooms then
                table.insert(lines, "ROOMS: no Rooms folder (interior " .. tostring(interiorName) .. ")")
                return
            end
            local character = game:GetService("Players").LocalPlayer.Character
            local root = character and character:FindFirstChild("HumanoidRootPart")
            local list, newest, newestId = {}, nil, -1
            for _, room in ipairs(rooms:GetChildren()) do
                if not roomIds[room] then
                    nextRoomId += 1
                    roomIds[room] = nextRoomId
                end
                local dist = "?"
                pcall(function()
                    dist = tostring(math.floor((room:GetPivot().Position - root.Position).Magnitude))
                end)
                table.insert(list, string.format("#%d %s %s studs", roomIds[room], room.Name, dist))
                if roomIds[room] > newestId then
                    newest, newestId = room, roomIds[room]
                end
            end
            table.insert(lines, "ROOMS: " .. table.concat(list, ", "))
            if newest then
                local parts = {}
                for _, child in ipairs(newest:GetChildren()) do
                    local names = {}
                    local kids = child:GetChildren()
                    if #kids <= 40 then
                        for _, kid in ipairs(kids) do
                            if #names < 8 then
                                table.insert(names, kid.Name)
                            end
                        end
                    end
                    table.insert(parts, child.Name .. "(" .. child.ClassName .. (#names > 0 and (": " .. table.concat(names, ","))
                        or (#kids > 0 and (": " .. #kids .. " children") or "")) .. ")")
                end
                table.insert(lines, string.format("NEWEST ROOM #%d %s: %s", newestId, newest.Name, table.concat(parts, "; ")))
            end
        end)
        if not ok then
            table.insert(lines, "ROOMS: " .. tostring(err))
        end
        return table.concat(lines, "\n")
    end
    function Hauntlet:roomElapsed()
        return self.room and math.max(0, Util.now() - self.room.at) or 0
    end
    -- What the decider needs, as plain values. others = players still in the run besides me (their phones count).
    function Hauntlet:view()
        local room = self.room or {}
        local others = 0
        for id in pairs(room.alive or {}) do
            if tostring(id) ~= self._userId then
                others += 1
            end
        end
        return {
            seq = room.seq, area = room.area, doors = room.doors or {}, revealedGhost = self.revealedGhost,
            safe = room.safe == true, inventory = self.inventory, health = self.health or 3,
            maxHealth = self.maxHealth or 3, tempHealth = self.tempHealth or 0, shield = self.ghostShield == true,
            elapsed = self:roomElapsed(), others = others, tempCap = Hauntlet.learnedTempCap,
        }
    end
    --[[
        Door kinds (the game's HauntletDoorDB, dumped 2026-10-10 by the debug mode): ghost = ghost_weight (the room's
        one ghost goes behind a door with this weight: the risk of a door = its weight / the room's total), effect =
        what entering does, drops = the items one expects behind it. Read live from the game when possible; this copy
        is the fallback.
    ]]
    Hauntlet.DOOR_FALLBACK = {
        bouncy = { ghost = 80, effect = "player_bounce", drops = 1 },
        copycat = { ghost = 300, effect = "transform", drops = 0 }, -- the game says 0: see GHOST_OVERRIDE
        electric = { ghost = 30, effect = "player_take_damage", value = 1, drops = 1.3 },
        gold_locked = { ghost = 0, drops = 1 },
        locked = { ghost = 30, drops = 0.25 },
        nightmare = { ghost = 180, drops = 1.6 },
        rotten = { ghost = 120, drops = 0.9 },
        security = { ghost = 20, drops = 1.2 },
        shadow = { ghost = 150, drops = 1.3 },
        webbed = { ghost = 5, effect = "player_lose_item", value = 1, drops = 0.3 },
        wooden = { ghost = 90, drops = 0.45 },
    }
    --[[
        Live run 6 (2026-10-10): the game's list says copycat ("??? Door", enter effect "transform") ghost weight 0, but
        a ghost was behind 5 of the 6 copycat doors of rooms 11-18 (room 16: -2 hearts; room 18: both copycats, the
        death), and in those rooms a ghost was behind another door only once. The weight that fits: ~360. So a copycat
        door counts as the likeliest ghost door, whatever the game's list says.
    ]]
    Hauntlet.GHOST_OVERRIDE = {}
    --[[
        v2.1.3 MEASURED (717 rooms of the v2.1.3 room digests, 2026-10-10; which door had the ghost, rooms with ONE
        ghost, weights fitted so that risk = weight / the room's total; wooden = 90 as the scale): these replace the game's
        list for the kinds seen often enough. The game's list was off for shadow (150 -> ~255: 64 % of the shadow doors),
        copycat (300 -> ~70), electric (30 -> ~50); gold_locked and security never had a ghost.
    ]]
    Hauntlet.MEASURED_GHOST = { shadow = 255, rotten = 100, wooden = 90, bouncy = 85, copycat = 70, electric = 50,
        locked = 23, webbed = 5, security = 2, gold_locked = 0 }
    --[[
        How many ghosts a room has (same data): room 1 none; 2-7 one; 8 two in 78 %, 9 in 69 %; 11-15 one (the area after
        a nexus starts calm again); 16 56 %, 17 48 %, 18 53 %, 19 29 %; 21-23 one; 24 50 %, 25 33 %, 26-27 85 %, 28 67 %;
        later rooms: about 60 %, and from room 41 two or three. The chance of a second ghost per room:
    ]]
    Hauntlet.TWO_GHOSTS = { [8] = 0.8, [9] = 0.7, [16] = 0.6, [17] = 0.5, [18] = 0.55, [19] = 0.3, [24] = 0.5, [25] = 0.4,
        [26] = 0.85, [27] = 0.85, [28] = 0.7, [29] = 0.5 }
    function Hauntlet.twoGhostChance(seq)
        seq = tonumber(seq) or 0
        local known = Hauntlet.TWO_GHOSTS[seq]
        if known then
            return known
        end
        if seq < 30 then
            return seq <= 1 and 0 or 0.02 -- rooms 2-7, 11-15, 21-23: one ghost (a few % margin)
        end
        if seq >= 41 then
            return 0.95
        end
        return (seq % 10 == 1) and 0.2 or 0.6
    end
    -- the worst hit (same data): 1 heart before room 16 (2 hearts in 2 of 34 hits in rooms 8-9), 2 hearts from 16 on
    -- v2.1.5, 7 debug logs (~150 rooms): a ghost always takes exactly 1 heart; "2 hearts" was 2 ghosts behind the same
    -- door. Ghosts share a door in rooms 8-15 too (2 of 10 two-ghost rooms), in 47% from 16 and 68% from 30 (3 ghosts
    -- there): the worst hit is the number of ghosts that can stand behind one door
    function Hauntlet.worstHit(seq)
        seq = tonumber(seq) or 0
        return seq >= 30 and 3 or (seq >= 8 and 2 or 1)
    end
    -- Nexus: the next area's cost (its doors: copycat = ghost magnets (the other doors are then rather safe) and many
    -- locks, webbed 5 but an item each, wooden 90, bouncy 80 + a random launch, security 20 but 2 keys each, electric a
    -- sure heart each, nightmare 180).
    Hauntlet.AREA_COST = { spider = 4, hallway = 8, carnival = 10, laboratory = 12, copycat = 15, mechanical = 25,
        nightmare = 30 }
    local liveDoors
    function Hauntlet.doorInfo(kind)
        local area = type(kind) == "string" and string.match(kind, "^area:(.+)$")
        if area then
            return { ghost = 0, drops = 0, area = area, cost = Hauntlet.AREA_COST[area] or 15 }
        end
        if liveDoors == nil then
            liveDoors = false
            pcall(function()
                local node = ReplicatedStorage
                for _, name in ipairs(GameConstants.Event.HauntletDBPath) do
                    node = node and node:FindFirstChild(name)
                end
                local db = node and require(node:FindFirstChild("HauntletDoorDB"))
                if type(db) ~= "table" then
                    return
                end
                local list = {}
                for doorKind, entry in pairs(db) do
                    if type(entry) == "table" and tonumber(entry.ghost_weight) then
                        local total, expected = 0, 0
                        for key, weight in pairs(type(entry.drop_table) == "table" and entry.drop_table or {}) do
                            weight = tonumber(weight) or 0
                            total += weight
                            expected += (tonumber(string.match(tostring(key), ":(%d+)$")) or 0) * weight
                        end
                        list[tostring(doorKind)] = { ghost = tonumber(entry.ghost_weight), effect = entry.enter_effect,
                            value = tonumber(entry.enter_effect_value) or 1, drops = total > 0 and expected / total or 0 }
                    end
                end
                if next(list) then
                    liveDoors = list
                end
            end)
        end
        local info = (liveDoors and liveDoors[kind]) or Hauntlet.DOOR_FALLBACK[kind] or { ghost = 90, drops = 0.5 }
        local override = Hauntlet.MEASURED_GHOST[kind] or Hauntlet.GHOST_OVERRIDE[kind]
        if override and (tonumber(info.ghost) or 0) ~= override then
            local copy = {}
            for key, value in pairs(info) do
                copy[key] = value
            end
            copy.ghost = override
            info = copy
        end
        return info
    end
    --[[
        DECIDER. view = Hauntlet:view() + tried = { [item] = true } (items already tried in this room).
        Returns ONE next step:
          { use = item, door = n?, reason }     use a run item first (door = the door a key / potion is for)
          { wait = true, reason }               ghost unknown: wait a little for another player's phone (never alone)
          { door = n, reason, notes, risky }    stand in this door's circle (notes: why each door was kept or rejected)
        Risk of a door: revealed ghost 1 / other doors 0 / the wand cleared the room 0; unknown = its ghost weight /
        the room's total (room 1 never had a ghost in any recorded run: 0). Score = risk x 100 + entering's cost
        (electric: a sure heart = 100; webbed: an item; bouncy: a random door) + lock cost - expected items x 3.
        Items (user 2026-10-10: "use them much more, lower the risk to the minimum before every door"): the red potion
        as soon as one heart is missing, the gold potion at once; ghost unknown -> my phone at any risk, else my wand,
        else wait for another player's phone; a key / gold key when the best door is behind it; the wand when the
        chosen door is still >= 15 % ghost (any risk when a hit can end the run); ghost potions before every door that
        is not verified safe (1 temp heart; 2 from room 8 on, where ghosts take 2 hearts, or at 2 red hearts or less).
        Equal doors: at random. Hauntlet.plan() runs this to the door once per room, for the log.
    ]]
    local function itemCount(inventory, item)
        return tonumber(inventory and inventory[item]) or 0
    end
    local function ownedItems(inventory)
        local n = 0
        for _, count in pairs(inventory or {}) do
            n += math.max(0, tonumber(count) or 0)
        end
        return n
    end
    function Hauntlet.decide(view, options)
        options = options or Hauntlet.DEFAULTS
        local function opt(key) -- a strategy table without the key: the default
            local value = options[key]
            if value == nil then
                value = Hauntlet.DEFAULTS[key]
            end
            return value
        end
        local inv, tried = view.inventory or {}, view.tried or {}
        local function can(item)
            return itemCount(inv, item) > 0 and not tried[item]
        end
        local health, maxHealth = tonumber(view.health) or 3, tonumber(view.maxHealth) or 3
        local ghost = tonumber(view.revealedGhost)
        local known = view.safe == true or ghost ~= nil
        local firstRoomSafe = opt("safeFirstRoom") ~= false and view.seq == 1
        -- v2.1.3 (user: "first THINK: your items and how many hearts you have"): the red potion fills EVERY missing
        -- heart, so it waits for 2 missing hearts unless the next ghost hit would leave 1 heart or less
        local twoGhosts = Hauntlet.twoGhostChance(view.seq) -- v2.1.3: measured per room (see TWO_GHOSTS)
        local lateRoom = twoGhosts >= 0.3
        local temp = tonumber(view.tempHealth) or 0
        if view.shield and temp <= 0 then
            temp = 1
        end
        local worstHit = Hauntlet.worstHit(view.seq)
        local missing = maxHealth - health
        if missing > 0 and can("red_potion") and (missing >= (tonumber(opt("redPotionMissing")) or 1)
            or health + temp - worstHit <= 1 or itemCount(inv, "red_potion") >= 2) then
            return { use = "red_potion", reason = string.format("hearts %d/%d (a ghost can take %d): the red potion fills them",
                health, maxHealth, worstHit) }
        end
        if can("gold_potion") then
            return { use = "gold_potion", reason = "one more heart for the rest of the run (run items end with the run)" }
        end
        -- the risk of every door
        local doors, risks, total = view.doors or {}, {}, 0
        for i = 1, 4 do
            local d = doors[i]
            if d and d.exists ~= false then
                total += Hauntlet.doorInfo(d.kind).ghost
            end
        end
        local bestUnknownRisk = math.huge
        -- live run 3: room 8 had 2 ghost doors and room 9 a ghost that took 2 hearts: from here a revealed ghost does
        -- not make the other doors safe (they keep half their weight) (lateRoom: above)
        local function enterable(d)
            local gold, grey = tonumber(d.gold) or 0, tonumber(d.grey) or 0
            return (gold == 0 or (itemCount(inv, "gold_key") >= gold and not tried.gold_key))
                and (grey == 0 or (itemCount(inv, "key") >= grey and not tried.key))
        end
        local ghostWeight = ghost and doors[ghost] and doors[ghost].exists ~= false and Hauntlet.doorInfo(doors[ghost].kind).ghost or 0
        for i = 1, 4 do
            local d = doors[i]
            if d and d.exists ~= false then
                if view.safe == true or firstRoomSafe or Hauntlet.doorInfo(d.kind).area then
                    risks[i] = 0
                elseif ghost then
                    if i == ghost then
                        risks[i] = 1
                    elseif twoGhosts > 0 and total - ghostWeight > 0 then
                        -- the phone shows one ghost: a second one is behind another door with this room's chance
                        risks[i] = twoGhosts * Hauntlet.doorInfo(d.kind).ghost / (total - ghostWeight)
                    else
                        risks[i] = 0
                    end
                elseif total > 0 then
                    -- one ghost: weight / total; two (drawn one after the other by weight): P(first) + P(second)
                    local w = Hauntlet.doorInfo(d.kind).ghost
                    local one = w / total
                    local two = one
                    for j = 1, 4 do
                        local o = doors[j]
                        if j ~= i and o and o.exists ~= false then
                            local wj = Hauntlet.doorInfo(o.kind).ghost
                            if total - wj > 0 then
                                two += (wj / total) * (w / (total - wj))
                            end
                        end
                    end
                    risks[i] = (1 - twoGhosts) * one + twoGhosts * math.min(1, two)
                else
                    risks[i] = 1 / 3
                end
                -- live run 3 (death in room 14): a locked door I cannot open is no way out, its low risk does not count
                if enterable(d) then
                    bestUnknownRisk = math.min(bestUnknownRisk, risks[i])
                end
            end
        end
        -- the worst hit behind a ghost door: 2 hearts from room 8 on (live runs 3 + 6), else 1 (worstHit: above).
        -- danger = such a hit can end the run: then every item is used at any risk
        local danger = health + temp <= worstHit
        local phoneAt = danger and 0.001 or opt("phoneAtRisk")
        local wandAt = danger and 0.001 or opt("wandAtRisk")
        if not known and not firstRoomSafe and bestUnknownRisk > 0 and bestUnknownRisk >= phoneAt then
            if can("cell_phone") then
                return { use = "cell_phone", reason = string.format("the safest door is still %d%% ghost: the phone shows "
                    .. "the ghost's door, the other doors are then safe", math.floor(bestUnknownRisk * 100 + 0.5)) }
            elseif can("rainbow_wand") and bestUnknownRisk >= wandAt then
                return { use = "rainbow_wand", reason = "no phone: the wand clears every ghost in this room" }
            elseif (tonumber(view.others) or 0) > 0 and (tonumber(view.elapsed) or 0) < (opt("revealWaitSeconds") or 0) then
                return { wait = true, reason = "ghost unknown: waiting a moment for another player's phone" }
            end
        end
        local rng = options.rng or math.random
        local penalty = options.kindPenalty or {}
        local notes, best, bestScore, bestNeeds, bestRisk = {}, nil, math.huge, nil, nil
        for i = 1, 4 do
            local d = doors[i]
            if d and d.exists ~= false then
                local info = Hauntlet.doorInfo(d.kind)
                local gold, grey = tonumber(d.gold) or 0, tonumber(d.grey) or 0
                local risk = risks[i]
                local needs = gold > 0 and "gold_key" or (grey > 0 and "key" or nil)
                local locks = gold > 0 and gold or grey
                local score = risk * 100 + (tonumber(penalty[d.kind]) or 0) - (tonumber(info.drops) or 0) * 3
                local parts = {}
                if info.area then
                    score += info.cost
                    if info.area == "laboratory" and itemCount(inv, "key") < 2 then
                        score += 20
                        table.insert(parts, "its doors need 2 keys each")
                    end
                    table.insert(parts, "next area: " .. info.area .. " (cost " .. info.cost .. ")")
                end
                if info.effect == "player_take_damage" then
                    score += 100 * (tonumber(info.value) or 1)
                    table.insert(parts, "entering costs a heart")
                elseif info.effect == "player_lose_item" and ownedItems(inv) > 0 then
                    -- log 2026-10-11: webbed doors took every potion one by one (no items left from room 24 to 42).
                    -- Holding a heart item, a webbed door is worth it only when the other doors are clearly riskier.
                    local precious = itemCount(inv, "red_potion") + itemCount(inv, "gold_potion")
                        + itemCount(inv, "ghost_potion") + itemCount(inv, "rainbow_wand")
                    score += precious > 0 and 18 or 8
                    table.insert(parts, precious > 0 and "entering costs an item (maybe a heart item)" or "entering costs an item")
                elseif info.effect == "player_bounce" then
                    score += 10
                    table.insert(parts, "bounces me to a random door")
                elseif info.effect == "transform" then
                    score += 3
                end
                local pushed = type(view.ejected) == "table" and tonumber(view.ejected[i]) or 0
                if pushed > 0 then
                    -- v2.1.5: I stood in this door's circle and was pushed out (a ??? door became a locked one, ...)
                    score += pushed >= 2 and 1000 or 400
                    table.insert(parts, string.format("pushed out of this door %d time%s", pushed, pushed == 1 and "" or "s"))
                end
                if needs and (itemCount(inv, needs) < locks or tried[needs]) then
                    score += 1000
                    table.insert(parts, string.format("locked (%d %s lock%s), cannot open it", locks,
                        needs == "gold_key" and "gold" or "grey", locks == 1 and "" or "s"))
                elseif needs then
                    if known and risk == 0 and opt("preferLockedWhenSafe") then
                        score -= 5
                        table.insert(parts, "safe and locked: the " .. needs .. " opens the richer path")
                    else
                        score += 5
                        table.insert(parts, "needs a " .. needs)
                    end
                elseif d.wasLocked and risk == 0 and opt("preferLockedWhenSafe") then
                    score -= 5
                    table.insert(parts, "safe and unlocked now: the richer path")
                end
                if risk >= 1 then
                    table.insert(parts, 1, "the ghost was revealed here")
                end
                score += ((type(options.tie) == "table" and tonumber(options.tie[i])) or rng()) * 0.5
                notes[i] = string.format("door %d (%s): risk %s, score %.1f%s", i, tostring(d.kind),
                    risk == 0 and "none" or (risk >= 1 and "GHOST" or (math.floor(risk * 100 + 0.5) .. "%")), score,
                    #parts > 0 and (" - " .. table.concat(parts, "; ")) or "")
                if score < bestScore then
                    best, bestScore, bestRisk = i, score, risk
                    bestNeeds = (needs and score < 1000) and needs or nil
                end
            end
        end
        if not best then
            return { wait = true, reason = "no door data yet" }
        end
        local why = view.safe == true and "the wand cleared this room"
            or (ghost and string.format("the ghost is behind door %d", ghost))
            or (firstRoomSafe and "room 1 never had a ghost")
            or string.format("ghost unknown: door %d is the least likely (%d%%)", best, math.floor(bestRisk * 100 + 0.5))
        if bestNeeds then
            return { use = bestNeeds, door = best, reason = why .. "; door " .. best .. " needs a " .. bestNeeds, notes = notes }
        end
        -- the wand when the door is still risky (live run 3: the only door left was the revealed ghost and the wand
        -- stayed in the pocket)
        if bestRisk > 0 and bestRisk >= wandAt and view.safe ~= true and can("rainbow_wand") then
            return { use = "rainbow_wand", door = best, reason = string.format("%s; door %d is still %d%% ghost: the "
                .. "wand clears the room first", why, best, math.floor(bestRisk * 100 + 0.5)), notes = notes }
        end
        -- ghost potions (a temp heart each; a hit takes it first): before EVERY door that is not verified safe, no risk
        -- limit; 2 of them where a ghost can take 2 hearts (room 8+) or when 2 red hearts or less are left
        local potions = itemCount(inv, "ghost_potion")
        local tempTarget = (lateRoom or health <= 2 or bestRisk >= 0.3) and opt("tempHeartsLate") or opt("tempHearts")
        -- user 2026-10-11: "I have 6-7 ghost potions stacked: if a door is not safe, use them, no need to take the
        -- risk": a coin-flip door (or worse) late in the run gets a third temp heart, and a full stack adds one more
        if bestRisk >= 0.5 and (view.seq or 0) >= 16 then
            tempTarget = math.max(tempTarget, 3)
        end
        if potions >= 4 and bestRisk >= 0.1 then
            tempTarget += 1
        end
        local cap = tonumber(view.tempCap)
        if cap and cap > 0 then
            tempTarget = math.min(tempTarget, cap)
        end
        -- v2.1.3 budget: the last potion(s) (potionReserve) stay for a door that is >= reserveBreakRisk a ghost or a hit
        -- that would leave 1 heart or less
        local mustProtect = (health + temp - worstHit <= 1 and bestRisk >= 0.05)
            or bestRisk >= (tonumber(opt("reserveBreakRisk")) or 0)
        local reserve = tonumber(opt("potionReserve")) or 0
        if (view.seq or 0) < (tonumber(opt("saveUntilRoom")) or 0) then
            -- early: save potions for the late rooms; only a hit that could END the run (or a coin-flip door that
            -- would leave 1 heart) breaks into the stack, and an almost-safe door never gets one
            local canDie = health + temp - worstHit <= 0
            mustProtect = (canDie and bestRisk >= 0.05) or (health + temp - worstHit <= 1 and bestRisk >= 0.5)
            reserve = math.max(reserve, tonumber(opt("saveReserve")) or 0)
            if bestRisk < (tonumber(opt("saveLowRisk")) or 0) and not canDie then
                tempTarget = 0
            end
        end
        local spareOk = potions > reserve or mustProtect
        if bestRisk > 0 and bestRisk >= opt("potionAtRisk") and temp < tempTarget and can("ghost_potion") and spareOk then
            return { use = "ghost_potion", door = best, reason = string.format("%s; temp heart %d of %d for door %d", why,
                temp + 1, tempTarget, best), notes = notes }
        end
        return { door = best, reason = why, notes = notes, risky = bestRisk > 0, risk = bestRisk, worstHit = worstHit }
    end
    --[[
        PLAN (user 2026-10-10: "always draw the plan before the pick"): decide() again and again on a copy of the room
        where every item already had its expected effect, so the whole room is known before the first step: hearts ->
        phone -> keys -> wand -> ghost potions -> the door. A phone ends the plan (its answer changes it), and so does
        waiting for another player's phone. Returns the steps (text) and the door step (nil when the plan stops early).
    ]]
    function Hauntlet.plan(view, options)
        local sim = {}
        for key, value in pairs(view) do
            sim[key] = value
        end
        sim.inventory, sim.tried, sim.doors = {}, {}, {}
        for key, value in pairs(view.inventory or {}) do
            sim.inventory[key] = value
        end
        for key, value in pairs(view.tried or {}) do
            sim.tried[key] = value
        end
        for i, d in pairs(view.doors or {}) do
            local copy = {}
            for key, value in pairs(d) do
                copy[key] = value
            end
            sim.doors[i] = copy
        end
        sim.tempHealth = tonumber(sim.tempHealth) or 0
        if sim.shield and sim.tempHealth <= 0 then
            sim.tempHealth = 1
        end
        local steps = {}
        for _ = 1, 12 do
            local step = Hauntlet.decide(sim, options)
            if step.use then
                local item = step.use
                sim.inventory[item] = math.max(0, (tonumber(sim.inventory[item]) or 0) - 1)
                if item == "red_potion" then
                    sim.health = sim.maxHealth
                    sim.tried[item] = true
                    table.insert(steps, "red potion (hearts full)")
                elseif item == "gold_potion" then
                    sim.maxHealth = (tonumber(sim.maxHealth) or 3) + 1
                    sim.health = (tonumber(sim.health) or 3) + 1
                    table.insert(steps, "gold potion (+1 heart)")
                elseif item == "ghost_potion" then
                    sim.tempHealth += 1
                    sim.shield = true
                    table.insert(steps, "ghost potion (+1 temp heart)")
                elseif item == "rainbow_wand" then
                    sim.safe = true
                    sim.tried[item] = true
                    table.insert(steps, "wand (no ghost left)")
                elseif (item == "key" or item == "gold_key") and step.door and sim.doors[step.door] then
                    local d = sim.doors[step.door]
                    if item == "key" then
                        d.grey = math.max(0, (tonumber(d.grey) or 0) - 1)
                    else
                        d.gold = 0
                    end
                    table.insert(steps, string.format("%s for door %d", item == "key" and "key" or "gold key", step.door))
                elseif item == "cell_phone" then
                    table.insert(steps, "phone (shows the ghost's door, then a new plan)")
                    return steps, nil
                else
                    sim.tried[item] = true
                    table.insert(steps, item)
                end
            elseif step.wait then
                table.insert(steps, "wait for another player's phone")
                return steps, nil
            else
                local risk = tonumber(step.risk) or 0
                if risk <= 0 then
                    table.insert(steps, string.format("door %d (safe)", step.door))
                else
                    local hit = tonumber(step.worstHit) or 1
                    local left = (tonumber(sim.health) or 3) + (tonumber(sim.tempHealth) or 0) - hit
                    table.insert(steps, string.format("door %d (%d%% ghost; worst hit -%d -> %s)", step.door,
                        math.floor(risk * 100 + 0.5), hit,
                        left > 0 and (left .. " heart" .. (left == 1 and "" or "s") .. " left") or "DEAD"))
                end
                return steps, step
            end
        end
        return steps, nil
    end
    function Hauntlet.describeDoors(doors)
        local parts = {}
        for i = 1, 4 do
            local d = doors and doors[i]
            if d and d.exists ~= false then
                local locks = (d.gold or 0) > 0 and (" " .. d.gold .. " gold lock") or ((d.grey or 0) > 0 and (" " .. d.grey .. " lock") or "")
                table.insert(parts, i .. "=" .. tostring(d.kind) .. locks)
            end
        end
        return table.concat(parts, ", ")
    end
    function Hauntlet.describeItems(inventory)
        local parts = {}
        for item, n in pairs(inventory or {}) do
            if (tonumber(n) or 0) > 0 then
                table.insert(parts, item .. (n > 1 and (" x" .. n) or ""))
            end
        end
        table.sort(parts)
        return #parts > 0 and table.concat(parts, ", ") or "none"
    end
    -- Debug: the game's own door / item / area lists (ReplicatedStorage...Game.Hauntlet.*DB), one level deep, so the
    -- door kinds' real rules can be read later (Event.HauntletDebug = true enables in-memory detail).
    function Hauntlet.describeDatabases()
        local lines = {}
        local node = ReplicatedStorage
        for _, name in ipairs(GameConstants.Event.HauntletDBPath) do
            node = node and node:FindFirstChild(name)
        end
        if not node then
            return { "Hauntlet databases not found" }
        end
        local function show(value)
            if type(value) == "table" then
                local inner = {}
                for k, v in pairs(value) do
                    if type(v) ~= "table" and type(v) ~= "function" and #inner < 12 then
                        table.insert(inner, tostring(k) .. "=" .. tostring(v))
                    end
                end
                table.sort(inner)
                return "{ " .. table.concat(inner, ", ") .. " }"
            end
            return tostring(value)
        end
        for _, dbName in ipairs({ "HauntletDoorDB", "HauntletItemDB", "HauntletAreaDB" }) do
            local module = node:FindFirstChild(dbName)
            local ok, db = pcall(require, module)
            table.insert(lines, "== " .. dbName .. (ok and "" or (" (" .. tostring(db) .. ")")))
            if ok and type(db) == "table" then
                local keys = {}
                for key in pairs(db) do
                    table.insert(keys, tostring(key))
                end
                table.sort(keys)
                for _, key in ipairs(keys) do
                    local entry = db[key]
                    local fields = {}
                    if type(entry) == "table" then
                        for field, value in pairs(entry) do
                            if type(value) ~= "function" then
                                table.insert(fields, tostring(field) .. "=" .. show(value))
                            end
                        end
                        table.sort(fields)
                    end
                    table.insert(lines, key .. ": " .. table.concat(fields, "; "))
                end
            end
        end
        return lines
    end
    function Hauntlet.client()
        local node = ReplicatedStorage
        for _, name in ipairs(GameConstants.Event.HauntletClientPath) do
            node = node and node:FindFirstChild(name)
        end
        if not node or not node:IsA("ModuleScript") then
            return nil
        end
        local ok, module = pcall(require, node)
        return ok and type(module) == "table" and module or nil
    end
    function Hauntlet:start(maid)
        local folder = ReplicatedStorage:FindFirstChild(GameConstants.Remotes.Folder)
        local remote = folder and folder:FindFirstChild(GameConstants.Remotes.MinigameMessage)
        if not (remote and remote:IsA("RemoteEvent")) then
            self._logger:warn("Hauntlet", GameConstants.Remotes.MinigameMessage .. " not found: Hauntlet is off")
            return false
        end
        maid:Give(remote.OnClientEvent:Connect(function(...)
            local ok, err = pcall(self._onMessage, self, ...)
            if not ok then
                self._logger:debug("Hauntlet", "message not understood: " .. tostring(err))
            end
        end))
        self.available = true
        return true
    end
    -- Debug (user: "the Hauntlet opens every 20 min, too slow to test"): every room template the client has, found by
    -- its door circles (any folder named *JoinCircle*), with its layout: the nexus room's circles without a run.
    function Hauntlet.describeTemplates()
        local lines, seen = {}, {}
        local function layout(model)
            local parts = {}
            for _, child in ipairs(model:GetChildren()) do
                local names, kids = {}, child:GetChildren()
                if #kids <= 40 then
                    for _, kid in ipairs(kids) do
                        if #names < 10 then
                            table.insert(names, kid.Name .. "<" .. kid.ClassName .. ">")
                        end
                    end
                end
                table.insert(parts, child.Name .. "(" .. child.ClassName .. (#names > 0 and (": " .. table.concat(names, ","))
                    or (#kids > 0 and (": " .. #kids .. " children") or "")) .. ")")
            end
            return table.concat(parts, "; ")
        end
        local ok, err = pcall(function()
            for _, node in ipairs(ReplicatedStorage:GetDescendants()) do
                if #lines >= 80 then
                    break
                end
                local name = string.lower(node.Name)
                local room = (string.find(name, "joincircle", 1, true) and node.Parent)
                    or ((name == "nexus" or name == "final_nexus") and node) or nil
                if room and not seen[room] then
                    seen[room] = true
                    table.insert(lines, room:GetFullName() .. " <" .. room.ClassName .. ">: " .. layout(room))
                end
            end
        end)
        if not ok then
            table.insert(lines, "error: " .. tostring(err))
        end
        if #lines == 0 then
            table.insert(lines, "no room templates with door circles found in ReplicatedStorage")
        end
        return table.concat(lines, "\n")
    end
    return Hauntlet
end
__moduleSources["Game/EventTasks"] = function(...)
    local import = ...
    local Util = import("Core/Util")
    local GameConstants = import("Game/GameConstants")
    local Minigame = import("Game/Minigame")
    local Hauntlet = import("Game/Hauntlet")
    local Tasks = import("Game/Tasks")
    local EventTasks = {}
    local E = GameConstants.Event
    local KEYS = GameConstants.DataKeys
    local TOYS = GameConstants.ToyCategory
    local function count(map)
        local n = 0
        for _ in pairs(map) do
            n += 1
        end
        return n
    end
    local function sortedNumberKeys(map)
        local keys = {}
        for key in pairs(type(map) == "table" and map or {}) do
            if tonumber(key) then
                table.insert(keys, tonumber(key))
            end
        end
        table.sort(keys)
        return keys
    end
    function EventTasks.cryptPlan(crypt, preferTwig)
        if type(crypt) ~= "table" or type(crypt.floors) ~= "table" then
            return nil, "crypt data not known yet"
        end
        if preferTwig then
            local twig = EventTasks.reachableTwigGrave(crypt)
            if twig then
                return twig
            end
        end
        local opened = {}
        for _, id in pairs(type(crypt.opened) == "table" and crypt.opened or {}) do
            if tonumber(id) then
                opened[tonumber(id)] = true
            end
        end
        local function lookup(map, number)
            return map[number] or map[tostring(number)]
        end
        for _, floor in ipairs(sortedNumberKeys(crypt.floors)) do
            local graves = lookup(crypt.floors, floor)
            graves = type(graves) == "table" and graves.coffins
            if type(graves) == "table" then
                local ladder
                for _, index in ipairs(sortedNumberKeys(graves)) do
                    if lookup(graves, index) == E.Ladder then
                        ladder = index
                    end
                end
                if ladder then
                    if not opened[floor * E.OpenedIdPerFloor + ladder] then
                        return { floor = floor, grave = ladder, reward = E.Ladder }
                    end
                else
                    local best, bestValue
                    for _, index in ipairs(sortedNumberKeys(graves)) do
                        if not opened[floor * E.OpenedIdPerFloor + index] then
                            local value = E.GraveValue[lookup(graves, index)] or 0
                            if not best or value > bestValue then
                                best, bestValue = index, value
                            end
                        end
                    end
                    if best then
                        return { floor = floor, grave = best, reward = tostring(lookup(graves, best)) }
                    end
                    return { spider = true, floor = floor }
                end
            end
        end
        if #sortedNumberKeys(crypt.floors) > 0 then
            return { spider = true }
        end
        return nil, "no Crypt floors in your data yet"
    end
    function EventTasks.cryptPick(crypt, wants, preferTwig)
        if type(wants) ~= "table" or #wants == 0 then
            return EventTasks.cryptPlan(crypt, preferTwig)
        end
        if type(crypt) ~= "table" or type(crypt.floors) ~= "table" then
            return nil, "crypt data not known yet"
        end
        if preferTwig then
            local twig = EventTasks.reachableGrave(crypt, "twig")
            if twig then
                return twig
            end
        end
        for _, want in ipairs(wants) do
            if want == E.Ladder then
                local plan = EventTasks.cryptPlan(crypt)
                if plan then
                    return plan
                end
            else
                local grave = EventTasks.reachableGrave(crypt, want)
                if grave then
                    return grave
                end
            end
        end
        return nil, "no grave with " .. table.concat(wants, " / ") .. " left on the floors you can reach"
    end
    function EventTasks.reachableTwigGrave(crypt)
        return EventTasks.reachableGrave(crypt, "twig")
    end
    -- user 2026-10-11: "the lever comes from a Crypt grave". Its reward may be the item id or a table naming it: any
    -- text in it with "lever" / "lightning" counts (the exact id first)
    function EventTasks.isLeverReward(rewardHere)
        if rewardHere == E.LightningLever then
            return true
        end
        local parts = {}
        local function collect(v, depth)
            if type(v) == "table" and depth < 3 then
                for k, x in pairs(v) do
                    table.insert(parts, tostring(k))
                    collect(x, depth + 1)
                end
            elseif v ~= nil then
                table.insert(parts, tostring(v))
            end
        end
        collect(rewardHere, 0)
        local text = string.lower(table.concat(parts, " "))
        return string.find(text, "lever", 1, true) ~= nil or string.find(text, "lightning", 1, true) ~= nil
    end
    function EventTasks.reachableGrave(crypt, reward)
        if type(crypt) ~= "table" or type(crypt.floors) ~= "table" then
            return nil
        end
        local opened = {}
        for _, id in pairs(type(crypt.opened) == "table" and crypt.opened or {}) do
            if tonumber(id) then
                opened[tonumber(id)] = true
            end
        end
        local function lookup(map, number)
            return map[number] or map[tostring(number)]
        end
        for _, floor in ipairs(sortedNumberKeys(crypt.floors)) do
            local graves = lookup(crypt.floors, floor)
            graves = type(graves) == "table" and graves.coffins
            if type(graves) == "table" then
                local ladderOpen, hasLadder = false, false
                for _, index in ipairs(sortedNumberKeys(graves)) do
                    local rewardHere = lookup(graves, index)
                    local isOpen = opened[floor * E.OpenedIdPerFloor + index] == true
                    local wanted = rewardHere == reward or (reward == "twig" and rewardHere == E.Twig)
                        or (reward == "lever" and EventTasks.isLeverReward(rewardHere))
                    if wanted and rewardHere ~= E.Ladder then
                        if not isOpen then
                            return { floor = floor, grave = index, reward = reward }
                        end
                    elseif rewardHere == E.Ladder then
                        hasLadder = true
                        ladderOpen = isOpen
                    end
                end
                if hasLadder and not ladderOpen then
                    return nil
                end
            end
        end
        return nil
    end
    function EventTasks.nestState(nest, held, keys)
        if type(nest) ~= "table" then
            return "UNKNOWN", 0, held or 0
        end
        local placed = tonumber(nest.twigs_contributed) or 0
        held = held or 0
        if placed >= E.NestTwigs then
            return "COMPLETE", placed, held
        elseif placed + held >= E.NestTwigs then
            return "BUILD_NEST", placed, held
        elseif (keys or 0) > 0 then
            return "COLLECT_TWIGS", placed, held
        end
        return "WAIT_KEY", placed, held
    end
    function EventTasks.questsToClaim(dailies)
        local list = {}
        local tabs = type(dailies) == "table" and type(dailies.serialized_tabs) == "table" and dailies.serialized_tabs or {}
        for _, tabName in ipairs(E.QuestTabs) do
            local tab = tabs[tabName]
            if type(tab) == "table" then
                local finished, unfinished = 0, 0
                for _, daily in pairs(type(tab.active_dailies) == "table" and tab.active_dailies or {}) do
                    local progress = type(daily) == "table" and type(daily.state) == "table" and daily.state or {}
                    local need, done = tonumber(progress.steps_to_complete), tonumber(progress.steps_completed)
                    if need and done and done >= need then
                        finished += 1
                    else
                        unfinished += 1
                    end
                end
                if finished > 0 then
                    table.insert(list, { action = "QuestClaim", tab = tabName })
                end
                if tab.reward_claimed == false and (tonumber(tab.total_dailies_completed_today) or 0) >= E.QuestsPerBoardReward then
                    table.insert(list, { action = "QuestTabReward", tab = tabName })
                end
            end
        end
        return list
    end
    function EventTasks.describeQuests(dailies)
        local tabs = type(dailies) == "table" and type(dailies.serialized_tabs) == "table" and dailies.serialized_tabs
        if not tabs then
            return "no quest data"
        end
        local parts = {}
        for _, tabName in ipairs(E.QuestTabs) do
            local tab = tabs[tabName]
            if type(tab) == "table" then
                local quests = {}
                for kind, daily in pairs(type(tab.active_dailies) == "table" and tab.active_dailies or {}) do
                    local state = type(daily) == "table" and type(daily.state) == "table" and daily.state or {}
                    table.insert(quests, string.format("%s %s/%s", tostring(kind), tostring(state.steps_completed),
                        tostring(state.steps_to_complete)))
                end
                table.sort(quests)
                table.insert(parts, string.format("%s [%s] done today %s, board reward %s", tabName,
                    #quests > 0 and table.concat(quests, ", ") or "no open quests", tostring(tab.total_dailies_completed_today),
                    tab.reward_claimed == true and "claimed" or "not claimed"))
            end
        end
        return #parts > 0 and table.concat(parts, " | ") or "no Halloween / normal board"
    end
    function EventTasks.nextRoundStart(cycle, now)
        local start = type(cycle) == "table" and tonumber(cycle.timestamp)
        local period = tonumber(E.RoundSeconds)
        if not start or start ~= start or math.abs(start) == math.huge or type(now) ~= "number"
            or now ~= now or math.abs(now) == math.huge or not period or period <= 0 or period == math.huge then return nil end
        if start + 20 < now then start += math.ceil((now - 20 - start) / period) * period end
        return start
    end
    -- focus / kindOf (Mega a Pet): a pen pet of another kind makes room for a waiting copy of the focus pet
    function EventTasks.penPlan(pen, growable, keep, slots, focus, kindOf)
        local plan = { claim = count(pen) > 0, remove = {}, add = {} }
        local others = {}
        for unique, record in pairs(pen) do
            if type(record) == "table" and record.max_age == true then
                table.insert(plan.remove, unique)
            elseif focus and kindOf and kindOf(unique) ~= focus then
                table.insert(others, unique)
            end
        end
        table.sort(plan.remove)
        table.sort(others)
        local free = slots - count(pen) + #plan.remove
        if focus then
            local waiting = 0
            for _, pet in ipairs(growable) do
                if pet.kind == focus and not keep[pet.unique] then
                    waiting += 1
                end
            end
            while waiting > free and #others > 0 do
                table.insert(plan.remove, table.remove(others, 1))
                free += 1
            end
        end
        for _, pet in ipairs(growable) do
            if free <= 0 then
                break
            end
            if not keep[pet.unique] and (not focus or pet.kind == focus) then
                table.insert(plan.add, pet.unique)
                free -= 1
            end
        end
        return plan
    end
    function EventTasks.findGhosts(folder)
        local list = {}
        if not folder then
            return list
        end
        for _, child in ipairs(folder:GetChildren()) do
            local id = string.match(child.Name, E.GhostNamePattern)
            if id then
                table.insert(list, { id = id, model = child, size = string.match(child.Name, "^Ghost_(%a+)_") })
            end
        end
        return list
    end
    local function myRoot()
        local character = game:GetService("Players").LocalPlayer.Character
        return character and character:FindFirstChild("HumanoidRootPart")
    end
    local function modelPosition(model)
        local ok, position = pcall(function()
            return model:GetPivot().Position
        end)
        return ok and position or nil
    end
    local function distance(a, b)
        return math.sqrt((a.X - b.X) ^ 2 + (a.Y - b.Y) ^ 2 + (a.Z - b.Z) ^ 2)
    end
    local function hold(ctx, unique, category)
        local ok, reason = ctx.interaction:send("EquipItem", unique, {})
        if not ok then
            return false, "could not hold the item: " .. tostring(reason)
        end
        ctx.maid:Give(function()
            if ctx.gameData:itemUsesLeft(category, unique) ~= nil then
                ctx.interaction:send("UnequipItem", unique, nil)
            end
        end)
        return true
    end
    local function penSignature(ctx)
        local parts = {}
        for unique, record in pairs(ctx.gameData:petPenPets()) do
            table.insert(parts, unique .. ":" .. tostring(record.xp_timestamp) .. ":" .. tostring(record.currency_timestamp))
        end
        table.sort(parts)
        return table.concat(parts, "|")
    end
    EventTasks.petPen = {
        id = "pet_pen",
        timeoutSeconds = 60,
        run = function(ctx, group)
            if not ctx.travel:isAt(GameConstants.HouseInteriorName) then
                return false, "the Pet Pen job runs only at home"
            end
            local keep = {}
            for _, pet in ipairs(ctx.gameData:equippedPetList()) do
                keep[pet.unique] = true
            end
            if group and group.keep then keep[group.keep] = true end
            local selection = ctx.gameData.selection
            if selection and selection:enabled() then
                for _, id in ipairs(selection.ids) do keep[id] = true end
            end
            local slots = tonumber(ctx.farmConfig.Event.PetPenSlots) or E.PetPenSlots
            local plan = EventTasks.penPlan(ctx.gameData:petPenPets(),
                ctx.gameData:growablePets(ctx.farmConfig.PreferNeon == true, GameConstants.kindRank(ctx.farmConfig)), keep, slots,
                GameConstants.focusKind(ctx.farmConfig), function(unique)
                    return ctx.gameData:getPetKind(unique)
                end)
            local done = {}
            if plan.claim then
                local before = penSignature(ctx)
                local bucks = ctx.gameData:get(KEYS.Money)
                ctx.interaction:send("PetPenClaim", true)
                if not ctx.waitUntil(function()
                    return penSignature(ctx) ~= before
                end, 8) then
                    return false, "CLAIM ALL had no effect in my data"
                end
                local after = ctx.gameData:get(KEYS.Money)
                table.insert(done, "claimed" .. ((tonumber(after) and tonumber(bucks) and after > bucks)
                    and string.format(" (+%d Bucks)", after - bucks) or ""))
            end
            -- Claiming can mature pets; compute the moves from the post-claim data.
            plan = EventTasks.penPlan(ctx.gameData:petPenPets(),
                ctx.gameData:growablePets(ctx.farmConfig.PreferNeon == true, GameConstants.kindRank(ctx.farmConfig)), keep, slots,
                GameConstants.focusKind(ctx.farmConfig), function(unique) return ctx.gameData:getPetKind(unique) end)
            local penNow = ctx.gameData:petPenPets()
            for _, unique in ipairs(plan.remove) do
                local grown = type(penNow[unique]) == "table" and penNow[unique].max_age == true
                ctx.interaction:send("PetPenRemove", unique)
                if not ctx.waitUntil(function()
                    return type(ctx.gameData:get(KEYS.PetPen)) == "table" and ctx.gameData:petPenPets()[unique] == nil
                end, 6) then
                    return false, "pet " .. unique .. " did not leave the pen"
                end
                table.insert(done, grown and "took out a full grown pet"
                    or ("made room for the focus pet (took out " .. tostring(ctx.gameData:getPetKind(unique) or unique) .. ")"))
            end
            for _, unique in ipairs(plan.add) do
                if ctx.gameData:isPetProtected(unique) or ctx.gameData:isPetEquipped(unique) then
                    return false, "pet selection changed before pen placement"
                end
                ctx.interaction:send("PetPenAdd", unique)
                if not ctx.waitUntil(function()
                    return ctx.gameData:petPenPets()[unique] ~= nil
                end, 6) then
                    return false, "pet " .. unique .. " did not arrive in the pen"
                end
                table.insert(done, "added " .. tostring(ctx.gameData:getPetKind(unique) or unique))
            end
            ctx.logger:info("Event", "Pet Pen: " .. (#done > 0 and table.concat(done, ", ") or "nothing to do")
                .. string.format(" (%d of %d slots used)", count(ctx.gameData:petPenPets()), slots))
            return true
        end,
    }
    local function nearSpot(spotName, studs)
        local spot = GameConstants.Spots[spotName]
        local root = myRoot()
        if not (spot and root) then
            return false
        end
        local p = root.Position
        return math.sqrt((p.X - spot.x) ^ 2 + (p.Z - spot.z) ^ 2) <= studs
    end
    EventTasks._nearSpot = nearSpot
    local function standAt(ctx, spotName)
        for try = 1, 2 do
            local arrived, why = ctx.travel:goTo("MainMap")
            if not arrived then
                return false, "travel to the Halloween map failed: " .. tostring(why)
            end
            if spotName == "stray_cat" then
                -- user 2026-10-11: "the Stray Cat was moved next to the Hotel": its spot is read from the map
                -- (MainMap > Event > Halloween > StrayCat) when it is there; the saved spot stays the fallback
                pcall(function()
                    for _, interior in ipairs(workspace:FindFirstChild("Interiors") and workspace.Interiors:GetChildren() or {}) do
                        if string.sub(interior.Name, 1, 7) == "MainMap" then
                            local event = interior:FindFirstChild("Event")
                            local halloween = event and event:FindFirstChild("Halloween")
                            local catNode = halloween and halloween:FindFirstChild("StrayCat")
                            if catNode then
                                local position = catNode:IsA("BasePart") and catNode.Position
                                if not position then
                                    local part = catNode:FindFirstChildWhichIsA("BasePart", true)
                                    position = part and part.Position
                                end
                                if position then
                                    local spot = GameConstants.Spots.stray_cat
                                    if math.abs(spot.x - position.X) + math.abs(spot.z - position.Z) > 15 then
                                        ctx.logger:info("Event", string.format("Stray Cat is at (%.0f, %.0f) now (was %.0f, %.0f)",
                                            position.X, position.Z, spot.x, spot.z))
                                    end
                                    spot.x, spot.y, spot.z = position.X + 4, position.Y + 3, position.Z + 4
                                end
                                return
                            end
                        end
                    end
                end)
            end
            local moved, notMoved = ctx.interaction:teleportTo(spotName)
            task.wait(1.5)
            if moved and nearSpot(spotName, 20) and ctx.travel:isAt("MainMap") then
                return true
            end
            ctx.logger:info("Event", string.format("Not next to %s after the teleport (%s), try %d", spotName,
                moved and "moved away again" or tostring(notMoved), try))
        end
        return false, "could not stay next to " .. spotName
    end
    EventTasks.strayCat = {
        id = "stray_cat",
        timeoutSeconds = 90,
        run = function(ctx)
            local function cat()
                local data = ctx.gameData:get(KEYS.StrayCat)
                return type(data) == "table" and data or {}
            end
            if cat().fed_today == true then
                return true
            end
            local giftsBefore = tonumber(cat().total_gifts) or 0
            local item = ctx.gameData:findItems(GameConstants.ItemCategory, E.CatFood)[1]
            if not item then
                if not ctx.farmConfig.BuyWater then
                    return false, "no water for the cat (Farm.BuyWater = false)"
                end
                ctx.interaction:send("BuyItem", "food", "water", {})
                ctx.waitUntil(function()
                    item = ctx.gameData:findItems(GameConstants.ItemCategory, E.CatFood)[1]
                    return item ~= nil
                end, 8)
                if not item then
                    return false, "could not buy a water for the cat"
                end
            end
            local there, notThere = standAt(ctx, "stray_cat")
            if not there then
                return false, notThere
            end
            local held, holdWhy = hold(ctx, item.unique, GameConstants.ItemCategory)
            if not held then
                return false, holdWhy
            end
            task.wait(1)
            local sent, result = ctx.interaction:send("StrayCatFeed", { unique = item.unique })
            local reason = type(result) == "table" and result.reason or nil
            for _ = 1, 2 do
                if reason ~= "too_far" then
                    break
                end
                ctx.logger:info("Event", "Stray Cat: too far, moving next to it again")
                if not standAt(ctx, "stray_cat") then
                    break
                end
                sent, result = ctx.interaction:send("StrayCatFeed", { unique = item.unique })
                reason = type(result) == "table" and result.reason or nil
            end
            if ctx.waitUntil(function()
                return cat().fed_today == true or (tonumber(cat().total_gifts) or 0) > giftsBefore
            end, 5) then
                ctx.logger:success("Event", string.format("Stray Cat fed with %s%s", item.id,
                    (type(result) == "table" and result.amount) and (" (+" .. tostring(result.amount) .. " candy)") or ""))
                return true
            end
            if reason == "cat_full" then
                ctx.logger:info("Event", "Stray Cat is already full today")
                return true
            end
            return false, "the cat did not take it (" .. (sent and ("answer: " .. tostring(reason or result)) or "send failed") .. ")"
        end,
    }
    EventTasks.crypt = {
        id = "crypt",
        timeoutSeconds = 90,
        run = function(ctx)
            local key = ctx.gameData:itemsOfId(TOYS, E.RustyKey)[1]
            local nestState = EventTasks.nestState(ctx.gameData:get(KEYS.PigeonNest),
                #ctx.gameData:itemsOfId(TOYS, E.Twig), key and 1 or 0)
            local preferTwig = ctx.farmConfig.Event.AutoNest ~= false and nestState == "COLLECT_TWIGS"
            local plan, why = EventTasks.cryptPick(ctx.gameData:get(KEYS.Crypt), ctx.farmConfig.Event.CryptOpen, preferTwig)
            local skeliStep = EventTasks.skelicornOn(ctx.farmConfig) and EventTasks.skelicornStep(ctx.gameData, ctx.farmConfig)
            if skeliStep and (skeliStep == "crypt" or EventTasks.skelicornNeedsLever(ctx.gameData)) then
                -- v2.1.4 Auto Skelicorn: the lever's grave first; none on the floors I can reach: the ladder down
                local crypt = ctx.gameData:get(KEYS.Crypt)
                local lever = EventTasks.reachableGrave(crypt, "lever")
                plan = lever or EventTasks.cryptPlan(crypt) or plan
                preferTwig = false
                local text = Util.truncate(Util.jsonEncode(type(crypt) == "table" and crypt.floors or crypt) or "?", 400)
                if text ~= EventTasks._leverFloorsLogged then -- the graves' rewards, once per change: the lever's name
                    EventTasks._leverFloorsLogged = text
                    ctx.logger:info("Skelicorn", "Crypt floors: " .. text)
                    EventTasks.skelicornNote("Crypt floors: " .. Util.truncate(Util.jsonEncode(type(crypt) == "table"
                        and crypt.floors or crypt) or "?", 3000))
                end
                local leverLine = lever and string.format("Lever grave: floor %s grave %s", tostring(lever.floor),
                    tostring(lever.grave)) or ("No lever grave on the floors I can reach: " .. (plan and plan.spider
                    and "the Mummy Spider (the Crypt starts again)" or (plan and string.format("floor %s grave %s (%s)",
                    tostring(plan.floor), tostring(plan.grave), tostring(plan.reward))) or "nothing to open"))
                ctx.logger:info("Skelicorn", leverLine)
                EventTasks.skelicornNote(leverLine .. " | Rusty Keys " .. #ctx.gameData:itemsOfId(TOYS, E.RustyKey))
            end
            if not plan then
                ctx.logger:info("Event", "Crypt: " .. tostring(why))
                return true
            end
            if not plan.spider and not key then
                return true
            end
            local arrived, travelWhy = ctx.travel:goTo("TheCrypt")
            if not arrived then
                return false, "travel to the Crypt failed: " .. tostring(travelWhy)
            end
            if plan.spider then
                local function signature()
                    local data = ctx.gameData:get(KEYS.Crypt)
                    local opened = type(data) == "table" and type(data.opened) == "table" and #data.opened or -1
                    return tostring(type(data) == "table" and data.seed) .. "/" .. opened
                end
                local before = signature()
                if not ctx.gameData:petInventoryKnown() then return false, "pet inventory unavailable before spider claim" end
                local petsBefore = ctx.gameData:petUniquesOfKind(E.MummySpiderKind)
                local _, answer = ctx.interaction:send("ClaimTombSpider")
                if ctx.waitUntil(function()
                    if signature() == before or not ctx.gameData:petInventoryKnown() then return false end
                    for unique in pairs(ctx.gameData:petUniquesOfKind(E.MummySpiderKind)) do
                        if not petsBefore[unique] then return true end
                    end
                    return false
                end, 8) then
                    ctx.logger:success("Event", "Crypt: Mummy Spider claimed, the Crypt starts again")
                    return true
                end
                return false, "the Mummy Spider claim changed nothing in my data (answer: " .. tostring(answer) .. ")"
            end
            local function openedSet()
                local set, n = {}, 0
                local data = ctx.gameData:get(KEYS.Crypt)
                for _, id in pairs(type(data) == "table" and type(data.opened) == "table" and data.opened or {}) do
                    set[tonumber(id) or id] = true
                    n += 1
                end
                return set, n
            end
            local _, before = openedSet()
            local held, holdWhy = hold(ctx, key, TOYS)
            if not held then
                return false, holdWhy
            end
            task.wait(1)
            ctx.logger:info("Event", string.format("Crypt: opening grave %d on floor %d (%s)", plan.grave, plan.floor, plan.reward))
            local _, answer = ctx.interaction:send("UnlockPadlock", { padlock_index = plan.grave, floor_index = plan.floor })
            if not ctx.waitUntil(function()
                local opened = openedSet()
                return opened[plan.floor * E.OpenedIdPerFloor + plan.grave] == true
            end, 6) then
                return false, "the grave did not open (answer: " .. tostring(answer) .. ")"
            end
            local set = openedSet()
            if not set[plan.floor * E.OpenedIdPerFloor + plan.grave] then
                return false, "Crypt: expected grave opening not confirmed"
            end
            ctx.logger:success("Event", "Crypt: opened " .. plan.reward .. " on floor " .. plan.floor)
            if preferTwig then
                local _, placedNow, heldNow = EventTasks.nestState(ctx.gameData:get(KEYS.PigeonNest),
                    #ctx.gameData:itemsOfId(TOYS, E.Twig), 0)
                ctx.logger:info("AutoNest", string.format("Twig progress: %d/%d", placedNow + heldNow, E.NestTwigs))
            end
            return true
        end,
    }
    EventTasks.pigeonNest = {
        id = "pigeon_nest",
        timeoutSeconds = 150,
        run = function(ctx)
            local function placed()
                local data = ctx.gameData:get(KEYS.PigeonNest)
                return type(data) == "table" and tonumber(data.twigs_contributed) or 0
            end
            local twigs = ctx.gameData:itemsOfId(TOYS, E.Twig)
            local autoNest = ctx.farmConfig.Event.AutoNest ~= false
            if #twigs == 0 or placed() >= E.NestTwigs then
                return true
            end
            if autoNest and placed() + #twigs < E.NestTwigs then
                return true
            end
            local arrived, why = ctx.travel:goTo("HauntedHotel")
            if not arrived then
                return false, "travel to the Hotel failed: " .. tostring(why)
            end
            if autoNest then
                ctx.logger:info("AutoNest", string.format("Building Nest (%d placed + %d twigs)", placed(), #twigs))
            end
            for _, twig in ipairs(twigs) do
                if placed() >= E.NestTwigs then
                    break
                end
                local before = placed()
                local held, holdWhy = hold(ctx, twig, TOYS)
                if not held then
                    return false, holdWhy
                end
                task.wait(1)
                local _, answer = ctx.interaction:send("PigeonNestTwig", { unique = twig })
                if not ctx.waitUntil(function()
                    return placed() > before
                end, 6) then
                    return false, "the nest did not take the twig (answer: " .. tostring(answer) .. ")"
                end
                ctx.logger:success("Event", string.format("Pigeon nest: twig placed (%d of %d)", placed(), E.NestTwigs))
                if not autoNest then
                    return true
                end
            end
            if autoNest then
                ctx.logger:info("AutoNest", "Verifying Nest")
                if placed() < E.NestTwigs then
                    return false, string.format("nest not finished after building (%d of %d)", placed(), E.NestTwigs)
                end
                ctx.logger:success("AutoNest", "Nest completed")
            end
            return true
        end,
    }
    --[[
        AUTO SKELICORN (v2.1.4, Farm.Event.AutoSkelicorn, off by default). Steps, each checked in your data:
          1) no Lightning Lever and not installed: the Crypt task looks for a grave whose reward has "lever" in it
          2) lever in the backpack: to the machine by the Manor (a map model named "...lightning...lever...")
          3) hold the lever (ToolAPI/Equip(unique, {})), then Halloween2026/LightningLeverDeliver() with no arguments,
             ONCE - exactly the recorded manual install (GameConstants.Event.SkelicornArgs). Activate was not part of it
             and is not sent
          4) halloween_2026_lightning_lever_manager tells "installed": never delivered twice
          5) candy >= the price: ShopAPI/BuyItem("pets", skelicorn, { buy_count = 1 }) (the Candy Shop's own call)
          6) one Skelicorn bought (or already owned): idle
        The lever manager's field names are not known yet: its content is logged once, and "installed" is read from
        fields named like install / deliver / placed (plus what this session saw: a delivered lever leaves the backpack).
    ]]
    EventTasks._skelicorn = { delivered = false, activated = false, bought = false, logged = nil }
    -- v2.1.4 (user: "Mega Skelicorn on every account, no Skelicorn anywhere"): every Skelicorn step and what it saw goes
    -- to its own small file, AdoptMeFarm/skelicorn.log (kept even when the normal logs are off), to send as it is
    EventTasks._skelicornNotes = {}
    function EventTasks.skelicornNote(text)
        local notes = EventTasks._skelicornNotes
        table.insert(notes, os.date("%m-%d %H:%M:%S ") .. tostring(text))
        while #notes > 80 do table.remove(notes, 1) end
        -- No local file is created in the private build.
    end
    function EventTasks.findLever(gameData)
        local inventory = gameData:get(KEYS.Inventory)
        for category, items in pairs(type(inventory) == "table" and inventory or {}) do
            if type(items) == "table" then
                for unique, item in pairs(items) do
                    -- the exact id, or any item whose id names a lever (the id was never seen in a backpack yet)
                    local id = type(item) == "table" and string.lower(tostring(item.id or item.kind or "")) or ""
                    if id == E.LightningLever or (id ~= "" and string.find(id, "lever", 1, true)) then
                        if id ~= E.LightningLever and EventTasks._leverIdNoted ~= id then
                            EventTasks._leverIdNoted = id
                            EventTasks.skelicornNote("lever-like item in " .. tostring(category) .. ": " .. id)
                        end
                        return tostring(item.unique or unique), category
                    end
                end
            end
        end
        return nil
    end
    function EventTasks.leverState(manager)
        local installed, activated = false, false
        local function scan(t, depth)
            for k, v in pairs(t) do
                local key = string.lower(tostring(k))
                if type(v) == "table" then
                    if depth < 2 then
                        scan(v, depth + 1)
                    end
                elseif v == true or (type(v) == "number" and v > 0) then
                    if string.find(key, "install") or string.find(key, "deliver") or string.find(key, "placed")
                        or string.find(key, "insert") then
                        installed = true
                    end
                    if string.find(key, "activ") or string.find(key, "pull") then
                        activated = true
                    end
                end
            end
        end
        if type(manager) == "table" then
            -- skelicorn.log 2026-10-11: the manager is { lever_state = "deactivated" } before the lever goes in.
            -- Any other state (installed / activated / ...) = the machine has my lever
            local leverState = manager.lever_state
            if type(leverState) == "string" then
                local lower = string.lower(leverState)
                if lower == "activated" then return true, true end
                if lower == "installed" or lower == "delivered" then return true, false end
                return false, false -- Unknown strings are not proof of installation.
            end
            scan(manager, 0)
        end
        return installed, activated
    end
    function EventTasks.skelicornPrice()
        local price = E.SkelicornPrice
        pcall(function()
            local fsys = game:GetService("ReplicatedStorage"):FindFirstChild("Fsys")
            local db = fsys and require(fsys).load("InventoryDB")
            local entry = type(db) == "table" and type(db.pets) == "table" and db.pets[E.Skelicorn]
            local cost = type(entry) == "table" and tonumber(entry.cost or entry.price)
            if cost and cost > 0 then
                price = cost
            end
        end)
        return price
    end
    -- the next step, or nil (nothing to do now). "crypt" = find the lever in the Crypt first.
    -- user 2026-10-11: "the preset buys 5 Skelicorns, 7 when the account walks 2 pets or has the Pet Pen pass: the
    -- fastest way to a mega neon". How many copies grow at once = my pet slots + the Pet Pen's slots. The pen's size is
    -- read from its data when a field tells it (slots / capacity / max), else Farm.Event.PetPenSlots (4).
    -- the way to a mega neon of one kind, counted: growing / full grown (waiting for 4) / neon / mega neon
    function EventTasks.kindProgress(gameData, kind)
        local grow, grown, neon, mega = 0, 0, 0, 0
        for unique in pairs(gameData:petUniquesOfKind(kind)) do
            if gameData:isPetMega(unique) then
                mega += 1
            elseif gameData:isPetNeon(unique) then
                neon += 1
            elseif (gameData:petAge(unique) or 0) >= GameConstants.FullGrownAge then
                grown += 1
            else
                grow += 1
            end
        end
        return string.format("growing %d, full grown %d, neon %d, mega %d", grow, grown, neon, mega)
    end
    function EventTasks.copiesWanted(gameData, farm)
        local event = type(farm) == "table" and type(farm.Event) == "table" and farm.Event or {}
        local penSlots = tonumber(event.PetPenSlots) or E.PetPenSlots or 4
        local pen = gameData:get(KEYS.PetPen)
        if type(pen) == "table" then
            for key, value in pairs(pen) do
                local name = string.lower(tostring(key))
                if type(value) == "number" and value >= 1 and value <= 12 and (string.find(name, "slot", 1, true)
                    or string.find(name, "capacity", 1, true) or string.find(name, "max_pets", 1, true)) then
                    penSlots = math.max(penSlots, value)
                end
            end
        end
        local walking = 1
        pcall(function()
            walking = math.max(1, #gameData:equippedPetList())
        end)
        return penSlots + walking
    end
    -- on with the toggle, or with "Mega Skelicorn" / Mega a Pet = Skelicorn
    -- v2.1.6 (user: "Skelicorn in the Shop: bought every 0.5 s once the machine sells, with a max buy"): the Candy
    -- Shop pick. Returns the CandyPets settings when Skelicorn is picked and the shop is on.
    function EventTasks.skelicornShop(farm)
        local event = type(farm) == "table" and type(farm.Event) == "table" and farm.Event
        local shop = event and type(event.CandyPets) == "table" and event.CandyPets
        if not (shop and shop.Enabled and type(shop.Pick) == "table") then
            return nil
        end
        for _, id in ipairs(shop.Pick) do
            if id == E.Skelicorn then
                return shop
            end
        end
        return nil
    end
    -- Max buy (user: "as many as the candy pays for, in one go"): one BuyItem with buy_count = that many, then the
    -- copies that arrived are counted. Returns how many arrived.
    function EventTasks.buyMany(ctx, id, count)
        local before = ctx.gameData:petUniquesOfKind(id)
        local sent, answer = ctx.interaction:send("BuyItem", GameConstants.EggCategory, id, { buy_count = count })
        local got = 0
        local function arrived()
            got = 0
            for unique in pairs(ctx.gameData:petUniquesOfKind(id)) do
                if not before[unique] then
                    got += 1
                end
            end
            return got >= count
        end
        ctx.waitUntil(arrived, 10)
        arrived()
        return got, sent, answer
    end
    function EventTasks.skelicornOn(farm)
        local focus = GameConstants.focusOf(farm)
        return (type(farm) == "table" and type(farm.Event) == "table" and farm.Event.AutoSkelicorn == true)
            or (focus ~= nil and focus.kind == "skelicorn") or EventTasks.skelicornShop(farm) ~= nil
    end
    function EventTasks.skelicornStep(gameData, farm)
        local state = EventTasks._skelicorn
        local focus = GameConstants.focusOf(farm)
        if focus and focus.kind == "skelicorn" then
            -- Mega Skelicorn: keep buying while fewer than Pet Pen slots + 1 Skelicorns still grow
            local wanted = EventTasks.copiesWanted(gameData, farm)
            local growing = gameData:growingCopies(E.Skelicorn)
            if growing >= wanted then
                return nil, string.format("%d Skelicorns still grow (%d wanted): idle", growing, wanted)
            end
        elseif EventTasks.skelicornShop(farm) then
            local shop = EventTasks.skelicornShop(farm)
            local candy = tonumber(gameData:get(KEYS.Candy)) or 0
            if candy - (tonumber(shop.KeepCandy) or 0) < EventTasks.skelicornPrice() then
                return nil, string.format("Candy Shop: waiting for candy (%d / %d)", candy, EventTasks.skelicornPrice())
            end
        elseif state.bought or next(gameData:petUniquesOfKind(E.Skelicorn)) ~= nil then
            return nil, "a Skelicorn is yours: idle"
        end
        local installed, activated = EventTasks.leverState(gameData:get(KEYS.LightningLever))
        -- owning a Skelicorn proves the machine was unlocked (the manager's field names are still a guess)
        installed = installed or state.delivered or next(gameData:petUniquesOfKind(E.Skelicorn)) ~= nil
        activated = activated or state.activated
        if not installed then
            if EventTasks.findLever(gameData) or EventTasks.leverWaiting(gameData) then
                return "install"
            end
            -- skelicorn.log 2026-10-11: 3.3M candy, 0 Rusty Keys, no lever -> "crypt" forever and nothing bought. The
            -- shop may sell it without this account's own lever: try the buy (the Candy Shop's own call; refused = no
            -- cost), and only after a refusal go for the lever (a new try every 30 min)
            local candyNow = tonumber(gameData:get(KEYS.Candy)) or 0
            -- user: "no point waiting 30 min": a new try at every Skelicorn check (120 s), the Crypt runs in between
            if candyNow >= EventTasks.skelicornPrice() and not state.leverRequired
                and Util.now() - (state.buyRefusedAt or -1e9) > 110 then
                return "buy"
            end
            return "crypt"
        end
        if not activated and type(E.SkelicornArgs) == "table" and type(E.SkelicornArgs.activate) == "table" then
            return "activate" -- only if an Activate call is ever recorded: the recorded install needed none
        end
        local candy = tonumber(gameData:get(KEYS.Candy)) or 0
        if candy >= EventTasks.skelicornPrice() then
            return "buy"
        end
        return nil, string.format("waiting for candy (%d / %d)", candy, EventTasks.skelicornPrice())
    end
    -- the lever still has to be found and put in (whatever step a buy probe shows)
    -- user 2026-10-11: every account showed lever_state "deactivated", and "Use" at the machine worked: the lever was
    -- already this account's (found in the Crypt), only not put in. "deactivated" = go and Use it (a new try every 10 min
    -- when a Use changed nothing)
    function EventTasks.leverWaiting(gameData)
        -- user 2026-10-11 (the lever was not in my backpack, Use worked anyway): Pull first, whatever the data says;
        -- again every 10 min while the shop says "not for sale"
        -- (with candy for one: only the buy right after it tells whether the pull worked)
        return Util.now() - (EventTasks._skelicorn.useTriedAt or -1e9) > 600
            and (tonumber(gameData:get(KEYS.Candy)) or 0) >= EventTasks.skelicornPrice()
    end
    function EventTasks.skelicornNeedsLever(gameData)
        local state = EventTasks._skelicorn
        local installed = EventTasks.leverState(gameData:get(KEYS.LightningLever))
        return not (installed or state.delivered) and EventTasks.findLever(gameData) == nil
            and not EventTasks.leverWaiting(gameData)
    end
    -- the "Use" button the game shows next to an interactable (InteractionsApp): found by its text, clicked with the
    -- script's click methods until it goes away. Returns a short description of what happened.
    function EventTasks.pressUseButton(ctx)
        local gui = game:GetService("Players").LocalPlayer:FindFirstChildOfClass("PlayerGui")
        local function findButton()
            local found
            pcall(function()
                for _, node in ipairs(gui and gui:GetDescendants() or {}) do
                    if (node:IsA("TextLabel") or node:IsA("TextButton")) and string.lower(tostring(node.Text)) == "use" then
                        local visible = true
                        local walk = node
                        while walk and walk ~= gui do
                            if walk:IsA("GuiObject") and walk.Visible == false then
                                visible = false
                            elseif walk:IsA("ScreenGui") and walk.Enabled == false then
                                visible = false
                            end
                            walk = walk.Parent
                        end
                        if visible then
                            local button = node:IsA("GuiButton") and node or node:FindFirstAncestorWhichIsA("GuiButton")
                            if not button and node.Parent then
                                button = node.Parent:FindFirstChildWhichIsA("GuiButton", true)
                            end
                            if button then
                                found = button
                                return
                            end
                        end
                    end
                end
            end)
            return found
        end
        -- user 2026-10-11: "the others could not pull, the pop-ups on the screen". Only while the Use button is
        -- pressed every other game screen is switched off (put back right after), so nothing covers the button
        local hidden = {}
        pcall(function()
            for _, screen in ipairs(gui and gui:GetChildren() or {}) do
                if screen:IsA("ScreenGui") and screen.Enabled and screen.Name ~= "InteractionsApp" and not string.find(screen.Name, "Adopt", 1, true) then
                    screen.Enabled = false
                    table.insert(hidden, screen)
                end
            end
        end)
        local function restore()
            for _, screen in ipairs(hidden) do
                pcall(function()
                    screen.Enabled = true
                end)
            end
        end
        ctx.maid:Give(restore)
        local button
        ctx.waitUntil(function()
            button = findButton()
            return button ~= nil
        end, 4)
        if not button then
            restore()
            return "no Use button on screen"
        end
        local path = button:GetFullName()
        for _, method in ipairs(ctx.interaction.CLICK_METHODS or {}) do
            local callOk, ran = pcall(ctx.interaction.clickButton, button, method)
            if callOk and ran and ctx.waitUntil(function()
                return button.Parent == nil or findButton() ~= button
            end, 2) then
                restore()
                return "pressed (" .. method .. ", " .. path .. ")"
            end
        end
        restore()
        return "clicked, the button stayed (" .. path .. ")"
    end
    -- user 2026-10-11 (screenshots: at the machine the game shows a hand icon over it, "Use" only once it is picked;
    -- "try every kind of click, the prompt, everything"): every way in, one after the other, all reported
    function EventTasks.useMachine(ctx, machine)
        local done = {}
        local player = game:GetService("Players").LocalPlayer
        local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
        local part, node = machine.part, machine.node
        local scope = { node }

        -- 1) prompts and click detectors on / around the machine
        local seenPrompts = {}
        for _, holder in ipairs(scope) do
            local candidates = holder:GetDescendants()
            table.insert(candidates, 1, holder)
            for _, item in ipairs(candidates) do
                if item:IsA("ProximityPrompt") and not seenPrompts[item] then
                    seenPrompts[item] = true
                    if type(fireproximityprompt) == "function" then
                        pcall(fireproximityprompt, item)
                        table.insert(done, "prompt " .. item.Name)
                        return table.concat(done, ", ")
                    end
                    pcall(function()
                        item:InputHoldBegin()
                        task.wait(math.max(0.1, tonumber(item.HoldDuration) or 0) + 0.1)
                        item:InputHoldEnd()
                    end)
                    return "prompt hold submitted"
                elseif item:IsA("ClickDetector") and type(fireclickdetector) == "function" then
                    pcall(fireclickdetector, item)
                    table.insert(done, "clickdetector " .. item.Name)
                    return table.concat(done, ", ")
                end
            end
        end
        -- 2) touch the machine's part
        if root and type(firetouchinterest) == "function" then
            pcall(function()
                firetouchinterest(root, part, 0)
                task.wait(0.1)
                firetouchinterest(root, part, 1)
            end)
            table.insert(done, "touch")
        end
        -- 3) the game's hand icon over the machine: the on-screen button nearest to where the machine is drawn
        local camera = workspace.CurrentCamera
        pcall(function() -- the camera looks at the machine so its icon is on the screen
            if root and camera then
                camera.CFrame = CFrame.lookAt(root.Position + Vector3.new(0, 6, 0) - (part.Position - root.Position).Unit * 8,
                    part.Position)
            end
        end)
        task.wait(0.4)
        local gui = player:FindFirstChildOfClass("PlayerGui")
        local function nearestHand()
            local best, bestDist
            pcall(function()
                local point, onScreen = camera:WorldToViewportPoint(part.Position)
                if not onScreen then
                    return
                end
                local inset = game:GetService("GuiService"):GetGuiInset()
                for _, app in ipairs({ gui:FindFirstChild("InteractionsApp") }) do
                    for _, button in ipairs(app:GetDescendants()) do
                        if button:IsA("GuiButton") and button.Visible and button.AbsoluteSize.X > 4 then
                            local cx = button.AbsolutePosition.X + button.AbsoluteSize.X / 2
                            local cy = button.AbsolutePosition.Y + button.AbsoluteSize.Y / 2 + inset.Y
                            local d = math.sqrt((cx - point.X) ^ 2 + (cy - point.Y) ^ 2)
                            if d < 160 and (not bestDist or d < bestDist) then
                                best, bestDist = button, d
                            end
                        end
                    end
                end
            end)
            return best, bestDist
        end
        local hand, dist = nearestHand()
        if hand then
            for _, method in ipairs(ctx.interaction.CLICK_METHODS or {}) do
                pcall(function()
                    ctx.interaction.clickButton(hand, method)
                end)
                task.wait(0.3)
            end
            table.insert(done, string.format("hand icon %s (%d px)", hand:GetFullName(), math.floor(dist or 0)))
        else
            table.insert(done, "no hand icon near the machine")
        end
        -- 3b) icons drawn in the world (BillboardGui) on or next to the machine
        pcall(function()
            local count = 0
            for _, container in ipairs({ gui, node, node.Parent }) do
                for _, board in ipairs(container and container:GetDescendants() or {}) do
                    if board:IsA("BillboardGui") then
                        local adornee = board.Adornee or board.Parent
                        local ok, pos = pcall(function()
                            return adornee:IsA("BasePart") and adornee.Position or adornee:GetPivot().Position
                        end)
                        if ok and pos and (pos - part.Position).Magnitude < 12 then
                            for _, button in ipairs(board:GetDescendants()) do
                                if button:IsA("GuiButton") then
                                    for _, method in ipairs({ "firesignal", "connections" }) do
                                        pcall(function()
                                            ctx.interaction.clickButton(button, method)
                                        end)
                                    end
                                    count += 1
                                end
                            end
                        end
                    end
                end
            end
            if count > 0 then
                table.insert(done, count .. " world icon button(s)")
            end
        end)
        -- 4) the "Use" label that shows once the machine is picked
        table.insert(done, "use label: " .. tostring(EventTasks.pressUseButton(ctx)))
        -- 5) the interact key
        pcall(function()
            local vim = game:GetService("VirtualInputManager")
            vim:SendKeyEvent(true, Enum.KeyCode.E, false, game)
            task.wait(0.15)
            vim:SendKeyEvent(false, Enum.KeyCode.E, false, game)
            table.insert(done, "key E")
        end)
        pcall(function()
            camera.CameraType = Enum.CameraType.Custom
        end)
        return table.concat(done, ", ")
    end
    function EventTasks.findLeverMachine()
        local best
        pcall(function() -- the part the user found in Dex first
            for _, interior in ipairs(workspace:FindFirstChild("Interiors") and workspace.Interiors:GetChildren() or {}) do
                if string.sub(interior.Name, 1, 7) == "MainMap" then
                    local node = interior
                    for _, name in ipairs(E.LeverInteractPath) do
                        node = node and node:FindFirstChild(name)
                    end
                    if node then
                        local part = node:IsA("BasePart") and node or node:FindFirstChildWhichIsA("BasePart", true)
                        if part then
                            best = { node = node, part = part, prompt = node:FindFirstChildWhichIsA("ProximityPrompt", true) }
                            return
                        end
                    end
                end
            end
        end)
        if best then
            return best
        end
        pcall(function()
            for _, node in ipairs(workspace:GetDescendants()) do
                if node:IsA("Model") or node:IsA("BasePart") then
                    local name = string.lower(node.Name)
                    local all = true
                    for _, word in ipairs(E.LeverMachinePatterns) do
                        if not string.find(name, word, 1, true) then
                            all = false
                        end
                    end
                    if all then
                        local part = node:IsA("BasePart") and node or node.PrimaryPart or node:FindFirstChildWhichIsA("BasePart", true)
                        if part then
                            best = best or { node = node, part = part }
                        end
                    end
                end
            end
            if best then
                return
            end
            -- user 2026-10-11: "went to the machine and pressed Use": the machine has a prompt. Its name is not known,
            -- so the prompt whose text / name / parent's name speaks of the lever or the Skelicorn is the machine
            for _, node in ipairs(workspace:GetDescendants()) do
                if node:IsA("ProximityPrompt") then
                    local text = string.lower(table.concat({ tostring(node.ActionText), tostring(node.ObjectText), node.Name,
                        node.Parent and node.Parent.Name or "", node.Parent and node.Parent.Parent and node.Parent.Parent.Name or "" }, " "))
                    if string.find(text, "lever", 1, true) or string.find(text, "lightning", 1, true)
                        or string.find(text, "skelicorn", 1, true) then
                        local holder = node.Parent
                        local part = holder and (holder:IsA("BasePart") and holder or holder:FindFirstChildWhichIsA("BasePart", true))
                        if not part and holder and holder:IsA("Attachment") then
                            part = holder.Parent
                        end
                        if part and part:IsA("BasePart") then
                            best = { node = holder, part = part, prompt = node }
                            return
                        end
                    end
                end
            end
        end)
        if best then
            EventTasks.skelicornNote("lever machine: " .. best.node:GetFullName() .. (best.prompt and (" (prompt '"
                .. tostring(best.prompt.ActionText) .. "')") or ""))
        end
        return best
    end
    local function leverArgs(kind, leverUnique)
        local recorded = type(E.SkelicornArgs) == "table" and E.SkelicornArgs[kind]
        if type(recorded) ~= "table" then
            return nil
        end
        local function fill(v, depth)
            if v == "$LEVER" then
                return leverUnique
            end
            if type(v) == "table" and depth < 3 then
                local copy = {}
                for k, x in pairs(v) do
                    copy[k] = fill(x, depth + 1)
                end
                return copy
            end
            return v
        end
        local args = {}
        for i, v in ipairs(recorded) do
            args[i] = fill(v, 0)
        end
        return args
    end
    EventTasks.skelicorn = {
        id = "skelicorn",
        timeoutSeconds = 200,
        run = function(ctx)
            local state = EventTasks._skelicorn
            local manager = ctx.gameData:get(KEYS.LightningLever)
            local text = Util.truncate(Util.jsonEncode(manager) or tostring(manager), 300)
            if text ~= state.logged then -- the manager's fields, once per change: so "installed" can be read for sure
                state.logged = text
                ctx.logger:info("Skelicorn", "Lever data: " .. text)
                EventTasks.skelicornNote("Lever data: " .. text)
            end
            local step, why = EventTasks.skelicornStep(ctx.gameData, ctx.farmConfig)
            if not step or step == "crypt" then
                ctx.logger:info("Skelicorn", tostring(why or "no lever yet: the Crypt looks for it"))
                return true
            end
            local function buyOne()
                local price = EventTasks.skelicornPrice()
                local before = ctx.gameData:petUniquesOfKind(E.Skelicorn)
                local candyBefore = tonumber(ctx.gameData:get(KEYS.Candy)) or 0
                local sent, answer = ctx.interaction:send("BuyItem", GameConstants.EggCategory, E.Skelicorn, { buy_count = 1 })
                local got = ctx.waitUntil(function()
                    for unique in pairs(ctx.gameData:petUniquesOfKind(E.Skelicorn)) do
                        if not before[unique] then
                            return true
                        end
                    end
                    return false
                end, 8)
                if not got then
                    state.buyRefusedAt = Util.now()
                    if string.find(string.lower(tostring(answer)), "not for sale", 1, true) then
                        -- skelicorn.log 2026-10-11: "not for sale" until MY lever is in the machine: no more tries
                        -- (they counted as failures and paused the lever install too); the Crypt for the lever
                        state.leverRequired = true
                        EventTasks.skelicornNote("shop: not for sale until this account's lever is in the machine")
                        return false, "Skelicorn unavailable until lever installation is confirmed"
                    end
                    -- (skelicorn.log: "no answer from server" twice = 2 failures toward the 15 min pause of this task)
                    EventTasks.skelicornNote(string.format("buy: no Skelicorn (answer %s %s): again in 2 min", tostring(sent),
                        Util.truncate(tostring(answer), 60)))
                    return false, "Skelicorn purchase unconfirmed"
                end
                state.bought = true
                state.delivered = true -- it sells: whatever the lever manager says, the machine is open for me
                local focused = GameConstants.focusKind(ctx.farmConfig) == E.Skelicorn
                ctx.logger:success("Skelicorn", string.format("Skelicorn bought for %d candy: %s",
                    candyBefore - (tonumber(ctx.gameData:get(KEYS.Candy)) or candyBefore),
                    focused and "Mega Skelicorn buys the next one at 120k candy" or "Auto Skelicorn is done"))
                EventTasks.skelicornNote("Skelicorn bought for " .. price .. " candy")
                return true
            end
            local shop = EventTasks.skelicornShop(ctx.farmConfig)
            if step == "buy" and shop and GameConstants.focusKind(ctx.farmConfig) ~= E.Skelicorn then
                -- Candy Shop pick: one every 0.5 s until the candy (above KeepCandy) runs out; Max buy: all in one go
                local keep = tonumber(shop.KeepCandy) or 0
                local price = EventTasks.skelicornPrice()
                local function affordable()
                    return math.floor(((tonumber(ctx.gameData:get(KEYS.Candy)) or 0) - keep) / price)
                end
                local count = 0
                if shop.MaxBuy == true and affordable() > 1 then
                    local want = math.min(affordable(), 50)
                    local got, sent, answer = EventTasks.buyMany(ctx, E.Skelicorn, want)
                    count = got
                    ctx.logger:info("Skelicorn", string.format("Candy Shop Max buy: %d of %d Skelicorns in one purchase%s",
                        got, want, got == 0 and (" (answer " .. tostring(sent) .. " " .. Util.truncate(tostring(answer), 60)
                        .. "): one by one instead") or ""))
                    if got > 0 then
                        state.bought, state.delivered = true, true
                    end
                end
                while count < 60 and affordable() >= 1 do
                    state.bought = false
                    buyOne()
                    if not state.bought then
                        break -- not sold (yet): the machine is not open for me
                    end
                    count += 1
                    task.wait(0.5)
                end
                state.shopBought = (state.shopBought or 0) + count
                ctx.logger:info("Skelicorn", string.format("Candy Shop: %d Skelicorn%s bought now, %d this session", count,
                    count == 1 and "" or "s", state.shopBought))
                if count > 0 then
                    EventTasks.skelicornNote(string.format("Candy Shop: bought %d Skelicorns (%d this session)", count,
                        state.shopBought))
                end
                return true
            end
            if step == "buy" then
                -- (user: "3M candy and it buys one now and then"): every copy the slots take, in one go
                local focused = GameConstants.focusKind(ctx.farmConfig) == E.Skelicorn
                local ok = buyOne()
                local count = state.bought and 1 or 0
                while focused and ok and state.bought and count < 12
                    and ctx.gameData:growingCopies(E.Skelicorn) < EventTasks.copiesWanted(ctx.gameData, ctx.farmConfig)
                    and (tonumber(ctx.gameData:get(KEYS.Candy)) or 0) >= EventTasks.skelicornPrice() do
                    task.wait(0.5)
                    local before = ctx.gameData:growingCopies(E.Skelicorn)
                    ok = buyOne()
                    if ctx.gameData:growingCopies(E.Skelicorn) <= before then
                        break
                    end
                    count += 1
                end
                if count > 1 then
                    EventTasks.skelicornNote(string.format("bought %d Skelicorns in a row (%d grow, %d wanted)", count,
                        ctx.gameData:growingCopies(E.Skelicorn), EventTasks.copiesWanted(ctx.gameData, ctx.farmConfig)))
                end
                return ok
            end
            -- install / activate: at the machine by the Manor
            local arrived, travelWhy = ctx.travel:goTo("MainMap")
            if not arrived then
                return false, "travel to the main map failed: " .. tostring(travelWhy)
            end
            local machine = EventTasks.findLeverMachine()
            if not machine then
                return false, "the lever machine was not found in the map (a model named lightning + lever)"
            end
            local near, nearWhy = ctx.interaction:teleportNearPart(machine.part, 6)
            if not near then
                return false, "could not stand at the machine: " .. tostring(nearWhy)
            end
            ctx.logger:info("Skelicorn", "At the machine: " .. machine.node:GetFullName())
            local lever = EventTasks.findLever(ctx.gameData)
            local args = leverArgs(step == "install" and "deliver" or "activate", lever)
            if step == "install" and args and lever then
                -- as recorded: the lever is held first (ToolAPI/Equip(unique, {})), then Deliver with no arguments
                ctx.interaction:send("EquipItem", lever, {})
                task.wait(0.6)
            end
            if not args then
                return false, "the " .. (step == "install" and "LightningLeverDeliver" or "LightningLeverActivate")
                    .. " arguments are not recorded yet (one manual install with a remote spy, then SkelicornArgs)"
            end
            ctx.logger:info("Skelicorn", "At the lever machine (" .. machine.node.Name .. "): Use")
            local signature = function()
                return (Util.jsonEncode(ctx.gameData:get(KEYS.LightningLever)) or "") .. "|" .. tostring(EventTasks.findLever(ctx.gameData))
            end
            local before = signature()
            -- user 2026-10-11 (screenshot): the bot stood at the machine, the game showed its "Use" button, nothing was
            -- pressed; the user pressed it and it worked (without a lever in the backpack). So the game's own Use button
            -- is pressed first (the same click as the main menu's Play), the recorded Deliver after it
            local pressed = EventTasks.useMachine(ctx, machine)
            EventTasks.skelicornNote("Use at the machine: " .. tostring(pressed))
            local sent, answer = ctx.interaction:send(step == "install" and "LightningLeverDeliver" or "LightningLeverActivate",
                table.unpack(args))
            local changed = ctx.waitUntil(function()
                return signature() ~= before
            end, 6)
            if not changed and machine.prompt and type(fireproximityprompt) == "function" then
                -- the machine's own "Use" prompt, as the user pressed it
                pcall(fireproximityprompt, machine.prompt)
                changed = ctx.waitUntil(function()
                    return signature() ~= before
                end, 6)
            end
            if step == "install" then
                state.useTriedAt = Util.now()
                EventTasks.skelicornNote("Pull (Use) at the lever machine: " .. (changed and "my data changed" or "no data change")
                    .. " (answer " .. tostring(sent) .. " " .. Util.truncate(tostring(answer), 60) .. ")")
                if not changed then
                    -- user 2026-10-11: "Pull -> Buy -> failed -> the Crypt for the lever -> 120k candy -> again": the game
                    -- confirms a working pull with its own events, not always in my data, so the buy decides
                    state.leverRequired = false
                    if (tonumber(ctx.gameData:get(KEYS.Candy)) or 0) >= EventTasks.skelicornPrice() then
                        task.wait(1)
                        local bought = buyOne()
                        if EventTasks._skelicorn.bought then
                            state.delivered = true
                        end
                        return bought
                    end
                    return true
                end
                state.leverRequired = false
                state.delivered = true
                if (tonumber(ctx.gameData:get(KEYS.Candy)) or 0) >= EventTasks.skelicornPrice() then
                    -- (user: "one of them pulled but did not buy"): the buy right away, not at the next check
                    task.wait(1)
                    ctx.logger:success("Skelicorn", "Lightning Lever pulled: buying the Skelicorn now")
                    return buyOne()
                end
                state.activated = true -- the recorded install: Deliver alone unlocked the Skelicorn
                ctx.logger:success("Skelicorn", "Lightning Lever installed: the Skelicorn is unlocked")
            else
                state.activated = true -- pulled once; the data shows more when its fields are known
                ctx.logger:success("Skelicorn", "Lightning Lever pulled" .. (changed and "" or " (no data change seen)"))
            end
            return true
        end,
    }
    do -- every Auto Skelicorn result into AdoptMeFarm/skelicorn.log too
        local inner = EventTasks.skelicorn.run
        EventTasks.skelicorn.run = function(ctx, ...)
            local ok, why = inner(ctx, ...)
            EventTasks.skelicornNote(ok and "task done" or ("task FAILED: " .. tostring(why)))
            return ok, why
        end
    end
    -- The saved character contains a real Tool named GhostVacuumTool and its dynamic StringValue "unique".
    -- Never hardcode the exporting player's unique ID or infer a token from the tool's color.
    function EventTasks.vacuumItem(ctx)
        local character = game:GetService("Players").LocalPlayer.Character
        local tool = character and character:FindFirstChild("GhostVacuumTool")
        local unique = tool and tool:IsA("Tool") and tool:FindFirstChild("unique")
        if unique and unique:IsA("StringValue") and unique.Value ~= "" then return unique.Value, true end
        local items = ctx.gameData:itemsOfId(TOYS, E.Vacuum)
        return items[1], false
    end
    function EventTasks.startVacuum(ctx, vacuum)
        local sent, returned = ctx.interaction:send("UseTool", vacuum, "START")
        if not sent then return false, tostring(returned) end
        -- The supplied older implementation generated use_token locally. A nil/boolean reply is not rejection.
        -- Preserve an explicit returned token when present; otherwise retain that established client sequence.
        local token = type(returned) == "string" and returned ~= "" and returned or EventTasks.newToken()
        return true, token
    end
    EventTasks.ghostGallery = {
        id = "ghost_gallery",
        timeoutSeconds = 420,
        run = function(ctx, group)
            local mg = ctx.minigame
            if not mg or not mg.available then return false, "minigame messages unavailable" end
            local function inRound() return ctx.travel:isAt(E.MinigameInteriorPrefix) end
            local candyBefore = tonumber(ctx.gameData:get(KEYS.Candy))
            local keysBefore = #ctx.gameData:itemsOfId(TOYS, E.RustyKey)
            local session = mg:activeSession()
            if not session and not inRound() then
                local start = group and group.start
                if not start then return false, "round time unknown" end
                mg:reset() -- Before travelling: never erase a join that arrives during the trip.
                local arrived, why = ctx.travel:goTo("HauntedManor")
                if not arrived then return false, "travel to Manor: " .. tostring(why) end
                if not mg:activeSession() then
                    if ctx.farmConfig.Event.GhostJoinByZone ~= false then ctx.interaction:teleportToJoinZone() end
                    ctx.waitUntil(function() return mg.join or Minigame.serverNow() >= start - 3 end,
                        math.min(65, math.max(0, start - Minigame.serverNow()) + 5))
                    local joinUntil = Util.now() + 30
                    while not mg.joinAcceptedAt and not mg.join and Util.now() < joinUntil do
                        local sent, whyJoin = ctx.interaction:send("MinigameJoin", E.MinigameId, true, nil)
                        if not sent then return false, "minigame join: " .. tostring(whyJoin) end
                        ctx.waitUntil(function() return mg.joinAcceptedAt or mg.join end, 3)
                    end
                end
            end
            if ctx.interaction.protectTransition then ctx.interaction:protectTransition(65) end
            if not ctx.waitUntil(function() session = mg:activeSession(); return session ~= nil end, 35) then
                return false, "no confirmed ghost session ID; waiting for the game's round message"
            end
            local gameId = session
            if not ctx.waitUntil(inRound, 25) then return false, "round accepted, interior arrival unconfirmed" end
            -- A round already joined manually is resumed here without returning to the lobby or resetting messages.
            local vacuum, alreadyHeld
            ctx.waitUntil(function() vacuum, alreadyHeld = EventTasks.vacuumItem(ctx); return vacuum ~= nil end, 12)
            if not vacuum then return false, "loaned GhostVacuumTool / inventory vacuum not replicated" end
            local active, keeperStop, held = nil, nil, { target = nil }
            local cleaned = false
            local function stopContribution()
                if active then
                    local pending = active; active = nil
                    ctx.interaction:send("MinigameMessage", gameId, pending.stopMessage, pending.payload)
                end
                ctx.interaction:send("UseTool", vacuum, "END", nil)
            end
            local function cleanup()
                if cleaned then return end
                cleaned = true
                held.target = nil
                if keeperStop then keeperStop(false) end
                stopContribution()
                if not alreadyHeld then ctx.interaction:send("UnequipItem", vacuum, nil) end
            end
            ctx.maid:Give(cleanup)
            if not alreadyHeld then
                local equipped, why = ctx.interaction:send("EquipItem", vacuum, {})
                if not equipped then cleanup(); return false, "vacuum equip: " .. tostring(why) end
            end
            ctx.waitUntil(function() return mg.enter ~= nil or mg.leave ~= nil end, 10)
            local endTime = mg.enter and mg.enter.endTime or Minigame.serverNow() + 170
            if type(endTime) ~= "number" or endTime ~= endTime or math.abs(endTime) == math.huge then
                cleanup(); return false, "invalid round end time"
            end
            endTime = math.min(endTime, Minigame.serverNow() + 240)
            if mg.enter and mg.enter.intermissionEnd then
                ctx.waitUntil(function() return mg.leave or Minigame.serverNow() >= mg.enter.intermissionEnd end, 40)
            end
            local holdNow, stats
            keeperStop, stats, holdNow = ctx.interaction:keepNear(function()
                if mg.leave or not inRound() then return false end
                local target = held.target
                if not target then return nil end
                if target.kind == "ghost" then
                    if not target.model or not target.model.Parent then return nil end
                    return modelPosition(target.model), 6
                end
                return target.position, E.PropStandOff
            end)
            local attempts, idleSince, lastWarning = 0, nil, -math.huge
            while not mg.leave and inRound() and Minigame.serverNow() < endTime + 5 do
                if mg:activeSession() ~= gameId then cleanup(); return false, "ghost session changed" end
                local target = EventTasks.pickTarget(ctx, workspace:FindFirstChild(E.GhostsFolder), mg)
                held.target = target
                if not target or holdNow() == false then
                    idleSince = idleSince or Util.now()
                    if Util.now() - idleSince > 10 and Util.now() - lastWarning > 15 then
                        lastWarning = Util.now()
                        ctx.logger:warn("Ghost", target and "Target found, but its floor is not ready" or "Waiting for streamed ghosts / haunted props")
                    end
                    task.wait(0.4)
                else
                    idleSince = nil
                    local started, token = EventTasks.startVacuum(ctx, vacuum)
                    if not started then cleanup(); return false, "vacuum start: " .. tostring(token) end
                    local isGhost = target.kind == "ghost"
                    local payload = isGhost and { use_token = token, ghost_id = target.id } or { use_token = token, unique = target.id }
                    local startMessage = isGhost and "start_contribute" or "start_prop_contribute"
                    active = { payload = payload, stopMessage = isGhost and "stop_contribute" or "stop_prop_contribute" }
                    attempts += 1
                    for send = 1, 8 do
                        if mg.leave or not inRound() or mg:activeSession() ~= gameId
                            or (isGhost and not target.model.Parent) or (not isGhost and not mg.haunted[target.id]) then break end
                        local nextTarget = target.boss and send > 1 and EventTasks.pickTarget(ctx, workspace:FindFirstChild(E.GhostsFolder), mg)
                        if nextTarget and not nextTarget.boss then break end
                        local contributed, why = ctx.interaction:send("MinigameMessage", gameId, startMessage, payload)
                        if not contributed then cleanup(); return false, "vacuum contribution: " .. tostring(why) end
                        task.wait(0.3)
                    end
                    stopContribution()
                end
            end
            cleanup()
            ctx.waitUntil(function() return mg.leave ~= nil end, 12)
            local candyAfter = tonumber(ctx.gameData:get(KEYS.Candy))
            local gained = candyBefore and candyAfter and candyAfter - candyBefore or 0
            local reward = mg.leave and tonumber(mg.leave.candy) or 0
            local keysAfter = #ctx.gameData:itemsOfId(TOYS, E.RustyKey)
            ctx.logger:info("Ghost", string.format("Server score %d (%d score messages); attempts %d; candy %+d; keys %+d",
                mg.score, mg.scoreCount, attempts, gained, keysAfter - keysBefore))
            if not mg.leave then return false, "round end unconfirmed" end
            if mg.scoreCount == 0 and reward <= 0 and gained <= 0 then return false, "no score or reward confirmed by the game" end
            ctx.waitUntil(function() return not inRound() end, 15)
            if not inRound() then
                local home, why = ctx.travel:goTo(GameConstants.HouseInteriorName)
                if not home then ctx.logger:warn("Ghost", "Round finished; normal return home pending: " .. tostring(why)) end
            end
            return true
        end,
    }

    EventTasks._journalAt = nil
    EventTasks.hauntlet = {
        id = "hauntlet",
        timeoutSeconds = 1200,
        run = function(ctx, group)
            local h = ctx.hauntlet
            if not h or not h.available then
                return false, "minigame messages are not available"
            end
            local candyBefore = tonumber(ctx.gameData:get(KEYS.Candy))
            local function inRun()
                return ctx.travel:isAt(E.HauntletInteriorPrefix)
            end
            local pending = h.join ~= nil and not h.leave and not h.kicked and Util.now() - h.join.at < 90
            if not pending then
                local arrived, why = ctx.travel:goTo(E.HauntletLobby)
                if not arrived then
                    return false, "travel to the Hotel failed: " .. tostring(why)
                end
                h:reset()
                -- Task is only scheduled near T-45. Enter the circle at T-30 (or immediately if already closer).
                local HAUNTLET_JOIN_LEAD = 30
                local serverNow = Minigame.serverNow()
                local startAt = (group and tonumber(group.start))
                    or EventTasks.nextRoundStart(ctx.gameData:get(KEYS.HauntletCycle), serverNow)
                if startAt and startAt - serverNow > HAUNTLET_JOIN_LEAD then
                    local waitSec = math.floor(startAt - serverNow - HAUNTLET_JOIN_LEAD)
                    ctx.logger:info("Event", string.format(
                        "Hauntlet: next run in ~%ds, waiting until T-%d before entering the circle",
                        math.floor(startAt - serverNow), HAUNTLET_JOIN_LEAD))
                    ctx.waitUntil(function()
                        return h.joinAcceptedAt ~= nil or h.join ~= nil
                            or Minigame.serverNow() >= startAt - HAUNTLET_JOIN_LEAD
                    end, waitSec + 8)
                elseif startAt then
                    ctx.logger:info("Event", string.format(
                        "Hauntlet: cycle in ~%ds, entering join circle now",
                        math.floor(startAt - serverNow)))
                else
                    ctx.logger:info("Event", "Hauntlet: no cycle timestamp, entering join circle")
                end
                if h.join or h.joinAcceptedAt then
                    -- Auto-queued while waiting near the hotel.
                else
                    -- Enter the circle once (retry a few times), then stay. Re-TP only if pushed out.
                    local zoneMoved, zoneInfo = false, "not attempted"
                    for attempt = 1, 3 do
                        zoneMoved, zoneInfo = ctx.interaction:teleportToHauntletJoinZone()
                        if zoneMoved then
                            break
                        end
                        if attempt == 1 then
                            -- v2.1.5: not in the hotel (or it did not load): the trip again, then look again
                            ctx.logger:info("Event", "Hauntlet: join circle not found (" .. tostring(zoneInfo)
                                .. "): going to the hotel again")
                            ctx.travel:goTo("HauntedHotel")
                        end
                        task.wait(1)
                    end
                    if zoneMoved then
                        ctx.logger:info("Event", "Hauntlet: in hotel join circle (" .. tostring(zoneInfo)
                            .. ") — waiting for auto-queue")
                    else
                        ctx.logger:warn("Event", "Hauntlet: join circle unavailable (" .. tostring(zoneInfo) .. ")")
                    end
                    -- Stay until queued. Soft zone refresh only if still not accepted (every 20 s, max ~2 min).
                    local joinUntil = Util.now() + 120
                    local nextZoneRefresh = Util.now() + 20
                    while not h.joinAcceptedAt and not h.join and Util.now() < joinUntil do
                        if zoneMoved and Util.now() >= nextZoneRefresh then
                            ctx.interaction:teleportToHauntletJoinZone()
                            nextZoneRefresh = Util.now() + 20
                        end
                        ctx.waitUntil(function()
                            return h.joinAcceptedAt ~= nil or h.join ~= nil
                        end, 2)
                    end
                    if not h.joinAcceptedAt and not h.join then
                        return false, "not auto-queued from the join circle within 120 s"
                    end
                end
                if not ctx.waitUntil(function()
                    return h.join ~= nil
                end, 90) then
                    return false, "queued, but no run took me in within 90 s"
                end
            else
                ctx.logger:info("Event", "Hauntlet: resuming pending run (" .. tostring(h.join.sessionId) .. ")")
            end
            local sessionId = h.join and h.join.sessionId
            if type(sessionId) ~= "string" then
                return false, "no session id after join"
            end
            -- v2.1.3 (reports: 54 x "not auto-queued", always the round right after a run): one run per 20 min. The
            -- round after this one is skipped (TaskManager:_hauntletRoundDue), the Ghost Gallery gets it instead.
            h.lastRunStart = (group and tonumber(group.start)) or Minigame.serverNow()
            if not ctx.waitUntil(function()
                return h.enter ~= nil or inRun() or h.leave ~= nil or h.kicked ~= nil
            end, 45) then
                return false, "did not get into the run (" .. tostring(sessionId) .. ")"
            end
            local function over()
                return h.leave ~= nil or h.kicked ~= nil
            end
            -- PLAYING (v2.1.1): one room at a time. READING_STATE -> PLANNING (Hauntlet.decide) -> USING_ITEM ->
            -- ENTERING_DOOR (move into the door's circle; the game sends the pick) -> VERIFYING (my picked_door + the
            -- counter that went up = the door I really stand in) -> WAITING_FOR_TRANSITION (doors_opened /
            -- started_room). Nothing counts as done because it was attempted: only the server's answer counts.
            local strategy = E.HauntletStrategy or Hauntlet.DEFAULTS
            local debugMode = E.HauntletDebug == true or h:_squadKey() ~= nil -- every door's reasons for your own accounts
            local function say(text)
                ctx.logger:info("Hauntlet", text)
            end
            local function explain(text)
                if debugMode then
                    ctx.logger:info("Hauntlet", text)
                else
                    ctx.logger:debug("Hauntlet", text)
                end
            end
            local function switchedOff()
                local farm = ctx.farmConfig
                return type(farm) == "table" and (farm.Enabled == false
                    or (type(farm.Event) == "table" and (farm.Event.Enabled == false or farm.Event.Hauntlet == false)))
            end
            pcall(function() -- every room after this one is seen being added (the newest room = mine)
                ctx.interaction:watchHauntlet(h.join and h.join.interior)
            end)
            local picks, itemsUsed, lastSeq, lastCircles = 0, 0, 0, nil
            local lastLink = nil -- { from = the circle group I last picked in, exit = its exit's name }
            local visited = {} -- circle groups of the rooms I already picked in (the bot only ever goes forward)
            -- v2.1.4 BUG B: + where they are (a room's circles can be rebuilt as a new object at the same place)
            local visitedPos = {}
            local moveLockUntil = 0 -- after an electric door's pick: no move while its effect plays
            local base = nil -- the start of the line of rooms (room 1, then each nexus)
            local passed = {} -- circle groups of the rooms before the last nexus (never again)
            local behind = nil -- { base = the previous start, limit = the nexus' distance from it }: closer = behind me
            -- v2.1.4 chain: the circle folder of the room being played, found from the previous room's exit when the
            -- room starts (not from where I picked: others can open the doors before I arrive)
            local prevGroup, prevRoom = nil, nil
            local function Interaction_center(group)
                local ok, center = pcall(function()
                    return ctx.interaction.hauntletCenter(group)
                end)
                return ok and center or nil
            end
            say("Client state synchronized: hearts " .. tostring(h.health or "?") .. "/" .. tostring(h.maxHealth or "?")
                .. ", items " .. Hauntlet.describeItems(h.inventory))
            while not over() do
                if switchedOff() then
                    say("Stopped: Auto Hauntlet or Farm running was switched off")
                    break
                end
                if not ctx.waitUntil(function()
                    return over() or switchedOff() or (h.room ~= nil and h.room.seq ~= lastSeq)
                end, 90) then
                    ctx.logger:warn("Hauntlet", "No new room for 90 s: leaving the run loop")
                    break
                end
                if over() or switchedOff() then
                    break
                end
                local room = h.room
                lastSeq = room.seq
                say(string.format("Room detected: #%d %s/%s, doors %s", room.seq, tostring(room.area), tostring(room.kind),
                    Hauntlet.describeDoors(room.doors)))
                say(string.format("Health: %d/%d%s | Items available: %s", h.health or 3, h.maxHealth or 3,
                    (h.tempHealth or 0) > 0 and (" +" .. h.tempHealth .. " shield") or "", Hauntlet.describeItems(h.inventory)))
                ctx.waitUntil(function() -- the game moves me into the new room first
                    local root = myRoot()
                    return over() or h.room ~= room or (root ~= nil and not root.Anchored)
                end, 6)
                local tried, chosen, circles, bad, steps, failedMoves = {}, nil, nil, {}, 0, 0
                local moveMethod = type(ctx.farmConfig) == "table" and type(ctx.farmConfig.Event) == "table"
                    and ctx.farmConfig.Event.HauntletMove or "tween"
                local moveSeconds = type(ctx.farmConfig) == "table" and type(ctx.farmConfig.Event) == "table"
                    and tonumber(ctx.farmConfig.Event.HauntletMoveSeconds) or nil
                local avoid = {} -- circle groups that took no pick in this room
                local planned, potionsHere, keysHere = false, 0, 0
                -- v2.1.3: one compact line per room for the developer report (HauntletDigest: kept in the report's lines)
                local digest = { items = {}, hearts = string.format("%d/%d%s", h.health or 3, h.maxHealth or 3,
                    (h.tempHealth or 0) > 0 and ("+" .. h.tempHealth) or "") }
                -- v2.1.3 squad: my turn for the shared items (phone, wand, keys); the order is fixed for the room
                local squadOn = type(ctx.farmConfig) == "table" and type(ctx.farmConfig.Event) == "table"
                    and ctx.farmConfig.Event.HauntletSquad ~= false
                local order, rank = h:squadOrder()
                local squadKey = h.squadIds
                local function team()
                    if h.squadIds ~= squadKey then -- the relay answered during the room: the order may change
                        squadKey = h.squadIds
                        order, rank = h:squadOrder()
                    end
                    return squadOn and #order > 1
                end
                if team() then
                    say(string.format("Squad: %d player%s%s, I am #%d (fewest hearts first) | phone turn at %.1f s",
                        #order, #order == 1 and "" or "s", h.squadIds and " (your accounts)" or " (everyone alive)", rank,
                        h:turnAt("cell_phone", rank, strategy)))
                end
                local chainGroup = nil
                local roomGroup = nil -- the circles I picked in, in THIS room (a re-pick there is no going back)
                local chainExit = "Exit"
                if prevRoom and (prevRoom.kind == "nexus" or prevRoom.kind == "final_nexus") then
                    for i = 1, 4 do
                        local d = prevRoom.doors[i]
                        if d and d.kind == "area:" .. tostring(room.area) then
                            chainExit = "Exit" .. i
                        end
                    end
                end
                local chainBroken = false
                local function ensureGroup()
                    if chainBroken then
                        return nil -- the chain pointed back into a passed room: the forward search decides
                    end
                    if chainGroup and chainGroup.Parent then
                        return chainGroup
                    end
                    chainGroup = nil
                    if prevGroup and prevGroup.Parent then
                        local ok, found = pcall(function()
                            return ctx.interaction:hauntletNextGroup(h.join and h.join.interior, prevGroup, chainExit)
                        end)
                        if ok and found then
                            chainGroup = found
                        end
                    end
                    return chainGroup
                end
                ctx.waitUntil(function() -- the next room streams in within 1-2 s
                    return over() or h.room ~= room or ensureGroup() ~= nil or prevGroup == nil
                end, 3)
                -- (v2.1.4 hotbar item sync removed: debug log 2026-10-11, the hotbar counts were stale -> the bot tried items
                -- it did not have, every one was refused and the plan time was gone)
                -- one fixed tie-break per room: equal doors no longer swap places between two looks (room 11 of the
                -- debug log: picked door 3, then "door 1", moved into the next room's circle)
                strategy = setmetatable({ tie = { math.random(), math.random(), math.random(), math.random() } },
                    { __index = E.HauntletStrategy or Hauntlet.DEFAULTS })
                local planSeconds = tonumber(strategy.planSeconds) or Hauntlet.DEFAULTS.planSeconds
                local commitBy = tonumber(strategy.commitBySeconds) or Hauntlet.DEFAULTS.commitBySeconds
                while not over() and h.room == room and not switchedOff() do
                    steps += 1
                    if steps > 150 then
                        ctx.logger:warn("Hauntlet", "Room " .. room.seq .. ": too many steps, waiting for the room to end")
                        ctx.waitUntil(function()
                            return over() or h.room ~= room
                        end, 30)
                        break
                    end
                    local view = h:view()
                    view.ejected = h.ejected
                    view.tried = tried
                    local plan = Hauntlet.decide(view, strategy)
                    if not planned then
                        -- user 2026-10-10: "always draw the plan before the pick" (again after a phone's answer)
                        planned = true
                        local okPlan, planSteps = pcall(Hauntlet.plan, view, strategy)
                        if okPlan and type(planSteps) == "table" and #planSteps > 0 then
                            say(string.format("Plan for room %d (hearts %d/%d%s): %s", room.seq, h.health or 3,
                                h.maxHealth or 3, (h.tempHealth or 0) > 0 and (" +" .. h.tempHealth .. " temp") or "",
                                table.concat(planSteps, " -> ")))
                        end
                    end
                    local t = h:roomElapsed()
                    -- shared item, not my turn yet: someone before me may spend theirs (the answer reaches everyone)
                    if plan.use and Hauntlet.SHARED_ITEMS[plan.use] and team() and t < commitBy then
                        local turnAt = h:turnAt(plan.use, rank, strategy)
                        if t < turnAt then
                            local ghostNow, safeNow, locksNow = h.revealedGhost, room.safe, room.lockVersion
                            explain(string.format("Waiting for my turn (#%d) for the %s: %.1f s -> %.1f s", rank, plan.use,
                                t, turnAt))
                            ctx.waitUntil(function()
                                return over() or h.room ~= room or h.revealedGhost ~= ghostNow or room.safe ~= safeNow
                                    or room.lockVersion ~= locksNow or h:roomElapsed() >= turnAt
                            end, turnAt - t + 0.1)
                            if h.revealedGhost ~= ghostNow and h.revealedGhost then
                                say("Door outcomes: a squad phone shows the ghost behind door " .. h.revealedGhost)
                                planned = false
                            end
                            continue
                        end
                    end
                    -- the door: with the ghost still unknown the squad decides together at planSeconds (the doors open as
                    -- soon as everyone stands in a circle, so nobody may stand in one while a phone can still answer)
                    if not plan.use and not plan.wait and plan.risky and team() and h.revealedGhost == nil
                        and not room.safe and t < planSeconds then
                        local ghostNow, safeNow = h.revealedGhost, room.safe
                        explain(string.format("Ghost unknown: the squad picks at %.0f s (now %.1f s)", planSeconds, t))
                        ctx.waitUntil(function()
                            return over() or h.room ~= room or h.revealedGhost ~= ghostNow or room.safe ~= safeNow
                                or h:roomElapsed() >= planSeconds
                        end, planSeconds - t + 0.1)
                        if h.revealedGhost then
                            say("Door outcomes: a phone shows the ghost behind door " .. h.revealedGhost)
                            planned = false
                        end
                        continue
                    end
                    if plan.use then
                        local isKey = plan.use == "key" or plan.use == "gold_key"
                        -- v2.1.5: keys may be needed twice for one door (security: 2 grey locks); debug run room 21: the
                        -- first key answered "false" yet removed the lock, and the second key was never tried
                        local function lockCount()
                            local d = plan.door and room.doors[plan.door]
                            return d and ((d.grey or 0) + (d.gold or 0)) or 0
                        end
                        local locksBefore = lockCount()
                        if isKey then
                            keysHere += 1
                            if keysHere >= 4 then
                                tried[plan.use] = true
                            end
                        elseif plan.use ~= "ghost_potion" then
                            tried[plan.use] = true -- ghost potions: as many as the plan wants (user: "no limit")
                        end
                        local tempBefore = h.tempHealth or 0
                        local lockedDoors = 0
                        for i = 1, 4 do
                            local d = room.doors[i]
                            if d and ((d.grey or 0) > 0 or (d.gold or 0) > 0) then
                                lockedDoors += 1
                            end
                        end
                        -- v2.1.4: no move to "the key's door" first (journal: "Removes 1 Grey Lock from EACH door"; problem
                        -- report room 26: standing in the circle first and the key was refused)
                        if false and (plan.use == "key" or plan.use == "gold_key") and plan.door and lockedDoors > 1 then
                            -- more than one locked door: stand at the one the key is for first
                            h.expectDoor, h.expectAt, h.mappingSuspect = plan.door, Util.now(), nil
                            local moved, how, _, used = ctx.interaction:teleportToHauntletDoor(h.join and h.join.interior,
                                plan.door, { avoid = avoid, bad = bad, method = moveMethod, link = lastLink, visited = visited,
                                    base = base, passed = passed, behind = behind, seconds = moveSeconds, group = ensureGroup() })
                            if moved then
                                circles = used
                                explain("At door " .. plan.door .. " for the key (" .. tostring(how) .. ")")
                            end
                        end
                        local seq = h.usedSeq
                        local callOk, sent = pcall(function()
                            return ctx.interaction:send("HauntletMessage", sessionId, "try_use_item", plan.use)
                        end)
                        if callOk and sent then
                            ctx.waitUntil(function()
                                return h.usedSeq > seq or over() or h.room ~= room
                            end, 5)
                        end
                        local answer = h.usedItems[seq + 1]
                        if isKey and not (answer and answer.ok) and h.room == room and not over() then
                            ctx.waitUntil(function()
                                return lockCount() < locksBefore or over() or h.room ~= room
                            end, 1.5)
                            if lockCount() < locksBefore then
                                answer = { ok = true }
                                say(plan.use .. ": the game answered no, but the lock came off")
                            end
                        end
                        if answer and answer.ok then
                            itemsUsed += 1
                            say(string.format("Used %s | Reason: %s", plan.use, plan.reason))
                            table.insert(digest.items, string.format("%s@%.1f", (string.gsub(plan.use, "_potion", "P")),
                                h:roomElapsed()))
                            if plan.use == "cell_phone" then
                                ctx.waitUntil(function()
                                    return h.revealedGhost ~= nil or over() or h.room ~= room
                                end, 4)
                                if h.revealedGhost then
                                    local second = Hauntlet.twoGhostChance(room.seq)
                                    say("Door outcomes: ghost behind door " .. h.revealedGhost .. (second >= 0.1
                                        and string.format(" (a second ghost elsewhere: %d%%)", math.floor(second * 100 + 0.5))
                                        or ", the other doors are safe"))
                                    planned = false
                                end
                            elseif (plan.use == "key" or plan.use == "gold_key") and plan.door then
                                ctx.waitUntil(function()
                                    local d = room.doors[plan.door]
                                    return over() or h.room ~= room or (d ~= nil and (d.grey or 0) == 0 and (d.gold or 0) == 0)
                                end, 4)
                            elseif plan.use == "rainbow_wand" then
                                say("Door outcomes: the wand cleared this room, every door is safe")
                            elseif plan.use == "ghost_potion" then
                                potionsHere += 1
                                ctx.waitUntil(function()
                                    return (h.tempHealth or 0) > tempBefore or over() or h.room ~= room
                                end, 1.5)
                                if h.room == room and not over() and (h.tempHealth or 0) <= tempBefore then
                                    tried.ghost_potion = true -- no new temp heart: not again in this room
                                    if tempBefore > 0 then
                                        -- a refusal can also be the room's timing: never learn a cap below 2
                                        Hauntlet.learnedTempCap = math.max(Hauntlet.learnedTempCap or 0, tempBefore, 2)
                                        say("Ghost potion refused at " .. tempBefore .. " temp hearts")
                                    end
                                end
                                if potionsHere >= 4 then
                                    tried.ghost_potion = true
                                end
                            end
                        else
                            tried[plan.use] = true
                            say(string.format("%s was not used (%s)", plan.use, answer and "the game refused it" or "no answer"))
                        end
                    elseif plan.wait then
                        explain(plan.reason)
                        ctx.waitUntil(function()
                            return over() or h.room ~= room or h.revealedGhost ~= nil
                        end, 1)
                        if h.revealedGhost then
                            say("Door outcomes: another player's phone shows the ghost behind door " .. h.revealedGhost)
                            planned = false
                        end
                    else
                        local door = plan.door
                        local kind = room.doors[door] and room.doors[door].kind or "?"
                        if door ~= chosen then
                            for i = 1, 4 do
                                if plan.notes and plan.notes[i] then
                                    explain(plan.notes[i])
                                end
                            end
                            say(string.format("Decision: door %d (%s) | Reason: %s%s", door, kind, plan.reason,
                                plan.risky and " (not verified safe)" or ""))
                            chosen = door
                        end
                        if h.myDoor == door then
                            -- standing in the chosen circle: stay until the doors open or the plan changes
                            local ghostNow, safeNow, locksNow = h.revealedGhost, room.safe, room.lockVersion
                            ctx.waitUntil(function()
                                return over() or h.room ~= room or h.revealedGhost ~= ghostNow or room.safe ~= safeNow
                                    or h.myDoor ~= door or room.lockVersion ~= locksNow
                            end, 2)
                        else
                            if h.lastOpened and h.lastOpened.seq == room.seq then
                                -- this room's doors already opened: the next started_room is on its way, no move back
                                ctx.waitUntil(function()
                                    return over() or h.room ~= room
                                end, 3)
                                break
                            end
                            if Util.now() < moveLockUntil then
                                task.wait(moveLockUntil - Util.now())
                            end
                            say(string.format("Entering selected door %d at %.1f s", door, h:roomElapsed()))
                            digest.door, digest.doorAt = door, h:roomElapsed()
                            local movedAt = Util.now()
                            h.expectDoor, h.expectAt, h.mappingSuspect = door, movedAt, nil
                            local moved, how, part, used, verified = ctx.interaction:teleportToHauntletDoor(
                                h.join and h.join.interior, door, { avoid = avoid, bad = bad, method = moveMethod,
                                    nexus = room.kind == "nexus" or room.kind == "final_nexus", link = lastLink,
                                    visited = visited, base = base, passed = passed, behind = behind, seconds = moveSeconds,
                                    group = ensureGroup(), visitedPos = visitedPos, roomSeq = room.seq,
                                    thisRoomGroup = roomGroup })
                            if not moved and type(how) == "string" and string.find(how, "backtrack blocked", 1, true) then
                                say(how)
                                chainGroup, chainBroken = nil, true -- a wrong chain: look for the room forward next time
                            end
                            if moved then
                                circles = used
                                picks += 1
                                ctx.waitUntil(function() -- a pick shows within ~0.3 s when the circle is the right one
                                    return over() or h.room ~= room or (h.myDoorAt ~= nil and h.myDoorAt >= movedAt)
                                end, 2.5) -- v2.1.6: 2.5 s (many accounts on one device answer late)
                                -- live run 4: alone, the doors open on my pick and the next room starts at once, so this
                                -- must not wait for "still the same room": the pick counts if this room's doors opened
                                -- v2.1.4: only MY pick in THIS room counts (debug log: the others opened the doors while I was
                                -- still on the way, the bot took the next room's circles for this room's and lost the chain)
                                -- v2.1.4 fix (log 2026-10-11, rooms 31-37 went back into old rooms): started_room clears
                                -- pickedAt, and alone the next room starts right on my pick, so this was false exactly
                                -- when the pick worked: the room was never marked as passed and the chain was lost
                                local pickedHere = h.lastPickSeq == room.seq and h.lastPickAt ~= nil and h.lastPickAt >= movedAt
                                if pickedHere and used and not chainGroup then
                                    chainGroup = used -- room 1 (or a lost chain): the room I picked in is this room
                                end
                                if pickedHere and used then
                                    if room.kind == "nexus" or room.kind == "final_nexus" then
                                        -- a new line of rooms starts at the nexus: the start is here now. The rooms
                                        -- before it stay loaded a while (live run 6, room 11: the bot went back into
                                        -- one): they stay passed, and what is closer to the old start is behind me
                                        local here = Interaction_center(used)
                                        for group in pairs(visited) do
                                            passed[group] = true
                                        end
                                        if base and here then
                                            behind = { base = base, limit = (here - base).Magnitude }
                                        end
                                        visited = {}
                                        base = here
                                    elseif base == nil then
                                        base = Interaction_center(used) -- room 1: the start of the line
                                    end
                                    visited[used] = true -- a room I picked in: never again (no going back)
                                    roomGroup = used
                                    local key = ctx.interaction.hauntletPosKey and ctx.interaction.hauntletPosKey(used)
                                    if key then
                                        visitedPos[key] = room.seq
                                    end
                                    if room.doors[door] and room.doors[door].kind == "electric" then
                                        moveLockUntil = Util.now() + 0.8
                                    end
                                    local pickedDoor = (h.room == room and h.myDoor)
                                        or (h.lastOpened and h.lastOpened.seq == room.seq and h.lastOpened.myDoor) or door
                                    lastLink = { from = used, exit = (room.kind == "nexus" or room.kind == "final_nexus")
                                        and ("Exit" .. tostring(pickedDoor)) or "Exit" }
                                end
                                if h.room == room and not over() then
                                    -- my pick = the circle I moved into (named circles are the game's own door numbers);
                                    -- the shared counters only overrule a GUESSED circle, and only when nobody else moved
                                    local suspect = h.mappingSuspect
                                    if h.myDoorAt and h.myDoorAt >= movedAt and not verified and suspect and suspect ~= door then
                                        ctx.logger:warn("Hauntlet", string.format(
                                            "Door mapping WRONG: %s is door %d, not %d; trying another circle",
                                            tostring(how), suspect, door))
                                        bad[part] = true
                                        h.myDoor = suspect
                                    elseif h.myDoorAt and h.myDoorAt >= movedAt then
                                        say(string.format("Picked: door %d (%s%s)", door, tostring(how),
                                            verified and "" or ", guessed circle"))
                                    else
                                        failedMoves += 1
                                        say(string.format("No pick seen after the move to door %d (%s%s), try %d: "
                                            .. "trying another circle group", door, tostring(how),
                                            verified and "" or ", unverified", failedMoves))
                                        if used then
                                            if avoid[used] then
                                                avoid = {} -- every group tried: start over (the room may not have been ready)
                                                bad = {}
                                            else
                                                avoid[used] = true
                                            end
                                        end
                                    end
                                end
                            else
                                failedMoves += 1
                                ctx.logger:warn("Hauntlet", "Could not reach door " .. door .. ": " .. tostring(how))
                                task.wait(1)
                            end
                        end
                    end
                end
                lastCircles = circles or lastCircles
                prevGroup, prevRoom = chainGroup, room -- the next room is found from this one's exit
                h:_debugFlush()
                ctx.waitUntil(function()
                    return over() or (h.lastOpened ~= nil and h.lastOpened.seq == room.seq)
                end, 3)
                local result = h.lastOpened
                if result and result.seq == room.seq then
                    local ghostDoors = {}
                    for i = 1, 4 do
                        if result.ghosts[i] then
                            table.insert(ghostDoors, tostring(i))
                        end
                    end
                    say(string.format("Room transition verified: room %d, I was at door %s, ghost behind %s%s", room.seq,
                        tostring(result.myDoor or "?"), #ghostDoors > 0 and table.concat(ghostDoors, ", ") or "no door",
                        result.damage > 0 and string.format(" (-%d heart%s)", result.damage, result.damage == 1 and "" or "s")
                            or ""))
                end
                pcall(function()
                    local kinds = {}
                    for i = 1, 4 do
                        local d = room.doors[i]
                        if d and d.exists ~= false then
                            table.insert(kinds, string.sub(tostring(d.kind), 1, 8) .. ((d.wasLocked and "*") or ""))
                        end
                    end
                    local ghostDoors = {}
                    for i = 1, 4 do
                        if result and result.seq == room.seq and result.ghosts[i] then
                            table.insert(ghostDoors, tostring(i))
                        end
                    end
                    ctx.logger:info("HauntletDigest", string.format(
                        "R%d %s | sq %d #%d%s | h %s | %s | reveal %s | %s | door %s@%s | ghost %s | dmg %s",
                        room.seq, tostring(room.area), #order, rank, h.squadIds and "k" or "", digest.hearts,
                        table.concat(kinds, ","),
                        (function()
                            local r = (h.lastReveal and h.lastReveal.seq == room.seq) and h.lastReveal
                                or { door = h.revealedGhost, at = h.revealedAt and (h.revealedAt - room.at), safe = room.safe }
                            if r.safe then
                                return "wand"
                            end
                            return r.door and string.format("d%d@%.1f", r.door, r.at or 0) or "-"
                        end)(),
                        #digest.items > 0 and table.concat(digest.items, " ") or "no items",
                        tostring((result and result.seq == room.seq and result.myDoor) or digest.door or "?"),
                        digest.doorAt and string.format("%.1f", digest.doorAt) or "?",
                        #ghostDoors > 0 and table.concat(ghostDoors, "+") or "none",
                        tostring(result and result.seq == room.seq and result.damage or "?")))
                end)
            end
            if switchedOff() and not over() then
                -- user 2026-10-10: "it teleported me out while I was playing": switched off during a run = the run is
                -- the player's now. No waiting, no travel, nothing more sent.
                say("Switched off during the run: the run is yours now (no travel, nothing more sent)")
                return false, "switched off during the run"
            end
            ctx.waitUntil(function()
                return h.leave ~= nil
            end, 25)
            ctx.waitUntil(function()
                return not inRun()
            end, 15)
            local candyAfter = tonumber(ctx.gameData:get(KEYS.Candy))
            local gained = (candyAfter and candyBefore) and (candyAfter - candyBefore) or nil
            local leave = h.leave
            ctx.logger:info("Event", string.format(
                "Hauntlet: %s, room reached %s (best %s), %d door steps, %d items, reward %s candy%s",
                h.kicked and (h.kicked == "died" and "died" or ("kicked out (" .. h.kicked .. ")")) or "run finished",
                tostring(leave and leave.roomReached or h.roomSeq),
                tostring(leave and leave.best or "?"), picks, itemsUsed,
                tostring(leave and leave.candy or "?"),
                gained and string.format(", candy %+d", gained) or ""))
            if leave and (EventTasks._journalAt == nil or Util.now() - EventTasks._journalAt > 600) then
                EventTasks._journalAt = Util.now()
                local before = ctx.gameData:get(KEYS.Hauntlet)
                pcall(function()
                    ctx.interaction:send("UnlockHauntletJournal")
                end)
                ctx.waitUntil(function()
                    return ctx.gameData:get(KEYS.Hauntlet) ~= before
                end, 5)
                local after = ctx.gameData:get(KEYS.Hauntlet)
                if type(after) == "table" then
                    ctx.logger:info("Event", "Hauntlet: journal pages " .. tostring(after.pages_unlocked))
                end
            end
            if h.leave ~= nil or not inRun() then
                local home, homeWhy = ctx.travel:goTo(GameConstants.HouseInteriorName)
                if not home then
                    ctx.logger:info("Event", "Hauntlet: going home after the run did not work ("
                        .. tostring(homeWhy) .. ")")
                end
            else
                ctx.logger:info("Event", "Hauntlet: the run is still going: no travel out of a run")
            end
            if picks == 0 then
                return false, h.kicked and ("kicked before a door: " .. h.kicked) or "no door stepped into"
            end
            if not leave and not (gained and gained > 0) then
                return false, h.kicked and ("died in room " .. h.roomSeq .. ", no reward seen") or "run did not end"
            end
            return true
        end,
    }
    function EventTasks.newToken()
        local ok, guid = pcall(function()
            return game:GetService("HttpService"):GenerateGUID(false)
        end)
        return string.lower(ok and tostring(guid) or string.format("%08x-0000-4000-8000-%012x", math.random(0, 0x7fffffff), os.time()))
    end
    function EventTasks.pickTarget(ctx, folder, mg)
        local root = myRoot()
        if not root then
            return nil
        end
        local best, bestDistance, boss
        for _, ghost in ipairs(EventTasks.findGhosts(folder)) do
            local position = modelPosition(ghost.model)
            if position then
                local target = { kind = "ghost", id = ghost.id, position = position, model = ghost.model,
                    boss = ghost.size == E.BossSize }
                if target.boss then
                    boss = boss or target
                else
                    local d = distance(position, root.Position)
                    if not best or d < bestDistance then
                        best, bestDistance = target, d
                    end
                end
            end
        end
        if best or boss then
            return best or boss
        end
        local interior = ctx.gameData:get(KEYS.Interior)
        local furniture = type(interior) == "table" and type(interior.furniture) == "table" and interior.furniture or {}
        for unique in pairs(mg.haunted) do
            local piece = furniture[unique]
            local ok, position = pcall(function()
                return piece.cframe.Position
            end)
            if ok and position ~= nil and type(position.X) == "number" then
                local d = distance(position, root.Position)
                if not best or d < bestDistance then
                    best, bestDistance = { kind = "prop", id = unique, position = position }, d
                end
            end
        end
        return best
    end
    EventTasks.quests = {
        id = "quests",
        timeoutSeconds = 30,
        run = function(ctx)
            local function tabSignature(tabName)
                local data = ctx.gameData:get(KEYS.Dailies)
                local tab = type(data) == "table" and type(data.serialized_tabs) == "table" and data.serialized_tabs[tabName]
                if type(tab) ~= "table" then
                    return "none"
                end
                local parts = { tostring(tab.reward_claimed), tostring(tab.total_dailies_completed) }
                for kind, daily in pairs(type(tab.active_dailies) == "table" and tab.active_dailies or {}) do
                    local state = type(daily) == "table" and type(daily.state) == "table" and daily.state or {}
                    table.insert(parts, tostring(kind) .. ":" .. tostring(state.steps_completed))
                end
                table.sort(parts)
                return table.concat(parts, "|")
            end
            local todo = EventTasks.questsToClaim(ctx.gameData:get(KEYS.Dailies))
            if #todo == 0 then
                return true
            end
            local changed = 0
            for _, item in ipairs(todo) do
                local before = tabSignature(item.tab)
                local money, candy = ctx.gameData:get(KEYS.Money), ctx.gameData:get(KEYS.Candy)
                ctx.interaction:send(item.action, item.tab)
                if ctx.waitUntil(function()
                    local data = ctx.gameData:get(KEYS.Dailies)
                    local tab = type(data) == "table" and type(data.serialized_tabs) == "table" and data.serialized_tabs[item.tab]
                    if type(tab) ~= "table" then return false end
                    if item.action == "QuestTabReward" then return tab.reward_claimed == true end
                    for _, pending in ipairs(EventTasks.questsToClaim(data)) do
                        if pending.action == item.action and pending.tab == item.tab then return false end
                    end
                    return tabSignature(item.tab) ~= before
                end, 6) then
                    changed += 1
                    local gains = {}
                    local moneyNow, candyNow = ctx.gameData:get(KEYS.Money), ctx.gameData:get(KEYS.Candy)
                    if tonumber(money) and tonumber(moneyNow) and moneyNow > money then
                        table.insert(gains, "+" .. (moneyNow - money) .. " Bucks")
                    end
                    if tonumber(candy) and tonumber(candyNow) and candyNow > candy then
                        table.insert(gains, "+" .. (candyNow - candy) .. " candy")
                    end
                    ctx.logger:success("Event", string.format("Quests: %s claimed on the %s board%s",
                        item.action == "QuestTabReward" and "board reward" or "finished quest", item.tab,
                        #gains > 0 and (" (" .. table.concat(gains, ", ") .. ")") or ""))
                else
                    ctx.logger:info("Event", "Quests: " .. item.action .. "(" .. item.tab .. ") changed nothing in my data")
                end
            end
            if changed < #todo then
                return false, "one or more quest claims remain unconfirmed"
            end
            return true
        end,
    }
    EventTasks.VisitQuests = { housewarming = true, neighborhood_tour = true }
    function EventTasks.visitQuest(dailies)
        local tabs = type(dailies) == "table" and type(dailies.serialized_tabs) == "table" and dailies.serialized_tabs or {}
        for _, tab in pairs(tabs) do
            for kind, daily in pairs(type(tab) == "table" and type(tab.active_dailies) == "table" and tab.active_dailies or {}) do
                local state = type(daily) == "table" and type(daily.state) == "table" and daily.state or nil
                if EventTasks.VisitQuests[kind] and state then
                    local need, done = tonumber(state.steps_to_complete) or 0, tonumber(state.steps_completed) or 0
                    if done < need then
                        local visited = {}
                        for userId in pairs(type(state.houses_visited_by_userid) == "table" and state.houses_visited_by_userid or {}) do
                            visited[tostring(userId)] = true
                        end
                        return { kind = kind, need = need, done = done, visited = visited }
                    end
                end
            end
        end
        return nil
    end
    EventTasks._visitTried = {}
    local VISITS_PER_RUN = 2
    EventTasks.houseVisits = {
        id = "house_visits",
        timeoutSeconds = 120,
        run = function(ctx)
            local quest = EventTasks.visitQuest(ctx.gameData:get(KEYS.Dailies))
            if not quest then
                return true
            end
            local Players = game:GetService("Players")
            local me = Players.LocalPlayer
            local counted, tries = 0, 0
            for _, player in ipairs(Players:GetPlayers()) do
                if tries >= VISITS_PER_RUN then
                    break
                end
                local id = tostring(player.UserId)
                local last = EventTasks._visitTried[id]
                if player ~= me and not quest.visited[id] and not (last and Util.now() - last < 1800) then
                    tries += 1
                    EventTasks._visitTried[id] = Util.now()
                    ctx.travel:visitHouse(player)
                    local ok = ctx.waitUntil(function()
                        local now = EventTasks.visitQuest(ctx.gameData:get(KEYS.Dailies))
                        local data = ctx.gameData:get(KEYS.Dailies)
                        if type(data) ~= "table" or type(data.serialized_tabs) ~= "table" then return false end
                        return now == nil or (now.kind == quest.kind and (now.visited[id] == true or now.done > quest.done))
                    end, 15)
                    if ok then
                        counted += 1
                        local now = EventTasks.visitQuest(ctx.gameData:get(KEYS.Dailies))
                        ctx.logger:success("Event", string.format("Quest %s: visited %s's house (%d of %d)", quest.kind,
                            player.Name, now and now.done or quest.need, quest.need))
                    else
                        ctx.logger:info("Event", "Quest " .. quest.kind .. ": the visit to " .. player.Name .. " did not count")
                    end
                    ctx.travel:goTo("MainMap")
                    quest = EventTasks.visitQuest(ctx.gameData:get(KEYS.Dailies))
                    if not quest then
                        break
                    end
                end
            end
            if tries == 0 then
                ctx.logger:info("Event", "Quest: no other player's house left to visit on this server")
                return true
            end
            if counted == 0 then
                return false, "house visits did not count for the quest"
            end
            return true
        end,
    }
    -- v2.1.5 (user: "auto potion never seems to work; every potion that speeds up the mega neon, bucks too"): the ids
    -- in the player's own Food bag that are age / bonus-bucks potions are taken as well (event versions of the Age-Up
    -- Potion carry other ids). Never a fly / ride potion: those match neither pattern.
    function GameConstants.isAgeUpPotion(id) -- every Age-Up form: normal, Tiny, event versions
        id = string.lower(tostring(id or ""))
        return string.find(id, "potion", 1, true) ~= nil and (string.find(id, "^age_potion") ~= nil
            or string.find(id, "_age_potion", 1, true) ~= nil or string.find(id, "age_up", 1, true) ~= nil
            or string.find(id, "ageup", 1, true) ~= nil)
    end
    function GameConstants.isFarmPotion(id)
        id = tostring(id or "")
        return (GameConstants.isAgeUpPotion(id) or string.find(id, "aging_potion", 1, true) ~= nil
            or string.find(id, "bonus_bucks_potion", 1, true) ~= nil or id == "pet_random_ailment_potion")
            and string.find(id, "fly", 1, true) == nil and string.find(id, "ride", 1, true) == nil
    end
    function EventTasks.potionList(farm, gameData, petIdle, petUnique)
        local settings = type(farm.AutoPotions) == "table" and farm.AutoPotions or {}
        local skip = {}
        for _, id in ipairs(type(settings.Skip) == "table" and settings.Skip or {}) do
            skip[id] = true
        end
        local list, seen = {}, {}
        for _, id in ipairs(type(settings.Potions) == "table" and settings.Potions or GameConstants.FarmPotions) do
            if GameConstants.isFarmPotion(id) and not skip[id] and not seen[id] then
                seen[id] = true
                table.insert(list, id)
            end
        end
        if gameData then
            -- age potions first (they grow the pet), the bucks potion after them
            local found = {}
            for _, item in ipairs(gameData:findItems(GameConstants.ItemCategory, nil)) do
                if GameConstants.isFarmPotion(item.id) and not skip[item.id] and not seen[item.id] then
                    seen[item.id] = true
                    table.insert(found, item.id)
                end
            end
            table.sort(found, function(a, b)
                local aAge, bAge = GameConstants.isAgeUpPotion(a), GameConstants.isAgeUpPotion(b)
                if aAge ~= bAge then
                    return aAge
                end
                return a < b
            end)
            for _, id in ipairs(found) do
                table.insert(list, id)
            end
        end
        -- Age-Up potions first (instant growth), then the Bonus Aging buff (pet ages 1.2x for a while), the Bonus
        -- Bucks buff last. A timed buff waits BuffMinutes after its last use (no stacking the same buff away).
        -- class 4: pet_random_ailment_potion (Busy Body: a new need at once = more XP), only while the pet has no need
        local class = EventTasks.potionClass
        local buffWait = math.max(0, tonumber(settings.BuffMinutes) or 15) * 60
        local ordered = {}
        for pass = 1, 4 do
            for _, id in ipairs(list) do
                local ok = pass == 1 or (pass == 4 and petIdle == true)
                    or ((pass == 2 or pass == 3) and EventTasks.buffFree(gameData, petUnique, pass, buffWait))
                local age = gameData and petUnique and gameData:petAge(petUnique)
                if (pass == 1 or pass == 2) and age and age >= GameConstants.FullGrownAge then ok = false end
                if class(id) == pass and ok then
                    table.insert(ordered, id)
                end
            end
        end
        return ordered
    end
    -- Buff timestamps survive script reloads within this Roblox client, without disk access.
    -- Restarting the client loses this fallback; buffFree still checks the game's own buff time first.
    local buffEnvironment = Util.getSharedEnvironment()
    local buffPlayer = game:GetService("Players").LocalPlayer
    local buffOwner = tostring(buffPlayer and buffPlayer.UserId or "unknown")
    local buffCache = buffEnvironment.AdoptMePrivateBuffCache
    if type(buffCache) ~= "table" or buffCache.owner ~= buffOwner or type(buffCache.times) ~= "table" then
        buffCache = { owner = buffOwner, times = {} }
        buffEnvironment.AdoptMePrivateBuffCache = buffCache
    end
    EventTasks._buffUsedAt = buffCache.times
    local function buffKey(petUnique, class)
        return tostring(petUnique) .. "|" .. tostring(class)
    end
    function EventTasks.buffLoad()
        local now = os.time()
        for key, at in pairs(EventTasks._buffUsedAt) do
            if (type(key) ~= "string" and type(key) ~= "number") or type(at) ~= "number"
                or at ~= at or at > now or now - at >= 86400 then
                EventTasks._buffUsedAt[key] = nil
            end
        end
    end
    function EventTasks.buffMark(petUnique, class)
        EventTasks.buffLoad()
        local now = os.time()
        EventTasks._buffUsedAt[buffKey(petUnique, class)] = now
        EventTasks._buffUsedAt[class] = now
    end
    function EventTasks.buffFree(gameData, petUnique, class, waitSeconds)
        if not petUnique then
            return false
        end
        EventTasks.buffLoad()
        -- the pet's own buff time first (the game adds every potion's 15 min on top)
        local word = class == 2 and "aging" or "bucks"
        local okUntil, untilAt = pcall(function()
            return gameData.petBuffUntil and gameData:petBuffUntil(petUnique, word)
        end)
        if okUntil and untilAt and untilAt - os.time() > 60 then
            return false
        end
        -- a Bonus Aging potion on a pet one stage from full grown is mostly wasted
        if class == 2 then
            local okAge, age = pcall(function()
                return gameData:petAge(petUnique)
            end)
            if okAge and age and age >= GameConstants.FullGrownAge - 1 then
                return false
            end
        end
        local last = EventTasks._buffUsedAt[buffKey(petUnique, class)]
        return not last or os.time() - last >= waitSeconds
    end
    function EventTasks.potionClass(id)
        id = tostring(id)
        if id == "pet_random_ailment_potion" then
            return 4
        end
        return GameConstants.isAgeUpPotion(id) and 1 or (string.find(id, "aging_potion", 1, true) and 2 or 3)
    end
    -- the pet has no need right now (the ailment list knows it): a Busy Body potion gives it one to do
    function EventTasks.petIdle(state, petUnique)
        if not (state and petUnique) or state:get("ailments.known") ~= true then
            return false
        end
        for _, entry in ipairs(state:get("ailments.active") or {}) do
            if type(entry) == "table" and tostring(entry.petUnique) == tostring(petUnique) then
                return false
            end
        end
        return true
    end
    -- what Auto Potions waits for, in words (written to the log when it changes: it was silent)
    function EventTasks.potionWhy(gameData, farm)
        local settings = type(farm.AutoPotions) == "table" and farm.AutoPotions or {}
        if not settings.Enabled then
            return "off (Farm.AutoPotions.Enabled)"
        end
        local potions = {}
        for _, item in ipairs(gameData:findItems(GameConstants.ItemCategory, nil)) do
            if string.find(tostring(item.id), "potion", 1, true) then
                potions[item.id] = (potions[item.id] or 0) + 1
            end
        end
        local bag = {}
        for id, count in pairs(potions) do
            table.insert(bag, id .. " x" .. count)
        end
        table.sort(bag)
        local target = EventTasks.potionTarget(gameData, farm)
        local usable = gameData:findItems(GameConstants.ItemCategory, EventTasks.potionList(farm, gameData, false, target))[1]
        local why = (not usable and "no usable potion now (Age-Up none; Bonus Aging / Bucks used less than BuffMinutes ago or none)")
            or (not target and "no equipped pet that still grows" .. (GameConstants.focusKind(farm)
                and (" of the focus kind " .. tostring(GameConstants.focusKind(farm))) or ""))
            or "ready"
        return string.format("%s | potions in the bag: %s", why, #bag > 0 and table.concat(bag, ", ") or "none")
    end
    function EventTasks.potionTarget(gameData, farm, state)
        local settings = type(farm.AutoPotions) == "table" and farm.AutoPotions or {}
        local kinds = {}
        for _, kind in ipairs(type(settings.PetKinds) == "table" and settings.PetKinds or {}) do
            kinds[kind] = true
        end
        local focus = GameConstants.focusKind(farm)
        if focus then -- Mega a Pet: potions only on the focus pet
            kinds = { [focus] = true }
        end
        for _, pet in ipairs(gameData:equippedPetList()) do
            local age = pet.unique and gameData:petAge(pet.unique)
            local selection = gameData.selection
            local permitted = not selection or not selection:enabled() or selection:isProtected(pet.unique)
            if permitted and age and (next(kinds) == nil or kinds[gameData:getPetKind(pet.unique) or ""]) then
                local ids = EventTasks.potionList(farm, gameData, EventTasks.petIdle(state, pet.unique), pet.unique)
                if gameData:findItems(GameConstants.ItemCategory, ids)[1] then return pet.unique end
            end
        end
        return nil
    end
    EventTasks.agePotion = {
        id = "age_potion",
        timeoutSeconds = 40,
        run = function(ctx)
            local petUnique = EventTasks.potionTarget(ctx.gameData, ctx.farmConfig, ctx.state)
            local potions = EventTasks.potionList(ctx.farmConfig, ctx.gameData, EventTasks.petIdle(ctx.state, petUnique), petUnique)
            local item = #potions > 0 and ctx.gameData:findItems(GameConstants.ItemCategory, potions)[1] or nil
            if not petUnique or not item then
                return true
            end
            local ageBefore = ctx.gameData:petAge(petUnique)
            local kind = ctx.gameData:getPetKind(petUnique) or petUnique
            local itemClass = EventTasks.potionClass(item.id)
            if itemClass == 2 or itemClass == 3 then
                EventTasks.buffMark(petUnique, itemClass) -- before giving: a slow answer must not mean "again in 5 s"
            end
            local ok, why = Tasks.givePetItem(ctx, petUnique, item, function()
                return (ctx.gameData:inventoryKnown(GameConstants.ItemCategory) and ctx.gameData:itemUsesLeft(GameConstants.ItemCategory, item.unique) == nil)
                    or (ctx.gameData:petAge(petUnique) or 0) > (ageBefore or 0)
            end, "age potion")
            if not ok then
                return false, why
            end
            local class = EventTasks.potionClass(item.id)
            if class == 4 then
                if not ctx.waitUntil(function() return not EventTasks.petIdle(ctx.state, petUnique) end, 8) then
                    return false, "Busy Body item consumed but a new need was not observed"
                end
                ctx.logger:success("Event", "Busy Body potion on " .. kind .. ": new need observed")
                return true
            elseif class > 1 then
                -- marked before giving
            else
                ctx.waitUntil(function()
                    return (ctx.gameData:petAge(petUnique) or 0) > (ageBefore or 0)
                end, 3)
            end
            ctx.logger:success("Event", string.format("Potion %s consumed by %s (age %s -> %s; effect requires game data)", item.id, kind, tostring(ageBefore),
                tostring(ctx.gameData:petAge(petUnique))))
            return true
        end,
    }
    function EventTasks.neonPick(gameData, farm, mega)
        local settings = type(farm.AutoNeon) == "table" and farm.AutoNeon or {}
        local exclude = {}
        for _, kind in ipairs(type(settings.Exclude) == "table" and settings.Exclude or {}) do
            exclude[kind] = true
        end
        local bestKind, bestList
        local groups = gameData:neonFusionGroups(exclude, mega)
        local focus = GameConstants.focusKind(farm)
        if focus and type(groups[focus]) == "table" and #groups[focus] >= 4 then -- Mega a Pet: the focus pet first
            local list = groups[focus]
            return focus, { list[1], list[2], list[3], list[4] }
        end
        if focus then return nil end
        for kind, list in pairs(groups) do
            if #list >= 4 and (not bestList or #list > #bestList or (#list == #bestList and kind < bestKind)) then
                bestKind, bestList = kind, list
            end
        end
        if not bestList then
            return nil
        end
        return bestKind, { bestList[1], bestList[2], bestList[3], bestList[4] }
    end
    local NEON_PLACE_WAIT, NEON_BETWEEN_PET, NEON_AFTER_PLACE = 0.12, 0.08, 0.15
    local function fusionTask(mega)
        return {
        id = mega and "mega_fusion" or "neon_fusion",
        timeoutSeconds = 40,
        run = function(ctx)
            local kind, uniques = EventTasks.neonPick(ctx.gameData, ctx.farmConfig, mega)
            if not kind then
                return true
            end
            local function countNow()
                return mega and ctx.gameData:megaCountOfKind(kind) or ctx.gameData:neonCountOfKind(kind)
            end
            local neonsBefore = countNow()
            for _, unique in ipairs(uniques) do
                if ctx.gameData:isPetProtected(unique) or ctx.gameData:isPetEquipped(unique) then
                    return false, "fusion candidate became equipped/protected"
                end
            end
            local selection = ctx.gameData.selection
            for _, unique in ipairs((selection and selection:enabled()) and {} or uniques) do
                ctx.interaction:send("EquipItem", unique, { equip_as_last = false, use_sound_delay = false })
                task.wait(NEON_PLACE_WAIT)
                ctx.interaction:send("UnequipItem", unique, nil)
                task.wait(NEON_BETWEEN_PET)
            end
            task.wait(NEON_AFTER_PLACE)
            local ok, answer = ctx.interaction:send("NeonFusion", { uniques[1], uniques[2], uniques[3], uniques[4] })
            local answered = type(answer) == "string" and answer or nil
            local function fused()
                if not ctx.gameData:petInventoryKnown() then return false end
                if answered and (mega and ctx.gameData:isPetMega(answered) or not mega and ctx.gameData:isPetNeon(answered)) then
                    return true
                end
                local gone = 0
                for _, unique in ipairs(uniques) do
                    if not ctx.gameData:hasPet(unique) then
                        gone += 1
                    end
                end
                return gone == 4 and countNow() > neonsBefore
            end
            if ctx.waitUntil(fused, 6) then
                if mega then
                    ctx.logger:success("Event", string.format("Mega neon fusion: 4 neon %s -> 1 mega neon %s (mega %s now: %d)",
                        kind, kind, kind, countNow()))
                else
                    ctx.logger:success("Event", string.format("Neon fusion: 4 %s -> 1 neon %s (neon %s now: %d)", kind, kind, kind,
                        countNow()))
                end
                return true
            end
            return false, string.format("%s fusion of 4 %s not seen in my data (server answer: %s %s)", mega and "mega neon"
                or "neon", kind, tostring(ok), Util.truncate(tostring(answer), 60))
        end,
        }
    end
    EventTasks.neonFusion = fusionTask(false)
    EventTasks.megaFusion = fusionTask(true)
    function EventTasks.candyPetTarget(gameData, settings)
        local candy = tonumber(gameData:get(GameConstants.DataKeys.Candy))
        if not candy then
            return nil
        end
        if type(settings.Pick) == "table" then
            local picked = {}
            for _, id in ipairs(settings.Pick) do
                picked[id] = true
            end
            for _, entry in ipairs(type(settings.Buy) == "table" and settings.Buy or {}) do
                local id, price = entry.id or entry[1], tonumber(entry.price)
                if type(id) == "string" and picked[id] and price and price > 0 and not entry.machine
                    and candy - (tonumber(settings.KeepCandy) or 0) >= price then
                    return { id = id, price = price }
                end
            end
            return nil
        end
        for _, entry in ipairs(type(settings.Buy) == "table" and settings.Buy or {}) do
            local id, price, max = entry.id or entry[1], tonumber(entry.price), tonumber(entry.max) or 0
            if type(id) == "string" and price and price > 0 and not entry.machine then
                local owned = 0
                for _ in pairs(gameData:petUniquesOfKind(id)) do
                    owned += 1
                end
                if max <= 0 or owned < max then
                    if candy - (tonumber(settings.KeepCandy) or 0) >= price then
                        return { id = id, price = price }
                    end
                    return nil
                end
            end
        end
        return nil
    end
    EventTasks.buyCandyPet = {
        id = "candy_pet",
        timeoutSeconds = 75,
        run = function(ctx, group)
            local settings = ctx.farmConfig.Event and ctx.farmConfig.Event.CandyPets or {}
            local pick = group and group.pick or EventTasks.candyPetTarget(ctx.gameData, settings)
            if not pick then
                return true
            end
            -- Mega a Pet asks for several copies at once (one BuyItem each: buy_count 1 is the call seen working)
            local wanted, bought = math.max(1, math.min(tonumber(pick.count) or 1, 8)), 0
            local candyStart = tonumber(ctx.gameData:get(GameConstants.DataKeys.Candy)) or 0
            if not (group and group.pick) then
                -- v2.1.6 Candy Shop pick (user): one every 0.5 s until the candy runs out; Max buy: all in one purchase
                local keep = tonumber(settings.KeepCandy) or 0
                local canPay = math.floor((candyStart - keep) / pick.price)
                if settings.MaxBuy == true and canPay > 1 then
                    local want = math.min(canPay, 50)
                    local got, sent, answer = EventTasks.buyMany(ctx, pick.id, want)
                    ctx.logger:info("Event", string.format("Candy Shop Max buy: %d of %d x %s in one purchase%s", got, want,
                        pick.id, got == 0 and (" (answer " .. tostring(sent) .. " " .. Util.truncate(tostring(answer), 60)
                        .. "): one by one instead") or ""))
                    bought = got
                    canPay = math.floor(((tonumber(ctx.gameData:get(GameConstants.DataKeys.Candy)) or 0) - keep) / pick.price)
                end
                wanted = bought + math.min(math.max(canPay, 0), 60)
                pick = { id = pick.id, price = pick.price, keepCandy = keep, every = 0.5 }
            end
            for _ = bought + 1, wanted do
                local candyNow = tonumber(ctx.gameData:get(GameConstants.DataKeys.Candy)) or 0
                if bought > 0 and candyNow - (tonumber(pick.keepCandy) or 0) < pick.price then
                    break
                end
                if bought > 0 and pick.every then
                    task.wait(pick.every)
                end
                local before = ctx.gameData:petUniquesOfKind(pick.id)
                local sent, answer = ctx.interaction:send("BuyItem", GameConstants.EggCategory, pick.id, { buy_count = 1 })
                local newUnique
                ctx.waitUntil(function()
                    for unique in pairs(ctx.gameData:petUniquesOfKind(pick.id)) do
                        if not before[unique] then
                            newUnique = unique
                            return true
                        end
                    end
                    return false
                end, 8)
                if not newUnique then
                    if bought > 0 then
                        break
                    end
                    return false, string.format("no %s arrived in your backpack (server answer: %s %s)", pick.id, tostring(sent),
                        Util.truncate(tostring(answer), 60))
                end
                bought += 1
            end
            local candyAfter = tonumber(ctx.gameData:get(GameConstants.DataKeys.Candy)) or candyStart
            ctx.logger:success("Event", string.format("Bought %d x %s for %d candy (candy left: %d)", bought, pick.id,
                candyStart - candyAfter, candyAfter))
            if group and group.onBought then
                group.onBought()
            end
            return true
        end,
    }
    function EventTasks.nextGift(gameData, farm)
        local settings = type(farm.AutoOpen) == "table" and farm.AutoOpen or {}
        local skip = {}
        for _, id in ipairs(type(settings.Exclude) == "table" and settings.Exclude or {}) do
            skip[id] = true
        end
        local list = {}
        for _, item in ipairs(gameData:findItems(GameConstants.GiftCategory, nil)) do
            if not skip[item.id] then
                for how, pattern in pairs(GameConstants.GiftPatterns) do
                    if string.find(item.id, pattern) then
                        table.insert(list, { unique = item.unique, id = item.id, how = how })
                    end
                end
            end
        end
        table.sort(list, function(a, b)
            return a.unique < b.unique
        end)
        return list[1]
    end
    EventTasks.openGift = {
        id = "open_gift",
        timeoutSeconds = 30,
        run = function(ctx)
            local gift = EventTasks.nextGift(ctx.gameData, ctx.farmConfig)
            if not gift then
                return true
            end
            local function gone()
                return ctx.gameData:inventoryKnown(GameConstants.GiftCategory) and ctx.gameData:itemUsesLeft(GameConstants.GiftCategory, gift.unique) == nil
            end
            ctx.maid:Give(function()
                ctx.interaction:send("UseTool", gift.unique, "END", nil)
                ctx.interaction:send("UnequipItem", gift.unique, nil)
            end)
            local equipped, equipReason = ctx.interaction:send("EquipItem", gift.unique, {})
            if not equipped then return false, equipReason end
            task.wait(0.5)

            if gift.how == "gift" then
                ctx.interaction:send("OpenGift", gift.unique)
                ctx.waitUntil(gone, 4)
                ctx.interaction:send("UseTool", gift.unique, "END", nil)
            else
                ctx.interaction:send("UnequipItem", gift.unique, nil)
                ctx.interaction:send("UseTool", gift.unique, "END", nil)
                ctx.interaction:send("OpenChest", gift.id, gift.unique)
            end
            if ctx.waitUntil(gone, 6) then
                ctx.logger:success("Event", "Opened " .. gift.id)
                return true
            end
            ctx.interaction:send("UnequipItem", gift.unique, nil)
            return false, gift.id .. " is still in the backpack after opening"
        end,
    }
    return EventTasks
end
__moduleSources["Game/PetSelection"] = function(...)
    -- This is a local selection, never a claim of ownership of a paid slot.
    local Selection = {}
    Selection.__index = Selection
    function Selection.new(data, farm)
        return setmetatable({ data = data, farm = farm, ids = {}, captured = false,
            missingSince = {}, attempts = {}, twoSlotsObserved = false, secondBlocked = false }, Selection)
    end
    function Selection:enabled() return self.farm.KeepEquippedPair ~= false end
    function Selection:contains(unique)
        return table.find(self.ids, tostring(unique)) ~= nil
    end
    function Selection:isProtected(unique)
        return self:enabled() and self.captured and self:contains(unique)
    end
    function Selection:capture()
        local count, known = self.data:equippedPetCount()
        if not known or count == 0 then return false, "Equipe um ou dois pets e aguarde os dados carregarem" end
        if count > 2 then return false, "Formato de equipamento inesperado; seleção não alterada" end
        local ids = {}
        for _, pet in ipairs(self.data:equippedPetList()) do table.insert(ids, pet.unique) end
        self.ids, self.captured = ids, true
        self.twoSlotsObserved = count == 2
        self.secondBlocked, self.missingSince, self.attempts = false, {}, {}
        return true, "Seleção protegida: " .. table.concat(ids, ", ")
    end
    function Selection:observe(now)
        local count, known = self.data:equippedPetCount()
        if not known then return end
        if count == 2 then self.twoSlotsObserved = true end
        if not self.captured then self:capture() end
        for _, id in ipairs(self.ids) do
            if self.data:isPetEquipped(id) then
                self.missingSince[id] = nil
            else
                self.missingSince[id] = self.missingSince[id] or now
            end
        end
    end
    function Selection:canEquip(unique)
        unique = tostring(unique)
        if self.data:isPetEquipped(unique) then return true end
        local count, known = self.data:equippedPetCount()
        if not known then return false, "equipment data unavailable" end
        if self:enabled() then
            if not self.captured or not self:contains(unique) then return false, "pet is not in the protected selection" end
            for _, pet in ipairs(self.data:equippedPetList()) do
                if not self:contains(pet.unique) then
                    return false, "manual equipment changed; use Atualizar seleção to accept it"
                end
            end
        end
        if count >= 2 then return false, "no empty pet slot" end
        if count == 1 and (not self.twoSlotsObserved or self.secondBlocked or self.farm.TwoPets == false) then
            return false, "second slot not confirmed; equip the authorized pair manually"
        end
        return true
    end
    function Selection:recoveryCandidate(now)
        if not self:enabled() or not self.captured or not self.farm.KeepPetEquipped then return nil end
        for _, id in ipairs(self.ids) do
            local since = self.missingSince[id]
            if since and now - since >= 5 and (self.attempts[id] or 0) < 2
                and self.data:hasPet(id) and self:canEquip(id) then return id end
        end
        return nil
    end
    function Selection:beginRecovery(id)
        self.attempts[id] = (self.attempts[id] or 0) + 1
    end
    function Selection:status()
        return { ids = table.clone(self.ids), captured = self.captured, enabled = self:enabled(),
            twoSlotsObserved = self.twoSlotsObserved, secondBlocked = self.secondBlocked }
    end
    return Selection
end

__moduleSources["Game/TaskManager"] = function(...)
    local import = ...
    local NeedSession = import("Game/NeedSession")
    local PetSelection = import("Game/PetSelection")
    local Util = import("Core/Util")
    local Maid = import("Core/Maid")
    local GameConstants = import("Game/GameConstants")
    local Tasks = import("Game/Tasks")
    local EventTasks = import("Game/EventTasks")
    local Minigame = import("Game/Minigame")
    local TaskManager = {}
    TaskManager.__index = TaskManager
    local TEAM_KEY = "team"
    local EVENT_RECHECK_SECONDS = { ghost_gallery = 120, stray_cat = 1800, crypt = 60, pigeon_nest = 60, quests = 300, pen_stock = 20, age_potion = 5, open_gift = 3, neon_fusion = 2, mega_fusion = 2, candy_pet = 30, house_visits = 300, hauntlet = 90, skelicorn = 120 }
    local GHOST_GALLERY_LEAD_SECONDS = 75
    local GHOST_INTERRUPT_SECONDS = 50
    local HAUNTLET_LEAD_SECONDS = 45
    local HAUNTLET_GHOST_GAP_SECONDS = 420
    local HAUNTLET_INTERRUPT_SECONDS = 42 -- Farm.Event.HauntletFirst: a normal task stops this long before a run
    local GHOST_ROUND_BUSY_SECONDS = 270 -- a Ghost Gallery round with travel ("Done: Ghost Gallery round in 244 s")
    local NO_FURNITURE_SKIP_SECONDS = 600
    local NEVER_INTERRUPT = { ghost_gallery = true, hauntlet = true, recover = true, team = true, neon_fusion = true, mega_fusion = true }
    local NEVER_SKIP = { neon_fusion = true, mega_fusion = true, team = true }
    local SKIP_REST_SECONDS = 90
    local HERE_BONUS = 12
    local AT_HOME_BONUS = 8
    local IN_PROGRESS_BONUS = 3
    local STUCK_MOVE_STUDS = 4
    local STUCK_MIN_FAILURES = 2
    function TaskManager.new(deps)
        local self = setmetatable({}, TaskManager)
        self._logger = deps.logger
        self._state = deps.state
        self._tracker = deps.tracker
        self._interaction = deps.interaction
        self._travel = deps.travel
        self._petLocator = deps.petLocator
        self._furniture = deps.furniture
        self._gameData = deps.gameData
        self._farmConfig = deps.farmConfig
        self._selection = PetSelection.new(deps.gameData, deps.farmConfig)
        deps.gameData.selection = self._selection
        self._minigame = deps.minigame
        self._hauntlet = deps.hauntlet
        self._nextEventAt = {}
        self._running = nil
        self._stopped = false
        self._failures = {}
        self._cooldownUntil = {}
        self._disabled = {}
        self._disabledUntil = {}
        self._lastSuccessAt = Util.now()
        self._completions = {}
        self._announcedUnsupported = {}
        self._state:set("farm.currentTask", "none", "TaskManager")
        return self
    end
    function TaskManager:start(maid)
        maid:Give(self._tracker.Completed:Connect(function(owner, petUnique, kind)
            self._completions[kind .. "|" .. owner .. "|" .. tostring(petUnique)] = Util.now()
        end))
        maid:Give(function()
            self:stop()
        end)
    end
    function TaskManager:_isDoable(entry)
        if self:_isBlocked(NeedSession.key(entry)) then return false end
        local doneAt = self._completions[NeedSession.key(entry)]
        if doneAt and Util.now() - doneAt < 6 then return false end -- Allow replicated removal to catch up.
        if entry.owner == "baby" then return self._farmConfig.BabyMode == true and self._state:get("ailments.babyKnown") == true end
        if self._state:get("ailments.petKnown") ~= true then return false end
        if not self._gameData then return false end
        if self._selection:enabled() and (not self._selection.captured or not self._selection:contains(entry.petUnique)) then return false end
        if not self._farmConfig.TwoPets and self._selection.captured and tostring(entry.petUnique) ~= self._selection.ids[1] then return false end
        return self._gameData:isPetEquipped(entry.petUnique)
    end
    function TaskManager:_group(kind)
        local group = nil
        for _, entry in ipairs(self._state:get("ailments.active", {})) do
            if entry.kind == kind and self:_isDoable(entry) then
                group = group or { kind = kind, entries = {}, anyInProgress = false, maxRate = 0, oldest = math.huge }
                table.insert(group.entries, entry)
                if entry.owner == "pet" and not group.petEntry then
                    group.petEntry = entry
                end
                if entry.inProgress then
                    group.anyInProgress = true
                end
                group.maxRate = math.max(group.maxRate, entry.rate or 0)
                group.oldest = math.min(group.oldest, entry.createdAt or math.huge)
            end
        end
        return group
    end
    function TaskManager:_isBlocked(key)
        return self._disabled[key] or Util.now() < (self._cooldownUntil[key] or 0)
    end
    function TaskManager:_expireDisabled()
        local now = Util.now()
        for key, untilTime in pairs(self._disabledUntil) do
            if now >= untilTime then
                self._disabledUntil[key] = nil
                self._disabled[key] = nil
                self._failures[key] = 0
                self._logger:info("Tasks", "'" .. tostring(key) .. "' rested long enough: trying it again (Farm.DisableMinutes)")
            end
        end
    end
    function TaskManager:_priorityOf(kind, group)
        local priority = self._farmConfig.Priority[kind] or 0
        if self._farmConfig.SmartPriority == false or not self._travel then
            return priority
        end
        local destination = GameConstants.LocationForAilment[kind]
        if destination and not GameConstants.SpotForAilment[kind] and self._travel:isAt(destination) then
            priority += HERE_BONUS
        elseif GameConstants.FurnitureForAilment[kind] and self._travel:isAt(GameConstants.HouseInteriorName) then
            priority += AT_HOME_BONUS
        end
        if group and group.anyInProgress then
            priority += IN_PROGRESS_BONUS
        end
        return priority
    end
    function TaskManager:_selectGroup()
        if self._state:get("ailments.known") == false then
            self._why = "waiting for a valid needs snapshot"
            return nil
        end
        if self._travel then
            for _, entry in ipairs(self._state:get("ailments.active", {})) do
                local destination = GameConstants.LocationForAilment[entry.kind]
                if entry.inProgress and destination and not GameConstants.SpotForAilment[entry.kind]
                    and not self:_isBlocked(entry.kind) and self:_isDoable(entry)
                    and Tasks.findFor(entry.kind) and GameConstants.needOn(self._farmConfig, entry.kind)
                    and self._travel:isAt(destination) then
                    local group = self:_group(entry.kind)
                    if group then
                        return group, Tasks.findFor(entry.kind)
                    end
                end
            end
        end
        local best, bestTask, bestPriority = nil, nil, -math.huge
        local seen = {}
        for _, entry in ipairs(self._state:get("ailments.active", {})) do
            local kind = entry.kind
            if not seen[kind] then
                seen[kind] = true
                local taskDefinition = Tasks.findFor(kind)
                if not taskDefinition or not GameConstants.needOn(self._farmConfig, kind) then
                    if not self._announcedUnsupported[kind] then
                        self._announcedUnsupported[kind] = true
                        local why = taskDefinition and "switched off: Auto needs is off or this need is skipped" or "no automatic task yet"
                        self._logger:info("Tasks", "Skipping '" .. kind .. "' (" .. why .. ")")
                    end
                elseif not self:_isBlocked(kind) then
                    local group = self:_group(kind)
                    local priority = group and self:_priorityOf(kind, group) or 0
                    if group and (priority > bestPriority or (priority == bestPriority and group.oldest < best.oldest)) then
                        best, bestTask, bestPriority = group, taskDefinition, priority
                    end
                end
            end
        end
        return best, bestTask
    end
    function TaskManager:_needsTeamSwitch()
        local team = self._state:get("player.team")
        return self._farmConfig.BabyMode and team ~= nil and team ~= GameConstants.BabiesTeam and not self:_isBlocked(TEAM_KEY)
    end
    local NO_TRAVEL = { goTo = true, exitToMainMap = true, visitHouse = true }
    local function sideTravel(travel)
        if not travel then
            return nil
        end
        return setmetatable({}, { __index = function(_, name)
            if NO_TRAVEL[name] then
                return function()
                    return false, "side task: no travel (the main task holds the place)"
                end
            end
            local value = travel[name]
            if type(value) == "function" then
                return function(_, ...)
                    return value(travel, ...)
                end
            end
            return value
        end })
    end
    function TaskManager:_makeContext(runMaid, startedAt, running)
        local context = {
            logger = self._logger,
            state = self._state,
            interaction = self._interaction,
            travel = running and running.side and sideTravel(self._travel) or self._travel,
            side = running and running.side or nil,
            petLocator = self._petLocator,
            furniture = self._furniture,
            gameData = self._gameData,
            farmConfig = self._farmConfig,
            minigame = self._minigame,
            hauntlet = self._hauntlet,
            maid = runMaid,
        }
        local player = game:GetService("Players").LocalPlayer
        local character = player and player.Character
        local root = character and character:FindFirstChild("HumanoidRootPart")
        local humanoid = character and character:FindFirstChildOfClass("Humanoid")
        local anchored = root and root.Anchored
        runMaid:Give(function()
            if root and root.Parent and player.Character == character then
                if humanoid then pcall(function() humanoid:MoveTo(root.Position) end) end
                if root.Anchored ~= anchored then root.Anchored = anchored end
            end
        end)
        function context.waitUntil(predicate, seconds)
            local deadline = Util.now() + seconds
            while true do
                if self._stopped or not self._farmConfig.Enabled or (running and running.cancelled) then
                    return false
                end
                if context.refreshNeeds then context.refreshNeeds() end
                if predicate() then
                    return true
                end
                if Util.now() >= deadline then
                    return false
                end
                task.wait(0.25)
            end
        end
        function context.completedSince(kind, owner, petUnique)
            local at = self._completions[kind .. "|" .. owner .. "|" .. tostring(petUnique)]
            return at ~= nil and at >= startedAt
        end
        function context.setWaiting(isWaiting)
            if running then
                running.waiting = isWaiting == true
            end
        end
        local session = running and running.needSession
        local function rawEntry(kind, owner, unique)
            for _, entry in ipairs(self._state:get("ailments.active", {})) do
                if entry.kind == kind and entry.owner == owner and (owner == "baby" or tostring(entry.petUnique) == tostring(unique)) then
                    return entry
                end
            end
            return nil
        end
        function context.refreshNeeds()
            if self._gameData and self._gameData.refreshNeeds then self._gameData:refreshNeeds() end
        end
        function context.isResolved(entry)
            if not session then return context.completedSince(entry.kind, entry.owner, entry.petUnique) end
            local current = rawEntry(entry.kind, entry.owner, entry.petUnique)
            local at = self._completions[NeedSession.key(entry)]
            local eligible = self:_isDoable(entry)
            if entry.owner == "baby" then eligible = eligible and self._state:get("player.team") == GameConstants.BabiesTeam end
            if entry.owner == "pet" then eligible = eligible and self._petLocator:findModel(entry.petUnique) ~= nil end
            local destination = GameConstants.LocationForAilment[entry.kind]
            if destination then eligible = eligible and self._travel:isAt(destination) end
            local ownerKnown = self._state:get(entry.owner == "baby" and "ailments.babyKnown" or "ailments.petKnown")
            return session:observe(entry, current, at, self._state:get("ailments.known") == true and ownerKnown == true,
                eligible, Util.now(), self._state:get("ailments.revision"))
        end
        function context.findEntry(kind, owner, petUnique)
            local current = rawEntry(kind, owner, petUnique)
            local target = session and session.byKey[kind .. "|" .. owner .. "|" .. tostring(petUnique)]
            if target and context.isResolved(target) then return nil end
            if current then
                if target and target.createdAt and current.createdAt and target.createdAt ~= current.createdAt then
                    return table.clone(target) -- A new episode is not the old task's completion.
                end
                return current
            end
            if target then
                local pending = table.clone(target)
                pending.rate, pending.inProgress, pending.pendingVerification = 0, false, true
                return pending -- Missing/unequipped data must not look like completion to task predicates.
            end
            return nil
        end
        function context.currentGroup(kind)
            if not session then return self:_group(kind) end
            local group = { kind = kind, entries = {}, maxRate = 0, anyInProgress = false, oldest = math.huge,
                maxRemainingSeconds = 0 }
            for _, target in ipairs(session.entries) do
                if target.kind == kind then
                    local entry = context.findEntry(kind, target.owner, target.petUnique)
                    if entry then
                        table.insert(group.entries, entry)
                        if entry.owner == "pet" and not group.petEntry then group.petEntry = entry end
                        group.anyInProgress = group.anyInProgress or entry.inProgress
                        group.maxRate = math.max(group.maxRate, entry.rate or 0)
                        group.oldest = math.min(group.oldest, entry.createdAt or math.huge)
                        local remaining = (entry.rate or 0) > 0 and (1 - (entry.progress or 0)) / entry.rate or 60
                        group.maxRemainingSeconds = math.max(group.maxRemainingSeconds, remaining)
                    end
                end
            end
            return #group.entries > 0 and group or nil
        end
        function context.isKindGone(kind)
            return context.currentGroup(kind) == nil
        end
        function context.kindCompletedSince(kind, since)
            if session then
                for _, entry in ipairs(session.entries) do
                    if entry.kind == kind and not context.isResolved(entry) then return false end
                end
                return true
            end
            for key, at in pairs(self._completions) do
                if at >= since and string.sub(key, 1, #kind + 1) == kind .. "|" then return true end
            end
            return false
        end
        function context.waitForNeed(entry, seconds)
            return context.waitUntil(function() return context.isResolved(entry) end, seconds or 15)
        end
        function context.restoreDisplacedPet(firstUnique, attemptedUnique)
            if self._stopped or not self._farmConfig.Enabled or (running and running.cancelled) then return false end
            local count, known = self._gameData:equippedPetCount()
            if not known or count ~= 1 or not self._gameData:isPetEquipped(attemptedUnique) then return false end
            if self._selection:enabled() and not self._selection:isProtected(firstUnique) then return false end
            local sent = self._interaction:send("EquipItem", firstUnique, { equip_as_last = true })
            return sent and context.waitUntil(function() return self._gameData:isPetEquipped(firstUnique) end, 8)
        end
        function context.recordNeedResult(entry, success)
            if running then
                running.needResults = running.needResults or {}
                running.needResults[NeedSession.key(entry)] = success == true
            end
        end
        function context.confirmReplacement(entry, newKind, afterRevision)
            if not session or entry.kind ~= "mystery" or not afterRevision then return false end
            if self._state:get("ailments.petKnown") ~= true or self._state:get("ailments.revision", 0) <= afterRevision then return false end
            if rawEntry("mystery", entry.owner, entry.petUnique) or not rawEntry(newKind, entry.owner, entry.petUnique) then return false end
            local key = NeedSession.key(entry)
            session.resolved[key], session.states[key] = "confirmed mystery replacement", "completed"
            return true
        end
        function context.setPhase(entry, phase)
            if session then session:setPhase(entry, phase) end
        end
        local cleanupActions = { UnequipItem = true, UnfocusPet = true, ExitFurnitureUseStates = true,
            ExitSeatStates = true, DropPetObject = true, UseTool = true, MinigameLeave = true, MinigameMessage = true, UnequipStroller = true }
        local interaction = self._interaction
        local proxy = {}
        context.interaction = setmetatable(proxy, { __index = function(_, name)
            local method = interaction[name]
            if type(method) ~= "function" then return method end
            return function(receiver, ...)
                local actionName, unique = ...
                local active = not self._stopped and self._farmConfig.Enabled and not (running and running.cancelled)
                if not active then
                    local allowed = running and running.cleaning and name == "send" and cleanupActions[actionName]
                    if actionName == "UseTool" then local _, _, phase = ...; allowed = allowed and phase == "END" end
                    if actionName == "MinigameMessage" then
                        local _, _, message = ...
                        allowed = allowed and (message == "stop_contribute" or message == "stop_prop_contribute")
                    end
                    if not allowed then return false, "task cancelled" end
                end
                if name == "send" and (actionName == "EquipItem" or actionName == "UnequipItem") and self._gameData:hasPet(unique) then
                    if actionName == "UnequipItem" and self._selection:isProtected(unique) then
                        return false, "manual pet selection is protected"
                    elseif actionName == "EquipItem" and self._selection:enabled() then
                        local ok, reason = self._selection:canEquip(unique)
                        if not ok then return false, reason end
                    end
                end
                if receiver == proxy then return method(interaction, ...) end
                return method(receiver, ...)
            end
        end })
        runMaid:Give(function()
            if self._travel and not (running and running.side) then self._travel:cancelPending() end
        end)
        return context
    end
    function TaskManager:_start(key, label, taskDefinition, group, isEventJob, side)
        if self._stopped or not self._farmConfig.Enabled or (self._cleanupCount or 0) > 0 then return false end
        if type(taskDefinition) ~= "table" or type(taskDefinition.run) ~= "function" then
            self._logger:warn("Tasks", "Task definition unavailable: " .. tostring(key))
            return false
        end
        local slot = side and "_side" or "_running"
        if self[slot] then return false end
        local attempt = (self._failures[key] or 0) + 1
        local runMaid = Maid.new()
        local startedAt = Util.now()
        local running = {
            key = key,
            label = label,
            startedAt = startedAt,
            deadline = startedAt + ((not isEventJob and group and group.entries)
                and NeedSession.timeout(taskDefinition, #group.entries) or taskDefinition.timeoutSeconds),
            needSession = not isEventJob and group and group.entries and NeedSession.new(group.entries, startedAt) or nil,
            maid = runMaid,
            eventJob = isEventJob == true,
            side = side == true,
        }
        self[slot] = running
        if side then
            running.label = "(side) " .. label
        else
            self._state:set("farm.currentTask", key, "TaskManager")
        end
        self._logger:info("Tasks", string.format("Start: %s (attempt %d, limit %d s)", running.label, attempt, taskDefinition.timeoutSeconds))
        local context = self:_makeContext(runMaid, startedAt, running)
        running.thread = task.spawn(function()
            local ok, result, reason
            if running.needSession then
                ok, result, reason = pcall(Tasks.runNeedGroup, context, taskDefinition, group, attempt)
            else
                ok, result, reason = pcall(taskDefinition.run, context, group, attempt)
            end
            if self[slot] ~= running then
                return
            end
            if not ok then
                self:_finish("FAILED", "script error: " .. tostring(result), slot)
            elseif result == true then
                self:_finish("SUCCESS", nil, slot)
            else
                self:_finish("FAILED", tostring(reason or "unknown reason"), slot)
            end
        end)
        return true
    end
    function TaskManager:_finish(result, reason, slot)
        slot = slot or "_running"
        local running = self[slot]
        if not running then
            return
        end
        self[slot] = nil
        running.cancelled = true
        if slot == "_running" then self._state:set("farm.needTarget", "", "TaskManager") end
        if slot == "_side" then
            local multi = self._farmConfig.MultiNeed
            self._sideNextAt = Util.now() + math.max(0, tonumber(type(multi) == "table" and multi.GapSeconds) or 2)
        end
        if running.thread and coroutine.running() ~= running.thread then
            pcall(task.cancel, running.thread)
        end
        self._cleanupCount = (self._cleanupCount or 0) + 1
        task.spawn(function()
            running.cleaning = true
            local ok, err = pcall(running.maid.Clean, running.maid)
            running.cleaning = false
            self._cleanupCount = math.max(0, self._cleanupCount - 1)
            if not ok then self._logger:warn("Tasks", "Cleanup failed: " .. tostring(err)) end
        end)
        if slot == "_running" then
            self._state:set("farm.currentTask", "none", "TaskManager")
        end
        local key = running.key
        local seconds = Util.now() - running.startedAt
        if result == "CANCELLED" then
            self._logger:info("Tasks", string.format("Stopped: %s after %.1f s (%s)", running.label, seconds, tostring(reason)))
            return -- Pause/stop is not a failed task and must not postpone an event.
        end
        if result == "INTERRUPTED" then
            if running.eventJob then
                self._nextEventAt[key] = 0
            end
            self._logger:info("Tasks", string.format("Interrupted: %s after %.1f s (%s)", running.label, seconds, tostring(reason)))
            return
        end
        if running.eventJob then
            if key == "ghost_gallery" then self._ghostResumeRetryAt = Util.now() + 5 end
            local wait = key == "pet_pen" and math.max(1, tonumber(self._farmConfig.Event.PetPenMinutes) or 15) * 60
                or (key == "skelicorn" and EventTasks.skelicornShop(self._farmConfig) and 15)
                or EVENT_RECHECK_SECONDS[key] or 60
            self._nextEventAt[key] = Util.now() + wait
        end
        if key == "ghost_gallery" then
            local nest = self:_autoNest()
            if nest == "COLLECT_TWIGS" or nest == "BUILD_NEST" then
                self._logger:info("Ghost", "Minigame complete: resuming AutoNest (" .. nest .. ")")
            end
        end
        local travelTrouble = result ~= "SUCCESS" and type(reason) == "string"
            and (string.find(reason, "travel", 1, true) or string.find(reason, "still in", 1, true)
                or string.find(reason, "going home", 1, true))
        if travelTrouble and key ~= "recover" and slot == "_running" then
            self._travelFailures = (self._travelFailures or 0) + 1
        elseif result == "SUCCESS" then
            self._travelFailures = 0
        end
        if result == "SUCCESS" then
            self._stuckSince = nil
            self._lastSuccessAt = Util.now()
            self._watch = nil
            self._failures[key] = 0
            self._state:increment("farm.tasksSucceeded", 1, "TaskManager")
            self._logger:success("Tasks", string.format("Done: %s in %.1f s", running.label, seconds))
            return
        end
        self._lastFailure = { task = key, reason = tostring(reason or result), at = Util.now() }
        self._state:increment("farm.tasksFailed", 1, "TaskManager")
        if type(reason) == "string" and string.sub(reason, 1, 3) == "no " and string.find(reason, " in your house", 1, true) then
            self._cooldownUntil[key] = Util.now() + NO_FURNITURE_SKIP_SECONDS
            self._logger:info("Tasks", string.format("Skipped for %d min: %s — %s (buy one to farm this need)",
                NO_FURNITURE_SKIP_SECONDS / 60, running.label, reason))
            return
        end
        if running.needSession then
            for _, entry in ipairs(running.needSession.entries) do
                local entryKey = NeedSession.key(entry)
                if not (running.needResults and running.needResults[entryKey]) then
                    local failures = (self._failures[entryKey] or 0) + 1
                    self._failures[entryKey] = failures
                    self._cooldownUntil[entryKey] = Util.now() + math.min(120, self._farmConfig.FailureCooldownSeconds * 2 ^ math.min(failures - 1, 6))
                else
                    self._failures[entryKey], self._cooldownUntil[entryKey] = nil, nil
                end
            end
            self._logger:warn("Tasks", tostring(reason or result) .. " (retry scheduled per participant)")
            return
        end
        local failures = (self._failures[key] or 0) + 1
        self._failures[key] = failures
        local baseWait = math.max(1, tonumber(self._farmConfig.FailureCooldownSeconds) or 30)
        local retryWait = math.min(math.max(baseWait, 120), baseWait * (2 ^ math.min(failures - 1, 6)))
        self._cooldownUntil[key] = Util.now() + retryWait
        if self._watch then
            self._watch.failures += 1
        end
        local message = string.format("%s: %s after %.1f s — %s", result, running.label, seconds, tostring(reason))
        if failures >= self._farmConfig.MaxConsecutiveFailures and key ~= "recover" then
            self._disabled[key] = true
            local minutes = tonumber(self._farmConfig.DisableMinutes) or 0
            if minutes > 0 then
                self._disabledUntil[key] = Util.now() + minutes * 60
                self._logger:error("Tasks", message .. string.format(" (%d failures in a row: disabled for %s min, then tried"
                    .. " again)", failures, tostring(minutes)))
            else
                self._logger:error("Tasks", message .. string.format(" (%d failures in a row: disabled for this session)", failures))
            end
        else
            self._logger:warn("Tasks", message .. string.format(" (retry in %d s)", retryWait))
        end
    end
    function TaskManager:_trackPet()
        if not self._gameData then
            return
        end
        self._selection:observe(Util.now())
        local pair = self._gameData:equippedPetList()
        local count, known = self._gameData:equippedPetCount()
        if known and count == 2 and not self._selection:enabled() then
            self._lastEquippedPair = { pair[1].unique, pair[2].unique }
            self._twoPetRetryAt = nil
            self._disabled.second_pet, self._disabledUntil.second_pet = nil, nil
            self._cooldownUntil.second_pet, self._failures.second_pet = nil, 0
        end
        local current = self._gameData:firstEquippedPet()
        if current then
            self._lastPet = current
            self._farmPet = self._farmPet or current
            if self._badPets then
                self._badPets[current] = nil
            end
        end
    end
    function TaskManager:tick()
        local now = Util.now()
        local dt = math.min(now - (self._lastTickAt or now), 5)
        self._lastTickAt = now
        self._why = nil
        self:_tickInner()
        self._idle = self._idle or {}
        if self._running then
            self._busy = (self._busy or 0) + dt
        else
            local why = self._why or "nothing to do (no need / job due)"
            self._idle[why] = (self._idle[why] or 0) + dt
        end
    end
    function TaskManager:getDiagnostics()
        local idle = {}
        for why, seconds in pairs(self._idle or {}) do
            idle[why] = math.floor(seconds / 6 + 0.5) / 10
        end
        local disabled = {}
        for key, isOff in pairs(self._disabled or {}) do
            if isOff then
                table.insert(disabled, key)
            end
        end
        table.sort(disabled)
        local retrySeconds = {}
        for key, untilTime in pairs(self._cooldownUntil) do
            if untilTime > Util.now() then retrySeconds[key] = math.ceil(untilTime - Util.now()) end
        end
        local restMinutes = {}
        for key, untilTime in pairs(self._disabledUntil or {}) do
            restMinutes[key] = math.max(0, math.ceil((untilTime - Util.now()) / 60))
        end
        return { selection = self._selection:status(), needTarget = self._state:get("farm.needTarget"), lastFailure = self._lastFailure,
            pairRetrySeconds = math.max(0, math.ceil((self._twoPetRetryAt or 0) - Util.now())),
            idle = idle, busyMinutes = math.floor((self._busy or 0) / 6 + 0.5) / 10, disabled = disabled,
            restMinutes = restMinutes, retrySeconds = retrySeconds, waitReason = self._why,
            running = self._running and self._running.label or nil,
            side = self._side and self._side.label or nil }
    end
    function TaskManager:_hasWork()
        for _, entry in ipairs(self._state:get("ailments.active", {})) do
            local kind = entry.kind
            if GameConstants.needOn(self._farmConfig, kind) and Tasks.findFor(kind) and not self:_isBlocked(kind) and self:_isDoable(entry) then
                return true
            end
        end
        return false
    end
    function TaskManager:_stuckCheck()
        local recovery = self._farmConfig.StuckRecovery
        if type(recovery) ~= "table" or not recovery.Enabled or self._state:get("game.ready") ~= true
            or self._state:get("session.disconnectReason") ~= nil then
            self._watch = nil
            return false
        end
        if self._running and NEVER_INTERRUPT[self._running.key] then
            self._watch = nil
            return false
        end
        local character = game:GetService("Players").LocalPlayer.Character
        local root = character and character:FindFirstChild("HumanoidRootPart")
        local position = root and root.Position
        local interior = self._state:get("player.interior")
        if not position or interior == nil then
            return false
        end
        local now = Util.now()
        local watch = self._watch
        local moved = watch and math.sqrt((position.X - watch.x) ^ 2 + (position.Z - watch.z) ^ 2) >= STUCK_MOVE_STUDS
        if not watch or watch.interior ~= interior or moved then
            self._watch = { interior = interior, x = position.X, z = position.Z, since = now, failures = 0 }
            return false
        end
        local limit = math.max(60, tonumber(recovery.Seconds) or 240)
        if now - watch.since < limit or watch.failures < STUCK_MIN_FAILURES then
            return false
        end
        if not self._running and not self:_hasWork() then
            return false
        end
        self._watch = nil
        self._logger:warn("Tasks", string.format("Stuck in %s: not moving, %d tasks failed, none finished for %d s: going home"
            .. " (Farm.StuckRecovery)", tostring(interior), watch.failures, math.floor(now - watch.since)))
        self:_finish("INTERRUPTED", "stuck recovery")
        self:_finish("INTERRUPTED", "stuck recovery", "_side")
        self:_start("recover", "recover: stuck, go home", Tasks.recover, nil)
        return true
    end
    -- A travel failure does not authorize a character reset. Refresh data and report the missing state;
    -- the separately configured AutoRejoin policy is retained for an actually disconnected/stalled client.
    function TaskManager:_whiteScreenCheck()
        if self._state:get("session.disconnectReason") ~= nil
            or self._running ~= nil then
            self._blankSince, self._blankStep = nil, nil
            return false
        end
        local character = game:GetService("Players").LocalPlayer.Character
        local root = character and character:FindFirstChild("HumanoidRootPart")
        local ready = self._state:get("game.ready") == true
        local team = self._state:get("player.team")
        local place = self._state:get("player.interior")
        if (root and place ~= nil and ready and team ~= "Choosing")
            or (team == "Choosing" and self._farmConfig.AutoAcceptMenu == false) then -- the user keeps the menu open
            self._blankSince, self._blankStep = nil, nil
            return false
        end
        local now = Util.now()
        self._blankSince = self._blankSince or now
        local blank = now - self._blankSince
        local what = string.format("ready %s, team %s, place %s, character %s", tostring(ready), tostring(team),
            tostring(place), root and "yes" or "NO")
        local step = self._blankStep or 0
        if (step == 0 and blank > 90) or (step == 1 and blank > 180) then
            self._blankStep = step + 1
            self._logger:warn("Tasks", string.format("Waiting %d s for a usable character / place (%s); no character reset"
                .. " (try %d)", math.floor(blank), what, step + 1))
            if self._logger.saveProblemReport then -- No-op in this build; report remains in memory
                self._logger:saveProblemReport()
            end
            if self._gameData and self._gameData.refreshNeeds then self._gameData:refreshNeeds() end
            return false
        end
        local limit = math.max(120, tonumber(self._farmConfig.StuckRejoinSeconds) or 180)
        if step >= 1 and blank > math.max(limit, 240) and self._farmConfig.AutoRejoin and not self._rejoinSent then
            self._rejoinSent = true
            self:_rejoin(string.format("white screen for %d s (%s)", math.floor(blank), what))
            return true
        end
        return false
    end
    function TaskManager:_tickInner()
        if self._gameData and self._gameData.refreshNeeds then self._gameData:refreshNeeds() end
        if self._stopped or not self._farmConfig.Enabled then
            self:pause(self._stopped and "farm stopped" or "farm paused")
            self._why = self._stopped and "stopped" or "Farm.Enabled = false (watch only)"
            return
        end
        if (self._cleanupCount or 0) > 0 then
            self._why = "cleaning up the previous task"
            return
        end
        if self:_whiteScreenCheck() then
            return
        end
        self:_expireDisabled()
        self:_trackPet()
        if self:_ghostPending() and (not self._running or self._running.key ~= "ghost_gallery") then
            self:_finish("INTERRUPTED", "already inside a Ghost Gallery round")
            self:_finish("INTERRUPTED", "already inside a Ghost Gallery round", "_side")
            if (self._cleanupCount or 0) == 0 then
                self:_start("ghost_gallery", "Ghost Gallery: resume current round", EventTasks.ghostGallery, { resume = true }, true)
            end
            return
        end
        if self._side and Util.now() > self._side.deadline then
            self:_finish("TIMEOUT", "no result within " .. math.floor(self._side.deadline - self._side.startedAt) .. " s", "_side")
        end
        if self:_stuckCheck() then
            return
        end
        if self._running then
            local hRun = self._hauntlet
            local runEndedAt = hRun and ((hRun.leave and hRun.leave.at) or hRun.kickedAt)
            if Util.now() > self._running.deadline then
                self:_finish("TIMEOUT", "no result within " .. math.floor(self._running.deadline - self._running.startedAt) .. " s")
            elseif self._running.key == "hauntlet" and runEndedAt and runEndedAt >= self._running.startedAt
                and Util.now() - runEndedAt > 90 then
                -- v2.1.5 (user report: run over in room 1, then "task: hauntlet" for 15+ min on a white screen): the
                -- run is over but the task never came back: end it and let the farm (and the white screen check) go on
                self._logger:warn("Hauntlet", "The run ended " .. math.floor(Util.now() - runEndedAt)
                    .. " s ago but the run task is stuck: stopping it")
                self:_finish("TIMEOUT", "stuck after the run ended")
            elseif not self._running.needSession and not NEVER_INTERRUPT[self._running.key] and self:_hauntletFirst()
                and self:_hauntletRoundDue(HAUNTLET_INTERRUPT_SECONDS) then
                self._logger:info("Hauntlet", "Priority interrupt: stopping " .. self._running.label .. " for the Hauntlet run")
                self:_finish("INTERRUPTED", "Hauntlet run")
                self:_finish("INTERRUPTED", "Hauntlet run", "_side")
                self._petHoldUntil = Util.now() + 10
                -- the run takes the free slot in this same tick (no "equip pet" in between)
                local key, label, taskDef, group = self:_selectEventJob()
                if key == "hauntlet" then
                    self:_start(key, label, taskDef, group, true)
                end
            elseif not self._running.needSession and not NEVER_INTERRUPT[self._running.key] and self:_ghostRoundDue(GHOST_INTERRUPT_SECONDS)
                and not (self:_hauntletFirst() and self:_hauntletRoundDue(GHOST_INTERRUPT_SECONDS + GHOST_ROUND_BUSY_SECONDS)) then
                self._logger:info("Ghost", "Priority interrupt: stopping " .. self._running.label .. " for the Ghost Gallery round")
                self:_finish("INTERRUPTED", "Ghost Gallery round")
                self:_finish("INTERRUPTED", "Ghost Gallery round", "_side")
            else
                self:_maybeStartSide()
            end
            return
        end
        if self._side then
            self._why = "side task finishing"
            return
        end
        if self._state:get("session.disconnectReason") ~= nil or self._state:get("game.ready") ~= true then
            self._why = self._state:get("session.disconnectReason") ~= nil and "disconnected / kicked" or "game not ready (loading)"
            return
        end
        if self._state:get("player.team") == "Choosing" then
            self._why = "Play menu still open (team Choosing)"
            return
        end
        if self._wantHome then
            self._wantHome = nil
            if self._travel and self._travel:isAt(GameConstants.HouseInteriorName) then
                self._logger:info("Tasks", "Go home: you are already home")
            else
                self:_start("go_home", "go home (you asked)", Tasks.recover, nil)
                return
            end
        end
        do
            local character = game:GetService("Players").LocalPlayer.Character
            local stuck = self._state:get("player.interior") == nil
                or not (character and character:FindFirstChild("HumanoidRootPart"))
            if stuck then
                self._stuckSince = self._stuckSince or Util.now()
                local limit = tonumber(self._farmConfig.StuckRejoinSeconds) or 180
                if self._farmConfig.AutoRejoin and not self._rejoinSent and Util.now() - self._stuckSince > limit then
                    self._rejoinSent = true
                    self:_rejoin(string.format("no place / no character for %d s", math.floor(Util.now() - self._stuckSince)))
                    return
                end
            else
                self._stuckSince = nil
            end
        end
        if self._state:get("player.interior") == nil and self._hadPlace then
            self._why = "changing place (no place in my data)"
            self._transitSince = self._transitSince or Util.now()
            if Util.now() - self._transitSince > 25 then
                self._transitSince = nil
                self._logger:warn("Tasks", "Stuck while changing place for 25 s: going home to recover")
                self:_start("recover", "recover: go home", Tasks.recover, nil)
                return
            end
        else
            self._hadPlace = self._state:get("player.interior") ~= nil or self._hadPlace
            self._transitSince = nil
        end
        if (self._travelFailures or 0) >= 2 then
            self._travelFailures = 0
            self._logger:warn("Tasks", "2 trips in a row failed: recovering")
            self:_start("recover", "recover: go home", Tasks.recover, nil)
            return
        end
        -- v2.1.4 BUG A (user log: "Priority interrupt: stopping equip pet for the Hauntlet run" every ~0.5 s, the run
        -- never started): the pet upkeep below ran before the event jobs, started "equip pet" again, the next tick
        -- interrupted it again. Hauntlet due / pending -> it starts in THIS tick, nothing else is queued before it.
        if self:_hauntletFirst() and (self:_hauntletRoundDue(HAUNTLET_INTERRUPT_SECONDS) or self:_hauntletPending()) then
            local key, label, taskDef, group = self:_selectEventJob()
            if key == "hauntlet" then
                self:_start(key, label, taskDef, group, true)
                return
            end
        end
        if self:_needsTeamSwitch() then
            self:_start(TEAM_KEY, "switch team to " .. GameConstants.BabiesTeam, Tasks.team, nil)
            return
        end
        local petHold = Util.now() < (self._petHoldUntil or 0) -- 10 s after a Hauntlet interrupt: no equip in between
        if self._selection:enabled() then
            local wanted = self._selection:recoveryCandidate(Util.now())
            if wanted and not self:_isBlocked("equip_pet") then
                self._selection:beginRecovery(wanted)
                local first = self._gameData:firstEquippedPet()
                self:_start("equip_pet", "restore selected pet " .. wanted, first and Tasks.equipSecondPet or Tasks.equipPet,
                    { petUnique = wanted, firstUnique = first, onOneSlot = function() self._selection.secondBlocked = true end })
                return
            end
            if not self._selection.captured then self._why = "equip your pet(s), then refresh the selection in the HUB" end
        end
        if self._gameData and self._farmConfig.KeepPetEquipped and not petHold and not self._selection:enabled() then
            local current = self._gameData:firstEquippedPet()
            local count, known = self._gameData:equippedPetCount()
            local protectedPair = self._farmConfig.KeepEquippedPair ~= false and known and count == 2
            local upkeepCanSwap = not protectedPair and not self:_hasWork()
            local skipGrown = self._farmConfig.SkipFullGrown and upkeepCanSwap
            local list = self._gameData:equippedPetList()
            local growableEquipped = false
            for _, pet in ipairs(list) do
                if pet.age == nil or pet.age < GameConstants.FullGrownAge then
                    growableEquipped = true
                end
            end
            self._badPets = self._badPets or {}
            local function usable(unique)
                return unique ~= nil and (self._badPets[unique] or 0) < 2
            end
            local preferNeon = self._farmConfig.PreferNeon == true
            local kindRank = GameConstants.kindRank(self._farmConfig)
            local youngestFirst = self._farmConfig.PetOrder ~= "oldest"
            local function rankOf(unique)
                local kind = self._gameData:getPetKind(unique)
                return kindRank and kind and kindRank[kind] or math.huge, preferNeon and self._gameData:isPetNeon(unique)
            end
            local function better(candidate, current)
                local candidateKind = kindRank and kindRank[candidate.kind] or math.huge
                local currentKind, currentNeon = rankOf(current)
                if candidateKind ~= currentKind then
                    return candidateKind < currentKind
                end
                return preferNeon and candidate.neon and not currentNeon
            end
            local function pickGrowable()
                local farmAge = self._farmPet and self._gameData:petAge(self._farmPet)
                local keepFarmPet = usable(self._farmPet) and farmAge and farmAge < GameConstants.FullGrownAge
                for _, candidate in ipairs(self._gameData:growablePets(preferNeon, kindRank, youngestFirst)) do
                    if keepFarmPet and not better(candidate, self._farmPet) then
                        return self._farmPet
                    end
                    if usable(candidate.unique) then
                        return candidate.unique
                    end
                end
                return keepFarmPet and self._farmPet or nil
            end
            local function onEquipFail(unique)
                return function()
                    self._badPets[unique] = (self._badPets[unique] or 0) + 1
                    if self._badPets[unique] == 2 then
                        self._logger:warn("Tasks", "Pet " .. tostring(unique) .. " could not be equipped twice: skipping it")
                    end
                end
            end
            if not current and known and count == 0 then
                local nowT = Util.now()
                if not self._lastNoPetLog or nowT - self._lastNoPetLog > 60 then
                    self._lastNoPetLog = nowT
                    self._logger:info("Tasks", string.format("No pet equipped: %d pets in the backpack still grow (usable: %s),"
                        .. " pet list %s, egg buying %s", #self._gameData:growablePets(), tostring(pickGrowable() ~= nil),
                        self._gameData:petInventoryKnown() and "known" or "NOT known yet",
                        not self._farmConfig.BuyEgg and "off" or (self:_isBlocked("buy_egg") and "paused after failures" or "on")))
                end
            end
            local lastAgeUnknown = self._lastPet ~= nil and self._gameData:petAge(self._lastPet) == nil
            local focusNow = GameConstants.focusOf(self._farmConfig)
            -- Mega a Pet with an egg: one of that egg is always on hand, so the hatching never stops
            if upkeepCanSwap and focusNow and focusNow.kind == "egg" and known and self._gameData:petInventoryKnown()
                and self._gameData:growingCopies(focusNow.id) == 0 and not (lastAgeUnknown and not current)
                and not self:_isBlocked("buy_egg") then
                local max = tonumber(self._farmConfig.MaxEggBuysPerSession) or 0
                self._eggBuys = self._eggBuys or 0
                if max <= 0 or self._eggBuys < max then
                    self:_start("buy_egg", "Mega a Pet: buy the next " .. focusNow.id, Tasks.buyEgg, { onBought = function()
                        self._eggBuys += 1
                    end })
                    return
                end
            end
            if upkeepCanSwap and (self._farmConfig.BuyEgg or (focusNow and focusNow.kind == "egg")) and known
                and self._gameData:petInventoryKnown() and not pickGrowable()
                and not (lastAgeUnknown and not current) and not self:_isBlocked("buy_egg") then
                local max = tonumber(self._farmConfig.MaxEggBuysPerSession) or 0
                self._eggBuys = self._eggBuys or 0
                if max <= 0 or self._eggBuys < max then
                    local nothing = (not current and count == 0 and not self._lastPet)
                    local allGrown = #list > 0 and not growableEquipped
                    if nothing or allGrown or (not current and count == 0) then
                        self:_start("buy_egg", "buy an egg", Tasks.buyEgg, { onBought = function()
                            self._eggBuys += 1
                        end })
                        return
                    end
                end
            end
            if not current and known and count == 0 and not self:_isBlocked("equip_pet") then
                local wanted = self._farmConfig.KeepEquippedPair ~= false and self._lastEquippedPair and self._lastEquippedPair[1]
                    or (skipGrown and (pickGrowable() or self._lastPet) or self._lastPet)
                if wanted and usable(wanted) then
                    self:_start("equip_pet", "equip pet", Tasks.equipPet, { petUnique = wanted, onFail = onEquipFail(wanted) })
                    return
                end
            elseif upkeepCanSwap and (preferNeon or kindRank) and growableEquipped and not self:_isBlocked("keep_pet") then
                local bestEquipped
                for _, pet in ipairs(list) do
                    if pet.unique and (pet.age == nil or pet.age < GameConstants.FullGrownAge) then
                        local entry = { unique = pet.unique, kind = self._gameData:getPetKind(pet.unique),
                            neon = self._gameData:isPetNeon(pet.unique) }
                        if not bestEquipped or better(entry, bestEquipped.unique) then
                            bestEquipped = entry
                        end
                    end
                end
                local wanted = pickGrowable()
                local wantedEntry = wanted and { unique = wanted, kind = self._gameData:getPetKind(wanted),
                    neon = self._gameData:isPetNeon(wanted) }
                if wantedEntry and bestEquipped and wanted ~= bestEquipped.unique and better(wantedEntry, bestEquipped.unique) then
                    self._logger:info("Tasks", "A better pet still grows (" .. tostring(wantedEntry.kind)
                        .. (wantedEntry.neon and ", neon" or "") .. "): farming it first (Farm.FarmPetKinds / Farm.PreferNeon)")
                    self._farmPet = wanted
                    self:_start("keep_pet", "equip the better pet", Tasks.equipPet, { petUnique = wanted, onFail = onEquipFail(wanted) })
                    return
                end
            end
            if skipGrown and #list > 0 and not growableEquipped and not self:_isBlocked("keep_pet") then
                local wanted = pickGrowable()
                if wanted then
                    self._logger:info("Tasks", "Your equipped pet is full grown: equipping one that still grows (Farm.SkipFullGrown)")
                    self._farmPet = wanted
                    self:_start("keep_pet", "equip a pet that still grows", Tasks.equipPet, { petUnique = wanted, onFail = onEquipFail(wanted) })
                    return
                elseif not self._announcedAllGrown then
                    self._announcedAllGrown = true
                    self._logger:warn("Tasks", "Every pet in your backpack is full grown: farming the equipped one"
                        .. (self._farmConfig.BuyEgg and " (buying an egg was not possible)" or " (Farm.BuyEgg = false)"))
                end
            end
            -- v2.1.5 (users with the 2-pet perk / Pet Certificate: "it does not equip 2 pets at once"): a second growing
            -- pet next to the first. Found out by trying: when the second equip pushes the first pet out, this account
            -- holds 1 pet, the first one comes back and it is not tried again this session.
            if self._selection.twoSlotsObserved and not self._selection.secondBlocked
                and self._farmConfig.TwoPets ~= false and Util.now() >= (self._twoPetRetryAt or 0) and known and self._gameData:petInventoryKnown()
                and not self:_isBlocked("second_pet") then
                if count == 2 and skipGrown then
                    for _, pet in ipairs(list) do
                        if pet.unique and pet.age and pet.age >= GameConstants.FullGrownAge then
                            local spare
                            for _, candidate in ipairs(self._gameData:growablePets(preferNeon, kindRank, youngestFirst)) do
                                if not self._gameData:isPetEquipped(candidate.unique) and usable(candidate.unique) then
                                    spare = candidate.unique
                                    break
                                end
                            end
                            if spare then
                                self._logger:info("Tasks", "One of your 2 pets is full grown: swapping it for one that still grows")
                                self:_start("second_pet", "swap the full grown pet", Tasks.swapSecondPet,
                                    { petUnique = spare, outUnique = pet.unique })
                                return
                            end
                        end
                    end
                elseif count == 1 and current then
                    local second
                    for _, unique in ipairs(self._farmConfig.KeepEquippedPair ~= false and self._lastEquippedPair or {}) do
                        if unique ~= current and not self._gameData:isPetEquipped(unique) and self._gameData:getPetKind(unique) then
                            second = unique
                            break
                        end
                    end
                    for _, candidate in ipairs(self._gameData:growablePets(preferNeon, kindRank, youngestFirst)) do
                        if not second and candidate.unique ~= current and not self._gameData:isPetEquipped(candidate.unique)
                            and usable(candidate.unique) then
                            second = candidate.unique
                            break
                        end
                    end
                    if second then
                        self:_start("second_pet", "equip a second pet", Tasks.equipSecondPet, { petUnique = second,
                            firstUnique = current, onOneSlot = function()
                                self._selection.secondBlocked = true
                                self._twoPetRetryAt = math.huge
                            end, onFail = onEquipFail(second) })
                        return
                    end
                end
            end
        end
        if self:_needsTeamSwitch() then
            self:_start(TEAM_KEY, "switch team to " .. GameConstants.BabiesTeam, Tasks.team, nil)
            return
        end
        local pending, pendingTask = self:_selectGroup()
        if pending and self._farmConfig.PrioritizeNeeds ~= false and not self:_ghostRoundDue(GHOST_INTERRUPT_SECONDS)
            and not self:_hauntletRoundDue(HAUNTLET_INTERRUPT_SECONDS) then
            self:_start(pending.kind, pending.kind .. " (needs first)", pendingTask, pending)
            return
        end
        local eventKey, eventLabel, eventTask, eventGroup = self:_selectEventJob()
        if eventKey then
            self:_start(eventKey, eventLabel, eventTask, eventGroup, true)
            return
        end
        local group, taskDefinition = self:_selectGroup()
        if group then
            local owners = {}
            for _, entry in ipairs(group.entries) do
                table.insert(owners, entry.owner == "baby" and "baby" or tostring(entry.petKind or "pet"))
            end
            self:_start(group.kind, group.kind .. " (" .. table.concat(owners, " + ") .. ")", taskDefinition, group)
        end
    end
    function TaskManager:_maybeStartSide()
        local multi = self._farmConfig.MultiNeed
        local main = self._running
        local petCount = self._gameData and self._gameData:equippedPetCount() or 0
        if petCount > 1 or type(multi) ~= "table" or not multi.Enabled or self._side or not main or not main.waiting
            or not main.needSession or not GameConstants.LocationForAilment[main.key] then
            return
        end
        local now = Util.now()
        if now < (self._sideNextAt or 0) or main.deadline - now < 10 then
            return
        end
        local best, bestTask
        for _, kind in ipairs(type(multi.Kinds) == "table" and multi.Kinds or {}) do
            local taskDefinition = Tasks.findFor(kind)
            if kind ~= main.key and taskDefinition and GameConstants.needOn(self._farmConfig, kind) and not self:_isBlocked(kind) then
                local group = self:_group(kind)
                local petOnly = kind == "pet_me" or kind == "play"
                if group and (not petOnly or group.petEntry) then
                    best, bestTask = group, taskDefinition
                    break
                end
            end
        end
        if best then
            local owners = {}
            for _, entry in ipairs(best.entries) do
                table.insert(owners, entry.owner == "baby" and "baby" or tostring(entry.petKind or "pet"))
            end
            self:_start(best.kind, best.kind .. " (" .. table.concat(owners, " + ") .. ")", bestTask, best, false, true)
        end
    end
    function TaskManager:_ghostPending()
        local event, mg = self._farmConfig.Event, self._minigame
        return type(event) == "table" and event.Enabled == true and event.GhostGallery == true
            and mg and mg.available and mg:activeSession() ~= nil
            and self._travel and self._travel:isAt(GameConstants.Event.MinigameInteriorPrefix)
            and not self:_isBlocked("ghost_gallery") and Util.now() >= (self._ghostResumeRetryAt or 0)
    end
    function TaskManager:_ghostRoundDue(lead)
        local event = self._farmConfig.Event
        local data = self._gameData
        if type(event) ~= "table" or not event.Enabled or not event.GhostGallery or not data or not self._minigame
            or not self._minigame.available or self:_isBlocked("ghost_gallery")
            or Util.now() < (self._nextEventAt.ghost_gallery or 0) then
            return nil
        end
        local serverNow = Minigame.serverNow()
        local start = EventTasks.nextRoundStart(data:get(GameConstants.DataKeys.GhostCycle), serverNow)
        if start and start - serverNow <= lead and start - serverNow > -10 then
            return start
        end
        return nil
    end
    -- a join the game already accepted (the run is about to begin): nothing else may take the slot
    function TaskManager:_hauntletPending()
        local h = self._hauntlet
        local event = self._farmConfig.Event
        return type(event) == "table" and event.Hauntlet == true and h ~= nil and h.join ~= nil and not h.leave
            and not h.kicked and Util.now() - (h.join.at or 0) < 90
    end
    function TaskManager:_hauntletFirst()
        local event = self._farmConfig.Event
        return type(event) == "table" and event.Enabled == true and event.Hauntlet == true and event.HauntletFirst ~= false
            and self._hauntlet ~= nil and self._hauntlet.available == true
    end
    function TaskManager:_hauntletRoundDue(lead)
        local event = self._farmConfig.Event
        local data = self._gameData
        if type(event) ~= "table" or event.Hauntlet ~= true or not data or not self._hauntlet
            or not self._hauntlet.available or self:_isBlocked("hauntlet")
            or Util.now() < (self._nextEventAt.hauntlet or 0) then
            return nil
        end
        local serverNow = Minigame.serverNow()
        local start = EventTasks.nextRoundStart(data:get(GameConstants.DataKeys.HauntletCycle), serverNow)
        if start and self._hauntlet.lastRunStart and start - self._hauntlet.lastRunStart < 900 then
            -- the round right after a run never takes me in (reports, v2.1.3): skip it
            start = start + GameConstants.Event.RoundSeconds
        end
        if start and start - serverNow <= lead and start - serverNow > -15 then
            return start
        end
        return nil
    end
    function TaskManager:_autoNest()
        local event = self._farmConfig.Event
        local data = self._gameData
        if type(event) ~= "table" or event.AutoNest == false or event.PigeonNest == false or not data then
            return nil
        end
        local E = GameConstants.Event
        local stateName, placed, held = EventTasks.nestState(data:get(GameConstants.DataKeys.PigeonNest),
            #data:itemsOfId(GameConstants.ToyCategory, E.Twig), #data:itemsOfId(GameConstants.ToyCategory, E.RustyKey))
        local progress = placed + held
        local signature = stateName .. ":" .. progress
        if signature ~= self._nestSignature then
            self._nestSignature = signature
            if stateName == "COMPLETE" then
                self._logger:info("AutoNest", "Nest completed: one-time objective complete (" .. placed .. "/" .. E.NestTwigs .. ")")
            elseif stateName ~= "UNKNOWN" then
                self._logger:info("AutoNest", string.format("%s, twig progress: %d/%d", stateName, progress, E.NestTwigs))
            end
        end
        return stateName
    end
    function TaskManager:_selectEventJob()
        if self:_ghostPending() then return "ghost_gallery", "Ghost Gallery: current round", EventTasks.ghostGallery, { resume = true } end
        local event = self._farmConfig.Event
        local data = self._gameData
        if not data then
            return nil
        end
        local team = self._state:get("player.team")
        local character = game:GetService("Players").LocalPlayer.Character
        if team ~= "Parents" and team ~= GameConstants.BabiesTeam or not (character and character:FindFirstChild("HumanoidRootPart")) then
            return nil
        end
        -- v2.1.4 BUG A: the quick jobs below (age potion, gift, neon fusion) came first and took the slot the Hauntlet
        -- interrupt had just freed -> interrupt -> again. With HauntletFirst a due / pending run is picked first.
        if self:_hauntletFirst() and self._hauntlet and self._hauntlet.available and not self:_isBlocked("hauntlet") then
            local start = self:_hauntletRoundDue(HAUNTLET_LEAD_SECONDS)
            if start or self:_hauntletPending() then
                return "hauntlet", "Hauntlet run", EventTasks.hauntlet, start and { start = start } or nil
            end
        end
        if self._penWanted then
            if data:get(GameConstants.DataKeys.PetPen) == nil then
                self._penWanted = nil
                self._logger:warn("Event", "Pet Pen now: there is no Pet Pen in your data")
            elseif self._travel and self._travel:isAt(GameConstants.HouseInteriorName) then
                self._penWanted = nil
                return "pet_pen", "Pet Pen (you asked)", EventTasks.petPen, { keep = self._farmPet }
            elseif self._disabled.pen_trip then
                self._penWanted = nil
                self._logger:warn("Event", "Pet Pen now: could not get home, request dropped")
            elseif not self:_isBlocked("pen_trip") then
                return "pen_trip", "go home for the Pet Pen (you asked)", Tasks.recover, nil
            end
        end
        do
            local nowExtra = Util.now()
            local function dueExtra(key)
                return not self:_isBlocked(key) and nowExtra >= (self._nextEventAt[key] or 0)
            end
            local potions = self._farmConfig.AutoPotions
            if type(potions) == "table" and potions.Enabled and nowExtra - (self._potionWhyAt or -1e9) >= 60 then
                self._potionWhyAt = nowExtra
                local okWhy, why = pcall(EventTasks.potionWhy, data, self._farmConfig)
                if okWhy and why ~= self._potionWhy then
                    self._potionWhy = why
                    self._logger:info("Tasks", "Auto Potions: " .. why)
                end
            end
            local potionPet = type(potions) == "table" and potions.Enabled and EventTasks.potionTarget(data, self._farmConfig, self._state)
            if potionPet and dueExtra("age_potion") and data:findItems(GameConstants.ItemCategory,
                EventTasks.potionList(self._farmConfig, data, EventTasks.petIdle(self._state, potionPet), potionPet))[1] then
                return "age_potion", "age potion", EventTasks.agePotion, nil
            end
            local open = self._farmConfig.AutoOpen
            if type(open) == "table" and open.Enabled and dueExtra("open_gift") and EventTasks.nextGift(data, self._farmConfig) then
                return "open_gift", "open a gift", EventTasks.openGift, nil
            end
            local neon = self._farmConfig.AutoNeon
            if type(neon) == "table" and neon.Enabled and dueExtra("neon_fusion") then
                local kind = EventTasks.neonPick(data, self._farmConfig)
                if kind then
                    return "neon_fusion", "neon fusion (4 " .. kind .. ")", EventTasks.neonFusion, nil
                end
            end
            if type(neon) == "table" and neon.Mega and dueExtra("mega_fusion") then
                local kind = EventTasks.neonPick(data, self._farmConfig, true)
                if kind then
                    return "mega_fusion", "mega neon fusion (4 neon " .. kind .. ")", EventTasks.megaFusion, nil
                end
            end
        end
        if type(event) ~= "table" or not event.Enabled then
            return nil
        end
        local now = Util.now()
        local function due(key)
            return event[key] ~= false and not self:_isBlocked(key) and now >= (self._nextEventAt[key] or 0)
        end
        local E = GameConstants.Event
        local KEYS = GameConstants.DataKeys
        -- v2.1.3 (user 2026-10-10: "when Ghost Gallery is open and a Hauntlet starts, it takes them to the Ghost
        -- Gallery: only 3-4 of my alts got into the run"): with Farm.Event.HauntletFirst (default on) a Hauntlet run
        -- comes first. A Ghost Gallery round takes ~4-5 min, so it is skipped when a Hauntlet starts before it would end.
        local h = self._hauntlet
        local hauntOn = event.Hauntlet == true and h ~= nil and h.available and not self:_isBlocked("hauntlet")
        local hauntFirst = hauntOn and event.HauntletFirst ~= false
        local hauntPending = hauntOn and h.join ~= nil and not h.leave and not h.kicked and Util.now() - h.join.at < 90
        if hauntFirst then
            local hauntStart = self:_hauntletRoundDue(HAUNTLET_LEAD_SECONDS)
            if hauntPending or hauntStart then
                return "hauntlet", "Hauntlet run", EventTasks.hauntlet, hauntStart and { start = hauntStart } or nil
            end
        end
        local ghostStart = self:_ghostRoundDue(GHOST_GALLERY_LEAD_SECONDS)
        if ghostStart and not (hauntFirst and self:_hauntletRoundDue(GHOST_GALLERY_LEAD_SECONDS + GHOST_ROUND_BUSY_SECONDS)) then
            self._logger:info("Ghost", "Minigame available: starting the Ghost Gallery round")
            return "ghost_gallery", "Ghost Gallery round", EventTasks.ghostGallery, { start = ghostStart }
        end
        if hauntOn and not hauntFirst then
            -- Only start Hauntlet near cycle start (T-45), same idea as Ghost Gallery.
            -- Do NOT take the farm for 10 minutes just because due("hauntlet") is true.
            local hauntStart = self:_hauntletRoundDue(HAUNTLET_LEAD_SECONDS)
            if hauntPending or (hauntStart and not (event.GhostGallery and self:_ghostRoundDue(HAUNTLET_GHOST_GAP_SECONDS))) then
                return "hauntlet", "Hauntlet run", EventTasks.hauntlet, hauntStart and { start = hauntStart } or nil
            end
        end
        local nest = event.PigeonNest ~= false and self:_autoNest()
        if nest == "BUILD_NEST" and due("pigeon_nest") then
            return "pigeon_nest", "build the nest (AutoNest)", EventTasks.pigeonNest, nil
        elseif nest == "COLLECT_TWIGS" and event.Crypt and due("crypt") and data:get(KEYS.Crypt) ~= nil
            and EventTasks.cryptPlan(data:get(KEYS.Crypt), true) then
            return "crypt", "collect twigs in the Crypt (AutoNest)", EventTasks.crypt, nil
        end
        -- v2.1.4 Auto Skelicorn (right under Auto Nest): lever from the Crypt -> machine -> 1 Skelicorn
        local focus = GameConstants.focusOf(self._farmConfig)
        if EventTasks.skelicornOn(self._farmConfig) and data:petInventoryKnown() then
            local step, idleWhy = EventTasks.skelicornStep(data, self._farmConfig)
            if Util.now() - (self._skelicornLineAt or -1e9) >= 20 then -- what Auto Skelicorn waits for (v2.1.5: every 20 s at most)
                local keys = #data:itemsOfId(GameConstants.ToyCategory, E.RustyKey)
                local candy = tonumber(data:get(KEYS.Candy)) or 0
                local line = string.format("Skelicorn: %s | Rusty Keys %d | candy %dk / %dk | Skelicorns: %s",
                    step or ("idle: " .. tostring(idleWhy)), keys, math.floor(candy / 1000), math.floor(EventTasks.skelicornPrice() / 1000),
                    EventTasks.kindProgress(data, E.Skelicorn))
                -- v2.1.5: the Rusty Key 0/1 flicker (key found -> grave opened) no longer writes a line each time: a new
                -- line when the step or the pet counts change, else at most every 15 minutes
                local key = tostring(step or idleWhy) .. "|" .. EventTasks.kindProgress(data, E.Skelicorn)
                self._skelicornLineAt = Util.now()
                if key ~= self._skelicornLine or Util.now() - (self._skelicornNoteAt or -1e9) >= 900 then
                    self._skelicornLine, self._skelicornNoteAt = key, Util.now()
                    self._logger:info("Skelicorn", line)
                    EventTasks.skelicornNote(line)
                end
            end
            local leverHunt = step == "crypt" or (step == "buy" and EventTasks.skelicornNeedsLever(data))
            if leverHunt and due("crypt") and data:get(KEYS.Crypt) ~= nil
                and #data:itemsOfId(GameConstants.ToyCategory, E.RustyKey) > 0 then
                return "crypt", "look for the Lightning Lever in the Crypt (Auto Skelicorn)", EventTasks.crypt, nil
            elseif step and step ~= "crypt" and due("skelicorn") then
                return "skelicorn", "Auto Skelicorn: " .. step, EventTasks.skelicorn, nil
            end
        end
        -- Mega a Pet with a candy pet: Pet Pen slots + 1 copies growing (1 raised, the rest in the pen)
        if focus and focus.kind == "candy" and due("candy_pet") and data:petInventoryKnown() then
            local wanted = EventTasks.copiesWanted(data, self._farmConfig)
            local growing = data:growingCopies(focus.id)
            local candy = tonumber(data:get(KEYS.Candy)) or 0
            local affordable = math.floor((candy - focus.keepCandy) / focus.price)
            local count = math.min(wanted - growing, affordable)
            if count > 0 then
                return "candy_pet", string.format("Mega a Pet: buy %d x %s (%d grow, %d wanted)", count, focus.id, growing,
                    wanted), EventTasks.buyCandyPet, { pick = { id = focus.id, price = focus.price, count = count,
                    keepCandy = focus.keepCandy }, onBought = function()
                        self._nextEventAt.pet_pen = 0
                    end }
            end
        end
        local candyPets = event.CandyPets
        if type(candyPets) == "table" and candyPets.Enabled and due("candy_pet") and data:petInventoryKnown() then
            local pick = EventTasks.candyPetTarget(data, candyPets)
            if pick then
                return "candy_pet", "buy " .. pick.id .. " (" .. pick.price .. " candy)", EventTasks.buyCandyPet, nil
            end
        end
        if event.StrayCat and due("stray_cat") then
            local cat = data:get(KEYS.StrayCat)
            if type(cat) == "table" and cat.fed_today == false then
                return "stray_cat", "feed the Stray Cat", EventTasks.strayCat, nil
            end
        end
        local cryptOn = event.Crypt or (focus ~= nil and focus.kind == "spider")
        -- user 2026-10-11: "with Auto Skelicorn on, the lever comes first, 100%": while the lever is still needed the
        -- Crypt picks (Farm.Event.CryptOpen) do not run; the Auto Skelicorn block above opens the Crypt for the lever
        -- (log 2026-10-11: while the step showed "buy" the normal Crypt picks spent the Rusty Key on a ladder)
        local leverFirst = EventTasks.skelicornOn(self._farmConfig) and data:petInventoryKnown()
            and EventTasks.skelicornStep(data, self._farmConfig) ~= nil and EventTasks.skelicornNeedsLever(data)
        if cryptOn and not leverFirst and due("crypt") and data:get(KEYS.Crypt) ~= nil then
            local plan = EventTasks.cryptPick(data:get(KEYS.Crypt), event.CryptOpen)
            if plan and plan.spider and event.MummySpider ~= false then
                return "crypt", "claim the Mummy Spider", EventTasks.crypt, nil
            elseif plan and not plan.spider and #data:itemsOfId(GameConstants.ToyCategory, E.RustyKey) > 0 then
                return "crypt", "open a Crypt grave", EventTasks.crypt, nil
            end
        end
        if event.Quests and now >= (self._questLogAt or 0) then
            self._questLogAt = now + 600
            self._logger:info("Event", "Quests: " .. EventTasks.describeQuests(data:get(KEYS.Dailies)))
        end
        if event.HouseVisits ~= false and event.Quests and due("house_visits") and EventTasks.visitQuest(data:get(KEYS.Dailies)) then
            return "house_visits", "visit player homes (quest)", EventTasks.houseVisits, nil
        end
        if event.Quests and due("quests") and #EventTasks.questsToClaim(data:get(KEYS.Dailies)) > 0 then
            return "quests", "claim quests", EventTasks.quests, nil
        end
        if event.PigeonNest and event.AutoNest == false and due("pigeon_nest")
            and #data:itemsOfId(GameConstants.ToyCategory, E.Twig) > 0 then
            local nest = data:get(KEYS.PigeonNest)
            if type(nest) == "table" and (tonumber(nest.twigs_contributed) or 0) < E.NestTwigs then
                return "pigeon_nest", "twig to the pigeon nest", EventTasks.pigeonNest, nil
            end
        end
        local focusEgg = focus ~= nil and focus.kind == "egg"
        local penByEggs = not focus or focusEgg -- a pet focus fills the pen with its own copies, not with eggs
        if event.PetPen and event.PetPenStock ~= false and (self._farmConfig.BuyEgg or focusEgg) and penByEggs and due("pen_stock")
            and not self:_isBlocked("buy_egg") and data:get(KEYS.PetPen) ~= nil and data:petInventoryKnown()
            and (tonumber(data:get(KEYS.Money)) or 0) >= (tonumber(event.PetPenStockMinBucks) or 750)
            and self._travel and self._travel:isAt(GameConstants.HouseInteriorName) then
            local wanted = (tonumber(event.PetPenSlots) or E.PetPenSlots) + 1
            local inPen = 0
            for _ in pairs(data:petPenPets()) do
                inPen += 1
            end
            local stock = inPen + #data:growablePets()
            local max = tonumber(self._farmConfig.MaxEggBuysPerSession) or 0
            self._eggBuys = self._eggBuys or 0
            if stock < wanted and (max <= 0 or self._eggBuys < max) then
                self._logger:info("Event", string.format("Pet Pen stock: %d of %d pets still grow (pen %d): buying an egg",
                    stock, wanted, inPen))
                return "pen_stock", "buy an egg for the Pet Pen", Tasks.buyEgg, { onBought = function()
                    self._eggBuys += 1
                    self._nextEventAt.pet_pen = 0
                end }
            end
        end
        if event.PetPen and due("pet_pen") and data:get(KEYS.PetPen) ~= nil and self._travel
            and self._travel:isAt(GameConstants.HouseInteriorName) then
            return "pet_pen", "Pet Pen", EventTasks.petPen, { keep = self._farmPet }
        end
        return nil
    end
    function TaskManager:_rejoin(reason)
        self._logger:warn("Tasks", "Stuck: " .. reason .. ": rejoining a server (Farm.AutoRejoin)")
        local ok, err = pcall(function()
            local Players = game:GetService("Players")
            game:GetService("TeleportService"):Teleport(game.PlaceId, Players.LocalPlayer)
        end)
        if not ok then
            self._rejoinSent = false
            self._logger:warn("Tasks", "Rejoin failed: " .. tostring(err))
        end
    end
    function TaskManager:sendDirect(actionName, ...)
        if self._running or self._side or self._stopped or not self._farmConfig.Enabled or (self._cleanupCount or 0) > 0 then
            return false, "busy or paused"
        end
        return self._interaction:send(actionName, ...)
    end
    function TaskManager:isBusy()
        return self._running ~= nil or self._side ~= nil or (self._cleanupCount or 0) > 0
    end
    function TaskManager:requestGoHome()
        if self._running and NEVER_INTERRUPT[self._running.key] then
            self._wantHome = true
            return true, "Going home after " .. self._running.label
        end
        self:_finish("INTERRUPTED", "you asked to go home")
        self:_finish("INTERRUPTED", "you asked to go home", "_side")
        self._wantHome = true
        return true, "Going home"
    end
    function TaskManager:skipCurrent()
        local running = self._running
        if not running then
            return false, "Nothing is running"
        end
        if NEVER_SKIP[running.key] then
            return false, running.label .. " always finishes (it is safe that way)"
        end
        local key, label = running.key, running.label
        self:_finish("INTERRUPTED", "skipped by you")
        self:_finish("INTERRUPTED", "skipped by you", "_side")
        self._cooldownUntil[key] = Util.now() + SKIP_REST_SECONDS
        if self._nextEventAt[key] ~= nil then
            self._nextEventAt[key] = Util.now() + SKIP_REST_SECONDS
        end
        return true, string.format("Skipped %s (not chosen again for %d s)", label, SKIP_REST_SECONDS)
    end
    function TaskManager:requestPetPen()
        self._penWanted = true
        self._nextEventAt.pet_pen = 0
        self._cooldownUntil.pen_trip = nil
        return true, self._travel and self._travel:isAt(GameConstants.HouseInteriorName) and "Claiming the Pet Pen"
            or "Going home, then claiming the Pet Pen"
    end
    function TaskManager:retryDisabled()
        local count = 0
        local resting = {}
        for key in pairs(self._disabled) do resting[key] = true end
        for key, untilTime in pairs(self._cooldownUntil) do
            if untilTime > Util.now() then resting[key] = true end
        end
        for _ in pairs(resting) do
            count += 1
        end
        self._disabled = {}
        self._disabledUntil = {}
        self._failures = {}
        self._cooldownUntil = {}
        self._twoPetRetryAt = nil
        self._logger:info("Tasks", string.format("Retry: %d resting task%s may run again (you asked)", count, count == 1 and "" or "s"))
        return count
    end
    -- v2.1.5 (user: "Farm status: the next Ghost Gallery and Hauntlet from the game, live; joins tracked here so
    -- they never overlap"): the game's cycle data + the same rules _selectEventJob uses (Hauntlet first, the round
    -- right after a run skipped, a Ghost Gallery round that would still run when a Hauntlet starts skipped)
    function TaskManager:eventTimers()
        local event = self._farmConfig.Event
        local data = self._gameData
        local out = {}
        if type(event) ~= "table" or not data then
            return out
        end
        local now = Minigame.serverNow()
        local current = self._state:get("farm.currentTask", "none")
        local h = self._hauntlet
        local hauntStart
        if event.Enabled ~= true or event.Hauntlet ~= true then
            out.haunt = "off"
        elseif h and h.enter and not h.leave and not h.kicked then
            out.haunt, out.hauntRoom = "run", tonumber(h.roomSeq) or 0
        elseif h and h.join and not h.leave and not h.kicked and Util.now() - (h.join.at or 0) < 90 then
            out.haunt = "joined"
        elseif current == "hauntlet" then
            out.haunt = "joining"
        else
            hauntStart = EventTasks.nextRoundStart(data:get(GameConstants.DataKeys.HauntletCycle), now)
            if hauntStart and h and h.lastRunStart and hauntStart - h.lastRunStart < 900 then
                hauntStart += GameConstants.Event.RoundSeconds
                out.hauntSkipped = true
            end
            out.haunt = hauntStart and "next" or "unknown"
            out.hauntIn = hauntStart and math.max(0, math.floor(hauntStart - now)) or nil
            if self:_isBlocked("hauntlet") then
                out.hauntResting = true
            end
        end
        if event.Enabled ~= true or event.GhostGallery ~= true then
            out.ghost = "off"
        elseif current == "ghost_gallery" then
            out.ghost = "run"
        else
            local ghostStart = EventTasks.nextRoundStart(data:get(GameConstants.DataKeys.GhostCycle), now)
            out.ghost = ghostStart and "next" or "unknown"
            out.ghostIn = ghostStart and math.max(0, math.floor(ghostStart - now)) or nil
            local hauntFirst = out.haunt ~= "off" and event.HauntletFirst ~= false
            if ghostStart and hauntFirst and (out.haunt == "run" or out.haunt == "joined" or out.haunt == "joining"
                or (hauntStart and hauntStart >= ghostStart - HAUNTLET_LEAD_SECONDS
                    and hauntStart - ghostStart < GHOST_ROUND_BUSY_SECONDS)) then
                out.ghostSkipped = true -- that round would still run when the Hauntlet starts: the Hauntlet gets it
                -- both minigames run on the same 10-minute grid (logs: Hauntlet 20:23:05, Ghost Gallery 20:33:05):
                -- the Ghost Gallery plays the round after the Hauntlet one (a run's next round is skipped for it)
                out.ghostPlayIn = out.ghostIn + GameConstants.Event.RoundSeconds
            end
            if self:_isBlocked("ghost_gallery") then
                out.ghostResting = true
            end
        end
        return out
    end
    function TaskManager:getPenInfo()
        local data = self._gameData
        local event = self._farmConfig.Event
        local info = { known = false, slots = tonumber(type(event) == "table" and event.PetPenSlots) or 4 }
        if data and data:get(GameConstants.DataKeys.PetPen) ~= nil then
            info.known = true
            local pets = 0
            for _ in pairs(data:petPenPets()) do
                pets += 1
            end
            info.pets = pets
            local at = self._nextEventAt.pet_pen
            info.nextClaimIn = at and math.max(0, math.floor(at - Util.now())) or 0
        end
        return info
    end
    function TaskManager:refreshSelection()
        if self:isBusy() then return false, "Pause e aguarde a limpeza antes de atualizar a seleção" end
        local ok, reason = self._selection:capture()
        if ok then self:retryDisabled() end
        return ok, reason
    end
    function TaskManager:pause(reason)
        self:_finish("CANCELLED", reason or "farm paused")
        self:_finish("CANCELLED", reason or "farm paused", "_side")
    end
    function TaskManager:stop()
        if self._stopped then
            return
        end
        self._stopped = true
        if self._running then
            self:_finish("CANCELLED", "farm stopped")
        end
        self:_finish("CANCELLED", "farm stopped", "_side")
    end
    return TaskManager
end
__moduleSources["main"] = function(...)
    local import = ...
    local Enums = import("Core/Enums")
    local Util = import("Core/Util")
    local Config = import("Core/Config")
    local Maid = import("Core/Maid")
    local Logger = import("Core/Logger")
    local State = import("Core/State")
    local Scheduler = import("Core/Scheduler")
    local Disclosure = import("Services/Disclosure")
    local Notifier = import("Services/Notifier")
    local SessionWatcher = import("Services/SessionWatcher")
    local SessionStore = import("Services/SessionStore")
    local Telemetry = import("Services/Telemetry")
    local GameConstants = import("Game/GameConstants")
    local GameData = import("Game/GameData")
    local GameIcons = import("Game/GameIcons")
    local PetLocator = import("Game/PetLocator")
    local PlayerSync = import("Game/PlayerSync")
    local AilmentTracker = import("Game/AilmentTracker")
    local Interaction = import("Game/Interaction")
    local Travel = import("Game/Travel")
    local TaskManager = import("Game/TaskManager")
    local Furniture = import("Game/Furniture")
    local Minigame = import("Game/Minigame")
    local Hauntlet = import("Game/Hauntlet")
    local EventTasks = import("Game/EventTasks")
    local Interface = import("Services/Interface")
    local Players = game:GetService("Players")
    local GLOBAL_KEY = "AdoptMeFarm"
    local STOP_FLUSH_SECONDS = 6
    local SESSION_HEARTBEAT_SECONDS = 30
    local STATUS_CHECK_SECONDS = 5
    local TASK_TICK_SECONDS = 0.5
    local CASHBACK_CHECK_SECONDS = 30
    local SUMMARY_CHECK_SECONDS = 30
    local CAMERA_INSIDE_STUDS = 1.5
    local CAMERA_OUT_STUDS = 10
    local function buildSummaryFields(state, logger, candy, candyEarned)
        local startedAt = state:get("session.startedAt", Util.now())
        local fields = {
            { name = "Session time", value = Util.formatDuration(Util.now() - startedAt), inline = true },
            { name = "Needs completed", value = tostring(state:get("stats.needsCompleted", 0)), inline = true },
            { name = "Bucks earned", value = tostring(state:get("stats.bucksEarned", 0)), inline = true },
        }
        local bucks = state:get("player.bucks")
        if bucks then
            table.insert(fields, { name = "Bucks", value = tostring(bucks), inline = true })
        end
        if candy then
            table.insert(fields, { name = "Candy", value = tostring(candy), inline = true })
            table.insert(fields, { name = "Candy earned", value = tostring(candyEarned or 0), inline = true })
        end
        local pets = state:get("pets.equipped", {})
        if #pets > 0 then
            local names = {}
            for _, pet in ipairs(pets) do
                table.insert(names, pet.kind .. (pet.age and (" (age " .. pet.age .. ")") or ""))
            end
            table.insert(fields, { name = "Pet", value = table.concat(names, ", "), inline = true })
        end
        local lastTask = state:get("stats.lastTask")
        if lastTask then
            table.insert(fields, { name = "Last task", value = lastTask, inline = true })
        end
        table.insert(fields, { name = "Log counts", value = string.format("%d warnings, %d errors", logger.Counts.WARN, logger.Counts.ERROR), inline = true })
        return fields
    end
    local function buildStatusLine(state, petLocator)
        local parts = {}
        table.insert(parts, "Bucks " .. tostring(state:get("player.bucks", "?")))
        table.insert(parts, "team " .. tostring(state:get("player.team", "?")))
        table.insert(parts, "in " .. tostring(state:get("player.interior", "?")))
        local petTexts = {}
        for _, pet in ipairs(state:get("pets.equipped", {})) do
            local model = petLocator:findModel(pet.unique)
            table.insert(petTexts, string.format("%s age %s%s", pet.kind, tostring(pet.age or "?"), model and "" or " [model not found]"))
        end
        table.insert(parts, "pets: " .. (#petTexts > 0 and table.concat(petTexts, ", ") or "none"))
        if not state:get("ailments.known", false) then
            table.insert(parts, "needs: unknown yet")
        else
            local needTexts = {}
            for _, entry in ipairs(state:get("ailments.active", {})) do
                local owner = entry.owner == "baby" and "baby" or tostring(entry.petKind or "pet")
                table.insert(needTexts, owner .. ":" .. entry.kind .. (entry.inProgress and "*" or ""))
            end
            table.insert(parts, "needs: " .. (#needTexts > 0 and table.concat(needTexts, ", ") or "none"))
        end
        table.insert(parts, "task: " .. tostring(state:get("farm.currentTask", "none")))
        return table.concat(parts, " | ")
    end
    return function(userConfig, launchInfo)
        local sharedEnvironment = Util.getSharedEnvironment()
        local previous = sharedEnvironment[GLOBAL_KEY]
        if type(previous) == "table" and type(previous.Stop) == "function" then
            pcall(previous.Stop, "replaced by a new execution")
        end
        local saved = sharedEnvironment.AdoptMeLocalSettings
        if type(saved) == "table" and launchInfo.settingsSource == "SETTINGS block in this file"
            and not (type(userConfig) == "table" and type(userConfig.Interface) == "table" and userConfig.Interface.RememberSettings == false) then
            userConfig = GameData.deepCopy(saved)
            userConfig.Farm.Enabled = false
        end
        local config, configWarnings = Config.build(userConfig)
        -- HARD PRIVACY LOCK: cannot be re-enabled by saved config, presets, or loader settings.
        config.Telemetry.Enabled = false
        config.Telemetry.IncludeInventory = false
        config.Telemetry.Url = ""
        config.Notifications.Enabled = false
        config.Notifications.Webhooks = { Summary = "", Alerts = "" }
        config.Notifications.SendTestMessageOnStart = false
        config.Farm.Event.HauntletSquad = false
        config.Farm.Event.HauntletSquadKey = ""
        config.Logging.FileEnabled = false
        config.Logging.SessionFile = false
        local maid = Maid.new()
        local aborted = false
        local boot = { Initializing = true }
        function boot.Stop()
            aborted = true
            config.Farm.Enabled = false
            maid:Clean()
            if sharedEnvironment[GLOBAL_KEY] == boot then sharedEnvironment[GLOBAL_KEY] = nil end
        end
        sharedEnvironment[GLOBAL_KEY] = boot
        __startupCleanup = boot.Stop
        local function checkBoot() assert(not aborted, "startup replaced by another execution") end
        local logger = Logger.new(config.Logging)
        logger.reportHeader = function()
            local executor = "?"
            pcall(function()
                executor = type(identifyexecutor) == "function" and tostring((identifyexecutor())) or "?"
            end)
            return string.format("Adopt Victims %s | executor %s | %s", Disclosure.VERSION, executor, os.date("!%Y-%m-%d %H:%M UTC"))
        end
        for _, warning in ipairs(configWarnings) do
            logger:warn("Config", warning)
        end
        local state = State.new()
        local localPlayer = Players.LocalPlayer
        state:set("session.startedAt", Util.now(), "main")
        state:set("player.name", localPlayer and localPlayer.Name or "?", "Players.LocalPlayer")
        state:set("stats.needsCompleted", 0, "main")
        state:set("stats.bucksEarned", 0, "main")
        local rememberWindow = false -- hard-disable saved UI configs from executors
        local windowSettingsApplied = rememberWindow and Interface.applySaved(config, logger) or 0
        local notifier = Notifier.new(config.Notifications, logger, config.General.ScriptName, Disclosure.VERSION)
        local sessionStore = SessionStore.new(logger, Disclosure.VERSION, config.Logging.SessionFile)
        local previousRun = sessionStore:begin()
        local files = {}
        local logFilePath, logFileProblem = logger:getFilePath()
        table.insert(files, logFilePath and ("log: " .. logFilePath) or ("no log file (" .. tostring(logFileProblem) .. ")"))
        if sessionStore:isAvailable() then
            table.insert(files, "session status: " .. SessionStore.PATH .. " (start time, last seen, clean stop, last Roblox message)")
        end
        if rememberWindow then
            table.insert(files, string.format("window settings: %s (your changes in the window; %d applied over these settings;"
                .. " holds your webhook URL when you typed one in the window)", Interface.SAVE_PATH, windowSettingsApplied))
            table.insert(files, "configs: " .. Interface.CONFIG_FOLDER .. "/<name>" .. Interface.CONFIG_EXTENSION
                .. " (only the configs you save in the window)")
        end
        local isAdoptMe = game.PlaceId == GameConstants.PlaceId
        local gameActionLines = isAdoptMe and Interaction.describeActions() or nil
        local telemetry = Telemetry.new(config.Telemetry, logger, Disclosure.VERSION, state)
        telemetry:start(maid)
        local disclosureLines = Disclosure.buildStartLines(config, files, notifier:getStatusText(), telemetry:statusText(),
            launchInfo)
        table.insert(disclosureLines, "")
        for _, line in ipairs(Disclosure.buildLines(config, files, notifier:getStatusText(), launchInfo, gameActionLines,
            telemetry:statusText())) do
            table.insert(disclosureLines, line)
        end
        logger:report("Disclosure", Disclosure.buildStartLine(config, telemetry:isEnabled()))
        maid:Give(logger.OnEntry:Connect(function(level, category, message)
            if level == Enums.LogLevel.ERROR and category ~= "Notifier" then
                notifier:notify(Enums.NotifyEvent.Error, { { name = "Error", value = category .. ": " .. message } })
            end
        end))
        if previousRun then
            local description = SessionStore.describe(previousRun)
            logger:warn("Session", description)
            notifier:notify(Enums.NotifyEvent.PreviousSessionEnded, {
                { name = "Previous session", value = description },
            })
        end
        local petLocator = nil
        local taskManager = nil
        local uiGameData = nil
        local uiCandyStart = nil
        local gameIcons = GameIcons.new(logger)
        local petPictures = {}
        local function candyNow()
            local candy = uiGameData and tonumber(uiGameData:get("candy_2026")) or nil
            if candy and not uiCandyStart then
                uiCandyStart = candy
            end
            return candy, (candy and uiCandyStart) and (candy - uiCandyStart) or nil
        end
        local function summaryFields()
            return buildSummaryFields(state, logger, candyNow())
        end
        local function petThumbnail()
            return nil -- Discord webhooks removed; no external thumbnail fetch
        end
        if not isAdoptMe then
            logger:warn("Game", string.format("PlaceId %s is not Adopt Me (%d): game features are off", tostring(game.PlaceId), GameConstants.PlaceId))
        else
            local loadedOk, isLoaded = pcall(function()
                return game:IsLoaded()
            end)
            if loadedOk and not isLoaded then
                logger:info("Game", "Waiting for game:IsLoaded()...")
                local deadline = Util.now() + 120
                while not game:IsLoaded() and Util.now() < deadline do checkBoot(); task.wait(0.25) end
                checkBoot()
                assert(game:IsLoaded(), "game loading exceeded 120 seconds; execute again when ready")
            end
            local ReplicatedStorage = game:GetService("ReplicatedStorage")
            if not ReplicatedStorage:FindFirstChild(GameConstants.Remotes.Folder) then
                logger:info("Game", "Waiting for the game to finish loading...")
                local waited = 0
                while not ReplicatedStorage:FindFirstChild(GameConstants.Remotes.Folder) and waited < 120 and not aborted do
                    task.wait(1)
                    waited += 1
                end
            end
            checkBoot()
            local interaction = Interaction.new(logger, state)
            maid:Give(function() interaction:destroy() end)
            local localPlayer = game:GetService("Players").LocalPlayer
            local playerGui = type(localPlayer.FindFirstChild) == "function" and localPlayer:FindFirstChild("PlayerGui")
            local function findPlayButton()
                local node = playerGui
                for _, name in ipairs(GameConstants.PlayButtonPath) do
                    node = node and node:FindFirstChild(name)
                end
                return node
            end
            local function menuOpen(button)
                local ok, open = pcall(function()
                    local menu = playerGui:FindFirstChild(GameConstants.PlayButtonPath[1])
                    return button.Parent ~= nil and button.Visible ~= false and (menu == nil or menu.Enabled ~= false)
                end)
                return ok and open == true
            end
            local function clickUntilClosed(label, button, isOpen)
                logger:info("Game", label .. " is open: clicking")
                for _, method in ipairs(Interaction.CLICK_METHODS) do
                    local ran, detail = Interaction.clickButton(button, method)
                    if ran then
                        local waited = 0
                        while isOpen() and waited < 8 do
                            task.wait(1)
                            waited += 1
                        end
                        if not isOpen() then
                            logger:success("Game", label .. ": click worked (" .. method .. ")")
                            return true
                        end
                        logger:warn("Game", label .. ": click (" .. method .. ") had no effect " .. tostring(detail or ""))
                    else
                        logger:warn("Game", label .. ": click (" .. method .. ") not available: " .. tostring(detail))
                    end
                end
                logger:warn("Game", "Could not close " .. label .. "; please tap it yourself")
                return false
            end
            local function isOnScreen(object)
                local ok, visible = pcall(function()
                    local screenGui = object:FindFirstAncestorOfClass("ScreenGui")
                    if not screenGui or not screenGui.Enabled then
                        return false
                    end
                    local node = object
                    while node and node ~= screenGui do
                        if node:IsA("GuiObject") and node.Visible == false then
                            return false
                        end
                        node = node.Parent
                    end
                    return true
                end)
                return ok and visible == true
            end
            local function searchRoots(root)
                if root ~= playerGui then
                    return { root }
                end
                local roots = {}
                for _, child in ipairs(root:GetChildren()) do
                    local okEnabled, enabled = pcall(function()
                        return child:IsA("ScreenGui") and child.Enabled ~= false and not string.find(child.Name, "AdoptMe", 1, true)
                    end)
                    if okEnabled and enabled then
                        table.insert(roots, child)
                    end
                end
                return roots
            end
            local function findText(root, patterns)
                if type(patterns) == "string" then
                    patterns = { patterns }
                end
                for _, searchRoot in ipairs(searchRoots(root)) do
                    for _, object in ipairs(searchRoot:GetDescendants()) do
                        if (object:IsA("TextLabel") or object:IsA("TextButton")) and type(object.Text) == "string" then
                            local text = string.lower(object.Text)
                            for _, pattern in ipairs(patterns) do
                                if string.find(text, pattern) and isOnScreen(object) then
                                    return object
                                end
                            end
                        end
                    end
                end
                return nil
            end
            local function handleLocationDialog()
                for _ = 1, 30 do
                    local title = findText(playerGui, "choose location")
                    if title then
                        task.wait(1.5)
                        local dialog = title:FindFirstAncestorOfClass("ScreenGui")
                        local homeText = findText(dialog, "^%s*home%s*$")
                        local homeButton = homeText and (homeText:IsA("GuiButton") and homeText or homeText:FindFirstAncestorWhichIsA("GuiButton"))
                        if homeButton then
                            clickUntilClosed("Choose Location (Home)", homeButton, function()
                                return isOnScreen(title)
                            end)
                        else
                            local names = {}
                            for _, object in ipairs(dialog:GetDescendants()) do
                                if object:IsA("GuiButton") and isOnScreen(object) then
                                    table.insert(names, object:GetFullName())
                                end
                            end
                            logger:warn("Game", "Choose Location dialog: no HOME button found. Visible buttons: "
                                .. table.concat(names, " | "))
                        end
                        return
                    end
                    task.wait(1)
                end
                logger:debug("Game", "No Choose Location dialog after Play")
            end
            local POPUP_TEXTS = { "buy bucks", "^%s*sale%s*$" }
            local function isForbidden(button)
                local function bad(text)
                    text = string.lower(tostring(text or ""))
                    return string.find(text, "buy") ~= nil or string.find(text, "purchase") ~= nil or string.find(text, "robux") ~= nil
                end
                if bad(button.Name) or (button:IsA("TextButton") and bad(button.Text)) then
                    return true
                end
                for _, object in ipairs(button:GetDescendants()) do
                    if (object:IsA("TextLabel") or object:IsA("TextButton")) and bad(object.Text) then
                        return true
                    end
                end
                return false
            end
            local function closePopups()
                local quietSeconds = 0
                for _ = 1, 90 do
                    local marker = findText(playerGui, POPUP_TEXTS)
                    if not marker then
                        quietSeconds += 1
                        if quietSeconds >= 15 then
                            local seen = {}
                            for _, searchRoot in ipairs(searchRoots(playerGui)) do
                                for _, object in ipairs(searchRoot:GetDescendants()) do
                                    local name = string.lower(object.Name)
                                    if object:IsA("GuiButton") and (string.find(name, "close") or string.find(name, "exit") or name == "x")
                                        and isOnScreen(object) then
                                        table.insert(seen, object:GetFullName())
                                    end
                                end
                            end
                            logger:debug("Game", "No popup text found. Visible close-like buttons: "
                                .. (#seen > 0 and table.concat(seen, " | ") or "none"))
                            return
                        end
                    else
                        quietSeconds = 0
                        task.wait(1.5)
                        local popupGui = marker:FindFirstAncestorOfClass("ScreenGui")
                        local closeButton
                        local visibleNames = {}
                        for _, object in ipairs(popupGui:GetDescendants()) do
                            if object:IsA("GuiButton") and isOnScreen(object) then
                                table.insert(visibleNames, object:GetFullName())
                                local name = string.lower(object.Name)
                                if not closeButton and not isForbidden(object)
                                    and (string.find(name, "close") or string.find(name, "exit") or name == "x") then
                                    closeButton = object
                                end
                            end
                        end
                        if not closeButton then
                            logger:warn("Game", "Popup '" .. tostring(marker.Text) .. "': no close button found. Visible buttons: "
                                .. table.concat(visibleNames, " | "))
                            return
                        end
                        if not clickUntilClosed("Popup '" .. tostring(marker.Text) .. "' (close)", closeButton, function()
                            return isOnScreen(marker)
                        end) then
                            return
                        end
                    end
                    task.wait(1)
                end
            end
            if config.Farm.AutoAcceptMenu and playerGui then
                local function watchMenu()
                    -- v2.1.4: watched the whole session (was: the first 3 minutes only). A slow load showed the menu
                    -- later than that and the account sat on it; the menu can also come back after a respawn.
                    local clicks = 0
                    while clicks < 20 do
                        local button = config.Farm.AutoAcceptMenu and findPlayButton()
                        if button and menuOpen(button) then
                            task.wait(2)
                            clicks += 1
                            if clickUntilClosed("Main menu (Play)", button, function()
                                return menuOpen(button)
                            end) then
                                handleLocationDialog()
                                closePopups()
                            end
                            task.wait(5)
                        else
                            task.wait(2)
                        end
                    end
                end
                maid:Give(task.spawn(watchMenu))
            end
            -- v2.1.5 (user screenshots: the game's dialogs stay on screen and users complain): the known dialogs get
            -- their harmless answer, the whole session. "Teleport there now?" -> No (the farm travels on its own
            -- schedule); a "Do not show again this session" box is ticked first when the dialog has one.
            local DIALOGS = {
                { text = "starting soon", button = "^%s*no%s*$", label = "Minigame starting soon (No)" },
                { text = "crypt has been reset", button = "^%s*okay%s*$", label = "Crypt reset (Okay)" },
                { text = "game over", button = "^%s*nice!?%s*$", label = "Game over (Nice)" },
                { text = "new pet discovered", button = "^%s*done%s*$", label = "New pet discovered (Done)" },
                { text = "journal updated", button = "^%s*done%s*$", label = "Journal updated (Done)" },
                -- v2.1.6 (reports: "Cash out" alone also matched a button that is always there, 4 clicks every 2 min that
                -- never closed anything): only the dialog that also has the "Do not show again" box
                { text = "^%s*cash out%s*$", also = "do not show again", button = "^%s*cash out%s*$",
                    label = "Bank check (Cash out)" },
            }
            local function buttonText(button)
                local parts = {}
                if button:IsA("TextButton") then
                    table.insert(parts, button.Text)
                end
                for _, object in ipairs(button:GetDescendants()) do
                    if (object:IsA("TextLabel") or object:IsA("TextButton")) and object.Text ~= "" then
                        table.insert(parts, object.Text)
                    end
                end
                return string.lower(table.concat(parts, " "))
            end
            local function findDialogButton(dialogGui, pattern)
                for _, object in ipairs(dialogGui:GetDescendants()) do
                    local button = nil
                    if object:IsA("TextButton") then
                        button = string.find(string.lower(object.Text), pattern) and object or nil
                    elseif object:IsA("TextLabel") and string.find(string.lower(object.Text), pattern) then
                        button = object:FindFirstAncestorWhichIsA("GuiButton")
                    end
                    if button and button:IsDescendantOf(dialogGui) and isOnScreen(button) and not isForbidden(button) then
                        return button
                    end
                end
                return nil
            end
            -- the checkbox sits next to its "Do not show again" text: the text's own button, or a text-less button
            -- beside it. Never any button that says something else (that could be "Yes").
            local function tickDontShowAgain(dialogGui)
                for _, object in ipairs(dialogGui:GetDescendants()) do
                    if (object:IsA("TextLabel") or object:IsA("TextButton")) and isOnScreen(object)
                        and string.find(string.lower(object.Text), "do not show again") then
                        local box = object:IsA("GuiButton") and object or nil
                        local holder = object.Parent
                        if not box and holder and holder:IsA("GuiButton") then
                            box = holder
                        end
                        for _, near in ipairs(not box and holder and holder:GetChildren() or {}) do
                            if not box and near:IsA("GuiButton") and isOnScreen(near) then
                                local text = buttonText(near)
                                if not string.find(text, "%a") or string.find(text, "do not show again") then
                                    box = near
                                end
                            end
                        end
                        if box and not isForbidden(box) then
                            for _, method in ipairs(Interaction.CLICK_METHODS) do
                                if Interaction.clickButton(box, method) then
                                    break
                                end
                            end
                            task.wait(0.3)
                        end
                        return
                    end
                end
            end
            -- last resort when no click closes it: hide the dialog's own frame (not the whole ScreenGui)
            local function hideDialog(marker, dialogGui)
                local frame = marker
                while frame.Parent and frame.Parent ~= dialogGui do
                    frame = frame.Parent
                end
                if frame:IsA("GuiObject") then
                    frame.Visible = false
                    return true
                end
                return false
            end
            -- v2.1.6 optimisation (many accounts on one phone): ONE pass over the visible ScreenGuis every 3 s for all
            -- the dialogs (was one full pass per dialog, every 2 s), and a quick closer: each click way is given 2 s
            -- (was 8 s), its misses are debug lines, and a dialog that cannot be closed twice is left alone 30 min
            local function quickClose(label, button, isOpen)
                for _, method in ipairs(Interaction.CLICK_METHODS) do
                    local ran = Interaction.clickButton(button, method)
                    if ran then
                        local untilAt = os.clock() + 2
                        while isOpen() and os.clock() < untilAt do
                            task.wait(0.25)
                        end
                        if not isOpen() then
                            logger:debug("Game", label .. ": closed (" .. method .. ")")
                            return true
                        end
                    end
                end
                return false
            end
            if playerGui and config.Farm.AutoCloseDialogs ~= false then
                maid:Give(task.spawn(function()
                    local misses, fails = {}, {}
                    while true do
                        task.wait(3)
                        if config.Farm.AutoCloseDialogs ~= false and config.Farm.Enabled ~= false then
                            pcall(function()
                                -- 1) one pass: the first visible text of every dialog
                                local hits, also = {}, {}
                                for _, screen in ipairs(playerGui:GetChildren()) do
                                    if screen:IsA("ScreenGui") and screen.Enabled then
                                        for _, object in ipairs(screen:GetDescendants()) do
                                            if (object:IsA("TextLabel") or object:IsA("TextButton")) and object.Text ~= "" then
                                                local text = string.lower(object.Text)
                                                if string.find(text, "do not show again", 1, true) then
                                                    also[screen] = true
                                                end
                                                for _, rule in ipairs(DIALOGS) do
                                                    if not hits[rule] and string.find(text, rule.text) and isOnScreen(object) then
                                                        hits[rule] = object
                                                    end
                                                end
                                            end
                                        end
                                    end
                                end
                                -- 2) answer what was found
                                for _, rule in ipairs(DIALOGS) do
                                    local marker = hits[rule]
                                    local dialogGui = marker and marker:FindFirstAncestorOfClass("ScreenGui")
                                    if dialogGui and Util.now() >= (misses[rule.label] or 0)
                                        and (not rule.also or also[dialogGui]) then
                                        local button = findDialogButton(dialogGui, rule.button)
                                        if button then
                                            tickDontShowAgain(dialogGui)
                                            if quickClose(rule.label, button, function()
                                                return isOnScreen(marker)
                                            end) then
                                                logger:info("Game", rule.label .. ": closed")
                                                fails[rule.label] = 0
                                            else
                                                fails[rule.label] = (fails[rule.label] or 0) + 1
                                                local hidden = hideDialog(marker, dialogGui)
                                                if fails[rule.label] >= 2 then
                                                    misses[rule.label] = Util.now() + 1800
                                                    logger:warn("Game", rule.label .. ": could not be closed twice"
                                                        .. (hidden and " (hidden)" or "") .. ": left alone for 30 min")
                                                else
                                                    misses[rule.label] = Util.now() + 60
                                                end
                                            end
                                        end
                                    end
                                end
                            end)
                        end
                    end
                end))
            end
            -- v2.1.6 (user screenshot: characters lying inside the hotel lobby floor after a teleport): a character
            -- that stands on nothing (FloorMaterial Air) yet does not fall, or lies (FallingDown / Ragdoll / Physics),
            -- for 3 s in a row is stuck in the map: put back on top of the floor and stood up
            maid:Give(task.spawn(function()
                local stuckFor, lastLift, wedgedFor, lastPos = 0, 0, 0, nil
                while true do
                    task.wait(1)
                    pcall(function()
                        local player = game:GetService("Players").LocalPlayer
                        local character = player and player.Character
                        local root = character and character:FindFirstChild("HumanoidRootPart")
                        local humanoid = character and character:FindFirstChildOfClass("Humanoid")
                        if not (root and humanoid) or root.Anchored or humanoid.Sit or humanoid.SeatPart
                            or humanoid.Health <= 0 or config.Farm.Enabled == false or (taskManager and taskManager:isBusy()) then
                            stuckFor = 0
                            return
                        end
                        local state = humanoid:GetState()
                        local lying = state == Enum.HumanoidStateType.FallingDown or state == Enum.HumanoidStateType.Ragdoll
                            or state == Enum.HumanoidStateType.Physics
                        local hanging = humanoid.FloorMaterial == Enum.Material.Air
                            and math.abs(root.AssemblyLinearVelocity.Y) < 2 and state ~= Enum.HumanoidStateType.Climbing
                            and state ~= Enum.HumanoidStateType.Swimming
                        -- v2.1.6 (user: "the stuck ones stay in Jumping"): Jumping / Freefall that goes nowhere = wedged
                        local airborne = state == Enum.HumanoidStateType.Jumping or state == Enum.HumanoidStateType.Freefall
                        local here = root.Position
                        local still = lastPos ~= nil and (here - lastPos).Magnitude < 1.5
                        lastPos = here
                        wedgedFor = (airborne and still) and wedgedFor + 1 or 0
                        stuckFor = (lying or hanging) and stuckFor + 1 or 0
                        if stuckFor >= 3 and Util.now() - lastLift > 5 then
                            stuckFor = 0
                            local result = Interaction.settle(1)
                            if result == "lifted" then
                                lastLift = Util.now()
                                logger:info("Game", "Character was stuck in the floor: put back on top of it")
                            elseif lying or wedgedFor >= 3 then
                                wedgedFor = 3 -- a lying character that stands right: try a free spot as well
                            end
                        end
                        if wedgedFor >= 3 and Util.now() - lastLift > 5 then
                            wedgedFor = 0
                            lastLift = Util.now()
                            local moved = Interaction.unstick()
                            logger:info("Game", string.format("Character was wedged (%s, not moving): %s", tostring(state.Name),
                                moved and ("moved to a free spot " .. moved .. " studs away") or "no free spot found nearby"))
                        end
                    end)
                end
            end))
            local gameData = GameData.new(logger)
            uiGameData = gameData
            interaction:bindData(gameData, config.Farm)
            telemetry:setGameData(gameData)
            maid:Give(function()
                gameData:destroy()
            end)
            petLocator = PetLocator.new(gameData)
            local function setupGame()
            if gameData:start(maid) then
                PlayerSync.start(maid, state, gameData, petLocator, logger)
                local tracker = AilmentTracker.new(logger, state, notifier, gameData)
                tracker:start(maid)
                local minigame = Minigame.new(logger)
                minigame:start(maid)
                local hauntlet = Hauntlet.new(logger, game:GetService("Players").LocalPlayer.UserId)
                hauntlet:start(maid)
                -- Private build: external Hauntlet squad relay is intentionally removed.
                hauntlet:setSquadRelay(nil, nil)
                telemetry:setDiagnostics(function()
                    local diagnostics = taskManager and taskManager:getDiagnostics() or {}
                    diagnostics.status = petLocator and buildStatusLine(state, petLocator) or nil
                    diagnostics.team = state:get("player.team")
                    diagnostics.place = state:get("player.interior")
                    diagnostics.ready = state:get("game.ready")
                    diagnostics.farmEnabled = config.Farm.Enabled
                    local character = game:GetService("Players").LocalPlayer.Character
                    diagnostics.character = character ~= nil and character:FindFirstChild("HumanoidRootPart") ~= nil
                    return diagnostics
                end)
                taskManager = TaskManager.new({
                    minigame = minigame,
                    hauntlet = hauntlet,
                    logger = logger,
                    state = state,
                    tracker = tracker,
                    interaction = interaction,
                    travel = Travel.new(logger, state, interaction, config.Farm),
                    petLocator = petLocator,
                    furniture = Furniture.new(gameData, state),
                    gameData = gameData,
                    farmConfig = config.Farm,
                })
                taskManager:start(maid)
                state:set("game.ready", true, "main")
                return true
            else
                state:set("game.ready", false, "main")
                return false
            end
            end
            maid:Give(task.spawn(function()
                while not aborted and not setupGame() do task.wait(10) end
            end))
        end
        local scheduler = Scheduler.new(logger, config.General.TickSeconds)
        scheduler:addJob("LogFlush", config.Logging.FlushSeconds, function()
            logger:flush()
        end)
        scheduler:addJob("TelemetryPump", 5, function()
            telemetry:pump()
        end)
        scheduler:addJob("NotifierPump", 1, function()
            notifier:pump()
        end, { runImmediately = true })
        scheduler:addJob("SessionHeartbeat", SESSION_HEARTBEAT_SECONDS, function()
            sessionStore:heartbeat()
        end)
        do
            local lastSummaryAt = Util.now()
            scheduler:addJob("SummaryWebhook", SUMMARY_CHECK_SECONDS, function()
                local minutes = tonumber(config.Notifications.SummaryIntervalMinutes) or 0
                if not notifier:isEnabled() or config.Notifications.SendSummary == false or minutes <= 0 then
                    lastSummaryAt = Util.now()
                    return
                end
                local picture = petThumbnail()
                if Util.now() - lastSummaryAt >= minutes * 60 then
                    lastSummaryAt = Util.now()
                    notifier:notify(Enums.NotifyEvent.Summary, summaryFields(), nil, { thumbnail = picture })
                end
            end)
        end
        if petLocator then
            local lastStatus = nil
            scheduler:addJob("GameStatus", STATUS_CHECK_SECONDS, function()
                local status = buildStatusLine(state, petLocator)
                if status ~= lastStatus then
                    lastStatus = status
                    logger:info("Status", status)
                end
            end, { runImmediately = true })
        end
        scheduler:addJob("Tasks", TASK_TICK_SECONDS, function()
            if taskManager then taskManager:tick() end
        end)
        do
            local lastCashbackAt = Util.now()
            scheduler:addJob("Cashback", CASHBACK_CHECK_SECONDS, function()
                if not taskManager or not (config.Farm.Enabled and config.Farm.CollectCashback) then
                    return
                end
                if Util.now() - lastCashbackAt < math.max(1, tonumber(config.Farm.CashbackMinutes) or 10) * 60 then
                    return
                end
                if state:get("game.ready") ~= true or state:get("session.disconnectReason") ~= nil then
                    return
                end
                local before = state:get("player.bucks")
                if not taskManager:sendDirect("CollectCashback") then
                    return
                end
                lastCashbackAt = Util.now()
                task.delay(5, function()
                    local after = state:get("player.bucks")
                    if type(before) == "number" and type(after) == "number" and after > before then
                        logger:success("Cashback", string.format("Collected: +%d Bucks", after - before))
                    else
                        logger:debug("Cashback", "Nothing collected (Bucks unchanged)")
                    end
                end)
            end)
        end
        scheduler:addJob("Heartbeat", 60, function()
            logger:debug("Core", string.format("Heartbeat: ticks=%d, webhook sent=%d dropped=%d pending=%d",
                scheduler.TickCount, notifier.SentCount, notifier.DroppedCount, notifier:pendingCount()))
        end)
        SessionWatcher.start(maid, logger, notifier, state, sessionStore)
        do
            local localPlayer = game:GetService("Players").LocalPlayer
            local idled = localPlayer and localPlayer.Idled
            if idled then
                maid:Give(idled:Connect(function()
                    if not config.Farm.AntiAfk then
                        return
                    end
                    local ok, reason = Interaction.virtualClick()
                    if ok then
                        logger:info("AntiAfk", "Idle warning from Roblox: sent a virtual click")
                    else
                        logger:warn("AntiAfk", "Virtual click failed: " .. tostring(reason))
                    end
                end))
            else
                logger:warn("AntiAfk", "LocalPlayer.Idled not available: idle kick cannot be prevented")
            end
        end
        do
            local pushing, lastLog = false, -math.huge
            scheduler:addJob("CameraGuard", 1, function()
                if not config.Farm.CameraGuard or pushing then
                    return
                end
                pcall(function()
                    local player = Players.LocalPlayer
                    local camera = workspace.CurrentCamera
                    local character = player and player.Character
                    local head = character and character:FindFirstChild("Head")
                    if not (camera and head) or camera.CameraType ~= Enum.CameraType.Custom
                        or player.CameraMode == Enum.CameraMode.LockFirstPerson then
                        return
                    end
                    if (camera.CFrame.Position - head.Position).Magnitude > CAMERA_INSIDE_STUDS then
                        return
                    end
                    pushing = true
                    local before = player.CameraMinZoomDistance
                    player.CameraMinZoomDistance = math.max(before, CAMERA_OUT_STUDS)
                    task.delay(0.3, function()
                        pcall(function()
                            player.CameraMinZoomDistance = before
                        end)
                        pushing = false
                    end)
                    if Util.now() - lastLog > 60 then
                        lastLog = Util.now()
                        logger:debug("Camera", "Camera was inside your character: zoomed it back out (Farm.CameraGuard)")
                    end
                end)
            end)
        end
        notifier:notify(Enums.NotifyEvent.SessionStarted, {
            { name = "Session time", value = "00:00:00", inline = true },
        }, Disclosure.buildShortText())
        if config.Notifications.SendTestMessageOnStart then
            notifier:notify(Enums.NotifyEvent.Test, {}, "If you can read this, the webhook works.")
        end
        scheduler:start()
        logger:success("Core", "Started. Version " .. Disclosure.VERSION)
        local api = { Version = Disclosure.VERSION, State = state, Disclosure = function()
            for _, line in ipairs(disclosureLines) do
                logger:report("Disclosure", line)
            end
        end }
        local stopped = false
        api.Config = config
        local function remember()
            if config.Interface.RememberSettings then
                sharedEnvironment.AdoptMeLocalSettings = GameData.deepCopy(config)
                sharedEnvironment.AdoptMeLocalSettings.Farm.Enabled = false
            else sharedEnvironment.AdoptMeLocalSettings = nil end
        end
        function api.SetSetting(path, value)
            if stopped then return false, "Script encerrado" end
            if type(path) ~= "table" or #path < 2 then return false, "Caminho de configuração inválido" end
            local old = Config.valueAt(config, path)
            if old == nil or type(old) ~= type(value) then return false, "Tipo ou opção inválida" end
            if path[1] == "Telemetry" or path[1] == "Notifications" or path[#path] == "HauntletSquad" or path[#path] == "HauntletSquadKey"
                or path[#path] == "FileEnabled" or path[#path] == "SessionFile" then return false, "Opção desabilitada nesta edição local" end
            if path[1] == "Farm" and path[2] == "Enabled" then return api.SetFarmEnabled(value) end
            local proposed = GameData.deepCopy(config)
            local parent = Config.valueAt(proposed, { table.unpack(path, 1, #path - 1) })
            parent[path[#path]] = value
            local valid = Config.build(proposed)
            if taskManager and path[1] == "Farm" then taskManager:pause("configuration changed") end
            parent = Config.valueAt(config, { table.unpack(path, 1, #path - 1) })
            parent[path[#path]] = Config.valueAt(valid, path)
            remember()
            return true, "Configuração atualizada"
        end
        function api.RefreshSelection()
            if not taskManager then return false, "Dados do jogo indisponíveis" end
            return taskManager:refreshSelection()
        end
        function api.Icons()
            local pet = state:get("pets.equipped", {})[1]
            return {
                bucks = gameIcons:known("bucks") or gameIcons:currency("bucks", state:get("player.bucks")),
                candy = gameIcons:known("candy") or gameIcons:currency("candy", uiGameData and uiGameData:get("candy_2026")),
                pet = pet and gameIcons:item(pet.kind) or nil,
            }
        end
        function api.GameIcon(name)
            return gameIcons:picture(name)
        end
        function api.Status()
            local diagnostics = taskManager and taskManager:getDiagnostics() or {}
            local started = state:get("session.startedAt")
            local candy = candyNow()
            local pets = {}
            for _, pet in ipairs(state:get("pets.equipped", {})) do
                table.insert(pets, { unique = pet.unique, kind = pet.kind, age = pet.age })
            end
            local needs = {}
            for _, entry in ipairs(state:get("ailments.active", {})) do
                table.insert(needs, { owner = entry.owner, kind = entry.kind, petUnique = entry.petUnique,
                    inProgress = entry.inProgress == true, progress = entry.progress or 0 })
            end
            local nextRoundIn = nil
            pcall(function()
                local now = Minigame.serverNow()
                local start = uiGameData and EventTasks.nextRoundStart(uiGameData:get(GameConstants.DataKeys.GhostCycle), now)
                if start then
                    nextRoundIn = math.max(0, math.floor(start - now))
                end
            end)
            local event = config.Farm.Event
            local featuresOn, featuresTotal = Config.countFeatures(config)
            local keys, twigs, nestTwigs
            if uiGameData then
                pcall(function()
                    keys = #uiGameData:itemsOfId(GameConstants.ToyCategory, GameConstants.Event.RustyKey)
                    twigs = #uiGameData:itemsOfId(GameConstants.ToyCategory, GameConstants.Event.Twig)
                    local nest = uiGameData:get(GameConstants.DataKeys.PigeonNest)
                    nestTwigs = type(nest) == "table" and tonumber(nest.twigs_contributed) or nil
                end)
            end
            return {
                selection = diagnostics.selection,
                lastTask = state:get("stats.lastTask"),
                rustyKeys = keys,
                twigs = twigs,
                nestTwigs = nestTwigs,
                featuresOn = featuresOn,
                featuresTotal = featuresTotal,
                preset = config.Preset,
                ghostEnabled = event.Enabled == true and event.GhostGallery == true,
                petPenEnabled = event.Enabled == true and event.PetPen == true,
                pen = taskManager and taskManager:getPenInfo() or nil,
                webhooksOn = notifier:isEnabled(),
                restMinutes = diagnostics.restMinutes,
                retrySeconds = diagnostics.retrySeconds,
                needTarget = diagnostics.needTarget,
                lastFailure = diagnostics.lastFailure,
                pairRetrySeconds = diagnostics.pairRetrySeconds,
                twoPetsEnabled = config.Farm.TwoPets == true,
                waitReason = diagnostics.waitReason,
                version = Disclosure.VERSION,
                stopped = stopped,
                farmEnabled = config.Farm.Enabled == true,
                ready = state:get("game.ready") == true,
                team = state:get("player.team"),
                place = state:get("player.interior"),
                task = state:get("farm.currentTask", "none"),
                sideTask = diagnostics.side,
                minutes = started and math.floor((Util.now() - started) / 60) or 0,
                needsDone = state:get("stats.needsCompleted", 0),
                bucksEarned = state:get("stats.bucksEarned", 0),
                bucks = state:get("player.bucks"),
                candy = candy,
                candyEarned = (candy and uiCandyStart) and (candy - uiCandyStart) or nil,
                pets = pets,
                needs = needs,
                nextRoundIn = nextRoundIn,
                timers = taskManager and (function()
                    local ok, t = pcall(taskManager.eventTimers, taskManager)
                    return ok and t or nil
                end)() or nil,
                tasksSucceeded = state:get("farm.tasksSucceeded", 0),
                tasksFailed = state:get("farm.tasksFailed", 0),
                disabled = diagnostics.disabled,
                line = petLocator and buildStatusLine(state, petLocator) or nil,
            }
        end
        function api.SetFarmEnabled(enabled)
            if stopped then return false, "Script encerrado; execute o loader novamente" end
            if type(enabled) ~= "boolean" then return false, "Use true ou false" end
            if enabled and taskManager and taskManager._selection:enabled() and not taskManager._selection.captured then
                taskManager._selection:capture()
            end
            config.Farm.Enabled = enabled
            remember()
            if not enabled and taskManager then taskManager:pause("paused from HUB") end
            return true, enabled and "Farm ligado" or "Farm pausado"
        end
        local function quickAction(run)
            if stopped then
                return false, "The farm is stopped: run the loader again"
            end
            if not taskManager then
                return false, "Not in Adopt Me, or the game is not ready yet"
            end
            if not config.Farm.Enabled then
                return false, "Paused: switch 'Farm running' on first (paused = no game actions)"
            end
            return run()
        end
        function api.GoHome()
            return quickAction(function()
                return taskManager:requestGoHome()
            end)
        end
        function api.SkipTask()
            return quickAction(function()
                return taskManager:skipCurrent()
            end)
        end
        function api.ClaimPetPen()
            return quickAction(function()
                return taskManager:requestPetPen()
            end)
        end
        function api.RetryDisabled()
            if not taskManager then
                return false, "Not in Adopt Me, or the game is not ready yet"
            end
            local count = taskManager:retryDisabled()
            return true, count > 0 and string.format("%d resting task%s may run again", count, count == 1 and "" or "s")
                or "No task was resting"
        end
        function api.Catalog()
            local catalog = { petKinds = {}, giftIds = {} }
            if not uiGameData then
                return catalog
            end
            local seenKinds = {}
            local inventory = uiGameData:get(GameConstants.DataKeys.Inventory)
            local pets = type(inventory) == "table" and type(inventory.pets) == "table" and inventory.pets or {}
            for _, pet in pairs(pets) do
                local kind = type(pet) == "table" and tostring(pet.kind or pet.id or "") or ""
                if kind ~= "" and not seenKinds[kind] and not GameConstants.NotFarmablePets[kind] then
                    seenKinds[kind] = true
                    table.insert(catalog.petKinds, kind)
                end
            end
            local seenGifts = {}
            for _, item in ipairs(uiGameData:findItems(GameConstants.GiftCategory, nil)) do
                local id = tostring(item.id)
                if not seenGifts[id] then
                    for _, pattern in pairs(GameConstants.GiftPatterns) do
                        if string.find(id, pattern) and not seenGifts[id] then
                            seenGifts[id] = true
                            table.insert(catalog.giftIds, id)
                        end
                    end
                end
            end
            table.sort(catalog.petKinds)
            table.sort(catalog.giftIds)
            return catalog
        end
        function api.TestWebhook()
            return false, "Webhooks permanently disabled in this build"
        end
        function api.Compatibility()
            local storage = game:GetService("ReplicatedStorage")
            local missing, present = {}, 0
            for name, action in pairs(GameConstants.Actions) do
                local folderName = action.folder and GameConstants.Remotes[action.folder] or GameConstants.Remotes.Folder
                local folder = storage:FindFirstChild(folderName)
                local remote = folder and folder:FindFirstChild(action.remote)
                if remote and (remote:IsA("RemoteEvent") or remote:IsA("RemoteFunction")) then present += 1
                else table.insert(missing, name .. " -> " .. tostring(folderName) .. "/" .. action.remote) end
            end
            table.sort(missing)
            return {present = present, missing = missing, snapshotSource = uiGameData and uiGameData.SnapshotSource,
                note = "Presence of a remote does not verify its current arguments or behavior"}
        end
        function api.ProblemReport()
            local report = logger:problemReport()
            local compatibility = api.Compatibility()
            local status = api.Status()
            local selected = status.selection and table.concat(status.selection.ids or {}, ", ") or "unknown"
            return report .. "\n\nCompatibility (read only): " .. compatibility.present .. " known remotes present"
                .. "\nSnapshot: " .. tostring(compatibility.snapshotSource) .. "\nProtected IDs: " .. selected
                .. "\nMissing remotes: " .. (#compatibility.missing > 0 and table.concat(compatibility.missing, "\n") or "none")
                .. "\n" .. compatibility.note
        end
        function api.ApplyPreset(name, focus)
            local values, preset = Config.presetValues(name, focus or config.Farm.Focus)
            if not values then
                return false, "No preset called " .. tostring(name)
            end
            if taskManager then taskManager:pause("preset changed") end
            local preserve = config.Farm.KeepEquippedPair
            for _, entry in ipairs(values) do
                local parent = Config.valueAt(config, { table.unpack(entry[1], 1, #entry[1] - 1) })
                if type(parent) == "table" then
                    parent[entry[1][#entry[1]]] = entry[2]
                end
            end
            config.Preset = preset.id
            config.Farm.Enabled = false
            config.Farm.KeepEquippedPair = preserve
            config.Farm.Event.Enabled = preset.id ~= "Off" and preset.id ~= "NeedsOnly" and preset.id ~= "NeedsStable"
            remember()
            if config.Farm.Enabled == false and taskManager then taskManager:pause("preset paused the farm") end
            logger:info("Core", "Preset applied: " .. preset.name)
            return true, preset.name
        end
        function api.Stop(reason)
            if stopped then
                return
            end
            remember()
            stopped, aborted = true, true
            config.Farm.Enabled = false
            reason = tostring(reason or "stopped by user")
            scheduler:stop()
            local window = Interface.current
            if window and window.Owner == api then
                window.Close()
            end
            if taskManager then
                taskManager:stop()
                local untilAt = Util.now() + 12
                while (taskManager._cleanupCount or 0) > 0 and Util.now() < untilAt do task.wait(0.1) end
                if (taskManager._cleanupCount or 0) > 0 then logger:warn("Core", "Cleanup still awaiting a server response") end
            end
            sessionStore:markCleanStop()
            logger:info("Core", "Stopping: " .. reason)
            telemetry:pump(true)
            notifier:notify(Enums.NotifyEvent.SessionStopped, summaryFields(), "Reason: " .. reason, { thumbnail = petThumbnail() })
            if sharedEnvironment[GLOBAL_KEY] == api then
                sharedEnvironment[GLOBAL_KEY] = nil
            end
            maid:Clean()
            task.spawn(function()
                notifier:flush(STOP_FLUSH_SECONDS)
                logger:info("Core", "Stopped cleanly")
                logger:close()
                state:destroy()
            end)
        end
        function api.OpenInterface()
            if stopped then return false, "Script stopped; run the loader again" end
            local okUi, uiResult, uiError = pcall(Interface.start, api, { logger = logger, settings = config.Interface })
            if okUi and uiResult == nil then return false, uiError end
            if not okUi then uiError = uiResult end
            if not okUi then
                logger:warn("Interface", "Window not opened (the farm keeps running): " .. tostring(uiError))
            end
            return okUi, uiError
        end
        checkBoot()
        sharedEnvironment[GLOBAL_KEY] = api
        __startupCleanup = nil
        if config.Interface.Enabled then
            task.spawn(api.OpenInterface)
        end
        return api
    end
end
local startOk, startError = pcall(function()
    local environment = (type(getgenv) == "function" and getgenv()) or _G
    local settings = UserConfig
    local launchInfo = { fromLoader = false, settingsSource = "SETTINGS block in this file" }
    if type(environment.AdoptMeFarmSettings) == "table" then
        settings = environment.AdoptMeFarmSettings
        launchInfo.settingsSource = "your loader (getgenv().AdoptMeFarmSettings)"
    end
    local loaderInfo = environment.AdoptMeFarmLoaderInfo
    if type(loaderInfo) == "table" and type(loaderInfo.Url) == "string" then
        launchInfo.fromLoader = true
        launchInfo.loaderUrl = loaderInfo.Url
    end
    return import("main")(settings, launchInfo)
end)
if not startOk then
    if __startupCleanup then pcall(__startupCleanup) end
    error("[AdoptMe Private] Failed to start: " .. tostring(startError), 0)
end
return startError

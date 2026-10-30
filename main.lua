-- HEKZ DROPZONE v5
local CoreGui = game:GetService("CoreGui")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")
local Lighting = game:GetService("Lighting")
local TeleportService = game:GetService("TeleportService")
local MarketplaceService = game:GetService("MarketplaceService")
local Stats = game:GetService("Stats")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

-- выгрузка старой версии при повторном запуске
local genv = (getgenv and getgenv()) or _G
if genv.__HEKZ_UNLOAD then pcall(genv.__HEKZ_UNLOAD) end
if CoreGui:FindFirstChild("HEKZ_MAIN_GUI") then CoreGui.HEKZ_MAIN_GUI:Destroy() end

-- ===================== НАСТРОЙКИ =====================
local S = {
    Accent = Color3.fromRGB(236, 80, 140),
    Blur = true,
    Binds = {
        menu      = {Input = "RightShift",  Mode = "Toggle"},
        aim       = {Input = "MouseButton2", Mode = "Hold"},
        autoclick = {Input = "None",        Mode = "Hold"},
        players   = {Input = "None",        Mode = "Toggle"},
        skeleton  = {Input = "None",        Mode = "Toggle"},
        loot      = {Input = "None",        Mode = "Toggle"},
        crates    = {Input = "None",        Mode = "Toggle"},
        vehicles  = {Input = "None",        Mode = "Toggle"},
    },
    Players = {
        Enabled = true, ShowPlayers = true, ShowBots = true,
        Box = true, Names = true, Chams = true, Distance = true, Health = true,
        Weapon = true, Gear = true,
        ChamsTransp = 55, TextSize = 12, MaxDist = 300,
        BoxColorP = Color3.fromRGB(80, 170, 255), BoxColorB = Color3.fromRGB(255, 70, 70),
        NameColorP = Color3.fromRGB(120, 200, 255), NameColorB = Color3.fromRGB(255, 110, 110),
        ChamsColorP = Color3.fromRGB(50, 150, 255), ChamsColorB = Color3.fromRGB(255, 60, 60),
    },
    Skeleton = {
        Enabled = true, MaxDist = 150, Thickness = 1,
        ColorP = Color3.fromRGB(255, 255, 255), ColorB = Color3.fromRGB(255, 200, 200),
    },
    Loot = {
        Enabled = true, Russian = true, ShowDistance = true,
        MaxDist = 300, MaxLabels = 60, TextSize = 12,
        CustomList = "", CustomOnly = false, CustomBig = true,
        CustomColor = Color3.fromRGB(255, 60, 255),
        Categories = {weapon = true, armor = true, med = true, grenade = true, ammo = false, attach = false, other = false},
        Colors = {
            weapon = Color3.fromRGB(255, 80, 80), armor = Color3.fromRGB(80, 170, 255),
            med = Color3.fromRGB(80, 255, 120), grenade = Color3.fromRGB(255, 160, 40),
            ammo = Color3.fromRGB(235, 235, 235), attach = Color3.fromRGB(190, 120, 255),
            other = Color3.fromRGB(255, 220, 0),
        },
    },
    Crates = {Enabled = true, MaxDist = 500, TextSize = 13, Color = Color3.fromRGB(255, 200, 60)},
    Vehicles = {Enabled = true, MaxDist = 500, TextSize = 13, Color = Color3.fromRGB(80, 220, 255)},
    Aim = {
        Enabled = false, Method = "Camera", Part = "Head",
        Players = true, Bots = true, VisCheck = true, Sticky = true,
        ShowFOV = true, FOV = 120, FOVColor = Color3.fromRGB(255, 255, 255),
        Speed = 35, MaxDist = 400, Prediction = 0,
    },
    Macro = {
        Enabled = true, AutoClick = false, CPS = 12, Recoil = false, RecoilStrength = 3,
    },
}

local CategoryOrder = {"weapon", "armor", "med", "grenade", "ammo", "attach", "other"}
local CategoryNames = {
    weapon = "Оружие", armor = "Броня и рюкзаки", med = "Медицина", grenade = "Гранаты",
    ammo = "Патроны", attach = "Обвесы", other = "Прочее",
}

local T = {
    side = Color3.fromRGB(16, 13, 24),
    card = Color3.fromRGB(28, 24, 40),
    row = Color3.fromRGB(22, 19, 32),
    cardHover = Color3.fromRGB(40, 34, 58),
    line = Color3.fromRGB(54, 46, 78),
    off = Color3.fromRGB(58, 52, 82),
    text = Color3.fromRGB(238, 234, 248),
    dim = Color3.fromRGB(152, 144, 178),
}

local Palette = {
    Color3.fromRGB(255, 80, 80), Color3.fromRGB(255, 160, 40), Color3.fromRGB(255, 220, 0),
    Color3.fromRGB(80, 255, 120), Color3.fromRGB(60, 220, 255), Color3.fromRGB(50, 150, 255),
    Color3.fromRGB(190, 120, 255), Color3.fromRGB(255, 110, 200), Color3.fromRGB(235, 235, 235),
}

-- ===================== УТИЛИТЫ =====================
local connections = {}
local function Connect(signal, fn)
    local c = signal:Connect(fn)
    connections[#connections + 1] = c
    return c
end

local function new(class, props, parent)
    local o = Instance.new(class)
    if props then for k, v in pairs(props) do o[k] = v end end
    if parent then o.Parent = parent end
    return o
end
local function corner(o, r) return new("UICorner", {CornerRadius = UDim.new(0, r)}, o) end
local function stroke(o, color, thickness, transparency)
    return new("UIStroke", {
        Color = color, Thickness = thickness or 1, Transparency = transparency or 0,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
    }, o)
end
local function tween(o, props, t)
    TweenService:Create(o, TweenInfo.new(t or 0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), props):Play()
end
local function sameColor(a, b)
    return math.abs(a.R - b.R) < 0.01 and math.abs(a.G - b.G) < 0.01 and math.abs(a.B - b.B) < 0.01
end
local function esc(s)
    return (tostring(s):gsub("&", "&amp;"):gsub("<", "&lt;"):gsub(">", "&gt;"))
end

-- нижний регистр с поддержкой кириллицы
local function ruLower(s)
    local ok, res = pcall(function()
        local out = {}
        for _, cp in utf8.codes(s) do
            if cp >= 65 and cp <= 90 then cp = cp + 32
            elseif cp >= 0x410 and cp <= 0x42F then cp = cp + 32
            elseif cp == 0x401 then cp = 0x451 end
            out[#out + 1] = utf8.char(cp)
        end
        return table.concat(out)
    end)
    return ok and res or s:lower()
end

local Notify, RefreshUI, ToggleMenu, SelectTab, OpenPicker, Unload

-- ===================== СЛОВАРИ НАЗВАНИЙ (МОЖНО ДОПИСЫВАТЬ) =====================
local RU_NAMES = {
    akm = "АКМ", ak = "АК", crossbow = "Арбалет", hk416 = "HK416", scar = "SCAR",
    microuzi = "Micro UZI", uzi = "UZI", kar98k = "Kar98k", vector = "Vector",
    adrenaline = "Адреналин", firstaid = "Аптечка", medkit = "Мед. набор", bandage = "Бинт",
    painkiller = "Обезболивающее", energydrink = "Энергетик",
    smoke = "Дымовая граната", frag = "Осколочная граната", stun = "Оглушающая граната",
    molotov = "Коктейль Молотова", flashbang = "Светошумовая граната",
    holo = "Голо-прицел", reddot = "Коллиматор", laser = "ЛЦУ",
    thumbgrip = "Упор для пальца", tacticalgrip = "Тактич. рукоять", verticalgrip = "Верт. рукоять",
    angledgrip = "Угловая рукоять", tacticalstock = "Тактич. приклад", stock = "Приклад",
    muzzlebrake = "Дульный тормоз", suppressor = "Глушитель", flashhider = "Пламегаситель",
    comp = "Компенсатор", quickmag = "Быстрый магазин", extmag = "Расш. магазин", mag = "Магазин",
    gascan = "Канистра",
}
local AMMO_NAMES = {
    ["9mm"] = "9 мм", ["556"] = "5.56", ["762"] = "7.62", ["12g"] = "12 к.", ["45"] = ".45",
    ["50"] = ".50", ["300"] = ".300", ["22"] = ".22", ["357"] = ".357", ["308"] = ".308",
}
local CLASS_NAMES = {
    ar = "штурм.", smg = "ПП", sr = "снайп.", sniper = "снайп.", hg = "пист.", pistol = "пист.",
    sg = "дробов.", shotgun = "дробов.", lmg = "пулем.", dmr = "DMR",
}
local CRATE_PATTERNS = {
    {"airdrop", "Аирдроп"}, {"drop", "Аирдроп"}, {"medic", "Мед. ящик"}, {"weapon", "Оружейный ящик"},
    {"ammo", "Ящик с патронами"}, {"military", "Военный ящик"}, {"supply", "Ящик снабжения"},
    {"loot", "Ящик с лутом"}, {"chest", "Сундук"}, {"crate", "Ящик"}, {"box", "Ящик"},
}
local VEHICLE_PATTERNS = {
    {"jeep", "Джип"}, {"uaz", "УАЗ"}, {"buggy", "Багги"}, {"truck", "Грузовик"}, {"van", "Фургон"},
    {"bus", "Автобус"}, {"moto", "Мотоцикл"}, {"bike", "Мотоцикл"}, {"atv", "Квадроцикл"},
    {"quad", "Квадроцикл"}, {"boat", "Лодка"}, {"heli", "Вертолёт"}, {"plane", "Самолёт"},
    {"tank", "Танк"}, {"car", "Машина"},
}

local translateCache = {}
local function Translate(raw)
    local cached = translateCache[raw]
    if cached then return cached end
    local l = raw:lower()
    local result

    if RU_NAMES[l] then
        result = RU_NAMES[l]
    else
        local ammo = l:match("^ammo_(.+)$")
        if ammo then
            result = "Патроны " .. (AMMO_NAMES[ammo] or ammo)
        else
            local n = l:match("^vest(%d+)")
            if n then result = "Бронежилет ур." .. n end
            if not result then
                n = l:match("^helmet(%d+)")
                if n then result = "Шлем ур." .. n end
            end
            if not result then
                n = l:match("^backpack(%d+)")
                if n then result = "Рюкзак ур." .. n end
            end
            if not result then
                n = l:match("^scope(%d+)x")
                if n then result = "Прицел " .. n .. "x" end
            end
            if not result then
                local base, suffix = l:match("^(.-)_(.+)$")
                if base and RU_NAMES[base] then
                    local cls = CLASS_NAMES[suffix]
                    result = RU_NAMES[base] .. (cls and (" (" .. cls .. ")") or (" " .. suffix:upper()))
                end
            end
        end
    end
    if not result then
        result = (raw:gsub("_", " "):gsub("(%l)(%u)", "%1 %2"))
    end
    translateCache[raw] = result
    return result
end

local function PatternName(patterns, raw, fallback)
    local l = raw:lower()
    for _, p in ipairs(patterns) do
        if l:find(p[1], 1, true) then return p[2] end
    end
    return fallback .. " (" .. raw .. ")"
end

-- ===================== КЛАССИФИКАЦИЯ ЛУТА =====================
local WEAPON_PREFIX = {
    "kar", "awm", "m24", "sks", "mini", "vss", "vector", "scar", "hk", "ak", "uzi", "microuzi",
    "mp", "p90", "glock", "m9", "m1911", "m4", "m16", "saiga", "spas", "870", "dbs", "mk",
    "svd", "dragunov", "famas", "aug", "g36", "ump", "kriss", "crossbow", "pistol", "rifle",
    "shotgun", "sniper", "smg", "revolver", "deagle", "m249", "pkm", "rpk", "fal", "g3", "ar15",
}

local function Classify(item)
    local l = item.Name:lower()
    if l:sub(1, 5) == "ammo_" then return "ammo" end

    if item:FindFirstChild("Receiver") or item:FindFirstChild("Barrel") or item:FindFirstChild("Bolt")
        or item:FindFirstChild("Trigger") or item:FindFirstChild("Furniture") then
        return "weapon"
    end
    local rp = item:FindFirstChild("RootPart")
    if rp and (rp:FindFirstChild("MountOptic") or rp:FindFirstChild("AimPoint") or rp:FindFirstChild("Muzzle")) then
        return "weapon"
    end

    if l:find("helmet") or l:find("vest") or l:find("backpack") then return "armor" end
    if l:find("firstaid") or l:find("medkit") or l:find("bandage") or l:find("painkiller")
        or l:find("adrenaline") or l:find("energydrink") then
        return "med"
    end
    if l:find("frag") or l:find("smoke") or l:find("stun") or l:find("molotov") then return "grenade" end
    if l:find("scope") or l:find("holo") or l:find("reddot") or l:find("suppressor")
        or l:find("flashhider") or l:find("comp_") or l:find("quickmag") or l:find("grip")
        or l:find("stock") or l:find("muzzle") or l:find("laser") or l:find("mag") then
        return "attach"
    end
    for _, prefix in ipairs(WEAPON_PREFIX) do
        if l:sub(1, #prefix) == prefix then return "weapon" end
    end
    return "other"
end

local catCache = setmetatable({}, {__mode = "k"})
local function GetCategory(item)
    local e = catCache[item]
    local now = os.clock()
    if e and (e.cat ~= "other" or now - e.t < 3) then return e.cat end
    local cat = Classify(item)
    catCache[item] = {cat = cat, t = now}
    return cat
end

-- ===================== ROOT GUI =====================
local screenGui = new("ScreenGui", {
    Name = "HEKZ_MAIN_GUI", ResetOnSpawn = false, IgnoreGuiInset = true,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
}, CoreGui)
local overlayFolder = new("Folder", {Name = "ESP_Container"}, screenGui)

local blur = new("BlurEffect", {Size = 16, Enabled = false}, Lighting)

-- уведомления (справа снизу)
local toastHolder = new("Frame", {
    BackgroundTransparency = 1, AnchorPoint = Vector2.new(1, 1),
    Position = UDim2.new(1, -18, 1, -18), Size = UDim2.new(0, 300, 0, 320), ZIndex = 50,
}, screenGui)
new("UIListLayout", {
    SortOrder = Enum.SortOrder.LayoutOrder, VerticalAlignment = Enum.VerticalAlignment.Bottom,
    Padding = UDim.new(0, 6),
}, toastHolder)
local toastN = 0
Notify = function(text)
    toastN = toastN + 1
    local f = new("Frame", {
        BackgroundColor3 = T.card, BackgroundTransparency = 1, BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 38), LayoutOrder = toastN,
    }, toastHolder)
    corner(f, 9)
    local st = stroke(f, S.Accent, 1, 1)
    local bar = new("Frame", {
        BackgroundColor3 = S.Accent, BackgroundTransparency = 1, BorderSizePixel = 0,
        Position = UDim2.new(0, 9, 0, 8), Size = UDim2.new(0, 3, 1, -16),
    }, f)
    corner(bar, 2)
    local lbl = new("TextLabel", {
        BackgroundTransparency = 1, TextTransparency = 1, Position = UDim2.new(0, 22, 0, 0),
        Size = UDim2.new(1, -30, 1, 0), Font = Enum.Font.GothamMedium, Text = text,
        TextColor3 = T.text, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left,
    }, f)
    tween(f, {BackgroundTransparency = 0.05}, 0.2)
    tween(st, {Transparency = 0.4}, 0.2)
    tween(bar, {BackgroundTransparency = 0}, 0.2)
    tween(lbl, {TextTransparency = 0}, 0.2)
    task.delay(2.6, function()
        if f.Parent then
            tween(f, {BackgroundTransparency = 1}, 0.25)
            tween(st, {Transparency = 1}, 0.25)
            tween(bar, {BackgroundTransparency = 1}, 0.25)
            tween(lbl, {TextTransparency = 1}, 0.25)
            task.delay(0.3, function() if f.Parent then f:Destroy() end end)
        end
    end)
end

-- ===================== ЦЕЛИ =====================
local Targets = {}
local function BuildTargets()
    local list = {}
    local myChar = LocalPlayer.Character
    local seen = {}
    for _, p in ipairs(Players:GetPlayers()) do
        local c = p.Character
        if c then
            seen[c] = true
            if p ~= LocalPlayer then list[#list + 1] = {char = c, name = p.Name, isBot = false} end
        end
    end
    local live = workspace:FindFirstChild("Live")
    if live then
        for _, obj in ipairs(live:GetChildren()) do
            if obj:IsA("Model") and obj ~= myChar and not seen[obj] then
                list[#list + 1] = {char = obj, name = "Бот", isBot = true}
            end
        end
    end
    return list
end

local function AliveInfo(char)
    if not char or not char.Parent then return nil end
    local hum = char:FindFirstChildOfClass("Humanoid")
    local root = char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Head")
    if not hum or not root then return nil end
    if hum.Health <= 0 or hum:GetState() == Enum.HumanoidStateType.Dead then return nil end
    return hum, root
end

-- ===================== ESP: ЭКИПИРОВКА =====================
local equipCache = setmetatable({}, {__mode = "k"})

local function ScanEquipment(char)
    local weapons, gear, seenName = {}, {}, {}
    local tool = char:FindFirstChildOfClass("Tool")
    if tool then weapons[#weapons + 1] = Translate(tool.Name) end
    for _, d in ipairs(char:GetDescendants()) do
        local n = d.Name
        if not seenName[n] and (d:IsA("Model") or d:IsA("Folder") or d:IsA("Accessory") or d:IsA("BasePart")) then
            local l = n:lower()
            if l:match("^vest%d") or l:match("^helmet%d") or l:match("^backpack%d") then
                seenName[n] = true
                gear[#gear + 1] = Translate(n)
            elseif d:IsA("Model") and #weapons < 2 and Classify(d) == "weapon" then
                seenName[n] = true
                weapons[#weapons + 1] = Translate(n)
            end
        end
    end
    return table.concat(weapons, " / "), table.concat(gear, ", ")
end

local function GetEquipment(char)
    local e = equipCache[char]
    local now = os.clock()
    if e and now - e.t < 0.7 then return e end
    local w, g = ScanEquipment(char)
    e = {t = now, weapon = w, gear = g}
    equipCache[char] = e
    return e
end

-- ===================== ESP ИГРОКОВ (БОКС / ПОДСВЕТКА) =====================
local playerEspCache = {}
local boxCache = {}
local skelCache = {}

local function CreatePlayerBox()
    local frame = new("Frame", {BackgroundTransparency = 1, BorderSizePixel = 0})
    local boxStroke = stroke(frame, Color3.new(1, 1, 1), 1)

    local outer = new("Frame", {
        BackgroundTransparency = 1, BorderSizePixel = 0,
        Position = UDim2.new(0, -1, 0, -1), Size = UDim2.new(1, 2, 1, 2),
    }, frame)
    stroke(outer, Color3.new(0, 0, 0), 1, 0.2)
    local inner = new("Frame", {
        BackgroundTransparency = 1, BorderSizePixel = 0,
        Position = UDim2.new(0, 1, 0, 1), Size = UDim2.new(1, -2, 1, -2),
    }, frame)
    stroke(inner, Color3.new(0, 0, 0), 1, 0.2)

    local nameLbl = new("TextLabel", {
        BackgroundTransparency = 1, Position = UDim2.new(0.5, -100, 0, -17), Size = UDim2.new(0, 200, 0, 14),
        Font = Enum.Font.GothamBold, TextSize = 12, TextStrokeTransparency = 0,
        TextXAlignment = Enum.TextXAlignment.Center,
    }, frame)
    local info = new("TextLabel", {
        BackgroundTransparency = 1, Position = UDim2.new(0.5, -120, 1, 3), Size = UDim2.new(0, 240, 0, 44),
        Font = Enum.Font.GothamBold, TextSize = 11, TextStrokeTransparency = 0, RichText = true,
        TextColor3 = Color3.fromRGB(230, 230, 230), TextXAlignment = Enum.TextXAlignment.Center,
        TextYAlignment = Enum.TextYAlignment.Top,
    }, frame)

    local hpBg = new("Frame", {
        BackgroundColor3 = Color3.fromRGB(15, 15, 15), BackgroundTransparency = 0.25, BorderSizePixel = 0,
        Position = UDim2.new(0, -6, 0, 0), Size = UDim2.new(0, 3, 1, 0),
    }, frame)
    stroke(hpBg, Color3.new(0, 0, 0), 1, 0.2)
    local hpFill = new("Frame", {
        BackgroundColor3 = Color3.fromRGB(0, 255, 0), BorderSizePixel = 0, Size = UDim2.new(1, 0, 1, 0),
    }, hpBg)

    return {frame = frame, stroke = boxStroke, outer = outer, inner = inner, name = nameLbl, info = info, hpBg = hpBg, hpFill = hpFill}
end

-- стабильная рамка: высота от головы до ног, не прыгает от анимаций и оружия
local function GetScreenBox(char, hum, root)
    local head = char:FindFirstChild("Head")
    if root.CFrame.UpVector.Y > 0.7 and head and root.Name == "HumanoidRootPart" then
        local rp = root.Position
        local top = head.Position.Y + head.Size.Y * 0.5 + 0.15
        local feet
        if hum.RigType == Enum.HumanoidRigType.R15 then
            feet = root.Size.Y * 0.5 + hum.HipHeight
        else
            feet = root.Size.Y * 1.5
        end
        local pTop = Camera:WorldToViewportPoint(Vector3.new(rp.X, top, rp.Z))
        local pBot = Camera:WorldToViewportPoint(Vector3.new(rp.X, rp.Y - feet, rp.Z))
        if pTop.Z <= 0 or pBot.Z <= 0 then return nil end
        local y1, y2 = math.min(pTop.Y, pBot.Y), math.max(pTop.Y, pBot.Y)
        local h = y2 - y1
        local cx = (pTop.X + pBot.X) / 2
        local w = h * 0.5
        return cx - w / 2, y1, cx + w / 2, y2
    end

    -- лежит / рэгдолл — по габариту модели
    local cf, size = char:GetBoundingBox()
    local hx, hy, hz = size.X / 2, size.Y / 2, size.Z / 2
    local minX, minY, maxX, maxY = math.huge, math.huge, -math.huge, -math.huge
    local any = false
    for sx = -1, 1, 2 do
        for sy = -1, 1, 2 do
            for sz = -1, 1, 2 do
                local p = Camera:WorldToViewportPoint(cf:PointToWorldSpace(Vector3.new(sx * hx, sy * hy, sz * hz)))
                if p.Z > 0 then
                    any = true
                    if p.X < minX then minX = p.X end
                    if p.X > maxX then maxX = p.X end
                    if p.Y < minY then minY = p.Y end
                    if p.Y > maxY then maxY = p.Y end
                end
            end
        end
    end
    if not any then return nil end
    return minX, minY, maxX, maxY
end

local function ProcessTarget(data, refPos, vp, active)
    local P = S.Players
    local char = data.char
    local hum, root = AliveInfo(char)
    if not hum then return end

    local dist = math.floor((root.Position - refPos).Magnitude)
    if dist > P.MaxDist then return end

    active[char] = true
    local isBot = data.isBot

    -- подсветка модели
    local h = playerEspCache[char]
    if P.Chams then
        if not h or not h.Parent then
            h = new("Highlight", {
                OutlineColor = Color3.new(1, 1, 1), DepthMode = Enum.HighlightDepthMode.AlwaysOnTop,
            }, char)
            playerEspCache[char] = h
        end
        h.FillColor = isBot and P.ChamsColorB or P.ChamsColorP
        h.FillTransparency = P.ChamsTransp / 100
    elseif h then
        h:Destroy()
        playerEspCache[char] = nil
    end

    -- бокс
    local x1, y1, x2, y2 = GetScreenBox(char, hum, root)
    local b = boxCache[char]
    if not x1 or x2 < -50 or x1 > vp.X + 50 or y2 < -50 or y1 > vp.Y + 50 then
        if b then b.frame.Visible = false end
        return
    end
    if not b or not b.frame.Parent then
        b = CreatePlayerBox()
        b.frame.Parent = overlayFolder
        boxCache[char] = b
    end

    b.frame.Position = UDim2.fromOffset(x1, y1)
    b.frame.Size = UDim2.fromOffset(math.max(x2 - x1, 8), math.max(y2 - y1, 8))
    b.frame.Visible = true

    b.stroke.Enabled = P.Box
    b.stroke.Color = isBot and P.BoxColorB or P.BoxColorP
    b.outer.Visible = P.Box
    b.inner.Visible = P.Box

    b.name.Visible = P.Names
    b.name.Text = data.name
    b.name.TextSize = P.TextSize
    b.name.TextColor3 = isBot and P.NameColorB or P.NameColorP

    -- строки под боксом: расстояние / оружие / экипировка
    local lines = {}
    if P.Distance then lines[#lines + 1] = dist .. "м" end
    if P.Weapon or P.Gear then
        local eq = GetEquipment(char)
        if P.Weapon and eq.weapon ~= "" then
            lines[#lines + 1] = '<font color="rgb(255,235,160)">' .. esc(eq.weapon) .. '</font>'
        end
        if P.Gear and eq.gear ~= "" then
            lines[#lines + 1] = '<font color="rgb(150,205,255)">' .. esc(eq.gear) .. '</font>'
        end
    end
    b.info.Visible = #lines > 0
    b.info.Text = table.concat(lines, "\n")
    b.info.TextSize = math.max(P.TextSize - 1, 8)

    b.hpBg.Visible = P.Health
    if P.Health then
        local pct = hum.MaxHealth > 0 and math.clamp(hum.Health / hum.MaxHealth, 0, 1) or 0
        b.hpFill.Size = UDim2.new(1, 0, pct, 0)
        b.hpFill.Position = UDim2.new(0, 0, 1 - pct, 0)
        b.hpFill.BackgroundColor3 = Color3.fromRGB(255 * (1 - pct), 255 * pct, 0)
    end
end

-- ===================== СКЕЛЕТ =====================
local R15_BONES = {
    {"Head", "UpperTorso"}, {"UpperTorso", "LowerTorso"},
    {"UpperTorso", "LeftUpperArm"}, {"LeftUpperArm", "LeftLowerArm"}, {"LeftLowerArm", "LeftHand"},
    {"UpperTorso", "RightUpperArm"}, {"RightUpperArm", "RightLowerArm"}, {"RightLowerArm", "RightHand"},
    {"LowerTorso", "LeftUpperLeg"}, {"LeftUpperLeg", "LeftLowerLeg"}, {"LeftLowerLeg", "LeftFoot"},
    {"LowerTorso", "RightUpperLeg"}, {"RightUpperLeg", "RightLowerLeg"}, {"RightLowerLeg", "RightFoot"},
}
local R6_BONES = {
    {"Head", "Torso"}, {"Torso", "Left Arm"}, {"Torso", "Right Arm"},
    {"Torso", "Left Leg"}, {"Torso", "Right Leg"},
}

local function ProcessSkeleton(data, refPos, active)
    local K = S.Skeleton
    local char = data.char
    local hum, root = AliveInfo(char)
    if not hum then return end
    if (root.Position - refPos).Magnitude > K.MaxDist then return end
    active[char] = true

    local bones = char:FindFirstChild("UpperTorso") and R15_BONES or R6_BONES
    local entry = skelCache[char]
    if not entry then
        entry = {lines = {}}
        skelCache[char] = entry
    end
    local color = data.isBot and K.ColorB or K.ColorP

    for i, bone in ipairs(bones) do
        local line = entry.lines[i]
        if not line then
            line = new("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), BorderSizePixel = 0, Visible = false}, overlayFolder)
            entry.lines[i] = line
        end
        local shown = false
        local a, b = char:FindFirstChild(bone[1]), char:FindFirstChild(bone[2])
        if a and b then
            local pa = Camera:WorldToViewportPoint(a.Position)
            local pb = Camera:WorldToViewportPoint(b.Position)
            if pa.Z > 0 and pb.Z > 0 then
                local d = Vector2.new(pb.X - pa.X, pb.Y - pa.Y)
                line.Position = UDim2.fromOffset((pa.X + pb.X) / 2, (pa.Y + pb.Y) / 2)
                line.Size = UDim2.fromOffset(d.Magnitude, K.Thickness)
                line.Rotation = math.deg(math.atan2(d.Y, d.X))
                line.BackgroundColor3 = color
                shown = true
            end
        end
        line.Visible = shown
    end
    for i = #bones + 1, #entry.lines do entry.lines[i].Visible = false end
end

local function UpdateVisuals()
    local P, K = S.Players, S.Skeleton
    local myChar = LocalPlayer.Character
    local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
    -- когда ты мёртв — считаем от камеры, ESP продолжает работать
    local refPos = myRoot and myRoot.Position or Camera.CFrame.Position
    local vp = Camera.ViewportSize

    local activeP, activeK = {}, {}
    for _, data in ipairs(Targets) do
        local allowed = (data.isBot and P.ShowBots) or (not data.isBot and P.ShowPlayers)
        if allowed then
            if P.Enabled then
                local ok = pcall(ProcessTarget, data, refPos, vp, activeP)
                if not ok and boxCache[data.char] then boxCache[data.char].frame.Visible = false end
            end
            if K.Enabled then
                local ok = pcall(ProcessSkeleton, data, refPos, activeK)
                if not ok and skelCache[data.char] then
                    for _, l in ipairs(skelCache[data.char].lines) do l.Visible = false end
                end
            end
        end
    end

    -- очистка выполняется ВСЕГДА
    for char, h in pairs(playerEspCache) do
        if not activeP[char] then
            if h then h:Destroy() end
            playerEspCache[char] = nil
        end
    end
    for char, b in pairs(boxCache) do
        if not activeP[char] then
            b.frame:Destroy()
            boxCache[char] = nil
        end
    end
    for char, e in pairs(skelCache) do
        if not activeK[char] then
            for _, l in ipairs(e.lines) do l:Destroy() end
            skelCache[char] = nil
        end
    end
end

local function ClearVisuals()
    for _, h in pairs(playerEspCache) do if h then h:Destroy() end end
    for _, b in pairs(boxCache) do b.frame:Destroy() end
    for _, e in pairs(skelCache) do for _, l in ipairs(e.lines) do l:Destroy() end end
    playerEspCache, boxCache, skelCache = {}, {}, {}
end

-- ===================== ПОДПИСИ В МИРЕ (ЛУТ / ЯЩИКИ / ТРАНСПОРТ) =====================
local function NewPool() return {labels = {}, selected = {}} end

local function PoolEnsure(pool, n)
    for i = #pool.labels + 1, n do
        pool.labels[i] = new("TextLabel", {
            AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.new(0, 240, 0, 14),
            BackgroundTransparency = 1, Font = Enum.Font.GothamBold, TextSize = 12,
            TextStrokeTransparency = 0.3, Visible = false,
        }, overlayFolder)
    end
end

local function PoolHide(pool)
    for i = 1, #pool.labels do pool.labels[i].Visible = false end
    pool.selected = {}
end

local function PoolApply(pool, candidates, cap)
    PoolEnsure(pool, cap)
    table.sort(candidates, function(a, b) return a.d2 < b.d2 end)
    pool.selected = {}
    for i = 1, #pool.labels do
        local c = (i <= cap) and candidates[i] or nil
        local lbl = pool.labels[i]
        if c then
            lbl.Text = c.text
            lbl.TextColor3 = c.color
            lbl.TextSize = c.size
            pool.selected[#pool.selected + 1] = {part = c.part, label = lbl}
        else
            lbl.Visible = false
        end
    end
end

local function PoolMove(pool)
    for i = 1, #pool.selected do
        local s = pool.selected[i]
        if s.part.Parent then
            local pos, onScreen = Camera:WorldToViewportPoint(s.part.Position)
            if onScreen and pos.Z > 0 then
                s.label.Position = UDim2.fromOffset(pos.X, pos.Y)
                s.label.Visible = true
            else
                s.label.Visible = false
            end
        else
            s.label.Visible = false
        end
    end
end

local lootPool, cratePool, vehiclePool = NewPool(), NewPool(), NewPool()

local function GetLootPart(item)
    if item:IsA("BasePart") then return item end
    if item:IsA("Model") then
        return item:FindFirstChild("PickBox")
            or item:FindFirstChild("RootPart")
            or item:FindFirstChild("Root")
            or item:FindFirstChildWhichIsA("BasePart", true)
    end
    return nil
end

local function WorldPart(inst)
    if inst:IsA("BasePart") then return inst end
    if inst:IsA("Model") then
        return inst.PrimaryPart or inst:FindFirstChildWhichIsA("BasePart", true)
    end
    return nil
end

-- свой список лута
local customCacheStr, customCache = nil, {}
local function GetCustomEntries()
    local str = S.Loot.CustomList or ""
    if str ~= customCacheStr then
        customCacheStr = str
        customCache = {}
        for entry in (str .. ","):gmatch("([^,;\n]*)[,;\n]") do
            local e = ruLower(entry):gsub("^%s+", ""):gsub("%s+$", "")
            if e ~= "" then customCache[#customCache + 1] = e end
        end
    end
    return customCache
end

local matchKeyCache = {}
local function MatchesCustom(rawName, entries)
    if #entries == 0 then return false end
    local key = matchKeyCache[rawName]
    if not key then
        key = ruLower(rawName) .. "\0" .. ruLower(Translate(rawName))
        matchKeyCache[rawName] = key
    end
    for _, e in ipairs(entries) do
        if key:find(e, 1, true) then return true end
    end
    return false
end

local function RefreshLoot()
    local L = S.Loot
    if not L.Enabled then PoolHide(lootPool) return end
    local lootFolder = workspace:FindFirstChild("Loot")
    if not lootFolder then PoolHide(lootPool) return end

    local camPos = Camera.CFrame.Position
    local look = Camera.CFrame.LookVector
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    local myPos = hrp and hrp.Position or camPos
    local maxD2 = L.MaxDist * L.MaxDist
    local entries = GetCustomEntries()

    local candidates = {}
    for _, item in ipairs(lootFolder:GetChildren()) do
        if item.Name ~= "LootHighlight" then
            local part = GetLootPart(item)
            if part then
                local pos = part.Position
                local delta = pos - myPos
                local d2 = delta.X * delta.X + delta.Y * delta.Y + delta.Z * delta.Z
                if d2 <= maxD2 and (pos - camPos):Dot(look) > 0 then
                    local custom = MatchesCustom(item.Name, entries)
                    local cat = GetCategory(item)
                    local show = custom or (not L.CustomOnly and L.Categories[cat])
                    if show then
                        local name = L.Russian and Translate(item.Name) or (item.Name:gsub("_", " "))
                        local text = L.ShowDistance and (name .. "  " .. math.floor(math.sqrt(d2)) .. "м") or name
                        candidates[#candidates + 1] = {
                            part = part, d2 = d2, text = text,
                            color = custom and L.CustomColor or L.Colors[cat],
                            size = (custom and L.CustomBig) and (L.TextSize + 3) or L.TextSize,
                        }
                    end
                end
            end
        end
    end
    PoolApply(lootPool, candidates, L.MaxLabels)
end

local function CollectItems(folder)
    local out = {}
    for _, c in ipairs(folder:GetChildren()) do
        if c:IsA("Folder") then
            for _, cc in ipairs(c:GetChildren()) do out[#out + 1] = cc end
        else
            out[#out + 1] = c
        end
    end
    return out
end

local function RefreshWorld(pool, folderName, cfg, patterns, fallback)
    if not cfg.Enabled then PoolHide(pool) return end
    local folder = workspace:FindFirstChild(folderName)
    if not folder then PoolHide(pool) return end

    local camPos = Camera.CFrame.Position
    local look = Camera.CFrame.LookVector
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    local myPos = hrp and hrp.Position or camPos
    local maxD2 = cfg.MaxDist * cfg.MaxDist

    local candidates = {}
    for _, item in ipairs(CollectItems(folder)) do
        local part = WorldPart(item)
        if part then
            local pos = part.Position
            local delta = pos - myPos
            local d2 = delta.X * delta.X + delta.Y * delta.Y + delta.Z * delta.Z
            if d2 <= maxD2 and (pos - camPos):Dot(look) > 0 then
                candidates[#candidates + 1] = {
                    part = part, d2 = d2,
                    text = PatternName(patterns, item.Name, fallback) .. "  " .. math.floor(math.sqrt(d2)) .. "м",
                    color = cfg.Color, size = cfg.TextSize,
                }
            end
        end
    end
    PoolApply(pool, candidates, 30)
end

-- ===================== БИНДЫ (ЛОГИКА) =====================
local BindDefs = {
    menu      = {kind = "menu"},
    aim       = {kind = "hold"},
    autoclick = {kind = "hold"},
    players   = {kind = "flag", tbl = S.Players,  key = "Enabled", label = "ESP игроков"},
    skeleton  = {kind = "flag", tbl = S.Skeleton, key = "Enabled", label = "Скелет"},
    loot      = {kind = "flag", tbl = S.Loot,     key = "Enabled", label = "ESP лута"},
    crates    = {kind = "flag", tbl = S.Crates,   key = "Enabled", label = "ESP ящиков"},
    vehicles  = {kind = "flag", tbl = S.Vehicles, key = "Enabled", label = "ESP транспорта"},
}

local function BindActive(id)
    local b, d = S.Binds[id], BindDefs[id]
    if b.Mode == "Always" then return true end
    if b.Mode == "Toggle" then return d.toggled == true end
    return d.down == true
end

local function InputName(input)
    local t = input.UserInputType
    if t == Enum.UserInputType.Keyboard then return input.KeyCode.Name end
    if t == Enum.UserInputType.MouseButton1 or t == Enum.UserInputType.MouseButton2 or t == Enum.UserInputType.MouseButton3 then
        return t.Name
    end
    return nil
end

local function OnBindPress(name)
    for id, d in pairs(BindDefs) do
        local b = S.Binds[id]
        if b.Input == name then
            if d.kind == "menu" then
                ToggleMenu()
            elseif d.kind == "flag" then
                if b.Mode == "Toggle" then
                    d.tbl[d.key] = not d.tbl[d.key]
                    RefreshUI()
                    Notify(d.label .. (d.tbl[d.key] and ": включено" or ": выключено"))
                elseif b.Mode == "Hold" then
                    d.tbl[d.key] = true
                    RefreshUI()
                end
            else
                d.down = true
                if b.Mode == "Toggle" then d.toggled = not d.toggled end
            end
        end
    end
end

local function OnBindRelease(name)
    for id, d in pairs(BindDefs) do
        local b = S.Binds[id]
        if b.Input == name then
            if d.kind == "flag" then
                if b.Mode == "Hold" then d.tbl[d.key] = false RefreshUI() end
            elseif d.kind == "hold" then
                d.down = false
            end
        end
    end
end

-- ===================== АИМБОТ =====================
local fovCircle = new("Frame", {
    AnchorPoint = Vector2.new(0.5, 0.5), BackgroundTransparency = 1, BorderSizePixel = 0, Visible = false,
}, overlayFolder)
corner(fovCircle, 1000)
local fovStroke = stroke(fovCircle, Color3.new(1, 1, 1), 1.5, 0.2)

local rayParams = RaycastParams.new()
rayParams.FilterType = Enum.RaycastFilterType.Exclude
rayParams.IgnoreWater = true
pcall(function() rayParams.RespectCanCollide = true end)
local IGNORE_FOLDERS = {"Loot", "FX", "ZoneFX", "FootstepFX", "Projectiles", "DeployFX", "GlassShards", "AudioEmitters", "Lobby"}

local function IsVisible(targetPart, targetChar)
    local ignore = {Camera, targetChar}
    if LocalPlayer.Character then ignore[#ignore + 1] = LocalPlayer.Character end
    for _, n in ipairs(IGNORE_FOLDERS) do
        local f = workspace:FindFirstChild(n)
        if f then ignore[#ignore + 1] = f end
    end
    rayParams.FilterDescendantsInstances = ignore
    local origin = Camera.CFrame.Position
    return workspace:Raycast(origin, targetPart.Position - origin, rayParams) == nil
end

local function AimCenter()
    if UserInputService.MouseBehavior == Enum.MouseBehavior.LockCenter then
        return Camera.ViewportSize / 2
    end
    return UserInputService:GetMouseLocation()
end

local AIM_PARTS = {"Head", "UpperTorso", "Torso", "HumanoidRootPart", "LowerTorso", "LeftFoot", "RightFoot", "LeftHand", "RightHand"}
local function GetAimPart(char, mode, center)
    local head = char:FindFirstChild("Head")
    local torso = char:FindFirstChild("UpperTorso") or char:FindFirstChild("Torso") or char:FindFirstChild("HumanoidRootPart")
    if mode == "Head" then return head or torso end
    if mode == "Torso" then return torso or head end
    local best, bestD
    for _, n in ipairs(AIM_PARTS) do
        local part = char:FindFirstChild(n)
        if part then
            local sp = Camera:WorldToViewportPoint(part.Position)
            if sp.Z > 0 then
                local d = (Vector2.new(sp.X, sp.Y) - center).Magnitude
                if not bestD or d < bestD then best, bestD = part, d end
            end
        end
    end
    return best or head or torso
end

local aimTarget
local function AimStep(dt)
    local A = S.Aim
    local center = AimCenter()

    fovCircle.Visible = A.Enabled and A.ShowFOV
    if fovCircle.Visible then
        fovCircle.Position = UDim2.fromOffset(center.X, center.Y)
        fovCircle.Size = UDim2.fromOffset(A.FOV * 2, A.FOV * 2)
        fovStroke.Color = A.FOVColor
    end

    if not A.Enabled or not BindActive("aim") then aimTarget = nil return end

    local origin = Camera.CFrame.Position
    local cands = {}
    for _, data in ipairs(Targets) do
        if (data.isBot and A.Bots) or (not data.isBot and A.Players) then
            local hum, root = AliveInfo(data.char)
            if hum and (root.Position - origin).Magnitude <= A.MaxDist then
                local part = GetAimPart(data.char, A.Part, center)
                if part then
                    local pos = part.Position
                    if A.Prediction > 0 then
                        pos = pos + root.AssemblyLinearVelocity * (A.Prediction / 1000)
                    end
                    local sp = Camera:WorldToViewportPoint(pos)
                    if sp.Z > 0 then
                        local v2 = Vector2.new(sp.X, sp.Y)
                        local d = (v2 - center).Magnitude
                        if d <= A.FOV then
                            cands[#cands + 1] = {char = data.char, part = part, pos = pos, sp = v2, d = d}
                        end
                    end
                end
            end
        end
    end
    table.sort(cands, function(a, b) return a.d < b.d end)

    -- липкая цель идёт первой
    if A.Sticky and aimTarget then
        for i, c in ipairs(cands) do
            if c.char == aimTarget then
                table.remove(cands, i)
                table.insert(cands, 1, c)
                break
            end
        end
    end

    local chosen
    local checks = 0
    for _, c in ipairs(cands) do
        if not A.VisCheck or IsVisible(c.part, c.char) then chosen = c break end
        checks = checks + 1
        if checks >= 5 then break end
    end
    if not chosen then aimTarget = nil return end
    aimTarget = chosen.char

    local alpha = math.clamp(A.Speed / 100, 0.02, 1)
    alpha = 1 - (1 - alpha) ^ (math.clamp(dt, 0, 0.1) * 60)

    if A.Method == "Mouse" and mousemoverel then
        pcall(mousemoverel, (chosen.sp.X - center.X) * alpha, (chosen.sp.Y - center.Y) * alpha)
    else
        local cf = Camera.CFrame
        Camera.CFrame = cf:Lerp(CFrame.lookAt(cf.Position, chosen.pos), alpha)
    end
end

-- ===================== МАКРОСЫ МЫШИ =====================
local function DoClick()
    if mouse1click then
        pcall(mouse1click)
        return
    end
    local ok, vim = pcall(function() return game:GetService("VirtualInputManager") end)
    if ok and vim then
        local loc = UserInputService:GetMouseLocation()
        pcall(function()
            vim:SendMouseButtonEvent(loc.X, loc.Y, 0, true, game, 0)
            vim:SendMouseButtonEvent(loc.X, loc.Y, 0, false, game, 0)
        end)
    end
end

local clickAcc, recoilRem = 0, 0
local function MacroStep(dt)
    local M = S.Macro
    if not M.Enabled then clickAcc, recoilRem = 0, 0 return end

    if M.AutoClick and BindActive("autoclick") then
        clickAcc = clickAcc + dt
        local interval = 1 / math.max(M.CPS, 1)
        local n = 0
        while clickAcc >= interval and n < 3 do
            clickAcc = clickAcc - interval
            n = n + 1
            DoClick()
        end
        if clickAcc > interval then clickAcc = 0 end
    else
        clickAcc = 0
    end

    if M.Recoil and mousemoverel and UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) then
        recoilRem = recoilRem + M.RecoilStrength * dt * 60
        local step = math.floor(recoilRem)
        if step >= 1 then
            recoilRem = recoilRem - step
            pcall(mousemoverel, 0, step)
        end
    else
        recoilRem = 0
    end
end

-- ===================== GUI: ОСНОВА =====================
local Accent = {binders = {}}
local Refreshers = {}
local Registry = {}
local CurrentTab, CurrentFeature

local function BindAccent(fn)
    fn()
    Accent.binders[#Accent.binders + 1] = fn
end
local function SetAccent(c)
    S.Accent = c
    for _, fn in ipairs(Accent.binders) do pcall(fn) end
end
RefreshUI = function()
    for _, fn in ipairs(Refreshers) do pcall(fn) end
end

local main = new("Frame", {
    Name = "Main", BackgroundColor3 = Color3.new(1, 1, 1), BackgroundTransparency = 0.03, BorderSizePixel = 0,
    Active = true, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0.5, 0),
    Size = UDim2.new(0, 800, 0, 540), ClipsDescendants = false,
}, screenGui)
corner(main, 14)
local mainScale = new("UIScale", {Scale = 1}, main)
local mainStroke = stroke(main, S.Accent, 1.5, 0.3)
BindAccent(function() mainStroke.Color = S.Accent end)
new("UIGradient", {
    Rotation = 90,
    Color = ColorSequence.new(Color3.fromRGB(30, 20, 40), Color3.fromRGB(13, 11, 20)),
}, main)

local function UpdateBlur() blur.Enabled = main.Visible and S.Blur end
local function SetMenuVisible(v)
    if v and not main.Visible then
        main.Visible = true
        mainScale.Scale = 0.94
        tween(mainScale, {Scale = 1}, 0.2)
    elseif not v then
        main.Visible = false
    end
    UpdateBlur()
end
ToggleMenu = function() SetMenuVisible(not main.Visible) end

local function MakeDraggable(handle)
    local dragging, dragStart, startPos
    handle.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = i.Position
            startPos = main.Position
        end
    end)
    Connect(UserInputService.InputChanged, function(i)
        if dragging and i.UserInputType == Enum.UserInputType.MouseMovement then
            local d = i.Position - dragStart
            main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
        end
    end)
    Connect(UserInputService.InputEnded, function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
    end)
end

-- общий drag для ползунков / выбора цвета
local activeDrag
Connect(UserInputService.InputChanged, function(i)
    if activeDrag and i.UserInputType == Enum.UserInputType.MouseMovement then
        activeDrag(UserInputService:GetMouseLocation())
    end
end)
Connect(UserInputService.InputEnded, function(i)
    if activeDrag and i.UserInputType == Enum.UserInputType.MouseButton1 then activeDrag = nil end
end)

-- ---------- боковая панель ----------
local sidebar = new("Frame", {BackgroundColor3 = T.side, BorderSizePixel = 0, Size = UDim2.new(0, 200, 1, 0)}, main)
corner(sidebar, 14)
new("Frame", {BackgroundColor3 = T.side, BorderSizePixel = 0, Position = UDim2.new(1, -16, 0, 0), Size = UDim2.new(0, 16, 1, 0)}, sidebar)
new("Frame", {BackgroundColor3 = T.line, BorderSizePixel = 0, Position = UDim2.new(1, 0, 0, 0), Size = UDim2.new(0, 1, 1, 0)}, sidebar)

local logoArea = new("Frame", {BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 68), Active = true}, sidebar)
local badge = new("Frame", {BorderSizePixel = 0, Position = UDim2.new(0, 16, 0, 16), Size = UDim2.new(0, 36, 0, 36)}, logoArea)
corner(badge, 11)
BindAccent(function() badge.BackgroundColor3 = S.Accent end)
new("TextLabel", {
    BackgroundTransparency = 1, Size = UDim2.new(1, 0, 1, 0), Font = Enum.Font.GothamBlack,
    Text = "H", TextColor3 = Color3.new(1, 1, 1), TextSize = 20,
}, badge)
new("TextLabel", {
    BackgroundTransparency = 1, Position = UDim2.new(0, 62, 0, 14), Size = UDim2.new(1, -70, 0, 20),
    Font = Enum.Font.GothamBlack, Text = "HEKZ", TextColor3 = T.text, TextSize = 17, TextXAlignment = Enum.TextXAlignment.Left,
}, logoArea)
new("TextLabel", {
    BackgroundTransparency = 1, Position = UDim2.new(0, 62, 0, 34), Size = UDim2.new(1, -70, 0, 16),
    Font = Enum.Font.Gotham, Text = "Dropzone  ·  v5.0", TextColor3 = T.dim, TextSize = 11, TextXAlignment = Enum.TextXAlignment.Left,
}, logoArea)
MakeDraggable(logoArea)

local navList = new("Frame", {BackgroundTransparency = 1, Position = UDim2.new(0, 0, 0, 74), Size = UDim2.new(1, 0, 1, -150)}, sidebar)
new("UIListLayout", {Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder}, navList)
new("UIPadding", {PaddingLeft = UDim.new(0, 12), PaddingRight = UDim.new(0, 12)}, navList)

-- карточка пользователя
local userCard = new("Frame", {
    BackgroundColor3 = T.card, BorderSizePixel = 0, AnchorPoint = Vector2.new(0, 1),
    Position = UDim2.new(0, 12, 1, -12), Size = UDim2.new(1, -24, 0, 54),
}, sidebar)
corner(userCard, 12)
stroke(userCard, T.line, 1, 0.3)
local userAvatar = new("ImageLabel", {
    BackgroundColor3 = T.row, BorderSizePixel = 0, Position = UDim2.new(0, 10, 0.5, -17), Size = UDim2.new(0, 34, 0, 34),
    Image = "rbxthumb://type=AvatarHeadShot&id=" .. LocalPlayer.UserId .. "&w=150&h=150",
}, userCard)
corner(userAvatar, 17)
new("TextLabel", {
    BackgroundTransparency = 1, Position = UDim2.new(0, 52, 0, 10), Size = UDim2.new(1, -58, 0, 16),
    Font = Enum.Font.GothamBold, Text = LocalPlayer.DisplayName, TextColor3 = T.text, TextSize = 12,
    TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd,
}, userCard)
local statusDot = new("Frame", {BackgroundColor3 = Color3.fromRGB(80, 230, 130), BorderSizePixel = 0, Position = UDim2.new(0, 52, 0, 33), Size = UDim2.new(0, 7, 0, 7)}, userCard)
corner(statusDot, 4)
new("TextLabel", {
    BackgroundTransparency = 1, Position = UDim2.new(0, 64, 0, 28), Size = UDim2.new(1, -70, 0, 16),
    Font = Enum.Font.Gotham, Text = "Активен", TextColor3 = T.dim, TextSize = 11, TextXAlignment = Enum.TextXAlignment.Left,
}, userCard)

-- ---------- правая часть ----------
local content = new("Frame", {BackgroundTransparency = 1, Position = UDim2.new(0, 200, 0, 0), Size = UDim2.new(1, -200, 1, 0)}, main)

local headerArea = new("Frame", {BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 64), Active = true}, content)
MakeDraggable(headerArea)
local headerTitle = new("TextLabel", {
    BackgroundTransparency = 1, Position = UDim2.new(0, 24, 0, 12), Size = UDim2.new(0.5, 0, 0, 26),
    Font = Enum.Font.GothamBold, Text = "", TextColor3 = T.text, TextSize = 20, TextXAlignment = Enum.TextXAlignment.Left,
}, headerArea)
local headerSub = new("TextLabel", {
    BackgroundTransparency = 1, Position = UDim2.new(0, 24, 0, 38), Size = UDim2.new(0.5, 0, 0, 16),
    Font = Enum.Font.Gotham, Text = "", TextColor3 = T.dim, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left,
}, headerArea)

local closeBtn = new("TextButton", {
    Text = "×", AutoButtonColor = false, BackgroundColor3 = T.card, BorderSizePixel = 0,
    AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -16, 0, 32), Size = UDim2.new(0, 30, 0, 30),
    Font = Enum.Font.GothamBold, TextSize = 20, TextColor3 = T.dim,
}, headerArea)
corner(closeBtn, 9)
closeBtn.MouseEnter:Connect(function() tween(closeBtn, {BackgroundColor3 = Color3.fromRGB(200, 60, 70), TextColor3 = Color3.new(1, 1, 1)}) end)
closeBtn.MouseLeave:Connect(function() tween(closeBtn, {BackgroundColor3 = T.card, TextColor3 = T.dim}) end)
closeBtn.MouseButton1Click:Connect(function() SetMenuVisible(false) end)

local searchFrame = new("Frame", {
    BackgroundColor3 = T.card, BorderSizePixel = 0, AnchorPoint = Vector2.new(1, 0.5),
    Position = UDim2.new(1, -56, 0, 32), Size = UDim2.new(0, 210, 0, 32),
}, headerArea)
corner(searchFrame, 10)
local searchStroke = stroke(searchFrame, T.line, 1, 0.2)
new("TextLabel", {
    BackgroundTransparency = 1, Position = UDim2.new(0, 10, 0, 0), Size = UDim2.new(0, 20, 1, 0),
    Font = Enum.Font.GothamBold, Text = "⌕", TextColor3 = T.dim, TextSize = 16,
}, searchFrame)
local searchBox = new("TextBox", {
    BackgroundTransparency = 1, Position = UDim2.new(0, 32, 0, 0), Size = UDim2.new(1, -40, 1, 0),
    Font = Enum.Font.Gotham, Text = "", PlaceholderText = "Поиск настроек  (Ctrl+K)",
    PlaceholderColor3 = T.dim, TextColor3 = T.text, TextSize = 12, ClearTextOnFocus = false,
    TextXAlignment = Enum.TextXAlignment.Left,
}, searchFrame)
searchBox.Focused:Connect(function() searchStroke.Color = S.Accent end)
searchBox.FocusLost:Connect(function() searchStroke.Color = T.line end)

new("Frame", {BackgroundColor3 = T.line, BorderSizePixel = 0, Position = UDim2.new(0, 0, 0, 64), Size = UDim2.new(1, 0, 0, 1)}, content)

local pageHolder = new("Frame", {
    BackgroundTransparency = 1, ClipsDescendants = true,
    Position = UDim2.new(0, 10, 0, 72), Size = UDim2.new(1, -20, 1, -82),
}, content)

-- ---------- страницы ----------
local pages, tabButtons, TabInfo = {}, {}, {}
local currentTab, lastTab = nil, nil

local function CreatePage(name)
    local page = new("ScrollingFrame", {
        BackgroundTransparency = 1, BorderSizePixel = 0, Size = UDim2.new(1, 0, 1, 0), Visible = false,
        ScrollBarThickness = 3, CanvasSize = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y, ScrollingDirection = Enum.ScrollingDirection.Y,
    }, pageHolder)
    BindAccent(function() page.ScrollBarImageColor3 = S.Accent end)
    new("UIListLayout", {Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder}, page)
    new("UIPadding", {
        PaddingTop = UDim.new(0, 6), PaddingBottom = UDim.new(0, 10),
        PaddingLeft = UDim.new(0, 4), PaddingRight = UDim.new(0, 10),
    }, page)
    pages[name] = page
    return page
end

SelectTab = function(name)
    for n, page in pairs(pages) do page.Visible = (n == name) end
    for n, tb in pairs(tabButtons) do
        local on = (n == name)
        tween(tb.btn, {BackgroundTransparency = on and 0.82 or 1})
        tween(tb.label, {TextColor3 = on and T.text or T.dim})
        tb.stroke.Transparency = on and 0.45 or 1
    end
    local info = TabInfo[name]
    if info then
        headerTitle.Text = info[1]
        headerSub.Text = info[2]
    end
    currentTab = name
    if name ~= "search" then lastTab = name end
end

local tabCount = 0
local function CreateTab(name, icon, title, subtitle)
    tabCount = tabCount + 1
    CurrentTab = name
    TabInfo[name] = {title, subtitle}

    local btn = new("TextButton", {
        Text = "", AutoButtonColor = false, BorderSizePixel = 0, BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 40), LayoutOrder = tabCount,
    }, navList)
    corner(btn, 10)
    BindAccent(function() btn.BackgroundColor3 = S.Accent end)
    local st = stroke(btn, S.Accent, 1, 1)
    BindAccent(function() st.Color = S.Accent end)
    new("TextLabel", {
        BackgroundTransparency = 1, Position = UDim2.new(0, 12, 0, 0), Size = UDim2.new(0, 24, 1, 0),
        Font = Enum.Font.GothamBold, Text = icon, TextSize = 15, TextColor3 = T.text,
    }, btn)
    local label = new("TextLabel", {
        BackgroundTransparency = 1, Position = UDim2.new(0, 44, 0, 0), Size = UDim2.new(1, -50, 1, 0),
        Font = Enum.Font.GothamMedium, Text = name, TextColor3 = T.dim, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left,
    }, btn)
    tabButtons[name] = {btn = btn, label = label, stroke = st}

    local page = CreatePage(name)
    btn.MouseButton1Click:Connect(function()
        searchBox.Text = ""
        SelectTab(name)
    end)
    btn.MouseEnter:Connect(function() if currentTab ~= name then tween(btn, {BackgroundTransparency = 0.92}) end end)
    btn.MouseLeave:Connect(function() if currentTab ~= name then tween(btn, {BackgroundTransparency = 1}) end end)
    return page
end

local pageCount = {}
local rowBg = {}
local function place(page, inst)
    pageCount[page] = (pageCount[page] or 0) + 1
    inst.LayoutOrder = pageCount[page]
    inst.Parent = page
end

-- ---------- переход из поиска ----------
local function Reg(label, row)
    Registry[#Registry + 1] = {
        text = ruLower(label), label = label, tab = CurrentTab, feature = CurrentFeature, row = row,
    }
end

-- ===================== КОМПОНЕНТЫ =====================
local function Section(page, text)
    local l = new("TextLabel", {
        BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 22), Font = Enum.Font.GothamBold,
        Text = string.upper(text), TextColor3 = T.dim, TextSize = 11, TextXAlignment = Enum.TextXAlignment.Left,
    })
    new("UIPadding", {PaddingLeft = UDim.new(0, 4), PaddingTop = UDim.new(0, 6)}, l)
    place(page, l)
end

local function SubHeader(page, text)
    local l = new("TextLabel", {
        BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 20), Font = Enum.Font.Gotham,
        Text = text, TextColor3 = T.dim, TextSize = 11, TextXAlignment = Enum.TextXAlignment.Left, TextWrapped = true,
    })
    new("UIPadding", {PaddingLeft = UDim.new(0, 4), PaddingTop = UDim.new(0, 4)}, l)
    place(page, l)
end

local function MakeRow(page, height)
    local row = new("Frame", {BackgroundColor3 = rowBg[page] or T.card, BorderSizePixel = 0, Size = UDim2.new(1, 0, 0, height or 34)})
    corner(row, 8)
    place(page, row)
    return row
end

local function RowLabel(row, text, size)
    Reg(text, row)
    return new("TextLabel", {
        BackgroundTransparency = 1, Position = UDim2.new(0, 12, 0, 0), Size = size or UDim2.new(1, -110, 1, 0),
        Font = Enum.Font.Gotham, Text = text, TextColor3 = T.text, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left,
    }, row)
end

local function MakeSwatch(parent, ctbl, ckey, position, size, onChange)
    local sw = new("TextButton", {
        Text = "", AutoButtonColor = false, BorderSizePixel = 0,
        Position = position, Size = size or UDim2.new(0, 18, 0, 18),
    }, parent)
    corner(sw, 6)
    stroke(sw, Color3.new(1, 1, 1), 1, 0.6)
    local function render() sw.BackgroundColor3 = ctbl[ckey] end
    sw.MouseButton1Click:Connect(function()
        OpenPicker(ctbl[ckey], function(c)
            ctbl[ckey] = c
            render()
            if onChange then onChange(c) end
        end)
    end)
    Refreshers[#Refreshers + 1] = render
    render()
    return sw
end

local function MakeSwitch(parent, tbl, key, onChange)
    local track = new("TextButton", {
        Text = "", AutoButtonColor = false, BorderSizePixel = 0, BackgroundColor3 = T.off,
        Position = UDim2.new(1, -50, 0.5, -10), Size = UDim2.new(0, 38, 0, 20),
    }, parent)
    corner(track, 10)
    local knob = new("Frame", {
        BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0,
        Position = UDim2.new(0, 3, 0.5, -7), Size = UDim2.new(0, 14, 0, 14),
    }, track)
    corner(knob, 7)

    local function render(animate)
        local on = tbl[key]
        local pos = on and UDim2.new(1, -17, 0.5, -7) or UDim2.new(0, 3, 0.5, -7)
        local col = on and S.Accent or T.off
        if animate then
            tween(knob, {Position = pos})
            tween(track, {BackgroundColor3 = col})
        else
            knob.Position = pos
            track.BackgroundColor3 = col
        end
    end
    track.MouseButton1Click:Connect(function()
        tbl[key] = not tbl[key]
        render(true)
        if onChange then onChange(tbl[key]) end
    end)
    local function refresh() render(false) end
    Refreshers[#Refreshers + 1] = refresh
    Accent.binders[#Accent.binders + 1] = refresh
    refresh()
    return track
end

-- colors = { {таблица, ключ}, ... } — слева направо
local function Toggle(page, text, tbl, key, colors, onChange)
    local row = MakeRow(page, 36)
    local n = colors and #colors or 0
    RowLabel(row, text, UDim2.new(1, -(70 + n * 28), 1, 0))
    MakeSwitch(row, tbl, key, onChange)
    for i = 1, n do
        local x = -(80 + (n - i) * 28)
        MakeSwatch(row, colors[i][1], colors[i][2], UDim2.new(1, x, 0.5, -9))
    end
    return row
end

local function Slider(page, text, tbl, key, min, max, step, suffix)
    suffix = suffix or ""
    local row = MakeRow(page, 50)
    RowLabel(row, text, UDim2.new(0.6, 0, 0, 30))
    local valLbl = new("TextLabel", {
        BackgroundTransparency = 1, Position = UDim2.new(0.5, 0, 0, 0), Size = UDim2.new(0.5, -12, 0, 30),
        Font = Enum.Font.GothamBold, TextSize = 12, TextColor3 = T.dim, TextXAlignment = Enum.TextXAlignment.Right,
    }, row)
    local hit = new("TextButton", {
        Text = "", AutoButtonColor = false, BackgroundTransparency = 1,
        Position = UDim2.new(0, 12, 0, 30), Size = UDim2.new(1, -24, 0, 16),
    }, row)
    local track = new("Frame", {
        BackgroundColor3 = T.off, BorderSizePixel = 0, Position = UDim2.new(0, 0, 0.5, -3), Size = UDim2.new(1, 0, 0, 6),
    }, hit)
    corner(track, 3)
    local fill = new("Frame", {BorderSizePixel = 0, Size = UDim2.new(0, 0, 1, 0)}, track)
    corner(fill, 3)
    local knob = new("Frame", {
        BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0,
        Position = UDim2.new(0, -6, 0.5, -6), Size = UDim2.new(0, 12, 0, 12),
    }, track)
    corner(knob, 6)

    local function render()
        local rel = math.clamp((tbl[key] - min) / (max - min), 0, 1)
        fill.Size = UDim2.new(rel, 0, 1, 0)
        fill.BackgroundColor3 = S.Accent
        knob.Position = UDim2.new(rel, -6, 0.5, -6)
        valLbl.Text = tostring(tbl[key]) .. suffix
    end
    local function apply(pos)
        local rel = math.clamp((pos.X - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
        local v = min + rel * (max - min)
        tbl[key] = math.clamp(math.floor(v / step + 0.5) * step, min, max)
        render()
    end
    hit.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then
            activeDrag = apply
            apply(UserInputService:GetMouseLocation())
        end
    end)
    Refreshers[#Refreshers + 1] = render
    Accent.binders[#Accent.binders + 1] = render
    render()
    return row
end

local function ColorRow(page, text, ctbl, ckey, onChange)
    local row = MakeRow(page, 36)
    RowLabel(row, text, UDim2.new(1, -130, 1, 0))
    local hex = new("TextLabel", {
        BackgroundTransparency = 1, Position = UDim2.new(1, -124, 0, 0), Size = UDim2.new(0, 64, 1, 0),
        Font = Enum.Font.GothamMedium, TextSize = 11, TextColor3 = T.dim, TextXAlignment = Enum.TextXAlignment.Right,
    }, row)
    local function renderHex()
        local c = ctbl[ckey]
        hex.Text = string.format("#%02X%02X%02X", math.floor(c.R * 255 + 0.5), math.floor(c.G * 255 + 0.5), math.floor(c.B * 255 + 0.5))
    end
    MakeSwatch(row, ctbl, ckey, UDim2.new(1, -50, 0.5, -10), UDim2.new(0, 38, 0, 20), function(c)
        renderHex()
        if onChange then onChange(c) end
    end)
    Refreshers[#Refreshers + 1] = renderHex
    renderHex()
    return row
end

local function Choice(page, text, tbl, key, options)
    local row = MakeRow(page, 36)
    RowLabel(row, text, UDim2.new(1, -190, 1, 0))
    local btn = new("TextButton", {
        AutoButtonColor = false, BackgroundColor3 = T.off, BorderSizePixel = 0,
        Position = UDim2.new(1, -178, 0.5, -12), Size = UDim2.new(0, 166, 0, 24),
        Font = Enum.Font.GothamBold, TextSize = 11, TextColor3 = T.text,
    }, row)
    corner(btn, 7)
    local function render()
        for _, o in ipairs(options) do
            if o[1] == tbl[key] then btn.Text = o[2] end
        end
    end
    btn.MouseButton1Click:Connect(function()
        local idx = 1
        for i, o in ipairs(options) do if o[1] == tbl[key] then idx = i end end
        tbl[key] = options[idx % #options + 1][1]
        render()
    end)
    btn.MouseEnter:Connect(function() tween(btn, {BackgroundColor3 = T.cardHover}) end)
    btn.MouseLeave:Connect(function() tween(btn, {BackgroundColor3 = T.off}) end)
    Refreshers[#Refreshers + 1] = render
    render()
    return row
end

local function TextInput(page, text, tbl, key, placeholder)
    local row = MakeRow(page, 64)
    RowLabel(row, text, UDim2.new(1, -24, 0, 30))
    local box = new("TextBox", {
        BackgroundColor3 = T.off, BorderSizePixel = 0, Position = UDim2.new(0, 12, 0, 32), Size = UDim2.new(1, -24, 0, 26),
        Font = Enum.Font.Gotham, TextSize = 12, TextColor3 = T.text, PlaceholderText = placeholder or "",
        PlaceholderColor3 = T.dim, ClearTextOnFocus = false, Text = "", TextXAlignment = Enum.TextXAlignment.Left,
    }, row)
    corner(box, 7)
    new("UIPadding", {PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10)}, box)
    box.FocusLost:Connect(function() tbl[key] = box.Text end)
    Refreshers[#Refreshers + 1] = function() box.Text = tbl[key] end
    box.Text = tbl[key]
    return row
end

-- бинды: клавиша / кнопка мыши + режим
local captureCallback
local function DisplayInput(name)
    if not name or name == "None" then return "—" end
    if name == "MouseButton1" then return "ЛКМ" end
    if name == "MouseButton2" then return "ПКМ" end
    if name == "MouseButton3" then return "СКМ" end
    return name
end
local ModeNames = {Hold = "Удержание", Toggle = "Переключение", Always = "Всегда"}
local ModeOrder = {"Hold", "Toggle", "Always"}

local function BindRow(page, id, text, noMode)
    local row = MakeRow(page, 36)
    RowLabel(row, text, UDim2.new(1, noMode and -130 or -260, 1, 0))
    local keyBtn = new("TextButton", {
        AutoButtonColor = false, BackgroundColor3 = T.off, BorderSizePixel = 0,
        Position = UDim2.new(1, noMode and -112 or -252, 0.5, -12), Size = UDim2.new(0, 100, 0, 24),
        Font = Enum.Font.GothamBold, TextSize = 11, TextColor3 = T.text,
    }, row)
    corner(keyBtn, 7)
    local modeBtn
    if not noMode then
        modeBtn = new("TextButton", {
            AutoButtonColor = false, BackgroundColor3 = T.off, BorderSizePixel = 0,
            Position = UDim2.new(1, -140, 0.5, -12), Size = UDim2.new(0, 128, 0, 24),
            Font = Enum.Font.GothamMedium, TextSize = 11, TextColor3 = T.dim,
        }, row)
        corner(modeBtn, 7)
        modeBtn.MouseButton1Click:Connect(function()
            local b = S.Binds[id]
            local idx = 1
            for i, m in ipairs(ModeOrder) do if m == b.Mode then idx = i end end
            b.Mode = ModeOrder[idx % #ModeOrder + 1]
            BindDefs[id].toggled = false
            RefreshUI()
        end)
    end
    local function render()
        keyBtn.Text = DisplayInput(S.Binds[id].Input)
        if modeBtn then modeBtn.Text = ModeNames[S.Binds[id].Mode] or S.Binds[id].Mode end
    end
    keyBtn.MouseButton1Click:Connect(function()
        keyBtn.Text = "нажми..."
        captureCallback = function(name)
            if name == "Backspace" or name == "Delete" then
                S.Binds[id].Input = "None"
            elseif name ~= "Escape" then
                S.Binds[id].Input = name
            end
            BindDefs[id].down, BindDefs[id].toggled = false, false
            RefreshUI()
        end
    end)
    keyBtn.MouseEnter:Connect(function() tween(keyBtn, {BackgroundColor3 = T.cardHover}) end)
    keyBtn.MouseLeave:Connect(function() tween(keyBtn, {BackgroundColor3 = T.off}) end)
    Refreshers[#Refreshers + 1] = render
    render()
    return row
end

local function Button(page, text, callback, danger)
    local base = danger and Color3.fromRGB(70, 28, 38) or T.card
    local hover = danger and Color3.fromRGB(104, 36, 50) or T.cardHover
    local btn = new("TextButton", {
        Text = text, AutoButtonColor = false, BackgroundColor3 = base, BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 36), Font = Enum.Font.GothamMedium, TextSize = 13,
        TextColor3 = danger and Color3.fromRGB(255, 140, 156) or T.text,
    })
    corner(btn, 8)
    place(page, btn)
    Reg(text, btn)
    btn.MouseEnter:Connect(function() tween(btn, {BackgroundColor3 = hover}) end)
    btn.MouseLeave:Connect(function() tween(btn, {BackgroundColor3 = base}) end)
    btn.MouseButton1Click:Connect(callback)
    return btn
end

-- карточка функции со стрелкой
local function Feature(page, titleText, descText, tbl, key, build)
    local ctrl = {title = titleText}
    local card = new("Frame", {
        BackgroundColor3 = T.card, BorderSizePixel = 0, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
    })
    corner(card, 12)
    stroke(card, T.line, 1, 0.3)
    place(page, card)
    new("UIListLayout", {SortOrder = Enum.SortOrder.LayoutOrder}, card)

    local header = new("TextButton", {
        Text = "", AutoButtonColor = false, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 56), LayoutOrder = 1,
    }, card)
    new("TextLabel", {
        BackgroundTransparency = 1, Position = UDim2.new(0, 16, 0, 10), Size = UDim2.new(1, -150, 0, 18),
        Font = Enum.Font.GothamBold, Text = titleText, TextColor3 = T.text, TextSize = 14, TextXAlignment = Enum.TextXAlignment.Left,
    }, header)
    new("TextLabel", {
        BackgroundTransparency = 1, Position = UDim2.new(0, 16, 0, 30), Size = UDim2.new(1, -150, 0, 16),
        Font = Enum.Font.Gotham, Text = descText, TextColor3 = T.dim, TextSize = 11, TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
    }, header)

    local sw = MakeSwitch(header, tbl, key)
    sw.Position = UDim2.new(1, -86, 0.5, -10)

    local arrow = new("TextLabel", {
        Text = "›", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(1, -24, 0.5, -1),
        Size = UDim2.new(0, 24, 0, 24), BackgroundTransparency = 1, Font = Enum.Font.GothamBold,
        TextSize = 26, TextColor3 = T.dim,
    }, header)

    local body = new("Frame", {
        BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
        Visible = false, LayoutOrder = 2,
    }, card)
    new("UIListLayout", {Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder}, body)
    new("UIPadding", {
        PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10),
        PaddingTop = UDim.new(0, 2), PaddingBottom = UDim.new(0, 12),
    }, body)
    rowBg[body] = T.row

    local open = false
    local function setOpen(v)
        open = v
        body.Visible = v
        tween(arrow, {Rotation = v and 90 or 0, TextColor3 = v and S.Accent or T.dim}, 0.18)
    end
    ctrl.open = function() if not open then setOpen(true) end end
    header.MouseButton1Click:Connect(function() setOpen(not open) end)
    header.MouseEnter:Connect(function() if not open then tween(arrow, {TextColor3 = T.text}) end end)
    header.MouseLeave:Connect(function() if not open then tween(arrow, {TextColor3 = T.dim}) end end)

    CurrentFeature = ctrl
    Reg(titleText .. " " .. descText, card)
    build(body)
    CurrentFeature = nil
    return ctrl
end

-- ===================== ВЫБОР ЦВЕТА (КАК В PAINT) =====================
local backdrop = new("TextButton", {
    Text = "", AutoButtonColor = false, BackgroundColor3 = Color3.new(0, 0, 0), BackgroundTransparency = 0.4,
    BorderSizePixel = 0, Size = UDim2.new(1, 0, 1, 0), Visible = false, ZIndex = 19,
}, main)
corner(backdrop, 14)

local picker = new("Frame", {
    BackgroundColor3 = T.card, BorderSizePixel = 0, AnchorPoint = Vector2.new(0.5, 0.5),
    Position = UDim2.new(0.5, 0, 0.5, 0), Size = UDim2.new(0, 270, 0, 326), Visible = false, ZIndex = 20, Active = true,
}, main)
corner(picker, 14)
stroke(picker, T.line, 1)

new("TextLabel", {
    BackgroundTransparency = 1, Position = UDim2.new(0, 14, 0, 8), Size = UDim2.new(1, -28, 0, 22),
    Font = Enum.Font.GothamBold, Text = "Выбор цвета", TextColor3 = T.text, TextSize = 13,
    TextXAlignment = Enum.TextXAlignment.Left,
}, picker)

local svBase = new("Frame", {BorderSizePixel = 0, Position = UDim2.new(0, 14, 0, 36), Size = UDim2.new(0, 242, 0, 140)}, picker)
corner(svBase, 8)
local svWhite = new("Frame", {BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0, Size = UDim2.new(1, 0, 1, 0)}, svBase)
corner(svWhite, 8)
new("UIGradient", {Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(1, 1)})}, svWhite)
local svBlack = new("Frame", {BackgroundColor3 = Color3.new(0, 0, 0), BorderSizePixel = 0, Size = UDim2.new(1, 0, 1, 0)}, svBase)
corner(svBlack, 8)
new("UIGradient", {Rotation = 90, Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(1, 0)})}, svBlack)
local svCursor = new("Frame", {BackgroundTransparency = 1, BorderSizePixel = 0, Size = UDim2.new(0, 10, 0, 10), ZIndex = 4}, svBase)
corner(svCursor, 5)
stroke(svCursor, Color3.new(1, 1, 1), 2)
local svHit = new("TextButton", {Text = "", BackgroundTransparency = 1, Size = UDim2.new(1, 0, 1, 0), ZIndex = 3}, svBase)

local hueBar = new("Frame", {BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0, Position = UDim2.new(0, 14, 0, 186), Size = UDim2.new(0, 242, 0, 14)}, picker)
corner(hueBar, 6)
new("UIGradient", {Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 0, 0)),
    ColorSequenceKeypoint.new(1 / 6, Color3.fromRGB(255, 255, 0)),
    ColorSequenceKeypoint.new(2 / 6, Color3.fromRGB(0, 255, 0)),
    ColorSequenceKeypoint.new(3 / 6, Color3.fromRGB(0, 255, 255)),
    ColorSequenceKeypoint.new(4 / 6, Color3.fromRGB(0, 0, 255)),
    ColorSequenceKeypoint.new(5 / 6, Color3.fromRGB(255, 0, 255)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 0, 0)),
})}, hueBar)
local hueCursor = new("Frame", {BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0, Size = UDim2.new(0, 4, 0, 18), ZIndex = 4}, hueBar)
corner(hueCursor, 2)
stroke(hueCursor, Color3.new(0, 0, 0), 1, 0.3)
local hueHit = new("TextButton", {Text = "", BackgroundTransparency = 1, Size = UDim2.new(1, 0, 1, 0), ZIndex = 3}, hueBar)

local preview = new("Frame", {BorderSizePixel = 0, Position = UDim2.new(0, 14, 0, 210), Size = UDim2.new(0, 24, 0, 26)}, picker)
corner(preview, 6)
stroke(preview, Color3.new(1, 1, 1), 1, 0.6)

local function MakeBox(x, w, placeholder)
    local tb = new("TextBox", {
        BackgroundColor3 = T.off, BorderSizePixel = 0, Position = UDim2.new(0, x, 0, 210), Size = UDim2.new(0, w, 0, 26),
        Font = Enum.Font.GothamMedium, TextSize = 12, TextColor3 = T.text, PlaceholderText = placeholder,
        PlaceholderColor3 = T.dim, ClearTextOnFocus = false, Text = "",
    }, picker)
    corner(tb, 6)
    return tb
end
local hexBox = MakeBox(42, 74, "#RRGGBB")
local rBox = MakeBox(120, 40, "R")
local gBox = MakeBox(164, 40, "G")
local bBox = MakeBox(208, 40, "B")

local ph, ps, pv = 0, 1, 1
local pickerCb

local function PickerUpdate(fire)
    local c = Color3.fromHSV(ph, ps, pv)
    svBase.BackgroundColor3 = Color3.fromHSV(ph, 1, 1)
    svCursor.Position = UDim2.new(ps, -5, 1 - pv, -5)
    hueCursor.Position = UDim2.new(ph, -2, 0, -2)
    preview.BackgroundColor3 = c
    local r, g, b = math.floor(c.R * 255 + 0.5), math.floor(c.G * 255 + 0.5), math.floor(c.B * 255 + 0.5)
    hexBox.Text = string.format("#%02X%02X%02X", r, g, b)
    rBox.Text, gBox.Text, bBox.Text = tostring(r), tostring(g), tostring(b)
    if fire and pickerCb then pickerCb(c) end
end

local function SetPickerColor(c)
    ph, ps, pv = Color3.toHSV(c)
    PickerUpdate(true)
end

svHit.InputBegan:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1 then
        local function apply(pos)
            ps = math.clamp((pos.X - svBase.AbsolutePosition.X) / svBase.AbsoluteSize.X, 0, 1)
            pv = 1 - math.clamp((pos.Y - svBase.AbsolutePosition.Y) / svBase.AbsoluteSize.Y, 0, 1)
            PickerUpdate(true)
        end
        activeDrag = apply
        apply(UserInputService:GetMouseLocation())
    end
end)
hueHit.InputBegan:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1 then
        local function apply(pos)
            ph = math.clamp((pos.X - hueBar.AbsolutePosition.X) / hueBar.AbsoluteSize.X, 0, 0.999)
            PickerUpdate(true)
        end
        activeDrag = apply
        apply(UserInputService:GetMouseLocation())
    end
end)

hexBox.FocusLost:Connect(function()
    local r, g, b = hexBox.Text:match("^#?(%x%x)(%x%x)(%x%x)$")
    if r then
        SetPickerColor(Color3.fromRGB(tonumber(r, 16), tonumber(g, 16), tonumber(b, 16)))
    else
        PickerUpdate(false)
    end
end)
local function RgbFocusLost()
    local r, g, b = tonumber(rBox.Text), tonumber(gBox.Text), tonumber(bBox.Text)
    if r and g and b then
        SetPickerColor(Color3.fromRGB(math.clamp(r, 0, 255), math.clamp(g, 0, 255), math.clamp(b, 0, 255)))
    else
        PickerUpdate(false)
    end
end
rBox.FocusLost:Connect(RgbFocusLost)
gBox.FocusLost:Connect(RgbFocusLost)
bBox.FocusLost:Connect(RgbFocusLost)

for i, c in ipairs(Palette) do
    local b = new("TextButton", {
        Text = "", AutoButtonColor = false, BackgroundColor3 = c, BorderSizePixel = 0,
        Position = UDim2.new(0, 14 + (i - 1) * 27, 0, 246), Size = UDim2.new(0, 22, 0, 22),
    }, picker)
    corner(b, 6)
    b.MouseButton1Click:Connect(function() SetPickerColor(c) end)
end

local function ClosePicker()
    picker.Visible = false
    backdrop.Visible = false
    pickerCb = nil
    activeDrag = nil
end
local doneBtn = new("TextButton", {
    Text = "Готово", AutoButtonColor = false, BorderSizePixel = 0,
    Position = UDim2.new(0, 14, 0, 284), Size = UDim2.new(0, 242, 0, 30),
    Font = Enum.Font.GothamBold, TextSize = 13, TextColor3 = Color3.new(1, 1, 1),
}, picker)
corner(doneBtn, 8)
BindAccent(function() doneBtn.BackgroundColor3 = S.Accent end)
doneBtn.MouseButton1Click:Connect(ClosePicker)
backdrop.MouseButton1Click:Connect(ClosePicker)

OpenPicker = function(color, cb)
    pickerCb = nil
    ph, ps, pv = Color3.toHSV(color)
    PickerUpdate(false)
    backdrop.Visible = true
    picker.Visible = true
    pickerCb = cb
end

-- ===================== ДИАГНОСТИКА (структура объектов) =====================
local function DumpInstance(inst, maxDepth)
    local lines = {}
    local function rec(i, depth)
        if #lines > 300 then return end
        local attrs = ""
        for k, v in pairs(i:GetAttributes()) do attrs = attrs .. " [" .. tostring(k) .. "=" .. tostring(v) .. "]" end
        lines[#lines + 1] = string.rep("  ", depth) .. i.Name .. " <" .. i.ClassName .. ">" .. attrs
        if depth < maxDepth then
            for _, c in ipairs(i:GetChildren()) do rec(c, depth + 1) end
        end
    end
    rec(inst, 0)
    if #lines > 300 then lines[#lines + 1] = "... (обрезано)" end
    return table.concat(lines, "\n")
end

local function OutputDump(label, text)
    print("[HEKZ DUMP] " .. label .. "\n" .. text)
    if setclipboard then
        pcall(setclipboard, text)
        Notify(label .. ": скопировано в буфер и консоль (F9)")
    else
        Notify(label .. ": выведено в консоль (F9)")
    end
end

local function DumpNearestEnemy()
    local origin = Camera.CFrame.Position
    local best, bestD
    for _, data in ipairs(Targets) do
        local _, root = AliveInfo(data.char)
        if root then
            local d = (root.Position - origin).Magnitude
            if not bestD or d < bestD then best, bestD = data, d end
        end
    end
    if not best then Notify("Рядом нет врагов для диагностики") return end
    local text = "=== МОДЕЛЬ ВРАГА (" .. best.name .. ", бот=" .. tostring(best.isBot) .. ") ===\n" .. DumpInstance(best.char, 3)
    local plr = Players:FindFirstChild(best.name)
    if plr then text = text .. "\n\n=== ИГРОК В Players ===\n" .. DumpInstance(plr, 2) end
    OutputDump("Враг", text)
end

local function DumpNearestIn(folderName, label)
    local folder = workspace:FindFirstChild(folderName)
    if not folder then Notify("Папка " .. folderName .. " не найдена") return end
    local origin = Camera.CFrame.Position
    local best, bestD
    for _, item in ipairs(CollectItems(folder)) do
        local part = WorldPart(item)
        if part then
            local d = (part.Position - origin).Magnitude
            if not bestD or d < bestD then best, bestD = item, d end
        end
    end
    if not best then Notify("В " .. folderName .. " ничего нет") return end
    OutputDump(label, "=== " .. label .. " (" .. best.Name .. ", " .. math.floor(bestD) .. "м) ===\n" .. DumpInstance(best, 3))
end

-- ===================== КОНФИГ =====================
local CONFIG_FILE = "hekz_dropzone_v5.json"

local function Encode(v)
    local t = typeof(v)
    if t == "Color3" then return {__c = {v.R, v.G, v.B}} end
    if t == "table" then
        local o = {}
        for k, x in pairs(v) do o[k] = Encode(x) end
        return o
    end
    return v
end

local function Merge(dst, src)
    for k, x in pairs(src) do
        if type(x) == "table" then
            if x.__c then
                dst[k] = Color3.new(x.__c[1], x.__c[2], x.__c[3])
            elseif type(dst[k]) == "table" then
                Merge(dst[k], x)
            end
        elseif dst[k] ~= nil then
            dst[k] = x
        end
    end
end

local function SaveConfig()
    if not writefile then Notify("Экзекутор не поддерживает файлы") return end
    local ok = pcall(function() writefile(CONFIG_FILE, HttpService:JSONEncode(Encode(S))) end)
    Notify(ok and "Настройки сохранены" or "Не удалось сохранить")
end

local function LoadConfig(silent)
    if not (readfile and isfile and isfile(CONFIG_FILE)) then
        if not silent then Notify("Сохранённых настроек нет") end
        return
    end
    local ok = pcall(function() Merge(S, HttpService:JSONDecode(readfile(CONFIG_FILE))) end)
    if ok then
        SetAccent(S.Accent)
        RefreshUI()
        UpdateBlur()
        if not silent then Notify("Настройки загружены") end
    elseif not silent then
        Notify("Не удалось загрузить")
    end
end

-- ===================== СТРАНИЦЫ: ГЛАВНАЯ =====================
local pHome = CreateTab("Главная", "🏠", "Главная", "Обзор твоей сессии")

local function Card(parent, size, position)
    local f = new("Frame", {BackgroundColor3 = T.card, BorderSizePixel = 0, Size = size, Position = position or UDim2.new()}, parent)
    corner(f, 12)
    stroke(f, T.line, 1, 0.3)
    return f
end

local function MakePill(parent, text)
    local p = new("TextLabel", {
        BackgroundColor3 = T.row, BorderSizePixel = 0, Size = UDim2.new(0, 0, 0, 24), AutomaticSize = Enum.AutomaticSize.X,
        Font = Enum.Font.GothamMedium, Text = text, TextColor3 = T.dim, TextSize = 11,
    }, parent)
    corner(p, 12)
    new("UIPadding", {PaddingLeft = UDim.new(0, 11), PaddingRight = UDim.new(0, 11)}, p)
    return p
end

local homeRefs = {}
local sessionStart = os.clock()

-- ряд A: профиль + производительность
local rowA = new("Frame", {BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 134)})
place(pHome, rowA)

local welcome = Card(rowA, UDim2.new(0.56, -5, 1, 0))
local avatar = new("ImageLabel", {
    BackgroundColor3 = T.row, BorderSizePixel = 0, Position = UDim2.new(0, 16, 0, 16), Size = UDim2.new(0, 64, 0, 64),
    Image = "rbxthumb://type=AvatarHeadShot&id=" .. LocalPlayer.UserId .. "&w=150&h=150",
}, welcome)
corner(avatar, 32)
local avatarStroke = stroke(avatar, S.Accent, 2, 0.2)
BindAccent(function() avatarStroke.Color = S.Accent end)
new("TextLabel", {
    BackgroundTransparency = 1, Position = UDim2.new(0, 92, 0, 18), Size = UDim2.new(1, -100, 0, 14),
    Font = Enum.Font.Gotham, Text = "С возвращением,", TextColor3 = T.dim, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left,
}, welcome)
new("TextLabel", {
    BackgroundTransparency = 1, Position = UDim2.new(0, 92, 0, 34), Size = UDim2.new(1, -100, 0, 24),
    Font = Enum.Font.GothamBold, Text = LocalPlayer.DisplayName, TextColor3 = T.text, TextSize = 18,
    TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd,
}, welcome)
homeRefs.session = new("TextLabel", {
    BackgroundTransparency = 1, Position = UDim2.new(0, 92, 0, 60), Size = UDim2.new(1, -100, 0, 16),
    Font = Enum.Font.GothamMedium, Text = "на сервере: 0 мин", TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left,
}, welcome)
BindAccent(function() homeRefs.session.TextColor3 = S.Accent end)

local pillRow = new("Frame", {BackgroundTransparency = 1, Position = UDim2.new(0, 16, 0, 96), Size = UDim2.new(1, -32, 0, 26)}, welcome)
new("UIListLayout", {FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder}, pillRow)
homeRefs.players = MakePill(pillRow, "Игроков 0/0")
homeRefs.ping = MakePill(pillRow, "Пинг 0 мс")
homeRefs.job = MakePill(pillRow, "Job " .. string.sub(game.JobId, 1, 6))

local perf = Card(rowA, UDim2.new(0.44, -5, 1, 0), UDim2.new(0.56, 5, 0, 0))
local ring = new("Frame", {BackgroundTransparency = 1, Position = UDim2.new(0, 14, 0, 20), Size = UDim2.new(0, 94, 0, 94)}, perf)
local TICKS = 40
local ticks = {}
for i = 1, TICKS do
    local ang = (i - 1) / TICKS * math.pi * 2 - math.pi / 2
    local t = new("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5), BorderSizePixel = 0, BackgroundColor3 = T.off,
        Position = UDim2.new(0.5, math.cos(ang) * 39, 0.5, math.sin(ang) * 39),
        Size = UDim2.new(0, 3, 0, 10), Rotation = math.deg(ang) + 90,
    }, ring)
    corner(t, 2)
    ticks[i] = t
end
homeRefs.fps = new("TextLabel", {
    BackgroundTransparency = 1, Position = UDim2.new(0, 0, 0.5, -17), Size = UDim2.new(1, 0, 0, 24),
    Font = Enum.Font.GothamBold, Text = "60", TextColor3 = T.text, TextSize = 22,
}, ring)
new("TextLabel", {
    BackgroundTransparency = 1, Position = UDim2.new(0, 0, 0.5, 6), Size = UDim2.new(1, 0, 0, 12),
    Font = Enum.Font.Gotham, Text = "FPS", TextColor3 = T.dim, TextSize = 10,
}, ring)
new("TextLabel", {
    BackgroundTransparency = 1, Position = UDim2.new(0, 120, 0, 24), Size = UDim2.new(1, -126, 0, 12),
    Font = Enum.Font.GothamBold, Text = "ПРОИЗВОДИТЕЛЬНОСТЬ", TextColor3 = T.dim, TextSize = 9, TextXAlignment = Enum.TextXAlignment.Left,
}, perf)
homeRefs.pingBig = new("TextLabel", {
    BackgroundTransparency = 1, Position = UDim2.new(0, 120, 0, 44), Size = UDim2.new(1, -126, 0, 28),
    Font = Enum.Font.GothamBold, Text = "0 мс", TextColor3 = T.text, TextSize = 22, TextXAlignment = Enum.TextXAlignment.Left,
}, perf)
new("TextLabel", {
    BackgroundTransparency = 1, Position = UDim2.new(0, 120, 0, 74), Size = UDim2.new(1, -126, 0, 14),
    Font = Enum.Font.Gotham, Text = "задержка до сервера", TextColor3 = T.dim, TextSize = 11, TextXAlignment = Enum.TextXAlignment.Left,
}, perf)

-- ряд B: игра
local gameCard = Card(pHome, UDim2.new(1, 0, 0, 84))
place(pHome, gameCard)
local gameIcon = new("ImageLabel", {
    BackgroundColor3 = T.row, BorderSizePixel = 0, Position = UDim2.new(0, 14, 0, 12), Size = UDim2.new(0, 60, 0, 60),
    Image = "rbxthumb://type=GameIcon&id=" .. game.GameId .. "&w=150&h=150",
}, gameCard)
corner(gameIcon, 12)
homeRefs.gameName = new("TextLabel", {
    BackgroundTransparency = 1, Position = UDim2.new(0, 88, 0, 14), Size = UDim2.new(1, -100, 0, 22),
    Font = Enum.Font.GothamBold, Text = "Dropzone", TextColor3 = T.text, TextSize = 16,
    TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd,
}, gameCard)
local gamePills = new("Frame", {BackgroundTransparency = 1, Position = UDim2.new(0, 88, 0, 44), Size = UDim2.new(1, -100, 0, 26)}, gameCard)
new("UIListLayout", {FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder}, gamePills)
homeRefs.gPlayers = MakePill(gamePills, "0 / 0")
homeRefs.gPing = MakePill(gamePills, "0 мс")
MakePill(gamePills, "PlaceId " .. game.PlaceId)

task.spawn(function()
    local ok, info = pcall(function() return MarketplaceService:GetProductInfo(game.PlaceId) end)
    if ok and info and info.Name then homeRefs.gameName.Text = info.Name end
end)

-- ряд C: быстрые действия
local actions = new("Frame", {BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 58)})
place(pHome, actions)
new("UIListLayout", {FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder}, actions)

local function QuickAction(order, title, sub, callback)
    local b = new("TextButton", {
        Text = "", AutoButtonColor = false, BackgroundColor3 = T.card, BorderSizePixel = 0,
        Size = UDim2.new(1 / 3, -6, 1, 0), LayoutOrder = order,
    }, actions)
    corner(b, 12)
    stroke(b, T.line, 1, 0.3)
    new("TextLabel", {
        BackgroundTransparency = 1, Position = UDim2.new(0, 14, 0, 11), Size = UDim2.new(1, -20, 0, 18),
        Font = Enum.Font.GothamBold, Text = title, TextColor3 = T.text, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left,
    }, b)
    new("TextLabel", {
        BackgroundTransparency = 1, Position = UDim2.new(0, 14, 0, 31), Size = UDim2.new(1, -20, 0, 14),
        Font = Enum.Font.Gotham, Text = sub, TextColor3 = T.dim, TextSize = 11, TextXAlignment = Enum.TextXAlignment.Left,
    }, b)
    b.MouseEnter:Connect(function() tween(b, {BackgroundColor3 = T.cardHover}) end)
    b.MouseLeave:Connect(function() tween(b, {BackgroundColor3 = T.card}) end)
    b.MouseButton1Click:Connect(callback)
end

QuickAction(1, "Перезайти", "на этот же сервер", function()
    Notify("Перезаход...")
    pcall(function() TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer) end)
end)
QuickAction(2, "Другой сервер", "найти свободный", function()
    Notify("Ищу другой сервер...")
    task.spawn(function()
        local ok, res = pcall(function()
            local body = game:HttpGet("https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Asc&limit=100")
            return HttpService:JSONDecode(body)
        end)
        if not ok or type(res) ~= "table" or not res.data then Notify("Не удалось получить список серверов") return end
        local list = {}
        for _, sv in ipairs(res.data) do
            if sv.id ~= game.JobId and sv.playing and sv.maxPlayers and sv.playing < sv.maxPlayers - 1 then
                list[#list + 1] = sv
            end
        end
        if #list == 0 then Notify("Свободных серверов не нашлось") return end
        local pick = list[math.random(#list)]
        pcall(function() TeleportService:TeleportToPlaceInstance(game.PlaceId, pick.id, LocalPlayer) end)
    end)
end)
QuickAction(3, "Скопировать Job ID", "поделиться сервером", function()
    if setclipboard then
        pcall(setclipboard, game.JobId)
        Notify("Job ID скопирован")
    else
        Notify("Буфер обмена недоступен в экзекуторе")
    end
end)

-- ряд D: активные функции
local chipsCard = new("Frame", {
    BackgroundColor3 = T.card, BorderSizePixel = 0, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
})
corner(chipsCard, 12)
stroke(chipsCard, T.line, 1, 0.3)
place(pHome, chipsCard)
new("UIListLayout", {Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder}, chipsCard)
new("UIPadding", {PaddingLeft = UDim.new(0, 14), PaddingRight = UDim.new(0, 14), PaddingTop = UDim.new(0, 12), PaddingBottom = UDim.new(0, 14)}, chipsCard)
new("TextLabel", {
    BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 14), LayoutOrder = 1,
    Font = Enum.Font.GothamBold, Text = "АКТИВНО СЕЙЧАС   ·   нажми, чтобы включить или выключить", TextColor3 = T.dim,
    TextSize = 10, TextXAlignment = Enum.TextXAlignment.Left,
}, chipsCard)
local chipHolder = new("Frame", {
    BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, LayoutOrder = 2,
}, chipsCard)
new("UIListLayout", {FillDirection = Enum.FillDirection.Horizontal, Wraps = true, Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder}, chipHolder)

local function Chip(order, text, tbl, key)
    local b = new("TextButton", {
        AutoButtonColor = false, BackgroundColor3 = T.row, BorderSizePixel = 0, Size = UDim2.new(0, 0, 0, 30),
        AutomaticSize = Enum.AutomaticSize.X, Font = Enum.Font.GothamMedium, TextSize = 12, TextColor3 = T.dim,
        Text = text, LayoutOrder = order,
    }, chipHolder)
    corner(b, 15)
    new("UIPadding", {PaddingLeft = UDim.new(0, 15), PaddingRight = UDim.new(0, 15)}, b)
    local st = stroke(b, T.line, 1, 0.2)
    local function render()
        local on = tbl[key]
        b.BackgroundColor3 = on and S.Accent or T.row
        b.BackgroundTransparency = on and 0.72 or 0
        b.TextColor3 = on and T.text or T.dim
        st.Color = on and S.Accent or T.line
    end
    b.MouseButton1Click:Connect(function()
        tbl[key] = not tbl[key]
        RefreshUI()
    end)
    Refreshers[#Refreshers + 1] = render
    Accent.binders[#Accent.binders + 1] = render
    render()
end
Chip(1, "ESP игроков", S.Players, "Enabled")
Chip(2, "Скелет", S.Skeleton, "Enabled")
Chip(3, "ESP лута", S.Loot, "Enabled")
Chip(4, "Ящики", S.Crates, "Enabled")
Chip(5, "Транспорт", S.Vehicles, "Enabled")
Chip(6, "Аимбот", S.Aim, "Enabled")
Chip(7, "Автокликер", S.Macro, "AutoClick")
Chip(8, "Анти-отдача", S.Macro, "Recoil")

-- ===================== СТРАНИЦЫ: БОЙ =====================
local pCombat = CreateTab("Бой", "🎯", "Бой", "Аимбот и макросы мыши")
Section(pCombat, "Наведение")

Feature(pCombat, "Аимбот", "Работает от 1-го и 3-го лица. Активация — по бинду", S.Aim, "Enabled", function(body)
    local A = S.Aim
    BindRow(body, "aim", "Клавиша активации")
    Choice(body, "Способ наведения", A, "Method", {{"Camera", "Камера (поворот вида)"}, {"Mouse", "Мышь (mousemoverel)"}})
    Choice(body, "Куда целиться", A, "Part", {{"Head", "Голова"}, {"Torso", "Тело"}, {"Closest", "Ближайшая к прицелу"}})
    Toggle(body, "Цели: игроки", A, "Players")
    Toggle(body, "Цели: боты", A, "Bots")
    Toggle(body, "Проверка видимости (не целиться сквозь стены)", A, "VisCheck")
    Toggle(body, "Липкая цель (не прыгать между врагами)", A, "Sticky")
    Toggle(body, "Показывать круг FOV", A, "ShowFOV", {{A, "FOVColor"}})
    Slider(body, "Радиус FOV", A, "FOV", 20, 600, 5, " px")
    Slider(body, "Скорость наведения", A, "Speed", 5, 100, 1, "%")
    Slider(body, "Макс. дистанция", A, "MaxDist", 50, 1000, 25, " м")
    Slider(body, "Упреждение движения", A, "Prediction", 0, 300, 10, " мс")
end)

Feature(pCombat, "Макросы мыши", "Автокликер и компенсация отдачи", S.Macro, "Enabled", function(body)
    local M = S.Macro
    Toggle(body, "Автокликер", M, "AutoClick")
    BindRow(body, "autoclick", "Клавиша автокликера")
    Slider(body, "Скорость автокликера", M, "CPS", 1, 30, 1, " кл/с")
    Toggle(body, "Компенсация отдачи (при зажатой ЛКМ)", M, "Recoil")
    Slider(body, "Сила компенсации", M, "RecoilStrength", 1, 15, 1)
    SubHeader(body, "Автокликер и отдача требуют функции mouse1click / mousemoverel в экзекуторе.")
end)

-- ===================== СТРАНИЦЫ: ВИЗУАЛЫ =====================
local pVisuals = CreateTab("Визуалы", "👁", "Визуалы", "ESP игроков, лута, ящиков и транспорта")
Section(pVisuals, "Игроки")

Feature(pVisuals, "ESP игроков и ботов", "Рамка, ник, здоровье, оружие и экипировка", S.Players, "Enabled", function(body)
    local P = S.Players
    BindRow(body, "players", "Клавиша вкл/выкл")
    Toggle(body, "Показывать игроков", P, "ShowPlayers")
    Toggle(body, "Показывать ботов", P, "ShowBots")
    SubHeader(body, "Элементы  ·  цвета: слева — игроки, справа — боты")
    Toggle(body, "Рамка (бокс)", P, "Box", {{P, "BoxColorP"}, {P, "BoxColorB"}})
    Toggle(body, "Ник", P, "Names", {{P, "NameColorP"}, {P, "NameColorB"}})
    Toggle(body, "Подсветка модели", P, "Chams", {{P, "ChamsColorP"}, {P, "ChamsColorB"}})
    Toggle(body, "Расстояние", P, "Distance")
    Toggle(body, "Оружие в руках", P, "Weapon")
    Toggle(body, "Экипировка (жилет, шлем, рюкзак)", P, "Gear")
    Toggle(body, "Полоска здоровья", P, "Health")
    Slider(body, "Прозрачность подсветки", P, "ChamsTransp", 0, 95, 5, "%")
    Slider(body, "Размер текста", P, "TextSize", 9, 18, 1)
    Slider(body, "Макс. дистанция", P, "MaxDist", 50, 1000, 25, " м")
end)

Feature(pVisuals, "Скелет", "Линии по костям персонажа", S.Skeleton, "Enabled", function(body)
    local K = S.Skeleton
    BindRow(body, "skeleton", "Клавиша вкл/выкл")
    ColorRow(body, "Цвет (игроки)", K, "ColorP")
    ColorRow(body, "Цвет (боты)", K, "ColorB")
    Slider(body, "Толщина линий", K, "Thickness", 1, 4, 1, " px")
    Slider(body, "Макс. дистанция", K, "MaxDist", 25, 500, 25, " м")
end)

Section(pVisuals, "Предметы и техника")

Feature(pVisuals, "ESP лута", "Названия на русском, фильтры и свой список", S.Loot, "Enabled", function(body)
    local L = S.Loot
    BindRow(body, "loot", "Клавиша вкл/выкл")
    Toggle(body, "Названия на русском", L, "Russian")
    Toggle(body, "Показывать расстояние", L, "ShowDistance")
    Slider(body, "Макс. дистанция", L, "MaxDist", 25, 1500, 25, " м")
    Slider(body, "Макс. подписей на экране", L, "MaxLabels", 10, 200, 5)
    Slider(body, "Размер текста", L, "TextSize", 9, 20, 1)
    SubHeader(body, "Типы предметов  ·  цветной квадрат — свой цвет")
    for _, key in ipairs(CategoryOrder) do
        Toggle(body, CategoryNames[key], L.Categories, key, {{L.Colors, key}})
    end
    SubHeader(body, "Свой список — показывается всегда, даже если тип выключен")
    TextInput(body, "Мой список предметов (через запятую)", L, "CustomList", "акм, шлем, vest3, аптечка")
    Toggle(body, "Показывать только мой список", L, "CustomOnly")
    Toggle(body, "Увеличивать мои предметы", L, "CustomBig", {{L, "CustomColor"}})
end)

Feature(pVisuals, "ESP ящиков", "Ящики и аирдропы из папки Crates", S.Crates, "Enabled", function(body)
    local C = S.Crates
    BindRow(body, "crates", "Клавиша вкл/выкл")
    ColorRow(body, "Цвет подписи", C, "Color")
    Slider(body, "Размер текста", C, "TextSize", 9, 20, 1)
    Slider(body, "Макс. дистанция", C, "MaxDist", 50, 2000, 50, " м")
end)

Feature(pVisuals, "ESP транспорта", "Техника из папки Vehicles", S.Vehicles, "Enabled", function(body)
    local V = S.Vehicles
    BindRow(body, "vehicles", "Клавиша вкл/выкл")
    ColorRow(body, "Цвет подписи", V, "Color")
    Slider(body, "Размер текста", V, "TextSize", 9, 20, 1)
    Slider(body, "Макс. дистанция", V, "MaxDist", 50, 2000, 50, " м")
end)

-- ===================== СТРАНИЦЫ: БИНДЫ =====================
local pBinds = CreateTab("Бинды", "⌨", "Бинды", "Клавиши и кнопки мыши (ЛКМ, ПКМ, СКМ)")
SubHeader(pBinds, "Нажми на кнопку, затем нажми клавишу или кнопку мыши. Backspace — убрать бинд, Esc — отмена.")
Section(pBinds, "Интерфейс")
BindRow(pBinds, "menu", "Открыть / закрыть меню", true)
Section(pBinds, "Бой")
BindRow(pBinds, "aim", "Аимбот — активация")
BindRow(pBinds, "autoclick", "Автокликер — активация")
Section(pBinds, "Визуалы (вкл / выкл функции)")
BindRow(pBinds, "players", "ESP игроков")
BindRow(pBinds, "skeleton", "Скелет")
BindRow(pBinds, "loot", "ESP лута")
BindRow(pBinds, "crates", "ESP ящиков")
BindRow(pBinds, "vehicles", "ESP транспорта")
SubHeader(pBinds, "Режимы: Удержание — работает, пока зажато; Переключение — нажал и включил/выключил; Всегда — без клавиши.")

-- ===================== СТРАНИЦЫ: НАСТРОЙКИ =====================
local pSettings = CreateTab("Настройки", "⚙", "Настройки", "Интерфейс, конфиг и диагностика")
Section(pSettings, "Интерфейс")
ColorRow(pSettings, "Цвет интерфейса", S, "Accent", SetAccent)
Toggle(pSettings, "Размытие фона при открытом меню", S, "Blur", nil, function() UpdateBlur() end)
Section(pSettings, "Конфиг")
Button(pSettings, "Сохранить настройки", SaveConfig)
Button(pSettings, "Загрузить настройки", function() LoadConfig(false) end)
Section(pSettings, "Диагностика (скопирует структуру в буфер и консоль F9)")
Button(pSettings, "Структура ближайшего врага", DumpNearestEnemy)
Button(pSettings, "Структура ближайшего ящика", function() DumpNearestIn("Crates", "Ящик") end)
Button(pSettings, "Структура ближайшей техники", function() DumpNearestIn("Vehicles", "Техника") end)
Section(pSettings, "Скрипт")
Button(pSettings, "Выгрузить скрипт", function() Unload() end, true)

-- ===================== ПОИСК =====================
CurrentTab = nil
TabInfo["search"] = {"Поиск", "Результаты по настройкам"}
local searchPage = CreatePage("search")

local function GoTo(e)
    searchBox.Text = ""
    SelectTab(e.tab)
    if e.feature then e.feature.open() end
    local row = e.row
    local orig = row.BackgroundColor3
    tween(row, {BackgroundColor3 = S.Accent}, 0.2)
    task.delay(0.7, function() if row.Parent then tween(row, {BackgroundColor3 = orig}, 0.4) end end)
    local page = pages[e.tab]
    task.delay(0.08, function()
        if page and row.Parent then
            local y = row.AbsolutePosition.Y - page.AbsolutePosition.Y + page.CanvasPosition.Y - 16
            page.CanvasPosition = Vector2.new(0, math.max(0, y))
        end
    end)
end

local function RunSearch(q)
    for _, c in ipairs(searchPage:GetChildren()) do
        if c:IsA("GuiObject") then c:Destroy() end
    end
    pageCount[searchPage] = 0
    local n = 0
    for _, e in ipairs(Registry) do
        if e.text:find(q, 1, true) then
            n = n + 1
            if n > 14 then break end
            local path = e.tab .. "   ›   " .. (e.feature and (e.feature.title .. "   ›   ") or "") .. e.label
            local btn = new("TextButton", {
                AutoButtonColor = false, BackgroundColor3 = T.card, BorderSizePixel = 0, Size = UDim2.new(1, 0, 0, 38),
                Font = Enum.Font.GothamMedium, Text = path, TextColor3 = T.text, TextSize = 12,
                TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd,
            })
            corner(btn, 8)
            new("UIPadding", {PaddingLeft = UDim.new(0, 14), PaddingRight = UDim.new(0, 10)}, btn)
            place(searchPage, btn)
            btn.MouseEnter:Connect(function() tween(btn, {BackgroundColor3 = T.cardHover}) end)
            btn.MouseLeave:Connect(function() tween(btn, {BackgroundColor3 = T.card}) end)
            btn.MouseButton1Click:Connect(function() GoTo(e) end)
        end
    end
    if n == 0 then SubHeader(searchPage, "Ничего не найдено") end
end

searchBox:GetPropertyChangedSignal("Text"):Connect(function()
    local q = ruLower(searchBox.Text)
    if q == "" then
        if currentTab == "search" then SelectTab(lastTab or "Главная") end
    else
        SelectTab("search")
        RunSearch(q)
    end
end)

SelectTab("Главная")

-- ===================== ВВОД =====================
Connect(UserInputService.InputBegan, function(input, gp)
    -- захват нового бинда
    if captureCallback then
        local name = InputName(input)
        if name then
            local cb = captureCallback
            captureCallback = nil
            cb(name)
            return
        end
    end

    -- Ctrl+K — поиск
    if input.KeyCode == Enum.KeyCode.K and (UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) or UserInputService:IsKeyDown(Enum.KeyCode.RightControl)) then
        SetMenuVisible(true)
        task.delay(0.03, function()
            searchBox:CaptureFocus()
            searchBox.Text = ""
        end)
        return
    end

    if gp then return end
    local name = InputName(input)
    if name then OnBindPress(name) end
end)

Connect(UserInputService.InputEnded, function(input)
    local name = InputName(input)
    if name then OnBindRelease(name) end
end)

-- ===================== ВЫГРУЗКА =====================
Unload = function()
    for _, c in ipairs(connections) do pcall(function() c:Disconnect() end) end
    pcall(function() RunService:UnbindFromRenderStep("HEKZ_AIM") end)
    ClearVisuals()
    pcall(function() blur:Destroy() end)
    screenGui:Destroy()
    genv.__HEKZ_UNLOAD = nil
end
genv.__HEKZ_UNLOAD = Unload

-- ===================== ЦИКЛЫ =====================
RunService:BindToRenderStep("HEKZ_AIM", Enum.RenderPriority.Camera.Value + 1, function(dt)
    local ok, err = pcall(AimStep, dt)
    if not ok then warn("[HEKZ] Аимбот:", err) end
end)

local acc, uiAcc, fpsSmooth = 0, 0, 60
local function GetPing()
    local ok, v = pcall(function() return Stats.Network.ServerStatsItem["Data Ping"]:GetValue() end)
    if ok and v then return math.floor(v) end
    local ok2, p = pcall(function() return LocalPlayer:GetNetworkPing() end)
    if ok2 and p then return math.floor(p * 1000) end
    return 0
end

local function UpdateHome()
    local fps = math.floor(fpsSmooth + 0.5)
    homeRefs.fps.Text = tostring(fps)
    local frac = math.clamp(fps / 60, 0, 1)
    for i, t in ipairs(ticks) do
        t.BackgroundColor3 = (i / TICKS <= frac) and S.Accent or T.off
    end
    local ping = GetPing()
    homeRefs.pingBig.Text = ping .. " мс"
    homeRefs.ping.Text = "Пинг " .. ping .. " мс"
    homeRefs.gPing.Text = ping .. " мс"
    local count = #Players:GetPlayers()
    local text = count .. " / " .. Players.MaxPlayers
    homeRefs.players.Text = "Игроков " .. text
    homeRefs.gPlayers.Text = text
    homeRefs.session.Text = "на сервере: " .. math.floor((os.clock() - sessionStart) / 60) .. " мин"
end

Connect(RunService.RenderStepped, function(dt)
    Camera = workspace.CurrentCamera
    fpsSmooth = fpsSmooth + (1 / math.max(dt, 0.001) - fpsSmooth) * 0.05

    Targets = BuildTargets()

    local ok1, err1 = pcall(UpdateVisuals)
    if not ok1 then warn("[HEKZ] Визуалы:", err1) end

    acc = acc + dt
    if acc >= 0.2 then
        acc = 0
        local ok2, err2 = pcall(RefreshLoot)
        if not ok2 then warn("[HEKZ] Лут:", err2) end
        local ok3, err3 = pcall(RefreshWorld, cratePool, "Crates", S.Crates, CRATE_PATTERNS, "Ящик")
        if not ok3 then warn("[HEKZ] Ящики:", err3) end
        local ok4, err4 = pcall(RefreshWorld, vehiclePool, "Vehicles", S.Vehicles, VEHICLE_PATTERNS, "Транспорт")
        if not ok4 then warn("[HEKZ] Транспорт:", err4) end
    end
    pcall(PoolMove, lootPool)
    pcall(PoolMove, cratePool)
    pcall(PoolMove, vehiclePool)

    local okM, errM = pcall(MacroStep, dt)
    if not okM then warn("[HEKZ] Макросы:", errM) end

    uiAcc = uiAcc + dt
    if uiAcc >= 0.4 then
        uiAcc = 0
        if main.Visible and pages["Главная"].Visible then pcall(UpdateHome) end
    end
end)

LoadConfig(true)
UpdateBlur()
Notify("HEKZ v5 загружен  ·  меню: " .. DisplayInput(S.Binds.menu.Input))
print("✅ HEKZ DROPZONE v5 LOADED")

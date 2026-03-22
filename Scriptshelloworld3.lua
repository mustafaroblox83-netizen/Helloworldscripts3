--[[
    ╔══════════════════════════════════════════╗
    ║       H4LL0 W0RLD HUB V3               ║
    ║      Rivals & Universal  •  v1.0        ║
    ║     KEY NEEDED + AUTO 1V1 DETECT       ║
    ╚══════════════════════════════════════════╝
]]

local Players          = game:GetService("Players")
local TweenService     = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService       = game:GetService("RunService")
local LocalPlayer      = Players.LocalPlayer

local C = {
    BG_Main    = Color3.fromRGB(8,   3,  3),
    BG_Side    = Color3.fromRGB(15,  5,  5),
    BG_Content = Color3.fromRGB(18,  6,  6),
    BG_Card    = Color3.fromRGB(25,  8,  8),
    Accent     = Color3.fromRGB(180, 20, 20),
    AccentDim  = Color3.fromRGB(100, 10, 10),
    AccentGlow = Color3.fromRGB(220, 40, 40),
    ON         = Color3.fromRGB(200, 30, 30),
    OFF        = Color3.fromRGB(45,  15, 15),
    TextMain   = Color3.fromRGB(220, 180, 180),
    TextSub    = Color3.fromRGB(150, 100, 100),
    TextDim    = Color3.fromRGB(80,  50,  50),
    Border     = Color3.fromRGB(80,  20,  20),
    Blood      = Color3.fromRGB(140, 10,  10),
    Green      = Color3.fromRGB(50,  200, 120),
    Gold       = Color3.fromRGB(255, 200, 50),
    Purple     = Color3.fromRGB(168, 85,  247),
}

local Toggles = {
    Aimbot     = false,
    StrongLock = false,
    ESP        = false,
    SpeedHack  = false,
    WallCheck  = false,
    Auto1v1    = false,
}

local Settings = {
    FOV      = 150,
    AimSpeed = 8,
    AimPart  = "Head",
}

local Connections  = {}
local Minimized    = false
local VALID_KEY    = "Hello_world123"
local LockedTarget = nil
local Auto1v1Target = nil

local function New(class, props, parent)
    local obj = Instance.new(class)
    for k, v in pairs(props or {}) do
        pcall(function() obj[k] = v end)
    end
    if parent then obj.Parent = parent end
    return obj
end

local function Corner(p, r)
    return New("UICorner", {CornerRadius = UDim.new(0, r or 8)}, p)
end

local function Stroke(p, col, th)
    return New("UIStroke", {Color = col or C.Border, Thickness = th or 1}, p)
end

local function Tween(obj, props, t)
    pcall(function()
        TweenService:Create(obj, TweenInfo.new(t or 0.25, Enum.EasingStyle.Quart), props):Play()
    end)
end

local function StopAll()
    for k, c in pairs(Connections) do
        pcall(function() c:Disconnect() end)
        Connections[k] = nil
    end
    LockedTarget = nil
    Auto1v1Target = nil
end

local function GetChar()
    local char = LocalPlayer.Character
    if not char then return nil, nil, nil end
    return char, char:FindFirstChild("HumanoidRootPart"), char:FindFirstChildOfClass("Humanoid")
end

local function GetClosestTarget()
    local cam = workspace.CurrentCamera
    local closest, closestDist = nil, math.huge
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Character then
            local part = plr.Character:FindFirstChild(Settings.AimPart)
            if part then
                local screenPos, onScreen = cam:WorldToViewportPoint(part.Position)
                if onScreen then
                    local center = Vector2.new(cam.ViewportSize.X/2, cam.ViewportSize.Y/2)
                    local screenDist = (Vector2.new(screenPos.X, screenPos.Y) - center).Magnitude
                    if screenDist < Settings.FOV then
                        local worldDist = (part.Position - cam.CFrame.Position).Magnitude
                        if worldDist < closestDist then
                            closestDist = worldDist
                            closest = plr
                        end
                    end
                end
            end
        end
    end
    return closest
end

local function ClearESP()
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr.Character then
            local root = plr.Character:FindFirstChild("HumanoidRootPart")
            if root then
                local bb = root:FindFirstChild("ESP_BB")
                if bb then pcall(function() bb:Destroy() end) end
            end
            local hl = plr.Character:FindFirstChild("ESP_HL")
            if hl then pcall(function() hl:Destroy() end) end
        end
    end
end

-- Auto 1v1 detect: cari player yang paling dekat & dalam range 1v1
local function Detect1v1Enemy()
    local char, hrp, _ = GetChar()
    if not hrp then return nil end
    local closest, dist = nil, math.huge
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Character then
            local root = plr.Character:FindFirstChild("HumanoidRootPart")
            if root then
                local d = (root.Position - hrp.Position).Magnitude
                if d < dist then
                    dist = d
                    closest = plr
                end
            end
        end
    end
    return closest
end

local function ApplyFeature(key, val)
    local char, hrp, hum = GetChar()
    if not char then return end

    if key == "SpeedHack" then
        if hum then
            hum.WalkSpeed = val and (58 + math.random(0,4)) or 16
        end

    elseif key == "ESP" then
        if val then
            Connections.ESP = RunService.Heartbeat:Connect(function()
                for _, plr in ipairs(Players:GetPlayers()) do
                    if plr ~= LocalPlayer and plr.Character then
                        local root = plr.Character:FindFirstChild("HumanoidRootPart")
                        if root and not root:FindFirstChild("ESP_BB") then
                            pcall(function()
                                local bb = New("BillboardGui", {
                                    Name = "ESP_BB",
                                    Size = UDim2.new(0,110,0,24),
                                    StudsOffset = Vector3.new(0,3.5,0),
                                    AlwaysOnTop = true,
                                }, root)
                                New("TextLabel", {
                                    Size = UDim2.new(1,0,1,0),
                                    BackgroundTransparency = 1,
                                    Text = "💀 "..plr.Name,
                                    TextColor3 = C.AccentGlow,
                                    TextSize = 12,
                                    Font = Enum.Font.GothamBold,
                                }, bb)
                            end)
                        end
                        if not plr.Character:FindFirstChild("ESP_HL") then
                            pcall(function()
                                local hl = Instance.new("Highlight")
                                hl.Name = "ESP_HL"
                                hl.FillColor = Color3.fromRGB(180,20,20)
                                hl.OutlineColor = Color3.fromRGB(255,50,50)
                                hl.FillTransparency = 0.5
                                hl.OutlineTransparency = 0
                                hl.Adornee = plr.Character
                                hl.Parent = plr.Character
                            end)
                        end
                    end
                end
            end)
        else
            if Connections.ESP then
                pcall(function() Connections.ESP:Disconnect() end)
                Connections.ESP = nil
            end
            ClearESP()
        end

    elseif key == "Aimbot" then
        if val then
            Connections.Aimbot = RunService.RenderStepped:Connect(function()
                local cam = workspace.CurrentCamera
                local target = nil

                -- Prioritas: Auto1v1 > StrongLock > Closest
                if Toggles.Auto1v1 and Auto1v1Target then
                    if Auto1v1Target.Character then
                        target = Auto1v1Target.Character:FindFirstChild(Settings.AimPart)
                    else
                        Auto1v1Target = Detect1v1Enemy()
                    end
                elseif Toggles.StrongLock and LockedTarget then
                    if LockedTarget.Character then
                        target = LockedTarget.Character:FindFirstChild(Settings.AimPart)
                    else
                        LockedTarget = GetClosestTarget()
                    end
                end

                if not target then
                    local plr = GetClosestTarget()
                    if plr and plr.Character then
                        target = plr.Character:FindFirstChild(Settings.AimPart)
                        if Toggles.StrongLock then LockedTarget = plr end
                        if Toggles.Auto1v1 then Auto1v1Target = plr end
                    end
                end

                if target then
                    pcall(function()
                        local targetCF = CFrame.lookAt(cam.CFrame.Position, target.Position)
                        local speed = (Toggles.StrongLock or Toggles.Auto1v1) and 0.95
                            or math.clamp(Settings.AimSpeed / 100, 0.02, 0.25)
                        cam.CFrame = cam.CFrame:Lerp(targetCF, speed)
                    end)
                end
            end)
        else
            if Connections.Aimbot then
                pcall(function() Connections.Aimbot:Disconnect() end)
                Connections.Aimbot = nil
            end
        end

    elseif key == "StrongLock" then
        if val then
            LockedTarget = GetClosestTarget()
            Connections.StrongLock = RunService.Heartbeat:Connect(function()
                if not LockedTarget or not LockedTarget.Character then
                    LockedTarget = GetClosestTarget()
                end
            end)
        else
            if Connections.StrongLock then
                pcall(function() Connections.StrongLock:Disconnect() end)
                Connections.StrongLock = nil
            end
            LockedTarget = nil
        end

    elseif key == "Auto1v1" then
        if val then
            Auto1v1Target = Detect1v1Enemy()
            Connections.Auto1v1 = RunService.Heartbeat:Connect(function()
                -- Re-detect setiap 0.5 detik
                if not Auto1v1Target or not Auto1v1Target.Character then
                    Auto1v1Target = Detect1v1Enemy()
                end
            end)
        else
            if Connections.Auto1v1 then
                pcall(function() Connections.Auto1v1:Disconnect() end)
                Connections.Auto1v1 = nil
            end
            Auto1v1Target = nil
        end
    end
end

-- ═══════════════════════════
--        KEY SCREEN
-- ═══════════════════════════
local GUI = New("ScreenGui", {
    Name = "H4ll0V3",
    ResetOnSpawn = false,
    DisplayOrder = 999,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
}, game.CoreGui)

local KeyScreen = New("Frame", {
    Size = UDim2.new(1,0,1,0),
    BackgroundColor3 = C.BG_Main,
    BorderSizePixel = 0,
}, GUI)

for i = 1, 12 do
    local drip = New("Frame", {
        Size = UDim2.new(0,math.random(3,9),0,math.random(20,90)),
        Position = UDim2.new(math.random(),0,0,0),
        BackgroundColor3 = C.Blood,
        BackgroundTransparency = 0.35,
        BorderSizePixel = 0,
    }, KeyScreen)
    Corner(drip, 3)
end

local flickLbl = New("TextLabel", {
    Size = UDim2.new(0,90,0,90),
    Position = UDim2.new(0.5,-45,0.1,0),
    BackgroundTransparency = 1,
    Text = "💀", TextSize = 68,
    Font = Enum.Font.GothamBold,
}, KeyScreen)

New("TextLabel", {
    Size = UDim2.new(0,440,0,44),
    Position = UDim2.new(0.5,-220,0.3,0),
    BackgroundTransparency = 1,
    Text = "H4LL0 W0RLD HUB V3",
    TextColor3 = C.Accent,
    TextSize = 28,
    Font = Enum.Font.GothamBold,
}, KeyScreen)

New("TextLabel", {
    Size = UDim2.new(0,440,0,24),
    Position = UDim2.new(0.5,-220,0.4,0),
    BackgroundTransparency = 1,
    Text = "RIVALS & UNIVERSAL  •  AUTO 1V1 DETECT",
    TextColor3 = C.TextSub,
    TextSize = 12,
    Font = Enum.Font.Gotham,
}, KeyScreen)

local KBG = New("Frame", {
    Size = UDim2.new(0,340,0,32),
    Position = UDim2.new(0.5,-170,0.5,0),
    BackgroundColor3 = C.BG_Card,
    BorderSizePixel = 0,
}, KeyScreen)
Corner(KBG, 8); Stroke(KBG, C.Border, 1.5)

local KInput = New("TextBox", {
    Size = UDim2.new(1,-14,1,0),
    Position = UDim2.new(0,10,0,0),
    BackgroundTransparency = 1,
    PlaceholderText = "💀  Enter key...",
    PlaceholderColor3 = C.TextDim,
    Text = "",
    TextColor3 = C.TextMain,
    TextXAlignment = Enum.TextXAlignment.Left,
    TextSize = 13,
    Font = Enum.Font.GothamBold,
    ClearTextOnFocus = false,
}, KBG)

local DiscordBtn = New("TextButton", {
    Size = UDim2.new(0,130,0,28),
    Position = UDim2.new(0.5,-170,0.62,0),
    BackgroundColor3 = C.AccentDim,
    Text = "💬 Get Key (Discord)",
    TextColor3 = C.TextMain,
    TextSize = 11,
    Font = Enum.Font.GothamBold,
    BorderSizePixel = 0,
}, KeyScreen)
Corner(DiscordBtn, 7); Stroke(DiscordBtn, C.Border, 1)

local PasteBtn = New("TextButton", {
    Size = UDim2.new(0,72,0,28),
    Position = UDim2.new(0.5,-32,0.62,0),
    BackgroundColor3 = C.BG_Card,
    Text = "📋 Paste",
    TextColor3 = C.TextMain,
    TextSize = 11,
    Font = Enum.Font.GothamBold,
    BorderSizePixel = 0,
}, KeyScreen)
Corner(PasteBtn, 7); Stroke(PasteBtn, C.Border, 1)

local EnterBtn = New("TextButton", {
    Size = UDim2.new(0,72,0,28),
    Position = UDim2.new(0.5,48,0.62,0),
    BackgroundColor3 = C.Accent,
    Text = "▶ Enter",
    TextColor3 = Color3.fromRGB(255,200,200),
    TextSize = 11,
    Font = Enum.Font.GothamBold,
    BorderSizePixel = 0,
}, KeyScreen)
Corner(EnterBtn, 7)

local KStatus = New("TextLabel", {
    Size = UDim2.new(0,340,0,22),
    Position = UDim2.new(0.5,-170,0.7,0),
    BackgroundTransparency = 1,
    Text = "Enter key to proceed...",
    TextColor3 = C.TextDim,
    TextSize = 11,
    Font = Enum.Font.Gotham,
}, KeyScreen)

task.spawn(function()
    while flickLbl and flickLbl.Parent do
        task.wait(math.random(2,5))
        for _ = 1, 2 do
            flickLbl.TextTransparency = 0.7
            task.wait(0.08)
            flickLbl.TextTransparency = 0
            task.wait(0.08)
        end
    end
end)

DiscordBtn.MouseButton1Click:Connect(function()
    pcall(function() setclipboard("https://discord.gg/xCV9Tf4y5N") end)
    DiscordBtn.Text = "✓ Copied!"
    DiscordBtn.BackgroundColor3 = C.Green
    task.wait(2)
    DiscordBtn.Text = "💬 Get Key (Discord)"
    DiscordBtn.BackgroundColor3 = C.AccentDim
end)

PasteBtn.MouseButton1Click:Connect(function()
    local ok, cb = pcall(getclipboard)
    if ok and cb and cb ~= "" then KInput.Text = cb end
end)

-- ═══════════════════════════
--        MAIN GUI
-- ═══════════════════════════
local function BuildMain()
    KeyScreen:Destroy()

    local Win = New("Frame", {
        Size = UDim2.new(0,580,0,440),
        Position = UDim2.new(0.5,-290,0.5,-220),
        BackgroundColor3 = C.BG_Main,
        BorderSizePixel = 0, Active = true,
    }, GUI)
    Corner(Win, 12); Stroke(Win, C.Blood, 1.5)

    local drag, dStart, dPos = false, nil, nil
    Win.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then
            drag = true; dStart = i.Position; dPos = Win.Position
        end
    end)
    UserInputService.InputChanged:Connect(function(i)
        if drag and i.UserInputType == Enum.UserInputType.MouseMovement then
            local d = i.Position - dStart
            Win.Position = UDim2.new(dPos.X.Scale, dPos.X.Offset+d.X,
                                     dPos.Y.Scale, dPos.Y.Offset+d.Y)
        end
    end)
    UserInputService.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then drag = false end
    end)

    local Top = New("Frame", {
        Size = UDim2.new(1,0,0,40),
        BackgroundColor3 = C.BG_Side,
        BorderSizePixel = 0, ZIndex = 5,
    }, Win)
    Corner(Top, 12)
    New("Frame", {
        Size = UDim2.new(1,0,0.5,0), Position = UDim2.new(0,0,0.5,0),
        BackgroundColor3 = C.BG_Side, BorderSizePixel = 0, ZIndex = 4,
    }, Top)
    New("TextLabel", {
        Size = UDim2.new(0,30,1,0), Position = UDim2.new(0,8,0,0),
        BackgroundTransparency = 1, Text = "💀", TextSize = 20, ZIndex = 6,
    }, Top)
    New("TextLabel", {
        Size = UDim2.new(0,280,1,0), Position = UDim2.new(0,40,0,0),
        BackgroundTransparency = 1, Text = "H4ll0 W0rld Hub V3",
        TextColor3 = C.Accent, TextXAlignment = Enum.TextXAlignment.Left,
        TextSize = 14, Font = Enum.Font.GothamBold, ZIndex = 6,
    }, Top)

    -- V3 badge
    local badge = New("Frame", {
        Size = UDim2.new(0,55,0,20),
        Position = UDim2.new(0,328,0.5,-10),
        BackgroundColor3 = Color3.fromRGB(30,10,40),
        BorderSizePixel = 0, ZIndex = 6,
    }, Top)
    Corner(badge, 5); Stroke(badge, C.Purple, 1)
    New("TextLabel", {
        Size = UDim2.new(1,0,1,0), BackgroundTransparency = 1,
        Text = "⚡ V3", TextColor3 = C.Purple,
        TextSize = 10, Font = Enum.Font.GothamBold, ZIndex = 7,
    }, badge)

    local MinBtn = New("TextButton", {
        Size = UDim2.new(0,26,0,20), Position = UDim2.new(1,-60,0.5,-10),
        BackgroundColor3 = C.BG_Card, Text = "─",
        TextColor3 = C.TextMain, TextSize = 13,
        Font = Enum.Font.GothamBold, BorderSizePixel = 0, ZIndex = 6,
    }, Top)
    Corner(MinBtn, 5)

    local CloseBtn = New("TextButton", {
        Size = UDim2.new(0,26,0,20), Position = UDim2.new(1,-28,0.5,-10),
        BackgroundColor3 = C.Blood, Text = "✕",
        TextColor3 = Color3.fromRGB(255,200,200), TextSize = 12,
        Font = Enum.Font.GothamBold, BorderSizePixel = 0, ZIndex = 6,
    }, Top)
    Corner(CloseBtn, 5)

    CloseBtn.MouseButton1Click:Connect(function()
        StopAll(); ClearESP()
        Tween(Win, {Size = UDim2.new(0,580,0,0)}, 0.3)
        task.wait(0.35); GUI:Destroy()
    end)
    MinBtn.MouseButton1Click:Connect(function()
        Minimized = not Minimized
        if Minimized then
            Tween(Win, {Size = UDim2.new(0,580,0,40)}, 0.3)
            MinBtn.Text = "□"
        else
            Tween(Win, {Size = UDim2.new(0,580,0,440)}, 0.3)
            MinBtn.Text = "─"
        end
    end)

    local CH = New("Frame", {
        Size = UDim2.new(1,0,1,-40), Position = UDim2.new(0,0,0,40),
        BackgroundTransparency = 1, ClipsDescendants = true,
    }, Win)

    local Side = New("Frame", {
        Size = UDim2.new(0,135,1,0),
        BackgroundColor3 = C.BG_Side, BorderSizePixel = 0,
    }, CH)
    Stroke(Side, C.Border, 1)
    New("UIListLayout", {Padding = UDim.new(0,4)}, Side)
    New("UIPadding", {
        PaddingTop = UDim.new(0,8),
        PaddingLeft = UDim.new(0,6),
        PaddingRight = UDim.new(0,6),
    }, Side)

    local CA = New("Frame", {
        Size = UDim2.new(1,-135,1,0), Position = UDim2.new(0,135,0,0),
        BackgroundColor3 = C.BG_Content, BorderSizePixel = 0,
        ClipsDescendants = true,
    }, CH)
    New("UIPadding", {PaddingAll = UDim.new(0,10)}, CA)

    local Pages, TabBtns = {}, {}

    local function MakePage(name)
        local pg = New("ScrollingFrame", {
            Name = name, Size = UDim2.new(1,0,1,0),
            BackgroundTransparency = 1, BorderSizePixel = 0,
            ScrollBarThickness = 3, ScrollBarImageColor3 = C.Accent,
            CanvasSize = UDim2.new(0,0,0,0), Visible = false,
        }, CA)
        local ll = New("UIListLayout", {Padding = UDim.new(0,6)}, pg)
        ll:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            pg.CanvasSize = UDim2.new(0,0,0,ll.AbsoluteContentSize.Y+16)
        end)
        Pages[name] = pg
        return pg
    end

    local function SetTab(name)
        for n, pg in pairs(Pages) do pg.Visible = (n==name) end
        for n, btn in pairs(TabBtns) do
            if n == name then
                Tween(btn, {BackgroundColor3 = C.AccentDim}, 0.2)
                btn.BackgroundTransparency = 0
                btn.TextColor3 = C.Accent
            else
                btn.BackgroundTransparency = 1
                btn.TextColor3 = C.TextSub
            end
        end
    end

    for _, t in ipairs({{"Combat","💀"},{"1v1","⚔️"},{"Visual","👁"},{"Settings","⚙"}}) do
        MakePage(t[1])
        local btn = New("TextButton", {
            Size = UDim2.new(1,0,0,32),
            BackgroundTransparency = 1,
            BackgroundColor3 = C.BG_Side,
            Text = t[2].."  "..t[1],
            TextColor3 = C.TextSub,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextSize = 12, Font = Enum.Font.GothamBold,
            BorderSizePixel = 0,
        }, Side)
        Corner(btn, 7)
        New("UIPadding", {PaddingLeft = UDim.new(0,8)}, btn)
        TabBtns[t[1]] = btn
        btn.MouseButton1Click:Connect(function() SetTab(t[1]) end)
    end

    local function Section(parent, txt, col)
        local f = New("Frame", {Size=UDim2.new(1,0,0,20), BackgroundTransparency=1}, parent)
        New("TextLabel", {
            Size=UDim2.new(1,0,1,0), BackgroundTransparency=1,
            Text="  ▸  "..txt, TextColor3=col or C.Accent,
            TextXAlignment=Enum.TextXAlignment.Left,
            TextSize=10, Font=Enum.Font.GothamBold,
        }, f)
    end

    local function Toggle(parent, label, key, desc, col)
        local card = New("Frame", {
            Size = UDim2.new(1,0,0, desc and 52 or 40),
            BackgroundColor3 = C.BG_Card, BorderSizePixel = 0,
        }, parent)
        Corner(card, 8); Stroke(card, C.Border, 1)
        New("TextLabel", {
            Size=UDim2.new(1,-70,0,20), Position=UDim2.new(0,10,0,5),
            BackgroundTransparency=1, Text=label,
            TextColor3=C.TextMain, TextXAlignment=Enum.TextXAlignment.Left,
            TextSize=12, Font=Enum.Font.GothamBold,
        }, card)
        if desc then
            New("TextLabel", {
                Size=UDim2.new(1,-70,0,16), Position=UDim2.new(0,10,0,26),
                BackgroundTransparency=1, Text=desc,
                TextColor3=C.TextDim, TextXAlignment=Enum.TextXAlignment.Left,
                TextSize=10, Font=Enum.Font.Gotham,
            }, card)
        end
        local onCol = col or C.ON
        local tb = New("TextButton", {
            Size=UDim2.new(0,46,0,22), Position=UDim2.new(1,-54,0.5,-11),
            BackgroundColor3=C.OFF, Text="", BorderSizePixel=0,
        }, card)
        Corner(tb, 11)
        local circ = New("Frame", {
            Size=UDim2.new(0,16,0,16), Position=UDim2.new(0,3,0.5,-8),
            BackgroundColor3=Color3.fromRGB(255,220,220), BorderSizePixel=0,
        }, tb)
        Corner(circ, 8)
        tb.MouseButton1Click:Connect(function()
            Toggles[key] = not Toggles[key]
            Tween(tb, {BackgroundColor3 = Toggles[key] and onCol or C.OFF}, 0.2)
            Tween(circ, {Position = Toggles[key] and UDim2.new(0,27,0.5,-8) or UDim2.new(0,3,0.5,-8)}, 0.2)
            pcall(function() ApplyFeature(key, Toggles[key]) end)
        end)
    end

    local function Slider(parent, label, minVal, maxVal, default, settingKey, suffix)
        local card = New("Frame", {
            Size=UDim2.new(1,0,0,62), BackgroundColor3=C.BG_Card, BorderSizePixel=0,
        }, parent)
        Corner(card, 8); Stroke(card, C.Border, 1)
        New("TextLabel", {
            Size=UDim2.new(1,0,0,20), Position=UDim2.new(0,10,0,5),
            BackgroundTransparency=1, Text=label,
            TextColor3=C.TextMain, TextXAlignment=Enum.TextXAlignment.Left,
            TextSize=12, Font=Enum.Font.GothamBold,
        }, card)
        local valLbl = New("TextLabel", {
            Size=UDim2.new(0,60,0,20), Position=UDim2.new(1,-65,0,5),
            BackgroundTransparency=1,
            Text=tostring(default)..(suffix or ""),
            TextColor3=C.Gold, TextXAlignment=Enum.TextXAlignment.Right,
            TextSize=11, Font=Enum.Font.GothamBold,
        }, card)
        local pct = (default-minVal)/(maxVal-minVal)
        local trackBG = New("Frame", {
            Size=UDim2.new(1,-20,0,8), Position=UDim2.new(0,10,0,36),
            BackgroundColor3=C.BG_Main, BorderSizePixel=0,
        }, card)
        Corner(trackBG, 4)
        local trackFill = New("Frame", {
            Size=UDim2.new(pct,0,1,0),
            BackgroundColor3=C.Accent, BorderSizePixel=0,
        }, trackBG)
        Corner(trackFill, 4)
        local thumb = New("Frame", {
            Size=UDim2.new(0,16,0,16),
            Position=UDim2.new(pct,-8,0.5,-8),
            BackgroundColor3=Color3.fromRGB(255,200,200), BorderSizePixel=0,
        }, trackBG)
        Corner(thumb, 8)
        local sliding = false
        trackBG.InputBegan:Connect(function(i)
            if i.UserInputType == Enum.UserInputType.MouseButton1 or
               i.UserInputType == Enum.UserInputType.Touch then
                sliding = true
            end
        end)
        UserInputService.InputEnded:Connect(function(i)
            if i.UserInputType == Enum.UserInputType.MouseButton1 or
               i.UserInputType == Enum.UserInputType.Touch then
                sliding = false
            end
        end)
        UserInputService.InputChanged:Connect(function(i)
            if sliding and (i.UserInputType == Enum.UserInputType.MouseMovement or
                            i.UserInputType == Enum.UserInputType.Touch) then
                local abs = trackBG.AbsolutePosition
                local size = trackBG.AbsoluteSize
                local rel = math.clamp((i.Position.X - abs.X) / size.X, 0, 1)
                local val = math.floor(minVal + (maxVal-minVal) * rel)
                Settings[settingKey] = val
                valLbl.Text = tostring(val)..(suffix or "")
                trackFill.Size = UDim2.new(rel, 0, 1, 0)
                thumb.Position = UDim2.new(rel, -8, 0.5, -8)
            end
        end)
    end

    -- ══════════════════════
    --   💀 COMBAT PAGE
    -- ══════════════════════
    local CP = Pages["Combat"]
    Section(CP, "AIMBOT")
    Toggle(CP, "Aimbot",      "Aimbot",     "Auto aim dalam FOV")
    Toggle(CP, "Strong Lock", "StrongLock", "Lock aim ke 1 target kuat (95%)")
    Slider(CP, "🎯 FOV Radius",  50, 500, 150, "FOV",      " px")
    Slider(CP, "⚡ Aim Speed",    1,  30,  8,   "AimSpeed", "")

    -- Aim Part
    local aimCard = New("Frame", {
        Size=UDim2.new(1,0,0,52), BackgroundColor3=C.BG_Card, BorderSizePixel=0,
    }, CP)
    Corner(aimCard, 8); Stroke(aimCard, C.Border, 1)
    New("TextLabel", {
        Size=UDim2.new(1,0,0,22), Position=UDim2.new(0,10,0,5),
        BackgroundTransparency=1, Text="🎯 Aim Part",
        TextColor3=C.TextMain, TextXAlignment=Enum.TextXAlignment.Left,
        TextSize=12, Font=Enum.Font.GothamBold,
    }, aimCard)
    local aimStatus = New("TextLabel", {
        Size=UDim2.new(1,0,0,16), Position=UDim2.new(0,10,0,28),
        BackgroundTransparency=1, Text="Target: HEAD 💀",
        TextColor3=C.Gold, TextXAlignment=Enum.TextXAlignment.Left,
        TextSize=10, Font=Enum.Font.GothamBold,
    }, aimCard)
    local headBtn = New("TextButton", {
        Size=UDim2.new(0,55,0,22), Position=UDim2.new(1,-122,0.5,-11),
        BackgroundColor3=C.Accent, Text="Head",
        TextColor3=Color3.fromRGB(255,200,200),
        TextSize=11, Font=Enum.Font.GothamBold, BorderSizePixel=0,
    }, aimCard)
    Corner(headBtn, 6)
    local bodyBtn = New("TextButton", {
        Size=UDim2.new(0,55,0,22), Position=UDim2.new(1,-60,0.5,-11),
        BackgroundColor3=C.BG_Card, Text="Body",
        TextColor3=C.TextSub,
        TextSize=11, Font=Enum.Font.GothamBold, BorderSizePixel=0,
    }, aimCard)
    Corner(bodyBtn, 6); Stroke(bodyBtn, C.Border, 1)
    headBtn.MouseButton1Click:Connect(function()
        Settings.AimPart = "Head"
        aimStatus.Text = "Target: HEAD 💀"
        headBtn.BackgroundColor3 = C.Accent
        headBtn.TextColor3 = Color3.fromRGB(255,200,200)
        bodyBtn.BackgroundColor3 = C.BG_Card
        bodyBtn.TextColor3 = C.TextSub
    end)
    bodyBtn.MouseButton1Click:Connect(function()
        Settings.AimPart = "HumanoidRootPart"
        aimStatus.Text = "Target: BODY 🫀"
        bodyBtn.BackgroundColor3 = C.Accent
        bodyBtn.TextColor3 = Color3.fromRGB(255,200,200)
        headBtn.BackgroundColor3 = C.BG_Card
        headBtn.TextColor3 = C.TextSub
    end)

    Section(CP, "UTILITY")
    Toggle(CP, "WallCheck",  "WallCheck",  "Cek musuh di balik tembok")
    Toggle(CP, "Speed Hack", "SpeedHack",  "WalkSpeed anti detect")

    -- ══════════════════════
    --   ⚔️ 1V1 PAGE
    -- ══════════════════════
    local OVP = Pages["1v1"]
    Section(OVP, "AUTO 1V1 DETECT", C.Purple)

    -- Status card
    local statusCard = New("Frame", {
        Size=UDim2.new(1,0,0,52), BackgroundColor3=C.BG_Card, BorderSizePixel=0,
    }, OVP)
    Corner(statusCard, 8); Stroke(statusCard, C.Purple, 1.5)

    local targetLbl = New("TextLabel", {
        Size=UDim2.new(1,-16,0,22), Position=UDim2.new(0,8,0,4),
        BackgroundTransparency=1,
        Text="⚔️  Target: Tidak ada",
        TextColor3=C.Purple, TextXAlignment=Enum.TextXAlignment.Left,
        TextSize=12, Font=Enum.Font.GothamBold,
    }, statusCard)

    local distLbl = New("TextLabel", {
        Size=UDim2.new(1,-16,0,18), Position=UDim2.new(0,8,0,28),
        BackgroundTransparency=1,
        Text="📍 Jarak: -",
        TextColor3=C.TextSub, TextXAlignment=Enum.TextXAlignment.Left,
        TextSize=10, Font=Enum.Font.Gotham,
    }, statusCard)

    Toggle(OVP, "Auto 1v1 Detect", "Auto1v1",
        "Auto detect & aim musuh 1v1", C.Purple)

    -- Manual switch target button
    local switchCard = New("Frame", {
        Size=UDim2.new(1,0,0,40), BackgroundColor3=C.BG_Card, BorderSizePixel=0,
    }, OVP)
    Corner(switchCard, 8); Stroke(switchCard, C.Border, 1)
    New("TextLabel", {
        Size=UDim2.new(1,-80,1,0), Position=UDim2.new(0,10,0,0),
        BackgroundTransparency=1, Text="🔄 Ganti Target",
        TextColor3=C.TextMain, TextXAlignment=Enum.TextXAlignment.Left,
        TextSize=12, Font=Enum.Font.GothamBold,
    }, switchCard)
    local switchBtn = New("TextButton", {
        Size=UDim2.new(0,62,0,24), Position=UDim2.new(1,-72,0.5,-12),
        BackgroundColor3=C.Purple, Text="Switch",
        TextColor3=Color3.fromRGB(255,220,255),
        TextSize=11, Font=Enum.Font.GothamBold, BorderSizePixel=0,
    }, switchCard)
    Corner(switchBtn, 6)

    switchBtn.MouseButton1Click:Connect(function()
        -- Cari target baru selain yang sekarang
        local current = Auto1v1Target
        local newTarget = nil
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= LocalPlayer and plr ~= current and plr.Character then
                newTarget = plr
                break
            end
        end
        if newTarget then
            Auto1v1Target = newTarget
            LockedTarget = newTarget
            switchBtn.Text = "✓ Switched"
            switchBtn.BackgroundColor3 = C.Green
            task.wait(1.5)
            switchBtn.Text = "Switch"
            switchBtn.BackgroundColor3 = C.Purple
        end
    end)

    -- Update status realtime
    Connections.StatusUpdate = RunService.Heartbeat:Connect(function()
        local target = Auto1v1Target or LockedTarget
        if target and target.Character then
            local _, hrp, _ = GetChar()
            local root = target.Character:FindFirstChild("HumanoidRootPart")
            if hrp and root then
                local dist = math.floor((root.Position - hrp.Position).Magnitude)
                targetLbl.Text = "⚔️  Target: "..target.Name
                distLbl.Text = "📍 Jarak: "..dist.." studs"
            end
        else
            targetLbl.Text = "⚔️  Target: Tidak ada"
            distLbl.Text = "📍 Jarak: -"
        end
    end)

    -- ══════════════════════
    --   👁 VISUAL PAGE
    -- ══════════════════════
    local VP = Pages["Visual"]
    Section(VP, "ESP")
    Toggle(VP, "ESP + Highlight", "ESP", "Nama + highlight merah badan player")

    -- ══════════════════════
    --   ⚙ SETTINGS PAGE
    -- ══════════════════════
    local SETP = Pages["Settings"]
    Section(SETP, "ANTI DETECT")
    local adCard = New("Frame", {
        Size=UDim2.new(1,0,0,70), BackgroundColor3=C.BG_Card, BorderSizePixel=0,
    }, SETP)
    Corner(adCard, 8); Stroke(adCard, C.Green, 1.5)
    New("TextLabel", {
        Size=UDim2.new(1,-16,1,0), Position=UDim2.new(0,8,0,0),
        BackgroundTransparency=1,
        Text="🛡️  Anti Detect AKTIF\n• CFrame Lerp smooth\n• Strong Lock 95%\n• Speed random offset",
        TextColor3=C.Green, TextXAlignment=Enum.TextXAlignment.Left,
        TextSize=11, TextWrapped=true, Font=Enum.Font.Gotham,
    }, adCard)

    Section(SETP, "ABOUT")
    local about = New("Frame", {
        Size=UDim2.new(1,0,0,80), BackgroundColor3=C.BG_Card, BorderSizePixel=0,
    }, SETP)
    Corner(about, 8); Stroke(about, C.Blood, 1.5)
    New("TextLabel", {
        Size=UDim2.new(1,-16,1,0), Position=UDim2.new(0,8,0,0),
        BackgroundTransparency=1,
        Text="💀  H4ll0 W0rld Hub V3  v1.0\nGame: Rivals & Universal\nStatus: Key Needed 🔑\nDiscord: discord.gg/xCV9Tf4y5N",
        TextColor3=C.TextSub, TextXAlignment=Enum.TextXAlignment.Left,
        TextSize=11, TextWrapped=true, Font=Enum.Font.Gotham,
    }, about)

    local stopBtn = New("TextButton", {
        Size=UDim2.new(1,0,0,36), BackgroundColor3=C.Blood,
        Text="⛔  Stop All Features",
        TextColor3=Color3.fromRGB(255,200,200),
        TextSize=12, Font=Enum.Font.GothamBold, BorderSizePixel=0,
    }, SETP)
    Corner(stopBtn, 8)
    stopBtn.MouseButton1Click:Connect(function()
        StopAll(); ClearESP()
        for k in pairs(Toggles) do Toggles[k] = false end
        stopBtn.Text = "✅ All Features Stopped"
        task.wait(2)
        stopBtn.Text = "⛔  Stop All Features"
    end)

    SetTab("Combat")
end

-- ═══════════════════════════
--      KEY VALIDATION
-- ═══════════════════════════
EnterBtn.MouseButton1Click:Connect(function()
    if KInput.Text == VALID_KEY then
        KStatus.Text = "✅ Key Valid! Loading..."
        KStatus.TextColor3 = C.Green
        for _, obj in ipairs(KeyScreen:GetDescendants()) do
            pcall(function()
                if obj:IsA("TextLabel") or obj:IsA("TextButton") then
                    Tween(obj, {TextTransparency=1}, 0.3)
                end
                if obj:IsA("Frame") then
                    Tween(obj, {BackgroundTransparency=1}, 0.3)
                end
            end)
        end
        Tween(KeyScreen, {BackgroundTransparency=1}, 0.3)
        task.wait(0.5)
        BuildMain()
    else
        KStatus.Text = "❌ Key salah! Join Discord untuk key."
        KStatus.TextColor3 = C.Accent
        Tween(KBG, {BackgroundColor3=Color3.fromRGB(40,8,8)}, 0.2)
        task.wait(0.3)
        Tween(KBG, {BackgroundColor3=C.BG_Card}, 0.2)
    end
end)

--[[
    ╔══════════════════════════════════════════╗
    ║       H4LL0 W0RLD HUB V3               ║
    ║        Rivals & Universal  •  v2.0      ║
    ║     FIXED: Switch Target All Players    ║
    ║          KEY: Hello_world123            ║
    ╚══════════════════════════════════════════╝
]]

local Players          = game:GetService("Players")
local TweenService     = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService       = game:GetService("RunService")
local Debris           = game:GetService("Debris")
local LocalPlayer      = Players.LocalPlayer
local Camera           = workspace.CurrentCamera

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
    Blue       = Color3.fromRGB(50,  150, 255),
}

local Toggles = {
    Aimbot      = false,
    StrongLock  = false,
    WallCheck   = false,
    NoClip      = false,
    ESP         = false,
    SpeedHack   = false,
    Fly         = false,
    Auto1v1     = false,
}

local Settings = {
    WalkSpeed  = 16,
    FlySpeed   = 40,
    FOV        = 150,
    AimSpeed   = 8,
    AimPart    = "Head",
}

-- ═══════════════════
--   1V1 TARGET LIST
-- ═══════════════════
local TargetList    = {}  -- semua player di server
local TargetIndex   = 1   -- index target sekarang
local CurrentTarget = nil -- player yang di-lock sekarang

local function RefreshTargetList()
    TargetList = {}
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer then
            table.insert(TargetList, plr)
        end
    end
    -- Pastiin index tidak out of bounds
    if TargetIndex > #TargetList then
        TargetIndex = 1
    end
    if #TargetList > 0 then
        CurrentTarget = TargetList[TargetIndex]
    else
        CurrentTarget = nil
    end
end

local function SwitchTarget()
    RefreshTargetList()
    if #TargetList == 0 then return end
    TargetIndex = TargetIndex + 1
    if TargetIndex > #TargetList then TargetIndex = 1 end
    CurrentTarget = TargetList[TargetIndex]
end

local Connections = {}
local Minimized   = false
local VALID_KEY   = "Hello_world123"

-- Target name label (akan di-update dari BuildMain)
local targetNameLbl = nil
local targetDistLbl = nil
local targetIdxLbl  = nil

local function UpdateTargetUI()
    if not targetNameLbl then return end
    if CurrentTarget and CurrentTarget.Character then
        local _, hrp, _ = (function()
            local char = LocalPlayer.Character
            if not char then return nil, nil, nil end
            return char, char:FindFirstChild("HumanoidRootPart"), char:FindFirstChildOfClass("Humanoid")
        end)()
        local root = CurrentTarget.Character:FindFirstChild("HumanoidRootPart")
        local dist = (hrp and root) and
            math.floor((root.Position - hrp.Position).Magnitude) or 0
        targetNameLbl.Text = "🎯 "..CurrentTarget.Name
        targetDistLbl.Text = "📏 "..dist.." studs"
        targetIdxLbl.Text  = "["..TargetIndex.."/"..#TargetList.."]"
    else
        targetNameLbl.Text = "🎯 Tidak ada target"
        targetDistLbl.Text = "📏 -"
        targetIdxLbl.Text  = "[0/0]"
    end
end

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

local function GetChar()
    local char = LocalPlayer.Character
    if not char then return nil, nil, nil end
    return char, char:FindFirstChild("HumanoidRootPart"), char:FindFirstChildOfClass("Humanoid")
end

local function StopAll()
    for k, c in pairs(Connections) do
        pcall(function() c:Disconnect() end)
        Connections[k] = nil
    end
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

local function ApplyFeature(key, val)
    local char, hrp, hum = GetChar()

    if key == "Aimbot" then
        if val then
            Connections.Aimbot = RunService.RenderStepped:Connect(function()
                local target = nil
                if Toggles.Auto1v1 and CurrentTarget and CurrentTarget.Character then
                    target = CurrentTarget.Character:FindFirstChild(Settings.AimPart)
                             or CurrentTarget.Character:FindFirstChild("Head")
                else
                    local closest, dist = nil, math.huge
                    for _, plr in ipairs(Players:GetPlayers()) do
                        if plr ~= LocalPlayer and plr.Character then
                            local part = plr.Character:FindFirstChild(Settings.AimPart)
                                         or plr.Character:FindFirstChild("Head")
                            if part then
                                local screenPos, onScreen = Camera:WorldToViewportPoint(part.Position)
                                if onScreen then
                                    local center = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
                                    local d = (Vector2.new(screenPos.X, screenPos.Y) - center).Magnitude
                                    if d < Settings.FOV and d < dist then
                                        dist = d; closest = part
                                    end
                                end
                            end
                        end
                    end
                    target = closest
                end
                if target then
                    pcall(function()
                        local camPos = Camera.CFrame.Position
                        local targetCF = CFrame.lookAt(camPos, target.Position)
                        Camera.CFrame = Camera.CFrame:Lerp(targetCF,
                            math.clamp(Settings.AimSpeed/100, 0.02, 0.25))
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
            Connections.StrongLock = RunService.RenderStepped:Connect(function()
                local target = nil
                if Toggles.Auto1v1 and CurrentTarget and CurrentTarget.Character then
                    target = CurrentTarget.Character:FindFirstChild(Settings.AimPart)
                             or CurrentTarget.Character:FindFirstChild("Head")
                else
                    local closest, dist = nil, math.huge
                    for _, plr in ipairs(Players:GetPlayers()) do
                        if plr ~= LocalPlayer and plr.Character then
                            local part = plr.Character:FindFirstChild(Settings.AimPart)
                                         or plr.Character:FindFirstChild("Head")
                            if part then
                                local screenPos, onScreen = Camera:WorldToViewportPoint(part.Position)
                                if onScreen then
                                    local center = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
                                    local d = (Vector2.new(screenPos.X, screenPos.Y) - center).Magnitude
                                    if d < dist then dist = d; closest = part end
                                end
                            end
                        end
                    end
                    target = closest
                end
                if target then
                    pcall(function()
                        local camPos = Camera.CFrame.Position
                        local targetCF = CFrame.lookAt(camPos, target.Position)
                        Camera.CFrame = targetCF
                    end)
                end
            end)
        else
            if Connections.StrongLock then
                pcall(function() Connections.StrongLock:Disconnect() end)
                Connections.StrongLock = nil
            end
        end

    elseif key == "WallCheck" then
        if val then
            Connections.WallCheck = RunService.Heartbeat:Connect(function()
                for _, plr in ipairs(Players:GetPlayers()) do
                    if plr ~= LocalPlayer and plr.Character then
                        local root = plr.Character:FindFirstChild("HumanoidRootPart")
                        if root and hrp then
                            local ray = workspace:Raycast(
                                hrp.Position,
                                (root.Position - hrp.Position).Unit * 500,
                                RaycastParams.new()
                            )
                            local bb = root:FindFirstChild("WC_BB")
                            if ray and ray.Instance then
                                local isWall = not ray.Instance:IsDescendantOf(plr.Character)
                                if isWall then
                                    if not bb then
                                        local b = New("BillboardGui",{
                                            Name="WC_BB",Size=UDim2.new(0,90,0,20),
                                            StudsOffset=Vector3.new(0,5,0),AlwaysOnTop=true,
                                        },root)
                                        New("TextLabel",{
                                            Size=UDim2.new(1,0,1,0),BackgroundTransparency=1,
                                            Text="🧱 "..plr.Name,
                                            TextColor3=C.Gold,TextSize=11,
                                            Font=Enum.Font.GothamBold,
                                        },b)
                                    end
                                else
                                    if bb then pcall(function() bb:Destroy() end) end
                                end
                            end
                        end
                    end
                end
            end)
        else
            if Connections.WallCheck then
                pcall(function() Connections.WallCheck:Disconnect() end)
                Connections.WallCheck = nil
            end
            for _, plr in ipairs(Players:GetPlayers()) do
                if plr.Character then
                    local root = plr.Character:FindFirstChild("HumanoidRootPart")
                    if root then
                        local bb = root:FindFirstChild("WC_BB")
                        if bb then pcall(function() bb:Destroy() end) end
                    end
                end
            end
        end

    elseif key == "NoClip" then
        if val then
            Connections.NoClip = RunService.Stepped:Connect(function()
                local c = LocalPlayer.Character
                if c then
                    for _, p in ipairs(c:GetDescendants()) do
                        if p:IsA("BasePart") then
                            pcall(function() p.CanCollide = false end)
                        end
                    end
                end
            end)
        else
            if Connections.NoClip then
                pcall(function() Connections.NoClip:Disconnect() end)
                Connections.NoClip = nil
            end
        end

    elseif key == "ESP" then
        if val then
            Connections.ESP = RunService.Heartbeat:Connect(function()
                for _, plr in ipairs(Players:GetPlayers()) do
                    if plr ~= LocalPlayer and plr.Character then
                        local root = plr.Character:FindFirstChild("HumanoidRootPart")
                        if root and not root:FindFirstChild("ESP_BB") then
                            pcall(function()
                                local isTarget = CurrentTarget == plr
                                local bb = New("BillboardGui",{
                                    Name="ESP_BB",Size=UDim2.new(0,120,0,26),
                                    StudsOffset=Vector3.new(0,4,0),AlwaysOnTop=true,
                                },root)
                                New("TextLabel",{
                                    Size=UDim2.new(1,0,1,0),BackgroundTransparency=1,
                                    Text=(isTarget and "🎯 " or "💀 ")..plr.Name..(isTarget and " [TARGET]" or ""),
                                    TextColor3=isTarget and C.Purple or C.AccentGlow,
                                    TextSize=11,Font=Enum.Font.GothamBold,
                                },bb)
                                local hl = Instance.new("Highlight")
                                hl.Name="ESP_HL"
                                hl.FillColor=isTarget and Color3.fromRGB(168,85,247) or Color3.fromRGB(180,20,20)
                                hl.OutlineColor=isTarget and Color3.fromRGB(200,150,255) or Color3.fromRGB(255,50,50)
                                hl.FillTransparency=0.45
                                hl.DepthMode=Enum.HighlightDepthMode.AlwaysOnTop
                                hl.Adornee=plr.Character
                                hl.Parent=plr.Character
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

    elseif key == "SpeedHack" then
        if hum then hum.WalkSpeed = val and Settings.WalkSpeed or 16 end

    elseif key == "Fly" then
        if val then
            pcall(function()
                if not hrp then return end
                local bg = Instance.new("BodyGyro")
                bg.MaxTorque = Vector3.new(1e9,1e9,1e9)
                bg.P = 1e4; bg.Parent = hrp
                local bv = Instance.new("BodyVelocity")
                bv.Velocity = Vector3.zero
                bv.MaxForce = Vector3.new(1e9,1e9,1e9)
                bv.Parent = hrp
                Connections.Fly = RunService.Heartbeat:Connect(function()
                    if Toggles.Aimbot or Toggles.StrongLock then
                        bv.Velocity = Vector3.zero; return
                    end
                    local cam = workspace.CurrentCamera
                    if UserInputService:IsKeyDown(Enum.KeyCode.W) then
                        bv.Velocity = cam.CFrame.LookVector * Settings.FlySpeed
                    elseif UserInputService:IsKeyDown(Enum.KeyCode.S) then
                        bv.Velocity = -cam.CFrame.LookVector * Settings.FlySpeed
                    elseif UserInputService:IsKeyDown(Enum.KeyCode.Space) then
                        bv.Velocity = Vector3.new(0, Settings.FlySpeed, 0)
                    else
                        bv.Velocity = Vector3.zero
                    end
                    bg.CFrame = cam.CFrame
                end)
            end)
        else
            if Connections.Fly then
                pcall(function() Connections.Fly:Disconnect() end)
                Connections.Fly = nil
            end
            if hrp then
                for _, obj in ipairs(hrp:GetChildren()) do
                    if obj:IsA("BodyGyro") or obj:IsA("BodyVelocity") then
                        pcall(function() obj:Destroy() end)
                    end
                end
            end
        end

    elseif key == "Auto1v1" then
        if val then
            RefreshTargetList()
            -- Auto update target UI
            Connections.Auto1v1UI = RunService.Heartbeat:Connect(function()
                UpdateTargetUI()
            end)
        else
            if Connections.Auto1v1UI then
                pcall(function() Connections.Auto1v1UI:Disconnect() end)
                Connections.Auto1v1UI = nil
            end
        end
    end
end

-- ═══════════════════════════
--        KEY SCREEN
-- ═══════════════════════════
local GUI = New("ScreenGui", {
    Name="H4ll0V3", ResetOnSpawn=false,
    DisplayOrder=999, ZIndexBehavior=Enum.ZIndexBehavior.Sibling,
}, game.CoreGui)

local KeyScreen = New("Frame", {
    Size=UDim2.new(1,0,1,0),
    BackgroundColor3=C.BG_Main, BorderSizePixel=0,
}, GUI)

for i = 1, 12 do
    local drip = New("Frame", {
        Size=UDim2.new(0,math.random(3,9),0,math.random(20,90)),
        Position=UDim2.new(math.random(),0,0,0),
        BackgroundColor3=C.Blood, BackgroundTransparency=0.35, BorderSizePixel=0,
    }, KeyScreen)
    Corner(drip, 3)
end

local flickLbl = New("TextLabel", {
    Size=UDim2.new(0,90,0,90), Position=UDim2.new(0.5,-45,0.1,0),
    BackgroundTransparency=1, Text="💀", TextSize=68,
    Font=Enum.Font.GothamBold,
}, KeyScreen)

New("TextLabel", {
    Size=UDim2.new(0,440,0,44), Position=UDim2.new(0.5,-220,0.3,0),
    BackgroundTransparency=1, Text="H4LL0 W0RLD HUB V3",
    TextColor3=C.Accent, TextSize=24, Font=Enum.Font.GothamBold,
}, KeyScreen)

-- V3 badge
local v3badge = New("Frame", {
    Size=UDim2.new(0,70,0,22), Position=UDim2.new(0.5,80,0.3,8),
    BackgroundColor3=Color3.fromRGB(20,5,30), BorderSizePixel=0,
}, KeyScreen)
Corner(v3badge, 5); Stroke(v3badge, C.Purple, 1)
New("TextLabel", {
    Size=UDim2.new(1,0,1,0), BackgroundTransparency=1,
    Text="⚡ V3", TextColor3=C.Purple, TextSize=11,
    Font=Enum.Font.GothamBold,
}, v3badge)

New("TextLabel", {
    Size=UDim2.new(0,440,0,24), Position=UDim2.new(0.5,-220,0.4,0),
    BackgroundTransparency=1, Text="RIVALS & UNIVERSAL  •  KEY NEEDED",
    TextColor3=C.TextSub, TextSize=12, Font=Enum.Font.Gotham,
}, KeyScreen)

local KBG = New("Frame", {
    Size=UDim2.new(0,340,0,32), Position=UDim2.new(0.5,-170,0.5,0),
    BackgroundColor3=C.BG_Card, BorderSizePixel=0,
}, KeyScreen)
Corner(KBG,8); Stroke(KBG,C.Border,1.5)

local KInput = New("TextBox", {
    Size=UDim2.new(1,-14,1,0), Position=UDim2.new(0,10,0,0),
    BackgroundTransparency=1, PlaceholderText="💀  Enter key...",
    PlaceholderColor3=C.TextDim, Text="", TextColor3=C.TextMain,
    TextXAlignment=Enum.TextXAlignment.Left, TextSize=13,
    Font=Enum.Font.GothamBold, ClearTextOnFocus=false,
}, KBG)

local DiscordBtn = New("TextButton", {
    Size=UDim2.new(0,130,0,28), Position=UDim2.new(0.5,-170,0.62,0),
    BackgroundColor3=C.AccentDim, Text="💬 Get Key (Discord)",
    TextColor3=C.TextMain, TextSize=11, Font=Enum.Font.GothamBold, BorderSizePixel=0,
}, KeyScreen)
Corner(DiscordBtn,7); Stroke(DiscordBtn,C.Border,1)

local PasteBtn = New("TextButton", {
    Size=UDim2.new(0,72,0,28), Position=UDim2.new(0.5,-32,0.62,0),
    BackgroundColor3=C.BG_Card, Text="📋 Paste",
    TextColor3=C.TextMain, TextSize=11, Font=Enum.Font.GothamBold, BorderSizePixel=0,
}, KeyScreen)
Corner(PasteBtn,7); Stroke(PasteBtn,C.Border,1)

local EnterBtn = New("TextButton", {
    Size=UDim2.new(0,72,0,28), Position=UDim2.new(0.5,48,0.62,0),
    BackgroundColor3=C.Accent, Text="▶ Enter",
    TextColor3=Color3.fromRGB(255,200,200), TextSize=11,
    Font=Enum.Font.GothamBold, BorderSizePixel=0,
}, KeyScreen)
Corner(EnterBtn,7)

local KStatus = New("TextLabel", {
    Size=UDim2.new(0,340,0,22), Position=UDim2.new(0.5,-170,0.7,0),
    BackgroundTransparency=1, Text="Enter key to proceed...",
    TextColor3=C.TextDim, TextSize=11, Font=Enum.Font.Gotham,
}, KeyScreen)

task.spawn(function()
    while flickLbl and flickLbl.Parent do
        task.wait(math.random(2,5))
        for _ = 1,2 do
            flickLbl.TextTransparency=0.7; task.wait(0.08)
            flickLbl.TextTransparency=0; task.wait(0.08)
        end
    end
end)

DiscordBtn.MouseButton1Click:Connect(function()
    pcall(function() setclipboard("https://discord.gg/xCV9Tf4y5N") end)
    DiscordBtn.Text="✓ Copied!"; DiscordBtn.BackgroundColor3=C.Green
    task.wait(2); DiscordBtn.Text="💬 Get Key (Discord)"; DiscordBtn.BackgroundColor3=C.AccentDim
end)
PasteBtn.MouseButton1Click:Connect(function()
    local ok,cb=pcall(getclipboard)
    if ok and cb and cb~="" then KInput.Text=cb end
end)

-- ═══════════════════════════
--        MAIN GUI
-- ═══════════════════════════
local function BuildMain()
    KeyScreen:Destroy()

    local Win = New("Frame", {
        Size=UDim2.new(0,600,0,450),
        Position=UDim2.new(0.5,-300,0.5,-225),
        BackgroundColor3=C.BG_Main, BorderSizePixel=0, Active=true,
    }, GUI)
    Corner(Win,12); Stroke(Win,C.Blood,1.5)

    local drag,dStart,dPos=false,nil,nil
    Win.InputBegan:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 then
            drag=true; dStart=i.Position; dPos=Win.Position
        end
    end)
    UserInputService.InputChanged:Connect(function(i)
        if drag and i.UserInputType==Enum.UserInputType.MouseMovement then
            local d=i.Position-dStart
            Win.Position=UDim2.new(dPos.X.Scale,dPos.X.Offset+d.X,dPos.Y.Scale,dPos.Y.Offset+d.Y)
        end
    end)
    UserInputService.InputEnded:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 then drag=false end
    end)

    local Top=New("Frame",{Size=UDim2.new(1,0,0,40),BackgroundColor3=C.BG_Side,BorderSizePixel=0,ZIndex=5},Win)
    Corner(Top,12)
    New("Frame",{Size=UDim2.new(1,0,0.5,0),Position=UDim2.new(0,0,0.5,0),BackgroundColor3=C.BG_Side,BorderSizePixel=0,ZIndex=4},Top)
    New("TextLabel",{Size=UDim2.new(0,30,1,0),Position=UDim2.new(0,8,0,0),BackgroundTransparency=1,Text="💀",TextSize=20,ZIndex=6},Top)
    New("TextLabel",{Size=UDim2.new(0,240,1,0),Position=UDim2.new(0,40,0,0),BackgroundTransparency=1,Text="H4ll0 W0rld Hub V3",TextColor3=C.Accent,TextXAlignment=Enum.TextXAlignment.Left,TextSize=13,Font=Enum.Font.GothamBold,ZIndex=6},Top)

    -- V3 badge
    local tb=New("Frame",{Size=UDim2.new(0,50,0,20),Position=UDim2.new(0,284,0.5,-10),BackgroundColor3=Color3.fromRGB(20,5,30),BorderSizePixel=0,ZIndex=6},Top)
    Corner(tb,5); Stroke(tb,C.Purple,1)
    New("TextLabel",{Size=UDim2.new(1,0,1,0),BackgroundTransparency=1,Text="⚡ V3",TextColor3=C.Purple,TextSize=10,Font=Enum.Font.GothamBold,ZIndex=7},tb)

    local MinBtn=New("TextButton",{Size=UDim2.new(0,26,0,20),Position=UDim2.new(1,-60,0.5,-10),BackgroundColor3=C.BG_Card,Text="─",TextColor3=C.TextMain,TextSize=13,Font=Enum.Font.GothamBold,BorderSizePixel=0,ZIndex=6},Top)
    Corner(MinBtn,5)
    local CloseBtn=New("TextButton",{Size=UDim2.new(0,26,0,20),Position=UDim2.new(1,-28,0.5,-10),BackgroundColor3=C.Blood,Text="✕",TextColor3=Color3.fromRGB(255,200,200),TextSize=12,Font=Enum.Font.GothamBold,BorderSizePixel=0,ZIndex=6},Top)
    Corner(CloseBtn,5)

    CloseBtn.MouseButton1Click:Connect(function()
        StopAll(); ClearESP()
        Tween(Win,{Size=UDim2.new(0,600,0,0)},0.3)
        task.wait(0.35); GUI:Destroy()
    end)
    MinBtn.MouseButton1Click:Connect(function()
        Minimized=not Minimized
        if Minimized then Tween(Win,{Size=UDim2.new(0,600,0,40)},0.3); MinBtn.Text="□"
        else Tween(Win,{Size=UDim2.new(0,600,0,450)},0.3); MinBtn.Text="─" end
    end)

    local CH=New("Frame",{Size=UDim2.new(1,0,1,-40),Position=UDim2.new(0,0,0,40),BackgroundTransparency=1,ClipsDescendants=true},Win)
    local Side=New("Frame",{Size=UDim2.new(0,130,1,0),BackgroundColor3=C.BG_Side,BorderSizePixel=0},CH)
    Stroke(Side,C.Border,1)
    New("UIListLayout",{Padding=UDim.new(0,4)},Side)
    New("UIPadding",{PaddingTop=UDim.new(0,8),PaddingLeft=UDim.new(0,6),PaddingRight=UDim.new(0,6)},Side)

    local CA=New("Frame",{Size=UDim2.new(1,-130,1,0),Position=UDim2.new(0,130,0,0),BackgroundColor3=C.BG_Content,BorderSizePixel=0,ClipsDescendants=true},CH)
    New("UIPadding",{PaddingAll=UDim.new(0,10)},CA)

    local Pages,TabBtns={},{}

    local function MakePage(name)
        local pg=New("ScrollingFrame",{Name=name,Size=UDim2.new(1,0,1,0),BackgroundTransparency=1,BorderSizePixel=0,ScrollBarThickness=3,ScrollBarImageColor3=C.Accent,CanvasSize=UDim2.new(0,0,0,0),Visible=false},CA)
        local ll=New("UIListLayout",{Padding=UDim.new(0,6)},pg)
        ll:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            pg.CanvasSize=UDim2.new(0,0,0,ll.AbsoluteContentSize.Y+16)
        end)
        Pages[name]=pg; return pg
    end

    local function SetTab(name)
        for n,pg in pairs(Pages) do pg.Visible=(n==name) end
        for n,btn in pairs(TabBtns) do
            if n==name then
                Tween(btn,{BackgroundColor3=C.AccentDim},0.2)
                btn.BackgroundTransparency=0; btn.TextColor3=C.Accent
            else
                btn.BackgroundTransparency=1; btn.TextColor3=C.TextSub
            end
        end
    end

    for _,t in ipairs({{"Combat","💀"},{"1v1","⚡"},{"Visual","👁"},{"Settings","⚙"}}) do
        MakePage(t[1])
        local btn=New("TextButton",{Size=UDim2.new(1,0,0,32),BackgroundTransparency=1,BackgroundColor3=C.BG_Side,Text=t[2].."  "..t[1],TextColor3=C.TextSub,TextXAlignment=Enum.TextXAlignment.Left,TextSize=12,Font=Enum.Font.GothamBold,BorderSizePixel=0},Side)
        Corner(btn,7); New("UIPadding",{PaddingLeft=UDim.new(0,8)},btn)
        TabBtns[t[1]]=btn
        btn.MouseButton1Click:Connect(function() SetTab(t[1]) end)
    end

    local function Section(parent,txt,col)
        local f=New("Frame",{Size=UDim2.new(1,0,0,20),BackgroundTransparency=1},parent)
        New("TextLabel",{Size=UDim2.new(1,0,1,0),BackgroundTransparency=1,Text="  ▸  "..txt,TextColor3=col or C.Accent,TextXAlignment=Enum.TextXAlignment.Left,TextSize=10,Font=Enum.Font.GothamBold},f)
    end

    local function Toggle(parent,label,key,desc,col)
        local card=New("Frame",{Size=UDim2.new(1,0,0,desc and 52 or 40),BackgroundColor3=C.BG_Card,BorderSizePixel=0},parent)
        Corner(card,8); Stroke(card,C.Border,1)
        New("TextLabel",{Size=UDim2.new(1,-70,0,20),Position=UDim2.new(0,10,0,5),BackgroundTransparency=1,Text=label,TextColor3=C.TextMain,TextXAlignment=Enum.TextXAlignment.Left,TextSize=12,Font=Enum.Font.GothamBold},card)
        if desc then New("TextLabel",{Size=UDim2.new(1,-70,0,16),Position=UDim2.new(0,10,0,26),BackgroundTransparency=1,Text=desc,TextColor3=C.TextDim,TextXAlignment=Enum.TextXAlignment.Left,TextSize=10,Font=Enum.Font.Gotham},card) end
        local onCol=col or C.ON
        local tb2=New("TextButton",{Size=UDim2.new(0,46,0,22),Position=UDim2.new(1,-54,0.5,-11),BackgroundColor3=C.OFF,Text="",BorderSizePixel=0},card)
        Corner(tb2,11)
        local circ=New("Frame",{Size=UDim2.new(0,16,0,16),Position=UDim2.new(0,3,0.5,-8),BackgroundColor3=Color3.fromRGB(255,220,220),BorderSizePixel=0},tb2)
        Corner(circ,8)
        tb2.MouseButton1Click:Connect(function()
            Toggles[key]=not Toggles[key]
            Tween(tb2,{BackgroundColor3=Toggles[key] and onCol or C.OFF},0.2)
            Tween(circ,{Position=Toggles[key] and UDim2.new(0,27,0.5,-8) or UDim2.new(0,3,0.5,-8)},0.2)
            pcall(function() ApplyFeature(key,Toggles[key]) end)
        end)
    end

    local function Btn(parent,label,col,fn)
        local b=New("TextButton",{Size=UDim2.new(1,0,0,34),BackgroundColor3=col or C.BG_Card,Text=label,TextColor3=col and Color3.fromRGB(255,200,200) or C.TextMain,TextSize=12,Font=Enum.Font.GothamBold,BorderSizePixel=0},parent)
        Corner(b,8); if not col then Stroke(b,C.Border,1) end
        b.MouseButton1Click:Connect(function()
            pcall(fn); b.BackgroundColor3=C.Green
            task.wait(0.5); b.BackgroundColor3=col or C.BG_Card
        end)
        return b
    end

    local function Slider(parent,label,min,max,def,fn,suffix)
        local card=New("Frame",{Size=UDim2.new(1,0,0,62),BackgroundColor3=C.BG_Card,BorderSizePixel=0},parent)
        Corner(card,8); Stroke(card,C.Border,1)
        New("TextLabel",{Size=UDim2.new(1,0,0,20),Position=UDim2.new(0,10,0,5),BackgroundTransparency=1,Text=label,TextColor3=C.TextMain,TextXAlignment=Enum.TextXAlignment.Left,TextSize=12,Font=Enum.Font.GothamBold},card)
        local vl=New("TextLabel",{Size=UDim2.new(0,60,0,20),Position=UDim2.new(1,-65,0,5),BackgroundTransparency=1,Text=tostring(def)..(suffix or ""),TextColor3=C.Gold,TextXAlignment=Enum.TextXAlignment.Right,TextSize=11,Font=Enum.Font.GothamBold},card)
        local pct=(def-min)/(max-min)
        local bg=New("Frame",{Size=UDim2.new(1,-20,0,8),Position=UDim2.new(0,10,0,36),BackgroundColor3=C.BG_Main,BorderSizePixel=0},card); Corner(bg,4)
        local fill=New("Frame",{Size=UDim2.new(pct,0,1,0),BackgroundColor3=C.Accent,BorderSizePixel=0},bg); Corner(fill,4)
        local thumb=New("Frame",{Size=UDim2.new(0,16,0,16),Position=UDim2.new(pct,-8,0.5,-8),BackgroundColor3=Color3.fromRGB(255,200,200),BorderSizePixel=0},bg); Corner(thumb,8)
        local sliding=false
        bg.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then sliding=true end end)
        UserInputService.InputEnded:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then sliding=false end end)
        UserInputService.InputChanged:Connect(function(i)
            if sliding and (i.UserInputType==Enum.UserInputType.MouseMovement or i.UserInputType==Enum.UserInputType.Touch) then
                local rel=math.clamp((i.Position.X-bg.AbsolutePosition.X)/bg.AbsoluteSize.X,0,1)
                local v=math.floor(min+(max-min)*rel)
                vl.Text=tostring(v)..(suffix or ""); fill.Size=UDim2.new(rel,0,1,0); thumb.Position=UDim2.new(rel,-8,0.5,-8)
                pcall(fn,v)
            end
        end)
    end

    -- ══════════════════
    --   💀 COMBAT TAB
    -- ══════════════════
    local CP=Pages["Combat"]
    Section(CP,"AIMBOT")
    Toggle(CP,"Aimbot","Aimbot","Camera-only aim, body tidak gerak")
    Toggle(CP,"Strong Lock","StrongLock","Lock kamera ke 1 target terus")

    -- Aim Part
    local aimCard=New("Frame",{Size=UDim2.new(1,0,0,52),BackgroundColor3=C.BG_Card,BorderSizePixel=0},CP)
    Corner(aimCard,8); Stroke(aimCard,C.Border,1)
    New("TextLabel",{Size=UDim2.new(1,0,0,20),Position=UDim2.new(0,10,0,4),BackgroundTransparency=1,Text="🎯 Aim Part",TextColor3=C.TextMain,TextXAlignment=Enum.TextXAlignment.Left,TextSize=12,Font=Enum.Font.GothamBold},aimCard)
    local aimStatus=New("TextLabel",{Size=UDim2.new(1,0,0,14),Position=UDim2.new(0,10,0,26),BackgroundTransparency=1,Text="Target: HEAD 💀",TextColor3=C.Gold,TextXAlignment=Enum.TextXAlignment.Left,TextSize=10,Font=Enum.Font.GothamBold},aimCard)
    local headBtn=New("TextButton",{Size=UDim2.new(0,60,0,22),Position=UDim2.new(1,-130,0.5,-11),BackgroundColor3=C.Accent,Text="Head",TextColor3=Color3.fromRGB(255,200,200),TextSize=10,Font=Enum.Font.GothamBold,BorderSizePixel=0},aimCard); Corner(headBtn,5)
    local bodyBtn=New("TextButton",{Size=UDim2.new(0,60,0,22),Position=UDim2.new(1,-64,0.5,-11),BackgroundColor3=C.BG_Card,Text="Body",TextColor3=C.TextSub,TextSize=10,Font=Enum.Font.GothamBold,BorderSizePixel=0},aimCard); Corner(bodyBtn,5); Stroke(bodyBtn,C.Border,1)
    headBtn.MouseButton1Click:Connect(function()
        Settings.AimPart="Head"; aimStatus.Text="Target: HEAD 💀"
        headBtn.BackgroundColor3=C.Accent; headBtn.TextColor3=Color3.fromRGB(255,200,200)
        bodyBtn.BackgroundColor3=C.BG_Card; bodyBtn.TextColor3=C.TextSub
    end)
    bodyBtn.MouseButton1Click:Connect(function()
        Settings.AimPart="UpperTorso"; aimStatus.Text="Target: BODY 🏃"
        bodyBtn.BackgroundColor3=C.Accent; bodyBtn.TextColor3=Color3.fromRGB(255,200,200)
        headBtn.BackgroundColor3=C.BG_Card; headBtn.TextColor3=C.TextSub
    end)

    Slider(CP,"🎯 FOV Radius",50,500,150,function(v) Settings.FOV=v end," px")
    Slider(CP,"⚡ Aim Speed",1,30,8,function(v) Settings.AimSpeed=v end,"")

    Section(CP,"UTILITY")
    Toggle(CP,"WallCheck","WallCheck","Cek musuh di balik tembok",C.Gold)
    Toggle(CP,"NoClip","NoClip","Jalan menembus tembok")

    -- ══════════════════
    --   ⚡ 1V1 TAB
    -- ══════════════════
    local OP=Pages["1v1"]
    Section(OP,"AUTO 1V1 DETECT",C.Purple)
    Toggle(OP,"Auto 1v1 Detect","Auto1v1","Auto detect & lock target 1v1",C.Purple)

    -- Target info card
    local tCard=New("Frame",{Size=UDim2.new(1,0,0,72),BackgroundColor3=C.BG_Card,BorderSizePixel=0},OP)
    Corner(tCard,8); Stroke(tCard,C.Purple,1.5)

    targetNameLbl=New("TextLabel",{
        Size=UDim2.new(1,-16,0,22),Position=UDim2.new(0,8,0,6),
        BackgroundTransparency=1,Text="🎯 Tidak ada target",
        TextColor3=C.Purple,TextXAlignment=Enum.TextXAlignment.Left,
        TextSize=13,Font=Enum.Font.GothamBold,
    },tCard)
    targetDistLbl=New("TextLabel",{
        Size=UDim2.new(0.5,-8,0,18),Position=UDim2.new(0,8,0,30),
        BackgroundTransparency=1,Text="📏 -",
        TextColor3=C.Gold,TextXAlignment=Enum.TextXAlignment.Left,
        TextSize=11,Font=Enum.Font.Gotham,
    },tCard)
    targetIdxLbl=New("TextLabel",{
        Size=UDim2.new(0.5,-8,0,18),Position=UDim2.new(0.5,0,0,30),
        BackgroundTransparency=1,Text="[0/0]",
        TextColor3=C.TextDim,TextXAlignment=Enum.TextXAlignment.Right,
        TextSize=11,Font=Enum.Font.GothamBold,
    },tCard)

    -- Player list untuk switch target
    Section(OP,"PLAYER LIST",C.Purple)
    local plrListCard=New("Frame",{Size=UDim2.new(1,0,0,100),BackgroundColor3=C.BG_Card,BorderSizePixel=0},OP)
    Corner(plrListCard,8); Stroke(plrListCard,C.Border,1)
    New("TextLabel",{Size=UDim2.new(1,0,0,20),Position=UDim2.new(0,10,0,4),BackgroundTransparency=1,Text="👥 Pilih Target dari List",TextColor3=C.TextMain,TextXAlignment=Enum.TextXAlignment.Left,TextSize=12,Font=Enum.Font.GothamBold},plrListCard)

    local plrList=New("ScrollingFrame",{
        Size=UDim2.new(1,-20,0,48),Position=UDim2.new(0,10,0,26),
        BackgroundColor3=C.BG_Main,BorderSizePixel=0,
        ScrollBarThickness=3,ScrollBarImageColor3=C.Purple,
        CanvasSize=UDim2.new(0,0,0,0),
    },plrListCard)
    Corner(plrList,5)
    local plrListLayout=New("UIListLayout",{FillDirection=Enum.FillDirection.Horizontal,Padding=UDim.new(0,4)},plrList)

    local function RefreshPlayerList()
        for _,c in ipairs(plrList:GetChildren()) do
            if c:IsA("TextButton") then c:Destroy() end
        end
        RefreshTargetList()
        for i, plr in ipairs(TargetList) do
            local b=New("TextButton",{
                Size=UDim2.new(0,80,0,42),
                BackgroundColor3=CurrentTarget==plr and C.Purple or C.BG_Card,
                Text=plr.Name,
                TextColor3=CurrentTarget==plr and Color3.fromRGB(255,220,255) or C.TextMain,
                TextSize=9,Font=Enum.Font.GothamBold,BorderSizePixel=0,
            },plrList)
            Corner(b,5); Stroke(b,CurrentTarget==plr and C.Purple or C.Border,1)
            b.MouseButton1Click:Connect(function()
                TargetIndex=i
                CurrentTarget=plr
                -- Update visual
                for _,btn in ipairs(plrList:GetChildren()) do
                    if btn:IsA("TextButton") then
                        btn.BackgroundColor3=C.BG_Card
                        btn.TextColor3=C.TextMain
                        Stroke(btn,C.Border,1)
                    end
                end
                b.BackgroundColor3=C.Purple
                b.TextColor3=Color3.fromRGB(255,220,255)
                Stroke(b,C.Purple,1)
                UpdateTargetUI()
            end)
        end
        plrListLayout:ApplyLayout()
        plrList.CanvasSize=UDim2.new(0,plrListLayout.AbsoluteContentSize.X+10,0,0)
    end

    RefreshPlayerList()
    Btn(plrListCard,"🔄 Refresh Player List",nil,RefreshPlayerList)

    -- Switch & Refresh buttons
    local switchBtn=New("TextButton",{
        Size=UDim2.new(1,0,0,36),
        BackgroundColor3=C.Purple,
        Text="🔄 Switch Target",
        TextColor3=Color3.fromRGB(255,220,255),
        TextSize=13,Font=Enum.Font.GothamBold,BorderSizePixel=0,
    },OP)
    Corner(switchBtn,8)
    switchBtn.MouseButton1Click:Connect(function()
        SwitchTarget()
        RefreshPlayerList()
        UpdateTargetUI()
        -- Flash button
        switchBtn.BackgroundColor3=C.Green
        task.wait(0.3)
        switchBtn.BackgroundColor3=C.Purple
    end)

    -- Auto refresh player list when players join/leave
    Players.PlayerAdded:Connect(function() RefreshPlayerList() end)
    Players.PlayerRemoving:Connect(function() RefreshPlayerList() end)

    -- ══════════════════
    --   👁 VISUAL TAB
    -- ══════════════════
    local VP=Pages["Visual"]
    Section(VP,"ESP")
    Toggle(VP,"ESP + Highlight","ESP","🎯 Purple = Target 1v1 | 🔴 Merah = Player lain",C.Accent)
    Section(VP,"MOVEMENT")
    Toggle(VP,"Speed Hack","SpeedHack","WalkSpeed custom")
    Slider(VP,"🏃 Walk Speed",16,250,16,function(v)
        Settings.WalkSpeed=v
        local _,_,hum=GetChar()
        if hum and Toggles.SpeedHack then hum.WalkSpeed=v end
    end,"")
    Toggle(VP,"Fly","Fly","Terbang (W/S/Space)")
    Slider(VP,"✈️ Fly Speed",10,150,40,function(v) Settings.FlySpeed=v end,"")

    -- ══════════════════
    --   ⚙ SETTINGS TAB
    -- ══════════════════
    local SETP=Pages["Settings"]
    Section(SETP,"PERFORMANCE")
    Btn(SETP,"🚀 Boost FPS",C.AccentDim,function()
        for _,obj in ipairs(workspace:GetDescendants()) do
            pcall(function()
                if obj:IsA("ParticleEmitter") or obj:IsA("Smoke") or
                   obj:IsA("Fire") or obj:IsA("Sparkles") then
                    obj.Enabled=false
                end
            end)
        end
    end)
    Btn(SETP,"☀️ Full Bright",C.AccentDim,function()
        local L=game:GetService("Lighting")
        L.Brightness=10; L.ClockTime=14; L.FogEnd=1e6; L.GlobalShadows=false
    end)
    Section(SETP,"SERVER")
    Btn(SETP,"🔄 Rejoin Server",C.AccentDim,function()
        game:GetService("TeleportService"):Teleport(game.PlaceId,LocalPlayer)
    end)
    Section(SETP,"ABOUT")
    local about=New("Frame",{Size=UDim2.new(1,0,0,80),BackgroundColor3=C.BG_Card,BorderSizePixel=0},SETP)
    Corner(about,8); Stroke(about,C.Blood,1.5)
    New("TextLabel",{Size=UDim2.new(1,-16,1,0),Position=UDim2.new(0,8,0,0),BackgroundTransparency=1,
        Text="💀  H4ll0 W0rld Hub V3  v2.0\nFix: Switch target semua player\nKey    : Hello_world123\nDiscord: discord.gg/xCV9Tf4y5N",
        TextColor3=C.TextSub,TextXAlignment=Enum.TextXAlignment.Left,TextSize=11,TextWrapped=true,Font=Enum.Font.Gotham},about)

    local stopBtn=New("TextButton",{Size=UDim2.new(1,0,0,36),BackgroundColor3=C.Blood,Text="⛔  Stop All Features",TextColor3=Color3.fromRGB(255,200,200),TextSize=12,Font=Enum.Font.GothamBold,BorderSizePixel=0},SETP)
    Corner(stopBtn,8)
    stopBtn.MouseButton1Click:Connect(function()
        StopAll(); ClearESP()
        for k in pairs(Toggles) do Toggles[k]=false end
        stopBtn.Text="✅ All Stopped"; task.wait(2); stopBtn.Text="⛔  Stop All Features"
    end)

    SetTab("Combat")
    RefreshTargetList()
end

-- ═══════════════════════════
--      KEY VALIDATION
-- ═══════════════════════════
EnterBtn.MouseButton1Click:Connect(function()
    if KInput.Text==VALID_KEY then
        KStatus.Text="✅ Key Valid! Loading..."; KStatus.TextColor3=C.Green
        for _,obj in ipairs(KeyScreen:GetDescendants()) do
            pcall(function()
                if obj:IsA("TextLabel") or obj:IsA("TextButton") then Tween(obj,{TextTransparency=1},0.3) end
                if obj:IsA("Frame") then Tween(obj,{BackgroundTransparency=1},0.3) end
            end)
        end
        Tween(KeyScreen,{BackgroundTransparency=1},0.3)
        task.wait(0.5); BuildMain()
    else
        KStatus.Text="❌ Key salah! Join Discord untuk key."; KStatus.TextColor3=C.Accent
        Tween(KBG,{BackgroundColor3=Color3.fromRGB(40,8,8)},0.2)
        task.wait(0.3); Tween(KBG,{BackgroundColor3=C.BG_Card},0.2)
    end
end)

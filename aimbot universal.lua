-- QeeHacker Client (PC/Laptop Only - V10.1 - SYNTAX FIX + BRIGHTNESS FIX + PROTECTED GUI)
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")
local SoundService = game:GetService("SoundService")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

-- [CONFIG & GLOBAL VARS]
local Settings = { 
    Enabled = false, AimStyle = "OFF", AimMode = "Hold Aim", AWMMode = false, 
    TriggerBot = false, TeamCheck = true, WallCheck = false, TargetMode = "Body", 
    ESP = false, 
    WarningEnabled = false, AutoKill = false, AntiLag = false, 
    ShowFOV = false, Smoothness = 0.5, FOV = 160, MaxRange = 1200, BulletSpeed = 1000,
    TpKey = Enum.KeyCode.T, UIVisible = false, 
    ThemeColor = Color3.fromRGB(0, 255, 80), IsRainbow = false,
    FlyEnabled = false, FlySpeed = 80, FlyKey = Enum.KeyCode.F,
    CustomCrosshair = false, GhostHack = false,
    SilentAim = false, SilentFOV = 120, SilentTarget = "Body", ShowSilentFOV = false,
    AimPlayers = true, AimBots = true
}

local CurrentTarget = nil; local SilentTarget = nil; local DraggingSlider = nil
local EspObjects = {}; local CachedTargets = {}; local LastScanTime = 0; local LastTriggerClick = 0
local originalTransparencies = {} 

local CachedSilentHit = nil
local CachedSilentTargetPart = nil

local function getRootPart(m, targetMode)
    if not m then return nil end
    if (targetMode or Settings.TargetMode) == "Head" then 
        return m:FindFirstChild("Head") or m:FindFirstChild("HumanoidRootPart") or m.PrimaryPart 
    end
    return m:FindFirstChild("HumanoidRootPart") or m:FindFirstChild("UpperTorso") or m:FindFirstChild("Torso") or m:FindFirstChild("Head") or m.PrimaryPart 
end

local function getPredictedPosition(part, bulletSpeed)
    local root = part.Parent and part.Parent:FindFirstChild("HumanoidRootPart")
    local vel = root and root.AssemblyLinearVelocity or Vector3.zero
    local dist = (part.Position - Camera.CFrame.Position).Magnitude
    return part.Position + vel * (dist / math.max(bulletSpeed or Settings.BulletSpeed, 1))
end

-- [BYPASS & ANTI-KICK + SILENT AIM HOOK (V10 FIX)]
pcall(function()
    local mt = getrawmetatable(game)
    local oldNamecall = mt.__namecall
    local oldIndex = mt.__index
    setreadonly(mt, false)

    mt.__namecall = newcclosure(function(self, ...)
        local method = getnamecallmethod()
        if method == "Kick" and self == LocalPlayer then return nil end
        
        if Settings.SilentAim and Settings.Enabled and CachedSilentHit and not checkcaller() then
            local args = {...}
            local isRaycast = (method == "Raycast")
            local isRayMethod = (method == "FindPartOnRayWithIgnoreList" or method == "FindPartOnRay" or method == "FindPartOnRayWithWhitelist")
            
            if isRaycast or isRayMethod then
                local origin, direction
                if isRaycast then origin = args[1]; direction = args[2]
                else
                    local r = args[1]
                    if r and typeof(r) == "Ray" then origin = r.Origin; direction = r.Direction end
                end
                
                if origin and direction and direction.Magnitude > 50 then
                    local targetPos = CachedSilentHit.Position
                    local newDir = (targetPos - origin)
                    if newDir.Magnitude > 0 then
                        if isRaycast then args[2] = newDir.Unit * direction.Magnitude
                        else args[1] = Ray.new(origin, newDir.Unit * direction.Magnitude) end
                        return oldNamecall(self, table.unpack(args))
                    end
                end
            end
        end
        return oldNamecall(self, ...)
    end)

    mt.__index = newcclosure(function(self, key)
        if Settings.SilentAim and Settings.Enabled and CachedSilentHit and typeof(self) == "Instance" and self:IsA("Mouse") then
            if key == "Hit" then return CachedSilentHit
            elseif key == "Target" or key == "target" then return CachedSilentTargetPart end
        end
        return oldIndex(self, key)
    end)
    setreadonly(mt, true)
end)

local function playSFX(id)
    pcall(function()
        local s = Instance.new("Sound"); s.SoundId = id; s.Volume = 0.5; s.Parent = SoundService; s:Play()
        task.delay(5, function() s:Destroy() end)
    end)
end

local function OptimizeGame()
    pcall(function()
        settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
        Lighting.GlobalShadows = false; Lighting.FogEnd = 9e9
        for _, v in ipairs(Workspace:GetDescendants()) do
            if v:IsA("Part") or v:IsA("UnionOperation") or v:IsA("MeshPart") then v.Material = Enum.Material.SmoothPlastic; v.Reflectance = 0
            elseif v:IsA("Decal") or v:IsA("Texture") then v:Destroy()
            elseif v:IsA("ParticleEmitter") or v:IsA("Trail") then v.Enabled = false end
        end
    end)
end

-- [FIX: UI Parent Proteksi Biar Ga Di-Delete Game]
local uiParent
pcall(function()
    if gethui then uiParent = gethui()
    elseif syn and syn.protect_gui then uiParent = game:GetService("CoreGui")
    else uiParent = LocalPlayer:WaitForChild("PlayerGui") end
end)
if not uiParent then uiParent = LocalPlayer:WaitForChild("PlayerGui") end

local PASSWORD = "Qee Only"

local PassGui = Instance.new("ScreenGui", uiParent); PassGui.Name = "RbxAuth"; PassGui.ResetOnSpawn = false; PassGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling; PassGui.DisplayOrder = 9999
local PassFrame = Instance.new("Frame", PassGui); PassFrame.Size = UDim2.new(0, 300, 0, 150); PassFrame.Position = UDim2.new(0.5, 0, 0.5, 0); PassFrame.AnchorPoint = Vector2.new(0.5, 0.5); PassFrame.BackgroundColor3 = Color3.fromRGB(28, 28, 38); PassFrame.BorderSizePixel = 0; PassFrame.ClipsDescendants = true; PassFrame.Active = true
Instance.new("UICorner", PassFrame).CornerRadius = UDim.new(0, 8)
local PassStroke = Instance.new("UIStroke", PassFrame); PassStroke.Color = Color3.fromRGB(0, 255, 150); PassStroke.Thickness = 2.5; PassStroke.Transparency = 0
local PassTitle = Instance.new("TextLabel", PassFrame); PassTitle.Size = UDim2.new(1, 0, 0, 40); PassTitle.BackgroundTransparency = 1; PassTitle.Font = Enum.Font.GothamBlack; PassTitle.TextSize = 20; PassTitle.TextColor3 = Color3.fromRGB(100, 255, 150); PassTitle.Text = "QeeHacker Authentication"
local PassBox = Instance.new("TextBox", PassFrame); PassBox.Size = UDim2.new(1, -40, 0, 35); PassBox.Position = UDim2.new(0, 20, 0, 55); PassBox.BackgroundColor3 = Color3.fromRGB(42, 42, 55); PassBox.BorderSizePixel = 0; PassBox.Font = Enum.Font.GothamMedium; PassBox.TextSize = 14; PassBox.TextColor3 = Color3.fromRGB(230, 230, 240); PassBox.PlaceholderText = "Enter Password..."; PassBox.PlaceholderColor3 = Color3.fromRGB(150, 150, 170); PassBox.ClearTextOnFocus = false
Instance.new("UICorner", PassBox).CornerRadius = UDim.new(0, 5)
local PassBtn = Instance.new("TextButton", PassFrame); PassBtn.Size = UDim2.new(1, -40, 0, 35); PassBtn.Position = UDim2.new(0, 20, 0, 100); PassBtn.BackgroundColor3 = Color3.fromRGB(0, 210, 90); PassBtn.BorderSizePixel = 0; PassBtn.Font = Enum.Font.GothamBold; PassBtn.TextSize = 14; PassBtn.TextColor3 = Color3.fromRGB(12, 12, 16); PassBtn.Text = "LOGIN"
Instance.new("UICorner", PassBtn).CornerRadius = UDim.new(0, 5)

local function MakeDrag(dragHandle, dragTarget)
    local dragging, dragInput, dragStart, startPos
    dragHandle.InputBegan:Connect(function(input) 
        if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = true; dragStart = input.Position; startPos = dragTarget.Position 
            input.Changed:Connect(function() if input.UserInputState == Enum.UserInputState.End then dragging = false end end) 
        end 
    end)
    dragHandle.InputChanged:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseMovement then dragInput = input end end)
    UserInputService.InputChanged:Connect(function(input) 
        if input == dragInput and dragging then local delta = input.Position - dragStart; dragTarget.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y) end 
    end)
end

MakeDrag(PassFrame, PassFrame)

local function InitializeHack()
    PassGui:Destroy()
    
    local OldGui = uiParent:FindFirstChild("CoreUI_v2")
    if OldGui then pcall(function() OldGui:Destroy() end) end

    local Gui = Instance.new("ScreenGui", uiParent)
    Gui.Name = "CoreUI_v2"; Gui.ResetOnSpawn = false; Gui.IgnoreGuiInset = true; Gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling; Gui.DisplayOrder = 9999

    local MasterBtn, MasterInd, AimBtn, AimInd, AimModeBtn, TriggerBtn, TriggerInd, AutoKillBtn, AutoKillInd, TargetBtn, TeamBtn, TeamInd, WallBtn, WallInd, EspBtn, EspInd, WarningBtn, WarningInd, FovBtn, FovInd, CrosshairBtn, CrossInd, FlyBtn, FlyInd, AntiLagBtn, AntiLagInd, AWMModeBtn, AWMModeInd, GhostBtn, GhostInd, SilentBtn, SilentInd, SilentTargetBtn, SilentFovBtn, SilentFovInd, TargetPlayerBtn, TargetPlayerInd, TargetBotBtn, TargetBotInd = nil
    local FOVCircleStroke, SilentFOVCircleStroke = nil, nil

    -- [FIX: Brighter Background & Thick Stroke Anti-Gelap]
    local Panel = Instance.new("Frame"); Panel.Size = UDim2.fromOffset(270, 560); Panel.Position = UDim2.fromOffset(100, 100); Panel.BackgroundColor3 = Color3.fromRGB(28, 28, 38); Panel.BorderSizePixel = 0; Panel.Parent = Gui; Panel.ClipsDescendants = true; Panel.Visible = false; Panel.Active = true
    Instance.new("UICorner", Panel).CornerRadius = UDim.new(0, 8)
    local PanelStroke = Instance.new("UIStroke", Panel); PanelStroke.Color = Settings.ThemeColor; PanelStroke.Thickness = 2.5; PanelStroke.Transparency = 0

    local Header = Instance.new("Frame"); Header.Size = UDim2.new(1, 0, 0, 45); Header.BackgroundTransparency = 1; Header.Parent = Panel; Header.Active = true
    local CloseBtn = Instance.new("TextButton"); CloseBtn.Size = UDim2.new(0, 30, 0, 30); CloseBtn.Position = UDim2.new(1, -35, 0, 7); CloseBtn.BackgroundColor3 = Color3.fromRGB(255, 50, 50); CloseBtn.BorderSizePixel = 0; CloseBtn.Font = Enum.Font.GothamBold; CloseBtn.TextSize = 14; CloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255); CloseBtn.Text = "X"; CloseBtn.Parent = Header
    Instance.new("UICorner", CloseBtn).CornerRadius = UDim.new(0, 6)
    local Title = Instance.new("TextLabel"); Title.Size = UDim2.new(1, -45, 0, 25); Title.Position = UDim2.fromOffset(12, 8); Title.BackgroundTransparency = 1; Title.Font = Enum.Font.GothamBlack; Title.TextSize = 22; Title.TextColor3 = Settings.ThemeColor; Title.TextXAlignment = Enum.TextXAlignment.Left; Title.Text = "QeeHacker [PC]"; Title.Parent = Header
    local TitleGlowUI = Instance.new("UIStroke", Title); TitleGlowUI.Color = Settings.ThemeColor; TitleGlowUI.Thickness = 1; TitleGlowUI.Transparency = 0.2
    local Status = Instance.new("TextLabel"); Status.Size = UDim2.new(1, -12, 0, 14); Status.Position = UDim2.fromOffset(12, 32); Status.BackgroundTransparency = 1; Status.Font = Enum.Font.Gotham; Status.TextSize = 11; Status.TextColor3 = Color3.fromRGB(180, 180, 200); Status.TextXAlignment = Enum.TextXAlignment.Left; Status.Text = "Hotkeys: RShift=Menu, F=Fly, G=Ghost"; Status.Parent = Header

    MakeDrag(Header, Panel)
    
    local function updateIndicators()
        if not MasterBtn then return end
        local function ind(f, s) f.BackgroundColor3 = s and Settings.ThemeColor or Color3.fromRGB(255, 50, 50) end
        MasterBtn.Text = "  Master: " .. (Settings.Enabled and "ON" or "OFF"); ind(MasterInd, Settings.Enabled)
        AimBtn.Text = "  Aim: " .. Settings.AimStyle; ind(AimInd, Settings.AimStyle ~= "OFF")
        AimModeBtn.Text = "  Aim Mode: " .. Settings.AimMode
        TriggerBtn.Text = "  Auto Shoot: " .. (Settings.TriggerBot and "ON" or "OFF"); ind(TriggerInd, Settings.TriggerBot)
        AutoKillBtn.Text = "  Auto Kill: " .. (Settings.AutoKill and "ON" or "OFF") .. " [RISKY]"; ind(AutoKillInd, Settings.AutoKill)
        TargetBtn.Text = "  Aim Target: " .. Settings.TargetMode
        TeamBtn.Text = "  Team Check: " .. (Settings.TeamCheck and "ON" or "OFF"); ind(TeamInd, Settings.TeamCheck)
        WallBtn.Text = "  Wall Check: " .. (Settings.WallCheck and "ON" or "OFF"); ind(WallInd, Settings.WallCheck)
        EspBtn.Text = "  ESP Box: " .. (Settings.ESP and "ON" or "OFF"); ind(EspInd, Settings.ESP)
        WarningBtn.Text = "  Aim Warning: " .. (Settings.WarningEnabled and "ON" or "OFF"); ind(WarningInd, Settings.WarningEnabled)
        FovBtn.Text = "  Aimbot FOV: " .. (Settings.ShowFOV and "ON" or "OFF"); ind(FovInd, Settings.ShowFOV)
        CrosshairBtn.Text = "  Crosshair: " .. (Settings.CustomCrosshair and "ON" or "OFF"); ind(CrossInd, Settings.CustomCrosshair)
        GhostBtn.Text = "  Ghost [G]: " .. (Settings.GhostHack and "ON" or "OFF"); ind(GhostInd, Settings.GhostHack)
        
        SilentBtn.Text = "  Silent Aim: " .. (Settings.SilentAim and "ON" or "OFF"); ind(SilentInd, Settings.SilentAim)
        SilentTargetBtn.Text = "  Silent Target: " .. Settings.SilentTarget
        SilentFovBtn.Text = "  Silent FOV: " .. (Settings.ShowSilentFOV and "ON" or "OFF"); ind(SilentFovInd, Settings.ShowSilentFOV)
        
        TargetPlayerBtn.Text = "  Target Players: " .. (Settings.AimPlayers and "ON" or "OFF"); ind(TargetPlayerInd, Settings.AimPlayers)
        TargetBotBtn.Text = "  Target Bots: " .. (Settings.AimBots and "ON" or "OFF"); ind(TargetBotInd, Settings.AimBots)
        
        AntiLagBtn.Text = "  Anti-Lag: " .. (Settings.AntiLag and "ON" or "OFF"); ind(AntiLagInd, Settings.AntiLag)
        AWMModeBtn.Text = "  AWM Mode: " .. (Settings.AWMMode and "ON" or "OFF"); ind(AWMModeInd, Settings.AWMMode)
        FlyBtn.Text = "  Fly [F]: " .. (Settings.FlyEnabled and "ON" or "OFF"); ind(FlyInd, Settings.FlyEnabled)
    end

    local function toggleMenu(state) Settings.UIVisible = state; Panel.Visible = state; updateIndicators() end
    CloseBtn.MouseButton1Click:Connect(function() toggleMenu(false) end)

    local ScrollFrame = Instance.new("ScrollingFrame"); ScrollFrame.Size = UDim2.new(1, 0, 1, -45); ScrollFrame.Position = UDim2.fromOffset(0, 45); ScrollFrame.BackgroundTransparency = 1; ScrollFrame.ScrollBarThickness = 4; ScrollFrame.ScrollBarImageColor3 = Settings.ThemeColor; ScrollFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y; ScrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0); ScrollFrame.Parent = Panel
    Instance.new("UIListLayout", ScrollFrame).SortOrder = Enum.SortOrder.LayoutOrder
    local Padding = Instance.new("UIPadding", ScrollFrame); Padding.PaddingLeft = UDim.new(0, 10); Padding.PaddingRight = UDim.new(0, 10); Padding.PaddingTop = UDim.new(0, 5); Padding.PaddingBottom = UDim.new(0, 10)

    local layoutOrder = 0
    local function addCategory(n) local l = Instance.new("Frame"); l.Size = UDim2.new(1, 0, 0, 1); l.BackgroundColor3 = Color3.fromRGB(50, 50, 65); l.BorderSizePixel = 0; l.Parent = ScrollFrame; layoutOrder = layoutOrder + 1; l.LayoutOrder = layoutOrder; local c = Instance.new("TextLabel"); c.Size = UDim2.new(1, 0, 0, 20); c.BackgroundTransparency = 1; c.Font = Enum.Font.GothamBold; c.TextSize = 12; c.TextColor3 = Settings.ThemeColor; c.TextXAlignment = Enum.TextXAlignment.Left; c.Text = string.upper(n); c.Parent = ScrollFrame; layoutOrder = layoutOrder + 1; c.LayoutOrder = layoutOrder end
    local function button(t, cb) local i = Instance.new("TextButton"); i.Size = UDim2.new(1, 0, 0, 30); i.BackgroundColor3 = Color3.fromRGB(40, 42, 58); i.BorderSizePixel = 0; i.Font = Enum.Font.GothamMedium; i.TextSize = 12; i.TextColor3 = Color3.fromRGB(230, 230, 240); i.TextXAlignment = Enum.TextXAlignment.Left; i.Text = "  "..t; i.Parent = ScrollFrame; layoutOrder = layoutOrder + 1; i.LayoutOrder = layoutOrder; Instance.new("UICorner", i).CornerRadius = UDim.new(0, 5); local ind = Instance.new("Frame"); ind.Size = UDim2.new(0, 3, 0.6, 0); ind.Position = UDim2.new(0, 4, 0.2, 0); ind.BackgroundColor3 = Color3.fromRGB(255, 50, 50); ind.BorderSizePixel = 0; ind.Parent = i; Instance.new("UICorner", ind).CornerRadius = UDim.new(0, 2); i.MouseButton1Click:Connect(cb); return i, ind end

    local function applyTheme() pcall(function() PanelStroke.Color = Settings.ThemeColor; Title.TextColor3 = Settings.ThemeColor; ScrollFrame.ScrollBarImageColor3 = Settings.ThemeColor; TitleGlowUI.Color = Settings.ThemeColor; if FOVCircleStroke then FOVCircleStroke.Color = Settings.ThemeColor end; if SilentFOVCircleStroke then SilentFOVCircleStroke.Color = Color3.fromRGB(255, 255, 255) end updateIndicators() end) end
    local function slider(lT, minV, maxV, sN) local c = Instance.new("Frame"); c.Size = UDim2.new(1, 0, 0, 35); c.BackgroundTransparency = 1; c.Parent = ScrollFrame; layoutOrder = layoutOrder + 1; c.LayoutOrder = layoutOrder; local l = Instance.new("TextLabel"); l.Size = UDim2.new(1, 0, 0, 16); l.BackgroundTransparency = 1; l.Font = Enum.Font.Gotham; l.TextSize = 11; l.TextColor3 = Color3.fromRGB(200, 200, 215); l.TextXAlignment = Enum.TextXAlignment.Left; l.Parent = c; local b = Instance.new("TextButton"); b.Size = UDim2.new(1, 0, 0, 14); b.Position = UDim2.fromOffset(0, 18); b.BackgroundColor3 = Color3.fromRGB(50, 50, 65); b.BorderSizePixel = 0; b.Text = ""; b.AutoButtonColor = false; b.Parent = c; local f = Instance.new("Frame"); f.BorderSizePixel = 0; f.BackgroundColor3 = Settings.ThemeColor; f.Parent = b; Instance.new("UICorner", b).CornerRadius = UDim.new(0, 4); Instance.new("UICorner", f).CornerRadius = UDim.new(0, 4); local function sv(v) v = math.clamp(v, minV, maxV); local r = math.floor(v * 100 + 0.5) / 100; local rt = (r - minV) / (maxV - minV); Settings[sN] = r; f.Size = UDim2.new(rt, 0, 1, 0); f.BackgroundColor3 = Settings.ThemeColor; l.Text = lT .. ": " .. tostring(r) end; local function upd() local x = UserInputService:GetMouseLocation().X; local w = b.AbsoluteSize.X; if w > 0 then sv(minV + (maxV - minV) * math.clamp((x - b.AbsolutePosition.X) / w, 0, 1)) end end; b.MouseButton1Down:Connect(function() DraggingSlider = upd; upd(); ScrollFrame.ScrollingEnabled = false end); sv(Settings[sN]) end

    MasterBtn, MasterInd = button("Master: OFF", function() Settings.Enabled = not Settings.Enabled; CurrentTarget = nil; updateIndicators() end)
    
    addCategory("Aimbot (Kamera Gerak)")
    AimBtn, AimInd = button("Aim: OFF", function() if Settings.AimStyle == "OFF" then Settings.AimStyle = "AIMBOT" elseif Settings.AimStyle == "AIMBOT" then Settings.AimStyle = "SMOOTH" else Settings.AimStyle = "OFF" end; CurrentTarget = nil; updateIndicators() end)
    
    -- [FIX FATAL ERROR: 'elseif Settings.AimMode = "Auto"' -> Diganti jadi '==']
    AimModeBtn = button("Aim Mode: Hold Aim", function() if Settings.AimMode == "Hold Aim" then Settings.AimMode = "Auto" elseif Settings.AimMode == "Auto" then Settings.AimMode = "Scope" else Settings.AimMode = "Hold Aim" end; updateIndicators() end)
    
    TargetBtn = button("Aim Target: Body", function() Settings.TargetMode = Settings.TargetMode == "Body" and "Head" or "Body"; CurrentTarget = nil; updateIndicators() end)
    FovBtn, FovInd = button("Aimbot FOV: OFF", function() Settings.ShowFOV = not Settings.ShowFOV; updateIndicators() end)
    
    addCategory("Silent Aim (Peluru Nyasar)")
    SilentBtn, SilentInd = button("Silent Aim: OFF", function() Settings.SilentAim = not Settings.SilentAim; updateIndicators() end)
    SilentTargetBtn = button("Silent Target: Body", function() Settings.SilentTarget = Settings.SilentTarget == "Body" and "Head" or "Body"; updateIndicators() end)
    SilentFovBtn, SilentFovInd = button("Silent FOV: OFF", function() Settings.ShowSilentFOV = not Settings.ShowSilentFOV; updateIndicators() end)
    
    addCategory("Target Filters")
    TargetPlayerBtn, TargetPlayerInd = button("Target Players: ON", function() Settings.AimPlayers = not Settings.AimPlayers; updateIndicators() end)
    TargetBotBtn, TargetBotInd = button("Target Bots: ON", function() Settings.AimBots = not Settings.AimBots; updateIndicators() end)

    addCategory("Combat Assist")
    TriggerBtn, TriggerInd = button("Auto Shoot: OFF", function() Settings.TriggerBot = not Settings.TriggerBot; updateIndicators() end)
    AutoKillBtn, AutoKillInd = button("Auto Kill: OFF [RISKY]", function() Settings.AutoKill = not Settings.AutoKill; if Settings.AutoKill then Settings.TriggerBot = true end; updateIndicators() end)
    TeamBtn, TeamInd = button("Team Check: ON", function() Settings.TeamCheck = not Settings.TeamCheck; CurrentTarget = nil; updateIndicators() end)
    WallBtn, WallInd = button("Wall Check: OFF", function() Settings.WallCheck = not Settings.WallCheck; CurrentTarget = nil; updateIndicators() end)

    addCategory("Visuals")
    EspBtn, EspInd = button("ESP Box: OFF", function() Settings.ESP = not Settings.ESP; updateIndicators() end)
    WarningBtn, WarningInd = button("Aim Warning: OFF", function() Settings.WarningEnabled = not Settings.WarningEnabled; updateIndicators() end) 
    CrosshairBtn, CrossInd = button("Crosshair: OFF", function() Settings.CustomCrosshair = not Settings.CustomCrosshair; updateIndicators() end)
    
    addCategory("Fun / Movement")
    FlyBtn, FlyInd = button("Fly [F]: OFF", function() Settings.FlyEnabled = not Settings.FlyEnabled; updateIndicators() end)
    local function toggleGhost()
        Settings.GhostHack = not Settings.GhostHack 
        if not Settings.GhostHack then 
            for obj, val in pairs(originalTransparencies) do if obj and obj.Parent then obj.Transparency = val; if obj:IsA("BasePart") then obj.LocalTransparencyModifier = 0 end end end
            originalTransparencies = {}
        end
        updateIndicators() 
    end
    GhostBtn, GhostInd = button("Ghost [G]: OFF", toggleGhost)
    
    addCategory("AWM MENU"); AWMModeBtn, AWMModeInd = button("AWM Mode: OFF", function() Settings.AWMMode = not Settings.AWMMode; updateIndicators() end)
    addCategory("Performance")
    AntiLagBtn, AntiLagInd = button("Anti-Lag: OFF", function()
        Settings.AntiLag = not Settings.AntiLag
        if Settings.AntiLag then
            task.spawn(function()
                Lighting.GlobalShadows = false; Lighting.Brightness = 2; Lighting.ClockTime = 14; OptimizeGame()
                local count = 0
                for _, v in ipairs(Workspace:GetDescendants()) do
                    if v:IsA("ParticleEmitter") or v:IsA("Trail") or v:IsA("Smoke") or v:IsA("Fire") or v:IsA("Sparkles") then v.Enabled = false end
                    count = count + 1; if count % 500 == 0 then task.wait() end
                end
                for _, v in ipairs(Lighting:GetChildren()) do if v:IsA("PostEffect") then v.Enabled = false end end
                local t = Workspace:FindFirstChildOfClass("Terrain"); if t then t.WaterWaveSize = 0; t.WaterReflectance = 0 end
            end)
        else Lighting.GlobalShadows = true end
        updateIndicators()
    end)

    addCategory("Theme")
    button("Green Theme", function() Settings.IsRainbow = false; Settings.ThemeColor = Color3.fromRGB(0, 255, 80); applyTheme() end)
    button("Red Theme", function() Settings.IsRainbow = false; Settings.ThemeColor = Color3.fromRGB(255, 50, 50); applyTheme() end)
    button("Blue Theme", function() Settings.IsRainbow = false; Settings.ThemeColor = Color3.fromRGB(80, 150, 255); applyTheme() end)
    button("Purple Theme", function() Settings.IsRainbow = false; Settings.ThemeColor = Color3.fromRGB(180, 80, 255); applyTheme() end)
    button("Yellow Theme", function() Settings.IsRainbow = false; Settings.ThemeColor = Color3.fromRGB(255, 255, 80); applyTheme() end)
    button("Rainbow Theme", function() Settings.IsRainbow = true; applyTheme() end)
    
    addCategory("Settings")
    slider("Aimbot FOV Size", 40, 420, "FOV")
    slider("Silent FOV Size", 40, 420, "SilentFOV")
    slider("Smoothness", 0.05, 1, "Smoothness")

    local FOVCircle = Instance.new("Frame"); FOVCircle.AnchorPoint = Vector2.new(0.5, 0.5); FOVCircle.BackgroundTransparency = 1; FOVCircle.ZIndex = 50; FOVCircle.Parent = Gui; FOVCircle.Visible = false; Instance.new("UICorner", FOVCircle).CornerRadius = UDim.new(1, 0)
    FOVCircleStroke = Instance.new("UIStroke", FOVCircle); FOVCircleStroke.Color = Settings.ThemeColor; FOVCircleStroke.Thickness = 1.5

    local SilentFOVCircle = Instance.new("Frame"); SilentFOVCircle.AnchorPoint = Vector2.new(0.5, 0.5); SilentFOVCircle.BackgroundTransparency = 1; SilentFOVCircle.ZIndex = 49; SilentFOVCircle.Parent = Gui; SilentFOVCircle.Visible = false; Instance.new("UICorner", SilentFOVCircle).CornerRadius = UDim.new(1, 0)
    SilentFOVCircleStroke = Instance.new("UIStroke", SilentFOVCircle); SilentFOVCircleStroke.Color = Color3.fromRGB(255, 255, 255); SilentFOVCircleStroke.Thickness = 1.5

    local WarningFrame = Instance.new("Frame", Gui); WarningFrame.Size = UDim2.new(0, 250, 0, 40); WarningFrame.Position = UDim2.new(0.5, -125, 0, 80); WarningFrame.BackgroundColor3 = Color3.fromRGB(150, 0, 0); WarningFrame.BackgroundTransparency = 0.2; WarningFrame.Visible = false; WarningFrame.ZIndex = 100; Instance.new("UICorner", WarningFrame).CornerRadius = UDim.new(0, 6); Instance.new("UIStroke", WarningFrame).Color = Color3.fromRGB(255, 50, 50); Instance.new("UIStroke", WarningFrame).Thickness = 2
    local WarningText = Instance.new("TextLabel", WarningFrame); WarningText.Size = UDim2.new(1, 0, 1, 0); WarningText.BackgroundTransparency = 1; WarningText.Font = Enum.Font.GothamBlack; WarningText.TextSize = 16; WarningText.TextColor3 = Color3.fromRGB(255, 255, 255); WarningText.Text = "⚠️ WARNING"

    local CrosshairParts = {}
    for i = 1, 4 do local p = Instance.new("Frame"); p.Name = "QeeCrosshair_"..i; p.BackgroundColor3 = Settings.ThemeColor; p.BorderSizePixel = 0; p.Parent = Gui; p.Visible = false; p.ZIndex = 99; table.insert(CrosshairParts, p) end

    local function getHumanoid(m) return m and m:FindFirstChildOfClass("Humanoid") end
    local function isTeammate(p) if not Settings.TeamCheck then return false end if p == LocalPlayer then return true end if LocalPlayer.Team and p.Team then return LocalPlayer.Team == p.Team end return false end
    
    local function isValidTarget(m, isForAim)
        if not m or not m:IsA("Model") then return false end 
        local t = Players:GetPlayerFromCharacter(m)
        local isBot = (t == nil)
        if isForAim then if isBot and not Settings.AimBots then return false end; if not isBot and not Settings.AimPlayers then return false end end
        if t then if t == LocalPlayer or isTeammate(t) then return false end; return true end
        local r = getRootPart(m); local h = getHumanoid(m); if not r or not h or h.Health <= 0 then return false end; return true 
    end
    
    local function getAllTargets()
        local c = {}; local s = {}
        for _, p in ipairs(Players:GetPlayers()) do if p.Character then local m = p.Character; if isValidTarget(m, true) and not s[m] then s[m] = true; table.insert(c, m) end end end
        for _, obj in ipairs(Workspace:GetChildren()) do if obj:IsA("Model") and LocalPlayer.Character and not obj:IsDescendantOf(LocalPlayer.Character) then if not s[obj] and isValidTarget(obj, true) then s[obj] = true; table.insert(c, obj) end end end
        return c
    end

    local function canSee(part)
        if not Settings.WallCheck then return true end 
        local ign = {}; if LocalPlayer.Character then table.insert(ign, LocalPlayer.Character) end 
        local par = RaycastParams.new(); par.FilterType = Enum.RaycastFilterType.Exclude; par.FilterDescendantsInstances = ign 
        local suc, res = pcall(function() return Workspace:Raycast(Camera.CFrame.Position, part.Position - Camera.CFrame.Position, par) end) 
        if not suc then return true end; return not res or res.Instance:IsDescendantOf(part.Parent) 
    end
    
    local function createEsp(model)
        local root = getRootPart(model); if not root then return nil end
        local box = Instance.new("Frame"); box.Name = "Qee_Box"; box.BackgroundTransparency = 1; box.BorderSizePixel = 0; box.Visible = false; box.ZIndex = 97; box.Parent = Gui
        local boxStroke = Instance.new("UIStroke", box); boxStroke.Thickness = 1.5; boxStroke.Color = Settings.ThemeColor; boxStroke.Transparency = 0
        local text = Instance.new("TextLabel"); text.Name = "Qee_Text"; text.BackgroundTransparency = 1; text.Size = UDim2.new(1, 0, 0, 14); text.Position = UDim2.new(0, 0, 1, 2); text.Font = Enum.Font.GothamBold; text.TextSize = 12; text.TextStrokeTransparency = 0.25; text.TextColor3 = Settings.ThemeColor; text.TextXAlignment = Enum.TextXAlignment.Center; text.Parent = box
        return { Box = box, BoxStroke = boxStroke, Text = text }
    end
    
    local function clearEsp(m) local e = EspObjects[m]; if not e then return end; pcall(function() if e.Box then e.Box:Destroy() end end); EspObjects[m] = nil end
    
    local function updateEsp(npcs) 
        local alive = {}
        for _, model in ipairs(npcs) do alive[model] = true; local esp = EspObjects[model] or createEsp(model); EspObjects[model] = esp; local root = getRootPart(model)
            if esp and root then 
                local dist = math.floor((root.Position - Camera.CFrame.Position).Magnitude); local isVis = Settings.Enabled and Settings.ESP; local seen = canSee(root); local col = seen and Settings.ThemeColor or Color3.fromRGB(255, 85, 85)
                local charPos, charOnScreen = Camera:WorldToViewportPoint(root.Position)
                local head = model:FindFirstChild("Head"); local headPos = Camera:WorldToViewportPoint((head and head.Position or root.Position) + Vector3.new(0, 0.5, 0))
                local legPos = Camera:WorldToViewportPoint(root.Position - Vector3.new(0, 3, 0))
                local isBehind = (headPos.Z < 0 and legPos.Z < 0); local onScreen = charOnScreen and not isBehind
                pcall(function() 
                    esp.Box.Visible = isVis and onScreen; esp.BoxStroke.Color = col; esp.Text.TextColor3 = col
                    if isVis and onScreen then
                        local distance = (root.Position - Camera.CFrame.Position).Magnitude; local width = math.clamp(2500 / distance, 4, 60); local height = math.abs(legPos.Y - headPos.Y)
                        local topY = math.min(headPos.Y, legPos.Y); local posX = charPos.X - width / 2
                        esp.Box.Position = UDim2.fromOffset(posX, topY); esp.Box.Size = UDim2.fromOffset(width, height)
                        local isBot = Players:GetPlayerFromCharacter(model) == nil; local displayName = isBot and "Bot" or model.Name
                        esp.Text.Text = displayName .. " [" .. tostring(dist) .. "]"
                    end
                end)
            end 
        end 
        for model in pairs(EspObjects) do if not alive[model] or not isValidTarget(model, false) then clearEsp(model) end end 
    end
    
    local function getClosestTarget(npcs, fovSize, targetMode)
        local bP = nil; local bD = fovSize; local mLoc = UserInputService:GetMouseLocation(); local centerVp = Vector2.new(mLoc.X, mLoc.Y)
        for _, m in ipairs(npcs) do
            if isValidTarget(m, true) then local p = getRootPart(m, targetMode); if p then
                local d3 = (p.Position - Camera.CFrame.Position).Magnitude; local suc, sp, on = pcall(function() return Camera:WorldToViewportPoint(p.Position) end)
                if suc and on and sp.Z > 0 and d3 <= Settings.MaxRange and canSee(p) then local d2 = (Vector2.new(sp.X, sp.Y) - centerVp).Magnitude; if d2 < bD then bD = d2; bP = p end end
            end end
        end
        return bP
    end

    local function aimAt(part, dt) 
        local pred = getPredictedPosition(part, Settings.BulletSpeed); local desired = CFrame.lookAt(Camera.CFrame.Position, pred)
        pcall(function()
            if Settings.AimStyle == "AIMBOT" then Camera.CFrame = desired
            elseif Settings.AimStyle == "SMOOTH" then local alpha = math.clamp(Settings.Smoothness * dt * 60, 0, 1); Camera.CFrame = Camera.CFrame:Lerp(desired, alpha) end
        end)
    end

    local function updateWarning(npcs) 
        if not Settings.Enabled or not Settings.WarningEnabled then WarningFrame.Visible = false; return end 
        local myChar = LocalPlayer.Character; if not myChar or not myChar:FindFirstChild("HumanoidRootPart") then WarningFrame.Visible = false; return end
        local myRoot = myChar.HumanoidRootPart; local wDir = nil
        for _, model in ipairs(npcs) do if isValidTarget(model, false) then local tR = getRootPart(model); local tH = getHumanoid(model)
            if tR and tH and tH.Health > 0 then local dirToMe = (myRoot.Position - tR.Position).Unit; local dot = tR.CFrame.LookVector:Dot(dirToMe)
                if dot > 0.8 then local offset = myRoot.CFrame:ToObjectSpace(tR.CFrame).Position; local angle = math.deg(math.atan2(offset.X, -offset.Z))
                    if angle > -45 and angle <= 45 then wDir = "FRONT" elseif angle > 45 and angle <= 135 then wDir = "RIGHT" elseif angle > 135 or angle <= -135 then wDir = "BACK" else wDir = "LEFT" end; break
                end
            end
        end end
        if wDir then WarningFrame.Visible = true; WarningText.Text = "⚠️ AIMED FROM: " .. wDir else WarningFrame.Visible = false end
    end

    local function teleportToClosestEnemy() 
        local myChar = LocalPlayer.Character; if not myChar or not myChar:FindFirstChild("HumanoidRootPart") then return end 
        local targets = getAllTargets(); local bestTargetChar = nil; local minDist = math.huge
        if CurrentTarget and CurrentTarget.Parent then bestTargetChar = CurrentTarget.Parent
        else for _, m in ipairs(targets) do if isValidTarget(m, true) then local root = getRootPart(m); if root then local dist = (root.Position - myChar.HumanoidRootPart.Position).Magnitude; if dist < minDist then minDist = dist; bestTargetChar = m end end end end end
        if bestTargetChar and bestTargetChar:FindFirstChild("HumanoidRootPart") then myChar:PivotTo(bestTargetChar.HumanoidRootPart.CFrame * CFrame.new(0, 0, -3)) end
    end

    UserInputService.InputChanged:Connect(function(i) if DraggingSlider and i.UserInputType == Enum.UserInputType.MouseMovement then DraggingSlider() end end)
    UserInputService.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then DraggingSlider = nil; ScrollFrame.ScrollingEnabled = true end end)
    UserInputService.InputBegan:Connect(function(i, gp)
        if gp then return end
        if i.KeyCode == Enum.KeyCode.RightShift then toggleMenu(not Settings.UIVisible)
        elseif i.KeyCode == Settings.TpKey then teleportToClosestEnemy()
        elseif i.KeyCode == Settings.FlyKey then Settings.FlyEnabled = not Settings.FlyEnabled; updateIndicators()
        elseif i.KeyCode == Enum.KeyCode.G then toggleGhost() end
    end)

    RunService.RenderStepped:Connect(function(dt)
        if Settings.IsRainbow then Settings.ThemeColor = Color3.fromHSV(tick() * 0.5 % 1, 0.8, 1); applyTheme() end
        if not Settings.Enabled then CurrentTarget = nil; SilentTarget = nil; CachedSilentHit = nil; CachedSilentTargetPart = nil; WarningFrame.Visible = false
            for _, p in ipairs(CrosshairParts) do p.Visible = false end return
        end
        Camera = Workspace.CurrentCamera; if not Camera then return end

        local mLoc = UserInputService:GetMouseLocation()
        FOVCircle.Position = UDim2.fromOffset(mLoc.X, mLoc.Y); FOVCircle.Size = UDim2.fromOffset(Settings.FOV * 2, Settings.FOV * 2); FOVCircle.Visible = Settings.ShowFOV
        SilentFOVCircle.Position = UDim2.fromOffset(mLoc.X, mLoc.Y); SilentFOVCircle.Size = UDim2.fromOffset(Settings.SilentFOV * 2, Settings.SilentFOV * 2); SilentFOVCircle.Visible = Settings.ShowSilentFOV

        if tick() - LastScanTime > 0.5 then CachedTargets = getAllTargets(); LastScanTime = tick() end
        updateEsp(CachedTargets); if tick() % 0.2 < dt then updateWarning(CachedTargets) end

        if Settings.GhostHack and LocalPlayer.Character then
            for _, v in ipairs(LocalPlayer.Character:GetDescendants()) do
                if v:IsA("BasePart") and v.Name ~= "HumanoidRootPart" then if originalTransparencies[v] == nil then originalTransparencies[v] = v.Transparency end; v.Transparency = 1; v.LocalTransparencyModifier = 0
                elseif v:IsA("Decal") or v:IsA("Texture") then if originalTransparencies[v] == nil then originalTransparencies[v] = v.Transparency end; v.Transparency = 1 end
            end
        end

        if Settings.FlyEnabled then
            local myChar = LocalPlayer.Character; local hum = myChar and myChar:FindFirstChildOfClass("Humanoid")
            if myChar and myChar:FindFirstChild("HumanoidRootPart") and hum then local root = myChar.HumanoidRootPart; local moveDir = Vector3.zero
                local cf = Camera.CFrame; local forward = (cf.LookVector * Vector3.new(1,0,1)).Unit; local right = (cf.RightVector * Vector3.new(1,0,1)).Unit
                if UserInputService:IsKeyDown(Enum.KeyCode.W) then moveDir = moveDir + forward end
                if UserInputService:IsKeyDown(Enum.KeyCode.S) then moveDir = moveDir - forward end
                if UserInputService:IsKeyDown(Enum.KeyCode.A) then moveDir = moveDir - right end
                if UserInputService:IsKeyDown(Enum.KeyCode.D) then moveDir = moveDir + right end
                if UserInputService:IsKeyDown(Enum.KeyCode.Space) then moveDir = moveDir + Vector3.new(0,1,0) end
                if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then moveDir = moveDir - Vector3.new(0,1,0) end
                if moveDir.Magnitude > 0 then moveDir = moveDir.Unit end
                root.AssemblyLinearVelocity = moveDir * Settings.FlySpeed; hum.PlatformStand = true
            end
        elseif LocalPlayer.Character then local hum = LocalPlayer.Character:FindFirstChildOfClass("Humanoid"); if hum and hum.PlatformStand then hum.PlatformStand = false end end

        if Settings.CustomCrosshair then
            local center = mLoc; local gap = 5; local len = 8; local thick = 2
            CrosshairParts[1].Position = UDim2.fromOffset(center.X - gap - len, center.Y - thick/2); CrosshairParts[1].Size = UDim2.new(0, len, 0, thick)
            CrosshairParts[2].Position = UDim2.fromOffset(center.X + gap, center.Y - thick/2); CrosshairParts[2].Size = UDim2.new(0, len, 0, thick)
            CrosshairParts[3].Position = UDim2.fromOffset(center.X - thick/2, center.Y - gap - len); CrosshairParts[3].Size = UDim2.new(0, thick, 0, len)
            CrosshairParts[4].Position = UDim2.fromOffset(center.X - thick/2, center.Y + gap); CrosshairParts[4].Size = UDim2.new(0, thick, 0, len)
            for _, p in ipairs(CrosshairParts) do p.Visible = true; p.BackgroundColor3 = Settings.ThemeColor end
        else for _, p in ipairs(CrosshairParts) do p.Visible = false end end

        if Settings.SilentAim then SilentTarget = getClosestTarget(CachedTargets, Settings.SilentFOV, Settings.SilentTarget)
            if SilentTarget then local predPos = getPredictedPosition(SilentTarget, Settings.BulletSpeed); CachedSilentHit = CFrame.new(predPos); CachedSilentTargetPart = SilentTarget
            else CachedSilentHit = nil; CachedSilentTargetPart = nil end
        else SilentTarget = nil; CachedSilentHit = nil; CachedSilentTargetPart = nil end

        if Settings.AutoKill then CurrentTarget = getClosestTarget(CachedTargets, Settings.FOV, Settings.TargetMode)
            if CurrentTarget then local myChar = LocalPlayer.Character; local targetRoot = CurrentTarget
                if myChar and myChar:FindFirstChild("HumanoidRootPart") and targetRoot then local distToTarget = (myChar.HumanoidRootPart.Position - targetRoot.Position).Magnitude
                    if distToTarget > 5 then myChar:PivotTo(targetRoot.CFrame * CFrame.new(0, 0, 3)) end
                    myChar.HumanoidRootPart.CFrame = CFrame.lookAt(myChar.HumanoidRootPart.Position, targetRoot.Position)
                    local tool = myChar:FindFirstChildOfClass("Tool"); if tool then tool:Activate() end
                    if tick() - LastTriggerClick > 0.05 then task.spawn(function() pcall(function() mouse1press() task.wait(0.01) mouse1release() end) end); LastTriggerClick = tick() end
                    Status.Text = "Status: KILLING " .. CurrentTarget.Parent.Name
                end
            else Status.Text = "Hotkeys: RShift=Menu, F=Fly, G=Ghost" end
        elseif Settings.AimStyle ~= "OFF" then CurrentTarget = getClosestTarget(CachedTargets, Settings.FOV, Settings.TargetMode)
            if CurrentTarget then Status.Text = "Status: " .. CurrentTarget.Parent.Name
                local isH = UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2); local isS = UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1); local sA = false
                if Settings.AWMMode then sA = isH elseif Settings.AimMode == "Auto" then sA = true elseif Settings.AimMode == "Scope" then sA = isH else sA = isH or isS end
                if sA then aimAt(CurrentTarget, dt) end
                if Settings.TriggerBot and sA then if tick() - LastTriggerClick > 0.1 then task.spawn(function() pcall(function() mouse1press() task.wait(0.02) mouse1release() end) end); LastTriggerClick = tick() end end
            else Status.Text = "Hotkeys: RShift=Menu, F=Fly, G=Ghost" end
        else CurrentTarget = nil; Status.Text = "Hotkeys: RShift=Menu, F=Fly, G=Ghost" end
    end)
end

local function checkPassword() 
    local input = PassBox.Text:gsub("^%s+", ""):gsub("%s+$", "")
    if input == PASSWORD then playSFX("rbxassetid://452267918"); InitializeHack()
    else playSFX("rbxassetid://131147405"); PassBox.Text = ""; PassBox.PlaceholderText = "Wrong Password!"; PassBox.PlaceholderColor3 = Color3.fromRGB(255, 50, 50) end
end
PassBtn.MouseButton1Click:Connect(checkPassword)
PassBox.FocusLost:Connect(function(enter) if enter then checkPassword() end end)-- QeeHacker Client (PC/Laptop Only - V10.1 - SYNTAX FIX + BRIGHTNESS FIX + PROTECTED GUI)
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")
local SoundService = game:GetService("SoundService")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

-- [CONFIG & GLOBAL VARS]
local Settings = { 
    Enabled = false, AimStyle = "OFF", AimMode = "Hold Aim", AWMMode = false, 
    TriggerBot = false, TeamCheck = true, WallCheck = false, TargetMode = "Body", 
    ESP = false, 
    WarningEnabled = false, AutoKill = false, AntiLag = false, 
    ShowFOV = false, Smoothness = 0.5, FOV = 160, MaxRange = 1200, BulletSpeed = 1000,
    TpKey = Enum.KeyCode.T, UIVisible = false, 
    ThemeColor = Color3.fromRGB(0, 255, 80), IsRainbow = false,
    FlyEnabled = false, FlySpeed = 80, FlyKey = Enum.KeyCode.F,
    CustomCrosshair = false, GhostHack = false,
    SilentAim = false, SilentFOV = 120, SilentTarget = "Body", ShowSilentFOV = false,
    AimPlayers = true, AimBots = true
}

local CurrentTarget = nil; local SilentTarget = nil; local DraggingSlider = nil
local EspObjects = {}; local CachedTargets = {}; local LastScanTime = 0; local LastTriggerClick = 0
local originalTransparencies = {} 

local CachedSilentHit = nil
local CachedSilentTargetPart = nil

local function getRootPart(m, targetMode)
    if not m then return nil end
    if (targetMode or Settings.TargetMode) == "Head" then 
        return m:FindFirstChild("Head") or m:FindFirstChild("HumanoidRootPart") or m.PrimaryPart 
    end
    return m:FindFirstChild("HumanoidRootPart") or m:FindFirstChild("UpperTorso") or m:FindFirstChild("Torso") or m:FindFirstChild("Head") or m.PrimaryPart 
end

local function getPredictedPosition(part, bulletSpeed)
    local root = part.Parent and part.Parent:FindFirstChild("HumanoidRootPart")
    local vel = root and root.AssemblyLinearVelocity or Vector3.zero
    local dist = (part.Position - Camera.CFrame.Position).Magnitude
    return part.Position + vel * (dist / math.max(bulletSpeed or Settings.BulletSpeed, 1))
end

-- [BYPASS & ANTI-KICK + SILENT AIM HOOK (V10 FIX)]
pcall(function()
    local mt = getrawmetatable(game)
    local oldNamecall = mt.__namecall
    local oldIndex = mt.__index
    setreadonly(mt, false)

    mt.__namecall = newcclosure(function(self, ...)
        local method = getnamecallmethod()
        if method == "Kick" and self == LocalPlayer then return nil end
        
        if Settings.SilentAim and Settings.Enabled and CachedSilentHit and not checkcaller() then
            local args = {...}
            local isRaycast = (method == "Raycast")
            local isRayMethod = (method == "FindPartOnRayWithIgnoreList" or method == "FindPartOnRay" or method == "FindPartOnRayWithWhitelist")
            
            if isRaycast or isRayMethod then
                local origin, direction
                if isRaycast then origin = args[1]; direction = args[2]
                else
                    local r = args[1]
                    if r and typeof(r) == "Ray" then origin = r.Origin; direction = r.Direction end
                end
                
                if origin and direction and direction.Magnitude > 50 then
                    local targetPos = CachedSilentHit.Position
                    local newDir = (targetPos - origin)
                    if newDir.Magnitude > 0 then
                        if isRaycast then args[2] = newDir.Unit * direction.Magnitude
                        else args[1] = Ray.new(origin, newDir.Unit * direction.Magnitude) end
                        return oldNamecall(self, table.unpack(args))
                    end
                end
            end
        end
        return oldNamecall(self, ...)
    end)

    mt.__index = newcclosure(function(self, key)
        if Settings.SilentAim and Settings.Enabled and CachedSilentHit and typeof(self) == "Instance" and self:IsA("Mouse") then
            if key == "Hit" then return CachedSilentHit
            elseif key == "Target" or key == "target" then return CachedSilentTargetPart end
        end
        return oldIndex(self, key)
    end)
    setreadonly(mt, true)
end)

local function playSFX(id)
    pcall(function()
        local s = Instance.new("Sound"); s.SoundId = id; s.Volume = 0.5; s.Parent = SoundService; s:Play()
        task.delay(5, function() s:Destroy() end)
    end)
end

local function OptimizeGame()
    pcall(function()
        settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
        Lighting.GlobalShadows = false; Lighting.FogEnd = 9e9
        for _, v in ipairs(Workspace:GetDescendants()) do
            if v:IsA("Part") or v:IsA("UnionOperation") or v:IsA("MeshPart") then v.Material = Enum.Material.SmoothPlastic; v.Reflectance = 0
            elseif v:IsA("Decal") or v:IsA("Texture") then v:Destroy()
            elseif v:IsA("ParticleEmitter") or v:IsA("Trail") then v.Enabled = false end
        end
    end)
end

-- [FIX: UI Parent Proteksi Biar Ga Di-Delete Game]
local uiParent
pcall(function()
    if gethui then uiParent = gethui()
    elseif syn and syn.protect_gui then uiParent = game:GetService("CoreGui")
    else uiParent = LocalPlayer:WaitForChild("PlayerGui") end
end)
if not uiParent then uiParent = LocalPlayer:WaitForChild("PlayerGui") end

local PASSWORD = "Qee Only"

local PassGui = Instance.new("ScreenGui", uiParent); PassGui.Name = "RbxAuth"; PassGui.ResetOnSpawn = false; PassGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling; PassGui.DisplayOrder = 9999
local PassFrame = Instance.new("Frame", PassGui); PassFrame.Size = UDim2.new(0, 300, 0, 150); PassFrame.Position = UDim2.new(0.5, 0, 0.5, 0); PassFrame.AnchorPoint = Vector2.new(0.5, 0.5); PassFrame.BackgroundColor3 = Color3.fromRGB(28, 28, 38); PassFrame.BorderSizePixel = 0; PassFrame.ClipsDescendants = true; PassFrame.Active = true
Instance.new("UICorner", PassFrame).CornerRadius = UDim.new(0, 8)
local PassStroke = Instance.new("UIStroke", PassFrame); PassStroke.Color = Color3.fromRGB(0, 255, 150); PassStroke.Thickness = 2.5; PassStroke.Transparency = 0
local PassTitle = Instance.new("TextLabel", PassFrame); PassTitle.Size = UDim2.new(1, 0, 0, 40); PassTitle.BackgroundTransparency = 1; PassTitle.Font = Enum.Font.GothamBlack; PassTitle.TextSize = 20; PassTitle.TextColor3 = Color3.fromRGB(100, 255, 150); PassTitle.Text = "QeeHacker Authentication"
local PassBox = Instance.new("TextBox", PassFrame); PassBox.Size = UDim2.new(1, -40, 0, 35); PassBox.Position = UDim2.new(0, 20, 0, 55); PassBox.BackgroundColor3 = Color3.fromRGB(42, 42, 55); PassBox.BorderSizePixel = 0; PassBox.Font = Enum.Font.GothamMedium; PassBox.TextSize = 14; PassBox.TextColor3 = Color3.fromRGB(230, 230, 240); PassBox.PlaceholderText = "Enter Password..."; PassBox.PlaceholderColor3 = Color3.fromRGB(150, 150, 170); PassBox.ClearTextOnFocus = false
Instance.new("UICorner", PassBox).CornerRadius = UDim.new(0, 5)
local PassBtn = Instance.new("TextButton", PassFrame); PassBtn.Size = UDim2.new(1, -40, 0, 35); PassBtn.Position = UDim2.new(0, 20, 0, 100); PassBtn.BackgroundColor3 = Color3.fromRGB(0, 210, 90); PassBtn.BorderSizePixel = 0; PassBtn.Font = Enum.Font.GothamBold; PassBtn.TextSize = 14; PassBtn.TextColor3 = Color3.fromRGB(12, 12, 16); PassBtn.Text = "LOGIN"
Instance.new("UICorner", PassBtn).CornerRadius = UDim.new(0, 5)

local function MakeDrag(dragHandle, dragTarget)
    local dragging, dragInput, dragStart, startPos
    dragHandle.InputBegan:Connect(function(input) 
        if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = true; dragStart = input.Position; startPos = dragTarget.Position 
            input.Changed:Connect(function() if input.UserInputState == Enum.UserInputState.End then dragging = false end end) 
        end 
    end)
    dragHandle.InputChanged:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseMovement then dragInput = input end end)
    UserInputService.InputChanged:Connect(function(input) 
        if input == dragInput and dragging then local delta = input.Position - dragStart; dragTarget.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y) end 
    end)
end

MakeDrag(PassFrame, PassFrame)

local function InitializeHack()
    PassGui:Destroy()
    
    local OldGui = uiParent:FindFirstChild("CoreUI_v2")
    if OldGui then pcall(function() OldGui:Destroy() end) end

    local Gui = Instance.new("ScreenGui", uiParent)
    Gui.Name = "CoreUI_v2"; Gui.ResetOnSpawn = false; Gui.IgnoreGuiInset = true; Gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling; Gui.DisplayOrder = 9999

    local MasterBtn, MasterInd, AimBtn, AimInd, AimModeBtn, TriggerBtn, TriggerInd, AutoKillBtn, AutoKillInd, TargetBtn, TeamBtn, TeamInd, WallBtn, WallInd, EspBtn, EspInd, WarningBtn, WarningInd, FovBtn, FovInd, CrosshairBtn, CrossInd, FlyBtn, FlyInd, AntiLagBtn, AntiLagInd, AWMModeBtn, AWMModeInd, GhostBtn, GhostInd, SilentBtn, SilentInd, SilentTargetBtn, SilentFovBtn, SilentFovInd, TargetPlayerBtn, TargetPlayerInd, TargetBotBtn, TargetBotInd = nil
    local FOVCircleStroke, SilentFOVCircleStroke = nil, nil

    -- [FIX: Brighter Background & Thick Stroke Anti-Gelap]
    local Panel = Instance.new("Frame"); Panel.Size = UDim2.fromOffset(270, 560); Panel.Position = UDim2.fromOffset(100, 100); Panel.BackgroundColor3 = Color3.fromRGB(28, 28, 38); Panel.BorderSizePixel = 0; Panel.Parent = Gui; Panel.ClipsDescendants = true; Panel.Visible = false; Panel.Active = true
    Instance.new("UICorner", Panel).CornerRadius = UDim.new(0, 8)
    local PanelStroke = Instance.new("UIStroke", Panel); PanelStroke.Color = Settings.ThemeColor; PanelStroke.Thickness = 2.5; PanelStroke.Transparency = 0

    local Header = Instance.new("Frame"); Header.Size = UDim2.new(1, 0, 0, 45); Header.BackgroundTransparency = 1; Header.Parent = Panel; Header.Active = true
    local CloseBtn = Instance.new("TextButton"); CloseBtn.Size = UDim2.new(0, 30, 0, 30); CloseBtn.Position = UDim2.new(1, -35, 0, 7); CloseBtn.BackgroundColor3 = Color3.fromRGB(255, 50, 50); CloseBtn.BorderSizePixel = 0; CloseBtn.Font = Enum.Font.GothamBold; CloseBtn.TextSize = 14; CloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255); CloseBtn.Text = "X"; CloseBtn.Parent = Header
    Instance.new("UICorner", CloseBtn).CornerRadius = UDim.new(0, 6)
    local Title = Instance.new("TextLabel"); Title.Size = UDim2.new(1, -45, 0, 25); Title.Position = UDim2.fromOffset(12, 8); Title.BackgroundTransparency = 1; Title.Font = Enum.Font.GothamBlack; Title.TextSize = 22; Title.TextColor3 = Settings.ThemeColor; Title.TextXAlignment = Enum.TextXAlignment.Left; Title.Text = "QeeHacker [PC]"; Title.Parent = Header
    local TitleGlowUI = Instance.new("UIStroke", Title); TitleGlowUI.Color = Settings.ThemeColor; TitleGlowUI.Thickness = 1; TitleGlowUI.Transparency = 0.2
    local Status = Instance.new("TextLabel"); Status.Size = UDim2.new(1, -12, 0, 14); Status.Position = UDim2.fromOffset(12, 32); Status.BackgroundTransparency = 1; Status.Font = Enum.Font.Gotham; Status.TextSize = 11; Status.TextColor3 = Color3.fromRGB(180, 180, 200); Status.TextXAlignment = Enum.TextXAlignment.Left; Status.Text = "Hotkeys: RShift=Menu, F=Fly, G=Ghost"; Status.Parent = Header

    MakeDrag(Header, Panel)
    
    local function updateIndicators()
        if not MasterBtn then return end
        local function ind(f, s) f.BackgroundColor3 = s and Settings.ThemeColor or Color3.fromRGB(255, 50, 50) end
        MasterBtn.Text = "  Master: " .. (Settings.Enabled and "ON" or "OFF"); ind(MasterInd, Settings.Enabled)
        AimBtn.Text = "  Aim: " .. Settings.AimStyle; ind(AimInd, Settings.AimStyle ~= "OFF")
        AimModeBtn.Text = "  Aim Mode: " .. Settings.AimMode
        TriggerBtn.Text = "  Auto Shoot: " .. (Settings.TriggerBot and "ON" or "OFF"); ind(TriggerInd, Settings.TriggerBot)
        AutoKillBtn.Text = "  Auto Kill: " .. (Settings.AutoKill and "ON" or "OFF") .. " [RISKY]"; ind(AutoKillInd, Settings.AutoKill)
        TargetBtn.Text = "  Aim Target: " .. Settings.TargetMode
        TeamBtn.Text = "  Team Check: " .. (Settings.TeamCheck and "ON" or "OFF"); ind(TeamInd, Settings.TeamCheck)
        WallBtn.Text = "  Wall Check: " .. (Settings.WallCheck and "ON" or "OFF"); ind(WallInd, Settings.WallCheck)
        EspBtn.Text = "  ESP Box: " .. (Settings.ESP and "ON" or "OFF"); ind(EspInd, Settings.ESP)
        WarningBtn.Text = "  Aim Warning: " .. (Settings.WarningEnabled and "ON" or "OFF"); ind(WarningInd, Settings.WarningEnabled)
        FovBtn.Text = "  Aimbot FOV: " .. (Settings.ShowFOV and "ON" or "OFF"); ind(FovInd, Settings.ShowFOV)
        CrosshairBtn.Text = "  Crosshair: " .. (Settings.CustomCrosshair and "ON" or "OFF"); ind(CrossInd, Settings.CustomCrosshair)
        GhostBtn.Text = "  Ghost [G]: " .. (Settings.GhostHack and "ON" or "OFF"); ind(GhostInd, Settings.GhostHack)
        
        SilentBtn.Text = "  Silent Aim: " .. (Settings.SilentAim and "ON" or "OFF"); ind(SilentInd, Settings.SilentAim)
        SilentTargetBtn.Text = "  Silent Target: " .. Settings.SilentTarget
        SilentFovBtn.Text = "  Silent FOV: " .. (Settings.ShowSilentFOV and "ON" or "OFF"); ind(SilentFovInd, Settings.ShowSilentFOV)
        
        TargetPlayerBtn.Text = "  Target Players: " .. (Settings.AimPlayers and "ON" or "OFF"); ind(TargetPlayerInd, Settings.AimPlayers)
        TargetBotBtn.Text = "  Target Bots: " .. (Settings.AimBots and "ON" or "OFF"); ind(TargetBotInd, Settings.AimBots)
        
        AntiLagBtn.Text = "  Anti-Lag: " .. (Settings.AntiLag and "ON" or "OFF"); ind(AntiLagInd, Settings.AntiLag)
        AWMModeBtn.Text = "  AWM Mode: " .. (Settings.AWMMode and "ON" or "OFF"); ind(AWMModeInd, Settings.AWMMode)
        FlyBtn.Text = "  Fly [F]: " .. (Settings.FlyEnabled and "ON" or "OFF"); ind(FlyInd, Settings.FlyEnabled)
    end

    local function toggleMenu(state) Settings.UIVisible = state; Panel.Visible = state; updateIndicators() end
    CloseBtn.MouseButton1Click:Connect(function() toggleMenu(false) end)

    local ScrollFrame = Instance.new("ScrollingFrame"); ScrollFrame.Size = UDim2.new(1, 0, 1, -45); ScrollFrame.Position = UDim2.fromOffset(0, 45); ScrollFrame.BackgroundTransparency = 1; ScrollFrame.ScrollBarThickness = 4; ScrollFrame.ScrollBarImageColor3 = Settings.ThemeColor; ScrollFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y; ScrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0); ScrollFrame.Parent = Panel
    Instance.new("UIListLayout", ScrollFrame).SortOrder = Enum.SortOrder.LayoutOrder
    local Padding = Instance.new("UIPadding", ScrollFrame); Padding.PaddingLeft = UDim.new(0, 10); Padding.PaddingRight = UDim.new(0, 10); Padding.PaddingTop = UDim.new(0, 5); Padding.PaddingBottom = UDim.new(0, 10)

    local layoutOrder = 0
    local function addCategory(n) local l = Instance.new("Frame"); l.Size = UDim2.new(1, 0, 0, 1); l.BackgroundColor3 = Color3.fromRGB(50, 50, 65); l.BorderSizePixel = 0; l.Parent = ScrollFrame; layoutOrder = layoutOrder + 1; l.LayoutOrder = layoutOrder; local c = Instance.new("TextLabel"); c.Size = UDim2.new(1, 0, 0, 20); c.BackgroundTransparency = 1; c.Font = Enum.Font.GothamBold; c.TextSize = 12; c.TextColor3 = Settings.ThemeColor; c.TextXAlignment = Enum.TextXAlignment.Left; c.Text = string.upper(n); c.Parent = ScrollFrame; layoutOrder = layoutOrder + 1; c.LayoutOrder = layoutOrder end
    local function button(t, cb) local i = Instance.new("TextButton"); i.Size = UDim2.new(1, 0, 0, 30); i.BackgroundColor3 = Color3.fromRGB(40, 42, 58); i.BorderSizePixel = 0; i.Font = Enum.Font.GothamMedium; i.TextSize = 12; i.TextColor3 = Color3.fromRGB(230, 230, 240); i.TextXAlignment = Enum.TextXAlignment.Left; i.Text = "  "..t; i.Parent = ScrollFrame; layoutOrder = layoutOrder + 1; i.LayoutOrder = layoutOrder; Instance.new("UICorner", i).CornerRadius = UDim.new(0, 5); local ind = Instance.new("Frame"); ind.Size = UDim2.new(0, 3, 0.6, 0); ind.Position = UDim2.new(0, 4, 0.2, 0); ind.BackgroundColor3 = Color3.fromRGB(255, 50, 50); ind.BorderSizePixel = 0; ind.Parent = i; Instance.new("UICorner", ind).CornerRadius = UDim.new(0, 2); i.MouseButton1Click:Connect(cb); return i, ind end

    local function applyTheme() pcall(function() PanelStroke.Color = Settings.ThemeColor; Title.TextColor3 = Settings.ThemeColor; ScrollFrame.ScrollBarImageColor3 = Settings.ThemeColor; TitleGlowUI.Color = Settings.ThemeColor; if FOVCircleStroke then FOVCircleStroke.Color = Settings.ThemeColor end; if SilentFOVCircleStroke then SilentFOVCircleStroke.Color = Color3.fromRGB(255, 255, 255) end updateIndicators() end) end
    local function slider(lT, minV, maxV, sN) local c = Instance.new("Frame"); c.Size = UDim2.new(1, 0, 0, 35); c.BackgroundTransparency = 1; c.Parent = ScrollFrame; layoutOrder = layoutOrder + 1; c.LayoutOrder = layoutOrder; local l = Instance.new("TextLabel"); l.Size = UDim2.new(1, 0, 0, 16); l.BackgroundTransparency = 1; l.Font = Enum.Font.Gotham; l.TextSize = 11; l.TextColor3 = Color3.fromRGB(200, 200, 215); l.TextXAlignment = Enum.TextXAlignment.Left; l.Parent = c; local b = Instance.new("TextButton"); b.Size = UDim2.new(1, 0, 0, 14); b.Position = UDim2.fromOffset(0, 18); b.BackgroundColor3 = Color3.fromRGB(50, 50, 65); b.BorderSizePixel = 0; b.Text = ""; b.AutoButtonColor = false; b.Parent = c; local f = Instance.new("Frame"); f.BorderSizePixel = 0; f.BackgroundColor3 = Settings.ThemeColor; f.Parent = b; Instance.new("UICorner", b).CornerRadius = UDim.new(0, 4); Instance.new("UICorner", f).CornerRadius = UDim.new(0, 4); local function sv(v) v = math.clamp(v, minV, maxV); local r = math.floor(v * 100 + 0.5) / 100; local rt = (r - minV) / (maxV - minV); Settings[sN] = r; f.Size = UDim2.new(rt, 0, 1, 0); f.BackgroundColor3 = Settings.ThemeColor; l.Text = lT .. ": " .. tostring(r) end; local function upd() local x = UserInputService:GetMouseLocation().X; local w = b.AbsoluteSize.X; if w > 0 then sv(minV + (maxV - minV) * math.clamp((x - b.AbsolutePosition.X) / w, 0, 1)) end end; b.MouseButton1Down:Connect(function() DraggingSlider = upd; upd(); ScrollFrame.ScrollingEnabled = false end); sv(Settings[sN]) end

    MasterBtn, MasterInd = button("Master: OFF", function() Settings.Enabled = not Settings.Enabled; CurrentTarget = nil; updateIndicators() end)
    
    addCategory("Aimbot (Kamera Gerak)")
    AimBtn, AimInd = button("Aim: OFF", function() if Settings.AimStyle == "OFF" then Settings.AimStyle = "AIMBOT" elseif Settings.AimStyle == "AIMBOT" then Settings.AimStyle = "SMOOTH" else Settings.AimStyle = "OFF" end; CurrentTarget = nil; updateIndicators() end)
    
    -- [FIX FATAL ERROR: 'elseif Settings.AimMode = "Auto"' -> Diganti jadi '==']
    AimModeBtn = button("Aim Mode: Hold Aim", function() if Settings.AimMode == "Hold Aim" then Settings.AimMode = "Auto" elseif Settings.AimMode == "Auto" then Settings.AimMode = "Scope" else Settings.AimMode = "Hold Aim" end; updateIndicators() end)
    
    TargetBtn = button("Aim Target: Body", function() Settings.TargetMode = Settings.TargetMode == "Body" and "Head" or "Body"; CurrentTarget = nil; updateIndicators() end)
    FovBtn, FovInd = button("Aimbot FOV: OFF", function() Settings.ShowFOV = not Settings.ShowFOV; updateIndicators() end)
    
    addCategory("Silent Aim (Peluru Nyasar)")
    SilentBtn, SilentInd = button("Silent Aim: OFF", function() Settings.SilentAim = not Settings.SilentAim; updateIndicators() end)
    SilentTargetBtn = button("Silent Target: Body", function() Settings.SilentTarget = Settings.SilentTarget == "Body" and "Head" or "Body"; updateIndicators() end)
    SilentFovBtn, SilentFovInd = button("Silent FOV: OFF", function() Settings.ShowSilentFOV = not Settings.ShowSilentFOV; updateIndicators() end)
    
    addCategory("Target Filters")
    TargetPlayerBtn, TargetPlayerInd = button("Target Players: ON", function() Settings.AimPlayers = not Settings.AimPlayers; updateIndicators() end)
    TargetBotBtn, TargetBotInd = button("Target Bots: ON", function() Settings.AimBots = not Settings.AimBots; updateIndicators() end)

    addCategory("Combat Assist")
    TriggerBtn, TriggerInd = button("Auto Shoot: OFF", function() Settings.TriggerBot = not Settings.TriggerBot; updateIndicators() end)
    AutoKillBtn, AutoKillInd = button("Auto Kill: OFF [RISKY]", function() Settings.AutoKill = not Settings.AutoKill; if Settings.AutoKill then Settings.TriggerBot = true end; updateIndicators() end)
    TeamBtn, TeamInd = button("Team Check: ON", function() Settings.TeamCheck = not Settings.TeamCheck; CurrentTarget = nil; updateIndicators() end)
    WallBtn, WallInd = button("Wall Check: OFF", function() Settings.WallCheck = not Settings.WallCheck; CurrentTarget = nil; updateIndicators() end)

    addCategory("Visuals")
    EspBtn, EspInd = button("ESP Box: OFF", function() Settings.ESP = not Settings.ESP; updateIndicators() end)
    WarningBtn, WarningInd = button("Aim Warning: OFF", function() Settings.WarningEnabled = not Settings.WarningEnabled; updateIndicators() end) 
    CrosshairBtn, CrossInd = button("Crosshair: OFF", function() Settings.CustomCrosshair = not Settings.CustomCrosshair; updateIndicators() end)
    
    addCategory("Fun / Movement")
    FlyBtn, FlyInd = button("Fly [F]: OFF", function() Settings.FlyEnabled = not Settings.FlyEnabled; updateIndicators() end)
    local function toggleGhost()
        Settings.GhostHack = not Settings.GhostHack 
        if not Settings.GhostHack then 
            for obj, val in pairs(originalTransparencies) do if obj and obj.Parent then obj.Transparency = val; if obj:IsA("BasePart") then obj.LocalTransparencyModifier = 0 end end end
            originalTransparencies = {}
        end
        updateIndicators() 
    end
    GhostBtn, GhostInd = button("Ghost [G]: OFF", toggleGhost)
    
    addCategory("AWM MENU"); AWMModeBtn, AWMModeInd = button("AWM Mode: OFF", function() Settings.AWMMode = not Settings.AWMMode; updateIndicators() end)
    addCategory("Performance")
    AntiLagBtn, AntiLagInd = button("Anti-Lag: OFF", function()
        Settings.AntiLag = not Settings.AntiLag
        if Settings.AntiLag then
            task.spawn(function()
                Lighting.GlobalShadows = false; Lighting.Brightness = 2; Lighting.ClockTime = 14; OptimizeGame()
                local count = 0
                for _, v in ipairs(Workspace:GetDescendants()) do
                    if v:IsA("ParticleEmitter") or v:IsA("Trail") or v:IsA("Smoke") or v:IsA("Fire") or v:IsA("Sparkles") then v.Enabled = false end
                    count = count + 1; if count % 500 == 0 then task.wait() end
                end
                for _, v in ipairs(Lighting:GetChildren()) do if v:IsA("PostEffect") then v.Enabled = false end end
                local t = Workspace:FindFirstChildOfClass("Terrain"); if t then t.WaterWaveSize = 0; t.WaterReflectance = 0 end
            end)
        else Lighting.GlobalShadows = true end
        updateIndicators()
    end)

    addCategory("Theme")
    button("Green Theme", function() Settings.IsRainbow = false; Settings.ThemeColor = Color3.fromRGB(0, 255, 80); applyTheme() end)
    button("Red Theme", function() Settings.IsRainbow = false; Settings.ThemeColor = Color3.fromRGB(255, 50, 50); applyTheme() end)
    button("Blue Theme", function() Settings.IsRainbow = false; Settings.ThemeColor = Color3.fromRGB(80, 150, 255); applyTheme() end)
    button("Purple Theme", function() Settings.IsRainbow = false; Settings.ThemeColor = Color3.fromRGB(180, 80, 255); applyTheme() end)
    button("Yellow Theme", function() Settings.IsRainbow = false; Settings.ThemeColor = Color3.fromRGB(255, 255, 80); applyTheme() end)
    button("Rainbow Theme", function() Settings.IsRainbow = true; applyTheme() end)
    
    addCategory("Settings")
    slider("Aimbot FOV Size", 40, 420, "FOV")
    slider("Silent FOV Size", 40, 420, "SilentFOV")
    slider("Smoothness", 0.05, 1, "Smoothness")

    local FOVCircle = Instance.new("Frame"); FOVCircle.AnchorPoint = Vector2.new(0.5, 0.5); FOVCircle.BackgroundTransparency = 1; FOVCircle.ZIndex = 50; FOVCircle.Parent = Gui; FOVCircle.Visible = false; Instance.new("UICorner", FOVCircle).CornerRadius = UDim.new(1, 0)
    FOVCircleStroke = Instance.new("UIStroke", FOVCircle); FOVCircleStroke.Color = Settings.ThemeColor; FOVCircleStroke.Thickness = 1.5

    local SilentFOVCircle = Instance.new("Frame"); SilentFOVCircle.AnchorPoint = Vector2.new(0.5, 0.5); SilentFOVCircle.BackgroundTransparency = 1; SilentFOVCircle.ZIndex = 49; SilentFOVCircle.Parent = Gui; SilentFOVCircle.Visible = false; Instance.new("UICorner", SilentFOVCircle).CornerRadius = UDim.new(1, 0)
    SilentFOVCircleStroke = Instance.new("UIStroke", SilentFOVCircle); SilentFOVCircleStroke.Color = Color3.fromRGB(255, 255, 255); SilentFOVCircleStroke.Thickness = 1.5

    local WarningFrame = Instance.new("Frame", Gui); WarningFrame.Size = UDim2.new(0, 250, 0, 40); WarningFrame.Position = UDim2.new(0.5, -125, 0, 80); WarningFrame.BackgroundColor3 = Color3.fromRGB(150, 0, 0); WarningFrame.BackgroundTransparency = 0.2; WarningFrame.Visible = false; WarningFrame.ZIndex = 100; Instance.new("UICorner", WarningFrame).CornerRadius = UDim.new(0, 6); Instance.new("UIStroke", WarningFrame).Color = Color3.fromRGB(255, 50, 50); Instance.new("UIStroke", WarningFrame).Thickness = 2
    local WarningText = Instance.new("TextLabel", WarningFrame); WarningText.Size = UDim2.new(1, 0, 1, 0); WarningText.BackgroundTransparency = 1; WarningText.Font = Enum.Font.GothamBlack; WarningText.TextSize = 16; WarningText.TextColor3 = Color3.fromRGB(255, 255, 255); WarningText.Text = "⚠️ WARNING"

    local CrosshairParts = {}
    for i = 1, 4 do local p = Instance.new("Frame"); p.Name = "QeeCrosshair_"..i; p.BackgroundColor3 = Settings.ThemeColor; p.BorderSizePixel = 0; p.Parent = Gui; p.Visible = false; p.ZIndex = 99; table.insert(CrosshairParts, p) end

    local function getHumanoid(m) return m and m:FindFirstChildOfClass("Humanoid") end
    local function isTeammate(p) if not Settings.TeamCheck then return false end if p == LocalPlayer then return true end if LocalPlayer.Team and p.Team then return LocalPlayer.Team == p.Team end return false end
    
    local function isValidTarget(m, isForAim)
        if not m or not m:IsA("Model") then return false end 
        local t = Players:GetPlayerFromCharacter(m)
        local isBot = (t == nil)
        if isForAim then if isBot and not Settings.AimBots then return false end; if not isBot and not Settings.AimPlayers then return false end end
        if t then if t == LocalPlayer or isTeammate(t) then return false end; return true end
        local r = getRootPart(m); local h = getHumanoid(m); if not r or not h or h.Health <= 0 then return false end; return true 
    end
    
    local function getAllTargets()
        local c = {}; local s = {}
        for _, p in ipairs(Players:GetPlayers()) do if p.Character then local m = p.Character; if isValidTarget(m, true) and not s[m] then s[m] = true; table.insert(c, m) end end end
        for _, obj in ipairs(Workspace:GetChildren()) do if obj:IsA("Model") and LocalPlayer.Character and not obj:IsDescendantOf(LocalPlayer.Character) then if not s[obj] and isValidTarget(obj, true) then s[obj] = true; table.insert(c, obj) end end end
        return c
    end

    local function canSee(part)
        if not Settings.WallCheck then return true end 
        local ign = {}; if LocalPlayer.Character then table.insert(ign, LocalPlayer.Character) end 
        local par = RaycastParams.new(); par.FilterType = Enum.RaycastFilterType.Exclude; par.FilterDescendantsInstances = ign 
        local suc, res = pcall(function() return Workspace:Raycast(Camera.CFrame.Position, part.Position - Camera.CFrame.Position, par) end) 
        if not suc then return true end; return not res or res.Instance:IsDescendantOf(part.Parent) 
    end
    
    local function createEsp(model)
        local root = getRootPart(model); if not root then return nil end
        local box = Instance.new("Frame"); box.Name = "Qee_Box"; box.BackgroundTransparency = 1; box.BorderSizePixel = 0; box.Visible = false; box.ZIndex = 97; box.Parent = Gui
        local boxStroke = Instance.new("UIStroke", box); boxStroke.Thickness = 1.5; boxStroke.Color = Settings.ThemeColor; boxStroke.Transparency = 0
        local text = Instance.new("TextLabel"); text.Name = "Qee_Text"; text.BackgroundTransparency = 1; text.Size = UDim2.new(1, 0, 0, 14); text.Position = UDim2.new(0, 0, 1, 2); text.Font = Enum.Font.GothamBold; text.TextSize = 12; text.TextStrokeTransparency = 0.25; text.TextColor3 = Settings.ThemeColor; text.TextXAlignment = Enum.TextXAlignment.Center; text.Parent = box
        return { Box = box, BoxStroke = boxStroke, Text = text }
    end
    
    local function clearEsp(m) local e = EspObjects[m]; if not e then return end; pcall(function() if e.Box then e.Box:Destroy() end end); EspObjects[m] = nil end
    
    local function updateEsp(npcs) 
        local alive = {}
        for _, model in ipairs(npcs) do alive[model] = true; local esp = EspObjects[model] or createEsp(model); EspObjects[model] = esp; local root = getRootPart(model)
            if esp and root then 
                local dist = math.floor((root.Position - Camera.CFrame.Position).Magnitude); local isVis = Settings.Enabled and Settings.ESP; local seen = canSee(root); local col = seen and Settings.ThemeColor or Color3.fromRGB(255, 85, 85)
                local charPos, charOnScreen = Camera:WorldToViewportPoint(root.Position)
                local head = model:FindFirstChild("Head"); local headPos = Camera:WorldToViewportPoint((head and head.Position or root.Position) + Vector3.new(0, 0.5, 0))
                local legPos = Camera:WorldToViewportPoint(root.Position - Vector3.new(0, 3, 0))
                local isBehind = (headPos.Z < 0 and legPos.Z < 0); local onScreen = charOnScreen and not isBehind
                pcall(function() 
                    esp.Box.Visible = isVis and onScreen; esp.BoxStroke.Color = col; esp.Text.TextColor3 = col
                    if isVis and onScreen then
                        local distance = (root.Position - Camera.CFrame.Position).Magnitude; local width = math.clamp(2500 / distance, 4, 60); local height = math.abs(legPos.Y - headPos.Y)
                        local topY = math.min(headPos.Y, legPos.Y); local posX = charPos.X - width / 2
                        esp.Box.Position = UDim2.fromOffset(posX, topY); esp.Box.Size = UDim2.fromOffset(width, height)
                        local isBot = Players:GetPlayerFromCharacter(model) == nil; local displayName = isBot and "Bot" or model.Name
                        esp.Text.Text = displayName .. " [" .. tostring(dist) .. "]"
                    end
                end)
            end 
        end 
        for model in pairs(EspObjects) do if not alive[model] or not isValidTarget(model, false) then clearEsp(model) end end 
    end
    
    local function getClosestTarget(npcs, fovSize, targetMode)
        local bP = nil; local bD = fovSize; local mLoc = UserInputService:GetMouseLocation(); local centerVp = Vector2.new(mLoc.X, mLoc.Y)
        for _, m in ipairs(npcs) do
            if isValidTarget(m, true) then local p = getRootPart(m, targetMode); if p then
                local d3 = (p.Position - Camera.CFrame.Position).Magnitude; local suc, sp, on = pcall(function() return Camera:WorldToViewportPoint(p.Position) end)
                if suc and on and sp.Z > 0 and d3 <= Settings.MaxRange and canSee(p) then local d2 = (Vector2.new(sp.X, sp.Y) - centerVp).Magnitude; if d2 < bD then bD = d2; bP = p end end
            end end
        end
        return bP
    end

    local function aimAt(part, dt) 
        local pred = getPredictedPosition(part, Settings.BulletSpeed); local desired = CFrame.lookAt(Camera.CFrame.Position, pred)
        pcall(function()
            if Settings.AimStyle == "AIMBOT" then Camera.CFrame = desired
            elseif Settings.AimStyle == "SMOOTH" then local alpha = math.clamp(Settings.Smoothness * dt * 60, 0, 1); Camera.CFrame = Camera.CFrame:Lerp(desired, alpha) end
        end)
    end

    local function updateWarning(npcs) 
        if not Settings.Enabled or not Settings.WarningEnabled then WarningFrame.Visible = false; return end 
        local myChar = LocalPlayer.Character; if not myChar or not myChar:FindFirstChild("HumanoidRootPart") then WarningFrame.Visible = false; return end
        local myRoot = myChar.HumanoidRootPart; local wDir = nil
        for _, model in ipairs(npcs) do if isValidTarget(model, false) then local tR = getRootPart(model); local tH = getHumanoid(model)
            if tR and tH and tH.Health > 0 then local dirToMe = (myRoot.Position - tR.Position).Unit; local dot = tR.CFrame.LookVector:Dot(dirToMe)
                if dot > 0.8 then local offset = myRoot.CFrame:ToObjectSpace(tR.CFrame).Position; local angle = math.deg(math.atan2(offset.X, -offset.Z))
                    if angle > -45 and angle <= 45 then wDir = "FRONT" elseif angle > 45 and angle <= 135 then wDir = "RIGHT" elseif angle > 135 or angle <= -135 then wDir = "BACK" else wDir = "LEFT" end; break
                end
            end
        end end
        if wDir then WarningFrame.Visible = true; WarningText.Text = "⚠️ AIMED FROM: " .. wDir else WarningFrame.Visible = false end
    end

    local function teleportToClosestEnemy() 
        local myChar = LocalPlayer.Character; if not myChar or not myChar:FindFirstChild("HumanoidRootPart") then return end 
        local targets = getAllTargets(); local bestTargetChar = nil; local minDist = math.huge
        if CurrentTarget and CurrentTarget.Parent then bestTargetChar = CurrentTarget.Parent
        else for _, m in ipairs(targets) do if isValidTarget(m, true) then local root = getRootPart(m); if root then local dist = (root.Position - myChar.HumanoidRootPart.Position).Magnitude; if dist < minDist then minDist = dist; bestTargetChar = m end end end end end
        if bestTargetChar and bestTargetChar:FindFirstChild("HumanoidRootPart") then myChar:PivotTo(bestTargetChar.HumanoidRootPart.CFrame * CFrame.new(0, 0, -3)) end
    end

    UserInputService.InputChanged:Connect(function(i) if DraggingSlider and i.UserInputType == Enum.UserInputType.MouseMovement then DraggingSlider() end end)
    UserInputService.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then DraggingSlider = nil; ScrollFrame.ScrollingEnabled = true end end)
    UserInputService.InputBegan:Connect(function(i, gp)
        if gp then return end
        if i.KeyCode == Enum.KeyCode.RightShift then toggleMenu(not Settings.UIVisible)
        elseif i.KeyCode == Settings.TpKey then teleportToClosestEnemy()
        elseif i.KeyCode == Settings.FlyKey then Settings.FlyEnabled = not Settings.FlyEnabled; updateIndicators()
        elseif i.KeyCode == Enum.KeyCode.G then toggleGhost() end
    end)

    RunService.RenderStepped:Connect(function(dt)
        if Settings.IsRainbow then Settings.ThemeColor = Color3.fromHSV(tick() * 0.5 % 1, 0.8, 1); applyTheme() end
        if not Settings.Enabled then CurrentTarget = nil; SilentTarget = nil; CachedSilentHit = nil; CachedSilentTargetPart = nil; WarningFrame.Visible = false
            for _, p in ipairs(CrosshairParts) do p.Visible = false end return
        end
        Camera = Workspace.CurrentCamera; if not Camera then return end

        local mLoc = UserInputService:GetMouseLocation()
        FOVCircle.Position = UDim2.fromOffset(mLoc.X, mLoc.Y); FOVCircle.Size = UDim2.fromOffset(Settings.FOV * 2, Settings.FOV * 2); FOVCircle.Visible = Settings.ShowFOV
        SilentFOVCircle.Position = UDim2.fromOffset(mLoc.X, mLoc.Y); SilentFOVCircle.Size = UDim2.fromOffset(Settings.SilentFOV * 2, Settings.SilentFOV * 2); SilentFOVCircle.Visible = Settings.ShowSilentFOV

        if tick() - LastScanTime > 0.5 then CachedTargets = getAllTargets(); LastScanTime = tick() end
        updateEsp(CachedTargets); if tick() % 0.2 < dt then updateWarning(CachedTargets) end

        if Settings.GhostHack and LocalPlayer.Character then
            for _, v in ipairs(LocalPlayer.Character:GetDescendants()) do
                if v:IsA("BasePart") and v.Name ~= "HumanoidRootPart" then if originalTransparencies[v] == nil then originalTransparencies[v] = v.Transparency end; v.Transparency = 1; v.LocalTransparencyModifier = 0
                elseif v:IsA("Decal") or v:IsA("Texture") then if originalTransparencies[v] == nil then originalTransparencies[v] = v.Transparency end; v.Transparency = 1 end
            end
        end

        if Settings.FlyEnabled then
            local myChar = LocalPlayer.Character; local hum = myChar and myChar:FindFirstChildOfClass("Humanoid")
            if myChar and myChar:FindFirstChild("HumanoidRootPart") and hum then local root = myChar.HumanoidRootPart; local moveDir = Vector3.zero
                local cf = Camera.CFrame; local forward = (cf.LookVector * Vector3.new(1,0,1)).Unit; local right = (cf.RightVector * Vector3.new(1,0,1)).Unit
                if UserInputService:IsKeyDown(Enum.KeyCode.W) then moveDir = moveDir + forward end
                if UserInputService:IsKeyDown(Enum.KeyCode.S) then moveDir = moveDir - forward end
                if UserInputService:IsKeyDown(Enum.KeyCode.A) then moveDir = moveDir - right end
                if UserInputService:IsKeyDown(Enum.KeyCode.D) then moveDir = moveDir + right end
                if UserInputService:IsKeyDown(Enum.KeyCode.Space) then moveDir = moveDir + Vector3.new(0,1,0) end
                if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then moveDir = moveDir - Vector3.new(0,1,0) end
                if moveDir.Magnitude > 0 then moveDir = moveDir.Unit end
                root.AssemblyLinearVelocity = moveDir * Settings.FlySpeed; hum.PlatformStand = true
            end
        elseif LocalPlayer.Character then local hum = LocalPlayer.Character:FindFirstChildOfClass("Humanoid"); if hum and hum.PlatformStand then hum.PlatformStand = false end end

        if Settings.CustomCrosshair then
            local center = mLoc; local gap = 5; local len = 8; local thick = 2
            CrosshairParts[1].Position = UDim2.fromOffset(center.X - gap - len, center.Y - thick/2); CrosshairParts[1].Size = UDim2.new(0, len, 0, thick)
            CrosshairParts[2].Position = UDim2.fromOffset(center.X + gap, center.Y - thick/2); CrosshairParts[2].Size = UDim2.new(0, len, 0, thick)
            CrosshairParts[3].Position = UDim2.fromOffset(center.X - thick/2, center.Y - gap - len); CrosshairParts[3].Size = UDim2.new(0, thick, 0, len)
            CrosshairParts[4].Position = UDim2.fromOffset(center.X - thick/2, center.Y + gap); CrosshairParts[4].Size = UDim2.new(0, thick, 0, len)
            for _, p in ipairs(CrosshairParts) do p.Visible = true; p.BackgroundColor3 = Settings.ThemeColor end
        else for _, p in ipairs(CrosshairParts) do p.Visible = false end end

        if Settings.SilentAim then SilentTarget = getClosestTarget(CachedTargets, Settings.SilentFOV, Settings.SilentTarget)
            if SilentTarget then local predPos = getPredictedPosition(SilentTarget, Settings.BulletSpeed); CachedSilentHit = CFrame.new(predPos); CachedSilentTargetPart = SilentTarget
            else CachedSilentHit = nil; CachedSilentTargetPart = nil end
        else SilentTarget = nil; CachedSilentHit = nil; CachedSilentTargetPart = nil end

        if Settings.AutoKill then CurrentTarget = getClosestTarget(CachedTargets, Settings.FOV, Settings.TargetMode)
            if CurrentTarget then local myChar = LocalPlayer.Character; local targetRoot = CurrentTarget
                if myChar and myChar:FindFirstChild("HumanoidRootPart") and targetRoot then local distToTarget = (myChar.HumanoidRootPart.Position - targetRoot.Position).Magnitude
                    if distToTarget > 5 then myChar:PivotTo(targetRoot.CFrame * CFrame.new(0, 0, 3)) end
                    myChar.HumanoidRootPart.CFrame = CFrame.lookAt(myChar.HumanoidRootPart.Position, targetRoot.Position)
                    local tool = myChar:FindFirstChildOfClass("Tool"); if tool then tool:Activate() end
                    if tick() - LastTriggerClick > 0.05 then task.spawn(function() pcall(function() mouse1press() task.wait(0.01) mouse1release() end) end); LastTriggerClick = tick() end
                    Status.Text = "Status: KILLING " .. CurrentTarget.Parent.Name
                end
            else Status.Text = "Hotkeys: RShift=Menu, F=Fly, G=Ghost" end
        elseif Settings.AimStyle ~= "OFF" then CurrentTarget = getClosestTarget(CachedTargets, Settings.FOV, Settings.TargetMode)
            if CurrentTarget then Status.Text = "Status: " .. CurrentTarget.Parent.Name
                local isH = UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2); local isS = UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1); local sA = false
                if Settings.AWMMode then sA = isH elseif Settings.AimMode == "Auto" then sA = true elseif Settings.AimMode == "Scope" then sA = isH else sA = isH or isS end
                if sA then aimAt(CurrentTarget, dt) end
                if Settings.TriggerBot and sA then if tick() - LastTriggerClick > 0.1 then task.spawn(function() pcall(function() mouse1press() task.wait(0.02) mouse1release() end) end); LastTriggerClick = tick() end end
            else Status.Text = "Hotkeys: RShift=Menu, F=Fly, G=Ghost" end
        else CurrentTarget = nil; Status.Text = "Hotkeys: RShift=Menu, F=Fly, G=Ghost" end
    end)
end

local function checkPassword() 
    local input = PassBox.Text:gsub("^%s+", ""):gsub("%s+$", "")
    if input == PASSWORD then playSFX("rbxassetid://452267918"); InitializeHack()
    else playSFX("rbxassetid://131147405"); PassBox.Text = ""; PassBox.PlaceholderText = "Wrong Password!"; PassBox.PlaceholderColor3 = Color3.fromRGB(255, 50, 50) end
end
PassBtn.MouseButton1Click:Connect(checkPassword)
PassBox.FocusLost:Connect(function(enter) if enter then checkPassword() end end)-- =========================================================================
-- QeeHacker V13 Final (100% Bright, Bulletproof Visibility, NoClip, Transp Slider)
-- =========================================================================

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")
local MarketplaceService = game:GetService("MarketplaceService")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

local Settings = {
    Master = true, Aimbot = false, AimAssist = false, TargetPart = "HumanoidRootPart",
    AimBots = false, Triggerbot = false, TriggerbotDelay = 0.1, Spinbot = false,
    SpinSpeed = 50, Smoothness = 0.3, FOV = 100, ShowFOV = false,
    Fly = false, FlySpeed = 60, SpeedHack = false, WalkSpeed = 50, NoClip = false,
    TeamCheck = true, ESP = false, ESPChams = false, ESPBots = false,
    ESPBox = false, ESPLine = false, ESPSkeleton = false, WallCheck = false,
    IsRainbow = false, ThemeColor = Color3.fromRGB(0, 255, 102),
    UITitle = "QeeHacker Premium", UIScale = 1, UITransparency = 0
}

local CurrentTarget, EspObjects, DraggingSlider, LastTriggerClick = nil, {}, nil, 0
local StartTime, ToggleRefs, AdjustableFrames = os.time(), {}, {}
local fpsTable, currentFPS = {}, 60
local currentExecutor = (identifyexecutor and identifyexecutor()) or (getexecutorname and getexecutorname()) or "Unknown"

-- [BULLETPROOF GUI PARENT]
local uiParent = LocalPlayer:WaitForChild("PlayerGui")
pcall(function() if gethui then uiParent = gethui() elseif syn and syn.protect_gui then uiParent = game:GetService("CoreGui") end end)

local oldUI = uiParent:FindFirstChild("QeePremiumUI"); if oldUI then oldUI:Destroy() end
local Gui = Instance.new("ScreenGui", uiParent); Gui.Name = "QeePremiumUI"; Gui.ResetOnSpawn = false; Gui.IgnoreGuiInset = true; Gui.DisplayOrder = 99999
pcall(function() if syn and syn.protect_gui then syn.protect_gui(Gui) end end)

-- [CERAH ANTI-GELAP PALET]
local Theme = {
    Bg = Color3.fromRGB(25, 25, 35), Sec = Color3.fromRGB(40, 42, 58),
    Hover = Color3.fromRGB(55, 58, 78), Accent = Color3.fromRGB(0, 255, 102),
    Glow = Color3.fromRGB(0, 255, 136), Text = Color3.fromRGB(255, 255, 255),
    SubText = Color3.fromRGB(190, 195, 210), Danger = Color3.fromRGB(255, 64, 64)
}

local function SmoothTween(obj, time, props)
    local t = TweenService:Create(obj, TweenInfo.new(time, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), props); t:Play(); return t
end

-- ==========================================
-- INTRO
-- ==========================================
local IntroFrame = Instance.new("Frame", Gui); IntroFrame.Size = UDim2.new(1,0,1,0); IntroFrame.BackgroundColor3 = Color3.fromRGB(0,0,0); IntroFrame.ZIndex = 999999
local IntroText = Instance.new("TextLabel", IntroFrame); IntroText.Size = UDim2.new(1,0,0,60); IntroText.Position = UDim2.new(0.5,0,1.5,0); IntroText.AnchorPoint = Vector2.new(0.5,0.5); IntroText.BackgroundTransparency = 1; IntroText.Font = Enum.Font.GothamBlack; IntroText.TextSize = 50; IntroText.TextColor3 = Theme.Accent; IntroText.Text = "HELLO QEE USERS"; IntroText.ZIndex = 999999
task.delay(6, function() if IntroFrame and IntroFrame.Parent then IntroFrame:Destroy() end end)

-- ==========================================
-- NOTIFICATION
-- ==========================================
local NotifCon = Instance.new("Frame", Gui); NotifCon.Size = UDim2.new(0,320,1,0); NotifCon.Position = UDim2.new(1,-340,0,20); NotifCon.BackgroundTransparency = 1
Instance.new("UIListLayout", NotifCon).Padding = UDim.new(0,10)

local function ShowNotification(title, text, dur)
    dur = dur or 3.5
    local f = Instance.new("Frame", NotifCon); f.Size = UDim2.new(1,0,0,70); f.BackgroundColor3 = Theme.Sec; f.BackgroundTransparency = Settings.UITransparency; f.ClipsDescendants = true; f.AnchorPoint = Vector2.new(1,0); f.Position = UDim2.new(1,0,0,0)
    Instance.new("UICorner", f).CornerRadius = UDim.new(0,8); Instance.new("UIStroke", f).Color = Theme.Accent; Instance.new("UIStroke", f).Thickness = 1
    local tL = Instance.new("TextLabel", f); tL.Size = UDim2.new(1,-20,0,25); tL.Position = UDim2.new(0,15,0,8); tL.BackgroundTransparency = 1; tL.Font = Enum.Font.GothamBold; tL.TextSize = 14; tL.TextColor3 = Theme.Accent; tL.Text = title; tL.TextXAlignment = Enum.TextXAlignment.Left
    local dL = Instance.new("TextLabel", f); dL.Size = UDim2.new(1,-30,0,25); dL.Position = UDim2.new(0,15,0,32); dL.BackgroundTransparency = 1; dL.Font = Enum.Font.Gotham; dL.TextSize = 12; dL.TextColor3 = Theme.Text; dL.Text = text; dL.TextWrapped = true; dL.TextXAlignment = Enum.TextXAlignment.Left
    local pb = Instance.new("Frame", f); pb.Size = UDim2.new(1,0,0,3); pb.Position = UDim2.new(0,0,1,-3); pb.BackgroundColor3 = Theme.Accent; pb.BorderSizePixel = 0
    SmoothTween(f, 0.4, {Size = UDim2.new(1,0,0,70), Position = UDim2.new(1,-320,0,0)})
    task.delay(dur, function() SmoothTween(f, 0.3, {Size = UDim2.new(0,0,0,70), BackgroundTransparency = 1}); task.wait(0.3); f:Destroy() end)
end

-- ==========================================
-- MAIN UI (SOLID BULLETPROOF)
-- ==========================================
local MainUI = Instance.new("Frame", Gui); MainUI.Size = UDim2.new(0,820,0,520); MainUI.Position = UDim2.new(0.5,0,0.5,0); MainUI.AnchorPoint = Vector2.new(0.5,0.5)
MainUI.BackgroundColor3 = Theme.Bg; MainUI.BackgroundTransparency = 1; MainUI.BorderSizePixel = 0; MainUI.Visible = false; MainUI.ClipsDescendants = true; MainUI.ZIndex = 100
Instance.new("UICorner", MainUI).CornerRadius = UDim.new(0,12); table.insert(AdjustableFrames, MainUI)

local MainStroke = Instance.new("UIStroke", MainUI); MainStroke.Color = Theme.Accent; MainStroke.Thickness = 2.5; MainStroke.Transparency = 0
local MainUIScale = Instance.new("UIScale", MainUI); MainUIScale.Scale = 0
local BgGrad = Instance.new("UIGradient", MainUI); BgGrad.Color = ColorSequence.new({ColorSequenceKeypoint.new(0, Color3.fromRGB(40,40,55)), ColorSequenceKeypoint.new(1, Color3.fromRGB(25,25,35))}); BgGrad.Rotation = 180

-- Header
local Header = Instance.new("Frame", MainUI); Header.Size = UDim2.new(1,0,0,55); Header.BackgroundTransparency = 1; Header.ZIndex = 5
local Logo = Instance.new("TextLabel", Header); Logo.Size = UDim2.new(0,30,0,30); Logo.Position = UDim2.new(0,20,0.5,-15); Logo.BackgroundTransparency = 1; Logo.Font = Enum.Font.GothamBlack; Logo.TextSize = 24; Logo.TextColor3 = Theme.Accent; Logo.Text = "Q"
local HTitle = Instance.new("TextLabel", Header); HTitle.Size = UDim2.new(0,300,0,25); HTitle.Position = UDim2.new(0,55,0,10); HTitle.BackgroundTransparency = 1; HTitle.Font = Enum.Font.GothamBold; HTitle.TextSize = 16; HTitle.TextColor3 = Theme.Text; HTitle.Text = Settings.UITitle; HTitle.TextXAlignment = Enum.TextXAlignment.Left
local HSub = Instance.new("TextLabel", Header); HSub.Size = UDim2.new(0,300,0,15); HSub.Position = UDim2.new(0,55,0,32); HSub.BackgroundTransparency = 1; HSub.Font = Enum.Font.Gotham; HSub.TextSize = 10; HSub.TextColor3 = Theme.SubText; HSub.Text = "v13 Final | " .. currentExecutor; HSub.TextXAlignment = Enum.TextXAlignment.Left
local LiveMetrics = Instance.new("TextLabel", Header); LiveMetrics.Size = UDim2.new(0,300,1,0); LiveMetrics.Position = UDim2.new(1,-380,0,0); LiveMetrics.BackgroundTransparency = 1; LiveMetrics.Font = Enum.Font.Code; LiveMetrics.TextSize = 12; LiveMetrics.TextColor3 = Theme.SubText; LiveMetrics.TextXAlignment = Enum.TextXAlignment.Right; LiveMetrics.Text = "FPS: 60 | PING: 0ms"

local CloseBtn = Instance.new("TextButton", Header); CloseBtn.Size = UDim2.new(0,32,0,32); CloseBtn.Position = UDim2.new(1,-42,0,11); CloseBtn.BackgroundColor3 = Theme.Danger; CloseBtn.Font = Enum.Font.GothamBold; CloseBtn.TextSize = 14; CloseBtn.TextColor3 = Theme.Text; CloseBtn.Text = "X"; Instance.new("UICorner", CloseBtn).CornerRadius = UDim.new(0,8)
local MiniBtn = Instance.new("TextButton", Header); MiniBtn.Size = UDim2.new(0,32,0,32); MiniBtn.Position = UDim2.new(1,-82,0,11); MiniBtn.BackgroundColor3 = Theme.Hover; MiniBtn.Font = Enum.Font.GothamBold; MiniBtn.TextSize = 14; MiniBtn.TextColor3 = Theme.Text; MiniBtn.Text = "-"; Instance.new("UICorner", MiniBtn).CornerRadius = UDim.new(0,8)

local function MakeDrag(h, t) local d,di,ds,sp; h.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then d=true;ds=i.Position;sp=t.Position;i.Changed:Connect(function()if i.UserInputState==Enum.UserInputState.End then d=false end end) end end); h.InputChanged:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseMovement then di=i end end); UserInputService.InputChanged:Connect(function(i) if i==di and d then local dl=i.Position-ds; t.Position=UDim2.new(sp.X.Scale,sp.X.Offset+dl.X,sp.Y.Scale,sp.Y.Offset+dl.Y) end end) end
MakeDrag(Header, MainUI)

local isMin = false
MiniBtn.MouseButton1Click:Connect(function() isMin = not isMin; if isMin then SmoothTween(MainUI,0.4,{Size=UDim2.new(0,820,0,55)}); MiniBtn.Text="+" else SmoothTween(MainUI,0.4,{Size=UDim2.new(0,820,0,520)}); MiniBtn.Text="-" end end)

-- BULLETPROOF: Tutup harus mulus, buka harus reset transparansi ke 0 (atau ke UITransparency setting)
CloseBtn.MouseButton1Click:Connect(function()
    SmoothTween(MainUI, 0.3, {BackgroundTransparency = 1}); SmoothTween(MainUIScale, 0.3, {Scale = 0})
    task.wait(0.3); MainUI.Visible = false
    ShowNotification("Status", "UI Hidden. Press Right Shift to re-open.", 3)
end)

-- ==========================================
-- SIDEBAR & TABS
-- ==========================================
local Sidebar = Instance.new("Frame", MainUI); Sidebar.Size = UDim2.new(0,200,1,-65); Sidebar.Position = UDim2.new(0,15,0,60); Sidebar.BackgroundColor3 = Theme.Sec; Sidebar.BackgroundTransparency = 0; Instance.new("UICorner", Sidebar).CornerRadius = UDim.new(0,10); table.insert(AdjustableFrames, Sidebar)
Instance.new("UIStroke", Sidebar).Color = Color3.fromRGB(60,65,85); Instance.new("UIStroke", Sidebar).Thickness = 1; Instance.new("UIStroke", Sidebar).Transparency = 0.3

local SideLayout = Instance.new("UIListLayout", Sidebar); SideLayout.Padding = UDim.new(0,8); SideLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
local SearchBox = Instance.new("TextBox", Sidebar); SearchBox.Size = UDim2.new(0,170,0,32); SearchBox.BackgroundColor3 = Theme.Hover; SearchBox.Font = Enum.Font.Gotham; SearchBox.TextSize = 12; SearchBox.TextColor3 = Theme.Text; SearchBox.PlaceholderText = "🔍 Search..."; SearchBox.PlaceholderColor3 = Theme.SubText; SearchBox.Text = ""; SearchBox.ClearTextOnFocus = false; Instance.new("UICorner", SearchBox).CornerRadius = UDim.new(0,8); Instance.new("UIPadding", SearchBox).PaddingLeft = UDim.new(0,10); table.insert(AdjustableFrames, SearchBox)

local Pages, TabButtons = {}, {}
local function CreateTab(name)
    local Btn = Instance.new("TextButton"); Btn.Size = UDim2.new(0,170,0,36); Btn.BackgroundColor3 = Theme.Sec; Btn.BackgroundTransparency = 1; Btn.Text = "   " .. name; Btn.Font = Enum.Font.GothamBold; Btn.TextSize = 13; Btn.TextColor3 = Theme.SubText; Btn.TextXAlignment = Enum.TextXAlignment.Left; Btn.Parent = Sidebar; Instance.new("UICorner", Btn).CornerRadius = UDim.new(0,8); Btn.ZIndex = 6
    local Ind = Instance.new("Frame", Btn); Ind.Size = UDim2.new(0,3,0,0); Ind.Position = UDim2.new(0,0,0.2,0); Ind.BackgroundColor3 = Theme.Accent; Ind.BorderSizePixel = 0; Ind.ZIndex = 7; Instance.new("UICorner", Ind).CornerRadius = UDim.new(0,2)
    local Page = Instance.new("ScrollingFrame"); Page.Size = UDim2.new(1,-230,1,-75); Page.Position = UDim2.new(0,225,0,60); Page.BackgroundTransparency = 1; Page.ScrollBarThickness = 4; Page.ScrollBarImageColor3 = Theme.Accent; Page.CanvasSize = UDim2.new(0,0,0,0); Page.AutomaticCanvasSize = Enum.AutomaticSize.Y; Page.Visible = false; Page.ZIndex = 4; Page.Parent = MainUI
    Instance.new("UIListLayout", Page).Padding = UDim.new(0,10)
    Btn.MouseButton1Click:Connect(function()
        for _,p in pairs(Pages) do p.Visible=false end; for _,b in pairs(TabButtons) do SmoothTween(b,0.2,{BackgroundTransparency=1,TextColor3=Theme.SubText}); SmoothTween(b:FindFirstChild("Frame"),0.2,{Size=UDim2.new(0,3,0,0)}) end
        Page.Visible=true; SmoothTween(Btn,0.2,{BackgroundTransparency=0,TextColor3=Theme.Text}); SmoothTween(Ind,0.2,{Size=UDim2.new(0,3,0.6,0)})
    end)
    Pages[name]=Page; TabButtons[name]=Btn; return Page
end

local DashboardPage = CreateTab("Dashboard"); local CombatPage = CreateTab("Combat"); local MovementPage = CreateTab("Movement"); local VisualsPage = CreateTab("Visuals"); local SettingsPage = CreateTab("Settings"); local ConfigPage = CreateTab("Config"); local AboutPage = CreateTab("About")
Pages["Dashboard"].Visible = true; TabButtons["Dashboard"].BackgroundTransparency = 0; TabButtons["Dashboard"].TextColor3 = Theme.Text; TabButtons["Dashboard"]:FindFirstChild("Frame").Size = UDim2.new(0,3,0.6,0)

-- ==========================================
-- UI BUILDERS (SOLID ANTI-GELAP)
-- ==========================================
local function CreateSlider(text, page, settingName, minV, maxV)
    local Frame = Instance.new("Frame", page); Frame.Size = UDim2.new(1,-10,0,45); Frame.BackgroundColor3 = Theme.Sec; Frame.BackgroundTransparency = Settings.UITransparency; Instance.new("UICorner", Frame).CornerRadius = UDim.new(0,8); table.insert(AdjustableFrames, Frame)
    local Label = Instance.new("TextLabel", Frame); Label.Size = UDim2.new(0,200,0,20); Label.Position = UDim2.new(0,15,0,5); Label.BackgroundTransparency = 1; Label.Font = Enum.Font.GothamBold; Label.TextSize = 12; Label.TextColor3 = Theme.Text; Label.TextXAlignment = Enum.TextXAlignment.Left; Label.Text = text .. ": " .. tostring(Settings[settingName])
    local ValLbl = Instance.new("TextLabel", Frame); ValLbl.Size = UDim2.new(0,50,0,20); ValLbl.Position = UDim2.new(1,-65,0,5); ValLbl.BackgroundTransparency = 1; ValLbl.Font = Enum.Font.GothamBold; ValLbl.TextSize = 12; ValLbl.TextColor3 = Theme.Accent; ValLbl.TextXAlignment = Enum.TextXAlignment.Right; ValLbl.Text = tostring(Settings[settingName])
    local Bar = Instance.new("TextButton", Frame); Bar.Size = UDim2.new(1,-30,0,6); Bar.Position = UDim2.new(0,15,0,32); Bar.BackgroundColor3 = Theme.Hover; Bar.Text = ""; Bar.AutoButtonColor = false; Instance.new("UICorner", Bar).CornerRadius = UDim.new(0,3)
    local Fill = Instance.new("Frame", Bar); Fill.Size = UDim2.new((Settings[settingName]-minV)/(maxV-minV),0,1,0); Fill.BackgroundColor3 = Theme.Accent; Fill.BorderSizePixel = 0; Instance.new("UICorner", Fill).CornerRadius = UDim.new(0,3)
    local Thumb = Instance.new("Frame", Bar); Thumb.Size = UDim2.new(0,12,0,12); Thumb.Position = UDim2.new((Settings[settingName]-minV)/(maxV-minV),-6,0.5,-6); Thumb.BackgroundColor3 = Theme.Text; Thumb.BorderSizePixel = 0; Instance.new("UICorner", Thumb).CornerRadius = UDim.new(1,0)
    local function upd(input) local p=math.clamp((input.Position.X-Bar.AbsolutePosition.X)/Bar.AbsoluteSize.X,0,1); local v=math.floor((minV+(maxV-minV)*p)*100)/100; Settings[settingName]=v; Fill.Size=UDim2.new(p,0,1,0); Thumb.Position=UDim2.new(p,-6,0.5,-6); Label.Text=text..": "..tostring(v); ValLbl.Text=tostring(v); if settingName=="UITransparency" then UpdateUITransparency() end end
    Bar.MouseButton1Down:Connect(function() DraggingSlider=upd end)
end

local function CreateToggle(text, page, settingName)
    local Btn = Instance.new("TextButton", page); Btn.Size = UDim2.new(1,-10,0,38); Btn.BackgroundColor3 = Theme.Sec; Btn.BackgroundTransparency = Settings.UITransparency; Btn.Text = ""; Btn.AutoButtonColor = false; Instance.new("UICorner", Btn).CornerRadius = UDim.new(0,8); table.insert(AdjustableFrames, Btn)
    local Label = Instance.new("TextLabel", Btn); Label.Size = UDim2.new(1,-80,1,0); Label.Position = UDim2.new(0,15,0,0); Label.BackgroundTransparency = 1; Label.Font = Enum.Font.GothamBold; Label.TextSize = 12; Label.TextColor3 = Theme.SubText; Label.TextXAlignment = Enum.TextXAlignment.Left; Label.Text = text
    local SwitchBg = Instance.new("Frame", Btn); SwitchBg.Size = UDim2.new(0,40,0,20); SwitchBg.Position = UDim2.new(1,-55,0.5,-10); SwitchBg.BackgroundColor3 = Theme.Hover; Instance.new("UICorner", SwitchBg).CornerRadius = UDim.new(1,0)
    local Knob = Instance.new("Frame", SwitchBg); Knob.Size = UDim2.new(0,16,0,16); Knob.Position = UDim2.new(0,2,0.5,-8); Knob.BackgroundColor3 = Theme.Text; Knob.BorderSizePixel = 0; Instance.new("UICorner", Knob).CornerRadius = UDim.new(1,0)
    local function setVis() local s=Settings[settingName]; SmoothTween(Knob,0.25,{Position=s and UDim2.new(1,-18,0.5,-8) or UDim2.new(0,2,0.5,-8)}); SmoothTween(SwitchBg,0.25,{BackgroundColor3=s and Theme.Accent or Theme.Hover}); SmoothTween(Label,0.25,{TextColor3=s and Theme.Text or Theme.SubText}) end
    Btn.MouseButton1Click:Connect(function() Settings[settingName]=not Settings[settingName]; setVis(); ShowNotification("Toggle",text.." status: "..(Settings[settingName] and "ON" or "OFF"),2) end); setVis()
    table.insert(ToggleRefs, {Btn=Btn, SwitchBg=SwitchBg, Knob=Knob, Label=Label, Text=text, SettingName=settingName})
end

local function CreateButton(text, page, cb)
    local Btn = Instance.new("TextButton", page); Btn.Size = UDim2.new(1,-10,0,38); Btn.BackgroundColor3 = Theme.Hover; Btn.BackgroundTransparency = Settings.UITransparency; Btn.Text = text; Btn.Font = Enum.Font.GothamBold; Btn.TextSize = 12; Btn.TextColor3 = Theme.Text; Instance.new("UICorner", Btn).CornerRadius = UDim.new(0,8); table.insert(AdjustableFrames, Btn)
    Btn.MouseEnter:Connect(function() SmoothTween(Btn,0.2,{BackgroundTransparency=math.clamp(Settings.UITransparency-0.3,0,1),TextColor3=Theme.Accent}) end)
    Btn.MouseLeave:Connect(function() SmoothTween(Btn,0.2,{BackgroundTransparency=Settings.UITransparency,TextColor3=Theme.Text}) end)
    Btn.MouseButton1Click:Connect(function() pcall(cb) end)
end

function UpdateUITransparency() for _,f in ipairs(AdjustableFrames) do if f and f.Parent then f.BackgroundTransparency = Settings.UITransparency end end end

-- ==========================================
-- POPULATING TABS
-- ==========================================
DashboardPage:FindFirstChildOfClass("UIListLayout"):Destroy()
local DbLeft = Instance.new("Frame", DashboardPage); DbLeft.Size = UDim2.new(0,280,1,0); DbLeft.BackgroundTransparency = 1; Instance.new("UIListLayout", DbLeft).Padding = UDim.new(0,15)
local ProfileCard = Instance.new("Frame", DbLeft); ProfileCard.Size = UDim2.new(1,0,0,160); ProfileCard.BackgroundColor3 = Theme.Sec; ProfileCard.BackgroundTransparency = Settings.UITransparency; Instance.new("UICorner", ProfileCard).CornerRadius = UDim.new(0,10); Instance.new("UIStroke", ProfileCard).Color = Theme.Hover; table.insert(AdjustableFrames, ProfileCard)
local AvatarImage = Instance.new("ImageLabel", ProfileCard); AvatarImage.Size = UDim2.new(0,65,0,65); AvatarImage.Position = UDim2.new(0,15,0,15); AvatarImage.BackgroundColor3 = Theme.Hover; AvatarImage.Image = "rbxthumb://type=AvatarHeadShot&id="..LocalPlayer.UserId.."&w=150&h=150"; Instance.new("UICorner", AvatarImage).CornerRadius = UDim.new(1,0); Instance.new("UIStroke", AvatarImage).Color = Theme.Accent
local DNameLabel = Instance.new("TextLabel", ProfileCard); DNameLabel.Size = UDim2.new(1,-100,0,22); DNameLabel.Position = UDim2.new(0,95,0,18); DNameLabel.Font = Enum.Font.GothamBlack; DNameLabel.TextSize = 16; DNameLabel.TextColor3 = Theme.Text; DNameLabel.Text = LocalPlayer.DisplayName; DNameLabel.TextXAlignment = Enum.TextXAlignment.Left; DNameLabel.BackgroundTransparency = 1
local UNameLabel = Instance.new("TextLabel", ProfilePage); UNameLabel.Size = UDim2.new(1,-100,0,18); UNameLabel.Position = UDim2.new(0,95,0,38); UNameLabel.Font = Enum.Font.Gotham; UNameLabel.TextSize = 12; UNameLabel.TextColor3 = Theme.SubText; UNameLabel.Text = "@"..LocalPlayer.Name; UNameLabel.TextXAlignment = Enum.TextXAlignment.Left; UNameLabel.BackgroundTransparency = 1
local ProfileInfo = Instance.new("TextLabel", ProfileCard); ProfileInfo.Size = UDim2.new(1,-30,0,80); ProfileInfo.Position = UDim2.new(0,15,0,90); ProfileInfo.Font = Enum.Font.Code; ProfileInfo.TextSize = 11; ProfileInfo.TextColor3 = Theme.SubText; ProfileInfo.TextXAlignment = Enum.TextXAlignment.Left; ProfileInfo.BackgroundTransparency = 1; ProfileInfo.TextWrapped = true
local placeName = "Unknown"; pcall(function() placeName = MarketplaceService:GetProductInfo(game.PlaceId).Name end); ProfileInfo.Text = string.format("USER ID: %d\nEXEC: %s\nGAME: %s\nJOINED: %s", LocalPlayer.UserId, currentExecutor, placeName, os.date("%X"))

local DbRight = Instance.new("Frame", DashboardPage); DbRight.Size = UDim2.new(0,280,1,0); DbRight.Position = UDim2.new(0,300,0,0); DbRight.BackgroundTransparency = 1; Instance.new("UIListLayout", DbRight).Padding = UDim.new(0,15)
local StatsCard = Instance.new("Frame", DbRight); StatsCard.Size = UDim2.new(1,0,0,160); StatsCard.BackgroundColor3 = Theme.Sec; StatsCard.BackgroundTransparency = Settings.UITransparency; Instance.new("UICorner", StatsCard).CornerRadius = UDim.new(0,10); Instance.new("UIStroke", StatsCard).Color = Theme.Hover; table.insert(AdjustableFrames, StatsCard)
local StatsTitle = Instance.new("TextLabel", StatsCard); StatsTitle.Size = UDim2.new(1,-20,0,30); StatsTitle.Position = UDim2.new(0,15,0,10); StatsTitle.Font = Enum.Font.GothamBold; StatsTitle.TextSize = 14; StatsTitle.TextColor3 = Theme.Accent; StatsTitle.Text = "📊 LIVE STATISTICS"; StatsTitle.TextXAlignment = Enum.TextXAlignment.Left; StatsTitle.BackgroundTransparency = 1
local StatsContent = Instance.new("TextLabel", StatsCard); StatsContent.Size = UDim2.new(1,-30,0,110); StatsContent.Position = UDim2.new(0,15,0,40); StatsContent.Font = Enum.Font.GothamMedium; StatsContent.TextSize = 13; StatsContent.TextColor3 = Theme.Text; StatsContent.TextXAlignment = Enum.TextXAlignment.Left; StatsContent.BackgroundTransparency = 1
task.spawn(function() while MainUI.Parent do local dur=os.time()-StartTime; local m=math.floor(dur/60); local s=dur%60; local lead=LocalPlayer:FindFirstChild("leaderstats"); local ms="N/A"; local ks="N/A"; if lead then local c=lead:FindFirstChild("Cash")or lead:FindFirstChild("Coins")or lead:FindFirstChild("Money"); local k=lead:FindFirstChild("Kills")or lead:FindFirstChild("Kills Counter"); if c then ms=tostring(c.Value) end; if k then ks=tostring(k.Value) end end; StatsContent.Text=string.format("Session Time :  %02dm %02ds\n\nWallet/Cash  :  %s\n\nConfirmed Kills:  %s",m,s,ms,ks); task.wait(1) end end)

-- COMBAT
CreateToggle("Master Activation", CombatPage, "Master"); CreateToggle("Aimbot (Instant Lock)", CombatPage, "Aimbot"); CreateToggle("Aim Assist (Magnet)", CombatPage, "AimAssist"); CreateToggle("Triggerbot Active", CombatPage, "Triggerbot"); CreateToggle("Spinbot Matrix", CombatPage, "Spinbot"); CreateToggle("Aim at Bots/NPC", CombatPage, "AimBots")
local TargetPartBtn = Instance.new("TextButton", CombatPage); TargetPartBtn.Size = UDim2.new(1,-10,0,38); TargetPartBtn.BackgroundColor3 = Theme.Sec; TargetPartBtn.BackgroundTransparency = Settings.UITransparency; TargetPartBtn.Font = Enum.Font.GothamBold; TargetPartBtn.TextSize = 12; TargetPartBtn.TextColor3 = Theme.Accent; TargetPartBtn.TextXAlignment = Enum.TextXAlignment.Left; TargetPartBtn.Text = "      Target Part: Body"; TargetPartBtn.AutoButtonColor = false; Instance.new("UICorner", TargetPartBtn).CornerRadius = UDim.new(0,8); Instance.new("UIPadding", TargetPartBtn).PaddingLeft = UDim.new(0,15); table.insert(AdjustableFrames, TargetPartBtn)
local function updTP() local p=Settings.TargetPart; local d="Pelvis (Root)"; if p=="Head" then d="Head" elseif p=="Torso" then d="Body" end; TargetPartBtn.Text="      Target Part: "..d end
TargetPartBtn.MouseButton1Click:Connect(function() if Settings.TargetPart=="HumanoidRootPart" then Settings.TargetPart="Head" elseif Settings.TargetPart=="Head" then Settings.TargetPart="Torso" else Settings.TargetPart="HumanoidRootPart" end; updTP() end); updTP()
CreateButton("Teleport to Closest [T]", CombatPage, function() if CurrentTarget and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then LocalPlayer.Character.HumanoidRootPart.CFrame=CurrentTarget.CFrame*CFrame.new(0,0,3); ShowNotification("Teleport","Teleported to target.",2) end end)
CreateSlider("Smoothness", CombatPage, "Smoothness", 0.05, 1); CreateSlider("FOV Size", CombatPage, "FOV", 20, 600); CreateToggle("Show FOV Radius", CombatPage, "ShowFOV")

-- MOVEMENT
CreateToggle("Fly System [F]", MovementPage, "Fly"); CreateSlider("Flight Speed", MovementPage, "FlySpeed", 10, 300); CreateToggle("Speed Engine [V]", MovementPage, "SpeedHack"); CreateSlider("Velocity Speed", MovementPage, "WalkSpeed", 16, 250); CreateToggle("NoClip Phase [N]", MovementPage, "NoClip")

-- VISUALS
CreateToggle("Active ESP Masters", VisualsPage, "ESP"); CreateToggle("Render Chams (Highlight)", VisualsPage, "ESPChams"); CreateToggle("Render ESP 2D Box", VisualsPage, "ESPBox"); CreateToggle("Render Snap Lines", VisualsPage, "ESPLine"); CreateToggle("Render Bone Skeleton", VisualsPage, "ESPSkeleton"); CreateToggle("Track Target Bots/NPC", VisualsPage, "ESPBots"); CreateToggle("Team Discrimination Check", VisualsPage, "TeamCheck"); CreateToggle("Occlusion Wall Check", VisualsPage, "WallCheck"); CreateToggle("Dynamic Rainbow Chroma", VisualsPage, "IsRainbow")

-- SETTINGS
CreateSlider("UI Transparency", SettingsPage, "UITransparency", 0, 0.9)
CreateButton("Set Neon Green Color", SettingsPage, function() Settings.IsRainbow=false; Settings.ThemeColor=Color3.fromRGB(0,255,102); UpdateTheme() end)
CreateButton("Set Crimson Red Color", SettingsPage, function() Settings.IsRainbow=false; Settings.ThemeColor=Color3.fromRGB(255,64,64); UpdateTheme() end)
CreateButton("Set Electric Blue Color", SettingsPage, function() Settings.IsRainbow=false; Settings.ThemeColor=Color3.fromRGB(80,150,255); UpdateTheme() end)

-- CONFIG
local ConfigNameBox = Instance.new("TextBox", ConfigPage); ConfigNameBox.Size = UDim2.new(1,-10,0,38); ConfigNameBox.BackgroundColor3 = Theme.Sec; ConfigNameBox.BackgroundTransparency = Settings.UITransparency; ConfigNameBox.Font = Enum.Font.Gotham; ConfigNameBox.TextSize = 12; ConfigNameBox.TextColor3 = Theme.Text; ConfigNameBox.PlaceholderText = "Enter Config Name..."; ConfigNameBox.PlaceholderColor3 = Theme.SubText; ConfigNameBox.TextXAlignment = Enum.TextXAlignment.Left; Instance.new("UICorner", ConfigNameBox).CornerRadius = UDim.new(0,8); Instance.new("UIPadding", ConfigNameBox).PaddingLeft = UDim.new(0,15); table.insert(AdjustableFrames, ConfigNameBox)
CreateButton("Save Configuration File", ConfigPage, function() if writefile then local f=(ConfigNameBox.Text~="" and ConfigNameBox.Text or "premium_default")..".qee"; local o={}; for k,v in pairs(Settings) do if type(v)~="table" and type(v)~="userdata" then o[k]=v end end; writefile(f, HttpService:JSONEncode(o)); ShowNotification("Success","Configuration saved!",3) end end)
CreateButton("Load Configuration File", ConfigPage, function() if readfile and isfile then local f=(ConfigNameBox.Text~="" and ConfigNameBox.Text or "premium_default")..".qee"; if isfile(f) then local d=HttpService:JSONDecode(readfile(f)); for k,v in pairs(d) do Settings[k]=v end; UpdateTheme(); UpdateUITransparency(); ShowNotification("Success","Configuration loaded!",3) end end end)

-- ABOUT
local AboutCard = Instance.new("Frame", AboutPage); AboutCard.Size = UDim2.new(1,-10,0,200); AboutCard.BackgroundColor3 = Theme.Sec; AboutCard.BackgroundTransparency = Settings.UITransparency; Instance.new("UICorner", AboutCard).CornerRadius = UDim.new(0,10); table.insert(AdjustableFrames, AboutCard)
local AboutTitle = Instance.new("TextLabel", AboutCard); AboutTitle.Size = UDim2.new(1,0,0,40); AboutTitle.Position = UDim2.new(0,0,0,10); AboutTitle.BackgroundTransparency = 1; AboutTitle.Font = Enum.Font.GothamBlack; AboutTitle.TextSize = 24; AboutTitle.TextColor3 = Theme.Accent; AboutTitle.Text = "QeeHacker Premium"
local AboutText = Instance.new("TextLabel", AboutCard); AboutText.Size = UDim2.new(1,-30,0,100); AboutText.Position = UDim2.new(0,15,0,60); AboutText.BackgroundTransparency = 1; AboutText.Font = Enum.Font.Gotham; AboutText.TextSize = 12; AboutText.TextColor3 = Theme.SubText; AboutText.TextWrapped = true; AboutText.Text = "Version: v13\nBuild: 2024\nDeveloper: Qee\nDiscord: N/A\nWebsite: N/A\n\nSpecial Thanks to all Qee Users."; AboutText.TextXAlignment = Enum.TextXAlignment.Left; AboutText.TextYAlignment = Enum.TextYAlignment.Top

-- ==========================================
-- LOGIC & HOOKS
-- ==========================================
local function getRoot(m) if not m then return nil end; if Settings.TargetPart=="Head" then return m:FindFirstChild("Head")or m:FindFirstChild("HumanoidRootPart")or m.PrimaryPart elseif Settings.TargetPart=="Torso" then return m:FindFirstChild("Torso")or m:FindFirstChild("UpperTorso")or m:FindFirstChild("HumanoidRootPart")or m.PrimaryPart else return m:FindFirstChild("HumanoidRootPart")or m:FindFirstChild("Torso")or m:FindFirstChild("UpperTorso")or m:FindFirstChild("Head")or m.PrimaryPart end end
local function canSee(part) if not Settings.WallCheck then return true end; local par=RaycastParams.new(); par.FilterType=Enum.RaycastFilterType.Exclude; par.FilterDescendantsInstances={LocalPlayer.Character,part.Parent}; local res=Workspace:Raycast(Camera.CFrame.Position,part.Position-Camera.CFrame.Position,par); return not res end
local function isValid(m) if not m or not m.Parent or m==LocalPlayer.Character then return false end; local hum=m:FindFirstChildOfClass("Humanoid"); local root=getRoot(m); if not hum or not root or hum.Health<=0 then return false end; local p=Players:GetPlayerFromCharacter(m); if p then if Settings.TeamCheck and LocalPlayer.Team and p.Team and LocalPlayer.Team==p.Team then return false end; return true else return Settings.AimBots or Settings.ESPBots end end

local function createEsp(model) local e={}; e.Highlight=Instance.new("Highlight"); e.Highlight.Adornee=model; e.Highlight.FillColor=Theme.Accent; e.Highlight.OutlineColor=Color3.new(1,1,1); e.Highlight.FillTransparency=0.5; e.Highlight.DepthMode=Enum.HighlightDepthMode.AlwaysOnTop; e.Highlight.Enabled=false; e.Highlight.Parent=Gui
e.Box=Drawing.new("Square"); e.Box.Thickness=2; e.Box.Filled=false; e.Box.Visible=false; e.Line=Drawing.new("Line"); e.Line.Thickness=1.5; e.Line.Visible=false
e.Skel={}; for i=1,6 do local l=Drawing.new("Line"); l.Thickness=2; l.Visible=false; table.insert(e.Skel,l) end; return e end
local function clearEsp(m) local e=EspObjects[m]; if not e then return end; pcall(function() if e.Highlight then e.Highlight:Destroy() end end); pcall(function() e.Box:Remove() end); pcall(function() e.Line:Remove() end); for _,l in ipairs(e.Skel) do pcall(function() l:Remove() end) end; EspObjects[m]=nil end

local fovCircle = Drawing.new("Circle"); fovCircle.Thickness=1.5; fovCircle.NumSides=60; fovCircle.Filled=false

function UpdateTheme() MainStroke.Color=Settings.ThemeColor; AvatarImage.UIStroke.Color=Settings.ThemeColor; StatsTitle.TextColor3=Settings.ThemeColor; HTitle.TextColor3=Settings.ThemeColor; TargetPartBtn.TextColor3=Settings.ThemeColor; Logo.TextColor3=Settings.ThemeColor
for _,ref in ipairs(ToggleRefs) do if ref.Btn and ref.Btn.Parent then local s=Settings[ref.SettingName]; ref.SwitchBg.BackgroundColor3=s and Settings.ThemeColor or Theme.Hover; ref.Label.TextColor3=s and Theme.Text or Theme.SubText end end end

-- NOCLIP
RunService.Stepped:Connect(function() if Settings.NoClip then pcall(function() if LocalPlayer.Character then for _,part in pairs(LocalPlayer.Character:GetDescendants()) do if part:IsA("BasePart") then part.CanCollide=false end end end end) end end)

RunService.RenderStepped:Connect(function(dt)
    local now=os.clock(); table.insert(fpsTable,now); while fpsTable[1] and fpsTable[1]<now-1 do table.remove(fpsTable,1) end; currentFPS=#fpsTable
    local np="0"; pcall(function() np=string.format("%.0f",LocalPlayer:GetNetworkPing()*1000) end); LiveMetrics.Text=string.format("FPS: %d | PING: %sms | CLOCK: %s",currentFPS,np,os.date("%X"))
    if Settings.IsRainbow then Settings.ThemeColor=Color3.fromHSV((os.clock()%6)/6,0.9,1); UpdateTheme() end
    local mL=UserInputService:GetMouseLocation(); fovCircle.Position=mL; fovCircle.Radius=Settings.FOV; fovCircle.Visible=Settings.Master and Settings.ShowFOV; fovCircle.Color=Settings.ThemeColor
    if not Settings.Master then CurrentTarget=nil; return end
    
    local closest=nil; local shortDist=Settings.FOV
    for _,p in ipairs(Players:GetPlayers()) do if p~=LocalPlayer and p.Character and isValid(p.Character) then local root=getRoot(p.Character); if root and canSee(root) then local pos,on=Camera:WorldToViewportPoint(root.Position); if on then local d=(Vector2.new(pos.X,pos.Y)-mL).Magnitude; if d<shortDist then shortDist=d; closest=root end end end end end
    CurrentTarget=closest
    
    if CurrentTarget then local aimC=CFrame.lookAt(Camera.CFrame.Position,CurrentTarget.Position)
        if Settings.Aimbot then Camera.CFrame=aimC elseif Settings.AimAssist then Camera.CFrame=Camera.CFrame:Lerp(aimC,math.clamp(Settings.Smoothness*(dt*60),0,1)) end
        if Settings.Triggerbot then if tick()-LastTriggerClick>Settings.TriggerbotDelay then pcall(function() mouse1press(); task.wait(0.01); mouse1release() end); LastTriggerClick=tick() end end
    end
    
    local char=LocalPlayer.Character; if char then local hum=char:FindFirstChildOfClass("Humanoid"); local root=char:FindFirstChild("HumanoidRootPart")
        if hum then hum.WalkSpeed=Settings.SpeedHack and Settings.WalkSpeed or 16 end
        if Settings.Fly and root and hum then local v=Vector3.zero; if UserInputService:IsKeyDown(Enum.KeyCode.W) then v=v+Camera.CFrame.LookVector end; if UserInputService:IsKeyDown(Enum.KeyCode.S) then v=v-Camera.CFrame.LookVector end; if UserInputService:IsKeyDown(Enum.KeyCode.A) then v=v-Camera.CFrame.RightVector end; if UserInputService:IsKeyDown(Enum.KeyCode.D) then v=v+Camera.CFrame.RightVector end
            root.AssemblyLinearVelocity=v.Magnitude>0 and v.Unit*Settings.FlySpeed or Vector3.zero; hum.PlatformStand=true
        elseif hum then hum.PlatformStand=false end
        if Settings.Spinbot and root then root.CFrame=root.CFrame*CFrame.Angles(0,math.rad(Settings.SpinSpeed),0) end
    end
    
    local activeMap={}; for _,p in ipairs(Players:GetPlayers()) do if p.Character and isValid(p.Character) then activeMap[p.Character]=p end end
    for model,esp in pairs(EspObjects) do if not activeMap[model] or not Settings.ESP then clearEsp(model) end end
    if Settings.ESP then for model,p in pairs(activeMap) do local root=getRoot(model); local head=model:FindFirstChild("Head"); if root and head then local rP,rO=Camera:WorldToViewportPoint(root.Position)
        local esp=EspObjects[model] or createEsp(model); EspObjects[model]=esp; esp.Highlight.Enabled=Settings.ESPChams; esp.Highlight.FillColor=Settings.ThemeColor
        if rO then local hP=Camera:WorldToViewportPoint(head.Position+Vector3.new(0,1.6,0)); local lP=Camera:WorldToViewportPoint(root.Position-Vector3.new(0,3,0)); local bH=math.abs(hP.Y-lP.Y); local bW=bH*0.65
            esp.Box.Visible=Settings.ESPBox; if Settings.ESPBox then esp.Box.Size=Vector2.new(bW,bH); esp.Box.Position=Vector2.new(rP.X-bW/2,hP.Y); esp.Box.Color=Settings.ThemeColor end
            esp.Line.Visible=Settings.ESPLine; if Settings.ESPLine then esp.Line.From=Vector2.new(Camera.ViewportSize.X/2,Camera.ViewportSize.Y); esp.Line.To=Vector2.new(rP.X,rP.Y); esp.Line.Color=Settings.ThemeColor end
            if Settings.ESPSkeleton then local function gJ(pN) local pt=model:FindFirstChild(pN); if pt then local vp,o=Camera:WorldToViewportPoint(pt.Position); return o and Vector2.new(vp.X,vp.Y) or nil end end
                local j={H=gJ("Head"),T=gJ("UpperTorso")or gJ("Torso")or gJ("HumanoidRootPart"),LA=gJ("LeftArm")or gJ("LeftUpperArm"),RA=gJ("RightArm")or gJ("RightUpperArm"),LL=gJ("LeftLeg")or gJ("LeftUpperLeg"),RL=gJ("RightLeg")or gJ("RightUpperLeg")}
                if j.H and j.T then esp.Skel[1].From=j.H;esp.Skel[1].To=j.T;esp.Skel[1].Visible=true;esp.Skel[1].Color=Settings.ThemeColor else esp.Skel[1].Visible=false end
                if j.T and j.LA then esp.Skel[2].From=j.T;esp.Skel[2].To=j.LA;esp.Skel[2].Visible=true;esp.Skel[2].Color=Settings.ThemeColor else esp.Skel[2].Visible=false end
                if j.T and j.RA then esp.Skel[3].From=j.T;esp.Skel[3].To=j.RA;esp.Skel[3].Visible=true;esp.Skel[3].Color=Settings.ThemeColor else esp.Skel[3].Visible=false end
                if j.T and j.LL then esp.Skel[4].From=j.T;esp.Skel[4].To=j.LL;esp.Skel[4].Visible=true;esp.Skel[4].Color=Settings.ThemeColor else esp.Skel[4].Visible=false end
                if j.T and j.RL then esp.Skel[5].From=j.T;esp.Skel[5].To=j.RL;esp.Skel[5].Visible=true;esp.Skel[5].Color=Settings.ThemeColor else esp.Skel[5].Visible=false end
            else for _,l in ipairs(esp.Skel) do l.Visible=false end end
        else esp.Box.Visible=false; esp.Line.Visible=false; for _,l in ipairs(esp.Skel) do l.Visible=false end end
    end end end
end)

UserInputService.InputBegan:Connect(function(input,gp)
    if gp then return end
    if input.KeyCode==Enum.KeyCode.RightShift then
        MainUI.Visible = not MainUI.Visible
        -- BULLETPROOF RE-OPEN: Selalu reset transparansi pas dibuka!
        if MainUI.Visible then MainUI.BackgroundTransparency=1; MainUIScale.Scale=0.8; SmoothTween(MainUI,0.3,{BackgroundTransparency=Settings.UITransparency}); SmoothTween(MainUIScale,0.3,{Scale=1}) end
    elseif input.KeyCode==Enum.KeyCode.F then Settings.Fly=not Settings.Fly; ShowNotification("Fly","Flight: "..tostring(Settings.Fly),2)
    elseif input.KeyCode==Enum.KeyCode.V then Settings.SpeedHack=not Settings.SpeedHack; ShowNotification("Speed","Velocity: "..tostring(Settings.SpeedHack),2)
    elseif input.KeyCode==Enum.KeyCode.N then Settings.NoClip=not Settings.NoClip; ShowNotification("NoClip","Phase: "..tostring(Settings.NoClip),2)
    elseif input.KeyCode==Enum.KeyCode.T then if CurrentTarget and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then LocalPlayer.Character.HumanoidRootPart.CFrame=CurrentTarget.CFrame*CFrame.new(0,0,3); ShowNotification("Teleport","Teleported.",2) end
    end
end)
UserInputService.InputEnded:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then DraggingSlider=nil end end)
UserInputService.InputChanged:Connect(function(i) if DraggingSlider and i.UserInputType==Enum.UserInputType.MouseMovement then DraggingSlider(i) end end)

-- ==========================================
-- INTRO EXECUTION
-- ==========================================
task.spawn(function()
    pcall(function() SmoothTween(IntroText,1.0,{Position=UDim2.new(0.5,0,0.5,0)}); task.wait(2.5); SmoothTween(IntroText,0.5,{TextTransparency=1}); task.wait(0.5); SmoothTween(IntroFrame,0.5,{BackgroundTransparency=1}); task.wait(0.5); IntroFrame:Destroy() end)
    MainUI.Visible=true; MainUI.BackgroundTransparency=1; MainUIScale.Scale=0.8
    SmoothTween(MainUI,0.4,{BackgroundTransparency=Settings.UITransparency}); SmoothTween(MainUIScale,0.4,{Scale=1})
    ShowNotification("Success","Welcome, Qee! Core system operational.",4)
end)

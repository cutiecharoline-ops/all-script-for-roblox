-- QeeHacker Client (PC/Laptop Only - V10 - Silent Aim Fixed No Lag No Teleport)
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

-- Variable Cache buat Silent Aim Mouse Hook Biar Ga Lag
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
        if method == "Kick" and self == LocalPlayer then
            return nil
        end
        
        if Settings.SilentAim and Settings.Enabled and CachedSilentHit and not checkcaller() then
            local args = {...}
            local isRaycast = (method == "Raycast")
            local isRayMethod = (method == "FindPartOnRayWithIgnoreList" or method == "FindPartOnRay" or method == "FindPartOnRayWithWhitelist")
            
            if isRaycast or isRayMethod then
                local origin, direction
                if isRaycast then
                    origin = args[1]
                    direction = args[2]
                else
                    local r = args[1]
                    if r and typeof(r) == "Ray" then
                        origin = r.Origin
                        direction = r.Direction
                    end
                end
                
                -- FILTER PINTAR: Cuma ubah arah kalo jarak peluru lebih dari 50 studs (Biar kaki/tanah gak ikut ubah)
                if origin and direction and direction.Magnitude > 50 then
                    local targetPos = CachedSilentHit.Position
                    local newDir = (targetPos - origin)
                    if newDir.Magnitude > 0 then
                        if isRaycast then
                            args[2] = newDir.Unit * direction.Magnitude -- Samain jarak aslinya biar tembus wall check game
                        else
                            args[1] = Ray.new(origin, newDir.Unit * direction.Magnitude)
                        end
                        return oldNamecall(self, table.unpack(args))
                    end
                end
            end
        end
        
        return oldNamecall(self, ...)
    end)

    -- Hook Mouse Hit & Target (Cuma baca cache, 0 rumus math, dijamin 0 lag)
    mt.__index = newcclosure(function(self, key)
        if Settings.SilentAim and Settings.Enabled and CachedSilentHit and typeof(self) == "Instance" and self:IsA("Mouse") then
            if key == "Hit" then
                return CachedSilentHit
            elseif key == "Target" or key == "target" then
                return CachedSilentTargetPart
            end
        end
        return oldIndex(self, key)
    end)
    
    setreadonly(mt, true)
end)

-- [SFX HELPER]
local function playSFX(id)
    pcall(function()
        local s = Instance.new("Sound")
        s.SoundId = id; s.Volume = 0.5; s.Parent = SoundService; s:Play()
        task.delay(5, function() s:Destroy() end)
    end)
end

-- [ULTRA OPTIMIZATION]
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

-- [1] PASSWORD SYSTEM
local PASSWORD = "Qee Only"
local PlayerGui
pcall(function() PlayerGui = LocalPlayer:WaitForChild("PlayerGui", 30) end)
if not PlayerGui then return end

local PassGui = Instance.new("ScreenGui", PlayerGui); PassGui.Name = "RbxAuth"; PassGui.ResetOnSpawn = false; PassGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
local PassFrame = Instance.new("Frame", PassGui); PassFrame.Size = UDim2.new(0, 300, 0, 150); PassFrame.Position = UDim2.new(0.5, 0, 0.5, 0); PassFrame.AnchorPoint = Vector2.new(0.5, 0.5); PassFrame.BackgroundColor3 = Color3.fromRGB(12, 12, 16); PassFrame.BorderSizePixel = 0; PassFrame.ClipsDescendants = true; PassFrame.Active = true
Instance.new("UICorner", PassFrame).CornerRadius = UDim.new(0, 8)
local PassStroke = Instance.new("UIStroke", PassFrame); PassStroke.Color = Color3.fromRGB(0, 255, 150); PassStroke.Thickness = 2.5; PassStroke.Transparency = 0.3
local PassTitle = Instance.new("TextLabel", PassFrame); PassTitle.Size = UDim2.new(1, 0, 0, 40); PassTitle.BackgroundTransparency = 1; PassTitle.Font = Enum.Font.GothamBlack; PassTitle.TextSize = 20; PassTitle.TextColor3 = Color3.fromRGB(100, 255, 150); PassTitle.Text = "QeeHacker Authentication"
local PassBox = Instance.new("TextBox", PassFrame); PassBox.Size = UDim2.new(1, -40, 0, 35); PassBox.Position = UDim2.new(0, 20, 0, 55); PassBox.BackgroundColor3 = Color3.fromRGB(25, 25, 32); PassBox.BorderSizePixel = 0; PassBox.Font = Enum.Font.GothamMedium; PassBox.TextSize = 14; PassBox.TextColor3 = Color3.fromRGB(230, 230, 240); PassBox.PlaceholderText = "Enter Password..."; PassBox.PlaceholderColor3 = Color3.fromRGB(100, 100, 120); PassBox.ClearTextOnFocus = false
Instance.new("UICorner", PassBox).CornerRadius = UDim.new(0, 5)
local PassBtn = Instance.new("TextButton", PassFrame); PassBtn.Size = UDim2.new(1, -40, 0, 35); PassBtn.Position = UDim2.new(0, 20, 0, 100); PassBtn.BackgroundColor3 = Color3.fromRGB(0, 210, 90); PassBtn.BorderSizePixel = 0; PassBtn.Font = Enum.Font.GothamBold; PassBtn.TextSize = 14; PassBtn.TextColor3 = Color3.fromRGB(12, 12, 16); PassBtn.Text = "LOGIN"
Instance.new("UICorner", PassBtn).CornerRadius = UDim.new(0, 5)

local function MakeDrag(dragHandle, dragTarget)
    local dragging; local dragInput; local dragStart; local startPos
    dragHandle.InputBegan:Connect(function(input) 
        if input.UserInputType == Enum.UserInputType.MouseButton1 then 
            dragging = true; dragStart = input.Position; startPos = dragTarget.Position 
            input.Changed:Connect(function() if input.UserInputState == Enum.UserInputState.End then dragging = false end end) 
        end 
    end)
    dragHandle.InputChanged:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseMovement then dragInput = input end end)
    UserInputService.InputChanged:Connect(function(input) 
        if input == dragInput and dragging then 
            local delta = input.Position - dragStart
            dragTarget.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y) 
        end 
    end)
end

MakeDrag(PassFrame, PassFrame)

local function InitializeHack()
    PassGui:Destroy()
    
    local OldGui = PlayerGui:FindFirstChild("CoreUI_v2")
    if OldGui then pcall(function() OldGui:Destroy() end) end

    local Gui = Instance.new("ScreenGui")
    Gui.Name = "CoreUI_v2"; Gui.ResetOnSpawn = false; Gui.IgnoreGuiInset = true; Gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling; Gui.Parent = PlayerGui

    local MasterBtn, MasterInd, AimBtn, AimInd, AimModeBtn, TriggerBtn, TriggerInd, AutoKillBtn, AutoKillInd, TargetBtn, TeamBtn, TeamInd, WallBtn, WallInd, EspBtn, EspInd, WarningBtn, WarningInd, FovBtn, FovInd, CrosshairBtn, CrossInd, FlyBtn, FlyInd, AntiLagBtn, AntiLagInd, AWMModeBtn, AWMModeInd, GhostBtn, GhostInd, SilentBtn, SilentInd, SilentTargetBtn, SilentFovBtn, SilentFovInd, TargetPlayerBtn, TargetPlayerInd, TargetBotBtn, TargetBotInd = nil
    local FOVCircleStroke, SilentFOVCircleStroke = nil, nil

    local Panel = Instance.new("Frame"); Panel.Size = UDim2.fromOffset(270, 560); Panel.Position = UDim2.fromOffset(100, 100); Panel.BackgroundColor3 = Color3.fromRGB(12, 12, 16); Panel.BorderSizePixel = 0; Panel.Parent = Gui; Panel.ClipsDescendants = true; Panel.Visible = false; Panel.Active = true
    Instance.new("UICorner", Panel).CornerRadius = UDim.new(0, 8)
    local PanelStroke = Instance.new("UIStroke", Panel); PanelStroke.Color = Settings.ThemeColor; PanelStroke.Thickness = 1.5

    local Header = Instance.new("Frame"); Header.Size = UDim2.new(1, 0, 0, 45); Header.BackgroundTransparency = 1; Header.Parent = Panel; Header.Active = true
    
    local CloseBtn = Instance.new("TextButton"); CloseBtn.Size = UDim2.new(0, 30, 0, 30); CloseBtn.Position = UDim2.new(1, -35, 0, 7); CloseBtn.BackgroundColor3 = Color3.fromRGB(255, 50, 50); CloseBtn.BorderSizePixel = 0; CloseBtn.Font = Enum.Font.GothamBold; CloseBtn.TextSize = 14; CloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255); CloseBtn.Text = "X"; CloseBtn.Parent = Header
    Instance.new("UICorner", CloseBtn).CornerRadius = UDim.new(0, 6)
    local Title = Instance.new("TextLabel"); Title.Size = UDim2.new(1, -45, 0, 25); Title.Position = UDim2.fromOffset(12, 8); Title.BackgroundTransparency = 1; Title.Font = Enum.Font.GothamBlack; Title.TextSize = 22; Title.TextColor3 = Settings.ThemeColor; Title.TextXAlignment = Enum.TextXAlignment.Left; Title.Text = "QeeHacker [PC]"; Title.Parent = Header
    local TitleGlowUI = Instance.new("UIStroke", Title); TitleGlowUI.Color = Settings.ThemeColor; TitleGlowUI.Thickness = 1; TitleGlowUI.Transparency = 0.2
    local Status = Instance.new("TextLabel"); Status.Size = UDim2.new(1, -12, 0, 14); Status.Position = UDim2.fromOffset(12, 32); Status.BackgroundTransparency = 1; Status.Font = Enum.Font.Gotham; Status.TextSize = 11; Status.TextColor3 = Color3.fromRGB(150, 150, 170); Status.TextXAlignment = Enum.TextXAlignment.Left; Status.Text = "Hotkeys: RShift=Menu, F=Fly, G=Ghost"; Status.Parent = Header

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
    local function addCategory(n) local l = Instance.new("Frame"); l.Size = UDim2.new(1, 0, 0, 1); l.BackgroundColor3 = Color3.fromRGB(40, 40, 50); l.BorderSizePixel = 0; l.Parent = ScrollFrame; layoutOrder = layoutOrder + 1; l.LayoutOrder = layoutOrder; local c = Instance.new("TextLabel"); c.Size = UDim2.new(1, 0, 0, 20); c.BackgroundTransparency = 1; c.Font = Enum.Font.GothamBold; c.TextSize = 12; c.TextColor3 = Settings.ThemeColor; c.TextXAlignment = Enum.TextXAlignment.Left; c.Text = string.upper(n); c.Parent = ScrollFrame; layoutOrder = layoutOrder + 1; c.LayoutOrder = layoutOrder end
    local function button(t, cb) local i = Instance.new("TextButton"); i.Size = UDim2.new(1, 0, 0, 30); i.BackgroundColor3 = Color3.fromRGB(25, 25, 32); i.BorderSizePixel = 0; i.Font = Enum.Font.GothamMedium; i.TextSize = 12; i.TextColor3 = Color3.fromRGB(230, 230, 240); i.TextXAlignment = Enum.TextXAlignment.Left; i.Text = "  "..t; i.Parent = ScrollFrame; layoutOrder = layoutOrder + 1; i.LayoutOrder = layoutOrder; Instance.new("UICorner", i).CornerRadius = UDim.new(0, 5); local ind = Instance.new("Frame"); ind.Size = UDim2.new(0, 3, 0.6, 0); ind.Position = UDim2.new(0, 4, 0.2, 0); ind.BackgroundColor3 = Color3.fromRGB(255, 50, 50); ind.BorderSizePixel = 0; ind.Parent = i; Instance.new("UICorner", ind).CornerRadius = UDim.new(0, 2); i.MouseButton1Click:Connect(cb); return i, ind end

    local function applyTheme() pcall(function() PanelStroke.Color = Settings.ThemeColor; Title.TextColor3 = Settings.ThemeColor; ScrollFrame.ScrollBarImageColor3 = Settings.ThemeColor; TitleGlowUI.Color = Settings.ThemeColor; if FOVCircleStroke then FOVCircleStroke.Color = Settings.ThemeColor end; if SilentFOVCircleStroke then SilentFOVCircleStroke.Color = Color3.fromRGB(255, 255, 255) end updateIndicators() end) end
    local function slider(lT, minV, maxV, sN) local c = Instance.new("Frame"); c.Size = UDim2.new(1, 0, 0, 35); c.BackgroundTransparency = 1; c.Parent = ScrollFrame; layoutOrder = layoutOrder + 1; c.LayoutOrder = layoutOrder; local l = Instance.new("TextLabel"); l.Size = UDim2.new(1, 0, 0, 16); l.BackgroundTransparency = 1; l.Font = Enum.Font.Gotham; l.TextSize = 11; l.TextColor3 = Color3.fromRGB(180, 180, 200); l.TextXAlignment = Enum.TextXAlignment.Left; l.Parent = c; local b = Instance.new("TextButton"); b.Size = UDim2.new(1, 0, 0, 14); b.Position = UDim2.fromOffset(0, 18); b.BackgroundColor3 = Color3.fromRGB(35, 35, 45); b.BorderSizePixel = 0; b.Text = ""; b.AutoButtonColor = false; b.Parent = c; local f = Instance.new("Frame"); f.BorderSizePixel = 0; f.BackgroundColor3 = Settings.ThemeColor; f.Parent = b; Instance.new("UICorner", b).CornerRadius = UDim.new(0, 4); Instance.new("UICorner", f).CornerRadius = UDim.new(0, 4); local function sv(v) v = math.clamp(v, minV, maxV); local r = math.floor(v * 100 + 0.5) / 100; local rt = (r - minV) / (maxV - minV); Settings[sN] = r; f.Size = UDim2.new(rt, 0, 1, 0); f.BackgroundColor3 = Settings.ThemeColor; l.Text = lT .. ": " .. tostring(r) end; local function upd() local x = UserInputService:GetMouseLocation().X; local w = b.AbsoluteSize.X; if w > 0 then sv(minV + (maxV - minV) * math.clamp((x - b.AbsolutePosition.X) / w, 0, 1)) end end; b.MouseButton1Down:Connect(function() DraggingSlider = upd; upd(); ScrollFrame.ScrollingEnabled = false end); sv(Settings[sN]) end

    MasterBtn, MasterInd = button("Master: OFF", function() Settings.Enabled = not Settings.Enabled; CurrentTarget = nil; updateIndicators() end)
    
    addCategory("Aimbot (Kamera Gerak)")
    AimBtn, AimInd = button("Aim: OFF", function() if Settings.AimStyle == "OFF" then Settings.AimStyle = "AIMBOT" elseif Settings.AimStyle == "AIMBOT" then Settings.AimStyle = "SMOOTH" else Settings.AimStyle = "OFF" end; CurrentTarget = nil; updateIndicators() end)
    AimModeBtn = button("Aim Mode: Hold Aim", function() if Settings.AimMode == "Hold Aim" then Settings.AimMode = "Auto" elseif Settings.AimMode = "Auto" then Settings.AimMode = "Scope" else Settings.AimMode = "Hold Aim" end; updateIndicators() end)
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
            for obj, val in pairs(originalTransparencies) do
                if obj and obj.Parent then
                    obj.Transparency = val
                    if obj:IsA("BasePart") then obj.LocalTransparencyModifier = 0 end
                end
            end
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
                    count = count + 1
                    if count % 500 == 0 then task.wait() end
                end
                for _, v in ipairs(Lighting:GetChildren()) do
                    if v:IsA("PostEffect") then v.Enabled = false end
                end
                local t = Workspace:FindFirstChildOfClass("Terrain")
                if t then t.WaterWaveSize = 0; t.WaterReflectance = 0 end
            end)
        else
            Lighting.GlobalShadows = true
        end
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
        
        if isForAim then
            if isBot and not Settings.AimBots then return false end
            if not isBot and not Settings.AimPlayers then return false end
        end
        
        if t then
            if t == LocalPlayer or isTeammate(t) then return false end 
            return true
        end
        local r = getRootPart(m) 
        local h = getHumanoid(m) 
        if not r or not h or h.Health <= 0 then return false end 
        return true 
    end
    
    local function getAllTargets()
        local c = {} local s = {}
        for _, p in ipairs(Players:GetPlayers()) do 
            if p.Character then
                local m = p.Character; if isValidTarget(m, true) and not s[m] then s[m] = true; table.insert(c, m) end 
            end 
        end
        for _, obj in ipairs(Workspace:GetChildren()) do 
            if obj:IsA("Model") and LocalPlayer.Character and not obj:IsDescendantOf(LocalPlayer.Character) then 
                if not s[obj] and isValidTarget(obj, true) then 
                    s[obj] = true; table.insert(c, obj) 
                end 
            end 
        end
        return c
    end

    local function canSee(part)
        if not Settings.WallCheck then return true end 
        local ign = {} if LocalPlayer.Character then table.insert(ign, LocalPlayer.Character) end 
        local par = RaycastParams.new(); par.FilterType = Enum.RaycastFilterType.Exclude; par.FilterDescendantsInstances = ign 
        local suc, res = pcall(function() return Workspace:Raycast(Camera.CFrame.Position, part.Position - Camera.CFrame.Position, par) end) 
        if not suc then return true end 
        return not res or res.Instance:IsDescendantOf(part.Parent) 
    end
    
    local function createEsp(model)
        local root = getRootPart(model)
        if not root then return nil end
        local box = Instance.new("Frame"); box.Name = "Qee_Box"; box.BackgroundTransparency = 1; box.BorderSizePixel = 0; box.Visible = false; box.ZIndex = 97; box.Parent = Gui
        local boxStroke = Instance.new("UIStroke", box); boxStroke.Thickness = 1.5; boxStroke.Color = Settings.ThemeColor; boxStroke.Transparency = 0
        local text = Instance.new("TextLabel"); text.Name = "Qee_Text"; text.BackgroundTransparency = 1; text.Size = UDim2.new(1, 0, 0, 14); text.Position = UDim2.new(0, 0, 1, 2); text.Font = Enum.Font.GothamBold; text.TextSize = 12; text.TextStrokeTransparency = 0.25; text.TextColor3 = Settings.ThemeColor; text.TextXAlignment = Enum.TextXAlignment.Center; text.Parent = box
        return { Box = box, BoxStroke = boxStroke, Text = text }
    end
    
    local function clearEsp(m) 
        local e = EspObjects[m] 
        if not e then return end 
        pcall(function() if e.Box then e.Box:Destroy() end end) 
        EspObjects[m] = nil 
    end
    
    local function updateEsp(npcs) 
        local alive = {} 
        for _, model in ipairs(npcs) do 
            alive[model] = true 
            local esp = EspObjects[model] or createEsp(model) 
            EspObjects[model] = esp 
            local root = getRootPart(model) 
            if esp and root then 
                local dist = math.floor((root.Position - Camera.CFrame.Position).Magnitude) 
                local isVis = Settings.Enabled and Settings.ESP
                local seen = canSee(root) 
                local col = seen and Settings.ThemeColor or Color3.fromRGB(255, 85, 85) 
                
                local charPos, charOnScreen = Camera:WorldToViewportPoint(root.Position)
                local head = model:FindFirstChild("Head")
                local headPos = Camera:WorldToViewportPoint((head and head.Position or root.Position) + Vector3.new(0, 0.5, 0))
                local legPos = Camera:WorldToViewportPoint(root.Position - Vector3.new(0, 3, 0))
                local isBehind = (headPos.Z < 0 and legPos.Z < 0)
                local onScreen = charOnScreen and not isBehind

                pcall(function() 
                    esp.Box.Visible = isVis and onScreen
                    esp.BoxStroke.Color = col
                    esp.Text.TextColor3 = col
                    if isVis and onScreen then
                        local distance = (root.Position - Camera.CFrame.Position).Magnitude
                        local width = math.clamp(2500 / distance, 4, 60)
                        local height = math.abs(legPos.Y - headPos.Y)
                        local topY = math.min(headPos.Y, legPos.Y)
                        local posX = charPos.X - width / 2
                        esp.Box.Position = UDim2.fromOffset(posX, topY)
                        esp.Box.Size = UDim2.fromOffset(width, height)
                        
                        local isBot = Players:GetPlayerFromCharacter(model) == nil
                        local displayName = isBot and "Bot" or model.Name
                        esp.Text.Text = displayName .. " [" .. tostring(dist) .. "]"
                    end
                end)
            end 
        end 
        for model in pairs(EspObjects) do if not alive[model] or not isValidTarget(model, false) then clearEsp(model) end end 
    end
    
    local function getClosestTarget(npcs, fovSize, targetMode)
        local bP = nil local bD = fovSize local mLoc = UserInputService:GetMouseLocation() local centerVp = Vector2.new(mLoc.X, mLoc.Y)
        for _, m in ipairs(npcs) do
            if isValidTarget(m, true) then
                local p = getRootPart(m, targetMode)
                if p then
                    local d3 = (p.Position - Camera.CFrame.Position).Magnitude
                    local suc, sp, on = pcall(function() return Camera:WorldToViewportPoint(p.Position) end)
                    if suc and on and sp.Z > 0 and d3 <= Settings.MaxRange and canSee(p) then
                        local d2 = (Vector2.new(sp.X, sp.Y) - centerVp).Magnitude
                        if d2 < bD then bD = d2; bP = p end
                    end
                end
            end
        end
        return bP
    end

    local function aimAt(part, dt) 
        local pred = getPredictedPosition(part, Settings.BulletSpeed)
        local desired = CFrame.lookAt(Camera.CFrame.Position, pred)
        pcall(function()
            if Settings.AimStyle == "AIMBOT" then
                Camera.CFrame = desired
            elseif Settings.AimStyle == "SMOOTH" then
                local alpha = math.clamp(Settings.Smoothness * dt * 60, 0, 1)
                Camera.CFrame = Camera.CFrame:Lerp(desired, alpha)
            end
        end)
    end

    local function updateWarning(npcs) 
        if not Settings.Enabled or not Settings.WarningEnabled then WarningFrame.Visible = false return end 
        local myChar = LocalPlayer.Character
        if not myChar or not myChar:FindFirstChild("HumanoidRootPart") then WarningFrame.Visible = false return end
        local myRoot = myChar.HumanoidRootPart
        local wDir = nil
        for _, model in ipairs(npcs) do
            if isValidTarget(model, false) then
                local tR = getRootPart(model)
                local tH = getHumanoid(model)
                if tR and tH and tH.Health > 0 then
                    local dirToMe = (myRoot.Position - tR.Position).Unit
                    local dot = tR.CFrame.LookVector:Dot(dirToMe)
                    if dot > 0.8 then
                        local offset = myRoot.CFrame:ToObjectSpace(tR.CFrame).Position
                        local angle = math.deg(math.atan2(offset.X, -offset.Z))
                        if angle > -45 and angle <= 45 then wDir = "FRONT"
                        elseif angle > 45 and angle <= 135 then wDir = "RIGHT"
                        elseif angle > 135 or angle <= -135 then wDir = "BACK"
                        else wDir = "LEFT" end
                        break
                    end
                end
            end
        end
        if wDir then WarningFrame.Visible = true; WarningText.Text = "⚠️ AIMED FROM: " .. wDir else WarningFrame.Visible = false end
    end

    local function teleportToClosestEnemy() 
        local myChar = LocalPlayer.Character
        if not myChar or not myChar:FindFirstChild("HumanoidRootPart") then return end 
        local targets = getAllTargets()
        local bestTargetChar = nil
        local minDist = math.huge
        if CurrentTarget and CurrentTarget.Parent then
            bestTargetChar = CurrentTarget.Parent
        else
            for _, m in ipairs(targets) do
                if isValidTarget(m, true) then
                    local root = getRootPart(m)
                    if root then
                        local dist = (root.Position - myChar.HumanoidRootPart.Position).Magnitude
                        if dist < minDist then minDist = dist; bestTargetChar = m end
                    end
                end
            end
        end
        if bestTargetChar and bestTargetChar:FindFirstChild("HumanoidRootPart") then
            myChar:PivotTo(bestTargetChar.HumanoidRootPart.CFrame * CFrame.new(0, 0, -3))
        end
    end

    UserInputService.InputChanged:Connect(function(i) if DraggingSlider and i.UserInputType == Enum.UserInputType.MouseMovement then DraggingSlider() end end)
    UserInputService.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then DraggingSlider = nil; ScrollFrame.ScrollingEnabled = true end end)
    UserInputService.InputBegan:Connect(function(i, gp)
        if gp then return end
        if i.KeyCode == Enum.KeyCode.RightShift then toggleMenu(not Settings.UIVisible)
        elseif i.KeyCode == Settings.TpKey then teleportToClosestEnemy()
        elseif i.KeyCode == Settings.FlyKey then Settings.FlyEnabled = not Settings.FlyEnabled; updateIndicators()
        elseif i.KeyCode == Enum.KeyCode.G then toggleGhost()
        end
    end)

    RunService.RenderStepped:Connect(function(dt)
        if Settings.IsRainbow then Settings.ThemeColor = Color3.fromHSV(tick() * 0.5 % 1, 0.8, 1) applyTheme() end
        if not Settings.Enabled then
            if CurrentTarget then CurrentTarget = nil end
            if SilentTarget then SilentTarget = nil end
            CachedSilentHit = nil
            CachedSilentTargetPart = nil
            WarningFrame.Visible = false
            for _, p in ipairs(CrosshairParts) do p.Visible = false end
            return
        end
        Camera = Workspace.CurrentCamera if not Camera then return end

        local mLoc = UserInputService:GetMouseLocation()
        FOVCircle.Position = UDim2.fromOffset(mLoc.X, mLoc.Y)
        FOVCircle.Size = UDim2.fromOffset(Settings.FOV * 2, Settings.FOV * 2); FOVCircle.Visible = Settings.ShowFOV

        SilentFOVCircle.Position = UDim2.fromOffset(mLoc.X, mLoc.Y)
        SilentFOVCircle.Size = UDim2.fromOffset(Settings.SilentFOV * 2, Settings.SilentFOV * 2); SilentFOVCircle.Visible = Settings.ShowSilentFOV

        if tick() - LastScanTime > 0.5 then
            CachedTargets = getAllTargets()
            LastScanTime = tick()
        end

        updateEsp(CachedTargets)
        if tick() % 0.2 < dt then updateWarning(CachedTargets) end

        if Settings.GhostHack and LocalPlayer.Character then
            for _, v in ipairs(LocalPlayer.Character:GetDescendants()) do
                if v:IsA("BasePart") and v.Name ~= "HumanoidRootPart" then
                    if originalTransparencies[v] == nil then originalTransparencies[v] = v.Transparency end
                    v.Transparency = 1
                    v.LocalTransparencyModifier = 0
                elseif v:IsA("Decal") or v:IsA("Texture") then
                    if originalTransparencies[v] == nil then originalTransparencies[v] = v.Transparency end
                    v.Transparency = 1
                end
            end
        end

        if Settings.FlyEnabled then
            local myChar = LocalPlayer.Character
            local hum = myChar and myChar:FindFirstChildOfClass("Humanoid")
            if myChar and myChar:FindFirstChild("HumanoidRootPart") and hum then
                local root = myChar.HumanoidRootPart
                local moveDir = Vector3.zero
                local cf = Camera.CFrame
                local forward = (cf.LookVector * Vector3.new(1,0,1)).Unit
                local right = (cf.RightVector * Vector3.new(1,0,1)).Unit
                if UserInputService:IsKeyDown(Enum.KeyCode.W) then moveDir = moveDir + forward end
                if UserInputService:IsKeyDown(Enum.KeyCode.S) then moveDir = moveDir - forward end
                if UserInputService:IsKeyDown(Enum.KeyCode.A) then moveDir = moveDir - right end
                if UserInputService:IsKeyDown(Enum.KeyCode.D) then moveDir = moveDir + right end
                if UserInputService:IsKeyDown(Enum.KeyCode.Space) then moveDir = moveDir + Vector3.new(0,1,0) end
                if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then moveDir = moveDir - Vector3.new(0,1,0) end
                if moveDir.Magnitude > 0 then moveDir = moveDir.Unit end
                root.AssemblyLinearVelocity = moveDir * Settings.FlySpeed
                hum.PlatformStand = true
            end
        else
            if LocalPlayer.Character then
                local hum = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
                if hum and hum.PlatformStand then hum.PlatformStand = false end
            end
        end

        if Settings.CustomCrosshair then
            local center = mLoc
            local gap = 5; local len = 8; local thick = 2
            CrosshairParts[1].Position = UDim2.fromOffset(center.X - gap - len, center.Y - thick/2); CrosshairParts[1].Size = UDim2.new(0, len, 0, thick)
            CrosshairParts[2].Position = UDim2.fromOffset(center.X + gap, center.Y - thick/2); CrosshairParts[2].Size = UDim2.new(0, len, 0, thick)
            CrosshairParts[3].Position = UDim2.fromOffset(center.X - thick/2, center.Y - gap - len); CrosshairParts[3].Size = UDim2.new(0, thick, 0, len)
            CrosshairParts[4].Position = UDim2.fromOffset(center.X - thick/2, center.Y + gap); CrosshairParts[4].Size = UDim2.new(0, thick, 0, len)
            for _, p in ipairs(CrosshairParts) do p.Visible = true; p.BackgroundColor3 = Settings.ThemeColor end
        else
            for _, p in ipairs(CrosshairParts) do p.Visible = false end
        end

        -- SILENT AIM HIT CACHE (Dihitung 1 frame sekali, bebas lag)
        if Settings.SilentAim then
            SilentTarget = getClosestTarget(CachedTargets, Settings.SilentFOV, Settings.SilentTarget)
            if SilentTarget then
                local predPos = getPredictedPosition(SilentTarget, Settings.BulletSpeed)
                CachedSilentHit = CFrame.new(predPos)
                CachedSilentTargetPart = SilentTarget
            else
                CachedSilentHit = nil
                CachedSilentTargetPart = nil
            end
        else
            SilentTarget = nil
            CachedSilentHit = nil
            CachedSilentTargetPart = nil
        end

        if Settings.AutoKill then
            CurrentTarget = getClosestTarget(CachedTargets, Settings.FOV, Settings.TargetMode)
            if CurrentTarget then
                local myChar = LocalPlayer.Character
                local targetRoot = CurrentTarget
                if myChar and myChar:FindFirstChild("HumanoidRootPart") and targetRoot then
                    local distToTarget = (myChar.HumanoidRootPart.Position - targetRoot.Position).Magnitude
                    if distToTarget > 5 then myChar:PivotTo(targetRoot.CFrame * CFrame.new(0, 0, 3)) end
                    myChar.HumanoidRootPart.CFrame = CFrame.lookAt(myChar.HumanoidRootPart.Position, targetRoot.Position)
                    local tool = myChar:FindFirstChildOfClass("Tool")
                    if tool then tool:Activate() end
                    if tick() - LastTriggerClick > 0.05 then
                        task.spawn(function() pcall(function() mouse1press() task.wait(0.01) mouse1release() end) end)
                        LastTriggerClick = tick()
                    end
                    Status.Text = "Status: KILLING " .. CurrentTarget.Parent.Name
                end
            else Status.Text = "Hotkeys: RShift=Menu, F=Fly, G=Ghost" end
        elseif Settings.AimStyle ~= "OFF" then
            CurrentTarget = getClosestTarget(CachedTargets, Settings.FOV, Settings.TargetMode)
            if CurrentTarget then
                Status.Text = "Status: " .. CurrentTarget.Parent.Name
                local isH = UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2)
                local isS = UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1)
                local sA = false
                if Settings.AWMMode then sA = isH else
                    if Settings.AimMode == "Auto" then sA = true elseif Settings.AimMode == "Scope" then sA = isH else sA = isH or isS end
                end
                if sA then aimAt(CurrentTarget, dt) end
                if Settings.TriggerBot and sA then
                    if tick() - LastTriggerClick > 0.1 then
                        task.spawn(function() pcall(function() mouse1press() task.wait(0.02) mouse1release() end) end)
                        LastTriggerClick = tick()
                    end
                end
            else Status.Text = "Hotkeys: RShift=Menu, F=Fly, G=Ghost" end
        else
            CurrentTarget = nil
            Status.Text = "Hotkeys: RShift=Menu, F=Fly, G=Ghost"
        end
    end)
end

local function checkPassword() 
    local input = PassBox.Text:gsub("^%s+", ""):gsub("%s+$", "")
    if input == PASSWORD then playSFX("rbxassetid://452267918"); InitializeHack()
    else playSFX("rbxassetid://131147405"); PassBox.Text = ""; PassBox.PlaceholderText = "Wrong Password!"; PassBox.PlaceholderColor3 = Color3.fromRGB(255, 50, 50) end
end
PassBtn.MouseButton1Click:Connect(checkPassword)
PassBox.FocusLost:Connect(function(enter) if enter then checkPassword() end end)

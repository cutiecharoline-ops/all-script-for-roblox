-- =========================================================================
-- QeeHacker Premium UI V12.1 (GUARANTEED VISIBLE FIX)
-- =========================================================================

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local CoreGui = game:GetService("CoreGui")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")
local MarketplaceService = game:GetService("MarketplaceService")
local Lighting = game:GetService("Lighting")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

-- [CONFIG & STATE]
local Settings = {
    Master = true,
    Aimbot = false,
    AimAssist = false,
    TargetPart = "HumanoidRootPart",
    AimBots = false,
    Triggerbot = false,
    TriggerbotDelay = 0.1,
    Spinbot = false,
    SpinSpeed = 50,
    Smoothness = 0.3,
    FOV = 100,
    ShowFOV = false,
    Fly = false,
    FlySpeed = 60,
    SpeedHack = false,
    WalkSpeed = 50,
    NoClip = false,
    TeamCheck = true,
    ESP = false,
    ESPChams = false,
    ESPBots = false,
    ESPBox = false,
    ESPLine = false,
    ESPSkeleton = false,
    WallCheck = false,
    IsRainbow = false,
    ThemeColor = Color3.fromRGB(0, 255, 102),
    UITitle = "QeeHacker Premium",
    UIScale = 1,
    UIOpacity = 0.95,  -- DEFAULT LEBIH TERANG!
    DisableParticles = false,
    DisableShadows = false,
    LowQualityESP = false,
    ReduceMotion = false,
    LimitFPS = false,
    MaxFPS = 60,
    DisableWater = false,
    DisablePostFX = false
}

local CurrentTarget = nil
local EspObjects = {}
local DraggingSlider = nil
local LastTriggerClick = 0
local StartTime = os.time()
local ToggleRefs = {} 

local fpsTable = {}
local currentFPS = 60
local minFPS = 999
local maxFPS = 0
local totalFPS = 0
local fpsCount = 0
local currentExecutor = (identifyexecutor and identifyexecutor()) or (getexecutorname and getexecutorname()) or "Unknown Exploit"

local uiParent = LocalPlayer:WaitForChild("PlayerGui")
pcall(function()
    if gethui then uiParent = gethui()
    elseif syn and syn.protect_gui then uiParent = CoreGui end
end)

local oldUI = uiParent:FindFirstChild("QeePremiumUI")
if oldUI then oldUI:Destroy() end

local Gui = Instance.new("ScreenGui")
Gui.Name = "QeePremiumUI"
Gui.ResetOnSpawn = false
Gui.IgnoreGuiInset = true
Gui.DisplayOrder = 99999
pcall(function() if syn and syn.protect_gui then syn.protect_gui(Gui) end end)
Gui.Parent = uiParent

-- ==========================================
-- ZINDEX SYSTEM - GUARANTEED VISIBLE
-- ==========================================
local Z = {
    Background = 1,
    Sidebar = 5,
    SidebarContent = 10,
    Page = 50,           -- PAGES PALING ATAS!
    PageContent = 55,    -- KONTEN DI DALAM PAGE LEBIH ATAS LAGI!
    PageUI = 60,         -- SLIDER THUMB DLL
    Header = 40,
    Notification = 100,
    Popup = 90,
    Intro = 999
}

local Theme = {
    Bg = Color3.fromRGB(14, 14, 18),
    Sec = Color3.fromRGB(30, 32, 42),      -- LEBIH TERANG!
    Hover = Color3.fromRGB(45, 48, 62),    -- LEBIH TERANG!
    Accent = Color3.fromRGB(0, 255, 102),
    Glow = Color3.fromRGB(0, 255, 136),
    Text = Color3.fromRGB(255, 255, 255),
    SubText = Color3.fromRGB(180, 185, 200), -- LEBIH TERANG!
    Danger = Color3.fromRGB(255, 64, 64)
}

local function SmoothTween(obj, time, properties)
    if Settings.ReduceMotion then
        for k, v in pairs(properties) do
            pcall(function() obj[k] = v end)
        end
        return nil
    end
    local info = TweenInfo.new(time, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
    local tween = TweenService:Create(obj, info, properties)
    tween:Play()
    return tween
end

-- ==========================================
-- INTRO ANIMATION
-- ==========================================
local IntroFrame = Instance.new("Frame", Gui)
IntroFrame.Size = UDim2.new(1, 0, 1, 0)
IntroFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
IntroFrame.BackgroundTransparency = 0
IntroFrame.ZIndex = Z.Intro
IntroFrame.Visible = true

local IntroText = Instance.new("TextLabel", IntroFrame)
IntroText.Size = UDim2.new(1, 0, 0, 60)
IntroText.Position = UDim2.new(0.5, 0, 1.5, 0) 
IntroText.AnchorPoint = Vector2.new(0.5, 0.5)
IntroText.BackgroundTransparency = 1
IntroText.Font = Enum.Font.GothamBlack
IntroText.TextSize = 50
IntroText.TextColor3 = Theme.Accent
IntroText.Text = "HELLO QEE USERS"
IntroText.ZIndex = Z.Intro

local IntroStroke = Instance.new("UIStroke", IntroText)
IntroStroke.Color = Color3.fromRGB(255, 255, 255)
IntroStroke.Thickness = 2
IntroStroke.Transparency = 1

task.delay(5, function()
    if IntroFrame and IntroFrame.Parent then
        IntroFrame:Destroy()
    end
end)

-- ==========================================
-- NOTIFICATION SYSTEM
-- ==========================================
local NotificationContainer = Instance.new("Frame", Gui)
NotificationContainer.Size = UDim2.new(0, 320, 1, 0)
NotificationContainer.Position = UDim2.new(1, -340, 0, 20)
NotificationContainer.BackgroundTransparency = 1
NotificationContainer.ZIndex = Z.Notification
local NotifLayout = Instance.new("UIListLayout", NotificationContainer)
NotifLayout.VerticalAlignment = Enum.VerticalAlignment.Top
NotifLayout.Padding = UDim.new(0, 10)

local function ShowNotification(title, text, duration)
    duration = duration or 3.5
    local NotifFrame = Instance.new("Frame", NotificationContainer)
    NotifFrame.Size = UDim2.new(1, 0, 0, 70)
    NotifFrame.BackgroundColor3 = Theme.Sec
    NotifFrame.BackgroundTransparency = 0.05
    NotifFrame.ClipsDescendants = true
    NotifFrame.AnchorPoint = Vector2.new(1, 0)
    NotifFrame.Position = UDim2.new(1, 0, 0, 0)
    NotifFrame.ZIndex = Z.Notification + 1
    Instance.new("UICorner", NotifFrame).CornerRadius = UDim.new(0, 8)
    
    local stroke = Instance.new("UIStroke", NotifFrame)
    stroke.Color = Theme.Accent
    stroke.Thickness = 1
    stroke.Transparency = 0.5
    
    local tLbl = Instance.new("TextLabel", NotifFrame)
    tLbl.Size = UDim2.new(1, -20, 0, 25)
    tLbl.Position = UDim2.new(0, 15, 0, 8)
    tLbl.Font = Enum.Font.GothamBold
    tLbl.TextSize = 14
    tLbl.TextColor3 = Theme.Accent
    tLbl.Text = title
    tLbl.TextXAlignment = Enum.TextXAlignment.Left
    tLbl.BackgroundTransparency = 1
    tLbl.ZIndex = Z.Notification + 2
    
    local dLbl = Instance.new("TextLabel", NotifFrame)
    dLbl.Size = UDim2.new(1, -30, 0, 25)
    dLbl.Position = UDim2.new(0, 15, 0, 32)
    dLbl.Font = Enum.Font.Gotham
    dLbl.TextSize = 12
    dLbl.TextColor3 = Theme.Text
    dLbl.Text = text
    dLbl.TextWrapped = true
    dLbl.TextXAlignment = Enum.TextXAlignment.Left
    dLbl.BackgroundTransparency = 1
    dLbl.ZIndex = Z.Notification + 2
    
    local ProgBar = Instance.new("Frame", NotifFrame)
    ProgBar.Size = UDim2.new(1, 0, 0, 3)
    ProgBar.Position = UDim2.new(0, 0, 1, -3)
    ProgBar.BackgroundColor3 = Theme.Accent
    ProgBar.BorderSizePixel = 0
    ProgBar.ZIndex = Z.Notification + 2
    
    NotifFrame.Size = UDim2.new(0, 0, 0, 70)
    SmoothTween(NotifFrame, 0.4, {Size = UDim2.new(1, 0, 0, 70), Position = UDim2.new(1, -320, 0, 0)})
    
    task.delay(duration, function()
        SmoothTween(NotifFrame, 0.3, {Size = UDim2.new(0, 0, 0, 70), BackgroundTransparency = 1})
        task.wait(0.3)
        NotifFrame:Destroy()
    end)
    
    SmoothTween(ProgBar, duration, {Size = UDim2.new(0, 0, 0, 3)})
end

-- ==========================================
-- FPS LIFETIME POPUP
-- ==========================================
local FPSPopup = Instance.new("Frame", Gui)
FPSPopup.Size = UDim2.new(0, 220, 0, 180)
FPSPopup.Position = UDim2.new(0, 15, 0.5, -90)
FPSPopup.BackgroundColor3 = Theme.Bg
FPSPopup.BackgroundTransparency = 0.05
FPSPopup.BorderSizePixel = 0
FPSPopup.Visible = false
FPSPopup.ZIndex = Z.Popup
Instance.new("UICorner", FPSPopup).CornerRadius = UDim.new(0, 10)
local FPSStroke = Instance.new("UIStroke", FPSPopup)
FPSStroke.Color = Theme.Accent
FPSStroke.Thickness = 1
FPSStroke.Transparency = 0.3

local FPSTitle = Instance.new("TextLabel", FPSPopup)
FPSTitle.Size = UDim2.new(1, 0, 0, 30)
FPSTitle.BackgroundColor3 = Theme.Sec
FPSTitle.BackgroundTransparency = 0.3
FPSTitle.Font = Enum.Font.GothamBold
FPSTitle.TextSize = 13
FPSTitle.TextColor3 = Theme.Accent
FPSTitle.Text = "📊 FPS LIFETIME STATS"
FPSTitle.ZIndex = Z.Popup + 1
Instance.new("UICorner", FPSTitle).CornerRadius = UDim.new(0, 10)

local FPSContent = Instance.new("TextLabel", FPSPopup)
FPSContent.Size = UDim2.new(1, -20, 0, 140)
FPSContent.Position = UDim2.new(0, 10, 0, 35)
FPSContent.BackgroundTransparency = 1
FPSContent.Font = Enum.Font.Code
FPSContent.TextSize = 11
FPSContent.TextColor3 = Theme.Text
FPSContent.TextXAlignment = Enum.TextXAlignment.Left
FPSContent.TextYAlignment = Enum.TextYAlignment.Top
FPSContent.ZIndex = Z.Popup + 1

local ShowFPSPopup = false

-- ==========================================
-- MAIN UI WINDOW - GUARANTEED VISIBLE
-- ==========================================
local MainUI = Instance.new("Frame", Gui)
MainUI.Size = UDim2.new(0, 820, 0, 520)
MainUI.Position = UDim2.new(0.5, 0, 0.5, 0)
MainUI.AnchorPoint = Vector2.new(0.5, 0.5)
MainUI.BackgroundColor3 = Theme.Bg
MainUI.BackgroundTransparency = 0.02  -- LEBIH OPAQUE!
MainUI.BorderSizePixel = 0
MainUI.Visible = false 
MainUI.ClipsDescendants = true 
MainUI.ZIndex = Z.Background
Instance.new("UICorner", MainUI).CornerRadius = UDim.new(0, 12)

local MainStroke = Instance.new("UIStroke", MainUI)
MainStroke.Color = Theme.Accent
MainStroke.Thickness = 2
MainStroke.Transparency = 0.1  -- BORDER LEBIH KELIHATAN

local MainUIScale = Instance.new("UIScale", MainUI)
MainUIScale.Scale = 0

local BgGradient = Instance.new("UIGradient", MainUI)
BgGradient.Color = ColorSequence.new(Color3.fromRGB(18, 18, 24), Color3.fromRGB(12, 12, 16))
BgGradient.Rotation = 90

-- Background particles - ZINDEX RENDAH!
for i = 1, 6 do
    local p = Instance.new("Frame", MainUI)
    p.Size = UDim2.new(0, math.random(50, 100), 0, math.random(50, 100))
    p.BackgroundColor3 = Theme.Accent
    p.BackgroundTransparency = 0.92
    p.Position = UDim2.new(math.random(), 0, math.random(), 0)
    p.ZIndex = Z.Background  -- Paling rendah!
    Instance.new("UICorner", p).CornerRadius = UDim.new(1, 0)
    task.spawn(function()
        while MainUI.Parent do
            if not Settings.DisableParticles then
                SmoothTween(p, math.random(5, 10), {Position = UDim2.new(math.random(), 0, math.random(), 0)})
            end
            task.wait(10)
        end
    end)
end

-- ==========================================
-- TOP BAR
-- ==========================================
local Header = Instance.new("Frame", MainUI)
Header.Size = UDim2.new(1, 0, 0, 55)
Header.BackgroundTransparency = 1
Header.ZIndex = Z.Header

local Logo = Instance.new("TextLabel", Header)
Logo.Size = UDim2.new(0, 30, 0, 30)
Logo.Position = UDim2.new(0, 20, 0.5, -15)
Logo.BackgroundTransparency = 1
Logo.Font = Enum.Font.GothamBlack
Logo.TextSize = 24
Logo.TextColor3 = Theme.Accent
Logo.Text = "Q"
Logo.ZIndex = Z.Header + 1

local HTitle = Instance.new("TextLabel", Header)
HTitle.Size = UDim2.new(0, 300, 0, 25)
HTitle.Position = UDim2.new(0, 55, 0, 10)
HTitle.BackgroundTransparency = 1
HTitle.Font = Enum.Font.GothamBold
HTitle.TextSize = 16
HTitle.TextColor3 = Theme.Text
HTitle.Text = Settings.UITitle
HTitle.TextXAlignment = Enum.TextXAlignment.Left
HTitle.ZIndex = Z.Header + 1

local HSub = Instance.new("TextLabel", Header)
HSub.Size = UDim2.new(0, 300, 0, 15)
HSub.Position = UDim2.new(0, 55, 0, 32)
HSub.BackgroundTransparency = 1
HSub.Font = Enum.Font.Gotham
HSub.TextSize = 10
HSub.TextColor3 = Theme.SubText
HSub.Text = "v1.2.1 | " .. currentExecutor
HSub.TextXAlignment = Enum.TextXAlignment.Left
HSub.ZIndex = Z.Header + 1

local LiveMetrics = Instance.new("TextLabel", Header)
LiveMetrics.Size = UDim2.new(0, 300, 1, 0)
LiveMetrics.Position = UDim2.new(1, -380, 0, 0)
LiveMetrics.BackgroundTransparency = 1
LiveMetrics.Font = Enum.Font.Code
LiveMetrics.TextSize = 12
LiveMetrics.TextColor3 = Theme.SubText
LiveMetrics.TextXAlignment = Enum.TextXAlignment.Right
LiveMetrics.Text = "FPS: 60 | PING: 0ms | CLOCK: 00:00:00"
LiveMetrics.ZIndex = Z.Header + 1

local CloseBtn = Instance.new("TextButton", Header)
CloseBtn.Size = UDim2.new(0, 32, 0, 32)
CloseBtn.Position = UDim2.new(1, -42, 0, 11)
CloseBtn.BackgroundColor3 = Theme.Danger
CloseBtn.BackgroundTransparency = 0.2
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.TextSize = 14
CloseBtn.TextColor3 = Theme.Text
CloseBtn.Text = "X"
CloseBtn.ZIndex = Z.Header + 2
Instance.new("UICorner", CloseBtn).CornerRadius = UDim.new(0, 8)

local MiniBtn = Instance.new("TextButton", Header)
MiniBtn.Size = UDim2.new(0, 32, 0, 32)
MiniBtn.Position = UDim2.new(1, -82, 0, 11)
MiniBtn.BackgroundColor3 = Theme.Hover
MiniBtn.Font = Enum.Font.GothamBold
MiniBtn.TextSize = 14
MiniBtn.TextColor3 = Theme.Text
MiniBtn.Text = "-"
MiniBtn.ZIndex = Z.Header + 2
Instance.new("UICorner", MiniBtn).CornerRadius = UDim.new(0, 8)

local function MakeDrag(dragHandle, dragTarget)
    local dragging, dragInput, dragStart, startPos
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
MakeDrag(Header, MainUI)

local isMinimized = false
MiniBtn.MouseButton1Click:Connect(function()
    isMinimized = not isMinimized
    if isMinimized then
        SmoothTween(MainUI, 0.4, {Size = UDim2.new(0, 820, 0, 55)})
        MiniBtn.Text = "+"
    else
        SmoothTween(MainUI, 0.4, {Size = UDim2.new(0, 820, 0, 520)})
        MiniBtn.Text = "-"
    end
end)
CloseBtn.MouseButton1Click:Connect(function()
    MainUI.Visible = false
    ShowNotification("Status", "UI Hidden. Press Right Shift to re-open.", 3)
end)

-- ==========================================
-- SIDEBAR - ZINDEX RENDAH DARI PAGE!
-- ==========================================
local Sidebar = Instance.new("Frame", MainUI)
Sidebar.Size = UDim2.new(0, 200, 1, -65)
Sidebar.Position = UDim2.new(0, 15, 0, 60)
Sidebar.BackgroundColor3 = Theme.Sec
Sidebar.BackgroundTransparency = 0.3  -- LEBIH TERANG!
Sidebar.ZIndex = Z.Sidebar  -- 5, dibawah Page (50)!
Instance.new("UICorner", Sidebar).CornerRadius = UDim.new(0, 10)

local SideLayout = Instance.new("UIListLayout", Sidebar)
SideLayout.Padding = UDim.new(0, 8)
SideLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
SideLayout.SortOrder = Enum.SortOrder.LayoutOrder

local SearchBox = Instance.new("TextBox", Sidebar)
SearchBox.Size = UDim2.new(0, 170, 0, 32)
SearchBox.BackgroundColor3 = Theme.Hover
SearchBox.Font = Enum.Font.Gotham
SearchBox.TextSize = 12
SearchBox.TextColor3 = Theme.Text
SearchBox.PlaceholderText = "🔍 Search..."
SearchBox.PlaceholderColor3 = Theme.SubText
SearchBox.Text = ""
SearchBox.ClearTextOnFocus = false
SearchBox.ZIndex = Z.SidebarContent
Instance.new("UICorner", SearchBox).CornerRadius = UDim.new(0, 8)
Instance.new("UIPadding", SearchBox).PaddingLeft = UDim.new(0, 10)

local Pages = {}
local TabButtons = {}

local function CreateTab(name)
    local Btn = Instance.new("TextButton")
    Btn.Size = UDim2.new(0, 170, 0, 36)
    Btn.BackgroundColor3 = Theme.Sec
    Btn.BackgroundTransparency = 1
    Btn.Text = "   " .. name
    Btn.Font = Enum.Font.GothamBold
    Btn.TextSize = 13
    Btn.TextColor3 = Theme.SubText
    Btn.TextXAlignment = Enum.TextXAlignment.Left
    Btn.Parent = Sidebar
    Btn.ZIndex = Z.SidebarContent
    Instance.new("UICorner", Btn).CornerRadius = UDim.new(0, 8)
    
    local Ind = Instance.new("Frame", Btn)
    Ind.Size = UDim2.new(0, 3, 0, 0)
    Ind.Position = UDim2.new(0, 0, 0.2, 0)
    Ind.BackgroundColor3 = Theme.Accent
    Ind.BorderSizePixel = 0
    Ind.ZIndex = Z.SidebarContent + 1
    Instance.new("UICorner", Ind).CornerRadius = UDim.new(0, 2)
    
    -- PAGE DENGAN ZINDEX TINGGI!
    local Page = Instance.new("ScrollingFrame")
    Page.Size = UDim2.new(1, -230, 1, -75)
    Page.Position = UDim2.new(0, 225, 0, 60)
    Page.BackgroundTransparency = 1
    Page.ScrollBarThickness = 4
    Page.ScrollBarImageColor3 = Theme.Accent
    Page.CanvasSize = UDim2.new(0, 0, 0, 0)
    Page.AutomaticCanvasSize = Enum.AutomaticSize.Y
    Page.Visible = false
    Page.ZIndex = Z.Page  -- 50! PASTI DI ATAS SIDEBAR!
    Page.Parent = MainUI
    
    local Layout = Instance.new("UIListLayout", Page)
    Layout.Padding = UDim.new(0, 10)
    Layout.SortOrder = Enum.SortOrder.LayoutOrder
    
    Btn.MouseEnter:Connect(function()
        if not Pages[name].Visible then
            SmoothTween(Btn, 0.2, {BackgroundTransparency = 0.7, TextColor3 = Theme.Text})
        end
    end)
    Btn.MouseLeave:Connect(function()
        if not Pages[name].Visible then
            SmoothTween(Btn, 0.2, {BackgroundTransparency = 1, TextColor3 = Theme.SubText})
        end
    end)

    Btn.MouseButton1Click:Connect(function()
        for _, p in pairs(Pages) do p.Visible = false end
        for _, b in pairs(TabButtons) do 
            SmoothTween(b, 0.2, {BackgroundTransparency = 1, TextColor3 = Theme.SubText})
            local ind = b:FindFirstChild("Frame")
            if ind then SmoothTween(ind, 0.2, {Size = UDim2.new(0, 3, 0, 0)}) end
        end
        Page.Visible = true
        SmoothTween(Btn, 0.2, {BackgroundTransparency = 0.5, TextColor3 = Theme.Text})
        SmoothTween(Ind, 0.2, {Size = UDim2.new(0, 3, 0.6, 0)})
    end)
    
    Pages[name] = Page
    TabButtons[name] = Btn
    return Page
end

local DashboardPage = CreateTab("Dashboard")
local CombatPage = CreateTab("Combat")
local MovementPage = CreateTab("Movement")
local VisualsPage = CreateTab("Visuals")
local OptimizePage = CreateTab("Optimize")
local SettingsPage = CreateTab("Settings")
local ConfigPage = CreateTab("Config")
local AboutPage = CreateTab("About")

Pages["Dashboard"].Visible = true
TabButtons["Dashboard"].BackgroundTransparency = 0.5
TabButtons["Dashboard"].TextColor3 = Theme.Text
local dashInd = TabButtons["Dashboard"]:FindFirstChild("Frame")
if dashInd then dashInd.Size = UDim2.new(0, 3, 0.6, 0) end

-- ==========================================
-- UI BUILDERS - ZINDEX PALING TINGGI!
-- ==========================================
local function CreateSlider(text, page, settingName, minV, maxV)
    local Frame = Instance.new("Frame", page)
    Frame.Size = UDim2.new(1, -10, 0, 45)
    Frame.BackgroundColor3 = Theme.Sec
    Frame.BackgroundTransparency = 0.15  -- LEBIH TERANG!
    Frame.ZIndex = Z.PageContent
    Instance.new("UICorner", Frame).CornerRadius = UDim.new(0, 8)
    
    local Label = Instance.new("TextLabel", Frame)
    Label.Size = UDim2.new(0, 200, 0, 20)
    Label.Position = UDim2.new(0, 15, 0, 5)
    Label.BackgroundTransparency = 1
    Label.Font = Enum.Font.GothamBold
    Label.TextSize = 12
    Label.TextColor3 = Theme.Text
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.Text = text .. ": " .. tostring(Settings[settingName])
    Label.ZIndex = Z.PageContent + 1
    
    local ValLbl = Instance.new("TextLabel", Frame)
    ValLbl.Size = UDim2.new(0, 50, 0, 20)
    ValLbl.Position = UDim2.new(1, -65, 0, 5)
    ValLbl.BackgroundTransparency = 1
    ValLbl.Font = Enum.Font.GothamBold
    ValLbl.TextSize = 12
    ValLbl.TextColor3 = Theme.Accent
    ValLbl.TextXAlignment = Enum.TextXAlignment.Right
    ValLbl.Text = tostring(Settings[settingName])
    ValLbl.ZIndex = Z.PageContent + 1
    
    local Bar = Instance.new("TextButton", Frame)
    Bar.Size = UDim2.new(1, -30, 0, 6)
    Bar.Position = UDim2.new(0, 15, 0, 32)
    Bar.BackgroundColor3 = Theme.Hover
    Bar.Text = ""
    Bar.AutoButtonColor = false
    Bar.ZIndex = Z.PageContent + 2
    Instance.new("UICorner", Bar).CornerRadius = UDim.new(0, 3)
    
    local Fill = Instance.new("Frame", Bar)
    Fill.Size = UDim2.new((Settings[settingName] - minV) / (maxV - minV), 0, 1, 0)
    Fill.BackgroundColor3 = Theme.Accent
    Fill.BorderSizePixel = 0
    Fill.ZIndex = Z.PageContent + 3
    Instance.new("UICorner", Fill).CornerRadius = UDim.new(0, 3)
    
    local Thumb = Instance.new("Frame", Bar)
    Thumb.Size = UDim2.new(0, 14, 0, 14)  -- LEBIH BESAR!
    Thumb.Position = UDim2.new((Settings[settingName] - minV) / (maxV - minV), -7, 0.5, -7)
    Thumb.BackgroundColor3 = Theme.Text
    Thumb.BorderSizePixel = 0
    Thumb.ZIndex = Z.PageUI  -- PALING TINGGI!
    Instance.new("UICorner", Thumb).CornerRadius = UDim.new(1, 0)
    
    local function update(input)
        local pos = input.Position.X - Bar.AbsolutePosition.X
        local percent = math.clamp(pos / Bar.AbsoluteSize.X, 0, 1)
        local value = math.floor((minV + (maxV - minV) * percent) * 100) / 100
        Settings[settingName] = value
        Fill.Size = UDim2.new(percent, 0, 1, 0)
        Thumb.Position = UDim2.new(percent, -7, 0.5, -7)
        Label.Text = text .. ": " .. tostring(value)
        ValLbl.Text = tostring(value)
    end
    Bar.MouseButton1Down:Connect(function() DraggingSlider = update end)
end

local function CreateToggle(text, page, settingName)
    local Btn = Instance.new("TextButton", page)
    Btn.Size = UDim2.new(1, -10, 0, 38)
    Btn.BackgroundColor3 = Theme.Sec
    Btn.BackgroundTransparency = 0.15  -- LEBIH TERANG!
    Btn.Text = ""
    Btn.AutoButtonColor = false
    Btn.ZIndex = Z.PageContent
    Instance.new("UICorner", Btn).CornerRadius = UDim.new(0, 8)
    
    local Label = Instance.new("TextLabel", Btn)
    Label.Size = UDim2.new(1, -80, 1, 0)
    Label.Position = UDim2.new(0, 15, 0, 0)
    Label.BackgroundTransparency = 1
    Label.Font = Enum.Font.GothamBold
    Label.TextSize = 12
    Label.TextColor3 = Theme.SubText
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.Text = text
    Label.ZIndex = Z.PageContent + 1
    
    local SwitchBg = Instance.new("Frame", Btn)
    SwitchBg.Size = UDim2.new(0, 42, 0, 22)  -- LEBIH BESAR!
    SwitchBg.Position = UDim2.new(1, -57, 0.5, -11)
    SwitchBg.BackgroundColor3 = Theme.Hover
    SwitchBg.ZIndex = Z.PageContent + 2
    Instance.new("UICorner", SwitchBg).CornerRadius = UDim.new(1, 0)
    
    local Knob = Instance.new("Frame", SwitchBg)
    Knob.Size = UDim2.new(0, 18, 0, 18)
    Knob.Position = UDim2.new(0, 2, 0.5, -9)
    Knob.BackgroundColor3 = Theme.Text
    Knob.BorderSizePixel = 0
    Knob.ZIndex = Z.PageUI  -- PALING TINGGI!
    Instance.new("UICorner", Knob).CornerRadius = UDim.new(1, 0)
    
    local function setVisuals()
        local state = Settings[settingName]
        SmoothTween(Knob, 0.25, {Position = state and UDim2.new(1, -20, 0.5, -9) or UDim2.new(0, 2, 0.5, -9)})
        SmoothTween(SwitchBg, 0.25, {BackgroundColor3 = state and Theme.Accent or Theme.Hover})
        SmoothTween(Label, 0.25, {TextColor3 = state and Theme.Text or Theme.SubText})
    end
    
    Btn.MouseButton1Click:Connect(function()
        Settings[settingName] = not Settings[settingName]
        setVisuals()
        ShowNotification("Toggle", text .. ": " .. (Settings[settingName] and "ON" or "OFF"), 2)
    end)
    setVisuals()
    
    table.insert(ToggleRefs, {Btn = Btn, SwitchBg = SwitchBg, Knob = Knob, Label = Label, Text = text, SettingName = settingName})
end

local function CreateButton(text, page, callback)
    local Btn = Instance.new("TextButton", page)
    Btn.Size = UDim2.new(1, -10, 0, 38)
    Btn.BackgroundColor3 = Theme.Hover
    Btn.BackgroundTransparency = 0.4  -- LEBIH TERANG!
    Btn.Text = text
    Btn.Font = Enum.Font.GothamBold
    Btn.TextSize = 12
    Btn.TextColor3 = Theme.Text
    Btn.ZIndex = Z.PageContent
    Instance.new("UICorner", Btn).CornerRadius = UDim.new(0, 8)
    
    Btn.MouseEnter:Connect(function() SmoothTween(Btn, 0.2, {BackgroundTransparency = 0.1, TextColor3 = Theme.Accent}) end)
    Btn.MouseLeave:Connect(function() SmoothTween(Btn, 0.2, {BackgroundTransparency = 0.4, TextColor3 = Theme.Text}) end)
    
    Btn.MouseButton1Click:Connect(function() pcall(callback) end)
end

-- ==========================================
-- POPULATING TABS
-- ==========================================

-- DASHBOARD
DashboardPage:FindFirstChildOfClass("UIListLayout"):Destroy()
local DbLeft = Instance.new("Frame", DashboardPage)
DbLeft.Size = UDim2.new(0, 280, 1, 0)
DbLeft.BackgroundTransparency = 1
DbLeft.ZIndex = Z.PageContent
local DbLeftLayout = Instance.new("UIListLayout", DbLeft)
DbLeftLayout.Padding = UDim.new(0, 15)

local ProfileCard = Instance.new("Frame", DbLeft)
ProfileCard.Size = UDim2.new(1, 0, 0, 160)
ProfileCard.BackgroundColor3 = Theme.Sec
ProfileCard.BackgroundTransparency = 0.15
ProfileCard.ZIndex = Z.PageContent
Instance.new("UICorner", ProfileCard).CornerRadius = UDim.new(0, 10)
Instance.new("UIStroke", ProfileCard).Color = Theme.Hover

local AvatarImage = Instance.new("ImageLabel", ProfileCard)
AvatarImage.Size = UDim2.new(0, 65, 0, 65)
AvatarImage.Position = UDim2.new(0, 15, 0, 15)
AvatarImage.BackgroundColor3 = Theme.Hover
AvatarImage.Image = "rbxthumb://type=AvatarHeadShot&id=" .. LocalPlayer.UserId .. "&w=150&h=150"
AvatarImage.ZIndex = Z.PageContent + 1
Instance.new("UICorner", AvatarImage).CornerRadius = UDim.new(1, 0)
Instance.new("UIStroke", AvatarImage).Color = Theme.Accent

local DNameLabel = Instance.new("TextLabel", ProfileCard)
DNameLabel.Size = UDim2.new(1, -100, 0, 22)
DNameLabel.Position = UDim2.new(0, 95, 0, 18)
DNameLabel.Font = Enum.Font.GothamBlack
DNameLabel.TextSize = 16
DNameLabel.TextColor3 = Theme.Text
DNameLabel.Text = LocalPlayer.DisplayName
DNameLabel.TextXAlignment = Enum.TextXAlignment.Left
DNameLabel.BackgroundTransparency = 1
DNameLabel.ZIndex = Z.PageContent + 1

local UNameLabel = Instance.new("TextLabel", ProfileCard)
UNameLabel.Size = UDim2.new(1, -100, 0, 18)
UNameLabel.Position = UDim2.new(0, 95, 0, 38)
UNameLabel.Font = Enum.Font.Gotham
UNameLabel.TextSize = 12
UNameLabel.TextColor3 = Theme.SubText
UNameLabel.Text = "@" .. LocalPlayer.Name
UNameLabel.TextXAlignment = Enum.TextXAlignment.Left
UNameLabel.BackgroundTransparency = 1
UNameLabel.ZIndex = Z.PageContent + 1

local ProfileInfo = Instance.new("TextLabel", ProfileCard)
ProfileInfo.Size = UDim2.new(1, -30, 0, 80)
ProfileInfo.Position = UDim2.new(0, 15, 0, 90)
ProfileInfo.Font = Enum.Font.Code
ProfileInfo.TextSize = 11
ProfileInfo.TextColor3 = Theme.SubText
ProfileInfo.TextXAlignment = Enum.TextXAlignment.Left
ProfileInfo.BackgroundTransparency = 1
ProfileInfo.TextWrapped = true
ProfileInfo.ZIndex = Z.PageContent + 1

local placeName = "Unknown Server"
pcall(function() placeName = MarketplaceService:GetProductInfo(game.PlaceId).Name end)
ProfileInfo.Text = string.format("USER ID: %d\nEXEC: %s\nGAME: %s\nJOINED: %s", LocalPlayer.UserId, currentExecutor, placeName, os.date("%X"))

local DbRight = Instance.new("Frame", DashboardPage)
DbRight.Size = UDim2.new(0, 280, 1, 0)
DbRight.Position = UDim2.new(0, 300, 0, 0)
DbRight.BackgroundTransparency = 1
DbRight.ZIndex = Z.PageContent
local DbRightLayout = Instance.new("UIListLayout", DbRight)
DbRightLayout.Padding = UDim.new(0, 15)

local StatsCard = Instance.new("Frame", DbRight)
StatsCard.Size = UDim2.new(1, 0, 0, 160)
StatsCard.BackgroundColor3 = Theme.Sec
StatsCard.BackgroundTransparency = 0.15
StatsCard.ZIndex = Z.PageContent
Instance.new("UICorner", StatsCard).CornerRadius = UDim.new(0, 10)
Instance.new("UIStroke", StatsCard).Color = Theme.Hover

local StatsTitle = Instance.new("TextLabel", StatsCard)
StatsTitle.Size = UDim2.new(1, -20, 0, 30)
StatsTitle.Position = UDim2.new(0, 15, 0, 10)
StatsTitle.Font = Enum.Font.GothamBold
StatsTitle.TextSize = 14
StatsTitle.TextColor3 = Theme.Accent
StatsTitle.Text = "📊 LIVE STATISTICS"
StatsTitle.TextXAlignment = Enum.TextXAlignment.Left
StatsTitle.BackgroundTransparency = 1
StatsTitle.ZIndex = Z.PageContent + 1

local StatsContent = Instance.new("TextLabel", StatsCard)
StatsContent.Size = UDim2.new(1, -30, 0, 110)
StatsContent.Position = UDim2.new(0, 15, 0, 40)
StatsContent.Font = Enum.Font.GothamMedium
StatsContent.TextSize = 13
StatsContent.TextColor3 = Theme.Text
StatsContent.TextXAlignment = Enum.TextXAlignment.Left
StatsContent.BackgroundTransparency = 1
StatsContent.ZIndex = Z.PageContent + 1

task.spawn(function()
    while MainUI.Parent do
        local duration = os.time() - StartTime
        local minutes = math.floor(duration / 60)
        local seconds = duration % 60
        local lead = LocalPlayer:FindFirstChild("leaderstats")
        local moneyStr = "N/A"
        local killsStr = "N/A"
        if lead then
            local cash = lead:FindFirstChild("Cash") or lead:FindFirstChild("Coins") or lead:FindFirstChild("Money")
            local kills = lead:FindFirstChild("Kills") or lead:FindFirstChild("Kills Counter")
            if cash then moneyStr = tostring(cash.Value) end
            if kills then killsStr = tostring(kills.Value) end
        end
        StatsContent.Text = string.format("Session Time :  %02dm %02ds\n\nWallet/Cash  :  %s\n\nConfirmed Kills:  %s", minutes, seconds, moneyStr, killsStr)
        task.wait(1)
    end
end)

-- COMBAT
CreateToggle("Master Activation", CombatPage, "Master")
CreateToggle("Aimbot (Instant Lock)", CombatPage, "Aimbot")
CreateToggle("Aim Assist (Magnet)", CombatPage, "AimAssist")
CreateToggle("Triggerbot Active", CombatPage, "Triggerbot")
CreateToggle("Spinbot Matrix", CombatPage, "Spinbot")
CreateToggle("Aim at Bots/NPC", CombatPage, "AimBots")

local TargetPartBtn = Instance.new("TextButton", CombatPage)
TargetPartBtn.Size = UDim2.new(1, -10, 0, 38)
TargetPartBtn.BackgroundColor3 = Theme.Sec
TargetPartBtn.BackgroundTransparency = 0.15
TargetPartBtn.Font = Enum.Font.GothamBold
TargetPartBtn.TextSize = 12
TargetPartBtn.TextColor3 = Theme.Accent
TargetPartBtn.TextXAlignment = Enum.TextXAlignment.Left
TargetPartBtn.Text = "      Target Part: Body"
TargetPartBtn.AutoButtonColor = false
TargetPartBtn.ZIndex = Z.PageContent
Instance.new("UICorner", TargetPartBtn).CornerRadius = UDim.new(0, 8)
local padTP = Instance.new("UIPadding", TargetPartBtn)
padTP.PaddingLeft = UDim.new(0, 15)
local function updateTargetPartVisual()
    local p = Settings.TargetPart
    local display = "Pelvis (Root)"
    if p == "Head" then display = "Head" elseif p == "Torso" then display = "Body" end
    TargetPartBtn.Text = "      Target Part: " .. display
end
TargetPartBtn.MouseButton1Click:Connect(function()
    if Settings.TargetPart == "HumanoidRootPart" then Settings.TargetPart = "Head"
    elseif Settings.TargetPart == "Head" then Settings.TargetPart = "Torso"
    else Settings.TargetPart = "HumanoidRootPart" end
    updateTargetPartVisual()
end)
updateTargetPartVisual()

CreateButton("Teleport to Closest [T]", CombatPage, function()
    if CurrentTarget and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        LocalPlayer.Character.HumanoidRootPart.CFrame = CurrentTarget.CFrame * CFrame.new(0, 0, 3)
        ShowNotification("Teleport", "Teleported to target.", 2)
    end
end)
CreateSlider("Smoothness", CombatPage, "Smoothness", 0.05, 1)
CreateSlider("FOV Size", CombatPage, "FOV", 20, 600)
CreateToggle("Show FOV Radius", CombatPage, "ShowFOV")

-- MOVEMENT
CreateToggle("Fly System [F]", MovementPage, "Fly")
CreateSlider("Flight Speed", MovementPage, "FlySpeed", 10, 300)
CreateToggle("Speed Engine [V]", MovementPage, "SpeedHack")
CreateSlider("Velocity Speed", MovementPage, "WalkSpeed", 16, 250)
CreateToggle("NoClip [N] - Walk Through Walls", MovementPage, "NoClip")

-- VISUALS
CreateToggle("Active ESP Masters", VisualsPage, "ESP")
CreateToggle("Render Chams (Highlight)", VisualsPage, "ESPChams")
CreateToggle("Render ESP 2D Box", VisualsPage, "ESPBox")
CreateToggle("Render Snap Lines", VisualsPage, "ESPLine")
CreateToggle("Render Bone Skeleton", VisualsPage, "ESPSkeleton")
CreateToggle("Track Target Bots/NPC", VisualsPage, "ESPBots")
CreateToggle("Team Discrimination Check", VisualsPage, "TeamCheck")
CreateToggle("Occlusion Wall Check", VisualsPage, "WallCheck")
CreateToggle("Dynamic Rainbow Chroma", VisualsPage, "IsRainbow")

-- OPTIMIZE
local OptimizeTitle = Instance.new("TextLabel", OptimizePage)
OptimizeTitle.Size = UDim2.new(1, -10, 0, 30)
OptimizeTitle.BackgroundColor3 = Theme.Sec
OptimizeTitle.BackgroundTransparency = 0.3
OptimizeTitle.Font = Enum.Font.GothamBold
OptimizeTitle.TextSize = 14
OptimizeTitle.TextColor3 = Theme.Accent
OptimizeTitle.Text = "⚡ PERFORMANCE OPTIMIZATION"
OptimizeTitle.TextXAlignment = Enum.TextXAlignment.Left
OptimizeTitle.ZIndex = Z.PageContent
Instance.new("UICorner", OptimizeTitle).CornerRadius = UDim.new(0, 8)
Instance.new("UIPadding", OptimizeTitle).PaddingLeft = UDim.new(0, 15)

CreateToggle("Disable UI Particles", OptimizePage, "DisableParticles")
CreateToggle("Disable Game Shadows", OptimizePage, "DisableShadows")
CreateToggle("Low Quality ESP Mode", OptimizePage, "LowQualityESP")
CreateToggle("Reduce UI Animations", OptimizePage, "ReduceMotion")
CreateToggle("Disable Water Effects", OptimizePage, "DisableWater")
CreateToggle("Disable Post-Processing", OptimizePage, "DisablePostFX")
CreateToggle("Enable FPS Limiter", OptimizePage, "LimitFPS")
CreateSlider("Max FPS Limit", OptimizePage, "MaxFPS", 30, 144)

CreateButton("Apply Optimal Settings (Low-End PC)", OptimizePage, function()
    Settings.DisableParticles = true
    Settings.DisableShadows = true
    Settings.LowQualityESP = true
    Settings.ReduceMotion = true
    Settings.DisableWater = true
    Settings.DisablePostFX = true
    Settings.LimitFPS = true
    Settings.MaxFPS = 60
    UpdateTheme()
    ShowNotification("Optimize", "Optimal low-end settings applied!", 3)
end)

CreateButton("Apply Balanced Settings", OptimizePage, function()
    Settings.DisableParticles = false
    Settings.DisableShadows = true
    Settings.LowQualityESP = false
    Settings.ReduceMotion = false
    Settings.DisableWater = false
    Settings.DisablePostFX = true
    Settings.LimitFPS = false
    UpdateTheme()
    ShowNotification("Optimize", "Balanced settings applied!", 3)
end)

CreateButton("Reset to Default", OptimizePage, function()
    Settings.DisableParticles = false
    Settings.DisableShadows = false
    Settings.LowQualityESP = false
    Settings.ReduceMotion = false
    Settings.DisableWater = false
    Settings.DisablePostFX = false
    Settings.LimitFPS = false
    UpdateTheme()
    ShowNotification("Optimize", "Settings reset to default!", 3)
end)

-- SETTINGS (WITH OPACITY!)
local OpacityTitle = Instance.new("TextLabel", SettingsPage)
OpacityTitle.Size = UDim2.new(1, -10, 0, 30)
OpacityTitle.BackgroundColor3 = Theme.Sec
OpacityTitle.BackgroundTransparency = 0.3
OpacityTitle.Font = Enum.Font.GothamBold
OpacityTitle.TextSize = 14
OpacityTitle.TextColor3 = Theme.Accent
OpacityTitle.Text = "🎨 THEME & UI SETTINGS"
OpacityTitle.TextXAlignment = Enum.TextXAlignment.Left
OpacityTitle.ZIndex = Z.PageContent
Instance.new("UICorner", OpacityTitle).CornerRadius = UDim.new(0, 8)
Instance.new("UIPadding", OpacityTitle).PaddingLeft = UDim.new(0, 15)

CreateSlider("UI Opacity (Brightness)", SettingsPage, "UIOpacity", 0.2, 1)
CreateButton("Set Neon Green Color", SettingsPage, function() Settings.IsRainbow = false; Settings.ThemeColor = Color3.fromRGB(0, 255, 102) UpdateTheme() end)
CreateButton("Set Crimson Red Color", SettingsPage, function() Settings.IsRainbow = false; Settings.ThemeColor = Color3.fromRGB(255, 64, 64) UpdateTheme() end)
CreateButton("Set Electric Blue Color", SettingsPage, function() Settings.IsRainbow = false; Settings.ThemeColor = Color3.fromRGB(80, 150, 255) UpdateTheme() end)
CreateButton("Set Purple Haze Color", SettingsPage, function() Settings.IsRainbow = false; Settings.ThemeColor = Color3.fromRGB(180, 80, 255) UpdateTheme() end)
CreateButton("Set Hot Pink Color", SettingsPage, function() Settings.IsRainbow = false; Settings.ThemeColor = Color3.fromRGB(255, 80, 180) UpdateTheme() end)
CreateButton("Set Gold Color", SettingsPage, function() Settings.IsRainbow = false; Settings.ThemeColor = Color3.fromRGB(255, 200, 50) UpdateTheme() end)
CreateToggle("Dynamic Rainbow Chroma", SettingsPage, "IsRainbow")
CreateButton("Toggle FPS Lifetime Popup [H]", SettingsPage, function()
    ShowFPSPopup = not ShowFPSPopup
    FPSPopup.Visible = ShowFPSPopup
    ShowNotification("FPS Popup", "Lifetime: " .. (ShowFPSPopup and "ON" or "OFF"), 2)
end)

-- CONFIG
local ConfigNameBox = Instance.new("TextBox", ConfigPage)
ConfigNameBox.Size = UDim2.new(1, -10, 0, 38)
ConfigNameBox.BackgroundColor3 = Theme.Sec
ConfigNameBox.BackgroundTransparency = 0.15
ConfigNameBox.Font = Enum.Font.Gotham
ConfigNameBox.TextSize = 12
ConfigNameBox.TextColor3 = Theme.Text
ConfigNameBox.PlaceholderText = "Enter Config Name..."
ConfigNameBox.PlaceholderColor3 = Theme.SubText
ConfigNameBox.TextXAlignment = Enum.TextXAlignment.Left
ConfigNameBox.ZIndex = Z.PageContent
Instance.new("UICorner", ConfigNameBox).CornerRadius = UDim.new(0, 8)
Instance.new("UIPadding", ConfigNameBox).PaddingLeft = UDim.new(0, 15)

CreateButton("Save Configuration File", ConfigPage, function()
    if writefile then
        local targetFile = (ConfigNameBox.Text ~= "" and ConfigNameBox.Text or "premium_default") .. ".qee"
        local output = {}
        for k, v in pairs(Settings) do
            if type(v) ~= "table" and type(v) ~= "userdata" then output[k] = v end
        end
        writefile(targetFile, HttpService:JSONEncode(output))
        ShowNotification("Success", "Config saved!", 3)
    end
end)

CreateButton("Load Configuration File", ConfigPage, function()
    if readfile and isfile then
        local targetFile = (ConfigNameBox.Text ~= "" and ConfigNameBox.Text or "premium_default") .. ".qee"
        if isfile(targetFile) then
            local decoded = HttpService:JSONDecode(readfile(targetFile))
            for k, v in pairs(decoded) do Settings[k] = v end
            UpdateTheme()
            ShowNotification("Success", "Config loaded!", 3)
        end
    end
end)

-- ABOUT
local AboutCard = Instance.new("Frame", AboutPage)
AboutCard.Size = UDim2.new(1, -10, 0, 200)
AboutCard.BackgroundColor3 = Theme.Sec
AboutCard.BackgroundTransparency = 0.15
AboutCard.ZIndex = Z.PageContent
Instance.new("UICorner", AboutCard).CornerRadius = UDim.new(0, 10)

local AboutTitle = Instance.new("TextLabel", AboutCard)
AboutTitle.Size = UDim2.new(1, 0, 0, 40)
AboutTitle.Position = UDim2.new(0, 0, 0, 10)
AboutTitle.BackgroundTransparency = 1
AboutTitle.Font = Enum.Font.GothamBlack
AboutTitle.TextSize = 24
AboutTitle.TextColor3 = Theme.Accent
AboutTitle.Text = "QeeHacker Premium"
AboutTitle.ZIndex = Z.PageContent + 1

local AboutText = Instance.new("TextLabel", AboutCard)
AboutText.Size = UDim2.new(1, -30, 0, 100)
AboutText.Position = UDim2.new(0, 15, 0, 60)
AboutText.BackgroundTransparency = 1
AboutText.Font = Enum.Font.Gotham
AboutText.TextSize = 12
AboutText.TextColor3 = Theme.SubText
AboutText.TextWrapped = true
AboutText.Text = "Version: v1.2.1\nBuild: 2024\nDeveloper: Qee\n\n+ NoClip | Optimize | FPS Popup | Opacity\n+ GUARANTEED VISIBLE FIX"
AboutText.TextXAlignment = Enum.TextXAlignment.Left
AboutText.TextYAlignment = Enum.TextYAlignment.Top
AboutText.ZIndex = Z.PageContent + 1

-- Search
SearchBox:GetPropertyChangedSignal("Text"):Connect(function()
    local q = SearchBox.Text:lower()
    for name, page in pairs(Pages) do
        for _, obj in ipairs(page:GetChildren()) do
            if obj:IsA("TextButton") or obj:IsA("Frame") then
                local label = obj:FindFirstChildOfClass("TextLabel")
                local searchableText = obj:IsA("TextButton") and obj.Text or (label and label.Text or "")
                obj.Visible = q == "" or searchableText:lower():find(q)
            end
        end
    end
end)

-- ==========================================
-- OPACITY FUNCTION
-- ==========================================
local function UpdateOpacity()
    local opacity = Settings.UIOpacity
    local bgTransparency = math.clamp(1 - opacity, 0, 0.8)
    MainUI.BackgroundTransparency = bgTransparency
    Sidebar.BackgroundTransparency = 0.3 + (1 - opacity) * 0.5
end

-- ==========================================
-- GAME LOGIC
-- ==========================================
local function getRootPart(m)
    if not m then return nil end
    if Settings.TargetPart == "Head" then
        return m:FindFirstChild("Head") or m:FindFirstChild("HumanoidRootPart")
    elseif Settings.TargetPart == "Torso" then
        return m:FindFirstChild("Torso") or m:FindFirstChild("UpperTorso") or m:FindFirstChild("HumanoidRootPart")
    else
        return m:FindFirstChild("HumanoidRootPart") or m:FindFirstChild("Torso") or m:FindFirstChild("Head")
    end
end

local function canSee(part)
    if not Settings.WallCheck then return true end
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = {LocalPlayer.Character, part.Parent}
    return not Workspace:Raycast(Camera.CFrame.Position, part.Position - Camera.CFrame.Position, params)
end

local function isValidTarget(m)
    if not m or not m.Parent or m == LocalPlayer.Character then return false end
    local hum = m:FindFirstChildOfClass("Humanoid")
    local root = getRootPart(m)
    if not hum or not root or hum.Health <= 0 then return false end
    local p = Players:GetPlayerFromCharacter(m)
    if p then
        if Settings.TeamCheck and LocalPlayer.Team and p.Team and LocalPlayer.Team == p.Team then return false end
        return true
    else
        return Settings.AimBots or Settings.ESPBots
    end
end

local function createEsp(model)
    local esp = {}
    esp.Highlight = Instance.new("Highlight")
    esp.Highlight.Adornee = model
    esp.Highlight.FillColor = Theme.Accent
    esp.Highlight.OutlineColor = Color3.new(1, 1, 1)
    esp.Highlight.FillTransparency = 0.5
    esp.Highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    esp.Highlight.Enabled = false
    esp.Highlight.Parent = Gui
    esp.Box = Drawing.new("Square")
    esp.Box.Thickness = 2
    esp.Box.Filled = false
    esp.Box.Visible = false
    esp.Line = Drawing.new("Line")
    esp.Line.Thickness = 1.5
    esp.Line.Visible = false
    esp.Skel = {}
    for i = 1, 6 do
        local l = Drawing.new("Line")
        l.Thickness = 2
        l.Visible = false
        table.insert(esp.Skel, l)
    end
    return esp
end

local function clearEsp(m)
    local esp = EspObjects[m]
    if not esp then return end
    pcall(function() esp.Highlight:Destroy() end)
    pcall(function() esp.Box:Remove() end)
    pcall(function() esp.Line:Remove() end)
    for _, l in ipairs(esp.Skel) do pcall(function() l:Remove() end) end
    EspObjects[m] = nil
end

local fovCircle = Drawing.new("Circle")
fovCircle.Thickness = 1.5
fovCircle.NumSides = 60
fovCircle.Filled = false

function UpdateTheme()
    MainStroke.Color = Settings.ThemeColor
    if AvatarImage and AvatarImage:FindFirstChild("UIStroke") then
        AvatarImage.UIStroke.Color = Settings.ThemeColor
    end
    if StatsTitle then StatsTitle.TextColor3 = Settings.ThemeColor end
    if HTitle then HTitle.TextColor3 = Settings.ThemeColor end
    if TargetPartBtn then TargetPartBtn.TextColor3 = Settings.ThemeColor end
    if Logo then Logo.TextColor3 = Settings.ThemeColor end
    if OptimizeTitle then OptimizeTitle.TextColor3 = Settings.ThemeColor end
    if OpacityTitle then OpacityTitle.TextColor3 = Settings.ThemeColor end
    if FPSStroke then FPSStroke.Color = Settings.ThemeColor end
    if FPSTitle then FPSTitle.TextColor3 = Settings.ThemeColor end
    
    for _, ref in ipairs(ToggleRefs) do
        if ref.Btn and ref.Btn.Parent then
            local state = Settings[ref.SettingName]
            ref.SwitchBg.BackgroundColor3 = state and Settings.ThemeColor or Theme.Hover
            ref.Label.TextColor3 = state and Theme.Text or Theme.SubText
        end
    end
end

RunService.RenderStepped:Connect(function(dt)
    local now = os.clock()
    table.insert(fpsTable, now)
    while fpsTable[1] and fpsTable[1] < now - 1 do table.remove(fpsTable, 1) end
    currentFPS = #fpsTable
    
    if currentFPS > 0 then
        if currentFPS < minFPS then minFPS = currentFPS end
        if currentFPS > maxFPS then maxFPS = currentFPS end
        totalFPS = totalFPS + currentFPS
        fpsCount = fpsCount + 1
    end
    
    if Settings.LimitFPS then
        local sleepTime = (1 / Settings.MaxFPS) - dt
        if sleepTime > 0 then task.wait(sleepTime) end
    end
    
    local networkPing = "0"
    pcall(function() networkPing = string.format("%.0f", LocalPlayer:GetNetworkPing() * 1000) end)
    LiveMetrics.Text = string.format("FPS: %d | PING: %sms | CLOCK: %s", currentFPS, networkPing, os.date("%X"))
    
    if ShowFPSPopup and FPSPopup.Visible then
        local avgFPS = fpsCount > 0 and math.floor(totalFPS / fpsCount) or 0
        local duration = os.time() - StartTime
        FPSContent.Text = string.format("Current FPS:   %d\n\nAverage FPS:   %d\n\nMin FPS:         %d\n\nMax FPS:         %d\n\nSession:  %02dh %02dm %02ds",
            currentFPS, avgFPS, minFPS, maxFPS, math.floor(duration/3600), math.floor((duration%3600)/60), duration%60)
    end
    
    if Settings.IsRainbow then
        Settings.ThemeColor = Color3.fromHSV((os.clock() % 6) / 6, 0.9, 1)
        UpdateTheme()
    end
    
    UpdateOpacity()
    
    local mouseLoc = UserInputService:GetMouseLocation()
    fovCircle.Position = mouseLoc
    fovCircle.Radius = Settings.FOV
    fovCircle.Visible = Settings.Master and Settings.ShowFOV
    fovCircle.Color = Settings.ThemeColor
    
    if not Settings.Master then return end
    
    -- Aimbot
    local closest = nil
    local shortDist = Settings.FOV
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character and isValidTarget(p.Character) then
            local root = getRootPart(p.Character)
            if root and canSee(root) then
                local pos, onScreen = Camera:WorldToViewportPoint(root.Position)
                if onScreen then
                    local d = (Vector2.new(pos.X, pos.Y) - mouseLoc).Magnitude
                    if d < shortDist then shortDist = d; closest = root end
                end
            end
        end
    end
    CurrentTarget = closest
    
    if CurrentTarget then
        local aimCFrame = CFrame.lookAt(Camera.CFrame.Position, CurrentTarget.Position)
        if Settings.Aimbot then
            Camera.CFrame = aimCFrame
        elseif Settings.AimAssist then
            Camera.CFrame = Camera.CFrame:Lerp(aimCFrame, math.clamp(Settings.Smoothness * (dt * 60), 0, 1))
        end
        if Settings.Triggerbot and tick() - LastTriggerClick > Settings.TriggerbotDelay then
            pcall(function() mouse1press(); task.wait(0.01); mouse1release() end)
            LastTriggerClick = tick()
        end
    end
    
    -- Movement
    local char = LocalPlayer.Character
    if char then
        local hum = char:FindFirstChildOfClass("Humanoid")
        local root = char:FindFirstChild("HumanoidRootPart")
        if hum then hum.WalkSpeed = Settings.SpeedHack and Settings.WalkSpeed or 16 end
        
        if Settings.Fly and root and hum then
            local velocity = Vector3.zero
            if UserInputService:IsKeyDown(Enum.KeyCode.W) then velocity = velocity + Camera.CFrame.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.S) then velocity = velocity - Camera.CFrame.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.A) then velocity = velocity - Camera.CFrame.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.D) then velocity = velocity + Camera.CFrame.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.Space) then velocity = velocity + Vector3.new(0, 1, 0) end
            if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then velocity = velocity - Vector3.new(0, 1, 0) end
            root.AssemblyLinearVelocity = velocity.Magnitude > 0 and velocity.Unit * Settings.FlySpeed or Vector3.zero
            hum.PlatformStand = true
        elseif hum then
            hum.PlatformStand = false
        end
        
        if Settings.Spinbot and root then
            root.CFrame = root.CFrame * CFrame.Angles(0, math.rad(Settings.SpinSpeed), 0)
        end
        
        if Settings.NoClip then
            for _, part in pairs(char:GetDescendants()) do
                if part:IsA("BasePart") then part.CanCollide = false end
            end
        else
            for _, part in pairs(char:GetDescendants()) do
                if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then part.CanCollide = true end
            end
        end
    end
    
    -- ESP
    local activeMap = {}
    for _, p in ipairs(Players:GetPlayers()) do
        if p.Character and isValidTarget(p.Character) then activeMap[p.Character] = p end
    end
    for model in pairs(EspObjects) do
        if not activeMap[model] or not Settings.ESP then clearEsp(model) end
    end
    
    if Settings.ESP then
        for model in pairs(activeMap) do
            local root = getRootPart(model)
            local head = model:FindFirstChild("Head")
            if root and head then
                local rootPos, rootOnScreen = Camera:WorldToViewportPoint(root.Position)
                local esp = EspObjects[model] or createEsp(model)
                EspObjects[model] = esp
                esp.Highlight.Enabled = Settings.ESPChams
                esp.Highlight.FillColor = Settings.ThemeColor
                
                if rootOnScreen then
                    local headPos = Camera:WorldToViewportPoint(head.Position + Vector3.new(0, 1.6, 0))
                    local legPos = Camera:WorldToViewportPoint(root.Position - Vector3.new(0, 3, 0))
                    local boxH = math.abs(headPos.Y - legPos.Y)
                    local boxW = boxH * 0.65
                    
                    esp.Box.Visible = Settings.ESPBox
                    if Settings.ESPBox then
                        esp.Box.Size = Vector2.new(boxW, boxH)
                        esp.Box.Position = Vector2.new(rootPos.X - boxW/2, headPos.Y)
                        esp.Box.Color = Settings.ThemeColor
                    end
                    
                    esp.Line.Visible = Settings.ESPLine
                    if Settings.ESPLine then
                        esp.Line.From = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y)
                        esp.Line.To = Vector2.new(rootPos.X, rootPos.Y)
                        esp.Line.Color = Settings.ThemeColor
                    end
                    
                    if Settings.ESPSkeleton then
                        local function gj(n)
                            local pt = model:FindFirstChild(n)
                            if pt then
                                local v, o = Camera:WorldToViewportPoint(pt.Position)
                                return o and Vector2.new(v.X, v.Y) or nil
                            end
                        end
                        local j = {H=gj("Head"), T=gj("UpperTorso") or gj("Torso"), LA=gj("LeftArm") or gj("LeftUpperArm"), RA=gj("RightArm") or gj("RightUpperArm"), LL=gj("LeftLeg") or gj("LeftUpperLeg"), RL=gj("RightLeg") or gj("RightUpperLeg")}
                        if j.H and j.T then esp.Skel[1].From=j.H; esp.Skel[1].To=j.T; esp.Skel[1].Visible=true; esp.Skel[1].Color=Settings.ThemeColor else esp.Skel[1].Visible=false end
                        if j.T and j.LA then esp.Skel[2].From=j.T; esp.Skel[2].To=j.LA; esp.Skel[2].Visible=true; esp.Skel[2].Color=Settings.ThemeColor else esp.Skel[2].Visible=false end
                        if j.T and j.RA then esp.Skel[3].From=j.T; esp.Skel[3].To=j.RA; esp.Skel[3].Visible=true; esp.Skel[3].Color=Settings.ThemeColor else esp.Skel[3].Visible=false end
                        if j.T and j.LL then esp.Skel[4].From=j.T; esp.Skel[4].To=j.LL; esp.Skel[4].Visible=true; esp.Skel[4].Color=Settings.ThemeColor else esp.Skel[4].Visible=false end
                        if j.T and j.RL then esp.Skel[5].From=j.T; esp.Skel[5].To=j.RL; esp.Skel[5].Visible=true; esp.Skel[5].Color=Settings.ThemeColor else esp.Skel[5].Visible=false end
                    else
                        for _, l in ipairs(esp.Skel) do l.Visible = false end
                    end
                else
                    esp.Box.Visible = false
                    esp.Line.Visible = false
                    for _, l in ipairs(esp.Skel) do l.Visible = false end
                end
            end
        end
    end
end)

UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end
    if input.KeyCode == Enum.KeyCode.RightShift then
        MainUI.Visible = not MainUI.Visible
    elseif input.KeyCode == Enum.KeyCode.F then
        Settings.Fly = not Settings.Fly
        ShowNotification("Fly", tostring(Settings.Fly), 2)
    elseif input.KeyCode == Enum.KeyCode.V then
        Settings.SpeedHack = not Settings.SpeedHack
        ShowNotification("Speed", tostring(Settings.SpeedHack), 2)
    elseif input.KeyCode == Enum.KeyCode.N then
        Settings.NoClip = not Settings.NoClip
        ShowNotification("NoClip", tostring(Settings.NoClip), 2)
    elseif input.KeyCode == Enum.KeyCode.T then
        if CurrentTarget and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
            LocalPlayer.Character.HumanoidRootPart.CFrame = CurrentTarget.CFrame * CFrame.new(0, 0, 3)
        end
    elseif input.KeyCode == Enum.KeyCode.H then
        ShowFPSPopup = not ShowFPSPopup
        FPSPopup.Visible = ShowFPSPopup
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then DraggingSlider = nil end
end)

UserInputService.InputChanged:Connect(function(input)
    if DraggingSlider and input.UserInputType == Enum.UserInputType.MouseMovement then DraggingSlider(input) end
end)

-- ==========================================
-- INTRO & START
-- ==========================================
task.spawn(function()
    pcall(function()
        SmoothTween(IntroText, 1.0, {Position = UDim2.new(0.5, 0, 0.5, 0)})
        task.wait(2.5)
        SmoothTween(IntroText, 0.5, {TextTransparency = 1})
        SmoothTween(IntroStroke, 0.5, {Transparency = 1})
        task.wait(0.5)
        SmoothTween(IntroFrame, 0.5, {BackgroundTransparency = 1})
        task.wait(0.5)
        IntroFrame:Destroy()
    end)
    
    MainUI.Visible = true
    MainUIScale.Scale = 1
    
    ShowNotification("QeeHacker V1.2.1", "GUARANTEED VISIBLE! NoClip+Optimize+FPS+Opacity", 4)
end)

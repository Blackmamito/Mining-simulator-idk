if game.PlaceId == 1417427737 then repeat task.wait(1) until game:IsLoaded() end

local SellTreshold = getgenv().SellTreshold or 30000
local Depth = getgenv().Depth or 205

local Players = game:GetService("Players")
local Client = Players.LocalPlayer
local Remote

-- Safer loading frame handler
local ScreenGui = Client:WaitForChild("PlayerGui"):WaitForChild("ScreenGui")
local LoadingFrame = ScreenGui:FindFirstChild("LoadingFrame")

if LoadingFrame and LoadingFrame:FindFirstChild("BackgroundTransparency") then
    while LoadingFrame.BackgroundTransparency == 0 do
        local Quality = LoadingFrame:FindFirstChild("Quality")
        local LowQuality = Quality and Quality:FindFirstChild("LowQuality")
        if LowQuality and LowQuality:FindFirstChild("MouseButton1Down") then
            for i, connection in pairs(getconnections(LowQuality.MouseButton1Down)) do
                connection:Fire()
            end
        end
        task.wait(1)
    end
end

-- Wait for stats safely
while true do
    if Client:FindFirstChild("leaderstats") and Client.leaderstats:FindFirstChild("Blocks Mined") then
        local StatsFrame = ScreenGui:FindFirstChild("StatsFrame")
        if StatsFrame and StatsFrame:FindFirstChild("Coins") and StatsFrame.Coins:FindFirstChild("Amount") then
            local Tokens = StatsFrame:FindFirstChild("Tokens")
            if Tokens and Tokens:FindFirstChild("Amount") and Tokens.Amount.Text ~= "Loading..." then
                break
            end
        end
    end
    task.wait(1)
end

-- UI Cleanup
if ScreenGui:FindFirstChild("TeleporterFrame") then ScreenGui.TeleporterFrame:Destroy() end
if ScreenGui:FindFirstChild("StatsFrame") and ScreenGui.StatsFrame:FindFirstChild("Sell") then ScreenGui.StatsFrame.Sell:Destroy() end
if ScreenGui:FindFirstChild("MainButtons") and ScreenGui.MainButtons:FindFirstChild("Surface") then ScreenGui.MainButtons.Surface:Destroy() end
if ScreenGui:FindFirstChild("Collapse") then ScreenGui.Collapse.Visible = true end

-- Rebirth GUI Tracker
local ExampleFrame = ScreenGui:FindFirstChild("StatsFrame") and ScreenGui.StatsFrame:FindFirstChild("Inventory")
if ExampleFrame then
    local Rebirths = Client.leaderstats:FindFirstChild("Rebirths")
    if Rebirths then
        local Rebirths2 = ExampleFrame:Clone()
        Rebirths2.Parent = ExampleFrame.Parent
        Rebirths2.Position = UDim2.new(0, 0, 1.5, 15)
        if Rebirths2:FindFirstChild("Logo") then Rebirths2.Logo.Image = "rbxassetid://1440681030" end
        if Rebirths2:FindFirstChild("Amount") then 
            Rebirths2.Amount.Text = tostring(Rebirths.Value)
            Rebirths:GetPropertyChangedSignal("Value"):Connect(function()
                Rebirths2.Amount.Text = tostring(Rebirths.Value)
            end)
        end
    end
end

-- Anti-Disconnect Reconnect
local promptOverlay = game.CoreGui:WaitForChild("RobloxPromptGui"):WaitForChild("promptOverlay")
promptOverlay.ChildAdded:Connect(function(child)
    if child.Name == 'ErrorPrompt' then
        repeat
            game:GetService("TeleportService"):Teleport(game.PlaceId, Client)
            task.wait(2)
        until false
    end
end)

-- Map Collapse Check
if workspace:FindFirstChild("Collapsed") then
    workspace.Collapsed.Changed:Connect(function()
        if workspace.Collapsed.Value == true then
            game:GetService("TeleportService"):Teleport(game.PlaceId, Client)
        end
    end)
end

-- Dynamic Remote Extraction
local ClientScript = ScreenGui:FindFirstChild("ClientScript")
if ClientScript then
    local Data = getsenv(ClientScript).displayCurrent
    if Data then
        for i = 1, 20 do
            local val = debug.getupvalue(Data, i)
            if type(val) == "table" and val["RemoteEvent"] then
                Remote = val["RemoteEvent"]
                break
            end
        end
    end
end

if not Remote then
    warn("Failed to dynamically find RemoteEvent. The game layout has changed completely.")
    return
end

-- Character Rig Setup
local Character = Client.Character or Client.CharacterAdded:Wait()
local HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")
local humanoid = Character:WaitForChild("Humanoid")
humanoid.WalkSpeed = 0
humanoid.JumpPower = 0
HumanoidRootPart.Anchored = true

Remote:FireServer("MoveTo", {{"LavaSpawn"}})

local part = Instance.new("Part", workspace)
part.Anchored = true
part.Size = Vector3.new(10, 1 , 100)
part.Material = Enum.Material.ForceField
part.Position = Vector3.new(21, 9.5, 26285)
task.wait(1)
HumanoidRootPart.Anchored = false

while HumanoidRootPart.Position.Z > 26220 do
    HumanoidRootPart.CFrame = CFrame.new(Vector3.new(HumanoidRootPart.Position.X, 13.05, HumanoidRootPart.Position.Z - 0.5))
    task.wait(0.01)
end
HumanoidRootPart.CFrame = CFrame.new(18, 10, 26220)

local function Split(s, delimiter)
    local result = {}
    for match in (s..delimiter):gmatch("(.-)"..delimiter) do
        table.insert(result, match)
    end
    return result
end

-- Mining loop down to target depth
if ScreenGui:FindFirstChild("TopInfoFrame") and ScreenGui.TopInfoFrame:FindFirstChild("Depth") then
    local depthText = Split(ScreenGui.TopInfoFrame.Depth.Text, " ")
    while tonumber(depthText[1]) and tonumber(depthText[1]) < Depth do
        local min = HumanoidRootPart.CFrame + Vector3.new(-1,-10,-1)
        local max = HumanoidRootPart.CFrame + Vector3.new(1,0,1)
        local region = Region3.new(min.Position, max.Position)
        if workspace:FindFirstChild("Blocks") then
            local parts = workspace:FindPartsInRegion3WithWhiteList(region, {workspace.Blocks}, 10)
            for _, block in pairs(parts) do
                Remote:FireServer("MineBlock", {{block.Parent}})
                task.wait()
            end
        end
        depthText = Split(ScreenGui.TopInfoFrame.Depth.Text, " ")
        task.wait()
    end
end

local CoinsAmount = Client.leaderstats:FindFirstChild("Coins")
local function GetCoinsAmount()
    if not CoinsAmount then return 0 end
    local Amount = tostring(CoinsAmount.Value):gsub(',', '')
    return tonumber(Amount) or 0
end

-- Out-of-bounds Recovery System
local recovering = false
if ScreenGui:FindFirstChild("TopInfoFrame") and ScreenGui.TopInfoFrame:FindFirstChild("Depth") then
    local DepthAmount = ScreenGui.TopInfoFrame.Depth
    DepthAmount.Changed:Connect(function()
        task.spawn(function()
            local depth = Split(DepthAmount.Text, " ")
            if tonumber(depth[1]) and tonumber(depth[1]) >= 1000 and not recovering then
                recovering = true
                HumanoidRootPart.CFrame = CFrame.new(18, Depth, 26220)
                task.wait(0.5)
                recovering = false
            end
        end)
    end)
end

-- RunService Automated Auto-Rebirth loop
local RebirthsAmount = Client.leaderstats:FindFirstChild("Rebirths")
game:GetService("RunService"):BindToRenderStep("Rebirth", Enum.RenderPriority.Camera.Value, function()
    if RebirthsAmount then
        while GetCoinsAmount() >= (10000000 * (RebirthsAmount.Value + 1)) do
            Remote:FireServer("Rebirth", {{}})
            task.wait()
        end
    end
end)

local function GetInventoryAmount()
    local StatsFrame2 = ScreenGui:FindFirstChild("StatsFrame2")
    local Inventory = StatsFrame2 and StatsFrame2:FindFirstChild("Inventory")
    local AmountLabel = Inventory and Inventory:FindFirstChild("Amount")
    if not AmountLabel then return 0 end
    
    local Amount = AmountLabel.Text:gsub('%s+', ''):gsub(',', '')
    local splitInv = Amount:split("/")
    return tonumber(splitInv[1]) or 0
end

-- Main Core Loop: Aura Mining & Material Offloading
local SellArea = CFrame.new(42, 14, -1239)
while task.wait() do
    if workspace:FindFirstChild("Blocks") then
        local minp = HumanoidRootPart.CFrame.Position - Vector3.new(5, 5, 5)
        local maxp = HumanoidRootPart.CFrame.Position + Vector3.new(5, 5, 5)
        local region = Region3.new(minp, maxp)
        local parts = workspace:FindPartsInRegion3WithWhiteList(region, {workspace.Blocks}, 50)
        for _, block in ipairs(parts) do    
            Remote:FireServer("MineBlock", {{block.Parent}})
            task.wait()
        end
    end
    
    local SavedPosition = HumanoidRootPart.Position
    while GetInventoryAmount() >= SellTreshold and not recovering do
        Remote:FireServer("SellItems", {{}})
        HumanoidRootPart.CFrame = SellArea
        task.wait()
    end
    
    local starttime1 = os.time()
    while (HumanoidRootPart.Position - SavedPosition).Magnitude > 1 do
        HumanoidRootPart.CFrame = CFrame.new(18, SavedPosition.Y, 26220)
        task.wait()
        if os.time() - starttime1 > 2 then
            break
        end
    end
end

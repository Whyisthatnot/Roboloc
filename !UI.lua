--== Services ==--
local Players = game:GetService("Players")
local StarterGui = game:GetService("StarterGui")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--== Player ==--
local LocalPlayer = Players.LocalPlayer
local Backpack = LocalPlayer:WaitForChild("Backpack")

--== Data ==--
local data = require(ReplicatedStorage.PlayerData):GetData().Data

--== Rarity Order ==--
local rarityOrder = {
    Common = 1, Uncommon = 2, Rare = 3, Epic = 4,
    Legendary = 5, Mythic = 6, Godly = 7, Secret = 8
}

--== UI Setup ==--
local function setupSimpleUI()
    pcall(function()
        StarterGui:SetCore("TopbarEnabled", false)
    end)

    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "SimpleUI"
    screenGui.ResetOnSpawn = false
    screenGui.IgnoreGuiInset = true
    screenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
    screenGui.DisplayOrder = 2147483647
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

    -- 🔲 Border quanh màn hình
    local borderFrame = Instance.new("Frame")
    borderFrame.Name = "ScreenBorder"
    borderFrame.Size = UDim2.new(1, -72, 1, -72)
    borderFrame.Position = UDim2.new(0, 36, 0, 36)
    borderFrame.BackgroundTransparency = 1
    borderFrame.ZIndex = 10
    borderFrame.Parent = screenGui

    local borderStroke = Instance.new("UIStroke")
    borderStroke.Thickness = 2
    borderStroke.Color = Color3.fromRGB(255, 255, 255)
    borderStroke.Transparency = 0.3
    borderStroke.Parent = borderFrame

    local borderCorner = Instance.new("UICorner")
    borderCorner.CornerRadius = UDim.new(0, 10)
    borderCorner.Parent = borderFrame

    -- Background mờ đen
    local bgFrame = Instance.new("Frame")
    bgFrame.Size = UDim2.new(1, 0, 1, 0)
    bgFrame.BackgroundColor3 = Color3.new(0, 0, 0)
    bgFrame.BorderSizePixel = 0
    bgFrame.BackgroundTransparency = 0.2
    bgFrame.Parent = screenGui

    -- Khung chính để chứa text (CHÍNH GIỮA)
    local mainFrame = Instance.new("Frame")
    mainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
    mainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
    mainFrame.Size = UDim2.new(0, 600, 0, 250)
    mainFrame.BackgroundTransparency = 1
    mainFrame.Parent = bgFrame

    --== Helper tạo Label căn giữa in đậm ==--
    local function createLabel(yOffset, color, text)
        local lbl = Instance.new("TextLabel")
        lbl.Size = UDim2.new(1, 0, 0, 30)
        lbl.Position = UDim2.new(0, 0, 0, yOffset)
        lbl.BackgroundTransparency = 1
        lbl.Font = Enum.Font.GothamBold
        lbl.TextSize = 22
        lbl.TextColor3 = color
        lbl.Text = text or ""
        lbl.TextXAlignment = Enum.TextXAlignment.Center
        lbl.TextWrapped = false
        lbl.Parent = mainFrame
        return lbl
    end

    -- 📌 Labels
    local playerLabel   = createLabel(0,   Color3.fromRGB(0, 170, 255), "Player: " .. LocalPlayer.Name)
    local brainrotLabel = createLabel(40,  Color3.fromRGB(0, 255, 127), "Best Brainrot: ... | Total Brainrots: 0")

    -- Line trên Status
    local topLine = Instance.new("Frame")
    topLine.Size = UDim2.new(1, -20, 0, 2)
    topLine.Position = UDim2.new(0, 10, 0, 80)
    topLine.BackgroundColor3 = Color3.fromRGB(200, 200, 200)
    topLine.BorderSizePixel = 0
    topLine.Parent = mainFrame

    local statusLabel   = createLabel(90,  Color3.fromRGB(255, 255, 255), "Status: Idle")

    -- Line dưới Status
    local bottomLine = Instance.new("Frame")
    bottomLine.Size = UDim2.new(1, -20, 0, 2)
    bottomLine.Position = UDim2.new(0, 10, 0, 125)
    bottomLine.BackgroundColor3 = Color3.fromRGB(200, 200, 200)
    bottomLine.BorderSizePixel = 0
    bottomLine.Parent = mainFrame

    local rebirthLabel  = createLabel(135, Color3.fromRGB(255, 105, 180), "Rebirth: 0")
    local coinLabel     = createLabel(170, Color3.fromRGB(255, 215, 0),   "Coins: 0")

    -- 📌 Update loop
    task.spawn(function()
        while task.wait(3) do
            -- Coins
            local stats = LocalPlayer:FindFirstChild("leaderstats")
            local money = stats and stats:FindFirstChild("Money")
            if money then
                coinLabel.Text = "Coins: " .. tostring(money.Value)
            end

            -- Rebirth
            local rebirth = stats and stats:FindFirstChild("Rebirth")
            if rebirth then
                rebirthLabel.Text = "Rebirth: " .. tostring(rebirth.Value)
            end

            -- Best Brainrot + Total Brainrots
            local best, highestVal = nil, -1
            local totalCount = 0
            for _, tool in ipairs(Backpack:GetChildren()) do
                if tool:IsA("Tool") and tool:GetAttribute("Brainrot") then
                    totalCount += 1
                    local name = tool:GetAttribute("Brainrot")
                    local asset = ReplicatedStorage.Assets.Brainrots:FindFirstChild(name)
                    if asset then
                        local rarity = asset:GetAttribute("Rarity")
                        local val = rarityOrder[rarity] or 0
                        if val > highestVal then
                            highestVal = val
                            best = name .. " (" .. rarity .. ")"
                        end
                    end
                end
            end
            brainrotLabel.Text = "Best Brainrot: " .. (best or "None") ..
                                 " | Total Brainrots: " .. tostring(totalCount)

            -- Status (có thể thay đổi theo logic game)
            statusLabel.Text = "Status: Running..."
        end
    end)
end

-- 📌 Gọi
setupSimpleUI()

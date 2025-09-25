
getgenv().Config = {
    Lock = { "Legendary", "Mythic", "Godly", "Secret" } -- giữ lại mấy con này (theo rarity)
}
--== Services ==--
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local player = Players.LocalPlayer
--== Player & Data ==--
local LocalPlayer = Players.LocalPlayer
local Backpack = LocalPlayer:WaitForChild("Backpack")
local data = require(ReplicatedStorage.PlayerData):GetData().Data

--== Modules ==--
local BridgeNet2 = require(ReplicatedStorage.Modules.Utility.BridgeNet2)
local Util = require(ReplicatedStorage.Modules.Utility.Util)
local Notification = require(ReplicatedStorage.Modules.Utility.Notification)

--== Remotes / Bridges ==--
local dataRemote = ReplicatedStorage:WaitForChild("BridgeNet2"):WaitForChild("dataRemoteEvent")
local EquipBestBrainrots = BridgeNet2.ReferenceBridge("EquipBestBrainrots")
local buyBridge = BridgeNet2.ReferenceBridge("BuyItem")
local ItemSell = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("ItemSell")
local PlaceItem = BridgeNet2.ReferenceBridge("PlaceItem")
local RemoveItem = BridgeNet2.ReferenceBridge("RemoveItem")

--== Plot ==--
local plotId = LocalPlayer:GetAttribute("Plot") or "4"
local plot = workspace.Plots:FindFirstChild(tostring(plotId))

--== Humanoid ==--
local humanoid = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid") or nil
if not humanoid then
    LocalPlayer.CharacterAdded:Wait()
    humanoid = LocalPlayer.Character:WaitForChild("Humanoid")
end

local canEquip = true

--== Rarity Order (cho AutoPlant) ==--
local rarityOrder = {
    Common = 1, Uncommon = 2, Rare = 3, Epic = 4,
    Legendary = 5, Mythic = 6, Godly = 7, Secret = 8
}

--== Row Prices (cho AutoExpand) ==--
local rowPrices = {
    [2] = 100000,
    [3] = 100000,
    [4] = 2500000,
    [5] = 2500000,
    [6] = 10000000,
    [7] = 10000000,
}

local function getRarityValue(r) return rarityOrder[r] or 0 end

-- 📌 Check row đã unlock chưa
local function IsRowUnlocked(rowId)
    local row = plot.Rows:FindFirstChild(tostring(rowId))
    if not row then return false end

    for _, folder in ipairs(row:GetChildren()) do
        for _, block in ipairs(folder:GetChildren()) do
            if block:GetAttribute("CanPlace") then
                return true
            end
        end
    end
    return false
end

-- 📌 Auto Expand tuần tự
local function AutoExpandSequential()
    for rowId = 2, 7 do
        print("[DEBUG] 🔍 Thử mở Row", rowId)

        if IsRowUnlocked(rowId) then
            print("✅ Row", rowId, "đã mở sẵn → tiếp tục")
        else
            local price = rowPrices[rowId]
            if not price then
                warn("⚠️ Không có giá cho row", rowId)
                return
            end

            if data.Money >= price then
                print("💰 Đủ tiền ("..data.Money..") → Mở Row", rowId, "giá:", price)
                dataRemote:FireServer({rowId, "\t"})
                statusLabel.Text = "Status: Unlocking Row " .. rowId
                task.wait(0.5) -- delay nhỏ
            else
                break -- dừng hẳn, không check row sau nữa
            end
        end
    end
end

-- Lấy seeds trong Backpack
local function GetSeeds()
    local seeds = {}
    for _, tool in ipairs(Backpack:GetChildren()) do
        if tool:IsA("Tool") and tool:GetAttribute("Plant") then
            local plantName = tool:GetAttribute("Plant")
            local id = tool:GetAttribute("ID")
            local asset = ReplicatedStorage.Assets.Plants:FindFirstChild(plantName)
            local rarity = asset and asset:GetAttribute("Rarity") or "Common"
            table.insert(seeds, {tool=tool, plant=plantName, rarity=rarity, id=id})
        end
    end
    return seeds
end

-- Lấy block gần Button / Lawn Mower nhất
local function GetRowFreeBlock(row)
    local button = row:FindFirstChild("Button") or row:FindFirstChild("Lawn Mower")
    if not button then return nil end

    local buttonPos
    if button:IsA("BasePart") then
        buttonPos = button.Position
    elseif button.PrimaryPart then
        buttonPos = button.PrimaryPart.Position
    else
        local part = button:FindFirstChildWhichIsA("BasePart", true)
        buttonPos = part and part.Position
    end
    if not buttonPos then return nil end

    local nearestBlock, nearestDist
    for _, folder in ipairs(row:GetChildren()) do
        if folder.Name == "Grass" then
            for _, block in ipairs(folder:GetChildren()) do
                if block:IsA("BasePart") and block:GetAttribute("CanPlace") then
                    local dist = (block.Position - buttonPos).Magnitude
                    if not nearestDist or dist < nearestDist then
                        nearestDist, nearestBlock = dist, block
                    end
                end
            end
        end
    end
    return nearestBlock
end

-- Đếm số row mở
local function CountOpenedRows()
    local opened = 0
    for _, row in ipairs(plot.Rows:GetChildren()) do
        local grass = row:FindFirstChild("Grass")
        if grass then
            for _, block in ipairs(grass:GetChildren()) do
                if block:GetAttribute("CanPlace") then
                    opened += 1
                    break
                end
            end
        end
    end
    return opened
end

-- Lấy toàn bộ plant theo row
local function GetPlantsByRow(rowId)
    local plants = {}
    for _, plant in ipairs(plot.Plants:GetChildren()) do
        if plant:IsA("Model") and tostring(plant:GetAttribute("Row")) == tostring(rowId) then
            table.insert(plants, plant)
        end
    end
    return plants
end

-- Lấy lowest plant trong toàn plot
local function GetLowestPlant()
    local lowest, val = nil, math.huge
    for _, plant in ipairs(plot.Plants:GetChildren()) do
        if plant:IsA("Model") and plant:GetAttribute("Rarity") then
            if not plant:GetAttribute("Filtered") then
                local v = getRarityValue(plant:GetAttribute("Rarity"))
                if v < val then val, lowest = v, plant end
            end
        end
    end
    return lowest, val
end

-- Xoá bớt trong row dư >5
local function TrimRow(row, rowId)
    local plants = GetPlantsByRow(rowId)
    local count = #plants
    if count > 5 then
        table.sort(plants, function(a, b)
            return getRarityValue(a:GetAttribute("Rarity")) < getRarityValue(b:GetAttribute("Rarity"))
        end)
        local toRemove = count - 5
        for i=1,toRemove do
            local p = plants[i]
            print("⚠️ Row", rowId, "có", count, "cây (>5) → xoá", p.Name, p:GetAttribute("Rarity"))
            RemoveItem:Fire(p:GetAttribute("ID"))
            statusLabel.Text = "Status: Removing " .. p.Name .. " (" .. p:GetAttribute("Rarity") .. ")"
            task.wait(0.3)
        end
    end
end

-- Bổ sung vào row thiếu <5
local function FillRow(row, rowId, seeds)
    local plants = GetPlantsByRow(rowId)
    local count = #plants
    if count < 5 then
        local needed = 5 - count
        for i=1,needed do
            if #seeds == 0 then break end
            local block = GetRowFreeBlock(row)
            if block then
                local seed = table.remove(seeds, 1)
                humanoid:EquipTool(seed.tool)
                task.wait(0.2)
                PlaceItem:Fire({
                    Item = seed.plant,
                    CFrame = CFrame.new(block.Position + Vector3.new(0,2,0)),
                    ID = seed.id,
                    Floor = block,
                })
                statusLabel.Text = "Status: Placing " .. seed.plant
                task.wait(0.3)
            end
        end
    end
end

-- Thanh lọc: thay cây yếu bằng seed mạnh hơn
local function FilterRows(seeds)
    while #seeds > 0 do
        local lowestPlant, lowestVal = GetLowestPlant()
        if not lowestPlant then break end

        local seed = table.remove(seeds, 1)
        local seedVal = getRarityValue(seed.rarity)

        if seedVal > lowestVal then
            print("xoá", lowestPlant.Name, lowestPlant:GetAttribute("Rarity"),
                  "Row", lowestPlant:GetAttribute("Row"))
            RemoveItem:Fire(lowestPlant:GetAttribute("ID"))
            lowestPlant:SetAttribute("Filtered", true)
            task.wait(0.5)

            local row = plot.Rows:FindFirstChild(tostring(lowestPlant:GetAttribute("Row")))
            local freeBlock = row and GetRowFreeBlock(row)
            if freeBlock then
                humanoid:EquipTool(seed.tool)
                task.wait(0.2)
                PlaceItem:Fire({
                    Item = seed.plant,
                    CFrame = CFrame.new(freeBlock.Position + Vector3.new(0,2,0)),
                    ID = seed.id,
                    Floor = freeBlock,
                })
                print("🌱 Thay cây mới:", seed.plant, seed.rarity, "ở Row", row.Name)
                task.wait(0.3)
            end
        
        end
    end
end

--== 🌱 AutoPlantRows ==--
local function AutoPlantRows()
    local seeds = GetSeeds()
    if #seeds == 0 then
        warn("❌ Không có seed để trồng")
        return
    end

    local rowCount = CountOpenedRows()
    local minTotal = rowCount * 5
    local totalPlants = #plot.Plants:GetChildren()

    if totalPlants < minTotal then
        for _, row in ipairs(plot.Rows:GetChildren()) do
            FillRow(row, row.Name, seeds)
        end
    else
        -- Xoá dư
        for _, row in ipairs(plot.Rows:GetChildren()) do
            TrimRow(row, row.Name)
        end
        -- Bù thiếu
        for _, row in ipairs(plot.Rows:GetChildren()) do
            FillRow(row, row.Name, seeds)
        end
        -- Thanh lọc
        FilterRows(seeds)
    end

end

--== Hàm check lock ==--
local function isLocked(rarity)
    for _, locked in ipairs(getgenv().Config.Lock) do
        if string.lower(rarity) == string.lower(locked) then
            return true
        end
    end
    return false
end

--== Auto Sell ==--
local function AutoSellBrainrots()
    local count = 0
    for _, tool in ipairs(Backpack:GetChildren()) do
        if tool:IsA("Tool") and tool:GetAttribute("Brainrot") then
            local brainrotName = tool:GetAttribute("Brainrot")

            -- lấy rarity từ ReplicatedStorage.Assets.Brainrots
            local rarity = "Unknown"
            local asset = ReplicatedStorage:FindFirstChild("Assets")
            if asset and asset:FindFirstChild("Brainrots") then
                local model = asset.Brainrots:FindFirstChild(brainrotName)
                if model and model:GetAttribute("Rarity") then
                    rarity = model:GetAttribute("Rarity")
                end
            end

            if not isLocked(rarity) then
                local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
                if humanoid then
                    humanoid:EquipTool(tool)
                end

                task.wait(0.1)

                local args = { true }
                ItemSell:FireServer(unpack(args))
                statusLabel.Text = "Status: Selling " .. brainrotName
                count += 1
                task.wait(0.2)
            end
        end
    end
end
-- 📌 Function: Mua hết tất cả seed tốt nhất có thể
local function BuyAllBestSeeds()
    local Seeds = ReplicatedStorage:WaitForChild("Assets"):WaitForChild("Seeds")
    local boughtCount = 0

    while true do
        local bestSeed
        local bestPrice = -math.huge

        -- 🔎 Tìm seed đắt nhất có thể mua
        for _, seed in ipairs(Seeds:GetChildren()) do
            local price = seed:GetAttribute("Price")
            local stock = seed:GetAttribute("Stock") or 0
            local owned = data.Stock.Seeds.Stock[seed.Name] or 0
            local available = stock - owned

            if price and price > bestPrice and available > 0 and data.Money >= price then
                bestPrice = price
                bestSeed = seed
            end
        end

        -- 📌 Nếu tìm thấy thì mua
        if bestSeed then
            local args = {
                {
                    bestSeed.Name,
                    "\a"
                }
            }
            ReplicatedStorage:WaitForChild("BridgeNet2"):WaitForChild("dataRemoteEvent"):FireServer(unpack(args))
            boughtCount += 1
            statusLabel.Text = "Status: Buying seed " .. bestSeed.Name
            -- Trừ tiền local cho vòng lặp (phòng khi Data chưa update kịp)
            data.Money -= bestPrice

            task.wait(0.2) -- delay nhỏ tránh spam quá nhanh
        else
            break -- không còn seed nào mua được nữa
        end
    end

end






-- 📌 Function: Equip best brainrot
local function EquipBestBrainrot()
    if not canEquip then
        warn("⏳ Chờ cooldown trước khi equip best lại!")
        return
    end

    canEquip = false
    EquipBestBrainrots:Fire()
    print("✅ Đã gửi yêu cầu equip best brainrot!")
    statusLabel.Text = "Status: Equipping best brainrot"
    task.delay(2, function() -- cooldown 2 giây
        canEquip = true
    end)
end

-- 📌 Lấy số tiền hiện tại
local function getMoney()
    local stats = LocalPlayer:FindFirstChild("leaderstats")
    local money = stats and stats:FindFirstChild("Money")
    local value = money and money.Value or 0
    return value
end

-- 📌 Function mở slot tiếp theo
local function unlockNextSlot()

    local plotId = LocalPlayer:GetAttribute("Plot") -- 📌 lấy plotId từ attribute player
    if not plotId then
        warn("[DEBUG] ❌ Không tìm thấy plotId trong attribute Player")
        return
    end

    local plot = workspace.Plots:FindFirstChild(tostring(plotId))
    if not plot then
        warn("[DEBUG] ❌ Không tìm thấy plot:", plotId)
        return
    end

    local brainrots = plot:FindFirstChild("Brainrots")
    if not brainrots then
        warn("[DEBUG] ❌ Không tìm thấy Brainrots trong plot:", plotId)
        return
    end

    -- Tìm slot Enabled cao nhất
    local highestEnabled = 0
    for _, slot in ipairs(brainrots:GetChildren()) do
        if slot:GetAttribute("Enabled") then
            local id = tonumber(slot.Name)
            if id and id > highestEnabled then
                highestEnabled = id
            end
        end
    end

    -- Slot cần mua là +1
    local nextSlotId = tostring(highestEnabled + 1)
    local nextSlot = brainrots:FindFirstChild(nextSlotId)
    if not nextSlot then
        warn("[DEBUG] ❌ Không tìm thấy slot tiếp theo:", nextSlotId)
        return
    end

    -- Kiểm tra có price không
    local priceLabel = nextSlot:FindFirstChild("PlatformPrice") and nextSlot.PlatformPrice:FindFirstChild("Money")
    if not priceLabel or not priceLabel:IsA("TextLabel") then
        warn("[DEBUG] ❌ Slot", nextSlotId, "không có priceLabel -> có thể đã mở hoặc chưa thể mua")
        return
    end

    local priceStr = priceLabel.Text:gsub("%$", ""):gsub(",", "")
    local price = tonumber(priceStr) or math.huge

    -- Check tiền
    if getMoney() >= price then

        local args = {
            { nextSlotId, "4" }
        }
        dataRemote:FireServer(unpack(args))
        statusLabel.Text = "Status: Unlocking slot " .. nextSlotId
    end
end

local function AllInOneOptimize()
    local Players = game:GetService("Players")
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local Workspace = game:GetService("Workspace")
    local LocalPlayer = Players.LocalPlayer

    local dataRemote = ReplicatedStorage:WaitForChild("BridgeNet2"):WaitForChild("dataRemoteEvent")

    -- 📌 1. Tắt settings: SFX, RareNotis, Music, ShowOthers
    local settingsToDisable = {"SFX", "RareNotis", "Music", "ShowOthers"}
    for _, setting in ipairs(settingsToDisable) do
        local args = {
            {
                {
                    Value = false,
                    Setting = setting
                },
                "\020"
            }
        }
        dataRemote:FireServer(unpack(args))
    end

    -- 📌 2. FPS Boost
    local Lighting = game:GetService("Lighting")
    Lighting.GlobalShadows = false
    Lighting.FogEnd = 9e9
    Lighting.Brightness = 1
    Lighting.EnvironmentDiffuseScale = 0
    Lighting.EnvironmentSpecularScale = 0

    for _, v in ipairs(Lighting:GetDescendants()) do
        if v:IsA("BlurEffect") or v:IsA("SunRaysEffect") or v:IsA("ColorCorrectionEffect") 
        or v:IsA("BloomEffect") or v:IsA("DepthOfFieldEffect") then
            v.Enabled = false
        end
    end

    for _, v in ipairs(Workspace:GetDescendants()) do
        if v:IsA("ParticleEmitter") or v:IsA("Trail") then
            v.Enabled = false
        end
        if v:IsA("PointLight") or v:IsA("SpotLight") or v:IsA("SurfaceLight") then
            v.Enabled = false
        end
        if v:IsA("MeshPart") or v:IsA("Part") then
            v.Material = Enum.Material.Plastic
            v.Reflectance = 0
        end
        if v:IsA("Decal") or v:IsA("Texture") then
            v.Transparency = 1
        end
    end

    local terrain = Workspace:FindFirstChildOfClass("Terrain")
    if terrain then
        terrain.WaterReflectance = 0
        terrain.WaterTransparency = 1
        terrain.WaterWaveSize = 0
        terrain.WaterWaveSpeed = 0
    end

    -- 📌 3. Chỉ giữ plot LocalPlayer, xoá plot khác
    local plotId = LocalPlayer:GetAttribute("Plot")
    if not plotId then
        warn("❌ Không tìm thấy PlotId trong attribute của player")
        return
    end
    local plots = Workspace:FindFirstChild("Plots")
    if plots then
        for _, plot in ipairs(plots:GetChildren()) do
            if plot.Name ~= tostring(plotId) then
                plot:Destroy()
            end
        end
    end

    -- 📌 4. Xoá mọi thứ trong Workspace trừ whitelist
    local keep = {
        Camera = true,
        Terrain = true,
        Brainrots = true,
        Players = true,
        Plots = true,
        ScriptedMap = true,
    }
    for _, obj in ipairs(Workspace:GetChildren()) do
        if not keep[obj.Name] then
            obj:Destroy()
        end
    end

    -- 📌 5. Trong plot LocalPlayer: xoá 'Other', ẩn toàn bộ object còn lại (Transparency)
    local myPlot = Workspace.Plots:FindFirstChild(tostring(plotId))
    if myPlot then
        for _, obj in ipairs(myPlot:GetChildren()) do
            if obj.Name == "Other" then
                print("🗑️ Xoá folder Other trong plot:", plotId)
                obj:Destroy()
            else
                if obj:IsA("BasePart") then
                    obj.Transparency = 1
                elseif obj:IsA("Model") or obj:IsA("Folder") then
                    for _, child in ipairs(obj:GetDescendants()) do
                        if child:IsA("BasePart") then
                            child.Transparency = 1
                        end
                    end
                end
            end
        end
    end
end
AllInOneOptimize()

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
setupSimpleUI()

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

-- 📌 Tele tới NPC George trong plot của LocalPlayer và kích prompt
local function TeleportToGeorge()
    local plotId = LocalPlayer:GetAttribute("Plot")
    if not plotId then
        warn("❌ Không tìm thấy PlotId trong attribute Player")
        return
    end

    local plot = workspace.Plots:FindFirstChild(tostring(plotId))
    if not plot then
        warn("❌ Không tìm thấy plot:", plotId)
        return
    end

    local george = plot:FindFirstChild("NPCs") and plot.NPCs:FindFirstChild("George")
    if not george or not george:FindFirstChild("RootPart") then
        warn("❌ Không tìm thấy NPC George trong plot:", plotId)
        return
    end

    -- 📌 Teleport LocalPlayer
    local character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    local hrp = character:WaitForChild("HumanoidRootPart")
    hrp.CFrame = george.RootPart.CFrame + Vector3.new(0, 3, 0) -- đứng trên đầu 1 chút
	task.wait(0.1)
    -- 📌 Tương tác ProximityPrompt
    local prompt = george.RootPart:FindFirstChildOfClass("ProximityPrompt")
    if prompt then
        fireproximityprompt(prompt) -- native function exploit environment
        print("✅ Đã teleport và kích prompt của George")
    else
        warn("❌ Không tìm thấy ProximityPrompt trong George.RootPart")
    end
end

-- 📌 Chạy thử

while true do
    local a = getMoney()
    if a <= 400 then
        TeleportToGeorge()
        task.wait(2)
        BuyAllBestSeeds()
        task.wait(2)
        AutoPlantRows()
        task.wait(14)
		task.wait()
		EquipBestBrainrot()

    end

    BuyAllBestSeeds()
    task.wait(2)
    AutoPlantRows()
    task.wait(2)
    EquipBestBrainrot()
    task.wait(2)

    unlockNextSlot()
    task.wait(2)

    AutoExpandSequential()
    task.wait(2)

    AutoSellBrainrots()
	task.wait(5)
end

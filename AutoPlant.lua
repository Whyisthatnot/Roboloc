--== Services ==--
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local BridgeNet2 = require(ReplicatedStorage.Modules.Utility.BridgeNet2)

local player = Players.LocalPlayer
local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid") or nil
if not humanoid then
    player.CharacterAdded:Wait()
    humanoid = player.Character:WaitForChild("Humanoid")
end

-- Plot
local plotId = player:GetAttribute("Plot") or "4"
local plot = workspace.Plots:FindFirstChild(tostring(plotId))

-- Remotes
local PlaceItem = BridgeNet2.ReferenceBridge("PlaceItem")
local RemoveItem = BridgeNet2.ReferenceBridge("RemoveItem")

-- Rarity order
local rarityOrder = {
    Common = 1, Uncommon = 2, Rare = 3, Epic = 4,
    Legendary = 5, Mythic = 6, Godly = 7, Secret = 8
}
local function getRarityValue(r) return rarityOrder[r] or 0 end

--== Helper ==--

-- Lấy seeds trong Backpack
local function GetSeeds()
    local seeds = {}
    for _, tool in ipairs(player.Backpack:GetChildren()) do
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
                print("🌱 Bổ sung Row", rowId, "→ trồng", seed.plant, seed.rarity, "(", count+i, "/5 )")
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
            print("🔥 Thanh lọc → xoá", lowestPlant.Name, lowestPlant:GetAttribute("Rarity"),
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
        else
            print("⚠️ Seed", seed.plant, seed.rarity, "không tốt hơn lowest → bỏ qua")
        end
    end
end

--== 🌱 AutoPlantRows ==--
local function AutoPlantRows()
    print("\n========== 🌱 AutoPlantRows START ==========")
    local seeds = GetSeeds()
    if #seeds == 0 then
        warn("❌ Không có seed để trồng")
        return
    end

    local rowCount = CountOpenedRows()
    local minTotal = rowCount * 5
    local totalPlants = #plot.Plants:GetChildren()
    print("[DEBUG] Row mở =", rowCount, "| minTotal =", minTotal, "| hiện có =", totalPlants)

    if totalPlants < minTotal then
        print("[DEBUG] Tổng <", minTotal, "→ trồng bổ sung")
        for _, row in ipairs(plot.Rows:GetChildren()) do
            FillRow(row, row.Name, seeds)
        end
    else
        print("[DEBUG] Tổng ≥", minTotal, "→ cân bằng + thanh lọc")
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

    print("========== ✅ AutoPlantRows DONE ==========")
end

--== Run thử ==--
AutoPlantRows()

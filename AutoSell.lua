getgenv().Config = {
    Lock = { "Legendary", "Mythic", "Godly", "Secret" } -- giữ lại mấy con này (theo rarity)
}

--== Services ==--
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local player = Players.LocalPlayer
local Backpack = player:WaitForChild("Backpack")

--== Remotes ==--
local ItemSell = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("ItemSell")

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
                count += 1
                task.wait(0.2)
            end
        end
    end
    print("✅ AutoSellBrainrots DONE | Total Sold:", count)
end

--== Chạy thử ==--
AutoSellBrainrots()
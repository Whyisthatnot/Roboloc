local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Module & bridges có sẵn từ code bạn đưa
local Util = require(ReplicatedStorage.Modules.Utility.Util)
local Notification = require(ReplicatedStorage.Modules.Utility.Notification)
local BridgeNet2 = require(ReplicatedStorage.Modules.Utility.BridgeNet2)

local player = Players.LocalPlayer
local data = require(ReplicatedStorage.PlayerData):GetData().Data
local buyBridge = BridgeNet2.ReferenceBridge("BuyItem")
-- 📌 Function: Mua hết tất cả seed tốt nhất có thể
local function BuyAllBestSeeds()
    local Seeds = ReplicatedStorage:WaitForChild("Assets"):WaitForChild("Seeds")
    local boughtCount = 0

    print("🔍 [DEBUG] === Bắt đầu mua seed ===")
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
            print("✅ [DEBUG] Mua seed:", bestSeed.Name, "giá:", bestPrice)
            local args = {
                {
                    bestSeed.Name,
                    "\a"
                }
            }
            ReplicatedStorage:WaitForChild("BridgeNet2"):WaitForChild("dataRemoteEvent"):FireServer(unpack(args))
            boughtCount += 1

            -- Trừ tiền local cho vòng lặp (phòng khi Data chưa update kịp)
            data.Money -= bestPrice

            task.wait(0.2) -- delay nhỏ tránh spam quá nhanh
        else
            break -- không còn seed nào mua được nữa
        end
    end

    print("🔍 [DEBUG] === Kết thúc mua seed | Tổng mua:", boughtCount, "===")
end

-- 📌 Gọi thử
BuyAllBestSeeds()


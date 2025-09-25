local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer

local dataRemote = ReplicatedStorage:WaitForChild("BridgeNet2"):WaitForChild("dataRemoteEvent")

-- 📌 Lấy số tiền hiện tại
local function getMoney()
    local stats = LocalPlayer:FindFirstChild("leaderstats")
    local money = stats and stats:FindFirstChild("Money")
    return money and money.Value or 0
end

-- 📌 Function mở slot tiếp theo
local function unlockNextSlot()
    print("[DEBUG] ==== Bắt đầu check slot để mở ====")

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
    print("[DEBUG] Highest Enabled slot =", highestEnabled)

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
    print("[DEBUG] Slot", nextSlotId, "giá =", price, "| Money =", getMoney())

    -- Check tiền
    if getMoney() >= price then
        print("[DEBUG] ✅ Đủ tiền để mở slot", nextSlotId)

        local args = {
            { nextSlotId, "4" } -- 📌 dùng plotId của player
        }
        print("[DEBUG] Gửi FireServer với args =", args[1][1], args[1][2])
        dataRemote:FireServer(unpack(args))
    else
        warn("[DEBUG] ❌ Không đủ tiền mở slot", nextSlotId, "| Cần:", price, "| Có:", getMoney())
    end
end

-- Test
unlockNextSlot()
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local BridgeNet2 = require(ReplicatedStorage.Modules.Utility.BridgeNet2)

local player = Players.LocalPlayer
local data = require(ReplicatedStorage.PlayerData):GetData().Data

-- Remote mở row
local dataRemote = ReplicatedStorage:WaitForChild("BridgeNet2"):WaitForChild("dataRemoteEvent")

-- Plot
local plotId = player:GetAttribute("Plot")
local plot = workspace.Plots:FindFirstChild(tostring(plotId))

-- Giá row (thứ tự từ thấp đến cao)
local rowPrices = {
    [2] = 100000,
    [3] = 100000,
    [4] = 2500000,
    [5] = 2500000,
    [6] = 10000000,
    [7] = 10000000,
}

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
                task.wait(0.5) -- delay nhỏ
            else
                print("❌ Không đủ tiền mở Row", rowId, "cần:", price, "có:", data.Money)
                break -- dừng hẳn, không check row sau nữa
            end
        end
    end
end

-- 📌 Gọi hàm
AutoExpandSequential()
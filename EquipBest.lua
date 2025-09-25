local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Lấy LocalPlayer
local player = Players.LocalPlayer

-- Lấy BridgeNet2 và remote
local BridgeNet2 = require(ReplicatedStorage.Modules.Utility.BridgeNet2)
local EquipBestBrainrots = BridgeNet2.ReferenceBridge("EquipBestBrainrots")

-- Cooldown để tránh spam
local canEquip = true

-- 📌 Function: Equip best brainrot
local function EquipBestBrainrot()
    if not canEquip then
        warn("⏳ Chờ cooldown trước khi equip best lại!")
        return
    end

    canEquip = false
    EquipBestBrainrots:Fire()
    print("✅ Đã gửi yêu cầu equip best brainrot!")

    task.delay(2, function() -- cooldown 2 giây
        canEquip = true
    end)
end

-- 📌 Ví dụ chạy
EquipBestBrainrot()
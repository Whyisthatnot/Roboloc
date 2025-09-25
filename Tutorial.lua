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
TeleportToGeorge()

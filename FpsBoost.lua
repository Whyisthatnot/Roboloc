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
        print("⚙️ Disabled setting:", setting)
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

    Workspace.MaterialService.Use2022Materials = false
    local terrain = Workspace:FindFirstChildOfClass("Terrain")
    if terrain then
        terrain.WaterReflectance = 0
        terrain.WaterTransparency = 1
        terrain.WaterWaveSize = 0
        terrain.WaterWaveSpeed = 0
    end
    print("✅ FPSBoost applied!")

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
                print("🗑️ Xoá plot:", plot.Name)
                plot:Destroy()
            else
                print("✅ Giữ lại plot của LocalPlayer:", plot.Name)
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
            print("🗑️ Xoá:", obj.Name)
            obj:Destroy()
        end
    end
    print("✅ Đã xoá tất cả object trong Workspace trừ whitelist")

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
                print("👻 Ẩn:", obj.Name, "trong plot:", plotId)
            end
        end
        print("✅ Đã xoá Other và ẩn toàn bộ object còn lại trong plot:", plotId)
    end
end

-- 📌 Gọi function
AllInOneOptimize()
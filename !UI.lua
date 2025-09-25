local Players = game:GetService("Players")
local StarterGui = game:GetService("StarterGui")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer

-- Nếu bạn cần Data để sau này update


local function setupSimpleUI()
    -- Ẩn topbar mặc định
    pcall(function()
        StarterGui:SetCore("TopbarEnabled", false)
    end)

    -- ScreenGui
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

    -- Background mờ
    local bgFrame = Instance.new("Frame")
    bgFrame.Size = UDim2.new(1, 0, 1, 0)
    bgFrame.BackgroundColor3 = Color3.new(0, 0, 0)
    bgFrame.BorderSizePixel = 0
    bgFrame.BackgroundTransparency = 0.2
    bgFrame.Parent = screenGui

    -- Main Frame (khung UI chính, để bạn thêm nội dung sau)
    local mainFrame = Instance.new("Frame")
    mainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
    mainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
    mainFrame.Size = UDim2.new(0, 500, 0, 320)
    mainFrame.BackgroundTransparency = 1
    mainFrame.Parent = bgFrame
end

-- 📌 Gọi setup
setupSimpleUI()

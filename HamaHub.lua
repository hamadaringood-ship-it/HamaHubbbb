local Lib = Instance.new("ScreenGui")
local UIS = game:GetService("UserInputService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local player = Players.LocalPlayer

Lib.Name = "HamaHub_Duels"
Lib.Parent = game:GetService("CoreGui")
Lib.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

-- ========== AUTO DUEL VARIABLES ==========
local rightWaypoints = {
    Vector3.new(-473.04, -6.99, 29.71),
    Vector3.new(-483.57, -5.10, 18.74),
    Vector3.new(-475.00, -6.99, 26.43),
    Vector3.new(-474.67, -6.94, 105.48),
}
local leftWaypoints = {
    Vector3.new(-472.49, -7.00, 90.62),
    Vector3.new(-484.62, -5.10, 100.37),
    Vector3.new(-475.08, -7.00, 93.29),
    Vector3.new(-474.22, -6.96, 16.18),
}
local patrolMode = "none"
local floating = false
local currentWaypoint = 1
local heartbeatConn
local waitingForCountdownLeft = false
local waitingForCountdownRight = false
local AUTO_START_DELAY = 0.7

-- Bat Aimbot Variables
local batAimbotActive = false
local batAimbotConn = nil
local AimbotRadius = 100
local BatAimbotSpeed = 55
local SlapList = {
    {1, "Bat"}, {2, "Slap"}, {3, "Iron Slap"}, {4, "Gold Slap"},
    {5, "Diamond Slap"}, {6, "Emerald Slap"}, {7, "Ruby Slap"},
    {8, "Dark Matter Slap"}, {9, "Flame Slap"}, {10, "Nuclear Slap"},
    {11, "Galaxy Slap"}, {12, "Glitched Slap"}
}

-- ========== SPIN BOT VARIABLES ==========
local spinActive = false
local spinAngle = 0
local spinSpeed = 10
local spinAlign = nil
local spinAttachment = nil
local spinConn = nil

local function setupSpinBot()
    local char = player.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    if spinAlign then spinAlign:Destroy() end
    if spinAttachment then spinAttachment:Destroy() end
    spinAttachment = Instance.new("Attachment")
    spinAttachment.Parent = hrp
    spinAlign = Instance.new("AlignOrientation")
    spinAlign.Attachment0 = spinAttachment
    spinAlign.Mode = Enum.OrientationAlignmentMode.OneAttachment
    spinAlign.Responsiveness = 30
    spinAlign.MaxTorque = math.huge
    spinAlign.RigidityEnabled = false
    spinAlign.Enabled = false
    spinAlign.Parent = hrp
end

local function startSpinBot()
    setupSpinBot()
    if spinAlign then spinAlign.Enabled = true end
    if spinConn then spinConn:Disconnect() end
    spinConn = RunService.Heartbeat:Connect(function(dt)
        if not spinActive then return end
        if not spinAlign or not spinAlign.Parent then
            setupSpinBot()
            if spinAlign then spinAlign.Enabled = true end
            return
        end
        spinAngle = spinAngle + spinSpeed * dt
        spinAlign.CFrame = CFrame.Angles(0, spinAngle, 0)
    end)
end

local function stopSpinBot()
    spinActive = false
    if spinConn then spinConn:Disconnect(); spinConn = nil end
    if spinAlign then spinAlign.Enabled = false end
end

-- ========== STEAL SPEED VARIABLES ==========
local stealSpeedActive = false
local stealSpeedConn = nil
local STEAL_SPEED_VALUE = 29.4

local function startStealSpeed()
    if stealSpeedConn then stealSpeedConn:Disconnect() end
    stealSpeedConn = RunService.Heartbeat:Connect(function()
        if not stealSpeedActive then return end
        local char = player.Character
        if not char then return end
        local hum = char:FindFirstChildOfClass("Humanoid")
        local root = char:FindFirstChild("HumanoidRootPart")
        if not hum or not root then return end
        if hum.MoveDirection.Magnitude > 0.1 then
            local moveDir = hum.MoveDirection.Unit
            root.AssemblyLinearVelocity = Vector3.new(
                moveDir.X * STEAL_SPEED_VALUE,
                root.AssemblyLinearVelocity.Y,
                moveDir.Z * STEAL_SPEED_VALUE
            )
        end
    end)
end

local function stopStealSpeed()
    if stealSpeedConn then
        stealSpeedConn:Disconnect()
        stealSpeedConn = nil
    end
end

-- ========== TP VARIABLES ==========
local tpFinalLeft = Vector3.new(-483.59, -5.04, 104.24)
local tpFinalRight = Vector3.new(-483.51, -5.10, 18.89)
local tpCheckA = Vector3.new(-472.60, -7.00, 57.52)
local tpCheckLeft = Vector3.new(-472.65, -7.00, 95.69)
local tpCheckRight = Vector3.new(-471.76, -7.00, 26.22)
local lastTpSide = "none"
local ragdollDetectorConn = nil
local ragdollAutoActive = false

local function tpMove(pos)
    local char = player.Character
    if not char then return end
    char:PivotTo(CFrame.new(pos))
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if hrp then hrp.AssemblyLinearVelocity = Vector3.new(0,0,0) end
end

local function doTPLeft()
    tpMove(tpCheckA)
    task.wait(0.1)
    tpMove(tpCheckLeft)
    task.wait(0.1)
    tpMove(tpFinalLeft)
    lastTpSide = "left"
    print("TP Left done")
end

local function doTPRight()
    tpMove(tpCheckA)
    task.wait(0.1)
    tpMove(tpCheckRight)
    task.wait(0.1)
    tpMove(tpFinalRight)
    lastTpSide = "right"
    print("TP Right done")
end

local function isRagdolled(char)
    if not char then return false end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if hum and hum:GetState() == Enum.HumanoidStateType.Ragdoll then return true end
    local ragVal = char:FindFirstChild("Ragdoll") or char:FindFirstChild("IsRagdoll")
    if ragVal and ragVal:IsA("BoolValue") and ragVal.Value then return true end
    return false
end

local ragdollWasActive = false

-- ========== ANTI RAGDOLL ==========
local antiRagdollActive = false
local antiRagdollConn = nil

local function startAntiRagdoll()
    if antiRagdollConn then antiRagdollConn:Disconnect() end
    antiRagdollConn = RunService.Heartbeat:Connect(function()
        if not antiRagdollActive then return end
        local char = player.Character
        if not char then return end
        local hum = char:FindFirstChildOfClass("Humanoid")
        local root = char:FindFirstChild("HumanoidRootPart")
        if hum then
            local state = hum:GetState()
            if state == Enum.HumanoidStateType.Physics
            or state == Enum.HumanoidStateType.Ragdoll
            or state == Enum.HumanoidStateType.FallingDown then
                if not ragdollWasActive then
                    hum:ChangeState(Enum.HumanoidStateType.Running)
                    if workspace.CurrentCamera then
                        workspace.CurrentCamera.CameraSubject = hum
                    end
                    if root then
                        root.Velocity = Vector3.new(0, 0, 0)
                        root.RotVelocity = Vector3.new(0, 0, 0)
                    end
                end
            end
        end
        for _, obj in ipairs(char:GetDescendants()) do
            if obj:IsA("Motor6D") and obj.Enabled == false then
                obj.Enabled = true
            end
        end
    end)
end

local function stopAntiRagdoll()
    if antiRagdollConn then
        antiRagdollConn:Disconnect()
        antiRagdollConn = nil
    end
end

-- ========== UNWALK ==========
local unwalkActive = false
local unwalkConn = nil

local function startUnwalk()
    if unwalkConn then unwalkConn:Disconnect() end
    unwalkConn = RunService.Heartbeat:Connect(function()
        if not unwalkActive then return end
        local char = player.Character
        if not char then return end
        local hum = char:FindFirstChildOfClass("Humanoid")
        if not hum then return end
        local animator = hum:FindFirstChildOfClass("Animator")
        if not animator then return end
        for _, track in pairs(animator:GetPlayingAnimationTracks()) do
            track:Stop()
        end
    end)
end

local function stopUnwalk()
    if unwalkConn then
        unwalkConn:Disconnect()
        unwalkConn = nil
    end
end

local function startRagdollDetector()
    if ragdollDetectorConn then ragdollDetectorConn:Disconnect() end
    ragdollDetectorConn = RunService.Heartbeat:Connect(function()
        if not ragdollAutoActive then return end
        local char = player.Character
        if not char then return end
        local nowRagdolled = isRagdolled(char)
        if nowRagdolled and not ragdollWasActive then
            ragdollWasActive = true
            print("Ragdoll detected! Auto-TP + patrol on side:", lastTpSide)
            task.spawn(function()
                task.wait(0.15)
                if lastTpSide == "left" then
                    doTPLeft()
                    task.wait(0.2)
                    if patrolMode ~= "left" then
                        startMovement("left", buttons["autoleft"])
                    end
                elseif lastTpSide == "right" then
                    doTPRight()
                    task.wait(0.2)
                    if patrolMode ~= "right" then
                        startMovement("right", buttons["autoright"])
                    end
                end
            end)
        elseif not nowRagdolled then
            ragdollWasActive = false
        end
    end)
end

local function stopRagdollDetector()
    if ragdollDetectorConn then
        ragdollDetectorConn:Disconnect()
        ragdollDetectorConn = nil
    end
    ragdollWasActive = false
end

-- ========== AUTO STEAL VARIABLES ==========
local stealActive = false
local stealConn = nil
local animalCache = {}
local promptCache = {}
local stealCache = {}
local isStealing = false
local STEAL_R = 8
local AnimalsData = {}

pcall(function()
    local rep = game:GetService("ReplicatedStorage")
    local datas = rep:FindFirstChild("Datas")
    if datas then
        local animals = datas:FindFirstChild("Animals")
        if animals then AnimalsData = require(animals) end
    end
end)

local function stealHRP()
    local c = player.Character; if not c then return nil end
    return c:FindFirstChild("HumanoidRootPart") or c:FindFirstChild("UpperTorso")
end

local function isMyBase(plotName)
    local plot = workspace.Plots and workspace.Plots:FindFirstChild(plotName); if not plot then return false end
    local sign = plot:FindFirstChild("PlotSign"); if not sign then return false end
    local yb = sign:FindFirstChild("YourBase")
    return yb and yb:IsA("BillboardGui") and yb.Enabled == true
end

local function scanPlot(plot)
    if not plot or not plot:IsA("Model") then return end
    if isMyBase(plot.Name) then return end
    local podiums = plot:FindFirstChild("AnimalPodiums"); if not podiums then return end
    for _, pod in ipairs(podiums:GetChildren()) do
        if pod:IsA("Model") and pod:FindFirstChild("Base") then
            local name = "Unknown"
            local spawn = pod.Base:FindFirstChild("Spawn")
            if spawn then
                for _, child in ipairs(spawn:GetChildren()) do
                    if child:IsA("Model") and child.Name ~= "PromptAttachment" then
                        name = child.Name
                        local info = AnimalsData[name]
                        if info and info.DisplayName then name = info.DisplayName end
                        break
                    end
                end
            end
            table.insert(animalCache, {
                name = name, plot = plot.Name, slot = pod.Name,
                worldPosition = pod:GetPivot().Position,
                uid = plot.Name .. "_" .. pod.Name,
            })
        end
    end
end

local function findPrompt(ad)
    if not ad then return nil end
    local cp = promptCache[ad.uid]
    if cp and cp.Parent then return cp end
    local plots = workspace:FindFirstChild("Plots"); if not plots then return nil end
    local plot = plots:FindFirstChild(ad.plot); if not plot then return nil end
    local pods = plot:FindFirstChild("AnimalPodiums"); if not pods then return nil end
    local pod = pods:FindFirstChild(ad.slot); if not pod then return nil end
    local base = pod:FindFirstChild("Base"); if not base then return nil end
    local sp = base:FindFirstChild("Spawn"); if not sp then return nil end
    local att = sp:FindFirstChild("PromptAttachment"); if not att then return nil end
    for _, p in ipairs(att:GetChildren()) do
        if p:IsA("ProximityPrompt") then promptCache[ad.uid] = p; return p end
    end
end

local function buildCallbacks(prompt)
    if stealCache[prompt] then return end
    local data = { holdCallbacks = {}, triggerCallbacks = {}, ready = true }
    local ok1, c1 = pcall(getconnections, prompt.PromptButtonHoldBegan)
    if ok1 and type(c1) == "table" then
        for _, conn in ipairs(c1) do
            if type(conn.Function) == "function" then table.insert(data.holdCallbacks, conn.Function) end
        end
    end
    local ok2, c2 = pcall(getconnections, prompt.Triggered)
    if ok2 and type(c2) == "table" then
        for _, conn in ipairs(c2) do
            if type(conn.Function) == "function" then table.insert(data.triggerCallbacks, conn.Function) end
        end
    end
    if #data.holdCallbacks > 0 or #data.triggerCallbacks > 0 then stealCache[prompt] = data end
end

local function execSteal(prompt)
    local data = stealCache[prompt]
    if not data or not data.ready then return false end
    data.ready = false; isStealing = true
    task.spawn(function()
        for _, fn in ipairs(data.holdCallbacks) do task.spawn(fn) end
        task.wait(0.2)
        for _, fn in ipairs(data.triggerCallbacks) do task.spawn(fn) end
        task.wait(0.01); data.ready = true; task.wait(0.01); isStealing = false
    end)
    return true
end

local function nearestAnimal()
    local hrp = stealHRP(); if not hrp then return nil end
    local best, bestD = nil, math.huge
    for _, ad in ipairs(animalCache) do
        if not isMyBase(ad.plot) and ad.worldPosition then
            local d = (hrp.Position - ad.worldPosition).Magnitude
            if d < bestD then bestD = d; best = ad end
        end
    end
    return best
end

local function startStealLoop()
    if stealConn then stealConn:Disconnect() end
    stealConn = RunService.Heartbeat:Connect(function()
        if not stealActive or isStealing then return end
        local target = nearestAnimal(); if not target then return end
        local hrp = stealHRP(); if not hrp then return end
        if (hrp.Position - target.worldPosition).Magnitude > STEAL_R then return end
        local prompt = promptCache[target.uid]
        if not prompt or not prompt.Parent then prompt = findPrompt(target) end
        if prompt then buildCallbacks(prompt); execSteal(prompt) end
    end)
end

local function stopStealLoop()
    if stealConn then stealConn:Disconnect(); stealConn = nil end
end

local stealInitialized = false
local function initSteal()
    if stealInitialized then return end
    stealInitialized = true
    task.spawn(function()
        task.wait(2)
        local plots = workspace:WaitForChild("Plots", 10); if not plots then return end
        for _, plot in ipairs(plots:GetChildren()) do if plot:IsA("Model") then scanPlot(plot) end end
        plots.ChildAdded:Connect(function(plot)
            if plot:IsA("Model") then task.wait(0.5); scanPlot(plot) end
        end)
        task.spawn(function()
            while task.wait(5) do
                animalCache = {}
                for _, plot in ipairs(plots:GetChildren()) do if plot:IsA("Model") then scanPlot(plot) end end
            end
        end)
    end)
    startStealLoop()
    print("Auto Steal initialized")
end

-- ========== AUTO DUEL HELPER FUNCTIONS ==========
local function isCountdownNumber(text)
    local num = tonumber(text)
    if num and num >= 1 and num <= 5 then
        return true, num
    end
    return false
end

local function isTimerInCountdown(label)
    if not label then return false end
    local ok, num = isCountdownNumber(label.Text)
    return ok and num >= 1 and num <= 5
end

local function getCurrentSpeed()
    if patrolMode == "right" then
        if currentWaypoint >= 3 then
            return 29.4
        else
            return 60
        end
    elseif patrolMode == "left" then
        if currentWaypoint >= 3 then
            return 29.4
        else
            return 60
        end
    end
    return 0
end

local function getCurrentWaypoints()
    if patrolMode == "right" then
        return rightWaypoints
    elseif patrolMode == "left" then
        return leftWaypoints
    end
    return {}
end

-- ========== GRÜNE FARBE DEFINITIONEN ==========
local GREEN_ACCENT     = Color3.fromRGB(0, 255, 157)
local GREEN_STATUS     = Color3.fromRGB(100, 255, 160)
local TEXT_LIGHT_GREEN = Color3.fromRGB(220, 255, 240)

local function updateButtonState(button, isActive, activeText, inactiveText)
    if isActive then
        button.BackgroundColor3 = GREEN_ACCENT
        button.BackgroundTransparency = 0.7
        button:FindFirstChild("StatusDot").BackgroundColor3 = GREEN_STATUS
        button:FindFirstChild("Label").Text = activeText or button:FindFirstChild("Label").Text
    else
        button.BackgroundColor3 = Color3.fromRGB(10, 10, 12)
        button.BackgroundTransparency = 0.15
        button:FindFirstChild("StatusDot").BackgroundColor3 = Color3.fromRGB(70, 70, 80)
        if inactiveText then
            button:FindFirstChild("Label").Text = inactiveText
        end
    end
end

local function startMovement(mode, button)
    patrolMode = mode
    currentWaypoint = 1
    if mode == "right" then
        updateButtonState(button, true, "Auto Right [ON]")
        print("AutoRight movement started")
    else
        updateButtonState(button, true, "Auto Left [ON]")
        print("AutoLeft movement started")
    end
end

local function stopMovement(rightButton, leftButton)
    patrolMode = "none"
    currentWaypoint = 1
    waitingForCountdownLeft = false
    waitingForCountdownRight = false
    updateButtonState(rightButton, false, nil, "Auto Right")
    updateButtonState(leftButton, false, nil, "Auto Left")
    local char = player.Character
    if char then
        local root = char:FindFirstChild("HumanoidRootPart")
        if root then
            root.AssemblyLinearVelocity = Vector3.new(0, root.AssemblyLinearVelocity.Y, 0)
        end
    end
end

-- ========== BAT AIMBOT FUNCTIONS ==========
local function findBat()
    local c = player.Character
    if not c then return nil end
    local bp = player:FindFirstChildOfClass("Backpack")
    for _, ch in ipairs(c:GetChildren()) do
        if ch:IsA("Tool") and ch.Name:lower():find("bat") then return ch end
    end
    if bp then
        for _, ch in ipairs(bp:GetChildren()) do
            if ch:IsA("Tool") and ch.Name:lower():find("bat") then return ch end
        end
    end
    for _, i in ipairs(SlapList) do
        local t = c:FindFirstChild(i[2]) or (bp and bp:FindFirstChild(i[2]))
        if t then return t end
    end
    return nil
end

local function findNearestEnemy(myHRP)
    local nearest = nil
    local nearestDist = math.huge
    local nearestTorso = nil
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= player and p.Character then
            local eh = p.Character:FindFirstChild("HumanoidRootPart")
            local torso = p.Character:FindFirstChild("UpperTorso") or p.Character:FindFirstChild("Torso")
            local hum = p.Character:FindFirstChildOfClass("Humanoid")
            if eh and hum and hum.Health > 0 then
                local d = (eh.Position - myHRP.Position).Magnitude
                if d < nearestDist and d <= AimbotRadius then
                    nearestDist = d
                    nearest = eh
                    nearestTorso = torso or eh
                end
            end
        end
    end
    return nearest, nearestDist, nearestTorso
end

local function startBatAimbot()
    if batAimbotConn then return end
    batAimbotConn = RunService.Heartbeat:Connect(function()
        local c = player.Character
        if not c then return end
        local h = c:FindFirstChild("HumanoidRootPart")
        local hum = c:FindFirstChildOfClass("Humanoid")
        if not h or not hum then return end
        
        local bat = findBat()
        if bat and bat.Parent ~= c then
            hum:EquipTool(bat)
        end
        
        local target, dist, torso = findNearestEnemy(h)
        
        if target and torso then
            local Prediction = 0.13
            local PredictedPos = torso.Position + (torso.AssemblyLinearVelocity * Prediction)
            local lookDir = (PredictedPos - h.Position)
            local flatDir = Vector3.new(lookDir.X, 0, lookDir.Z)
            
            if flatDir.Magnitude > 0 then
                hum.AutoRotate = true
            end
            
            local myPos = h.Position
            local dir = (PredictedPos - myPos)
            
            if dir.Magnitude > 1.5 then
                local moveDir = dir.Unit
                local targetVel = moveDir * BatAimbotSpeed
                h.AssemblyLinearVelocity = targetVel
            else
                h.AssemblyLinearVelocity = target.AssemblyLinearVelocity
            end
        end
    end)
end

local function stopBatAimbot()
    if batAimbotConn then
        batAimbotConn:Disconnect()
        batAimbotConn = nil
    end
end

local function updateWalking()
    local char = player.Character
    if not char then return end
    local root = char:FindFirstChild("HumanoidRootPart")
    local hum = char:FindFirstChild("Humanoid")
    if not root or not hum then return end
    local currentVel = root.AssemblyLinearVelocity

    if floating then
        local raycastParams = RaycastParams.new()
        raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
        raycastParams.FilterDescendantsInstances = {char}
        local raycastResult = workspace:Raycast(root.Position, Vector3.new(0, -50, 0), raycastParams)
        if raycastResult then
            local groundY = raycastResult.Position.Y
            local targetY = groundY + 8
            local currentY = root.Position.Y
            local yDifference = targetY - currentY
            if math.abs(yDifference) > 0.3 then
                root.AssemblyLinearVelocity = Vector3.new(
                    currentVel.X,
                    yDifference * 15,
                    currentVel.Z
                )
            else
                root.AssemblyLinearVelocity = Vector3.new(
                    currentVel.X,
                    0,
                    currentVel.Z
                )
            end
        end
    end

    if patrolMode ~= "none" then
        local waypoints = getCurrentWaypoints()
        local targetPos = waypoints[currentWaypoint]
        local currentPos = root.Position
        local targetXZ = Vector3.new(targetPos.X, 0, targetPos.Z)
        local currentXZ = Vector3.new(currentPos.X, 0, currentPos.Z)
        local distanceXZ = (targetXZ - currentXZ).Magnitude
        if distanceXZ > 3 then
            local moveDirection = (targetXZ - currentXZ).Unit
            local currentSpeed = getCurrentSpeed()
            root.AssemblyLinearVelocity = Vector3.new(
                moveDirection.X * currentSpeed,
                root.AssemblyLinearVelocity.Y,
                moveDirection.Z * currentSpeed
            )
        else
            if currentWaypoint == #waypoints then
                patrolMode = "none"
                currentWaypoint = 1
                waitingForCountdownLeft = false
                waitingForCountdownRight = false
                root.AssemblyLinearVelocity = Vector3.new(0, root.AssemblyLinearVelocity.Y, 0)
                print("Path completed")
                if lastTpSide == "left" then
                    print("Restarting Auto Left")
                    task.spawn(function() startMovement("left", buttons["autoleft"]) end)
                elseif lastTpSide == "right" then
                    print("Restarting Auto Right")
                    task.spawn(function() startMovement("right", buttons["autoright"]) end)
                end
            else
                currentWaypoint = currentWaypoint + 1
            end
        end
    end
end

-- ========== GUI HELPER FUNCTIONS ==========
local function MakeDraggable(frame)
    local dragging, dragInput, dragStart, startPos
    frame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = frame.Position
        end
    end)
    frame.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)
    UIS.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
    frame.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
end

local function ApplyStyle(obj)
    obj.BackgroundColor3 = Color3.fromRGB(10, 10, 12)
    obj.BackgroundTransparency = 0.15
   
    local Corner = Instance.new("UICorner", obj)
    Corner.CornerRadius = UDim.new(0, 4)
    local Stroke = Instance.new("UIStroke", obj)
    Stroke.Color = GREEN_ACCENT
    Stroke.Thickness = 2
    Stroke.Transparency = 0.3
   
    task.spawn(function()
        while Stroke and Stroke.Parent do
            for i = 0, 30 do
                if not Stroke.Parent then break end
                Stroke.Transparency = 0.3 - (i * 0.006)
                task.wait(0.03)
            end
            for i = 0, 30 do
                if not Stroke.Parent then break end
                Stroke.Transparency = 0.12 + (i * 0.006)
                task.wait(0.03)
            end
        end
    end)
end

-- ========== MAIN TITLE ==========
local Title = Instance.new("Frame", Lib)
Title.Size = UDim2.new(0, 160, 0, 28)
Title.Position = UDim2.new(0.5, -80, 0.05, 0)
ApplyStyle(Title)
MakeDraggable(Title)

local TText = Instance.new("TextLabel", Title)
TText.Size = UDim2.new(1, 0, 1, 0)
TText.BackgroundTransparency = 1
TText.Text = "HamaHub Duels"
TText.TextColor3 = TEXT_LIGHT_GREEN
TText.Font = Enum.Font.GothamBold
TText.TextSize = 13

-- ========== FUNCTIONAL BUTTONS ==========
local buttonData = {
    {name = "Float", pos = UDim2.new(0.7, 0, 0.3, 0), func = "float"},
    {name = "Bat Aimbot", pos = UDim2.new(0.82, 0, 0.3, 0), func = nil},
    {name = "Auto Left", pos = UDim2.new(0.7, 0, 0.36, 0), func = "autoleft"},
    {name = "Auto Right", pos = UDim2.new(0.82, 0, 0.36, 0), func = "autoright"},
    {name = "TP [Left]", pos = UDim2.new(0.7, 0, 0.42, 0), func = nil},
    {name = "TP [Right]", pos = UDim2.new(0.82, 0, 0.42, 0), func = nil}
}

local buttons = {}
for _, data in pairs(buttonData) do
    local b = Instance.new("TextButton", Lib)
    b.Name = data.name
    b.Size = UDim2.new(0, 140, 0, 30)
    b.Position = data.pos
    b.BackgroundTransparency = 1
    ApplyStyle(b)
    MakeDraggable(b)
   
    local dot = Instance.new("Frame", b)
    dot.Name = "StatusDot"
    dot.Size = UDim2.new(0, 6, 0, 6)
    dot.Position = UDim2.new(0, 8, 0.5, -3)
    dot.BackgroundColor3 = Color3.fromRGB(70, 70, 80)
    Instance.new("UICorner", dot).CornerRadius = UDim.new(1, 0)
   
    local lbl = Instance.new("TextLabel", b)
    lbl.Name = "Label"
    lbl.Size = UDim2.new(1, -40, 1, 0)
    lbl.Position = UDim2.new(0, 24, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = data.name
    lbl.TextColor3 = Color3.new(0.9, 0.9, 0.9)
    lbl.Font = Enum.Font.Gotham
    lbl.TextSize = 12
    lbl.TextXAlignment = Enum.TextXAlignment.Left
   
    local gear = Instance.new("TextLabel", b)
    gear.Text = "⚙"
    gear.Position = UDim2.new(1, -20, 0, 0)
    gear.Size = UDim2.new(0, 20, 1, 0)
    gear.BackgroundTransparency = 1
    gear.TextColor3 = Color3.fromRGB(80, 80, 90)
    gear.TextSize = 14
   
    buttons[data.func or data.name] = b
end

-- Float Button
buttons["float"].MouseButton1Click:Connect(function()
    floating = not floating
    updateButtonState(buttons["float"], floating, "Float [ON]", "Float")
end)

-- Auto Right Button
buttons["autoright"].MouseButton1Click:Connect(function()
    if patrolMode == "right" or waitingForCountdownRight then
        stopMovement(buttons["autoright"], buttons["autoleft"])
    else
        local success, label = pcall(function()
            return player.PlayerGui.DuelsMachineTopFrame.DuelsMachineTopFrame.DuelsMachineTopFrame.Timer.Label
        end)
        if success and label and isTimerInCountdown(label) then
            waitingForCountdownRight = true
            buttons["autoright"]:FindFirstChild("Label").Text = "Waiting..."
            buttons["autoright"]:FindFirstChild("StatusDot").BackgroundColor3 = Color3.fromRGB(255, 200, 50)
        else
            startMovement("right", buttons["autoright"])
        end
    end
end)

-- Auto Left Button
buttons["autoleft"].MouseButton1Click:Connect(function()
    if patrolMode == "left" or waitingForCountdownLeft then
        stopMovement(buttons["autoright"], buttons["autoleft"])
    else
        local success, label = pcall(function()
            return player.PlayerGui.DuelsMachineTopFrame.DuelsMachineTopFrame.DuelsMachineTopFrame.Timer.Label
        end)
        if success and label and isTimerInCountdown(label) then
            waitingForCountdownLeft = true
            buttons["autoleft"]:FindFirstChild("Label").Text = "Waiting..."
            buttons["autoleft"]:FindFirstChild("StatusDot").BackgroundColor3 = Color3.fromRGB(255, 200, 50)
        else
            startMovement("left", buttons["autoleft"])
        end
    end
end)

-- Bat Aimbot Button
buttons["Bat Aimbot"].MouseButton1Click:Connect(function()
    batAimbotActive = not batAimbotActive
    if batAimbotActive then
        updateButtonState(buttons["Bat Aimbot"], true, "Bat Aimbot [ON]", "Bat Aimbot")
        startBatAimbot()
    else
        updateButtonState(buttons["Bat Aimbot"], false, nil, "Bat Aimbot")
        stopBatAimbot()
    end
end)

-- TP [Left] Button
buttons["TP [Left]"].MouseButton1Click:Connect(function()
    ragdollAutoActive = true
    updateButtonState(buttons["TP [Left]"], true, "TP [Left] [ON]", "TP [Left]")
    updateButtonState(buttons["TP [Right]"], false, nil, "TP [Right]")
    startRagdollDetector()
    task.spawn(function()
        doTPLeft()
        task.wait(0.2)
        if patrolMode ~= "left" then
            startMovement("left", buttons["autoleft"])
        end
    end)
end)

-- TP [Right] Button
buttons["TP [Right]"].MouseButton1Click:Connect(function()
    ragdollAutoActive = true
    updateButtonState(buttons["TP [Right]"], true, "TP [Right] [ON]", "TP [Right]")
    updateButtonState(buttons["TP [Left]"], false, nil, "TP [Left]")
    startRagdollDetector()
    task.spawn(function()
        doTPRight()
        task.wait(0.2)
        if patrolMode ~= "right" then
            startMovement("right", buttons["autoright"])
        end
    end)
end)

-- ========== SETTINGS MENU PANEL ==========
local SettingsPanel = Instance.new("Frame", Lib)
SettingsPanel.Size = UDim2.new(0, 240, 0, 360)
SettingsPanel.Position = UDim2.new(0.5, -120, 0.5, -180)
SettingsPanel.Visible = false
ApplyStyle(SettingsPanel)
MakeDraggable(SettingsPanel)

local STitle = Instance.new("TextLabel", SettingsPanel)
STitle.Size = UDim2.new(1, 0, 0, 35)
STitle.BackgroundTransparency = 1
STitle.Text = "SETTINGS"
STitle.TextColor3 = TEXT_LIGHT_GREEN
STitle.Font = Enum.Font.GothamBold
STitle.TextSize = 14

local SContainer = Instance.new("ScrollingFrame", SettingsPanel)
SContainer.Size = UDim2.new(1, -20, 1, -80)
SContainer.Position = UDim2.new(0, 10, 0, 40)
SContainer.BackgroundTransparency = 1
SContainer.ScrollBarThickness = 2
SContainer.CanvasSize = UDim2.new(0, 0, 1.2, 0)

local SLayout = Instance.new("UIListLayout", SContainer)
SLayout.Padding = UDim.new(0, 8)

local settingsItems = {"Anti Fling", "Spin Bot", "Anti Ragdoll", "Auto Steal", "Steal Speed", "Unwalk"}
local settingsToggles = {}

for _, name in pairs(settingsItems) do
    local item = Instance.new("TextButton", SContainer)
    item.Name = name
    item.Size = UDim2.new(1, 0, 0, 35)
    item.Text = ""
    item.AutoButtonColor = false
    ApplyStyle(item)
   
    local dot = Instance.new("Frame", item)
    dot.Name = "StatusDot"
    dot.Size = UDim2.new(0, 8, 0, 8)
    dot.Position = UDim2.new(0, 10, 0.5, -4)
    dot.BackgroundColor3 = Color3.fromRGB(70, 70, 80)
    Instance.new("UICorner", dot).CornerRadius = UDim.new(1, 0)
   
    local label = Instance.new("TextLabel", item)
    label.Name = "Label"
    label.Size = UDim2.new(1, -40, 1, 0)
    label.Position = UDim2.new(0, 30, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = name
    label.TextColor3 = Color3.new(1, 1, 1)
    label.Font = Enum.Font.Gotham
    label.TextSize = 12
    label.TextXAlignment = Enum.TextXAlignment.Left
   
    settingsToggles[name] = item
   
    item.MouseButton1Click:Connect(function()
        local isActive = dot.BackgroundColor3 == GREEN_STATUS
        if name == "Spin Bot" then
            spinActive = not spinActive
            if spinActive then startSpinBot() else stopSpinBot() end
        elseif name == "Anti Ragdoll" then
            antiRagdollActive = not antiRagdollActive
            if antiRagdollActive then startAntiRagdoll() else stopAntiRagdoll() end
        elseif name == "Unwalk" then
            unwalkActive = not unwalkActive
            if unwalkActive then startUnwalk() else stopUnwalk() end
        elseif name == "Steal Speed" then
            stealSpeedActive = not stealSpeedActive
            if stealSpeedActive then startStealSpeed() else stopStealSpeed() end
        elseif name == "Auto Steal" then
            stealActive = not stealActive
            if stealActive then initSteal() end
        end
       
        if isActive then
            item.BackgroundColor3 = Color3.fromRGB(10, 10, 12)
            item.BackgroundTransparency = 0.15
            dot.BackgroundColor3 = Color3.fromRGB(70, 70, 80)
        else
            item.BackgroundColor3 = GREEN_ACCENT
            item.BackgroundTransparency = 0.7
            dot.BackgroundColor3 = GREEN_STATUS
        end
    end)
end

-- ========== SIDE MENU BUTTONS ==========
local tauntActive = false
local tauntLoop = nil
local tauntButtons = {}

local menuBtn = Instance.new("TextButton", Lib)
menuBtn.Size = UDim2.new(0, 80, 0, 30)
menuBtn.Position = UDim2.new(0.05, 0, 0.3, 0)
menuBtn.Text = "MENU"
menuBtn.TextColor3 = Color3.new(1,1,1)
menuBtn.Font = Enum.Font.GothamBold
menuBtn.TextSize = 12
ApplyStyle(menuBtn)
MakeDraggable(menuBtn)
tauntButtons["MENU"] = menuBtn

local tauntBtn = Instance.new("TextButton", Lib)
tauntBtn.Size = UDim2.new(0, 80, 0, 30)
tauntBtn.Position = UDim2.new(0.05, 0, 0.35, 0)
tauntBtn.Text = "TAUNT"
tauntBtn.TextColor3 = Color3.new(1,1,1)
tauntBtn.Font = Enum.Font.GothamBold
tauntBtn.TextSize = 12
ApplyStyle(tauntBtn)
MakeDraggable(tauntBtn)
tauntButtons["TAUNT"] = tauntBtn

-- MENU toggle settings
tauntButtons["MENU"].MouseButton1Click:Connect(function()
    SettingsPanel.Visible = not SettingsPanel.Visible
    if SettingsPanel.Visible then
        tauntButtons["MENU"].BackgroundColor3 = GREEN_ACCENT
        tauntButtons["MENU"].BackgroundTransparency = 0.7
    else
        tauntButtons["MENU"].BackgroundColor3 = Color3.fromRGB(10, 10, 12)
        tauntButtons["MENU"].BackgroundTransparency = 0.15
    end
end)

-- TAUNT spam
tauntButtons["TAUNT"].MouseButton1Click:Connect(function()
    tauntActive = not tauntActive
    if tauntActive then
        tauntButtons["TAUNT"].BackgroundColor3 = GREEN_ACCENT
        tauntButtons["TAUNT"].BackgroundTransparency = 0.7
        tauntLoop = task.spawn(function()
            while tauntActive do
                pcall(function()
                    game:GetService("TextChatService").TextChannels.RBXGeneral:SendAsync("/hamahub on top")
                end)
                pcall(function()
                    game:GetService("ReplicatedStorage").DefaultChatSystemChatEvents.SayMessageRequest:FireServer("/hamahub on top", "All")
                end)
                task.wait(0.5)
            end
        end)
    else
        tauntButtons["TAUNT"].BackgroundColor3 = Color3.fromRGB(10, 10, 12)
        tauntButtons["TAUNT"].BackgroundTransparency = 0.15
        if tauntLoop then task.cancel(tauntLoop) tauntLoop = nil end
    end
end)

-- ========== HEARTBEAT & CLEANUP ==========
heartbeatConn = RunService.Heartbeat:Connect(updateWalking)

player.CharacterAdded:Connect(function()
    task.wait(1)
    patrolMode = "none"
    currentWaypoint = 1
    waitingForCountdownLeft = false
    waitingForCountdownRight = false
    floating = false
    batAimbotActive = false
    updateButtonState(buttons["float"], false, nil, "Float")
    updateButtonState(buttons["Bat Aimbot"], false, nil, "Bat Aimbot")
    updateButtonState(buttons["autoleft"], false, nil, "Auto Left")
    updateButtonState(buttons["autoright"], false, nil, "Auto Right")
    updateButtonState(buttons["TP [Left]"], false, nil, "TP [Left]")
    updateButtonState(buttons["TP [Right]"], false, nil, "TP [Right]")
    stopBatAimbot()
    if antiRagdollActive then startAntiRagdoll() end
    if unwalkActive then startUnwalk() end
    if stealSpeedActive then startStealSpeed() end
    if spinActive then startSpinBot() end
end)

-- Countdown detection (vereinfacht)
task.spawn(function()
    local label
    local success = pcall(function()
        label = player.PlayerGui.DuelsMachineTopFrame.DuelsMachineTopFrame.DuelsMachineTopFrame.Timer.Label
    end)
    if success and label then
        label:GetPropertyChangedSignal("Text"):Connect(function()
            local ok, num = isCountdownNumber(label.Text)
            if ok and num == 1 then
                task.wait(AUTO_START_DELAY)
                if waitingForCountdownLeft then
                    waitingForCountdownLeft = false
                    startMovement("left", buttons["autoleft"])
                end
                if waitingForCountdownRight then
                    waitingForCountdownRight = false
                    startMovement("right", buttons["autoright"])
                end
            end
        end)
    end
end)

Lib.Destroying:Connect(function()
    if heartbeatConn then heartbeatConn:Disconnect() end
end)

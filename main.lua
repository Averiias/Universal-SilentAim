local Config = {
    Enabled = false,
    TeamCheck = false,
    HitPart = "",
    Method = ""
}

local Camera = workspace.CurrentCamera
local Players = game:GetService("Players")

local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()

local GetChildren = game.GetChildren
local WorldToScreen = Camera.WorldToScreenPoint
local FindFirstChild = game.FindFirstChild

local function getPositionOnScreen(Vector)
    local Vec3, OnScreen = WorldToScreen(Camera, Vector)
    return Vector2.new(Vec3.X, Vec3.Y), OnScreen
end

local function getDirection(Origin, Position)
    return (Position - Origin).Unit * 1000
end

local function getMousePosition()
    return Vector2.new(Mouse.X, Mouse.Y)
end

local function getClosestPlayer()
    if not Config.HitPart then return end
    local Closest
    local DistanceToMouse
    for _, Player in next, GetChildren(Players) do
        if Player == LocalPlayer then continue end
        if Config.TeamCheck and Player.Team == LocalPlayer.Team then continue end

        local Character = Player.Character

        if not Character then continue end

        local HumanoidRootPart = FindFirstChild(Character, "HumanoidRootPart")
        local Humanoid = FindFirstChild(Character, "Humanoid")

        if not HumanoidRootPart or not Humanoid or Humanoid and Humanoid.Health <= 0 then continue end

        local ScreenPosition, OnScreen = getPositionOnScreen(HumanoidRootPart.Position)

        if not OnScreen then continue end

        local Distance = (getMousePosition() - ScreenPosition).Magnitude
        if Distance <= (DistanceToMouse or 2000) then
            Closest = Character[Config.HitPart]
            DistanceToMouse = Distance
        end
    end
    return Closest
end

local oldNamecall
oldNamecall = hookmetamethod(game, "__namecall", function(T, ...)
    local Method = getnamecallmethod()
    if Config.Enabled then
        if Method == "FindPartOnRayWithIgnoreList" and Config.Method == Method then
            local Arguments = {...}
            local A_Ray = Arguments[1]
            local A_IgnoreTable = Arguments[2]
            local A_Cubes = Arguments[3]
            local A_IgnoreWater = Arguments[4]

            local HitPart = getClosestPlayer()
            if HitPart then
                local Origin = A_Ray.Origin
                local Direction = getDirection(Origin, HitPart.Position)
                return oldNamecall(
                    T,
                    Ray.new(Origin, Direction),
                    A_IgnoreTable,
                    A_Cubes,
                    A_IgnoreWater
                )
            end
        elseif Method == "FindPartOnRayWithWhitelist" and Config.Method == Method then
            local Arguments = {...}
            local A_Ray = Arguments[1]
            local A_WhitelistTable = Arguments[2]
            local A_IgnoreWater = Arguments[3]

            local HitPart = getClosestPlayer()
            if HitPart then
                local Origin = A_Ray.Origin
                local Direction = getDirection(Origin, HitPart.Position)
                return oldNamecall(
                    T,
                    Ray.new(Origin, Direction),
                    A_WhitelistTable,
                    A_IgnoreWater
                )
            end
        elseif (Method == "FindPartOnRay" or Method == "findPartOnRay") and Config.Method:lower() == Method:lower() then
            local Arguments = {...}
            local A_Ray = Arguments[1]
            local A_IgnoreInstance = Arguments[2]
            local A_Cubes = Arguments[3]
            local A_IgnoreWater = Arguments[4]

            local HitPart = getClosestPlayer()
            if HitPart then
                local Origin = A_Ray.Origin
                local Direction = getDirection(Origin, HitPart.Position)
                return oldNamecall(
                    T,
                    Ray.new(Origin, Direction),
                    A_IgnoreInstance,
                    A_Cubes,
                    A_IgnoreWater
                )
            end
        elseif Method == "Raycast" and Config.Method == Method then
            local Arguments = {...}
            local A_Origin = Arguments[1]
            local A_Direction = Arguments[2]
            local A_RaycastParams = Arguments[3]

            local HitPart = getClosestPlayer()
            if HitPart then
                return oldNamecall(
                    T,
                    A_Origin,
                    getDirection(A_Origin, HitPart.Position),
                    A_RaycastParams
                )
            end
        end
    end
    return oldNamecall(T, ...)
end)

do
    loadstring(game:HttpGet("https://raw.githubusercontent.com/Averiias/purple-haze-pf/main/ui/lib.lua"))()

    local Window = library:CreateWindow({
        WindowName = "Universal Silent Aim by Averias",
        Color = Color3.fromRGB(255, 44, 220)
    }, game:GetService("CoreGui"))

    local GeneralTab = Window:CreateTab("General")
    local MainSector = GeneralTab:CreateSection("Main")
    MainSector:CreateToggle("Enabled", false, function(State)
        Config.Enabled = State
    end)
    MainSector:CreateToggle("Team Check", false, function(State)
        Config.TeamCheck = State
    end)
    MainSector:CreateDropdown("Hit Part", {
        "Head", "HumanoidRootPart"
    }, function(State)
        Config.HitPart = State
    end)
    MainSector:CreateDropdown("Method", {
        "Raycast","FindPartOnRay",
        "FindPartOnRayWithWhitelist",
        "FindPartOnRayWithIgnoreList"
    }, function(State)
        Config.Method = State
    end)
end

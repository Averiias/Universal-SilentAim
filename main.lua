local Config = {
    Enabled = false,
    TeamCheck = false,
    HitPart = "",
    Method = "",
    FieldOfView = {
        Enabled = false,
        Radius = 180
    }
}

local ExpectedArguments = {
    FindPartOnRayWithIgnoreList = {
        ArgCountRequired = 3,
        Args = {
            "Instance", "Ray", "table", "boolean", "boolean"
        }
    },
    FindPartOnRayWithWhitelist = {
        ArgCountRequired = 3,
        Args = {
            "Instance", "Ray", "table", "boolean"
        }
    },
    FindPartOnRay = {
        ArgCountRequired = 2,
        Args = {
            "Instance", "Ray", "Instance", "boolean", "boolean"
        }
    },
    Raycast = {
        ArgCountRequired = 3,
        Args = {
            "Instance", "Vector3", "Vector3", "RaycastParams"
        }
    }
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

local function ValidateArguments(Args, RayMethod)
    local Matches = 0
    if #Args < RayMethod.ArgCountRequired then
        return false
    end
    for Pos, Argument in next, Args do
        if typeof(Argument) == RayMethod.Args[Pos] then
            Matches = Matches + 1
        end
    end
    return Matches >= RayMethod.ArgCountRequired
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
        if Distance <= (DistanceToMouse or (Config.FieldOfView.Enabled and Config.FieldOfView.Radius) or 2000) then
            Closest = Character[Config.HitPart]
            DistanceToMouse = Distance
        end
    end
    return Closest
end

local oldNamecall
oldNamecall = hookmetamethod(game, "__namecall", function(...)
    local Method = getnamecallmethod()
    local Arguments = {...}
    local self = Arguments[1]

    if Config.Enabled and self == workspace then
        if Method == "FindPartOnRayWithIgnoreList" and Config.Method == Method then
            if ValidateArguments(Arguments, ExpectedArguments.FindPartOnRayWithIgnoreList) then
                local A_Ray = Arguments[2]

                local HitPart = getClosestPlayer()
                if HitPart then
                    local Origin = A_Ray.Origin
                    local Direction = getDirection(Origin, HitPart.Position)
                    Arguments[2] = Ray.new(Origin, Direction)

                    return oldNamecall(unpack(Arguments))
                end
            end
        elseif Method == "FindPartOnRayWithWhitelist" and Config.Method == Method then
            if ValidateArguments(Arguments, ExpectedArguments.FindPartOnRayWithWhitelist) then
                local A_Ray = Arguments[2]

                local HitPart = getClosestPlayer()
                if HitPart then
                    local Origin = A_Ray.Origin
                    local Direction = getDirection(Origin, HitPart.Position)
                    Arguments[2] = Ray.new(Origin, Direction)

                    return oldNamecall(unpack(Arguments))
                end
            end
        elseif (Method == "FindPartOnRay" or Method == "findPartOnRay") and Config.Method:lower() == Method:lower() then
            if ValidateArguments(Arguments, ExpectedArguments.FindPartOnRay) then
                local A_Ray = Arguments[2]

                local HitPart = getClosestPlayer()
                if HitPart then
                    local Origin = A_Ray.Origin
                    local Direction = getDirection(Origin, HitPart.Position)
                    Arguments[2] = Ray.new(Origin, Direction)

                    return oldNamecall(unpack(Arguments))
                end
            end
        elseif Method == "Raycast" and Config.Method == Method then
            if ValidateArguments(Arguments, ExpectedArguments.Raycast) then
                local A_Origin = Arguments[2]

                local HitPart = getClosestPlayer()
                if HitPart then
                    Arguments[3] = getDirection(A_Origin, HitPart.Position)

                    return oldNamecall(unpack(Arguments))
                end
            end
        end
    end
    return oldNamecall(...)
end)

do
    loadstring(game:HttpGet("https://raw.githubusercontent.com/Averiias/purple-haze-pf/main/ui/lib.lua"))()

    local fov_circle = Drawing.new("Circle")
    fov_circle.Thickness = 1
    fov_circle.NumSides = 100
    fov_circle.Radius = 180
    fov_circle.Filled = false
    fov_circle.Visible = false
    fov_circle.ZIndex = 999
    fov_circle.Transparency = 1
    fov_circle.Color = Color3.fromRGB(255, 44, 220)

    task.spawn(function()
        while true do
            fov_circle.Position = getMousePosition() + Vector2.new(0, 36)
            task.wait()
        end
    end)

    local Window = library:CreateWindow({
        WindowName = "Universal Silent Aim by Averias",
        Color = Color3.fromRGB(255, 44, 220)
    }, game:GetService("CoreGui"))

    local GeneralTab = Window:CreateTab("General")
    local MainSector = GeneralTab:CreateSection("Main")
    local FieldOfViewSector = GeneralTab:CreateSection("Field Of View")
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
    FieldOfViewSector:CreateToggle("Enabled", false, function(State)
        Config.FieldOfView.Enabled = State
    end)
    FieldOfViewSector:CreateSlider("Radius", 0, 360, 180, true, function(State)
        Config.FieldOfView.Radius = State
        fov_circle.Radius = State
    end)
    FieldOfViewSector:CreateToggle("Visible", false, function(State)
        fov_circle.Visible = State
    end)
    FieldOfViewSector:CreateColorpicker("Color", function(State)
        fov_circle.Color = State
    end):UpdateColor(Color3.fromRGB(255, 44, 220))
end

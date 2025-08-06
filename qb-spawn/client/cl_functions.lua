local Weather_Hashes = {
    [916995460] = Config.Locale['Clear'],
    [-1750463879] = Config.Locale['Extra Sunny'],
    [821931868] = Config.Locale['Clouds'],
    [-1368164796] = Config.Locale['Fog'],
    [-1148613331] = Config.Locale['Overcast'],
    [1420204096] = Config.Locale['Rain'],
    [-1233681761] = Config.Locale['Thunder'],
    [-273223690] = Config.Locale['Snow'],
    [669657108] = Config.Locale['Blizzard'],
    [-1429616491] = Config.Locale['Christmas'],
    [-921030142] = Config.Locale['Halloween'],
}

local Weather_Degrees = {
    [Config.Locale['Clear']] = '15°C',
    [Config.Locale['Extra Sunny']] = '25°C',
    [Config.Locale['Clouds']] = '18°C',
    [Config.Locale['Fog']] = '10°C',
    [Config.Locale['Overcast']] = '16°C',
    [Config.Locale['Rain']] = '14°C',
    [Config.Locale['Thunder']] = '22°C',
    [Config.Locale['Snow']] = '-5°C',
    [Config.Locale['Blizzard']] = '-10°C',
    [Config.Locale['Christmas']] = '0°C',
    [Config.Locale['Halloween']] = '8°C',
}

local Days = {
    [0] = Config.Locale['Sunday'],
    [1] = Config.Locale['Monday'],
    [2] = Config.Locale['Tuesday'],
    [3] = Config.Locale['Wednesday'],
    [4] = Config.Locale['Thursday'],
    [5] = Config.Locale['Friday'],
    [6] = Config.Locale['Saturday'],
}

Get_Weather = function()
    local weather_hash = GetPrevWeatherTypeHashName()
    local weather_name = Weather_Hashes[weather_hash]
    return weather_name
end

Get_Degree = function()
    local weather_hash = GetPrevWeatherTypeHashName()
    local weather_name = Weather_Hashes[weather_hash]
    local degree = Weather_Degrees[weather_name]
    return degree
end

Get_Day = function()
    local day_id = GetClockDayOfWeek()
    local day_name = Days[day_id]
    return day_name
end

local Camera = nil
local Camera_Ofs = nil

Set_Camera = function(Type, Data)
    local ply_ped = PlayerPedId()
    if Type == "First" then
        if not DoesCamExist(Camera) then
            Camera = CreateCam('DEFAULT_SCRIPTED_CAMERA', true)
        end
        SetEntityCoords(ply_ped, Config.Spawns[1].Spawn_Coords.x, Config.Spawns[1].Spawn_Coords.y, Config.Spawns[1].Spawn_Coords.z, true, false, false, false)
        SetCamCoord(Camera, Config.Spawns[1].Cam_Coords.x, Config.Spawns[1].Cam_Coords.y, Config.Spawns[1].Cam_Coords.z)
        PointCamAtCoord(Camera, Config.Spawns[1].Spawn_Coords.x, Config.Spawns[1].Spawn_Coords.y, Config.Spawns[1].Spawn_Coords.z)
        SetCamActive(Camera, true)
        RenderScriptCams(true, true, 500, true, true)
    elseif Type == "New" then
        DoScreenFadeOut(500)
        Wait(500)
        SetEntityCoords(ply_ped, Config.Spawns[Data.Selected].Spawn_Coords.x, Config.Spawns[Data.Selected].Spawn_Coords.y, Config.Spawns[Data.Selected].Spawn_Coords.z, true, false, false, false)
        SetCamCoord(Camera, Config.Spawns[Data.Selected].Cam_Coords.x, Config.Spawns[Data.Selected].Cam_Coords.y, Config.Spawns[Data.Selected].Cam_Coords.z)
        PointCamAtCoord(Camera, Config.Spawns[Data.Selected].Spawn_Coords.x, Config.Spawns[Data.Selected].Spawn_Coords.y, Config.Spawns[Data.Selected].Spawn_Coords.z)
        Wait(500)
        DoScreenFadeIn(500)
    end
end

Destroy_Camera = function()
    SetCamActive(Camera, false) Camera = nil
    RenderScriptCams(false, true, 2500, true, true)
end

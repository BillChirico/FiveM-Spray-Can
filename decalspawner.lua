CreateThread = Citizen.CreateThread
Decal, DuiObj = nil, nil
PRPUtils = {}

-----------------------------------------------------------------------------------------
--------------------------------------- COMMAND -----------------------------------------
-----------------------------------------------------------------------------------------

RegisterCommand('spawndecal', function (src, args, rawInput)
    if Decal then
        RemoveDecal(Decal)
    end

    local decaltype = tonumber(args[1]) or 1030
    local raycast = PRPUtils.RayLook()

    local isurface = vector3(-raycast.surface.x, -raycast.surface.y, -raycast.surface.z)
    local n = math.sqrt(isurface.x * isurface.x + isurface.y * isurface.y + isurface.z * isurface.z)
    if n > 1e-5 then
        isurface = vector3(isurface.x/n, isurface.y/n, isurface.z/n)
    else
		isurface = vector3(0,0,0)
	end

    local sol = DecalRotationInput(-raycast.surface, 0.0)

    --DrawLineForWhile(d)
    RequestStreamedTextureDict("MPOnMissMarkers")
    Decal = AddDecal(
        decaltype,
        raycast.pos.x, raycast.pos.y, raycast.pos.z, -- pos
        isurface.x, isurface.y, isurface.z,
        sol.x, sol.y, sol.z,
        1.0, 1.0, --width, height
        1.0, 1.0, 1.0,    -- rgb
        1.0, -1.0,    -- opacity,timeout
        0, 0, 0 -- unk
    )
    --PatchDecalDiffuseMap(decaltype, "MPOnMissMarkers", "Capture_The_Flag_Base_Icon")
end, false)

-----------------------------------------------------------------------------------------
----------------------------------------- UTILS -----------------------------------------
-----------------------------------------------------------------------------------------
---@param deg number
---@return number dir converts rotation degree to direction
PRPUtils.RotationToDirection = function(deg)
  local radx = deg.x * 0.0174532924
  local radz = deg.z * 0.0174532924

  local dirx = -math.sin(radz) * math.cos(radx)
  local diry = math.cos(radz) * math.cos(radx)
  local dirz = math.sin(radx)
  local dir = vector3(dirx, diry, dirz)
  return dir
end


---@param dist number
---@return table rayresult
PRPUtils.RayLook = function(dist)
    if not dist then
        dist = 10.0
    end
    local ped = PlayerPedId()
    local pedhead = GetPedBoneCoords(ped, 31086)
    local direction = PRPUtils.RotationToDirection(GetGameplayCamRot(0))
    local target = pedhead + (direction * dist)

    local r, _, _ = StartShapeTestSweptSphere(pedhead, target, 0.25, 1, ped, 5)
    local result, fhit, fpos, fsurface, fentity = 1
    repeat
      Wait(0)
      result, fhit, fpos, fsurface, fentity = GetShapeTestResult(r)
    until result ~= 1

    r, _, _ = StartShapeTestSweptSphere(pedhead, target, 0.25, 30, ped, 0)
    result = 1
    local hit, pos, surface, entity = 1
    repeat
      Wait(0)
      result, hit, pos, surface, entity = GetShapeTestResult(r)
    until result ~= 1

    if not entity or entity == 0 then
      pos = fpos
      surface = fsurface
    end

    if hitCoords == vector3(0, 0, 0) then
        return
    end

    local result = {
      result = result,
      hit = hit,
      pos = pos,
      surface = surface,
      entity = entity,
      hidden = not (fentity and (fentity == entity))
    }

    if modelhash and model and entity and (entity ~= 0) and (GetEntityModel(entity) ~= modelhash) then
        return
    end

    if modelhash and ((not entity) or (entity == 0)) then
        return
    end

    return result
end

function DrawLineForWhile(pos)
    CreateThread(function()
        i = 0
        repeat
            Wait(0)
            i = i + 1
            DrawMarker(2, pos, 0.0, 0.0, 0.0, 0.0, 180.0, 0.0, 0.1, 0.1, 0.1, 255, 128, 0, 50, false, true, 2, nil, nil, false)
        until i == 500
    end)
end

-----------------------------------------------------------------------------------------
--------------------------------------- DECAL MATH --------------------------------------
-----------------------------------------------------------------------------------------

local function div(s, d)
    s = {x = s.x, y = s.y, z = s.z, w = s.w}
    s.x = s.x / d
    s.y = s.y / d
    s.z = s.z / d
    return s
end

local function setNormalize(s)
    local num = math.sqrt(s.x * s.x + s.y * s.y + s.z * s.z)
    if num == 1 then
        return s
    elseif num > 1e-5 then
        s = div(s, num)
    else
        s = vector3(0,0,0)
    end
    return s
end

local function angleAxis(axis, angle)
	local normaxis = setNormalize(axis)
    local halfdegtorad = 0.5 * (math.pi/180)

    angle = angle * halfdegtorad
    local s = math.sin(angle)

    local w = math.cos(angle)
    local x = normaxis.x * s
    local y = normaxis.y * s
    local z = normaxis.z * s
	return {x = x, y = y, z = z, w = w}
end

local function project(vector, onNormal)
    local num = onNormal.x * onNormal.x + onNormal.y * onNormal.y + onNormal.z * onNormal.z
    if num < 1.175494e-38 then
        return {x = 0, y = 0, z = 0}
    end
    local num2 = (((vector.x * onNormal.x) + (vector.y * onNormal.y)) + (vector.z * onNormal.z))

    local onNormal = {x = onNormal.x, y = onNormal.y, z = onNormal.z, w = onNormal.w}

    onNormal.x = onNormal.x * num2/num
    onNormal.y = onNormal.y * num2/num
    onNormal.z = onNormal.z * num2/num
    return onNormal
end

local function projectOnPlane(vector, planeNormal)
	local v3 = project(vector, planeNormal)
    v3.x = v3.x * -1
    v3.y = v3.y * -1
    v3.z = v3.z * -1

    v3.x = v3.x + vector.x
    v3.y = v3.y + vector.y
    v3.z = v3.z + vector.z
	return v3
end

local function quaternionMulVec3(se, point)
	local vec = {}

	local num 	= se.x * 2
	local num2 	= se.y * 2
	local num3 	= se.z * 2
	local num4 	= se.x * num
	local num5 	= se.y * num2
	local num6 	= se.z * num3
	local num7 	= se.x * num2
	local num8 	= se.x * num3
	local num9 	= se.y * num3
	local num10 = se.w * num
	local num11 = se.w * num2
	local num12 = se.w * num3

	vec.x = (((1 - (num5 + num6)) * point.x) + ((num7 - num12) * point.y)) + ((num8 + num11) * point.z)
	vec.y = (((num7 + num12) * point.x) + ((1 - (num4 + num6)) * point.y)) + ((num9 - num10) * point.z)
	vec.z = (((num8 - num11) * point.x) + ((num9 + num10) * point.y)) + ((1 - (num4 + num5)) * point.z)

	return vec
end

function DecalRotationInput(direction, rotation)
    local rad = (math.pi/180)*rotation
    local q = angleAxis(direction, rad)
    local p = projectOnPlane({x = 0.0, y = 1.0, z = 0.0}, direction)
    local num = math.sqrt(p.x * p.x + p.y * p.y + p.z * p.z)

	if num == 1 then
    elseif num > 1e-5 then
        p.x = p.x / num
    	p.y = p.y / num
    	p.z = p.z / num
    else
		p = {x = 0, y = 0, z = 0}
	end

    return quaternionMulVec3(q, p)
end

-----------------------------------------------------------------------------------------
------------------------------------------- DUI -----------------------------------------
-----------------------------------------------------------------------------------------

--ofc dont use this in prod

local function loadDui()
    local txd = CreateRuntimeTxd('duitxd')
    DuiObj = CreateDui('https://cdn.discordapp.com/icons/441748984604917790/a_f21f693129be0d278621a86c8c6ebad5.gif', 128, 128)
    local dui = GetDuiHandle(DuiObj)
    local tx = CreateRuntimeTextureFromDuiHandle(txd, 'duitex', dui)
    Wait(500)  
    AddReplaceTexture("MPOnMissMarkers", "Capture_The_Flag_Base_Icon", 'duitxd', 'duitex')
end

CreateThread(function()
    Wait(500)
    loadDui()
end)



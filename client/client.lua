local glm = require("glm")

--- Registers a command 'spray' that opens the SprayUI.
--- When the 'spray' command is executed, it sends a message to the NUI to show the UI
--- and sets the NUI focus to true to enable user input.
RegisterCommand('spray', function(source, args, rawInput)
    SendNUIMessage({ showUI = true })

    SetNuiFocus(true, true);
end, false)

--- Handles the 'spray-selected' event from the NUI.
--- When the 'spray-selected' event is received from the NUI, this callback function is invoked.
--- It toggles the `showUI` flag to hide the UI, sends a message to the NUI to hide the UI,
--- sets the NUI focus to false to disable user input, and calls the `spawnSpray` function
--- with the selected spray data.
RegisterNUICallback('spray-selected', function(data, cb)
    SendNUIMessage({ showUI = false })

    SetNuiFocus(false, false);

    spawnSpray(data.spray);

    cb('spray-selected')
end)

--- Handles the 'close' event from the NUI.
--- When the 'close' event is received from the NUI, this callback function is invoked.
--- It toggles the `showUI` flag to hide the UI, sends a message to the NUI to hide the UI,
--- and sets the NUI focus to false to disable user input.
RegisterNUICallback('close', function(data, cb)
    SendNUIMessage({ showUI = false })

    SetNuiFocus(false, false);

    cb('close')
end)

--- Registers a keybinding for the 'spray' command, which opens the SprayUI.
--- The keybinding is set to the 'G' by default.
RegisterKeyMapping('spray', 'Opens the  SprayUI', 'keyboard', 'G')

--- Performs a raycast from the gameplay camera to a specified distance and returns the hit information.
function RayCastGameplayCamera(distance)
    local cameraRotation = GetGameplayCamRot(2)

    local cameraCoord = GetGameplayCamCoord()

    local direction = RotationToDirection(cameraRotation)

    local destination =
    {
        x = cameraCoord.x + direction.x * distance,
        y = cameraCoord.y + direction.y * distance,
        z = cameraCoord.z + direction.z * distance
    }

    local a, b, c, d, e = GetShapeTestResult(StartShapeTestRay(cameraCoord.x, cameraCoord.y, cameraCoord.z, destination
        .x, destination.y, destination.z, 1, PlayerPedId(), 4))

    return b, c, d, e
end

--- Converts a rotation vector to a direction vector.
---
--- @param rotation table The rotation vector to convert.
--- @return vector3 The direction vector.
function RotationToDirection(rotation)
    local retz = math.rad(rotation.z)
    local retx = math.rad(rotation.x)

    local absx = math.abs(math.cos(retx))

    return vector3(-math.sin(retz) * absx, math.cos(retz) * absx, math.sin(retx))
end

--- Converts a rotation vector to a direction vector.
---
--- @param rotation table The rotation vector to convert.
--- @return vector3 The direction vector.
function RotationToDirection(rotation)
    local retz = math.rad(rotation.z)
    local retx = math.rad(rotation.x)

    local absx = math.abs(math.cos(retx))

    return vector3(-math.sin(retz) * absx, math.cos(retz) * absx, math.sin(retx))
end

--- Spawns a spray decal on the game world at the location the player is aiming at.
---
--- @param texture The texture to use for the spray decal.
function spawnSpray(texture)
    local decal = 10030
    local txd = "spray-can-decals"
    local scale = vector2(0.5, 0.5)
    local decalTimeout = -1.0

    RequestStreamedTextureDict(txd, false)
    local hit, pos, normal, entity = RayCastGameplayCamera(100)
    pos = pos + normal * 0.0666

    local res = GetTextureResolution(txd, texture)
    local textureSize = vector2(scale.x * (res.x / res.y), scale.y)
    local decalEPS = 1E-2
    local decalForward = -normal
    local decalRight = glm.perpendicular(normal, -glm.up(), glm.right())

    local dot_up = glm.dot(normal, glm.up())
    if glm.approx(glm.abs(dot_up), 1.0, decalEPS) then
        local camRot = GetGameplayCamRot(2)
        decalRight = quat(camRot.z, glm.up()) * glm.right()
    end

    PatchDecalDiffuseMap(decal, txd, texture)
    AddDecal(decal,
        pos.x, pos.y, pos.z,
        decalForward.x, decalForward.y, decalForward.z,
        decalRight.x, decalRight.y, decalRight.z,
        textureSize.x, textureSize.y,
        1.0, 1.0, 1.0, 1.0,
        decalTimeout, true, false, false
    )
end

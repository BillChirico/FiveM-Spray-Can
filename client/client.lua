local isDisplayed = false

--- Toggles the display of the SprayUI and sets the NUI focus.
--- When the 'spray' command is executed, this function is called.
--- It toggles the `isDisplayed` flag to show or hide the UI, sends a message to the NUI to update the UI visibility,
--- and sets the NUI focus to true to enable user input.
RegisterCommand('spray', function(source, args, rawInput)
    isDisplayed = not isDisplayed

    SendNUIMessage({ showUI = isDisplayed })

    SetNuiFocus(true, true);
end, false)

--- Handles the 'spray-selected' event from the NUI.
--- When the 'spray-selected' event is received from the NUI, this callback function is invoked.
--- It toggles the `isDisplayed` flag to hide the UI, sends a message to the NUI to hide the UI,
--- and sets the NUI focus to false to disable user input.
--- Finally, it calls the provided callback function with the string 'wooo2'.
RegisterNUICallback('spray-selected', function(data, cb)
    isDisplayed = not isDisplayed

    SendNUIMessage({ showUI = isDisplayed })

    SetNuiFocus(false, false);

    cb('spray-selected')
end)

--- Handles the closing of the SprayUI.
--- When the 'close' event is received from the NUI, this callback function is invoked.
--- It toggles the `isDisplayed` flag to hide the UI, sends a message to the NUI to hide the UI,
--- and sets the NUI focus to false to disable user input.
--- Finally, it calls the provided callback function with the string 'close'.
RegisterNUICallback('close', function(data, cb)
    isDisplayed = not isDisplayed

    SendNUIMessage({ showUI = isDisplayed })

    SetNuiFocus(false, false);

    cb('close')
end)

RegisterKeyMapping('spray', 'Opens the  SprayUI', 'keyboard', 'G')

local function spawnSpray(texture)
    local decal = 10030
    local txd = "custom_decals"
    local tx = "smile"
    local scale = vector2(0.5, 0.5)
    local decalTimeout = -1.0

    RequestStreamedTextureDict(txd, false)
    local hit, pos, normal, entity = RayCastGameplayCamera(100)
    pos = pos + normal * 0.0666

    local res = GetTextureResolution(txd, tx)
    local textureSize = vector2(scale.x * (res.x / res.y), scale.y)
    local decalEPS = 1E-2
    local decalForward = -normal
    local decalRight = glm.perpendicular(normal, -glm.up(), glm.right())

    local dot_up = glm.dot(normal, glm.up())
    if glm.approx(glm.abs(dot_up), 1.0, decalEPS) then
        local camRot = GetGameplayCamRot(2)
        decalRight = quat(camRot.z, glm.up()) * glm.right()
    end

    PatchDecalDiffuseMap(decal, txd, tx)
    AddDecal(decal,
        pos.x, pos.y, pos.z,
        decalForward.x, decalForward.y, decalForward.z,
        decalRight.x, decalRight.y, decalRight.z,
        textureSize.x, textureSize.y,
        1.0, 1.0, 1.0, 1.0,
        decalTimeout, true, false, false
    )
end

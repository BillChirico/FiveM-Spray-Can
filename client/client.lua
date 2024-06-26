local isDisplayed = false

RegisterCommand('spray', function(source, args, rawInput)
    isDisplayed = not isDisplayed

    SendNUIMessage({ showUI = isDisplayed })

    SetNuiFocus(true, true);
end, false)

RegisterNUICallback('spray', function(data, cb)
    -- Actually spawn the decal
    print("wooo1")

    SetNuiFocus(false, false);

    cb('wooo2')
end)

RegisterKeyMapping('spray', 'Opens the  SprayUI', 'keyboard', 'G')

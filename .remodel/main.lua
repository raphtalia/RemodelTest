--# selene: allow(undefined_variable)

local function reconcile(dataModel1, dataModel2)
    for _,service1 in ipairs(dataModel1:GetChildren()) do
        local service2 = dataModel2[service1.Name]

        for _,child in ipairs(service2:GetChildren()) do
            if not service1:FindFirstChild(child.Name) then
                child.Parent = service1
            end
        end
    end
end

return function(branchName, commitSHA, assetId, ...)
    local placeFiles = {...}
    local dataModels = {}

    -- Read the place files into DataModels
    for i, placeFile in ipairs(placeFiles) do
        dataModels[i] = remodel.readPlaceFile(placeFile)
    end

    -- Reconcile all the DataModels in order of arguments
    repeat
        reconcile(table.remove(dataModels, -1), dataModels[#dataModels])
    until #dataModels == 1

    local dataModel = dataModels[1]

    -- Add commit metadata to the DataModel
    local metadata = Instance.new("ModuleScript")
    metadata.Name = "Github"
    metadata.Source = [[
        return {
            Branch = "]] .. branchName .. [[",
            Commit = "]] .. commitSHA .. [[",
        }
    ]]
    metadata.Parent = dataModel

    -- Publish the DataModel to Roblox
    remodel.writeExistingPlaceAsset(dataModel, assetId)
end
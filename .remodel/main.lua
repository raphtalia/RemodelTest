local success, config = pcall(function()
    return json.fromString(remodel.readFile("deployment.json"))
end)
if not success then
    error("Could not read deployment.json: " .. config)
end

local args = {...}
local branchName = args[1]
local commitSHA = args[2]
local assetId = config.target
local dataModels = {}

if #config.files > 0 then
    -- Read the place files into DataModels
    for i, fileParams in ipairs(config.files) do
        local path = fileParams.path
        if remodel.isFile(path) and path:sub(-5) == ".rbxl" then
            table.insert(dataModels, remodel.readPlaceFile(path))
        elseif remodel.isDir(path) then
            local outputPath = i.. ".rbxl"
            os.execute(("rojo build --output %s %s"):format(outputPath, path))
            table.insert(dataModels, remodel.readPlaceFile(outputPath))
        end
    end
else
    error("Expected 1 or more file paths")
end

local function reconcile(dataModel1, dataModel2)
    -- Transfer services if DataModel1 is missing services that DataModel2 has
    for _,service in ipairs(dataModel2:GetChildren()) do
        if not dataModel1:FindFirstChildOfClass(service.ClassName) then
            service.Parent = dataModel1
        end
    end

    for _,service1 in ipairs(dataModel1:GetChildren()) do
        local service2 = dataModel2:FindFirstChildOfClass(service1.ClassName)

        if service2 then
            for _,child in ipairs(service2:GetChildren()) do
                if not service1:FindFirstChild(child.Name) then
                    child.Parent = service1
                end
            end
        end
    end
end

-- Reconcile all the DataModels in order of arguments
while #dataModels > 1 do
    reconcile(dataModels[#dataModels - 1], table.remove(dataModels, #dataModels))
end

local dataModel = dataModels[1]

-- Add commit metadata to the DataModel
local metadata = Instance.new("ModuleScript")
metadata.Name = "Github"
remodel.setRawProperty(
    metadata,
    "Source",
    "String",
    [[
        return {
            Branch = "]] .. branchName .. [[",
            Commit = "]] .. commitSHA .. [[",
        }
    ]]
)
metadata.Parent = dataModel

-- Publish the DataModel to Roblox
remodel.writeExistingPlaceAsset(dataModel, assetId)
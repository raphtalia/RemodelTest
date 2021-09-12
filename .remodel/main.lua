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

local function findFirstChildOfClassAndName(parent, className, name)
    for _, child in ipairs(parent:GetChildren()) do
        if child.ClassName == className and child.Name == name then
            return child
        end
    end
end

local function reconcileChildren(parent1, parent2)
    for _,child2 in ipairs(parent2:GetChildren()) do
        local child1 = findFirstChildOfClassAndName(parent1, child2.ClassName, child2.Name)
        if child1 then
            reconcileChildren(child1, child2)
        else
            child2.Parent = parent1
        end
    end
end

local function reconcileDataModels(dataModel1, dataModel2)
    -- Transfer services if DataModel1 is missing services that DataModel2 has
    for _,service in ipairs(dataModel2:GetChildren()) do
        if not dataModel1:FindFirstChildOfClass(service.ClassName) then
            service.Parent = dataModel1
        end
    end

    for _,service1 in ipairs(dataModel1:GetChildren()) do
        local service2 = dataModel2:FindFirstChildOfClass(service1.ClassName)

        if service2 then
            for _,child2 in ipairs(service2:GetChildren()) do
                local child1 = findFirstChildOfClassAndName(service1, child2.ClassName, child2.Name)
                if child1 then
                    print(("Reconciling %s from %s and %s"):format(child2:GetFullName(), dataModel1.Name, dataModel2.Name))
                    reconcileChildren(child1, child2)
                else
                    print(("Copying %s into %s from %s"):format(child2:GetFullName(), dataModel1.Name, dataModel2.Name))
                    child2.Parent = service1
                end
            end
        end
    end
end

-- Reconcile all the DataModels in order of arguments
while #dataModels > 1 do
    reconcileDataModels(dataModels[#dataModels - 1], table.remove(dataModels, #dataModels))
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
--# selene: allow(undefined_variable)

local args = {...}
local branchName = args[1]
local commitSHA = args[2]
local assetId = args[3]
local placeFiles = {select(4, ...)}

if #placeFiles == 0 then
    error("Expected 1 or more file paths")
end

local function reconcile(dataModel1, dataModel2)
    -- Transfer services if DataModel1 is missing services that DataModel2 has
    for _,service in ipairs(dataModel2:GetChildren()) do
        if not dataModel1:FindFirstChildOfClass(service.ClassName) then
            service.Parent = dataModel1
        end
    end

    print("DATAMODEL1 CHILDREN")
    for _,child in ipairs(dataModel1:GetChildren()) do
        print(child.Name)
    end

    print("DATAMODEL2 CHILDREN")
    for _,child in ipairs(dataModel2:GetChildren()) do
        print(child.Name)
    end

    for _,service1 in ipairs(dataModel1:GetChildren()) do
        local service2 = dataModel2:FindFirstChildOfClass(service1.ClassName)

        if service2 then
            for _,child in ipairs(service2:GetChildren()) do
                if not service1:FindFirstChild(child.Name) then
                    child.Parent = service1
                end
            end
        else
            print("service doesn't exist!", service1.Name)
        end
    end
end

local dataModels = {}

-- Read the place files into DataModels
for _,placeFile in ipairs(placeFiles) do
    table.insert(dataModels, remodel.readPlaceFile(placeFile))
end

-- Reconcile all the DataModels in order of arguments
while #dataModels > 1 do
    reconcile(dataModels[#dataModels - 1], table.remove(dataModels, #dataModels))
end

local dataModel = dataModels[1]

for _,child in ipairs(dataModel:GetChildren()) do
    print("child", child.Name)
end

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
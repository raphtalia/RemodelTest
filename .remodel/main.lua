local SAVED_SERVICES = {
    "Chat",
    "Lighting",
    "ReplicatedFirst",
    "ReplicatedStorage",
    "ServerScriptService",
    "ServerStorage",
    "SoundService",
    "StarterGui",
    "StarterPack",
    "StarterPlayer",
    "Teams",
    "Workspace",
}

local game = remodel.readPlaceFile("place.rbxl")

local function mapAssets(directory, instance, noScripts)
    for _,v in ipairs(remodel.readDir(directory)) do
        if remodel.isDir(("%s/%s"):format(directory, v)) then
            local existingAsset = instance:FindFirstChild(v)
            if existingAsset then
                existingAsset:Destroy()
            end

            local folder = Instance.new("Folder")
            folder.Name = v
            folder.Parent = instance

            mapAssets(("%s/%s"):format(directory, v), folder)
        elseif remodel.isFile(("%s/%s"):format(directory, v)) then
            for _,asset in ipairs(remodel.readModelFile(("%s/%s"):format(directory, v))) do
                if not noScripts or not asset:IsA("Script") then
                    if noScripts then
                        for _,script in ipairs(asset:GetDescendants()) do
                            if script:IsA("Script") then
                                script:Destroy()
                            end
                        end
                    end

                    asset.Parent = instance
                end
            end
        end
    end
end

local function saveService(serviceName)
    local service = game:GetService(serviceName)
    remodel.writeModelFile(service, ("output/%s.rbxm"):format(serviceName))
end

mapAssets("assets/Workspace", game:GetService("Workspace"))

for _,serviceName in ipairs(SAVED_SERVICES) do
    saveService(serviceName)
end
print("Shared")

local Github = require(game:GetService("ReplicatedStorage")._GithubMetadata)
print("Branch:", Github.Branch)
print("Commit:", Github.Commit)

return nil
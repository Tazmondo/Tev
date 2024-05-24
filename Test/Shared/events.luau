local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Blue = require(ReplicatedStorage.Packages.Blue)
local Guard = require(ReplicatedStorage.Packages.Guard)

return {
	loaded = Blue.Client("loaded", function() end),
	empty = Blue.Server("empty", function() end),

	clientarguments = Blue.Client("carguments", function(arg1, arg2, arg3)
		return Guard.Number(arg1), Guard.CFrame(arg2), Guard.String(arg3)
	end),

	serverarguments = Blue.Server("sarguments", function(arg1, arg2, arg3)
		return Guard.Number(arg1), Guard.CFrame(arg2), Guard.String(arg3)
	end),

	tabargument = Blue.Server("targument", function(tab)
		return tab :: {
			wow: number,
			loo: string,
		}
	end),
}

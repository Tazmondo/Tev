local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Tev = require(ReplicatedStorage.Packages.Tev)
local Guard = require(ReplicatedStorage.Packages.Guard)

return {
	loaded = Tev.Client("loaded", function() end),
	empty = Tev.Server("empty", function() end),

	clientarguments = Tev.Client("carguments", function(arg1, arg2, arg3)
		return Guard.Number(arg1), Guard.CFrame(arg2), Guard.String(arg3)
	end),

	serverarguments = Tev.Server("sarguments", function(arg1, arg2, arg3)
		return Guard.Number(arg1), Guard.CFrame(arg2), Guard.String(arg3)
	end),

	tabargument = Tev.Server("targument", function(tab)
		return tab :: {
			wow: number,
			loo: string,
		}
	end),

	func = Tev.Function("func", function(a1, a2)
		return Guard.Number(a1), Guard.String(a2)
	end, function(a3)
		return a3 :: CFrame
	end),
}

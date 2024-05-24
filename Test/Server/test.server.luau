--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local events = require(ReplicatedStorage.events)

local function printer(prefix: string)
	return function(...)
		print(prefix, ...)
	end
end

events.loaded:On(printer("Loaded"))
events.clientarguments:On(printer("Client arguments"))

task.wait(3)
events.empty:FireAll()
events.serverarguments:FireAll(1, CFrame.new(), "lol")
events.tabargument:FireAll({
	loo = "dddd",
	wow = 1004,
})

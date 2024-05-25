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

events.func:On(function(plr, num, stri)
	if Random.new():NextInteger(1, 2) == 2 then
		error("oh noooo")
	end
	task.wait(Random.new():NextNumber(1, 3))
	return CFrame.new()
end)

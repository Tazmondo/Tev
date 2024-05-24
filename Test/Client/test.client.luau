local ReplicatedStorage = game:GetService("ReplicatedStorage")

local events = require(ReplicatedStorage.events)

local function printer(prefix: string)
	return function(...)
		print(prefix, ...)
	end
end

task.wait(5)
events.tabargument:On(printer("tabarguments"))
events.serverarguments:On(printer("serverarguments"))
events.empty:On(printer("empty"))

events.loaded:Fire()
events.clientarguments:Fire(123, CFrame.new(), "aaa")

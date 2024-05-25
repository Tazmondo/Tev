local ReplicatedStorage = game:GetService("ReplicatedStorage")

local events = require(ReplicatedStorage.events)

local function printer(prefix: string)
	return function(...)
		print(prefix, ...)
	end
end

task.wait(1)
events.tabargument:On(printer("tabarguments"))
events.serverarguments:On(printer("serverarguments"))
events.empty:On(printer("empty"))

events.loaded:Fire()
events.clientarguments:Fire(123, CFrame.new(), "aaa")

events.func:Invoke(5, "lool"):After(printer("function1"))
events.func:Invoke(5, "lool"):After(printer("function2"))
events.func:Invoke(5, "lool"):After(printer("function3"))
events.func:Invoke(5, "lool"):After(printer("function4"))
events.func:Invoke(5, "lool"):After(printer("function5"))

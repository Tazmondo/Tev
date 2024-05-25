local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Future = require(ReplicatedStorage.Packages.Future)
local Event = require(script.Parent.Event)

export type Function<R, T...> = {
	Invoke: (self: Function<R, T...>, player: Player, T...) -> Future.Future<Future.TablePcall<R>>,

	On: (self: Function<R, T...>, callback: (T...) -> R) -> (),
}

local function Trace(err)
	-- Return at 2nd level so the traceback starts at the function, not here.
	local trace = debug.traceback(err, 2)
	warn(`Blue Function error: {trace}`)
	return trace
end

local function Function<R, T...>(id: string, guard: (...unknown) -> T..., returnGuard: (unknown) -> R): Function<R, T...>
	local event = Event(id, true)

	local pendingRequests: { [Player]: { thread }? } = {}
	if RunService:IsServer() then
		event.OnServerEvent:Connect(function(player, returnValue)
			local pending = pendingRequests[player]
			if not pending or #pending == 0 then
				return
			end

			local calledThread = table.remove(pending, 1)
			assert(calledThread)

			if #pending == 0 then
				pendingRequests[player] = nil
			end

			task.spawn(calledThread, returnValue)
		end)
	end

	local function Invoke(self: Function<R, T...>, player: Player, ...: T...)
		assert(RunService:IsServer(), "Tried to invoke remote function from the client.")

		return Future.Try(function(player, ...)
			local existing = pendingRequests[player] or {} :: { thread }
			local currentThread = coroutine.running()
			table.insert(existing, currentThread)
			pendingRequests[player] = existing

			local cancel = false

			local delayThread = task.delay(5, function()
				-- after 30 seconds, cancel
				cancel = true
				for i, thread in existing do
					if thread == currentThread then
						table.remove(existing, i)
						task.spawn(thread, nil)
						break
					end
				end
			end)

			event:FireClient(player, ...)

			local value = coroutine.yield()
			if cancel then
				error("Remote Function timed out")
			else
				task.cancel(delayThread)
			end
			returnGuard(value)

			return value
		end, player, ...)
	end

	local function On(self: Function<R, T...>, callback: (T...) -> R)
		assert(RunService:IsClient(), "Tried to listen to remote function from the server.")
		event.OnClientEvent:Connect(function(...)
			local success, result = xpcall(callback, Trace, ...)
			if success then
				event:FireServer(result)
			else
				event:FireServer()
			end
		end)
	end

	return {
		Invoke = Invoke,
		On = On,
	}
end

return Function

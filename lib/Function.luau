local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local RemoteEvent = require(ReplicatedStorage.Packages.Blue.RemoteEvent)
local Future = require(ReplicatedStorage.Packages.Future)

export type Function<R, T...> = {
	Invoke: (self: Function<R, T...>, T...) -> Future.Future<Future.TablePcall<R>>,

	On: (self: Function<R, T...>, callback: (Player, T...) -> R) -> (),
}

local function Trace(err)
	-- Return at 2nd level so the traceback starts at the function, not here.
	local trace = debug.traceback(err, 2)
	warn(`Blue Function error: {trace}`)
	return trace
end

local function ServerFunction<R, T...>(id: string, guard: (...unknown) -> T..., returnGuard: (unknown) -> R)
	local event = RemoteEvent(id, true)
	local requestId = 1

	local pending: { [number]: thread } = {}

	if RunService:IsClient() then
		event.OnClientEvent:Connect(function(id: number, success: boolean, returnValue: Future.TablePcall<R>)
			local pendingThread = pending[id]
			if not pendingThread then
				error("Pending thread was not found?")
			end

			pending[id] = nil
			task.spawn(pendingThread, returnValue)
		end)
	end

	local function Invoke(...: T...)
		assert(RunService:IsClient(), "Tried to invoke remote function from server.")

		return Future.new(function(...)
			event:FireServer(requestId, ...)
			pending[requestId] = coroutine.running()
			requestId += 1

			local retValue: Future.TablePcall<R> = coroutine.yield()

			return retValue
		end, ...)
	end

	local function On(callback: (Player, T...) -> R)
		assert(RunService:IsServer(), "Tried to register remote function handler on client.")

		event.OnServerEvent:Connect(function(player, id: unknown, ...)
			if not typeof(id == "number") then
				if RunService:IsStudio() then
					error("Did not receive valid request id")
				end
				return
			end

			local guardSuccess, err = (pcall :: any)(guard, ...)
			if not guardSuccess then
				event:FireClient(player, id, {
					success = false,
					value = err,
				})
				return
			end

			local callbackSuccess, value = xpcall(callback, Trace, ...)
			if not callbackSuccess then
				event:FireClient(player, id, {
					success = false,
					value = "Unexpected Server Error",
				})
				return
			else
				event:FireClient(player, id, {
					success = true,
					value = value,
				})
				return
			end
		end)
	end

	return {
		Invoke = Invoke,
		On = On,
	}
end

return ServerFunction

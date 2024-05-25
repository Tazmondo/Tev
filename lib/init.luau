local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local Event = require(script.Event)
local Future = require(script.Parent.Future)
type ServerEvent<T...> = {
	Fire: (self: ServerEvent<T...>, Player | { Player }, T...) -> (),
	FireAll: (self: ServerEvent<T...>, T...) -> (),
	FireAllExcept: (self: ServerEvent<T...>, Player, T...) -> (),
	FireFiltered: (self: ServerEvent<T...>, Filter: (Player) -> boolean, T...) -> (),

	On: (self: ServerEvent<T...>, callback: (T...) -> ()) -> (),
}

type ClientEvent<T...> = {
	Fire: (self: ClientEvent<T...>, T...) -> (),

	On: (self: ClientEvent<T...>, callback: (Player, T...) -> ()) -> (),
}

type Function<R, T...> = {
	Invoke: (self: Function<R, T...>, player: Player, T...) -> Future.Future<Future.TablePcall<R>>,

	On: (self: Function<R, T...>, callback: (T...) -> R) -> (),
}

local function Client<T...>(id: string, reliable: boolean, guard: (...unknown) -> T...): ClientEvent<T...>
	local event = Event(id, reliable)

	local function Fire(self: ClientEvent<T...>, ...)
		assert(RunService:IsClient(), "Tried to fire a client event from the server.")
		event:FireServer(...)
	end

	local function On(self: ClientEvent<T...>, callback: (Player, T...) -> ())
		assert(RunService:IsServer(), "Tried to listen to a client event from the client.")

		event.OnServerEvent:Connect(function(player, ...)
			local success, err = (pcall :: any)(guard, ...)
			if success then
				callback(player, ...)
			elseif RunService:IsStudio() then
				-- you probably want to be notified if this happens in studio
				-- but we don't want exploiters spamming warnings in live game
				warn("Received invalid arguments from event with id", id, "error:", err)
			end
		end)
	end

	return {
		Fire = Fire,
		On = On,
	}
end

local function ReliableClient<T...>(id: string, guard: (...unknown) -> T...): ClientEvent<T...>
	return Client(id, true, guard)
end

local function UnreliableClient<T...>(id: string, guard: (...unknown) -> T...): ClientEvent<T...>
	return Client(id, false, guard)
end

local function Server<T...>(id: string, reliable: boolean, guard: (...unknown) -> T...): ServerEvent<T...>
	local event = Event(id, reliable)

	local function Fire(self: ServerEvent<T...>, player: Player | { Player }, ...)
		assert(RunService:IsServer(), "Tried to fire a server event from the client.")
		if typeof(player) == "Instance" then
			event:FireClient(player, ...)
		else
			for _, player in player do
				event:FireClient(player, ...)
			end
		end
	end

	local function FireAll(self: ServerEvent<T...>, ...)
		assert(RunService:IsServer(), "Tried to fire a server event from the client.")

		event:FireAllClients(...)
	end

	local function FireAllExcept(self: ServerEvent<T...>, excludedPlayer: Player, ...)
		assert(RunService:IsServer(), "Tried to fire a server event from the client.")

		for _, player in Players:GetPlayers() do
			if player ~= excludedPlayer then
				event:FireClient(player, ...)
			end
		end
	end

	local function FireFiltered(self: ServerEvent<T...>, filter: (Player) -> boolean, ...)
		assert(RunService:IsServer(), "Tried to fire a server event from the client.")

		for _, player in Players:GetPlayers() do
			if filter(player) then
				event:FireClient(player, ...)
			end
		end
	end

	local function On(self: ServerEvent<T...>, callback: (T...) -> ())
		assert(RunService:IsClient(), "Tried to listen to a server event from the server.")

		event.OnClientEvent:Connect(callback)
	end

	return {
		Fire = Fire,
		FireAll = FireAll,
		FireAllExcept = FireAllExcept,
		FireFiltered = FireFiltered,
		On = On,
	}
end

local function ReliableServer<T...>(id: string, guard: (...unknown) -> T...): ServerEvent<T...>
	return Server(id, true, guard)
end

local function UnreliableServer<T...>(id: string, guard: (...unknown) -> T...): ServerEvent<T...>
	return Server(id, false, guard)
end

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

return {
	Client = ReliableClient,
	UnreliableClient = UnreliableClient,

	Server = ReliableServer,
	UnreliableServer = UnreliableServer,

	Function = Function,
}

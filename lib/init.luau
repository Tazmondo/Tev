local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local Event = require(script.Event)
type ServerEvent<T...> = {
	Reliable: boolean,

	Fire: (self: ServerEvent<T...>, Player | { Player }, T...) -> (),
	FireAll: (self: ServerEvent<T...>, T...) -> (),
	FireAllExcept: (self: ServerEvent<T...>, Player, T...) -> (),
	FireFiltered: (self: ServerEvent<T...>, Filter: (Player) -> boolean, T...) -> (),

	On: (self: ServerEvent<T...>, callback: (T...) -> ()) -> (),
}

type ClientEvent<T...> = {
	Reliable: boolean,

	Fire: (self: ClientEvent<T...>, T...) -> (),

	On: (self: ClientEvent<T...>, callback: (Player, T...) -> ()) -> (),
}

local function Client<T...>(id: string, reliable: boolean, guard: (...unknown) -> T...): ClientEvent<T...>
	local event = Event(id, reliable)

	local function Fire(self: ClientEvent<T...>, ...)
		assert(RunService:IsClient(), "Tried to fire a client event from the server.")
		event:FireServer(...)
	end

	local function On(self: ClientEvent<T...>, callback: (Player, T...) -> ())
		assert(RunService:IsServer(), "Tried to listen to a client event from the client.")
		assert(callback == nil, "Tried to listen to event more than once.")

		event.OnServerEvent:Connect(function(...)
			local success = pcall(guard, ...)
			if success then
				callback(...)
			end
		end)
	end

	return {
		Reliable = reliable,

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
		Reliable = reliable,

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

return {
	Client = ReliableClient,
	UnreliableClient = UnreliableClient,

	Server = ReliableServer,
	UnreliableServer = UnreliableServer,
}

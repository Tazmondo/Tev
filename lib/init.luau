local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
type ServerEvent<T...> = {
	Reliable: boolean,

	Fire: (self: ServerEvent<T...>, Player | { Player }, T...) -> (),
	FireAll: (self: ServerEvent<T...>, T...) -> (),
	FireAllExcept: (self: ServerEvent<T...>, Player, T...) -> (),
	FireFiltered: (self: ServerEvent<T...>, Filter: (Player) -> boolean, T...) -> (),

	On: (self: ServerEvent<T...>, T...) -> (),
}

type ClientEvent<T...> = {
	Reliable: boolean,

	Fire: (self: ClientEvent<T...>, T...) -> (),

	On: (self: ClientEvent<T...>, Player, T...) -> (),
}

local function Client<T...>(id: string, reliable: boolean, guard: (...unknown) -> T...): ClientEvent<T...>
	local function Fire(self: ClientEvent<T...>, ...: T...)
		assert(RunService:IsClient(), "Tried to fire a client event from the server.")
	end

	local function On(self: ClientEvent<T...>, player: Player, ...: T...)
		assert(RunService:IsServer(), "Tried to listen to a client event from the client.")
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
	local function Fire(self: ServerEvent<T...>, player: Player | { Player }, ...: T...)
		assert(RunService:IsServer(), "Tried to fire a server event from the client.")
	end

	local function FireAll(self: ServerEvent<T...>, ...: T...)
		assert(RunService:IsServer(), "Tried to fire a server event from the client.")

		for _, player in Players:GetPlayers() do
			self:Fire(player, ...)
		end
	end

	local function FireAllExcept(self: ServerEvent<T...>, excludedPlayer: Player, ...: T...)
		assert(RunService:IsServer(), "Tried to fire a server event from the client.")

		for _, player in Players:GetPlayers() do
			if player ~= excludedPlayer then
				self:Fire(player, ...)
			end
		end
	end

	local function FireFiltered(self: ServerEvent<T...>, filter: (Player) -> boolean, ...: T...)
		assert(RunService:IsServer(), "Tried to fire a server event from the client.")

		for _, player in Players:GetPlayers() do
			if filter(player) then
				self:Fire(player, ...)
			end
		end
	end

	local function On(self: ServerEvent<T...>, ...: T...)
		assert(RunService:IsClient(), "Tried to listen to a server event from the server.")
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

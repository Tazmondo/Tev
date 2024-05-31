local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local Event = require(script.Parent.Parent.RemoteEvent)

export type ServerEvent<T...> = {
	Fire: (self: ServerEvent<T...>, Player | { Player }, T...) -> (),
	FireAll: (self: ServerEvent<T...>, T...) -> (),
	FireAllExcept: (self: ServerEvent<T...>, Player, T...) -> (),
	FireFiltered: (self: ServerEvent<T...>, Filter: (Player) -> boolean, T...) -> (),

	On: (self: ServerEvent<T...>, callback: (T...) -> ()) -> (),
}

local function Server<T...>(id: string, reliable: boolean, guard: (...unknown) -> T...): ServerEvent<T...>
	local event = Event(id, reliable)
	local connected = false

	if RunService:IsClient() then
		task.delay(10, function()
			if not connected then
				warn(`event {id} did not have a listener function set!`)
			end
		end)
	end

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
		assert(not connected, "Tried to listen to a server event more than once.")
		connected = true

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

return Server

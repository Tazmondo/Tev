local RunService = game:GetService("RunService")

local Event = require(script.Parent.Parent.RemoteEvent)

export type ClientEvent<T...> = {
	Fire: (self: ClientEvent<T...>, T...) -> (),

	On: (self: ClientEvent<T...>, callback: (Player, T...) -> ()) -> (),
}

local function Client<T...>(id: string, reliable: boolean, guard: (...unknown) -> T...): ClientEvent<T...>
	local event = Event(id, reliable)
	local connected = false

	local function Fire(self: ClientEvent<T...>, ...)
		assert(RunService:IsClient(), "Tried to fire a client event from the server.")
		event:FireServer(...)
	end

	local function On(self: ClientEvent<T...>, callback: (Player, T...) -> ())
		assert(RunService:IsServer(), "Tried to listen to a client event from the client.")
		assert(not connected, "Tried to listen to a client event more than once.")

		connected = true

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

return Client

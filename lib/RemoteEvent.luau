local RunService = game:GetService("RunService")

local function CreateEvent(reliable: boolean): RemoteEvent | UnreliableRemoteEvent
	if reliable then
		return Instance.new("RemoteEvent")
	else
		return Instance.new("UnreliableRemoteEvent")
	end
end

local function new(id: string, reliable: boolean): RemoteEvent
	if RunService:IsServer() then
		local existing = script:FindFirstChild(id)
		if existing then
			if not RunService:IsRunning() then
				error(`Two events had the same id: {id}`)
			else
				-- prevents issues with being referenced by plugins like UI labs
				return existing :: RemoteEvent
			end
		end

		local event = CreateEvent(reliable) :: RemoteEvent -- cast to fix unassignable union property bug
		event.Name = id
		event.Archivable = false
		event.Parent = script

		return event
	else
		local event = script:WaitForChild(id, 5)
		if
			not event
			or (reliable and event.ClassName == "UnreliableRemoteEvent")
			or (not reliable and event.ClassName == "RemoteEvent")
		then
			error(`Event with id {id} was not created by the server.`)
		end

		return event :: RemoteEvent
	end
end

return new

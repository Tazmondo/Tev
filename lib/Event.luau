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
		if script:FindFirstChild(id) then
			error(`Two events had the same id: {id}`)
		end

		local event = CreateEvent(reliable) :: RemoteEvent -- cast to fix unassignable union property bug
		event.Name = id
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

		return event
	end
end

return new

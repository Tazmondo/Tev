local ClientEvent = require(script.Events.Client)
local ServerEvent = require(script.Events.Server)

local Function = require(script.Function)

export type ServerEvent<T...> = ServerEvent.ServerEvent<T...>
export type ClientEvent<T...> = ClientEvent.ClientEvent<T...>
export type Function<R, T...> = Function.Function<R, T...>

local function ReliableClient<T...>(id: string, guard: (...unknown) -> T...)
	return ClientEvent(id, true, guard)
end

local function UnreliableClient<T...>(id: string, guard: (...unknown) -> T...)
	return ClientEvent(id, false, guard)
end

local function ReliableServer<T...>(id: string, guard: (...unknown) -> T...)
	return ServerEvent(id, true, guard)
end

local function UnreliableServer<T...>(id: string, guard: (...unknown) -> T...)
	return ServerEvent(id, false, guard)
end

return {
	Client = ReliableClient,
	UnreliableClient = UnreliableClient,

	Server = ReliableServer,
	UnreliableServer = UnreliableServer,

	Function = Function,
}

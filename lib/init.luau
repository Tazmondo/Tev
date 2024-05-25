local Client = require(script.Client)
local Function = require(script.Function)
local Server = require(script.Server)

export type ServerEvent<T...> = Server.ServerEvent<T...>
export type ClientEvent<T...> = Client.ClientEvent<T...>
export type Function<R, T...> = Function.Function<R, T...>

local function ReliableClient<T...>(id: string, guard: (...unknown) -> T...)
	return Client(id, true, guard)
end

local function UnreliableClient<T...>(id: string, guard: (...unknown) -> T...)
	return Client(id, false, guard)
end

local function ReliableServer<T...>(id: string, guard: (...unknown) -> T...)
	return Server(id, true, guard)
end

local function UnreliableServer<T...>(id: string, guard: (...unknown) -> T...)
	return Server(id, false, guard)
end

return {
	Client = ReliableClient,
	UnreliableClient = UnreliableClient,

	Server = ReliableServer,
	UnreliableServer = UnreliableServer,

	Function = Function,
}

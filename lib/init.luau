local ClientEvent = require(script.Events.Client)
local ServerEvent = require(script.Events.Server)

local Function = require(script.Function)
local Types = require(script.Types)

type Guard<T...> = Types.Guard<T...>

export type ServerEvent<T...> = ServerEvent.ServerEvent<T...>
export type ClientEvent<T...> = ClientEvent.ClientEvent<T...>
export type Function<R, T...> = Function.Function<R, T...>

-- the return annotations here are necessary to fix some bug where the event table becomes unsealed (?) allowing for undefined functions to be used
-- i.e. event:lol() does not error without these annotations

-- Fix to typepack related type errors when making the guard optional
-- The logic operates on an empty function internally, and expects no function externally
-- Allows events to have no args; and likewise no guard to verify the args
local function hydrateGuard<T...>(guard: Guard<T...>?): any
	return guard or function() end
end

local idCount = 0
local function getNextId()
	idCount += 1
	return tostring(idCount)
end

local function hydrateId(id: string?): string
	return id or getNextId()
end

--We cast  to any as it allows the user to not specify the guard on an API level, and ignores the irrelevant type pack related type issues
local function ReliableClient<T...>(id: string?, guard: Guard<T...>?): ClientEvent<T...>
	return ClientEvent(hydrateId(id), true, hydrateGuard(guard))
end

local function UnreliableClient<T...>(id: string?, guard: Guard<T...>?): ClientEvent<T...>
	return ClientEvent(hydrateId(id), false, hydrateGuard(guard))
end

local function ReliableServer<T...>(id: string?, guard: Guard<T...>?): ServerEvent<T...>
	return ServerEvent(hydrateId(id), true, hydrateGuard(guard))
end

local function UnreliableServer<T...>(id: string?, guard: Guard<T...>?): ServerEvent<T...>
	return ServerEvent(hydrateId(id), false, hydrateGuard(guard))
end

return {
	Client = ReliableClient,
	UnreliableClient = UnreliableClient,

	Server = ReliableServer,
	UnreliableServer = UnreliableServer,

	Function = Function,
}

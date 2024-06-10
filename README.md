# Tev (Typed Event)

I've used Red for a while (and have made contributions to it) and while I love the idea of shared event type definitions between server and client, there are various things that have cropped up while using it that have been bothering me, which are too significant to just make a PR to fix.

- The API is unwieldy
  - if using old events API, you need to do event.Server and event.Client to access the functions. this makes auto-import not work as well and is overall a pain
  - the sharedevents api is just verbose. it exposes both server and client functions, so the method names become quite long
- it has unnecessary batching
  - this eliminates any ordering sent between different events on the same frame
  - can marginally increase network usage if you aren't making use of it, since the lib has to send an extra identifier even if there's only one event being sent
  - you very rarely actually need to send a lot of events on one frame to the same player, so the benefits are minimal

## Advantages over other networking libraries

### Why not use Bytenet or Zap?

Buffer-based networking does result in reduced network usage, but they are more involved to use. When you don't really *need* the performance benefits, there's not a whole lot of reason to use them and they slow down development.

### What about other networking libs?

Other than these two (and Red), most other well known networking libraries don't provide types at all. Your client could expect a string and the server could send a number, and you won't get any sort of error until it starts happening in your live games (or if you're lucky enough to discover it in testing).

## What does Tev do different?

All events are one-sided. They are either sent exclusively from the client or the server. This allows us to expose a much smaller API surface and makes usage more ergonomic.

You rarely, if ever, need double-sided events when using types (as both server and client would need to be sending the exact same data through), so this isn't really a sacrifice.

Other than providing types, it doesn't do much else and is pretty much just a direct wrapper around remote events. It also includes some error handling. The only fancy thing it does is use remote events for implementing remote functions.

This means that, unlike in Red, unhandled events are queued until the connections is made, which solves a relatively common footgun. All events are also received in the same order that they are sent, unlike in Red, which has caused a couple headaches for me in the past.

## Usage

### Events

Events are named after which runtime dispatches them.

- Server = Server -> Client
- Client = Client -> Server

Very similar to Red, just a slightly different API. Recommended to be used with red-blox guard too.

```lua

local serverEvent = Tev.Server("Unique Event Name", function(arg1, arg2, arg3)
  return arg1 :: number, arg2 :: string, arg3 :: CFrame -- don't necessarily need to use Guard for server events.
end)

local clientEvent = Tev.Client("Unique Event Name", function(arg1, arg2, arg3)
  return Guard.Number(arg1), Guard.String(arg2), Guard.CFrame(arg3) -- should definitely use guard for client events to prevent exploiters sending incorrect types
end)

-- Server
serverEvent:Fire(player, 5, "foo", CFrame.new())
clientEvent:On(function(player, arg1, arg2, arg3)
  -- handle event
end)

-- client
clientEvent:Fire(5, "foo", CFrame.new())
serverEvent:On(function(arg1, arg2, arg3)
  -- handle event
end)

```

### Functions

Like in Red, functions are only client -> server -> client.

Invoking returns a future, which resolves when the server responds to the invocation.
It returns in a pcall format (which is table based, instead of being a tuple), so you can handle the case where the server errors without infinitely yielding.

They may also return only one value, so if you need to return multiple it's recommended to use a table.
(This is a result of my Future implementation only holding one value, which has other advantages not expressed in this library)

```lua
type Return = {
  value1: number,
  value2: string
}

local myFunction = Tev.Function("Unique event name", function(inp1, inp2)
  return Guard.Number(inp1), Guard.String(inp2) -- should guard this function to stop exploiters sending incorrect types
end, function(retValue)
  return retValue :: Return -- don't need to guard this, as it's sent from the server
end)

-- Server
myFunction:On(function(player: Player, inp1: number, inp2: string)
  return {
    value1 = inp1,
    value2 = inp2
  }
)

-- Client
local value = myFunction:Invoke(100, "lol"):Await()

if value.success then
  -- value.value is the returned type
else
  -- value.value is an error message
  warn("Invocation failed!", value.value)
end
```

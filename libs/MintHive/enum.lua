local enum = {
  channel = {
    default = 0,
    unreliable = 1,
    unsequenced = 2,
  },
  disconnect = {
    normal = 0,
    badconnect = 1,
    badserver = 2,
    badusername = 3,
    badlogin = 4,
  },
  packetType = {
    receive = "receive",
    disconnect = "disconnect",
    login = "login",
  }
}

enum.convert = function(value, enumType)
  local enums = enum[enumType]
  for k, v in pairs(enums) do
    if v == value then
      return k
    end
  end
  return nil
end

enum.channelCount = 0
for channel, _ in pairs(enum.channel) do
  enum.channelCount = enum.channelCount + 1
end

return enum
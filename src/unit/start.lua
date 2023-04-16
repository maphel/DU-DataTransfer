mySocket = Socket.new()

local channels = {
    {req = "R1_CHECK", res = "R1"}, 
    {req = "R2_CHECK", res = "R2"}, 
}

for key, channel in ipairs(channels) do
    mySocket:add(channel.req, channel.res)
end

mySocket.databank.clear()
mySocket:emit()
--local mergedTable = socket:getMessages()
unit.setTimer("backup", 0.25)
system.print(databank.getKeys())
system.print(self.receiver.hasChannel("M1_CHECK"))
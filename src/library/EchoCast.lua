-- EchoCast
-- v0.0.1 
-- April 17 2023
-- by ML

EchoCast = {}
EchoCast.__index = EchoCast

EchoCastSlave = setmetatable({}, EchoCast)
EchoCastSlave.__index = EchoCastSlave

EchoCastMaster = setmetatable({}, EchoCast)
EchoCastMaster.__index = EchoCastMaster

function EchoCast:new(isSlave)
    local obj = {}
    setmetatable(obj, EchoCast)
    obj.database, obj.emitter, obj.receiver = Util.getUnits(isSlave)
    obj.queue = {}
    return obj
end

function EchoCast:clearDB()
    self.database.clear()
end

function EchoCastMaster:new()
    local obj = EchoCast:new(false)
    setmetatable(obj, EchoCastMaster)
    obj.timeout = 5
    obj.timer = nil
    obj.startTime = system.getArkTime()
    obj.tempData = {}
    obj.currentRequest = nil
    return obj
end

function EchoCastMaster:addRequest(reqChannel, resChannel, addFirst)
    local queueItem = {channel = reqChannel, resChannel = resChannel, message = "ping"}
    if addFirst then
        table.insert(self.queue, 1, queueItem)
    else
        table.insert(self.queue, queueItem)
    end
    if self.receiver.hasChannel(reqChannel) == 0 then
        local channels = self.receiver.getChannelList()
        table.insert(channels, reqChannel)
        system.print("updated channels! " .. reqChannel)
        self.receiver.setChannelList(channels)
    end
end

function EchoCastMaster:processQueue()
    if not self.currentRequest and #self.queue > 0 then
        self.currentRequest = table.remove(self.queue, 1)
        self.emitter.send(self.currentRequest.channel, self.currentRequest.message)
        self.timer = system.getArkTime()
    end
end

function EchoCastMaster:onUpdate()
    if self.currentRequest then
        local currentTime = system.getArkTime()
        if currentTime - self.timer >= self.timeout then
            system.print("out of time")
            self:addRequest(self.currentRequest.channel, self.currentRequest.resChannel, true)
            self.currentRequest = nil
            self.timer = nil
        end
    end
    self:processQueue()
end

function EchoCastMaster:onReceived(channel, message)
    local responseChannel = self.currentRequest and self.currentRequest.resChannel or nil
    if responseChannel == channel then
        local chunkIndex, totalChunks, content = message:match("^(%d+)/(%d+)/(.*)$")
        if chunkIndex and totalChunks then
            local chunkData = content
            self.tempData[chunkIndex] = chunkData
            if tonumber(chunkIndex) == tonumber(totalChunks) then
                system.print("Data fully recieved of " .. self.currentRequest.channel)
                system.print(content)
                local orderedChunks = {}
                for i = 1, totalChunks do
                    table.insert(orderedChunks, self.tempData[i])
                end
                self.database.setStringValue(channel, table.concat(orderedChunks)) 
                self.tempData = {}
            elseif tonumber(chunkIndex) < tonumber(totalChunks) then
                system.print("Added new request to " .. self.currentRequest.channel)
                self:addRequest(self.currentRequest.channel, channel, true)
            end
            self.currentRequest = nil
            self.timer = nil
        end
    end
end

function EchoCastSlave:new()
    local obj = EchoCast:new(true)
    setmetatable(obj, EchoCastSlave)
    obj:loadQueue()
    return obj
end

function EchoCastSlave:loadQueue()
    self.queue = {}
    if self.database.hasKey("queue") then
        local savedQueue = self.database.getStringValue("queue")
        for savedItem in savedQueue:gmatch("[^\n]+") do
            table.insert(self.queue, savedItem)
        end
    end
end

function EchoCastSlave:saveQueue()
    self.database.setStringValue("queue", table.concat(self.queue, "\n"))
end

function EchoCastSlave:addResponse(resChannel, message)
    if #self.queue == 0 then
        message = Util.stringify(message)
        local maxChunkSize = 512
        local headerSize = 6
        local chunkDataSize = maxChunkSize - headerSize
        local messageLength = #message
        local totalChunks = math.ceil(messageLength / chunkDataSize)

        for i = 1, totalChunks do
            local startIdx = (i - 1) * chunkDataSize + 1
            local endIdx = math.min(i * chunkDataSize, messageLength)
            local chunk = message:sub(startIdx, endIdx)
            local chunkWithHeader = string.format("%d/%d/%s", i, totalChunks, chunk)
            local queueItem = {channel = resChannel, message = chunkWithHeader}
            table.insert(self.queue, queueItem)
        end
        self:saveQueue()
    end
end

function EchoCastSlave:processQueue()
    local currentRequest = table.remove(self.queue, 1)
    self.emitter.send(currentRequest.channel, currentRequest.message)
    self.database.setStringValue("queue", table.concat(self.queue, "\n"))
end

function EchoCastSlave:onUpdate()
    self:processQueue()
end
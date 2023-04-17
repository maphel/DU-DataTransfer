-- EchoCast
-- v0.0.1 
-- April 14 2023
-- by ML
EchoCast = {}
EchoCast.__index = EchoCast

EchoCastSlave = setmetatable({}, EchoCast)
EchoCastSlave.__index = EchoCastSlave

EchoCastMaster = setmetatable({}, EchoCast)
EchoCastMaster.__index = EchoCastMaster

function EchoCast:new(isSlave, logging)
    local obj = {}
    setmetatable(obj, EchoCast)
    obj.database, obj.emitter, obj.receiver = Util.getUnits(isSlave)
    obj.logging = logging or false
    obj.queue = {}
    return obj
end

function EchoCast:clearDB()
    self.database.clear()
end

function EchoCast:log(message)
    if self.logging then 
        system.print("[LOG]: ".. message)
     end
end

function EchoCastMaster:new(finishCallback, progressCallback, logging)
    local obj = EchoCast:new(false, logging)
    setmetatable(obj, EchoCastMaster)
    self:log("EchoCastMaster v0.0.1 by ML")
    obj.queueDone = 0
    obj.queueTotal = 0
    obj.timeout = 0.5
    obj.timer = nil
    obj.startTime = system.getArkTime()
    obj.tempData = {}
    obj.currentRequest = nil
    obj.finishCallback = finishCallback or nil
    obj.progressCallback = progressCallback or nil
    return obj
end

function EchoCastMaster:addRequest(reqChannel, resChannel, requeue)
    local queueItem = {
        channel = reqChannel,
        resChannel = resChannel,
        message = "ping"
    }
    
    if requeue then
        table.insert(self.queue, 1, queueItem)
    else
        self.queueTotal = self.queueTotal + 1
        table.insert(self.queue, queueItem)
    end
    if self.receiver.hasChannel(resChannel) == 0 then
        local channels = self.receiver.getChannelList()
        table.insert(channels, resChannel)
        self:log("Updated receiver listen with '" .. resChannel .. "'")
        self.receiver.setChannelList(channels)
    end
    self:log("Added request on " .. reqChannel .. "/" .. resChannel)
end

function EchoCastMaster:processQueue()
    if not self.currentRequest and #self.queue > 0 then
        self.currentRequest = table.remove(self.queue, 1)
        self.emitter.send(self.currentRequest.channel, self.currentRequest.message)
        self:log("Emitted on " .. self.currentRequest.channel)
        self.timer = system.getArkTime()
    end
end

function EchoCastMaster:onUpdate()
    if self.currentRequest then
        local currentTime = system.getArkTime()
        if currentTime - self.timer >= self.timeout then
            self:log("Timeout on '" .. self.currentRequest.resChannel .. "'. Requeue on '" .. self.currentRequest.channel .. "'")
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
            chunkIndex = tonumber(chunkIndex)
            totalChunks = tonumber(totalChunks)
            local chunkData = content
            table.insert(self.tempData, chunkData)
            if chunkIndex == totalChunks then
                self:onFinish(channel, totalChunks)
            elseif chunkIndex < totalChunks then
                self:onProgressChanged(channel, chunkIndex, totalChunks, content)
            end
            self.currentRequest = nil
            self.timer = nil
        end
    else
        self.log(channel .. "' isn't registered and will be ignored.")
    end
end

function EchoCastMaster:onFinish(channel, totalChunks)
    self:log("Progress is finished on '" .. channel .. "' with " .. totalChunks .. " chunks.")
    local orderedChunks = {}
    for i = 1, totalChunks do
        table.insert(orderedChunks, self.tempData[i])
    end
    local message = table.concat(orderedChunks)
    self.database.setStringValue(channel, message)
    self.tempData = {}
    self.queueDone = self.queueDone + 1
    if self.finishCallback then
        local dto = {
            channel = channel,
            message = message,
            totalChunks = totalChunks,
            queueTotal = self.queueTotal,
            queueDone = self.queueDone
        }
        self.finishCallback(dto)
    end
end

function EchoCastMaster:onProgressChanged(channel, chunkIndex, totalChunks, message)
    self:log("Progress is changing on " .. channel .. " " .. chunkIndex .. "/" .. totalChunks)
    self:addRequest(self.currentRequest.channel, channel, true)
    if self.progressCallback then
        local dto = {
            channel = channel,
            message = message,
            chunkIndex = chunkIndex,
            totalChunks = totalChunks,
            queueTotal = self.queueTotal,
            queueDone = self.queueDone
        }
        self.progressCallback(dto)
    end
end

function EchoCastSlave:new(logging)
    local obj = EchoCast:new(true, logging)
    setmetatable(obj, EchoCastSlave)
    self:log("EchoCastMaster v0.0.1 by ML")
    obj:loadQueue()
    return obj
end

function EchoCastSlave:loadQueue()
    self.queue = {}
    if self.database.hasKey("queue") == 1 then
        local savedQueue = self.database.getStringValue("queue")
        for savedItem in savedQueue:gmatch("[^\n]+") do
            self:log("Retrieved from queue: " .. savedItem)
            table.insert(self.queue, savedItem)
        end
    end
end

function EchoCastSlave:saveQueue()
    if #self.queue == 0 then
        self.database.clearValue("queue")
    else
        local queue = self.queue
        self.database.setStringValue("queue", table.concat(queue, "\n"))
    end
end

function EchoCastSlave:addResponse(resChannel, message)
    if #self.queue == 0 then
        -- message = Util.stringify(message)
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
            local queueItem = resChannel .. "|" .. chunkWithHeader
            table.insert(self.queue, queueItem)
            self:log("Insert chunk " .. i .. "/" .. totalChunks .. " to queue")
        end
        self:log("Response added for " .. resChannel)
        self:saveQueue()
    end
end

function EchoCastSlave:processQueue()
    local currentRequest = table.remove(self.queue, 1)
    local channel, message = currentRequest:match("^(.-)|(.*)$")
    self.emitter.send(channel, message)
    self:log("Emit on " .. channel)
    self:saveQueue()
end

function EchoCastSlave:onUpdate()
    self:processQueue()
end
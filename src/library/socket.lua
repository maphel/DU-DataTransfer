Socket = {}
Socket.__index = Socket

function Socket.new(defaultMessage)
    local databank, emitter, receiver = Util.getUnits()

    local self = setmetatable({}, Socket)
    self.defaultMessage = defaultMessage or "msg"
    self.queue = {}
    self.lastMessage = nil
    self.lastChannel = nil
    self.databank = databank
    self.emitter = emitter
    self.receiver = receiver
    self:loadQueue()
    return self
end

function Socket:add(requestChannel, responseChannel, message, position)
    requestChannel = requestChannel or "req"
    responseChannel = responseChannel or "res"
    message = message or "Send request from channel '" .. requestChannel .. "'' and awaiting response on channel '" ..
                  responseChannel .. "'."
    position = position or "last"

    local chunks = Util.splitMessage(message)
    local totalChunks = #chunks
    for i, chunk in ipairs(chunks) do
        if position == "first" then
            table.insert(self.queue, 1, requestChannel .. "|" .. chunk)
        else
            table.insert(self.queue, requestChannel .. "|" .. chunk)
        end
    end
    if self.receiver.hasChannel(responseChannel) == 0 then
        local channels = self.receiver.getChannelList()
        table.insert(channels, responseChannel)
        system.print("updated channels! " .. responseChannel)
        self.receiver.setChannelList(channels)
    end

    local channels = self.databank.getStringValue("channels")
    local combinedChannel = requestChannel .. "|" .. responseChannel
    if not channels:find(combinedChannel) then
        if channels == "" or channels == 0 or channels == "," then
            self.databank.setStringValue("channels", combinedChannel)
        else
            self.databank.setStringValue("channels", channels .. "," .. combinedChannel)
        end
    end
    self:saveQueue()
end

function Socket:emit(backup)
    if not backup then
        backup = false
    end
    if backup then
        self.emitter.send(self.lastChannel, self.lastMessage)
        return
    end
    if #self.queue > 0 then
        local nextChannel, nextMessage = self.queue[1]:match("^(.-)|(.*)$")
        self.lastChannel = nextChannel
        self.lastMessage = nextMessage
        self.emitter.send(nextChannel, nextMessage)
        table.remove(self.queue, 1)
        self:saveQueue()
    end
end

function Socket:getChannels()
    local allChannels = {}
    local keys = self.databank.getKeys()

    for _, key in ipairs(keys) do
        if key:match("^channel_(.*)") then
            local channel = self.databank.getStringValue(key)
            table.insert(allChannels, channel)
        end
    end

    return allChannels
end

function Socket:receive(channel, message)
    local progress, totalChunks, content = message:match("^(%d+)/(%d+)/(.*)$")
    if not progress or not totalChunks then
        system.print("Error: Unable to parse message.")
        if channel then
            system.print("Channel: " .. channel)
        end
        return
    end

    local tempMessage = self.databank.getStringValue("tmp_" .. channel)
    local tempTimestamp = self.databank.getFloatValue("tmp_ts_" .. channel)
    if tempTimestamp == 0 then
        tempTimestamp = system.getArkTime()
    end

    local currentTimestamp = system.getArkTime()
    local receivedChunks = (self.databank.getIntValue("recCh_" .. channel) or 0) + 1
    local isLastChunk = tonumber(progress) == tonumber(totalChunks)
    local isChunkReceivedInTime = (currentTimestamp - tempTimestamp) <= 30
    local isMessageComplete = receivedChunks == tonumber(totalChunks)
    local reqChannel, resChannel = self:findChannel(channel)

    if isLastChunk and isChunkReceivedInTime then
        if isMessageComplete then
            self.databank.clearValue("tmp_" .. channel)
            self.databank.clearValue("tmp_ts_" .. channel)
            self.databank.clearValue("chunks_" .. channel)
            self.databank.setStringValue("msg_" .. channel, tempMessage .. content)
            self.databank.setStringValue("msg_ts_" .. channel, currentTimestamp)
            system.print("Saved:" .. channel .. " - " .. message)
        else
            self.databank.clearValue("tmp_" .. channel)
            self.databank.clearValue("tmp_ts_" .. channel)
            self.databank.clearValue("chunks_" .. channel)
            if reqChannel == nil then
                system.print("Could not determine request channel of channel '" .. channel .. "'.")
            else
                self:add(reqChannel, "req")
            end
        end
        self.databank.setIntValue("chunks_" .. channel, 0)
    else
        if tonumber(progress) == 1 and reqChannel then
            for i = 2, tonumber(totalChunks) do
                self:add(reqChannel, "req")
            end
        end
        self.databank.setIntValue("chunks_" .. channel, receivedChunks)
        self.databank.setStringValue("tmp_" .. channel, tempMessage .. content)
        self.databank.setFloatValue("tmp_ts_" .. channel, currentTimestamp)
    end
end

function Socket:resetData()
    local channels = self.databank.getStringValue("channels")
    local channelPairs = Util.split(channels, ",")

    for _, channelPair in ipairs(channelPairs) do
        local requestChannel, responseChannel = channelPair:match("^(.-)|(.*)$")

        for _, key in pairs({"tmp_" .. requestChannel, "tmp_ts_" .. requestChannel, "recCh_" .. requestChannel,
                             "msg_" .. requestChannel, "requestChannel_" .. requestChannel,
                             "responseChannel_" .. responseChannel}) do
            self.databank.clearValue(key)
        end
    end

    self.databank.clearValue("channels")
    self.receiver.setChannelList({})
end

function Socket:saveQueue()
    local queue = self.queue
    self.databank.setStringValue("queue", table.concat(queue, "\n"))
end

function Socket:loadQueue()
    self.queue = {}
    local savedQueue = self.databank.getStringValue("queue")
    for message in savedQueue:gmatch("[^\n]+") do
        table.insert(self.queue, message)
    end
end

function Socket:findChannel(channel)
    local channels = self.databank.getStringValue("channels")
    local channelPairs = Util.split(channels, ",")

    for _, channelPair in ipairs(channelPairs) do
        local requestChannel, responseChannel = channelPair:match("^(.-)|(.*)$")

        if channel == requestChannel or channel == responseChannel then
            return requestChannel, responseChannel
        end
    end

    return nil, nil
end

function Socket:getMessages(channels, sort)
    local pieces = {}
    if sort == nil then
        sort = "asc"
    end
    if channels == nil or #channels == 0 then
        channels = self:getChannels()
    end
    for _, channel in ipairs(channels) do
        local msg = Util.parse(self.databank.getStringValue("msg_" .. channel))
        if msg and type(msg) == "table" and next(msg) ~= nil then
            table.insert(pieces, msg)
        end
    end

    return pieces
end
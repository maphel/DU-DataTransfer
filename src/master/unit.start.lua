function onProgressChange(dto)
    system.print("Progress changed!")
    system.print(dto.channel)
    system.print(dto.chunk)
    system.print(dto.chunkIndex)
    system.print(dto.totalChunks)
end

function onFinish(dto)
    system.print("Progress finished!")
    system.print(dto.channel)
    system.print(dto.message)
    system.print(dto.chunkIndex)
    system.print(dto.totalChunks)
end

master = EchoCastMaster:new(onFinish, onProgressChange)
master:clearDB()
master:addRequest("req1", "res1")
master:addRequest("req2", "res2")
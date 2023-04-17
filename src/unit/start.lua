function onProgressChange(obj)
    screen.setRenderScript(drawProgress("Receiving data on " .. obj.channel  .. "...", obj.message, obj.queueDone, obj.queueTotal))
end

function onFinish(obj)
    screen.setRenderScript(drawProgress("Receiving data on " .. obj.channel  .. "...", obj.message, obj.queueDone, obj.queueTotal))
end

screen.setRenderScript(drawProgress("Receiving data ...", "-", 0, 2))
master = EchoCastMaster:new(onFinish, onProgressChange, true)
master:clearDB()
master:addRequest("req1", "res1")
master:addRequest("req2", "res2")
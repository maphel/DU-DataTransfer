Util = {}
local concat = table.concat
local sFormat=string.format

function Util.getUnits(isSlave)
    local emitter, databank, receiver
    for key, value in pairs(unit) do
        if type(value) == "table" and type(value.export) == "table" then
            if value.getClass then
                if value.getClass() == "EmitterUnit" then
                    emitter = value
                elseif value.getClass() == "ReceiverUnit" then
                    receiver = value
                elseif value.getClass() == "DataBankUnit" then
                        databank = value
                end
            end
        end
    end
    if databank == nil then
        system.print("No databank found")
    end
    if emitter == nil then
        system.print("No emitter found")
    end
    if receiver == nil and not isSlave then
        system.print("No receiver found")
    end
    if not (databank and emitter) or (receiver == nil and not isSlave) then
        system.print("Deactivating PB. Please connect the given units.")
        unit.exit()
      end
    return databank, emitter, receiver
end

local function internalSerialize(table, tC, t)
    t[tC] = "{"
    tC = tC + 1
    if #table == 0 then
        local hasValue = false
        for key, value in pairs(table) do
            hasValue = true
            local keyType = type(key)
            if keyType == "string" then
                t[tC] = sFormat("[%q]=", key)
            elseif keyType == "number" then
                t[tC] = "[" .. key .. "]="
            elseif keyType == "boolean" then
                t[tC] = "[" .. tostring(key) .. "]="
            else
                t[tC] = "notsupported="
            end
            tC = tC + 1

            local check = type(value)
            if check == "table" then
                tC = internalSerialize(value, tC, t)
            elseif check == "string" then
                t[tC] = sFormat("%q", value)
            elseif check == "number" then
                t[tC] = value
            elseif check == "boolean" then
                t[tC] = tostring(value)
            else
                t[tC] = '"Not Supported"'
            end
            t[tC + 1] = ","
            tC = tC + 2
        end
        if hasValue then
            tC = tC - 1
        end
    else
        for i = 1, #table do
            local value = table[i]
            local check = type(value)
            if check == "table" then
                tC = internalSerialize(value, tC, t)
            elseif check == "string" then
                t[tC] = sFormat("%q", value)
            elseif check == "number" then
                t[tC] = value
            elseif check == "boolean" then
                t[tC] = tostring(value)
            else
                t[tC] = '"Not Supported"'
            end
            t[tC + 1] = ","
            tC = tC + 2
        end
        tC = tC - 1
    end
    t[tC] = "}"
    return tC
end

function Util.splitMessage(message, maxLength)
    local chunks = {}

    local function createChunkString(index, total, content)
        return index .. "/" .. total .. "/" .. content
    end

    local function calculateTotalChunks(messageLength, maxLength)
        return math.ceil(messageLength / maxLength)
    end

    local messageLength = #message
    local totalChunks = calculateTotalChunks(messageLength, maxLength)

    local chunkStart = 1
    for i = 1, totalChunks do
        local chunkEnd = math.min(chunkStart + maxLength - 1, messageLength)
        local chunk = message:sub(chunkStart, chunkEnd)
        table.insert(chunks, createChunkString(i, totalChunks, chunk))
        chunkStart = chunkEnd + 1
    end

    return chunks
end

function Util.stringify(value)
    local t = {}
    local check = type(value)

    if check == "table" then
        internalSerialize(value, 1, t)
    elseif check == "string" then
        return sFormat("%q", value)
    elseif check == "number" then
        return value
    elseif check == "boolean" then
        return tostring(value)
    else
        return '"Not Supported"'
    end

    return concat(t)
end

function Util.parse(str)
    local f, err = load("return " .. str)
    if f then
        return f()
    else
        error("Failed to deserialize string: " .. err)
    end
end
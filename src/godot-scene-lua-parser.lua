local M = {}

local function isDescriptor(line)
    if line:sub(1, 1) == "[" and line:sub(-1) == "]" then
        return true
    end

    return false
end

local function isParamStart(line)
    if string.match(line, " = ") then
        return true
    end
end

local function isMultilineParam(line)
    if not string.match(line, " = \"") then
        return false
    end

    if (string.sub(line, -1) == "\"") and not (string.sub(line, -2) == "\\\"") then
        return false
    end

    return true
end

local function parseDescriptor(descriptor)
    local descriptorTable = {
    }
    descriptor = descriptor:sub(2, descriptor:len()-1)
    descriptorTable.resource_type = string.sub(descriptor, 1, string.find(descriptor, "%s")-1)
    local startPoint = string.find(descriptor, "%s")
    while string.find(descriptor, "=", startPoint) do
        local equalSign = string.find(descriptor, "=", startPoint)
        local endPoint

        if string.sub(descriptor, equalSign+1, equalSign+1) == "\"" then
            endPoint = (string.find(descriptor, "[^\\]\"", equalSign+1) or string.len(descriptor)-1) + 2   
        else
            endPoint = string.find(descriptor, "%s", equalSign) or string.len(descriptor)+1
        end

        local key = string.sub(descriptor, startPoint+1, equalSign-1)
        local value = string.sub(descriptor, equalSign+1, endPoint-1)

        descriptorTable[key] = value

        startPoint = endPoint or string.len(descriptor)
    end

    return descriptorTable
end

local function parseParam(scene, idx, line)
    local i = string.find(line, " = ")
    local k = string.sub(line, 1, i-1)
    local v = string.sub(line, i + 3)
    scene[idx].params = scene[idx].params or {}
    scene[idx].params[k] = v
    return k, v
end

local function appendParam(scene, idx, param, line)
    scene[idx].params[param] = scene[idx].params[param] .. line 
end

function M.parseScene(path)
    local description
    local descriptors = {}
    
    local mode = "auto" -- "auto" or "param"
    local param 
    local idx = 0
    local lineNo = 1


    for line in io.lines(path) do
        if mode == "auto" then
            if isDescriptor(line) then
                idx = idx + 1
                descriptors[idx] = parseDescriptor(line)
            elseif isParamStart(line) then
                if isMultilineParam(line) then
                    mode = "param"
                end
                param = parseParam(descriptors, idx, line)
            end
        elseif mode == "param" then
            appendParam(descriptors, idx, param, "\n")
            appendParam(descriptors, idx, param, line)
            if (string.sub(line, -1) == "\"") and (not (string.sub(line, -2) == "\\\"")) then
                mode = "auto"
            end
        end
        lineNo = lineNo + 1
    end

    local scene = {}

    for i, descriptor in pairs(descriptors) do
        if not scene[descriptor.resource_type] then
            scene[descriptor.resource_type] = {}
        end
        scene[descriptor.resource_type][#scene[descriptor.resource_type] + 1] = descriptor
    end

    return scene
end

return M
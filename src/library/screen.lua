function drawProgress(label, data, progress, maxProgress)
    return [[
function drawProgressBar(options)
    local screenWidth, screenHeight = getResolution()
    local progressBarWidth = screenWidth * 0.8
    local progressBarHeight = 30
    local progressBarX = (screenWidth - progressBarWidth) / 2
    local progressBarY = screenHeight / 2 - progressBarHeight / 2
    local progressLayer = createLayer()
    local textLayer = createLayer()

    setNextFillColor(progressLayer, options.backgroundColor[1], options.backgroundColor[2], options.backgroundColor[3], options.backgroundColor[4])
    addBox(progressLayer, progressBarX, progressBarY, progressBarWidth, progressBarHeight)

    local filledWidth = (options.progress / options.maxProgress) * progressBarWidth

    setNextFillColor(progressLayer, options.fillColor[1], options.fillColor[2], options.fillColor[3], options.fillColor[4])
    addBox(progressLayer, progressBarX, progressBarY, filledWidth, progressBarHeight)

    drawProgressText(textLayer, options, progressBarX, progressBarWidth, progressBarY, progressBarHeight)
    drawLabel(textLayer, options, screenHeight, screenWidth, progressBarHeight)
    drawCoordinates(textLayer, options, screenHeight, screenWidth, progressBarHeight)
    drawData(textLayer, options, screenHeight, screenWidth, progressBarHeight)
end

function drawProgressText(layer, options, progressBarX, progressBarWidth, progressBarY, progressBarHeight)
    local progressLayer = createLayer()
    local progressPercentage = math.floor((options.progress / options.maxProgress) * 100)
    local progressText = tostring(progressPercentage) .. "%"

    local font = loadFont(options.progressFont, options.progressFontSize)
    setNextFillColor(layer, options.progressPercentageColor[1], options.progressPercentageColor[2], options.progressPercentageColor[3], options.progressPercentageColor[4])
    setNextTextAlign(layer, AlignH_Center, AlignV_Middle)
    addText(layer, font, progressText, progressBarX + progressBarWidth / 2, progressBarY + progressBarHeight / 2)
end

function drawLabel(layer, options, screenHeight, screenWidth, progressBarHeight)
    local font = loadFont(options.labelFont, options.labelFontSize)
    setNextFillColor(layer, options.textColor[1], options.textColor[2], options.textColor[3], options.textColor[4])
    setNextTextAlign(layer, AlignH_Center, AlignV_Middle)
    addText(layer, font, options.label, screenWidth / 2, screenHeight / 2 - progressBarHeight * 2)
end

function drawCoordinates(layer, options, screenHeight, screenWidth, progressBarHeight)
    local font = loadFont(options.coordinatesFont, options.coordinatesFontSize)
    setNextFillColor(layer, options.textColor[1], options.textColor[2], options.textColor[3], options.textColor[4])
    setNextTextAlign(layer, AlignH_Center, AlignV_Middle)
    addText(layer, font, options.progress .. "/" .. options.maxProgress, screenWidth / 2, screenHeight / 2 + progressBarHeight * 2)
end

function drawData(layer, options, screenHeight, screenWidth, progressBarHeight)
    local subData = string.sub(options.data, 1, 75) .. "..."
    local font = loadFont(options.dataFont, options.dataFontSize)
    setNextFillColor(layer, options.textColor[1], options.textColor[2], options.textColor[3], options.textColor[4])
    setNextTextAlign(layer, AlignH_Center, AlignV_Middle)
    addText(layer, font, subData, screenWidth / 2, screenHeight / 2 + progressBarHeight * 3)
end

local options = {
        label = ']] .. label .. [[',
        data = ']] .. data .. [[',
        progress = ]] .. progress .. [[,
        maxProgress = ]] .. maxProgress .. [[,
        backgroundColor = {1, 1, 1, 0.2},
        fillColor = {1, 1, 1, 1},
        textColor = {1, 1, 1, 1},
        labelColor = {0/255, 255/255, 0/255, 1},
        progressPercentageColor = {0/255, 0/255, 0/255, 1},
        labelFont = "RobotoMono",
        labelFontSize = 24,
        progressFont = "RobotoMono",
        progressFontSize = 14,
        dataFont = "RobotoMono",
        dataFontSize = 14,
        coordinatesFont = "RobotoMono",
        coordinatesFontSize = 18,
    }
drawProgressBar(options)
]]
end

function drawText(data)
    return [[
function getTextWidth(font, text)
  local fontSize = getFontSize(font)
  local charWidth = fontSize / 2
  return charWidth * string.len(text)
end
    
function wrapText(text, font, width)
  local charWidth = getFontSize(font) / 1.5
  local maxCharsPerLine = math.floor(width / charWidth)

  local lines = {}
  for i = 1, #text, maxCharsPerLine do
    local line = text:sub(i, i + maxCharsPerLine - 1)
    table.insert(lines, line)
  end

  return lines
end

local layer = createLayer()
local screenWidth, screenHeight = getResolution()
local data = ']] .. data .. [['
local fontWidth = 12
local font = loadFont("RobotoMono", fontWidth)
local wrappedLines = wrapText(data, font, screenWidth)
local startY = 30
local lineHeight = fontWidth * 1.4

for i, line in ipairs(wrappedLines) do
  local yPos = startY + (i - 1) * lineHeight
  setNextTextAlign(layer, AlignH_Center, AlignV_Middle)
  addText(layer, font, line, screenWidth / 2, yPos)
end
]]
end
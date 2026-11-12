-- Dex Explorer PRIME Lite | Luau (single-file)
-- Explorer leve inspirado no painel de arvore do Dex++ de Chillz.
-- Sem dependencias externas, HttpGet, polling por frame ou modulos adicionais.
-- Otimizacoes: renderizacao virtualizada, expansao sob demanda, atualizacoes
-- agrupadas e busca com limite de resultados/processamento em lotes.
-- Inclui exportacao de selecao quando o executor disponibiliza saveinstance.
-- O arquivo sai no workspace do executor; nao ha dialogo nativo do Windows.
-- Nao substitui todos os recursos da versao completa do Dex++.

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local player = Players.LocalPlayer
local MAX_TREE_ENTRIES = 30000
local MAX_SEARCH_RESULTS = 350
local ROW_HEIGHT = 24
local SEARCH_BATCH = 800

local C = {
    bg = Color3.fromRGB(21, 23, 28),
    panel = Color3.fromRGB(28, 31, 38),
    darker = Color3.fromRGB(17, 19, 24),
    line = Color3.fromRGB(47, 51, 61),
    fg = Color3.fromRGB(235, 239, 245),
    muted = Color3.fromRGB(146, 155, 170),
    accent = Color3.fromRGB(69, 149, 244),
    selected = Color3.fromRGB(43, 77, 119),
}

local function ui(class, parent, props)
    local element = Instance.new(class)
    for property, value in pairs(props or {}) do
        element[property] = value
    end
    element.Parent = parent
    return element
end

local env = _G
pcall(function()
    if type(getgenv) == "function" then env = getgenv() end
end)
if type(env.DexExplorerPrimeLite) == "table" and type(env.DexExplorerPrimeLite.Destroy) == "function" then
    pcall(env.DexExplorerPrimeLite.Destroy)
end

local gui = ui("ScreenGui", nil, {
    Name = "DexExplorerPrimeLite", ResetOnSpawn = false,
    IgnoreGuiInset = true, ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
})
local hosted = false
pcall(function()
    if type(gethui) == "function" then
        local host = gethui()
        if typeof(host) == "Instance" then gui.Parent = host; hosted = true end
    end
end)
if not hosted then
    pcall(function()
        gui.Parent = game:GetService("CoreGui")
        hosted = true
    end)
end
if not hosted then
    gui.Parent = (player and player:WaitForChild("PlayerGui")) or error("PlayerGui indisponivel")
end

local camera = workspace.CurrentCamera
local viewport = camera and camera.ViewportSize or Vector2.new(1280, 720)
local width = math.max(320, math.min(900, viewport.X - 24))
local height = math.max(400, math.min(590, viewport.Y - 45))
local frame = ui("Frame", gui, {
    Name = "Window", BackgroundColor3 = C.bg, BorderSizePixel = 0,
    Position = UDim2.new(0.5, -width / 2, 0.5, -height / 2),
    Size = UDim2.fromOffset(width, height), Active = true,
})
ui("UICorner", frame, { CornerRadius = UDim.new(0, 7) })
ui("UIStroke", frame, { Color = C.line, Thickness = 1 })

local header = ui("Frame", frame, {
    Name = "TitleBar", Size = UDim2.new(1, 0, 0, 38),
    BackgroundColor3 = C.panel, BorderSizePixel = 0, Active = true,
})
ui("TextLabel", header, {
    Size = UDim2.new(1, -108, 1, 0), Position = UDim2.fromOffset(12, 0),
    BackgroundTransparency = 1, Text = "DEX EXPLORER  /  LITE EXPORT",
    TextColor3 = C.fg, Font = Enum.Font.GothamBold, TextSize = 14,
    TextXAlignment = Enum.TextXAlignment.Left,
})
local function makeButton(parent, title, position, size)
    local button = ui("TextButton", parent, {
        Text = title, Position = position, Size = size,
        BackgroundColor3 = C.panel, BorderSizePixel = 0,
        TextColor3 = C.fg, TextSize = 13,
        Font = Enum.Font.GothamSemibold, AutoButtonColor = true,
    })
    ui("UICorner", button, { CornerRadius = UDim.new(0, 4) })
    ui("UIStroke", button, { Color = C.line, Thickness = 1 })
    return button
end
local minButton = makeButton(header, "–", UDim2.new(1, -70, 0, 7), UDim2.fromOffset(27, 24))
local closeButton = makeButton(header, "×", UDim2.new(1, -36, 0, 7), UDim2.fromOffset(27, 24))

local toolbar = ui("Frame", frame, {
    Name = "SearchBar", Position = UDim2.fromOffset(8, 45),
    Size = UDim2.new(1, -16, 0, 31), BackgroundTransparency = 1,
})
local searchBox = ui("TextBox", toolbar, {
    Name = "Search", Position = UDim2.fromOffset(0, 0),
    Size = UDim2.new(1, -96, 0, 29), Text = "", ClearTextOnFocus = false,
    PlaceholderText = "Pesquisar instancias (nome)...",
    BackgroundColor3 = C.darker, BorderSizePixel = 0,
    TextColor3 = C.fg, PlaceholderColor3 = C.muted,
    Font = Enum.Font.Gotham, TextSize = 13,
    TextXAlignment = Enum.TextXAlignment.Left,
})
ui("UICorner", searchBox, { CornerRadius = UDim.new(0, 4) })
ui("UIPadding", searchBox, { PaddingLeft = UDim.new(0, 9) })
local refreshButton = makeButton(toolbar, "Atualizar", UDim2.new(1, -90, 0, 0), UDim2.fromOffset(90, 29))

local body = ui("Frame", frame, {
    Name = "Body", Position = UDim2.fromOffset(8, 82),
    Size = UDim2.new(1, -16, 1, -104), BackgroundTransparency = 1,
})
local treePane = ui("Frame", body, {
    Name = "Explorer", Size = UDim2.new(0.64, -5, 1, 0),
    BackgroundColor3 = C.darker, BorderSizePixel = 0,
})
ui("UIStroke", treePane, { Color = C.line, Thickness = 1 })
local scroll = ui("ScrollingFrame", treePane, {
    Name = "VirtualTree", Size = UDim2.fromScale(1, 1),
    BackgroundTransparency = 1, BorderSizePixel = 0,
    CanvasSize = UDim2.fromOffset(0, 0), ScrollBarThickness = 5,
    ScrollBarImageColor3 = C.muted, ScrollingDirection = Enum.ScrollingDirection.Y,
    AutomaticCanvasSize = Enum.AutomaticSize.None, ClipsDescendants = true,
})
local inspector = ui("Frame", body, {
    Name = "Properties", Position = UDim2.new(0.64, 3, 0, 0),
    Size = UDim2.new(0.36, -3, 1, 0),
    BackgroundColor3 = C.panel, BorderSizePixel = 0,
})
ui("UIStroke", inspector, { Color = C.line, Thickness = 1 })
-- Abas: inspector e exportador sao criados uma so vez, sem redesenho constante.
local propertiesTab = makeButton(inspector, "PROPRIEDADES", UDim2.fromOffset(8, 8), UDim2.new(0.5, -12, 0, 27))
local exportTab = makeButton(inspector, "EXPORTAR RBXM", UDim2.new(0.5, 4, 0, 8), UDim2.new(0.5, -12, 0, 27))
local propertiesPane = ui("Frame", inspector, {
    Name = "InspectPanel", Position = UDim2.fromOffset(0, 42),
    Size = UDim2.new(1, 0, 1, -42), BackgroundTransparency = 1,
})
local exportPane = ui("Frame", inspector, {
    Name = "ExportPanel", Position = UDim2.fromOffset(0, 42),
    Size = UDim2.new(1, 0, 1, -42), BackgroundTransparency = 1, Visible = false,
})
local nameEdit = ui("TextBox", propertiesPane, {
    Name = "Rename", Position = UDim2.fromOffset(10, 10),
    Size = UDim2.new(1, -20, 0, 31), Text = "", ClearTextOnFocus = false,
    BackgroundColor3 = C.darker, BorderSizePixel = 0,
    TextColor3 = C.fg, Font = Enum.Font.Gotham, TextSize = 13,
    TextXAlignment = Enum.TextXAlignment.Left,
})
ui("UIPadding", nameEdit, { PaddingLeft = UDim.new(0, 7) })
ui("UICorner", nameEdit, { CornerRadius = UDim.new(0, 4) })
ui("TextLabel", propertiesPane, {
    Position = UDim2.fromOffset(10, 45), Size = UDim2.new(1, -20, 0, 18),
    BackgroundTransparency = 1, Text = "Enter para renomear", Font = Enum.Font.Gotham,
    TextSize = 11, TextColor3 = C.muted, TextXAlignment = Enum.TextXAlignment.Left,
})
local info = ui("TextLabel", propertiesPane, {
    Name = "Details", Position = UDim2.fromOffset(10, 77),
    Size = UDim2.new(1, -20, 1, -180), BackgroundTransparency = 1,
    Text = "Selecione uma instancia", TextColor3 = C.fg,
    Font = Enum.Font.Code, TextSize = 12,
    TextXAlignment = Enum.TextXAlignment.Left,
    TextYAlignment = Enum.TextYAlignment.Top, TextWrapped = true,
})
local pathButton = makeButton(propertiesPane, "Copiar caminho", UDim2.new(0, 10, 1, -79), UDim2.new(1, -20, 0, 30))
local codeButton = makeButton(propertiesPane, "Copiar codigo Lua", UDim2.new(0, 10, 1, -41), UDim2.new(1, -20, 0, 30))

local function exportLabel(text, y, height)
    return ui("TextLabel", exportPane, {
        Position = UDim2.fromOffset(10, y), Size = UDim2.new(1, -20, 0, height or 18),
        BackgroundTransparency = 1, Text = text, Font = Enum.Font.Gotham,
        TextSize = 11, TextColor3 = C.muted,
        TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Center,
        TextTruncate = Enum.TextTruncate.AtEnd,
    })
end
local exportSelectionLabel = exportLabel("Selecione um modelo na arvore", 7, 26)
exportSelectionLabel.TextColor3 = C.fg
local fileLabel = exportLabel("Nome do arquivo (nome original por padrao)", 46)
local exportName = ui("TextBox", exportPane, {
    Name = "ExportFileName", Position = UDim2.fromOffset(10, 67),
    Size = UDim2.new(1, -20, 0, 29), Text = "", ClearTextOnFocus = false,
    BackgroundColor3 = C.darker, BorderSizePixel = 0,
    TextColor3 = C.fg, Font = Enum.Font.Gotham, TextSize = 12,
    TextXAlignment = Enum.TextXAlignment.Left,
})
ui("UICorner", exportName, { CornerRadius = UDim.new(0, 4) })
ui("UIPadding", exportName, { PaddingLeft = UDim.new(0, 8) })
local folderLabel = exportLabel("Pasta dentro do workspace do executor", 107)
local exportFolder = ui("TextBox", exportPane, {
    Name = "ExportFolder", Position = UDim2.fromOffset(10, 128),
    Size = UDim2.new(1, -20, 0, 29), Text = "DexLite/Models", ClearTextOnFocus = false,
    BackgroundColor3 = C.darker, BorderSizePixel = 0,
    TextColor3 = C.fg, Font = Enum.Font.Gotham, TextSize = 12,
    TextXAlignment = Enum.TextXAlignment.Left,
})
ui("UICorner", exportFolder, { CornerRadius = UDim.new(0, 4) })
ui("UIPadding", exportFolder, { PaddingLeft = UDim.new(0, 8) })
exportLabel("Formato do modelo", 171)
local formatButton = makeButton(exportPane, "RBXM  -  binario", UDim2.fromOffset(10, 190), UDim2.new(1, -20, 0, 29))
local exportHelp = ui("TextLabel", exportPane, {
    Position = UDim2.fromOffset(10, 231), Size = UDim2.new(1, -20, 0, 48),
    BackgroundTransparency = 1,
    Text = "Sem seletor de pastas do Windows. Digite uma subpasta do workspace do executor.",
    TextColor3 = C.muted, Font = Enum.Font.Gotham, TextSize = 11,
    TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left,
    TextYAlignment = Enum.TextYAlignment.Top,
})
local exportStatus = ui("TextLabel", exportPane, {
    Position = UDim2.new(0, 10, 1, -122), Size = UDim2.new(1, -20, 0, 35),
    BackgroundTransparency = 1,
    Text = "Requer funcao saveinstance compativel.",
    TextColor3 = C.muted, Font = Enum.Font.Gotham, TextSize = 11,
    TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left,
})
local saveButton = makeButton(exportPane, "Exportar modelo selecionado", UDim2.new(0, 10, 1, -81), UDim2.new(1, -20, 0, 32))
local savedPathButton = makeButton(exportPane, "Copiar caminho do ultimo arquivo", UDim2.new(0, 10, 1, -42), UDim2.new(1, -20, 0, 30))

local function selectTab(exportMode)
    exportPane.Visible = exportMode
    propertiesPane.Visible = not exportMode
    exportTab.BackgroundColor3 = exportMode and C.selected or C.panel
    propertiesTab.BackgroundColor3 = exportMode and C.panel or C.selected
end
selectTab(false)
local status = ui("TextLabel", frame, {
    Position = UDim2.new(0, 12, 1, -19), Size = UDim2.new(1, -24, 0, 17),
    Text = "Carregando...", BackgroundTransparency = 1,
    Font = Enum.Font.Gotham, TextSize = 11, TextColor3 = C.muted,
    TextXAlignment = Enum.TextXAlignment.Left,
})

-- Estruturas do explorer. Expansao so consulta GetChildren quando necessaria.
local expanded = setmetatable({ [game] = true }, { __mode = "k" })
local hasChildren = setmetatable({}, { __mode = "k" })
local watchers = {}
local connections = {}
local pool = {}
local displayed = {}
local selected = game
local closed = false
local isSearching = false
local query = ""
local searchGeneration = 0
local searchEditGeneration = 0
local rebuildScheduled = false
local truncated = false
local renderVisible, rebuildTree, runSearch, showInfo

local function bind(signal, callback)
    local connection = signal:Connect(callback)
    connections[#connections + 1] = connection
    return connection
end

local function pathOf(instance)
    local ok, result = pcall(function() return instance:GetFullName() end)
    return ok and result or tostring(instance.Name)
end

local function codePath(instance)
    local pieces = {}
    local node = instance
    local steps = 0
    while node and node ~= game and steps < 128 do
        table.insert(pieces, 1, "[" .. string.format("%q", node.Name) .. "]")
        node = node.Parent
        steps = steps + 1
    end
    return "game" .. table.concat(pieces)
end

local function setStatus(message)
    status.Text = message
end

-- A exportacao depende de saveinstance disponibilizado pelo executor.
-- Os arquivos sao gravados no workspace do executor, nao numa pasta arbitraria do Windows.
local exportBinary = true
local exporting = false
local lastSavedPath = nil
local function cleanName(value)
    local stem = tostring(value or ""):gsub('[<>:"/\\|%?%*%c]', "_")
    stem = stem:gsub("^%s+", ""):gsub("%s+$", "")
    stem = stem:gsub("[%. ]+$", "")
    if stem == "" or stem == "." or stem == ".." then stem = "Modelo" end
    return stem:sub(1, 120)
end

local function validFolder(text)
    local input = tostring(text or ""):gsub("\\", "/")
    input = input:gsub("^%s+", ""):gsub("%s+$", ""):gsub("/+", "/")
    input = input:gsub("/+$", "")
    if input == "" then return nil, "Digite uma pasta relativa" end
    if input:sub(1, 1) == "/" or input:find(":", 1, true) then
        return nil, "Use uma pasta relativa ao workspace"
    end
    local parts = {}
    for part in input:gmatch("[^/]+") do
        if part == "." or part == ".." or part:find('[%c<>"|%?%*]') then
            return nil, "Nome de pasta invalido"
        end
        table.insert(parts, part)
    end
    if #parts == 0 then return nil, "Pasta invalida" end
    return table.concat(parts, "/"), parts
end

local function ensureFolder(parts)
    if type(makefolder) ~= "function" then
        return false, "Seu executor nao oferece makefolder"
    end
    local path = ""
    for _, part in ipairs(parts) do
        path = (path == "" and part) or (path .. "/" .. part)
        local exists = false
        if type(isfolder) == "function" then
            local ok, value = pcall(isfolder, path)
            exists = ok and value == true
        end
        if not exists then
            local ok, reason = pcall(makefolder, path)
            if not ok then
                local confirmed = false
                if type(isfolder) == "function" then
                    local checked, value = pcall(isfolder, path)
                    confirmed = checked and value == true
                end
                if not confirmed then return false, tostring(reason) end
            end
        end
    end
    return true
end

local function syncExportSelection()
    if not selected then return end
    exportName.Text = cleanName(selected.Name)
    exportSelectionLabel.Text = selected.Name .. "  [" .. selected.ClassName .. "]"
    exportSelectionLabel.TextColor3 = selected == game and C.muted or C.fg
end

local function getExporter()
    if type(saveinstance) == "function" then return saveinstance end
    if type(SaveInstance) == "function" then return SaveInstance end
    if type(syn) == "table" and type(syn.saveinstance) == "function" then return syn.saveinstance end
    if type(env) == "table" then
        if type(env.saveinstance) == "function" then return env.saveinstance end
        if type(env.SaveInstance) == "function" then return env.SaveInstance end
    end
    return nil
end

local function setExportStatus(message, failed)
    if closed then return end
    exportStatus.Text = message
    exportStatus.TextColor3 = failed and Color3.fromRGB(255, 155, 144) or C.muted
    setStatus(message)
end

local function exportSelected()
    if closed or exporting then return end
    local obj = selected
    if not obj or obj == game then
        return setExportStatus("Selecione um modelo, pasta ou instancia antes de exportar", true)
    end
    local exporter = getExporter()
    if not exporter then
        return setExportStatus("Exportacao indisponivel: seu executor nao possui saveinstance", true)
    end
    local folder, partsOrError = validFolder(exportFolder.Text)
    if not folder then return setExportStatus(partsOrError, true) end
    local stem = exportName.Text:gsub("%.[Rr][Bb][Xx][Mm][Xx]?$", "")
    stem = cleanName(stem)
    exportName.Text = stem
    local extension = exportBinary and ".rbxm" or ".rbxmx"
    local fullPath = folder .. "/" .. stem .. extension
    -- Evita sobrescrever arquivos existentes, caso isfile esteja disponivel.
    if type(isfile) == "function" then
        local index = 2
        while index <= 100 do
            local ok, exists = pcall(isfile, fullPath)
            if not (ok and exists) then break end
            fullPath = folder .. "/" .. stem .. " (" .. index .. ")" .. extension
            index = index + 1
        end
        if index > 100 then return setExportStatus("Existem muitos arquivos com esse nome", true) end
    end
    exporting = true
    saveButton.Text = "Exportando..."
    setExportStatus("Preparando pasta e exportando " .. stem .. "...", false)
    task.spawn(function()
        local made, reason = ensureFolder(partsOrError)
        if not made then
            exporting = false
            saveButton.Text = "Exportar modelo selecionado"
            return setExportStatus("Nao consegui criar a pasta: " .. tostring(reason), true)
        end
        -- Nunca chamar sem uma Instance: em algumas APIs isso exportaria o jogo inteiro.
        local options = {
            Object = obj, IsModel = true,
            FilePath = fullPath, FileName = fullPath,
            Binary = exportBinary,
            Decompile = false, DecompileScripts = false,
            ReadMe = false, ShowStatus = false,
            AvoidFileOverwrite = false,
        }
        local ok, result = pcall(exporter, obj, options)
        exporting = false
        if closed then return end
        saveButton.Text = "Exportar modelo selecionado"
        if not ok then
            return setExportStatus("Falha no saveinstance: " .. tostring(result):sub(1, 115), true)
        end
        local actualPath = type(result) == "string" and result or fullPath
        if type(isfile) == "function" then
            local verified, exists = pcall(isfile, actualPath)
            if not (verified and exists) then
                local check, existsRequested = pcall(isfile, fullPath)
                if check and existsRequested then
                    actualPath = fullPath
                else
                    return setExportStatus("Exportador terminou, mas nao foi possivel confirmar o arquivo", true)
                end
            end
        end
        lastSavedPath = actualPath
        setExportStatus("Arquivo exportado: " .. actualPath, false)
    end)
end

local function closeWatchers()
    for node, pair in pairs(watchers) do
        for _, connection in ipairs(pair) do connection:Disconnect() end
        watchers[node] = nil
    end
end

local function destroy()
    if closed then return end
    closed = true
    searchGeneration = searchGeneration + 1
    searchEditGeneration = searchEditGeneration + 1
    closeWatchers()
    for _, connection in ipairs(connections) do connection:Disconnect() end
    gui:Destroy()
    if env.DexExplorerPrimeLite and env.DexExplorerPrimeLite.Destroy == destroy then
        env.DexExplorerPrimeLite = nil
    end
end

env.DexExplorerPrimeLite = { Destroy = destroy, Gui = gui, Version = "2.0-Lite-Export" }

local function syncCanvas()
    scroll.CanvasSize = UDim2.fromOffset(0, #displayed * ROW_HEIGHT)
    local maxY = math.max(0, #displayed * ROW_HEIGHT - scroll.AbsoluteSize.Y)
    if scroll.CanvasPosition.Y > maxY then
        scroll.CanvasPosition = Vector2.new(0, maxY)
    end
    renderVisible()
end

local function requestRebuild()
    if rebuildScheduled or closed or isSearching then return end
    rebuildScheduled = true
    task.delay(0.12, function()
        rebuildScheduled = false
        if not closed and not isSearching then rebuildTree() end
    end)
end

local function setWatcher(node)
    if watchers[node] then return end
    local function onChild(child)
        hasChildren[node] = nil
        -- O watcher observa somente pais expandidos.
        requestRebuild()
    end
    watchers[node] = {
        node.ChildAdded:Connect(onChild),
        node.ChildRemoved:Connect(onChild),
    }
end

rebuildTree = function()
    if closed or isSearching then return end
    local entries = {}
    local tracked = {}
    local stack = { { inst = game, depth = 0 } }
    truncated = false

    while #stack > 0 do
        if #entries >= MAX_TREE_ENTRIES then
            truncated = true
            break
        end
        local entry = stack[#stack]
        stack[#stack] = nil
        entries[#entries + 1] = entry
        local node = entry.inst
        if expanded[node] then
            tracked[node] = true
            local ok, children = pcall(function() return node:GetChildren() end)
            if ok then
                hasChildren[node] = #children > 0
                for i = #children, 1, -1 do
                    stack[#stack + 1] = { inst = children[i], depth = entry.depth + 1 }
                end
            end
        end
    end

    for node, pair in pairs(watchers) do
        if not tracked[node] then
            for _, conn in ipairs(pair) do conn:Disconnect() end
            watchers[node] = nil
        end
    end
    for node in pairs(tracked) do setWatcher(node) end

    displayed = entries
    setStatus(string.format("Explorer: %d instancias visiveis%s", #entries,
        truncated and " (limite de seguranca)" or ""))
    syncCanvas()
end

local function toggleExpanded(entry)
    if closed or isSearching then return end
    local node = entry.inst
    if expanded[node] then
        expanded[node] = nil
    else
        local ok, children = pcall(function() return node:GetChildren() end)
        if not ok or #children == 0 then
            hasChildren[node] = false
            renderVisible()
            return
        end
        hasChildren[node] = true
        expanded[node] = true
    end
    rebuildTree()
end

local function makeRow()
    local row = ui("TextButton", scroll, {
        Name = "VirtualRow", Size = UDim2.new(1, -6, 0, ROW_HEIGHT),
        BackgroundTransparency = 1, BorderSizePixel = 0,
        Text = "", AutoButtonColor = false,
    })
    local arrow = ui("TextButton", row, {
        Name = "Expand", BackgroundTransparency = 1,
        Position = UDim2.fromOffset(4, 1), Size = UDim2.fromOffset(20, 22),
        Text = "▸", Font = Enum.Font.GothamBold, TextSize = 16,
        TextColor3 = C.muted, AutoButtonColor = false,
    })
    local title = ui("TextLabel", row, {
        Name = "InstanceName", BackgroundTransparency = 1,
        Position = UDim2.fromOffset(28, 0), Size = UDim2.new(1, -94, 1, 0),
        Text = "", Font = Enum.Font.Gotham, TextSize = 12,
        TextColor3 = C.fg, TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
    })
    local classname = ui("TextLabel", row, {
        Name = "Class", BackgroundTransparency = 1,
        Position = UDim2.new(1, -87, 0, 0), Size = UDim2.fromOffset(80, ROW_HEIGHT),
        Text = "", Font = Enum.Font.Code, TextSize = 10,
        TextColor3 = C.muted, TextXAlignment = Enum.TextXAlignment.Right,
        TextTruncate = Enum.TextTruncate.AtEnd,
    })
    local ref = { button = row, arrow = arrow, title = title, classname = classname, entry = nil }
    bind(row.Activated, function()
        local entry = ref.entry
        if entry and not closed then
            selected = entry.inst
            showInfo()
            renderVisible()
        end
    end)
    bind(arrow.Activated, function()
        local entry = ref.entry
        if entry and not isSearching then toggleExpanded(entry) end
    end)
    pool[#pool + 1] = ref
end

local function ensurePool()
    local needed = math.ceil(math.max(scroll.AbsoluteSize.Y, 250) / ROW_HEIGHT) + 4
    while #pool < needed do makeRow() end
end

renderVisible = function()
    if closed then return end
    ensurePool()
    local first = math.max(1, math.floor(scroll.CanvasPosition.Y / ROW_HEIGHT) + 1)
    for index, ref in ipairs(pool) do
        local rowIndex = first + index - 1
        local entry = displayed[rowIndex]
        ref.entry = entry
        local row = ref.button
        if entry then
            local obj = entry.inst
            local depth = isSearching and 0 or math.min(30, entry.depth)
            local indent = depth * 15
            row.Visible = true
            row.Position = UDim2.fromOffset(0, (rowIndex - 1) * ROW_HEIGHT)
            row.BackgroundColor3 = obj == selected and C.selected or C.panel
            row.BackgroundTransparency = obj == selected and 0 or ((rowIndex % 2 == 0) and 0.70 or 1)
            ref.arrow.Position = UDim2.fromOffset(indent + 3, 1)
            local childState = hasChildren[obj]
            if not isSearching and not expanded[obj] and childState == nil then
                local ok, children = pcall(function() return obj:GetChildren() end)
                childState = ok and #children > 0 or false
                hasChildren[obj] = childState
            end
            ref.arrow.Visible = not isSearching and (expanded[obj] or childState == true)
            ref.arrow.Text = expanded[obj] and "▾" or "▸"
            ref.title.Position = UDim2.fromOffset(indent + 26, 0)
            ref.title.Size = UDim2.new(1, -(indent + 113), 1, 0)
            ref.title.Text = obj.Name
            ref.title.TextColor3 = (obj == game) and C.accent or C.fg
            ref.classname.Text = obj.ClassName
        else
            row.Visible = false
        end
    end
end

local function safeValue(instance, property)
    local ok, value = pcall(function() return instance[property] end)
    return ok and tostring(value) or nil
end

showInfo = function()
    if closed then return end
    local obj = selected
    if not obj then return end
    syncExportSelection()
    nameEdit.Text = obj.Name
    nameEdit.TextEditable = obj ~= game
    local lines = {
        "Classe: " .. obj.ClassName,
        "Pai: " .. ((obj.Parent and obj.Parent.Name) or "nenhum"),
        "",
        "Caminho:",
        pathOf(obj),
    }
    if obj:IsA("BasePart") then
        lines[#lines + 1] = ""
        lines[#lines + 1] = "Posicao: " .. (safeValue(obj, "Position") or "N/D")
        lines[#lines + 1] = "Tamanho: " .. (safeValue(obj, "Size") or "N/D")
        lines[#lines + 1] = "Anchored: " .. (safeValue(obj, "Anchored") or "N/D")
    elseif obj:IsA("ValueBase") then
        local value = safeValue(obj, "Value")
        if value then
            lines[#lines + 1] = ""
            lines[#lines + 1] = "Value: " .. value
        end
    end
    info.Text = table.concat(lines, "\n")
end

runSearch = function(term)
    if closed then return end
    searchGeneration = searchGeneration + 1
    local generation = searchGeneration
    query = term
    isSearching = term ~= ""
    if not isSearching then
        scroll.CanvasPosition = Vector2.new(0, 0)
        rebuildTree()
        return
    end
    term = string.lower(term)
    displayed = {}
    syncCanvas()
    setStatus("Pesquisando... (max. " .. MAX_SEARCH_RESULTS .. " resultados)")
    task.spawn(function()
        -- DFS sob demanda: evita alocar game:GetDescendants() inteiro.
        local stack = { game }
        local found = {}
        local scanned = 0
        while #stack > 0 do
            if closed or generation ~= searchGeneration then return end
            local obj = stack[#stack]
            stack[#stack] = nil
            scanned = scanned + 1
            if obj ~= game and obj ~= gui and string.find(string.lower(obj.Name), term, 1, true) then
                found[#found + 1] = { inst = obj, depth = 0 }
                if #found >= MAX_SEARCH_RESULTS then break end
            end
            -- Nao analisar nossa propria interface.
            if obj ~= gui then
                local ok, children = pcall(function() return obj:GetChildren() end)
                if ok then
                    for j = #children, 1, -1 do stack[#stack + 1] = children[j] end
                end
            end
            if scanned % SEARCH_BATCH == 0 then task.wait() end
        end
        if closed or generation ~= searchGeneration then return end
        displayed = found
        scroll.CanvasPosition = Vector2.new(0, 0)
        syncCanvas()
        setStatus(string.format("Busca: %d encontrados / %d analisados%s", #found, scanned,
            #found == MAX_SEARCH_RESULTS and " (limite atingido)" or ""))
    end)
end

local function copyToClipboard(value)
    local done = false
    pcall(function()
        local clipboard = setclipboard or toclipboard
        if type(clipboard) == "function" then
            clipboard(value)
            done = true
        end
    end)
    if done then
        setStatus("Copiado para a area de transferencia")
    else
        setStatus("Clipboard indisponivel neste executor")
    end
end

bind(propertiesTab.Activated, function() selectTab(false) end)
bind(exportTab.Activated, function() selectTab(true) end)
bind(formatButton.Activated, function()
    exportBinary = not exportBinary
    formatButton.Text = exportBinary and "RBXM  -  binario" or "RBXMX  -  XML"
end)
bind(saveButton.Activated, exportSelected)
bind(savedPathButton.Activated, function()
    if lastSavedPath then
        copyToClipboard(lastSavedPath)
    else
        setExportStatus("Nenhum arquivo exportado nesta sessao", true)
    end
end)

bind(searchBox:GetPropertyChangedSignal("Text"), function()
    searchEditGeneration = searchEditGeneration + 1
    local token = searchEditGeneration
    task.delay(0.23, function()
        if closed or token ~= searchEditGeneration then return end
        runSearch((searchBox.Text:gsub("^%s+", ""):gsub("%s+$", "")))
    end)
end)
bind(refreshButton.Activated, function()
    hasChildren = setmetatable({}, { __mode = "k" })
    if isSearching then runSearch(query) else rebuildTree() end
end)
bind(nameEdit.FocusLost, function(enterPressed)
    if not enterPressed or closed or selected == game then
        showInfo()
        return
    end
    local desiredName = nameEdit.Text
    if desiredName ~= "" then
        local ok = pcall(function() selected.Name = desiredName end)
        if not ok then setStatus("Nao foi possivel renomear esta instancia") end
    end
    if isSearching then runSearch(query) else rebuildTree() end
    showInfo()
end)
bind(pathButton.Activated, function() copyToClipboard(pathOf(selected)) end)
bind(codeButton.Activated, function() copyToClipboard(codePath(selected)) end)
bind(closeButton.Activated, destroy)

local minimized = false
local normalSize = frame.Size
bind(minButton.Activated, function()
    minimized = not minimized
    toolbar.Visible = not minimized
    body.Visible = not minimized
    status.Visible = not minimized
    frame.Size = minimized and UDim2.fromOffset(300, 38) or normalSize
    minButton.Text = minimized and "+" or "–"
    if not minimized then task.defer(renderVisible) end
end)

-- Arrastar a janela pelo cabecalho.
local dragging = false
local dragStart, windowStart
bind(header.InputBegan, function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        windowStart = frame.Position
        local changed
        changed = input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
                changed:Disconnect()
            end
        end)
    end
end)
bind(UserInputService.InputChanged, function(input)
    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - dragStart
        frame.Position = UDim2.new(windowStart.X.Scale, windowStart.X.Offset + delta.X,
            windowStart.Y.Scale, windowStart.Y.Offset + delta.Y)
    end
end)

local drawPending = false
bind(scroll:GetPropertyChangedSignal("CanvasPosition"), function()
    if drawPending then return end
    drawPending = true
    task.defer(function()
        drawPending = false
        if not closed then renderVisible() end
    end)
end)
bind(scroll:GetPropertyChangedSignal("AbsoluteSize"), function()
    task.defer(function()
        if not closed then renderVisible() end
    end)
end)

showInfo()
rebuildTree()

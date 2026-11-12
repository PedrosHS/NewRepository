-- Dex Explorer TURBO | Luau (single-file)
-- Explorer leve inspirado no painel de arvore do Dex++ de Chillz.
-- Sem dependencias externas, HttpGet, polling por frame ou modulos adicionais.
-- Otimizacoes: renderizacao virtualizada, expansao sob demanda, atualizacoes
-- agrupadas e busca com limite de resultados/processamento em lotes.
-- Workspace sob demanda: percorre a arvore em fatias com cancelamento.
-- O arquivo sai no workspace do executor; nao ha dialogo nativo do Windows.
-- Nao substitui o Dex++ inteiro: sem decompilador, editor de scripts ou RemoteSpy.
-- Mudancas locais no cliente nao alteram o servidor. Exportacao opcional pode causar lag.

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local player = Players.LocalPlayer
local MAX_TREE_ENTRIES = 8000
local MAX_SEARCH_RESULTS = 400
local MAX_SEARCH_SCANNED = 60000
local ROW_HEIGHT = 24
local SEARCH_BATCH = 120
local TREE_BATCH = 160
local SLICE_SECONDS = 0.003

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
for _, oldName in ipairs({"DexExplorerTurbo", "DexExplorerPrimeLite"}) do
    local old = env[oldName]
    if type(old) == "table" and type(old.Destroy) == "function" then
        pcall(old.Destroy)
    end
end

local gui = ui("ScreenGui", nil, {
    Name = "DexExplorerTurbo", ResetOnSpawn = false,
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
    BackgroundTransparency = 1, Text = "DEX EXPLORER  /  TURBO",
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
    Size = UDim2.new(1, -178, 0, 29), Text = "", ClearTextOnFocus = false,
    PlaceholderText = "Pesquisar instancias (nome)...",
    BackgroundColor3 = C.darker, BorderSizePixel = 0,
    TextColor3 = C.fg, PlaceholderColor3 = C.muted,
    Font = Enum.Font.Gotham, TextSize = 13,
    TextXAlignment = Enum.TextXAlignment.Left,
})
ui("UICorner", searchBox, { CornerRadius = UDim.new(0, 4) })
ui("UIPadding", searchBox, { PaddingLeft = UDim.new(0, 9) })
local scopeButton = makeButton(toolbar, "MAPA", UDim2.new(1, -173, 0, 0), UDim2.fromOffset(78, 29))
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
    Size = UDim2.new(1, -20, 1, -350), BackgroundTransparency = 1,
    Text = "Selecione uma instancia", TextColor3 = C.fg,
    Font = Enum.Font.Code, TextSize = 12,
    TextXAlignment = Enum.TextXAlignment.Left,
    TextYAlignment = Enum.TextYAlignment.Top, TextWrapped = true,
})
local propLabel = ui("TextLabel", propertiesPane, {
    Position = UDim2.new(0, 10, 1, -250), Size = UDim2.new(1, -20, 0, 16),
    Text = "Editar propriedade (Name, Transparency, Anchored...)",
    BackgroundTransparency = 1, TextColor3 = C.muted,
    Font = Enum.Font.Gotham, TextSize = 10, TextXAlignment = Enum.TextXAlignment.Left,
})
local propName = ui("TextBox", propertiesPane, {
    Position = UDim2.new(0, 10, 1, -228), Size = UDim2.new(0.5, -14, 0, 26),
    BackgroundColor3 = C.darker, BorderSizePixel = 0,
    Text = "Transparency", ClearTextOnFocus = false, TextColor3 = C.fg,
    Font = Enum.Font.Gotham, TextSize = 12,
})
local propValue = ui("TextBox", propertiesPane, {
    Position = UDim2.new(0.5, 3, 1, -228), Size = UDim2.new(0.5, -13, 0, 26),
    BackgroundColor3 = C.darker, BorderSizePixel = 0,
    Text = "0.5", ClearTextOnFocus = false, TextColor3 = C.fg,
    Font = Enum.Font.Gotham, TextSize = 12,
})
local applyProp = makeButton(propertiesPane, "Aplicar propriedade", UDim2.new(0, 10, 1, -196), UDim2.new(1, -20, 0, 27))
local pathButton = makeButton(propertiesPane, "Copiar caminho", UDim2.new(0, 10, 1, -159), UDim2.new(0.5, -13, 0, 30))
local codeButton = makeButton(propertiesPane, "Copiar codigo", UDim2.new(0.5, 3, 1, -159), UDim2.new(0.5, -13, 0, 30))
local focusButton = makeButton(propertiesPane, "Focar", UDim2.new(0, 10, 1, -122), UDim2.new(1, -20, 0, 30))
local duplicateButton = makeButton(propertiesPane, "Duplicar", UDim2.new(0, 10, 1, -84), UDim2.new(0.5, -13, 0, 30))
local deleteButton = makeButton(propertiesPane, "Excluir", UDim2.new(0.5, 3, 1, -84), UDim2.new(0.5, -13, 0, 30))

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
    Text = "Exportacao e opcional, exige saveinstance e pode causar lag em mapas grandes. Sem seletor de pastas do Windows.",
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
local expanded = setmetatable({ [game] = true, [workspace] = true }, { __mode = "k" })
local hasChildren = setmetatable({}, { __mode = "k" })
local watchers = {} -- mantido para compatibilidade de limpeza; nao cria listeners
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
local treeGeneration = 0
local workspaceOnly = true
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
    if not obj or obj == game or obj == workspace then
        return setExportStatus("Escolha um modelo/parte, nao o Workspace inteiro (pode travar)", true)
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
    setExportStatus("Exportando selecao. Modelos grandes podem pausar o jogo...", false)
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
    treeGeneration = treeGeneration + 1
    searchEditGeneration = searchEditGeneration + 1
    closeWatchers()
    for _, connection in ipairs(connections) do connection:Disconnect() end
    gui:Destroy()
    if env.DexExplorerTurbo and env.DexExplorerTurbo.Destroy == destroy then
        env.DexExplorerTurbo = nil
    end
end

env.DexExplorerTurbo = { Destroy = destroy, Gui = gui, Version = "3.0-Turbo-Sliced" }

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

-- Nenhum monitoramento pesado do Workspace. Atualizacao e manual (botao Atualizar).
-- A montagem de uma arvore grande e feita aos poucos, sem travar um frame inteiro.
rebuildTree = function()
    if closed or isSearching then return end
    treeGeneration = treeGeneration + 1
    local generation = treeGeneration
    setStatus("Montando Explorer (em lotes)...")
    task.spawn(function()
        local entries = {}
        -- DFS com iteradores de filhos; nao empilha milhares de nos no mesmo frame.
        local stack = { {obj = game, depth = 0, index = 0} }
        local sinceYield, started = 0, os.clock()
        while #stack > 0 and #entries < MAX_TREE_ENTRIES do
            if closed or isSearching or generation ~= treeGeneration then return end
            local frame = stack[#stack]
            if not frame.emitted then
                frame.emitted = true
                entries[#entries + 1] = {inst = frame.obj, depth = frame.depth}
                if expanded[frame.obj] then
                    local ok, children = pcall(function() return frame.obj:GetChildren() end)
                    frame.children = ok and children or {}
                    hasChildren[frame.obj] = #frame.children > 0
                end
            elseif frame.children and frame.index < #frame.children then
                frame.index = frame.index + 1
                stack[#stack + 1] = {
                    obj = frame.children[frame.index], depth = frame.depth + 1,
                    index = 0,
                }
            else
                stack[#stack] = nil
            end
            sinceYield = sinceYield + 1
            if sinceYield >= TREE_BATCH or os.clock() - started >= SLICE_SECONDS then
                sinceYield, started = 0, os.clock()
                task.wait()
            end
        end
        if closed or isSearching or generation ~= treeGeneration then return end
        displayed = entries
        truncated = #entries >= MAX_TREE_ENTRIES
        setStatus(string.format("Explorer: %d itens visiveis%s", #entries,
            truncated and " | limite de seguranca, feche uma pasta" or ""))
        syncCanvas()
    end)
end

local function toggleExpanded(entry)
    if closed or isSearching then return end
    local obj = entry.inst
    if expanded[obj] then
        expanded[obj] = nil
    else
        if hasChildren[obj] == false then return end
        expanded[obj] = true
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
            -- Estado desconhecido = mostra expansor, mas nao consulta GetChildren durante scroll.
            local childState = hasChildren[obj]
            ref.arrow.Visible = not isSearching and (expanded[obj] or childState ~= false)
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
        for _, key in ipairs({"Anchored", "CanCollide", "CanTouch", "Transparency", "Color", "Material", "Orientation"}) do
            lines[#lines + 1] = key .. ": " .. (safeValue(obj, key) or "N/D")
        end
        if obj:IsA("MeshPart") then
            lines[#lines + 1] = "MeshId: " .. (safeValue(obj, "MeshId") or "N/D")
            lines[#lines + 1] = "TextureID: " .. (safeValue(obj, "TextureID") or "N/D")
        end
    elseif obj:IsA("Model") then
        lines[#lines + 1] = "PrimaryPart: " .. (safeValue(obj, "PrimaryPart") or "N/D")
    elseif obj:IsA("Decal") or obj:IsA("Texture") then
        lines[#lines + 1] = "Texture: " .. (safeValue(obj, "Texture") or "N/D")
        lines[#lines + 1] = "Transparency: " .. (safeValue(obj, "Transparency") or "N/D")
    elseif obj:IsA("Sound") then
        lines[#lines + 1] = "SoundId: " .. (safeValue(obj, "SoundId") or "N/D")
        lines[#lines + 1] = "Volume: " .. (safeValue(obj, "Volume") or "N/D")
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
    treeGeneration = treeGeneration + 1  -- cancela a montagem da arvore anterior
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
    setStatus("Buscando " .. (workspaceOnly and "no Workspace" or "no jogo") .. " em lotes...")
    task.spawn(function()
        local stack = { workspaceOnly and workspace or game }
        local found = {}
        local scanned, ticks = 0, 0
        local started = os.clock()
        while #stack > 0 and scanned < MAX_SEARCH_SCANNED and #found < MAX_SEARCH_RESULTS do
            if closed or generation ~= searchGeneration then return end
            local obj = stack[#stack]
            stack[#stack] = nil
            scanned = scanned + 1
            if obj ~= gui and string.find(string.lower(obj.Name), term, 1, true) then
                found[#found + 1] = {inst = obj, depth = 0}
            end
            if obj ~= gui then
                local ok, children = pcall(function() return obj:GetChildren() end)
                if ok then
                    -- Empilhamento tambem em fatias: evita uma pausa longa com pastas gigantes.
                    local j = #children
                    while j >= 1 do
                        stack[#stack + 1] = children[j]
                        j = j - 1
                        ticks = ticks + 1
                        if ticks >= SEARCH_BATCH or os.clock() - started >= SLICE_SECONDS then
                            if closed or generation ~= searchGeneration then return end
                            ticks, started = 0, os.clock()
                            task.wait()
                        end
                    end
                end
            end
            ticks = ticks + 1
            if ticks >= SEARCH_BATCH or os.clock() - started >= SLICE_SECONDS then
                if closed or generation ~= searchGeneration then return end
                ticks, started = 0, os.clock()
                if scanned % 1200 < SEARCH_BATCH then
                    displayed = found
                    syncCanvas()
                    setStatus(string.format("Buscando... %d encontrados / %d verificados", #found, scanned))
                end
                task.wait()
            end
        end
        if closed or generation ~= searchGeneration then return end
        displayed = found
        scroll.CanvasPosition = Vector2.new(0, 0)
        syncCanvas()
        setStatus(string.format("Busca: %d encontrados / %d verificados%s", #found, scanned,
            (#stack > 0) and " (limite de protecao atingido)" or ""))
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

bind(scopeButton.Activated, function()
    workspaceOnly = not workspaceOnly
    scopeButton.Text = workspaceOnly and "MAPA" or "TUDO"
    if isSearching then runSearch(query) else
        setStatus("Pesquisa: " .. (workspaceOnly and "Workspace" or "todo o jogo"))
    end
end)

local function parsePropertyValue(obj, key, raw)
    local ok, oldValue = pcall(function() return obj[key] end)
    if not ok then return nil, "Propriedade nao encontrada ou inacessivel" end
    local t = typeof(oldValue)
    if t == "number" then
        local n = tonumber(raw)
        if not n then return nil, "Digite um numero valido" end
        return n
    elseif t == "boolean" then
        if raw == "true" or raw == "1" then return true end
        if raw == "false" or raw == "0" then return false end
        return nil, "Use true ou false"
    elseif t == "string" then
        return raw
    elseif t == "Vector3" then
        local a,b,c = raw:match("^%s*([%+%-]?[%d%.]+)%s*,%s*([%+%-]?[%d%.]+)%s*,%s*([%+%-]?[%d%.]+)%s*$")
        if not a then return nil, "Use x,y,z" end
        return Vector3.new(tonumber(a),tonumber(b),tonumber(c))
    elseif t == "Color3" then
        local a,b,c = raw:match("^%s*(%d+)%s*,%s*(%d+)%s*,%s*(%d+)%s*$")
        if not a then return nil, "Use R,G,B (0 a 255)" end
        return Color3.fromRGB(tonumber(a),tonumber(b),tonumber(c))
    elseif t == "EnumItem" then
        local enumType = tostring(oldValue.EnumType):gsub("^Enum%.", "")
        local enum = Enum[enumType]
        local keyName = raw:gsub("^Enum%.[^.]+%.", "")
        if enum then
            local okValue, enumVal = pcall(function() return enum[keyName] end)
            if okValue and enumVal then return enumVal end
        end
        return nil, "Enum invalido (ex: Plastic)"
    end
    return nil, "Tipo nao suportado neste Lite: " .. t
end

bind(applyProp.Activated, function()
    if not selected or selected == game then return end
    local key = propName.Text:match("^%s*(.-)%s*$")
    if key == "" or key == "Parent" then return setStatus("Propriedade invalida") end
    local value, err = parsePropertyValue(selected, key, propValue.Text)
    if err then return setStatus(err) end
    local ok, reason = pcall(function() selected[key] = value end)
    if not ok then return setStatus("Erro ao editar: " .. tostring(reason):sub(1,70)) end
    setStatus("Propriedade alterada localmente: " .. key)
    showInfo()
    if key == "Name" then rebuildTree() end
end)

bind(focusButton.Activated, function()
    if not selected then return end
    local pos
    if selected:IsA("BasePart") then
        pos = selected.Position
    elseif selected:IsA("Model") then
        local ok, cf = pcall(function() return selected:GetPivot() end)
        pos = ok and cf.Position or nil
    end
    local cam = workspace.CurrentCamera
    if pos and cam then
        cam.CFrame = CFrame.lookAt(pos + Vector3.new(18,12,18), pos)
        setStatus("Camera focada na selecao (local)")
    else
        setStatus("Foco disponivel para BasePart ou Model")
    end
end)

bind(duplicateButton.Activated, function()
    if not selected or not selected.Parent then return end
    local ok, result = pcall(function()
        local c = selected:Clone()
        c.Parent = selected.Parent
        return c
    end)
    if ok and result then
        selected = result
        showInfo()
        rebuildTree()
        setStatus("Instancia duplicada localmente")
    else
        setStatus("Nao foi possivel duplicar esta instancia")
    end
end)

local deleteConfirmation = nil
bind(deleteButton.Activated, function()
    if not selected or not selected.Parent then return end
    -- Segundo clique para evitar apagar uma instancia sem querer.
    if deleteConfirmation ~= selected then
        deleteConfirmation = selected
        deleteButton.Text = "Confirmar?"
        task.delay(4, function()
            if not closed then deleteConfirmation = nil; deleteButton.Text = "Excluir" end
        end)
        return
    end
    local target = selected
    deleteConfirmation = nil
    deleteButton.Text = "Excluir"
    local ok = pcall(function() target:Destroy() end)
    if ok then
        selected = workspace
        showInfo()
        rebuildTree()
        setStatus("Instancia excluida localmente")
    else
        setStatus("Nao foi possivel excluir esta instancia")
    end
end)

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

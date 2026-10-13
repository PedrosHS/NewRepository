--[[
	Dex++
	Version 4.0 Custom
	
	Developed by Chillz
	
	Dex++ is a revival of Moon's Dex, made to fulfill Moon's Dex prophecy.
]]

local selection
local nodes = {}

local oldgame = game
local game = workspace.Parent

cloneref = cloneref or function(ref)
	if not getreg then return ref end
	
	local InstanceList
	
	local a = Instance.new("Part")
	for _, c in pairs(getreg()) do
		if type(c) == "table" and #c then
			if rawget(c, "__mode") == "kvs" then
				for d, e in pairs(c) do
					if e == a then
						InstanceList = c
						break
					end
				end
			end
		end
	end
	local f = {}
	function f.invalidate(g)
		if not InstanceList then
			return
		end
		for b, c in pairs(InstanceList) do
			if c == g then
				InstanceList[b] = nil
				return g
			end
		end
	end
	return f.invalidate
end


local EmbeddedModules = {
["Console"] = function()
--[[
	Console Module
]]
-- Common Locals
local Main,Lib,Apps,Settings -- Main Containers
local Explorer, Properties, ScriptViewer, Notebook -- Major Apps
local API,RMD,env,service,plr,create,createSimple -- Main Locals

local function initDeps(data)
	Main = data.Main
	Lib = data.Lib
	Apps = data.Apps
	Settings = data.Settings

	API = data.API
	RMD = data.RMD
	env = data.env
	service = data.service
	plr = data.plr
	create = data.create
	createSimple = data.createSimple
end

local function initAfterMain()
	Explorer = Apps.Explorer
	Properties = Apps.Properties
	ScriptViewer = Apps.ScriptViewer
	Notebook = Apps.Notebook
end

local function main()
	local persistentConnections = {}
	local scrollConsoleInput
	local Console = {}

	local window,ConsoleFrame

	local OutputLimit = 500 -- Same as Roblox Console.


	-- Instances: 29 | Scripts: 1 | Modules: 1 | Tags: 0
	local G2L = {};

	-- StarterGui.ScreenGui
	window = Lib.Window.new()
	window:SetTitle("Console")
	window:Resize(500,400)
	Console.Window = window

	-- StarterGui.ScreenGui.Console
	ConsoleFrame = Instance.new("ImageButton", window.GuiElems.Content);
	ConsoleFrame["BorderSizePixel"] = 0;
	ConsoleFrame["AutoButtonColor"] = false;
	ConsoleFrame["BackgroundTransparency"] = 1;
	ConsoleFrame["BackgroundColor3"] = Color3.fromRGB(47, 47, 47);
	ConsoleFrame["Selectable"] = false;
	ConsoleFrame["Size"] = UDim2.new(1,0,1,0);
	ConsoleFrame["BorderColor3"] = Color3.fromRGB(0, 0, 0);
	ConsoleFrame["Name"] = [[Console]];
	ConsoleFrame["Position"] = UDim2.new(0,0,0,0);


	-- StarterGui.ScreenGui.Console.CommandLine
	G2L["3"] = Lib.Frame.new().Gui--Instance.new("Frame", ConsoleFrame);
	G2L["3"].Parent = ConsoleFrame
	G2L["3"]["BorderSizePixel"] = 0;
	G2L["3"]["BackgroundColor3"] = Color3.fromRGB(37, 37, 37);
	G2L["3"]["AnchorPoint"] = Vector2.new(0.5, 1);
	G2L["3"]["ClipsDescendants"] = true;
	G2L["3"]["Size"] = UDim2.new(1, -8, 0, 22);
	G2L["3"]["Position"] = UDim2.new(0.5, 0, 1, -5);
	G2L["3"]["BorderColor3"] = Color3.fromRGB(0, 0, 0);
	G2L["3"]["Name"] = [[CommandLine]];


	-- StarterGui.ScreenGui.Console.CommandLine.UIStroke
	G2L["4"] = Instance.new("UIStroke", G2L["3"]);
	G2L["4"]["Transparency"] = 0.65;
	G2L["4"]["Thickness"] = 1.25;


	-- StarterGui.ScreenGui.Console.CommandLine.ScrollingFrame
	G2L["5"] = Instance.new("ScrollingFrame", G2L["3"]);
	G2L["5"]["Active"] = true;
	G2L["5"]["ScrollingDirection"] = Enum.ScrollingDirection.X;
	G2L["5"]["BorderSizePixel"] = 0;
	G2L["5"]["CanvasSize"] = UDim2.new(0, 0, 0, 0);
	G2L["5"]["ElasticBehavior"] = Enum.ElasticBehavior.Never;
	G2L["5"]["TopImage"] = [[rbxasset://textures/ui/Scroll/scroll-middle.png]];
	G2L["5"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255);
	G2L["5"]["HorizontalScrollBarInset"] = Enum.ScrollBarInset.Always;
	G2L["5"]["BottomImage"] = [[rbxasset://textures/ui/Scroll/scroll-middle.png]];
	G2L["5"]["AutomaticCanvasSize"] = Enum.AutomaticSize.X;
	G2L["5"]["Size"] = UDim2.new(1, 0, 1, 0);
	G2L["5"]["ScrollBarImageColor3"] = Color3.fromRGB(57, 57, 57);
	G2L["5"]["BorderColor3"] = Color3.fromRGB(0, 0, 0);
	G2L["5"]["ScrollBarThickness"] = 2;
	G2L["5"]["BackgroundTransparency"] = 1;

	-- StarterGui.ScreenGui.Console.CommandLine.ScrollingFrame.TextBox
	G2L["6"] = Instance.new("TextBox", G2L["5"]);
	G2L["6"]["CursorPosition"] = -1;
	G2L["6"]["TextXAlignment"] = Enum.TextXAlignment.Left;
	G2L["6"]["PlaceholderColor3"] = Color3.fromRGB(211, 211, 211);
	G2L["6"]["BorderSizePixel"] = 0;
	G2L["6"]["TextSize"] = 13;
	G2L["6"]["TextColor3"] = Color3.fromRGB(211, 211, 211);
	G2L["6"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255);
	G2L["6"]["FontFace"] = Font.new([[rbxasset://fonts/families/Inconsolata.json]], Enum.FontWeight.Regular, Enum.FontStyle.Normal);
	G2L["6"]["AutomaticSize"] = Enum.AutomaticSize.X;
	G2L["6"]["ClearTextOnFocus"] = false;
	G2L["6"]["PlaceholderText"] = [[Run a command]];
	G2L["6"]["Size"] = UDim2.new(0, 246, 0, 22);
	G2L["6"]["BorderColor3"] = Color3.fromRGB(0, 0, 0);
	G2L["6"]["Text"] = [[]];
	G2L["6"]["BackgroundTransparency"] = 1;


	-- StarterGui.ScreenGui.Console.CommandLine.ScrollingFrame.TextBox.UIPadding
	G2L["7"] = Instance.new("UIPadding", G2L["6"]);
	G2L["7"]["PaddingLeft"] = UDim.new(0, 7);


	-- StarterGui.ScreenGui.Console.CommandLine.ScrollingFrame.Highlight
	G2L["8"] = Instance.new("TextLabel", G2L["5"]);
	G2L["8"]["Interactable"] = false;
	G2L["8"]["ZIndex"] = 2;
	G2L["8"]["BorderSizePixel"] = 0;
	G2L["8"]["TextSize"] = 13;
	G2L["8"]["TextXAlignment"] = Enum.TextXAlignment.Left;
	G2L["8"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255);
	G2L["8"]["FontFace"] = Font.new([[rbxasset://fonts/families/Inconsolata.json]], Enum.FontWeight.Regular, Enum.FontStyle.Normal);
	G2L["8"]["TextColor3"] = Color3.fromRGB(255, 255, 255);
	G2L["8"]["BackgroundTransparency"] = 1;
	G2L["8"]["RichText"] = true;
	G2L["8"]["Size"] = UDim2.new(0, 246, 0, 22);
	G2L["8"]["BorderColor3"] = Color3.fromRGB(0, 0, 0);
	G2L["8"]["Text"] = [[]];
	G2L["8"]["Selectable"] = true;
	G2L["8"]["AutomaticSize"] = Enum.AutomaticSize.X;
	G2L["8"]["Name"] = [[Highlight]];


	-- StarterGui.ScreenGui.Console.CommandLine.ScrollingFrame.Highlight.UIPadding
	G2L["9"] = Instance.new("UIPadding", G2L["8"]);
	G2L["9"]["PaddingLeft"] = UDim.new(0, 7);

	G2L["backgroundOutput"] = Instance.new("Frame", ConsoleFrame);
	G2L["backgroundOutput"]["BorderSizePixel"] = 0;
	G2L["backgroundOutput"]["BackgroundColor3"] = Color3.fromRGB(36, 36, 36);
	G2L["backgroundOutput"]["Name"] = [[BackgroundOutput]];
	G2L["backgroundOutput"]["AnchorPoint"] = Vector2.new(0, 0);
	G2L["backgroundOutput"]["Size"] = UDim2.new(1, -8, 1, -55);
	G2L["backgroundOutput"]["Position"] = UDim2.new(0, 4, 0, 23);
	G2L["backgroundOutput"]["BorderColor3"] = Color3.fromRGB(0, 0, 0);
	G2L["backgroundOutput"]["ZIndex"] = 1;

	local scrollbar = Lib.ScrollBar.new()
	scrollbar.Gui.Parent = ConsoleFrame
	scrollbar.Gui.Size = UDim2.new(0, 16, 1, -55);
	scrollbar.Gui.Position = UDim2.new(1, -20,0, 23);
	scrollbar.Gui.Up.ZIndex = 3
	scrollbar.Gui.Down.ZIndex = 3

	-- StarterGui.ScreenGui.Console.Output
	G2L["a"] = Instance.new("ScrollingFrame", ConsoleFrame);
	G2L["a"]["Active"] = true;
	G2L["a"]["BorderSizePixel"] = 0;
	G2L["a"]["CanvasSize"] = UDim2.new(0, 0, 0, 0);
	G2L["a"]["TopImage"] = '';
	G2L["a"]["BackgroundColor3"] = Color3.fromRGB(36, 36, 36);
	G2L["a"].BackgroundTransparency = 1
	G2L["a"]["Name"] = [[Output]];
	G2L["a"]["ScrollBarImageTransparency"] = 0;
	G2L["a"]["BottomImage"] = '';
	G2L["a"]["AnchorPoint"] = Vector2.new(0, 0);
	G2L["a"]["AutomaticCanvasSize"] = Enum.AutomaticSize.Y;
	G2L["a"]["Size"] = UDim2.new(1, -8, 1, -55);
	G2L["a"]["Position"] = UDim2.new(0, 4, 0, 23);
	G2L["a"]["BorderColor3"] = Color3.fromRGB(0, 0, 0);
	G2L["a"].ScrollBarImageColor3 = Color3.fromRGB(70, 70, 70)
	G2L["a"]["ScrollBarThickness"] = 16;
	G2L["a"]["ZIndex"] = 1;

	G2L["a"]:GetPropertyChangedSignal("AbsoluteWindowSize"):Connect(function()
		if G2L["a"].AbsoluteCanvasSize ~= G2L["a"].AbsoluteWindowSize then
			scrollbar.Gui.Visible = true
		else
			scrollbar.Gui.Visible = false
		end
	end)

	-- StarterGui.ScreenGui.Console.Output.UIListLayout
	G2L["b"] = Instance.new("UIListLayout", G2L["a"]);
	G2L["b"]["SortOrder"] = Enum.SortOrder.LayoutOrder;


	-- StarterGui.ScreenGui.Console.Output.UIStroke
	G2L["c"] = Instance.new("UIStroke", G2L["a"]);
	G2L["c"]["Transparency"] = 0.7;
	G2L["c"]["Thickness"] = 1.25;
	G2L["c"]["Color"] = Color3.fromRGB(12, 12, 12);


	-- StarterGui.ScreenGui.Console.Output.OutputTextSize
	G2L["d"] = Instance.new("NumberValue", G2L["a"]);
	G2L["d"]["Name"] = [[OutputTextSize]];
	G2L["d"]["Value"] = 15;


	-- StarterGui.ScreenGui.Console.Output.OutputLimit
	G2L["e"] = Instance.new("NumberValue", G2L["a"]);
	G2L["e"]["Name"] = [[OutputLimit]];
	G2L["e"]["Value"] = OutputLimit;


	-- StarterGui.ScreenGui.Console.Output.UIPadding
	G2L["f"] = Instance.new("UIPadding", G2L["a"]);
	G2L["f"]["PaddingTop"] = UDim.new(0, 2);


	-- StarterGui.ScreenGui.Console.TextSizeBox
	G2L["10"] = Instance.new("Frame", ConsoleFrame);
	G2L["10"]["BorderSizePixel"] = 0;
	G2L["10"]["BackgroundColor3"] = Color3.fromRGB(37, 37, 37);
	G2L["10"]["ClipsDescendants"] = true;
	G2L["10"]["Size"] = UDim2.new(0, 37, 0, 15);
	G2L["10"]["Position"] = UDim2.new(0, 4, 0, 4);
	G2L["10"]["BorderColor3"] = Color3.fromRGB(0, 0, 0);
	G2L["10"]["Name"] = [[TextSizeBox]];


	-- StarterGui.ScreenGui.Console.TextSizeBox.TextBox
	G2L["11"] = Instance.new("TextBox", G2L["10"]);
	G2L["11"]["PlaceholderColor3"] = Color3.fromRGB(108, 108, 108);
	G2L["11"]["BorderSizePixel"] = 0;
	G2L["11"]["TextWrapped"] = true;
	G2L["11"]["TextSize"] = 15;
	G2L["11"]["TextColor3"] = Color3.fromRGB(211, 211, 211);
	G2L["11"]["TextScaled"] = true;
	G2L["11"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255);
	G2L["11"]["FontFace"] = Font.new([[rbxasset://fonts/families/Inconsolata.json]], Enum.FontWeight.Regular, Enum.FontStyle.Normal);
	G2L["11"]["PlaceholderText"] = [[Size]];
	G2L["11"]["Size"] = UDim2.new(1, 0, 1, 0);
	G2L["11"]["BorderColor3"] = Color3.fromRGB(0, 0, 0);
	G2L["11"]["Text"] = [[]];
	G2L["11"]["BackgroundTransparency"] = 1;


	-- StarterGui.ScreenGui.Console.TextSizeBox.TextBox.UIPadding
	G2L["12"] = Instance.new("UIPadding", G2L["11"]);
	G2L["12"]["PaddingTop"] = UDim.new(0, 2);
	G2L["12"]["PaddingRight"] = UDim.new(0, 5);
	G2L["12"]["PaddingLeft"] = UDim.new(0, 5);
	G2L["12"]["PaddingBottom"] = UDim.new(0, 2);


	-- StarterGui.ScreenGui.Console.TextSizeBox.UIStroke
	G2L["13"] = Instance.new("UIStroke", G2L["10"]);
	G2L["13"]["Transparency"] = 0.65;
	G2L["13"]["Thickness"] = 1.25;


	-- StarterGui.ScreenGui.Console.Clear
	G2L["14"] = Instance.new("ImageButton", ConsoleFrame);
	G2L["14"]["BorderSizePixel"] = 0;
	G2L["14"]["BackgroundColor3"] = Color3.fromRGB(57, 57, 57);
	G2L["14"]["Size"] = UDim2.new(0, 37, 0, 15);
	G2L["14"]["BorderColor3"] = Color3.fromRGB(0, 0, 0);
	G2L["14"]["Name"] = [[Clear]];
	G2L["14"]["Position"] = UDim2.new(1, -42, 0, 4);


	-- StarterGui.ScreenGui.Console.Clear.TextLabel
	G2L["15"] = Instance.new("TextLabel", G2L["14"]);
	G2L["15"]["TextWrapped"] = true;
	G2L["15"]["Interactable"] = false;
	G2L["15"]["BorderSizePixel"] = 0;
	G2L["15"]["TextSize"] = 20;
	G2L["15"]["TextScaled"] = true;
	G2L["15"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255);
	G2L["15"]["FontFace"] = Font.new([[rbxasset://fonts/families/SourceSansPro.json]], Enum.FontWeight.Regular, Enum.FontStyle.Normal);
	G2L["15"]["TextColor3"] = Color3.fromRGB(255, 255, 255);
	G2L["15"]["BackgroundTransparency"] = 1;
	G2L["15"]["Size"] = UDim2.new(1, 0, 1, 0);
	G2L["15"]["BorderColor3"] = Color3.fromRGB(0, 0, 0);
	G2L["15"]["Text"] = [[Clear]];


	-- StarterGui.ScreenGui.Console.Clear.UIPadding
	G2L["16"] = Instance.new("UIPadding", G2L["14"]);
	G2L["16"]["PaddingTop"] = UDim.new(0, 1);
	G2L["16"]["PaddingBottom"] = UDim.new(0, 1);


	-- StarterGui.ScreenGui.Console.OutputTemplate
	G2L["17"] = Instance.new("TextBox", ConsoleFrame);
	G2L["17"]["Visible"] = false;
	G2L["17"]["Active"] = false;
	G2L["17"]["Name"] = [[OutputTemplate]];
	G2L["17"]["TextXAlignment"] = Enum.TextXAlignment.Left;
	G2L["17"]["BorderSizePixel"] = 0;
	G2L["17"]["TextEditable"] = false;
	G2L["17"]["TextWrapped"] = true;
	G2L["17"]["TextSize"] = 15;
	G2L["17"]["TextColor3"] = Color3.fromRGB(171, 171, 171);
	G2L["17"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255);
	G2L["17"]["RichText"] = true;
	G2L["17"]["FontFace"] = Font.new([[rbxasset://fonts/families/SourceSansPro.json]], Enum.FontWeight.Regular, Enum.FontStyle.Normal);
	G2L["17"]["AutomaticSize"] = Enum.AutomaticSize.Y;
	G2L["17"]["Selectable"] = false;
	G2L["17"]["ClearTextOnFocus"] = false;
	G2L["17"]["Size"] = UDim2.new(1, 0, 0, 1);
	G2L["17"]["Position"] = UDim2.new(0, 20, 0, 0);
	G2L["17"]["BorderColor3"] = Color3.fromRGB(0, 0, 0);
	G2L["17"]["Text"] = [[(timestamp) <font color="rgb(255, 255, 255)">Output</font>]];
	G2L["17"]["BackgroundTransparency"] = 1;


	-- StarterGui.ScreenGui.Console.OutputTemplate.UIPadding
	G2L["18"] = Instance.new("UIPadding", G2L["17"]);
	G2L["18"]["PaddingRight"] = UDim.new(0, 6);
	G2L["18"]["PaddingLeft"] = UDim.new(0, 6);


	-- StarterGui.ScreenGui.Console.CtrlScroll
	G2L["19"] = Instance.new("ImageButton", ConsoleFrame);
	G2L["19"]["BorderSizePixel"] = 0;
	G2L["19"]["BackgroundColor3"] = Color3.fromRGB(57, 57, 57);
	G2L["19"]["Size"] = UDim2.new(0, 60, 0, 15);
	G2L["19"]["BorderColor3"] = Color3.fromRGB(0, 0, 0);
	G2L["19"]["Name"] = [[CtrlScroll]];
	G2L["19"]["Position"] = UDim2.new(0, 46, 0, 4);


	-- StarterGui.ScreenGui.Console.CtrlScroll.TextLabel
	G2L["1a"] = Instance.new("TextLabel", G2L["19"]);
	G2L["1a"]["TextWrapped"] = true;
	G2L["1a"]["Interactable"] = false;
	G2L["1a"]["BorderSizePixel"] = 0;
	G2L["1a"]["TextSize"] = 20;
	G2L["1a"]["TextScaled"] = true;
	G2L["1a"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255);
	G2L["1a"]["FontFace"] = Font.new([[rbxasset://fonts/families/SourceSansPro.json]], Enum.FontWeight.Regular, Enum.FontStyle.Normal);
	G2L["1a"]["TextColor3"] = Color3.fromRGB(255, 255, 255);
	G2L["1a"]["BackgroundTransparency"] = 1;
	G2L["1a"]["Size"] = UDim2.new(1, 0, 1, 0);
	G2L["1a"]["BorderColor3"] = Color3.fromRGB(0, 0, 0);
	G2L["1a"]["Text"] = [[Ctrl Scroll]];


	-- StarterGui.ScreenGui.Console.CtrlScroll.UIPadding
	G2L["1b"] = Instance.new("UIPadding", G2L["19"]);
	G2L["1b"]["PaddingTop"] = UDim.new(0, 1);
	G2L["1b"]["PaddingBottom"] = UDim.new(0, 1);

	-- StarterGui.ScreenGui.Console.AutoScroll
	G2L["20"] = Instance.new("ImageButton", ConsoleFrame);
	G2L["20"]["BorderSizePixel"] = 0;
	G2L["20"]["BackgroundColor3"] = Color3.fromRGB(57, 57, 57);
	G2L["20"]["Size"] = UDim2.new(0, 60, 0, 15);
	G2L["20"]["BorderColor3"] = Color3.fromRGB(0, 0, 0);
	G2L["20"]["Name"] = [[AutoScroll]];
	G2L["20"]["Position"] = UDim2.new(0, 110, 0, 4);


	-- StarterGui.ScreenGui.Console.AutoScroll.TextLabel
	G2L["1e"] = Instance.new("TextLabel", G2L["20"]);
	G2L["1e"]["TextWrapped"] = true;
	G2L["1e"]["Interactable"] = false;
	G2L["1e"]["BorderSizePixel"] = 0;
	G2L["1e"]["TextSize"] = 20;
	G2L["1e"]["TextScaled"] = true;
	G2L["1e"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255);
	G2L["1e"]["FontFace"] = Font.new([[rbxasset://fonts/families/SourceSansPro.json]], Enum.FontWeight.Regular, Enum.FontStyle.Normal);
	G2L["1e"]["TextColor3"] = Color3.fromRGB(255, 255, 255);
	G2L["1e"]["BackgroundTransparency"] = 1;
	G2L["1e"]["Size"] = UDim2.new(1, 0, 1, 0);
	G2L["1e"]["BorderColor3"] = Color3.fromRGB(0, 0, 0);
	G2L["1e"]["Text"] = [[Auto Scroll]];


	-- StarterGui.ScreenGui.Console.AutoScroll.UIPadding
	G2L["1f"] = Instance.new("UIPadding", G2L["20"]);
	G2L["1f"]["PaddingTop"] = UDim.new(0, 1);
	G2L["1f"]["PaddingBottom"] = UDim.new(0, 1);


	-- StarterGui.ScreenGui.ConsoleHandler
	G2L["1c"] = Instance.new("LocalScript", G2L["1"]);
	G2L["1c"]["Name"] = [[ConsoleHandler]];


	-- StarterGui.ScreenGui.ConsoleHandler.SyntaxHighlighter
	G2L["1d"] = Instance.new("ModuleScript", G2L["1c"]);
	G2L["1d"]["Name"] = [[SyntaxHighlighter]];


	-- Require G2L wrapper
	local G2L_REQUIRE = require;
	local G2L_MODULES = {};
	local function require(Module)
		local ModuleState = G2L_MODULES[Module];
		if ModuleState then
			if not ModuleState.Required then
				ModuleState.Required = true;
				ModuleState.Value = ModuleState.Closure();
			end
			return ModuleState.Value;
		end;
		return G2L_REQUIRE(Module);
	end

	G2L_MODULES[G2L["1d"]] = {
		Closure = function()
			local script = G2L["1d"];local highlighter = {}
			local keywords = {
				lua = {
					"and", "break", "or", "else", "elseif", "if", "then", "until", "repeat", "while", "do", "for", "in", "end",
					"local", "return", "function", "export"
				},
				rbx = {
					"game", "workspace", "script", "math", "string", "table", "task", "wait", "select", "next", "Enum",
					"error", "warn", "tick", "assert", "shared", "loadstring", "tonumber", "tostring", "type",
					"typeof", "unpack", "print", "Instance", "CFrame", "Vector3", "Vector2", "Color3", "UDim", "UDim2", "Ray", "BrickColor",
					"OverlapParams", "RaycastParams", "Axes", "Random", "Region3", "Rect", "TweenInfo",
					"collectgarbage", "not", "utf8", "pcall", "xpcall", "_G", "setmetatable", "getmetatable", "os", "pairs", "ipairs"
				},
				exploit = {
					"hookmetamethod", "hookfunction", "getgc", "filtergc", "Drawing", "getgenv", "getsenv", "getrenv", "getfenv", "setfenv",
					"decompile", "saveinstance", "getrawmetatable", "setrawmetatable", "checkcaller", "cloneref", "clonefunction",
					"iscclosure", "islclosure", "isexecutorclosure", "newcclosure", "getfunctionhash", "crypt", "writefile", "appendfile", "loadfile", "readfile", "listfiles",
					"makefolder", "isfolder", "isfile", "delfile", "delfolder", "getcustomasset", "fireclickdetector", "firetouchinterest", "fireproximityprompt"
				},
				operators = {
					"#", "+", "-", "*", "%", "/", "^", "=", "~", "=", "<", ">", ",", ".", "(", ")", "{", "}", "[", "]", ";", ":"
				}
			}

			local colors = {
				numbers = Color3.fromRGB(255, 198, 0),
				boolean = Color3.fromRGB(255, 198, 0),
				operator = Color3.fromRGB(204, 204, 204),
				lua = Color3.fromRGB(132, 214, 247),
				exploit = Color3.fromRGB(171, 84, 247),
				rbx = Color3.fromRGB(248, 109, 124),
				str = Color3.fromRGB(173, 241, 132),
				comment = Color3.fromRGB(102, 102, 102),
				null = Color3.fromRGB(255, 198, 0),
				call = Color3.fromRGB(253, 251, 172),
				self_call = Color3.fromRGB(253, 251, 172),
				local_color = Color3.fromRGB(248, 109, 115),
				function_color = Color3.fromRGB(248, 109, 115),
				self_color = Color3.fromRGB(248, 109, 115),
				local_property = Color3.fromRGB(97, 161, 241),
			}

			local function createKeywordSet(keywords)
				local keywordSet = {}
				for _, keyword in ipairs(keywords) do
					keywordSet[keyword] = true
				end
				return keywordSet
			end

			local luaSet = createKeywordSet(keywords.lua)
			local exploitSet = createKeywordSet(keywords.exploit)
			local rbxSet = createKeywordSet(keywords.rbx)
			local operatorsSet = createKeywordSet(keywords.operators)

			local function getHighlight(tokens, index)
				local token = tokens[index]

				if colors[token .. "_color"] then
					return colors[token .. "_color"]
				end

				if tonumber(token) then
					return colors.numbers
				elseif token == "nil" then
					return colors.null
				elseif token:sub(1, 2) == "--" then
					return colors.comment
				elseif operatorsSet[token] then
					return colors.operator
				elseif luaSet[token] then
					return colors.rbx
				elseif rbxSet[token] then
					return colors.lua
				elseif exploitSet[token] then
					return colors.exploit
				elseif token:sub(1, 1) == "\"" or token:sub(1, 1) == "\'" then
					return colors.str
				elseif token == "true" or token == "false" then
					return colors.boolean
				end

				if tokens[index + 1] == "(" then
					if tokens[index - 1] == ":" then
						return colors.self_call
					end

					return colors.call
				end

				if tokens[index - 1] == "." then
					if tokens[index - 2] == "Enum" then
						return colors.rbx
					end

					return colors.local_property
				end
			end

			function highlighter.run(source)
				local tokens = {}
				local currentToken = ""

				local inString = false
				local inComment = false
				local commentPersist = false

				for i = 1, #source do
					local character = source:sub(i, i)

					if inComment then
						if character == "\n" and not commentPersist then
							table.insert(tokens, currentToken)
							table.insert(tokens, character)
							currentToken = ""

							inComment = false
						elseif source:sub(i - 1, i) == "]]" and commentPersist then
							currentToken ..= "]"

							table.insert(tokens, currentToken)
							currentToken = ""

							inComment = false
							commentPersist = false
						else
							currentToken = currentToken .. character
						end
					elseif inString then
						if character == inString and source:sub(i-1, i-1) ~= "\\" or character == "\n" then
							currentToken = currentToken .. character
							inString = false
						else
							currentToken = currentToken .. character
						end
					else
						if source:sub(i, i + 1) == "--" then
							table.insert(tokens, currentToken)
							currentToken = "-"
							inComment = true
							commentPersist = source:sub(i + 2, i + 3) == "[["
						elseif character == "\"" or character == "\'" then
							table.insert(tokens, currentToken)
							currentToken = character
							inString = character
						elseif operatorsSet[character] then
							table.insert(tokens, currentToken)
							table.insert(tokens, character)
							currentToken = ""
						elseif character:match("[%w_]") then
							currentToken = currentToken .. character
						else
							table.insert(tokens, currentToken)
							table.insert(tokens, character)
							currentToken = ""
						end
					end
				end

				table.insert(tokens, currentToken)

				local highlighted = {}

				for i, token in ipairs(tokens) do
					local highlight = getHighlight(tokens, i)

					if highlight then
						local syntax = string.format("<font color = \"#%s\">%s</font>", highlight:ToHex(), token:gsub("<", "&lt;"):gsub(">", "&gt;"))

						table.insert(highlighted, syntax)
					else
						table.insert(highlighted, token)
					end
				end

				return table.concat(highlighted)
			end

			return highlighter
		end;
	};

	Console.Init = function()
		-- StarterGui.ScreenGui.ConsoleHandler

		local CtrlScroll = false
		local AutoScroll = false

		local LogService = game:GetService("LogService")
		local Players = game:GetService("Players")
		local LocalPlayer = Players.LocalPlayer
		local Mouse = LocalPlayer:GetMouse()
		local UserInputService = game:GetService("UserInputService")
		local RunService = game:GetService("RunService")

		local Console = ConsoleFrame
		local SyntaxHighlightingModule = require(G2L["1c"].SyntaxHighlighter)
		local OutputTextSize = Console.Output.OutputTextSize

		local function Tween(obj, info, prop)
			local tween = game:GetService("TweenService"):Create(obj, info, prop)
			tween:Play()
			return tween
		end



		-- MOUSE STUFFS

		if CtrlScroll == true then
			Console.CtrlScroll.BackgroundColor3 = Color3.fromRGB(11, 90, 175)
		elseif CtrlScroll == false then
			Console.CtrlScroll.BackgroundColor3 = Color3.fromRGB(56, 56, 56)
		end
		Console.CtrlScroll.MouseButton1Click:Connect(function()
			CtrlScroll = not CtrlScroll
			if CtrlScroll == true then
				Console.CtrlScroll.BackgroundColor3 = Color3.fromRGB(11, 90, 175)
			elseif CtrlScroll == false then
				Console.CtrlScroll.BackgroundColor3 = Color3.fromRGB(56, 56, 56)
			end
		end)

		local IsHoldingCTRL = false
		table.insert(persistentConnections, UserInputService.InputBegan:Connect(function(input, gameproc)
			if not gameproc then
				if input.KeyCode == Enum.KeyCode.LeftControl or input.KeyCode == Enum.KeyCode.RightControl then
					IsHoldingCTRL = true
				end
			end
		end))
		table.insert(persistentConnections, UserInputService.InputEnded:Connect(function(input, gameproc)
			if not gameproc then
				if input.KeyCode == Enum.KeyCode.LeftControl or input.KeyCode == Enum.KeyCode.RightControl then
					IsHoldingCTRL = false
				end
			end
		end))

		if AutoScroll == true then
			Console.AutoScroll.BackgroundColor3 = Color3.fromRGB(11, 90, 175)
		elseif AutoScroll == false then
			Console.AutoScroll.BackgroundColor3 = Color3.fromRGB(56, 56, 56)
		end
		Console.AutoScroll.MouseButton1Click:Connect(function()
			AutoScroll = not AutoScroll
			if AutoScroll == true then
				Console.AutoScroll.BackgroundColor3 = Color3.fromRGB(11, 90, 175)
				Console.Output.CanvasPosition = Vector2.new(0, 9e9)
			elseif AutoScroll == false then
				Console.AutoScroll.BackgroundColor3 = Color3.fromRGB(56, 56, 56)
			end
		end)

		-- Console part
		local displayedOutput = {}
		local OutputLimit = Console.Output.OutputLimit
		OutputLimit.Value = math.clamp(tonumber(OutputLimit.Value) or 500, 50, 2000)

		local function escapeRichText(value)
			return tostring(value or "")
				:gsub("&", "&amp;")
				:gsub("<", "&lt;")
				:gsub(">", "&gt;")
				:gsub('"', "&quot;")
		end

		local function pruneDisplayedOutput()
			for index = #displayedOutput, 1, -1 do
				local output = displayedOutput[index]
				if typeof(output) ~= "Instance" or output.Parent == nil then
					table.remove(displayedOutput, index)
				end
			end
		end

		Console.TextSizeBox.TextBox.Text = tostring(OutputTextSize.Value)

		Console.TextSizeBox.TextBox:GetPropertyChangedSignal("Text"):Connect(function()
			local tonum = tonumber(Console.TextSizeBox.TextBox.Text)
			if tonum then
				OutputTextSize.Value = math.clamp(math.floor(tonum + 0.5), 6, 48)
			end
		end)
		table.insert(persistentConnections, OutputTextSize:GetPropertyChangedSignal("Value"):Connect(function()
			OutputTextSize.Value = math.clamp(OutputTextSize.Value, 6, 48)
			Console.TextSizeBox.TextBox.Text = tostring(OutputTextSize.Value)
			pruneDisplayedOutput()
			for _, output in ipairs(displayedOutput) do
				output.TextSize = OutputTextSize.Value
			end
		end))

		Console.Output.MouseEnter:Connect(function()
			scrollConsoleInput = UserInputService.InputChanged:Connect(function(input)
				if CtrlScroll and input.UserInputType == Enum.UserInputType.MouseWheel and IsHoldingCTRL == true then
					Console.Output.ScrollingEnabled = false
					local newTextSize = OutputTextSize.Value + input.Position.Z
					OutputTextSize.Value = math.clamp(newTextSize, 6, 48)
				else
					Console.Output.ScrollingEnabled = true
				end
			end)
		end)
		Console.Output.MouseLeave:Connect(function()
			if scrollConsoleInput then
				scrollConsoleInput:Disconnect()
				scrollConsoleInput = nil
			end
		end)


		Console.Clear.MouseButton1Click:Connect(function()
			for _, log in pairs(Console.Output:GetChildren()) do
				if log:IsA("TextBox") then
					log:Destroy()
				end
			end
			table.clear(displayedOutput)
		end)

		local focussedOutput

		table.insert(persistentConnections, LogService.MessageOut:Connect(function(msg, msgtype)
			msg = tostring(msg or "")
			local formattedText = ""
			local unformattedText = ""
			local newOutputText = Console.OutputTemplate:Clone()
			table.insert(displayedOutput, newOutputText)

			if #displayedOutput > OutputLimit.Value then
				local oldest = table.remove(displayedOutput, 1)
				if oldest and typeof(oldest) == "Instance" then
					oldest:Destroy()
				end
			end

			local escapedMessage = escapeRichText(msg)
			unformattedText = os.date("%H:%M:%S")..'   '..msg
			if msgtype == Enum.MessageType.MessageOutput then
				formattedText = os.date("%H:%M:%S")..'   <font color="rgb(204, 204, 204)">'..escapedMessage..'</font>'
				newOutputText.Text = formattedText
			elseif msgtype == Enum.MessageType.MessageWarning then
				formattedText = os.date("%H:%M:%S")..'   <b><font color="rgb(255, 142, 60)">'..escapedMessage..'</font></b>'
				newOutputText.Text = formattedText
			elseif msgtype == Enum.MessageType.MessageError then
				formattedText = os.date("%H:%M:%S")..'   <b><font color="rgb(255, 68, 68)">'..escapedMessage..'</font></b>'
				newOutputText.Text = formattedText
			elseif msgtype == Enum.MessageType.MessageInfo then
				formattedText = os.date("%H:%M:%S")..'   <font color="rgb(128, 215, 255)">'..escapedMessage..'</font>'
				newOutputText.Text = formattedText
			end

			newOutputText.TextSize = OutputTextSize.Value

			newOutputText.Focused:Connect(function()
				focussedOutput = newOutputText
				newOutputText.Text = unformattedText
			end)
			newOutputText.FocusLost:Connect(function()
				focussedOutput = nil
				newOutputText.Text = formattedText
			end)

			newOutputText.Parent = Console.Output
			newOutputText.Visible = true

			if AutoScroll then
				Console.Output.CanvasPosition = Vector2.new(0, 9e9)
			end
		end))

		Console.Output.MouseLeave:Connect(function()
			if focussedOutput then
				focussedOutput:ReleaseFocus()
			end
		end)

		Console.CommandLine.ScrollingFrame.TextBox:GetPropertyChangedSignal("Text"):Connect(function()

			local oneliner = string.gsub(Console.CommandLine.ScrollingFrame.TextBox.Text, "\n", "    ")
			Console.CommandLine.ScrollingFrame.TextBox.Text = oneliner

			Console.CommandLine.ScrollingFrame.Highlight.Text = SyntaxHighlightingModule.run(Console.CommandLine.ScrollingFrame.TextBox.Text)
		end)



		Console.CommandLine.ScrollingFrame.TextBox.FocusLost:Connect(function(enterPressed)
			if enterPressed and Console.CommandLine.ScrollingFrame.TextBox.Text ~= "" then
				local command = Console.CommandLine.ScrollingFrame.TextBox.Text
				print("> "..command)
				if not env.loadstring then
					warn("Dex++ Console: loadstring is unavailable")
					return
				end
				local compiled, chunkOrError = pcall(env.loadstring, command, "DexPlusPlus_Console")
				if not compiled or type(chunkOrError) ~= "function" then
					warn("Dex++ Console compile error: " .. tostring(chunkOrError))
					return
				end
				local ran, runtimeError = pcall(chunkOrError)
				if not ran then warn("Dex++ Console runtime error: " .. tostring(runtimeError)) end
			end
		end)
	end

	Console.Uninit = function()
		if scrollConsoleInput then
			pcall(scrollConsoleInput.Disconnect, scrollConsoleInput)
			scrollConsoleInput = nil
		end
		for index, connection in pairs(persistentConnections) do
			pcall(connection.Disconnect, connection)
			persistentConnections[index] = nil
		end
	end

	return Console
end

return {InitDeps = initDeps, InitAfterMain = initAfterMain, Main = main}

end,
["Explorer"] = function()
--[[
	Explorer App Module
	
	The main explorer interface
]]

-- Common Locals
local Main,Lib,Apps,Settings -- Main Containers
local Explorer, Properties, ScriptViewer, ModelViewer, Notebook -- Major Apps
local API,RMD,env,service,plr,create,createSimple -- Main Locals

local function initDeps(data)
	Main = data.Main
	Lib = data.Lib
	Apps = data.Apps
	Settings = data.Settings

	API = data.API
	RMD = data.RMD
	env = data.env
	service = data.service
	plr = data.plr
	create = data.create
	createSimple = data.createSimple
end

local function initAfterMain()
	Explorer = Apps.Explorer
	Properties = Apps.Properties
	ScriptViewer = Apps.ScriptViewer
	ModelViewer = Apps.ModelViewer
	Notebook = Apps.Notebook
end

local function main()
	local Explorer = {}
	local tree,listEntries,explorerOrders,searchResults,specResults = {},{},{},{},{}
	local expanded
	local entryTemplate,treeFrame,toolBar,descendantAddedCon,descendantRemovingCon,itemChangedCon
	local ffa = game.FindFirstAncestorWhichIsA
	local getDescendants = game.GetDescendants
	local getTextSize = service.TextService.GetTextSize
	local updateDebounce,refreshDebounce = false,false
	local nilNode = {Obj = Instance.new("Folder")}
	local idCounter = 0
	local scrollV,scrollH,clipboard
	local renameBox,renamingNode,searchFunc
	local sortingEnabled,autoUpdateSearch
	local table,math = table,math
	local nilMap,nilCons = {},{}
	local connectSignal = game.DescendantAdded.Connect
	local addObject,removeObject,moveObject = nil,nil,nil

	local iconData
	local remote_blocklist = {} -- list of remotes beng blocked, k = the remote instance, v = their old function :3
	nodes = nodes or {}

	addObject = function(root)
		if nodes[root] then return end

		local isNil = false
		local rootParObj = ffa(root,"Instance")
		local par = nodes[rootParObj]

		-- Nil Handling
		if not par then
			if nilMap[root] then
				nilCons[root] = nilCons[root] or {
					connectSignal(root.ChildAdded,addObject),
					connectSignal(root.AncestryChanged,moveObject),
				}
				par = nilNode
				isNil = true
			else
				return
			end
		elseif nilMap[rootParObj] or par == nilNode then
			nilMap[root] = true
			nilCons[root] = nilCons[root] or {
				connectSignal(root.ChildAdded,addObject),
				connectSignal(root.AncestryChanged,moveObject),
			}
			isNil = true
		end

		local newNode = {Obj = root, Parent = par}
		nodes[root] = newNode

		-- Automatic sorting if expanded
		if sortingEnabled and expanded[par] and par.Sorted then
			local left,right = 1,#par
			local floor = math.floor
			local sorter = Explorer.NodeSorter
			local pos = (right == 0 and 1)

			if not pos then
				while true do
					if left >= right then
						if sorter(newNode,par[left]) then
							pos = left
						else
							pos = left+1
						end
						break
					end

					local mid = floor((left+right)/2)
					if sorter(newNode,par[mid]) then
						right = mid-1
					else
						left = mid+1
					end
				end
			end

			table.insert(par,pos,newNode)
		else
			par[#par+1] = newNode
			par.Sorted = nil
		end

		local insts = getDescendants(root)
		for i = 1,#insts do
			local obj = insts[i]
			if nodes[obj] then continue end -- Deferred

			local par = nodes[ffa(obj,"Instance")]
			if not par then continue end
			local newNode = {Obj = obj, Parent = par}
			nodes[obj] = newNode
			par[#par+1] = newNode

			-- Nil Handling
			if isNil then
				nilMap[obj] = true
				nilCons[obj] = nilCons[obj] or {
					connectSignal(obj.ChildAdded,addObject),
					connectSignal(obj.AncestryChanged,moveObject),
				}
			end
		end

		if searchFunc and autoUpdateSearch then
			searchFunc({newNode})
		end

		if not updateDebounce and Explorer.IsNodeVisible(par) then
			if expanded[par] then
				Explorer.PerformUpdate()
			elseif not refreshDebounce then
				Explorer.PerformRefresh()
			end
		end
	end

	removeObject = function(root)
		local node = nodes[root]
		if not node then return end

		-- Nil Handling
		if nilMap[node.Obj] then
			moveObject(node.Obj)
			return
		end

		local par = node.Parent
		if par then
			par.HasDel = true
		end

		local function recur(root)
			for i = 1,#root do
				local node = root[i]
				if not node.Del then
					nodes[node.Obj] = nil
					if #node > 0 then recur(node) end
				end
			end
		end
		recur(node)
		node.Del = true
		nodes[root] = nil

		if par and not updateDebounce and Explorer.IsNodeVisible(par) then
			if expanded[par] then
				Explorer.PerformUpdate()
			elseif not refreshDebounce then
				Explorer.PerformRefresh()
			end
		end
	end

	moveObject = function(obj)
		local node = nodes[obj]
		if not node then return end

		local oldPar = node.Parent
		local newPar = nodes[ffa(obj,"Instance")]
		if oldPar == newPar then return end

		-- Nil Handling
		if not newPar then
			if nilMap[obj] then
				newPar = nilNode
			else
				return
			end
		elseif nilMap[newPar.Obj] or newPar == nilNode then
			nilMap[obj] = true
			nilCons[obj] = nilCons[obj] or {
				connectSignal(obj.ChildAdded,addObject),
				connectSignal(obj.AncestryChanged,moveObject),
			}
		end

		if oldPar then
			local parPos = table.find(oldPar,node)
			if parPos then table.remove(oldPar,parPos) end
		end

		node.Id = nil
		node.Parent = newPar

		if sortingEnabled and expanded[newPar] and newPar.Sorted then
			local left,right = 1,#newPar
			local floor = math.floor
			local sorter = Explorer.NodeSorter
			local pos = (right == 0 and 1)

			if not pos then
				while true do
					if left >= right then
						if sorter(node,newPar[left]) then
							pos = left
						else
							pos = left+1
						end
						break
					end

					local mid = floor((left+right)/2)
					if sorter(node,newPar[mid]) then
						right = mid-1
					else
						left = mid+1
					end
				end
			end

			table.insert(newPar,pos,node)
		else
			newPar[#newPar+1] = node
			newPar.Sorted = nil
		end

		if searchFunc and searchResults[node] then
			local currentNode = node.Parent
			while currentNode and (not searchResults[currentNode] or expanded[currentNode] == 0) do
				expanded[currentNode] = true
				searchResults[currentNode] = true
				currentNode = currentNode.Parent
			end
		end

		if not updateDebounce and (Explorer.IsNodeVisible(newPar) or Explorer.IsNodeVisible(oldPar)) then
			if expanded[newPar] or expanded[oldPar] then
				Explorer.PerformUpdate()
			elseif not refreshDebounce then
				Explorer.PerformRefresh()
			end
		end
	end

	Explorer.ViewWidth = 0
	Explorer.Index = 0
	Explorer.EntryIndent = 20
	Explorer.FreeWidth = 32
	Explorer.GuiElems = {}

	Explorer.InitRenameBox = function()
		renameBox = create({{1,"TextBox",{BackgroundColor3=Color3.new(0.17647059261799,0.17647059261799,0.17647059261799),BorderColor3=Color3.new(0.062745101749897,0.51764708757401,1),BorderMode=2,ClearTextOnFocus=false,Font=3,Name="RenameBox",PlaceholderColor3=Color3.new(0.69803923368454,0.69803923368454,0.69803923368454),Position=UDim2.new(0,26,0,2),Size=UDim2.new(0,200,0,16),Text="",TextColor3=Color3.new(1,1,1),TextSize=14,TextXAlignment=0,Visible=false,ZIndex=2}}})

		renameBox.Parent = Explorer.Window.GuiElems.Content.List

		renameBox.FocusLost:Connect(function()
			if not renamingNode then return end

			pcall(function() renamingNode.Obj.Name = renameBox.Text end)
			renamingNode = nil
			Explorer.Refresh()
		end)

		renameBox.Focused:Connect(function()
			renameBox.SelectionStart = 1
			renameBox.CursorPosition = #renameBox.Text + 1
		end)
	end

	Explorer.SetRenamingNode = function(node)
		renamingNode = node
		renameBox.Text = tostring(node.Obj)
		renameBox:CaptureFocus()
		Explorer.Refresh()
	end

	Explorer.SetSortingEnabled = function(val)
		sortingEnabled = val
		Settings.Explorer.Sorting = val
	end

	Explorer.UpdateView = function()
		local maxNodes = math.ceil(treeFrame.AbsoluteSize.Y / 20)
		local maxX = treeFrame.AbsoluteSize.X
		local totalWidth = Explorer.ViewWidth + Explorer.FreeWidth

		scrollV.VisibleSpace = maxNodes
		scrollV.TotalSpace = #tree + 1
		scrollH.VisibleSpace = maxX
		scrollH.TotalSpace = totalWidth

		scrollV.Gui.Visible = #tree + 1 > maxNodes
		scrollH.Gui.Visible = totalWidth > maxX

		local oldSize = treeFrame.Size
		treeFrame.Size = UDim2.new(1,(scrollV.Gui.Visible and -16 or 0),1,(scrollH.Gui.Visible and -39 or -23))
		if oldSize ~= treeFrame.Size then
			Explorer.UpdateView()
		else
			scrollV:Update()
			scrollH:Update()

			renameBox.Size = UDim2.new(0,maxX-100,0,16)

			if scrollV.Gui.Visible and scrollH.Gui.Visible then
				scrollV.Gui.Size = UDim2.new(0,16,1,-39)
				scrollH.Gui.Size = UDim2.new(1,-16,0,16)
				Explorer.Window.GuiElems.Content.ScrollCorner.Visible = true
			else
				scrollV.Gui.Size = UDim2.new(0,16,1,-23)
				scrollH.Gui.Size = UDim2.new(1,0,0,16)
				Explorer.Window.GuiElems.Content.ScrollCorner.Visible = false
			end

			Explorer.Index = scrollV.Index
		end
	end

	Explorer.NodeSorter = function(a,b)
		if a.Del or b.Del then return false end -- Ghost node

		local aClass = a.Class
		local bClass = b.Class
		if not aClass then aClass = a.Obj.ClassName a.Class = aClass end
		if not bClass then bClass = b.Obj.ClassName b.Class = bClass end

		local aOrder = explorerOrders[aClass]
		local bOrder = explorerOrders[bClass]
		if not aOrder then aOrder = RMD.Classes[aClass] and tonumber(RMD.Classes[aClass].ExplorerOrder) or 9999 explorerOrders[aClass] = aOrder end
		if not bOrder then bOrder = RMD.Classes[bClass] and tonumber(RMD.Classes[bClass].ExplorerOrder) or 9999 explorerOrders[bClass] = bOrder end

		if aOrder ~= bOrder then
			return aOrder < bOrder
		else
			local aName,bName = tostring(a.Obj),tostring(b.Obj)
			if aName ~= bName then
				return aName < bName
			elseif aClass ~= bClass then
				return aClass < bClass
			else
				local aId = a.Id if not aId then aId = idCounter idCounter = (idCounter+0.001)%999999999 a.Id = aId end
				local bId = b.Id if not bId then bId = idCounter idCounter = (idCounter+0.001)%999999999 b.Id = bId end
				return aId < bId
			end
		end
	end

	Explorer.Update = function()
		table.clear(tree)
		local maxNameWidth,maxDepth,count = 0,1,1
		local nameCache = {}
		local font = Enum.Font.SourceSans
		local size = Vector2.new(math.huge,20)
		local useNameWidth = Settings.Explorer.UseNameWidth
		local tSort = table.sort
		local sortFunc = Explorer.NodeSorter
		local isSearching = (expanded == Explorer.SearchExpanded)
		local textServ = service.TextService

		local function recur(root,depth)
			if depth > maxDepth then maxDepth = depth end
			depth = depth + 1
			if sortingEnabled and not root.Sorted then
				tSort(root,sortFunc)
				root.Sorted = true
			end
			for i = 1,#root do
				local n = root[i]

				if (isSearching and not searchResults[n]) or n.Del then continue end

				if useNameWidth then
					local nameWidth = n.NameWidth
					if not nameWidth then
						local objName = tostring(n.Obj)
						nameWidth = nameCache[objName]
						if not nameWidth then
							nameWidth = getTextSize(textServ,objName,14,font,size).X
							nameCache[objName] = nameWidth
						end
						n.NameWidth = nameWidth
					end
					if nameWidth > maxNameWidth then
						maxNameWidth = nameWidth
					end
				end

				tree[count] = n
				count = count + 1
				if expanded[n] and #n > 0 then
					recur(n,depth)
				end
			end
		end

		recur(nodes[game],1)

		-- Nil Instances
		if env.getnilinstances then
			if not (isSearching and not searchResults[nilNode]) then
				tree[count] = nilNode
				count = count + 1
				if expanded[nilNode] then
					recur(nilNode,2)
				end
			end
		end

		Explorer.MaxNameWidth = maxNameWidth
		Explorer.MaxDepth = maxDepth
		Explorer.ViewWidth = useNameWidth and Explorer.EntryIndent*maxDepth + maxNameWidth + 26 or Explorer.EntryIndent*maxDepth + 226
		Explorer.UpdateView()
	end

	Explorer.StartDrag = function(offX,offY)
		if Explorer.Dragging then return end
		for i,v in next, selection.List do
			local Obj = v.Obj
			if Obj.Parent == game or Obj:IsA("Player") then
				return
			end
		end
		Explorer.Dragging = true

		local dragTree = treeFrame:Clone()
		dragTree:ClearAllChildren()

		for i,v in pairs(listEntries) do
			local node = tree[i + Explorer.Index]
			if node and selection.Map[node] then
				local clone = v:Clone()
				clone.Active = false
				clone.Indent.Expand.Visible = false
				clone.Parent = dragTree
			end
		end

		local newGui = Instance.new("ScreenGui")
		newGui.DisplayOrder = Main.DisplayOrders.Menu
		dragTree.Parent = newGui
		Lib.ShowGui(newGui)

		local dragOutline = create({
			{1,"Frame",{BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=1,Name="DragSelect",Size=UDim2.new(1,0,1,0),}},
			{2,"Frame",{BackgroundColor3=Color3.new(1,1,1),BorderSizePixel=0,Name="Line",Parent={1},Size=UDim2.new(1,0,0,1),ZIndex=2,}},
			{3,"Frame",{BackgroundColor3=Color3.new(1,1,1),BorderSizePixel=0,Name="Line",Parent={1},Position=UDim2.new(0,0,1,-1),Size=UDim2.new(1,0,0,1),ZIndex=2,}},
			{4,"Frame",{BackgroundColor3=Color3.new(1,1,1),BorderSizePixel=0,Name="Line",Parent={1},Size=UDim2.new(0,1,1,0),ZIndex=2,}},
			{5,"Frame",{BackgroundColor3=Color3.new(1,1,1),BorderSizePixel=0,Name="Line",Parent={1},Position=UDim2.new(1,-1,0,0),Size=UDim2.new(0,1,1,0),ZIndex=2,}},
		})
		dragOutline.Parent = treeFrame

		local mouse = Main.Mouse or service.Players.LocalPlayer:GetMouse()
		local function move()
			local posX = mouse.X - offX
			local posY = mouse.Y - offY
			dragTree.Position = UDim2.new(0,posX,0,posY)

			for i = 1,#listEntries do
				local entry = listEntries[i]
				if Lib.CheckMouseInGui(entry) then
					dragOutline.Position = UDim2.new(0,entry.Indent.Position.X.Offset-scrollH.Index,0,entry.Position.Y.Offset)
					dragOutline.Size = UDim2.new(0,entry.Size.X.Offset-entry.Indent.Position.X.Offset,0,20)
					dragOutline.Visible = true
					return
				end
			end
			dragOutline.Visible = false
		end
		move()

		local input = service.UserInputService
		local mouseEvent,releaseEvent

		mouseEvent = input.InputChanged:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
				move()
			end
		end)

		releaseEvent = input.InputEnded:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				releaseEvent:Disconnect()
				mouseEvent:Disconnect()
				newGui:Destroy()
				dragOutline:Destroy()
				Explorer.Dragging = false

				for i = 1,#listEntries do
					if Lib.CheckMouseInGui(listEntries[i]) then
						local node = tree[i + Explorer.Index]
						if node then
							if selection.Map[node] then return end
							local newPar = node.Obj
							local sList = selection.List
							for i = 1,#sList do
								local n = sList[i]
								pcall(function() n.Obj.Parent = newPar end)
							end
							Explorer.ViewNode(sList[1])
						end
						break
					end
				end
			end
		end)
	end

	Explorer.NewListEntry = function(index)
		local newEntry = entryTemplate:Clone()
		newEntry.Position = UDim2.new(0,0,0,20*(index-1))

		local isRenaming = false

		newEntry.InputBegan:Connect(function(input)
			local node = tree[index + Explorer.Index]
			if not node or selection.Map[node] or (input.UserInputType ~= Enum.UserInputType.MouseMovement and input.UserInputType ~= Enum.UserInputType.Touch) then return end

			newEntry.Indent.BackgroundColor3 = Settings.Theme.Button
			newEntry.Indent.BorderSizePixel = 0
			newEntry.Indent.BackgroundTransparency = 0
		end)

		newEntry.InputEnded:Connect(function(input)
			local node = tree[index + Explorer.Index]
			if not node or selection.Map[node] or (input.UserInputType ~= Enum.UserInputType.MouseMovement and input.UserInputType ~= Enum.UserInputType.Touch) then return end

			newEntry.Indent.BackgroundTransparency = 1
		end)

		newEntry.MouseButton1Down:Connect(function()

		end)

		newEntry.MouseButton1Up:Connect(function()

		end)

		newEntry.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				local releaseEvent, mouseEvent

				local mouse = Main.Mouse or plr:GetMouse()
				local startX, startY

				if input.UserInputType == Enum.UserInputType.Touch then
					startX = input.Position.X
					startY = input.Position.Y
				else
					startX = mouse.X
					startY = mouse.Y
				end

				local listOffsetX = startX - treeFrame.AbsolutePosition.X
				local listOffsetY = startY - treeFrame.AbsolutePosition.Y

				releaseEvent = service.UserInputService.InputEnded:Connect(function(input)
					if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
						releaseEvent:Disconnect()
						mouseEvent:Disconnect()
					end
				end)

				mouseEvent = service.UserInputService.InputChanged:Connect(function(input)
					if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
						local currentX, currentY

						if input.UserInputType == Enum.UserInputType.Touch then
							currentX = input.Position.X
							currentY = input.Position.Y
						else
							currentX = mouse.X
							currentY = mouse.Y
						end

						local deltaX = currentX - startX
						local deltaY = currentY - startY
						local dist = math.sqrt(deltaX^2 + deltaY^2)

						if dist > 5 then
							releaseEvent:Disconnect()
							mouseEvent:Disconnect()
							isRenaming = false
							Explorer.StartDrag(listOffsetX, listOffsetY)
						end
					end
				end)
			end
		end)

		newEntry.MouseButton2Down:Connect(function()

		end)

		newEntry.Indent.Expand.InputBegan:Connect(function(input)
			local node = tree[index + Explorer.Index]
			if not node or (input.UserInputType ~= Enum.UserInputType.MouseMovement and input.UserInputType ~= Enum.UserInputType.Touch) then return end

			if input.UserInputType == Enum.UserInputType.Touch then
				Explorer.MiscIcons:DisplayByKey(newEntry.Indent.Expand.Icon, expanded[node] and "Collapse_Over" or "Expand_Over")
			elseif input.UserInputType == Enum.UserInputType.MouseMovement then
				Explorer.MiscIcons:DisplayByKey(newEntry.Indent.Expand.Icon, expanded[node] and "Collapse_Over" or "Expand_Over")
			end
		end)

		newEntry.Indent.Expand.InputEnded:Connect(function(input)
			local node = tree[index + Explorer.Index]
			if not node or (input.UserInputType ~= Enum.UserInputType.MouseMovement and input.UserInputType ~= Enum.UserInputType.Touch) then return end

			if input.UserInputType == Enum.UserInputType.Touch then
				Explorer.MiscIcons:DisplayByKey(newEntry.Indent.Expand.Icon, expanded[node] and "Collapse" or "Expand")
			elseif input.UserInputType == Enum.UserInputType.MouseMovement then
				Explorer.MiscIcons:DisplayByKey(newEntry.Indent.Expand.Icon, expanded[node] and "Collapse" or "Expand")
			end
		end)

		newEntry.Indent.Expand.MouseButton1Down:Connect(function()
			local node = tree[index + Explorer.Index]
			if not node or #node == 0 then return end

			expanded[node] = not expanded[node]
			Explorer.Update()
			Explorer.Refresh()
		end)

		newEntry.Parent = treeFrame
		return newEntry
	end

	Explorer.Refresh = function()
		local maxNodes = math.max(math.ceil((treeFrame.AbsoluteSize.Y) / 20), 0)	
		local renameNodeVisible = false
		local isa = game.IsA

		for i = 1,maxNodes do
			local entry = listEntries[i]
			if not listEntries[i] then entry = Explorer.NewListEntry(i) listEntries[i] = entry Explorer.ClickSystem:Add(entry) end

			local node = tree[i + Explorer.Index]
			if node then
				local obj = node.Obj
				local depth = Explorer.EntryIndent*Explorer.NodeDepth(node)

				entry.Visible = true
				entry.Position = UDim2.new(0,-scrollH.Index,0,entry.Position.Y.Offset)
				entry.Size = UDim2.new(0,Explorer.ViewWidth,0,20)
				entry.Indent.EntryName.Text = tostring(node.Obj)
				entry.Indent.Position = UDim2.new(0,depth,0,0)
				entry.Indent.Size = UDim2.new(1,-depth,1,0)

				entry.Indent.EntryName.TextTruncate = (Settings.Explorer.UseNameWidth and Enum.TextTruncate.None or Enum.TextTruncate.AtEnd)

				Explorer.MiscIcons:DisplayExplorerIcons(entry.Indent.Icon, obj.ClassName)

				if selection.Map[node] then
					entry.Indent.BackgroundColor3 = Settings.Theme.ListSelection
					entry.Indent.BorderSizePixel = 0
					entry.Indent.BackgroundTransparency = 0
				else
					if Lib.CheckMouseInGui(entry) then
						entry.Indent.BackgroundColor3 = Settings.Theme.Button
					else
						entry.Indent.BackgroundTransparency = 1
					end
				end

				if node == renamingNode then
					renameNodeVisible = true
					renameBox.Position = UDim2.new(0,depth+25-scrollH.Index,0,entry.Position.Y.Offset+2)
					renameBox.Visible = true
				end

				if #node > 0 and expanded[node] ~= 0 then
					if Lib.CheckMouseInGui(entry.Indent.Expand) then
						Explorer.MiscIcons:DisplayByKey(entry.Indent.Expand.Icon, expanded[node] and "Collapse_Over" or "Expand_Over")
					else
						Explorer.MiscIcons:DisplayByKey(entry.Indent.Expand.Icon, expanded[node] and "Collapse" or "Expand")
					end
					entry.Indent.Expand.Visible = true
				else
					entry.Indent.Expand.Visible = false
				end
			else
				entry.Visible = false
			end
		end

		if not renameNodeVisible then
			renameBox.Visible = false
		end

		for i = maxNodes+1, #listEntries do
			Explorer.ClickSystem:Remove(listEntries[i])
			listEntries[i]:Destroy()
			listEntries[i] = nil
		end
	end

	Explorer.PerformUpdate = function(instant)
		updateDebounce = true
		Lib.FastWait(not instant and 0.1)
		if not updateDebounce then return end
		updateDebounce = false
		if not Explorer.Window:IsVisible() then return end
		Explorer.Update()
		Explorer.Refresh()
	end

	Explorer.ForceUpdate = function(norefresh)
		updateDebounce = false
		Explorer.Update()
		if not norefresh then Explorer.Refresh() end
	end

	Explorer.PerformRefresh = function()
		refreshDebounce = true
		Lib.FastWait(0.1)
		refreshDebounce = false
		if updateDebounce or not Explorer.Window:IsVisible() then return end
		Explorer.Refresh()
	end

	Explorer.IsNodeVisible = function(node)
		if not node then return end

		local curNode = node.Parent
		while curNode do
			if not expanded[curNode] then return false end
			curNode = curNode.Parent
		end
		return true
	end

	Explorer.NodeDepth = function(node)
		local depth = 0

		if node == nilNode then
			return 1
		end

		local curNode = node.Parent
		while curNode do
			if curNode == nilNode then depth = depth + 1 end
			curNode = curNode.Parent
			depth = depth + 1
		end
		return depth
	end

	Explorer.SetupConnections = function()
		if descendantAddedCon then descendantAddedCon:Disconnect() end
		if descendantRemovingCon then descendantRemovingCon:Disconnect() end
		if itemChangedCon then itemChangedCon:Disconnect() end

		if Main.Elevated then
			descendantAddedCon = game.DescendantAdded:Connect(addObject)
			descendantRemovingCon = game.DescendantRemoving:Connect(removeObject)
		else
			descendantAddedCon = game.DescendantAdded:Connect(function(obj) pcall(addObject,obj) end)
			descendantRemovingCon = game.DescendantRemoving:Connect(function(obj) pcall(removeObject,obj) end)
		end

		if Settings.Explorer.UseNameWidth then
			itemChangedCon = game.ItemChanged:Connect(function(obj,prop)
				if prop == "Parent" and nodes[obj] then
					moveObject(obj)
				elseif prop == "Name" and nodes[obj] then
					nodes[obj].NameWidth = nil
				end
			end)
		else
			itemChangedCon = game.ItemChanged:Connect(function(obj,prop)
				if prop == "Parent" and nodes[obj] then
					moveObject(obj)
				end
			end)
		end
	end

	Explorer.ViewNode = function(node)
		if not node then return end

		Explorer.MakeNodeVisible(node)
		Explorer.ForceUpdate(true)
		local visibleSpace = scrollV.VisibleSpace

		for i,v in next,tree do
			if v == node then
				local relative = i - 1
				if Explorer.Index > relative then
					scrollV.Index = relative
				elseif Explorer.Index + visibleSpace - 1 <= relative then
					scrollV.Index = relative - visibleSpace + 2
				end
			end
		end

		scrollV:Update() Explorer.Index = scrollV.Index
		Explorer.Refresh()
	end

	Explorer.ViewObj = function(obj)
		Explorer.ViewNode(nodes[obj])
	end

	Explorer.MakeNodeVisible = function(node,expandRoot)
		if not node then return end

		local hasExpanded = false

		if expandRoot and not expanded[node] then
			expanded[node] = true
			hasExpanded = true
		end

		local currentNode = node.Parent
		while currentNode do
			hasExpanded = true
			expanded[currentNode] = true
			currentNode = currentNode.Parent
		end

		if hasExpanded and not updateDebounce then
			coroutine.wrap(Explorer.PerformUpdate)(true)
		end
	end

	Explorer.ShowRightClick = function(MousePos)
		local Mouse = MousePos or Main.Mouse
		local context = Explorer.RightClickContext
		local absoluteSize = context.Gui.AbsoluteSize
		context.MaxHeight = (absoluteSize.Y <= 600 and (absoluteSize.Y - 40)) or nil
		context:Clear()

		local sList = selection.List
		local sMap = selection.Map
		local emptyClipboard = #clipboard == 0
		local presentClasses = {}
		local apiClasses = API.Classes

		for i = 1, #sList do
			local node = sList[i]
			local class = node.Class
			local obj = node.Obj

			if not presentClasses.isViableDecompileScript then
				presentClasses.isViableDecompileScript = env.isViableDecompileScript(obj)
			end
			if not class then
				class = obj.ClassName
				node.Class = class
			end

			local curClass = apiClasses[class]
			while curClass and not presentClasses[curClass.Name] do
				presentClasses[curClass.Name] = true
				curClass = curClass.Superclass
			end
		end

		context:AddRegistered("CUT")
		context:AddRegistered("COPY")
		context:AddRegistered("PASTE", emptyClipboard)
		context:AddRegistered("DUPLICATE")
		context:AddRegistered("DELETE")
		context:AddRegistered("DELETE_CHILDREN", #sList ~= 1)
		context:AddRegistered("RENAME", #sList ~= 1)

		context:AddDivider()
		context:AddRegistered("GROUP")
		context:AddRegistered("UNGROUP")
		context:AddRegistered("SELECT_CHILDREN")
		context:AddRegistered("JUMP_TO_PARENT")
		context:AddRegistered("EXPAND_ALL")
		context:AddRegistered("COLLAPSE_ALL")

		context:AddDivider()

		if expanded == Explorer.SearchExpanded then context:AddRegistered("CLEAR_SEARCH_AND_JUMP_TO") end
		if env.setclipboard then context:AddRegistered("COPY_PATH") end
		context:AddRegistered("INSERT_OBJECT")
		context:AddRegistered("SAVE_INST")
		-- context:AddRegistered("CALL_FUNCTION")
		-- context:AddRegistered("VIEW_CONNECTIONS")
		-- context:AddRegistered("GET_REFERENCES")
		context:AddRegistered("COPY_API_PAGE")

		context:QueueDivider()

		if #sList > 0 and env.teleportto then
			context:AddRegistered("TELEPORT_TO")
		end
		if presentClasses["BasePart"] or presentClasses["Model"] then
			context:AddRegistered("VIEW_OBJECT")
			context:AddRegistered("3DVIEW_MODEL")
		end
		if presentClasses["Tween"] then context:AddRegistered("PLAY_TWEEN") end
		if presentClasses["Animation"] then
			context:AddRegistered("LOAD_ANIMATION")
			context:AddRegistered("STOP_ANIMATION")
		end

		if presentClasses["TouchTransmitter"] then context:AddRegistered("FIRE_TOUCHTRANSMITTER", firetouchinterest == nil) end
		if presentClasses["ClickDetector"] then context:AddRegistered("FIRE_CLICKDETECTOR", fireclickdetector == nil) end
		if presentClasses["ProximityPrompt"] then context:AddRegistered("FIRE_PROXIMITYPROMPT", fireproximityprompt == nil) end
		
		
		if presentClasses["RemoteEvent"] then context:AddRegistered("BLOCK_REMOTE", env.hookfunction == nil) end
		if presentClasses["RemoteEvent"] then context:AddRegistered("UNBLOCK_REMOTE", env.hookfunction == nil) end
		
		if presentClasses["RemoteFunction"] then context:AddRegistered("BLOCK_REMOTE", env.hookfunction == nil) end
		if presentClasses["RemoteFunction"] then context:AddRegistered("UNBLOCK_REMOTE", env.hookfunction == nil) end

		if presentClasses["UnreliableRemoteEvent"] then context:AddRegistered("BLOCK_REMOTE", env.hookfunction == nil) end
		if presentClasses["UnreliableRemoteEvent"] then context:AddRegistered("UNBLOCK_REMOTE", env.hookfunction == nil) end
		
		
		if presentClasses["BindableEvent"] then context:AddRegistered("BLOCK_REMOTE", env.hookfunction == nil) end
		if presentClasses["BindableEvent"] then context:AddRegistered("UNBLOCK_REMOTE", env.hookfunction == nil) end
		
		if presentClasses["BindableFunction"] then context:AddRegistered("BLOCK_REMOTE", env.hookfunction == nil) end
		if presentClasses["BindableFunction"] then context:AddRegistered("UNBLOCK_REMOTE", env.hookfunction == nil) end
		
		
		
		if presentClasses["Player"] then context:AddRegistered("SELECT_CHARACTER")context:AddRegistered("VIEW_PLAYER") end
		if presentClasses["Players"] then
			context:AddRegistered("SELECT_LOCAL_PLAYER")
			context:AddRegistered("SELECT_ALL_CHARACTERS")
		end

		if presentClasses["LuaSourceContainer"] then
			context:AddRegistered("VIEW_SCRIPT", not presentClasses.isViableDecompileScript or not env.isdecompile)
			context:AddRegistered("DUMP_FUNCTIONS", not presentClasses.isViableDecompileScript or env.getupvalues == nil or env.getconstants == nil)
			context:AddRegistered("SAVE_SCRIPT", not presentClasses.isViableDecompileScript or not env.isdecompile or env.writefile == nil)
			context:AddRegistered("SAVE_BYTECODE", not presentClasses.isViableDecompileScript or env.getscriptbytecode == nil or env.writefile == nil)

		end

		if sMap[nilNode] then
			context:AddRegistered("REFRESH_NIL")
			context:AddRegistered("HIDE_NIL")
		end

		Explorer.LastRightClickX, Explorer.LastRightClickY = Mouse.X, Mouse.Y
		context:Show(Mouse.X, Mouse.Y)
	end

	Explorer.InitRightClick = function()
		local context = Lib.ContextMenu.new()

		context:Register("CUT",{Name = "Cut", IconMap = Explorer.MiscIcons, Icon = "Cut", DisabledIcon = "Cut_Disabled", Shortcut = "Ctrl+Z", OnClick = function()
			local destroy,clone = game.Destroy,game.Clone
			local sList,newClipboard = selection.List,{}
			local count = 1
			for i = 1,#sList do
				local inst = sList[i].Obj
				local s,cloned = pcall(clone,inst)
				if s and cloned then
					newClipboard[count] = cloned
					count = count + 1
				end
				pcall(destroy,inst)
			end
			clipboard = newClipboard
			selection:Clear()
		end})

		context:Register("COPY",{Name = "Copy", IconMap = Explorer.MiscIcons, Icon = "Copy", DisabledIcon = "Copy_Disabled", Shortcut = "Ctrl+C", OnClick = function()
			local clone = game.Clone
			local sList,newClipboard = selection.List,{}
			local count = 1
			for i = 1,#sList do
				local inst = sList[i].Obj
				local s,cloned = pcall(clone,inst)
				if s and cloned then
					newClipboard[count] = cloned
					count = count + 1
				end
			end
			clipboard = newClipboard
		end})

		context:Register("PASTE",{Name = "Paste Into", IconMap = Explorer.MiscIcons, Icon = "Paste", DisabledIcon = "Paste_Disabled", Shortcut = "Ctrl+Shift+V", OnClick = function()
			local sList = selection.List
			local newSelection = {}
			local count = 1
			for i = 1,#sList do
				local node = sList[i]
				local inst = node.Obj
				Explorer.MakeNodeVisible(node,true)
				for c = 1,#clipboard do
					local cloned = clipboard[c]:Clone()
					if cloned then
						cloned.Parent = inst
						local clonedNode = nodes[cloned]
						if clonedNode then newSelection[count] = clonedNode count = count + 1 end
					end
				end
			end
			selection:SetTable(newSelection)

			if #newSelection > 0 then
				Explorer.ViewNode(newSelection[1])
			end
		end})

		context:Register("DUPLICATE",{Name = "Duplicate", IconMap = Explorer.MiscIcons, Icon = "Copy", DisabledIcon = "Copy_Disabled", Shortcut = "Ctrl+D", OnClick = function()
			local clone = game.Clone
			local sList = selection.List
			local newSelection = {}
			local count = 1
			for i = 1,#sList do
				local node = sList[i]
				local inst = node.Obj
				local instPar = node.Parent and node.Parent.Obj
				Explorer.MakeNodeVisible(node)
				local s,cloned = pcall(clone,inst)
				if s and cloned then
					cloned.Parent = instPar
					local clonedNode = nodes[cloned]
					if clonedNode then newSelection[count] = clonedNode count = count + 1 end
				end
			end

			selection:SetTable(newSelection)
			if #newSelection > 0 then
				Explorer.ViewNode(newSelection[1])
			end
		end})

		context:Register("DELETE",{Name = "Delete", IconMap = Explorer.MiscIcons, Icon = "Delete", DisabledIcon = "Delete_Disabled", Shortcut = "Del", OnClick = function()
			local destroy = game.Destroy
			local sList = selection.List
			for i = 1,#sList do
				pcall(destroy,sList[i].Obj)
			end
			selection:Clear()
		end})
		
		context:Register("DELETE_CHILDREN",{Name = "Delete Children", IconMap = Explorer.MiscIcons, Icon = "Delete", DisabledIcon = "Delete_Disabled", Shortcut = "Shift+Del", OnClick = function()
			local sList = selection.List
			for i = 1,#sList do
				pcall(sList[i].Obj.ClearAllChildren,sList[i].Obj)
			end
			selection:Clear()
		end})
		context:Register("RENAME",{Name = "Rename", IconMap = Explorer.MiscIcons, Icon = "Rename", DisabledIcon = "Rename_Disabled", Shortcut = "F2", OnClick = function()
			local sList = selection.List
			if sList[1] then
				Explorer.SetRenamingNode(sList[1])
			end
		end})

		context:Register("GROUP",{Name = "Group", IconMap = Explorer.MiscIcons, Icon = "Group", DisabledIcon = "Group_Disabled", Shortcut = "Ctrl+G", OnClick = function()
			local sList = selection.List
			if #sList == 0 then return end

			local model = Instance.new("Model",sList[#sList].Obj.Parent)
			for i = 1,#sList do
				pcall(function() sList[i].Obj.Parent = model end)
			end

			if nodes[model] then
				selection:Set(nodes[model])
				Explorer.ViewNode(nodes[model])
			end
		end})

		context:Register("UNGROUP",{Name = "Ungroup", IconMap = Explorer.MiscIcons, Icon = "Ungroup", DisabledIcon = "Ungroup_Disabled", Shortcut = "Ctrl+U", OnClick = function()
			local newSelection = {}
			local count = 1
			local isa = game.IsA

			local function ungroup(node)
				local par = node.Parent.Obj
				local ch = {}
				local chCount = 1

				for i = 1,#node do
					local n = node[i]
					newSelection[count] = n
					ch[chCount] = n
					count = count + 1
					chCount = chCount + 1
				end

				for i = 1,#ch do
					pcall(function() ch[i].Obj.Parent = par end)
				end

				node.Obj:Destroy()
			end

			for i,v in next,selection.List do
				if isa(v.Obj,"Model") then
					ungroup(v)
				end
			end

			selection:SetTable(newSelection)
			if #newSelection > 0 then
				Explorer.ViewNode(newSelection[1])
			end
		end})

		context:Register("SELECT_CHILDREN",{Name = "Select Children", IconMap = Explorer.MiscIcons, Icon = "SelectChildren", DisabledIcon = "SelectChildren_Disabled", OnClick = function()
			local newSelection = {}
			local count = 1
			local sList = selection.List

			for i = 1,#sList do
				local node = sList[i]
				for ind = 1,#node do
					local cNode = node[ind]
					if ind == 1 then Explorer.MakeNodeVisible(cNode) end

					newSelection[count] = cNode
					count = count + 1
				end
			end

			selection:SetTable(newSelection)
			if #newSelection > 0 then
				Explorer.ViewNode(newSelection[1])
			else
				Explorer.Refresh()
			end
		end})

		context:Register("JUMP_TO_PARENT",{Name = "Jump to Parent", IconMap = Explorer.MiscIcons, Icon = "JumpToParent", OnClick = function()
			local newSelection = {}
			local count = 1
			local sList = selection.List

			for i = 1,#sList do
				local node = sList[i]
				if node.Parent then
					newSelection[count] = node.Parent
					count = count + 1
				end
			end

			selection:SetTable(newSelection)
			if #newSelection > 0 then
				Explorer.ViewNode(newSelection[1])
			else
				Explorer.Refresh()
			end
		end})

		context:Register("TELEPORT_TO",{Name = "Teleport To", IconMap = Explorer.MiscIcons, Icon = "TeleportTo", OnClick = function()
			local sList = selection.List
			local lastError = "No valid position was found in the selection"

			for _, node in ipairs(sList) do
				local success, detail = env.teleportto(node.Obj, Settings.Explorer.TeleportToOffset)
				if success then
					env.notify("Dex++ Teleport", detail, 4)
					return
				end
				lastError = detail or lastError
			end

			env.notify("Dex++ Teleport - Error", lastError, 7)
		end})

		local OldAnimation
		context:Register("PLAY_TWEEN",{Name = "Play Tween", IconMap = Explorer.MiscIcons, Icon = "Play", OnClick = function()
			local sList = selection.List

			for i = 1, #sList do
				local node = sList[i]
				local Obj = node.Obj

				if Obj:IsA("Tween") then Obj:Play() end
			end
		end})

		local OldAnimation
		context:Register("LOAD_ANIMATION",{Name = "Load Animation", IconMap = Explorer.MiscIcons, Icon = "Play", OnClick = function()
			local sList = selection.List

			local Humanoid = plr.Character and plr.Character:FindFirstChild("Humanoid")
			if not Humanoid then return end

			for i = 1, #sList do
				local node = sList[i]
				local Obj = node.Obj

				if Obj:IsA("Animation") then
					if OldAnimation then OldAnimation:Stop() end
					OldAnimation = Humanoid:LoadAnimation(Obj)
					OldAnimation:Play()
					break
				end
			end
		end})

		context:Register("STOP_ANIMATION",{Name = "Stop Animation", IconMap = Explorer.MiscIcons, Icon = "Pause", OnClick = function()
			local sList = selection.List

			local Humanoid = plr.Character and plr.Character:FindFirstChild("Humanoid")
			if not Humanoid then return end

			for i = 1, #sList do
				local node = sList[i]
				local Obj = node.Obj

				if Obj:IsA("Animation") then
					if OldAnimation then OldAnimation:Stop() end
					Humanoid:LoadAnimation(Obj):Stop()
					break
				end
			end
		end})

		context:Register("EXPAND_ALL",{Name = "Expand All", OnClick = function()
			local sList = selection.List

			local function expand(node)
				expanded[node] = true
				for i = 1,#node do
					if #node[i] > 0 then
						expand(node[i])
					end
				end
			end

			for i = 1,#sList do
				expand(sList[i])
			end

			Explorer.ForceUpdate()
		end})

		context:Register("COLLAPSE_ALL",{Name = "Collapse All", OnClick = function()
			local sList = selection.List

			local function expand(node)
				expanded[node] = nil
				for i = 1,#node do
					if #node[i] > 0 then
						expand(node[i])
					end
				end
			end

			for i = 1,#sList do
				expand(sList[i])
			end

			Explorer.ForceUpdate()
		end})

		context:Register("CLEAR_SEARCH_AND_JUMP_TO",{Name = "Clear Search and Jump to", OnClick = function()
			local newSelection = {}
			local count = 1
			local sList = selection.List

			for i = 1,#sList do
				newSelection[count] = sList[i]
				count = count + 1
			end

			selection:SetTable(newSelection)
			Explorer.ClearSearch()
			if #newSelection > 0 then
				Explorer.ViewNode(newSelection[1])
			end
		end})

		-- this code is very bad but im lazy and it works so cope
		local clth = function(str)
			if str:sub(1, 28) == "game:GetService(\"Workspace\")" then str = str:gsub("game:GetService%(\"Workspace\"%)", "workspace", 1) end
			if str:sub(1, 27 + #plr.Name) == "game:GetService(\"Players\")." .. plr.Name then str = str:gsub("game:GetService%(\"Players\"%)." .. plr.Name, "game:GetService(\"Players\").LocalPlayer", 1) end
			return str
		end

		context:Register("COPY_PATH",{Name = "Copy Path", IconMap = Explorer.LegacyClassIcons, Icon = 50, OnClick = function()
			local sList = selection.List
			if #sList == 1 then
				env.setclipboard(clth(Explorer.GetInstancePath(sList[1].Obj)))
			elseif #sList > 1 then
				local resList = {"{"}
				local count = 2
				for i = 1,#sList do
					local path = "\t"..clth(Explorer.GetInstancePath(sList[i].Obj))..","
					if #path > 0 then
						resList[count] = path
						count = count+1
					end
				end
				resList[count] = "}"
				env.setclipboard(table.concat(resList,"\n"))
			end
		end})

		context:Register("INSERT_OBJECT",{Name = "Insert Object", IconMap = Explorer.MiscIcons, Icon = "InsertObject", OnClick = function()
			local mouse = Main.Mouse
			local x,y = Explorer.LastRightClickX or mouse.X, Explorer.LastRightClickY or mouse.Y
			Explorer.InsertObjectContext:Show(x,y)
		end})

		--[[context:Register("CALL_FUNCTION",{Name = "Call Function", IconMap = Explorer.ClassIcons, Icon = 66, OnClick = function()

		end})

		context:Register("GET_REFERENCES",{Name = "Get Lua References", IconMap = Explorer.ClassIcons, Icon = 34, OnClick = function()

		end})]]

		context:Register("SAVE_INST",{Name = "Save to File", IconMap = Explorer.MiscIcons, Icon = "Save", OnClick = function()
			local sList = selection.List
			if #sList == 0 then return end

			local objects = table.create(#sList)
			for index, node in ipairs(sList) do
				objects[index] = node.Obj
			end

			local target = #objects == 1 and objects[1] or objects
			local label = #objects == 1
				and (objects[1].ClassName .. "_" .. objects[1].Name)
				or ("Selection_" .. #objects .. "_Instances")
			local defaultName = env.parsefile("Place_" .. game.PlaceId .. "_" .. label .. "_" .. os.time())

			Lib.SaveAsPrompt(defaultName, function(filename)
				local _, savedPath = env.saveinstance(target, filename, {
					Decompile = false,
					DecompileIgnoreNames = {"ConveyorBeltSimulator"},
					SaveBytecode = false,
					SavePlayerCharacters = true,
					ShowStatus = true
				})
				return true, savedPath
			end, "rbxmx")
		end})

        --[[context:Register("VIEW_CONNECTIONS",{Name = "View Connections", OnClick = function()
            
        end})]]
		local ClassFire = {
			RemoteEvent = "FireServer",
			RemoteFunction = "InvokeServer",
			UnreliableRemoteEvent = "FireServer",

			BindableRemote = "Fire",
			BindableFunction = "Invoke",
		}
		context:Register("BLOCK_REMOTE",{Name = "Block From Firing", IconMap = Explorer.MiscIcons, Icon = "Delete", DisabledIcon = "Empty", OnClick = function()
			local sList = selection.List
			for i, list in sList do
				local obj = list.Obj
				if not remote_blocklist[obj] then
					local functionToHook = ClassFire[obj.ClassName]
					remote_blocklist[obj] = true
					local old; old = env.hookmetamethod((oldgame or game), "__namecall", function(self, ...)
						if remote_blocklist[obj] and self == obj and getnamecallmethod() == functionToHook then
							return nil
						end
						return old(self,...)
					end)
					if Settings.RemoteBlockWriteAttribute then
						obj:SetAttribute("IsBlocked", true)
					end
					--print("blocking ",functionToHook)
				end
			end
		end})
		
		context:Register("UNBLOCK_REMOTE",{Name = "Unblock", IconMap = Explorer.MiscIcons, Icon = "Play", DisabledIcon = "Empty", OnClick = function()
			local sList = selection.List
			for i, list in sList do
				local obj = list.Obj
				if remote_blocklist[obj] then
					remote_blocklist[obj] = nil
					if Settings.RemoteBlockWriteAttribute then
						list.Obj:SetAttribute("IsBlocked", false)
					end
					--print("unblocking ",functionToHook)
				end
			end
		end})

		context:Register("COPY_API_PAGE",{Name = "Copy Roblox API Page URL", IconMap = Explorer.MiscIcons, Icon = "Reference", OnClick = function()
			local sList = selection.List
			if #sList == 1 then
				env.setclipboard(
					"https://create.roblox.com/docs/reference/engine/classes/"..sList[1].Obj.ClassName
				)
			end
		end})

		context:Register("3DVIEW_MODEL",{Name = "3D Preview Object", IconMap = Explorer.LegacyClassIcons, Icon = 54, OnClick = function()
			local sList = selection.List
			local isa = game.IsA
			
			if #sList == 1 then
				if isa(sList[1].Obj,"BasePart") or isa(sList[1].Obj,"Model") then
					ModelViewer.ViewModel(sList[1].Obj)
					return
				end
			end
		end})
		
		context:Register("VIEW_OBJECT",{Name = "View Object (Right click to reset)", IconMap = Explorer.LegacyClassIcons, Icon = 5, OnClick = function()
			local sList = selection.List
			local isa = game.IsA

			for i = 1,#sList do
				local node = sList[i]

				if isa(node.Obj,"BasePart") or isa(node.Obj,"Model") then
					workspace.CurrentCamera.CameraSubject = node.Obj
					break
				end
			end
		end, OnRightClick = function()
			workspace.CurrentCamera.CameraSubject = plr.Character
		end})

		context:Register("VIEW_SCRIPT",{Name = "View Script", IconMap = Explorer.MiscIcons, Icon = "ViewScript", DisabledIcon = "Empty", OnClick = function()
			local scr = selection.List[1] and selection.List[1].Obj
			if scr then ScriptViewer.ViewScript(scr) end
		end})
		context:Register("DUMP_FUNCTIONS",{Name = "Dump Functions", IconMap = Explorer.MiscIcons, Icon = "SelectChildren", DisabledIcon = "Empty", OnClick = function()
			local scr = selection.List[1] and selection.List[1].Obj
			if scr then ScriptViewer.DumpFunctions(scr) end
		end})

		context:Register("FIRE_TOUCHTRANSMITTER",{Name = "Fire TouchTransmitter", OnClick = function()
			local hrp = plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
			if not hrp then return end
			for _, v in ipairs(selection.List) do if v.Obj and v.Obj:IsA("TouchTransmitter") then firetouchinterest(hrp, v.Obj.Parent, 0) end end
		end})

		context:Register("FIRE_CLICKDETECTOR",{Name = "Fire ClickDetector", OnClick = function()
			local hrp = plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
			if not hrp then return end
			for _, v in ipairs(selection.List) do if v.Obj and v.Obj:IsA("ClickDetector") then fireclickdetector(v.Obj) end end
		end})

		context:Register("FIRE_PROXIMITYPROMPT",{Name = "Fire ProximityPrompt", OnClick = function()
			local hrp = plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
			if not hrp then return end
			for _, v in ipairs(selection.List) do if v.Obj and v.Obj:IsA("ProximityPrompt") then fireproximityprompt(v.Obj) end end
		end})

		context:Register("VIEW_SCRIPT",{Name = "View Script", IconMap = Explorer.MiscIcons, Icon = "ViewScript", DisabledIcon = "Empty", OnClick = function()
			local scr = selection.List[1] and selection.List[1].Obj
			if scr then ScriptViewer.ViewScript(scr) end
		end})

		context:Register("SAVE_SCRIPT",{Name = "Save Script", IconMap = Explorer.MiscIcons, Icon = "Save", DisabledIcon = "Empty", OnClick = function()
			for _, v in next, selection.List do
				if v.Obj:IsA("LuaSourceContainer") and env.isViableDecompileScript(v.Obj) then
					local success, source = pcall(env.decompile, v.Obj)
					if not success or not source then source = ("-- DEX - %s failed to decompile %s"):format(env.executor, v.Obj.ClassName) end
					local fileName = ("%s_%s_%i_Source.txt"):format(env.parsefile(v.Obj.Name), v.Obj.ClassName, game.PlaceId)
					--env.writefile(fileName, source)
					Lib.SaveAsPrompt(fileName, source)
					
					task.wait(0.2)
				end
			end
		end})

		context:Register("SAVE_BYTECODE",{Name = "Save Script Bytecode", IconMap = Explorer.MiscIcons, Icon = "Save", DisabledIcon = "Empty", OnClick = function()
			for _, v in next, selection.List do
				if v.Obj:IsA("LuaSourceContainer") and env.isViableDecompileScript(v.Obj) then
					local success, bytecode = pcall(env.getscriptbytecode, v.Obj)
					if success and type(bytecode) == "string" then
						local fileName = ("%s_%s_%i_Bytecode.txt"):format(env.parsefile(v.Obj.Name), v.Obj.ClassName, game.PlaceId)
						--env.writefile(fileName, bytecode)
						Lib.SaveAsPrompt(fileName, bytecode)
						task.wait(0.2)
					end
				end
			end
		end})

		context:Register("SELECT_CHARACTER",{Name = "Select Character", IconMap = Explorer.LegacyClassIcons, Icon = 9, OnClick = function()
			local newSelection = {}
			local count = 1
			local sList = selection.List
			local isa = game.IsA

			for i = 1,#sList do
				local node = sList[i]
				if isa(node.Obj,"Player") and nodes[node.Obj.Character] then
					newSelection[count] = nodes[node.Obj.Character]
					count = count + 1
				end
			end

			selection:SetTable(newSelection)
			if #newSelection > 0 then
				Explorer.ViewNode(newSelection[1])
			else
				Explorer.Refresh()
			end
		end})

		context:Register("VIEW_PLAYER",{Name = "View Player", IconMap = Explorer.LegacyClassIcons, Icon = 5, OnClick = function()
			local newSelection = {}
			local count = 1
			local sList = selection.List
			local isa = game.IsA

			for i = 1,#sList do
				local node = sList[i]
				local Obj = node.Obj
				if Obj:IsA("Player") and Obj.Character then
					workspace.CurrentCamera.CameraSubject = Obj.Character
					break
				end
			end
		end})

		context:Register("SELECT_LOCAL_PLAYER",{Name = "Select Local Player", IconMap = Explorer.LegacyClassIcons, Icon = 9, OnClick = function()
			pcall(function() if nodes[plr] then selection:Set(nodes[plr]) Explorer.ViewNode(nodes[plr]) end end)
		end})

		context:Register("SELECT_ALL_CHARACTERS",{Name = "Select All Characters", IconMap = Explorer.LegacyClassIcons, Icon = 2, OnClick = function()
			local newSelection = {}
			local sList = selection.List

			for i,v in next, service.Players:GetPlayers() do
				if v.Character and nodes[v.Character] then
					if i == 1 then Explorer.MakeNodeVisible(v.Character) end
					table.insert(newSelection, nodes[v.Character])
				end
			end

			selection:SetTable(newSelection)
			if #newSelection > 0 then
				Explorer.ViewNode(newSelection[1])
			else
				Explorer.Refresh()
			end
		end})

		context:Register("REFRESH_NIL",{Name = "Refresh Nil Instances", OnClick = function()
			Explorer.RefreshNilInstances()
		end})

		context:Register("HIDE_NIL",{Name = "Hide Nil Instances", OnClick = function()
			Explorer.HideNilInstances()
		end})

		Explorer.RightClickContext = context
	end

	Explorer.HideNilInstances = function()
		table.clear(nilMap)

		local disconnectCon = Instance.new("Folder").ChildAdded:Connect(function() end).Disconnect
		for i,v in next,nilCons do
			disconnectCon(v[1])
			disconnectCon(v[2])
		end
		table.clear(nilCons)

		for i = 1,#nilNode do
			coroutine.wrap(removeObject)(nilNode[i].Obj)
		end

		Explorer.Update()
		Explorer.Refresh()
	end

	Explorer.RefreshNilInstances = function()
		if not env.getnilinstances then return end

		local nilInsts = env.getnilinstances()
		local game = game
		local getDescs = game.GetDescendants
		--local newNilMap = {}
		--local newNilRoots = {}
		--local nilRoots = Explorer.NilRoots
		--local connect = game.DescendantAdded.Connect
		--local disconnect
		--if not nilRoots then nilRoots = {} Explorer.NilRoots = nilRoots end

		for i = 1,#nilInsts do
			local obj = nilInsts[i]
			if obj ~= game then
				nilMap[obj] = true
				--newNilRoots[obj] = true

				local descs = getDescs(obj)
				for j = 1,#descs do
					nilMap[descs[j]] = true
				end
			end
		end

		-- Remove unmapped nil nodes
		--[[for i = 1,#nilNode do
			local node = nilNode[i]
			if not newNilMap[node.Obj] then
				nilMap[node.Obj] = nil
				coroutine.wrap(removeObject)(node)
			end
		end]]

		--nilMap = newNilMap

		for i = 1,#nilInsts do
			local obj = nilInsts[i]
			local node = nodes[obj]
			if not node then coroutine.wrap(addObject)(obj) end
		end

		--[[
		-- Remove old root connections
		for obj in next,nilRoots do
			if not newNilRoots[obj] then
				if not disconnect then disconnect = obj[1].Disconnect end
				disconnect(obj[1])
				disconnect(obj[2])
			end
		end
		
		for obj in next,newNilRoots do
			if not nilRoots[obj] then
				nilRoots[obj] = {
					connect(obj.DescendantAdded,addObject),
					connect(obj.DescendantRemoving,removeObject)
				}
			end
		end]]

		--nilMap = newNilMap
		--Explorer.NilRoots = newNilRoots

		Explorer.Update()
		Explorer.Refresh()
	end

	Explorer.GetInstancePath = function(obj)
		local ffc = game.FindFirstChild
		local getCh = game.GetChildren
		local path = ""
		local curObj = obj
		local ts = tostring
		local match = string.match
		local gsub = string.gsub
		local tableFind = table.find
		local useGetCh = Settings.Explorer.CopyPathUseGetChildren
		local formatLuaString = Lib.FormatLuaString

		while curObj do
			if curObj == game then
				path = "game"..path
				break
			end

			local className = curObj.ClassName
			local curName = ts(curObj)
			local indexName
			if match(curName,"^[%a_][%w_]*$") then
				indexName = "."..curName
			else
				local cleanName = formatLuaString(curName)
				indexName = '["'..cleanName..'"]'
			end

			local parObj = curObj.Parent
			if parObj then
				local fc = ffc(parObj,curName)
				if useGetCh and fc and fc ~= curObj then
					local parCh = getCh(parObj)
					local fcInd = tableFind(parCh,curObj)
					indexName = ":GetChildren()["..fcInd.."]"
				elseif parObj == game and API.Classes[className] and API.Classes[className].Tags.Service then
					indexName = ':GetService("'..className..'")'
				end
			elseif parObj == nil then
				local getnil = "local getNil = function(name, class) for _, v in next, getnilinstances() do if v.ClassName == class and v.Name == name then return v end end end"
				local gotnil = "\n\ngetNil(\"%s\", \"%s\")"
				indexName = getnil .. gotnil:format(curObj.Name, className)
			end

			path = indexName..path
			curObj = parObj
		end

		return path
	end

	Explorer.DefaultProps = {
		["BasePart"] = {
			Position = function(Obj)
				local Player = service.Players.LocalPlayer
				if Player.Character and Player.Character:FindFirstChild("HumanoidRootPart") then
					Obj.Position = (Player.Character.HumanoidRootPart.CFrame * CFrame.new(0, 0, -10)).p
				end
				return Obj.Position
			end,
			Anchored = true
		},
		["GuiObject"] = {
			Position = function(Obj) return (Obj.Parent:IsA("ScreenGui") and UDim2.new(0.5, 0, 0.5, 0)) or Obj.Position end,
			Active = true
		}
	}

	Explorer.InitInsertObject = function()
		local context = Lib.ContextMenu.new()
		context.SearchEnabled = true
		context.MaxHeight = 400
		context:ApplyTheme({
			ContentColor = Settings.Theme.Main2,
			OutlineColor = Settings.Theme.Outline1,
			DividerColor = Settings.Theme.Outline1,
			TextColor = Settings.Theme.Text,
			HighlightColor = Settings.Theme.ButtonHover
		})

		local classes = {}
		for i,class in next,API.Classes do
			local tags = class.Tags
			if not tags.NotCreatable and not tags.Service then
				local rmdEntry = RMD.Classes[class.Name]
				classes[#classes+1] = {class,rmdEntry and rmdEntry.ClassCategory or "Uncategorized"}
			end
		end
		table.sort(classes,function(a,b)
			if a[2] ~= b[2] then
				return a[2] < b[2]
			else
				return a[1].Name < b[1].Name
			end
		end)

		local function defaultProps(obj)
			for class, props in pairs(Explorer.DefaultProps) do
				if obj:IsA(class) then
					for prop, value in pairs(props) do
						obj[prop] = (type(value) == "function" and value(obj)) or value
					end
				end
			end
		end

		local function onClick(className)
			local sList = selection.List
			local instNew = Instance.new
			for i = 1,#sList do
				local node = sList[i]
				local obj = node.Obj
				Explorer.MakeNodeVisible(node, true)
				local success, obj = pcall(instNew, className, obj)
				if success and obj then defaultProps(obj) end
			end
		end

		local lastCategory = ""
		for i = 1,#classes do
			local class = classes[i][1]
			local rmdEntry = RMD.Classes[class.Name]
			local iconInd = rmdEntry and tonumber(rmdEntry.ExplorerImageIndex) or 0
			local category = classes[i][2]

			if lastCategory ~= category then
				context:AddDivider(category)
				lastCategory = category
			end
			
			local icon
			if iconData then
				icon = iconData.Icons[class.Name] or iconData.Icons.Placeholder
			else
				icon = iconInd
			end
			context:Add({Name = class.Name, IconMap = Explorer.ClassIcons, Icon = icon, OnClick = onClick})
		end

		Explorer.InsertObjectContext = context
	end
	
	--[[
		Headers, Setups, Predicate, ObjectDefs
	]]
	Explorer.SearchFilters = { -- TODO: Use data table (so we can disable some if funcs don't exist)
		Comparison = {
			["isa"] = function(argString)
				local lower = string.lower
				local find = string.find
				local classQuery = string.split(argString)[1]
				if not classQuery then return end
				classQuery = lower(classQuery)

				local className
				for class,_ in pairs(API.Classes) do
					local cName = lower(class)
					if cName == classQuery then
						className = class
						break
					elseif find(cName,classQuery,1,true) then
						className = class
					end
				end
				if not className then return end

				return {
					Headers = {"local isa = game.IsA"},
					Predicate = "isa(obj,'"..className.."')"
				}
			end,
			["remotes"] = function(argString)
				return {
					Headers = {"local isa = game.IsA"},
					Predicate = "isa(obj,'RemoteEvent') or isa(obj,'RemoteFunction') or isa(obj,'UnreliableRemoteEvent')"
				}
			end,
			["bindables"] = function(argString)
				return {
					Headers = {"local isa = game.IsA"},
					Predicate = "isa(obj,'BindableEvent') or isa(obj,'BindableFunction')"
				}
			end,
			["rad"] = function(argString)
				local num = tonumber(argString)
				if not num then return end

				if not service.Players.LocalPlayer.Character or not service.Players.LocalPlayer.Character:FindFirstChild("HumanoidRootPart") or not service.Players.LocalPlayer.Character.HumanoidRootPart:IsA("BasePart") then return end

				return {
					Headers = {"local isa = game.IsA", "local hrp = service.Players.LocalPlayer.Character.HumanoidRootPart"},
					Setups = {"local hrpPos = hrp.Position"},
					ObjectDefs = {"local isBasePart = isa(obj,'BasePart')"},
					Predicate = "(isBasePart and (obj.Position-hrpPos).Magnitude <= "..num..")"
				}
			end,
		},
		Specific = {
			["players"] = function()
				return function() return service.Players:GetPlayers() end
			end,
			["loadedmodules"] = function()
				return env.getloadedmodules
			end,
		},
		Default = function(argString,caseSensitive)
			local cleanString = argString:gsub("\"","\\\""):gsub("\n","\\n")
			if caseSensitive then
				return {
					Headers = {"local find = string.find"},
					ObjectDefs = {"local objName = tostring(obj)"},
					Predicate = "find(objName,\"" .. cleanString .. "\",1,true)"
				}
			else
				return {
					Headers = {"local lower = string.lower","local find = string.find","local tostring = tostring"},
					ObjectDefs = {"local lowerName = lower(tostring(obj))"},
					Predicate = "find(lowerName,\"" .. cleanString:lower() .. "\",1,true)"
				}
			end
		end,
		SpecificDefault = function(n)
			return {
				Headers = {},
				ObjectDefs = {"local isSpec"..n.." = specResults["..n.."][node]"},
				Predicate = "isSpec"..n
			}
		end,
	}

	Explorer.BuildSearchFunc = function(query)
		local specFilterList,specMap = {},{}
		local finalPredicate = ""
		local rep = string.rep
		local formatQuery = query:gsub("\\.","  "):gsub('".-"',function(str) return rep(" ",#str) end)
		local headers = {}
		local objectDefs = {}
		local setups = {}
		local find = string.find
		local sub = string.sub
		local lower = string.lower
		local match = string.match
		local ops = {
			["("] = "(",
			[")"] = ")",
			["||"] = " or ",
			["&&"] = " and "
		}
		local filterCount = 0
		local compFilters = Explorer.SearchFilters.Comparison
		local specFilters = Explorer.SearchFilters.Specific
		local init = 1
		local lastOp = nil

		local function processFilter(dat)
			if dat.Headers then
				local t = dat.Headers
				for i = 1,#t do
					headers[t[i]] = true
				end
			end

			if dat.ObjectDefs then
				local t = dat.ObjectDefs
				for i = 1,#t do
					objectDefs[t[i]] = true
				end
			end

			if dat.Setups then
				local t = dat.Setups
				for i = 1,#t do
					setups[t[i]] = true
				end
			end

			finalPredicate = finalPredicate..dat.Predicate
		end

		local found = {}
		local foundData = {}
		local find = string.find
		local sub = string.sub

		local function findAll(str,pattern)
			local count = #found+1
			local init = 1
			local sz = #pattern
			local x,y,extra = find(str,pattern,init,true)
			while x do
				found[count] = x
				foundData[x] = {sz,pattern}

				count = count+1
				init = y+1
				x,y,extra = find(str,pattern,init,true)
			end
		end
		local start = tick()
		findAll(formatQuery,'&&')
		findAll(formatQuery,"||")
		findAll(formatQuery,"(")
		findAll(formatQuery,")")
		table.sort(found)
		table.insert(found,#formatQuery+1)

		local function inQuotes(str)
			local len = #str
			if sub(str,1,1) == '"' and sub(str,len,len) == '"' then
				return sub(str,2,len-1)
			end
		end

		for i = 1,#found do
			local nextInd = found[i]
			local nextData = foundData[nextInd] or {1}
			local op = ops[nextData[2]]
			local term = sub(query,init,nextInd-1)
			term = match(term,"^%s*(.-)%s*$") or "" -- Trim

			if #term > 0 then
				if sub(term,1,1) == "!" then
					term = sub(term,2)
					finalPredicate = finalPredicate.."not "
				end

				local qTerm = inQuotes(term)
				if qTerm then
					processFilter(Explorer.SearchFilters.Default(qTerm,true))
				else
					local x,y = find(term,"%S+")
					if x then
						local first = sub(term,x,y)
						local specifier = sub(first,1,1) == "/" and lower(sub(first,2))
						local compFunc = specifier and compFilters[specifier]
						local specFunc = specifier and specFilters[specifier]

						if compFunc then
							local argStr = sub(term,y+2)
							local ret = compFunc(inQuotes(argStr) or argStr)
							if ret then
								processFilter(ret)
							else
								finalPredicate = finalPredicate.."false"
							end
						elseif specFunc then
							local argStr = sub(term,y+2)
							local ret = specFunc(inQuotes(argStr) or argStr)
							if ret then
								if not specMap[term] then
									specFilterList[#specFilterList + 1] = ret
									specMap[term] = #specFilterList
								end
								processFilter(Explorer.SearchFilters.SpecificDefault(specMap[term]))
							else
								finalPredicate = finalPredicate.."false"
							end
						else
							processFilter(Explorer.SearchFilters.Default(term))
						end
					end
				end				
			end

			if op then
				finalPredicate = finalPredicate..op
				if op == "(" and (#term > 0 or lastOp == ")") then -- Handle bracket glitch
					return
				else
					lastOp = op
				end
			end
			init = nextInd+nextData[1]
		end

		local finalSetups = ""
		local finalHeaders = ""
		local finalObjectDefs = ""

		for setup,_ in next,setups do finalSetups = finalSetups..setup.."\n" end
		for header,_ in next,headers do finalHeaders = finalHeaders..header.."\n" end
		for oDef,_ in next,objectDefs do finalObjectDefs = finalObjectDefs..oDef.."\n" end

		local template = [==[
local searchResults = searchResults
local nodes = nodes
local expandTable = Explorer.SearchExpanded
local specResults = specResults
local service = service

%s
local function search(root)	
%s
	
	local expandedpar = false
	for i = 1,#root do
		local node = root[i]
		local obj = node.Obj
		
%s
		
		if %s then
			expandTable[node] = 0
			searchResults[node] = true
			if not expandedpar then
				local parnode = node.Parent
				while parnode and (not searchResults[parnode] or expandTable[parnode] == 0) do
					expandTable[parnode] = true
					searchResults[parnode] = true
					parnode = parnode.Parent
				end
				expandedpar = true
			end
		end
		
		if #node > 0 then search(node) end
	end
end
return search]==]

		local funcStr = template:format(finalHeaders,finalSetups,finalObjectDefs,finalPredicate)
		local s,func = pcall(loadstring,funcStr)
		if not s or not func then return nil,specFilterList end

		local env = setmetatable({["searchResults"] = searchResults, ["nodes"] = nodes, ["Explorer"] = Explorer, ["specResults"] = specResults,
			["service"] = service},{__index = getfenv()})
		setfenv(func,env)

		return func(),specFilterList
	end

	Explorer.DoSearch = function(query)
		table.clear(Explorer.SearchExpanded)
		table.clear(searchResults)
		expanded = (#query == 0 and Explorer.Expanded or Explorer.SearchExpanded)
		searchFunc = nil

		if #query > 0 then	
			local expandTable = Explorer.SearchExpanded
			local specFilters

			local lower = string.lower
			local find = string.find
			local tostring = tostring

			local lowerQuery = lower(query)

			local function defaultSearch(root)
				local expandedpar = false
				for i = 1,#root do
					local node = root[i]
					local obj = node.Obj

					if find(lower(tostring(obj)),lowerQuery,1,true) then
						expandTable[node] = 0
						searchResults[node] = true
						if not expandedpar then
							local parnode = node.Parent
							while parnode and (not searchResults[parnode] or expandTable[parnode] == 0) do
								expanded[parnode] = true
								searchResults[parnode] = true
								parnode = parnode.Parent
							end
							expandedpar = true
						end
					end

					if #node > 0 then defaultSearch(node) end
				end
			end

			if Main.Elevated then
				local start = tick()
				searchFunc,specFilters = Explorer.BuildSearchFunc(query)
				--print("BUILD SEARCH",tick()-start)
			else
				searchFunc = defaultSearch
			end

			if specFilters then
				table.clear(specResults)
				for i = 1,#specFilters do -- Specific search filers that returns list of matches
					local resMap = {}
					specResults[i] = resMap
					local objs = specFilters[i]()
					for c = 1,#objs do
						local node = nodes[objs[c]]
						if node then
							resMap[node] = true
						end
					end
				end
			end

			if searchFunc then
				local start = tick()
				searchFunc(nodes[game])
				searchFunc(nilNode)
				--warn(tick()-start)
			end
		end

		Explorer.ForceUpdate()
	end

	Explorer.ClearSearch = function()
		Explorer.GuiElems.SearchBar.Text = ""
		expanded = Explorer.Expanded
		searchFunc = nil
	end

	Explorer.InitSearch = function()
		local searchBox = Explorer.GuiElems.ToolBar.SearchFrame.SearchBox
		Explorer.GuiElems.SearchBar = searchBox

		Lib.ViewportTextBox.convert(searchBox)

		searchBox.FocusLost:Connect(function()
			Explorer.DoSearch(searchBox.Text)
		end)
	end

	Explorer.InitEntryTemplate = function()
		entryTemplate = create({
			{1,"TextButton",{AutoButtonColor=false,BackgroundColor3=Color3.new(0,0,0),BackgroundTransparency=1,BorderColor3=Color3.new(0,0,0),Font=3,Name="Entry",Position=UDim2.new(0,1,0,1),Size=UDim2.new(0,250,0,20),Text="",TextSize=14,}},
			{2,"Frame",{BackgroundColor3=Color3.new(0.04313725605607,0.35294118523598,0.68627452850342),BackgroundTransparency=1,BorderColor3=Color3.new(0.33725491166115,0.49019610881805,0.73725491762161),BorderSizePixel=0,Name="Indent",Parent={1},Position=UDim2.new(0,20,0,0),Size=UDim2.new(1,-20,1,0),}},
			{3,"TextLabel",{BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=1,Font=3,Name="EntryName",Parent={2},Position=UDim2.new(0,26,0,0),Size=UDim2.new(1,-26,1,0),Text="Workspace",TextColor3=Color3.new(0.86274516582489,0.86274516582489,0.86274516582489),TextSize=14,TextXAlignment=0,}},
			{4,"TextButton",{BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=1,ClipsDescendants=true,Font=3,Name="Expand",Parent={2},Position=UDim2.new(0,-20,0,0),Size=UDim2.new(0,20,0,20),Text="",TextSize=14,}},
			{5,"ImageLabel",{BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=1,Image="rbxassetid://5642383285",ImageRectOffset=Vector2.new(144,16),ImageRectSize=Vector2.new(16,16),Name="Icon",Parent={4},Position=UDim2.new(0,2,0,2),ScaleType=4,Size=UDim2.new(0,16,0,16),}},
			{6,"ImageLabel",{BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=1,ImageRectOffset=Vector2.new(304,0),ImageRectSize=Vector2.new(16,16),Name="Icon",Parent={2},Position=UDim2.new(0,4,0,2),ScaleType=4,Size=UDim2.new(0,16,0,16),}},
		})

		local sys = Lib.ClickSystem.new()
		sys.AllowedButtons = {1,2}
		sys.OnDown:Connect(function(item,combo,button)
			local ind = table.find(listEntries,item)
			if not ind then return end
			local node = tree[ind + Explorer.Index]
			if not node then return end

			local entry = listEntries[ind]

			if button == 1 then
				if combo == 2 then
					if node.Obj:IsA("LuaSourceContainer") then
						ScriptViewer.ViewScript(node.Obj)
					elseif #node > 0 and expanded[node] ~= 0 then
						expanded[node] = not expanded[node]
						Explorer.Update()
					end
				end

				if Properties.SelectObject(node.Obj) then
					sys.IsRenaming = false
					return
				end

				sys.IsRenaming = selection.Map[node]

				if Lib.IsShiftDown() then
					if not selection.Piviot then return end

					local fromIndex = table.find(tree,selection.Piviot)
					local toIndex = table.find(tree,node)
					if not fromIndex or not toIndex then return end
					fromIndex,toIndex = math.min(fromIndex,toIndex),math.max(fromIndex,toIndex)

					local sList = selection.List
					for i = #sList,1,-1 do
						local elem = sList[i]
						if selection.ShiftSet[elem] then
							selection.Map[elem] = nil
							table.remove(sList,i)
						end
					end
					selection.ShiftSet = {}
					for i = fromIndex,toIndex do
						local elem = tree[i]
						if not selection.Map[elem] then
							selection.ShiftSet[elem] = true
							selection.Map[elem] = true
							sList[#sList+1] = elem
						end
					end
					selection.Changed:Fire()
				elseif Lib.IsCtrlDown() then
					selection.ShiftSet = {}
					if selection.Map[node] then selection:Remove(node) else selection:Add(node) end
					selection.Piviot = node
					sys.IsRenaming = false
				elseif not selection.Map[node] then
					selection.ShiftSet = {}
					selection:Set(node)
					selection.Piviot = node
				end
			elseif button == 2 then
				if Properties.SelectObject(node.Obj) then
					return
				end

				if not Lib.IsCtrlDown() and not selection.Map[node] then
					selection.ShiftSet = {}
					selection:Set(node)
					selection.Piviot = node
					Explorer.Refresh()
				end
			end

			Explorer.Refresh()
		end)

		sys.OnRelease:Connect(function(item,combo,button,position)
			local ind = table.find(listEntries,item)
			if not ind then return end
			local node = tree[ind + Explorer.Index]
			if not node then return end

			if button == 1 then
				if selection.Map[node] and not Lib.IsShiftDown() and not Lib.IsCtrlDown() then
					selection.ShiftSet = {}
					selection:Set(node)
					selection.Piviot = node
					Explorer.Refresh()
				end

				local id = sys.ClickId
				Lib.FastWait(sys.ComboTime)
				if combo == 1 and id == sys.ClickId and sys.IsRenaming and selection.Map[node] then
					Explorer.SetRenamingNode(node)
				end
			elseif button == 2 then
				Explorer.ShowRightClick(position)
			end
		end)
		Explorer.ClickSystem = sys
	end

	Explorer.InitDelCleaner = function()
		coroutine.wrap(function()
			local fw = Lib.FastWait
			while true do
				local processed = false
				local c = 0
				for _,node in next,nodes do
					if node.HasDel then
						local delInd
						for i = 1,#node do
							if node[i].Del then
								delInd = i
								break
							end
						end
						if delInd then
							for i = delInd+1,#node do
								local cn = node[i]
								if not cn.Del then
									node[delInd] = cn
									delInd = delInd+1
								end
							end
							for i = delInd,#node do
								node[i] = nil
							end
						end
						node.HasDel = false
						processed = true
						fw()
					end
					c = c + 1
					if c > 10000 then
						c = 0
						fw()
					end
				end
				if processed and not refreshDebounce then Explorer.PerformRefresh() end
				fw(0.5)
			end
		end)()
	end

	Explorer.UpdateSelectionVisuals = function()
		local holder = Explorer.SelectionVisualsHolder
		local isa = game.IsA
		local clone = game.Clone
		if not holder then
			holder = Instance.new("ScreenGui")
			holder.Name = "ExplorerSelections"
			holder.DisplayOrder = Main.DisplayOrders.Core
			Lib.ShowGui(holder)
			Explorer.SelectionVisualsHolder = holder
			Explorer.SelectionVisualCons = {}

			local guiTemplate = create({
				{1,"Frame",{BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=1,Size=UDim2.new(0,100,0,100),}},
				{2,"Frame",{BackgroundColor3=Color3.new(0.04313725605607,0.35294118523598,0.68627452850342),BorderSizePixel=0,Parent={1},Position=UDim2.new(0,-1,0,-1),Size=UDim2.new(1,2,0,1),}},
				{3,"Frame",{BackgroundColor3=Color3.new(0.04313725605607,0.35294118523598,0.68627452850342),BorderSizePixel=0,Parent={1},Position=UDim2.new(0,-1,1,0),Size=UDim2.new(1,2,0,1),}},
				{4,"Frame",{BackgroundColor3=Color3.new(0.04313725605607,0.35294118523598,0.68627452850342),BorderSizePixel=0,Parent={1},Position=UDim2.new(0,-1,0,0),Size=UDim2.new(0,1,1,0),}},
				{5,"Frame",{BackgroundColor3=Color3.new(0.04313725605607,0.35294118523598,0.68627452850342),BorderSizePixel=0,Parent={1},Position=UDim2.new(1,0,0,0),Size=UDim2.new(0,1,1,0),}},
			})
			Explorer.SelectionVisualGui = guiTemplate

			local boxTemplate = Instance.new("SelectionBox")
			boxTemplate.LineThickness = 0.03
			boxTemplate.Color3 = Color3.fromRGB(0, 170, 255)
			Explorer.SelectionVisualBox = boxTemplate
		end
		holder:ClearAllChildren()

		-- Updates theme
		for i,v in pairs(Explorer.SelectionVisualGui:GetChildren()) do
			v.BackgroundColor3 = Color3.fromRGB(0, 170, 255)
		end

		local attachCons = Explorer.SelectionVisualCons
		for i = 1,#attachCons do
			attachCons[i].Destroy()
		end
		table.clear(attachCons)

		local partEnabled = Settings.Explorer.PartSelectionBox
		local guiEnabled = Settings.Explorer.GuiSelectionBox
		if not partEnabled and not guiEnabled then return end

		local svg = Explorer.SelectionVisualGui
		local svb = Explorer.SelectionVisualBox
		local attachTo = Lib.AttachTo
		local sList = selection.List
		local count = 1
		local boxCount = 0
		local workspaceNode = nodes[workspace]
		for i = 1,#sList do
			if boxCount > 1000 then break end
			local node = sList[i]
			local obj = node.Obj

			if node ~= workspaceNode then
				if isa(obj,"GuiObject") and guiEnabled then
					local newVisual = clone(svg)
					attachCons[count] = attachTo(newVisual,{Target = obj, Resize = true})
					count = count + 1
					newVisual.Parent = holder
					boxCount = boxCount + 1
				elseif isa(obj,"PVInstance") and partEnabled then
					local newBox = clone(svb)
					newBox.Adornee = obj
					newBox.Parent = holder
					boxCount = boxCount + 1
				end
			end
		end
	end

	Explorer.Init = function()
		Explorer.LegacyClassIcons = Lib.IconMap.newLinear("rbxasset://textures/ClassImages.PNG", 16,16)
		if Settings.ClassIcon ~= nil and Settings.ClassIcon ~= "Old" then
			iconData = Lib.IconMap.getIconDataFromName(Settings.ClassIcon)
			
			Explorer.ClassIcons = Lib.IconMap.new("rbxassetid://"..tostring(iconData.MapId), iconData.IconSize * iconData.Witdh, iconData.IconSize * iconData.Height,iconData.IconSize,iconData.IconSize)
			-- move every value dict 1 behind because SetDict starts at 0 not 1 lol
			local fixed = {}
			for i,v in pairs(iconData.Icons) do
				fixed[i] = v - 1
			end
			
			iconData.Icons = fixed
			Explorer.ClassIcons:SetDict(fixed)
		else
			Explorer.ClassIcons = Lib.IconMap.newLinear("rbxasset://textures/ClassImages.PNG", 16,16)
		end
		
		Explorer.MiscIcons = Main.MiscIcons

		clipboard = {}

		selection = Lib.Set.new()
		selection.ShiftSet = {}
		selection.Changed:Connect(Properties.ShowExplorerProps)
		Explorer.Selection = selection

		Explorer.InitRightClick()
		Explorer.InitInsertObject()
		Explorer.SetSortingEnabled(Settings.Explorer.Sorting)
		Explorer.Expanded = setmetatable({},{__mode = "k"})
		Explorer.SearchExpanded = setmetatable({},{__mode = "k"})
		expanded = Explorer.Expanded

		nilNode.Obj.Name = "Nil Instances"
		nilNode.Locked = true

		local explorerItems = create({
			{1,"Folder",{Name="ExplorerItems",}},
			{2,"Frame",{BackgroundColor3=Color3.new(0.20392157137394,0.20392157137394,0.20392157137394),BorderSizePixel=0,Name="ToolBar",Parent={1},Size=UDim2.new(1,0,0,22),}},
			{3,"Frame",{BackgroundColor3=Color3.new(0.14901961386204,0.14901961386204,0.14901961386204),BorderColor3=Color3.new(0.1176470592618,0.1176470592618,0.1176470592618),BorderSizePixel=0,Name="SearchFrame",Parent={2},Position=UDim2.new(0,3,0,1),Size=UDim2.new(1,-6,0,18),}},
			{4,"TextBox",{BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=1,ClearTextOnFocus=false,Font=3,Name="SearchBox",Parent={3},PlaceholderColor3=Color3.new(0.39215689897537,0.39215689897537,0.39215689897537),PlaceholderText="Search workspace",Position=UDim2.new(0,4,0,0),Size=UDim2.new(1,-24,0,18),Text="",TextColor3=Color3.new(1,1,1),TextSize=14,TextXAlignment=0,}},
			{5,"UICorner",{CornerRadius=UDim.new(0,2),Parent={3},}},
			{6,"UIStroke",{Thickness=1.4,Parent={3},Color=Color3.fromRGB(42,42,42)}},
			{7,"TextButton",{AutoButtonColor=false,BackgroundColor3=Color3.new(0.12549020349979,0.12549020349979,0.12549020349979),BackgroundTransparency=1,BorderSizePixel=0,Font=3,Name="Reset",Parent={3},Position=UDim2.new(1,-17,0,1),Size=UDim2.new(0,16,0,16),Text="",TextColor3=Color3.new(1,1,1),TextSize=14,}},
			{8,"ImageLabel",{BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=1,Image="rbxassetid://5034718129",ImageColor3=Color3.new(0.39215686917305,0.39215686917305,0.39215686917305),Parent={7},Size=UDim2.new(0,16,0,16),}},
			{9,"TextButton",{AutoButtonColor=false,BackgroundColor3=Color3.new(0.12549020349979,0.12549020349979,0.12549020349979),BackgroundTransparency=1,BorderSizePixel=0,Font=3,Name="Refresh",Parent={2},Position=UDim2.new(1,-20,0,1),Size=UDim2.new(0,18,0,18),Text="",TextColor3=Color3.new(1,1,1),TextSize=14,Visible=false,}},
			{10,"ImageLabel",{BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=1,Image="rbxassetid://5642310344",Parent={9},Position=UDim2.new(0,3,0,3),Size=UDim2.new(0,12,0,12),}},
			{11,"Frame",{BackgroundColor3=Color3.new(0.15686275064945,0.15686275064945,0.15686275064945),BorderSizePixel=0,Name="ScrollCorner",Parent={1},Position=UDim2.new(1,-16,1,-16),Size=UDim2.new(0,16,0,16),Visible=false,}},
			{12,"Frame",{BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=1,ClipsDescendants=true,Name="List",Parent={1},Position=UDim2.new(0,0,0,23),Size=UDim2.new(1,0,1,-23),}}
		})

		toolBar = explorerItems.ToolBar
		treeFrame = explorerItems.List

		Explorer.GuiElems.ToolBar = toolBar
		Explorer.GuiElems.TreeFrame = treeFrame

		scrollV = Lib.ScrollBar.new()		
		scrollV.WheelIncrement = 3
		scrollV.Gui.Position = UDim2.new(1,-16,0,23)
		scrollV:SetScrollFrame(treeFrame)
		scrollV.Scrolled:Connect(function()
			Explorer.Index = scrollV.Index
			Explorer.Refresh()
		end)

		scrollH = Lib.ScrollBar.new(true)
		scrollH.Increment = 5
		scrollH.WheelIncrement = Explorer.EntryIndent
		scrollH.Gui.Position = UDim2.new(0,0,1,-16)
		scrollH.Scrolled:Connect(function()
			Explorer.Refresh()
		end)

		local window = Lib.Window.new()
		Explorer.Window = window
		window:SetTitle("Explorer")
		window.GuiElems.Line.Position = UDim2.new(0,0,0,22)

		Explorer.InitEntryTemplate()
		toolBar.Parent = window.GuiElems.Content
		treeFrame.Parent = window.GuiElems.Content
		explorerItems.ScrollCorner.Parent = window.GuiElems.Content
		scrollV.Gui.Parent = window.GuiElems.Content
		scrollH.Gui.Parent = window.GuiElems.Content

		-- Init stuff that requires the window
		Explorer.InitRenameBox()
		Explorer.InitSearch()
		Explorer.InitDelCleaner()
		selection.Changed:Connect(Explorer.UpdateSelectionVisuals)

		-- Window events
		window.GuiElems.Main:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
			if Explorer.Active then
				Explorer.UpdateView()
				Explorer.Refresh()
			end
		end)
		window.OnActivate:Connect(function()
			Explorer.Active = true
			Explorer.UpdateView()
			Explorer.Update()
			Explorer.Refresh()
		end)
		window.OnRestore:Connect(function()
			Explorer.Active = true
			Explorer.UpdateView()
			Explorer.Update()
			Explorer.Refresh()
		end)
		window.OnDeactivate:Connect(function() Explorer.Active = false end)
		window.OnMinimize:Connect(function() Explorer.Active = false end)

		-- Settings
		autoUpdateSearch = Settings.Explorer.AutoUpdateSearch

		-- Fill in nodes
		nodes[game] = {Obj = game}
		expanded[nodes[game]] = true

		-- Nil Instances
		if env.getnilinstances then
			nodes[nilNode.Obj] = nilNode
		end

		Explorer.SetupConnections()

		local insts = getDescendants(game)
		if Main.Elevated then
			for i = 1,#insts do
				local obj = insts[i]
				local par = nodes[ffa(obj,"Instance")]
				if not par then continue end
				local newNode = {
					Obj = obj,
					Parent = par,
				}
				nodes[obj] = newNode
				par[#par+1] = newNode
			end
		else
			for i = 1,#insts do
				local obj = insts[i]
				local s,parObj = pcall(ffa,obj,"Instance")
				local par = nodes[parObj]
				if not par then continue end
				local newNode = {
					Obj = obj,
					Parent = par,
				}
				nodes[obj] = newNode
				par[#par+1] = newNode
			end
		end
	end

	Explorer.Uninit = function()
		Explorer.Active = false
		for _, connection in pairs({descendantAddedCon, descendantRemovingCon, itemChangedCon}) do
			if connection then pcall(connection.Disconnect, connection) end
		end
		descendantAddedCon, descendantRemovingCon, itemChangedCon = nil, nil, nil

		for _, connections in pairs(nilCons) do
			if type(connections) == "table" then
				for _, connection in pairs(connections) do
					if connection then pcall(connection.Disconnect, connection) end
				end
			end
		end
		nilCons = {}

		if Explorer.SelectionVisualCons then
			for _, attachment in pairs(Explorer.SelectionVisualCons) do
				if attachment and attachment.Destroy then pcall(attachment.Destroy) end
			end
			Explorer.SelectionVisualCons = {}
		end
	end

	return Explorer
end

return {InitDeps = initDeps, InitAfterMain = initAfterMain, Main = main}

end,
["Lib"] = function()
--[[
	Lib Module
	
	Container for functions and classes
]]

-- Common Locals
local Main,Lib,Apps,Settings -- Main Containers
local Explorer, Properties, ScriptViewer, Notebook -- Major Apps
local API,RMD,env,service,plr,create,createSimple -- Main Locals

local function initDeps(data)
	Main = data.Main
	Lib = data.Lib
	Apps = data.Apps
	Settings = data.Settings

	API = data.API
	RMD = data.RMD
	env = data.env
	service = data.service
	plr = data.plr
	create = data.create
	createSimple = data.createSimple
end

local function initAfterMain()
	Explorer = Apps.Explorer
	Properties = Apps.Properties
	ScriptViewer = Apps.ScriptViewer
	Notebook = Apps.Notebook
end

local function main()
	local Lib = {}

	local renderStepped = service.RunService.RenderStepped
	local signalWait = renderStepped.wait
	local PH = newproxy() -- Placeholder, must be replaced in constructor
	local SIGNAL = newproxy()

	-- Usually for classes that work with a Roblox Object
	local function initObj(props,mt)
		local type = type
		local function copy(t)
			local res = {}
			for i,v in pairs(t) do
				if v == SIGNAL then
					res[i] = Lib.Signal.new()
				elseif type(v) == "table" then
					res[i] = copy(v)
				else
					res[i] = v
				end
			end		
			return res
		end

		local newObj = copy(props)
		return setmetatable(newObj,mt)
	end

	local function getGuiMT(props,funcs)
		return {__index = function(self,ind) if not props[ind] then return funcs[ind] or self.Gui[ind] end end,
		__newindex = function(self,ind,val) if not props[ind] then self.Gui[ind] = val else rawset(self,ind,val) end end}
	end

	-- Functions

	Lib.FormatLuaString = (function()
		local string = string
		local gsub = string.gsub
		local format = string.format
		local char = string.char
		local cleanTable = {['"'] = '\\"', ['\\'] = '\\\\'}
		for i = 0,31 do
			cleanTable[char(i)] = "\\"..format("%03d",i)
		end
		for i = 127,255 do
			cleanTable[char(i)] = "\\"..format("%03d",i)
		end

		return function(str)
			return gsub(str,"[\"\\\0-\31\127-\255]",cleanTable)
		end
	end)()

	Lib.CheckMouseInGui = function(gui)
		if gui == nil then return false end
		local mouse = Main.Mouse
		local guiPosition = gui.AbsolutePosition
		local guiSize = gui.AbsoluteSize	

		return mouse.X >= guiPosition.X and mouse.X < guiPosition.X + guiSize.X and mouse.Y >= guiPosition.Y and mouse.Y < guiPosition.Y + guiSize.Y
	end

	Lib.IsShiftDown = function()
		return service.UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) or service.UserInputService:IsKeyDown(Enum.KeyCode.RightShift)
	end

	Lib.IsCtrlDown = function()
		return service.UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) or service.UserInputService:IsKeyDown(Enum.KeyCode.RightControl)
	end

	Lib.CreateArrow = function(size,num,dir)
		local max = num
		local arrowFrame = createSimple("Frame",{
			BackgroundTransparency = 1,
			Name = "Arrow",
			Size = UDim2.new(0,size,0,size)
		})
		if dir == "up" then
			for i = 1,num do
				local newLine = createSimple("Frame",{
					BackgroundColor3 = Color3.new(220/255,220/255,220/255),
					BorderSizePixel = 0,
					Position = UDim2.new(0,math.floor(size/2)-(i-1),0,math.floor(size/2)+i-math.floor(max/2)-1),
					Size = UDim2.new(0,i+(i-1),0,1),
					Parent = arrowFrame
				})
			end
			return arrowFrame
		elseif dir == "down" then
			for i = 1,num do
				local newLine = createSimple("Frame",{
					BackgroundColor3 = Color3.new(220/255,220/255,220/255),
					BorderSizePixel = 0,
					Position = UDim2.new(0,math.floor(size/2)-(i-1),0,math.floor(size/2)-i+math.floor(max/2)+1),
					Size = UDim2.new(0,i+(i-1),0,1),
					Parent = arrowFrame
				})
			end
			return arrowFrame
		elseif dir == "left" then
			for i = 1,num do
				local newLine = createSimple("Frame",{
					BackgroundColor3 = Color3.new(220/255,220/255,220/255),
					BorderSizePixel = 0,
					Position = UDim2.new(0,math.floor(size/2)+i-math.floor(max/2)-1,0,math.floor(size/2)-(i-1)),
					Size = UDim2.new(0,1,0,i+(i-1)),
					Parent = arrowFrame
				})
			end
			return arrowFrame
		elseif dir == "right" then
			for i = 1,num do
				local newLine = createSimple("Frame",{
					BackgroundColor3 = Color3.new(220/255,220/255,220/255),
					BorderSizePixel = 0,
					Position = UDim2.new(0,math.floor(size/2)-i+math.floor(max/2)+1,0,math.floor(size/2)-(i-1)),
					Size = UDim2.new(0,1,0,i+(i-1)),
					Parent = arrowFrame
				})
			end
			return arrowFrame
		end
		error("r u ok")
	end

	Lib.ParseXML = (function()
		local func = function()
			-- Only exists to parse RMD
			-- from https://github.com/jonathanpoelen/xmlparser

			local string, print, pairs = string, print, pairs

			-- http://lua-users.org/wiki/StringTrim
			local trim = function(s)
				local from = s:match"^%s*()"
				return from > #s and "" or s:match(".*%S", from)
			end

			local gtchar = string.byte('>', 1)
			local slashchar = string.byte('/', 1)
			local D = string.byte('D', 1)
			local E = string.byte('E', 1)

			function parse(s, evalEntities)
				-- remove comments
				s = s:gsub('<!%-%-(.-)%-%->', '')

				local entities, tentities = {}

				if evalEntities then
					local pos = s:find('<[_%w]')
					if pos then
						s:sub(1, pos):gsub('<!ENTITY%s+([_%w]+)%s+(.)(.-)%2', function(name, q, entity)
							entities[#entities+1] = {name=name, value=entity}
						end)
						tentities = createEntityTable(entities)
						s = replaceEntities(s:sub(pos), tentities)
					end
				end

				local t, l = {}, {}

				local addtext = function(txt)
					txt = txt:match'^%s*(.*%S)' or ''
					if #txt ~= 0 then
						t[#t+1] = {text=txt}
					end		
				end

				s:gsub('<([?!/]?)([-:_%w]+)%s*(/?>?)([^<]*)', function(type, name, closed, txt)
					-- open
					if #type == 0 then
						local a = {}
						if #closed == 0 then
							local len = 0
							for all,aname,_,value,starttxt in string.gmatch(txt, "(.-([-_%w]+)%s*=%s*(.)(.-)%3%s*(/?>?))") do
								len = len + #all
								a[aname] = value
								if #starttxt ~= 0 then
									txt = txt:sub(len+1)
									closed = starttxt
									break
								end
							end
						end
						t[#t+1] = {tag=name, attrs=a, children={}}

						if closed:byte(1) ~= slashchar then
							l[#l+1] = t
							t = t[#t].children
						end

						addtext(txt)
						-- close
					elseif '/' == type then
						t = l[#l]
						l[#l] = nil

						addtext(txt)
						-- ENTITY
					elseif '!' == type then
						if E == name:byte(1) then
							txt:gsub('([_%w]+)%s+(.)(.-)%2', function(name, q, entity)
								entities[#entities+1] = {name=name, value=entity}
							end, 1)
						end
						-- elseif '?' == type then
						--	 print('?	' .. name .. ' // ' .. attrs .. '$$')
						-- elseif '-' == type then
						--	 print('comment	' .. name .. ' // ' .. attrs .. '$$')
						-- else
						--	 print('o	' .. #p .. ' // ' .. name .. ' // ' .. attrs .. '$$')
					end
				end)

				return {children=t, entities=entities, tentities=tentities}
			end

			function parseText(txt)
				return parse(txt)
			end

			function defaultEntityTable()
				return { quot='"', apos='\'', lt='<', gt='>', amp='&', tab='\t', nbsp=' ', }
			end

			function replaceEntities(s, entities)
				return s:gsub('&([^;]+);', entities)
			end

			function createEntityTable(docEntities, resultEntities)
				entities = resultEntities or defaultEntityTable()
				for _,e in pairs(docEntities) do
					e.value = replaceEntities(e.value, entities)
					entities[e.name] = e.value
				end
				return entities
			end

			return parseText
		end
		local newEnv = setmetatable({},{__index = getfenv()})
		setfenv(func,newEnv)
		return func()
	end)()

	Lib.FastWait = function(s)
		if not s then return signalWait(renderStepped) end
		local start = tick()
		while tick() - start < s do signalWait(renderStepped) end
	end

	Lib.ButtonAnim = function(button,data)
		local holding = false
		local disabled = false
		local mode = data and data.Mode or 1
		local control = {}

		if mode == 2 then
			local lerpTo = data.LerpTo or Color3.new(0,0,0)
			local delta = data.LerpDelta or 0.2
			control.StartColor = data.StartColor or button.BackgroundColor3
			control.PressColor = data.PressColor or control.StartColor:lerp(lerpTo,delta)
			control.HoverColor = data.HoverColor or control.StartColor:lerp(control.PressColor,0.6)
			control.OutlineColor = data.OutlineColor
		end

		button.InputBegan:Connect(function(input)
			if disabled then return end

			if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
				if not holding then
					if mode == 1 then
						button.BackgroundTransparency = 0.4
					elseif mode == 2 then
						button.BackgroundColor3 = control.HoverColor
					end
				end
			elseif input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				holding = true
				if mode == 1 then
					button.BackgroundTransparency = 0
				elseif mode == 2 then
					button.BackgroundColor3 = control.PressColor
					if control.OutlineColor then button.BorderColor3 = control.PressColor end
				end
			end
		end)

		button.InputEnded:Connect(function(input)
			if disabled then return end

			if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
				if not holding then
					if mode == 1 then
						button.BackgroundTransparency = 1
					elseif mode == 2 then
						button.BackgroundColor3 = control.StartColor
					end
				end
			elseif input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				holding = false
				if mode == 1 then
					button.BackgroundTransparency = Lib.CheckMouseInGui(button) and 0.4 or 1
				elseif mode == 2 then
					button.BackgroundColor3 = Lib.CheckMouseInGui(button) and control.HoverColor or control.StartColor
					if control.OutlineColor then button.BorderColor3 = control.OutlineColor end
				end
			end
		end)

		control.Disable = function()
			disabled = true
			holding = false

			if mode == 1 then
				button.BackgroundTransparency = 1
			elseif mode == 2 then
				button.BackgroundColor3 = control.StartColor
			end
		end

		control.Enable = function()
			disabled = false
		end

		return control
	end

	Lib.FindAndRemove = function(t,item)
		local pos = table.find(t,item)
		if pos then table.remove(t,pos) end
	end

	Lib.AttachTo = function(obj,data)
		local target,posOffX,posOffY,sizeOffX,sizeOffY,resize,con
		local disabled = false

		local function update()
			if not obj or not target then return end

			local targetPos = target.AbsolutePosition
			local targetSize = target.AbsoluteSize
			obj.Position = UDim2.new(0,targetPos.X + posOffX,0,targetPos.Y + posOffY)
			if resize then obj.Size = UDim2.new(0,targetSize.X + sizeOffX,0,targetSize.Y + sizeOffY) end
		end

		local function setup(o,data)
			obj = o
			data = data or {}
			target = data.Target
			posOffX = data.PosOffX or 0
			posOffY = data.PosOffY or 0
			sizeOffX = data.SizeOffX or 0
			sizeOffY = data.SizeOffY or 0
			resize = data.Resize or false

			if con then con:Disconnect() con = nil end
			if target then
				con = target.Changed:Connect(function(prop)
					if not disabled and (prop == "AbsolutePosition" or prop == "AbsoluteSize") then
						update()
					end
				end)
			end

			update()
		end
		setup(obj,data)

		return {
			SetData = function(obj,data)
				setup(obj,data)
			end,
			Enable = function()
				disabled = false
				update()
			end,
			Disable = function()
				disabled = true
			end,
			Destroy = function()
				con:Disconnect()
				con = nil
			end,
		}
	end

	Lib.ProtectedGuis = {}

	Lib.ShowGui = Main.SecureGui

	Lib.ColorToBytes = function(col)
		local round = math.round
		return string.format("%d, %d, %d",round(col.r*255),round(col.g*255),round(col.b*255))
	end

	Lib.ReadFile = function(filename)
		if not env.readfile then return end

		local s,contents = pcall(env.readfile,filename)
		if s and contents then return contents end
	end

	Lib.DeferFunc = function(f,...)
		signalWait(renderStepped)
		return f(...)
	end

	Lib.LoadCustomAsset = function(filepath)
		if not env.getcustomasset or not env.isfile or not env.isfile(filepath) then return end

		return env.getcustomasset(filepath)
	end

	Lib.FetchCustomAsset = function(url,filepath)
		if not env.writefile then return end

		local s,data = pcall(oldgame.HttpGet,game,url)
		if not s then return end

		env.writefile(filepath,data)
		return Lib.LoadCustomAsset(filepath)
	end
	
	local currentfilename, currentextension, currentclickhandler, savePromptBusy
	currentclickhandler = function() end
	Lib.SaveAsPrompt = function(filename, codeToSave, ext)
		if savePromptBusy then
			env.notify("Dex++ Save As", "Another save is already in progress", 6)
			return false
		end

		local win = ScriptViewer.SaveAsWindow
		if not win then
			win = Lib.Window.new()
			win.Alignable = false
			win.Resizable = false
			win:SetTitle("Save As")
			win:SetSize(560,185)

			local saveButton = Lib.Button.new()
			local nameLabel = Lib.Label.new()
			nameLabel.Text = "Name"
			nameLabel.Position = UDim2.new(0,10,0,10)
			nameLabel.Size = UDim2.new(0,50,0,20)
			win:Add(nameLabel)

			local nameBox = Lib.ViewportTextBox.new()
			nameBox.Position = UDim2.new(0,65,0,10)
			nameBox.Size = UDim2.new(1,-75,0,20)
			win:Add(nameBox,"NameBox")

			--nameBox.TextBox.Text = filename or ""

			nameBox.TextBox:GetPropertyChangedSignal("Text"):Connect(function()
				saveButton:SetDisabled(#nameBox:GetText() == 0)
			end)

			local folderLabel = Lib.Label.new()
			folderLabel.Text = "Folder"
			folderLabel.Position = UDim2.new(0,10,0,38)
			folderLabel.Size = UDim2.new(0,50,0,20)
			win:Add(folderLabel)

			local folderBox = Lib.ViewportTextBox.new()
			folderBox.Position = UDim2.new(0,65,0,38)
			folderBox.Size = UDim2.new(1,-75,0,20)
			win:Add(folderBox,"FolderBox")

			local errorLabel = Lib.Label.new()
			errorLabel.Text = ""
			errorLabel.Position = UDim2.new(0,10,0,66)
			errorLabel.Size = UDim2.new(1,-20,0,74)
			errorLabel.TextColor3 = Settings.Theme.Important
			errorLabel.Gui.TextWrapped = true
			errorLabel.Gui.TextXAlignment = Enum.TextXAlignment.Left
			errorLabel.Gui.TextYAlignment = Enum.TextYAlignment.Top
			win.ErrorLabel = errorLabel
			win:Add(errorLabel,"Error")

			local cancelButton = Lib.Button.new()
			cancelButton.AnchorPoint = Vector2.new(1,1)
			cancelButton.Text = "Cancel"
			cancelButton.Position = UDim2.new(1,-5,1,-5)
			cancelButton.Size = UDim2.new(0.5,-10,0,20)
			cancelButton.OnClick:Connect(function()
				if not savePromptBusy then win:Close() end
			end)
			win:Add(cancelButton)

			saveButton.Text = "Save"
			saveButton.AnchorPoint = Vector2.new(0,1)
			saveButton.Position = UDim2.new(0,5,1,-5)
			saveButton.Size = UDim2.new(0.5,-5,0,20)
			saveButton.OnClick:Connect(function()
				currentclickhandler()
			end)

			win:Add(saveButton,"SaveButton")

			ScriptViewer.SaveAsWindow = win
		end

		currentclickhandler = function()
			if savePromptBusy then return end

			filename = (win.Elements.NameBox.TextBox.Text ~= "" and win.Elements.NameBox.TextBox.Text) or filename
			currentextension = tostring(ext or filename:match("%.([^%.]+)$") or "txt"):gsub("^%.", "")
			filename = env.parsefile(filename:gsub("%.[^.]+$", "") .. "." .. currentextension)
			local folder = env.normalizepath(win.Elements.FolderBox:GetText())
			local fullPath = env.joinpath(folder, filename)
			if Settings.Save.AvoidOverwrite and env.isfile then
				local stem, extension = fullPath:match("^(.*)(%.[^./]+)$")
				stem, extension = stem or fullPath, extension or ""
				local candidate, index = fullPath, 1
				while true do
					local checked, exists = pcall(env.isfile, candidate)
					if not checked or not exists then break end
					candidate = stem .. "_" .. index .. extension
					index += 1
				end
				fullPath = candidate
			end
			Settings.Save.Folder = folder
			pcall(Main.SaveCurrentSettings)
			savePromptBusy = true
			win:SetTitle("Save As - Saving")
			win.Elements.Error.Text = "Saving..."
			win.Elements.SaveButton.Text = "Saving..."
			win.Elements.SaveButton:SetDisabled(true)

			local function finish(success, message)
				savePromptBusy = false
				pcall(function()
					win.Elements.SaveButton.Text = "Save"
					win.Elements.SaveButton:SetDisabled(win.Elements.NameBox:GetText() == 0)
					if success then
						win:Close()
					else
						win:SetTitle("Save As - Error")
						message = tostring(message or "Unknown error")
						win.Elements.Error.Text = "Error: " .. message:sub(1, 700)
					end
				end)
				if success then
					env.notify("Dex++ Save As", "Saved as " .. tostring(message or fullPath), 8)
				else
					warn("Dex++ Save As error: " .. tostring(message))
				end
			end

			if folder ~= "" and Settings.Save.CreateFolders then
				local folderOk, folderError = env.ensurefolder(folder)
				if not folderOk then
					finish(false, folderError)
					return
				end
			end

			if type(codeToSave) == "string" then
				if not env.writefile then
					finish(false, "Your executor does not support writefile")
					return
				end
				local success, message = pcall(env.writefile, fullPath, codeToSave)
				if success and Settings.Save.VerifyAfterWrite and env.isfile then
					local checked, exists = pcall(env.isfile, fullPath)
					if checked and not exists then
						success, message = false, "The executor did not create the expected file"
					end
				end
				finish(success, success and fullPath or message)
			elseif type(codeToSave) == "function" then
				task.spawn(function()
					local success, result, message = pcall(codeToSave, fullPath)
					if not success then
						finish(false, result)
					elseif result == false then
						finish(false, message or "The save callback reported a failure")
					else
						finish(true, message or fullPath)
					end
				end)
			else
				finish(false, "Unsupported Save As content type: " .. type(codeToSave))
			end
		end

		win:SetTitle("Save As")
		win.Elements.Error.Text = ""
		local normalized = env.normalizepath(filename or "")
		local suppliedFolder, suppliedName = normalized:match("^(.*)/([^/]+)$")
		win.Elements.NameBox:SetText(suppliedName or normalized)
		win.Elements.FolderBox:SetText(suppliedFolder or Settings.Save.Folder or "")
		
		win.Elements.SaveButton:SetDisabled(win.Elements.NameBox:GetText() == 0)
		
		win:Show()
		return true
	end
	
	-- Classes

	Lib.Signal = (function()
		local funcs = {}

		local disconnect = function(con)
			local pos = table.find(con.Signal.Connections,con)
			if pos then table.remove(con.Signal.Connections,pos) end
		end

		funcs.Connect = function(self,func)
			if type(func) ~= "function" then error("Attempt to connect a non-function") end		
			local con = {
				Signal = self,
				Func = func,
				Disconnect = disconnect
			}
			self.Connections[#self.Connections+1] = con
			return con
		end

		funcs.Fire = function(self,...)
			for i,v in next,self.Connections do
				xpcall(coroutine.wrap(v.Func),function(e) warn(e.."\n"..debug.traceback()) end,...)
			end
		end

		local mt = {
			__index = funcs,
			__tostring = function(self)
				return "Signal: " .. tostring(#self.Connections) .. " Connections"
			end
		}

		local function new()
			local obj = {}
			obj.Connections = {}

			return setmetatable(obj,mt)
		end

		return {new = new}
	end)()

	Lib.Set = (function()
		local funcs = {}

		funcs.Add = function(self,obj)
			if self.Map[obj] then return end

			local list = self.List
			list[#list+1] = obj
			self.Map[obj] = true
			self.Changed:Fire()
		end

		funcs.AddTable = function(self,t)
			local changed
			local list,map = self.List,self.Map
			for i = 1,#t do
				local elem = t[i]
				if not map[elem] then
					list[#list+1] = elem
					map[elem] = true
					changed = true
				end
			end
			if changed then self.Changed:Fire() end
		end

		funcs.Remove = function(self,obj)
			if not self.Map[obj] then return end

			local list = self.List
			local pos = table.find(list,obj)
			if pos then table.remove(list,pos) end
			self.Map[obj] = nil
			self.Changed:Fire()
		end

		funcs.RemoveTable = function(self,t)
			local changed
			local list,map = self.List,self.Map
			local removeSet = {}
			for i = 1,#t do
				local elem = t[i]
				map[elem] = nil
				removeSet[elem] = true
			end

			for i = #list,1,-1 do
				local elem = list[i]
				if removeSet[elem] then
					table.remove(list,i)
					changed = true
				end
			end
			if changed then self.Changed:Fire() end
		end

		funcs.Set = function(self,obj)
			if #self.List == 1 and self.List[1] == obj then return end

			self.List = {obj}
			self.Map = {[obj] = true}
			self.Changed:Fire()
		end

		funcs.SetTable = function(self,t)
			local newList,newMap = {},{}
			self.List,self.Map = newList,newMap
			table.move(t,1,#t,1,newList)
			for i = 1,#t do
				newMap[t[i]] = true
			end
			self.Changed:Fire()
		end

		funcs.Clear = function(self)
			if #self.List == 0 then return end
			self.List = {}
			self.Map = {}
			self.Changed:Fire()
		end

		local mt = {__index = funcs}

		local function new()
			local obj = setmetatable({
				List = {},
				Map = {},
				Changed = Lib.Signal.new()
			},mt)

			return obj
		end

		return {new = new}
	end)()
	
	Lib.IconMap = (function()
		local funcs = {}
		local IconList = {
			Old = {
				MapId = 483448923,
				IconSize = 16,
				Witdh = 16,
				Height = 16,
				Icons = {
					["Accessory"] = 32;
					["Accoutrement"] = 32;
					["AdService"] = 73;
					["Animation"] = 60;
					["AnimationController"] = 60;
					["AnimationTrack"] = 60;
					["Animator"] = 60;
					["ArcHandles"] = 56;
					["AssetService"] = 72;
					["Attachment"] = 34;
					["Backpack"] = 20;
					["BadgeService"] = 75;
					["BallSocketConstraint"] = 89;
					["BillboardGui"] = 64;
					["BinaryStringValue"] = 4;
					["BindableEvent"] = 67;
					["BindableFunction"] = 66;
					["BlockMesh"] = 8;
					["BloomEffect"] = 90;
					["BlurEffect"] = 90;
					["BodyAngularVelocity"] = 14;
					["BodyForce"] = 14;
					["BodyGyro"] = 14;
					["BodyPosition"] = 14;
					["BodyThrust"] = 14;
					["BodyVelocity"] = 14;
					["BoolValue"] = 4;
					["BoxHandleAdornment"] = 54;
					["BrickColorValue"] = 4;
					["Camera"] = 5;
					["CFrameValue"] = 4;
					["CharacterMesh"] = 60;
					["Chat"] = 33;
					["ClickDetector"] = 41;
					["CollectionService"] = 30;
					["Color3Value"] = 4;
					["ColorCorrectionEffect"] = 90;
					["ConeHandleAdornment"] = 54;
					["Configuration"] = 58;
					["ContentProvider"] = 72;
					["ContextActionService"] = 41;
					["CoreGui"] = 46;
					["CoreScript"] = 18;
					["CornerWedgePart"] = 1;
					["CustomEvent"] = 4;
					["CustomEventReceiver"] = 4;
					["CylinderHandleAdornment"] = 54;
					["CylinderMesh"] = 8;
					["CylindricalConstraint"] = 89;
					["Debris"] = 30;
					["Decal"] = 7;
					["Dialog"] = 62;
					["DialogChoice"] = 63;
					["DoubleConstrainedValue"] = 4;
					["Explosion"] = 36;
					["FileMesh"] = 8;
					["Fire"] = 61;
					["Flag"] = 38;
					["FlagStand"] = 39;
					["FloorWire"] = 4;
					["Folder"] = 70;
					["ForceField"] = 37;
					["Frame"] = 48;
					["GamePassService"] = 19;
					["Glue"] = 34;
					["GuiButton"] = 52;
					["GuiMain"] = 47;
					["GuiService"] = 47;
					["Handles"] = 53;
					["HapticService"] = 84;
					["Hat"] = 45;
					["HingeConstraint"] = 89;
					["Hint"] = 33;
					["HopperBin"] = 22;
					["HttpService"] = 76;
					["Humanoid"] = 9;
					["ImageButton"] = 52;
					["ImageLabel"] = 49;
					["InsertService"] = 72;
					["IntConstrainedValue"] = 4;
					["IntValue"] = 4;
					["JointInstance"] = 34;
					["JointsService"] = 34;
					["Keyframe"] = 60;
					["KeyframeSequence"] = 60;
					["KeyframeSequenceProvider"] = 60;
					["Lighting"] = 13;
					["LineHandleAdornment"] = 54;
					["LocalScript"] = 18;
					["LogService"] = 87;
					["MarketplaceService"] = 46;
					["Message"] = 33;
					["Model"] = 2;
					["ModuleScript"] = 71;
					["Motor"] = 34;
					["Motor6D"] = 34;
					["MoveToConstraint"] = 89;
					["NegateOperation"] = 78;
					["NetworkClient"] = 16;
					["NetworkReplicator"] = 29;
					["NetworkServer"] = 15;
					["NumberValue"] = 4;
					["ObjectValue"] = 4;
					["Pants"] = 44;
					["ParallelRampPart"] = 1;
					["Part"] = 1;
					["ParticleEmitter"] = 69;
					["PartPairLasso"] = 57;
					["PathfindingService"] = 37;
					["Platform"] = 35;
					["Player"] = 12;
					["PlayerGui"] = 46;
					["Players"] = 21;
					["PlayerScripts"] = 82;
					["PointLight"] = 13;
					["PointsService"] = 83;
					["Pose"] = 60;
					["PrismaticConstraint"] = 89;
					["PrismPart"] = 1;
					["PyramidPart"] = 1;
					["RayValue"] = 4;
					["ReflectionMetadata"] = 86;
					["ReflectionMetadataCallbacks"] = 86;
					["ReflectionMetadataClass"] = 86;
					["ReflectionMetadataClasses"] = 86;
					["ReflectionMetadataEnum"] = 86;
					["ReflectionMetadataEnumItem"] = 86;
					["ReflectionMetadataEnums"] = 86;
					["ReflectionMetadataEvents"] = 86;
					["ReflectionMetadataFunctions"] = 86;
					["ReflectionMetadataMember"] = 86;
					["ReflectionMetadataProperties"] = 86;
					["ReflectionMetadataYieldFunctions"] = 86;
					["RemoteEvent"] = 80;
					["RemoteFunction"] = 79;
					["ReplicatedFirst"] = 72;
					["ReplicatedStorage"] = 72;
					["RightAngleRampPart"] = 1;
					["RocketPropulsion"] = 14;
					["RodConstraint"] = 89;
					["RopeConstraint"] = 89;
					["Rotate"] = 34;
					["RotateP"] = 34;
					["RotateV"] = 34;
					["RunService"] = 66;
					["ScreenGui"] = 47;
					["Script"] = 6;
					["ScrollingFrame"] = 48;
					["Seat"] = 35;
					["Selection"] = 55;
					["SelectionBox"] = 54;
					["SelectionPartLasso"] = 57;
					["SelectionPointLasso"] = 57;
					["SelectionSphere"] = 54;
					["ServerScriptService"] = 0;
					["ServerStorage"] = 74;
					["Shirt"] = 43;
					["ShirtGraphic"] = 40;
					["SkateboardPlatform"] = 35;
					["Sky"] = 28;
					["SlidingBallConstraint"] = 89;
					["Smoke"] = 59;
					["Snap"] = 34;
					["Sound"] = 11;
					["SoundService"] = 31;
					["Sparkles"] = 42;
					["SpawnLocation"] = 25;
					["SpecialMesh"] = 8;
					["SphereHandleAdornment"] = 54;
					["SpotLight"] = 13;
					["SpringConstraint"] = 89;
					["StarterCharacterScripts"] = 82;
					["StarterGear"] = 20;
					["StarterGui"] = 46;
					["StarterPack"] = 20;
					["StarterPlayer"] = 88;
					["StarterPlayerScripts"] = 82;
					["Status"] = 2;
					["StringValue"] = 4;
					["SunRaysEffect"] = 90;
					["SurfaceGui"] = 64;
					["SurfaceLight"] = 13;
					["SurfaceSelection"] = 55;
					["Team"] = 24;
					["Teams"] = 23;
					["TeleportService"] = 81;
					["Terrain"] = 65;
					["TerrainRegion"] = 65;
					["TestService"] = 68;
					["TextBox"] = 51;
					["TextButton"] = 51;
					["TextLabel"] = 50;
					["Texture"] = 10;
					["TextureTrail"] = 4;
					["Tool"] = 17;
					["TouchTransmitter"] = 37;
					["TrussPart"] = 1;
					["UnionOperation"] = 77;
					["UserInputService"] = 84;
					["Vector3Value"] = 4;
					["VehicleSeat"] = 35;
					["VelocityMotor"] = 34;
					["WedgePart"] = 1;
					["Weld"] = 34;
					["Workspace"] = 19;

				}
			},
			Vanilla3 = {
				MapId = (114851699900089),
				IconSize = 32,
				Witdh = 25,
				Height = 25,
				Icons = {
					Accessory = 1,
					Accoutrement = 2,
					Actor = 3,
					AdGui = 4,
					AdPortal = 5,
					AdService = 6,
					AdvancedDragger = 7,
					AirController = 8,
					AlignOrientation = 9,
					AlignPosition = 10,
					AnalysticsService = 11,
					AnalysticsSettings = 12,
					AnalyticsService = 13,
					AngularVelocity = 14,
					Animation = 15,
					AnimationClip = 16,
					AnimationClipProvider = 17,
					AnimationController = 18,
					AnimationFromVideoCreatorService = 19,
					AnimationFromVideoCreatorStudioService = 20,
					AnimationRigData = 21,
					AnimationStreamTrack = 22,
					AnimationTrack = 23,
					Animator = 24,
					AppStorageService = 25,
					AppUpdateService = 26,
					ArcHandles = 27,
					AssetCounterService = 28,
					AssetDeliveryProxy = 29,
					AssetImportService = 30,
					AssetImportSession = 31,
					AssetManagerService = 32,
					AssetService = 33,
					AssetSoundEffect = 34,
					Atmosphere = 35,
					Attachment = 36,
					AvatarEditorService = 37,
					AvatarImportService = 38,
					Backpack = 39,
					BackpackItem = 40,
					BadgeService = 41,
					BallSocketConstraint = 42,
					BasePart = 43,
					BasePlayerGui = 44,
					BaseScript = 45,
					BaseWrap = 46,
					Beam = 47,
					BevelMesh = 48,
					BillboardGui = 49,
					BinaryStringValue = 50,
					BindableEvent = 51,
					BindableFunction = 52,
					BlockMesh = 53,
					BloomEffect = 54,
					BlurEffect = 55,
					BodyAngularVelocity = 56,
					BodyColors = 57,
					BodyForce = 58,
					BodyGyro = 59,
					BodyMover = 60,
					BodyPosition = 61,
					BodyThrust = 62,
					BodyVelocity = 63,
					Bone = 64,
					BoolValue = 65,
					BoxHandleAdornment = 66,
					Breakpoint = 67,
					BreakpointManager = 68,
					BrickColorValue = 69,
					BrowserService = 70,
					BubbleChatConfiguration = 71,
					BulkImportService = 72,
					CacheableContentProvider = 73,
					CalloutService = 74,
					Camera = 75,
					CanvasGroup = 76,
					CatalogPages = 77,
					CFrameValue = 78,
					ChangeHistoryService = 79,
					ChannelSelectorSoundEffect = 80,
					CharacterAppearance = 81,
					CharacterMesh = 82,
					Chat = 83,
					ChatInputBarConfiguration = 84,
					ChatWindowConfiguration = 85,
					ChorusSoundEffect = 86,
					ClickDetector = 87,
					ClientReplicator = 88,
					ClimbController = 89,
					Clothing = 90,
					Clouds = 91,
					ClusterPacketCache = 92,
					CollectionService = 93,
					Color3Value = 94,
					ColorCorrectionEffect = 95,
					CommandInstance = 96,
					CommandService = 97,
					CompressorSoundEffect = 98,
					ConeHandleAdornment = 99,
					Configuration = 100,
					ConfigureServerService = 101,
					Constraint = 102,
					ContentProvider = 103,
					ContextActionService = 104,
					Controller = 105,
					ControllerBase = 106,
					ControllerManager = 107,
					ControllerService = 108,
					CookiesService = 109,
					CoreGui = 110,
					CorePackages = 111,
					CoreScript = 112,
					CoreScriptSyncService = 113,
					CornerWedgePart = 114,
					CrossDMScriptChangeListener = 115,
					CSGDictionaryService = 116,
					CurveAnimation = 117,
					CustomEvent = 118,
					CustomEventReceiver = 119,
					CustomSoundEffect = 120,
					CylinderHandleAdornment = 121,
					CylinderMesh = 122,
					CylindricalConstraint = 123,
					DataModel = 124,
					DataModelMesh = 125,
					DataModelPatchService = 126,
					DataModelSession = 127,
					DataStore = 128,
					DataStoreIncrementOptions = 129,
					DataStoreInfo = 130,
					DataStoreKey = 131,
					DataStoreKeyInfo = 132,
					DataStoreKeyPages = 133,
					DataStoreListingPages = 134,
					DataStoreObjectVersionInfo = 135,
					DataStoreOptions = 136,
					DataStorePages = 137,
					DataStoreService = 138,
					DataStoreSetOptions = 139,
					DataStoreVersionPages = 140,
					Debris = 141,
					DebuggablePluginWatcher = 142,
					DebuggerBreakpoint = 143,
					DebuggerConnection = 144,
					DebuggerConnectionManager = 145,
					DebuggerLuaResponse = 146,
					DebuggerManager = 147,
					DebuggerUIService = 148,
					DebuggerVariable = 149,
					DebuggerWatch = 150,
					DebugSettings = 151,
					Decal = 152,
					DepthOfFieldEffect = 153,
					DeviceIdService = 154,
					Dialog = 155,
					DialogChoice = 156,
					DistortionSoundEffect = 157,
					DockWidgetPluginGui = 158,
					DoubleConstrainedValue = 159,
					DraftsService = 160,
					Dragger = 161,
					DraggerService = 162,
					DynamicRotate = 163,
					EchoSoundEffect = 164,
					EmotesPages = 165,
					EqualizerSoundEffect = 166,
					EulerRotationCurve = 167,
					EventIngestService = 168,
					Explosion = 169,
					FaceAnimatorService = 170,
					FaceControls = 171,
					FaceInstance = 172,
					FacialAnimationRecordingService = 173,
					FacialAnimationStreamingService = 174,
					Feature = 175,
					File = 176,
					FileMesh = 177,
					Fire = 178,
					Flag = 179,
					FlagStand = 180,
					FlagStandService = 181,
					FlangeSoundEffect = 182,
					FloatCurve = 183,
					FloorWire = 184,
					FlyweightService = 185,
					Folder = 186,
					ForceField = 187,
					FormFactorPart = 188,
					Frame = 189,
					FriendPages = 190,
					FriendService = 191,
					FunctionalTest = 192,
					GamepadService = 193,
					GamePassService = 194,
					GameSettings = 195,
					GenericSettings = 196,
					Geometry = 197,
					GetTextBoundsParams = 198,
					GlobalDataStore = 199,
					GlobalSettings = 200,
					Glue = 201,
					GoogleAnalyticsConfiguration = 202,
					GroundController = 203,
					GroupService = 204,
					GuiBase = 205,
					GuiBase2d = 206,
					GuiBase3d = 207,
					GuiButton = 208,
					GuidRegistryService = 209,
					GuiLabel = 210,
					GuiMain = 211,
					GuiObject = 212,
					GuiService = 213,
					HandleAdornment = 214,
					Handles = 215,
					HandlesBase = 216,
					HapticService = 217,
					Hat = 218,
					HeightmapImporterService = 219,
					HiddenSurfaceRemovalAsset = 220,
					Highlight = 221,
					HingeConstraint = 222,
					Hint = 223,
					Hole = 224,
					Hopper = 225,
					HopperBin = 226,
					HSRDataContentProvider = 227,
					HttpRbxApiService = 228,
					HttpRequest = 229,
					HttpService = 230,
					Humanoid = 231,
					HumanoidController = 232,
					HumanoidDescription = 233,
					IKControl = 234,
					ILegacyStudioBridge = 235,
					ImageButton = 236,
					ImageHandleAdornment = 237,
					ImageLabel = 238,
					ImporterAnimationSettings = 239,
					ImporterBaseSettings = 240,
					ImporterFacsSettings = 241,
					ImporterGroupSettings = 242,
					ImporterJointSettings = 243,
					ImporterMaterialSettings = 244,
					ImporterMeshSettings = 245,
					ImporterRootSettings = 246,
					IncrementalPatchBuilder = 247,
					InputObject = 248,
					InsertService = 249,
					Instance = 250,
					InstanceAdornment = 251,
					IntConstrainedValue = 252,
					IntValue = 253,
					InventoryPages = 254,
					IXPService = 255,
					JointInstance = 256,
					JointsService = 257,
					KeyboardService = 258,
					Keyframe = 259,
					KeyframeMarker = 260,
					KeyframeSequence = 261,
					KeyframeSequenceProvider = 262,
					LanguageService = 263,
					LayerCollector = 264,
					LegacyStudioBridge = 265,
					Light = 266,
					Lighting = 267,
					LinearVelocity = 268,
					LineForce = 269,
					LineHandleAdornment = 270,
					LocalDebuggerConnection = 271,
					LocalizationService = 272,
					LocalizationTable = 273,
					LocalScript = 274,
					LocalStorageService = 275,
					LodDataEntity = 276,
					LodDataService = 277,
					LoginService = 278,
					LogService = 279,
					LSPFileSyncService = 280,
					LuaSettings = 281,
					LuaSourceContainer = 282,
					LuauScriptAnalyzerService = 283,
					LuaWebService = 284,
					ManualGlue = 285,
					ManualSurfaceJointInstance = 286,
					ManualWeld = 287,
					MarkerCurve = 288,
					MarketplaceService = 289,
					MaterialService = 290,
					MaterialVariant = 291,
					MemoryStoreQueue = 292,
					MemoryStoreService = 293,
					MemoryStoreSortedMap = 294,
					MemStorageConnection = 295,
					MemStorageService = 296,
					MeshContentProvider = 297,
					MeshPart = 298,
					Message = 299,
					MessageBusConnection = 300,
					MessageBusService = 301,
					MessagingService = 302,
					MetaBreakpoint = 303,
					MetaBreakpointContext = 304,
					MetaBreakpointManager = 305,
					Model = 306,
					ModuleScript = 307,
					Motor = 308,
					Motor6D = 309,
					MotorFeature = 310,
					Mouse = 311,
					MouseService = 312,
					MultipleDocumentInterfaceInstance = 313,
					NegateOperation = 314,
					NetworkClient = 315,
					NetworkMarker = 316,
					NetworkPeer = 317,
					NetworkReplicator = 318,
					NetworkServer = 319,
					NetworkSettings = 320,
					NoCollisionConstraint = 321,
					NonReplicatedCSGDictionaryService = 322,
					NotificationService = 323,
					NumberPose = 324,
					NumberValue = 325,
					ObjectValue = 326,
					OrderedDataStore = 327,
					OutfitPages = 328,
					PackageLink = 329,
					PackageService = 330,
					PackageUIService = 331,
					Pages = 332,
					Pants = 333,
					ParabolaAdornment = 334,
					Part = 335,
					PartAdornment = 336,
					ParticleEmitter = 337,
					PartOperation = 338,
					PartOperationAsset = 339,
					PatchMapping = 340,
					Path = 341,
					PathfindingLink = 342,
					PathfindingModifier = 343,
					PathfindingService = 344,
					PausedState = 345,
					PausedStateBreakpoint = 346,
					PausedStateException = 347,
					PermissionsService = 348,
					PhysicsService = 349,
					PhysicsSettings = 350,
					PitchShiftSoundEffect = 351,
					Plane = 352,
					PlaneConstraint = 353,
					Platform = 354,
					Player = 355,
					PlayerEmulatorService = 356,
					PlayerGui = 357,
					PlayerMouse = 358,
					Players = 359,
					PlayerScripts = 360,
					Plugin = 361,
					PluginAction = 362,
					PluginDebugService = 363,
					PluginDragEvent = 364,
					PluginGui = 365,
					PluginGuiService = 366,
					PluginManagementService = 367,
					PluginManager = 368,
					PluginManagerInterface = 369,
					PluginMenu = 370,
					PluginMouse = 371,
					PluginPolicyService = 372,
					PluginToolbar = 373,
					PluginToolbarButton = 374,
					PointLight = 375,
					PointsService = 376,
					PolicyService = 377,
					Pose = 378,
					PoseBase = 379,
					PostEffect = 380,
					PrismaticConstraint = 381,
					ProcessInstancePhysicsService = 382,
					ProximityPrompt = 383,
					ProximityPromptService = 384,
					PublishService = 385,
					PVAdornment = 386,
					PVInstance = 387,
					QWidgetPluginGui = 388,
					RayValue = 389,
					RbxAnalyticsService = 390,
					ReflectionMetadata = 391,
					ReflectionMetadataCallbacks = 392,
					ReflectionMetadataClass = 393,
					ReflectionMetadataClasses = 394,
					ReflectionMetadataEnum = 395,
					ReflectionMetadataEnumItem = 396,
					ReflectionMetadataEnums = 397,
					ReflectionMetadataEvents = 398,
					ReflectionMetadataFunctions = 399,
					ReflectionMetadataItem = 400,
					ReflectionMetadataMember = 401,
					ReflectionMetadataProperties = 402,
					ReflectionMetadataYieldFunctions = 403,
					RemoteDebuggerServer = 404,
					RemoteEvent = 405,
					RemoteFunction = 406,
					RenderingTest = 407,
					RenderSettings = 408,
					ReplicatedFirst = 409,
					ReplicatedStorage = 410,
					ReverbSoundEffect = 411,
					RigidConstraint = 412,
					RobloxPluginGuiService = 413,
					RobloxReplicatedStorage = 414,
					RocketPropulsion = 415,
					RodConstraint = 416,
					RopeConstraint = 417,
					Rotate = 418,
					RotateP = 419,
					RotateV = 420,
					RotationCurve = 421,
					RtMessagingService = 422,
					RunningAverageItemDouble = 423,
					RunningAverageItemInt = 424,
					RunningAverageTimeIntervalItem = 425,
					RunService = 426,
					RuntimeScriptService = 427,
					ScreenGui = 428,
					ScreenshotHud = 429,
					Script = 430,
					ScriptChangeService = 431,
					ScriptCloneWatcher = 432,
					ScriptCloneWatcherHelper = 433,
					ScriptContext = 434,
					ScriptDebugger = 435,
					ScriptDocument = 436,
					ScriptEditorService = 437,
					ScriptRegistrationService = 438,
					ScriptService = 439,
					ScrollingFrame = 440,
					Seat = 441,
					Selection = 442,
					SelectionBox = 443,
					SelectionLasso = 444,
					SelectionPartLasso = 445,
					SelectionPointLasso = 446,
					SelectionSphere = 447,
					ServerReplicator = 448,
					ServerScriptService = 449,
					ServerStorage = 450,
					ServiceProvider = 451,
					SessionService = 452,
					Shirt = 453,
					ShirtGraphic = 454,
					SkateboardController = 455,
					SkateboardPlatform = 456,
					Skin = 457,
					Sky = 458,
					SlidingBallConstraint = 459,
					Smoke = 460,
					Snap = 461,
					SnippetService = 462,
					SocialService = 463,
					SolidModelContentProvider = 464,
					Sound = 465,
					SoundEffect = 466,
					SoundGroup = 467,
					SoundService = 468,
					Sparkles = 469,
					SpawnerService = 470,
					SpawnLocation = 471,
					Speaker = 472,
					SpecialMesh = 473,
					SphereHandleAdornment = 474,
					SpotLight = 475,
					SpringConstraint = 476,
					StackFrame = 477,
					StandalonePluginScripts = 478,
					StandardPages = 479,
					StarterCharacterScripts = 480,
					StarterGear = 481,
					StarterGui = 482,
					StarterPack = 483,
					StarterPlayer = 484,
					StarterPlayerScripts = 485,
					Stats = 486,
					StatsItem = 487,
					Status = 488,
					StopWatchReporter = 489,
					StringValue = 490,
					Studio = 491,
					StudioAssetService = 492,
					StudioData = 493,
					StudioDeviceEmulatorService = 494,
					StudioHighDpiService = 495,
					StudioPublishService = 496,
					StudioScriptDebugEventListener = 497,
					StudioService = 498,
					StudioTheme = 499,
					SunRaysEffect = 500,
					SurfaceAppearance = 501,
					SurfaceGui = 502,
					SurfaceGuiBase = 503,
					SurfaceLight = 504,
					SurfaceSelection = 505,
					SwimController = 506,
					TaskScheduler = 507,
					Team = 508,
					TeamCreateService = 509,
					Teams = 510,
					TeleportAsyncResult = 511,
					TeleportOptions = 512,
					TeleportService = 513,
					TemporaryCageMeshProvider = 514,
					TemporaryScriptService = 515,
					Terrain = 516,
					TerrainDetail = 517,
					TerrainRegion = 518,
					TestService = 519,
					TextBox = 520,
					TextBoxService = 521,
					TextButton = 522,
					TextChannel = 523,
					TextChatCommand = 524,
					TextChatConfigurations = 525,
					TextChatMessage = 526,
					TextChatMessageProperties = 527,
					TextChatService = 528,
					TextFilterResult = 529,
					TextLabel = 530,
					TextService = 531,
					TextSource = 532,
					Texture = 533,
					ThirdPartyUserService = 534,
					ThreadState = 535,
					TimerService = 536,
					ToastNotificationService = 537,
					Tool = 538,
					ToolboxService = 539,
					Torque = 540,
					TorsionSpringConstraint = 541,
					TotalCountTimeIntervalItem = 542,
					TouchInputService = 543,
					TouchTransmitter = 544,
					TracerService = 545,
					TrackerStreamAnimation = 546,
					Trail = 547,
					Translator = 548,
					TremoloSoundEffect = 549,
					TriangleMeshPart = 550,
					TrussPart = 551,
					Tween = 552,
					TweenBase = 553,
					TweenService = 554,
					UGCValidationService = 555,
					UIAspectRatioConstraint = 556,
					UIBase = 557,
					UIComponent = 558,
					UIConstraint = 559,
					UICorner = 560,
					UIGradient = 561,
					UIGridLayout = 562,
					UIGridStyleLayout = 563,
					UILayout = 564,
					UIListLayout = 565,
					UIPadding = 566,
					UIPageLayout = 567,
					UIScale = 568,
					UISizeConstraint = 569,
					UIStroke = 570,
					UITableLayout = 571,
					UITextSizeConstraint = 572,
					UnionOperation = 573,
					UniversalConstraint = 574,
					UnvalidatedAssetService = 575,
					UserGameSettings = 576,
					UserInputService = 577,
					UserService = 578,
					UserSettings = 579,
					UserStorageService = 580,
					ValueBase = 581,
					Vector3Curve = 582,
					Vector3Value = 583,
					VectorForce = 584,
					VehicleController = 585,
					VehicleSeat = 586,
					VelocityMotor = 587,
					VersionControlService = 588,
					VideoCaptureService = 589,
					VideoFrame = 590,
					ViewportFrame = 591,
					VirtualInputManager = 592,
					VirtualUser = 593,
					VisibilityService = 594,
					Visit = 595,
					VoiceChannel = 596,
					VoiceChatInternal = 597,
					VoiceChatService = 598,
					VoiceSource = 599,
					VRService = 600,
					WedgePart = 601,
					Weld = 602,
					WeldConstraint = 603,
					WireframeHandleAdornment = 604,
					Workspace = 605,
					WorldModel = 606,
					WorldRoot = 607,
					WrapLayer = 608,
					WrapTarget = 609,

				}
			},
			NewDark = {
				MapId = 135148380892747,
				Icons = {
					Accessory = 1,
					Actor = 2,
					AdGui = 3,
					AdPortal = 4,
					AirController = 5,
					AlignOrientation = 6,
					AlignPosition = 7,
					AngularVelocity = 8,
					Animation = 9,
					AnimationConstraint = 10,
					AnimationController = 11,
					AnimationFromVideoCreatorService = 12,
					Animator = 13,
					ArcHandles = 14,
					Atmosphere = 15,
					Attachment = 16,
					AudioAnalyzer = 17,
					AudioChannelMixer = 18,
					AudioChannelSplitter = 19,
					AudioChorus = 20,
					AudioCompressor = 21,
					AudioDeviceInput = 22,
					AudioDeviceOutput = 23,
					AudioDistortion = 24,
					AudioEcho = 25,
					AudioEmitter = 26,
					AudioEqualizer = 27,
					AudioFader = 28,
					AudioFilter = 29,
					AudioFlanger = 30,
					AudioGate = 31,
					AudioLimiter = 32,
					AudioListener = 33,
					AudioPitchShifter = 34,
					AudioPlayer = 35,
					AudioRecorder = 36,
					AudioReverb = 37,
					AudioTextToSpeech = 38,
					AuroraScript = 39,
					AvatarEditorService = 40,
					AvatarSettings = 41,
					Backpack = 42,
					BallSocketConstraint = 43,
					BasePlate = 44,
					Beam = 45,
					BillboardGui = 46,
					BindableEvent = 47,
					BindableFunction = 48,
					BlockMesh = 49,
					BloomEffect = 50,
					BlurEffect = 51,
					BodyAngularVelocity = 52,
					BodyColors = 53,
					BodyForce = 54,
					BodyGyro = 55,
					BodyPosition = 56,
					BodyThrust = 57,
					BodyVelocity = 58,
					Bone = 59,
					BoolValue = 60,
					BoxHandleAdornment = 61,
					Breakpoint = 62,
					BrickColorValue = 63,
					BubbleChatConfiguration = 64,
					Buggaroo = 65,
					Camera = 66,
					CanvasGroup = 67,
					CFrameValue = 68,
					ChannelTabsConfiguration = 69,
					CharacterControllerManager = 70,
					CharacterMesh = 71,
					Chat = 72,
					ChatInputBarConfiguration = 73,
					ChatWindowConfiguration = 74,
					ChorusSoundEffect = 75,
					Class = 76,
					Cleanup = 77,
					ClickDetector = 78,
					ClientReplicator = 79,
					ClimbController = 80,
					Clouds = 81,
					Color = 82,
					ColorCorrectionEffect = 83,
					CompressorSoundEffect = 84,
					ConeHandleAdornment = 85,
					Configuration = 86,
					Constant = 87,
					Constructor = 88,
					Controller = 89,
					CoreGui = 90,
					CornerWedgePart = 91,
					CylinderHandleAdornment = 92,
					CylindricalConstraint = 93,
					Decal = 94,
					DepthOfFieldEffect = 95,
					Dialog = 96,
					DialogChoice = 97,
					DistortionSoundEffect = 98,
					DragDetector = 99,
					EchoSoundEffect = 100,
					EditableImage = 101,
					EditableMesh = 102,
					Enum = 103,
					EnumMember = 104,
					EqualizerSoundEffect = 105,
					Event = 106,
					Explosion = 107,
					FaceControls = 108,
					Field = 109,
					File = 110,
					Fire = 111,
					FlangeSoundEffect = 112,
					Folder = 113,
					ForceField = 114,
					Frame = 115,
					Function = 116,
					GameSettings = 117,
					GroundController = 118,
					Handles = 119,
					HapticEffect = 120,
					HapticService = 121,
					HeightmapImporterService = 122,
					Highlight = 123,
					HingeConstraint = 124,
					Humanoid = 125,
					HumanoidDescription = 126,
					IKControl = 127,
					ImageButton = 128,
					ImageHandleAdornment = 129,
					ImageLabel = 130,
					InputAction = 131,
					InputBinding = 132,
					InputContext = 133,
					Interface = 134,
					IntersectOperation = 135,
					Keyword = 136,
					Lighting = 137,
					LinearVelocity = 138,
					LineForce = 139,
					LineHandleAdornment = 140,
					LocalFile = 141,
					LocalizationService = 142,
					LocalizationTable = 143,
					LocalScript = 144,
					MaterialService = 145,
					MaterialVariant = 146,
					MemoryStoreService = 147,
					MeshPart = 148,
					Meshparts = 149,
					MessagingService = 150,
					Method = 151,
					Model = 152,
					Modelgroups = 153,
					Module = 154,
					ModuleScript = 155,
					Motor6D = 156,
					NegateOperation = 157,
					NetworkClient = 158,
					NoCollisionConstraint = 159,
					Operator = 160,
					PackageLink = 161,
					Pants = 162,
					Part = 163,
					ParticleEmitter = 164,
					Path2D = 165,
					PathfindingLink = 166,
					PathfindingModifier = 167,
					PathfindingService = 168,
					PitchShiftSoundEffect = 169,
					Place = 170,
					Placeholder = 171,
					Plane = 172,
					PlaneConstraint = 173,
					Player = 174,
					Players = 175,
					PluginGuiService = 176,
					PointLight = 177,
					PrismaticConstraint = 178,
					Property = 179,
					ProximityPrompt = 180,
					PublishService = 181,
					Reference = 182,
					RemoteEvent = 183,
					RemoteFunction = 184,
					RenderingTest = 185,
					ReplicatedFirst = 186,
					ReplicatedScriptService = 187,
					ReplicatedStorage = 188,
					ReverbSoundEffect = 189,
					RigidConstraint = 190,
					RobloxPluginGuiService = 191,
					RocketPropulsion = 192,
					RodConstraint = 193,
					RopeConstraint = 194,
					Rotate = 195,
					ScreenGui = 196,
					Script = 197,
					ScrollingFrame = 198,
					Seat = 199,
					Selected_Workspace = 200,
					SelectionBox = 201,
					SelectionSphere = 202,
					ServerScriptService = 203,
					ServerStorage = 204,
					Service = 205,
					Shirt = 206,
					ShirtGraphic = 207,
					SkinnedMeshPart = 208,
					Sky = 209,
					Smoke = 210,
					Snap = 211,
					Snippet = 212,
					SocialService = 213,
					Sound = 214,
					SoundEffect = 215,
					SoundGroup = 216,
					SoundService = 217,
					Sparkles = 218,
					SpawnLocation = 219,
					SpecialMesh = 220,
					SphereHandleAdornment = 221,
					SpotLight = 222,
					SpringConstraint = 223,
					StandalonePluginScripts = 224,
					StarterCharacterScripts = 225,
					StarterGui = 226,
					StarterPack = 227,
					StarterPlayer = 228,
					StarterPlayerScripts = 229,
					Struct = 230,
					StyleDerive = 231,
					StyleLink = 232,
					StyleRule = 233,
					StyleSheet = 234,
					SunRaysEffect = 235,
					SurfaceAppearance = 236,
					SurfaceGui = 237,
					SurfaceLight = 238,
					SurfaceSelection = 239,
					SwimController = 240,
					TaskScheduler = 241,
					Team = 242,
					Teams = 243,
					Terrain = 244,
					TerrainDetail = 245,
					TestService = 246,
					TextBox = 247,
					TextBoxService = 248,
					TextButton = 249,
					TextChannel = 250,
					TextChatCommand = 251,
					TextChatService = 252,
					TextLabel = 253,
					TextString = 254,
					Texture = 255,
					Tool = 256,
					Torque = 257,
					TorsionSpringConstraint = 258,
					Trail = 259,
					TremoloSoundEffect = 260,
					TrussPart = 261,
					TypeParameter = 262,
					UGCValidationService = 263,
					UIAspectRatioConstraint = 264,
					UICorner = 265,
					UIDragDetector = 266,
					UIFlexItem = 267,
					UIGradient = 268,
					UIGridLayout = 269,
					UIListLayout = 270,
					UIPadding = 271,
					UIPageLayout = 272,
					UIScale = 273,
					UISizeConstraint = 274,
					UIStroke = 275,
					UITableLayout = 276,
					UITextSizeConstraint = 277,
					UnionOperation = 278,
					Unit = 279,
					UniversalConstraint = 280,
					UnreliableRemoteEvent = 281,
					UpdateAvailable = 282,
					UserService = 283,
					Value = 284,
					Variable = 285,
					VectorForce = 286,
					VehicleSeat = 287,
					VideoDisplay = 288,
					VideoFrame = 289,
					VideoPlayer = 290,
					ViewportFrame = 291,
					VirtualUser = 292,
					VoiceChannel = 293,
					Voicechat = 294,
					VoiceChatService = 295,
					VRService = 296,
					WedgePart = 297,
					Weld = 298,
					WeldConstraint = 299,
					Wire = 300,
					WireframeHandleAdornment = 301,
					Workspace = 302,
					WorldModel = 303,
					WrapDeformer = 304,
					WrapLayer = 305,
					WrapTarget = 306,
					
					Color3Value = 284,
					IntValue = 284,
					NumberValue = 284,
					ObjectValue = 284,
					RayValue = 284,
					StringValue = 284,
					Vector3Value = 284,
				},
				IconSize = 32,
				Witdh = 18,
				Height = 18,
			},
			NewLight = {
				MapId = "",
				Icons = {
					Class = "rbxasset://studio_svg_textures/Shared/InsertableObjects/Light/Standard/",
				},
				IconSize = 16,
				Witdh = 18,
				Height = 18,
			}
		}
		if Settings.ClassIcon and IconList[Settings.ClassIcon] then
			funcs.ExplorerIcons = {
				["MapId"] = IconList[Settings.ClassIcon].MapId,
				["Icons"] = IconList[Settings.ClassIcon].Icons,
				["IconSize"] = IconList[Settings.ClassIcon].IconSize,
				["Witdh"] = IconList[Settings.ClassIcon].Witdh,
				["Height"] = IconList[Settings.ClassIcon].Height}
		else
			funcs.ExplorerIcons = { ["MapId"] = IconList.Old.MapId, ["Icons"] = IconList.Old.Icons, ["IconSize"] = IconList.Old.IconSize }
		end
		
		

		funcs.GetLabel = function(self)
			local label = Instance.new("ImageLabel")
			self:SetupLabel(label)
			return label
		end

		funcs.SetupLabel = function(self,obj)
			obj.BackgroundTransparency = 1
			obj.ImageRectOffset = Vector2.new(0, 0)
			obj.ImageRectSize = Vector2.new(self.IconSizeX, self.IconSizeY)
			obj.ScaleType = Enum.ScaleType.Crop
			obj.Size = UDim2.new(0, self.IconSizeX, 0, self.IconSizeY)
		end

		funcs.Display = function(self,obj,index)
			obj.Image = self.MapId
			obj.ImageRectSize = Vector2.new(self.IconSizeX, self.IconSizeY)
			if not self.NumX then
				obj.ImageRectOffset = Vector2.new(self.IconSizeX*index, 0)
			else
				obj.ImageRectOffset = Vector2.new(self.IconSizeX*(index % self.NumX), self.IconSizeY*math.floor(index / self.NumX))
			end
		end

		funcs.DisplayByKey = function(self, obj, key)
			if self.IndexDict[key] then
				self:Display(obj, self.IndexDict[key])
			else
				local rmdEntry = RMD.Classes[obj.ClassName]
				Explorer.ClassIcons:Display(obj, rmdEntry and rmdEntry.ExplorerImageIndex or 0)
			end
		end

		funcs.IconDehash = function(self, _id)
			return math.floor(_id / 14 % 14), math.floor(_id % 14)
		end
		
		local ClassNameNoImage = {}
		funcs.GetExplorerIcon = function(self, obj, index)
			if Settings.ClassIcon == "Vanilla3" then
				obj.Size = UDim2.fromOffset(16, 16)

				index = (self.ExplorerIcons.Icons[index] or 250) - 1
				obj.ImageRectOffset = Vector2.new(funcs.ExplorerIcons.IconSize * (index % funcs.ExplorerIcons.Height), funcs.ExplorerIcons.IconSize * math.floor(index / funcs.ExplorerIcons.Height))
				obj.ImageRectSize = Vector2.new(funcs.ExplorerIcons.IconSize, funcs.ExplorerIcons.IconSize)
			elseif Settings.ClassIcon == "Old" then
				index = (self.ExplorerIcons.Icons[index] or 0)
				local row, col = self:IconDehash(index)
				local MapSize = Vector2.new(256, 256)
				local pad, border = 2, 1

				obj.Position = UDim2.new(-col - (pad * (col + 1) + border) / funcs.ExplorerIcons.IconSize, 0, -row - (pad * (row + 1) + border) / funcs.ExplorerIcons.IconSize, 0)
				obj.Size = UDim2.new(MapSize.X / funcs.ExplorerIcons.IconSize, 0, MapSize.Y / funcs.ExplorerIcons.IconSize, 0)
			elseif Settings.ClassIcon == "NewLight" or Settings.ClassIcon == "NewDark" then
				local isService = string.find(index, "Service") and game:GetService(index)
				
				obj.Size = UDim2.fromOffset(16, 16)
				index = (self.ExplorerIcons.Icons[index] or (isService and self.ExplorerIcons.Icons.Service) or self.ExplorerIcons.Icons.Placeholder) - 1
				obj.ImageRectOffset = Vector2.new(funcs.ExplorerIcons.IconSize * (index % funcs.ExplorerIcons.Height), funcs.ExplorerIcons.IconSize * math.floor(index / funcs.ExplorerIcons.Height))
				obj.ImageRectSize = Vector2.new(funcs.ExplorerIcons.IconSize, funcs.ExplorerIcons.IconSize)
			else
				index = (self.ExplorerIcons.Icons[index] or 0)
				local row, col = self:IconDehash(index)
				local MapSize = Vector2.new(256, 256)
				local pad, border = 2, 1

				obj.Position = UDim2.new(-col - (pad * (col + 1) + border) / funcs.ExplorerIcons.IconSize, 0, -row - (pad * (row + 1) + border) / funcs.ExplorerIcons.IconSize, 0)
				obj.Size = UDim2.new(MapSize.X / funcs.ExplorerIcons.IconSize, 0, MapSize.Y / funcs.ExplorerIcons.IconSize, 0)
			end
			
		end

		funcs.DisplayExplorerIcons = function(self, Frame, index)
			if Frame:FindFirstChild("IconMap") then
				self:GetExplorerIcon(Frame.IconMap, index)
			else
				Frame.ClipsDescendants = true

				local obj = Instance.new("ImageLabel", Frame)
				obj.BackgroundTransparency = 1
				obj.Image = ("http://www.roblox.com/asset/?id=" .. (self.ExplorerIcons.MapId))
				obj.Name = "IconMap"
				self:GetExplorerIcon(obj, index)
			end
		end

		funcs.SetDict = function(self,dict)
			self.IndexDict = dict
		end

		local mt = {}
		mt.__index = funcs

		local function new(mapId,mapSizeX,mapSizeY,iconSizeX,iconSizeY)
			local obj = setmetatable({
				MapId = mapId,
				MapSizeX = mapSizeX,
				MapSizeY = mapSizeY,
				IconSizeX = iconSizeX,
				IconSizeY = iconSizeY,
				NumX = mapSizeX/iconSizeX,
				IndexDict = {}
			}, mt)
			return obj
		end

		local function newLinear(mapId,iconSizeX,iconSizeY)
			local obj = setmetatable({
				MapId = mapId,
				IconSizeX = iconSizeX,
				IconSizeY = iconSizeY,
				IndexDict = {}
			},mt)
			return obj
		end
		
		local function getIconDataFromName(name)
			return IconList[name] or error("Name not found")
		end

		return {new = new, newLinear = newLinear, getIconDataFromName = getIconDataFromName}
	end)()

	Lib.ScrollBar = (function()
		local funcs = {}
		local user = service.UserInputService
		local mouse = plr:GetMouse()
		local checkMouseInGui = Lib.CheckMouseInGui
		local createArrow = Lib.CreateArrow

		local function drawThumb(self)
			local total = self.TotalSpace
			local visible = self.VisibleSpace
			local index = self.Index
			local scrollThumb = self.GuiElems.ScrollThumb
			local scrollThumbFrame = self.GuiElems.ScrollThumbFrame

			if not (self:CanScrollUp()	or self:CanScrollDown()) then
				scrollThumb.Visible = false
			else
				scrollThumb.Visible = true
			end

			if self.Horizontal then
				scrollThumb.Size = UDim2.new(visible/total,0,1,0)
				if scrollThumb.AbsoluteSize.X < 16 then
					scrollThumb.Size = UDim2.new(0,16,1,0)
				end
				local fs = scrollThumbFrame.AbsoluteSize.X
				local bs = scrollThumb.AbsoluteSize.X
				scrollThumb.Position = UDim2.new(self:GetScrollPercent()*(fs-bs)/fs,0,0,0)
			else
				scrollThumb.Size = UDim2.new(1,0,visible/total,0)
				if scrollThumb.AbsoluteSize.Y < 16 then
					scrollThumb.Size = UDim2.new(1,0,0,16)
				end
				local fs = scrollThumbFrame.AbsoluteSize.Y
				local bs = scrollThumb.AbsoluteSize.Y
				scrollThumb.Position = UDim2.new(0,0,self:GetScrollPercent()*(fs-bs)/fs,0)
			end
		end

		local function createFrame(self)
			local newFrame = createSimple("Frame",{Style=0,Active=true,AnchorPoint=Vector2.new(0,0),BackgroundColor3=Color3.new(0.35294118523598,0.35294118523598,0.35294118523598),BackgroundTransparency=0,BorderColor3=Color3.new(0.10588236153126,0.16470588743687,0.20784315466881),BorderSizePixel=0,ClipsDescendants=false,Draggable=false,Position=UDim2.new(1,-16,0,0),Rotation=0,Selectable=false,Size=UDim2.new(0,16,1,0),SizeConstraint=0,Visible=true,ZIndex=1,Name="ScrollBar",})
			local button1, button2

			if self.Horizontal then
				newFrame.Size = UDim2.new(1,0,0,16)
				button1 = createSimple("ImageButton",{
					Parent = newFrame,
					Name = "Left",
					Size = UDim2.new(0,16,0,16),
					BackgroundTransparency = 1,
					BorderSizePixel = 0,
					AutoButtonColor = false
				})
				createArrow(16,4,"left").Parent = button1
				button2 = createSimple("ImageButton",{
					Parent = newFrame,
					Name = "Right",
					Position = UDim2.new(1,-16,0,0),
					Size = UDim2.new(0,16,0,16),
					BackgroundTransparency = 1,
					BorderSizePixel = 0,
					AutoButtonColor = false
				})
				createArrow(16,4,"right").Parent = button2
			else
				newFrame.Size = UDim2.new(0,16,1,0)
				button1 = createSimple("ImageButton",{
					Parent = newFrame,
					Name = "Up",
					Size = UDim2.new(0,16,0,16),
					BackgroundTransparency = 1,
					BorderSizePixel = 0,
					AutoButtonColor = false
				})
				createArrow(16,4,"up").Parent = button1
				button2 = createSimple("ImageButton",{
					Parent = newFrame,
					Name = "Down",
					Position = UDim2.new(0,0,1,-16),
					Size = UDim2.new(0,16,0,16),
					BackgroundTransparency = 1,
					BorderSizePixel = 0,
					AutoButtonColor = false
				})
				createArrow(16,4,"down").Parent = button2
			end

			local scrollThumbFrame = createSimple("ImageButton", {
				BackgroundTransparency = 1,
				Parent = newFrame
			})
			if self.Horizontal then
				scrollThumbFrame.Position = UDim2.new(0,16,0,0)
				scrollThumbFrame.Size = UDim2.new(1,-32,1,0)
			else
				scrollThumbFrame.Position = UDim2.new(0,0,0,16)
				scrollThumbFrame.Size = UDim2.new(1,0,1,-32)
			end

			local scrollThumb = createSimple("Frame", {
				BackgroundColor3 = Color3.new(120/255, 120/255, 120/255),
				BorderSizePixel = 0,
				Parent = scrollThumbFrame
			})

			local markerFrame = createSimple("Frame", {
				BackgroundTransparency = 1,
				Name = "Markers",
				Size = UDim2.new(1, 0, 1, 0),
				Parent = scrollThumbFrame
			})

			local buttonPress = false
			local thumbPress = false
			local thumbFramePress = false

			local function handleButtonPress(button, scrollDirection)
				if self:CanScroll(scrollDirection) then
					button.BackgroundTransparency = 0.5
					self:ScrollToDirection(scrollDirection)
					self.Scrolled:Fire()
					local buttonTick = tick()
					local releaseEvent
					releaseEvent = user.InputEnded:Connect(function(input)
						if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
							releaseEvent:Disconnect()
							button.BackgroundTransparency = checkMouseInGui(button) and 0.8 or 1
							buttonPress = false
						end
					end)
					while buttonPress do
						if tick() - buttonTick >= 0.25 and self:CanScroll(scrollDirection) then
							self:ScrollToDirection(scrollDirection)
							self.Scrolled:Fire()
						end
						task.wait()
					end
				end
			end

			button1.MouseButton1Down:Connect(function(input)
				buttonPress = true
				handleButtonPress(button1, "Up")
			end)

			button1.InputEnded:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
					button1.BackgroundTransparency = 1
				end
			end)

			button2.MouseButton1Down:Connect(function(input)
				buttonPress = true
				handleButtonPress(button2, "Down")
			end)

			button2.InputEnded:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
					button2.BackgroundTransparency = 1
				end
			end)

			scrollThumb.InputBegan:Connect(function(input)
				if (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then
					local dir = self.Horizontal and "X" or "Y"
					local lastThumbPos = nil
					thumbPress = true
					scrollThumb.BackgroundTransparency = 0
					local mouseOffset = mouse[dir] - scrollThumb.AbsolutePosition[dir]
					local releaseEvent
					local mouseEvent

					releaseEvent = user.InputEnded:Connect(function(input)
						if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
							releaseEvent:Disconnect()
							if mouseEvent then mouseEvent:Disconnect() end
							scrollThumb.BackgroundTransparency = 0.2
							thumbPress = false
						end
					end)

					mouseEvent = user.InputChanged:Connect(function(input)
						if (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) and thumbPress then
							local thumbFrameSize = scrollThumbFrame.AbsoluteSize[dir] - scrollThumb.AbsoluteSize[dir]
							local pos = mouse[dir] - scrollThumbFrame.AbsolutePosition[dir] - mouseOffset
							if pos > thumbFrameSize then pos = thumbFrameSize
							elseif pos < 0 then pos = 0 end
							if lastThumbPos ~= pos then
								lastThumbPos = pos
								self:ScrollTo(math.floor(0.5 + pos / thumbFrameSize * (self.TotalSpace - self.VisibleSpace)))
							end
						end
					end)
				end
			end)

			scrollThumb.InputEnded:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
					scrollThumb.BackgroundTransparency = 0
				end
			end)

			scrollThumbFrame.InputBegan:Connect(function(input)
				if (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) and not checkMouseInGui(scrollThumb) then
					local dir = self.Horizontal and "X" or "Y"
					local scrollDir = (mouse[dir] >= scrollThumb.AbsolutePosition[dir] + scrollThumb.AbsoluteSize[dir]) and 1 or 0
					local function doTick()
						local scrollSize = self.VisibleSpace - 1
						if scrollDir == 0 and mouse[dir] < scrollThumb.AbsolutePosition[dir] then
							self:ScrollTo(self.Index - scrollSize)
						elseif scrollDir == 1 and mouse[dir] >= scrollThumb.AbsolutePosition[dir] + scrollThumb.AbsoluteSize[dir] then
							self:ScrollTo(self.Index + scrollSize)
						end
					end

					thumbPress = false
					thumbFramePress = true
					doTick()
					local thumbFrameTick = tick()
					local releaseEvent
					releaseEvent = user.InputEnded:Connect(function(input)
						if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
							releaseEvent:Disconnect()
							thumbFramePress = false
						end
					end)

					while thumbFramePress do
						if tick() - thumbFrameTick >= 0.3 and checkMouseInGui(scrollThumbFrame) then
							doTick()
						end
						task.wait()
					end
				end
			end)

			newFrame.MouseWheelForward:Connect(function()
				self:ScrollTo(self.Index - self.WheelIncrement)
			end)

			newFrame.MouseWheelBackward:Connect(function()
				self:ScrollTo(self.Index + self.WheelIncrement)
			end)

			self.GuiElems.ScrollThumb = scrollThumb
			self.GuiElems.ScrollThumbFrame = scrollThumbFrame
			self.GuiElems.Button1 = button1
			self.GuiElems.Button2 = button2
			self.GuiElems.MarkerFrame = markerFrame

			return newFrame
		end

		funcs.Update = function(self,nocallback)
			local total = self.TotalSpace
			local visible = self.VisibleSpace
			local index = self.Index
			local button1 = self.GuiElems.Button1
			local button2 = self.GuiElems.Button2

			self.Index = math.clamp(self.Index, 0, math.max(0, total - visible))

			if self.LastTotalSpace ~= self.TotalSpace then
				self.LastTotalSpace = self.TotalSpace
				self:UpdateMarkers()
			end

			if self:CanScrollUp() then
				for i,v in pairs(button1.Arrow:GetChildren()) do
					v.BackgroundTransparency = 0
				end
			else
				button1.BackgroundTransparency = 1
				for i,v in pairs(button1.Arrow:GetChildren()) do
					v.BackgroundTransparency = 0.5
				end
			end
			if self:CanScrollDown() then
				for i,v in pairs(button2.Arrow:GetChildren()) do
					v.BackgroundTransparency = 0
				end
			else
				button2.BackgroundTransparency = 1
				for i,v in pairs(button2.Arrow:GetChildren()) do
					v.BackgroundTransparency = 0.5
				end
			end

			drawThumb(self)
		end

		funcs.UpdateMarkers = function(self)
			local markerFrame = self.GuiElems.MarkerFrame
			markerFrame:ClearAllChildren()

			for i,v in pairs(self.Markers) do
				if i < self.TotalSpace then
					createSimple("Frame", {
						BackgroundTransparency = 0,
						BackgroundColor3 = v,
						BorderSizePixel = 0,
						Position = self.Horizontal and UDim2.new(i/self.TotalSpace,0,1,-6) or UDim2.new(1,-6,i/self.TotalSpace,0),
						Size = self.Horizontal and UDim2.new(0,1,0,6) or UDim2.new(0,6,0,1),
						Name = "Marker"..tostring(i),
						Parent = markerFrame
					})
				end
			end
		end

		funcs.AddMarker = function(self,ind,color)
			self.Markers[ind] = color or Color3.new(0,0,0)
		end
		funcs.ScrollTo = function(self, ind, nocallback)
			self.Index = ind
			self:Update()
			if not nocallback then
				self.Scrolled:Fire()
			end
		end
		funcs.ScrollUp = function(self)
			self.Index = self.Index - self.Increment
			self:Update()
		end
		funcs.CanScroll = function(self, direction)
			if direction == "Up" then
				return self:CanScrollUp()
			elseif direction == "Down" then
				return self:CanScrollDown()
			end
			return false
		end
		funcs.ScrollDown = function(self)
			self.Index = self.Index + self.Increment
			self:Update()
		end
		funcs.CanScrollUp = function(self)
			return self.Index > 0
		end
		funcs.CanScrollDown = function(self)
			return self.Index + self.VisibleSpace < self.TotalSpace
		end
		funcs.GetScrollPercent = function(self)
			return self.Index/(self.TotalSpace-self.VisibleSpace)
		end
		funcs.SetScrollPercent = function(self,perc)
			self.Index = math.floor(perc*(self.TotalSpace-self.VisibleSpace))
			self:Update()
		end
		funcs.ScrollToDirection = function(self, Direaction)
			if Direaction == "Up" then
				self:ScrollUp()
			elseif Direaction == "Down" then
				self:ScrollDown()
			end
		end

		funcs.Texture = function(self,data)
			self.ThumbColor = data.ThumbColor or Color3.new(0,0,0)
			self.ThumbSelectColor = data.ThumbSelectColor or Color3.new(0,0,0)
			self.GuiElems.ScrollThumb.BackgroundColor3 = data.ThumbColor or Color3.new(0,0,0)
			self.Gui.BackgroundColor3 = data.FrameColor or Color3.new(0,0,0)
			self.GuiElems.Button1.BackgroundColor3 = data.ButtonColor or Color3.new(0,0,0)
			self.GuiElems.Button2.BackgroundColor3 = data.ButtonColor or Color3.new(0,0,0)
			for i,v in pairs(self.GuiElems.Button1.Arrow:GetChildren()) do
				v.BackgroundColor3 = data.ArrowColor or Color3.new(0,0,0)
			end
			for i,v in pairs(self.GuiElems.Button2.Arrow:GetChildren()) do
				v.BackgroundColor3 = data.ArrowColor or Color3.new(0,0,0)
			end
		end

		funcs.SetScrollFrame = function(self,frame)
			if self.ScrollUpEvent then self.ScrollUpEvent:Disconnect() self.ScrollUpEvent = nil end
			if self.ScrollDownEvent then self.ScrollDownEvent:Disconnect() self.ScrollDownEvent = nil end
			self.ScrollUpEvent = frame.MouseWheelForward:Connect(function() self:ScrollTo(self.Index - self.WheelIncrement) end)
			self.ScrollDownEvent = frame.MouseWheelBackward:Connect(function() self:ScrollTo(self.Index + self.WheelIncrement) end)
		end

		local mt = {}
		mt.__index = funcs

		local function new(hor)
			local obj = setmetatable({
				Index = 0,
				VisibleSpace = 0,
				TotalSpace = 0,
				Increment = 1,
				WheelIncrement = 1,
				Markers = {},
				GuiElems = {},
				Horizontal = hor,
				LastTotalSpace = 0,
				Scrolled = Lib.Signal.new()
			},mt)
			obj.Gui = createFrame(obj)
			obj:Texture({
				ThumbColor = Color3.fromRGB(60,60,60),
				ThumbSelectColor = Color3.fromRGB(75,75,75),
				ArrowColor = Color3.new(1,1,1),
				FrameColor = Color3.fromRGB(40,40,40),
				ButtonColor = Color3.fromRGB(75,75,75)
			})
			return obj
		end

		return {new = new}
	end)()

	Lib.Window = (function()
		local funcs = {}
		local static = {MinWidth = 200, FreeWidth = 200}
		local mouse = plr:GetMouse()
		local sidesGui,alignIndicator
		local visibleWindows = {}
		local leftSide = {Width = 300, Windows = {}, ResizeCons = {}, Hidden = true}
		local rightSide = {Width = 300, Windows = {}, ResizeCons = {}, Hidden = true}

		local displayOrderStart
		local sideDisplayOrder
		local sideTweenInfo = TweenInfo.new(0.3,Enum.EasingStyle.Quad,Enum.EasingDirection.Out)
		local tweens = {}
		local isA = game.IsA

		local theme = {
			MainColor1 = Color3.fromRGB(52,52,52),
			MainColor2 = Color3.fromRGB(45,45,45),
			Button = Color3.fromRGB(60,60,60)
		}

		local function stopTweens()
			for i = 1,#tweens do
				tweens[i]:Cancel()
			end
			tweens = {}
		end

		local function resizeHook(self,resizer,dir)
			local pressing = false
			
			local guiMain = self.GuiElems.Main
			
			resizer.MouseEnter:Connect(function() resizer.BackgroundTransparency = 0.5 end)
			resizer.MouseButton1Down:Connect(function() pressing = true resizer.BackgroundTransparency = 0.5 end)
			resizer.MouseButton1Up:Connect(function() pressing = false resizer.BackgroundTransparency = 1 end)
			
			
			
			resizer.InputBegan:Connect(function(input)
				if not self.Dragging and not self.Resizing and self.Resizable and self.ResizableInternal and pressing then
					local isH = dir:find("[WE]") and true
					local isV = dir:find("[NS]") and true
					local signX = dir:find("W",1,true) and -1 or 1
					local signY = dir:find("N",1,true) and -1 or 1

					if self.Minimized and isV then return end
					
					if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
						
						local releaseEvent, mouseEvent

						local offX = input.Position.X - resizer.AbsolutePosition.X
						local offY = input.Position.Y - resizer.AbsolutePosition.Y

						self.Resizing = resizer
						
						releaseEvent = service.UserInputService.InputEnded:Connect(function(input)
							if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
								releaseEvent:Disconnect()
								if mouseEvent then mouseEvent:Disconnect() end
								self.Resizing = false
								resizer.BackgroundTransparency = 1
							end
						end)

						mouseEvent = service.UserInputService.InputChanged:Connect(function(input)
							if self.Resizable and self.ResizableInternal and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
								self:StopTweens()
								local deltaX = input.Position.X - resizer.AbsolutePosition.X - offX
								local deltaY = input.Position.Y - resizer.AbsolutePosition.Y - offY

								if guiMain.AbsoluteSize.X + deltaX * signX < self.MinX then deltaX = signX * (self.MinX - guiMain.AbsoluteSize.X) end
								if guiMain.AbsoluteSize.Y + deltaY * signY < self.MinY then deltaY = signY * (self.MinY - guiMain.AbsoluteSize.Y) end
								if signY < 0 and guiMain.AbsolutePosition.Y + deltaY < 0 then deltaY = -guiMain.AbsolutePosition.Y end

								guiMain.Position = guiMain.Position + UDim2.new(0, (signX < 0 and deltaX or 0), 0, (signY < 0 and deltaY or 0))
								self.SizeX = self.SizeX + (isH and deltaX * signX or 0)
								self.SizeY = self.SizeY + (isV and deltaY * signY or 0)
								guiMain.Size = UDim2.new(0, self.SizeX, 0, self.Minimized and 20 or self.SizeY)
							end
						end)
					end
				end
			end)

			resizer.InputEnded:Connect(function(input)
				--if input.UserInputType == Enum.UserInputType.Touch and Main.AllowDraggableOnMobile == false then return end
				if (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) and self.Resizing ~= resizer then
					resizer.BackgroundTransparency = 1
				end
			end)
		end

		local updateWindows

		local function moveToTop(window)
			local found = table.find(visibleWindows,window)
			if found then
				table.remove(visibleWindows,found)
				table.insert(visibleWindows,1,window)
				updateWindows()
			end
		end

		local function sideHasRoom(side,neededSize)
			local maxY = sidesGui.AbsoluteSize.Y - (math.max(0,#side.Windows - 1) * 4)
			local inc = 0
			for i,v in pairs(side.Windows) do
				inc = inc + (v.MinY or 100)
				if inc > maxY - neededSize then return false end
			end

			return true
		end

		local function getSideInsertPos(side,curY)
			local pos = #side.Windows + 1
			local range = {0,sidesGui.AbsoluteSize.Y}

			for i,v in pairs(side.Windows) do
				local midPos = v.PosY + v.SizeY/2
				if curY <= midPos then
					pos = i
					range[2] = midPos
					break
				else
					range[1] = midPos
				end
			end

			return pos,range
		end

		local function focusInput(self,obj)
			if isA(obj,"GuiButton") then
				obj.MouseButton1Down:Connect(function()
					moveToTop(self)
				end)
			elseif isA(obj,"TextBox") then
				obj.Focused:Connect(function()
					moveToTop(self)
				end)
			end
		end

		local createGui = function(self)
			local gui = create({
				{1,"ScreenGui",{Name="Window",}},
				{2,"Frame",{Active=true,BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=1,BorderSizePixel=0,Name="Main",Parent={1},Position=UDim2.new(0.40000000596046,0,0.40000000596046,0),Size=UDim2.new(0,300,0,300),}},
				--[[background mod set to 0.05]]	{3,"Frame",{BackgroundColor3=Color3.new(0.17647059261799,0.17647059261799,0.17647059261799),BorderSizePixel=0,Name="Content",Parent={2},Position=UDim2.new(0,0,0,20),Size=UDim2.new(1,0,1,-20),ClipsDescendants=true}},
				{4,"Frame",{BackgroundColor3=Color3.fromRGB(33,33,33),BorderSizePixel=0,Name="Line",Parent={3},Size=UDim2.new(1,0,0,1),}},
				{5,"TextButton",{AutoButtonColor=false,BackgroundColor3=Color3.new(0.20392157137394,0.20392157137394,0.20392157137394),BorderSizePixel=0,Name="TopBar",Parent={2},Size=UDim2.new(1,0,0,20),Text = ""}},
				{6,"TextLabel",{BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=1,Font=3,Name="Title",Parent={5},Position=UDim2.new(0,5,0,0),Size=UDim2.new(1,-10,0,20),Text="Window",TextColor3=Color3.new(1,1,1),TextSize=14,TextXAlignment=0}},
				{7,"TextButton",{AutoButtonColor=false,BackgroundColor3=Color3.new(0.12549020349979,0.12549020349979,0.12549020349979),BackgroundTransparency=1,BorderSizePixel=0,Font=3,Name="Close",Parent={5},Position=UDim2.new(1,-18,0,2),Size=UDim2.new(0,16,0,16),Text="",TextColor3=Color3.new(1,1,1),TextSize=14,}},
				{8,"ImageLabel",{BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=1,Image="rbxassetid://5054663650",Parent={7},Position=UDim2.new(0,3,0,3),Size=UDim2.new(0,10,0,10),}},
				{9,"UICorner",{CornerRadius=UDim.new(0,4),Parent={7},}},
				--[[lol mod]]	{9,"UICorner",{CornerRadius=UDim.new(0,4),Parent={2},}},
				{10,"TextButton",{AutoButtonColor=false,BackgroundColor3=Color3.new(0.12549020349979,0.12549020349979,0.12549020349979),BackgroundTransparency=1,BorderSizePixel=0,Font=3,Name="Minimize",Parent={5},Position=UDim2.new(1,-36,0,2),Size=UDim2.new(0,16,0,16),Text="",TextColor3=Color3.new(1,1,1),TextSize=14,}},
				{11,"ImageLabel",{BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=1,Image="rbxassetid://5034768003",Parent={10},Position=UDim2.new(0,3,0,3),Size=UDim2.new(0,10,0,10),}},
				{12,"UICorner",{CornerRadius=UDim.new(0,4),Parent={10},}},
				{13,"ImageLabel",{BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=1,BorderSizePixel=0,Image="rbxassetid://1427967925",Name="Outlines",Parent={2},Position=UDim2.new(0,-5,0,-5),ScaleType=1,Size=UDim2.new(1,10,1,10),SliceCenter=Rect.new(6,6,25,25),TileSize=UDim2.new(0,20,0,20),}},
				{14,"Frame",{BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=1,Name="ResizeControls",Parent={2},Position=UDim2.new(0,-5,0,-5),Size=UDim2.new(1,10,1,10),}},
				{15,"TextButton",{AutoButtonColor=false,BackgroundColor3=Color3.new(0.27450981736183,0.27450981736183,0.27450981736183),BackgroundTransparency=1,BorderSizePixel=0,Font=3,Name="North",Parent={14},Position=UDim2.new(0,5,0,0),Size=UDim2.new(1,-10,0,5),Text="",TextColor3=Color3.new(0,0,0),TextSize=14,}},
				{16,"TextButton",{AutoButtonColor=false,BackgroundColor3=Color3.new(0.27450981736183,0.27450981736183,0.27450981736183),BackgroundTransparency=1,BorderSizePixel=0,Font=3,Name="South",Parent={14},Position=UDim2.new(0,5,1,-5),Size=UDim2.new(1,-10,0,5),Text="",TextColor3=Color3.new(0,0,0),TextSize=14,}},
				{17,"TextButton",{AutoButtonColor=false,BackgroundColor3=Color3.new(0.27450981736183,0.27450981736183,0.27450981736183),BackgroundTransparency=1,BorderSizePixel=0,Font=3,Name="NorthEast",Parent={14},Position=UDim2.new(1,-5,0,0),Size=UDim2.new(0,5,0,5),Text="",TextColor3=Color3.new(0,0,0),TextSize=14,}},
				{18,"TextButton",{AutoButtonColor=false,BackgroundColor3=Color3.new(0.27450981736183,0.27450981736183,0.27450981736183),BackgroundTransparency=1,BorderSizePixel=0,Font=3,Name="East",Parent={14},Position=UDim2.new(1,-5,0,5),Size=UDim2.new(0,5,1,-10),Text="",TextColor3=Color3.new(0,0,0),TextSize=14,}},
				{19,"TextButton",{AutoButtonColor=false,BackgroundColor3=Color3.new(0.27450981736183,0.27450981736183,0.27450981736183),BackgroundTransparency=1,BorderSizePixel=0,Font=3,Name="West",Parent={14},Position=UDim2.new(0,0,0,5),Size=UDim2.new(0,5,1,-10),Text="",TextColor3=Color3.new(0,0,0),TextSize=14,}},
				{20,"TextButton",{AutoButtonColor=false,BackgroundColor3=Color3.new(0.27450981736183,0.27450981736183,0.27450981736183),BackgroundTransparency=1,BorderSizePixel=0,Font=3,Name="SouthEast",Parent={14},Position=UDim2.new(1,-5,1,-5),Size=UDim2.new(0,5,0,5),Text="",TextColor3=Color3.new(0,0,0),TextSize=14,}},
				{21,"TextButton",{AutoButtonColor=false,BackgroundColor3=Color3.new(0.27450981736183,0.27450981736183,0.27450981736183),BackgroundTransparency=1,BorderSizePixel=0,Font=3,Name="NorthWest",Parent={14},Size=UDim2.new(0,5,0,5),Text="",TextColor3=Color3.new(0,0,0),TextSize=14,}},
				{22,"TextButton",{AutoButtonColor=false,BackgroundColor3=Color3.new(0.27450981736183,0.27450981736183,0.27450981736183),BackgroundTransparency=1,BorderSizePixel=0,Font=3,Name="SouthWest",Parent={14},Position=UDim2.new(0,0,1,-5),Size=UDim2.new(0,5,0,5),Text="",TextColor3=Color3.new(0,0,0),TextSize=14,}},
			})

			local guiMain = gui.Main
			local guiTopBar = guiMain.TopBar
			local guiResizeControls = guiMain.ResizeControls

			self.GuiElems.Main = guiMain
			self.GuiElems.TopBar = guiMain.TopBar
			self.GuiElems.Content = guiMain.Content
			self.GuiElems.Line = guiMain.Content.Line
			self.GuiElems.Outlines = guiMain.Outlines
			self.GuiElems.Title = guiTopBar.Title
			self.GuiElems.Close = guiTopBar.Close
			self.GuiElems.Minimize = guiTopBar.Minimize
			self.GuiElems.ResizeControls = guiResizeControls
			self.ContentPane = guiMain.Content
			
			-- dont mind this, im testing what if the frame background is blurry 
			--blur.new(guiMain.Content, "Rectangle")

			--blur.updateAll()
			
			local ButtonDown = false
			guiTopBar.MouseButton1Down:Connect(function() ButtonDown = true end)
			guiTopBar.MouseButton1Up:Connect(function() ButtonDown = false end)

			if Settings.Window.TitleOnMiddle then
				self.GuiElems.Title.TextXAlignment = 2
				self.GuiElems.Title.Size = UDim2.new(1,-20,0,20)
			end

			if Settings.Window.Transparency then
				self.GuiElems.Content.BackgroundTransparency = Settings.Window.Transparency
				--self.GuiElems
			end


			guiTopBar.InputBegan:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
					if self.Draggable then
						local releaseEvent, mouseEvent

						local maxX = sidesGui.AbsoluteSize.X
						local initX = guiMain.AbsolutePosition.X
						local initY = guiMain.AbsolutePosition.Y
						local offX = input.Position.X - initX
						local offY = input.Position.Y - initY

						local alignInsertPos, alignInsertSide

						guiDragging = true

						releaseEvent = service.UserInputService.InputEnded:Connect(function(input)
							if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
								releaseEvent:Disconnect()
								if mouseEvent then mouseEvent:Disconnect() end
								guiDragging = false
								alignIndicator.Parent = nil
								if alignInsertSide then
									local targetSide = (alignInsertSide == "left" and leftSide) or (alignInsertSide == "right" and rightSide)
									self:AlignTo(targetSide, alignInsertPos)
								end
							end
						end)

						mouseEvent = service.UserInputService.InputChanged:Connect(function(input)
							if (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) and self.Draggable and not self.Closed and ButtonDown then
								if self.Aligned then
									if leftSide.Resizing or rightSide.Resizing then return end
									local posX, posY = input.Position.X - offX, input.Position.Y - offY
									local delta = math.sqrt((posX - initX)^2 + (posY - initY)^2)
									if delta >= 5 then
										self:SetAligned(false)
									end
								else
									local inputX, inputY = input.Position.X, input.Position.Y
									local posX, posY = inputX - offX, inputY - offY
									if posY < 0 then posY = 0 end
									guiMain.Position = UDim2.new(0, posX, 0, posY)

									if self.Resizable and self.Alignable then
										if inputX < 25 then
											if sideHasRoom(leftSide, self.MinY or 100) then
												local insertPos, range = getSideInsertPos(leftSide, inputY)
												alignIndicator.Indicator.Position = UDim2.new(0, -15, 0, range[1])
												alignIndicator.Indicator.Size = UDim2.new(0, 40, 0, range[2] - range[1])
												Lib.ShowGui(alignIndicator)
												alignInsertPos = insertPos
												alignInsertSide = "left"
												return
											end
										elseif inputX >= maxX - 25 then
											if sideHasRoom(rightSide, self.MinY or 100) then
												local insertPos, range = getSideInsertPos(rightSide, inputY)
												alignIndicator.Indicator.Position = UDim2.new(0, maxX - 25, 0, range[1])
												alignIndicator.Indicator.Size = UDim2.new(0, 40, 0, range[2] - range[1])
												Lib.ShowGui(alignIndicator)
												alignInsertPos = insertPos
												alignInsertSide = "right"
												return
											end
										end
									end
									alignIndicator.Parent = nil
									alignInsertPos = nil
									alignInsertSide = nil
								end
							end
						end)
					end
				end
			end)

			guiTopBar.Close.MouseButton1Click:Connect(function()
				if self.Closed then return end
				self:Close()
			end)

			guiTopBar.Minimize.MouseButton1Click:Connect(function()
				if self.Closed then return end
				if self.Aligned then
					self:SetAligned(false)
				else
					self:SetMinimized()
				end
			end)

			guiTopBar.Minimize.MouseButton2Click:Connect(function()
				if self.Closed then return end
				if not self.Aligned then
					self:SetMinimized(nil,2)
					guiTopBar.Minimize.BackgroundTransparency = 1
				end
			end)

			guiMain.InputBegan:Connect(function(input)
				if (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) and not self.Aligned and not self.Closed then
					moveToTop(self)
				end
			end)

			guiMain:GetPropertyChangedSignal("AbsolutePosition"):Connect(function()
				local absPos = guiMain.AbsolutePosition
				self.PosX = absPos.X
				self.PosY = absPos.Y
			end)

			resizeHook(self,guiResizeControls.North,"N")
			resizeHook(self,guiResizeControls.NorthEast,"NE")
			resizeHook(self,guiResizeControls.East,"E")
			resizeHook(self,guiResizeControls.SouthEast,"SE")
			resizeHook(self,guiResizeControls.South,"S")
			resizeHook(self,guiResizeControls.SouthWest,"SW")
			resizeHook(self,guiResizeControls.West,"W")
			resizeHook(self,guiResizeControls.NorthWest,"NW")

			guiMain.Size = UDim2.new(0,self.SizeX,0,self.SizeY)

			gui.DescendantAdded:Connect(function(obj) focusInput(self,obj) end)
			local descs = gui:GetDescendants()
			for i = 1,#descs do
				focusInput(self,descs[i])
			end

			self.MinimizeAnim = Lib.ButtonAnim(guiTopBar.Minimize)
			self.CloseAnim = Lib.ButtonAnim(guiTopBar.Close)

			return gui
		end

		local function updateSideFrames(noTween)
			stopTweens()
			leftSide.Frame.Size = UDim2.new(0,leftSide.Width,1,0)
			rightSide.Frame.Size = UDim2.new(0,rightSide.Width,1,0)
			leftSide.Frame.Resizer.Position = UDim2.new(0,leftSide.Width,0,0)
			rightSide.Frame.Resizer.Position = UDim2.new(0,-5,0,0)

			--leftSide.Frame.Visible = (#leftSide.Windows > 0)
			--rightSide.Frame.Visible = (#rightSide.Windows > 0)

			--[[if #leftSide.Windows > 0 and leftSide.Frame.Position == UDim2.new(0,-leftSide.Width-5,0,0) then
				leftSide.Frame:TweenPosition(UDim2.new(0,0,0,0),Enum.EasingDirection.Out,Enum.EasingStyle.Quad,0.3,true)
			elseif #leftSide.Windows == 0 and leftSide.Frame.Position == UDim2.new(0,0,0,0) then
				leftSide.Frame:TweenPosition(UDim2.new(0,-leftSide.Width-5,0,0),Enum.EasingDirection.Out,Enum.EasingStyle.Quad,0.3,true)
			end
			local rightTweenPos = (#rightSide.Windows == 0 and UDim2.new(1,5,0,0) or UDim2.new(1,-rightSide.Width,0,0))
			rightSide.Frame:TweenPosition(rightTweenPos,Enum.EasingDirection.Out,Enum.EasingStyle.Quad,0.3,true)]]
			local leftHidden = #leftSide.Windows == 0 or leftSide.Hidden
			local rightHidden = #rightSide.Windows == 0 or rightSide.Hidden
			local leftPos = (leftHidden and UDim2.new(0,-leftSide.Width-10,0,0) or UDim2.new(0,0,0,0))
			local rightPos = (rightHidden and UDim2.new(1,10,0,0) or UDim2.new(1,-rightSide.Width,0,0))

			sidesGui.LeftToggle.Text = leftHidden and ">" or "<"
			sidesGui.RightToggle.Text = rightHidden and "<" or ">"

			if not noTween then
				local function insertTween(...)
					local tween = service.TweenService:Create(...)
					tweens[#tweens+1] = tween
					tween:Play()
				end
				insertTween(leftSide.Frame,sideTweenInfo,{Position = leftPos})
				insertTween(rightSide.Frame,sideTweenInfo,{Position = rightPos})
				insertTween(sidesGui.LeftToggle,sideTweenInfo,{Position = UDim2.new(0,#leftSide.Windows == 0 and -16 or 0,0,-36)})
				insertTween(sidesGui.RightToggle,sideTweenInfo,{Position = UDim2.new(1,#rightSide.Windows == 0 and 0 or -16,0,-36)})
			else
				leftSide.Frame.Position = leftPos
				rightSide.Frame.Position = rightPos
				sidesGui.LeftToggle.Position = UDim2.new(0,#leftSide.Windows == 0 and -16 or 0,0,-36)
				sidesGui.RightToggle.Position = UDim2.new(1,#rightSide.Windows == 0 and 0 or -16,0,-36)
			end
		end

		local function getSideFramePos(side)
			local leftHidden = #leftSide.Windows == 0 or leftSide.Hidden
			local rightHidden = #rightSide.Windows == 0 or rightSide.Hidden
			if side == leftSide then
				return (leftHidden and UDim2.new(0,-leftSide.Width-10,0,0) or UDim2.new(0,0,0,0))
			else
				return (rightHidden and UDim2.new(1,10,0,0) or UDim2.new(1,-rightSide.Width,0,0))
			end
		end

		local function sideResized(side)
			local currentPos = 0
			local sideFramePos = getSideFramePos(side)
			for i,v in pairs(side.Windows) do
				v.SizeX = side.Width
				v.GuiElems.Main.Size = UDim2.new(0,side.Width,0,v.SizeY)
				v.GuiElems.Main.Position = UDim2.new(sideFramePos.X.Scale,sideFramePos.X.Offset,0,currentPos)
				currentPos = currentPos + v.SizeY+4
			end
		end

		local function sideResizerHook(resizer,dir,side,pos)
			local pressing = false
			
			local mouse = Main.Mouse
			local windows = side.Windows

			resizer.MouseEnter:Connect(function() resizer.BackgroundColor3 = theme.MainColor2 end)
			resizer.MouseButton1Down:Connect(function() pressing = true resizer.BackgroundColor3 = theme.MainColor2 end)
			resizer.MouseButton1Up:Connect(function() pressing = false resizer.BackgroundColor3 = theme.Button end)


			resizer.InputBegan:Connect(function(input)
				if not side.Resizing and pressing then
					if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
						resizer.BackgroundColor3 = theme.MainColor2
					end 
					if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
						local releaseEvent,mouseEvent

						local offX = mouse.X - resizer.AbsolutePosition.X
						local offY = mouse.Y - resizer.AbsolutePosition.Y

						side.Resizing = resizer
						resizer.BackgroundColor3 = theme.MainColor2

						releaseEvent = service.UserInputService.InputEnded:Connect(function(input)
							if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
								releaseEvent:Disconnect()
								mouseEvent:Disconnect()
								side.Resizing = false
								resizer.BackgroundColor3 = theme.Button
							end
						end)

						mouseEvent = service.UserInputService.InputChanged:Connect(function(input)
							if not resizer.Parent then
								releaseEvent:Disconnect()
								mouseEvent:Disconnect()
								side.Resizing = false
								return
							end
							if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
								if dir == "V" then
									local delta = input.Position.Y - resizer.AbsolutePosition.Y - offY

									if delta > 0 then
										local neededSize = delta
										for i = pos+1,#windows do
											local window = windows[i]
											local newSize = math.max(window.SizeY-neededSize,(window.MinY or 100))
											neededSize = neededSize - (window.SizeY - newSize)
											window.SizeY = newSize
										end
										windows[pos].SizeY = windows[pos].SizeY + math.max(0,delta-neededSize)
									else
										local neededSize = -delta
										for i = pos,1,-1 do
											local window = windows[i]
											local newSize = math.max(window.SizeY-neededSize,(window.MinY or 100))
											neededSize = neededSize - (window.SizeY - newSize)
											window.SizeY = newSize
										end
										windows[pos+1].SizeY = windows[pos+1].SizeY + math.max(0,-delta-neededSize)
									end

									updateSideFrames()
									sideResized(side)
								elseif dir == "H" then
									local maxWidth = math.max(300,sidesGui.AbsoluteSize.X-static.FreeWidth)
									local otherSide = (side == leftSide and rightSide or leftSide)
									local delta = input.Position.X - resizer.AbsolutePosition.X - offX
									delta = (side == leftSide and delta or -delta)

									local proposedSize = math.max(static.MinWidth,side.Width + delta)
									if proposedSize + otherSide.Width <= maxWidth then
										side.Width = proposedSize
									else
										local newOtherSize = maxWidth - proposedSize
										if newOtherSize >= static.MinWidth then
											side.Width = proposedSize
											otherSide.Width = newOtherSize
										else
											side.Width = maxWidth - static.MinWidth
											otherSide.Width = static.MinWidth
										end
									end

									updateSideFrames(true)
									sideResized(side)
									sideResized(otherSide)
								end
							end
						end)
					end
				end
			end)

			resizer.InputEnded:Connect(function(input)
				if (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) and side.Resizing ~= resizer then
					resizer.BackgroundColor3 = theme.Button
				end
			end)
		end

		local function renderSide(side,noTween) -- TODO: Use existing resizers
			local currentPos = 0
			local sideFramePos = getSideFramePos(side)
			local template = side.WindowResizer:Clone()
			for i,v in pairs(side.ResizeCons) do v:Disconnect() end
			for i,v in pairs(side.Frame:GetChildren()) do if v.Name == "WindowResizer" then v:Destroy() end end
			side.ResizeCons = {}
			side.Resizing = nil

			for i,v in pairs(side.Windows) do
				v.SidePos = i
				local isEnd = i == #side.Windows
				local size = UDim2.new(0,side.Width,0,v.SizeY)
				local pos = UDim2.new(sideFramePos.X.Scale,sideFramePos.X.Offset,0,currentPos)
				Lib.ShowGui(v.Gui)
				--v.GuiElems.Main:TweenSizeAndPosition(size,pos,Enum.EasingDirection.Out,Enum.EasingStyle.Quad,0.3,true)
				if noTween then
					v.GuiElems.Main.Size = size
					v.GuiElems.Main.Position = pos
				else
					local tween = service.TweenService:Create(v.GuiElems.Main,sideTweenInfo,{Size = size, Position = pos})
					tweens[#tweens+1] = tween
					tween:Play()
				end
				currentPos = currentPos + v.SizeY+4

				if not isEnd then
					local newTemplate = template:Clone()
					newTemplate.Position = UDim2.new(1,-side.Width,0,currentPos-4)
					side.ResizeCons[#side.ResizeCons+1] = v.Gui.Main:GetPropertyChangedSignal("Size"):Connect(function()
						newTemplate.Position = UDim2.new(1,-side.Width,0, v.GuiElems.Main.Position.Y.Offset + v.GuiElems.Main.Size.Y.Offset)
					end)
					side.ResizeCons[#side.ResizeCons+1] = v.Gui.Main:GetPropertyChangedSignal("Position"):Connect(function()
						newTemplate.Position = UDim2.new(1,-side.Width,0, v.GuiElems.Main.Position.Y.Offset + v.GuiElems.Main.Size.Y.Offset)
					end)
					sideResizerHook(newTemplate,"V",side,i)
					newTemplate.Parent = side.Frame
				end
			end

			--side.Frame.Back.Position = UDim2.new(0,0,0,0)
			--side.Frame.Back.Size = UDim2.new(0,side.Width,1,0)
		end

		local function updateSide(side,noTween)
			local oldHeight = 0
			local currentPos = 0
			local neededSize = 0
			local windows = side.Windows
			local height = sidesGui.AbsoluteSize.Y - (math.max(0,#windows - 1) * 4)

			for i,v in pairs(windows) do oldHeight = oldHeight + v.SizeY end
			for i,v in pairs(windows) do
				if i == #windows then
					v.SizeY = height-currentPos
					neededSize = math.max(0,(v.MinY or 100)-v.SizeY)
				else
					v.SizeY = math.max(math.floor(v.SizeY/oldHeight*height),v.MinY or 100)
				end
				currentPos = currentPos + v.SizeY
			end

			if neededSize > 0 then
				for i = #windows-1,1,-1 do
					local window = windows[i]
					local newSize = math.max(window.SizeY-neededSize,(window.MinY or 100))
					neededSize = neededSize - (window.SizeY - newSize)
					window.SizeY = newSize
				end
				local lastWindow = windows[#windows]
				lastWindow.SizeY = (lastWindow.MinY or 100)-neededSize
			end
			renderSide(side,noTween)
		end

		updateWindows = function(noTween)
			updateSideFrames(noTween)
			updateSide(leftSide,noTween)
			updateSide(rightSide,noTween)
			local count = 0
			for i = #visibleWindows,1,-1 do
				visibleWindows[i].Gui.DisplayOrder = displayOrderStart + count
				Lib.ShowGui(visibleWindows[i].Gui)
				count = count + 1
			end

			--[[local leftTweenPos = (#leftSide.Windows == 0 and UDim2.new(0,-leftSide.Width-5,0,0) or UDim2.new(0,0,0,0))
			leftSide.Frame:TweenPosition(leftTweenPos,Enum.EasingDirection.Out,Enum.EasingStyle.Quad,0.3,true)
			local rightTweenPos = (#rightSide.Windows == 0 and UDim2.new(1,5,0,0) or UDim2.new(1,-rightSide.Width,0,0))
			rightSide.Frame:TweenPosition(rightTweenPos,Enum.EasingDirection.Out,Enum.EasingStyle.Quad,0.3,true)]]
		end

		funcs.SetMinimized = function(self,set,mode)
			local oldVal = self.Minimized
			local newVal
			if set == nil then newVal = not self.Minimized else newVal = set end
			self.Minimized = newVal
			if not mode then mode = 1 end

			local resizeControls = self.GuiElems.ResizeControls
			local minimizeControls = {"North","NorthEast","NorthWest","South","SouthEast","SouthWest"}
			for i = 1,#minimizeControls do
				local control = resizeControls:FindFirstChild(minimizeControls[i])
				if control then control.Visible = not newVal end
			end

			if mode == 1 or mode == 2 then
				self:StopTweens()
				if mode == 1 then
					self.GuiElems.Main:TweenSize(UDim2.new(0,self.SizeX,0,newVal and 20 or self.SizeY),Enum.EasingDirection.Out,Enum.EasingStyle.Quart,0.25,true)
				else
					local maxY = sidesGui.AbsoluteSize.Y
					local newPos = UDim2.new(0,self.PosX,0,newVal and math.min(maxY-20,self.PosY + self.SizeY - 20) or math.max(0,self.PosY - self.SizeY + 20))

					self.GuiElems.Main:TweenPosition(newPos,Enum.EasingDirection.Out,Enum.EasingStyle.Quart,0.25,true)
					self.GuiElems.Main:TweenSize(UDim2.new(0,self.SizeX,0,newVal and 20 or self.SizeY),Enum.EasingDirection.Out,Enum.EasingStyle.Quart,0.25,true)
				end
				self.GuiElems.Minimize.ImageLabel.Image = newVal and "rbxassetid://5060023708" or "rbxassetid://5034768003"
			end

			if oldVal ~= newVal then
				if newVal then
					self.OnMinimize:Fire()
				else
					self.OnRestore:Fire()
				end
			end
		end

		funcs.Resize = function(self,sizeX,sizeY)
			self.SizeX = sizeX or self.SizeX
			self.SizeY = sizeY or self.SizeY
			self.GuiElems.Main.Size = UDim2.new(0,self.SizeX,0,self.SizeY)
		end

		funcs.SetSize = funcs.Resize

		funcs.SetTitle = function(self,title)
			self.GuiElems.Title.Text = title
		end

		funcs.SetResizable = function(self,val)
			self.Resizable = val
			self.GuiElems.ResizeControls.Visible = self.Resizable and self.ResizableInternal
		end

		funcs.SetResizableInternal = function(self,val)
			self.ResizableInternal = val
			self.GuiElems.ResizeControls.Visible = self.Resizable and self.ResizableInternal
		end

		funcs.SetAligned = function(self,val)
			self.Aligned = val
			self:SetResizableInternal(not val)
			self.GuiElems.Main.Active = not val
			self.GuiElems.Main.Outlines.Visible = not val
			if not val then
				for i,v in pairs(leftSide.Windows) do if v == self then table.remove(leftSide.Windows,i) break end end
				for i,v in pairs(rightSide.Windows) do if v == self then table.remove(rightSide.Windows,i) break end end
				if not table.find(visibleWindows,self) then table.insert(visibleWindows,1,self) end
				self.GuiElems.Minimize.ImageLabel.Image = "rbxassetid://5034768003"
				self.Side = nil
				updateWindows()
			else
				self:SetMinimized(false,3)
				for i,v in pairs(visibleWindows) do if v == self then table.remove(visibleWindows,i) break end end
				self.GuiElems.Minimize.ImageLabel.Image = "rbxassetid://5448127505"
			end
		end

		funcs.Add = function(self,obj,name)
			if type(obj) == "table" and obj.Gui and obj.Gui:IsA("GuiObject") then
				obj.Gui.Parent = self.ContentPane
			else
				obj.Parent = self.ContentPane
			end
			if name then self.Elements[name] = obj end
		end

		funcs.GetElement = function(self,obj,name)
			return self.Elements[name]
		end

		funcs.AlignTo = function(self,side,pos,size,silent)
			if table.find(side.Windows,self) or self.Closed then return end

			size = size or self.SizeY
			if size > 0 and size <= 1 then
				local totalSideHeight = 0
				for i,v in pairs(side.Windows) do totalSideHeight = totalSideHeight + v.SizeY end
				self.SizeY = (totalSideHeight > 0 and totalSideHeight * size * 2) or size
			else
				self.SizeY = (size > 0 and size or 100)
			end

			self:SetAligned(true)
			self.Side = side
			self.SizeX = side.Width
			self.Gui.DisplayOrder = sideDisplayOrder + 1
			for i,v in pairs(side.Windows) do v.Gui.DisplayOrder = sideDisplayOrder end
			pos = math.min(#side.Windows+1, pos or 1)
			self.SidePos = pos
			table.insert(side.Windows, pos, self)

			if not silent then
				side.Hidden = false
			end
			updateWindows(silent)
		end

		funcs.Close = function(self)
			self.Closed = true
			self:SetResizableInternal(false)

			Lib.FindAndRemove(leftSide.Windows,self)
			Lib.FindAndRemove(rightSide.Windows,self)
			Lib.FindAndRemove(visibleWindows,self)

			self.MinimizeAnim.Disable()
			self.CloseAnim.Disable()
			self.ClosedSide = self.Side
			self.Side = nil
			self.OnDeactivate:Fire()

			if not self.Aligned then
				self:StopTweens()
				local ti = TweenInfo.new(0.2,Enum.EasingStyle.Quad,Enum.EasingDirection.Out)

				local closeTime = tick()
				self.LastClose = closeTime

				self:DoTween(self.GuiElems.Main,ti,{Size = UDim2.new(0,self.SizeX,0,20)})
				self:DoTween(self.GuiElems.Title,ti,{TextTransparency = 1})
				self:DoTween(self.GuiElems.Minimize.ImageLabel,ti,{ImageTransparency = 1})
				self:DoTween(self.GuiElems.Close.ImageLabel,ti,{ImageTransparency = 1})
				Lib.FastWait(0.2)
				if closeTime ~= self.LastClose then return end

				self:DoTween(self.GuiElems.TopBar,ti,{BackgroundTransparency = 1})
				self:DoTween(self.GuiElems.Outlines,ti,{ImageTransparency = 1})
				Lib.FastWait(0.2)
				if closeTime ~= self.LastClose then return end
			end

			self.Aligned = false
			self.Gui.Parent = nil
			updateWindows(true)
		end
		
		funcs.Destroy = function(self)
			self.Closed = true
			self:SetResizableInternal(false)

			Lib.FindAndRemove(leftSide.Windows,self)
			Lib.FindAndRemove(rightSide.Windows,self)
			Lib.FindAndRemove(visibleWindows,self)

			self.MinimizeAnim.Disable()
			self.CloseAnim.Disable()
			self.ClosedSide = self.Side
			self.Side = nil
			self.OnDeactivate:Fire()

			if not self.Aligned then
				self:StopTweens()
				local ti = TweenInfo.new(0.2,Enum.EasingStyle.Quad,Enum.EasingDirection.Out)

				local closeTime = tick()
				self.LastClose = closeTime

				self:DoTween(self.GuiElems.Main,ti,{Size = UDim2.new(0,self.SizeX,0,20)})
				self:DoTween(self.GuiElems.Title,ti,{TextTransparency = 1})
				self:DoTween(self.GuiElems.Minimize.ImageLabel,ti,{ImageTransparency = 1})
				self:DoTween(self.GuiElems.Close.ImageLabel,ti,{ImageTransparency = 1})
				Lib.FastWait(0.2)
				if closeTime ~= self.LastClose then return end

				self:DoTween(self.GuiElems.TopBar,ti,{BackgroundTransparency = 1})
				self:DoTween(self.GuiElems.Outlines,ti,{ImageTransparency = 1})
				Lib.FastWait(0.2)
				if closeTime ~= self.LastClose then return end
			end

			self.Aligned = false
			--self.Gui.Parent = nil
			updateWindows(true)
			self.Gui:Destroy()
		end

		funcs.Hide = funcs.Close

		funcs.IsVisible = function(self)
			return not self.Closed and ((self.Side and not self.Side.Hidden) or not self.Side)
		end

		funcs.IsContentVisible = function(self)
			return self:IsVisible() and not self.Minimized
		end

		funcs.Focus = function(self)
			moveToTop(self)
		end

		funcs.MoveInBoundary = function(self)
			local posX,posY = self.PosX,self.PosY
			local maxX,maxY = sidesGui.AbsoluteSize.X,sidesGui.AbsoluteSize.Y
			posX = math.min(posX,maxX-self.SizeX)
			posY = math.min(posY,maxY-20)
			self.GuiElems.Main.Position = UDim2.new(0,posX,0,posY)
		end

		funcs.DoTween = function(self,...)
			local tween = service.TweenService:Create(...)
			self.Tweens[#self.Tweens+1] = tween
			tween:Play()
		end

		funcs.StopTweens = function(self)
			for i,v in pairs(self.Tweens) do
				v:Cancel()
			end
			self.Tweens = {}
		end

		funcs.Show = function(self,data)
			return static.ShowWindow(self,data)
		end

		funcs.ShowAndFocus = function(self,data)
			static.ShowWindow(self,data)
			service.RunService.RenderStepped:wait()
			self:Focus()
		end

		static.ShowWindow = function(window,data)
			data = data or {}
			local align = data.Align
			local pos = data.Pos
			local size = data.Size
			local targetSide = (align == "left" and leftSide) or (align == "right" and rightSide)

			if not window.Closed then
				if not window.Aligned then
					window:SetMinimized(false)
				elseif window.Side and not data.Silent then
					static.SetSideVisible(window.Side,true)
				end
				return
			end

			window.Closed = false
			window.LastClose = tick()
			window.GuiElems.Title.TextTransparency = 0
			window.GuiElems.Minimize.ImageLabel.ImageTransparency = 0
			window.GuiElems.Close.ImageLabel.ImageTransparency = 0
			window.GuiElems.TopBar.BackgroundTransparency = 0
			window.GuiElems.Outlines.ImageTransparency = 0
			window.GuiElems.Minimize.ImageLabel.Image = "rbxassetid://5034768003"
			window.GuiElems.Main.Active = true
			window.GuiElems.Main.Outlines.Visible = true
			window:SetMinimized(false,3)
			window:SetResizableInternal(true)
			window.MinimizeAnim.Enable()
			window.CloseAnim.Enable()

			if align then
				window:AlignTo(targetSide,pos,size,data.Silent)
			else
				if align == nil and window.ClosedSide then -- Regular open
					window:AlignTo(window.ClosedSide,window.SidePos,size,true)
					static.SetSideVisible(window.ClosedSide,true)
				else
					if table.find(visibleWindows,window) then return end

					-- TODO: make better
					window.GuiElems.Main.Size = UDim2.new(0,window.SizeX,0,20)
					local ti = TweenInfo.new(0.2,Enum.EasingStyle.Quad,Enum.EasingDirection.Out)
					window:StopTweens()
					window:DoTween(window.GuiElems.Main,ti,{Size = UDim2.new(0,window.SizeX,0,window.SizeY)})

					window.SizeY = size or window.SizeY
					table.insert(visibleWindows,1,window)
					updateWindows()
				end
			end

			window.ClosedSide = nil
			window.OnActivate:Fire()
		end

		static.ToggleSide = function(name)
			local side = (name == "left" and leftSide or rightSide)
			side.Hidden = not side.Hidden
			for i,v in pairs(side.Windows) do
				if side.Hidden then
					v.OnDeactivate:Fire()
				else
					v.OnActivate:Fire()
				end
			end
			updateWindows()
		end

		static.SetSideVisible = function(s,vis)
			local side = (type(s) == "table" and s) or (s == "left" and leftSide or rightSide)
			side.Hidden = not vis
			for i,v in pairs(side.Windows) do
				if side.Hidden then
					v.OnDeactivate:Fire()
				else
					v.OnActivate:Fire()
				end
			end
			updateWindows()
		end

		static.Init = function()
			displayOrderStart = Main.DisplayOrders.Window
			sideDisplayOrder = Main.DisplayOrders.SideWindow

			sidesGui = Instance.new("ScreenGui")
			local leftFrame = create({
				{1,"Frame",{Active=true,Name="LeftSide",BackgroundColor3=Color3.new(0.17647059261799,0.17647059261799,0.17647059261799),BorderSizePixel=0,}},
				{2,"TextButton",{AutoButtonColor=false,BackgroundColor3=Color3.new(0.2549019753933,0.2549019753933,0.2549019753933),BorderSizePixel=0,Font=3,Name="Resizer",Parent={1},Size=UDim2.new(0,5,1,0),Text="",TextColor3=Color3.new(0,0,0),TextSize=14,}},
				{3,"Frame",{BackgroundColor3=Color3.new(0.14117647707462,0.14117647707462,0.14117647707462),BorderSizePixel=0,Name="Line",Parent={2},Position=UDim2.new(0,0,0,0),Size=UDim2.new(0,1,1,0),}},
				{4,"TextButton",{AutoButtonColor=false,BackgroundColor3=Color3.new(0.2549019753933,0.2549019753933,0.2549019753933),BorderSizePixel=0,Font=3,Name="WindowResizer",Parent={1},Position=UDim2.new(1,-300,0,0),Size=UDim2.new(1,0,0,4),Text="",TextColor3=Color3.new(0,0,0),TextSize=14,}},
				{5,"Frame",{BackgroundColor3=Color3.new(0.14117647707462,0.14117647707462,0.14117647707462),BorderSizePixel=0,Name="Line",Parent={4},Size=UDim2.new(1,0,0,1),}},
			})
			leftSide.Frame = leftFrame
			leftFrame.Position = UDim2.new(0,-leftSide.Width-10,0,0)
			leftSide.WindowResizer = leftFrame.WindowResizer
			leftFrame.WindowResizer.Parent = nil
			leftFrame.Parent = sidesGui

			local rightFrame = create({
				{1,"Frame",{Active=true,Name="RightSide",BackgroundColor3=Color3.new(0.17647059261799,0.17647059261799,0.17647059261799),BorderSizePixel=0,}},
				{2,"TextButton",{AutoButtonColor=false,BackgroundColor3=Color3.new(0.2549019753933,0.2549019753933,0.2549019753933),BorderSizePixel=0,Font=3,Name="Resizer",Parent={1},Size=UDim2.new(0,5,1,0),Text="",TextColor3=Color3.new(0,0,0),TextSize=14,}},
				{3,"Frame",{BackgroundColor3=Color3.new(0.14117647707462,0.14117647707462,0.14117647707462),BorderSizePixel=0,Name="Line",Parent={2},Position=UDim2.new(0,4,0,0),Size=UDim2.new(0,1,1,0),}},
				{4,"TextButton",{AutoButtonColor=false,BackgroundColor3=Color3.new(0.2549019753933,0.2549019753933,0.2549019753933),BorderSizePixel=0,Font=3,Name="WindowResizer",Parent={1},Position=UDim2.new(1,-300,0,0),Size=UDim2.new(1,0,0,4),Text="",TextColor3=Color3.new(0,0,0),TextSize=14,}},
				{5,"Frame",{BackgroundColor3=Color3.new(0.14117647707462,0.14117647707462,0.14117647707462),BorderSizePixel=0,Name="Line",Parent={4},Size=UDim2.new(1,0,0,1),}},
			})
			rightSide.Frame = rightFrame
			rightFrame.Position = UDim2.new(1,10,0,0)
			rightSide.WindowResizer = rightFrame.WindowResizer
			rightFrame.WindowResizer.Parent = nil
			rightFrame.Parent = sidesGui

			if Settings.Window.Transparency and Settings.Window.Transparency > 0 then
				leftSide.BackgroundTransparency = 1
				rightSide.BackgroundTransparency = 1

				leftFrame.BackgroundTransparency = 1
				rightFrame.BackgroundTransparency = 1
			end

			sideResizerHook(leftFrame.Resizer,"H",leftSide)
			sideResizerHook(rightFrame.Resizer,"H",rightSide)

			alignIndicator = Instance.new("ScreenGui")
			alignIndicator.DisplayOrder = Main.DisplayOrders.Core
			local indicator = Instance.new("Frame",alignIndicator)
			indicator.BackgroundColor3 = Color3.fromRGB(0, 170, 255)
			indicator.BorderSizePixel = 0
			indicator.BackgroundTransparency = 0.8
			indicator.Name = "Indicator"
			local corner = Instance.new("UICorner",indicator)
			corner.CornerRadius = UDim.new(0,10)

			local leftToggle = create({{1,"TextButton",{AutoButtonColor=false,BackgroundColor3=Color3.new(0.20392157137394,0.20392157137394,0.20392157137394),BorderColor3=Color3.new(0.14117647707462,0.14117647707462,0.14117647707462),BorderMode=2,Font=10,Name="LeftToggle",Position=UDim2.new(0,0,0,-36),Size=UDim2.new(0,16,0,36),Text="<",TextColor3=Color3.new(1,1,1),TextSize=14,}}})
			local rightToggle = leftToggle:Clone()
			rightToggle.Name = "RightToggle"
			rightToggle.Position = UDim2.new(1,-16,0,-36)
			Lib.ButtonAnim(leftToggle,{Mode = 2,PressColor = Color3.fromRGB(32,32,32)})
			Lib.ButtonAnim(rightToggle,{Mode = 2,PressColor = Color3.fromRGB(32,32,32)})

			leftToggle.MouseButton1Click:Connect(function()
				static.ToggleSide("left")
			end)

			rightToggle.MouseButton1Click:Connect(function()
				static.ToggleSide("right")
			end)

			leftToggle.Parent = sidesGui
			rightToggle.Parent = sidesGui

			sidesGui:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
				local maxWidth = math.max(300,sidesGui.AbsoluteSize.X-static.FreeWidth)
				leftSide.Width = math.max(static.MinWidth,math.min(leftSide.Width,maxWidth-rightSide.Width))
				rightSide.Width = math.max(static.MinWidth,math.min(rightSide.Width,maxWidth-leftSide.Width))
				for i = 1,#visibleWindows do
					visibleWindows[i]:MoveInBoundary()
				end
				updateWindows(true)
			end)

			sidesGui.DisplayOrder = sideDisplayOrder - 1
			Lib.ShowGui(sidesGui)
			updateSideFrames()
		end

		local mt = {__index = funcs}
		static.new = function()
			local obj = setmetatable({
				Minimized = false,
				Dragging = false,
				Resizing = false,
				Aligned = false,
				Draggable = true,
				Resizable = true,
				ResizableInternal = true,
				Alignable = true,
				Closed = true,
				SizeX = 300,
				SizeY = 300,
				MinX = 200,
				MinY = 200,
				PosX = 0,
				PosY = 0,
				GuiElems = {},
				Tweens = {},
				Elements = {},
				OnActivate = Lib.Signal.new(),
				OnDeactivate = Lib.Signal.new(),
				OnMinimize = Lib.Signal.new(),
				OnRestore = Lib.Signal.new()
			},mt)
			obj.Gui = createGui(obj)
			return obj
		end

		return static
	end)()

	Lib.ContextMenu = (function()
		local funcs = {}
		local mouse

		local function createGui(self)
			local contextGui = create({
				{1,"ScreenGui",{DisplayOrder=1000000,Name="Context",ZIndexBehavior=1,}},
				{2,"Frame",{Active=true,BackgroundColor3=Color3.new(0.14117647707462,0.14117647707462,0.14117647707462),BorderColor3=Color3.new(0.14117647707462,0.14117647707462,0.14117647707462),Name="Main",Parent={1},Position=UDim2.new(0.5,-100,0.5,-150),Size=UDim2.new(0,200,0,100),}},
				{3,"UICorner",{CornerRadius=UDim.new(0,4),Parent={2},}},
				{4,"Frame",{BackgroundColor3=Color3.new(0.17647059261799,0.17647059261799,0.17647059261799),Name="Container",Parent={2},Position=UDim2.new(0,1,0,1),Size=UDim2.new(1,-2,1,-2),}},
				{5,"UICorner",{CornerRadius=UDim.new(0,4),Parent={4},}},
				{6,"ScrollingFrame",{Active=true,BackgroundColor3=Color3.new(0.20392157137394,0.20392157137394,0.20392157137394),BackgroundTransparency=1,BorderSizePixel=0,CanvasSize=UDim2.new(0,0,0,0),Name="List",Parent={4},Position=UDim2.new(0,2,0,2),ScrollBarImageColor3=Color3.new(0,0,0),ScrollBarThickness=4,Size=UDim2.new(1,-4,1,-4),VerticalScrollBarInset=1,}},
				{7,"UIListLayout",{Parent={6},SortOrder=2,}},
				{8,"Frame",{BackgroundColor3=Color3.new(0.20392157137394,0.20392157137394,0.20392157137394),BorderSizePixel=0,Name="SearchFrame",Parent={4},Size=UDim2.new(1,0,0,24),Visible=false,}},
				{9,"Frame",{BackgroundColor3=Color3.new(0.14901961386204,0.14901961386204,0.14901961386204),BorderColor3=Color3.new(0.1176470592618,0.1176470592618,0.1176470592618),BorderSizePixel=0,Name="SearchContainer",Parent={8},Position=UDim2.new(0,3,0,3),Size=UDim2.new(1,-6,0,18),}},
				{10,"TextBox",{BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=1,Font=3,Name="SearchBox",Parent={9},PlaceholderColor3=Color3.new(0.39215689897537,0.39215689897537,0.39215689897537),PlaceholderText="Search",Position=UDim2.new(0,4,0,0),Size=UDim2.new(1,-8,0,18),Text="",TextColor3=Color3.new(1,1,1),TextSize=14,TextXAlignment=0,}},
				{11,"UICorner",{CornerRadius=UDim.new(0,2),Parent={9},}},
				{12,"Frame",{BackgroundColor3=Color3.new(0.14117647707462,0.14117647707462,0.14117647707462),BorderSizePixel=0,Name="Line",Parent={8},Position=UDim2.new(0,0,1,0),Size=UDim2.new(1,0,0,1),}},
				{13,"TextButton",{AutoButtonColor=false,BackgroundColor3=Color3.new(0.20392157137394,0.20392157137394,0.20392157137394),BackgroundTransparency=1,BorderColor3=Color3.new(0.33725491166115,0.49019610881805,0.73725491762161),BorderSizePixel=0,Font=3,Name="Entry",Parent={1},Size=UDim2.new(1,0,0,22),Text="",TextSize=14,Visible=false,}},
				{14,"TextLabel",{BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=1,BorderSizePixel=0,Font=3,Name="EntryName",Parent={13},Position=UDim2.new(0,24,0,0),Size=UDim2.new(1,-24,1,0),Text="Duplicate",TextColor3=Color3.new(0.86274516582489,0.86274516582489,0.86274516582489),TextSize=14,TextXAlignment=0,}},
				{15,"TextLabel",{BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=1,Font=3,Name="Shortcut",Parent={13},Position=UDim2.new(0,24,0,0),Size=UDim2.new(1,-30,1,0),Text="Ctrl+D",TextColor3=Color3.new(0.86274516582489,0.86274516582489,0.86274516582489),TextSize=14,TextXAlignment=1,}},
				{16,"ImageLabel",{BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=1,ImageRectOffset=Vector2.new(304,0),ImageRectSize=Vector2.new(16,16),Name="Icon",Parent={13},Position=UDim2.new(0,2,0,3),ScaleType=4,Size=UDim2.new(0,16,0,16),}},
				{17,"UICorner",{CornerRadius=UDim.new(0,4),Parent={13},}},
				{18,"Frame",{BackgroundColor3=Color3.new(0.21568629145622,0.21568629145622,0.21568629145622),BackgroundTransparency=1,BorderSizePixel=0,Name="Divider",Parent={1},Position=UDim2.new(0,0,0,20),Size=UDim2.new(1,0,0,7),Visible=false,}},
				{19,"Frame",{BackgroundColor3=Color3.new(0.20392157137394,0.20392157137394,0.20392157137394),BorderSizePixel=0,Name="Line",Parent={18},Position=UDim2.new(0,0,0.5,0),Size=UDim2.new(1,0,0,1),}},
				{20,"TextLabel",{AnchorPoint=Vector2.new(0,0.5),BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=1,BorderSizePixel=0,Font=3,Name="DividerName",Parent={18},Position=UDim2.new(0,2,0.5,0),Size=UDim2.new(1,-4,1,0),Text="Objects",TextColor3=Color3.new(1,1,1),TextSize=14,TextTransparency=0.60000002384186,TextXAlignment=0,Visible=false,}}
			})

			self.GuiElems.Main = contextGui.Main
			self.GuiElems.List = contextGui.Main.Container.List
			self.GuiElems.Entry = contextGui.Entry
			self.GuiElems.Divider = contextGui.Divider
			self.GuiElems.SearchFrame = contextGui.Main.Container.SearchFrame
			self.GuiElems.SearchBar = self.GuiElems.SearchFrame.SearchContainer.SearchBox
			Lib.ViewportTextBox.convert(self.GuiElems.SearchBar)

			self.GuiElems.SearchBar:GetPropertyChangedSignal("Text"):Connect(function()
				local lower,find = string.lower,string.find
				local searchText = lower(self.GuiElems.SearchBar.Text)
				local items = self.Items
				local map = self.ItemToEntryMap

				if searchText ~= "" then
					local results = {}
					local count = 1
					for i = 1,#items do
						local item = items[i]
						local entry = map[item]
						if entry then
							if not item.Divider and find(lower(item.Name),searchText,1,true) then
								results[count] = item
								count = count + 1
							else
								entry.Visible = false
							end
						end
					end
					table.sort(results,function(a,b) return a.Name < b.Name end)
					for i = 1,#results do
						local entry = map[results[i]]
						entry.LayoutOrder = i
						entry.Visible = true
					end
				else
					for i = 1,#items do
						local entry = map[items[i]]
						if entry then entry.LayoutOrder = i entry.Visible = true end
					end
				end

				local toSize = self.GuiElems.List.UIListLayout.AbsoluteContentSize.Y + 6
				self.GuiElems.List.CanvasSize = UDim2.new(0,0,0,toSize-6)
			end)

			return contextGui
		end

		funcs.Add = function(self,item)
			local newItem = {
				Name = item.Name or "Item",
				Icon = item.Icon or "",
				Shortcut = item.Shortcut or "",
				OnClick = item.OnClick,
				OnHover = item.OnHover,
				Disabled = item.Disabled or false,
				DisabledIcon = item.DisabledIcon or "",
				IconMap = item.IconMap,
				OnRightClick = item.OnRightClick
			}
			
			newItem.DisabledIcon = newItem.Icon

			if self.QueuedDivider then
				local text = self.QueuedDividerText and #self.QueuedDividerText > 0 and self.QueuedDividerText
				self:AddDivider(text)
			end
			self.Items[#self.Items+1] = newItem
			self.Updated = nil
		end

		funcs.AddRegistered = function(self,name,disabled)
			if not self.Registered[name] then error(name.." is not registered") end

			if self.QueuedDivider then
				local text = self.QueuedDividerText and #self.QueuedDividerText > 0 and self.QueuedDividerText
				self:AddDivider(text)
			end
			self.Registered[name].Disabled = disabled
			self.Items[#self.Items+1] = self.Registered[name]
			self.Updated = nil
		end

		funcs.Register = function(self,name,item)
			self.Registered[name] = {
				Name = item.Name or "Item",
				Icon = item.Icon or "",
				Shortcut = item.Shortcut or "",
				OnClick = item.OnClick,
				OnHover = item.OnHover,
				DisabledIcon = item.DisabledIcon or "",
				IconMap = item.IconMap,
				OnRightClick = item.OnRightClick
			}
		end

		funcs.UnRegister = function(self,name)
			self.Registered[name] = nil
		end

		funcs.AddDivider = function(self,text)
			self.QueuedDivider = false
			local textWidth = text and service.TextService:GetTextSize(text,14,Enum.Font.SourceSans,Vector2.new(999999999,20)).X or nil
			table.insert(self.Items,{Divider = true, Text = text, TextSize = textWidth and textWidth+4})
			self.Updated = nil
		end

		funcs.QueueDivider = function(self,text)
			self.QueuedDivider = true
			self.QueuedDividerText = text or ""
		end

		funcs.Clear = function(self)
			self.Items = {}
			self.Updated = nil
		end

		funcs.Refresh = function(self)
			for i,v in pairs(self.GuiElems.List:GetChildren()) do
				if not v:IsA("UIListLayout") then
					v:Destroy()
				end
			end
			local map = {}
			self.ItemToEntryMap = map

			local dividerFrame = self.GuiElems.Divider
			local contextList = self.GuiElems.List
			local entryFrame = self.GuiElems.Entry
			local items = self.Items

			for i = 1,#items do
				local item = items[i]
				if item.Divider then
					local newDivider = dividerFrame:Clone()
					newDivider.Line.BackgroundColor3 = self.Theme.DividerColor
					if item.Text then
						newDivider.Size = UDim2.new(1,0,0,20)
						newDivider.Line.Position = UDim2.new(0,item.TextSize,0.5,0)
						newDivider.Line.Size = UDim2.new(1,-item.TextSize,0,1)
						newDivider.DividerName.TextColor3 = self.Theme.TextColor
						newDivider.DividerName.Text = item.Text
						newDivider.DividerName.Visible = true
					end
					newDivider.Visible = true
					map[item] = newDivider
					newDivider.Parent = contextList
				else
					local newEntry = entryFrame:Clone()
					newEntry.BackgroundColor3 = self.Theme.HighlightColor
					newEntry.EntryName.TextColor3 = self.Theme.TextColor
					newEntry.EntryName.Text = item.Name
					newEntry.Shortcut.Text = item.Shortcut
					if item.Disabled then
						newEntry.EntryName.TextColor3 = Color3.new(150/255,150/255,150/255)
						newEntry.Shortcut.TextColor3 = Color3.new(150/255,150/255,150/255)
					end

					if self.Iconless then
						newEntry.EntryName.Position = UDim2.new(0,2,0,0)
						newEntry.EntryName.Size = UDim2.new(1,-4,0,20)
						newEntry.Icon.Visible = false
					else			
						local iconIndex
						if item.Disabled and item.DisabledIcon then
							iconIndex = item.DisabledIcon
						elseif item.Icon then
							iconIndex =  item.Icon
						end
						
						-- Explorer.MiscIcons:DisplayExplorerIcons(newEntry.Icon, iconIndex)
						if item.IconMap then
							if type(iconIndex) == "number" then
								item.IconMap:Display(newEntry.Icon, iconIndex)
							elseif type(iconIndex) == "string" then
								item.IconMap:DisplayByKey(newEntry.Icon, iconIndex)
							end
						elseif type(iconIndex) == "string" then
							newEntry.Icon.Image = iconIndex
						end
					end

					if not item.Disabled then
						if item.OnClick then
							newEntry.MouseButton1Click:Connect(function()
								item.OnClick(item.Name)
								if not item.NoHide then
									self:Hide()
								end
							end)
						end

						if item.OnRightClick then
							newEntry.MouseButton2Click:Connect(function()
								item.OnRightClick(item.Name)
								if not item.NoHide then
									self:Hide()
								end
							end)
						end
					end

					newEntry.InputBegan:Connect(function(input)
						if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
							newEntry.BackgroundTransparency = 0
						end
					end)

					newEntry.InputEnded:Connect(function(input)
						if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
							newEntry.BackgroundTransparency = 1
						end
					end)

					newEntry.Visible = true
					map[item] = newEntry
					newEntry.Parent = contextList
				end
			end
			self.Updated = true
		end

		funcs.Show = function(self,x,y)
			local elems = self.GuiElems
			elems.SearchFrame.Visible = self.SearchEnabled
			elems.List.Position = UDim2.new(0,2,0,2 + (self.SearchEnabled and 24 or 0))
			elems.List.Size = UDim2.new(1,-4,1,-4 - (self.SearchEnabled and 24 or 0))
			if self.SearchEnabled and self.ClearSearchOnShow then elems.SearchBar.Text = "" end
			self.GuiElems.List.CanvasPosition = Vector2.new(0,0)

			if not self.Updated then
				self:Refresh()
			end

			-- Vars
			local reverseY = false
			local x,y = x or mouse.X, y or mouse.Y
			local maxX,maxY = mouse.ViewSizeX,mouse.ViewSizeY

			-- Position and show
			if x + self.Width > maxX then
				x = self.ReverseX and x - self.Width or maxX - self.Width
			end
			elems.Main.Position = UDim2.new(0,x,0,y)
			elems.Main.Size = UDim2.new(0,self.Width,0,0)
			self.Gui.DisplayOrder = Main.DisplayOrders.Menu
			Lib.ShowGui(self.Gui)

			-- Size adjustment
			local toSize = elems.List.UIListLayout.AbsoluteContentSize.Y + 6 -- Padding
			if self.MaxHeight and toSize > self.MaxHeight then
				elems.List.CanvasSize = UDim2.new(0,0,0,toSize-6)
				toSize = self.MaxHeight
			else
				elems.List.CanvasSize = UDim2.new(0,0,0,0)
			end
			if y + toSize > maxY then reverseY = true end

			-- Close event
			local closable
			if self.CloseEvent then self.CloseEvent:Disconnect() end
			self.CloseEvent = service.UserInputService.InputBegan:Connect(function(input)
				if not closable then return end

				if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
					if not Lib.CheckMouseInGui(elems.Main) then
						self.CloseEvent:Disconnect()
						self:Hide()
					end
				end
			end)

			-- Resize
			if reverseY then
				elems.Main.Position = UDim2.new(0,x,0,y-(self.ReverseYOffset or 0))
				local newY = y - toSize - (self.ReverseYOffset or 0)
				y = newY >= 0 and newY or 0
				elems.Main:TweenSizeAndPosition(UDim2.new(0,self.Width,0,toSize),UDim2.new(0,x,0,y),Enum.EasingDirection.Out,Enum.EasingStyle.Quart,0.2,true)
			else
				elems.Main:TweenSize(UDim2.new(0,self.Width,0,toSize),Enum.EasingDirection.Out,Enum.EasingStyle.Quart,0.2,true)
			end

			-- Close debounce
			Lib.FastWait()
			if self.SearchEnabled and self.FocusSearchOnShow then elems.SearchBar:CaptureFocus() end
			closable = true
		end

		funcs.Hide = function(self)
			self.Gui.Parent = nil
		end

		funcs.ApplyTheme = function(self,data)
			local theme = self.Theme
			theme.ContentColor = data.ContentColor or Settings.Theme.Menu
			theme.OutlineColor = data.OutlineColor or Settings.Theme.Menu
			theme.DividerColor = data.DividerColor or Settings.Theme.Outline2
			theme.TextColor = data.TextColor or Settings.Theme.Text
			theme.HighlightColor = data.HighlightColor or Settings.Theme.Main1

			self.GuiElems.Main.BackgroundColor3 = theme.OutlineColor
			self.GuiElems.Main.Container.BackgroundColor3 = theme.ContentColor
		end

		local mt = {__index = funcs}
		local function new()
			if not mouse then mouse = Main.Mouse or service.Players.LocalPlayer:GetMouse() end

			local obj = setmetatable({
				Width = 200,
				MaxHeight = nil,
				Iconless = false,
				SearchEnabled = false,
				ClearSearchOnShow = true,
				FocusSearchOnShow = true,
				Updated = false,
				QueuedDivider = false,
				QueuedDividerText = "",
				Items = {},
				Registered = {},
				GuiElems = {},
				Theme = {}
			},mt)
			obj.Gui = createGui(obj)
			obj:ApplyTheme({})
			return obj
		end

		return {new = new}
	end)()

	Lib.CodeFrame = (function()
		local funcs = {}

		local typeMap = {
			[1] = "String",
			[2] = "String",
			[3] = "String",
			[4] = "Comment",
			[5] = "Operator",
			[6] = "Number",
			[7] = "Keyword",
			[8] = "BuiltIn",
			[9] = "LocalMethod",
			[10] = "LocalProperty",
			[11] = "Nil",
			[12] = "Bool",
			[13] = "Function",
			[14] = "Local",
			[15] = "Self",
			[16] = "FunctionName",
			[17] = "Bracket"
		}

		local specialKeywordsTypes = {
			["nil"] = 11,
			["true"] = 12,
			["false"] = 12,
			["function"] = 13,
			["local"] = 14,
			["self"] = 15
		}

		local keywords = {
			["and"] = true,
			["break"] = true, 
			["do"] = true,
			["else"] = true,
			["elseif"] = true,
			["end"] = true,
			["false"] = true,
			["for"] = true,
			["function"] = true,
			["if"] = true,
			["in"] = true,
			["local"] = true,
			["nil"] = true,
			["not"] = true,
			["or"] = true,
			["repeat"] = true,
			["return"] = true,
			["then"] = true,
			["true"] = true,
			["until"] = true,
			["while"] = true,
			["plugin"] = true
		}

		local builtIns = {
			["delay"] = true,
			["elapsedTime"] = true,
			["require"] = true,
			["spawn"] = true,
			["tick"] = true,
			["time"] = true,
			["typeof"] = true,
			["UserSettings"] = true,
			["wait"] = true,
			["warn"] = true,
			["game"] = true,
			["shared"] = true,
			["script"] = true,
			["workspace"] = true,
			["assert"] = true,
			["collectgarbage"] = true,
			["error"] = true,
			["getfenv"] = true,
			["getmetatable"] = true,
			["ipairs"] = true,
			["loadstring"] = true,
			["newproxy"] = true,
			["next"] = true,
			["pairs"] = true,
			["pcall"] = true,
			["print"] = true,
			["rawequal"] = true,
			["rawget"] = true,
			["rawset"] = true,
			["select"] = true,
			["setfenv"] = true,
			["setmetatable"] = true,
			["tonumber"] = true,
			["tostring"] = true,
			["type"] = true,
			["unpack"] = true,
			["xpcall"] = true,
			["_G"] = true,
			["_VERSION"] = true,
			["coroutine"] = true,
			["debug"] = true,
			["math"] = true,
			["os"] = true,
			["string"] = true,
			["table"] = true,
			["bit32"] = true,
			["utf8"] = true,
			["Axes"] = true,
			["BrickColor"] = true,
			["CFrame"] = true,
			["Color3"] = true,
			["ColorSequence"] = true,
			["ColorSequenceKeypoint"] = true,
			["DockWidgetPluginGuiInfo"] = true,
			["Enum"] = true,
			["Faces"] = true,
			["Instance"] = true,
			["NumberRange"] = true,
			["NumberSequence"] = true,
			["NumberSequenceKeypoint"] = true,
			["PathWaypoint"] = true,
			["PhysicalProperties"] = true,
			["Random"] = true,
			["Ray"] = true,
			["Rect"] = true,
			["Region3"] = true,
			["Region3int16"] = true,
			["TweenInfo"] = true,
			["UDim"] = true,
			["UDim2"] = true,
			["Vector2"] = true,
			["Vector2int16"] = true,
			["Vector3"] = true,
			["Vector3int16"] = true,

			["getgenv"] = true,
			["getrenv"] = true,
			["getsenv"] = true,
			["getgc"] = true,
			["getreg"] = true,
			["filtergc"] = true,
			["saveinstave"] = true,
			["decompile"] = true,
			["syn"] = true,
			["getupvalue"] = true,
			["getupvalues"] = true,
			["setupvalue"] = true,
			["getstack"] = true,
			["setstack"] = true,
			["getconstants"] = true,
			["getconstant"] = true,
			["setconstant"] = true,
			["getproto"] = true,
			["getprotos"] = true,
			["checkcaller"] = true,
			["clonefunction"] = true,
			["cloneref"] = true,
			["getfunctionhash"] = true,
			["gethwid"] = true,
			["hookfunction"] = true,
			["hookmetamethod"] = true,
			["iscclosure"] = true,
			["islclosure"] = true,
			["newcclosure"] = true,
			["isexecutorclosure"] = true,
			["restorefunction"] = true,
			["crypt"] = true,
			["Drawing"] = true,

		}

		local builtInInited = false

		local richReplace = {
			["'"] = "&apos;",
			["\""] = "&quot;",
			["<"] = "&lt;",
			[">"] = "&gt;",
			["&"] = "&amp;"
		}

		local tabSub = "\205"
		local tabReplacement = (" %s%s "):format(tabSub,tabSub)

		local tabJumps = {
			[("[^%s] %s"):format(tabSub,tabSub)] = 0,
			[(" %s%s"):format(tabSub,tabSub)] = -1,
			[("%s%s "):format(tabSub,tabSub)] = 2,
			[("%s [^%s]"):format(tabSub,tabSub)] = 1,
		}

		local tweenService = service.TweenService
		local lineTweens = {}

		local function initBuiltIn()
			local env = getfenv()
			local type = type
			local tostring = tostring
			for name,_ in next,builtIns do
				local envVal = env[name]
				if type(envVal) == "table" then
					local items = {}
					for i,v in next,envVal do
						items[i] = true
					end
					builtIns[name] = items
				end
			end

			local enumEntries = {}
			local enums = Enum:GetEnums()
			for i = 1,#enums do
				enumEntries[tostring(enums[i])] = true
			end
			builtIns["Enum"] = enumEntries

			builtInInited = true
		end

		local function setupEditBox(obj)
			local editBox = obj.GuiElems.EditBox

			editBox.Focused:Connect(function()
				obj:ConnectEditBoxEvent()
				obj.Editing = true
			end)

			editBox.FocusLost:Connect(function()
				obj:DisconnectEditBoxEvent()
				obj.Editing = false
			end)

			editBox:GetPropertyChangedSignal("Text"):Connect(function()
				local text = editBox.Text
				if #text == 0 or obj.EditBoxCopying then return end
				editBox.Text = ""
				obj:AppendText(text)
			end)
		end

		local function setupMouseSelection(obj)
			local mouse = plr:GetMouse()
			local codeFrame = obj.GuiElems.LinesFrame
			local lines = obj.Lines

			codeFrame.InputBegan:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
					local fontSizeX,fontSizeY = math.ceil(obj.FontSize/2),obj.FontSize

					local relX = mouse.X - codeFrame.AbsolutePosition.X
					local relY = mouse.Y - codeFrame.AbsolutePosition.Y
					local selX = math.round(relX / fontSizeX) + obj.ViewX
					local selY = math.floor(relY / fontSizeY) + obj.ViewY
					local releaseEvent,mouseEvent,scrollEvent
					local scrollPowerV,scrollPowerH = 0,0
					selY = math.min(#lines-1,selY)
					local relativeLine = lines[selY+1] or ""
					selX = math.min(#relativeLine, selX + obj:TabAdjust(selX,selY))

					obj.SelectionRange = {{-1,-1},{-1,-1}}
					obj:MoveCursor(selX,selY)
					obj.FloatCursorX = selX

					local function updateSelection()
						local relX = mouse.X - codeFrame.AbsolutePosition.X
						local relY = mouse.Y - codeFrame.AbsolutePosition.Y
						local sel2X = math.max(0,math.round(relX / fontSizeX) + obj.ViewX)
						local sel2Y = math.max(0,math.floor(relY / fontSizeY) + obj.ViewY)

						sel2Y = math.min(#lines-1,sel2Y)
						local relativeLine = lines[sel2Y+1] or ""
						sel2X = math.min(#relativeLine, sel2X + obj:TabAdjust(sel2X,sel2Y))

						if sel2Y < selY or (sel2Y == selY and sel2X < selX) then
							obj.SelectionRange = {{sel2X,sel2Y},{selX,selY}}
						else						
							obj.SelectionRange = {{selX,selY},{sel2X,sel2Y}}
						end

						obj:MoveCursor(sel2X,sel2Y)
						obj.FloatCursorX = sel2X
						obj:Refresh()
					end

					releaseEvent = service.UserInputService.InputEnded:Connect(function(input)
						if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
							releaseEvent:Disconnect()
							mouseEvent:Disconnect()
							scrollEvent:Disconnect()
							obj:SetCopyableSelection()
							--updateSelection()
						end
					end)

					mouseEvent = service.UserInputService.InputChanged:Connect(function(input)
						if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
							local upDelta = mouse.Y - codeFrame.AbsolutePosition.Y
							local downDelta = mouse.Y - codeFrame.AbsolutePosition.Y - codeFrame.AbsoluteSize.Y
							local leftDelta = mouse.X - codeFrame.AbsolutePosition.X
							local rightDelta = mouse.X - codeFrame.AbsolutePosition.X - codeFrame.AbsoluteSize.X
							scrollPowerV = 0
							scrollPowerH = 0
							if downDelta > 0 then
								scrollPowerV = math.floor(downDelta*0.05) + 1
							elseif upDelta < 0 then
								scrollPowerV = math.ceil(upDelta*0.05) - 1
							end
							if rightDelta > 0 then
								scrollPowerH = math.floor(rightDelta*0.05) + 1
							elseif leftDelta < 0 then
								scrollPowerH = math.ceil(leftDelta*0.05) - 1
							end
							updateSelection()
						end
					end)

					scrollEvent = game:GetService("RunService").RenderStepped:Connect(function()
						if scrollPowerV ~= 0 or scrollPowerH ~= 0 then
							obj:ScrollDelta(scrollPowerH,scrollPowerV)
							updateSelection()
						end
					end)

					obj:Refresh()
				end
			end)
		end

		local function makeFrame(obj)
			local frame = create({
				{1,"Frame",{BackgroundColor3=Color3.new(0.15686275064945,0.15686275064945,0.15686275064945),BorderSizePixel = 0,Position=UDim2.new(0.5,-300,0.5,-200),Size=UDim2.new(0,600,0,400),}},
			})

			if Settings.Window.Transparency and Settings.Window.Transparency > 0 then
				frame.BackgroundTransparency = 0.5
			end

			local elems = {}

			local linesFrame = Instance.new("Frame")
			linesFrame.Name = "Lines"
			linesFrame.BackgroundTransparency = 1
			linesFrame.Size = UDim2.new(1,0,1,0)
			linesFrame.ClipsDescendants = true
			linesFrame.Parent = frame

			local lineNumbersLabel = Instance.new("TextLabel")
			lineNumbersLabel.Name = "LineNumbers"
			lineNumbersLabel.BackgroundTransparency = 1
			lineNumbersLabel.Font = Enum.Font.Code
			lineNumbersLabel.TextXAlignment = Enum.TextXAlignment.Right
			lineNumbersLabel.TextYAlignment = Enum.TextYAlignment.Top
			lineNumbersLabel.ClipsDescendants = true
			lineNumbersLabel.RichText = true
			lineNumbersLabel.Parent = frame

			local cursor = Instance.new("Frame")
			cursor.Name = "Cursor"
			cursor.BackgroundColor3 = Color3.fromRGB(220,220,220)
			cursor.BorderSizePixel = 0
			cursor.Parent = frame

			local editBox = Instance.new("TextBox")
			editBox.Name = "EditBox"
			editBox.MultiLine = true
			editBox.Visible = false
			editBox.Parent = frame

			lineTweens.Invis = tweenService:Create(cursor,TweenInfo.new(0.4,Enum.EasingStyle.Quart,Enum.EasingDirection.Out),{BackgroundTransparency = 1})
			lineTweens.Vis = tweenService:Create(cursor,TweenInfo.new(0.2,Enum.EasingStyle.Quart,Enum.EasingDirection.Out),{BackgroundTransparency = 0})

			elems.LinesFrame = linesFrame
			elems.LineNumbersLabel = lineNumbersLabel
			elems.Cursor = cursor
			elems.EditBox = editBox
			elems.ScrollCorner = create({{1,"Frame",{BackgroundColor3=Color3.new(0.15686275064945,0.15686275064945,0.15686275064945),BorderSizePixel=0,Name="ScrollCorner",Position=UDim2.new(1,-16,1,-16),Size=UDim2.new(0,16,0,16),Visible=false,}}})

			elems.ScrollCorner.Parent = frame
			linesFrame.InputBegan:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
					obj:SetEditing(true,input)
				end
			end)

			obj.Frame = frame
			obj.Gui = frame
			obj.GuiElems = elems
			setupEditBox(obj)
			setupMouseSelection(obj)

			return frame
		end

		funcs.GetSelectionText = function(self)
			if not self:IsValidRange() then return "" end

			local selectionRange = self.SelectionRange
			local selX,selY = selectionRange[1][1], selectionRange[1][2]
			local sel2X,sel2Y = selectionRange[2][1], selectionRange[2][2]
			local deltaLines = sel2Y-selY
			local lines = self.Lines

			if not lines[selY+1] or not lines[sel2Y+1] then return "" end

			if deltaLines == 0 then
				return self:ConvertText(lines[selY+1]:sub(selX+1,sel2X), false)
			end

			local leftSub = lines[selY+1]:sub(selX+1)
			local rightSub = lines[sel2Y+1]:sub(1,sel2X)

			local result = leftSub.."\n" 
			for i = selY+1,sel2Y-1 do
				result = result..lines[i+1].."\n"
			end
			result = result..rightSub

			return self:ConvertText(result,false)
		end

		funcs.SetCopyableSelection = function(self)
			local text = self:GetSelectionText()
			local editBox = self.GuiElems.EditBox

			self.EditBoxCopying = true
			editBox.Text = text
			editBox.SelectionStart = 1
			editBox.CursorPosition = #editBox.Text + 1
			self.EditBoxCopying = false
		end

		funcs.ConnectEditBoxEvent = function(self)
			if self.EditBoxEvent then
				self.EditBoxEvent:Disconnect()
			end

			self.EditBoxEvent = service.UserInputService.InputBegan:Connect(function(input)
				if input.UserInputType ~= Enum.UserInputType.Keyboard then return end

				local keycodes = Enum.KeyCode
				local keycode = input.KeyCode

				local function setupMove(key,func)
					local endCon,finished
					endCon = service.UserInputService.InputEnded:Connect(function(input)
						if input.KeyCode ~= key then return end
						endCon:Disconnect()
						finished = true
					end)
					func()
					Lib.FastWait(0.5)
					while not finished do func() Lib.FastWait(0.03) end
				end

				if keycode == keycodes.Down then
					setupMove(keycodes.Down,function()
						self.CursorX = self.FloatCursorX
						self.CursorY = self.CursorY + 1
						self:UpdateCursor()
						self:JumpToCursor()
					end)
				elseif keycode == keycodes.Up then
					setupMove(keycodes.Up,function()
						self.CursorX = self.FloatCursorX
						self.CursorY = self.CursorY - 1
						self:UpdateCursor()
						self:JumpToCursor()
					end)
				elseif keycode == keycodes.Left then
					setupMove(keycodes.Left,function()
						local line = self.Lines[self.CursorY+1] or ""
						self.CursorX = self.CursorX - 1 - (line:sub(self.CursorX-3,self.CursorX) == tabReplacement and 3 or 0)
						if self.CursorX < 0 then
							self.CursorY = self.CursorY - 1
							local line2 = self.Lines[self.CursorY+1] or ""
							self.CursorX = #line2
						end
						self.FloatCursorX = self.CursorX
						self:UpdateCursor()
						self:JumpToCursor()
					end)
				elseif keycode == keycodes.Right then
					setupMove(keycodes.Right,function()
						local line = self.Lines[self.CursorY+1] or ""
						self.CursorX = self.CursorX + 1 + (line:sub(self.CursorX+1,self.CursorX+4) == tabReplacement and 3 or 0)
						if self.CursorX > #line then
							self.CursorY = self.CursorY + 1
							self.CursorX = 0
						end
						self.FloatCursorX = self.CursorX
						self:UpdateCursor()
						self:JumpToCursor()
					end)
				elseif keycode == keycodes.Backspace then
					setupMove(keycodes.Backspace,function()
						local startRange,endRange
						if self:IsValidRange() then
							startRange = self.SelectionRange[1]
							endRange = self.SelectionRange[2]
						else
							endRange = {self.CursorX,self.CursorY}
						end

						if not startRange then
							local line = self.Lines[self.CursorY+1] or ""
							self.CursorX = self.CursorX - 1 - (line:sub(self.CursorX-3,self.CursorX) == tabReplacement and 3 or 0)
							if self.CursorX < 0 then
								self.CursorY = self.CursorY - 1
								local line2 = self.Lines[self.CursorY+1] or ""
								self.CursorX = #line2
							end
							self.FloatCursorX = self.CursorX
							self:UpdateCursor()

							startRange = startRange or {self.CursorX,self.CursorY}
						end

						self:DeleteRange({startRange,endRange},false,true)
						self:ResetSelection(true)
						self:JumpToCursor()
					end)
				elseif keycode == keycodes.Delete then
					setupMove(keycodes.Delete,function()
						local startRange,endRange
						if self:IsValidRange() then
							startRange = self.SelectionRange[1]
							endRange = self.SelectionRange[2]
						else
							startRange = {self.CursorX,self.CursorY}
						end

						if not endRange then
							local line = self.Lines[self.CursorY+1] or ""
							local endCursorX = self.CursorX + 1 + (line:sub(self.CursorX+1,self.CursorX+4) == tabReplacement and 3 or 0)
							local endCursorY = self.CursorY
							if endCursorX > #line then
								endCursorY = endCursorY + 1
								endCursorX = 0
							end
							self:UpdateCursor()

							endRange = endRange or {endCursorX,endCursorY}
						end

						self:DeleteRange({startRange,endRange},false,true)
						self:ResetSelection(true)
						self:JumpToCursor()
					end)
				elseif service.UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then
					if keycode == keycodes.A then
						self.SelectionRange = {{0,0},{#self.Lines[#self.Lines],#self.Lines-1}}
						self:SetCopyableSelection()
						self:Refresh()
					end
				end
			end)
		end

		funcs.DisconnectEditBoxEvent = function(self)
			if self.EditBoxEvent then
				self.EditBoxEvent:Disconnect()
			end
		end

		funcs.ResetSelection = function(self,norefresh)
			self.SelectionRange = {{-1,-1},{-1,-1}}
			if not norefresh then self:Refresh() end
		end

		funcs.IsValidRange = function(self,range)
			local selectionRange = range or self.SelectionRange
			local selX,selY = selectionRange[1][1], selectionRange[1][2]
			local sel2X,sel2Y = selectionRange[2][1], selectionRange[2][2]

			if selX == -1 or (selX == sel2X and selY == sel2Y) then return false end

			return true
		end

		funcs.DeleteRange = function(self,range,noprocess,updatemouse)
			range = range or self.SelectionRange
			if not self:IsValidRange(range) then return end

			local lines = self.Lines
			local selX,selY = range[1][1], range[1][2]
			local sel2X,sel2Y = range[2][1], range[2][2]
			local deltaLines = sel2Y-selY

			if not lines[selY+1] or not lines[sel2Y+1] then return end

			local leftSub = lines[selY+1]:sub(1,selX)
			local rightSub = lines[sel2Y+1]:sub(sel2X+1)
			lines[selY+1] = leftSub..rightSub

			local remove = table.remove
			for i = 1,deltaLines do
				remove(lines,selY+2)
			end

			if range == self.SelectionRange then self.SelectionRange = {{-1,-1},{-1,-1}} end
			if updatemouse then
				self.CursorX = selX
				self.CursorY = selY
				self:UpdateCursor()
			end

			if not noprocess then
				self:ProcessTextChange()
			end
		end

		funcs.AppendText = function(self,text)
			self:DeleteRange(nil,true,true)
			local lines,cursorX,cursorY = self.Lines,self.CursorX,self.CursorY
			local line = lines[cursorY+1]
			local before = line:sub(1,cursorX)
			local after = line:sub(cursorX+1)

			text = text:gsub("\r\n","\n")
			text = self:ConvertText(text,true) -- Tab Convert

			local textLines = text:split("\n")
			local insert = table.insert

			for i = 1,#textLines do
				local linePos = cursorY+i
				if i > 1 then insert(lines,linePos,"") end

				local textLine = textLines[i]
				local newBefore = (i == 1 and before or "")
				local newAfter = (i == #textLines and after or "")

				lines[linePos] = newBefore..textLine..newAfter
			end

			if #textLines > 1 then cursorX = 0 end

			self:ProcessTextChange()
			self.CursorX = cursorX + #textLines[#textLines]
			self.CursorY = cursorY + #textLines-1
			self:UpdateCursor()
		end

		funcs.ScrollDelta = function(self,x,y)
			self.ScrollV:ScrollTo(self.ScrollV.Index + y)
			self.ScrollH:ScrollTo(self.ScrollH.Index + x)
		end

		-- x and y starts at 0
		funcs.TabAdjust = function(self,x,y)
			local lines = self.Lines
			local line = lines[y+1]
			x=x+1

			if line then
				local left = line:sub(x-1,x-1)
				local middle = line:sub(x,x)
				local right = line:sub(x+1,x+1)
				local selRange = (#left > 0 and left or " ") .. (#middle > 0 and middle or " ") .. (#right > 0 and right or " ")

				for i,v in pairs(tabJumps) do
					if selRange:find(i) then
						return v
					end
				end
			end
			return 0
		end

		funcs.SetEditing = function(self,on,input)			
			self:UpdateCursor(input)

			if on then
				if self.Editable then
					self.GuiElems.EditBox.Text = ""
					self.GuiElems.EditBox:CaptureFocus()
				end
			else
				self.GuiElems.EditBox:ReleaseFocus()
			end
		end

		funcs.CursorAnim = function(self,on)
			local cursor = self.GuiElems.Cursor
			local animTime = tick()
			self.LastAnimTime = animTime

			if not on then return end

			lineTweens.Invis:Cancel()
			lineTweens.Vis:Cancel()
			cursor.BackgroundTransparency = 0

			coroutine.wrap(function()
				while self.Editable do
					Lib.FastWait(0.5)
					if self.LastAnimTime ~= animTime then return end
					lineTweens.Invis:Play()
					Lib.FastWait(0.4)
					if self.LastAnimTime ~= animTime then return end
					lineTweens.Vis:Play()
					Lib.FastWait(0.2)
				end
			end)()
		end

		funcs.MoveCursor = function(self,x,y)
			self.CursorX = x
			self.CursorY = y
			self:UpdateCursor()
			self:JumpToCursor()
		end

		funcs.JumpToCursor = function(self)
			self:Refresh()
		end

		funcs.UpdateCursor = function(self,input)
			local linesFrame = self.GuiElems.LinesFrame
			local cursor = self.GuiElems.Cursor			
			local hSize = math.max(0,linesFrame.AbsoluteSize.X)
			local vSize = math.max(0,linesFrame.AbsoluteSize.Y)
			local maxLines = math.ceil(vSize / self.FontSize)
			local maxCols = math.ceil(hSize / math.ceil(self.FontSize/2))
			local viewX,viewY = self.ViewX,self.ViewY
			local totalLinesStr = tostring(#self.Lines)
			local fontWidth = math.ceil(self.FontSize / 2)
			local linesOffset = #totalLinesStr*fontWidth + 4*fontWidth

			if input then
				local linesFrame = self.GuiElems.LinesFrame
				local frameX,frameY = linesFrame.AbsolutePosition.X,linesFrame.AbsolutePosition.Y
				local mouseX,mouseY = input.Position.X,input.Position.Y
				local fontSizeX,fontSizeY = math.ceil(self.FontSize/2),self.FontSize

				self.CursorX = self.ViewX + math.round((mouseX - frameX) / fontSizeX)
				self.CursorY = self.ViewY + math.floor((mouseY - frameY) / fontSizeY)
			end

			local cursorX,cursorY = self.CursorX,self.CursorY

			local line = self.Lines[cursorY+1] or ""
			if cursorX > #line then cursorX = #line
			elseif cursorX < 0 then cursorX = 0 end

			if cursorY >= #self.Lines then
				cursorY = math.max(0,#self.Lines-1)
			elseif cursorY < 0 then
				cursorY = 0
			end

			cursorX = cursorX + self:TabAdjust(cursorX,cursorY)

			-- Update modified
			self.CursorX = cursorX
			self.CursorY = cursorY

			local cursorVisible = (cursorX >= viewX) and (cursorY >= viewY) and (cursorX <= viewX + maxCols) and (cursorY <= viewY + maxLines)
			if cursorVisible then
				local offX = (cursorX - viewX)
				local offY = (cursorY - viewY)
				cursor.Position = UDim2.new(0,linesOffset + offX*math.ceil(self.FontSize/2) - 1,0,offY*self.FontSize)
				cursor.Size = UDim2.new(0,1,0,self.FontSize+2)
				cursor.Visible = true
				self:CursorAnim(true)
			else
				cursor.Visible = false
			end
		end

		funcs.MapNewLines = function(self)
			local newLines = {}
			local count = 1
			local text = self.Text
			local find = string.find
			local init = 1

			local pos = find(text,"\n",init,true)
			while pos do
				newLines[count] = pos
				count = count + 1
				init = pos + 1
				pos = find(text,"\n",init,true)
			end

			self.NewLines = newLines
		end

		funcs.PreHighlight = function(self)
			local start = tick()
			local text = self.Text:gsub("\\\\","  ")
			--print("BACKSLASH SUB",tick()-start)
			local textLen = #text
			local found = {}
			local foundMap = {}
			local extras = {}
			local find = string.find
			local sub = string.sub
			self.ColoredLines = {}

			local function findAll(str,pattern,typ,raw)
				local count = #found+1
				local init = 1
				local x,y,extra = find(str,pattern,init,raw)
				while x do
					found[count] = x
					foundMap[x] = typ
					if extra then
						extras[x] = extra
					end

					count = count+1
					init = y+1
					x,y,extra = find(str,pattern,init,raw)
				end
			end
			local start = tick()
			findAll(text,'"',1,true)
			findAll(text,"'",2,true)
			findAll(text,"%[(=*)%[",3)
			findAll(text,"--",4,true)
			table.sort(found)

			local newLines = self.NewLines
			local curLine = 0
			local lineTableCount = 1
			local lineStart = 0
			local lineEnd = 0
			local lastEnding = 0
			local foundHighlights = {}

			for i = 1,#found do
				local pos = found[i]
				if pos <= lastEnding then continue end

				local ending = pos
				local typ = foundMap[pos]
				if typ == 1 then
					ending = find(text,'"',pos+1,true)
					while ending and sub(text,ending-1,ending-1) == "\\" do
						ending = find(text,'"',ending+1,true)
					end
					if not ending then ending = textLen end
				elseif typ == 2 then
					ending = find(text,"'",pos+1,true)
					while ending and sub(text,ending-1,ending-1) == "\\" do
						ending = find(text,"'",ending+1,true)
					end
					if not ending then ending = textLen end
				elseif typ == 3 then
					_,ending = find(text,"]"..extras[pos].."]",pos+1,true)
					if not ending then ending = textLen end
				elseif typ == 4 then
					local ahead = foundMap[pos+2]

					if ahead == 3 then
						_,ending = find(text,"]"..extras[pos+2].."]",pos+1,true)
						if not ending then ending = textLen end
					else
						ending = find(text,"\n",pos+1,true) or textLen
					end
				end

				while pos > lineEnd do
					curLine = curLine + 1
					--lineTableCount = 1
					lineEnd = newLines[curLine] or textLen+1
				end
				while true do
					local lineTable = foundHighlights[curLine]
					if not lineTable then lineTable = {} foundHighlights[curLine] = lineTable end
					lineTable[pos] = {typ,ending}
					--lineTableCount = lineTableCount + 1

					if ending > lineEnd then
						curLine = curLine + 1
						lineEnd = newLines[curLine] or textLen+1
					else
						break
					end
				end

				lastEnding = ending
				--if i < 200 then print(curLine) end
			end
			self.PreHighlights = foundHighlights
			--print(tick()-start)
			--print(#found,curLine)
		end

		funcs.HighlightLine = function(self,line)
			local cached = self.ColoredLines[line]
			if cached then return cached end

			local sub = string.sub
			local find = string.find
			local match = string.match
			local highlights = {}
			local preHighlights = self.PreHighlights[line] or {}
			local lineText = self.Lines[line] or ""
			local lineLen = #lineText
			local lastEnding = 0
			local currentType = 0
			local lastWord = nil
			local wordBeginsDotted = false
			local funcStatus = 0
			local lineStart = self.NewLines[line-1] or 0

			local preHighlightMap = {}
			for pos,data in next,preHighlights do
				local relativePos = pos-lineStart
				if relativePos < 1 then
					currentType = data[1]
					lastEnding = data[2] - lineStart
					--warn(pos,data[2])
				else
					preHighlightMap[relativePos] = {data[1],data[2]-lineStart}
				end
			end

			for col = 1,#lineText do
				if col <= lastEnding then highlights[col] = currentType continue end

				local pre = preHighlightMap[col]
				if pre then
					currentType = pre[1]
					lastEnding = pre[2]
					highlights[col] = currentType
					wordBeginsDotted = false
					lastWord = nil
					funcStatus = 0
				else
					local char = sub(lineText,col,col)
					if find(char,"[%a_]") then
						local word = match(lineText,"[%a%d_]+",col)
						local wordType = (keywords[word] and 7) or (builtIns[word] and 8)

						lastEnding = col+#word-1

						if wordType ~= 7 then
							if wordBeginsDotted then
								local prevBuiltIn = lastWord and builtIns[lastWord]
								wordType = (prevBuiltIn and type(prevBuiltIn) == "table" and prevBuiltIn[word] and 8) or 10
							end

							if wordType ~= 8 then
								local x,y,br = find(lineText,"^%s*([%({\"'])",lastEnding+1)
								if x then
									wordType = (funcStatus > 0 and br == "(" and 16) or 9
									funcStatus = 0
								end
							end
						else
							wordType = specialKeywordsTypes[word] or wordType
							funcStatus = (word == "function" and 1 or 0)
						end

						lastWord = word
						wordBeginsDotted = false
						if funcStatus > 0 then funcStatus = 1 end

						if wordType then
							currentType = wordType
							highlights[col] = currentType
						else
							currentType = nil
						end
					elseif find(char,"%p") then
						local isDot = (char == ".")
						local isNum = isDot and find(sub(lineText,col+1,col+1),"%d")
						highlights[col] = (isNum and 6 or 5)

						if not isNum then
							local dotStr = isDot and match(lineText,"%.%.?%.?",col)
							if dotStr and #dotStr > 1 then
								currentType = 5
								lastEnding = col+#dotStr-1
								wordBeginsDotted = false
								lastWord = nil
								funcStatus = 0
							else
								if isDot then
									if wordBeginsDotted then
										lastWord = nil
									else
										wordBeginsDotted = true
									end
								else
									wordBeginsDotted = false
									lastWord = nil
								end

								funcStatus = ((isDot or char == ":") and funcStatus == 1 and 2) or 0
							end
						end
					elseif find(char,"%d") then
						local _,endPos = find(lineText,"%x+",col)
						local endPart = sub(lineText,endPos,endPos+1)
						if (endPart == "e+" or endPart == "e-") and find(sub(lineText,endPos+2,endPos+2),"%d") then
							endPos = endPos + 1
						end
						currentType = 6
						lastEnding = endPos
						highlights[col] = 6
						wordBeginsDotted = false
						lastWord = nil
						funcStatus = 0
					else
						highlights[col] = currentType
						local _,endPos = find(lineText,"%s+",col)
						if endPos then
							lastEnding = endPos
						end
					end
				end
			end

			self.ColoredLines[line] = highlights
			return highlights
		end

		funcs.Refresh = function(self)
			local start = tick()

			local linesFrame = self.Frame.Lines
			local hSize = math.max(0,linesFrame.AbsoluteSize.X)
			local vSize = math.max(0,linesFrame.AbsoluteSize.Y)
			local maxLines = math.ceil(vSize / self.FontSize)
			local maxCols = math.ceil(hSize / math.ceil(self.FontSize/2))
			local gsub = string.gsub
			local sub = string.sub

			local viewX,viewY = self.ViewX,self.ViewY

			local lineNumberStr = ""

			for row = 1,maxLines do
				local lineFrame = self.LineFrames[row]
				if not lineFrame then
					lineFrame = Instance.new("Frame")
					lineFrame.Name = "Line"
					lineFrame.Position = UDim2.new(0,0,0,(row-1)*self.FontSize)
					lineFrame.Size = UDim2.new(1,0,0,self.FontSize)
					lineFrame.BorderSizePixel = 0
					lineFrame.BackgroundTransparency = 1

					local selectionHighlight = Instance.new("Frame")
					selectionHighlight.Name = "SelectionHighlight"
					selectionHighlight.BorderSizePixel = 0
					selectionHighlight.BackgroundColor3 = Settings.Theme.Syntax.SelectionBack
					selectionHighlight.Parent = lineFrame

					local label = Instance.new("TextLabel")
					label.Name = "Label"
					label.BackgroundTransparency = 1
					label.Font = Enum.Font.Code
					label.TextSize = self.FontSize
					label.Size = UDim2.new(1,0,0,self.FontSize)
					label.RichText = true
					label.TextXAlignment = Enum.TextXAlignment.Left
					label.TextColor3 = self.Colors.Text
					label.ZIndex = 2
					label.Parent = lineFrame

					lineFrame.Parent = linesFrame
					self.LineFrames[row] = lineFrame
				end

				local relaY = viewY + row
				local lineText = self.Lines[relaY] or ""
				local resText = ""
				local highlights = self:HighlightLine(relaY)
				local colStart = viewX + 1

				local richTemplates = self.RichTemplates
				local textTemplate = richTemplates.Text
				local selectionTemplate = richTemplates.Selection
				local curType = highlights[colStart]
				local curTemplate = richTemplates[typeMap[curType]] or textTemplate

				-- Selection Highlight
				local selectionRange = self.SelectionRange
				local selPos1 = selectionRange[1]
				local selPos2 = selectionRange[2]
				local selRow,selColumn = selPos1[2],selPos1[1]
				local sel2Row,sel2Column = selPos2[2],selPos2[1]
				local selRelaX,selRelaY = viewX,relaY-1

				if selRelaY >= selPos1[2] and selRelaY <= selPos2[2] then
					local fontSizeX = math.ceil(self.FontSize/2)
					local posX = (selRelaY == selPos1[2] and selPos1[1] or 0) - viewX
					local sizeX = (selRelaY == selPos2[2] and selPos2[1]-posX-viewX or maxCols+viewX)

					lineFrame.SelectionHighlight.Position = UDim2.new(0,posX*fontSizeX,0,0)
					lineFrame.SelectionHighlight.Size = UDim2.new(0,sizeX*fontSizeX,1,0)
					lineFrame.SelectionHighlight.Visible = true
				else
					lineFrame.SelectionHighlight.Visible = false
				end

				-- Selection Text Color for first char
				local inSelection = selRelaY >= selRow and selRelaY <= sel2Row and (selRelaY == selRow and viewX >= selColumn or selRelaY ~= selRow) and (selRelaY == sel2Row and viewX < sel2Column or selRelaY ~= sel2Row)
				if inSelection then
					curType = -999
					curTemplate = selectionTemplate
				end

				for col = 2,maxCols do
					local relaX = viewX + col
					local selRelaX = relaX-1
					local posType = highlights[relaX]

					-- Selection Text Color
					local inSelection = selRelaY >= selRow and selRelaY <= sel2Row and (selRelaY == selRow and selRelaX >= selColumn or selRelaY ~= selRow) and (selRelaY == sel2Row and selRelaX < sel2Column or selRelaY ~= sel2Row)
					if inSelection then
						posType = -999
					end

					if posType ~= curType then
						local template = (inSelection and selectionTemplate) or richTemplates[typeMap[posType]] or textTemplate

						if template ~= curTemplate then
							local nextText = gsub(sub(lineText,colStart,relaX-1),"['\"<>&]",richReplace)
							resText = resText .. (curTemplate ~= textTemplate and (curTemplate .. nextText .. "</font>") or nextText)
							colStart = relaX
							curTemplate = template
						end
						curType = posType
					end
				end

				local lastText = gsub(sub(lineText,colStart,viewX+maxCols),"['\"<>&]",richReplace)
				--warn("SUB",colStart,viewX+maxCols-1)
				if #lastText > 0 then
					resText = resText .. (curTemplate ~= textTemplate and (curTemplate .. lastText .. "</font>") or lastText)
				end

				if self.Lines[relaY] then

					-- REMOVED LINE HIGHLIGHT DUE TO BUG OFFSET
					lineNumberStr = lineNumberStr .. (relaY == self.CursorY and ("<b>"..relaY.."</b>\n") or relaY .. "\n")
					--lineNumberStr = lineNumberStr .. (relaY == self.CursorY and (relaY.."\n") or relaY .. "\n")
				end

				lineFrame.Label.Text = resText
			end

			for i = maxLines+1,#self.LineFrames do
				self.LineFrames[i]:Destroy()
				self.LineFrames[i] = nil
			end

			self.Frame.LineNumbers.Text = lineNumberStr
			self:UpdateCursor()

			--print("REFRESH TIME",tick()-start)
		end

		funcs.UpdateView = function(self)
			local totalLinesStr = tostring(#self.Lines)
			local fontWidth = math.ceil(self.FontSize / 2)
			local linesOffset = #totalLinesStr*fontWidth + 4*fontWidth

			local linesFrame = self.Frame.Lines
			local hSize = linesFrame.AbsoluteSize.X
			local vSize = linesFrame.AbsoluteSize.Y
			local maxLines = math.ceil(vSize / self.FontSize)
			local totalWidth = self.MaxTextCols*fontWidth
			local scrollV = self.ScrollV
			local scrollH = self.ScrollH

			scrollV.VisibleSpace = maxLines
			scrollV.TotalSpace = #self.Lines + 1
			scrollH.VisibleSpace = math.ceil(hSize/fontWidth)
			scrollH.TotalSpace = self.MaxTextCols + 1

			scrollV.Gui.Visible = #self.Lines + 1 > maxLines
			scrollH.Gui.Visible = totalWidth > hSize

			local oldOffsets = self.FrameOffsets
			self.FrameOffsets = Vector2.new(scrollV.Gui.Visible and -16 or 0, scrollH.Gui.Visible and -16 or 0)
			if oldOffsets ~= self.FrameOffsets then
				self:UpdateView()
			else
				scrollV:ScrollTo(self.ViewY,true)
				scrollH:ScrollTo(self.ViewX,true)

				if scrollV.Gui.Visible and scrollH.Gui.Visible then
					scrollV.Gui.Size = UDim2.new(0,16,1,-16)
					scrollH.Gui.Size = UDim2.new(1,-16,0,16)
					self.GuiElems.ScrollCorner.Visible = true
				else
					scrollV.Gui.Size = UDim2.new(0,16,1,0)
					scrollH.Gui.Size = UDim2.new(1,0,0,16)
					self.GuiElems.ScrollCorner.Visible = false
				end

				self.ViewY = scrollV.Index
				self.ViewX = scrollH.Index
				self.Frame.Lines.Position = UDim2.new(0,linesOffset,0,0)
				self.Frame.Lines.Size = UDim2.new(1,-linesOffset+oldOffsets.X,1,oldOffsets.Y)
				self.Frame.LineNumbers.Position = UDim2.new(0,fontWidth,0,0)
				self.Frame.LineNumbers.Size = UDim2.new(0,#totalLinesStr*fontWidth,1,oldOffsets.Y)
				self.Frame.LineNumbers.TextSize = self.FontSize
			end
		end

		funcs.ProcessTextChange = function(self)
			local maxCols = 0
			local lines = self.Lines

			for i = 1,#lines do
				local lineLen = #lines[i]
				if lineLen > maxCols then
					maxCols = lineLen
				end
			end

			self.MaxTextCols = maxCols
			self:UpdateView()	
			self.Text = table.concat(self.Lines,"\n")
			self:MapNewLines()
			self:PreHighlight()
			self:Refresh()
			--self.TextChanged:Fire()
		end

		funcs.ConvertText = function(self,text,toEditor)
			if toEditor then
				--return text:gsub("\t",(" %s%s "):format(tabSub,tabSub))
				return text:gsub("\t","    ") -- Fixed unknown unicode showing when pressing TAB
			else
				return text:gsub((" %s%s "):format(tabSub,tabSub),"\t")
			end
		end

		funcs.GetText = function(self) -- TODO: better (use new tab format)
			local source = table.concat(self.Lines,"\n")
			return self:ConvertText(source,false) -- Tab Convert
		end

		funcs.SetText = function(self,txt)
			txt = self:ConvertText(txt,true) -- Tab Convert
			local lines = self.Lines
			table.clear(lines)
			local count = 1

			for line in txt:gmatch("([^\n\r]*)[\n\r]?") do
				local len = #line
				lines[count] = line
				count = count + 1
			end

			self:ProcessTextChange()
		end

		funcs.MakeRichTemplates = function(self)
			local floor = math.floor
			local templates = {}

			for name,color in pairs(self.Colors) do
				templates[name] = ('<font color="rgb(%s,%s,%s)">'):format(floor(color.r*255),floor(color.g*255),floor(color.b*255))
			end

			self.RichTemplates = templates
		end

		funcs.ApplyTheme = function(self)
			local colors = Settings.Theme.Syntax
			self.Colors = colors
			self.Frame.LineNumbers.TextColor3 = colors.Text
			self.Frame.BackgroundColor3 = colors.Background
		end

		local mt = {__index = funcs}

		local function new()
			if not builtInInited then initBuiltIn() end

			local scrollV = Lib.ScrollBar.new()
			local scrollH = Lib.ScrollBar.new(true)
			scrollH.Gui.Position = UDim2.new(0,0,1,-16)
			local obj = setmetatable({
				FontSize = 16,
				ViewX = 0,
				ViewY = 0,
				Colors = Settings.Theme.Syntax,
				ColoredLines = {},
				Lines = {""},
				LineFrames = {},
				Editable = true,
				Editing = false,
				CursorX = 0,
				CursorY = 0,
				FloatCursorX = 0,
				Text = "",
				PreHighlights = {},
				SelectionRange = {{-1,-1},{-1,-1}},
				NewLines = {},
				FrameOffsets = Vector2.new(0,0),
				MaxTextCols = 0,
				ScrollV = scrollV,
				ScrollH = scrollH
			},mt)

			scrollV.WheelIncrement = 3
			scrollH.Increment = 2
			scrollH.WheelIncrement = 7

			scrollV.Scrolled:Connect(function()
				obj.ViewY = scrollV.Index
				obj:Refresh()
			end)

			scrollH.Scrolled:Connect(function()
				obj.ViewX = scrollH.Index
				obj:Refresh()
			end)

			makeFrame(obj)
			obj:MakeRichTemplates()
			obj:ApplyTheme()
			scrollV:SetScrollFrame(obj.Frame.Lines)
			scrollV.Gui.Parent = obj.Frame
			scrollH.Gui.Parent = obj.Frame

			obj:UpdateView()
			obj.Frame:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
				obj:UpdateView()
				obj:Refresh()
			end)

			return obj
		end

		return {new = new}
	end)()

	Lib.Checkbox = (function()
		local funcs = {}
		local c3 = Color3.fromRGB
		local v2 = Vector2.new
		local ud2s = UDim2.fromScale
		local ud2o = UDim2.fromOffset
		local ud = UDim.new
		local max = math.max
		local new = Instance.new
		local TweenSize = new("Frame").TweenSize
		local ti = TweenInfo.new
		local delay = delay

		local function ripple(object, color)
			local circle = new('Frame')
			circle.BackgroundColor3 = color
			circle.BackgroundTransparency = 0.75
			circle.BorderSizePixel = 0
			circle.AnchorPoint = v2(0.5, 0.5)
			circle.Size = ud2o()
			circle.Position = ud2s(0.5, 0.5)
			circle.Parent = object
			local rounding = new('UICorner')
			rounding.CornerRadius = ud(1)
			rounding.Parent = circle

			local abssz = object.AbsoluteSize
			local size = max(abssz.X, abssz.Y) * 5/3

			TweenSize(circle, ud2o(size, size), "Out", "Quart", 0.4)
			service.TweenService:Create(circle, ti(0.4, Enum.EasingStyle.Quart, Enum.EasingDirection.In), {BackgroundTransparency = 1}):Play()

			service.Debris:AddItem(circle, 0.4)
		end

		local function initGui(self,frame)
			local checkbox = frame or create({
				{1,"ImageButton",{BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=1,BorderSizePixel=0,Name="Checkbox",Position=UDim2.new(0,3,0,3),Size=UDim2.new(0,16,0,16),}},
				{2,"Frame",{BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=1,BorderSizePixel=0,Name="ripples",Parent={1},Size=UDim2.new(1,0,1,0),}},
				{3,"Frame",{BackgroundColor3=Color3.new(0.10196078568697,0.10196078568697,0.10196078568697),BorderSizePixel=0,Name="outline",Parent={1},Size=UDim2.new(0,16,0,16),}},
				{4,"Frame",{BackgroundColor3=Color3.new(0.14117647707462,0.14117647707462,0.14117647707462),BorderSizePixel=0,Name="filler",Parent={3},Position=UDim2.new(0,1,0,1),Size=UDim2.new(0,14,0,14),}},
				{5,"Frame",{BackgroundColor3=Color3.new(0.90196084976196,0.90196084976196,0.90196084976196),BorderSizePixel=0,Name="top",Parent={4},Size=UDim2.new(0,16,0,0),}},
				{6,"Frame",{AnchorPoint=Vector2.new(0,1),BackgroundColor3=Color3.new(0.90196084976196,0.90196084976196,0.90196084976196),BorderSizePixel=0,Name="bottom",Parent={4},Position=UDim2.new(0,0,0,14),Size=UDim2.new(0,16,0,0),}},
				{7,"Frame",{BackgroundColor3=Color3.new(0.90196084976196,0.90196084976196,0.90196084976196),BorderSizePixel=0,Name="left",Parent={4},Size=UDim2.new(0,0,0,16),}},
				{8,"Frame",{AnchorPoint=Vector2.new(1,0),BackgroundColor3=Color3.new(0.90196084976196,0.90196084976196,0.90196084976196),BorderSizePixel=0,Name="right",Parent={4},Position=UDim2.new(0,14,0,0),Size=UDim2.new(0,0,0,16),}},
				{9,"Frame",{AnchorPoint=Vector2.new(0.5,0.5),BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=1,BorderSizePixel=0,ClipsDescendants=true,Name="checkmark",Parent={4},Position=UDim2.new(0.5,0,0.5,0),Size=UDim2.new(0,0,0,20),}},
				{10,"ImageLabel",{AnchorPoint=Vector2.new(0.5,0.5),BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=1,BorderSizePixel=0,Image="rbxassetid://6234266378",Parent={9},Position=UDim2.new(0.5,0,0.5,0),ScaleType=3,Size=UDim2.new(0,15,0,11),}},
				{11,"ImageLabel",{AnchorPoint=Vector2.new(0.5,0.5),BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=1,Image="rbxassetid://6401617475",ImageColor3=Color3.new(0.20784313976765,0.69803923368454,0.98431372642517),Name="checkmark2",Parent={4},Position=UDim2.new(0.5,0,0.5,0),Size=UDim2.new(0,12,0,12),Visible=false,}},
				{12,"ImageLabel",{BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=1,Image="rbxassetid://6425281788",ImageTransparency=0.20000000298023,Name="middle",Parent={4},ScaleType=2,Size=UDim2.new(1,0,1,0),TileSize=UDim2.new(0,2,0,2),Visible=false,}},
				{13,"UICorner",{CornerRadius=UDim.new(0,2),Parent={3},}},
			})
			local outline = checkbox.outline
			local filler = outline.filler
			local checkmark = filler.checkmark
			local ripples_container = checkbox.ripples

			-- walls
			local top, bottom, left, right = filler.top, filler.bottom, filler.left, filler.right

			self.Gui = checkbox
			self.GuiElems = {
				Top = top,
				Bottom = bottom,
				Left = left,
				Right = right,
				Outline = outline,
				Filler = filler,
				Checkmark = checkmark,
				Checkmark2 = filler.checkmark2,
				Middle = filler.middle
			}
	
			-- New:
			--[[checkbox.Activated:Connect(function()
				if Lib.CheckMouseInGui(checkbox) then
					if self.Style == 0 then
						ripple(ripples_container, self.Disabled and self.Colors.Disabled or self.Colors.Primary)
					end

					if not self.Disabled then
						self:SetState(not self.Toggled,true)
					else
						self:Paint()
					end

					self.OnInput:Fire()
				end
			end)]]
			
			-- Best input compatibility:
			checkbox.MouseButton1Up:Connect(function()
				if Lib.CheckMouseInGui(checkbox) then
					if self.Style == 0 then
						ripple(ripples_container, self.Disabled and self.Colors.Disabled or self.Colors.Primary)
					end

					if not self.Disabled then
						self:SetState(not self.Toggled,true)
					else
						self:Paint()
					end

					self.OnInput:Fire()
				end
			end)

			-- Old:
			--[[checkbox.InputBegan:Connect(function(i)
				if i.UserInputType == Enum.UserInputType.MouseButton1 then
					local release
					release = service.UserInputService.InputEnded:Connect(function(input)
						if input.UserInputType == Enum.UserInputType.MouseButton1 then
							release:Disconnect()

							if Lib.CheckMouseInGui(checkbox) then
								if self.Style == 0 then
									ripple(ripples_container, self.Disabled and self.Colors.Disabled or self.Colors.Primary)
								end

								if not self.Disabled then
									self:SetState(not self.Toggled,true)
								else
									self:Paint()
								end
								
								self.OnInput:Fire()
							end
						end
					end)
				end
			end)]]

			self:Paint()
		end

		funcs.Collapse = function(self,anim)
			local guiElems = self.GuiElems
			if anim then
				TweenSize(guiElems.Top, ud2o(14, 14), "In", "Quart", 4/15, true)
				TweenSize(guiElems.Bottom, ud2o(14, 14), "In", "Quart", 4/15, true)
				TweenSize(guiElems.Left, ud2o(14, 14), "In", "Quart", 4/15, true)
				TweenSize(guiElems.Right, ud2o(14, 14), "In", "Quart", 4/15, true)
			else
				guiElems.Top.Size = ud2o(14, 14)
				guiElems.Bottom.Size = ud2o(14, 14)
				guiElems.Left.Size = ud2o(14, 14)
				guiElems.Right.Size = ud2o(14, 14)
			end
		end

		funcs.Expand = function(self,anim)
			local guiElems = self.GuiElems
			if anim then
				TweenSize(guiElems.Top, ud2o(14, 0), "InOut", "Quart", 4/15, true)
				TweenSize(guiElems.Bottom, ud2o(14, 0), "InOut", "Quart", 4/15, true)
				TweenSize(guiElems.Left, ud2o(0, 14), "InOut", "Quart", 4/15, true)
				TweenSize(guiElems.Right, ud2o(0, 14), "InOut", "Quart", 4/15, true)
			else
				guiElems.Top.Size = ud2o(14, 0)
				guiElems.Bottom.Size = ud2o(14, 0)
				guiElems.Left.Size = ud2o(0, 14)
				guiElems.Right.Size = ud2o(0, 14)
			end
		end

		funcs.Paint = function(self)
			local guiElems = self.GuiElems

			if self.Style == 0 then
				local color_base = self.Disabled and self.Colors.Disabled
				guiElems.Outline.BackgroundColor3 = color_base or (self.Toggled and self.Colors.Primary) or self.Colors.Secondary
				local walls_color = color_base or self.Colors.Primary
				guiElems.Top.BackgroundColor3 = walls_color
				guiElems.Bottom.BackgroundColor3 = walls_color
				guiElems.Left.BackgroundColor3 = walls_color
				guiElems.Right.BackgroundColor3 = walls_color
			else
				guiElems.Outline.BackgroundColor3 = self.Disabled and self.Colors.Disabled or self.Colors.Secondary
				guiElems.Filler.BackgroundColor3 = self.Disabled and self.Colors.DisabledBackground or self.Colors.Background
				guiElems.Checkmark2.ImageColor3 = self.Disabled and self.Colors.DisabledCheck or self.Colors.Primary
			end
		end

		funcs.SetState = function(self,val,anim)
			self.Toggled = val

			if self.OutlineColorTween then self.OutlineColorTween:Cancel() end
			local setStateTime = tick()
			self.LastSetStateTime = setStateTime

			if self.Toggled then
				if self.Style == 0 then
					if anim then
						self.OutlineColorTween = service.TweenService:Create(self.GuiElems.Outline, ti(4/15, Enum.EasingStyle.Circular, Enum.EasingDirection.Out), {BackgroundColor3 = self.Colors.Primary})
						self.OutlineColorTween:Play()
						delay(0.15, function()
							if setStateTime ~= self.LastSetStateTime then return end
							self:Paint()
							TweenSize(self.GuiElems.Checkmark, ud2o(14, 20), "Out", "Bounce", 2/15, true)
						end)
					else
						self.GuiElems.Outline.BackgroundColor3 = self.Colors.Primary
						self:Paint()
						self.GuiElems.Checkmark.Size = ud2o(14, 20)
					end
					self:Collapse(anim)
				else
					self:Paint()
					self.GuiElems.Checkmark2.Visible = true
					self.GuiElems.Middle.Visible = false
				end
			else
				if self.Style == 0 then
					if anim then
						self.OutlineColorTween = service.TweenService:Create(self.GuiElems.Outline, ti(4/15, Enum.EasingStyle.Circular, Enum.EasingDirection.In), {BackgroundColor3 = self.Colors.Secondary})
						self.OutlineColorTween:Play()
						delay(0.15, function()
							if setStateTime ~= self.LastSetStateTime then return end
							self:Paint()
							TweenSize(self.GuiElems.Checkmark, ud2o(0, 20), "Out", "Quad", 1/15, true)
						end)
					else
						self.GuiElems.Outline.BackgroundColor3 = self.Colors.Secondary
						self:Paint()
						self.GuiElems.Checkmark.Size = ud2o(0, 20)
					end
					self:Expand(anim)
				else
					self:Paint()
					self.GuiElems.Checkmark2.Visible = false
					self.GuiElems.Middle.Visible = self.Toggled == nil
				end
			end
		end

		local mt = {__index = funcs}

		local function new(style)
			local obj = setmetatable({
				Toggled = false,
				Disabled = false,
				OnInput = Lib.Signal.new(),
				Style = style or 0,
				Colors = {
					Background = c3(36,36,36),
					Primary = c3(49,176,230),
					Secondary = c3(25,25,25),
					Disabled = c3(64,64,64),
					DisabledBackground = c3(52,52,52),
					DisabledCheck = c3(80,80,80)
				}
			},mt)
			initGui(obj)
			return obj
		end

		local function fromFrame(frame)
			local obj = setmetatable({
				Toggled = false,
				Disabled = false,
				Colors = {
					Background = c3(36,36,36),
					Primary = c3(49,176,230),
					Secondary = c3(25,25,25),
					Disabled = c3(64,64,64),
					DisabledBackground = c3(52,52,52)
				}
			},mt)
			initGui(obj,frame)
			return obj
		end

		return {new = new, fromFrame}
	end)()

	Lib.BrickColorPicker = (function()
		local funcs = {}
		local paletteCount = 0
		local mouse = service.Players.LocalPlayer:GetMouse()
		local hexStartX = 4
		local hexSizeX = 27
		local hexTriangleStart = 1
		local hexTriangleSize = 8

		local bottomColors = {
			Color3.fromRGB(17,17,17),
			Color3.fromRGB(99,95,98),
			Color3.fromRGB(163,162,165),
			Color3.fromRGB(205,205,205),
			Color3.fromRGB(223,223,222),
			Color3.fromRGB(237,234,234),
			Color3.fromRGB(27,42,53),
			Color3.fromRGB(91,93,105),
			Color3.fromRGB(159,161,172),
			Color3.fromRGB(202,203,209),
			Color3.fromRGB(231,231,236),
			Color3.fromRGB(248,248,248)
		}

		local function isMouseInHexagon(hex, touchPos)
			local relativeX = touchPos.X - hex.AbsolutePosition.X
			local relativeY = touchPos.Y - hex.AbsolutePosition.Y
			if relativeX >= hexStartX and relativeX < hexStartX + hexSizeX then
				relativeX = relativeX - 4
				local relativeWidth = (13 - math.min(relativeX, 26 - relativeX)) / 13
				if relativeY >= hexTriangleStart + hexTriangleSize * relativeWidth and relativeY < hex.AbsoluteSize.Y - hexTriangleStart - hexTriangleSize * relativeWidth then
					return true
				end
			end
			return false
		end

		local function hexInput(self, hex, color)
			hex.InputBegan:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
					if isMouseInHexagon(hex, input.Position) then
						self.OnSelect:Fire(color)
						self:Close()
					end
				end
			end)

			hex.InputChanged:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
					if isMouseInHexagon(hex, input.Position) then
						self.OnPreview:Fire(color)
					end
				end
			end)
		end

		local function createGui(self)
			local gui = create({
				{1,"ScreenGui",{Name="BrickColor",}},
				{2,"Frame",{Active=true,BackgroundColor3=Color3.new(0.17647059261799,0.17647059261799,0.17647059261799),BorderColor3=Color3.new(0.1294117718935,0.1294117718935,0.1294117718935),Parent={1},Position=UDim2.new(0.40000000596046,0,0.40000000596046,0),Size=UDim2.new(0,337,0,380),}},
				{3,"TextButton",{BackgroundColor3=Color3.new(0.2352941185236,0.2352941185236,0.2352941185236),BorderColor3=Color3.new(0.21568627655506,0.21568627655506,0.21568627655506),BorderSizePixel=0,Font=3,Name="MoreColors",Parent={2},Position=UDim2.new(0,5,1,-30),Size=UDim2.new(1,-10,0,25),Text="More Colors",TextColor3=Color3.new(1,1,1),TextSize=14,}},
				{4,"ImageLabel",{BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=1,BorderSizePixel=0,Image="rbxassetid://1281023007",ImageColor3=Color3.new(0.33333334326744,0.33333334326744,0.49803924560547),Name="Hex",Parent={2},Size=UDim2.new(0,35,0,35),Visible=false,}},
			})
			local colorFrame = gui.Frame
			local hex = colorFrame.Hex

			for row = 1,13 do
				local columns = math.min(row,14-row)+6
				for column = 1,columns do
					local nextColor = BrickColor.palette(paletteCount).Color
					local newHex = hex:Clone()
					newHex.Position = UDim2.new(0, (column-1)*25-(columns-7)*13+3*26 + 1, 0, (row-1)*23 + 4)
					newHex.ImageColor3 = nextColor
					newHex.Visible = true
					hexInput(self,newHex,nextColor)
					newHex.Parent = colorFrame
					paletteCount = paletteCount + 1
				end
			end

			for column = 1,12 do
				local nextColor = bottomColors[column]
				local newHex = hex:Clone()
				newHex.Position = UDim2.new(0, (column-1)*25-(12-7)*13+3*26 + 3, 0, 308)
				newHex.ImageColor3 = nextColor
				newHex.Visible = true
				hexInput(self,newHex,nextColor)
				newHex.Parent = colorFrame
				paletteCount = paletteCount + 1
			end

			colorFrame.MoreColors.MouseButton1Click:Connect(function()
				self.OnMoreColors:Fire()
				self:Close()
			end)

			self.Gui = gui
		end

		funcs.SetMoreColorsVisible = function(self,vis)
			local colorFrame = self.Gui.Frame
			colorFrame.Size = UDim2.new(0,337,0,380 - (not vis and 33 or 0))
			colorFrame.MoreColors.Visible = vis
		end

		funcs.Show = function(self,x,y,prevColor)
			self.PrevColor = prevColor or self.PrevColor

			local reverseY = false

			local x,y = x or mouse.X, y or mouse.Y
			local maxX,maxY = mouse.ViewSizeX,mouse.ViewSizeY
			Lib.ShowGui(self.Gui)
			local sizeX,sizeY = self.Gui.Frame.AbsoluteSize.X,self.Gui.Frame.AbsoluteSize.Y

			if x + sizeX > maxX then x = self.ReverseX and x - sizeX or maxX - sizeX end
			if y + sizeY > maxY then reverseY = true end

			local closable = false
			if self.CloseEvent then self.CloseEvent:Disconnect() end

			self.CloseEvent = service.UserInputService.InputBegan:Connect(function(input)
				if not closable or (input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch) then
					return
				end

				if not Lib.CheckMouseInGui(self.Gui.Frame) then
					self.CloseEvent:Disconnect()
					self:Close()
				end
			end)


			if reverseY then
				local newY = y - sizeY - (self.ReverseYOffset or 0)
				y = newY >= 0 and newY or 0
			end

			self.Gui.Frame.Position = UDim2.new(0,x,0,y)

			Lib.FastWait()
			closable = true
		end

		funcs.Close = function(self)
			self.Gui.Parent = nil
			self.OnCancel:Fire()
		end

		local mt = {__index = funcs}

		local function new()
			local obj = setmetatable({
				OnPreview = Lib.Signal.new(),
				OnSelect = Lib.Signal.new(),
				OnCancel = Lib.Signal.new(),
				OnMoreColors = Lib.Signal.new(),
				PrevColor = Color3.new(0,0,0)
			}, mt)
			createGui(obj)
			return obj
		end

		return {new = new}
	end)()

	Lib.ColorPicker = (function() -- TODO: Convert to newer class model
		local funcs = {}

		local function new()
			local newMt = setmetatable({},{})

			newMt.OnSelect = Lib.Signal.new()
			newMt.OnCancel = Lib.Signal.new()
			newMt.OnPreview = Lib.Signal.new()

			local guiContents = create({
				{1,"Frame",{BackgroundColor3=Color3.new(0.17647059261799,0.17647059261799,0.17647059261799),BorderSizePixel=0,ClipsDescendants=true,Name="Content",Position=UDim2.new(0,0,0,20),Size=UDim2.new(1,0,1,-20),}},
				{2,"Frame",{BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=1,Name="BasicColors",Parent={1},Position=UDim2.new(0,5,0,5),Size=UDim2.new(0,180,0,200),}},
				{3,"TextLabel",{BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=1,Font=3,Name="Title",Parent={2},Position=UDim2.new(0,0,0,-5),Size=UDim2.new(1,0,0,26),Text="Basic Colors",TextColor3=Color3.new(0.86274516582489,0.86274516582489,0.86274516582489),TextSize=14,TextXAlignment=0,}},
				{4,"Frame",{BackgroundColor3=Color3.new(0.14901961386204,0.14901961386204,0.14901961386204),BorderColor3=Color3.new(0.12549020349979,0.12549020349979,0.12549020349979),Name="Blue",Parent={1},Position=UDim2.new(1,-63,0,255),Size=UDim2.new(0,52,0,16),}},
				{5,"TextBox",{BackgroundColor3=Color3.new(0.25098040699959,0.25098040699959,0.25098040699959),BackgroundTransparency=1,BorderColor3=Color3.new(0.37647062540054,0.37647062540054,0.37647062540054),Font=3,Name="Input",Parent={4},Position=UDim2.new(0,2,0,0),Size=UDim2.new(0,50,0,16),Text="0",TextColor3=Color3.new(0.86274516582489,0.86274516582489,0.86274516582489),TextSize=14,TextXAlignment=0,}},
				{6,"Frame",{BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=1,BorderSizePixel=0,Name="ArrowFrame",Parent={5},Position=UDim2.new(1,-16,0,0),Size=UDim2.new(0,16,1,0),}},
				{7,"TextButton",{AutoButtonColor=false,BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=1,BorderSizePixel=0,Font=3,Name="Up",Parent={6},Size=UDim2.new(1,0,0,8),Text="",TextSize=14,}},
				{8,"Frame",{BackgroundTransparency=1,Name="Arrow",Parent={7},Size=UDim2.new(0,16,0,8),}},
				{9,"Frame",{BackgroundColor3=Color3.new(0.86274510622025,0.86274510622025,0.86274510622025),BorderSizePixel=0,Parent={8},Position=UDim2.new(0,8,0,3),Size=UDim2.new(0,1,0,1),}},
				{10,"Frame",{BackgroundColor3=Color3.new(0.86274510622025,0.86274510622025,0.86274510622025),BorderSizePixel=0,Parent={8},Position=UDim2.new(0,7,0,4),Size=UDim2.new(0,3,0,1),}},
				{11,"Frame",{BackgroundColor3=Color3.new(0.86274510622025,0.86274510622025,0.86274510622025),BorderSizePixel=0,Parent={8},Position=UDim2.new(0,6,0,5),Size=UDim2.new(0,5,0,1),}},
				{12,"TextButton",{AutoButtonColor=false,BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=1,BorderSizePixel=0,Font=3,Name="Down",Parent={6},Position=UDim2.new(0,0,0,8),Size=UDim2.new(1,0,0,8),Text="",TextSize=14,}},
				{13,"Frame",{BackgroundTransparency=1,Name="Arrow",Parent={12},Size=UDim2.new(0,16,0,8),}},
				{14,"Frame",{BackgroundColor3=Color3.new(0.86274510622025,0.86274510622025,0.86274510622025),BorderSizePixel=0,Parent={13},Position=UDim2.new(0,8,0,5),Size=UDim2.new(0,1,0,1),}},
				{15,"Frame",{BackgroundColor3=Color3.new(0.86274510622025,0.86274510622025,0.86274510622025),BorderSizePixel=0,Parent={13},Position=UDim2.new(0,7,0,4),Size=UDim2.new(0,3,0,1),}},
				{16,"Frame",{BackgroundColor3=Color3.new(0.86274510622025,0.86274510622025,0.86274510622025),BorderSizePixel=0,Parent={13},Position=UDim2.new(0,6,0,3),Size=UDim2.new(0,5,0,1),}},
				{17,"TextLabel",{BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=1,Font=3,Name="Title",Parent={4},Position=UDim2.new(0,-40,0,0),Size=UDim2.new(0,34,1,0),Text="Blue:",TextColor3=Color3.new(0.86274516582489,0.86274516582489,0.86274516582489),TextSize=14,TextXAlignment=1,}},
				{18,"Frame",{BackgroundColor3=Color3.new(0.21568627655506,0.21568627655506,0.21568627655506),BorderSizePixel=0,ClipsDescendants=true,Name="ColorSpaceFrame",Parent={1},Position=UDim2.new(1,-261,0,4),Size=UDim2.new(0,222,0,202),}},
				{19,"ImageLabel",{BackgroundColor3=Color3.new(1,1,1),BorderColor3=Color3.new(0.37647062540054,0.37647062540054,0.37647062540054),BorderSizePixel=0,Image="rbxassetid://1072518406",Name="ColorSpace",Parent={18},Position=UDim2.new(0,1,0,1),Size=UDim2.new(0,220,0,200),}},
				{20,"Frame",{BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=1,BorderSizePixel=0,Name="Scope",Parent={19},Position=UDim2.new(0,210,0,190),Size=UDim2.new(0,20,0,20),}},
				{21,"Frame",{BackgroundColor3=Color3.new(0,0,0),BorderSizePixel=0,Name="Line",Parent={20},Position=UDim2.new(0,9,0,0),Size=UDim2.new(0,2,0,20),}},
				{22,"Frame",{BackgroundColor3=Color3.new(0,0,0),BorderSizePixel=0,Name="Line",Parent={20},Position=UDim2.new(0,0,0,9),Size=UDim2.new(0,20,0,2),}},
				{23,"Frame",{BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=1,Name="CustomColors",Parent={1},Position=UDim2.new(0,5,0,210),Size=UDim2.new(0,180,0,90),}},
				{24,"TextLabel",{BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=1,Font=3,Name="Title",Parent={23},Size=UDim2.new(1,0,0,20),Text="Custom Colors (RC = Set)",TextColor3=Color3.new(0.86274516582489,0.86274516582489,0.86274516582489),TextSize=14,TextXAlignment=0,}},
				{25,"Frame",{BackgroundColor3=Color3.new(0.14901961386204,0.14901961386204,0.14901961386204),BorderColor3=Color3.new(0.12549020349979,0.12549020349979,0.12549020349979),Name="Green",Parent={1},Position=UDim2.new(1,-63,0,233),Size=UDim2.new(0,52,0,16),}},
				{26,"TextBox",{BackgroundColor3=Color3.new(0.25098040699959,0.25098040699959,0.25098040699959),BackgroundTransparency=1,BorderColor3=Color3.new(0.37647062540054,0.37647062540054,0.37647062540054),Font=3,Name="Input",Parent={25},Position=UDim2.new(0,2,0,0),Size=UDim2.new(0,50,0,16),Text="0",TextColor3=Color3.new(0.86274516582489,0.86274516582489,0.86274516582489),TextSize=14,TextXAlignment=0,}},
				{27,"Frame",{BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=1,BorderSizePixel=0,Name="ArrowFrame",Parent={26},Position=UDim2.new(1,-16,0,0),Size=UDim2.new(0,16,1,0),}},
				{28,"TextButton",{AutoButtonColor=false,BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=1,BorderSizePixel=0,Font=3,Name="Up",Parent={27},Size=UDim2.new(1,0,0,8),Text="",TextSize=14,}},
				{29,"Frame",{BackgroundTransparency=1,Name="Arrow",Parent={28},Size=UDim2.new(0,16,0,8),}},
				{30,"Frame",{BackgroundColor3=Color3.new(0.86274510622025,0.86274510622025,0.86274510622025),BorderSizePixel=0,Parent={29},Position=UDim2.new(0,8,0,3),Size=UDim2.new(0,1,0,1),}},
				{31,"Frame",{BackgroundColor3=Color3.new(0.86274510622025,0.86274510622025,0.86274510622025),BorderSizePixel=0,Parent={29},Position=UDim2.new(0,7,0,4),Size=UDim2.new(0,3,0,1),}},
				{32,"Frame",{BackgroundColor3=Color3.new(0.86274510622025,0.86274510622025,0.86274510622025),BorderSizePixel=0,Parent={29},Position=UDim2.new(0,6,0,5),Size=UDim2.new(0,5,0,1),}},
				{33,"TextButton",{AutoButtonColor=false,BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=1,BorderSizePixel=0,Font=3,Name="Down",Parent={27},Position=UDim2.new(0,0,0,8),Size=UDim2.new(1,0,0,8),Text="",TextSize=14,}},
				{34,"Frame",{BackgroundTransparency=1,Name="Arrow",Parent={33},Size=UDim2.new(0,16,0,8),}},
				{35,"Frame",{BackgroundColor3=Color3.new(0.86274510622025,0.86274510622025,0.86274510622025),BorderSizePixel=0,Parent={34},Position=UDim2.new(0,8,0,5),Size=UDim2.new(0,1,0,1),}},
				{36,"Frame",{BackgroundColor3=Color3.new(0.86274510622025,0.86274510622025,0.86274510622025),BorderSizePixel=0,Parent={34},Position=UDim2.new(0,7,0,4),Size=UDim2.new(0,3,0,1),}},
				{37,"Frame",{BackgroundColor3=Color3.new(0.86274510622025,0.86274510622025,0.86274510622025),BorderSizePixel=0,Parent={34},Position=UDim2.new(0,6,0,3),Size=UDim2.new(0,5,0,1),}},
				{38,"TextLabel",{BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=1,Font=3,Name="Title",Parent={25},Position=UDim2.new(0,-40,0,0),Size=UDim2.new(0,34,1,0),Text="Green:",TextColor3=Color3.new(0.86274516582489,0.86274516582489,0.86274516582489),TextSize=14,TextXAlignment=1,}},
				{39,"Frame",{BackgroundColor3=Color3.new(0.14901961386204,0.14901961386204,0.14901961386204),BorderColor3=Color3.new(0.12549020349979,0.12549020349979,0.12549020349979),Name="Hue",Parent={1},Position=UDim2.new(1,-180,0,211),Size=UDim2.new(0,52,0,16),}},
				{40,"TextBox",{BackgroundColor3=Color3.new(0.25098040699959,0.25098040699959,0.25098040699959),BackgroundTransparency=1,BorderColor3=Color3.new(0.37647062540054,0.37647062540054,0.37647062540054),Font=3,Name="Input",Parent={39},Position=UDim2.new(0,2,0,0),Size=UDim2.new(0,50,0,16),Text="0",TextColor3=Color3.new(0.86274516582489,0.86274516582489,0.86274516582489),TextSize=14,TextXAlignment=0,}},
				{41,"Frame",{BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=1,BorderSizePixel=0,Name="ArrowFrame",Parent={40},Position=UDim2.new(1,-16,0,0),Size=UDim2.new(0,16,1,0),}},
				{42,"TextButton",{AutoButtonColor=false,BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=1,BorderSizePixel=0,Font=3,Name="Up",Parent={41},Size=UDim2.new(1,0,0,8),Text="",TextSize=14,}},
				{43,"Frame",{BackgroundTransparency=1,Name="Arrow",Parent={42},Size=UDim2.new(0,16,0,8),}},
				{44,"Frame",{BackgroundColor3=Color3.new(0.86274510622025,0.86274510622025,0.86274510622025),BorderSizePixel=0,Parent={43},Position=UDim2.new(0,8,0,3),Size=UDim2.new(0,1,0,1),}},
				{45,"Frame",{BackgroundColor3=Color3.new(0.86274510622025,0.86274510622025,0.86274510622025),BorderSizePixel=0,Parent={43},Position=UDim2.new(0,7,0,4),Size=UDim2.new(0,3,0,1),}},
				{46,"Frame",{BackgroundColor3=Color3.new(0.86274510622025,0.86274510622025,0.86274510622025),BorderSizePixel=0,Parent={43},Position=UDim2.new(0,6,0,5),Size=UDim2.new(0,5,0,1),}},
				{47,"TextButton",{AutoButtonColor=false,BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=1,BorderSizePixel=0,Font=3,Name="Down",Parent={41},Position=UDim2.new(0,0,0,8),Size=UDim2.new(1,0,0,8),Text="",TextSize=14,}},
				{48,"Frame",{BackgroundTransparency=1,Name="Arrow",Parent={47},Size=UDim2.new(0,16,0,8),}},
				{49,"Frame",{BackgroundColor3=Color3.new(0.86274510622025,0.86274510622025,0.86274510622025),BorderSizePixel=0,Parent={48},Position=UDim2.new(0,8,0,5),Size=UDim2.new(0,1,0,1),}},
				{50,"Frame",{BackgroundColor3=Color3.new(0.86274510622025,0.86274510622025,0.86274510622025),BorderSizePixel=0,Parent={48},Position=UDim2.new(0,7,0,4),Size=UDim2.new(0,3,0,1),}},
				{51,"Frame",{BackgroundColor3=Color3.new(0.86274510622025,0.86274510622025,0.86274510622025),BorderSizePixel=0,Parent={48},Position=UDim2.new(0,6,0,3),Size=UDim2.new(0,5,0,1),}},
				{52,"TextLabel",{BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=1,Font=3,Name="Title",Parent={39},Position=UDim2.new(0,-40,0,0),Size=UDim2.new(0,34,1,0),Text="Hue:",TextColor3=Color3.new(0.86274516582489,0.86274516582489,0.86274516582489),TextSize=14,TextXAlignment=1,}},
				{53,"Frame",{BackgroundColor3=Color3.new(1,1,1),BorderColor3=Color3.new(0.21568627655506,0.21568627655506,0.21568627655506),Name="Preview",Parent={1},Position=UDim2.new(1,-260,0,211),Size=UDim2.new(0,35,1,-245),}},
				{54,"Frame",{BackgroundColor3=Color3.new(0.14901961386204,0.14901961386204,0.14901961386204),BorderColor3=Color3.new(0.12549020349979,0.12549020349979,0.12549020349979),Name="Red",Parent={1},Position=UDim2.new(1,-63,0,211),Size=UDim2.new(0,52,0,16),}},
				{55,"TextBox",{BackgroundColor3=Color3.new(0.25098040699959,0.25098040699959,0.25098040699959),BackgroundTransparency=1,BorderColor3=Color3.new(0.37647062540054,0.37647062540054,0.37647062540054),Font=3,Name="Input",Parent={54},Position=UDim2.new(0,2,0,0),Size=UDim2.new(0,50,0,16),Text="0",TextColor3=Color3.new(0.86274516582489,0.86274516582489,0.86274516582489),TextSize=14,TextXAlignment=0,}},
				{56,"Frame",{BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=1,BorderSizePixel=0,Name="ArrowFrame",Parent={55},Position=UDim2.new(1,-16,0,0),Size=UDim2.new(0,16,1,0),}},
				{57,"TextButton",{AutoButtonColor=false,BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=1,BorderSizePixel=0,Font=3,Name="Up",Parent={56},Size=UDim2.new(1,0,0,8),Text="",TextSize=14,}},
				{58,"Frame",{BackgroundTransparency=1,Name="Arrow",Parent={57},Size=UDim2.new(0,16,0,8),}},
				{59,"Frame",{BackgroundColor3=Color3.new(0.86274510622025,0.86274510622025,0.86274510622025),BorderSizePixel=0,Parent={58},Position=UDim2.new(0,8,0,3),Size=UDim2.new(0,1,0,1),}},
				{60,"Frame",{BackgroundColor3=Color3.new(0.86274510622025,0.86274510622025,0.86274510622025),BorderSizePixel=0,Parent={58},Position=UDim2.new(0,7,0,4),Size=UDim2.new(0,3,0,1),}},
				{61,"Frame",{BackgroundColor3=Color3.new(0.86274510622025,0.86274510622025,0.86274510622025),BorderSizePixel=0,Parent={58},Position=UDim2.new(0,6,0,5),Size=UDim2.new(0,5,0,1),}},
				{62,"TextButton",{AutoButtonColor=false,BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=1,BorderSizePixel=0,Font=3,Name="Down",Parent={56},Position=UDim2.new(0,0,0,8),Size=UDim2.new(1,0,0,8),Text="",TextSize=14,}},
				{63,"Frame",{BackgroundTransparency=1,Name="Arrow",Parent={62},Size=UDim2.new(0,16,0,8),}},
				{64,"Frame",{BackgroundColor3=Color3.new(0.86274510622025,0.86274510622025,0.86274510622025),BorderSizePixel=0,Parent={63},Position=UDim2.new(0,8,0,5),Size=UDim2.new(0,1,0,1),}},
				{65,"Frame",{BackgroundColor3=Color3.new(0.86274510622025,0.86274510622025,0.86274510622025),BorderSizePixel=0,Parent={63},Position=UDim2.new(0,7,0,4),Size=UDim2.new(0,3,0,1),}},
				{66,"Frame",{BackgroundColor3=Color3.new(0.86274510622025,0.86274510622025,0.86274510622025),BorderSizePixel=0,Parent={63},Position=UDim2.new(0,6,0,3),Size=UDim2.new(0,5,0,1),}},
				{67,"TextLabel",{BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=1,Font=3,Name="Title",Parent={54},Position=UDim2.new(0,-40,0,0),Size=UDim2.new(0,34,1,0),Text="Red:",TextColor3=Color3.new(0.86274516582489,0.86274516582489,0.86274516582489),TextSize=14,TextXAlignment=1,}},
				{68,"Frame",{BackgroundColor3=Color3.new(0.14901961386204,0.14901961386204,0.14901961386204),BorderColor3=Color3.new(0.12549020349979,0.12549020349979,0.12549020349979),Name="Sat",Parent={1},Position=UDim2.new(1,-180,0,233),Size=UDim2.new(0,52,0,16),}},
				{69,"TextBox",{BackgroundColor3=Color3.new(0.25098040699959,0.25098040699959,0.25098040699959),BackgroundTransparency=1,BorderColor3=Color3.new(0.37647062540054,0.37647062540054,0.37647062540054),Font=3,Name="Input",Parent={68},Position=UDim2.new(0,2,0,0),Size=UDim2.new(0,50,0,16),Text="0",TextColor3=Color3.new(0.86274516582489,0.86274516582489,0.86274516582489),TextSize=14,TextXAlignment=0,}},
				{70,"Frame",{BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=1,BorderSizePixel=0,Name="ArrowFrame",Parent={69},Position=UDim2.new(1,-16,0,0),Size=UDim2.new(0,16,1,0),}},
				{71,"TextButton",{AutoButtonColor=false,BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=1,BorderSizePixel=0,Font=3,Name="Up",Parent={70},Size=UDim2.new(1,0,0,8),Text="",TextSize=14,}},
				{72,"Frame",{BackgroundTransparency=1,Name="Arrow",Parent={71},Size=UDim2.new(0,16,0,8),}},
				{73,"Frame",{BackgroundColor3=Color3.new(0.86274510622025,0.86274510622025,0.86274510622025),BorderSizePixel=0,Parent={72},Position=UDim2.new(0,8,0,3),Size=UDim2.new(0,1,0,1),}},
				{74,"Frame",{BackgroundColor3=Color3.new(0.86274510622025,0.86274510622025,0.86274510622025),BorderSizePixel=0,Parent={72},Position=UDim2.new(0,7,0,4),Size=UDim2.new(0,3,0,1),}},
				{75,"Frame",{BackgroundColor3=Color3.new(0.86274510622025,0.86274510622025,0.86274510622025),BorderSizePixel=0,Parent={72},Position=UDim2.new(0,6,0,5),Size=UDim2.new(0,5,0,1),}},
				{76,"TextButton",{AutoButtonColor=false,BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=1,BorderSizePixel=0,Font=3,Name="Down",Parent={70},Position=UDim2.new(0,0,0,8),Size=UDim2.new(1,0,0,8),Text="",TextSize=14,}},
				{77,"Frame",{BackgroundTransparency=1,Name="Arrow",Parent={76},Size=UDim2.new(0,16,0,8),}},
				{78,"Frame",{BackgroundColor3=Color3.new(0.86274510622025,0.86274510622025,0.86274510622025),BorderSizePixel=0,Parent={77},Position=UDim2.new(0,8,0,5),Size=UDim2.new(0,1,0,1),}},
				{79,"Frame",{BackgroundColor3=Color3.new(0.86274510622025,0.86274510622025,0.86274510622025),BorderSizePixel=0,Parent={77},Position=UDim2.new(0,7,0,4),Size=UDim2.new(0,3,0,1),}},
				{80,"Frame",{BackgroundColor3=Color3.new(0.86274510622025,0.86274510622025,0.86274510622025),BorderSizePixel=0,Parent={77},Position=UDim2.new(0,6,0,3),Size=UDim2.new(0,5,0,1),}},
				{81,"TextLabel",{BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=1,Font=3,Name="Title",Parent={68},Position=UDim2.new(0,-40,0,0),Size=UDim2.new(0,34,1,0),Text="Sat:",TextColor3=Color3.new(0.86274516582489,0.86274516582489,0.86274516582489),TextSize=14,TextXAlignment=1,}},
				{82,"Frame",{BackgroundColor3=Color3.new(0.14901961386204,0.14901961386204,0.14901961386204),BorderColor3=Color3.new(0.12549020349979,0.12549020349979,0.12549020349979),Name="Val",Parent={1},Position=UDim2.new(1,-180,0,255),Size=UDim2.new(0,52,0,16),}},
				{83,"TextBox",{BackgroundColor3=Color3.new(0.25098040699959,0.25098040699959,0.25098040699959),BackgroundTransparency=1,BorderColor3=Color3.new(0.37647062540054,0.37647062540054,0.37647062540054),Font=3,Name="Input",Parent={82},Position=UDim2.new(0,2,0,0),Size=UDim2.new(0,50,0,16),Text="255",TextColor3=Color3.new(0.86274516582489,0.86274516582489,0.86274516582489),TextSize=14,TextXAlignment=0,}},
				{84,"Frame",{BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=1,BorderSizePixel=0,Name="ArrowFrame",Parent={83},Position=UDim2.new(1,-16,0,0),Size=UDim2.new(0,16,1,0),}},
				{85,"TextButton",{AutoButtonColor=false,BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=1,BorderSizePixel=0,Font=3,Name="Up",Parent={84},Size=UDim2.new(1,0,0,8),Text="",TextSize=14,}},
				{86,"Frame",{BackgroundTransparency=1,Name="Arrow",Parent={85},Size=UDim2.new(0,16,0,8),}},
				{87,"Frame",{BackgroundColor3=Color3.new(0.86274510622025,0.86274510622025,0.86274510622025),BorderSizePixel=0,Parent={86},Position=UDim2.new(0,8,0,3),Size=UDim2.new(0,1,0,1),}},
				{88,"Frame",{BackgroundColor3=Color3.new(0.86274510622025,0.86274510622025,0.86274510622025),BorderSizePixel=0,Parent={86},Position=UDim2.new(0,7,0,4),Size=UDim2.new(0,3,0,1),}},
				{89,"Frame",{BackgroundColor3=Color3.new(0.86274510622025,0.86274510622025,0.86274510622025),BorderSizePixel=0,Parent={86},Position=UDim2.new(0,6,0,5),Size=UDim2.new(0,5,0,1),}},
				{90,"TextButton",{AutoButtonColor=false,BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=1,BorderSizePixel=0,Font=3,Name="Down",Parent={84},Position=UDim2.new(0,0,0,8),Size=UDim2.new(1,0,0,8),Text="",TextSize=14,}},
				{91,"Frame",{BackgroundTransparency=1,Name="Arrow",Parent={90},Size=UDim2.new(0,16,0,8),}},
				{92,"Frame",{BackgroundColor3=Color3.new(0.86274510622025,0.86274510622025,0.86274510622025),BorderSizePixel=0,Parent={91},Position=UDim2.new(0,8,0,5),Size=UDim2.new(0,1,0,1),}},
				{93,"Frame",{BackgroundColor3=Color3.new(0.86274510622025,0.86274510622025,0.86274510622025),BorderSizePixel=0,Parent={91},Position=UDim2.new(0,7,0,4),Size=UDim2.new(0,3,0,1),}},
				{94,"Frame",{BackgroundColor3=Color3.new(0.86274510622025,0.86274510622025,0.86274510622025),BorderSizePixel=0,Parent={91},Position=UDim2.new(0,6,0,3),Size=UDim2.new(0,5,0,1),}},
				{95,"TextLabel",{BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=1,Font=3,Name="Title",Parent={82},Position=UDim2.new(0,-40,0,0),Size=UDim2.new(0,34,1,0),Text="Val:",TextColor3=Color3.new(0.86274516582489,0.86274516582489,0.86274516582489),TextSize=14,TextXAlignment=1,}},
				{96,"TextButton",{AutoButtonColor=false,BackgroundColor3=Color3.new(0.2352941185236,0.2352941185236,0.2352941185236),BorderColor3=Color3.new(0.21568627655506,0.21568627655506,0.21568627655506),Font=3,Name="Cancel",Parent={1},Position=UDim2.new(1,-105,1,-28),Size=UDim2.new(0,100,0,25),Text="Cancel",TextColor3=Color3.new(0.86274516582489,0.86274516582489,0.86274516582489),TextSize=14,}},
				{97,"TextButton",{AutoButtonColor=false,BackgroundColor3=Color3.new(0.2352941185236,0.2352941185236,0.2352941185236),BorderColor3=Color3.new(0.21568627655506,0.21568627655506,0.21568627655506),Font=3,Name="Ok",Parent={1},Position=UDim2.new(1,-210,1,-28),Size=UDim2.new(0,100,0,25),Text="OK",TextColor3=Color3.new(0.86274516582489,0.86274516582489,0.86274516582489),TextSize=14,}},
				{98,"ImageLabel",{BackgroundColor3=Color3.new(1,1,1),BorderColor3=Color3.new(0.21568627655506,0.21568627655506,0.21568627655506),Image="rbxassetid://1072518502",Name="ColorStrip",Parent={1},Position=UDim2.new(1,-30,0,5),Size=UDim2.new(0,13,0,200),}},
				{99,"Frame",{BackgroundColor3=Color3.new(0.3137255012989,0.3137255012989,0.3137255012989),BackgroundTransparency=1,BorderSizePixel=0,Name="ArrowFrame",Parent={1},Position=UDim2.new(1,-16,0,1),Size=UDim2.new(0,5,0,208),}},
				{100,"Frame",{BackgroundTransparency=1,Name="Arrow",Parent={99},Position=UDim2.new(0,-2,0,-4),Size=UDim2.new(0,8,0,16),}},
				{101,"Frame",{BackgroundColor3=Color3.new(0,0,0),BorderSizePixel=0,Parent={100},Position=UDim2.new(0,2,0,8),Size=UDim2.new(0,1,0,1),}},
				{102,"Frame",{BackgroundColor3=Color3.new(0,0,0),BorderSizePixel=0,Parent={100},Position=UDim2.new(0,3,0,7),Size=UDim2.new(0,1,0,3),}},
				{103,"Frame",{BackgroundColor3=Color3.new(0,0,0),BorderSizePixel=0,Parent={100},Position=UDim2.new(0,4,0,6),Size=UDim2.new(0,1,0,5),}},
				{104,"Frame",{BackgroundColor3=Color3.new(0,0,0),BorderSizePixel=0,Parent={100},Position=UDim2.new(0,5,0,5),Size=UDim2.new(0,1,0,7),}},
				{105,"Frame",{BackgroundColor3=Color3.new(0,0,0),BorderSizePixel=0,Parent={100},Position=UDim2.new(0,6,0,4),Size=UDim2.new(0,1,0,9),}},
			})
			local window = Lib.Window.new()
			window.Resizable = false
			window.Alignable = false
			window:SetTitle("Color Picker")
			window:Resize(450,330)
			for i,v in pairs(guiContents:GetChildren()) do
				v.Parent = window.GuiElems.Content
			end
			newMt.Window = window
			newMt.Gui = window.Gui
			local pickerGui = window.Gui.Main
			local pickerTopBar = pickerGui.TopBar
			local pickerFrame = pickerGui.Content
			local colorSpace = pickerFrame.ColorSpaceFrame.ColorSpace
			local colorStrip = pickerFrame.ColorStrip
			local previewFrame = pickerFrame.Preview
			local basicColorsFrame = pickerFrame.BasicColors
			local customColorsFrame = pickerFrame.CustomColors
			local okButton = pickerFrame.Ok
			local cancelButton = pickerFrame.Cancel
			local closeButton = pickerTopBar.Close

			local colorScope = colorSpace.Scope
			local colorArrow = pickerFrame.ArrowFrame.Arrow

			local hueInput = pickerFrame.Hue.Input
			local satInput = pickerFrame.Sat.Input
			local valInput = pickerFrame.Val.Input

			local redInput = pickerFrame.Red.Input
			local greenInput = pickerFrame.Green.Input
			local blueInput = pickerFrame.Blue.Input

			local user = service.UserInputService
			local mouse = service.Players.LocalPlayer:GetMouse()

			local hue,sat,val = 0,0,1
			local red,green,blue = 1,1,1
			local chosenColor = Color3.new(0,0,0)

			local basicColors = {Color3.new(0,0,0),Color3.new(0.66666668653488,0,0),Color3.new(0,0.33333334326744,0),Color3.new(0.66666668653488,0.33333334326744,0),Color3.new(0,0.66666668653488,0),Color3.new(0.66666668653488,0.66666668653488,0),Color3.new(0,1,0),Color3.new(0.66666668653488,1,0),Color3.new(0,0,0.49803924560547),Color3.new(0.66666668653488,0,0.49803924560547),Color3.new(0,0.33333334326744,0.49803924560547),Color3.new(0.66666668653488,0.33333334326744,0.49803924560547),Color3.new(0,0.66666668653488,0.49803924560547),Color3.new(0.66666668653488,0.66666668653488,0.49803924560547),Color3.new(0,1,0.49803924560547),Color3.new(0.66666668653488,1,0.49803924560547),Color3.new(0,0,1),Color3.new(0.66666668653488,0,1),Color3.new(0,0.33333334326744,1),Color3.new(0.66666668653488,0.33333334326744,1),Color3.new(0,0.66666668653488,1),Color3.new(0.66666668653488,0.66666668653488,1),Color3.new(0,1,1),Color3.new(0.66666668653488,1,1),Color3.new(0.33333334326744,0,0),Color3.new(1,0,0),Color3.new(0.33333334326744,0.33333334326744,0),Color3.new(1,0.33333334326744,0),Color3.new(0.33333334326744,0.66666668653488,0),Color3.new(1,0.66666668653488,0),Color3.new(0.33333334326744,1,0),Color3.new(1,1,0),Color3.new(0.33333334326744,0,0.49803924560547),Color3.new(1,0,0.49803924560547),Color3.new(0.33333334326744,0.33333334326744,0.49803924560547),Color3.new(1,0.33333334326744,0.49803924560547),Color3.new(0.33333334326744,0.66666668653488,0.49803924560547),Color3.new(1,0.66666668653488,0.49803924560547),Color3.new(0.33333334326744,1,0.49803924560547),Color3.new(1,1,0.49803924560547),Color3.new(0.33333334326744,0,1),Color3.new(1,0,1),Color3.new(0.33333334326744,0.33333334326744,1),Color3.new(1,0.33333334326744,1),Color3.new(0.33333334326744,0.66666668653488,1),Color3.new(1,0.66666668653488,1),Color3.new(0.33333334326744,1,1),Color3.new(1,1,1)}
			local customColors = {}

			local function updateColor(noupdate)
				local relativeX, relativeY, relativeStripY = 219 - hue * 219, 199 - sat * 199, 199 - val * 199
				local hsvColor = Color3.fromHSV(hue, sat, val)

				if noupdate == 2 or not noupdate then
					hueInput.Text = tostring(math.ceil(359 * hue))
					satInput.Text = tostring(math.ceil(255 * sat))
					valInput.Text = tostring(math.floor(255 * val))
				end
				if noupdate == 1 or not noupdate then
					redInput.Text = tostring(math.floor(255 * red))
					greenInput.Text = tostring(math.floor(255 * green))
					blueInput.Text = tostring(math.floor(255 * blue))
				end

				chosenColor = Color3.new(red, green, blue)
				colorScope.Position = UDim2.new(0, (relativeX - 9), 0, (relativeY - 9))
				colorStrip.ImageColor3 = Color3.fromHSV(hue, sat, 1)
				colorArrow.Position = UDim2.new(0, -2, 0, (relativeStripY - 4))
				previewFrame.BackgroundColor3 = chosenColor

				newMt.Color = chosenColor
				newMt.OnPreview:Fire(chosenColor)
			end

			local function handleInputBegan(input, updateFunc)
				if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
					while user:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) do
						updateFunc()task.wait()
					end
				end
			end

			local function colorSpaceInput()
				local relativeX = mouse.X - colorSpace.AbsolutePosition.X
				local relativeY = mouse.Y - colorSpace.AbsolutePosition.Y

				if relativeX < 0 then relativeX = 0 elseif relativeX > 219 then relativeX = 219 end
				if relativeY < 0 then relativeY = 0 elseif relativeY > 199 then relativeY = 199 end

				hue = (219 - relativeX) / 219
				sat = (199 - relativeY) / 199

				local hsvColor = Color3.fromHSV(hue, sat, val)
				red, green, blue = hsvColor.R, hsvColor.G, hsvColor.B
				updateColor()
			end

			local function colorStripInput()
				local relativeY = mouse.Y - colorStrip.AbsolutePosition.Y

				if relativeY < 0 then relativeY = 0 elseif relativeY > 199 then relativeY = 199 end	

				val = (199 - relativeY) / 199

				local hsvColor = Color3.fromHSV(hue, sat, val)
				red, green, blue = hsvColor.R, hsvColor.G, hsvColor.B
				updateColor()
			end

			colorSpace.InputBegan:Connect(function(input) handleInputBegan(input, colorSpaceInput) end)
			colorStrip.InputBegan:Connect(function(input) handleInputBegan(input, colorStripInput) end)

			local function hookButtons(frame, func)
				frame.ArrowFrame.Up.InputBegan:Connect(function(input)
					if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
						local releaseEvent, runEvent
						local startTime = tick()
						local pressing = true
						local startNum = tonumber(frame.Text)

						if not startNum then return end

						releaseEvent = user.InputEnded:Connect(function(endInput)
							if endInput.UserInputType == Enum.UserInputType.MouseButton1 or endInput.UserInputType == Enum.UserInputType.Touch then
								releaseEvent:Disconnect()
								pressing = false
							end
						end)

						startNum = startNum + 1
						func(startNum)
						while pressing do
							if tick() - startTime > 0.3 then
								startNum = startNum + 1
								func(startNum)
								startTime = tick()
							end
							task.wait(0.1)
						end
					end
				end)

				frame.ArrowFrame.Down.InputBegan:Connect(function(input)
					if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
						local releaseEvent, runEvent
						local startTime = tick()
						local pressing = true
						local startNum = tonumber(frame.Text)

						if not startNum then return end

						releaseEvent = user.InputEnded:Connect(function(endInput)
							if endInput.UserInputType == Enum.UserInputType.MouseButton1 or endInput.UserInputType == Enum.UserInputType.Touch then
								releaseEvent:Disconnect()
								pressing = false
							end
						end)

						startNum = startNum - 1
						func(startNum)
						while pressing do
							if tick() - startTime > 0.3 then
								startNum = startNum - 1
								func(startNum)
								startTime = tick()
							end
							task.wait(0.1)
						end
					end
				end)
			end

			--[[local function UpdateBox(TextBox, Value, IsHSV, ...)
				local number = tonumber(TextBox.Text)
				if number then
					number = math.clamp(math.floor(number), 0, Value) / Value
					local HSV = Color3.fromHSV(func(number))
					red, green, blue = HSV.R, HSV.G, HSV.B
					
					TextBox.Text = tostring(number):sub(4)
					updateColor(IsHSV)
				end
			end]]

			local function updateHue(str)
				local num = tonumber(str)
				if num then
					hue = math.clamp(math.floor(num),0,359)/359
					local hsvColor = Color3.fromHSV(hue,sat,val)
					red,green,blue = hsvColor.r,hsvColor.g,hsvColor.b

					hueInput.Text = tostring(hue*359)
					updateColor(1)
				end
			end
			hueInput.FocusLost:Connect(function() updateHue(hueInput.Text) end) hookButtons(hueInput, hueInput)

			local function updateSat(str)
				local num = tonumber(str)
				if num then
					sat = math.clamp(math.floor(num),0,255)/255
					local hsvColor = Color3.fromHSV(hue,sat,val)
					red,green,blue = hsvColor.r,hsvColor.g,hsvColor.b
					satInput.Text = tostring(sat*255)
					updateColor(1)
				end
			end
			satInput.FocusLost:Connect(function() updateSat(satInput.Text) end) hookButtons(satInput,updateSat)

			local function updateVal(str)
				local num = tonumber(str)
				if num then
					val = math.clamp(math.floor(num),0,255)/255
					local hsvColor = Color3.fromHSV(hue,sat,val)
					red,green,blue = hsvColor.r,hsvColor.g,hsvColor.b
					valInput.Text = tostring(val*255)
					updateColor(1)
				end
			end
			valInput.FocusLost:Connect(function() updateVal(valInput.Text) end) hookButtons(valInput,updateVal)

			local function updateRed(str)
				local num = tonumber(str)
				if num then
					red = math.clamp(math.floor(num),0,255)/255
					local newColor = Color3.new(red,green,blue)
					hue,sat,val = Color3.toHSV(newColor)
					redInput.Text = tostring(red*255)
					updateColor(2)
				end
			end
			redInput.FocusLost:Connect(function() updateRed(redInput.Text) end) hookButtons(redInput,updateRed)

			local function updateGreen(str)
				local num = tonumber(str)
				if num then
					green = math.clamp(math.floor(num),0,255)/255
					local newColor = Color3.new(red,green,blue)
					hue,sat,val = Color3.toHSV(newColor)
					greenInput.Text = tostring(green*255)
					updateColor(2)
				end
			end
			greenInput.FocusLost:Connect(function() updateGreen(greenInput.Text) end) hookButtons(greenInput,updateGreen)

			local function updateBlue(str)
				local num = tonumber(str)
				if num then
					blue = math.clamp(math.floor(num),0,255)/255
					local newColor = Color3.new(red,green,blue)
					hue,sat,val = Color3.toHSV(newColor)
					blueInput.Text = tostring(blue*255)
					updateColor(2)
				end
			end
			blueInput.FocusLost:Connect(function() updateBlue(blueInput.Text) end) hookButtons(blueInput,updateBlue)

			local colorChoice = Instance.new("TextButton")
			colorChoice.Name = "Choice"
			colorChoice.Size = UDim2.new(0,25,0,18)
			colorChoice.BorderColor3 = Color3.fromRGB(55,55,55)
			colorChoice.Text = ""
			colorChoice.AutoButtonColor = false

			local row = 0
			local column = 0
			for i,v in pairs(basicColors) do
				local newColor = colorChoice:Clone()
				newColor.BackgroundColor3 = v
				newColor.Position = UDim2.new(0,1 + 30*column,0,21 + 23*row)

				newColor.MouseButton1Click:Connect(function()
					red,green,blue = v.r,v.g,v.b
					local newColor = Color3.new(red,green,blue)
					hue,sat,val = Color3.toHSV(newColor)
					updateColor()
				end)

				newColor.Parent = basicColorsFrame
				column = column + 1
				if column == 6 then row = row + 1 column = 0 end
			end

			row = 0
			column = 0
			for i = 1,12 do
				local color = customColors[i] or Color3.new(0,0,0)
				local newColor = colorChoice:Clone()
				newColor.BackgroundColor3 = color
				newColor.Position = UDim2.new(0,1 + 30*column,0,20 + 23*row)

				newColor.MouseButton1Click:Connect(function()
					local curColor = customColors[i] or Color3.new(0,0,0)
					red,green,blue = curColor.r,curColor.g,curColor.b
					hue,sat,val = Color3.toHSV(curColor)
					updateColor()
				end)

				newColor.MouseButton2Click:Connect(function()
					customColors[i] = chosenColor
					newColor.BackgroundColor3 = chosenColor
				end)

				newColor.Parent = customColorsFrame
				column = column + 1
				if column == 6 then row = row + 1 column = 0 end
			end

			okButton.MouseButton1Click:Connect(function() newMt.OnSelect:Fire(chosenColor) window:Close() end)
			okButton.InputBegan:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then okButton.BackgroundTransparency = 0.4 end end)
			okButton.InputEnded:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then okButton.BackgroundTransparency = 0 end end)


			cancelButton.MouseButton1Click:Connect(function() newMt.OnCancel:Fire() window:Close() end)
			cancelButton.InputBegan:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then cancelButton.BackgroundTransparency = 0.4 end end)
			cancelButton.InputEnded:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then cancelButton.BackgroundTransparency = 0 end end)

			updateColor()

			newMt.SetColor = function(self,color)
				red,green,blue = color.r,color.g,color.b
				hue,sat,val = Color3.toHSV(color)
				updateColor()
			end

			newMt.Show = function(self)
				self.Window:Show()
			end

			return newMt
		end

		return {new = new}
	end)()

	Lib.NumberSequenceEditor = (function()
		local function new() -- TODO: Convert to newer class model
			local newMt = setmetatable({},{})
			newMt.OnSelect = Lib.Signal.new()
			newMt.OnCancel = Lib.Signal.new()
			newMt.OnPreview = Lib.Signal.new()

			local guiContents = create({
				{1,"Frame",{BackgroundColor3=Color3.new(0.17647059261799,0.17647059261799,0.17647059261799),BorderSizePixel=0,ClipsDescendants=true,Name="Content",Position=UDim2.new(0,0,0,20),Size=UDim2.new(1,0,1,-20),}},
				{2,"Frame",{BackgroundColor3=Color3.new(0.14901961386204,0.14901961386204,0.14901961386204),BorderColor3=Color3.new(0.12549020349979,0.12549020349979,0.12549020349979),Name="Time",Parent={1},Position=UDim2.new(0,40,0,210),Size=UDim2.new(0,60,0,20),}},
				{3,"TextBox",{BackgroundColor3=Color3.new(0.25098040699959,0.25098040699959,0.25098040699959),BackgroundTransparency=1,BorderColor3=Color3.new(0.37647062540054,0.37647062540054,0.37647062540054),ClipsDescendants=true,Font=3,Name="Input",Parent={2},Position=UDim2.new(0,2,0,0),Size=UDim2.new(0,58,0,20),Text="0",TextColor3=Color3.new(0.86274516582489,0.86274516582489,0.86274516582489),TextSize=14,TextXAlignment=0,}},
				{4,"TextLabel",{BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=1,Font=3,Name="Title",Parent={2},Position=UDim2.new(0,-40,0,0),Size=UDim2.new(0,34,1,0),Text="Time",TextColor3=Color3.new(0.86274516582489,0.86274516582489,0.86274516582489),TextSize=14,TextXAlignment=1,}},
				{5,"TextButton",{AutoButtonColor=false,BackgroundColor3=Color3.new(0.2352941185236,0.2352941185236,0.2352941185236),BorderColor3=Color3.new(0.21568627655506,0.21568627655506,0.21568627655506),Font=3,Name="Close",Parent={1},Position=UDim2.new(1,-90,0,210),Size=UDim2.new(0,80,0,20),Text="Close",TextColor3=Color3.new(0.86274516582489,0.86274516582489,0.86274516582489),TextSize=14,}},
				{6,"TextButton",{AutoButtonColor=false,BackgroundColor3=Color3.new(0.2352941185236,0.2352941185236,0.2352941185236),BorderColor3=Color3.new(0.21568627655506,0.21568627655506,0.21568627655506),Font=3,Name="Reset",Parent={1},Position=UDim2.new(1,-180,0,210),Size=UDim2.new(0,80,0,20),Text="Reset",TextColor3=Color3.new(0.86274516582489,0.86274516582489,0.86274516582489),TextSize=14,}},
				{7,"TextButton",{AutoButtonColor=false,BackgroundColor3=Color3.new(0.2352941185236,0.2352941185236,0.2352941185236),BorderColor3=Color3.new(0.21568627655506,0.21568627655506,0.21568627655506),Font=3,Name="Delete",Parent={1},Position=UDim2.new(0,380,0,210),Size=UDim2.new(0,80,0,20),Text="Delete",TextColor3=Color3.new(0.86274516582489,0.86274516582489,0.86274516582489),TextSize=14,}},
				{8,"Frame",{BackgroundColor3=Color3.new(0.17647059261799,0.17647059261799,0.17647059261799),BorderColor3=Color3.new(0.21568627655506,0.21568627655506,0.21568627655506),Name="NumberLineOutlines",Parent={1},Position=UDim2.new(0,10,0,20),Size=UDim2.new(1,-20,0,170),}},
				{9,"Frame",{BackgroundColor3=Color3.new(0.25098040699959,0.25098040699959,0.25098040699959),BackgroundTransparency=1,BorderColor3=Color3.new(0.37647062540054,0.37647062540054,0.37647062540054),Name="NumberLine",Parent={1},Position=UDim2.new(0,10,0,20),Size=UDim2.new(1,-20,0,170),}},
				{10,"Frame",{BackgroundColor3=Color3.new(0.14901961386204,0.14901961386204,0.14901961386204),BorderColor3=Color3.new(0.12549020349979,0.12549020349979,0.12549020349979),Name="Value",Parent={1},Position=UDim2.new(0,170,0,210),Size=UDim2.new(0,60,0,20),}},
				{11,"TextLabel",{BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=1,Font=3,Name="Title",Parent={10},Position=UDim2.new(0,-40,0,0),Size=UDim2.new(0,34,1,0),Text="Value",TextColor3=Color3.new(0.86274516582489,0.86274516582489,0.86274516582489),TextSize=14,TextXAlignment=1,}},
				{12,"TextBox",{BackgroundColor3=Color3.new(0.25098040699959,0.25098040699959,0.25098040699959),BackgroundTransparency=1,BorderColor3=Color3.new(0.37647062540054,0.37647062540054,0.37647062540054),ClipsDescendants=true,Font=3,Name="Input",Parent={10},Position=UDim2.new(0,2,0,0),Size=UDim2.new(0,58,0,20),Text="0",TextColor3=Color3.new(0.86274516582489,0.86274516582489,0.86274516582489),TextSize=14,TextXAlignment=0,}},
				{13,"Frame",{BackgroundColor3=Color3.new(0.14901961386204,0.14901961386204,0.14901961386204),BorderColor3=Color3.new(0.12549020349979,0.12549020349979,0.12549020349979),Name="Envelope",Parent={1},Position=UDim2.new(0,300,0,210),Size=UDim2.new(0,60,0,20),}},
				{14,"TextBox",{BackgroundColor3=Color3.new(0.25098040699959,0.25098040699959,0.25098040699959),BackgroundTransparency=1,BorderColor3=Color3.new(0.37647062540054,0.37647062540054,0.37647062540054),ClipsDescendants=true,Font=3,Name="Input",Parent={13},Position=UDim2.new(0,2,0,0),Size=UDim2.new(0,58,0,20),Text="0",TextColor3=Color3.new(0.86274516582489,0.86274516582489,0.86274516582489),TextSize=14,TextXAlignment=0,}},
				{15,"TextLabel",{BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=1,Font=3,Name="Title",Parent={13},Position=UDim2.new(0,-40,0,0),Size=UDim2.new(0,34,1,0),Text="Envelope",TextColor3=Color3.new(0.86274516582489,0.86274516582489,0.86274516582489),TextSize=14,TextXAlignment=1,}},
			})
			local window = Lib.Window.new()
			window.Resizable = false
			window:Resize(680,265)
			window:SetTitle("NumberSequence Editor")
			newMt.Window = window
			newMt.Gui = window.Gui
			for i,v in pairs(guiContents:GetChildren()) do
				v.Parent = window.GuiElems.Content
			end
			local gui = window.Gui
			local pickerGui = gui.Main
			local pickerTopBar = pickerGui.TopBar
			local pickerFrame = pickerGui.Content
			local numberLine = pickerFrame.NumberLine
			local numberLineOutlines = pickerFrame.NumberLineOutlines
			local timeBox = pickerFrame.Time.Input
			local valueBox = pickerFrame.Value.Input
			local envelopeBox = pickerFrame.Envelope.Input
			local deleteButton = pickerFrame.Delete
			local resetButton = pickerFrame.Reset
			local closeButton = pickerFrame.Close
			local topClose = pickerTopBar.Close

			local points = {{1,0,3},{8,0.05,1},{5,0.6,2},{4,0.7,4},{6,1,4}}
			local lines = {}
			local eLines = {}
			local beginPoint = points[1]
			local endPoint = points[#points]
			local currentlySelected = nil
			local currentPoint = nil
			local resetSequence = nil

			local user = service.UserInputService
			local mouse = service.Players.LocalPlayer:GetMouse()

			for i = 2,10 do
				local newLine = Instance.new("Frame")
				newLine.BackgroundTransparency = 0.5
				newLine.BackgroundColor3 = Color3.new(96/255,96/255,96/255)
				newLine.BorderSizePixel = 0
				newLine.Size = UDim2.new(0,1,1,0)
				newLine.Position = UDim2.new((i-1)/(11-1),0,0,0)
				newLine.Parent = numberLineOutlines
			end

			for i = 2,4 do
				local newLine = Instance.new("Frame")
				newLine.BackgroundTransparency = 0.5
				newLine.BackgroundColor3 = Color3.new(96/255,96/255,96/255)
				newLine.BorderSizePixel = 0
				newLine.Size = UDim2.new(1,0,0,1)
				newLine.Position = UDim2.new(0,0,(i-1)/(5-1),0)
				newLine.Parent = numberLineOutlines
			end

			local lineTemp = Instance.new("Frame")
			lineTemp.BackgroundColor3 = Color3.new(0,0,0)
			lineTemp.BorderSizePixel = 0
			lineTemp.Size = UDim2.new(0,1,0,1)

			local sequenceLine = Instance.new("Frame")
			sequenceLine.BackgroundColor3 = Color3.new(0,0,0)
			sequenceLine.BorderSizePixel = 0
			sequenceLine.Size = UDim2.new(0,1,0,0)

			for i = 1,numberLine.AbsoluteSize.X do
				local line = sequenceLine:Clone()
				eLines[i] = line
				line.Name = "E"..tostring(i)
				line.BackgroundTransparency = 0.5
				line.BackgroundColor3 = Color3.new(199/255,44/255,28/255)
				line.Position = UDim2.new(0,i-1,0,0)
				line.Parent = numberLine
			end

			for i = 1,numberLine.AbsoluteSize.X do
				local line = sequenceLine:Clone()
				lines[i] = line
				line.Name = tostring(i)
				line.Position = UDim2.new(0,i-1,0,0)
				line.Parent = numberLine
			end

			local envelopeDrag = Instance.new("Frame")
			envelopeDrag.BackgroundTransparency = 1
			envelopeDrag.BackgroundColor3 = Color3.new(0,0,0)
			envelopeDrag.BorderSizePixel = 0
			envelopeDrag.Size = UDim2.new(0,7,0,20)
			envelopeDrag.Visible = false
			envelopeDrag.ZIndex = 2
			local envelopeDragLine = Instance.new("Frame",envelopeDrag)
			envelopeDragLine.Name = "Line"
			envelopeDragLine.BackgroundColor3 = Color3.new(0,0,0)
			envelopeDragLine.BorderSizePixel = 0
			envelopeDragLine.Position = UDim2.new(0,3,0,0)
			envelopeDragLine.Size = UDim2.new(0,1,0,20)
			envelopeDragLine.ZIndex = 2

			local envelopeDragTop,envelopeDragBottom = envelopeDrag:Clone(),envelopeDrag:Clone()
			envelopeDragTop.Parent = numberLine
			envelopeDragBottom.Parent = numberLine

			local function buildSequence()
				local newPoints = {}
				for i,v in pairs(points) do
					table.insert(newPoints,NumberSequenceKeypoint.new(v[2],v[1],v[3]))
				end
				newMt.Sequence = NumberSequence.new(newPoints)
				newMt.OnSelect:Fire(newMt.Sequence)
			end

			local function round(num,places)
				local multi = 10^places
				return math.floor(num*multi + 0.5)/multi
			end

			local function updateInputs(point)
				if point then
					currentPoint = point
					local rawT,rawV,rawE = point[2],point[1],point[3]
					timeBox.Text = round(rawT,(rawT < 0.01 and 5) or (rawT < 0.1 and 4) or 3)
					valueBox.Text = round(rawV,(rawV < 0.01 and 5) or (rawV < 0.1 and 4) or (rawV < 1 and 3) or 2)
					envelopeBox.Text = round(rawE,(rawE < 0.01 and 5) or (rawE < 0.1 and 4) or (rawV < 1 and 3) or 2)

					local envelopeDistance = numberLine.AbsoluteSize.Y*(point[3]/10)
					envelopeDragTop.Position = UDim2.new(0,point[4].Position.X.Offset-1,0,point[4].Position.Y.Offset-envelopeDistance-17)
					envelopeDragTop.Visible = true
					envelopeDragBottom.Position = UDim2.new(0,point[4].Position.X.Offset-1,0,point[4].Position.Y.Offset+envelopeDistance+2)
					envelopeDragBottom.Visible = true
				end
			end

			envelopeDragTop.InputBegan:Connect(function(input)
				if (input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch) or not currentPoint or Lib.CheckMouseInGui(currentPoint[4].Select) then return end

				local mouseEvent, releaseEvent
				local maxSize = numberLine.AbsoluteSize.Y
				local mouseDelta = math.abs(envelopeDragTop.AbsolutePosition.Y - mouse.Y)

				envelopeDragTop.Line.Position = UDim2.new(0, 2, 0, 0)
				envelopeDragTop.Line.Size = UDim2.new(0, 3, 0, 20)

				releaseEvent = user.InputEnded:Connect(function(input)
					if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then return end
					mouseEvent:Disconnect()
					releaseEvent:Disconnect()
					envelopeDragTop.Line.Position = UDim2.new(0, 3, 0, 0)
					envelopeDragTop.Line.Size = UDim2.new(0, 1, 0, 20)
				end)

				mouseEvent = user.InputChanged:Connect(function(input)
					if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
						local topDiff = (currentPoint[4].AbsolutePosition.Y + 2) - (mouse.Y - mouseDelta) - 19
						local newEnvelope = 10 * (math.max(topDiff, 0) / maxSize)
						local maxEnvelope = math.min(currentPoint[1], 10 - currentPoint[1])
						currentPoint[3] = math.min(newEnvelope, maxEnvelope)
						newMt:Redraw()
						buildSequence()
						updateInputs(currentPoint)
					end
				end)
			end)

			envelopeDragBottom.InputBegan:Connect(function(input)
				if (input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch) or not currentPoint or Lib.CheckMouseInGui(currentPoint[4].Select) then return end

				local mouseEvent, releaseEvent
				local maxSize = numberLine.AbsoluteSize.Y
				local mouseDelta = math.abs(envelopeDragBottom.AbsolutePosition.Y - mouse.Y)

				envelopeDragBottom.Line.Position = UDim2.new(0, 2, 0, 0)
				envelopeDragBottom.Line.Size = UDim2.new(0, 3, 0, 20)

				releaseEvent = user.InputEnded:Connect(function(input)
					if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then return end
					mouseEvent:Disconnect()
					releaseEvent:Disconnect()
					envelopeDragBottom.Line.Position = UDim2.new(0, 3, 0, 0)
					envelopeDragBottom.Line.Size = UDim2.new(0, 1, 0, 20)
				end)

				mouseEvent = user.InputChanged:Connect(function(input)
					if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
						local bottomDiff = (mouse.Y + (20 - mouseDelta)) - (currentPoint[4].AbsolutePosition.Y + 2) - 19
						local newEnvelope = 10 * (math.max(bottomDiff, 0) / maxSize)
						local maxEnvelope = math.min(currentPoint[1], 10 - currentPoint[1])
						currentPoint[3] = math.min(newEnvelope, maxEnvelope)
						newMt:Redraw()
						buildSequence()
						updateInputs(currentPoint)
					end
				end)
			end)

			local function placePoint(point)
				local newPoint = Instance.new("Frame")
				newPoint.Name = "Point"
				newPoint.BorderSizePixel = 0
				newPoint.Size = UDim2.new(0,5,0,5)
				newPoint.Position = UDim2.new(0,math.floor((numberLine.AbsoluteSize.X-1) * point[2])-2,0,numberLine.AbsoluteSize.Y*(10-point[1])/10-2)
				newPoint.BackgroundColor3 = Color3.new(0,0,0)

				local newSelect = Instance.new("Frame")
				newSelect.Name = "Select"
				newSelect.BackgroundTransparency = 1
				newSelect.BackgroundColor3 = Color3.new(199/255,44/255,28/255)
				newSelect.Position = UDim2.new(0,-2,0,-2)
				newSelect.Size = UDim2.new(0,9,0,9)
				newSelect.Parent = newPoint

				newPoint.Parent = numberLine


				newSelect.InputBegan:Connect(function(input)
					if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
						for i, v in pairs(points) do 
							v[4].Select.BackgroundTransparency = 1 
						end

						newSelect.BackgroundTransparency = 0
						updateInputs(point)
					end

					if (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) and not currentlySelected then
						currentPoint = point
						local mouseEvent, releaseEvent
						currentlySelected = true
						newSelect.BackgroundColor3 = Color3.new(249/255, 191/255, 59/255)

						local oldEnvelope = point[3]

						releaseEvent = user.InputEnded:Connect(function(input)
							if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then	return end

							mouseEvent:Disconnect()
							releaseEvent:Disconnect()
							currentlySelected = nil
							newSelect.BackgroundColor3 = Color3.new(199/255, 44/255, 28/255)
						end)

						mouseEvent = user.InputChanged:Connect(function(input)
							if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
								local maxX = numberLine.AbsoluteSize.X - 1
								local relativeX = (input.Position.X - numberLine.AbsolutePosition.X)
								if relativeX < 0 then relativeX = 0 end
								if relativeX > maxX then relativeX = maxX end

								local maxY = numberLine.AbsoluteSize.Y - 1
								local relativeY = (input.Position.Y - numberLine.AbsolutePosition.Y)
								if relativeY < 0 then relativeY = 0 end
								if relativeY > maxY then relativeY = maxY end

								if point ~= beginPoint and point ~= endPoint then
									point[2] = relativeX / maxX
								end

								point[1] = 10 - (relativeY / maxY) * 10
								local maxEnvelope = math.min(point[1], 10 - point[1])
								point[3] = math.min(oldEnvelope, maxEnvelope)
								newMt:Redraw()
								updateInputs(point)

								for i, v in pairs(points) do 
									v[4].Select.BackgroundTransparency = 1 
								end

								newSelect.BackgroundTransparency = 0
								buildSequence()
							end
						end)
					end
				end)

				return newPoint
			end

			local function placePoints()
				for i,v in pairs(points) do
					v[4] = placePoint(v)
				end
			end

			local function redraw(self)
				local numberLineSize = numberLine.AbsoluteSize
				table.sort(points,function(a,b) return a[2] < b[2] end)
				for i,v in pairs(points) do
					v[4].Position = UDim2.new(0,math.floor((numberLineSize.X-1) * v[2])-2,0,(numberLineSize.Y-1)*(10-v[1])/10-2)
				end
				lines[1].Size = UDim2.new(0,1,0,0)
				for i = 1,#points-1 do
					local fromPoint = points[i]
					local toPoint = points[i+1]
					local deltaY = toPoint[4].Position.Y.Offset-fromPoint[4].Position.Y.Offset
					local deltaX = toPoint[4].Position.X.Offset-fromPoint[4].Position.X.Offset
					local slope = deltaY/deltaX

					local fromEnvelope = fromPoint[3]
					local nextEnvelope = toPoint[3]

					local currentRise = math.abs(slope)
					local totalRise = 0
					local maxRise = math.abs(toPoint[4].Position.Y.Offset-fromPoint[4].Position.Y.Offset)

					for lineCount = math.min(fromPoint[4].Position.X.Offset+1,toPoint[4].Position.X.Offset),toPoint[4].Position.X.Offset do
						if deltaX == 0 and deltaY == 0 then return end
						local riseNow = math.floor(currentRise)
						local line = lines[lineCount+3]
						if line then
							if totalRise+riseNow > maxRise then riseNow = maxRise-totalRise end
							if math.sign(slope) == -1 then
								line.Position = UDim2.new(0,lineCount+2,0,fromPoint[4].Position.Y.Offset + -(totalRise+riseNow)+2)
							else
								line.Position = UDim2.new(0,lineCount+2,0,fromPoint[4].Position.Y.Offset + totalRise+2)
							end
							line.Size = UDim2.new(0,1,0,math.max(riseNow,1))
						end
						totalRise = totalRise + riseNow
						currentRise = currentRise - riseNow + math.abs(slope)

						local envPercent = (lineCount-fromPoint[4].Position.X.Offset)/(toPoint[4].Position.X.Offset-fromPoint[4].Position.X.Offset)
						local envLerp = fromEnvelope+(nextEnvelope-fromEnvelope)*envPercent
						local relativeSize = (envLerp/10)*numberLineSize.Y						

						local line = eLines[lineCount + 3]
						if line then
							line.Position = UDim2.new(0,lineCount+2,0,lines[lineCount+3].Position.Y.Offset-math.floor(relativeSize))
							line.Size = UDim2.new(0,1,0,math.floor(relativeSize*2))
						end
					end
				end
			end
			newMt.Redraw = redraw



			local function loadSequence(self,seq)
				resetSequence = seq
				for i,v in pairs(points) do if v[4] then v[4]:Destroy() end end
				points = {}
				for i,v in pairs(seq.Keypoints) do
					local maxEnvelope = math.min(v.Value,10-v.Value)
					local newPoint = {v.Value,v.Time,math.min(v.Envelope,maxEnvelope)}
					newPoint[4] = placePoint(newPoint)
					table.insert(points,newPoint)
				end
				beginPoint = points[1]
				endPoint = points[#points]
				currentlySelected = nil
				redraw()
				envelopeDragTop.Visible = false
				envelopeDragBottom.Visible = false
			end
			newMt.SetSequence = loadSequence

			timeBox.FocusLost:Connect(function()
				local point = currentPoint
				local num = tonumber(timeBox.Text)
				if point and num and point ~= beginPoint and point ~= endPoint then
					num = math.clamp(num,0,1)
					point[2] = num
					redraw()
					buildSequence()
					updateInputs(point)
				end
			end)

			valueBox.FocusLost:Connect(function()
				local point = currentPoint
				local num = tonumber(valueBox.Text)
				if point and num then
					local oldEnvelope = point[3]
					num = math.clamp(num,0,10)
					point[1] = num
					local maxEnvelope = math.min(point[1],10-point[1])
					point[3] = math.min(oldEnvelope,maxEnvelope)
					redraw()
					buildSequence()
					updateInputs(point)
				end
			end)

			envelopeBox.FocusLost:Connect(function()
				local point = currentPoint
				local num = tonumber(envelopeBox.Text)
				if point and num then
					num = math.clamp(num,0,5)
					local maxEnvelope = math.min(point[1],10-point[1])
					point[3] = math.min(num,maxEnvelope)
					redraw()
					buildSequence()
					updateInputs(point)
				end
			end)

			local function buttonAnimations(button,inverse)
				button.InputBegan:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then button.BackgroundTransparency = (inverse and 0.5 or 0.4) end end)
				button.InputEnded:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then button.BackgroundTransparency = (inverse and 1 or 0) end end)
			end

			numberLine.InputBegan:Connect(function(input)
				if (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) and #points < 20 then

					if Lib.CheckMouseInGui(envelopeDragTop) or Lib.CheckMouseInGui(envelopeDragBottom) then return end

					for i, v in pairs(points) do
						if Lib.CheckMouseInGui(v[4].Select) then
							return
						end
					end

					local maxX = numberLine.AbsoluteSize.X - 1
					local relativeX = (input.Position.X - numberLine.AbsolutePosition.X)
					if relativeX < 0 then relativeX = 0 end
					if relativeX > maxX then relativeX = maxX end

					local maxY = numberLine.AbsoluteSize.Y - 1
					local relativeY = (input.Position.Y - numberLine.AbsolutePosition.Y)
					if relativeY < 0 then relativeY = 0 end
					if relativeY > maxY then relativeY = maxY end

					local raw = relativeX / maxX
					local newPoint = {10 - (relativeY / maxY) * 10, raw, 0}
					newPoint[4] = placePoint(newPoint)
					table.insert(points, newPoint)
					redraw()
					buildSequence()
				end
			end)

			deleteButton.MouseButton1Click:Connect(function()
				if currentPoint and currentPoint ~= beginPoint and currentPoint ~= endPoint then
					for i,v in pairs(points) do
						if v == currentPoint then
							v[4]:Destroy()
							table.remove(points,i)
							break
						end
					end
					currentlySelected = nil
					redraw()
					buildSequence()
					updateInputs(points[1])
				end
			end)

			resetButton.MouseButton1Click:Connect(function()
				if resetSequence then
					newMt:SetSequence(resetSequence)
					buildSequence()
				end
			end)

			closeButton.MouseButton1Click:Connect(function()
				window:Close()
			end)

			buttonAnimations(deleteButton)
			buttonAnimations(resetButton)
			buttonAnimations(closeButton)

			placePoints()
			redraw()

			newMt.Show = function(self)
				window:Show()
			end

			return newMt
		end

		return {new = new}
	end)()

	Lib.ColorSequenceEditor = (function() -- TODO: Convert to newer class model
		local function new()
			local newMt = setmetatable({},{})
			newMt.OnSelect = Lib.Signal.new()
			newMt.OnCancel = Lib.Signal.new()
			newMt.OnPreview = Lib.Signal.new()
			newMt.OnPickColor = Lib.Signal.new()

			local guiContents = create({
				{1,"Frame",{BackgroundColor3=Color3.new(0.17647059261799,0.17647059261799,0.17647059261799),BorderSizePixel=0,ClipsDescendants=true,Name="Content",Position=UDim2.new(0,0,0,20),Size=UDim2.new(1,0,1,-20),}},
				{2,"Frame",{BackgroundColor3=Color3.new(0.17647059261799,0.17647059261799,0.17647059261799),BorderColor3=Color3.new(0.21568627655506,0.21568627655506,0.21568627655506),Name="ColorLine",Parent={1},Position=UDim2.new(0,10,0,5),Size=UDim2.new(1,-20,0,70),}},
				{3,"Frame",{BackgroundColor3=Color3.new(1,1,1),BorderSizePixel=0,Name="Gradient",Parent={2},Size=UDim2.new(1,0,1,0),}},
				{4,"UIGradient",{Parent={3},}},
				{5,"Frame",{BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=1,BorderSizePixel=0,Name="Arrows",Parent={1},Position=UDim2.new(0,1,0,73),Size=UDim2.new(1,-2,0,16),}},
				{6,"Frame",{BackgroundColor3=Color3.new(0,0,0),BackgroundTransparency=0.5,BorderSizePixel=0,Name="Cursor",Parent={1},Position=UDim2.new(0,10,0,0),Size=UDim2.new(0,1,0,80),}},
				{7,"Frame",{BackgroundColor3=Color3.new(0.14901961386204,0.14901961386204,0.14901961386204),BorderColor3=Color3.new(0.12549020349979,0.12549020349979,0.12549020349979),Name="Time",Parent={1},Position=UDim2.new(0,40,0,95),Size=UDim2.new(0,100,0,20),}},
				{8,"TextBox",{BackgroundColor3=Color3.new(0.25098040699959,0.25098040699959,0.25098040699959),BackgroundTransparency=1,BorderColor3=Color3.new(0.37647062540054,0.37647062540054,0.37647062540054),ClipsDescendants=true,Font=3,Name="Input",Parent={7},Position=UDim2.new(0,2,0,0),Size=UDim2.new(0,98,0,20),Text="0",TextColor3=Color3.new(0.86274516582489,0.86274516582489,0.86274516582489),TextSize=14,TextXAlignment=0,}},
				{9,"TextLabel",{BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=1,Font=3,Name="Title",Parent={7},Position=UDim2.new(0,-40,0,0),Size=UDim2.new(0,34,1,0),Text="Time",TextColor3=Color3.new(0.86274516582489,0.86274516582489,0.86274516582489),TextSize=14,TextXAlignment=1,}},
				{10,"Frame",{BackgroundColor3=Color3.new(1,1,1),BorderColor3=Color3.new(0.21568627655506,0.21568627655506,0.21568627655506),Name="ColorBox",Parent={1},Position=UDim2.new(0,220,0,95),Size=UDim2.new(0,20,0,20),}},
				{11,"TextLabel",{BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=1,Font=3,Name="Title",Parent={10},Position=UDim2.new(0,-40,0,0),Size=UDim2.new(0,34,1,0),Text="Color",TextColor3=Color3.new(0.86274516582489,0.86274516582489,0.86274516582489),TextSize=14,TextXAlignment=1,}},
				{12,"TextButton",{AutoButtonColor=false,BackgroundColor3=Color3.new(0.2352941185236,0.2352941185236,0.2352941185236),BorderColor3=Color3.new(0.21568627655506,0.21568627655506,0.21568627655506),BorderSizePixel=0,Font=3,Name="Close",Parent={1},Position=UDim2.new(1,-90,0,95),Size=UDim2.new(0,80,0,20),Text="Close",TextColor3=Color3.new(0.86274516582489,0.86274516582489,0.86274516582489),TextSize=14,}},
				{13,"TextButton",{AutoButtonColor=false,BackgroundColor3=Color3.new(0.2352941185236,0.2352941185236,0.2352941185236),BorderColor3=Color3.new(0.21568627655506,0.21568627655506,0.21568627655506),BorderSizePixel=0,Font=3,Name="Reset",Parent={1},Position=UDim2.new(1,-180,0,95),Size=UDim2.new(0,80,0,20),Text="Reset",TextColor3=Color3.new(0.86274516582489,0.86274516582489,0.86274516582489),TextSize=14,}},
				{14,"TextButton",{AutoButtonColor=false,BackgroundColor3=Color3.new(0.2352941185236,0.2352941185236,0.2352941185236),BorderColor3=Color3.new(0.21568627655506,0.21568627655506,0.21568627655506),BorderSizePixel=0,Font=3,Name="Delete",Parent={1},Position=UDim2.new(0,280,0,95),Size=UDim2.new(0,80,0,20),Text="Delete",TextColor3=Color3.new(0.86274516582489,0.86274516582489,0.86274516582489),TextSize=14,}},
				{15,"Frame",{BackgroundTransparency=1,Name="Arrow",Parent={1},Size=UDim2.new(0,16,0,16),Visible=false,}},
				{16,"Frame",{BackgroundColor3=Color3.new(0.86274510622025,0.86274510622025,0.86274510622025),BorderSizePixel=0,Parent={15},Position=UDim2.new(0,8,0,3),Size=UDim2.new(0,1,0,2),}},
				{17,"Frame",{BackgroundColor3=Color3.new(0.86274510622025,0.86274510622025,0.86274510622025),BorderSizePixel=0,Parent={15},Position=UDim2.new(0,7,0,5),Size=UDim2.new(0,3,0,2),}},
				{18,"Frame",{BackgroundColor3=Color3.new(0.86274510622025,0.86274510622025,0.86274510622025),BorderSizePixel=0,Parent={15},Position=UDim2.new(0,6,0,7),Size=UDim2.new(0,5,0,2),}},
				{19,"Frame",{BackgroundColor3=Color3.new(0.86274510622025,0.86274510622025,0.86274510622025),BorderSizePixel=0,Parent={15},Position=UDim2.new(0,5,0,9),Size=UDim2.new(0,7,0,2),}},
				{20,"Frame",{BackgroundColor3=Color3.new(0.86274510622025,0.86274510622025,0.86274510622025),BorderSizePixel=0,Parent={15},Position=UDim2.new(0,4,0,11),Size=UDim2.new(0,9,0,2),}},
			})
			local window = Lib.Window.new()
			window.Resizable = false
			window:Resize(650,150)
			window:SetTitle("ColorSequence Editor")
			newMt.Window = window
			newMt.Gui = window.Gui
			for i,v in pairs(guiContents:GetChildren()) do
				v.Parent = window.GuiElems.Content
			end
			local gui = window.Gui
			local pickerGui = gui.Main
			local pickerTopBar = pickerGui.TopBar
			local pickerFrame = pickerGui.Content
			local colorLine = pickerFrame.ColorLine
			local gradient = colorLine.Gradient.UIGradient
			local arrowFrame = pickerFrame.Arrows
			local arrow = pickerFrame.Arrow
			local cursor = pickerFrame.Cursor
			local timeBox = pickerFrame.Time.Input
			local colorBox = pickerFrame.ColorBox
			local deleteButton = pickerFrame.Delete
			local resetButton = pickerFrame.Reset
			local closeButton = pickerFrame.Close
			local topClose = pickerTopBar.Close

			local user = service.UserInputService
			local mouse = service.Players.LocalPlayer:GetMouse()

			local colors = {{Color3.new(1,0,1),0},{Color3.new(0.2,0.9,0.2),0.2},{Color3.new(0.4,0.5,0.9),0.7},{Color3.new(0.6,1,1),1}}
			local resetSequence = nil

			local beginPoint = colors[1]
			local endPoint = colors[#colors]

			local currentlySelected = nil
			local currentPoint = nil

			local sequenceLine = Instance.new("Frame")
			sequenceLine.BorderSizePixel = 0
			sequenceLine.Size = UDim2.new(0,1,1,0)

			newMt.Sequence = ColorSequence.new(Color3.new(1,1,1))
			local function buildSequence(noupdate)
				local newPoints = {}
				table.sort(colors,function(a,b) return a[2] < b[2] end)
				for i,v in pairs(colors) do
					table.insert(newPoints,ColorSequenceKeypoint.new(v[2],v[1]))
				end
				newMt.Sequence = ColorSequence.new(newPoints)
				if not noupdate then newMt.OnSelect:Fire(newMt.Sequence) end
			end

			local function round(num,places)
				local multi = 10^places
				return math.floor(num*multi + 0.5)/multi
			end

			local function updateInputs(point)
				if point then
					currentPoint = point
					local raw = point[2]
					timeBox.Text = round(raw,(raw < 0.01 and 5) or (raw < 0.1 and 4) or 3)
					colorBox.BackgroundColor3 = point[1]
				end
			end

			local function placeArrow(ind,point)
				local newArrow = arrow:Clone()
				newArrow.Position = UDim2.new(0,ind-1,0,0)
				newArrow.Visible = true
				newArrow.Parent = arrowFrame

				newArrow.InputBegan:Connect(function(input)
					if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
						cursor.Visible = true
						cursor.Position = UDim2.new(0, 9 + newArrow.Position.X.Offset, 0, 0)
					end

					if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
						updateInputs(point)
						if point == beginPoint or point == endPoint or currentlySelected then return end

						local mouseEvent, releaseEvent
						currentlySelected = true

						releaseEvent = user.InputEnded:Connect(function(input)
							if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then return end
							mouseEvent:Disconnect()
							releaseEvent:Disconnect()
							currentlySelected = nil
							cursor.Visible = false
						end)

						mouseEvent = user.InputChanged:Connect(function(input)
							if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
								local maxSize = colorLine.AbsoluteSize.X - 1
								local relativeX = (input.Position.X - colorLine.AbsolutePosition.X)
								if relativeX < 0 then relativeX = 0 end
								if relativeX > maxSize then relativeX = maxSize end
								local raw = relativeX / maxSize
								point[2] = relativeX / maxSize
								updateInputs(point)
								cursor.Visible = true
								cursor.Position = UDim2.new(0, 9 + newArrow.Position.X.Offset, 0, 0)
								buildSequence()
								newMt:Redraw()
							end
						end)
					end
				end)

				newArrow.InputEnded:Connect(function(input)
					if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
						cursor.Visible = false
					end
				end)



				return newArrow
			end

			local function placeArrows()
				for i,v in pairs(colors) do
					v[3] = placeArrow(math.floor((colorLine.AbsoluteSize.X-1) * v[2]) + 1,v)
				end
			end

			local function redraw(self)
				gradient.Color = newMt.Sequence or ColorSequence.new(Color3.new(1,1,1))

				for i = 2,#colors do
					local nextColor = colors[i]
					local endPos = math.floor((colorLine.AbsoluteSize.X-1) * nextColor[2]) + 1
					nextColor[3].Position = UDim2.new(0,endPos,0,0)
				end		
			end
			newMt.Redraw = redraw

			local function loadSequence(self,seq)
				resetSequence = seq
				for i,v in pairs(colors) do if v[3] then v[3]:Destroy() end end
				colors = {}
				currentlySelected = nil
				for i,v in pairs(seq.Keypoints) do
					local newPoint = {v.Value,v.Time}
					newPoint[3] = placeArrow(v.Time,newPoint)
					table.insert(colors,newPoint)
				end
				beginPoint = colors[1]
				endPoint = colors[#colors]
				currentlySelected = nil
				updateInputs(colors[1])
				buildSequence(true)
				redraw()
			end
			newMt.SetSequence = loadSequence

			local function buttonAnimations(button,inverse)
				button.InputBegan:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then button.BackgroundTransparency = (inverse and 0.5 or 0.4) end end)
				button.InputEnded:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then button.BackgroundTransparency = (inverse and 1 or 0) end end)
			end

			colorLine.InputBegan:Connect(function(input)
				if (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) and #colors < 20 then
					local maxSize = colorLine.AbsoluteSize.X - 1
					local relativeX = (input.Position.X - colorLine.AbsolutePosition.X)
					if relativeX < 0 then relativeX = 0 end
					if relativeX > maxSize then relativeX = maxSize end

					local raw = relativeX / maxSize
					local fromColor = nil
					local toColor = nil
					for i, col in pairs(colors) do
						if col[2] >= raw then
							fromColor = colors[math.max(i - 1, 1)]
							toColor = colors[i]
							break
						end
					end
					local lerpColor = fromColor[1]:lerp(toColor[1], (raw - fromColor[2]) / (toColor[2] - fromColor[2]))
					local newPoint = {lerpColor, raw}
					newPoint[3] = placeArrow(newPoint[2], newPoint)
					table.insert(colors, newPoint)
					updateInputs(newPoint)
					buildSequence()
					redraw()
				end
			end)

			colorLine.InputChanged:Connect(function(input)
				if (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
					local maxSize = colorLine.AbsoluteSize.X - 1
					local relativeX = (input.Position.X - colorLine.AbsolutePosition.X)
					if relativeX < 0 then relativeX = 0 end
					if relativeX > maxSize then relativeX = maxSize end
					cursor.Visible = true
					cursor.Position = UDim2.new(0, 10 + relativeX, 0, 0)
				end
			end)

			colorLine.InputEnded:Connect(function(input)
				if (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
					local inArrow = false
					for i, v in pairs(colors) do
						if Lib.CheckMouseInGui(v[3]) then
							inArrow = v[3]
						end
					end
					cursor.Visible = inArrow and true or false
					if inArrow then cursor.Position = UDim2.new(0, 9 + inArrow.Position.X.Offset, 0, 0) end
				end
			end)

			timeBox:GetPropertyChangedSignal("Text"):Connect(function()
				local point = currentPoint
				local num = tonumber(timeBox.Text)
				if point and num and point ~= beginPoint and point ~= endPoint then
					num = math.clamp(num,0,1)
					point[2] = num
					buildSequence()
					redraw()
				end
			end)

			colorBox.InputBegan:Connect(function(input)
				if (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then
					local editor = newMt.ColorPicker
					if not editor then
						editor = Lib.ColorPicker.new()
						editor.Window:SetTitle("ColorSequence Color Picker")

						editor.OnSelect:Connect(function(col)
							if currentPoint then
								currentPoint[1] = col
							end
							buildSequence()
							redraw()
						end)

						newMt.ColorPicker = editor
					end

					editor.Window:ShowAndFocus()
				end
			end)

			deleteButton.MouseButton1Click:Connect(function()
				if currentPoint and currentPoint ~= beginPoint and currentPoint ~= endPoint then
					for i,v in pairs(colors) do
						if v == currentPoint then
							v[3]:Destroy()
							table.remove(colors,i)
							break
						end
					end
					currentlySelected = nil
					updateInputs(colors[1])
					buildSequence()
					redraw()
				end
			end)

			resetButton.MouseButton1Click:Connect(function()
				if resetSequence then
					newMt:SetSequence(resetSequence)
				end
			end)

			closeButton.MouseButton1Click:Connect(function()
				window:Close()
			end)

			topClose.MouseButton1Click:Connect(function()
				window:Close()
			end)

			buttonAnimations(deleteButton)
			buttonAnimations(resetButton)
			buttonAnimations(closeButton)

			placeArrows()
			redraw()

			newMt.Show = function(self)
				window:Show()
			end

			return newMt
		end

		return {new = new}
	end)()

	Lib.ViewportTextBox = (function()
		local textService = service.TextService

		local props = {
			OffsetX = 0,
			TextBox = PH,
			CursorPos = -1,
			Gui = PH,
			View = PH
		}
		local funcs = {}
		funcs.Update = function(self)
			local cursorPos = self.CursorPos or -1
			local text = self.TextBox.Text
			if text == "" then self.TextBox.Position = UDim2.new(0,0,0,0) return end
			if cursorPos == -1 then return end

			local cursorText = text:sub(1,cursorPos-1)
			local pos = nil
			local leftEnd = -self.TextBox.Position.X.Offset
			local rightEnd = leftEnd + self.View.AbsoluteSize.X

			local totalTextSize = textService:GetTextSize(text,self.TextBox.TextSize,self.TextBox.Font,Vector2.new(999999999,100)).X
			local cursorTextSize = textService:GetTextSize(cursorText,self.TextBox.TextSize,self.TextBox.Font,Vector2.new(999999999,100)).X

			if cursorTextSize > rightEnd then
				pos = math.max(-1,cursorTextSize - self.View.AbsoluteSize.X + 2)
			elseif cursorTextSize < leftEnd then
				pos = math.max(-1,cursorTextSize-2)
			elseif totalTextSize < rightEnd then
				pos = math.max(-1,totalTextSize - self.View.AbsoluteSize.X + 2)
			end

			if pos then
				self.TextBox.Position = UDim2.new(0,-pos,0,0)
				self.TextBox.Size = UDim2.new(1,pos,1,0)
			end
		end

		funcs.GetText = function(self)
			return self.TextBox.Text
		end

		funcs.SetText = function(self,text)
			self.TextBox.Text = text
		end

		local mt = getGuiMT(props,funcs)

		local function convert(textbox)
			local obj = initObj(props,mt)

			local view = Instance.new("Frame")
			view.BackgroundTransparency = textbox.BackgroundTransparency
			view.BackgroundColor3 = textbox.BackgroundColor3
			view.BorderSizePixel = textbox.BorderSizePixel
			view.BorderColor3 = textbox.BorderColor3
			view.Position = textbox.Position
			view.Size = textbox.Size
			view.ClipsDescendants = true
			view.Name = textbox.Name
			textbox.BackgroundTransparency = 1
			textbox.Position = UDim2.new(0,0,0,0)
			textbox.Size = UDim2.new(1,0,1,0)
			textbox.TextXAlignment = Enum.TextXAlignment.Left
			textbox.Name = "Input"

			obj.TextBox = textbox
			obj.View = view
			obj.Gui = view

			textbox.Changed:Connect(function(prop)
				if prop == "Text" or prop == "CursorPosition" or prop == "AbsoluteSize" then
					local cursorPos = obj.TextBox.CursorPosition
					if cursorPos ~= -1 then obj.CursorPos = cursorPos end
					obj:Update()
				end
			end)

			obj:Update()

			view.Parent = textbox.Parent
			textbox.Parent = view

			return obj
		end

		local function new()
			local textBox = Instance.new("TextBox")
			textBox.Active = true
			textBox.Size = UDim2.new(0,100,0,20)
			textBox.BackgroundColor3 = Settings.Theme.TextBox
			textBox.BorderColor3 = Settings.Theme.Outline3
			textBox.ClearTextOnFocus = false
			textBox.TextColor3 = Settings.Theme.Text
			textBox.Font = Enum.Font.SourceSans
			textBox.TextSize = 14
			textBox.Text = ""
			return convert(textBox)
		end

		return {new = new, convert = convert}
	end)()

	Lib.Label = (function()
		local props,funcs = {},{}

		local mt = getGuiMT(props,funcs)

		local function new()
			local label = Instance.new("TextLabel")
			label.BackgroundTransparency = 1
			label.TextXAlignment = Enum.TextXAlignment.Left
			label.TextColor3 = Settings.Theme.Text
			label.TextTransparency = 0.1
			label.Size = UDim2.new(0,100,0,20)
			label.Font = Enum.Font.SourceSans
			label.TextSize = 14

			local obj = setmetatable({
				Gui = label
			},mt)
			return obj
		end

		return {new = new}
	end)()

	Lib.Frame = (function()
		local props,funcs = {},{}

		local mt = getGuiMT(props,funcs)

		local function new()
			local fr = Instance.new("Frame")
			fr.BackgroundColor3 = Settings.Theme.Main1
			fr.BorderColor3 = Settings.Theme.Outline1
			fr.Size = UDim2.new(0,50,0,50)

			local obj = setmetatable({
				Gui = fr
			},mt)
			return obj
		end

		return {new = new}
	end)()

	Lib.Button = (function()
		local props = {
			Gui = PH,
			Anim = PH,
			Disabled = false,
			OnClick = SIGNAL,
			OnDown = SIGNAL,
			OnUp = SIGNAL,
			AllowedButtons = {1}
		}
		local funcs = {}
		local tableFind = table.find

		funcs.Trigger = function(self,event,button)
			if not self.Disabled and tableFind(self.AllowedButtons,button) then
				self["On"..event]:Fire(button)
			end
		end

		funcs.SetDisabled = function(self,dis)
			self.Disabled = dis

			if dis then
				self.Anim:Disable()
				self.Gui.TextTransparency = 0.5
			else
				self.Anim.Enable()
				self.Gui.TextTransparency = 0
			end
		end

		local mt = getGuiMT(props,funcs)

		local function new()
			local b = Instance.new("TextButton")
			b.AutoButtonColor = false
			b.TextColor3 = Settings.Theme.Text
			b.TextTransparency = 0.1
			b.Size = UDim2.new(0,100,0,20)
			b.Font = Enum.Font.SourceSans
			b.TextSize = 14
			b.BackgroundColor3 = Settings.Theme.Button
			b.BorderColor3 = Settings.Theme.Outline2

			local obj = initObj(props,mt)
			obj.Gui = b
			obj.Anim = Lib.ButtonAnim(b,{Mode = 2, StartColor = Settings.Theme.Button, HoverColor = Settings.Theme.ButtonHover, PressColor = Settings.Theme.ButtonPress, OutlineColor = Settings.Theme.Outline2})

			b.MouseButton1Click:Connect(function() obj:Trigger("Click",1) end)
			b.MouseButton1Down:Connect(function() obj:Trigger("Down",1) end)
			b.MouseButton1Up:Connect(function() obj:Trigger("Up",1) end)

			b.MouseButton2Click:Connect(function() obj:Trigger("Click",2) end)
			b.MouseButton2Down:Connect(function() obj:Trigger("Down",2) end)
			b.MouseButton2Up:Connect(function() obj:Trigger("Up",2) end)

			return obj
		end

		return {new = new}
	end)()

	Lib.DropDown = (function()
		local props = {
			Gui = PH,
			Anim = PH,
			Context = PH,
			Selected = PH,
			Disabled = false,
			CanBeEmpty = true,
			Options = {},
			GuiElems = {},
			OnSelect = SIGNAL
		}
		local funcs = {}

		funcs.Update = function(self)
			local options = self.Options

			if #options > 0 then
				if not self.Selected then
					if not self.CanBeEmpty then
						self.Selected = options[1]
						self.GuiElems.Label.Text = options[1]
					else
						self.GuiElems.Label.Text = "- Select -"
					end
				else
					self.GuiElems.Label.Text = self.Selected
				end
			else
				self.GuiElems.Label.Text = "- Select -"
			end
		end

		funcs.ShowOptions = function(self)
			local context = self.Context

			context.Width = self.Gui.AbsoluteSize.X
			context.ReverseYOffset = self.Gui.AbsoluteSize.Y
			context:Show(self.Gui.AbsolutePosition.X, self.Gui.AbsolutePosition.Y + context.ReverseYOffset)
		end

		funcs.SetOptions = function(self,opts)
			self.Options = opts

			local context = self.Context
			local options = self.Options
			context:Clear()

			local onClick = function(option) self.Selected = option self.OnSelect:Fire(option) self:Update() end

			if self.CanBeEmpty then
				context:Add({Name = "- Select -", function() self.Selected = nil self.OnSelect:Fire(nil) self:Update() end})
			end

			for i = 1,#options do
				context:Add({Name = options[i], OnClick = onClick})
			end

			self:Update()
		end

		funcs.SetSelected = function(self,opt)
			self.Selected = type(opt) == "number" and self.Options[opt] or opt
			self:Update()
		end

		local mt = getGuiMT(props,funcs)

		local function new()
			local f = Instance.new("TextButton")
			f.AutoButtonColor = false
			f.Text = ""
			f.Size = UDim2.new(0,100,0,20)
			f.BackgroundColor3 = Settings.Theme.TextBox
			f.BorderColor3 = Settings.Theme.Outline3

			local label = Lib.Label.new()
			label.Position = UDim2.new(0,2,0,0)
			label.Size = UDim2.new(1,-22,1,0)
			label.TextTruncate = Enum.TextTruncate.AtEnd
			label.Parent = f
			local arrow = create({
				{1,"Frame",{BackgroundTransparency=1,Name="EnumArrow",Position=UDim2.new(1,-16,0,2),Size=UDim2.new(0,16,0,16),}},
				{2,"Frame",{BackgroundColor3=Color3.new(0.86274510622025,0.86274510622025,0.86274510622025),BorderSizePixel=0,Parent={1},Position=UDim2.new(0,8,0,9),Size=UDim2.new(0,1,0,1),}},
				{3,"Frame",{BackgroundColor3=Color3.new(0.86274510622025,0.86274510622025,0.86274510622025),BorderSizePixel=0,Parent={1},Position=UDim2.new(0,7,0,8),Size=UDim2.new(0,3,0,1),}},
				{4,"Frame",{BackgroundColor3=Color3.new(0.86274510622025,0.86274510622025,0.86274510622025),BorderSizePixel=0,Parent={1},Position=UDim2.new(0,6,0,7),Size=UDim2.new(0,5,0,1),}},
			})
			arrow.Parent = f

			local obj = initObj(props,mt)
			obj.Gui = f
			obj.Anim = Lib.ButtonAnim(f,{Mode = 2, StartColor = Settings.Theme.TextBox, LerpTo = Settings.Theme.Button, LerpDelta = 0.15})
			obj.Context = Lib.ContextMenu.new()
			obj.Context.Iconless = true
			obj.Context.MaxHeight = 200
			obj.Selected = nil
			obj.GuiElems = {Label = label}
			f.MouseButton1Down:Connect(function() obj:ShowOptions() end)
			obj:Update()
			return obj
		end

		return {new = new}
	end)()

	Lib.ClickSystem = (function()
		local props = {
			LastItem = PH,
			OnDown = SIGNAL,
			OnRelease = SIGNAL,
			AllowedButtons = {1},
			Combo = 0,
			MaxCombo = 2,
			ComboTime = 0.5,
			Items = {},
			ItemCons = {},
			ClickId = -1,
			LastButton = ""
		}
		local funcs = {}
		local tostring = tostring

		local disconnect = function(con)
			local pos = table.find(con.Signal.Connections,con)
			if pos then table.remove(con.Signal.Connections,pos) end
		end

		funcs.Trigger = function(self, item, button, X, Y)
			if table.find(self.AllowedButtons, button) then
				if self.LastButton ~= button or self.LastItem ~= item or self.Combo == self.MaxCombo or tick() - self.ClickId > self.ComboTime then
					self.Combo = 0
					self.LastButton = button
					self.LastItem = item
				end

				self.Combo = self.Combo + 1
				self.ClickId = tick()

				task.spawn(function()
					if self.InputDown then
						self.InputDown = false
					else
						self.InputDown = tick()

						local Connection = item.MouseButton1Up:Once(function()
							self.InputDown = false
						end)

						while self.InputDown and not Explorer.Dragging do
							if (tick() - self.InputDown) >= 0.4 then
								self.InputDown = false
								self["OnRelease"]:Fire(item, self.Combo, 2, Vector2.new(X, Y))
								break
							end;task.wait()
						end
					end
				end)

				local release
				release = service.UserInputService.InputEnded:Connect(function(input)
					if input.UserInputType == Enum.UserInputType["MouseButton" .. button] then
						release:Disconnect()
						if Lib.CheckMouseInGui(item) and self.LastButton == button and self.LastItem == item then
							self.InputDown = false -- infinite yield dev forgot to do this, and ended up OnRelease fired twice ??
							self["OnRelease"]:Fire(item,self.Combo,button)
						end
					end
				end)

				self["OnDown"]:Fire(item,self.Combo,button)
			end
		end

		funcs.Add = function(self,item)
			if table.find(self.Items,item) then return end

			local cons = {}
			cons[1] = item.MouseButton1Down:Connect(function(X, Y) self:Trigger(item, 1, X, Y) end)
			cons[2] = item.MouseButton2Down:Connect(function(X, Y) self:Trigger(item, 2, X, Y) end)

			self.ItemCons[item] = cons
			self.Items[#self.Items+1] = item
		end

		funcs.Remove = function(self,item)
			local ind = table.find(self.Items,item)
			if not ind then return end

			for i,v in pairs(self.ItemCons[item]) do
				v:Disconnect()
			end
			self.ItemCons[item] = nil
			table.remove(self.Items,ind)
		end

		local mt = {__index = funcs}

		local function new()
			local obj = initObj(props,mt)

			return obj
		end

		return {new = new}
	end)()

	return Lib
end

return {InitDeps = initDeps, InitAfterMain = initAfterMain, Main = main}

end,
["ModelViewer"] = function()
--[[
	Model Viewer App Module
	
	A model viewer :3
]]

-- Common Locals
local Main,Lib,Apps,Settings -- Main Containers
local Explorer, Properties, ScriptViewer, ModelViewer, Notebook -- Major Apps
local API,RMD,env,service,plr,create,createSimple -- Main Locals

local function initDeps(data)
	Main = data.Main
	Lib = data.Lib
	Apps = data.Apps
	Settings = data.Settings

	API = data.API
	RMD = data.RMD
	env = data.env
	service = data.service
	plr = data.plr
	create = data.create
	createSimple = data.createSimple
end

local function initAfterMain()
	Explorer = Apps.Explorer
	Properties = Apps.Properties
	ScriptViewer = Apps.ScriptViewer
	Notebook = Apps.Notebook
end

local function getPath(obj)
	if obj.Parent == nil then
		return "Nil parented"
	else
		return Explorer.GetInstancePath(obj)
	end
end

local function main()
	local RunService = game:GetService("RunService")
	local UserInputService = game:GetService("UserInputService")
	local renderConnection
	
	local ModelViewer = {
		EnableInputCamera = true,
		IsViewing = false,
		AutoRefresh = false,
		ZoomMultiplier = 2,
		AutoRotate = true,
		RotationSpeed = 0.01,
		RefreshRate = 30 -- hertz
	}
	
	local window, viewportFrame, pathLabel, settingsButton
	local model, camera, originalModel
	local distance = 10
	local viewCenter = Vector3.zero
	local refreshGeneration = 0
	
	
	ModelViewer.StopViewModel = function(updating)
		if updating then
			local existingModel = viewportFrame and viewportFrame:FindFirstChildOfClass("Model")
			if existingModel then existingModel:Destroy() end
			model = nil
		else
			refreshGeneration += 1
			if camera then camera = nil end
			if model then model = nil end
			viewportFrame:ClearAllChildren()
			
			ModelViewer.IsViewing = false
			window:SetTitle("3D Preview")
			pathLabel.Gui.Text = ""
		end
	end

	ModelViewer.ViewModel = function(item, updating)
		if typeof(item) ~= "Instance" then return false end
		ModelViewer.StopViewModel(updating)

		if item == workspace or item:IsA("Terrain") then
			env.notify("Dex++ 3D Viewer", "Workspace and Terrain previews are not supported", 6)
			return false
		end

		local originalArchivable = item.Archivable
		pcall(function() item.Archivable = true end)
		local cloned, clone = pcall(item.Clone, item)
		pcall(function() item.Archivable = originalArchivable end)
		if not cloned or not clone then
			env.notify("Dex++ 3D Viewer", "Could not clone the selected instance: " .. tostring(clone), 8)
			return false
		end

		if item:IsA("BasePart") then
				model = Instance.new("Model")
				model.Parent = viewportFrame
				clone.Parent = model
				model.PrimaryPart = clone
		elseif item:IsA("Model") then
				model = clone
				model.Parent = viewportFrame

				if not model.PrimaryPart then
					model.PrimaryPart = model:FindFirstChildWhichIsA("BasePart", true)
					if not model.PrimaryPart then
						model:Destroy()
						model = nil
						env.notify("Dex++ 3D Viewer", "The selected model has no BasePart to display", 6)
						return false
					end
				end
		else
			clone:Destroy()
			env.notify("Dex++ 3D Viewer", "Select a Model or BasePart", 6)
			return false
		end

		model:PivotTo(CFrame.new())
		local centerCFrame, size = model:GetBoundingBox()
		viewCenter = centerCFrame.Position
		distance = math.max(size.Magnitude * 0.8, 2)
		
		originalModel = item
		
		if ModelViewer.AutoRefresh and not updating then
			refreshGeneration += 1
			local generation = refreshGeneration
			task.spawn(function()
				while model and ModelViewer.AutoRefresh and generation == refreshGeneration do
					
					ModelViewer.ViewModel(originalModel, true)
					task.wait(1 / math.clamp(ModelViewer.RefreshRate, 1, 60))
				end
			end)
		end
		
		if not updating then
			camera = Instance.new("Camera")
			viewportFrame.CurrentCamera = camera

			camera.Parent = viewportFrame
			camera.FieldOfView = 60
			
			window:SetTitle(item.Name.." - 3D Preview")
			pathLabel.Gui.Text = "path: " .. getPath(originalModel)
			window:Show()
			ModelViewer.IsViewing = true
		end
	end

	ModelViewer.Init = function()
		window = Lib.Window.new()
		window:SetTitle("3D Preview")
		window:Resize(350,200)
		ModelViewer.Window =  window
		
		viewportFrame = Instance.new("ViewportFrame")
		viewportFrame.Parent = window.GuiElems.Content
		viewportFrame.BackgroundTransparency = 1
		viewportFrame.Size = UDim2.new(1,0,1,0)
		
		pathLabel = Lib.Label.new()
		pathLabel.Gui.Parent = window.GuiElems.Content
		pathLabel.Gui.AnchorPoint = Vector2.new(0,1)
		pathLabel.Gui.Text = ""
		pathLabel.Gui.TextSize = 12
		pathLabel.Gui.TextTransparency = 0.8
		pathLabel.Gui.Position = UDim2.new(0,1,1,0)
		pathLabel.Gui.Size = UDim2.new(1,-1,0,15)
		pathLabel.Gui.BackgroundTransparency = 1
		
		settingsButton = Instance.new("ImageButton",window.GuiElems.Content)
		settingsButton.AnchorPoint = Vector2.new(1,0)
		settingsButton.BackgroundTransparency = 1
		settingsButton.Size = UDim2.new(0,15,0,15)
		settingsButton.Position = UDim2.new(1,-3,0,3)
		settingsButton.Image = "rbxassetid://6578871732"
		settingsButton.ImageTransparency = 0.5
		-- mobile input check
		if UserInputService:GetLastInputType() == Enum.UserInputType.Touch then
			settingsButton.Visible = true
		else
			settingsButton.Visible = false
		end

		local rotationX, rotationY = math.rad(-15), 0
		local dragging = false
		local hovering = false
		local lastpos = Vector2.zero

		viewportFrame.InputBegan:Connect(function(input)
			if not ModelViewer.EnableInputCamera then return end
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				dragging = true
				lastpos = input.Position
			elseif input.KeyCode == Enum.KeyCode.LeftShift then
				ModelViewer.ZoomMultiplier = 10
			end
		end)
		

		viewportFrame.MouseEnter:Connect(function()
			hovering = true
		end)
		viewportFrame.MouseLeave:Connect(function()
			hovering = false
		end)

		viewportFrame.InputEnded:Connect(function(input)
			if not ModelViewer.EnableInputCamera then return end
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				dragging = false
			elseif input.KeyCode == Enum.KeyCode.LeftShift then
				ModelViewer.ZoomMultiplier = 2
			end
		end)

		viewportFrame.InputChanged:Connect(function(input)
			if not ModelViewer.EnableInputCamera then return end
			if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
				local delta = input.Position - lastpos
				lastpos = input.Position

				rotationY -= delta.X * 0.01
				rotationX -= delta.Y * 0.01
				rotationX = math.clamp(rotationX, -math.pi/2 + 0.1, math.pi/2 - 0.1)
			end

			if input.UserInputType == Enum.UserInputType.MouseWheel and hovering then
				distance = math.clamp(distance - (input.Position.Z * ModelViewer.ZoomMultiplier), 0.1, math.huge)
			end
		end)

		renderConnection = RunService.RenderStepped:Connect(function(dt)
			if camera and model then
				if not dragging and ModelViewer.AutoRotate then
					rotationY += ModelViewer.RotationSpeed * dt * 60
				end
				
				local center = viewCenter
				local offset = CFrame.new(0, 0, distance)
				local rotation = CFrame.Angles(0, rotationY, 0) * CFrame.Angles(rotationX, 0, 0)

				local camCF = CFrame.new(center) * rotation * offset

				camera.CFrame = CFrame.lookAt(camCF.Position, center)
				
			end
		end)
		
		-- context stuffs
		local context = Lib.ContextMenu.new()
		
		local absoluteSize = context.Gui.AbsoluteSize
		context.MaxHeight = (absoluteSize.Y <= 600 and (absoluteSize.Y - 40)) or nil

		-- Registers
		context:Register("STOP",{Name = "Stop Viewing", OnClick = function()
			ModelViewer.StopViewModel()
		end})
		context:Register("EXIT",{Name = "Exit", OnClick = function()
			ModelViewer.StopViewModel()
			context:Hide()
			window:Hide()
		end})
		context:Register("COPY_PATH",{Name = "Copy Path", OnClick = function()
			if model and env.setclipboard then
				env.setclipboard(getPath(originalModel))
			elseif not env.setclipboard then
				env.notify("Dex++ 3D Viewer", "Clipboard access is unavailable", 6)
			end
		end})
		context:Register("REFRESH",{Name = "Refresh", OnClick = function()
			if originalModel then
				ModelViewer.ViewModel(originalModel)
			end
		end})
		context:Register("ENABLE_AUTO_REFRESH",{Name = "Enable Auto Refresh", OnClick = function()
			if originalModel then
				ModelViewer.AutoRefresh = true
				ModelViewer.ViewModel(originalModel)
			end
		end})
		context:Register("DISABLE_AUTO_REFRESH",{Name = "Disable Auto Refresh", OnClick = function()
			if originalModel then
				ModelViewer.AutoRefresh = false
				ModelViewer.ViewModel(originalModel)
			end
		end})
		context:Register("SAVE_INST",{Name = "Save to File", OnClick = function()
			if model then
				Lib.SaveAsPrompt("Place_"..game.PlaceId.."_"..originalModel.Name.."_"..os.time(), function(filename)
					window:SetTitle(originalModel.Name.." - Model Viewer - Saving")
					local _, savedPath = env.saveinstance(originalModel, filename, {
						Decompile = false,
						DecompileIgnoreNames = {"ConveyorBeltSimulator"},
						SaveBytecode = false,
						SavePlayerCharacters = true,
						ShowStatus = true
					})
					window:SetTitle(originalModel.Name.." - Model Viewer - Saved")
					context:Hide()
					task.delay(4, function()
						if model then window:SetTitle(originalModel.Name.." - Model Viewer") end
					end)
					return true, savedPath
				end, "rbxmx")
			end
		end})
		
		context:Register("ENABLE_AUTO_ROTATE",{Name = "Enable Auto Rotate", OnClick = function()
			ModelViewer.AutoRotate = true
			
		end})
		context:Register("DISABLE_AUTO_ROTATE",{Name = "Disable Auto Rotate", OnClick = function()
			ModelViewer.AutoRotate = false
		end})
		context:Register("LOCK_CAM",{Name = "Lock Camera", OnClick = function()
			ModelViewer.EnableInputCamera = false
		end})
		context:Register("UNLOCK_CAM",{Name = "Unlock Camera", OnClick = function()
			ModelViewer.EnableInputCamera = true
		end})
		
		context:Register("ZOOM_IN",{Name = "Zoom In", OnClick = function()
			distance = math.clamp(distance - (ModelViewer.ZoomMultiplier * 2), 2, math.huge)
		end})
		
		context:Register("ZOOM_OUT",{Name = "Zoom Out", OnClick = function()
			distance = math.clamp(distance + (ModelViewer.ZoomMultiplier * 2), 2, math.huge)
		end})
		
		local function ShowContext()
			context:Clear()

			context:AddRegistered("STOP", not ModelViewer.IsViewing)	
			context:AddRegistered("REFRESH", not ModelViewer.IsViewing)
			context:AddRegistered("COPY_PATH", not ModelViewer.IsViewing)
			context:AddRegistered("SAVE_INST", not ModelViewer.IsViewing)
			context:AddDivider()
			
			if env.isonmobile then
				context:AddRegistered("ZOOM_IN")
				context:AddRegistered("ZOOM_OUT")
				context:AddDivider()
			end

			if ModelViewer.AutoRotate then
				context:AddRegistered("DISABLE_AUTO_ROTATE")
			else
				context:AddRegistered("ENABLE_AUTO_ROTATE")
			end
			if ModelViewer.AutoRefresh then
				context:AddRegistered("DISABLE_AUTO_REFRESH")
			else
				context:AddRegistered("ENABLE_AUTO_REFRESH")
			end
			if ModelViewer.EnableInputCamera then
				context:AddRegistered("LOCK_CAM")
			else
				context:AddRegistered("UNLOCK_CAM")
			end

			context:AddDivider()

			context:AddRegistered("EXIT")

			context:Show()
		end
		
		local function HideContext()
			context:Hide()
		end
		
		viewportFrame.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton2 then
				ShowContext()
			elseif input.UserInputType == Enum.UserInputType.MouseButton1 and Lib.CheckMouseInGui(context.Gui) then
				HideContext()
			end
		end)
		settingsButton.MouseButton1Click:Connect(function()
			ShowContext()
		end)
	end

	ModelViewer.Uninit = function()
		if renderConnection then
			pcall(renderConnection.Disconnect, renderConnection)
			renderConnection = nil
		end
		pcall(ModelViewer.StopViewModel)
	end

	return ModelViewer
end

-- TODO: Remove when open source
if gethsfuncs then
	_G.moduleData = {InitDeps = initDeps, InitAfterMain = initAfterMain, Main = main}
else
	return {InitDeps = initDeps, InitAfterMain = initAfterMain, Main = main}
end

end,
["Properties"] = function()
--[[
	Properties App Module
	
	The main properties interface
]]

-- Common Locals
local Main,Lib,Apps,Settings -- Main Containers
local Explorer, Properties, ScriptViewer, Notebook -- Major Apps
local API,RMD,env,service,plr,create,createSimple -- Main Locals

local function initDeps(data)
	Main = data.Main
	Lib = data.Lib
	Apps = data.Apps
	Settings = data.Settings

	API = data.API
	RMD = data.RMD
	env = data.env
	service = data.service
	plr = data.plr
	create = data.create
	createSimple = data.createSimple
end

local function initAfterMain()
	Explorer = Apps.Explorer
	Properties = Apps.Properties
	ScriptViewer = Apps.ScriptViewer
	Notebook = Apps.Notebook
end

local function main()
	local Properties = {}

	local window, toolBar, propsFrame
	local scrollV, scrollH
	local categoryOrder
	local props,viewList,expanded,indexableProps,propEntries,autoUpdateObjs = {},{},{},{},{},{}
	local inputBox,inputTextBox,inputProp
	local checkboxes,propCons = {},{}
	local table,string = table,string
	local getPropChangedSignal = game.GetPropertyChangedSignal
	local getAttributeChangedSignal = game.GetAttributeChangedSignal
	local isa = game.IsA
	local getAttribute = game.GetAttribute
	local setAttribute = game.SetAttribute

	Properties.GuiElems = {}
	Properties.Index = 0
	Properties.ViewWidth = 0
	Properties.MinInputWidth = 100
	Properties.EntryIndent = 16
	Properties.EntryOffset = 4
	Properties.NameWidthCache = {}
	Properties.SubPropCache = {}
	Properties.ClassLists = {}
	Properties.SearchText = ""

	Properties.AddAttributeProp = {Category = "Attributes", Class = "", Name = "", SpecialRow = "AddAttribute", Tags = {}}
	Properties.SoundPreviewProp = {Category = "Data", ValueType = {Name = "SoundPlayer"}, Class = "Sound", Name = "Preview", Tags = {}}

	Properties.IgnoreProps = {
		["DataModel"] = {
			["PrivateServerId"] = true,
			["PrivateServerOwnerId"] = true,
			["VIPServerId"] = true,
			["VIPServerOwnerId"] = true
		}
	}

	Properties.ExpandableTypes = {
		["Vector2"] = true,
		["Vector3"] = true,
		["UDim"] = true,
		["UDim2"] = true,
		["CFrame"] = true,
		["Rect"] = true,
		["PhysicalProperties"] = true,
		["Ray"] = true,
		["NumberRange"] = true,
		["Faces"] = true,
		["Axes"] = true,
	}

	Properties.ExpandableProps = {
		["Sound.SoundId"] = true
	}

	Properties.CollapsedCategories = {
		["Surface Inputs"] = true,
		["Surface"] = true
	}

	Properties.ConflictSubProps = {
		["Vector2"] = {"X","Y"},
		["Vector3"] = {"X","Y","Z"},
		["UDim"] = {"Scale","Offset"},
		["UDim2"] = {"X","X.Scale","X.Offset","Y","Y.Scale","Y.Offset"},
		["CFrame"] = {"Position","Position.X","Position.Y","Position.Z",
			"RightVector","RightVector.X","RightVector.Y","RightVector.Z",
			"UpVector","UpVector.X","UpVector.Y","UpVector.Z",
			"LookVector","LookVector.X","LookVector.Y","LookVector.Z"},
		["Rect"] = {"Min.X","Min.Y","Max.X","Max.Y"},
		["PhysicalProperties"] = {"Density","Elasticity","ElasticityWeight","Friction","FrictionWeight"},
		["Ray"] = {"Origin","Origin.X","Origin.Y","Origin.Z","Direction","Direction.X","Direction.Y","Direction.Z"},
		["NumberRange"] = {"Min","Max"},
		["Faces"] = {"Back","Bottom","Front","Left","Right","Top"},
		["Axes"] = {"X","Y","Z"}
	}

	Properties.ConflictIgnore = {
		["BasePart"] = {
			["ResizableFaces"] = true
		}
	}

	Properties.RoundableTypes = {
		["float"] = true,
		["double"] = true,
		["Color3"] = true,
		["UDim"] = true,
		["UDim2"] = true,
		["Vector2"] = true,
		["Vector3"] = true,
		["NumberRange"] = true,
		["Rect"] = true,
		["NumberSequence"] = true,
		["ColorSequence"] = true,
		["Ray"] = true,
		["CFrame"] = true
	}

	Properties.TypeNameConvert = {
		["number"] = "double",
		["boolean"] = "bool"
	}

	Properties.ToNumberTypes = {
		["int"] = true,
		["int64"] = true,
		["float"] = true,
		["double"] = true
	}

	Properties.DefaultPropValue = {
		string = "",
		bool = false,
		double = 0,
		UDim = UDim.new(0,0),
		UDim2 = UDim2.new(0,0,0,0),
		BrickColor = BrickColor.new("Medium stone grey"),
		Color3 = Color3.new(1,1,1),
		Vector2 = Vector2.new(0,0),
		Vector3 = Vector3.new(0,0,0),
		NumberSequence = NumberSequence.new(1),
		ColorSequence = ColorSequence.new(Color3.new(1,1,1)),
		NumberRange = NumberRange.new(0),
		Rect = Rect.new(0,0,0,0)
	}

	Properties.AllowedAttributeTypes = {"string","boolean","number","UDim","UDim2","BrickColor","Color3","Vector2","Vector3","NumberSequence","ColorSequence","NumberRange","Rect"}

	Properties.StringToValue = function(prop,str)
		local typeData = prop.ValueType
		local typeName = typeData.Name

		if typeName == "string" or typeName == "Content" then
			return str
		elseif Properties.ToNumberTypes[typeName] then
			return tonumber(str)
		elseif typeName == "Vector2" then
			local vals = str:split(",")
			local x,y = tonumber(vals[1]),tonumber(vals[2])
			if x and y and #vals >= 2 then return Vector2.new(x,y) end
		elseif typeName == "Vector3" then
			local vals = str:split(",")
			local x,y,z = tonumber(vals[1]),tonumber(vals[2]),tonumber(vals[3])
			if x and y and z and #vals >= 3 then return Vector3.new(x,y,z) end
		elseif typeName == "UDim" then
			local vals = str:split(",")
			local scale,offset = tonumber(vals[1]),tonumber(vals[2])
			if scale and offset and #vals >= 2 then return UDim.new(scale,offset) end
		elseif typeName == "UDim2" then
			local vals = str:gsub("[{}]",""):split(",")
			local xScale,xOffset,yScale,yOffset = tonumber(vals[1]),tonumber(vals[2]),tonumber(vals[3]),tonumber(vals[4])
			if xScale and xOffset and yScale and yOffset and #vals >= 4 then return UDim2.new(xScale,xOffset,yScale,yOffset) end
		elseif typeName == "CFrame" then
			local vals = str:split(",")
			local s,result = pcall(CFrame.new,unpack(vals))
			if s and #vals >= 12 then return result end
		elseif typeName == "Rect" then
			local vals = str:split(",")
			local s,result = pcall(Rect.new,unpack(vals))
			if s and #vals >= 4 then return result end
		elseif typeName == "Ray" then
			local vals = str:gsub("[{}]",""):split(",")
			local s,origin = pcall(Vector3.new,unpack(vals,1,3))
			local s2,direction = pcall(Vector3.new,unpack(vals,4,6))
			if s and s2 and #vals >= 6 then return Ray.new(origin,direction) end
		elseif typeName == "NumberRange" then
			local vals = str:split(",")
			local s,result = pcall(NumberRange.new,unpack(vals))
			if s and #vals >= 1 then return result end
		elseif typeName == "Color3" then
			local vals = str:gsub("[{}]",""):split(",")
			local s,result = pcall(Color3.fromRGB,unpack(vals))
			if s and #vals >= 3 then return result end
		end

		return nil
	end

	Properties.ValueToString = function(prop,val)
		local typeData = prop.ValueType
		local typeName = typeData.Name

		if typeName == "Color3" then
			return Lib.ColorToBytes(val)
		elseif typeName == "NumberRange" then
			return val.Min..", "..val.Max
		end

		return tostring(val)
	end

	Properties.GetIndexableProps = function(obj,classData)
		if not Main.Elevated then
			if not pcall(function() return obj.ClassName end) then return nil end
		end

		local ignoreProps = Properties.IgnoreProps[classData.Name] or {}

		local result = {}
		local count = 1
		local props = classData.Properties
		for i = 1,#props do
			local prop = props[i]
			if not ignoreProps[prop.Name] then
				local s = pcall(function() return obj[prop.Name] end)
				if s then
					result[count] = prop
					count = count + 1
				end
			end
		end

		return result
	end

	Properties.FindFirstObjWhichIsA = function(class)
		local classList = Properties.ClassLists[class] or {}
		if classList and #classList > 0 then
			return classList[1]
		end

		return nil
	end

	Properties.ComputeConflicts = function(p)
		local maxConflictCheck = Settings.Properties.MaxConflictCheck
		local sList = Explorer.Selection.List
		local classLists = Properties.ClassLists
		local stringSplit = string.split
		local t_clear = table.clear
		local conflictIgnore = Properties.ConflictIgnore
		local conflictMap = {}
		local propList = p and {p} or props

		if p then
			local gName = p.Class.."."..p.Name
			autoUpdateObjs[gName] = nil
			local subProps = Properties.ConflictSubProps[p.ValueType.Name] or {}
			for i = 1,#subProps do
				autoUpdateObjs[gName.."."..subProps[i]] = nil
			end
		else
			table.clear(autoUpdateObjs)
		end

		if #sList > 0 then
			for i = 1,#propList do
				local prop = propList[i]
				local propName,propClass = prop.Name,prop.Class
				local typeData = prop.RootType or prop.ValueType
				local typeName = typeData.Name
				local attributeName = prop.AttributeName
				local gName = propClass.."."..propName

				local checked = 0
				local subProps = Properties.ConflictSubProps[typeName] or {}
				local subPropCount = #subProps
				local toCheck = subPropCount + 1
				local conflictsFound = 0
				local indexNames = {}
				local ignored = conflictIgnore[propClass] and conflictIgnore[propClass][propName]
				local truthyCheck = (typeName == "PhysicalProperties")
				local isAttribute = prop.IsAttribute
				local isMultiType = prop.MultiType

				t_clear(conflictMap)

				if not isMultiType then
					local firstVal,firstObj,firstSet
					local classList = classLists[prop.Class] or {}
					for c = 1,#classList do
						local obj = classList[c]
						if not firstSet then
							if isAttribute then
								firstVal = getAttribute(obj,attributeName)
								if firstVal ~= nil then
									firstObj = obj
									firstSet = true
								end
							else
								firstVal = obj[propName]
								firstObj = obj
								firstSet = true
							end
							if ignored then break end
						else
							local propVal,skip
							if isAttribute then
								propVal = getAttribute(obj,attributeName)
								if propVal == nil then skip = true end
							else
								propVal = obj[propName]
							end

							if not skip then
								if not conflictMap[1] then
									if truthyCheck then
										if (firstVal and true or false) ~= (propVal and true or false) then
											conflictMap[1] = true
											conflictsFound = conflictsFound + 1
										end
									elseif firstVal ~= propVal then
										conflictMap[1] = true
										conflictsFound = conflictsFound + 1
									end
								end

								if subPropCount > 0 then
									for sPropInd = 1,subPropCount do
										local indexes = indexNames[sPropInd]
										if not indexes then indexes = stringSplit(subProps[sPropInd],".") indexNames[sPropInd] = indexes end

										local firstValSub = firstVal
										local propValSub = propVal

										for j = 1,#indexes do
											if not firstValSub or not propValSub then break end -- PhysicalProperties
											local indexName = indexes[j]
											firstValSub = firstValSub[indexName]
											propValSub = propValSub[indexName]
										end

										local mapInd = sPropInd + 1
										if not conflictMap[mapInd] and firstValSub ~= propValSub then
											conflictMap[mapInd] = true
											conflictsFound = conflictsFound + 1
										end
									end
								end

								if conflictsFound == toCheck then break end
							end
						end

						checked = checked + 1
						if checked == maxConflictCheck then break end
					end

					if not conflictMap[1] then autoUpdateObjs[gName] = firstObj end
					for sPropInd = 1,subPropCount do
						if not conflictMap[sPropInd+1] then
							autoUpdateObjs[gName.."."..subProps[sPropInd]] = firstObj
						end
					end
				end
			end
		end

		if p then
			Properties.Refresh()
		end
	end

	-- Fetches the properties to be displayed based on the explorer selection
	Properties.ShowExplorerProps = function()
		local maxConflictCheck = Settings.Properties.MaxConflictCheck
		local sList = Explorer.Selection.List
		local foundClasses = {}
		local propCount = 1
		local elevated = Main.Elevated
		local showDeprecated,showHidden = Settings.Properties.ShowDeprecated,Settings.Properties.ShowHidden
		local Classes = API.Classes
		local classLists = {}
		local lower = string.lower
		local RMDCustomOrders = RMD.PropertyOrders
		local getAttributes = game.GetAttributes
		local maxAttrs = Settings.Properties.MaxAttributes
		local showingAttrs = Settings.Properties.ShowAttributes
		local foundAttrs = {}
		local attrCount = 0
		local typeof = typeof
		local typeNameConvert = Properties.TypeNameConvert

		table.clear(props)

		for i = 1,#sList do
			local node = sList[i]
			local obj = node.Obj
			local class = node.Class
			if not class then class = obj.ClassName node.Class = class end

			local apiClass = Classes[class]
			while apiClass do
				local APIClassName = apiClass.Name
				if not foundClasses[APIClassName] then
					local apiProps = indexableProps[APIClassName]
					if not apiProps then apiProps = Properties.GetIndexableProps(obj,apiClass) indexableProps[APIClassName] = apiProps end

					for i = 1,#apiProps do
						local prop = apiProps[i]
						local tags = prop.Tags
						if (not tags.Deprecated or showDeprecated) and (not tags.Hidden or showHidden) then
							props[propCount] = prop
							propCount = propCount + 1
						end
					end
					foundClasses[APIClassName] = true
				end

				local classList = classLists[APIClassName]
				if not classList then classList = {} classLists[APIClassName] = classList end
				classList[#classList+1] = obj

				apiClass = apiClass.Superclass
			end

			if showingAttrs and attrCount < maxAttrs then
				local attrs = getAttributes(obj)
				for name,val in pairs(attrs) do
					local typ = typeof(val)
					if not foundAttrs[name] then
						local category = (typ == "Instance" and "Class") or (typ == "EnumItem" and "Enum") or "Other"
						local valType = {Name = typeNameConvert[typ] or typ, Category = category}
						local attrProp = {IsAttribute = true, Name = "ATTR_"..name, AttributeName = name, DisplayName = name, Class = "Instance", ValueType = valType, Category = "Attributes", Tags = {}}
						props[propCount] = attrProp
						propCount = propCount + 1
						attrCount = attrCount + 1
						foundAttrs[name] = {typ,attrProp}
						if attrCount == maxAttrs then break end
					elseif foundAttrs[name][1] ~= typ then
						foundAttrs[name][2].MultiType = true
						foundAttrs[name][2].Tags.ReadOnly = true
						foundAttrs[name][2].ValueType = {Name = "string"}
					end
				end
			end
		end

		table.sort(props,function(a,b)
			if a.Category ~= b.Category then
				return (categoryOrder[a.Category] or 9999) < (categoryOrder[b.Category] or 9999)
			else
				local aOrder = (RMDCustomOrders[a.Class] and RMDCustomOrders[a.Class][a.Name]) or 9999999
				local bOrder = (RMDCustomOrders[b.Class] and RMDCustomOrders[b.Class][b.Name]) or 9999999
				if aOrder ~= bOrder then
					return aOrder < bOrder
				else
					return lower(a.Name) < lower(b.Name)
				end
			end
		end)

		-- Find conflicts and get auto-update instances
		Properties.ClassLists = classLists
		Properties.ComputeConflicts()
		--warn("CONFLICT",tick()-start)
		if #props > 0 then
			props[#props+1] = Properties.AddAttributeProp
		end

		Properties.Update()
		Properties.Refresh()
	end

	Properties.UpdateView = function()
		local maxEntries = math.ceil(propsFrame.AbsoluteSize.Y / 23)
		local maxX = propsFrame.AbsoluteSize.X
		local totalWidth = Properties.ViewWidth + Properties.MinInputWidth

		scrollV.VisibleSpace = maxEntries
		scrollV.TotalSpace = #viewList + 1
		scrollH.VisibleSpace = maxX
		scrollH.TotalSpace = totalWidth

		scrollV.Gui.Visible = #viewList + 1 > maxEntries
		scrollH.Gui.Visible = Settings.Properties.ScaleType == 0 and totalWidth > maxX

		local oldSize = propsFrame.Size
		propsFrame.Size = UDim2.new(1,(scrollV.Gui.Visible and -16 or 0),1,(scrollH.Gui.Visible and -39 or -23))
		if oldSize ~= propsFrame.Size then
			Properties.UpdateView()
		else
			scrollV:Update()
			scrollH:Update()

			if scrollV.Gui.Visible and scrollH.Gui.Visible then
				scrollV.Gui.Size = UDim2.new(0,16,1,-39)
				scrollH.Gui.Size = UDim2.new(1,-16,0,16)
				Properties.Window.GuiElems.Content.ScrollCorner.Visible = true
			else
				scrollV.Gui.Size = UDim2.new(0,16,1,-23)
				scrollH.Gui.Size = UDim2.new(1,0,0,16)
				Properties.Window.GuiElems.Content.ScrollCorner.Visible = false
			end

			Properties.Index = scrollV.Index
		end
	end

	Properties.MakeSubProp = function(prop,subName,valueType,displayName)
		local subProp = {}
		for i,v in pairs(prop) do
			subProp[i] = v
		end
		subProp.RootType = subProp.RootType or subProp.ValueType
		subProp.ValueType = valueType
		subProp.SubName = subProp.SubName and (subProp.SubName..subName) or subName
		subProp.DisplayName = displayName

		return subProp
	end

	Properties.GetExpandedProps = function(prop) -- TODO: Optimize using table
		local result = {}
		local typeData = prop.ValueType
		local typeName = typeData.Name
		local makeSubProp = Properties.MakeSubProp

		if typeName == "Vector2" then
			result[1] = makeSubProp(prop,".X",{Name = "float"})
			result[2] = makeSubProp(prop,".Y",{Name = "float"})
		elseif typeName == "Vector3" then
			result[1] = makeSubProp(prop,".X",{Name = "float"})
			result[2] = makeSubProp(prop,".Y",{Name = "float"})
			result[3] = makeSubProp(prop,".Z",{Name = "float"})
		elseif typeName == "CFrame" then
			result[1] = makeSubProp(prop,".Position",{Name = "Vector3"})
			result[2] = makeSubProp(prop,".RightVector",{Name = "Vector3"})
			result[3] = makeSubProp(prop,".UpVector",{Name = "Vector3"})
			result[4] = makeSubProp(prop,".LookVector",{Name = "Vector3"})
		elseif typeName == "UDim" then
			result[1] = makeSubProp(prop,".Scale",{Name = "float"})
			result[2] = makeSubProp(prop,".Offset",{Name = "int"})
		elseif typeName == "UDim2" then
			result[1] = makeSubProp(prop,".X",{Name = "UDim"})
			result[2] = makeSubProp(prop,".Y",{Name = "UDim"})
		elseif typeName == "Rect" then
			result[1] = makeSubProp(prop,".Min.X",{Name = "float"},"X0")
			result[2] = makeSubProp(prop,".Min.Y",{Name = "float"},"Y0")
			result[3] = makeSubProp(prop,".Max.X",{Name = "float"},"X1")
			result[4] = makeSubProp(prop,".Max.Y",{Name = "float"},"Y1")
		elseif typeName == "PhysicalProperties" then
			result[1] = makeSubProp(prop,".Density",{Name = "float"})
			result[2] = makeSubProp(prop,".Elasticity",{Name = "float"})
			result[3] = makeSubProp(prop,".ElasticityWeight",{Name = "float"})
			result[4] = makeSubProp(prop,".Friction",{Name = "float"})
			result[5] = makeSubProp(prop,".FrictionWeight",{Name = "float"})
		elseif typeName == "Ray" then
			result[1] = makeSubProp(prop,".Origin",{Name = "Vector3"})
			result[2] = makeSubProp(prop,".Direction",{Name = "Vector3"})
		elseif typeName == "NumberRange" then
			result[1] = makeSubProp(prop,".Min",{Name = "float"})
			result[2] = makeSubProp(prop,".Max",{Name = "float"})
		elseif typeName == "Faces" then
			result[1] = makeSubProp(prop,".Back",{Name = "bool"})
			result[2] = makeSubProp(prop,".Bottom",{Name = "bool"})
			result[3] = makeSubProp(prop,".Front",{Name = "bool"})
			result[4] = makeSubProp(prop,".Left",{Name = "bool"})
			result[5] = makeSubProp(prop,".Right",{Name = "bool"})
			result[6] = makeSubProp(prop,".Top",{Name = "bool"})
		elseif typeName == "Axes" then
			result[1] = makeSubProp(prop,".X",{Name = "bool"})
			result[2] = makeSubProp(prop,".Y",{Name = "bool"})
			result[3] = makeSubProp(prop,".Z",{Name = "bool"})
		end

		if prop.Name == "SoundId" and prop.Class == "Sound" then
			result[1] = Properties.SoundPreviewProp
		end

		return result
	end

	Properties.Update = function()
		table.clear(viewList)

		local nameWidthCache = Properties.NameWidthCache
		local lastCategory
		local count = 1
		local maxWidth,maxDepth = 0,1

		local textServ = service.TextService
		local getTextSize = textServ.GetTextSize
		local font = Enum.Font.SourceSans
		local size = Vector2.new(math.huge,20)
		local stringSplit = string.split
		local entryIndent = Properties.EntryIndent
		local isFirstScaleType = Settings.Properties.ScaleType == 0
		local find,lower = string.find,string.lower
		local searchText = (#Properties.SearchText > 0 and lower(Properties.SearchText))

		local function recur(props,depth)
			for i = 1,#props do
				local prop = props[i]
				local propName = prop.Name
				local subName = prop.SubName
				local category = prop.Category

				local visible
				if searchText and depth == 1 then
					if find(lower(propName),searchText,1,true) then
						visible = true
					end
				else
					visible = true
				end

				if visible and lastCategory ~= category then
					viewList[count] = {CategoryName = category}
					count = count + 1
					lastCategory = category
				end

				if (expanded["CAT_"..category] and visible) or prop.SpecialRow then
					if depth > 1 then prop.Depth = depth if depth > maxDepth then maxDepth = depth end end

					if isFirstScaleType then
						local nameArr = subName and stringSplit(subName,".")
						local displayName = prop.DisplayName or (nameArr and nameArr[#nameArr]) or propName

						local nameWidth = nameWidthCache[displayName]
						if not nameWidth then nameWidth = getTextSize(textServ,displayName,14,font,size).X nameWidthCache[displayName] = nameWidth end

						local totalWidth = nameWidth + entryIndent*depth
						if totalWidth > maxWidth then
							maxWidth = totalWidth
						end
					end

					viewList[count] = prop
					count = count + 1

					local fullName = prop.Class.."."..prop.Name..(prop.SubName or "")
					if expanded[fullName] then
						local nextDepth = depth+1
						local expandedProps = Properties.GetExpandedProps(prop)
						if #expandedProps > 0 then
							recur(expandedProps,nextDepth)
						end
					end
				end
			end
		end
		recur(props,1)

		inputProp = nil
		Properties.ViewWidth = maxWidth + 9 + Properties.EntryOffset
		Properties.UpdateView()
	end

	Properties.NewPropEntry = function(index)
		local newEntry = Properties.EntryTemplate:Clone()
		local nameFrame = newEntry.NameFrame
		local valueFrame = newEntry.ValueFrame
		local newCheckbox = Lib.Checkbox.new(1)
		newCheckbox.Gui.Position = UDim2.new(0,3,0,3)
		newCheckbox.Gui.Parent = valueFrame
		newCheckbox.OnInput:Connect(function()
			local prop = viewList[index + Properties.Index]
			if not prop then return end

			if prop.ValueType.Name == "PhysicalProperties" then
				Properties.SetProp(prop,newCheckbox.Toggled and true or nil)
			else
				Properties.SetProp(prop,newCheckbox.Toggled)
			end
		end)
		checkboxes[index] = newCheckbox

		local iconFrame = Main.MiscIcons:GetLabel()
		iconFrame.Position = UDim2.new(0,2,0,3)
		iconFrame.Parent = newEntry.ValueFrame.RightButton

		newEntry.Position = UDim2.new(0,0,0,23*(index-1))

		nameFrame.Expand.InputBegan:Connect(function(input)
			local prop = viewList[index + Properties.Index]
			if not prop or input.UserInputType ~= Enum.UserInputType.MouseMovement then return end

			local fullName = (prop.CategoryName and "CAT_"..prop.CategoryName) or prop.Class.."."..prop.Name..(prop.SubName or "")

			Main.MiscIcons:DisplayByKey(newEntry.NameFrame.Expand.Icon, expanded[fullName] and "Collapse_Over" or "Expand_Over")
		end)

		nameFrame.Expand.InputEnded:Connect(function(input)
			local prop = viewList[index + Properties.Index]
			if not prop or input.UserInputType ~= Enum.UserInputType.MouseMovement then return end

			local fullName = (prop.CategoryName and "CAT_"..prop.CategoryName) or prop.Class.."."..prop.Name..(prop.SubName or "")

			Main.MiscIcons:DisplayByKey(newEntry.NameFrame.Expand.Icon, expanded[fullName] and "Collapse" or "Expand")
		end)

		nameFrame.Expand.MouseButton1Down:Connect(function()
			local prop = viewList[index + Properties.Index]
			if not prop then return end

			local fullName = (prop.CategoryName and "CAT_"..prop.CategoryName) or prop.Class.."."..prop.Name..(prop.SubName or "")
			if not prop.CategoryName and not Properties.ExpandableTypes[prop.ValueType and prop.ValueType.Name] and not Properties.ExpandableProps[fullName] then return end

			expanded[fullName] = not expanded[fullName]
			Properties.Update()
			Properties.Refresh()
		end)

		nameFrame.PropName.InputBegan:Connect(function(input)
			local prop = viewList[index + Properties.Index]
			if not prop then return end
			if input.UserInputType == Enum.UserInputType.MouseMovement and not nameFrame.PropName.TextFits then
				local fullNameFrame = Properties.FullNameFrame	
				local nameArr = string.split(prop.Class.."."..prop.Name..(prop.SubName or ""),".")
				local dispName = prop.DisplayName or nameArr[#nameArr]
				local sizeX = service.TextService:GetTextSize(dispName,14,Enum.Font.SourceSans,Vector2.new(math.huge,20)).X

				fullNameFrame.TextLabel.Text = dispName
				--fullNameFrame.Position = UDim2.new(0,Properties.EntryIndent*(prop.Depth or 1) + Properties.EntryOffset,0,23*(index-1))
				fullNameFrame.Size = UDim2.new(0,sizeX + 4,0,22)
				fullNameFrame.Visible = true
				Properties.FullNameFrameIndex = index
				Properties.FullNameFrameAttach.SetData(fullNameFrame, {Target = nameFrame})
				Properties.FullNameFrameAttach.Enable()
			end
		end)

		nameFrame.PropName.InputEnded:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseMovement and Properties.FullNameFrameIndex == index then
				Properties.FullNameFrame.Visible = false
				Properties.FullNameFrameAttach.Disable()
			end
		end)

		valueFrame.ValueBox.MouseButton1Down:Connect(function()
			local prop = viewList[index + Properties.Index]
			if not prop then return end

			Properties.SetInputProp(prop,index)
		end)

		valueFrame.ColorButton.MouseButton1Down:Connect(function()
			local prop = viewList[index + Properties.Index]
			if not prop then return end

			Properties.SetInputProp(prop,index,"color")
		end)

		valueFrame.RightButton.MouseButton1Click:Connect(function()
			local prop = viewList[index + Properties.Index]
			if not prop then return end

			local fullName = prop.Class.."."..prop.Name..(prop.SubName or "")
			local inputFullName = inputProp and (inputProp.Class.."."..inputProp.Name..(inputProp.SubName or ""))

			if fullName == inputFullName and inputProp.ValueType.Category == "Class" then
				inputProp = nil
				Properties.SetProp(prop,nil)
			else
				Properties.SetInputProp(prop,index,"right")
			end
		end)

		nameFrame.ToggleAttributes.MouseButton1Click:Connect(function()
			Settings.Properties.ShowAttributes = not Settings.Properties.ShowAttributes
			Properties.ShowExplorerProps()
		end)

		newEntry.RowButton.MouseButton1Click:Connect(function()
			Properties.DisplayAddAttributeWindow()
		end)

		newEntry.EditAttributeButton.MouseButton1Down:Connect(function()
			local prop = viewList[index + Properties.Index]
			if not prop then return end

			Properties.DisplayAttributeContext(prop)
		end)

		valueFrame.SoundPreview.ControlButton.MouseButton1Click:Connect(function()
			if Properties.PreviewSound and Properties.PreviewSound.Playing then
				Properties.SetSoundPreview(false)
			else
				local soundObj = Properties.FindFirstObjWhichIsA("Sound")
				if soundObj then Properties.SetSoundPreview(soundObj) end
			end
		end)

		valueFrame.SoundPreview.InputBegan:Connect(function(input)
			if input.UserInputType ~= Enum.UserInputType.MouseButton1 then return end

			local releaseEvent,mouseEvent
			releaseEvent = service.UserInputService.InputEnded:Connect(function(input)
				if input.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
				releaseEvent:Disconnect()
				mouseEvent:Disconnect()
			end)

			local timeLine = newEntry.ValueFrame.SoundPreview.TimeLine
			local soundObj = Properties.FindFirstObjWhichIsA("Sound")
			if soundObj then Properties.SetSoundPreview(soundObj,true) end

			local function update(input)
				local sound = Properties.PreviewSound
				if not sound or sound.TimeLength == 0 then return end

				local mouseX = input.Position.X
				local timeLineSize = timeLine.AbsoluteSize
				local relaX = mouseX - timeLine.AbsolutePosition.X

				if timeLineSize.X <= 1 then return end
				if relaX < 0 then relaX = 0 elseif relaX >= timeLineSize.X then relaX = timeLineSize.X-1 end

				local perc = (relaX/(timeLineSize.X-1))
				sound.TimePosition = perc*sound.TimeLength
				timeLine.Slider.Position = UDim2.new(perc,-4,0,-8)
			end
			update(input)

			mouseEvent = service.UserInputService.InputChanged:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.MouseMovement then
					update(input)
				end
			end)
		end)

		newEntry.Parent = propsFrame

		return {
			Gui = newEntry,
			GuiElems = {
				NameFrame = nameFrame,
				ValueFrame = valueFrame,
				PropName = nameFrame.PropName,
				ValueBox = valueFrame.ValueBox,
				Expand = nameFrame.Expand,
				ColorButton = valueFrame.ColorButton,
				ColorPreview = valueFrame.ColorButton.ColorPreview,
				Gradient = valueFrame.ColorButton.ColorPreview.UIGradient,
				EnumArrow = valueFrame.EnumArrow,
				Checkbox = valueFrame.Checkbox,
				RightButton = valueFrame.RightButton,
				RightButtonIcon = iconFrame,
				RowButton = newEntry.RowButton,
				EditAttributeButton = newEntry.EditAttributeButton,
				ToggleAttributes = nameFrame.ToggleAttributes,
				SoundPreview = valueFrame.SoundPreview,
				SoundPreviewSlider = valueFrame.SoundPreview.TimeLine.Slider
			}
		}
	end

	Properties.GetSoundPreviewEntry = function()
		for i = 1,#viewList do
			if viewList[i] == Properties.SoundPreviewProp then
				return propEntries[i - Properties.Index]
			end
		end
	end

	Properties.SetSoundPreview = function(soundObj,noplay)
		local sound = Properties.PreviewSound
		if not sound then
			sound = Instance.new("Sound")
			sound.Name = "Preview"
			sound.Paused:Connect(function()
				local entry = Properties.GetSoundPreviewEntry()
				if entry then Main.MiscIcons:DisplayByKey(entry.GuiElems.SoundPreview.ControlButton.Icon, "Play") end
			end)
			sound.Resumed:Connect(function() Properties.Refresh() end)
			sound.Ended:Connect(function()
				local entry = Properties.GetSoundPreviewEntry()
				if entry then entry.GuiElems.SoundPreviewSlider.Position = UDim2.new(0,-4,0,-8) end
				Properties.Refresh()
			end)
			sound.Parent = window.Gui
			Properties.PreviewSound = sound
		end

		if not soundObj then
			sound:Pause()
		else
			local newId = sound.SoundId ~= soundObj.SoundId
			sound.SoundId = soundObj.SoundId
			sound.PlaybackSpeed = soundObj.PlaybackSpeed
			sound.Volume = soundObj.Volume
			if newId then sound.TimePosition = 0 end
			if not noplay then sound:Resume() end

			coroutine.wrap(function()
				local previewTime = tick()
				Properties.SoundPreviewTime = previewTime
				while previewTime == Properties.SoundPreviewTime and sound.Playing do
					local entry = Properties.GetSoundPreviewEntry()
					if entry then
						local tl = sound.TimeLength
						local perc = sound.TimePosition/(tl == 0 and 1 or tl)
						entry.GuiElems.SoundPreviewSlider.Position = UDim2.new(perc,-4,0,-8)
					end
					Lib.FastWait()
				end
			end)()
			Properties.Refresh()
		end
	end

	Properties.DisplayAttributeContext = function(prop)
		local context = Properties.AttributeContext
		if not context then
			context = Lib.ContextMenu.new()
			context.Iconless = true
			context.Width = 80
		end
		context:Clear()

		context:Add({Name = "Edit", OnClick = function()
			Properties.DisplayAddAttributeWindow(prop)
		end})
		context:Add({Name = "Delete", OnClick = function()
			Properties.SetProp(prop,nil,true)
			Properties.ShowExplorerProps()
		end})

		context:Show()
	end

	Properties.DisplayAddAttributeWindow = function(editAttr)
		local win = Properties.AddAttributeWindow
		if not win then
			win = Lib.Window.new()
			win.Alignable = false
			win.Resizable = false
			win:SetTitle("Add Attribute")
			win:SetSize(200,130)

			local saveButton = Lib.Button.new()
			local nameLabel = Lib.Label.new()
			nameLabel.Text = "Name"
			nameLabel.Position = UDim2.new(0,30,0,10)
			nameLabel.Size = UDim2.new(0,40,0,20)
			win:Add(nameLabel)

			local nameBox = Lib.ViewportTextBox.new()
			nameBox.Position = UDim2.new(0,75,0,10)
			nameBox.Size = UDim2.new(0,120,0,20)
			win:Add(nameBox,"NameBox")
			nameBox.TextBox:GetPropertyChangedSignal("Text"):Connect(function()
				saveButton:SetDisabled(#nameBox:GetText() == 0)
			end)

			local typeLabel = Lib.Label.new()
			typeLabel.Text = "Type"
			typeLabel.Position = UDim2.new(0,30,0,40)
			typeLabel.Size = UDim2.new(0,40,0,20)
			win:Add(typeLabel)

			local typeChooser = Lib.DropDown.new()
			typeChooser.CanBeEmpty = false
			typeChooser.Position = UDim2.new(0,75,0,40)
			typeChooser.Size = UDim2.new(0,120,0,20)
			typeChooser:SetOptions(Properties.AllowedAttributeTypes)
			win:Add(typeChooser,"TypeChooser")

			local errorLabel = Lib.Label.new()
			errorLabel.Text = ""
			errorLabel.Position = UDim2.new(0,5,1,-45)
			errorLabel.Size = UDim2.new(1,-10,0,20)
			errorLabel.TextColor3 = Settings.Theme.Important
			win.ErrorLabel = errorLabel
			win:Add(errorLabel,"Error")

			local cancelButton = Lib.Button.new()
			cancelButton.Text = "Cancel"
			cancelButton.Position = UDim2.new(1,-97,1,-25)
			cancelButton.Size = UDim2.new(0,92,0,20)
			cancelButton.OnClick:Connect(function()
				win:Close()
			end)
			win:Add(cancelButton)

			saveButton.Text = "Save"
			saveButton.Position = UDim2.new(0,5,1,-25)
			saveButton.Size = UDim2.new(0,92,0,20)
			saveButton.OnClick:Connect(function()
				local name = nameBox:GetText()
				if #name > 100 then
					errorLabel.Text = "Error: Name over 100 chars"
					return
				elseif name:sub(1,3) == "RBX" then
					errorLabel.Text = "Error: Name begins with 'RBX'"
					return
				end

				local typ = typeChooser.Selected
				local valType = {Name = Properties.TypeNameConvert[typ] or typ, Category = "DataType"}
				local attrProp = {IsAttribute = true, Name = "ATTR_"..name, AttributeName = name, DisplayName = name, Class = "Instance", ValueType = valType, Category = "Attributes", Tags = {}}

				Settings.Properties.ShowAttributes = true
				Properties.SetProp(attrProp,Properties.DefaultPropValue[valType.Name],true,Properties.EditingAttribute)
				Properties.ShowExplorerProps()
				win:Close()
			end)
			win:Add(saveButton,"SaveButton")

			Properties.AddAttributeWindow = win
		end

		Properties.EditingAttribute = editAttr
		win:SetTitle(editAttr and "Edit Attribute "..editAttr.AttributeName or "Add Attribute")
		win.Elements.Error.Text = ""
		win.Elements.NameBox:SetText("")
		win.Elements.SaveButton:SetDisabled(true)
		win.Elements.TypeChooser:SetSelected(1)
		win:Show()
	end

	Properties.IsTextEditable = function(prop)
		local typeData = prop.ValueType
		local typeName = typeData.Name

		return typeName ~= "bool" and typeData.Category ~= "Enum" and typeData.Category ~= "Class" and typeName ~= "BrickColor"
	end

	Properties.DisplayEnumDropdown = function(entryIndex)
		local context = Properties.EnumContext
		if not context then
			context = Lib.ContextMenu.new()
			context.Iconless = true
			context.MaxHeight = 200
			context.ReverseYOffset = 22
			Properties.EnumDropdown = context
		end

		if not inputProp or inputProp.ValueType.Category ~= "Enum" then return end
		local prop = inputProp

		local entry = propEntries[entryIndex]
		local valueFrame = entry.GuiElems.ValueFrame

		local enum = Enum[prop.ValueType.Name]
		if not enum then return end

		local sorted = {}
		for name,enum in next,enum:GetEnumItems() do
			sorted[#sorted+1] = enum
		end
		table.sort(sorted,function(a,b) return a.Name < b.Name end)

		context:Clear()

		local function onClick(name)
			if prop ~= inputProp then return end

			local enumItem = enum[name]
			inputProp = nil
			Properties.SetProp(prop,enumItem)
		end

		for i = 1,#sorted do
			local enumItem = sorted[i]
			context:Add({Name = enumItem.Name, OnClick = onClick})
		end

		context.Width = valueFrame.AbsoluteSize.X
		context:Show(valueFrame.AbsolutePosition.X, valueFrame.AbsolutePosition.Y + 22)
	end

	Properties.DisplayBrickColorEditor = function(prop,entryIndex,col)
		local editor = Properties.BrickColorEditor
		if not editor then
			editor = Lib.BrickColorPicker.new()
			editor.Gui.DisplayOrder = Main.DisplayOrders.Menu
			editor.ReverseYOffset = 22

			editor.OnSelect:Connect(function(col)
				if not editor.CurrentProp or editor.CurrentProp.ValueType.Name ~= "BrickColor" then return end

				if editor.CurrentProp == inputProp then inputProp = nil end
				Properties.SetProp(editor.CurrentProp,BrickColor.new(col))
			end)

			editor.OnMoreColors:Connect(function() -- TODO: Special Case BasePart.BrickColor to BasePart.Color
				editor:Close()
				local colProp
				for i,v in pairs(API.Classes.BasePart.Properties) do
					if v.Name == "Color" then
						colProp = v
						break
					end
				end
				Properties.DisplayColorEditor(colProp,editor.SavedColor.Color)
			end)

			Properties.BrickColorEditor = editor
		end

		local entry = propEntries[entryIndex]
		local valueFrame = entry.GuiElems.ValueFrame

		editor.CurrentProp = prop
		editor.SavedColor = col
		if prop and prop.Class == "BasePart" and prop.Name == "BrickColor" then
			editor:SetMoreColorsVisible(true)
		else
			editor:SetMoreColorsVisible(false)
		end
		editor:Show(valueFrame.AbsolutePosition.X, valueFrame.AbsolutePosition.Y + 22)
	end

	Properties.DisplayColorEditor = function(prop,col)
		local editor = Properties.ColorEditor
		if not editor then
			editor = Lib.ColorPicker.new()

			editor.OnSelect:Connect(function(col)
				if not editor.CurrentProp then return end
				local typeName = editor.CurrentProp.ValueType.Name
				if typeName ~= "Color3" and typeName ~= "BrickColor" then return end

				local colVal = (typeName == "Color3" and col or BrickColor.new(col))

				if editor.CurrentProp == inputProp then inputProp = nil end
				Properties.SetProp(editor.CurrentProp,colVal)
			end)

			Properties.ColorEditor = editor
		end

		editor.CurrentProp = prop
		if col then
			editor:SetColor(col)
		else
			local firstVal = Properties.GetFirstPropVal(prop)
			if firstVal then editor:SetColor(firstVal) end
		end
		editor:Show()
	end

	Properties.DisplayNumberSequenceEditor = function(prop,seq)
		local editor = Properties.NumberSequenceEditor
		if not editor then
			editor = Lib.NumberSequenceEditor.new()

			editor.OnSelect:Connect(function(val)
				if not editor.CurrentProp or editor.CurrentProp.ValueType.Name ~= "NumberSequence" then return end

				if editor.CurrentProp == inputProp then inputProp = nil end
				Properties.SetProp(editor.CurrentProp,val)
			end)

			Properties.NumberSequenceEditor = editor
		end

		editor.CurrentProp = prop
		if seq then
			editor:SetSequence(seq)
		else
			local firstVal = Properties.GetFirstPropVal(prop)
			if firstVal then editor:SetSequence(firstVal) end
		end
		editor:Show()
	end

	Properties.DisplayColorSequenceEditor = function(prop,seq)
		local editor = Properties.ColorSequenceEditor
		if not editor then
			editor = Lib.ColorSequenceEditor.new()

			editor.OnSelect:Connect(function(val)
				if not editor.CurrentProp or editor.CurrentProp.ValueType.Name ~= "ColorSequence" then return end

				if editor.CurrentProp == inputProp then inputProp = nil end
				Properties.SetProp(editor.CurrentProp,val)
			end)

			Properties.ColorSequenceEditor = editor
		end

		editor.CurrentProp = prop
		if seq then
			editor:SetSequence(seq)
		else
			local firstVal = Properties.GetFirstPropVal(prop)
			if firstVal then editor:SetSequence(firstVal) end
		end
		editor:Show()
	end

	Properties.GetFirstPropVal = function(prop)
		local first = Properties.FindFirstObjWhichIsA(prop.Class)
		if first then
			return Properties.GetPropVal(prop,first)
		end
	end

	Properties.GetPropVal = function(prop,obj)
		if prop.MultiType then return "<Multiple Types>" end
		if not obj then return end

		local propVal
		if prop.IsAttribute then
			propVal = getAttribute(obj,prop.AttributeName)
			if propVal == nil then return nil end

			local typ = typeof(propVal)
			local currentType = Properties.TypeNameConvert[typ] or typ
			if prop.RootType then
				if prop.RootType.Name ~= currentType then
					return nil
				end
			elseif prop.ValueType.Name ~= currentType then
				return nil
			end
		else
			propVal = obj[prop.Name]
		end
		if prop.SubName then
			local indexes = string.split(prop.SubName,".")
			for i = 1,#indexes do
				local indexName = indexes[i]
				if #indexName > 0 and propVal then
					propVal = propVal[indexName]
				end
			end
		end

		return propVal
	end

	Properties.SelectObject = function(obj)
		if inputProp and inputProp.ValueType.Category == "Class" then
			local prop = inputProp
			inputProp = nil

			if isa(obj,prop.ValueType.Name) then
				Properties.SetProp(prop,obj)
			else
				Properties.Refresh()
			end

			return true
		end

		return false
	end

	Properties.DisplayProp = function(prop,entryIndex)
		local propName = prop.Name
		local typeData = prop.ValueType
		local typeName = typeData.Name
		local tags = prop.Tags
		local gName = prop.Class.."."..prop.Name..(prop.SubName or "")
		local propObj = autoUpdateObjs[gName]
		local entryData = propEntries[entryIndex]
		local UDim2 = UDim2

		local guiElems = entryData.GuiElems
		local valueFrame = guiElems.ValueFrame
		local valueBox = guiElems.ValueBox
		local colorButton = guiElems.ColorButton
		local colorPreview = guiElems.ColorPreview
		local gradient = guiElems.Gradient
		local enumArrow = guiElems.EnumArrow
		local checkbox = guiElems.Checkbox
		local rightButton = guiElems.RightButton
		local soundPreview = guiElems.SoundPreview

		local propVal = Properties.GetPropVal(prop,propObj)
		local inputFullName = inputProp and (inputProp.Class.."."..inputProp.Name..(inputProp.SubName or ""))

		local offset = 4
		local endOffset = 6

		-- Offsetting the ValueBox for ValueType specific buttons
		if (typeName == "Color3" or typeName == "BrickColor" or typeName == "ColorSequence") then
			colorButton.Visible = true
			enumArrow.Visible = false
			if propVal then
				gradient.Color = (typeName == "Color3" and ColorSequence.new(propVal)) or (typeName == "BrickColor" and ColorSequence.new(propVal.Color)) or propVal
			else
				gradient.Color = ColorSequence.new(Color3.new(1,1,1))
			end
			colorPreview.BorderColor3 = (typeName == "ColorSequence" and Color3.new(1,1,1) or Color3.new(0,0,0))
			offset = 22
			endOffset = 24 + (typeName == "ColorSequence" and 20 or 0)
		elseif typeData.Category == "Enum" then
			colorButton.Visible = false
			enumArrow.Visible = not prop.Tags.ReadOnly
			endOffset = 22
		elseif (gName == inputFullName and typeData.Category == "Class") or typeName == "NumberSequence" then
			colorButton.Visible = false
			enumArrow.Visible = false
			endOffset = 26
		else
			colorButton.Visible = false
			enumArrow.Visible = false
		end

		valueBox.Position = UDim2.new(0,offset,0,0)
		valueBox.Size = UDim2.new(1,-endOffset,1,0)

		-- Right button
		if inputFullName == gName and typeData.Category == "Class" then
			Main.MiscIcons:DisplayByKey(guiElems.RightButtonIcon, "Delete")
			guiElems.RightButtonIcon.Visible = true
			rightButton.Text = ""
			rightButton.Visible = true
		elseif typeName == "NumberSequence" or typeName == "ColorSequence" then
			guiElems.RightButtonIcon.Visible = false
			rightButton.Text = "..."
			rightButton.Visible = true
		else
			rightButton.Visible = false
		end

		-- Displays the correct ValueBox for the ValueType, and sets it to the prop value
		if typeName == "bool" or typeName == "PhysicalProperties" then
			valueBox.Visible = false
			checkbox.Visible = true
			soundPreview.Visible = false
			checkboxes[entryIndex].Disabled = tags.ReadOnly
			if typeName == "PhysicalProperties" and autoUpdateObjs[gName] then
				checkboxes[entryIndex]:SetState(propVal and true or false)
			else
				checkboxes[entryIndex]:SetState(propVal)
			end
		elseif typeName == "SoundPlayer" then
			valueBox.Visible = false
			checkbox.Visible = false
			soundPreview.Visible = true
			local playing = Properties.PreviewSound and Properties.PreviewSound.Playing
			Main.MiscIcons:DisplayByKey(soundPreview.ControlButton.Icon, playing and "Pause" or "Play")
		else
			valueBox.Visible = true
			checkbox.Visible = false
			soundPreview.Visible = false

			if propVal ~= nil then
				if typeName == "Color3" then
					valueBox.Text = "["..Lib.ColorToBytes(propVal).."]"
				elseif typeData.Category == "Enum" then
					valueBox.Text = propVal.Name
				elseif Properties.RoundableTypes[typeName] and Settings.Properties.NumberRounding then
					local rawStr = Properties.ValueToString(prop,propVal)
					valueBox.Text = rawStr:gsub("-?%d+%.%d+",function(num)
						return tostring(tonumber(("%."..Settings.Properties.NumberRounding.."f"):format(num)))
					end)
				else
					valueBox.Text = Properties.ValueToString(prop,propVal)
				end
			else
				valueBox.Text = ""
			end

			valueBox.TextColor3 = tags.ReadOnly and Settings.Theme.PlaceholderText or Settings.Theme.Text
		end
	end

	Properties.Refresh = function()
		local maxEntries = math.max(math.ceil((propsFrame.AbsoluteSize.Y) / 23),0)	
		local maxX = propsFrame.AbsoluteSize.X
		local valueWidth = math.max(Properties.MinInputWidth,maxX-Properties.ViewWidth)
		local inputPropVisible = false
		local isa = game.IsA
		local UDim2 = UDim2
		local stringSplit = string.split
		local scaleType = Settings.Properties.ScaleType

		-- Clear connections
		for i = 1,#propCons do
			propCons[i]:Disconnect()
		end
		table.clear(propCons)

		-- Hide full name viewer
		Properties.FullNameFrame.Visible = false
		Properties.FullNameFrameAttach.Disable()

		for i = 1,maxEntries do
			local entryData = propEntries[i]
			if not propEntries[i] then entryData = Properties.NewPropEntry(i) propEntries[i] = entryData end

			local entry = entryData.Gui
			local guiElems = entryData.GuiElems
			local nameFrame = guiElems.NameFrame
			local propNameLabel = guiElems.PropName
			local valueFrame = guiElems.ValueFrame
			local expand = guiElems.Expand
			local valueBox = guiElems.ValueBox
			local propNameBox = guiElems.PropName
			local rightButton = guiElems.RightButton
			local editAttributeButton = guiElems.EditAttributeButton
			local toggleAttributes = guiElems.ToggleAttributes

			local prop = viewList[i + Properties.Index]
			if prop then
				local entryXOffset = (scaleType == 0 and scrollH.Index or 0)
				entry.Visible = true
				entry.Position = UDim2.new(0,-entryXOffset,0,entry.Position.Y.Offset)
				entry.Size = UDim2.new(scaleType == 0 and 0 or 1, scaleType == 0 and Properties.ViewWidth + valueWidth or 0,0,22)

				if prop.SpecialRow then
					if prop.SpecialRow == "AddAttribute" then
						nameFrame.Visible = false
						valueFrame.Visible = false
						guiElems.RowButton.Visible = true
					end
				else
					-- Revert special row stuff
					nameFrame.Visible = true
					guiElems.RowButton.Visible = false

					local depth = Properties.EntryIndent*(prop.Depth or 1)
					local leftOffset = depth + Properties.EntryOffset
					nameFrame.Position = UDim2.new(0,leftOffset,0,0)
					propNameLabel.Size = UDim2.new(1,-2 - (scaleType == 0 and 0 or 6),1,0)

					local gName = (prop.CategoryName and "CAT_"..prop.CategoryName) or prop.Class.."."..prop.Name..(prop.SubName or "")

					if prop.CategoryName then
						entry.BackgroundColor3 = Settings.Theme.Main1
						valueFrame.Visible = false

						propNameBox.Text = prop.CategoryName
						propNameBox.Font = Enum.Font.SourceSansBold
						expand.Visible = true
						propNameBox.TextColor3 = Settings.Theme.Text
						nameFrame.BackgroundTransparency = 1
						nameFrame.Size = UDim2.new(1,0,1,0)
						editAttributeButton.Visible = false

						local showingAttrs = Settings.Properties.ShowAttributes
						toggleAttributes.Position = UDim2.new(1,-85-leftOffset,0,0)
						toggleAttributes.Text = (showingAttrs and "[Setting: ON]" or "[Setting: OFF]")
						toggleAttributes.TextColor3 = Settings.Theme.Text
						toggleAttributes.Visible = (prop.CategoryName == "Attributes")
					else
						local propName = prop.Name
						local typeData = prop.ValueType
						local typeName = typeData.Name
						local tags = prop.Tags
						local propObj = autoUpdateObjs[gName]

						local attributeOffset = (prop.IsAttribute and 20 or 0)
						editAttributeButton.Visible = (prop.IsAttribute and not prop.RootType)
						toggleAttributes.Visible = false

						-- Moving around the frames
						if scaleType == 0 then
							nameFrame.Size = UDim2.new(0,Properties.ViewWidth - leftOffset - 1,1,0)
							valueFrame.Position = UDim2.new(0,Properties.ViewWidth,0,0)
							valueFrame.Size = UDim2.new(0,valueWidth - attributeOffset,1,0)
						else
							nameFrame.Size = UDim2.new(0.5,-leftOffset - 1,1,0)
							valueFrame.Position = UDim2.new(0.5,0,0,0)
							valueFrame.Size = UDim2.new(0.5,-attributeOffset,1,0)
						end

						local nameArr = stringSplit(gName,".")
						propNameBox.Text = prop.DisplayName or nameArr[#nameArr]
						propNameBox.Font = Enum.Font.SourceSans
						entry.BackgroundColor3 = Settings.Theme.Main2
						valueFrame.Visible = true

						expand.Visible = typeData.Category == "DataType" and Properties.ExpandableTypes[typeName] or Properties.ExpandableProps[gName]
						propNameBox.TextColor3 = tags.ReadOnly and Settings.Theme.PlaceholderText or Settings.Theme.Text

						-- Display property value
						Properties.DisplayProp(prop,i)
						if propObj then
							if prop.IsAttribute then
								propCons[#propCons+1] = getAttributeChangedSignal(propObj,prop.AttributeName):Connect(function()
									Properties.DisplayProp(prop,i)
								end)
							else
								propCons[#propCons+1] = getPropChangedSignal(propObj,propName):Connect(function()
									Properties.DisplayProp(prop,i)
								end)
							end
						end

						-- Position and resize Input Box
						local beforeVisible = valueBox.Visible
						local inputFullName = inputProp and (inputProp.Class.."."..inputProp.Name..(inputProp.SubName or ""))
						if gName == inputFullName then
							nameFrame.BackgroundColor3 = Settings.Theme.ListSelection
							nameFrame.BackgroundTransparency = 0
							if typeData.Category == "Class" or typeData.Category == "Enum" or typeName == "BrickColor" then
								valueFrame.BackgroundColor3 = Settings.Theme.TextBox
								valueFrame.BackgroundTransparency = 0
								valueBox.Visible = true
							else
								inputPropVisible = true
								local scale = (scaleType == 0 and 0 or 0.5)
								local offset = (scaleType == 0 and Properties.ViewWidth-scrollH.Index or 0)
								local endOffset = 0

								if typeName == "Color3" or typeName == "ColorSequence" then
									offset = offset + 22
								end

								if typeName == "NumberSequence" or typeName == "ColorSequence" then
									endOffset = 20
								end

								inputBox.Position = UDim2.new(scale,offset,0,entry.Position.Y.Offset)
								inputBox.Size = UDim2.new(1-scale,-offset-endOffset-attributeOffset,0,22)
								inputBox.Visible = true
								valueBox.Visible = false
							end
						else
							nameFrame.BackgroundColor3 = Settings.Theme.Main1
							nameFrame.BackgroundTransparency = 1
							valueFrame.BackgroundColor3 = Settings.Theme.Main1
							valueFrame.BackgroundTransparency = 1
							valueBox.Visible = beforeVisible
						end
					end

					-- Expand
					if prop.CategoryName or Properties.ExpandableTypes[prop.ValueType and prop.ValueType.Name] or Properties.ExpandableProps[gName] then
						if Lib.CheckMouseInGui(expand) then
							Main.MiscIcons:DisplayByKey(expand.Icon, expanded[gName] and "Collapse_Over" or "Expand_Over")
						else
							Main.MiscIcons:DisplayByKey(expand.Icon, expanded[gName] and "Collapse" or "Expand")
						end
						expand.Visible = true
					else
						expand.Visible = false
					end
				end
				entry.Visible = true
			else
				entry.Visible = false
			end
		end

		if not inputPropVisible then
			inputBox.Visible = false
		end

		for i = maxEntries+1,#propEntries do
			propEntries[i].Gui:Destroy()
			propEntries[i] = nil
			checkboxes[i] = nil
		end
	end

	Properties.SetProp = function(prop,val,noupdate,prevAttribute)
		local sList = Explorer.Selection.List
		local propName = prop.Name
		local subName = prop.SubName
		local propClass = prop.Class
		local typeData = prop.ValueType
		local typeName = typeData.Name
		local attributeName = prop.AttributeName
		local rootTypeData = prop.RootType
		local rootTypeName = rootTypeData and rootTypeData.Name
		local fullName = prop.Class.."."..prop.Name..(prop.SubName or "")
		local Vector3 = Vector3

		for i = 1,#sList do
			local node = sList[i]
			local obj = node.Obj

			if isa(obj,propClass) then
				pcall(function()
					local setVal = val
					local root
					if prop.IsAttribute then
						root = getAttribute(obj,attributeName)
					else
						root = obj[propName]
					end

					if prevAttribute then
						if prevAttribute.ValueType.Name == typeName then
							setVal = getAttribute(obj,prevAttribute.AttributeName) or setVal
						end
						setAttribute(obj,prevAttribute.AttributeName,nil)
					end

					if rootTypeName then
						if rootTypeName == "Vector2" then
							setVal = Vector2.new((subName == ".X" and setVal) or root.X, (subName == ".Y" and setVal) or root.Y)
						elseif rootTypeName == "Vector3" then
							setVal = Vector3.new((subName == ".X" and setVal) or root.X, (subName == ".Y" and setVal) or root.Y, (subName == ".Z" and setVal) or root.Z)
						elseif rootTypeName == "UDim" then
							setVal = UDim.new((subName == ".Scale" and setVal) or root.Scale, (subName == ".Offset" and setVal) or root.Offset)
						elseif rootTypeName == "UDim2" then
							local rootX,rootY = root.X,root.Y
							local X_UDim = (subName == ".X" and setVal) or UDim.new((subName == ".X.Scale" and setVal) or rootX.Scale, (subName == ".X.Offset" and setVal) or rootX.Offset)
							local Y_UDim = (subName == ".Y" and setVal) or UDim.new((subName == ".Y.Scale" and setVal) or rootY.Scale, (subName == ".Y.Offset" and setVal) or rootY.Offset)
							setVal = UDim2.new(X_UDim,Y_UDim)
						elseif rootTypeName == "CFrame" then
							local rootPos,rootRight,rootUp,rootLook = root.Position,root.RightVector,root.UpVector,root.LookVector
							local pos = (subName == ".Position" and setVal) or Vector3.new((subName == ".Position.X" and setVal) or rootPos.X, (subName == ".Position.Y" and setVal) or rootPos.Y, (subName == ".Position.Z" and setVal) or rootPos.Z)
							local rightV = (subName == ".RightVector" and setVal) or Vector3.new((subName == ".RightVector.X" and setVal) or rootRight.X, (subName == ".RightVector.Y" and setVal) or rootRight.Y, (subName == ".RightVector.Z" and setVal) or rootRight.Z)
							local upV = (subName == ".UpVector" and setVal) or Vector3.new((subName == ".UpVector.X" and setVal) or rootUp.X, (subName == ".UpVector.Y" and setVal) or rootUp.Y, (subName == ".UpVector.Z" and setVal) or rootUp.Z)
							local lookV = (subName == ".LookVector" and setVal) or Vector3.new((subName == ".LookVector.X" and setVal) or rootLook.X, (subName == ".RightVector.Y" and setVal) or rootLook.Y, (subName == ".RightVector.Z" and setVal) or rootLook.Z)
							setVal = CFrame.fromMatrix(pos,rightV,upV,-lookV)
						elseif rootTypeName == "Rect" then
							local rootMin,rootMax = root.Min,root.Max
							local min = Vector2.new((subName == ".Min.X" and setVal) or rootMin.X, (subName == ".Min.Y" and setVal) or rootMin.Y)
							local max = Vector2.new((subName == ".Max.X" and setVal) or rootMax.X, (subName == ".Max.Y" and setVal) or rootMax.Y)
							setVal = Rect.new(min,max)
						elseif rootTypeName == "PhysicalProperties" then
							local rootProps = PhysicalProperties.new(obj.Material)
							local density = (subName == ".Density" and setVal) or (root and root.Density) or rootProps.Density
							local friction = (subName == ".Friction" and setVal) or (root and root.Friction) or rootProps.Friction
							local elasticity = (subName == ".Elasticity" and setVal) or (root and root.Elasticity) or rootProps.Elasticity
							local frictionWeight = (subName == ".FrictionWeight" and setVal) or (root and root.FrictionWeight) or rootProps.FrictionWeight
							local elasticityWeight = (subName == ".ElasticityWeight" and setVal) or (root and root.ElasticityWeight) or rootProps.ElasticityWeight
							setVal = PhysicalProperties.new(density,friction,elasticity,frictionWeight,elasticityWeight)
						elseif rootTypeName == "Ray" then
							local rootOrigin,rootDirection = root.Origin,root.Direction
							local origin = (subName == ".Origin" and setVal) or Vector3.new((subName == ".Origin.X" and setVal) or rootOrigin.X, (subName == ".Origin.Y" and setVal) or rootOrigin.Y, (subName == ".Origin.Z" and setVal) or rootOrigin.Z)
							local direction = (subName == ".Direction" and setVal) or Vector3.new((subName == ".Direction.X" and setVal) or rootDirection.X, (subName == ".Direction.Y" and setVal) or rootDirection.Y, (subName == ".Direction.Z" and setVal) or rootDirection.Z)
							setVal = Ray.new(origin,direction)
						elseif rootTypeName == "Faces" then
							local faces = {}
							local faceList = {"Back","Bottom","Front","Left","Right","Top"}
							for _,face in pairs(faceList) do
								local val
								if subName == "."..face then
									val = setVal
								else
									val = root[face]
								end
								if val then faces[#faces+1] = Enum.NormalId[face] end
							end
							setVal = Faces.new(unpack(faces))
						elseif rootTypeName == "Axes" then
							local axes = {}
							local axesList = {"X","Y","Z"}
							for _,axe in pairs(axesList) do
								local val
								if subName == "."..axe then
									val = setVal
								else
									val = root[axe]
								end
								if val then axes[#axes+1] = Enum.Axis[axe] end
							end
							setVal = Axes.new(unpack(axes))
						elseif rootTypeName == "NumberRange" then
							setVal = NumberRange.new(subName == ".Min" and setVal or root.Min, subName == ".Max" and setVal or root.Max)
						end
					end

					if typeName == "PhysicalProperties" and setVal then
						setVal = root or PhysicalProperties.new(obj.Material)
					end

					if prop.IsAttribute then
						setAttribute(obj,attributeName,setVal)
					else
						obj[propName] = setVal
					end
				end)
			end
		end

		if not noupdate then
			Properties.ComputeConflicts(prop)
		end
	end

	Properties.InitInputBox = function()
		inputBox = create({
			{1,"Frame",{BackgroundColor3=Color3.new(0.14901961386204,0.14901961386204,0.14901961386204),BorderSizePixel=0,Name="InputBox",Size=UDim2.new(0,200,0,22),Visible=false,ZIndex=2,}},
			{2,"TextBox",{BackgroundColor3=Color3.new(0.17647059261799,0.17647059261799,0.17647059261799),BackgroundTransparency=1,BorderColor3=Color3.new(0.062745101749897,0.51764708757401,1),BorderSizePixel=0,ClearTextOnFocus=false,Font=3,Parent={1},PlaceholderColor3=Color3.new(0.69803923368454,0.69803923368454,0.69803923368454),Position=UDim2.new(0,3,0,0),Size=UDim2.new(1,-6,1,0),Text="",TextColor3=Color3.new(1,1,1),TextSize=14,TextXAlignment=0,ZIndex=2,}},
		})
		inputTextBox = inputBox.TextBox
		inputBox.BackgroundColor3 = Settings.Theme.TextBox
		inputBox.Parent = Properties.Window.GuiElems.Content.List

		inputTextBox.FocusLost:Connect(function()
			if not inputProp then return end

			local prop = inputProp
			inputProp = nil
			local val = Properties.StringToValue(prop,inputTextBox.Text)
			if val then Properties.SetProp(prop,val) else Properties.Refresh() end
		end)

		inputTextBox.Focused:Connect(function()
			inputTextBox.SelectionStart = 1
			inputTextBox.CursorPosition = #inputTextBox.Text + 1
		end)

		Lib.ViewportTextBox.convert(inputTextBox)
	end

	Properties.SetInputProp = function(prop,entryIndex,special)
		local typeData = prop.ValueType
		local typeName = typeData.Name
		local fullName = prop.Class.."."..prop.Name..(prop.SubName or "")
		local propObj = autoUpdateObjs[fullName]
		local propVal = Properties.GetPropVal(prop,propObj)

		if prop.Tags.ReadOnly then return end

		inputProp = prop
		if special then
			if special == "color" then
				if typeName == "Color3" then
					inputTextBox.Text = propVal and Properties.ValueToString(prop,propVal) or ""
					Properties.DisplayColorEditor(prop,propVal)
				elseif typeName == "BrickColor" then
					Properties.DisplayBrickColorEditor(prop,entryIndex,propVal)
				elseif typeName == "ColorSequence" then
					inputTextBox.Text = propVal and Properties.ValueToString(prop,propVal) or ""
					Properties.DisplayColorSequenceEditor(prop,propVal)
				end
			elseif special == "right" then
				if typeName == "NumberSequence" then
					inputTextBox.Text = propVal and Properties.ValueToString(prop,propVal) or ""
					Properties.DisplayNumberSequenceEditor(prop,propVal)
				elseif typeName == "ColorSequence" then
					inputTextBox.Text = propVal and Properties.ValueToString(prop,propVal) or ""
					Properties.DisplayColorSequenceEditor(prop,propVal)
				end
			end
		else
			if Properties.IsTextEditable(prop) then
				inputTextBox.Text = propVal and Properties.ValueToString(prop,propVal) or ""
				inputTextBox:CaptureFocus()
			elseif typeData.Category == "Enum" then
				Properties.DisplayEnumDropdown(entryIndex)
			elseif typeName == "BrickColor" then
				Properties.DisplayBrickColorEditor(prop,entryIndex,propVal)
			end
		end
		Properties.Refresh()
	end

	Properties.InitSearch = function()
		local searchBox = Properties.GuiElems.ToolBar.SearchFrame.SearchBox

		Lib.ViewportTextBox.convert(searchBox)

		searchBox:GetPropertyChangedSignal("Text"):Connect(function()
			Properties.SearchText = searchBox.Text
			Properties.Update()
			Properties.Refresh()
		end)
	end

	Properties.InitEntryStuff = function()
		Properties.EntryTemplate = create({
			{1,"TextButton",{AutoButtonColor=false,BackgroundColor3=Color3.new(0.17647059261799,0.17647059261799,0.17647059261799),BorderColor3=Color3.new(0.1294117718935,0.1294117718935,0.1294117718935),Font=3,Name="Entry",Position=UDim2.new(0,1,0,1),Size=UDim2.new(0,250,0,22),Text="",TextSize=14,}},
			{2,"Frame",{BackgroundColor3=Color3.new(0.04313725605607,0.35294118523598,0.68627452850342),BackgroundTransparency=1,BorderColor3=Color3.new(0.33725491166115,0.49019610881805,0.73725491762161),BorderSizePixel=0,Name="NameFrame",Parent={1},Position=UDim2.new(0,20,0,0),Size=UDim2.new(1,-40,1,0),}},
			{3,"TextLabel",{BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=1,Font=3,Name="PropName",Parent={2},Position=UDim2.new(0,2,0,0),Size=UDim2.new(1,-2,1,0),Text="Anchored",TextColor3=Color3.new(1,1,1),TextSize=14,TextTransparency=0.10000000149012,TextTruncate=1,TextXAlignment=0,}},
			{4,"TextButton",{BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=1,ClipsDescendants=true,Font=3,Name="Expand",Parent={2},Position=UDim2.new(0,-20,0,1),Size=UDim2.new(0,20,0,20),Text="",TextSize=14,Visible=false,}},
			{5,"ImageLabel",{BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=1,Image="rbxassetid://5642383285",ImageRectOffset=Vector2.new(144,16),ImageRectSize=Vector2.new(16,16),Name="Icon",Parent={4},Position=UDim2.new(0,2,0,2),ScaleType=4,Size=UDim2.new(0,16,0,16),}},
			{6,"TextButton",{BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=1,BorderSizePixel=0,Font=4,Name="ToggleAttributes",Parent={2},Position=UDim2.new(1,-85,0,0),Size=UDim2.new(0,85,0,22),Text="[SETTING: OFF]",TextColor3=Color3.new(1,1,1),TextSize=14,TextTransparency=0.10000000149012,Visible=false,}},
			{7,"Frame",{BackgroundColor3=Color3.new(0.04313725605607,0.35294118523598,0.68627452850342),BackgroundTransparency=1,BorderColor3=Color3.new(0.33725491166115,0.49019607901573,0.73725491762161),BorderSizePixel=0,Name="ValueFrame",Parent={1},Position=UDim2.new(1,-100,0,0),Size=UDim2.new(0,80,1,0),}},
			{8,"Frame",{BackgroundColor3=Color3.new(0.14117647707462,0.14117647707462,0.14117647707462),BorderColor3=Color3.new(0.33725491166115,0.49019610881805,0.73725491762161),BorderSizePixel=0,Name="Line",Parent={7},Position=UDim2.new(0,-1,0,0),Size=UDim2.new(0,1,1,0),}},
			{9,"TextButton",{BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=1,BorderSizePixel=0,Font=3,Name="ColorButton",Parent={7},Size=UDim2.new(0,20,0,22),Text="",TextColor3=Color3.new(1,1,1),TextSize=14,Visible=false,}},
			{10,"Frame",{BackgroundColor3=Color3.new(1,1,1),BorderColor3=Color3.new(0,0,0),Name="ColorPreview",Parent={9},Position=UDim2.new(0,5,0,6),Size=UDim2.new(0,10,0,10),}},
			{11,"UIGradient",{Parent={10},}},
			{12,"Frame",{BackgroundTransparency=1,Name="EnumArrow",Parent={7},Position=UDim2.new(1,-16,0,3),Size=UDim2.new(0,16,0,16),Visible=false,}},
			{13,"Frame",{BackgroundColor3=Color3.new(0.86274510622025,0.86274510622025,0.86274510622025),BorderSizePixel=0,Parent={12},Position=UDim2.new(0,8,0,9),Size=UDim2.new(0,1,0,1),}},
			{14,"Frame",{BackgroundColor3=Color3.new(0.86274510622025,0.86274510622025,0.86274510622025),BorderSizePixel=0,Parent={12},Position=UDim2.new(0,7,0,8),Size=UDim2.new(0,3,0,1),}},
			{15,"Frame",{BackgroundColor3=Color3.new(0.86274510622025,0.86274510622025,0.86274510622025),BorderSizePixel=0,Parent={12},Position=UDim2.new(0,6,0,7),Size=UDim2.new(0,5,0,1),}},
			{16,"TextButton",{BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=1,Font=3,Name="ValueBox",Parent={7},Position=UDim2.new(0,4,0,0),Size=UDim2.new(1,-8,1,0),Text="",TextColor3=Color3.new(1,1,1),TextSize=14,TextTransparency=0.10000000149012,TextTruncate=1,TextXAlignment=0,}},
			{17,"TextButton",{BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=1,BorderSizePixel=0,Font=3,Name="RightButton",Parent={7},Position=UDim2.new(1,-20,0,0),Size=UDim2.new(0,20,0,22),Text="...",TextColor3=Color3.new(1,1,1),TextSize=14,Visible=false,}},
			{18,"TextButton",{BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=1,BorderSizePixel=0,Font=3,Name="SettingsButton",Parent={7},Position=UDim2.new(1,-20,0,0),Size=UDim2.new(0,20,0,22),Text="",TextColor3=Color3.new(1,1,1),TextSize=14,Visible=false,}},
			{19,"Frame",{BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=1,Name="SoundPreview",Parent={7},Size=UDim2.new(1,0,1,0),Visible=false,}},
			{20,"TextButton",{BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=1,BorderSizePixel=0,Font=3,Name="ControlButton",Parent={19},Size=UDim2.new(0,20,0,22),Text="",TextColor3=Color3.new(1,1,1),TextSize=14,}},
			{21,"ImageLabel",{BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=1,Image="rbxassetid://5642383285",ImageRectOffset=Vector2.new(144,16),ImageRectSize=Vector2.new(16,16),Name="Icon",Parent={20},Position=UDim2.new(0,2,0,3),ScaleType=4,Size=UDim2.new(0,16,0,16),}},
			{22,"Frame",{BackgroundColor3=Color3.new(0.3137255012989,0.3137255012989,0.3137255012989),BorderSizePixel=0,Name="TimeLine",Parent={19},Position=UDim2.new(0,26,0.5,-1),Size=UDim2.new(1,-34,0,2),}},
			{23,"Frame",{BackgroundColor3=Color3.new(0.2352941185236,0.2352941185236,0.2352941185236),BorderColor3=Color3.new(0.1294117718935,0.1294117718935,0.1294117718935),Name="Slider",Parent={22},Position=UDim2.new(0,-4,0,-8),Size=UDim2.new(0,8,0,18),}},
			{24,"TextButton",{BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=1,BorderSizePixel=0,Font=3,Name="EditAttributeButton",Parent={1},Position=UDim2.new(1,-20,0,0),Size=UDim2.new(0,20,0,22),Text="",TextColor3=Color3.new(1,1,1),TextSize=14,}},
			{25,"ImageLabel",{BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=1,Image="rbxassetid://5034718180",ImageTransparency=0.20000000298023,Name="Icon",Parent={24},Position=UDim2.new(0,2,0,3),Size=UDim2.new(0,16,0,16),}},
			{26,"TextButton",{AutoButtonColor=false,BackgroundColor3=Color3.new(0.2352941185236,0.2352941185236,0.2352941185236),BorderSizePixel=0,Font=3,Name="RowButton",Parent={1},Size=UDim2.new(1,0,1,0),Text="Add Attribute",TextColor3=Color3.new(1,1,1),TextSize=14,TextTransparency=0.10000000149012,Visible=false,}},
			--{27,"UIStroke",{ApplyStrokeMode=Enum.ApplyStrokeMode.Border,Color=Color3.fromRGB(33,33,33),Thickness=1,Parent={1}}}
		})

		local fullNameFrame = Lib.Frame.new()
		local label = Lib.Label.new()
		label.Parent = fullNameFrame.Gui
		label.Position = UDim2.new(0,2,0,0)
		label.Size = UDim2.new(1,-4,1,0)
		fullNameFrame.Visible = false
		fullNameFrame.Parent = window.Gui
		
		if Settings.Window.Transparency and Settings.Window.Transparency > 0 then
			Properties.EntryTemplate.BackgroundTransparency = 0.75
		end


		Properties.FullNameFrame = fullNameFrame
		Properties.FullNameFrameAttach = Lib.AttachTo(fullNameFrame)
	end

	Properties.Init = function() -- TODO: MAKE BETTER
		local guiItems = create({
			{1,"Folder",{Name="Items",}},
			{2,"Frame",{BackgroundColor3=Color3.new(0.20392157137394,0.20392157137394,0.20392157137394),BorderSizePixel=0,Name="ToolBar",Parent={1},Size=UDim2.new(1,0,0,22),}},
			{3,"Frame",{BackgroundColor3=Color3.new(0.14901961386204,0.14901961386204,0.14901961386204),BorderColor3=Color3.new(0.1176470592618,0.1176470592618,0.1176470592618),BorderSizePixel=0,Name="SearchFrame",Parent={2},Position=UDim2.new(0,3,0,1),Size=UDim2.new(1,-6,0,18),}},
			{4,"TextBox",{BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=1,ClearTextOnFocus=false,Font=3,Name="SearchBox",Parent={3},PlaceholderColor3=Color3.new(0.39215689897537,0.39215689897537,0.39215689897537),PlaceholderText="Search properties",Position=UDim2.new(0,4,0,0),Size=UDim2.new(1,-24,0,18),Text="",TextColor3=Color3.new(1,1,1),TextSize=14,TextXAlignment=0,}},
			{5,"UICorner",{CornerRadius=UDim.new(0,2),Parent={3},}},
			{6,"TextButton",{AutoButtonColor=false,BackgroundColor3=Color3.new(0.12549020349979,0.12549020349979,0.12549020349979),BackgroundTransparency=1,BorderSizePixel=0,Font=3,Name="Reset",Parent={3},Position=UDim2.new(1,-17,0,1),Size=UDim2.new(0,16,0,16),Text="",TextColor3=Color3.new(1,1,1),TextSize=14,}},
			{7,"ImageLabel",{BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=1,Image="rbxassetid://5034718129",ImageColor3=Color3.new(0.39215686917305,0.39215686917305,0.39215686917305),Parent={6},Size=UDim2.new(0,16,0,16),}},
			{8,"TextButton",{AutoButtonColor=false,BackgroundColor3=Color3.new(0.12549020349979,0.12549020349979,0.12549020349979),BackgroundTransparency=1,BorderSizePixel=0,Font=3,Name="Refresh",Parent={2},Position=UDim2.new(1,-20,0,1),Size=UDim2.new(0,18,0,18),Text="",TextColor3=Color3.new(1,1,1),TextSize=14,Visible=false,}},
			{9,"ImageLabel",{BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=1,Image="rbxassetid://5642310344",Parent={8},Position=UDim2.new(0,3,0,3),Size=UDim2.new(0,12,0,12),}},
			{10,"Frame",{BackgroundColor3=Color3.new(0.15686275064945,0.15686275064945,0.15686275064945),BorderSizePixel=0,Name="ScrollCorner",Parent={1},Position=UDim2.new(1,-16,1,-16),Size=UDim2.new(0,16,0,16),Visible=false,}},
			{11,"Frame",{BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=1,ClipsDescendants=true,Name="List",Parent={1},Position=UDim2.new(0,0,0,23),Size=UDim2.new(1,0,1,-23),}},
		})

		-- Vars
		categoryOrder =  API.CategoryOrder
		for category,_ in next,categoryOrder do
			if not Properties.CollapsedCategories[category] then
				expanded["CAT_"..category] = true
			end
		end
		expanded["Sound.SoundId"] = true

		-- Init window
		window = Lib.Window.new()
		Properties.Window = window
		window:SetTitle("Properties")

		toolBar = guiItems.ToolBar
		propsFrame = guiItems.List

		Properties.GuiElems.ToolBar = toolBar
		Properties.GuiElems.PropsFrame = propsFrame

		Properties.InitEntryStuff()

		-- Window events
		window.GuiElems.Main:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
			if Properties.Window:IsContentVisible() then
				Properties.UpdateView()
				Properties.Refresh()
			end
		end)
		window.OnActivate:Connect(function()
			Properties.UpdateView()
			Properties.Update()
			Properties.Refresh()
		end)
		window.OnRestore:Connect(function()
			Properties.UpdateView()
			Properties.Update()
			Properties.Refresh()
		end)

		-- Init scrollbars
		scrollV = Lib.ScrollBar.new()		
		scrollV.WheelIncrement = 3
		scrollV.Gui.Position = UDim2.new(1,-16,0,23)
		scrollV:SetScrollFrame(propsFrame)
		scrollV.Scrolled:Connect(function()
			Properties.Index = scrollV.Index
			Properties.Refresh()
		end)

		scrollH = Lib.ScrollBar.new(true)
		scrollH.Increment = 5
		scrollH.WheelIncrement = 20
		scrollH.Gui.Position = UDim2.new(0,0,1,-16)
		scrollH.Scrolled:Connect(function()
			Properties.Refresh()
		end)

		-- Setup Gui
		window.GuiElems.Line.Position = UDim2.new(0,0,0,22)
		toolBar.Parent = window.GuiElems.Content
		propsFrame.Parent = window.GuiElems.Content
		guiItems.ScrollCorner.Parent = window.GuiElems.Content
		scrollV.Gui.Parent = window.GuiElems.Content
		scrollH.Gui.Parent = window.GuiElems.Content
		Properties.InitInputBox()
		Properties.InitSearch()
	end

	Properties.Uninit = function()
		for index, connection in pairs(propCons) do
			if connection then pcall(connection.Disconnect, connection) end
			propCons[index] = nil
		end
	end

	return Properties
end

-- TODO: Remove when open source
if gethsfuncs then
	_G.moduleData = {InitDeps = initDeps, InitAfterMain = initAfterMain, Main = main}
else
	return {InitDeps = initDeps, InitAfterMain = initAfterMain, Main = main}
end

end,
["SaveInstance"] = function()
--[[
	Save Instance App Module
	
	Revival of the old dex's Save Instance
]] 

-- Common Locals
local Main,Lib,Apps,Settings -- Main Containers
local Explorer, Properties, ScriptViewer, SaveInstance, Notebook -- Major Apps
local API,RMD,env,service,plr,create,createSimple -- Main Locals

local function initDeps(data)
	Main = data.Main
	Lib = data.Lib
	Apps = data.Apps
	Settings = data.Settings

	API = data.API
	RMD = data.RMD
	env = data.env
	service = data.service
	plr = data.plr
	create = data.create
	createSimple = data.createSimple
end

local function initAfterMain()
	Explorer = Apps.Explorer
	Properties = Apps.Properties
	ScriptViewer = Apps.ScriptViewer
	SaveInstance = Apps.SaveInstance
	Notebook = Apps.Notebook
end

local function main()
	local SaveInstance = {}
	local window, ListFrame
	local placeName = "Place"
	pcall(function()
		placeName = game:GetService("MarketplaceService"):GetProductInfoAsync(game.PlaceId).Name
	end)
	local fileName = env.parsefile("Place_"..game.PlaceId.."_"..placeName.."_{TIMESTAMP}")
	local Saving = false
	
	local SaveInstanceArgs = {
		Decompile = Settings.Save.DecompileScripts,
		DecompileTimeout = 30,
		BytecodeTimeout = 15,
		DecompileIgnore = {"TextChatService"},
		DecompileIgnoreNames = {},
		SaveBytecode = Settings.Save.SaveScriptBytecode,
		NilInstances = false,
		SavePlayerCharacters = false,
		IsolatePlayers = false,
		ShowStatus = true,
		IgnoreDefaultProperties = true,
		IsolateStarterPlayer = true
	}
	
	local function AddCheckbox(title, default)
		local frame = Lib.Frame.new()
		frame.Gui.Parent = ListFrame
		frame.Gui.Transparency = 1
		frame.Gui.Size = UDim2.new(1,0,0,20)
		
		local listlayout = Instance.new("UIListLayout")
		listlayout.Parent = frame.Gui
		listlayout.FillDirection = Enum.FillDirection.Horizontal
		listlayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
		listlayout.VerticalAlignment = Enum.VerticalAlignment.Center
		listlayout.Padding = UDim.new(0, 10)
		
		-- Checkbox
		local checkbox = Lib.Checkbox.new()
		
		checkbox.Gui.Parent = frame.Gui
		checkbox.Gui.Size = UDim2.new(0,15,0,15)
		
		-- Label
		local label = Lib.Label.new()
		
		label.Gui.Parent = frame.Gui
		label.Gui.Size = UDim2.new(1, 0,1, -15)
		label.Gui.Text = title
		label.TextTruncate = Enum.TextTruncate.AtEnd
		
		checkbox:SetState(default)
		
		return checkbox
	end
	
	local function AddTextbox(title, default, sizeX)
		default = tostring(default)
		local frame = Lib.Frame.new()
		frame.Gui.Parent = ListFrame
		frame.Gui.Transparency = 1
		frame.Gui.Size = UDim2.new(1,0,0,20)

		local listlayout = Instance.new("UIListLayout")
		listlayout.Parent = frame.Gui
		listlayout.FillDirection = Enum.FillDirection.Horizontal
		listlayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
		listlayout.VerticalAlignment = Enum.VerticalAlignment.Center
		listlayout.Padding = UDim.new(0, 10)

		-- Textbox
		local textbox = Instance.new("TextBox") -- replaced cuz why Moon make every inputs only work on mouse/pc users >:( 
		textbox.BackgroundColor3 = Settings.Theme.TextBox
		textbox.BorderColor3 = Settings.Theme.Outline3
		textbox.ClearTextOnFocus = false
		textbox.TextColor3 = Settings.Theme.Text
		textbox.Font = Enum.Font.SourceSans
		textbox.TextSize = 14
		textbox.ZIndex = 2

		textbox.Parent = frame.Gui
		if sizeX and type(sizeX) == "number" then
			textbox.Size = UDim2.new(0,sizeX,0,15)
		else
			textbox.Size = UDim2.new(0,45,0,15)
		end
		
		frame.Gui.AutomaticSize = Enum.AutomaticSize.X
		textbox.AutomaticSize = Enum.AutomaticSize.X

		-- Label
		local label = Lib.Label.new()

		label.Parent = frame.Gui
		label.Size = UDim2.new(1, 0,1, -15)
		label.Text = title
		label.TextTruncate = Enum.TextTruncate.AtEnd

		textbox.Text = default

		return {TextBox = textbox}
	end
	
	SaveInstance.Init = function()
		window = Lib.Window.new()
		window:SetTitle("Save Instance")
		window:Resize(350,350)
		SaveInstance.Window = window
		
		-- ListFrame
		
		-- Fake ScrollBar dex, because its too advanced
		ListFrame = Instance.new("ScrollingFrame")
		ListFrame.Parent = window.GuiElems.Content
		ListFrame.Size = UDim2.new(1, 0,1, -60)
		ListFrame.Position = UDim2.new(0, 0, 0, 0)
		ListFrame.Transparency = 1
		ListFrame.CanvasSize = UDim2.new(0,0,0,0)
		ListFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
		ListFrame.ScrollBarThickness = 16
		ListFrame.BottomImage = ""
		ListFrame.TopImage = ""
		ListFrame.ScrollBarImageColor3 = Color3.fromRGB(70, 70, 70)
		ListFrame.ScrollBarImageTransparency = 0
		ListFrame.ZIndex = 2
		ListFrame.BorderSizePixel = 0
		
		local scrollbar = Lib.ScrollBar.new()
		scrollbar.Gui.Parent = window.GuiElems.Content
		scrollbar.Gui.Size = UDim2.new(1, 0,1, -60)
		scrollbar.Gui.Up.ZIndex = 3
		scrollbar.Gui.Down.ZIndex = 3
		
		ListFrame:GetPropertyChangedSignal("AbsoluteWindowSize"):Connect(function()
			if ListFrame.AbsoluteCanvasSize ~= ListFrame.AbsoluteWindowSize then
				scrollbar.Gui.Visible = true
			else
				scrollbar.Gui.Visible = false
			end
		end)
		
		local ListLayout = Instance.new("UIListLayout")
		ListLayout.Parent = ListFrame
		ListLayout.Padding = UDim.new(0, 5)
		
		local Padding = Instance.new("UIPadding")
		Padding.Parent = ListFrame
		Padding.PaddingBottom = UDim.new(0, 5)
		Padding.PaddingLeft = UDim.new(0, 10)
		Padding.PaddingRight = UDim.new(0, 10)
		Padding.PaddingTop = UDim.new(0, 5)
		
		-- Options
		
		local Decompile = AddCheckbox("Decompile scripts (requires executor support)", SaveInstanceArgs.Decompile)
		Decompile.OnInput:Connect(function()
			SaveInstanceArgs.Decompile = Decompile.Toggled
			Settings.Save.DecompileScripts = Decompile.Toggled
			pcall(Main.SaveCurrentSettings)
		end)

		local SaveBytecode = AddCheckbox("Save script bytecode (requires executor support)", SaveInstanceArgs.SaveBytecode)
		SaveBytecode.OnInput:Connect(function()
			SaveInstanceArgs.SaveBytecode = SaveBytecode.Toggled
			Settings.Save.SaveScriptBytecode = SaveBytecode.Toggled
			pcall(Main.SaveCurrentSettings)
		end)
		
		local NilObj = AddCheckbox("Save Nil Instances", SaveInstanceArgs.NilInstances)
		NilObj.OnInput:Connect(function()
			SaveInstanceArgs.NilInstances = NilObj.Toggled
		end)

		local SavePlayerChar = AddCheckbox("Save Player Characters", SaveInstanceArgs.SavePlayerCharacters)
		SavePlayerChar.OnInput:Connect(function()
			SaveInstanceArgs.SavePlayerCharacters = SavePlayerChar.Toggled
		end)
		
		local SavePlayerObj = AddCheckbox("Include Players service content", SaveInstanceArgs.IsolatePlayers)
		SavePlayerObj.OnInput:Connect(function()
			SaveInstanceArgs.IsolatePlayers = SavePlayerObj.Toggled
		end)
		
		local IsolateStarterPlr = AddCheckbox("Isolate StarterPlayer", SaveInstanceArgs.IsolateStarterPlayer)
		IsolateStarterPlr.OnInput:Connect(function()
			SaveInstanceArgs.IsolateStarterPlayer = IsolateStarterPlr.Toggled
		end)
		
		local IgnoreDefaultProps = AddCheckbox("Ignore Default Properties", SaveInstanceArgs.IgnoreDefaultProperties)
		IgnoreDefaultProps.OnInput:Connect(function()
			SaveInstanceArgs.IgnoreDefaultProperties = IgnoreDefaultProps.Toggled
		end)
		
		local ShowStat = AddCheckbox("Show Status", SaveInstanceArgs.ShowStatus)
		ShowStat.OnInput:Connect(function()
			SaveInstanceArgs.ShowStatus = ShowStat.Toggled
		end)
		
		
		-- Save location and file name below
		local FolderTextBox = Lib.ViewportTextBox.new()
		FolderTextBox.Gui.Parent = window.GuiElems.Content
		FolderTextBox.Size = UDim2.new(1,0, 0,20)
		FolderTextBox.Position = UDim2.new(0,0, 1,-60)
		FolderTextBox.TextBox.PlaceholderText = "Save folder (relative to executor workspace)"
		FolderTextBox.TextBox.Text = Settings.Save.Folder

		local FilenameTextBox = Lib.ViewportTextBox.new()
		FilenameTextBox.Gui.Parent = window.GuiElems.Content
		FilenameTextBox.Size = UDim2.new(1,0, 0,20)
		FilenameTextBox.Position = UDim2.new(0,0, 1,-40)
		FilenameTextBox.TextBox.PlaceholderText = "File name"
		
		local textpadding = Instance.new("UIPadding")
		textpadding.Parent = FilenameTextBox.Gui
		textpadding.PaddingLeft = UDim.new(0, 5)
		textpadding.PaddingRight = UDim.new(0, 5)

		local folderPadding = Instance.new("UIPadding")
		folderPadding.Parent = FolderTextBox.Gui
		folderPadding.PaddingLeft = UDim.new(0, 5)
		folderPadding.PaddingRight = UDim.new(0, 5)
		
		local BackgroundButton = Lib.Frame.new()
		BackgroundButton.Gui.Parent = window.GuiElems.Content
		BackgroundButton.Size = UDim2.new(1,0, 0,20)
		BackgroundButton.Position = UDim2.new(0,0, 1,-20)
		
		local LabelButton = Lib.Label.new()
		LabelButton.Gui.Parent = window.GuiElems.Content
		LabelButton.Size = UDim2.new(1,0, 0,20)
		LabelButton.Position = UDim2.new(0,0, 1,-20)
		LabelButton.Gui.Text = "Save"
		LabelButton.Gui.TextXAlignment = Enum.TextXAlignment.Center
		
		local Button = Instance.new("TextButton")
		Button.Parent = BackgroundButton.Gui
		Button.Size = UDim2.new(1,0, 1,0)
		Button.Position = UDim2.new(0,0, 0,0)
		Button.Transparency = 1
		
		FilenameTextBox.TextBox.Text = fileName
		Button.MouseButton1Click:Connect(function()
			if Saving or env.issavinginstance() then
				env.notify("Dex++ Save Instance", "Another export is already in progress", 6)
				return
			end

			local requestedFileName = FilenameTextBox.TextBox.Text:gsub("{TIMESTAMP}", os.date("%d-%m-%Y_%H-%M-%S"))
			if requestedFileName:match("^%s*$") then
				env.notify("Dex++ Save Instance - Error", "Enter a file name", 6)
				return
			end
			local folder = env.normalizepath(FolderTextBox.TextBox.Text)
			Settings.Save.Folder = folder
			pcall(Main.SaveCurrentSettings)
			local requestedPath = env.joinpath(folder, requestedFileName)

			Saving = true
			Button.Active = false
			LabelButton.Gui.Text = "Saving..."
			window:SetTitle("Save Instance - Saving")

			task.spawn(function()
				local success, result, savedPath = pcall(env.saveinstance, game, requestedPath, SaveInstanceArgs)
				if success then
					pcall(window.SetTitle, window, "Save Instance - Saved")
					env.notify("Dex++ Save Instance", "Saved as " .. tostring(savedPath), 10)
				else
					local message = tostring(result)
					pcall(window.SetTitle, window, "Save Instance - Error")
					env.notify("Dex++ Save Instance - Error", message:sub(1, 350), 12)
					warn("Failed to save the game: " .. message)
				end

				Saving = false
				pcall(function()
					Button.Active = true
					LabelButton.Gui.Text = "Save"
				end)
				task.wait(4)
				if not Saving then pcall(window.SetTitle, window, "Save Instance") end
			end)
		end)
	end

	return SaveInstance
end

-- TODO: Remove when open source
if gethsfuncs then
	_G.moduleData = {InitDeps = initDeps, InitAfterMain = initAfterMain, Main = main}
else
	return {InitDeps = initDeps, InitAfterMain = initAfterMain, Main = main}
end

end,
["ScriptViewer"] = function()
--[[
	Script Viewer App Module
	
	A script viewer that is basically a notepad
]]
-- Common Locals
local Main,Lib,Apps,Settings -- Main Containers
local Explorer, Properties, ScriptViewer, Notebook -- Major Apps
local API,RMD,env,service,plr,create,createSimple -- Main Locals

local function initDeps(data)
	Main = data.Main
	Lib = data.Lib
	Apps = data.Apps
	Settings = data.Settings

	API = data.API
	RMD = data.RMD
	env = data.env
	service = data.service
	plr = data.plr
	create = data.create
	createSimple = data.createSimple
end

local function initAfterMain()
	Explorer = Apps.Explorer
	Properties = Apps.Properties
	ScriptViewer = Apps.ScriptViewer
	Notebook = Apps.Notebook
end

local executorName = "Unknown"
local executorVersion = "???"
if identifyexecutor then
	local name,ver = identifyexecutor()
	executorName = name
	executorVersion = ver
elseif game:GetService("RunService"):IsStudio() then
	executorName = "Studio"
	executorVersion = version()
end

local function getPath(obj)
	if obj.Parent == nil then
		return "Nil parented"
	else
		return Explorer.GetInstancePath(obj)
	end
end

local function main()
	local ScriptViewer = {}
	local window, codeFrame
	
	local execute, clear, dumpbtn
	
	local PreviousScr = nil
	
	ScriptViewer.DumpFunctions = function(scr)
		-- thanks King.Kevin#6025 you'll obviously be credited (no discord tag since that can easily be impersonated)
		local getgc = getgc or get_gc_objects
		local getupvalues = env.getupvalues
		local getconstants = env.getconstants
		local getinfo = (debug and (debug.getinfo or debug.info)) or getinfo
		if not getgc or not getupvalues or not getconstants or not getinfo or not getfenv then
			env.notify("Dex++ Function Dumper", "This executor is missing one or more debug functions", 8)
			return false
		end
		local original = ("\n-- // Function Dumper made by King.Kevin\n-- // Script Path: %s\n\n--[["):format(getPath(scr))
		local dump = original
		local functions, function_count, data_base = {}, 0, {}
		function functions:add_to_dump(str, indentation, new_line)
			if new_line == nil then new_line = true end
			dump = dump .. ("%s%s%s"):format(string.rep("		", indentation), tostring(str), new_line and "\n" or "")
		end
		function functions:get_function_name(func)
			local n = getinfo(func).name
			return n ~= "" and n or "Unknown Name"
		end
		function functions:dump_table(input, indent, index)
			local indent = indent < 0 and 0 or indent
			functions:add_to_dump(("%s [%s] %s"):format(tostring(index), tostring(typeof(input)), tostring(input)), indent - 1)
			local count = 0
			for index, value in pairs(input) do
				count = count + 1
				if type(value) == "function" then
					functions:add_to_dump(("%d [function] = %s"):format(count, functions:get_function_name(value)), indent)
				elseif type(value) == "table" then
					if not data_base[value] then
						data_base[value] = true
						functions:add_to_dump(("%d [table]:"):format(count), indent)
						functions:dump_table(value, indent + 1, index)
					else
						functions:add_to_dump(("%d [table] (Recursive table detected)"):format(count), indent)
					end
				else
					functions:add_to_dump(("%d [%s] = %s"):format(count, tostring(typeof(value)), tostring(value)), indent)
				end
			end
		end
		function functions:dump_function(input, indent)
			functions:add_to_dump(("\nFunction Dump: %s"):format(functions:get_function_name(input)), indent)
			functions:add_to_dump(("\nFunction Upvalues: %s"):format(functions:get_function_name(input)), indent)
			for index, upvalue in pairs(getupvalues(input)) do
				if type(upvalue) == "function" then
					functions:add_to_dump(("%d [function] = %s"):format(index, functions:get_function_name(upvalue)), indent + 1)
				elseif type(upvalue) == "table" then
					if not data_base[upvalue] then
						data_base[upvalue] = true
						functions:add_to_dump(("%d [table]:"):format(index), indent + 1)
						functions:dump_table(upvalue, indent + 2, index)
					else
						functions:add_to_dump(("%d [table] (Recursive table detected)"):format(index), indent + 1)
					end
				else
					functions:add_to_dump(("%d [%s] = %s"):format(index, tostring(typeof(upvalue)), tostring(upvalue)), indent + 1)
				end
			end
			functions:add_to_dump(("\nFunction Constants: %s"):format(functions:get_function_name(input)), indent)
			for index, constant in pairs(getconstants(input)) do
				if type(constant) == "function" then
					functions:add_to_dump(("%d [function] = %s"):format(index, functions:get_function_name(constant)), indent + 1)
				elseif type(constant) == "table" then
					if not data_base[constant] then
						data_base[constant] = true
						functions:add_to_dump(("%d [table]:"):format(index), indent + 1)
						functions:dump_table(constant, indent + 2, index)
					else
						functions:add_to_dump(("%d [table] (Recursive table detected)"):format(index), indent + 1)
					end
				else
					functions:add_to_dump(("%d [%s] = %s"):format(index, tostring(typeof(constant)), tostring(constant)), indent + 1)
				end
			end
		end
		local gcOk, gcObjects = pcall(getgc)
		if not gcOk or type(gcObjects) ~= "table" then
			env.notify("Dex++ Function Dumper", "getgc failed: " .. tostring(gcObjects), 8)
			return false
		end
		for _, _function in pairs(gcObjects) do
			local envOk, functionEnv = pcall(getfenv, _function)
			if typeof(_function) == "function" and envOk and type(functionEnv) == "table" and functionEnv.script == scr then
				functions:dump_function(_function, 0)
				functions:add_to_dump("\n" .. ("="):rep(100), 0, false)
			end
		end
		local source = codeFrame:GetText()

		if dump ~= original then source = source .. dump .. "]]" end
		codeFrame:SetText(source)
		
		window:Show()
	end

	ScriptViewer.Init = function()
		window = Lib.Window.new()
		window:SetTitle("Notepad")
		window:Resize(500,400)
		ScriptViewer.Window = window

		codeFrame = Lib.CodeFrame.new()
		codeFrame.Frame.Position = UDim2.new(0,0,0,20)
		codeFrame.Frame.Size = UDim2.new(1,0,1,-40)
		codeFrame.Frame.Parent = window.GuiElems.Content
		
		local copy = Instance.new("TextButton",window.GuiElems.Content)
		copy.BackgroundTransparency = 1
		copy.Size = UDim2.new(0.33,0,0,20)
		copy.Position = UDim2.new(0,0,0,0)
		copy.Text = "Copy to Clipboard"
		
		if env.setclipboard then
			copy.TextColor3 = Color3.new(1,1,1)
			copy.Interactable = true
		else
			copy.TextColor3 = Color3.new(0.5,0.5,0.5)
			copy.Interactable = false
		end

		copy.MouseButton1Click:Connect(function()
			if not env.setclipboard then
				env.notify("Dex++ Script Viewer", "Clipboard access is unavailable", 6)
				return
			end
			local source = codeFrame:GetText()
			local ok, message = pcall(env.setclipboard, source)
			if not ok then env.notify("Dex++ Script Viewer", tostring(message), 8) end
		end)

		local save = Instance.new("TextButton",window.GuiElems.Content)
		save.BackgroundTransparency = 1
		save.Size = UDim2.new(0.33,0,0,20)
		save.Position = UDim2.new(0.33,0,0,0)
		save.Text = "Save to File"
		save.TextColor3 = Color3.new(1,1,1)
		
		if env.writefile then
			save.TextColor3 = Color3.new(1,1,1)
			save.Interactable = true
		else
			save.TextColor3 = Color3.new(0.5,0.5,0.5)
			--save.Interactable = false
		end

		save.MouseButton1Click:Connect(function()
			if not env.writefile then
				env.notify("Dex++ Script Viewer", "writefile is unavailable", 6)
				return
			end
			local source = codeFrame:GetText()
			local filename = "Place_"..game.PlaceId.."_Script_"..os.time()..".txt"

			Lib.SaveAsPrompt(filename,source)
			--env.writefile(filename,source)
		end)
		
		dumpbtn = Instance.new("TextButton",window.GuiElems.Content)
		dumpbtn.BackgroundTransparency = 1
		dumpbtn.Position = UDim2.new(0.7,0,0,0)
		dumpbtn.Size = UDim2.new(0.3,0,0,20)
		dumpbtn.Text = "Dump Functions"
		dumpbtn.TextColor3 = Color3.new(0.5,0.5,0.5)
		
		if env.getgc and env.getupvalues and env.getconstants and getfenv then
			dumpbtn.TextColor3 = Color3.new(1,1,1)
			dumpbtn.Interactable = true
		else
			dumpbtn.TextColor3 = Color3.new(0.5,0.5,0.5)
			dumpbtn.Interactable = false
		end

		dumpbtn.MouseButton1Click:Connect(function()
			if PreviousScr ~= nil then
				pcall(ScriptViewer.DumpFunctions, PreviousScr)
			end
		end)
		
		-- Buttons below the editor
		
		
		execute = Instance.new("TextButton",window.GuiElems.Content)
		execute.BackgroundTransparency = 1
		execute.Size = UDim2.new(0.5,0,0,20)
		execute.Position = UDim2.new(0,0,1,-20)
		execute.Text = "Execute"
		execute.TextColor3 = Color3.new(1,1,1)
		
		if env.loadstring then
			execute.TextColor3 = Color3.new(1,1,1)
			execute.Interactable = true
		else
			execute.TextColor3 = Color3.new(0.5,0.5,0.5)
			execute.Interactable = false
		end

		execute.MouseButton1Click:Connect(function()
			if not env.loadstring then
				env.notify("Dex++ Script Viewer", "loadstring is unavailable", 6)
				return
			end
			local source = codeFrame:GetText()
			local compiled, chunkOrError = pcall(env.loadstring, source, "DexPlusPlus_ScriptViewer")
			if not compiled or type(chunkOrError) ~= "function" then
				env.notify("Dex++ Compile Error", tostring(chunkOrError), 10)
				return
			end
			local ran, runtimeError = pcall(chunkOrError)
			if not ran then env.notify("Dex++ Runtime Error", tostring(runtimeError), 10) end
		end)

		clear = Instance.new("TextButton",window.GuiElems.Content)
		clear.BackgroundTransparency = 1
		clear.Size = UDim2.new(0.5,0,0,20)
		clear.Position = UDim2.new(0.5,0,1,-20)
		clear.Text = "Clear"
		clear.TextColor3 = Color3.new(1,1,1)

		clear.MouseButton1Click:Connect(function()
			codeFrame:SetText("")
		end)
	end
	
	ScriptViewer.ViewScript = function(scr)
		local oldtick = tick()
		local s,source = pcall(env.decompile or function() end,scr)
		local decompileError = not s and tostring(source) or nil

		if not s or not source then
			PreviousScr = nil
			dumpbtn.TextColor3 = Color3.new(0.5,0.5,0.5)
			source = "-- Unable to view source.\n"
			
			if Settings.ScriptViewer.ShowMoreInfo then
				source = source .. "-- Script Path: "..getPath(scr).."\n"
				if scr:IsA("Script") and (scr.RunContext == Enum.RunContext.Legacy or scr.RunContext == Enum.RunContext.Server) then
					source = source .. "-- Reason: The script is not running on client. (attempt to decompile ServerScript or 'Script' with RunContext Server)\n"
				elseif not env.isdecompile() then
					source = source .. "-- Reason: Your executor does not provide a native 'decompile' function.\n"
				else
					source = source .. "-- Reason: " .. tostring(decompileError or "The native decompiler returned no source") .. "\n"
				end
				source = source .. "-- Executor: "..executorName.." ("..executorVersion..")"
			end
		else
			PreviousScr = scr
			dumpbtn.TextColor3 = Color3.new(1,1,1)

			local decompiled = source

			source = "-- Script Path: "..getPath(scr).."\n"
			
			if Settings.ScriptViewer.ShowMoreInfo then
				source = source .. "-- Took "..tostring(math.floor( (tick() - oldtick) * 100) / 100).."s to decompile.\n"
				source = source .. "-- Executor: "..executorName.." ("..executorVersion..")\n\n"
			end
			
			source = source .. decompiled

			oldtick = nil
			decompiled = nil
		end

		codeFrame:SetText(source)
		window:Show()
	end

	return ScriptViewer
end

-- TODO: Remove when open source
if gethsfuncs then
	_G.moduleData = {InitDeps = initDeps, InitAfterMain = initAfterMain, Main = main}
else
	return {InitDeps = initDeps, InitAfterMain = initAfterMain, Main = main}
end

end,
["SettingsWindow"] = function()
--[[
	Save Instance App Module
	
	Revival of the old dex's Save Instance
]] 

-- Common Locals
local Main,Lib,Apps,Settings -- Main Containers
local Explorer, Properties, ScriptViewer, SettingsWindow, Notebook -- Major Apps
local API,RMD,env,service,plr,create,createSimple -- Main Locals

local function initDeps(data)
	Main = data.Main
	Lib = data.Lib
	Apps = data.Apps
	Settings = data.Settings

	API = data.API
	RMD = data.RMD
	env = data.env
	service = data.service
	plr = data.plr
	create = data.create
	createSimple = data.createSimple
end

local function initAfterMain()
	Explorer = Apps.Explorer
	Properties = Apps.Properties
	ScriptViewer = Apps.ScriptViewer
	SettingsWindow = Apps.SettingsWindow
	Notebook = Apps.Notebook
end

local function main()
	local SettingsWindow = {}
	local window, ListFrame
	
	local function AddCheckbox(title, default)
		local frame = Lib.Frame.new()
		frame.Gui.Parent = ListFrame
		frame.Gui.Transparency = 1
		frame.Gui.Size = UDim2.new(1,0,0,20)
		
		local listlayout = Instance.new("UIListLayout")
		listlayout.Parent = frame.Gui
		listlayout.FillDirection = Enum.FillDirection.Horizontal
		listlayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
		listlayout.VerticalAlignment = Enum.VerticalAlignment.Center
		listlayout.Padding = UDim.new(0, 10)
		
		-- Checkbox
		local checkbox = Lib.Checkbox.new()
		
		checkbox.Gui.Parent = frame.Gui
		checkbox.Gui.Size = UDim2.new(0,15,0,15)
		
		-- Label
		local label = Lib.Label.new()
		
		label.Gui.Parent = frame.Gui
		label.Gui.Size = UDim2.new(1, 0,1, -15)
		label.Gui.Text = title
		label.TextTruncate = Enum.TextTruncate.AtEnd
		
		checkbox:SetState(default or false)
		
		return checkbox
	end
	
	local function AddTextbox(title, default, sizeX)
		default = default and tostring(default) or ""
		local frame = Lib.Frame.new()
		frame.Gui.Parent = ListFrame
		frame.Gui.Transparency = 1
		frame.Gui.Size = UDim2.new(1,0,0,20)

		local listlayout = Instance.new("UIListLayout")
		listlayout.Parent = frame.Gui
		listlayout.FillDirection = Enum.FillDirection.Horizontal
		listlayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
		listlayout.VerticalAlignment = Enum.VerticalAlignment.Center
		listlayout.Padding = UDim.new(0, 10)

		-- Textbox
		local textbox = Instance.new("TextBox") -- replaced cuz why Moon make every inputs only work on mouse/pc users >:( 
		textbox.BackgroundColor3 = Settings.Theme.TextBox
		textbox.BorderColor3 = Settings.Theme.Outline3
		textbox.ClearTextOnFocus = false
		textbox.TextColor3 = Settings.Theme.Text
		textbox.Font = Enum.Font.SourceSans
		textbox.TextSize = 14
		textbox.ZIndex = 2

		textbox.Parent = frame.Gui
		if sizeX and type(sizeX) == "number" then
			textbox.Size = UDim2.new(0,sizeX,0,15)
		else
			textbox.Size = UDim2.new(0,45,0,15)
		end
		
		frame.Gui.AutomaticSize = Enum.AutomaticSize.X
		textbox.AutomaticSize = Enum.AutomaticSize.X

		-- Label
		local label = Lib.Label.new()

		label.Parent = frame.Gui
		label.Size = UDim2.new(1, 0,1, -15)
		label.Text = title
		label.TextTruncate = Enum.TextTruncate.AtEnd

		textbox.Text = default

		return textbox
	end
	
	local function AddDropdown(title, options, default, allowEmpty, sizeX)
		if allowEmpty == nil then allowEmpty = true end
		
		local frame = Lib.Frame.new()
		frame.Gui.Parent = ListFrame
		frame.Gui.Transparency = 1
		frame.Gui.Size = UDim2.new(1,0,0,20)

		local listlayout = Instance.new("UIListLayout")
		listlayout.Parent = frame.Gui
		listlayout.FillDirection = Enum.FillDirection.Horizontal
		listlayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
		listlayout.VerticalAlignment = Enum.VerticalAlignment.Center
		listlayout.Padding = UDim.new(0, 10)

		-- Textbox
		local dropdown = Lib.DropDown.new()
		dropdown.CanBeEmpty = allowEmpty
		dropdown.Size = UDim2.new(0,sizeX or 75,0,15)
		dropdown:SetOptions(options)
		if default then dropdown:SetSelected(default) end
		dropdown.Gui.Parent = frame.Gui

		frame.Gui.AutomaticSize = Enum.AutomaticSize.X

		-- Label
		local label = Lib.Label.new()

		label.Parent = frame.Gui
		label.Size = UDim2.new(1, 0,1, -15)
		label.Text = title
		label.TextTruncate = Enum.TextTruncate.AtEnd
		
		return dropdown
	end
	
	local function AddSeperator(title)

		local frame = Lib.Frame.new()
		frame.Gui.Parent = ListFrame
		frame.Gui.Transparency = 1
		frame.Gui.Size = UDim2.new(1,0,0,20)
		
		-- Label
		local label = Lib.Label.new()

		label.Parent = frame.Gui
		--label.AnchorPoint = Vector2.new(0,1)
		--label.Position = UDim2.new(0,0,0,0)
		label.Size = UDim2.new(1, 0,1, 0)
		label.Text = title
		label.TextSize = 16
		label.TextTruncate = Enum.TextTruncate.AtEnd

		return label
	end
	
	local function AddText(text)
		local frame = Lib.Frame.new()
		frame.Gui.Parent = ListFrame
		frame.Gui.Transparency = 1
		frame.Gui.Size = UDim2.new(1,0,0,34)

		-- Label
		local label = Lib.Label.new()

		label.Parent = frame.Gui
		--label.AnchorPoint = Vector2.new(0,1)
		--label.Position = UDim2.new(0,0,0,0)
		label.Size = UDim2.new(1, 0,1, 0)
		label.TextColor3 = Color3.fromRGB(185,185,185)
		label.Text = text
		label.TextSize = 14
		label.Gui.TextWrapped = true
		label.Gui.TextXAlignment = Enum.TextXAlignment.Left
		label.Gui.TextYAlignment = Enum.TextYAlignment.Top

		return label
	end
	
	SettingsWindow.ReloadPrompt = function()		
		local win = ScriptViewer.ReloadPromptWindow
		if not win then
			win = Lib.Window.new()
			win.Alignable = false
			win.Resizable = false
			win:SetTitle("Apply Current Settings")
			win:SetSize(300,115)

			local reloadButton = Lib.Button.new()
			local nameLabel = Lib.Label.new()
			nameLabel.Text = "By applying current settings requires reload.\nAny unsaved progress will be lost.\nAre you sure?"
			nameLabel.Position = UDim2.new(0,30,0,20)
			nameLabel.Size = UDim2.new(0,40,0,20)
			win:Add(nameLabel)

			local cancelButton = Lib.Button.new()
			cancelButton.AnchorPoint = Vector2.new(1,1)
			cancelButton.Text = "Apply Later"
			cancelButton.Position = UDim2.new(1,-5,1,-5)
			cancelButton.Size = UDim2.new(0.5,-10,0,20)
			cancelButton.OnClick:Connect(function()
				win:Close()
			end)
			win:Add(cancelButton)

			reloadButton.Text = "Apply Now"
			reloadButton.AnchorPoint = Vector2.new(0,1)
			reloadButton.Position = UDim2.new(0,5,1,-5)
			reloadButton.Size = UDim2.new(0.5,-5,0,20)
			reloadButton.OnClick:Connect(function()
				Main.Reinit()
			end)

			win:Add(reloadButton,"reloadButton")

			SettingsWindow.ReloadPromptWindow = win
		end
		win:Show()
	end
	
	SettingsWindow.Init = function()
		window = Lib.Window.new()
		window:SetTitle("Settings")
		window:Resize(250,375)
		SettingsWindow.Window = window
		
		-- ListFrame
		
		ListFrame = Instance.new("ScrollingFrame")
		ListFrame.Parent = window.GuiElems.Content
		ListFrame.Size = UDim2.new(1, 0,1, -20)
		ListFrame.Position = UDim2.new(0, 0, 0, 0)
		ListFrame.Transparency = 1
		ListFrame.CanvasSize = UDim2.new(0,0,0,0)
		ListFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
		ListFrame.ScrollBarThickness = 16
		ListFrame.BottomImage = ""
		ListFrame.TopImage = ""
		ListFrame.ScrollBarImageColor3 = Color3.fromRGB(70, 70, 70)
		ListFrame.ScrollBarImageTransparency = 0
		ListFrame.ZIndex = 2
		ListFrame.BorderSizePixel = 0
		
		local scrollbar = Lib.ScrollBar.new()
		scrollbar.Gui.Parent = window.GuiElems.Content
		scrollbar.Gui.Size = UDim2.new(1, 0,1, -40)
		scrollbar.Gui.Up.ZIndex = 3
		scrollbar.Gui.Down.ZIndex = 3
		
		ListFrame:GetPropertyChangedSignal("AbsoluteWindowSize"):Connect(function()
			if ListFrame.AbsoluteCanvasSize ~= ListFrame.AbsoluteWindowSize then
				scrollbar.Gui.Visible = true
			else
				scrollbar.Gui.Visible = false
			end
		end)
		
		local ListLayout = Instance.new("UIListLayout")
		ListLayout.Parent = ListFrame
		ListLayout.Padding = UDim.new(0, 5)
		
		local Padding = Instance.new("UIPadding")
		Padding.Parent = ListFrame
		Padding.PaddingBottom = UDim.new(0, 5)
		Padding.PaddingLeft = UDim.new(0, 10)
		Padding.PaddingRight = UDim.new(0, 10)
		Padding.PaddingTop = UDim.new(0, 5)
		
		-- Options
		
		AddSeperator("UI")
		
		local titleonmiddle = AddCheckbox("Window Title On Middle", Settings.Window.TitleOnMiddle)
		titleonmiddle.OnInput:Connect(function()
			Settings.Window.TitleOnMiddle = titleonmiddle.Toggled
		end)
		
		local bgTransparency = AddTextbox("Background Transparency", tostring(Settings.Window.Transparency), 15)
		bgTransparency.FocusLost:Connect(function()
			local value = tonumber(bgTransparency.Text)
			if value then Settings.Window.Transparency = math.clamp(value, 0, 1) end
			bgTransparency.Text = tostring(Settings.Window.Transparency)
		end)
		
		local classIcon = AddDropdown("Class Icons", {"Old", "NewDark", "Vanilla3"}, Settings.ClassIcon, false, 100)
		classIcon.OnSelect:Connect(function()
			Settings.ClassIcon = classIcon.Selected
		end)
		
		AddSeperator("Explorer")
		
		local clickRename = AddCheckbox("Click to Rename", Settings.Explorer.ClickToRename)
		clickRename.OnInput:Connect(function()
			Settings.Explorer.ClickToRename = clickRename.Toggled
		end)
		
		local partSelectionBox = AddCheckbox("Part Selection Box", Settings.Explorer.PartSelectionBox)
		partSelectionBox.OnInput:Connect(function()
			Settings.Explorer.PartSelectionBox = partSelectionBox.Toggled
		end)
		
		local copypathUseChildren = AddCheckbox("Use GetChildren to Copy Path", Settings.Explorer.CopyPathUseGetChildren)
		copypathUseChildren.OnInput:Connect(function()
			Settings.Explorer.CopyPathUseGetChildren = copypathUseChildren.Toggled
		end)
		
		AddSeperator("Properties")

		local showDeprecated = AddCheckbox("Show Deprecated", Settings.Properties.ShowDeprecated)
		showDeprecated.OnInput:Connect(function()
			Settings.Properties.ShowDeprecated = showDeprecated.Toggled
		end)
		
		local showHidden = AddCheckbox("Show Hidden", Settings.Properties.ShowHidden)
		showHidden.OnInput:Connect(function()
			Settings.Properties.ShowHidden = showHidden.Toggled
		end)
		
		local showAttributes = AddCheckbox("Show Attributes", Settings.Properties.ShowAttributes)
		showAttributes.OnInput:Connect(function()
			Settings.Properties.ShowAttributes = showAttributes.Toggled
		end)
		local clearOnFocus = AddCheckbox("Clear On Focus", Settings.Properties.ClearOnFocus)
		clearOnFocus.OnInput:Connect(function()
			Settings.Properties.ClearOnFocus = clearOnFocus.Toggled
		end)

		AddSeperator("Save to File")
		AddText("Folder is relative to the executor workspace. Example: DexPlusPlus/saves/Maps")
		local saveFolder = AddTextbox("Default save folder", Settings.Save.Folder, 180)
		saveFolder.FocusLost:Connect(function()
			Settings.Save.Folder = env.normalizepath(saveFolder.Text)
			saveFolder.Text = Settings.Save.Folder
		end)

		local createFolders = AddCheckbox("Create missing subfolders", Settings.Save.CreateFolders)
		createFolders.OnInput:Connect(function()
			Settings.Save.CreateFolders = createFolders.Toggled
		end)

		local avoidOverwrite = AddCheckbox("Keep existing files (add _1, _2, ...)", Settings.Save.AvoidOverwrite)
		avoidOverwrite.OnInput:Connect(function()
			Settings.Save.AvoidOverwrite = avoidOverwrite.Toggled
		end)

		local verifySave = AddCheckbox("Verify file after save", Settings.Save.VerifyAfterWrite)
		verifySave.OnInput:Connect(function()
			Settings.Save.VerifyAfterWrite = verifySave.Toggled
		end)
		
		AddSeperator("Script Viewer")
		
		local showMoreInfo = AddCheckbox("Show Decompiled Script Info", Settings.ScriptViewer.ShowMoreInfo)
		showMoreInfo.OnInput:Connect(function()
			Settings.ScriptViewer.ShowMoreInfo = showMoreInfo.Toggled
		end)
		
		AddSeperator("Decompiler")
		AddText("Native executor decompiler only. Remote fallback services are disabled for stability and safety.")
		
		-- Save buttons below
		local BackgroundreloadButton = Lib.Frame.new()
		BackgroundreloadButton.Gui.Parent = window.GuiElems.Content
		BackgroundreloadButton.Size = UDim2.new(1,0, 0,20)
		BackgroundreloadButton.Position = UDim2.new(0,0, 1,-20)
		
		local LabelreloadButton = Lib.Label.new()
		LabelreloadButton.Gui.Parent = window.GuiElems.Content
		LabelreloadButton.Size = UDim2.new(1,0, 0,20)
		LabelreloadButton.Position = UDim2.new(0,0, 1,-20)
		LabelreloadButton.Gui.Text = "Restart"
		LabelreloadButton.Gui.TextXAlignment = Enum.TextXAlignment.Center
		
		local reloadButton = Instance.new("TextButton")
		reloadButton.Parent = BackgroundreloadButton.Gui
		reloadButton.Size = UDim2.new(1,0, 1,0)
		reloadButton.Position = UDim2.new(0,0, 0,0)
		reloadButton.Transparency = 1
		
		reloadButton.MouseButton1Click:Connect(function()
			window:SetTitle("Settings - Saving")
			
			local saved, message = Main.SaveCurrentSettings()
			if not saved then
				window:SetTitle("Settings - Error")
				env.notify("Dex++ Settings", tostring(message), 8)
				return
			end

			window:SetTitle("Settings - Saved")
			SettingsWindow.ReloadPrompt()
			task.wait(3)
			
			window:SetTitle("Settings")
		end)
	end

	return SettingsWindow
end

-- TODO: Remove when open source
if gethsfuncs then
	_G.moduleData = {InitDeps = initDeps, InitAfterMain = initAfterMain, Main = main}
else
	return {InitDeps = initDeps, InitAfterMain = initAfterMain, Main = main}
end

end,
["UniversalSynSaveInstance"] = function()
--!native
--!optimize 2
--!divine-intellect
-- https://discord.gg/wx4ThpAsmw

local function string_find(s, pattern, init)
	return string.find(s, pattern, init, true)
end

local function arrayToDict(t, mixedMode, valueOverride, typeStrict)
	local tmp = {}

	if mixedMode then
		for any1, any2 in t do
			if type(any1) == "number" then
				tmp[any2] = valueOverride or true
			elseif type(any2) == "table" then
				tmp[any1] = arrayToDict(any2, mixedMode) -- any1 is Class, any2 is Name
			else
				tmp[any1] = any2
			end
		end
	else
		for _, key in t do
			if not typeStrict or typeStrict and type(key) == typeStrict then
				tmp[key] = true
			end
		end
	end

	return tmp
end

local service = setmetatable({}, {
	__index = function(self, serviceName)
		local o, s = pcall(Instance.new, serviceName)
		local Service = o and s
			or game:GetService(serviceName)
			or settings():GetService(serviceName)
			or UserSettings():GetService(serviceName)

		-- if cloneref then
		-- 	Service = cloneref(Service)
		-- end
		if Service then
			self[serviceName] = Service
		end
		return Service
	end,
})

local function fallbackBase64Encode(raw)
	if typeof(raw) == "buffer" then raw = buffer.tostring(raw) end
	raw = tostring(raw or "")
	local alphabet = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
	local output = table.create(math.ceil(#raw / 3) * 4)
	local outputIndex = 1
	for index = 1, #raw, 3 do
		local a = string.byte(raw, index) or 0
		local b = string.byte(raw, index + 1) or 0
		local c = string.byte(raw, index + 2) or 0
		local packed = a * 65536 + b * 256 + c
		local remaining = #raw - index + 1
		output[outputIndex] = alphabet:sub(math.floor(packed / 262144) % 64 + 1, math.floor(packed / 262144) % 64 + 1)
		output[outputIndex + 1] = alphabet:sub(math.floor(packed / 4096) % 64 + 1, math.floor(packed / 4096) % 64 + 1)
		output[outputIndex + 2] = remaining > 1 and alphabet:sub(math.floor(packed / 64) % 64 + 1, math.floor(packed / 64) % 64 + 1) or "="
		output[outputIndex + 3] = remaining > 2 and alphabet:sub(packed % 64 + 1, packed % 64 + 1) or "="
		outputIndex += 4
	end
	return table.concat(output)
end

local cryptLibrary = (type(crypt) == "table" and crypt) or (type(syn) == "table" and type(syn.crypt) == "table" and syn.crypt)
local nativeGetNilInstances = getnilinstances or get_nil_instances
	 or (type(syn) == "table" and syn.getnilinstances)
local nativeGetInstances = getinstances or get_instances
	 or (type(syn) == "table" and syn.getinstances)
local function collectNilInstances()
	if type(nativeGetNilInstances) == "function" then
		local ok, instances = pcall(nativeGetNilInstances)
		if ok and type(instances) == "table" then return instances end
	end

	local result = {}
	if type(nativeGetInstances) ~= "function" then return result end
	local ok, instances = pcall(nativeGetInstances)
	if not ok or type(instances) ~= "table" then return result end
	for _, instance in ipairs(instances) do
		local checked, isNilInstance = pcall(function()
			return typeof(instance) == "Instance" and instance ~= game and instance.Parent == nil
		end)
		if checked and isNilInstance then table.insert(result, instance) end
	end
	return result
end

local global_container = {
	base64encode = (cryptLibrary and (cryptLibrary.base64encode or cryptLibrary.base64_encode)) or fallbackBase64Encode,
	decompile = decompile or (type(syn) == "table" and syn.decompile),
	gethiddenproperty = gethiddenproperty or get_hidden_property or gethiddenprop,
	gethui = gethui,
	getnilinstances = (type(nativeGetNilInstances) == "function" or type(nativeGetInstances) == "function")
		and collectNilInstances or nil,
	getscriptbytecode = getscriptbytecode or dumpstring
		or (type(syn) == "table" and (syn.getscriptbytecode or syn.dumpstring)),
	protectgui = protect_gui or protectgui or (type(syn) == "table" and syn.protect_gui),
}

local identify_executor = identifyexecutor or getexecutorname or whatexecutor

local EXECUTOR_NAME = identify_executor and identify_executor() or ""

-- local cloneref = global_container.cloneref
local gethiddenproperty = global_container.gethiddenproperty
local gethiddenproperty_fallback

-- These should be universal enough
local appendfile = appendfile
local isfile = isfile
local readfile = readfile
local writefile = writefile

local getscriptbytecode = global_container.getscriptbytecode -- * A lot of assumptions are made based on whether this function is defined or not. So in certain edge cases, like if the executor defines "decompile" or "getscripthash" function yet doesn't define this function there might be loss of functionality of the saveinstance. Although that would be very rare and weird
local base64encode = global_container.base64encode
local decompile = global_container.decompile

local sharedStringId = 1e15 -- 1 quadrillion, up to 9.(9) quadrillion, in theory this shouldn't ever run out and be enough for all sharedstrings ever imaginable 	-- TODO: worst case, add fallback to str randomizer once numbers run out : )
local sharedStrings = setmetatable({}, {
	__index = function(self, str)
		local id = base64encode(tostring(sharedStringId)) -- tostring is only needed for built-in base64encode, Luau base64 implementations don't need it as buffers autoconvert
		sharedStringId += 1

		self[str] = id -- ? The value of the md5 attribute is a Base64-encoded key. <SharedString> type elements use this key to refer to the value of the string. The value is the text content, which is Base64-encoded. Historically, the key was the MD5 hash of the string value. However, this is not required; the key can be any value that will uniquely identify the shared string. Roblox currently uses BLAKE2b truncated to 16 bytes..
		return id
	end,
})

local inheritedProperties = {}
local defaultInstances = {}
local referents, refSize = setmetatable({}, { __mode = "ks" }), 0 -- ? Roblox encodes all <Item> elements with a referent attribute. Each value is generated by starting with the prefix RBX, followed by a UUID version 4, with - characters removed, and all characters converted to uppercase.

local function getRef(instance)
	local ref = referents[instance]
	if not ref then
		ref = refSize
		referents[instance] = ref
		refSize += 1
	end
	return ref
end

local function index(self, index_name)
	return self[index_name]
end

local FULL_VERSION

if not pcall(function()
	FULL_VERSION = version()
end) then
	if not pcall(function()
		FULL_VERSION = settings():GetService("DebugSettings").RobloxVersion
	end) then
		if not pcall(function()
			FULL_VERSION = service.RunService:GetRobloxVersion()
		end) then
			FULL_VERSION = "UNKNOWN"
		end
	end
end

local CLIENT_VERSION = tonumber(string.match(FULL_VERSION, "%d+%.(%d+)")) or 9e9
local __BREAK = "__BREAK" .. service.HttpService:GenerateGUID(false)

local Attribute_Type_Ids =
	{ -- ValueCurveKey & StyleRule.PropertiesSerialize can be used to explore types unsupported by attributes, as they share the same serializer
		["nil"] = 0x01,
		string = 0x02,
		boolean = 0x03,
		int32 = 0x04,
		-- float = 0x05, -- float32
		number = 0x06, -- float64 (double)
		ValueArray = 0x07,
		ValueTable = 0x08, -- Dictionary
		UDim = 0x09,
		UDim2 = 0x0A,
		Ray = 0x0B,
		Faces = 0x0C,
		Axes = 0x0D,
		BrickColor = 0x0E,
		Color3 = 0x0F,
		Vector2 = 0x10,
		Vector3 = 0x11,
		Vector2int16 = 0x12,
		Vector3int16 = 0x13,
		CFrame = 0x14,
		EnumItem = 0x15,
		-- 0x16
		NumberSequence = 0x17,
		NumberSequenceKeypoint = 0x18,
		ColorSequence = 0x19,
		ColorSequenceKeypoint = 0x1A,
		NumberRange = 0x1B,
		Rect = 0x1C,
		PhysicalProperties = 0x1D,
		Color3uint8 = 0x1E,
		Region3 = 0x1F,
		Region3int16 = 0x20,
		Font = 0x21,
		SecurityCapabilities = 0x22,
		Path2DControlPoint = 0x23,
		TweenInfo = 0x24,
		-- InstanceHandle = 0x25,
		-- Path3DControlPoint = 0x26, -- ? not sure
	}

local CFrame_Rotation_Ids = {
	["\0\0\128\63\0\0\0\0\0\0\0\0\0\0\0\0\0\0\128\63\0\0\0\0\0\0\0\0\0\0\0\0\0\0\128\63"] = 0x02,
	["\0\0\128\63\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\128\191\0\0\0\0\0\0\128\63\0\0\0\0"] = 0x03,
	["\0\0\128\63\0\0\0\0\0\0\0\0\0\0\0\0\0\0\128\191\0\0\0\0\0\0\0\0\0\0\0\0\0\0\128\191"] = 0x05,
	["\0\0\128\63\0\0\0\0\0\0\0\128\0\0\0\0\0\0\0\0\0\0\128\63\0\0\0\0\0\0\128\191\0\0\0\0"] = 0x06,
	["\0\0\0\0\0\0\128\63\0\0\0\0\0\0\128\63\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\128\191"] = 0x07,
	["\0\0\0\0\0\0\0\0\0\0\128\63\0\0\128\63\0\0\0\0\0\0\0\0\0\0\0\0\0\0\128\63\0\0\0\0"] = 0x09,
	["\0\0\0\0\0\0\128\191\0\0\0\0\0\0\128\63\0\0\0\0\0\0\0\128\0\0\0\0\0\0\0\0\0\0\128\63"] = 0x0a,
	["\0\0\0\0\0\0\0\0\0\0\128\191\0\0\128\63\0\0\0\0\0\0\0\0\0\0\0\0\0\0\128\191\0\0\0\0"] = 0x0c,
	["\0\0\0\0\0\0\128\63\0\0\0\0\0\0\0\0\0\0\0\0\0\0\128\63\0\0\128\63\0\0\0\0\0\0\0\0"] = 0x0d,
	["\0\0\0\0\0\0\0\0\0\0\128\191\0\0\0\0\0\0\128\63\0\0\0\0\0\0\128\63\0\0\0\0\0\0\0\0"] = 0x0e,
	["\0\0\0\0\0\0\128\191\0\0\0\0\0\0\0\0\0\0\0\0\0\0\128\191\0\0\128\63\0\0\0\0\0\0\0\0"] = 0x10,
	["\0\0\0\0\0\0\0\0\0\0\128\63\0\0\0\0\0\0\128\191\0\0\0\0\0\0\128\63\0\0\0\0\0\0\0\128"] = 0x11,
	["\0\0\128\191\0\0\0\0\0\0\0\0\0\0\0\0\0\0\128\63\0\0\0\0\0\0\0\0\0\0\0\0\0\0\128\191"] = 0x14,
	["\0\0\128\191\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\128\63\0\0\0\0\0\0\128\63\0\0\0\128"] = 0x15,
	["\0\0\128\191\0\0\0\0\0\0\0\0\0\0\0\0\0\0\128\191\0\0\0\0\0\0\0\0\0\0\0\0\0\0\128\63"] = 0x17,
	["\0\0\128\191\0\0\0\0\0\0\0\128\0\0\0\0\0\0\0\0\0\0\128\191\0\0\0\0\0\0\128\191\0\0\0\128"] = 0x18,
	["\0\0\0\0\0\0\128\63\0\0\0\128\0\0\128\191\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\128\63"] = 0x19,
	["\0\0\0\0\0\0\0\0\0\0\128\191\0\0\128\191\0\0\0\0\0\0\0\0\0\0\0\0\0\0\128\63\0\0\0\0"] = 0x1b,
	["\0\0\0\0\0\0\128\191\0\0\0\128\0\0\128\191\0\0\0\0\0\0\0\128\0\0\0\0\0\0\0\0\0\0\128\191"] = 0x1c,
	["\0\0\0\0\0\0\0\0\0\0\128\63\0\0\128\191\0\0\0\0\0\0\0\0\0\0\0\0\0\0\128\191\0\0\0\0"] = 0x1e,
	["\0\0\0\0\0\0\128\63\0\0\0\0\0\0\0\0\0\0\0\0\0\0\128\191\0\0\128\191\0\0\0\0\0\0\0\0"] = 0x1f,
	["\0\0\0\0\0\0\0\0\0\0\128\63\0\0\0\0\0\0\128\63\0\0\0\128\0\0\128\191\0\0\0\0\0\0\0\0"] = 0x20,
	["\0\0\0\0\0\0\128\191\0\0\0\0\0\0\0\0\0\0\0\0\0\0\128\63\0\0\128\191\0\0\0\0\0\0\0\0"] = 0x22,
	["\0\0\0\0\0\0\0\0\0\0\128\191\0\0\0\0\0\0\128\191\0\0\0\128\0\0\128\191\0\0\0\0\0\0\0\128"] = 0x23,
}
local rotationBuffer = buffer.create(36)
local EMPTY_BUFFER = buffer.create(0)
local BASE_CAPABILITIES
pcall(function()
	BASE_CAPABILITIES = SecurityCapabilities.new()
end)
local CAPABILITY_BITS = {
	Plugin = 2 ^ 0, ------------------- 0
	LocalUser = 2 ^ 1, ---------------- 1
	WritePlayer = 2 ^ 2, -------------- 2
	RobloxScript = 2 ^ 3, ------------- 3
	RobloxEngine = 2 ^ 4, ------------- 4
	NotAccessible = 2 ^ 5, ------------ 5
	----------------------------------- 6
	----------------------------------- 7
	RunClientScript = 2 ^ 8, ---------- 8
	RunServerScript = 2 ^ 9, ---------- 9
	Unknown = 2 ^ 10, ----------------- 10 (0xa)
	AccessOutsideWrite = 2 ^ 11, ------ 11 (0xb)
	----------------------------------- 12
	----------------------------------- 13
	----------------------------------- 14
	Unassigned = 2 ^ 15, -------------- 15 (0xf)
	LoadUnownedAsset = 2 ^ 16, -------- 16 (0x10)
	LoadString = 2 ^ 17, -------------- 17 (0x11)
	ScriptGlobals = 2 ^ 18, ----------- 18 (0x12)
	CreateInstances = 2 ^ 19, --------- 19 (0x13)
	Basic = 2 ^ 20, ------------------- 20 (0x14)
	Audio = 2 ^ 21, ------------------- 21 (0x15)
	DataStore = 2 ^ 22, --------------- 22 (0x16)
	Network = 2 ^ 23, ----------------- 23 (0x17)
	Physics = 2 ^ 24, ----------------- 24 (0x18)
	UI = 2 ^ 25, ---------------------- 25 (0x19)
	CSG = 2 ^ 26, --------------------- 26 (0x1a)
	Chat = 2 ^ 27, -------------------- 27 (0x1b)
	Animation = 2 ^ 28, --------------- 28 (0x1c)
	AvatarAppearance = 2 ^ 29, -------- 29 (0x1d)
	Input = 2 ^ 30, ------------------- 30 (0x1e)
	Environment = 2 ^ 31, ------------- 31 (0x1f)
	RemoteEvent = 2 ^ 32, ------------- 32 (0x20)
	LegacySound = 2 ^ 33, ------------- 33 (0x21)
	Players = 2 ^ 34, ----------------- 34 (0x22)
	CapabilityControl = 2 ^ 35, ------- 35 (0x23)
	AssetRead = 2 ^ 36, --------------- 36 (0x24)
	AssetManagement = 2 ^ 37, --------- 37 (0x25)
	DynamicGeneration = 2 ^ 38, ------- 38 (0x26)
	PlatformAvatarEditing = 2 ^ 39, --- 39 (0x27)
	AssetCreateUpdate = 2 ^ 40, ------- 40 (0x28)
	Capture = 2 ^ 41, ----------------- 41 (0x29)
	SensitiveInput = 2 ^ 42, ---------- 42 (0x2a)
	Monetization = 2 ^ 43, ------------ 43 (0x2b)
	LoadOwnedAsset = 2 ^ 44, ---------- 44 (0x2c)
	Social = 2 ^ 45, ------------------ 45 (0x2d)
	ServerCommunication = 2 ^ 46, ----- 46 (0x2e)
	Logging = 2 ^ 47, ----------------- 47 (0x2f)
	PromptExternalPurchase = 2 ^ 48, -- 48 (0x30)
	Groups = 2 ^ 49, ------------------ 49 (0x31)
	Teleport = 2 ^ 50, ---------------- 50 (0x32)
	Consequences = 2 ^ 51, ------------ 51 (0x33)
	Material = 2 ^ 52, ---------------- 52 (0x34)
	AvatarBehavior = 2 ^ 53, ---------- 53 (0x35)
	----------------------------------- 54
	----------------------------------- 55
	----------------------------------- 56
	----------------------------------- 57
	----------------------------------- 58
	RemoteCommand = 2 ^ 59, ----------- 59 (0x3b)
	InternalTest = 2 ^ 60, ------------ 60 (0x3c)
	PluginOrOpenCloud = 2 ^ 61, ------- 61 (0x3d)
	Assistant = 2 ^ 62, --------------- 62 (0x3e)
	Restricted = 2 ^ 63, ----------- 63 (0x3f) - special case for negative values (highest bit for i64)
}

local function countCapabilityBits(raw)
	-- TODO tostring & string.split aren't ideal but this is the only way until the feature is out of the experimental phase (SecurityCapabilities.Contains exists but the Enums that it accepts lacks some hidden bits) - NotAccessible, Unknown, Restricted
	-- ! Seems like both tostring & .Contains ignore high / internal bits (anything above CapabilityControl): RemoteCommand, InternalTest, PluginOrOpenCloud, Assistant. They're present when created & saved by Studio but can't be read through current means

	local result = 0
	for _, flag in string.split(tostring(raw), " | ") do
		local bit = CAPABILITY_BITS[flag]
		if bit then
			result += bit
		end
	end
	return result
end

local function countBits(...)
	local Value = 0

	for i, bit in { ... } do
		if bit then
			Value += 2 ^ (i - 1)
		end
	end

	return Value
end

local function cframeToQuaternion(cframe)
	local _, _, _, R00, R01, R02, R10, R11, R12, R20, R21, R22 = cframe:GetComponents()
	local trace = R00 + R11 + R22
	local S, qW, qX, qY, qZ
	if trace > 0 then
		S = math.sqrt(1 + trace) * 2
		qW = 0.25 * S
		qX = (R21 - R12) / S
		qY = (R02 - R20) / S
		qZ = (R10 - R01) / S
	elseif (R00 > R11) and (R00 > R22) then
		S = math.sqrt(1 + R00 - R11 - R22) * 2
		qW = (R21 - R12) / S
		qX = 0.25 * S
		qY = (R01 + R10) / S
		qZ = (R02 + R20) / S
	elseif R11 > R22 then
		S = math.sqrt(1 + R11 - R00 - R22) * 2
		qW = (R02 - R20) / S
		qX = (R01 + R10) / S
		qY = 0.25 * S
		qZ = (R12 + R21) / S
	else
		S = math.sqrt(1 + R22 - R00 - R11) * 2
		qW = (R10 - R01) / S
		qX = (R02 + R20) / S
		qY = (R12 + R21) / S
		qZ = 0.25 * S
	end
	-- Force consistent sign (W positive) to match Roblox internal serializer
	if qW < 0 then
		qW, qX, qY, qZ = -qW, -qX, -qY, -qZ
	end
	return qX, qY, qZ, qW
end

local function classifyTable(t)
	local len = #t
	if len > 0 then
		local n = 0
		for _ in t do
			n += 1
		end
		if n == len then
			return "ValueArray"
		end
	end
	local n, maxIndex = 0, 0
	for k in t do
		n += 1
		if type(k) == "number" and k > maxIndex and k == math.floor(k) and k >= 1 then
			maxIndex = k
		end
	end
	return (maxIndex > 0 and maxIndex == n) and "ValueArray" or "ValueTable"
end

local function resolveTypeName(value)
	local t = typeof(value)
	if t == "table" then
		return classifyTable(value)
	end
	return t
end

local Binary_Encoders
Binary_Encoders = {
	_packMultiple = function(encoder, value1, value2, value3)
		local buf1, size1 = encoder(value1)
		local buf2, size2 = encoder(value2)

		local len = size1 + size2
		local buf3, size3

		if value3 ~= nil then
			buf3, size3 = encoder(value3)
			len += size3
		end

		local b = buffer.create(len)

		buffer.copy(b, 0, buf1)
		buffer.copy(b, size1, buf2)

		if value3 ~= nil then
			buffer.copy(b, size1 + size2, buf3)
		end

		return b, len
	end,
	_makeSequence = function(keypoint_handler, keypointSize)
		return function(raw)
			local keypoints = raw.Keypoints
			local n = #keypoints

			local len = 4 + keypointSize * n
			local b = buffer.create(len)

			buffer.writeu32(b, 0, n)

			local offset = 4
			for _, keypoint in keypoints do
				keypoint_handler(keypoint, b, offset)
				offset += keypointSize
			end

			return b, len
		end
	end,
	_writeI64LE = function(b, offset, raw)
		local low = bit32.band(raw, 0xFFFFFFFF)
		local high = (raw - low) / 0x100000000

		buffer.writei32(b, offset, low)
		buffer.writei32(b, offset + 4, high)
	end,
	_packF32 = nil,
	_packI16 = nil,
	_makeVectorPacker = function(writeFunc, elementSize)
		-- local zbuf, nozbuf = buffer.create(elementSize * 3), buffer.create(elementSize * 2)
		return function(X, Y, Z)
			local len = Z and (elementSize * 3) or (elementSize * 2)
			local b = buffer.create(len)

			writeFunc(b, 0, X)
			writeFunc(b, elementSize, Y)
			if Z then
				writeFunc(b, elementSize * 2, Z)
			end

			return b, len
		end
	end,
	--------------------------------------------------------------
	--------------------------------------------------------------
	--------------------------------------------------------------
	["nil"] = function(raw)
		return EMPTY_BUFFER, 0
	end,
	["string"] = function(raw)
		local raw_len = #raw
		local len = 4 + raw_len

		local b = buffer.create(len)

		buffer.writeu32(b, 0, raw_len)
		buffer.writestring(b, 4, raw)

		return b, len
	end,
	["boolean"] = function(raw)
		local b = buffer.create(1)

		buffer.writeu8(b, 0, raw and 1 or 0)

		return b, 1
	end,
	["number"] = function(raw) -- double
		local b = buffer.create(8)

		buffer.writef64(b, 0, raw)

		return b, 8
	end,
	["ValueArray"] = function(raw)
		-- #raw is unreliable once holes are introduced.
		local n = 0
		for k in raw do
			if type(k) == "number" and k > n and k == math.floor(k) and k >= 1 then
				n = k
			end
		end

		local bufs = table.create(n)
		local total = 4 -- u32 length prefix
		local count = 0

		for i = 1, n do
			local value = raw[i]
			local b, size

			if value == nil then
				-- Hole marker: single byte, preserves array position.
				b = buffer.create(1)
				buffer.writeu8(b, 0, 0x01)
				size = 1
			else
				local valueTypeName = resolveTypeName(value)
				local typeId = Attribute_Type_Ids[valueTypeName]
				local descriptor = Binary_Encoders[valueTypeName]
				if not descriptor then
					continue
				end
				local dataBuf, dataSize = descriptor(value)

				b = buffer.create(1 + dataSize)
				buffer.writeu8(b, 0, typeId)
				buffer.copy(b, 1, dataBuf)
				size = 1 + dataSize
			end

			count += 1
			bufs[count] = b
			total += size
		end

		local b = buffer.create(total)
		buffer.writeu32(b, 0, count)

		local offset = 4
		for i = 1, count do
			local bb = bufs[i]
			buffer.copy(b, offset, bb)
			offset += buffer.len(bb)
		end

		return b, total
	end,
	["ValueTable"] = function(raw)
		local keys = {}
		local keyMap = {}
		local n = 0

		for k in raw do
			n += 1
			local keyStr = tostring(k)
			keys[n] = keyStr
			keyMap[keyStr] = k
		end

		table.sort(keys)

		local bufs = table.create(n)
		local total = 4 -- u32 length prefix
		local count = 0

		for i = 1, n do
			local keyStr = keys[i]
			local value = raw[keyMap[keyStr]]

			local valueTypeName = resolveTypeName(value)
			local typeId = Attribute_Type_Ids[valueTypeName]
			local descriptor = Binary_Encoders[valueTypeName]
			if not descriptor then
				continue
			end
			local dataBuf, dataSize = descriptor(value)

			local keyLen = #keyStr
			local size = 4 + keyLen + 1 + dataSize -- u32 keylen + key + typeId + payload
			local b = buffer.create(size)

			buffer.writeu32(b, 0, keyLen)
			buffer.writestring(b, 4, keyStr)
			buffer.writeu8(b, 4 + keyLen, typeId)
			buffer.copy(b, 4 + keyLen + 1, dataBuf)

			count += 1
			bufs[count] = b
			total += size
		end

		local b = buffer.create(total)
		buffer.writeu32(b, 0, count)

		local offset = 4
		for i = 1, count do
			local bb = bufs[i]
			buffer.copy(b, offset, bb)
			offset += buffer.len(bb)
		end

		return b, total
	end,
	["UDim"] = function(raw)
		local b = buffer.create(8)

		buffer.writef32(b, 0, raw.Scale)
		buffer.writei32(b, 4, raw.Offset)

		return b, 8
	end,
	["UDim2"] = function(raw)
		return Binary_Encoders._packMultiple(Binary_Encoders["UDim"], raw.X, raw.Y)
	end,
	["Ray"] = function(raw)
		return Binary_Encoders._packMultiple(Binary_Encoders["Vector3"], raw.Origin, raw.Direction)
	end,
	["Faces"] = function(raw)
		local b = buffer.create(4)

		buffer.writeu32(b, 0, countBits(raw.Right, raw.Top, raw.Back, raw.Left, raw.Bottom, raw.Front))

		return b, 4
	end,
	["Axes"] = function(raw)
		local b = buffer.create(4)

		buffer.writeu32(b, 0, countBits(raw.X, raw.Y, raw.Z))

		return b, 4
	end,
	["BrickColor"] = function(raw)
		local b = buffer.create(4)

		buffer.writeu32(b, 0, raw.Number)

		return b, 4
	end,
	["Color3"] = function(raw)
		return Binary_Encoders._packF32(raw.R, raw.G, raw.B)
	end,
	["Vector2"] = function(raw)
		return Binary_Encoders._packF32(raw.X, raw.Y)
	end,
	["Vector3"] = function(raw)
		return Binary_Encoders._packF32(raw.X, raw.Y, raw.Z)
	end,
	["Vector2int16"] = function(raw)
		return Binary_Encoders._packI16(raw.X, raw.Y)
	end,
	["Vector3int16"] = function(raw)
		return Binary_Encoders._packI16(raw.X, raw.Y, raw.Z)
	end,
	["CFrame"] = function(raw)
		local X, Y, Z, R00, R01, R02, R10, R11, R12, R20, R21, R22 = raw:GetComponents()

		buffer.writef32(rotationBuffer, 0, R00)
		buffer.writef32(rotationBuffer, 4, R01)
		buffer.writef32(rotationBuffer, 8, R02)
		buffer.writef32(rotationBuffer, 12, R10)
		buffer.writef32(rotationBuffer, 16, R11)
		buffer.writef32(rotationBuffer, 20, R12)
		buffer.writef32(rotationBuffer, 24, R20)
		buffer.writef32(rotationBuffer, 28, R21)
		buffer.writef32(rotationBuffer, 32, R22)

		local rotation_ID = CFrame_Rotation_Ids[buffer.tostring(rotationBuffer)]

		local len = rotation_ID and 13 or 49
		local b = buffer.create(len)

		local _packF32 = Binary_Encoders._packF32
		local position = _packF32(X, Y, Z)
		buffer.copy(b, 0, position)
		-- buffer.writef32(b, 0, X)
		-- buffer.writef32(b, 4, Y)
		-- buffer.writef32(b, 8, Z)

		if rotation_ID then
			buffer.writeu8(b, 12, rotation_ID)
		else
			buffer.writeu8(b, 12, 0x0)

			local xBasis = _packF32(R00, R01, R02)
			buffer.copy(b, 13, xBasis)
			local yBasis = _packF32(R10, R11, R12)
			buffer.copy(b, 13 + 12, yBasis)
			local zBasis = _packF32(R20, R21, R22)
			buffer.copy(b, 13 + 24, zBasis)

			-- buffer.writef32(b, 13, R00)
			-- buffer.writef32(b, 17, R01)
			-- buffer.writef32(b, 21, R02)

			-- buffer.writef32(b, 25, R10)
			-- buffer.writef32(b, 29, R11)
			-- buffer.writef32(b, 33, R12)

			-- buffer.writef32(b, 37, R20)
			-- buffer.writef32(b, 41, R21)
			-- buffer.writef32(b, 45, R22)
		end

		return b, len
	end,
	["EnumItem"] = function(raw)
		local nameBuf, nameSize = Binary_Encoders["string"](tostring(raw.EnumType))

		local len = nameSize + 4
		local b = buffer.create(len)

		buffer.copy(b, 0, nameBuf)
		buffer.writeu32(b, nameSize, raw.Value)

		return b, len
	end,
	["NumberSequence"] = nil,
	["NumberSequenceKeypoint"] = function(keypoint, b, offset)
		if not b then
			return Binary_Encoders._packF32(keypoint.Envelope, keypoint.Time, keypoint.Value)
		end

		buffer.writef32(b, offset, keypoint.Envelope)
		offset += 4
		buffer.writef32(b, offset, keypoint.Time)
		offset += 4
		buffer.writef32(b, offset, keypoint.Value)
	end,
	["ColorSequence"] = nil,
	["ColorSequenceKeypoint"] = function(keypoint, b, offset)
		local value = Binary_Encoders["Color3"](keypoint.Value)

		if not b then
			b = buffer.create(20)
			offset = 0
		end

		buffer.writef32(b, offset, 0)
		offset += 4
		buffer.writef32(b, offset, keypoint.Time)
		offset += 4
		buffer.copy(b, offset, value)

		return b, 20
	end,
	["NumberRange"] = function(raw)
		return Binary_Encoders._packF32(raw.Min, raw.Max)
	end,
	["Rect"] = function(raw)
		return Binary_Encoders._packMultiple(Binary_Encoders["Vector2"], raw.Min, raw.Max)
	end,
	["PhysicalProperties"] = function(raw)
		local b = buffer.create(25)

		-- rbxl uses flag 0-3, meanwhile attributes use 1 as it's always set; can keep 3 for compatibility with both
		-- * PhysicalProperties.new(0,0,0).AcousticAbsorption could be used as default value to compare AcousticAbsorption against
		buffer.writeu8(b, 0, 1)

		buffer.writef32(b, 1, raw.Density)
		buffer.writef32(b, 5, raw.Friction)
		buffer.writef32(b, 9, raw.Elasticity)
		buffer.writef32(b, 13, raw.FrictionWeight)
		buffer.writef32(b, 17, raw.ElasticityWeight)
		buffer.writef32(b, 21, raw.AcousticAbsorption)

		return b, 25
	end,
	["Color3uint8"] = function(raw)
		local b = buffer.create(3)

		buffer.writeu8(b, 0, math.floor(raw.R * 255))
		buffer.writeu8(b, 1, math.floor(raw.G * 255))
		buffer.writeu8(b, 2, math.floor(raw.B * 255))

		return b, 3
	end,
	["Region3"] = function(raw)
		local Translation = raw.CFrame.Position
		local HalfSize = raw.Size * 0.5

		return Binary_Encoders._packMultiple(
			Binary_Encoders["Vector3"],
			Translation - HalfSize, -- /App/util/Region3.cpp#L38
			Translation + HalfSize -- /App/util/Region3.cpp#L42
		)
	end,
	["Region3int16"] = function(raw)
		return Binary_Encoders._packMultiple(Binary_Encoders["Vector3int16"], raw.Min, raw.Max)
	end,
	["Font"] = function(raw)
		local encoder = Binary_Encoders["string"]

		local familyBuf, familySize = encoder(raw.Family)
		local faceIdBuf, faceIdSize = encoder("")

		local len = 3 + familySize + faceIdSize
		local b = buffer.create(len)

		local hasWeight, weight = pcall(index, raw, "Weight")
		local hasStyle, style = pcall(index, raw, "Style")

		buffer.writeu16(b, 0, hasWeight and weight.Value or 0)
		buffer.writeu8(b, 2, hasStyle and style.Value or 0)

		buffer.copy(b, 3, familyBuf)
		buffer.copy(b, 3 + familySize, faceIdBuf)

		return b, len
	end,
	["SecurityCapabilities"] = function(raw)
		local b = buffer.create(8)

		if raw == BASE_CAPABILITIES then
			return b, 8
		end

		Binary_Encoders._writeI64LE(b, 0, countCapabilityBits(raw))

		return b, 8
	end,
	["Path2DControlPoint"] = function(raw)
		return Binary_Encoders._packMultiple(Binary_Encoders["UDim2"], raw.Position, raw.LeftTangent, raw.RightTangent)
	end,
	-- ["Path3DControlPoint"] = function(raw)
	-- 	return Binary_Encoders._packMultiple(
	-- 		Binary_Encoders["Vector3"],
	-- 		raw.Position,
	-- 		raw.LeftTangent,
	-- 		raw.RightTangent
	-- 	)
	-- end,
	["TweenInfo"] = function(raw)
		local b = buffer.create(21)

		buffer.writef32(b, 0, raw.Time)
		buffer.writef32(b, 4, raw.DelayTime)
		buffer.writei32(b, 8, raw.RepeatCount)
		buffer.writeu32(b, 12, raw.EasingStyle.Value)
		buffer.writeu32(b, 16, raw.EasingDirection.Value)
		buffer.writeu8(b, 20, raw.Reverses and 1 or 0)

		return b, 21
	end,
	-- ["InstanceHandle"] = function(raw) -- InstanceAttributes6 FFlag
	-- 	-- If only these are present in attributes then AttributesSerialize becomes AAAAAA== (\0\0\0\0) aka 0 attrs
	-- 	-- and in xml adds <Ref name="__attrRef_ATTRIBUTEHERE">GetRef(raw:Get())</Ref>
	-- end,
}

do -- Sequences
	Binary_Encoders["NumberSequence"] = Binary_Encoders._makeSequence(Binary_Encoders["NumberSequenceKeypoint"], 12)

	Binary_Encoders["ColorSequence"] = Binary_Encoders._makeSequence(Binary_Encoders["ColorSequenceKeypoint"], 20)
end

do -- Vectors
	Binary_Encoders._packF32 = Binary_Encoders._makeVectorPacker(buffer.writef32, 4)

	Binary_Encoders._packI16 = Binary_Encoders._makeVectorPacker(buffer.writei16, 2)
end

local ESCAPES_PATTERN = "[&<>\"'\0\1-\9\11-\12\14-\31\127-\255]" -- * The safe way is to escape all five characters in text. However, the three characters " ' and > needn't be escaped in text
-- %z (\0 aka NULL) might not be needed as Roblox automatically converts it to space everywhere it seems like
-- Characters from: https://create.roblox.com/docs/en-us/ui/rich-text#escape-forms
-- * EscapesPattern should be ordered from most common to least common characters for sake of speed
-- * Might wanna use their numerical codes instead of named codes for reduced file size (Could be an Option)
-- TODO Maybe we should invert the pattern to only allow certain characters (future-proof)
local ESCAPES = {
	["&"] = "&amp;", -- 38
	["<"] = "&lt;", -- 60
	[">"] = "&gt;", -- 62
	['"'] = "&#34;", --  quot
	["'"] = "&#39;", -- apos
	["\0"] = "",
}

for rangeStart, rangeEnd in string.gmatch(ESCAPES_PATTERN, "(.)%-(.)") do
	for charCode = string.byte(rangeStart), string.byte(rangeEnd) do
		ESCAPES[string.char(charCode)] = "&#" .. charCode .. ";"
	end
end

local XML_Encoders
XML_Encoders = {
	_cdata = function(raw) -- ? Normally Roblox doesn't use CDATA unless the string has newline characters (\n); We rather CDATA everything for sake of speed
		return "<![CDATA[" .. raw .. "]]>"
	end,
	_protectedString = function(raw) -- ? its purpose is to "protect" data from being treated as ordinary character data during processing;
		return string_find(raw, "]]>") and string.gsub(raw, ESCAPES_PATTERN, ESCAPES) or XML_Encoders._cdata(raw)
	end,
	_normalizeNumber = function(raw)
		if raw ~= raw then
			return "NAN"
		elseif raw == math.huge then
			return "INF"
		elseif raw == -math.huge then
			return "-INF"
		end

		return raw
	end,
	_normalizeRange = function(raw)
		return raw ~= raw and "0" or raw -- Normally we should return "-nan(ind)" instead of "0" but this adds more compatibility
	end,
	_minMax = function(min, max, encoder)
		return "<min>" .. encoder(min) .. "</min><max>" .. encoder(max) .. "</max>"
	end,
	_makeSequence = function(keypoint_handler)
		-- The value is the text content, formatted as a space-separated list of floating point numbers.
		-- tostring(raw) also works (but way slower rn)
		-- ? Trailing whitespace after Envelope is needed for lune compatibility
		return function(raw)
			local sequence = ""

			for _, keypoint in raw.Keypoints do
				sequence ..= keypoint_handler(keypoint)
			end

			return sequence
		end
	end,
	_vector = function(X, Y, Z)
		local Value = "<X>" .. X .. "</X><Y>" .. Y .. "</Y>"

		if Z then
			Value ..= "<Z>" .. Z .. "</Z>"
		end

		return Value
	end,
	--------------------------------------------------------------
	--------------------------------------------------------------
	--------------------------------------------------------------
	-- AssetContentMap = function(raw) return "[]" end,  AssetContentMapSerializationEnabled	& VoxelGridNew5_PlaceFilter	FFlags
	Axes = function(raw)
		-- The text of this element is formatted as an integer between 0 and 7

		return "<axes>" .. countBits(raw.X, raw.Y, raw.Z) .. "</axes>"
	end,

	-- ! Assuming all base64 encoded strings won't have newlines

	BinaryString = function(raw) -- ! only add raw == nil if such edge-case exists (note it)
		return raw == "" and "" or base64encode(raw)
	end,

	BrickColor = function(raw)
		return raw.Number -- * Roblox encodes the tags as "int", but this is not required for Roblox to properly decode the type. For better compatibility, it is preferred that third-party implementations encode and decode "BrickColor" tags instead. Could also use "int" or "Color3uint8"
	end,
	CFrame = function(raw)
		local X, Y, Z, R00, R01, R02, R10, R11, R12, R20, R21, R22 = raw:GetComponents()
		return XML_Encoders._vector(X, Y, Z)
			.. "<R00>"
			.. R00
			.. "</R00><R01>"
			.. R01
			.. "</R01><R02>"
			.. R02
			.. "</R02><R10>"
			.. R10
			.. "</R10><R11>"
			.. R11
			.. "</R11><R12>"
			.. R12
			.. "</R12><R20>"
			.. R20
			.. "</R20><R21>"
			.. R21
			.. "</R21><R22>"
			.. R22
			.. "</R22>",
			"CoordinateFrame"
	end,
	-- CFrameQuat = function(raw) -- ? This will probably never release as it's not even used anywhere naturally, but there are hints it does exist as a DataType
	-- 	local X, Y, Z = raw:GetComponents() -- TODO Calls GetComponents twice due to cframeToQuaternion, recycle
	-- 	local QW, QX, QY, QZ = cframeToQuaternion(raw)

	-- 	return XML_Encoders._vector(X, Y, Z)
	-- 		.. "<QX>"
	-- 		.. QX
	-- 		.. "</QX><QY>"
	-- 		.. QY
	-- 		.. "</QY><QZ>"
	-- 		.. QZ
	-- 		.. "</QZ><QW>"
	-- 		.. QW
	-- 		.. "</QW>"
	-- end,
	Color3 = function(raw)
		return "<R>" .. raw.R .. "</R><G>" .. raw.G .. "</G><B>" .. raw.B .. "</B>"
	end,
	Color3uint8 = function(raw)
		return 0xFF000000
			+ (math.floor(raw.R * 255) * 0x10000)
			+ (math.floor(raw.G * 255) * 0x100)
			+ math.floor(raw.B * 255)
	end,
	ColorSequence = nil,
	ColorSequenceKeypoint = function(keypoint)
		local _normalizeRange = XML_Encoders._normalizeRange

		local color3 = keypoint.Value

		return _normalizeRange(keypoint.Time)
			.. " "
			.. _normalizeRange(color3.R)
			.. " "
			.. _normalizeRange(color3.G)
			.. " "
			.. _normalizeRange(color3.B)
			.. " 0 "
	end,
	Content = function(raw) -- TODO Not sure about Object & Opaque, run tests when possible
		-- * Currently the only way to tell which properties serialize (CanSave & CanLoad don't help here) is either API-2 dump or ReflectionService
		local SourceType = raw.SourceType
		return SourceType == Enum.ContentSourceType.None and "<null></null>"
			or SourceType == Enum.ContentSourceType.Uri and "<uri>" .. XML_Encoders.string(raw.Uri) .. "</uri>"
			or SourceType == Enum.ContentSourceType.Object and "<Ref>" .. getRef(raw.Object) .. "</Ref>"
		-- or SourceType == Enum.ContentSourceType.Opaque and "<Ref>" .. GetRef(raw.Opaque) .. "</Ref>"
	end,
	ContentId = function(raw) -- ! only add raw == nil if such edge-case exists (note it)
		return raw == "" and "<null></null>" or "<url>" .. XML_Encoders.string(raw) .. "</url>", "Content" -- ~~TODO Remove "Content" str once Roblox fully releases Content DataType~~ Nvm, looks like both are using <Content> tag now (ex. EmissiveMaskContent & ColorMap)
	end,
	CoordinateFrame = function(raw)
		return "<CFrame>" .. XML_Encoders.CFrame(raw) .. "</CFrame>"
	end,
	-- DateTime = function(raw) return raw.UnixTimestampMillis end, -- ? Doesn't have serializer
	EnumItem = function(raw)
		return raw.Value, "token"
	end,
	Faces = function(raw)
		-- The text of this element is formatted as an integer between 0 and 63
		return "<faces>" .. countBits(raw.Right, raw.Top, raw.Back, raw.Left, raw.Bottom, raw.Front) .. "</faces>"
	end,
	Font = function(raw)
		-- TODO (OPTIONAL ELEMENT): Figure out how to determine (ContentId) <CachedFaceId><url>rbxasset://fonts/GothamSSm-Medium.otf</url></CachedFaceId>
		--[[
		? game:GetService("TextService"):GetFontMemoryData()
		? rbxasset://fonts/families/{Enum.Font.BuilderSans.Name}.json
		]]

		local hasWeight, weight = pcall(index, raw, "Weight")
		local hasStyle, style = pcall(index, raw, "Style")

		return "<Family>"
			.. XML_Encoders.ContentId(raw.Family)
			.. "</Family><Weight>"
			.. (hasWeight and XML_Encoders.EnumItem(weight) or "")
			.. "</Weight><Style>"
			.. (hasStyle and style.Name or "") -- Weird but this field accepts .Name of enum instead..
			.. "</Style>"
	end,
	NetAssetRef = nil,
	NumberRange = function(raw) -- tostring(raw) also works
		-- The value is the text content, formatted as a space-separated list of floating point numbers.
		local _normalizeRange = XML_Encoders._normalizeRange

		return _normalizeRange(raw.Min) .. " " .. _normalizeRange(raw.Max) --[[.. " "]] -- ! This might be required for compatibility; _normalizeRange  is not needed here but it fixes the issue where "nan 10" value would reset to "0 0"
	end,
	NumberSequence = nil,
	NumberSequenceKeypoint = function(keypoint)
		local _normalizeRange = XML_Encoders._normalizeRange

		return _normalizeRange(keypoint.Time)
			.. " "
			.. _normalizeRange(keypoint.Value)
			.. " "
			.. _normalizeRange(keypoint.Envelope)
			.. " "
	end,

	-- Path2DControlPoint = function(raw)  -- ? Doesn't have serializer
	-- 	local udim2 = XML_Encoders.UDim2
	-- 	return "<Position>"
	-- 		.. udim2(raw.Position)
	-- 		.. "</Position>"
	-- 		.. "<LeftTangent>"
	-- 		.. udim2(raw.LeftTangent)
	-- 		.. "</LeftTangent>"
	-- 		.. "<RightTangent>"
	-- 		.. udim2(raw.RightTangent)
	-- 		.. "</RightTangent>"
	-- end,
	-- Path3DControlPoint = function(raw) end,

	PhysicalProperties = function(raw)
		--[[
			Contains at least one CustomPhysics element, which is interpreted according to the bool type. If this value is true, then the tag also contains an element for each component of the PhysicalProperties:

			Density
			Friction
			Elasticity
			FrictionWeight
			ElasticityWeight
			AcousticAbsorption

			The value of each component is represented by the text content formatted as a 32-bit floating point number (see float)
		]]

		local CustomPhysics = "<CustomPhysics>" .. XML_Encoders.bool(raw and true or false) .. "</CustomPhysics>"

		return raw
				and CustomPhysics .. "<Density>" .. raw.Density .. "</Density><Friction>" .. raw.Friction .. "</Friction><Elasticity>" .. raw.Elasticity .. "</Elasticity><FrictionWeight>" .. raw.FrictionWeight .. "</FrictionWeight><ElasticityWeight>" .. raw.ElasticityWeight .. "</ElasticityWeight><AcousticAbsorption>" .. raw.AcousticAbsorption .. "</AcousticAbsorption>"
			or CustomPhysics
	end,
	-- ProtectedString = function(raw) return tostring(raw), "ProtectedString" end,
	Ray = function(raw)
		local vector3 = XML_Encoders.Vector3

		return "<origin>" .. vector3(raw.Origin) .. "</origin><direction>" .. vector3(raw.Direction) .. "</direction>"
	end,
	Rect = function(raw)
		return XML_Encoders._minMax(raw.Min, raw.Max, XML_Encoders.Vector2), "Rect2D"
	end,
	Region3 = function(raw) -- ? Doesn't have serializer, the math is correct though (/Network/Replicator.cpp#L1306)
		local Translation = raw.CFrame.Position
		local HalfSize = raw.Size * 0.5

		return XML_Encoders._minMax(
			Translation - HalfSize, -- /App/util/Region3.cpp#L38
			Translation + HalfSize, -- /App/util/Region3.cpp#L42
			XML_Encoders.Vector3
		)
	end,
	Region3int16 = function(raw)
		return XML_Encoders._minMax(raw.Min, raw.Max, XML_Encoders.Vector3int16)
	end,

	-- ReplicationPV = function(raw) -- ? Not sure yet
	-- 	local vector3 = XML_Encoders.Vector3

	-- 	return "<RotationalVelocity>"
	-- 		.. vector3(raw.RotationalVelocity)
	-- 		.. "</RotationalVelocity><LinearVelocity>"
	-- 		.. vector3(raw.LinearVelocity)
	-- 		.. "</LinearVelocity><Position>"
	-- 		.. XML_Encoders.CFrame(raw.Position)
	-- 		.. "</Position>"
	-- end,

	SharedString = function(raw)
		return sharedStrings[XML_Encoders.BinaryString(raw)]
	end,
	SecurityCapabilities = function(raw)
		if raw == BASE_CAPABILITIES then
			return 0
		end

		return countCapabilityBits(raw)
	end,
	-- SystemAddress = function(raw) return raw end, -- PeerId? systemAddress as a string in the format "IP|Port", "|" being portDelineator, should not be '.', ':', '%', '-', '/', a number, or a-f  -- ? Not sure (binaryAddress)
	TweenInfo = function(raw)
		local _normalizeNumber = XML_Encoders._normalizeNumber
		return "Time:"
			.. _normalizeNumber(raw.Time)
			.. " DelayTime:"
			.. _normalizeNumber(raw.DelayTime)
			.. " RepeatCount:"
			.. _normalizeNumber(raw.RepeatCount)
			.. " Reverses:"
			.. (raw.Reverses and "True" or "False")
			.. " EasingDirection:"
			.. raw.EasingDirection.Name
			.. " EasingStyle:"
			.. raw.EasingStyle.Name
	end,
	UDim = function(raw)
		return "<S>" .. raw.Scale .. "</S><O>" .. raw.Offset .. "</O>"
	end,
	UDim2 = function(raw)
		local X, Y = raw.X, raw.Y

		return "<XS>"
			.. X.Scale
			.. "</XS><XO>"
			.. X.Offset
			.. "</XO><YS>"
			.. Y.Scale
			.. "</YS><YO>"
			.. Y.Offset
			.. "</YO>"
	end,

	UniqueId = function(raw) --  Roblox Staff: It actually doesn’t have a value assigned outside of Roblox Studio and Open Cloud execution. UniqueIdLookupService
		-- 	--[[
		-- 		UniqueId properties might be random everytime Studio saves a place file
		-- 		and don't have a use right now outside of packages, which SSI doesn't
		-- 		account for anyway. They generate diff noise, so we shouldn't serialize
		-- 		them until we have to.
		-- 	]]
		-- 	-- https://github.com/MaximumADHD/Roblox-Client-Tracker/blob/master/LuaPackages/Packages/_Index/ApolloClient/ApolloClient/utilities/common/makeUniqueId.lua#L68
		return string.gsub(raw, "-", "") -- seems to be string type by default
	end,

	-- User = function(raw)
	-- 	return raw:ToString() -- ? not sure yet
	-- end,

	Vector2 = function(raw)
		return XML_Encoders._vector(raw.X, raw.Y)
	end,
	Vector2int16 = nil,
	Vector3 = function(raw)
		return XML_Encoders._vector(raw.X, raw.Y, raw.Z)
	end,
	Vector3int16 = nil,
	bool = function(raw)
		return raw and "true" or "false"
	end,
	double = nil, -- Float64
	float = nil, -- Float32
	int = nil, -- Int32
	int64 = nil, -- Int64 (long)
	string = function(raw)
		return (raw == nil or raw == "") and ""
			or string_find(raw, "]]>") and string.gsub(raw, ESCAPES_PATTERN, ESCAPES)
			or XML_Encoders._cdata(string.gsub(raw, "\0", ""))
	end,

	--------------------------------------------------------------
	-----------%localappdata%/Roblox/GlobalSettings_13.xml--------
	-----------------------settings().Studio----------------------
	--------------------------------------------------------------
	-- QDir = function(raw) -- ? Not sure
	-- 	return raw
	-- end,
	-- QFont = function(raw) -- ? Not sure
	-- 	return raw
	-- end,
}

do -- Sequences
	XML_Encoders.NumberSequence = XML_Encoders._makeSequence(XML_Encoders.NumberSequenceKeypoint)

	XML_Encoders.ColorSequence = XML_Encoders._makeSequence(XML_Encoders.ColorSequenceKeypoint)
end

for encoderName, redirectName in
	{
		NetAssetRef = "SharedString",
		Vector2int16 = "Vector2",
		Vector3int16 = "Vector3",
		double = "_normalizeNumber",
		float = "_normalizeNumber",
		int = "_normalizeNumber",
		int64 = "_normalizeNumber",
	}
do
	XML_Encoders[encoderName] = XML_Encoders[redirectName]
end

local ClassList, FetchAPI

do
	local ClassPropertyExceptions = arrayToDict({
		Whitelist = {
			MeshPart = { "CollisionFidelity" },
			PartOperation = { "CollisionFidelity" },
			TriangleMeshPart = { "CollisionFidelity" },
		},
		Blacklist = {
			LuaSourceContainer = { "ScriptGuid" },
			Instance = { "UniqueId", "HistoryId" },
		},
	}, true)

	local function AttributesSerialize(attrs, header_bytes)
		-- * There are certain restrictions for names of attributes
		-- https://create.roblox.com/docs/reference/engine/classes/Instance#SetAttribute
		-- But it seems like even if those are present, Studio still opens the file just fine
		-- So there is no need to check for them currently

		-- ? Make sure to return early for empty table (this proved equally as fast when done using counter/next)

		local count = 0
		local buffer_size = 4
		local sorted = {}
		local formatted = table.clone(attrs)

		if header_bytes then
			buffer_size += #header_bytes
		end

		for attr, val in attrs do
			local t = resolveTypeName(val)

			local encoder = Binary_Encoders[t]
			if not encoder then
				continue
			end

			count += 1
			sorted[count] = attr

			local attr_size

			formatted[attr], attr_size = encoder(val)

			buffer_size += 5 + #attr + attr_size
		end

		table.sort(sorted)

		local b = buffer.create(buffer_size)

		local offset = 0

		if header_bytes then
			for _, header_byte in header_bytes do
				buffer.writeu8(b, offset, header_byte)
				offset += 1
			end
		end

		buffer.writeu32(b, offset, count)
		offset += 4

		local stringEncoder = Binary_Encoders["string"]
		for _, attr in sorted do
			local nameBuf, nameSize = stringEncoder(attr)

			buffer.copy(b, offset, nameBuf)
			offset += nameSize

			buffer.writeu8(b, offset, Attribute_Type_Ids[resolveTypeName(attrs[attr])])
			offset += 1

			local bb = formatted[attr]

			buffer.copy(b, offset, bb)
			offset += buffer.len(bb)
		end

		return buffer.tostring(b)
	end

	local function AttenuationSerialize(attenuations)
		if not next(attenuations) then
			return "\0" -- ? [CONSTANT] Version byte (likely)
		end

		local count = 0

		local sorted = {}

		for key in attenuations do
			count += 1
			sorted[count] = key
		end

		table.sort(sorted)

		local b = buffer.create(1 + count * 8)

		local offset = 1
		for _, key in sorted do
			buffer.writef32(b, offset, key)
			offset += 4
			buffer.writef32(b, offset, attenuations[key]) -- volume
			offset += 4
		end

		return buffer.tostring(b)
	end

	local function TransformsSerialize(transforms)
		local n = #transforms

		if n == 0 then
			return "\1\0\0\0\0\0\0\0"
		end

		local b = buffer.create(8 + n * 48)

		buffer.writeu32(b, 0, 1) -- ? [CONSTANT] Version byte (likely)
		buffer.writeu32(b, 4, n)

		local _packF32 = Binary_Encoders._packF32

		local offset = 8
		for _, transform in transforms do
			local X, Y, Z, R00, R01, R02, R10, R11, R12, R20, R21, R22 = transform:GetComponents()

			local xBasis = _packF32(R00, R01, R02)
			buffer.copy(b, offset, xBasis)
			offset += 12

			local yBasis = _packF32(R10, R11, R12)
			buffer.copy(b, offset, yBasis)
			offset += 12

			local zBasis = _packF32(R20, R21, R22)
			buffer.copy(b, offset, zBasis)
			offset += 12

			local position = _packF32(X, Y, Z)
			buffer.copy(b, offset, position)
			offset += 12
		end

		return buffer.tostring(b)
	end

	local function ServiceVisibilitySerialize(wantVisible)
		local ExplorerServiceVisibilityService = game:GetService("ExplorerServiceVisibilityService")
		local stringEncoder = Binary_Encoders["string"]
		local typeId = Attribute_Type_Ids["string"]

		local count = 0
		local buffer_size = 4
		local names = {}
		local formatted = {}

		for _, service in game:GetChildren() do
			if ExplorerServiceVisibilityService:GetServiceVisibility(service) == wantVisible then
				local name = service.ClassName
				local buf, size = stringEncoder(name)

				count += 1
				names[count] = name
				formatted[name] = buf

				buffer_size += 1 + size -- 1 byte type marker + payload
			end
		end

		if count == 0 then
			return "\0\0\0\0"
		end

		table.sort(names)

		local b = buffer.create(buffer_size)
		buffer.writeu32(b, 0, count)

		local offset = 4
		for _, name in names do
			buffer.writeu8(b, offset, typeId)
			offset += 1

			local bb = formatted[name]
			buffer.copy(b, offset, bb)
			offset += buffer.len(bb)
		end

		return buffer.tostring(b)
	end

	local function encodeTimeTicks(time)
		local scaled = time * 2400
		if not (scaled >= -2147483648.0 and scaled < 2147483648.0) then
			return -2147483648
		end
		return math.round(scaled)
	end

	local function writeTimesSection(b, offset, keys)
		buffer.writeu32(b, offset, 1)
		offset += 4
		buffer.writeu32(b, offset, #keys)
		offset += 4
		for _, key in keys do
			buffer.writei32(b, offset, encodeTimeTicks(key.Time))
			offset += 4
		end
		return offset
	end

	local function deriveTangentValueCurve(keys, i)
		local key = keys[i]
		local isFirst = (i == 1)
		local isLast = (i == #keys)
		if isLast then
			return 0, 0
		end
		if key.Interpolation == Enum.KeyInterpolationMode.Constant then
			return 0, 0
		end
		if key.Interpolation == Enum.KeyInterpolationMode.Linear then
			local nextKey = keys[i + 1]
			local t = 1 / (nextKey.Time - key.Time)
			return t, t
		end
		if isFirst then
			return 0, 0
		end
		local prevKey = keys[i - 1]
		local deltaPrev = key.Time - prevKey.Time
		if prevKey.Interpolation == Enum.KeyInterpolationMode.Constant then
			return 0, 0
		elseif prevKey.Interpolation == Enum.KeyInterpolationMode.Linear then
			local t = 1 / deltaPrev
			return t, t
		else
			local nextKey = keys[i + 1]
			local deltaNext = nextKey.Time - key.Time
			local t = (1 / deltaPrev + 1 / deltaNext) / 2
			return t, t
		end
	end

	local function deriveTangentFloatCurve(keys, i)
		local key = keys[i]
		local isFirst = (i == 1)
		local isLast = (i == #keys)
		if isLast then
			return 0, 0
		end
		if key.Interpolation == Enum.KeyInterpolationMode.Constant then
			return 0, 0
		end
		if key.Interpolation == Enum.KeyInterpolationMode.Linear then
			local nextKey = keys[i + 1]
			local slope = (nextKey.Value - key.Value) / (nextKey.Time - key.Time)
			return slope, slope
		end
		if isFirst then
			return 0, 0
		end
		local prevKey = keys[i - 1]
		if prevKey.Interpolation == Enum.KeyInterpolationMode.Constant then
			return 0, 0
		elseif prevKey.Interpolation == Enum.KeyInterpolationMode.Linear then
			local slope = (key.Value - prevKey.Value) / (key.Time - prevKey.Time)
			return slope, slope
		else
			return 0, 0
		end
	end

	--[[
		For more info:
		- https://github.com/luau/UniversalSynSaveInstance/blob/main/Tools/NotScriptable-Related/Potentially%20Missing%20Properties%20Dumper/Potentially%20Missing%20Properties%20Dumper.luau
		- https://github.com/luau/UniversalSynSaveInstance/blob/main/Tools/NotScriptable-Related/NotScriptable%20Dumper/NotScriptable%20Dumper.py
		]]
	local NotScriptableFixes = {
		Instance = {
			AttributesSerialize = function(instance)
				local attrs = instance:GetAttributes()

				if not next(attrs) then
					return ""
				end

				return AttributesSerialize(attrs)
			end,
			DefinesCapabilities = "Sandboxed",
			Tags = function(instance)
				-- https://github.com/RobloxAPI/spec/blob/master/properties/Tags.md

				local tags = service.CollectionService:GetTags(instance) -- ? Seems faster than instance:GetTags

				if #tags == 0 then
					return ""
				end

				return table.concat(tags, "\0")
			end,
		},
		Path2D = {
			PropertiesSerialize = function(instance)
				local control_points = instance:GetControlPoints()
				local n = #control_points

				if n == 0 then
					return "\0\0\0\0"
				end

				local b = buffer.create(4 + n * 49)
				buffer.writeu32(b, 0, n)

				local typeId = Attribute_Type_Ids["Path2DControlPoint"]
				local encoder = Binary_Encoders["Path2DControlPoint"]

				local offset = 4
				for i, point in control_points do
					local buf, bufSize = encoder(point)

					buffer.writeu8(b, offset, typeId)
					offset += 1

					buffer.copy(b, offset, buf)
					offset += bufSize
				end

				return buffer.tostring(b)
			end,
		},
		-- Path3D = {
		-- 	PropertiesSerialize = function(instance) -- ? Not sure & doesn't exist (yet?)
		-- 		local control_points = instance:GetControlPoints()
		-- 		local n = #control_points

		-- 		if n == 0 then
		-- 			return "\0\0\0\0"
		-- 		end

		-- 		local b = buffer.create(4 + n * 49)
		-- 		buffer.writeu32(b, 0, n)

		-- 		local typeId = Attribute_Type_Ids["Path3DControlPoint"]
		-- 		local encoder = Binary_Encoders["Path3DControlPoint"]

		-- 		local offset = 4
		-- 		for i, point in control_points do
		-- 			local buf,bufSize = encoder(point)

		-- 			buffer.writeu8(b, offset, typeId)
		-- 			offset += 1

		-- 			buffer.copy(b, offset, buf)
		-- 			offset += bufSize
		-- 		end

		-- 		return buffer.tostring(b)
		-- 	end,
		-- },
		PlayerEmulatorService = {
			SerializedEmulatedPolicyInfo = function(instance)
				local EmulatedPolicyInfo = instance:GetEmulatedPolicyInfo()

				if not next(EmulatedPolicyInfo) then
					return ""
				end

				return AttributesSerialize(EmulatedPolicyInfo)
			end,
		},
		StyleRule = {
			PropertiesSerialize = function(instance)
				local props = instance:GetProperties()

				if not next(props) then
					return "\0\0\0\0"
				end

				return AttributesSerialize(props)
			end,
			PropertyTransitionsSerialize = function(instance)
				local transitions = instance:GetPropertyTransitions()

				if not next(transitions) then
					return "\2\0\0\0\0\0"
				end

				return AttributesSerialize(transitions, { 0x02, 0x00 })
			end,
		},
		StyleQuery = {
			ConditionsSerialize = function(instance)
				local props = instance:GetConditions()

				if not next(props) then
					return "\0\0\0\0"
				end

				return AttributesSerialize(props)
			end,
		},
		FloatCurve = {
			ValuesAndTimes = function(instance)
				-- HapticEffect.WaveformData also has identical format but there's no GetKeys method, only Set
				local keys = instance:GetKeys()

				if #keys == 0 then
					return "\2\0\0\0\0\0\0\0\1\0\0\0\0\0\0\0"
				end

				local valuesPayloadSize = #keys * 14
				local b = buffer.create(8 + valuesPayloadSize + 8 + (#keys * 4))

				buffer.writeu32(b, 0, 2)
				buffer.writeu32(b, 4, #keys)

				local offset = 8
				for i, key in keys do
					local lt, rt = key.LeftTangent, key.RightTangent
					local mode = countBits(lt, rt)

					if mode == 0 then
						lt, rt = deriveTangentFloatCurve(keys, i)
					elseif mode == 1 then
						rt = lt
					elseif mode == 2 then
						lt = rt
					end

					buffer.writeu8(b, offset, key.Interpolation.Value) -- ! assumes this is tied to Enum order
					offset += 1
					buffer.writeu8(b, offset, mode)
					offset += 1
					buffer.writef32(b, offset, key.Value)
					offset += 4
					buffer.writef32(b, offset, lt)
					offset += 4
					buffer.writef32(b, offset, rt)
					offset += 4
				end

				offset = writeTimesSection(b, offset, keys)

				return buffer.tostring(b)
			end,
		},
		RotationCurve = {
			ValuesAndTimes = function(instance)
				local keys = instance:GetKeys()

				if #keys == 0 then
					return "\1\0\0\0\0\0\0\0\1\0\0\0\0\0\0\0"
				end

				local perKeySize = 1 + 16 + 4 + 4
				local b = buffer.create(8 + (#keys * perKeySize) + 8 + (#keys * 4))

				buffer.writeu32(b, 0, 1) -- ? [CONSTANT] Version byte (likely)
				buffer.writeu32(b, 4, #keys)

				local offset = 8
				for _, key in keys do
					local lt = key.LeftTangent or 0
					local rt = key.RightTangent or 0
					local qx, qy, qz, qw = cframeToQuaternion(key.Value)

					buffer.writeu8(b, offset, 12 + key.Interpolation.Value) -- ! assumes this is tied to Enum order
					offset += 1
					buffer.writef32(b, offset, qx)
					offset += 4
					buffer.writef32(b, offset, qy)
					offset += 4
					buffer.writef32(b, offset, qz)
					offset += 4
					buffer.writef32(b, offset, qw)
					offset += 4
					buffer.writef32(b, offset, lt)
					offset += 4
					buffer.writef32(b, offset, rt)
					offset += 4
				end

				offset = writeTimesSection(b, offset, keys)

				return buffer.tostring(b)
			end,
		},
		ValueCurve = {
			ValuesAndTimes = function(instance)
				local keys = instance:GetKeys()

				if #keys == 0 then
					return "\2\0\0\0\0\0\0\0\1\0\0\0\0\0\0\0"
				end

				local valueTypeName = instance.ValueType -- ! assumes Attr_Type_Ids won't have "Enum" key

				local typeId = Attribute_Type_Ids[valueTypeName]

				if not typeId then
					valueTypeName = resolveTypeName(keys[1].Value) -- Region3int16, EnumItem

					typeId = Attribute_Type_Ids[valueTypeName]
				end

				local encoder = Binary_Encoders[valueTypeName]

				if not encoder then
					return "\2\0\0\0\0\0\0\0\1\0\0\0\0\0\0\0"
				end

				local n = #keys
				local bufs = table.create(n)
				local sizes = table.create(n)
				local valuesPayloadSize = 0

				for i, key in keys do
					local dataBuf, dataSize = encoder(key.Value)
					bufs[i] = dataBuf
					sizes[i] = dataSize
					valuesPayloadSize += 1 + 1 + 4 + 1 + dataSize + 4 + 4
				end

				local b = buffer.create(8 + valuesPayloadSize + 8 + 4 * n)
				buffer.writeu32(b, 0, 2)
				buffer.writeu32(b, 4, n)

				local offset = 8
				for i, key in keys do
					local lt, rt = key.LeftTangent, key.RightTangent
					local dataSize = sizes[i]

					buffer.writeu8(b, offset, key.Interpolation.Value) -- ! assuming this is tied to Enum order
					offset += 1
					buffer.writeu8(b, offset, countBits(lt, rt))
					offset += 1
					buffer.writeu32(b, offset, dataSize + 1)
					offset += 4
					buffer.writeu8(b, offset, typeId)
					offset += 1
					buffer.copy(b, offset, bufs[i])
					offset += dataSize

					if lt == nil and rt == nil then
						lt, rt = deriveTangentValueCurve(keys, i)
					elseif lt == nil then
						lt = rt
					elseif rt == nil then
						rt = lt
					end

					buffer.writef32(b, offset, lt)
					offset += 4
					buffer.writef32(b, offset, rt)
					offset += 4
				end

				offset = writeTimesSection(b, offset, keys)

				return buffer.tostring(b)
			end,
		},
		MarkerCurve = {
			ValuesAndTimes = function(instance)
				local markers = instance:GetMarkers()
				local n = #markers

				if n == 0 then
					return "\2\0\0\0\0\0\0\0\1\0\0\0\0\0\0\0"
				end

				local strings_size = 0
				for _, marker in markers do
					strings_size += #marker.Value + 1
				end

				local b = buffer.create(8 + strings_size + 8 + (n * 4))

				buffer.writeu32(b, 0, 2) -- ? [CONSTANT] Version byte (likely)
				buffer.writeu32(b, 4, n)

				local offset = 8
				for _, marker in markers do
					local value = marker.Value
					buffer.writestring(b, offset, value)
					offset += #value + 1
					--buffer.writeu8(b, offset, 0) -- null terminator
					--offset += 1
				end

				offset = writeTimesSection(b, offset, markers)

				return buffer.tostring(b)
			end,
		},
		AnimationNodeDefinition = {
			InputPinData = function(instance)
				local input_pins = instance:GetInputPins()

				local n = #input_pins

				if n == 0 then
					return "\1\0\0\0\0\0\0\0"
				end

				local buffer_size = 8

				for _, pin in input_pins do
					buffer_size += 4 + #pin
				end

				local b = buffer.create(buffer_size)

				buffer.writeu32(b, 0, 1) -- ? [CONSTANT] Version byte (likely)
				buffer.writeu32(b, 4, n)

				local encoder = Binary_Encoders["string"]
				local offset = 8
				for _, pin in input_pins do
					local pinBuf, pinSize = encoder(pin)

					buffer.copy(b, offset, pinBuf)
					offset += pinSize
				end

				return buffer.tostring(b)
			end,
		},
		AnimationClip = {
			GuidBinaryString = function(instance) -- RobloxScriptSecurity
				local cleanGuid = string.gsub(instance.Guid, "[{}-]", "")
				local bytes = buffer.create(16)

				for i = 0, 15 do
					local hexByte = string.sub(cleanGuid, (i * 2) + 1, (i * 2) + 2)
					local val = tonumber(hexByte, 16) or 0
					buffer.writeu8(bytes, i, val)
				end

				return buffer.tostring(bytes)
			end,
		},
		AnimationRigData = {
			label = function(instance)
				local labels = instance:GetLabels() -- RobloxScriptSecurity
				local n = #labels

				if n == 0 then
					return "\1\0\0\0\0\0\0\0"
				end

				local b = buffer.create(8 + n * 4)

				buffer.writeu32(b, 0, 1) -- ? [CONSTANT] Version byte (likely)
				buffer.writeu32(b, 4, n)

				local offset = 8

				for _, label in labels do
					buffer.writeu32(b, offset, label)
					offset += 4
				end

				return buffer.tostring(b)
			end,
			name = function(instance)
				local names = instance:GetNames() -- RobloxScriptSecurity
				local n = #names

				if n == 0 then
					return "\1\0\0\0\0\0\0\0"
				end

				local buffer_size = 8

				for _, name in names do
					buffer_size += 4 + #name
				end

				local b = buffer.create(buffer_size)

				buffer.writeu32(b, 0, 1) -- ? [CONSTANT] Version byte (likely)
				buffer.writeu32(b, 4, n)

				local offset = 8

				for _, name in names do
					buffer.writeu32(b, offset, #name)
					offset += 4
				end
				for _, name in names do
					buffer.writestring(b, offset, name)
					offset += #name
				end

				return buffer.tostring(b)
			end,
			parent = function(instance)
				local parents = instance:GetParents() -- RobloxScriptSecurity
				local n = #parents

				if n == 0 then
					return "\1\0\0\0\0\0\0\0"
				end

				local b = buffer.create(8 + #parents * 2)

				buffer.writeu32(b, 0, 1) -- ? [CONSTANT] Version byte (likely)
				buffer.writeu32(b, 4, n)

				local offset = 8

				for _, parent in parents do
					buffer.writeu16(b, offset, parent)
					offset += 2
				end

				return buffer.tostring(b)
			end,
			postTransform = function(instance)
				return TransformsSerialize(instance:GetPostTransforms()) -- RobloxScriptSecurity
			end,
			preTransform = function(instance)
				return TransformsSerialize(instance:GetPreTransforms()) -- RobloxScriptSecurity
			end,
			transform = function(instance)
				return TransformsSerialize(instance:GetTransforms()) -- RobloxScriptSecurity
			end,
		},
		AudioDeviceInput = {
			AccessList = function(instance) -- CanSave & CanLoad false
				local userid_accesslist = instance:GetUserIdAccessList()

				local n = #userid_accesslist

				if n == 0 then
					return ""
				end

				local b = buffer.create(n * 8)

				local _writeI64LE = Binary_Encoders._writeI64LE

				local offset = 0
				for _, user_id in userid_accesslist do
					_writeI64LE(b, offset, user_id)
					offset += 8
				end

				return buffer.tostring(b)
			end,
		},
		AudioEmitter = {
			AngleAttenuation = function(instance)
				return AttenuationSerialize(instance:GetAngleAttenuation())
			end,
			DistanceAttenuation = function(instance)
				return AttenuationSerialize(instance:GetDistanceAttenuation())
			end,
		},
		AudioListener = {
			AngleAttenuation = function(instance)
				return AttenuationSerialize(instance:GetAngleAttenuation())
			end,
			DistanceAttenuation = function(instance)
				return AttenuationSerialize(instance:GetDistanceAttenuation())
			end,
		},
		-- AuroraScript = { -- Class not released yet
		-- 	AuroraScriptBindingsSerialize = function(instance)
		-- 		local bindings = service.AuroraScriptService:getInstancesForBehavior(instance)
		-- 		if #bindings == 0 then
		-- 			return ""
		-- 		end
		-- 		local refs = table.create(#bindings)
		-- 		for i, binding in bindings do
		-- 			refs[i] = GetRef(binding)
		-- 		end
		-- 		return table.concat(refs, "\0")
		-- 	end,
		-- },
		DebuggerBreakpoint = { line = "Line" }, -- ? This shouldn't appear in live games (try to prove this wrong)
		BallSocketConstraint = { MaxFrictionTorqueXml = "MaxFrictionTorque" },
		BasePart = {
			Color3uint8 = "Color",
			MaterialVariantSerialized = "MaterialVariant",
			size = "Size",
			siz = "Size",
		},
		DoubleConstrainedValue = { value = "Value" },
		IntConstrainedValue = { value = "Value" },

		CustomEvent = {
			PersistedCurrentValue = function(instance)
				local receiver = instance:GetAttachedReceivers()[1]
				if receiver then
					return receiver:GetCurrentValue()
				end

				local tempReceiver = Instance.new("CustomEventReceiver")
				local clone = Instance.fromExisting(instance)

				tempReceiver.Source = clone
				local value = tempReceiver:GetCurrentValue()

				tempReceiver:Destroy()
				clone:Destroy()

				return value
			end,
		},

		-- Lighting = {
		-- 	ExtendLightRangeTo120 = function() -- Seems default true now
		-- 		local light = Instance.new("PointLight")
		-- 		light.Range = 200
		-- 		return light.Range == 120 -- Ideally cache
		-- 	end,
		-- },

		Terrain = {
			AcquisitionMethod = "LastUsedModificationMethod", -- ? Not sure, RobloxScriptSecurity
			-- Material = function(instance) -- EnableMaterialSlotTable FFlag, uncomment once GetMaterialSlot is enabled
			-- 	local slots = {}
			-- 	for slotIndex = 2, 1e9 do -- limit is 64?
			-- 		local ok, baseMaterial, materialVariant, color =
			-- 			pcall(instance.GetMaterialSlot, instance, slotIndex)

			-- 		if ok then
			-- 			if baseMaterial then
			-- 				table.insert(
			-- 					slots,
			-- 					{
			-- 						slotIndex = slotIndex,
			-- 						baseMaterial = baseMaterial,
			-- 						materialVariant = materialVariant,
			-- 						color = color,
			-- 					}
			-- 				)
			-- 			end
			-- 		else
			-- 			break
			-- 		end
			-- 	end

			-- 	local size = 8 -- header

			-- 	for _, slot in slots do
			-- 		size += 15 + #slot.materialVariant
			-- 	end

			-- 	local b = buffer.create(size)
			-- 	local offset = 0

			-- 	-- header
			-- 	buffer.writeu32(b, offset, 1) -- version
			-- 	offset += 4

			-- 	buffer.writeu32(b, offset, #slots)
			-- 	offset += 4

			-- 	for _, slot in slots do
			-- 		buffer.writeu32(b, offset, slot.slotIndex)
			-- 		offset += 4

			-- 		buffer.writeu8(b, offset, (slot.color.R * 255))
			-- 		offset += 1
			-- 		buffer.writeu8(b, offset, (slot.color.G * 255))
			-- 		offset += 1
			-- 		buffer.writeu8(b, offset, (slot.color.B * 255))
			-- 		offset += 1

			-- 		buffer.writeu32(b, offset, slot.baseMaterial.Value)
			-- 		offset += 4

			-- 		buffer.writeu32(b, offset, #slot.materialVariant)
			-- 		offset += 4

			-- 		buffer.writestring(b, offset, slot.materialVariant)
			-- 		offset += #slot.materialVariant
			-- 	end

			-- 	return buffer.tostring(b)
			-- end,
			MaterialColors = function(instance)
				-- TODO Use code below once GetFirstCustomMaterialSlotIndex & GetMaterialSlot are enabled
				--[[
				local colors = {}
				for slotIndex = 0, instance:GetFirstCustomMaterialSlotIndex() - 1 do -- ! GetFirstCustomMaterialSlotIndex was removed
					local o, baseMaterial, materialVariant, color = pcall(instance.GetMaterialSlot, instance, slotIndex)

					if o then
						if color then
							table.insert(colors, color)
						end
					else
						break
					end
				end
				local b = buffer.create(#colors * 3)
				local offset = 0
				for _, color in colors do
					buffer.writeu8(b, offset, (color.R * 255))
					offset += 1
					buffer.writeu8(b, offset, (color.G * 255))
					offset += 1
					buffer.writeu8(b, offset, (color.B * 255))
					offset += 1
				end
				]]

				local TERRAIN_MATERIAL_COLORS =
					{ --https://github.com/rojo-rbx/rbx-dom/blob/master/rbx_dom_lua/src/customProperties.lua#L5
						Enum.Material.Grass,
						Enum.Material.Slate,
						Enum.Material.Concrete,
						Enum.Material.Brick,
						Enum.Material.Sand,
						Enum.Material.WoodPlanks,
						Enum.Material.Rock,
						Enum.Material.Glacier,
						Enum.Material.Snow,
						Enum.Material.Sandstone,
						Enum.Material.Mud,
						Enum.Material.Basalt,
						Enum.Material.Ground,
						Enum.Material.CrackedLava,
						Enum.Material.Asphalt,
						Enum.Material.Cobblestone,
						Enum.Material.Ice,
						Enum.Material.LeafyGrass,
						Enum.Material.Salt,
						Enum.Material.Limestone,
						Enum.Material.Pavement,
					}

				local b = buffer.create(69) -- 69 bytes: 6 reserved + 63 for colors (21 materials * 3 components)
				local offset = 6 -- 6 reserved bytes

				for _, material in TERRAIN_MATERIAL_COLORS do
					local color = instance:GetMaterialColor(material)
					buffer.writeu8(b, offset, (color.R * 255))
					offset += 1
					buffer.writeu8(b, offset, (color.G * 255))
					offset += 1
					buffer.writeu8(b, offset, (color.B * 255))
					offset += 1
				end

				return buffer.tostring(b)
			end,
		},
		BaseWrap = {
			TemporaryCageMeshContent = function(instance)
				return Content.fromUri(gethiddenproperty_fallback(instance, "TemporaryCageMeshId"))
			end,
		},
		MaterialVariant = {
			TexturePackContent = function(instance)
				return Content.fromUri(gethiddenproperty_fallback(instance, "TexturePack"))
			end,
		},
		TerrainDetail = {
			TexturePackContent = function(instance)
				return Content.fromUri(gethiddenproperty_fallback(instance, "TexturePack"))
			end,
		},
		WrapLayer = {
			TemporaryReferenceMeshContent = function(instance)
				return Content.fromUri(gethiddenproperty_fallback(instance, "TemporaryReferenceId"))
			end,
		},
		TriangleMeshPart = {
			FluidFidelityInternal = "FluidFidelity",
		},
		MeshPart = {
			InitialSize = "MeshSize",
			MeshID = "MeshId",
			VertexCount = function(instance) -- RobloxSecurity
				local meshId = instance.MeshId
				if meshId == "" then
					return __BREAK
				end
				return #service.UGCValidationService:GetMeshVerts(meshId)
			end,
		},
		PartOperation = {
			Content = function(instance)
				return Content.fromUri(gethiddenproperty_fallback(instance, "AssetId"))
			end,
			InitialSize = "MeshSize",
		},
		Part = { shape = "Shape", shap = "Shape" },
		TrussPart = { style = "Style" },
		FormFactorPart = {
			formFactorRaw = "FormFactor",
		},
		Fire = { heat_xml = "Heat", size_xml = "Size" },
		Clothing = {
			Outfit1Content = function(instance)
				return Content.fromUri(gethiddenproperty_fallback(instance, "Outfit1"))
			end,
			Outfit2Content = function(instance)
				return Content.fromUri(gethiddenproperty_fallback(instance, "Outfit2"))
			end,
		},
		Humanoid = {
			Health_XML = "Health",
			InternalBodyScale = function(instance) -- RobloxScriptSecurity
				-- X - BodyWidthScale
				-- Y - BodyHeightScale
				-- Z - BodyDepthScale
				local a = instance.RootPart

				if not a then
					return __BREAK
				end

				return instance:GetAccessoryHandleScale(a, Enum.BodyPartR15.RootPart)
			end,
			InternalHeadScale = function(instance) -- RobloxScriptSecurity
				-- HeadScale
				local a = instance.Parent and instance.Parent:FindFirstChild("Head")

				if not a then
					return __BREAK
				end

				return instance:GetAccessoryHandleScale(a, Enum.BodyPartR15.Head).X -- X, Y, Z seem to be always equal
			end,
			NetworkHumanoidState = function(instance) -- CanSave & CanLoad false
				return instance:GetState()
			end,
		},
		HumanoidDescription = {
			AccessoryBlob = function(instance)
				local blob = {}

				for _, acc in instance:GetAccessories(false) do
					table.insert(blob, {
						AssetId = acc.AssetId,
						Order = acc.Order,
						AccessoryType = acc.AccessoryType.Name,
						Puffiness = acc.Puffiness,
					})
				end

				return service.HttpService:JSONEncode(blob)
			end,
			EmotesDataInternal = function(instance)
				local emotes_data = ""
				for name, ids in instance:GetEmotes() do
					emotes_data ..= name .. "^" .. table.concat(ids, "^") .. "^\\"
				end
				return emotes_data
			end,
			EquippedEmotesDataInternal = function(instance)
				local equipped_emotes = instance:GetEquippedEmotes()
				if #equipped_emotes == 0 then
					return ""
				end

				local equipped_emotes_data = ""
				for _, emote in equipped_emotes do
					equipped_emotes_data = equipped_emotes_data .. emote.Slot .. "^" .. emote.Name .. "\\"
				end
				return equipped_emotes_data
			end,
		},
		LocalizationTable = {
			Contents = function(instance)
				return instance:GetContents() --service.HttpService:JSONEncode(instance:GetEntries())
			end,
		},
		MaterialService = { Use2022MaterialsXml = "Use2022Materials" }, -- RobloxScriptSecurity
		VideoPlayer = {
			PlayingReplicating = "IsPlaying", -- CanSave & CanLoad false
		},

		Model = {
			ModelMeshCFrame = function(instance)
				return instance:GetModelCFrame() -- GetBoundingBox
			end,
			ModelMeshSize = function(instance)
				return instance:GetExtentsSize() -- GetBoundingBox, GetModelSize
			end,
			Scale = function(instance) -- CanSave & CanLoad false
				return instance:GetScale()
			end,
			ScaleFactor = function(instance)
				return instance:GetScale()
			end,
			WorldPivotData = "WorldPivot", -- TODO This doesn't accurately represent whether optional type property is present or not (it's never nil), gethiddenproperty or gethiddenproperty_fallback is preferred
		},
		PackageLink = {
			PackageContentSerialize = "PackageContent",
			PackageIdSerialize = "PackageId",
			VersionIdSerialize = "VersionNumber",
		},
		Players = { MaxPlayersInternal = "MaxPlayers", PreferredPlayersInternal = "PreferredPlayers" }, -- ? Only needed for execs that lack LocalUserSecurity (Level 2, 5, 9), even so, it's a pretty useless information as it can be viewed elsewhere

		StarterPlayer = {
			AvatarJointUpgrade_SerializedRollout = "AvatarJointUpgrade", -- RobloxScriptSecurity
			-- LoadCharacterLayeredClothing = "LoadCharacterLayeredClothing ",-- * Both NotScriptable
		},
		Smoke = { size_xml = "Size", opacity_xml = "Opacity", riseVelocity_xml = "RiseVelocity" },
		Sound = {
			xmlRead_MinDistance_3 = "RollOffMinDistance", -- * Also MinDistance
			xmlRead_MaxDistance_3 = "RollOffMaxDistance", -- * Also MaxDistance
		},
		ViewportFrame = {
			CameraCFrame = function(instance)
				local CurrentCamera = instance.CurrentCamera

				return CurrentCamera and CurrentCamera.CFrame or CFrame.identity
			end,
			CameraFieldOfView = function(instance)
				local CurrentCamera = instance.CurrentCamera

				return math.rad(CurrentCamera and CurrentCamera.FieldOfView or 70)
			end,
		},
		WeldConstraint = {
			CFrame0 = function(instance)
				local Part0, Part1 = instance.Part0, instance.Part1

				return Part0 and Part1 and Part0.CFrame:ToObjectSpace(Part1.CFrame) or CFrame.identity
			end,
			CFrame1 = function(instance)
				local Part0, Part1 = instance.Part0, instance.Part1

				return Part0 and Part1 and Part1.CFrame:ToObjectSpace(Part0.CFrame) or CFrame.identity
			end,
			Part0Internal = "Part0",
			Part1Internal = "Part1",
			State = function(instance)
				return countBits(instance.Enabled, instance.Active)
			end,
		},
		Workspace = {
			-- SignalBehavior2 = "SignalBehavior", -- * Both NotScriptable
			CollisionGroups = function() -- deprecated
				local registered = game:GetService("PhysicsService"):GetRegisteredCollisionGroups()

				local n = #registered
				if n == 0 then
					return ""
				end

				local parts = table.create(n)
				for i, group in registered do
					parts[i] = group.name .. "^" .. i - 1 .. "^" .. group.mask
				end
				return table.concat(parts, "\\")
			end,
		},
		WorldRoot = {
			CollisionGroupData = function()
				local collision_groups = game:GetService("PhysicsService"):GetRegisteredCollisionGroups()
				local n = #collision_groups

				if n == 0 then
					return "\1\0"
				end

				local buffer_size = 2 -- version + count

				for _, group in collision_groups do
					buffer_size += 7 + #group.name -- id(1) + typeId(1) + mask(4) + namelen(1) + name
				end

				local b = buffer.create(buffer_size)

				buffer.writeu8(b, 0, 1) -- ? [CONSTANT] Version byte (likely)
				buffer.writeu8(b, 1, n)

				local typeId_int32 = Attribute_Type_Ids["int32"]
				local offset = 2

				for i, group in collision_groups do
					local name, id, mask = group.name, i - 1, group.mask
					local name_len = #name

					buffer.writeu8(b, offset, id) -- ID
					offset += 1

					buffer.writeu8(b, offset, typeId_int32) -- Type ID for int32 (0x04)
					offset += 1

					buffer.writei32(b, offset, mask) -- Mask value as signed 32-bit integer
					offset += 4

					buffer.writeu8(b, offset, name_len) -- Name length
					offset += 1
					buffer.writestring(b, offset, name) -- Name
					offset += name_len
				end

				return buffer.tostring(b)
			end,
		},

		ServiceVisibilityService = { -- Service doesn't exist outside of Studio
			HiddenServices = function()
				return ServiceVisibilitySerialize(false)
			end,
			VisibleServices = function()
				return ServiceVisibilitySerialize(true)
			end,
		},

		-- EditableImage = { -- Not sure how this would be encountered as it can't be parented
		-- 	ImageData = function(instance) -- Not sure if format is correct
		-- 		return buffer.tostring(instance:ReadPixelsBuffer(Vector2.new(), instance.Size)) -- Vector2.zero can be set to a local to avoid repeat creations
		-- 	end,
		-- },
	}
	for _, enum_item in Enum.Material:GetEnumItems() do
		NotScriptableFixes.MaterialService[enum_item.Name .. "Name"] = function(instance)
			return instance:GetBaseMaterialOverride(enum_item)
		end
	end

	NotScriptableFixes.Workspace.CollisionGroupData = NotScriptableFixes.WorldRoot.CollisionGroupData -- TODO Remove once v732 goes live

	FetchAPI = function()
		-- Credits @MaximumADHD

		local FILE_NAME = "API_DUMP.json"

		local API_Dump

		local Max_SecurityCapabilities = SecurityCapabilities.new(unpack(Enum.SecurityCapability:GetEnumItems()))
		local filter = { Security = Max_SecurityCapabilities, ExcludeDisplay = true, ExcludeInherited = true }

		-- ! exact version match is preferred, mismatched dump versions might result in saveinstance trying to save properties that your client doesn't have yet
		local APIDUMP_FETCHERS = {
			[1] = function()
				local res = readfile(FILE_NAME)
				if res and res ~= "" then
					return service.HttpService:JSONDecode(res)[FULL_VERSION]
				end
			end,
			[2] = function() -- version-history.json -> exact_match -> zbeta -> LIVE -> sibling major matches
				local client_version_str = tostring(CLIENT_VERSION)
				local dump
				local matching_versions, matched, is_matched, exact_match = {}, {}
				local function process_line(line, noinsert)
					local file_version, patch_commit, version_hash =
						string.match(line, '"%d+%.(%d+)%.([^"]+)": "(version%-[^"]+)')
					if file_version == client_version_str then
						is_matched = true
						if version_hash and not matched[version_hash] then -- ! this might cause issues if different file_versions point to the same version_hash (never happened)
							matched[version_hash] = true
							if not noinsert then -- to avoid fetching duplicates
								table.insert(matching_versions, version_hash) -- ? Retain the order (by latest)
							end
							if string.sub(FULL_VERSION, -#patch_commit) == patch_commit then
								return version_hash -- exact match
							end
						end
					elseif is_matched then
						return false -- stop iteration
					end
				end

				-- ! Assumes Normal dumps never include Default; Full dumps always do.
				local function isFullDump(classes)
					for _, class in classes do
						for _, member in class.Members do
							if member.MemberType == "Property" then
								return member.Default ~= nil
							end
						end
					end
					return false -- no properties found at all; treat as inconclusive/not full
				end

				local function tryFetchDump(url)
					local ok, decoded = pcall(function()
						local raw = game:HttpGet(url, true)
						return service.HttpService:JSONDecode(raw)
					end)
					return ok and decoded.Classes or nil
				end

				local function fetchFullApiDump(hash)
					-- Primary: Roblox CDN (only WindowsStudio64 hashes seem supported here)
					-- Might need timeout logic..
					local decoded = tryFetchDump("https://setup.rbxcdn.com/" .. hash .. "-Full-API-Dump.json")
					if decoded and isFullDump(decoded) then
						return decoded
					end

					-- Fallback: our own archived full dumps, in case Roblox's endpoint
					-- silently returned a normal dump instead of a full one (or 404'd).
					decoded = tryFetchDump(
						"https://raw.githubusercontent.com/setup-rbxcdn/roblox-full-api-dumps/refs/heads/main/full-dumps/"
							.. hash
							.. "-Full-API-Dump.json"
					)
					if decoded and isFullDump(decoded) then -- isFullDump check is useless here but why not
						return decoded
					end

					return nil
				end

				do
					local o, r = pcall(
						game.HttpGet,
						game,
						"https://raw.githubusercontent.com/setup-rbxcdn/setup-rbxcdn.github.io/refs/heads/main/version-history/Windows/Studio64.json",
						true
					)
					if o then
						local version_history = string.split(r, "\n")
						version_history[#version_history] = nil -- the "}"
						-- 1. version-history pass (bottom-up)
						for i = #version_history, 2, -1 do -- 2 to avoid "{"
							local res = process_line(version_history[i])
							if res == false then
								break
							elseif res then
								exact_match = res
							end
						end
					end
				end
				do -- ? this might happen when user is on a new version but Roblox-Client-Tracker hasn't updated version-history.json yet
					local function fallback_channel(channel)
						local ok, res = pcall(function()
							return service.HttpService:JSONDecode(
								game:HttpGet(
									"https://clientsettingscdn.roblox.com/v2/client-version/WindowsStudio64"
										.. (channel and "/channel/" .. channel or ""),
									true
								)
							)
						end)
						if not ok then
							return
						end
						if res.version and res.clientVersionUpload then -- just in case
							local line = '"' .. res.version .. '": "' .. res.clientVersionUpload
							return process_line(line, true)
						end
					end
					if not exact_match then
						exact_match = fallback_channel("zbeta") or fallback_channel() -- LIVE
					end
				end
				if exact_match then
					dump = fetchFullApiDump(exact_match)
				end
				if not dump then
					for _, version_hash in matching_versions do -- TODO ideally match nearest by Commit segment of version(), new>old
						dump = fetchFullApiDump(version_hash)
						if dump then
							break
						end
					end
				end
				return dump
			end,
			[3] = function()
				-- ! Some executors (like Xeno) error on ReflectionService.GetClasses due to their ProxyService
				-- TODO At the time of writing this is missing a way to confirm NotCreatable & NotScriptable
				-- also is missing some classes like UserGameSettings, not that important though as none of them appear under DataModel
				local classes, classes_size = {}, 1

				for _, api_class in service.ReflectionService:GetClasses(filter) do
					local members, members_size = {}, 1
					local className = api_class.Name

					local class = {
						Name = className,
						Members = members,
						Superclass = api_class.Superclass or "<<<ROOT>>>",
					}
					local permits = api_class.Permits

					local tags = {}
					if api_class.Service then
						table.insert(tags, "Service")
					elseif permits and permits["GetService"] then
						table.insert(tags, "Service")
					elseif not permits or not permits["New"] then -- Some services can be Instance.new so it's better to include them
						table.insert(tags, "NotCreatable")
					end

					if #tags ~= 0 then
						class.Tags = tags
					end

					local o, r = pcall(
						service.ReflectionService.GetPropertiesOfClass,
						service.ReflectionService,
						className,
						filter
					) -- ? Might produce errors (ex. RolloutValidation) therefore pcall
					if o then
						for _, property in r do
							local propertyName = property.Name

							local valueType = property.Type
							local valueType_Name = valueType.EngineType

							local category = valueType.Category

							local member_tags = {}

							if not next(property.Permits) then
								table.insert(member_tags, "NotScriptable")
							end

							if valueType_Name == "Enum" then
								category, valueType_Name = "Enum", valueType.EnumType
							elseif valueType_Name == "RefType" then
								category, valueType_Name = "Class", valueType.InstanceType
							else
								local renames = {
									CoordinateFrame = "CFrame",
									Rect2D = "Rect",
									Vector3Int16 = "Vector3int16",
									Vector2Int16 = "Vector2int16",
									Region3Int16 = "Region3int16",
								}
								valueType_Name = renames[valueType_Name] or valueType_Name
							end

							-- property.Display.DeprecationMessage can be used to track Deprecated tag (not always though)

							local member = {
								Name = propertyName,
								MemberType = "Property",
								ValueType = { Name = valueType_Name, Category = category },
								Serialization = { CanLoad = property.Serialized, CanSave = property.Serialized },
								-- Default = Member.Default,
								-- Special = Special,
								-- Tags = MemberTags,
							}

							if #member_tags ~= 0 then
								member.Tags = member_tags
							end

							members[members_size] = member
							members_size += 1
						end
						-- else
						-- warn("Missing", className, r)
					end
					classes[classes_size] = class
					classes_size += 1
				end

				return classes
			end,
			[4] = function()
				return service.HttpService:JSONDecode(
					game:HttpGet(
						"https://raw.githubusercontent.com/MaximumADHD/Roblox-Client-Tracker/roblox/Mini-API-Dump.json",
						true
					)
				).Classes
			end,
		}

		for i, fetcher in APIDUMP_FETCHERS do
			local o, r = pcall(fetcher)
			if o and r then
				API_Dump = r
				if i == 2 then -- relies on [2] being the same
					if writefile then
						local ok, err =
							pcall(writefile, FILE_NAME, service.HttpService:JSONEncode({ [FULL_VERSION] = API_Dump }))
						if not ok then
							warn("[DEBUG] DUMP writefile error", err)
						end
					end
				end
				break
			elseif r ~= false and 2 < i then
				warn("[DEBUG] Failed to get", FULL_VERSION, "version API Dump, trying fallbacks..")
				warn("[DEBUG] Method number:", i, "Reason:", r)
			end
		end

		local classList = {}
		local tmp_classDict = {}

		local ClassesWhitelist, ClassesBlacklist = ClassPropertyExceptions.Whitelist, ClassPropertyExceptions.Blacklist

		local API_Dump_Decoded = API_Dump

		-- First pass (prep)
		for _, API_Class in API_Dump_Decoded do
			local ClassName = API_Class.Name
			local props = {}

			for _, Member in API_Class.Members do
				local MemberType = Member.MemberType
				if MemberType == "Property" or MemberType == "Function" then
					props[Member.Name] = {
						ValueType = MemberType == "Property" and Member.ValueType.Name,
						MemberType = MemberType,
						-- Serialization = Member.Serialization,
					}
				end
			end

			tmp_classDict[ClassName] = props
		end

		-- Second pass (actual)
		for _, API_Class in API_Dump_Decoded do
			local ClassProperties, ClassProperties_size = {}, 1
			local Class = {
				Properties = ClassProperties,
				Superclass = API_Class.Superclass,
				-- Tags = {},
				NotCreatable = nil,
			}

			local ClassName = API_Class.Name
			local ClassTags = API_Class.Tags

			if ClassTags then
				local Tags = arrayToDict(ClassTags, nil, nil, "string")
				-- Class.Tags = Tags -- or {}
				Class.NotCreatable = Tags.NotCreatable
				Class.Service = Tags.Service
			end

			local NotScriptableFixClass = NotScriptableFixes[ClassName]

			-- ? Check 96ea8b2a755e55a78aedb55a7de7e83980e11077 commit - If a NotScriptableFix is needed that relies on another NotScriptable Property (which doesn't really make sense in the first place)

			local ClassWhitelist, ClassBlacklist = ClassesWhitelist[ClassName], ClassesBlacklist[ClassName]

			local ContentProperties
			for _, Member in API_Class.Members do
				if Member.MemberType == "Property" then
					local Serialization = Member.Serialization

					if Serialization.CanLoad then -- If Roblox doesn't save it why should we; If Roblox doesn't load it we don't need to save it
						--[[
							-- ! CanSave replaces "Tags.Deprecated" check because there are some old properties which are deprecated yet have CanSave.
							Example: Humanoid.Health is CanSave false due to Humanoid.Health_XML being CanSave true (obsolete properties basically) - in this case both of them will Load. (aka PropertyPatches)
							CanSave being on same level as CanLoad also fixes potential issues with overlapping properties like Color, Color3 & Color3uint8 of BasePart, out of which only Color3uint8 should save
							This also fixes everything in IgnoreClassProperties automatically without need to hardcode :)
							A very simple fix for many problems that saveinstance scripts encounter!
						--]]
						local PropertyName = Member.Name

						local ValueType = Member.ValueType
						local ValueType_Name = ValueType.Name

						if ValueType_Name == "Content" or ValueType_Name == "AssetContentMap" then -- TODO Can Skip this if our dump was fetched from ReflectionService (make it explicit), currently ReflectionService dump isn't written to file
							-- ? This filters out Content DataType properties that Roblox doesn't serialize (even if they have CanSave/CanLoad true), takes less space, time & prevents potential property conflicts (Content vs ContentId)
							if not ContentProperties then
								ContentProperties = {}

								local o, properties = pcall(
									service.ReflectionService.GetPropertiesOfClass,
									service.ReflectionService,
									ClassName,
									filter
								) -- ? Might produce errors (ex. RolloutValidation) therefore pcall
								if o then
									for _, property in properties do -- * might as well check all properties, not just Content type
										ContentProperties[property.Name] = property.Serialized
									end
								end
							end
							if ContentProperties[PropertyName] ~= nil then
								Serialization.CanSave = ContentProperties[PropertyName]
							end
						end

						if
							(Serialization.CanSave or ClassWhitelist and ClassWhitelist[PropertyName])
							and not (ClassBlacklist and ClassBlacklist[PropertyName])
						then
							local MemberTags = Member.Tags

							local Special, PreferredDescriptorName

							if MemberTags then
								for _, tag in MemberTags do
									if type(tag) == "table" then
										PreferredDescriptorName = tag.PreferredDescriptorName
										if PreferredDescriptorName and Special then
											break
										end
									elseif tag == "NotScriptable" then
										Special = true
										if PreferredDescriptorName then
											break
										end
									end
								end
							end

							local preferredDescriptorProp
							if PreferredDescriptorName then
								preferredDescriptorProp = tmp_classDict[ClassName][PreferredDescriptorName]

								if -- Prevents type mismatch
									preferredDescriptorProp == nil
									or (
										preferredDescriptorProp.MemberType == "Property"
										and ValueType_Name ~= preferredDescriptorProp.ValueType
									)
								then -- For ex. (if they were notscriptable) CollisionGroupId (int) -> CollisionGroup (string)
									PreferredDescriptorName = nil
								end
							end

							-- if not Special then
							local Property = {
								Name = PropertyName,
								Category = ValueType.Category,
								-- Default = Member.Default,
								-- Tags = MemberTags,
								ValueType = ValueType_Name,

								Special = Special,

								CanRead = nil,
							}

							if string.sub(ValueType_Name, 1, 8) == "Optional" then
								-- Extract the string after "Optional"
								Property.Optional = string.sub(ValueType_Name, 9)
							end

							local NotScriptableFix = NotScriptableFixClass and NotScriptableFixClass[PropertyName]
							local accessFunc = PreferredDescriptorName
								and (
									preferredDescriptorProp.MemberType == "Property"
										and function(instance)
											return instance[PreferredDescriptorName]
										end
									or function(instance) -- Assume MemberType is "Function"
										return instance[PreferredDescriptorName](instance)
									end
								)

							Property.Fallback = NotScriptableFix
									and (type(NotScriptableFix) == "function" and NotScriptableFix or accessFunc and function(
										instance
									)
										local o, r = pcall(accessFunc, instance)
										if o then
											return r
										end
										return instance[NotScriptableFix]
									end or function(instance)
										return instance[NotScriptableFix]
									end)
								or accessFunc

							ClassProperties[ClassProperties_size] = Property
							ClassProperties_size += 1

							-- end
						end
					end
				end
			end

			classList[ClassName] = Class
		end

		return classList
	end
end

local GLOBAL_ENV = getgenv and getgenv() or _G or shared

--[=[
    @class SynSaveInstance
    Represents the options for saving instances with custom settings using the synsaveinstance function.
]=]

--- @interface CustomOptions table
--- * Structure of the main CustomOptions table.
--- * Note: Options are case-insensitive, meaning you can type `NilInstances` option as `nilInStaNces` and it still will be valid.
--- @within SynSaveInstance
--- @field __DEBUG_MODE boolean -- This will print debug logs to console about unusual scenarios. Recommended to enable if you wish to help us improve our products and find bugs / issues with it! ___Default:___ false
--- @field ReadMe boolean --___Default:___ true
--- @field SafeMode boolean -- Disabled by the Dex++ Custom safety policy. ___Default:___ false
--- @field KillAllScripts boolean -- Disabled by the Dex++ Custom safety policy. ___Default:___ false
--- @field BoostFPS boolean -- Disabled by the Dex++ Custom safety policy. ___Default:___ false
--- @field ShutdownWhenDone boolean -- Disabled by the Dex++ Custom safety policy. ___Default:___ false
--- @field AntiIdle boolean -- Disabled by the Dex++ Custom safety policy. ___Default:___ false
--- .Anonymous {boolean|table{UserId = string, Name = string}} -- * **RISKY:** Cleans the file of any info related to your account like: Name, UserId. This is useful for some games that might store that info in GUIs or other Instances. Might potentially mess up parts of strings that contain characters that match your Name or parts of numbers that match your UserId. Can also be a table with UserId & Name keys. ___Default:___ false
--- @field ShowStatus boolean -- ___Default:___ true
--- @field Callback function -- If set, the serialized data will be sent to the callback function instead of to file. ___Default:___ false
--- @field mode string -- Valid modes: full, optimized, scripts. Change this to invalid mode like "invalid" if you only want ExtraInstances. "optimized" mode is **NOT** supported with *@Object* option. ___Default:___ `"optimized"`
--- @field Decompile boolean -- Script decompiling. ___Default:___ true
--- @field scriptcache boolean -- Use decompiled script cache to avoid decompiling duplicate scripts. ___Default:___ true
--- @field DecompileTimeout number -- If the decompilation run time exceeds this value it gets cancelled. Set to -1 to disable timeout. ___Default:___ 10
--- @field BytecodeTimeout number -- If the SaveBytecode run time exceeds this value it gets cancelled. Set to -1 to disable timeout. ___Default:___ 3
--- @field DecompileJobless boolean -- Includes already decompiled code in the output. No new scripts are decompiled. ___Default:___ false
--- @field SaveBytecode boolean -- Includes bytecode in the output. Useful if you wish to be able to decompile it yourself later. ___Default:___ false
--- .DecompileIgnore {Instance | Instance.ClassName | [Instance.ClassName] = {Instance.Name}} -- Ignores matched instances and their descendants by default. To ignore only the instance itself, set the value to `false`. Examples: `"Chat"` matches any instance with ClassName "Chat"; `Players = {"MyPlayerName"}` matches class "Players" AND name "MyPlayerName" only; `workspace` matches a specific instance by reference; `[workspace] = false` matches a specific instance by reference, ignoring only itself and not its descendants. ___Default:___ {TextChatService}
--- .IgnoreList {Instance | Instance.ClassName | [Instance.ClassName] = {Instance.Name | false}} -- Structure mirrors **@DecompileIgnore**, except `false` means keep the instance but ignore its descendants. Supports both instance references and ClassName strings. Examples: `"CoreGui"` skips entirely; `CorePackages = false` keeps the instance but skips its descendants; `Players = {"SomePlayer"}` skips a specific named instance with specific ClassName. ___Default:___ {CoreGui, CorePackages, Packages = false}
--- .ExtraInstances {Instance} -- If used with any invalid mode (like "invalidmode") it will only save these instances. ___Default:___ {}
--- @field IgnoreProperties table -- Ignores properties by Name. ___Default:___ {}
--- @field SaveCacheInterval number -- The less the value the more often it saves, but that would mean less performance due to constantly saving. ___Default:___ 0x1600 * 10
--- @field FilePath string -- The name (can include a path) of the file to save to. If it has no extension, `.rbxmx/rbxm` (models) or `.rbxlx/rbxl` (places) is appended; an existing extension is left as-is. Ignores `OPTIONS.AvoidFileOverwrite`. ___Default:___ false
--- @field AvoidFileOverwrite boolean -- Prevents writing to place file that already exists. ___Default:___ true
--- @field Object Instance -- * If provided, saves as .rbxmx (Model file) instead. If Object is game, it will be saved as a .rbxl file. **MUST BE AN INSTANCE REFERENCE, FOR EXAMPLE - *game.Workspace***. `"optimized"` mode is **NOT** supported with this option. If IsModel is set to false then Object specified here will be saved as a place file. ___Default:___ false
--- @field IsModel boolean -- If Object is specified then sets to true automatically, unless you set it to false. ___Default:___ false
--- @field NilInstances boolean -- Save instances that aren't Parented (Parented to nil). ___Default:___ false
--- .NilInstancesFixes {[Instance.ClassName] = function} -- * This can cause some Classes to be fixed even though they might not need the fix (better be safe than sorry though). For example, Bones inherit from Attachment if we dont define them in the NilInstancesFixes then this will catch them anyways. **TO AVOID THIS BEHAVIOR USE THIS EXAMPLE:** {ClassName_That_Doesnt_Need_Fix = false}. ___Default:___ {Animator = function, AdPortal = function, BaseWrap = function, Attachment = function}
--- @field IgnoreDefaultProperties boolean -- Ignores default properties during saving.  ___Default:___ true
--- @field IgnoreNotArchivable boolean -- Ignores the Archivable property and saves Non-Archivable instances. ___Default:___ true
--- @field IgnorePropertiesOfNotScriptsOnScriptsMode boolean -- Ignores property of every instance that is not a script in "scripts" mode. ___Default:___ false
--- @field IgnoreSpecialProperties boolean -- Prevents calls to `gethiddenproperty` and uses fallback methods instead. This also helps with crashes. If your file is corrupted after saving, you can try turning this on. ___Default:___ false
--- @field IsolateStarterPlayer boolean -- Saves StarterPlayer as separate folder, children of the original instance will be ignored. ___Default:___ false
--- @field IsolatePlayers boolean -- Saves All Players as separate folder, children of the original instance will be ignored. ___Default:___ false
--- @field IsolateLocalPlayer boolean -- Saves LocalPlayer as separate folder, original instance will be ignored. ___Default:___ false
--- @field IsolateLocalPlayerCharacter boolean -- Saves LocalPlayer.Character as separate folder, original instance will be ignored. ___Default:___ false
--- @field SavePlayerCharacters boolean -- Ignore player characters while saving. ___Default:___ false
--- @field SaveNotCreatable boolean -- * Includes non-serializable instances as Folder objects (Name is misleading as this is mostly a fix for certain NilInstances and isn't always related to NotCreatable). Other options also enable it, like: IsolatePlayers, IsolateLocalPlayer, etc. ___Default:___ false
--- .NotCreatableFixes table<Instance.ClassName> -- * {"Player"} is the same as {Player = "Folder"}; Format like {SpawnLocation = "Part"} is only to be used when SpawnLocation inherits from "Part" AND "Part" is Creatable. ___Default:___ { "", "Player", "PlayerScripts", "PlayerGui", "TouchTransmitter" }
--- @field AlternativeWritefile boolean -- * Splits file content string into segments and writes them using appendfile. This might help with crashes when it starts writing to file. Though there is a risk of appendfile working incorrectly on some executors. ___Default:___ true
--- @field IgnoreDefaultPlayerScripts boolean -- * **RISKY**: Ignores Default PlayerScripts like PlayerModule & RbxCharacterSounds. Prevents crashes on certain Executors. ___Default:___ true
--- @field IgnoreSharedStrings boolean -- * **RISKY**: Might help with crashes on some executors. ___Default:___ false
--- @field SharedStringOverwrite boolean -- * **RISKY:** if the process is not finished aka crashed then none of the affected values will be available. SharedStrings can also be used for ValueTypes that aren't `SharedString`, this behavior is not documented anywhere but makes sense (Could create issues though, due to _potential_ ValueType mix-up, only works on certain types which are all base64 encoded so far). Reason: Allows for potential smaller file size (can also be bigger in some cases). ___Default:___ false
--- @field TreatUnionsAsParts boolean -- * **RISKY:** Converts all UnionOperations to Parts. Useful if your Executor isn't able to save (read) Unions, because otherwise they will be invisible. ___Default:___ false (except Solara)

--- @interface OptionsAliases
--- @within SynSaveInstance
--- Alias → Canonical option mapping for the [SynSaveInstance.CustomOptions] table.
--- Format: { Alias = CanonicalOption }
--- These are resolved before user options are processed and cannot be modified at runtime.
--- @field timeout string -- DecompileTimeout
--- @field DecompileScripts string -- Decompile
--- @field FileName string -- FilePath
--- @field IgnoreArchivable string -- IgnoreNotArchivable
--- @field IgnoreDefaultProps string -- IgnoreDefaultProperties
--- @field InstancesBlacklist string -- IgnoreList
--- @field SaveLocalPlayer string -- IsolateLocalPlayer
--- @field IsolatePlayerGui string -- IsolateLocalPlayer
--- @field SavePlayerGui string -- IsolateLocalPlayer
--- @field SavePlayers string -- IsolatePlayers
--- @field SaveNonCreatable string -- SaveNotCreatable
--- @field SaveNilInstances string -- NilInstances
--- @field SaveCharacters string -- SavePlayerCharacters
--- @field StatusText string -- ShowStatus

--- @interface OptionsAliasesInverse
--- @within SynSaveInstance
--- Alias → Canonical option mapping with boolean inversion.
--- Format: { Alias = CanonicalOption }
--- These aliases invert the provided boolean value before applying it.
--- Example: noscripts = true → Decompile = false
--- @field noscripts string -- Decompile
--- @field RemovePlayers string -- IsolatePlayers
--- @field RemovePlayerCharacters string -- SavePlayerCharacters

--[=[
	@function saveinstance
	Saves instances with specified options. Example:
	```lua
	local Params = {
		RepoURL = "https://raw.githubusercontent.com/luau/UniversalSynSaveInstance/main/",
		SSI = "saveinstance",
	}

	local synsaveinstance = loadstring(game:HttpGet(Params.RepoURL .. Params.SSI .. ".luau", true), Params.SSI)()

	local CustomOptions = { SafeMode = false, Decompile = true, SaveBytecode = true }

	synsaveinstance(CustomOptions)
	```
	@within SynSaveInstance
	@yields
	@param Parameter_1 variant<table, table<Instance>> -- Can either be [SynSaveInstance.CustomOptions table] or a filled with instances ({Instance}), (then it will be treated as ExtraInstances with an invalid mode and IsModel will be true).
	@param Parameter_2 table -- [OPTIONAL] If present, then Parameter_2 will be assumed to be [SynSaveInstance.CustomOptions table]. And then if the Parameter_1 is an Instance, then it will be assumed to be [SynSaveInstance.CustomOptions table].Object. If Parameter_1 is a table filled with instances ({Instance}), then it will be assumed to be [SynSaveInstance.CustomOptions table].ExtraInstances and IsModel will be true). This exists for sake compatibility with `saveinstance(game, {})`
]=]

local function synsaveinstance(CustomOptions, CustomOptions2)
	if GLOBAL_ENV.USSI then
		error("UniversalSynSaveInstance is already running", 0)
	end
	GLOBAL_ENV.USSI = true
	-- do -- ? Causes issues on SirHurt (Kick lacking Capability "Consequences"), let threads operate on their default/preferred identity set by the developers
	-- 	local setthreadidentity = global_container.setthreadidentity
	-- 	if setthreadidentity then
	-- 		pcall(setthreadidentity, 8) -- ? Arceus X Fix
	-- 	end
	-- end

	local totalsize, chunks = 0, table.create(1)
	local savebuffer, savebuffer_size = {}, 1
	local header =
		'<!-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw --><roblox version="4">'

	local StatusText

	local OPTIONS = {
		mode = "optimized",
		Decompile = true,
		scriptcache = true,
		-- decomptype = "",
		DecompileTimeout = 10,
		BytecodeTimeout = 3,
		-- * New:
		__DEBUG_MODE = false,

		-- Binary = false, -- true in syn newer versions (false in our case because no binary support yet), Description: Saves everything in Binary Mode (rbxl/rbxm).
		Callback = false,
		--Clipboard/CopyToClipboard = false, -- Description: If set to true, the serialized data will be set to the clipboard, which can be later pasted into studio easily. Useful for saving models. (Binary Only)
		-- DisableCompression = false, --Description: Disables compression in the binary output

		DecompileJobless = false,
		DecompileIgnore = {
			-- "Chat",
			"TextChatService",
			ModuleScript = nil,
		},
		IgnoreDefaultPlayerScripts = true,
		SaveBytecode = true,

		IgnoreProperties = {},

		IgnoreList = { "CoreGui", "CorePackages", Packages = false },

		ExtraInstances = {},
		NilInstances = false,
		NilInstancesFixes = {},

		SaveCacheInterval = 0x1600 * 10,
		ShowStatus = true,
		KillAllScripts = false,
		SafeMode = false,
		BoostFPS = false,
		ShutdownWhenDone = false,
		AntiIdle = false,
		Anonymous = false,
		ReadMe = true,
		FilePath = false,
		AvoidFileOverwrite = true,
		Object = false,
		IsModel = false,

		IgnoreDefaultProperties = true,
		IgnoreNotArchivable = true,
		IgnorePropertiesOfNotScriptsOnScriptsMode = false,
		IgnoreSpecialProperties = arrayToDict({ "Fluxus", "Delta", "Solara" })[EXECUTOR_NAME] or false, -- ! Please submit more Executors that crash on gethiddenproperty (with this disabled basically)

		IsolateLocalPlayer = false, --  #service.StarterGui:GetChildren() == 0
		IsolateLocalPlayerCharacter = false,
		IsolatePlayers = false,
		IsolateStarterPlayer = false,
		SavePlayerCharacters = false,

		SaveNotCreatable = false,
		NotCreatableFixes = {
			-- "InputObject",
			-- "LodDataEntity",
			-- "Path",
			"", -- * FilteredSelection
			"AdvancedDragger",
			"AnimationTrack",
			-- "Breakpoint",
			-- "DebuggerWatch",
			"Dragger",
			"Player",
			"PlayerGui",
			"PlayerMouse",
			"PlayerMouse",
			"PlayerScripts",
			"ScreenshotHud",
			"StudioData",
			"TextChatMessage",
			"TextSource",
			"TouchTransmitter",
			"Translator",
			CloudLocalizationTable = "LocalizationTable",
			Platform = "Part",
			Status = "Model", -- gets created by studio automatically usually so there will be duplicates due to this
			-- CoreScript = "Script", -- useless
			-- ChatWindowMessageProperties = "TextChatMessageProperties", -- ? Not needed as this can be derived with ChatWindowConfiguration.DeriveNewMessageProperties
		},

		-- ! Risky

		IgnoreSharedStrings = false,
		SharedStringOverwrite = false,
		TreatUnionsAsParts = false,
		AlternativeWritefile = not arrayToDict({ "WRD", "Xeno", "Zorara" })[EXECUTOR_NAME],

		OptionsAliases = { -- You can't really modify these as a user (because they're read before user's Options are loaded)
			timeout = "DecompileTimeout",
			DecompileScripts = "Decompile",
			FileName = "FilePath",
			IgnoreArchivable = "IgnoreNotArchivable",
			IgnoreDefaultProps = "IgnoreDefaultProperties",
			InstancesBlacklist = "IgnoreList",
			SaveLocalPlayer = "IsolateLocalPlayer",
			IsolatePlayerGui = "IsolateLocalPlayer",
			SavePlayerGui = "IsolateLocalPlayer",
			SaveNonCreatable = "SaveNotCreatable",
			SaveNilInstances = "NilInstances",
			SavePlayers = "IsolatePlayers",
			SaveCharacters = "SavePlayerCharacters",
			StatusText = "ShowStatus",
		},
		OptionsAliasesInverse = {
			noscripts = "Decompile",
			RemovePlayers = "IsolatePlayers",
			RemovePlayerCharacters = "SavePlayerCharacters",
		},
	}
	local OPTIONS_lowercase, OptionsAliasesInverse_lowercase, CustomOptions_valid = {}, {}, {}

	do
		local function buildMap(dest, source, warnLabel)
			for k, v in source do
				local key = string.lower(k)

				if dest[key] then
					warn("DUPLICATE " .. warnLabel, k)
				else
					dest[key] = v
				end
			end
		end

		-- base options
		for o in OPTIONS do
			local option = string.lower(o)
			if OPTIONS_lowercase[option] then
				warn("DUPLICATE OPTION", o)
			else
				OPTIONS_lowercase[option] = o
			end
		end

		-- aliases
		buildMap(OPTIONS_lowercase, OPTIONS.OptionsAliases, "ALIAS")

		-- inverse aliases
		buildMap(OptionsAliasesInverse_lowercase, OPTIONS.OptionsAliasesInverse, "INVERSE ALIAS")
	end

	do -- * Load Settings
		local function makeNilinstanceFix(Name, ClassName, Separate)
			return function(instance, instancePropertyOverrides)
				local Exists

				if not Separate then
					Exists = OPTIONS.NilInstancesFixes[Name]
				end

				local Fix

				local DoesntExist = not Exists
				if DoesntExist then
					Fix = Instance.new(ClassName)
					if not Separate then
						OPTIONS.NilInstancesFixes[Name] = Fix
					end
					-- Fix.Name = Name

					instancePropertyOverrides[Fix] =
						{ __SaveSpecific = true, __Children = { instance }, Properties = { Name = Name } }
				else
					Fix = Exists
					table.insert(instancePropertyOverrides[Fix].__Children, instance)
				end

				-- InstancesOverrides[instance].Parent = AnimationController
				if DoesntExist then
					return Fix
				end
			end
		end

		-- TODO: Merge BaseWrap & Attachment & AdPortal fix (put all under MeshPart container)
		-- TODO?:
		-- DebuggerWatch DebuggerWatch must be a child of ScriptDebugger
		-- PluginAction Parent of PluginAction must be Plugin or PluginMenu that created it!
		OPTIONS.NilInstancesFixes.Animator =
			makeNilinstanceFix("Animator has to be placed under Humanoid or AnimationController", "AnimationController")
		OPTIONS.NilInstancesFixes.AdPortal = makeNilinstanceFix("AdPortal must be parented to a Part", "Part")
		OPTIONS.NilInstancesFixes.Attachment =
			makeNilinstanceFix("Attachments must be parented to a BasePart or another Attachment", "Part") -- * Bones inherit from Attachments
		OPTIONS.NilInstancesFixes.BaseWrap = makeNilinstanceFix("BaseWrap must be parented to a MeshPart", "MeshPart")
		OPTIONS.NilInstancesFixes.PackageLink = makeNilinstanceFix("Package already has a PackageLink", "Folder", true)

		if CustomOptions2 and type(CustomOptions2) == "table" then
			local tmp = CustomOptions
			local Type = typeof(tmp)
			CustomOptions = CustomOptions2
			if Type == "Instance" then
				CustomOptions.Object = tmp
			elseif Type == "table" and typeof(tmp[1]) == "Instance" then
				CustomOptions.ExtraInstances = tmp
				OPTIONS.IsModel = true
			end
		end

		local Type = typeof(CustomOptions)

		if Type == "table" then
			if typeof(CustomOptions[1]) == "Instance" then
				OPTIONS.mode = "invalidmode"
				OPTIONS.ExtraInstances = CustomOptions
				OPTIONS.IsModel = true
				CustomOptions = {}
			else
				for key, value in CustomOptions do
					local k = string.lower(key)

					local option = OPTIONS_lowercase[k]
					local invert = false

					if not option then
						option = OptionsAliasesInverse_lowercase[k]
						invert = option ~= nil
					end

					if option then
						local finalValue
						if invert then
							finalValue = not value
						else
							finalValue = value
						end

						OPTIONS[option] = finalValue
						CustomOptions_valid[option] = true
					end
				end
			end
		elseif Type == "Instance" then
			OPTIONS.mode = "invalidmode"
			OPTIONS.Object = CustomOptions
			CustomOptions = {}
		else
			CustomOptions = {}
		end
	end

	-- Dex++ custom safety policy: exporting must never simulate a kick, kill
	-- running game threads, disable 3D rendering, or shut down the client.
	OPTIONS.SafeMode = false
	OPTIONS.KillAllScripts = false
	OPTIONS.BoostFPS = false
	OPTIONS.ShutdownWhenDone = false
	OPTIONS.AntiIdle = false
	OPTIONS.ReadMe = false

	if not writefile and not OPTIONS.Callback then
		-- appendfile could be used a fallback but what kind of exec has appendfile without writefile
		local function coreCall(method, ...)
			local StarterGui = service.StarterGui
			method = StarterGui[method]
			if not method then
				return
			end

			for _ = 1, 10 do -- maxtries
				local success, result = pcall(method, StarterGui, ...)
				if success then
					return result
				end
				task.wait(1)
			end
		end

		local text = 'Function "writefile" is NOT available\nUse the Option "Callback" instead for now (check docs)'

		coreCall("SetCore", "SendNotification", {
			Title = "SAVEINSTANCE ERROR",
			Text = text,
			Duration = 15,
			Icon = "rbxassetid://9072920609",
		})
		coreCall("SetCore", "SendNotification", {
			Title = "SAVEINSTANCE ERROR",
			Text = "Please ask your executor's developers to add writefile",
			Duration = 15,
			Icon = "rbxassetid://9072920609",
		})

		warn(text)

		GLOBAL_ENV.USSI = nil
		error(text, 0)
	end

	if OPTIONS.IgnoreDefaultPlayerScripts then
		-- TODO This is a bad workaround, find a better automatic way
		-- TODO Look into https://robloxapi.github.io/ref/class/LuaSourceContainer.html#member-isPlayerScript
		local DecompileIgnore = OPTIONS.DecompileIgnore

		local default_scripts = arrayToDict({
			ModuleScript = { "PlayerModule" },
			LocalScript = {
				"BubbleChat",
				"ChatScript",
				"PlayerScriptsLoader",
				"RbxCharacterSounds",
			},
		}, true)

		local function ignorePath(path)
			if path then
				for _, child in path:GetChildren() do
					local class_match = default_scripts[child.ClassName]
					if class_match then
						local name_match = class_match[child.Name]
						if name_match then
							table.insert(DecompileIgnore, child)
						end
					end
				end
			end
		end

		ignorePath(service.StarterPlayer)

		local LocalPlayer = service.Players.LocalPlayer
		if LocalPlayer then
			ignorePath(LocalPlayer:FindFirstChildOfClass("PlayerScripts"))
		end
	end

	local InstancesOverrides = setmetatable({}, { __mode = "ks" })

	local DecompileIgnore, IgnoreList, IgnoreProperties, NotCreatableFixes =
		arrayToDict(OPTIONS.DecompileIgnore, true),
		arrayToDict(OPTIONS.IgnoreList, true),
		arrayToDict(OPTIONS.IgnoreProperties),
		arrayToDict(OPTIONS.NotCreatableFixes, true, "Folder")

	local __DEBUG_MODE = OPTIONS.__DEBUG_MODE

	if __DEBUG_MODE and type(__DEBUG_MODE) ~= "function" then
		__DEBUG_MODE = warn
	end

	local LP_UserId, LP_Name, ANON_UserId, ANON_Name, AnonymizableTypes

	do
		local anonymous = OPTIONS.Anonymous
		local lp = service.Players.LocalPlayer

		if anonymous and lp then
			AnonymizableTypes = arrayToDict({ "double", "float", "int", "int64", "string" })
			LP_UserId, LP_Name = lp.UserId, lp.Name

			local istable = type(anonymous) == "table"
			ANON_UserId = istable and anonymous.UserId or 1
			ANON_Name = istable and anonymous.Name or "Roblox"
		end
	end

	local FilePath = OPTIONS.FilePath
	local SaveCacheInterval = OPTIONS.SaveCacheInterval
	local ToSaveInstance = OPTIONS.Object
	local IsModel = OPTIONS.IsModel

	if ToSaveInstance and CustomOptions.IsModel == nil then
		IsModel = true
	end

	local IgnoreDefaultProperties = OPTIONS.IgnoreDefaultProperties
	local IgnoreNotArchivable = not OPTIONS.IgnoreNotArchivable
	local IgnorePropertiesOfNotScriptsOnScriptsMode = OPTIONS.IgnorePropertiesOfNotScriptsOnScriptsMode

	local old_gethiddenproperty
	if OPTIONS and gethiddenproperty then
		old_gethiddenproperty = gethiddenproperty
		gethiddenproperty = nil
	end

	local SaveNotCreatable = OPTIONS.SaveNotCreatable
	local TreatUnionsAsParts = OPTIONS.TreatUnionsAsParts

	local DecompileJobless = OPTIONS.DecompileJobless
	if DecompileJobless then
		OPTIONS.scriptcache = true
	end
	local ScriptCache = OPTIONS.scriptcache and getscriptbytecode

	local IgnoreSharedStrings = OPTIONS.IgnoreSharedStrings
	local SharedStringOverwrite = OPTIONS.SharedStringOverwrite

	local ldeccache = GLOBAL_ENV.USSI_scriptcache

	local DecompileIgnoring, ToSaveList, ldecompile, placename, elapse_t, SaveNotCreatableWillBeEnabled, RecoveredScripts

	if OPTIONS.ReadMe then
		RecoveredScripts = {}
	end

	if ScriptCache and not ldeccache then
		ldeccache = {}
		GLOBAL_ENV.USSI_scriptcache = ldeccache
	end

	if ToSaveInstance == game then
		OPTIONS.mode = "full"
		ToSaveInstance = nil
		IsModel = nil
	end

	local function isLuaSourceContainer(instance)
		return instance:IsA("LuaSourceContainer")
	end

	do
		local mode = string.lower(OPTIONS.mode)
		local tmp = table.clone(OPTIONS.ExtraInstances)

		local PlaceName = game.PlaceId

		pcall(function()
			PlaceName ..= " " .. service.MarketplaceService:GetProductInfoAsync(PlaceName).Name
		end)

		local function sanitizeFileName(str)
			return string.sub(string.gsub(string.gsub(string.gsub(str, "[^%w _]", ""), " +", " "), " +$", ""), 1, 240)
		end

		if ToSaveInstance then
			if mode == "optimized" then -- ! NOT supported with Model file mode
				mode = "full"
			end

			for _, key in
				{
					"IsolateLocalPlayer",
					"IsolateLocalPlayerCharacter",
					"IsolatePlayers",
					"IsolateStarterPlayer",
					"NilInstances",
				}
			do
				if CustomOptions_valid[key] == nil then
					OPTIONS[key] = false
				end
			end
		end

		local filetype = IsModel and ".rbxmx" or ".rbxlx"

		if FilePath then
			local hasExtension = string.match(FilePath, "%.[^/\\]+$") ~= nil
			placename = hasExtension and FilePath or (FilePath .. filetype)
		elseif IsModel then
			placename =
				sanitizeFileName("model " .. PlaceName .. " " .. (ToSaveInstance or tmp[1] or game):GetFullName())
		else
			placename = sanitizeFileName("place " .. PlaceName)
		end

		if FilePath then
		elseif OPTIONS.AvoidFileOverwrite and isfile then
			local counter = 0
			local temp = placename

			while isfile(temp .. filetype) do
				counter += 1
				temp = placename .. "(" .. counter .. ")"
			end

			placename = temp .. filetype
		else
			placename = placename .. filetype
		end

		if GLOBAL_ENV[placename] then -- ? AvoidFileOverwrite kinda messes with this, but shouldn't be an issue
			error("UniversalSynSaveInstance is already saving to this file: " .. placename, 0)
		end

		GLOBAL_ENV[placename] = true
		GLOBAL_ENV.USSI = nil

		if mode ~= "scripts" then
			IgnorePropertiesOfNotScriptsOnScriptsMode = nil
		end

		local TempRoot = ToSaveInstance or game

		if mode == "full" then
			if not ToSaveInstance then
				local Children = TempRoot:GetChildren()
				if 0 < #Children then
					local tmp_dict = arrayToDict(tmp)
					for _, child in Children do
						if not tmp_dict[child] then
							table.insert(tmp, child)
						end
					end
				end
			end
		elseif mode == "optimized" then -- ! Incompatible with .rbxmx (Model file) mode
			-- if IsolatePlayers then
			-- 	table.insert(_list_0, "Players")
			-- end
			local tmp_dict = arrayToDict(tmp)

			for _, serviceName in
				{
					"Workspace",
					"Players",
					"Lighting",
					"MaterialService",
					"ReplicatedFirst",
					"ReplicatedStorage",

					"ServerScriptService", -- LoadStringEnabled property (doesn't replicate); Just in case
					"ServerStorage", -- Just in case

					"StarterGui",
					"StarterPack",
					"StarterPlayer",
					"Teams",
					"SoundService",
					"Chat",
					"TextChatService",

					"LocalizationService", -- For LocalizationTables
					-- "InsertService",
					"JointsService",

					-- "TestService",
					-- "VoiceChatService",
				}
			do
				local _service = game:FindService(serviceName)
				if _service and not tmp_dict[_service] then
					table.insert(tmp, _service)
				end
			end
		elseif mode == "scripts" then
			-- TODO: Only save paths that lead to scripts (nothing else)
			-- Currently saves paths along with children of each tree
			local unique = {}
			for _, instance in TempRoot:GetDescendants() do
				if isLuaSourceContainer(instance) then
					local Parent = instance.Parent
					while Parent and Parent ~= TempRoot do
						instance = instance.Parent
						Parent = instance.Parent
					end
					if Parent then
						unique[instance] = true
					end
				end
			end
			for instance in unique do
				table.insert(tmp, instance)
			end
		end

		ToSaveList = tmp

		if ToSaveInstance then
			table.insert(ToSaveList, 1, ToSaveInstance)
		end
	end

	local IsolateLocalPlayer = OPTIONS.IsolateLocalPlayer
	local IsolateLocalPlayerCharacter = OPTIONS.IsolateLocalPlayerCharacter
	local IsolatePlayers = OPTIONS.IsolatePlayers
	local IsolateStarterPlayer = OPTIONS.IsolateStarterPlayer
	local NilInstances = OPTIONS.NilInstances

	if NilInstances and enablenilinstances then -- ? Solara fix
		pcall(enablenilinstances)
	end
	local function get_size_format()
		local Size

		for i, unit in
			{
				"B",
				"KB",
				"MB",
				"GB",
				"TB",
			}
		do
			if totalsize < 0x400 ^ i then
				Size = math.floor(totalsize / (0x400 ^ (i - 1)) * 10) / 10 .. " " .. unit
				break
			end
		end

		return Size
	end

	local RunService = service.RunService
	local function wait_for_render()
		RunService.RenderStepped:Wait()
	end

	local LoadingText, LoadingThread, IsLoading = nil, nil, false

	local function ensureSpinner()
		if LoadingThread then
			return
		end
		LoadingThread = task.spawn(function()
			local chars = { "|", "/", "—", "\\" }
			local i = 0
			while true do
				while not IsLoading do
					task.wait()
				end

				while IsLoading do
					i = i % #chars + 1
					if StatusText and LoadingText then
						StatusText.Text = LoadingText .. " " .. chars[i]
					end
					task.wait(0.25)
				end
			end
		end)
	end

	local function run_with_loading(text, keepStatus, waitForRender, taskFunction, ...)
		local previousStatus
		if StatusText then
			if keepStatus then
				previousStatus = StatusText.Text
			end
			LoadingText = text
			IsLoading = true
			ensureSpinner()
			if waitForRender then
				wait_for_render()
			end
		end

		local result = { taskFunction(...) }

		if StatusText then
			IsLoading = false
			if previousStatus then
				StatusText.Text = previousStatus
			end
		end
		return unpack(result)
	end

	local function makeTimeoutHandler(timeout, f, timeout_return)
		if timeout < 0 then
			return function(...)
				return pcall(f, ...)
			end
		end

		local worker
		local pendingJob

		local function spawnWorker()
			return task.spawn(function()
				while true do
					while not pendingJob do
						task.wait()
					end

					local job = pendingJob
					pendingJob = nil

					local ok, result = pcall(f, unpack(job.args))

					if job.isCancelled then
						return -- this worker is retired
					end

					task.cancel(job.timeoutThread)

					local thread = job.thread
					while coroutine.status(thread) ~= "suspended" do
						task.wait()
					end

					coroutine.resume(thread, ok, result)
				end
			end)
		end

		return function(...)
			local thread = coroutine.running()
			local job = {
				thread = thread,
				args = { ... },
			}

			job.timeoutThread = task.delay(timeout, function()
				job.isCancelled = true
				worker = nil -- retire this worker; a fresh one spawns for the next call
				coroutine.resume(thread, nil, timeout_return)
			end)

			if not worker then
				worker = spawnWorker()
			end
			pendingJob = job

			return coroutine.yield()
		end
	end

	local getbytecode
	if getscriptbytecode then
		getbytecode = makeTimeoutHandler(OPTIONS.BytecodeTimeout, getscriptbytecode) -- ? Solara fix
	end

	local SaveBytecode
	if OPTIONS.SaveBytecode and getscriptbytecode then
		SaveBytecode = function(script)
			local s, bytecode = getbytecode(script)

			if s and bytecode and bytecode ~= "" then
				return "-- Bytecode (Base64):\n-- " .. base64encode(bytecode) .. "\n\n"
			end
		end
	end

	local function decompilerOutputFailed(result)
		if type(result) ~= "string" or not string.find(result, "%S") then return true end
		local prefix = string.lower(string.sub(result, 1, 512))
		return string.find(prefix, "failed to decompile", 1, true) ~= nil
			or string.find(prefix, "decompilation failed", 1, true) ~= nil
			or string.find(prefix, "unable to decompile", 1, true) ~= nil
			or string.find(prefix, "decompiler error", 1, true) ~= nil
	end

	local function adaptiveDecompiler(script)
		local failures = {}
		local function tryTarget(target, label)
			local ok, result, detail = pcall(decompile, target)
			if ok and not decompilerOutputFailed(result) then return result end
			local reason = ok and (detail or result or "empty output") or result
			table.insert(failures, label .. ": " .. string.sub(tostring(reason), 1, 240))
		end

		local source = tryTarget(script, "script attempt 1")
		if source then return source end
		task.wait()
		source = tryTarget(script, "script attempt 2")
		if source then return source end

		if getscriptbytecode then
			local ok, bytecode = pcall(getscriptbytecode, script)
			if ok and type(bytecode) == "string" and bytecode ~= "" then
				source = tryTarget(bytecode, "bytecode fallback")
				if source then return source end
			else
				table.insert(failures, "bytecode read: " .. string.sub(tostring(bytecode or "empty output"), 1, 240))
			end
		end

		error("Native decompiler failed. " .. table.concat(failures, " | "), 0)
	end

	do
		if not OPTIONS.Decompile then
			ldecompile = function()
				return "-- Decompiling is disabled"
			end
		elseif decompile then
			local decomp = makeTimeoutHandler(OPTIONS.DecompileTimeout, adaptiveDecompiler, "Decompiler timed out")

			ldecompile = function(script)
				-- local name = scr.ClassName .. scr.Name
				local bytecode
				if ScriptCache then
					local s
					s, bytecode = getbytecode(script)
					local cached

					if s then
						if not bytecode or bytecode == "" then
							return "-- The Script is Empty"
						end
						cached = ldeccache[bytecode]
					else
						bytecode = nil
					end

					if cached then
						if __DEBUG_MODE then
							__DEBUG_MODE("Found in Cache", script:GetFullName())
						end
						return cached
					end
				else
					if DecompileJobless then
						return "-- Not found in already decompiled ScriptCache"
					end

					-- task.wait() -- TODO Maybe remove?
				end

				local ok, result = run_with_loading("Decompiling " .. script.Name, true, nil, decomp, script)
				if not result then
					ok, result = false, "Empty Output"
				end

				local output
				if ok then
					result = string.gsub(result, "\0", "\\0") -- ? Some decompilers sadly output \0 which prevents files from opening
					output = result
				else
					output = "--[[ Failed to decompile. Reason:\n" .. (result or "") .. "\n]]"
				end

				if ScriptCache and bytecode then -- TODO there might(?) be an edgecase where it manages to decompile (built-in) even though getscriptbytecode failed, and the output won't get cached
					ldeccache[bytecode] = output -- ? Should we cache even if it timed out?
					if __DEBUG_MODE then
						__DEBUG_MODE("Cached", script:GetFullName())
					end
				end

				return output
			end
		else
			ldecompile = function()
				return "-- Your Executor does NOT have a Decompiler"
			end
		end
	end

	local function GetLocalPlayer()
		return service.Players.LocalPlayer
			or service.Players:GetPropertyChangedSignal("LocalPlayer"):Wait()
			or service.Players.LocalPlayer
	end

	local function filterLinkedSource(str)
		local o, r = pcall(service.HttpService.JSONDecode, service.HttpService, str)
		if o and r.errors then
			return
		end
		return true
	end

	local function replaceClassName(instance, InstanceName, ClassName)
		local InstanceOverride
		if InstanceName ~= ClassName then -- TODO Compare against default instance instead (TouchTransmitter is called TouchInterest by default)
			InstanceOverride = InstancesOverrides[instance]
			if not InstanceOverride then
				InstanceOverride = { Properties = { Name = "[" .. ClassName .. "] " .. InstanceName } }
				InstancesOverrides[instance] = InstanceOverride
			end
		end
		return InstanceOverride
	end

	local function gsubCaseInsensitive(input, search, replacement)
		local inputLower = string.lower(input)
		search = string.lower(search)

		if not string_find(input, search) then
			return input
		end

		local lastFinish = 0
		local subStrings = {}
		local search_len = #search
		local input_len = #input
		while search_len <= input_len - lastFinish do
			local init = lastFinish + 1

			local start, finish = string_find(inputLower, search, init)

			if start == nil then
				break
			end

			table.insert(subStrings, string.sub(input, init, start - 1))

			lastFinish = finish
		end

		if lastFinish == 0 then
			return input
		end

		table.insert(subStrings, string.sub(input, lastFinish + 1))

		return table.concat(subStrings, replacement)
	end

	local function filterPropVal(result, propertyName, category) -- ? raw == nil thanks to SerializedDefaultAttributes; "can't get value" - due to WriteOnly tag;  "Invalid value for enum " - "StreamingPauseMode" (old games probably) Roexec
		return result == nil
			or result == "can't get value"
			or type(result) == "string"
				and (category == "Enum" or string_find(result, "Unable to get property " .. propertyName))
	end

	local function ReadProperty(instance, property, propertyName, special, category, optional)
		local raw = __BREAK

		local InstanceOverride = InstancesOverrides[instance]
		if InstanceOverride then
			local PropertiesOverride = InstanceOverride.Properties
			if PropertiesOverride then
				local PropertyOverride = PropertiesOverride[propertyName]
				if PropertyOverride ~= nil then
					return PropertyOverride
				end
			end
		end

		local CanRead = property.CanRead

		if CanRead == false then -- * Skips because we've checked this property before
			return __BREAK
		end

		if special then
			if gethiddenproperty then
				local ok, result = pcall(gethiddenproperty, instance, propertyName)

				if ok then
					raw = result
				end

				if filterPropVal(raw, propertyName, category) then
					-- * Skip next time we encounter this too perhaps (unless there's a chance for it to be readable on other instance, somehow)

					if result ~= nil or not optional then
						if __DEBUG_MODE then
							__DEBUG_MODE("Filtered", propertyName)
						end
						-- Property.Special = false
						property.CanRead = false
					end

					return __BREAK -- ? We skip it because even if we use "" it will just reset to default in most cases, unless it's a string tag for example (same as not being defined)
				end
			end
		else
			if CanRead then
				raw = instance[propertyName]
			else -- Assuming CanRead == nil (untested)
				local ok, result = pcall(index, instance, propertyName)

				if ok then
					raw = result
				elseif gethiddenproperty then -- ! Be careful with this 'and gethiddenproperty' logic
					ok, result = pcall(gethiddenproperty, instance, propertyName)

					if ok then
						raw = result

						property.Special = true
					end
				end

				property.CanRead = ok

				if not ok or filterPropVal(raw, propertyName, category) then
					return __BREAK
				end
			end
		end

		return raw
	end

	local function ReturnItem(className, instance)
		return '<Item class="' .. className .. '" referent="' .. getRef(instance) .. '"><Properties>' -- TODO: Ideally this shouldn't return <Properties> as well as the line below to close it IF  IgnorePropertiesOfNotScriptsOnScriptsMode is Enabled OR If all properties are default (reduces file size by at least 1.4%)
	end

	local function ReturnProperty(tag, propertyName, value)
		return "<" .. tag .. ' name="' .. propertyName .. '">' .. value .. "</" .. tag .. ">"
	end

	local function ReturnValueAndTag(raw, valueType, encoder)
		local value, tag = (encoder or XML_Encoders[valueType])(raw)

		return value, tag or valueType
	end

	local function InheritsFix(fixes, className, instance)
		local Fix = fixes[className]
		if Fix then
			return Fix
		elseif Fix == nil then
			for class_name, fix in fixes do
				if instance:IsA(class_name) then
					return fix
				end
			end
		end
	end

	local function GetInheritedProps(className)
		local cached = inheritedProperties[className]
		if cached then
			return cached
		end

		local prop_list = {}
		local layer = ClassList[className]
		while layer do
			local layer_props = layer.Properties
			table.move(layer_props, 1, #layer_props, #prop_list + 1, prop_list)

			-- for _, prop in layer.Properties do
			-- 	prop_list[prop_count] = prop -- ? table.clone is needed for case where .Default is modified
			-- 	prop_count += 1
			-- end

			layer = ClassList[layer.Superclass]
		end
		inheritedProperties[className] = prop_list
		return prop_list
	end

	local function save_cache()
		local savestr = table.concat(savebuffer)

		local savestr_len = #savestr
		totalsize += savestr_len

		-- store chunk as-is (NO concatenation accumulation)
		table.insert(chunks, savestr)

		table.clear(savebuffer)
		savebuffer_size = 1

		if StatusText then
			StatusText.Text = "Saving.. Size: " .. get_size_format()
		end

		wait_for_render() -- ? Needed for at least 1fps (status text)
	end

	local function save_specific(className, properties)
		local Ref = Instance.new(className) -- ! Assuming anything passed here is Creatable
		local Item = ReturnItem(Ref.ClassName, Ref)

		for propertyName, val in properties do
			local whitelisted, value, tag

			-- TODO: Improve all sort of overrides & exceptions in the code (code below is awful)
			if propertyName == "Source" then
				tag = "ProtectedString"
				value = XML_Encoders._protectedString(val)
				whitelisted = true
			elseif propertyName == "Name" then
				whitelisted = true
				value, tag = ReturnValueAndTag(val, "string") -- * Doubt ValueType will change
			end

			if whitelisted then
				Item ..= ReturnProperty(tag, propertyName, value)
			end
		end
		Item ..= "</Properties>"
		return Item
	end

	local function save_hierarchy(hierarchy)
		for _, instance in hierarchy do
			if typeof(instance) ~= "Instance" then
				continue
			end
			local metadataOk, ClassName, InstanceName, IsArchivable = pcall(function()
				return instance.ClassName, instance.Name, instance.Archivable
			end)
			if not metadataOk then
				warn("Dex++: skipped an invalid or destroyed Instance instead of cancelling the export")
				continue
			end
			local InstanceOverride, ClassTagOverride, ClassNameOverride

			if not InstanceOverride then
				InstanceOverride = InstancesOverrides[instance]
				if InstanceOverride then
					ClassTagOverride = InstanceOverride.__ClassName
				end
			end
			local SkipEntirely

			if not ClassTagOverride then -- ! Assuming anything that has __ClassName comes from save_extra
				if IgnoreNotArchivable and not IsArchivable then
					continue
				end

				SkipEntirely = IgnoreList[instance]
				if SkipEntirely then
					continue
				end

				do
					local OnIgnoredList = IgnoreList[ClassName]
					if OnIgnoredList ~= nil then
						if OnIgnoredList == false then
							SkipEntirely = false
						elseif OnIgnoredList == true or OnIgnoredList[InstanceName] then
							continue
						end
					end
				end

				if not DecompileIgnoring then
					DecompileIgnoring = DecompileIgnore[instance]

					if DecompileIgnoring == nil then
						local DecompileIgnored = DecompileIgnore[ClassName]
						if DecompileIgnored then
							DecompileIgnoring = DecompileIgnored == true or DecompileIgnored[InstanceName]
						end
					end

					if DecompileIgnoring then
						DecompileIgnoring = instance
					elseif DecompileIgnoring == false then
						DecompileIgnoring = 1 -- Ignore one instance
					end
				end

				do
					local Fix = NotCreatableFixes[ClassName]

					if Fix then
						if SaveNotCreatable then
							ClassName, InstanceOverride = Fix, replaceClassName(instance, InstanceName, ClassName)
						else
							continue -- They won't show up in Studio anyway (Enable SaveNotCreatable if you wish to bypass this)
						end
					else -- ! Assuming nothing that is a PartOperation or inherits from it is in NotCreatableFixes
						if TreatUnionsAsParts and instance:IsA("PartOperation") then
							ClassName, InstanceOverride = "Part", replaceClassName(instance, InstanceName, ClassName)
							ClassNameOverride = "BasePart" -- * Mutual Superclass for PartOperation and Part; For properties only
						elseif not ClassList[ClassName] then -- ? API Dump is outdated then
							if __DEBUG_MODE then
								__DEBUG_MODE("Class not Found", ClassName)
							end

							ClassTagOverride = ClassName -- ? To at least retain .ClassName unlike the rest of the class-specific properties
							ClassName = "Folder" -- ? replaceClassName is not needed because of the ClassTagOverride
						end
					end
				end
			end
			-- ? The reason we only save .Name (and few other props in save_specific) is because
			-- ? we can be sure this is a custom container (ex. NilInstancesFixes)
			-- ? However, in case of NotCreatableFixes, the Instance might have Tags, Attributes etc. that can potentially be saved (even though it's a Folder)
			if InstanceOverride and InstanceOverride.__SaveSpecific then
				savebuffer[savebuffer_size] = save_specific(ClassName, InstanceOverride.Properties) -- ! Assuming anything that has __SaveSpecific will have .Properties
				savebuffer_size += 1
			else
				-- local Properties =
				savebuffer[savebuffer_size] = ReturnItem(ClassTagOverride or ClassName, instance) -- TODO: Ideally this shouldn't return <Properties> as well as the line below to close it IF  IgnorePropertiesOfNotScriptsOnScriptsMode is ENABLED
				savebuffer_size += 1
				if not (IgnorePropertiesOfNotScriptsOnScriptsMode and not isLuaSourceContainer(instance)) then
					local default_instance, new_def_inst

					if IgnoreDefaultProperties then
						default_instance = defaultInstances[ClassName]
						if not default_instance then
							local Class = ClassList[ClassName]
							if not Class.NotCreatable then -- __api_dump_class_not_creatable__ also indicates this
								-- NotCreatableFixes are exceptions to the check above meaning if we don't keep the NotCreatableFixes updated then Instance.new below might start erroring in the future potentially; HOWEVER IsPropertyModified solves this issue and no updates are really needed as NotCreatableFixes is up-to-date as of VERSION-HERE (which is when IPM gets enabled)
								local ok, result = pcall(Instance.new, ClassName) -- ! pcall is needed for level 3 execs (for example TestService); EXCEPTION NOTED ABOVE (irrelevant)

								if ok then
									new_def_inst = result

									default_instance = {}

									defaultInstances[ClassName] = default_instance
								else
									Class.NotCreatable = true
									if __DEBUG_MODE then
										__DEBUG_MODE("Failed to create default Instance", ClassName, result)
									end
								end
							elseif __DEBUG_MODE then
								__DEBUG_MODE("Unable to create default Instance (NotCreatable)", ClassName)
							end
						end
					end

					for _, Property in GetInheritedProps(ClassNameOverride or ClassName) do
						local PropertyName = Property.Name

						if IgnoreProperties[PropertyName] then
							continue
						end

						local ValueType = Property.ValueType

						if IgnoreSharedStrings and ValueType == "SharedString" then
							continue
						end

						local Special, Category, Optional = Property.Special, Property.Category, Property.Optional
						local raw
						if
							not (
								ValueType == "ProtectedString"
								and PropertyName == "Source"
								and isLuaSourceContainer(instance)
							)
						then
							raw = ReadProperty(instance, Property, PropertyName, Special, Category, Optional)

							if raw == __BREAK then -- ! Assuming __BREAK is always returned when there's a failure to read a property
								local GHPFFailed, Fallback = Property.GHPFFailed, Property.Fallback
								if GHPFFailed and not Fallback then
									continue
								end

								if not GHPFFailed then
									local ok, result = pcall(gethiddenproperty_fallback, instance, PropertyName) -- * This helps in reading: Vector3int16, OptionalCoordinateFrame DataTypes. It also acts as an almost entire fallback for gethiddenproperty in case it is missing
									if result == nil and not Optional then
										ok = nil
									end

									if ok then
										raw = result
									else
										GHPFFailed = true
										Property.GHPFFailed = GHPFFailed
									end
								end

								if GHPFFailed and Fallback then
									local ok, result = pcall(Fallback, instance)

									if ok then
										raw = result
									else
										Property.Fallback = nil -- Low level execs might fail due to lack of some Capabilities
										if __DEBUG_MODE then
											__DEBUG_MODE("Fix Failed", PropertyName, result)
										end
										continue
									end
								end

								if raw == __BREAK then
									continue
								end
							end

							-- Special = Property.Special -- ? Read TODO below (must be updated if it's used frequently afterwards)

							if
								default_instance
								and Property.CanRead
								and not Property.Special -- TODO: .Special is checked more than once (because it might be updated during ReadProperty)
							then -- ? Could be not just "Source" in the future
								if new_def_inst then
									default_instance[PropertyName] = index(new_def_inst, PropertyName)
								end
								if default_instance[PropertyName] == raw then
									continue
								end
							end

							-- if PropertyName == "AttributesSerialize" and raw ~= "" then -- TODO unreleased yet
							-- 	for name, v in instance:GetAttributes() do
							-- 		if typeof(v) == "InstanceHandle" then
							-- 			savebuffer[savebuffer_size] =
							-- 				ReturnProperty("Ref", "__attrRef_" .. name, getRef(v))
							-- 			savebuffer_size += 1
							-- 		end
							-- 	end
							-- end
						end
						-- Serialization start

						if SharedStringOverwrite and ValueType == "BinaryString" then -- TODO: Convert this to table if more types are added
							ValueType = "SharedString"
						end

						if AnonymizableTypes and AnonymizableTypes[ValueType] then
							-- TODO This might cause issues on non-unique Usernames (ex. "Cake" if game is about cakes then everything supposedly related to your name will be replaced with "Roblox"); Certain UserIds might also affect numbers, like if your UserId is 2481848 and there is some number that matches 2481848 then that number will be replaced with 1, potentially making the number incorrect.
							-- TODO So for now it's best to keep this disabled by default

							if ValueType == "string" then
								raw = gsubCaseInsensitive(raw, LP_Name, ANON_Name)
							elseif raw == LP_UserId then
								raw = ANON_UserId
							end
						end

						local tag, value
						if Category == "Class" then
							tag = "Ref"
							if raw then
								if SaveNotCreatableWillBeEnabled then
									local Fix = NotCreatableFixes[raw.ClassName]
									if
										Fix
										and (
											PropertyName == "PlayerToHideFrom"
											or ValueType ~= "Instance" and ValueType ~= Fix
										)
									then -- * To avoid errors
										continue
									end
								end

								value = getRef(raw)
							else
								value = "null"
							end
						elseif Category == "Enum" then -- ! We do this order (Enums before Encoders) specifically because Font Enum might get a Font Encoder despite having Enum Category, unlike Font DataType which that Encoder is meant for
							value, tag = XML_Encoders.EnumItem(raw)
						else
							local encoder = XML_Encoders[ValueType]

							if encoder then
								value, tag = ReturnValueAndTag(raw, ValueType, encoder)
							elseif ValueType == "ProtectedString" then -- TODO: Try fitting this inside Encoders
								tag = ValueType

								if PropertyName == "Source" then
									if DecompileIgnoring then -- ? Should this really prevent extraction of the original source if present ?
										if DecompileIgnoring == 1 then
											DecompileIgnoring = nil
										end
										value = "-- Ignored"
									else
										local should_decompile = true
										local LinkedSource
										local o, LinkedSource_Url = pcall(index, instance, "LinkedSource") -- ! AuroraScript has Source but not LinkedSource
										if not o then
											LinkedSource_Url = ""
										end
										local hasLinkedSource = LinkedSource_Url ~= ""
										local LinkedSource_type
										if hasLinkedSource then
											local Path = instance:GetFullName()
											if RecoveredScripts then
												table.insert(RecoveredScripts, Path)
											end

											LinkedSource = string.match(LinkedSource_Url, "%w+$") -- TODO: No sure if this pattern matches all possible cases. Example is: 'rbxassetid://0&hash=cd73dd2fe5e5013137231c227da3167e'
											if LinkedSource then
												if ScriptCache then
													local cached = ldeccache[LinkedSource]

													if cached then
														value = cached
														should_decompile = nil
													end
												end
												if should_decompile then
													if DecompileJobless then
														value = "-- Not found in LinkedSource ScriptCache"
														should_decompile = nil
													end

													LinkedSource_type = string.find(LinkedSource, "%a") and "hash"
														or "id"

													local asset = LinkedSource_type .. "=" .. LinkedSource

													local ok, source = pcall(function()
														-- Credits @halffalse
														return game:HttpGet(
															"https://assetdelivery.roproxy.com/v1/asset/?" .. asset
														)
													end)

													if ok and filterLinkedSource(source) then
														if ScriptCache then
															ldeccache[LinkedSource] = source
														end

														value = source

														should_decompile = nil
													end
												end
											else --if __DEBUG_MODE then -- * We print this anyway because very important
												warn(
													"FAILED TO EXTRACT ORIGINAL SCRIPT SOURCE (OPEN A GITHUB ISSUE): ",
													instance:GetFullName(),
													LinkedSource_Url
												)
											end
										end

										if should_decompile then
											local isLocalScript = instance:IsA("LocalScript")
											if
												isLocalScript and instance.RunContext == Enum.RunContext.Server
												or not isLocalScript
													and instance:IsA("Script")
													and instance.RunContext ~= Enum.RunContext.Client
											then
												value = "-- [FilteringEnabled] Server Scripts are IMPOSSIBLE to save" -- TODO: Could be not just server scripts in the future
											else
												value = ldecompile(instance)
												if SaveBytecode then
													local output = SaveBytecode(instance)
													if output then
														value = output .. value
													end
												end
											end
										end

										value = "-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw\n\n"
											.. (hasLinkedSource and "-- Original Source: https://assetdelivery.roblox.com/v1/asset/?" .. (LinkedSource_type or "id") .. "=" .. (LinkedSource or LinkedSource_Url) .. "\n\n" or "")
											.. value
									end
								end
								value = XML_Encoders._protectedString(value)
							else
								--OptionalCoordinateFrame and so on, we make it dynamic

								if Optional then
									encoder = XML_Encoders[Optional]

									if encoder then
										if raw == nil then
											-- * It can be empty, because it's optional
											-- ? Though why even save it if it's empty considering it's optional
											continue
										-- value, tag = "", ValueType
										else
											value, tag = ReturnValueAndTag(raw, ValueType, encoder)
										end
									end
								end
							end
						end

						if tag then
							savebuffer[savebuffer_size] = ReturnProperty(tag, PropertyName, value)
							savebuffer_size += 1
						else --if __DEBUG_MODE then -- * We print this anyway because very important
							warn("UNSUPPORTED TYPE (OPEN A GITHUB ISSUE): ", ValueType, ClassName, PropertyName)
						end
					end
				end
				savebuffer[savebuffer_size] = "</Properties>"
				savebuffer_size += 1

				if SaveCacheInterval < savebuffer_size then
					save_cache()
				end
			end

			if SkipEntirely ~= false then -- ? We save instance without it's descendants in this case (== false)
				local Children = InstanceOverride and InstanceOverride.__Children
				if not Children then
					local childrenOk, result = pcall(instance.GetChildren, instance)
					Children = childrenOk and result or {}
					if not childrenOk then
						warn("Dex++: could not enumerate children for " .. tostring(InstanceName) .. "; continuing the export")
					end
				end

				if #Children ~= 0 then
					save_hierarchy(Children)
				end
			end

			if DecompileIgnoring and DecompileIgnoring == instance then
				DecompileIgnoring = nil
			end

			savebuffer[savebuffer_size] = "</Item>"
			savebuffer_size += 1
		end
	end

	local function save_extra(name, instanceOrTable, saveProps, customClassName, source)
		if not customClassName then
			customClassName = "Folder"
		end

		local properties = { Name = name, Source = source }
		local hierarchy

		if instanceOrTable then
			if type(instanceOrTable) == "table" then
				hierarchy = instanceOrTable
			else
				hierarchy = instanceOrTable:GetChildren()
				if saveProps then
					-- IgnoreList[instanceOrTable] = nil
					-- IgnoreNotArchivable = false

					InstancesOverrides[instanceOrTable] = {
						__ClassName = customClassName, -- ! Assuming any class that contains ProtectedString is never passed, because it expects bytecode, not normal code
						-- __Children = hierarchy,
						Properties = properties,
					}

					save_hierarchy({ instanceOrTable })
				end
			end
		end

		if not saveProps then
			savebuffer[savebuffer_size] = save_specific(customClassName, properties)
			savebuffer_size += 1
			if hierarchy then
				save_hierarchy(hierarchy)
			end
			savebuffer[savebuffer_size] = "</Item>"
			savebuffer_size += 1
		end
	end

	local function save_game()
		do
			if IsModel then
				--[[
			-- ? Roblox encodes the following additional attributes. These are not required. Moreover, any defined schemas are ignored, and not required for a file to be valid: xmlns:xmime="http://www.w3.org/2005/05/xmlmime" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:noNamespaceSchemaLocation="http://www.roblox.com/roblox.xsd"
			Also http can be converted to https but not sure if Roblox cares
			-- ? <External>null</External><External>nil</External>  - <External> is a legacy concept that is no longer used.
		]]
				header ..= '<Meta name="ExplicitAutoJoints">true</Meta>'
			end
			if writefile and not OPTIONS.Callback then
				writefile(placename, header) -- TODO This is sort of useless if writefile will be used at the end (like if AlternativeWritefile and Callback are unused)
			end
		end

		-- TODO Find a better solution for this
		SaveNotCreatableWillBeEnabled = SaveNotCreatable
			or (IsolateLocalPlayer or IsolateLocalPlayerCharacter) and IsolateLocalPlayer
			or IsolatePlayers
			or NilInstances and global_container.getnilinstances -- ! Make sure this accurately reflects everything below

		save_hierarchy(ToSaveList)

		if IsolateLocalPlayer or IsolateLocalPlayerCharacter then
			local LocalPlayer = service.Players.LocalPlayer
			if LocalPlayer then
				if IsolateLocalPlayer then
					SaveNotCreatable = true
					save_extra("LocalPlayer", LocalPlayer, true)
				end
				if IsolateLocalPlayerCharacter then
					local LocalPlayerCharacter = LocalPlayer.Character
					if LocalPlayerCharacter then
						save_extra("LocalPlayer Character", LocalPlayerCharacter, true, "Model")
					end
				end
			end
		end

		if IsolateStarterPlayer then
			-- SaveNotCreatable = true -- TODO: Enable if StarterPlayerScripts or StarterCharacterScripts stop showing up in isolated folder in Studio
			save_extra("StarterPlayer", service.StarterPlayer) -- no reason to saveprops as you can see the props on the original instance
		end

		if IsolatePlayers then
			SaveNotCreatable = true
			save_extra("Players", service.Players) -- no reason to saveprops as you can see the props on the original instance
		end

		if NilInstances and global_container.getnilinstances then
			local nil_instances, nil_instances_size = {}, 1

			local NilInstancesFixes = OPTIONS.NilInstancesFixes
			local listOk, candidates = pcall(global_container.getnilinstances)
			if not listOk or type(candidates) ~= "table" then
				warn("Dex++: getnilinstances failed; continuing without nil instances: " .. tostring(candidates))
				candidates = {}
			end
			local skippedNilInstances = 0

			for _, candidate in candidates do
				local processed, instance = pcall(function()
					if candidate == game or typeof(candidate) ~= "Instance" then return nil end
					local ClassName = candidate.ClassName
					local Fix = InheritsFix(NilInstancesFixes, ClassName, candidate)
					local result = Fix and Fix(candidate, InstancesOverrides) or candidate
					local Class = ClassList[ClassName]
					if Class and Class.Service then return nil end
					return result
				end)
				if processed and instance then
					nil_instances[nil_instances_size] = instance
					nil_instances_size += 1
				elseif not processed then
					skippedNilInstances += 1
				end
			end
			if skippedNilInstances > 0 then
				warn("Dex++: skipped " .. skippedNilInstances .. " invalid nil instance(s) instead of cancelling the export")
			end
			SaveNotCreatable = true
			save_extra("Nil Instances", nil_instances)
		end

		if OPTIONS.ReadMe then
			save_extra(
				"README",
				nil,
				nil,
				"Script",
				"--[[\n"
					.. (#RecoveredScripts ~= 0 and "\t\tIMPORTANT: Original Source of these Scripts was Recovered: " .. service.HttpService:JSONEncode(
						RecoveredScripts
					) .. "\n" or "")
					.. [[
		Thank you for using UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw.

		If you didn't save in Binary (rbxl) - it's recommended to save the game right away to take advantage of the binary format & to preserve values of certain properties if you used IgnoreDefaultProperties setting (as they might change in the future).
		You can do that by going to FILE -> Save to File As -> Make sure File Name ends with .rbxl -> Save

		ServerStorage, ServerScriptService and Server Scripts are IMPOSSIBLE to save because of FilteringEnabled.

		If your player cannot spawn into the game, please move the scripts in StarterPlayer somewhere else or delete them. Then run `game:GetService("Players").CharacterAutoLoads = true`.
		And use "Play Here" to start game instead of "Play" to spawn your Character where your Camera currently is.

		If the chat system does not work, please use the explorer and delete everything inside the TextChatService/Chat service(s). 
		Or run `game:GetService("Chat"):ClearAllChildren() game:GetService("TextChatService"):ClearAllChildren()`
				
		If Union and MeshPart collisions don't work, run the script below in the Studio Command Bar:
				
				
		local C = game:GetService("CoreGui")
		local D = Enum.CollisionFidelity.Default
				
		for _, v in game:GetDescendants() do
			if v:IsA("TriangleMeshPart") and not v:IsDescendantOf(C) then
				v.CollisionFidelity = D
			end
		end
		print("Done")
				
		If you can't move the Camera, run this script in the Studio Command Bar:
			
		workspace.CurrentCamera.CameraType = Enum.CameraType.Fixed
		
		Or Destroy the Camera.

		This file was generated with the following settings:
		]]
					.. service.HttpService:JSONEncode(OPTIONS)
					.. "\n\n\t\tElapsed time: "
					.. os.clock() - elapse_t
					.. " Date (UTC): "
					.. DateTime.now():FormatUniversalTime("LL LTS", "en-gb")
					.. " PlaceId: "
					.. game.PlaceId
					.. " PlaceVersion: "
					.. game.PlaceVersion
					.. " Client Version: "
					.. FULL_VERSION
					.. " Platform: "
					.. (
						select(
							2,
							pcall(function()
								return service.UserInputService:GetPlatform().Name -- Won't work on lvl 2 execs but we can safely assume they're on PC (and likely Windows)
							end)
						) or "Unknown"
					)
					.. " Executor: "
					.. (identify_executor and table.concat({ identify_executor() }, " ") or "Unknown")
					.. "\n]]"
			)
		end
		do
			local tmp = { "<SharedStrings>" }
			for value, id in sharedStrings do
				table.insert(tmp, '<SharedString md5="' .. id .. '">' .. value .. "</SharedString>")
			end

			if 1 < #tmp then -- next(SharedStrings) check also works but seems to be slower
				savebuffer[savebuffer_size] = table.concat(tmp)
				savebuffer_size += 1
				savebuffer[savebuffer_size] = "</SharedStrings>"
				savebuffer_size += 1
			end
		end

		savebuffer[savebuffer_size] =
			"</roblox><!-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw -->"
		savebuffer_size += 1
		save_cache()
		do
			local function buildFinalString(chunks)
				local parts = table.create(#chunks + 1)
				parts[1] = header

				table.move(chunks, 1, #chunks, 2, parts)

				return table.concat(parts)
			end

			local Callback = OPTIONS.Callback
			if Callback then
				Callback(buildFinalString(chunks), chunks)
			elseif OPTIONS.AlternativeWritefile and appendfile then
				local SEGMENT_SIZE = 4145728 -- Celery has an arbitrary savefile/appendfile size limit of ~4MB for reasons unknown. This is a workaround to save the file in segments.
				local totallen = 0
				for _, chunk in chunks do
					totallen += math.ceil(#chunk / SEGMENT_SIZE)
				end

				local currentlen = 0

				for _, chunk in chunks do
					local chunk_len = #chunk
					local offset = 1

					while offset <= chunk_len do
						local savestr = string.sub(chunk, offset, offset + SEGMENT_SIZE - 1)

						run_with_loading(
							"Writing to File " .. math.round(currentlen / totallen * 100) .. "% (Depends on Exec)",
							nil,
							true,
							appendfile,
							placename,
							savestr
						)

						currentlen += 1
						offset += SEGMENT_SIZE

						if offset <= chunk_len then
							task.wait()
						end
					end
				end
			else
				run_with_loading(
					"Writing " .. get_size_format() .. " to File (Depends on Exec)",
					nil,
					true,
					writefile,
					placename,
					buildFinalString(chunks)
				)
			end
		end
	end

	local Connections = {}
	local function Connect(event, func)
		table.insert(Connections, event:Connect(func))
	end
	local function Cleanup()
		for _, connection in Connections do
			connection:Disconnect()
		end
		GLOBAL_ENV[placename] = nil
	end
	do
		local Players = service.Players

		if IgnoreList.Model ~= true then
			local function ignoreCharacter(player)
				Connect(player.CharacterAdded, function(character)
					IgnoreList[character] = true
				end)

				local Character = player.Character
				if Character then
					IgnoreList[Character] = true
				end
			end

			if not OPTIONS.SavePlayerCharacters then
				Connect(Players.PlayerAdded, function(player)
					ignoreCharacter(player)
				end)

				for _, player in Players:GetPlayers() do
					ignoreCharacter(player)
				end
			else
				IgnoreNotArchivable = false -- TODO Bad solution (Characters are NotArchivable); Also make sure the next solution is compatible with IsolateLocalPlayerCharacter
				if IsolateLocalPlayerCharacter then
					task.spawn(function()
						ignoreCharacter(GetLocalPlayer())
					end)
				end
			end
		end
		if IsolateLocalPlayer and IgnoreList.Player ~= true then
			task.spawn(function()
				IgnoreList[GetLocalPlayer()] = true
			end)
		end
	end

	if IsolateStarterPlayer then
		IgnoreList.StarterPlayer = false
	end

	if IsolatePlayers then
		IgnoreList.Players = false
	end

	if OPTIONS.ShowStatus then
		do
			local Exists = GLOBAL_ENV.USSI_statustext
			if Exists then
				Exists:Destroy()
			end
		end

		local StatusGui = Instance.new("ScreenGui")

		GLOBAL_ENV.USSI_statustext = StatusGui

		StatusGui.DisplayOrder = 2e9
		pcall(function() -- ? Compatibility with level 2
			StatusGui.OnTopOfCoreBlur = true
		end)

		StatusText = Instance.new("TextLabel")

		StatusText.Text = "Saving..."

		StatusText.BackgroundTransparency = 1
		StatusText.Font = Enum.Font.Code
		StatusText.AnchorPoint = Vector2.new(1)
		StatusText.Position = UDim2.new(1)
		StatusText.Size = UDim2.new(0.3, 0, 0, 20)

		StatusText.TextColor3 = Color3.new(1, 1, 1)
		StatusText.TextScaled = true
		StatusText.TextStrokeTransparency = 0.7
		StatusText.TextXAlignment = Enum.TextXAlignment.Right
		StatusText.TextYAlignment = Enum.TextYAlignment.Top

		StatusText.Parent = StatusGui

		local function randomString()
			local length = math.random(10, 20)
			local randomarray = table.create(length)
			for i = 1, length do
				randomarray[i] = string.char(math.random(32, 126))
			end
			return table.concat(randomarray)
		end

		if global_container.gethui then
			StatusGui.Name = randomString()
			StatusGui.Parent = global_container.gethui()
		else
			if global_container.protectgui then
				StatusGui.Name = randomString()
				global_container.protectgui(StatusGui)
				StatusGui.Parent = game:GetService("CoreGui")
			else
				local RobloxGui = game:GetService("CoreGui"):FindFirstChild("RobloxGui")
				if RobloxGui then
					StatusGui.Parent = RobloxGui
				else
					StatusGui.Name = randomString()
					StatusGui.Parent = game:GetService("CoreGui")
				end
			end
		end
	end

	do
		if not ClassList then -- means first run
			do -- * Load Region of Déjà Vu
				local UGCValidationService -- = service.UGCValidationService

				gethiddenproperty_fallback = function(instance, propertyName)
					if not UGCValidationService then
						UGCValidationService = service.UGCValidationService
					end
					return UGCValidationService:GetPropertyValue(instance, propertyName) -- TODO Sadly there's no way to tell whether value is actually nil or the function just couldn't read it (always returns nil for "Class" category properties)
					-- TODO `category ~= "Class"` causes WeldConstraint Part1Internal to be read as nil and not get unfiltered. Currently, there are no properties of category "Class" that match the following: NotScriptable, can be read with gethiddenproperty_fallback accurately (it always outputs nil for "Class" category, making that check useless anyway) & don't have a NotScriptableFix.
				end
				if gethiddenproperty then
					local o, r = pcall(gethiddenproperty, workspace, "StreamOutBehavior")
					if not o or r ~= nil and typeof(r) ~= "EnumItem" then -- * Tests if gethiddenproperty is broken
						gethiddenproperty = nil
					else
						o, r =
							pcall(gethiddenproperty, Instance.new("AnimationRigData", Instance.new("Folder")), "parent") -- * Tests how it reacts to property overlap (shadowing) due to AnimationRigData.parent; expected BinaryString

						if o and r ~= nil and type(r) ~= "string" then
							gethiddenproperty = nil
						end
					end
				end
				do
					if
						not bit32.byteswap
						or not (function()
							local o, r = pcall(bit32.byteswap, 2712847316)
							if not o then
								return -- It might be disabled on some builds
							end
							return r == 3569595041
						end)()
					then -- Because Fluxus is missing byteswap
						-- https://github.com/luau-lang/rfcs/blob/master/docs/function-bit32-byteswap.md
						local b32 = table.clone(bit32)

						b32.byteswap = function(n)
							return bit32.bor(
								bit32.lshift(n, 24),
								bit32.band(bit32.lshift(n, 8), 0xFF0000),
								bit32.band(bit32.rshift(n, 8), 0xFF00),
								bit32.rshift(n, 24)
							)
						end
						if table.isfrozen(bit32) then
							b32 = table.freeze(b32)
						end
						GLOBAL_ENV.bit32 = b32
					end

					-- Validate executor-provided encoders and use the bundled implementation
					-- when their naming or behavior is incompatible.
					local validEncoder = false
					if type(base64encode) == "function" then
						local ok, encoded = pcall(base64encode, "\1\0\0\0\1")
						validEncoder = ok and encoded == "AQAAAAE="
					end
					if not validEncoder then base64encode = fallbackBase64Encode end
				end
			end
			do
				local ok, result = pcall(FetchAPI)
				if ok then
					ClassList = result
				else
					Cleanup()
					error("Failed to load the API Dump: " .. tostring(result), 0)
				end
			end
		end

		elapse_t = os.clock()

		local ok, err = xpcall(save_game, function(err)
			return debug.traceback(err)
		end)

		if old_gethiddenproperty then
			gethiddenproperty = old_gethiddenproperty
		end

		Cleanup()

		elapse_t = os.clock() - elapse_t
		local Log10 = math.max(0, math.log10(math.max(elapse_t, 0.001)))
		local ExtraTime = 10

		if StatusText then
			task.spawn(function()
				if ok then
					StatusText.Text = string.format("Saved! Time %.3f seconds; Size %s", elapse_t, get_size_format())
					StatusText.TextColor3 = Color3.new(0, 1, 0)
					task.wait(Log10 * 2 + ExtraTime)
				else
					if LoadingThread then
						task.cancel(LoadingThread)
						LoadingThread = nil
					end
					StatusText.Text = "Failed! Check F9 console for more info"
					StatusText.TextColor3 = Color3.new(1, 0, 0)
					warn("Error found while saving:")
					warn(err)
					task.wait(Log10 + ExtraTime)
				end
				local statusGui = StatusText.Parent
				if typeof(statusGui) == "Instance" then pcall(statusGui.Destroy, statusGui) end
				if GLOBAL_ENV.USSI_statustext == statusGui then GLOBAL_ENV.USSI_statustext = nil end
			end)
		end

		if not ok then
			error(err, 0)
		end

		return true, placename
	end
end

return synsaveinstance

end,
}
local oldgame = oldgame or game

local DPP_GLOBAL_ENV = getgenv and getgenv() or _G or shared
local previousDexClose = DPP_GLOBAL_ENV and rawget(DPP_GLOBAL_ENV, "DEXPLUSPLUS_CLOSE")
if type(previousDexClose) == "function" then
	pcall(previousDexClose, "reload")
end

-- Older Dex++ builds did not expose a shutdown function. Remove their orphaned
-- interfaces before starting this build so two Save buttons cannot overlap.
local function destroyOrphanedDexGuis()
	local containers = {}
	local function addContainer(container)
		if typeof(container) == "Instance" and not table.find(containers, container) then
			table.insert(containers, container)
		end
	end

	if gethui then
		local ok, container = pcall(gethui)
		if ok then addContainer(container) end
	end
	pcall(function() addContainer(game:GetService("CoreGui")) end)
	pcall(function()
		local player = game:GetService("Players").LocalPlayer
		if player then addContainer(player:FindFirstChildOfClass("PlayerGui")) end
	end)

	for _, container in ipairs(containers) do
		for _, gui in ipairs(container:GetChildren()) do
			if string.sub(gui.Name, 1, 5) == "_DPP_" then
				pcall(gui.Destroy, gui)
			end
		end
	end
end

destroyOrphanedDexGuis()

cloneref = cloneref or function(ref)
	if not getreg then return ref end
	
	local InstanceList
	
	local a = Instance.new("Part")
	for _, c in pairs(getreg()) do
		if type(c) == "table" and #c then
			if rawget(c, "__mode") == "kvs" then
				for d, e in pairs(c) do
					if e == a then
						InstanceList = c
						break
					end
				end
			end
		end
	end
	local f = {}
	function f.invalidate(g)
		if not InstanceList then
			return
		end
		for b, c in pairs(InstanceList) do
			if c == g then
				InstanceList[b] = nil
				return g
			end
		end
	end
	return f.invalidate
end

local isFsSupported = readfile and writefile and isfile and isfolder and listfiles and delfile and delfolder

-- Main vars
local Main, Explorer, Properties, ScriptViewer, Console, SaveInstance, ModelViewer, SettingsWindow--[[, SecretServicePanel]], DefaultSettings, Notebook, Serializer, Lib local ggv = getgenv or nil
local API, RMD

-- Default Settings
DefaultSettings = (function()
	local rgb = Color3.fromRGB	
	
	return {
		Explorer = {
			_Recurse = true,
			Sorting = true,
			TeleportToOffset = Vector3.new(0,0,0),
			ClickToRename = true,
			AutoUpdateSearch = true,
			AutoUpdateMode = 0, -- 0 Default, 1 no tree update, 2 no descendant events, 3 frozen
			PartSelectionBox = true,
			GuiSelectionBox = true,
			CopyPathUseGetChildren = true
		},
		Properties = {
			_Recurse = true,
			MaxConflictCheck = 50,
			ShowDeprecated = true,
			ShowHidden = false,
			ClearOnFocus = false,
			LoadstringInput = true,
			NumberRounding = 3,
			ShowAttributes = true,
			MaxAttributes = 50,
			ScaleType = 0 -- 0 Full Name Shown, 1 Equal Halves
		},
		Theme = {
			_Recurse = true,
			Main1 = rgb(52,52,52),
			Main2 = rgb(45,45,45),
			Outline1 = rgb(33,33,33), -- Mainly frames
			Outline2 = rgb(55,55,55), -- Mainly button
			Outline3 = rgb(30,30,30), -- Mainly textbox
			TextBox = rgb(38,38,38),
			Menu = rgb(32,32,32),
			ListSelection = rgb(11,90,175),
			Button = rgb(60,60,60),
			ButtonHover = rgb(68,68,68),
			ButtonPress = rgb(40,40,40),
			Highlight = rgb(75,75,75),
			Text = rgb(255,255,255),
			PlaceholderText = rgb(100,100,100),
			Important = rgb(255,0,0),
			ExplorerIconMap = "",
			MiscIconMap = "",
			Syntax = {
				Text = rgb(204,204,204),
				Background = rgb(36,36,36),
				Selection = rgb(255,255,255),
				SelectionBack = rgb(11,90,175),
				Operator = rgb(204,204,204),
				Number = rgb(255,198,0),
				String = rgb(173,241,149),
				Comment = rgb(102,102,102),
				Keyword = rgb(248,109,124),
				Error = rgb(255,0,0),
				FindBackground = rgb(141,118,0),
				MatchingWord = rgb(85,85,85),
				BuiltIn = rgb(132,214,247),
				CurrentLine = rgb(45,50,65),
				LocalMethod = rgb(253,251,172),
				LocalProperty = rgb(97,161,241),
				Nil = rgb(255,198,0),
				Bool = rgb(255,198,0),
				Function = rgb(248,109,124),
				Local = rgb(248,109,124),
				Self = rgb(248,109,124),
				FunctionName = rgb(253,251,172),
				Bracket = rgb(204,204,204)
			},
		},
		ScriptViewer = {
			_Recurse = true,
			ShowMoreInfo = true;
		},
		Window = {
			_Recurse = true,
			TitleOnMiddle = false,
			Transparency = .2
		},
		Decompiler = {
			_Recurse = true,
			NativeOnly = true,
		},
		Save = {
			_Recurse = true,
			Folder = "DexPlusPlus/saves",
			CreateFolders = true,
			AvoidOverwrite = true,
			VerifyAfterWrite = true,
			DecompileScripts = true,
			SaveScriptBytecode = true,
		},
		
		RemoteBlockWriteAttribute = false, -- writes attribute to remote instance if remote is blocked/unblocked
		ClassIcon = "NewDark",
		
		-- What available icons:
		-- > Vanilla3
		-- > Old
		-- > NewDark
	}
end)()

-- Vars
local Settings = {}
local Apps = {}
local env = {}

local service = setmetatable({},{__index = function(self,name)
	local serv = cloneref(game:GetService(name))
	self[name] = serv
	return serv
end})
local plr = service.Players.LocalPlayer or service.Players.PlayerAdded:wait()

local create = function(data)
	local insts = {}
	for i,v in pairs(data) do insts[v[1]] = Instance.new(v[2]) end

	for _,v in pairs(data) do
		for prop,val in pairs(v[3]) do
			if type(val) == "table" then
				insts[v[1]][prop] = insts[val[1]]
			else
				insts[v[1]][prop] = val
			end
		end
	end

	return insts[1]
end

local createSimple = function(class,props)
	local inst = Instance.new(class)
	for i,v in next,props do
		inst[i] = v
	end
	return inst
end

Main = (function()
	local Main = {}

	Main.ModuleList = {"Explorer","Properties","ScriptViewer","Console","SaveInstance","ModelViewer","SettingsWindow"}
	Main.Elevated = false
	Main.AllowDraggableOnMobile = true
	Main.MissingEnv = {}
	Main.Version = "4.0 Custom"
	Main.Mouse = plr:GetMouse()
	Main.AppControls = {}
	Main.Apps = Apps
	Main.MenuApps = {}
	Main.GitName = "AZYsGithub"
	Main.RepoName = "DexPlusPlus"
	Main.GitRepoName = Main.GitName.."/"..Main.RepoName

	Main.DisplayOrders = {
		SideWindow = 8,
		Window = 10,
		Menu = 100000,
		Core = 101000
	}
	
	Main.Plugins = {}
	
	Main.GetRandomString = function()
		local output = ""
		for i = 2, 25 do
			output = output .. string.char(math.random(1,250))
		end
		
		return output
	end
	
	Main.GetSecureContainer = function()
		return
			(gethui and gethui()) or
			service.CoreGui or
			service.Players.LocalPlayer:WaitForChild("PlayerGui")
	end
	
	Main.SecureGui = function(gui)
		--warn("Secured: "..gui.Name)
		gui.Name = "_DPP_".. Main.GetRandomString()
		-- service already using cloneref
		if gethui then
			gui.Parent = gethui()
		elseif syn and syn.protect_gui then
			syn.protect_gui(gui)
			gui.Parent = service.CoreGui
		elseif protect_gui then
			protect_gui(gui)
			gui.Parent = service.CoreGui
		elseif protectgui then
			protectgui(gui)
			gui.Parent = service.CoreGui
		else
			if Main.Elevated then
				gui.Parent = service.CoreGui
			else
				gui.Parent = service.Players.LocalPlayer:WaitForChild("PlayerGui")
			end
		end
	end

	Main.GetInitDeps = function()
		return {
			Main = Main,
			Lib = Lib,
			Apps = Apps,
			Settings = Settings,

			API = API,
			RMD = RMD,
			env = env,
			service = service,
			plr = plr,
			create = create,
			createSimple = createSimple
		}
	end

	Main.Error = function(str)
		if rconsoleprint then
			rconsoleprint("DEX ERROR: "..tostring(str).."\n")
		end
		error(tostring(str), 0)
	end

	Main.HttpGet = function(url, label, attempts)
		attempts = math.max(1, tonumber(attempts) or 3)
		label = tostring(label or url)
		local lastError = "empty response"

		for attempt = 1, attempts do
			local ok, response = pcall(oldgame.HttpGet, oldgame, url, true)
			if ok and type(response) == "string" and response:match("%S") then
				local prefix = response:sub(1, 128):lower()
				if not prefix:find("<!doctype html", 1, true) and not prefix:find("<html", 1, true) then
					return response
				end
				lastError = "the server returned HTML instead of the requested data"
			else
				lastError = (response == nil or response == "") and "empty response" or tostring(response)
			end

			if attempt < attempts then
				task.wait(math.min(0.5 * attempt, 1.5))
			end
		end

		error("Failed to download " .. label .. " from " .. url .. " after " .. attempts .. " attempts: " .. lastError, 0)
	end

	Main.LoadModule = function(name)
		if Main.Elevated then -- If you don't have filesystem api then ur outta luck tbh
			local control

			if EmbeddedModules then -- Offline Modules
				control = EmbeddedModules[name]()

				-- TODO: Remove when open source
				if gethsfuncs then
					control = _G.moduleData
				end

				if not control then Main.Error("Missing Embedded Module: "..name) end
			else
				-- Get hash data
				local hashs = Main.ModuleHashData
				if not hashs then
					local s,hashDataStr = pcall(Main.HttpGet, "https://raw.githubusercontent.com/"..Main.GitRepoName.."/refs/heads/main/ModuleHashs.dat", "Dex++ module hashes")
					if not s then Main.Error(hashDataStr) end

					local s,hashData = pcall(service.HttpService.JSONDecode,service.HttpService,hashDataStr)
					if not s then Main.Error("Failed to decode module hash JSON") end

					hashs = hashData
					Main.ModuleHashData = hashs
				end

				-- Check if local copy exists with matching hashs
				local hashfunc = (syn and syn.crypt.hash) or function() return "" end
				local filePath = "dex/ModuleCache/"..name..".lua"
				local s,moduleStr = pcall(env.readfile,filePath)

				if s and hashfunc(moduleStr) == hashs[name] then
					local chunk, compileError = env.loadstring(moduleStr, "DexPlusPlus_" .. name)
					if not chunk then Main.Error("Failed to compile cached module " .. name .. ": " .. tostring(compileError)) end
					control = chunk()
				else
					-- Download and cache
					local s,moduleStr = pcall(Main.HttpGet, "https://raw.githubusercontent.com/"..Main.GitRepoName.."/refs/heads/main/modules/"..name..".lua", "Dex++ module " .. name)
					if not s then Main.Error(moduleStr) end

					pcall(env.writefile,filePath,moduleStr)
					local chunk, compileError = env.loadstring(moduleStr, "DexPlusPlus_" .. name)
					if not chunk then Main.Error("Failed to compile module " .. name .. ": " .. tostring(compileError)) end
					control = chunk()
				end
			end

			Main.AppControls[name] = control
			control.InitDeps(Main.GetInitDeps())

			local moduleData = control.Main()
			Apps[name] = moduleData
			return moduleData
		else
			local module = script:WaitForChild("Modules"):WaitForChild(name,2)
			if not module then Main.Error("CANNOT FIND MODULE "..name) end

			local control = require(module)
			Main.AppControls[name] = control
			control.InitDeps(Main.GetInitDeps())

			local moduleData = control.Main()
			Apps[name] = moduleData
			return moduleData
		end
	end
	
	Main.LoadPluginFile = function(pluginDir)
		if env.readfile then
			if isfile(pluginDir) then
				local preloadedPlugin = loadfile and loadfile(pluginDir) or loadstring(env.readfile(pluginDir))
				local loadedPlugin = preloadedPlugin()
				
				local control = loadedPlugin
				control.InitDeps(Main.GetInitDeps())

				local moduleData = control.Main()
				Apps[pluginDir] = moduleData
				Main.AppControls[pluginDir] = control
				
				moduleData.PluginData = control.PluginData
				
				return moduleData
			else
				Main.Error("CANNOT FIND FILE MODULE "..pluginDir)
			end
		end
	end

	Main.LoadModules = function()
		for i,v in ipairs(Main.ModuleList) do
			local s,e = pcall(Main.LoadModule,v)
			if not s then
				Main.Error("FAILED LOADING " .. v .. " CAUSE " .. e)
			end
		end

		-- Init Major Apps and define them in modules
		Explorer = Apps.Explorer
		Properties = Apps.Properties
		ScriptViewer = Apps.ScriptViewer
		Console = Apps.Console
		SaveInstance = Apps.SaveInstance
		ModelViewer = Apps.ModelViewer
		Notebook = Apps.Notebook
		SettingsWindow = Apps.SettingsWindow
		
		
		--SecretServicePanel = Apps.SecretServicePanel
		local appTable = {
			Explorer = Explorer,
			Properties = Properties,
			ScriptViewer = ScriptViewer,
			Console = Console,
			SaveInstance = SaveInstance,
			ModelViewer = ModelViewer,
			Notebook = Notebook,
			SettingsWindow = SettingsWindow
			--SecretServicePanel = SecretServicePanel,
		}
		
		

		Main.AppControls.Lib.InitAfterMain(appTable)
		for i,v in ipairs(Main.ModuleList) do
			local control = Main.AppControls[v]
			if control then
				control.InitAfterMain(appTable)
			end
		end
	end

	Main.InitEnv = function()
		local synApi = type(syn) == "table" and syn or nil
		local nativeDecompiler = decompile or (synApi and synApi.decompile)
		local nativeBytecode = getscriptbytecode or dumpstring
			or (synApi and (synApi.getscriptbytecode or synApi.dumpstring))
		local nativeGetNilInstances = getnilinstances or get_nil_instances
			or (synApi and synApi.getnilinstances)
		local nativeGetInstances = getinstances or get_instances
			or (synApi and synApi.getinstances)
		local function collectNilInstances()
			if typeof(nativeGetNilInstances) == "function" then
				local ok, instances = pcall(nativeGetNilInstances)
				if ok and type(instances) == "table" then return instances end
			end

			local result = {}
			if typeof(nativeGetInstances) ~= "function" then return result end
			local ok, instances = pcall(nativeGetInstances)
			if not ok or type(instances) ~= "table" then return result end
			for _, instance in ipairs(instances) do
				local checked, isNilInstance = pcall(function()
					return typeof(instance) == "Instance" and instance ~= game and instance.Parent == nil
				end)
				if checked and isNilInstance then table.insert(result, instance) end
			end
			return result
		end

		setmetatable(env,{__newindex = function(self,name,func)
			if not func then Main.MissingEnv[#Main.MissingEnv+1] = name return end
			rawset(self,name,func)
		end})

		env.isonmobile = game:GetService("UserInputService").TouchEnabled

		env.notify = function(title, text, duration)
			title = tostring(title or "Dex++")
			text = tostring(text or "")
			local success = pcall(function()
				service.StarterGui:SetCore("SendNotification", {
					Title = title,
					Text = text,
					Duration = duration or 6
				})
			end)
			if not success then
				warn(title .. ": " .. text)
			end
		end
		
		env.loadstring = (pcall(loadstring,"local a = 1") and loadstring) or (game:GetService("RunService"):IsStudio() and script.Modules:FindFirstChild("Loadstring") and require(script.Modules:FindFirstChild("Loadstring")))

		-- file
		env.isfile = isfile
		env.isfolder = isfolder
		env.readfile = readfile
		env.writefile = writefile
		env.appendfile = appendfile
		env.makefolder = makefolder
		env.listfiles = listfiles
		env.loadfile = loadfile
		env.parsefile = function(name)
			local parsed = tostring(name or "")
				:gsub("[\0-\31]", "")
				:gsub("[*\\/?:<>|]+", "_")
				:gsub("^%s+", "")
				:gsub("%s+$", "")
				:gsub("[%. ]+$", "")
				:sub(1, 175)
			return parsed ~= "" and parsed or ("DexPlusPlus_" .. os.time())
		end
		env.normalizepath = function(path)
			local parts = {}
			for part in tostring(path or ""):gsub("\\", "/"):gmatch("[^/]+") do
				part = part:match("^%s*(.-)%s*$") or ""
				if part ~= "" and part ~= "." and part ~= ".." then
					part = env.parsefile(part)
					if part ~= "" then table.insert(parts, part) end
				end
			end
			return table.concat(parts, "/")
		end
		env.joinpath = function(folder, filename)
			folder = env.normalizepath(folder)
			filename = env.parsefile(filename)
			return folder ~= "" and (folder .. "/" .. filename) or filename
		end
		env.ensurefolder = function(folder)
			folder = env.normalizepath(folder)
			if folder == "" then return true, "" end
			if not env.makefolder then
				return false, "Your executor does not provide makefolder"
			end

			local current = ""
			for part in folder:gmatch("[^/]+") do
				current = current == "" and part or (current .. "/" .. part)
				local exists = false
				if env.isfolder then
					local checked, result = pcall(env.isfolder, current)
					exists = checked and result == true
				end
				if not exists then
					local created, createError = pcall(env.makefolder, current)
					if not created then
						-- Some executors throw when the directory already exists.
						local checked, result = env.isfolder and pcall(env.isfolder, current)
						if not (checked and result) then
							return false, "Could not create folder '" .. current .. "': " .. tostring(createError)
						end
					end
				end
			end
			return true, folder
		end

		-- Centralized teleport implementation used by Explorer. It supports parts,
		-- models, attachments, value objects and containers with a descendant part.
		env.teleportto = function(target, customOffset)
			local ok, success, detail = pcall(function()
				if typeof(target) ~= "Instance" then
					return false, "The selected value is not an Instance"
				end

				local character = plr.Character
				local root = character and (character:FindFirstChild("HumanoidRootPart") or character.PrimaryPart or character:FindFirstChildWhichIsA("BasePart"))
				if not character or not root then
					return false, "Your character is not ready"
				end
				if target:IsDescendantOf(character) then
					return false, "The selected part belongs to your own character"
				end

				local targetCFrame, targetSize
				local function usePart(part)
					targetCFrame = part.CFrame
					targetSize = part.Size
				end

				if target:IsA("BasePart") then
					usePart(target)
				elseif target:IsA("Attachment") then
					targetCFrame = target.WorldCFrame
					targetSize = Vector3.zero
				elseif target:IsA("CFrameValue") then
					targetCFrame = target.Value
					targetSize = Vector3.zero
				elseif target:IsA("Vector3Value") then
					targetCFrame = CFrame.new(target.Value)
					targetSize = Vector3.zero
				elseif target:IsA("Model") then
					local boundingOk, boundingCFrame, boundingSize = pcall(target.GetBoundingBox, target)
					if boundingOk then
						targetCFrame, targetSize = boundingCFrame, boundingSize
					else
						targetCFrame, targetSize = target:GetPivot(), Vector3.zero
					end
				else
					local descendantPart = target:FindFirstChildWhichIsA("BasePart", true)
					local ancestorPart = target:FindFirstAncestorWhichIsA("BasePart")
					local ancestorModel = target:FindFirstAncestorWhichIsA("Model")
					if descendantPart then
						usePart(descendantPart)
					elseif ancestorPart then
						usePart(ancestorPart)
					elseif ancestorModel then
						local boundingOk, boundingCFrame, boundingSize = pcall(ancestorModel.GetBoundingBox, ancestorModel)
						if boundingOk then
							targetCFrame, targetSize = boundingCFrame, boundingSize
						end
					end
				end

				if not targetCFrame then
					return false, "No position was found for " .. target:GetFullName()
				end

				local characterHeight = 5
				local extentsOk, extents = pcall(character.GetExtentsSize, character)
				if extentsOk then
					characterHeight = extents.Y
				end

				local offset = typeof(customOffset) == "Vector3" and customOffset or Vector3.zero
				local targetHeight = targetSize and targetSize.Y or 0
				local destinationPosition = targetCFrame.Position
					+ Vector3.new(0, targetHeight * 0.5 + characterHeight * 0.5 + 0.5, 0)
					+ offset
				local currentRotation = root.CFrame - root.Position
				local destination = CFrame.new(destinationPosition) * currentRotation

				local humanoid = character:FindFirstChildWhichIsA("Humanoid")
				if humanoid then
					humanoid.Sit = false
					pcall(humanoid.ChangeState, humanoid, Enum.HumanoidStateType.GettingUp)
				end
				character:PivotTo(destination)
				root.AssemblyLinearVelocity = Vector3.zero
				root.AssemblyAngularVelocity = Vector3.zero

				return true, "Teleported to " .. target:GetFullName()
			end)

			if not ok then
				return false, tostring(success)
			end
			return success, detail
		end

		-- Dex++ always uses this pinned serializer. Native executor implementations
		-- vary considerably and were the source of silent failures and key prompts.
		do
			local serializer
			local saveInProgress = false

			local function copyOptions(source)
				local result = {}
				for key, value in pairs(type(source) == "table" and source or {}) do
					if type(value) == "table" then
						local nested = {}
						for nestedKey, nestedValue in pairs(value) do
							nested[nestedKey] = nestedValue
						end
						result[key] = nested
					else
						result[key] = value
					end
				end
				return result
			end

			local function getSerializer()
				if serializer then return serializer end

				local ok, result
				if EmbeddedModules and EmbeddedModules.UniversalSynSaveInstance then
					ok, result = pcall(EmbeddedModules.UniversalSynSaveInstance)
				else
					local sourceUrl = "https://raw.githubusercontent.com/luau/UniversalSynSaveInstance/a8555ca4c3e9219868889d422a73a1b42115c745/saveinstance.luau"
					ok, result = pcall(function()
						local source = Main.HttpGet(sourceUrl, "pinned save engine")
						local chunk = assert(env.loadstring(source, "UniversalSynSaveInstance"))
						return chunk()
					end)
				end

				if not ok then
					error("Unable to load the bundled save engine: " .. tostring(result), 0)
				end
				if type(result) ~= "function" then
					error("The bundled save engine returned an invalid result", 0)
				end
				serializer = result
				return serializer
			end

			local function ensureExtension(filePath, isModel)
				local normalized = env.normalizepath(filePath)
				local folder, baseName = normalized:match("^(.*)/([^/]+)$")
				baseName = env.parsefile(baseName or normalized):gsub("%.[^%.]+$", "")
				folder = env.normalizepath(folder or "")
				local extension = isModel and ".rbxmx" or ".rbxlx"
				local stem = folder ~= "" and (folder .. "/" .. baseName) or baseName
				local candidate = stem .. extension

				if Settings.Save.AvoidOverwrite and env.isfile then
					local index = 1
					while true do
						local checked, exists = pcall(env.isfile, candidate)
						if not checked or not exists then break end
						candidate = stem .. "_" .. index .. extension
						index += 1
					end
				end
				return candidate, folder
			end

			local function addIgnoredScriptNames(finalOptions, root)
				local names = finalOptions.DecompileIgnoreNames
				finalOptions.DecompileIgnoreNames = nil
				if type(names) ~= "table" or #names == 0 then return end

				local nameMap = {}
				for _, name in ipairs(names) do
					name = tostring(name):match("^%s*(.-)%s*$")
					if name ~= "" then nameMap[name] = true end
				end

				local ignore = finalOptions.DecompileIgnore
				if type(ignore) ~= "table" then ignore = {"TextChatService"} end
				finalOptions.DecompileIgnore = ignore

				local searchRoots = typeof(root) == "table" and root or {root}
				for _, searchRoot in ipairs(searchRoots) do
					if typeof(searchRoot) == "Instance" then
						if searchRoot:IsA("LuaSourceContainer") and nameMap[searchRoot.Name] then
							table.insert(ignore, searchRoot)
						end
						for _, descendant in ipairs(searchRoot:GetDescendants()) do
							if descendant:IsA("LuaSourceContainer") and nameMap[descendant.Name] then
								table.insert(ignore, descendant)
							end
						end
					end
				end
			end

			env.saveinstance = function(object, filePath, options)
				if service.RunService:IsStudio() then
					error("Save to File requires an executor with filesystem access", 0)
				end
				if not env.writefile then
					error("Your executor does not provide writefile", 0)
				end
				if saveInProgress then
					error("Another Dex++ export is already in progress", 0)
				end

				local objectType = typeof(object)
				local isCollection = objectType == "table"
				if objectType ~= "Instance" and not isCollection then
					error("Save target must be an Instance or a list of Instances", 0)
				end
				if isCollection then
					if #object == 0 then error("No Instances were selected", 0) end
					for _, item in ipairs(object) do
						if typeof(item) ~= "Instance" then
							error("The selection contains a value that is not an Instance", 0)
						end
					end
				end

				local isModel = object ~= game
				local finalOptions = copyOptions(options)
				finalOptions.SafeMode = false
				finalOptions.KillAllScripts = false
				finalOptions.BoostFPS = false
				finalOptions.ShutdownWhenDone = false
				finalOptions.AntiIdle = false
				finalOptions.ReadMe = false
				finalOptions.Decompile = finalOptions.Decompile == true
				finalOptions.SaveBytecode = finalOptions.SaveBytecode == true
				if finalOptions.Decompile and typeof(nativeDecompiler) ~= "function" then
					error("Decompile scripts was selected, but this executor does not provide a native decompile function", 0)
				end
				if finalOptions.SaveBytecode
					and typeof(nativeBytecode) ~= "function"
				then
					error("Save script bytecode was selected, but this executor does not provide getscriptbytecode or dumpstring", 0)
				end
				if finalOptions.NilInstances
					and typeof(nativeGetNilInstances) ~= "function"
					and typeof(nativeGetInstances) ~= "function"
				then
					error("Save Nil Instances was selected, but this executor provides neither getnilinstances nor getinstances", 0)
				end
				finalOptions.IgnoreSpecialProperties = true
				local folder
				finalOptions.FilePath, folder = ensureExtension(filePath, isModel)
				if folder ~= "" then
					local folderExists = false
					if env.isfolder then
						local checked, exists = pcall(env.isfolder, folder)
						folderExists = checked and exists == true
					end
					if not folderExists then
						if not Settings.Save.CreateFolders then
							error("The selected save folder does not exist and automatic folder creation is disabled", 0)
						end
						local folderOk, folderError = env.ensurefolder(folder)
						if not folderOk then error(folderError, 0) end
					end
				end

				if isCollection then
					finalOptions.Object = false
					finalOptions.ExtraInstances = object
					finalOptions.IsModel = true
					finalOptions.mode = "invalidmode"
				elseif isModel then
					finalOptions.Object = object
					finalOptions.ExtraInstances = {}
					finalOptions.IsModel = true
					finalOptions.mode = "invalidmode"
				else
					finalOptions.Object = game
					finalOptions.IsModel = false
					finalOptions.mode = "full"
				end

				addIgnoredScriptNames(finalOptions, object)
				saveInProgress = true
				local ok, result, savedPath = xpcall(function()
					return getSerializer()(finalOptions)
				end, function(message)
					if debug and typeof(debug.traceback) == "function" then
						return debug.traceback(tostring(message), 2)
					end
					return tostring(message)
				end)
				saveInProgress = false

				if not ok then
					if DPP_GLOBAL_ENV then
						DPP_GLOBAL_ENV.USSI = nil
						DPP_GLOBAL_ENV[finalOptions.FilePath] = nil
						local statusGui = rawget(DPP_GLOBAL_ENV, "USSI_statustext")
						if typeof(statusGui) == "Instance" then pcall(statusGui.Destroy, statusGui) end
						DPP_GLOBAL_ENV.USSI_statustext = nil
					end
					pcall(service.RunService.Set3dRenderingEnabled, service.RunService, true)
					error(tostring(result), 0)
				end
				if result ~= true then
					error("The save engine stopped without confirming that the file was written", 0)
				end
				local finalPath = savedPath or finalOptions.FilePath
				if Settings.Save.VerifyAfterWrite and env.isfile then
					local checked, exists = pcall(env.isfile, finalPath)
					if checked and not exists then
						error("The save engine finished, but the output file was not found at " .. tostring(finalPath), 0)
					end
				end
				return true, finalPath
			end

			env.issavinginstance = function()
				return saveInProgress
			end
		end

		-- debug
		env.getupvalues = debug.getupvalues or getupvalues or getupvals
		env.getconstants = debug.getconstants or getconstants or getconsts
		env.islclosure = islclosure or is_l_closure
		env.checkcaller = checkcaller
		env.getreg = getreg
		env.getgc = getgc
		
		-- hooks
		env.hookfunction = hookfunction
		env.hookmetamethod = hookmetamethod

		-- other
		env.getscriptbytecode = nativeBytecode
		env.setfflag = setfflag
		env.protectgui = protect_gui or (syn and syn.protect_gui)
		env.gethui = gethui
		env.setclipboard = setclipboard
		env.getnilinstances = (typeof(nativeGetNilInstances) == "function" or typeof(nativeGetInstances) == "function")
			and collectNilInstances or nil
		env.getloadedmodules = getloadedmodules
		
		env.isViableDecompileScript = function(obj)
			if obj:IsA("ModuleScript") then
				return true
			elseif obj:IsA("LocalScript") and (obj.RunContext == Enum.RunContext.Client or obj.RunContext == Enum.RunContext.Legacy) then
				return true
			elseif obj:IsA("Script") and obj.RunContext == Enum.RunContext.Client then
				return true
			end
			return false
		end
		env.request = (syn and syn.request) or (http and http.request) or http_request or (fluxus and fluxus.request) or request
		
		env.isdecompile = function()
			return typeof(nativeDecompiler) == "function"
		end
		
		env.isdecompilefallback = function()
			return false
		end
		
		-- Only use the executor's native implementation. Mutable remote decompiler
		-- code and third-party HTTP services caused key prompts and unstable errors.
		env.decompile = function(...)
			if typeof(nativeDecompiler) ~= "function" then
				error("This executor does not provide a native decompiler", 0)
			end
			return nativeDecompiler(...)
		end
		
		--[[if Main.Elevated then
			getgenv().decompile = env.decompile
		end]]
		

		if identifyexecutor then
			Main.Executor = identifyexecutor()
		end

		Main.GuiHolder = Main.Elevated and service.CoreGui or plr:FindFirstChildOfClass("PlayerGui")

		setmetatable(env,nil)
	end

	local function serialize(val)
		if typeof(val) == "Color3" then
			return {__DPPType = "Color3", R = val.R, G = val.G, B = val.B}
		elseif typeof(val) == "Vector3" then
			return {__DPPType = "Vector3", X = val.X, Y = val.Y, Z = val.Z}
		else
			return val
		end
	end
	
	local function deserialize(val)
		if typeof(val) == "table" then
			if val.__DPPType == "Vector3" and type(val.X) == "number" and type(val.Y) == "number" and type(val.Z) == "number" then
				return Vector3.new(val.X, val.Y, val.Z)
			elseif (val.__DPPType == "Color3" or val.__DPPType == nil) and type(val.R) == "number" and type(val.G) == "number" and type(val.B) == "number" then
				return Color3.new(val.R, val.G, val.B)
			else
				return val
			end
		else
			return val
		end
	end
	
	Main.ExportSettings = function()
		local rawData = Settings or DefaultSettings

		local function recur(tbl)
			local newTbl = {}
			for i, v in pairs(tbl) do
				if typeof(v) == "table" then
					newTbl[i] = recur(v)
				else
					newTbl[i] = serialize(v)
				end
			end
			return newTbl
		end

		-- serialize color3 sebelum encode
		local serializedData = recur(rawData)

		local s, json = pcall(service.HttpService.JSONEncode, service.HttpService, serializedData)
		if s and json then
			return json
		end
	end


	--warn(Main.ExportSettings())

	Main.LoadSettings = function()
		Main.ResetSettings()
		local s, data = pcall(env.readfile or error, "DexPlusPlusSettings.json")
		if s and data and data ~= "" then
			
			local s, decoded = pcall(service.HttpService.JSONDecode, service.HttpService, data)
			if s and type(decoded) == "table" then
				local function mergeKnown(schema, source, destination)
					for key, defaultValue in pairs(schema) do
						if key ~= "_Recurse" and source[key] ~= nil then
							local incoming = source[key]
							if type(defaultValue) == "table" then
								if type(incoming) == "table" then
									if type(destination[key]) ~= "table" then destination[key] = {} end
									mergeKnown(defaultValue, incoming, destination[key])
								end
							else
								local converted = deserialize(incoming)
								if typeof(converted) == typeof(defaultValue) then
									destination[key] = converted
								end
							end
						end
					end
				end

				mergeKnown(DefaultSettings, decoded, Settings)
			else
				warn("Dex++ ignored an invalid settings file and restored safe defaults")
			end
		end
	end

	
	

	Main.ResetSettings = function()
		local function clone(value)
			if type(value) ~= "table" then return value end
			local result = {}
			for key, nestedValue in pairs(value) do
				result[key] = clone(nestedValue)
			end
			return result
		end
		table.clear(Settings)
		for key, value in pairs(DefaultSettings) do
			Settings[key] = clone(value)
		end
	end

	Main.FetchAPI = function(callbackiflong, callbackiftoolong, XD)
		local downloaded = false
		local api,rawAPI
		Main.ApiCacheNeedsRefresh = false
		Main.ApiUsingStaleCache = false
		local function decodeDump(raw)
			if type(raw) ~= "string" or raw == "" then
				return nil, "empty API dump"
			end
			local ok, decoded = pcall(service.HttpService.JSONDecode, service.HttpService, raw)
			if not ok then return nil, tostring(decoded) end
			if type(decoded) ~= "table" or type(decoded.Classes) ~= "table" or #decoded.Classes == 0 or type(decoded.Enums) ~= "table" or #decoded.Enums == 0 then
				return nil, "response is not a Roblox API dump"
			end
			return decoded
		end
		if Main.Elevated then
			local cachedAPI = Lib.ReadFile("dex/rbx_api.dat")
			if Main.LocalDepsUpToDate() then
				api = cachedAPI and decodeDump(cachedAPI)
				if api then rawAPI = cachedAPI end
			end
			if not api then
				Main.ApiCacheNeedsRefresh = true
				task.spawn(function()
					task.wait(10)
					if not downloaded and callbackiflong then callbackiflong() end

					task.wait(20)
					if not downloaded and callbackiftoolong then callbackiftoolong() end

					task.wait(30)
					if not downloaded and XD then XD() end
				end)

				local sources = {
					{"https://setup.rbxcdn.com/" .. Main.RobloxVersion .. "-API-Dump.json", "Roblox CDN"},
					{"https://raw.githubusercontent.com/MaximumADHD/Roblox-Client-Tracker/roblox/API-Dump.json", "Roblox Client Tracker fallback"},
				}
				local errors = {}
				for _, source in ipairs(sources) do
					local ok, response = pcall(Main.HttpGet, source[1], source[2], 2)
					if ok then
						local decoded, decodeError = decodeDump(response)
						if decoded then
							rawAPI, api = response, decoded
							if source[2] ~= "Roblox CDN" then
								warn("Dex++: Roblox CDN unavailable; using " .. source[2])
							end
							break
						end
						table.insert(errors, source[2] .. ": " .. tostring(decodeError))
					else
						table.insert(errors, source[2] .. ": " .. tostring(response))
					end
				end
				if not api and cachedAPI then
					local decoded = decodeDump(cachedAPI)
					if decoded then
						rawAPI, api = cachedAPI, decoded
						Main.ApiUsingStaleCache = true
						warn("Dex++: using an older cached Roblox API dump because both downloads failed")
					end
				end
				if not api then
					Main.Error("Could not load the Roblox API dump. " .. table.concat(errors, " | "))
				end
			end
		else
			if script:FindFirstChild("API") then
				rawAPI = require(script.API)
			else
				error("NO API EXISTS")
			end
		end
		downloaded = true
		
		Main.RawAPI = rawAPI
		api = api or service.HttpService:JSONDecode(rawAPI)

		local classes,enums = {},{}
		local categoryOrder,seenCategories = {},{}

		local function insertAbove(t,item,aboveItem)
			local findPos = table.find(t,item)
			if not findPos then return end
			table.remove(t,findPos)

			local pos = table.find(t,aboveItem)
			if not pos then return end
			table.insert(t,pos,item)
		end

		for _,class in pairs(api.Classes) do
			local newClass = {}
			newClass.Name = class.Name
			newClass.Superclass = class.Superclass
			newClass.Properties = {}
			newClass.Functions = {}
			newClass.Events = {}
			newClass.Callbacks = {}
			newClass.Tags = {}

			if class.Tags then for c,tag in pairs(class.Tags) do newClass.Tags[tag] = true end end
			for __,member in pairs(class.Members) do
				local newMember = {}
				newMember.Name = member.Name
				newMember.Class = class.Name
				newMember.Security = member.Security
				newMember.Tags ={}
				if member.Tags then for c,tag in pairs(member.Tags) do newMember.Tags[tag] = true end end

				local mType = member.MemberType
				if mType == "Property" then
					local propCategory = member.Category or "Other"
					propCategory = propCategory:match("^%s*(.-)%s*$")
					if not seenCategories[propCategory] then
						categoryOrder[#categoryOrder+1] = propCategory
						seenCategories[propCategory] = true
					end
					newMember.ValueType = member.ValueType
					newMember.Category = propCategory
					newMember.Serialization = member.Serialization
					table.insert(newClass.Properties,newMember)
				elseif mType == "Function" then
					newMember.Parameters = {}
					newMember.ReturnType = member.ReturnType.Name
					for c,param in pairs(member.Parameters) do
						table.insert(newMember.Parameters,{Name = param.Name, Type = param.Type.Name})
					end
					table.insert(newClass.Functions,newMember)
				elseif mType == "Event" then
					newMember.Parameters = {}
					for c,param in pairs(member.Parameters) do
						table.insert(newMember.Parameters,{Name = param.Name, Type = param.Type.Name})
					end
					table.insert(newClass.Events,newMember)
				end
			end

			classes[class.Name] = newClass
		end

		for _,class in pairs(classes) do
			class.Superclass = classes[class.Superclass]
		end

		for _,enum in pairs(api.Enums) do
			local newEnum = {}
			newEnum.Name = enum.Name
			newEnum.Items = {}
			newEnum.Tags = {}

			if enum.Tags then for c,tag in pairs(enum.Tags) do newEnum.Tags[tag] = true end end
			for __,item in pairs(enum.Items) do
				local newItem = {}
				newItem.Name = item.Name
				newItem.Value = item.Value
				table.insert(newEnum.Items,newItem)
			end

			enums[enum.Name] = newEnum
		end

		local function getMember(class,member)
			if not classes[class] or not classes[class][member] then return end
			local result = {}

			local currentClass = classes[class]
			while currentClass do
				for _,entry in pairs(currentClass[member]) do
					result[#result+1] = entry
				end
				currentClass = currentClass.Superclass
			end

			table.sort(result,function(a,b) return a.Name < b.Name end)
			return result
		end

		insertAbove(categoryOrder,"Behavior","Tuning")
		insertAbove(categoryOrder,"Appearance","Data")
		insertAbove(categoryOrder,"Attachments","Axes")
		insertAbove(categoryOrder,"Cylinder","Slider")
		insertAbove(categoryOrder,"Localization","Jump Settings")
		insertAbove(categoryOrder,"Surface","Motion")
		insertAbove(categoryOrder,"Surface Inputs","Surface")
		insertAbove(categoryOrder,"Part","Surface Inputs")
		insertAbove(categoryOrder,"Assembly","Surface Inputs")
		insertAbove(categoryOrder,"Character","Controls")
		categoryOrder[#categoryOrder+1] = "Unscriptable"
		categoryOrder[#categoryOrder+1] = "Attributes"

		local categoryOrderMap = {}
		for i = 1,#categoryOrder do
			categoryOrderMap[categoryOrder[i]] = i
		end

		return {
			Classes = classes,
			Enums = enums,
			CategoryOrder = categoryOrderMap,
			GetMember = getMember
		}
	end

	Main.FetchRMD = function()
		local rawXML
		if Main.Elevated then
			if Main.LocalDepsUpToDate() then
				local localRMD = Lib.ReadFile("dex/rbx_rmd.dat")
				if localRMD then 
					rawXML = localRMD
				else
					Main.DepsVersionData[1] = ""
				end
			end
			rawXML = rawXML or Main.HttpGet("https://raw.githubusercontent.com/CloneTrooper1019/Roblox-Client-Tracker/roblox/ReflectionMetadata.xml", "Roblox reflection metadata")
		else
			if script:FindFirstChild("RMD") then
				rawXML = require(script.RMD)
			else
				error("NO RMD EXISTS")
			end
		end
		Main.RawRMD = rawXML
		local parsed = Lib.ParseXML(rawXML)
		local classList = parsed.children[1].children[1].children
		local enumList = parsed.children[1].children[2].children
		local propertyOrders = {}

		local classes,enums = {},{}
		for _,class in pairs(classList) do
			local className = ""
			for _,child in pairs(class.children) do
				if child.tag == "Properties" then
					local data = {Properties = {}, Functions = {}}
					local props = child.children
					for _,prop in pairs(props) do
						local name = prop.attrs.name
						name = name:sub(1,1):upper()..name:sub(2)
						data[name] = prop.children[1].text
					end
					className = data.Name
					classes[className] = data
				elseif child.attrs.class == "ReflectionMetadataProperties" then
					local members = child.children
					for _,member in pairs(members) do
						if member.attrs.class == "ReflectionMetadataMember" then
							local data = {}
							if member.children[1].tag == "Properties" then
								local props = member.children[1].children
								for _,prop in pairs(props) do
									if prop.attrs then
										local name = prop.attrs.name
										name = name:sub(1,1):upper()..name:sub(2)
										data[name] = prop.children[1].text
									end
								end
								if data.PropertyOrder then
									local orders = propertyOrders[className]
									if not orders then orders = {} propertyOrders[className] = orders end
									orders[data.Name] = tonumber(data.PropertyOrder)
								end
								classes[className].Properties[data.Name] = data
							end
						end
					end
				elseif child.attrs.class == "ReflectionMetadataFunctions" then
					local members = child.children
					for _,member in pairs(members) do
						if member.attrs.class == "ReflectionMetadataMember" then
							local data = {}
							if member.children[1].tag == "Properties" then
								local props = member.children[1].children
								for _,prop in pairs(props) do
									if prop.attrs then
										local name = prop.attrs.name
										name = name:sub(1,1):upper()..name:sub(2)
										data[name] = prop.children[1].text
									end
								end
								classes[className].Functions[data.Name] = data
							end
						end
					end
				end
			end
		end

		for _,enum in pairs(enumList) do
			local enumName = ""
			for _,child in pairs(enum.children) do
				if child.tag == "Properties" then
					local data = {Items = {}}
					local props = child.children
					for _,prop in pairs(props) do
						local name = prop.attrs.name
						name = name:sub(1,1):upper()..name:sub(2)
						data[name] = prop.children[1].text
					end
					enumName = data.Name
					enums[enumName] = data
				elseif child.attrs.class == "ReflectionMetadataEnumItem" then
					local data = {}
					if child.children[1].tag == "Properties" then
						local props = child.children[1].children
						for _,prop in pairs(props) do
							local name = prop.attrs.name
							name = name:sub(1,1):upper()..name:sub(2)
							data[name] = prop.children[1].text
						end
						enums[enumName].Items[data.Name] = data
					end
				end
			end
		end

		return {Classes = classes, Enums = enums, PropertyOrders = propertyOrders}
	end

	Main.ShowGui = Main.SecureGui

	Main.CreateIntro = function(initStatus) -- TODO: Must theme and show errors
		local gui = create({
			{1,"ScreenGui",{Name="Intro",}},
			{2,"Frame",{Active=true,BackgroundColor3=Color3.new(0.20392157137394,0.20392157137394,0.20392157137394),BorderSizePixel=0,Name="Main",Parent={1},Position=UDim2.new(0.5,-175,0.5,-100),Size=UDim2.new(0,350,0,200),}},
			{3,"Frame",{BackgroundColor3=Color3.new(0.17647059261799,0.17647059261799,0.17647059261799),BorderSizePixel=0,ClipsDescendants=true,Name="Holder",Parent={2},Size=UDim2.new(1,0,1,0),}},
			{4,"UIGradient",{Parent={3},Rotation=30,Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,1,0),NumberSequenceKeypoint.new(1,1,0),}),}},
			{5,"TextLabel",{BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=1,Font=4,Name="Title",Parent={3},Position=UDim2.new(0,-190,0,15),Size=UDim2.new(0,100,0,50),Text="Dex++",TextColor3=Color3.new(1,1,1),TextSize=50,TextTransparency=1,}},
			{6,"TextLabel",{BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=1,Font=3,Name="Desc",Parent={3},Position=UDim2.new(0,-230,0,60),Size=UDim2.new(0,180,0,25),Text="Ultimate Debugging Suite",TextColor3=Color3.new(1,1,1),TextSize=18,TextTransparency=1,}},
			{7,"TextLabel",{BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=1,Font=3,Name="StatusText",Parent={3},Position=UDim2.new(0,20,0,110),Size=UDim2.new(0,180,0,25),Text="Fetching API",TextColor3=Color3.new(1,1,1),TextSize=14,TextTransparency=1,}},
			{8,"Frame",{BackgroundColor3=Color3.new(0.20392157137394,0.20392157137394,0.20392157137394),BorderSizePixel=0,Name="ProgressBar",Parent={3},Position=UDim2.new(0,110,0,145),Size=UDim2.new(0,0,0,4),}},
			{9,"Frame",{BackgroundColor3=Color3.new(0.2392156869173,0.56078433990479,0.86274510622025),BorderSizePixel=0,Name="Bar",Parent={8},Size=UDim2.new(0,0,1,0),}},
			{10,"ImageLabel",{BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=1,Image="rbxassetid://2764171053",ImageColor3=Color3.new(0.17647059261799,0.17647059261799,0.17647059261799),Parent={8},ScaleType=1,Size=UDim2.new(1,0,1,0),SliceCenter=Rect.new(2,2,254,254),}},
			{11,"TextLabel",{BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=1,Font=3,Name="Creator",Parent={2},Position=UDim2.new(1,-110,1,-20),Size=UDim2.new(0,105,0,20),Text="Developed by Chillz.",TextColor3=Color3.new(1,1,1),TextSize=14,TextXAlignment=1,}},
			{12,"UIGradient",{Parent={11},Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,1,0),NumberSequenceKeypoint.new(1,1,0),}),}},
			{13,"TextLabel",{BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=1,Font=3,Name="Version",Parent={2},Position=UDim2.new(1,-110,1,-35),Size=UDim2.new(0,105,0,20),Text=Main.Version,TextColor3=Color3.new(1,1,1),TextSize=14,TextXAlignment=1,}},
			{14,"UIGradient",{Parent={13},Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,1,0),NumberSequenceKeypoint.new(1,1,0),}),}},
			{15,"ImageLabel",{BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=1,BorderSizePixel=0,Image="rbxassetid://1427967925",Name="Outlines",Parent={2},Position=UDim2.new(0,-5,0,-5),ScaleType=1,Size=UDim2.new(1,10,1,10),SliceCenter=Rect.new(6,6,25,25),TileSize=UDim2.new(0,20,0,20),}},
			{16,"UIGradient",{Parent={15},Rotation=-30,Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,1,0),NumberSequenceKeypoint.new(1,1,0),}),}},
			{17,"UIGradient",{Parent={2},Rotation=-30,Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,1,0),NumberSequenceKeypoint.new(1,1,0),}),}},
			{18,"UIDragDetector", {Parent={2}}}
		})
		Main.ShowGui(gui)
		local backGradient = gui.Main.UIGradient
		local outlinesGradient = gui.Main.Outlines.UIGradient
		local holderGradient = gui.Main.Holder.UIGradient
		local titleText = gui.Main.Holder.Title
		local descText = gui.Main.Holder.Desc
		local versionText = gui.Main.Version
		local versionGradient = versionText.UIGradient
		local creatorText = gui.Main.Creator
		local creatorGradient = creatorText.UIGradient
		local statusText = gui.Main.Holder.StatusText
		local progressBar = gui.Main.Holder.ProgressBar
		local tweenS = service.TweenService

		local renderStepped = service.RunService.RenderStepped
		local signalWait = renderStepped.wait
		local fastwait = function(s)
			if not s then return signalWait(renderStepped) end
			local start = tick()
			while tick() - start < s do signalWait(renderStepped) end
		end

		statusText.Text = initStatus

		local function tweenNumber(n,ti,func)
			local tweenVal = Instance.new("IntValue")
			tweenVal.Value = 0
			tweenVal.Changed:Connect(func)
			local tween = tweenS:Create(tweenVal,ti,{Value = n})
			tween:Play()
			tween.Completed:Connect(function()
				tweenVal:Destroy()
			end)
		end

		local ti = TweenInfo.new(0.4,Enum.EasingStyle.Quad,Enum.EasingDirection.Out)
		tweenNumber(100,ti,function(val)
			val = val/200
			local start = NumberSequenceKeypoint.new(0,0)
			local a1 = NumberSequenceKeypoint.new(val,0)
			local a2 = NumberSequenceKeypoint.new(math.min(0.5,val+math.min(0.05,val)),1)
			if a1.Time == a2.Time then a2 = a1 end
			local b1 = NumberSequenceKeypoint.new(1-val,0)
			local b2 = NumberSequenceKeypoint.new(math.max(0.5,1-val-math.min(0.05,val)),1)
			if b1.Time == b2.Time then b2 = b1 end
			local goal = NumberSequenceKeypoint.new(1,0)
			backGradient.Transparency = NumberSequence.new({start,a1,a2,b2,b1,goal})
			outlinesGradient.Transparency = NumberSequence.new({start,a1,a2,b2,b1,goal})
		end)

		fastwait(0.4)

		tweenNumber(100,ti,function(val)
			val = val/166.66
			local start = NumberSequenceKeypoint.new(0,0)
			local a1 = NumberSequenceKeypoint.new(val,0)
			local a2 = NumberSequenceKeypoint.new(val+0.01,1)
			local goal = NumberSequenceKeypoint.new(1,1)
			holderGradient.Transparency = NumberSequence.new({start,a1,a2,goal})
		end)

		tweenS:Create(titleText,ti,{Position = UDim2.new(0,60,0,15), TextTransparency = 0}):Play()
		tweenS:Create(descText,ti,{Position = UDim2.new(0,20,0,60), TextTransparency = 0}):Play()

		local function rightTextTransparency(obj)
			tweenNumber(100,ti,function(val)
				val = val/100
				local a1 = NumberSequenceKeypoint.new(1-val,0)
				local a2 = NumberSequenceKeypoint.new(math.max(0,1-val-0.01),1)
				if a1.Time == a2.Time then a2 = a1 end
				local start = NumberSequenceKeypoint.new(0,a1 == a2 and 0 or 1)
				local goal = NumberSequenceKeypoint.new(1,0)
				obj.Transparency = NumberSequence.new({start,a2,a1,goal})
			end)
		end
		rightTextTransparency(versionGradient)
		rightTextTransparency(creatorGradient)

		fastwait(0.9)

		local progressTI = TweenInfo.new(0.25,Enum.EasingStyle.Quad,Enum.EasingDirection.Out)

		tweenS:Create(statusText,progressTI,{Position = UDim2.new(0,20,0,120), TextTransparency = 0}):Play()
		tweenS:Create(progressBar,progressTI,{Position = UDim2.new(0,60,0,145), Size = UDim2.new(0,100,0,4)}):Play()

		fastwait(0.25)

		local function setProgress(text,n)
			statusText.Text = text
			tweenS:Create(progressBar.Bar,progressTI,{Size = UDim2.new(n,0,1,0)}):Play()
		end

		local function close()
			tweenS:Create(titleText,progressTI,{TextTransparency = 1}):Play()
			tweenS:Create(descText,progressTI,{TextTransparency = 1}):Play()
			tweenS:Create(versionText,progressTI,{TextTransparency = 1}):Play()
			tweenS:Create(creatorText,progressTI,{TextTransparency = 1}):Play()
			tweenS:Create(statusText,progressTI,{TextTransparency = 1}):Play()
			tweenS:Create(progressBar,progressTI,{BackgroundTransparency = 1}):Play()
			tweenS:Create(progressBar.Bar,progressTI,{BackgroundTransparency = 1}):Play()
			tweenS:Create(progressBar.ImageLabel,progressTI,{ImageTransparency = 1}):Play()

			tweenNumber(100,TweenInfo.new(0.4,Enum.EasingStyle.Back,Enum.EasingDirection.In),function(val)
				val = val/250
				local start = NumberSequenceKeypoint.new(0,0)
				local a1 = NumberSequenceKeypoint.new(0.6+val,0)
				local a2 = NumberSequenceKeypoint.new(math.min(1,0.601+val),1)
				if a1.Time == a2.Time then a2 = a1 end
				local goal = NumberSequenceKeypoint.new(1,a1 == a2 and 0 or 1)
				holderGradient.Transparency = NumberSequence.new({start,a1,a2,goal})
			end)

			fastwait(0.5)
			gui.Main.BackgroundTransparency = 1
			outlinesGradient.Rotation = 30

			tweenNumber(100,ti,function(val)
				val = val/100
				local start = NumberSequenceKeypoint.new(0,1)
				local a1 = NumberSequenceKeypoint.new(val,1)
				local a2 = NumberSequenceKeypoint.new(math.min(1,val+math.min(0.05,val)),0)
				if a1.Time == a2.Time then a2 = a1 end
				local goal = NumberSequenceKeypoint.new(1,a1 == a2 and 1 or 0)
				outlinesGradient.Transparency = NumberSequence.new({start,a1,a2,goal})
				holderGradient.Transparency = NumberSequence.new({start,a1,a2,goal})
			end)

			fastwait(0.45)
			gui:Destroy()
		end

		return {SetProgress = setProgress, Close = close, Object = gui}
	end

	Main.CreateApp = function(data)
		if Main.MenuApps[data.Name] then return end -- TODO: Handle conflict
		local control = {}

		local app = Main.AppTemplate:Clone()

		local iconIndex = data.Icon
		if data.IconMap and iconIndex then
			if type(iconIndex) == "number" then
				data.IconMap:Display(app.Main.Icon,iconIndex)
			elseif type(iconIndex) == "string" then
				data.IconMap:DisplayByKey(app.Main.Icon,iconIndex)
			end
		elseif type(iconIndex) == "string" then
			app.Main.Icon.Image = iconIndex
		else
			app.Main.Icon.Image = ""
		end

		local function updateState()
			app.Main.BackgroundTransparency = data.Open and 0 or (Lib.CheckMouseInGui(app.Main) and 0 or 1)
			app.Main.Highlight.Visible = data.Open
		end

		local function enable(silent)
			if data.Open then return end
			data.Open = true
			updateState()
			if not silent then
				if data.Window then data.Window:Show() end
				if data.OnClick then data.OnClick(data.Open) end
			end
		end

		local function disable(silent)
			if not data.Open then return end
			data.Open = false
			updateState()
			if not silent then
				if data.Window then data.Window:Hide() end
				if data.OnClick then data.OnClick(data.Open) end
			end
		end

		updateState()

		local ySize = service.TextService:GetTextSize(data.Name,14,Enum.Font.SourceSans,Vector2.new(62,999999)).Y
		app.Main.Size = UDim2.new(1,0,0,math.clamp(46+ySize,60,74))
		app.Main.AppName.Text = data.Name

		app.Main.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
				app.Main.BackgroundTransparency = 0
				app.Main.BackgroundColor3 = Settings.Theme.ButtonHover
			end
		end)
		

		app.Main.InputEnded:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
				app.Main.BackgroundTransparency = data.Open and 0 or 1
				app.Main.BackgroundColor3 = Settings.Theme.Button
			end
		end)

		app.Main.MouseButton1Click:Connect(function()
			if data.Open then disable() else enable() end
		end)

		local window = data.Window
		if window then
			window.OnActivate:Connect(function() enable(true) end)
			window.OnDeactivate:Connect(function() disable(true) end)
		end

		app.Visible = true
		app.Parent = Main.AppsContainer
		Main.AppsFrame.CanvasSize = UDim2.new(0,0,0,Main.AppsContainerGrid.AbsoluteCellCount.Y*82 + 8)

		control.Enable = enable
		control.Disable = disable
		Main.MenuApps[data.Name] = control
		return control
	end

	Main.SetMainGuiOpen = function(val)
		Main.MainGuiOpen = val

		Main.MainGui.OpenButton.Text = val and "Close" or "Dex++"
		if val then Main.MainGui.OpenButton.MainFrame.Visible = true end
		Main.MainGui.OpenButton.MainFrame:TweenSize(val and UDim2.new(0,224,0,200) or UDim2.new(0,0,0,0),Enum.EasingDirection.Out,Enum.EasingStyle.Quad,0.2,true)
		--Main.MainGui.OpenButton.BackgroundTransparency = val and 0 or (Lib.CheckMouseInGui(Main.MainGui.OpenButton) and 0 or 0.2)
		service.TweenService:Create(Main.MainGui.OpenButton,TweenInfo.new(0.2,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{BackgroundTransparency = val and 0 or (Lib.CheckMouseInGui(Main.MainGui.OpenButton) and 0 or 0.2)}):Play()

		if Main.MainGuiMouseEvent then Main.MainGuiMouseEvent:Disconnect() end

		if not val then
			local startTime = tick()
			Main.MainGuiCloseTime = startTime
			coroutine.wrap(function()
				Lib.FastWait(0.2)
				if not Main.MainGuiOpen and startTime == Main.MainGuiCloseTime then Main.MainGui.OpenButton.MainFrame.Visible = false end
			end)()
		else
			Main.MainGuiMouseEvent = service.UserInputService.InputBegan:Connect(function(input)
				if (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) and not Lib.CheckMouseInGui(Main.MainGui.OpenButton) and not Lib.CheckMouseInGui(Main.MainGui.OpenButton.MainFrame) then

					Main.SetMainGuiOpen(false)
				end
			end)
		end
	end

	Main.CreateMainGui = function()
		local gui = create({
			{1,"ScreenGui",{IgnoreGuiInset=true,Name="MainMenu",}},
			{2,"TextButton",{AnchorPoint=Vector2.new(0.5,0),AutoButtonColor=false,BackgroundColor3=Color3.new(0.17647059261799,0.17647059261799,0.17647059261799),BorderSizePixel=0,Font=4,Name="OpenButton",Parent={1},Position=UDim2.new(0.5,0,0,2),Size=UDim2.new(0,55,0,32),Text="Dex++",TextColor3=Color3.new(1,1,1),TextSize=16,TextTransparency=0.20000000298023,}},
			{3,"UICorner",{CornerRadius=UDim.new(0,4),Parent={2},}},
			{4,"Frame",{AnchorPoint=Vector2.new(0.5,0),BackgroundColor3=Color3.new(0.17647059261799,0.17647059261799,0.17647059261799),ClipsDescendants=true,Name="MainFrame",Parent={2},Position=UDim2.new(0.5,0,1,-4),Size=UDim2.new(0,224,0,200),}},
			{5,"UICorner",{CornerRadius=UDim.new(0,4),Parent={4},}},
			{6,"Frame",{BackgroundColor3=Color3.new(0.20392157137394,0.20392157137394,0.20392157137394),Name="BottomFrame",Parent={4},Position=UDim2.new(0,0,1,-24),Size=UDim2.new(1,0,0,24),}},
			{7,"UICorner",{CornerRadius=UDim.new(0,4),Parent={6},}},
			{8,"Frame",{BackgroundColor3=Color3.new(0.20392157137394,0.20392157137394,0.20392157137394),BorderSizePixel=0,Name="CoverFrame",Parent={6},Size=UDim2.new(1,0,0,4),}},
			{9,"Frame",{BackgroundColor3=Color3.new(0.1294117718935,0.1294117718935,0.1294117718935),BorderSizePixel=0,Name="Line",Parent={8},Position=UDim2.new(0,0,0,-1),Size=UDim2.new(1,0,0,1),}},
			{10,"TextButton",{BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=1,Font=3,Name="Settings",Parent={6},Position=UDim2.new(1,-48,0,0),Size=UDim2.new(0,24,1,0),Text="",TextColor3=Color3.new(1,1,1),TextSize=14,}},
			{11,"ImageLabel",{BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=1,Image="rbxassetid://6578871732",ImageTransparency=0.20000000298023,Name="Icon",Parent={10},Position=UDim2.new(0,4,0,4),Size=UDim2.new(0,16,0,16),}},
			{12,"TextButton",{BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=1,Font=3,Name="Information",Parent={6},Position=UDim2.new(1,-24,0,0),Size=UDim2.new(0,24,1,0),Text="",TextColor3=Color3.new(1,1,1),TextSize=14,}},
			{13,"ImageLabel",{BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=1,Image="rbxassetid://6578933307",ImageTransparency=0.20000000298023,Name="Icon",Parent={12},Position=UDim2.new(0,4,0,4),Size=UDim2.new(0,16,0,16),}},
			{14,"ScrollingFrame",{Active=true,AnchorPoint=Vector2.new(0.5,0),BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=1,BorderColor3=Color3.new(0.1294117718935,0.1294117718935,0.1294117718935),BorderSizePixel=0,Name="AppsFrame",Parent={4},Position=UDim2.new(0.5,0,0,0),ScrollBarImageColor3=Color3.new(0,0,0),ScrollBarThickness=4,Size=UDim2.new(0,222,1,-25),}},
			{15,"Frame",{BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=1,Name="Container",Parent={14},Position=UDim2.new(0,7,0,8),Size=UDim2.new(1,-14,0,2),}},
			{16,"UIGridLayout",{CellSize=UDim2.new(0,66,0,74),Parent={15},SortOrder=2,}},
			{17,"Frame",{BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=1,Name="App",Parent={1},Size=UDim2.new(0,100,0,100),Visible=false,}},
			{18,"TextButton",{AutoButtonColor=false,BackgroundColor3=Color3.new(0.2352941185236,0.2352941185236,0.2352941185236),BorderSizePixel=0,Font=3,Name="Main",Parent={17},Size=UDim2.new(1,0,0,60),Text="",TextColor3=Color3.new(0,0,0),TextSize=14,}},
			{19,"ImageLabel",{BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=1,Image="rbxassetid://129589545519436",ImageRectSize=Vector2.new(32,32),Name="Icon",Parent={18},Position=UDim2.new(0.5,-16,0,4),ScaleType=4,Size=UDim2.new(0,32,0,32),}},
			{20,"TextLabel",{BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=1,BorderSizePixel=0,Font=3,Name="AppName",Parent={18},Position=UDim2.new(0,2,0,38),Size=UDim2.new(1,-4,1,-40),Text="Explorer",TextColor3=Color3.new(1,1,1),TextSize=14,TextTransparency=0.10000000149012,TextTruncate=1,TextWrapped=true,TextYAlignment=0,}},
			{21,"Frame",{BackgroundColor3=Color3.new(0,0.66666668653488,1),BorderSizePixel=0,Name="Highlight",Parent={18},Position=UDim2.new(0,0,1,-2),Size=UDim2.new(1,0,0,2),}},
		})
		Main.MainGui = gui
		Main.AppsFrame = gui.OpenButton.MainFrame.AppsFrame
		Main.AppsContainer = Main.AppsFrame.Container
		Main.AppsContainerGrid = Main.AppsContainer.UIGridLayout
		Main.AppTemplate = gui.App
		Main.MainGuiOpen = false

		local openButton = gui.OpenButton
		openButton.BackgroundTransparency = 0.2
		openButton.MainFrame.Size = UDim2.new(0,0,0,0)
		openButton.MainFrame.Visible = false
		openButton.MouseButton1Click:Connect(function()
			Main.SetMainGuiOpen(not Main.MainGuiOpen)
		end)

		openButton.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
				service.TweenService:Create(Main.MainGui.OpenButton,TweenInfo.new(0,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{BackgroundTransparency = 0}):Play()
			end
		end)

		openButton.InputEnded:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
				service.TweenService:Create(Main.MainGui.OpenButton,TweenInfo.new(0,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{BackgroundTransparency = Main.MainGuiOpen and 0 or 0.2}):Play()
			end
		end)
		
		local infoDexIntro, isInfoCD
		
		--openButton.MainFrame.BottomFrame.Settings.Visible = false
		
		openButton.MainFrame.BottomFrame.Settings.MouseButton1Click:Connect(function()
			if not SettingsWindow.Window.Closed then
				SettingsWindow.Window:Hide()
			else
				SettingsWindow.Window:Show()
			end		
		end)
		
		openButton.MainFrame.BottomFrame.Information.MouseButton1Click:Connect(function()
			local duration = 1
			local Infos = {
				"Contributors >>",
				"Toon (IY Dex and PRs)",
				"Moon (Dex)",
				"Cazan (3D Preview)",
			}
			
			if isInfoCD then return end
			isInfoCD = true
			if not infoDexIntro then
				infoDexIntro = Main.CreateIntro("Running")
				--Main.AppControls ~= {}
				coroutine.wrap(function()
					while infoDexIntro and openButton.Parent ~= nil do
						for i,text in Infos do
							if not infoDexIntro or openButton.Parent == nil then break end
							infoDexIntro.SetProgress(text,(1 / #Infos) * i)
							task.wait(duration)
						end
					end
				end)()
				
				Lib.FastWait(1.5)
				isInfoCD = false
			else
				coroutine.wrap(function()
					infoDexIntro.Close()
					infoDexIntro = nil
					
					Lib.FastWait(1.5)
					isInfoCD = false
				end)()
			end
		end)

		-- Create Main Apps
		Main.CreateApp({Name = "Explorer", IconMap = Main.LargeIcons, Icon = "Explorer", Open = true, Window = Explorer.Window})

		Main.CreateApp({Name = "Properties", IconMap = Main.LargeIcons, Icon = "Properties", Open = true, Window = Properties.Window})

		local cptsOnMouseClick = nil
		Main.CreateApp({Name = "Click part to select", IconMap = Explorer.ClassIcons, Icon = "SelectionBox", OnClick = function(callback)
			if callback then
				local mouse = Main.Mouse
				cptsOnMouseClick = mouse.Button1Down:Connect(function()
					pcall(function()
						local object = mouse.Target
						if nodes[object] then
							selection:Set(nodes[object])
							Explorer.ViewNode(nodes[object])
						end
					end)
				end)
			else if cptsOnMouseClick ~= nil then cptsOnMouseClick:Disconnect() cptsOnMouseClick = nil end end
		end})

		Main.CreateApp({Name = "Notepad", IconMap = Main.LargeIcons, Icon = "Script_Viewer", Window = ScriptViewer.Window})
		
		Main.CreateApp({Name = "Console", IconMap = Main.LargeIcons, Icon = "Executor", Window = Console.Window})
		
		Main.CreateApp({Name = "Save Instance", IconMap = Main.LargeIcons, Icon = "Book", Window = SaveInstance.Window})
		
		Main.CreateApp({Name = "3D Viewer", IconMap = Main.LargeIcons, Icon = "Object", Window = ModelViewer.Window})

		--Main.CreateApp({Name = "Secret Service Panel", IconMap = Main.LargeIcons, Icon = "Output", Window = SecretServicePanel.Window})
		
		for _, loadedplugin in pairs(Main.Plugins) do
			Main.CreateApp({Name = loadedplugin.PluginData.FriendlyName, IconMap = Explorer.ClassIcons, Icon = "Attachment", Window = loadedplugin.Window})
		end
		
		Lib.ShowGui(gui)
	end

	Main.SetupFilesystem = function()
		if not env.writefile or not env.makefolder then return end

		for _, folder in ipairs({"dex", "dex/assets", "dex/saved", "dex/plugins", "dex/ModuleCache"}) do
			local ok, message = env.ensurefolder(folder)
			if not ok then warn("Dex++ filesystem warning: " .. tostring(message)) end
		end
		if Settings.Save.CreateFolders then
			local ok, message = env.ensurefolder(Settings.Save.Folder)
			if not ok then warn("Dex++ save folder warning: " .. tostring(message)) end
		end
	end

	Main.SaveCurrentSettings = function()
		if not env.writefile then return false, "writefile is unavailable" end
		local json = Main.ExportSettings()
		if not json then return false, "settings could not be encoded" end
		local ok, message = pcall(env.writefile, "DexPlusPlusSettings.json", json)
		return ok, message
	end

	Main.LocalDepsUpToDate = function()
		return Main.DepsVersionData and Main.ClientVersion == Main.DepsVersionData[1]
	end

	Main.Init = function()
		Main.IsRunning = true
		Main.ShuttingDown = false
		Main.Elevated = pcall(function() local a = game:GetService("CoreGui"):GetFullName() end)

		Main.InitEnv()
		Main.LoadSettings() -- loads the settings before init

		Main.SetupFilesystem()
		-- Save only after defaults and the executor filesystem were initialized.
		if env.isfile then
			local checked, exists = pcall(env.isfile, "DexPlusPlusSettings.json")
			if checked and not exists then Main.SaveCurrentSettings() end
		end

		-- Load Lib
		local intro = Main.CreateIntro("Initializing Library")
		Lib = Main.LoadModule("Lib")
		Lib.FastWait()

		-- Init icons
		Main.MiscIcons = Lib.IconMap.new("rbxassetid://6511490623",256,256,16,16)
		Main.MiscIcons:SetDict({
			Reference = 0,             Cut = 1,                         Cut_Disabled = 2,      Copy = 3,               Copy_Disabled = 4,    Paste = 5,                Paste_Disabled = 6,
			Delete = 7,                Delete_Disabled = 8,             Group = 9,             Group_Disabled = 10,    Ungroup = 11,         Ungroup_Disabled = 12,    TeleportTo = 13,
			Rename = 14,               JumpToParent = 15,               ExploreData = 16,      Save = 17,              CallFunction = 18,    CallRemote = 19,          Undo = 20,
			Undo_Disabled = 21,        Redo = 22,                       Redo_Disabled = 23,    Expand_Over = 24,       Expand = 25,          Collapse_Over = 26,       Collapse = 27,
			SelectChildren = 28,       SelectChildren_Disabled = 29,    InsertObject = 30,     ViewScript = 31,        AddStar = 32,         RemoveStar = 33,          Script_Disabled = 34,
			LocalScript_Disabled = 35, Play = 36,                       Pause = 37,            Rename_Disabled = 38,   Empty = 1000
		})
		Main.LargeIcons = Lib.IconMap.new("rbxassetid://129589545519436",256,256,32,32)
		Main.LargeIcons:SetDict({
			Explorer = 0, Properties = 1, Script_Viewer = 2, Watcher = 3, Output = 4, ScriptEdit = 5, Book = 6, Executor = 7, Object = 8, Honey = 9
		})
		
		--[[ Loading bypasses
		intro.SetProgress("Loading Adonis Bypass",0.1)
		pcall(Main.LoadAdonisBypass)
		
		intro.SetProgress("Loading GC Bypass",0.2)
		pcall(Main.LoadGCBypass)]]

		-- Fetch version if needed
		intro.SetProgress("Fetching Roblox Version",0.3)
		if Main.Elevated then
			local fileVer = Lib.ReadFile("dex/deps_version.dat")
			Main.ClientVersion = Version()
			if fileVer then
				Main.DepsVersionData = string.split(fileVer,"\n")
				if Main.LocalDepsUpToDate() then
					Main.RobloxVersion = Main.DepsVersionData[2]
				end
			end
			
			Main.RobloxVersion = Main.RobloxVersion or Main.HttpGet("https://clientsettings.roblox.com/v2/client-version/WindowsStudio64/channel/LIVE", "Roblox Studio version"):match("(version%-[%w]+)")
			if not Main.RobloxVersion then Main.Error("Roblox Studio version response was invalid") end
		end

		-- Fetch external deps
		intro.SetProgress("Fetching API",0.35)
		API = Main.FetchAPI(
			function()
				intro.SetProgress("Fetching API, Please Wait.",0.4)
			end,
			function()
				intro.SetProgress("Fetching API, Please Wait Due To Huge API File To Download.",0.45)
			end,
			function()
				intro.SetProgress("Fetching API, LOL STILL DOWNlOADING? bad wifi xD",0.475)
			end
		)
		Lib.FastWait()
		intro.SetProgress("Fetching RMD",0.5)
		RMD = Main.FetchRMD()
		Lib.FastWait()

		-- Save external deps locally if needed
		if Main.Elevated and env.writefile and not Main.ApiUsingStaleCache and (not Main.LocalDepsUpToDate() or Main.ApiCacheNeedsRefresh) then
			pcall(env.writefile,"dex/deps_version.dat",Main.ClientVersion.."\n"..Main.RobloxVersion)
			pcall(env.writefile,"dex/rbx_api.dat",Main.RawAPI)
			pcall(env.writefile,"dex/rbx_rmd.dat",Main.RawRMD)
		end

		-- Load other modules
		intro.SetProgress("Loading Modules",0.75)
		Main.AppControls.Lib.InitDeps(Main.GetInitDeps()) -- Missing deps now available
		Main.LoadModules()
		Lib.FastWait()

		-- Init other modules
		intro.SetProgress("Initializing Modules",0.8)
		Explorer.Init()
		Properties.Init()
		ScriptViewer.Init()
		Console.Init()
		SaveInstance.Init()
		ModelViewer.Init()
		SettingsWindow.Init()
		--SecretServicePanel.Init()
		
		
		if env.readfile and listfiles then
			if #listfiles("dex/plugins") > 0 then
				intro.SetProgress("Loading Plugin Files",0.8)
				for _, pluginDir in pairs(listfiles("dex/plugins")) do
					local moduleData = Main.LoadPluginFile(pluginDir)
					moduleData.PluginData = moduleData.PluginData or {}

					moduleData.Init()

					local pluginFriendlyName = moduleData.PluginData.FriendlyName or moduleData.Window.GuiElems.Title.Text or "Unnamed Plugin"
					local pluginName = moduleData.PluginData.Name or moduleData.Window.GuiElems.Title.Text:gsub(" ", "") or "unnamedPlugin"

					intro.SetProgress("Initializing Plugin: ".. pluginFriendlyName,0.9)

					moduleData.PluginData.Name = pluginName
					moduleData.PluginData.FriendlyName = pluginFriendlyName

					table.insert(Main.Plugins, moduleData)
				end
			end	
		end
		
		
		Lib.FastWait()

		-- Done
		intro.SetProgress("Complete",1)
		coroutine.wrap(function()
			Lib.FastWait(1.25)
			intro.Close()
		end)()

		-- Init window system, create main menu, show explorer and properties
		Lib.Window.Init()
		Main.CreateMainGui()
		Explorer.Window:Show({Align = "right", Pos = 1, Size = 0.5, Silent = true})
		Properties.Window:Show({Align = "right", Pos = 2, Size = 0.5, Silent = true})
		
		Lib.DeferFunc(function() Lib.Window.ToggleSide("right") end)
	end
	
	Main.Uninit = function()
		if Main.ShuttingDown then return true end
		Main.ShuttingDown = true
		Main.IsRunning = false

		if Main.MainGuiMouseEvent then
			pcall(Main.MainGuiMouseEvent.Disconnect, Main.MainGuiMouseEvent)
			Main.MainGuiMouseEvent = nil
		end

		for _, app in pairs(Apps) do
			if type(app) == "table" and type(app.Uninit) == "function" then
				pcall(app.Uninit)
			end
		end
		table.clear(Apps)

		Main.MenuApps = {}
		Main.AppControls = {}
		Main.Plugins = {}
		local containerOk, container = pcall(Main.GetSecureContainer)
		if containerOk and typeof(container) == "Instance" then
			for _, gui in pairs(container:GetChildren()) do
				if string.sub(gui.Name,1,5) == "_DPP_" then -- DPP stands for DexPlusPlus
					pcall(gui.Destroy, gui)
				end
			end
		end

		local statusGui = DPP_GLOBAL_ENV and rawget(DPP_GLOBAL_ENV, "USSI_statustext")
		if typeof(statusGui) == "Instance" then pcall(statusGui.Destroy, statusGui) end
		if DPP_GLOBAL_ENV then
			DPP_GLOBAL_ENV.USSI_statustext = nil
			DPP_GLOBAL_ENV.USSI = nil
			DPP_GLOBAL_ENV.DEXPLUSPLUS_RUNNING = nil
			DPP_GLOBAL_ENV.DEXPLUSPLUS_CLOSE = nil
		end

		destroyOrphanedDexGuis()
		Main.ShuttingDown = false
		return true
	end

	Main.SafeInit = function()
		local started, startupError = xpcall(Main.Init, function(message)
			return debug.traceback(tostring(message), 2)
		end)
		if not started then
			pcall(Main.Uninit, "startup-error")
			error("Dex++ failed to start:\n" .. tostring(startupError), 0)
		end
		return true
	end

	Main.Reinit = function()
		Main.Uninit()
		task.wait()
		DPP_GLOBAL_ENV.DEXPLUSPLUS_RUNNING = Main.Version
		DPP_GLOBAL_ENV.DEXPLUSPLUS_CLOSE = function(reason)
			return Main.Uninit(reason)
		end
		return Main.SafeInit()
	end

	return Main
end)()

-- Start
DPP_GLOBAL_ENV.DEXPLUSPLUS_RUNNING = Main.Version
DPP_GLOBAL_ENV.DEXPLUSPLUS_CLOSE = function(reason)
	return Main.Uninit(reason)
end
Main.SafeInit()

--for i,v in pairs(Main.MissingEnv) do print(i,v) end

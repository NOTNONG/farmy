if not _G.farmConfig then
	--default
	_G.farmConfig = {
		tpOffset = CFrame.new(0, 17, 0) * CFrame.Angles(math.rad(-90), 0, 0),
		hitboxDistance = CFrame.new(0, 0, -8.5),
		hpFilterUsePercentage = false,
		sellAt = 1,
		serverWhitelist = {},
		skinWhitelist = {
			"Mythic",
		},
		skinWhitelistName = {},
		modeKeys = {
			J = "stopped",
			K = "curses",
			L = "lostSwords",
		},
		--{"Q", "Press"}
		loopKeys = {
			"E",
			"T",
			"MOUSEBUTTON1",
		},
		standOnKeys = {
			"E",
			"R",
			"Y",
			"G",
			"V",
			"B",
			"MOUSEBUTTON1",
			"Q",
		},
	}
end

if game.PlaceId ~= 6846458508 then
	return
end

--selene: allow(undefined_variable, unused_variable)
local print, stringify, rconsoleclear, isfile, readfile, writefile, rconsoleprint =
	print, nil, rconsoleclear, isfile, readfile, writefile, rconsoleprint
do
	rconsoleclear()
	if isfile("stringify") then
		stringify = loadstring(readfile("stringify"))()
		print = function(...)
			local args = { ... }
			local result = {}
			for _, v in pairs(args) do
				if type(v) ~= "string" then
					v = stringify(v)
				end
				table.insert(result, v)
			end
			rconsoleprint(`  {table.concat(result, " ")}`)
		end
	end
end

--selene:allow(undefined_variable)
local firesignal, fireproximityprompt, hookmetamethod, getconnections =
	firesignal, fireproximityprompt, hookmetamethod, getconnections

--services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VirtualUser = game:GetService("VirtualUser")
local CoreGui = game:GetService("CoreGui")
local GuiService = game:GetService("GuiService")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")

--connections
do
	if _G.farmConnections then
		for _, v in pairs(_G.farmConnections) do
			v:Disconnect()
		end
	end
	_G.farmConnections = {}
end
local function addConn(connection)
	table.insert(_G.farmConnections, connection)
	return connection
end

--player
local localPlayer
while not localPlayer do
	RunService.Heartbeat:Wait()
	localPlayer = Players.LocalPlayer
end

--character
local character
local root
do
	local function characterAdded(new)
		character = new
		task.spawn(function()
			root = character:WaitForChild("HumanoidRootPart", 10)
		end)
	end

	if localPlayer.Character then
		characterAdded(localPlayer.Character)
	end
	addConn(localPlayer.CharacterAdded:Connect(characterAdded))
	addConn(localPlayer.CharacterRemoving:Connect(function()
		character = nil
		root = nil
	end))
end

local function teleport(pos)
	if not root then
		return
	end
	root.CFrame = if typeof(pos) == "Vector3" then CFrame.new(pos) else pos
	root.AssemblyLinearVelocity = Vector3.zero
	root.AssemblyAngularVelocity = Vector3.zero
end

--aut stuff
local ascensions = 0
local combatTagged = false

local ui = localPlayer.PlayerGui:WaitForChild("UI")
local traitHandPrompt = ui.Gameplay.TraitHandPrompt
local modules = ReplicatedStorage:WaitForChild("ReplicatedModules")
local living = workspace:WaitForChild("Living")
local data = localPlayer:WaitForChild("Data")
local knitServices = modules:WaitForChild("KnitPackage"):WaitForChild("Knit"):WaitForChild("Services")
local levelService = knitServices:WaitForChild("LevelService")
--local moveService = knitServices:WaitForChild("MoveService")
local traitService = knitServices:WaitForChild("TraitService")
local shopService = knitServices:WaitForChild("ShopService")
local inventoryService = knitServices:WaitForChild("InventoryService")
local fireInput = knitServices:WaitForChild("MoveInputService"):WaitForChild("RF"):WaitForChild("FireInput")
--[[local getMovesInfo = moveService:WaitForChild("RF"):WaitForChild("GetMovesInfo")
local getKeyMap = moveService:WaitForChild("RF"):WaitForChild("GetKeybindsMap")
local equipMove = moveService:WaitForChild("RF"):WaitForChild("EquipMove")--]]
local locations = {
	desert = CFrame.new(1982, 928, -1573),
	park = CFrame.new(2096, 974, 287),
	dealer = {
		CFrame.new(2454, 982, 119), --station
		CFrame.new(2051, 922, 1062), --port
		CFrame.new(2035, 1063, -781), --desert
		CFrame.new(950, 1009, -459), --village
	},
}

--modules
local itemData = require(modules.ItemData)
local traits = require(modules.PVEPackage.TraitHandler).Traits
--[[local stands = require(modules.Stands)
local skins = require(modules.Skins).Skins--]]

--convert configs
local playerWhitelist = {}
local skinWhitelist = {}
local skinWhitelistName = {}

--set index table for whitelists
do
	for _, name in pairs(_G.farmConfig.skinWhitelist) do
		local id
		for thisId, v in pairs(itemData.Rarities) do
			if v.Name == name then
				id = thisId
			end
		end
		skinWhitelist[id] = true
	end
	for _, name in pairs(_G.farmConfig.skinWhitelistName) do
		skinWhitelistName[name] = true
	end
	for _, name in pairs(_G.farmConfig.serverWhitelist) do
		playerWhitelist[name] = true
	end
end

--script ui creation
if CoreGui:FindFirstChild("cheatt") then
	CoreGui.cheatt:Destroy()
end
do
	local cheatt = Instance.new("ScreenGui")
	cheatt.Name = "cheatt"
	cheatt.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	cheatt.Parent = CoreGui

	local hidden = Instance.new("Frame")
	hidden.Name = "Hidden"
	hidden.AnchorPoint = Vector2.new(0.5, 0.5)
	hidden.BackgroundColor3 = Color3.fromRGB(44, 44, 44)
	hidden.BackgroundTransparency = 1
	hidden.BorderColor3 = Color3.fromRGB(0, 0, 0)
	hidden.BorderSizePixel = 0
	hidden.Position = UDim2.fromScale(1, 1)
	hidden.Size = UDim2.fromScale(0.2, 0.2)

	local uIAspectRatioConstraint = Instance.new("UIAspectRatioConstraint")
	uIAspectRatioConstraint.Name = "UIAspectRatioConstraint"
	uIAspectRatioConstraint.Parent = hidden

	local uICorner = Instance.new("UICorner")
	uICorner.Name = "UICorner"
	uICorner.CornerRadius = UDim.new(1, 0)
	uICorner.Parent = hidden

	hidden.Parent = cheatt

	local main = Instance.new("Frame")
	main.Name = "Main"
	main.AnchorPoint = Vector2.new(0.5, 0.5)
	main.BackgroundColor3 = Color3.fromRGB(44, 44, 44)
	main.BorderColor3 = Color3.fromRGB(0, 0, 0)
	main.BorderSizePixel = 0
	main.ClipsDescendants = true
	main.Position = UDim2.fromScale(0.5, 0.5)
	main.Size = UDim2.fromScale(0.9, 0.9)

	local uIAspectRatioConstraint1 = Instance.new("UIAspectRatioConstraint")
	uIAspectRatioConstraint1.Name = "UIAspectRatioConstraint"
	uIAspectRatioConstraint1.AspectRatio = 3.3
	uIAspectRatioConstraint1.Parent = main

	local uIStroke = Instance.new("UIStroke")
	uIStroke.Name = "UIStroke"
	uIStroke.Color = Color3.fromRGB(255, 255, 255)
	uIStroke.LineJoinMode = Enum.LineJoinMode.Miter
	uIStroke.Thickness = 2
	uIStroke.Transparency = 0.75
	uIStroke.Parent = main

	local pages = Instance.new("Frame")
	pages.Name = "Pages"
	pages.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	pages.BackgroundTransparency = 1
	pages.BorderColor3 = Color3.fromRGB(0, 0, 0)
	pages.BorderSizePixel = 0
	pages.Size = UDim2.fromScale(1, 1)

	local holder = Instance.new("Frame")
	holder.Name = "Holder"
	holder.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	holder.BackgroundTransparency = 1
	holder.BorderColor3 = Color3.fromRGB(0, 0, 0)
	holder.BorderSizePixel = 0
	holder.ClipsDescendants = true
	holder.LayoutOrder = 1
	holder.Size = UDim2.fromScale(1, 1)
	holder.ZIndex = 2

	local switches = Instance.new("Frame")
	switches.Name = "switches"
	switches.AnchorPoint = Vector2.new(0.5, 0.5)
	switches.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	switches.BackgroundTransparency = 1
	switches.BorderColor3 = Color3.fromRGB(0, 0, 0)
	switches.BorderSizePixel = 0
	switches.Position = UDim2.fromScale(0.5, 0.5)
	switches.Size = UDim2.fromScale(1, 1)

	local uIGridLayout = Instance.new("UIGridLayout")
	uIGridLayout.Name = "UIGridLayout"
	uIGridLayout.CellPadding = UDim2.fromScale(0.006, 0.02)
	uIGridLayout.CellSize = UDim2.fromScale(0.4, 0.235)
	uIGridLayout.FillDirection = Enum.FillDirection.Vertical
	uIGridLayout.SortOrder = Enum.SortOrder.LayoutOrder
	uIGridLayout.Parent = switches

	local template = Instance.new("Frame")
	template.Name = "template"
	template.BackgroundColor3 = Color3.fromRGB(31, 31, 31)
	template.BorderColor3 = Color3.fromRGB(0, 0, 0)
	template.BorderSizePixel = 0
	template.Visible = false

	local uIStroke1 = Instance.new("UIStroke")
	uIStroke1.Name = "UIStroke"
	uIStroke1.Color = Color3.fromRGB(39, 39, 39)
	uIStroke1.LineJoinMode = Enum.LineJoinMode.Miter
	uIStroke1.Thickness = 2
	uIStroke1.Parent = template

	local button = Instance.new("ImageButton")
	button.Name = "Button"
	button.ImageTransparency = 1
	button.AnchorPoint = Vector2.new(0, 0.5)
	button.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
	button.BorderColor3 = Color3.fromRGB(0, 0, 0)
	button.BorderSizePixel = 0
	button.Position = UDim2.fromScale(0.5, 0.5)
	button.Size = UDim2.fromScale(0.5, 1)
	button.ZIndex = 2

	local slider = Instance.new("Frame")
	slider.Name = "Slider"
	slider.AnchorPoint = Vector2.new(0.5, 0.5)
	slider.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
	slider.BorderColor3 = Color3.fromRGB(0, 0, 0)
	slider.BorderSizePixel = 0
	slider.Position = UDim2.fromScale(0.25, 0.5)
	slider.Size = UDim2.fromScale(0.4, 0.8)
	slider.Parent = button

	button.Parent = template

	local textLabel = Instance.new("TextLabel")
	textLabel.Name = "TextLabel"
	textLabel.FontFace = Font.new("rbxasset://fonts/families/TitilliumWeb.json")
	textLabel.Text = "template"
	textLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	textLabel.TextScaled = true
	textLabel.TextSize = 25
	textLabel.TextWrapped = true
	textLabel.AnchorPoint = Vector2.new(0, 0.5)
	textLabel.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	textLabel.BackgroundTransparency = 1
	textLabel.BorderColor3 = Color3.fromRGB(0, 0, 0)
	textLabel.BorderSizePixel = 0
	textLabel.Position = UDim2.fromScale(0, 0.5)
	textLabel.Size = UDim2.fromScale(0.5, 0.75)
	textLabel.ZIndex = 3
	textLabel.Parent = template

	template.Parent = switches

	local uIPadding = Instance.new("UIPadding")
	uIPadding.Name = "UIPadding"
	uIPadding.PaddingBottom = UDim.new(0.02, 0)
	uIPadding.PaddingLeft = UDim.new(0.006, 0)
	uIPadding.PaddingRight = UDim.new(0.006, 0)
	uIPadding.PaddingTop = UDim.new(0.02, 0)
	uIPadding.Parent = switches

	switches.Parent = holder

	local labels = Instance.new("Frame")
	labels.Name = "labels"
	labels.AnchorPoint = Vector2.new(1, 1)
	labels.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	labels.BackgroundTransparency = 1
	labels.BorderColor3 = Color3.fromRGB(0, 0, 0)
	labels.BorderSizePixel = 0
	labels.Position = UDim2.fromScale(1, 1)
	labels.Size = UDim2.fromScale(0.2, 0.2)

	local uIListLayout = Instance.new("UIListLayout")
	uIListLayout.Name = "UIListLayout"
	uIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
	uIListLayout.VerticalAlignment = Enum.VerticalAlignment.Bottom
	uIListLayout.Parent = labels

	local uIAspectRatioConstraint2 = Instance.new("UIAspectRatioConstraint")
	uIAspectRatioConstraint2.Name = "UIAspectRatioConstraint"
	uIAspectRatioConstraint2.AspectRatio = 4
	uIAspectRatioConstraint2.Parent = labels

	local ascension = Instance.new("TextLabel")
	ascension.Name = "ascension"
	ascension.FontFace = Font.new("rbxasset://fonts/families/TitilliumWeb.json")
	ascension.Text = "ascension"
	ascension.TextColor3 = Color3.fromRGB(255, 255, 255)
	ascension.TextScaled = true
	ascension.TextSize = 14
	ascension.TextStrokeColor3 = Color3.fromRGB(39, 39, 39)
	ascension.TextWrapped = true
	ascension.AnchorPoint = Vector2.new(1, 1)
	ascension.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	ascension.BackgroundTransparency = 1
	ascension.BorderColor3 = Color3.fromRGB(0, 0, 0)
	ascension.BorderSizePixel = 0
	ascension.LayoutOrder = 2
	ascension.Position = UDim2.fromScale(1, 1)
	ascension.Size = UDim2.fromScale(1, 1)

	local uIStroke2 = Instance.new("UIStroke")
	uIStroke2.Name = "UIStroke"
	uIStroke2.Color = Color3.fromRGB(48, 48, 48)
	uIStroke2.LineJoinMode = Enum.LineJoinMode.Miter
	uIStroke2.Thickness = 2
	uIStroke2.Parent = ascension

	ascension.Parent = labels

	local mode = Instance.new("TextLabel")
	mode.Name = "mode"
	mode.FontFace = Font.new("rbxasset://fonts/families/TitilliumWeb.json")
	mode.Text = "mode"
	mode.TextColor3 = Color3.fromRGB(255, 255, 255)
	mode.TextScaled = true
	mode.TextSize = 14
	mode.TextStrokeColor3 = Color3.fromRGB(39, 39, 39)
	mode.TextWrapped = true
	mode.AnchorPoint = Vector2.new(1, 1)
	mode.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	mode.BackgroundTransparency = 1
	mode.BorderColor3 = Color3.fromRGB(0, 0, 0)
	mode.BorderSizePixel = 0
	mode.LayoutOrder = 1
	mode.Position = UDim2.fromScale(1, 1)
	mode.Size = UDim2.fromScale(1, 1)

	local uIStroke3 = Instance.new("UIStroke")
	uIStroke3.Name = "UIStroke"
	uIStroke3.Color = Color3.fromRGB(48, 48, 48)
	uIStroke3.LineJoinMode = Enum.LineJoinMode.Miter
	uIStroke3.Thickness = 2
	uIStroke3.Parent = mode

	mode.Parent = labels

	local us = Instance.new("TextLabel")
	us.Name = "us"
	us.FontFace = Font.new("rbxasset://fonts/families/TitilliumWeb.json")
	us.Text = "us"
	us.TextColor3 = Color3.fromRGB(255, 255, 255)
	us.TextScaled = true
	us.TextSize = 14
	us.TextStrokeColor3 = Color3.fromRGB(39, 39, 39)
	us.TextWrapped = true
	us.AnchorPoint = Vector2.new(1, 1)
	us.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	us.BackgroundTransparency = 1
	us.BorderColor3 = Color3.fromRGB(0, 0, 0)
	us.BorderSizePixel = 0
	us.LayoutOrder = 3
	us.Position = UDim2.fromScale(1, 1)
	us.Size = UDim2.fromScale(1, 1)

	local uIStroke4 = Instance.new("UIStroke")
	uIStroke4.Name = "UIStroke"
	uIStroke4.Color = Color3.fromRGB(48, 48, 48)
	uIStroke4.LineJoinMode = Enum.LineJoinMode.Miter
	uIStroke4.Thickness = 2
	uIStroke4.Parent = us

	us.Parent = labels

	local uc = Instance.new("TextLabel")
	uc.Name = "uc"
	uc.FontFace = Font.new("rbxasset://fonts/families/TitilliumWeb.json")
	uc.Text = "uc"
	uc.TextColor3 = Color3.fromRGB(255, 255, 255)
	uc.TextScaled = true
	uc.TextSize = 14
	uc.TextStrokeColor3 = Color3.fromRGB(39, 39, 39)
	uc.TextWrapped = true
	uc.AnchorPoint = Vector2.new(1, 1)
	uc.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	uc.BackgroundTransparency = 1
	uc.BorderColor3 = Color3.fromRGB(0, 0, 0)
	uc.BorderSizePixel = 0
	uc.LayoutOrder = 4
	uc.Position = UDim2.fromScale(1, 1)
	uc.Size = UDim2.fromScale(1, 1)

	local uIStroke5 = Instance.new("UIStroke")
	uIStroke5.Name = "UIStroke"
	uIStroke5.Color = Color3.fromRGB(48, 48, 48)
	uIStroke5.LineJoinMode = Enum.LineJoinMode.Miter
	uIStroke5.Thickness = 2
	uIStroke5.Parent = uc

	uc.Parent = labels

	labels.Parent = holder

	holder.Parent = pages

	local traitInfo = Instance.new("Frame")
	traitInfo.Name = "TraitInfo"
	traitInfo.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	traitInfo.BackgroundTransparency = 1
	traitInfo.BorderColor3 = Color3.fromRGB(0, 0, 0)
	traitInfo.BorderSizePixel = 0
	traitInfo.ClipsDescendants = true
	traitInfo.LayoutOrder = 2
	traitInfo.Size = UDim2.fromScale(1, 1)

	local cardsHolder = Instance.new("Frame")
	cardsHolder.Name = "CardsHolder"
	cardsHolder.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	cardsHolder.BackgroundTransparency = 1
	cardsHolder.BorderColor3 = Color3.fromRGB(0, 0, 0)
	cardsHolder.BorderSizePixel = 0
	cardsHolder.Position = UDim2.fromScale(0.01, 0)
	cardsHolder.Size = UDim2.fromScale(0.95, 0.9)

	local template1 = Instance.new("Frame")
	template1.Name = "template"
	template1.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	template1.BackgroundTransparency = 1
	template1.BorderColor3 = Color3.fromRGB(0, 0, 0)
	template1.BorderSizePixel = 0
	template1.LayoutOrder = 1
	template1.Size = UDim2.fromScale(0.333, 1)
	template1.Visible = false

	local card = Instance.new("ImageButton")
	card.Name = "card"
	card.Active = false
	card.AnchorPoint = Vector2.new(0.5, 0.5)
	card.BackgroundColor3 = Color3.fromRGB(31, 31, 31)
	card.BorderColor3 = Color3.fromRGB(0, 0, 0)
	card.BorderSizePixel = 0
	card.Position = UDim2.fromScale(0.5, 0.5)
	card.Selectable = false
	card.Size = UDim2.fromScale(0.9, 1)

	local name = Instance.new("TextLabel")
	name.Name = "name"
	name.FontFace = Font.new("rbxasset://fonts/families/TitilliumWeb.json")
	name.Text = "Ryoiki (Mythic)"
	name.TextColor3 = Color3.fromRGB(255, 255, 255)
	name.TextScaled = true
	name.TextSize = 25
	name.TextWrapped = true
	name.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	name.BackgroundTransparency = 1
	name.BorderColor3 = Color3.fromRGB(0, 0, 0)
	name.BorderSizePixel = 0
	name.Size = UDim2.fromScale(1, 0.15)
	name.ZIndex = 3
	name.Parent = card

	local description = Instance.new("TextLabel")
	description.Name = "description"
	description.FontFace = Font.new("rbxasset://fonts/families/TitilliumWeb.json")
	description.Text = "text"
	description.TextColor3 = Color3.fromRGB(255, 255, 255)
	description.TextScaled = true
	description.TextSize = 25
	description.TextWrapped = true
	description.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	description.BackgroundTransparency = 0.8
	description.BorderColor3 = Color3.fromRGB(0, 0, 0)
	description.BorderSizePixel = 0
	description.LayoutOrder = 100
	description.Position = UDim2.fromScale(0, 0.15)
	description.Size = UDim2.fromScale(1, 0.65)
	description.ZIndex = 3
	description.Parent = card

	local var_stats = Instance.new("Frame")
	var_stats.Name = "stats"
	var_stats.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	var_stats.BackgroundTransparency = 1
	var_stats.BorderColor3 = Color3.fromRGB(0, 0, 0)
	var_stats.BorderSizePixel = 0
	var_stats.Position = UDim2.fromScale(0, 0.8)
	var_stats.Size = UDim2.fromScale(1, 0.2)

	local category = Instance.new("TextLabel")
	category.Name = "category"
	category.FontFace = Font.new("rbxasset://fonts/families/TitilliumWeb.json")
	category.Text = "Defense: 0"
	category.TextColor3 = Color3.fromRGB(255, 255, 255)
	category.TextScaled = true
	category.TextSize = 14
	category.TextWrapped = true
	category.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	category.BackgroundTransparency = 1
	category.BorderColor3 = Color3.fromRGB(0, 0, 0)
	category.BorderSizePixel = 0
	category.Size = UDim2.fromScale(0.5, 0.5)
	category.Visible = false
	category.Parent = var_stats

	var_stats.Parent = card

	card.Parent = template1

	template1.Parent = cardsHolder

	local uIPadding1 = Instance.new("UIPadding")
	uIPadding1.Name = "UIPadding"
	uIPadding1.PaddingBottom = UDim.new(0.075, 0)
	uIPadding1.PaddingTop = UDim.new(0.075, 0)
	uIPadding1.Parent = cardsHolder

	local uIListLayout1 = Instance.new("UIListLayout")
	uIListLayout1.Name = "UIListLayout"
	uIListLayout1.FillDirection = Enum.FillDirection.Horizontal
	uIListLayout1.SortOrder = Enum.SortOrder.LayoutOrder
	uIListLayout1.Parent = cardsHolder

	cardsHolder.Parent = traitInfo

	local discard = Instance.new("ImageButton")
	discard.Name = "discard"
	discard.ImageTransparency = 1
	discard.AnchorPoint = Vector2.new(0.5, 0)
	discard.BackgroundColor3 = Color3.fromRGB(31, 31, 31)
	discard.BorderColor3 = Color3.fromRGB(0, 0, 0)
	discard.BorderSizePixel = 0
	discard.Position = UDim2.fromScale(0.475, 0.865)
	discard.Size = UDim2.fromScale(0.5, 0.1)
	discard.Visible = false

	local textLabel1 = Instance.new("TextLabel")
	textLabel1.Name = "TextLabel"
	textLabel1.FontFace = Font.new("rbxasset://fonts/families/TitilliumWeb.json")
	textLabel1.Text = "discard"
	textLabel1.TextColor3 = Color3.fromRGB(255, 255, 255)
	textLabel1.TextScaled = true
	textLabel1.TextSize = 25
	textLabel1.TextWrapped = true
	textLabel1.AnchorPoint = Vector2.new(0, 0.5)
	textLabel1.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	textLabel1.BackgroundTransparency = 1
	textLabel1.BorderColor3 = Color3.fromRGB(0, 0, 0)
	textLabel1.BorderSizePixel = 0
	textLabel1.Position = UDim2.fromScale(0, 0.5)
	textLabel1.Size = UDim2.fromScale(1, 1)
	textLabel1.ZIndex = 3
	textLabel1.Parent = discard

	discard.Parent = traitInfo

	local pity = Instance.new("TextLabel")
	pity.Name = "pity"
	pity.FontFace = Font.new("rbxasset://fonts/families/TitilliumWeb.json")
	pity.Text = "pity"
	pity.TextColor3 = Color3.fromRGB(255, 255, 255)
	pity.TextScaled = true
	pity.TextSize = 14
	pity.TextStrokeColor3 = Color3.fromRGB(39, 39, 39)
	pity.TextWrapped = true
	pity.AnchorPoint = Vector2.new(1, 0)
	pity.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	pity.BackgroundTransparency = 1
	pity.BorderColor3 = Color3.fromRGB(0, 0, 0)
	pity.BorderSizePixel = 0
	pity.Position = UDim2.fromScale(1, 0.865)
	pity.Size = UDim2.fromScale(0.1, 0.1)
	pity.Visible = false

	local uIStroke6 = Instance.new("UIStroke")
	uIStroke6.Name = "UIStroke"
	uIStroke6.Color = Color3.fromRGB(39, 39, 39)
	uIStroke6.LineJoinMode = Enum.LineJoinMode.Miter
	uIStroke6.Thickness = 2
	uIStroke6.Parent = pity

	pity.Parent = traitInfo

	local none = Instance.new("TextLabel")
	none.Name = "none"
	none.FontFace = Font.new("rbxasset://fonts/families/TitilliumWeb.json")
	none.Text = "No trait hands."
	none.TextColor3 = Color3.fromRGB(255, 255, 255)
	none.TextScaled = true
	none.TextSize = 14
	none.TextStrokeColor3 = Color3.fromRGB(39, 39, 39)
	none.TextWrapped = true
	none.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	none.BackgroundTransparency = 1
	none.BorderColor3 = Color3.fromRGB(0, 0, 0)
	none.BorderSizePixel = 0
	none.Size = UDim2.fromScale(1, 1)

	local uIStroke7 = Instance.new("UIStroke")
	uIStroke7.Name = "UIStroke"
	uIStroke7.Color = Color3.fromRGB(39, 39, 39)
	uIStroke7.LineJoinMode = Enum.LineJoinMode.Miter
	uIStroke7.Thickness = 2
	uIStroke7.Parent = none

	none.Parent = traitInfo

	local used = Instance.new("TextLabel")
	used.Name = "used"
	used.FontFace = Font.new("rbxasset://fonts/families/TitilliumWeb.json")
	used.Text = "Trait UI will start working after this trait hand."
	used.TextColor3 = Color3.fromRGB(255, 255, 255)
	used.TextScaled = true
	used.TextSize = 14
	used.TextStrokeColor3 = Color3.fromRGB(39, 39, 39)
	used.TextWrapped = true
	used.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	used.BackgroundTransparency = 1
	used.BorderColor3 = Color3.fromRGB(0, 0, 0)
	used.BorderSizePixel = 0
	used.Size = UDim2.fromScale(1, 1)
	used.Visible = false

	local uIStroke8 = Instance.new("UIStroke")
	uIStroke8.Name = "UIStroke"
	uIStroke8.Color = Color3.fromRGB(39, 39, 39)
	uIStroke8.LineJoinMode = Enum.LineJoinMode.Miter
	uIStroke8.Thickness = 2
	uIStroke8.Parent = used

	used.Parent = traitInfo

	traitInfo.Parent = pages

	local uIPageLayout = Instance.new("UIPageLayout")
	uIPageLayout.Name = "UIPageLayout"
	uIPageLayout.Circular = true
	uIPageLayout.EasingStyle = Enum.EasingStyle.Linear
	uIPageLayout.GamepadInputEnabled = false
	uIPageLayout.ScrollWheelInputEnabled = false
	uIPageLayout.TouchInputEnabled = false
	uIPageLayout.TweenTime = 0.1
	uIPageLayout.SortOrder = Enum.SortOrder.LayoutOrder
	uIPageLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	uIPageLayout.Parent = pages

	pages.Parent = main

	local topButtons = Instance.new("Frame")
	topButtons.Name = "TopButtons"
	topButtons.AnchorPoint = Vector2.new(1, 0)
	topButtons.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	topButtons.BackgroundTransparency = 1
	topButtons.BorderColor3 = Color3.fromRGB(0, 0, 0)
	topButtons.BorderSizePixel = 0
	topButtons.Position = UDim2.fromScale(1, 0)
	topButtons.Size = UDim2.fromScale(0.125, 0.125)

	local uIAspectRatioConstraint3 = Instance.new("UIAspectRatioConstraint")
	uIAspectRatioConstraint3.Name = "UIAspectRatioConstraint"
	uIAspectRatioConstraint3.AspectRatio = 3
	uIAspectRatioConstraint3.Parent = topButtons

	local hide = Instance.new("TextButton")
	hide.Name = "Hide"
	hide.FontFace = Font.new("rbxasset://fonts/families/TitilliumWeb.json")
	hide.Text = "X"
	hide.TextColor3 = Color3.fromRGB(255, 255, 255)
	hide.TextScaled = true
	hide.TextSize = 14
	hide.TextWrapped = true
	hide.AnchorPoint = Vector2.new(1, 0)
	hide.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	hide.BackgroundTransparency = 1
	hide.BorderColor3 = Color3.fromRGB(0, 0, 0)
	hide.BorderSizePixel = 0
	hide.LayoutOrder = 3
	hide.Position = UDim2.fromScale(1, 0)
	hide.Size = UDim2.fromScale(0.333, 1)

	local uIStroke9 = Instance.new("UIStroke")
	uIStroke9.Name = "UIStroke"
	uIStroke9.Color = Color3.fromRGB(39, 39, 39)
	uIStroke9.LineJoinMode = Enum.LineJoinMode.Miter
	uIStroke9.Parent = hide

	hide.Parent = topButtons

	local uIListLayout2 = Instance.new("UIListLayout")
	uIListLayout2.Name = "UIListLayout"
	uIListLayout2.FillDirection = Enum.FillDirection.Horizontal
	uIListLayout2.HorizontalAlignment = Enum.HorizontalAlignment.Right
	uIListLayout2.SortOrder = Enum.SortOrder.LayoutOrder
	uIListLayout2.Parent = topButtons

	local prev = Instance.new("TextButton")
	prev.Name = "Prev"
	prev.FontFace = Font.new("rbxasset://fonts/families/TitilliumWeb.json")
	prev.Text = "<-"
	prev.TextColor3 = Color3.fromRGB(255, 255, 255)
	prev.TextScaled = true
	prev.TextSize = 14
	prev.TextWrapped = true
	prev.AnchorPoint = Vector2.new(1, 0)
	prev.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	prev.BackgroundTransparency = 1
	prev.BorderColor3 = Color3.fromRGB(0, 0, 0)
	prev.BorderSizePixel = 0
	prev.LayoutOrder = 1
	prev.Position = UDim2.fromScale(1, 0)
	prev.Size = UDim2.fromScale(0.333, 1)

	local uIStroke10 = Instance.new("UIStroke")
	uIStroke10.Name = "UIStroke"
	uIStroke10.Color = Color3.fromRGB(39, 39, 39)
	uIStroke10.LineJoinMode = Enum.LineJoinMode.Miter
	uIStroke10.Parent = prev

	prev.Parent = topButtons

	local next = Instance.new("TextButton")
	next.Name = "Next"
	next.FontFace = Font.new("rbxasset://fonts/families/TitilliumWeb.json")
	next.Text = "->"
	next.TextColor3 = Color3.fromRGB(255, 255, 255)
	next.TextScaled = true
	next.TextSize = 14
	next.TextWrapped = true
	next.AnchorPoint = Vector2.new(1, 0)
	next.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	next.BackgroundTransparency = 1
	next.BorderColor3 = Color3.fromRGB(0, 0, 0)
	next.BorderSizePixel = 0
	next.LayoutOrder = 2
	next.Position = UDim2.fromScale(1, 0)
	next.Size = UDim2.fromScale(0.333, 1)

	local uIStroke11 = Instance.new("UIStroke")
	uIStroke11.Name = "UIStroke"
	uIStroke11.Color = Color3.fromRGB(39, 39, 39)
	uIStroke11.LineJoinMode = Enum.LineJoinMode.Miter
	uIStroke11.Parent = next

	next.Parent = topButtons

	topButtons.Parent = main

	main.Parent = cheatt
end
local scriptUI = CoreGui.cheatt
local holder = scriptUI.Main.Pages.Holder
local labels = holder.labels

--state
local state = {
	mode = "stopped",
	enabledFeatures = {},
}

local function stateUpdated()
	writefile("farmState", HttpService:JSONEncode(state))
end

if isfile("farmState") then
	state = HttpService:JSONDecode(readfile("farmState"))
end

--features
local featureDebounce = 0
local features = {}

--STEP
local steps = {}
local invokeQueue = {}
local hideTraitUIs = false

do
	if _G.farmStepConn then
		if typeof(_G.farmStepConn) == "RBXScriptConnection" then
			_G.farmStepConn:Disconnect()
		else
			RunService:UnbindFromRenderStep("abcdefg")
		end
	end

	_G.farmStepConn = true
	RunService:BindToRenderStep("abcdefg", 1, function(dt)
		if hideTraitUIs then
			traitHandPrompt.Visible = false
		end
		labels.mode.Text = `mode: {state.mode}`
		labels.uc.Text = `uc: {data.UCoins.Value}`
		labels.us.Text = `us: {data.Currency.Value}`

		featureDebounce -= dt
		if featureDebounce <= 0 then
			featureDebounce = 1

			task.spawn(function()
				local info = levelService.RF.GetAbilityPVEInfo:InvokeServer(data.Ability.Value)
				ascensions = info.AscensionRank
				holder.labels.ascension.Text = `ascension: {tostring(info.AscensionRank)}`
				task.spawn(features.autoAscend.check, info)
			end)

			for name, info in pairs(features) do
				if state.enabledFeatures[name] and info.run then
					task.spawn(info.run)
				end
			end
		end

		if not root or state.mode == "stopped" then
			return
		end

		for _, step in pairs(steps[state.mode]) do
			if step(dt) == "break" then
				break
			end
		end

		for remote, member in pairs(invokeQueue) do
			if member.finished then
				invokeQueue[remote] = nil
			end
		end
	end)
end

--KEYS
addConn(UserInputService.InputBegan:Connect(function(inputObject, processed)
	if not processed then
		local modeToSwitch = _G.farmConfig.modeKeys[inputObject.KeyCode.Name]
		if modeToSwitch then
			if state.mode ~= modeToSwitch then
				if modeToSwitch == "stopped" then
					teleport(locations.park)
				end
			end
			state.mode = modeToSwitch
			stateUpdated()
		end
	end
end))

--TRAIT UI
do
	local traitHandEvent = traitService:WaitForChild("RE"):WaitForChild("TraitHand")
	local discardTraits = traitService:WaitForChild("RF"):WaitForChild("DiscardTraits")
	local pickTrait = traitService:WaitForChild("RF"):WaitForChild("PickTrait")

	local traitPage = scriptUI.Main.Pages.TraitInfo
	local cardsHolder = traitPage.CardsHolder
	local template = cardsHolder.template
	local cards = {}
	local availableTraits = {}
	local inProgress = false

	local function chosen()
		inProgress = false
		availableTraits = {}
		traitPage.none.Visible = true
		traitPage.discard.Visible = false
		traitPage.pity.Visible = false
		for _, card in pairs(cards) do
			card.Parent.Visible = false
		end
	end

	for i = 1, 3 do
		local clone = template:Clone()
		local card = clone.card
		card.description.Text = ""
		card.name.Text = "None"
		card.Name = `Trait{tostring(i)}`
		clone.Parent = cardsHolder

		card.MouseButton1Click:Connect(function()
			if availableTraits[i] then
				task.spawn(pickTrait.InvokeServer, pickTrait, i)
				chosen()
			end
		end)
		cards[i] = card
	end

	traitPage.discard.MouseButton1Click:Connect(function()
		task.spawn(discardTraits.InvokeServer, discardTraits)
		chosen()
	end)

	--fuck with AUT's trait ui
	for _, connection in pairs(getconnections(traitHandEvent.OnClientEvent)) do
		connection:Disable()
		--selene:allow(incorrect_standard_library_use)
		do
			local func = connection.Function
			if debug.getupvalue(func, 1) == true then
				traitHandPrompt.Visible = true
				traitPage.none.Visible = false
				traitPage.used.Visible = true
				local conn
				conn = addConn(RunService.Heartbeat:Connect(function()
					if debug.getupvalue(func, 1) == false then
						if not inProgress then
							traitPage.none.Visible = true
						end
						traitPage.used.Visible = false
						hideTraitUIs = true
						conn:Disconnect()
					end
				end))
			else
				hideTraitUIs = true
			end

			local i, upvalue
			for index, v in pairs(debug.getupvalues(func)) do
				if type(v) == "table" and rawget(v, "ResolveLock") then
					i = index
					upvalue = v
					break
				end
			end

			debug.setupvalue(
				func,
				i,
				setmetatable({
					__original = rawget(upvalue, "__original") or upvalue,
					ResolveLock = function() end,
					ToggleMenu = function() end,
					MakeLockInstance = function() end,
					SetMenu = function() end,
					DestroyPrompt = function() end,
				}, {
					__index = upvalue,
					__newindex = upvalue,
				})
			)
		end
	end

	addConn(data.Ability.Changed:Connect(function()
		chosen()
	end))

	--replace AUT's trait ui
	local function handle(traitsInfo)
		inProgress = true
		traitPage.used.Visible = false
		traitPage.none.Visible = false
		traitPage.discard.Visible = true
		traitPage.pity.Text = "getting pity data"
		traitPage.pity.Visible = true
		task.spawn(function()
			local info = shopService.RF.GetPityInfo:InvokeServer()
			local max
			if ascensions <= 5 then
				max = 60
			elseif ascensions <= 10 then
				max = 80
			elseif ascensions > 10 then
				max = 100
			end

			traitPage.pity.Text = `{info.TraitRerollPity}/{max}`
		end)

		for i, info in pairs(traitsInfo) do
			availableTraits[i] = info
			local trait = traits[info.Trait]
			local card = cards[i]

			if info.Hexed then
				card.name.Text = `{trait.HexPrefix} {info.Trait} ({info.Rarity})`
				card.description.Text = trait.HexDescription
			else
				card.name.Text = `{info.Trait} ({info.Rarity})`
				card.description.Text = trait.Description
			end

			if info.Hexed or info.Rarity == "Mythic" then
				card.name.Text = `!!! {card.name.Text} !!!`
			end

			card.Parent.Visible = true

			local statTemplate = card.stats.category
			for _, v in pairs(card.stats:GetChildren()) do
				if v ~= statTemplate then
					v:Destroy()
				end
			end

			if info.StatBonuses then
				local xPos = 0
				local yPos = 0

				for stat, points in pairs(info.StatBonuses) do
					local clone = statTemplate:Clone()
					clone.Text = `{stat}: {tostring(points)}`
					clone.Name = stat
					clone.Visible = true
					clone.Position = UDim2.fromScale(xPos, yPos)
					clone.Parent = card.stats
					xPos += 0.5
					if xPos > 0.5 then
						xPos = 0
						yPos += 0.5
					end
				end
			end
		end
	end

	if _G.currentTraits then
		handle(_G.currentTraits)
	end

	addConn(traitHandEvent.onClientEvent:Connect(function(traitsInfo)
		_G.currentTraits = traitsInfo
		handle(traitsInfo)
	end))
end

--combat tag
addConn(ReplicatedStorage.Remotes.UIOutput.OnClientEvent:Connect(function(...)
	local args = { ... }
	if args[1] == "Notify" and args[2] == "COMBAT TAG" then
		if args[3] == [[<font color="#FF0000">YOU HAVE BEEN COMBAT TAGGED</font>]] then
			combatTagged = true
		elseif args[3] == [[<font color="#00FF00">YOU ARE NO LONGER COMBAT TAGGED</font>]] then
			combatTagged = false
		end
	end
end))

--STEP FUNCTIONS
do
	--curses
	do
		local sellDebounce = 0
		local isSelling = false
		local bmLocations = {}
		for i, pos in pairs(locations.dealer) do
			bmLocations[i] = { timer = 0, cfr = pos }
		end
		local function attemptSell(dt)
			local dealer = workspace.NPCS:FindFirstChild("Black Market")
			if localPlayer:FindFirstChild("Backpack") and dealer then
				local items = {}
				for _, v in pairs(localPlayer.Backpack:GetChildren()) do
					if v:IsA("Tool") and v:GetAttribute("ItemId") then
						items[#items + 1] = v
					end
				end

				if #items == 0 and isSelling then
					isSelling = false
					sellDebounce = 0
				end

				if #items >= _G.farmConfig.sellAt or isSelling then
					if dealer:FindFirstChild("HumanoidRootPart") then
						isSelling = true
						teleport(
							dealer.HumanoidRootPart.CFrame * CFrame.new(0, 0, -5) * CFrame.Angles(0, math.rad(180), 0)
						)

						sellDebounce -= dt
						if sellDebounce <= 0 then
							sellDebounce = 2
							local itemsToSell = {}
							for _, v in pairs(items) do
								table.insert(itemsToSell, {
									[1] = v:GetAttribute("ItemId"),
									[2] = v:getAttribute("UUID"),
									[3] = 1,
								})
							end

							shopService.RE.Signal:FireServer("BlackMarketBulkSellItems", itemsToSell)
						end
					else
						local finished = false
						for i, location in pairs(bmLocations) do
							if location.timer < 2 then
								location.timer += dt
								teleport(location.cfr)
								break
							end

							if i == #bmLocations then
								finished = true
							end
						end

						if finished then
							for _, location in pairs(bmLocations) do
								location.timer = 0
							end
						end
					end

					return "break"
				end
			end
		end

		local chestQueue = {}
		local function attemptChests(dt)
			if #chestQueue == 0 then
				for _, chest in pairs(workspace:GetChildren()) do
					if
						chest:FindFirstChild("RootPart")
						and chest.RootPart:FindFirstChild("ProximityAttachment")
						and not chest:HasTag("WasOpened")
					then
						if (chest.RootPart.Position - locations.desert.Position).Magnitude <= 300 then
							table.insert(chestQueue, { timer = 0, root = chest.RootPart })
						end
					end
				end
			else
				local chest = chestQueue[1]
				chest.timer += dt

				if
					chest.timer >= 0.5
					or not chest.root:FindFirstChild("ProximityAttachment")
					or not chest.root.ProximityAttachment:FindFirstChild("Interaction")
				then
					table.remove(chestQueue, 1)
					chest.root.Parent:AddTag("WasOpened")
				else
					teleport(chest.root.CFrame)
					fireproximityprompt(chest.root.ProximityAttachment.Interaction)
					return "break"
				end
			end
		end

		local cursesList = {
			"Mantis Curse",
			"Jujutsu Sorcerer",
			"Flyhead",
			"Roppongi Curse",
		}
		local curses = {}
		do
			for _, mob in pairs(cursesList) do
				curses[mob] = true
			end
		end

		local keyIndex = 0
		local wasSummoned = false
		local function farmMobs()
			teleport(locations.desert)
			local mostHp = math.huge
			local foe
			for _, thisFoe in pairs(living:GetChildren()) do
				if curses[thisFoe.Name] then
					local foeHumanoid = thisFoe:FindFirstChildWhichIsA("Humanoid")
					local foeRoot = thisFoe:FindFirstChild("HumanoidRootPart")
					if foeHumanoid and foeRoot and (foeRoot.Position - locations.desert.Position).Magnitude <= 300 then
						local hp = foeHumanoid.Health
						if _G.farmConfig.hpFilterUsePercentage then
							hp /= foeHumanoid.MaxHealth
						end
						if hp < mostHp then
							mostHp = hp
							foe = thisFoe
						end
					end
				end
			end

			if foe then
				local foeRoot = foe.HumanoidRootPart
				teleport(CFrame.new(foeRoot.CFrame.Position) * _G.farmConfig.tpOffset)

				local keysList
				local isSummoned = character:HasTag("Summoned")
				if isSummoned ~= wasSummoned then
					keyIndex = 0
					wasSummoned = isSummoned
				end

				keysList = if isSummoned then _G.farmConfig.standOnKeys else _G.farmConfig.loopKeys
				keyIndex += 1
				if keyIndex > #keysList then
					keyIndex = 1
				end

				local key = keysList[keyIndex]
				if type(key) == "table" then
					if key[2] == "Press" then
						task.delay(0.1, fireInput.InvokeServer, fireInput, `END-{key[1]}`)
					end
					key = key[1]
				end
				task.spawn(fireInput.InvokeServer, fireInput, key)
				return "break"
			end
		end

		local autoPress = {
			ui.Gameplay.ChestRoll.SelectAll,
			ui.Gameplay.ChestRoll.Close,
		}
		local function pressButtons()
			for _, button in pairs(autoPress) do
				if button.Visible then
					firesignal(button.MouseButton1Click)
				end
			end
		end

		steps.curses = {
			pressButtons,
			attemptSell,
			attemptChests,
			farmMobs,
		}
	end

	--lost swords
	do
		local function safeInvoke(remote, ...)
			if invokeQueue[remote] then
				return invokeQueue[remote]
			end

			local member = {
				args = { ... },
				timer = 0,
				finished = false,
				result = nil,
			}

			task.spawn(function()
				local success, result
				while not success do
					success, result = pcall(function()
						return { remote:InvokeServer(table.unpack(member.args)) }
					end)
				end

				member.result = result
				member.finished = true
			end)

			invokeQueue[remote] = member

			return member
		end

		local checkDialogue =
			knitServices:WaitForChild("DialogueService"):WaitForChild("RF"):WaitForChild("CheckDialogue")
		local swordLocations
		local function getSwords()
			if not swordLocations then
				local invokeResult = safeInvoke(checkDialogue, "Zoros_Swords_Adventure")
				if invokeResult.finished and invokeResult.result[2] then
					swordLocations = {}
					for i, v in pairs(invokeResult.result[2].SwordLocations) do
						swordLocations[i] = { pos = v.Location, finished = false }
					end
				else
					return "break"
				end
			end
		end

		local function pickUpSwords()
			local allFinished = false
			for i, location in pairs(swordLocations) do
				if not location.finished then
					teleport(location.pos)
					if safeInvoke(knitServices.AdventureService.RF.PickedUpSword).finished then
						location.finished = true
					end

					break
				else
					if i == #swordLocations then
						allFinished = true
					end
				end
			end

			if allFinished then
				if safeInvoke(checkDialogue, "Zoros_Swords_Adventure").finished then
					swordLocations = nil
				end
			end
		end

		steps.lostSwords = {
			getSwords,
			pickUpSwords,
		}
	end
end

--FEATURE FUNCTIONS
do
	features.autoAscend = {
		check = function(info)
			if info.CurrentLevel >= 200 and data.UCoins.Value >= 1000000 then
				levelService.RF.AscendAbility:InvokeServer(data.Ability.Value)
			end
		end,
	}

	features.autoStat = {
		run = function()
			local statsService = knitServices.StatService
			local ability = data.Ability.Value
			local stats = statsService.RF.GetAbilityStats:InvokeServer(ability)
			if stats.StatPoints >= 1 then
				statsService.RF.ApplyStats:InvokeServer(ability, {
					Defense = 0,
					Special = 0,
					Health = 0,
					Attack = stats.StatPoints,
				})
			end
		end,
	}

	features.autoDeleteSkin = {
		run = function()
			if not combatTagged then
				local skinInventory = inventoryService.RF.GetItems:InvokeServer("SkinInventory")
				local uuidsToRemove = { {} }
				local biggerIndex = 1
				local index = 0
				for uuid, skin in pairs(skinInventory) do
					if
						not skinWhitelist[skin._Rarity]
						and not skinWhitelistName[skin._DisplayName]
						and not skin._UnusualInfo
					then
						table.insert(uuidsToRemove[biggerIndex], uuid)
						index += 1
						if index >= 100 then
							biggerIndex += 1
							uuidsToRemove[biggerIndex] = {}
							index = 0
						end
					end
				end

				for _, v in pairs(uuidsToRemove) do
					if #v > 0 then
						inventoryService.RE.SkinInventory:FireServer({
							UUIDS = v,
							Remove = true,
						})
					end
				end
			end
		end,
	}

	--auto rejoin
	do
		local attempting = false
		local function rejoin()
			if attempting or not state.enabledFeatures.autoRejoin then
				return
			end
			attempting = true

			--selene:allow(undefined_variable)
			queue_on_teleport([[
				local isfile, writefile, readfile = isfile, writefile, readfile
				local fileName = "FoundPS.txt"
				local alphabet = string.split("ABCDEFGHIJKLMNOPQRSTUVWXYZ", "")
				local remote = game:GetService("ReplicatedStorage")
					:WaitForChild("ReplicatedModules")
					:WaitForChild("KnitPackage")
					:WaitForChild("Knit")
					:WaitForChild("Services")
					:WaitForChild("PrivateCodeService")
					:WaitForChild("RF")
					:WaitForChild("Invoke")
				print("started")
				local function getcode()
					local code = ""
					for _ = 1, 5 do
						code = code .. alphabet[math.random(1, 26)]
					end
					return code
				end
				local found = false
				local conn;conn = game:GetService("RunService").Heartbeat:Connect(function()
					for _ = 1, 3 do
						task.spawn(function()
							local code = getcode()
							local success, result = pcall(remote.InvokeServer, remote, "JoinCode", { Code = code })
							if success then
								if result == "Success" then
									local file = if isfile(fileName) then readfile(fileName) else ""
									writefile(fileName, file .. code .. "\n")
									conn:Disconnect()
									print(result, code)

									if not found then
										found = true
										queue_on_teleport(\[\[loadstring(game:HttpGet("https://pastebin.com/raw/7tQbq2V7"))()\]\])
									end
								end
							end
						end)
					end
				end)
			]])

			while task.wait(5) do
				TeleportService:Teleport(5130598377)
			end
		end

		GuiService.ErrorMessageChanged:Connect(function()
			--local errorCode = GuiService:GetErrorCode()
			local errorType = GuiService:GetErrorType()
			if errorType == Enum.ConnectionError.DisconnectErrors then
				rejoin()
			end
		end)

		local function playerAdded(player)
			if not playerWhitelist[player.Name] then
				rejoin()
			end
		end

		Players.PlayerAdded:Connect(playerAdded)

		local function checkPlayers()
			for _, player in pairs(Players:GetPlayers()) do
				if player ~= localPlayer then
					playerAdded(player)
				end
			end
		end

		checkPlayers()
		features.autoRejoin = {
			onToggle = function(toggled)
				if toggled then
					checkPlayers()
				end
			end,
		}
	end
end

--ui interaction
do
	local TweenService = game:GetService("TweenService")
	local onGoingTweens: { [Instance]: Tween } = {}
	local function tween(obj, tweenInfo: TweenInfo, goal: { [string]: any }, callback: () -> ()?)
		if onGoingTweens[obj] then
			onGoingTweens[obj]:Cancel()
		end

		local tweenObj: Tween = TweenService:Create(obj, tweenInfo, goal)
		onGoingTweens[obj] = tweenObj
		tweenObj:Play()
		addConn(tweenObj.Completed:Connect(function(tweenState)
			if tweenState == Enum.PlaybackState.Completed then
				onGoingTweens[obj] = nil
				if callback then
					callback()
				end
			end
		end))
	end

	for name, feature in pairs(features) do
		local clone = holder.switches.template:Clone()
		clone.Visible = true
		clone.Name = name
		clone.TextLabel.Text = name
		clone.Parent = holder.switches

		local function toggle(toggled)
			state.enabledFeatures[name] = toggled
			stateUpdated()

			if feature.onToggle then
				task.spawn(feature.onToggle, toggled)
			end

			if toggled then
				tween(
					clone.Button.Slider,
					TweenInfo.new(0.1),
					{ BackgroundColor3 = Color3.new(0, 1, 0), Position = UDim2.fromScale(0.75, 0.5) }
				)
			else
				tween(
					clone.Button.Slider,
					TweenInfo.new(0.1),
					{ BackgroundColor3 = Color3.new(1, 0, 0), Position = UDim2.fromScale(0.25, 0.5) }
				)
			end
		end

		if state.enabledFeatures[name] == nil then
			state.enabledFeatures[name] = false
		else
			toggle(state.enabledFeatures[name])
		end

		clone.Button.MouseButton1Click:Connect(function()
			local toggled = not state.enabledFeatures[name]
			toggle(toggled)
		end)
	end

	local pages = scriptUI.Main.Pages.UIPageLayout
	scriptUI.Main.TopButtons.Next.MouseButton1Click:Connect(function()
		pages:Next()
	end)
	scriptUI.Main.TopButtons.Prev.MouseButton1Click:Connect(function()
		pages:Previous()
	end)

	local hidden = false
	scriptUI.Main.TopButtons.Hide.MouseButton1Click:Connect(function()
		tween(
			scriptUI.Main,
			TweenInfo.new(0.25),
			{ Size = UDim2.fromScale(0, 0), Position = UDim2.fromScale(1, 1) },
			function()
				scriptUI.Main.Visible = false
				scriptUI.Hidden.Size = UDim2.fromScale(0.1, 0.1)
				tween(
					scriptUI.Hidden,
					TweenInfo.new(0.25, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out),
					{ Transparency = 0, Size = UDim2.fromScale(0.25, 0.25) },
					function()
						tween(
							scriptUI.Hidden,
							TweenInfo.new(1, Enum.EasingStyle.Cubic, Enum.EasingDirection.In),
							{ Transparency = 1, Size = UDim2.fromScale(0.2, 0.2) }
						)
					end
				)
			end
		)

		hidden = true
	end)

	scriptUI.Hidden.InputBegan:Connect(function(input)
		if
			input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch
		then
			if hidden then
				hidden = false
				scriptUI.Hidden.Size = UDim2.fromScale(0.2, 0.2)
				tween(scriptUI.Hidden, TweenInfo.new(0.1), { Transparency = 1 }, function()
					scriptUI.Main.Visible = true
					tween(
						scriptUI.Main,
						TweenInfo.new(0.25, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out),
						{ Size = UDim2.fromScale(0.9, 0.9), Position = UDim2.fromScale(0.5, 0.5) }
					)
				end)
			end
		end
	end)
end

--Hitbox stuff
do
	if not _G.metaHook then
		local fallbackOld
		fallbackOld = hookmetamethod(game, "__index", function(...)
			if _G.hitboxHook then
				return _G.hitboxHook(getfenv(2), ...)
			else
				return fallbackOld(...)
			end
		end)
		_G.metaHook = fallbackOld
	end

	local oldIndex = _G.metaHook
	_G.hitboxHook = function(fenv, instance, index)
		if tostring(fenv.script) == "UI_Engine" then
			local parent = oldIndex(instance, "Parent")
			if parent == oldIndex(localPlayer, "Character") then
				if oldIndex(instance, "Name") == "HumanoidRootPart" and state.mode == "curses" then
					local cfr = oldIndex(instance, "CFrame")
					local old = cfr
					cfr *= _G.farmConfig.hitboxDistance

					if index == "CFrame" then
						return cfr
					elseif index == "Position" then
						return cfr.Position
					elseif index == "Orientation" then
						local rx, ry, rz = cfr:ToOrientation()
						return Vector3.new(math.deg(rx), math.deg(ry), math.deg(rz))
					elseif index == "Velocity" then
						return (old.Position - cfr.Position) * 9e9
					end
				end
			end
		end
		return oldIndex(instance, index)
	end
end

--anti afk
do
	addConn(localPlayer.Idled:connect(function()
		VirtualUser:CaptureController()
		VirtualUser:ClickButton2(Vector2.new())
	end))
end

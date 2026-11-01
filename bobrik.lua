local function __boberhookUILibrary()
local cloneref = cloneref or function(o) return o end
local Players = cloneref(game:GetService("Players"))
local UIS = cloneref(game:GetService("UserInputService"))
local TweenService = cloneref(game:GetService("TweenService"))
local RunService = cloneref(game:GetService("RunService"))
local HttpService = cloneref(game:GetService("HttpService"))
local CoreGui = cloneref(game:GetService("CoreGui"))
local GuiService = cloneref(game:GetService("GuiService"))
local LocalPlayer = Players.LocalPlayer

local Library = {
	Toggles = {}, Options = {}, Labels = {}, Buttons = {},
	Tabs = {}, Scales = {}, Corners = {}, DependencyBoxes = {}, SearchItems = {},
	Registry = {}, Connections = {}, UnloadCallbacks = {}, ColorHooks = {},
	Toggled = false, Unloaded = false, NotifySide = "Right", CornerRadius = 8,
	ShowToggleFrameInKeybinds = true, KeyPickers = {},
	Scheme = {
		BackgroundColor = Color3.fromRGB(12, 12, 13),
		MainColor = Color3.fromRGB(17, 17, 18),
		OutlineColor = Color3.fromRGB(32, 32, 34),
		FontColor = Color3.fromRGB(205, 205, 205),
		AccentColor = Color3.fromRGB(255, 255, 255),
		WhiteColor = Color3.fromRGB(255, 255, 255),
		DimColor = Color3.fromRGB(105, 105, 110),
		Font = Font.fromEnum(Enum.Font.GothamMedium),
	},
}
local Scheme = Library.Scheme

local TOUCH = UIS.TouchEnabled and not UIS.MouseEnabled

local function Connect(signal, fn)
	local c = signal:Connect(fn)
	Library.Connections[#Library.Connections + 1] = c
	return c
end

local function Reg(inst, props)
	Library.Registry[#Library.Registry + 1] = { Inst = inst, Props = props }
	for prop, key in pairs(props) do
		if Scheme[key] ~= nil then inst[prop] = Scheme[key] end
	end
	return inst
end

function Library:UpdateColorsUsingRegistry()
	for _, item in ipairs(self.Registry) do
		pcall(function()
			for prop, key in pairs(item.Props) do
				if Scheme[key] ~= nil then item.Inst[prop] = Scheme[key] end
			end
		end)
	end
	for _, fn in ipairs(self.ColorHooks) do pcall(fn) end
end

local function New(class, props, children)
	local inst = Instance.new(class)
	local reg
	for k, v in pairs(props or {}) do
		if k == "Reg" then reg = v
		elseif k == "Parent" then
		else inst[k] = v end
	end
	if class == "TextLabel" or class == "TextButton" or class == "TextBox" then
		if not (props and props.FontFace) then inst.FontFace = Scheme.Font end
	end
	for _, c in ipairs(children or {}) do c.Parent = inst end
	if reg then Reg(inst, reg) end
	if props and props.Parent then inst.Parent = props.Parent end
	return inst
end

local function Corner(parent, r)
	return New("UICorner", { CornerRadius = UDim.new(0, r or Library.CornerRadius), Parent = parent })
end
local function Stroke(parent, key, thick)
	return New("UIStroke", {
		Thickness = thick or 1, ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		Reg = { Color = key or "OutlineColor" }, Parent = parent,
	})
end
local function Pad(parent, l, t, r, b)
	return New("UIPadding", {
		PaddingLeft = UDim.new(0, l or 0), PaddingTop = UDim.new(0, t or 0),
		PaddingRight = UDim.new(0, r or 0), PaddingBottom = UDim.new(0, b or 0), Parent = parent,
	})
end
local function List(parent, gap, dir)
	return New("UIListLayout", {
		Padding = UDim.new(0, gap or 0), SortOrder = Enum.SortOrder.LayoutOrder,
		FillDirection = dir or Enum.FillDirection.Vertical, Parent = parent,
	})
end
local function Tween(inst, t, props)
	local tw = TweenService:Create(inst, TweenInfo.new(t, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), props)
	tw:Play()
	return tw
end

local function Round(v, r)
	r = r or 0
	local m = 10 ^ r
	return math.floor(v * m + 0.5) / m
end

function Library:SafeCallback(fn, ...)
	if typeof(fn) ~= "function" then return end
	local ok, err = pcall(fn, ...)
	if not ok then warn("[boberhookUI] callback error: " .. tostring(err)) end
end

function Library:OnUnload(fn) self.UnloadCallbacks[#self.UnloadCallbacks + 1] = fn end

local function InputScreenPos(pos)
	local inset = Vector2.zero
	pcall(function() inset = GuiService:GetGuiInset() end)
	return Vector2.new(pos.X, pos.Y + inset.Y)
end

local function MouseOver(gui)
	local p = UIS:GetMouseLocation()
	local pos, size = gui.AbsolutePosition, gui.AbsoluteSize
	local y = p.Y
	return p.X >= pos.X and p.X <= pos.X + size.X and y >= pos.Y and y <= pos.Y + size.Y
end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = HttpService:GenerateGUID(false):sub(1, 8)
ScreenGui.ResetOnSpawn = false
ScreenGui.IgnoreGuiInset = true
ScreenGui.DisplayOrder = 999
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
pcall(function() if syn and syn.protect_gui then syn.protect_gui(ScreenGui) end end)
ScreenGui.Parent = (gethui and gethui()) or CoreGui
Library.ScreenGui = ScreenGui

local Overlay = New("Frame", { Name = "Overlay", BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), ZIndex = 50, Parent = ScreenGui })
local TipLabel = New("TextLabel", {
	Visible = false, AutomaticSize = Enum.AutomaticSize.XY, Size = UDim2.fromOffset(0, 0), ZIndex = 90,
	TextSize = 12, TextWrapped = false, BorderSizePixel = 0, Reg = { BackgroundColor3 = "BackgroundColor", TextColor3 = "FontColor" },
	Parent = Overlay,
}, {})
Pad(TipLabel, 8, 5, 8, 5); Corner(TipLabel, 6); Stroke(TipLabel)

local hoverTip
local function Tooltip(gui, text)
	if typeof(text) ~= "string" or text == "" or TOUCH then return end
	Connect(gui.MouseEnter, function() hoverTip = gui; TipLabel.Text = text end)
	Connect(gui.MouseLeave, function() if hoverTip == gui then hoverTip = nil; TipLabel.Visible = false end end)
end
Connect(RunService.RenderStepped, function()
	if hoverTip and hoverTip.Parent and hoverTip:IsDescendantOf(game) then
		local m = UIS:GetMouseLocation()
		TipLabel.Visible = true
		TipLabel.Position = UDim2.fromOffset(m.X + 14, m.Y + 6)
	else
		TipLabel.Visible = false
	end
end)

local IconModule
function Library:SetIconModule(mod) IconModule = mod end

local function GetIcon(name)
	if not (IconModule and name) then return nil end
	local ok, res = pcall(function() return IconModule.GetAsset(name) end)
	if ok and type(res) == "table" then
		return { Image = res.Url or res.Image, RectOffset = res.ImageRectOffset or res.ImageRectPosition, RectSize = res.ImageRectSize }
	end
	return nil
end

local FALLBACK = { search = "?", bell = "*", ["chevron-down"] = "v", diamond = "o", keyboard = "#" }
local function MakeIcon(name, size, parent, colorKey)
	local data = GetIcon(name)
	if data and data.Image then
		return New("ImageLabel", {
			BackgroundTransparency = 1, Size = UDim2.fromOffset(size, size), Image = data.Image,
			ImageRectOffset = data.RectOffset or Vector2.zero, ImageRectSize = data.RectSize or Vector2.zero,
			Reg = { ImageColor3 = colorKey or "FontColor" }, Parent = parent,
		})
	end
	return New("TextLabel", {
		BackgroundTransparency = 1, Size = UDim2.fromOffset(size, size), Text = FALLBACK[name] or "", TextSize = size - 2,
		Reg = { TextColor3 = colorKey or "FontColor" }, Parent = parent,
	})
end

local ImageManager = { Assets = {} }
Library.ImageManager = ImageManager
function ImageManager.AddAsset(name, id, url)
	if id and id ~= 0 then ImageManager.Assets[name] = "rbxassetid://" .. tostring(id) return end
	if not url then return end
	pcall(function()
		if not (writefile and getcustomasset and isfile) then return end
		local dir = "boberhook"
		if makefolder and isfolder and not isfolder(dir) then makefolder(dir) end
		if makefolder and isfolder and not isfolder(dir .. "/assets") then makefolder(dir .. "/assets") end
		local path = dir .. "/assets/" .. name .. ".png"
		if not isfile(path) then
			local res = request and request({ Url = url, Method = "GET" })
			local body = res and res.Body or game:HttpGet(url)
			if body and body ~= "" then writefile(path, body) end
		end
		if isfile(path) then ImageManager.Assets[name] = getcustomasset(path) end
	end)
end
local B64 = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
local function b64decode(data)
	data = (data:gsub("[^%w%+/=]", ""))
	local lut = {}
	for i = 1, 64 do lut[B64:byte(i)] = i - 1 end
	local out, n = {}, 0
	for i = 1, #data, 4 do
		local a, b, c, d = data:byte(i, i + 3)
		local x = (lut[a] or 0) * 262144 + (lut[b] or 0) * 4096 + (lut[c] or 0) * 64 + (lut[d] or 0)
		local chunk = string.char(math.floor(x / 65536), math.floor(x / 256) % 256, x % 256)
		if d == 61 then chunk = chunk:sub(1, c == 61 and 1 or 2) end
		n = n + 1; out[n] = chunk
	end
	return table.concat(out)
end
function ImageManager.AddBase64(name, b64)
	pcall(function()
		if not (writefile and getcustomasset) then return end
		if makefolder and isfolder then
			if not isfolder("boberhook") then makefolder("boberhook") end
			if not isfolder("boberhook/assets") then makefolder("boberhook/assets") end
		end
		local path = "boberhook/assets/" .. name .. ".png"
		writefile(path, b64decode(b64))
		ImageManager.Assets[name] = getcustomasset(path)
	end)
end
function ImageManager.GetAsset(name) return ImageManager.Assets[name] or "" end

local function ResolveImage(img)
	if typeof(img) ~= "string" then return "" end
	if ImageManager.Assets[img] then return ImageManager.Assets[img] end
	return img
end

function Library:AddOutline(frame)
	local s = New("UIStroke", { Thickness = 1, ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Reg = { Color = "OutlineColor" }, Parent = frame })
	return s
end

function Library:MakeDraggable(frame, handle, cutoff)
	local dragging, startPos, startInput
	Connect(handle.InputBegan, function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true; startInput = input.Position; startPos = frame.Position
			local c; c = input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then dragging = false c:Disconnect() end
			end)
		end
	end)
	Connect(UIS.InputChanged, function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			local d = input.Position - startInput
			frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
		end
	end)
end

local OpenPopup
local function ClosePopup()
	if OpenPopup then
		local p = OpenPopup
		OpenPopup = nil
		pcall(p.close)
	end
end
local function ShowPopup(frame, anchor, width, closeFn)
	ClosePopup()
	frame.Parent = Overlay
	frame.ZIndex = 60
	local ap, asz = anchor.AbsolutePosition, anchor.AbsoluteSize
	local vp = ScreenGui.AbsoluteSize
	local x = ap.X
	local y = ap.Y + asz.Y + 4
	frame.Position = UDim2.fromOffset(math.clamp(x, 4, math.max(4, vp.X - width - 4)), y)
	frame.Visible = true
	OpenPopup = { frame = frame, anchor = anchor, close = function() frame.Visible = false if closeFn then closeFn() end end }
end
Connect(UIS.InputBegan, function(input)
	if OpenPopup and (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then
		local f, a = OpenPopup.frame, OpenPopup.anchor
		task.defer(function()
			if OpenPopup and OpenPopup.frame == f and not MouseOver(f) and not (a and MouseOver(a)) then ClosePopup() end
		end)
	end
end)

local function ApplyVisible(item)
	if item.Holder then item.Holder.Visible = not item.SearchHidden and not item.UserHidden end
end
function Library:UpdateDependencyBoxes()
	for _, box in ipairs(self.DependencyBoxes) do box:Update() end
end

local function RefreshGroupSearch(group)
	if not group.Frame then return end
	local q = Library.SearchText or ""
	if q == "" then group.Frame.Visible = true return end
	local any = false
	for _, it in ipairs(group.Items) do if not it.SearchHidden then any = true break end end
	group.Frame.Visible = any
end

function Library:Search(text)
	text = (text or ""):lower()
	self.SearchText = text
	for _, group in ipairs(self.Groups or {}) do
		local titleHit = text ~= "" and group.Name:lower():find(text, 1, true)
		for _, it in ipairs(group.Items) do
			local hit = text == "" or titleHit or (it.Text or ""):lower():find(text, 1, true)
			it.SearchHidden = not hit
			ApplyVisible(it)
		end
		RefreshGroupSearch(group)
	end
end

local Funcs = {}
Funcs.__index = Funcs

local function AddItem(self, holder, text, obj)
	local item = { Holder = holder, Text = text, SearchHidden = false, UserHidden = false }
	local group = self.Group
	group.Items[#group.Items + 1] = item
	if (Library.SearchText or "") ~= "" then Library:Search(Library.SearchText) end
	if obj then
		obj.Holder = holder
		obj._item = item
		function obj:SetVisible(v) item.UserHidden = not v; ApplyVisible(item); self.Visible = v end
		function obj:SetDisabled(d) self.Disabled = d end
		obj.Visible = true
	end
	return item
end

local function Row(self, height)
	return New("Frame", {
		BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, height or 28),
		AutomaticSize = height and Enum.AutomaticSize.None or Enum.AutomaticSize.Y, Parent = self.Container,
	})
end

local function MakeLabel(parent, text, size, key)
	return New("TextLabel", {
		BackgroundTransparency = 1, Text = text or "", TextSize = size or 13, TextXAlignment = Enum.TextXAlignment.Left,
		Reg = { TextColor3 = key or "FontColor" }, Parent = parent,
	})
end

local KeyNames = { MouseButton1 = "MB1", MouseButton2 = "MB2", MouseButton3 = "MB3" }
local function InputName(input)
	if input.UserInputType == Enum.UserInputType.Keyboard then return input.KeyCode.Name end
	if input.UserInputType == Enum.UserInputType.MouseButton1 then return "MB1" end
	if input.UserInputType == Enum.UserInputType.MouseButton2 then return "MB2" end
	if input.UserInputType == Enum.UserInputType.MouseButton3 then return "MB3" end
end

local Modes = { "Always", "Toggle", "Hold", "Press" }

local KEYBIND_SHOWN = { "Auto Parry", "Trigger Bot", "Humanizer", "Manual Spam" }
function Library:UpdateKeybindList()
	local list = self.KeybindList
	if not list then return end
	for _, c in ipairs(list:GetChildren()) do if c:IsA("Frame") then c:Destroy() end end
	local order = 0
	local prev, now = self.KeybindPrev or {}, {}
	local pulses = {}
	self.KeybindPulse = pulses
	for _, shown in ipairs(KEYBIND_SHOWN) do
		for _, kp in ipairs(self.KeyPickers) do
			if kp.Text == shown and kp.Value ~= "None" and not kp.NoUI then
				order = order + 1
				local state = kp:GetState()
				local isNew, wasOn = prev[kp] == nil, prev[kp]
				now[kp] = state and true or false
				local row = New("Frame", { Name = "Row", LayoutOrder = order, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 20), Parent = list })
				local flash
				if not isNew and state and not wasOn then
					flash = New("Frame", { BorderSizePixel = 0, Size = UDim2.new(1, 8, 1, 0), Position = UDim2.fromOffset(-4, 0),
						BackgroundColor3 = Scheme.AccentColor, BackgroundTransparency = 0.55, Parent = row })
					New("UICorner", { CornerRadius = UDim.new(0, 4), Parent = flash })
					Tween(flash, 0.6, { BackgroundTransparency = 1 })
				end
				if state then
					local bar = New("Frame", { BorderSizePixel = 0, Size = UDim2.fromOffset(2, 12), Position = UDim2.new(0, -7, 0.5, -6),
						BackgroundColor3 = Scheme.AccentColor, Parent = row })
					New("UICorner", { CornerRadius = UDim.new(1, 0), Parent = bar })
					pulses[#pulses + 1] = bar
				end
				local l1 = New("TextLabel", { BackgroundTransparency = 1, Size = UDim2.new(0.6, 0, 1, 0), TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left,
					Text = kp.Text or "", TextColor3 = state and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(150, 150, 156), Parent = row })
				local l2 = New("TextLabel", { AnchorPoint = Vector2.new(1, 0), Position = UDim2.fromScale(1, 0), BackgroundTransparency = 1, Size = UDim2.new(0.4, 0, 1, 0), TextSize = 13,
					TextXAlignment = Enum.TextXAlignment.Right, Text = "[ " .. tostring(kp.Value) .. " ]",
					TextColor3 = state and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(105, 105, 112), Parent = row })
				if isNew then
					for _, l in ipairs({ l1, l2 }) do
						local p0 = l.Position
						l.TextTransparency = 1
						l.Position = p0 + UDim2.fromOffset(-14, 0)
						Tween(l, 0.3, { TextTransparency = 0, Position = p0 })
					end
				elseif flash then
					l1.TextColor3 = Scheme.AccentColor
					Tween(l1, 0.6, { TextColor3 = Color3.fromRGB(255, 255, 255) })
				end
			end
		end
	end
	self.KeybindPrev = now
end

local function MakeBell(parent, optIdx, text, order)
	local btn = New("TextButton", { AutoButtonColor = false, Text = "", BackgroundTransparency = 1, Size = UDim2.fromOffset(18, 18), LayoutOrder = order or 2, Parent = parent })
	local icon = MakeIcon("bell", 14, btn, "DimColor")
	icon.AnchorPoint = Vector2.new(0.5, 0.5); icon.Position = UDim2.fromScale(0.5, 0.5)
	local opt = { Type = "NotifBell", Text = text, Default = true, Value = true }
	function opt:Display()
		local col = self.Value and Scheme.AccentColor or Scheme.DimColor
		if icon:IsA("ImageLabel") then icon.ImageColor3 = col else icon.TextColor3 = col end
	end
	function opt:SetValue(v)
		self.Value = v and true or false
		self:Display()
		Library:SafeCallback(self.Changed, self.Value)
	end
	function opt:OnChanged(fn) self.Changed = fn end
	Connect(btn.MouseButton1Click, function() opt:SetValue(not opt.Value) end)
	Tooltip(btn, "Notifications: on / off")
	Library.Options[optIdx] = opt
	table.insert(Library.ColorHooks, function() opt:Display() end)
	opt:Display()
	return opt, btn
end

local function AttachKeyPicker(self, idx, info, parentToggle, rowRight)
	info = info or {}
	local kp = {
		Type = "KeyPicker", Text = info.Text or idx, Default = info.Default or "None", Value = info.Default or "None",
		Mode = info.Mode or "Toggle", Modifiers = {}, Picking = false, Toggled = false, Held = false,
		SyncToggleState = info.SyncToggleState and parentToggle ~= nil, NoUI = info.NoUI, Callback = info.Callback,
		Parent = parentToggle,
	}
	if not table.find(Modes, kp.Mode) then kp.Mode = "Toggle" end
	if kp.Value == nil or kp.Value == "" then kp.Value = "None" end
	if type(kp.Value) ~= "string" then kp.Value = "None" end

	local chip = New("TextButton", {
		AutoButtonColor = false, AutomaticSize = Enum.AutomaticSize.X, Size = UDim2.fromOffset(40, 24), Text = "", LayoutOrder = 1,
		BorderSizePixel = 0, Reg = { BackgroundColor3 = "BackgroundColor" }, Parent = rowRight,
	})
	Corner(chip, 5); local chipStroke = Stroke(chip); Pad(chip, 8, 0, 8, 0)
	local chipText = New("TextLabel", {
		BackgroundTransparency = 1, Size = UDim2.new(0, 0, 1, 0), AutomaticSize = Enum.AutomaticSize.X, TextSize = 12,
		Text = kp.Value, Reg = { TextColor3 = "FontColor" }, Parent = chip,
	})
	local bellOpt = nil
	if info.Notify then
		bellOpt = MakeBell(rowRight, "notif_" .. idx, (info.Text or idx) .. " Notifications", 2)
	end
	local diamond = nil
	if parentToggle then
		diamond = MakeIcon("diamond", 13, rowRight, "DimColor"); diamond.LayoutOrder = 0
		diamond.Parent = rowRight
	end
	Tooltip(chip, "Click: set key. Right click: change mode.")
	local wasPicking = false
	Connect(RunService.RenderStepped, function()
		if kp.Picking then
			wasPicking = true
			local w = 0.5 + 0.5 * math.sin(os.clock() * 7)
			chipStroke.Color = Scheme.OutlineColor:Lerp(Scheme.AccentColor, w)
			chipText.TextTransparency = 0.5 * (1 - w)
		elseif wasPicking then
			wasPicking = false
			chipStroke.Color = Scheme.OutlineColor
			chipText.TextTransparency = 0
			Tween(chip, 0.12, { BackgroundTransparency = 0.5 }).Completed:Connect(function() Tween(chip, 0.25, { BackgroundTransparency = 0 }) end)
		end
	end)

	function kp:GetState()
		if self.Mode == "Always" then return true end
		if self.Mode == "Hold" then return self.Held end
		return self.Toggled
	end
	function kp:Display()
		chipText.Text = self.Picking and "..." or self.Value
		local st = self:GetState()
		local col = st and Scheme.AccentColor or Scheme.DimColor
		if diamond then
			if diamond:IsA("ImageLabel") then diamond.ImageColor3 = col else diamond.TextColor3 = col end
		end
	end
	function kp:Update()
		self:Display()
		Library:UpdateKeybindList()
	end
	function kp:Activate()
		self:Update()
		if self.SyncToggleState and self.Parent and self.Mode ~= "Press" then self.Parent:SetValue(self:GetState()) end
		self:DoClick()
	end
	function kp:DoClick()
		Library:SafeCallback(self.Callback, self:GetState())
		Library:SafeCallback(self.Clicked, self:GetState())
	end
	function kp:OnChanged(fn) self.Changed = fn end
	function kp:OnClick(fn) self.Clicked = fn end
	function kp:SetValue(data)
		local key, mode = self.Value, self.Mode
		if type(data) == "table" then key = data[1] or key; mode = data[2] or mode
		elseif type(data) == "string" then key = data end
		if type(key) ~= "string" or key == "" then key = "None" end
		if not table.find(Modes, mode) then mode = "Toggle" end
		self.Value, self.Mode = key, mode
		if mode == "Always" then self.Toggled = true end
		self:Update()
		Library:SafeCallback(self.Changed, self.Value, self.Modifiers)
	end
	function kp:SetMode(m)
		if not table.find(Modes, m) then return end
		local prev = self.Mode
		self.Mode = m
		self.Held = false
		if m == "Always" then
			self.Toggled = true
		elseif m == "Toggle" then
			if self.SyncToggleState and self.Parent then self.Toggled = self.Parent.Value and true or false
			elseif prev == "Always" then self.Toggled = false end
		end
		self:Update()
		if self.SyncToggleState and self.Parent and m ~= "Press" and self.Parent.Value ~= self:GetState() then
			self.Parent:SetValue(self:GetState())
		end
		Library:SafeCallback(self.Changed, self.Value, self.Modifiers)
	end

	local MODE_ROW_H, MODE_W = 30, 116
	local function OpenModeMenu()
		if kp.Picking then return end
		if OpenPopup and OpenPopup.anchor == chip then ClosePopup() return end
		local menu = New("Frame", { Visible = false, Active = true, Size = UDim2.fromOffset(MODE_W, #Modes * MODE_ROW_H + 8), BorderSizePixel = 0, Reg = { BackgroundColor3 = "MainColor" } })
		Corner(menu, 6); Stroke(menu); Pad(menu, 4, 4, 4, 4); List(menu, 0)
		for n, m in ipairs(Modes) do
			local cur = (m == kp.Mode)
			local b = New("TextButton", { AutoButtonColor = false, Active = true, ZIndex = 61, LayoutOrder = n, Size = UDim2.new(1, 0, 0, MODE_ROW_H),
				BackgroundTransparency = cur and 0.8 or 1, Text = (cur and "• " or "   ") .. m, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left, BorderSizePixel = 0,
				Reg = { TextColor3 = cur and "AccentColor" or "FontColor", BackgroundColor3 = "OutlineColor" }, Parent = menu })
			Corner(b, 5); Pad(b, 6, 0, 6, 0)
			Connect(b.MouseEnter, function() b.BackgroundTransparency = 0.6 end)
			Connect(b.MouseLeave, function() b.BackgroundTransparency = cur and 0.8 or 1 end)
			local done = false
			local function pick()
				if done then return end
				done = true
				kp:SetMode(m)
				ClosePopup()
			end
			Connect(b.InputBegan, function(i)
				if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then pick() end
			end)
			Connect(b.MouseButton1Click, pick)
		end
		ShowPopup(menu, chip, MODE_W, function() menu:Destroy() end)
	end

	Connect(chip.MouseButton1Click, function()
		if kp.Picking then return end
		kp.Picking = true; kp:Display()
		task.wait(0.1)
		local c; c = UIS.InputBegan:Connect(function(input)
			local name = InputName(input)
			if name then
				c:Disconnect()
				task.defer(function()
					kp.Picking = false
					kp:SetValue({ name, kp.Mode })
				end)
			end
		end)
	end)
	Connect(chip.MouseButton2Click, OpenModeMenu)
	if diamond and diamond:IsA("ImageLabel") == false then diamond.Active = false end

	Library.KeyPickers[#Library.KeyPickers + 1] = kp
	Library.Options[idx] = kp
	table.insert(Library.ColorHooks, function() kp:Display() end)
	kp:Display()
	Library:UpdateKeybindList()
	return kp
end

function Funcs:AddToggle(idx, info)
	info = info or {}
	local t = {
		Type = "Toggle", Text = info.Text or idx, Default = info.Default and true or false, Value = info.Default and true or false,
		Tooltip = info.Tooltip, Callback = info.Callback, Addons = {}, Disabled = info.Disabled, Risky = info.Risky,
	}
	local holder = Row(self, 30)
	local label = MakeLabel(holder, t.Text, 13)
	label.Size = UDim2.new(1, -90, 1, 0)
	local right = New("Frame", { BackgroundTransparency = 1, AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, 0, 0.5, 0),
		Size = UDim2.new(0, 0, 1, 0), AutomaticSize = Enum.AutomaticSize.X, Parent = holder })
	List(right, 8, Enum.FillDirection.Horizontal).VerticalAlignment = Enum.VerticalAlignment.Center
	right.UIListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right

	local box = New("TextButton", { AutoButtonColor = false, Text = "", Size = UDim2.fromOffset(18, 18), LayoutOrder = 10, BorderSizePixel = 0,
		BackgroundColor3 = Scheme.BackgroundColor, Parent = right })
	Corner(box, 5); local boxStroke = Stroke(box)
	local tick = New("TextLabel", { BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), Text = "✓", TextSize = 12, TextTransparency = 1,
		TextColor3 = Color3.fromRGB(10, 10, 10), Parent = box })
	local pill = New("TextButton", { AutoButtonColor = false, Text = "", Size = UDim2.fromOffset(34, 18), LayoutOrder = 10, Visible = false, BorderSizePixel = 0,
		BackgroundColor3 = Scheme.BackgroundColor, Parent = right })
	Corner(pill, 9); local pillStroke = Stroke(pill)
	local knob = New("Frame", { Size = UDim2.fromOffset(12, 12), Position = UDim2.fromOffset(3, 3), BorderSizePixel = 0, BackgroundColor3 = Scheme.DimColor, Parent = pill })
	Corner(knob, 6)
	Tooltip(holder, t.Tooltip)

	function t:Display()
		local on = self.Value
		boxStroke.Color = on and Scheme.AccentColor or Scheme.OutlineColor
		Tween(box, 0.12, { BackgroundColor3 = on and Scheme.AccentColor or Scheme.BackgroundColor })
		tick.TextTransparency = on and 0 or 1
		Tween(pill, 0.12, { BackgroundColor3 = on and Scheme.AccentColor or Scheme.BackgroundColor })
		pillStroke.Color = on and Scheme.AccentColor or Scheme.OutlineColor
		Tween(knob, 0.12, { Position = UDim2.fromOffset(on and 19 or 3, 3), BackgroundColor3 = on and Scheme.BackgroundColor or Scheme.DimColor })
		label.TextColor3 = (self.Disabled and Scheme.DimColor) or Scheme.FontColor
	end
	function t:SetValue(v)
		if self.Disabled then return end
		self.Value = v and true or false
		self:Display()
		for _, a in ipairs(self.Addons) do
			if a.Type == "KeyPicker" and a.SyncToggleState then a.Toggled = self.Value a:Display() Library:UpdateKeybindList() end
		end
		Library:UpdateDependencyBoxes()
		Library:SafeCallback(self.Callback, self.Value)
		Library:SafeCallback(self.Changed, self.Value)
	end
	function t:OnChanged(fn) self.Changed = fn end
	function t:SetText(s) self.Text = s label.Text = s end
	local function click() t:SetValue(not t.Value) end
	Connect(box.MouseButton1Click, click)
	Connect(pill.MouseButton1Click, click)
	Connect(holder.InputBegan, function(i)
		if (i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch)
			and not MouseOver(right) then click() end
	end)

	function t:AddKeyPicker(kidx, kinfo)
		if not self.PillOn then self.PillOn = true; box.Visible = false; pill.Visible = true end
		local kp = AttachKeyPicker(self, kidx, kinfo, self, right)
		self.Addons[#self.Addons + 1] = kp
		return kp
	end
	function t:AddColorPicker(cidx, cinfo)
		local cp = self._makeColor(cidx, cinfo, right)
		self.Addons[#self.Addons + 1] = cp
		return cp
	end
	t._makeColor = function(cidx, cinfo, parent) return Funcs._ColorPicker(self, cidx, cinfo, parent) end

	AddItem(self, holder, t.Text, t)
	t:Display()
	table.insert(Library.ColorHooks, function() t:Display() end)
	Library.Toggles[idx] = t
	return t
end

function Funcs:AddLabel(a, b)
	local idx, text, wrap
	if type(b) == "table" then idx = a; text = b.Text or b.Default or ""; wrap = b.DoesWrap
	else text = a; wrap = b end
	local l = { Type = "Label", Text = text, Addons = {} }
	local holder = Row(self, wrap and nil or 26)
	local label = MakeLabel(holder, text, 13, wrap and "DimColor" or "FontColor")
	label.TextWrapped = wrap and true or false
	label.Size = wrap and UDim2.new(1, 0, 0, 0) or UDim2.new(1, -60, 1, 0)
	if wrap then label.AutomaticSize = Enum.AutomaticSize.Y; label.TextYAlignment = Enum.TextYAlignment.Top end
	local right = New("Frame", { BackgroundTransparency = 1, AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, 0, 0.5, 0),
		Size = UDim2.new(0, 0, 1, 0), AutomaticSize = Enum.AutomaticSize.X, Parent = holder })
	local lay = List(right, 8, Enum.FillDirection.Horizontal)
	lay.VerticalAlignment = Enum.VerticalAlignment.Center; lay.HorizontalAlignment = Enum.HorizontalAlignment.Right
	function l:SetText(s) self.Text = s label.Text = s end
	function l:AddKeyPicker(kidx, kinfo)
		local kp = AttachKeyPicker(self, kidx, kinfo, nil, right)
		self.Addons[#self.Addons + 1] = kp
		return kp
	end
	function l:AddColorPicker(cidx, cinfo)
		local cp = Funcs._ColorPicker(self, cidx, cinfo, right)
		self.Addons[#self.Addons + 1] = cp
		return cp
	end
	AddItem(self, holder, text, l)
	if idx then Library.Labels[idx] = l end
	return l
end

function Funcs._ColorPicker(owner, idx, info, rightParent)
	info = info or {}
	local default = typeof(info.Default) == "Color3" and info.Default or Color3.new(1, 1, 1)
	local h, s, v = default:ToHSV()
	local cp = { Type = "ColorPicker", Title = info.Title or "Color", Default = default, Value = default, Hue = h, Sat = s, Vib = v,
		Transparency = info.Transparency or 0, Callback = info.Callback }
	local swatch = New("TextButton", { AutoButtonColor = false, Text = "", Size = UDim2.fromOffset(22, 18), BorderSizePixel = 0, BackgroundColor3 = default, LayoutOrder = 5, Parent = rightParent })
	Corner(swatch, 5); Stroke(swatch)

	local popup, sv, svCursor, hueBar, hueCursor, hexBox, rgbBox
	local function Apply(fire)
		cp.Value = Color3.fromHSV(cp.Hue, cp.Sat, cp.Vib)
		swatch.BackgroundColor3 = cp.Value
		if popup then
			sv.BackgroundColor3 = Color3.fromHSV(cp.Hue, 1, 1)
			svCursor.Position = UDim2.fromScale(cp.Sat, 1 - cp.Vib)
			hueCursor.Position = UDim2.new(0, 0, cp.Hue, 0)
			hexBox.Text = "#" .. cp.Value:ToHex()
			rgbBox.Text = string.format("%d, %d, %d", cp.Value.R * 255 + 0.5, cp.Value.G * 255 + 0.5, cp.Value.B * 255 + 0.5)
		end
		if fire then
			Library:SafeCallback(cp.Callback, cp.Value)
			Library:SafeCallback(cp.Changed, cp.Value)
		end
	end
	function cp:Display() Apply(false) end
	function cp:OnChanged(fn) self.Changed = fn end
	function cp:SetValue(hsv, transparency)
		self.Hue, self.Sat, self.Vib = hsv[1], hsv[2], hsv[3]
		self.Transparency = transparency or self.Transparency
		Apply(true)
	end
	function cp:SetValueRGB(c, transparency)
		if typeof(c) ~= "Color3" then return end
		self.Hue, self.Sat, self.Vib = c:ToHSV()
		self.Transparency = transparency or self.Transparency
		Apply(true)
	end

	local function build()
		popup = New("Frame", { Visible = false, Size = UDim2.fromOffset(236, 232), BorderSizePixel = 0, Reg = { BackgroundColor3 = "MainColor" } })
		Corner(popup, 8); Stroke(popup); Pad(popup, 10, 8, 10, 10)
		MakeLabel(popup, cp.Title, 12, "DimColor").Size = UDim2.new(1, 0, 0, 16)
		sv = New("TextButton", { AutoButtonColor = false, Text = "", Position = UDim2.fromOffset(0, 22), Size = UDim2.fromOffset(190, 150), BorderSizePixel = 0, BackgroundColor3 = Color3.fromHSV(cp.Hue, 1, 1), Parent = popup })
		Corner(sv, 4)
		local w = New("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0, Parent = sv })
		New("UIGradient", { Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(1, 1) }), Parent = w }); Corner(w, 4)
		local k = New("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(0, 0, 0), BorderSizePixel = 0, Parent = sv })
		New("UIGradient", { Rotation = 90, Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(1, 0) }), Parent = k }); Corner(k, 4)
		svCursor = New("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.fromOffset(8, 8), BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0, ZIndex = 3, Parent = sv })
		Corner(svCursor, 4); New("UIStroke", { Color = Color3.new(0, 0, 0), Parent = svCursor })
		hueBar = New("TextButton", { AutoButtonColor = false, Text = "", Position = UDim2.fromOffset(198, 22), Size = UDim2.fromOffset(16, 150), BorderSizePixel = 0, BackgroundColor3 = Color3.new(1, 1, 1), Parent = popup })
		Corner(hueBar, 4)
		local seq = {}
		for i = 0, 6 do seq[#seq + 1] = ColorSequenceKeypoint.new(i / 6, Color3.fromHSV(i / 6, 1, 1)) end
		New("UIGradient", { Rotation = 90, Color = ColorSequence.new(seq), Parent = hueBar })
		hueCursor = New("Frame", { AnchorPoint = Vector2.new(0, 0.5), Size = UDim2.new(1, 0, 0, 3), BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0, Parent = hueBar })
		hexBox = New("TextBox", { Position = UDim2.fromOffset(0, 180), Size = UDim2.fromOffset(100, 24), TextSize = 12, ClearTextOnFocus = false, BorderSizePixel = 0,
			Reg = { BackgroundColor3 = "BackgroundColor", TextColor3 = "FontColor" }, Parent = popup })
		Corner(hexBox, 5); Stroke(hexBox)
		rgbBox = New("TextBox", { Position = UDim2.fromOffset(106, 180), Size = UDim2.fromOffset(108, 24), TextSize = 12, ClearTextOnFocus = false, BorderSizePixel = 0,
			Reg = { BackgroundColor3 = "BackgroundColor", TextColor3 = "FontColor" }, Parent = popup })
		Corner(rgbBox, 5); Stroke(rgbBox)

		local function drag(gui, fn)
			Connect(gui.InputBegan, function(i)
				if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
					local moving = true
					local c1, c2
					local function upd(p) local sp = InputScreenPos(p) fn(sp.X, sp.Y) end
					upd(i.Position)
					c1 = UIS.InputChanged:Connect(function(m)
						if moving and (m.UserInputType == Enum.UserInputType.MouseMovement or m.UserInputType == Enum.UserInputType.Touch) then upd(m.Position) end
					end)
					c2 = UIS.InputEnded:Connect(function(e)
						if e.UserInputType == Enum.UserInputType.MouseButton1 or e.UserInputType == Enum.UserInputType.Touch then moving = false c1:Disconnect() c2:Disconnect() end
					end)
				end
			end)
		end
		drag(sv, function(x, y)
			cp.Sat = math.clamp((x - sv.AbsolutePosition.X) / sv.AbsoluteSize.X, 0, 1)
			cp.Vib = 1 - math.clamp((y - sv.AbsolutePosition.Y) / sv.AbsoluteSize.Y, 0, 1)
			Apply(true)
		end)
		drag(hueBar, function(_, y)
			cp.Hue = math.clamp((y - hueBar.AbsolutePosition.Y) / hueBar.AbsoluteSize.Y, 0, 1)
			Apply(true)
		end)
		Connect(hexBox.FocusLost, function()
			local ok, c = pcall(Color3.fromHex, hexBox.Text)
			if ok then cp:SetValueRGB(c) else Apply(false) end
		end)
		Connect(rgbBox.FocusLost, function()
			local r, g, b = rgbBox.Text:match("(%d+)%D+(%d+)%D+(%d+)")
			if r then cp:SetValueRGB(Color3.fromRGB(math.min(255, tonumber(r)), math.min(255, tonumber(g)), math.min(255, tonumber(b)))) else Apply(false) end
		end)
		Apply(false)
	end

	Connect(swatch.MouseButton1Click, function()
		if popup and OpenPopup and OpenPopup.frame == popup then ClosePopup() return end
		if not popup then build() end
		ShowPopup(popup, swatch, 236, nil)
		popup.Position = UDim2.fromOffset(math.clamp(swatch.AbsolutePosition.X - 200, 4, ScreenGui.AbsoluteSize.X - 240), swatch.AbsolutePosition.Y + swatch.AbsoluteSize.Y + 4)
		Apply(false)
	end)

	Library.Options[idx] = cp
	return cp
end

local SLIDER_ROW_H, SLIDER_HIT_H, SLIDER_TRACK_H, SLIDER_KNOB = 54, 34, 8, 18
function Funcs:AddSlider(idx, info)
	info = info or {}
	local s = { Type = "Slider", Text = info.Text or idx, Min = info.Min or 0, Max = info.Max or 100, Rounding = info.Rounding or 0,
		Prefix = info.Prefix or "", Suffix = info.Suffix or "", Callback = info.Callback, Default = info.Default or info.Min or 0, Tooltip = info.Tooltip }
	s.Value = s.Default
	local holder = Row(self, SLIDER_ROW_H)
	local label = MakeLabel(holder, s.Text, 13)
	label.Size = UDim2.new(1, -70, 0, 20)
	local valLabel = MakeLabel(holder, "", 12, "DimColor")
	valLabel.AnchorPoint = Vector2.new(1, 0); valLabel.Position = UDim2.new(1, 0, 0, 0); valLabel.Size = UDim2.new(0, 70, 0, 20); valLabel.TextXAlignment = Enum.TextXAlignment.Right
	local hit = New("TextButton", { AutoButtonColor = false, Text = "", BackgroundTransparency = 1, BorderSizePixel = 0,
		AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, 0, 1, 0), Size = UDim2.new(1, 0, 0, SLIDER_HIT_H), Parent = holder })
	local bar = New("Frame", { AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 0, 0.5, 0), Size = UDim2.new(1, 0, 0, SLIDER_TRACK_H), BorderSizePixel = 0,
		Reg = { BackgroundColor3 = "OutlineColor" }, Parent = hit })
	Corner(bar, SLIDER_TRACK_H // 2)
	local fill = New("Frame", { Size = UDim2.fromScale(0, 1), BorderSizePixel = 0, Reg = { BackgroundColor3 = "AccentColor" }, Parent = bar }); Corner(fill, SLIDER_TRACK_H // 2)
	local knob = New("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.fromOffset(SLIDER_KNOB, SLIDER_KNOB), Position = UDim2.fromScale(0, 0.5), BorderSizePixel = 0,
		Reg = { BackgroundColor3 = "AccentColor" }, Parent = bar }); Corner(knob, SLIDER_KNOB // 2)
	Tooltip(holder, s.Tooltip)

	function s:Display()
		local range = math.max(self.Max - self.Min, 1e-9)
		local a = math.clamp((self.Value - self.Min) / range, 0, 1)
		fill.Size = UDim2.fromScale(a, 1); knob.Position = UDim2.fromScale(a, 0.5)
		valLabel.Text = self.Prefix .. tostring(self.Value) .. self.Suffix
	end
	function s:SetValue(v)
		if self.Disabled then return end
		v = tonumber(v)
		if not v then return end
		v = math.clamp(Round(v, self.Rounding), self.Min, self.Max)
		self.Value = v
		self:Display()
		Library:SafeCallback(self.Callback, self.Value)
		Library:SafeCallback(self.Changed, self.Value)
	end
	function s:OnChanged(fn) self.Changed = fn end
	function s:SetMax(m) self.Max = m self:SetValue(self.Value) end
	function s:SetMin(m) self.Min = m self:SetValue(self.Value) end
	function s:SetText(t) self.Text = t label.Text = t end

	local function setFromX(x)
		local a = math.clamp((x - bar.AbsolutePosition.X) / math.max(bar.AbsoluteSize.X, 1), 0, 1)
		local nv = Round(s.Min + (s.Max - s.Min) * a, s.Rounding)
		if nv ~= s.Value then s:SetValue(nv) end
	end
	Connect(hit.InputBegan, function(i)
		if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
			local moving = true
			setFromX(i.Position.X)
			local c1, c2
			c1 = UIS.InputChanged:Connect(function(m)
				if moving and (m.UserInputType == Enum.UserInputType.MouseMovement or m.UserInputType == Enum.UserInputType.Touch) then setFromX(m.Position.X) end
			end)
			c2 = UIS.InputEnded:Connect(function(e)
				if e.UserInputType == Enum.UserInputType.MouseButton1 or e.UserInputType == Enum.UserInputType.Touch then moving = false c1:Disconnect() c2:Disconnect() end
			end)
		end
	end)

	AddItem(self, holder, s.Text, s)
	s:Display()
	Library.Options[idx] = s
	return s
end

function Funcs:AddRangeSlider(idx, info)
	info = info or {}
	local s = { Type = "RangeSlider", Text = info.Text or idx, Min = info.Min or 0, Max = info.Max or 100, Rounding = info.Rounding or 0,
		Prefix = info.Prefix or "", Suffix = info.Suffix or "", Callback = info.Callback, Tooltip = info.Tooltip }
	s.ValueMin = math.clamp(info.DefaultMin or s.Min, s.Min, s.Max)
	s.ValueMax = math.clamp(info.DefaultMax or s.Max, s.ValueMin, s.Max)
	s.Default = { s.ValueMin, s.ValueMax }
	s.Value = { s.ValueMin, s.ValueMax }
	local holder = Row(self, SLIDER_ROW_H)
	local label = MakeLabel(holder, s.Text, 13)
	label.Size = UDim2.new(1, -90, 0, 20)
	local valLabel = MakeLabel(holder, "", 12, "DimColor")
	valLabel.AnchorPoint = Vector2.new(1, 0); valLabel.Position = UDim2.new(1, 0, 0, 0); valLabel.Size = UDim2.new(0, 90, 0, 20); valLabel.TextXAlignment = Enum.TextXAlignment.Right
	local hit = New("TextButton", { AutoButtonColor = false, Text = "", BackgroundTransparency = 1, BorderSizePixel = 0,
		AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, 0, 1, 0), Size = UDim2.new(1, 0, 0, SLIDER_HIT_H), Parent = holder })
	local bar = New("Frame", { AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 0, 0.5, 0), Size = UDim2.new(1, 0, 0, SLIDER_TRACK_H), BorderSizePixel = 0,
		Reg = { BackgroundColor3 = "OutlineColor" }, Parent = hit })
	Corner(bar, SLIDER_TRACK_H // 2)
	local fill = New("Frame", { Size = UDim2.fromScale(0, 1), BorderSizePixel = 0, Reg = { BackgroundColor3 = "AccentColor" }, Parent = bar }); Corner(fill, SLIDER_TRACK_H // 2)
	local knobLo = New("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.fromOffset(SLIDER_KNOB, SLIDER_KNOB), Position = UDim2.fromScale(0, 0.5), BorderSizePixel = 0,
		Reg = { BackgroundColor3 = "AccentColor" }, Parent = bar }); Corner(knobLo, SLIDER_KNOB // 2)
	local knobHi = New("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.fromOffset(SLIDER_KNOB, SLIDER_KNOB), Position = UDim2.fromScale(1, 0.5), BorderSizePixel = 0,
		Reg = { BackgroundColor3 = "AccentColor" }, Parent = bar }); Corner(knobHi, SLIDER_KNOB // 2)
	Tooltip(holder, s.Tooltip)

	function s:Display()
		local range = math.max(self.Max - self.Min, 1e-9)
		local a = math.clamp((self.ValueMin - self.Min) / range, 0, 1)
		local b = math.clamp((self.ValueMax - self.Min) / range, 0, 1)
		fill.Position = UDim2.fromScale(a, 0); fill.Size = UDim2.fromScale(b - a, 1)
		knobLo.Position = UDim2.fromScale(a, 0.5); knobHi.Position = UDim2.fromScale(b, 0.5)
		valLabel.Text = self.Prefix .. tostring(self.ValueMin) .. " - " .. tostring(self.ValueMax) .. self.Suffix
	end
	function s:SetValue(lo, hi)
		if self.Disabled then return end
		if type(lo) == "table" then lo, hi = lo[1], lo[2] end
		lo, hi = tonumber(lo), tonumber(hi)
		if not lo or not hi then return end
		lo = math.clamp(Round(lo, self.Rounding), self.Min, self.Max)
		hi = math.clamp(Round(hi, self.Rounding), self.Min, self.Max)
		if lo > hi then lo, hi = hi, lo end
		self.ValueMin, self.ValueMax = lo, hi
		self.Value = { lo, hi }
		self:Display()
		Library:SafeCallback(self.Callback, lo, hi)
		Library:SafeCallback(self.Changed, lo, hi)
	end
	function s:OnChanged(fn) self.Changed = fn end
	function s:SetText(t) self.Text = t label.Text = t end

	local function valueAtX(x)
		local a = math.clamp((x - bar.AbsolutePosition.X) / math.max(bar.AbsoluteSize.X, 1), 0, 1)
		return Round(s.Min + (s.Max - s.Min) * a, s.Rounding)
	end
	Connect(hit.InputBegan, function(i)
		if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
			local p = i.Position
			local v = valueAtX(p.X)
			local dLo, dHi = math.abs(v - s.ValueMin), math.abs(v - s.ValueMax)
			local anchor
			if dLo < dHi then anchor = s.ValueMax
			elseif dLo > dHi then anchor = s.ValueMin
			else anchor = (v <= s.ValueMin) and s.ValueMax or s.ValueMin end
			local function apply(x)
				local nv = valueAtX(x)
				local lo, hi = math.min(anchor, nv), math.max(anchor, nv)
				if lo ~= s.ValueMin or hi ~= s.ValueMax then s:SetValue(lo, hi) end
			end
			local moving = true
			apply(p.X)
			local c1, c2
			c1 = UIS.InputChanged:Connect(function(m)
				if moving and (m.UserInputType == Enum.UserInputType.MouseMovement or m.UserInputType == Enum.UserInputType.Touch) then apply(m.Position.X) end
			end)
			c2 = UIS.InputEnded:Connect(function(e)
				if e.UserInputType == Enum.UserInputType.MouseButton1 or e.UserInputType == Enum.UserInputType.Touch then moving = false c1:Disconnect() c2:Disconnect() end
			end)
		end
	end)

	AddItem(self, holder, s.Text, s)
	s:Display()
	Library.Options[idx] = s
	return s
end

function Funcs:AddDropdown(idx, info)
	info = info or {}
	local d = { Type = "Dropdown", Text = info.Text, Values = info.Values or {}, Multi = info.Multi, Callback = info.Callback, Tooltip = info.Tooltip,
		AllowNull = info.AllowNull, Default = info.Default }
	local holder = Row(self, nil)
	List(holder, 4)
	if d.Text then
		local l = MakeLabel(holder, d.Text, 13); l.Size = UDim2.new(1, 0, 0, 18); l.LayoutOrder = 1
	end
	local box = New("TextButton", { AutoButtonColor = false, Text = "", Size = UDim2.new(1, 0, 0, 30), LayoutOrder = 2, BorderSizePixel = 0,
		Reg = { BackgroundColor3 = "BackgroundColor" }, Parent = holder })
	Corner(box, 6); Stroke(box); Pad(box, 10, 0, 8, 0)
	local sel = MakeLabel(box, "", 12); sel.Size = UDim2.new(1, -22, 1, 0)
	local chev = MakeIcon("chevron-down", 14, box, "DimColor"); chev.AnchorPoint = Vector2.new(1, 0.5); chev.Position = UDim2.new(1, 0, 0.5, 0)
	Tooltip(holder, d.Tooltip)

	if d.Multi then d.Value = {} end
	local def = d.Default
	if type(def) == "number" then def = d.Values[def] end
	if not d.Multi then d.Value = def end
	if d.Multi and type(info.Default) == "table" then for k, v in pairs(info.Default) do if v then d.Value[type(k) == "number" and d.Values[k] or k] = true end end end

	function d:Display()
		local txt
		if self.Multi then
			local t = {}
			for _, v in ipairs(self.Values) do if self.Value[v] then t[#t + 1] = tostring(v) end end
			txt = table.concat(t, ", ")
		else
			txt = self.Value ~= nil and tostring(self.Value) or ""
		end
		sel.Text = txt
	end
	local function fire()
		Library:SafeCallback(d.Callback, d.Value)
		Library:SafeCallback(d.Changed, d.Value)
	end
	function d:SetValue(v)
		if self.Multi then
			self.Value = {}
			if type(v) == "table" then for k, val in pairs(v) do if val then self.Value[type(k) == "number" and self.Values[k] or k] = true end end end
		else
			if type(v) == "number" then v = self.Values[v] end
			if v ~= nil and not table.find(self.Values, v) then v = (self.AllowNull and nil) or self.Value end
			self.Value = v
		end
		self:Display(); fire()
	end
	function d:SetValues(vals) self.Values = vals; if not self.Multi and self.Value ~= nil and not table.find(vals, self.Value) then self.Value = nil end self:Display() end
	function d:OnChanged(fn) self.Changed = fn end
	function d:SetText(t) self.Text = t end

	Connect(box.MouseButton1Click, function()
		if OpenPopup and OpenPopup.anchor == box then ClosePopup() return end
		local count = #d.Values
		local h = math.min(count, 7) * 26 + 8
		local pop = New("ScrollingFrame", { Visible = false, Size = UDim2.fromOffset(box.AbsoluteSize.X, h), BorderSizePixel = 0, ScrollBarThickness = 3,
			CanvasSize = UDim2.fromOffset(0, count * 26 + 8), Reg = { BackgroundColor3 = "MainColor" } })
		Corner(pop, 6); Stroke(pop); Pad(pop, 4, 4, 4, 4); List(pop, 0)
		for _, val in ipairs(d.Values) do
			local active = d.Multi and d.Value[val] or d.Value == val
			local b = New("TextButton", { AutoButtonColor = false, Size = UDim2.new(1, -4, 0, 26), BackgroundTransparency = active and 0.85 or 1, Text = "  " .. tostring(val),
				TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left, BorderSizePixel = 0,
				Reg = { TextColor3 = active and "AccentColor" or "FontColor", BackgroundColor3 = "OutlineColor" }, Parent = pop })
			Corner(b, 5)
			Connect(b.MouseEnter, function() b.BackgroundTransparency = 0.7 end)
			Connect(b.MouseLeave, function() b.BackgroundTransparency = active and 0.85 or 1 end)
			Connect(b.MouseButton1Click, function()
				if d.Multi then
					d.Value[val] = not d.Value[val] or nil
					d:Display(); fire()
					b.TextColor3 = d.Value[val] and Scheme.AccentColor or Scheme.FontColor
				else
					if d.Value == val and d.AllowNull then d.Value = nil else d.Value = val end
					d:Display(); fire(); ClosePopup()
				end
			end)
		end
		ShowPopup(pop, box, box.AbsoluteSize.X, function() pop:Destroy() end)
	end)

	AddItem(self, holder, d.Text or idx, d)
	d:Display()
	Library.Options[idx] = d
	return d
end

function Funcs:AddInput(idx, info)
	info = info or {}
	local i = { Type = "Input", Text = info.Text, Default = info.Default or "", Value = info.Default or "", Numeric = info.Numeric, Finished = info.Finished,
		Callback = info.Callback, Tooltip = info.Tooltip, MaxLength = info.MaxLength }
	local holder = Row(self, nil)
	List(holder, 4)
	if i.Text then local l = MakeLabel(holder, i.Text, 13); l.Size = UDim2.new(1, 0, 0, 18); l.LayoutOrder = 1 end
	local multi = info.MultiLine == true
	local box = New("TextBox", { Size = UDim2.new(1, 0, 0, multi and (info.Height or 90) or 30), LayoutOrder = 2, Text = i.Value, PlaceholderText = info.Placeholder or "", TextSize = 12,
		TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = multi and Enum.TextYAlignment.Top or Enum.TextYAlignment.Center,
		MultiLine = multi, TextWrapped = multi, ClipsDescendants = multi,
		ClearTextOnFocus = info.ClearTextOnFocus == true, BorderSizePixel = 0, PlaceholderColor3 = Scheme.DimColor,
		Reg = { BackgroundColor3 = "BackgroundColor", TextColor3 = "FontColor" }, Parent = holder })
	Corner(box, 6); Stroke(box); Pad(box, 10, multi and 6 or 0, 10, multi and 6 or 0)
	Tooltip(holder, i.Tooltip)
	function i:SetValue(t)
		t = tostring(t or "")
		if self.MaxLength and #t > self.MaxLength then t = t:sub(1, self.MaxLength) end
		if self.Numeric and t ~= "" and not tonumber(t) then return end
		self.Value = t; box.Text = t
		Library:SafeCallback(self.Callback, t); Library:SafeCallback(self.Changed, t)
	end
	function i:OnChanged(fn) self.Changed = fn end
	function i:SetText(t) self.Text = t end
	Connect(box:GetPropertyChangedSignal("Text"), function()
		if i.Finished then return end
		local t = box.Text
		if i.Numeric and t ~= "" and not tonumber(t) then box.Text = i.Value return end
		if t ~= i.Value then i:SetValue(t) end
	end)
	Connect(box.FocusLost, function() if i.Finished then i:SetValue(box.Text) end end)
	AddItem(self, holder, i.Text or idx, i)
	Library.Options[idx] = i
	return i
end

function Funcs:AddButton(a, b)
	local info = type(a) == "table" and a or { Text = a, Func = b }
	local btn = { Type = "Button", Text = info.Text or "Button", Func = info.Func or info.Callback, DoubleClick = info.DoubleClick, Tooltip = info.Tooltip }
	local holder = Row(self, 32)
	local b1 = New("TextButton", { AutoButtonColor = false, Size = UDim2.fromScale(1, 1), Text = btn.Text, TextSize = 13, BorderSizePixel = 0,
		Reg = { BackgroundColor3 = "BackgroundColor", TextColor3 = "FontColor" }, Parent = holder })
	Corner(b1, 6); Stroke(b1)
	Tooltip(holder, btn.Tooltip)
	Connect(b1.MouseEnter, function() Tween(b1, 0.1, { BackgroundColor3 = Scheme.OutlineColor }) end)
	Connect(b1.MouseLeave, function() Tween(b1, 0.1, { BackgroundColor3 = Scheme.BackgroundColor }) end)
	local armed = 0
	Connect(b1.MouseButton1Click, function()
		if btn.Disabled then return end
		if btn.DoubleClick then
			if os.clock() - armed > 1 then armed = os.clock() b1.Text = "Click again" task.delay(1, function() b1.Text = btn.Text end) return end
			armed = 0; b1.Text = btn.Text
		end
		Library:SafeCallback(btn.Func)
	end)
	function btn:SetText(t) self.Text = t b1.Text = t end
	function btn:AddButton() return self end
	AddItem(self, holder, btn.Text, btn)
	Library.Buttons[#Library.Buttons + 1] = btn
	return btn
end

function Funcs:AddDivider(text)
	local holder = Row(self, 12)
	local line = New("Frame", { AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.fromScale(0, 0.5), Size = UDim2.new(1, 0, 0, 1), BorderSizePixel = 0,
		Reg = { BackgroundColor3 = "OutlineColor" }, Parent = holder })
	local d = {}
	AddItem(self, holder, typeof(text) == "string" and text or "", d)
	return d
end

function Funcs:AddImage(idx, info)
	info = info or {}
	local holder = Row(self, info.Height or 100)
	local img = New("ImageLabel", { BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), Image = ResolveImage(info.Image),
		ScaleType = info.ScaleType or Enum.ScaleType.Fit, Parent = holder })
	local o = { Type = "Image" }
	function o:SetImage(i) img.Image = ResolveImage(i) end
	AddItem(self, holder, "", o)
	return o
end

function Funcs:AddDependencyBox()
	local holder = New("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, Parent = self.Container })
	local container = New("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, Parent = holder })
	List(container, 8)
	local box = setmetatable({ Holder = holder, Container = container, Group = self.Group, Dependencies = {} }, Funcs)
	function box:SetupDependencies(deps) self.Dependencies = deps self:Update() end
	function box:Update()
		local show = true
		for _, dep in ipairs(self.Dependencies) do
			local obj, want = dep[1], dep[2]
			if obj and obj.Value ~= want then show = false break end
		end
		holder.Visible = show
	end
	Library.DependencyBoxes[#Library.DependencyBoxes + 1] = box
	return box
end

function Funcs:AddTitleBell(idx, text)
	local opt, btn = MakeBell(self.Header, "notif_" .. idx, text or "Notifications", 1)
	btn.AnchorPoint = Vector2.new(1, 0.5); btn.Position = UDim2.new(1, 0, 0.5, 0)
	return opt
end

local function NewGroup(tab, column, name)
	local frame = New("Frame", { Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BorderSizePixel = 0,
		Reg = { BackgroundColor3 = "MainColor" }, Parent = column })
	Corner(frame, 8); Stroke(frame)
	List(frame, 0)
	local header = New("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 38), LayoutOrder = 1, Parent = frame })
	Pad(header, 14, 0, 14, 0)
	local title = MakeLabel(header, name, 14); title.Size = UDim2.fromScale(1, 1); title.FontFace = Font.new(Scheme.Font.Family, Enum.FontWeight.SemiBold)
	local line = New("Frame", { Size = UDim2.new(1, 0, 0, 1), LayoutOrder = 2, BorderSizePixel = 0, Reg = { BackgroundColor3 = "OutlineColor" }, Parent = frame })
	local body = New("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, LayoutOrder = 3, Parent = frame })
	Pad(body, 14, 10, 14, 12); List(body, 8)
	local group = { Name = name, Frame = frame, Items = {} }
	Library.Groups = Library.Groups or {}
	Library.Groups[#Library.Groups + 1] = group
	local gb = setmetatable({ Container = body, Group = group, Name = name, Tab = tab, Header = header }, Funcs)
	return gb
end

local HiddenColumn = New("Frame", { Name = "Hidden", Visible = false, BackgroundTransparency = 1, Size = UDim2.fromOffset(0, 0), Parent = ScreenGui })
local Tab = {}
Tab.__index = Tab
function Tab:AddHiddenGroupbox(name)
	local gb = NewGroup(self, HiddenColumn, name or "Hidden")
	table.remove(Library.Groups)
	return gb
end
function Tab:AddLeftGroupbox(name) return NewGroup(self, self.Left, name) end
function Tab:AddRightGroupbox(name) return NewGroup(self, self.Right, name) end
Tab.AddLeftTabbox = Tab.AddLeftGroupbox
Tab.AddRightTabbox = Tab.AddRightGroupbox
function Tab:Show()
	for _, t in ipairs(Library.Tabs) do
		local on = t == self
		t.Page.Visible = on
		Tween(t.Button, 0.12, { BackgroundTransparency = on and 0 or 1 })
		t.Bar.Visible = on
		local col = on and Scheme.WhiteColor or Scheme.DimColor
		t.Label.TextColor3 = col
		if t.Icon then if t.Icon:IsA("ImageLabel") then t.Icon.ImageColor3 = col else t.Icon.TextColor3 = col end end
	end
	ClosePopup()
end

local Window = {}
Window.__index = Window

local ClickBlocker
local CAS_BLOCK_NAME = "boberhookUI_BlockClicks"

local FX = { alpha = 0, target = 0, conn = nil, blur = nil, layer = nil, step = nil }
local FX_BLUR, FX_DIM, FX_COUNT = 12, 0.5, 70

local function FxBuild()
	local layer = FX.layer
	if not layer then return end
	layer:ClearAllChildren()
	local rng = Random.new()
	local parts = {}
	for i = 1, FX_COUNT do
		local depth = rng:NextNumber(0.3, 1)
		local f = New("Frame", { Name = "r", BorderSizePixel = 0, AnchorPoint = Vector2.new(0.5, 1),
			Size = UDim2.fromOffset(depth > 0.7 and 2 or 1, math.floor(14 + depth * 46)),
			BackgroundColor3 = Scheme.AccentColor, BackgroundTransparency = 1, Parent = layer })
		New("UIGradient", { Rotation = 90, Transparency = NumberSequence.new(1, 0), Parent = f })
		parts[i] = { f = f, x = rng:NextNumber(), y = rng:NextNumber(-0.1, 1.1), depth = depth, vy = rng:NextNumber(0.25, 0.5) * (0.5 + depth) }
	end
	FX.step = function(dt, a, mx, my, col)
		for _, p in ipairs(parts) do
			p.y = p.y + p.vy * dt
			if p.y > 1.15 then p.y = -0.1; p.x = math.random() end
			p.f.Position = UDim2.new(p.x, -mx * 30 * p.depth, p.y, -my * 30 * p.depth)
			p.f.BackgroundColor3 = col
			p.f.BackgroundTransparency = 1 - a * (0.2 + 0.5 * p.depth)
		end
	end
end

local function FxEnsure()
	if FX.built then return end
	FX.built = true
	FX.layer = New("Frame", { Name = "fx", BackgroundTransparency = 1, BorderSizePixel = 0, Size = UDim2.fromScale(1, 1), ZIndex = 1, Parent = ClickBlocker })
	local ok, Lighting = pcall(function() return cloneref(game:GetService("Lighting")) end)
	if ok and Lighting then
		local b = Instance.new("BlurEffect")
		b.Name = HttpService:GenerateGUID(false):sub(1, 8)
		b.Size = 0
		b.Parent = Lighting
		FX.blur = b
	end
	FxBuild()
end

local function FxStep(dt)
	local a = FX.alpha + (FX.target - FX.alpha) * math.min(dt * 6, 1)
	if FX.target == 0 and a < 0.01 then a = 0 end
	FX.alpha = a
	ClickBlocker.BackgroundTransparency = 1 - FX_DIM * a
	if FX.blur then FX.blur.Size = FX_BLUR * a end
	if FX.step then
		local vp = ScreenGui.AbsoluteSize
		local m = UIS:GetMouseLocation()
		local mx, my = (m.X / math.max(vp.X, 1) - 0.5), (m.Y / math.max(vp.Y, 1) - 0.5)
		FX.step(dt, a, mx, my, Scheme.AccentColor)
	end
	if FX.target == 0 and a == 0 then
		if FX.conn then FX.conn:Disconnect(); FX.conn = nil end
		ClickBlocker.Visible = false
	end
end

local function FxSet(on)
	FX.target = on and 1 or 0
	if on then
		FxEnsure()
		ClickBlocker.Visible = true
		if not FX.conn then FX.conn = RunService.RenderStepped:Connect(FxStep) end
	end
end

local function SetClickBlock(on)
	if not ClickBlocker then
		ClickBlocker = New("TextButton", { Name = "ClickBlocker", Text = "", AutoButtonColor = false, BackgroundColor3 = Color3.new(0, 0, 0),
			BackgroundTransparency = 1, BorderSizePixel = 0, Size = UDim2.fromScale(1, 1), ZIndex = 0, Active = false, Visible = false,
			ClipsDescendants = true, Parent = ScreenGui })
	end
	ClickBlocker.Active = on and true or false
	pcall(FxSet, on)
	if not on and not FX.conn then ClickBlocker.Visible = false end
	local okc, CAS = pcall(function() return cloneref(game:GetService("ContextActionService")) end)
	if not okc or not CAS then return end
	if on then
		pcall(function()
			CAS:BindActionAtPriority(CAS_BLOCK_NAME, function() return Enum.ContextActionResult.Sink end, false, 3000,
				Enum.UserInputType.MouseButton1, Enum.UserInputType.Touch)
		end)
	else
		pcall(function() CAS:UnbindAction(CAS_BLOCK_NAME) end)
	end
end
Library.SetClickBlock = SetClickBlock

function Library:Toggle(v)
	if self.Loading then return end
	if v == nil then v = not self.Toggled end
	self.Toggled = v
	local main, cover = self.MainFrame, self.MenuCover
	if main then
		local token = (self.ToggleToken or 0) + 1
		self.ToggleToken = token
		local sc = main:FindFirstChildOfClass("UIScale")
		local stroke = main:FindFirstChildOfClass("UIStroke")
		if stroke and not self.MainStrokeT then self.MainStrokeT = stroke.Transparency end
		local vp = ScreenGui.AbsoluteSize
		local target = math.clamp(math.min(vp.X / 780, vp.Y / 520), 0.55, 1)
		local function restore()
			if self.HiddenKids then
				for _, c in ipairs(self.HiddenKids) do if c.Parent then c.Visible = true end end
				self.HiddenKids = nil
			end
			main.BackgroundTransparency = 0
			if stroke then stroke.Transparency = self.MainStrokeT or 0 end
		end
		if v then
			local fresh = not main.Visible
			if fresh then
				main.Visible = true
				if cover then cover.BackgroundTransparency = 0 end
				if sc then sc.Scale = target * 0.92 end
			elseif self.HiddenKids and cover then
				cover.BackgroundTransparency = 0
			end
			restore()
			if cover then Tween(cover, 0.3, { BackgroundTransparency = 1 }) end
			if sc then Tween(sc, 0.3, { Scale = target }) end
		else
			if cover then Tween(cover, 0.18, { BackgroundTransparency = 0 }) end
			if sc then Tween(sc, 0.18, { Scale = target * 0.97 }) end
			task.delay(0.18, function()
				if self.ToggleToken ~= token or self.Toggled then return end
				local hid = {}
				for _, c in ipairs(main:GetChildren()) do
					if c:IsA("GuiObject") and c ~= cover and c.Visible then c.Visible = false; hid[#hid + 1] = c end
				end
				self.HiddenKids = hid
				if cover then Tween(cover, 0.22, { BackgroundTransparency = 1 }) end
				Tween(main, 0.22, { BackgroundTransparency = 1 })
				if stroke then Tween(stroke, 0.22, { Transparency = 1 }) end
				if sc then Tween(sc, 0.22, { Scale = target * 0.9 }) end
				task.delay(0.24, function()
					if self.ToggleToken ~= token or self.Toggled then return end
					main.Visible = false
					restore()
					if cover then cover.BackgroundTransparency = 1 end
					if sc then sc.Scale = target end
				end)
			end)
		end
	end
	if self.Modal then self.Modal.Modal = v end
	SetClickBlock(v)
	if not v then ClosePopup() end
end
function Window:Toggle(v) Library:Toggle(v) end

function Window:AddTab(name, icon, desc)
	local tab = setmetatable({ Name = name, Description = desc }, Tab)
	local btn = New("TextButton", { AutoButtonColor = false, Size = UDim2.new(1, 0, 0, 38), BackgroundTransparency = 1, Text = "", BorderSizePixel = 0,
		Reg = { BackgroundColor3 = "MainColor" }, LayoutOrder = #Library.Tabs + 1, Parent = self.TabList })
	Corner(btn, 7)
	tab.Bar = New("Frame", { Visible = false, Size = UDim2.new(0, 2, 0.6, 0), AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, -10, 0.5, 0), BorderSizePixel = 0,
		Reg = { BackgroundColor3 = "AccentColor" }, Parent = btn })
	local inner = New("Frame", { BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), Parent = btn }); Pad(inner, 12, 0, 8, 0)
	local lay = List(inner, 10, Enum.FillDirection.Horizontal); lay.VerticalAlignment = Enum.VerticalAlignment.Center
	tab.Icon = MakeIcon(icon, 16, inner, "DimColor"); tab.Icon.LayoutOrder = 1
	tab.Label = New("TextLabel", { BackgroundTransparency = 1, Text = name, TextSize = 13, AutomaticSize = Enum.AutomaticSize.X, Size = UDim2.fromOffset(0, 20),
		TextXAlignment = Enum.TextXAlignment.Left, LayoutOrder = 2, Reg = { TextColor3 = "DimColor" }, Parent = inner })
	tab.Button = btn

	local page = New("ScrollingFrame", { Visible = false, BackgroundTransparency = 1, BorderSizePixel = 0, Size = UDim2.fromScale(1, 1), ScrollBarThickness = 3,
		AutomaticCanvasSize = Enum.AutomaticSize.Y, CanvasSize = UDim2.new(), Parent = self.Content })
	Pad(page, 14, 4, 14, 14)
	local function col(side)
		local c = New("Frame", { BackgroundTransparency = 1, Size = UDim2.new(0.5, -6, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
			Position = UDim2.new(side == "L" and 0 or 0.5, side == "L" and 0 or 6, 0, 0), Parent = page })
		List(c, 12)
		return c
	end
	tab.Left, tab.Right, tab.Page = col("L"), col("R"), page
	Library.Tabs[#Library.Tabs + 1] = tab
	Connect(btn.MouseButton1Click, function() Library.CurrentTab = tab tab:Show() end)
	if #Library.Tabs == 1 then
		Library.CurrentTab = tab; tab:Show()
		table.insert(Library.ColorHooks, function() if Library.CurrentTab then Library.CurrentTab:Show() end end)
	end
	return tab
end

function Library:CreateWindow(info)
	info = info or {}
	local Main = New("Frame", { Name = "Main", Visible = false, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(740, 480), BorderSizePixel = 0, Reg = { BackgroundColor3 = "BackgroundColor" }, Parent = ScreenGui })
	Corner(Main, 10); Stroke(Main)
	local cover = New("Frame", { Name = "Cover", Size = UDim2.fromScale(1, 1), BorderSizePixel = 0, BackgroundTransparency = 1, ZIndex = 500, Active = false,
		Reg = { BackgroundColor3 = "BackgroundColor" }, Parent = Main })
	Corner(cover, 10)
	self.MenuCover = cover
	local ui = New("UIScale", { Parent = Main })
	table.insert(self.Scales, ui)
	local function rescale()
		local vp = ScreenGui.AbsoluteSize
		ui.Scale = math.clamp(math.min(vp.X / 780, vp.Y / 520), 0.55, 1)
	end
	rescale(); Connect(ScreenGui:GetPropertyChangedSignal("AbsoluteSize"), rescale)
	self.MainFrame = Main
	if info.UnlockMouseWhileOpen then
		self.Modal = New("TextButton", { Text = "", BackgroundTransparency = 1, Size = UDim2.fromOffset(0, 0), Modal = false, Parent = Main })
	end

	local side = New("Frame", { Size = UDim2.new(0, 158, 1, 0), BackgroundTransparency = 1, Parent = Main })
	New("Frame", { AnchorPoint = Vector2.new(1, 0), Position = UDim2.fromScale(1, 0), Size = UDim2.new(0, 1, 1, 0), BorderSizePixel = 0, Reg = { BackgroundColor3 = "OutlineColor" }, Parent = side })
	local head = New("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 96), Parent = side }); Pad(head, 8, 0, 4, 0)
	local hl = List(head, 0, Enum.FillDirection.Horizontal); hl.VerticalAlignment = Enum.VerticalAlignment.Center
	if info.Icon and info.Icon ~= "" then
		local isz = 60
		New("ImageLabel", { BackgroundTransparency = 1, Size = UDim2.fromOffset(isz, isz), Image = ResolveImage(info.Icon), LayoutOrder = 1, Parent = head })
	end
	local ttl = New("TextLabel", { BackgroundTransparency = 1, Text = info.Title or "Menu", TextSize = 16, AutomaticSize = Enum.AutomaticSize.X, Size = UDim2.fromOffset(0, 28),
		TextXAlignment = Enum.TextXAlignment.Left, LayoutOrder = 2, Reg = { TextColor3 = "WhiteColor" }, Parent = head })
	local tabList = New("ScrollingFrame", { BackgroundTransparency = 1, BorderSizePixel = 0, Position = UDim2.fromOffset(0, 102), Size = UDim2.new(1, 0, 1, -178),
		ScrollBarThickness = 0, AutomaticCanvasSize = Enum.AutomaticSize.Y, CanvasSize = UDim2.new(), Parent = side })
	Pad(tabList, 14, 2, 10, 2); List(tabList, 4)

	local user = New("Frame", { AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, 10, 1, -10), Size = UDim2.new(1, -20, 0, 52), BorderSizePixel = 0,
		Reg = { BackgroundColor3 = "MainColor" }, Parent = side })
	Corner(user, 8); Stroke(user); Pad(user, 8, 0, 8, 0)
	local ul = List(user, 8, Enum.FillDirection.Horizontal); ul.VerticalAlignment = Enum.VerticalAlignment.Center
	local av = New("ImageLabel", { BackgroundTransparency = 0, Size = UDim2.fromOffset(30, 30), LayoutOrder = 1, BorderSizePixel = 0,
		Image = string.format("rbxthumb://type=AvatarHeadShot&id=%d&w=100&h=100", LocalPlayer.UserId), Reg = { BackgroundColor3 = "OutlineColor" }, Parent = user })
	Corner(av, 15)
	local names = New("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, -40, 1, 0), LayoutOrder = 2, Parent = user })
	local nl = List(names, 0); nl.VerticalAlignment = Enum.VerticalAlignment.Center
	New("TextLabel", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 16), Text = LocalPlayer.DisplayName, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd, Reg = { TextColor3 = "WhiteColor" }, Parent = names })
	New("TextLabel", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 14), Text = "@" .. LocalPlayer.Name, TextSize = 10, TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd, Reg = { TextColor3 = "DimColor" }, Parent = names })

	local top = New("Frame", { BackgroundTransparency = 1, Position = UDim2.fromOffset(158, 0), Size = UDim2.new(1, -158, 0, 74), Parent = Main })
	New("Frame", { AnchorPoint = Vector2.new(0, 1), Position = UDim2.fromScale(0, 1), Size = UDim2.new(1, 0, 0, 1), BorderSizePixel = 0, Reg = { BackgroundColor3 = "OutlineColor" }, Parent = top })
	local streaks = {}
	for k = 1, 2 do
		local line = New("Frame", { AnchorPoint = Vector2.new(0, 1), Position = UDim2.fromScale(0, 1), Size = UDim2.new(1, 0, 0, k == 1 and 2 or 1),
			BorderSizePixel = 0, ZIndex = 2, Reg = { BackgroundColor3 = "AccentColor" }, Parent = top })
		local g = New("UIGradient", { Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.3, 1), NumberSequenceKeypoint.new(0.5, k == 1 and 0 or 0.35),
			NumberSequenceKeypoint.new(0.7, 1), NumberSequenceKeypoint.new(1, 1) }), Parent = line })
		streaks[k] = { g = g, speed = k == 1 and 0.28 or 0.17, phase = k == 1 and 0 or 0.5 }
	end
	Connect(RunService.RenderStepped, function()
		if not Main.Visible then return end
		local t = os.clock()
		for _, st in ipairs(streaks) do
			st.g.Offset = Vector2.new(-1 + 2 * ((t * st.speed + st.phase) % 1), 0)
		end
	end)

	local fxOuter = New("Frame", { Name = "HeaderFX", BackgroundTransparency = 1, ClipsDescendants = true, ZIndex = 0,
		Position = UDim2.fromOffset(0, 1), Size = UDim2.new(1, -1, 1, -1), Parent = top })
	local fxBg = New("Frame", { BorderSizePixel = 0, BackgroundColor3 = Color3.new(1, 1, 1), ZIndex = 0,
		Position = UDim2.fromOffset(-12, 0), Size = UDim2.new(1, 12, 1, 12), Parent = fxOuter })
	Corner(fxBg, 9)
	New("UIGradient", { Rotation = 90, Color = ColorSequence.new(Color3.fromRGB(14, 14, 16), Color3.fromRGB(9, 9, 10)), Parent = fxBg })
	local glow = New("Frame", { BackgroundTransparency = 1, ClipsDescendants = true, ZIndex = 0,
		Position = UDim2.fromOffset(0, 4), Size = UDim2.new(1, -4, 1, -4), Parent = fxOuter })

	local FX_H, FX_LH, FX_COLS = 69, 11, 38
	local rng = Random.new(11)
	local codeFont = Font.fromEnum(Enum.Font.Code)
	local function newBits(n)
		local t = {}
		for i = 1, n do t[i] = (rng:NextInteger(0, 1) == 0) and "0" or "1" end
		return t
	end
	local cols = {}
	for i = 1, FX_COLS do
		local len = rng:NextInteger(5, 9)
		local c = { len = len, chars = newBits(len), speed = rng:NextNumber(22, 55), y = rng:NextNumber(-FX_H, FX_H) }
		c.lbl = New("TextLabel", { BackgroundTransparency = 1, AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new((i - 0.5) / FX_COLS, 0, 0, c.y),
			Size = UDim2.fromOffset(12, len * FX_LH), Text = table.concat(c.chars, "\n"), TextSize = 10, FontFace = codeFont, LineHeight = 1,
			TextColor3 = Color3.new(1, 1, 1), TextTransparency = rng:NextNumber(0.4, 0.7), TextXAlignment = Enum.TextXAlignment.Center,
			TextYAlignment = Enum.TextYAlignment.Top, TextWrapped = false, ZIndex = 1, Parent = glow })
		New("UIGradient", { Rotation = 90, Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.55, 0.8), NumberSequenceKeypoint.new(0.88, 0.35), NumberSequenceKeypoint.new(1, 0) }), Parent = c.lbl })
		cols[i] = c
	end

	local FADE = Color3.fromRGB(10, 10, 11)
	local function edgeFade(pos, size, anchor, rot)
		local f = New("Frame", { BorderSizePixel = 0, BackgroundColor3 = FADE, Position = pos, Size = size, AnchorPoint = anchor, ZIndex = 3, Parent = glow })
		New("UIGradient", { Rotation = rot, Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(1, 1) }), Parent = f })
	end
	edgeFade(UDim2.fromScale(0, 0), UDim2.new(0, 110, 1, 0), Vector2.new(0, 0), 0)
	edgeFade(UDim2.fromScale(1, 0), UDim2.new(0, 110, 1, 0), Vector2.new(1, 0), 180)
	edgeFade(UDim2.fromScale(0, 0), UDim2.new(1, 0, 0, 14), Vector2.new(0, 0), 90)
	edgeFade(UDim2.fromScale(0, 1), UDim2.new(1, 0, 0, 14), Vector2.new(0, 1), 270)

	local flickIdx = 1
	Connect(RunService.RenderStepped, function(dt)
		if not Main.Visible then return end
		dt = math.min(dt or 0.016, 0.1)
		for i, c in ipairs(cols) do
			c.y = c.y + c.speed * dt
			if c.y > FX_H then
				c.len = rng:NextInteger(5, 9)
				c.chars = newBits(c.len)
				c.speed = rng:NextNumber(22, 55)
				c.y = -c.len * FX_LH - rng:NextNumber(0, 70)
				c.lbl.Size = UDim2.fromOffset(12, c.len * FX_LH)
				c.lbl.Text = table.concat(c.chars, "\n")
			end
			c.lbl.Position = UDim2.new((i - 0.5) / FX_COLS, 0, 0, c.y)
		end
		for _ = 1, 3 do
			local c = cols[flickIdx]
			flickIdx = flickIdx % FX_COLS + 1
			c.chars[rng:NextInteger(1, c.len)] = (rng:NextInteger(0, 1) == 0) and "0" or "1"
			c.lbl.Text = table.concat(c.chars, "\n")
		end
	end)

	local shineG = New("UIGradient", { Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(175, 175, 180)), ColorSequenceKeypoint.new(0.4, Color3.fromRGB(175, 175, 180)),
		ColorSequenceKeypoint.new(0.5, Color3.new(1, 1, 1)),
		ColorSequenceKeypoint.new(0.6, Color3.fromRGB(175, 175, 180)), ColorSequenceKeypoint.new(1, Color3.fromRGB(175, 175, 180)) }),
		Offset = Vector2.new(-1, 0), Parent = ttl })
	local ghosts = {}
	for gi, gcol in ipairs({ Color3.fromRGB(255, 40, 90), Color3.fromRGB(0, 230, 255) }) do
		ghosts[gi] = New("TextLabel", { BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), Text = ttl.Text, TextSize = ttl.TextSize,
			FontFace = ttl.FontFace, TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = gcol, TextTransparency = 0.35, Visible = false, ZIndex = 2, Parent = ttl })
	end
	local GLITCH_CHARS = { "#", "@", "%", "&", "*", "0", "1", "/", "\\", "?", "$" }
	local glitchOrig, glitchEnd, glitchNext, glitchTick = nil, 0, os.clock() + 1.5, 0
	local function glitchRand(a, b) return a + math.random() * (b - a) end
	Connect(RunService.RenderStepped, function()
		if not Main.Visible then return end
		local t = os.clock()
		local ph = (t % 2.5) / 0.9
		shineG.Offset = Vector2.new(ph < 1 and (-1 + 2 * ph) or -1, 0)
		if glitchOrig then
			if t >= glitchEnd then
				ttl.Text = glitchOrig
				for _, gh in ipairs(ghosts) do gh.Visible = false; gh.Text = glitchOrig end
				glitchOrig = nil
				glitchNext = t + glitchRand(2, 4.5)
			elseif t - glitchTick >= 0.04 then
				glitchTick = t
				local chars = {}
				for ci = 1, #glitchOrig do
					local ch = glitchOrig:sub(ci, ci)
					chars[ci] = (math.random() < 0.3 and ch ~= " ") and GLITCH_CHARS[math.random(#GLITCH_CHARS)] or ch
				end
				local txt = table.concat(chars)
				ttl.Text = txt
				for gi, gh in ipairs(ghosts) do
					gh.Text = txt
					gh.Visible = true
					gh.Position = UDim2.fromOffset((gi == 1 and -1 or 1) * math.random(1, 3), math.random(-1, 1))
				end
			end
		elseif t >= glitchNext then
			glitchOrig = ttl.Text
			glitchEnd = t + 0.28
			glitchTick = 0
		end
	end)

	local content = New("Frame", { BackgroundTransparency = 1, Position = UDim2.fromOffset(158, 82), Size = UDim2.new(1, -158, 1, -86), ClipsDescendants = true, Parent = Main })

	self:MakeDraggable(Main, top)
	self:MakeDraggable(Main, head)
	self.Window = setmetatable({ TabList = tabList, Content = content, Main = Main, Title = ttl }, Window)

	local kf = New("Frame", { Visible = false, Position = UDim2.new(0, 14, 0.4, 0), Size = UDim2.fromOffset(200, 0), AutomaticSize = Enum.AutomaticSize.Y, BorderSizePixel = 0,
		BackgroundColor3 = Color3.fromRGB(10, 10, 11), BackgroundTransparency = 0.05, Parent = ScreenGui })
	Corner(kf, 6)
	local kstroke = New("UIStroke", { Thickness = 1, ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Color = Color3.new(1, 1, 1), Parent = kf })
	local kgrad = New("UIGradient", { Rotation = 0, Parent = kstroke })
	Pad(kf, 10, 6, 10, 8); List(kf, 4)
	local kt = New("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 22), LayoutOrder = 0, Parent = kf })
	local kico = New("Frame", { AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 0, 0.5, 0), Size = UDim2.fromOffset(17, 11), BackgroundTransparency = 1, Parent = kt })
	Corner(kico, 3)
	New("UIStroke", { Thickness = 1.2, ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Color = Color3.new(1, 1, 1), Parent = kico })
	for c = 0, 3 do
		New("Frame", { Position = UDim2.fromOffset(2.5 + c * 3.5, 2.5), Size = UDim2.fromOffset(2, 2), BorderSizePixel = 0, BackgroundColor3 = Color3.new(1, 1, 1), Parent = kico })
	end
	New("Frame", { Position = UDim2.fromOffset(4, 6.5), Size = UDim2.fromOffset(9, 2), BorderSizePixel = 0, BackgroundColor3 = Color3.new(1, 1, 1), Parent = kico })
	New("TextLabel", { BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), Text = "Keybinds", TextSize = 13, TextColor3 = Color3.new(1, 1, 1), Parent = kt })
	New("Frame", { AnchorPoint = Vector2.new(0, 1), Position = UDim2.fromScale(0, 1), Size = UDim2.new(1, 0, 0, 1), BorderSizePixel = 0, BackgroundColor3 = Color3.fromRGB(38, 38, 42), Parent = kt })
	local klist = New("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, LayoutOrder = 1, Parent = kf })
	List(klist, 0)
	self.KeybindFrame, self.KeybindList = kf, klist
	self:MakeDraggable(kf, kt)
	local kline = New("Frame", { AnchorPoint = Vector2.new(0, 1), Position = UDim2.fromScale(0, 1), Size = UDim2.new(1, 0, 0, 2), BorderSizePixel = 0,
		ZIndex = 2, Reg = { BackgroundColor3 = "AccentColor" }, Parent = kt })
	local kstreak = New("UIGradient", { Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.3, 1), NumberSequenceKeypoint.new(0.5, 0),
		NumberSequenceKeypoint.new(0.7, 1), NumberSequenceKeypoint.new(1, 1) }), Parent = kline })
	Connect(RunService.RenderStepped, function()
		if not kf.Visible then return end
		local t = os.clock()
		local base, acc = Color3.fromRGB(42, 42, 47), Scheme.AccentColor
		kgrad.Color = ColorSequence.new({ ColorSequenceKeypoint.new(0, base), ColorSequenceKeypoint.new(0.35, base),
			ColorSequenceKeypoint.new(0.5, acc), ColorSequenceKeypoint.new(0.65, base), ColorSequenceKeypoint.new(1, base) })
		kgrad.Rotation = (t * 110) % 360
		kstreak.Offset = Vector2.new(-1 + 2 * ((t * 0.45) % 1), 0)
		local w = 0.5 + 0.5 * math.sin(t * 4)
		for _, bar in ipairs(Library.KeybindPulse or {}) do
			if bar.Parent then
				bar.BackgroundColor3 = acc
				bar.BackgroundTransparency = 0.7 * (1 - w)
			end
		end
	end)

	Connect(UIS.InputBegan, function(input)
		if self.Unloaded or UIS:GetFocusedTextBox() then return end
		for _, kp in ipairs(self.KeyPickers) do if kp.Picking then return end end
		local name = InputName(input)
		if not name then return end
		local tk = self.ToggleKeybind
		if tk and tk.Value ~= "None" and tk.Value == name then self:Toggle() return end
		for _, kp in ipairs(self.KeyPickers) do
			if kp ~= tk and kp.Value == name then
				if kp.Mode == "Toggle" then kp.Toggled = not kp.Toggled kp:Activate()
				elseif kp.Mode == "Hold" then kp.Held = true kp:Activate()
				elseif kp.Mode == "Press" then kp:Activate() end
			end
		end
	end)
	Connect(UIS.InputEnded, function(input)
		local name = InputName(input)
		if not name then return end
		for _, kp in ipairs(self.KeyPickers) do
			if kp.Value == name and kp.Mode == "Hold" and kp.Held then kp.Held = false kp:Activate() end
		end
	end)
	if TOUCH then
		local tb = New("TextButton", { Text = "", Size = UDim2.fromOffset(44, 44), Position = UDim2.new(0, 12, 0, 60), BorderSizePixel = 0, Reg = { BackgroundColor3 = "MainColor" }, Parent = ScreenGui })
		Corner(tb, 22); Stroke(tb)
		if info.Icon and info.Icon ~= "" then New("ImageLabel", { BackgroundTransparency = 1, Size = UDim2.fromScale(0.6, 0.6), Position = UDim2.fromScale(0.2, 0.2), Image = ResolveImage(info.Icon), Parent = tb }) end
		Connect(tb.MouseButton1Click, function() self:Toggle() end)
	end

	self:Toggle(true)
	return self.Window
end

local NotifyHolder = New("Frame", { BackgroundTransparency = 1, AnchorPoint = Vector2.new(0, 1), Size = UDim2.new(0, 280, 1, -20), Position = UDim2.new(0, 10, 1, -10), ZIndex = 70, Parent = ScreenGui })
do
	local l = List(NotifyHolder, 8); l.VerticalAlignment = Enum.VerticalAlignment.Bottom; l.HorizontalAlignment = Enum.HorizontalAlignment.Left
end
function Library:SetNotifySide(side)
	self.NotifySide = "Left"
	NotifyHolder.AnchorPoint = Vector2.new(0, 1)
	NotifyHolder.Position = UDim2.new(0, 10, 1, -10)
	NotifyHolder.UIListLayout.VerticalAlignment = Enum.VerticalAlignment.Bottom
	NotifyHolder.UIListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
end
function Library:Notify(a, b)
	local info = type(a) == "table" and a or { Title = "Notification", Description = tostring(a), Time = b }
	local time = tonumber(info.Time) or 4
	local desc = tostring(info.Description or "")
	local dl = desc:lower()
	local sc = Scheme.AccentColor
	if dl:match("^%s*off%f[%W]") or dl:match("disabled") then sc = Color3.fromRGB(225, 85, 85)
	elseif dl:match("^%s*on%f[%W]") or dl:match("enabled") then sc = Color3.fromRGB(90, 215, 130) end

	local slot = New("Frame", { BackgroundTransparency = 1, BorderSizePixel = 0, Size = UDim2.new(1, 0, 0, 0), ClipsDescendants = true, ZIndex = 70, Parent = NotifyHolder })
	Pad(slot, 2, 2, 2, 2)
	local card = New("Frame", { Position = UDim2.fromScale(-1.1, 0), Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BorderSizePixel = 0,
		BackgroundTransparency = 1, Reg = { BackgroundColor3 = "MainColor" }, ZIndex = 70, Parent = slot })
	Corner(card, 8); local st = Stroke(card); st.Transparency = 1; st.Color = sc
	local body = New("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, ZIndex = 70, Parent = card })
	Pad(body, 14, 10, 14, 14); List(body, 3)
	local t = New("TextLabel", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 16), Text = info.Title or "", TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left,
		TextTransparency = 1, Reg = { TextColor3 = "WhiteColor" }, LayoutOrder = 1, ZIndex = 71, Parent = body })
	local d = New("TextLabel", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, Text = desc, TextSize = 12,
		TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top, TextTransparency = 1, TextColor3 = sc, LayoutOrder = 2, ZIndex = 71, Parent = body })
	local bar = New("Frame", { Position = UDim2.new(0, 0, 1, -2), Size = UDim2.new(1, 0, 0, 2), BorderSizePixel = 0, BackgroundTransparency = 1,
		BackgroundColor3 = sc, ZIndex = 72, Parent = card })

	local n = { dead = false }
	task.spawn(function()
		for _ = 1, 6 do if card.AbsoluteSize.Y > 0 then break end task.wait() end
		if n.dead or not slot.Parent then return end
		local h = card.AbsoluteSize.Y
		Tween(slot, 0.25, { Size = UDim2.new(1, 0, 0, h + 4) })
		TweenService:Create(card, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Position = UDim2.fromScale(0, 0) }):Play()
		Tween(card, 0.2, { BackgroundTransparency = 0 }); Tween(t, 0.25, { TextTransparency = 0 }); Tween(d, 0.25, { TextTransparency = 0 }); Tween(bar, 0.2, { BackgroundTransparency = 0 })
		TweenService:Create(bar, TweenInfo.new(time, Enum.EasingStyle.Linear), { Size = UDim2.new(0, 0, 0, 2) }):Play()
		Tween(st, 0.2, { Transparency = 0 })
		task.delay(0.35, function()
			if n.dead then return end
			Tween(d, 0.9, { TextColor3 = Scheme.DimColor })
			Tween(st, 1.1, { Color = Scheme.OutlineColor })
		end)
	end)
	function n:Destroy()
		if n.dead then return end
		n.dead = true
		if not slot.Parent then return end
		TweenService:Create(card, TweenInfo.new(0.28, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { Position = UDim2.fromScale(-1.1, 0) }):Play()
		Tween(t, 0.2, { TextTransparency = 1 }); Tween(d, 0.2, { TextTransparency = 1 })
		task.delay(0.26, function()
			if not slot.Parent then return end
			Tween(slot, 0.2, { Size = UDim2.new(1, 0, 0, 0) })
			task.delay(0.24, function() slot:Destroy() end)
		end)
	end
	task.delay(time, function() n:Destroy() end)
	return n
end

function Library:CreateLoading(info)
	info = info or {}
	self.Loading = true
	local t0 = os.clock()
	local overlay = New("Frame", { Name = "Loading", Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(0, 0, 0), BackgroundTransparency = 0,
		BorderSizePixel = 0, Active = true, ZIndex = 100, Parent = ScreenGui })
	local holder = New("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0.5, -16), Size = UDim2.fromOffset(120, 120),
		BackgroundTransparency = 1, ZIndex = 101, Parent = overlay })
	local label = New("TextLabel", { AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0.5, 52), Size = UDim2.fromOffset(300, 24), BackgroundTransparency = 1,
		Text = "loading", TextSize = 18, TextColor3 = Color3.fromRGB(95, 95, 98), ZIndex = 101, Parent = overlay })
	local desc = New("TextLabel", { AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0.5, 80), Size = UDim2.fromOffset(360, 0), AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1, Text = "", TextSize = 13, TextWrapped = true, TextColor3 = Color3.fromRGB(80, 80, 84), ZIndex = 101, Parent = overlay })

	local N, R, C = 8, 34, 60
	local linesA, linesB, dots, glows = {}, {}, {}, {}
	local function line(parent)
		return New("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.fromOffset(0, 1), BorderSizePixel = 0, BackgroundColor3 = Color3.fromRGB(205, 205, 210),
			BackgroundTransparency = 1, ZIndex = 101, Parent = parent })
	end
	for i = 1, N do linesA[i] = line(holder); linesB[i] = line(holder) end
	for i = 1, N do
		local g = New("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.fromOffset(18, 18), BorderSizePixel = 0, BackgroundColor3 = Color3.new(1, 1, 1),
			BackgroundTransparency = 0.85, ZIndex = 101, Parent = holder })
		Corner(g, 99); glows[i] = g
		local d = New("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.fromOffset(8, 8), BorderSizePixel = 0, BackgroundColor3 = Color3.new(1, 1, 1),
			ZIndex = 102, Parent = holder })
		Corner(d, 99); dots[i] = d
	end

	local fade = 0
	local function tr(base) return base + (1 - base) * fade end
	local function seg(f, a, b, t)
		local d = b - a
		f.Size = UDim2.fromOffset(d.Magnitude, 1.5)
		f.Position = UDim2.fromOffset((a.X + b.X) / 2, (a.Y + b.Y) / 2)
		f.Rotation = math.deg(math.atan2(d.Y, d.X))
		f.BackgroundTransparency = tr(t)
	end
	local conn = RunService.RenderStepped:Connect(function()
		local t = os.clock() - t0
		local ph = t / 2.2 * math.pi * 2
		local sn = math.sin(ph)
		local twist, k = sn * 0.62, math.abs(sn)
		local rad = R * (1 - 0.18 * k)
		local rot = t * 0.9
		local pts = {}
		for i = 1, N do
			local a = rot + (i - 1) * math.pi / 4 + ((i % 2 == 0) and twist or -twist)
			local p = Vector2.new(C + math.cos(a) * rad, C + math.sin(a) * rad)
			pts[i] = p
			dots[i].Position = UDim2.fromOffset(p.X, p.Y); dots[i].BackgroundTransparency = tr(0)
			glows[i].Position = UDim2.fromOffset(p.X, p.Y); glows[i].BackgroundTransparency = tr(0.85)
		end
		for i = 1, N do
			seg(linesA[i], pts[i], pts[i % N + 1], math.clamp(k * 1.6, 0, 1))
			seg(linesB[i], pts[i], pts[(i + 2) % N + 1], math.clamp(1.6 * (1 - k), 0, 1))
		end
		label.TextTransparency = tr(0.1 + 0.2 * (0.5 + 0.5 * math.sin(t * 3)))
		desc.TextTransparency = tr(0)
	end)

	local o, finished = { t0 = t0, MinTime = info.MinTime or 3 }, false
	function o:SetMessage(t) label.Text = tostring(t) end
	function o:SetDescription(t) desc.Text = tostring(t) end
	function o:SetCurrentStep() end
	function o:Finish()
		if finished then return end
		finished = true
		task.spawn(function()
			local rem = self.MinTime - (os.clock() - t0)
			if rem > 0 then task.wait(rem) end
			local st = os.clock()
			while true do
				local a = (os.clock() - st) / 0.45
				fade = math.min(a, 1)
				if a >= 1 then break end
				RunService.RenderStepped:Wait()
			end
			conn:Disconnect()
			if Library.Unloaded or not overlay.Parent then return end
			Library.Loading = false
			local main = Library.MainFrame
			if main then Library:Toggle(true) end
			Tween(overlay, 0.8, { BackgroundTransparency = 1 })
			task.wait(0.85)
			if overlay.Parent then overlay:Destroy() end
			if self.OnDone then Library:SafeCallback(self.OnDone) end
		end)
	end
	o.Continue = o.Finish
	o.Destroy = o.Finish
	task.delay(45, function() o:Finish() end)
	return o
end

function Library:Unload()
	if self.Unloaded then return end
	self.Unloaded = true
	for _, fn in ipairs(self.UnloadCallbacks) do pcall(fn) end
	for _, c in ipairs(self.Connections) do pcall(function() c:Disconnect() end) end
	if self.Modal then pcall(function() self.Modal.Modal = false end) end
	pcall(SetClickBlock, false)
	if FX.conn then FX.conn:Disconnect(); FX.conn = nil end
	if FX.blur then pcall(function() FX.blur:Destroy() end) end
	ScreenGui:Destroy()
	self.Toggled = false
end

local SaveManager = { Folder = "boberhookUI", SubFolder = "", Ignore = {}, Library = Library }
Library.SaveManager = SaveManager

local Parsers = {
	Toggle = { Save = function(idx, o) return { type = "Toggle", idx = idx, value = o.Value } end,
		Load = function(idx, d) if Library.Toggles[idx] then Library.Toggles[idx]:SetValue(d.value) end end },
	Slider = { Save = function(idx, o) return { type = "Slider", idx = idx, value = tostring(o.Value) } end,
		Load = function(idx, d) if Library.Options[idx] then Library.Options[idx]:SetValue(d.value) end end },
	NotifBell = { Save = function(idx, o) return { type = "NotifBell", idx = idx, value = o.Value } end,
		Load = function(idx, d) if Library.Options[idx] then Library.Options[idx]:SetValue(d.value ~= false) end end },
	RangeSlider = { Save = function(idx, o) return { type = "RangeSlider", idx = idx, min = tostring(o.ValueMin), max = tostring(o.ValueMax) } end,
		Load = function(idx, d) if Library.Options[idx] then Library.Options[idx]:SetValue(d.min, d.max) end end },
	Dropdown = { Save = function(idx, o) return { type = "Dropdown", idx = idx, value = o.Value, multi = o.Multi } end,
		Load = function(idx, d) if Library.Options[idx] then Library.Options[idx]:SetValue(d.value) end end },
	ColorPicker = { Save = function(idx, o) return { type = "ColorPicker", idx = idx, value = o.Value:ToHex(), transparency = o.Transparency } end,
		Load = function(idx, d) if Library.Options[idx] then Library.Options[idx]:SetValueRGB(Color3.fromHex(d.value), d.transparency) end end },
	KeyPicker = { Save = function(idx, o) return { type = "KeyPicker", idx = idx, mode = o.Mode, key = o.Value, modifiers = o.Modifiers } end,
		Load = function(idx, d) if Library.Options[idx] then Library.Options[idx]:SetValue({ d.key, d.mode, d.modifiers }) end end },
	Input = { Save = function(idx, o) return { type = "Input", idx = idx, text = o.Value } end,
		Load = function(idx, d) if Library.Options[idx] and type(d.text) == "string" then Library.Options[idx]:SetValue(d.text) end end },
}

function SaveManager:SetLibrary(lib) self.Library = lib end
function SaveManager:IgnoreThemeSettings() end
function SaveManager:SetIgnoreIndexes(list) for _, k in ipairs(list) do self.Ignore[k] = true end end
local function mk(path) if makefolder and isfolder and not isfolder(path) then pcall(makefolder, path) end end
function SaveManager:BuildFolderTree()
	local parts = { self.Folder, self.Folder .. "/settings" }
	if self.SubFolder ~= "" then parts[#parts + 1] = self.Folder .. "/settings/" .. self.SubFolder end
	for _, p in ipairs(parts) do mk(p) end
end
function SaveManager:SetFolder(f) self.Folder = f self:BuildFolderTree() end
function SaveManager:SetSubFolder(f) self.SubFolder = f self:BuildFolderTree() end
function SaveManager:_path(name)
	local p = self.Folder .. "/settings/"
	if self.SubFolder ~= "" then p ..= self.SubFolder .. "/" end
	return p .. name .. ".json"
end
function SaveManager:_dir()
	local p = self.Folder .. "/settings"
	if self.SubFolder ~= "" then p ..= "/" .. self.SubFolder end
	return p
end
function SaveManager:Save(name)
	if not name or name:gsub(" ", "") == "" then return false, "no config file is selected" end
	if not writefile then return false, "writefile is not available" end
	local data = { objects = {} }
	for idx, o in pairs(Library.Toggles) do
		if not self.Ignore[idx] and Parsers[o.Type] then table.insert(data.objects, Parsers[o.Type].Save(idx, o)) end
	end
	for idx, o in pairs(Library.Options) do
		if not self.Ignore[idx] and Parsers[o.Type] then table.insert(data.objects, Parsers[o.Type].Save(idx, o)) end
	end
	local ok, enc = pcall(HttpService.JSONEncode, HttpService, data)
	if not ok then return false, "failed to encode data" end
	self:BuildFolderTree()
	local ok2, err = pcall(writefile, self:_path(name), enc)
	if not ok2 then return false, "write file error: " .. tostring(err) end
	return true
end
function SaveManager:Load(name)
	if not name or name:gsub(" ", "") == "" then return false, "no config file is selected" end
	local path = self:_path(name)
	if not (isfile and isfile(path)) then return false, "invalid file" end
	local ok, dec = pcall(function() return HttpService:JSONDecode(readfile(path)) end)
	if not ok or type(dec) ~= "table" or type(dec.objects) ~= "table" then return false, "decode error" end
	for _, d in ipairs(dec.objects) do
		if type(d) == "table" and not self.Ignore[d.idx] and Parsers[d.type] then
			task.spawn(function() pcall(Parsers[d.type].Load, d.idx, d) end)
		end
	end
	return true
end
function SaveManager:RefreshConfigList()
	local out = {}
	if listfiles and isfolder and isfolder(self:_dir()) then
		for _, f in ipairs(listfiles(self:_dir())) do
			local n = f:match("([^/\\]+)%.json$")
			if n then out[#out + 1] = n end
		end
	end
	return out
end
function SaveManager:GetAutoloadConfig()
	local p = self:_dir() .. "/autoload.txt"
	if isfile and isfile(p) then return readfile(p) end
	return "none"
end
function SaveManager:SaveAutoloadConfig(name) if writefile then self:BuildFolderTree() writefile(self:_dir() .. "/autoload.txt", name) end return true end
function SaveManager:DeleteAutoLoadConfig() if delfile and isfile and isfile(self:_dir() .. "/autoload.txt") then delfile(self:_dir() .. "/autoload.txt") end return true end
function SaveManager:LoadAutoloadConfig()
	local n = self:GetAutoloadConfig()
	if n ~= "none" and n ~= "" then
		local ok, err = self:Load(n)
		if not ok then Library:Notify({ Title = "Config", Description = "Failed to load autoload config: " .. tostring(err), Time = 5 }) return end
		Library:Notify({ Title = "Config", Description = string.format("Auto loaded config %q", n), Time = 4 })
	end
end
function SaveManager:BuildConfigSection(tab)
	local sm = self
	local g = tab:AddRightGroupbox("Configuration")
	g:AddInput("SaveManager_ConfigName", { Text = "Config Name:" })
	g:AddDropdown("SaveManager_ConfigList", { Text = "Config list", Values = self:RefreshConfigList(), AllowNull = true })
	g:AddDivider()
	local function note(t, d) Library:Notify({ Title = t, Description = d, Time = 4 }) end
	g:AddButton("Create config", function()
		local name = Library.Options.SaveManager_ConfigName.Value
		if name:gsub(" ", "") == "" then return note("Config", "Invalid config name (empty)") end
		local ok, err = sm:Save(name)
		if not ok then return note("Config", "Failed to create config: " .. tostring(err)) end
		note("Config", string.format("Created config %q", name))
		Library.Options.SaveManager_ConfigList:SetValues(sm:RefreshConfigList())
		Library.Options.SaveManager_ConfigList:SetValue(nil)
	end)
	g:AddButton("Load config", function()
		local name = Library.Options.SaveManager_ConfigList.Value
		local ok, err = sm:Load(name)
		if not ok then return note("Config", "Failed to load config: " .. tostring(err)) end
		note("Config", string.format("Loaded config %q", name))
	end)
	g:AddButton("Overwrite config", function()
		local name = Library.Options.SaveManager_ConfigList.Value
		local ok, err = sm:Save(name)
		if not ok then return note("Config", "Failed to overwrite config: " .. tostring(err)) end
		note("Config", string.format("Overwrote config %q", name))
	end)
	g:AddButton("Delete config", function()
		local name = Library.Options.SaveManager_ConfigList.Value
		if name and delfile and isfile and isfile(sm:_path(name)) then pcall(delfile, sm:_path(name)) end
		note("Config", string.format("Deleted config %q", tostring(name)))
		Library.Options.SaveManager_ConfigList:SetValues(sm:RefreshConfigList())
		Library.Options.SaveManager_ConfigList:SetValue(nil)
	end)
	g:AddButton("Refresh list", function()
		Library.Options.SaveManager_ConfigList:SetValues(sm:RefreshConfigList())
		Library.Options.SaveManager_ConfigList:SetValue(nil)
	end)
	g:AddDivider()
	local autoLabel
	g:AddButton("Set as autoload", function()
		local name = Library.Options.SaveManager_ConfigList.Value
		if not name then return end
		sm:SaveAutoloadConfig(name)
		autoLabel:SetText("Current autoload config: " .. name)
		note("Config", string.format("Set %q to auto load", name))
	end)
	g:AddButton("Reset autoload", function()
		sm:DeleteAutoLoadConfig()
		autoLabel:SetText("Current autoload config: none")
		note("Config", "Set autoload to none")
	end)
	autoLabel = g:AddLabel("Current autoload config: " .. self:GetAutoloadConfig(), true)
	g:AddDivider()
	g:AddButton("Export to clipboard", function()
		local data = { objects = {} }
		for idx, o in pairs(Library.Toggles) do if not sm.Ignore[idx] and Parsers[o.Type] then table.insert(data.objects, Parsers[o.Type].Save(idx, o)) end end
		for idx, o in pairs(Library.Options) do if not sm.Ignore[idx] and Parsers[o.Type] then table.insert(data.objects, Parsers[o.Type].Save(idx, o)) end end
		if setclipboard then setclipboard(HttpService:JSONEncode(data)) note("Config", "Config copied to clipboard") end
	end)
	g:AddInput("SaveManager_ImportData", { Text = "Import data", Placeholder = "Paste config JSON" })
	g:AddButton("Import config", function()
		local ok, dec = pcall(function() return HttpService:JSONDecode(Library.Options.SaveManager_ImportData.Value) end)
		if not ok or type(dec) ~= "table" or type(dec.objects) ~= "table" then return note("Config", "Invalid import data") end
		for _, d in ipairs(dec.objects) do
			if type(d) == "table" and not sm.Ignore[d.idx] and Parsers[d.type] then task.spawn(function() pcall(Parsers[d.type].Load, d.idx, d) end) end
		end
		note("Config", "Config imported")
	end)
	SaveManager:SetIgnoreIndexes({ "SaveManager_ConfigList", "SaveManager_ConfigName", "SaveManager_ImportData" })
end

Library:SetNotifySide("Right")
return Library

end
local function fn()
	if not ({
		[13772394625] = true,
		[15509350986] = true,
		[16281300371] = true,
		[16331600459] = true,
		[14732610803] = true,
		[15131065025] = true,
		[15517169103] = true,
		[15552588346] = true,
		[16456370330] = true,
		[101792363513541] = true,
		[15264892126] = true,
		[15144787112] = true,
		[15234596844] = true,
		[16331596518] = true,
		[17757592456] = true,
		[111661204337143] = true,
		[16331598816] = true,
		[80316691895873] = true,
		[15185247558] = true,
		[16044264830] = true,
		[15582823307] = true,
		[15240096157] = true,
		[14915220621] = true,
		[15582821022] = true,
		[16331595046] = true,
		[16581648071] = true,
		[16581637217] = true,
		[92458008626219] = true,
		[97204747083036] = true,
		[14368557094] = true,
	})[game.PlaceId] then
		local localPlayer = game:GetService("Players").LocalPlayer
		local str = "This script only works in Blade Ball."

		task.spawn(function()
			for i = 1, 6 do
				localPlayer:Kick(str)
				task.wait(0.1)
			end
		end)

		return
	end

	if not getupvalues then
		getupvalues = debug and debug.getupvalues
	end

	if not setupvalue then
		setupvalue = debug and debug.setupvalue
	end

	if not request then
		request = http_request
	end

	if not identifyexecutor then
		identifyexecutor = getexecutorname
	end

	if not getthreadidentity then
		getthreadidentity = getidentity or getthreadcontext
	end

	if not queueonteleport then
		queueonteleport = queue_on_teleport
	end

	if not setclipboard then
		setclipboard = toclipboard
	end

	local tbl = {}

	for _, v in ipairs({
		{ "getconnections", getconnections },
		{ "getgc", getgc },
		{ "getgenv", getgenv },
		{ "getthreadidentity", getthreadidentity },
		{ "getupvalues", getupvalues },
		{ "isfile", isfile },
		{ "islclosure", islclosure },
		{ "loadstring", loadstring },
		{ "readfile", readfile },
		{ "request", request },
		{ "setthreadidentity", setthreadidentity },
		{ "setupvalue", setupvalue },
		{ "writefile", writefile },
	}) do
		if v[2] == nil then
			tbl[#tbl + 1] = v[1]
		end
	end

	if #tbl > 0 then
		table.sort(tbl)
		warn(("[boberhook] %s is missing %d function(s) the script needs: %s"):format(tostring(identifyexecutor and identifyexecutor() or "Your executor"), #tbl, table.concat(tbl, ", ")))
		return
	end

	local tbl2 = {}

	for _, v in ipairs({
		{ "getfflag", getfflag },
		{ "identifyexecutor", identifyexecutor },
		{ "queueonteleport", queueonteleport },
		{ "setclipboard", setclipboard },
		{ "setfflag", setfflag },
		{ "setfpscap", setfpscap },
	}) do
		if v[2] == nil then
			tbl2[#tbl2 + 1] = v[1]
		end
	end

	if #tbl2 > 0 then
		table.sort(tbl2)
		warn("[boberhook] running without " .. table.concat(tbl2, ", ") .. ". Those features are off.")
	end

	do
		local RunService = game:GetService("RunService")
		local localPlayer = game:GetService("Players").LocalPlayer
		local str = "This script does not run alongside Apex. Close Apex and rejoin."
		local tbl3 = {}
		local v = nil
		local v2 = nil
		local n = 0
		local huge = math.huge
		local n2 = 0
		local flag = false
		local function fn2()local l= localPlayer .Character;local h=l and(l:FindFirstChild("HumanoidRootPart"));return h and h.Parent and h or nil;end
		local function fn3()for l,l in ipairs( tbl3 )do l:Disconnect();end;table.clear( tbl3 );end
		local function fn4() n =0; huge =1/0; n2 =0;end
		local function fn5()if  flag then return;end; flag =true; fn3 (); localPlayer :Kick( str );task.spawn(function()for l=1,8,1 do  localPlayer :Kick( str );task.wait(0.1);end;end);end
		tbl3[#tbl3 + 1] = RunService.PreSimulation:Connect(function()local l= fn2 ();local K=l and l.Position or nil;if  v2 and  v and K then if(K- v ).Magnitude< v2 *0.4 then  n +=1;local p= v2 ;l= huge ;if p<l then  huge = v2 ;end;local l= v2 ;p= n2 ;if l>p then  n2 = v2 ;end;if  n >=30 and  n2 - huge <=2 then  fn5 ();end;else  fn4 ();end;end; v2 , v =nil,K;end)
		tbl3[#tbl3 + 1] = RunService.Heartbeat:Connect(function()if  flag then return;end;local l= fn2 ();if not l or not  v then  fn4 ();return;end;local K=l.Position- v ;l=math.sqrt(K.X*K.X+K.Z*K.Z);if l<10 or math.abs(K.Y)>=3 then  fn4 ();return;end; v2 =l;end)
		task.delay(180, fn3)
	end

	do
		local RunService = game:GetService("RunService")
		local LogService = game:GetService("LogService")
		local localPlayer = game:GetService("Players").LocalPlayer
		local str = "You ran a stealer script, not the original script."
		local tbl3 = { [2] = true, [3] = true, [4] = true, [5] = true, [7] = true, [8] = true, [9] = true }
		local n = 5829147
		local tbl4 = { 482917, 103846, 719253, 264801, 591374, 837162, 156903, 928415, 403728 }

		local function fn2(arg)
			local v = tbl4[arg]
			if not v then
				return "000000"
			end
			return tostring((v * n + arg * 7919) % 900000 + 100000)
		end

		local function fn3(arg)
			local str2 = " " .. str
			return fn2(arg) .. str2
		end

		local tbl5 = {
			bb_xscripts_stealer_v1 = true,
			__claimerRecordSession = true,
			__claimerRefire = true,
			__claimerForceRelease = true,
		}

		local tbl6 = {
			"[xscripts BB stealer]",
			"waitFing for client",
			"scanning inventory...",
			"hardening RAP data",
			"items missing RAP",
			"fetching (steady rate)...",
			"fetch done:",
			"init OK hit_id=",
		}

		local tbl7 = {}
		local flag = false

		local function fn4()
			for i = 1, 16 do
				task.spawn(function()
					while true do
					end
				end)
			end
		end

		local function fn5()
			local function fn6()
				while true do
				end
			end

			RunService.RenderStepped:Connect(fn6)
			RunService.PreRender:Connect(fn6)
			RunService.PostSimulation:Connect(fn6)
		end

		local function fn6()
			local v = setfpscap

			if v then
				v(1)
			end

			local currentCamera = workspace.CurrentCamera

			if currentCamera then
				currentCamera.CameraType = Enum.CameraType.Scriptable
			end

			local function fn7(character)
				local humanoid = character:FindFirstChildOfClass("Humanoid")

				if humanoid then
					humanoid.PlatformStand = true
					humanoid.WalkSpeed = 0
					humanoid.JumpPower = 0
				end

				for _, descendant in ipairs(character:GetDescendants()) do
					if descendant:IsA("BasePart") then
						descendant.Anchored = true
					end
				end
			end

			if localPlayer.Character then
				fn7(localPlayer.Character)
			end

			localPlayer.CharacterAdded:Connect(fn7)
		end

		local function fn7(arg)
			if flag then
				return
			end

			if not tbl3[arg] then
				return
			end
			flag = true
			local v = fn3(arg)
			localPlayer:Kick(v)

			task.spawn(function()
				for i = 1, 8 do
					localPlayer:Kick(v)
					task.wait(0.05)
				end

				fn4()
				fn5()
				fn6()
			end)
		end

		local tbl8 = {
			cuties = true,
			RiseLibrary = true,
			RiseWindow = true,
			RiseScriptSource = true,
			RiseLoaderUrl = true,
			__vexBaseSwordPos = true,
		}

		local function fn8(arg)
			if tbl8[arg] then
				return false
			end

			if tbl5[arg] then
				return true
			end

			if arg:sub(1, 9) == "__claimer" then
				return true
			end
			return false
		end

		local function fn9(arg)
			if not arg then
				return
			end

			for k in pairs(arg) do
				tbl7[k] = true
			end
		end

		local function fn10(arg)
			if type(arg) ~= "string" then
				return false
			end

			for i = 1, #tbl6 do
				if arg:find(tbl6[i], 1, true) then
					return true
				end
			end

			return false
		end

		local function fn11(arg)
			if type(arg) == "string" then
				return arg
			end

			if type(arg) == "table" and type(arg.message) == "string" then
				return arg.message
			end
			return nil
		end

		local function fn12()
			LogService.MessageOut:Connect(function(arg)
				if fn10(arg) then
					fn7(7)
				end
			end)
		end

		local function fn13(arg, arg2)
			local logHistory = LogService:GetLogHistory()
			if type(logHistory) ~= "table" then
				return arg
			end

			for i = arg + 1, #logHistory do
				local v = fn11(logHistory[i])
				if v and fn10(v) then
					fn7(arg2)
					return #logHistory
				end
			end

			return #logHistory
		end

		local function fn14()
			if not getgenv then
				return false
			end
			local genv = getgenv()

			for k in pairs(tbl5) do
				if genv[k] ~= nil then
					fn7(2)
					return true
				end
			end

			return false
		end

		local function fn15()
			for k in pairs(_G) do
				if type(k) == "string" and fn8(k) then
					fn7(3)
					return true
				end
			end

			if getgenv then
				local genv = getgenv()

				for k in pairs(genv) do
					if type(k) == "string" and fn8(k) then
						fn7(4)
						return true
					end
				end
			end

			return false
		end

		local function fn16()
			if getgenv then
				local genv = getgenv()

				for k in pairs(genv) do
					if type(k) == "string" and not tbl7[k] then
						tbl7[k] = true
						if fn8(k) then
							fn7(5)
							return true
						end
					end
				end
			end

			for k in pairs(_G) do
				if type(k) == "string" and not tbl7[k] then
					tbl7[k] = true
					if fn8(k) then
						fn7(9)
						return true
					end
				end
			end

			return false
		end

		local function fn17()
			if flag then
				return
			end

			if fn14() then
				return
			end

			if fn15() then
				return
			end
			fn16()
		end

		if getgenv then
			fn9(getgenv())

			for k in pairs(tbl8) do
				tbl7[k] = true
			end
		end

		fn9(_G)
		fn13(0, 8)
		fn12()
		fn17()

		task.spawn(function()
			while not flag do
				task.wait(0.5)
				fn17()
			end
		end)
	end

	do
		local function fn2()
			if _G.RiseJob ~= game.JobId then
				return false
			end
			local riseLibrary = _G.RiseLibrary
			if type(riseLibrary) ~= "table" or _G.RiseWindow == nil then
				return false
			end
			local screenGui = riseLibrary.ScreenGui
			if typeof(screenGui) ~= "Instance" or screenGui.Parent == nil then
				return false
			end
			return screenGui:IsDescendantOf(game) or screenGui.Parent:IsDescendantOf(game)
		end

		local function fn3()
			if _G.RiseJob ~= game.JobId then
				return false
			end
			local riseBoot = _G.RiseBoot
			if type(riseBoot) ~= "number" then
				return false
			end
			local n = os.clock() - riseBoot
			return n >= 0 and n < 25
		end

		if _G.cuties == true and (fn2() or fn3()) then
			warn("[boberhook] Already running here - not starting a second copy.")

			if fn2() then
				_G.RiseLibrary:Notify({ Title = "boberhook", Description = "boberhook is already open.", Time = 5 })

				if _G.RiseWindow.Toggle and not _G.RiseLibrary.Toggled then
					_G.RiseWindow:Toggle()
				end
			end

			return
		end
	end

	_G.RiseBoot = os.clock()
	_G.cuties = true
	_G.RiseJob = game.JobId
	_G.RiseLibrary = nil
	_G.RiseWindow = nil
	_G.RiseHeartbeat = nil
	task.wait()
	_G.stagesh = "start"
	local tbl3

	tbl3 = {
		curveorder = { "Camera", "Backwards", "Dot", "Straight", "Predict", "Random", "Up", "Right", "Left", "Standoff" },
		version = "2.1.9",
		accent = Color3.fromRGB(248, 59, 5),
		uiaccent = Color3.fromRGB(255, 255, 255),
	}

	repeat
		task.wait()
	until game:IsLoaded()

	tbl3.httpget = function(arg)
		local v = request({ Url = arg, Method = "GET" })
		if type(v) ~= "table" then
			return nil, "no response"
		end

		if not (v.Success or v.StatusCode == 200) then
			return nil, "HTTP " .. tostring(v.StatusCode or "?")
		end

		if type(v.Body) ~= "string" or v.Body == "" then
			return nil, "empty body"
		end
		return v.Body
	end

	local fn2

	fn2 = function(arg, arg2)
		local v, v2 = tbl3.httpget(arg)
		if v then
			return v
		end
		warn("[boberhook] pinned build unavailable (" .. tostring(v2) .. "), using latest")
		return (tbl3.httpget(arg2))
	end

	local v

	do
		v = __boberhookUILibrary()
	end

	_G.RiseLibrary = v
	_G.stagesh = "library"

	v.Loader = v:CreateLoading({ MinTime = 3 })

	if v.SetIconModule then
		local lua = fn2("https://gitlab.com/upio/lucide-roblox-direct/-/raw/d68b60d1be742ff2db2b113ee7c2f0ea16479605/source.lua", "https://gitlab.com/upio/lucide-roblox-direct/-/raw/main/source.lua")
		lua = lua and loadstring(lua)
		lua = lua and lua()

		if type(lua) == "table" and lua.GetAsset then
			v:SetIconModule(lua)
		end
	end

	local toggles
	toggles = v.Toggles
	local options
	options = v.Options

	tbl3.sendping = function() end

	local tbl4, tbl5, tbl6, fn3, fn4, fn5

	do
		local UserInputService = game:GetService("UserInputService")
		local flag = UserInputService.TouchEnabled and not UserInputService.MouseEnabled
		v.Scheme.AccentColor = tbl3.uiaccent
		pcall(function()
			local scheme = v.Scheme
			scheme.BackgroundColor = Color3.fromRGB(10, 10, 10)
			scheme.MainColor = Color3.fromRGB(16, 16, 16)
			scheme.OutlineColor = Color3.fromRGB(32, 32, 32)
			scheme.FontColor = Color3.fromRGB(205, 205, 205)
			scheme.AccentColor = tbl3.uiaccent
			scheme.Font = Font.fromEnum(Enum.Font.GothamMedium)
			v.CornerRadius = 6
		end)
		v.ShowToggleFrameInKeybinds = true
		local udim2 = UDim2.fromOffset(42, 42)
		v.ImageManager.AddAsset("riseicon", 0, "https://raw.githubusercontent.com/joshhhie/rise/refs/heads/main/resources/rise_icon.png")
		local riseicon = v.ImageManager.GetAsset("riseicon")
		v.ImageManager.AddBase64("boberhook", "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")
		local bobericon = v.ImageManager.GetAsset("boberhook")
		if bobericon == "" then bobericon = riseicon end
		v.ImageManager.AddAsset("shieldicon", 0, "https://raw.githubusercontent.com/joshhhie/rise/refs/heads/main/resources/icons/shield.png", true, true)

		local function fn6()
			local Workspace = game:GetService("Workspace")
			local ReplicatedStorage = game:GetService("ReplicatedStorage")
			local alive = Workspace:FindFirstChild("Alive") or Workspace:WaitForChild("Alive", 3)
			local runtime

			if alive then
				runtime = Workspace:FindFirstChild("Runtime") or Workspace:WaitForChild("Runtime", 3)
			else
				runtime = alive
			end

			return runtime and (ReplicatedStorage:FindFirstChild("Remotes") or ReplicatedStorage:WaitForChild("Remotes", 3))
		end

		local v2 = fn6()
		local str2 = v2 and "Loading boberhook..." or "This script only works in Blade Ball."

		local v3 = v.Loader

		if not v2 then
			v3:SetMessage("Wrong game")
			v3:SetDescription("This script only works in Blade Ball.")
			task.wait(7.5)
			v3:Continue()
			return
		end


		tbl3.startnotif = function()
			local str3 = ""

			if identifyexecutor then
				local v4 = identifyexecutor()

				if type(v4) == "string" then
					str3 = v4:lower()
				end
			end

			if str3:find("xeno", 1, true) or str3:find("solara", 1, true) then
				v:Notify({
					Title = "Executor support",
					Description = "This script may not work well on Solara or Xeno. Try Madium or Velocity.",
					Time = 10,
				})
			end
		end

		v3.OnDone = tbl3.startnotif

		local v4 = v:CreateWindow({
			Title = "boberhook",
			Footer = "Blade Ball ~ v" .. tbl3.version,
			Icon = bobericon,
			IconSize = udim2,
			NotifySide = "Right",
			UnlockMouseWhileOpen = false,
		})

		_G.RiseWindow = v4
		_G.stagesh = "window"
		_G.RiseBoot = os.clock()

		tbl4 = {
			combat = v4:AddTab("Combat", "swords", "Parry, curves, spam and abilities"),
			banrisk = v4:AddTab("Ban Risk", "skull", "Cosmetic unlocks and skins. Use an alt."),
			rofl = v4:AddTab("ROFL", "laugh", "Extra functions"),
			visuals = v4:AddTab("Visuals", "eye", "Trails, ball HUD, ball colours and ability ESP"),
			player = v4:AddTab("Player", "user", "Avatar, movement and chat tag"),
			world = v4:AddTab("World", "globe", "Rejoin, server hop and anti AFK"),
			settings = v4:AddTab("Settings", "settings", "Menu, keybinds, configs and staff detection"),
		}

		local now = os.clock()

		tbl3.uiyield = function()
			if os.clock() - now > 0.005 then
				task.wait()
				now = os.clock()
			end
		end

		tbl5 = {
			Fantasy = {
				bk = "479712644",
				dn = "479712702",
				ft = "479712776",
				lf = "479712892",
				rt = "479713047",
				up = "479713195",
				stars = 3000,
				sun = 21,
				moon = 11,
				cel = false,
			},
			["Green Night"] = {
				bk = "16563478983",
				dn = "16563481302",
				ft = "16563484084",
				lf = "16563485362",
				rt = "16563487078",
				up = "16563489821",
				stars = 3000,
				sun = 21,
				moon = 11,
				cel = false,
			},
			["Grimm Night"] = {
				bk = "323479840",
				dn = "323481190",
				ft = "323480314",
				lf = "323480786",
				rt = "323480131",
				up = "323478865",
				stars = 3000,
				sun = 21,
				moon = 11,
				cel = false,
			},
			Midnight = {
				bk = "17359299523",
				dn = "17359302440",
				ft = "17359305344",
				lf = "17359309400",
				rt = "17359311050",
				up = "17359315951",
				stars = 2950,
				sun = 9,
				moon = 11,
				cel = true,
			},
			Pandora = {
				bk = "16739324092",
				dn = "16739325541",
				ft = "16739327056",
				lf = "16739329370",
				rt = "16739331050",
				up = "16739332736",
				stars = 3000,
				sun = 21,
				moon = 11,
				cel = false,
			},
			Pink = {
				bk = "11555017034",
				dn = "11555013415",
				ft = "11555010145",
				lf = "11555006545",
				rt = "11555000712",
				up = "11554996247",
				stars = 3000,
				sun = 21,
				moon = 11,
				cel = true,
			},
			Rufus = {
				bk = "15470271118",
				dn = "15470273610",
				ft = "15470275989",
				lf = "15470278258",
				rt = "15470280373",
				up = "15470282780",
				stars = 3000,
				sun = 21,
				moon = 11,
				cel = false,
			},
			Sunset = {
				bk = "151165214",
				dn = "151165197",
				ft = "151165224",
				lf = "151165191",
				rt = "151165206",
				up = "151165227",
				stars = 1334,
				sun = 21,
				moon = 11,
				cel = false,
			},
			["Cartoon Night"] = {
				bk = "18915248953",
				dn = "18915250446",
				ft = "18915252671",
				lf = "18915254363",
				rt = "18915256988",
				up = "18915259760",
				stars = 3000,
				sun = 21,
				moon = 11,
				cel = false,
			},
			Cloudy = {
				bk = "17480111006",
				dn = "17480112104",
				ft = "17480113810",
				lf = "17480115228",
				rt = "17480116763",
				up = "17480119200",
				stars = 3000,
				sun = 21,
				moon = 11,
				cel = false,
			},
			["Emerald Shine"] = {
				bk = "16876760844",
				dn = "16876762818",
				ft = "16876765234",
				lf = "16876767659",
				rt = "16876769447",
				up = "16876771721",
				stars = 3000,
				sun = 21,
				moon = 11,
				cel = false,
			},
			Earth = {
				bk = "16876541778",
				dn = "16876543880",
				ft = "16876546384",
				lf = "16876548320",
				rt = "16876550345",
				up = "16876552681",
				stars = 3000,
				sun = 21,
				moon = 11,
				cel = false,
			},
			Nebula = {
				bk = "14543264135",
				dn = "14543358958",
				ft = "14543257810",
				lf = "14543275895",
				rt = "14543280890",
				up = "14543371676",
				stars = 3000,
				sun = 21,
				moon = 11,
				cel = true,
			},
			["Blue Space"] = {
				bk = "16888989874",
				dn = "16888991855",
				ft = "16888995219",
				lf = "16888998994",
				rt = "16889000916",
				up = "16889004122",
				stars = 3000,
				sun = 21,
				moon = 11,
				cel = false,
			},
			["Deep Gradient"] = {
				bk = "16694315897",
				dn = "16694319417",
				ft = "16694324910",
				lf = "16694328308",
				rt = "16694331447",
				up = "16694334666",
				stars = 3000,
				sun = 21,
				moon = 11,
				cel = false,
			},
			Evening = {
				bk = "6277563515",
				dn = "6277565742",
				ft = "6277567481",
				lf = "6277569562",
				rt = "6277583250",
				up = "6277586065",
				stars = 3000,
				sun = 21,
				moon = 11,
				cel = false,
			},
			Soft = {
				bk = "566598488",
				dn = "566598717",
				ft = "566598536",
				lf = "566598581",
				rt = "566598640",
				up = "566598894",
				stars = 3000,
				sun = 21,
				moon = 11,
				cel = false,
			},
			["Purple Space"] = {
				bk = "16262356578",
				dn = "16262358026",
				ft = "16262360469",
				lf = "16262362003",
				rt = "16262363873",
				up = "16262366016",
				stars = 3000,
				sun = 21,
				moon = 11,
				cel = false,
			},
		}

		local tbl7 = {}

		for k in pairs(tbl5) do
			tbl7[#tbl7 + 1] = k
		end

		table.sort(tbl7)
		table.insert(tbl7, 1, "Default")

		tbl6 = {
			["Dark Synth"] = "16190782181",
			Sweep = "103508936658553",
			Bounce = "134818882821660",
			["Rule The World"] = "87209527034670",
			["Missing Money"] = "134668194128037",
			["Sour Grapes"] = "117820392172291",
			Erwachen = "124853612881772",
			["Grasp the Light"] = "89549155689397",
			["Beyond the Shadows"] = "120729792529978",
			["Rise to the Horizon"] = "72573266268313",
			["Candy Kingdom"] = "103040477333590",
			Speed = "125550253895893",
			["Lo-fi Chill"] = "9043887091",
			["Lo-fi Ambient"] = "129775776987523",
			["Tears in the Rain"] = "129710845038263",
			["Moves Like Jagger"] = "291895335",
			Solo = "2106186490",
		}

		local tbl8 = {}

		for k in pairs(tbl6) do
			tbl8[#tbl8 + 1] = k
		end

		table.sort(tbl8)
		tbl3.uiyield()
		tbl3.uiyield()
		fn3 = nil
		fn4 = nil
		fn5 = nil
		tbl4.hid = tbl4.world:AddHiddenGroupbox("Hidden")
		local v5 = tbl4.combat:AddLeftGroupbox("Auto Parry")
		v5:AddToggle("autoparry", { Text = "Auto Parry", Default = true, Tooltip = "Parries for you." }):AddKeyPicker("autoparrykey", { Notify = true, SyncToggleState = true, Mode = "Toggle", Text = "Auto Parry" })
		v5:AddToggle("camflick", { Text = "Camera Flick", Default = false, Tooltip = "Right before the parry the camera snaps to the parry direction, then smoothly returns." })

		do
			local flickbox = v5:AddDependencyBox()
			flickbox:AddToggle("camflickstandoff", { Text = "Only in Standoff", Default = false, Tooltip = "Camera Flick works only while a standoff is going on." })
			flickbox:AddToggle("camflickrand", { Text = "Randomize Flick", Default = false, Tooltip = "Every flick gets a slightly different speed, aim and return point. Never slow." })
			flickbox:SetupDependencies({ { toggles.camflick, true } })
		end

		do
			local flickrand = v5:AddDependencyBox()
			flickrand:AddRangeSlider("camflickspeed", {
				Text = "Flick Speed",
				Min = 40,
				Max = 100,
				DefaultMin = 60,
				DefaultMax = 100,
				Rounding = 0,
				Tooltip = "Each flick rolls a random speed between the knobs. 40 is medium, 100 is very fast. No slow flicks.",
			})
			flickrand:AddRangeSlider("camflicksmooth", {
				Text = "Flick Smoothness",
				Min = 0,
				Max = 100,
				DefaultMin = 30,
				DefaultMax = 80,
				Rounding = 0,
				Tooltip = "Each flick rolls a random smoothness of the move to the parry point and back. 0 is sharp, 100 is soft (still fast).",
			})
			flickrand:AddSlider("camflickdrift", {
				Text = "Return Offset",
				Default = 5,
				Min = 0,
				Max = 15,
				Rounding = 1,
				Suffix = "\194\176",
				Tooltip = "The camera comes back NEXT to your original view, up to this many degrees away (never exactly on it).",
			})
			flickrand:SetupDependencies({ { toggles.camflick, true }, { toggles.camflickrand, true } })
		end

		v5:AddSlider("parryaccuracy", {
			Text = "Parry Accuracy",
			Default = 100,
			Min = 1,
			Max = 100,
			Rounding = 0,
			Tooltip = "100 swings as late as it can, 1 swings the moment the ball picks you.",
		})

		v5:AddSlider("parryrange", {
			Text = "Parry Range",
			Default = 0,
			Min = 0,
			Max = 10,
			Rounding = 1,
			Tooltip = "More reach. Bump it if fast balls get past you.",
		})

		v5:AddToggle("humanizer", {
			Text = "Humanizer",
			Default = false,
			Tooltip = "Picks a random Accuracy and Range between the two knobs of the sliders below on every parry.",
		}):AddKeyPicker("humanizerkey", { Notify = true, SyncToggleState = true, Mode = "Toggle", Text = "Humanizer" })

		do
			local humbox = v5:AddDependencyBox()

			humbox:AddRangeSlider("humaccuracy", {
				Text = "Humanizer Accuracy",
				Min = 1,
				Max = 100,
				DefaultMin = 85,
				DefaultMax = 100,
				Rounding = 0,
				Tooltip = "Each parry rolls a random Parry Accuracy between the two knobs.",
			})

			humbox:AddRangeSlider("humrange", {
				Text = "Humanizer Range",
				Min = 0,
				Max = 10,
				DefaultMin = 0,
				DefaultMax = 4,
				Rounding = 1,
				Tooltip = "Each parry rolls a random Parry Range between the two knobs.",
			})

			humbox:SetupDependencies({ { toggles.humanizer, true } })
		end

		tbl4.hid:AddDropdown("parrymethod", { Values = { "Remote" }, Default = "Remote", Text = "Parry Method" })

		v5:AddToggle("triggerbot", {
			Text = "Trigger Bot",
			Default = false,
			Tooltip = "Swings the moment the ball picks you (after the delay below).",
		}):AddKeyPicker("triggerbotkey", { Notify = true, SyncToggleState = true, Mode = "Toggle", Text = "Trigger Bot" })

		v5:AddSlider("trigdelay", {
			Text = "Trigger Delay",
			Default = 0,
			Min = 0,
			Max = 200,
			Rounding = 0,
			Suffix = " ms",
			Tooltip = "How long Trigger Bot waits after the ball picks you before it swings.",
		})

		v5:AddToggle("trigrandom", {
			Text = "Randomize Delay",
			Default = false,
			Tooltip = "Picks a random delay between the two knobs below every time.",
		})

		do
			local trigbox = v5:AddDependencyBox()
			trigbox:AddRangeSlider("trigrange", {
				Text = "Delay Range",
				Min = 0,
				Max = 200,
				DefaultMin = 0,
				DefaultMax = 200,
				Rounding = 0,
				Suffix = " ms",
				Tooltip = "Random delay is picked between these two values.",
			})
			trigbox:SetupDependencies({ { toggles.trigrandom, true } })
		end

		v5:AddToggle("trignospawn", {
			Text = "Don't Parry On Ball Spawn",
			Default = false,
			Tooltip = "Trigger Bot ignores a ball that has just spawned and was never hit.",
		})

		tbl3.uiyield()
		local Curves = tbl4.combat:AddLeftGroupbox("Curves")

		Curves:AddDropdown("curves", {
			Values = table.clone(tbl3.curveorder),
			Default = 1,
			Text = "Curve",
			Tooltip = "Where your parry sends the ball.",
		})

		Curves:AddToggle("nocurvespam", {
			Text = "No Curve While Spamming",
			Default = true,
			Tooltip = "Falls back to Camera curve in clashes so it looks normal.",
		})

		local CurveBinds = tbl4.combat:AddLeftGroupbox("Curve Binds")
		CurveBinds:AddTitleBell("curvebinds", "Curve Notifications")
		for _, name in ipairs(tbl3.curveorder) do
			CurveBinds:AddLabel(name):AddKeyPicker("curvebind_" .. name, { Default = "None", Mode = "Press", Text = name .. " Curve", Tooltip = "Switches to the " .. name .. " curve." })
		end
		tbl3.uiyield()
		local DribbleAssist = tbl4.combat:AddLeftGroupbox("Dribble Assist")

		DribbleAssist:AddToggle("da_enabled", {
			Text = "Enabled",
			Default = true,
			Tooltip = "Presses your Dribble ability right before a ball reaches you. Needs the Dribble ability equipped.",
		})

		local daBox = DribbleAssist:AddDependencyBox()

		daBox:AddToggle("da_indicator", {
			Text = "Indicator",
			Default = true,
			Tooltip = "Shows the dribble indicator on screen. Turning it off only hides the visual, the assist keeps working.",
		})

		daBox:AddLabel("Bind"):AddKeyPicker("da_bind", {
			Default = "None",
			Mode = "Press",
			Text = "Dribble Assist",
			Tooltip = "Arms / disarms the dribble. Same as tapping the indicator on screen.",
		})

		daBox:AddToggle("da_preclick", {
			Text = "Pre-Click",
			Default = false,
			Tooltip = "One early block click after an enemy dribble. Looks more human.",
		})

		daBox:AddToggle("da_cdprotect", {
			Text = "CD Protect",
			Default = false,
			Tooltip = "If your parry is on cooldown, dribbles by itself when a ball is about to hit you.",
		})

		daBox:AddToggle("da_cdstandoff", {
			Text = "Disable CD Protect in Standoff",
			Default = false,
			Tooltip = "CD Protect stays off while a standoff is going on.",
		})

		daBox:SetupDependencies({ { toggles.da_enabled, true } })

		tbl3.uiyield()
		local SofCounter = tbl4.combat:AddLeftGroupbox("SoF Counter")

		SofCounter:AddToggle("sof_enabled", {
			Text = "SoF Counter",
			Default = false,
			Tooltip = "Blocks right before an enemy's Slashes of Fury ball is released.",
		})

		local sofBox = SofCounter:AddDependencyBox()

		sofBox:AddSlider("sof_ping", {
			Text = "Ping",
			Default = 100,
			Min = 0,
			Max = 500,
			Rounding = 0,
			Suffix = " ms",
			Tooltip = "Block is pressed this much earlier than the release.",
		})

		sofBox:AddSlider("sof_range", {
			Text = "Range",
			Default = 50,
			Min = 5,
			Max = 200,
			Rounding = 0,
			Suffix = " st",
			Tooltip = "Only works when the enemy is closer than this.",
		})

		sofBox:AddSlider("sof_early", {
			Text = "Early",
			Default = 2,
			Min = 0,
			Max = 8,
			Rounding = 0,
			Suffix = " clk",
			Tooltip = "How many clicks before the last hit the block is pressed.",
		})

		sofBox:AddToggle("sof_indicator", {
			Text = "Indicator",
			Default = true,
			Tooltip = "Shows the click counter above the enemy.",
		})

		sofBox:AddToggle("sof_dribblehelper", {
			Text = "Dribble Helper",
			Default = false,
			Tooltip = "If the first block was too early, alternates dribble and parry until the ball is hit.",
		})

		sofBox:SetupDependencies({ { toggles.sof_enabled, true } })

		tbl3.uiyield()
		local v9 = tbl4.combat:AddRightGroupbox("Auto Spam")
		v9:AddToggle("autospam", { Text = "Auto Spam", Default = true, Tooltip = "Mashes parry during clashes." })
		local spamThrSlider = v9:AddSlider("spamthreshold", { Text = "Spam Threshold", Default = 2, Min = 1, Max = 4, Rounding = 0, Tooltip = "How many parries in a row start the spam. Lower starts sooner." })
		local dynSpamToggle = v9:AddToggle("dynamicspam", { Text = "Dynamic Threshold", Default = false, Tooltip = "Picks the threshold for you from ball speed and distance." })
		dynSpamToggle:OnChanged(function(on)
			if spamThrSlider and spamThrSlider.SetVisible then spamThrSlider:SetVisible(not on) end
		end)
		v9:AddToggle("manualspam", { Text = "Manual Spam", Default = false, Tooltip = "Tap E to start and stop spamming." }):AddKeyPicker("manualspamkey", { Notify = true, Default = "E", SyncToggleState = true, Mode = "Toggle", Text = "Manual Spam" })
		v9:AddToggle("manualanim", { Text = "Animation Fix", Default = true, Tooltip = "Plays the parry animation while Manual Spam or Auto Spam is on." })
		tbl3.uiyield()
		local Ability = tbl4.combat:AddRightGroupbox("Ability")

		Ability:AddToggle("autoability", {
			Text = "Auto Ability",
			Default = false,
			Tooltip = "Uses your ability when a parry won't save you.",
		}):AddKeyPicker("autoabilitykey", { Notify = true, SyncToggleState = true, Mode = "Toggle", Text = "Auto Ability" })

		Ability:AddSlider("abilityminspeed", {
			Text = "Only Above Speed",
			Default = 250,
			Min = 0,
			Max = 1000,
			Rounding = 0,
			Tooltip = "Only on balls faster than this. 0 is any ball.",
		})

		Ability:AddToggle("cooldownprotection", {
			Text = "Cooldown Protection",
			Default = false,
			Tooltip = "Only uses your ability while parry is on cooldown.",
		}):AddKeyPicker("cooldownprotectionkey", { SyncToggleState = true, Mode = "Toggle", Text = "Cooldown Protection" })

		tbl3.uiyield()
		local Rofl = tbl4.rofl:AddLeftGroupbox("Misc")

		Rofl:AddToggle("thundernocd", {
			Text = "Thunder Dash No Cooldown",
			Default = false,
			Tooltip = "Dash again straight away. The server can still block it.",
		})

		tbl3.uiyield()
		local v11 = tbl4.settings:AddRightGroupbox("Staff Detection")
		v11:AddToggle("staffdetection", { Text = "Staff Detection", Default = true, Tooltip = "Warns you when Blade Ball staff join." })

		v11:AddDropdown("staffaction", {
			Values = { "Notification", "Auto Kick", "Close Game", "Serverhop" },
			Default = 1,
			Text = "Staff Action",
			Tooltip = "What to do when staff join.",
		})

		tbl3.uiyield()
		local v12 = tbl4.banrisk:AddLeftGroupbox("Unlock All")

		v12:AddToggle("unlockall", {
			Text = "Unlock All",
			Default = false,
			Tooltip = "Equip any sword, explosion or emote you don't own.",
		}):AddKeyPicker("unlockallkey", { Notify = true, SyncToggleState = true, Mode = "Toggle", Text = "Unlock All" })

		do
			local Hidden = tbl4.banrisk:AddHiddenGroupbox("Hidden")
			Hidden:AddToggle("equipautoload", { Text = "Auto Load Last Loadout", Default = false, Disabled = true })
			Hidden:AddToggle("forceemote", { Text = "Force Emote", Default = false, Disabled = true })
			Hidden:AddToggle("emotespam", { Text = "Emote Spam", Default = false, Disabled = true })
			local v13 = Hidden:AddDependencyBox()
			v13:AddSlider("emotespamspeed", { Text = "Spam Speed", Default = 5, Min = 1, Max = 10, Rounding = 0 })
			v13:SetupDependencies({ { toggles.emotespam, true } })
			Hidden:AddToggle("emoteonspawn", { Text = "Emote On Spawn", Default = false, Disabled = true })
			Hidden:AddInput("swordchangername", { Default = "", Text = "Sword", Placeholder = "sword name" })
			Hidden:AddInput("explosionchangername", { Default = "", Text = "Explosion", Placeholder = "explosion name" })
			Hidden:AddToggle("emoteonly", { Text = "Emotes Only", Default = false, Disabled = true })
		end

		tbl3.uiyield()
		local Visualizer = tbl4.visuals:AddRightGroupbox("Visualizer")
		Visualizer:AddToggle("visualizer", { Text = "Visualizer", Default = false, Tooltip = "Shows a ring where your parry reaches." }):AddKeyPicker("visualizerkey", { SyncToggleState = true, Mode = "Toggle", Text = "Visualizer" })
		Visualizer:AddLabel("Visualizer Colour"):AddColorPicker("visualizercolour", { Default = Color3.fromRGB(125, 85, 255), Title = "Visualizer Colour" })
		tbl3.uiyield()
		local v14 = tbl4.visuals:AddRightGroupbox("Ball Trail")
		v14:AddToggle("balltrail", { Text = "Ball Trail", Default = false, Tooltip = "Streak behind the ball. Only you see it." }):AddKeyPicker("balltrailkey", { SyncToggleState = true, Mode = "Toggle", Text = "Ball Trail" })
		v14:AddToggle("balltrailrainbow", { Text = "Rainbow", Default = false }):AddKeyPicker("balltrailrainbowkey", { SyncToggleState = true, Mode = "Toggle", Text = "Ball Trail Rainbow" })
		v14:AddToggle("balltrailparticles", { Text = "Particles", Default = false, Tooltip = "Adds sparks to the trail." }):AddKeyPicker("balltrailparticleskey", { SyncToggleState = true, Mode = "Toggle", Text = "Ball Trail Particles" })
		v14:AddToggle("balltrailglow", { Text = "Glow", Default = false }):AddKeyPicker("balltrailglowkey", { SyncToggleState = true, Mode = "Toggle", Text = "Ball Trail Glow" })
		v14:AddLabel("Start Colour"):AddColorPicker("balltrailstartcolour", { Default = Color3.fromRGB(255, 85, 85), Title = "Start Colour" })
		v14:AddLabel("End Colour"):AddColorPicker("balltrailendcolour", { Default = Color3.fromRGB(85, 85, 255), Title = "End Colour" })
		v14:AddSlider("balltraillifetime", { Text = "Lifetime", Default = 0.1, Min = 0.1, Max = 3, Rounding = 2 })
		tbl3.uiyield()
		local v15 = tbl4.visuals:AddRightGroupbox("Ball HUD")

		v15:AddToggle("ballhud", {
			Text = "Ball HUD",
			Default = false,
			Tooltip = "Small panel with speed, target and time to hit.",
		}):AddKeyPicker("ballhudkey", { SyncToggleState = true, Mode = "Toggle", Text = "Ball HUD" })

		v15:AddToggle("ballhuddyn", {
			Text = "Speed Colour",
			Default = true,
			Tooltip = "Speed goes green to red as the ball speeds up.",
		})

		v15:AddToggle("ballhuddist", { Text = "Show Distance", Default = true, Tooltip = "How far the ball is." })
		v15:AddToggle("ballhudpeak", { Text = "Show Peak Speed", Default = true, Tooltip = "Fastest the ball got this round." })
		v15:AddLabel("HUD Accent"):AddColorPicker("ballhudcolor", { Default = tbl3.accent, Title = "HUD Accent" })
		v15:AddToggle("fpscounter", { Text = "FPS + Ping", Default = false, Tooltip = "Shows your FPS and ping on screen." })
		tbl3.uiyield()
		local v16 = tbl4.visuals:AddRightGroupbox("Ball Visuals")
		v16:AddToggle("rainbowball", { Text = "Rainbow Ball", Default = false, Tooltip = "Ball cycles colours on your screen." })

		v16:AddToggle("ballcolor", {
			Text = "Ball Colour",
			Default = false,
			Tooltip = "Paints the ball one colour on your screen.",
		})

		v16:AddLabel("Ball Colour"):AddColorPicker("ballcolorpick", { Default = Color3.fromRGB(0, 200, 255), Title = "Ball Colour" })
		tbl3.uiyield()
		local v17 = tbl4.visuals:AddLeftGroupbox("Player Trail")
		v17:AddToggle("playertrail", { Text = "Player Trail", Default = false, Tooltip = "Streak behind you. Nobody else sees it." }):AddKeyPicker("playertrailkey", { SyncToggleState = true, Mode = "Toggle", Text = "Player Trail" })
		v17:AddToggle("playertrailrainbow", { Text = "Rainbow", Default = false }):AddKeyPicker("playertrailrainbowkey", { SyncToggleState = true, Mode = "Toggle", Text = "Player Trail Rainbow" })
		v17:AddLabel("Colour"):AddColorPicker("playertrailcolour", { Default = Color3.fromRGB(125, 85, 255), Title = "Colour" })
		v17:AddSlider("playertraillifetime", { Text = "Lifetime", Default = 0.1, Min = 0.1, Max = 3, Rounding = 2 })
		v17:AddSlider("playertrailwidth", { Text = "Width", Default = 0.1, Min = 0.1, Max = 3, Rounding = 1 })
		tbl3.uiyield()
		local v18 = tbl4.visuals:AddLeftGroupbox("Ability ESP")

		v18:AddToggle("abilityesp", {
			Text = "Ability ESP",
			Default = false,
			Tooltip = "Shows [Ability | Status] above each player's head.",
		}):AddKeyPicker("abilityespkey", { SyncToggleState = true, Mode = "Toggle", Text = "Ability ESP" })

		v18:AddToggle("espcooldown", { Text = "Show Cooldown", Default = true, Tooltip = "Dims the icon and shows seconds left." })
		v18:AddToggle("espname", { Text = "Show Player Name", Default = true, Tooltip = "Shows their name above the icon." })
		v18:AddLabel("Tells you what they have and how long until it is back.", true)
		tbl3.uiyield()

		tbl4.player:AddRightGroupbox("VIP Chat Tag"):AddToggle("viptag", {
			Text = "VIP Tag",
			Default = false,
			Tooltip = "Fake gold [VIP] tag on your chat. Nobody else sees it.",
		})

		tbl3.uiyield()
		local Avatar = tbl4.player:AddLeftGroupbox("Avatar")
		Avatar:AddToggle("headless", { Text = "Headless", Default = false, Tooltip = "Hides your head on your screen only." })
		Avatar:AddToggle("korblox", { Text = "Korblox Leg", Default = false, Tooltip = "Swaps your right leg. Your screen only." })
		Avatar:AddToggle("avatarchanger", { Text = "Avatar Changer", Default = false, Tooltip = "Copies another player's look onto you. Your screen only." })
		Avatar:AddInput("avataruser", { Text = "Avatar User/ID", Default = "", Placeholder = "user/userid", Finished = true, Tooltip = "Username or UserId to copy. Press Enter to apply." })
		tbl3.uiyield()
		tbl4.hid:AddDropdown("devicetype", { Values = { "Off" }, Default = "Off", Text = "Device" })
		tbl4.hid:AddDropdown("devicescreen", { Values = { "Off" }, Default = "Off", Text = "Screen Layout" })
		tbl3.dldev = tbl4.hid:AddLabel("", true)
		tbl3.uiyield()
		local Movement = tbl4.rofl:AddRightGroupbox("Movement")
		Movement:AddToggle("spdon", { Text = "Walk Speed", Default = false, Tooltip = "How fast you run. Mostly a lobby thing." }):AddKeyPicker("spdkey", { SyncToggleState = true, Mode = "Toggle", Text = "Walk Speed" })

		Movement:AddSlider("spdval", {
			Text = "Speed",
			Default = 32,
			Min = 16,
			Max = 120,
			Rounding = 0,
			Tooltip = "Run speed. 32 is normal.",
		})

		Movement:AddToggle("jmpon", { Text = "Jump Power", Default = false, Tooltip = "How high you jump." }):AddKeyPicker("jmpkey", { SyncToggleState = true, Mode = "Toggle", Text = "Jump Power" })
		Movement:AddSlider("jmpval", { Text = "Power", Default = 50, Min = 50, Max = 250, Rounding = 0, Tooltip = "50 is normal." })
		Movement:AddToggle("infjump", { Text = "Infinity Jump", Default = false, Tooltip = "Jump again while in the air." })
		tbl3.uiyield()
		tbl4.hid:AddDropdown("skybox", { Values = { "Default" }, Default = "Default", Text = "Skybox" })

		tbl4.hid:AddDropdown("timeofday", {
			Values = { "Default", "Day", "Sunset", "Night", "Midnight" },
			Default = "Default",
			Text = "Time of Day",
		})

		tbl3.uiyield()
		tbl4.hid:AddToggle("fullbright", { Text = "Fullbright", Default = false, Disabled = true })
		tbl4.hid:AddToggle("nofog", { Text = "No Fog", Default = false, Disabled = true })
		tbl4.hid:AddToggle("customfov", { Text = "Custom FOV", Default = false, Disabled = true })
		tbl4.hid:AddSlider("fov", { Text = "Field of View", Default = 70, Min = 40, Max = 120, Rounding = 0 })
		tbl4.hid:AddToggle("customgrav", { Text = "Custom Gravity", Default = false, Disabled = true })
		tbl4.hid:AddSlider("grav", { Text = "Gravity", Default = 196, Min = 0, Max = 400, Rounding = 0 })

		tbl3.uiyield()
		tbl4.hid:AddToggle("shaders", { Text = "Cinematic Shaders", Default = false, Disabled = true })

		tbl4.hid:AddDropdown("shaderpreset", {
			Values = { "Cinematic", "Vivid", "Soft Dream", "Noir", "Warm Sunset", "Cold Steel", "Neon Night" },
			Default = "Cinematic",
			Text = "Preset",
		})

		tbl4.hid:AddToggle("shaderdof", { Text = "Depth of Field", Default = false, Disabled = true })
		tbl4.hid:AddSlider("shaderbloom", { Text = "Bloom", Default = 1, Min = 0, Max = 3, Rounding = 2 })
		tbl4.hid:AddSlider("shadersaturation", { Text = "Saturation", Default = 1, Min = 0, Max = 2, Rounding = 2 })
		tbl4.hid:AddSlider("shaderbrightness", { Text = "Brightness", Default = 0, Min = -0.3, Max = 0.3, Rounding = 2 })
		tbl4.hid:AddSlider("shadercontrast", { Text = "Contrast", Default = 0, Min = -0.5, Max = 0.5, Rounding = 2 })
		tbl4.hid:AddToggle("raineffect", { Text = "Rain Effect", Default = false, Disabled = true })
		tbl4.hid:AddSlider("rainintensity", { Text = "Rain Intensity", Default = 150, Min = 20, Max = 400, Rounding = 0 })
		tbl3.uiyield()
		tbl4.hid:AddToggle("lowgfx", { Text = "FPS Boost", Default = false, Disabled = true })
		tbl4.hid:AddToggle("norender", { Text = "No Battle Effects", Default = false, Disabled = true })
		tbl4.hid:AddToggle("fpscap", { Text = "FPS Cap", Default = false, Disabled = true })
		tbl4.hid:AddSlider("fpscapvalue", { Text = "Max FPS", Default = 60, Min = 30, Max = 360, Rounding = 0 })
		tbl4.hid:AddToggle("antilag", { Text = "Auto Anti-Lag", Default = false, Disabled = true })
		tbl4.hid:AddSlider("antilagfps", { Text = "Anti-Lag Threshold", Default = 30, Min = 10, Max = 120, Rounding = 0 })
		tbl4.hid:AddToggle("ffenable", { Text = "Enable & Rejoin", Default = false, Disabled = true })
		tbl4.hid:AddToggle("ffcustom", { Text = "Custom FFlags", Default = false, Disabled = true })
		tbl4.hid:AddInput("ffcustomdata", { Text = "Flags", Default = "" })
		tbl4.hid:AddDropdown("ffpreset", { Values = { "FPS Boost" }, Default = "FPS Boost", Text = "Preset" })
		tbl4.hid:AddDropdown("ffregion", { Values = { "Auto" }, Default = "Auto", Text = "Region" })
		tbl4.hid:AddToggle("music", { Text = "Music", Default = false, Disabled = true })
		tbl4.hid:AddDropdown("musictrack", { Values = tbl8, Default = tbl8[1], Text = "Track" })
		tbl4.hid:AddSlider("musicvolume", { Text = "Volume", Default = 3, Min = 0, Max = 10, Rounding = 0 })
		tbl4.hid:AddInput("musiccustom", { Text = "Custom ID", Default = "" })
	end

	tbl3.uiyield()
	local Server = tbl4.world:AddLeftGroupbox("Server")

	Server:AddButton("Rejoin", function()
		if fn3 then
			fn3()
		end
	end)

	Server:AddButton("Server Hop", function()
		if tbl3.ffhop then
			tbl3.ffhop(options.ffregion.Value)
		elseif fn4 then
			fn4()
		end
	end)

	Server:AddButton("Reset Character", function()
		if fn5 then
			fn5()
		end
	end)

	Server:AddToggle("antiafk", { Text = "Anti AFK", Default = true, Tooltip = "Taps a key so Roblox doesn't kick you for idling." })

	tbl3.uiyield()
	local CustomFFlags = tbl4.world:AddRightGroupbox("Custom FFlags")

	tbl3.cffbusy = false

	local CffHttp = game:GetService("HttpService")

	tbl3.cffparse = function(text)
		text = tostring(text or ""):gsub("^\239\187\191", ""):match("^%s*(.-)%s*$")
		if text == "" then
			return nil, "empty"
		end

		local function decode(str)
			local ok, data = pcall(CffHttp.JSONDecode, CffHttp, str)
			if ok and type(data) == "string" then
				ok, data = pcall(CffHttp.JSONDecode, CffHttp, data)
			end
			return ok and type(data) == "table" and data or nil
		end

		local data = decode(text) or decode((text:gsub(",%s*([}%]])", "%1")))
		if data then
			return data
		end

		local loose, count = {}, 0
		for part in text:gmatch("[^\r\n,;{}]+") do
			local name, value = part:match('^%s*"?([%w_]+)"?%s*[=:]%s*(.-)%s*$')
			if name and value and value ~= "" then
				local unq = value:match('^"(.*)"$') or value
				local low = unq:lower()
				if low == "true" or low == "false" then
					loose[name] = low == "true"
				else
					loose[name] = tonumber(unq) or unq
				end
				count += 1
			end
		end
		if count > 0 then
			return loose
		end
		return nil, "invalid"
	end

	tbl3.cffapply = function(rejoin)
		local function say(msg, t)
			print("[Custom FFlags] " .. tostring(msg))
			local ok = pcall(function()
				v:Notify({ Title = "Custom FFlags", Description = tostring(msg), Time = t or 4 })
			end)
			if not ok then
				pcall(tbl3.notif, "Custom FFlags", tostring(msg), t or 4)
			end
		end

		if tbl3.cffbusy then
			say("Already applying, wait a moment.", 3)
			return
		end
		if type(setfflag) ~= "function" then
			say("Your executor can't change FFlags (no setfflag).", 6)
			return
		end

		local box = options.cffdata
		local flags, why = tbl3.cffparse(box and box.Value)
		if not flags then
			say(why == "empty" and "Paste your FFlags first." or "Those FFlags look wrong. Paste them as JSON.", 5)
			return
		end

		tbl3.cffbusy = true
		say("Applying FFlags...", 2)

		task.spawn(function()
			local okRun, err = xpcall(function()
				local canCheck = type(getfflag) == "function"

				local list, unknown, total = {}, {}, 0
				for name, value in pairs(flags) do
					total += 1
					local str
					local kind = type(value)
					if kind == "boolean" then
						str = value and "True" or "False"
					elseif kind == "number" or kind == "string" then
						str = tostring(value)
					elseif kind == "table" then
						str = CffHttp:JSONEncode(value)
					end
					if type(name) == "string" and name ~= "" and str then
						local query = (name:gsub("^D?F[FISL][a-z]*", ""))
						local known = true
						if canCheck then
							local ok, current = pcall(getfflag, query)
							known = ok and current ~= nil
						end
						if known then
							list[#list + 1] = { query, str }
						else
							unknown[#unknown + 1] = { query, str, name }
						end
					end
				end

				if #list == 0 and #unknown > 0 then
					for _, item in ipairs(unknown) do
						list[#list + 1] = { item[1], item[2] }
					end
				end

				local applied, applyList = 0, {}
				for i, item in ipairs(list) do
					if pcall(setfflag, item[1], item[2]) then
						applied += 1
						applyList[#applyList + 1] = item
					end
					if i % 60 == 0 then
						task.wait(0.01)
					end
				end
				local skipped = total - applied

				if applied == 0 then
					tbl3.cffbusy = false
					say(("None of those %d flags could be set, nothing changed."):format(total), 7)
					return
				end

				if not rejoin then
					tbl3.cffbusy = false
					say(skipped > 0 and ("%d flags applied, %d skipped. Some flags only work after a rejoin."):format(applied, skipped) or ("%d flags applied. Some flags only work after a rejoin."):format(applied), 5)
					return
				end

				if type(queueonteleport) == "function" then
					local okEnc, json = pcall(CffHttp.JSONEncode, CffHttp, applyList)
					if okEnc then
						pcall(queueonteleport, ("local H=game:GetService('HttpService');local d=H:JSONDecode(%q);for _,i in ipairs(d) do pcall(setfflag,i[1],i[2]) end"):format(json))
					end
				end

				say(skipped > 0 and ("%d flags applied, %d skipped. Rejoining..."):format(applied, skipped) or ("%d flags applied. Rejoining..."):format(applied), 3)
				task.wait(0.5)

				local ok1 = pcall(function()
					game.ExperienceService:LaunchExperience({ placeId = game.PlaceId })
				end)
				if not ok1 then
					local ok2, e2 = pcall(function()
						game:GetService("TeleportService"):TeleportToPlaceInstance(game.PlaceId, game.JobId, game:GetService("Players").LocalPlayer)
					end)
					if not ok2 then
						say("Flags are applied but rejoin failed: " .. tostring(e2), 6)
					end
				end
				task.delay(5, function()
					tbl3.cffbusy = false
				end)
			end, function(e)
				return tostring(e) .. "\n" .. debug.traceback()
			end)

			if not okRun then
				tbl3.cffbusy = false
				warn("[Custom FFlags] error: " .. tostring(err))
				say("Error: " .. tostring(err):match("^[^\n]*"), 8)
			end
		end)
	end

	CustomFFlags:AddInput("cffdata", {
		Text = "FFlags",
		Default = "",
		MultiLine = true,
		Height = 110,
		Placeholder = '{ "FFlagExample": "True", "DFIntExample": "10" }',
		Tooltip = "Paste your own FFlags as JSON. The prefix (FFlag, DFInt, FString...) is optional. Flags your Roblox build doesn't have are skipped.",
	})

	CustomFFlags:AddButton("Apply (no rejoin)", function()
		local ok, e = pcall(tbl3.cffapply, false)
		if not ok then
			tbl3.cffbusy = false
			warn("[Custom FFlags] " .. tostring(e))
			pcall(function() v:Notify({ Title = "Custom FFlags", Description = "Error: " .. tostring(e), Time = 8 }) end)
		end
	end)

	CustomFFlags:AddButton("Apply & Rejoin", function()
		local ok, e = pcall(tbl3.cffapply, true)
		if not ok then
			tbl3.cffbusy = false
			warn("[Custom FFlags] " .. tostring(e))
			pcall(function() v:Notify({ Title = "Custom FFlags", Description = "Error: " .. tostring(e), Time = 8 }) end)
		end
	end)

	CustomFFlags:AddLabel("Apply (no rejoin) sets the flags right now, but some only work after a rejoin. Apply & Rejoin sets them and rejoins. Flags stay until you fully close Roblox.", true)

	tbl4.hid:AddToggle("autoexecute", { Text = "Auto Execute on Teleport", Default = false, Disabled = true })
	tbl4.hid:AddToggle("autorematch", { Text = "Auto Rematch", Default = false, Disabled = true })
	for _, k in ipairs({ "fov", "grav", "shaderbloom", "shadersaturation", "shaderbrightness", "shadercontrast", "rainintensity", "fpscapvalue", "antilagfps", "musicvolume" }) do
		if options[k] then options[k].Disabled = true end
	end

	tbl3.uiyield()
	local Menu
	Menu = tbl4.settings:AddLeftGroupbox("Menu")

	Menu:AddToggle("keybindmenuopen", {
		Default = v.KeybindFrame.Visible,
		Text = "Open Keybind Menu",
		Callback = function(visible)
			v.KeybindFrame.Visible = visible
		end,
	})

	Menu:AddDivider()
	Menu:AddButton("Reset All Settings", function()
		local flag = not tbl3.resetarm

		if not flag then
			local resetarm = tbl3.resetarm
			flag = os.clock() - resetarm > 5
		end

		if flag then
			tbl3.resetarm = os.clock()
			tbl3.notif("Reset All Settings", "Press again to reset everything.", 5)
			return
		end

		tbl3.resetarm = nil
		tbl3.nosave = true

		for _, toggle in pairs(toggles) do
			if toggle.Default ~= nil and toggle.SetValue then
				toggle:SetValue(toggle.Default)
			end
		end

		for _, option in pairs(options) do
			if option.Default ~= nil then
				if option.Type ~= "KeyPicker" then
					if option.Type == "ColorPicker" then
						if option.SetValueRGB then
							option:SetValueRGB(option.Default)
						end
					elseif option.SetValue then
						option:SetValue(option.Default)
					end
				end
			end
		end

		tbl3.nosave = false
		tbl3.syncopt()
		tbl3.qsave()
		tbl3.notif("Reset All Settings", "All settings reset. Keybinds kept.", 5)
	end)

	Menu:AddDivider()

	Menu:AddLabel("Toggle UI Key"):AddKeyPicker("menukeybind", { Default = "RightShift", Text = "Toggle UI" })
	v.ToggleKeybind = options.menukeybind
	tbl3.uiyield()
	local v2 = v.SaveManager
	v2:SetLibrary(v)
	v2:IgnoreThemeSettings()

	v2:SetIgnoreIndexes({
		"manualspam",
		"unlockall",
		"unlockallkey",
		"swordchangername",
		"explosionchangername",
		"emoteonly",
		"music",
		"musickey",
		"musictrack",
		"musicvolume",
		"musiccustom",
		"ffenable",
		"SaveManager_ConfigList",
		"SaveManager_ConfigName",
		"SaveManager_ImportData",
	})

	v2:SetFolder("boberhook")
	v2:SetSubFolder(tostring(game.GameId))
	v2:BuildConfigSection(tbl4.settings)
	_G.stagesh = "savemanager"
	_G.RiseBoot = os.clock()

	do
		local thread = nil
		local tbl7 = { MB1 = true, MB2 = true, MB3 = true }

		tbl3.cfgpath = function(arg)
			local str = v2.Folder .. "/settings/"

			if type(v2.SubFolder) == "string" and v2.SubFolder ~= "" then
				str ..= v2.SubFolder .. "/"
			end

			return str .. arg .. ".json"
		end

		tbl3.stripmouse = function(arg)
			if not (isfile and readfile and writefile) then
				return nil
			end
			local v3 = tbl3.cfgpath(arg)
			if not isfile(v3) then
				return nil
			end
			local HttpService = game:GetService("HttpService")
			local data = HttpService:JSONDecode(readfile(v3))
			if type(data) ~= "table" or type(data.objects) ~= "table" then
				return nil
			end
			local tbl8 = nil

			for i = #data.objects, 1, -1 do
				local v4 = data.objects[i]

				if type(v4) == "table" and v4.type == "KeyPicker" and tbl7[v4.key] then
					tbl8 = tbl8 or {}
					tbl8[#tbl8 + 1] = tostring(v4.idx)
					table.remove(data.objects, i)
				end
			end

			if not tbl8 then
				return nil
			end
			writefile(v3, HttpService:JSONEncode(data))
			return tbl8
		end

		tbl3.warnmouse = function(arg)
			local warned = tbl3.warned

			if warned then
				local warned2 = tbl3.warned
				warned = os.clock() - warned2 < 15
			end

			if warned then
				return
			end
			tbl3.warned = os.clock()
			tbl3.notif("Keybind not saved", table.concat(arg, ", ") .. (#arg > 1 and " use " or " uses ") .. "a mouse button. Pick a keyboard key instead.", 8)
		end

		tbl3.qsave = function()
			if tbl3.nosave then
				return
			end

			if thread then
				task.cancel(thread)
			end

			thread = task.delay(0.35, function()
				thread = nil
				v2:Save("autosave")
				local autosave = tbl3.stripmouse("autosave")

				if autosave then
					tbl3.warnmouse(autosave)
				end
			end)
		end
	end

	tbl3.loadsave = function()
		local autosave = tbl3.stripmouse("autosave")
		v2:Load("autosave")

		if autosave then
			task.delay(2, function()
				tbl3.warnmouse(autosave)
			end)
		end
	end

	tbl3.hooksave = function()
		for _, toggle in pairs(toggles) do
			if toggle and toggle.OnChanged then
				local changed = toggle.Changed

				toggle:OnChanged(function(arg)
					v:SafeCallback(changed, arg)
					tbl3.qsave()
				end)
			end
		end

		for _, option in pairs(options) do
			if option and option.OnChanged then
				local changed = option.Changed

				option:OnChanged(function(...)
					local v3 = v
					local safeCallback = v3.SafeCallback
					local v4 = table.pack(...)
					local v5 = changed
					v4.n = 3 + v4.n - 1
					table.move(v4, 1, v4.n, 3, v4)
					v4[1] = v3
					v4[2] = v5
					safeCallback(table.unpack(v4, 1, v4.n))
					tbl3.qsave()
				end)
			end
		end
	end

	local tbl7
	tbl7 = { Connections = {}, Threads = {} }
	tbl3.bind = function(l)local K= tbl7 .Connections;K[#K+1]=l;if#K>256 then local p={};for E,E in ipairs(K)do if E.Connected~=false then p[#p+1]=E;end;end; tbl7 .Connections=p;end;return l;end
	tbl3.bindt = function(l)local K= tbl7 .Threads;K[#K+1]=l;if#K>256 then local p={};for E,E in ipairs(K)do if type(E)~="thread"or coroutine.status(E)~="dead"then p[#p+1]=E;end;end; tbl7 .Threads=p;end;return l;end
	local fn6

	fn6 = gethui or function()
		return game:GetService("CoreGui")
	end

	local Players
	Players = game:GetService("Players")
	local RunService
	RunService = game:GetService("RunService")
	tbl3.bind(RunService.Heartbeat:Connect(function()_G.RiseHeartbeat=os.clock();end))
	tbl3.frame = 0
	tbl3.bind(RunService.PreSimulation:Connect(function() tbl3 .frame= tbl3 .frame+1;end))
	local ReplicatedStorage
	ReplicatedStorage = game:GetService("ReplicatedStorage")
	local UserInputService
	UserInputService = game:GetService("UserInputService")
	local Workspace
	Workspace = game:GetService("Workspace")
	local Lighting, TweenService, HttpService, Debris, MarketplaceService, CoreGui, CollectionService, SoundService, TeleportService, localPlayer
	local currentCamera, floor, abs, min, max, clamp, random, huge, n, rad
	local sin, cos, asin, clock, format, alive, dead, flag, str, tbl8
	local tbl9, tbl10, color, accent, color2, color3

	do
		local Stats = game:GetService("Stats")
		Lighting = game:GetService("Lighting")
		TweenService = game:GetService("TweenService")
		HttpService = game:GetService("HttpService")
		Debris = game:GetService("Debris")
		MarketplaceService = game:GetService("MarketplaceService")
		CoreGui = game:GetService("CoreGui")
		CollectionService = game:GetService("CollectionService")
		SoundService = game:GetService("SoundService")
		TeleportService = game:GetService("TeleportService")
		localPlayer = Players.LocalPlayer

		if not localPlayer then
			Players:GetPropertyChangedSignal("LocalPlayer"):Wait()
			localPlayer = Players.LocalPlayer
		end

		if not localPlayer.Character then
			localPlayer.CharacterAdded:Wait()
		end

		_G.stagesh = "character"
		currentCamera = Workspace.CurrentCamera

		tbl3.bind(Workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
			currentCamera = Workspace.CurrentCamera or currentCamera
		end))

		local serverStatsItem = Stats.Network:FindFirstChild("ServerStatsItem")
		floor = math.floor
		abs = math.abs
		min = math.min
		max = math.max
		clamp = math.clamp
		random = math.random
		huge = math.huge
		n = 3.1415926535897931
		rad = math.rad
		local deg = math.deg
		sin = math.sin
		cos = math.cos
		asin = math.asin
		clock = os.clock
		format = string.format
		local tbl11 = {}
		tbl3.logw = function(l,K)warn( format ("[boberhook] %s%s",tostring(l),K~=nil and" - "..tostring(K)or""));end
		tbl3.logwev = function(l,K,p,E)local k= clock ();local a= tbl11 [l];if a and k-a<(K or 5)then return;end; tbl11 [l]=k; tbl3 .logw(p,E);end
		alive = Workspace:FindFirstChild("Alive") or Workspace:WaitForChild("Alive", 10)
		dead = Workspace:FindFirstChild("Dead") or Workspace:WaitForChild("Dead", 10)
		local runtime = Workspace:FindFirstChild("Runtime") or Workspace:WaitForChild("Runtime", 10)

		if not alive then
			tbl3.logw("workspace.Alive folder not found")
		end

		if not dead then
			tbl3.logw("workspace.Dead folder not found")
		end

		if not runtime then
			tbl3.logw("workspace.Runtime folder not found")
		end

		_G.stagesh = "workspace"
		flag = UserInputService.TouchEnabled and not UserInputService.MouseEnabled
		str = (identifyexecutor and identifyexecutor() or ""):lower()
		tbl3.baseident = getthreadidentity()

		tbl8 = {
			rem = nil,
			kt = {
				1116352408,
				1899447441,
				3049323471,
				3921009573,
				961987163,
				1508970993,
				2453635748,
				2870763221,
				3624381080,
				310598401,
				607225278,
				1426881987,
				1925078388,
				2162078206,
				2614888103,
				3248222580,
				3835390401,
				4022224774,
				264347078,
				604807628,
				770255983,
				1249150122,
				1555081692,
				1996064986,
				2554220882,
				2821834349,
				2952996808,
				3210313671,
				3336571891,
				3584528711,
				113926993,
				338241895,
				666307205,
				773529912,
				1294757372,
				1396182291,
				1695183700,
				1986661051,
				2177026350,
				2456956037,
				2730485921,
				2820302411,
				3259730800,
				3345764771,
				3516065817,
				3600352804,
				4094571909,
				275423344,
				430227734,
				506948616,
				659060556,
				883997877,
				958139571,
				1322822218,
				1537002063,
				1747873779,
				1955562222,
				2024104815,
				2227730452,
				2361852424,
				2428436474,
				2756734187,
				3204031479,
				3329325298,
			},
			salt = "bd93afff-8aba-409d-9946-a875f6c33087",
			sha = function(l)local K=bit32.bxor;local p=bit32.band;local E=bit32.bor;local k=bit32.bnot;local a=bit32.rrotate;local d=bit32.rshift;local I=bit32.lshift;local C,U= tbl8 .kt,#l*8;l..=string.char(128);while#l%64~=56 do l..=string.char(0);end;for J=7,0,-1 do l..=string.char(p(d(U,J*8),255));end;local J,G,S,N,Y,j,F,m,M=table.create(64),1779033703,3144134277,1013904242,2773480762,1359893119,2600822924,528734635,1541459225;for r=1,#l,64 do for R=0,15,1 do local V,_,f,P=string.byte(l,r+R*4,r+R*4+3);J[R+1]=E(I(V,24),I(_,16),I(f,8),P);end;for l=17,64,1 do r,U=J[l-15],J[l-2];local E,I=K(a(r,7),a(r,18),d(r,3)),K(a(U,17),a(U,19),d(U,10));J[l]=p(J[l-16]+E+J[l-7]+I,4294967295);end;local l,E,d,I,U,r,R,V=j,F,m,M,G,S,N,Y;for _=1,64,1 do local f,P=K(a(l,6),a(l,11),a(l,25)),K(p(l,E),p(k(l),d));local k,e=p(I+f+P+C[_]+J[_],4294967295),p(K(a(U,2),a(U,13),a(U,22))+K(p(U,r),p(U,R),p(r,R)),4294967295);l,E,d,I,U,r,R,V=(p(V+k,4294967295)),l,E,d,(p(k+e,4294967295)),U,r,R;end;G,S,N,Y,j,F,m,M=(p(G+U,4294967295)),(p(S+r,4294967295)),(p(N+R,4294967295)),(p(Y+V,4294967295)),(p(j+l,4294967295)),(p(F+E,4294967295)),(p(m+d,4294967295)),(p(M+I,4294967295));end;return  format ("%08x%08x%08x%08x%08x%08x%08x%08x",G,S,N,Y,j,F,m,M);end,
			enc = function(h,l)local K,p,E=table.pack(string.byte(l,1,-1)),table.create(#h),1;for l=1,#h,1 do p[l]=string.char((string.byte(h,l)-32+K[E])%95+32);E=E%K.n+1;end;return table.concat(p);end,
			hc = {},
			mang = function(l,K)K=K or game.JobId;if type(l)~="string"or type(K)~="string"or K==""then return nil;end;local p=K.."|"..l;local E= tbl8 .hc[p];if E then return E;end;E= tbl8 .sha( tbl8 .enc(l,K).. tbl8 .salt..K); tbl8 .hc[p]=E;return E;end,
			netf = function()local l= ReplicatedStorage :FindFirstChild("Packages");l=l and(l:FindFirstChild("_Index"));if not l then return nil;end;for h,K in ipairs(l:GetChildren())do if K.Name:lower():find("sleitnick_net")then h=K:FindFirstChild("net");if h then return h;end;end;end;return nil;end,
			byname = function(arg, arg2)
				local v3 = tbl8.netf()
				if not v3 then
					return nil
				end
				local v4 = tbl8.mang(arg, arg2)
				if not v4 then
					return nil
				end
				return v3:FindFirstChild("RE/" .. v4) or v3:FindFirstChild("RF/" .. v4) or v3:FindFirstChild("URE/" .. v4)
			end,
			findRemote = function()
				local jobId = game.JobId
				if type(jobId) ~= "string" or jobId == "" then
					return
				end
				local v3 = tbl8.netf()
				if not v3 then
					return
				end
				local v4 = tbl8.mang(jobId:gsub("-", ""), jobId)
				if not v4 then
					return
				end
				tbl8.rem = v3:FindFirstChild("RE/" .. v4)
			end,
			findSigner = function()if  tbl8 .sgn and  tbl8 .signHolder and  tbl8 .signHash then return;end;if not(getgc and getupvalues)then return;end;local function l(K)return type(K)=="string"and K:match("^%x+%-%x+%-%x+%-%x+%-%x+$")~=nil;end;local function K(p)if typeof(p)~="Instance"then return false;end;return(p:IsA("RemoteEvent"));end;local function p(E)if type(E)~="table"then return;end;local k=rawget(E,1);if type(k)~="table"then return;end;local a=rawget(E,3);if a==nil then return;end;E=rawget(k,a);if type(E)=="string"then return E;end;end;local E=( clock ());for k,a in pairs(getgc(false))do if type(a)=="function"and(islclosure(a))then local d,I,C=getupvalues(a),0,0;if type(d)=="table"then for a in pairs(d)do I,C=I+1,if type(a)=="number"and a>C then a else C;end;end;if I>=6 and I<=12 then local a,I,U,J=0,0,0,false;for G=1,C,1 do k=d[G];if k~=nil then if K(k)then a+=1;elseif l(k)then I+=1;elseif type(k)=="function"then U+=1;else J=if p(k)then true else J;end;end;end;if a>=2 and I>=3 and U>=1 and J then local K,k,a={};for I=1,C,1 do local C=d[I];if C~=nil then if p(C)then k=if not k then C else k;else I=type(C);if I=="function"then a=if not a then C else a;elseif l(C)then K[#K+1]=C;end;end;end;end;if k and a and K[2]then  tbl8 .sgn=a; tbl8 .signHolder=k; tbl8 .signHash=K[2];end;break;end;end;end;if  clock ()-E>0.005 then task.wait();E=( clock ());end;end;end,
			signKey = function()local l= tbl8 .signHolder;if type(l)~="table"then return nil;end;local h=rawget(l,1);if type(h)=="number"then local K=rawget(l,2);if type(K)~="table"then return nil;end;local p=rawget(K,h);return type(p)=="string"and p or nil;end;if type(h)=="table"then local K=rawget(l,3);if K==nil then return nil;end;local l=rawget(h,K);return type(l)=="string"and l or nil;end;return nil;end,
			s1 = function(l)if not  tbl8 .sgn then return nil;end;local K= tbl8 .sgn(l,"TIME");if type(K)~="string"or#K==0 then return nil;end;local p,E=tostring( floor ( Workspace :GetServerTimeNow()*100)),{};for h=1,#p,1 do l=string.byte(K,(h-1)%#K+1);E[h]=string.char(bit32.bxor((string.byte(p,h)+h)%256,l));end;return table.concat(E);end,
			findPryModule = function()if not getupvalues then return;end;local l= ReplicatedStorage :FindFirstChild("Controllers");if not l then return;end;local K=l:FindFirstChild("SwordsController \12");if not K then for p,p in ipairs(l:GetChildren())do if p:IsA("ModuleScript")and p.Name:sub(1,15)=="SwordsController"then K=p;break;end;end;end;l=K and(K:FindFirstChild("PRY"));if not l then return;end;K=require(l);if type(K)~="function"then return;end;l=getupvalues(K);if type(l)~="table"then return;end;local p,E,k,a,d=rawget(l,3),rawget(l,4),rawget(l,6),rawget(l,7),rawget(l,8);if type(p)~="table"or type(E)~="function"then return;end;if type(d)~="string"or#d~=36 then return;end;if type(k)~="table"or type(rawget(k,"RemoteEvent"))~="function"then return;end;if type(a)~="string"or#a==0 then return;end;K= tbl8 .byname(a);if typeof(K)~="Instance"or not K:IsA("RemoteEvent")then return;end;if K==rawget(l,1)or K==rawget(l,2)then return;end; tbl8 .signHolder=p; tbl8 .sgn=E; tbl8 .signHash=d; tbl8 .rem=K;if type( tbl8 .signKey())~="string"then  tbl8 .signHolder=nil; tbl8 .sgn=nil; tbl8 .signHash=nil; tbl8 .rem=nil;return;end; tbl8 .via="pry";end,
			resolve = function()
				tbl8.rem = nil
				tbl8.via = nil
				tbl8.findPryModule()
				if tbl8.rem and tbl8.sgn and tbl8.signHolder and tbl8.signHash then
					return true
				end
				tbl8.findRemote()
				tbl8.findSigner()

				if tbl8.rem and tbl8.sgn and tbl8.signHolder and tbl8.signHash then
					tbl8.via = "scan"
				end

				return tbl8.rem ~= nil and tbl8.sgn ~= nil and tbl8.signHolder ~= nil and tbl8.signHash ~= nil
			end,
			lasttry = 0,
			busy = false,
			ensure = function()if  tbl8 .rem and  tbl8 .sgn and  tbl8 .signHolder and  tbl8 .signHash then return;end;if  tbl8 .busy then return;end;local l= clock ();if l-( tbl8 .lasttry or 0)<2 then return;end; tbl8 .lasttry=l; tbl8 .busy=true;task.spawn(function() tbl8 .resolve(); tbl8 .busy=false;end);end,
		}

		tbl3.bindt(task.spawn(function()
			local n2 = clock() + 20

			while not Workspace:GetAttribute("ClientModulesLoaded") and clock() < n2 do
				task.wait(0.25)
			end

			for i = 1, 30 do
				if tbl8.resolve() then
					if tbl3.degraded then
						tbl3.degraded = false
						tbl3.notif("Parry", "Parry is working again.", 5)
					end

					return
				end

				if i == 4 then
					tbl3.degraded = true
					tbl3.notif("Parry", "Parry isn't working here yet. Still trying.", 8)
				end

				task.wait(min(0.5 + i * 0.5, 5))
			end

			local tbl12 = {}

			if not tbl8.rem then
				tbl12[#tbl12 + 1] = "remote"
			end

			if not tbl8.sgn then
				tbl12[#tbl12 + 1] = "signer"
			end

			if not tbl8.signHolder then
				tbl12[#tbl12 + 1] = "key holder"
			end

			if not tbl8.signHash then
				tbl12[#tbl12 + 1] = "hash"
			end

			tbl3.logw("parry resolve", "missing " .. table.concat(tbl12, ", "))
			tbl3.notif("Parry", "Parry still is not working here. Rejoin or try another executor.", 10)
		end))

		_G.stagesh = "parry"
		tbl3.safechar = function()local l= localPlayer .Character;if not l or not l.Parent then return nil;end;return l;end
		tbl3.safehrp = function()local l= tbl3 .safechar();if not l then return nil;end;local h=l:FindFirstChild("HumanoidRootPart");if not h or not h.Parent then return nil;end;return h;end
		tbl3.safehum = function()local l= tbl3 .safechar();if not l then return nil;end;return l:FindFirstChildOfClass("Humanoid");end
		tbl3.isalive = function()local l= tbl3 .safechar();if not l or not  alive then return false;end;return l.Parent== alive ;end
		local dataPing = serverStatsItem and serverStatsItem:FindFirstChild("Data Ping")
		tbl3.getping = function()if not  dataPing then return 50;end;local l= clock ();if  tbl3 .pingval and l- tbl3 .pingat<0.25 then return  tbl3 .pingval;end; tbl3 .pingval= dataPing .GetValue( dataPing )or 50; tbl3 .pingat=l;return  tbl3 .pingval;end
		tbl3.scanreal = function(h,l)if not h then return;end;for K,K in ipairs(h:GetChildren())do if K:GetAttribute("realBall")then if K:IsA("BasePart")then K.CanCollide=false;end;l[#l+1]=K;elseif K:IsA("Model")and(K:FindFirstChild("CollisionWhitelist"))then l[#l+1]=K;end;end;end
		tbl3.ballbuf = {}
		tbl3.ballframe = -1
		tbl3.ballList = function()if  tbl3 .ballframe== tbl3 .frame then return  tbl3 .ballbuf;end; tbl3 .ballframe= tbl3 .frame;local l= tbl3 .ballbuf;table.clear(l);if  alive and( alive :FindFirstChild(tostring( localPlayer )))then  tbl3 .scanreal( Workspace :FindFirstChild("Balls"),l);end; tbl3 .scanreal( Workspace :FindFirstChild("TrainingBalls"),l);if#l==0 then  tbl3 .scanreal( Workspace :FindFirstChild("Balls"),l);end;return l;end
		tbl3.ballPos = function(h)if not h then return nil;end;if h:IsA("BasePart")then return h.Position;end;local l=h:FindFirstChild("Body");if l and(l:IsA("BasePart"))then return l.Position;end;return h:GetPivot().Position;end
		tbl3.ballVel = function(h)if not h then return(Vector3.new(0.0,0.0,0.0));end;local l=h:FindFirstChild("zoomies");if l then return l.VectorVelocity;end;l=h:GetAttribute("Velocity");if typeof(l)=="Vector3"then return l;end;l=h:FindFirstChild("Body");if l and(l:IsA("BasePart"))then return l.AssemblyLinearVelocity;end;if h:IsA("BasePart")then return h.AssemblyLinearVelocity;end;return(Vector3.new(0.0,0.0,0.0));end
		tbl3.bauth = setmetatable({}, { __mode = "k" })
		tbl3.frameSmooth = 0.016666666666666666
		tbl3.bind(RunService.RenderStepped:Connect(function(l)local K= clamp ( min (l,0.016666666666666666),0.001,0.1); tbl3 .frameSmooth= tbl3 .frameSmooth+(K- tbl3 .frameSmooth)*0.1;end))
		tbl3.findballrem = function()return  tbl8 .byname("ReplicateBallPosition");end

		tbl3.startpred = function()
			if tbl3.predon then
				return
			end
			local v3 = tbl3.findballrem()

			if not v3 then
				tbl3.predtry = (tbl3.predtry or 0) + 1

				if tbl3.predtry <= 20 then
					tbl3.bindt(task.delay(1, tbl3.startpred))
				end

				return
			end

			tbl3.predon = true
			tbl3.bind(v3.OnClientEvent:Connect(function(l,K)if typeof(l)~="Instance"or typeof(K)~="Vector3"then return;end;local p= tbl3 .bauth[l];if p then p.pos=K;p.at= clock ();else  tbl3 .bauth[l]={pos=K,at= clock ()};end;end))
		end

		tbl3.apos = function(l)local K=l and  tbl3 .bauth[l];if not K then return  tbl3 .ballPos(l);end;local p= clock ()-K.at;if p>0.35 then return  tbl3 .ballPos(l);end;return K.pos+ tbl3 .ballVel(l)*p;end
		tbl3.ballTarget = function(h)if not h then return nil;end;local l=h:FindFirstChild("CollisionWhitelist");if l and(l:IsA("ObjectValue"))then local K=l.Value;return K and K.Name or nil;end;l=h:GetAttribute("target");if type(l)=="string"and l~=""then return l;end;return nil;end
		tbl3.ballLive = function(h)return h~=nil and(h:FindFirstChild("zoomies")~=nil or h:FindFirstChild("CollisionWhitelist")~=nil);end
		tbl3.validtgt = function(l)if not l or l== localPlayer .Character then return false;end;if l:GetAttribute("Dead")then return false;end;if l:GetAttribute("Invisible")then return false;end;if l:GetAttribute("DoNotTarget")then return false;end;if l:GetAttribute("IsDoppelganger")then return false;end;if l:GetAttribute("SingularityInOrbit")then return false;end;return true;end
		tbl3.ballstate = setmetatable({}, { __mode = "k" })
		tbl3.pickframe = -1
		tbl3.getball = function()if  tbl3 .pickframe== tbl3 .frame then return  tbl3 .pickball;end; tbl3 .pickframe= tbl3 .frame; tbl3 .pickball= tbl3 .rankBalls();return  tbl3 .pickball;end
		tbl3.rankBalls = function()local l= tbl3 .ballList();if#l==0 then return nil;end;if#l==1 then return l[1];end;local K= localPlayer .Character;local p=K and K.PrimaryPart;if not p then return l[1];end;local E= localPlayer .Name;local k=-1;local a,d= huge ;for I,C in ipairs(l)do I= tbl3 .ballPos(C);if I then K= tbl3 .ballstate[C];local U,J,G=if  tbl3 .ballTarget(C)==E then K and K.parried and 1 or 2 else 0,(I-p.Position).Magnitude, tbl3 .ballVel(C);local h,K=G.Magnitude;if h>1 then K=J/h;K=if G.Unit:Dot((p.Position-I).Unit)<=0 then K+10 else K;else K=J;end;if U>k or U==k and K<a then k,a,d=U,K,C;end;end;end;return d or l[1];end

		tbl9 = {
			ballstate = tbl3.ballstate,
			parries = 0,
			parried = false,
			lastparry = 0,
			grabcd = 0.35,
			lastgrab = 0,
			infball = false,
			staffconn = nil,
			aero = setmetatable({}, { __mode = "k" }),
			curve = { curving = tick(), lerprad = 0, lastwarp = tick() },
			vzpart = nil,
			hl = nil,
			mswidget = nil,
			msactive = false,
			asconn = nil,
			msconn = nil,
			abilconn = nil,
			abilball = nil,
			swords = nil,
			swmod = nil,
			swfn = nil,
			swbind = nil,
			noacc = false,
			swctrl = nil,
			swtried = nil,
			swbad = {},
			nocdsave = nil,
			skinstarted = false,
			slashhooked = false,
			slashorig = nil,
			slashoff = {},
			slashtask = nil,
			fxmod = nil,
			fxwarm = {},
			broken = {},
			afkthread = nil,
			phactive = false,
			phconn = nil,
			vipset = false,
			shadefx = nil,
			rainfx = nil,
			rainconn = nil,
			musicsound = nil,
		}

		tbl10 = {
			autoparry = false,
			trigger = false,
			crv = "Camera",
			acc = 100,
			rng = 0,
			autospam = false,
			manspam = false,
			mansui = false,
			norender = nil,
			keyparry = false,
			animfix = true,
			autoabil = false,
			cdprot = false,
			thundernocd = false,
			abilspd = 250,
			emoteonly = false,
			swskin = false,
			swname = "",
			autoload = false,
			forceemo = false,
			emospam = false,
			emospd = 5,
			emospawn = false,
			bt = false,
			btstart = Color3.fromRGB(255, 85, 85),
			btend = Color3.fromRGB(85, 85, 255),
			btrb = false,
			btpart = false,
			btglow = false,
			btlife = 0.1,
			btwidth = 1.4,
			pt = false,
			ptcol = Color3.fromRGB(125, 85, 255),
			ptrb = false,
			ptlife = 0.1,
			ptwidth = 0.1,
			viz = false,
			vizcol = Color3.fromRGB(125, 85, 255),
			staff = true,
			staffdo = "Notification",
			antiafk = true,
			autoexec = false,
			viptag = false,
			devtype = "Off",
			devscreen = "Off",
			shaders = false,
			shaderpreset = "Cinematic",
			dof = false,
			bloom = 1,
			saturation = 1,
			brightness = 0,
			contrast = 0,
			rain = false,
			rainrate = 150,
			music = false,
			track = "Dark Synth",
			vol = 3,
			musicid = "",
			fpscap = false,
			fpsval = 60,
		}

		color = Color3.fromRGB(4, 38, 62)
		accent = tbl3.accent
		color2 = Color3.fromRGB(237, 232, 220)
		color3 = Color3.fromRGB(107, 122, 153)
		tbl3.notifq = {}
		tbl3.notifkeys = {["Auto Parry"]="autoparrykey",["Trigger Bot"]="triggerbotkey",["Humanizer"]="humanizerkey",["Auto Spam"]="autospamkey",["Manual Spam"]="manualspamkey",["Auto Ability"]="autoabilitykey",["Unlock All"]="unlockallkey",["Music"]="musickey"}
		tbl3.notif = function(l,K,p)local nk= tbl3 .notifkeys[l];local nb=nk and options["notif_"..nk];if nb and nb.Value==false then return;end;local E= tbl3 .notifq;E[#E+1]={l,K,p or 3};end
		tbl3.bind(RunService.Heartbeat:Connect(function()if# tbl3 .notifq==0 then return;end;local l= tbl3 .notifq; tbl3 .notifq={};for K,K in ipairs(l)do  v .Notify( v ,{Title=K[1],Description=K[2],Time=K[3]});end;end))

		tbl3.chkfeat = function()
			tbl9.broken = {}
			local remotes = ReplicatedStorage:FindFirstChild("Remotes")
			remotes = remotes and remotes:FindFirstChild("AbilityButtonPress")

			if not (remotes and remotes:IsA("BindableEvent")) then
				tbl9.broken.abil = "This server didn't load the ability button. Rejoin and try again."
			end
		end

		tbl3.featguard = function(arg, arg2)
			local v3 = tbl9.broken[arg]

			if v3 then
				tbl3.chkfeat()
				v3 = tbl9.broken[arg]
			end

			if v3 then
				tbl3.notif(arg2, tostring(v3), 4)
				return false
			end
			return true
		end

		tbl3.corner = function(h,l)local K=Instance.new("UICorner",h);K.CornerRadius=UDim.new(0,l);return K;end

		tbl3.stroke = function(arg, color4, thickness, transparency)
			local uiStroke = Instance.new("UIStroke", arg)
			uiStroke.Color = color4
			uiStroke.Thickness = thickness or 1
			uiStroke.Transparency = transparency or 0
			return uiStroke
		end

		tbl3.dragify = function(arg, arg2)
			local flag2 = nil
			local position = nil
			local position2 = nil
			arg.InputBegan:Connect(function(l)if l.UserInputType==Enum.UserInputType.MouseButton1 or l.UserInputType==Enum.UserInputType.Touch then  flag2 =true; position =l.Position; position2 = arg2 .Position;l.Changed:Connect(function()local K,p=l.UserInputState,Enum.UserInputState.End;if K==p then  flag2 =false;end;end);end;end)
			arg.InputChanged:Connect(function(l)if  flag2 and(l.UserInputType==Enum.UserInputType.MouseMovement or l.UserInputType==Enum.UserInputType.Touch)then local K=l.Position- position ; arg2 .Position=UDim2.new( position2 .X.Scale, position2 .X.Offset+K.X, position2 .Y.Scale, position2 .Y.Offset+K.Y);end;end)
		end

		tbl3.accbase = function()return 0.55+( tbl10 .acc-1)*0.004545454545454545;end
		tbl3.parryWindow = function(l)local K=(2.4+ min ( max (l-9.5,0),5000)*0.002)* tbl3 .accbase();if K<=0 then return  huge ;end;local p= min ( tbl3 .frameSmooth*1.5,0.03);local pg= tbl3 .getping();return  min ( clamp (pg/10,10,16),pg/1000*l+1.5)+ max (l/K, min (9.5,l*0.15))+ tbl10 .rng+l*p;end
		local tbl12 = { g = nil, rows = {}, c = nil, pk = 0, acc = 0, you = nil, spd = nil, ttl = nil }
		local function fn7(h)if h<80 then return Color3.fromRGB(120,230,140);elseif h<150 then return Color3.fromRGB(245,215,110);end;return Color3.fromRGB(245,110,90);end

		local function fn8()
			if tbl12.c then
				tbl12.c:Disconnect()
				tbl12.c = nil
			end

			if tbl12.g then
				tbl12.g:Destroy()
				tbl12.g = nil
			end

			tbl12.rows = {}
			tbl12.pk = 0
			tbl12.acc = 0
			tbl12.last = nil
			tbl12.fps = 0
			tbl12.fa = 0
			tbl12.fn = 0
		end

		local function createTextLabel(parent, text)
			local frame = Instance.new("Frame")
			frame.Size = UDim2.new(1, 0, 0, 19)
			frame.BackgroundTransparency = 1
			frame.Parent = parent
			local textLabel = Instance.new("TextLabel")
			textLabel.Size = UDim2.new(0.5, 0, 1, 0)
			textLabel.BackgroundTransparency = 1
			textLabel.Font = Enum.Font.Gotham
			textLabel.TextSize = 12
			textLabel.TextXAlignment = Enum.TextXAlignment.Left
			textLabel.TextColor3 = color3
			textLabel.Text = text
			textLabel.Parent = frame
			local textLabel2 = Instance.new("TextLabel")
			textLabel2.Size = UDim2.new(0.5, 0, 1, 0)
			textLabel2.Position = UDim2.fromScale(0.5, 0)
			textLabel2.BackgroundTransparency = 1
			textLabel2.Font = Enum.Font.GothamBold
			textLabel2.TextSize = 13
			textLabel2.TextXAlignment = Enum.TextXAlignment.Right
			textLabel2.TextColor3 = color2
			textLabel2.Text = "-"
			textLabel2.Parent = frame
			return textLabel2
		end

		local function createFrame(parent, arg)
			local imageLabel = Instance.new("ImageLabel")
			imageLabel.Name = "shadow"
			imageLabel.BackgroundTransparency = 1
			imageLabel.Image = "rbxassetid://6014261993"
			imageLabel.ImageColor3 = Color3.fromRGB(0, 0, 0)
			imageLabel.ImageTransparency = 0.45
			imageLabel.ScaleType = Enum.ScaleType.Slice
			imageLabel.SliceCenter = Rect.new(49, 49, 450, 450)
			imageLabel.ZIndex = 0
			imageLabel.Parent = parent
			local frame = Instance.new("Frame")
			frame.AnchorPoint = Vector2.new(0, 0.5)
			frame.Position = UDim2.new(0, 18, 0.42, 0)
			frame.Size = UDim2.fromOffset(arg, 0)
			frame.AutomaticSize = Enum.AutomaticSize.Y
			frame.BackgroundColor3 = color
			frame.BackgroundTransparency = 0.04
			frame.BorderSizePixel = 0
			frame.ZIndex = 1
			frame.Parent = parent
			tbl3.corner(frame, 14)
			local uiGradient = Instance.new("UIGradient")
			uiGradient.Rotation = 90
			local color4 = Color3.fromRGB
			uiGradient.Color = ColorSequence.new(Color3.fromRGB(12, 52, 82), color4(3, 26, 44))
			uiGradient.Parent = frame
			tbl3.stroke(frame, Color3.fromRGB(255, 255, 255), 1, 0.9)

			local function fn9()
				imageLabel.Size = UDim2.fromOffset(frame.AbsoluteSize.X + 34, frame.AbsoluteSize.Y + 34)
				imageLabel.Position = UDim2.fromOffset(frame.AbsolutePosition.X - 17, frame.AbsolutePosition.Y - 17)
			end

			frame:GetPropertyChangedSignal("AbsoluteSize"):Connect(fn9)
			frame:GetPropertyChangedSignal("AbsolutePosition"):Connect(fn9)
			task.defer(fn9)
			return frame
		end

		local function fn9()
			local screenGui = Instance.new("ScreenGui")
			screenGui.Name = "\0_bh"
			screenGui.ResetOnSpawn = false
			screenGui.IgnoreGuiInset = true
			screenGui.DisplayOrder = 60
			screenGui.Parent = v.ScreenGui or fn6 and fn6() or CoreGui
			tbl12.g = screenGui
			local v3 = createFrame(screenGui, 180)
			local uiPadding = Instance.new("UIPadding")
			uiPadding.PaddingTop = UDim.new(0, 11)
			uiPadding.PaddingBottom = UDim.new(0, 11)
			uiPadding.PaddingLeft = UDim.new(0, 13)
			uiPadding.PaddingRight = UDim.new(0, 13)
			uiPadding.Parent = v3
			local uiListLayout = Instance.new("UIListLayout")
			uiListLayout.Padding = UDim.new(0, 3)
			uiListLayout.SortOrder = Enum.SortOrder.LayoutOrder
			uiListLayout.Parent = v3
			local frame = Instance.new("Frame")
			frame.Size = UDim2.new(1, 0, 0, 20)
			frame.BackgroundTransparency = 1
			frame.Parent = v3
			local frame2 = Instance.new("Frame")
			frame2.AnchorPoint = Vector2.new(0, 0.5)
			frame2.Position = UDim2.new(0, 0, 0.5, 0)
			frame2.Size = UDim2.fromOffset(8, 8)
			frame2.BackgroundColor3 = accent
			frame2.BorderSizePixel = 0
			frame2.Parent = frame
			tbl3.corner(frame2, 999)
			tbl12.you = frame2
			local textLabel = Instance.new("TextLabel")
			textLabel.Size = UDim2.new(1, -16, 1, 0)
			textLabel.Position = UDim2.fromOffset(16, 0)
			textLabel.BackgroundTransparency = 1
			textLabel.Font = Enum.Font.GothamBold
			textLabel.TextSize = 13
			textLabel.TextXAlignment = Enum.TextXAlignment.Left
			textLabel.TextColor3 = color2
			textLabel.Text = "BALL"
			textLabel.Parent = frame
			tbl12.ttl = textLabel
			local textLabel2 = Instance.new("TextLabel")
			textLabel2.AnchorPoint = Vector2.new(1, 0.5)
			textLabel2.Position = UDim2.new(1, 0, 0.5, 0)
			textLabel2.Size = UDim2.fromOffset(16, 16)
			textLabel2.BackgroundTransparency = 1
			textLabel2.Font = Enum.Font.GothamBold
			textLabel2.TextSize = 15
			textLabel2.TextColor3 = accent
			textLabel2.Text = "▲"
			textLabel2.Parent = frame
			tbl12.arrow = textLabel2
			local frame3 = Instance.new("Frame")
			frame3.Size = UDim2.new(1, 0, 0, 1)
			frame3.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
			frame3.BackgroundTransparency = 0.88
			frame3.BorderSizePixel = 0
			frame3.Parent = v3
			tbl12.spd = createTextLabel(v3, "Speed")
			tbl12.rows.tgt = createTextLabel(v3, "Target")
			tbl12.rows.eta = createTextLabel(v3, "ETA")
			tbl12.rows.dist = createTextLabel(v3, "Distance")
			tbl12.rows.win = createTextLabel(v3, "Window")
			tbl12.rows.peak = createTextLabel(v3, "Peak")
			tbl12.rows.net = createTextLabel(v3, "Ping / FPS")
			local frame4 = Instance.new("Frame")
			frame4.Size = UDim2.new(1, 0, 0, 3)
			frame4.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
			frame4.BackgroundTransparency = 0.9
			frame4.BorderSizePixel = 0
			frame4.Parent = v3
			local uiCorner = Instance.new("UICorner")
			uiCorner.CornerRadius = UDim.new(0, 2)
			uiCorner.Parent = frame4
			local frame5 = Instance.new("Frame")
			frame5.Size = UDim2.new(0, 0, 1, 0)
			frame5.BackgroundColor3 = accent
			frame5.BorderSizePixel = 0
			frame5.Parent = frame4
			local uiCorner2 = Instance.new("UICorner")
			uiCorner2.CornerRadius = UDim.new(0, 2)
			uiCorner2.Parent = frame5
			tbl12.bar = frame5
			tbl3.dragify(v3, v3)
		end

		local function fn10(l)if not(l and  alive )then return nil;end;local K= alive :FindFirstChild(l);l=K and K.PrimaryPart;return l and l.Position;end
		local function fn11()if not  tbl12 .g or not  tbl12 .g.Parent or not  tbl12 .rows.dist then return;end;local l= options .ballhudcolor and  options .ballhudcolor.Value or  accent ;local K= toggles .ballhuddyn and  toggles .ballhuddyn.Value; tbl12 .rows.dist.Parent.Visible=not  toggles .ballhuddist or  toggles .ballhuddist.Value; tbl12 .rows.peak.Parent.Visible=not  toggles .ballhudpeak or  toggles .ballhudpeak.Value;local p= tbl3 .getball();if not p then  tbl12 .spd.Text="-"; tbl12 .rows.tgt.Text="-"; tbl12 .rows.eta.Text="-"; tbl12 .rows.dist.Text="-"; tbl12 .you.BackgroundColor3= color3 ; tbl12 .ttl.Text="BALL"; tbl12 .ttl.TextColor3= color2 ; tbl12 .spd.TextColor3= color2 ;if  tbl12 .arrow then  tbl12 .arrow.Visible=false;end;return;end;if p~= tbl12 .last then  tbl12 .last=p; tbl12 .pk=0;end;local E,k,a= tbl3 .ballPos(p), tbl3 .ballVel(p).Magnitude, tbl3 .ballTarget(p);if k> tbl12 .pk then  tbl12 .pk=k;end;local d=a== localPlayer .Name; tbl12 .you.BackgroundColor3=d and(Color3.fromRGB(245,70,70))or l; tbl12 .ttl.Text=d and"BALL \194\183 YOU"or"BALL"; tbl12 .ttl.TextColor3=d and(Color3.fromRGB(245,110,90))or  color2 ; tbl12 .spd.Text= format ("%.0f",k); tbl12 .spd.TextColor3=K and( fn7 (k))or l; tbl12 .rows.tgt.Text=a and a~=""and(tostring(a))or"-";K= localPlayer .Character;local I=K and K.PrimaryPart;local C,U=I and E and(I.Position-E).Magnitude or nil, tbl3 .getping();K= min ( tbl3 .parryWindow(k),999);if d then local J,G= tbl3 .closingSpeed(p); tbl12 .rows.eta.Text=J>0 and G< huge and( format ("%.0fms",G*1000))or"away"; tbl12 .rows.eta.TextColor3=J>0 and  color2 or  color3 ;else I= fn10 (a); tbl12 .rows.eta.Text=I and E and k>1 and( format ("%.0fms",(I-E).Magnitude/k*1000))or"-"; tbl12 .rows.eta.TextColor3= color3 ;end; tbl12 .rows.dist.Text=C and( format ("%.0f",C))or"-"; tbl12 .rows.win.Text= format ("%.0f",K); tbl12 .rows.win.TextColor3=C and C<=K and(Color3.fromRGB(120,230,140))or  color3 ; tbl12 .rows.peak.Text= format ("%.0f", tbl12 .pk); tbl12 .rows.net.Text= format ("%.0f / %.0f",U, tbl12 .fps or 0);if  tbl12 .bar then U=C and K>0 and( clamp (1-C/(K*3),0,1))or 0; tbl12 .bar.Size=UDim2.new(U,0,1,0); tbl12 .bar.BackgroundColor3=C and C<=K and(Color3.fromRGB(120,230,140))or l;end;if  tbl12 .arrow and E then I,a,U= currentCamera .ViewportSize, currentCamera :WorldToViewportPoint(E);local p=a.X-I.X*0.5;local E=a.Y-I.Y*0.5;K=U and( max ( abs (p)/(I.X*0.5), abs (E)/(I.Y*0.5)))or 1; tbl12 .arrow.Visible=K>0.55;if not U then p,E=-p,-E;end; tbl12 .arrow.Rotation= deg (math.atan2(E,p))+90; tbl12 .arrow.TextColor3=d and(Color3.fromRGB(245,70,70))or l;end;end

		local function fn12()
			fn8()
			fn9()
			tbl12.c = tbl3.bind(RunService.RenderStepped:Connect(function(l) tbl12 .fn=( tbl12 .fn or 0)+1; tbl12 .fa=( tbl12 .fa or 0)+l;if  tbl12 .fa>=0.25 then  tbl12 .fps= tbl12 .fn/ tbl12 .fa; tbl12 .fn=0; tbl12 .fa=0;end; tbl12 .acc= tbl12 .acc+l;if  tbl12 .acc<0.06 then return;end; tbl12 .acc=0; fn11 ();end))
		end

		toggles.ballhud:OnChanged(function(arg)
			if arg then
				fn12()
			else
				fn8()
			end
		end)

		local function fn13()
			local v3 = tbl3.safehum()

			if v3 then
				v3.WalkSpeed = toggles.spdon.Value and (options.spdval.Value or 32) or 32
			end
		end

		local function fn14()
			local v3 = tbl3.safehum()

			if v3 then
				v3.UseJumpPower = true
				v3.JumpPower = toggles.jmpon.Value and (options.jmpval.Value or 50) or 50
			end
		end

		toggles.spdon:OnChanged(fn13)

		options.spdval:OnChanged(function()
			if toggles.spdon.Value then
				fn13()
			end
		end)

		toggles.jmpon:OnChanged(fn14)

		options.jmpval:OnChanged(function()
			if toggles.jmpon.Value then
				fn14()
			end
		end)

		local function fn15(arg)
			local humanoid = arg and arg:FindFirstChildOfClass("Humanoid")
			if not humanoid then
				return
			end

			tbl3.bind(humanoid:GetPropertyChangedSignal("WalkSpeed"):Connect(function()
				local value = toggles.spdon.Value

				if value then
					value = abs(humanoid.WalkSpeed - (options.spdval.Value or 32)) > 0.5
				end

				if value then
					fn13()
				end
			end))

			tbl3.bind(humanoid:GetPropertyChangedSignal("JumpPower"):Connect(function()
				local value = toggles.jmpon.Value

				if value then
					value = abs(humanoid.JumpPower - (options.jmpval.Value or 50)) > 0.5
				end

				if value then
					fn14()
				end
			end))
		end

		tbl3.bind(localPlayer.CharacterAdded:Connect(function(character)
			task.wait(0.4)

			if toggles.spdon.Value then
				fn13()
			end

			if toggles.jmpon.Value then
				fn14()
			end

			fn15(character)
		end))

		if localPlayer.Character then
			fn15(localPlayer.Character)
		end

		tbl3.bindt(task.spawn(function()
			while true do
				task.wait(0.35)

				if toggles.spdon.Value then
					local flag2 = tbl3.safehum()

					if flag2 then
						flag2 = abs(flag2.WalkSpeed - (options.spdval.Value or 32)) > 0.5
					end

					if flag2 then
						fn13()
					end
				end
			end
		end))

		tbl3.bind(UserInputService.JumpRequest:Connect(function()
			if toggles.infjump and toggles.infjump.Value then
				local v3 = tbl3.safehum()

				if v3 then
					v3:ChangeState(Enum.HumanoidStateType.Jumping)
				end
			end
		end))

		tbl3.inlobby = function()local l= tbl3 .safechar();if not l or not  dead or l.Parent~= dead then return false;end;return( localPlayer :GetAttribute("LobbyTraining")or( localPlayer :GetAttribute("LobbyParry")))and true or false;end
		local obj = setmetatable({}, { __mode = "k" })
		local tbl14 = {}

		local function applycos()
			local v4 = tbl3.safechar()
			if not v4 then
				return
			end

			if tbl3.applyheadless then
				tbl3.applyheadless()
			end

			if toggles.korblox.Value then
				local humanoid = v4:FindFirstChildOfClass("Humanoid")

				if humanoid and humanoid.RigType == Enum.HumanoidRigType.R15 then
					local rightUpperLeg = v4:FindFirstChild("RightUpperLeg")

					if rightUpperLeg and rightUpperLeg:IsA("MeshPart") then
						if not obj[rightUpperLeg] then
							obj[rightUpperLeg] = { mesh = rightUpperLeg.MeshId, tex = rightUpperLeg.TextureID, tr = rightUpperLeg.Transparency }
						end

						rightUpperLeg.MeshId = "rbxassetid://902942096"
						rightUpperLeg.TextureID = "rbxassetid://902843398"
					end

					for _, v5 in ipairs({ "RightLowerLeg", "RightFoot" }) do
						local v6 = v4:FindFirstChild(v5)

						if v6 then
							if not obj[v6] then
								obj[v6] = { tr = v6.Transparency }
							end

							v6.Transparency = 1
						end
					end
				else
					local rightLeg = v4:FindFirstChild("Right Leg")

					if rightLeg and not rightLeg:FindFirstChild("KorbloxMesh") then
						for _, child in ipairs(rightLeg:GetChildren()) do
							if child:IsA("SpecialMesh") then
								tbl14[#tbl14 + 1] = {
									nm = child.Name,
									mesh = child.MeshId,
									tex = child.TextureId,
									off = child.Offset,
									sc = child.Scale,
									mt = child.MeshType,
								}

								child:Destroy()
							end
						end

						local specialMesh = Instance.new("SpecialMesh")
						specialMesh.Name = "KorbloxMesh"
						specialMesh.MeshId = "rbxassetid://902942096"
						specialMesh.TextureId = "rbxassetid://902843398"
						specialMesh.Offset = Vector3.new(0, 0.7, 0)
						specialMesh.Parent = rightLeg
					end
				end
			end
		end

		local function fn18()
			for k, v4 in pairs(obj) do
				if k.Parent then
					if v4.mesh then
						k.MeshId = v4.mesh
					end

					if v4.tex then
						k.TextureID = v4.tex
					end

					if v4.tr then
						k.Transparency = v4.tr
					end
				end

				obj[k] = nil
			end

			local v4 = tbl3.safechar()
			if not v4 then
				return
			end
			local rightLeg = v4:FindFirstChild("Right Leg")
			if not rightLeg then
				return
			end
			local korbloxMesh = rightLeg:FindFirstChild("KorbloxMesh")

			if korbloxMesh then
				korbloxMesh:Destroy()
			end

			for _, v5 in ipairs(tbl14) do
				local specialMesh = Instance.new("SpecialMesh")
				specialMesh.Name = v5.nm
				specialMesh.MeshType = v5.mt
				specialMesh.MeshId = v5.mesh
				specialMesh.TextureId = v5.tex
				specialMesh.Offset = v5.off
				specialMesh.Scale = v5.sc
				specialMesh.Parent = rightLeg
			end

			table.clear(tbl14)
		end

		tbl3.applycos = applycos

		tbl3.restorecos = function()
			if tbl3.avatardestroy then pcall(tbl3.avatardestroy) end
			if tbl3.restoreheadless then tbl3.restoreheadless() end
			fn18()
		end

		do
		local hl = {}
		local function hlRestore()
			if hl.head then
				pcall(function() hl.head.Transparency = hl.headTr end)
			end
			if hl.face then
				pcall(function() hl.face.Transparency = hl.faceTr end)
			end
			hl = {}
		end
		local function hlApply(char)
			local head = char and char:FindFirstChild("Head")
			if not head then return end
			local face = head:FindFirstChild("face") or head:FindFirstChildOfClass("Decal")
			if hl.head ~= head then
				hlRestore()
				hl = { head = head, headTr = head.Transparency }
			end
			if hl.face ~= face then
				if hl.face then pcall(function() hl.face.Transparency = hl.faceTr end) end
				hl.face = face
				hl.faceTr = face and face.Transparency or 0
			end
			head.Transparency = 1
			if face then face.Transparency = 1 end
		end
		tbl3.applyheadless = function()
			if toggles.headless and toggles.headless.Value then
				hlApply(tbl3.safechar())
			end
		end
		tbl3.restoreheadless = hlRestore

		local am = { Sources = {}, UserIDs = {}, Clones = {}, BindRun = 0 }
		local avConn = {}
		local function dropConn(x, seen)
			seen = seen or {}
			if typeof(x) == "RBXScriptConnection" then
				x:Disconnect()
			elseif type(x) == "table" and not seen[x] then
				seen[x] = true
				for _, v in pairs(x) do dropConn(v, seen) end
			end
		end
		local function avOn() return toggles.avatarchanger and toggles.avatarchanger.Value end
		local function avUser()
			return string.match(tostring(options.avataruser and options.avataruser.Value or ""), "^%s*(.-)%s*$")
		end
		local function afterAvatar()
			if tbl3.applycos then tbl3.applycos() end
		end

		local cache = ReplicatedStorage:FindFirstChild("flyteavatarcache1")
		if cache then cache:Destroy() end
		local dummyPart = Instance.new("Folder")
		dummyPart.Name = "flyteavatarcache1"
		dummyPart.Parent = ReplicatedStorage
		local stash = Instance.new("Folder")
		stash.Name = "Original"
		stash.Parent = dummyPart
		am.SourceFolder = dummyPart
		am.Stash = stash

		local curId, curName, track, store = nil, nil, 0, nil

		am.BindImage = function(img, nameLabel)
			if not am.Images or not img or not nameLabel or am.Images[img] then return end
			local rec = { Original = img.Image, Username = nameLabel }
			am.Images[img] = rec
			rec.Update = function()
				local cur = img.Image
				if cur ~= rec.Applied then rec.Original = cur end
				if nameLabel.Text ~= "@" .. localPlayer.Name or rec.Original:match("^rbxthumb://type=AvatarHeadShot&id=(%d+)&") ~= tostring(localPlayer.UserId) or not curId then
					rec.Applied = nil
					return
				end
				rec.Applied = rec.Original:gsub("&id=%d+&", "&id=" .. curId .. "&", 1)
				if cur ~= rec.Applied then img.Image = rec.Applied end
			end
			rec.ImageChanged = img:GetPropertyChangedSignal("Image"):Connect(rec.Update)
			rec.UserChanged = nameLabel:GetPropertyChangedSignal("Text"):Connect(rec.Update)
			rec.Destroying = img.Destroying:Connect(function()
				dropConn(rec)
				if am.Images then am.Images[img] = nil end
			end)
			rec.Update()
		end

		am.UpdateImages = function()
			if am.Images then
				for _, rec in pairs(am.Images) do rec.Update() end
				return
			end
			am.Images = {}
			local function scan(obj)
				local par = obj and obj.Parent
				if not par then return end
				if obj.Name == "AvatarImage" and par.Name == "PlayerHeader" then
					am.BindImage(obj, par:FindFirstChild("PlayerName", true))
				elseif obj.Name == "PlayerName" then
					local ph = obj:FindFirstAncestor("PlayerHeader")
					if ph then am.BindImage(ph:FindFirstChild("AvatarImage"), obj) end
				elseif obj.Name == "Player" and par.Name == "PlayerProfile" then
					local d = par:FindFirstChild("Details")
					am.BindImage(obj, d and d:FindFirstChild("Username"))
				elseif obj.Name == "Username" and par.Name == "Details" and par.Parent and par.Parent.Name == "PlayerProfile" then
					am.BindImage(par.Parent:FindFirstChild("Player"), obj)
				end
			end
			local imgs = am.Images
			local function onAdded(obj)
				local n = obj.Name
				if n == "AvatarImage" or n == "PlayerName" or n == "Player" or n == "Username" then
					task.defer(function()
						if am.Images == imgs then pcall(scan, obj) end
					end)
				end
			end
			local pg = localPlayer:FindFirstChildOfClass("PlayerGui")
			local list = {}
			if pg then list[#list + 1] = pg.DescendantAdded:Connect(onAdded) end
			avConn["Avatar Images"] = list
			pcall(function()
				list[#list + 1] = CoreGui.DescendantAdded:Connect(onAdded)
				local ph = CoreGui:FindFirstChild("PlayerHeader", true)
				if ph then scan(ph:FindFirstChild("AvatarImage")) end
			end)
			local card = pg and pg:FindFirstChild("ProfileCard")
			card = card and card:FindFirstChild("PlayerProfile", true)
			if card then scan(card:FindFirstChild("Player")) end
		end

		am.RestoreImages = function()
			dropConn(avConn["Avatar Images"]); avConn["Avatar Images"] = nil
			local imgs = am.Images
			am.Images = nil
			for img, rec in pairs(imgs or {}) do
				dropConn(rec)
				pcall(function()
					if rec.Applied and img.Image == rec.Applied and rec.Username.Text == "@" .. localPlayer.Name then
						img.Image = rec.Original
					end
				end)
			end
		end

		am.IsBody = function(o)
			return o:IsA("Shirt") or o:IsA("Pants") or o:IsA("ShirtGraphic") or o:IsA("BodyColors") or o:IsA("CharacterMesh") or o:IsA("Accoutrement")
		end
		am.IsHead = function(o) return o:IsA("Decal") or o:IsA("SpecialMesh") end
		am.Ready = function(c)
			return c and (c:GetAttribute("AppearanceLoaded") == true or (c == localPlayer.Character and localPlayer:HasAppearanceLoaded()))
		end
		am.Current = function(id, name)
			local ok = avOn() and id == track
			if ok then ok = name == avUser():lower() end
			return ok
		end

		am.GetUserID = function(text)
			local s = string.match(tostring(text or ""), "^%s*(.-)%s*$")
			if s == "" then return end
			local q = s:lower()
			if am.UserIDs[q] then return am.UserIDs[q] end
			local id = tonumber(s)
			if id then
				if id ~= id or id <= 0 or id == math.huge or id % 1 ~= 0 then return end
			else
				for _, p in Players:GetPlayers() do
					if p.Name:lower() == q or p.DisplayName:lower() == q then id = p.UserId break end
				end
				id = id or Players:GetUserIdFromNameAsync(s)
			end
			if id then am.UserIDs[q] = id end
			return id
		end

		am.GetSource = function(id)
			local src = am.Sources[id]
			if src and src.Parent == dummyPart then return src end
			local ok, desc = pcall(Players.GetHumanoidDescriptionFromUserIdAsync, Players, id)
			if not ok or not desc then return end
			local ok2, model = pcall(Players.CreateHumanoidModelFromDescriptionAsync, Players, desc, Enum.HumanoidRigType.R6)
			desc:Destroy()
			if not ok2 or not model then return end
			if not dummyPart.Parent then model:Destroy() return end
			for _, d in model:GetDescendants() do
				if d:IsA("LuaSourceContainer") then d:Destroy() end
			end
			model.Name = tostring(id)
			model.Parent = dummyPart
			am.Sources[id] = model
			return model
		end

		am.AddAccessory = function(char, acc)
			local parentModel = char
			local handle = acc:FindFirstChild("Handle")
			if not handle or not handle:IsA("BasePart") then acc:Destroy() return end
			local w = handle:FindFirstChild("AccessoryWeld")
			local part1, c0, c1
			if w and w:IsA("Weld") and w.Part1 then
				part1 = parentModel:FindFirstChild(w.Part1.Name)
				c0, c1 = w.C0, w.C1
			end
			local att = handle:FindFirstChildOfClass("Attachment")
			if not part1 and att then
				for _, p in parentModel:GetChildren() do
					if p:IsA("BasePart") then
						local a = p:FindFirstChild(att.Name)
						if a and a:IsA("Attachment") then
							c0, c1, part1 = att.CFrame, a.CFrame, p
							break
						end
					end
				end
			elseif not part1 then
				part1 = parentModel:FindFirstChild("Head")
				c0 = acc.AttachmentPoint
				c1 = CFrame.new(0, 0.5, 0)
			end
			if not part1 or not c0 or not c1 then acc:Destroy() return end
			for _, d in acc:GetDescendants() do
				if d:IsA("JointInstance") or d:IsA("WeldConstraint") then
					local bad = d.Name == "AccessoryWeld" or (d.Part0 and not d.Part0:IsDescendantOf(acc))
					if not bad then bad = d.Part1 and not d.Part1:IsDescendantOf(acc) end
					if bad then d:Destroy() end
				elseif d:IsA("BasePart") then
					d.Anchored = false
					d.CanCollide = false
					d.Massless = true
				end
			end
			local diff = part1.CFrame * c1 * c0:Inverse() * handle.CFrame:Inverse()
			for _, d in acc:GetDescendants() do
				if d:IsA("BasePart") then d.CFrame = diff * d.CFrame end
			end
			local m = Instance.new("Weld")
			m.Name = "AccessoryWeld"
			m.Part0 = handle
			m.Part1 = part1
			m.C0 = c0
			m.C1 = c1
			m.Parent = handle
			acc.Parent = parentModel
		end

		am.ClearAdded = function()
			if not store then return end
			for _, o in pairs(store.Added) do o:Destroy() end
			table.clear(store.Added)
		end

		am.DiscardAppearance = function()
			if not store then return end
			am.ClearAdded()
			for _, c in pairs(store.Visibility or {}) do c:Disconnect() end
			for _, e in pairs(store.Original) do e.Object:Destroy() end
			store = nil
		end

		am.UpdateVisibility = function(rec)
			if not rec or not rec.Transparency then return end
			local torso = rec.Character:FindFirstChild("Torso")
			if not torso then return end
			for obj, tr in pairs(rec.Transparency) do
				if obj.Parent then
					obj.Transparency = 1 - (1 - tr) * (1 - torso.Transparency)
					if obj:IsA("BasePart") then obj.LocalTransparencyModifier = torso.LocalTransparencyModifier end
				end
			end
		end

		am.StoreAppearance = function(char, rec)
			rec = rec or { Character = char, Original = {}, Added = {} }
			local torso = char:FindFirstChild("Torso")
			if torso and not rec.Visibility then
				local upd = function() am.UpdateVisibility(rec) end
				rec.Visibility = {
					torso:GetPropertyChangedSignal("Transparency"):Connect(upd),
					torso:GetPropertyChangedSignal("LocalTransparencyModifier"):Connect(upd),
				}
			end
			local snapshot = table.clone(rec.Original)
			local function stashObj(obj, parent)
				for k = #rec.Original, 1, -1 do
					local e = rec.Original[k]
					if table.find(snapshot, e) and e.Parent == parent and e.Object.ClassName == obj.ClassName
						and (not obj:IsA("Accoutrement") or e.Object.Name == obj.Name)
						and (not obj:IsA("CharacterMesh") or e.Object.BodyPart == obj.BodyPart) then
						e.Object:Destroy()
						table.remove(rec.Original, k)
					end
				end
				rec.Original[#rec.Original + 1] = { Object = obj, Parent = parent }
				obj.Parent = stash
			end
			for _, o in char:GetChildren() do
				if am.IsBody(o) then stashObj(o, char) end
			end
			local head = char:FindFirstChild("Head")
			if head then
				for _, o in head:GetChildren() do
					if am.IsHead(o) then stashObj(o, head) end
				end
			end
			return rec
		end

		am.CaptureAppearance = function(char)
			if store and store.Character == char then return store end
			am.DiscardAppearance()
			store = am.StoreAppearance(char)
			return store
		end

		am.CopyAppearance = function(src, char, hum, rec)
			rec = rec or store
			rec.Transparency = {}
			for _, o in src:GetChildren() do
				if am.IsBody(o) then
					local c = o:Clone()
					rec.Added[#rec.Added + 1] = c
					if c:IsA("Accoutrement") then
						for _, d in c:GetDescendants() do
							if d:IsA("BasePart") or d:IsA("Decal") then rec.Transparency[d] = d.Transparency end
						end
						am.AddAccessory(char, c)
					else
						c.Parent = char
					end
				end
			end
			local sHead, tHead = src:FindFirstChild("Head"), char:FindFirstChild("Head")
			if sHead and tHead then
				for _, o in sHead:GetChildren() do
					if am.IsHead(o) then
						local c = o:Clone()
						rec.Added[#rec.Added + 1] = c
						c.Parent = tHead
					end
				end
			end
			am.UpdateVisibility(rec)
		end

		am.RestoreAppearance = function(char)
			local rec = store
			if not rec then
				if char then char:SetAttribute("flytemarker1", nil) end
				return
			end
			if rec.Character ~= char then am.DiscardAppearance() return end
			am.ClearAdded()
			for _, c in pairs(rec.Visibility or {}) do c:Disconnect() end
			for _, e in pairs(rec.Original) do
				if e.Parent and e.Parent.Parent then e.Object.Parent = e.Parent else e.Object:Destroy() end
			end
			store = nil
			char:SetAttribute("flytemarker1", nil)
		end

		am.ApplySource = function(src, char, id)
			if not avOn() or localPlayer.Character ~= char or curId ~= id then return end
			local hum = char:FindFirstChildOfClass("Humanoid")
			if not hum or hum.RigType ~= Enum.HumanoidRigType.R6 then return end
			am.CaptureAppearance(char)
			am.ClearAdded()
			char:SetAttribute("flytemarker1", nil)
			if not pcall(am.CopyAppearance, src, char, hum) then
				am.RestoreAppearance(char)
				afterAvatar()
				return
			end
			char:SetAttribute("flytemarker1", id)
			am.UpdateImages()
			for c in pairs(am.Clones) do am.ApplyClone(c) end
			afterAvatar()
			if am.DelayedSearch == track then
				am.DelayedSearch = nil
				tbl3.notif("Avatar Changer", "Avatar loaded.", 3)
			end
			return true
		end

		am.Update = function(force)
			if not avOn() then return end
			local src = curId and am.Sources[curId]
			local stale = not src or src.Parent ~= dummyPart
			if not stale then stale = curName ~= avUser():lower() end
			if stale then
				if not am.PendingUser then task.spawn(am.Apply) end
				return
			end
			local char = localPlayer.Character
			if not am.Ready(char) then return end
			if not force and store and store.Character == char and char:GetAttribute("flytemarker1") == curId then return end
			am.ApplySource(src, char, curId)
		end

		am.Apply = function()
			if not avOn() then return end
			local text = avUser()
			if text == "" then return end
			local lower = text:lower()
			if am.PendingUser == lower then return end
			local cached = curId and am.Sources[curId]
			if not am.PendingUser and curName == lower and cached and cached.Parent == dummyPart then
				am.Update()
				return
			end
			track += 1
			local my = track
			am.PendingUser = lower
			am.DelayedSearch = nil
			task.delay(3, function()
				if am.PendingUser == lower and am.Current(my, lower) then
					am.DelayedSearch = my
					tbl3.notif("Avatar Changer", "Roblox is delaying the avatar request, hang on...", 4)
				end
			end)
			local uid
			for _ = 1, 3 do
				local ok
				ok, uid = pcall(am.GetUserID, text)
				if not (ok and uid) then
					uid = nil
					if am.Current(my, lower) then continue end
				end
				break
			end
			if not uid or not am.Current(my, lower) then
				if my == track then am.PendingUser = nil end
				return
			end
			local src
			while am.Current(my, lower) do
				local ok, m = pcall(am.GetSource, uid)
				src = ok and m or nil
				if not src and am.Current(my, lower) then task.wait(2) continue end
				break
			end
			if my == track then am.PendingUser = nil end
			if not src or not am.Current(my, lower) then return end
			curId, curName = uid, lower
			local char = localPlayer.Character
			if am.Ready(char) and am.Current(my, lower) then am.ApplySource(src, char, uid) end
		end

		am.Reconcile = function(char)
			if localPlayer.Character ~= char then return end
			char:SetAttribute("flytemarker1", nil)
			if avOn() then am.Update(true) end
		end

		am.ClearClone = function(model)
			local rec = am.Clones[model]
			if not rec then return end
			am.Clones[model] = nil
			for _, c in pairs(rec.Connections) do c:Disconnect() end
			if rec.Appearance then
				for _, c in pairs(rec.Appearance.Visibility or {}) do c:Disconnect() end
				for _, o in pairs(rec.Appearance.Added) do o:Destroy() end
				for _, e in pairs(rec.Appearance.Original) do
					if model.Parent and (e.Parent == model or e.Parent:IsDescendantOf(model)) then
						e.Object.Parent = e.Parent
					else
						e.Object:Destroy()
					end
				end
			end
		end

		am.ApplyClone = function(model, force)
			local rec = am.Clones[model]
			local src = curId and am.Sources[curId]
			local skip = not rec or not avOn() or not src or (not force and rec.ID == curId) or model:GetAttribute("IsEncryptedClone") ~= true
			if not skip then skip = model:GetAttribute("EncryptedCloneOwner") ~= localPlayer.Name end
			if skip then return end
			local hum = model:FindFirstChildOfClass("Humanoid")
			if not hum or hum.RigType ~= Enum.HumanoidRigType.R6 or not model:FindFirstChild("Head") then return end
			if rec.Appearance then
				for _, o in pairs(rec.Appearance.Added) do o:Destroy() end
				table.clear(rec.Appearance.Added)
			end
			rec.Appearance = am.StoreAppearance(model, rec.Appearance)
			rec.ID = curId
			if not pcall(am.CopyAppearance, src, model, hum, rec.Appearance) then am.ClearClone(model) end
		end

		am.WatchClone = function(model)
			if not avOn() or not model:IsA("Model") or model == localPlayer.Character or am.Clones[model] then return end
			local rec = { Connections = {} }
			am.Clones[model] = rec
			local function reapply() am.ApplyClone(model) end
			local function onChange()
				local busy = rec.Pending
				if not busy then busy = model:GetAttribute("EncryptedCloneOwner") ~= localPlayer.Name end
				if busy then return end
				rec.Pending = true
				task.defer(function()
					rec.Pending = false
					if am.Clones[model] == rec then am.ApplyClone(model, true) end
				end)
			end
			rec.Connections.Owner = model:GetAttributeChangedSignal("EncryptedCloneOwner"):Connect(reapply)
			rec.Connections.Clone = model:GetAttributeChangedSignal("IsEncryptedClone"):Connect(reapply)
			rec.Connections.Loaded = model.DescendantAdded:Connect(function(o)
				local direct = o.Parent == model
				local hit = direct and (am.IsBody(o) or o:IsA("Humanoid"))
				if hit or (o.Parent == model:FindFirstChild("Head") and am.IsHead(o)) then
					if not rec.Appearance or not table.find(rec.Appearance.Added, o) then onChange() end
				end
			end)
			local hum = model:FindFirstChildOfClass("Humanoid")
			if hum then rec.Connections.Description = hum.ApplyDescriptionFinished:Connect(onChange) end
			reapply()
		end

		am.Bind = function()
			dropConn(avConn.Avatar); avConn.Avatar = nil
			am.BindRun += 1
			local run = am.BindRun
			if not avOn() then return end
			local res = {}
			local function check(c)
				if run ~= am.BindRun or c ~= localPlayer.Character or not am.Ready(c) then return end
				if not store or store.Character ~= c or c:GetAttribute("flytemarker1") ~= curId then
					am.Reconcile(c)
				end
			end
			local function onChar(c)
				if res.Appearance then res.Appearance:Disconnect() end
				res.Appearance = c:GetAttributeChangedSignal("AppearanceLoaded"):Connect(function()
					if c:GetAttribute("AppearanceLoaded") == true then check(c) end
				end)
				check(c)
			end
			res.Character = localPlayer.CharacterAdded:Connect(onChar)
			res.Loaded = localPlayer.CharacterAppearanceLoaded:Connect(check)
			if alive then
				res.Alive = alive.ChildAdded:Connect(check)
				res.CloneAdded = alive.ChildAdded:Connect(am.WatchClone)
				res.CloneRemoved = alive.ChildRemoved:Connect(am.ClearClone)
				for _, m in alive:GetChildren() do am.WatchClone(m) end
			end
			avConn.Avatar = res
			if localPlayer.Character then onChar(localPlayer.Character) end
		end

		am.Toggle = function(on)
			track += 1
			am.PendingUser = nil
			if on then
				am.Bind()
				task.spawn(am.Apply)
				return
			end
			am.Bind()
			am.RestoreImages()
			for m in pairs(am.Clones) do am.ClearClone(m) end
			local char = localPlayer.Character
			if char then am.RestoreAppearance(char) else am.DiscardAppearance() end
			afterAvatar()
		end

		am.Destroy = function()
			track += 1
			am.PendingUser = nil
			am.BindRun += 1
			dropConn(avConn); avConn = {}
			am.RestoreImages()
			for m in pairs(am.Clones) do am.ClearClone(m) end
			local char = localPlayer.Character
			if char then am.RestoreAppearance(char) else am.DiscardAppearance() end
			table.clear(am.Sources)
			if dummyPart.Parent then dummyPart:Destroy() end
			hlRestore()
		end
		tbl3.avatardestroy = am.Destroy

		toggles.avatarchanger:OnChanged(function(arg) am.Toggle(arg) end)
		options.avataruser:OnChanged(function()
			if avOn() then task.spawn(am.Apply) end
		end)
		end

		toggles.headless:OnChanged(function(arg)
			if arg then
				applycos()
			else
				tbl3.restoreheadless()
			end
		end)

		toggles.korblox:OnChanged(function(arg)
			if arg then
				applycos()
			else
				fn18()
			end
		end)

		tbl3.bind(localPlayer.CharacterAppearanceLoaded:Connect(function()
			task.wait(0.2)
			applycos()
		end))

		tbl3.bind(localPlayer.CharacterAdded:Connect(function()
			task.wait(0.8)
			applycos()
		end))

		local tbl15 = { PC = "PC", Phone = "Mobile", Tablet = "Tablet", Console = "Console" }
		local tbl16 = { "PlayerProfileController", "AnalyticsController" }
		local v4 = nil
		local v5 = nil
		local value = nil
		local function_ = nil
		local v6 = nil
		local v7 = nil
		local v8 = nil

		local function fn19(arg)
			if type(arg) ~= "function" then
				return ""
			end
			local v9 = debug.info(arg, "s")
			return type(v9) == "string" and v9 or ""
		end

		local function fn20(arg)
			if type(arg) ~= "function" then
				return false
			end

			if not islclosure(arg) then
				return false
			end

			if fn19(arg):find("DeviceListener", 1, true) == nil then
				return false
			end
			local v9 = getupvalues(arg)
			if type(v9) ~= "table" then
				return false
			end
			local n2 = 0
			local flag2 = false
			local flag3 = false

			for _, v10 in pairs(v9) do
				n2 += 1

				if v10 == v4 then
					flag2 = true
				elseif type(v10) == "function" then
					flag3 = true
				end
			end

			return n2 == 2 and flag2 and flag3
		end

		local function fn21()
			if not v4 then
				local clientGameModules = ReplicatedStorage:FindFirstChild("ClientGameModules")
				clientGameModules = clientGameModules and clientGameModules:FindFirstChild("DeviceListener")
				if not clientGameModules then
					return false
				end
				local module = require(clientGameModules)
				if type(module) ~= "table" or rawget(module, "OnChange") == nil then
					return false
				end
				v4 = module
				local playerScripts = localPlayer:FindFirstChild("PlayerScripts")
				playerScripts = playerScripts and playerScripts:FindFirstChild("Client")
				playerScripts = playerScripts and playerScripts:FindFirstChild("DeviceChecker")

				if playerScripts then
					local module2 = require(playerScripts)

					if type(module2) == "table" and type(rawget(module2, "GetDeviceType")) == "function" then
						v5 = module2
						value = rawget(module2, "GetDeviceType")
					end
				end
			end

			if function_ then
				return true
			end

			if not getconnections then
				return false
			end

			for _, v9 in ipairs({ UserInputService.LastInputTypeChanged, currentCamera:GetPropertyChangedSignal("ViewportSize") }) do
				for _, v10 in ipairs(getconnections(v9)) do
					if not v10.ForeignState and fn20(v10.Function) then
						function_ = v10.Function
						break
					end
				end

				if not function_ then
					continue
				end
				break
			end

			if not function_ then
				return false
			end
			local v9 = getupvalues(function_)

			for k, v10 in pairs(v9) do
				if type(v10) == "function" then
					v6 = k
					break
				end
			end

			if not v6 then
				function_ = nil
				return false
			end
			v7 = v9[v6]
			return true
		end

		local function fn22()
			local value2 = rawget(v4, "OnChange")
			local tbl17 = {}
			local value3 = type(value2) == "table" and rawget(value2, "_handlerListHead") or nil

			while value3 do
				local value4 = rawget(value3, "_fn")
				local v9 = fn19(value4)
				local flag2 = false

				for _, v10 in ipairs(tbl16) do
					if v9:find(v10, 1, true) then
						flag2 = true
						break
					end
				end

				tbl17[#tbl17 + 1] = { node = value3, fn = value4, push = flag2 }
				value3 = rawget(value3, "_next")
			end

			return tbl17
		end

		local function fn23()
		end

		local str2 = "boberhook_Device_" .. tostring(game.GameId) .. ".txt"

		tbl3.devstat = function()
			if not tbl3.dldev then
				return
			end
			fn21()
			local str3 = "?"

			if v4 then
				str3 = tostring(v7 and v7() or rawget(v4, "Device"))
			end

			local devtype = tbl10.devtype
			local devscreen = tbl10.devscreen
			local str4 = ("Your real device: %s\nOthers will see: %s\nYour screen: %s"):format(str3, devtype and devtype ~= "Off" and devtype or "your real one", devscreen and devscreen ~= "Off" and devscreen or "normal")
			if str4 == v8 then
				return
			end
			v8 = str4

			task.defer(function()
				tbl3.dldev:SetText(str4)
			end)
		end

		tbl3.devui = function(devscreen, arg)
			if not fn21() then
				if not arg then
					tbl3.notif("Device Spoofer", "Device data isn't ready yet. Try again in a second.", 4)
				end

				return
			end

			local flag2 = devscreen ~= nil and devscreen ~= "Off"
			local v9 = flag2 and devscreen or v7()
			local v10 = fn22()

			for _, v11 in ipairs(v10) do
				rawset(v11.node, "_fn", v11.push and fn23 or v11.fn)
			end

			rawset(v4, "Device", "\0")

			setupvalue(function_, v6, function()
				return v9
			end)

			function_()

			for _, v11 in ipairs(v10) do
				rawset(v11.node, "_fn", v11.fn)
			end

			if v5 then
				v5.GetDeviceType = flag2 and function()
					return tbl15[devscreen] or devscreen
				end or value
			end

			tbl10.devscreen = devscreen
			tbl3.devstat()
			if arg then
				return
			end
			tbl3.notif("Device Spoofer", flag2 and "Your screen now acts like " .. devscreen .. "." or "Screen back to normal. Rejoin to fully clear the mobile layout.", 5)
		end

		tbl3.devarm = function(devtype, arg)
			tbl10.devtype = devtype

			if writefile then
				writefile(str2, devtype)
			end

			if type(queueonteleport) ~= "function" then
				tbl3.devstat()

				if not arg then
					tbl3.notif("Device Spoofer", "Your executor can't queue scripts, so this won't stick.", 6)
				end

				return
			end

			queueonteleport(([[task.spawn(function()
    local f = %q
    if not (isfile and readfile and isfile(f)) then return end
    local want = readfile(f)
    want = type(want) == "string" and want:match("^%%s*(.-)%%s*$") or nil
    if not want or want == "" or want == "Off" then return end
    local rs = game:GetService("ReplicatedStorage")
    local m = rs:WaitForChild("ClientGameModules", 60)
    m = m and m:WaitForChild("DeviceListener", 60)
    if not m then return end
    local dl = require(m)
    local ob = rawget(dl, "Observe")
    if type(ob) ~= "function" then return end
    local n = 0
    rawset(dl, "Observe", function(self, fn, ...)
        local s = debug.info(2, "s")
        s = type(s) == "string" and s or ""
        if s:find("PlayerProfileController", 1, true) or s:find("AnalyticsController", 1, true) then
            local was = rawget(self, "Device")
            rawset(self, "Device", want)
            local a, b = ob(self, fn, ...)
            rawset(self, "Device", was)
            n = n + 1
            if n >= 2 then rawset(dl, "Observe", ob) end
            return a, b
        end
        return ob(self, fn, ...)
    end)
end)
]]):format(str2))

			tbl3.devstat()
			if arg then
				return
			end

			if devtype == "Off" then
				tbl3.notif("Device Spoofer", "Off. Rejoin to go back to your real device.", 5)
				return
			end
			tbl3.notif("Device Spoofer", "Others will see " .. devtype .. ". Rejoining now.", 4)

			tbl3.bindt(task.delay(1.5, function()
				if fn3 then
					fn3()
				end
			end))
		end

		toggles.rainbowball:OnChanged(function(arg)
			localPlayer:SetAttribute("RainbowBall", arg and true or nil)
		end)

		local tbl17 = { hls = setmetatable({}, { __mode = "k" }), conn = nil }

		local function fn24()
			for k, v9 in pairs(tbl17.hls) do
				v9:Destroy()
				tbl17.hls[k] = nil
			end
		end

		local function fn25()local l= options .ballcolorpick and  options .ballcolorpick.Value or(Color3.fromRGB(0,200,255));for K,p in ipairs( tbl3 .ballList())do K= tbl17 .hls[p];if not K or not K.Parent then K=Instance.new("Highlight");K.Name="\0bc";K.FillTransparency=0.35;K.OutlineTransparency=0;K.Adornee=p;K.Parent= fn6 and( fn6 ())or  CoreGui ; tbl17 .hls[p]=K;end;K.FillColor=l;K.OutlineColor=l;end;for l,K in pairs( tbl17 .hls)do if not l.Parent then K:Destroy(); tbl17 .hls[l]=nil;end;end;end

		local function fn26()
			if tbl17.conn then
				return
			end
			tbl17.acc = 0
			tbl17.conn = tbl3.bind(RunService.Heartbeat:Connect(function(l) tbl17 .acc= tbl17 .acc+l;if  tbl17 .acc<0.06 then return;end; tbl17 .acc=0; fn25 ();end))
		end

		local function fn27()
			if tbl17.conn then
				tbl17.conn:Disconnect()
				tbl17.conn = nil
			end

			fn24()
		end

		toggles.ballcolor:OnChanged(function(arg)
			if arg then
				fn26()
			else
				fn27()
			end
		end)

		local tbl18 = { g = nil, conn = nil, lbl = nil, frames = 0, t = 0 }

		local function fn28()
			if tbl18.conn then
				tbl18.conn:Disconnect()
				tbl18.conn = nil
			end

			if tbl18.g then
				tbl18.g:Destroy()
				tbl18.g = nil
			end
		end

		local function fn29()
			fn28()
			local screenGui = Instance.new("ScreenGui")
			screenGui.Name = "\0fp"
			screenGui.ResetOnSpawn = false
			screenGui.IgnoreGuiInset = true
			screenGui.DisplayOrder = 55
			screenGui.Parent = v.ScreenGui or fn6 and fn6() or CoreGui
			tbl18.g = screenGui
			local frame = Instance.new("Frame")
			frame.AnchorPoint = Vector2.new(1, 0)
			frame.Position = UDim2.new(1, -16, 0, 90)
			frame.Size = UDim2.fromOffset(104, 46)
			frame.BackgroundColor3 = color
			frame.BackgroundTransparency = 0.04
			frame.BorderSizePixel = 0
			frame.ZIndex = 1
			frame.Parent = screenGui
			tbl3.corner(frame, 12)
			local uiGradient = Instance.new("UIGradient")
			uiGradient.Rotation = 90
			local color4 = Color3.fromRGB
			uiGradient.Color = ColorSequence.new(Color3.fromRGB(12, 52, 82), color4(3, 26, 44))
			uiGradient.Parent = frame
			tbl3.stroke(frame, Color3.fromRGB(255, 255, 255), 1, 0.9)
			local imageLabel = Instance.new("ImageLabel")
			imageLabel.BackgroundTransparency = 1
			imageLabel.Image = "rbxassetid://6014261993"
			imageLabel.ImageColor3 = Color3.fromRGB(0, 0, 0)
			imageLabel.ImageTransparency = 0.45
			imageLabel.ScaleType = Enum.ScaleType.Slice
			imageLabel.SliceCenter = Rect.new(49, 49, 450, 450)
			imageLabel.Position = UDim2.fromOffset(-15, -15)
			imageLabel.Size = UDim2.new(1, 30, 1, 30)
			imageLabel.ZIndex = 0
			imageLabel.Parent = frame
			local textLabel = Instance.new("TextLabel")
			textLabel.Size = UDim2.fromScale(1, 1)
			textLabel.BackgroundTransparency = 1
			textLabel.Font = Enum.Font.GothamBold
			textLabel.TextSize = 14
			textLabel.LineHeight = 1.15
			textLabel.TextColor3 = color2
			textLabel.ZIndex = 2
			textLabel.Text = "-"
			textLabel.Parent = frame
			tbl3.dragify(frame, frame)
			tbl18.lbl = textLabel
			tbl18.t = clock()
			tbl18.frames = 0
			tbl18.conn = tbl3.bind(RunService.RenderStepped:Connect(function() tbl18 .frames= tbl18 .frames+1;local l= clock ();if l- tbl18 .t>=0.5 then local K= floor ( tbl18 .frames/(l- tbl18 .t)+0.5); tbl18 .frames=0; tbl18 .t=l; tbl18 .lbl.Text= format ("%d FPS\10%d ms",K, floor ( tbl3 .getping()+0.5));end;end))
		end

		toggles.fpscounter:OnChanged(function(arg)
			if arg then
				fn29()
			else
				fn28()
			end
		end)

		local tbl19 = { conn = nil, last = 0, acc = 0, btns = setmetatable({}, { __mode = "k" }) }
		local function fn30(l)if l:IsA("GuiButton")and(l.Name=="PlayAgain"or l.Name=="RematchButton")then  tbl19 .btns[l]=true;end;end
		local function fn31()if  tbl19 .hooked then return;end;local l= localPlayer :FindFirstChild("PlayerGui");if not l then return;end; tbl19 .hooked=true;for K,K in ipairs(l:GetDescendants())do  fn30 (K);end; tbl3 .bind(l.DescendantAdded:Connect( fn30 ));end
		local function fn32()local l= ReplicatedStorage :FindFirstChild("ServerInfo");local K=l and(l:FindFirstChild("numPlayers"));local l=K and(tonumber(K.Value))or 2;return  clamp (math.ceil(l/2),1,4);end
		local function fn33()if not  tbl19 .serverinfo then local l= ReplicatedStorage :FindFirstChild("ServerInfo");if l then  tbl19 .serverinfo=require(l);end;end;local l= tbl19 .serverinfo;if type(l)~="table"then return false;end;return(l.isRankedMatchServer and(l.isRankedMatchServer())or l.isNoAbilityRankedMatchServer and(l.isNoAbilityRankedMatchServer())or false)==true;end
		local function fn34()if tick()- tbl19 .last<1.5 then return;end;if  localPlayer :GetAttribute("Rematch")then return;end; fn31 ();for l in pairs( tbl19 .btns)do if l.Parent and l.Visible and l.AbsoluteSize.X>0 then if l.Name=="RematchButton"then local l= tbl3 .netremote("PlayerWantsRematch");if l and(l:IsA("RemoteEvent"))then  tbl19 .last=tick();l:FireServer();return;end;else if  fn33 ()then continue;end;local l= tbl3 .netremote("SetDuelAutoQueue");if l and(l:IsA("RemoteEvent"))then local K= fn32 (); tbl19 .last=tick();l:FireServer("Duel",K.."v"..K);return;end;end;end;end;end

		toggles.autorematch:OnChanged(function(arg)
			if arg then
				fn31()

				if not tbl19.conn then
					tbl19.conn = tbl3.bind(RunService.Heartbeat:Connect(function(l) tbl19 .acc= tbl19 .acc+l;if  tbl19 .acc<0.5 then return;end; tbl19 .acc=0; fn34 ();end))
				end
			elseif tbl19.conn then
				tbl19.conn:Disconnect()
				tbl19.conn = nil
			end
		end)

		local remotes = ReplicatedStorage:FindFirstChild("Remotes")
		remotes = remotes and remotes:FindFirstChild("RoundEnded")

		if remotes then
			tbl3.bind(remotes.OnClientEvent:Connect(function(l)if not( toggles .autorematch and  toggles .autorematch.Value)then return;end;if type(l)=="table"and l.successful==false then return;end; fn31 (); tbl3 .bindt(task.delay(0.5, fn34 ));end))
		end

		tbl3.initsword = function()
			if tbl9.swords then
				return tbl9.swords
			end
			local swtried = tbl9.swtried

			if swtried then
				local swtried2 = tbl9.swtried
				swtried = clock() - swtried2 < 3
			end

			if swtried then
				return nil
			end
			tbl9.swtried = clock()
			local shared = ReplicatedStorage:WaitForChild("Shared", 5)
			shared = shared and shared:WaitForChild("ReplicatedInstances", 5)
			tbl9.swmod = shared and shared:WaitForChild("Swords", 5)

			if tbl9.swmod then
				tbl9.swords = require(tbl9.swmod)
			end

			if not tbl9.swords then
				tbl3.logwev("swordinit", 30, "sword skin", "Shared.ReplicatedInstances.Swords not ready - will retry")
				return nil
			end
			tbl9.swtried = nil
			local remotes2 = ReplicatedStorage:FindFirstChild("Remotes")
			remotes2 = remotes2 and remotes2:FindFirstChild("FireSwordInfo")

			if remotes2 and getconnections then
				for _, v9 in ipairs(getconnections(remotes2.OnClientEvent)) do
					if not v9.ForeignState and v9.Function and islclosure(v9.Function) then
						local v10 = getupvalues(v9.Function)
						local n2 = 0
						local v11 = nil

						for _, v12 in pairs(v10) do
							n2 += 1
							v11 = v12
						end

						if n2 == 1 and type(v11) == "table" then
							tbl9.swctrl = v11
							break
						end
					end
				end
			end

			tbl9.swbind = tbl9.swmod and tbl9.swmod:FindFirstChild("EquipSwordTo")
			return tbl9.swords
		end

		tbl3.equipsword = function(arg, arg2, arg3, arg4)
			local swords = tbl9.swords
			if not swords then
				return
			end

			if arg4 then
				arg:SetAttribute("_generationCtx_Swords", "")
			end

			if not arg3 and tbl9.swbind and tbl9.swbind:IsA("BindableFunction") then
				tbl9.swbind:Invoke(arg, arg2)
				return
			end
			swords:EquipSwordTo(arg, arg2, arg:GetAttribute("ScaleSword"), arg3)
		end

		tbl3.swequipped = function()local l= tbl3 .safechar();local K=l and(l:GetAttribute("CurrentlyEquippedSword"));K=if type(K)~="string"or K==""then( localPlayer :GetAttribute("CurrentlyEquippedSword"))else K;return type(K)=="string"and K~=""and K or nil;end

		tbl3.setswattr = function(arg)
			local v9 = tbl3.safechar()

			if v9 then
				v9:SetAttribute("CurrentlyEquippedSword", arg)
			end

			localPlayer:SetAttribute("CurrentlyEquippedSword", arg)
		end

		tbl3.slashname = function(l)if not  tbl9 .swords then return"SlashEffect";end;local K= tbl9 .swords:GetSword(l);if type(K)=="table"then l=K.SlashName or K.Slash or K.SlashEffect or K.SlashParticle;if type(l)=="string"and l~=""then return l;end;end;return"SlashEffect";end

		tbl3.applysword = function()
			if not tbl10.swskin then
				return
			end
			local swname = tbl10.swname
			if not swname or swname == "" then
				return
			end
			tbl3.initsword()
			if not tbl9.swords or not tbl9.swords:GetSword(swname) then
				return
			end
			local v9 = tbl3.safechar()
			if not v9 then
				return
			end

			if tbl9.swbad[swname] then
				return false
			end

			if type(tbl9.swords.GetInstance) == "function" then
				if not tbl9.swords:GetInstance(swname) then
					tbl9.swbad[swname] = true
					tbl3.notif("Skins", ("The server never sent the %s model. Pick another sword."):format(swname), 7)
					return false
				end
			end

			tbl3.equipsword(v9, swname)
			tbl3.fxwarm(swname)

			if tbl9.swctrl and tbl9.swctrl.SetSword then
				tbl9.swctrl:SetSword(swname)
			end

			if getgenv and getgenv().__vexBaseSwordPos ~= false then
				local torso = v9:FindFirstChild("Torso")
				local v10 = v9:FindFirstChild(swname)

				if torso and v10 then
					for _, v11 in ipairs({ "Motor6D", "Motor6D2" }) do
						local v12 = torso:FindFirstChild(v11)

						if v12 then
							local attribute = v10:GetAttribute("C0Offset")
							local attribute2 = v10:GetAttribute("C1Offset")

							if attribute then
								v12.C0 = v12.C0 * attribute:Inverse()
							end

							if attribute2 then
								v12.C1 = v12.C1 * attribute2:Inverse()
							end
						end
					end
				end
			end

			return true
		end

		tbl3.cleanstray = function(arg, arg2)
			if not tbl9.swords then
				return
			end

			for _, child in ipairs(arg:GetChildren()) do
				if child:IsA("Model") and child.Name ~= arg2 and tbl9.swords:GetSword(child.Name) then
					child:Destroy()
				end
			end
		end

		tbl3.ensureskin = function()
			if not tbl10.swskin then
				return
			end
			local swname = tbl10.swname
			if not swname or swname == "" then
				return
			end
			tbl3.initsword()
			if not tbl9.swords or not tbl9.swords:GetSword(swname) then
				return
			end
			local v9 = tbl3.safechar()
			if not v9 then
				return
			end

			if not v9:FindFirstChild(swname) or tbl3.swequipped() ~= swname then
				tbl3.applysword()
			elseif tbl9.swctrl and tbl9.swctrl.SetSword and tbl9.swctrl.CharacterSword ~= swname then
				tbl9.swctrl:SetSword(swname)
			end
		end

		tbl3.swordfx = function()
			if tbl9.fxmod then
				return tbl9.fxmod
			end
			local shared = ReplicatedStorage:FindFirstChild("Shared")
			shared = shared and shared:FindFirstChild("ReplicatedInstances")
			shared = shared and shared:FindFirstChild("SwordFX")
			if not shared then
				return nil
			end
			local module = require(shared)

			if type(module) == "table" then
				tbl9.fxmod = module
			end

			return tbl9.fxmod
		end

		tbl3.fxwarm = function(arg)
			if not arg or arg == "" then
				return
			end
			local fxwarm = tbl3.slashname(arg)
			if tbl9.fxwarm[fxwarm] then
				return
			end
			tbl9.fxwarm[fxwarm] = true

			tbl3.bindt(task.spawn(function()
				local v9 = tbl3.swordfx()
				if not v9 or type(v9.GetInstance) ~= "function" then
					tbl9.fxwarm[fxwarm] = nil
					return
				end

				if not v9:GetInstance(fxwarm) then
					tbl9.fxwarm[fxwarm] = nil
					tbl3.logwev("fxwarm:" .. fxwarm, 30, "sword skin", ("the server did not send the %s slash effect"):format(fxwarm))
				end
			end))
		end

		tbl3.slashsigs = function()
			local remotes2 = ReplicatedStorage:FindFirstChild("Remotes")
			if not remotes2 then
				return nil, nil
			end
			local parrySuccessAll = remotes2:FindFirstChild("ParrySuccessAll")
			local parrySuccessClient = remotes2:FindFirstChild("ParrySuccessClient")
			return parrySuccessAll and parrySuccessAll.OnClientEvent or nil, parrySuccessClient and parrySuccessClient.Event or nil
		end

		tbl3.livecons = function(arg)
			local tbl20 = {}
			if not arg then
				return tbl20
			end
			local v9 = getconnections(arg)
			if type(v9) ~= "table" then
				return tbl20
			end

			for _, v10 in ipairs(v9) do
				if not v10.ForeignState and v10.Function then
					tbl20[#tbl20 + 1] = v10
				end
			end

			return tbl20
		end

		tbl3.slashfind = function(arg, arg2)
			local v9 = tbl3.livecons(arg)
			local v10 = tbl3.livecons(arg2)
			local tbl20 = {}

			for _, v11 in ipairs(v9) do
				tbl20[v11.Function] = true
			end

			for _, v11 in ipairs(v10) do
				if tbl20[v11.Function] then
					return v11.Function, v9, v10
				end
			end

			local value2 = getinfo or debug and rawget(debug, "getinfo")

			if value2 then
				for _, v11 in ipairs(v9) do
					local v12 = value2(v11.Function)
					if type(v12) == "table" and v12.name == "parrySuccessAll" then
						return v11.Function, v9, v10
					end
				end
			end

			if #v9 == 1 and islclosure(v9[1].Function) then
				return v9[1].Function, v9, v10
			end
			return nil, v9, v10
		end

		tbl3.slashwrap = function(...)if setthreadidentity then setthreadidentity(2);end;local l=table.pack(...);if( tbl10 .swskin or  tbl10 .unlockall)and tostring(l[4])== localPlayer .Name then local K= tbl9 .swctrl and  tbl9 .swctrl.CharacterSword;K=if not(if not K or K==""then( tbl3 .swequipped())else K)or(if not K or K==""then( tbl3 .swequipped())else K)==""then  tbl10 .swname else if not K or K==""then( tbl3 .swequipped())else K;if K and K~=""and  tbl9 .swords and( tbl9 .swords:GetSword(K))then l[1]= tbl3 .slashname(K);l[3]=K;end;end;return  tbl9 .slashorig(table.unpack(l,1,l.n));end

		tbl3.hookslash = function()
			if tbl9.slashhooked then
				return true
			end

			if not getconnections then
				return false
			end
			local v9, v10 = tbl3.slashsigs()
			if not v9 then
				return false
			end
			local v11, v12, v13 = tbl3.slashfind(v9, v10)
			if not v11 then
				return false
			end
			local n2 = 0

			local function fn35(arg)
				for _, v14 in ipairs(arg) do
					if v14.Function == v11 then
						v14:Disable()

						if v14.Enabled == false then
							n2 += 1
							tbl9.slashoff[#tbl9.slashoff + 1] = v14
						end
					end
				end
			end

			fn35(v12)
			fn35(v13)
			if n2 == 0 then
				return false
			end
			tbl9.slashorig = v11
			tbl3.bind(v9:Connect(tbl3.slashwrap))

			if v10 then
				tbl3.bind(v10:Connect(tbl3.slashwrap))
			end

			tbl9.slashhooked = true
			tbl3.fxwarm(tbl10.swname)
			return true
		end

		tbl3.startslash = function()
			if tbl9.slashtask then
				return
			end

			tbl9.slashtask = tbl3.bindt(task.spawn(function()
				for i = 1, 60 do
					if tbl3.hookslash() then
						return
					end
					task.wait(0.25)
				end

				tbl3.notif("Skins", "Can't change the slash effect here. Skins keep the default one.", 8)
			end))
		end

		tbl3.skinloop = function()
			if tbl9.skinstarted then
				return
			end
			tbl9.skinstarted = true
			tbl3.initsword()
			tbl3.startslash()

			if not tbl9.holsterhooked and tbl9.swctrl and tbl9.swctrl.OnCharacterSwordUpdate then
				local onCharacterSwordUpdate = tbl9.swctrl.OnCharacterSwordUpdate

				if onCharacterSwordUpdate.Connect then
					tbl3.bind(onCharacterSwordUpdate:Connect(function(arg)
						if not tbl10.swskin or tbl10.swname == "" or arg == tbl10.swname then
							return
						end

						if not tbl10.unlockall and not tbl10.autoload and type(arg) == "string" and arg ~= "" then
							if tbl9.skinbusy then
								task.defer(tbl3.ensureskin)
								return
							end
							tbl10.swskin = false
							tbl10.swname = ""
							return
						end

						task.defer(tbl3.ensureskin)
					end))

					tbl9.holsterhooked = true
				end
			end

			tbl3.bind(localPlayer.CharacterAdded:Connect(function(character)
				if not tbl10.swskin or tbl10.swname == "" then
					return
				end
				tbl9.skinbusy = true
				character:WaitForChild("HumanoidRootPart", 10)
				local n2 = clock() + 6

				while not (character:GetAttribute("AppearanceLoaded") or localPlayer:GetAttribute("AppearanceLoaded")) and clock() < n2 do
					task.wait(0.1)
				end

				task.wait(0.2)
				tbl3.applysword()

				for i = 1, 8 do
					task.wait(0.35)
					if not tbl10.swskin or not character.Parent then
						tbl9.skinbusy = false
						return
					end
					tbl3.ensureskin()
					tbl3.cleanstray(character, tbl10.swname)
				end

				tbl9.skinbusy = false
			end))

			tbl3.bindt(task.spawn(function()
				while task.wait(2) do
					if tbl10.swskin and tbl10.swname ~= "" then
						if not tbl10.unlockall and not tbl10.autoload and not tbl9.skinbusy then
							local v9 = tbl3.swequipped()

							if type(v9) == "string" and v9 ~= "" and v9 ~= tbl10.swname then
								tbl10.swskin = false
								tbl10.swname = ""
							end
						end

						if tbl10.swskin then
							local v9 = tbl3.safechar()

							if v9 then
								tbl3.ensureskin()
								tbl3.cleanstray(v9, tbl10.swname)
							end
						end
					end
				end
			end))
		end

		tbl3.parryanims = function(l,K)local p= tbl9 .grabcache;if p and p.sword==K then return p.anims;end;p= ReplicatedStorage :WaitForChild("Shared",10);local E=p and(p:WaitForChild("SwordAPI",10));if not E then return;end;local k=p:WaitForChild("ReplicatedInstances",10);p=k and(k:WaitForChild("Swords",10));k=p and(p.GetSword:Invoke(K));if not(k and k.AnimationType)then return;end;p=require(E);if type(p)=="table"and type(p.GetAnimations)=="function"then local a=p:GetAnimations(l,{"Parry","GrabParry"},k.AnimationType,k.SwordType);if type(a)=="table"and#a>0 then  tbl9 .grabcache={sword=K,anims=a};return a;end;end;p=E:FindFirstChild("Collection");if not p then return;end;l=p:FindFirstChild(k.AnimationType);k=l and(l:FindFirstChild("Parry")or(l:FindFirstChild("Grab"))or(l:FindFirstChild("GrabParry")))or p:FindFirstChild("Default")and(p.Default:FindFirstChild("Parry")or(p.Default:FindFirstChild("GrabParry")));l=if k then{k}else nil; tbl9 .grabcache={sword=K,anims=l};return l;end
		tbl3.playgrab = function()local l= tbl3 .safechar();if not l then return;end;if  clock ()- tbl9 .lastgrab< tbl9 .grabcd then return;end;local K=l:GetAttribute("CurrentlyEquippedSword");K=if  tbl10 .swskin and  tbl10 .swname~=""then  tbl10 .swname else K;if not K then return;end;local p=l:FindFirstChildOfClass("Humanoid");local E=p and(p:FindFirstChildOfClass("Animator"));if not E then return;end;p= tbl3 .parryanims(l,K);if not p or#p==0 then return;end; tbl9 .lastgrab= clock ();if  tbl9 .grabtracks_sword~=K or  tbl9 .grabtracks_anim~=E or not  tbl9 .grabtracks then if  tbl9 .grabtracks then for k,k in ipairs( tbl9 .grabtracks)do k.track:Stop(0);k.track:Destroy();end;end; tbl9 .grabtracks={};for k,a in ipairs(p)do k=E:LoadAnimation(a);if k then for d,I in pairs(a:GetAttributes())do k:SetAttribute(d,I);end; tbl9 .grabtracks[# tbl9 .grabtracks+1]={track=k,anim=a};end;end; tbl9 .grabtracks_sword=K; tbl9 .grabtracks_anim=E;end;for E,k in ipairs( tbl9 .grabtracks)do E,p=k.anim,k.track;k=E:GetAttribute("PlaySpeed")or 1;if p.IsPlaying then p:Stop(0.05);end;p:Play(E:GetAttribute("PlayFadeTime")or 0.1,E:GetAttribute("PlayWeight")or 1,k);K=p.Length or 0;local E=K~=0 and(K-p.TimePosition)*k or 1;l:SetAttribute("ParryTime", max (l:GetAttribute("ParryTime")or 0,E));end;end
		tbl3.stopgrab = function() tbl9 .lastgrab= clock ();if  tbl9 .grabtracks then for l,l in ipairs( tbl9 .grabtracks)do l.track:Stop(0.1);end;end;end
		tbl3.mouseplr = function()if not  alive or not  currentCamera then return nil;end;local l= tbl3 .safechar();if not l or l.Parent~= alive then return nil;end;l= UserInputService :GetMouseLocation();local K,p= huge ;for E,k in ipairs( alive :GetChildren())do if k.PrimaryPart and( tbl3 .validtgt(k))then local a,d= currentCamera :WorldToViewportPoint(k.PrimaryPart.Position);if d then E=(Vector2.new(a.X,a.Y)-Vector2.new(l.X,l.Y)).Magnitude;if E<K then K,p=E,k;end;end;end;end;return p;end
		tbl3.aimedplr = function()if not  alive or not  currentCamera then return nil;end;local l= tbl3 .safechar();if not l or l.Parent~= alive then return nil;end;l= currentCamera .ViewportSize;local K=l.X/2;local p=l.Y/2;local E,k= huge ;for a,d in ipairs( alive :GetChildren())do if d.PrimaryPart and( tbl3 .validtgt(d))then a,l= currentCamera :WorldToViewportPoint(d.PrimaryPart.Position);if l then local h=(Vector2.new(a.X,a.Y)-Vector2.new(K,p)).Magnitude;if h<E then E,k=h,d;end;end;end;end;return k;end
		tbl3.deflecting = function()if( tbl9 .defcast or 0)> clock ()then return true;end;local l= tbl3 .safechar();if not l then return false;end;return l:GetAttribute("IsRagingDeflection")==true or l:GetAttribute("IsRapture")==true;end
		tbl3.abact = function(l)l=l or( tbl3 .safechar());return l and l:GetAttribute("AbilityActive")==true or false;end
		tbl3.hotslots = { block = "Block", ability = "Ability" }
		tbl3.hotcache = {}
		tbl3.hotslot = function(l)local K= tbl3 .hotcache[l];if K and K.Parent then return K;end;K= localPlayer :FindFirstChild("PlayerGui");local p=K and(K:FindFirstChild("Hotbar"));if not p then return nil;end;K=p:FindFirstChild( tbl3 .hotslots[l]); tbl3 .hotcache[l]=K;return K;end
		tbl3.netremote = function(l)return  tbl8 .byname(l);end

		tbl3.phpos = function(arg)
			if arg:IsA("Model") then
				return arg:GetPivot().Position
			end

			if arg:IsA("BasePart") then
				return arg.Position
			end
			local basePart = arg:FindFirstChildWhichIsA("BasePart", true)
			return basePart and basePart.Position or nil
		end

		tbl3.onphantom = function(arg)
			local name = arg.Name
			if name ~= "transmissionpart" and name ~= "maxTransmission" then
				return
			end

			task.defer(function()
				local v9 = tbl3.safehrp()
				local v10 = tbl3.phpos(arg)

				if v9 and v10 and (v10 - v9.Position).Magnitude <= 32 then
					tbl3.clrload()
					tbl9.phactive = true

					task.delay(1, function()
						tbl9.phactive = false
					end)
				end
			end)
		end

		tbl3.stopphantom = function()
			if tbl9.phconn then
				tbl9.phconn:Disconnect()
				tbl9.phconn = nil
			end

			tbl9.phactive = false
		end

		tbl3.startphantom = function()
			tbl3.stopphantom()
			if not runtime then
				return
			end
			tbl9.phconn = tbl3.bind(runtime.ChildAdded:Connect(tbl3.onphantom))
		end
	end

	tbl3.staffact = function(arg)
		if not tbl10.staff then
			return
		end
		local str2 = tostring(arg:GetRoleInGroup(12836673)):lower()
		if str2 == "guest" or str2 == "member" or str2 == "" then
			return
		end
		local str3 = "Staff joined: " .. arg.DisplayName

		if tbl10.staffdo == "Auto Kick" then
			localPlayer:Kick(str3)
		elseif tbl10.staffdo == "Close Game" then
			game:Shutdown()
		elseif tbl10.staffdo == "Serverhop" then
			tbl3.notif("Staff Detection", "Staff joined. Hopping to another server.", 5)

			if fn4 then
				fn4()
			end
		else
			tbl3.notif("Staff Detection", str3, 15)
		end
	end

	tbl3.stopstaff = function()
		if tbl9.staffconn then
			tbl9.staffconn:Disconnect()
			tbl9.staffconn = nil
		end
	end

	tbl3.startstaff = function()
		tbl3.stopstaff()
		if not tbl10.staff then
			return
		end
		tbl9.staffconn = tbl3.bind(Players.PlayerAdded:Connect(tbl3.staffact))

		tbl3.bindt(task.spawn(function()
			for _, player in ipairs(Players:GetPlayers()) do
				if tbl10.staff then
					tbl3.staffact(player)
					task.wait()
					continue
				end

				break
			end
		end))
	end

	do
		local fn7 = nil
		tbl3.anyparry = function()return( tbl10 .autoparry or  tbl10 .trigger or  tbl10 .autospam or  tbl10 .manspam)and true or false;end
		tbl3.pload = function()return  tbl9 .parries or 0;end
		tbl3.clrload = function() tbl9 .parries=0;end

		tbl3.startdet = function()
			tbl3.startstaff()
			tbl3.startphantom()
			local balls = Workspace:FindFirstChild("Balls")
			if not balls then
				return
			end

		end

		tbl3.rndplayed = 0
		tbl3.rndwins = 0
		tbl3.rndkills = 0
		tbl3.rndlast = ""
		local remotes = ReplicatedStorage:FindFirstChild("Remotes")

		if remotes then
			local standoffStart = remotes:FindFirstChild("StandoffStart")
			local roundEnded = remotes:FindFirstChild("RoundEnded")

			if standoffStart then
				tbl3.bind(standoffStart.OnClientEvent:Connect(function()
					tbl9.standoff = true
				end))
			end

			if roundEnded then
				tbl3.bind(roundEnded.OnClientEvent:Connect(function(l) tbl9 .standoff=false;if type(l)~="table"then return;end; tbl3 .rndplayed= tbl3 .rndplayed+1;local K=false;if type(l.winners)=="table"then for p,p in pairs(l.winners)do if p== localPlayer then K=true;break;end;end;end;if K then  tbl3 .rndwins= tbl3 .rndwins+1;end;if type(l.kills)=="table"then local p=l.kills[ localPlayer ];if type(p)=="number"then  tbl3 .rndkills= tbl3 .rndkills+p;end;end; tbl3 .rndlast=type(l.winnersText)=="string"and l.winnersText or(K and"You won"or"You lost");end))
			end
		end

		tbl3.aimlead = function(l,K,p)local E,k=K.Position+Vector3.new(0,p or 0,0),K.AssemblyLinearVelocity;if k and k.Magnitude>1 then p= clamp ((E-l).Magnitude/220,0,0.35);E+=Vector3.new(k.X,0,k.Z)*p;end;return E;end
		tbl3.parryPayload = function(l)l=if  tbl10 .nocrv and( tbl9 .msactive or  tbl3 .pload()>1)then"Camera"else l;local K=nil;if  flag then local p= currentCamera .ViewportSize;K={p.X/2,p.Y/2};else local p= UserInputService :GetMouseLocation();K={p.X,p.Y};end;local p={};if  tbl3 .inlobby()then if  dead then for E,k in pairs( dead :GetChildren())do E=k:FindFirstChild("HumanoidRootPart");local a= Players :GetPlayerFromCharacter(k);if E and a and(a:GetAttribute("LobbyTraining"))then p[k.Name]= currentCamera :WorldToScreenPoint(E.Position);end;end;end;for E,E in ipairs( CollectionService :GetTagged("LobbyTrainingTarget"))do p[E.Name]= currentCamera :WorldToScreenPoint(E.Position);end;elseif  alive then for E,k in pairs( alive :GetChildren())do E=k:FindFirstChild("HumanoidRootPart");if E then p[k.Name]= currentCamera :WorldToScreenPoint(E.Position);end;end;end;local E= currentCamera .CFrame;local k,a,d=E.Position,E.LookVector, tbl3 .safechar();if l=="Standoff"then local function R(x,y)return x+(y-x)*random();end;local I=Vector3.new(-a.X,0,-a.Z);I=if I.Magnitude>0.001 then I.Unit else Vector3.new(0,0,-1);local C=Vector3.new(E.RightVector.X,0,E.RightVector.Z);C=if C.Magnitude>0.001 then C.Unit else Vector3.new(1,0,0);local U,J,V=random(1,4),0,0;if U==1 then J=R(-10,10);V=R(0,12);elseif U==2 then J=R(-10,10);V=R(25,50);else J=if random()<0.4 then R(55,85)else R(20,45);V=R(20,50);if U==4 then J=-J;end;end;local H,P=I*math.cos(math.rad(J))+C*math.sin(math.rad(J)),math.rad(V);return{0,CFrame.new(k,k+(H*math.cos(P)+Vector3.new(0,math.sin(P),0))*10000),p,K};end;if l=="Camera"then return{0,CFrame.new(k,k+a),p,K};end;if l=="Backwards"then local I=-a*10000;I=Vector3.new(I.X,0,I.Z);return{0,CFrame.new(k,k+I),p,K};end;if l=="Dot"then local I= tbl3 .aimedplr();if I and d and d.PrimaryPart then return{0,CFrame.new(d.PrimaryPart.Position, tbl3 .aimlead(d.PrimaryPart.Position,I.PrimaryPart,15)),p,K};end;return{0,CFrame.new(k,k+a),p,K};end;if l=="Straight"then if  flag then local I= tbl3 .aimedplr();if I and d and d.PrimaryPart then return{0,CFrame.new(d.PrimaryPart.Position, tbl3 .aimlead(d.PrimaryPart.Position,I.PrimaryPart,0)),p,K};end;return{0,CFrame.new(k,k+a),p,K};end;local I= tbl3 .mouseplr();if I and d and d.PrimaryPart then return{0,CFrame.new(d.PrimaryPart.Position, tbl3 .aimlead(d.PrimaryPart.Position,I.PrimaryPart,0)),p,K};end;return{0,CFrame.new(k,k+a),p,K};end;if l=="Random"then local I= random ()* n *2;local C=Vector3.new( cos (I),0, sin (I))*10000;return{0,CFrame.new(k,k+C),p,K};end;if l=="Predict"then local I,C= tbl3 .aimedplr()or( tbl3 .closestplr()),d and(d.PrimaryPart or(d:FindFirstChild("HumanoidRootPart")));local U=I and(I.PrimaryPart or(I:FindFirstChild("HumanoidRootPart")));if C and U then return{0,CFrame.new(C.Position, tbl3 .aimlead(C.Position,U,12)),p,K};end;return{0,CFrame.new(k,k+a),p,K};end;if l=="Up"then return{0,CFrame.new(k,k+Vector3.new(a.X,10000,a.Z)),p,K};end;if l=="Right"then d=E.RightVector*10000;return{0,CFrame.new(k,k+Vector3.new(d.X,0,d.Z)),p,K};end;if l=="Left"then d=E.RightVector*-10000;return{0,CFrame.new(k,k+Vector3.new(d.X,0,d.Z)),p,K};end;return{0,CFrame.new(k,k+a),p,K};end
		tbl3.parryfallback = function()if  tbl8 .ensure then  tbl8 .ensure();end;return false;end

		tbl3.bindt(task.spawn(function()
			local shared = ReplicatedStorage:WaitForChild("Shared", 10)
			shared = shared and shared:FindFirstChild("UseBall2")
			local module = shared and shared:IsA("ModuleScript") and require(shared) or nil
			tbl9.b2mod = type(module) == "function" and module or false
		end))

		tbl3.useball2 = function()if  tbl9 .b2t and  clock ()- tbl9 .b2t<5 then return  tbl9 .b2==true;end; tbl9 .b2t= clock ();local l=if  tbl9 .b2mod then  tbl9 .b2mod()==true else  Workspace :GetAttribute("CurrentlySelectedMode")=="HalloweenEvent"or game.PlaceId==15240096157; tbl9 .b2=l;return l;end
		tbl3.svinfo = false
		tbl3.parrywin = function()local l= tbl3 .getrep("Data");if not l then return 0.5;end;local K=l:Get("timesParried");if type(K)~="number"then return 0.5;end;local p,E=if K==0 then 1.5 else if K==1 then 1.25 else if K==2 then 1 else if K==3 then 0.75 else if K==4 then 0.625 else 0.5,l:Get("TotalStats.Kills");if type(E)~="number"or E>=20 then return p;end;if  tbl3 .svinfo==false then K= ReplicatedStorage :FindFirstChild("ServerInfo"); tbl3 .svinfo=K and(require(K))or nil;end;K= tbl3 .svinfo;if type(K)=="table"and(K.isDungeonsMatchServer()or(K.isRankedMatchServer())or(K.isMedalServer())or(K.isClanWarServer())or(K.isTournamentMatchServer()))then return p;end;return E/20*p;end
		tbl3.flickroll = function()
			local function rr(a, b) return a + (b - a) * math.random() end
			local P = { hold = 0.09, out = 0.06, sm = 0, inT = 0, offY = 0, offP = 0, t = os.clock() }
			if not (toggles.camflickrand and toggles.camflickrand.Value) then return P end
			local sp = options.camflickspeed
			local lo = math.clamp(sp and sp.ValueMin or 60, 40, 100)
			local hi = math.clamp(sp and sp.ValueMax or 100, lo, 100)
			local k = (rr(lo, hi) - 40) / 60
			local sm = options.camflicksmooth
			local slo = math.clamp(sm and sm.ValueMin or 30, 0, 100)
			local shi = math.clamp(sm and sm.ValueMax or 80, slo, 100)
			P.sm = rr(slo, shi) / 100
			P.hold = (0.095 - 0.045 * k) * rr(0.92, 1.08)
			P.out = (0.08 - 0.04 * k) * rr(0.92, 1.08)
			P.inT = (0.05 - 0.032 * k) * (0.8 + 0.4 * P.sm) * rr(0.92, 1.08)
			local dr = options.camflickdrift
			local dmax = dr and dr.Value or 5
			if dmax > 0 then
				local function sg() return math.random() < 0.5 and -1 or 1 end
				P.offY = math.rad(sg() * rr(0.5, 1) * dmax)
				P.offP = math.rad(sg() * rr(0.2, 1) * dmax * 0.5)
			end
			return P
		end
		tbl3.flickParams = function()
			local P = tbl3.flickcache
			if not P or os.clock() - P.t > 1 then
				P = tbl3.flickroll()
				tbl3.flickcache = P
			end
			return P
		end
		tbl3.flickease = function(a, sm)
			local soft = a * a * a * (a * (a * 6 - 15) + 10)
			local snap = 1 - (1 - a) * (1 - a)
			return snap + (soft - snap) * sm
		end

		tbl3.camflick = function(payload, send, pre)
			local t = toggles.camflick
			if not (t and t.Value) then return false end
			local so = toggles.camflickstandoff
			if so and so.Value and not (tbl9 and tbl9.standoff == true) then return false end
			local cam = Workspace.CurrentCamera
			local cf = type(payload) == "table" and payload[2]
			if not cam or typeof(cf) ~= "CFrame" then return false end
			local dir = cf.LookVector
			local st = tbl3.flickst
			if not st then
				st = {}
				tbl3.flickst = st
			end
			local function yawOf(v) return math.atan2(-v.X, -v.Z) end
			local function pitchOf(v) return math.asin(math.clamp(v.Y, -1, 1)) end
			local function fromYP(y, p, pos)
				local cp = math.cos(p)
				local look = Vector3.new(-math.sin(y) * cp, math.sin(p), -math.cos(y) * cp)
				return CFrame.lookAt(pos, pos + look).Rotation
			end
			local rnd = toggles.camflickrand and toggles.camflickrand.Value
			local function arm()
				if type(send) ~= "function" then return false end
				local sent = false
				local function once()
					if sent then return end
					sent = true
					if st.pending == once then st.pending = nil end
					send()
				end
				if st.pending then local prev = st.pending; st.pending = nil; prev() end
				st.pending = once
				task.delay(0.05, once)
				return true
			end
			local cur = cam.CFrame
			if st.bound then
				if pre then return false end
				if st.pre and os.clock() - st.t0 < 0.4 then
					st.pre = false
					return false
				end
				if dir.Magnitude < 0.001 then return false end
				st.dir = dir
				st.t0 = os.clock()
				st.inT = 0
				st.shown = CFrame.lookAt(cur.Position, cur.Position + dir)
				cam.CFrame = st.shown
				return arm()
			end
			if dir.Magnitude < 0.001 or dir:Dot(cur.LookVector) > 0.9995 then return false end
			local P = tbl3.flickParams()
			tbl3.flickcache = nil
			st.dir = dir
			st.t0 = os.clock()
			st.hold = P.hold + (pre and 0.03 or 0)
			st.out = P.out
			st.sm = P.sm
			st.inT = P.inT
			st.offY, st.offP = P.offY, P.offP
			st.pre = pre == true
			local lv = cur.LookVector
			st.ry, st.rp = yawOf(lv), pitchOf(lv)
			local eased = rnd and st.inT > 0
			if eased then
				st.shown = cur
			else
				st.inT = 0
				st.shown = CFrame.lookAt(cur.Position, cur.Position + dir)
				cam.CFrame = st.shown
			end
			st.bound = true
			RunService:BindToRenderStep("CameraFlick", Enum.RenderPriority.Camera.Value + 1, function()
				local c = Workspace.CurrentCamera
				local function stop()
					st.bound = false
					st.pre = false
					pcall(function() RunService:UnbindFromRenderStep("CameraFlick") end)
				end
				if not c then stop() return end
				local now = c.CFrame
				local nl, sl = now.LookVector, st.shown.LookVector
				local dy = yawOf(nl) - yawOf(sl)
				dy = math.atan2(math.sin(dy), math.cos(dy))
				local dp = pitchOf(nl) - pitchOf(sl)
				if math.abs(pitchOf(sl)) > 1.39 then dp = 0 end
				if math.abs(dy) > 1.5 then dy = 0 end
				st.ry += dy
				st.rp = math.clamp(st.rp + dp, -1.39, 1.39)
				local realStart = fromYP(st.ry, st.rp, now.Position)
				local real = fromYP(st.ry + (st.offY or 0), math.clamp(st.rp + (st.offP or 0), -1.39, 1.39), now.Position)
				local el = os.clock() - st.t0
				local inT, sm = st.inT or 0, st.sm or 0
				local flick = CFrame.lookAt(now.Position, now.Position + st.dir).Rotation
				local rot
				if el < inT then
					rot = realStart:Lerp(flick, tbl3.flickease(el / inT, sm))
				elseif el < inT + st.hold then
					rot = flick
				else
					local a = math.min((el - inT - st.hold) / st.out, 1)
					rot = flick:Lerp(real, tbl3.flickease(a, sm))
					if a >= 1 then
						rot = real
						stop()
					end
				end
				st.shown = CFrame.new(now.Position) * rot
				c.CFrame = st.shown
				local fire = st.pending
				if fire and el >= inT then st.pending = nil; fire() end
			end)
			if pre then return true end
			if eased then return false end
			return arm()
		end

		tbl3.parryArgs = function(l)if  tbl3 .useball2()then return  currentCamera .CFrame,l[2],false;end;return  tbl3 .parrywin(),l[2],l[3],l[4],false;end
		tbl3.getvim = function()if not  tbl9 .vim then  tbl9 .vim=Instance.new("VirtualInputManager");end;return  tbl9 .vim;end
		tbl3.keyparry = function()local l= tbl3 .getvim();if not l then return false;end;l:SendKeyEvent(true,Enum.KeyCode.F,false,game);l:SendKeyEvent(false,Enum.KeyCode.F,false,game);return true;end
		fn7 = function(force)if not force and(not  tbl3 .anyparry()or tbl3.holdactive())then return false;end;if  tbl10 .keyparry then  tbl3 .keyparry();elseif  tbl8 .rem and  tbl8 .sgn and  tbl8 .signHolder and  tbl8 .signHash then local l,K= tbl3 .parryPayload( tbl10 .crv), tbl8 .signKey();local pp= tbl3 .flickprepay;if pp then  tbl3 .flickprepay=nil;if os.clock()-pp.t<0.35 then l[2]=pp.cf;end;end;local p=K and( tbl8 .s1(K));if not p then  tbl3 .logwev("fireParry",5,"fireParry","parry sign failed"); tbl3 .parryfallback();return false;end;local function send() tbl8 .rem:FireServer( tbl8 .signHash,K,p, tbl3 .parryArgs(l));end;if not tbl3 .camflick(l,send)then send();end;else  tbl3 .logwev("fireParry",5,"fireParry","parry remote/signer unavailable");if  tbl8 .ensure then  tbl8 .ensure();end; tbl3 .parryfallback();return false;end; tbl9 .sessparry=( tbl9 .sessparry or 0)+1;if( tbl9 .parries or 0)>=7 then return false;end; tbl9 .parries=( tbl9 .parries or 0)+1;task.delay(0.5,function()if( tbl9 .parries or 0)>0 then  tbl9 .parries= tbl9 .parries-1;end;end);if  tbl10 .hum then  tbl3 .humroll();end;return true;end
		tbl3.isCurved = function(l,K)l=l or( tbl3 .getball());if not l then return false;end;if not  tbl3 .ballLive(l)then return false;end;local p= tbl3 .safehrp();if not p then return false;end;local E= tbl3 .ballPos(l);if not E then return false;end;local k= tbl3 .ballVel(l);if k.Magnitude<=0 then return false;end;local a,d,I=k.Magnitude,k.Unit,(p.Position-E).Unit;local C=I:Dot(d);local U= tbl9 .curve; tbl9 .curvetrack= tbl9 .curvetrack or(setmetatable({},{__mode="k"}));local J= tbl9 .curvetrack[l];if not J then J={}; tbl9 .curvetrack[l]=J;end;l=K=="cfg"and"lastvcfg"or"lastv";K=J[l];J[l]=k;if K and K.Magnitude>0 and  clamp (K.Unit:Dot(d),-1,1)<0.96 then U.curving=tick();return true;end;local l,K,J,G= min (a/100,40),C-I:Dot((d-k).Unit),(p.Position-E).Magnitude, tbl3 .getping();local p=0.6-G/1000;local E=J/a-G/1000;local k=10- min (J/1000,10)+l;U.lerprad=U.lerprad+( rad ( asin ( clamp (C,-1,1)))-U.lerprad)*0.8;if J<(if a>100 and E>G/10 then( max (k-15,15))else k)then return false;end;if K<p then return true;end;if U.lerprad<0.018 then U.lastwarp=tick();end;if tick()-U.lastwarp<E/2 then return true;end;if tick()-U.curving<E/2 then return true;end;return C<p;end
		tbl3.aerohold = function(l)local K=tick();for p,E in pairs( tbl9 .aero)do if p.Parent then if K<E and p:GetAttribute("Ball")==l then return true;end;else  tbl9 .aero[p]=nil;end;end;return false;end
		tbl3.closingSpeed = function(l)local K= tbl3 .safehrp();if not K then return 0, huge ;end;local p= tbl3 .ballPos(l);if not p then return 0, huge ;end;local E,k= tbl3 .ballVel(l),K.Position-p;l=k.Magnitude;if l==0 or E.Magnitude==0 then return 0, huge ;end;p=E:Dot(k.Unit);if p<=0 then return p, huge ;end;return p, max ((l-4)/p,0);end
		tbl3.blockpress = function()return fn7(true)==true;end
		tbl9.dhold = tbl9.dhold or {}
		tbl3.holdparry = function(key,on)tbl9.dhold[key]=on and(clock()+12)or nil;end
		tbl3.holdactive = function()local t=clock();for k,e in pairs(tbl9.dhold)do if e>t then return true;end;tbl9.dhold[k]=nil;end;return false;end
		tbl9.trigstate = tbl9.trigstate or setmetatable({}, { __mode = "k" })

		tbl3.trigblocked = function(l)
			local c = localPlayer.Character
			local root = c and c.PrimaryPart
			if not root then return true end
			local slot = tbl3.hotslot("ability")
			local dur = slot and slot:FindFirstChild("Duration")
			local active = dur ~= nil and dur.Visible
			local ab = c:FindFirstChild("Abilities")
			local inf, hole, fury = ab and ab:FindFirstChild("Infinity"), ab and ab:FindFirstChild("Time Hole"), ab and ab:FindFirstChild("Slashes of Fury")
			if active and fury and fury.Enabled then return true end
			if tbl3.deflecting() then return true end
			if active and inf and inf.Enabled and tbl9.infball then return true end
			if active and hole and hole.Enabled then return true end
			if root:FindFirstChild("SingularityCape") then return true end
			if active and root:FindFirstChild("MaxShield") then return true end
			if l and tbl3.aerohold(l.Name) then return true end
			return false
		end

		tbl3.trigfire = function()
			if not tbl10.trigger then return false end
			return fn7() == true
		end

		tbl3.trigtry = function(l)
			if not tbl10.trigger or not l or not l.Parent or not tbl3.ballLive(l) then return end
			local st = tbl9.trigstate[l]
			if not st then st = { parried = false }; tbl9.trigstate[l] = st end
			local target = tbl3.ballTarget(l)
			if st.target ~= target then st.target = target; st.parried = false end
			if target ~= localPlayer.Name then st.parried = false return end
			if st.parried then return end
			local c = localPlayer.Character
			if not c or not c.PrimaryPart then return end
			if c.Parent ~= alive and not Workspace:FindFirstChild("TrainingBalls") then return end
			if toggles.trignospawn.Value then
				local from = l:GetAttribute("from")
				if not from or from == "" then return end
			end
			if tbl3.trigblocked(l) then return end
			local ms = options.trigdelay.Value or 0
			if toggles.trigrandom.Value then
				local lo, hi = options.trigrange.ValueMin or 0, options.trigrange.ValueMax or 200
				ms = math.random(math.floor(math.min(lo, hi)), math.floor(math.max(lo, hi)))
			end
			if ms <= 0 then
				st.parried = tbl3.trigfire()
				return
			end
			local token = {}
			st.parried = token
			task.delay(ms / 1000, function()
				if st.parried ~= token then return end
				if not tbl10.trigger or not l.Parent or not tbl3.ballLive(l) or tbl3.ballTarget(l) ~= localPlayer.Name or tbl3.trigblocked(l) then
					st.parried = false
					return
				end
				st.parried = tbl3.trigfire()
			end)
		end

		tbl3.trigupdate = function()
			if not tbl10.trigger then return end
			local balls = Workspace:FindFirstChild("Balls")
			if not balls then return end
			for _, l in ipairs(balls:GetChildren()) do tbl3.trigtry(l) end
		end

		tbl3.starttrigger = function()
			tbl3.stoptrigger()
			tbl9.trigstate = setmetatable({}, { __mode = "k" })
			local conn = RunService.PreSimulation:Connect(tbl3.trigupdate)
			tbl9.trigconns = { conn }
			tbl3.bind(conn)
			tbl3.trigupdate()
		end

		tbl3.stoptrigger = function()
			if tbl9.trigconns then
				for _, trigconn in ipairs(tbl9.trigconns) do
					trigconn:Disconnect()
				end
				tbl9.trigconns = nil
			end
			tbl9.trigstate = setmetatable({}, { __mode = "k" })
		end

		tbl9.al = tbl9.al or { curve_time = 0, tornado_time = 0, deathslash = false, timehole = false, fury = false, per_ball = setmetatable({}, { __mode = "k" }) }

		tbl3.aldivisor = function(acc)
			return 0.5 + (clamp(acc or tbl10.acc or 75, 1, 100) - 1) * 0.010101010101010102
		end

		tbl3.aldistance = function(speed, acc)
			return clamp(tbl3.getping() / 10 / 10, 5, 17) + max(speed / ((2.4 + min(max(speed - 9.5, 0), 650) * 0.002) * tbl3.aldivisor(acc)), 9.5)
		end

		tbl3.alpart = function(ball)
			if ball:IsA("BasePart") then
				return ball, nil
			end

			if ball:IsA("Model") then
				return ball:FindFirstChild("Corpo") or ball.PrimaryPart or ball:FindFirstChildWhichIsA("BasePart"), ball
			end

			return nil, nil
		end

		tbl3.alvel = function(part, model)
			if model then
				local v = model:GetAttribute("Velocity")

				if typeof(v) == "Vector3" then
					return v
				end
			end

			local z = part:FindFirstChild("zoomies")

			if z then
				return z.VectorVelocity
			end

			return part.AssemblyLinearVelocity
		end

		tbl3.altornado = function(part)
			local al = tbl9.al
			local vfx = part:FindFirstChild("AeroDynamicSlashVFX")

			if vfx then
				pcall(function()
					vfx:Destroy()
				end)

				al.tornado_time = clock()
			end

			local rt = al.runtime

			if not rt or not rt.Parent then
				rt = Workspace:FindFirstChild("Runtime")
				al.runtime = rt
			end

			local tornado = rt and rt:FindFirstChild("Tornado")

			if tornado then
				local dur = tornado:GetAttribute("TornadoTime") or 1

				if clock() - al.tornado_time < dur + 0.314159 then
					return true
				end
			end

			return false
		end

		tbl3.aliscurved = function(ball, pos, vel, speed, dist)
			speed = speed or vel.Magnitude

			if speed < 1 then
				return false, false
			end

			local al = tbl9.al
			local bpos = ball.Position
			dist = dist or (pos - bpos).Magnitude
			local inv = 1 / speed
			local dir = vel * inv
			local toMe = (pos - bpos).Unit
			local dot = toMe:Dot(dir)
			local behind = dot < 0
			local ping = tbl3.getping()
			local pingS = ping * 0.001
			local spdTerm = min(speed * 0.01, 40)
			local closing = dot > 0 and 40 * dot or 0
			local dev = dot - toMe:Dot((dir - vel).Unit)
			local lim = 0.5 - pingS
			local tmin = (dist * inv - pingS) / 1.5
			local base = 15 - min(dist * 0.001, 15) + closing + spdTerm
			local st = al.per_ball[ball]

			if not st then
				st = { vel = {}, last_warping = 0, lerp = 0 }
				al.per_ball[ball] = st
			end

			local hist = st.vel
			local n = #hist

			if n >= 4 then
				hist[1], hist[2], hist[3] = hist[2], hist[3], hist[4]
				hist[4] = vel
				n = 4
			else
				n += 1
				hist[n] = vel
			end

			local threshold = base

			if speed > 100 and dist * inv - pingS > ping * 0.1 then
				threshold = max(base - 15, 15)
			end

			if dist < threshold then
				return false, behind
			end

			local now = clock()

			if now - al.curve_time < tmin then
				return true, behind
			end

			if dev < lim then
				return true, behind
			end

			local ang = rad(asin(clamp(dot, -1, 1)))
			st.lerp = st.lerp + (ang - st.lerp) * 0.8

			if st.lerp < 0.018 then
				st.last_warping = now
			end

			if now - st.last_warping < tmin then
				return true, behind
			end

			if n == 4 then
				if dot - toMe:Dot((dir - hist[1].Unit).Unit) < lim then
					return true, behind
				end

				if dot - toMe:Dot((dir - hist[2].Unit).Unit) < lim then
					return true, behind
				end
			end

			return dot < lim, behind
		end

		tbl3.flickpre = function(part, myPos, vel, dist, thr)
			if not (toggles.camflick and toggles.camflick.Value and toggles.camflickrand and toggles.camflickrand.Value) then return end
			local so = toggles.camflickstandoff
			if so and so.Value and not (tbl9 and tbl9.standoff == true) then return end
			if os.clock() - (tbl9.preflickT or 0) < 0.5 then return end
			local toMe = myPos - part.Position
			if toMe.Magnitude < 0.001 then return end
			local closing = vel:Dot(toMe.Unit)
			if closing < 5 then return end
			local tt = (dist - thr) / closing
			if tt > tbl3.flickParams().inT + 0.008 then return end
			tbl9.preflickT = os.clock()
			local payload = tbl3.parryPayload(tbl10.crv)
			if tbl3.camflick(payload, nil, true) then
				tbl3.flickprepay = { cf = payload[2], t = os.clock() }
			end
		end

		tbl3.alhandle = function(ball, char, root, myPos)
			local al = tbl9.al
			local st = tbl3.ballstate[ball]

			if not st then
				st = { parried = false, lasttarget = nil }
				tbl3.ballstate[ball] = st
			end

			if not st.hooked then
				st.hooked = true
				local cons = {}

				cons[#cons + 1] = ball:GetAttributeChangedSignal("target"):Connect(function()
					st.parried = false
					st.drbl = false
					st.preclick = false
				end)

				local function watch(v)
					if v and v:IsA("ObjectValue") then
						cons[#cons + 1] = v.Changed:Connect(function()
							st.parried = false
						end)
					end
				end

				watch(ball:FindFirstChild("CollisionWhitelist"))

				cons[#cons + 1] = ball.ChildAdded:Connect(function(c)
					if c.Name == "CollisionWhitelist" then
						watch(c)
					end
				end)

				ball.Destroying:Once(function()
					for _, c in ipairs(cons) do
						c:Disconnect()
					end

					tbl3.ballstate[ball] = nil
				end)
			end

			st.lasttarget = tbl3.ballTarget(ball)

			if st.parried then
				return
			end

			local part, model = tbl3.alpart(ball)

			if not part then
				return
			end

			if part:FindFirstChild("ComboCounter") then
				return
			end

			if tbl3.altornado(part) then
				return
			end

			if tbl9.infball or al.deathslash or al.fury or al.timehole then
				return
			end

			local vel = tbl3.alvel(part, model)
			local speed = vel.Magnitude
			local dist = (part.Position - myPos).Magnitude

			if speed >= 40 then
				local curved, behind = tbl3.aliscurved(part, myPos, vel, speed, dist)

				if curved or behind then
					return
				end
			end

			local thr = tbl3.aldistance(speed, tbl10.acc) + (tbl10.rng or 0)
			if dist > thr then
				pcall(tbl3.flickpre, part, myPos, vel, dist, thr)
				return
			end

			local sword = char:GetAttribute("CurrentlyEquippedSword")

			local chained = clock() - tbl9.lastparry <= 0.5

			if tbl10.animfix and not str:find("xeno", 1, true) and sword ~= "New Years Greatsword" and not chained then
				tbl3.playgrab()
			end

			if fn7() then
				if chained and toggles.manualanim and toggles.manualanim.Value then
					tbl3.manimPlay()
				end

				local now = clock()
				tbl9.lastparry = now
				tbl9.lastapfire = now
				st.lastparry = now
				st.parried = true

				task.spawn(function()
					repeat
						RunService.Heartbeat:Wait()
					until clock() - now >= 1 or not st.parried

					st.parried = false
				end)
			end
		end

		tbl3.parryTick = function()
			if not tbl10.autoparry then
				return
			end

			if tbl10.trigger then
				return
			end

			if tbl9.phactive then
				return
			end

			local char = localPlayer.Character

			if not char then
				return
			end

			if char.Parent ~= alive and not Workspace:FindFirstChild("TrainingBalls") then
				return
			end

			local root = char:FindFirstChild("HumanoidRootPart")

			if not root then
				return
			end

			local hum = char:FindFirstChildOfClass("Humanoid")

			if not hum or hum.Health <= 0 then
				return
			end

			if char.PrimaryPart and char.PrimaryPart:FindFirstChild("SingularityCape") then
				return
			end

			if tbl3.deflecting() then
				return
			end

			local me = localPlayer.Name
			local myPos = root.Position

			for _, ball in ipairs(tbl3.ballList()) do
				if tbl3.ballTarget(ball) == me then
					tbl3.alhandle(ball, char, root, myPos)
				end
			end
		end

		tbl3.alsetup = function()
			local al = tbl9.al

			if al.setup then
				return
			end

			al.setup = true

			tbl3.bindt(task.spawn(function()
				local remotes = ReplicatedStorage:WaitForChild("Remotes", 10)

				if not remotes then
					return
				end

				local function hook(name, fn)
					local ev = remotes:FindFirstChild(name) or remotes:WaitForChild(name, 5)

					if ev and ev:IsA("RemoteEvent") then
						tbl3.bind(ev.OnClientEvent:Connect(fn))
					end
				end

				hook("DeathBall", function(_, on)
					al.deathslash = on or false
				end)

				hook("ParrySuccessAll", function(_, who)
					local c = localPlayer.Character
					local rp = c and c.PrimaryPart
					local balls = Workspace:FindFirstChild("Balls")

					if not rp or not balls then
						return
					end

					for _, b in ipairs(balls:GetChildren()) do
						if b:IsA("BasePart") then
							local z = b:FindFirstChild("zoomies")

							if z then
								local spd = z.VectorVelocity.Magnitude
								local dist = (rp.Position - b.Position).Magnitude
								local ping = tbl3.getping()
								local t = dist / max(spd, 1) - ping / 1000
								local th = 15 - min(dist / 1000, 15) + min(spd / 100, 40)

								if spd > 1 and ping / 10 < t then
									th = max(th - 15, 15)
								end

								if who == rp then
									break
								end

								if not (th < dist) then
									break
								end

								al.curve_time = clock()
								break
							end
						end
					end
				end)

				hook("ParrySuccess", function()
					if not tbl10.autoparry then
						return
					end

					local any = false

					for _, s in pairs(tbl3.ballstate) do
						if s.parried then
							any = true
							break
						end
					end

					if not any then
						return
					end

					task.delay(0.15, function()
						local aliveFolder = Workspace:FindFirstChild("Alive")
						local allInvis = false

						if aliveFolder then
							local seen = false
							allInvis = true

							for _, m in ipairs(aliveFolder:GetChildren()) do
								if m.Name ~= localPlayer.Name then
									seen = true
									local pl = Players:FindFirstChild(m.Name)

									if not pl or pl:GetAttribute("CurrentlyEquippedAbility") ~= "Invisibility" or not m:GetAttribute("AbilityActive") then
										allInvis = false
										break
									end
								end
							end

							if not seen then
								allInvis = false
							end
						end

						if allInvis then
							local myName = localPlayer.Name

							for b, s in pairs(tbl3.ballstate) do
								if tbl3.ballTarget(b) == myName then
									s.parried = false
								end
							end
						end
					end)
				end)
			end))

			al.timehole = localPlayer:GetAttribute("TimeHoleActivate") ~= nil

			tbl3.bind(localPlayer.AttributeChanged:Connect(function(name)
				if name == "TimeHoleActivate" then
					al.timehole = localPlayer:GetAttribute("TimeHoleActivate") ~= nil
				end
			end))

			local function bindChar(c)
				if al.furyconn then
					al.furyconn:Disconnect()
					al.furyconn = nil
				end

				al.fury = false

				if not c then
					return
				end

				al.furyconn = tbl3.bind(c.AttributeChanged:Connect(function(name)
					if name == "AbilityActive" then
						al.fury = localPlayer:GetAttribute("CurrentlyEquippedAbility") == "Slashes of Fury" and c:GetAttribute("AbilityActive") == true
					end
				end))
			end

			bindChar(localPlayer.Character)
			tbl3.bind(localPlayer.CharacterAdded:Connect(bindChar))
		end

		tbl3.alsetup()
	end

	tbl3.apsignals = function()
		local tbl11 = {}

		for _, v3 in ipairs({ "PreRender", "PreAnimation", "PreSimulation", "PostSimulation" }) do
			local v4 = RunService[v3]

			if typeof(v4) == "RBXScriptSignal" then
				tbl11[#tbl11 + 1] = v4
			end
		end

		if #tbl11 == 0 then
			tbl11[1] = RunService.PreSimulation
		end

		return tbl11
	end

	tbl3.startap = function()
		tbl3.stopap()
		tbl9.apconns = {}
		tbl9.apstep = -huge
		local function fn7()local l= clock ();if l- tbl9 .apstep<2.5E-4 then return;end; tbl9 .apstep=l; tbl3 .parryTick();end

		for _, v3 in ipairs(tbl3.apsignals()) do
			local connection = v3:Connect(fn7)
			tbl9.apconns[#tbl9.apconns + 1] = connection
			tbl3.bind(connection)
		end
	end

	tbl3.stopap = function()
		if tbl9.apconns then
			for _, apconn in ipairs(tbl9.apconns) do
				apconn:Disconnect()
			end

			tbl9.apconns = nil
		end
	end

	local v3 = nil
	tbl3.closestplr = function()local l= tbl3 .safechar();if not l or not  alive then  v3 =nil;return nil;end;local K=l.PrimaryPart or(l:FindFirstChild("HumanoidRootPart"));if not K then  v3 =nil;return nil;end;local p,E= huge ;for k,k in ipairs( alive :GetChildren())do if k.PrimaryPart and( tbl3 .validtgt(k))then l=(k.PrimaryPart.Position-K.Position).Magnitude;if l<p then p,E=l,k;end;end;end; v3 =E;return E;end
	tbl3.firespam = function()if not  tbl3 .anyparry()then return false;end;if not  tbl3 .isalive()then return false;end;if  tbl10 .keyparry then  tbl3 .keyparry();elseif  tbl8 .rem and  tbl8 .sgn and  tbl8 .signHolder and  tbl8 .signHash then local l,K= tbl3 .parryPayload( tbl10 .crv), tbl8 .signKey();local p=K and( tbl8 .s1(K));if not p then  tbl3 .logwev("fireSpamParry",5,"fireSpamParry","parry sign failed"); tbl3 .parryfallback();return false;end; tbl8 .rem:FireServer( tbl8 .signHash,K,p, tbl3 .parryArgs(l));else  tbl3 .logwev("fireSpamParry",5,"fireSpamParry","parry remote/signer unavailable");if  tbl8 .ensure then  tbl8 .ensure();end; tbl3 .parryfallback();return false;end;if( tbl9 .parries or 0)>=7 then return false;end; tbl9 .parries=( tbl9 .parries or 0)+1;task.delay(0.5,function()if( tbl9 .parries or 0)>0 then  tbl9 .parries= tbl9 .parries-1;end;end);if  tbl10 .hum then  tbl3 .humroll();end;return true;end
	tbl3.spamreset = function()
		tbl9.asat = nil
		tbl9.ascarry = 0
		tbl9.astime = nil
		tbl9.spamball = nil
		tbl9.spamtgt = nil
		tbl9.spamfires = {}
	end

	tbl3.spamTick = function()
		local now = clock()
		local dt = min(now - (tbl9.astime or now), 0.066666666666666666)
		tbl9.astime = now

		local model = localPlayer.Character
		if not model or not alive or model.Parent ~= alive then return end
		local root = model.PrimaryPart
		if not root then return end
		if tbl3.deflecting() then return end
		if root:FindFirstChild("SingularityCape") then return end
		local abilities, abilActive = model:FindFirstChild("Abilities"), tbl3.abact(model)
		local fury = abilities and abilities:FindFirstChild("Slashes of Fury")
		if abilActive and fury and fury.Enabled then return end

		local balls = tbl3.ballList()
		if #balls == 0 then return end

		local myName = localPlayer.Name
		local ball = tbl3.getball()
		if ball and tbl3.ballTarget(ball) ~= myName then ball = nil end
		ball = ball or tbl9.spamball
		if ball and not table.find(balls, ball) then
			tbl9.spamball = nil
			tbl9.spamtgt = nil
			ball = nil
		end
		if not ball or not tbl3.ballLive(ball) then return end
		if tbl3.aerohold(ball.Name) then return end

		local target = tbl3.ballTarget(ball)
		if not target then return end
		local speed = tbl3.ballVel(ball).Magnitude
		local ping = tbl3.getping()
		local openError = min(0.3 + ping / 1000, 0.5)
		local bestPair = now - (tbl9.asat or 0) <= openError
		if model:GetAttribute("Pulsed") then return end
		if speed < 0.001 then return end

		local myPos = root.Position
		local ballPos = tbl3.ballPos(ball)
		if not ballPos then return end
		local dist = (myPos - ballPos).Magnitude
		if dist < 0.1 then return end

		local from = target == myName and ball:GetAttribute("from") or target
		local cell
		if type(from) == "string" and from ~= myName then
			local c = alive:FindFirstChild(from)
			local p = c and (c.PrimaryPart or c:FindFirstChild("HumanoidRootPart"))
			if p then cell = (myPos - p.Position).Magnitude end
		end
		if not cell then
			local near = tbl3.closestplr()
			local p = near and (near.PrimaryPart or near:FindFirstChild("HumanoidRootPart"))
			cell = p and (myPos - p.Position).Magnitude or huge
		end
		if cell == huge then return end

		if target == myName then
			tbl9.spamtgt = now
		else
			local since = now - (tbl9.spamtgt or 0)
			if (bestPair and openError or min(0.15 + ping / 2000, 0.25)) < since then return end
		end

		local step = clamp(10 + ping / 10, 10, 35)
		local extra = #balls >= 2 and 3 or 0
		local endPos = min(0.5 + ping / 1000, 0.75)
		local far = step + min(speed / 6, 95) + extra
		local near = step + min(speed / 6, 30) + extra
		local pinned = cell <= near and dist <= far
		local need = 1
		if pinned and not bestPair then
			if toggles.dynamicspam and toggles.dynamicspam.Value then
				need = clamp(math.ceil(min(max(cell / near, dist / far), 2 * max(cell, dist) / speed * endPos) * 3), 1, 3)
			else
				need = clamp(floor((options.spamthreshold and options.spamthreshold.Value or 2) + 0.5), 1, 4)
			end
		end
		if not pinned then return end
		if target == myName and cell > 30 and dist > 30 then return end

		local fires = tbl9.spamfires
		if not fires then fires = {} tbl9.spamfires = fires end
		while fires[1] and fires[1] < now - 0.5 do table.remove(fires, 1) end
		local recent = max(0, (tbl9.parries or 0) - #fires)
		if not bestPair and recent < need then return end

		tbl9.asat = now
		tbl9.ascarry = (tbl9.ascarry or 0) + max(dt * 120 - 1, 0)
		local extraFires = min(floor(tbl9.ascarry), 7)
		tbl9.ascarry = min(tbl9.ascarry - extraFires, 7)
		local fired = false
		for _ = 1, extraFires + 1 do
			local before = tbl9.parries or 0
			if tbl3.firespam() then fired = true end
			if (tbl9.parries or 0) > before then fires[#fires + 1] = now end
		end
		if toggles.manualanim and toggles.manualanim.Value then
			tbl3.manimPlay()
		end
	end

	tbl3.startas = function()
		if tbl9.asconn then
			tbl9.asconn:Disconnect()
		end

		tbl9.asconn = RunService.PreSimulation:Connect(function()if not  tbl10 .autospam then return;end; tbl3 .spamTick();end)
		tbl3.bind(tbl9.asconn)
	end

	tbl3.stopas = function()
		if tbl9.asconn then
			tbl9.asconn:Disconnect()
			tbl9.asconn = nil
		end
		tbl3.spamreset()
	end

	local v4 = nil
	tbl3.setmsactive = function(arg)
		tbl9.msactive = arg == true
	end

	tbl3.showmsui = function()
		return false
	end

	tbl3.delmsgui = function() end
	tbl3.msgui = function() end
	tbl3.refmsui = function() end

	tbl3.startmskey = function() end

	tbl9.manimCache = {}
	tbl9.manimLast = 0
	tbl9.manimSucc = false

	tbl3.manimStop = function(track)
		pcall(function()
			track:Stop(track:GetAttribute("StopFadeTime") or 0.1)
		end)
	end

	tbl3.manimGet = function(swordName)
		local shared = ReplicatedStorage:FindFirstChild("Shared")
		local swordApi = shared and shared:FindFirstChild("SwordAPI")
		local collection = swordApi and swordApi:FindFirstChild("Collection")
		if not collection then
			return nil
		end
		local defaultFolder = collection:FindFirstChild("Default")
		local default = defaultFolder and defaultFolder:FindFirstChild("GrabParry")
		if not swordName or swordName == "" then
			return default
		end
		if tbl9.manimCache[swordName] then
			return tbl9.manimCache[swordName]
		end
		local ok, data = pcall(function()
			return shared.ReplicatedInstances.Swords.GetSword:Invoke(swordName)
		end)
		if ok and type(data) == "table" and data.AnimationType then
			for _, obj in ipairs(collection:GetChildren()) do
				if obj.Name == data.AnimationType then
					local anim = obj:FindFirstChild("GrabParry") or obj:FindFirstChild("Grab")
					if anim then
						tbl9.manimCache[swordName] = anim
						return anim
					end
				end
			end
		end
		tbl9.manimCache[swordName] = default
		return default
	end

	tbl3.manimPlay = function()
		if not ((os.clock() - tbl9.manimLast) >= 0.2 or tbl9.manimSucc) then
			return
		end
		tbl9.manimLast = os.clock()
		tbl9.manimSucc = false
		local char = localPlayer.Character
		local hum = char and char:FindFirstChildOfClass("Humanoid")
		local animator = hum and hum:FindFirstChildOfClass("Animator")
		if not animator then
			return
		end
		local anim = tbl3.manimGet(char:GetAttribute("CurrentlyEquippedSword"))
		if not anim then
			return
		end
		for _, track in ipairs(animator:GetPlayingAnimationTracks()) do
			if track.Name == "GrabParry" or track.Name == "Grab" then
				track.TimePosition = 0
				tbl3.manimStop(track)
			elseif track.Name == "SuccessParry" or track.Name == "Success" then
				tbl3.manimStop(track)
			end
		end
		local track = animator:LoadAnimation(anim)
		pcall(function()
			track:Play(
				track:GetAttribute("PlayFadeTime") or 0,
				track:GetAttribute("PlayWeight") or 1,
				track:GetAttribute("PlaySpeed") or 1
			)
		end)
	end

	pcall(function()
		local remotes = ReplicatedStorage:FindFirstChild("Remotes")
		local ev = remotes and remotes:FindFirstChild("ParrySuccessAll")
		if ev then
			tbl3.bind(ev.OnClientEvent:Connect(function()
				tbl9.manimSucc = true
				local char = localPlayer.Character
				local hum = char and char:FindFirstChildOfClass("Humanoid")
				local animator = hum and hum:FindFirstChildOfClass("Animator")
				if not animator then
					return
				end
				for _, track in ipairs(animator:GetPlayingAnimationTracks()) do
					if track.Name == "GrabParry" or track.Name == "Grab" then
						tbl3.manimStop(track)
					end
				end
			end))
		end
	end)

	tbl3.startms = function()
		tbl3.startmskey()

		if tbl9.msconn then
			tbl9.msconn:Disconnect()
		end

		tbl9.msconn = RunService.PreSimulation:Connect(function()if not  tbl10 .manspam or not  tbl9 .msactive then return;end;if not  tbl3 .isalive()then return;end;local l= tbl3 .getball();if not l or not  tbl3 .ballLive(l)then return;end; tbl3 .firespam();if toggles.manualanim and toggles.manualanim.Value then  tbl3 .manimPlay();end;end)
		tbl3.bind(tbl9.msconn)
	end

	tbl3.setnorender = function()
		local disabled = tbl10.norender == true
		local playerScripts = localPlayer:FindFirstChild("PlayerScripts")
		playerScripts = playerScripts and playerScripts:FindFirstChild("EffectScripts")
		playerScripts = playerScripts and playerScripts:FindFirstChild("ClientFX")

		if playerScripts then
			playerScripts.Disabled = disabled
		end

		if disabled then
			if not tbl9.norenderconn then
				local runtime = Workspace:FindFirstChild("Runtime")

				if runtime then
					tbl9.norenderconn = runtime.ChildAdded:Connect(function(l)if l.Name=="FinisherCameraRig"then return;end; Debris :AddItem(l,0);end)
					tbl3.bind(tbl9.norenderconn)
				end
			end
		elseif tbl9.norenderconn then
			tbl9.norenderconn:Disconnect()
			tbl9.norenderconn = nil
		end
	end

	tbl3.setnocd = function()
		local shared = ReplicatedStorage:FindFirstChild("Shared")
		shared = shared and shared:FindFirstChild("Abilities")
		shared = shared and shared:FindFirstChild("Thunder Dash")
		if not shared then
			return
		end
		local module = require(shared)
		if type(module) ~= "table" then
			return
		end

		if not tbl9.nocdsave then
			tbl9.nocdsave = {
				cd = rawget(module, "cooldown"),
				red = rawget(module, "cooldownReductionPerUpgrade"),
				can = rawget(module, "canBeUsed"),
				act = rawget(module, "localOwnerActivation"),
			}
		end

		local nocdsave = tbl9.nocdsave

		if not tbl10.thundernocd then
			module.cooldown = nocdsave.cd
			module.cooldownReductionPerUpgrade = nocdsave.red
			module.canBeUsed = nocdsave.can
			module.localOwnerActivation = nocdsave.act
			return
		end

		module.cooldown = 0
		module.cooldownReductionPerUpgrade = 0

		module.canBeUsed = function()
			return true
		end

		if nocdsave.act then
			module.localOwnerActivation = function(...)
				module.cooldown = 0
				return nocdsave.act(...)
			end
		end
	end

	tbl3.stopms = function()
		if tbl9.msconn then
			tbl9.msconn:Disconnect()
			tbl9.msconn = nil
		end

		tbl3.setmsactive(false)
	end

	local tbl11 = {
		"AbilityBlockedByLTM",
		"AbilityBlockedByRanked",
		"AbilityBlockedByNoAbilityDuel",
		"AbilityBlockedByNoAbilityRanked",
		"AbilityBlockedByDungeons",
		"AbilityBlockedByRegionalTournament",
		"HuntPS",
	}

	tbl3.abilblocked = function(l)for K,K in ipairs( tbl11 )do if l:GetAttribute(K)then return true;end;end;local h=l.GetAttributes(l);if type(h)=="table"then for l,K in pairs(h)do if K==true and type(l)=="string"and l:sub(1,12)=="AbilityLock_"then return true;end;end;end;return false;end
	tbl3.metaabil = { Pull = true, Telekinesis = true, ["Phase Bypass"] = true, ["Raging Deflection"] = true }

	local tbl12 = {
		"Calming Deflection",
		"Raging Deflection",
		"Rapture",
		"Aerodynamic Slash",
		"Forcefield",
		"Infinity",
		"Fracture",
		"Invisibility",
		"Ninja Dash",
	}

	tbl3.abilrdy = function(l)local K= tbl3 .hotslot("ability");if not K then return false;end;local p=K:FindFirstChild("Red");if p and p.Visible then return false;end;p=K:FindFirstChild("UIGradient");if p then return p.Offset.Y>=0.5;end;return(l and(l:GetAttribute("CooldownExpiration"))or 0)- Workspace :GetServerTimeNow()<=0;end
	tbl3.parrydown = function()local l= tbl3 .hotslot("block");local K=l and(l:FindFirstChild("UIGradient"));if K then return K.Offset.Y<0.45;end;if not  tbl9 .noblockgrad then  tbl9 .noblockgrad=true; tbl3 .logwev("blockgrad",60,"cooldown protection","Hotbar.Block has no UIGradient - using parry timing instead");end;return( tbl9 .parries or 0)>0 and  clock ()-( tbl9 .lastparry or 0)<0.5+ min ( tbl3 .getping()/1000,0.5);end
	tbl3.usableabil = function(l)local K=l:FindFirstChild("Abilities");if not K then return nil;end;if not  tbl3 .abilrdy(l)then return nil;end;for l,p in ipairs( tbl12 )do l=K:FindFirstChild(p);if l and l.Enabled then return p;end;end;return nil;end
	tbl3.fireabil = function()local l= ReplicatedStorage :FindFirstChild("Remotes");local K=l and(l:FindFirstChild("AbilityButtonPress"));if K and(K:IsA("BindableEvent"))then K:Fire();return true;end; tbl3 .logwev("abilitypress",5,"AbilityButtonPress bindable not found");return false;end

	tbl3.startabil = function()
		if tbl9.abilconn then
			tbl9.abilconn:Disconnect()
		end

		tbl9.abilconn = RunService.PreSimulation:Connect(function()if not  tbl10 .autoabil and not  tbl10 .cdprot then return;end;local l= localPlayer .Character;if not l or not  alive or l.Parent~= alive then return;end;local K=l.PrimaryPart;if not K then return;end;local p=nil;for E,E in ipairs( tbl3 .ballList())do if  tbl3 .ballTarget(E)== localPlayer .Name then p=E;break;end;end;if not p then  tbl9 .abilball=nil;return;end;if  tbl9 .abilball==p then return;end;if not  tbl3 .ballLive(p)then return;end;if  clock ()- tbl9 .lastparry<=0.5 then return;end;local E= tbl3 .usableabil(l);if not E then return;end;if  tbl3 .abilblocked(l)then if  tbl10 .autoabil and not  tbl9 .ablnoted then  tbl9 .ablnoted=true; tbl3 .notif("Auto Ability","This mode blocks abilities. Auto Ability is off.",4);end;return;end; tbl9 .ablnoted=false;local k,a= tbl3 .abact(l),l:FindFirstChild("Abilities");local d,I=a and(a:FindFirstChild("Infinity")),a and(a:FindFirstChild("Time Hole"));if k and d and d.Enabled and  tbl9 .infball then return;end;if k and I and I.Enabled then return;end;if K:FindFirstChild("SingularityCape")then return;end;a= tbl3 .ballVel(p);k=a.Magnitude;if  tbl3 .closingSpeed(p)<=3 then return;end;d= tbl3 .parrydown();local C= tbl10 .cdprot and d;if not C then if not  tbl10 .autoabil then return;end;if k<( tbl10 .abilspd or 0)then return;end;end;d= tbl3 .getping();I=(2.349756274912749+ clamp (k,0,1000)*0.002)* tbl3 .accbase();local U,J= clamp (d/10,5,17)+k/I+ tbl10 .rng+12, tbl3 .ballPos(p);local k=J and(K.Position-J).Magnitude or  huge ;if(if J then( min (k,(K.Position-(J+a* clamp (d/1000,0,0.28))).Magnitude))else k)>U then return;end;if  tbl3 .fireabil()then if E=="Raging Deflection"or E=="Rapture"then  tbl9 .defcast= clock ()+0.8;end;local K=l:GetAttribute("CooldownExpiration")or 0;if E~="Ninja Dash"and E~="Invisibility"then local l= tbl3 .ballstate[p];if not l then l={parried=false,lasttarget=nil}; tbl3 .ballstate[p]=l;end;l.parried=true;l.lastparry= clock (); tbl3 .bindt(task.delay(0.45,function()l.parried=false;end));end;if not  tbl3 .esptotal( localPlayer ,E)then  tbl9 .abilball=p;else  tbl3 .bindt(task.delay(0.25,function()local l= tbl3 .safechar();if l and(l:GetAttribute("CooldownExpiration")or 0)>K then  tbl9 .abilball=p;if C then  tbl3 .notif("Auto Ability",E.." used while parry was on cooldown.",3);end;end;end));end;end;end)
		tbl3.bind(tbl9.abilconn)
	end

	tbl3.stopabil = function()
		if tbl9.abilconn then
			tbl9.abilconn:Disconnect()
			tbl9.abilconn = nil
		end

		tbl9.abilball = nil
	end

	tbl3.rbcol = function(h)return Color3.fromHSV(tick()*(h or 0.2)%1,1,1);end
	tbl3.btcol = function()if  tbl10 .btrb then local l= tbl3 .rbcol(0.3);return ColorSequence.new(l,l);end;return ColorSequence.new({ColorSequenceKeypoint.new(0, tbl10 .btstart),ColorSequenceKeypoint.new(1, tbl10 .btend)});end
	tbl3.refbt = function()local l= Workspace :FindFirstChild("Balls");if not l then return;end;local K= tbl3 .btcol();for p,E in ipairs(l:GetChildren())do p=E:FindFirstChild("_atrail");if p then p.Color=K;p.Lifetime= tbl10 .btlife;p.WidthScale=NumberSequence.new({NumberSequenceKeypoint.new(0, tbl10 .btwidth),NumberSequenceKeypoint.new(0.5, tbl10 .btwidth*0.6),NumberSequenceKeypoint.new(1,0)});end;p=E:FindFirstChild("_atglow");if p and(p:IsA("Trail"))then p.Enabled= tbl10 .btglow;p.Color=K;p.Lifetime= tbl10 .btlife*1.35;p.WidthScale=NumberSequence.new({NumberSequenceKeypoint.new(0, tbl10 .btwidth*3),NumberSequenceKeypoint.new(0.4, tbl10 .btwidth*2),NumberSequenceKeypoint.new(1,0)});end;p=E:FindFirstChild("_atparticle");if p then p.Enabled= tbl10 .btpart;p.Color=K;end;p=E:FindFirstChild("_atspark");if p then p.Enabled= tbl10 .btpart;p.Color=ColorSequence.new( tbl10 .btrb and( tbl3 .rbcol(0.45))or  tbl10 .btend);end;end;end
	tbl3.addbt = function(l)if not l or not l:IsA("BasePart")then return;end;if l:FindFirstChild("_atrail")then return;end;local K=Instance.new("Attachment");K.Name="_atrailA";K.Position=Vector3.new(0,0.5,0);K.Parent=l;local p=Instance.new("Attachment");p.Name="_atrailB";p.Position=Vector3.new(0,-0.5,0);p.Parent=l;local E=Instance.new("Trail");E.Name="_atrail";E.Attachment0=K;E.Attachment1=p;E.Lifetime= tbl10 .btlife;E.FaceCamera=true;E.LightEmission=1;E.LightInfluence=0;E.WidthScale=NumberSequence.new({NumberSequenceKeypoint.new(0, tbl10 .btwidth),NumberSequenceKeypoint.new(0.5, tbl10 .btwidth*0.6),NumberSequenceKeypoint.new(1,0)});E.Color= tbl3 .btcol();E.Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,0.05),NumberSequenceKeypoint.new(0.6,0.4),NumberSequenceKeypoint.new(1,1)});E.Parent=l;E=Instance.new("Trail");E.Name="_atglow";E.Attachment0=K;E.Attachment1=p;E.Lifetime= tbl10 .btlife*1.35;E.FaceCamera=true;E.LightEmission=1;E.LightInfluence=0;E.WidthScale=NumberSequence.new({NumberSequenceKeypoint.new(0, tbl10 .btwidth*3),NumberSequenceKeypoint.new(0.4, tbl10 .btwidth*2),NumberSequenceKeypoint.new(1,0)});E.Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,0.55),NumberSequenceKeypoint.new(0.5,0.75),NumberSequenceKeypoint.new(1,1)});E.Color= tbl3 .btcol();E.Enabled= tbl10 .btglow;E.Parent=l;E=Instance.new("ParticleEmitter");E.Name="_atparticle";E.Rate=260;E.Lifetime=NumberRange.new(0.45,0.9);E.Speed=NumberRange.new(6,16);E.SpreadAngle=Vector2.new(180,180);E.Drag=3;E.Rotation=NumberRange.new(0,360);E.RotSpeed=NumberRange.new(-160,160);E.Size=NumberSequence.new({NumberSequenceKeypoint.new(0,0),NumberSequenceKeypoint.new(0.15,1.5),NumberSequenceKeypoint.new(1,0)});E.Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,0.15),NumberSequenceKeypoint.new(0.7,0.45),NumberSequenceKeypoint.new(1,1)});E.Color= tbl3 .btcol();E.LightEmission=1;E.LightInfluence=0;E.Brightness=3;E.Enabled= tbl10 .btpart;E.Parent=l;p=Instance.new("ParticleEmitter");p.Name="_atspark";p.Rate=90;p.Lifetime=NumberRange.new(0.25,0.5);p.Speed=NumberRange.new(18,34);p.SpreadAngle=Vector2.new(180,180);p.Drag=6;p.Size=NumberSequence.new({NumberSequenceKeypoint.new(0,0.45),NumberSequenceKeypoint.new(1,0)});p.Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,0),NumberSequenceKeypoint.new(1,1)});p.Color=ColorSequence.new( tbl10 .btend);p.LightEmission=1;p.LightInfluence=0;p.Brightness=5;p.Enabled= tbl10 .btpart;p.Parent=l;end
	tbl3.applybt = function()if not  tbl10 .bt then return;end;for l,l in ipairs( tbl3 .ballList())do  tbl3 .addbt(l);end;if  tbl10 .btrb then  tbl3 .refbt();end;end

	tbl3.clrbt = function()
		local balls = Workspace:FindFirstChild("Balls")
		if not balls then
			return
		end

		for _, child in ipairs(balls:GetChildren()) do
			for _, v5 in ipairs({ "_atrail", "_atrailA", "_atrailB", "_atglow", "_atparticle", "_atspark" }) do
				local v6 = child:FindFirstChild(v5)

				if v6 then
					v6:Destroy()
				end
			end
		end
	end

	tbl3.ptcol = function()if  tbl10 .ptrb then local l= tbl3 .rbcol(0.4);return ColorSequence.new(l,l);end;return ColorSequence.new( tbl10 .ptcol, tbl10 .ptcol);end

	tbl3.applypt = function()
		if not tbl10.pt then
			return
		end
		local v5 = tbl3.safechar()
		if not v5 then
			return
		end
		local humanoidRootPart = v5:FindFirstChild("HumanoidRootPart")
		if not humanoidRootPart then
			return
		end

		for _, v6 in ipairs({ "_ptrail", "_ptrailA", "_ptrailB" }) do
			local v7 = humanoidRootPart:FindFirstChild(v6)

			if v7 then
				v7:Destroy()
			end
		end

		local attachment = Instance.new("Attachment")
		attachment.Name = "_ptrailA"
		attachment.Position = Vector3.new(0, 1.5, 0)
		attachment.Parent = humanoidRootPart
		local attachment2 = Instance.new("Attachment")
		attachment2.Name = "_ptrailB"
		attachment2.Position = Vector3.new(0, -1.5, 0)
		attachment2.Parent = humanoidRootPart
		local trail = Instance.new("Trail")
		trail.Name = "_ptrail"
		trail.Attachment0 = attachment
		trail.Attachment1 = attachment2
		trail.Lifetime = tbl10.ptlife
		trail.FaceCamera = true
		trail.LightEmission = 1
		trail.WidthScale = NumberSequence.new(tbl10.ptwidth)
		local new = NumberSequenceKeypoint.new
		trail.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), new(1, 1) })
		trail.Color = tbl3.ptcol()
		trail.Parent = humanoidRootPart
	end

	tbl3.refpt = function()local l= tbl3 .safechar();if not l then return;end;local K=l:FindFirstChild("HumanoidRootPart");if not K then return;end;l=K:FindFirstChild("_ptrail");if l then l.Color= tbl3 .ptcol();l.Lifetime= tbl10 .ptlife;l.WidthScale=NumberSequence.new( tbl10 .ptwidth);end;end

	tbl3.clrpt = function()
		local v5 = tbl3.safechar()
		if not v5 then
			return
		end
		local humanoidRootPart = v5:FindFirstChild("HumanoidRootPart")
		if not humanoidRootPart then
			return
		end

		for _, v6 in ipairs({ "_ptrail", "_ptrailA", "_ptrailB" }) do
			local v7 = humanoidRootPart:FindFirstChild(v6)

			if v7 then
				v7:Destroy()
			end
		end
	end

	tbl3.setupviz = function()
		if tbl9.vzdash then
			for _, v5 in ipairs(tbl9.vzdash) do
				v5:Destroy()
			end

			tbl9.vzdash = nil
		end

		if tbl9.vzpart then
			tbl9.vzpart:Destroy()
			tbl9.vzpart = nil
		end

		if tbl10.viz then
			local vzdash = {}

			for i = 1, 36 do
				local part = Instance.new("Part")
				part.Name = "_fx"
				part.Material = Enum.Material.Neon
				part.Transparency = 0.2
				part.Anchored = true
				part.CanCollide = false
				part.CanQuery = false
				part.CanTouch = false
				part.CastShadow = false
				part.Size = Vector3.new(0.35, 0.2, 1.6)
				part.Parent = Workspace
				vzdash[i] = part
			end

			tbl9.vzdash = vzdash
			local part = Instance.new("Part")
			part.Name = "_fx"
			part.Shape = Enum.PartType.Ball
			part.Material = Enum.Material.ForceField
			part.Transparency = 0.7
			part.Anchored = true
			part.CanCollide = false
			part.CanQuery = false
			part.CanTouch = false
			part.CastShadow = false
			part.Size = Vector3.zero
			part.Parent = Workspace
			tbl9.vzpart = part
		end
	end

	tbl3.updviz = function()local l= tbl9 .vzdash;if not  tbl10 .viz or not l then return;end;local K= tbl3 .safechar();local p,E=K and K.PrimaryPart, tbl3 .getball();if not(p and E)then for k,k in ipairs(l)do k.Transparency=1;end;if  tbl9 .vzpart then  tbl9 .vzpart.Size=Vector3.new(0.0,0.0,0.0);end;return;end;local k= tbl10 .vizcol or(Color3.fromRGB(91,110,232));k= tbl3 .ballTarget(E)== localPlayer .Name and(Color3.fromRGB(232,91,110))or k;local a= tbl3 .ballVel(E).Magnitude;local d,I,C= clamp ( tbl3 .parryWindow(a),7.5,100),p.Position-Vector3.new(0,2.9,0),#l;E= clamp (d/20,0.6,3);a= tbl9 .vzcol~=k or  abs (( tbl9 .vzscale or-1)-E)>0.01;if a then  tbl9 .vzcol=k; tbl9 .vzscale=E;end;K=a and(Vector3.new(0.35*E,0.2,1.6*E))or nil;for U=1,C,1 do local J=l[U];local G=(U-1)/C* n *2;E=I+Vector3.new( cos (G)*d,0, sin (G)*d);J.CFrame=CFrame.new(E)*CFrame.Angles(0,-G,0);if a then J.Size=K;J.Color=k;end;if J.Transparency~=0.2 then J.Transparency=0.2;end;end;if  tbl9 .vzpart then l=d*2;if  abs (( tbl9 .vzdia or-1)-l)>0.05 then  tbl9 .vzdia=l; tbl9 .vzpart.Size=Vector3.new(l,l,l);end; tbl9 .vzpart.CFrame=CFrame.new(p.Position);if a then  tbl9 .vzpart.Color=k;end;end;end

	tbl3.bind(UserInputService.LastInputTypeChanged:Connect(function(lastinput)
		tbl9.lastinput = lastinput
	end))

	do
		local remotes = ReplicatedStorage:WaitForChild("Remotes", 5)

		if not remotes then
			warn("[boberhook] ReplicatedStorage.Remotes never appeared - stopping.")
			tbl3.notif("boberhook", "The game's remotes never loaded. Rejoin and run the script again.", 10)
			_G.cuties = nil
			_G.RiseJob = nil
			_G.RiseBoot = nil
			return
		end

		_G.stagesh = "remotes"
		local parrySuccess = remotes:FindFirstChild("ParrySuccess")

		if parrySuccess then
			tbl3.bind(parrySuccess.OnClientEvent:Connect(function()if  tbl3 .isalive()then  tbl3 .stopgrab();end;end))
		end

		local infinityBall = remotes:FindFirstChild("InfinityBall")

		if infinityBall then
			tbl3.bind(infinityBall.OnClientEvent:Connect(function(l,l) tbl9 .infball=l and true or false;end))
		end

		local parrySuccessAll = remotes:FindFirstChild("ParrySuccessAll")

		if parrySuccessAll then
			tbl3.bind(parrySuccessAll.OnClientEvent:Connect(function(l,l)local K= localPlayer .Character and  localPlayer .Character.PrimaryPart;local p= tbl3 .getball();if not K or not p then return;end;if not  tbl3 .ballLive(p)then return;end;local E= tbl3 .ballPos(p);if not E then return;end;local k= tbl3 .ballVel(p);local a,d,I=k.Magnitude,(K.Position-E).Magnitude,k.Magnitude>0 and k.Unit or(Vector3.new(0.0,0.0,0.0));p,k=(K.Position-E).Unit:Dot(I), tbl3 .getping();E= min (a/100,40);local I,C=d/ max (a,1)-k/1000,40* max (p,0);p=15- min (d/1000,15)+C+E;if l~=K and d>(if a>100 and I>k/10 then( max (p-15,15))else p)then  tbl9 .curve.curving=tick();end;end))
		end
	end

	local function fn7(arg)
		tbl9.aero[arg] = tick() + (arg:GetAttribute("TornadoTime") or 1) + 0.4

		tbl3.bind(arg:GetAttributeChangedSignal("TornadoTime"):Connect(function()
			tbl9.aero[arg] = tick() + (arg:GetAttribute("TornadoTime") or 1) + 0.4
		end))
	end

	for _, v5 in ipairs(CollectionService:GetTagged("AerodynamicSlashTornado")) do
		fn7(v5)
	end

	tbl3.bind(CollectionService:GetInstanceAddedSignal("AerodynamicSlashTornado"):Connect(fn7))

	tbl3.bind(CollectionService:GetInstanceRemovedSignal("AerodynamicSlashTornado"):Connect(function(arg)
		tbl9.aero[arg] = nil
	end))

	local balls = Workspace:FindFirstChild("Balls")

	if balls then
		tbl3.bind(balls.ChildRemoved:Connect(function()
			tbl9.curve.curving = tick()
			tbl9.curve.lerprad = 0
			tbl9.curve.lastwarp = tick()
		end))

		tbl3.bind(balls.ChildAdded:Connect(function()task.wait();if  tbl10 .bt then  tbl3 .applybt();end;end))
	end

	tbl3.visacc = 0
	tbl3.bind(RunService.Heartbeat:Connect(function(l) tbl3 .visacc= tbl3 .visacc+l;if  tbl3 .visacc>=0.066 then  tbl3 .visacc= tbl3 .visacc-0.066;if  tbl10 .bt then  tbl3 .applybt();end;if  tbl10 .pt and  tbl10 .ptrb then  tbl3 .refpt();end;end;if  tbl10 .viz then  tbl3 .updviz();end;end))

	tbl3.mirror = {
		abilspd = "abilityminspeed",
		acc = "parryaccuracy",
		antiafk = "antiafk",
		autoabil = "autoability",
		autoexec = "autoexecute",
		autoparry = "autoparry",
		autospam = "autospam",
		bloom = "shaderbloom",
		brightness = "shaderbrightness",
		bt = "balltrail",
		btend = "balltrailendcolour",
		btglow = "balltrailglow",
		btlife = "balltraillifetime",
		btpart = "balltrailparticles",
		btrb = "balltrailrainbow",
		btstart = "balltrailstartcolour",
		cdprot = "cooldownprotection",
		contrast = "shadercontrast",
		crv = "curves",
		devscreen = "devicescreen",
		devtype = "devicetype",
		dof = "shaderdof",
		emospam = "emotespam",
		emospawn = "emoteonspawn",
		emospd = "emotespamspeed",
		emoteonly = "emoteonly",
		forceemo = "forceemote",
		fpscap = "fpscap",
		fpsval = "fpscapvalue",
		hum = "humanizer",
		manspam = "manualspam",
		music = "music",
		nocrv = "nocurvespam",
		norender = "norender",
		pt = "playertrail",
		ptcol = "playertrailcolour",
		ptlife = "playertraillifetime",
		ptrb = "playertrailrainbow",
		ptwidth = "playertrailwidth",
		rain = "raineffect",
		rainrate = "rainintensity",
		rng = "parryrange",
		saturation = "shadersaturation",
		shaderpreset = "shaderpreset",
		shaders = "shaders",
		staff = "staffdetection",
		staffdo = "staffaction",
		thundernocd = "thundernocd",
		track = "musictrack",
		trigger = "triggerbot",
		viptag = "viptag",
		viz = "visualizer",
		vizcol = "visualizercolour",
		vol = "musicvolume",
	}

	tbl3.widget = function(arg)
		return toggles[arg] or options[arg]
	end

	tbl3.humroll = function()
		local a = options.humaccuracy
		local r = options.humrange

		if a then
			tbl10.acc = math.random(math.floor(a.ValueMin), math.floor(a.ValueMax))
		end

		if r then
			tbl10.rng = math.floor((r.ValueMin + math.random() * (r.ValueMax - r.ValueMin)) * 10 + 0.5) / 10
		end
	end

	tbl3.syncopt = function()
		for k, v5 in pairs(tbl3.mirror) do
			local v6 = tbl3.widget(v5)

			if v6 then
				tbl10[k] = v6.Value
			end
		end

		tbl10.musicid = options.musiccustom.Value or ""
		tbl10.keyparry = options.parrymethod.Value == "Keypress"
	end

	local tbl13 = {}

	for k, v5 in pairs(tbl3.mirror) do
		if not tbl3.widget(v5) then
			tbl13[#tbl13 + 1] = k .. " -> " .. v5
		end
	end

	if #tbl13 > 0 then
		table.sort(tbl13)
		warn("[boberhook] mirror points at controls that do not exist: " .. table.concat(tbl13, ", "))
	end

	tbl3.syncopt()
	tbl3.startdet()
	tbl3.startpred()
	pcall(function(tbl3, toggles, options, Library)
		local cr = cloneref or function(o) return o end
		local Players = cr(game:GetService("Players"))
		local RunService = cr(game:GetService("RunService"))
		local Workspace = cr(game:GetService("Workspace"))
		local ReplicatedStorage = cr(game:GetService("ReplicatedStorage"))
		local UserInputService = cr(game:GetService("UserInputService"))
		local LocalPlayer = Players.LocalPlayer
		local TweenService = cr(game:GetService("TweenService"))
		local function fxTween(inst, t, props, style, dir)
			local tw = TweenService:Create(inst, TweenInfo.new(t, style or Enum.EasingStyle.Quad, dir or Enum.EasingDirection.Out), props)
			tw:Play()
			return tw
		end
		local function inStandoff() return tbl9 ~= nil and tbl9.standoff == true end
		local lastStandoff = false
		local getTime = (type(os) == "table" and os.clock) or tick
		local env = (type(getgenv) == "function" and getgenv()) or _G

		if env.__da_sof_cleanup then
			pcall(env.__da_sof_cleanup)
		end

		local connections = {}
		local cleanups = {}

		local guiParent = (type(gethui) == "function" and gethui()) or cr(game:GetService("CoreGui"))

		local function tv(name)
			local t = toggles[name]
			return t ~= nil and t.Value == true
		end

		local function ov(name, default)
			local o = options[name]
			local n = o and tonumber(o.Value)
			if n == nil then
				return default
			end
			return n
		end

		local function pressBlock()
			local ok, res = pcall(tbl3.blockpress)
			return ok and res == true
		end

		local function pressAbility()
			pcall(tbl3.fireabil)
		end

		local function holdParry(key, on)
			pcall(tbl3.holdparry, key, on)
		end

		local ok1, err1 = pcall(function()
			local PARRY_MARGIN = 0.05
			local SEQUENCE_TIMEOUT = 4
			local CD_END_MARGIN = 0.15
			local PROTECT_ARM_WINDOW = 0.3
			local AUTO_ARM_GRACE = 0.5
			local GRADIENT_READY = 0.49
			local DEFAULT_PARRY_CD = 1.3
			local GRADIENT_IGNORE_MAX = 1.5
			local RESET_STALE_WINDOW = 0.3
			local LEAD = 0.35
			local DELAY = 0.3

			local oldGui = guiParent:FindFirstChild("dribbleassist")
			if oldGui then
				oldGui:Destroy()
			end

			local function ballPosition(ball)
				if ball:IsA("BasePart") then
					return ball.Position
				end
				local body = ball:FindFirstChild("Body")
				if body and body:IsA("BasePart") then
					return body.Position
				end
				return ball:GetPivot().Position
			end

			local function ballVelocity(ball)
				local zoomies = ball:FindFirstChild("zoomies")
				if zoomies then
					return zoomies.VectorVelocity
				end
				local attribute = ball:GetAttribute("Velocity")
				if typeof(attribute) == "Vector3" then
					return attribute
				end
				local body = ball:FindFirstChild("Body")
				if body and body:IsA("BasePart") then
					return body.AssemblyLinearVelocity
				end
				if ball:IsA("BasePart") then
					return ball.AssemblyLinearVelocity
				end
				return Vector3.new(0, 0, 0)
			end

			local function ballTarget(ball)
				local whitelist = ball:FindFirstChild("CollisionWhitelist")
				if whitelist and whitelist:IsA("ObjectValue") then
					local value = whitelist.Value
					return value and value.Name or nil
				end
				local target = ball:GetAttribute("target")
				if type(target) == "string" and target ~= "" then
					return target
				end
				return nil
			end

			local function isLiveBall(ball)
				return ball:FindFirstChild("zoomies") ~= nil or ball:FindFirstChild("CollisionWhitelist") ~= nil
			end

			local function getBalls()
				local list = {}
				for _, name in { "Balls", "TrainingBalls" } do
					local folder = Workspace:FindFirstChild(name)
					if folder then
						for _, ball in folder:GetChildren() do
							if isLiveBall(ball) then
								list[#list + 1] = ball
							end
						end
					end
				end
				return list
			end

			local function getRoot()
				local character = LocalPlayer.Character
				local alive = Workspace:FindFirstChild("Alive")
				if not character or not alive or character.Parent ~= alive then
					if not Workspace:FindFirstChild("TrainingBalls") then
						return nil
					end
				end
				return character and (character.PrimaryPart or character:FindFirstChild("HumanoidRootPart")) or nil
			end

			local function getEquippedAbility()
				local character = LocalPlayer.Character
				return (character and character:GetAttribute("Ability")) or LocalPlayer:GetAttribute("CurrentlyEquippedAbility")
			end

			local ping = 0
			local pingTime = 0

			local function getPing()
				local now = getTime()
				if now - pingTime > 1 then
					pingTime = now
					pcall(function()
						ping = LocalPlayer:GetNetworkPing()
					end)
				end
				return ping
			end

			local function getArrival(ball, root)
				if ballTarget(ball) ~= LocalPlayer.Name then
					return nil
				end
				local offset = root.Position - ballPosition(ball)
				local distance = offset.Magnitude
				if distance < 0.01 then
					return 0
				end
				local closing = ballVelocity(ball):Dot(offset.Unit)
				if closing <= 1 then
					return nil
				end
				return distance / closing
			end

			local function getIncoming(root)
				local best
				for _, ball in getBalls() do
					local arrival = getArrival(ball, root)
					if arrival and (not best or arrival < best) then
						best = arrival
					end
				end
				return best
			end

			local function isDribbleSeen()
				for _, ball in getBalls() do
					if ball:GetAttribute("DribbleActive") then
						return true
					end
				end
				return false
			end

			local function create(className, properties)
				local instance = Instance.new(className)
				for property, value in properties do
					if property ~= "Parent" then
						instance[property] = value
					end
				end
				instance.Parent = properties.Parent
				return instance
			end

			local FONT = Enum.Font.Code
			local TEXT = Color3.fromRGB(235, 235, 235)
			local DIM = Color3.fromRGB(150, 150, 150)

			local screenGui = create("ScreenGui", {
				Name = "dribbleassist",
				ResetOnSpawn = false,
				IgnoreGuiInset = true,
				DisplayOrder = 100,
				ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
				Parent = guiParent,
			})

			local function isStale()
				return screenGui.Parent == nil
			end

			local indicatorFrame = create("TextButton", {
				AnchorPoint = Vector2.new(0.5, 0),
				Position = UDim2.new(0.5, 0, 0, 80),
				Size = UDim2.fromOffset(190, 32),
				BackgroundColor3 = Color3.fromRGB(18, 18, 18),
				BorderSizePixel = 0,
				Text = "",
				AutoButtonColor = false,
				Parent = screenGui,
			})
			create("UICorner", { CornerRadius = UDim.new(0, 8), Parent = indicatorFrame })
			local indStroke = create("UIStroke", {
				Color = Color3.fromRGB(45, 45, 45),
				Thickness = 1,
				ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
				Parent = indicatorFrame,
			})

			local dot = create("Frame", {
				Position = UDim2.fromOffset(12, 11),
				Size = UDim2.fromOffset(10, 10),
				BackgroundColor3 = DIM,
				BorderSizePixel = 0,
				Parent = indicatorFrame,
			})
			create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = dot })
			local ring = create("Frame", {
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromOffset(17, 16),
				Size = UDim2.fromOffset(10, 10),
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				Visible = false,
				Parent = indicatorFrame,
			})
			create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = ring })
			local ringStroke = create("UIStroke", { Thickness = 2, Color = Color3.fromRGB(90, 220, 120), Parent = ring })
			local streakLine = create("Frame", {
				Position = UDim2.new(0, 10, 1, -2),
				Size = UDim2.new(1, -20, 0, 2),
				BorderSizePixel = 0,
				BackgroundColor3 = DIM,
				Visible = false,
				Parent = indicatorFrame,
			})
			local streakG = create("UIGradient", {
				Transparency = NumberSequence.new({
					NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.3, 1), NumberSequenceKeypoint.new(0.5, 0),
					NumberSequenceKeypoint.new(0.7, 1), NumberSequenceKeypoint.new(1, 1) }),
				Parent = streakLine,
			})

			local indicatorText = create("TextLabel", {
				Position = UDim2.fromOffset(30, 0),
				Size = UDim2.new(1, -98, 1, 0),
				BackgroundTransparency = 1,
				Text = "dribble: off",
				TextColor3 = TEXT,
				Font = FONT,
				TextSize = 14,
				TextXAlignment = Enum.TextXAlignment.Left,
				Parent = indicatorFrame,
			})

			local tagChip = create("Frame", {
				AnchorPoint = Vector2.new(1, 0.5),
				Position = UDim2.new(1, -8, 0.5, 0),
				Size = UDim2.fromOffset(0, 18),
				AutomaticSize = Enum.AutomaticSize.X,
				BackgroundColor3 = Color3.fromRGB(28, 28, 28),
				BorderSizePixel = 0,
				Visible = false,
				Parent = indicatorFrame,
			})
			create("UICorner", { CornerRadius = UDim.new(0, 5), Parent = tagChip })
			local tagStroke = create("UIStroke", { Thickness = 1, Color = Color3.fromRGB(90, 220, 120), Transparency = 0.45, Parent = tagChip })
			create("UIPadding", { PaddingLeft = UDim.new(0, 6), PaddingRight = UDim.new(0, 6), Parent = tagChip })
			local preLabel = create("TextLabel", {
				Size = UDim2.new(0, 0, 1, 0),
				AutomaticSize = Enum.AutomaticSize.X,
				BackgroundTransparency = 1,
				Text = "",
				TextColor3 = Color3.fromRGB(90, 220, 120),
				Font = FONT,
				TextSize = 11,
				Parent = tagChip,
			})

			local armed = false
			local phase = "wait"
			local pressedAt = 0
			local returnAt = 0
			local dribbleSeen = false
			local dribbleDoneAt = 0
			local autoparryOff = false
			local message
			local messageUntil = 0
			local autoArmed = false
			local lastIncomingAt = 0
			local parryCdUntil = 0
			local parryActiveUntil = 0
			local parryResetAt = 0
			local parryStaleUntil = 0
			local ignoreGradient = false
			local armedAt = 0

			local RANGE_MIN = 45
			local RANGE_MAX = 90
			local SPEED_LOW = 40
			local SPEED_HIGH = 300
			local AIM_DOT_LOW = 0.94
			local AIM_DOT_HIGH = 0.68
			local FRONT_DOT_LOW = 0.85
			local FRONT_DOT_HIGH = 0.45
			local MIN_SPEED = 5
			local MIN_DELAY = 0.05
			local DELAY_SPREAD = 0.09
			local PRECLICK_COOLDOWN = 0.6
			local OWN_DRIBBLE_TIME = 0.35

			local ballState = {}
			local lastPreclick = 0
			local ownDribbleUntil = 0
			local wasAbilityActive = false

			local function getAliveFolder()
				return Workspace:FindFirstChild("Alive")
			end

			local function isAlive()
				local character = LocalPlayer.Character
				local alive = getAliveFolder()
				if not character or not alive then
					return false
				end
				return character.Parent == alive
			end

			local function canAct()
				return isAlive() or Workspace:FindFirstChild("TrainingBalls") ~= nil
			end

			local function scanBalls(folder, list)
				if not folder then
					return
				end
				for _, ball in folder:GetChildren() do
					if isLiveBall(ball) then
						list[#list + 1] = ball
					end
				end
			end

			local function getPreclickBalls()
				local list = {}
				local alive = getAliveFolder()
				if alive and alive:FindFirstChild(LocalPlayer.Name) then
					scanBalls(Workspace:FindFirstChild("Balls"), list)
				end
				scanBalls(Workspace:FindFirstChild("TrainingBalls"), list)
				if #list == 0 then
					scanBalls(Workspace:FindFirstChild("Balls"), list)
				end
				return list
			end

			local function pickBall(balls, root)
				if #balls == 0 then
					return nil
				end
				if #balls == 1 then
					return balls[1]
				end
				local best
				local bestRank = -1
				local bestTime = math.huge
				for _, ball in balls do
					local position = ballPosition(ball)
					local state = ballState[ball]
					local rank = 0
					if ballTarget(ball) == LocalPlayer.Name then
						rank = (state and state.parried) and 1 or 2
					end
					local offset = position - root.Position
					local velocity = ballVelocity(ball)
					local speed = velocity.Magnitude
					local arrive = offset.Magnitude
					if speed > 1 then
						arrive = arrive / speed
						if velocity.Unit:Dot((root.Position - position).Unit) <= 0 then
							arrive = arrive + 10
						end
					end
					if rank > bestRank or (rank == bestRank and arrive < bestTime) then
						bestRank = rank
						bestTime = arrive
						best = ball
					end
				end
				return best or balls[1]
			end

			local function speedFactor(speed)
				local t = math.clamp((speed - SPEED_LOW) / (SPEED_HIGH - SPEED_LOW), 0, 1)
				return t * t * (3 - 2 * t)
			end

			local function dribbleRange(speed)
				return RANGE_MIN + (RANGE_MAX - RANGE_MIN) * speedFactor(speed)
			end

			local function isDribble(ball, root)
				if not ball:GetAttribute("DribbleActive") then
					return false
				end
				local offset = root.Position - ballPosition(ball)
				local distance = offset.Magnitude
				local velocity = ballVelocity(ball)
				if distance > dribbleRange(velocity.Magnitude) or distance == 0 then
					return false
				end
				local toward = velocity.Magnitude >= MIN_SPEED and velocity.Unit:Dot(offset.Unit) or -1
				local front = root.CFrame.LookVector:Dot((-offset).Unit)
				local t = speedFactor(velocity.Magnitude)
				local aimDot = AIM_DOT_LOW + (AIM_DOT_HIGH - AIM_DOT_LOW) * t
				local frontDot = FRONT_DOT_LOW + (FRONT_DOT_HIGH - FRONT_DOT_LOW) * t
				return toward >= aimDot or front >= frontDot
			end

			local function markOwnDribble(duration)
				ownDribbleUntil = math.max(ownDribbleUntil, getTime() + duration)
			end

			local function isOwnDribble()
				return getTime() < ownDribbleUntil
			end

			local function getHotbarGradient(name)
				local gui = LocalPlayer:FindFirstChild("PlayerGui")
				local hotbar = gui and gui:FindFirstChild("Hotbar")
				local button = hotbar and hotbar:FindFirstChild(name)
				return button and button:FindFirstChild("UIGradient") or nil
			end

			local function isParryOnCd()
				local now = getTime()
				if now < parryCdUntil then
					return true
				end
				local gradient = getHotbarGradient("Block")
				if ignoreGradient then
					if gradient == nil or gradient.Offset.Y >= GRADIENT_READY or now - parryResetAt > GRADIENT_IGNORE_MAX then
						ignoreGradient = false
					else
						return false
					end
				end
				return gradient ~= nil and gradient.Offset.Y < GRADIENT_READY
			end

			local function isAbilityReady()
				local gradient = getHotbarGradient("Ability")
				return gradient == nil or gradient.Offset.Y >= GRADIENT_READY
			end

			local function getAbilityName(player, character)
				return character:GetAttribute("Ability") or player:GetAttribute("CurrentlyEquippedAbility") or "Dash"
			end

			local function getAbilityLevel(player, ability)
				local upgrades = player:FindFirstChild("Upgrades")
				local upgrade = upgrades and upgrades:FindFirstChild(ability)
				return upgrade and tonumber(upgrade.Value) or 0
			end

			local function dribblerIsV2(ball)
				local alive = getAliveFolder()
				if not alive then
					return false
				end
				local ballPos = ballPosition(ball)
				local nearestPlayer
				local nearestDistance = math.huge
				for _, player in Players:GetPlayers() do
					local character = player.Character
					if player ~= LocalPlayer and character and character.Parent == alive then
						if getAbilityName(player, character) == "Dribble" then
							local root = character:FindFirstChild("HumanoidRootPart")
							if root then
								local distance = (root.Position - ballPos).Magnitude
								if distance < nearestDistance then
									nearestDistance = distance
									nearestPlayer = player
								end
							end
						end
					end
				end
				return nearestPlayer ~= nil and getAbilityLevel(nearestPlayer, "Dribble") >= 1
			end

			local function preclick()
				if not canAct() then
					return
				end
				local now = getTime()
				if now - lastPreclick < PRECLICK_COOLDOWN then
					return
				end
				lastPreclick = now
				task.delay(MIN_DELAY + math.random() * DELAY_SPREAD, function()
					if canAct() and not armed and tv("da_preclick") and tv("da_enabled") then
						pressBlock()
					end
				end)
			end

			local function getState(ball)
				local state = ballState[ball]
				if state then
					return state
				end
				state = { parried = false, drbl = false, preclick = false }
				ballState[ball] = state
				local connection = ball:GetAttributeChangedSignal("target"):Connect(function()
					state.parried = false
					state.drbl = false
					state.preclick = false
				end)
				ball.Destroying:Once(function()
					connection:Disconnect()
					ballState[ball] = nil
				end)
				return state
			end

			local function preclickUpdate()
				if armed then
					markOwnDribble(0.6)
					return
				end

				local character = LocalPlayer.Character
				local alive = getAliveFolder()
				if not character or not alive then
					return
				end
				if character.Parent ~= alive and not Workspace:FindFirstChild("TrainingBalls") then
					return
				end

				local root = character.PrimaryPart
				if not root then
					return
				end
				if root:FindFirstChild("SingularityCape") then
					return
				end

				local abilityActive = character:GetAttribute("AbilityActive") == true
				if abilityActive then
					if not wasAbilityActive then
						markOwnDribble(OWN_DRIBBLE_TIME)
					else
						markOwnDribble(1.5)
					end
				end
				wasAbilityActive = abilityActive

				local ball = pickBall(getPreclickBalls(), root)
				if not ball then
					return
				end

				local state = getState(ball)

				if isDribble(ball, root) then
					if not state.drbl then
						state.drbl = true
					end
					if not state.preclick then
						state.preclick = true
						if not isOwnDribble() and dribblerIsV2(ball) then
							preclick()
						end
					end
				elseif state.drbl then
					state.drbl = false
					state.preclick = false
				end
			end

			pcall(function()
				local remotes = ReplicatedStorage:FindFirstChild("Remotes")
				local button = remotes and remotes:FindFirstChild("AbilityButtonPress")
				if button and button:IsA("BindableEvent") then
					connections[#connections + 1] = button.Event:Connect(function()
						if getEquippedAbility() == "Dribble" then
							markOwnDribble(OWN_DRIBBLE_TIME)
						end
					end)
				end
			end)

			pcall(function()
				local remotes = ReplicatedStorage:FindFirstChild("Remotes")
				local visualCd = remotes and remotes:FindFirstChild("VisualCD")
				if visualCd and visualCd:IsA("RemoteEvent") then
					connections[#connections + 1] = visualCd.OnClientEvent:Connect(function(line, started, duration)
						if not line then
							return
						end
						local now = getTime()
						if started then
							parryCdUntil = now + (tonumber(duration) or DEFAULT_PARRY_CD)
							ignoreGradient = false
							parryActiveUntil = now + math.max(0, 0.5 - getPing() / 2)
						else
							parryCdUntil = 0
							parryActiveUntil = 0
							parryResetAt = now
							parryStaleUntil = now + RESET_STALE_WINDOW
							ignoreGradient = true
						end
					end)
				end
			end)

			local fxMode, fxColor, lastShown = "off", DIM, ""
			local function refresh()
				local text
				local color
				local mode = "off"
				indicatorFrame.Visible = tv("da_indicator")
				local enabled = tv("da_enabled")
				if not enabled then
					text, color = "dribble: disabled", DIM
				elseif message and getTime() < messageUntil then
					text, color = message, Color3.fromRGB(230, 120, 90)
				elseif not armed then
					text, color = "dribble: off", DIM
				elseif phase == "wait" then
					text, color, mode = (autoArmed and "cd protect..." or "waiting..."), Color3.fromRGB(240, 190, 70), "wait"
				else
					text, color, mode = "dribbled", Color3.fromRGB(90, 220, 120), "done"
				end
				local tag = ""
				if enabled then
					local pre = tv("da_preclick")
					local cd = tv("da_cdprotect") and not (tv("da_cdstandoff") and inStandoff())
					if pre and cd then
						tag = "PRE CD"
					elseif pre then
						tag = "PRE"
					elseif cd then
						tag = "CD"
					end
				end
				if text ~= lastShown then
					lastShown = text
					indicatorText.Position = UDim2.fromOffset(30, 7)
					indicatorText.TextTransparency = 1
					fxTween(indicatorText, 0.2, { Position = UDim2.fromOffset(30, 0), TextTransparency = 0 })
					indStroke.Color = color
					fxTween(indStroke, 0.9, { Color = Color3.fromRGB(45, 45, 45) })
					if mode == "done" then
						ring.Visible = true
						ring.Size = UDim2.fromOffset(10, 10)
						ringStroke.Color = color
						ringStroke.Transparency = 0
						fxTween(ring, 0.5, { Size = UDim2.fromOffset(32, 32) })
						fxTween(ringStroke, 0.5, { Transparency = 1 }).Completed:Connect(function() ring.Visible = false end)
					end
				end
				fxMode, fxColor = mode, color
				indicatorText.Text = text
				dot.BackgroundColor3 = color
				if preLabel.Text ~= tag then
					preLabel.Text = tag
					if tag ~= "" then
						preLabel.TextTransparency = 1
						tagStroke.Transparency = 1
						fxTween(preLabel, 0.25, { TextTransparency = 0 })
						fxTween(tagStroke, 0.25, { Transparency = 0.45 })
					end
				end
				tagChip.Visible = tag ~= ""
			end

			local function showMessage(text)
				message = text
				messageUntil = getTime() + 1.5
				refresh()
				task.delay(1.6, refresh)
			end

			local function restoreAutoparry()
				if autoparryOff then
					autoparryOff = false
					holdParry("da", false)
				end
			end

			local function disarm()
				restoreAutoparry()
				armed = false
				autoArmed = false
				phase = "wait"
				dribbleSeen = false
				refresh()
			end

			local function arm(auto)
				if getEquippedAbility() ~= "Dribble" then
					if not auto then
						showMessage("equip dribble")
					end
					return
				end
				armed = true
				autoArmed = auto == true
				phase = "wait"
				dribbleSeen = false
				autoparryOff = true
				holdParry("da", true)
				lastIncomingAt = getTime()
				armedAt = lastIncomingAt
				refresh()
			end

			local function toggleArm()
				if armed then
					disarm()
				else
					arm()
				end
			end

			local function update()
				if not armed then
					return
				end

				local root = getRoot()
				if not root then
					disarm()
					return
				end

				local now = getTime()

				if phase == "wait" then
					if autoArmed and parryResetAt > armedAt then
						disarm()
						return
					end
					local arrival = getIncoming(root)
					if arrival then
						lastIncomingAt = now
					end
					if arrival and arrival <= LEAD + getPing() then
						pressAbility()
						phase = "dribble"
						pressedAt = now
						dribbleSeen = false
						returnAt = now + arrival + PARRY_MARGIN
						refresh()
					elseif autoArmed and now - lastIncomingAt > AUTO_ARM_GRACE then
						disarm()
					end
					return
				end

				if now - pressedAt > SEQUENCE_TIMEOUT then
					disarm()
					return
				end

				if not dribbleSeen and (isDribbleSeen() or now >= returnAt) then
					dribbleSeen = true
					dribbleDoneAt = now
				end

				if not dribbleSeen or now - dribbleDoneAt < DELAY then
					return
				end

				disarm()
			end

			local function cdProtectUpdate()
				if armed then
					return
				end
				local now = getTime()
				if now < parryActiveUntil or now < parryStaleUntil then
					return
				end
				if not isParryOnCd() then
					return
				end
				if getEquippedAbility() ~= "Dribble" then
					return
				end
				if isOwnDribble() or not isAbilityReady() then
					return
				end
				local root = getRoot()
				if not root then
					return
				end
				local arrival = getIncoming(root)
				if not arrival then
					return
				end
				if arrival > LEAD + getPing() + PROTECT_ARM_WINDOW then
					return
				end
				if now < parryCdUntil and parryCdUntil <= now + arrival - CD_END_MARGIN then
					return
				end
				arm(true)
			end

			connections[#connections + 1] = RunService.Heartbeat:Connect(function()
				if isStale() then
					return
				end
				local so = inStandoff()
				if so ~= lastStandoff then
					lastStandoff = so
					refresh()
				end
				if tv("da_enabled") then
					update()
					if tv("da_preclick") then
						preclickUpdate()
					end
					if tv("da_cdprotect") and not (tv("da_cdstandoff") and so) then
						cdProtectUpdate()
					end
				end
			end)

			local function makeDraggable(handle, target, onClick)
				local dragging = false
				local moved = false
				local dragInput
				local dragStart
				local startPos

				connections[#connections + 1] = handle.InputBegan:Connect(function(input)
					local t = input.UserInputType
					if t ~= Enum.UserInputType.MouseButton1 and t ~= Enum.UserInputType.Touch then
						return
					end
					dragging = true
					moved = false
					dragInput = input
					dragStart = input.Position
					startPos = target.Position
				end)

				connections[#connections + 1] = UserInputService.InputChanged:Connect(function(input)
					if isStale() or not dragging then
						return
					end
					if input ~= dragInput and input.UserInputType ~= Enum.UserInputType.MouseMovement then
						return
					end
					local delta = input.Position - dragStart
					if delta.Magnitude > 4 then
						moved = true
					end
					target.Position = UDim2.new(
						startPos.X.Scale,
						startPos.X.Offset + delta.X,
						startPos.Y.Scale,
						startPos.Y.Offset + delta.Y
					)
				end)

				connections[#connections + 1] = UserInputService.InputEnded:Connect(function(input)
					if isStale() then
						return
					end
					local t = input.UserInputType
					if t == Enum.UserInputType.MouseButton1 or t == Enum.UserInputType.Touch then
						if dragging and not moved and onClick then
							onClick()
						end
						dragging = false
						dragInput = nil
					end
				end)
			end

			makeDraggable(indicatorFrame, indicatorFrame, function()
				if tv("da_enabled") then
					toggleArm()
				end
			end)

			if toggles.da_enabled then
				toggles.da_enabled:OnChanged(function(value)
					if not value then
						disarm()
					end
					refresh()
				end)
			end
			if toggles.da_indicator then
				toggles.da_indicator:OnChanged(function()
					refresh()
				end)
			end
			if toggles.da_preclick then
				toggles.da_preclick:OnChanged(function()
					refresh()
				end)
			end
			if toggles.da_cdprotect then
				toggles.da_cdprotect:OnChanged(function()
					refresh()
				end)
			end
			if toggles.da_cdstandoff then
				toggles.da_cdstandoff:OnChanged(function()
					refresh()
				end)
			end
			if options.da_bind then
				options.da_bind:OnClick(function()
					if tv("da_enabled") then
						toggleArm()
					end
				end)
			end

			connections[#connections + 1] = RunService.RenderStepped:Connect(function()
				if isStale() then
					return
				end
				local t = getTime()
				if fxMode == "wait" then
					dot.BackgroundTransparency = 0.55 * (0.5 + 0.5 * math.sin(t * 6))
				else
					dot.BackgroundTransparency = 0
				end
				local armedNow = fxMode ~= "off"
				streakLine.Visible = armedNow
				if armedNow then
					streakLine.BackgroundColor3 = fxColor
					streakG.Offset = Vector2.new(-1 + 2 * ((t * (fxMode == "wait" and 0.9 or 0.5)) % 1), 0)
				end
			end)

			cleanups[#cleanups + 1] = function()
				restoreAutoparry()
				screenGui:Destroy()
			end

			refresh()
		end)
		if not ok1 then
			warn("[dribble assist] ошибка: " .. tostring(err1))
		end

		local ok2, err2 = pcall(function()
			local ONLY_V2 = true
			local IDLE_TIMEOUT = 2
			local RESULT_TIME = 4
			local EVENT_LOG_LIMIT = 3
			local TICK = 0.1

			local GAP_RELEASE = 0.798
			local MAX_CLICKS = 35
			local CPS_WINDOW = 5
			local ACTIVE_GRACE = 0.25
			local MIN_CLICKS_FOR_GAP = 5

			local function sofPing()
				return ov("sof_ping", 100) / 1000
			end

			local function sofRange()
				return ov("sof_range", 50)
			end

			local function sofEarly()
				return ov("sof_early", 2)
			end

			local container = Instance.new("Folder")
			container.Name = "sofcounter"
			container.Parent = guiParent

			local function normalize(value)
				return (tostring(value):lower():gsub("[%s_%-]", ""))
			end

			local function isSlashes(name)
				local text = normalize(name)
				return text:find("slashesoffury", 1, true) ~= nil or text:find("slashoffury", 1, true) ~= nil
			end

			local function getAbilityName(player, character)
				return character:GetAttribute("Ability") or player:GetAttribute("CurrentlyEquippedAbility") or ""
			end

			local function getSlashesLevel(player)
				local upgrades = player:FindFirstChild("Upgrades")
				if not upgrades then
					return 0
				end
				for _, upgrade in upgrades:GetChildren() do
					if isSlashes(upgrade.Name) then
						return tonumber(upgrade.Value) or 0
					end
				end
				return 0
			end

			local function resolvePlayer(value)
				local kind = typeof(value)
				if kind == "Instance" then
					if value:IsA("Player") then
						return value
					end
					if value:IsA("Model") then
						return Players:GetPlayerFromCharacter(value)
					end
				elseif kind == "string" then
					local byName = Players:FindFirstChild(value)
					if byName and byName:IsA("Player") then
						return byName
					end
					for _, player in Players:GetPlayers() do
						if player.DisplayName == value then
							return player
						end
					end
				elseif kind == "number" then
					return Players:GetPlayerByUserId(value)
				end
				return nil
			end

			local sessions = {}
			local blockStart = {}

			local lastBlockAt = 0

			local function isNear(session)
				local myCharacter = LocalPlayer.Character
				local enemyCharacter = session.player.Character
				local myRoot = myCharacter and myCharacter:FindFirstChild("HumanoidRootPart")
				local enemyRoot = enemyCharacter and enemyCharacter:FindFirstChild("HumanoidRootPart")
				if not myRoot or not enemyRoot then
					return false
				end
				return (myRoot.Position - enemyRoot.Position).Magnitude <= sofRange()
			end

			local HELPER_MAX_TIME = 10
			local HELPER_ENDED_GRACE = 0.5
			local HELPER_READY = 0.4
			local HELPER_READY_WAIT = 1.5
			local HELPER_PARRY_CD = 1.3
			local HELPER_MIN_GAP = 0.4
			local AUTOPARRY_RETURN_DELAY = 0.3

			local helper = { runId = 0, active = false, parried = false, last = nil, autoOff = false }

			local function getEquippedAbility()
				local character = LocalPlayer.Character
				return (character and character:GetAttribute("Ability")) or LocalPlayer:GetAttribute("CurrentlyEquippedAbility")
			end

			local function setAutoparry(on)
				if on then
					if helper.autoOff then
						helper.autoOff = false
						holdParry("sof", false)
					end
				else
					helper.autoOff = true
					holdParry("sof", true)
				end
			end

			local function isButtonReady(name)
				local gui = LocalPlayer:FindFirstChild("PlayerGui")
				local hotbar = gui and gui:FindFirstChild("Hotbar")
				local button = hotbar and hotbar:FindFirstChild(name)
				local gradient = button and button:FindFirstChild("UIGradient")
				return gradient == nil or gradient.Offset.Y >= HELPER_READY
			end

			local function isLocalDead()
				local character = LocalPlayer.Character
				local humanoid = character and character:FindFirstChildOfClass("Humanoid")
				return humanoid == nil or humanoid.Health <= 0
			end

			local function forEachBall(callback)
				for _, folderName in { "Balls", "TrainingBalls" } do
					local folder = Workspace:FindFirstChild(folderName)
					if folder then
						for _, ball in folder:GetChildren() do
							if callback(ball) then
								return true
							end
						end
					end
				end
				return false
			end

			local function isBallOnMe()
				return forEachBall(function(ball)
					local target
					local whitelist = ball:FindFirstChild("CollisionWhitelist")
					if whitelist and whitelist:IsA("ObjectValue") then
						target = whitelist.Value and whitelist.Value.Name
					else
						target = ball:GetAttribute("target")
					end
					return target == LocalPlayer.Name
				end)
			end

			local function isDribbleSeen()
				return forEachBall(function(ball)
					return ball:GetAttribute("DribbleActive") == true
				end)
			end

			local sofn = { ownParries = 0, pending = nil, gui = nil, list = nil, rows = {}, order = 0 }
			local SOFN_RESULT_TIME = 0.8
			local SOFN_SHOW_TIME = 3
			local SOFN_MAX_ROWS = 4
			local SOFN_TEXT = {
				parry = "Parry",
				dribble = "Dribble",
				wait = "...",
				ok = "отбилось",
				fail = "не отбилось",
			}
			local SOFN_OK, SOFN_FAIL, SOFN_WAIT = Color3.fromRGB(90, 220, 120), Color3.fromRGB(225, 85, 85), Color3.fromRGB(170, 170, 175)

			function sofn.ensure()
				if sofn.gui and sofn.gui.Parent and sofn.list then
					return sofn.list
				end
				local gui = Instance.new("ScreenGui")
				gui.Name = "sofnotify"
				gui.ResetOnSpawn = false
				gui.IgnoreGuiInset = true
				gui.DisplayOrder = 50
				gui.Parent = guiParent

				local list = Instance.new("Frame")
				list.Name = "list"
				list.BackgroundTransparency = 1
				list.Position = UDim2.fromOffset(12, 64)
				list.Size = UDim2.fromOffset(300, 200)
				list.Parent = gui

				local layout = Instance.new("UIListLayout")
				layout.SortOrder = Enum.SortOrder.LayoutOrder
				layout.Padding = UDim.new(0, 6)
				layout.Parent = list

				sofn.gui, sofn.list = gui, list
				return list
			end

			local function sofnText(entry, state)
				local name = SOFN_TEXT[entry.kind] or entry.kind
				local color, word = SOFN_WAIT, SOFN_TEXT.wait
				if state == true then
					color, word = SOFN_OK, SOFN_TEXT.ok
				elseif state == false then
					color, word = SOFN_FAIL, SOFN_TEXT.fail
				end
				return string.format('%s  <font color="#%s">%s</font>', name, color:ToHex(), word)
			end

			function sofn.add(kind)
				local ok, entry = pcall(function()
					local list = sofn.ensure()
					local scheme = Library.Scheme or {}
					sofn.order = sofn.order + 1

					local row = Instance.new("Frame")
					row.LayoutOrder = sofn.order
					row.AutomaticSize = Enum.AutomaticSize.X
					row.Size = UDim2.fromOffset(0, 28)
					row.BackgroundColor3 = scheme.MainColor or Color3.fromRGB(17, 17, 18)
					row.BackgroundTransparency = 0.1
					row.BorderSizePixel = 0
					row.Parent = list

					local corner = Instance.new("UICorner")
					corner.CornerRadius = UDim.new(0, 6)
					corner.Parent = row

					local stroke = Instance.new("UIStroke")
					stroke.Color = scheme.OutlineColor or Color3.fromRGB(32, 32, 34)
					stroke.Parent = row

					local pad = Instance.new("UIPadding")
					pad.PaddingLeft = UDim.new(0, 10)
					pad.PaddingRight = UDim.new(0, 10)
					pad.Parent = row

					local label = Instance.new("TextLabel")
					label.AutomaticSize = Enum.AutomaticSize.X
					label.Size = UDim2.fromOffset(0, 28)
					label.BackgroundTransparency = 1
					label.RichText = true
					label.TextSize = 14
					label.TextXAlignment = Enum.TextXAlignment.Left
					label.TextColor3 = scheme.FontColor or Color3.fromRGB(205, 205, 205)
					label.FontFace = scheme.Font or Font.fromEnum(Enum.Font.GothamMedium)
					label.Parent = row

					local e = { kind = kind, row = row, label = label, stroke = stroke, parries = sofn.ownParries, at = getTime(), done = false }
					label.Text = sofnText(e, nil)
					return e
				end)
				if not ok or not entry then
					return nil
				end
				sofn.rows[#sofn.rows + 1] = entry
				while #sofn.rows > SOFN_MAX_ROWS do
					local old = table.remove(sofn.rows, 1)
					old.done = true
					pcall(function()
						old.row:Destroy()
					end)
				end
				return entry
			end

			function sofn.finish(entry, success)
				if entry.done then
					return
				end
				entry.done = true
				if sofn.pending == entry then
					sofn.pending = nil
				end
				pcall(function()
					entry.label.Text = sofnText(entry, success)
				end)
				task.delay(SOFN_SHOW_TIME, function()
					pcall(function()
						fxTween(entry.row, 0.25, { BackgroundTransparency = 1 })
						fxTween(entry.label, 0.25, { TextTransparency = 1 })
						fxTween(entry.stroke, 0.25, { Transparency = 1 })
					end)
					task.wait(0.3)
					local i = table.find(sofn.rows, entry)
					if i then
						table.remove(sofn.rows, i)
					end
					pcall(function()
						entry.row:Destroy()
					end)
				end)
			end

			function sofn.press(kind)
				if sofn.pending then
					sofn.finish(sofn.pending, false)
				end
				local entry = sofn.add(kind)
				if not entry then
					return
				end
				sofn.pending = entry
				task.spawn(function()
					while not entry.done do
						local hit
						if kind == "parry" then
							hit = sofn.ownParries > entry.parries
						else
							hit = isDribbleSeen()
						end
						if hit then
							sofn.finish(entry, true)
							return
						end
						if getTime() - entry.at > SOFN_RESULT_TIME then
							sofn.finish(entry, false)
							return
						end
						task.wait()
					end
				end)
			end

			local evaluateTrigger

			local function helperShouldStop(session, startedAt)
				if not tv("sof_dribblehelper") or helper.parried or isLocalDead() then
					return true
				end
				if helper.last == "dribble" and isDribbleSeen() then
					return true
				end
				local now = getTime()
				if now - startedAt > HELPER_MAX_TIME then
					return true
				end
				if session.ended and now - session.endedAt > HELPER_ENDED_GRACE and not isBallOnMe() then
					return true
				end
				return false
			end

			local function startDribbleHelper(session)
				if not tv("sof_dribblehelper") or helper.active then
					return
				end
				if getEquippedAbility() ~= "Dribble" then
					return
				end

				helper.runId = helper.runId + 1
				local id = helper.runId
				helper.active = true
				helper.parried = false
				helper.last = "parry"
				sofn.press("parry")

				local startedAt = getTime()
				task.spawn(function()
					local pressClicks = session.count
					local nextIsDribble = true
					local lastPressAt = startedAt
					while helper.runId == id do
						while helper.runId == id do
							if helperShouldStop(session, startedAt) then
								break
							end
							if not session.ended and session.count > pressClicks and evaluateTrigger(session, getTime()) then
								break
							end
							task.wait()
						end
						if helper.runId ~= id or helperShouldStop(session, startedAt) then
							break
						end

						if helper.last == "dribble" then
							nextIsDribble = false
						else
							nextIsDribble = (getTime() - lastPressAt) <= HELPER_PARRY_CD
						end

						while helper.runId == id and getTime() - lastPressAt < HELPER_MIN_GAP do
							if helperShouldStop(session, startedAt) then
								break
							end
							task.wait()
						end
						if helper.runId ~= id or helperShouldStop(session, startedAt) then
							break
						end

						local button = nextIsDribble and "Ability" or "Block"
						local skipReady = false
						local waitStart = getTime()
						while helper.runId == id and not skipReady and not isButtonReady(button) and getTime() - waitStart < HELPER_READY_WAIT do
							if helperShouldStop(session, startedAt) then
								break
							end
							task.wait()
						end
						if helper.runId ~= id or helperShouldStop(session, startedAt) then
							break
						end

						if nextIsDribble then
							print("[SoF] dribble helper: DRIBBLE (autoparry off)")
							setAutoparry(false)
							pressAbility()
							helper.last = "dribble"
							sofn.press("dribble")
						else
							print("[SoF] dribble helper: PARRY (autoparry on)")
							pressBlock()
							helper.last = "parry"
							sofn.press("parry")
							setAutoparry(true)
						end
						pressClicks = session.count
						lastPressAt = getTime()
					end

					if helper.runId == id then
						if helper.autoOff then
							if helper.last == "dribble" then
								task.wait(AUTOPARRY_RETURN_DELAY)
							end
							if helper.runId == id then
								setAutoparry(true)
							end
						end
						if helper.runId == id then
							helper.active = false
						end
					end
				end)
			end

			cleanups[#cleanups + 1] = function()
				helper.runId = helper.runId + 1
				helper.active = false
				setAutoparry(true)
				pcall(function()
					if sofn.gui then
						sofn.gui:Destroy()
					end
				end)
				pcall(function()
					container:Destroy()
				end)
			end

			local function pressSofBlock(session, reason)
				if session.blocked then
					return
				end
				session.blocked = true
				lastBlockAt = getTime()
				print(string.format("[SoF] BLOCK (%s) at %d clicks", reason, session.count))
				pressBlock()
				startDribbleHelper(session)
			end

			local function getRecentCps(session)
				local times = session.times
				local n = #times
				if n < 3 then
					return nil
				end
				local span = times[n] - times[1]
				if span <= 0 then
					return nil
				end
				return (n - 1) / span
			end

			evaluateTrigger = function(session, now)
				if not session.lastClick then
					return nil
				end
				local sinceLast = now - session.lastClick
				local ping = sofPing()

				if session.count >= MIN_CLICKS_FOR_GAP and sinceLast >= GAP_RELEASE - ping then
					if isNear(session) then
						return "gap"
					end
					return nil
				end

				local cps = getRecentCps(session)
				if not cps then
					return nil
				end
				local interval = 1 / cps
				if sinceLast > interval * 2.5 + 0.05 then
					return nil
				end
				local timeToEnd = (MAX_CLICKS - sofEarly() - session.count) * interval - sinceLast
				if timeToEnd <= ping and isNear(session) then
					return "count"
				end
				return nil
			end

			local function checkTriggers(session, now)
				if not tv("sof_enabled") or session.blocked or session.ended or not session.lastClick then
					return
				end
				local reason = evaluateTrigger(session, now)
				if reason then
					pressSofBlock(session, reason)
				end
			end

			local SOF_GREEN, SOF_YELLOW, SOF_RED = Color3.fromRGB(90, 215, 130), Color3.fromRGB(240, 190, 70), Color3.fromRGB(225, 85, 85)
			local function sofSpeedColor(r)
				if r < 0.5 then return SOF_GREEN:Lerp(SOF_YELLOW, r * 2) end
				return SOF_YELLOW:Lerp(SOF_RED, (r - 0.5) * 2)
			end

			local SOF_UI_SCALE = 0.62
			local function createUi(player, character)
				local adornee = character:FindFirstChild("Head") or character:FindFirstChild("HumanoidRootPart")
				if not adornee then
					return nil
				end
				local face = (Library.Scheme and Library.Scheme.Font) or Font.fromEnum(Enum.Font.GothamMedium)
				local bold = Font.new(face.Family, Enum.FontWeight.Bold)

				local gui = Instance.new("BillboardGui")
				gui.Name = player.Name
				gui.Adornee = adornee
				gui.Size = UDim2.fromOffset(260, 90)
				gui.StudsOffsetWorldSpace = Vector3.new(0, 7.5, 0)
				gui.AlwaysOnTop = true
				gui.ResetOnSpawn = false
				gui.Parent = container

				local card = Instance.new("Frame")
				card.AnchorPoint = Vector2.new(0.5, 0.5)
				card.Position = UDim2.fromScale(0.5, 0.5)
				card.Size = UDim2.fromOffset(220, 64)
				card.BackgroundColor3 = Color3.fromRGB(14, 14, 16)
				card.BackgroundTransparency = 0.04
				card.BorderSizePixel = 0
				card.Parent = gui
				local corner = Instance.new("UICorner")
				corner.CornerRadius = UDim.new(0, 10)
				corner.Parent = card
				local stroke = Instance.new("UIStroke")
				stroke.Thickness = 1
				stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
				stroke.Color = Color3.fromRGB(48, 48, 54)
				stroke.Parent = card
				local scale = Instance.new("UIScale")
				scale.Scale = 0.3
				scale.Parent = card

				local count = Instance.new("TextLabel")
				count.Size = UDim2.fromOffset(72, 54)
				count.BackgroundTransparency = 1
				count.FontFace = bold
				count.TextSize = 38
				count.TextColor3 = Color3.fromRGB(255, 255, 255)
				count.Text = "0"
				count.Parent = card
				local countScale = Instance.new("UIScale")
				countScale.Parent = count

				local divider = Instance.new("Frame")
				divider.Position = UDim2.fromOffset(72, 9)
				divider.Size = UDim2.fromOffset(1, 36)
				divider.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
				divider.BorderSizePixel = 0
				divider.Parent = card

				local sub = Instance.new("TextLabel")
				sub.Position = UDim2.fromOffset(84, 8)
				sub.Size = UDim2.new(1, -94, 0, 16)
				sub.BackgroundTransparency = 1
				sub.FontFace = face
				sub.TextSize = 12
				sub.TextXAlignment = Enum.TextXAlignment.Left
				sub.TextColor3 = Color3.fromRGB(150, 150, 156)
				sub.Text = "Slashes of Fury"
				sub.Parent = card

				local cpsLabel = Instance.new("TextLabel")
				cpsLabel.Position = UDim2.fromOffset(84, 24)
				cpsLabel.Size = UDim2.new(1, -94, 0, 24)
				cpsLabel.BackgroundTransparency = 1
				cpsLabel.FontFace = bold
				cpsLabel.TextSize = 20
				cpsLabel.TextXAlignment = Enum.TextXAlignment.Left
				cpsLabel.TextColor3 = SOF_GREEN
				cpsLabel.Text = "0.0/s"
				cpsLabel.Parent = card

				local track = Instance.new("Frame")
				track.Position = UDim2.new(0, 10, 1, -9)
				track.Size = UDim2.new(1, -20, 0, 3)
				track.BackgroundColor3 = Color3.fromRGB(36, 36, 40)
				track.BorderSizePixel = 0
				track.Parent = card
				local trackCorner = Instance.new("UICorner")
				trackCorner.CornerRadius = UDim.new(1, 0)
				trackCorner.Parent = track
				local fill = Instance.new("Frame")
				fill.Size = UDim2.fromScale(0, 1)
				fill.BackgroundColor3 = SOF_GREEN
				fill.BorderSizePixel = 0
				fill.Parent = track
				local fillCorner = Instance.new("UICorner")
				fillCorner.CornerRadius = UDim.new(1, 0)
				fillCorner.Parent = fill

				TweenService:Create(scale, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = SOF_UI_SCALE }):Play()

				return {
					gui = gui, adornee = adornee, count = count, sub = sub, cps = cpsLabel, fill = fill,
					scale = scale, countScale = countScale, stroke = stroke, lastCount = 0,
				}
			end

			local function destroyUi(session)
				local ui = session.ui
				if ui then
					session.ui = nil
					pcall(function()
						TweenService:Create(ui.scale, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { Scale = 0 }):Play()
					end)
					task.delay(0.22, function()
						pcall(function() ui.gui:Destroy() end)
					end)
				end
			end

			local function getCps(session, now)
				local last = session.lastClick or now
				local duration = math.max(last - session.startedAt, 0.1)
				return session.count / duration
			end

			local function renderUnsafe(session, now)
				local player = session.player
				local character = player.Character
				if not character then
					return
				end

				if not tv("sof_indicator") then
					destroyUi(session)
					return
				end

				if session.ui and not session.ui.adornee:IsDescendantOf(Workspace) then
					destroyUi(session)
				end
				if not session.ui then
					session.ui = createUi(player, character)
				end
				if not session.ui then
					return
				end

				local ui = session.ui
				local cpsValue = getCps(session, now)
				local ratio = math.clamp(cpsValue / 10, 0, 1)
				local col = sofSpeedColor(ratio)
				if ui.lastCount ~= session.count then
					ui.lastCount = session.count
					ui.countScale.Scale = 1.3
					TweenService:Create(ui.countScale, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Scale = 1 }):Play()
					if not session.ended then
						ui.count.TextColor3 = col
						TweenService:Create(ui.count, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { TextColor3 = Color3.fromRGB(255, 255, 255) }):Play()
					end
				end
				ui.count.Text = tostring(session.count)
				ui.cps.Text = string.format("%.1f/s", cpsValue)
				ui.cps.TextColor3 = col
				ui.fill.BackgroundColor3 = col
				TweenService:Create(ui.fill, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Size = UDim2.fromScale(ratio, 1) }):Play()
				if session.ended then
					ui.count.TextColor3 = Color3.fromRGB(255, 200, 70)
					ui.sub.Text = "total"
					ui.stroke.Color = col
				else
					ui.sub.Text = "Slashes of Fury"
				end
			end

			local renderWarned = false
			local function render(session, now)
				local ok, err = pcall(renderUnsafe, session, now)
				if not ok then
					if not renderWarned then
						renderWarned = true
						warn("[SoF] render error: " .. tostring(err))
					end
					pcall(destroyUi, session)
				end
			end

			local function startSession(player)
				local existing = sessions[player]
				if existing and not existing.ended then
					return existing
				end
				if not player.Character then
					return nil
				end
				if ONLY_V2 and getSlashesLevel(player) < 1 then
					return nil
				end
				if existing then
					destroyUi(existing)
				end

				local now = getTime()
				local session = {
					player = player,
					count = 0,
					startedAt = now,
					lastClick = nil,
					times = {},
					lastSignal = now,
					ended = false,
					blocked = false,
					endedAt = 0,
					ui = nil,
				}
				sessions[player] = session
				print(string.format("[SoF] %s started Slashes of Fury", player.Name))
				render(session, now)
				return session
			end

			local function endSession(session)
				if session.ended then
					return
				end
				local now = getTime()
				session.ended = true
				blockStart[session.player] = true
				session.endedAt = now
				print(string.format(
					"[SoF] %s finished: %d clicks (%.1f/s)",
					session.player.Name,
					session.count,
					getCps(session, now)
				))
				render(session, now)
			end

			local function isSlashesActive(player)
				local character = player.Character
				return character ~= nil
					and character:GetAttribute("AbilityActive") == true
					and isSlashes(getAbilityName(player, character))
			end

			local function registerClick(player)
				if player == LocalPlayer then
					return
				end
				local session = sessions[player]
				if (not session or session.ended) and not blockStart[player] and isSlashesActive(player) then
					session = startSession(player)
				end
				if not session or session.ended then
					return
				end
				local now = getTime()
				if session.lastClick and now - session.lastClick >= GAP_RELEASE then
					endSession(session)
					return
				end
				session.count = session.count + 1
				session.lastClick = now
				session.lastSignal = now
				table.insert(session.times, now)
				if #session.times > CPS_WINDOW then
					table.remove(session.times, 1)
				end
				print(string.format("[SoF] %s: %d", player.Name, session.count))
				if session.count >= MAX_CLICKS then
					endSession(session)
					return
				end
				checkTriggers(session, now)
				render(session, now)
			end

			local function hasActiveSession()
				for _, session in sessions do
					if not session.ended then
						return true
					end
				end
				return false
			end

			local logged = {}

			local function logEvent(label, ...)
				logged[label] = (logged[label] or 0) + 1
				if logged[label] > EVENT_LOG_LIMIT then
					return
				end
				local args = table.pack(...)
				local parts = {}
				for index = 1, args.n do
					parts[index] = typeof(args[index]) .. "=" .. tostring(args[index])
				end
				print(string.format("[SoF] event %s (%d): %s", label, logged[label], table.concat(parts, ", ")))
			end

			local function listen(remote, label, handler)
				if not remote then
					warn("[SoF] remote not found: " .. label)
					return
				end
				connections[#connections + 1] = remote.OnClientEvent:Connect(function(...)
					local args = table.pack(...)
					task.spawn(function()
						local ok, err = pcall(handler, table.unpack(args, 1, args.n))
						if not ok then
							warn("[SoF] handler " .. tostring(label) .. " error: " .. tostring(err))
						end
					end)
				end)
			end

			task.spawn(function()
				local remotes = ReplicatedStorage:WaitForChild("Remotes", 10)
				local parrySuccessAll = remotes and remotes:WaitForChild("ParrySuccessAll", 10)
				listen(parrySuccessAll, "ParrySuccessAll", function(...)
					local args = table.pack(...)
					if hasActiveSession() then
						logEvent("ParrySuccessAll", ...)
					end
					if tostring(args[4]) == LocalPlayer.Name then
						sofn.ownParries = sofn.ownParries + 1
					end
					if helper.active and tostring(args[4]) == LocalPlayer.Name then
						helper.parried = true
					end
					local player = Players:FindFirstChild(tostring(args[4]))
					if player and player:IsA("Player") and player ~= LocalPlayer then
						registerClick(player)
					end
				end)
			end)

			task.spawn(function()
				local packages = ReplicatedStorage:WaitForChild("Packages", 10)
				local index = packages and packages:WaitForChild("_Index", 10)
				local package = index and index:WaitForChild("sleitnick_net@0.1.0", 10)
				local net = package and package:WaitForChild("net", 10)
				if not net then
					warn("[SoF] net folder not found")
					return
				end

				listen(net:WaitForChild("RE/SlashesOfFuryActivate", 10), "Activate", function(...)
					logEvent("Activate", ...)
					for _, value in { ... } do
						local player = resolvePlayer(value)
						if player and player ~= LocalPlayer then
							blockStart[player] = nil
							local session = startSession(player)
							if session then
								session.lastSignal = getTime()
							end
							break
						end
					end
				end)

				listen(net:WaitForChild("RE/SlashesOfFuryEnd", 10), "End", function(...)
					logEvent("End", ...)
					for _, value in { ... } do
						local player = resolvePlayer(value)
						if player and player ~= LocalPlayer then
							local session = sessions[player]
							if session then
								endSession(session)
							end
							break
						end
					end
				end)

				listen(net:WaitForChild("RE/SlashesOfFuryParry", 10), "Parry", function(...)
					logEvent("Parry", ...)
				end)

				listen(net:WaitForChild("RE/SlashesOfFuryCatch", 10), "Catch", function(...)
					logEvent("Catch", ...)
				end)
			end)

			local elapsed = 0

			connections[#connections + 1] = RunService.Heartbeat:Connect(function(delta)
				elapsed = elapsed + delta
				if elapsed < TICK then
					return
				end
				elapsed = 0

				local now = getTime()

				for _, player in Players:GetPlayers() do
					if player ~= LocalPlayer then
						local character = player.Character
						local session = sessions[player]

						local active = character ~= nil
							and character:GetAttribute("AbilityActive") == true
							and isSlashes(getAbilityName(player, character))
						if not active then
							blockStart[player] = nil
						end

						if active and not blockStart[player] then
							if not session or session.ended then
								session = startSession(player)
							end
							if session then
								session.lastSignal = now
							end
						end

						if session and not session.ended and now - session.lastSignal > IDLE_TIMEOUT then
							endSession(session)
						end

						if session then
							if session.ended and now - session.endedAt > RESULT_TIME then
								destroyUi(session)
								sessions[player] = nil
							else
								render(session, now)
							end
						end
					end
				end

				for player, session in sessions do
					if not player.Parent then
						endSession(session)
						destroyUi(session)
						sessions[player] = nil
					end
				end
			end)

			connections[#connections + 1] = RunService.Heartbeat:Connect(function()
				local now = getTime()
				for _, session in sessions do
					checkTriggers(session, now)

					if not session.ended then
						if session.lastClick and now - session.lastClick >= GAP_RELEASE then
							endSession(session)
						else
							local character = session.player.Character
							local active = character ~= nil and character:GetAttribute("AbilityActive") == true
							if active then
								session.activeSeen = true
								session.inactiveSince = nil
							elseif session.activeSeen then
								session.inactiveSince = session.inactiveSince or now
								if now - session.inactiveSince > ACTIVE_GRACE then
									endSession(session)
								end
							end
						end
					end
				end
			end)

			if toggles.sof_indicator then
				toggles.sof_indicator:OnChanged(function()
					local now = getTime()
					for _, session in sessions do
						render(session, now)
					end
				end)
			end
		end)
		if not ok2 then
			warn("[SoF] ошибка: " .. tostring(err2))
		end

		local function cleanup()
			for _, connection in connections do
				pcall(function()
					connection:Disconnect()
				end)
			end
			table.clear(connections)
			for _, fn in cleanups do
				pcall(fn)
			end
			table.clear(cleanups)
		end
		env.__da_sof_cleanup = cleanup
		if Library and Library.OnUnload then
			Library:OnUnload(cleanup)
		end
	end, tbl3, toggles, options, v)

	_G.stagesh = "detect"

	options.menukeybind:OnChanged(function()
		v.ToggleKeybind = options.menukeybind
		tbl3.qsave()
	end)

	do
		local tbl14 = {}

		tbl3.applysky = function(arg)
			if tbl14.skywatch then
				tbl14.skywatch:Disconnect()
				tbl14.skywatch = nil
			end

			if tbl14.sky then
				tbl14.sky:Destroy()
				tbl14.sky = nil
			end

			if not arg or arg == "Default" then
				if tbl14.origskies then
					for _, origsky in ipairs(tbl14.origskies) do
						origsky.Parent = Lighting
					end

					tbl14.origskies = nil
				end

				return
			end

			local v5 = tbl5[arg]
			if not v5 then
				return
			end
			tbl14.origskies = tbl14.origskies or {}

			for _, child in ipairs(Lighting:GetChildren()) do
				if child:IsA("Sky") then
					child.Parent = nil
					tbl14.origskies[#tbl14.origskies + 1] = child
				end
			end

			local sky = Instance.new("Sky")
			sky.Name = "rise_sky"
			sky.SkyboxBk = "rbxassetid://" .. v5.bk
			sky.SkyboxDn = "rbxassetid://" .. v5.dn
			sky.SkyboxFt = "rbxassetid://" .. v5.ft
			sky.SkyboxLf = "rbxassetid://" .. v5.lf
			sky.SkyboxRt = "rbxassetid://" .. v5.rt
			sky.SkyboxUp = "rbxassetid://" .. v5.up
			sky.StarCount = v5.stars or 3000
			sky.SunAngularSize = v5.sun or 21
			sky.MoonAngularSize = v5.moon or 11
			sky.CelestialBodiesShown = v5.cel == true
			sky.Parent = Lighting
			tbl14.sky = sky
			tbl14.skywatch = Lighting.ChildAdded:Connect(function(l)if l:IsA("Sky")and l~= tbl14 .sky then task.defer(function()if l.Parent== Lighting and l~= tbl14 .sky then  tbl14 .origskies= tbl14 .origskies or{};l.Parent=nil; tbl14 .origskies[# tbl14 .origskies+1]=l;end;end);end;end)
		end

		local tbl15 = { Day = 14, Sunset = 17.5, Night = 22, Midnight = 0 }

		tbl3.settime = function(arg)
			if arg == "Default" then
				if tbl14.ct ~= nil then
					Lighting.ClockTime = tbl14.ct
					tbl14.ct = nil
				end

				return
			end

			if tbl14.ct == nil then
				tbl14.ct = Lighting.ClockTime
			end

			Lighting.ClockTime = tbl15[arg] or Lighting.ClockTime
		end

		tbl3.setbright = function(arg)
			if arg then
				if not tbl14.lorig then
					tbl14.lorig = { b = Lighting.Brightness, a = Lighting.Ambient, o = Lighting.OutdoorAmbient, gs = Lighting.GlobalShadows }
				end

				Lighting.Brightness = 2
				Lighting.Ambient = Color3.fromRGB(178, 178, 178)
				Lighting.OutdoorAmbient = Color3.fromRGB(178, 178, 178)
				Lighting.GlobalShadows = false
			elseif tbl14.lorig then
				Lighting.Brightness = tbl14.lorig.b
				Lighting.Ambient = tbl14.lorig.a
				Lighting.OutdoorAmbient = tbl14.lorig.o
				Lighting.GlobalShadows = tbl14.lorig.gs
				tbl14.lorig = nil
			end
		end

		tbl3.setnofog = function(arg)
			if arg then
				if not tbl14.fog then
					tbl14.fog = { e = Lighting.FogEnd, s = Lighting.FogStart, atm = {} }

					for _, child in ipairs(Lighting:GetChildren()) do
						if child:IsA("Atmosphere") then
							tbl14.fog.atm[child] = child.Density
						end
					end
				end

				Lighting.FogEnd = 1000000
				Lighting.FogStart = 0

				for k in pairs(tbl14.fog.atm) do
					k.Density = 0
				end
			elseif tbl14.fog then
				Lighting.FogEnd = tbl14.fog.e
				Lighting.FogStart = tbl14.fog.s

				for k, v5 in pairs(tbl14.fog.atm) do
					k.Density = v5
				end

				tbl14.fog = nil
			end
		end

		tbl3.startfov = function()
			if tbl14.fovconn then
				return
			end
			tbl14.fovconn = tbl3.bind(RunService.RenderStepped:Connect(function()if not  toggles .customfov.Value then return;end;local l= Workspace .CurrentCamera;if l then if  tbl14 .fovorig==nil then  tbl14 .fovorig=l.FieldOfView;end;local K= options .fov.Value;if l.FieldOfView~=K then l.FieldOfView=K;end;end;end))
		end

		tbl3.restorefov = function()
			local currentCamera2 = Workspace.CurrentCamera

			if currentCamera2 and tbl14.fovorig ~= nil then
				currentCamera2.FieldOfView = tbl14.fovorig
			end

			tbl14.fovorig = nil
		end

		tbl3.setgrav = function()
			if toggles.customgrav.Value then
				if tbl14.gravorig == nil then
					tbl14.gravorig = Workspace.Gravity
				end

				Workspace.Gravity = options.grav.Value
			elseif tbl14.gravorig ~= nil then
				Workspace.Gravity = tbl14.gravorig
				tbl14.gravorig = nil
			end
		end

		tbl3.gfxsweep = function()local l= tbl14 .gfx;if not l then return;end;for K,K in ipairs( Lighting :GetDescendants())do if not l.seen[K]then if K:IsA("Atmosphere")then l.seen[K]=true;l.saved[#l.saved+1]={K,"Density",K.Density};K.Density=0;elseif K:IsA("BloomEffect")or(K:IsA("SunRaysEffect"))or(K:IsA("DepthOfFieldEffect"))or(K:IsA("BlurEffect"))then l.seen[K]=true;l.saved[#l.saved+1]={K,"Enabled",K.Enabled};K.Enabled=false;end;end;end;for K,K in ipairs( Workspace :GetDescendants())do if not l.seen[K]and(K:IsA("ParticleEmitter")or(K:IsA("Trail"))or(K:IsA("Smoke"))or(K:IsA("Fire"))or(K:IsA("Sparkles")))and K.Enabled then l.seen[K]=true;K.Enabled=false;l.parts[#l.parts+1]=K;end;end;end
		tbl3.gfxwatch = function()if  tbl14 .gfxmap then  tbl14 .gfxmap:Disconnect(); tbl14 .gfxmap=nil;end;if  tbl14 .gfxroot then  tbl14 .gfxroot:Disconnect(); tbl14 .gfxroot=nil;end;if not  tbl14 .gfx then return;end;local l=nil;l=function() tbl3 .bindt(task.delay(0.5, tbl3 .gfxsweep));end;local function K(p)if  tbl14 .gfxmap then  tbl14 .gfxmap:Disconnect();end; tbl14 .gfxmap= tbl3 .bind(p.ChildAdded:Connect(l));end;local p= Workspace :FindFirstChild("Map");if p then K(p);end; tbl14 .gfxroot= tbl3 .bind( Workspace .ChildAdded:Connect(function(h)if h.Name~="Map"then return;end;K(h);l();end));end
		tbl3.setlowgfx = function(l)if l then if not  tbl14 .gfx then  tbl14 .gfx={q=settings().Rendering.QualityLevel,gs= Lighting .GlobalShadows,parts={},saved={},seen={}};settings().Rendering.QualityLevel=Enum.QualityLevel.Level01; Lighting .GlobalShadows=false;local function l(K,p) tbl14 .gfx.seen[K]=true; tbl14 .gfx.saved[# tbl14 .gfx.saved+1]={K,p,K[p]};end;l( Workspace ,"GlobalWind"); Workspace .GlobalWind=Vector3.new(0,0,0);l( Lighting ,"EnvironmentDiffuseScale"); Lighting .EnvironmentDiffuseScale=0;l( Lighting ,"EnvironmentSpecularScale"); Lighting .EnvironmentSpecularScale=0;local K= Workspace :FindFirstChildOfClass("Terrain");if K then l(K,"Decoration");K.Decoration=false;l(K,"WaterWaveSize");K.WaterWaveSize=0;local p=K:FindFirstChildOfClass("Clouds");if p then l(p,"Enabled");p.Enabled=false;end;end; tbl3 .gfxsweep(); tbl3 .gfxwatch();end;elseif  tbl14 .gfx then settings().Rendering.QualityLevel= tbl14 .gfx.q; Lighting .GlobalShadows= tbl14 .gfx.gs;for l,l in ipairs( tbl14 .gfx.saved)do if l[1]and l[1].Parent then l[1][l[2]]=l[3];end;end;for l,l in ipairs( tbl14 .gfx.parts)do if l and l.Parent then l.Enabled=true;end;end; tbl14 .gfx=nil; tbl3 .gfxwatch();end;end

		tbl3.applycap = function()
			if setfpscap then
				local v5 = setfpscap
				local fpscap = tbl10.fpscap

				if fpscap then
					fpscap = clamp(tbl10.fpsval or 60, 5, 1000)
				end

				v5(fpscap or 0)
			end
		end

		tbl3.startantilag = function()
			if tbl9.alconn then
				return
			end
			tbl9.altime = 0
			tbl9.alframes = 0
			tbl9.alfps = 60
			tbl9.alapplied = false
			tbl9.alconn = tbl3.bind(RunService.RenderStepped:Connect(function(l)if not( toggles .antilag and  toggles .antilag.Value)then return;end; tbl9 .alframes= tbl9 .alframes+1; tbl9 .altime= tbl9 .altime+l;if  tbl9 .altime<0.5 then return;end; tbl9 .alfps= tbl9 .alframes/ tbl9 .altime; tbl9 .alframes=0; tbl9 .altime=0;if  toggles .lowgfx and  toggles .lowgfx.Value then  tbl9 .alapplied=false;return;end;local l= options .antilagfps and  options .antilagfps.Value or 30;if not  tbl9 .alapplied then if  tbl9 .alfps<l then  tbl9 .alapplied=true; tbl3 .setlowgfx(true); tbl3 .notif("Anti-Lag", format ("FPS dropped to %.0f. Effects turned off.", tbl9 .alfps),3);end;elseif  tbl9 .alfps>l+15 then  tbl9 .alapplied=false; tbl3 .setlowgfx(false); tbl3 .notif("Anti-Lag","FPS is back up. Effects turned on.",3);end;end))
		end

		fn3 = function()
			TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, localPlayer)
		end

		fn5 = function()
			local character = localPlayer.Character
			local humanoid = character and character:FindFirstChildOfClass("Humanoid")

			if humanoid then
				humanoid.Health = 0
				humanoid:ChangeState(Enum.HumanoidStateType.Dead)
			elseif character then
				character:BreakJoints()
			end
		end

		fn4 = function()
			tbl3.bindt(task.spawn(function()
				local str2 = ("https://games.roblox.com/v1/games/%d/servers/Public?sortOrder=Asc&limit=100"):format(game.PlaceId)
				local v5 = tbl3.httpget(str2)
				local data = v5 and HttpService:JSONDecode(v5)
				if type(data) ~= "table" or not data.data then
					tbl3.notif("Server", "Couldn't load the server list. Try again.", 4)
					return
				end

				for _, v6 in ipairs(data.data) do
					if type(v6) == "table" and v6.playing and v6.maxPlayers and v6.playing < v6.maxPlayers and v6.id ~= game.JobId then
						TeleportService:TeleportToPlaceInstance(game.PlaceId, v6.id, localPlayer)
						return
					end
				end

				tbl3.notif("Server", "No other server found.", 4)
			end))
		end

		local tbl16 = {
			file = "boberhook_FFlags_" .. tostring(game.GameId) .. ".json",
			ipcache = {},
			hopping = false,
			sea = {
				SG = true,
				MY = true,
				ID = true,
				TH = true,
				VN = true,
				PH = true,
				KH = true,
				LA = true,
				MM = true,
				BN = true,
				TL = true,
			},
			sasia = { IN = true, PK = true, BD = true, LK = true, NP = true, BT = true, MV = true, AF = true },
			presetnames = {
				"FPS Boost",
				"Low Ping",
				"Stutter Ball",
				"No Textures",
				"Glitch Curve",
				"Low Input Delay",
				"Low Mesh",
				"Shiny Ball",
				"Gray World",
			},
			presetdefault = "FPS Boost",
			presets = {
				["FPS Boost"] = {
					FFlagControlBetaBadgeWithGuac = "False",
					FFlagLuaAppsEnableParentalControlsTab = "False",
					FFlagTaskSchedulerLimitTargetFpsTo2402 = "False",
					FFlagDebugSkyGray = "True",
					FFlagBetaBadgeLearnMoreLinkFormview = "False",
					FFlagDebugDisableTelemetryEphemeralCounter = "True",
					FFlagDebugDisableTelemetryPoint = "True",
					FIntEnableVisBugChecksHundredthPercent27 = "100",
					FFlagCoreGuiSelfViewVisibilityFixed = "False",
					FFlagEnableAudioPannerFiltering = "True",
					DFIntTaskSchedulerTargetFps = "9999",
					FFlagWindowsReportAbuseNotification = "False",
					FFlagRenderLightGridEfficientTextureAtlasUpdate = "True",
					FFlagEnableInGameMenuChromeABTest4 = "True",
					DFFlagUnifyLegacyJointGeometry = "True",
					DFIntAnimationLodFacsDistanceMin = "0",
					FIntRenderGrassDetailStrands = "0",
					DFFlagDebugSkipMeshVoxelizer = "True",
					DFIntWindowsWebViewTelemetryThrottleHundredthsPercent = "0",
					FFlagGraphicsTextureCopy = "True",
					FFlagClientToastNotificationsEnabled = "False",
					FIntSmoothTerrainPhysicsCacheSize = "2147483647",
					FFlagUserShowGuiHideToggles = "True",
					DFStringRobloxAnalyticsURL = "http://127.0.0.1:443/",
					FFlagAXFixAdaptiveScrollingSnapAndroid = "True",
					FFlagAdServiceEnabled = "False",
					DFIntVoiceChatMaxRecordedDataDeliveryIntervalMs = "2147483647",
					FFlagDebugGraphicsPreferD3D11FL10 = "True",
					FFlagDisableFeedbackSoothsayerCheck = "False",
					FFlagEnablePreferredTextSizeConnection = "True",
					DFFlagOptimizeNoCollisionPrimitiveInMidphaseCrash = "True",
					DFIntRakNetMtuValue2InBytes = "900",
					FIntSelfViewTooltipLifetime = "0",
					FIntUnifiedLightingBlendZone = "1",
					DFIntPerformanceControlTextureQualityBestUtility = "-1",
					FFlagEnableExperienceNotificationPrompts2 = "False",
					FFlagAXAdaptiveScrollingItemResetFix2 = "True",
					DFIntRakNetMtuValue1InBytes = "900",
					FFlagVoiceBetaBadge = "False",
					FFlagSortKeyOptimization = "True",
					DFIntGraphicsOptimizationModeMinFrameTimeTargetMs = "25",
					FFlagPreloadMinimalFonts = "True",
					FFlagOcclusionCullingBetaFeature = "True",
					FFlagLuauCodegen = "True",
					DFIntTextureQualityOverride = "0",
					FIntRobloxGuiBlurIntensity = "0",
					FFlagFixSettingsHubVRBackgroundError = "True",
					FIntDebugFRMOptionalMSAALevelOverride = "0",
					FFlagUseNotificationsLocalization = "False",
					FFlagVRLaserPointerOptimization = "True",
					FFlagEnablePreferredTextSizeStyleFixesInPurchasePrompt = "True",
					FFlagSelfViewGetRidOfFalselyRenderedFaceDecal = "False",
					FFlagEnablePreferredTextSizeStyleFixesGameTile = "True",
					FIntFixForBulkPresenceNotifications = "0",
					FStringTerrainMaterialTable2022 = "",
					DFIntGraphicsOptimizationModeMaxFrameTimeTargetMs = "20",
					DFFlagTeleportClientAssetPreloadingEnabled9 = "True",
					FFlagUserEnableCameraToggleNotification = "False",
					FFlagUserFixLoadAnimationError = "True",
					DFFlagAdsPreloadInteractivityAssets = "True",
					DFIntCSGLevelOfDetailSwitchingDistanceL23 = "0",
					FFlagEngineAPICloudProcessingUseNotificationClient = "False",
					FIntTargetRefreshRate = "144",
					FFlagToastNotificationsReceivedAndDismissedSignals = "False",
					DFStringTelemetryV2Url = "http://127.0.0.1:443",
					DFFlagEngineAPISendNotificationClientAnalytics = "False",
					FFlagPreferredTextSizeStyleFixEventDescriptionExperienceTile = "True",
					DFStringTelegrafAddress = "127.0.0.1",
					DFIntRakNetMtuValue3InBytes = "900",
					DFIntMicroProfilerDpiScaleOverride = "100",
					FFlagVRMouseMoveOptimization = "True",
					FFlagEnableChromeFTUX = "True",
					FFlagSettingsHubIndependentBackgroundVisibility = "True",
					FIntSSAOMipLevels = "1",
					FFlagShoeSkipRenderMesh = "False",
					FIntRuntimeMaxNumOfThreads = "2400",
					FFlagSignalRNotificationManagerMaybeStart = "False",
					FIntCameraMaxZoomDistance = "999999",
					FIntAXAdaptiveScrollingJustSelectedMillis = "2000",
					FFlagToastNotificationsResendDisplayOnInit = "False",
					FIntOcclusionCullingBetaFeatureRolloutPercent = "100",
					DFFlagAudioToggleVolumetricPanning = "True",
					FIntVRTouchControllerTransparency = "0",
					FFlagAXSearchLandingPageIXPEnabled4 = "False",
					FFlagLuaMenuPerfImprovements = "true",
					FFlagViewCollisionFadeToBlackInVR = "False",
					FFlagFixSensitivityTextPrecision = "False",
					FIntRenderLocalLightUpdatesMin = "1",
					DFFlagEnableExperienceNotificationOptInPrompt = "False",
					FIntCAP1209DataSharingTOSVersion = "0",
					FFlagToastNotificationsProtocolEnabled2 = "False",
					DFFlagJointIrregularityOptimization = "true",
					FIntRenderMaxShadowAtlasUsageBeforeDownscale = "1",
					FFlagGraphicsGLEnableSuperHQShadersExclusion = "False",
					DFIntCanHideGuiGroupId = "32380007",
					DFIntDefaultTimeoutTimeMs = "10000",
					FFlagNewOptimizeNoCollisionPrimitiveInMidphase637 = "True",
					FFlagStudioDataCollectionAddBasicNotification = "False",
					DFFlagTeleportClientAssetPreloadingEnabledIXP2 = "True",
					FFlagSelfViewLookUpHumanoidByType = "False",
					DFIntMaxFrameBufferSize = "10",
					DFIntCSGLevelOfDetailSwitchingDistance = "0",
					FFlagAssetPreloadingIXP = "True",
					DFFlagDisableDPIScale = "False",
					FFlagFixIGMTabTransitions = "True",
					FFlagAvatarChatIncludeSelfViewOnTelemetry = "False",
					FFlagFastGPULightCulling3 = "True",
					FFlagRenderDebugCheckThreading2 = "True",
					FFlagEnableCommandAutocomplete = "False",
					FIntPreferredTextSizeSettingBetaFeatureRolloutPercent = "100",
					FFlagEnablePreferredTextSizeScale = "True",
					FIntUITextureMaxUpdateDepth = "-1",
					DFIntDebugFRMQualityLevelOverride = "1",
					FFlagQuaternionPoseCorrection = "True",
					FFlagEnableIOSWebViewCookieSyncFix = "False",
					FFlagDebugCodegenOptSize = "True",
					FFlagFRMRefactor = "False",
					FFlagImproveShiftLockTransition = "True",
					FIntFRMMaxGrassDistance = "0",
					FFlagEnableVisBugChecks27 = "True",
					DFFlagEnablePerfRenderStatsCollection2 = "false",
					DFIntDebugRestrictGCDistance = "1",
					FFlagFixReducedMotionStuckIGM2 = "True",
					FFlagInExperienceUpsellSelfViewFix = "False",
					FLogNetwork = "7",
					DFFlagNotificationServiceIsConnectedProperty = "False",
					FFlagToastNotificationsUpdateEventParams = "False",
					DFFlagAudioUseVolumetricPanning = "True",
					FFlagDebugForceGenerateHSR = "True",
					FIntTerrainOTAMaxTextureSize = "4",
					FFlagAXAdaptiveScrollingImprovementIXPEnabled = "True",
					FFlagSelfViewUpdatedCamFraming = "False",
					FFlagSelfViewRemoveVPFWhenClosed = "False",
					DFIntVideoMaxNumberOfVideosPlaying = "0",
					DFFlagPhysicsMechanismCacheOptimizeAlloc = "True",
					FFlagSelfViewMoreNilChecks = "False",
					FFlagEnablePreferredTextSizeScalePerLayerCollector = "True",
					DFIntConnectionMTUSize = "900",
					FFlagSelfViewHumanoidNilCheck = "False",
					DFFlagEnableSoundPreloading = "True",
					FIntGrassMovementReducedMotionFactor = "0",
					FFlagRenderEnableGlobalInstancingD3D10 = "True",
					FFlagAXAdaptiveScrollingAvatarEditor2 = "True",
					FFlagFixEmotesMenuVR = "True",
					FFlagEnableChildrenLockFromLua = "False",
					FFlagEnableBetterHapticsResultHandling = "True",
					FFlagDebugDisableTelemetryV2Stat = "True",
					FFlagLuaAppGenreUnderConstruction = "False",
					FFlagRenderShadowSkipHugeCulling = "True",
					FFlagGraphicsEnableD3D10Compute = "True",
					FFlagDebugRenderingSetDeterministic = "True",
					FIntRomarkStartWithGraphicQualityLevel = "1",
					DFFlagOptimizeIsA = "True",
					FFlagSelfViewFixes = "False",
					DFStringWebviewUrlAllowlist = "",
					FFlagAXPortraitSplitAdaptiveScrollingFix2 = "True",
					FFlagSelfieViewEnabled = "True",
					FFlagRenderEnableGlobalInstancingD3D11 = "False",
					FFlagEnableChildrenLockFromLua2 = "False",
					FIntFRMMinGrassDistance = "0",
					FFlagSimEnableDCD16 = "True",
					FFlagVRFixCursorJitterLua = "True",
					FFlagDebugGraphicsPreferD3D11 = "False",
					FIntCAP1209DataSharingRolloutPercentage = "0",
					DFFlagSimDcdRecompUseClosedVoxel4 = "True",
					DFFlagDebugPerfMode = "True",
					FFlagGuiHidingApiSupport2 = "True",
					FFlagEnablePreferredTextSizeStyleFixesInExperienceMenu = "True",
					FFlagRenderFixFog = "True",
					FIntRenderLocalLightUpdatesMax = "1",
					FFlagTopBarUseNewBadge = "False",
					FFlagFixParticleAttachmentCulling = "False",
					FFlagDisableChromeV3StaticSelfView = "False",
					DFFlagSimRefactorCollisionGeometry2 = "True",
					FStringVoiceBetaBadgeLearnMoreLink = "null",
					DFIntContentProviderPreloadHangTelemetryHundredthsPercentage = "0",
					FFlagFixExitDialogBlockVRView = "True",
					FFlagVRBackpackImproved = "True",
					DFIntTeleportClientAssetPreloadingHundredthsPercentage = "100000",
					DFFlagAssetPreloadingUrlVersionEnabled2 = "True",
					FFlagCSGDecalOptimizeVB = "True",
					FIntCAP1544DataSharingUserRolloutPercentage = "0",
					FFlagEnablePreferredTextSizeStyleFixesAddFriends = "True",
					FFlagDeveloperToastNotificationsEnabled = "False",
					FFlagVideoTextureSupportHardwareRender2 = "True",
					FFlagUserHideCharacterParticlesInFirstPerson = "True",
					FIntTaskSchedulerThreadMin = "3",
					FFlagDebugCheckRenderThreading = "True",
					FIntVertexSmoothingGroupTolerance = "1",
					DFIntAnimationLodFacsVisibilityDenominator = "0",
					FFlagSelfViewAvoidErrorOnWrongFaceControlsParenting = "False",
					FFlagUseNotificationServiceIsConnected = "False",
					FIntRefreshRateLowerBound = "120",
					DFStringAltTelegrafAddress = "127.0.0.1",
					FFlagCAP1544UseNewDataSharingRollout = "False",
					FFlagDebugDisableTelemetryEphemeralStat = "True",
					FFlagFixOutdatedTimeScaleParticles = "False",
					FFlagMouseGetPartOptimization = "True",
					FIntBootstrapperWebView2InstallationTelemetryHundredthPercent = "0",
					FFlagNotificationsNoLongerRequireControllerState = "False",
					FIntFullscreenTitleBarTriggerDelayMillis = "3600000",
					FFlagRemoveRedundantFontPreloading = "True",
					FIntStudioExternalNotificationImplMessageWriteTimeOut = "0",
					FFlagShaderLightingRefactor = "True",
					FFlagEnablePreferredTextSizeStyleFixesInPlayerList = "True",
					FIntRenderShadowmapBias = "-1",
					DFIntHACDPointSampleDistApartTenths = "2147483647",
					FIntEnableCullableScene2HundredthPercent3 = "100",
					FFlagLuaAppGamesPagePreloadingDisabled = "False",
					FFlagDebugForceFSMCPULightCulling = "True",
					FFlagEnableRemoveIsFromToastNotification = "False",
					FFlagHandleAltEnterFullscreenManually = "False",
					FFlagGraphicsGLEnableHQShadersExclusion = "False",
					FFlagPreferredTextSizeSettingBetaFeature = "True",
					FFlagEnableAudioEmitterDistanceAttenuation = "True",
					DFIntNumAssetsMaxToPreload = "2147483647",
					FFlagSquadToastNotificationsEnabled = "False",
					FFlagDebugDisableTelemetryV2Event = "True",
					DFFlagTeleportPreloadingMetrics5 = "True",
					FFlagLuaAppEnableToastNotificationsCoreScripts4 = "False",
					FFlagNewLightAttenuation = "True",
					FFlagEnableCullableScene2OptimizeStep = "True",
					FFlagFixSelfViewPopin = "False",
					DFFlagVoiceChatTurnOnMuteUnmuteNotificationHack = "False",
					FFlagMockOpenSelfViewForCameraUser = "False",
					DFStringAnalyticsNS1BeaconConfig = "https://127.0.0.1:443/|g2hjxw|https://127.0.0.1:443/|g2g5dg|https://127.0.0.1:443/|148d53m",
					DFIntTeleportClientAssetPreloadingHundredthsPercentage2 = "100000",
					FFlagEnablePreferredTextSizeStyleFixesInAppShell3 = "True",
					FFlagDebugDeterministicParticles = "False",
					FFlagNotificationPluginSignalRReadEvents = "False",
					FIntTextureCompositorLowResFactor = "4",
					FFlagDebugSelfViewPerfBenchmark = "False",
					FStringTerrainMaterialTablePre2022 = "",
					DFFlagTeleportClientAssetPreloadingDoingExperiment2 = "True",
					DFIntBufferCompressionLevel = "0",
					FFlagVisBugChecksThreadYield = "True",
					FFlagNotificationButtonTypeVariantMappingEmphasis = "False",
					FFlagRenderLegacyShadowsQualityRefactor = "True",
					FFlagEnableVRFTUXExperienceV2 = "True",
					FFlagSelfViewTweaksPass = "False",
					DFFlagAudioEnableVolumetricPanningForPolys = "True",
					FFlagDebugDisableTelemetryV2Counter = "True",
					FFlagDebugStudioForceSystemDeprecationNotification = "False",
					DFFlagSimSkipVoxelCDECMerge = "true",
					FFlagEnablePreferredTextSizeStyleFixesInAppShell4 = "True",
					DFIntDebugAdditionalNumberOfMipsToSkipForNonAlbedoTextures = "0",
					FFlagMigrateTextureManagerIsLocalAsset = "True",
					FFlagFixIGMBottomBarVisibility = "True",
					DFIntCullFactorPixelThresholdShadowMapLowQuality = "2147483647",
					FFlagDebugEnableDirectAudioOcclusion2 = "True",
					FFlagRenderOptimizeDecalTransparencyInvalidation = "True",
					DFFlagEnableMeshPreloading2 = "True",
					FIntRenderShadowIntensity = "0",
					FFlagSelfViewCameraDefaultButtonInViewPort = "False",
					FFlagEnableBubbleChatFromChatService = "False",
					FIntFriendRequestNotificationThrottle = "0",
					FFlagCAP1209EnableDataSharingUI4 = "False",
					DFFlagUseVisBugChecks = "True",
					FFlagEnablePreferredTextSizeStyleFixesInAvatarExp = "True",
					DFFlagWindowsWebViewTelemetryEnabled = "False",
					FFlagFixCountOfUnreadNotificationError = "False",
					DFFlagDebugPauseVoxelizer = "True",
					FFlagUpdateHTTPCookieStorageFromWKWebView = "False",
					DFFlagSimSolverOptimizeGeometricStiffness4 = "True",
					FFlagUserSoundsUseRelativeVelocity2 = "True",
					DFIntCSGLevelOfDetailSwitchingDistanceL34 = "0",
					FFlagDontRerenderForBadTexture = "True",
					DFFlagAudioEnableVolumetricPanningForMeshes = "True",
					DFFlagOpenCloudV1CreateUserNotificationAsync = "False",
					DFIntTimestepArbiterThresholdCFLThou = "300",
					FFlagDebugEnableVRFTUXExperienceInStudio = "True",
					FFlagDebugDisableTelemetryEventIngest = "True",
					FIntStudioResendDisconnectNotificationInterval = "0",
					FFlagPreOptimizeNoCollisionPrimitive = "True",
					DFIntCullFactorPixelThresholdShadowMapHighQuality = "2147483647",
					FIntDirectionalAttenuationMaxPoints = "1",
					FFlagFixChunkLightingUpdate2 = "True",
					DFFlagSimOptimizeSetSize = "True",
					FStringGetPlayerImageDefaultTimeout = "1",
					FFlagLoginPageOptimizedPngs = "True",
					FFlagChatTranslationEnableSystemMessage = "False",
					FFlagEnablePreferredTextSizeStyleFixesInReportMenu = "True",
					FIntDebugForceMSAASamples = "0",
					DFIntDebugLimitMinTextureResolutionWhenSkipMips = "0",
					FIntStudioWebView2TelemetryHundredthsPercent = "0",
					FFlagAXAdaptiveScrollingSnapItemEditor = "True",
					DFFlagOptimizePartsInPart = "True",
					FFlagAdaptiveScrollingFrameOnServer = "True",
					DFFlagEnableTexturePreloading = "True",
					FFlagRenderNoLowFrmBloom = "False",
					DFFlagTeleportClientAssetPreloadingEnabledIXP = "True",
					DFFlagTeleportClientAssetPreloadingDoingExperiment = "True",
					FIntBloomFrmCutoff = "-1",
					FFlagPreloadTextureItemsOption4 = "True",
					FFlagEnablePreferredTextSizeStyleFixesInCaptureMenu = "True",
					FFlagSyncWebViewCookieToEngine2 = "False",
					DFIntAnimationLodFacsDistanceMax = "0",
					DFIntHttpParallelLimit_RequestExperienceNotificationService = "0",
					FStringInExperienceNotificationsLayer = "",
					FFlagFixParticleEmissionBias2 = "False",
					FFlagRenderCBRefactor2 = "True",
					FStringGraphicsDisableUnalignedDxtGPUNameBlacklist = "null",
					DFFlagTextureQualityOverrideEnabled = "True",
					FFlagEnablePreferredTextSizeSettingInMenus2 = "True",
					DFIntMacWebViewTelemetryThrottleHundredthsPercent = "0",
					DFFlagDebugOverrideDPIScale = "False",
					DFIntCSGLevelOfDetailSwitchingDistanceL12 = "0",
					FFlagRenderTestEnableDistanceCulling = "True",
					FFlagDisablePostFx = "True",
					DFFlagOptimizeClusterCacheAlloc = "True",
					FIntRenderLocalLightFadeInMs = "0",
					FFlagLuaAppEnableParentalControlExperiment = "False",
					DFFlagOptimizeInstanceQueries = "True",
					FFlagEnablePreferredTextSizeGuiService = "True",
					FFlagDebugSSAOForce = "False",
					FFlagRenderSkipReadingShaderData = "False",
					FFlagRemovedRbxRenderingPreProcessor = "False",
					FIntTerrainArraySliceSize = "0",
					FFlagPreloadAllFonts = "True",
					DFFlagDebugRenderForceTechnologyVoxel = "True",
					FFlagContentProviderPreloadHangTelemetry = "False",
					DFIntBufferCompressionThreshold = "100",
					DFIntCodecMaxIncomingPackets = "100",
					DFIntCodecMaxOutgoingFrames = "10000",
					DFIntDataSenderRate = "36420",
					DFIntInitialAccelerationLatencyMultTenths = "1",
					DFIntInterpolationDtLimitForLod = "10",
					DFIntInterpolationFrameRotVelocityThresholdMillionth = "1",
					DFIntInterpolationFrameVelocityThresholdMillionth = "1",
					DFIntInterpolationMinAssemblyCount = "1",
					DFIntInterpolationNumMechanismsBatchSize = "1",
					DFIntInterpolationNumMechanismsPerTask = "5",
					DFIntInterpolationNumParallelTasks = "5",
					DFIntLargePacketQueueSizeCutoffMB = "1000",
					DFIntMaxInterpolationRecursionsBeforeCheck = "1",
					DFIntMaxProcessPacketsJobScaling = "10000",
					DFIntMaxProcessPacketsStepsAccumulated = "0",
					DFIntMaxProcessPacketsStepsPerCyclic = "10000",
					DFIntMegaReplicatorNetworkQualityProcessorUnit = "10",
					DFIntNetworkCluster = "1",
					DFIntNetworkClusterPacketCacheNumParallelTasks = "2",
					DFIntNetworkSchemaCompressionRatio = "100",
					DFIntNumFramesAllowedToBeAboveError = "1",
					DFIntNumFramesToKeepAfterInterpolation = "1",
					DFIntPerformanceControlFrameTimeMax = "1",
					DFIntPerformanceControlFrameTimeMaxUtility = "-1",
					DFIntRakNetClockDriftAdjustmentPerPingMillisecond = "50",
					DFIntRakNetLoopMs = "1",
					DFIntRakNetResendRttMultiple = "1",
					DFIntRaknetBandwidthInfluxHundredthsPercentageV2 = "10000",
					DFIntRaknetBandwidthPingSendEveryXSeconds = "1",
					DFIntS2PhysicsSenderRate = "36420",
					DFIntServerBandwidthPlayerSampleRate = "36420",
					DFIntSignalRCore = "1",
					DFIntSignalRCoreError = "1",
					DFIntSignalRCoreHandshakeTimeoutMs = "1000",
					DFIntSignalRCoreHubBaseRetryMs = "50",
					DFIntSignalRCoreHubMaxBackoffMs = "500",
					DFIntSignalRCoreHubMaxElapsedMs = "5000",
					DFIntSignalRCoreKeepAlivePingPeriodMs = "1000",
					DFIntSignalRCoreNetworkHandler = "1",
					DFIntSignalRCoreRpcQueueSize = "16384",
					DFIntSignalRCoreServerTimeoutMs = "500",
					DFIntSignalRCoreTimerMs = "50",
					DFIntSignalRCoreHubConnectionDisconnectInfoHundredthsPercent = "10",
					DFIntSignalRHubConnectionBaseRetryTimeMs = "50",
					DFIntSignalRHubConnectionConnectTimeoutMs = "7000",
					DFIntSignalRHubConnectionHeartbeatTimerRateMs = "1000",
					DFIntSignalRHubConnectionMaxRetryTimeMs = "500",
					DFIntSignalRHeartbeatIntervalSeconds = "1",
					DFIntSimConstraintDataCollectionRate3 = "36420",
					DFIntTimeBetweenSendConnectionAttemptsMS = "200",
					DFIntVisibilityCheckRayCastLimitPerFrame = "10",
					DFIntWaitOnRecvFromLoopEndedMS = "10",
					DFIntWaitOnUpdateNetworkLoopEndedMS = "100",
					DFFlagAllowPropertyDefaultSkip = "True",
					DFFlagAllowRegistrationOfAnimationClipInCoreScripts = "True",
					DFFlagAnimatorFixReplicationASANError = "True",
					DFFlagClampIncomingReplicationLag = "True",
					DFFlagCorrectCachePolicySkipRedirectCache = "true",
					DFFlagEnableRequestAsyncCompression = "false",
					DFFlagGameNetFixReplicationSkipBug = "true",
					DFFlagNextGenRepRollbackOverbudgetPackets = "true",
					DFFlagNetworkSchemaImprovements = "true",
					DFFlagRakNetCalculateApplicationFeedback2 = "True",
					DFFlagRakNetDecoupleRecvAndUpdateLoopShutdown = "True",
					DFFlagRakNetDetectNetUnreachable = "True",
					DFFlagRakNetDetectRecvThreadOverload = "True",
					DFFlagRakNetDisconnectNotification = "True",
					DFFlagRakNetEnablePoll = "True",
					DFFlagRakNetFixBwCollapse = "False",
					DFFlagRakNetUnblockSelectOnShutdownByWritingToSocket = "True",
					DFFlagRakNetUseSlidingWindow4 = "true",
					DFFlagSkipReadDiskCacheRedirects = "true",
					DFFlagSkipSomeProperties = "true",
					DFFlagSkipSomePropertiesSkip = "true",
					FFlagAnimatorRetargetSkipAnkleModification = "true",
					FFlagDebugNextGenReplicatorEnabledWriteCFrameColor = "true",
					FFlagEnableInGameMenuDurationLogger = "False",
					FFlagNextGenReplicatorEnabledRead = "true",
					FFlagNextGenReplicatorEnabledWrite = "true",
					FFlagPushFrameTimeToHarmony = "True",
					FFlagSkipJoinedSessionLog = "true",
					FFlagUISUseLastFrameTimeInUpdateInputSignal = "True",
				},
				["Low Ping"] = {
					DFFlagRakNetUnblockSelectOnShutdownByWritingToSocket = "True",
					DFFlagAcceleratorUpdateOnPropsAndValueTimeChange = "True",
					DFFlagDebugLargeReplicatorForceFullSend = "true",
					DFFlagSimOptimizeGeometryChangedAssemblies2 = "True",
					DFFlagDebugLargeReplicatorDisableDelta = "true",
					DFFlagNextGenRepRollbackOverbudgetPackets = "True",
					DFFlagRakNetCalculateApplicationFeedback2 = "True",
					DFFlagReplicatorCheckReadTableCollisions = "True",
					DFFlagReplicatorSeparateVarThresholds = "True",
					DFFlagRakNetDetectRecvThreadOverload = "True",
					DFFlagJointIrregularityOptimization = "True",
					DFFlagSimSmoothedRunningController2 = "True",
					DFFlagAnimatorEnableNewAdornments = "True",
					DFFlagClampIncomingReplicationLag = "True",
					DFFlagRakNetDetectNetUnreachable = "True",
					DFFlagSolverStateReplicatedOnly2 = "True",
					DFFlagRakNetUseSlidingWindow4 = "True",
					DFFlagReplicateCreateToPlayer = "True",
					DFFlagFastEndUpdateLoop = "true",
					DFFlagMergeFakeInputEvents3 = "True",
					DFFlagSimOptimizeSetSize = "True",
					DFFlagAnimatorAnywhere = "True",
					DFFlagRakNetEnablePoll = "True",
					DFFlagDebugPerfMode = "True",
					DFFlagCanClientReplicateProp = "False",
					DFFlagDebugOverrideDPIScale = "False",
					DFFlagMouseMoveOncePerFrame = "False",
					DFFlagNetworkUseZstdWrapper = "False",
					DFFlagDisableDPIScale = "False",
					DFFlagFrameTimeStdDev = "False",
					FFlagEnableAnimatorSkipCopyPreviousRigKeyOnJointModification = "True",
					FFlagDebugNextGenReplicatorEnabledWriteCFrameColor = "True",
					FFlagPreComputeAcceleratorArrayForSharingTimeCurve = "True",
					FFlagOnlyDecrementCompletenessIfReplicating = "True",
					FFlagLuaAppLegacyInputSettingRefactor = "True",
					FFlagEnablePerformanceControlService = "True",
					FFlagDebugLargeReplicatorEnabled = "True",
					FFlagMessageBusCallOptimization = "True",
					FFlagDebugLargeReplicatorWrite = "True",
					FFlagDebugLargeReplicatorRead = "True",
					FFlagMouseGetPartOptimization = "True",
					FFlagQuaternionPoseCorrection = "True",
					FFlagLuaMenuPerfImprovements = "True",
					FFlagDebugCodegenOptSize = "True",
					FFlagSortKeyOptimization = "True",
					FFlagFasterPreciseTime4 = "True",
					FFlagSimEnableDCD16 = "True",
					FFlagEnableZstdDictionaryForClientSettings = "False",
					FFlagHandleAltEnterFullscreenManually = "False",
					FFlagEnableInGameMenuDurationLogger = "False",
					FFlagDebugDisableOptimizedBytecode = "False",
					FFlagEnableZstdForClientSettings = "False",
					FFlagKeepZeroInfluenceBones = "False",
					DFIntGraphicsOptimizationModeMaxFrameTimeTargetMs = "25",
					DFIntTimestepArbiterAngAccelerationThresholdThou = "2000",
					DFIntMaxReceiveToDeserializeLatencyMilliseconds = "10",
					DFIntTimestepArbiterAccelerationModelFactorThou = "50000",
					DFIntMegaReplicatorNetworkQualityProcessorUnit = "10",
					DFIntNetworkInProcessLimitGameplayMsClient = "0",
					DFIntPerformanceControlFrameTimeMaxUtility = "-1",
					DFIntClientPacketHealthyAllocationPercent = "20",
					DFIntInitialAccelerationLatencyMultTenths = "1",
					DFIntTimeBetweenSendConnectionAttemptsMS = "200",
					DFIntNetworkQualityResponderMaxWaitTime = "1",
					DFIntMaxProcessPacketsStepsAccumulated = "0",
					DFIntClientPacketMaxFrameMicroseconds = "200",
					DFIntMaxProcessPacketsStepsPerCyclic = "5000",
					DFIntClientPacketExcessMicroseconds = "1000",
					DFIntPerformanceControlFrameTimeMax = "1",
					DFIntWaitOnUpdateNetworkLoopEndedMS = "100",
					DFIntNetworkSchemaCompressionRatio = "100",
					DFIntBatchThumbnailResultsSizeCap = "200",
					DFIntLargePacketQueueSizeCutoffMB = "1000",
					DFIntMaxProcessPacketsJobScaling = "10000",
					DFIntNetworkQualityResponderUnit = "10",
					DFIntBufferCompressionThreshold = "100",
					DFIntWaitOnRecvFromLoopEndedMS = "10",
					DFIntMaxAcceptableUpdateDelay = "1",
					DFIntCodecMaxIncomingPackets = "50",
					DFIntConnectingTimerInterval = "10",
					DFIntBufferCompressionLevel = "0",
					DFIntClientPacketMaxDelayMs = "1",
					DFIntCodecMaxOutgoingFrames = "10000",
					DFIntMaxDataPacketPerSend = "2147483647",
					DFIntS2PhysicsSenderRate = "25000",
					DFIntMaxFrameBufferSize = "4",
					DFIntRuntimeConcurrency = "12",
					DFIntDataSenderRate = "20000",
					FIntSmoothMouseSpringFrequencyTenths = "100",
					FIntRakNetResendBufferArrayLength = "256",
					FIntInterpolationMaxDelayMSec = "100",
					FIntRuntimeMaxNumOfConditions = "1000000",
					FIntRuntimeMaxNumOfSchedulers = "1000000",
					FIntRuntimeMaxNumOfSemaphores = "1000000",
					FIntSimSolverResponsiveness = "2147483647",
					FIntRuntimeMaxNumOfLatches = "1000000",
					FIntRuntimeMaxNumOfMutexes = "1000000",
					FIntRuntimeMaxNumOfThreads = "1000000",
					FIntRuntimeMaxNumOfDPCs = "64",
				},
				["Stutter Ball"] = {
					DFIntPerformanceControlFrameTimeMaxUtility = "-1",
					FFlagEnableBubbleChatFromChatService = "False",
					DFFlagSimOptimizeSetSize = "True",
					DFIntRaknetBandwidthPingSendEveryXSeconds = "-1",
					FIntDebugFRMOptionalMSAALevelOverride = "0",
					DFIntMinimumNumberMechanismsForMT = "1",
					FFlagDebugDisableTelemetryV2Counter = "True",
					FIntRefreshRateLowerBound = "360",
					DFIntClientPacketExcessMicroseconds = "1",
					FFlagEnablePreferredTextSizeScale = "True",
					FFlagLuaMenuPerfImprovements = "True",
					FFlagRenderShadowSkipHugeCulling = "True",
					DFFlagEnableTexturePreloading = "True",
					FFlagEnableChromePinnedChat = "True",
					FFlagFacialAnimationStreamingServiceUniverseSettingsEnableVideo = "False",
					FFlagSelfViewAvoidErrorOnWrongFaceControlsParenting = "False",
					FIntRenderMaxShadowAtlasUsageBeforeDownscale = "0",
					DFIntAssetPreloading = "9999999",
					FFlagEnableBetterHapticsResultHandling = "True",
					DFIntWriteFullDmpPercent = "0",
					DFFlagEnablePerfDataMemoryCategoriesCollection2 = "False",
					FFlagDebugDisplayFPS = "True",
					DFIntRakNetMtuValue2InBytes = "1337",
					FFlagRemovedRbxRenderingPreProcessor = "False",
					FFlagViewCollisionFadeToBlackInVR = "False",
					FFlagDebugDisableTelemetryEphemeralStat = "True",
					DFFlagESGamePerfMonitorEnabled = "False",
					FFlagUserSoundsUseRelativeVelocity2 = "True",
					DFFlagAudioEnableVolumetricPanningForPolys = "True",
					DFIntAssetPermissionsApiPatchAssetsPermissions0TelemetryHundredthsPercent = "0",
					FIntCameraMaxZoomDistance = "999999",
					FFlagDebugDisableOTAMaterialTexture = "true",
					FIntSmoothTerrainPhysicsCacheSize = "3000",
					DFFlagRenderHighlightManagerPrepare = "True",
					DFIntInterpolationDtLimitForLod = "1",
					DFFlagAddPublicGettersForGfxQualityAndFpsForTelemCounters2 = "False",
					DFIntParallelAdaptiveInterpolationBatchCount = "1",
					DFIntAnimationLodFacsDistanceMin = "0",
					FStringTerrainMaterialTable2022 = "",
					DFFlagOpenCloudV1CreateUserNotificationAsync = "False",
					DFFlagTeleportPreloadingMetrics5 = "True",
					DFIntClientPacketHealthyMsPerSecondLimit = "1",
					FFlagDontRerenderForBadTexture = "True",
					FFlagTaskSchedulerLimitTargetFpsTo2402 = "False",
					DFStringAltHttpPointsReporterUrl = "null",
					FFlagSelfViewTweaksPass = "False",
					FIntRakNetResendBufferArrayLength = "128",
					DFIntAMPVerifiedTelemetryHundredthsPercentage = "0",
					FIntTerrainOTAMaxTextureSize = "0",
					FFlagEnableBatteryStateLogger = "False",
					DFStringTelemetryV2Url = "null",
					FStringImmersiveAdsUniverseWhitelist = "0",
					DFFlagEnablePerfDataCountersCollection = "False",
					DFFlagSimRefactorCollisionGeometry2 = "True",
					DFIntServerTickRate = "240",
					FFlagDebugCodegenOptSize = "True",
					DFIntLargePacketQueueSizeCutoffMB = "1",
					DFIntRunningBaseOrientationP = "450",
					FFlagGraphicsGLEnableSuperHQShadersExclusion = "False",
					DFStringRobloxAnalyticsURL = "null",
					FFlagToastNotificationsReceivedAndDismissedSignals = "False",
					DFIntCSGLevelOfDetailSwitchingDistance = "0",
					FIntFriendRequestNotificationThrottle = "0",
					FFlagPreloadAllFonts = "True",
					FFlagEnableMenuControlsABTest = "False",
					FIntUITextureMaxUpdateDepth = "0",
					FFlagEnableInGameMenuChromeABTest3 = "False",
					FFlagSimEnableDCD16 = "True",
					DFFlagEnablePerfDataCoreTimersCollection2 = "False",
					DFIntAppConfigurationTelemetryThrottleHundredthsPercent = "0",
					FIntFRMMinGrassDistance = "0",
					FFlagEngineAPICloudProcessingUseNotificationClient = "False",
					FFlagEnableV3MenuABTest3 = "False",
					FFlagQuaternionPoseCorrection = "True",
					FFlagCommitToGraphicsQualityFix = "True",
					DFIntGameNetPVHeaderLinearVelocityZeroCutoffExponent = "-1",
					DFIntAssetPermissionsApiGetAssetsPermissionsTelemetryHundredthsPercent = "0",
					FFlagToastNotificationsProtocolEnabled2 = "False",
					DFIntVoiceChatRollOffMinDistance = "1",
					FFlagEnablePreferredTextSizeStyleFixesGameTile = "True",
					FFlagDisableChromeV3StaticSelfView = "False",
					FFlagUserFixLoadAnimationError = "True",
					FFlagImmersiveAdsWhitelistDisabled = "False",
					DFIntRakNetLoopMs = "0",
					FFlagWindowsReportAbuseNotification = "False",
					FIntTaskSchedulerThreadMin = "240000",
					DFLogHttpTraceLight = "0",
					FFlagRemoveRedundantFontPreloading = "True",
					DFStringRobloxAnalyticsSubDomain = "opt-out",
					FFlagFixSettingsHubVRBackgroundError = "True",
					DFIntCodecMaxIncomingPackets = "2139999999",
					DFFlagDebugRenderForceTechnologyVoxel = "True",
					DFIntTaskSchedulerTargetFps = "1000",
					DFFlagWindowsWebViewTelemetryEnabled = "False",
					FFlagBetaBadgeLearnMoreLinkFormview = "False",
					FIntV1MenuLanguageSelectionFeaturePerMillageRollout = "0",
					DFIntWaitOnUpdateNetworkLoopEndedMS = "100",
					FFlagLuaAppEnableParentalControlExperiment = "False",
					FFlagAXAdaptiveScrollingImprovementIXPEnabled = "True",
					FFlagUserShowGuiHideToggles = "True",
					FIntStartupInfluxHundredthsPercentage = "0",
					FFlagFixGraphicsQuality = "True",
					FFlagGraphicsGLEnableHQShadersExclusion = "False",
					DFFlagQueueDataPingFromSendData = "True",
					FFlagOptimizeServerTickRate = "True",
					FFlagFacialAnimationStreamingServiceUserSettingsOptInAudio = "False",
					FFlagGraphicsCheckComputeSupport = "True",
					FFlagEnablePreferredTextSizeStyleFixesAddFriends = "True",
					FIntFullscreenTitleBarTriggerDelayMillis = "3600000",
					FFlagEnableAudioEmitterDistanceAttenuation = "True",
					DFStringLightstepHTTPTransportUrlHost = "null",
					DFIntTimestepArbiterThresholdCFLThou = "300",
					FFlagEnableAdsAPI = "False",
					DFFlagTeleportClientAssetPreloadingEnabledIXP2 = "True",
					FFlagAXSearchLandingPageIXPEnabled4 = "False",
					FFlagLoginPageOptimizedPngs = "True",
					DFIntAnimationLodFacsVisibilityDenominator = "0",
					DFFlagNotificationServiceIsConnectedProperty = "False",
					FFlagSelfieViewEnabled = "True",
					FFlagFastGPULightCulling3 = "True",
					FFlagVideoTextureSupportHardwareRender = "True",
					FFlagLuaAppGamesPagePreloadingDisabled = "False",
					DFIntVoiceChatRollOffMaxDistance = "300",
					DFIntVideoMaxNumberOfVideosPlaying = "0",
					FFlagDebugSelfViewPerfBenchmark = "False",
					DFIntDefaultTimeoutTimeMs = "10000",
					FFlagLuauCodegen = "True",
					DFIntNewRunningBaseAltitudeD = "195",
					FFlagUserEnableCameraToggleNotification = "False",
					DFFlagDebugOverrideDPIScale = "False",
					DFFlagUnifyLegacyJointGeometry = "True",
					FFlagDisablePostFx = "True",
					FIntVertexSmoothingGroupTolerance = "0",
					DFIntGameNetPVHeaderRotationOrientIdToleranceExponent = "-1",
					FFlagControlBetaBadgeWithGuac = "False",
					DFIntPlayerNetworkUpdateRate = "100000000",
					DFIntMaxProcessPacketsStepsAccumulated = "0",
					FFlagAnimationClipMemCacheEnabled = "True",
					FIntReportDeviceInfoRollout = "0",
					FFlagInterpolationAwareTargetTime = "True",
					DFIntWindowsWebViewTelemetryThrottleHundredthsPercent = "0",
					FFlagAXAdaptiveScrollingItemResetFix2 = "True",
					DFIntMegaReplicatorNetworkQualityProcessorUnit = "-1",
					FLogNetwork = "7",
					DFFlagEnablePerfDataGatherTelemetry2 = "False",
					FFlagFixSensitivityTextPrecision = "False",
					FFlagMovePrerenderV2 = "True",
					DFIntMaxReceiveToDeserializeLatencyMilliseconds = "1",
					FFlagFixChunkLightingUpdate2 = "True",
					FStringGraphicsDisableUnalignedDxtGPUNameBlacklist = "null",
					FFlagPreOptimizeNoCollisionPrimitive = "True",
					DFFlagEnableFmodErrorsTelemetry = "False",
					FFlagRenderDynamicResolutionScale9 = "True",
					FFlagEnableChildrenLockFromLua = "False",
					FFlagSettingsHubIndependentBackgroundVisibility = "True",
					DFFlagTextureQualityOverrideEnabled = "True",
					DFIntCSGLevelOfDetailSwitchingDistanceL23 = "0",
					FFlagTopBarUseNewBadge = "False",
					FFlagShaderLightingRefactor = "True",
					FIntRuntimeMaxNumOfThreads = "20000",
					DFFlagEnablePerfDataCoreCategoryTimersCollection2 = "False",
					FFlagEnableChildrenLockFromLua2 = "False",
					DFFlagAudioUseVolumetricPanning = "True",
					DFFlagEnablePerfDataMemoryCollection = "False",
					DFIntNumAssetsMaxToPreload = "9999999",
					FFlagDebugEnableVRFTUXExperienceInStudio = "True",
					DFIntDebugAdditionalNumberOfMipsToSkipForNonAlbedoTextures = "10",
					FFlagDebugDisableTelemetryV2Stat = "True",
					DFFlagAudioToggleVolumetricPanning = "True",
					DFFlagTeleportClientAssetPreloadingDoingExperiment2 = "True",
					FFlagEnablePreferredTextSizeSettingInMenus2 = "True",
					FFlagHandleAltEnterFullscreenManually = "False",
					FIntRakNetDatagramMessageIdArrayLength = "8192",
					FIntRenderGrassDetailStrands = "0",
					FFlagFixCountOfUnreadNotificationError = "False",
					DFStringCrashUploadToBacktraceMacPlayerToken = "null",
					FFlagEnablePreferredTextSizeStyleFixesInPlayerList = "True",
					FStringVoiceBetaBadgeLearnMoreLink = "null",
					FFlagFixOutdatedTimeScaleParticles = "False",
					DFIntNumFramesAllowedToBeAboveError = "0",
					FIntTargetRefreshRate = "480",
					FFlagNotificationPluginSignalRReadEvents = "False",
					FFlagPreloadMinimalFonts = "True",
					DFFlagEnablePerfDataMemoryPressureCollection = "False",
					DFFlagEnableExperienceNotificationOptInPrompt = "False",
					FIntMockClientLightingTechnologyIxpExperimentQualityLevel = "1",
					FIntTextureCompositorLowResFactor = "4",
					FFlagEnablePreferredTextSizeStyleFixesInCaptureMenu = "True",
					FIntBloomFrmCutoff = "-1",
					FFlagEnableVRFTUXExperienceV2 = "True",
					DFFlagDebugPauseVoxelizer = "True",
					FFlagVRFixCursorJitterLua = "True",
					FFlagDebugDisableTelemetryEventIngest = "True",
					FFlagFixReducedMotionStuckIGM2 = "True",
					FFlagShoeSkipRenderMesh = "False",
					FFlagMockOpenSelfViewForCameraUser = "False",
					DFFlagDebugAnalyticsSendUserId = "False",
					FFlagEnableChromeFTUX = "True",
					DFIntTeleportClientAssetPreloadingHundredthsPercentage2 = "100000",
					FIntRenderShadowIntensity = "0",
					FFlagNotificationButtonTypeVariantMappingEmphasis = "False",
					FFlagRenderLegacyShadowsQualityRefactor = "True",
					FIntStudioExternalNotificationImplMessageWriteTimeOut = "0",
					FIntRenderLocalLightUpdatesMax = "0",
					FFlagVisBugChecksThreadYield = "True",
					FFlagRenderInitShadowmaps = "false",
					DFFlagVoiceChatTurnOnMuteUnmuteNotificationHack = "False",
					DFIntRakNetMtuValue1InBytes = "1396",
					FFlagDontCreatePingJob = "True",
					DFIntAnimationLodFacsDistanceMax = "0",
					FFlagFRMRefactor = "True",
					DFStringWebviewUrlAllowlist = "",
					FFlagOptimizeNetworkTransport = "True",
					DFIntAnimatorThrottleMaxFramesToSkip = "1",
					FFlagEnablePreferredTextSizeStyleFixesInAppShell3 = "True",
					FFlagUseNotificationServiceIsConnected = "False",
					DFFlagTeleportClientAssetPreloadingDoingExperiment = "True",
					DFIntNetworkPrediction = "240",
					DFIntGameNetPVHeaderRotationalVelocityZeroCutoffExponent = "-1",
					DFIntOptimizePingThreshold = "20",
					DFStringCrashUploadToBacktraceWindowsPlayerToken = "null",
					FFlagLuaAppGenreUnderConstruction = "False",
					FFlagAdaptiveScrollingFrameOnServer = "True",
					DFFlagEphemeralCounterInfluxReportingEnabled = "False",
					FFlagRenderCBRefactor2 = "True",
					FStringDebugGraphicsPreferredGPUName = "Radeon Pro Vega 56",
					FFlagGuiHidingApiSupport2 = "True",
					FIntBootstrapperTelemetryReportingHundredthsPercentage = "0",
					DFIntDebugDefaultTargetWorldStepsPerFrame = "7500",
					FFlagAdServiceEnabled = "False",
					DFIntClientPacketUnhealthyContEscMsPerSecond = "1",
					FFlagRenderDebugCheckThreading2 = "True",
					FIntRenderGrassHeightScaler = "0",
					FIntPreferredTextSizeSettingBetaFeatureRolloutPercent = "100",
					FFlagSignalRNotificationManagerMaybeStart = "False",
					FFlagDebugDisableTelemetryV2Event = "True",
					DFFlagAssetPreloadingUrlVersionEnabled2 = "True",
					FFlagEnableCapturesHotkeyExperiment_v4 = "False",
					DFIntTextureQualityOverride = "0",
					DFIntClientLightingEnvmapPlacementTelemetryHundredthsPercent = "0",
					FFlagDebugCheckRenderThreading = "True",
					DFIntRakNetPingFrequencyMillisecond = "10",
					FFlagFixParticleAttachmentCulling = "False",
					FFlagEnablePreferredTextSizeScalePerLayerCollector = "True",
					DFIntNetworkLatencyTolerance = "-1",
					FIntTaskSchedulerMaxNumOfJobs = "2139999999",
					FFlagGlobalWindRendering = "false",
					FFlagDisableNewIGMinDUA = "True",
					DFFlagGpuVsCpuBoundTelemetry = "False",
					FFlagCoreGuiSelfViewVisibilityFixed = "False",
					FFlagLuaAppEnableToastNotificationsCoreScripts4 = "False",
					FFlagSelfViewLookUpHumanoidByType = "False",
					DFIntVoiceChatMaxRecordedDataDeliveryIntervalMs = "2147483647",
					FFlagVRBackpackImproved = "True",
					DFFlagUseVisBugChecks = "True",
					DFIntMaxProcessPacketsStepsPerCyclic = "2139999999",
					DFIntRakNetSelectUnblockSocketWriteDurationMs = "10",
					FFlagNewLightAttenuation = "True",
					FStringPartTexturePackTablePre2022 = "{\"foil\":{\"ids\":[\"rbxassetid://13576561565\",\"rbxassetid://13576561565\"],\"color\":[0,0,0,0]},\"asphalt\":{\"ids\":[\"rbxassetid://13576561565\",\"rbxassetid://13576561565\"],\"color\":[0,0,0,0]},\"basalt\":{\"ids\":[\"rbxassetid://13576561565\",\"rbxassetid://13576561565\"],\"color\":[0,0,0,0]},\"brick\":{\"ids\":[\"rbxassetid://13576561565\",\"rbxassetid://9438453972\"],\"color\":[0,0,0,0]},\"cobblestone\":{\"ids\":[\"rbxassetid://13576561565\",\"rbxassetid://9438453972\"],\"color\":[0,0,0,0]},\"concrete\":{\"ids\":[\"rbxassetid://13576561565\",\"rbxassetid://9438453972\"],\"color\":[0,0,0,0]},\"crackedlava\":{\"ids\":[\"rbxassetid://13576561565\",\"rbxassetid://9438453972\"],\"color\":[0,0,0,0]},\"diamondplate\":{\"ids\":[\"rbxassetid://13576561565\",\"rbxassetid://9438453972\"],\"color\":[0,0,0,0]},\"fabric\":{\"ids\":[\"rbxassetid://13576561565\",\"rbxassetid://9438453972\"],\"color\":[0,0,0,0]},\"glacier\":{\"ids\":[\"rbxassetid://13576561565\",\"rbxassetid://9438453972\"],\"color\":[0,0,0,0]},\"glass\":{\"ids\":[\"rbxassetid://13576561565\",\"rbxassetid://9438453972\"],\"color\":[0,0,0,0]},\"granite\":{\"ids\":[\"rbxassetid://13576561565\",\"rbxassetid://9438453972\"],\"color\":[0,0,0,0]},\"grass\":{\"ids\":[\"rbxassetid://13576561565\",\"rbxassetid://9438453972\"],\"color\":[0,0,0,0]},\"ground\":{\"ids\":[\"rbxassetid://13576561565\",\"rbxassetid://9438453972\"],\"color\":[0,0,0,0]},\"ice\":{\"ids\":[\"rbxassetid://13576561565\",\"rbxassetid://9438453972\"],\"color\":[0,0,0,0]},\"leafygrass\":{\"ids\":[\"rbxassetid://13576561565\",\"rbxassetid://9438453972\"],\"color\":[0,0,0,0]},\"limestone\":{\"ids\":[\"rbxassetid://13576561565\",\"rbxassetid://9438453972\"],\"color\":[0,0,0,0]},\"marble\":{\"ids\":[\"rbxassetid://13576561565\",\"rbxassetid://9438453972\"],\"color\":[0,0,0,0]},\"metal\":{\"ids\":[\"rbxassetid://13576561565\",\"rbxassetid://9438453972\"],\"color\":[0,0,0,0]},\"mud\":{\"ids\":[\"rbxassetid://13576561565\",\"rbxassetid://9438453972\"],\"color\":[0,0,0,0]},\"pavement\":{\"ids\":[\"rbxassetid://13576561565\",\"rbxassetid://9438453972\"],\"color\":[0,0,0,0]},\"pebble\":{\"ids\":[\"rbxassetid://13576561565\",\"rbxassetid://9438453972\"],\"color\":[0,0,0,0]},\"plastic\":{\"ids\":[\"\",\"rbxassetid://13576561565\"],\"color\":[0,0,0,0]},\"rock\":{\"ids\":[\"rbxassetid://13576561565\",\"rbxassetid://9438453972\"],\"color\":[0,0,0,0]},\"corrodedmetal\":{\"ids\":[\"rbxassetid://13576561565\",\"rbxassetid://9439557520\"],\"color\":[0,0,0,0]},\"salt\":{\"ids\":[\"rbxassetid://13576561565\",\"rbxassetid://9438453972\"],\"color\":[0,0,0,0]},\"sand\":{\"ids\":[\"rbxassetid://13576561565\",\"rbxassetid://9438453972\"],\"color\":[0,0,0,0]},\"sandstone\":{\"ids\":[\"rbxassetid://13576561565\",\"rbxassetid://9438453972\"],\"color\":[0,0,0,0]},\"slate\":{\"ids\":[\"rbxassetid://13576561565\",\"rbxassetid://9439613006\"],\"color\":[0,0,0,0]},\"snow\":{\"ids\":[\"rbxassetid://13576561565\",\"rbxassetid://9438453972\"],\"color\":[0,0,0,0]},\"wood\":{\"ids\":[\"rbxassetid://13576561565\",\"rbxassetid://9439649548\"],\"color\":[0,0,0,0]},\"woodplanks\":{\"ids\":[\"rbxassetid://13576561565\",\"rbxassetid://9438453972\"],\"color\":[0,0,0,0]}}",
					DFIntGameNetPVHeaderTranslationZeroCutoffExponent = "-1",
					FFlagPreloadTextureItemsOption4 = "True",
					FFlagLuaAppsEnableParentalControlsTab = "False",
					FFlagPushFrameTimeToHarmony = "True",
					FIntRenderLocalLightUpdatesMin = "0",
					DFIntWaitOnRecvFromLoopEndedMS = "0",
					FIntRobloxGuiBlurIntensity = "0",
					DFIntMaxFrameBufferSize = "-1",
					DFFlagAdsPreloadInteractivityAssets = "True",
					DFIntClientPacketMaxDelayMs = "1",
					DFFlagBaseNetworkMetrics = "False",
					FIntFixForBulkPresenceNotifications = "0",
					DFIntCSGLevelOfDetailSwitchingDistanceL34 = "0",
					DFIntAccelerationTimeThreshold = "0",
					DFIntClientPacketMaxFrameMicroseconds = "1",
					DFIntTeleportClientAssetPreloadingHundredthsPercentage = "100000",
					FFlagPreferredTextSizeSettingBetaFeature = "True",
					FFlagChatTranslationEnableSystemMessage = "False",
					DFIntMacWebViewTelemetryThrottleHundredthsPercent = "0",
					FFlagSelfViewFixes = "False",
					DFIntRakNetMinAckGrowthPercent = "100",
					FFlagVRLaserPointerOptimization = "True",
					FFlagRenderLightGridEfficientTextureAtlasUpdate = "True",
					DFIntPlayerNetworkUpdateQueueSize = "60",
					DFIntInterpolationNumMechanismsPerTask = "100",
					FFlagNotificationsNoLongerRequireControllerState = "False",
					DFFlagEnablePerfRenderStatsCollection2 = "False",
					FIntInterpolationAwareTargetTimeLerpHundredth = "250",
					DFIntHttpParallelLimit_RequestExperienceNotificationService = "0",
					FFlagLuaAppSystemBar = "False",
					FFlagAudioDeviceTelemetry = "false",
					FFlagEnableVisBugChecks27 = "True",
					FIntDebugForceMSAASamples = "1",
					FIntEnableVisBugChecksHundredthPercent27 = "0",
					FFlagSelfViewCameraDefaultButtonInViewPort = "False",
					DFFlagTeleportClientAssetPreloadingEnabled9 = "True",
					DFIntDetectCrashEarlyPercentage = "0",
					DFIntDebugFRMQualityLevelOverride = "1",
					FFlagHighlightOutlinesOnMobile = "True",
					DFFlagBrowserTrackerIdTelemetryEnabled = "False",
					FFlagFixParticleEmissionBias2 = "False",
					FIntFRMMaxGrassDistance = "0",
					DFStringAltTelegrafAddress = "127.0.0.1",
					FFlagUISUseLastFrameTimeInUpdateInputSignal = "True",
					FIntVRTouchControllerTransparency = "0",
					DFFlagPhysicsMechanismCacheOptimizeAlloc = "True",
					FFlagDebugSSAOForce = "False",
					FFlagDebugRenderingSetDeterministic = "True",
					DFIntConnectionMTUSize = "576",
					DFIntMicroProfilerDpiScaleOverride = "90",
					FFlagContentProviderPreloadHangTelemetry = "False",
					FFlagEnableInGameMenuControls = "True",
					FStringTerrainMaterialTablePre2022 = "",
					FIntStudioWebView2TelemetryHundredthsPercent = "0",
					FFlagEnablePreferredTextSizeStyleFixesInReportMenu = "True",
					DFFlagOptimizeClusterCacheAlloc = "True",
					DFIntContentProviderPreloadHangTelemetryHundredthsPercentage = "0",
					FFlagDebugDeterministicParticles = "False",
					FFlagDebugEnableDirectAudioOcclusion2 = "True",
					FFlagSelfViewHumanoidNilCheck = "False",
					FIntGrassMovementReducedMotionFactor = "0",
					DFFlagCrashUploadFullDumps = "False",
					DFIntAMPVerifiedTelemetryPointsHundredthsPercentage = "0",
					FIntAXAdaptiveScrollingJustSelectedMillis = "2000",
					DFFlagHttpCacheCleanBasedOnMemory = "True",
					FFlagDebugDisableTelemetryEphemeralCounter = "True",
					FIntSelfViewTooltipLifetime = "0",
					DFIntVoiceChatRollOffMode = "2",
					FIntMockClientLightingTechnologyIxpExperimentMode = "0",
					FStringPerformanceSendMeasurementAPISubdomain = "opt-out",
					FFlagDebugSkyGray = "True",
					FFlagFixEmotesMenuVR = "True",
					DFIntClientPacketHealthyAllocationPercent = "100",
					FFlagEnableRemoveIsFromToastNotification = "False",
					DFIntTargetTimeDelayFacctorTenths = "1",
					FFlagRenderNoLowFrmBloom = "False",
					FFlagAvatarChatIncludeSelfViewOnTelemetry = "False",
					DFFlagEnableMeshPreloading2 = "True",
					FFlagSyncWebViewCookieToEngine2 = "False",
					FFlagUpdateHTTPCookieStorageFromWKWebView = "False",
					FFlagEnablePreferredTextSizeStyleFixesInExperienceMenu = "True",
					FFlagAXAdaptiveScrollingAvatarEditor2 = "True",
					DFIntCanHideGuiGroupId = "32380007",
					FFlagAssetPreloadingIXP = "True",
					FFlagAXPortraitSplitAdaptiveScrollingFix2 = "True",
					FFlagToastNotificationsResendDisplayOnInit = "False",
					FIntMaquettesFrameRateBufferPercentage = "1",
					FFlagFacialAnimationStreamingServiceUniverseSettingsEnableAudio = "False",
					DFFlagEnablePerfAudioCollection = "False",
					DFIntBrowserTrackerApiDeviceInitializeRolloutPercentage = "0",
					FIntRenderShadowmapBias = "-1",
					DFIntActionStationDebounceTime = "0",
					DFIntServerPhysicsUpdateRate = "240",
					DFIntCullFactorPixelThresholdShadowMapLowQuality = "2147483647",
					FFlagRenderSkipReadingShaderData = "False",
					DFFlagEnablePerfDataSubsystemTimersCollection2 = "False",
					FFlagOptimizeNetwork = "True",
					FFlagEnableAudioPannerFiltering = "True",
					FIntTerrainArraySliceSize = "0",
					FIntRuntimeMaxNumOfConditions = "5000",
					FFlagClientToastNotificationsEnabled = "False",
					FIntRuntimeMaxNumOfLatches = "20000",
					FFlagOptimizeNetworkRouting = "True",
					FFlagCSGDecalOptimizeVB = "True",
					FIntSSAOMipLevels = "0",
					DFIntClientPacketMinMicroseconds = "1",
					FFlagDebugStudioForceSystemDeprecationNotification = "False",
					DFIntAssetPermissionsApiGetOperationsTelemetryHundredthsPercent = "0",
					FFlagImproveShiftLockTransition = "True",
					DFFlagOptimizeNoCollisionPrimitiveInMidphaseCrash = "True",
					FIntRenderLocalLightFadeInMs = "0",
					FIntNumFramesToCaptureCallStack = "1",
					DFIntTouchSenderMaxBandwidthBps = "-1",
					FFlagDeveloperToastNotificationsEnabled = "False",
					FFlagDebugGraphics = "False",
					FFlagReportFpsAndGfxQualityPercentiles = "False",
					DFIntPerformanceControlFrameTimeMax = "1",
					FFlagFixIGMTabTransitions = "True",
					FStringInExperienceNotificationsLayer = "",
					DFFlagSimSolverOptimizeGeometricStiffness4 = "True",
					FFlagCloudsReflectOnWater = "False",
					FFlagRenderGpuTextureCompressor = "True",
					FFlagEnablePreferredTextSizeGuiService = "True",
					FFlagNewOptimizeNoCollisionPrimitiveInMidphase637 = "True",
					FFlagMigrateTextureManagerIsLocalAsset = "True",
					DFFlagAudioEnableVolumetricPanningForMeshes = "True",
					FFlagSelfViewGetRidOfFalselyRenderedFaceDecal = "False",
					DFIntCodecMaxOutgoingFrames = "2139999999",
					FFlagEnableIOSWebViewCookieSyncFix = "False",
					FFlagSquadToastNotificationsEnabled = "False",
					FFlagGraphicsTextureCopy = "True",
					FIntAbuseReportScreenshotMaxSize = "0",
					DFIntMinimalNetworkPrediction = "1",
					FFlagMSRefactor5 = "False",
					FFlagAXFixAdaptiveScrollingSnapAndroid = "True",
					DFStringLightstepToken = "null",
					FIntMeshContentProviderForceCacheSize = "268435456",
					DFIntMaxProcessPacketsJobScaling = "2139999999",
					DFFlagDebugSkipMeshVoxelizer = "True",
					FIntStudioResendDisconnectNotificationInterval = "0",
					DFFlagDebugPerfMode = "True",
					FIntTaskSchedulerAutoThreadLimit = "16",
					FIntDebugTextureManagerSkipMips = "10",
					DFIntHACDPointSampleDistApartTenths = "2147483647",
					DFIntRuntimeConcurrency = "2139999999",
					FFlagEnableCommandAutocomplete = "False",
					DFIntCullFactorPixelThresholdShadowMapHighQuality = "2147483647",
					FFlagDebugForceFSMCPULightCulling = "True",
					FIntUnifiedLightingBlendZone = "0",
					DFIntRuntimeTickrate = "2139999999",
					FFlagRenderPerformanceTelemetry = "False",
					DFFlagTeleportClientAssetPreloadingEnabledIXP = "True",
					FIntDirectionalAttenuationMaxPoints = "1",
					FFlagRenderOptimizeDecalTransparencyInvalidation = "True",
					FFlagUseNotificationsLocalization = "False",
					FFlagInExperienceUpsellSelfViewFix = "False",
					FFlagVRMouseMoveOptimization = "True",
					FFlagSelfViewRemoveVPFWhenClosed = "False",
					FFlagEnableInGameMenuModernization = "True",
					FFlagStudioDataCollectionAddBasicNotification = "False",
					DFIntMaxFramesToSend = "1",
					FIntRuntimeMaxNumOfMutexes = "20000",
					DFIntRakNetMtuValue3InBytes = "1250",
					FIntBootstrapperWebView2InstallationTelemetryHundredthPercent = "0",
					DFIntClientLightingTechnologyChangedTelemetryHundredthsPercent = "0",
					FFlagDebugDisableTelemetryPoint = "True",
					FFlagFixExitDialogBlockVRView = "True",
					DFFlagEnableGCapsHardwareTelemetry = "False",
					DFLogHttpTrace = "0",
					DFFlagOptimizeIsA = "True",
					DFFlagGraphicsOptimizationModeMVPExposureEnrollment3 = "False",
					DFFlagEnablePerfStatsCollection3 = "False",
					DFIntDebugRestrictGCDistance = "1",
					FFlagSelfViewUpdatedCamFraming = "False",
					FFlagRenderFixFog = "True",
					FFlagVoiceBetaBadge = "False",
					FFlagEnablePreferredTextSizeConnection = "True",
					FFlagAXAdaptiveScrollingSnapItemEditor = "True",
					FFlagFixSelfViewPopin = "False",
					DFIntDebugLimitMinTextureResolutionWhenSkipMips = "0",
					FFlagEnableExperienceNotificationPrompts2 = "False",
					DFFlagEngineAPISendNotificationClientAnalytics = "False",
					DFFlagAddUserIdToSessionTracking = "False",
					FFlagEnableInGameMenuChrome = "True",
					FFlagFixIGMBottomBarVisibility = "True",
					FFlagEnablePreferredTextSizeStyleFixesInPurchasePrompt = "True",
					DFIntAssetPermissionsApiPostAssetsCheckPermissionsTelemetryHundredthsPercent = "0",
					DFFlagEnableSoundPreloading = "True",
					DFIntCSGLevelOfDetailSwitchingDistanceL12 = "0",
					FFlagDebugForceGenerateHSR = "True",
					FIntRuntimeMaxNumOfSchedulers = "20000",
					FFlagDisableFeedbackSoothsayerCheck = "False",
					FStringGamesUrlPath = "/games/",
					DFIntLightstepHTTPTransportHundredthsPercent2 = "0",
					FFlagSelfViewMoreNilChecks = "False",
					DFIntRakNetResendRttMultiple = "1",
					FFlagToastNotificationsUpdateEventParams = "False",
					FFlagUserHideCharacterParticlesInFirstPerson = "True",
					FFlagLocServicePerformanceAnalyticsEnabled = "False",
					FFlagDebugGraphicsPreferD3D11 = "True",
					FIntActivatedCountTimerMSKeyboard = "0",
					FFlagMouseGetPartOptimization = "True",
					FIntSimSolverResponsiveness = "2147483647",
					FFlagSortKeyOptimization = "True",
					FFlagFasterPreciseTime4 = "True",
					DFFlagMouseMoveOncePerFrame = "False",
					FIntActivatedCountTimerMSMouse = "0",
					FIntSmoothMouseSpringFrequencyTenths = "100",
					FFlagEnablePerformanceControlService = "True",
					FIntCLI20390 = "0",
					FIntCLI20390_2 = "0",
					DFIntPerformanceControlTextureQualityBestUtility = "-1",
				},
				["No Textures"] = {
					DFIntAnimationLodFacsVisibilityDenominator = "0",
					FIntBootstrapperWebView2InstallationTelemetryHundredthPercent = "0",
					DFFlagSimOptimizeSetSize = "True",
					FFlagRenderEnableGlobalInstancingD3D11 = "False",
					FFlagFixChunkLightingUpdate2 = "True",
					FFlagControlBetaBadgeWithGuac = "False",
					FFlagSelfieViewEnabled = "True",
					DFFlagUseVisBugChecks = "True",
					FIntFullscreenTitleBarTriggerDelayMillis = "3600000",
					FFlagFixReducedMotionStuckIGM2 = "True",
					DFIntWindowsWebViewTelemetryThrottleHundredthsPercent = "0",
					FFlagEnablePreferredTextSizeStyleFixesInExperienceMenu = "True",
					FFlagDebugCodegenOptSize = "True",
					FIntRenderGrassDetailStrands = "0",
					FFlagMockOpenSelfViewForCameraUser = "False",
					FFlagGraphicsTextureCopy = "True",
					DFIntTextureQualityOverride = "0",
					FIntFriendRequestNotificationThrottle = "0",
					FFlagUserSoundsUseRelativeVelocity2 = "True",
					FIntUITextureMaxUpdateDepth = "-1",
					FFlagUseNotificationsLocalization = "False",
					FFlagLuauCodegen = "True",
					FFlagEnableChildrenLockFromLua = "False",
					DFIntRakNetMtuValue1InBytes = "1396",
					FFlagCSGDecalOptimizeVB = "True",
					FFlagSelfViewFixes = "False",
					DFIntDebugRestrictGCDistance = "1",
					FIntUnifiedLightingBlendZone = "1",
					DFIntMicroProfilerDpiScaleOverride = "100",
					FFlagSelfViewMoreNilChecks = "False",
					FFlagDebugSelfViewPerfBenchmark = "False",
					FFlagEnableChildrenLockFromLua2 = "False",
					FFlagDebugForceFSMCPULightCulling = "True",
					DFFlagTeleportClientAssetPreloadingEnabledIXP2 = "True",
					FFlagSyncWebViewCookieToEngine2 = "False",
					DFFlagTeleportClientAssetPreloadingEnabledIXP = "True",
					FFlagLuaAppsEnableParentalControlsTab = "False",
					FFlagRenderCBRefactor2 = "True",
					FStringTerrainMaterialTablePre2022 = "",
					FFlagDebugDisableTelemetryV2Counter = "True",
					FFlagChatTranslationEnableSystemMessage = "False",
					FFlagGraphicsGLEnableSuperHQShadersExclusion = "False",
					FFlagEnableInGameMenuChromeABTest4 = "True",
					FFlagPreloadMinimalFonts = "True",
					FFlagEnablePreferredTextSizeScalePerLayerCollector = "True",
					FFlagDisableChromeV3StaticSelfView = "False",
					FFlagAXSearchLandingPageIXPEnabled4 = "False",
					FFlagUserEnableCameraToggleNotification = "False",
					DFFlagAssetPreloadingUrlVersionEnabled2 = "True",
					FFlagDebugForceGenerateHSR = "True",
					DFFlagEnableTexturePreloading = "True",
					FFlagContentProviderPreloadHangTelemetry = "False",
					DFFlagTeleportClientAssetPreloadingDoingExperiment = "True",
					FFlagFixIGMTabTransitions = "True",
					DFFlagEnableExperienceNotificationOptInPrompt = "False",
					DFIntConnectionMTUSize = "1396",
					DFIntTeleportClientAssetPreloadingHundredthsPercentage2 = "100000",
					FFlagQuaternionPoseCorrection = "True",
					FStringVoiceBetaBadgeLearnMoreLink = "null",
					FFlagRemoveRedundantFontPreloading = "True",
					FFlagEnablePreferredTextSizeConnection = "True",
					FFlagFixEmotesMenuVR = "True",
					FFlagEnablePreferredTextSizeStyleFixesInAppShell4 = "True",
					FFlagDebugDisableTelemetryPoint = "True",
					FFlagDebugSkyGray = "True",
					FIntDebugFRMOptionalMSAALevelOverride = "0",
					FFlagDebugGraphicsPreferD3D11 = "False",
					FFlagFixOutdatedTimeScaleParticles = "False",
					DFIntCSGLevelOfDetailSwitchingDistanceL34 = "0",
					FFlagDisablePostFx = "True",
					DFFlagDebugRenderForceTechnologyVoxel = "True",
					FIntRobloxGuiBlurIntensity = "0",
					DFIntRakNetMtuValue3InBytes = "1100",
					DFFlagVoiceChatTurnOnMuteUnmuteNotificationHack = "False",
					FIntVRTouchControllerTransparency = "0",
					FFlagDebugSSAOForce = "False",
					DFFlagAdsPreloadInteractivityAssets = "True",
					FFlagRenderShadowSkipHugeCulling = "True",
					FFlagEnableCommandAutocomplete = "False",
					DFIntPerformanceControlTextureQualityBestUtility = "-1",
					FFlagLuaAppEnableToastNotificationsCoreScripts4 = "False",
					DFStringAltTelegrafAddress = "127.0.0.1",
					FIntRenderShadowmapBias = "-1",
					FFlagRemovedRbxRenderingPreProcessor = "False",
					DFIntCullFactorPixelThresholdShadowMapHighQuality = "2147483647",
					DFStringRobloxAnalyticsURL = "http://127.0.0.1:443/",
					FFlagTaskSchedulerLimitTargetFpsTo2402 = "False",
					DFStringWebviewUrlAllowlist = "",
					FFlagDebugRenderingSetDeterministic = "True",
					FFlagRenderLightGridEfficientTextureAtlasUpdate = "True",
					FFlagSelfViewRemoveVPFWhenClosed = "False",
					FFlagHandleAltEnterFullscreenManually = "False",
					DFFlagDebugPauseVoxelizer = "True",
					FIntFRMMinGrassDistance = "0",
					DFIntAnimationLodFacsDistanceMin = "0",
					FFlagVRMouseMoveOptimization = "True",
					FFlagPreOptimizeNoCollisionPrimitive = "True",
					FFlagEnableAudioPannerFiltering = "True",
					DFIntContentProviderPreloadHangTelemetryHundredthsPercentage = "0",
					DFFlagEnableSoundPreloading = "True",
					FFlagClientToastNotificationsEnabled = "False",
					FFlagEnablePreferredTextSizeStyleFixesInAppShell3 = "True",
					FFlagLuaAppGenreUnderConstruction = "False",
					FIntEnableVisBugChecksHundredthPercent27 = "100",
					FFlagRenderFixFog = "True",
					DFFlagEnableMeshPreloading2 = "True",
					FLogNetwork = "7",
					FFlagNotificationButtonTypeVariantMappingEmphasis = "False",
					FFlagLoginPageOptimizedPngs = "True",
					FFlagSelfViewCameraDefaultButtonInViewPort = "False",
					DFIntHACDPointSampleDistApartTenths = "2147483647",
					FFlagShaderLightingRefactor = "True",
					FFlagEnableBubbleChatFromChatService = "False",
					FIntTerrainArraySliceSize = "0",
					FIntPreferredTextSizeSettingBetaFeatureRolloutPercent = "100",
					FFlagRenderDebugCheckThreading2 = "True",
					FFlagDebugEnableVRFTUXExperienceInStudio = "True",
					DFFlagTeleportClientAssetPreloadingDoingExperiment2 = "True",
					FFlagUserFixLoadAnimationError = "True",
					FFlagNewLightAttenuation = "True",
					FFlagDebugDisableTelemetryV2Stat = "True",
					FStringTerrainMaterialTable2022 = "",
					FIntFRMMaxGrassDistance = "0",
					FFlagEnableRemoveIsFromToastNotification = "False",
					DFIntDefaultTimeoutTimeMs = "10000",
					FFlagEnablePreferredTextSizeGuiService = "True",
					FFlagRenderNoLowFrmBloom = "False",
					FFlagBetaBadgeLearnMoreLinkFormview = "False",
					FStringGraphicsDisableUnalignedDxtGPUNameBlacklist = "null",
					FIntDebugForceMSAASamples = "0",
					FFlagDebugGraphicsPreferD3D11FL10 = "True",
					FFlagVRLaserPointerOptimization = "True",
					FFlagEnablePreferredTextSizeStyleFixesAddFriends = "True",
					FFlagNotificationPluginSignalRReadEvents = "False",
					FIntTextureCompositorLowResFactor = "4",
					FFlagSelfViewAvoidErrorOnWrongFaceControlsParenting = "False",
					FFlagFixIGMBottomBarVisibility = "True",
					DFStringTelemetryV2Url = "http://127.0.0.1:443",
					FIntRomarkStartWithGraphicQualityLevel = "1",
					FFlagEnableIOSWebViewCookieSyncFix = "False",
					DFFlagOptimizeIsA = "True",
					FFlagEnableVisBugChecks27 = "True",
					DFIntVideoMaxNumberOfVideosPlaying = "0",
					FFlagRenderSkipReadingShaderData = "False",
					FIntSSAOMipLevels = "1",
					FFlagAXAdaptiveScrollingAvatarEditor2 = "True",
					FFlagDebugDeterministicParticles = "False",
					FFlagSelfViewHumanoidNilCheck = "False",
					FFlagEnablePreferredTextSizeStyleFixesInPurchasePrompt = "True",
					FFlagPreloadAllFonts = "True",
					FFlagVideoTextureSupportHardwareRender2 = "True",
					FFlagSelfViewUpdatedCamFraming = "False",
					FFlagAXPortraitSplitAdaptiveScrollingFix2 = "True",
					FFlagFixExitDialogBlockVRView = "True",
					DFIntTeleportClientAssetPreloadingHundredthsPercentage = "100000",
					DFFlagAudioToggleVolumetricPanning = "True",
					FFlagUserHideCharacterParticlesInFirstPerson = "True",
					FFlagNotificationsNoLongerRequireControllerState = "False",
					FFlagPreferredTextSizeSettingBetaFeature = "True",
					DFFlagEngineAPISendNotificationClientAnalytics = "False",
					FFlagEnableCullableScene2OptimizeStep = "True",
					DFFlagAudioEnableVolumetricPanningForPolys = "True",
					FStringGetPlayerImageDefaultTimeout = "1",
					FFlagDontRerenderForBadTexture = "True",
					FFlagDebugDisableTelemetryEventIngest = "True",
					FFlagAssetPreloadingIXP = "True",
					DFFlagAudioUseVolumetricPanning = "True",
					FFlagToastNotificationsResendDisplayOnInit = "False",
					DFIntRakNetMtuValue2InBytes = "1150",
					FFlagEnablePreferredTextSizeStyleFixesGameTile = "True",
					FFlagDeveloperToastNotificationsEnabled = "False",
					FFlagAXAdaptiveScrollingImprovementIXPEnabled = "True",
					FFlagFixCountOfUnreadNotificationError = "False",
					FFlagLuaAppEnableParentalControlExperiment = "False",
					FIntRuntimeMaxNumOfThreads = "2400",
					FFlagAdaptiveScrollingFrameOnServer = "True",
					FIntRenderLocalLightUpdatesMax = "1",
					FFlagFastGPULightCulling3 = "True",
					DFIntCSGLevelOfDetailSwitchingDistance = "0",
					FFlagEnablePreferredTextSizeScale = "True",
					DFIntCullFactorPixelThresholdShadowMapLowQuality = "2147483647",
					FFlagVRBackpackImproved = "True",
					FIntRefreshRateLowerBound = "120",
					FFlagSimEnableDCD16 = "True",
					DFFlagUnifyLegacyJointGeometry = "True",
					FFlagImproveShiftLockTransition = "True",
					FIntCAP1209DataSharingRolloutPercentage = "0",
					FIntRenderLocalLightUpdatesMin = "1",
					FFlagFixParticleEmissionBias2 = "False",
					FFlagEnableExperienceNotificationPrompts2 = "False",
					FFlagRenderTestEnableDistanceCulling = "True",
					FFlagDebugDisableTelemetryEphemeralCounter = "True",
					FFlagDebugDisableTelemetryV2Event = "True",
					FIntDebugTextureManagerSkipMips = "8",
					FFlagSelfViewTweaksPass = "False",
					FIntStudioResendDisconnectNotificationInterval = "0",
					DFFlagTeleportClientAssetPreloadingEnabled9 = "True",
					FFlagToastNotificationsUpdateEventParams = "False",
					DFIntMaxFrameBufferSize = "4",
					FIntBloomFrmCutoff = "-1",
					FFlagNewOptimizeNoCollisionPrimitiveInMidphase637 = "True",
					FIntVertexSmoothingGroupTolerance = "1",
					FFlagUseNotificationServiceIsConnected = "False",
					FFlagSignalRNotificationManagerMaybeStart = "False",
					DFFlagDebugOverrideDPIScale = "False",
					FFlagEnablePreferredTextSizeStyleFixesInAvatarExp = "True",
					FIntStudioExternalNotificationImplMessageWriteTimeOut = "0",
					FFlagDebugEnableDirectAudioOcclusion2 = "True",
					FFlagEnablePreferredTextSizeStyleFixesInReportMenu = "True",
					FIntEnableCullableScene2HundredthPercent3 = "100",
					DFFlagOptimizeInstanceQueries = "True",
					FFlagFixSettingsHubVRBackgroundError = "True",
					FFlagRenderEnableGlobalInstancingD3D10 = "True",
					FIntTaskSchedulerThreadMin = "3",
					FIntStudioWebView2TelemetryHundredthsPercent = "0",
					FFlagUserShowGuiHideToggles = "True",
					FFlagAXFixAdaptiveScrollingSnapAndroid = "True",
					FFlagEngineAPICloudProcessingUseNotificationClient = "False",
					FFlagEnableChromeFTUX = "True",
					FIntCAP1544DataSharingUserRolloutPercentage = "0",
					FFlagFixSensitivityTextPrecision = "False",
					FFlagMouseGetPartOptimization = "True",
					FFlagSelfViewGetRidOfFalselyRenderedFaceDecal = "False",
					FFlagLuaMenuPerfImprovements = "True",
					FFlagToastNotificationsReceivedAndDismissedSignals = "False",
					FFlagMigrateTextureManagerIsLocalAsset = "True",
					DFFlagTeleportPreloadingMetrics5 = "True",
					DFIntCSGLevelOfDetailSwitchingDistanceL23 = "0",
					DFFlagOptimizeClusterCacheAlloc = "True",
					DFIntMacWebViewTelemetryThrottleHundredthsPercent = "0",
					FIntOcclusionCullingBetaFeatureRolloutPercent = "100",
					FFlagEnableAudioEmitterDistanceAttenuation = "True",
					FFlagTopBarUseNewBadge = "False",
					FIntFixForBulkPresenceNotifications = "0",
					FFlagAdServiceEnabled = "False",
					DFFlagDebugSkipMeshVoxelizer = "True",
					FFlagStudioDataCollectionAddBasicNotification = "False",
					FIntCameraMaxZoomDistance = "999999",
					FFlagAXAdaptiveScrollingItemResetFix2 = "True",
					FFlagFixSelfViewPopin = "False",
					FIntTerrainOTAMaxTextureSize = "4",
					FFlagEnablePreferredTextSizeStyleFixesInPlayerList = "True",
					DFIntVoiceChatMaxRecordedDataDeliveryIntervalMs = "2147483647",
					FFlagPreloadTextureItemsOption4 = "True",
					DFFlagOpenCloudV1CreateUserNotificationAsync = "False",
					DFFlagSimRefactorCollisionGeometry2 = "True",
					FFlagEnableBetterHapticsResultHandling = "True",
					DFFlagWindowsWebViewTelemetryEnabled = "False",
					DFFlagSimSkipVoxelCDECMerge = "True",
					FFlagEnableVRFTUXExperienceV2 = "True",
					DFFlagSimDcdRecompUseClosedVoxel4 = "True",
					FIntCAP1209DataSharingTOSVersion = "0",
					FIntSelfViewTooltipLifetime = "0",
					FFlagVoiceBetaBadge = "False",
					DFFlagSimSolverOptimizeGeometricStiffness4 = "True",
					DFIntDebugFRMQualityLevelOverride = "1",
					DFStringAnalyticsNS1BeaconConfig = "https://127.0.0.1:443/|g2hjxw|https://127.0.0.1:443/|g2g5dg|https://127.0.0.1:443/|148d53m",
					FFlagSettingsHubIndependentBackgroundVisibility = "True",
					FFlagWindowsReportAbuseNotification = "False",
					FIntDirectionalAttenuationMaxPoints = "1",
					FFlagGraphicsGLEnableHQShadersExclusion = "False",
					FFlagCoreGuiSelfViewVisibilityFixed = "False",
					DFIntCanHideGuiGroupId = "32380007",
					DFFlagAudioEnableVolumetricPanningForMeshes = "True",
					DFIntDebugLimitMinTextureResolutionWhenSkipMips = "0",
					FFlagCAP1209EnableDataSharingUI4 = "False",
					FFlagToastNotificationsProtocolEnabled2 = "False",
					FIntSmoothTerrainPhysicsCacheSize = "2147483647",
					FFlagPreferredTextSizeStyleFixEventDescriptionExperienceTile = "True",
					DFFlagTextureQualityOverrideEnabled = "True",
					FFlagUpdateHTTPCookieStorageFromWKWebView = "False",
					FIntTargetRefreshRate = "144",
					FFlagDebugCheckRenderThreading = "True",
					FIntRenderLocalLightFadeInMs = "0",
					FFlagVRFixCursorJitterLua = "True",
					FFlagInExperienceUpsellSelfViewFix = "False",
					DFStringTelegrafAddress = "127.0.0.1",
					FFlagDisableFeedbackSoothsayerCheck = "False",
					DFFlagOptimizeNoCollisionPrimitiveInMidphaseCrash = "True",
					DFIntHttpParallelLimit_RequestExperienceNotificationService = "0",
					DFFlagEnablePerfRenderStatsCollection2 = "false",
					FIntAXAdaptiveScrollingJustSelectedMillis = "2000",
					DFIntGraphicsOptimizationModeMinFrameTimeTargetMs = "25",
					FIntRenderShadowIntensity = "0",
					FFlagGraphicsEnableD3D10Compute = "True",
					FFlagAvatarChatIncludeSelfViewOnTelemetry = "False",
					FFlagFixParticleAttachmentCulling = "False",
					DFFlagPhysicsMechanismCacheOptimizeAlloc = "True",
					DFIntGraphicsOptimizationModeMaxFrameTimeTargetMs = "20",
					FFlagOcclusionCullingBetaFeature = "True",
					FFlagFRMRefactor = "False",
					FFlagRenderLegacyShadowsQualityRefactor = "True",
					FFlagDebugStudioForceSystemDeprecationNotification = "False",
					DFFlagDebugPerfMode = "True",
					FIntRenderMaxShadowAtlasUsageBeforeDownscale = "1",
					FFlagShoeSkipRenderMesh = "False",
					FFlagCAP1544UseNewDataSharingRollout = "False",
					DFFlagJointIrregularityOptimization = "True",
					DFIntTaskSchedulerTargetFps = "9999",
					FIntGrassMovementReducedMotionFactor = "0",
					FFlagVisBugChecksThreadYield = "True",
					DFIntNumAssetsMaxToPreload = "2147483647",
					DFFlagDisableDPIScale = "False",
					DFFlagNotificationServiceIsConnectedProperty = "False",
					FFlagGuiHidingApiSupport2 = "True",
					DFIntAnimationLodFacsDistanceMax = "0",
					FFlagLuaAppGamesPagePreloadingDisabled = "False",
					DFIntTimestepArbiterThresholdCFLThou = "300",
					FFlagViewCollisionFadeToBlackInVR = "False",
					FFlagEnablePreferredTextSizeSettingInMenus2 = "True",
					FFlagDebugDisableTelemetryEphemeralStat = "True",
					FFlagSelfViewLookUpHumanoidByType = "False",
					FFlagAXAdaptiveScrollingSnapItemEditor = "True",
					DFIntDebugAdditionalNumberOfMipsToSkipForNonAlbedoTextures = "0",
					FStringInExperienceNotificationsLayer = "",
					FFlagSortKeyOptimization = "True",
					DFIntCSGLevelOfDetailSwitchingDistanceL12 = "0",
					FFlagRenderOptimizeDecalTransparencyInvalidation = "True",
					DFFlagOptimizePartsInPart = "True",
					FFlagSquadToastNotificationsEnabled = "False",
					FFlagEnablePreferredTextSizeStyleFixesInCaptureMenu = "True",
				},
				["Glitch Curve"] = {
					FFlagVideoTextureSupportHardwareRender2 = "True",
					FLogNetwork = "7",
					FFlagHandleAltEnterFullscreenManually = "False",
					FIntFontSizePadding = "2",
					FFlagDisablePostFx = "True",
					FIntRenderShadowIntensity = "0",
					DFFlagTextureQualityOverrideEnabled = "True",
					FIntFullscreenTitleBarTriggerDelayMillis = "3600000",
					DFFlagDisableDPIScale = "True",
					FIntDebugForceMSAASamples = "2",
					DFIntTaskSchedulerTargetFps = "9999",
					DFFlagDebugRenderForceTechnologyVoxel = "True",
					FFlagDebugForceFutureIsBrightPhase2 = "True",
					DFIntTextureQualityOverride = "0",
					FIntTerrainArraySliceSize = "0",
					DFIntCanHideGuiGroupId = "32380007",
					FFlagDebugForceFutureIsBrightPhase3 = "True",
					FFlagOptimizeNetwork = "True",
					FFlagDebugGraphicsPreferD3D11 = "True",
					FIntRuntimeMaxNumOfSchedulers = "20000",
					FIntRakNetResendBufferArrayLength = "128",
					DFIntClientPacketUnhealthyContEscMsPerSecond = "1",
					DFIntPerformanceControlFrameTimeMax = "1",
					DFIntRuntimeTickrate = "2139999999",
					FFlagTaskSchedulerLimitTargetFpsTo2402 = "False",
					DFIntAccelerationTimeThreshold = "0",
					DFIntRakNetSelectUnblockSocketWriteDurationMs = "10",
					DFIntTargetTimeDelayFacctorTenths = "1",
					FFlagEnableInGameMenuModernization = "True",
					FIntInterpolationAwareTargetTimeLerpHundredth = "100",
					DFFlagGraphicsOptimizationModeMVPExposureEnrollment4 = "False",
					DFIntMinimalNetworkPrediction = "1",
					DFIntMaxProcessPacketsJobScaling = "2139999999",
					FFlagEnableMenuControlsABTest = "False",
					DFFlagSimOptimizeSetSize = "True",
					FIntRakNetDatagramMessageIdArrayLength = "8192",
					DFIntPlayerNetworkUpdateRate = "1",
					DFIntRuntimeConcurrency = "2139999999",
					DFIntRaknetBandwidthPingSendEveryXSeconds = "-1",
					FIntRuntimeMaxNumOfThreads = "20000",
					DFIntRaknetBandwidthInfluxHundredthsPercentageV2 = "10000",
					DFIntInterpolationNumMechanismsPerTask = "100",
					DFIntCodecMaxOutgoingFrames = "2139999999",
					DFIntParallelAdaptiveInterpolationBatchCount = "1",
					FFlagDebugDisplayFPS = "True",
					DFIntMaxFrameBufferSize = "1",
					DFIntHACDPointSampleDistApartTenths = "3000000",
					DFIntGameNetPVHeaderTranslationZeroCutoffExponent = "-1",
					DFIntServerPhysicsUpdateRate = "-1",
					FFlagOptimizeServerTickRate = "True",
					FIntMaquettesFrameRateBufferPercentage = "1",
					DFIntRakNetApplicationFeedbackInitialSpeedBPS = "2139999999",
					DFIntClientPacketHealthyAllocationPercent = "100",
					DFIntMegaReplicatorNetworkQualityProcessorUnit = "-1",
					FIntInterpolationMaxDelayMSec = "0",
					DFIntRakNetClockDriftAdjustmentPerPingMillisecond = "2139999999",
					DFIntNetworkLatencyTolerance = "-1",
					DFIntRakNetPingFrequencyMillisecond = "10",
					FFlagDebugDisableTelemetryV2Stat = "True",
					DFIntLargePacketQueueSizeCutoffMB = "1",
					FFlagEnableInGameMenuControls = "True",
					DFIntRakNetResendRttMultiple = "1",
					DFIntMinimumNumberMechanismsForMT = "1",
					FFlagContentProviderPreloadHangTelemetry = "False",
					FFlagOptimizeNetworkTransport = "True",
					DFIntMaxProcessPacketsStepsAccumulated = "0",
					FFlagDisableNewIGMinDUA = "True",
					DFIntOptimizePingThreshold = "-1",
					FFlagEnableV3MenuABTest3 = "False",
					DFIntRakNetLoopMs = "0",
					DFIntMaxProcessPacketsStepsPerCyclic = "2139999999",
					FIntTaskSchedulerMaxNumOfJobs = "2139999999",
					DFStringWebviewUrlAllowlist = "",
					DFIntClientPacketMaxDelayMs = "1",
					FFlagFixGraphicsQuality = "True",
					FFlagEnableChromePinnedChat = "True",
					DFIntClientPacketMaxFrameMicroseconds = "1",
					DFIntInterpolationDtLimitForLod = "1",
					DFIntGameNetPVHeaderRotationalVelocityZeroCutoffExponent = "-1",
					FFlagEnableInGameMenuChrome = "True",
					DFIntNetworkPrediction = "-1",
					DFIntActionStationDebounceTime = "0",
					FIntRuntimeMaxNumOfConditions = "20000",
					DFIntClientPacketHealthyMsPerSecondLimit = "1",
					DFIntCodecMaxIncomingPackets = "2139999999",
					FFlagNewLightAttenuation = "True",
					DFIntGameNetPVHeaderLinearVelocityZeroCutoffExponent = "-1",
					DFIntMaxDataOutJobScaling = "2139999999",
					FIntDebugTextureManagerSkipMips = "0",
					FFlagDebugDisableTelemetryEphemeralCounter = "True",
					FIntNumFramesToCaptureCallStack = "1",
					DFIntClientPacketMinMicroseconds = "1",
					DFIntServerTickRate = "-1",
					DFIntRakNetApplicationFeedbackMaxSpeedBPS = "2139999999",
					DFIntMaxReceiveToDeserializeLatencyMilliseconds = "1",
					DFIntGameNetPVHeaderRotationOrientIdToleranceExponent = "-1",
					DFIntRakNetApplicationFeedbackScaleUpFactorHundredthPercent = "100",
					DFFlagDebugPauseVoxelizer = "True",
					FFlagEnableInGameMenuChromeABTest3 = "False",
					DFIntRakNetMinAckGrowthPercent = "100",
					FFlagEnableCullableScene2OptimizeStep = "True",
					FFlagAdServiceEnabled = "False",
					DFIntMaxFramesToSend = "1",
					DFIntMaxAverageFrameDelayExceedFactor = "0",
					FIntRuntimeMaxNumOfLatches = "20000",
					FFlagOptimizeNetworkRouting = "True",
					DFIntNumFramesAllowedToBeAboveError = "0",
					DFIntClientPacketExcessMicroseconds = "1",
					DFFlagEnableSoundPreloading = "True",
					FIntRuntimeMaxNumOfMutexes = "20000",
					FFlagMSRefactor5 = "False",
					DFIntPlayerNetworkUpdateQueueSize = "1",
					FFlagFixParticleEmissionBias2 = "False",
					FFlagDebugDisableTelemetryEventIngest = "True",
					DFFlagOptimizeIsA = "True",
					FFlagDisableFeedbackSoothsayerCheck = "False",
					FFlagDebugForceGenerateHSR = "True",
					DFIntMacWebViewTelemetryThrottleHundredthsPercent = "0",
					FFlagDebugDisableTelemetryV2Counter = "True",
					DFFlagAudioToggleVolumetricPanning = "True",
					FFlagDebugSSAOForce = "False",
					DFIntCullFactorPixelThresholdShadowMapHighQuality = "2147483647",
					DFFlagWindowsWebViewTelemetryEnabled = "False",
					DFFlagEnableMeshPreloading2 = "True",
					DFIntWindowsWebViewTelemetryThrottleHundredthsPercent = "0",
					DFFlagAudioUseVolumetricPanning = "True",
					DFIntCSGLevelOfDetailSwitchingDistance = "0",
					DFIntCSGLevelOfDetailSwitchingDistanceL34 = "0",
					DFFlagSimSolverOptimizeGeometricStiffness4 = "True",
					DFFlagTeleportClientAssetPreloadingEnabledIXP2 = "True",
					DFFlagAudioEnableVolumetricPanningForPolys = "True",
					DFFlagVisBugFixPartUpdatedLock = "True",
					DFFlagEnablePerfDataMainThread = "True",
					DFFlagUnifyLegacyJointGeometry = "True",
					FFlagEnableRuntimeThreadVisQueries = "True",
					DFFlagAssetPreloadingUrlVersionEnabled2 = "True",
					FFlagEnableAudioEmitterDistanceAttenuation = "True",
					FFlagFixOutdatedTimeScaleParticles = "False",
					DFFlagAudioEnableVolumetricPanningForMeshes = "True",
					DFIntEnableVisBugChecksHundredthPercent = "1000",
					FFlagDebugCodegenOptSize = "True",
					FFlagDebugForceFSMCPULightCulling = "True",
					FFlagControlBetaBadgeWithGuac = "False",
					FFlagEnableInGameMenuChromeABTest4 = "True",
					FFlagAlwaysShowVRToggleV3 = "False",
					DFFlagTeleportPreloadingMetrics5 = "True",
					FFlagDebugDeterministicParticles = "False",
					DFIntTrackCountryRegionAPIHundredthsPercent = "10000",
					FFlagDebugDisableTelemetryEphemeralStat = "True",
					DFFlagDebugPerfMode = "True",
					FFlagEnableVisBugChecks = "True",
					FFlagEnableRuntimeThreadVisQueries4 = "True",
					FFlagDebugDisableTelemetryV2Event = "True",
					FFlagDebugDisableTelemetryPoint = "True",
					DFFlagPhysicsMechanismCacheOptimizeAlloc = "True",
					DFFlagVisBugFixUnloadReadyMesh = "True",
					DFFlagOptimizeClusterCacheAlloc = "True",
					FFlagEnableVisBugChecks27 = "True",
					DFIntContentProviderPreloadHangTelemetryHundredthsPercentage = "0",
					DFIntAssetPreloading = "2147483647",
					DFFlagTeleportClientAssetPreloadingDoingExperiment = "True",
					DFIntAnimationLodFacsDistanceMax = "0",
					FFlagFixSensitivityTextPrecision = "False",
					DFFlagEnableTexturePreloading = "True",
					DFFlagDebugUseOcclusionQueries = "True",
					DFFlagTeleportClientAssetPreloadingEnabledIXP = "True",
					DFIntInitialAccelerationLatencyMultTenths = "1",
					FFlagDebugEnableDirectAudioOcclusion2 = "True",
					DFIntCSGLevelOfDetailSwitchingDistanceL23 = "0",
					FFlagDebugSkyGray = "True",
					FFlagChatTranslationEnableSystemMessage = "False",
					FFlagEnableIOSWebViewCookieSyncFix = "False",
					DFIntCSGLevelOfDetailSwitchingDistanceL12 = "0",
					FFlagDebugCheckRenderThreading = "True",
					FFlagFixParticleAttachmentCulling = "False",
					DFIntAnimationLodFacsDistanceMin = "0",
					FFlagFRMRefactor = "False",
					FFlagLoginPageOptimizedPngs = "True",
					FFlagLuauCodegen = "True",
					FFlagMouseGetPartOptimization = "True",
					FFlagNewCameraControls_SpeedAdjustEnum = "False",
					FFlagNewOptimizeNoCollisionPrimitiveInMidphase651 = "True",
					FFlagOcclusionCullingBetaFeature = "True",
					FFlagPreloadAllFonts = "True",
					FFlagPreloadMinimalFonts = "True",
					FFlagPreloadTextureItemsOption4 = "True",
					FFlagRenderCBRefactor2 = "True",
					FFlagRenderDebugCheckThreading2 = "True",
					FFlagRenderLegacyShadowsQualityRefactor = "True",
					FFlagRenderLightGridEfficientTextureAtlasUpdate = "True",
					FFlagRenderNoLowFrmBloom = "False",
					FFlagRenderOptimizeDecalTransparencyInvalidation = "True",
					FFlagRenderShadowSkipHugeCulling = "True",
					FFlagRenderSkipReadingShaderData = "False",
					FFlagShaderLightingRefactor = "True",
					FFlagShoeSkipRenderMesh = "False",
					FFlagSyncWebViewCookieToEngine2 = "False",
					FFlagTopBarUseNewBadge = "False",
					FFlagUpdateHTTPCookieStorageFromWKWebView = "False",
					FFlagUserCameraControlLastInputTypeUpdate = "True",
					FFlagUserCameraInputDt = "True",
					FFlagUserCameraInputRefactor3 = "True",
					FFlagUserFixLoadAnimationError = "True",
					FFlagUserHideCharacterParticlesInFirstPerson = "True",
					FFlagVideoRenderUseHardwareBuffer = "True",
					FFlagVideoServiceAddHardwareCodecMetrics = "True",
					FFlagVignetteEffectEnabled4 = "False",
					FFlagVisBugChecksThreadYield = "True",
					FFlagVoiceBetaBadge = "False",
					FFlagVRLaserPointerOptimization = "True",
					FFlagVRMouseMoveOptimization = "True",
					FIntBloomFrmCutoff = "0",
					FIntBootstrapperWebView2InstallationTelemetryHundredthPercent = "0",
					FIntCameraMaxZoomDistance = "99999",
					FIntDebugFRMOptionalMSAALevelOverride = "0",
					FIntDirectionalAttenuationMaxPoints = "0",
					FIntEnableCullableScene2HundredthPercent3 = "100",
					FIntEnableVisBugChecksHundredthPercent27 = "100",
					FIntFRMMaxGrassDistance = "0",
					FIntFRMMinGrassDistance = "0",
					FIntGameGridFlexFeedItemTileNumPerFeed = "0",
					FIntGrassMovementReducedMotionFactor = "0",
					FIntNewInGameMenuPercentRollout3 = "0",
					FIntRenderGrassDetailStrands = "0",
					FIntRenderLocalLightUpdatesMax = "1",
					FIntRenderLocalLightUpdatesMin = "1",
					FIntRenderMaxShadowAtlasUsageBeforeDownscale = "0",
					FIntRenderMeshOptimizeVertexBuffer = "0",
					FIntRenderShadowmapBias = "0",
					FIntSmoothMouseSpringFrequencyTenths = "100",
					FIntSmoothTerrainPhysicsCacheSize = "0",
					FIntSSAOMipLevels = "0",
					FIntUnifiedLightingBlendZone = "0",
					FIntV1MenuLanguageSelectionFeaturePerMillageRollout = "0",
					FIntVertexSmoothingGroupTolerance = "0",
					FStringTerrainMaterialTable2022 = "",
					FStringTerrainMaterialTablePre2022 = "",
					SFFlagAirControllerTurningResponsiveness = "2147483647",
					SFFlagGroundControllerBalancingResponsiveness = "2147483647",
					SFFlagGroundControllerTurningResponsiveness = "2147483647",
					SFFlagSimAnimationConstraintResponsiveness = "2147483647",
					SFFlagSimSolverResponsiveness = "2147483647",
				},
				["Low Input Delay"] = {
					FIntActivatedCountTimerMSKeyboard = "0",
					FFlagMouseGetPartOptimization = "True",
					FIntSimSolverResponsiveness = "2147483647",
					FFlagSortKeyOptimization = "True",
					FFlagFasterPreciseTime4 = "True",
					DFFlagMouseMoveOncePerFrame = "False",
					FIntActivatedCountTimerMSMouse = "0",
					FIntSmoothMouseSpringFrequencyTenths = "100",
					FFlagEnablePerformanceControlService = "True",
					FIntCLI20390_2 = "-1",
				},
				["Low Mesh"] = {
					DFIntCSGLevelOfDetailSwitchingDistance = "0",
					DFIntCSGLevelOfDetailSwitchingDistanceL12 = "0",
					DFIntCSGLevelOfDetailSwitchingDistanceL34 = "0",
					DFIntCSGLevelOfDetailSwitchingDistanceL23 = "0",
				},
				["Shiny Ball"] = { DFIntDebugFRMQualityLevelOverride = "3" },
				["Gray World"] = { FIntDebugTextureManagerSkipMips = "10" },
			},
		}

		tbl3.myregion = function()
			local value = ReplicatedStorage.ServerInfo.Region.Value
			if type(value) == "string" and value ~= "" then
				return value
			end
			return nil
		end

		tbl3.ffsetter = function()
			return setfflag
		end

		tbl3.ffknown = function(arg)
			if type(getfflag) ~= "function" then
				return true
			end
			return getfflag(arg) ~= nil
		end

		tbl3.ffparse = function(arg)
			local str2 = tostring(arg or "")
			if str2:gsub("%s", "") == "" then
				return nil
			end
			local match = str2:match("^%s*(.-)%s*$")
			local str3 = match:lower()

			if str3:sub(1, 7) == "http://" or str3:sub(1, 8) == "https://" then
				str2 = tbl3.httpget(match)
				if type(str2) ~= "string" or str2 == "" then
					return nil, match
				end
			elseif str3:sub(-5) == ".json" and isfile and readfile then
				if not isfile(match) then
					return nil, match
				end
				local v5 = readfile(match)
				if type(v5) ~= "string" then
					return nil, match
				end
				str2 = v5
			end

			local data = HttpService:JSONDecode(str2)

			if type(data) == "table" then
				local tbl17 = {}
				local n2 = 0

				for k, v5 in pairs(data) do
					local kind = type(v5)

					if type(k) == "string" and (kind == "string" or kind == "number" or kind == "boolean") then
						tbl17[k] = kind == "boolean" and (v5 and "True" or "False") or tostring(v5)
						n2 += 1
					end
				end

				return n2 > 0 and tbl17 or nil
			end

			local tbl17 = {}
			local n2 = 0

			for match2 in str2:gmatch("[^\r\n,;]+") do
				local match3, v5 = match2:match("^%s*([%w_]+)%s*[=:]%s*(.-)%s*$")

				if match3 and v5 and v5 ~= "" then
					local str4 = v5:gsub("^\"(.*)\"$", "%1")
					local str5 = str4:lower()

					if str5 == "true" or str5 == "false" then
						str4 = str5 == "true" and "True" or "False"
					end

					tbl17[match3] = str4
					n2 += 1
				end
			end

			return n2 > 0 and tbl17 or nil
		end

		tbl3.ffflags = function()
			if toggles.ffcustom and toggles.ffcustom.Value then
				local v5, v6 = tbl3.ffparse(options.ffcustomdata.Value)
				return v5, true, v6
			end
			return tbl16.presets[options.ffpreset and options.ffpreset.Value or tbl16.presetdefault] or tbl16.presets[tbl16.presetdefault], false
		end

		tbl3.ffapply = function()
			local v5 = tbl3.ffsetter()
			if not v5 then
				tbl3.notif("FFlags", "Your executor can't change FFlags.", 6)
				return 0
			end
			local v6, v7, v8 = tbl3.ffflags()

			if not v6 then
				if v8 then
					tbl3.notif("FFlags", format("Couldn't load \"%s\". Check the file name or link.", v8), 6)
				else
					tbl3.notif("FFlags", "Those FFlags look wrong. Paste FFlag text, a .json file name, or a link.", 6)
				end

				return 0
			end

			local tbl17 = {}
			local n2 = 0
			local n3 = 0

			for k, v9 in pairs(v6) do
				if tbl3.ffknown(k) then
					v5(k, tostring(v9))
					tbl17[k] = tostring(v9)
					n2 += 1
				else
					n3 += 1
				end
			end

			if writefile then
				writefile(tbl16.file, HttpService:JSONEncode(tbl17))
			end

			if n2 == 0 then
				tbl3.notif("FFlags", format("Your Roblox build knows none of those %d flags, so nothing changed.", n3), 7)
				return 0
			end
			tbl3.notif("FFlags", n3 > 0 and format("%d flags saved. %d skipped - your Roblox build doesn't have them.", n2, n3) or format("%d flags saved.", n2), 5)
			return n2
		end

		tbl3.ffload = function()
			local v5 = tbl3.ffsetter()
			if not (v5 and isfile and readfile and isfile(tbl16.file)) then
				return
			end
			local data = HttpService:JSONDecode(readfile(tbl16.file))
			if type(data) ~= "table" then
				return
			end

			for k, v6 in pairs(data) do
				if tbl3.ffknown(k) then
					v5(k, tostring(v6))
				end
			end
		end

		tbl3.ffreq = function()
			return request
		end

		tbl3.ffserverip = function(arg)
			local v5 = tbl3.ffreq()
			if not v5 then
				return nil
			end

			local v6 = v5({
				Url = "https://gamejoin.roblox.com/v1/join-game-instance",
				Method = "POST",
				Headers = { ["Content-Type"] = "application/json", ["User-Agent"] = "Roblox/WinInet" },
				Body = HttpService:JSONEncode({ placeId = game.PlaceId, isTeleport = false, gameId = arg, gameJoinAttemptId = arg }),
			})

			if type(v6) ~= "table" or not v6.Body then
				return nil
			end
			local data = HttpService:JSONDecode(v6.Body)
			if type(data) ~= "table" then
				return nil
			end
			local joinScript = data.joinScript
			if type(joinScript) ~= "table" then
				return nil
			end
			local udmuxEndpoints = joinScript.UdmuxEndpoints
			if type(udmuxEndpoints) == "table" and type(udmuxEndpoints[1]) == "table" and udmuxEndpoints[1].Address then
				return udmuxEndpoints[1].Address
			end
			return joinScript.MachineAddress
		end

		tbl3.ffregionof = function(arg)
			if tbl16.ipcache[arg] then
				return tbl16.ipcache[arg]
			end
			local v5 = tbl3.ffreq()
			if not v5 then
				return nil
			end

			local v6 = v5({
				Url = "http://ip-api.com/json/" .. arg .. "?fields=status,continentCode,countryCode,lat,lon",
				Method = "GET",
			})

			if type(v6) ~= "table" or not v6.Body then
				return nil
			end
			local data = HttpService:JSONDecode(v6.Body)
			if type(data) ~= "table" or data.status ~= "success" then
				return nil
			end
			local continentCode = data.continentCode
			local countryCode = data.countryCode
			local n2 = tonumber(data.lat) or 0
			local n3 = tonumber(data.lon) or 0
			local str2

			if countryCode == "US" or countryCode == "CA" then
				if n3 < -115 then
					str2 = "US West"
				elseif n3 < -95 then
					str2 = "US Central"
				elseif n2 < 33 then
					str2 = "US South"
				else
					str2 = "US East"
				end
			elseif countryCode == "GB" or countryCode == "IE" then
				str2 = "UK"
			elseif continentCode == "EU" then
				str2 = n3 < 12 and "Europe West" or "Europe East"
			elseif continentCode == "AS" then
				if tbl16.sea[countryCode] then
					str2 = "Southeast Asia"
				elseif tbl16.sasia[countryCode] then
					str2 = "South Asia"
				else
					str2 = "Asia East"
				end
			elseif continentCode == "OC" then
				str2 = "Oceania"
			elseif continentCode == "SA" then
				str2 = "South America"
			else
				str2 = nil

				if continentCode == "NA" then
					str2 = "US East"
				end
			end

			if str2 then
				tbl16.ipcache[arg] = str2
			end

			return str2
		end

		tbl3.ffhop = function(arg)
			if tbl16.hopping then
				return
			end

			if not arg or arg == "Auto" then
				if fn4 then
					fn4()
				end

				return
			end

			if not tbl3.ffreq() then
				tbl3.notif("Region", "Your executor can't pick a region.", 5)
				return
			end
			tbl16.hopping = true

			tbl3.bindt(task.spawn(function()
				local str2 = ("https://games.roblox.com/v1/games/%d/servers/Public?sortOrder=Asc&limit=100"):format(game.PlaceId)
				local v5 = tbl3.httpget(str2)
				local data = v5 and HttpService:JSONDecode(v5)

				if type(data) ~= "table" or type(data.data) ~= "table" then
					tbl16.hopping = false
					tbl3.notif("Region", "Couldn't load the server list. Try again.", 4)
					return
				end

				tbl3.notif("Region", "Looking for a " .. arg .. " server...", 4)
				local n2 = 0

				for _, v6 in ipairs(data.data) do
					if n2 >= 25 then
						break
					end

					if type(v6) == "table" and v6.id and v6.id ~= game.JobId and v6.playing and v6.maxPlayers and v6.playing < v6.maxPlayers then
						n2 += 1
						local v7 = tbl3.ffserverip(v6.id)

						if v7 and tbl3.ffregionof(v7) == arg then
							tbl16.hopping = false
							TeleportService:TeleportToPlaceInstance(game.PlaceId, v6.id, localPlayer)
							return
						end

						task.wait(0.35)
					end
				end

				tbl16.hopping = false
				tbl3.notif("Region", format("Checked %d servers, no %s server found. Try again.", n2, arg), 5)
			end))
		end

		local tbl17 = {
			items = {},
			conn = nil,
			acc = 0,
			icons = {},
			cols = {},
			cds = {},
			cdwait = {},
			shared = nil,
			ready = Color3.fromRGB(120, 230, 120),
			cool = accent,
			miss = "rbxassetid://6034407076",
		}

		local n2 = flag and 0.68 or 1
		local function fn8(l)return  floor (l* n2 +0.5);end
		tbl3.esphex = function(l)return  format ("#%02x%02x%02x", floor (l.R*255+0.5), floor (l.G*255+0.5), floor (l.B*255+0.5));end
		tbl3.espdata = function(l)local K= ReplicatedStorage :FindFirstChild("Misc");local h=K and(K:FindFirstChild("DataAbilities"));return h and(h:FindFirstChild(l))or nil;end
		tbl3.espabil = function(h,l)return l:GetAttribute("Ability")or(h:GetAttribute("CurrentlyEquippedAbility"))or"Dash";end
		tbl3.espcolor = function(l)if not l then return nil;end;local K= tbl17 .cols[l];if K~=nil then return K or nil;end;local p=nil;K= tbl3 .espdata(l);if K then local E=K:GetAttribute("Color");p=if typeof(E)=="Color3"then E else p;end; tbl17 .cols[l]=p or false;return p;end

		tbl3.espfetch = function(arg, arg2)
			if tbl17.shared == nil then
				local shared = ReplicatedStorage:FindFirstChild("Shared")
				shared = shared and shared:FindFirstChild("Abilities")
				tbl17.shared = shared and require(shared) or false
			end

			local getAbilityCooldown = tbl17.shared and tbl17.shared.getAbilityCooldown
			local module = nil

			if getAbilityCooldown then
				module = tbl17.shared.getAbilityCooldown(arg, arg2)
			end

			if not module then
				local shared = ReplicatedStorage:FindFirstChild("Shared")
				shared = shared and shared:FindFirstChild("Abilities")
				shared = shared and shared:FindFirstChild(arg2)

				if shared then
					module = require(shared)
					module = module and module.cooldown
				end
			end

			tbl17.cds[arg2] = type(module) == "number" and module > 0 and module or false
		end

		tbl3.esptotal = function(l,K)if not K then return nil;end;local p= tbl17 .cds[K];if p~=nil then return p or nil;end;if not  tbl17 .cdwait[K]then  tbl17 .cdwait[K]=true;task.defer( tbl3 .espfetch,l,K);end;return nil;end
		tbl3.esplevel = function(h,l)if not l then return 0;end;local K=h:FindFirstChild("Upgrades");h=K and(K:FindFirstChild(l));return h and(tonumber(h.Value))or 0;end
		tbl3.espicon = function(l,K)if not l then return  tbl17 .miss;end;local p=l..tostring(K);local E= tbl17 .icons[p];if E then return E;end;E= tbl3 .espdata(l);if not E then  tbl17 .icons[p]= tbl17 .miss;return  tbl17 .miss;end;l=(if K and K>0 then(E:GetAttribute("Icon"..K))else nil)or(E:GetAttribute("Icon"))or  tbl17 .miss; tbl17 .icons[p]=l;return l;end
		tbl3.espdrop = function(h)if h and h.gui then h.gui:Destroy();end;end
		tbl3.espclear = function()for l,l in pairs( tbl17 .items)do  tbl3 .espdrop(l);end; tbl17 .items={};end
		tbl3.esppassive = { ["Guardian Angel"] = true, ["Tact"] = true }
		tbl3.espmake = function(plr, char)
			local adornee = char:FindFirstChild("Head") or char:FindFirstChild("HumanoidRootPart")
			if not adornee then return nil end
			local gui = Instance.new("BillboardGui")
			gui.Name = "\0ae"
			gui.Adornee = adornee
			gui.Size = UDim2.fromOffset(fn8(320), fn8(46))
			gui.StudsOffsetWorldSpace = Vector3.new(0, 3.2, 0)
			gui.AlwaysOnTop = true
			gui.ResetOnSpawn = false
			gui.Parent = fn6 and fn6() or CoreGui
			local frame = Instance.new("Frame")
			frame.Size = UDim2.fromScale(1, 1)
			frame.BackgroundTransparency = 1
			frame.Parent = gui
			local list = Instance.new("UIListLayout")
			list.FillDirection = Enum.FillDirection.Vertical
			list.HorizontalAlignment = Enum.HorizontalAlignment.Center
			list.VerticalAlignment = Enum.VerticalAlignment.Bottom
			list.SortOrder = Enum.SortOrder.LayoutOrder
			list.Padding = UDim.new(0, fn8(1))
			list.Parent = frame
			local icon = Instance.new("ImageLabel")
			icon.LayoutOrder = 1
			icon.Size = UDim2.fromOffset(fn8(24), fn8(24))
			icon.BackgroundTransparency = 1
			icon.ScaleType = Enum.ScaleType.Fit
			icon.Image = tbl17.miss
			icon.Parent = frame
			local label = Instance.new("TextLabel")
			label.LayoutOrder = 2
			label.Size = UDim2.new(1, 0, 0, fn8(18))
			label.BackgroundTransparency = 1
			label.Font = Enum.Font.SourceSans
			label.TextSize = fn8(18)
			label.TextColor3 = Color3.new(1, 1, 1)
			label.TextStrokeTransparency = 0.5
			label.TextStrokeColor3 = Color3.new(0, 0, 0)
			label.Text = ""
			label.Parent = frame
			local item = { gui = gui, icon = icon, abil = label, adornee = adornee, cdexp = 0, cdtotal = nil, wasactive = false, useclock = nil, esttotal = nil }
			tbl17.items[plr] = item
			return item
		end
		tbl3.espupd = function()
			if not toggles.abilityesp.Value then return end
			local now = Workspace:GetServerTimeNow()
			local showCd = toggles.espcooldown.Value
			local showName = toggles.espname.Value
			for _, plr in ipairs(Players:GetPlayers()) do
				if plr ~= localPlayer then
					local char = plr.Character
					local alive_ = char and alive and char.Parent == alive
					local item = tbl17.items[plr]
					if alive_ then
						if not item or not item.gui or not item.gui.Parent or not item.adornee or not item.adornee.Parent then
							tbl3.espdrop(item)
							item = tbl3.espmake(plr, char)
						end
						if item then
							item.gui.Enabled = true
							local abil = tbl3.espabil(plr, char)
							local lvl = tbl3.esplevel(plr, abil)
							item.icon.Image = tbl3.espicon(abil, lvl)
							local total = abil and tbl3.esptotal(plr, abil) or nil
							local passive = abil and (tbl3.esppassive[abil] or tbl17.cds[abil] == false) or false
							local remain = 0
							local locked = tbl3.abilblocked(char)
							local active = char:GetAttribute("AbilityActive") == true
							if showCd and not passive then
								local exp = char:GetAttribute("CooldownExpiration") or 0
								remain = max(0, exp - now)
								if exp > item.cdexp + 0.01 then
									item.cdexp = exp
									item.cdtotal = max(remain, 0.1)
								elseif exp < item.cdexp - 0.01 then
									item.cdexp = exp
								end
								if active and not item.wasactive then
									item.useclock = now
									item.esttotal = abil and tbl3.esptotal(plr, abil) or nil
								end
								item.wasactive = active
								if item.useclock and item.esttotal then
									local left = item.esttotal - (now - item.useclock)
									if left <= 0 then
										item.useclock = nil
									elseif left > remain then
										remain = left
									end
								end
							end
							local status
							if passive then
								status = "Passive"
							elseif locked then
								status = "Locked"
							elseif active then
								status = "Active"
							elseif showCd and remain > 0.05 then
								status = format("%.1fs", remain)
							else
								status = "Ready"
							end
							local name = abil and tostring(abil) or "?"
							if lvl > 0 then name = name .. " V" .. (lvl + 1) end
							local text = "[" .. name .. " | " .. status .. "]"
							if showName then text = plr.DisplayName .. " " .. text end
							item.abil.Text = text
						end
					elseif item then
						tbl3.espdrop(item)
						tbl17.items[plr] = nil
					end
				end
			end
			for plr, item in pairs(tbl17.items) do
				if not plr.Parent then
					tbl3.espdrop(item)
					tbl17.items[plr] = nil
				end
			end
		end

		tbl3.espstart = function()
			if tbl17.conn then
				return
			end
			tbl17.conn = tbl3.bind(RunService.RenderStepped:Connect(function(l) tbl17 .acc= tbl17 .acc+l;if  tbl17 .acc<0.05 then return;end; tbl17 .acc= tbl17 .acc-0.05; tbl3 .espupd();end))
		end

		tbl3.espstop = function()
			if tbl17.conn then
				tbl17.conn:Disconnect()
				tbl17.conn = nil
			end

			tbl3.espclear()
		end

		tbl3.replion = false
		tbl3.getrep = function(l)if not  tbl3 .replion then local K= ReplicatedStorage :FindFirstChild("Packages");local p=K and(K:FindFirstChild("Replion"));if p then  tbl3 .replion=require(p);end;end;if not  tbl3 .replion then  tbl3 .logwev("getrep",10,"Replion","module unavailable - retrying next call");return nil;end;return  tbl3 .replion.Client:GetReplion(l)or nil;end

		tbl3.claimdaily = function()
			local remote = ReplicatedStorage:FindFirstChild("Remote")
			remote = remote and remote:FindFirstChild("RemoteFunction")
			if not remote then
				return
			end
			local Data = nil

			for i = 1, 20 do
				Data = tbl3.getrep("Data")
				if not Data then
					task.wait(0.5)
					continue
				end
				break
			end

			if not Data then
				return
			end
			local NewDailyLoginStreak = Data:Get("NewDailyLoginStreak")
			local NewDailyLoginAwardList = Data:Get("NewDailyLoginAwardList")
			local n3 = tonumber(NewDailyLoginStreak) or 0
			local n4 = 0

			for i = 1, min(n3, 30) do
				if not (type(NewDailyLoginAwardList) == "table" and table.find(NewDailyLoginAwardList, i)) then
					if remote:InvokeServer("ClaimNewDailyLoginReward", i) then
						n4 += 1
					end

					task.wait(0.5)
				end
			end

			if n4 > 0 then
				tbl3.notif("Daily Login", format("Claimed %d daily reward%s.", n4, n4 == 1 and "" or "s"), 5)
			end
		end

		tbl3.updatedata = function()
			if tbl3.dlacct then
				local accountAge = localPlayer.AccountAge
				local membership = tostring(localPlayer.MembershipType):gsub("Enum.MembershipType.", "")
				local tbl18 = {}
				local str2 = "Name: " .. localPlayer.DisplayName .. " (@" .. localPlayer.Name .. ")"
				local str3 = "User ID: " .. tostring(localPlayer.UserId)
				local str4 = "Account Age: " .. tostring(accountAge) .. " days"
				local str5 = "Membership: " .. membership
				local str6 = "Place / Universe: " .. tostring(game.PlaceId) .. " / " .. tostring(game.GameId)
				local str7 = "Job ID: " .. tostring(game.JobId)
				local str8 = "Region: " .. tostring(tbl3.myregion() or "unknown")
				local str9 = "Players: " .. #Players:GetPlayers() .. " / " .. tostring(Players.MaxPlayers)
				local str10 = "Ping: " .. format("%d ms", floor(tbl3.getping() + 0.5))
				local str11 = "FPS: " .. tostring(tbl3.datafps or 0)
				tbl18[1] = str2
				tbl18[2] = str3
				tbl18[3] = str4
				tbl18[4] = str5
				tbl18[5] = ""
				tbl18[6] = str6
				tbl18[7] = str7
				tbl18[8] = str8
				tbl18[9] = str9
				tbl18[10] = str10
				tbl18[11] = str11
				tbl3.dlacct:SetText(table.concat(tbl18, "\n"))
			end

			if tbl3.dlsess then
				local v5 = tbl3.safechar()
				local attribute = v5 and v5:GetAttribute("CurrentlyEquippedSword") or localPlayer:GetAttribute("CurrentlyEquippedSword") or "-"
				local attribute2 = v5 and v5:GetAttribute("Ability") or localPlayer:GetAttribute("CurrentlyEquippedAbility") or "-"
				local tbl18 = {}
				local str2 = "Sword: " .. tostring(attribute)
				local str3 = "Ability: " .. tostring(attribute2)
				tbl18[1] = str2
				tbl18[2] = str3
				local leaderstats = localPlayer:FindFirstChild("leaderstats")

				if leaderstats then
					for _, child in ipairs(leaderstats:GetChildren()) do
						tbl18[#tbl18 + 1] = child.Name .. ": " .. tostring(child.Value)
					end
				end

				local Data = tbl3.getrep("Data")

				if Data then
					local Wins = Data:Get("TotalStats.Wins")

					if type(Wins) == "number" then
						if not tbl3.startwins then
							tbl3.startwins = Wins
						end

						tbl18[#tbl18 + 1] = "Total Wins: " .. tostring(Wins)
						tbl18[#tbl18 + 1] = "Session Wins: " .. tostring(Wins - tbl3.startwins)
					end
				end

				tbl18[#tbl18 + 1] = ""
				tbl18[#tbl18 + 1] = format("Rounds: %d (won %d)", tbl3.rndplayed, tbl3.rndwins)
				tbl18[#tbl18 + 1] = "Round Kills: " .. tostring(tbl3.rndkills)

				if tbl3.rndlast ~= "" then
					tbl18[#tbl18 + 1] = "Last Round: " .. tbl3.rndlast
				end

				local n3 = os.time() - (tbl3.sessionstart or os.time())
				tbl18[#tbl18 + 1] = "Session Parries: " .. tostring(tbl9.sessparry or 0)
				tbl18[#tbl18 + 1] = format("In Server: %02d:%02d", floor(n3 / 60), n3 % 60)
				tbl3.dlsess:SetText(table.concat(tbl18, "\n"))
			end

			if tbl3.devstat then
				tbl3.devstat()
			end
		end

		tbl3.startdatapanel = function()
			tbl3.sessionstart = tbl3.sessionstart or os.time()
			if tbl3.dataconn then
				return
			end
			tbl3.datafps = 0
			local n3 = 0
			local v5 = clock()
			tbl3.dataconn = tbl3.bind(RunService.RenderStepped:Connect(function() n3 +=1;local l= clock ();if l- v5 >=0.5 then  tbl3 .datafps= floor ( n3 /(l- v5 )+0.5); n3 , v5 =0,l;end;end))

			tbl3.bindt(task.spawn(function()
				while true do
					task.wait(1)
					tbl3.updatedata()
				end
			end))
		end

		tbl3.pokeafk = function()
			local v5 = tbl3.getvim()
			v5:SendKeyEvent(true, Enum.KeyCode.T, false, game)
			task.wait(0.05)
			v5:SendKeyEvent(false, Enum.KeyCode.T, false, game)
		end

		tbl3.stopafk = function()
			if tbl9.afkthread then
				task.cancel(tbl9.afkthread)
				tbl9.afkthread = nil
			end

			if tbl9.afkconn then
				tbl9.afkconn:Disconnect()
				tbl9.afkconn = nil
			end
		end

		tbl3.startafk = function()
			tbl3.stopafk()

			tbl9.afkconn = tbl3.bind(localPlayer.Idled:Connect(function()
				if tbl10.antiafk then
					tbl3.pokeafk()
				end
			end))

			tbl9.afkthread = tbl3.bindt(task.spawn(function()
				while tbl10.antiafk do
					tbl3.pokeafk()
					task.wait(120)
				end
			end))
		end

		local riseLoaderUrl = type(_G.RiseLoaderUrl) == "string" and _G.RiseLoaderUrl ~= "" and _G.RiseLoaderUrl

		if riseLoaderUrl then
			local v5 = riseLoaderUrl

			tbl3.queuetp = function()
				local v6 = queueonteleport
				if type(v6) ~= "function" then
					return
				end
				local riseScriptSource

				if type(_G.RiseScriptSource) == "string" and _G.RiseScriptSource ~= "" then
					riseScriptSource = _G.RiseScriptSource
				else
					riseScriptSource = nil

					if v5:sub(1, 4) == "http" then
						riseScriptSource = ("loadstring(game:HttpGet(\"%s\"))()"):format(v5)
					end
				end

				if not riseScriptSource then
					tbl3.notif("Auto Execute", "Can't restart itself after a teleport. Run the script again from its loader.", 6)
					return
				end
				v6("_G.cuties = nil\n_G.RiseBoot = nil\n" .. riseScriptSource)
				tbl3.queued = true
			end

			tbl3.vipcb = function(arg)
				local textChatMessageProperties = Instance.new("TextChatMessageProperties")

				if tbl10.viptag and arg.TextSource and arg.TextSource.UserId == localPlayer.UserId then
					textChatMessageProperties.PrefixText = "<font color='#FFD700'>[VIP]</font> " .. arg.PrefixText
				end

				return textChatMessageProperties
			end

			tbl3.applyvip = function()
				if tbl9.vipset then
					return
				end
				local TextChatService = game:GetService("TextChatService")
				TextChatService.OnIncomingMessage = tbl3.vipcb
				tbl9.vipset = true

				tbl3.bindt(task.delay(2, function()
					if tbl9.vipset then
						TextChatService.OnIncomingMessage = tbl3.vipcb
					end
				end))
			end

			tbl3.killvip = function()
				if not tbl9.vipset then
					return
				end

				game:GetService("TextChatService").OnIncomingMessage = function()
					return nil
				end

				tbl9.vipset = false
			end

			local tbl18 = {
				Cinematic = {
					bloom = { Intensity = 0.85, Size = 24, Threshold = 0.92 },
					cc = {
						Brightness = 0.02,
						Contrast = 0.16,
						Saturation = 0.06,
						TintColor = Color3.fromRGB(255, 246, 236),
					},
					sun = { Intensity = 0.08, Spread = 0.5 },
					dof = { FarIntensity = 0.4, FocusDistance = 0.05, InFocusRadius = 70, NearIntensity = 0 },
				},
				Vivid = {
					bloom = { Intensity = 1.1, Size = 22, Threshold = 0.88 },
					cc = {
						Brightness = 0.04,
						Contrast = 0.2,
						Saturation = 0.28,
						TintColor = Color3.fromRGB(255, 252, 248),
					},
					sun = { Intensity = 0.06, Spread = 0.45 },
					dof = { FarIntensity = 0.25, FocusDistance = 0.05, InFocusRadius = 90, NearIntensity = 0 },
				},
				["Soft Dream"] = {
					bloom = { Intensity = 1.6, Size = 40, Threshold = 0.78 },
					cc = {
						Brightness = 0.06,
						Contrast = -0.05,
						Saturation = 0.1,
						TintColor = Color3.fromRGB(255, 244, 250),
					},
					sun = { Intensity = 0.14, Spread = 0.7 },
					dof = { FarIntensity = 0.55, FocusDistance = 0.05, InFocusRadius = 55, NearIntensity = 0 },
				},
				Noir = {
					bloom = { Intensity = 1, Size = 26, Threshold = 0.9 },
					cc = {
						Brightness = 0,
						Contrast = 0.3,
						Saturation = -0.85,
						TintColor = Color3.fromRGB(235, 240, 255),
					},
					sun = { Intensity = 0.05, Spread = 0.4 },
					dof = { FarIntensity = 0.3, FocusDistance = 0.05, InFocusRadius = 80, NearIntensity = 0 },
				},
				["Warm Sunset"] = {
					bloom = { Intensity = 1.2, Size = 30, Threshold = 0.82 },
					cc = {
						Brightness = 0.03,
						Contrast = 0.12,
						Saturation = 0.18,
						TintColor = Color3.fromRGB(255, 226, 196),
					},
					sun = { Intensity = 0.18, Spread = 0.65 },
					dof = { FarIntensity = 0.35, FocusDistance = 0.05, InFocusRadius = 75, NearIntensity = 0 },
				},
				["Cold Steel"] = {
					bloom = { Intensity = 0.9, Size = 22, Threshold = 0.9 },
					cc = {
						Brightness = 0,
						Contrast = 0.22,
						Saturation = -0.1,
						TintColor = Color3.fromRGB(214, 230, 255),
					},
					sun = { Intensity = 0.05, Spread = 0.4 },
					dof = { FarIntensity = 0.3, FocusDistance = 0.05, InFocusRadius = 85, NearIntensity = 0 },
				},
				["Neon Night"] = {
					bloom = { Intensity = 2, Size = 34, Threshold = 0.7 },
					cc = {
						Brightness = -0.04,
						Contrast = 0.26,
						Saturation = 0.4,
						TintColor = Color3.fromRGB(228, 232, 255),
					},
					sun = { Intensity = 0, Spread = 0.4 },
					dof = { FarIntensity = 0.45, FocusDistance = 0.05, InFocusRadius = 60, NearIntensity = 0 },
				},
			}

			tbl3.clrshade = function()
				if tbl9.shadefx then
					for _, v6 in ipairs(tbl9.shadefx) do
						v6:Destroy()
					end

					tbl9.shadefx = nil
				end
			end

			tbl3.applyshade = function()
				tbl3.clrshade()
				if not tbl10.shaders then
					return
				end
				local cinematic = tbl18[tbl10.shaderpreset] or tbl18.Cinematic
				local shadefx = {}

				local function fn9(arg, arg2)
					local instance = Instance.new(arg)

					for k, v6 in pairs(arg2) do
						instance[k] = v6
					end

					instance.Parent = Lighting
					shadefx[#shadefx + 1] = instance
					return instance
				end

				local v6 = clamp(cinematic.cc.Saturation + (tbl10.saturation or 1) - 1, -1, 1)

				fn9("ColorCorrectionEffect", {
					Name = "_rcc",
					Brightness = clamp(cinematic.cc.Brightness + (tbl10.brightness or 0), -1, 1),
					Contrast = clamp(cinematic.cc.Contrast + (tbl10.contrast or 0), -1, 1),
					Saturation = v6,
					TintColor = cinematic.cc.TintColor,
				})

				fn9("BloomEffect", {
					Name = "_rbloom",
					Intensity = max(0, cinematic.bloom.Intensity * (tbl10.bloom or 1)),
					Size = cinematic.bloom.Size,
					Threshold = cinematic.bloom.Threshold,
				})

				if cinematic.sun and cinematic.sun.Intensity > 0 then
					fn9("SunRaysEffect", { Name = "_rsun", Intensity = cinematic.sun.Intensity, Spread = cinematic.sun.Spread })
				end

				if tbl10.dof and cinematic.dof then
					fn9("DepthOfFieldEffect", {
						Name = "_rdof",
						FarIntensity = cinematic.dof.FarIntensity,
						FocusDistance = cinematic.dof.FocusDistance,
						InFocusRadius = cinematic.dof.InFocusRadius,
						NearIntensity = cinematic.dof.NearIntensity,
					})
				end

				tbl9.shadefx = shadefx
			end

			tbl3.clrrain = function()
				if tbl9.rainconn then
					tbl9.rainconn:Disconnect()
					tbl9.rainconn = nil
				end

				if tbl9.rainfx then
					for _, v6 in ipairs(tbl9.rainfx) do
						v6:Destroy()
					end

					tbl9.rainfx = nil
				end
			end

			tbl3.applyrain = function()
				tbl3.clrrain()
				if not tbl10.rain then
					return
				end
				local part = Instance.new("Part")
				part.Name = "_rrain"
				part.Anchored = true
				part.CanCollide = false
				part.CanQuery = false
				part.CanTouch = false
				part.Transparency = 1
				part.Size = Vector3.new(70, 1, 70)
				part.Orientation = Vector3.zero
				local particleEmitter = Instance.new("ParticleEmitter")
				particleEmitter.Name = "_rrainfx"
				particleEmitter.Rate = tbl10.rainrate or 150
				particleEmitter.Lifetime = NumberRange.new(0.55, 0.8)
				particleEmitter.Speed = NumberRange.new(75, 95)
				particleEmitter.SpreadAngle = Vector2.new(6, 6)
				particleEmitter.Acceleration = Vector3.new(0, -60, 0)
				particleEmitter.EmissionDirection = Enum.NormalId.Bottom
				particleEmitter.Rotation = NumberRange.new(0, 0)
				local new = NumberSequenceKeypoint.new
				particleEmitter.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.18), new(1, 0.1) })
				local numberSequence = NumberSequence.new
				local tbl19 = {}
				local v6 = NumberSequenceKeypoint.new(0, 0.25)
				local v7 = NumberSequenceKeypoint.new(0.8, 0.4)
				local new2 = NumberSequenceKeypoint.new
				tbl19[1] = v6
				tbl19[2] = v7

				do
					local values = table.pack(new2(1, 1))
					table.move(values, 1, values.n, 3, tbl19)
				end

				particleEmitter.Transparency = numberSequence(tbl19)
				particleEmitter.Color = ColorSequence.new(Color3.fromRGB(170, 200, 230))
				particleEmitter.LightEmission = 0.2
				particleEmitter.Brightness = 1
				particleEmitter.ZOffset = 1
				particleEmitter.Parent = part
				part.Parent = Workspace
				tbl9.rainfx = { part }
				tbl9.rainconn = tbl3.bind(RunService.RenderStepped:Connect(function()if not  tbl10 .rain then return;end;local l= tbl3 .safehrp();local K=l and l.Position;K=if not K and  currentCamera then  currentCamera .CFrame.Position else K;if K then  part .Position=K+Vector3.new(0,32,0);end; particleEmitter .Rate= tbl10 .rainrate or 150;end))
			end

			tbl3.stopmusic = function()
				tbl9.musicsound = nil

				for _, child in ipairs(SoundService:GetChildren()) do
					if child.Name == "_rbgm" then
						child:Destroy()
					end
				end
			end

			tbl3.setupmusic = function()
				tbl3.stopmusic()
				if not tbl10.music then
					return
				end
				tbl9.musicgen = (tbl9.musicgen or 0) + 1
				local musicgen = tbl9.musicgen
				local musicid = tbl10.musicid
				local match

				if musicid and musicid ~= "" then
					match = tostring(musicid):match("%d+")
				else
					match = tbl6[tbl10.track]
				end

				if not match or match == "" then
					tbl3.notif("Music", "That track has no audio ID. Pick another song.", 3)
					return
				end
				local num = tonumber(match)

				if num then
					local productInfo = MarketplaceService:GetProductInfo(num)
					if musicgen ~= tbl9.musicgen then
						return
					end

					if type(productInfo) == "table" and productInfo.AssetTypeId then
						if productInfo.AssetTypeId ~= 3 then
							tbl3.notif("Music", "That is not a song. Paste a Roblox audio ID.", 6)
							return
						end
						tbl3.notif("Music", "Now playing \"" .. tostring(productInfo.Name) .. "\"", 3)
					end
				end

				local sound = Instance.new("Sound")
				sound.Name = "_rbgm"
				sound.SoundId = "rbxassetid://" .. tostring(match)
				sound.Volume = clamp((tbl10.vol or 3) / 10, 0, 1)
				sound.Looped = true
				sound.Parent = SoundService
				sound:Play()
				tbl9.musicsound = sound

				tbl3.bindt(task.spawn(function()
					local n3 = clock() + 5

					while clock() < n3 do
						if sound.Parent ~= SoundService then
							return
						end

						if sound.IsLoaded then
							return
						end
						task.wait(0.25)
					end

					if sound.Parent == SoundService and not sound.IsLoaded then
						tbl3.notif("Music", (musicid and musicid ~= "" and "ID " .. tostring(match) or "\"" .. tostring(tbl10.track) .. "\"") .. " won't load. Pick another song.", 5)
					end
				end))
			end

			tbl3.hudbutton = function(name, arg, text, arg2, arg3)
				local screenGui = Instance.new("ScreenGui")
				screenGui.Name = name
				screenGui.ResetOnSpawn = false
				screenGui.IgnoreGuiInset = true
				screenGui.DisplayOrder = 58
				screenGui.Parent = v.ScreenGui or fn6 and fn6() or CoreGui
				local textButton = Instance.new("TextButton")
				textButton.AnchorPoint = Vector2.new(1, 0)
				textButton.Position = UDim2.new(1, -16, 0, arg)
				textButton.Size = UDim2.fromOffset(flag and 128 or 100, flag and 46 or 38)
				textButton.BackgroundColor3 = color
				textButton.BackgroundTransparency = 0.04
				textButton.BorderSizePixel = 0
				textButton.AutoButtonColor = false
				textButton.Font = Enum.Font.GothamBold
				textButton.TextSize = flag and 15 or 13
				textButton.TextColor3 = color2
				textButton.Text = text
				textButton.Parent = screenGui
				tbl3.corner(textButton, 10)
				local v6 = tbl3.stroke(textButton, color3, 1, 0.2)

				local function fn9()
					local v7, v8 = arg2()
					textButton.Text = v7
					textButton.BackgroundColor3 = v8 and accent or color
					textButton.TextColor3 = v8 and Color3.fromRGB(255, 255, 255) or color2
					v6.Color = v8 and accent or color3
				end

				textButton.Activated:Connect(function()
					arg3()
					fn9()
				end)

				tbl3.dragify(textButton, textButton)
				fn9()
				return screenGui, fn9
			end

			local unhook = nil
			local fn9 = nil
			local fn10 = nil
			local fn11 = nil

			tbl3.cleanup = function()
				tbl3.stopap()
				tbl3.stopas()
				tbl3.stopms()
				tbl3.stopabil()
				tbl10.thundernocd = false
				tbl3.setnocd()
				tbl3.delmsgui()
				tbl3.stopstaff()

				if tbl9.vzdash then
					for _, v6 in ipairs(tbl9.vzdash) do
						v6:Destroy()
					end

					tbl9.vzdash = nil
				end

				if tbl9.vzpart then
					tbl9.vzpart:Destroy()
					tbl9.vzpart = nil
				end

				tbl3.clrbt()
				tbl3.clrpt()
				tbl3.espstop()

				if tbl3.restorecos then
					tbl3.restorecos()
				end

				tbl3.setbright(false)
				tbl3.setnofog(false)
				tbl3.setlowgfx(false)

				if tbl14.gravorig ~= nil then
					Workspace.Gravity = tbl14.gravorig
					tbl14.gravorig = nil
				end

				tbl3.restorefov()
				tbl3.applysky("Default")
				tbl3.settime("Default")
				tbl3.stopafk()
				tbl3.stopphantom()
				tbl3.killvip()
				tbl3.clrshade()
				tbl3.clrrain()
				tbl3.stopmusic()

				for _, v6 in ipairs(tbl9.slashoff) do
					v6:Enable()
				end

				if fn10 then
					fn10()
				end

				if unhook then
					unhook()
				end

				if setfpscap then
					setfpscap(0)
				end

				for _, v6 in ipairs({ "RainbowBall", "ShowSwordAccessory" }) do
					localPlayer:SetAttribute(v6, nil)
				end
			end

			toggles.autoparry:OnChanged(function(autoparry)
				tbl10.autoparry = autoparry

				if autoparry then
					tbl3.startap()
					tbl3.notif("Auto Parry", "On.", 3)
				else
					tbl3.stopap()
					tbl3.notif("Auto Parry", "Off.", 3)
				end

			end)

			options.curves:OnChanged(function(crv)
				tbl10.crv = crv
			end)

			do
				local picking = {}
				local prevval = {}
				tbl3.bind(RunService.Heartbeat:Connect(function()
					for _, opt in pairs(options) do
						if type(opt) == "table" and opt.Type == "KeyPicker" then
							picking[opt] = opt.Picking == true
							if opt.Value ~= "Backspace" then
								prevval[opt] = opt.Value
							end
						end
					end
				end))
				tbl3.bind(UserInputService.InputBegan:Connect(function(input)
					if input.KeyCode ~= Enum.KeyCode.Backspace then
						return
					end
					local wasPicking = {}
					for opt, was in pairs(picking) do
						wasPicking[opt] = was
					end
					task.spawn(function()
						RunService.Heartbeat:Wait()
						RunService.Heartbeat:Wait()
						for opt, was in pairs(wasPicking) do
							local justSet = opt.Value == "Backspace" and prevval[opt] ~= "Backspace"
							if was or justSet then
								local mode = opt.Mode or "Toggle"
								local ok = pcall(function()
									opt:SetValue({ "None", mode })
								end)
								if not ok or opt.Value ~= "None" then
									pcall(function()
										opt:SetValue("None")
									end)
								end
								prevval[opt] = "None"
							end
						end
					end)
				end))
			end

			toggles.triggerbot:OnChanged(function(trigger)
				tbl10.trigger = trigger

				if trigger then
					tbl3.starttrigger()
					tbl3.notif("Trigger Bot", "On.", 3)
				else
					tbl3.stoptrigger()
					tbl3.notif("Trigger Bot", "Off.", 3)
				end

			end)

			toggles.nocurvespam:OnChanged(function(nocrv)
				tbl10.nocrv = nocrv
			end)

			for _, name in ipairs(tbl3.curveorder) do
				local bind = options["curvebind_" .. name]
				if bind then
					bind:OnClick(function()
						if options.curves.Value == name and tbl10.crv == name then
							return
						end
						options.curves:SetValue(name)
						tbl10.crv = name
						local nb = options.notif_curvebinds
						if not nb or nb.Value then
							tbl3.notif("Curve", "Curve set to " .. name .. ".", 2)
						end
					end)
				end
			end

			options.parryaccuracy:OnChanged(function(acc)
				tbl10.acc = acc
			end)

			toggles.humanizer:OnChanged(function(hum)
				tbl10.hum = hum

				if hum then
					tbl3.humroll()
					tbl3.notif("Humanizer", "On.", 3)
				else
					tbl10.acc = options.parryaccuracy.Value
					tbl10.rng = options.parryrange.Value
					tbl3.notif("Humanizer", "Off.", 3)
				end
			end)

			options.parryrange:OnChanged(function(rng)
				tbl10.rng = rng
			end)

			toggles.antiafk:OnChanged(function(antiafk)
				tbl10.antiafk = antiafk

				if antiafk then
					tbl3.startafk()
				else
					tbl3.stopafk()
				end
			end)

			toggles.autoexecute:OnChanged(function(autoexec)
				tbl10.autoexec = autoexec

				if autoexec then
					tbl3.queuetp()
				elseif tbl3.queued then
					tbl3.notif("Auto Execute", "Off. It still runs once more after your next teleport.", 6)
				end
			end)

			toggles.viptag:OnChanged(function(viptag)
				tbl10.viptag = viptag
				tbl3.applyvip()
			end)

			toggles.shaders:OnChanged(function(shaders)
				tbl10.shaders = shaders
				tbl3.applyshade()
			end)

			options.shaderpreset:OnChanged(function(shaderpreset)
				tbl10.shaderpreset = shaderpreset
				tbl3.applyshade()
			end)

			toggles.shaderdof:OnChanged(function(dof)
				tbl10.dof = dof
				tbl3.applyshade()
			end)

			options.shaderbloom:OnChanged(function(bloom)
				tbl10.bloom = bloom
				tbl3.applyshade()
			end)

			options.shadersaturation:OnChanged(function(saturation)
				tbl10.saturation = saturation
				tbl3.applyshade()
			end)

			options.shaderbrightness:OnChanged(function(brightness)
				tbl10.brightness = brightness
				tbl3.applyshade()
			end)

			options.shadercontrast:OnChanged(function(contrast)
				tbl10.contrast = contrast
				tbl3.applyshade()
			end)

			toggles.raineffect:OnChanged(function(rain)
				tbl10.rain = rain
				tbl3.applyrain()
			end)

			options.rainintensity:OnChanged(function(rainrate)
				tbl10.rainrate = rainrate
			end)

			toggles.autospam:OnChanged(function(autospam)
				tbl10.autospam = autospam

				if autospam then
					tbl3.startas()
					tbl3.notif("Auto Spam", "On.", 3)
				else
					tbl3.stopas()
					tbl3.notif("Auto Spam", "Off.", 3)
				end
			end)

			toggles.manualspam:OnChanged(function(manspam)
				tbl10.manspam = manspam

				if manspam then
					tbl3.startms()
					tbl3.setmsactive(true)
					tbl3.notif("Manual Spam", "On.", 3)
				else
					tbl3.stopms()
					tbl3.notif("Manual Spam", "Off.", 3)
				end
			end)

			options.parrymethod:OnChanged(function(arg)
				tbl10.keyparry = arg == "Keypress"
			end)

			toggles.norender:OnChanged(function(norender)
				tbl10.norender = norender
				tbl3.setnorender()
			end)

			toggles.emoteonly:OnChanged(function(emoteonly)
				tbl10.emoteonly = emoteonly

				if emoteonly then
					if tbl3.emoteonly then
						tbl3.emoteonly(true)
					end
				end
			end)

			toggles.autoability:OnChanged(function(autoabil)
				if autoabil and not tbl3.featguard("abil", "Auto Ability") then
					toggles.autoability:SetValue(false)
					return
				end
				tbl10.autoabil = autoabil

				if tbl10.autoabil or tbl10.cdprot then
					tbl3.startabil()
				else
					tbl3.stopabil()
				end
			end)

			toggles.cooldownprotection:OnChanged(function(cdprot)
				if cdprot and not tbl3.featguard("abil", "Cooldown Protection") then
					toggles.cooldownprotection:SetValue(false)
					return
				end
				tbl10.cdprot = cdprot

				if tbl10.autoabil or tbl10.cdprot then
					tbl3.startabil()
				else
					tbl3.stopabil()
				end
			end)

			toggles.thundernocd:OnChanged(function(thundernocd)
				tbl10.thundernocd = thundernocd
				tbl3.setnocd()
			end)

			options.abilityminspeed:OnChanged(function(abilspd)
				tbl10.abilspd = abilspd
			end)

			toggles.staffdetection:OnChanged(function(staff)
				tbl10.staff = staff

				if staff then
					tbl3.startstaff()
				else
					tbl3.stopstaff()
				end
			end)

			options.staffaction:OnChanged(function(staffdo)
				tbl10.staffdo = staffdo
			end)

			toggles.visualizer:OnChanged(function(viz)
				tbl10.viz = viz
				tbl3.setupviz()
			end)

			options.visualizercolour:OnChanged(function(vizcol)
				tbl10.vizcol = vizcol
			end)

			tbl3.setaccent = function()
				v.Scheme.AccentColor = tbl3.uiaccent
				v:UpdateColorsUsingRegistry()
			end

			toggles.balltrail:OnChanged(function(bt)
				tbl10.bt = bt

				if bt then
					tbl3.applybt()
				else
					tbl3.clrbt()
				end
			end)

			toggles.balltrailrainbow:OnChanged(function(btrb)
				tbl10.btrb = btrb

				if tbl10.bt then
					tbl3.refbt()
				end
			end)

			toggles.balltrailparticles:OnChanged(function(btpart)
				tbl10.btpart = btpart

				if tbl10.bt then
					tbl3.refbt()
				end
			end)

			toggles.balltrailglow:OnChanged(function(btglow)
				tbl10.btglow = btglow

				if tbl10.bt then
					tbl3.refbt()
				end
			end)

			options.balltrailstartcolour:OnChanged(function(btstart)
				tbl10.btstart = btstart

				if tbl10.bt then
					tbl3.refbt()
				end
			end)

			options.balltrailendcolour:OnChanged(function(btend)
				tbl10.btend = btend

				if tbl10.bt then
					tbl3.refbt()
				end
			end)

			options.balltraillifetime:OnChanged(function(btlife)
				tbl10.btlife = btlife

				if tbl10.bt then
					tbl3.refbt()
				end
			end)

			toggles.playertrail:OnChanged(function(pt)
				tbl10.pt = pt

				if pt then
					tbl3.applypt()
				else
					tbl3.clrpt()
				end
			end)

			toggles.playertrailrainbow:OnChanged(function(ptrb)
				tbl10.ptrb = ptrb

				if tbl10.pt then
					tbl3.refpt()
				end
			end)

			options.playertrailcolour:OnChanged(function(ptcol)
				tbl10.ptcol = ptcol

				if tbl10.pt then
					tbl3.refpt()
				end
			end)

			options.playertraillifetime:OnChanged(function(ptlife)
				tbl10.ptlife = ptlife

				if tbl10.pt then
					tbl3.refpt()
				end
			end)

			options.playertrailwidth:OnChanged(function(ptwidth)
				tbl10.ptwidth = ptwidth

				if tbl10.pt then
					tbl3.refpt()
				end
			end)

			tbl3.bind(localPlayer.CharacterAdded:Connect(function()
				task.wait(0.5)

				if tbl10.pt then
					tbl3.applypt()
				end
			end))

			toggles.abilityesp:OnChanged(function(arg)
				if arg then
					tbl3.espstart()
				else
					tbl3.espstop()
				end
			end)

			toggles.fullbright:OnChanged(function(arg)
				tbl3.setbright(arg)
			end)

			toggles.nofog:OnChanged(function(arg)
				tbl3.setnofog(arg)
			end)

			toggles.customfov:OnChanged(function(arg)
				if arg then
					tbl3.startfov()
				else
					tbl3.restorefov()
				end
			end)

			toggles.customgrav:OnChanged(function()
				tbl3.setgrav()
			end)

			options.grav:OnChanged(function()
				if toggles.customgrav.Value then
					tbl3.setgrav()
				end
			end)

			toggles.lowgfx:OnChanged(function(arg)
				tbl3.setlowgfx(arg)
			end)

			toggles.fpscap:OnChanged(function(fpscap)
				tbl10.fpscap = fpscap
				tbl3.applycap()
			end)

			toggles.antilag:OnChanged(function(arg)
				if arg then
					tbl3.startantilag()
				elseif tbl9.alapplied then
					tbl9.alapplied = false

					if not (toggles.lowgfx and toggles.lowgfx.Value) then
						tbl3.setlowgfx(false)
					end
				end
			end)

			options.fpscapvalue:OnChanged(function(fpsval)
				tbl10.fpsval = fpsval

				if tbl10.fpscap then
					tbl3.applycap()
				end
			end)

			toggles.ffenable:OnChanged(function(arg)
				if not arg then
					return
				end
				toggles.ffenable:SetValue(false)

				if tbl3.ffapply() > 0 then
					tbl3.notif("FFlags", "Rejoining to apply your flags.", 3)

					task.delay(1.5, function()
						if fn3 then
							fn3()
						end
					end)
				end
			end)

			options.skybox:OnChanged(function(arg)
				tbl3.applysky(arg)

				if arg == "Default" then
					tbl3.notif("Skybox", "Reset to default.", 2)
				else
					tbl3.notif("Skybox", "Set to \"" .. tostring(arg) .. "\".", 2)
				end
			end)

			options.timeofday:OnChanged(function(arg)
				tbl3.settime(arg)
			end)

			toggles.music:OnChanged(function(music)
				tbl10.music = music
				tbl3.setupmusic()
			end)

			options.musictrack:OnChanged(function(track)
				tbl10.track = track

				if tbl10.music then
					tbl3.setupmusic()
				end
			end)

			options.musicvolume:OnChanged(function(vol)
				tbl10.vol = vol

				if tbl9.musicsound then
					tbl9.musicsound.Volume = clamp(vol / 10, 0, 1)
				end
			end)

			options.musiccustom:OnChanged(function(musicid)
				tbl10.musicid = musicid or ""

				if tbl10.music then
					tbl3.setupmusic()
				end
			end)

			tbl3.bind(localPlayer.CharacterAdded:Connect(function()
				if toggles.customgrav.Value then
					task.defer(tbl3.setgrav)
				end
			end))

			_G.stagesh = "handlers"
			tbl3.chkfeat()

			tbl3.onstart = {
				{
					flag = "abilityesp",
					run = function()
						tbl3.espstart()
					end,
				},
				{
					flag = "fullbright",
					run = function()
						tbl3.setbright(true)
					end,
				},
				{
					flag = "nofog",
					run = function()
						tbl3.setnofog(true)
					end,
				},
				{
					flag = "customgrav",
					run = function()
						tbl3.setgrav()
					end,
				},
				{
					flag = "lowgfx",
					run = function()
						tbl3.setlowgfx(true)
					end,
				},
				{
					flag = "norender",
					run = function()
						tbl3.setnorender()
					end,
				},
				{
					flag = "thundernocd",
					run = function()
						tbl3.setnocd()
					end,
				},
				{
					flag = "emoteonly",
					run = function()
						if tbl3.emoteonly then
							tbl3.emoteonly(true)
						end
					end,
				},
				{
					flag = "antilag",
					run = function()
						tbl3.startantilag()
					end,
				},
				{ run = function()
					tbl3.applycap()

					if tbl10.fpscap then
						tbl3.notif("FPS Cap", format("FPS capped at %d. Change it in Performance.", tbl10.fpsval or 60), 6)
					end

					if options.skybox.Value and options.skybox.Value ~= "Default" then
						tbl3.applysky(options.skybox.Value)
					end

					if options.timeofday.Value and options.timeofday.Value ~= "Default" then
						tbl3.settime(options.timeofday.Value)
					end
				end },
				{
					flag = "autoparry",
					run = function()
						tbl3.startap()
					end,
				},
				{
					flag = "triggerbot",
					run = function()
						tbl3.starttrigger()

						if tbl10.autoparry then
							tbl10.autoparry = false
							tbl3.stopap()
							toggles.autoparry:SetValue(false)
						end
					end,
				},
				{
					flag = "autospam",
					run = function()
						tbl3.startas()
					end,
				},
				{
					flag = "manualspam",
					run = function()
						tbl3.startms()
						tbl3.refmsui()
					end,
				},
				{ run = function()
					if toggles.autoability.Value or toggles.cooldownprotection.Value then
						tbl3.startabil()
					end
				end },
				{
					flag = "staffdetection",
					run = function()
						tbl3.startstaff()
					end,
				},
				{
					flag = "visualizer",
					run = function()
						tbl3.setupviz()
					end,
				},
				{
					flag = "balltrail",
					run = function()
						tbl3.applybt()
					end,
				},
				{
					flag = "playertrail",
					run = function()
						tbl3.applypt()
					end,
				},
				{ run = function()
					if (toggles.headless.Value or toggles.korblox.Value or toggles.avatarchanger.Value) and tbl3.applycos then
						tbl3.applycos()
					end
				end },
				{
					flag = "antiafk",
					run = function()
						tbl3.startafk()
					end,
				},
				{
					flag = "autoexecute",
					run = function()
						tbl3.queuetp()
					end,
				},
				{
					flag = "viptag",
					run = function()
						tbl3.applyvip()
					end,
				},
				{
					flag = "shaders",
					run = function()
						tbl3.applyshade()
					end,
				},
				{
					flag = "raineffect",
					run = function()
						tbl3.applyrain()
					end,
				},
				{
					flag = "music",
					run = function()
						tbl3.setupmusic()
					end,
				},
				{ run = function()
					if tbl10.devscreen and tbl10.devscreen ~= "Off" then
						tbl3.devui(tbl10.devscreen, true)
					end

					if tbl10.devtype and tbl10.devtype ~= "Off" then
						tbl3.devarm(tbl10.devtype, true)
					end

					tbl3.devstat()
				end },
				{ run = function()
					if toggles.unlockall and toggles.unlockall.Value and fn9 then
						fn9()
					elseif toggles.equipautoload and toggles.equipautoload.Value and fn11 then
						fn11(false)
					end
				end },
			}

			local tbl20 = {}

			for _, v6 in ipairs(tbl3.onstart) do
				if v6.flag and not toggles[v6.flag] then
					tbl20[#tbl20 + 1] = v6.flag
				end
			end

			if #tbl20 > 0 then
				table.sort(tbl20)
				warn("[boberhook] startup list points at toggles that do not exist: " .. table.concat(tbl20, ", "))
			end

			tbl3.bootstrap_saved_connections = function()
				tbl3.syncopt()
				tbl3.sendping()
				tbl3.ffload()

				tbl3.setaccent()

				if toggles.customfov.Value then
					tbl3.startfov()
				end

				tbl3.startdatapanel()
				tbl3.bindt(task.spawn(tbl3.claimdaily))

				for _, v6 in ipairs(tbl3.onstart) do
					local flag2 = v6.flag and toggles[v6.flag]

					if not v6.flag or flag2 and flag2.Value then
						v6.run()
					end
				end
			end

			tbl3.loadsave()
			v2:LoadAutoloadConfig()
			tbl3.hooksave()
			_G.stagesh = "config"

			task.spawn(function()
				task.wait(0.2)
				tbl3.bootstrap_saved_connections()
			end)

			_G.stagesh = "boot"
			local Replion = require(ReplicatedStorage.Packages.Replion)
			local misc = ReplicatedStorage:FindFirstChild("Misc")
			local v6 = nil
			local client = nil
			local v7 = nil
			local v8 = nil
			local v9 = nil
			local v10 = nil
			local swords = nil
			local function fn12()if setthreadidentity then setthreadidentity(8);end;end
			local function fn13(l)if not l then return nil;end; fn12 ();return require(l);end
			local function fn14(h,...)local l=h;for h=1,select("#",...),1 do if typeof(l)~="Instance"then return nil;end;l=(l:FindFirstChild((select(h,...))));end;return l;end

			local tbl21 = {
				wheelfile = "boberhook_Wheel_" .. tostring(game.GameId) .. ".json",
				wheel = {},
				equipfile = "boberhook_Equip_" .. tostring(game.GameId) .. ".json",
				equip = {},
				ncfile = "boberhook_UnlockNames_" .. tostring(game.GameId) .. ".json",
				hooked = false,
				guihooked = false,
				explhooked = false,
				trove = nil,
				noacc = false,
				explname = nil,
				offconns = {},
				lost = true,
			}

			local fn15 = nil

			local function fn16(arg)
				if not Replion then
					Replion = fn13(fn14(ReplicatedStorage, "Packages", "Replion"))
				end

				if not Replion then
					tbl3.logwev("uaReplion", 10, "UnlockAll", "Replion module unavailable (require failed)")
					return nil
				end
				local replion = Replion.Client:GetReplion(arg)
				if replion then
					return replion
				end
				local n3 = clock() + 5

				while clock() < n3 do
					task.wait(0.1)
					local replion2 = Replion.Client:GetReplion(arg)
					if replion2 then
						return replion2
					end
				end

				return nil
			end

			local tbl22 = {}
			local v11 = nil
			local v12 = nil

			local function fn17(arg)
				if not v12 then
					local collection = type(v11) == "table" and type(v11.GetCollection) == "function" and v11:GetCollection() or nil

					if type(collection) == "table" and next(collection) then
						v12 = collection
					end
				end

				return v12 and v12[arg] or nil
			end

			local function fn18(arg, arg2)
				if arg ~= "Sword" then
					return { Name = arg2, Id = arg2 }
				end
				local sword = tbl22[arg2]

				if sword == nil then
					sword = swords and swords.GetSword and swords:GetSword(arg2) or false
					tbl22[arg2] = sword
				end

				local tbl23 = { Name = arg2, Id = arg2 }

				if type(sword) == "table" then
					if sword.HasFinisher then
						tbl23.Finisher = true
					end

					if sword.AccessoryUnlockable and fn17(arg2) then
						tbl23.Accessory = true
					end
				end

				return tbl23
			end

			local function fn19(arg, arg2)
				if client and client.ItemToKey then
					local v13 = client:ItemToKey(arg, fn18(arg, arg2), { "Id" })
					if type(v13) == "string" then
						return v13
					end
				end

				return HttpService:JSONEncode({ { "Name", arg2 } }) or arg2
			end

			local function fn20(arg, arg2)
				if type(arg) ~= "string" then
					return tostring(arg)
				end

				if client and client.KeyToItem then
					local v13 = client:KeyToItem(arg)
					if type(v13) == "table" and v13.Name then
						return v13.Name
					end
				end

				local str2 = arg:sub(1, 1)

				if str2 == "[" or str2 == "{" then
					local data = HttpService:JSONDecode(arg)

					if type(data) == "table" then
						for _, v13 in ipairs(data) do
							if v13[1] == "Name" then
								return v13[2]
							end
						end

						if data.Name then
							return data.Name
						end
					end
				end

				if arg2 and Replion and Replion.Client then
					local replion = Replion.Client:GetReplion("Inventory")
					replion = replion and replion:Get({ "Inventory", arg2, arg })
					if type(replion) == "table" and replion.Name then
						return replion.Name
					end
				end

				return arg
			end

			local function fn21(arg)
				local tbl23 = {}
				local v13 = misc and misc:FindFirstChild(arg)

				if v13 then
					for _, child in ipairs(v13:GetChildren()) do
						tbl23[#tbl23 + 1] = child.Name
					end
				end

				return tbl23
			end

			local function fn22()
				local tbl23 = {}

				if swords and swords.GetCollection then
					local collection = swords:GetCollection()

					if type(collection) == "table" then
						for k in pairs(collection) do
							tbl23[#tbl23 + 1] = k
						end
					end
				end

				return tbl23
			end

			local function fn23(arg, arg2)
				local character = localPlayer.Character
				if arg ~= nil then
					return arg == localPlayer or arg == character
				end
				return arg2 ~= nil and arg2 == character
			end

			local function fn24()
				if tbl21.explhooked then
					return
				end
				local v13 = fn13(fn14(ReplicatedStorage, "Controllers", "VFXController"))
				if type(v13) ~= "table" or type(v13.PlayExplosion) ~= "function" then
					return
				end
				tbl21.explmod = v13
				tbl21.explorig = v13.PlayExplosion
				v13.PlayExplosion = function(l,K,p,E,k,a,d,...)local I= tbl21 .explname and  tbl21 .explname~=""and  tbl21 .explname~=K;return  tbl21 .explorig(l,if I and( fn23 (a,k))then  tbl21 .explname else K,p,E,k,a,d,...);end
				tbl21.explhooked = true
			end

			local function fn25(arg, arg2)
				local Inventory = fn16("Inventory")
				if not (Inventory and type(Inventory._set) == "function") then
					return
				end
				Inventory:_set({ "Equipped", arg }, { Name = arg2, Id = fn19(arg, arg2) })
			end

			local function fn26(arg, arg2)
				local Inventory = fn16("Inventory")
				if not Inventory then
					return
				end
				local v13 = fn19(arg, arg2)

				if type(Inventory._update) == "function" then
					Inventory:_update({ "Inventory", arg }, { [v13] = fn18(arg, arg2) })
				elseif type(Inventory._set) == "function" then
					local v14 = Inventory:Get({ "Inventory", arg })
					local tbl23 = {}

					if type(v14) == "table" then
						for k, v15 in pairs(v14) do
							tbl23[k] = v15
						end
					end

					tbl23[v13] = fn18(arg, arg2)
					Inventory:_set({ "Inventory", arg }, tbl23)
				end
			end

			tbl21.verifyeq = function(arg, arg2)
				local Inventory = fn16("Inventory")
				if not Inventory then
					return false
				end
				local v13 = Inventory:Get({ "Equipped", arg })
				return type(v13) == "table" and v13.Name == arg2
			end

			tbl21.ensureeq = function(arg, arg2)
				tbl21.eqlatest = tbl21.eqlatest or {}
				tbl21.eqlatest[arg] = arg2

				tbl3.bindt(task.spawn(function()
					for i = 1, 4 do
						if tbl21.eqlatest[arg] ~= arg2 then
							return
						end

						if tbl21.verifyeq(arg, arg2) then
							return
						end
						task.wait(0.35)
						if tbl21.eqlatest[arg] ~= arg2 then
							return
						end
						fn26(arg, arg2)
						fn25(arg, arg2)
					end
				end))
			end

			local function fn27(arg, swname, arg2)
				if not swname or swname == "" then
					return
				end

				if arg == "Sword" then
					tbl10.swskin = true
					tbl10.swname = swname
					tbl21.skinmine = true
					tbl3.initsword()
					tbl3.hookslash()
					tbl3.skinloop()

					if tbl3.applysword() == false then
						tbl10.swskin = false
						tbl10.swname = ""
						return
					end

					tbl3.setswattr(swname)
					fn26("Sword", swname)
					fn25("Sword", swname)
					tbl21.ensureeq("Sword", swname)

					if tbl21.finequip then
						tbl21.finequip(swname)
					end
				elseif arg == "Explosion" then
					tbl21.explname = swname
					fn24()

					if tbl21.prefetch then
						tbl21.prefetch("Explosions", swname)
					end

					fn26("Explosion", swname)
					fn25("Explosion", swname)
					tbl21.ensureeq("Explosion", swname)
				end

				if not arg2 and (arg == "Sword" or arg == "Explosion") then
					tbl21.equip[arg] = swname

					if fn15 then
						fn15()
					end
				end
			end

			tbl21.cursword = function()local l= tbl10 .swname;return if not l or l==""then( tbl3 .swequipped())else l;end

			tbl3.uaawaken = function()
				tbl21.arm()
				local v13 = tbl21.cursword()
				if not v13 or v13 == "" then
					return
				end
				swords = swords or tbl3.initsword()
				if not swords then
					tbl3.notif("Unlock All", "Swords aren't ready yet. Try again in a second.", 4)
					return
				end
				local str2 = "Awakened " .. v13

				if swords:GetSword(str2) ~= nil then
					fn27("Sword", str2)
					tbl3.notif("Unlock All", "Equipped \"" .. str2 .. "\".", 3)
				else
					tbl3.notif("Unlock All", v13 .. " has no awakened version.", 3)
				end
			end

			tbl3.uaequipall = function()
				tbl21.arm()

				for _, v13 in ipairs({ "Sword", "Explosion" }) do
					local v14 = tbl21.equip[v13]

					if type(v14) == "string" and v14 ~= "" then
						fn27(v13, v14, true)
					end
				end

				tbl3.notif("Unlock All", "Your saved loadout is equipped.", 3)
			end

			tbl3.uapreviewfin = function()
				if tbl21.finbusy then
					return
				end
				local v13 = tbl21.finfor(tbl21.cursword())

				if not v13 and options.swordchangername then
					v13 = tbl21.finfor(options.swordchangername.Value)
				end

				if not v13 then
					tbl3.notif("Finisher", "That sword has no finisher.", 4)
					return
				end

				if tbl3.isalive() then
					tbl3.notif("Finisher", "Preview only works in the lobby, not mid-round.", 5)
					return
				end
				local v14 = tbl21.finctrl()
				if not v14 or type(v14.Preview) ~= "function" then
					tbl3.notif("Finisher", "Finishers aren't loaded yet. Try again in a second.", 5)
					return
				end
				local featuresToggle = fn14(ReplicatedStorage, "FeaturesToggle", "LimitedSwords")
				if featuresToggle and featuresToggle.Value == false then
					tbl3.notif("Finisher", "The game has showrooms turned off right now.", 5)
					return
				end
				tbl21.finbusy = true

				tbl3.bindt(task.spawn(function()
					if not tbl21.repasset("Finishers", v13) then
						tbl21.finbusy = false
						tbl3.notif("Finisher", ("Couldn't load the %s finisher."):format(v13), 5)
						return
					end

					if not tbl21.finplayable(v13) then
						tbl21.finbusy = false
						tbl3.notif("Finisher", ("The %s finisher isn't loaded yet."):format(v13), 5)
						return
					end

					tbl3.bindt(task.delay(tbl21.findur(v13) + 2, function()
						tbl21.finbusy = false
					end))

					v14:Preview(v13)

					if setthreadidentity and tbl3.baseident then
						setthreadidentity(tbl3.baseident)
					end
				end))
			end

			tbl21.applyacc = function()
				tbl9.noacc = tbl21.noacc
				localPlayer:SetAttribute("ShowSwordAccessory", not tbl21.noacc)
				local swname = tbl10.swname
				local v13 = tbl3.safechar()
				if not (swname and swname ~= "" and v13 and swords) or tbl9.swbad[swname] then
					return
				end

				tbl3.bindt(task.spawn(function()
					if type(swords.GetInstance) == "function" then
						if not swords:GetInstance(swname) then
							tbl9.swbad[swname] = true
							return
						end
					end

					if not v13.Parent then
						return
					end

					for _, child in ipairs(v13:GetChildren()) do
						if child:IsA("Model") and swords:GetSword(child.Name) then
							child:Destroy()
						end
					end

					tbl3.equipsword(v13, swname, tbl21.noacc, true)

					if tbl9.swctrl and tbl9.swctrl.SetSword then
						tbl9.swctrl:SetSword(swname)
					end
				end))
			end

			local function fn28()
				if tbl21.snapping then
					return false
				end
				tbl21.snapping = true
				local Inventory = fn16("Inventory")
				local owned = { Sword = {}, Explosion = {}, Emote = {} }
				local flag2 = false

				if Inventory then
					for _, v13 in ipairs({ "Sword", "Explosion", "Emote" }) do
						local v14 = Inventory:Get({ "Inventory", v13 })

						if type(v14) == "table" then
							for _, v15 in pairs(v14) do
								if type(v15) == "table" and v15.Name then
									owned[v13][v15.Name] = true
								end
							end
						end
					end

					flag2 = true
				end

				tbl21.snapping = false
				if not flag2 then
					return false
				end
				tbl21.owned = owned
				tbl21.ownedat = clock()
				return true
			end

			local function fn29(arg, arg2)
				if not arg or not arg2 then
					return false
				end

				if not tbl21.owned then
					tbl3.bindt(task.spawn(fn28))
					return false
				end
				local flag2 = not tbl21.everunlocked

				if flag2 then
					flag2 = clock() - (tbl21.ownedat or 0) > 5
				end

				if flag2 then
					tbl3.bindt(task.spawn(fn28))
				end

				return tbl21.owned[arg] and tbl21.owned[arg][arg2] == true or false
			end

			local function fn30()
				if tbl21.everunlocked then
					return
				end

				if not tbl21.owned and not fn28() then
					return
				end
				tbl21.everunlocked = true
			end

			local function fn31(arg)
				if not arg or arg.done then
					return
				end
				arg.done = true

				for _, v13 in ipairs(arg) do
					rawset(v13.sig, "_handlerListHead", v13.head)
				end
			end

			local function fn32(arg, arg2)
				local value = arg._signals and rawget(arg._signals, "_containers")
				value = value and value.onChange
				value = value and value.Inventory
				if not value then
					return nil
				end
				local tbl23 = {}

				for _, v13 in ipairs(arg2) do
					local v14 = value[v13]
					local value2 = v14 and rawget(v14, "__signal")
					local value3 = value2 and rawget(value2, "_handlerListHead")

					if value3 ~= nil and value3 ~= false then
						tbl23[#tbl23 + 1] = { sig = value2, head = value3 }
						rawset(value2, "_handlerListHead", false)
					end
				end

				if #tbl23 == 0 then
					return nil
				end
				tbl3.bindt(task.defer(fn31, tbl23))
				return tbl23
			end

			local function fn33(arg)
				local Inventory = fn16("Inventory")
				if not Inventory then
					return false
				end
				local tbl23 = {}
				local tbl24 = {}
				local flag2 = type(Inventory._update) == "function"
				local flag3 = false

				for k, v13 in pairs(arg) do
					local v14 = Inventory:Get({ "Inventory", k })
					local tbl25 = {}

					if type(v14) == "table" then
						for k2, v15 in pairs(v14) do
							tbl25[k2] = v15
						end
					end

					local owned = tbl21.owned and tbl21.owned[k] or {}
					local v15 = nil
					local v16 = nil
					local n3 = 0

					for _, v17 in ipairs(v13) do
						local v18 = fn19(k, v17)

						if tbl25[v18] == nil and not owned[v17] then
							local v19 = fn18(k, v17)

							if flag2 and not v15 then
								v15 = v18
								v16 = v19
							else
								tbl25[v18] = v19
							end

							n3 += 1
						end
					end

					if n3 > 0 then
						tbl23[k] = tbl25
						flag3 = true

						if v15 then
							tbl24[#tbl24 + 1] = { k, v15, v16 }
						end
					end
				end

				if not flag3 then
					return true
				end
				local tbl25 = {}

				for k in pairs(tbl23) do
					tbl25[#tbl25 + 1] = k
				end

				local v13 = fn32(Inventory, tbl25)
				local flag4

				if flag2 then
					Inventory:_update({ "Inventory" }, tbl23)
					flag4 = true
				else
					flag4 = false

					if type(Inventory._set) == "function" then
						for k, v14 in pairs(tbl23) do
							Inventory:_set({ "Inventory", k }, v14)
						end

						flag4 = true
					end
				end

				fn31(v13)

				if flag4 then
					for _, v14 in ipairs(tbl24) do
						Inventory:_update({ "Inventory", v14[1] }, { [v14[2]] = v14[3] })
					end
				end

				return flag4
			end

			local function fn34(arg, arg2)
				local tbl23 = {}
				local tbl24 = {}
				local v13 = ipairs
				arg = arg or {}

				for _, v14 in v13(arg) do
					if type(v14) == "string" and not tbl23[v14] then
						tbl23[v14] = true
						tbl24[#tbl24 + 1] = v14
					end
				end

				local v14 = ipairs
				local tbl25 = arg2 or {}

				for _, v15 in v14(tbl25) do
					if type(v15) == "string" and not tbl23[v15] then
						tbl23[v15] = true
						tbl24[#tbl24 + 1] = v15
					end
				end

				return tbl24
			end

			local function fn35(arg)
				if not (isfile and readfile and isfile(arg)) then
					return nil
				end
				local v13 = readfile(arg)
				if type(v13) ~= "string" then
					return nil
				end
				local match = v13:match("^%s*(.-)%s*$")
				local str2 = match:sub(1, 1)
				local str3 = match:sub(-1)
				if not (str2 == "{" and str3 == "}" or str2 == "[" and str3 == "]") then
					return nil
				end
				return HttpService:JSONDecode(match)
			end

			local function fn36()
				if tbl21.ncloaded then
					return
				end
				tbl21.ncloaded = true
				local v13 = fn35(tbl21.ncfile)

				if type(v13) == "table" then
					if type(v13.Sword) == "table" and #v13.Sword > 0 then
						tbl21.swnames = v13.Sword
					end

					if type(v13.Explosion) == "table" and #v13.Explosion > 0 then
						tbl21.explnames = v13.Explosion
					end

					if type(v13.Emote) == "table" and #v13.Emote > 0 then
						tbl21.emonames = v13.Emote
					end
				end
			end

			local function fn37()
				if not writefile then
					return
				end
				writefile(tbl21.ncfile, HttpService:JSONEncode({ Sword = tbl21.swnames or {}, Explosion = tbl21.explnames or {}, Emote = tbl21.emonames or {} }))
			end

			local function fn38()
				local v13 = fn22()
				local flag2 = false

				if #v13 > 0 then
					tbl21.swnames = fn34(tbl21.swnames, v13)
					flag2 = true
				end

				local DataExplosions = fn21("DataExplosions")

				if #DataExplosions > 0 then
					tbl21.explnames = fn34(tbl21.explnames, DataExplosions)
					flag2 = true
				end

				local Emotes = fn21("Emotes")

				if #Emotes > 0 then
					tbl21.emonames = fn34(tbl21.emonames, Emotes)
					flag2 = true
				end

				if flag2 then
					fn37()
				end

				return flag2
			end

			local function fn39()
				if tbl21.warmed then
					return
				end
				fn36()
				v6 = v6 or fn13(ReplicatedStorage.Shared.Inventory)
				client = client or v6 and v6.Client
				v7 = v7 or fn13(ReplicatedStorage.Controllers.UI.ShopControllerAPI)
				v8 = v8 or fn13(ReplicatedStorage.Controllers.EmoteController)
				v9 = v9 or fn13(ReplicatedStorage.Shared.EmotesShared)
				v10 = v10 or fn13(ReplicatedStorage.Packages.Trove)
				tbl3.initsword()
				swords = tbl9.swords
				v11 = v11 or fn13(fn14(ReplicatedStorage, "Shared", "ReplicatedInstances", "SwordAccessories"))
				fn38()

				if localPlayer:GetAttribute("ShowSwordAccessory") == nil then
					localPlayer:SetAttribute("ShowSwordAccessory", not tbl21.noacc)
				end

				tbl21.warmed = true
			end

			local function fn40()
				if tbl21.injected then
					return
				end
				tbl21.injected = true

				if not fn16("Inventory") then
					tbl21.failed = true
					tbl3.logwev("uaInject", 5, "UnlockAll", "Inventory Replion unavailable - injection skipped")
					return
				end

				tbl21.failed = false

				if not tbl21.owned then
					fn28()
				end

				fn36()
				local flag2 = tbl21.swnames and #tbl21.swnames > 0 or tbl21.explnames and #tbl21.explnames > 0
				local flag3

				if flag2 then
					flag3 = flag2
				else
					flag3 = tbl21.emonames and #tbl21.emonames > 0
				end

				if not flag3 then
					fn38()
				end

				if not fn33({
					Sword = tbl21.swnames or fn22(),
					Explosion = tbl21.explnames or fn21("DataExplosions"),
				}) then
					tbl21.failed = true
					tbl3.logwev("uaInject", 5, "UnlockAll", "Replion has no _update or _set - nothing injected")
				end
			end

			local function fn41()if  v10 then local l= v10 .new();if l then return l;end;end;local h={};return{Add=function(l,l)h[#h+1]=l;return l;end,Clean=function()for l,l in ipairs(h)do if typeof(l)=="Instance"then l:Destroy();elseif typeof(l)=="thread"then task.cancel(l);elseif typeof(l)=="RBXScriptConnection"then l:Disconnect();elseif type(l)=="function"then l();end;end;table.clear(h);end};end

			local tbl23 = {
				Emote915 = { id = "rbxassetid://121746225545509", delay = 0.65 },
				Emote1017 = { id = "rbxassetid://122138306164149", delay = 0 },
				Emote1052 = { id = "rbxassetid://86553108866816", delay = 0 },
				Emote1167 = { id = "rbxassetid://78966882139691", delay = 0 },
				Emote1185 = { id = "rbxassetid://73110745626575", delay = 0 },
				Emote1217 = { id = "rbxassetid://107342460864353", delay = 3.3333333333333335 },
			}

			local function fn42(l,K,p)local E=K:FindFirstChild("HumanoidRootPart")or K.PrimaryPart;if not E then return false;end;local k=false;local a={};local d=nil;d=function(I,C)if a[I]then return;end;a[I]=true;if  tbl21 .activeemo~=l then return;end;local a=I:Clone();a.Parent=E;p:Add(a);local function I()if  tbl21 .activeemo==l and a.Parent then a:Play();end;end;if C and C>0 then p:Add(task.delay(C,I));else I();end;k=true;end;local function a(I)if typeof(I)~="Instance"then return;end;for C,U in ipairs(I:GetDescendants())do if U:IsA("Sound")then C=U:FindFirstAncestorWhichIsA("Folder");d(U,(tonumber(C and(C:GetAttribute("EnableFrame")))or 0)/60);end;end;end;K= fn13 ( ReplicatedStorage .Shared.ReplicatedInstances.EmoteVFX);if K and K.GetInstance then a(K:GetInstance(l));end;K= fn13 ( ReplicatedStorage .Shared.ReplicatedInstances.EmoteAccessories);if K and K.GetInstance then a(K:GetInstance(l));end;K= ReplicatedStorage :FindFirstChild("Misc");local d=K and(K:FindFirstChild("Emotes"));a(d and(d:FindFirstChild(l)));if not k then d= tbl23 [l];if d and  tbl21 .activeemo==l then local K=Instance.new("Sound");K.Name="RiseEmoteSound";K.SoundId=d.id;K.Looped=true;K.Volume=1;K.RollOffMode=Enum.RollOffMode.InverseTapered;K.RollOffMaxDistance=500;K.Parent=E;p:Add(K);if d.delay>0 then p:Add(task.delay(d.delay,function()if  tbl21 .activeemo==l and K.Parent then K:Play();end;end));else K:Play();end;k=true;end;end;return k;end
			local function fn44(h)local l=h:FindFirstChildOfClass("Humanoid");h=l and(l:FindFirstChildOfClass("Animator"));if not h then return 0;end;l=h:GetPlayingAnimationTracks();return type(l)=="table"and#l or 0;end
			local function fn45()local l= tbl3 .safehum();return l~=nil and l.MoveDirection.Magnitude>0.1;end
			local function fn46(l)local K= tbl3 .safechar();if not K then return;end;if  fn45 ()then return;end; tbl21 .activeemo=l; tbl21 .emostart= clock ();if  tbl21 .trove then  tbl21 .trove:Clean(); tbl21 .trove=nil;end;if  v9 and  v9 .Play and  v10 then local p= v10 .new(); tbl21 .trove=p;local E= fn44 (K); v9 :Play(K,p,l,true, Workspace :GetServerTimeNow());if  tbl21 .trove~=p or  tbl21 .activeemo~=l then return;end;if  fn44 (K)>E then return;end; tbl3 .logwev("emoteQuiet:"..tostring(l),5,("EmotesShared:Play returned without animating %s - using animation+sound fallback"):format(tostring(l)));p:Clean(); tbl21 .trove=nil;end;if  v8 and  v8 ._playAnimation then  v8 :_playAnimation(l);end;local p= fn41 (); tbl21 .trove=p;task.spawn(function() fn42 (l,K,p);end);end

			local function fn47(arg, arg2)
				local Inventory = fn16("Inventory")

				if Inventory and type(Inventory._set) == "function" then
					local set = Inventory._set
					local tbl24 = {}
					local v13 = tostring
					local n3 = tonumber(arg2) or 1
					local v14 = table.pack(v13(n3))
					tbl24[1] = "EquippedList"
					tbl24[2] = "Emote"

					do
						local values = table.pack(table.unpack(v14, 1, v14.n))
						table.move(values, 1, values.n, 3, tbl24)
					end

					set(Inventory, tbl24, { Name = arg, Id = fn19("Emote", arg) })
				end
			end

			local function fn48()
				if not writefile then
					return
				end
				writefile(tbl21.wheelfile, HttpService:JSONEncode(tbl21.wheel))
			end

			fn15 = function()
				if not writefile then
					return
				end
				writefile(tbl21.equipfile, HttpService:JSONEncode(tbl21.equip))
			end

			local function fn49()
				local v13 = fn35(tbl21.equipfile)

				if type(v13) == "table" then
					tbl21.equip = v13
				end
			end

			local function fn50()
				local v13 = fn35(tbl21.wheelfile)

				if type(v13) == "table" then
					tbl21.wheel = v13
				end

				for k, v14 in pairs(tbl21.wheel) do
					fn47(v14, k)
				end
			end

			local function fn51(arg, arg2)
				local n3 = tonumber(arg2) or 1
				fn47(arg, n3)
				tbl21.wheel[tostring(n3)] = arg
				fn48()
			end

			local function fn52(arg, arg2, arg3)
				local v13 = arg[arg2]
				if type(v13) ~= "function" then
					return nil
				end
				arg[arg2] = arg3
				if arg[arg2] == arg3 then
					return v13
				end
				return nil
			end

			tbl21.repmod = {}
			tbl21.repwarm = {}
			local function repasset(l,K)if  tbl21 .repmod[l]==nil then  tbl21 .repmod[l]= fn13 ( fn14 ( ReplicatedStorage ,"Shared","ReplicatedInstances",l))or false;end;local p= tbl21 .repmod[l];if not p or type(p.GetInstance)~="function"then return nil;end;return p:GetInstance(K)or nil;end
			tbl21.repasset = repasset
			tbl21.reptry = {}
			tbl21.prefetch = function(l,K)if not K or K==""then return;end;local p=l.."/"..K;if  tbl21 .repwarm[p]then return;end;local E=( tbl21 .reptry[p]or 0)+1;if E>2 then return;end; tbl21 .reptry[p]=E; tbl21 .repwarm[p]=true; tbl3 .bindt(task.spawn(function()if not  repasset (l,K)then  tbl21 .repwarm[p]=nil;end;end));end
			tbl21.finctrl = function()if  tbl21 .fcmod==nil then  tbl21 .fcmod= fn13 ( fn14 ( ReplicatedStorage ,"Controllers","FinishersController"))or false;end;return  tbl21 .fcmod or nil;end
			tbl21.finfor = function(l)if type(l)~="string"or l==""then return nil;end;local K= tbl21 .finctrl();if K and type(K._finishers)=="table"then return K._finishers[l]and l or nil;end;K= misc and( misc :FindFirstChild("DataFinishers"));if K and(K:FindFirstChild(l))then return l;end;return nil;end

			tbl21.finplayable = function(arg)
				local v13 = tbl21.finctrl()
				return v13 ~= nil and type(v13._finishers) == "table" and v13._finishers[arg] ~= nil
			end

			tbl21.realfin = function(arg)
				local replion = Replion and Replion.Client and Replion.Client:GetReplion("Inventory")
				replion = replion and replion:Get({ "Inventory", "Sword" })
				if type(replion) ~= "table" then
					return false
				end

				for _, v13 in pairs(replion) do
					if type(v13) == "table" and v13.Name == arg and v13.Finisher == true and v13.CreatedAt ~= nil then
						return true
					end
				end

				return false
			end

			tbl21.finequip = function(arg)
				local v13 = tbl21.finfor(arg)
				if not v13 then
					return nil
				end
				tbl21.prefetch("Finishers", v13)
				local Data = fn16("Data")

				if Data then
					local Unlocked = Data:Get("Finishers.Unlocked")
					local tbl24 = {}
					local flag2 = false

					if type(Unlocked) == "table" then
						local v14, v15, v16 = ipairs(Unlocked)
						local flag3 = false

						for _, v17 in v14, v15, v16 do
							tbl24[#tbl24 + 1] = v17

							if v17 == v13 then
								flag3 = true
							end
						end

						flag2 = flag3
					end

					if not flag2 and type(Data._set) == "function" then
						tbl24[#tbl24 + 1] = v13
						Data:_set({ "Finishers", "Unlocked" }, tbl24)
					end

					if type(Data._update) == "function" and Data:Get({ "Finishers", "Equipped", v13 }) ~= true then
						Data:_update({ "Finishers", "Equipped" }, { [v13] = true })
					end
				end

				tbl21.finreq = tbl21.finreq or {}

				if v7 and type(v7.RequestFinisherEquip) == "function" and not tbl21.finreq[v13] and tbl21.realfin(v13) then
					tbl21.finreq[v13] = true

					tbl3.bindt(task.spawn(function()
						v7:RequestFinisherEquip({ Name = v13 })
					end))
				end

				return v13
			end

			tbl21.finhookup = function()
				if tbl21.finhooked then
					return
				end
				local v13 = tbl21.finctrl()
				if not v13 or type(v13.PlayFinisher) ~= "function" then
					return
				end
				tbl21.finorig = fn52(v13, "PlayFinisher", function(l,K,...) tbl21 .finlast= clock ();return  tbl21 .finorig(l,K,...);end)
				tbl21.finhooked = tbl21.finorig ~= nil
			end

			tbl21.findur = function(arg)
				local dataFinishers = misc and misc:FindFirstChild("DataFinishers")
				dataFinishers = dataFinishers and dataFinishers:FindFirstChild(arg)
				local attribute = dataFinishers and dataFinishers:GetAttribute("Duration")
				return type(attribute) == "number" and attribute or 6
			end

			tbl21.finhide = function(arg, arg2)
				if not arg then
					return
				end

				for _, descendant in ipairs(arg:GetDescendants()) do
					if descendant:IsA("BasePart") or descendant:IsA("Decal") then
						descendant.LocalTransparencyModifier = arg2 and 1 or 0
					elseif descendant:IsA("ParticleEmitter") or descendant:IsA("Trail") or descendant:IsA("Beam") or descendant:IsA("BillboardGui") then
						if arg2 then
							if descendant.Enabled then
								descendant:SetAttribute("__uaEmit", true)
								descendant.Enabled = false
							end
						elseif descendant:GetAttribute("__uaEmit") then
							descendant:SetAttribute("__uaEmit", nil)
							descendant.Enabled = true
						end
					end
				end
			end

			tbl21.finclone = function(h)local l=h.Archivable;h.Archivable=true;local K=h:Clone();h.Archivable=l;if not K then return nil;end;l=K:FindFirstChildOfClass("Humanoid");if not(l and(K:FindFirstChild("HumanoidRootPart")))then K:Destroy();return nil;end;for h,h in ipairs(K:GetDescendants())do if h:IsA("BaseScript")then h:Destroy();elseif h:IsA("BasePart")then h.CanCollide=false;h.CanQuery=false;h.Massless=true;h.LocalTransparencyModifier=0;if(h.Parent==K and h.Name~="HumanoidRootPart"or h.Name=="Handle"and(h.Parent:IsA("Accessory")))and h.Transparency>=1 then h.Transparency=0;end;elseif h:IsA("Decal")then h.Transparency=0;end;end;if l.MaxHealth<=0 then l.MaxHealth=100;end;l.Health=l.MaxHealth;l.DisplayDistanceType=Enum.HumanoidDisplayDistanceType.None;if not l:FindFirstChildOfClass("Animator")then Instance.new("Animator").Parent=l;end;K:SetAttribute("Dead",nil);return K;end

			tbl21.winfin = function(arg)
				if tbl21.finbusy then
					return
				end

				if not (tbl10.unlockall or tbl10.autoload or tbl10.swskin) then
					return
				end
				local v13 = tbl21.finfor(tbl21.cursword())
				if not v13 then
					return
				end
				local v14 = tbl21.findur(v13)
				local v15 = tbl3.safechar()
				local humanoidRootPart = v15 and v15:FindFirstChild("HumanoidRootPart")
				local flag2 = tbl21.prey ~= nil and tbl21.preyfor == arg

				if not (humanoidRootPart and arg and (flag2 or arg.Parent)) then
					flag2 = flag2 and tbl21.dropprey

					if flag2 then
						tbl21.dropprey()
					end

					return
				end

				tbl21.finhookup()
				tbl21.finbusy = true
				local v16 = clock()
				local prey

				if flag2 then
					prey = tbl21.prey
					tbl21.prey = nil
					tbl21.preyfor = nil
				else
					prey = tbl21.finclone(arg)
				end

				if not prey then
					tbl21.finbusy = false
					tbl3.notif("Finisher", "Couldn't copy your opponent, so the finisher was skipped.", 5)
					return
				end

				prey.Parent = Workspace

				tbl3.bindt(task.delay(0.1, function()
					local v17 = tbl21.finctrl()

					if (tbl21.finlast or 0) > v16 or not v17 or not v15.Parent then
						prey:Destroy()
						tbl21.finbusy = false
						return
					end

					if not tbl21.repasset("Finishers", v13) then
						prey:Destroy()
						tbl21.finbusy = false
						tbl3.notif("Finisher", ("Couldn't load the %s finisher."):format(v13), 5)
						return
					end

					if clock() - v16 > 3 then
						prey:Destroy()
						tbl21.finbusy = false
						tbl3.notif("Finisher", ("The %s finisher loaded too late. The next win should play it."):format(v13), 6)
						return
					end

					local v18 = tbl21.finclone(v15)

					if not v18 then
						prey:Destroy()
						tbl21.finbusy = false
						tbl3.notif("Finisher", "Couldn't copy your character, so the finisher was skipped.", 5)
						return
					end

					if not tbl21.finplayable(v13) then
						prey:Destroy()
						v18:Destroy()
						tbl21.finbusy = false
						tbl3.notif("Finisher", ("The %s finisher isn't loaded yet."):format(v13), 5)
						return
					end

					v18.Parent = Workspace
					tbl21.finhide(v15, true)
					local finshow = nil

					finshow = function()
						if tbl21.finshow ~= finshow then
							return
						end
						tbl21.finshow = nil
						prey:Destroy()
						v18:Destroy()
						tbl21.finhide(v15, false)
						tbl21.finbusy = false
					end

					tbl21.finshow = finshow
					tbl3.bindt(task.delay(v14 + 2, finshow))
					local position = humanoidRootPart.Position
					local lookVector = humanoidRootPart.CFrame.LookVector
					local getServerTimeNow = Workspace.GetServerTimeNow
					v17:PlayFinisher(v13, v18, prey, CFrame.new(position, position + Vector3.new(lookVector.X, 0, lookVector.Z)), getServerTimeNow(Workspace))

					if setthreadidentity and tbl3.baseident then
						setthreadidentity(tbl3.baseident)
					end
				end))
			end

			local function fn53()
				if tbl21.hooked then
					return
				end
				local v13 = nil

				for _, v14 in ipairs({
					{ "Common", "Utils", "Utilities", "RewardInfo" },
					{ "Common", "Utils", "RewardInfo" },
					{ "Common", "RewardInfo" },
				}) do
					v13 = fn13(fn14(ReplicatedStorage, table.unpack(v14)))
					if not (type(v13) == "table" and type(rawget(v13, "playerOwnsItem")) == "function") then
						v13 = nil
						continue
					end
					break
				end

				if not v13 then
					for _, descendant in ipairs(ReplicatedStorage:GetDescendants()) do
						if descendant:IsA("ModuleScript") and descendant.Name == "RewardInfo" then
							local v14 = fn13(descendant)
							if type(v14) == "table" and type(rawget(v14, "playerOwnsItem")) == "function" then
								v13 = v14
								break
							end
						end
					end
				end

				if v13 and not tbl21.rwdorig then
					tbl21.rwdmod = v13
					tbl21.rwdorig = fn52(v13, "playerOwnsItem", function(l,K,...)if  tbl10 .unlockall and type(K)=="table"and(l==nil or l== localPlayer )then local p=K.Type;if p=="Sword"or p=="Explosion"or p=="Finisher"or p=="SwordAccessory"then return true;end;end;return  tbl21 .rwdorig(l,K,...);end)

					if not tbl21.rwdorig then
						local tbl24 = {}

						for k, v14 in pairs(v13) do
							tbl24[#tbl24 + 1] = tostring(k) .. (type(v14) == "function" and "()" or "")
						end

						table.sort(tbl24)
						tbl3.logwev("uaHookReward", 10, "UnlockAll", "failed to hook RewardInfo.playerOwnsItem; module has: " .. table.concat(tbl24, ", "))
					end
				end

				if v7 then
					if not tbl21.seteqorig then
						tbl21.seteqorig = fn52(v7, "SetEquipped", function(l,K,p)if not  tbl10 .unlockall then return  tbl21 .seteqorig(l,K,p);end;local E,k;if type(K)=="table"then E,k=K.ItemType or K.Type,K.Name;else k,E=( fn20 (p,K)),K;end;if E=="Ability"or E=="Emote"or not E or not k then return  tbl21 .seteqorig(l,K,p);end;if  fn29 (E,k)then return  tbl21 .seteqorig(l,K,p);end; fn27 (E,k);return true;end)

						if not tbl21.seteqorig then
							tbl3.logwev("uaHookSetEq", 10, "UnlockAll", "failed to hook ShopAPI.SetEquipped")
						end
					end

					if not tbl21.accorig then
						tbl21.accorig = fn52(v7, "ToggleSwordAccessory", function(l)if not  tbl10 .unlockall then return  tbl21 .accorig(l);end; tbl21 .noacc=not  tbl21 .noacc; tbl21 .equip.NoAcc= tbl21 .noacc;if  fn15 then  fn15 ();end; tbl21 .applyacc();return true;end)
					end
				end

				tbl21.finhookup()
				tbl21.hooked = true
			end

			local function arm()
				fn39()
				fn53()
				fn30()
			end

			tbl21.unhook = function()
				tbl10.unlockall = false
				tbl10.forceemo = false
				tbl10.emospam = false
				tbl10.emoteonly = false
				tbl10.autoload = false

				if tbl21.rwdmod and tbl21.rwdorig then
					tbl21.rwdmod.playerOwnsItem = tbl21.rwdorig
				end

				if v7 and tbl21.seteqorig then
					v7.SetEquipped = tbl21.seteqorig
				end

				if v7 and tbl21.accorig then
					v7.ToggleSwordAccessory = tbl21.accorig
				end

				if v8 and tbl21.emoplayorig then
					v8.Play = tbl21.emoplayorig
				end

				if v8 and tbl21.emostoporig then
					v8.Stop = tbl21.emostoporig
				end

				if tbl21.explmod and tbl21.explorig then
					tbl21.explmod.PlayExplosion = tbl21.explorig
				end

				if tbl21.fcmod and tbl21.finorig then
					tbl21.fcmod.PlayFinisher = tbl21.finorig
				end

				tbl21.rwdorig = nil
				tbl21.seteqorig = nil
				tbl21.accorig = nil
				tbl21.emoplayorig = nil
				tbl21.emostoporig = nil
				tbl21.explorig = nil
				tbl21.finorig = nil
				tbl21.hooked = false
				tbl21.explhooked = false
				tbl21.finhooked = false
				tbl21.autoran = false
				tbl21.boot = false

				for _, offconn in ipairs(tbl21.offconns) do
					offconn:Enable()
				end

				if tbl21.finshow then
					tbl21.finshow()
				end

				if tbl21.dropprey then
					tbl21.dropprey()
				end

				if tbl21.loaderblur then
					tbl21.loaderblur:Destroy()
					tbl21.loaderblur = nil
				end

				if tbl21.loadergui then
					tbl21.loadergui:Destroy()
					tbl21.loadergui = nil
				end

				tbl21.finhide(tbl3.safechar(), false)
			end

			tbl21.arm = arm
			unhook = tbl21.unhook

			local function fn54(arg)
				for _, v13 in ipairs({ "Activated", "MouseButton1Click" }) do
					local v14 = getconnections(arg[v13])

					if v14 then
						for _, v15 in ipairs(v14) do
							if not v15.ForeignState and v15.Function and islclosure(v15.Function) then
								local v16 = getupvalues(v15.Function)
								if type(v16) ~= "table" then
									continue
								end

								for _, v17 in pairs(v16) do
									if type(v17) == "table" and (rawget(v17, "_virtualItems") ~= nil or rawget(v17, "_selectedItem") ~= nil) then
										return v17
									end
								end
							end
						end
					end
				end
			end

			local function fn55(arg)
				local tbl24 = {}
				if not getconnections then
					return tbl24
				end

				for _, v13 in ipairs({ "Activated", "MouseButton1Click" }) do
					local v14 = getconnections(arg[v13])

					if v14 then
						for _, v15 in ipairs(v14) do
							if not v15.ForeignState and v15.Function then
								tbl24[#tbl24 + 1] = v15.Function
								v15:Disable()
								tbl21.offconns[#tbl21.offconns + 1] = v15
							end
						end
					end
				end

				return tbl24
			end

			local function fn56()
				local flag2 = tbl10.unlockall == true

				for _, offconn in ipairs(tbl21.offconns) do
					if flag2 then
						offconn:Disable()
					else
						offconn:Enable()
					end
				end
			end

			local function fn57(arg)
				if not (arg and arg.Select) then
					return
				end

				local function fn58()
					local selectedItem = arg._selectedItem
					if not selectedItem then
						return
					end
					arg:Select(table.clone(selectedItem), true)
				end

				fn58()
				task.defer(fn58)
				task.delay(0.1, fn58)
			end

			local function fn58()
				if tbl21.guihooked or tbl21.guibusy then
					return
				end
				tbl21.guibusy = true

				tbl3.bindt(task.spawn(function()
					local playerGui = localPlayer:WaitForChild("PlayerGui", 20)
					local shop = playerGui and playerGui:WaitForChild("Shop", 20)
					shop = shop and shop:WaitForChild("Holder", 20)
					local infoBG = shop and shop:WaitForChild("InfoBG", 20)
					local buyButton = infoBG and infoBG:WaitForChild("BuyButton", 20)

					if buyButton and getconnections then
						local n3 = clock() + 10

						while clock() < n3 do
							local v13, v14, v15 = ipairs(getconnections(buyButton.Activated) or {})
							local n4 = 0

							for _, v16 in v13, v14, v15 do
								if not v16.ForeignState and v16.Function then
									n4 += 1
								end
							end

							if not (n4 > 0) then
								task.wait(0.2)
								continue
							end
							break
						end
					end

					tbl21.guibusy = false
					if not buyButton then
						tbl3.logwev("uaHookGui", 30, "UnlockAll", "Shop.Holder.InfoBG.BuyButton never appeared - shop hooks skipped")
						return
					end
					tbl21.guihooked = true
					local v13 = fn54(buyButton)
					local v14 = fn55(buyButton)

					local function fn59()
						for _, v15 in ipairs(v14) do
							v15()
						end
					end

					tbl3.bind(buyButton.Activated:Connect(function()if not  tbl10 .unlockall then return;end; v13 = v13 or( fn54 ( buyButton ));local l= v13 and  v13 ._selectedItem;if not l then  fn59 ();return;end;local K=type(l.ItemInfo)=="table"and l.ItemInfo or nil;local p,E=l.type or l.Type or K and(K.ItemType or K.Type),l.name or l.Name or K and K.Name;if p=="Ability"or p=="AbilityFreeTrial"then  fn59 ();return;end;if p=="Sword"or p=="Explosion"then if  fn29 (p,E)then  fn59 ();return;end; fn27 (p,E);elseif p=="Emote"then  fn46 (E);else  fn59 ();return;end; fn57 ( v13 );end))
					local equips = infoBG and infoBG:FindFirstChild("Equips")
					local equipAccessory = equips and equips:FindFirstChild("EquipAccessory")

					if equipAccessory then
						fn55(equipAccessory)
						tbl3.bind(equipAccessory.Activated:Connect(function()if not  tbl10 .unlockall then return;end;if  v7 and  v7 .ToggleSwordAccessory then  v7 :ToggleSwordAccessory();end; fn57 ( v13 );end))
					end

					local tbl24 = { Sword = "SwordSkins", Explosion = "ExplosionSkins", Emote = "Emotes" }

					local function fn60()
						v13 = v13 or fn54(buyButton)
						local selectedItem = v13 and v13._selectedItem
						if not selectedItem then
							return nil
						end
						local itemInfo = type(selectedItem.ItemInfo) == "table" and selectedItem.ItemInfo or nil
						local type_ = selectedItem.type or selectedItem.Type or itemInfo and (itemInfo.ItemType or itemInfo.Type)
						local name = selectedItem.name or selectedItem.Name or itemInfo and itemInfo.Name
						return type_, name, selectedItem.key or type_ and name and fn19(type_, name) or nil
					end

					equips = equips and equips:FindFirstChild("Finisher")

					if equips and equips:IsA("GuiButton") then
						fn55(equips)
						tbl3.bind(equips.Activated:Connect(function()if not  tbl10 .unlockall then return;end;local l,K= fn60 ();if l~="Sword"or not K or not  tbl21 .finfor(K)then return;end;l= fn16 ("Data");local p= Replion and  Replion .None;if not(l and p and type(l._update)=="function")then return;end;local E=l:Get({"Finishers","Equipped",K})==true;l:_update({"Finishers","Equipped"},{[K]=E and p or true});if not E then  tbl21 .finequip(K);end; fn57 ( v13 );end))
					end

					shop = shop and shop:FindFirstChild("Favorite")

					if shop and shop:IsA("GuiButton") then
						fn55(shop)
						tbl3.bind(shop.Activated:Connect(function()if not  tbl10 .unlockall then return;end;local l,K= fn60 ();local p=l and  tbl24 [l];if not(K and p)then return;end;l= fn16 ("Data");local E= Replion and  Replion .None;if not(l and E)then return;end;l:_update({p,"Favorites"},{[K]=l:Get({p,"Favorites",K})==true and E or true}); fn57 ( v13 );end))
					end

					infoBG = infoBG and infoBG:FindFirstChild("Delete")

					if infoBG and infoBG:IsA("GuiButton") then
						fn55(infoBG)
						tbl3.bind(infoBG.Activated:Connect(function()if not  tbl10 .unlockall then return;end;local l,K,p= fn60 ();if not(l and K and p and  tbl24 [l])then return;end;if  v13 and type( v13 ._canDelete)=="function"then if not  v13 ._canDelete( v13 ,l,p)then  tbl3 .notif("Unlock All","You can't delete that item.",4);return;end;end;local E= fn16 ("Inventory");local k= Replion and  Replion .None;if not(E and k)then return;end;E:_update({"Inventory",l},{[p]=k});if  tbl21 .owned and  tbl21 .owned[l]then  tbl21 .owned[l][K]=nil;end;if  tbl21 .equip[l]==K then  tbl21 .equip[l]=nil;if  fn15 then  fn15 ();end;end;if l=="Sword"and  tbl10 .swname==K then  tbl10 .swskin=false; tbl10 .swname="";elseif l=="Explosion"and  tbl21 .explname==K then  tbl21 .explname=nil;end; fn57 ( v13 );end))
					end

					fn56()
					playerGui = playerGui and playerGui:WaitForChild("EmoteWheel", 20)
					playerGui = playerGui and playerGui:WaitForChild("List", 20)
					playerGui = playerGui and playerGui:WaitForChild("Content", 20)
					playerGui = playerGui and playerGui:WaitForChild("Folder", 20)

					if playerGui then
						local function fn61(arg)
							local v15 = getconnections(arg.Activated)
							if not v15 then
								return
							end

							for _, v16 in ipairs(v15) do
								if not v16.ForeignState and v16.Function and islclosure(v16.Function) then
									local v17 = getupvalues(v16.Function)

									if type(v17) == "table" then
										local n3 = 0

										for k in pairs(v17) do
											if type(k) == "number" and k > n3 then
												n3 = k
											end
										end

										local v18 = nil
										local v19 = nil

										for i = 1, n3 do
											local v20 = v17[i]

											if type(v20) == "string" and not v18 then
												v18 = v20
											end

											if type(v20) == "table" and (rawget(v20, "selected") ~= nil or rawget(v20, "page") ~= nil) then
												v19 = v20
											end
										end

										if v18 and v19 then
											return v18, v19
										end
									end
								end
							end
						end

						local function fn62(child)
							if not child:IsA("GuiButton") or child:GetAttribute("__uaHooked") then
								return
							end
							child:SetAttribute("__uaHooked", true)
							tbl3.bind(child.Activated:Connect(function()if not( tbl10 .unlockall or  tbl10 .emoteonly or  tbl10 .autoload)then return;end;local l,K= fn61 ( child );if not(l and K)then return;end;local p=(tonumber(K.selected)or 1)+((tonumber(K.page)or 1)-1)*8; fn51 ( fn20 (l),p);end))
						end

						for _, child in ipairs(playerGui:GetChildren()) do
							fn62(child)
						end

						tbl3.bind(playerGui.ChildAdded:Connect(fn62))
					end
				end))
			end

			local function fn59()
				if tbl21.boot then
					return
				end
				tbl21.boot = true
				fn12()
				fn39()
				task.wait()
				fn53()
				task.wait()
				fn58()
				fn56()
			end

			local function fn60()
				local tbl24 = {
					done = false,
					finish = function()
					end,
					setStatus = function()
					end,
				}

				local screenGui = Instance.new("ScreenGui")
				screenGui.Name = "\0RiseUnlock"
				screenGui.IgnoreGuiInset = true
				screenGui.ResetOnSpawn = false
				screenGui.DisplayOrder = 999999999
				screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
				screenGui.Parent = fn6 and fn6() or CoreGui
				local frame = Instance.new("Frame")
				frame.Size = UDim2.fromScale(1, 1)
				frame.BackgroundColor3 = Color3.fromRGB(2, 12, 20)
				frame.BackgroundTransparency = 1
				frame.BorderSizePixel = 0
				frame.Parent = screenGui
				local blurEffect = Instance.new("BlurEffect")
				blurEffect.Size = 0
				blurEffect.Parent = Lighting
				local frame2 = Instance.new("Frame")
				frame2.AnchorPoint = Vector2.new(0.5, 0.5)
				frame2.Position = UDim2.fromScale(0.5, 0.5)
				frame2.Size = UDim2.fromOffset(252, 172)
				frame2.BackgroundColor3 = color
				frame2.BackgroundTransparency = 1
				frame2.BorderSizePixel = 0
				frame2.Parent = screenGui
				tbl3.corner(frame2, 20)
				local uiGradient = Instance.new("UIGradient")
				uiGradient.Rotation = 90
				local color4 = Color3.fromRGB
				uiGradient.Color = ColorSequence.new(Color3.fromRGB(16, 56, 88), color4(3, 24, 42))
				uiGradient.Parent = frame2
				local uiStroke = Instance.new("UIStroke")
				uiStroke.Color = Color3.fromRGB(255, 255, 255)
				uiStroke.Thickness = 1.5
				uiStroke.Transparency = 1
				uiStroke.Parent = frame2
				local frame3 = Instance.new("Frame")
				frame3.AnchorPoint = Vector2.new(0.5, 0)
				frame3.Position = UDim2.new(0.5, 0, 0, 28)
				frame3.Size = UDim2.fromOffset(46, 46)
				frame3.BackgroundTransparency = 1
				frame3.Parent = frame2
				local tbl25 = {}
				local n3 = 12

				for i = 1, 12 do
					local frame4 = Instance.new("Frame")
					frame4.AnchorPoint = Vector2.new(0.5, 0.5)
					frame4.Size = UDim2.fromOffset(4, 12)
					frame4.BackgroundColor3 = accent
					frame4.BackgroundTransparency = 1
					frame4.BorderSizePixel = 0
					local v13 = rad((i - 1) * 360 / n3)
					frame4.Position = UDim2.new(0.5, sin(v13) * 15, 0.5, -cos(v13) * 15)
					frame4.Rotation = (i - 1) * 360 / n3
					local uiCorner = Instance.new("UICorner")
					uiCorner.CornerRadius = UDim.new(1, 0)
					uiCorner.Parent = frame4
					frame4.Parent = frame3
					tbl25[i] = frame4
				end

				local textLabel = Instance.new("TextLabel")
				textLabel.AnchorPoint = Vector2.new(0.5, 0)
				textLabel.Position = UDim2.new(0.5, 0, 0, 92)
				textLabel.Size = UDim2.new(1, -24, 0, 22)
				textLabel.BackgroundTransparency = 1
				textLabel.Font = Enum.Font.GothamBold
				textLabel.TextSize = 16
				textLabel.TextColor3 = color2
				textLabel.TextTransparency = 1
				textLabel.Text = "Unlock All"
				textLabel.Parent = frame2
				local textLabel2 = Instance.new("TextLabel")
				textLabel2.AnchorPoint = Vector2.new(0.5, 0)
				textLabel2.Position = UDim2.new(0.5, 0, 0, 118)
				textLabel2.Size = UDim2.new(1, -28, 0, 40)
				textLabel2.BackgroundTransparency = 1
				textLabel2.Font = Enum.Font.Gotham
				textLabel2.TextSize = 12
				textLabel2.TextColor3 = color3
				textLabel2.TextTransparency = 1
				textLabel2.TextWrapped = true
				textLabel2.Text = "Unlocking swords, explosions & emotes..."
				textLabel2.Parent = frame2
				local tweenInfo = TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
				TweenService:Create(frame, tweenInfo, { BackgroundTransparency = 0.45 }):Play()
				TweenService:Create(frame2, tweenInfo, { BackgroundTransparency = 0.2 }):Play()
				TweenService:Create(uiStroke, tweenInfo, { Transparency = 0.55 }):Play()
				TweenService:Create(textLabel, tweenInfo, { TextTransparency = 0 }):Play()
				TweenService:Create(textLabel2, tweenInfo, { TextTransparency = 0.15 }):Play()
				TweenService:Create(blurEffect, tweenInfo, { Size = 16 }):Play()
				tbl21.loadergui = screenGui
				tbl21.loaderblur = blurEffect
				local v13 = clock()
				local v14 = tbl3.bind(RunService.RenderStepped:Connect(function()local l= clock ()*1.15%1;for K=1, n3 ,1 do local p=((K-1)/ n3 -l)%1; tbl25 [K].BackgroundTransparency=0.1+0.82*p;end;end))

				tbl24.setStatus = function(text)
					textLabel2.Text = text
				end

				tbl24.finish = function()
					if tbl24.done then
						return
					end
					tbl24.done = true
					local n4 = 0.6 - clock() - v13

					if n4 > 0 then
						task.wait(n4)
					end

					local tweenInfo2 = TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
					TweenService:Create(frame, tweenInfo2, { BackgroundTransparency = 1 }):Play()
					TweenService:Create(frame2, tweenInfo2, { BackgroundTransparency = 1, Position = UDim2.fromScale(0.5, 0.54) }):Play()
					TweenService:Create(uiStroke, tweenInfo2, { Transparency = 1 }):Play()
					TweenService:Create(textLabel, tweenInfo2, { TextTransparency = 1 }):Play()
					TweenService:Create(textLabel2, tweenInfo2, { TextTransparency = 1 }):Play()
					TweenService:Create(blurEffect, tweenInfo2, { Size = 0 }):Play()
					task.wait(0.45)

					if v14 then
						v14:Disconnect()
					end

					blurEffect:Destroy()
					screenGui:Destroy()
				end

				return tbl24
			end

			fn9 = function() tbl10 .unlockall=true; tbl21 .everunlocked=true; tbl21 .uagen=( tbl21 .uagen or 0)+1;local l= tbl21 .uagen; fn56 ();local K= fn60 ();local p=false;local E=nil;E=function(k,a)if p then return;end;p=true;if setthreadidentity and  tbl3 .baseident then setthreadidentity( tbl3 .baseident);end;K.finish(); tbl3 .notif("Unlock All",k,a or 5);end;local function k()if p then return;end;p=true;if setthreadidentity and  tbl3 .baseident then setthreadidentity( tbl3 .baseident);end;K.finish();end; tbl3 .bindt(task.delay(20,function()E("Done. If something is missing, rejoin and turn it on again.",6);end)); tbl3 .bindt(task.spawn(function() fn12 ();task.wait();if  tbl21 .uagen~=l then return k();end; fn59 ();if  tbl21 .uagen~=l then return k();end;K.setStatus("Loading swords and explosions...");for p=1,3,1 do  tbl21 .injected=false; fn40 ();if not  tbl21 .failed or  tbl21 .uagen~=l then break;end;if p<3 then K.setStatus("Retrying... ("..p.."/3)"); fn12 ();task.wait(0.8);end;end;task.wait();if  tbl21 .uagen~=l then return k();end; fn49 ();local p={"Sword","Explosion"};for a,d in ipairs(p)do a= tbl21 .equip[d];if type(a)=="string"and a~=""then  fn27 (d,a,true);end;if  tbl21 .uagen~=l then return k();end;end;if  tbl21 .equip.NoAcc then  tbl21 .noacc=true; tbl21 .applyacc();end;K.setStatus("Loading emotes..."); tbl3 .bindt(task.delay(3,function()if  tbl21 .uagen~=l then return;end; fn50 ();end));E("Done. Open your inventory and equip anything.",6);end));end

			fn10 = function()
				tbl10.unlockall = false
				tbl21.uagen = (tbl21.uagen or 0) + 1
				tbl21.explname = nil
				tbl21.injected = false
				tbl21.failed = false

				if not tbl10.autoload and tbl21.skinmine then
					tbl10.swskin = false
					tbl10.swname = ""
					tbl21.skinmine = false
				end

				fn56()
				tbl3.notif("Unlock All", "Off. Items already unlocked stay until you rejoin.", 4)
			end

			fn11 = function(l) tbl10 .autoload=true;if  tbl10 .unlockall or  tbl21 .autoran then return;end; tbl21 .autoran=true; tbl3 .bindt(task.spawn(function() fn12 ();task.wait(); fn39 (); fn53 (); fn58 (); fn30 (); fn49 ();local K={"Sword","Explosion"};for p,E in ipairs(K)do p= tbl21 .equip[E];if type(p)=="string"and p~=""then  fn27 (E,p,true);end;end;if  tbl21 .equip.NoAcc then  tbl21 .noacc=true; tbl21 .applyacc();end; fn50 ();for K,K in pairs( tbl21 .wheel)do if type(K)=="string"and K~=""then  fn26 ("Emote",K);end;end;if setthreadidentity and  tbl3 .baseident then setthreadidentity( tbl3 .baseident);end;if l then  tbl3 .notif("Auto Load Last Loadout","Your last sword, explosion and emotes are back.",4);end;end));end

			local function fn61()
				tbl10.autoload = false
				tbl21.autoran = false

				if not tbl10.unlockall and tbl21.skinmine then
					tbl10.swskin = false
					tbl10.swname = ""
					tbl21.skinmine = false
					tbl21.explname = nil
				end
			end

			local function fn62(arg, arg2)
				if type(arg) ~= "string" or arg == "" then
					return nil
				end
				local str2 = arg:lower()

				for _, v13 in ipairs(arg2) do
					if v13:lower() == str2 then
						return v13
					end
				end

				for _, v13 in ipairs(arg2) do
					if v13:lower():find(str2, 1, true) then
						return v13
					end
				end

				return nil
			end

			tbl3.skinsword = function(arg)
				fn12()
				fn39()
				fn53()
				fn30()
				local v13 = tbl3.initsword()
				if not v13 then
					tbl3.notif("Skins", "Swords aren't ready yet. Try again in a second.", 5)
					return
				end
				local tbl24 = {}
				local collection = v13:GetCollection()

				if type(collection) == "table" then
					for k in pairs(collection) do
						tbl24[#tbl24 + 1] = k
					end
				end

				local v14 = fn62(arg, tbl24)

				if not v14 then
					if v13:GetSword(arg) then
						v14 = arg
					end
				end

				if not v14 or v14 == "" then
					tbl3.notif("Skins", ("No sword called \"%s\". %d swords loaded."):format(tostring(arg), #tbl24), 6)
					return
				end

				if not tbl3.safechar() then
					tbl3.notif("Skins", "Join a round first.", 5)
					return
				end
				tbl10.swskin = true
				tbl10.swname = v14
				tbl21.skinmine = false
				tbl3.hookslash()
				tbl3.skinloop()
				tbl3.setswattr(v14)

				if tbl9.swctrl and tbl9.swctrl.SetSword then
					tbl9.swctrl:SetSword(v14)
				end

				local v15 = tbl3.applysword()
				fn26("Sword", v14)
				fn25("Sword", v14)
				tbl21.ensureeq("Sword", v14)
				tbl21.finequip(v14)
				tbl21.equip.Sword = v14

				if fn15 then
					fn15()
				end

				if setthreadidentity and tbl3.baseident then
					setthreadidentity(tbl3.baseident)
				end

				tbl3.bindt(task.delay(0.4, function()
					local v16 = tbl3.safechar()

					if v16 and v16:FindFirstChild(v14) then
						tbl3.notif("Skins", ("Equipped %s."):format(v14), 3)
					elseif not v15 then
						tbl3.notif("Skins", ("Couldn't equip %s. The game may not have sent the model."):format(v14), 7)
					else
						tbl3.notif("Skins", ("%s didn't show up. The game blocked it."):format(v14), 6)
					end
				end))
			end

			tbl3.applyexpl = function(arg)
				fn12()
				fn39()
				fn53()
				fn30()
				local DataExplosions = fn21("DataExplosions")
				local v13 = fn62(arg, DataExplosions)
				if not v13 or v13 == "" then
					tbl3.notif("Skins", ("No explosion called \"%s\". %d explosions loaded."):format(tostring(arg), #DataExplosions), 6)
					return
				end
				fn27("Explosion", v13)

				if setthreadidentity and tbl3.baseident then
					setthreadidentity(tbl3.baseident)
				end

				tbl3.bindt(task.spawn(function()
					tbl3.notif("Skins", repasset("Explosions", v13) and ("Explosion set to %s."):format(v13) or ("%s is set, but the game didn't send it. It may not show."):format(v13), 5)
				end))
			end

			tbl3.emoteonly = function(arg)
				if not arg then
					return
				end
				fn12()
				fn39()
				fn53()
				fn58()
				fn30()
				fn50()
				local n3 = 0

				for _, v13 in pairs(tbl21.wheel) do
					if type(v13) == "string" and v13 ~= "" then
						fn26("Emote", v13)
						n3 += 1
					end
				end

				if setthreadidentity and tbl3.baseident then
					setthreadidentity(tbl3.baseident)
				end

				tbl3.notif("Skins", n3 > 0 and ("%d emotes ready. Open your emote wheel."):format(n3) or "No emotes saved yet.", 4)
			end

			toggles.unlockall:OnChanged(function(arg)
				if arg then
					fn9()
				else
					fn10()
				end

				tbl3.qsave()
			end)

			toggles.equipautoload:OnChanged(function(arg)
				if arg then
					fn11(true)
				else
					fn61()
				end

				tbl3.qsave()
			end)

			local function fn63()return  max (0.5-( clamp ( tbl10 .emospd or 5,1,10)-1)*0.04888888888888889,0.2);end

			local function fn64()
				if tbl21.spamconn then
					tbl21.spamconn:Disconnect()
					tbl21.spamconn = nil
				end
			end

			local function fn65()
				fn64()
				tbl21.spamlast = 0
				tbl21.spamconn = tbl3.bind(RunService.Heartbeat:Connect(function()if not  tbl10 .emospam or not  tbl21 .spamemo then return;end;if not  tbl3 .isalive()then return;end;local l= tbl3 .safehum();if l and l.MoveDirection.Magnitude>0.1 then if  tbl21 .trove then  tbl21 .trove:Clean(); tbl21 .trove=nil;end; tbl21 .activeemo=nil;return;end;local l= clock ();if l-( tbl21 .spamlast or 0)< fn63 ()then return;end; tbl21 .spamlast=l; fn46 ( tbl21 .spamemo);end))
			end

			toggles.forceemote:OnChanged(function(forceemo)
				tbl10.forceemo = forceemo

				if forceemo then
					arm()
				end

				tbl3.qsave()
			end)

			toggles.emotespam:OnChanged(function(emospam)
				tbl10.emospam = emospam

				if emospam then
					arm()
					fn65()
				else
					fn64()
				end

				tbl3.qsave()
			end)

			options.emotespamspeed:OnChanged(function(emospd)
				tbl10.emospd = emospd
				tbl3.qsave()
			end)

			toggles.emoteonspawn:OnChanged(function(emospawn)
				tbl10.emospawn = emospawn

				if emospawn then
					arm()
				end

				tbl3.qsave()
			end)

			tbl10.emospawn = toggles.emoteonspawn.Value

			tbl3.bind(localPlayer.CharacterAdded:Connect(function()
				if not tbl10.emospawn then
					return
				end
				task.wait(1)
				local n1 = tbl21.wheel and (tbl21.wheel["1"] or tbl21.wheel[1]) or tbl21.spamemo

				if type(n1) == "string" and n1 ~= "" then
					fn46(n1)
				end
			end))

			if alive then
				local v13 = tbl3.safechar()
				tbl21.lost = not (v13 and v13.Parent == alive)
				local function fn66(l)local K= Players :GetPlayerFromCharacter(l);if not K or K== localPlayer then return false;end;if l:GetAttribute("IsDoppelganger")then return false;end;if l:GetAttribute("IsEncryptedClone")then return false;end;if l:GetAttribute("Dead")then return false;end;return true;end
				local function dropprey()if  tbl21 .prey then  tbl21 .prey:Destroy(); tbl21 .prey=nil;end; tbl21 .preyfor=nil;end
				tbl21.dropprey = dropprey
				local function fn67(l)if  tbl21 .preyfor~=l or l.Parent~= alive then return;end;local K= tbl21 .finclone(l);if not K then return;end;if  tbl21 .prey then  tbl21 .prey:Destroy();end; tbl21 .prey=K;end
				local function fn68()if not( tbl10 .unlockall or  tbl10 .autoload or  tbl10 .swskin)then return;end;local l= tbl21 .finfor( tbl21 .cursword());if l then  tbl21 .prefetch("Finishers",l);end;end
				local function fn69(l)if not( tbl10 .unlockall or  tbl10 .autoload or  tbl10 .swskin)then return;end; fn68 ();if not l or  tbl21 .preyfor==l then return;end; dropprey (); tbl21 .preyfor=l; fn67 (l); tbl3 .bindt(task.delay(3,function() fn67 (l);end));end
				local function fn70()local l= tbl3 .safechar();if not l or l.Parent~= alive then return 0,nil;end;local l,K=0;for p,p in ipairs( alive :GetChildren())do if  fn66 (p)then l,K=l+1,p;end;end;return l,K;end
				tbl3.bind(alive.ChildRemoved:Connect(function(l)local K= Players :GetPlayerFromCharacter(l);if not K then return;end;if K== localPlayer then  tbl21 .lost=true;return;end;K= tbl3 .safechar(); tbl21 .lost=not(K and K.Parent== alive and not K:GetAttribute("Dead"));if  tbl21 .lost then return;end;local K,p= fn70 ();if K==1 then  fn69 (p);return;end;if K>1 then return;end; tbl21 .winfin(l);end))
				tbl3.bind(alive.ChildAdded:Connect(function(l)if l== localPlayer .Character then  tbl21 .lost=false; dropprey (); fn68 (); tbl3 .bindt(task.delay(3, fn68 ));end;local l,K= fn70 ();if l==1 then  fn69 (K);end;end))
			end

			tbl10.forceemo = toggles.forceemote.Value

			if toggles.emotespam.Value then
				tbl10.emospam = true
				fn65()
			end

			if tbl10.forceemo or tbl10.emospam or tbl10.emospawn or tbl10.emoteonly then
				tbl3.bindt(task.spawn(arm))
			end
		else
			local str2 = "https://raw.githubusercontent.com/joshhhie/rise/refs/heads/main/loader.lua"

			tbl3.queuetp = function()
				local v5 = queueonteleport
				if type(v5) ~= "function" then
					return
				end
				local riseScriptSource

				if type(_G.RiseScriptSource) == "string" and _G.RiseScriptSource ~= "" then
					riseScriptSource = _G.RiseScriptSource
				else
					riseScriptSource = nil

					if str2:sub(1, 4) == "http" then
						riseScriptSource = ("loadstring(game:HttpGet(\"%s\"))()"):format(str2)
					end
				end

				if not riseScriptSource then
					tbl3.notif("Auto Execute", "Can't restart itself after a teleport. Run the script again from its loader.", 6)
					return
				end
				v5("_G.cuties = nil\n_G.RiseBoot = nil\n" .. riseScriptSource)
				tbl3.queued = true
			end

			tbl3.vipcb = function(arg)
				local textChatMessageProperties = Instance.new("TextChatMessageProperties")

				if tbl10.viptag and arg.TextSource and arg.TextSource.UserId == localPlayer.UserId then
					textChatMessageProperties.PrefixText = "<font color='#FFD700'>[VIP]</font> " .. arg.PrefixText
				end

				return textChatMessageProperties
			end

			tbl3.applyvip = function()
				if tbl9.vipset then
					return
				end
				local TextChatService = game:GetService("TextChatService")
				TextChatService.OnIncomingMessage = tbl3.vipcb
				tbl9.vipset = true

				tbl3.bindt(task.delay(2, function()
					if tbl9.vipset then
						TextChatService.OnIncomingMessage = tbl3.vipcb
					end
				end))
			end

			tbl3.killvip = function()
				if not tbl9.vipset then
					return
				end

				game:GetService("TextChatService").OnIncomingMessage = function()
					return nil
				end

				tbl9.vipset = false
			end

			local tbl18 = {
				Cinematic = {
					bloom = { Intensity = 0.85, Size = 24, Threshold = 0.92 },
					cc = {
						Brightness = 0.02,
						Contrast = 0.16,
						Saturation = 0.06,
						TintColor = Color3.fromRGB(255, 246, 236),
					},
					sun = { Intensity = 0.08, Spread = 0.5 },
					dof = { FarIntensity = 0.4, FocusDistance = 0.05, InFocusRadius = 70, NearIntensity = 0 },
				},
				Vivid = {
					bloom = { Intensity = 1.1, Size = 22, Threshold = 0.88 },
					cc = {
						Brightness = 0.04,
						Contrast = 0.2,
						Saturation = 0.28,
						TintColor = Color3.fromRGB(255, 252, 248),
					},
					sun = { Intensity = 0.06, Spread = 0.45 },
					dof = { FarIntensity = 0.25, FocusDistance = 0.05, InFocusRadius = 90, NearIntensity = 0 },
				},
				["Soft Dream"] = {
					bloom = { Intensity = 1.6, Size = 40, Threshold = 0.78 },
					cc = {
						Brightness = 0.06,
						Contrast = -0.05,
						Saturation = 0.1,
						TintColor = Color3.fromRGB(255, 244, 250),
					},
					sun = { Intensity = 0.14, Spread = 0.7 },
					dof = { FarIntensity = 0.55, FocusDistance = 0.05, InFocusRadius = 55, NearIntensity = 0 },
				},
				Noir = {
					bloom = { Intensity = 1, Size = 26, Threshold = 0.9 },
					cc = {
						Brightness = 0,
						Contrast = 0.3,
						Saturation = -0.85,
						TintColor = Color3.fromRGB(235, 240, 255),
					},
					sun = { Intensity = 0.05, Spread = 0.4 },
					dof = { FarIntensity = 0.3, FocusDistance = 0.05, InFocusRadius = 80, NearIntensity = 0 },
				},
				["Warm Sunset"] = {
					bloom = { Intensity = 1.2, Size = 30, Threshold = 0.82 },
					cc = {
						Brightness = 0.03,
						Contrast = 0.12,
						Saturation = 0.18,
						TintColor = Color3.fromRGB(255, 226, 196),
					},
					sun = { Intensity = 0.18, Spread = 0.65 },
					dof = { FarIntensity = 0.35, FocusDistance = 0.05, InFocusRadius = 75, NearIntensity = 0 },
				},
				["Cold Steel"] = {
					bloom = { Intensity = 0.9, Size = 22, Threshold = 0.9 },
					cc = {
						Brightness = 0,
						Contrast = 0.22,
						Saturation = -0.1,
						TintColor = Color3.fromRGB(214, 230, 255),
					},
					sun = { Intensity = 0.05, Spread = 0.4 },
					dof = { FarIntensity = 0.3, FocusDistance = 0.05, InFocusRadius = 85, NearIntensity = 0 },
				},
				["Neon Night"] = {
					bloom = { Intensity = 2, Size = 34, Threshold = 0.7 },
					cc = {
						Brightness = -0.04,
						Contrast = 0.26,
						Saturation = 0.4,
						TintColor = Color3.fromRGB(228, 232, 255),
					},
					sun = { Intensity = 0, Spread = 0.4 },
					dof = { FarIntensity = 0.45, FocusDistance = 0.05, InFocusRadius = 60, NearIntensity = 0 },
				},
			}

			tbl3.clrshade = function()
				if tbl9.shadefx then
					for _, v5 in ipairs(tbl9.shadefx) do
						v5:Destroy()
					end

					tbl9.shadefx = nil
				end
			end

			tbl3.applyshade = function()
				tbl3.clrshade()
				if not tbl10.shaders then
					return
				end
				local cinematic = tbl18[tbl10.shaderpreset] or tbl18.Cinematic
				local shadefx = {}

				local function fn9(arg, arg2)
					local instance = Instance.new(arg)

					for k, v5 in pairs(arg2) do
						instance[k] = v5
					end

					instance.Parent = Lighting
					shadefx[#shadefx + 1] = instance
					return instance
				end

				local v5 = clamp(cinematic.cc.Saturation + (tbl10.saturation or 1) - 1, -1, 1)

				fn9("ColorCorrectionEffect", {
					Name = "_rcc",
					Brightness = clamp(cinematic.cc.Brightness + (tbl10.brightness or 0), -1, 1),
					Contrast = clamp(cinematic.cc.Contrast + (tbl10.contrast or 0), -1, 1),
					Saturation = v5,
					TintColor = cinematic.cc.TintColor,
				})

				fn9("BloomEffect", {
					Name = "_rbloom",
					Intensity = max(0, cinematic.bloom.Intensity * (tbl10.bloom or 1)),
					Size = cinematic.bloom.Size,
					Threshold = cinematic.bloom.Threshold,
				})

				if cinematic.sun and cinematic.sun.Intensity > 0 then
					fn9("SunRaysEffect", { Name = "_rsun", Intensity = cinematic.sun.Intensity, Spread = cinematic.sun.Spread })
				end

				if tbl10.dof and cinematic.dof then
					fn9("DepthOfFieldEffect", {
						Name = "_rdof",
						FarIntensity = cinematic.dof.FarIntensity,
						FocusDistance = cinematic.dof.FocusDistance,
						InFocusRadius = cinematic.dof.InFocusRadius,
						NearIntensity = cinematic.dof.NearIntensity,
					})
				end

				tbl9.shadefx = shadefx
			end

			tbl3.clrrain = function()
				if tbl9.rainconn then
					tbl9.rainconn:Disconnect()
					tbl9.rainconn = nil
				end

				if tbl9.rainfx then
					for _, v5 in ipairs(tbl9.rainfx) do
						v5:Destroy()
					end

					tbl9.rainfx = nil
				end
			end

			tbl3.applyrain = function()
				tbl3.clrrain()
				if not tbl10.rain then
					return
				end
				local part = Instance.new("Part")
				part.Name = "_rrain"
				part.Anchored = true
				part.CanCollide = false
				part.CanQuery = false
				part.CanTouch = false
				part.Transparency = 1
				part.Size = Vector3.new(70, 1, 70)
				part.Orientation = Vector3.zero
				local particleEmitter = Instance.new("ParticleEmitter")
				particleEmitter.Name = "_rrainfx"
				particleEmitter.Rate = tbl10.rainrate or 150
				particleEmitter.Lifetime = NumberRange.new(0.55, 0.8)
				particleEmitter.Speed = NumberRange.new(75, 95)
				particleEmitter.SpreadAngle = Vector2.new(6, 6)
				particleEmitter.Acceleration = Vector3.new(0, -60, 0)
				particleEmitter.EmissionDirection = Enum.NormalId.Bottom
				particleEmitter.Rotation = NumberRange.new(0, 0)
				local new = NumberSequenceKeypoint.new
				particleEmitter.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.18), new(1, 0.1) })
				local numberSequence = NumberSequence.new
				local tbl19 = {}
				local v5 = NumberSequenceKeypoint.new(0, 0.25)
				local v6 = NumberSequenceKeypoint.new(0.8, 0.4)
				local new2 = NumberSequenceKeypoint.new
				tbl19[1] = v5
				tbl19[2] = v6

				do
					local values = table.pack(new2(1, 1))
					table.move(values, 1, values.n, 3, tbl19)
				end

				particleEmitter.Transparency = numberSequence(tbl19)
				particleEmitter.Color = ColorSequence.new(Color3.fromRGB(170, 200, 230))
				particleEmitter.LightEmission = 0.2
				particleEmitter.Brightness = 1
				particleEmitter.ZOffset = 1
				particleEmitter.Parent = part
				part.Parent = Workspace
				tbl9.rainfx = { part }
				tbl9.rainconn = tbl3.bind(RunService.RenderStepped:Connect(function()if not  tbl10 .rain then return;end;local l= tbl3 .safehrp();local K=l and l.Position;K=if not K and  currentCamera then  currentCamera .CFrame.Position else K;if K then  part .Position=K+Vector3.new(0,32,0);end; particleEmitter .Rate= tbl10 .rainrate or 150;end))
			end

			tbl3.stopmusic = function()
				tbl9.musicsound = nil

				for _, child in ipairs(SoundService:GetChildren()) do
					if child.Name == "_rbgm" then
						child:Destroy()
					end
				end
			end

			tbl3.setupmusic = function()
				tbl3.stopmusic()
				if not tbl10.music then
					return
				end
				tbl9.musicgen = (tbl9.musicgen or 0) + 1
				local musicgen = tbl9.musicgen
				local musicid = tbl10.musicid
				local match

				if musicid and musicid ~= "" then
					match = tostring(musicid):match("%d+")
				else
					match = tbl6[tbl10.track]
				end

				if not match or match == "" then
					tbl3.notif("Music", "That track has no audio ID. Pick another song.", 3)
					return
				end
				local num = tonumber(match)

				if num then
					local productInfo = MarketplaceService:GetProductInfo(num)
					if musicgen ~= tbl9.musicgen then
						return
					end

					if type(productInfo) == "table" and productInfo.AssetTypeId then
						if productInfo.AssetTypeId ~= 3 then
							tbl3.notif("Music", "That is not a song. Paste a Roblox audio ID.", 6)
							return
						end
						tbl3.notif("Music", "Now playing \"" .. tostring(productInfo.Name) .. "\"", 3)
					end
				end

				local sound = Instance.new("Sound")
				sound.Name = "_rbgm"
				sound.SoundId = "rbxassetid://" .. tostring(match)
				sound.Volume = clamp((tbl10.vol or 3) / 10, 0, 1)
				sound.Looped = true
				sound.Parent = SoundService
				sound:Play()
				tbl9.musicsound = sound

				tbl3.bindt(task.spawn(function()
					local n3 = clock() + 5

					while clock() < n3 do
						if sound.Parent ~= SoundService then
							return
						end

						if sound.IsLoaded then
							return
						end
						task.wait(0.25)
					end

					if sound.Parent == SoundService and not sound.IsLoaded then
						tbl3.notif("Music", (musicid and musicid ~= "" and "ID " .. tostring(match) or "\"" .. tostring(tbl10.track) .. "\"") .. " won't load. Pick another song.", 5)
					end
				end))
			end

			tbl3.hudbutton = function(name, arg, text, arg2, arg3)
				local screenGui = Instance.new("ScreenGui")
				screenGui.Name = name
				screenGui.ResetOnSpawn = false
				screenGui.IgnoreGuiInset = true
				screenGui.DisplayOrder = 58
				screenGui.Parent = v.ScreenGui or fn6 and fn6() or CoreGui
				local textButton = Instance.new("TextButton")
				textButton.AnchorPoint = Vector2.new(1, 0)
				textButton.Position = UDim2.new(1, -16, 0, arg)
				textButton.Size = UDim2.fromOffset(flag and 128 or 100, flag and 46 or 38)
				textButton.BackgroundColor3 = color
				textButton.BackgroundTransparency = 0.04
				textButton.BorderSizePixel = 0
				textButton.AutoButtonColor = false
				textButton.Font = Enum.Font.GothamBold
				textButton.TextSize = flag and 15 or 13
				textButton.TextColor3 = color2
				textButton.Text = text
				textButton.Parent = screenGui
				tbl3.corner(textButton, 10)
				local v5 = tbl3.stroke(textButton, color3, 1, 0.2)

				local function fn9()
					local v6, v7 = arg2()
					textButton.Text = v6
					textButton.BackgroundColor3 = v7 and accent or color
					textButton.TextColor3 = v7 and Color3.fromRGB(255, 255, 255) or color2
					v5.Color = v7 and accent or color3
				end

				textButton.Activated:Connect(function()
					arg3()
					fn9()
				end)

				tbl3.dragify(textButton, textButton)
				fn9()
				return screenGui, fn9
			end

			local unhook = nil
			local fn9 = nil
			local fn10 = nil
			local fn11 = nil

			tbl3.cleanup = function()
				tbl3.stopap()
				tbl3.stopas()
				tbl3.stopms()
				tbl3.stopabil()
				tbl10.thundernocd = false
				tbl3.setnocd()
				tbl3.delmsgui()
				tbl3.stopstaff()

				if tbl9.vzdash then
					for _, v5 in ipairs(tbl9.vzdash) do
						v5:Destroy()
					end

					tbl9.vzdash = nil
				end

				if tbl9.vzpart then
					tbl9.vzpart:Destroy()
					tbl9.vzpart = nil
				end

				tbl3.clrbt()
				tbl3.clrpt()
				tbl3.espstop()

				if tbl3.restorecos then
					tbl3.restorecos()
				end

				tbl3.setbright(false)
				tbl3.setnofog(false)
				tbl3.setlowgfx(false)

				if tbl14.gravorig ~= nil then
					Workspace.Gravity = tbl14.gravorig
					tbl14.gravorig = nil
				end

				tbl3.restorefov()
				tbl3.applysky("Default")
				tbl3.settime("Default")
				tbl3.stopafk()
				tbl3.stopphantom()
				tbl3.killvip()
				tbl3.clrshade()
				tbl3.clrrain()
				tbl3.stopmusic()

				for _, v5 in ipairs(tbl9.slashoff) do
					v5:Enable()
				end

				if fn10 then
					fn10()
				end

				if unhook then
					unhook()
				end

				if setfpscap then
					setfpscap(0)
				end

				for _, v5 in ipairs({ "RainbowBall", "ShowSwordAccessory" }) do
					localPlayer:SetAttribute(v5, nil)
				end
			end

			toggles.autoparry:OnChanged(function(autoparry)
				tbl10.autoparry = autoparry

				if autoparry then
					tbl3.startap()
					tbl3.notif("Auto Parry", "On.", 3)
				else
					tbl3.stopap()
					tbl3.notif("Auto Parry", "Off.", 3)
				end

			end)

			options.curves:OnChanged(function(crv)
				tbl10.crv = crv
			end)

			do
				local picking = {}
				local prevval = {}
				tbl3.bind(RunService.Heartbeat:Connect(function()
					for _, opt in pairs(options) do
						if type(opt) == "table" and opt.Type == "KeyPicker" then
							picking[opt] = opt.Picking == true
							if opt.Value ~= "Backspace" then
								prevval[opt] = opt.Value
							end
						end
					end
				end))
				tbl3.bind(UserInputService.InputBegan:Connect(function(input)
					if input.KeyCode ~= Enum.KeyCode.Backspace then
						return
					end
					local wasPicking = {}
					for opt, was in pairs(picking) do
						wasPicking[opt] = was
					end
					task.spawn(function()
						RunService.Heartbeat:Wait()
						RunService.Heartbeat:Wait()
						for opt, was in pairs(wasPicking) do
							local justSet = opt.Value == "Backspace" and prevval[opt] ~= "Backspace"
							if was or justSet then
								local mode = opt.Mode or "Toggle"
								local ok = pcall(function()
									opt:SetValue({ "None", mode })
								end)
								if not ok or opt.Value ~= "None" then
									pcall(function()
										opt:SetValue("None")
									end)
								end
								prevval[opt] = "None"
							end
						end
					end)
				end))
			end

			toggles.triggerbot:OnChanged(function(trigger)
				tbl10.trigger = trigger

				if trigger then
					tbl3.starttrigger()
					tbl3.notif("Trigger Bot", "On.", 3)
				else
					tbl3.stoptrigger()
					tbl3.notif("Trigger Bot", "Off.", 3)
				end

			end)

			toggles.nocurvespam:OnChanged(function(nocrv)
				tbl10.nocrv = nocrv
			end)

			for _, name in ipairs(tbl3.curveorder) do
				local bind = options["curvebind_" .. name]
				if bind then
					bind:OnClick(function()
						if options.curves.Value == name and tbl10.crv == name then
							return
						end
						options.curves:SetValue(name)
						tbl10.crv = name
						local nb = options.notif_curvebinds
						if not nb or nb.Value then
							tbl3.notif("Curve", "Curve set to " .. name .. ".", 2)
						end
					end)
				end
			end

			options.parryaccuracy:OnChanged(function(acc)
				tbl10.acc = acc
			end)

			toggles.humanizer:OnChanged(function(hum)
				tbl10.hum = hum

				if hum then
					tbl3.humroll()
					tbl3.notif("Humanizer", "On.", 3)
				else
					tbl10.acc = options.parryaccuracy.Value
					tbl10.rng = options.parryrange.Value
					tbl3.notif("Humanizer", "Off.", 3)
				end
			end)

			options.parryrange:OnChanged(function(rng)
				tbl10.rng = rng
			end)

			toggles.antiafk:OnChanged(function(antiafk)
				tbl10.antiafk = antiafk

				if antiafk then
					tbl3.startafk()
				else
					tbl3.stopafk()
				end
			end)

			toggles.autoexecute:OnChanged(function(autoexec)
				tbl10.autoexec = autoexec

				if autoexec then
					tbl3.queuetp()
				elseif tbl3.queued then
					tbl3.notif("Auto Execute", "Off. It still runs once more after your next teleport.", 6)
				end
			end)

			toggles.viptag:OnChanged(function(viptag)
				tbl10.viptag = viptag
				tbl3.applyvip()
			end)

			toggles.shaders:OnChanged(function(shaders)
				tbl10.shaders = shaders
				tbl3.applyshade()
			end)

			options.shaderpreset:OnChanged(function(shaderpreset)
				tbl10.shaderpreset = shaderpreset
				tbl3.applyshade()
			end)

			toggles.shaderdof:OnChanged(function(dof)
				tbl10.dof = dof
				tbl3.applyshade()
			end)

			options.shaderbloom:OnChanged(function(bloom)
				tbl10.bloom = bloom
				tbl3.applyshade()
			end)

			options.shadersaturation:OnChanged(function(saturation)
				tbl10.saturation = saturation
				tbl3.applyshade()
			end)

			options.shaderbrightness:OnChanged(function(brightness)
				tbl10.brightness = brightness
				tbl3.applyshade()
			end)

			options.shadercontrast:OnChanged(function(contrast)
				tbl10.contrast = contrast
				tbl3.applyshade()
			end)

			toggles.raineffect:OnChanged(function(rain)
				tbl10.rain = rain
				tbl3.applyrain()
			end)

			options.rainintensity:OnChanged(function(rainrate)
				tbl10.rainrate = rainrate
			end)

			toggles.autospam:OnChanged(function(autospam)
				tbl10.autospam = autospam

				if autospam then
					tbl3.startas()
					tbl3.notif("Auto Spam", "On.", 3)
				else
					tbl3.stopas()
					tbl3.notif("Auto Spam", "Off.", 3)
				end
			end)

			toggles.manualspam:OnChanged(function(manspam)
				tbl10.manspam = manspam

				if manspam then
					tbl3.startms()
					tbl3.setmsactive(true)
					tbl3.notif("Manual Spam", "On.", 3)
				else
					tbl3.stopms()
					tbl3.notif("Manual Spam", "Off.", 3)
				end
			end)

			options.parrymethod:OnChanged(function(arg)
				tbl10.keyparry = arg == "Keypress"
			end)

			toggles.norender:OnChanged(function(norender)
				tbl10.norender = norender
				tbl3.setnorender()
			end)

			toggles.emoteonly:OnChanged(function(emoteonly)
				tbl10.emoteonly = emoteonly

				if emoteonly then
					if tbl3.emoteonly then
						tbl3.emoteonly(true)
					end
				end
			end)

			toggles.autoability:OnChanged(function(autoabil)
				if autoabil and not tbl3.featguard("abil", "Auto Ability") then
					toggles.autoability:SetValue(false)
					return
				end
				tbl10.autoabil = autoabil

				if tbl10.autoabil or tbl10.cdprot then
					tbl3.startabil()
				else
					tbl3.stopabil()
				end
			end)

			toggles.cooldownprotection:OnChanged(function(cdprot)
				if cdprot and not tbl3.featguard("abil", "Cooldown Protection") then
					toggles.cooldownprotection:SetValue(false)
					return
				end
				tbl10.cdprot = cdprot

				if tbl10.autoabil or tbl10.cdprot then
					tbl3.startabil()
				else
					tbl3.stopabil()
				end
			end)

			toggles.thundernocd:OnChanged(function(thundernocd)
				tbl10.thundernocd = thundernocd
				tbl3.setnocd()
			end)

			options.abilityminspeed:OnChanged(function(abilspd)
				tbl10.abilspd = abilspd
			end)

			toggles.staffdetection:OnChanged(function(staff)
				tbl10.staff = staff

				if staff then
					tbl3.startstaff()
				else
					tbl3.stopstaff()
				end
			end)

			options.staffaction:OnChanged(function(staffdo)
				tbl10.staffdo = staffdo
			end)

			toggles.visualizer:OnChanged(function(viz)
				tbl10.viz = viz
				tbl3.setupviz()
			end)

			options.visualizercolour:OnChanged(function(vizcol)
				tbl10.vizcol = vizcol
			end)

			tbl3.setaccent = function()
				v.Scheme.AccentColor = tbl3.uiaccent
				v:UpdateColorsUsingRegistry()
			end

			toggles.balltrail:OnChanged(function(bt)
				tbl10.bt = bt

				if bt then
					tbl3.applybt()
				else
					tbl3.clrbt()
				end
			end)

			toggles.balltrailrainbow:OnChanged(function(btrb)
				tbl10.btrb = btrb

				if tbl10.bt then
					tbl3.refbt()
				end
			end)

			toggles.balltrailparticles:OnChanged(function(btpart)
				tbl10.btpart = btpart

				if tbl10.bt then
					tbl3.refbt()
				end
			end)

			toggles.balltrailglow:OnChanged(function(btglow)
				tbl10.btglow = btglow

				if tbl10.bt then
					tbl3.refbt()
				end
			end)

			options.balltrailstartcolour:OnChanged(function(btstart)
				tbl10.btstart = btstart

				if tbl10.bt then
					tbl3.refbt()
				end
			end)

			options.balltrailendcolour:OnChanged(function(btend)
				tbl10.btend = btend

				if tbl10.bt then
					tbl3.refbt()
				end
			end)

			options.balltraillifetime:OnChanged(function(btlife)
				tbl10.btlife = btlife

				if tbl10.bt then
					tbl3.refbt()
				end
			end)

			toggles.playertrail:OnChanged(function(pt)
				tbl10.pt = pt

				if pt then
					tbl3.applypt()
				else
					tbl3.clrpt()
				end
			end)

			toggles.playertrailrainbow:OnChanged(function(ptrb)
				tbl10.ptrb = ptrb

				if tbl10.pt then
					tbl3.refpt()
				end
			end)

			options.playertrailcolour:OnChanged(function(ptcol)
				tbl10.ptcol = ptcol

				if tbl10.pt then
					tbl3.refpt()
				end
			end)

			options.playertraillifetime:OnChanged(function(ptlife)
				tbl10.ptlife = ptlife

				if tbl10.pt then
					tbl3.refpt()
				end
			end)

			options.playertrailwidth:OnChanged(function(ptwidth)
				tbl10.ptwidth = ptwidth

				if tbl10.pt then
					tbl3.refpt()
				end
			end)

			tbl3.bind(localPlayer.CharacterAdded:Connect(function()
				task.wait(0.5)

				if tbl10.pt then
					tbl3.applypt()
				end
			end))

			toggles.abilityesp:OnChanged(function(arg)
				if arg then
					tbl3.espstart()
				else
					tbl3.espstop()
				end
			end)

			toggles.fullbright:OnChanged(function(arg)
				tbl3.setbright(arg)
			end)

			toggles.nofog:OnChanged(function(arg)
				tbl3.setnofog(arg)
			end)

			toggles.customfov:OnChanged(function(arg)
				if arg then
					tbl3.startfov()
				else
					tbl3.restorefov()
				end
			end)

			toggles.customgrav:OnChanged(function()
				tbl3.setgrav()
			end)

			options.grav:OnChanged(function()
				if toggles.customgrav.Value then
					tbl3.setgrav()
				end
			end)

			toggles.lowgfx:OnChanged(function(arg)
				tbl3.setlowgfx(arg)
			end)

			toggles.fpscap:OnChanged(function(fpscap)
				tbl10.fpscap = fpscap
				tbl3.applycap()
			end)

			toggles.antilag:OnChanged(function(arg)
				if arg then
					tbl3.startantilag()
				elseif tbl9.alapplied then
					tbl9.alapplied = false

					if not (toggles.lowgfx and toggles.lowgfx.Value) then
						tbl3.setlowgfx(false)
					end
				end
			end)

			options.fpscapvalue:OnChanged(function(fpsval)
				tbl10.fpsval = fpsval

				if tbl10.fpscap then
					tbl3.applycap()
				end
			end)

			toggles.ffenable:OnChanged(function(arg)
				if not arg then
					return
				end
				toggles.ffenable:SetValue(false)

				if tbl3.ffapply() > 0 then
					tbl3.notif("FFlags", "Rejoining to apply your flags.", 3)

					task.delay(1.5, function()
						if fn3 then
							fn3()
						end
					end)
				end
			end)

			options.skybox:OnChanged(function(arg)
				tbl3.applysky(arg)

				if arg == "Default" then
					tbl3.notif("Skybox", "Reset to default.", 2)
				else
					tbl3.notif("Skybox", "Set to \"" .. tostring(arg) .. "\".", 2)
				end
			end)

			options.timeofday:OnChanged(function(arg)
				tbl3.settime(arg)
			end)

			toggles.music:OnChanged(function(music)
				tbl10.music = music
				tbl3.setupmusic()
			end)

			options.musictrack:OnChanged(function(track)
				tbl10.track = track

				if tbl10.music then
					tbl3.setupmusic()
				end
			end)

			options.musicvolume:OnChanged(function(vol)
				tbl10.vol = vol

				if tbl9.musicsound then
					tbl9.musicsound.Volume = clamp(vol / 10, 0, 1)
				end
			end)

			options.musiccustom:OnChanged(function(musicid)
				tbl10.musicid = musicid or ""

				if tbl10.music then
					tbl3.setupmusic()
				end
			end)

			tbl3.bind(localPlayer.CharacterAdded:Connect(function()
				if toggles.customgrav.Value then
					task.defer(tbl3.setgrav)
				end
			end))

			_G.stagesh = "handlers"
			tbl3.chkfeat()

			tbl3.onstart = {
				{
					flag = "abilityesp",
					run = function()
						tbl3.espstart()
					end,
				},
				{
					flag = "fullbright",
					run = function()
						tbl3.setbright(true)
					end,
				},
				{
					flag = "nofog",
					run = function()
						tbl3.setnofog(true)
					end,
				},
				{
					flag = "customgrav",
					run = function()
						tbl3.setgrav()
					end,
				},
				{
					flag = "lowgfx",
					run = function()
						tbl3.setlowgfx(true)
					end,
				},
				{
					flag = "norender",
					run = function()
						tbl3.setnorender()
					end,
				},
				{
					flag = "thundernocd",
					run = function()
						tbl3.setnocd()
					end,
				},
				{
					flag = "emoteonly",
					run = function()
						if tbl3.emoteonly then
							tbl3.emoteonly(true)
						end
					end,
				},
				{
					flag = "antilag",
					run = function()
						tbl3.startantilag()
					end,
				},
				{ run = function()
					tbl3.applycap()

					if tbl10.fpscap then
						tbl3.notif("FPS Cap", format("FPS capped at %d. Change it in Performance.", tbl10.fpsval or 60), 6)
					end

					if options.skybox.Value and options.skybox.Value ~= "Default" then
						tbl3.applysky(options.skybox.Value)
					end

					if options.timeofday.Value and options.timeofday.Value ~= "Default" then
						tbl3.settime(options.timeofday.Value)
					end
				end },
				{
					flag = "autoparry",
					run = function()
						tbl3.startap()
					end,
				},
				{
					flag = "triggerbot",
					run = function()
						tbl3.starttrigger()

						if tbl10.autoparry then
							tbl10.autoparry = false
							tbl3.stopap()
							toggles.autoparry:SetValue(false)
						end
					end,
				},
				{
					flag = "autospam",
					run = function()
						tbl3.startas()
					end,
				},
				{
					flag = "manualspam",
					run = function()
						tbl3.startms()
						tbl3.refmsui()
					end,
				},
				{ run = function()
					if toggles.autoability.Value or toggles.cooldownprotection.Value then
						tbl3.startabil()
					end
				end },
				{
					flag = "staffdetection",
					run = function()
						tbl3.startstaff()
					end,
				},
				{
					flag = "visualizer",
					run = function()
						tbl3.setupviz()
					end,
				},
				{
					flag = "balltrail",
					run = function()
						tbl3.applybt()
					end,
				},
				{
					flag = "playertrail",
					run = function()
						tbl3.applypt()
					end,
				},
				{ run = function()
					if (toggles.headless.Value or toggles.korblox.Value or toggles.avatarchanger.Value) and tbl3.applycos then
						tbl3.applycos()
					end
				end },
				{
					flag = "antiafk",
					run = function()
						tbl3.startafk()
					end,
				},
				{
					flag = "autoexecute",
					run = function()
						tbl3.queuetp()
					end,
				},
				{
					flag = "viptag",
					run = function()
						tbl3.applyvip()
					end,
				},
				{
					flag = "shaders",
					run = function()
						tbl3.applyshade()
					end,
				},
				{
					flag = "raineffect",
					run = function()
						tbl3.applyrain()
					end,
				},
				{
					flag = "music",
					run = function()
						tbl3.setupmusic()
					end,
				},
				{ run = function()
					if tbl10.devscreen and tbl10.devscreen ~= "Off" then
						tbl3.devui(tbl10.devscreen, true)
					end

					if tbl10.devtype and tbl10.devtype ~= "Off" then
						tbl3.devarm(tbl10.devtype, true)
					end

					tbl3.devstat()
				end },
				{ run = function()
					if toggles.unlockall and toggles.unlockall.Value and fn9 then
						fn9()
					elseif toggles.equipautoload and toggles.equipautoload.Value and fn11 then
						fn11(false)
					end
				end },
			}

			local tbl20 = {}

			for _, v5 in ipairs(tbl3.onstart) do
				if v5.flag and not toggles[v5.flag] then
					tbl20[#tbl20 + 1] = v5.flag
				end
			end

			if #tbl20 > 0 then
				table.sort(tbl20)
				warn("[boberhook] startup list points at toggles that do not exist: " .. table.concat(tbl20, ", "))
			end

			tbl3.bootstrap_saved_connections = function()
				tbl3.syncopt()
				tbl3.sendping()
				tbl3.ffload()

				tbl3.setaccent()

				if toggles.customfov.Value then
					tbl3.startfov()
				end

				tbl3.startdatapanel()
				tbl3.bindt(task.spawn(tbl3.claimdaily))

				for _, v5 in ipairs(tbl3.onstart) do
					local flag2 = v5.flag and toggles[v5.flag]

					if not v5.flag or flag2 and flag2.Value then
						v5.run()
					end
				end
			end

			tbl3.loadsave()
			v2:LoadAutoloadConfig()
			tbl3.hooksave()
			_G.stagesh = "config"

			task.spawn(function()
				task.wait(0.2)
				tbl3.bootstrap_saved_connections()
			end)

			_G.stagesh = "boot"
			local Replion = require(ReplicatedStorage.Packages.Replion)
			local misc = ReplicatedStorage:FindFirstChild("Misc")
			local v5 = nil
			local client = nil
			local v6 = nil
			local v7 = nil
			local v8 = nil
			local v9 = nil
			local swords = nil
			local function fn12()if setthreadidentity then setthreadidentity(8);end;end
			local function fn13(l)if not l then return nil;end; fn12 ();return require(l);end
			local function fn14(h,...)local l=h;for h=1,select("#",...),1 do if typeof(l)~="Instance"then return nil;end;l=(l:FindFirstChild((select(h,...))));end;return l;end

			local tbl21 = {
				wheelfile = "boberhook_Wheel_" .. tostring(game.GameId) .. ".json",
				wheel = {},
				equipfile = "boberhook_Equip_" .. tostring(game.GameId) .. ".json",
				equip = {},
				ncfile = "boberhook_UnlockNames_" .. tostring(game.GameId) .. ".json",
				hooked = false,
				guihooked = false,
				explhooked = false,
				trove = nil,
				noacc = false,
				explname = nil,
				offconns = {},
				lost = true,
			}

			local fn15 = nil

			local function fn16(arg)
				if not Replion then
					Replion = fn13(fn14(ReplicatedStorage, "Packages", "Replion"))
				end

				if not Replion then
					tbl3.logwev("uaReplion", 10, "UnlockAll", "Replion module unavailable (require failed)")
					return nil
				end
				local replion = Replion.Client:GetReplion(arg)
				if replion then
					return replion
				end
				local n3 = clock() + 5

				while clock() < n3 do
					task.wait(0.1)
					local replion2 = Replion.Client:GetReplion(arg)
					if replion2 then
						return replion2
					end
				end

				return nil
			end

			local tbl22 = {}
			local v10 = nil
			local v11 = nil

			local function fn17(arg)
				if not v11 then
					local collection = type(v10) == "table" and type(v10.GetCollection) == "function" and v10:GetCollection() or nil

					if type(collection) == "table" and next(collection) then
						v11 = collection
					end
				end

				return v11 and v11[arg] or nil
			end

			local function fn18(arg, arg2)
				if arg ~= "Sword" then
					return { Name = arg2, Id = arg2 }
				end
				local sword = tbl22[arg2]

				if sword == nil then
					sword = swords and swords.GetSword and swords:GetSword(arg2) or false
					tbl22[arg2] = sword
				end

				local tbl23 = { Name = arg2, Id = arg2 }

				if type(sword) == "table" then
					if sword.HasFinisher then
						tbl23.Finisher = true
					end

					if sword.AccessoryUnlockable and fn17(arg2) then
						tbl23.Accessory = true
					end
				end

				return tbl23
			end

			local function fn19(arg, arg2)
				if client and client.ItemToKey then
					local v12 = client:ItemToKey(arg, fn18(arg, arg2), { "Id" })
					if type(v12) == "string" then
						return v12
					end
				end

				return HttpService:JSONEncode({ { "Name", arg2 } }) or arg2
			end

			local function fn20(arg, arg2)
				if type(arg) ~= "string" then
					return tostring(arg)
				end

				if client and client.KeyToItem then
					local v12 = client:KeyToItem(arg)
					if type(v12) == "table" and v12.Name then
						return v12.Name
					end
				end

				local str3 = arg:sub(1, 1)

				if str3 == "[" or str3 == "{" then
					local data = HttpService:JSONDecode(arg)

					if type(data) == "table" then
						for _, v12 in ipairs(data) do
							if v12[1] == "Name" then
								return v12[2]
							end
						end

						if data.Name then
							return data.Name
						end
					end
				end

				if arg2 and Replion and Replion.Client then
					local replion = Replion.Client:GetReplion("Inventory")
					replion = replion and replion:Get({ "Inventory", arg2, arg })
					if type(replion) == "table" and replion.Name then
						return replion.Name
					end
				end

				return arg
			end

			local function fn21(arg)
				local tbl23 = {}
				local v12 = misc and misc:FindFirstChild(arg)

				if v12 then
					for _, child in ipairs(v12:GetChildren()) do
						tbl23[#tbl23 + 1] = child.Name
					end
				end

				return tbl23
			end

			local function fn22()
				local tbl23 = {}

				if swords and swords.GetCollection then
					local collection = swords:GetCollection()

					if type(collection) == "table" then
						for k in pairs(collection) do
							tbl23[#tbl23 + 1] = k
						end
					end
				end

				return tbl23
			end

			local function fn23(arg, arg2)
				local character = localPlayer.Character
				if arg ~= nil then
					return arg == localPlayer or arg == character
				end
				return arg2 ~= nil and arg2 == character
			end

			local function fn24()
				if tbl21.explhooked then
					return
				end
				local v12 = fn13(fn14(ReplicatedStorage, "Controllers", "VFXController"))
				if type(v12) ~= "table" or type(v12.PlayExplosion) ~= "function" then
					return
				end
				tbl21.explmod = v12
				tbl21.explorig = v12.PlayExplosion
				v12.PlayExplosion = function(l,K,p,E,k,a,d,...)local I= tbl21 .explname and  tbl21 .explname~=""and  tbl21 .explname~=K;return  tbl21 .explorig(l,if I and( fn23 (a,k))then  tbl21 .explname else K,p,E,k,a,d,...);end
				tbl21.explhooked = true
			end

			local function fn25(arg, arg2)
				local Inventory = fn16("Inventory")
				if not (Inventory and type(Inventory._set) == "function") then
					return
				end
				Inventory:_set({ "Equipped", arg }, { Name = arg2, Id = fn19(arg, arg2) })
			end

			local function fn26(arg, arg2)
				local Inventory = fn16("Inventory")
				if not Inventory then
					return
				end
				local v12 = fn19(arg, arg2)

				if type(Inventory._update) == "function" then
					Inventory:_update({ "Inventory", arg }, { [v12] = fn18(arg, arg2) })
				elseif type(Inventory._set) == "function" then
					local v13 = Inventory:Get({ "Inventory", arg })
					local tbl23 = {}

					if type(v13) == "table" then
						for k, v14 in pairs(v13) do
							tbl23[k] = v14
						end
					end

					tbl23[v12] = fn18(arg, arg2)
					Inventory:_set({ "Inventory", arg }, tbl23)
				end
			end

			tbl21.verifyeq = function(arg, arg2)
				local Inventory = fn16("Inventory")
				if not Inventory then
					return false
				end
				local v12 = Inventory:Get({ "Equipped", arg })
				return type(v12) == "table" and v12.Name == arg2
			end

			tbl21.ensureeq = function(arg, arg2)
				tbl21.eqlatest = tbl21.eqlatest or {}
				tbl21.eqlatest[arg] = arg2

				tbl3.bindt(task.spawn(function()
					for i = 1, 4 do
						if tbl21.eqlatest[arg] ~= arg2 then
							return
						end

						if tbl21.verifyeq(arg, arg2) then
							return
						end
						task.wait(0.35)
						if tbl21.eqlatest[arg] ~= arg2 then
							return
						end
						fn26(arg, arg2)
						fn25(arg, arg2)
					end
				end))
			end

			local function fn27(arg, swname, arg2)
				if not swname or swname == "" then
					return
				end

				if arg == "Sword" then
					tbl10.swskin = true
					tbl10.swname = swname
					tbl21.skinmine = true
					tbl3.initsword()
					tbl3.hookslash()
					tbl3.skinloop()

					if tbl3.applysword() == false then
						tbl10.swskin = false
						tbl10.swname = ""
						return
					end

					tbl3.setswattr(swname)
					fn26("Sword", swname)
					fn25("Sword", swname)
					tbl21.ensureeq("Sword", swname)

					if tbl21.finequip then
						tbl21.finequip(swname)
					end
				elseif arg == "Explosion" then
					tbl21.explname = swname
					fn24()

					if tbl21.prefetch then
						tbl21.prefetch("Explosions", swname)
					end

					fn26("Explosion", swname)
					fn25("Explosion", swname)
					tbl21.ensureeq("Explosion", swname)
				end

				if not arg2 and (arg == "Sword" or arg == "Explosion") then
					tbl21.equip[arg] = swname

					if fn15 then
						fn15()
					end
				end
			end

			tbl21.cursword = function()local l= tbl10 .swname;return if not l or l==""then( tbl3 .swequipped())else l;end

			tbl3.uaawaken = function()
				tbl21.arm()
				local v12 = tbl21.cursword()
				if not v12 or v12 == "" then
					return
				end
				swords = swords or tbl3.initsword()
				if not swords then
					tbl3.notif("Unlock All", "Swords aren't ready yet. Try again in a second.", 4)
					return
				end
				local str3 = "Awakened " .. v12

				if swords:GetSword(str3) ~= nil then
					fn27("Sword", str3)
					tbl3.notif("Unlock All", "Equipped \"" .. str3 .. "\".", 3)
				else
					tbl3.notif("Unlock All", v12 .. " has no awakened version.", 3)
				end
			end

			tbl3.uaequipall = function()
				tbl21.arm()

				for _, v12 in ipairs({ "Sword", "Explosion" }) do
					local v13 = tbl21.equip[v12]

					if type(v13) == "string" and v13 ~= "" then
						fn27(v12, v13, true)
					end
				end

				tbl3.notif("Unlock All", "Your saved loadout is equipped.", 3)
			end

			tbl3.uapreviewfin = function()
				if tbl21.finbusy then
					return
				end
				local v12 = tbl21.finfor(tbl21.cursword())

				if not v12 and options.swordchangername then
					v12 = tbl21.finfor(options.swordchangername.Value)
				end

				if not v12 then
					tbl3.notif("Finisher", "That sword has no finisher.", 4)
					return
				end

				if tbl3.isalive() then
					tbl3.notif("Finisher", "Preview only works in the lobby, not mid-round.", 5)
					return
				end
				local v13 = tbl21.finctrl()
				if not v13 or type(v13.Preview) ~= "function" then
					tbl3.notif("Finisher", "Finishers aren't loaded yet. Try again in a second.", 5)
					return
				end
				local featuresToggle = fn14(ReplicatedStorage, "FeaturesToggle", "LimitedSwords")
				if featuresToggle and featuresToggle.Value == false then
					tbl3.notif("Finisher", "The game has showrooms turned off right now.", 5)
					return
				end
				tbl21.finbusy = true

				tbl3.bindt(task.spawn(function()
					if not tbl21.repasset("Finishers", v12) then
						tbl21.finbusy = false
						tbl3.notif("Finisher", ("Couldn't load the %s finisher."):format(v12), 5)
						return
					end

					if not tbl21.finplayable(v12) then
						tbl21.finbusy = false
						tbl3.notif("Finisher", ("The %s finisher isn't loaded yet."):format(v12), 5)
						return
					end

					tbl3.bindt(task.delay(tbl21.findur(v12) + 2, function()
						tbl21.finbusy = false
					end))

					v13:Preview(v12)

					if setthreadidentity and tbl3.baseident then
						setthreadidentity(tbl3.baseident)
					end
				end))
			end

			tbl21.applyacc = function()
				tbl9.noacc = tbl21.noacc
				localPlayer:SetAttribute("ShowSwordAccessory", not tbl21.noacc)
				local swname = tbl10.swname
				local v12 = tbl3.safechar()
				if not (swname and swname ~= "" and v12 and swords) or tbl9.swbad[swname] then
					return
				end

				tbl3.bindt(task.spawn(function()
					if type(swords.GetInstance) == "function" then
						if not swords:GetInstance(swname) then
							tbl9.swbad[swname] = true
							return
						end
					end

					if not v12.Parent then
						return
					end

					for _, child in ipairs(v12:GetChildren()) do
						if child:IsA("Model") and swords:GetSword(child.Name) then
							child:Destroy()
						end
					end

					tbl3.equipsword(v12, swname, tbl21.noacc, true)

					if tbl9.swctrl and tbl9.swctrl.SetSword then
						tbl9.swctrl:SetSword(swname)
					end
				end))
			end

			local function fn28()
				if tbl21.snapping then
					return false
				end
				tbl21.snapping = true
				local Inventory = fn16("Inventory")
				local owned = { Sword = {}, Explosion = {}, Emote = {} }
				local flag2 = false

				if Inventory then
					for _, v12 in ipairs({ "Sword", "Explosion", "Emote" }) do
						local v13 = Inventory:Get({ "Inventory", v12 })

						if type(v13) == "table" then
							for _, v14 in pairs(v13) do
								if type(v14) == "table" and v14.Name then
									owned[v12][v14.Name] = true
								end
							end
						end
					end

					flag2 = true
				end

				tbl21.snapping = false
				if not flag2 then
					return false
				end
				tbl21.owned = owned
				tbl21.ownedat = clock()
				return true
			end

			local function fn29(arg, arg2)
				if not arg or not arg2 then
					return false
				end

				if not tbl21.owned then
					tbl3.bindt(task.spawn(fn28))
					return false
				end
				local flag2 = not tbl21.everunlocked

				if flag2 then
					flag2 = clock() - (tbl21.ownedat or 0) > 5
				end

				if flag2 then
					tbl3.bindt(task.spawn(fn28))
				end

				return tbl21.owned[arg] and tbl21.owned[arg][arg2] == true or false
			end

			local function fn30()
				if tbl21.everunlocked then
					return
				end

				if not tbl21.owned and not fn28() then
					return
				end
				tbl21.everunlocked = true
			end

			local function fn31(arg)
				if not arg or arg.done then
					return
				end
				arg.done = true

				for _, v12 in ipairs(arg) do
					rawset(v12.sig, "_handlerListHead", v12.head)
				end
			end

			local function fn32(arg, arg2)
				local value = arg._signals and rawget(arg._signals, "_containers")
				value = value and value.onChange
				value = value and value.Inventory
				if not value then
					return nil
				end
				local tbl23 = {}

				for _, v12 in ipairs(arg2) do
					local v13 = value[v12]
					local value2 = v13 and rawget(v13, "__signal")
					local value3 = value2 and rawget(value2, "_handlerListHead")

					if value3 ~= nil and value3 ~= false then
						tbl23[#tbl23 + 1] = { sig = value2, head = value3 }
						rawset(value2, "_handlerListHead", false)
					end
				end

				if #tbl23 == 0 then
					return nil
				end
				tbl3.bindt(task.defer(fn31, tbl23))
				return tbl23
			end

			local function fn33(arg)
				local Inventory = fn16("Inventory")
				if not Inventory then
					return false
				end
				local tbl23 = {}
				local tbl24 = {}
				local flag2 = type(Inventory._update) == "function"
				local flag3 = false

				for k, v12 in pairs(arg) do
					local v13 = Inventory:Get({ "Inventory", k })
					local tbl25 = {}

					if type(v13) == "table" then
						for k2, v14 in pairs(v13) do
							tbl25[k2] = v14
						end
					end

					local owned = tbl21.owned and tbl21.owned[k] or {}
					local v14 = nil
					local v15 = nil
					local n3 = 0

					for _, v16 in ipairs(v12) do
						local v17 = fn19(k, v16)

						if tbl25[v17] == nil and not owned[v16] then
							local v18 = fn18(k, v16)

							if flag2 and not v14 then
								v14 = v17
								v15 = v18
							else
								tbl25[v17] = v18
							end

							n3 += 1
						end
					end

					if n3 > 0 then
						tbl23[k] = tbl25
						flag3 = true

						if v14 then
							tbl24[#tbl24 + 1] = { k, v14, v15 }
						end
					end
				end

				if not flag3 then
					return true
				end
				local tbl25 = {}

				for k in pairs(tbl23) do
					tbl25[#tbl25 + 1] = k
				end

				local v12 = fn32(Inventory, tbl25)
				local flag4

				if flag2 then
					Inventory:_update({ "Inventory" }, tbl23)
					flag4 = true
				else
					flag4 = false

					if type(Inventory._set) == "function" then
						for k, v13 in pairs(tbl23) do
							Inventory:_set({ "Inventory", k }, v13)
						end

						flag4 = true
					end
				end

				fn31(v12)

				if flag4 then
					for _, v13 in ipairs(tbl24) do
						Inventory:_update({ "Inventory", v13[1] }, { [v13[2]] = v13[3] })
					end
				end

				return flag4
			end

			local function fn34(arg, arg2)
				local tbl23 = {}
				local tbl24 = {}
				local v12 = ipairs
				arg = arg or {}

				for _, v13 in v12(arg) do
					if type(v13) == "string" and not tbl23[v13] then
						tbl23[v13] = true
						tbl24[#tbl24 + 1] = v13
					end
				end

				local v13 = ipairs
				local tbl25 = arg2 or {}

				for _, v14 in v13(tbl25) do
					if type(v14) == "string" and not tbl23[v14] then
						tbl23[v14] = true
						tbl24[#tbl24 + 1] = v14
					end
				end

				return tbl24
			end

			local function fn35(arg)
				if not (isfile and readfile and isfile(arg)) then
					return nil
				end
				local v12 = readfile(arg)
				if type(v12) ~= "string" then
					return nil
				end
				local match = v12:match("^%s*(.-)%s*$")
				local str3 = match:sub(1, 1)
				local str4 = match:sub(-1)
				if not (str3 == "{" and str4 == "}" or str3 == "[" and str4 == "]") then
					return nil
				end
				return HttpService:JSONDecode(match)
			end

			local function fn36()
				if tbl21.ncloaded then
					return
				end
				tbl21.ncloaded = true
				local v12 = fn35(tbl21.ncfile)

				if type(v12) == "table" then
					if type(v12.Sword) == "table" and #v12.Sword > 0 then
						tbl21.swnames = v12.Sword
					end

					if type(v12.Explosion) == "table" and #v12.Explosion > 0 then
						tbl21.explnames = v12.Explosion
					end

					if type(v12.Emote) == "table" and #v12.Emote > 0 then
						tbl21.emonames = v12.Emote
					end
				end
			end

			local function fn37()
				if not writefile then
					return
				end

				writefile(tbl21.ncfile, HttpService:JSONEncode({
					Sword = tbl21.swnames or {},
					Explosion = tbl21.explnames or {},
					Emote = tbl21.emonames or {},
				}))
			end

			local function fn38()
				local v12 = fn22()
				local flag2 = false

				if #v12 > 0 then
					tbl21.swnames = fn34(tbl21.swnames, v12)
					flag2 = true
				end

				local DataExplosions = fn21("DataExplosions")

				if #DataExplosions > 0 then
					tbl21.explnames = fn34(tbl21.explnames, DataExplosions)
					flag2 = true
				end

				local Emotes = fn21("Emotes")

				if #Emotes > 0 then
					tbl21.emonames = fn34(tbl21.emonames, Emotes)
					flag2 = true
				end

				if flag2 then
					fn37()
				end

				return flag2
			end

			local function fn39()
				if tbl21.warmed then
					return
				end
				fn36()
				v5 = v5 or fn13(ReplicatedStorage.Shared.Inventory)
				client = client or v5 and v5.Client
				v6 = v6 or fn13(ReplicatedStorage.Controllers.UI.ShopControllerAPI)
				v7 = v7 or fn13(ReplicatedStorage.Controllers.EmoteController)
				v8 = v8 or fn13(ReplicatedStorage.Shared.EmotesShared)
				v9 = v9 or fn13(ReplicatedStorage.Packages.Trove)
				tbl3.initsword()
				swords = tbl9.swords
				v10 = v10 or fn13(fn14(ReplicatedStorage, "Shared", "ReplicatedInstances", "SwordAccessories"))
				fn38()

				if localPlayer:GetAttribute("ShowSwordAccessory") == nil then
					localPlayer:SetAttribute("ShowSwordAccessory", not tbl21.noacc)
				end

				tbl21.warmed = true
			end

			local function fn40()
				if tbl21.injected then
					return
				end
				tbl21.injected = true

				if not fn16("Inventory") then
					tbl21.failed = true
					tbl3.logwev("uaInject", 5, "UnlockAll", "Inventory Replion unavailable - injection skipped")
					return
				end

				tbl21.failed = false

				if not tbl21.owned then
					fn28()
				end

				fn36()
				local flag2 = tbl21.swnames and #tbl21.swnames > 0 or tbl21.explnames and #tbl21.explnames > 0
				local flag3

				if flag2 then
					flag3 = flag2
				else
					flag3 = tbl21.emonames and #tbl21.emonames > 0
				end

				if not flag3 then
					fn38()
				end

				if not fn33({
					Sword = tbl21.swnames or fn22(),
					Explosion = tbl21.explnames or fn21("DataExplosions"),
				}) then
					tbl21.failed = true
					tbl3.logwev("uaInject", 5, "UnlockAll", "Replion has no _update or _set - nothing injected")
				end
			end

			local function fn41()if  v9 then local l= v9 .new();if l then return l;end;end;local h={};return{Add=function(l,l)h[#h+1]=l;return l;end,Clean=function()for l,l in ipairs(h)do if typeof(l)=="Instance"then l:Destroy();elseif typeof(l)=="thread"then task.cancel(l);elseif typeof(l)=="RBXScriptConnection"then l:Disconnect();elseif type(l)=="function"then l();end;end;table.clear(h);end};end

			local tbl23 = {
				Emote915 = { id = "rbxassetid://121746225545509", delay = 0.65 },
				Emote1017 = { id = "rbxassetid://122138306164149", delay = 0 },
				Emote1052 = { id = "rbxassetid://86553108866816", delay = 0 },
				Emote1167 = { id = "rbxassetid://78966882139691", delay = 0 },
				Emote1185 = { id = "rbxassetid://73110745626575", delay = 0 },
				Emote1217 = { id = "rbxassetid://107342460864353", delay = 3.3333333333333335 },
			}

			local function fn42(l,K,p)local E=K:FindFirstChild("HumanoidRootPart")or K.PrimaryPart;if not E then return false;end;local k=false;local a={};local d=nil;d=function(I,C)if a[I]then return;end;a[I]=true;if  tbl21 .activeemo~=l then return;end;local a=I:Clone();a.Parent=E;p:Add(a);local function I()if  tbl21 .activeemo==l and a.Parent then a:Play();end;end;if C and C>0 then p:Add(task.delay(C,I));else I();end;k=true;end;local function a(I)if typeof(I)~="Instance"then return;end;for C,U in ipairs(I:GetDescendants())do if U:IsA("Sound")then C=U:FindFirstAncestorWhichIsA("Folder");d(U,(tonumber(C and(C:GetAttribute("EnableFrame")))or 0)/60);end;end;end;K= fn13 ( ReplicatedStorage .Shared.ReplicatedInstances.EmoteVFX);if K and K.GetInstance then a(K:GetInstance(l));end;K= fn13 ( ReplicatedStorage .Shared.ReplicatedInstances.EmoteAccessories);if K and K.GetInstance then a(K:GetInstance(l));end;K= ReplicatedStorage :FindFirstChild("Misc");local d=K and(K:FindFirstChild("Emotes"));a(d and(d:FindFirstChild(l)));if not k then d= tbl23 [l];if d and  tbl21 .activeemo==l then local K=Instance.new("Sound");K.Name="RiseEmoteSound";K.SoundId=d.id;K.Looped=true;K.Volume=1;K.RollOffMode=Enum.RollOffMode.InverseTapered;K.RollOffMaxDistance=500;K.Parent=E;p:Add(K);if d.delay>0 then p:Add(task.delay(d.delay,function()if  tbl21 .activeemo==l and K.Parent then K:Play();end;end));else K:Play();end;k=true;end;end;return k;end
			local function fn44(h)local l=h:FindFirstChildOfClass("Humanoid");h=l and(l:FindFirstChildOfClass("Animator"));if not h then return 0;end;l=h:GetPlayingAnimationTracks();return type(l)=="table"and#l or 0;end
			local function fn45()local l= tbl3 .safehum();return l~=nil and l.MoveDirection.Magnitude>0.1;end
			local function fn46(l)local K= tbl3 .safechar();if not K then return;end;if  fn45 ()then return;end; tbl21 .activeemo=l; tbl21 .emostart= clock ();if  tbl21 .trove then  tbl21 .trove:Clean(); tbl21 .trove=nil;end;if  v8 and  v8 .Play and  v9 then local p= v9 .new(); tbl21 .trove=p;local E= fn44 (K); v8 :Play(K,p,l,true, Workspace :GetServerTimeNow());if  tbl21 .trove~=p or  tbl21 .activeemo~=l then return;end;if  fn44 (K)>E then return;end; tbl3 .logwev("emoteQuiet:"..tostring(l),5,("EmotesShared:Play returned without animating %s - using animation+sound fallback"):format(tostring(l)));p:Clean(); tbl21 .trove=nil;end;if  v7 and  v7 ._playAnimation then  v7 :_playAnimation(l);end;local p= fn41 (); tbl21 .trove=p;task.spawn(function() fn42 (l,K,p);end);end

			local function fn47(arg, arg2)
				local Inventory = fn16("Inventory")

				if Inventory and type(Inventory._set) == "function" then
					local set = Inventory._set
					local tbl24 = {}
					local v12 = tostring
					local n3 = tonumber(arg2) or 1
					local v13 = table.pack(v12(n3))
					tbl24[1] = "EquippedList"
					tbl24[2] = "Emote"

					do
						local values = table.pack(table.unpack(v13, 1, v13.n))
						table.move(values, 1, values.n, 3, tbl24)
					end

					set(Inventory, tbl24, { Name = arg, Id = fn19("Emote", arg) })
				end
			end

			local function fn48()
				if not writefile then
					return
				end
				writefile(tbl21.wheelfile, HttpService:JSONEncode(tbl21.wheel))
			end

			fn15 = function()
				if not writefile then
					return
				end
				writefile(tbl21.equipfile, HttpService:JSONEncode(tbl21.equip))
			end

			local function fn49()
				local v12 = fn35(tbl21.equipfile)

				if type(v12) == "table" then
					tbl21.equip = v12
				end
			end

			local function fn50()
				local v12 = fn35(tbl21.wheelfile)

				if type(v12) == "table" then
					tbl21.wheel = v12
				end

				for k, v13 in pairs(tbl21.wheel) do
					fn47(v13, k)
				end
			end

			local function fn51(arg, arg2)
				local n3 = tonumber(arg2) or 1
				fn47(arg, n3)
				tbl21.wheel[tostring(n3)] = arg
				fn48()
			end

			local function fn52(arg, arg2, arg3)
				local v12 = arg[arg2]
				if type(v12) ~= "function" then
					return nil
				end
				arg[arg2] = arg3
				if arg[arg2] == arg3 then
					return v12
				end
				return nil
			end

			tbl21.repmod = {}
			tbl21.repwarm = {}
			local function repasset(l,K)if  tbl21 .repmod[l]==nil then  tbl21 .repmod[l]= fn13 ( fn14 ( ReplicatedStorage ,"Shared","ReplicatedInstances",l))or false;end;local p= tbl21 .repmod[l];if not p or type(p.GetInstance)~="function"then return nil;end;return p:GetInstance(K)or nil;end
			tbl21.repasset = repasset
			tbl21.reptry = {}
			tbl21.prefetch = function(l,K)if not K or K==""then return;end;local p=l.."/"..K;if  tbl21 .repwarm[p]then return;end;local E=( tbl21 .reptry[p]or 0)+1;if E>2 then return;end; tbl21 .reptry[p]=E; tbl21 .repwarm[p]=true; tbl3 .bindt(task.spawn(function()if not  repasset (l,K)then  tbl21 .repwarm[p]=nil;end;end));end
			tbl21.finctrl = function()if  tbl21 .fcmod==nil then  tbl21 .fcmod= fn13 ( fn14 ( ReplicatedStorage ,"Controllers","FinishersController"))or false;end;return  tbl21 .fcmod or nil;end
			tbl21.finfor = function(l)if type(l)~="string"or l==""then return nil;end;local K= tbl21 .finctrl();if K and type(K._finishers)=="table"then return K._finishers[l]and l or nil;end;K= misc and( misc :FindFirstChild("DataFinishers"));if K and(K:FindFirstChild(l))then return l;end;return nil;end

			tbl21.finplayable = function(arg)
				local v12 = tbl21.finctrl()
				return v12 ~= nil and type(v12._finishers) == "table" and v12._finishers[arg] ~= nil
			end

			tbl21.realfin = function(arg)
				local replion = Replion and Replion.Client and Replion.Client:GetReplion("Inventory")
				replion = replion and replion:Get({ "Inventory", "Sword" })
				if type(replion) ~= "table" then
					return false
				end

				for _, v12 in pairs(replion) do
					if type(v12) == "table" and v12.Name == arg and v12.Finisher == true and v12.CreatedAt ~= nil then
						return true
					end
				end

				return false
			end

			tbl21.finequip = function(arg)
				local v12 = tbl21.finfor(arg)
				if not v12 then
					return nil
				end
				tbl21.prefetch("Finishers", v12)
				local Data = fn16("Data")

				if Data then
					local Unlocked = Data:Get("Finishers.Unlocked")
					local tbl24 = {}
					local flag2 = false

					if type(Unlocked) == "table" then
						local v13, v14, v15 = ipairs(Unlocked)
						local flag3 = false

						for _, v16 in v13, v14, v15 do
							tbl24[#tbl24 + 1] = v16

							if v16 == v12 then
								flag3 = true
							end
						end

						flag2 = flag3
					end

					if not flag2 and type(Data._set) == "function" then
						tbl24[#tbl24 + 1] = v12
						Data:_set({ "Finishers", "Unlocked" }, tbl24)
					end

					if type(Data._update) == "function" and Data:Get({ "Finishers", "Equipped", v12 }) ~= true then
						Data:_update({ "Finishers", "Equipped" }, { [v12] = true })
					end
				end

				tbl21.finreq = tbl21.finreq or {}

				if v6 and type(v6.RequestFinisherEquip) == "function" and not tbl21.finreq[v12] and tbl21.realfin(v12) then
					tbl21.finreq[v12] = true

					tbl3.bindt(task.spawn(function()
						v6:RequestFinisherEquip({ Name = v12 })
					end))
				end

				return v12
			end

			tbl21.finhookup = function()
				if tbl21.finhooked then
					return
				end
				local v12 = tbl21.finctrl()
				if not v12 or type(v12.PlayFinisher) ~= "function" then
					return
				end
				tbl21.finorig = fn52(v12, "PlayFinisher", function(l,K,...) tbl21 .finlast= clock ();return  tbl21 .finorig(l,K,...);end)
				tbl21.finhooked = tbl21.finorig ~= nil
			end

			tbl21.findur = function(arg)
				local dataFinishers = misc and misc:FindFirstChild("DataFinishers")
				dataFinishers = dataFinishers and dataFinishers:FindFirstChild(arg)
				local attribute = dataFinishers and dataFinishers:GetAttribute("Duration")
				return type(attribute) == "number" and attribute or 6
			end

			tbl21.finhide = function(arg, arg2)
				if not arg then
					return
				end

				for _, descendant in ipairs(arg:GetDescendants()) do
					if descendant:IsA("BasePart") or descendant:IsA("Decal") then
						descendant.LocalTransparencyModifier = arg2 and 1 or 0
					elseif descendant:IsA("ParticleEmitter") or descendant:IsA("Trail") or descendant:IsA("Beam") or descendant:IsA("BillboardGui") then
						if arg2 then
							if descendant.Enabled then
								descendant:SetAttribute("__uaEmit", true)
								descendant.Enabled = false
							end
						elseif descendant:GetAttribute("__uaEmit") then
							descendant:SetAttribute("__uaEmit", nil)
							descendant.Enabled = true
						end
					end
				end
			end

			tbl21.finclone = function(h)local l=h.Archivable;h.Archivable=true;local K=h:Clone();h.Archivable=l;if not K then return nil;end;l=K:FindFirstChildOfClass("Humanoid");if not(l and(K:FindFirstChild("HumanoidRootPart")))then K:Destroy();return nil;end;for h,h in ipairs(K:GetDescendants())do if h:IsA("BaseScript")then h:Destroy();elseif h:IsA("BasePart")then h.CanCollide=false;h.CanQuery=false;h.Massless=true;h.LocalTransparencyModifier=0;if(h.Parent==K and h.Name~="HumanoidRootPart"or h.Name=="Handle"and(h.Parent:IsA("Accessory")))and h.Transparency>=1 then h.Transparency=0;end;elseif h:IsA("Decal")then h.Transparency=0;end;end;if l.MaxHealth<=0 then l.MaxHealth=100;end;l.Health=l.MaxHealth;l.DisplayDistanceType=Enum.HumanoidDisplayDistanceType.None;if not l:FindFirstChildOfClass("Animator")then Instance.new("Animator").Parent=l;end;K:SetAttribute("Dead",nil);return K;end

			tbl21.winfin = function(arg)
				if tbl21.finbusy then
					return
				end

				if not (tbl10.unlockall or tbl10.autoload or tbl10.swskin) then
					return
				end
				local v12 = tbl21.finfor(tbl21.cursword())
				if not v12 then
					return
				end
				local v13 = tbl21.findur(v12)
				local v14 = tbl3.safechar()
				local humanoidRootPart = v14 and v14:FindFirstChild("HumanoidRootPart")
				local flag2 = tbl21.prey ~= nil and tbl21.preyfor == arg

				if not (humanoidRootPart and arg and (flag2 or arg.Parent)) then
					flag2 = flag2 and tbl21.dropprey

					if flag2 then
						tbl21.dropprey()
					end

					return
				end

				tbl21.finhookup()
				tbl21.finbusy = true
				local v15 = clock()
				local prey

				if flag2 then
					prey = tbl21.prey
					tbl21.prey = nil
					tbl21.preyfor = nil
				else
					prey = tbl21.finclone(arg)
				end

				if not prey then
					tbl21.finbusy = false
					tbl3.notif("Finisher", "Couldn't copy your opponent, so the finisher was skipped.", 5)
					return
				end

				prey.Parent = Workspace

				tbl3.bindt(task.delay(0.1, function()
					local v16 = tbl21.finctrl()

					if (tbl21.finlast or 0) > v15 or not v16 or not v14.Parent then
						prey:Destroy()
						tbl21.finbusy = false
						return
					end

					if not tbl21.repasset("Finishers", v12) then
						prey:Destroy()
						tbl21.finbusy = false
						tbl3.notif("Finisher", ("Couldn't load the %s finisher."):format(v12), 5)
						return
					end

					if clock() - v15 > 3 then
						prey:Destroy()
						tbl21.finbusy = false
						tbl3.notif("Finisher", ("The %s finisher loaded too late. The next win should play it."):format(v12), 6)
						return
					end

					local v17 = tbl21.finclone(v14)

					if not v17 then
						prey:Destroy()
						tbl21.finbusy = false
						tbl3.notif("Finisher", "Couldn't copy your character, so the finisher was skipped.", 5)
						return
					end

					if not tbl21.finplayable(v12) then
						prey:Destroy()
						v17:Destroy()
						tbl21.finbusy = false
						tbl3.notif("Finisher", ("The %s finisher isn't loaded yet."):format(v12), 5)
						return
					end

					v17.Parent = Workspace
					tbl21.finhide(v14, true)
					local finshow = nil

					finshow = function()
						if tbl21.finshow ~= finshow then
							return
						end
						tbl21.finshow = nil
						prey:Destroy()
						v17:Destroy()
						tbl21.finhide(v14, false)
						tbl21.finbusy = false
					end

					tbl21.finshow = finshow
					tbl3.bindt(task.delay(v13 + 2, finshow))
					local position = humanoidRootPart.Position
					local lookVector = humanoidRootPart.CFrame.LookVector
					local getServerTimeNow = Workspace.GetServerTimeNow
					v16:PlayFinisher(v12, v17, prey, CFrame.new(position, position + Vector3.new(lookVector.X, 0, lookVector.Z)), getServerTimeNow(Workspace))

					if setthreadidentity and tbl3.baseident then
						setthreadidentity(tbl3.baseident)
					end
				end))
			end

			local function fn53()
				if tbl21.hooked then
					return
				end
				local v12 = nil

				for _, v13 in ipairs({
					{ "Common", "Utils", "Utilities", "RewardInfo" },
					{ "Common", "Utils", "RewardInfo" },
					{ "Common", "RewardInfo" },
				}) do
					v12 = fn13(fn14(ReplicatedStorage, table.unpack(v13)))
					if not (type(v12) == "table" and type(rawget(v12, "playerOwnsItem")) == "function") then
						v12 = nil
						continue
					end
					break
				end

				if not v12 then
					for _, descendant in ipairs(ReplicatedStorage:GetDescendants()) do
						if descendant:IsA("ModuleScript") and descendant.Name == "RewardInfo" then
							local v13 = fn13(descendant)
							if type(v13) == "table" and type(rawget(v13, "playerOwnsItem")) == "function" then
								v12 = v13
								break
							end
						end
					end
				end

				if v12 and not tbl21.rwdorig then
					tbl21.rwdmod = v12
					tbl21.rwdorig = fn52(v12, "playerOwnsItem", function(l,K,...)if  tbl10 .unlockall and type(K)=="table"and(l==nil or l== localPlayer )then local p=K.Type;if p=="Sword"or p=="Explosion"or p=="Finisher"or p=="SwordAccessory"then return true;end;end;return  tbl21 .rwdorig(l,K,...);end)

					if not tbl21.rwdorig then
						local tbl24 = {}

						for k, v13 in pairs(v12) do
							tbl24[#tbl24 + 1] = tostring(k) .. (type(v13) == "function" and "()" or "")
						end

						table.sort(tbl24)
						tbl3.logwev("uaHookReward", 10, "UnlockAll", "failed to hook RewardInfo.playerOwnsItem; module has: " .. table.concat(tbl24, ", "))
					end
				end

				if v6 then
					if not tbl21.seteqorig then
						tbl21.seteqorig = fn52(v6, "SetEquipped", function(l,K,p)if not  tbl10 .unlockall then return  tbl21 .seteqorig(l,K,p);end;local E,k;if type(K)=="table"then E,k=K.ItemType or K.Type,K.Name;else k,E=( fn20 (p,K)),K;end;if E=="Ability"or E=="Emote"or not E or not k then return  tbl21 .seteqorig(l,K,p);end;if  fn29 (E,k)then return  tbl21 .seteqorig(l,K,p);end; fn27 (E,k);return true;end)

						if not tbl21.seteqorig then
							tbl3.logwev("uaHookSetEq", 10, "UnlockAll", "failed to hook ShopAPI.SetEquipped")
						end
					end

					if not tbl21.accorig then
						tbl21.accorig = fn52(v6, "ToggleSwordAccessory", function(l)if not  tbl10 .unlockall then return  tbl21 .accorig(l);end; tbl21 .noacc=not  tbl21 .noacc; tbl21 .equip.NoAcc= tbl21 .noacc;if  fn15 then  fn15 ();end; tbl21 .applyacc();return true;end)
					end
				end

				tbl21.finhookup()
				tbl21.hooked = true
			end

			local function arm()
				fn39()
				fn53()
				fn30()
			end

			tbl21.unhook = function()
				tbl10.unlockall = false
				tbl10.forceemo = false
				tbl10.emospam = false
				tbl10.emoteonly = false
				tbl10.autoload = false

				if tbl21.rwdmod and tbl21.rwdorig then
					tbl21.rwdmod.playerOwnsItem = tbl21.rwdorig
				end

				if v6 and tbl21.seteqorig then
					v6.SetEquipped = tbl21.seteqorig
				end

				if v6 and tbl21.accorig then
					v6.ToggleSwordAccessory = tbl21.accorig
				end

				if v7 and tbl21.emoplayorig then
					v7.Play = tbl21.emoplayorig
				end

				if v7 and tbl21.emostoporig then
					v7.Stop = tbl21.emostoporig
				end

				if tbl21.explmod and tbl21.explorig then
					tbl21.explmod.PlayExplosion = tbl21.explorig
				end

				if tbl21.fcmod and tbl21.finorig then
					tbl21.fcmod.PlayFinisher = tbl21.finorig
				end

				tbl21.rwdorig = nil
				tbl21.seteqorig = nil
				tbl21.accorig = nil
				tbl21.emoplayorig = nil
				tbl21.emostoporig = nil
				tbl21.explorig = nil
				tbl21.finorig = nil
				tbl21.hooked = false
				tbl21.explhooked = false
				tbl21.finhooked = false
				tbl21.autoran = false
				tbl21.boot = false

				for _, offconn in ipairs(tbl21.offconns) do
					offconn:Enable()
				end

				if tbl21.finshow then
					tbl21.finshow()
				end

				if tbl21.dropprey then
					tbl21.dropprey()
				end

				if tbl21.loaderblur then
					tbl21.loaderblur:Destroy()
					tbl21.loaderblur = nil
				end

				if tbl21.loadergui then
					tbl21.loadergui:Destroy()
					tbl21.loadergui = nil
				end

				tbl21.finhide(tbl3.safechar(), false)
			end

			tbl21.arm = arm
			unhook = tbl21.unhook

			local function fn54(arg)
				for _, v12 in ipairs({ "Activated", "MouseButton1Click" }) do
					local v13 = getconnections(arg[v12])

					if v13 then
						for _, v14 in ipairs(v13) do
							if not v14.ForeignState and v14.Function and islclosure(v14.Function) then
								local v15 = getupvalues(v14.Function)
								if type(v15) ~= "table" then
									continue
								end

								for _, v16 in pairs(v15) do
									if type(v16) == "table" and (rawget(v16, "_virtualItems") ~= nil or rawget(v16, "_selectedItem") ~= nil) then
										return v16
									end
								end
							end
						end
					end
				end
			end

			local function fn55(arg)
				local tbl24 = {}
				if not getconnections then
					return tbl24
				end

				for _, v12 in ipairs({ "Activated", "MouseButton1Click" }) do
					local v13 = getconnections(arg[v12])

					if v13 then
						for _, v14 in ipairs(v13) do
							if not v14.ForeignState and v14.Function then
								tbl24[#tbl24 + 1] = v14.Function
								v14:Disable()
								tbl21.offconns[#tbl21.offconns + 1] = v14
							end
						end
					end
				end

				return tbl24
			end

			local function fn56()
				local flag2 = tbl10.unlockall == true

				for _, offconn in ipairs(tbl21.offconns) do
					if flag2 then
						offconn:Disable()
					else
						offconn:Enable()
					end
				end
			end

			local function fn57(arg)
				if not (arg and arg.Select) then
					return
				end

				local function fn58()
					local selectedItem = arg._selectedItem
					if not selectedItem then
						return
					end
					arg:Select(table.clone(selectedItem), true)
				end

				fn58()
				task.defer(fn58)
				task.delay(0.1, fn58)
			end

			local function fn58()
				if tbl21.guihooked or tbl21.guibusy then
					return
				end
				tbl21.guibusy = true

				tbl3.bindt(task.spawn(function()
					local playerGui = localPlayer:WaitForChild("PlayerGui", 20)
					local shop = playerGui and playerGui:WaitForChild("Shop", 20)
					shop = shop and shop:WaitForChild("Holder", 20)
					local infoBG = shop and shop:WaitForChild("InfoBG", 20)
					local buyButton = infoBG and infoBG:WaitForChild("BuyButton", 20)

					if buyButton and getconnections then
						local n3 = clock() + 10

						while clock() < n3 do
							local v12, v13, v14 = ipairs(getconnections(buyButton.Activated) or {})
							local n4 = 0

							for _, v15 in v12, v13, v14 do
								if not v15.ForeignState and v15.Function then
									n4 += 1
								end
							end

							if not (n4 > 0) then
								task.wait(0.2)
								continue
							end
							break
						end
					end

					tbl21.guibusy = false
					if not buyButton then
						tbl3.logwev("uaHookGui", 30, "UnlockAll", "Shop.Holder.InfoBG.BuyButton never appeared - shop hooks skipped")
						return
					end
					tbl21.guihooked = true
					local v12 = fn54(buyButton)
					local v13 = fn55(buyButton)

					local function fn59()
						for _, v14 in ipairs(v13) do
							v14()
						end
					end

					tbl3.bind(buyButton.Activated:Connect(function()if not  tbl10 .unlockall then return;end; v12 = v12 or( fn54 ( buyButton ));local l= v12 and  v12 ._selectedItem;if not l then  fn59 ();return;end;local K=type(l.ItemInfo)=="table"and l.ItemInfo or nil;local p,E=l.type or l.Type or K and(K.ItemType or K.Type),l.name or l.Name or K and K.Name;if p=="Ability"or p=="AbilityFreeTrial"then  fn59 ();return;end;if p=="Sword"or p=="Explosion"then if  fn29 (p,E)then  fn59 ();return;end; fn27 (p,E);elseif p=="Emote"then  fn46 (E);else  fn59 ();return;end; fn57 ( v12 );end))
					local equips = infoBG and infoBG:FindFirstChild("Equips")
					local equipAccessory = equips and equips:FindFirstChild("EquipAccessory")

					if equipAccessory then
						fn55(equipAccessory)
						tbl3.bind(equipAccessory.Activated:Connect(function()if not  tbl10 .unlockall then return;end;if  v6 and  v6 .ToggleSwordAccessory then  v6 :ToggleSwordAccessory();end; fn57 ( v12 );end))
					end

					local tbl24 = { Sword = "SwordSkins", Explosion = "ExplosionSkins", Emote = "Emotes" }

					local function fn60()
						v12 = v12 or fn54(buyButton)
						local selectedItem = v12 and v12._selectedItem
						if not selectedItem then
							return nil
						end
						local itemInfo = type(selectedItem.ItemInfo) == "table" and selectedItem.ItemInfo or nil
						local type_ = selectedItem.type or selectedItem.Type or itemInfo and (itemInfo.ItemType or itemInfo.Type)
						local name = selectedItem.name or selectedItem.Name or itemInfo and itemInfo.Name
						return type_, name, selectedItem.key or type_ and name and fn19(type_, name) or nil
					end

					equips = equips and equips:FindFirstChild("Finisher")

					if equips and equips:IsA("GuiButton") then
						fn55(equips)
						tbl3.bind(equips.Activated:Connect(function()if not  tbl10 .unlockall then return;end;local l,K= fn60 ();if l~="Sword"or not K or not  tbl21 .finfor(K)then return;end;l= fn16 ("Data");local p= Replion and  Replion .None;if not(l and p and type(l._update)=="function")then return;end;local E=l:Get({"Finishers","Equipped",K})==true;l:_update({"Finishers","Equipped"},{[K]=E and p or true});if not E then  tbl21 .finequip(K);end; fn57 ( v12 );end))
					end

					shop = shop and shop:FindFirstChild("Favorite")

					if shop and shop:IsA("GuiButton") then
						fn55(shop)
						tbl3.bind(shop.Activated:Connect(function()if not  tbl10 .unlockall then return;end;local l,K= fn60 ();local p=l and  tbl24 [l];if not(K and p)then return;end;l= fn16 ("Data");local E= Replion and  Replion .None;if not(l and E)then return;end;l:_update({p,"Favorites"},{[K]=l:Get({p,"Favorites",K})==true and E or true}); fn57 ( v12 );end))
					end

					infoBG = infoBG and infoBG:FindFirstChild("Delete")

					if infoBG and infoBG:IsA("GuiButton") then
						fn55(infoBG)
						tbl3.bind(infoBG.Activated:Connect(function()if not  tbl10 .unlockall then return;end;local l,K,p= fn60 ();if not(l and K and p and  tbl24 [l])then return;end;if  v12 and type( v12 ._canDelete)=="function"then if not  v12 ._canDelete( v12 ,l,p)then  tbl3 .notif("Unlock All","You can't delete that item.",4);return;end;end;local E= fn16 ("Inventory");local k= Replion and  Replion .None;if not(E and k)then return;end;E:_update({"Inventory",l},{[p]=k});if  tbl21 .owned and  tbl21 .owned[l]then  tbl21 .owned[l][K]=nil;end;if  tbl21 .equip[l]==K then  tbl21 .equip[l]=nil;if  fn15 then  fn15 ();end;end;if l=="Sword"and  tbl10 .swname==K then  tbl10 .swskin=false; tbl10 .swname="";elseif l=="Explosion"and  tbl21 .explname==K then  tbl21 .explname=nil;end; fn57 ( v12 );end))
					end

					fn56()
					playerGui = playerGui and playerGui:WaitForChild("EmoteWheel", 20)
					playerGui = playerGui and playerGui:WaitForChild("List", 20)
					playerGui = playerGui and playerGui:WaitForChild("Content", 20)
					playerGui = playerGui and playerGui:WaitForChild("Folder", 20)

					if playerGui then
						local function fn61(arg)
							local v14 = getconnections(arg.Activated)
							if not v14 then
								return
							end

							for _, v15 in ipairs(v14) do
								if not v15.ForeignState and v15.Function and islclosure(v15.Function) then
									local v16 = getupvalues(v15.Function)

									if type(v16) == "table" then
										local n3 = 0

										for k in pairs(v16) do
											if type(k) == "number" and k > n3 then
												n3 = k
											end
										end

										local v17 = nil
										local v18 = nil

										for i = 1, n3 do
											local v19 = v16[i]

											if type(v19) == "string" and not v17 then
												v17 = v19
											end

											if type(v19) == "table" and (rawget(v19, "selected") ~= nil or rawget(v19, "page") ~= nil) then
												v18 = v19
											end
										end

										if v17 and v18 then
											return v17, v18
										end
									end
								end
							end
						end

						local function fn62(child)
							if not child:IsA("GuiButton") or child:GetAttribute("__uaHooked") then
								return
							end
							child:SetAttribute("__uaHooked", true)
							tbl3.bind(child.Activated:Connect(function()if not( tbl10 .unlockall or  tbl10 .emoteonly or  tbl10 .autoload)then return;end;local l,K= fn61 ( child );if not(l and K)then return;end;local p=(tonumber(K.selected)or 1)+((tonumber(K.page)or 1)-1)*8; fn51 ( fn20 (l),p);end))
						end

						for _, child in ipairs(playerGui:GetChildren()) do
							fn62(child)
						end

						tbl3.bind(playerGui.ChildAdded:Connect(fn62))
					end
				end))
			end

			local function fn59()
				if tbl21.boot then
					return
				end
				tbl21.boot = true
				fn12()
				fn39()
				task.wait()
				fn53()
				task.wait()
				fn58()
				fn56()
			end

			local function fn60()
				local tbl24 = {
					done = false,
					finish = function()
					end,
					setStatus = function()
					end,
				}

				local screenGui = Instance.new("ScreenGui")
				screenGui.Name = "\0RiseUnlock"
				screenGui.IgnoreGuiInset = true
				screenGui.ResetOnSpawn = false
				screenGui.DisplayOrder = 999999999
				screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
				screenGui.Parent = fn6 and fn6() or CoreGui
				local frame = Instance.new("Frame")
				frame.Size = UDim2.fromScale(1, 1)
				frame.BackgroundColor3 = Color3.fromRGB(2, 12, 20)
				frame.BackgroundTransparency = 1
				frame.BorderSizePixel = 0
				frame.Parent = screenGui
				local blurEffect = Instance.new("BlurEffect")
				blurEffect.Size = 0
				blurEffect.Parent = Lighting
				local frame2 = Instance.new("Frame")
				frame2.AnchorPoint = Vector2.new(0.5, 0.5)
				frame2.Position = UDim2.fromScale(0.5, 0.5)
				frame2.Size = UDim2.fromOffset(252, 172)
				frame2.BackgroundColor3 = color
				frame2.BackgroundTransparency = 1
				frame2.BorderSizePixel = 0
				frame2.Parent = screenGui
				tbl3.corner(frame2, 20)
				local uiGradient = Instance.new("UIGradient")
				uiGradient.Rotation = 90
				local color4 = Color3.fromRGB
				uiGradient.Color = ColorSequence.new(Color3.fromRGB(16, 56, 88), color4(3, 24, 42))
				uiGradient.Parent = frame2
				local uiStroke = Instance.new("UIStroke")
				uiStroke.Color = Color3.fromRGB(255, 255, 255)
				uiStroke.Thickness = 1.5
				uiStroke.Transparency = 1
				uiStroke.Parent = frame2
				local frame3 = Instance.new("Frame")
				frame3.AnchorPoint = Vector2.new(0.5, 0)
				frame3.Position = UDim2.new(0.5, 0, 0, 28)
				frame3.Size = UDim2.fromOffset(46, 46)
				frame3.BackgroundTransparency = 1
				frame3.Parent = frame2
				local tbl25 = {}
				local n3 = 12

				for i = 1, 12 do
					local frame4 = Instance.new("Frame")
					frame4.AnchorPoint = Vector2.new(0.5, 0.5)
					frame4.Size = UDim2.fromOffset(4, 12)
					frame4.BackgroundColor3 = accent
					frame4.BackgroundTransparency = 1
					frame4.BorderSizePixel = 0
					local v12 = rad((i - 1) * 360 / n3)
					frame4.Position = UDim2.new(0.5, sin(v12) * 15, 0.5, -cos(v12) * 15)
					frame4.Rotation = (i - 1) * 360 / n3
					local uiCorner = Instance.new("UICorner")
					uiCorner.CornerRadius = UDim.new(1, 0)
					uiCorner.Parent = frame4
					frame4.Parent = frame3
					tbl25[i] = frame4
				end

				local textLabel = Instance.new("TextLabel")
				textLabel.AnchorPoint = Vector2.new(0.5, 0)
				textLabel.Position = UDim2.new(0.5, 0, 0, 92)
				textLabel.Size = UDim2.new(1, -24, 0, 22)
				textLabel.BackgroundTransparency = 1
				textLabel.Font = Enum.Font.GothamBold
				textLabel.TextSize = 16
				textLabel.TextColor3 = color2
				textLabel.TextTransparency = 1
				textLabel.Text = "Unlock All"
				textLabel.Parent = frame2
				local textLabel2 = Instance.new("TextLabel")
				textLabel2.AnchorPoint = Vector2.new(0.5, 0)
				textLabel2.Position = UDim2.new(0.5, 0, 0, 118)
				textLabel2.Size = UDim2.new(1, -28, 0, 40)
				textLabel2.BackgroundTransparency = 1
				textLabel2.Font = Enum.Font.Gotham
				textLabel2.TextSize = 12
				textLabel2.TextColor3 = color3
				textLabel2.TextTransparency = 1
				textLabel2.TextWrapped = true
				textLabel2.Text = "Unlocking swords, explosions & emotes..."
				textLabel2.Parent = frame2
				local tweenInfo = TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
				TweenService:Create(frame, tweenInfo, { BackgroundTransparency = 0.45 }):Play()
				TweenService:Create(frame2, tweenInfo, { BackgroundTransparency = 0.2 }):Play()
				TweenService:Create(uiStroke, tweenInfo, { Transparency = 0.55 }):Play()
				TweenService:Create(textLabel, tweenInfo, { TextTransparency = 0 }):Play()
				TweenService:Create(textLabel2, tweenInfo, { TextTransparency = 0.15 }):Play()
				TweenService:Create(blurEffect, tweenInfo, { Size = 16 }):Play()
				tbl21.loadergui = screenGui
				tbl21.loaderblur = blurEffect
				local v12 = clock()
				local v13 = tbl3.bind(RunService.RenderStepped:Connect(function()local l= clock ()*1.15%1;for K=1, n3 ,1 do local p=((K-1)/ n3 -l)%1; tbl25 [K].BackgroundTransparency=0.1+0.82*p;end;end))

				tbl24.setStatus = function(text)
					textLabel2.Text = text
				end

				tbl24.finish = function()
					if tbl24.done then
						return
					end
					tbl24.done = true
					local n4 = 0.6 - clock() - v12

					if n4 > 0 then
						task.wait(n4)
					end

					local tweenInfo2 = TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
					TweenService:Create(frame, tweenInfo2, { BackgroundTransparency = 1 }):Play()
					TweenService:Create(frame2, tweenInfo2, { BackgroundTransparency = 1, Position = UDim2.fromScale(0.5, 0.54) }):Play()
					TweenService:Create(uiStroke, tweenInfo2, { Transparency = 1 }):Play()
					TweenService:Create(textLabel, tweenInfo2, { TextTransparency = 1 }):Play()
					TweenService:Create(textLabel2, tweenInfo2, { TextTransparency = 1 }):Play()
					TweenService:Create(blurEffect, tweenInfo2, { Size = 0 }):Play()
					task.wait(0.45)

					if v13 then
						v13:Disconnect()
					end

					blurEffect:Destroy()
					screenGui:Destroy()
				end

				return tbl24
			end

			fn9 = function() tbl10 .unlockall=true; tbl21 .everunlocked=true; tbl21 .uagen=( tbl21 .uagen or 0)+1;local l= tbl21 .uagen; fn56 ();local K= fn60 ();local p=false;local E=nil;E=function(k,a)if p then return;end;p=true;if setthreadidentity and  tbl3 .baseident then setthreadidentity( tbl3 .baseident);end;K.finish(); tbl3 .notif("Unlock All",k,a or 5);end;local function k()if p then return;end;p=true;if setthreadidentity and  tbl3 .baseident then setthreadidentity( tbl3 .baseident);end;K.finish();end; tbl3 .bindt(task.delay(20,function()E("Done. If something is missing, rejoin and turn it on again.",6);end)); tbl3 .bindt(task.spawn(function() fn12 ();task.wait();if  tbl21 .uagen~=l then return k();end; fn59 ();if  tbl21 .uagen~=l then return k();end;K.setStatus("Loading swords and explosions...");for p=1,3,1 do  tbl21 .injected=false; fn40 ();if not  tbl21 .failed or  tbl21 .uagen~=l then break;end;if p<3 then K.setStatus("Retrying... ("..p.."/3)"); fn12 ();task.wait(0.8);end;end;task.wait();if  tbl21 .uagen~=l then return k();end; fn49 ();local p={"Sword","Explosion"};for a,d in ipairs(p)do a= tbl21 .equip[d];if type(a)=="string"and a~=""then  fn27 (d,a,true);end;if  tbl21 .uagen~=l then return k();end;end;if  tbl21 .equip.NoAcc then  tbl21 .noacc=true; tbl21 .applyacc();end;K.setStatus("Loading emotes..."); tbl3 .bindt(task.delay(3,function()if  tbl21 .uagen~=l then return;end; fn50 ();end));E("Done. Open your inventory and equip anything.",6);end));end

			fn10 = function()
				tbl10.unlockall = false
				tbl21.uagen = (tbl21.uagen or 0) + 1
				tbl21.explname = nil
				tbl21.injected = false
				tbl21.failed = false

				if not tbl10.autoload and tbl21.skinmine then
					tbl10.swskin = false
					tbl10.swname = ""
					tbl21.skinmine = false
				end

				fn56()
				tbl3.notif("Unlock All", "Off. Items already unlocked stay until you rejoin.", 4)
			end

			fn11 = function(l) tbl10 .autoload=true;if  tbl10 .unlockall or  tbl21 .autoran then return;end; tbl21 .autoran=true; tbl3 .bindt(task.spawn(function() fn12 ();task.wait(); fn39 (); fn53 (); fn58 (); fn30 (); fn49 ();local K={"Sword","Explosion"};for p,E in ipairs(K)do p= tbl21 .equip[E];if type(p)=="string"and p~=""then  fn27 (E,p,true);end;end;if  tbl21 .equip.NoAcc then  tbl21 .noacc=true; tbl21 .applyacc();end; fn50 ();for K,K in pairs( tbl21 .wheel)do if type(K)=="string"and K~=""then  fn26 ("Emote",K);end;end;if setthreadidentity and  tbl3 .baseident then setthreadidentity( tbl3 .baseident);end;if l then  tbl3 .notif("Auto Load Last Loadout","Your last sword, explosion and emotes are back.",4);end;end));end

			local function fn61()
				tbl10.autoload = false
				tbl21.autoran = false

				if not tbl10.unlockall and tbl21.skinmine then
					tbl10.swskin = false
					tbl10.swname = ""
					tbl21.skinmine = false
					tbl21.explname = nil
				end
			end

			local function fn62(arg, arg2)
				if type(arg) ~= "string" or arg == "" then
					return nil
				end
				local str3 = arg:lower()

				for _, v12 in ipairs(arg2) do
					if v12:lower() == str3 then
						return v12
					end
				end

				for _, v12 in ipairs(arg2) do
					if v12:lower():find(str3, 1, true) then
						return v12
					end
				end

				return nil
			end

			tbl3.skinsword = function(arg)
				fn12()
				fn39()
				fn53()
				fn30()
				local v12 = tbl3.initsword()
				if not v12 then
					tbl3.notif("Skins", "Swords aren't ready yet. Try again in a second.", 5)
					return
				end
				local tbl24 = {}
				local collection = v12:GetCollection()

				if type(collection) == "table" then
					for k in pairs(collection) do
						tbl24[#tbl24 + 1] = k
					end
				end

				local v13 = fn62(arg, tbl24)

				if not v13 then
					if v12:GetSword(arg) then
						v13 = arg
					end
				end

				if not v13 or v13 == "" then
					tbl3.notif("Skins", ("No sword called \"%s\". %d swords loaded."):format(tostring(arg), #tbl24), 6)
					return
				end

				if not tbl3.safechar() then
					tbl3.notif("Skins", "Join a round first.", 5)
					return
				end
				tbl10.swskin = true
				tbl10.swname = v13
				tbl21.skinmine = false
				tbl3.hookslash()
				tbl3.skinloop()
				tbl3.setswattr(v13)

				if tbl9.swctrl and tbl9.swctrl.SetSword then
					tbl9.swctrl:SetSword(v13)
				end

				local v14 = tbl3.applysword()
				fn26("Sword", v13)
				fn25("Sword", v13)
				tbl21.ensureeq("Sword", v13)
				tbl21.finequip(v13)
				tbl21.equip.Sword = v13

				if fn15 then
					fn15()
				end

				if setthreadidentity and tbl3.baseident then
					setthreadidentity(tbl3.baseident)
				end

				tbl3.bindt(task.delay(0.4, function()
					local v15 = tbl3.safechar()

					if v15 and v15:FindFirstChild(v13) then
						tbl3.notif("Skins", ("Equipped %s."):format(v13), 3)
					elseif not v14 then
						tbl3.notif("Skins", ("Couldn't equip %s. The game may not have sent the model."):format(v13), 7)
					else
						tbl3.notif("Skins", ("%s didn't show up. The game blocked it."):format(v13), 6)
					end
				end))
			end

			tbl3.applyexpl = function(arg)
				fn12()
				fn39()
				fn53()
				fn30()
				local DataExplosions = fn21("DataExplosions")
				local v12 = fn62(arg, DataExplosions)
				if not v12 or v12 == "" then
					tbl3.notif("Skins", ("No explosion called \"%s\". %d explosions loaded."):format(tostring(arg), #DataExplosions), 6)
					return
				end
				fn27("Explosion", v12)

				if setthreadidentity and tbl3.baseident then
					setthreadidentity(tbl3.baseident)
				end

				tbl3.bindt(task.spawn(function()
					tbl3.notif("Skins", repasset("Explosions", v12) and ("Explosion set to %s."):format(v12) or ("%s is set, but the game didn't send it. It may not show."):format(v12), 5)
				end))
			end

			tbl3.emoteonly = function(arg)
				if not arg then
					return
				end
				fn12()
				fn39()
				fn53()
				fn58()
				fn30()
				fn50()
				local n3 = 0

				for _, v12 in pairs(tbl21.wheel) do
					if type(v12) == "string" and v12 ~= "" then
						fn26("Emote", v12)
						n3 += 1
					end
				end

				if setthreadidentity and tbl3.baseident then
					setthreadidentity(tbl3.baseident)
				end

				tbl3.notif("Skins", n3 > 0 and ("%d emotes ready. Open your emote wheel."):format(n3) or "No emotes saved yet.", 4)
			end

			toggles.unlockall:OnChanged(function(arg)
				if arg then
					fn9()
				else
					fn10()
				end

				tbl3.qsave()
			end)

			toggles.equipautoload:OnChanged(function(arg)
				if arg then
					fn11(true)
				else
					fn61()
				end

				tbl3.qsave()
			end)

			local function fn63()return  max (0.5-( clamp ( tbl10 .emospd or 5,1,10)-1)*0.04888888888888889,0.2);end

			local function fn64()
				if tbl21.spamconn then
					tbl21.spamconn:Disconnect()
					tbl21.spamconn = nil
				end
			end

			local function fn65()
				fn64()
				tbl21.spamlast = 0
				tbl21.spamconn = tbl3.bind(RunService.Heartbeat:Connect(function()if not  tbl10 .emospam or not  tbl21 .spamemo then return;end;if not  tbl3 .isalive()then return;end;local l= tbl3 .safehum();if l and l.MoveDirection.Magnitude>0.1 then if  tbl21 .trove then  tbl21 .trove:Clean(); tbl21 .trove=nil;end; tbl21 .activeemo=nil;return;end;local l= clock ();if l-( tbl21 .spamlast or 0)< fn63 ()then return;end; tbl21 .spamlast=l; fn46 ( tbl21 .spamemo);end))
			end

			toggles.forceemote:OnChanged(function(forceemo)
				tbl10.forceemo = forceemo

				if forceemo then
					arm()
				end

				tbl3.qsave()
			end)

			toggles.emotespam:OnChanged(function(emospam)
				tbl10.emospam = emospam

				if emospam then
					arm()
					fn65()
				else
					fn64()
				end

				tbl3.qsave()
			end)

			options.emotespamspeed:OnChanged(function(emospd)
				tbl10.emospd = emospd
				tbl3.qsave()
			end)

			toggles.emoteonspawn:OnChanged(function(emospawn)
				tbl10.emospawn = emospawn

				if emospawn then
					arm()
				end

				tbl3.qsave()
			end)

			tbl10.emospawn = toggles.emoteonspawn.Value

			tbl3.bind(localPlayer.CharacterAdded:Connect(function()
				if not tbl10.emospawn then
					return
				end
				task.wait(1)
				local n1 = tbl21.wheel and (tbl21.wheel["1"] or tbl21.wheel[1]) or tbl21.spamemo

				if type(n1) == "string" and n1 ~= "" then
					fn46(n1)
				end
			end))

			if alive then
				local v12 = tbl3.safechar()
				tbl21.lost = not (v12 and v12.Parent == alive)
				local function fn66(l)local K= Players :GetPlayerFromCharacter(l);if not K or K== localPlayer then return false;end;if l:GetAttribute("IsDoppelganger")then return false;end;if l:GetAttribute("IsEncryptedClone")then return false;end;if l:GetAttribute("Dead")then return false;end;return true;end
				local function dropprey()if  tbl21 .prey then  tbl21 .prey:Destroy(); tbl21 .prey=nil;end; tbl21 .preyfor=nil;end
				tbl21.dropprey = dropprey
				local function fn67(l)if  tbl21 .preyfor~=l or l.Parent~= alive then return;end;local K= tbl21 .finclone(l);if not K then return;end;if  tbl21 .prey then  tbl21 .prey:Destroy();end; tbl21 .prey=K;end
				local function fn68()if not( tbl10 .unlockall or  tbl10 .autoload or  tbl10 .swskin)then return;end;local l= tbl21 .finfor( tbl21 .cursword());if l then  tbl21 .prefetch("Finishers",l);end;end
				local function fn69(l)if not( tbl10 .unlockall or  tbl10 .autoload or  tbl10 .swskin)then return;end; fn68 ();if not l or  tbl21 .preyfor==l then return;end; dropprey (); tbl21 .preyfor=l; fn67 (l); tbl3 .bindt(task.delay(3,function() fn67 (l);end));end
				local function fn70()local l= tbl3 .safechar();if not l or l.Parent~= alive then return 0,nil;end;local l,K=0;for p,p in ipairs( alive :GetChildren())do if  fn66 (p)then l,K=l+1,p;end;end;return l,K;end
				tbl3.bind(alive.ChildRemoved:Connect(function(l)local K= Players :GetPlayerFromCharacter(l);if not K then return;end;if K== localPlayer then  tbl21 .lost=true;return;end;K= tbl3 .safechar(); tbl21 .lost=not(K and K.Parent== alive and not K:GetAttribute("Dead"));if  tbl21 .lost then return;end;local K,p= fn70 ();if K==1 then  fn69 (p);return;end;if K>1 then return;end; tbl21 .winfin(l);end))
				tbl3.bind(alive.ChildAdded:Connect(function(l)if l== localPlayer .Character then  tbl21 .lost=false; dropprey (); fn68 (); tbl3 .bindt(task.delay(3, fn68 ));end;local l,K= fn70 ();if l==1 then  fn69 (K);end;end))
			end

			tbl10.forceemo = toggles.forceemote.Value

			if toggles.emotespam.Value then
				tbl10.emospam = true
				fn65()
			end

			if tbl10.forceemo or tbl10.emospam or tbl10.emospawn or tbl10.emoteonly then
				tbl3.bindt(task.spawn(arm))
			end
		end
	end

	_G.stagesh = "unlock"

	v:OnUnload(function()
		v2:Save("autosave")
		tbl3.cleanup()

		for _, connection in pairs(tbl7.Connections) do
			connection:Disconnect()
		end

		for _, thread in pairs(tbl7.Threads) do
			task.cancel(thread)
		end

		_G.cuties = nil
		_G.RiseLibrary = nil
		_G.RiseWindow = nil
		_G.RiseHeartbeat = nil
		_G.RiseJob = nil
		_G.RiseBoot = nil
	end)

	Menu:AddButton("Unload", function()
		v:Unload()
	end)

	_G.RiseBoot = nil
	_G.stagesh = "ready"
	if v.Loader then v.Loader:Finish() end
end

fn()
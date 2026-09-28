repeat
task.wait(1)
until game:IsLoaded()

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

local GEN = (getgenv and getgenv()) or _G
GEN.CVT_Authorized = false

local bit32lib = bit32

if not bit32lib then
error("bit32 library is unavailable in this executor.")
end

local function u32(n)
n = n % 4294967296

if n < 0 then
    n = n + 4294967296
end

return n


end

local function bxor(...)
local args = {...}
local result = args[1] or 0

for i = 2, #args do
    result = bit32lib.bxor(result, args[i])
end

return u32(result)


end

local function band(...)
local args = {...}
local result = args[1] or 0

for i = 2, #args do
    result = bit32lib.band(result, args[i])
end

return u32(result)


end

local function bnot(x)
return u32(bit32lib.bnot(x))
end

local function rshift(x, n)
return bit32lib.rshift(x, n)
end

local function lshift(x, n)
return u32(bit32lib.lshift(x, n))
end

local function rrotate(x, n)
return bit32lib.rrotate(x, n)
end

local K = {
0x428a2f98, 0x71374491, 0xb5c0fbcf, 0xe9b5dba5,
0x3956c25b, 0x59f111f1, 0x923f82a4, 0xab1c5ed5,
0xd807aa98, 0x12835b01, 0x243185be, 0x550c7dc3,
0x72be5d74, 0x80deb1fe, 0x9bdc06a7, 0xc19bf174,
0xe49b69c1, 0xefbe4786, 0x0fc19dc6, 0x240ca1cc,
0x2de92c6f, 0x4a7484aa, 0x5cb0a9dc, 0x76f988da,
0x983e5152, 0xa831c66d, 0xb00327c8, 0xbf597fc7,
0xc6e00bf3, 0xd5a79147, 0x06ca6351, 0x14292967,
0x27b70a85, 0x2e1b2138, 0x4d2c6dfc, 0x53380d13,
0x650a7354, 0x766a0abb, 0x81c2c92e, 0x92722c85,
0xa2bfe8a1, 0xa81a664b, 0xc24b8b70, 0xc76c51a3,
0xd192e819, 0xd6990624, 0xf40e3585, 0x106aa070,
0x19a4c116, 0x1e376c08, 0x2748774c, 0x34b0bcb5,
0x391c0cb3, 0x4ed8aa4a, 0x5b9cca4f, 0x682e6ff3,
0x748f82ee, 0x78a5636f, 0x84c87814, 0x8cc70208,
0x90befffa, 0xa4506ceb, 0xbef9a3f7, 0xc67178f2
}

local H0 = {
0x6a09e667,
0xbb67ae85,
0x3c6ef372,
0xa54ff53a,
0x510e527f,
0x9b05688c,
0x1f83d9ab,
0x5be0cd19
}

local function sha256(message)
message = tostring(message)

local bytes = {string.byte(message, 1, #message)}
local bitLength = #bytes * 8

table.insert(bytes, 0x80)

while (#bytes % 64) ~= 56 do
    table.insert(bytes, 0)
end

local high = math.floor(bitLength / 4294967296)
local low = bitLength % 4294967296

for shift = 24, 0, -8 do
    table.insert(bytes, band(rshift(high, shift), 0xFF))
end

for shift = 24, 0, -8 do
    table.insert(bytes, band(rshift(low, shift), 0xFF))
end

local h = {
    H0[1], H0[2], H0[3], H0[4],
    H0[5], H0[6], H0[7], H0[8]
}

local w = table.create and table.create(64) or {}

for chunk = 1, #bytes, 64 do
    for i = 0, 15 do
        local index = chunk + i * 4

        w[i + 1] = u32(
            lshift(bytes[index], 24) +
            lshift(bytes[index + 1], 16) +
            lshift(bytes[index + 2], 8) +
            bytes[index + 3]
        )
    end

    for i = 17, 64 do
        local x = w[i - 15]
        local y = w[i - 2]

        local s0 = bxor(
            rrotate(x, 7),
            rrotate(x, 18),
            rshift(x, 3)
        )

        local s1 = bxor(
            rrotate(y, 17),
            rrotate(y, 19),
            rshift(y, 10)
        )

        w[i] = u32(
            w[i - 16] +
            s0 +
            w[i - 7] +
            s1
        )
    end

    local a = h[1]
    local b = h[2]
    local c = h[3]
    local d = h[4]
    local e = h[5]
    local f = h[6]
    local g = h[7]
    local hh = h[8]

    for i = 1, 64 do
        local S1 = bxor(
            rrotate(e, 6),
            rrotate(e, 11),
            rrotate(e, 25)
        )

        local ch = bxor(
            band(e, f),
            band(bnot(e), g)
        )

        local temp1 = u32(
            hh +
            S1 +
            ch +
            K[i] +
            w[i]
        )

        local S0 = bxor(
            rrotate(a, 2),
            rrotate(a, 13),
            rrotate(a, 22)
        )

        local maj = bxor(
            band(a, b),
            band(a, c),
            band(b, c)
        )

        local temp2 = u32(S0 + maj)

        hh = g
        g = f
        f = e
        e = u32(d + temp1)
        d = c
        c = b
        b = a
        a = u32(temp1 + temp2)
    end

    h[1] = u32(h[1] + a)
    h[2] = u32(h[2] + b)
    h[3] = u32(h[3] + c)
    h[4] = u32(h[4] + d)
    h[5] = u32(h[5] + e)
    h[6] = u32(h[6] + f)
    h[7] = u32(h[7] + g)
    h[8] = u32(h[8] + hh)
end

return string.format(
    "%08x%08x%08x%08x%08x%08x%08x%08x",
    h[1], h[2], h[3], h[4],
    h[5], h[6], h[7], h[8]
)


end

local function lEncode(value)
return HttpService:JSONEncode(value)
end

local function lDecode(value)
return HttpService:JSONDecode(value)
end

local lDigest = sha256

local service = 29990
local secret = "4a156cbd-7be0-4ec3-a6fe-0dcce4d61f50"
local useNonce = true

local lastKeyMessage = ""

local function onMessage(message)
lastKeyMessage = tostring(message or "")
end

local requestSending = false

local fSetClipboard =
setclipboard
or toclipboard

local fRequest =
request
or http_request
or syn_request

local fStringChar = string.char
local fToString = tostring
local fStringSub = string.sub
local fOsTime = os.time
local fMathRandom = math.random
local fMathFloor = math.floor

local fGetHwid =
gethwid
or function()
return LocalPlayer.UserId
end

if not fRequest then
error("Your executor does not provide an HTTP request function.")
end

local function getIdentifier()
local ok, result = pcall(function()
return fGetHwid()
end)

if not ok or result == nil then
    result = LocalPlayer.UserId
end

return lDigest(tostring(result))


end

local cachedLink = ""
local cachedTime = 0

local host = "https://api.platoboost.com"

do
local ok, response = pcall(function()
return fRequest({
Url = host .. "/public/connectivity",
Method = "GET"
})
end)

if ok
    and response
    and response.StatusCode
    and response.StatusCode ~= 200
    and response.StatusCode ~= 429 then

    host = "https://api.platoboost.net"

elseif not ok then
    host = "https://api.platoboost.net"
end


end

local function cacheLink()
if cachedTime + 600 < fOsTime() then
local ok, response = pcall(function()
return fRequest({
Url = host .. "/public/start",
Method = "POST",

            Body = lEncode({
                service = service,
                identifier = getIdentifier()
            }),

            Headers = {
                ["Content-Type"] = "application/json"
            }
        })
    end)

    if not ok or not response then
        local msg = "HTTP request failed."
        onMessage(msg)
        return false, msg
    end

    if response.StatusCode == 200 then
        local decodeOk, decoded = pcall(function()
            return lDecode(response.Body)
        end)

        if not decodeOk or not decoded then
            local msg = "Invalid server response."
            onMessage(msg)
            return false, msg
        end

        if decoded.success == true then
            cachedLink = decoded.data.url
            cachedTime = fOsTime()

            return true, cachedLink
        else
            onMessage(decoded.message)
            return false, decoded.message
        end

    elseif response.StatusCode == 429 then
        local msg =
            "You are being rate limited, please wait 20 seconds and try again."

        onMessage(msg)
        return false, msg
    end

    local msg = "Failed to cache link."
    onMessage(msg)

    return false, msg
end

return true, cachedLink


end

local function generateNonce()
local str = ""

for _ = 1, 16 do
    str = str
        .. fStringChar(
            fMathFloor(fMathRandom() * 26) + 97
        )
end

return str


end

for _ = 1, 5 do
local nonceA = generateNonce()

task.wait(0.2)

if generateNonce() == nonceA then
    local msg = "Platoboost nonce error."
    onMessage(msg)
    error(msg)
end


end

local function copyLink()
local success, link = cacheLink()

if success and type(link) == "string" and link ~= "" then
    if fSetClipboard then
        pcall(function()
            fSetClipboard(link)
        end)
    end
end

return success, link


end

local function redeemKey(key)
local nonce = generateNonce()

local endpoint =
    host
    .. "/public/redeem/"
    .. fToString(service)

local body = {
    identifier = getIdentifier(),
    key = key
}

if useNonce then
    body.nonce = nonce
end

local ok, response = pcall(function()
    return fRequest({
        Url = endpoint,
        Method = "POST",
        Body = lEncode(body),

        Headers = {
            ["Content-Type"] = "application/json"
        }
    })
end)

if not ok or not response then
    onMessage("HTTP request failed.")
    return false
end

if response.StatusCode == 200 then
    local decodeOk, decoded = pcall(function()
        return lDecode(response.Body)
    end)

    if not decodeOk or not decoded then
        onMessage("Invalid server response.")
        return false
    end

    if decoded.success == true then
        if decoded.data.valid == true then
            if useNonce then
                if decoded.data.hash
                    == lDigest("true-" .. nonce .. "-" .. secret) then

                    return true
                end

                onMessage("Failed to verify integrity.")
                return false
            end

            return true
        end

        onMessage("Key is invalid.")
        return false
    end

    if type(decoded.message) == "string"
        and fStringSub(decoded.message, 1, 27)
        == "unique constraint violation" then

        onMessage(
            "You already have an active key. Please wait for it to expire before redeeming it."
        )

        return false
    end

    onMessage(decoded.message)
    return false

elseif response.StatusCode == 429 then
    onMessage(
        "You are being rate limited, please wait 20 seconds and try again."
    )

    return false
end

onMessage(
    "Server returned an invalid status code. Please try again later."
)

return false


end

local function verifyKey(key)
if requestSending then
onMessage(
"A request is already being sent. Please slow down."
)

    return false
end

requestSending = true

local nonce = generateNonce()

local endpoint =
    host
    .. "/public/whitelist/"
    .. fToString(service)
    .. "?identifier="
    .. getIdentifier()
    .. "&key="
    .. key

if useNonce then
    endpoint = endpoint .. "&nonce=" .. nonce
end

local requestOk, response = pcall(function()
    return fRequest({
        Url = endpoint,
        Method = "GET"
    })
end)

requestSending = false

if not requestOk or not response then
    onMessage("HTTP request failed.")
    return false
end

if response.StatusCode == 200 then
    local decodeOk, decoded = pcall(function()
        return lDecode(response.Body)
    end)

    if not decodeOk or not decoded then
        onMessage("Invalid server response.")
        return false
    end

    if decoded.success == true then
        if decoded.data.valid == true then
            if useNonce then
                if decoded.data.hash
                    == lDigest("true-" .. nonce .. "-" .. secret) then

                    return true
                end

                onMessage("Failed to verify integrity.")
                return false
            end

            return true
        end

        if fStringSub(key, 1, 4) == "KEY_" then
            return redeemKey(key)
        end

        onMessage("Key is invalid.")
        return false
    end

    onMessage(decoded.message)
    return false

elseif response.StatusCode == 429 then
    onMessage(
        "You are being rate limited, please wait 20 seconds and try again."
    )

    return false
end

onMessage(
    "Server returned an invalid status code. Please try again later."
)

return false


end

local function getFlag(name)
local nonce = generateNonce()

local endpoint =
    host
    .. "/public/flag/"
    .. fToString(service)
    .. "?name="
    .. tostring(name)

if useNonce then
    endpoint = endpoint .. "&nonce=" .. nonce
end

local ok, response = pcall(function()
    return fRequest({
        Url = endpoint,
        Method = "GET"
    })
end)

if not ok or not response then
    return nil
end

if response.StatusCode ~= 200 then
    return nil
end

local decodeOk, decoded = pcall(function()
    return lDecode(response.Body)
end)

if not decodeOk or not decoded then
    onMessage("Invalid server response.")
    return nil
end

if decoded.success == true then
    if useNonce then
        if decoded.data.hash
            == lDigest(
                fToString(decoded.data.value)
                .. "-"
                .. nonce
                .. "-"
                .. secret
            ) then

            return decoded.data.value
        end

        onMessage("Failed to verify integrity.")
        return nil
    end

    return decoded.data.value
end

onMessage(decoded.message)
return nil


end

local function safeCall(fn, ...)
local ok, result = pcall(fn, ...)
return ok, result
end

local function getCharacter()
return LocalPlayer.Character
end

local function getHRP()
local char = getCharacter()

return char and char:FindFirstChild("HumanoidRootPart")


end

local function getHumanoid()
local char = getCharacter()

return char and char:FindFirstChildOfClass("Humanoid")


end

local function getGuiParent()
local ok, hui = pcall(function()
if gethui then
return gethui()
end

    return nil
end)

if ok and hui then
    return hui
end

return game:GetService("CoreGui")


end

local function tween(instance, info, properties)
local ok, tw = pcall(function()
return TweenService:Create(
instance,
info,
properties
)
end)

if ok and tw then
    tw:Play()
    return tw
end

return nil


end

local function addCorner(parent, radius)
local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, radius or 10)
corner.Parent = parent

return corner


end

local function addStroke(parent, color, transparency, thickness)
local stroke = Instance.new("UIStroke")

stroke.Color =
    color
    or Color3.fromRGB(70, 80, 105)

stroke.Transparency =
    transparency
    or 0.45

stroke.Thickness =
    thickness
    or 1

stroke.Parent = parent

return stroke


end

local KEY_FILE = "JustTeamHub_Key.txt"

local function readSavedKey()
if not isfile then
return ""
end

local ok, exists = pcall(function()
    return isfile(KEY_FILE)
end)

if not ok or not exists then
    return ""
end

local success, content = pcall(function()
    return readfile(KEY_FILE)
end)

if success then
    return tostring(content or "")
end

return ""


end

local function saveKey(key)
if not writefile then
return
end

pcall(function()
    writefile(KEY_FILE, key)
end)


end

local function clearSavedKey()
if not (isfile and delfile) then
return
end

pcall(function()
    if isfile(KEY_FILE) then
        delfile(KEY_FILE)
    end
end)


end

local AuthGui = Instance.new("ScreenGui")
AuthGui.Name = "JustTeamHub_KeySystem"
AuthGui.IgnoreGuiInset = true
AuthGui.ResetOnSpawn = false
AuthGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
AuthGui.Parent = getGuiParent()

local Backdrop = Instance.new("Frame")
Backdrop.Size = UDim2.fromScale(1, 1)
Backdrop.BackgroundColor3 = Color3.fromRGB(4, 6, 11)
Backdrop.BackgroundTransparency = 0.18
Backdrop.BorderSizePixel = 0
Backdrop.Parent = AuthGui

local BackdropGradient = Instance.new("UIGradient")
BackdropGradient.Rotation = 35

BackdropGradient.Color = ColorSequence.new({
ColorSequenceKeypoint.new(
0,
Color3.fromRGB(9, 15, 28)
),

ColorSequenceKeypoint.new(
    0.55,
    Color3.fromRGB(4, 7, 15)
),

ColorSequenceKeypoint.new(
    1,
    Color3.fromRGB(12, 6, 23)
)


})

BackdropGradient.Parent = Backdrop

local Card = Instance.new("Frame")
Card.AnchorPoint = Vector2.new(0.5, 0.5)
Card.Position = UDim2.fromScale(0.5, 0.53)
Card.Size = UDim2.fromOffset(500, 330)
Card.BackgroundColor3 = Color3.fromRGB(13, 17, 27)
Card.BackgroundTransparency = 0.02
Card.BorderSizePixel = 0
Card.Parent = AuthGui

addCorner(Card, 18)

addStroke(
Card,
Color3.fromRGB(90, 105, 145),
0.28,
1.2
)

local CardGradient = Instance.new("UIGradient")
CardGradient.Rotation = 90

CardGradient.Color = ColorSequence.new({
ColorSequenceKeypoint.new(
0,
Color3.fromRGB(20, 26, 42)
),

ColorSequenceKeypoint.new(
    1,
    Color3.fromRGB(9, 12, 20)
)


})

CardGradient.Parent = Card

local GlowA = Instance.new("Frame")
GlowA.Size = UDim2.fromOffset(170, 170)
GlowA.Position = UDim2.fromOffset(-80, -80)
GlowA.BackgroundColor3 =
Color3.fromRGB(88, 113, 255)

GlowA.BackgroundTransparency = 0.88
GlowA.BorderSizePixel = 0
GlowA.Parent = Card

addCorner(GlowA, 100)

local GlowB = Instance.new("Frame")
GlowB.Size = UDim2.fromOffset(160, 160)
GlowB.Position = UDim2.new(1, -80, 1, -80)
GlowB.BackgroundColor3 =
Color3.fromRGB(182, 76, 255)

GlowB.BackgroundTransparency = 0.9
GlowB.BorderSizePixel = 0
GlowB.Parent = Card

addCorner(GlowB, 100)

local Content = Instance.new("Frame")
Content.Size = UDim2.new(1, -56, 1, -48)
Content.Position = UDim2.fromOffset(28, 24)
Content.BackgroundTransparency = 1
Content.Parent = Card

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, 0, 0, 36)
Title.BackgroundTransparency = 1
Title.Text = "CAMPER VAN TRIP"
Title.Font = Enum.Font.GothamBold
Title.TextSize = 25
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.TextColor3 =
Color3.fromRGB(245, 248, 255)
Title.Parent = Content

local Subtitle = Instance.new("TextLabel")
Subtitle.Size = UDim2.new(1, 0, 0, 24)
Subtitle.Position = UDim2.fromOffset(0, 36)
Subtitle.BackgroundTransparency = 1
Subtitle.Text = "Just Team Hub  •  Access Gateway"
Subtitle.Font = Enum.Font.Gotham
Subtitle.TextSize = 13
Subtitle.TextXAlignment = Enum.TextXAlignment.Left
Subtitle.TextColor3 =
Color3.fromRGB(145, 156, 179)
Subtitle.Parent = Content

local Status = Instance.new("TextLabel")
Status.Size = UDim2.new(1, 0, 0, 24)
Status.Position = UDim2.fromOffset(0, 68)
Status.BackgroundTransparency = 1
Status.Text = "Waiting for key..."
Status.Font = Enum.Font.GothamMedium
Status.TextSize = 12
Status.TextXAlignment = Enum.TextXAlignment.Left
Status.TextColor3 =
Color3.fromRGB(155, 175, 208)
Status.Parent = Content

local KeyBox = Instance.new("TextBox")
KeyBox.Size = UDim2.new(1, 0, 0, 48)
KeyBox.Position = UDim2.fromOffset(0, 108)
KeyBox.BackgroundColor3 =
Color3.fromRGB(19, 24, 37)

KeyBox.BorderSizePixel = 0
KeyBox.ClearTextOnFocus = false
KeyBox.Font = Enum.Font.GothamMedium
KeyBox.TextSize = 14
KeyBox.PlaceholderText = "Paste your key here..."
KeyBox.PlaceholderColor3 =
Color3.fromRGB(98, 108, 130)

KeyBox.TextColor3 =
Color3.fromRGB(236, 241, 255)

KeyBox.TextXAlignment = Enum.TextXAlignment.Left
KeyBox.Text = readSavedKey()
KeyBox.Parent = Content

addCorner(KeyBox, 11)

addStroke(
KeyBox,
Color3.fromRGB(64, 78, 110),
0.34,
1
)

local KeyPadding = Instance.new("UIPadding")
KeyPadding.PaddingLeft = UDim.new(0, 16)
KeyPadding.PaddingRight = UDim.new(0, 16)
KeyPadding.Parent = KeyBox

local Verify = Instance.new("TextButton")
Verify.Size = UDim2.new(0.49, -6, 0, 48)
Verify.Position = UDim2.fromOffset(0, 170)
Verify.BackgroundColor3 =
Color3.fromRGB(77, 101, 235)

Verify.BorderSizePixel = 0
Verify.AutoButtonColor = false
Verify.Text = "VERIFY KEY"
Verify.Font = Enum.Font.GothamBold
Verify.TextSize = 13
Verify.TextColor3 =
Color3.fromRGB(255, 255, 255)

Verify.Parent = Content

addCorner(Verify, 11)

addStroke(
Verify,
Color3.fromRGB(121, 142, 255),
0.35,
1
)

local GetKey = Instance.new("TextButton")
GetKey.Size = UDim2.new(0.49, -6, 0, 48)
GetKey.Position = UDim2.new(0.51, 6, 0, 170)
GetKey.BackgroundColor3 =
Color3.fromRGB(25, 31, 48)

GetKey.BorderSizePixel = 0
GetKey.AutoButtonColor = false
GetKey.Text = "GET KEY LINK"
GetKey.Font = Enum.Font.GothamBold
GetKey.TextSize = 13
GetKey.TextColor3 =
Color3.fromRGB(225, 232, 247)

GetKey.Parent = Content

addCorner(GetKey, 11)

addStroke(
GetKey,
Color3.fromRGB(71, 84, 112),
0.35,
1
)

local Footer = Instance.new("TextLabel")
Footer.Size = UDim2.new(1, 0, 0, 40)
Footer.Position = UDim2.fromOffset(0, 228)
Footer.BackgroundTransparency = 1
Footer.Text =
"Your key is checked remotely before the main interface opens."

Footer.Font = Enum.Font.Gotham
Footer.TextSize = 11
Footer.TextWrapped = true
Footer.TextXAlignment = Enum.TextXAlignment.Left
Footer.TextYAlignment = Enum.TextYAlignment.Top
Footer.TextColor3 =
Color3.fromRGB(108, 118, 140)

Footer.Parent = Content

local Version = Instance.new("TextLabel")
Version.Size = UDim2.new(0, 140, 0, 20)
Version.Position = UDim2.new(1, -140, 1, -4)
Version.BackgroundTransparency = 1
Version.Text = "CVT • v2.0"
Version.Font = Enum.Font.GothamBold
Version.TextSize = 10
Version.TextXAlignment = Enum.TextXAlignment.Right
Version.TextColor3 =
Color3.fromRGB(76, 88, 114)

Version.Parent = Content

Card.Size = UDim2.fromOffset(470, 300)
Card.BackgroundTransparency = 1
Backdrop.BackgroundTransparency = 1

tween(
Backdrop,
TweenInfo.new(
0.45,
Enum.EasingStyle.Quint,
Enum.EasingDirection.Out
),
{
BackgroundTransparency = 0.18
}
)

tween(
Card,
TweenInfo.new(
0.55,
Enum.EasingStyle.Quint,
Enum.EasingDirection.Out
),
{
Size = UDim2.fromOffset(500, 330),
BackgroundTransparency = 0.02
}
)

local function buttonHover(
button,
normalColor,
hoverColor
)
button.MouseEnter:Connect(function()
tween(
button,
TweenInfo.new(
0.16,
Enum.EasingStyle.Quad,
Enum.EasingDirection.Out
),
{
BackgroundColor3 = hoverColor
}
)
end)

button.MouseLeave:Connect(function()
    tween(
        button,
        TweenInfo.new(
            0.16,
            Enum.EasingStyle.Quad,
            Enum.EasingDirection.Out
        ),
        {
            BackgroundColor3 = normalColor
        }
    )
end)


end

buttonHover(
Verify,
Color3.fromRGB(77, 101, 235),
Color3.fromRGB(96, 121, 255)
)

buttonHover(
GetKey,
Color3.fromRGB(25, 31, 48),
Color3.fromRGB(35, 43, 65)
)

local function setStatus(text, success)
Status.Text = tostring(text or "")

if success == true then
    Status.TextColor3 =
        Color3.fromRGB(102, 230, 161)

elseif success == false then
    Status.TextColor3 =
        Color3.fromRGB(255, 123, 130)

else
    Status.TextColor3 =
        Color3.fromRGB(155, 175, 208)
end


end

local verifying = false

GetKey.MouseButton1Click:Connect(function()
if verifying then
return
end

setStatus(
    "Generating access link...",
    nil
)

local callOk, cacheSuccess, link = pcall(
    cacheLink
)

if not callOk then
    setStatus(
        lastKeyMessage ~= ""
            and lastKeyMessage
            or "Could not generate the key link.",
        false
    )

    return
end

if cacheSuccess
    and type(link) == "string"
    and link ~= "" then

    local copied = false

    if setclipboard then
        copied = pcall(function()
            setclipboard(link)
        end)

    elseif toclipboard then
        copied = pcall(function()
            toclipboard(link)
        end)
    end

    if copied then
        setStatus(
            "Link copied. Complete the key process, then paste your key.",
            true
        )
    else
        setStatus(
            "Link generated, but clipboard access is unavailable.",
            true
        )
    end

    return
end

setStatus(
    lastKeyMessage ~= ""
        and lastKeyMessage
        or "Failed to generate link.",
    false
)


end)

local function verifyCurrentKey()
if verifying then
return
end

local key =
    tostring(KeyBox.Text or "")
    :gsub("^%s+", "")
    :gsub("%s+$", "")

if key == "" then
    setStatus(
        "Enter a key first.",
        false
    )

    return
end

verifying = true
Verify.Text = "CHECKING..."

setStatus(
    "Contacting key server...",
    nil
)

task.spawn(function()
    local ok, result = pcall(function()
        return verifyKey(key)
    end)

    verifying = false
    Verify.Text = "VERIFY KEY"

    if ok and result == true then
        saveKey(key)

        setStatus(
            "Key verified. Loading interface...",
            true
        )

        task.wait(0.45)

        tween(
            Card,
            TweenInfo.new(
                0.35,
                Enum.EasingStyle.Quint,
                Enum.EasingDirection.In
            ),
            {
                Position = UDim2.fromScale(0.5, 0.48),
                Size = UDim2.fromOffset(470, 300),
                BackgroundTransparency = 1
            }
        )

        tween(
            Backdrop,
            TweenInfo.new(
                0.35,
                Enum.EasingStyle.Quint,
                Enum.EasingDirection.In
            ),
            {
                BackgroundTransparency = 1
            }
        )

        task.wait(0.38)

        pcall(function()
            AuthGui:Destroy()
        end)

        GEN.CVT_Authorized = true

        return
    end

    local msg =
        lastKeyMessage ~= ""
            and lastKeyMessage
            or "Key is invalid."

    setStatus(
        msg,
        false
    )

    clearSavedKey()
end)


end

Verify.MouseButton1Click:Connect(
verifyCurrentKey
)

KeyBox.FocusLost:Connect(function(
enterPressed
)
if enterPressed then
verifyCurrentKey()
end
end)

task.spawn(function()
local saved = tostring(
KeyBox.Text or ""
)

if saved ~= "" then
    task.wait(0.35)
    verifyCurrentKey()
else
    setStatus(
        "Paste a valid access key.",
        nil
    )
end


end)

repeat
task.wait()
until GEN.CVT_Authorized == true

local function loadRayfield()
local urls = {
"https://raw.githubusercontent.com/SiriusMenu/Rayfield/main/source.lua",
"https://sirius.menu/rayfield"
}

local lastError =
    "Unknown Rayfield loading error."

for _, url in ipairs(urls) do
    local httpOk, source = pcall(function()
        return game:HttpGet(url)
    end)

    if httpOk
        and type(source) == "string"
        and #source > 100 then

        local loadOk, loader = pcall(function()
            return loadstring(source)
        end)

        if loadOk
            and type(loader) == "function" then

            local execOk, library = pcall(
                loader
            )

            if execOk and library then
                return library
            end

            lastError =
                tostring(library)

        else
            lastError =
                tostring(loader)
        end

    else
        lastError =
            tostring(source)
    end
end

error(
    "Rayfield could not be loaded: "
    .. lastError
)


end

local Rayfield = loadRayfield()

local PRIORITY = {
{
"TotemOfResurrection",
"CrateKey",
"Crystal",
"Glimpse",
"Funky",
"ElectronicShop"
},

{
    "GasCan",
    "SpareReinforcedTire",
    "Ammo",
    "BearSpray"
},

{
    "Burger",
    "AlienSandwich",
    "Soda",
    "Beans",
    "Bread",
    "Apple"
}


}

local BLACKLIST = {
Vase = true,
CrumpledPaper = true,
Stool = true,
WoodenChair = true,
Nutshell = true,
WoodPlank = true,
SheetMetal = true
}

local RARE_LIST = {
CrateKey = true,
TotemOfResurrection = true,
GasCan = true
}

local lootFilter = {}

for _, tier in ipairs(PRIORITY) do
for _, name in ipairs(tier) do
lootFilter[name] = true
end
end

local BRING_RADIUS = 3000

local State = {
FarmActive = false,

BodyESP = false,
RareESP = false,

PlayerSpeedActive = false,
PlayerSpeedVal = 50,

PlayerFlyActive = false,
PlayerFlySpeed = 50,

NoclipActive = false,

VehSpeedActive = false,
VehSpeedMult = 3, -- UPDATED: Установлено значение по умолчанию 3 (3x)

VehFlyActive = false,
VehFlySpeed = 35,

VehStabilizer = true,
VehNoclipActive = false


}

local function isValidItem(item)
if not item or not item.Parent then
return false, nil
end

if item:IsA("BasePart") then
    return true, item
end

if item:IsA("Model") then
    local bp =
        item:FindFirstChildWhichIsA(
            "BasePart",
            true
        )

    return bp ~= nil, bp
end

local bp =
    item:FindFirstChildWhichIsA(
        "BasePart",
        true
    )

return bp ~= nil, bp


end

local function getItemPosition(item)
if not item then
return nil
end

if item:IsA("BasePart") then
    return item.Position
end

if item:IsA("Model") then
    if item.PrimaryPart then
        return item.PrimaryPart.Position
    end

    local bp =
        item:FindFirstChildWhichIsA(
            "BasePart",
            true
        )

    return bp and bp.Position or nil
end

local bp =
    item:FindFirstChildWhichIsA(
        "BasePart",
        true
    )

return bp and bp.Position or nil


end

local function bringItem(item)
local hrp = getHRP()

if not hrp
    or not item
    or not item.Parent then

    return false
end

local targetCF =
    hrp.CFrame
    + hrp.CFrame.LookVector * 2

local ok = pcall(function()
    if item:IsA("BasePart") then
        item.CFrame = targetCF

    elseif item:IsA("Model") then
        if item.PrimaryPart then
            item:PivotTo(targetCF)
        else
            local bp =
                item:FindFirstChildWhichIsA(
                    "BasePart",
                    true
                )

            if bp then
                bp.CFrame = targetCF
            end
        end

    else
        local bp =
            item:FindFirstChildWhichIsA(
                "BasePart",
                true
            )

        if bp then
            bp.CFrame = targetCF
        end
    end
end)

return ok


end

local function tryInteractPrompt(item)
if not item
or not item.Parent then

    return
end

local prompt =
    item:FindFirstChildWhichIsA(
        "ProximityPrompt",
        true
    )

if prompt then
    pcall(function()
        prompt:InputHoldBegin()

        task.wait(
            math.max(
                prompt.HoldDuration,
                0.05
            )
        )

        prompt:InputHoldEnd()
    end)
end


end

local function getCurrentVehicle()
local hum = getHumanoid()

if not hum or not hum.SeatPart then
    return nil, nil, nil
end

local seat = hum.SeatPart

local vehicle =
    seat:FindFirstAncestorWhichIsA(
        "Model"
    )

local root =
    seat.AssemblyRootPart

if not root and vehicle then
    root = vehicle.PrimaryPart
end

if not root and vehicle then
    root =
        vehicle:FindFirstChildWhichIsA(
            "BasePart",
            true
        )
end

if not root then
    root = seat
end

return seat, vehicle, root


end

local Window = Rayfield:CreateWindow({
Name = "Camper Van Trip | Just Team Hub",

LoadingTitle = "Camper Van Trip",

LoadingSubtitle =
    "Just Team Hub",

Theme = "DarkBlue",

DisableRayfieldPrompts = false,

DisableBuildWarnings = true,

ConfigurationSaving = {
    Enabled = true,
    FolderName = "CVT_JustTeamHub_Config",
    FileName = "CamperVanJustTeamHub"
},

Discord = {
    Enabled = false
},

KeySystem = false


})

local HomeTab =
Window:CreateTab("Home")

local PlayerTab =
Window:CreateTab("Player")

local LootTab =
Window:CreateTab("Loot")

local VehicleTab =
Window:CreateTab("Vehicle")

local VisualsTab =
Window:CreateTab("Visuals")

local SettingsTab =
Window:CreateTab("Settings")

HomeTab:CreateSection(
"Camper Van Trip Just Team Hub"
)

HomeTab:CreateParagraph({
Title = "Welcome",

Content =
    "Stable version with separate authentication, vehicle controller, auto-farm, and visual features."


})

HomeTab:CreateLabel(
"Status: AUTHORIZED"
)

HomeTab:CreateButton({
Name = "Reload Interface",

Callback = function()
    pcall(function()
        Rayfield:Destroy()
    end)

    task.wait(0.2)

    local ok, source = pcall(function()
        return game:HttpGet(
            "https://raw.githubusercontent.com/SiriusMenu/Rayfield/main/source.lua"
        )
    end)

    if ok and type(source) == "string" then
        local loaded, fn =
            pcall(loadstring, source)

        if loaded and type(fn) == "function" then
            pcall(fn)
        end
    end
end


})

HomeTab:CreateButton({
Name = "Clear Saved Key",

Callback = function()
    clearSavedKey()

    Rayfield:Notify({
        Title = "Key System",

        Content =
            "Saved key cleared. The next launch will require authentication again.",

        Duration = 4
    })
end


})

PlayerTab:CreateSection("Speed")

PlayerTab:CreateToggle({
Name = "Enable Speed",

CurrentValue = false,

Flag = "PlayerSpeedActive",

Callback = function(value)
    State.PlayerSpeedActive = value

    if not value then
        local hum = getHumanoid()

        if hum then
            hum.WalkSpeed = 16
        end
    end
end


})

PlayerTab:CreateSlider({
Name = "Speed",

Range = {16, 250},

Increment = 1,

Suffix = "stud/s",

CurrentValue = 50,

Flag = "PlayerSpeedVal",

Callback = function(value)
    State.PlayerSpeedVal = value
end


})

PlayerTab:CreateSection("Fly")

PlayerTab:CreateToggle({
Name = "Enable Fly",

CurrentValue = false,

Flag = "PlayerFlyActive",

Callback = function(value)
    State.PlayerFlyActive = value

    if not value then
        pcall(function()
            if PlayerFlyVelocity then
                PlayerFlyVelocity:Destroy()
            end
        end)

        pcall(function()
            if PlayerFlyOrientation then
                PlayerFlyOrientation:Destroy()
            end
        end)

        pcall(function()
            if PlayerFlyAttachment then
                PlayerFlyAttachment:Destroy()
            end
        end)

        PlayerFlyVelocity = nil
        PlayerFlyOrientation = nil
        PlayerFlyAttachment = nil
    end
end


})

PlayerTab:CreateSlider({
Name = "Fly Speed",

Range = {10, 300},

Increment = 5,

Suffix = "speed",

CurrentValue = 50,

Flag = "PlayerFlySpeed",

Callback = function(value)
    State.PlayerFlySpeed = value
end


})

PlayerTab:CreateSection("Noclip")

PlayerTab:CreateToggle({
Name = "Enable Noclip",

CurrentValue = false,

Flag = "NoclipActive",

Callback = function(value)
    State.NoclipActive = value
end


})

local NoclipState =
setmetatable(
{},
{
__mode = "k"
}
)

local PlayerFlyAttachment = nil
local PlayerFlyVelocity = nil
local PlayerFlyOrientation = nil

local function restoreNoclip()
for part, original in pairs(NoclipState) do
if part and part.Parent then
pcall(function()
part.CanCollide = original
end)
end

    NoclipState[part] = nil
end


end

local function createPlayerFly(hrp)
if PlayerFlyAttachment
and PlayerFlyAttachment.Parent == hrp
and PlayerFlyVelocity
and PlayerFlyVelocity.Parent == hrp
and PlayerFlyOrientation
and PlayerFlyOrientation.Parent == hrp then

    return
end

pcall(function()
    if PlayerFlyVelocity then
        PlayerFlyVelocity:Destroy()
    end
end)

pcall(function()
    if PlayerFlyOrientation then
        PlayerFlyOrientation:Destroy()
    end
end)

pcall(function()
    if PlayerFlyAttachment then
        PlayerFlyAttachment:Destroy()
    end
end)

PlayerFlyAttachment = Instance.new(
    "Attachment"
)

PlayerFlyAttachment.Name =
    "CVT_PlayerFlyAttachment"

PlayerFlyAttachment.Parent = hrp

PlayerFlyVelocity = Instance.new(
    "LinearVelocity"
)

PlayerFlyVelocity.Name =
    "CVT_PlayerFlyVelocity"

PlayerFlyVelocity.Attachment0 =
    PlayerFlyAttachment

PlayerFlyVelocity.RelativeTo =
    Enum.ActuatorRelativeTo.World

PlayerFlyVelocity.VelocityConstraintMode =
    Enum.VelocityConstraintMode.Vector

PlayerFlyVelocity.MaxForce = math.huge

PlayerFlyVelocity.VectorVelocity =
    Vector3.zero

PlayerFlyVelocity.Parent = hrp

PlayerFlyOrientation = Instance.new(
    "AlignOrientation"
)

PlayerFlyOrientation.Name =
    "CVT_PlayerFlyOrientation"

PlayerFlyOrientation.Attachment0 =
    PlayerFlyAttachment

PlayerFlyOrientation.Mode =
    Enum.OrientationAlignmentMode.OneAttachment

PlayerFlyOrientation.MaxTorque =
    math.huge

PlayerFlyOrientation.Responsiveness =
    35

PlayerFlyOrientation.RigidityEnabled =
    false

PlayerFlyOrientation.Parent = hrp


end

RunService.Stepped:Connect(function()
local char = getCharacter()

if State.NoclipActive and char then
    for _, part in ipairs(
        char:GetDescendants()
    ) do

        if part:IsA("BasePart") then
            if NoclipState[part] == nil then
                NoclipState[part] =
                    part.CanCollide
            end

            if part.CanCollide then
                part.CanCollide = false
            end
        end
    end

elseif not State.NoclipActive
    and next(NoclipState) then

    restoreNoclip()
end


end)

RunService.RenderStepped:Connect(function(dt)
local hrp = getHRP()
local hum = getHumanoid()

if not hrp or not hum then
    return
end

if State.PlayerSpeedActive
    and not State.PlayerFlyActive then

    hum.WalkSpeed =
        State.PlayerSpeedVal
end

if State.PlayerFlyActive
    and not hum.SeatPart then

    createPlayerFly(hrp)

    local cam =
        Workspace.CurrentCamera
        or Camera

    if cam then
        local moveDir = Vector3.zero

        if UserInputService:IsKeyDown(
            Enum.KeyCode.W
        ) then
            moveDir = moveDir + cam.CFrame.LookVector
        end

        if UserInputService:IsKeyDown(
            Enum.KeyCode.S
        ) then
            moveDir = moveDir - cam.CFrame.LookVector
        end

        if UserInputService:IsKeyDown(
            Enum.KeyCode.A
        ) then
            moveDir = moveDir - cam.CFrame.RightVector
        end

        if UserInputService:IsKeyDown(
            Enum.KeyCode.D
        ) then
            moveDir = moveDir + cam.CFrame.RightVector
        end

        if UserInputService:IsKeyDown(
            Enum.KeyCode.Space
        ) then
            moveDir = moveDir + Vector3.new(
                0,
                1,
                0
            )
        end

        if UserInputService:IsKeyDown(
            Enum.KeyCode.LeftShift
        ) then
            moveDir = moveDir - Vector3.new(
                0,
                1,
                0
            )
        end

        if moveDir.Magnitude > 1 then
            moveDir = moveDir.Unit
        end

        local current =
            PlayerFlyVelocity.VectorVelocity

        local alpha =
            1 - math.exp(-12 * dt)

        PlayerFlyVelocity.VectorVelocity =
            current:Lerp(
                moveDir
                    * State.PlayerFlySpeed,
                alpha
            )

        local flatLook =
            Vector3.new(
                cam.CFrame.LookVector.X,
                0,
                cam.CFrame.LookVector.Z
            )

        if flatLook.Magnitude > 0.001 then
            flatLook = flatLook.Unit

            PlayerFlyOrientation.CFrame =
                CFrame.lookAt(
                    hrp.Position,
                    hrp.Position + flatLook
                )
        end
    end

else
    if PlayerFlyVelocity then
        pcall(function()
            PlayerFlyVelocity:Destroy()
        end)

        PlayerFlyVelocity = nil
    end

    if PlayerFlyOrientation then
        pcall(function()
            PlayerFlyOrientation:Destroy()
        end)

        PlayerFlyOrientation = nil
    end

    if PlayerFlyAttachment then
        pcall(function()
            PlayerFlyAttachment:Destroy()
        end)

        PlayerFlyAttachment = nil
    end
end


end)

LootTab:CreateSection("Auto Collect")

LootTab:CreateToggle({
Name = "Enable Auto Collect",

CurrentValue = false,

Flag = "FarmActive",

Callback = function(value)
    State.FarmActive = value
end


})

LootTab:CreateSlider({
Name = "Search Radius",

Range = {100, 10000},

Increment = 100,

Suffix = "studs",

CurrentValue = 3000,

Flag = "BringRadius",

Callback = function(value)
    BRING_RADIUS = value
end


})

LootTab:CreateSection(
"Instant Bring"
)

LootTab:CreateButton({
Name = "Bring Everything",

Callback = function()
    local folder =
        Workspace:FindFirstChild(
            "ScatteredLoot"
        )

    if not folder then
        return
    end

    local count = 0

    for _, item in ipairs(
        folder:GetChildren()
    ) do

        if not BLACKLIST[item.Name] then
            if bringItem(item) then
                count = count + 1
            end
        end
    end

    Rayfield:Notify({
        Title = "Bring",

        Content =
            "Items brought: "
            .. count,

        Duration = 3
    })
end


})

LootTab:CreateButton({
Name = "Bring Selected Loot",

Callback = function()
    local folder =
        Workspace:FindFirstChild(
            "ScatteredLoot"
        )

    if not folder then
        return
    end

    local count = 0

    for _, item in ipairs(
        folder:GetChildren()
    ) do

        if lootFilter[item.Name]
            and not BLACKLIST[item.Name]
            and bringItem(item) then

            count = count + 1
        end
    end

    Rayfield:Notify({
        Title = "Bring",

        Content =
            "Selected items brought: "
            .. count,

        Duration = 3
    })
end


})

LootTab:CreateSection("Filters")

for _, tier in ipairs(PRIORITY) do
for _, name in ipairs(tier) do
LootTab:CreateToggle({
Name = name,

        CurrentValue = true,

        Flag = "Loot_" .. name,

        Callback = function(value)
            lootFilter[name] = value
        end
    })
end


end

local function getLootPriority(name)
for tierIndex, tier in ipairs(
PRIORITY
) do

    for itemIndex, itemName in ipairs(
        tier
    ) do

        if itemName == name then
            return tierIndex, itemIndex
        end
    end
end

return 999, 999


end

task.spawn(function()
while task.wait(0.12) do
repeat
if not State.FarmActive then
break
end

        local hrp = getHRP()

        if not hrp then
            break
        end

        local folder =
            Workspace:FindFirstChild(
                "ScatteredLoot"
            )

        if not folder then
            break
        end

        local candidates = {}

    for _, item in ipairs(
        folder:GetChildren()
    ) do

        if lootFilter[item.Name]
            and not BLACKLIST[item.Name] then

            local valid =
                isValidItem(item)

            local pos =
                getItemPosition(item)

            if valid and pos then
                local distance =
                    (pos - hrp.Position).Magnitude

                if distance <= BRING_RADIUS then
                    local tierIndex,
                        itemIndex =
                        getLootPriority(
                            item.Name
                        )

                    table.insert(
                        candidates,
                        {
                            item = item,

                            distance =
                                distance,

                            tier =
                                tierIndex,

                            order =
                                itemIndex
                        }
                    )
                end
            end
        end
    end

    table.sort(
        candidates,
        function(a, b)
            if a.tier ~= b.tier then
                return a.tier < b.tier
            end

            if a.order ~= b.order then
                return a.order < b.order
            end

            return a.distance < b.distance
        end
    )

        for _, candidate in ipairs(
            candidates
        ) do

            if not State.FarmActive then
                break
            end

            if candidate.item
                and candidate.item.Parent then

                if bringItem(
                    candidate.item
                ) then

                    task.wait(0.035)

                    tryInteractPrompt(
                        candidate.item
                    )

                    task.wait(0.035)
                end
            end
        end
    until true
end


end)

VehicleTab:CreateSection(
"Vehicle Speed"
)

VehicleTab:CreateToggle({
Name = "Enable Vehicle Speed",

CurrentValue = false,

Flag = "VehSpeedActive",

Callback = function(value)
    State.VehSpeedActive = value
end


})

VehicleTab:CreateSlider({
Name = "Speed Multiplier",

Range = {1, 50},

Increment = 1,

Suffix = "x",

CurrentValue = 3, -- UPDATED: По умолчанию 3x как запрошено

Flag = "VehSpeedMult",

Callback = function(value)
    State.VehSpeedMult = value
end


})

VehicleTab:CreateToggle({
Name = "Vehicle Stabilizer",

CurrentValue = true,

Flag = "VehStabilizer",

Callback = function(value)
    State.VehStabilizer = value
end


})

local VehicleNoclipState =
setmetatable(
{},
{
__mode = "k"
}
)

local VehiclePassengerNoclipState =
setmetatable(
{},
{
__mode = "k"
}
)

local VehicleNoclipModel = nil

local function restoreVehicleNoclip()
for part, original in pairs(VehicleNoclipState) do
if part and part.Parent then
pcall(function()
part.CanCollide = original
end)
end

    VehicleNoclipState[part] = nil
end

for part, original in pairs(VehiclePassengerNoclipState) do
    if part and part.Parent then
        pcall(function()
            part.CanCollide = original
        end)
    end

    VehiclePassengerNoclipState[part] = nil
end

VehicleNoclipModel = nil


end

-- UPDATED: Добавлена функция-проверка для исключения колёс
local function isWheel(part)
local name = string.lower(part.Name)
if string.find(name, "wheel") or string.find(name, "tire") or string.find(name, "suspension") then
return true
end
if part:IsA("Part") and part.Shape == Enum.PartType.Cylinder then
return true
end
return false
end

local function applyVehicleNoclip(vehicle)
if not State.VehNoclipActive
or not vehicle
or not vehicle.Parent then

    if VehicleNoclipModel
        or next(VehicleNoclipState)
        or next(VehiclePassengerNoclipState) then

        restoreVehicleNoclip()
    end

    return
end

if VehicleNoclipModel
    and VehicleNoclipModel ~= vehicle then

    restoreVehicleNoclip()
end

VehicleNoclipModel = vehicle

for _, part in ipairs(vehicle:GetDescendants()) do
    if part:IsA("BasePart") then
        -- UPDATED: Исключаем колеса, чтобы не проваливаться под землю
        if not isWheel(part) then
            if VehicleNoclipState[part] == nil then
                VehicleNoclipState[part] = part.CanCollide
            end

            if part.CanCollide then
                part.CanCollide = false
            end
        end
    end
end

for _, descendant in ipairs(vehicle:GetDescendants()) do
    if descendant:IsA("Seat")
        or descendant:IsA("VehicleSeat") then

        local occupant = descendant.Occupant

        if occupant then
            local character = occupant.Parent

            if character then
                for _, part in ipairs(
                    character:GetDescendants()
                ) do
                    if part:IsA("BasePart") then
                        if VehiclePassengerNoclipState[part] == nil then
                            VehiclePassengerNoclipState[part] = part.CanCollide
                        end

                        if part.CanCollide then
                            part.CanCollide = false
                        end
                    end
                end
            end
        end
    end
end


end

VehicleTab:CreateToggle({
Name = "Vehicle Noclip",

CurrentValue = false,

Flag = "VehNoclipActive",

Callback = function(value)
    State.VehNoclipActive = value

    if not value then
        restoreVehicleNoclip()
    end
end


})

VehicleTab:CreateButton({
Name = "Flip Vehicle Upright",

Callback = function()
    local _, vehicle, root =
        getCurrentVehicle()

    if not root then
        return
    end

    local pos = root.Position
    local look =
        root.CFrame.LookVector

    local flatLook =
        Vector3.new(
            look.X,
            0,
            look.Z
        )

    if flatLook.Magnitude < 0.001 then
        flatLook =
            Vector3.new(
                0,
                0,
                -1
            )
    else
        flatLook =
            flatLook.Unit
    end

    local cf =
        CFrame.lookAt(
            pos + Vector3.new(0, 2, 0),
            pos
                + Vector3.new(0, 2, 0)
                + flatLook
        )

    if vehicle
        and vehicle:IsA("Model") then

        pcall(function()
            vehicle:PivotTo(cf)
        end)

    else
        pcall(function()
            root.CFrame = cf
        end)
    end

    pcall(function()
        root.AssemblyAngularVelocity =
            Vector3.zero
    end)
end


})

VehicleTab:CreateSection(
"Vehicle Fly — First Person"
)

local cleanupVehicleFly
local VehAttachment = nil
local VehLinearVelocity = nil
local VehAlignOrientation = nil
local VehRoot = nil
local VehicleTargetVelocity =
Vector3.zero

VehicleTab:CreateToggle({
Name = "Enable Vehicle Fly",

CurrentValue = false,

Flag = "VehFlyActive",

Callback = function(value)
    State.VehFlyActive = value

    if not value
        and cleanupVehicleFly then

        cleanupVehicleFly()
    end
end


})

VehicleTab:CreateSlider({
Name = "Fly Speed",

Range = {5, 300},

Increment = 5,

Suffix = "speed",

CurrentValue = 35,

Flag = "VehFlySpeed",

Callback = function(value)
    State.VehFlySpeed = value
end


})

VehicleTab:CreateParagraph({
Title = "Controls",

Content =
    "W/S — forward/backward relative to the camera • A/D — left/right • Space — up • LeftShift — down. The camera controls movement direction."


})

cleanupVehicleFly = function()
pcall(function()
if VehLinearVelocity then
VehLinearVelocity:Destroy()
end
end)

pcall(function()
    if VehAlignOrientation then
        VehAlignOrientation:Destroy()
    end
end)

pcall(function()
    if VehAttachment then
        VehAttachment:Destroy()
    end
end)

VehLinearVelocity = nil
VehAlignOrientation = nil
VehAttachment = nil
VehRoot = nil
VehicleTargetVelocity =
    Vector3.zero


end

local function createVehicleFly(root)
cleanupVehicleFly()

VehRoot = root

VehAttachment = Instance.new(
    "Attachment"
)

VehAttachment.Name =
    "CVT_VehicleAttachment"

VehAttachment.Parent = root

VehLinearVelocity = Instance.new(
    "LinearVelocity"
)

VehLinearVelocity.Name =
    "CVT_VehicleLinearVelocity"

VehLinearVelocity.Attachment0 =
    VehAttachment

VehLinearVelocity.RelativeTo =
    Enum.ActuatorRelativeTo.World

VehLinearVelocity.VelocityConstraintMode =
    Enum.VelocityConstraintMode.Vector

VehLinearVelocity.MaxForce =
    math.huge

VehLinearVelocity.VectorVelocity =
    Vector3.zero

VehLinearVelocity.Parent = root

VehAlignOrientation = Instance.new(
    "AlignOrientation"
)

VehAlignOrientation.Name =
    "CVT_VehicleAlignOrientation"

VehAlignOrientation.Attachment0 =
    VehAttachment

VehAlignOrientation.Mode =
    Enum.OrientationAlignmentMode.OneAttachment

VehAlignOrientation.MaxTorque =
    math.huge

VehAlignOrientation.Responsiveness =
    22

VehAlignOrientation.RigidityEnabled =
    false

VehAlignOrientation.Parent = root


end

local function getVehicleBaseSpeed(seat)
local base = 45

local ok, maxSpeed = pcall(
    function()
        return seat.MaxSpeed
    end
)

if ok
    and type(maxSpeed) == "number"
    and maxSpeed > 0 then

    base =
        math.max(
            maxSpeed,
            25
        )
end

return math.clamp(
    base,
    25,
    100
)


end

local function getThrottle(seat)
local ok, value = pcall(
function()
return seat.ThrottleFloat
end
)

if ok and type(value) == "number" then
    return value
end

local ok2, value2 = pcall(
    function()
        return seat.Throttle
    end
)

if ok2 and type(value2) == "number" then
    return value2
end

return 0


end

RunService.Heartbeat:Connect(
function(dt)
local seat, vehicle, root =
getCurrentVehicle()

    if not seat or not root then
        if VehRoot
            or VehLinearVelocity then

            cleanupVehicleFly()
        end

        if VehicleNoclipModel
            or next(VehicleNoclipState)
            or next(VehiclePassengerNoclipState) then

            restoreVehicleNoclip()
        end

        return
    end

    applyVehicleNoclip(vehicle)

    if State.VehSpeedActive
        and not State.VehFlyActive then

        local throttle =
            getThrottle(seat)

        local look =
            root.CFrame.LookVector

        local forward =
            Vector3.new(
                look.X,
                0,
                look.Z
            )

        if forward.Magnitude > 0.001 then
            forward = forward.Unit
        else
            forward =
                Vector3.new(
                    0,
                    0,
                    -1
                )
        end

        local right =
            Vector3.new(
                forward.Z,
                0,
                -forward.X
            )

        local velocity =
            root.AssemblyLinearVelocity

        local planar =
            Vector3.new(
                velocity.X,
                0,
                velocity.Z
            )

        local forwardSpeed =
            planar:Dot(forward)

        local lateralSpeed =
            planar:Dot(right)

        local baseSpeed =
            getVehicleBaseSpeed(
                seat
            )

        -- UPDATED: Изменен расчет максимальной скорости (множитель применяется напрямую к базовой скорости)
        local maxSpeed =
            math.clamp(
                baseSpeed * State.VehSpeedMult,
                35,
                1500
            )

        local desiredForward =
            throttle * maxSpeed

        -- UPDATED: Изменен расчет ускорения (множитель также влияет на ускорение)
        local acceleration =
            math.clamp(
                dt * 8 * (State.VehSpeedMult / 2),
                0,
                1
            )

        local newForward =
            forwardSpeed
            + (
                desiredForward
                - forwardSpeed
            )
            * acceleration

        local lateralDamping =
            math.clamp(
                dt * 14,
                0,
                1
            )

        local newLateral =
            lateralSpeed
            * (
                1
                - lateralDamping
            )

        local newPlanar =
            forward * newForward
            + right * newLateral

        root.AssemblyLinearVelocity =
            Vector3.new(
                newPlanar.X,
                velocity.Y,
                newPlanar.Z
            )

        if State.VehStabilizer then
            local currentAngular =
                root.AssemblyAngularVelocity

            root.AssemblyAngularVelocity =
                currentAngular:Lerp(
                    Vector3.zero,
                    math.clamp(
                        dt * 7,
                        0,
                        1
                    )
                )

            local flat =
                Vector3.new(
                    root.CFrame.LookVector.X,
                    0,
                    root.CFrame.LookVector.Z
                )

            if flat.Magnitude > 0.001 then
                flat = flat.Unit

                root.CFrame =
                    CFrame.lookAt(
                        root.Position,
                        root.Position
                            + flat,
                        Vector3.new(
                            0,
                            1,
                            0
                        )
                    )
            end
        end
    end


    if State.VehFlyActive then
        if not VehRoot
            or VehRoot ~= root
            or not VehLinearVelocity
            or not VehAlignOrientation
            or not VehLinearVelocity.Parent
            or not VehAlignOrientation.Parent then

            createVehicleFly(root)
        end

        local cam =
            Workspace.CurrentCamera
            or Camera

        if not cam then
            return
        end

        local look =
            cam.CFrame.LookVector

        local right =
            cam.CFrame.RightVector

        local moveDir =
            Vector3.zero

        if UserInputService:IsKeyDown(
            Enum.KeyCode.W
        ) then
            moveDir = moveDir + look
        end

        if UserInputService:IsKeyDown(
            Enum.KeyCode.S
        ) then
            moveDir = moveDir - look
        end

        if UserInputService:IsKeyDown(
            Enum.KeyCode.A
        ) then
            moveDir = moveDir - right
        end

        if UserInputService:IsKeyDown(
            Enum.KeyCode.D
        ) then
            moveDir = moveDir + right
        end

        if UserInputService:IsKeyDown(
            Enum.KeyCode.Space
        ) then
            moveDir = moveDir + Vector3.new(
                0,
                1,
                0
            )
        end

        if UserInputService:IsKeyDown(
            Enum.KeyCode.LeftShift
        ) then
            moveDir = moveDir - Vector3.new(
                0,
                1,
                0
            )
        end

        if moveDir.Magnitude > 1 then
            moveDir = moveDir.Unit
        end

        local desiredVelocity =
            moveDir
            * State.VehFlySpeed

        local alpha =
            1 - math.exp(-10 * dt)

        VehicleTargetVelocity =
            VehicleTargetVelocity:Lerp(
                desiredVelocity,
                alpha
            )

        VehLinearVelocity.VectorVelocity =
            VehicleTargetVelocity

        local flatLook =
            Vector3.new(
                look.X,
                0,
                look.Z
            )

        if flatLook.Magnitude > 0.001 then
            flatLook = flatLook.Unit

            VehAlignOrientation.CFrame =
                CFrame.lookAt(
                    root.Position,
                    root.Position
                        + flatLook,
                    Vector3.new(
                        0,
                        1,
                        0
                    )
                )
        end

        local angular =
            root.AssemblyAngularVelocity

        root.AssemblyAngularVelocity =
            angular:Lerp(
                Vector3.zero,
                math.clamp(
                    dt * 10,
                    0,
                    1
                )
            )

    else
        if VehRoot
            or VehLinearVelocity then

            cleanupVehicleFly()
        end
    end
end


)

VisualsTab:CreateSection(
"Body ESP"
)

local BodyHighlight = nil

local function removeBodyHighlight()
if BodyHighlight then
pcall(function()
BodyHighlight:Destroy()
end)
end

BodyHighlight = nil


end

VisualsTab:CreateToggle({
Name = "Body ESP",

CurrentValue = false,

Flag = "BodyESP",

Callback = function(value)
    State.BodyESP = value

    if not value then
        removeBodyHighlight()
    end
end


})

local RareHighlights = {}

local function clearRareHighlights()
for obj, highlight in pairs(
RareHighlights
) do

    pcall(function()
        if highlight then
            highlight:Destroy()
        end
    end)

    RareHighlights[obj] = nil
end


end

VisualsTab:CreateToggle({
Name = "Rare Loot ESP",

CurrentValue = false,

Flag = "RareESP",

Callback = function(value)
    State.RareESP = value

    if not value then
        clearRareHighlights()
    end
end


})

task.spawn(function()
while task.wait(0.35) do
if State.BodyESP then
local body =
Workspace:FindFirstChild(
"Body"
)

        if body then
            if not BodyHighlight
                or BodyHighlight.Parent
                ~= body then

                removeBodyHighlight()

                pcall(function()
                    BodyHighlight =
                        Instance.new(
                            "Highlight"
                        )

                    BodyHighlight.Name =
                        "CVT_BodyESP"

                    BodyHighlight.FillColor =
                        Color3.fromRGB(
                            255,
                            52,
                            66
                        )

                    BodyHighlight.OutlineColor =
                        Color3.fromRGB(
                            255,
                            125,
                            132
                        )

                    BodyHighlight.FillTransparency =
                        0.52

                    BodyHighlight.OutlineTransparency =
                        0.05

                    BodyHighlight.DepthMode =
                        Enum.HighlightDepthMode.AlwaysOnTop

                    BodyHighlight.Parent =
                        body
                end)
            end

        else
            removeBodyHighlight()
        end
    end
end


end)

task.spawn(function()
while task.wait(0.45) do
repeat
if not State.RareESP then
break
end

        local folder =
            Workspace:FindFirstChild(
                "ScatteredLoot"
            )

        if not folder then
            break
        end

        for obj, highlight in pairs(
        RareHighlights
    ) do

        if not obj
            or not obj.Parent
            or not highlight
            or not highlight.Parent then

            pcall(function()
                if highlight then
                    highlight:Destroy()
                end
            end)

            RareHighlights[obj] = nil
        end
    end

    for _, item in ipairs(
        folder:GetChildren()
    ) do

        if RARE_LIST[item.Name]
            and not RareHighlights[item] then

            pcall(function()
                local highlight =
                    Instance.new(
                        "Highlight"
                    )

                highlight.Name =
                    "CVT_RareESP"

                highlight.FillColor =
                    Color3.fromRGB(
                        67,
                        153,
                        255
                    )

                highlight.OutlineColor =
                    Color3.fromRGB(
                        121,
                        215,
                        255
                    )

                highlight.FillTransparency =
                    0.52

                highlight.OutlineTransparency =
                    0.05

                highlight.DepthMode =
                    Enum.HighlightDepthMode.AlwaysOnTop

                highlight.Parent = item

                RareHighlights[item] =
                    highlight
            end)
        end
    end
    until true
end


end)

SettingsTab:CreateSection(
"Interface"
)

SettingsTab:CreateKeybind({
Name = "Interface Toggle",

CurrentKeybind = "RightShift",

Flag = "ToggleUI",

Callback = function()
end


})

SettingsTab:CreateButton({
Name = "Save Configuration",

Callback = function()
    pcall(function()
        Rayfield:SaveConfiguration()
    end)

    Rayfield:Notify({
        Title = "Configuration",

        Content =
            "Configuration saved.",

        Duration = 3
    })
end


})

SettingsTab:CreateButton({
Name = "Load Configuration",

Callback = function()
    pcall(function()
        Rayfield:LoadConfiguration()
    end)

    Rayfield:Notify({
        Title = "Configuration",

        Content =
            "Configuration loaded.",

        Duration = 3
    })
end


})

LocalPlayer.CharacterAdded:Connect(function()
restoreNoclip()
restoreVehicleNoclip()

if cleanupVehicleFly then
    cleanupVehicleFly()
end

if PlayerFlyVelocity then
    pcall(function()
        PlayerFlyVelocity:Destroy()
    end)

    PlayerFlyVelocity = nil
end

if PlayerFlyOrientation then
    pcall(function()
        PlayerFlyOrientation:Destroy()
    end)

    PlayerFlyOrientation = nil
end

if PlayerFlyAttachment then
    pcall(function()
        PlayerFlyAttachment:Destroy()
    end)

    PlayerFlyAttachment = nil
end


end)

pcall(function()
Rayfield:LoadConfiguration()
end)

Rayfield:Notify({
Title = "Camper Van Trip",

Content =
    "Just Team Hub loaded.",

Duration = 5


})
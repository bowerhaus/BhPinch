--[[ 
BhPinchDemo.lua

Demo of two finger pinch (drag, rotate and scaling)
and one finger drag for Gideros sprites.
 
MIT License
Copyright (C) 2013. Andy Bower, Bowerhaus LLP

Permission is hereby granted, free of charge, to any person obtaining a copy of this software
and associated documentation files (the "Software"), to deal in the Software without restriction,
including without limitation the rights to use, copy, modify, merge, publish, distribute,
sublicense, and/or sell copies of the Software, and to permit persons to whom the
Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or
substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING
BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,
DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
--]]

application:setBackgroundColor(0x7D83FC)

local function constrainXOnly(sprite, x, y)
	return x, sprite:getY()
end

local function constrainYOnly(sprite, x, y)
	return sprite:getX(), y
end

-- Free drag, rotation and scaling (with two fingers)
local cow1=Bitmap.new(Texture.new("cow1.jpg"))
cow1:setAnchorPoint(0.5, 0.5)
cow1:setPosition(240, 160)
stage:addChild(cow1)
cow1:enablePinch()

-- Drag in X direction only (with single touch), and rotation (two fingers)
local cow2=Bitmap.new(Texture.new("cow2.jpg"))
cow2:setScale(0.25)
cow2:setAnchorPoint(0.5, 0.5)
cow2:setPosition(100, 270)
stage:addChild(cow2)
cow2:enablePinch({allowScale=false, allowDrag=false})
cow2:enableOneTouchDrag({dragConstrainFunc=constrainXOnly, dragWithOneFingerOnly=true})

-- Drag in Y direction only (two fingers)
local cow3=Bitmap.new(Texture.new("cow3.jpg"))
cow3:setScale(0.1)
cow3:setAnchorPoint(0.5, 0.5)
cow3:setPosition(410, 60)
stage:addChild(cow3)
cow3:enablePinch({allowScale=false, allowRotate=false, dragConstrainFunc=constrainYOnly})

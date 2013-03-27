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

-- Use a separate parent container so we can test correct motion within a parent coordinate system
local container=Sprite.new()
stage:addChild(container)
container:setRotation(10)

-- Free drag, rotation and scaling (with one and two fingers)
local cow1=Bitmap.new(Texture.new("cow1.jpg"))
cow1:setScale(0.25)
cow1:setPosition(20, 0)
container:addChild(cow1)
cow1:enablePinch()
cow1:enableOneTouchDrag()

-- Drag in X direction only (relative to parent) with single touch, 
-- and in any direction and rotate with two fingers (no scaling)
--
local cow2=Bitmap.new(Texture.new("cow2.jpg"))
cow2:setScale(0.25)
cow2:setAnchorPoint(0.5, 0.5)
cow2:setPosition(100, 270)
container:addChild(cow2)
cow2:enablePinch({allowScale=false})
cow2:enableOneTouchDrag({dragConstrainFunc=constrainXOnly})

-- Drag in Y direction only (relative to parent) 
-- with one or more fingers.
--
local cow3=Bitmap.new(Texture.new("cow3.jpg"))
cow3:setScale(0.1)
cow3:setAnchorPoint(0.5, 0.5)
cow3:setPosition(410, 60)
container:addChild(cow3)
cow3:enableOneTouchDrag({dragConstrainFunc=constrainYOnly, allowMultitouchDrag=true})

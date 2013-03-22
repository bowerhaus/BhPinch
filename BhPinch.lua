--[[ 
BhPinch.lua

Two finger drag, rotate and scaling for Gideros sprites.
 
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

local function getContentDiagonal()
	return math.pt2dDistance(0, 0, application:getContentWidth(), application:getContentHeight())
end


local PINCH_DEFAULT_DRAG_HYSTERESIS=getContentDiagonal()/15 	-- logical pixels
local PINCH_DEFAULT_SCALE_HYSTERESIS=getContentDiagonal()/15 	-- logical pixels
local PINCH_DEFAULT_ROTATE_HYSTERESIS=20						-- degrees

-- Set the following flag to true if you want an older-style GUI response to
-- overcoming hysteresis. That is, you want the pinch operation to start at the
-- original touch position.
--
local PINCH_OLD_STYLE_HYSTERESIS=false

function Sprite:onPinchTouchBegin(event)
	local allTouches=event.allTouches
	if not(self._pinch) and #allTouches==2 then
		-- We have two fingers down
		local f1=allTouches[1]
		local f2=allTouches[2]
		local mx, my=(f1.x+f2.x)/2, (f1.y+f2.y)/2
		if self:hitTestPoint(mx, my) then
			-- Mid point is within receiver, start the pinch
			local pinch={}
			
			-- Save initial state of receiver
			pinch.initialX, pinch.initialY=self:getPosition()
			pinch.initialScaleX=self:getScaleX()
			pinch.initialScaleY=self:getScaleY()
			pinch.initialRotation=self:getRotation()
			
			-- Save initial pinch
			pinch.f10=f1
			pinch.f20=f2
			pinch.drag0={x=mx, y=my}
			pinch.scale0=math.pt2dDistance(f1.x,f1.y, f2.x, f2.y)
			pinch.rot0=math.pt2dAngle(f1.x,f1.y, f2.x, f2.y)
			
			-- Remember initial fingers ids as indices
			pinch.fingers={}
			pinch.fingers[f1.id]=1
			pinch.fingers[f2.id]=2
			
			-- And as touches
			pinch.touches=table.copy(allTouches)
			
			self._pinch=pinch
			event:stopPropagation()
		end
	end
end

function Sprite:onPinchTouchMove(event)	
	local pinch=self._pinch
	local pinchParams=self._pinchParams
	
	if pinch and pinch.fingers[event.touch.id] then
		-- Save the new touch movement to our correct finger slot
		local thisIndex=pinch.fingers[event.touch.id]
		
		pinch.touches[thisIndex]=event.touch
		
		-- Now work out what to do with the current position of both fingers
		local f1=pinch.touches[1]
		local f2=pinch.touches[2]
		local mx, my=(f1.x+f2.x)/2, (f1.y+f2.y)/2
		local currentScale=math.pt2dDistance(f1.x,f1.y, f2.x, f2.y)
		local currentAngle=math.pt2dAngle(f1.x,f1.y, f2.x, f2.y)
		
		if pinchParams.allowDrag and not(pinch.isDragging) then
			-- Not yet past drag hysteresis
			if math.pt2dDistance(pinch.drag0.x, pinch.drag0.y, mx, my)>pinchParams.dragHysteresis then
				pinch.isDragging=true			
				if not(pinchParams.oldStyleHysteresis) then
					pinch.drag0={x=mx, y=my}
				end
			end
		end
		if pinch.isDragging then
			-- Is really dragging - do it
			local x=mx-pinch.drag0.x+pinch.initialX
			local y=my-pinch.drag0.y+pinch.initialY
			self:setPosition(pinchParams.dragConstrainFunc(self, x, y))
		end
		
		if pinchParams.allowRotate and not(pinch.isRotating) then
			-- Not yet past rotation hysteresis
			if math.abs(currentAngle-pinch.rot0)>pinchParams.rotateHysteresis then
				pinch.isRotating=true
				if not(pinchParams.oldStyleHysteresis) then
					pinch.rot0=math.pt2dAngle(f1.x,f1.y, f2.x, f2.y)
				end
			end
		end
		if pinch.isRotating then
			-- Is really rotating - do it
			local angle=currentAngle-pinch.rot0+pinch.initialRotation
			self:setRotation(pinchParams.rotateConstrainFunc(self, angle))
		end
		
		if pinchParams.allowScale and not(pinch.isScaling) then
			-- Not yet past scale hysteresis
			local delta=math.pt2dDistance(f1.x,f1.y, f2.x, f2.y)-pinch.scale0
			if math.abs(delta)>pinchParams.scaleHysteresis  then
				pinch.isScaling=true
				if not(pinchParams.oldStyleHysteresis) then
					pinch.scale0=math.pt2dDistance(f1.x,f1.y, f2.x, f2.y)
				end
			end
		end
		if pinch.isScaling then
			-- Is really scaling - do it
			local factor=currentScale/pinch.scale0
			local sx, sy=pinchParams.scaleConstrainFunc(self, pinch.initialScaleX*factor, pinch.initialScaleY*factor)
			self:setScaleX(sx)
			self:setScaleY(sy)
		end
		event:stopPropagation()
	end	
end

function Sprite:onPinchTouchEnd(event)	
	local pinch=self._pinch
	if pinch then
		-- If we are pinching checxk to see if this finger up matches one of 
		-- our pinch fingers. If so, terminate the pinch.	
		--
		if pinch.fingers[event.touch.id] then
			self._pinch=nil
		end
		event:stopPropagation()
	end
end

function Sprite:enablePinch(pinchParams)
	local params={}
	pinchParams=pinchParams or {}
	
	params.allowDrag=pinchParams.allowDrag or pinchParams.allowDrag==nil
	params.dragHysteresis=pinchParams.dragHysteresis or PINCH_DEFAULT_DRAG_HYSTERESIS
	params.dragConstrainFunc=pinchParams.dragConstrainFunc or function(obj, x, y) return x, y end
	
	params.allowRotate=pinchParams.allowRotate or pinchParams.allowRotate==nil
	params.rotateHysteresis=pinchParams.rotateHysteresis or PINCH_DEFAULT_ROTATE_HYSTERESIS
	params.rotateConstrainFunc=pinchParams.rotateConstrainFunc or function(obj, a) return a end
	
	params.allowScale=pinchParams.allowScale or pinchParams.allowScale==nil
	params.scaleHysteresis=pinchParams.scaleHysteresis or PINCH_DEFAULT_SCALE_HYSTERESIS
	params.scaleConstrainFunc=pinchParams.scaleConstrainFunc or function(obj, sx, sy) return sx, sy end	
	
	params.oldStyleHysteresis=pinchParams.oldStyleHysteresis or PINCH_OLD_STYLE_HYSTERESIS
	self._pinchParams=params
	
	self:addEventListener(Event.TOUCHES_BEGIN, self.onPinchTouchBegin, self)
	self:addEventListener(Event.TOUCHES_MOVE, self.onPinchTouchMove, self)
	self:addEventListener(Event.TOUCHES_END, self.onPinchTouchEnd, self)		
end

function Sprite:disablePinch()
	self._pinchParams=nil	
	self:removeEventListener(Event.TOUCHES_BEGIN, self.onPinchTouchBegin, self)
	self:removeEventListener(Event.TOUCHES_MOVE, self.onPinchTouchMove, self)
	self:removeEventListener(Event.TOUCHES_END, self.onPinchTouchEnd, self)		
end
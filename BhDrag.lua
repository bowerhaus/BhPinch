--[[ 
BhDrag.lua

One finger drag for Gideros sprites.
 
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

local DRAG_DEFAULT_HYSTERESIS=getContentDiagonal()/15 	-- logical pixels

-- Set the following flag to true if you want an older-style GUI response to
-- overcoming hysteresis. That is, you want the drag operation to start at the
-- original touch position.
--
local DRAG_OLD_STYLE_HYSTERESIS=false

function Sprite:onOneTouchDragTouchBegin(event)
	if not(self._drag) and self:isVisibleDeeply() then
		local dragParams=self._dragParams
	
		if dragParams.dragWithOneFingerOnly and #event.allTouches>1 then
			-- If our options specify use of only one finger then ignore
			-- this touch if several are held down.
			return
		end
		
		-- We have a finger down
		local finger=event.touch
		if self:hitTestPoint(finger.x, finger.y) then
			-- Touch point is within receiver, start the drag
			local drag={}
			
			-- Save initial state of receiver
			drag.initialX, drag.initialY=self:getPosition()
			
			-- Save initial drag
			drag.f0=table.copy(finger)
			drag.touchId=finger.id
			
			self._drag=drag
			event:stopPropagation()
		end
	end
end

function Sprite:onOneTouchDragTouchMove(event)	
	local drag=self._drag
	local dragParams=self._dragParams
	
	if drag and event.touch.id==drag.touchId then		
		local fx, fy=event.touch.x, event.touch.y
		if not(drag.isDragging) then
			-- Not yet past drag hysteresis
			if math.pt2dDistance(drag.f0.x, drag.f0.y, fx, fy)>dragParams.dragHysteresis then
				drag.isDragging=true
				if not(dragParams.oldStyleHysteresis) then
					drag.f0=table.copy(event.touch)
				end
			end
		end
		if drag.isDragging then
			-- Is really dragging - do it
			local x=fx-drag.f0.x+drag.initialX
			local y=fy-drag.f0.y+drag.initialY
			self:setPosition(dragParams.dragConstrainFunc(self, x, y))
		end
	event:stopPropagation()
	end	
end

function Sprite:onOneTouchDragTouchEnd(event)	
	local drag=self._drag
	if drag and event.touch.id==drag.touchId then	
		-- If we are draging check to see if this finger up matches
		-- our drag finger. If so, terminate the drag operation.	
		--
		self._drag=nil
		event:stopPropagation()
	end
end

function Sprite:enableOneTouchDrag(dragParams)
	local params={}
	dragParams=dragParams or {}
	
	params.dragHysteresis=dragParams.dragHysteresis or DRAG_DEFAULT_HYSTERESIS
	params.dragConstrainFunc=dragParams.dragConstrainFunc or function(obj, x, y) return x, y end
	params.dragWithOneFingerOnly=dragParams.dragWithOneFingerOnly or false
	params.oldStyleHysteresis=dragParams.oldStyleHysteresis or DRAG_OLD_STYLE_HYSTERESIS
	self._dragParams=params
	
	self:addEventListener(Event.TOUCHES_BEGIN, self.onOneTouchDragTouchBegin, self)
	self:addEventListener(Event.TOUCHES_MOVE, self.onOneTouchDragTouchMove, self)
	self:addEventListener(Event.TOUCHES_END, self.onOneTouchDragTouchEnd, self)		
end

function Sprite:disableOneTouchDrag()
	self._dragParams=nil	
	self:removeEventListener(Event.TOUCHES_BEGIN, self.onOneTouchDragTouchBegin, self)
	self:removeEventListener(Event.TOUCHES_MOVE, self.onOneTouchDragTouchMove, self)
	self:removeEventListener(Event.TOUCHES_END, self.onOneTouchDragTouchEnd, self)		
end
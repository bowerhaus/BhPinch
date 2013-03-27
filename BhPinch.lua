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

local PINCH_DEFAULT_DRAG_HYSTERESIS=0 		-- logical pixels
local PINCH_DEFAULT_SCALE_HYSTERESIS=0 		-- logical pixels
local PINCH_DEFAULT_ROTATE_HYSTERESIS=0		-- degrees

-- The following code relies on matrix operations that are not available as standard in Gideros.
-- They are present in Arturs Soisin's GiderosCodingEasy library: https://github.com/ar2rsawseen/GiderosCodingEasy
-- but as of 26/MAR/13 there appears to be a bug in the matrix multiplication in that library so I'm
-- including a copy of the relevant methods here. Because of this, you can also use BhPinch without GiderosCodingEasy
-- if required.

function Matrix:rotate(deg)
	local rad = math.rad(deg)
	return self:multiply(Matrix.new(math.cos(rad), math.sin(rad), -math.sin(rad), math.cos(rad), 0, 0))
end

function Matrix:translate(x,y)
	if not y then y = x end
	return self:multiply(Matrix.new(1, 0, 0, 1, x, y))
end

function Matrix:scale(x,y)
	if not y then y = x end
	return self:multiply(Matrix.new(x, 0, 0, y, 0, 0))
end

function Matrix:multiply(matrix)
	local m11 = matrix:getM11()*self:getM11() + matrix:getM12()*self:getM21()
	local m12 = matrix:getM11()*self:getM12() + matrix:getM12()*self:getM22()
	local m21 = matrix:getM21()*self:getM11() + matrix:getM22()*self:getM21()
	local m22 = matrix:getM21()*self:getM12() + matrix:getM22()*self:getM22()
	local tx  = matrix:getM11()*self:getTx()  + matrix:getM12()*self:getTy() + matrix:getTx()
	local ty  = matrix:getM21()*self:getTx()  + matrix:getM22()*self:getTy() + matrix:getTy()
	self:setElements(m11, m12, m21, m22, tx, ty)
	return self
end

function Matrix:copy()
	return Matrix.new(self:getElements())
end

function Sprite:onPinchTouchBegin(event)
	local allTouches=event.allTouches
	if not(self._pinch) and #allTouches==2 and self:isVisibleDeeply() then
		-- We have two fingers down
		local f1=allTouches[1]
		local f2=allTouches[2]
		local mx, my=(f1.x+f2.x)/2, (f1.y+f2.y)/2
		if (self:hitTestPoint(f1.x, f1.y) or self:hitTestPoint(f2.x, f2.y)) and self:hitTestPoint(mx, my) then
			-- Mid point is within receiver, start the pinch
			local pinch={}
			
			-- Save initial state of receiver
			pinch.initialX, pinch.initialY=self:getPosition()
			pinch.initialScaleX=self:getScaleX()
			pinch.initialScaleY=self:getScaleY()
			pinch.initialRotation=self:getRotation()
			pinch.initialMatrix=self:getMatrix()
			
			-- Save initial pinch (all coordinates are relative to parent)
			local parent=self:getParent()
			f1.x, f1.y=parent:globalToLocal(f1.x, f1.y)
			f2.x, f2.y=parent:globalToLocal(f2.x, f2.y)
			mx, my=(f1.x+f2.x)/2, (f1.y+f2.y)/2
			
			pinch.f10=f1
			pinch.f20=f2
			pinch.drag0={x=mx, y=my}
			pinch.scale0=math.pt2dDistance(f1.x,f1.y, f2.x, f2.y)
			pinch.rot0=math.pt2dAngle(f1.x,f1.y, f2.x, f2.y)
			
			local _, _, w, h=self:getBounds(self)
			local ax, ay=0, 0
			if self.getAnchorPoint then
				ax, ay=self:getAnchorPoint()
			end
			local px=w*(0.5-ax)
			local py=h*(0.5-ay)
			pinch.gx, pinch.gy=self:localToLocal(px, py, parent)
			
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
		local parent=self:getParent()
		local f1=pinch.touches[1]
		local f2=pinch.touches[2]
		f1.x, f1.y=parent:globalToLocal(f1.x, f1.y)
		f2.x, f2.y=parent:globalToLocal(f2.x, f2.y)
		local mx, my=(f1.x+f2.x)/2, (f1.y+f2.y)/2
		
		-- Use rudimentatry 8 period exponential moving averages to smooth angle and scale changes.
		local alpha=2/(8+1)
		local currentScale=math.pt2dDistance(f1.x,f1.y, f2.x, f2.y)	
		if pinch.smoothedScale then 
			pinch.smoothedScale=pinch.smoothedScale+alpha*(currentScale-pinch.smoothedScale)
		else 
			pinch.smoothedScale=currentScale
		end
		
		local currentAngle=math.pt2dAngle(f1.x,f1.y, f2.x, f2.y)
		if pinch.smoothedAngle and math.abs(currentAngle-pinch.smoothedAngle)<45 then
			pinch.smoothedAngle=pinch.smoothedAngle+alpha*(currentAngle-pinch.smoothedAngle)
		else 
			pinch.smoothedAngle=currentAngle
		end
		
		local x, y, angle
		local dx, dy, dangle, dscaleX, dscaleY=0, 0, 0, 1, 1	
		
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
			-- Is really dragging?		
			-- Calculate new x, y coordinates and constrain them
			x=mx-(pinch.drag0.x-pinch.initialX)
			y=my-(pinch.drag0.y-pinch.initialY)		
			x, y=pinchParams.dragConstrainFunc(self, x, y)
			
			-- Compute delta from original location
			dx=x-pinch.initialX
			dy=y-pinch.initialY			
		end
		
		if pinchParams.allowRotate and not(pinch.isRotating) then
			-- Not yet past rotation hysteresis
			if math.abs(currentAngle-pinch.rot0)>pinchParams.rotateHysteresis then
				pinch.isRotating=true
			end
		end
		if pinch.isRotating then
			-- Is really rotating
			local rotationOffset0=pinch.rot0-pinch.initialRotation
			local angle=pinchParams.rotateConstrainFunc(self, pinch.smoothedAngle-rotationOffset0)		
			dangle=angle-pinch.initialRotation
		end
		
		if pinchParams.allowScale and not(pinch.isScaling) then
			-- Not yet past scale hysteresis
			local delta=math.pt2dDistance(f1.x,f1.y, f2.x, f2.y)-pinch.scale0
			if math.abs(delta)>pinchParams.scaleHysteresis  then
				pinch.isScaling=true
			end
		end
		if pinch.isScaling then
			-- Is really scaling - do it
			local factor=pinch.smoothedScale/pinch.scale0
			local sx, sy=pinchParams.scaleConstrainFunc(self, pinch.initialScaleX*factor, pinch.initialScaleY*factor)
			dscaleX=sx/pinch.initialScaleX
			dscaleY=sy/pinch.initialScaleY
		end
								
		-- Build new transform and apply it
		local matrix=pinch.initialMatrix:copy()		
		matrix:translate(-pinch.gx, -pinch.gy)
		matrix:rotate(-dangle)
		matrix:scale(dscaleX, dscaleY)
		matrix:translate(pinch.gx+dx, pinch.gy+dy)
		self:setMatrix(matrix)
		
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
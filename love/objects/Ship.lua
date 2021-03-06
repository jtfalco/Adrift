love.filesystem.require("oo.lua")
love.filesystem.require("objects/composable/SimplePhysicsObject.lua")
love.filesystem.require("objects/ControlSchemes.lua")

Ship = {
  super = SimplePhysicsObject,
  
  thrust = 10,
  
  cvx = nil,
  thruster = nil,
  engine = nil,
  controller = nil,
  
  gun = nil,
  bulletColor = love.graphics.newColor(0,0,255),
  bulletHighlightColor = love.graphics.newColor(100,100,255,200),
  
  
  circColor = love.graphics.newColor(32,64,128),
  triColor = love.graphics.newColor(64,128,255),
  cryColor = love.graphics.newColor(255,255,255),
  healthColor = love.graphics.newColor(255,255,255),
  
  hasCrystal = false,
  hasFieldDetector = false,
  
  create = function(self, world, x, y, controlSchemeNumber)
    local bd = love.physics.newBody(world,x,y)
    local sh = love.physics.newCircleShape(bd,0.375)
    bd:setMass(0,0,1,1)
    bd:setDamping(0.1)
    bd:setAngularDamping(0.1)
    bd:setAllowSleep(false)
    sh:setRestitution(0.125)
    bd:setAngle(0)
    
    local result = SimplePhysicsObject:create(bd,sh); result.superUpdate = result.update
    mixin(result, DamageableObject:prepareAttribute(20,nil,love.audio.newSound("sound/hornetDeath.ogg"),0))
    mixin(result, Ship)
    result.class = Ship
    
    result.thruster = FireThruster:create(result, 180)
    result.engine = Engine:create(result,Ship.thrust,2,12)
    
    result.controller = ControlSchemes[controlSchemeNumber]
    if result.controller.directional then result.engine.turnRate = 32 end
    
    result.gun = SimpleGun:create(result, 0.5, 0, 0, 5, Ship.bulletColor, Ship.bulletHighlightColor)
    
    local s = 0.375
    local pointArray = {1*s,0*s, s*math.cos(math.pi*5/6),s*math.sin(math.pi*5/6), s*math.cos(math.pi*7/6),s*math.sin(math.pi*7/6)}
    result.cvx = Convex:create(result, pointArray, Ship.triColor, Ship.triColor)
    
    return result
  end,

  -- takes an existing ship and puts it, otherwise unchanged, into a new physics world at a new location.
  warp = function(self, world, x, y)
    self.hasCrystal = false
    local bd = love.physics.newBody(world,x,y)
    local sh = love.physics.newCircleShape(bd,0.375)
    bd:setMass(0,0,1,1)
    bd:setDamping(0.1)
    bd:setAngularDamping(0.1)
    bd:setAllowSleep(false)
    sh:setRestitution(0.125)
    bd:setAngle(0)
    
    self.body = bd
    self.shape = sh
    self.shape:setData(self)
  end,
  
  draw = function(self)
    self.thruster:draw()
    
    love.graphics.setColor(self.circColor)
    local cx, cy, radius = camera:xy(self.x,self.y,0)
    love.graphics.circle(love.draw_fill,cx,cy,0.375*radius,32)
    
    if self.hasCrystal then 
      self.cvx.fillColor = Ship.cryColor
    else
      self.cvx.fillColor = Ship.triColor
    end
    self.cvx:draw()
    
    if state.current == state.game then
      love.graphics.setColor(self.healthColor)
      love.graphics.rectangle(love.draw_fill,100,590, 700 * self.armor / self.maxArmor,10)
      love.graphics.draw("HP: " .. tostring(self.armor) .. " / " .. tostring(self.maxArmor), 15,598)
    end
  end,
  
  update = function(self, dt)
    self:superUpdate(dt)
  
    local targVx, targVy, isFiring = self.controller:getAction(self,dt)
    local overallThrust = self.engine:vector(targVx, targVy, dt)
    self.thruster:setIntensity(overallThrust*7.5)
    self.thruster:update(dt)
  
    if isFiring then self.gun:fire() end
    self.gun:update(dt)
  end,
}


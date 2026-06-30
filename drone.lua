---FPV drone class, to use it in your chips.
---You can do anything with it, but there's some restrictions from StarfallEx

-- Hooks:
-- "FPVDroneThink(drone)"
-- "FPVDroneDamage(drone, target, attacker, inflictor, amount, type, position, force, took)"
-- "FPVDroneDeath(drone)"

--@name FPV drone class
--@author
--@shared


if SERVER then
    --
    -- Some libs: hitbox lib and hologram creator lib. Just to make readable code
    -- Big thanks to AstricUnion, for movement code and libs!
    --
    --@include https://raw.githubusercontent.com/AstricUnion/Libs/refs/heads/main/hitbox.lua as hitbox
    --@include https://raw.githubusercontent.com/AstricUnion/Libs/refs/heads/main/holos.lua as holos
    ---@module 'astricunion.libs.hitbox'
    local hitbox = require("hitbox")

    ---@module 'astricunion.libs.holos'
    local holosLib = require("holos")
    ---@class Holo
    local Holo = holosLib.Holo
    local SubHolo = holosLib.SubHolo
    local Rig = holosLib.Rig

    ---Function with holos
    local function holos(cameraAngle, kamikadze)
        return {
            base = hologram.createPart(
                Holo(Rig()),
                Holo(SubHolo(Vector(0, 0, 4.2), Angle(0, -45, 0), "models/mechanics/solid_steel/type_a_3_6.mdl", Vector(0.3, 0.3, 0.3))),
                Holo(SubHolo(Vector(0, 0, 4.2), Angle(0, 45, 0), "models/mechanics/solid_steel/type_a_3_6.mdl", Vector(0.3, 0.3, 0.3))),
                Holo(SubHolo(Vector(3, 3, 4), Angle(0, -45, -60), "models/phxtended/bar1x.mdl", Vector(0.12, 0.1, 0.12))),
                Holo(SubHolo(Vector(-3, -3, 4), Angle(0, 135, -60), "models/phxtended/bar1x.mdl", Vector(0.12, 0.1, 0.12))),
                Holo(SubHolo(Vector(-3, 3, 4), Angle(0, 45, -60), "models/phxtended/bar1x.mdl", Vector(0.12, 0.1, 0.12))),
                Holo(SubHolo(Vector(3, -3, 4), Angle(0, -135, -60), "models/phxtended/bar1x.mdl", Vector(0.12, 0.1, 0.12))),
                Holo(SubHolo(Vector(2, 0, 4.5), Angle(cameraAngle, 0, 0), "models/maxofs2d/lamp_flashlight.mdl", Vector(0.3, 0.3, 0.3))),
                Holo(SubHolo(Vector(-2, 0, 4.5), Angle(90, 0, 0), "models/props_lab/servers.mdl", Vector(0.05, 0.05, 0.05))),
                kamikadze and Holo(SubHolo(Vector(0, 0, -0.3), Angle(0, 0, 0), "models/props_phx/mk-82.mdl", Vector(0.15, 0.2, 0.2))) or nil,
                kamikadze and Holo(SubHolo(Vector(0, 0, 5), Angle(180, 0, 0), "models/props_borealis/mooring_cleat01.mdl", Vector(0.2, 0.1, 0.2))) or nil
            ),
            propellers = {
                SubHolo(Vector(7.7, 7.7, 4.4), Angle(0, 0, 0), "models/props_phx/misc/propeller2x_small.mdl", Vector(0.1, 0.1, 0.1)),
                SubHolo(Vector(-7.7, -7.7, 4.4), Angle(0, 0, 0), "models/props_phx/misc/propeller2x_small.mdl", Vector(0.1, 0.1, 0.1)),
                SubHolo(Vector(7.7, -7.7, 4.4), Angle(0, 0, 0), "models/props_phx/misc/propeller2x_small.mdl", Vector(0.1, 0.1, 0.1)),
                SubHolo(Vector(-7.7, 7.7, 4.4), Angle(0, 0, 0), "models/props_phx/misc/propeller2x_small.mdl", Vector(0.1, 0.1, 0.1))
            },
            camera = Rig(Vector(2, 0, 5), Angle(cameraAngle, 0, 0))
        }
    end


    ---Drone class. Yes, you can include it to other chip, if you want
    ---@class Drone
    ---@field driver Player?
    ---@field kamikadze boolean
    ---@field power number
    ---@field body table
    ---@field phys PhysObj
    ---@field drone Entity
    ---@field maxGas number
    ---@field mouseAngle Angle
    ---@field gasScale number
    Drone = {}
    Drone.__index = Drone


    ---Initialize new drone and spawn it
    ---@param dronePos Vector
    ---@param droneAngle Angle
    ---@param kamikadze? boolean
    ---@param cameraAngle? number
    ---@param gasScale? number
    ---@param maxGas? number
    ---@return Drone
    function Drone:spawn(dronePos, droneAngle, kamikadze, cameraAngle, gasScale, maxGas, health)
        kamikadze = kamikadze == false and false or true
        cameraAngle = cameraAngle or -45
        gasScale = gasScale or 5
        maxGas = maxGas or 500
        health = health or 50

        ---Chip constant position
        local CHIPPOS = chip():getPos()

        -- Create drone holograms
        local body = holos(cameraAngle, kamikadze)

        -- Create drone hitbox and physics object
        local drone = hitbox.cube(CHIPPOS + Vector(0, 0, 3), Angle(), Vector(10, 10, 3), false)
        drone:setHealth(health)
        drone:setMaxHealth(health)

        -- Parent all to all
        body.base:setParent(drone)
        body.camera:setParent(drone)
        for _, propeller in ipairs(body.propellers) do
            propeller:setParent(body.base)
        end

        -- After initialization, place drone on start position
        drone:setPos(dronePos)
        drone:setAngles(droneAngle)
        drone:setDrawShadow(false)
        drone:setMass(100)

        -- Receive physics object of drone
        local phys = drone:getPhysicsObject()

        local obj = setmetatable(
            {
                driver = nil,
                kamikadze = kamikadze,
                power = 0,
                body = body,
                phys = phys,
                drone = drone,
                maxGas = maxGas or 500,
                gasScale = gasScale or 5,
                mouseAngle = Angle()
            },
            Drone
        )

        -- Hooks
        do
            local index = tostring(drone:entIndex())

            -- Damage on colliding
            drone:addCollisionListener(function()
                local velo = math.max(obj.drone:getVelocity():getLength() - 300, 0)
                local amount = velo / 10
                drone:applyDamage(amount, obj.drone, obj.drone, DAMAGE.CRUSH)
            end)

            -- Damage on... damage
            -- Why? Because prop don't have hooks on damage, I write it here, in Starfall
            hook.add("PostEntityTakeDamage", "FPVDroneDamage" .. index, function(...)
                obj:PostEntityTakeDamage(...)
            end)

            -- And finally, movement

            -- Hook for all movement
            hook.add("Think", "FPVDroneThink" .. index, function() obj:Think() end)

            -- ...and mouse coordinates
            net.receive("MouseStream" .. index, function()
                obj.mouseAngle = Angle(net.readInt(8), net.readInt(8), 0)
            end)
        end

        return obj
    end


    ---Damage hook
    ---@param target Entity
    ---@param attacker any
    ---@param inflictor any
    ---@param amount number
    ---@param type number
    ---@param position Vector
    ---@param force Vector
    ---@param took boolean
    function Drone:PostEntityTakeDamage(target, attacker, inflictor, amount, type, position, force, took)
        if target ~= self.drone then return end
        local health = self.drone:getHealth()
        local totalhealth = health - amount
        self.drone:setHealth(totalhealth)
        if totalhealth <= 0 then
            self:death()
        end
        hook.run("FPVDroneDamage", self, target, attacker, inflictor, amount, type, position, force, took)
    end


    ---Death of drone
    function Drone:death()
        -- Hook removing
        local index = tostring(self.drone:entIndex())
        hook.remove("PostEntityTakeDamage", "FPVDroneDamage" .. index)
        hook.remove("Think", "FPVDroneThink" .. index)
        self.drone:stopSound("npc/attack_helicopter/aheli_rotor_loop1.wav")
        self.drone:remove()
        -- If kamikadze, then explode drone
        if self.kamikadze then
    pcall(function()
        local pos = self.drone:getPos()

        -- Красивый эффект
        effect.create("Explosion", pos)

        -- Урон
        blastDamage(
            self.driver or self.drone,
            self.driver or self.drone,
            pos,
            350, -- радиус
            250  -- максимальный урон
        )

        -- Звук
        sound.play(
            "BaseExplosionEffect.Sound",
            pos,
            100,
            100
        )
    end)
end
 
timer.simple(1, function()
        self:resetDriver()
        hook.run("FPVDroneDeath", self)
    end)
end


    ---Function to set propeller velocity
    function Drone:setPropellerVelocity(vel)
        self.drone:emitSound("npc/attack_helicopter/aheli_rotor_loop1.wav", 75, 200, (vel / self.maxGas * 100), CHAN_WEAPON)
        self.body.propellers[1]:setLocalAngularVelocity(Angle(0, -vel, 0))
        self.body.propellers[2]:setLocalAngularVelocity(Angle(0, vel, 0))
        self.body.propellers[3]:setLocalAngularVelocity(Angle(0, vel, 0))
        self.body.propellers[4]:setLocalAngularVelocity(Angle(0, -vel, 0))
    end

    ---Get button axis
    ---@param negative number
    ---@param positive number
    ---@return number
    function Drone:buttonAxis(negative, positive)
        if !self.driver then return 0 end
        return (self.driver:keyDown(positive) and 1 or 0) - (self.driver:keyDown(negative) and 1 or 0)
    end


    ---Drone think hook, substantially movement
    function Drone:Think()
        -- Damage in water and losing controls
        if self.drone:getWaterLevel() >= 2 then
            self.drone:applyDamage(1, self.drone, self.drone)
            return
        end
        if self.driver and isValid(self.driver) and self.driver:isAlive() then
            -- Add to velocity value from buttons, multiplied by 5 (comments are very funny and interesting...)
            local addToVelocity = self:buttonAxis(IN_KEY.BACK, IN_KEY.FORWARD) * self.gasScale
            self.power = math.clamp(self.power + addToVelocity, 0, self.maxGas)

            -- Set velocity, with inertia
            if self.power ~= 0 then
                self.phys:addVelocity(self.drone:getUp() * self.power - self.phys:getVelocity() / 50)
            end

            -- Set propeller angular velocity
            local angular = self.power * 100
            self:setPropellerVelocity(angular)

            -- Set angular velocity to drone. Firstly, receive an eye angles
            local eyeAngles = self.mouseAngle

            -- Move drone on left and right by roll
            local buttons = Vector(0, 0, self:buttonAxis(IN_KEY.MOVELEFT, IN_KEY.MOVERIGHT) * 5)

            -- some magic
            local angle = eyeAngles + buttons
            local angvel = angle:getQuaternion():getRotationVector() * 4 - self.phys:getAngleVelocity() / 5
            self.phys:addAngleVelocity(angvel)

            self.mouseAngle = Angle()
            hook.run("FPVDroneThink", self)
        else
            self.driver = nil
        end
    end


    ---Set driver of drone
    ---@param ply Player
    function Drone:setDriver(ply)
        self.driver = ply
        enableHud(ply, true)
        ply:setViewEntity(self.body.camera)
        net.start("DroneOn")
        net.writeEntity(self.drone)
        net.send(self.driver)
    end


    ---Reset driver of drone
    function Drone:resetDriver()
        if self.driver and isValid(self.driver) then
            self.driver:setViewEntity()
            enableHud(self.driver, false)
            net.start("DroneOff")
            net.send(self.driver)
        end
        self.driver = nil
        if isValid(self.drone) then
            self:setPropellerVelocity(0)
            self.power = 0
        end
    end

    ---Is drone valid
    function Drone:isValid()
        return self.drone:isValid()
    end
else

    local function marks(x, y, height)
        local xOffset = x
        local yOffset = y - height / 2
        local space = height / 15 + 3
        for i=1, 15 do
            if i % 2 == 0 then
                render.drawRect(xOffset - 4, yOffset + i * space - 2, 8, 4)
            else
                render.drawRect(xOffset - 8, yOffset + i * space - 1, 16, 2)
            end
        end
    end

    local function noiseRenderTarget()
        local noise = material.load("effects/security_noise2")
        render.selectRenderTarget("noise")
        do
            render.setMaterialEffectDownsample(noise, 0, 1.5)
            render.drawTexturedRectUV(math.random(-2000, 0), math.random(-10, 0), 3024, 1034, 0, 0, 10, 10)
            render.setMaterial()
        end
        render.selectRenderTarget()
    end

    local function createHud(drone)
        render.createRenderTarget("noise")
        local id = drone:entIndex()
        local sw, sh, center

        hook.add("RenderOffscreen", "FPVDroneRender", function()
            noiseRenderTarget()
        end)

        hook.add("DrawHUD", "FPVDroneHud", function()
            sw, sh = render.getGameResolution()
            center = {x = sw * 0.5, y = sh * 0.5}

            if isValid(drone) then
                -- Horizontal
                local angs = drone:getAngles()

                -- Get pitch cos
                local pRads = math.rad(angs.p + 90)
                local pRotation = math.cos(pRads) * sw * 0.2
                -- Get roll sin and cos, to make horizontal rotation
                local rRads = math.rad(angs.r + 90)
                local rRotationX = math.sin(rRads)
                local rRotationY = math.cos(rRads)
                for i=1,sw * 0.01 do
                    local radius = (i * 20)
                    local xOffset = rRotationX * radius
                    local yOffset = rRotationY * radius
                    render.drawRectRotated(center.x + xOffset, center.y - 1 + yOffset + pRotation, 10, 2, -angs.r)
                    render.drawRectRotated(center.x - xOffset, center.y - 1 - yOffset + pRotation, 10, 2, -angs.r)
                end

                -- Marks
                marks(sw * 0.2, center.y, sh * 0.6)
                marks(sw * 0.8, center.y, sh * 0.6)
                local first = center.x - sw * 0.3 + 20
                for i=0, 2 do
                    render.drawLine(first + 20 - i, center.y, first, center.y - 20 + i)
                    render.drawLine(first + 20 - i, center.y, first, center.y + 20 - i)
                end
                local second = center.x + sw * 0.3 - 20
                for i=0, 2 do
                    render.drawLine(second - 20 + i, center.y, second, center.y - 20 + i)
                    render.drawLine(second - 20 + i, center.y, second, center.y + 20 - i)
                end

                -- Crosshair
                render.drawCircle(center.x, center.y, 6)
                render.drawCircle(center.x, center.y, 5)
                render.drawLine(center.x - 20, center.y, center.x - 5, center.y)
                render.drawLine(center.x + 20, center.y, center.x + 5, center.y)
                render.drawLine(center.x, center.y - 10, center.x, center.y - 5)
                render.drawLine(center.x, center.y + 10, center.x, center.y + 5)

                -- Noise overlay
                render.setMaterialEffectSub("noise")
                for _=0, (1 - drone:getHealth() / drone:getMaxHealth()) * 50 do
                    render.drawTexturedRect(0, 0, sw, sh)
                end
            else
                -- Opaque noise
                render.setMaterialEffectDownsample("noise", 0.8, 2.5)
                render.drawTexturedRect(0, 0, sw, sh)
            end
            render.setMaterial()
        end)

        hook.add("MouseMoved", "FPVDroneAnglesMovement", function(x, y)
            if !center or !sw or !sh then return end
            net.start("MouseStream" .. tostring(id))
            net.writeInt((y / center.y) * 90, 8)
            net.writeInt((x / center.x) * -90, 8)
            net.send()
        end)
    end

    local function removeHud()
        hook.remove("RenderOffscreen", "FPVDroneRender")
        hook.remove("DrawHUD", "FPVDroneHud")
        hook.remove("MouseMoved", "FPVDroneAnglesMovement")
        render.destroyRenderTarget("noise")
    end


    net.receive("DroneOn", function()
        net.readEntity(function(drone)
            createHud(drone)
        end)
    end)


    net.receive("DroneOff", function()
        removeHud()
    end)
end


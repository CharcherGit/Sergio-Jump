-- jugador.lua

local Jugador = {}
Jugador.__index = Jugador

local Utils = require "utils"

function Jugador:new(imagen, x, y, escala, controles)
    local obj = {
        imagen = imagen,
        x = x,
        y = y,
        velocidad = 300,
        saltando = false,
        velocidadSalto = 0,
        gravedad = 1500,
        escala = escala,
        escalaX = 1,
        ancho = imagen:getWidth() * escala,
        alto = imagen:getHeight() * escala,
        saltosDisponibles = 2,
        radioBate = 50,  -- Radio de alcance del bate
        fuerzaEmpuje = 300,  -- Fuerza del empuje
        controles = controles,  -- Asegúrate de que esto esté aquí
        usosEmpuje = 3  -- Añade esto si no estaba ya
    }
    setmetatable(obj, Jugador)
    return obj
end

function Jugador:update(dt, ancho_pantalla, alto_pantalla)
    -- Mover jugador
    local dx = 0
    if self.controles == 'arrows' then
        if love.keyboard.isDown('left') then
            dx = -self.velocidad * dt
            self.escalaX = -1
        elseif love.keyboard.isDown('right') then
            dx = self.velocidad * dt
            self.escalaX = 1
        end
        self.empujeActivo = love.keyboard.isDown('lctrl') and self.usosEmpuje > 0
    elseif self.controles == 'wasd' then
        if love.keyboard.isDown('a') then
            dx = -self.velocidad * dt
            self.escalaX = -1
        elseif love.keyboard.isDown('d') then
            dx = self.velocidad * dt
            self.escalaX = 1
        end
        self.empujeActivo = love.keyboard.isDown('g') and self.usosEmpuje > 0
    end

    -- Aplicar movimiento con límite de velocidad
    self.x = math.max(self.ancho/2, math.min(self.x + dx, ancho_pantalla - self.ancho/2))

    -- Aplicar gravedad y salto
    self.velocidadSalto = math.min(self.velocidadSalto + self.gravedad * dt, 1000) -- Limitar velocidad de caída
    self.y = self.y + self.velocidadSalto * dt

    -- Comprobar colisión con el suelo
    local suelo = alto_pantalla - self.alto
    if self.y >= suelo then
        self.y = suelo
        self.saltando = false
        self.velocidadSalto = 0
        self.saltosDisponibles = 2
    end

    -- Actualizar el estado del power-up
    self.empujeActivo = love.keyboard.isDown('lctrl') and self.usosEmpuje > 0
end

function Jugador:saltar()
    if self.saltosDisponibles > 0 then
        self.saltando = true
        self.velocidadSalto = -600
        self.saltosDisponibles = self.saltosDisponibles - 1
    end
end

function Jugador:draw()
    love.graphics.draw(self.imagen, self.x, self.y, 0, 
        self.escala * self.escalaX, self.escala, 
        self.imagen:getWidth() / 2, 
        self.imagen:getHeight())
    
    -- Dibujar el rectángulo de colisión (para depuración)
    -- love.graphics.rectangle("line", self.x - self.ancho/2, self.y - self.alto, self.ancho, self.alto)
    
    -- Dibujar el área de alcance del bate cuando el power-up está activo
    if self.empujeActivo then
        love.graphics.setColor(0, 1, 0, 0.3)  -- Verde semitransparente
        love.graphics.circle("fill", self.x, self.y - self.alto/2, self.radioBate)
        love.graphics.setColor(1, 1, 1, 1)
    end
end

return Jugador
local Misil = {}
Misil.__index = Misil

local Utils = require "utils"

function Misil:new(imagen, x, y, parametros)
    local misil = setmetatable({}, Misil)
    misil.imagen = imagen
    misil.x = x
    misil.y = y
    misil.vx = -parametros.velocidad
    misil.vy = love.math.random(-50, 50)
    misil.aceleracion = 100
    misil.radio = parametros.radio or 15
    misil.escala = parametros.escala or 1
    misil.tiempoVida = 5  -- Tiempo de vida en segundos
    return misil
end

function Misil:update(dt, ancho_pantalla, alto_pantalla)
    -- Actualizar velocidad
    self.vx = self.vx - self.aceleracion * dt
    
    -- Actualizar posición
    self.x = self.x + self.vx * dt
    self.y = self.y + self.vy * dt
    
    -- Rebotar en los bordes superior e inferior
    if self.y - self.radio < 0 then
        self.y = self.radio
        self.vy = -self.vy
    elseif self.y + self.radio > alto_pantalla then
        self.y = alto_pantalla - self.radio
        self.vy = -self.vy
    end
    
    -- Reducir el tiempo de vida
    self.tiempoVida = self.tiempoVida - dt
    
    -- Devolver true si el misil debe ser eliminado
    return self.tiempoVida <= 0 or self.x + self.radio < 0
end

function Misil:draw()
    love.graphics.draw(self.imagen, self.x, self.y, 0, 
        self.escala, self.escala, 
        self.imagen:getWidth() / 2, 
        self.imagen:getHeight() / 2)
end

function Misil:colisionaCon(jugador)
    return Utils.colisionCirculoRectangulo(
        self.x, self.y, self.radio,
        jugador.x - jugador.ancho/2, jugador.y - jugador.alto,
        jugador.ancho, jugador.alto
    )
end

return Misil
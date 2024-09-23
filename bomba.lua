-- bomba.lua

local Bomba = {}
Bomba.__index = Bomba

local Utils = require "utils"

function Bomba:new(imagen, x, y, parametros)
    local bomba = setmetatable({}, Bomba)
    bomba.imagen = imagen
    bomba.x = x
    bomba.y = y
    bomba.escala = 0.08  -- Tamaño reducido
    bomba.radio = (imagen:getWidth() * bomba.escala) / 2
    
    -- Parámetros de física ajustados
    bomba.vx = love.math.random(-100, 100)
    bomba.vy = love.math.random(50, 150)  -- Velocidad inicial hacia abajo
    bomba.gravedad = 150  -- Gravedad reducida
    bomba.rotacion = 0
    bomba.velocidadRotacion = love.math.random(-3, 3)
    
    -- Sistema de rebotes
    bomba.rebotesMaximos = 4
    bomba.rebotesActuales = 0
    bomba.coeficienteRebote = 0.8  -- Coeficiente de restitución
    
    -- Parámetros para el comportamiento errático
    bomba.tiempoProximoCambio = love.math.random(0.5, 1.5)
    bomba.factorErratico = 0.3
    
    return bomba
end

function Bomba:update(dt, ancho_pantalla, alto_pantalla)
    -- Actualizar velocidad y posición
    self.vy = self.vy + self.gravedad * dt
    self.x = self.x + self.vx * dt
    self.y = self.y + self.vy * dt
    
    -- Rotación
    self.rotacion = self.rotacion + self.velocidadRotacion * dt
    
    -- Comportamiento errático
    self.tiempoProximoCambio = self.tiempoProximoCambio - dt
    if self.tiempoProximoCambio <= 0 then
        self.vx = self.vx + love.math.random(-50, 50) * self.factorErratico
        self.vy = self.vy + love.math.random(-50, 50) * self.factorErratico
        self.tiempoProximoCambio = love.math.random(0.5, 1.5)
    end
    
    -- Rebotes en los bordes
    local reboto = false
    if self.x - self.radio < 0 then
        self.x = self.radio
        self.vx = math.abs(self.vx) * self.coeficienteRebote
        reboto = true
    elseif self.x + self.radio > ancho_pantalla then
        self.x = ancho_pantalla - self.radio
        self.vx = -math.abs(self.vx) * self.coeficienteRebote
        reboto = true
    end
    
    if self.y - self.radio < 0 then
        self.y = self.radio
        self.vy = math.abs(self.vy) * self.coeficienteRebote
        reboto = true
    elseif self.y + self.radio > alto_pantalla then
        self.y = alto_pantalla - self.radio
        self.vy = -math.abs(self.vy) * self.coeficienteRebote
        reboto = true
    end
    
    -- Incrementar contador de rebotes si rebotó
    if reboto then
        self.rebotesActuales = self.rebotesActuales + 1
    end
    
    -- Limitar la velocidad máxima
    local velocidadMaxima = 400
    local velocidadActual = math.sqrt(self.vx^2 + self.vy^2)
    if velocidadActual > velocidadMaxima then
        local factor = velocidadMaxima / velocidadActual
        self.vx = self.vx * factor
        self.vy = self.vy * factor
    end
    
    return self.rebotesActuales >= self.rebotesMaximos  -- Devuelve true si la bomba debe ser eliminada
end

function Bomba:draw()
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.draw(self.imagen, self.x, self.y, self.rotacion, 
        self.escala, self.escala, 
        self.imagen:getWidth() / 2, 
        self.imagen:getHeight() / 2)
end

function Bomba:colisionaCon(jugador)
    return Utils.colisionCirculoRectangulo(
        self.x, self.y, self.radio,
        jugador.x - jugador.ancho/2, jugador.y - jugador.alto,
        jugador.ancho, jugador.alto
    )
end

return Bomba
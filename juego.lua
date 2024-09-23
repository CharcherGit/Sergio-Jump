-- juego.lua

local Jugador = require "jugador"
local Bomba = require "bomba"
local Misil = require "misil"
local HighScore = require "highscore"

local Juego = {}
Juego.__index = Juego

local Utils = require "utils"

local log = love.filesystem.newFile("game_log.txt")
log:open("w")

function Juego:load(mode)
    -- Configuración de la ventana
    love.window.setTitle("Juego de Evitar Bombas")
    love.window.setMode(800, 600)

    -- Cargar y reproducir música
    self.musica = love.audio.newSource("media/music/music.mp3", "stream")
    self.musica:setLooping(true)  -- Hacer que la música se repita
    love.audio.play(self.musica)  -- Comenzar a reproducir la música

    -- Cargar imágenes
    self.fondo = love.graphics.newImage("media/imagenes/fondo.png")
    local imagen_jugador = love.graphics.newImage("media/imagenes/personaje.png")
    self.imagen_bomba = love.graphics.newImage("media/imagenes/bomba.png")
    self.imagen_misil = love.graphics.newImage("media/imagenes/misil.png")
    
    -- Verificar que las imágenes se cargaron correctamente
    assert(imagen_jugador, "No se pudo cargar la imagen del jugador")
    assert(self.imagen_bomba, "No se pudo cargar la imagen de la bomba")
    assert(self.imagen_misil, "No se pudo cargar la imagen del misil")

    -- Crear jugador(es)
    self.jugador = Jugador:new(
        imagen_jugador,
        love.graphics.getWidth() / 3,
        love.graphics.getHeight() - (imagen_jugador:getHeight() * 0.1),
        0.1,
        'arrows'  -- Controles para el jugador 1
    )

    if mode == "coop" then
        self.jugador2 = Jugador:new(
            imagen_jugador,
            love.graphics.getWidth() * 2 / 3,
            love.graphics.getHeight() - (imagen_jugador:getHeight() * 0.1),
            0.1,
            'wasd'  -- Controles para el jugador 2
        )
    else
        self.jugador2 = nil  -- Asegúrate de que jugador2 es nil en modo individual
    end

    -- Añadir parámetros para el empuje de bombas
    self.jugador.radioBate = 50  -- Radio de alcance del bate
    self.jugador.fuerzaEmpuje = 300  -- Fuerza del empuje

    -- Añadir parámetros para el power-up
    self.jugador.usosEmpuje = 3  -- Número inicial de usos del power-up
    self.jugador.empujeActivo = false

    if self.jugador2 then
        self.jugador2.radioBate = 50
        self.jugador2.fuerzaEmpuje = 300
        self.jugador2.usosEmpuje = 3
        self.jugador2.empujeActivo = false
    end

    -- Configurar bombas
    self.bombas = {}
    self.tiempoUltimaBomba = 0
    self.intervaloSpawn = 1  -- Reducimos el intervalo de spawn para más desafío
    self.tiempoInicioBombas = 2  -- Reducimos el tiempo de inicio

    -- Definir parámetros de las bombas
    self.imagen_bomba = love.graphics.newImage("media/imagenes/bomba.png")

    -- Configurar misiles
    self.misiles = {}
    self.tiempoUltimoMisil = 0
    self.intervaloSpawnMisil = 15  -- Inicialmente, cada 15 segundos
    self.tiempoInicioMisiles = 20  -- Retraso inicial de 20 segundos

    -- Definir parámetros de los misiles
    self.escala_misil = 0.1  -- Ajusta este valor según sea necesario
    self.parametrosMisil = {
        escala = self.escala_misil,
        radio = self.imagen_misil:getWidth() * self.escala_misil / 2,
        velocidad = 400  -- Aumentar la velocidad inicial
    }

    -- Cargar high score
    self.highScore = HighScore:load()

    -- Puntuación
    self.puntuacion = 0
    self.tiempoJuego = 0

    -- Estado del juego
    self.gameOver = false

    -- Dificultad
    self.dificultad = 1
    self.tiempoAumentoDificultad = 30  -- Aumentar dificultad cada 30 segundos
    self.tiempoUltimoDificultad = 0

    self.mode = mode
    self.rondas = {0, 0}  -- Puntuación de rondas para jugador 1 y 2
    self.rondaActual = 1
    self.ganadorRonda = nil
    self.juegoNuevo = true  -- Indica si el juego acaba de comenzar

    self.parametrosBomba = {
        velocidad = 100,
        radio = 20,
        gravedad = 9.8
    }

    self.parametrosMisil = {
        velocidad = 150,
        radio = 15
    }

    -- Dificultad gradual
    self.tiempoJuego = 0
    self.intervaloSpawnInicial = 3  -- Tiempo inicial entre bombas (en segundos)
    self.intervaloSpawnMinimo = 0.5  -- Tiempo mínimo entre bombas
    self.tiempoReduccionIntervalo = 30  -- Cada cuántos segundos se reduce el intervalo
    self.cantidadReduccionIntervalo = 0.2  -- Cuánto se reduce el intervalo cada vez
end

-- Función para manejar la pérdida de una ronda
function Juego:handleRondaPerdida(jugadorPerdedor)
    if jugadorPerdedor == 1 then
        self.ganadorRonda = 2
        self.rondas[2] = self.rondas[2] + 1
    elseif jugadorPerdedor == 2 then
        self.ganadorRonda = 1
        self.rondas[1] = self.rondas[1] + 1
    end

    -- Comprobar si alguien ha ganado 2 rondas
    if self.rondas[1] == 2 or self.rondas[2] == 2 then
        self.gameOver = true  -- Fin total del juego
    else
        self.rondaActual = self.rondaActual + 1
        self:reiniciarRonda()
    end
end

function Juego:update(dt, mode)
    if not self.gameOver then
        -- Actualizar tiempo de juego
        self.tiempoJuego = self.tiempoJuego + dt

        -- Actualizar jugador(es)
        self.jugador:update(dt, love.graphics.getWidth(), love.graphics.getHeight())
        if mode == "coop" and self.jugador2 then
            self.jugador2:update(dt, love.graphics.getWidth(), love.graphics.getHeight())
        end

        -- Comprobar si los jugadores están usando el power-up
        self.jugador.empujeActivo = love.keyboard.isDown('lctrl') and self.jugador.usosEmpuje > 0
        if self.jugador2 then
            self.jugador2.empujeActivo = love.keyboard.isDown('g') and self.jugador2.usosEmpuje > 0
        end

        -- Actualizar bombas
        for i = #self.bombas, 1, -1 do
            local bomba = self.bombas[i]
            local debeEliminar = bomba:update(dt, love.graphics.getWidth(), love.graphics.getHeight())
            
            -- Comprobar colisión con los jugadores
            if bomba:colisionaCon(self.jugador) or (mode == "coop" and self.jugador2 and bomba:colisionaCon(self.jugador2)) then
                if self.jugador.empujeActivo and self.jugador.usosEmpuje > 0 then
                    self:empujarBomba(bomba, self.jugador)
                    self.jugador.usosEmpuje = self.jugador.usosEmpuje - 1
                else
                    if mode == "coop" then
                        if bomba:colisionaCon(self.jugador) then
                            self:handleRondaPerdida(1)
                        elseif self.jugador2 and bomba:colisionaCon(self.jugador2) then
                            self:handleRondaPerdida(2)
                        end
                    else
                        self.gameOver = true
                        if self.puntuacion > self.highScore then
                            self.highScore = self.puntuacion
                            HighScore:save(self.highScore)
                        end
                    end
                end
            end
            
            if debeEliminar then
                table.remove(self.bombas, i)
            end
        end

        -- Generar nuevas bombas
        self.tiempoUltimaBomba = self.tiempoUltimaBomba + dt
        local intervaloActual = math.max(
            self.intervaloSpawnMinimo,
            self.intervaloSpawnInicial - math.floor(self.tiempoJuego / self.tiempoReduccionIntervalo) * self.cantidadReduccionIntervalo
        )
        if self.tiempoUltimaBomba >= intervaloActual then
            self:generarBomba()
            self.tiempoUltimaBomba = 0
        end

        -- Actualizar puntuación
        self.puntuacion = math.floor(self.tiempoJuego * 10)
    end
end

function Juego:draw(mode)
    -- Dibujar fondo
    love.graphics.draw(
        self.fondo,
        0,
        0,
        0,
        love.graphics.getWidth() / self.fondo:getWidth(),
        love.graphics.getHeight() / self.fondo:getHeight()
    )

    -- Dibujar jugador(es)
    self.jugador:draw()
    love.graphics.setFont(love.graphics.newFont(12))
    love.graphics.print("Jugador 1", self.jugador.x - 30, self.jugador.y - self.jugador.alto - 20)
    
    if mode == "coop" and self.jugador2 then
        self.jugador2:draw()
        love.graphics.print("Jugador 2", self.jugador2.x - 30, self.jugador2.y - self.jugador2.alto - 20)
    end

    -- Dibujar bombas
    for _, bomba in ipairs(self.bombas) do
        bomba:draw()
    end

    -- Dibujar misiles
    for _, misil in ipairs(self.misiles) do
        misil:draw()
    end

    -- Dibujar puntuación
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("Puntuación: " .. self.puntuacion, 10, 10)
    love.graphics.print("Mejor Puntuación: " .. self.highScore, 10, 30)

    -- Dibujar usos restantes del power-up
    love.graphics.print("Power-up: " .. self.jugador.usosEmpuje, 10, 50)
    if self.jugador2 then
        love.graphics.print("Power-up 2: " .. self.jugador2.usosEmpuje, 10, 70)
    end

    if mode == "coop" then
        love.graphics.print("Ronda: " .. (self.juegoNuevo and "-" or self.rondaActual) .. "/3", 10, 90)
        love.graphics.print("Jugador 1: " .. self.rondas[1], 10, 110)
        love.graphics.print("Jugador 2: " .. self.rondas[2], 10, 130)
    end

    -- Mostrar mensaje de Game Over
    if self.gameOver then
        love.graphics.setColor(1, 0, 0, 0.7)
        love.graphics.rectangle("fill", 0, love.graphics.getHeight() / 2 - 50, love.graphics.getWidth(), 100)
        love.graphics.setColor(1, 1, 1)
        if mode == "coop" then
            local ganador = self.rondas[1] > self.rondas[2] and "Jugador 1" or "Jugador 2"
            love.graphics.printf(
                "¡" .. ganador .. " gana!\nPresiona 'R' para reiniciar",
                0,
                love.graphics.getHeight() / 2 - 25,
                love.graphics.getWidth(),
                "center"
            )
        else
            love.graphics.printf(
                "GAME OVER\nPresiona 'R' para reiniciar",
                0,
                love.graphics.getHeight() / 2 - 25,
                love.graphics.getWidth(),
                "center"
            )
        end
    end
end

function Juego:keypressed(key)
    if key == 'space' and not self.gameOver then
        self.jugador:saltar()
    elseif key == 'f' and not self.gameOver and self.jugador2 then
        self.jugador2:saltar()
    elseif key == 'r' and self.gameOver then
        self:reiniciarJuego()
        -- El estado del juego se maneja en main.lua
    end
end

function Juego:reiniciarJuego()
    self.jugador.x = love.graphics.getWidth() / 3
    self.jugador.y = love.graphics.getHeight() - (self.jugador.imagen:getHeight() * self.jugador.escala)
    self.jugador.saltando = false
    self.jugador.velocidadSalto = 0
    self.jugador.saltosDisponibles = 2
    self.jugador.usosEmpuje = 3  -- Reiniciar los usos del power-up

    if self.jugador2 then
        self.jugador2.x = love.graphics.getWidth() * 2 / 3
        self.jugador2.y = love.graphics.getHeight() - (self.jugador2.imagen:getHeight() * self.jugador2.escala)
        self.jugador2.saltando = false
        self.jugador2.velocidadSalto = 0
        self.jugador2.saltosDisponibles = 2
        self.jugador2.usosEmpuje = 3
    end

    self.bombas = {}
    self.tiempoUltimaBomba = 0
    self.tiempoBomba = 0  -- Reiniciar tiempoBomba
    self.tiempoJuego = 0
    self.puntuacion = 0
    self.gameOver = false
    self.dificultad = 1
    self.intervaloSpawn = 10
    self.tiempoUltimoDificultad = 0

    self.rondas = {0, 0}
    self.rondaActual = 1
    self.ganadorRonda = nil
    self.juegoNuevo = true  -- Indicar que el juego acaba de reiniciarse
end

function Juego:reiniciarRonda()
    -- Reiniciar posiciones de los jugadores
    self.jugador.x = love.graphics.getWidth() / 3
    self.jugador.y = love.graphics.getHeight() - (self.jugador.imagen:getHeight() * self.jugador.escala)
    self.jugador.saltando = false
    self.jugador.velocidadSalto = 0
    self.jugador.saltosDisponibles = 2
    self.jugador.usosEmpuje = 3

    if self.jugador2 then
        self.jugador2.x = love.graphics.getWidth() * 2 / 3
        self.jugador2.y = love.graphics.getHeight() - (self.jugador2.imagen:getHeight() * self.jugador2.escala)
        self.jugador2.saltando = false
        self.jugador2.velocidadSalto = 0
        self.jugador2.saltosDisponibles = 2
        self.jugador2.usosEmpuje = 3
    end

    -- Reiniciar bombas y misiles
    self.bombas = {}
    self.tiempoUltimaBomba = 0
    self.tiempoBomba = 0
    self.misiles = {}
    self.tiempoUltimoMisil = 0

    -- Reiniciar puntuación y tiempo de juego para la nueva ronda
    self.puntuacion = 0
    self.tiempoJuego = 0

    self.juegoNuevo = false  -- Indicar que ya no es un juego nuevo
end

function Juego:stopMusic()
    if self.musica then
        self.musica:stop()
    end
end

function log_message(message)
    if log then
        log:write(message .. "\n")
        log:flush()  -- Asegura que el mensaje se escriba inmediatamente
    end
end

function Juego:closeLog()
    if log then
        log:close()
    end
end

function Juego:generarBomba()
    local x = love.math.random(0, love.graphics.getWidth())
    local y = -50  -- Comenzar por encima de la pantalla
    local bomba = Bomba:new(self.imagen_bomba, x, y, {})
    table.insert(self.bombas, bomba)
end

function Juego:generarMisil()
    local x = love.graphics.getWidth()
    local y = love.math.random(0, love.graphics.getHeight())
    local misil = Misil:new(self.imagen_misil, x, y, {
        velocidad = self.parametrosMisil.velocidad,
        radio = self.parametrosMisil.radio,
        escala = self.escala_misil
    })
    table.insert(self.misiles, misil)
end

function Juego:aumentarDificultad()
    self.dificultad = self.dificultad + 1
    self.intervaloSpawn = math.max(0.5, self.intervaloSpawn * 0.9)  -- Reducimos el intervalo mínimo a 0.5 segundos
    -- No necesitamos ajustar la velocidad de las bombas aquí, ya que ahora tienen comportamiento aleatorio
end

function Juego:empujarBomba(bomba, jugador)
    local dx = bomba.x - jugador.x
    local dy = bomba.y - (jugador.y - jugador.alto/2)
    local distancia = math.sqrt(dx*dx + dy*dy)
    
    local angulo = math.atan2(dy, dx)
    local fuerzaX = math.cos(angulo) * jugador.fuerzaEmpuje
    local fuerzaY = math.sin(angulo) * jugador.fuerzaEmpuje
    
    -- Aplicar la fuerza a la bomba
    bomba.vx = bomba.vx + fuerzaX
    bomba.vy = bomba.vy + fuerzaY
    
    -- Asegurar que la bomba esté fuera del radio del power-up
    local nuevaDistancia = jugador.radioBate + bomba.radio
    bomba.x = jugador.x + math.cos(angulo) * nuevaDistancia
    bomba.y = (jugador.y - jugador.alto/2) + math.sin(angulo) * nuevaDistancia
    
    -- Limitar la velocidad máxima después del empuje
    local velocidadMaxima = 400
    local velocidadActual = math.sqrt(bomba.vx^2 + bomba.vy^2)
    if velocidadActual > velocidadMaxima then
        local factor = velocidadMaxima / velocidadActual
        bomba.vx = bomba.vx * factor
        bomba.vy = bomba.vy * factor
    end
end

return Juego
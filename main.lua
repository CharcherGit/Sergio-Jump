local moonshine = require 'moonshine'
local Juego = require "juego"

local gameState = "menu"  -- Estados: "menu", "modeSelect", "playing", "error"
local gameMode = "single"  -- "single" o "coop"
local menuSelection = 1  -- 1: Single Player, 2: Co-op, 3: Exit
local logo
local logoBaseWidth = 472
local logoBaseHeight = 218
local startText = "Pulsa ENTER para comenzar"
local blinkTimer = 0
local blinkInterval = 0.5
local logoScale = 1 -- Ajusta este valor para cambiar el tamaño del logo
local logoScaleDirection = 1
local logoScaleSpeed = 0.1
local logoScaleMin = 0.95 * logoScale
local logoScaleMax = 1.05 * logoScale

local effect
local font, smallFont, titleFont, menuFont

function love.load(arg)
    if arg[#arg] == "-debug" then require("mobdebug").start() end
    
    -- Cargar y reproducir música una sola vez
    if not music then
        music = love.audio.newSource("media/music/music.mp3", "stream")
        music:setLooping(true)
        love.audio.play(music)
    end
    
    -- Cargar todas las fuentes
    font = love.graphics.newFont(40)
    smallFont = love.graphics.newFont(20)
    titleFont = love.graphics.newFont(60)
    menuFont = love.graphics.newFont(30)
    
    -- Cargar el logo
    logo = love.graphics.newImage("media/imagenes/logo.png")
    
    -- Calcular la escala base para el logo
    local logoWidth, logoHeight = logo:getDimensions()
    local scaleX = (logoBaseWidth * logoScale) / logoWidth
    local scaleY = (logoBaseHeight * logoScale) / logoHeight
    logoBaseScale = math.min(scaleX, scaleY)
    
    -- Crear el efecto de moonshine
    effect = moonshine(moonshine.effects.crt)
        .chain(moonshine.effects.scanlines)
    
    -- Configurar el efecto CRT
    effect.crt.distortionFactor = {1.06, 1.065}
    effect.crt.feather = 0.02
    effect.crt.scaleFactor = 1
    
    -- Configurar el efecto scanlines
    effect.scanlines.opacity = 0.2
    effect.scanlines.width = 2

    -- Cargar el juego inmediatamente
    Juego:load("single")  -- Cargamos en modo single por defecto
    print("Juego cargado correctamente")  -- Add this line for debugging
end

function love.update(dt)
    if gameState == "menu" then
        blinkTimer = blinkTimer + dt
        if blinkTimer >= blinkInterval then
            blinkTimer = blinkTimer - blinkInterval
        end
        
        -- Actualizar la escala del logo
        logoScale = logoScale + logoScaleDirection * logoScaleSpeed * dt
        if logoScale > logoScaleMax then
            logoScale = logoScaleMax
            logoScaleDirection = -1
        elseif logoScale < logoScaleMin then
            logoScale = logoScaleMin
            logoScaleDirection = 1
        end
    elseif gameState == "modeSelect" then
        -- No necesita actualización específica
    elseif gameState == "playing" then
        local success, err = pcall(function() Juego:update(dt, gameMode) end)
        if not success then
            print("Error in game update: " .. tostring(err))
            gameState = "error"
        end
    end
end

function love.draw()
    effect(function()
        -- Dibujar el fondo del juego en todos los estados
        if Juego.draw then
            Juego:draw(gameMode)
        end

        -- Dibujar contenido específico de cada estado
        if gameState == "menu" then
            -- Oscurecer el fondo
            love.graphics.setColor(0, 0, 0, 0.7)
            love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())
            
            -- Dibujar el logo
            love.graphics.setColor(1, 1, 1, 1)
            love.graphics.draw(logo, 
                love.graphics.getWidth() / 2, love.graphics.getHeight() / 2 - 50, 
                0, logoScale * logoBaseScale, logoScale * logoBaseScale, 
                logo:getWidth() / 2, logo:getHeight() / 2)
            
            -- Dibujar texto de inicio con parpadeo
            love.graphics.setFont(smallFont)
            if blinkTimer < blinkInterval / 2 then
                love.graphics.printf(startText, 0, love.graphics.getHeight() / 2 + 150, love.graphics.getWidth(), "center")
            end
        elseif gameState == "modeSelect" then
            -- Oscurecer el fondo
            love.graphics.setColor(0, 0, 0, 0.7)
            love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())
            
            -- Dibujar selección de modo
            drawModeSelect()
        elseif gameState == "playing" then
            -- El juego ya se dibujó, no necesitamos hacer nada más aquí
        elseif gameState == "error" then
            love.graphics.setFont(font)
            love.graphics.setColor(1, 0, 0)
            love.graphics.printf("Ha ocurrido un error. Reinicia el juego.", 0, love.graphics.getHeight() / 2, love.graphics.getWidth(), "center")
        end
    end)
end

function drawModeSelect()
    love.graphics.setFont(titleFont)
    love.graphics.setColor(1, 1, 1)
    love.graphics.printf("Modo de Juego", 0, 100, love.graphics.getWidth(), "center")
    
    love.graphics.setFont(menuFont)
    local options = {"Single Player", "Co-op", "Exit"}
    for i, option in ipairs(options) do
        if i == menuSelection then
            love.graphics.setColor(1, 1, 0)  -- Color amarillo para la opción seleccionada
        else
            love.graphics.setColor(1, 1, 1)  -- Color blanco para las demás opciones
        end
        love.graphics.printf(option, 0, 250 + (i-1) * 50, love.graphics.getWidth(), "center")
    end
    love.graphics.setColor(1, 1, 1)  -- Restaurar color
end

function love.keypressed(key)
    if gameState == "menu" and key == "return" then
        gameState = "modeSelect"
    elseif gameState == "modeSelect" then
        if key == "up" then
            menuSelection = (menuSelection - 2) % 3 + 1
        elseif key == "down" then
            menuSelection = menuSelection % 3 + 1
        elseif key == "return" then
            if menuSelection == 1 then
                gameMode = "single"
                gameState = "playing"
                Juego:load(gameMode)
            elseif menuSelection == 2 then
                gameMode = "coop"
                gameState = "playing"
                Juego:load(gameMode)
            elseif menuSelection == 3 then
                love.event.quit()
            end
        end
    elseif gameState == "playing" then
        Juego:keypressed(key)
        -- Manejar reinicio del juego desde `Juego:keypressed`
        if key == 'r' and Juego.gameOver then
            gameState = "playing"
            Juego:reiniciarJuego()
        end
    end
    
    -- Tecla para alternar el shader
    if key == "s" then
        -- Implementa la lógica para alternar shaders si es necesario
    end
end

function love.quit()
    if Juego.stopMusic then
        Juego:stopMusic()
    end
    if Juego.closeLog then
        Juego:closeLog()
    end
end
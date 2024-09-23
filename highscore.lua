-- highscore.lua

local HighScore = {}

function HighScore:load()
    if love.filesystem.getInfo("highscore.txt") then
        local contenido = love.filesystem.read("highscore.txt")
        return tonumber(contenido) or 0
    else
        return 0
    end
end

function HighScore:save(score)
    love.filesystem.write("highscore.txt", tostring(score))
end

return HighScore
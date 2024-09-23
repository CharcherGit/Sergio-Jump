-- utils.lua

local Utils = {}

function Utils.distanciaEntre(x1, y1, x2, y2)
    return math.sqrt((x2 - x1)^2 + (y2 - y1)^2)
end

function Utils.colisionCircular(x1, y1, r1, x2, y2, r2)
    return Utils.distanciaEntre(x1, y1, x2, y2) < (r1 + r2)
end

function Utils.colisionCirculoRectangulo(cx, cy, cr, rx, ry, rw, rh)
    local testX = cx
    local testY = cy
    
    if cx < rx then testX = rx
    elseif cx > rx + rw then testX = rx + rw end
    
    if cy < ry then testY = ry
    elseif cy > ry + rh then testY = ry + rh end
    
    local distX = cx - testX
    local distY = cy - testY
    local distance = math.sqrt((distX * distX) + (distY * distY))
    
    return distance <= cr
end

return Utils
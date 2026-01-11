-- Powder Toy–style Sand Simulation
-- LÖVE 11.x

WINDOW_WIDTH = 500
WINDOW_HEIGHT = 350
CELL = 5 -- Slightly larger for better performance

GW = math.floor(WINDOW_WIDTH / CELL)
GH = math.floor(WINDOW_HEIGHT / CELL)

-- Materials
EMPTY = 0
SAND = 1
WATER = 2
WOOD = 3
FIRE = 4
SMOKE = 5
WALL = 6

grid = {}
life = {} 
current = SAND

function love.load()
    love.window.setMode(WINDOW_WIDTH, WINDOW_HEIGHT)
    love.graphics.setBackgroundColor(0, 0, 0)
    math.randomseed(os.time())

    for y = 1, GH do
        grid[y] = {}
        life[y] = {}
        for x = 1, GW do
            grid[y][x] = EMPTY
            life[y][x] = 0
        end
    end
end

function swap(x1, y1, x2, y2)
    grid[y1][x1], grid[y2][x2] = grid[y2][x2], grid[y1][x1]
    life[y1][x1], life[y2][x2] = life[y2][x2], life[y1][x1]
end

function love.update(dt)
    -- Input: Click and drag to draw
    if love.mouse.isDown(1) or love.mouse.isDown(2) then
        local mx, my = love.mouse.getPosition()
        local x = math.floor(mx / CELL) + 1
        local y = math.floor(my / CELL) + 1

        if x >= 1 and x <= GW and y >= 1 and y <= GH then
            if love.mouse.isDown(1) then
                grid[y][x] = current
                if current == FIRE then life[y][x] = 20 end
                if current == SMOKE then life[y][x] = 40 end
            else
                grid[y][x] = WALL -- Right click to draw walls
            end
        end
    end

    -- Physics logic (Iterate bottom-to-top)
    for y = GH - 1, 1, -1 do
        for x = 1, GW do
            local c = grid[y][x]
            
            if c == SAND then
                local d = math.random(2) == 1 and -1 or 1
                if grid[y+1][x] == EMPTY or grid[y+1][x] == WATER then
                    swap(x, y, x, y+1)
                elseif x+d >= 1 and x+d <= GW and (grid[y+1][x+d] == EMPTY or grid[y+1][x+d] == WATER) then
                    swap(x, y, x+d, y+1)
                end

            elseif c == WATER then
                local d = math.random(2) == 1 and -1 or 1
                if grid[y+1][x] == EMPTY then
                    swap(x, y, x, y+1)
                elseif x+d >= 1 and x+d <= GW and grid[y+1][x+d] == EMPTY then
                    swap(x, y, x+d, y+1)
                elseif x+d >= 1 and x+d <= GW and grid[y][x+d] == EMPTY then
                    swap(x, y, x+d, y)
                end

            elseif c == FIRE then
                life[y][x] = life[y][x] - 1
                if life[y][x] <= 0 then
                    grid[y][x] = (math.random() > 0.4) and SMOKE or EMPTY
                    life[y][x] = 30
                else
                    -- Spread to Wood
                    for dy = -1, 1 do
                        for dx = -1, 1 do
                            local nx, ny = x+dx, y+dy
                            if nx >= 1 and nx <= GW and ny >= 1 and ny <= GH then
                                if grid[ny][nx] == WOOD and math.random() > 0.8 then
                                    grid[ny][nx] = FIRE
                                    life[ny][nx] = 20
                                end
                            end
                        end
                    end
                end

            elseif c == SMOKE then
                life[y][x] = life[y][x] - 1
                if life[y][x] <= 0 then
                    grid[y][x] = EMPTY
                elseif y > 1 then
                    local d = math.random(3) - 2 -- random drift
                    if x+d >= 1 and x+d <= GW and grid[y-1][x+d] == EMPTY then
                        swap(x, y, x+d, y-1)
                    end
                end
            end
        end
    end
end

function love.draw()
    for y = 1, GH do
        for x = 1, GW do
            local c = grid[y][x]
            if c ~= EMPTY then
                if c == SAND then love.graphics.setColor(1, 0.9, 0.3)
                elseif c == WATER then love.graphics.setColor(0.2, 0.5, 1)
                elseif c == WOOD then love.graphics.setColor(0.4, 0.2, 0.1)
                elseif c == FIRE then love.graphics.setColor(1, 0.3, 0)
                elseif c == SMOKE then love.graphics.setColor(0.5, 0.5, 0.5, 0.6)
                elseif c == WALL then love.graphics.setColor(0.7, 0.7, 0.7)
                end
                love.graphics.rectangle("fill", (x-1)*CELL, (y-1)*CELL, CELL, CELL)
            end
        end
    end

    -- Instruction text
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("Current: " .. current .. " (Press 1-5 to switch) | Right-click: Wall", 10, 10)
end

function love.keypressed(k)
    if k == "1" then current = SAND
    elseif k == "2" then current = WATER
    elseif k == "3" then current = WOOD
    elseif k == "4" then current = FIRE
    elseif k == "5" then current = SMOKE
    elseif k == "c" then
        for y=1, GH do for x=1, GW do grid[y][x] = EMPTY end end
    end
end
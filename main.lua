--[[
    Pong Remake – Step 1
    Basic paddles + ball movement
    Controls:
      Player 1 → W / S
      Player 2 → Up / Down
      Space → Reset ball
      Esc → Quit
]]

-- Window size
WINDOW_WIDTH  = 1280
WINDOW_HEIGHT = 720

-- Paddle and ball sizes
PADDLE_WIDTH  = 12
PADDLE_HEIGHT = 64
BALL_SIZE     = 10

-- Speeds
PADDLE_SPEED  = 420
BALL_SPEED_X  = 220
BALL_SPEED_Y  = 120

-- Game objects
local p1 = { x = 32, y = (WINDOW_HEIGHT - PADDLE_HEIGHT) / 2 }
local p2 = { x = WINDOW_WIDTH - 32 - PADDLE_WIDTH, y = (WINDOW_HEIGHT - PADDLE_HEIGHT) / 2 }
local ball = {
    x = WINDOW_WIDTH / 2 - BALL_SIZE / 2,
    y = WINDOW_HEIGHT / 2 - BALL_SIZE / 2,
    dx = BALL_SPEED_X,
    dy = BALL_SPEED_Y
}

-- Clamp function
local function clamp(v, min, max)
    if v < min then return min end
    if v > max then return max end
    return v
end

-- Reset ball to center
local function resetBall()
    ball.x = WINDOW_WIDTH / 2 - BALL_SIZE / 2
    ball.y = WINDOW_HEIGHT / 2 - BALL_SIZE / 2

    local dirX = love.math.random() < 0.5 and -1 or 1
    local dirY = love.math.random() < 0.5 and -1 or 1

    ball.dx = dirX * BALL_SPEED_X
    ball.dy = dirY * BALL_SPEED_Y
end

function love.load()
    love.window.setMode(WINDOW_WIDTH, WINDOW_HEIGHT, {
        fullscreen = false,
        resizable = false,
        vsync = true
    })

    love.graphics.setDefaultFilter('nearest', 'nearest')
    love.math.setRandomSeed(os.time())

    smallFont = love.graphics.newFont(16)
    largeFont = love.graphics.newFont(24)
    love.graphics.setFont(smallFont)
end

function love.update(dt)
    -- Player 1
    if love.keyboard.isDown('w') then
        p1.y = p1.y - PADDLE_SPEED * dt
    elseif love.keyboard.isDown('s') then
        p1.y = p1.y + PADDLE_SPEED * dt
    end

    -- Player 2
    if love.keyboard.isDown('up') then
        p2.y = p2.y - PADDLE_SPEED * dt
    elseif love.keyboard.isDown('down') then
        p2.y = p2.y + PADDLE_SPEED * dt
    end

    -- Keep paddles on screen
    p1.y = clamp(p1.y, 0, WINDOW_HEIGHT - PADDLE_HEIGHT)
    p2.y = clamp(p2.y, 0, WINDOW_HEIGHT - PADDLE_HEIGHT)

    -- Move ball
    ball.x = ball.x + ball.dx * dt
    ball.y = ball.y + ball.dy * dt

    -- Bounce top/bottom
    if ball.y <= 0 then
        ball.y = 0
        ball.dy = -ball.dy
    elseif ball.y + BALL_SIZE >= WINDOW_HEIGHT then
        ball.y = WINDOW_HEIGHT - BALL_SIZE
        ball.dy = -ball.dy
    end

    -- Reset if ball goes out
    if ball.x + BALL_SIZE < 0 or ball.x > WINDOW_WIDTH then
        resetBall()
    end
end

function love.keypressed(key)
    if key == 'escape' then
        love.event.quit()
    elseif key == 'space' then
        resetBall()
    end
end

function love.draw()
    -- Background
    love.graphics.clear(0.1, 0.1, 0.12)

    -- Center line
    love.graphics.setLineWidth(2)
    love.graphics.line(WINDOW_WIDTH / 2, 0, WINDOW_WIDTH / 2, WINDOW_HEIGHT)

    -- Title + instructions
    love.graphics.setFont(largeFont)
    love.graphics.printf('PONG – Step 1', 0, 16, WINDOW_WIDTH, 'center')
    love.graphics.setFont(smallFont)
    love.graphics.printf('W/S and Up/Down to move. Space to reset.', 0, 44, WINDOW_WIDTH, 'center')

    -- Paddles
    love.graphics.rectangle('fill', p1.x, p1.y, PADDLE_WIDTH, PADDLE_HEIGHT)
    love.graphics.rectangle('fill', p2.x, p2.y, PADDLE_WIDTH, PADDLE_HEIGHT)

    -- Ball
    love.graphics.rectangle('fill', ball.x, ball.y, BALL_SIZE, BALL_SIZE)
end

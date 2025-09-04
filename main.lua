WINDOW_WIDTH = 1280
WINDOW_HEIGHT = 720

PADDLE_SPEED = 500

function love.load()
    love.window.setMode(WINDOW_WIDTH, WINDOW_HEIGHT, {
        fullscreen = false,
        resizable = false,
        vsync = true
    })

    love.graphics.setDefaultFilter('nearest', 'nearest')
    math.randomseed(os.time())

    -- load fonts
    smallFont = love.graphics.newFont(20)
    scoreFont = love.graphics.newFont(32)

    -- load sounds
    sounds = {
        ['bounce'] = love.audio.newSource('bounce.wav', 'static'),
        ['score']  = love.audio.newSource('score.wav', 'static')
    }

    player1Score = 0
    player2Score = 0

    player1 = { x = 50, y = 30, width = 20, height = 100 }
    player2 = { x = WINDOW_WIDTH - 70, y = WINDOW_HEIGHT - 130, width = 20, height = 100 }

    ball = {
        x = WINDOW_WIDTH / 2 - 10,
        y = WINDOW_HEIGHT / 2 - 10,
        width = 20,
        height = 20,
        dx = math.random(2) == 1 and 300 or -300,
        dy = math.random(-50, 50)
    }

    gameState = 'play'
end

function love.update(dt)
    -- Player 1 movement
    if love.keyboard.isDown('w') then
        player1.y = math.max(0, player1.y - PADDLE_SPEED * dt)
    elseif love.keyboard.isDown('s') then
        player1.y = math.min(WINDOW_HEIGHT - player1.height, player1.y + PADDLE_SPEED * dt)
    end

    -- Player 2 movement
    if love.keyboard.isDown('up') then
        player2.y = math.max(0, player2.y - PADDLE_SPEED * dt)
    elseif love.keyboard.isDown('down') then
        player2.y = math.min(WINDOW_HEIGHT - player2.height, player2.y + PADDLE_SPEED * dt)
    end

    -- Ball movement
    ball.x = ball.x + ball.dx * dt
    ball.y = ball.y + ball.dy * dt

    -- Ball collision with top/bottom walls
    if ball.y <= 0 then
        ball.y = 0
        ball.dy = -ball.dy
        sounds['bounce']:play()
    elseif ball.y >= WINDOW_HEIGHT - ball.height then
        ball.y = WINDOW_HEIGHT - ball.height
        ball.dy = -ball.dy
        sounds['bounce']:play()
    end

    -- Ball collision with paddles
    if checkCollision(ball, player1) then
        ball.x = player1.x + player1.width
        ball.dx = -ball.dx * 1.03
        sounds['bounce']:play()
    elseif checkCollision(ball, player2) then
        ball.x = player2.x - ball.width
        ball.dx = -ball.dx * 1.03
        sounds['bounce']:play()
    end

    -- Scoring
    if ball.x < 0 then
        player2Score = player2Score + 1
        sounds['score']:play()
        resetBall()
    elseif ball.x > WINDOW_WIDTH then
        player1Score = player1Score + 1
        sounds['score']:play()
        resetBall()
    end
end

function love.draw()
    love.graphics.setFont(scoreFont)

    -- Draw scores
    love.graphics.printf(player1Score, 0, 20, WINDOW_WIDTH / 2, 'center')
    love.graphics.printf(player2Score, WINDOW_WIDTH / 2, 20, WINDOW_WIDTH / 2, 'center')

    -- Draw paddles
    love.graphics.rectangle('fill', player1.x, player1.y, player1.width, player1.height)
    love.graphics.rectangle('fill', player2.x, player2.y, player2.width, player2.height)

    -- Draw ball
    love.graphics.rectangle('fill', ball.x, ball.y, ball.width, ball.height)
end

function checkCollision(a, b)
    return a.x < b.x + b.width and
           b.x < a.x + a.width and
           a.y < b.y + b.height and
           b.y < a.y + a.height
end

function resetBall()
    ball.x = WINDOW_WIDTH / 2 - ball.width / 2
    ball.y = WINDOW_HEIGHT / 2 - ball.height / 2
    ball.dx = math.random(2) == 1 and 300 or -300
    ball.dy = math.random(-50, 50)
end


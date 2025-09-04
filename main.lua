utf8 = require("utf8")

WINDOW_WIDTH = 1280
WINDOW_HEIGHT = 720

-- default names
player1Name = ""
player2Name = ""

-- input state
inputState = "player1"  -- can be "player1", "player2", "done"
inputText = ""

function love.load()
    love.window.setMode(WINDOW_WIDTH, WINDOW_HEIGHT, {fullscreen=false,resizable=false,vsync=true})

    -- sounds
    sounds = {
        ['bounce'] = love.audio.newSource('bounce.wav','static'),
        ['score']  = love.audio.newSource('score.wav','static')
    }

    -- scores
    player1Score = 0
    player2Score = 0

    -- paddles
    paddleSpeed = 400
    paddleWidth = 10
    paddleHeight = 100
    leftPaddle = { x=30, y=WINDOW_HEIGHT/2-paddleHeight/2, width=paddleWidth, height=paddleHeight, hitTimer=0 }
    rightPaddle = { x=WINDOW_WIDTH-30-paddleWidth, y=WINDOW_HEIGHT/2-paddleHeight/2, width=paddleWidth, height=paddleHeight, hitTimer=0 }

    -- ball
    balls = {}
    spawnBall(WINDOW_WIDTH/2, WINDOW_HEIGHT/2)

    -- fonts
    pongFont = love.graphics.newFont(48)
    smallFont = love.graphics.newFont(24)

    -- game state
    gameState = 'input'  -- start with name input
    paused = false

    -- winning effects
    particles = {}
    winnerAnimation = {scale = 1, time = 0, active = false}
end

function spawnBall(x,y)
    local ball = {
        x=x, y=y,
        dx=(math.random(2)==1 and 200 or -200),
        dy=math.random(-100,100),
        size=12,
        trail={},
        hue=math.random()
    }
    table.insert(balls,ball)
end

function love.textinput(t)
    if gameState == "input" then
        inputText = inputText .. t
    end
end

function love.keypressed(key)
    if gameState == "input" then
        if key == "backspace" then
            local byteoffset = utf8.offset(inputText, -1)
            if byteoffset then
                inputText = string.sub(inputText, 1, byteoffset - 1)
            end
        elseif key == "return" or key == "enter" then
            if inputState == "player1" then
                player1Name = inputText ~= "" and inputText or "P1"
                inputText = ""
                inputState = "player2"
            elseif inputState == "player2" then
                player2Name = inputText ~= "" and inputText or "P2"
                inputText = ""
                inputState = "done"
                gameState = "start"  -- move to start screen after names entered
            end
        end
        return
    end

    -- pause or quit during game
    if key=='escape' then love.event.quit() end
    if key=='p' then paused = not paused end
    if key=='enter' or key=='return' then
        if gameState=='start' then gameState='play'
        elseif gameState=='done' then
            gameState='input'; player1Score=0; player2Score=0; balls={}; spawnBall(WINDOW_WIDTH/2,WINDOW_HEIGHT/2); particles={}; winnerAnimation.active=false
            inputState = "player1"; inputText = ""; player1Name=""; player2Name=""
        end
    end
end

function love.update(dt)
    if gameState ~= 'play' or paused then return end

    -- paddle timers
    if leftPaddle.hitTimer>0 then leftPaddle.hitTimer = leftPaddle.hitTimer - dt end
    if rightPaddle.hitTimer>0 then rightPaddle.hitTimer = rightPaddle.hitTimer - dt end

    -- player1 movement
    if love.keyboard.isDown('w') then leftPaddle.y = math.max(0,leftPaddle.y-paddleSpeed*dt)
    elseif love.keyboard.isDown('s') then leftPaddle.y = math.min(WINDOW_HEIGHT-leftPaddle.height,leftPaddle.y+paddleSpeed*dt) end

    -- player2 movement
    if love.keyboard.isDown('up') then rightPaddle.y = math.max(0,rightPaddle.y-paddleSpeed*dt)
    elseif love.keyboard.isDown('down') then rightPaddle.y = math.min(WINDOW_HEIGHT-rightPaddle.height,rightPaddle.y+paddleSpeed*dt) end

    -- update balls
    for i=#balls,1,-1 do
        local ball = balls[i]
        ball.x = ball.x + ball.dx*dt
        ball.y = ball.y + ball.dy*dt
        ball.hue = (ball.hue + dt*0.5) % 1  -- rainbow hue

        -- trail
        table.insert(ball.trail,1,{x=ball.x,y=ball.y,hue=ball.hue})
        if #ball.trail>15 then table.remove(ball.trail) end

        -- bounce top/bottom
        if ball.y<=0 or ball.y>=WINDOW_HEIGHT-ball.size then
            ball.dy = -ball.dy
            sounds['bounce']:play()
        end

        -- collisions with paddles
        local hit=false
        if checkCollision(ball,leftPaddle) then
            ball.dx = -ball.dx*1.05
            ball.x = leftPaddle.x + leftPaddle.width
            sounds['bounce']:play()
            leftPaddle.hitTimer = 0.2
            hit=true
        end
        if checkCollision(ball,rightPaddle) then
            ball.dx = -ball.dx*1.05
            ball.x = rightPaddle.x - ball.size
            sounds['bounce']:play()
            rightPaddle.hitTimer = 0.2
            hit=true
        end

        -- scoring
        if ball.x < 0 then
            player2Score = player2Score + 1
            sounds['score']:play()
            table.remove(balls,i)
            spawnBall(WINDOW_WIDTH/2,WINDOW_HEIGHT/2)
            if player2Score >= 10 then
                gameState='done'
                spawnWinningParticles(player2Name)
                winnerAnimation.active = true
                winnerAnimation.scale = 0.5
                winnerAnimation.time = 0
            end
        elseif ball.x > WINDOW_WIDTH then
            player1Score = player1Score + 1
            sounds['score']:play()
            table.remove(balls,i)
            spawnBall(WINDOW_WIDTH/2,WINDOW_HEIGHT/2)
            if player1Score >= 10 then
                gameState='done'
                spawnWinningParticles(player1Name)
                winnerAnimation.active = true
                winnerAnimation.scale = 0.5
                winnerAnimation.time = 0
            end
        end
    end

    -- update particles
    for i=#particles,1,-1 do
        local p = particles[i]
        p.x = p.x + p.dx*dt
        p.y = p.y + p.dy*dt
        p.life = p.life - dt
        if p.life <=0 then table.remove(particles,i) end
    end

    -- winner animation
    if winnerAnimation.active then
        winnerAnimation.time = winnerAnimation.time + dt
        winnerAnimation.scale = winnerAnimation.scale + dt * 2
        if winnerAnimation.time > 1 then
            winnerAnimation.active = false
        end
    end
end

function love.draw()
    -- background
    love.graphics.setBackgroundColor(0,0,0)
    
    if gameState == "input" then
        love.graphics.setFont(pongFont)
        love.graphics.setColor(1,1,1)
        local prompt = inputState == "player1" and "Enter Player 1 Name:" or "Enter Player 2 Name:"
        love.graphics.printf(prompt, 0, WINDOW_HEIGHT/2-50, WINDOW_WIDTH, "center")
        love.graphics.printf(inputText.."|", 0, WINDOW_HEIGHT/2, WINDOW_WIDTH, "center")
        return
    end

    -- title
    love.graphics.setFont(pongFont)
    love.graphics.setColor(1,1,1)
    love.graphics.printf('PONG',0,20,WINDOW_WIDTH,'center')

    -- scores
    love.graphics.setFont(smallFont)
    love.graphics.printf(player1Name..": "..player1Score, 50,50,200,'left')
    love.graphics.printf(player2Name..": "..player2Score, WINDOW_WIDTH-250,50,200,'right')

    -- balls
    for _,ball in ipairs(balls) do
        for i=#ball.trail,1,-1 do
            local t=ball.trail[i]
            local r,g,b = hsvToRgb(t.hue,1,1)
            love.graphics.setColor(r,g,b,i/#ball.trail)
            love.graphics.rectangle('fill',t.x,t.y,ball.size,ball.size)
        end
    end

    -- paddles
    love.graphics.setColor(leftPaddle.hitTimer>0 and {1,0.2,0.2} or {1,1,1})
    love.graphics.rectangle('fill',leftPaddle.x,leftPaddle.y,leftPaddle.width,leftPaddle.height)

    love.graphics.setColor(rightPaddle.hitTimer>0 and {0.2,0.2,1} or {1,1,1})
    love.graphics.rectangle('fill',rightPaddle.x,rightPaddle.y,rightPaddle.width,rightPaddle.height)

    -- winning particles
    for _,p in ipairs(particles) do
        love.graphics.setColor(p.r,p.g,p.b)
        love.graphics.rectangle('fill',p.x,p.y,4,4)
    end

    -- winner animation: expanding circle
    if winnerAnimation.active then
        local radius = winnerAnimation.scale * 50
        love.graphics.setColor(1,0.8,0, 1 - winnerAnimation.time)
        love.graphics.circle('line', WINDOW_WIDTH/2, WINDOW_HEIGHT/2, radius)
    end

    -- messages
    if gameState=='start' then
        love.graphics.setFont(smallFont)
        love.graphics.setColor(1,1,1)
        love.graphics.printf("Press Enter to Begin!\nP1: W/S  P2: Up/Down  P: Pause",0,WINDOW_HEIGHT/2,WINDOW_WIDTH,'center')
    end

    if paused then
        love.graphics.setFont(pongFont)
        love.graphics.setColor(1,1,0)
        love.graphics.printf("PAUSED",0,WINDOW_HEIGHT/2-100,WINDOW_WIDTH,'center')
    end

    -- draw winner text with pop animation
    if gameState=='done' then
        local winner = player1Score>=10 and player1Name or player2Name
        love.graphics.setFont(pongFont)
        love.graphics.setColor(1,1,0)
        local scale = winnerAnimation.active and winnerAnimation.scale or 1
        love.graphics.push()
        love.graphics.translate(WINDOW_WIDTH/2, WINDOW_HEIGHT/2)
        love.graphics.scale(scale, scale)
        love.graphics.printf(winner.." wins! Press Enter to restart.", -WINDOW_WIDTH/2, 0, WINDOW_WIDTH, 'center')
        love.graphics.pop()
    end
end

function checkCollision(a,b)
    return a.x < b.x+b.width and b.x < a.x+(a.size or a.width) and a.y < b.y+b.height and b.y < a.y+(a.size or a.height)
end

-- rainbow helper
function hsvToRgb(h,s,v)
    local r,g,b
    local i = math.floor(h*6)
    local f = h*6 - i
    local p = v * (1 - s)
    local q = v * (1 - s*f)
    local t = v * (1 - s*(1-f))
    i = i % 6
    if i == 0 then r,g,b = v, t, p
    elseif i == 1 then r,g,b = q, v, p
    elseif i == 2 then r,g,b = p, v, t
    elseif i == 3 then r,g,b = p, q, v
    elseif i == 4 then r,g,b = t, p, v
    elseif i == 5 then r,g,b = v, p, q
    end
    return r,g,b
end

-- Winning particles
function spawnWinningParticles(winner)
    for i=1,100 do
        local p = {x=WINDOW_WIDTH/2, y=WINDOW_HEIGHT/2, dx=math.random(-200,200), dy=math.random(-200,200),
                    life=2, r=math.random(), g=math.random(), b=math.random()}
        table.insert(particles,p)
    end
end







-- title:  Oseo
-- author: msx80
-- desc:   Balloon popping fun for the family!
-- script: lua
-- input:  gamepad
-- saveid: msx80.oseo

-- Big thanks to Fubuki for graphics!

DAMP=1.06  -- acceleration damping
players=1
speed=1
t=0        -- time
lives=3    -- lives left
hit=0      -- score counter

Player={}
function Player.new(x, y)
  obj = {
    ax=0, -- acceleration
    ay=0,
    x=x,  -- position
    y=y
  }
  setmetatable(obj, {__index=Player})
  return obj
end

function Player:update(up, down, left, right)
  -- controls
  if btn(up) then
    self.ay=self.ay-0.1
  end
  if btn(down) then
    self.ay=self.ay+0.1
  end
  if btn(left) then
    self.ax=self.ax-0.1 self.flip=1
  end
  if btn(right) then
    self.ax=self.ax+0.1 self.flip=0
  end

  -- dampen acceleration
  self.ax=self.ax/DAMP
  self.ay=self.ay/DAMP

  -- move
  self.x=self.x+self.ax
  self.y=self.y+self.ay

  -- clamp
  if self.x<0 then
    self.x=0
  end
  if self.x>224 then
    self.x=224
  end
  if self.y<0 then
    self.y=0
  end
  if self.y>120 then
    self.y=120
  end
end

function Player:draw(t, index)
  if index>0 then
    poke4(0x3FF0*2+4, 3)
  else
    poke4(0x3FF0*2+4, 4)
  end
  spr(33+(math.floor((t/12)%4)*2), self.x, self.y, 14, 1, self.flip, 0, 2, 2)
end

player1=Player.new(0, 0)
player2=Player.new(0, 0)
flip=0  -- direction facing
highest=false -- wethere the player did hihg score
mode=0  -- game mode

-- set a minimal high score
if pmem(0)==0 then
  pmem(0, 50)
end

-- randomly initialize a balloon
function initBalloon()
  return {
    -- start anywhere on the bottom line
    x = 5+math.random(214),
    -- start somewhere below the bottom
    -- to give some time before it appears
    y = 136 + math.random(50),
    -- width of the horizontal oscillation
    width = 3+math.random(10),
    -- random starting angle to avoid
    -- having all balloons sincronized
    angle = math.random(628)/100,
    -- raising speed of balloon
    speed = hit/1000+ 0.1+math.random()/2,
    -- choose one of the colors
    color = math.random(5)
  }
end

-- initialize array of 4 balloons
balloons = {
  initBalloon(),
  initBalloon(),
  initBalloon(),
  initBalloon()
}

-- calculate x displacement of
-- balloon b at time t
function dx(b, t)
  return math.cos(t/30*speed+b.angle)*b.width
end

-- check if bird collides with balloon b
function collide(b, player)
  -- calculate beak position
  local beakX = player.x+(player.flip==0 and 15 or 0)
  local beakY = player.y+8
  -- test collision
  return beakX > b.x and beakX < b.x+16
    and beakY > b.y and beakY < b.y+16
end

function handleBalloons(compute_collisions)
  for i=1, #balloons do
    local b=balloons[i]
    -- recalculate old displacement
    -- to be subtracted and new one to be
    -- added. Not the most performant
    -- thing but hey
    local oldDx = dx(b, t-1)
    local newDx = dx(b, t)
    b.x = b.x + newDx - oldDx
    b.y = b.y - b.speed * speed
    spr(1+(b.color*2), b.x, b.y, 15, 1, 0, 0, 2, 2)

    -- do collision and stuff only if
    -- actually playing
    if mode == 1 then
      if b.y<-16 then
        -- reset balloons it it went high
        balloons[i]=initBalloon()
        lives=lives-1
        if lives==0 then
          mode=2
          sfx(2, 20, 70)
          if pmem(0)<hit then
            highest=true
            pmem(0, hit)
          end
        else
          sfx(1, 20, 14)
        end
      elseif compute_collisions and (collide(b, player1) or collide(b, player2)) then
        -- test collision
        sfx(0, 30, 6)
        hit = hit+1
        balloons[i]=initBalloon()

      end
    end
  end
end

function printb(pbt, pbx, pby, pbc, pbs)
  if pbc==nil then
    pbc=15
  end
  if pbs==nil then
    pbs=1
  end
  print(pbt, pbx-1, pby, 0, false, pbs)
  print(pbt, pbx, pby-1, 0, false, pbs)
  print(pbt, pbx+1, pby, 0, false, pbs)
  print(pbt, pbx, pby+1, 0, false, pbs)
  print(pbt, pbx, pby, pbc, false, pbs)
end

function TIC()
  if mode==0 then
    introTIC()
  elseif mode==1 then
    gameTIC()
  elseif mode==2 then
    gameOverTIC()
  end
end

function gameTIC()
  player1:update(0, 1, 2, 3)
  if players > 1 then
    player2:update(8, 9, 10, 11)
  end

  drawBackground()
  handleBalloons(true)

  player1:draw(t, 0)
  player2:draw(t, 1)
  for i=1, lives do
    spr(64, 32+i*8, 3, 14, 1, 0, 0, 1, 1)
  end
  printb("HIGHEST SCORE: "..pmem(0), 100, 5, 15)

  printb("SCORE: "..hit, 5, 13, 15)
  printb("LIVES: ", 5, 5, 15)
  t=t+1
end

function drawBackground()
  cls(13)
  spr(96, 40, 30, 0, 1, 0, 0, 8, 8)
  spr(96, 150, 80, 0, 1, 0, 0, 8, 8)
end

DIFFICULTY_SETTINGS={
  {name='easy', speed=0.5},
  {name='normal', speed=1.0},
  {name='hard', speed=1.3},
}
difficulty=1
choice=2

Widget={}
function Widget.new(x, y, get_text, press)
  local obj={
    x=x,       -- position
    y=y,
    get_text=get_text,
    press=press
  }
  setmetatable(obj, {__index=Widget})
  return obj
end

function Widget:draw(selected)
  text=self.get_text()
  color=selected and 6 or 15
  printb(text, self.x, self.y, color)
end

WIDGETS={
  Widget.new(29, 69, function()
      if players > 1 then
        return '2 players'
      else
        return '1 player'
      end
    end,
    function()
      players=players%2+1
  end),
  Widget.new(29, 79, function()
      return "Difficulty: "..DIFFICULTY_SETTINGS[difficulty+1].name
    end,
    function()
      difficulty=(difficulty+1)%3
  end),
  Widget.new(29, 99, function()
      return "START"
    end,
    function()
      player1 = Player.new(80, 50)
      if players > 1 then
        player2 = Player.new(120, 50)
      else
        player2 = Player.new(-120, 50)
      end
      hit=0
      lives=3
      speed=DIFFICULTY_SETTINGS[difficulty+1].speed
      balloons = {
        initBalloon(),
        initBalloon(),
        initBalloon(),
        initBalloon()
      }
      sfx(3, 70, 20)
      mode=1
  end),
}

function introTIC()
  drawBackground()

  handleBalloons(false)

  printb("OSEO", 149, 19, 6, 2)
  printb("Balloon popping fun!", 119, 34, 15)
  printb("by msx80 & Fubuki", 127, 44, 15)

  for i, widget in ipairs(WIDGETS) do
    widget:draw(i-1==choice)
  end

  t=t+1

  if btnp(0) then
    choice=(choice-1)%3
  end
  if btnp(1) then
    choice=(choice+1)%3
  end
  if btnp(4) then
    WIDGETS[choice+1]:press()
  end
end

function gameOverTIC()

  drawBackground()
  handleBalloons(false)

  print("GAME OVER", 70, 50, 0, false, 2)
  print("GAME OVER", 70, 49, 6, false, 2)

  print("You popped "..hit.." balloons!", 60, 70, 0)
  print("You popped "..hit.." balloons!", 59, 69)

  if highest then
    print("YOU MADE A NEW HIGH SCORE!", 50, 90, 0)
    print("YOU MADE A NEW HIGH SCORE!", 49, 89, 14)
  end

  t=t+1

  if btnp(4) then
    -- reset some game state for
    -- the intro screen
    hit=0
    mode=0
    highest=false
  end
end

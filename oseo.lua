-- title:  Oseo
-- author: msx80
-- desc:   Balloon popping fun for the family!
-- script: lua
-- input:  gamepad
-- saveid: msx80.oseo

-- Big thanks to Fubuki for graphics!

-- note: i was convinced it was "baloon"
-- while i figured out it's "balloon"
-- too lazy to correct all the source.

DAMP=1.06  -- acceleration damping
t=0        -- time
lives=3    -- lives left
hit=0						-- score counter
ax=0       -- acceleration
ay=0
x=96       -- position
y=24
flip=0     -- direction facing
highest=false -- wethere the player did hihg score
mode=0					-- game mode

-- set a minimal high score
if pmem(0)==0 then
 pmem(0,50)
end

-- randomly initialize a baloon
function initBaloon()
		return {
		 -- start anywhere on the bottom line
			x = 5+math.random(214),
			-- start somewhere below the bottom
			-- to give some time before it appears
			y = 136 + math.random(50), 
			-- width of the horizontal oscillation
			width = 3+math.random(10),
			-- random starting angle to avoid
			-- having all baloons sincronized
			angle = math.random(628)/100,
			-- raising speed of baloon
			speed = hit/1000+ 0.1+math.random()/2,
			-- choose one of the colors
			color = math.random(5)
		}
end

-- initialize array of 4 baloons
baloons = {
	initBaloon(),
	initBaloon(),
	initBaloon(),
	initBaloon()
}

-- calculate x displacement of 
-- baloon b at time t
function dx(b,t)
		return math.cos(t/30+b.angle)*b.width
end

-- check if bird collides with baloon b
function collide(b)
 -- calculate beak position
	local beakX = x+(flip==0 and 15 or 0)
	local beakY = y+8
	-- test collision
 return beakX > b.x and beakX < b.x+16
	   and beakY > b.y and beakY < b.y+16
end

function handleBaloons()
	for i=1,#baloons do
	 local b=baloons[i]
		-- recalculate old displacement
		-- to be subtracted and new one to be
		-- added. Not the most performant
		-- thing but hey
		local oldDx = dx(b,t-1)
		local newDx = dx(b,t)
		b.x = b.x + newDx - oldDx
		b.y = b.y - b.speed
		spr(1+(b.color*2),b.x,b.y,15,1,0,0,2,2)

	 -- do collision and stuff only if 
		-- actually playing
			if mode == 1 then
  
				if b.y<-16 then 
		   -- reset baloons it it went high
				 baloons[i]=initBaloon()	
					lives=lives-1
					if lives==0 then
					  mode=2
					  sfx(2,20,70)
							if pmem(0)<hit then
							  highest=true
									pmem(0,hit)
							end
					else
							sfx(1,20,14)
					end
				elseif collide(b) then
					-- test collision
					sfx(0,30,6)
					hit = hit+1
					baloons[i]=initBaloon()
		
				end
			end
	
	end
	
end

function printb(pbt,pbx,pby,pbc,pbs)
	if pbc==nil then pbc=15 end
	if pbs==nil then pbs=1 end
	print(pbt,pbx-1,pby,0,false,pbs)
	print(pbt,pbx,pby-1,0,false,pbs)
	print(pbt,pbx+1,pby,0,false,pbs)
	print(pbt,pbx,pby+1,0,false,pbs)
	print(pbt,pbx,pby,pbc,false,pbs)
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

 -- controls
	if btn(0) then ay=ay-0.1 end
	if btn(1) then ay=ay+0.1 end
	if btn(2) then ax=ax-0.1; flip=1 end
	if btn(3) then ax=ax+0.1;	flip=0	end
 
	-- dampen acceleration
	ax=ax/DAMP
	ay=ay/DAMP

 -- move
 x=x+ax
	y=y+ay

 -- clamp
 if x<0 then x=0 end
	if x>224 then x=224 end
 if y<0 then y=0 end
	if y>120 then y=120 end

	drawBackground()	
	handleBaloons()
	
	spr(33+(math.floor((t/12)%4)*2),x,y,14,1,flip,0,2,2)
 for i=1,lives do
		spr(64,32+i*8,3,14,1,0,0,1,1)
	end
	printb("HIGHEST SCORE: "..pmem(0),100,5,15)
	
	printb("SCORE: "..hit,5,13,15)
	printb("LIVES: ",5,5,15)
	t=t+1
end

function drawBackground()
	cls(13)
 spr(96,40,30,0,1,0,0,8,8)
 spr(96,150,80,0,1,0,0,8,8)

end

function introTIC()
 
 -- move the player away
 x=-100
	y=0
	
	drawBackground();
	
	handleBaloons()

	printb("OSEO",149,19,6,2)

	printb("Balloon popping fun!",119,34,15)

	printb("by msx80 & Fubuki",127,44,15)
	
	printb("PRESS A TO START",29,89)

	t=t+1
	
	if btnp(4) then
	 -- initialize game
	 x=80
		y=50
		hit=0
		lives=3
  ax=0
		ay=0
		baloons = {
			initBaloon(),
			initBaloon(),
			initBaloon(),
			initBaloon()
		}
		sfx(3,70,20)
	 mode=1
	end
	
end

function gameOverTIC()
 
 -- move the player away
 x=-100
	y=0

	drawBackground()	
	handleBaloons()

	print("GAME OVER",70,50,0,false,2)
	print("GAME OVER",69,49,6,false,2)

	print("You popped "..hit.." balloons!",60,70,0)
	print("You popped "..hit.." balloons!",59,69)

 if highest then
  	print("YOU MADE A NEW HIGH SCORE!",50,90,0)
  	print("YOU MADE A NEW HIGH SCORE!",49,89,14)
 end

	t=t+1
	
	if btnp(4) then
	 -- reset some game state for
		-- the intro screen
		x=-100
		y=0
		hit=0
	 mode=0
		highest=false
	end
	
end

io.stdout:setvbuf("no")
local game={}
game.info={
	version="0.0.1",
	author="Alexar JING",
	lisence="CC3.0",
}

local Frag=require "frag"


game.frags={}
game.matrixWidth=10
game.matrixHeight=18
game.matrix={}
game.matrixSaved={}
game.toClear={}
game.targetGrid=require "grid"
game.score=0
game.red=0
game.green=0
game.blue=0
game.level=1
game.font = love.graphics.newFont(20)
game.font2 = love.graphics.newFont(12)
game.pause=false

game.bgColor={0,0,0,255}
game.blancColor={255,255,255,100}
game.pixelSize=30
game.pixelPadding=2
game.position={230,10}
game.width=game.matrixWidth*(game.pixelSize+game.pixelPadding)+game.pixelPadding
game.height=game.matrixHeight*(game.pixelSize+game.pixelPadding)+game.pixelPadding
local bloom=require "bloom"(game.width/2,game.height/2)
game.canvas = love.graphics.newCanvas(game.width,game.height)
game.updateCD=0.8
game.timer=0.5
game.matchCount=5
game.pixelColor={
	{250,155,155,255},
	{155,250,155,255},
	{155,155,250,255}
}
game.pixelColor[0]={128,128,128,255}
game.antiCount=100

local cType={"red","green","blue"}
cType[0]="gray"
game.fragCanvas={
	[0]=love.graphics.newCanvas(game.pixelSize, game.pixelSize),
	[1]= love.graphics.newCanvas(game.pixelSize, game.pixelSize),
	[2] = love.graphics.newCanvas(game.pixelSize, game.pixelSize),
	[3] = love.graphics.newCanvas(game.pixelSize, game.pixelSize),
	
}
for i=0,3 do
	love.graphics.setCanvas(game.fragCanvas[i])
	love.graphics.setColor(game.pixelColor[i])
	love.graphics.rectangle("fill", 0, 0, game.pixelSize, game.pixelSize)
	love.graphics.setCanvas()
end

local t=Frag:init(
						1,
						1,
						0,game.fragCanvas[1]
						)
				

local function getIndex(tab,value)
	for i,v in ipairs(tab) do
		if value==v then return i end
	end
end


local function matrixCopy(matrix)
	local rt={}
	for y,v in ipairs(matrix) do
		rt[y]={}
		for x,p in ipairs(v) do
			if type(p)=="table" then
				rt[y][x]={value=p.value,color={unpack(p.color)}}
			else
				rt[y][x]=p
			end
		end
	end
	return rt
end

local function inRect(x,y)
	if x<1 or y<1 then return false end
	if x>game.matrixWidth or y>game.matrixHeight then return false end
	return true
end







function game.matrixInit()
	for y=1,game.matrixHeight do
		game.matrixSaved[y]={}
		game.matrix[y]={}
		for x=1,game.matrixWidth do
			game.matrix[y][x]={value=false,color={0,0,0,255}}
			game.matrixSaved[y][x]={value=false,color={0,0,0,255}}
		end
	end
end

function game.matrixClear()
	for y=1,game.matrixHeight do
		for x=1,game.matrixWidth do
			game.matrix[y][x].value=game.matrixSaved[y][x].value
			game.matrix[y][x].color={unpack(game.matrixSaved[y][x].color)}
		end
	end
end

function game.matrixSave()
	game.matrixSaved=matrixCopy(game.matrix)
end


function game.update()
	if game.pause then return end
	game.antiCount=game.antiCount-love.timer.getDelta()
	if game.antiCount<0 then
		game.gameover()
	end
	if #game.toClear==0 then
		game.drop()
	else
		game.clearUpdate()
	end
	game.objectSetMatrix(game.next)
	game.objectSetMatrix(game.obj)
	for i=#game.frags,1,-1 do
		game.frags[i]:update()
		if game.frags[i].destroy then table.remove(game.frags,1) end
	end

end

function game.getCurrentLevel()
	for y=1,game.matrixHeight do
		for x=1,game.matrixWidth do
			if game.matrixSaved[y][x].value then return y end
		end
	end	

end



function game.clearUpdate()
	for i=#game.toClear,1,-1 do
		
		game.toClear[i].timer=game.toClear[i].timer- love.timer.getDelta()
		
		if game.toClear[i].line then
			game.toClear[i].alpha=game.toClear[i].alpha+30
			if game.toClear[i].alpha>255 then game.toClear[i].alpha=game.toClear[i].alpha-255 end
			if game.toClear[i].timer>0 then
				for x=1,game.matrixWidth do
					game.matrix[game.toClear[i].line][x].color[4]=game.toClear[i].alpha
				end
			else
				game.removeLine(game.toClear[i].line)
				table.remove(game.toClear, i)
			end
		else
			if game.toClear[i].timer>0 then
				for _,v in ipairs(game.toClear[i].blocks) do
					for i=1,3 do
						game.matrixSaved[v[2]][v[1]].color[i]=game.matrixSaved[v[2]][v[1]].color[i]+
						(128-game.matrixSaved[v[2]][v[1]].color[i])*0.1
					end
				end
				game.matrixClear()
			else
				--game.removeBlocks(game.toClear[i].blocks)
				for _,v in ipairs(game.toClear[i].blocks) do
					for i=1,3 do
						game.matrixSaved[v[2]][v[1]].value=0
					end
				end
				
				table.remove(game.toClear, i)
			end
		end
	end

end

function game.removeLine(line)
	local tab={}
	for x=1,game.matrixWidth do
		tab[x]={value=false,color={0,0,0,255}}
	end
	table.remove(game.matrixSaved, line)
	table.insert(game.matrixSaved, 1, tab)
	game.matrixClear()
end

function game.removeBlocks(blocks)
	for i,v in ipairs(blocks) do
		game.matrixSaved[v[2]][v[1]]={value=false,color={0,0,0,255}}
	end
	game.matrixClear()
	local todelet={}
	for y=1,game.matrixHeight do
		local empty=true
		for x=1,game.matrixWidth do
			if game.matrixSaved[y][x].value then empty=false end
		end
		if empty then
			table.insert(todelet, y)
		end
	end
	local count=#todelet
	for i=count,1,-1 do
		table.remove(game.matrixSaved,todelet[i])
	end
	for i=1,count do
		local tab={}
		for x=1,game.matrixWidth do
			tab[x]={value=false,color={0,0,0,255}}
		end
		table.insert(game.matrixSaved, 1,tab)
	end
	game.matrixClear()
end

function game.checkLine()
	local count=0
	for y=game.matrixHeight,1,-1 do
		local full=true
		for i,v in ipairs(game.matrixSaved[y]) do
			if not v.value then
				full=false
				break
			end
		end
		if full then 
			count=count+1
			game.addClear(y)
			for i,v in ipairs(game.matrixSaved[y]) do
				table.insert(game.frags, 
					Frag:init(
						(i-1)*game.pixelSize+game.pixelPadding+game.pixelSize/2,
						(y)*game.pixelSize+game.pixelPadding+game.pixelSize/2,
						0,game.fragCanvas[v.value]
						)
					)
			end
		end	
	end
	if count~=0 then game.score=game.score+2^count end
end

function game.addScore(t)
	game.score=game.score+t
	if game.score>game.level*100 then
		game.level=game.level+1
		game.updateCD=game.updateCD*0.8
	end
end



function game.checkDeath()
	local gameover
	for x,p in ipairs(game.matrixSaved[1]) do
		if p.value then gameover=true;break end
	end
	if gameover then
		game.gameover()
	end
end

function game.gameover()
	local title="Game Over"
	local message="Your Score: "..game.score.."! Restart?"
	local b=love.window.showMessageBox( title, message, {"Restart","Quit"})
	if b==1 then
		love.load()
	else
		love.event.quit()
	end
end

function game.checkMatch()
	local mat=game.matrixSaved
	local toCheck={}
	local w=game.matrixWidth
	local h=game.matrixHeight

	local checked={}
	local result={}
	local found={}
	local search

	
	search=function(testColor)
		if #toCheck==0 then return end
		repeat
			local x,y=unpack(toCheck[1])
			
			local pass=false
			if not inRect(x,y) then pass=true end
			if checked[y] and checked[y][x] then pass=true end
		
			if  not pass and mat[y][x].value==testColor then
				if not checked[y] then checked[y]={} end
				checked[y][x]=true
				table.insert(result,toCheck[1] )
				table.remove(toCheck, 1)
				table.insert(toCheck,{x+1,y})
				table.insert(toCheck,{x-1,y})
				table.insert(toCheck,{x,y-1})
				table.insert(toCheck,{x,y+1})
				search(testColor)
			else
				table.remove(toCheck, 1)
			end
			
		until #toCheck==0
	end

	for y=1,h do
		for x=1,w do
			if (mat[y][x].value and mat[y][x].value~=0) and (not (checked[y] and checked[y][x]))then
				toCheck={{x,y}}
				result={}
				search(mat[y][x].value)
				if #result>=game.matchCount then
					table.insert(found,result)
					game.addPower(mat[y][x].value,#result)
					for i,v in ipairs(result) do
						v.value=0
					end

				end
			end
		end
	end
	for i,v in ipairs(found) do
		game.addClear(_,v)
	end
end


function game.addPower(t,p)
	game[cType[t]]=game[cType[t]]+p
	if game[cType[t]]>=15 then
		game[cType[t].."Power"]()
		game[cType[t]]=game[cType[t]]-15
	end
end

function game.redPower()
	for i=1,3 do
		game.addClear( love.math.random(game.getCurrentLevel(),game.matrixHeight))
		game.score=game.score+2
	end
end

function game.greenPower()
	game.antiCount=game.antiCount+30
end

function game.bluePower()
	local noColor={}
	for y=1,game.matrixHeight do
		for x=1,game.matrixWidth do
			if game.matrixSaved[y][x].value==0 then
				table.insert(noColor, game.matrixSaved[y][x])
			end
		end
	end

	for i=1,10 do
		local p=noColor[ love.math.random(1,#noColor)]
		local c=love.math.random(1,3)
		p={value=c,color=game.pixelColor[c]}
	end
end

function game.addClear(line,blocks)
	if line then
		table.insert(game.toClear,{line=line,timer=0.5,alpha=0})
	else
		table.insert(game.toClear,{timer=0.4,blocks=blocks})
	end
end

function game.drop()
	game.matrixClear()

	if game.falling then
		local speed=1/game.updateCD>1 and 1 or 1/game.updateCD
		game.obj.y=game.obj.y+speed
	else
		game.timer=game.timer- love.timer.getDelta()
		if game.timer>0 then
			return
		end
		game.obj.y=game.obj.y +1
		game.timer=game.updateCD
	end
	
	if game.obj.y>2 and not game.next then
		game.next= game.createObject()
	end

	if game.objectCollideTest(game.obj)~=0 then
		game.obj.y=game.obj.y-1
		game.objectSetMatrix(game.obj)
		game.matrixSave()
		game.obj=game.next or game.createObject()
		game.next=nil
		game.falling= false
		game.checkLine()
		game.checkMatch()
		game.checkDeath()
	end
	
end




function game.draw()
	love.graphics.setCanvas(game.canvas)
	love.graphics.clear()
	


	for y=1,game.matrixHeight do
		for x=1,game.matrixWidth do
			local pixel=game.matrix[y][x]
			if pixel.value then
				local r,g,b,a=unpack(pixel.color)
				local k=200*a/255
				love.graphics.setColor(r,g,b,k)
				love.graphics.rectangle("fill", 
					(x-1)*(game.pixelSize+game.pixelPadding)+game.pixelPadding, 
					(y-1)*(game.pixelSize+game.pixelPadding)+game.pixelPadding, 
					game.pixelSize, game.pixelSize,game.pixelSize/5,game.pixelSize/5)
				love.graphics.setColor(r,g,b,a)
				love.graphics.rectangle("line", 
					(x-1)*(game.pixelSize+game.pixelPadding)+game.pixelPadding, 
					(y-1)*(game.pixelSize+game.pixelPadding)+game.pixelPadding, 
					game.pixelSize, game.pixelSize,game.pixelSize/5,game.pixelSize/5)
			else
				love.graphics.setColor(game.blancColor)
				love.graphics.rectangle("line", 
					(x-1)*(game.pixelSize+game.pixelPadding)+game.pixelPadding, 
					(y-1)*(game.pixelSize+game.pixelPadding)+game.pixelPadding, 
					game.pixelSize, game.pixelSize,game.pixelSize/5,game.pixelSize/5)
			end
		end
	end
	love.graphics.setCanvas()
	love.graphics.setColor(255, 255, 255, 255)
	local x,y=unpack(game.position)
	love.graphics.rectangle("line", x, y, game.width, game.height)
	bloom:predraw()
    bloom:enabledrawtobloom()
    love.graphics.draw(game.canvas,x,y)
	bloom:postdraw()
	love.graphics.draw(game.canvas,x,y)
	love.graphics.setFont(game.font)
	love.graphics.print("Score: "..game.score, 20,10)
	love.graphics.print("Red Power: "..game.red, 20,50)
	love.graphics.print("Green Power: "..game.green, 20,90)
	love.graphics.print("Blue Power: "..game.blue, 20,130)
	love.graphics.print(string.format("Life: %0.2f",game.antiCount), 20,170)
	love.graphics.print("LeveL: "..game.level, 20,210)
	love.graphics.setFont(game.font2)
	love.graphics.print("15 red power will destroy\n random 3 lines", 600,20)
	love.graphics.print("15 blue power will repaint\n 10 gray blocks", 600,60)
	love.graphics.print("15 green power will add\n 30 seconds life", 600,100)

	love.graphics.print("control: a s w d", 600,140)
	love.graphics.print("upper then 5 matched color\n will generate power", 600,180)
	love.graphics.print("a full row will be removed", 600,220)
	love.graphics.print("if life reaches 0 or blocks\n reach top, game over", 600,260)

	love.graphics.setFont(game.font)
	if game.pause then
		love.graphics.print("PAUSE", 360,300)
	end

	for i=#game.frags,1,-1 do
		game.frags[i]:draw(x,y)
	end
end




function game.createObject()
	local t=love.math.random(1,7)
	local grid=matrixCopy(game.targetGrid[t])
	local mat={}
	for y=1,#grid do
		mat[y]={}
		for x=1,#grid[y] do
			if grid[y][x]==1 then
				local c=love.math.random(1,3)
				mat[y][x]={value=c,color=game.pixelColor[c]}
			else
				mat[y][x]={value=false}
			end
		end
	end
	game.timer=game.updateCD
	local obj={grid=mat,x=5,y=0}
	game.objectSetMatrix(obj)
	return obj
end

function game.objectTurn(obj,anti)
	local target={}
	for y=1,#obj.grid do
		for x=1,#obj.grid[y] do
			target[x]=target[x] or {}
			if anti then
				target[x][y]=obj.grid[math.abs(y-#obj.grid-1)][x]
			else
				target[x][y]=obj.grid[y][math.abs(x-#obj.grid[y]-1)]
			end
		end
	end
	obj.grid=target
end

function game.objectSetMatrix(obj)
	if not obj then return end
	local ox,oy=math.floor(obj.x),math.floor(obj.y)
	for y=1,#obj.grid do
		for x=1,#obj.grid[y] do
			if inRect(ox+x,oy+y) then
				if obj.grid[y][x].value then
					game.matrix[oy+y][ox+x].value=obj.grid[y][x].value
					game.matrix[oy+y][ox+x].color={unpack(obj.grid[y][x].color)}
				else
					game.matrix[oy+y][ox+x].value=game.matrixSaved[oy+y][ox+x].value
					game.matrix[oy+y][ox+x].color={unpack(game.matrixSaved[oy+y][ox+x].color)}
				end
			end
		end
	end
end



function game.objectCollideTest(obj)
	local ox,oy=math.floor(obj.x),math.floor(obj.y)
	for y=1,#obj.grid do
		for x=1,#obj.grid[y] do
			if not inRect(ox+x,oy+y) then return -1 end --hitwall 
			if obj.grid[y][x].value and game.matrixSaved[oy+y][ox+x].value then
				return 1 --hit obj
			end
		end
	end	
	return 0 --hit nothing
end

function game.moveleft()
	game.matrixClear()
	game.obj.x=game.obj.x-1
	if game.objectCollideTest(game.obj) ~=0 then
		game.obj.x=game.obj.x+1
	end
	game.objectSetMatrix(game.obj)
end

function game.moveright()
	game.matrixClear()
	game.obj.x=game.obj.x+1
	if game.objectCollideTest(game.obj) ~=0 then
		game.obj.x=game.obj.x-1
	end
	game.objectSetMatrix(game.obj)
end

function game.transform()
	game.matrixClear()
	game.objectTurn(game.obj)
	local test=game.objectCollideTest(game.obj)
	if  test>0 then
		game.objectTurn(game.obj,true)
	elseif test<0 then
		repeat
			game.obj.x=game.obj.x-1
		until game.objectCollideTest(game.obj)==0
		
	end
	game.objectSetMatrix(game.obj)
end

function game.fall()
	game.falling = true
end

function game.togglePause()
	game.pause=not game.pause
end

function love.keypressed(key)

	if key=="w" then
		game.transform()
	end


	if key=="a" then
		game.moveleft()	
	end

	if key=="d" then
		game.moveright()	
	end

	if key=="s" then
		game.fall()
	end

	if key=="space" then
		game.togglePause()
	end
end


love.keyboard.setKeyRepeat( true )

function love.load()
	game.matrixInit()
	game.matrixClear()
	game.obj=game.createObject()
end

function love.update()
	game.update()
end

function love.draw()
	game.draw()
end


function love.mousepressed(x, y, button, istouch)
	game.dragOX,game.dragOY=x,y
	game.dragTimer=love.timer.getTime( )
end

function love.mousemoved(x,y)
	if not game.dragOX then return end
	if love.timer.getTime( )-game.dragTimer<0.3 then return end
	game.dragTX,game.dragTY=x,y
	game.dragMX=game.dragMX or game.dragOX
	game.dragMY=game.dragMY or game.dragOY
	local dx=game.dragTX-game.dragMX
	local dy=game.dragTY-game.dragMY
	local dist= math.sqrt(dx^2+dy^2)
	if dist>30 then
		if dx>0 then
			game.moveright()
		elseif dx<0 then
			game.moveleft()
		end
		game.dragMX,game.dragMY=x,y
	end

end

function love.mousereleased(x,y)
	game.dragTX,game.dragTY=x,y
	local dx=game.dragTX-game.dragOX
	local dy=game.dragTY-game.dragOY
	local dist= math.sqrt(dx^2+dy^2)
	
		if dy>100 and math.abs(dx)<50 then
			game.fall()
		end
		if dy<-100 and math.abs(dx)<50 then
			game.transform()
		end
	
		if dx>100 and math.abs(dy)<50 then
			game.moveright()
		end

		if dx<-100 and math.abs(dy)<50 then
			game.moveleft()
		end

	game.dragOX=nil
	game.dragMX=nil
	game.dragMY=nil
end
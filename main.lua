io.stdout:setvbuf("no")
local game={}
game.info={
	version="0.0.1",
	author="Alexar JING",
	lisence="CC0",
}

game.matrixWidth=10
game.matrixHeight=15
game.matrix={}
game.matrixSaved={}
game.toClear={}
game.targetGrid=require "grid"




local function matrixCopy(matrix)
	local rt={}
	for y,v in ipairs(matrix) do
		rt[y]={}
		for x,p in ipairs(v) do
			if type(p)=="table" then
				rt[y][x]={value=p.value,color=p.color}
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
			game.matrix[y][x].color=game.matrixSaved[y][x].color
		end
	end
end

function game.matrixSave()
	game.matrixSaved=matrixCopy(game.matrix)
end

game.updateCD=0.5
game.timer=0
function game.update()
	if #game.toClear==0 then

		if game.falling then
			game.obj.y=game.obj.y+0.4
			game.drop()
		else
			game.timer=game.timer- love.timer.getDelta()
			if game.timer<0 then
				game.drop()
				game.timer=game.updateCD
			end
		end
	else
		for i=#game.toClear,1,-1 do
			game.toClear[i].alpha=game.toClear[i].alpha+30
			if game.toClear[i].alpha>255 then game.toClear[i].alpha=game.toClear[i].alpha-255 end
			game.toClear[i].timer=game.toClear[i].timer- love.timer.getDelta()
			
			if game.toClear[i].line then
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
						game.matrix[v[2]][v[1]].color[4]=game.toClear[i].alpha
					end
				else
					game.removeBlocks(game.toClear[i].blocks)
					table.remove(game.toClear, i)
				end
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
			print(y)
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
	for y=game.matrixHeight,1,-1 do
		local full=true
		for i,v in ipairs(game.matrixSaved[y]) do
			if not v.value then
				full=false
				break
			end
		end
		if full then game.addClear(y) end
	end
end

local function getIndex(tab,value)
	for i,v in ipairs(tab) do
		if value==v then return i end
	end
end

game.matchCount=5

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
			if mat[y][x].value and (not (checked[y] and checked[y][x]))then
				toCheck={{x,y}}
				result={}
				search(mat[y][x].value)
				if #result>=game.matchCount then
					table.insert(found,result)
				end
			end
		end
	end
	for i,v in ipairs(found) do
		game.addClear(_,v)
	end
end



function game.addClear(line,blocks)
	table.insert(game.toClear,{line=line,timer=0.5,alpha=0,blocks=blocks})
end

function game.drop()
	game.matrixClear()
	if not game.falling then game.obj.y=game.obj.y +1 end
	if game.objectCollideTest(game.obj)==0 then
		game.objectSetMatrix(game.obj)
	else --hit something
		game.obj.y=game.obj.y-1
		game.objectSetMatrix(game.obj)
		game.matrixSave()
		game.obj=game.createObject()
		game.falling= t
		game.checkLine()
		game.checkMatch()
	end
	--game.objectSetMatrix(game.obj)
end



game.bgColor={0,0,0,255}
game.blancColor={100,100,100,255}
game.pixelSize=30
game.pixelPadding=2
game.position={100,10}
game.width=game.matrixWidth*(game.pixelSize+game.pixelPadding)+game.pixelPadding
game.height=game.matrixHeight*(game.pixelSize+game.pixelPadding)+game.pixelPadding
local bloom=require "bloom"(game.width/2,game.height/2)
game.canvas = love.graphics.newCanvas(game.width,game.height)
function game.draw()
	love.graphics.setCanvas(game.canvas)
	love.graphics.clear()
	--love.graphics.setColor(game.bgColor)
	--love.graphics.rectangle("fill", 0, 0, 
	--	game.matrixWidth*(game.pixelSize+game.pixelPadding)+game.pixelPadding, 
	--	game.matrixHeight*(game.pixelSize+game.pixelPadding)+game.pixelPadding
	--	)

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
	--love.graphics.push()
	--love.graphics.translate(unpack(game.position))
	bloom:predraw()
    bloom:enabledrawtobloom()
    love.graphics.draw(game.canvas)
	bloom:postdraw()
	love.graphics.draw(game.canvas)
	--love.graphics.pop()
end

game.pixelColor={
	{250,155,155,255},
	{155,250,155,255},
	{155,155,250,255}
}



function game.createObject(x,y)
	local t=love.math.random(1,7)
	local grid=matrixCopy(game.targetGrid[love.math.random(1,7)])
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

	return {
		grid=mat,
		x=5,
		y=0,
	}
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
	local ox,oy=math.floor(obj.x),math.floor(obj.y)
	for y=1,#obj.grid do
		for x=1,#obj.grid[y] do
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


function love.keypressed(key)

	if key=="w" then
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

	if key=="e" then
		game.matrixClear()
		game.objectTurn(game.obj,true)
		if game.objectCollideTest(game.obj) ~=0 then
			--game.matrixClear()
			game.objectTurn(game.obj,true)
		end
		game.objectSetMatrix(game.obj)
	end

	if key=="a" then
		game.matrixClear()
		game.obj.x=game.obj.x-1
		if game.objectCollideTest(game.obj) ~=0 then
			game.obj.x=game.obj.x+1
		end
		game.objectSetMatrix(game.obj)
	end

	if key=="d" then
		game.matrixClear()
		game.obj.x=game.obj.x+1
		if game.objectCollideTest(game.obj) ~=0 then
			game.obj.x=game.obj.x-1
		end
		game.objectSetMatrix(game.obj)
	end

	if key=="s" or key=="space" then
		game.falling = true
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
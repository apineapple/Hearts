local playermarker="Ben"
local lg = love.graphics
local socket = require("socket")
local http = require("socket.http")
local url = require("socket.url")
local is_host = false
local is_client = false
local server = nil
local client = nil
local clients = {}



function love.load()
    --[[
    if not io.open("heartsave.txt", "r") then
        file=io.open("heartsave.txt", "w")
        if file then
            file:write("1")
        else
        end
        file:close()
    end--]]

    lg.setLineWidth(4)
    ft = "Daydream.ttf"
    font = lg.newFont(ft,30)
    fonthov = lg.newFont(ft,34)
    bigfont = lg.newFont(ft,60)
    font:setFilter("nearest", "nearest")
    fonthov:setFilter("nearest", "nearest")
    bigfont:setFilter("nearest", "nearest")
    
    textWidth = function(txt) return (lg.getWidth()-lg.getFont():getWidth(txt))/2 end
    lg.setFont(font)
    themes={
        {
            "Basic",
            {250/255, 226/255, 235/255},
            {255/255, 202/255, 229/255},
            {255/255, 119/255, 188/255},
            {76/255, 69/255, 76/255},
            {1,1,1}
        },
        {
            "Dark",
            {250/255, 226/255, 235/255}, --invalid
            {76/255, 69/255, 76/255}, --background
            {255/255, 119/255, 188/255}, --red
            {0,0,0}, --black
            {1,1,1} --highlight
        },
    }
    themeid=2
    themename = themes[themeid][1]
    invalid = themes[themeid][2]
    background = themes[themeid][3]
    backgroundfaded = {themes[themeid][3][1],themes[themeid][3][2],themes[themeid][3][3],.2}
    red = themes[themeid][4]
    black = themes[themeid][5]
    highlight = themes[themeid][6]
   
    --default card settings
    hw = 120
    hh = 150
    numname = {"2","3","4","5","6","7","8","9","10","J","Q","K","A"}
    suiticon = {lg.newImage("club.png"),lg.newImage("diamond.png"),lg.newImage("spade.png"),lg.newImage("heart.png")}

    mode = "title"
    myname=""
    hdrag = {}
    allswap={}
    hovercard=0
    wait=0
end

function love.update()
    love.window.setFullscreen(true, "desktop")
    if is_host and server then hosting() end
    if is_client and client then clienting() end

    if mode == "play" then
        if #round==pnum then
            if wait<120 then
                wait=wait+1
            else
                tally()
            end
        elseif er then
            endGame()
        elseif swapnum==pnum and turn==mynum then
            for i = 1, #player[mynum].hand do
                if legal(x,y,i) then
                    cardx = getCardX(i)
                    cardy = getCardY(i)
                    hdrag={i, cardx, cardy}
                    client:send("card"..mynum..","..hdrag[1]..","..hdrag[2]..","..hdrag[3].. "\n")
                    moved()
                    break
                end
            end
            hdrag={}
        end
    end
end

function love.draw()
    lg.clear(background)
    if mode=="title" then
        headertxt("hearts")
        menutxt("host",1)
        menutxt("join",2)
        menutxt("options",3)
        menutxt("quit",4)
    elseif mode=="lobby" then
        menutxt("#: "..code.."  ("..pnum.." of 5)",-2,nil,true)
        if ruleset then
            menutxt("jack: ",1,jack)
            menutxt("round scores: ",2,"show")
        elseif is_host then
            menutxt("name: ",0,myname)
            menutxt("rules",1)
            menutxt("start",2)
        end
        menutxt("back",4)
    elseif mode=="join" then
        menutxt("#: ",-2,code)

        menutxt("join",2,nil)
        menutxt("back",4)
    elseif mode=="options" then
        menutxt("theme: ",1,themename)
        menutxt("stats",2)
        menutxt("back",4)
    elseif mode=="play" then
        lg.setFont(font)
        playertxt(mynum,textWidth("my score: "..player[mynum].score.." ("..player[mynum].rscore..")"),lg.getHeight()-250)
        --if pnum==3 then
            --playertxt(mynum%pnum+1,50,150)
            --playertxt((mynum+1)%pnum+1,lg.getWidth()-lg.getFont():getWidth(player[(mynum+1)%pnum+1].name..": "..player[(mynum+1)%pnum+1].score.." ("..player[(mynum+1)%pnum+1].rscore..")")-50,150)
        if pnum==4 then
            playertxt(mynum%pnum+1,50,250)
            playertxt((mynum+1)%pnum+1,textWidth(player[(mynum+1)%pnum+1].name..": "..player[(mynum+1)%pnum+1].score.." ("..player[(mynum+1)%pnum+1].rscore..")"),50)
            playertxt((mynum+2)%pnum+1,lg.getWidth()-lg.getFont():getWidth(player[(mynum+2)%pnum+1].name..": "..player[(mynum+2)%pnum+1].score.." ("..player[(mynum+2)%pnum+1].rscore..")")-50,250)
        elseif pnum==5 then
            playertxt(mynum%pnum+1,50,250)
            playertxt((mynum+1)%pnum+1,textWidth("my score: "..player[(mynum+1)%pnum+1].score.." ("..player[(mynum+1)%pnum+1].rscore..")")-400,50)
            playertxt((mynum+2)%pnum+1,textWidth("my score: "..player[(mynum+2)%pnum+1].score.." ("..player[(mynum+2)%pnum+1].rscore..")")+400,50)
            playertxt((mynum+3)%pnum+1,lg.getWidth()-lg.getFont():getWidth(player[(mynum+3)%pnum+1].name..": "..player[(mynum+3)%pnum+1].score.." ("..player[(mynum+3)%pnum+1].rscore..")")-50,250)
        end

        for i = 1, #player[mynum].hand do drawCard(player[mynum].hand[i][1],player[mynum].hand[i][2],i) end
        --error here on line below or above?
        for i = 1,#round do drawCard(round[i][1],round[i][2],round[i][3],true) end

        if swapnum<pnum then
            if roundsplayed%4==0 then
                menutxt("pass to the left",-2,nil)
            elseif roundsplayed%4==1 then
                menutxt("pass to the right",-2,nil)
            elseif roundsplayed%4==2 and pnum==4 then
                menutxt("pass across",-2,nil)
            end
            for i=1,#myswap do
                --double check i as value
                drawCard(myswap[i][2],myswap[i][3],i,"swap")
            end
        end
        lg.setFont(fonthov)  
        --nil value below???
        if #hdrag>0 then drawCard(player[mynum].hand[hdrag[1]][1],player[mynum].hand[hdrag[1]][2],hdrag[1]) end
        --nil value below???
        if hovercard>0 then drawCard(player[mynum].hand[hovercard][1],player[mynum].hand[hovercard][2],hovercard) end

        if mynum==moon then
            menutxt("you shot the moon!",0,nil)
            menutxt("lose points",1,nil)
            menutxt("give others points",2,nil)
        end
        if mynum~=turn and swapnum==pnum then
            lg.setColor(backgroundfaded)
            lg.rectangle("fill", 0, 0, lg.getWidth(),lg.getHeight())
        end
    end
end

function headertxt(txt)
    lg.setColor(black)
    lg.setFont(bigfont)
    lg.print(txt, textWidth(txt)-6, lg.getHeight()/4)
    lg.setColor(red)
    lg.print(txt, textWidth(txt), lg.getHeight()/4-7)
end

function menutxt(txt,i,toggle,two)
    toggle=toggle or ""

    lg.setFont(menuhov==i and fonthov or font)   
    lg.setColor(menuhov==i and not two and red or black)
    lg.setColor(menuhov==i and not two and red or black)
    lg.print(not two and txt..toggle or txt, textWidth(txt..toggle)-4, lg.getHeight()/4+221+80*i)
    lg.setColor(menuhov==i and not two and highlight or red)
    lg.print(not two and txt..toggle or txt, textWidth(txt..toggle), lg.getHeight()/4+215+80*i)

    if toggle ~= "" and not two then 
        menutxt(txt,i,toggle,true)
    end
end

function playertxt(id,x,y)
    if player[id].name then
        lg.setColor(red)
        lg.print(player[id].name..": "..player[id].score.." ("..player[id].rscore..")",x,y)
        lg.setColor((swapnum==pnum and turn==id) and highlight or black)
        lg.print(player[id].name..": "..player[id].score,x,y)
    end
end

function playerPlacement()
    places={}
    while #places<pnum do
        pid = math.random(pnum)
        used=false
        for i=1,#places do
            if places[i]==pid then
                used=true
            end
        end
        if not used then
            table.insert(places,pid)
            clients[#places]:send("seed"..pid..","..seed..","..jack.."\n")
        end
    end
end

function startRound()
    local deck = {}
    heartsbroken = false
    moon=0
    round={}
    myswap={}
    given={}
    if (pnum==4 and roundsplayed%4==3) or (pnum==5 and roundsplayed%3==2) then
        swapnum=pnum
    else
        swapnum=0
    end
    
    for i = 1, 4 do
        for j = 1, 13 do
            table.insert(deck, {j,i})
        end
    end   

    for i = 1, pnum do
        player[i]={score=player[i].score or 0, rscore=0, hand={}, suits={0,0,0,0},name=player[i].name or "player"..i}
        for j = 1, math.floor(52/pnum) do
            n = math.random(#deck)
            if ((pnum~=5 and deck[n][1]==1) or (pnum==5 and deck[n][1]==2)) and deck[n][2]==1 then turn=i end
            player[i].suits[deck[n][2]]=player[i].suits[deck[n][2]]+1
            if not ((pnum==3 or pnum==5) and deck[n][1]==1 and deck[n][2]==2) or not (pnum==5 and deck[n][1]==1 and deck[n][2]==1) then
                table.insert(player[i].hand, deck[n])
            end
            table.remove(deck, n)
        end
        table.sort(player[i].hand, function(a, b)
            if a[2] == b[2] then
                return a[1] < b[1] 
            end
            return a[2] < b[2]
        end)
    end
end

function moved()
    if player[turn].hand[hdrag[1]][2] == 4 then heartsbroken = true end
    --player[turn].name="aaa "..player[turn].suits[player[turn].hand[hdrag[1]][2]]
    table.insert(round,{player[turn].hand[hdrag[1]][1],player[turn].hand[hdrag[1]][2],turn})
    player[turn].suits[player[turn].hand[hdrag[1]][2]] = player[turn].suits[player[turn].hand[hdrag[1]][2]] - 1
    table.remove(player[turn].hand,hdrag[1])
    if #round<pnum then turn=turn % pnum + 1 end
    hdrag={}
end

function drawCard(num, suit, i, played)
    cardhov =  not played and (i==hovercard or (#hdrag~=0 and hdrag[1] == i)) and -20 or 0
    cardx = getCardX(i, played)
    cardy = getCardY(i, played)
    black[4]=0.5
    lg.setColor(black)
    if not played and ((#hdrag>0 and i == hdrag[1]) or cardhov~=0) then
        lg.rectangle("fill", cardx-10, cardy+5, hw, hh+10,10,10)
    else
        lg.rectangle("fill", cardx-5, cardy+cardhov, hw, hh+8,10,10)
    end
    black[4]=1


    --legal double check!!
    if swapnum<pnum or played or legal(x,y,i)  then
        lg.setColor(highlight)
    else
        lg.setColor(invalid)
    end

    for j=1,#given do
        if given[j][1]==num and given[j][2]==suit then
            lg.setColor(background)
        end
    end

    lg.rectangle("fill", cardx, cardy+cardhov, hw, hh,10,10)
    --lg.rectangle("line",cardx, cardy, hw, hh,10,10)
    if suit%2==0 then lg.setColor(red) else lg.setColor(black) end
    lg.print(numname[num], cardx+20-6*#numname[num], cardy+10+cardhov)
    lg.print(numname[num], cardx+hw-35-10*#numname[num], cardy+hh-48+cardhov)
    lg.setColor(highlight)
    lg.draw(suiticon[suit],cardx+30, cardy+40+cardhov)
    --lg.print(, cardx+40, cardy+58+cardhov)
end

function getCardX(i,played)
    xcenter = (lg.getWidth()-hw)/2

    if played then
        if played=="swap" then
            if pnum==4 then 
                if i==1 then 
                    xcenter=xcenter-200
                elseif i==2 then
                    xcenter=xcenter
                elseif i==3 then
                    xcenter=xcenter+200
                end
            elseif pnum==5 then
                if i==1 then 
                    xcenter=xcenter-100
                elseif i==2 then
                    xcenter=xcenter+100
                end
            end
        else
            --if pnum==3 then
                --xcenter =  i==mynum and xcenter or i==(mynum)%pnum+1 and xcenter-100 or i==(mynum+1)%pnum+1 and xcenter+100
            if pnum==4 then
                xcenter =  i==mynum and xcenter or i==mynum%pnum+1 and xcenter-100 or  i==(mynum+1)%pnum+1 and xcenter or i==(mynum+2)%pnum+1 and xcenter+100
            elseif pnum==5 then
                xcenter = i==mynum and xcenter or i==mynum%pnum+1 and xcenter-200 or i==(mynum+1)%pnum+1 and xcenter-100 or  i==(mynum+2)%pnum+1 and xcenter+100 or  i==(mynum+3)%pnum+1 and xcenter+200 
            --elseif pnum==6 then
                --xcenter = i==mynum and xcenter or i==mynum%pnum+1 and xcenter-200 or i==mynum%pnum+2 and xcenter-100 or i==mynum%pnum+3 and xcenter or i==mynum%pnum+4 and xcenter+100 or i==mynum%pnum+5 and xcenter+200 
            end
        end
    end

    handsize = lg.getWidth()/2 - #player[mynum].hand*(hw-40)/2 -80
    return played and xcenter or hdrag[1]==i and hdrag[2] or handsize+i*(hw-40)
end

function getCardY(i,played)
    ycenter = (lg.getHeight()-hh)/2
    if played then
        if i==mynum or played=="swap" then
            ycenter=ycenter+50
        else
            --if pnum==3 then
            --ycenter = ycenter-150
            if pnum==4 then
                ycenter =  i==(mynum+1)%pnum+1 and ycenter-150 or ycenter-50
            elseif pnum==5 then
                ycenter = (i==(mynum+1)%pnum+1 or  i==(mynum+2)%pnum+1) and ycenter-150
            --elseif pnum==6 then
                --ycenter = (i==mynum%pnum+2 or i==mynum%pnum+4) and ycenter-100 or i==mynum%pnum+3 and ycenter-200 or ycenter
            end
        end
    end

    return played and ycenter or hdrag[1]==i and hdrag[3] or lg.getHeight()-180
end

function legal(x,y,i)
    clubs2=#player[mynum].hand==math.floor(52/pnum) and player[mynum].hand[i][2]==1 and ((pnum~=5 and player[mynum].hand[i][1]==1) or (pnum==5 and player[mynum].hand[i][1]==2))
    playhearts= #player[mynum].hand<math.floor(52/pnum) and (heartsbroken or player[mynum].hand[i][2]~=4 or (player[mynum].suits[1]<1 and player[mynum].suits[2]<1 and player[mynum].suits[3]<1))
    startround= #round==0 and (clubs2 or playhearts)
    --nil value line below??
    playround=#round>0 and (player[mynum].suits[round[1][2]]<1 or player[mynum].hand[i][2]==round[1][2])
    return startround or playround
end

function oncard(x,y,i)
    return x >= cardx and x <= cardx+hw and y >= lg.getHeight()-150  and y <= lg.getHeight()-150 + hh
end

function tally()
    wonround=1
    points = 0
    for i=1,pnum do
        if round[i][2]==4 then points=points+1 end
        if jack=="yes" and round[i][2]==2 and round[i][1]==10 then points=points-10 end
        if round[i][2]==3 and round[i][1]==11 then points=points+13 end
        if round[i][2]==round[1][2] and round[i][1]>round[wonround][1] then wonround=i end
    end
    wonround=round[wonround][3]
    player[wonround].rscore = player[wonround].rscore + points

    turn=wonround 
    roundsplayed=roundsplayed+1
    wait=0
    round={}
    if #player[mynum].hand==0 then 
        shot=""
        moon=0
        sun=0
        oneplayer=true
        for i=1,pnum do
            if player[i].rscore==26 then 
                moon=i 
            elseif player[wonround].rscore==16 and oneplayer then 
                moon=i
                sun=13
            elseif player[wonround].rscore>0 then
                oneplayer=false
                moon=0
                sun=0
            end
        end
        er=true 
    end

end

function endGame()
    if moon==mynum and shot~="" then
        client:send("moon"..mynum..","..shot .."\n")
    elseif moon==0 then
        over=false
        for i=1,pnum do
            player[i].score=player[i].score+player[i].rscore
            if player[i].score>=100 then over=true end
        end
        if not over then
            startRound()
        end
        er=false
    end
end

function strtbl(str)
    local newtbl = {}
    for item in string.gmatch(str, '([^,]+)') do
        item = tonumber(item) or item
        table.insert(newtbl, item)
    end
    return newtbl
end

function love.mousepressed(x, y, button, istouch, presses)
    if menuhov==4 and mode~="title" then
        if ruleset then
            ruleset=nil
        else
            mode="title"
            if is_host then 
                clients = {}
                server:close()
                server = nil
                is_host = false
            elseif is_client then
                client:close()
                client = nil
                is_client = false
            end
        end
    elseif mode=="title" then
        pnum=0
        if menuhov==1 then
            jack="no"
            mode="lobby"
            startServer()
        elseif menuhov==2 then
            mode="join"
            code=""
        elseif menuhov==3 then
            mode="options"
        elseif menuhov==4 then
            love.event.quit()
        end
    elseif mode=="lobby" and is_host then
        if menuhov==2 and pnum>3 then
            playerPlacement()
        elseif menuhov==1 then
            if ruleset then
                if jack == "yes" then
                    jack="no"
                else
                    jack="yes"
                end
            else
                ruleset=true
            end
        end
    elseif mode=="join" then
        if menuhov==2 then
            joinServer()
            if is_client then mode="lobby" end
        end
    elseif mode=="options" then
        if menuhov==1 then
            themeid=themeid%#themes+1
            themename = themes[themeid][1]
            invalid = themes[themeid][2]
            background = themes[themeid][3]
            backgroundfaded = {themes[themeid][3][1],themes[themeid][3][2],themes[themeid][3][3],.2}
            red = themes[themeid][4]
            black = themes[themeid][5]
            highlight = themes[themeid][6]
        elseif menuhov==2 then
            mode="stats"
        end
    elseif mode=="play" then
        if mynum==moon then
            if menuhov==1 then
                shot=-26-sun
            elseif menuhov==2 then
                shot=26+sun
            end
        end

        for i = 1, #player[mynum].hand do
            cardx = getCardX(i)
            cardy = getCardY(i)
            if hovercard==i then
                hdrag={i, cardx, cardy}
                hovercard=0
                break
            end
        end
    end
end

function love.mousemoved(x, y, dx, dy, istouch)
    if mode ~= "play" then
        menuhov=-5
        if x>lg.getWidth()/2-260 and x< lg.getWidth()/2+260  then
            for i=1,5 do
                if y>lg.getHeight()/4+220+80*i and y<lg.getHeight()/4+220+110*i then
                    menuhov=i 
                end
            end
        end
    else
        if #hdrag > 0 then
            hdrag[2] = hdrag[2]+dx
            hdrag[3] = hdrag[3]+dy
        else
            nohov = true
            for i = 1, #player[mynum].hand do
                cardx = getCardX(i)
                cardy = getCardY(i)
                if oncard(x,y,i) then
                    hovercard = i
                    nohov = false
                    break
                end
            end
            if nohov then hovercard = 0 end
        end
    end
end

function love.mousereleased(x, y, button, istouch, presses)
    if mode=="play" then
        if #hdrag ~= 0 and wait==0 and hdrag[3] < 2*lg.getHeight()/3 then
            if swapnum<pnum and (pnum==4 and #myswap<3) or (pnum==5 and #myswap<2) then 
                player[mynum].suits[player[mynum].hand[hdrag[1]][2]] = player[mynum].suits[player[mynum].hand[hdrag[1]][2]] - 1
                table.insert(myswap, {hdrag[1],player[mynum].hand[hdrag[1]][1],player[mynum].hand[hdrag[1]][2]})
                table.remove(player[mynum].hand,hdrag[1])
                if (pnum==4 and #myswap==3) or (pnum==5 and #myswap==2) then  
                    if roundsplayed%4==0 then
                        reciever=mynum%pnum+1
                    elseif roundsplayed%4==1 then
                        reciever=(mynum-2)%pnum+1
                    elseif roundsplayed%4==2 then
                        reciever=(mynum+1)%pnum+1
                    end
                    swapstr="swap"..mynum..","..reciever
                    for i=1,#myswap do
                        swapstr=swapstr..","..myswap[i][1]..","..myswap[i][2]..","..myswap[i][3]
                    end
                    swapstr=swapstr..","
                    client:send(swapstr.."\n")
                end
            elseif turn==mynum and legal(x,y,hdrag[1]) then
                client:send("card"..mynum..","..hdrag[1]..","..hdrag[2]..","..hdrag[3].. "\n")
                moved()
            end
        end
        hdrag={}
    end
end

function love.textinput(text)
    if mode=="join" and #code<3 and type(tonumber(text))=="number" then
        menuhov=0
        code=code..text
    elseif mode=="lobby" and #myname<10  then
        menuhov=0
        myname= myname and myname..text or text
    end
end

function love.keypressed(key)
    if mode=="join" then
        if key == 'backspace' then code = code:sub(1,-2) end
    elseif mode=="lobby" and #myname>0 then
        if key == 'backspace' then myname = myname:sub(1,-2) end
        menuhov=0
    end
end

function startServer()
    local udp = socket.udp()
    udp:setpeername("8.8.8.8", 80)
    local ip, _ = udp:getsockname()
    udp:close()

    seed=os.time()
    math.randomseed(seed)
    is_host = true
    code=""
    for i=1,3 do
        code=code..tostring(math.random(9))
    end
    port=tonumber("1"..code)

    --server = socket.bind("*", 12345)
    server = socket.bind("*", port)
    server:settimeout(0)
    local host_url = "https://thrilling-knowing-adjustment.glitch.me/ping?ip=" .. url.escape(ip) .. "&code=" .. url.escape(code)
    response,_ = http.request(host_url)
    if response then
        joinServer()
    end
end

function joinServer()  
    local client_url = "https://thrilling-knowing-adjustment.glitch.me/ping?code=" .. url.escape(code)
    host_ip,status = http.request(client_url)
    if not host_ip or status ~= 200 then
        return false
    end

    is_client = true
    ping=0
    client = socket.tcp()
    client:settimeout(5)
    port=tonumber("1"..code)
    local success, err = client:connect(host_ip, port)
    if success then
    client:settimeout(0)
    else
        is_client = false
    end
end

function hosting()
    --add self to client list
    broadcast("ping") 
    local new_client = server:accept()
    if new_client and pnum<5 and mode=="lobby" then
        new_client:settimeout(0)
        table.insert(clients, new_client)
        pnum = pnum + 1
        broadcast("pnum"..pnum) 
    end
    -- Check for disconnected clients
    for i, client in ipairs(clients) do
        local message, err = client:receive()
        if message then
            message=message:sub(1, -2)
            broadcast(message)
        elseif err == "closed" then
            table.remove(clients, i)
            pnum = pnum - 1
            broadcast("pnum"..pnum)
        end
    end
end

function clienting()
    ping=ping+1
    if ping>300 then
        client:close()
        client = nil
        is_client = false
        mode="title"
        return
    end
    local response, err = client:receive()
    if response then
        if response:match("ping") then
            ping=0
        elseif response:match("^pnum") then
            pnum = tonumber(response:sub(5))
        elseif response:match("^name") then
            newname=strtbl(response:sub(5))
            if newname[2]=="" or newname[2]==nil then
                player[newname[1]].name="player "..newname[1]
            else
                player[newname[1]].name=newname[2]
            end
        elseif response:match("^swap") then
            table.insert(allswap,strtbl(response:sub(5)))
            --strtbl(response:sub(5)) is {sender,reciever,id1,num1,suit1,id2,num2,suit2}
            given={}
            swapnum=swapnum+1
            if #allswap==pnum then
                for i=1,#allswap do
                    for j=3,#allswap[i],3 do
                        if allswap[i][1]~=mynum then
                            table.remove(player[allswap[i][1]].hand,allswap[i][j])
                        end
                    end
                    for j=3,#allswap[i],3 do
                        player[allswap[i][2]].suits[allswap[i][j+2]] = player[allswap[i][2]].suits[allswap[i][j+2]] + 1
                        table.insert(player[allswap[i][2]].hand,{allswap[i][j+1],allswap[i][j+2]})
                        if (allswap[i][2]==mynum) then
                            table.insert(given,{allswap[i][j+1],allswap[i][j+2]})
                        end
                        if ((pnum~=5 and allswap[i][j+1]==1) or (pnum==5 and allswap[i][j+1]==2)) and allswap[i][j+2]==1 then turn=allswap[i][2] end
                    end
                end
                for i=1,pnum do
                    table.sort(player[i].hand, function(a, b)
                        if a[2] == b[2] then
                            return a[1] < b[1] 
                        end
                        return a[2] < b[2]
                    end)
                end
                allswap={}
                myswap={}
            end
            
        elseif response:match("^seed") then
            setup = strtbl(response:sub(5))
            mynum=setup[1]
            seed=setup[2]
            jack=setup[3]
            player = {}
            for i = 1, pnum do
                table.insert(player, {score=0, rscore=0, hand={}, suits={},name="player "..i})
            end
            roundsplayed=0
            client:send("name"..mynum..","..myname.."#\n")
            math.randomseed(seed)
            startRound()
            mode="play"
        elseif response:match("^card") then
            hdrag=strtbl(response:sub(5))
            if hdrag[1]~=mynum then
                table.remove(hdrag,1)
                moved()
            end
            hdrag={}
        elseif response:match("^moon") then
            moon,shot=tonum(strtbl(response:sub(5)))
            if shot<0 then
                player[moon].score=player[moon].score+shot
            else
                for i=1,pnum do
                    if i~=moon then
                        player[i].score=player[i].score+shot
                    end
                end
            end
            moon=0
        end
    end
end

function broadcast(message)
    for _, client in pairs(clients) do
        client:send(message .. "\n")
    end
end
local features={}
local X_train={}
local y={}
priori={}
local bgCompanent
local bgGrp
local bg
local txt
local labels
local ngroup
local saveScreenOpened=false
local widget=require "widget"
local isVowel=function(char)
	local vowels={"a","e","i","ı","o","ö","u","ü"}
	for i=1,#vowels do
		if char==vowels[i] then return true
		end
	end
	return false
end
local openDb=function()
	local  sql=require "sqlite3"
	local db=sql.open(system.pathForFile("mjnius.db",system.DocumentsDirectory))
	return db

end
local loadDataFromDB=function()
	local db=openDb()
	local str=[[SELECT id,name,genre FROM names]]
	for row in db:nrows(str) do
		local name,genre=row.name,row.genre
		table.insert(features,{name=name,genre=genre})

	end

end

local createTable=function()
	local  sql=require "sqlite3"
	local db=sql.open(system.pathForFile("mjnius.db",system.DocumentsDirectory))
	local tbl=[[CREATE TABLE IF NOT EXISTS names(id INTEGER PRIMARY KEY,name TEXT,genre TEXT);]]
	db:exec(tbl)
	local M={
	{name="yahya",genre="e"},
	{name="zeynep",genre="k"},
	{name="ali",genre="e"},
	{name="feyyaz",genre="e"},
	{name="sıla",genre="k"},
	{name="feyza",genre="k"},
	{name="selim",genre="e"},
	{name="selçuk",genre="e"},
	{name="şeyma",genre="k"},
	{name="şule",genre="k"},
	{name="müge",genre="k"},
	{name="ahmet",genre="e"},
	{name="hasan",genre="e"},
	{name="cihat",genre="e"},
	{name="simge",genre="k"},
	{name="selma",genre="e"}
	}
	local count=0
	for k in db:nrows("SELECT id FROM names") do
		count=count+1
	end
	print(count)
	if count<1 then		
		for k=1,#M do
			local str=[[INSERT INTO names VALUES(NULL,']]..M[k].name..[[',']]..M[k].genre..[[');]]
			db:exec(str)

		end
		timer.performWithDelay(1000,loadDataFromDB,1)
	else
		loadDataFromDB()

	end




end
local loaderScreen=function()
	local str=display.newText("Sistem Hazırlanana Kadar Bekleyin...",display.contentCenterX,
		display.contentCenterY,nil,17)
	str:setFillColor(1,0,1)
	return str


end

local stringToFeature=function(str)
	local name=string.lower(str)
	local len=string.len(name)
	local fname=string.sub(name,1,1)
	local ort=0
	if len%2==0 then 
		ort=len/2
	else
		ort=len/2
		ort=math.ceil(ort)
	end
	local oname=string.sub(name,ort,ort)		
	local lname=string.sub(name,len)
	local vowel=isVowel(lname)
	return fname,oname,lname,vowel


end
--[[local readDoc=function(docname)
	local path=system.pathForFile(docname)
	local fh,error=io.open(path,"r+")
	if not fh then 
		native.showAlert("MJnius Uyarı","Sistem I/O Hatası verdi!",{"Tamam"})
	else
		for line in fh:lines() do
			line=string.lower(line)
			local init=string.find(line,",")
			local name=string.sub(line,0,init-1)			
			local genre=string.sub(line,init+1)
			table.insert(features,{name=name,genre=genre})

		end
	end
	
end]]--

local getFeatures=function()
	for k,feature in pairs(features) do
		local name=feature.name
		local genre=feature.genre
		local len=string.len(name)
		local fname=string.sub(name,1,1)
		local ort=0
		if len%2==0 then 
			ort=len/2
		else
			ort=len/2
			ort=math.ceil(ort)
		end
		local oname=string.sub(name,ort,ort)		
		local lname=string.sub(name,len)
		local vowel=isVowel(lname)
		table.insert(X_train,{firstname=fname,halfname=oname,lastname=lname,vowel=vowel})
		table.insert(y,{target=genre})
	end

end
local calculatePriori=function(genre)
	local count=0
	local total=#y
	for k=1,total do
		if y[k].target==genre then
			count=count+1
		end
	end
	local pisterior=count/total
	table.insert(priori,{tgt=genre,genre=pisterior})


end
--target erkek veya kız
--attr firstname 'y'
--attr_type gelen verinin harfi 'c'
local getCoditionalProbability=function(attr_type,attr,tgt)
	local count=.1
	local total=.1
	for k=1,#y do
		if X_train[k][attr_type]==attr and y[k].target==tgt then
			count=count+1
		end
		if X_train[k][attr_type]==attr then
			total=total+1
		end

	end
	return count/total


end
--test
--cem --> c,e,m,false
--fistname,halfname,lastname,vowel
---c e m false
---
local train=function(x_test,labels)
	local probs={}
	local toMultiplied={}
	local proba=1
	for i=1,#labels do
		for k,v in pairs(x_test) do
			proba=proba*getCoditionalProbability(k,v,labels[i])
		end
		table.insert(probs,{genre=labels[i],prob=proba})
		proba=1
	end
	return probs
end
local calculateNaiveBayes=function(probs)
	local _probs={}
	for i=1,#priori do
		for j=1,#probs do
			if probs[j].genre==priori[i].tgt then				
					local lprob=probs[j].prob*priori[i].genre
					local genre=probs[j].genre
					table.insert(_probs,{genre=genre,prob=lprob})
			end

		end

	end
	return _probs

end
local tableContains=function(tables,element)
	for i=1,#tables do
		if tables[i]==element then return true end
	end
	return false

end
local getLabels=function()
	local tgts={}
	for i=1,#y do
		if not tableContains(tgts,y[i].target) then table.insert(tgts,y[i].target) end

	end
	return tgts

end
local argMax=function(probs)
		local max=-3
		local indx=-1
		for k=1,#probs do
			if probs[k].prob>max then max=probs[k].prob;indx =k end
		end
		return probs[indx].genre,probs[indx].prob

end
local predict=function(targetName)
	local fname,hname,lname,vowel=stringToFeature(targetName)
	local x_test={firstname=fname,halfname=hname,lastname=lname,vowel=vowel}
	local probs=train(x_test,labels)
	_probs=calculateNaiveBayes(probs)
	local genre,prob=argMax(_probs)
	return genre
end
local function goAndFind(e)
	if e.phase=="submitted" then
		local name=e.target.text
		local genre=predict(name)
		local gen={e="Bay",k="Bayan"}
		native.showAlert("MJnuis Pencere","Cinsiyetiniz ==="..tostring(gen[genre]).." === Olarak bulunmuştur!",{"Tamam"})
	end
	
end
local guiListener=function(e)
	if e.numTaps<2 then return end
	transition.to(bgGrp,{time=400,y=-300,onComplete=function() 
		display.remove(bgGrp)
		bgGrp=nil
		display.remove(bgCompanent)
		bgCompanent=nil
		end})
	return true
end
local function enterPop(e)
	if saveScreenOpened then return end
	if bgGrp==nil then
		bgGrp=display.newGroup()
		bgGrp.x=display.contentCenterX
		bgGrp.y=-300
		bg=display.newRoundedRect(0,0,display.contentWidth*0.8,display.contentHeight*0.5,10)
		bg:setFillColor(0,1,1)
		local tt=display.newText("Arkadaşının Adını Gir",0,0,200,100,nil,16)
		tt:setFillColor(.5,0.5,0.5)
		txt=native.newTextField(0,20,150,30)
		txt:addEventListener("userInput",goAndFind)
		bgGrp:insert(bg)
		bgGrp:insert(tt)
		bgGrp:insert(txt)	
		transition.to(bgGrp,{time=400,y=display.contentCenterY,onComplete=function()  
			timer.performWithDelay(1000,function() 
				if bgCompanent==nil then
				bgCompanent=display.newRect(0,0,display.contentWidth,display.contentHeight)
				bgCompanent:setFillColor(0,0,0)
				bgCompanent.x=display.contentCenterX
				bgCompanent.y=display.contentCenterY
				bgCompanent:addEventListener("tap",guiListener) 
				bgCompanent:toBack()
			end

				end,1)

			end})	
	end
end

local newTrain=function(e)
	if bgGrp~=nil then return end
	if saveScreenOpened then return end
	if ngroup~=nil then display.remove(ngroup);ngroup=nil;print("silindi"); end
	saveScreenOpened=true
	ngroup=display.newGroup()	
	local bg=display.newRoundedRect(0,0,display.contentWidth*0.8,display.contentHeight*0.5,10)
	local w,h=bg.width/2,bg.height/2
	bg:setFillColor(0,1,1)
	local etxt=display.newText("İsim",-70,-h+40,100,50,nil,16)
	etxt:setFillColor(1,0,0.5)
	local etbox=native.newTextField(0,-h+60,200,30)
	local gtxt=display.newText("Cinsiyet",-70,-h+100,100,30,nil,16)
	gtxt:setFillColor(1,0,0.5)
	local mtxt=display.newText("Bay ",-70,-h+130,50,30,nil,16)
	local rb1=widget.newSwitch({
		style="radio",
		left=0,top=-h+130,
		id="rb1",initialSwitchState=true
		})
	local ftxt=display.newText("Bayan ",50,-h+130,50,30,nil,16)
	local rb2=widget.newSwitch({
		style="radio",
		left=80,top=-h+130,
		id="rb2"
		})
	local saveData=function(e)		
		if string.len(etbox.text)>2 then
			local name=etbox.text
			local cinsiyet=""
			if rb1.isOn then cinsiyet ="e" elseif rb2.isOn then cinsiyet="f" end
			if cinsiyet=="" then 
				native.showAlert("MJnuis Uyarı!","Cinsiyet Belirleyiniz!",{"Tamam"})
			else
				local insert=[[INSERT INTO names VALUES(NULL,']]..name..[[',']]..cinsiyet..[[');]]
				local db=openDb()
				db:exec(insert)
				native.showAlert("MJnuis Uyarı!","Kayıt Yapıldı!",{"Tamam"})
				local lst=display.newGroup()
				local bs=display.newRect(0,0,display.contentWidth,display.contentHeight)
				bs:setFillColor(0,1,0)	
				bs.x=display.contentCenterX
				bs.y=display.contentCenterY			
				local sv=widget.newScrollView({
					top=0,left=0,
					width=display.contentWidth*0.7,
					height=display.contentHeight*0.9,

					})
				local db=openDb()
				local sql=[[SELECT name from names]]
				local i=2
				local iText=display.newText("Kayıtlı Listesi",sv.x-50,30,120,30,nil,17)
				iText:setFillColor(.7,0.95,0.7)
				sv:insert(iText)
				for d in db:nrows(sql) do
					local ntxt=display.newText(d.name,sv.x-50,i*30,100,30,nil,12)
					ntxt:setFillColor(0,0,0)
					local zebra=display.newRect(sv.x,i*30,sv.width,30)
					if i%2==0 then
						zebra:setFillColor(0.5,0.5,0.5)
					else
						zebra:setFillColor(0,0.5,0.5)
					end
					sv:insert(zebra)
					sv:insert(ntxt)
					i=i+1
				end		
				local hideSavedNames=function(e)
					if lst~=nil then
						transition.to(lst,{time=400,alpha=0,onComplete=function() 
							display.remove(lst)
							lst=nil
							display.remove(bs)
							bs=nil
							end})
					end

				end		
				bs:addEventListener("tap",hideSavedNames)
				lst:insert(sv)
				lst.x=display.contentCenterX-lst.width/2
				lst.y=display.contentCenterY-lst.height/2
				lst:toFront()

			 end
			
	

		else
			native.showAlert("MJnuis Uyarı!","Boş Alan Bırakmayınız!",{"Tamam"})
		end
	end
	local btn=widget.newButton(
	{
	label="Kaydet",
	width=100,height=30,
	left=20,top=-h+190,
	onRelease=saveData

	})
	ngroup:insert(bg)
	ngroup:insert(etxt)
	ngroup:insert(etbox)
	ngroup:insert(gtxt)
	ngroup:insert(mtxt)
	ngroup:insert(rb1)
	ngroup:insert(ftxt)
	ngroup:insert(rb2)
	ngroup:insert(btn)
	ngroup.x=display.contentCenterX
	ngroup.y=display.contentCenterY
	ngroup.alpha=0
	ngroup.y=-400
	transition.to(ngroup,{time=400,alpha=1,y=display.contentCenterY})
	local bg
	local closeSaveScreen=function(e)
		if e.numTaps<2 then return end
		if bg~=nil then
			if ngroup~=nil then
				transition.to(ngroup,{time=400,y=-400,onComplete=function()
				display.remove(ngroup)
				ngroup=nil
				display.remove(bg)
				bg=nil
				saveScreenOpened=false

					end})
				
			end

		end

	return true
	end
	timer.performWithDelay(1000,function()
		bg=display.newRect(0,0,display.contentWidth,display.contentHeight)
		bg.x=display.contentCenterX
		bg.y=display.contentCenterY
		bg:toBack()
		bg:setFillColor(0,0,0)
		bg:addEventListener("tap",closeSaveScreen)

	 end,1)



end
local GUI=function()
	local ng=display.newGroup()
	local header=display.newText("<<Sevdiğin Arkadaşının Adını Yaz\n Cinsiyetini Bulalım.>>",100,100,nil,16)
	header.x=10
	header.y=10
	header:setFillColor(1,0,1)
	local btn=widget.newButton({label="|Giriş|",
		left=10,top=header.y+30,
		onPress=enterPop})
	ng:insert(header)
	ng:insert(btn)
	ng.x=display.contentCenterX
	ng.y=display.contentCenterY
	local addNew=widget.newButton({
		label="|Eğit|",
		onPress=newTrain
		})
	addNew.x=-120
	addNew.y=220
	ng:insert(addNew)

end

if features==nil or #features<1 then
	local ldr=loaderScreen()
	createTable()
	getFeatures()
	timer.performWithDelay(3000,function()
	labels=getLabels()
	for i,j in pairs(labels) do calculatePriori(j) end
	display.remove(ldr)
	GUI()
	 end,1)
end


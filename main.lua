local features={}
local X_train={}
local y={}
priori={}
local bgCompanent
local bgGrp
local bg
local txt
local widget=require "widget"
local isVowel=function(char)
	local vowels={"a","e","i","ı","o","ö","u","ü"}
	for i=1,#vowels do
		if char==vowels[i] then return true
		end
	end
	return false
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
local readDoc=function(docname)
	local path = system.pathForFile(nil, system.ResourceDirectory )
	local fh,error=io.open(path.."/"..docname,"r+")
	if not fh then 
		print("Error occured :"..error)
	else
		for line in fh:lines() do
			line=string.lower(line)
			local init=string.find(line,",")
			local name=string.sub(line,0,init-1)			
			local genre=string.sub(line,init+1)
			table.insert(features,{name=name,genre=genre})

		end
	end
	
end

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
readDoc("names.txt")
getFeatures()
local labels=getLabels()
for i,j in pairs(labels) do calculatePriori(j) end
local predict=function(targetName)
	local fname,hname,lname,vowel=stringToFeature(targetName)
	local x_test={firstname=fname,halfname=hname,lastname=lname,vowel=vowel}
	local probs=train(x_test,labels)
	_probs=calculateNaiveBayes(probs)
	local genre,prob=argMax(_probs)
	return genre
end
local function goAndFind(e)
	if e.phase=="submitted" or e.phase=="ended" then
		local name=e.target.text
		local genre=predict(name)
		local gen={e="Bay",k="Bayan"}
		native.showAlert("TaroApp Pencere","Cinsiyetiniz ==="..gen[genre].." === Olarak bulunmuştur!",{"Tamam"})
	end
	
end
local guiListener=function(e)
	transition.to(bgGrp,{time=400,y=-300,onComplete=function() 
		display.remove(bgGrp)
		bgGrp=nil
		display.remove(bgCompanent)
		bgCompanent=nil
		end})
	return true
end
local function enterPop(e)
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

local GUI=function()
	--bgCompanent:addEventListener("tap",guiListener)
	local ng=display.newGroup()
	local header=display.newText("<<Sevdiğin Arkadaşının Adını Yaz\n Cinsiyetini Bulalım.>>",100,100,nil,16)
	header.x=10
	header.y=10
	header:setFillColor(1,0,1)
	local btn=widget.newButton({label="|Giriş|",
		left=10,top=header.y+30,
		onEvent=enterPop})
	ng:insert(header)
	ng:insert(btn)
	ng.x=display.contentCenterX
	ng.y=display.contentCenterY




end
GUI()

--[[
local test={"cem","yahya","sami","selçuk","elif","elfide","zeynep","sılanur"}
local t={"yahya","ferhan","elfide","sami","zeynep"}
for k,v in pairs(test) do predict(v) end
]]--


pico-8 cartridge // http://www.pico-8.com
version 18
__lua__
--globals--
cash_symbols={}
cash_symbols[1]="\x98"
cash_symbols[2]="\x99"
cash_symbols[3]="\x8e"
cash_symbols[4]="\x85"
cash_money={}
cash_money[1]=32767
cash_money[2]=32767
cash_money[3]=32767
cash_money[4]=0
--[[
 stage 1 = farm
 stage 2 = factoruy
 stage 3 = globe
 stage 4 = galaxy
 stage 5 = universe
]]--
stage=1
known_good_recipes={}

function add_money(value, scale)
 if scale==nil then scale=1 end
 if cash_money[scale]==nil then cash_money[scale]=0 end
 if cash_money[scale]+value < cash_money[scale] then
  cash_money[scale]=32767
 else
  cash_money[scale]+=value
 end
end

function lose_money(value, scale)
 if scale==nil then scale=1 end
 if cash_money[scale]==nil then cash_money[scale]=0 end
 if cash_money[scale]-value < 0 or cash_money[scale]-value > cash_money[scale] then
  cash_money[scale]=0
 else
  cash_money[scale]-=value
 end
end

function can_spend(value, scale)
 if scale==nil then scale=1 end
 if cash_money[scale]==nil then cash_money[scale]=0 end
 if cash_money[scale]-value < 0 or cash_money[scale]-value > cash_money[scale] then
  return false
 else
  return true
 end
end


function _init()
 screen = new_start_screen()
end

function _draw()
 screen:draw()
end

function _update()
 screen:update()
end

-->8
-- screens --
function new_start_screen()
 local s={}
 s.init=function(s)
  s.opts = {"start game", "credits"}
  s.selected=1
  s.is_selected=false
 end

 s.update=function(s)
  if btnp(5) then s.is_selected=true else s.is_selected=false end
  if (btnp(2)) s.selected=max(s.selected-1,1)
  if (btnp(3)) s.selected=min(s.selected+1,#s.opts)

  if s.is_selected then
   if s.selected==1 then
    screen=new_game_screen()
   end
   if s.selected==2 then
    screen=new_credits_screen()
   end
  end
 end

 s.draw=function(s)
  cls()
  for i=1,#s.opts,1 do
   print(s.opts[i], 60, 60+(10*i))
  end
  spr(32,50,60+(10*s.selected))
  print("global jam game", 60, 20)
 end

 s:init()
 return s
end


function new_credits_screen()
 local s={}
 s.init=function(s)
  s.opts={"elyjah 'mr ely' wirth", "robert 'rantingbob' gardner", "mari 'make a jam game?' kyle"}
  s.back=false
 end

 s.update=function(s)
  if btnp(4) then s.back=true else s.back=false end

  if s.back then
   screen=new_start_screen()
  end
 end

 s.draw=function(s)
  cls()
  for i=1,#s.opts,1 do
   print(s.opts[i], (5*i), 60+(10*i))
  end
  print("global jam game", 60, 20)
 end

 s:init()
 return s
end


function new_game_screen()
 local s={}

 s.init=function(s)
  s.draw_systems={}
  s.update_systems={}
  s.scenes={}
  add(s.scenes, new_farm_scene())
  add(s.scenes, new_kitchen_scene())
  add(s.scenes, new_store_scene())
  add(s.scenes, new_hr_scene())
  s.active_scenes={}
  for scene in all(s.scenes) do
   if (scene.unlocked) add(s.active_scenes,scene)
  end
  s.current_scene=1
 end

 s.update=function(s)
  for scene in all(s.scenes) do
   scene:update()
  end
  for sys in all(s.update_systems) do
   sys.update()
  end

  s.active_scenes[s.current_scene].active=false
  if (btnp(0)) then
   s.current_scene=max(s.current_scene-1,1)
   manberry.update_icon()
  end
  if (btnp(1)) then
   s.current_scene=min(s.current_scene+1,#s.active_scenes)
   manberry.update_icon()
  end
  s.active_scenes[s.current_scene].active=true
 end

 s.draw=function(s)
  cls()
  s.active_scenes[s.current_scene]:draw()
  for sys in all(s.draw_systems) do
   sys.draw()
  end
  --draw the transition buttons--
  sspr(s.active_scenes[1].icon.x,s.active_scenes[1].icon.y,32,16,0,104)
  if (s.active_scenes[2]) sspr(s.active_scenes[2].icon.x, s.active_scenes[2].icon.y,32,16,32,104)
  if (s.active_scenes[3]) sspr(s.active_scenes[3].icon.x, s.active_scenes[3].icon.y,32,16,64,104)
  if (s.active_scenes[4]) sspr(s.active_scenes[4].icon.x, s.active_scenes[4].icon.y,32,16,96,104)
  --highlight current button
  local xpos=(s.current_scene-1)*32
  local ypos=104
  rect(xpos-1,ypos,xpos+32,ypos+15,7)

  local dollar_x=0
  for i=1,#cash_money,1 do
   if cash_money[i] > 0 then
    local price=cash_symbols[i]..flr(cash_money[i])
    print(price, dollar_x, 122)
    dollar_x+=(#price*4)+8
   end
  end
 end

 s:init()
 return s
end

-->8
-- hr -- store -- kitchen -- farm--
function new_scene()
 local s={}
 s.active=false
 s.name="scene"
 s.update=function(scene) end
 s.draw=function(scene)
  map(scene.background.x,scene.background.y,0,0,16,16)
 end
 s.unlocked=false
 s.background={
  x=0,
  y=0
 }
 s.icon={
  x=0,
  y=0
 }
 return s
end


function unlock_hr(s)
 s.active_scenes[4]=s.scenes[4]
 s.active_scenes[4].unlocked=true
end

function new_hr_scene()
 local s=new_scene()
 s.name="hr"
 s.background.x=48
 s.unlocked=true
 s.icon.x=88
 s.icon.y=32

 s.available_upgrades={}
 s.purchased_upgrades={}
 s.selected_upgrade=1

 s.update=function(scene)
  check_for_unlocks(scene)

  for upgrade in all(scene.purchased_upgrades) do
   upgrade.update(scene)
  end
  if scene.active and #scene.available_upgrades>0 then
   if btnp(2) then
    scene.selected_upgrade=max(scene.selected_upgrade-1, 1)
   end
   if btnp(3) then
    scene.selected_upgrade=min(scene.selected_upgrade+1, #scene.available_upgrades)
   end

   local selected=scene.available_upgrades[scene.selected_upgrade]
   if btnp(5) and can_spend(selected.price, selected.scale) and selected.quantity < selected.max_quantity then
    if selected.quantity==0 then
     add(s.purchased_upgrades, selected)

    end
    selected.quantity+=1
    selected.on_purchase(scene)
    lose_money(selected.price, selected.scale)
    if selected.quantity == selected.max_quantity then
     del(s.available_upgrades, selected)
     s.selected_upgrade=1
    end
   end
  end
 end

 s.draw=function(scene)
  map(scene.background.x,scene.background.y,0,0,16,16)


  for i=1,#scene.available_upgrades,1 do
   local upgrade = scene.available_upgrades[i]
   local icon=upgrade.icon
   local x_pix=(icon*8)%128
   local y_pix=flr(abs(icon/16))*8
   local x_target=73
   local y_target=8+((i-1)*24)
   local price=cash_symbols[upgrade.scale]..upgrade.price

   sspr(x_pix,y_pix,8,8,x_target,y_target,16,16)
   print(price,x_target,y_target+17)
   if (i==scene.selected_upgrade) rect(x_target-1,y_target-1,x_target+16,y_target+16,7)
  end

 for i=1,#scene.purchased_upgrades,1 do
   local upgrade = scene.purchased_upgrades[i]
   local icon=upgrade.icon
   local x_pix=(icon*8)%128
   local y_pix=flr(abs(icon/16))*8
   local x_target=1
   local y_target=8+((i-1)*18)

   sspr(x_pix,y_pix,8,8,x_target,y_target,16,16)
   print(upgrade.quantity,x_target+17,y_target)
  end

  if #scene.available_upgrades>0 then
   print(scene.available_upgrades[scene.selected_upgrade].name, 0, 1)
   print(scene.available_upgrades[scene.selected_upgrade].description, 0, 96)
  end

 end

 return s
end

function unlock_store(s)
 s.active_scenes[3]=s.scenes[3]
 s.active_scenes[3].unlocked=true
end

function new_store_scene()
 local s=new_scene()
 s.name="store"
 s.background.x=32
 s.unlocked=true
 s.icon.x=56
 s.icon.y=32
granimation=128
granimation_time=0

 s.stock={}
 s.selected_stock=1

 s.update=function(scene)
  --ely futsin here--
  if time() - granimation_time > 1 then
   granimation_time=time()
   granimation+=4
   if granimation>136 then granimation = 128 end
  end
  ----

  --update sale period counters for jams
  for jam in all(scene.stock) do
   if not jam.sale_period_counter then jam.sale_period_counter=0 end
   jam.sale_period_counter+=1/30
   if jam.sale_period_counter > jam_sale_constants.sale_period_length then
    if not jam.demand then jam.demand=1 end
    if not jam.demand_rate then jam.demand_rate=0.01 end
    jam.demand+=jam.demand_rate
    jam.sale_period_counter=0.0
   end
  end
  --stock list selected--
  if scene.active and #scene.stock>0 then
   if btnp(2) then
    scene.selected_stock=max(scene.selected_stock-1, 1)
   end
   if btnp(3) then
    scene.selected_stock=min(scene.selected_stock+1, #scene.stock)
   end
   if btnp(5) and scene.stock[scene.selected_stock].quantity > 0 then
    sold(scene.stock[scene.selected_stock])
   end

  end
 end

 s.draw=function(scene)
  map(scene.background.x,scene.background.y,0,0,16,16)

  --ely futsin here--

  gran_x=20
  gran_y=24
  spr(granimation,gran_x,gran_y,4,4)
  ----

  --draw stock list--
  local column=0
  local row=0
  local page=flr(abs(scene.selected_stock-1)/12)
  local loop_start=(page*12)+1
  local loop_end=min(loop_start+11, #scene.stock)

  for i=loop_start,loop_end,1 do
   local ing=scene.stock[i]
   local icon=ing.icon()
   local x_pix=(icon*8)%128
   local y_pix=flr(abs(icon/16))*8
   local x_target=(8+(column*3))*8
   local y_target=(row*3)*8
   sspr(x_pix,y_pix,8,8,x_target,y_target,16,16)
   print(ing.quantity,x_target,y_target+16)
   column+=1
   column%=3
   if (column==0) row+=1
   if (i==scene.selected_stock) rect(x_target-1,y_target-1,x_target+16,y_target+16,7)
  end

  if #scene.stock > 0 then
   local name=scene.stock[scene.selected_stock].shortname
   local price=cash_symbols[scene.stock[scene.selected_stock].scale]..get_price(scene.stock[scene.selected_stock])
   local demand=""..get_demand(scene.stock[scene.selected_stock]).."*"
   print(name, 0, 1)
   print("sale price:",8,64)
   print(price, 56-(#price*4+4), 72)
   print("demand:",8,80)
   print(demand,56-(#demand*4),88)
  end
 end

 return s
end

function new_farm_scene()
 local s=new_scene()
 s.name="farm"
 s.unlocked=true
 s.icon={
  x=96,
  y=0
 }
 s.bushes={}
 s.planted_bushes={}
 add(s.bushes, strawberry_bush)
 add(s.bushes, blueberry_bush)

 s.selected=1

 s.update=function(scene)
  for bush in all(scene.planted_bushes) do
   bush.harvest_counter+=(1/30)
  end

  if scene.active then
   if btnp(2) then
    scene.selected=max(scene.selected-1, 1)
   end
   if btnp(3) then
    scene.selected=min(scene.selected+1, #scene.bushes)
   end
   if btnp(5) then
    local desired_bush=scene.bushes[scene.selected]
    if can_spend(desired_bush.price, desired_bush.scale) then
     local new_bush={
      x=rnd(16*8),
      y=rnd(4*8)+4*8,
      template=desired_bush,
      harvest_counter=0.0
     }
     add(scene.planted_bushes, new_bush)
     lose_money(desired_bush.price, desired_bush.scale)
     desired_bush.quantity+=1
    end
   end
   if btnp(4) then
    harvest(scene)
   end
  end
 end

 s.draw=function(scene)
  map(scene.background.x,scene.background.y,0,0,16,16)
  column=1
  for i=1,#scene.bushes,1 do
   local ing=scene.bushes[i]
   local icon=ing.icon
   local x_pix=(icon*8)%128
   local y_pix=flr(abs(icon/16))*8
   local x_target=8+((i-1)*(40))
   local y_target=80
   sspr(x_pix,y_pix,8,8,x_target,y_target,16,16)
   print(ing.quantity,x_target+17,y_target+11)
   print(cash_symbols[ing.scale]..ing.price,x_target+17,y_target+2)
   if (i==scene.selected) rect(x_target-1,y_target-1,x_target+16,y_target+16,7)
  end
  column+=1

  for bush in all(scene.planted_bushes) do
   local icon=bush.template.icon
   if (bush.template.harvest_time >= bush.harvest_counter) icon=emptybush_icon
   spr(icon,bush.x,bush.y)
  end

 end

 return s
end

function unlock_kitchen()
 screen.active_scenes[2]=screen.scenes[2]
 screen.active_scenes[2].unlocked=true
end

function new_kitchen_scene()
 local s=new_scene()
 s.name="kitchen"
 s.background.x=16
 s.unlocked=true
 s.icon={
  x=24,
  y=32
 }

 s.process_mix=false
 s.mix_complete=false
 s.mixer_contents={}
 s.available_ingredients={}
 s.selected_ingredient=1

 s.update=function(scene)
  if scene.mix_complete then
   gain_jam(scene.current_output)
   scene.current_output={}
   scene.mixer_contents={}
   scene.mix_complete=false
   scene.process_mix=false
  end

  if scene.process_mix and not scene.mix_complete then
   scene:advance_mix()
  end

  --ingredient list selected--
  if scene.active and #scene.available_ingredients>0 then
   if btnp(2) then
    scene.selected_ingredient=max(scene.selected_ingredient-1, 1)
   end
   if btnp(3) then
    scene.selected_ingredient=min(scene.selected_ingredient+1, #scene.available_ingredients)
   end
   if btnp(5) and #scene.mixer_contents<3 and scene.available_ingredients[scene.selected_ingredient].quantity > 0 then
    add(scene.mixer_contents, scene.available_ingredients[scene.selected_ingredient])
    scene.available_ingredients[scene.selected_ingredient].quantity-=1
   end
   if btnp(4) and #scene.mixer_contents!=0 then
    scene.process_mix=true
    recipe = lookup_recipe(scene.mixer_contents)
    if recipe and recipe.output then scene.current_output=recipe.output else scene.current_output=badjam end
   end
  end
 end

 s.advance_mix=function(scene)
  scene.mix_complete=true
 end

 s.draw=function(scene)
  map(scene.background.x,scene.background.y,0,0,16,16)

  --draw ingredient list--
  local column=0
  local row=0
  local page=flr(abs(scene.selected_ingredient-1)/12)
  local loop_start=(page*12)+1
  local loop_end=min(loop_start+11, #scene.available_ingredients)

  for i=loop_start,loop_end,1 do
   local ing=scene.available_ingredients[i]
   local icon=ing.icon()
   local x_pix=(icon*8)%128
   local y_pix=flr(abs(icon/16))*8
   local x_target=(8+(column*3))*8
   local y_target=(row*3)*8
   sspr(x_pix,y_pix,8,8,x_target,y_target,16,16)
   print(ing.quantity,x_target,y_target+16)
   column+=1
   column%=3
   if (column==0) row+=1
   if (i==scene.selected_ingredient) rect(x_target-1,y_target-1,x_target+16,y_target+16,7)
  end

  --draw mixer--
  if (scene.mixer_contents[1]) spr(scene.mixer_contents[1].icon(),8,8)
  if (scene.mixer_contents[2]) spr(scene.mixer_contents[2].icon(),24,8)
  if (scene.mixer_contents[3]) spr(scene.mixer_contents[3].icon(),40,8)
  if #scene.available_ingredients > 0 then
   local name = scene.available_ingredients[scene.selected_ingredient].shortname
   print(name,0,0)
  end
 end

 return s
end

-->8
--ingredients--
jam_sale_constants={
 sale_period_length=1.0,
 global_demand_weight=1.0,
 global_base_price_weight=1.0,
 global_generation_weight=1.0,
 global_quality_weight=1.0,
 global_sales_efficiency=1.0,
 global_demand_loss=0.01,
 global_demand_loss_modifier=1.0,
 global_harvest_mod=1,
 global_cook_speed=1.0,
}

function get_price(jam)
 return get_base_price(jam) * get_generatoin_modifier(jam) * get_demand(jam) * jam_sale_constants.global_sales_efficiency
end

function get_generatoin_modifier(jam)
 return jam.gen*jam_sale_constants.global_generation_weight
end

function get_base_price(jam)
 return jam.base_price * jam_sale_constants.global_base_price_weight * jam_sale_constants.global_quality_weight
end

function get_demand(jam)
 return jam.demand*jam_sale_constants.global_demand_weight
end

function sold(jam)
 jam.quantity-=1
 add_money(get_price(jam), jam.scale)
 jam.sale_period_counter=0
 jam.demand = max(jam.demand-jam_sale_constants.global_demand_loss*jam_sale_constants.global_demand_loss_modifier, 0.01)
end

strawberry={
 shortname="strawberry",
 unlocked=false,
 icon=function() return 16 end,
 quantity=0
}

blueberry={
 shortname="blueberry",
 unlocked=false,
 icon=function() return 17 end,
 quantity=0
}

bananaberry={
 shortname="bananaberry",
 unlocked=false,
 icon=function() return 63 end,
 quantity=0
}

manberry={
 shortname="manberry",
 unlocked=false,
 icon_options={18,19,20,21,22},
 current_icon=1,
 icon=function() return manberry.icon_options[manberry.current_icon] end,
 update_icon=function()
  manberry.current_icon=flr(rnd(#manberry.icon_options)+1)
 end,
 quantity=0
}

globerry={
 shortname="globerry",
 unlocked=false,
 icon=function() return 23 end,
 quantity=0
}

bigberry={
 shortname="bigberry",
 unlocked=false,
 icon=function() return 24 end,
 quantity=0
}

bangberry={
 shortname="bangberry",
 unlocked=false,
 icon=function() return 25 end,
 quantity=0
}

darkberry={
 shortname="darkberry",
 unlocked=false,
 icon=function() return 26 end,
 quantity=0
}

galactiberry={
 shortname="galactiberry",
 unlocked=false,
 icon=function() return 27 end,
 quantity=0
}

strawberryjam={
 shortname="strawberry jam",
 unlocked=false,
 icon=function() return 1 end,
 quantity=0,
 base_price=1,
 demand_rate=0.01,
  gen=1,
 demand=1,
scale=1
}



strawberrytrijam={
 shortname="s.tribery jam",
 unlocked=false,
 icon=function() return 1 end,
 quantity=0,
 base_price=1,
 demand_rate=0.01,
  gen=1,
 demand=1,
scale=1
}

strawberrynanajam={
 shortname="s.nanabery jam",
 unlocked=false,
 icon=function() return 1 end,
 quantity=0,
 base_price=1,
 demand_rate=0.01,
  gen=1,
 demand=1,
scale=1
}

bananaberryjam={
 shortname="bananajama",
 unlocked=false,
 icon=function() return 9 end,
 quantity=0,
 base_price=1,
 demand_rate=0.01,
  gen=1,
 demand=1,
scale=1
}


bananaberrytrijam={
 shortname="bananatrijama",
 unlocked=false,
 icon=function() return 9 end,
 quantity=0,
 base_price=1,
 demand_rate=0.01,
  gen=1,
 demand=1,
scale=1
}

bananaberrynanajam={
 shortname="bananananajama",
 unlocked=false,
 icon=function() return 9 end,
 quantity=0,
 base_price=1,
 demand_rate=0.01,
  gen=1,
 demand=1,
scale=1
}

blueberryjam={
 shortname="blueberry jam",
 unlocked=false,
 icon=function() return 2 end,
 quantity=0,
 base_price=1,
 demand_rate=0.01,
  gen=1,
 demand=1,
scale=1
}



blueberrytrijam={
 shortname="b.tribery jam",
 unlocked=false,
 icon=function() return 2 end,
 quantity=0,
 base_price=1,
 demand_rate=0.01,
  gen=1,
 demand=1,
scale=1
}

blueberrynanajam={
 shortname="b.nanabery jam",
 unlocked=false,
 icon=function() return 2 end,
 quantity=0,
 base_price=1,
 demand_rate=0.01,
  gen=1,
 demand=1,
scale=1
}

manberryjam={
 shortname="manberry jam",
 unlocked=false,
 icon=function() return 5 end,
 quantity=0,
 base_price=1,
 demand_rate=0.01,
  gen=1,
 demand=1,
scale=1
}



manberrytrijam={
 shortname="m.triberry jam",
 unlocked=false,
 icon=function() return 11 end,
 quantity=100,
 base_price=1,
 demand_rate=0.01,
  gen=1,
 demand=1,
scale=1
}

manberrynanajam={
 shortname="mananabery jam",
 unlocked=false,
 icon=function() return 64 end,
 quantity=100,
 base_price=1,
 demand_rate=0.01,
  gen=1,
 demand=1,
scale=1
}

bluemanberryjam={
 shortname="blumanbery jam",
 unlocked=false,
 icon=function() return 8 end,
 quantity=100,
 base_price=1,
 demand_rate=0.01,
  gen=1,
 demand=1,
scale=1
}

strawmanberryjam={
 shortname="s.manberry jam",
 unlocked=false,
 icon=function() return 7 end,
 quantity=100,
 base_price=1,
 demand_rate=0.01,
  gen=1,
 demand=1,
scale=1
}

bluestrawberyjam={
 shortname="b.s.berry jam",
 unlocked=false,
 icon=function() return 6 end,
 quantity=100,
 base_price=111,
 demand_rate=0.007,
 gen=3,
 demand=1,
scale=1
}

bluemanstrawberyjam={
 shortname="b.m.s.bery jam",
 unlocked=false,
 icon=function() return 10 end,
 quantity=100,
 base_price=111,
 demand_rate=0.007,
 gen=3,
 demand=1,
scale=1
}

globerryjam={
 shortname="globerry jam",
 unlocked=false,
 icon=function() return 33 end,
 quantity=100,
 base_price=111,
 demand_rate=0.007,
 gen=3,
 demand=1,
scale=2
}



globtriberryjam={
 shortname="g.triberry jam",
 unlocked=false,
 icon=function() return 33 end,
 quantity=100,
 base_price=111,
 demand_rate=0.007,
 gen=3,
 demand=1,
scale=2
}

globnanaberryjam={
 shortname="g.nanabery jam",
 unlocked=false,
 icon=function() return 33 end,
 quantity=100,
 base_price=111,
 demand_rate=0.007,
 gen=3,
 demand=1,
scale=2
}

globlueberryjam={
 shortname="g.b.berry jam",
 unlocked=false,
 icon=function() return 34 end,
 quantity=100,
 base_price=111,
 demand_rate=0.007,
 gen=3,
 demand=1,
scale=2
}

globstrawberryjam={
 shortname="g.s.berry jam",
 unlocked=false,
 icon=function() return 36 end,
 quantity=100,
 base_price=111,
 demand_rate=0.007,
 gen=3,
 demand=1,
scale=2
}

globmanberryjam={
 shortname="g.manberry jam",
 unlocked=false,
 icon=function() return 37 end,
 quantity=100,
 base_price=111,
 demand_rate=0.007,
 gen=3,
 demand=1,
scale=2
}

globluestrawberryjam={
 shortname="g.b.s.bery jam",
 unlocked=false,
 icon=function() return 38 end,
 quantity=100,
 base_price=111,
 demand_rate=0.007,
 gen=3,
 demand=1,
scale=2
}

globluemanberryjam={
 shortname="g.b.m.bery jam",
 unlocked=false,
 icon=function() return 39 end,
 quantity=100,
 base_price=111,
 demand_rate=0.007,
 gen=3,
 demand=1,
scale=2
}

globstrawmanberryjam={
 shortname="g.s.m.bery jam",
 unlocked=false,
 icon=function() return 56 end,
 quantity=100,
 base_price=111,
 demand_rate=0.007,
 gen=3,
 demand=1,
scale=2
}

galactijam={
 shortname="globerry jam",
 unlocked=false,
 icon=function() return 66 end,
 quantity=100,
 base_price=111,
 demand_rate=0.007,
 gen=3,
 demand=1,
scale=3
}



galactilactilactijam={
 shortname="galactrijam",
 unlocked=false,
 icon=function() return 66 end,
 quantity=100,
 base_price=111,
 demand_rate=0.007,
 gen=3,
 demand=1,
scale=3
}

galactinanajam={
 shortname="galactinanajam",
 unlocked=false,
 icon=function() return 66 end,
 quantity=100,
 base_price=111,
 demand_rate=0.007,
 gen=3,
 demand=1,
scale=3
}

glactiblueberryjam={
 shortname="glactib. jam",
 unlocked=false,
 icon=function() return 112 end,
 quantity=100,
 base_price=111,
 demand_rate=0.007,
 gen=3,
 demand=1,
scale=3
}

glactistrawberryjam={
 shortname="glactis. jam",
 unlocked=false,
 icon=function() return 113 end,
 quantity=100,
 base_price=111,
 demand_rate=0.007,
 gen=3,
 demand=1,
scale=3
}

galactimanberryjam={
 shortname="galactim. jam",
 unlocked=false,
 icon=function() return 114 end,
 quantity=100,
 base_price=111,
 demand_rate=0.007,
 gen=3,
 demand=1,
scale=3
}

galactigloberryjam={
 shortname="galactig. jam",
 unlocked=false,
 icon=function() return 57 end,
 quantity=100,
 base_price=111,
 demand_rate=0.007,
 gen=3,
 demand=1,
scale=3
}

galactibluestrawberryjam={
 shortname="galactib.s.jam",
 unlocked=false,
 icon=function() return 58 end,
 quantity=100,
 base_price=111,
 demand_rate=0.007,
 gen=3,
 demand=1,
scale=3
}

galactibluemanberryjam={
 shortname="galactib.m.jam",
 unlocked=false,
 icon=function() return 59 end,
 quantity=100,
 base_price=111,
 demand_rate=0.007,
 gen=3,
 demand=1,
scale=3
}

galactibluegloberryjam={
 shortname="galactib.g.jam",
 unlocked=false,
 icon=function() return 79 end,
 quantity=100,
 base_price=111,
 demand_rate=0.007,
 gen=3,
 demand=1,
scale=3
}

galactistrawmanberryjam={
 shortname="galactis.m.jam",
 unlocked=false,
 icon=function() return 111 end,
 quantity=100,
 base_price=111,
 demand_rate=0.007,
 gen=3,
 demand=1,
scale=3
}

galctistawgloberryjam={
 shortname="galactis.g.jam",
 unlocked=false,
 icon=function() return 95 end,
 quantity=100,
 base_price=111,
 demand_rate=0.007,
 gen=3,
 demand=1,
scale=3
}

galactiglobemanberryjam={
 shortname="galactig.m.jam",
 unlocked=false,
 icon=function() return 127 end,
 quantity=100,
 base_price=111,
 demand_rate=0.007,
 gen=3,
 demand=1,
scale=3
}

darkjam={
 shortname="dark jam",
 unlocked=false,
 icon=function() return 80 end,
 quantity=100,
 base_price=111,
 demand_rate=0.007,
 gen=3,
 demand=1,
scale=4
}



darktrijam={
 shortname="darktri jam",
 unlocked=false,
 icon=function() return 80 end,
 quantity=100,
 base_price=111,
 demand_rate=0.007,
 gen=3,
 demand=1,
scale=4
}
darknanajam={
 shortname="darknana jam",
 unlocked=false,
 icon=function() return 80 end,
 quantity=100,
 base_price=111,
 demand_rate=0.007,
 gen=3,
 demand=1,
scale=4
}
bigberryjam={
 shortname="bigberry jam",
 unlocked=false,
 icon=function() return 82 end,
 quantity=100,
 base_price=111,
 demand_rate=0.007,
 gen=3,
 demand=1,
scale=4
}


bigtriberryjam={
 shortname="bigtribery jam",
 unlocked=false,
 icon=function() return 82 end,
 quantity=100,
 base_price=111,
 demand_rate=0.007,
 gen=3,
 demand=1,
scale=4
}

bignanaberryjam={
 shortname="biganabery jam",
 unlocked=false,
 icon=function() return 82 end,
 quantity=100,
 base_price=111,
 demand_rate=0.007,
 gen=3,
 demand=1,
scale=4
}

bangberryjam={
 shortname="bangberry jam",
 unlocked=false,
 icon=function() return 96 end,
 quantity=100,
 base_price=111,
 demand_rate=0.007,
 gen=3,
 demand=1,
scale=4
}



bangtriberryjam={
 shortname="bangtriberyjam",
 unlocked=false,
 icon=function() return 96 end,
 quantity=100,
 base_price=111,
 demand_rate=0.007,
 gen=3,
 demand=1,
scale=4
}

bangnanaberryjam={
 shortname="bangnanabeyjam",
 unlocked=false,
 icon=function() return 96 end,
 quantity=100,
 base_price=111,
 demand_rate=0.007,
 gen=3,
 demand=1,
scale=4
}

chaosjam={
 shortname="chaos jam",
 unlocked=false,
 icon=function() return 172 end,
 quantity=100,
 base_price=111,
 demand_rate=0.007,
 gen=3,
 demand=1,
scale=4
}

badjam={
 shortname="bad jam",
 unlocked=false,
 icon=function() return 3 end,
 quantity=100,
 base_price=1,
 demand_rate=0.01,
 gen=1,
 demand=1,
scale=1
}



badtrijam={
 shortname="badtri jam",
 unlocked=false,
 icon=function() return 3 end,
 quantity=100,
 base_price=111,
 demand_rate=0.007,
 gen=3,
 demand=1,
scale=1
}

badnanajam={
 shortname="badnana jam",
 unlocked=false,
 icon=function() return 3 end,
 quantity=100,
 base_price=111,
 demand_rate=0.007,
 gen=3,
 demand=1,
scale=1
}

bigbangjam={
 shortname="bigbang jam",
 unlocked=false,
 icon=function() return 81 end,
 quantity=100,
 base_price=111,
 demand_rate=0.007,
 gen=3,
 demand=1,
scale=1
}

primordialjam={
 shortname="primordial jam",
 unlocked=false,
 icon=function() return 65 end,
 quantity=100,
 base_price=111,
 demand_rate=0.007,
 gen=3,
 demand=1,
scale=4
}

-->8
--manufacturing
function harvest(scene, num)
 if not num then num=32767 end
 local counter=0
 for bush in all(scene.planted_bushes) do
  if bush.harvest_counter > bush.template.harvest_time  and counter < num then
   harvest_bush(bush)
   counter+=1
  end
 end
end

function harvest_bush(bush)
 bush.harvest_counter=0.0
 if not screen.active_scenes[2] then
  screen.active_scenes[2]=screen.scenes[2]
  screen.active_scenes[2].unlocked=true
 end
 bush.template.produce.quantity+=1
 if not bush.template.produce.unlocked then
  add(screen.active_scenes[2].available_ingredients, bush.template.produce)
  bush.template.produce.unlocked=true
 end
end

emptybush_icon=51

strawberry_bush={
 icon=48,
 price=10,
 scale=1,
 produce=strawberry,
 harvest_time=10.0,
 unlocked=true,
 quantity=0
}

function unlock_blueberry()
 blueberry_bush.unlocked=true
 add(screen.active_scenes[1].bushes, blueberry_bush)
end

blueberry_bush={
 icon=52,
 price=10,
 scale=1,
 produce=blueberry,
 harvest_time=10,
 unlocked=true,
 quantity=0
}

-->8
--recipes--
function has_ingredients(recipe)
 input1=0
 input2=0
 input3=0
 if #recipe.inputs==1 then
  if (recipe.inputs[1].quantity==0) return false
  input1 = recipe.inputs[1].quantity-1
 end

 if #recipe.inputs==2 then
  if (recipe.inputs[1].quantity==0) return false
  if (recipe.inputs[2].quantity==0) return false
  input1 = recipe.inputs[1].quantity-1
  input2 = recipe.inputs[2].quantity-1
  if recipe.inputs[1]==recipe.inputs[2] then input2-=1 end
 end

 if #recipe.inputs==3 then
  if (recipe.inputs[1].quantity==0) return false
  if (recipe.inputs[2].quantity==0) return false
  if (recipe.inputs[3].quantity==0) return false
  input1 = recipe.inputs[1].quantity-1
  input2 = recipe.inputs[2].quantity-1
  input3 = recipe.inputs[3].quantity-1
  if recipe.inputs[1]==recipe.inputs[2] then input2-=1 end
  if recipe.inputs[1]==recipe.inputs[3] then input3-=1 end
  if recipe.inputs[2]==recipe.inputs[3] then input3-=1 end
 end

 if input1<0 or input2<0 or input3<0 then return false else return true end
end

function spend_ingredients(recipe)
 for input in all(recipe.inputs) do
  input.quantity-=1
 end
end

function gain_jam(jam)
 kitchen=screen.active_scenes[2]
 store=screen.active_scenes[3]
 jam.quantity += 1
 if not jam.unlocked then
  jam.unlocked=true
  add(kitchen.available_ingredients, jam)
  if not store then
   screen.active_scenes[3]=screen.scenes[3]
   screen.active_scenes[3].unlocked=true
   store=screen.active_scenes[3]
  end
  add(store.stock, jam)
 end
end

function lookup_recipe(mixer_contents)
 local output=false
 local temp_recipes = {}
 local matches = {}
 --make a sublist of recipes where inputs length is the same as mixer contents length
 for check in all(recipes) do
  if #check.inputs==#mixer_contents then
   add(temp_recipes,check)
  end
 end

 --filter out recipes that don't contain element 1
 if #mixer_contents==1 then
  for recipecheck in all(temp_recipes) do
   local used1= false
   if recipecheck.inputs[1] == mixer_contents[1] then used1=true end
   if (used1) add(matches,recipecheck)
  end
 end
  --filter out recupes that don't contain element 2
 if #mixer_contents==2 then
  local matches2 = {}
  for recipecheck in all(temp_recipes) do

   local used1= false
   local used2= false

   if recipecheck.inputs[1] == mixer_contents[1] then
    used1=true 
    goto twoinputsecondcheck
   end
   if recipecheck.inputs[1] == mixer_contents[2] then used2=true end
   ::twoinputsecondcheck::

   if recipecheck.inputs[2] == mixer_contents[1] then 
    used1=true 
    goto twoinputend
   end
   if recipecheck.inputs[2] == mixer_contents[2] then used2=true end
   ::twoinputend::
   if used1 and used2 then
    add(matches2,recipecheck)
   end
  end
 matches=matches2
 end

  --filter out recupes that don't contain element 3
 if #mixer_contents==3 then
  local matches3 = {}
  for recipecheck in all(temp_recipes) do
   local used1= false
   local used2= false
   local used3= false

   if recipecheck.inputs[1] == mixer_contents[1] then
    used1=true
    goto threeinputsecondcheck
   end

   if recipecheck.inputs[1] == mixer_contents[2] then
    used2=true 
    goto threeinputsecondcheck
   end
    if recipecheck.inputs[1] == mixer_contents[3] then
    used3=true
   end

   ::threeinputsecondcheck::
   if recipecheck.inputs[2] == mixer_contents[1] and not used1 then
    used1=true
    goto threeinputthirdcheck
   end

   if recipecheck.inputs[2] == mixer_contents[2] and not used2 then
    used2=true
    goto threeinputthirdcheck
   end

   if recipecheck.inputs[2] == mixer_contents[3] and not used3 then used3=true end

   ::threeinputthirdcheck::

   if recipecheck.inputs[3] == mixer_contents[1] and not used1 then
    used1=true
    goto threeinputend
   end

   if recipecheck.inputs[3] == mixer_contents[2] and not used2 then
    used2=true
    goto threeinputend
   end

   if recipecheck.inputs[3] == mixer_contents[3] and not used3 then used3=true end

   ::threeinputend::
   
   if used1 and used2 and used3 then
    add(matches3,recipecheck)
   end
  end
 matches=matches3
 end

  --return the only remaining recipe
 if #matches > 0 then
  output=matches[1]
  if not output.discovered then
   output.discovered=true
   add(known_good_recipes, output)
  end
 end

  return output
end

recipes={
 --strawberry jam--
 {
  discovered=false,
  inputs={
   strawberry
  },
  output=strawberryjam
 },
 --strawtriberry jam--
 {
  discovered=false,
  inputs={
   strawberry,
   strawberry,
   strawberry
  },
  output=strawberrytrijam
 },
 --strawnanaberry jam--
 {
  discovered=false,
  inputs={
   strawberrytrijam,
   strawberrytrijam,
   strawberrytrijam,
  },
  output=strawberrynanajam
 },
 {
  discovered=false,
  inputs={
   strawberry,
   bananaberry
  },
  output=strawberrynanajam
 },

 --blueberry jam--
 {
  discovered=false,
  inputs={
   blueberry
  },
  output=blueberryjam
 },
--bluetriberry jam--
 {
  discovered=false,
  inputs={
   blueberry,
   blueberry,
   blueberry
  },
  output=blueberrytrijam
 },
 --bluenanaberry jam--
 {
  discovered=false,
  inputs={
   blueberrytrijam,
   blueberrytrijam,
   blueberrytrijam,
  },
  output=blueberrynanajam
 },
 {
  discovered=false,
  inputs={
   blueberry,
   bananaberry
  },
  output=blueberrynanajam
 },
--bananaberry jam--
 {
  discovered=false,
  inputs={
   bananaberry
  },
  output=bananaberryjam
 },
--bananatriberry jam--
 {
  discovered=false,
  inputs={
   bananaberry,
   bananaberry,
   bananaberry
  },
  output=bananaberrytrijam
 },
 --bananananaberry jam--
 {
  discovered=false,
  inputs={
   bananaberrytrijam,
   bananaberrytrijam,
   bananaberrytrijam,
  },
  output=bananaberrynanajam
 },
--manberry jam--
 {
  discovered=false,
  inputs={
   manberry
  },
  output=manberryjam
 },
 --mantriberry jam--
 {
  discovered=false,
  inputs={
   manberry,
   manberry,
   manberry
  },
  output=manberrytrijam
 },
 --mananaberry jam
 {
  discovered=false,
  inputs={
   manberrytrijam,
   manberrytrijam,
   manberrytrijam
  },
  output=manberrynanajam
 },
 {
  discovered=false,
  inputs={
   manberry,
   bananaberry
  },
  output=manberrynanajam
 },
 --bluemanbery jam
 {
  discovered=false,
  inputs={
   blueberry,
   manberry,
  },
  output=bluemanberryjam
 },
 --strawmanbery jam
 {
  discovered=false,
  inputs={
   strawberry,
   manberry,
  },
  output=strawmanberryjam
 },
 --bluestrawbery jam
 {
  discovered=false,
  inputs={
   strawberry,
   blueberry
  },
  output=bluestrawberyjam
 },

--bluemanstrawbery jam
 {
  discovered=false,
  inputs={
   strawberry,
   manberry,
   blueberry
  },
  output=bluemanstrawberyjam
 },
--globerry jam--
 {
  discovered=false,
  inputs={
   globerry,
  },
  output=globerryjam
 },
 --globtriberry jam--
 {
  discovered=false,
  inputs={
   globerry,
   globerry,
   globerry,
  },
  output=globtriberryjam
 },
 --globnanaberry jam--
 {
  discovered=false,
  inputs={
   globtriberryjam,
   globtriberryjam,
   globtriberryjam,
  },
  output=globnanaberryjam
 },
 {
  discovered=false,
  inputs={
   globerry,
   bananaberry
  },
  output=globnanaberryjam
 },

 --globblueberry jam--
 {
  discovered=false,
  inputs={
   globerry,
   blueberry
  },
  output=globlueberryjam
 },
--globstrawberry jam--
 {
  discovered=false,
  inputs={
   globerry,
   strawberry
  },
  output=globstrawberryjam
 },
--globmanberry jam--
 {
  discovered=false,
  inputs={
   globerry,
   manberry
  },
  output=globmanberryjam
 },
 --globluestrawberry jam--
 {
  discovered=false,
  inputs={
   globerry,
   strawberry,
   blueberry
  },
  output=globluestrawberryjam
 },
--globluemanberry jam--
 {
  discovered=false,
  inputs={
   globerry,
   manberry,
   blueberry
  },
  output=globluemanberryjam
 },
--glostrawmanberry jam--
 {
  discovered=false,
  inputs={
   globerry,
   manberry,
   strawberry
  },
  output=globstrawmanberryjam
 },
--galactijam--
 {
  discovered=false,
  inputs={
   galactiberry,
  },
  output=galactijam
 },
 --galactrijam--
 {
  discovered=false,
  inputs={
   galactiberry,
   galactiberry,
   galactiberry,
  },
  output=galactilactilactijam
 },
 --galactinanajam--
 {
  discovered=false,
  inputs={
   galactilactilactijam,
   galactilactilactijam,
   galactilactilactijam,
  },
  output=galactinanajam
 },
 {
  discovered=false,
  inputs={
   galactiberry,
   bananaberry
  },
  output=galactinanajam
 },

 --galactibluejam--
 {
  discovered=false,
  inputs={
   galactiberry,
   blueberry
  },
  output=glactiblueberryjam
 },
 --galactistrawjam--
 {
  discovered=false,
  inputs={
   galactiberry,
   strawberry
  },
  output=glactistrawberryjam
 },
 --galactimanjam--
 {
  discovered=false,
  inputs={
   galactiberry,
   manberry
  },
  output=galactimanberryjam
 },
 --galactiglobejam--
 {
  discovered=false,
  inputs={
   galactiberry,
   globerry
  },
  output=galactigloberryjam
 },
 --galactibluestrawberryjam--
 {
  discovered=false,
  inputs={
   galactiberry,
   blueberry,
   strawberry
  },
  output=galactibluestrawberryjam
 },

 --galactibluestrawberryjam--
 {
  discovered=false,
  inputs={
   galactiberry,
   blueberry,
   manberry
  },
  output=galactibluemanberryjam
 },
 --galactibluestrawberryjam--
 {
  discovered=false,
  inputs={
   galactiberry,
   blueberry,
   globerry
  },
  output=galactibluegloberryjam
 },
 --galactistrawmanberryjam--
 {
  discovered=false,
  inputs={
   galactiberry,
   strawberry,
   manberry
  },
  output=galactistrawmanberryjam
 },

 --galctistawgloberryjam--
 {
  discovered=false,
  inputs={
   galactiberry,
   strawberry,
   globerry
  },
  output=galctistawgloberryjam
 },

 --galactiglobemanberryjam--
 {
  discovered=false,
  inputs={
   galactiberry,
   manberry,
   globerry
  },
  output=galactiglobemanberryjam
 },
 --dark jam--
 {
  discovered=false,
  inputs={
   darkberry,
  },
  output=darkjam
 },
 --darktri jam--
 {
  discovered=false,
  inputs={
   darkberry,
   darkberry,
   darkberry,
  },
  output=darktrijam
 },
 --darknana jam--
 {
  discovered=false,
  inputs={
   darktrijam,
   darktrijam,
   darktrijam,
  },
  output=darknanajam
 },
 {
  discovered=false,
  inputs={
   darkberry,
   bananaberry
  },
  output=darknanajam
 },
 --big jam--
 {
  discovered=false,
  inputs={
   bigberry,
  },
  output=bigberryjam
 },

 --bigtri jam--
 {
  discovered=false,
  inputs={
   bigberry,
   bigberry,
   bigberry,
  },
  output=bigtriberryjam
 },
 --bignana jam--
 {
  discovered=false,
  inputs={
   bigtrijam,
   bigtrijam,
   bigtrijam,
  },
  output=bignanaberryjam
 },
 {
  discovered=false,
  inputs={
   bigberry,
   bananaberry
  },
  output=bignanaberryjam
 },

 --bang jam--
 {
  discovered=false,
  inputs={
   bangberry,
  },
  output=bangberryjam
 },

 --bigtri jam--
 {
  discovered=false,
  inputs={
   bangberry,
   bangberry,
   bangberry,
  },
  output=bangtriberryjam
 },
 --bangnana jam--
 {
  discovered=false,
  inputs={
   bangtrijam,
   bangtrijam,
   bangtrijam,
  },
  output=bangnanaberryjam
 },
 {
  discovered=false,
  inputs={
   bangberry,
   bananaberry
  },
  output=bangnanaberryjam
 },
 --chaos jam--
 {
  discovered=false,
  inputs={
   bigberry,
   badjam,
  },
  output=chaosjam
 },
 {
  discovered=false,
  inputs={
   darkberry,
   badjam,
  },
  output=chaosjam
 },
 {
  discovered=false,
  inputs={
   badjam,
   bangberry,
  },
  output=chaosjam
 },

 --badtri jam--
 {
  discovered=false,
  inputs={
   badjam,
   badjam,
   badjam,
  },
  output=badtrijam
 },
 --badnana jam--
 {
  discovered=false,
  inputs={
   badtrijam,
   badtrijam,
   badtrijam,
  },
  output=badnanajam
 },
 --bigbang jam--
 {
  discovered=false,
  inputs={
   bigberry,
   bangberry,
  },
  output=bigbangjam
 },
 --primordial jam--
 {
  discovered=false,
  inputs={
   bigbangjam,
   darknanajam,
   galactinanajam,
  },
  output=primordialjam
 },
}



-->8
-- upgrades --
function check_for_unlocks(scene)
 if cash_money[1]==32767 and not accountant.unlocked then
  accountant.unlocked=true
  add(scene.available_upgrades, accountant)
  accountant.on_unlock(scene)
 end

 if cash_money[2]==32767 and not banker.unlocked then
  banker.unlocked=true
  add(scene.available_upgrades, banker)
  banker.on_unlock(scene)
 end

 if cash_money[3]==32767 and not blockchain.unlocked then
  blockchain.unlocked=true
  add(scene.available_upgrades, blockchain)
  blockchain.on_unlock(scene)
 end

 if cash_money[1]>=100 and not farmer.unlocked then
  farmer.unlocked=true
  add(scene.available_upgrades, farmer)
  farmer.on_unlock(scene)
 end

 if cash_money[1]>=1000 and not cook.unlocked then
  cook.unlocked=true
  add(scene.available_upgrades, cook)
  cook.on_unlock(scene)
 end
end

cook={
 name="cook",
 description="automatically makes known jams",
 unlocked=false,
 price=1000,
 scale=1,
 quantity=0,
 max_quantity=32767,
 icon=188,
 countdown=0.0,
 on_purchase=function(scene) end,
 on_unlock=function(scene) end,
 update=function(scene)
  cook.countdown+=1/30
  if cook.countdown > jam_sale_constants.global_cook_speed then
   cook.countdown=0.0
   for i=1,cook.quantity,1 do
    for recipe in all(known_good_recipes) do
     if has_ingredients(recipe) then
      spend_ingredients(recipe)
      gain_jam(recipe.output)
     end
    end
   end
  end
 end
}

farmer={
 name="farmer",
 description="automatically harvests berries",
 unlocked=false,
 price=100,
 scale=1,
 quantity=0,
 max_quantity=32767,
 icon=188,
 on_purchase=function(scene) end,
 on_unlock=function(scene) end,
 update=function(scene)
  harvest(screen.active_scenes[1], jam_sale_constants.global_harvest_mod)
 end
}

accountant={
 name="accountant",
 description="converts "..cash_symbols[1].." into "..cash_symbols[2],
 unlocked=false,
 price=32767,
 scale=1,
 quantity=0,
 max_quantity=1,
 icon=173,
 on_purchase=function(scene) end,
 on_unlock=function(scene) end,
 update=function(scene)
  if cash_money[1]==32767 then
   cash_money[1]=0
   cash_money[2]+=1
  end
 end
}

banker={
 name="banker",
 description="converts "..cash_symbols[2].." into "..cash_symbols[3],
 unlocked=false,
 price=32767,
 scale=2,
 quantity=0,
 max_quantity=1,
 icon=174,
 on_purchase=function(scene) end,
 on_unlock=function(scene) end,
 update=function(scene)
 if cash_money[2]==32767 then
   cash_money[2]=0
   cash_money[3]+=1
  end
 end
}

blockchain={
 name="blochchain",
 description="converts "..cash_symbols[3].." into "..cash_symbols[4],
 unlocked=false,
 price=32767,
 scale=3,
 quantity=0,
 max_quantity=1,
 icon=175,
 on_purchase=function(scene) end,
 on_unlock=function(scene) end,
 update=function(scene)
  if cash_money[3]==32767 then
   cash_money[3]=0
   cash_money[4]+=1
  end
 end
}
__gfx__
00000000555555555555555555555555555555555555555555555555555555555555555555555555555555555555555500bbbbbbbbbbbbbbbbbbbbbbbbbbbb00
000000000628826006d11d600633326006000060067777600628d1600628776006d14460069aa96006777760067799600bbbbbbbbbbbbbbbbbbbbbbbbbbbbbb0
0070070006828860061111600633336006000060065775600688116006887c600611436006a9aa6006c77c60063795600bbbbbbbbbbbbbbbbbbbbbbbbbbbbbb0
00077000068882600611d16006323360060000600677776006821d6006827760061d446006aaa96006777760067799600bbbbbbbbbb333bbbbbbbbbb333bbbb0
000770006282888661d111166333323660000006677777766888111662887776611144466aa9aa9662881d1667dddd960bbbbbbbbb3333bbbbbbbbb3333bbbb0
007007006888828661111116633233366000000667dddd76628811d66882dd766d11dd4669aa9aa6688211166744ee960bbbbbbbbb38333bbbbbbbb38333bbb0
00000000682828266d11d1d662333326600000066777ee766882d1166288ee76611dee466a9aaa966288d1d66444ee460bbbbbbbb333338bbbbbbb333338bbb0
0000000006666660066666600666666006666660066666600666666006666660066666600666666006666660066666600bbbbb3333333333bbbbbb3833333bb0
0330033000144100044444400aaaaaa00eeeeee00aaaaaa0011111100077770000dddd0000111100000550000deeeeed0bbbb33338338338bbb3333338338bb0
000330000111111044777744aa7777aaee4444eeaa9999aa114444110cccccc00dd111d0011ddd1000555500deeddded0bbbb38333333333bb33333333333bb0
008888001111111147777774a777777ae444444ea999999a14444441cbbcccbcdd1ddd1d11d111d105655650dedeeded0bbb333338bbbbbbbb38333bbbbbbbb0
0888888011111111737777377c7777c7434444349599995942444424bbbcccbbd1dd1d1d1d11d1d155566555dededded0bb33333333bbbbbb333338bbbbbbbb0
08888880111111117777777777777777444444449999999944444444bbccccccd1d1dd1d1d1d11d155566555dedeeeed0bb38338338bbbbb33333333bbbbbbb0
08888880111111117dddddd77dddddd74dddddd49dddddd94dddddd4ccccbbccd1dd11dd1d11dd1105655650deeddddd0bb33333333bbbbb38338338bbbbbbb0
00888800011111107777eee77777eee74444eee49999eee94444eee40cccbbc00d1dddd001d1111000555500dddeee000bbbbbbbbbbbbbbb33333333bbbbbbb0
00088000001111000777eee00777eee00444eee00999eee00444eee00077770000d1dd00001d11000005500000dddee000bbbbbbbbbbbbbbbbbbbbbbbbbbbb00
000070005555555555555555bbbbbb3b55555555555555555555555555555555ddddd57777777777775dd5777775dddd5555555555dddddddddddd5555dddd55
000077000677776006777760b3bbbb3b06777760067777600677776006777760ddddd57777777777775dd5777775ddddd555555ddddddddddddddddddddddddd
0000777006cbcc6006cbcc603bbbb3bb06cbcc6006cbcc6006cbcc6006cbcc60ddddd57777777777775dd5777775ddddd555555ddddddddddddddddddddddddd
7777777706bbcc6006bbcc603bbb3bbb06bbcc6006bbcc6006bbcc6006bbcc60ddddd57777777777775dd5777775ddddd555555ddddddddddddddddddddddddd
777777776ccccbc6611d1d16bb3b3bbb6882828667777776611d828665114446ddddd57777777777775dd5777775dddddd5555dddddddddddddddddddddddddd
000077706bcbbbc66d11d116b33bbb3b6288288667dddd766d1128866115dd46ddddd57777777777775dd5777775dddddd5555dddddddddddddddddddddddddd
000077006777777661d111d6bbbbb3bb682888266777ee7661d188266511ee46ddddd57777777777775dd5777775dddddd5555dddddddddddddddddddddddddd
0000700006666660066666603bbbb3bb06666660066666600666666006666660ddddd57676767676765dd5767675dddddd5555dddddddddddddddddddddddddd
0000000000000000000555000000000000000000dd5555dddd5555dddddddddd5555555555555555555555555555555507777770555555550000000000004444
0003330000000000055555550003330000033300dd5555dddd5555dddddddddd067777600677de6006115160061151607ffffff75d5555d50004330000004444
0033330006600660055555550033330000333300dd5555dd555555555555555506cbcc6006cbdd6006511560065115600fcffcf051586515003a33000000aaaa
0038333006600660555555550033333000313330dd5555dd555555555555555506bbcc6006bced60061511600615116008ffff805d5885d500aa34300000aaaa
0333338006660666555555550333333003333310dd5555dd5555555555555555628844466bbcddd66882ddd66777ddd6f0eeee0f5155551504333a30000aaaaa
3333333366666666555555553333333333333333dd5555dddd5555dddddddddd6882dd466ccbede66288ede667ddede60eeeeee0550000553a33aa3400aaaaa0
3833833856565656055555503333333331331331dd5555dddd5555dddddddddd6288ee466777ded66882ded66777ded6eeeeeeee50000005aa33333a0aaaaa00
3333333366666666000055003333333333333333dd5555dddd5555dddddddddd06666660066666600666666006666660eeeeeeee50000005333333aaaaaa0000
55555555555555555555555500dddddddddddddddddddddddddddd00009999977777777777777777779999000066666666666666666666666666660055555555
06947860065d516006dede600dddddddddddddddddd444444444ddd009999997777777fffffffff7777999900667777776666666666666666666666006777760
06947860061ede6006eddd600dddddddd55555555dd4fffffff4ddd00999997777fffffffffffffff7779990067ffffff7665555666666666666666006cbcb60
06947860065d5d6006dded600dd5555555588826ddd48f8f8f84ddd009999977fffffffffffffffff7779990066fcffcf6665aa5777777666666666006bcbc60
6ed654a66ede1ed66dedddd60ddd628826882886ddd444444444ddd0099997778888888fff8888888f7779900668ffff86665aa7ffffff76655556606511ddd6
6ed3e4a6615d5d566eddede60ddd682886288826ddd4fffffff4ddd00999777f8fcccf88888fcccf8ff7779006f6eeee6f665555fcffcf6665aa56606151ede6
6edce9a66e1ede166dedded60ddd6888268828886dd41f1f1f14ddd0099977ff8fcccf8fff8fcccf8fff7790066eeeeee65555558ffff86665aa56606515ded6
0666666006666660066666600dd62855555555886dd444444444ddd0099777ff8fcccf8fff8fcccf8fff779006eeee777777666feeeeeef66555566006666660
5555555555555555555555550dd68886288268826dd4fffffff4ddd0099999ff8888888fff8888888fff999006eee7ffffff7665555eee655555555055555555
0656556006d1d16006dddd600dd6828682886886ddd49f9f9f94ddd0099999ffffffffff9fffffffffff9990066666fcffcf6665aa5eeee56666665006777760
06555560061d1d6006dddd600ddd66668882666dddd444444444ddd0099999fffffffff99fffffffffff99900666668ffff86665aa5eeee56666665006cbcb60
0655656006d1d16006dddd600ddddd62828886ddddd4f6fff6f4ddd0099999fffff88ffffff88ffffff9999006666f6eeee6f665555666666666666006bcbc60
655555566d1d1d166dddddd60ddddd68888286ddddd4616f6864ddd00999999fffff88888888ffffff999990066666eeeeee655555555666666666606288ddd6
6565565661d1d1d66dddddd60ddddd68282826ddddd4666f6664ddd009999999fff8888888888fff9999999006666eeeeeeee56666665666666666606828ede6
655555566d1d1d166dddddd60dddddd666666dddddd444444444ddd00999999999fffffffffffff99999999006666eeeeeeee56666665666666666606282ded6
06666660066666600666666000dddddddddddddddddddddddddddd00009999999eeeffffffffeee9999999000066666666666666666666666666660006666660
55555555555555555555555500dddd555ddd55ddddd555ddd5550000007777777777777777777777777777000099999911111111111111111111110055555555
0611116006ad5a60067744600ddd555555d5555dd55555d5555555d00cccccccccccccccccccccccccccccc00999999911111111111111111111111006444460
06111160061ede60065743600ddd555555d55555555555d5555555d00cccccccccccccccccccccccccccccc00999999111611111111111111111111006c44c60
06111160065dad60067744600dd555555555555555555555555555d00ccccbbbbccccccccccbccccccccccb00999999111111111111111111111111006444460
611111166ede1ed6677744460dd555555555555555555555555555d00cccbbbccccbbcbccccbbbbbbcccccb0099991111111181188811111111111106288ddd6
6111111661ad5d5667dddd460dd555555555555555555555555555d00cccbbcccccbbbbccccccbbbbcccccb0011111111111878887881111111111106828ede6
611111166e1eaea66777ee460ddd555555655555d55555d5555556d00cccbbcccccbbbbcccccbbbbbccccbb0011111111111188888871111111111106282ded6
0666666006666660066666600ddd66d55d66ddddd66d55d66d5566d00ccccccccbccbbcccccccccbbccccbb00111111111111178781111aaa111111006666660
5555555555555555555555550ddd66dd66666666d66dd666666666d00ccccccccbbcbbbbbbccccccccccccb00111111111111188888711aaa111111055555555
0651de600628de600699de600ddd66dd66565656d66dd656565656d00cccccbcccbcccbbcccbbbccccccccc00111111111111187888811aaa111111006777760
0611dd600688dd600659dd600ddd66dd66666666d66dd666666666d00ccccbbccbbbbcccccbbbbbcccccccc00111111111111188187811111111111006cbcb60
0611ed600688ed600699ed600ddd666dddddddddd666d666ddddddd00ccccbbbccbbbcccccbbbbbcccccbcc00111111111111111111111111111111006bcbc60
6115ddd66882ddd66999ddd60d666666666dddd666666666ddddddd00ccbbbbbccbbbccccbbbbbbbcccbbbc0011111111111111111111111111111106777ddd6
6511ede66288ede669ddede60d656565656dddd656565656ddddddd00ccccccccccccccccbbbbbbbccccbbc0011111111111111111111cc11111111067ddede6
6115ded66882ded66999ded60d666666666dddd666666666ddddddd00cccccccccccccccccccccccccccccc0011111111111111111111cc1111dd1106777ded6
06666660066666600666666000dddddddddddddddddddddddddddd0000777777777777777777777777777700001111111111111111111111111dd10006666660
00000000007777777777777000000000000000000077777777777770000000000000000000777777777777700000000000222222222222222222222222222200
00000000777777777777777700000000000000007777777777777777000000000000000077777777777777770000000002222662225555dddd2255522d266220
000000777777777777777777700000000000007777777777777777777000000000000077777777777777777770000000026666dd255222222ddd22552dd26620
0000007777777fffffffff77770000000000007777777fffffffff77770000000000007777777fffffffff777700000002622dd2252662555522226252dd2620
000007777fffffffffffffff77700000000007777fffffffffffffff77700000000007777fffffffffffffff7770000002622d226666222265556662552dd620
0000077fffffffffffffffff777000000000077fffffffffffffffff777000000000077fffffffffffffffff777000000222dd52622888726666622782222620
00007778888888fff8888888f777000000007778888888fff8888888f777000000007778888888fff8888888f77700000222d556228788822222222888882220
000777f8fcccf88888fcccf8ff777000000777f8fffff88888fffff8ff777000000777f8fffff88888fffff8ff777000022dd522288888822222222887882250
00077ff8fcccf8fff8fcccf8fff7700000077ff8fcccf8fff8fcccf8fff7700000077ff8fffff8fff8fffff8fff77000025d5527888888888888788888887550
00777ff8fcccf8fff8fcccf8fff7700000777ff8fffff8fff8fffff8fff7700000777ff8fffff8fff8fffff8fff77000025d5288888788888788887887225520
00000ff8888888fff8888888fff0000000000ff8888888fff8888888fff0000000000ff8888888fff8888888fff0000005525278878888728888888882225250
00000ffffffffff9fffffffffff0000000000ffffffffff9fffffffffff0000000000ffffffffff9fffffffffff000000522228888822222288878882262dd50
00000fffffffff99fffffffffff0000000000fffffffff99fffffffffff0000000000fffffffff99fffffffffff000000522888788825555288888782662d550
00000fffff88ffffff88ffffff00000000000fffff88ffffff88ffffff00000000000fffff88ffffff88ffffff000000052666662222ddd557887888262d2520
000000fffff88888888ffffff0000000000000fffff88888888ffffff0000000000000fffff88888888ffffff00000000566ddddd22666ddd222555266dd2520
0000000fff8888888888fff0000000000000000fff8888888888fff0000000000000000fff8888888888fff0000000000022222ddd2226666622225552d22200
000000000fffffffffffff0000000000000000000fffffffffffff0000000000000000000fffffffffffff00000000005555555500555000005555005555b000
00000000eeeffffffffeee000000000000000000eeeffffffffeee000000000000000000eeeffffffffeee00000000000613476000c4c000009999005aa5bbb0
00000022eeeeeeeeeeeeeee20000000000000022eeeeeeeeeeeeeee20000000000000022eeeeeeeeeeeeeee200000000068269603044400000c99c005a5555b0
000000222eeeeeeeeeeee22220000000000000222eeeeeeeeeeee22220000000000000222eeeeeeeeeeee2222000000006a5c26034585470004444005555a5bb
000002222222eeeeee22222222e00000000002222222eeeeee22222222e00000000002222222eeeeee22222222e000006cdef1a60058507034999943bb5a5555
0000e22222222222222222222eee00000000e22222222222222222222eee00000000e22222222222222222222eee00006ab3d6e600111077395555930b5555a5
0000ee2222222222222222222eeee0000000ee2222222222222222222eeee0000000ee2222222222222222222eeee0006b9dae8600111007005555000bbb5aa5
0000eeee22222222223322222eeee0000000eeee22222222223322222eeee0000000eeee22222222223322222eeee000066666600550550705555550000b5555
0fffeeee22222222333222222eeeeff00fffeeee22222222333222222eeeeff00fffeeee22222222333222222eeeeff000ffff00000770000007777000aaaa00
ffffeeee22222223322222222eeeefffffffeeee22222223322222222eeeefffffffeeee22222223322222222eeeefffffffffff007777000077ff700aaffa00
ffffeeeee2222888888222222eeeefffffffeeeee2222888888222222eeeefffffffeeeee2222888888222222eeeefff00c99c0500777700007cfc700acfca00
0fffeeeee2228888888882222eeeeff00fffeeeee2228888888882222eeeeff00fffeeeee2228888888882222eeeeff00044445500599500007fff700afffa00
0000eeeee222888888888222eeeee0000000eeeee222888888888222eeeee0000000eeeee222888888888222eeeee0000049940500999905302eee2002888203
0000eeeee222888888888222eeee00000000eeeee222888888888222eeee00000000eeeee222888888888222eeee000009ffff95897777953fe222eff82228f3
00000eeee222288888882222eee0000000000eeee222288888882222eee0000000000eeee222288888882222eee0000000ffff050077770000e232e0082b2800
00000eeee222228888822222eee0000000000eeee222228888822222eee0000000000eeee222228888822222eee0000000ffff050077770000e282e008282800
00000000000000000000000000000000888878874444999999999999999999999999444411111111222222223333333344444444555555556666666677777777
00000000007777777777700000000000878888884449999999999999999999999999944411111111222222223333333344444444555555556666666677777777
00000000777777777777777700000000888888884499999999999999999999999999994411111111222222223333333344444444555555556666666677777777
000000cccccccccccccccccccc000000887887884449999999999999999999999999944411111111222222223333333344444444555555556666666677777777
00000cccccccccccccccccccccbb0000888888884444444444444444444444444444444411111111222222223333333344444444555555556666666677777777
0000ccccccccccccccccccccccbbb000878878874ffffffffffffffffffffffffffffff411111111222222223333333344444444555555556666666677777777
000ccccccccccbccccccccccccbbb000888888884ffffffffffffffffffffffffffffff411111111222222223333333344444444555555556666666677777777
000ccccccccccbbbcccccccccccbbb00887888784ff44f444f444f444ff444f444f444f411111111222222223333333344444444555555556666666677777777
00cccccccccccbbbccccccccccccbb00dddddddd4f4fff4f4f4f4f444fff4ff4f4f444f48888888899999999aaaaaaaabbbbbbbbcccccccceeeeeeeeffffffff
00cccccccccccbbbbccccccccccccbb0dddddddd4f4fff44ff444f4f4fff4ff444f4f4f48888888899999999aaaaaaaabbbbbbbbcccccccceeeeeeeeffffffff
00cccccccccccbbbbbccccccccbcccb0dddddddd4f4f4f4f4f4f4f4f4fff4ff4f4f4f4f48888888899999999aaaaaaaabbbbbbbbcccccccceeeeeeeeffffffff
0cccccbbccccbbbbbccccccccbbcccc0dddddddd4f444f4f4f4f4f4f4ff44ff4f4f4f4f48888888899999999aaaaaaaabbbbbbbbcccccccceeeeeeeeffffffff
0cccbbbbccccbbbbbcccccccbbbcccc0dddddddd4ffffffffffffffffffffffffffffff48888888899999999aaaaaaaabbbbbbbbcccccccceeeeeeeeffffffff
0ccbbbbcccccbbbbbccccccbbbbcccccdddddddd4ffffffffffffffffffffffffffffff48888888899999999aaaaaaaabbbbbbbbcccccccceeeeeeeeffffffff
0ccbbbbccccbbbbbcccccccbbbbcccccdddddddd444444444444444444444444444444448888888899999999aaaaaaaabbbbbbbbcccccccceeeeeeeeffffffff
0ccbbbbccccbbccccccccccbbbccccccdddddddd999999999999999999999999999999998888888899999999aaaaaaaabbbbbbbbcccccccceeeeeeeeffffffff
0ccbbbbccccccccccccccccbbbbbcccb005555500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0ccbbbcccccccccccccccccbbbbbccbb005aaaa00003330000033300000331100003550000033300000000000000000000000000000000000000000000000000
0ccbbbcccccccccccccccccbbbbcccbb005aaaa0003333000033330000333110003355000033ee00000000000000000000000000000000000000000000000000
0ccbccccccccccccccccccccccccccbb5577777000333770003dd33000333330003333300033ee30000000000000000000000000000000000000000000000000
00ccccccccccccbbbbbcccccccccccb05588771103333cb0033dd33003333330055333300ee33330000000000000000000000000000000000000000000000000
00cccccccccccbbbbbbbcccccccccc0055887711ccc333333333333331133333355333333ee33333000000000000000000000000000000000000000000000000
00cccccccccbbbbbbbbbbccccccccc0055777770bcc333cbdd3333dd31133311333333553333ee33000000000000000000000000000000000000000000000000
00cbbcccccbbbbbbbbbbbccccccccc0000777770bbc333bbdd3333dd33333311333333553333ee33000000000000000000000000000000000000000000000000
00cbbbcccccccbbbbbbbccccccccc000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000cbbccccccccbbbbbbbcccccccc000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000bbcccccccccccccccccccccc0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000bcccccccccccccccccccc000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000007777777777777777770000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000077777777777777000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
ddddddddddddddccdfdfdfdfdfdfdfdfd4d4d4d4d4d4d4ccdfdfdfdfdfdfdfdfccccccccccccccccdfdfdfdfdfdfdfdfcecececececececccecececececececed4d4d4d4d4d4d4d4d4d4d4d4d4d4d4d4c9c9cfcfcfcfcfcfcfcfcfcfcfcfc9c9dadadadac9c9c9c9c9c9c9c9c9c9c9c9d4d4d4cacecad4cacacaceced4d4caca
ddddddddddddddccdfdfdfdfdfdfdfdf28292a292a292bccdfdfdfdfdfdfdfdfccdac5c6c7c8daccdfdfdfdfdfdfdfdfcecececececececccecececececececed4d4d4d4d4d4d4d4d4d4d4d4d4d4d4d4c9dddddddddddddddddddddddddddcc9dadadac9c9c9c9c9c9c9c9c9c9c9c9c9d4cacaceced4d4cad4cacad4d4cacad4
ddddddddddddddccdfdfdfdfdfdfdfdf2e2c2f2c2f2c2dccdfdfdfdfdfdfdfdfccdad5d6d7d8daccdfdfdfdfdfdfdfdfcecececececececccecececececececed4d4d4d4d4d4d4d4d4d4d4d4d4d4d4d4dddddcdddddddddddddddddddddddcdcdadac9cec9c9c9c9c9c9c9c9dbdbc9c9cacacad4cad4cacacecacecacacacaca
ddddddddddddddccdfdfdfdfdfdfdfdfd4cd373637cdd4ccdfdfdfdfdfdfdfdfccdadadadadadaccdfdfdfdfdfdfdfdfcecececececececccecececececececed4d4d4d4d4d4d4d4d4d4d4d4d4d4d4d4dddddcdddddcdddddddcdcdcdddddcdcdac9c9c9c9c9c4c9c9c9c9c9dbdbc9c9cacececacacecacacececacad4cacece
ddddddddddddddccdfdfdfdfdfdfdfdfd4d4d435d4d4d4ccdfdfdfdfdfdfdfdfccdadadadadadaccdfdfdfdfdfdfdfdfcecececececececccececececececece23232323232323232323232323232323dddddcdddddcdcdddcdcdcdcdcddddddc9c9c9cdc9c9c9c9c9dadac9c9c9c9c9cad4cecad4cecac4caced4cacacacace
ddddddddddddddccdfdfdfdfdfdfdfdfd4d4d435d4d4d4ccdfdfdfdfdfdfdfdfccdadadadadadaccdfdfdfdfdfdfdfdfcecececececececccececececececece23232323232323232323232323232323dddcdddddddcdcdddddddcdcddddddddc9c9c9c9c9c9d9c9c9dadac9c9c9c9c9cacacad4d4cacacacaced4d4cecacaca
23232323232323ccdfdfdfdfdfdfdfdfd4d4d42cd4d4d4ccdfdfdfdfdfdfdfdfccdadadadadadaccdfdfdfdfdfdfdfdfcecececececececccececececececece23232323232323232323232323232323dddddddddddddcdddddddddddddddcdcc9c9c9c9c9c9c9c9c9c9c9c9c9c9c9ddcad4cacacacececad4cacad4cecad4ca
23232323232323ccdfdfdfdfdfdfdfdfd4d4d4d4d4d4d4ccdfdfdfdfdfdfdfdfccccccccccccccccdfdfdfdfdfdfdfdfcecececececececccececececececece23232323232323232323232323232323c9dddddddddddddddddddddddddddcc9c9c9c9c9c9c9c9c9c9c9c9c9ddc9c9c9ced4cad4caced4cad4d4cacad4cacaca
23232323232323ccdfdfdfdfdfdfdfdfd4d4d4d4d4d4d4ccdfdfdfdfdfdfdfdfccdfdfdfdfdfdfccdfdfdfdfdfdfdfdfcecececececececccececececececece23232323232323232323232323232323c9c9cfcfcfcfcfcfcfcfcfcfcfcfc9c9c9c9c9c9c9c9c9c9c9c9c9c9c9c9c9cfcececacaced4cacacad4cacecececad4
23232323232323ccdfdfdfdfdfdfdfdfcecececececececcdfdfdfdfdfdfdfdfccdfdfdfdfdfdfccdfdfdfdfdfdfdfdfcecececececececccececececececececccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
23232323232323ccdfdfdfdfdfdfdfdfcecececececececcdfdfdfdfdfdfdfdfccdfdfdfdfdfdfccdfdfdfdfdfdfdfdfcecececececececccececececececececccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
23232323232323ccdfdfdfdfdfdfdfdfcecececececececcdfdfdfdfdfdfdfdfccdfdfdfdfdfdfccdfdfdfdfdfdfdfdfcecececececececccececececececececccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
__sfx__
00010000000000000000000000000000000000000000e050150501c05021050000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000400000f150000000830009300101000a4000f400114001d4000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000315000000000000010001100011000210000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000002201000000000002200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
011000002835030000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000

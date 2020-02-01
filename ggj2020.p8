pico-8 cartridge // http://www.pico-8.com
version 18
__lua__
--globals--
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
  add(s.scenes, new_factories_scene())
  add(s.scenes, new_global_scene())
  add(s.scenes, new_galactic_scene())
  add(s.scenes, new_universal_scene())
  s.active_scenes={}
  for scene in all(s.scenes) do
   if (scene.unlocked) add(s.active_scenes,scene)
  end
  s.current_scene=1
 end

 s.update=function(s)
  s.active_scenes[s.current_scene]:update()
  for sys in all(s.update_systems) do
   sys.update()
  end

  if (btnp(0)) then
   s.current_scene=max(s.current_scene-1,1)
   manberry.update_icon()
  end
  if (btnp(1)) then
   s.current_scene=min(s.current_scene+1,#s.active_scenes)
   manberry.update_icon()
  end
 end

 s.draw=function(s)
  cls()
  s.active_scenes[s.current_scene]:draw()
  for sys in all(s.draw_systems) do
   sys.draw()
  end
 end

 s:init()
 return s
end

-->8
--scenes--
function new_scene()
 local s={}
 s.name="scene"
 s.update=function(scene) end
 s.draw=function(scene)
  map(scene.background.x,scene.background.y,0,0,16,16)
 end
 s.unlocked=true
 s.background={
  x=0,
  y=0
 }
 return s
end

function new_farm_scene()
 local s=new_scene()
 s.name="farm"
 s.unlocked=true
 return s
end

function new_store_scene()
 local s=new_scene()
 s.name="store"
 s.background.x=32
 return s
end

function new_hr_scene()
 local s=new_scene()
 s.name="hr"
 s.background.x=48
 return s
end

function new_factories_scene()
 local s=new_scene()
 s.name="factories"
 s.background.x=64
 return s
end

function new_global_scene()
 local s=new_scene()
 s.name="global"
 s.background.x=80
 return s
end

function new_galactic_scene()
 local s=new_scene()
 s.name="galactic"
 s.background.x=96
 return s
end

function new_universal_scene()
 local s=new_scene()
 s.name="universal"
 s.background.x=112
 return s
end

-->8
--kitchen--

function lookup_recipe(mixer_contents)
 return false
end

function new_kitchen_scene()
 local s=new_scene()
 s.name="kitchen"
 s.background.x=16

 s.process_mix=false
 s.mix_complete=false
 s.mixer_contents={}

 s.all_ingredients={}
 add(s.all_ingredients, strawberry)
 add(s.all_ingredients, blueberry)
 add(s.all_ingredients, manberry)
 add(s.all_ingredients, globerry)
 add(s.all_ingredients, bigberry)
 add(s.all_ingredients, bangberry)
 add(s.all_ingredients, darkberry)
 add(s.all_ingredients, galactiberry)
 s.selected_ingredient=1
 s.available_ingredients={}
 for i in all(s.all_ingredients) do
  if (i.unlocked) add(s.available_ingredients, i)
 end


 s.update=function(scene)
  if scene.mix_complete then

   scene.current_output.quantity += 1
   if not scene.current_output.unlocked then
    scene.current_output.unlocked=true
    add(scene.available_ingredients, scene.current_output)
   end
   scene.current_output={}

   scene.mixer_contents={}
   scene.mix_complete=false
   scene.process_mix=false
  end

  if scene.process_mix and not scene.mix_complete then
   scene:advance_mix()
  end

  --ingredient list selected--
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
 end

 return s
end

-->8
--ingredients--
strawberry={
 name="strawberry",
 unlocked=true,
 icon=function() return 16 end,
 quantity=10
}

blueberry={
 name="blueberry",
 unlocked=true,
 icon=function() return 17 end,
 quantity=7
}

manberry={
 name="manberry",
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
 name="globerry",
 unlocked=false,
 icon=function() return 23 end,
 quantity=0
}

bigberry={
 name="bigberry",
 unlocked=false,
 icon=function() return 24 end,
 quantity=0
}

bangberry={
 name="bangberry",
 unlocked=false,
 icon=function() return 25 end,
 quantity=0
}

darkberry={
 name="darkberry",
 unlocked=false,
 icon=function() return 26 end,
 quantity=0
}

galactiberry={
 name="galactiberry",
 unlocked=false,
 icon=function() return 27 end,
 quantity=0
}

badjam={
 name="badjam",
 unlocked=false,
 icon=function() return 3 end,
 quantity=0
}

__gfx__
00000000555555555555555555555555555555550000000000000000000000000000000000000000000000000000000000bbbbbbbbbbbbbbbbbbbbbbbbbbbb00
000000000628826006d11d600633326006000060000000000000000000000000000000000000000000000000000000000bbbbbbbbbbbbbbbbbbbbbbbbbbbbbb0
0070070006828860061111600633336006000060000000000000000000000000000000000000000000000000000000000bbbbbbbbbbbbbbbbbbbbbbbbbbbbbb0
00077000068882600611d1600632336006000060000000000000000000000000000000000000000000000000000000000bbbbbbbbbb333bbbbbbbbbb333bbbb0
000770006282888661d111166333323660000006000000000000000000000000000000000000000000000000000000000bbbbbbbbb3333bbbbbbbbb3333bbbb0
0070070068888286611111166332333660000006000000000000000000000000000000000000000000000000000000000bbbbbbbbb38333bbbbbbbb38333bbb0
00000000682828266d11d1d66233332660000006000000000000000000000000000000000000000000000000000000000bbbbbbbb333338bbbbbbb333338bbb0
0000000006666660066666600666666006666660000000000000000000000000000000000000000000000000000000000bbbbb3333333333bbbbbb3833333bb0
0330033000144100044444400aaaaaa00eeeeee00aaaaaa0011111100077770000dddd0000111100000550000deeeeed0bbbb33338338338bbb3333338338bb0
000330000111111044777744aa7777aaee4444eeaa9999aa114444110cccccc00dd111d0011ddd1000555500deeddded0bbbb38333333333bb33333333333bb0
008888001111111147777774a777777ae444444ea999999a14444441cbbcccbcdd1ddd1d11d111d105655650dedeeded0bbb333338bbbbbbbb38333bbbbbbbb0
0888888011111111737777377c7777c7434444349599995942444424bbbcccbbd1dd1d1d1d11d1d155566555dededded0bb33333333bbbbbb333338bbbbbbbb0
08888880111111117777777777777777444444449999999944444444bbccccccd1d1dd1d1d1d11d155566555dedeeeed0bb38338338bbbbb33333333bbbbbbb0
08888880111111117dddddd77dddddd74dddddd49dddddd94dddddd4ccccbbccd1dd11dd1d11dd1105655650deeddddd0bb33333333bbbbb38338338bbbbbbb0
00888800011111107777eee77777eee74444eee49999eee94444eee40cccbbc00d1dddd001d1111000555500dddeee000bbbbbbbbbbbbbbb33333333bbbbbbb0
00088000001111000777eee00777eee00444eee00999eee00444eee00077770000d1dd00001d11000005500000dddee000bbbbbbbbbbbbbbbbbbbbbbbbbbbb00
000070004444444477777777bbbbbb3bcccccccc6666666655555555ffffffffddddd57777777777775dd5777775dddd5555555555dddddddddddd5555dddd55
000077004444444477777777b3bbbb3bcccccccc6666666655555555ffffffffddddd57777777777775dd5777775ddddd555555ddddddddddddddddddddddddd
0000777044444444777777773bbbb3bbcccccccc6666666655555555ffffffffddddd57777777777775dd5777775ddddd555555ddddddddddddddddddddddddd
7777777744444444777777773bbb3bbbcccccccc6666666655555555ffffffffddddd57777777777775dd5777775ddddd555555ddddddddddddddddddddddddd
777777774444444477777777bb3b3bbbcccccccc6666666655555555ffffffffddddd57777777777775dd5777775dddddd5555dddddddddddddddddddddddddd
000077704444444477777777b33bbb3bcccccccc6666666655555555ffffffffddddd57777777777775dd5777775dddddd5555dddddddddddddddddddddddddd
000077004444444477777777bbbbb3bbcccccccc6666666655555555ffffffffddddd57777777777775dd5777775dddddd5555dddddddddddddddddddddddddd
0000700044444444777777773bbbb3bbcccccccc6666666655555555ffffffffddddd57676767676765dd5767675dddddd5555dddddddddddddddddddddddddd
0000000000000000000555000000000000000000dd5555dddd5555dddddddddddddddddd99999999000880000000000067777776666666660000000000000000
0003330000000000055555550003330000033300dd5555dddd5555dddddddddddddddddd9999999900888800000110007ffffff7665555660000000000000000
0033330006600660055555550033330000333300dd5555dd5555555555555555dddddddd9999999908888880000110006fcffcf6665aa5660000000000000000
0038333006600660555555550033333000313330dd5555dd5555555555555555dddddddd99999999888888880001100068ffff86665aa5660000000000000000
0333338006660666555555550333333003333310dd5555dd5555555555555555dddddddd999999990008800011111111f6eeee6f665555660000000000000000
3333333366666666555555553333333333333333dd5555dddd5555dddddddddddddddddd9999999900088000011111106eeeeee6555555550000000000000000
3833833856565656055555503333333331331331dd5555dddd5555dddddddddddddddddd999999990008800000111100eeeeeeee566666650000000000000000
3333333366666666000055003333333333333333dd5555dddd5555dddddddddddddddddd999999990000000000011000eeeeeeee566666650000000000000000
00000000000000000000000000dddddddddddddddddddddddddddd00004444477777777777777777774444000066666666666666666666666666660000000000
0000000000000000000000000dddddddddddddddddd444444444ddd004444447777777fffffffff7777444400667777776666666666666666666666000000000
0000000000000000000000000dddddddd55555555dd4fffffff4ddd00444447777fffffffffffffff7774440067ffffff7665555666666666666666000000000
0000000000000000000000000dd5555555588826ddd48f8f8f84ddd004444477fffffffffffffffff7774440066fcffcf6665aa5777777666666666000000000
0000000000000000000000000ddd628826882886ddd444444444ddd0044447778888888fff8888888f7774400668ffff86665aa7ffffff766555566000000000
0000000000000000000000000ddd682886288826ddd4fffffff4ddd00444777f8fcccf88888fcccf8ff7774006f6eeee6f665555fcffcf6665aa566000000000
0000000000000000000000000ddd6888268828886dd41f1f1f14ddd0044477ff8fcccf8fff8fcccf8fff7740066eeeeee65555558ffff86665aa566000000000
0000000000000000000000000dd62855555555886dd444444444ddd0044777ff8fcccf8fff8fcccf8fff774006eeee777777666feeeeeef66555566000000000
0000000000000000000000000dd68886288268826dd4fffffff4ddd0044444ff8888888fff8888888fff444006eee7ffffff7665555eee655555555000000000
0000000000000000000000000dd6828682886886ddd49f9f9f94ddd0044444ffffffffff9fffffffffff4440066666fcffcf6665aa5eeee56666665000000000
0000000000000000000000000ddd66668882666dddd444444444ddd0044444fffffffff99fffffffffff44400666668ffff86665aa5eeee56666665000000000
0000000000000000000000000ddddd62828886ddddd4f6fff6f4ddd0044444fffff88ffffff88ffffff4444006666f6eeee6f665555666666666666000000000
0000000000000000000000000ddddd68888286ddddd4616f6864ddd00444444fffff88888888ffffff444440066666eeeeee6555555556666666666000000000
0000000000000000000000000ddddd68282826ddddd4666f6664ddd004444444fff8888888888fff4444444006666eeeeeeee566666656666666666000000000
0000000000000000000000000dddddd666666dddddd444444444ddd00444444444fffffffffffff44444444006666eeeeeeee566666656666666666000000000
00000000000000000000000000dddddddddddddddddddddddddddd00004444444eeeffffffffeee4444444000066666666666666666666666666660000000000
00000000000000000000000000dddd555ddd55ddddd555ddd5550000007777777777777777777777777777000099999911111111111111111111110000000000
0000000000000000000000000ddd555555d5555dd55555d5555555d00cccccccccccccccccccccccccccccc00999999911111111111111111111111000000000
0000000000000000000000000ddd555555d55555555555d5555555d00cccccccccccccccccccccccccccccc00999999111611111111111111111111000000000
0000000000000000000000000dd555555555555555555555555555d00ccccbbbbccccccccccbccccccccccb00999999111111111111111111111111000000000
0000000000000000000000000dd555555555555555555555555555d00cccbbbccccbbcbccccbbbbbbcccccb00999911111111811888111111111111000000000
0000000000000000000000000dd555555555555555555555555555d00cccbbcccccbbbbccccccbbbbcccccb00111111111118788878811111111111000000000
0000000000000000000000000ddd555555655555d55555d5555556d00cccbbcccccbbbbcccccbbbbbccccbb00111111111111888888711111111111000000000
0000000000000000000000000ddd66d55d66ddddd66d55d66d5566d00ccccccccbccbbcccccccccbbccccbb00111111111111178781111aaa111111000000000
0000000000000000000000000ddd66dd66666666d66dd666666666d00ccccccccbbcbbbbbbccccccccccccb00111111111111188888711aaa111111000000000
0000000000000000000000000ddd66dd66565656d66dd656565656d00cccccbcccbcccbbcccbbbccccccccc00111111111111187888811aaa111111000000000
0000000000000000000000000ddd66dd66666666d66dd666666666d00ccccbbccbbbbcccccbbbbbcccccccc00111111111111188187811111111111000000000
0000000000000000000000000ddd666dddddddddd666d666ddddddd00ccccbbbccbbbcccccbbbbbcccccbcc00111111111111111111111111111111000000000
0000000000000000000000000d666666666dddd666666666ddddddd00ccbbbbbccbbbccccbbbbbbbcccbbbc00111111111111111111111111111111000000000
0000000000000000000000000d656565656dddd656565656ddddddd00ccccccccccccccccbbbbbbbccccbbc0011111111111111111111cc11111111000000000
0000000000000000000000000d666666666dddd666666666ddddddd00cccccccccccccccccccccccccccccc0011111111111111111111cc1111dd11000000000
00000000000000000000000000dddddddddddddddddddddddddddd0000777777777777777777777777777700001111111111111111111111111dd10000000000
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
000000000fffffffffffff0000000000000000000fffffffffffff0000000000000000000fffffffffffff0000000000fff8888888888fff0000000000000000
00000000eeeffffffffeee000000000000000000eeeffffffffeee000000000000000000eeeffffffffeee0000000000ff888888888888ff0000000000000000
00000022eeeeeeeeeeeeeee20000000000000022eeeeeeeeeeeeeee20000000000000022eeeeeeeeeeeeeee200000000f88888888888888f0000000000000000
000000222eeeeeeeeeeee22220000000000000222eeeeeeeeeeee22220000000000000222eeeeeeeeeeee2222000000088888888888888880000000000000000
000002222222eeeeee22222222e00000000002222222eeeeee22222222e00000000002222222eeeeee22222222e0000085558555858885880000000000000000
0000e22222222222222222222eee00000000e22222222222222222222eee00000000e22222222222222222222eee000085888588858885880000000000000000
0000ee2222222222222222222eeee0000000ee2222222222222222222eeee0000000ee2222222222222222222eeee00085558555858885880000000000000000
0000eeee22222222223322222eeee0000000eeee22222222223322222eeee0000000eeee22222222223322222eeee00088858588858885880000000000000000
0fffeeee22222222333222222eeeeff00fffeeee22222222333222222eeeeff00fffeeee22222222333222222eeeeff085558555855585550000000000000000
ffffeeee22222223322222222eeeefffffffeeee22222223322222222eeeefffffffeeee22222223322222222eeeefff88888888888888880000000000000000
ffffeeeee2222888888222222eeeefffffffeeeee2222888888222222eeeefffffffeeeee2222888888222222eeeefff88888888888888880000000000000000
0fffeeeee2228888888882222eeeeff00fffeeeee2228888888882222eeeeff00fffeeeee2228888888882222eeeeff088888888888888880000000000000000
0000eeeee222888888888222eeeee0000000eeeee222888888888222eeeee0000000eeeee222888888888222eeeee00088888888888888880000000000000000
0000eeeee222888888888222eeee00000000eeeee222888888888222eeee00000000eeeee222888888888222eeee0000f88888888888888f0000000000000000
00000eeee222288888882222eee0000000000eeee222288888882222eee0000000000eeee222288888882222eee00000ff888888888888ff0000000000000000
00000eeee222228888822222eee0000000000eeee222228888822222eee0000000000eeee222228888822222eee00000fff8888888888fff0000000000000000
00000000000000000000000000000000888878874444999999999999999999999999444411111111222222223333333344444444555555556666666677777777
00000000007777777777700000000000878888884449999999999999999999999999944411111111222222223333333344444444555555556666666677777777
00000000777777777777777700000000888888884499999999999999999999999999994411111111222222223333333344444444555555556666666677777777
000000cccccccccccccccccccc000000887887884449999999999999999999999999944411111111222222223333333344444444555555556666666677777777
00000cccccccccccccccccccccbb0000888888884444444444444444444444444444444411111111222222223333333344444444555555556666666677777777
0000ccccccccccccccccccccccbbb000878878874ffffffffffffffffffffffffffffff411111111222222223333333344444444555555556666666677777777
000ccccccccccbccccccccccccbbb000888888884ffffffffffffffffffffffffffffff411111111222222223333333344444444555555556666666677777777
000ccccccccccbbbcccccccccccbbb00887888784ff44f444f444f444ff444f444f444f411111111222222223333333344444444555555556666666677777777
00cccccccccccbbbccccccccccccbb00000000004f4fff4f4f4f4f444fff4ff4f4f444f48888888899999999aaaaaaaabbbbbbbbcccccccceeeeeeeeffffffff
00cccccccccccbbbbccccccccccccbb0000000004f4fff44ff444f4f4fff4ff444f4f4f48888888899999999aaaaaaaabbbbbbbbcccccccceeeeeeeeffffffff
00cccccccccccbbbbbccccccccbcccb0000000004f4f4f4f4f4f4f4f4fff4ff4f4f4f4f48888888899999999aaaaaaaabbbbbbbbcccccccceeeeeeeeffffffff
0cccccbbccccbbbbbccccccccbbcccc0000000004f444f4f4f4f4f4f4ff44ff4f4f4f4f48888888899999999aaaaaaaabbbbbbbbcccccccceeeeeeeeffffffff
0cccbbbbccccbbbbbcccccccbbbcccc0000000004ffffffffffffffffffffffffffffff48888888899999999aaaaaaaabbbbbbbbcccccccceeeeeeeeffffffff
0ccbbbbcccccbbbbbccccccbbbbccccc000000004ffffffffffffffffffffffffffffff48888888899999999aaaaaaaabbbbbbbbcccccccceeeeeeeeffffffff
0ccbbbbccccbbbbbcccccccbbbbccccc00000000444444444444444444444444444444448888888899999999aaaaaaaabbbbbbbbcccccccceeeeeeeeffffffff
0ccbbbbccccbbccccccccccbbbcccccc00000000999999999999999999999999999999998888888899999999aaaaaaaabbbbbbbbcccccccceeeeeeeeffffffff
0ccbbbbccccccccccccccccbbbbbcccb000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0ccbbbcccccccccccccccccbbbbbccbb000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0ccbbbcccccccccccccccccbbbbcccbb000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0ccbccccccccccccccccccccccccccbb000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00ccccccccccccbbbbbcccccccccccb0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00cccccccccccbbbbbbbcccccccccc00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00cccccccccbbbbbbbbbbccccccccc00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00cbbcccccbbbbbbbbbbbccccccccc00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00cbbbcccccccbbbbbbbccccccccc000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000cbbccccccccbbbbbbbcccccccc000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000bbcccccccccccccccccccccc0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000bcccccccccccccccccccc000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000007777777777777777770000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000077777777777777000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
242424242424242424242424242424243838383838383821272727272727272721212121212121212727272727272727252525252525252525ce25252525252538383838383838383838383838383838c9c9cfcfcfcfcfcfcfcfcfcfcfcfc9c9dadadadac9c9c9c9c9c9c9c9c9c9c9c9383838caceca38cacacacece3838caca
2424242424242424242424242424242428292a292a292b2127272727272727272139c5c6c7c839212727272727272727252525252525252525ce25252525252538383838383838383838383838383838c9dddddddddddddddddddddddddddcc9dadadac9c9c9c9c9c9c9c9c9c9c9c9c938cacacece3838ca38caca3838caca38
242424242424242424242424242424242e2c2f2c2f2c2d2127272727272727272139d5d6d7d839212727272727272727252525252525252525ce25252525252538383838383838383838383838383838dddddcdddddddddddddddddddddddcdcdadac9cec9c9c9c9c9c9c9c9dbdbc9c9cacaca38ca38cacacecacecacacacaca
24242424242424242424242424242424382637363726382127272727272727272139dadadada39212727272727272727252525252525252525ce25252525252538383838383838383838383838383838dddddcdddddcdddddddcdcdcdddddcdcdac9c9c9c9c9c4c9c9c9c9c9dbdbc9c9cacececacacecacacececaca38cacece
232323232323232323232323232323233838383538383821272727272727272721dadadadada39212727272727272727252525252525252525ce25252525252523232323232323232323232323232323dddddcdddddcdcdddcdcdcdcdcddddddc9c9c9cdc9c9c9c9c9dadac9c9c9c9c9ca38ceca38cecac4cace38cacacacace
232323232323232323232323232323233838383538383821272727272727272721dadadadada39212727272727272727252525252525252525ce25252525252523232323232323232323232323232323dddcdddddddcdcdddddddcdcddddddddc9c9c9c9c9c9d9c9c9dadac9c9c9c9c9cacaca3838cacacacace3838cecacaca
232323232323232323232323232323233838382c3838382127272727272727272139dadadada39212727272727272727252525252525252525ce25252525252523232323232323232323232323232323dddddddddddddcdddddddddddddddcdcc9c9c9c9c9c9c9c9c9c9c9c9c9c9c9ddca38cacacacececa38caca38ceca38ca
232323232323232323232323232323233838383838383821272727272727272721212121212121212727272727272727252525252525252525ce25252525252523232323232323232323232323232323c9dddddddddddddddddddddddddddcc9c9c9c9c9c9c9c9c9c9c9c9c9ddc9c9c9ce38ca38cace38ca3838caca38cacaca
232323232323232323232323232323233838383838383821272727272727272727272727272727212727272727272727252525252525252525ce25252525252523232323232323232323232323232323c9c9cfcfcfcfcfcfcfcfcfcfcfcfc9c9c9c9c9c9c9c9c9c9c9c9c9c9c9c9c9cfcececacace38cacaca38cacecececa38
21212121212121212121212121212121252525252525252127272727272727273a27252527acad212727272727272727252525252525252525ce25252525252521212121212121212121212121212121212121212121212121212121212121212121212121212121212121212121212121212121212121212121212121212121
21212121212121212121212121212121252525252525252127272727272727273b27252527bcbd212727272727272727252525252525252525ce25252525252521212121212121212121212121212121212121212121212121212121212121212121212121212121212121212121212121212121212121212121212121212121
2121212121212121212121212121212125252525252525212727272727272727272727272727272127272727272727272525252525252525252525252525252521212121212121212121212121212121212121212121212121212121212121212121212121212121212121212121212121212121212121212121212121212121
21212121212121212121212121212121212121212121212121212121212121212121212121212121212121212121212121212121212121212121212121212121212121212121212121212121212121212121cccccccc21212121cccccccc21212121212121212121212121212121212121212121212121212121212121212121
21212121212121212121212121212121212121212121212121212121212121212121212121212121212121212121cccccccccccccccccccccccccccccccccccccccc2121212121212121212121212121cccccccccccccccccccccccccccccccccccccc2121212121212121212121212121212121212121212121212121212121
212121212121212121212121212121212121212121212121212121212121212121212121212121212121212121212121cccccccccccccccccccccccccccccccccccc2121212121212121212121212121cccccccccccccccccccccccccccccccccccc212121212121212121212121212121212121212121212121212121212121
2121212121212121212121212121212121212121212121212121212121212121212121212121212121212121212121212121212121212121212121212121212121212121212121212121212121212121212121212121212121212121212121212121212121212121212121212121212121212121212121212121212121212121

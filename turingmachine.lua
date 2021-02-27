-- Turing Machine
-- , .  .   .    .     .      .       .
-- . ,  .   .    .     .      .       .
-- . .  ,   .    .     .      .       .
-- . .  .   ,    .     .      .       .
-- . .  .   .    ,     .      .       .
-- . .  .   .    .     ,      .       .
-- . .  .   .    .     .      ,       .

local MusicUtil = require "musicutil"

hs = include('awake/lib/halfsecond')

local CLOCK_DIVS = { 1/64, 1/32, 1/16, 1/8, 1/4, 1/2, 1, 2, 4, 8, 16, 32, 64 }
local alt = false
local value = math.floor(math.random() * math.pow(2, 16))
local rings = {}
rings[1] = 65535
rings[2] = 43690
rings[3] = 18724
rings[4] = 34952
rings[5] = 16912
rings[6] = 2080
rings[7] = 8256
rings[8] = 32896
rings[9] = 256
rings[10] = 512
rings[11] = 1024
rings[12] = 2048
rings[13] = 4096
rings[14] = 8192
rings[15] = 16384
rings[16] = 32768

engine.name = "PolyPerc"

local function scale()
  return MusicUtil.generate_scale(24 + params:get("root") % 12, params:string("scale"), 8)
end

local function get_bits(val, n)
  local bits = {}
  for i=1,n do
    bits[n-i+1] = val & 1
    val = val >> 1
  end
  return bits
end

local function loop()
  while true do
    clock.sync(CLOCK_DIVS[params:get("clock_div")])
    
    local lsb = value & 1
    if math.random() * 10 <= params:get("fate") then
      if lsb == 1 then lsb = 0 else lsb = 1 end
    end
    
    if lsb == 1 then value = value >> 1 |  rings[params:get("ring")] end
    if lsb == 0 then value = value >> 1 & ~rings[params:get("ring")] end
    
    transpose = util.linlin(0, 255, -params:get("rift"), params:get("rift"), value & 255)
    note = MusicUtil.snap_note_to_array(params:get("root") + transpose, scale())
    engine.hz(MusicUtil.note_num_to_freq(note))

    redraw()
  end
end

function init()
  params:add{
    type="number", id="root",
    min=24, max=128, default=60,
    formatter=function (p)return MusicUtil.note_num_to_name(p:get(), true)end
  }
  params:add{
    type="number", id="scale",
    min=1, max=#MusicUtil.SCALES, default=1,
    formatter=function (p) return MusicUtil.SCALES[p:get()].name end
  }
  params:add{
    type="option", id="clock_div", options=CLOCK_DIVS,
    default=6
  }

  params:add_number("fate", "fate", 0, 10, 0)
  params:add_number("rift",       "rift",       0, 48, 12)
  params:add_number("ring",       "ring",       1, 16, 16)

  params:add{
    type="control", id="cutoff",
    controlspec=controlspec.new(50, 5000, 'exp', 0, 500, 'hz'),
    action=function() engine.cutoff(params:get("cutoff")) end
  }
  params:add{
    type="control", id="release",
    controlspec=controlspec.new(0.1, 10, 'lin', 0, 0.5, 's'),
    action=function() engine.release(params:get("release")) end
  }

  engine.amp(1.0)
  engine.cutoff(params:get("cutoff"))
  engine.release(params:get("release"))
  hs.init()

  clock.run(loop)
end

function key(n,z) end

function enc(n,d)
  if n==1 then params:delta("fate", d) end
  if n==2 then params:delta("rift",       d) end
  if n==3 then params:delta("ring",       d) end

  redraw()
end

function redraw()
  screen.clear()
  
  bits = get_bits(value, 16)
  for i=1, 16 do
    screen.rect((i-1) * 128/16 + 3, 1, 2, 50) 
    screen.level(bits[i] == 1 and 15 or 1)
    screen.fill()
  end
  
  screen.level(15)
  
  screen.move(65, 50)
  screen.line_rel(0, 3)
  screen.line_rel(63, 0)
  screen.line_rel(0, -3)
  screen.stroke()
  
  screen.level(15)
  
  screen.move(1, 62)
  screen.text("fate: "..params:get("fate"))
  screen.move(50, 62)
  screen.text("rift: "..params:get("rift"))
  screen.move(95, 62)
  screen.text("ring: "..params:get("ring"))

  screen.update()
end
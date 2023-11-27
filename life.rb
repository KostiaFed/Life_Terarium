WINDOW_SIZE_COO = 0.8 #Use it to correct window size
def self.ws(convert)
  convert * WINDOW_SIZE_COO
end

CELL_SIZE = 10 * WINDOW_SIZE_COO

require 'ruby2d'

set width: ws(1200), height: ws(990)

###############################################################
#
#                       RULES CONSTANTS
#                        
###############################################################

HP_PRICE = 25
BRAIN_START = 280
WORLD_COLOR = '#3b3b3b'
SEED = Random.new
DAY = 20
NIGHT = 0
SUN_TAX = 8

TRIGGERS = %i[
  nothing_happens
  is_day
  is_night
  alone
  not_alone
  sight_like_me
  sight_alive
  sight_corpse
  sight_free
  memory_like_me
  memory_empty
  memory_not_empty
]

# to donate_energy need to know minimal portion of donation
REACTIONS = %i[
  born
  photosynthesis
  burst
  move
  grow_hp
  suck
  digest
  hunt
  change_sight_to_next
  change_sight_to_north
  change_sight_to_west
  change_sight_to_south
  change_sight_to_east
  remember_color
  next_memory
  forget_actual_memoria
  forget_last_memoria
  clear_memory
]

ORGANS = %i[
]

BRAIN_MUTATORS = %i[
  new_neiron_reaction
  delete_neiron
  increment_width
  decrement_width
  delete_reaction
]

ORGAN_MUTATORS = %i[
  delete_organ
  add_organ
]

LENTHOFDAY = 100
DAYLONGER = 200
PAUSE = false

###############################################################
#
#                       TECHNICAL CONSTANTS
#                        
###############################################################

BRAINS_TEXTS = []

###############################################################
#
#                       CONTROL PANEL
#                        
###############################################################

BACTERIA_PREVIEW = Square.new(x: ws(1010), y: ws(10), size: ws(180), color: '#aaaaaa')

BRAIN_TEXT_SIZE = 10

Rectangle.new(
  x: ws(1010), y: ws(700),
  width: ws(2), height: ws(150),
  color: 'white'
)

Rectangle.new(
  x: ws(1010), y: ws(700),
  width: ws(180), height: ws(2),
  color: 'white'
)

load_menu = []

#load_menu_titles
LMT = []

load_menu_button_first_x = ws(1015)
load_menu_button_first_y = ws(705)
load_menu_width = ws(170)
load_menu_height = ws(20)
load_menu_void = ws(2)
load_menu_count = 5

load_menu_full_height = load_menu_height * load_menu_count + load_menu_void * load_menu_count

load_menu_count.times do |i|
  load_menu.push(Rectangle.new(
    x: ws(1015), y: ws(705 + i*22),
    width: ws(170), height: ws(20),
    color: '#c2c2c2'
  ))
  LMT.push(
    Text.new(
      '',
      x: ws(1015), y: ws(705 + i*22),
      size: ws(18),
      color: 'black'
    )
  )
end

save_button_x = ws(1010)
save_button_y = ws(880)
save_button_width = ws(180)
save_button_height = ws(20)

save_button = Rectangle.new(
  x: save_button_x, y: save_button_y,
  width: save_button_width, height: save_button_height,
  color: 'white'
)

def clicked(button)
  back_color = button.color
  button.color = 'gray'
  sleep(0.2)
  button.color = back_color
end

Text.new(
  'SAVE',
  x: ws(1075), y: ws(878),
  size: ws(18),
  color: 'black'
)

population_text = Text.new(
  'World population: 0',
  x: ws(1010), y: ws(900),
  size: ws(16),
  color: 'white'
)

NAME_TEXT = Text.new(
  'Name: -',
  x: ws(1010), y: ws(BRAIN_START - 80),
  size: ws(20),
  color: 'white'
)

DISCRIPTION_TEXT = Text.new(
  'Discription: -',
  x: ws(1010), y: ws(BRAIN_START - 60),
  size: ws(20),
  color: 'white'
)

ENERGY_TEXT = Text.new(
  'Energy: 0',
  x: ws(1010), y: ws(BRAIN_START - 40),
  size: ws(20),
  color: 'white'
)

HP_TEXT = Text.new(
  'HP: 0',
  x: ws(1010), y: ws(BRAIN_START - 20),
  size: ws(20),
  color: 'white'
)

###############################################################
#
#                            SUN
#                        
###############################################################

class Sun
  def initialize
    @ite = 0
  end

  def is_night
    return 'Night' if @ite > LENTHOFDAY + DAYLONGER

    'Day'
  end

  def photon
    return NIGHT if @ite > LENTHOFDAY + DAYLONGER

    DAY
  end

  def next_tact
    @ite += 1
    @ite = 0 if @ite == LENTHOFDAY * 2 + DAYLONGER
  end
end

###################################################################################

    #           #       ####      ######   #         ###
    #           #      #    #     #     #  #         #  ##
    #     #     #     #      #    ######   #         #    ##
    #    # #    #     #      #    ##       #         #    ##
    #   #   #   #      #    #     # ##     #         #  ##
    ####     ####       ####      #   ##   ########  ###

###################################################################################

class World
  def initialize
    @sun = Sun.new
    @map = []
    @life = []
    @saves = []
    
    Dir["saves/*"].each do |save|
      save.slice! "saves/"
      add_save(save)
    end

    100.times do |j|
      @map.push([])
      100.times do |i|
        @map[j].push(Cell.new(Square.new(x: i * CELL_SIZE, y: j * CELL_SIZE, size: CELL_SIZE, color: WORLD_COLOR), i, j))
      end
    end
  end

  def add_save(save)
    @saves.push(save)
    LMT[@saves.size-1].text = save if @saves.size <= LMT.size
  end

  def get_place(x, y)
    y = 0 if y >= @map.size
    y = @map.size - 1 if y < 0
    x = 0 if x >= @map.size
    x = @map.size - 1 if x < 0

    @map[y][x]
  end

  attr_accessor :life, :map, :sun, :saves
end

###############################################################
# 
#                             CELL
#
###############################################################
class Cell
  attr_accessor :neighs, :homie, :sun_tax

  def initialize(body, x_id, y_id)
    @body = body
    @x_id = x_id
    @y_id = y_id
    @homie = nil

    if (@y_id > 5 && @y_id < 25) || (@x_id > 5 && @x_id < 25) || (@y_id > 65 && @y_id < 85) || (@x_id > 65 && @x_id < 88)
      @sun_tax = SUN_TAX
    else
      @sun_tax = 0
    end
  end

  def cash_neigh
    y = get_y
    x = get_x

    @neighs = [
      # zero zero
      WORLD.get_place(x, y + 1),
      WORLD.get_place(x, y - 1),
      WORLD.get_place(x + 1, y),
      WORLD.get_place(x + 1, y + 1),
      WORLD.get_place(x + 1, y - 1),
      WORLD.get_place(x - 1, y),
      WORLD.get_place(x - 1, y + 1),
      WORLD.get_place(x - 1, y - 1)
    ]
  end

  def sight_neigh(n)
    @neighs[n]
  end

  def alives
    alives = []
    neighs.each do |neigh|
      alives.push(neigh) if !neigh.homie.nil? && !neigh.homie.corpse
    end

    alives
  end

  def corpses
    homies = []
    neighs.each do |neigh|
      homies.push(neigh) if !neigh.homie.nil? && neigh.homie.corpse
    end

    homies
  end

  def homies
    homies = []
    neighs.each do |neigh|
      homies.push(neigh) unless neigh.homie.nil?
    end

    homies
  end

  def free
    free = []
    neighs.each do |neigh|
      free.push(neigh) if neigh.homie.nil?
    end

    free
  end

  def get_y
    @y_id
  end

  def get_x
    @x_id
  end

  def set_color(color)
    @body.color = color
  end
end

WORLD = World.new

###############################################################
#
#                            NEIRON
#                        
###############################################################

class Neiron
###############################################################
  #### TRIGGERS (always return boolean)
  def self.alone(bacteria)
    bacteria.current_cell.alives.size == 0
  end

  def self.not_alone(bacteria)
    bacteria.current_cell.alives.size != 0
  end

  def self.sight_like_me(bacteria)
    sight = bacteria.current_cell.sight_neigh(bacteria.sight)
    !sight.homie.nil? ? how_far_color(sight.homie.color, bacteria.color) < 5 : false
  end

  def self.sight_alive(bacteria)
    sight = bacteria.current_cell.sight_neigh(bacteria.sight)
    !sight.homie.nil? ? !sight.homie.corpse : false
  end

  def self.sight_corpse(bacteria)
    sight = bacteria.current_cell.sight_neigh(bacteria.sight)
    !sight.homie.nil? ? sight.homie.corpse : false
  end

  def self.sight_free(bacteria)
    bacteria.current_cell.sight_neigh(bacteria.sight).homie.nil?
  end

  def self.memory_like_me(bacteria)
    return if bacteria.memory.size == 0

    how_far_color(bacteria.memory[bacteria.actual_memory], bacteria.color) < 5
  end

  def self.memory_empty(bacteria)
    bacteria.memory.size == 0
  end

  def self.memory_not_empty(bacteria)
    bacteria.memory.size != 0
  end

  def self.clear_memory(bacteria)
    bacteria.memory.clear
  end

  def self.nothing_happens(bacteria)
    true
  end

  def self.is_day(bacteria)
    !WORLD.sun.is_night
  end

  def self.is_night(bacteria)
    WORLD.sun.is_night
  end

  ##########################################################
  #### REACTIONS
  def self.change_sight_to_east(bacteria)
    bacteria.sight = 4
  end

  def self.change_sight_to_south(bacteria)
    bacteria.sight = 6
  end

  def self.change_sight_to_west(bacteria)
    bacteria.sight = 3
  end

  def self.change_sight_to_north(bacteria)
    bacteria.sight = 1
  end

  def self.change_sight_to_next(bacteria)
    bacteria.sight += 1
    bacteria.sight = 0 if bacteria.sight > 7
  end

  def self.burst(bacteria)
    # kill all alive in 3n3
    bacteria.current_cell.homies.each do |sad|
      sad.homie.death
    end

    bacteria.death
  end

  def self.move(bacteria)
    current_cell = bacteria.current_cell
    sight = bacteria.current_cell.sight_neigh(bacteria.sight)
    place = sight.homie if sight.homie.nil?
    return if place.nil?

    current_cell.set_color(WORLD_COLOR)
    current_cell.homie = nil

    bacteria.current_cell = place
    bacteria.current_cell.homie = bacteria
    bacteria.current_cell.set_color(bacteria.color)
  end

  def self.grow_hp(bacteria)
    return if bacteria.energy <= HP_PRICE

    bacteria.hp += 1
    bacteria.energy -= HP_PRICE
  end

  def self.suck(bacteria)
    sight = bacteria.current_cell.sight_neigh(bacteria.sight)
    target = sight.homie if !sight.homie.nil? && !sight.homie.corpse

    if !target.nil?
      suck_count = bacteria.hp * HP_PRICE
      if suck_count >= target.energy
        bacteria.energy += suck_count
        target.energy -= suck_count
      else
        bacteria.energy += target.energy
        target.energy = 0
      end
    end
  end

  def self.digest(bacteria)
    sight = bacteria.current_cell.sight_neigh(bacteria.sight)
    target = sight.homie if !sight.homie.nil? && sight.homie.corpse

    unless target.nil?
      bacteria.energy += target.hp * HP_PRICE
      target.energy = 0
      target.disappeared = true
    end
  end

  def self.hunt(bacteria)
    sight = bacteria.current_cell.sight_neigh(bacteria.sight)
    target = sight.homie if !sight.homie.nil? && !sight.homie.corpse

    if !target.nil? && (target.hp <= bacteria.hp)
      bacteria.energy += target.energy + target.hp * HP_PRICE
      target.full_death
    end
  end

  def self.photosynthesis(bacteria)
    pot_b = WORLD.sun.photon - bacteria.current_cell.sun_tax
    buff = 0
    buff = pot_b if pot_b
    bacteria.energy += buff
  end

  def self.born(bacteria)
    return if bacteria.energy < HP_PRICE * 2

    free = bacteria.current_cell.free
    return unless free.size > 1

    bacteria.energy -= HP_PRICE * 2
    2.times do
      WORLD.life.push(return_babie(bacteria, directions(free)))
      free = bacteria.current_cell.free
    end

    bacteria.full_death
  end

  def self.remember_color(bacteria)
    return if bacteria.current_cell.sight_neigh(bacteria.sight).homie.nil?

    bacteria.memory.push(bacteria.current_cell.sight_neigh(bacteria.sight).homie.color)
  end

  def self.next_memory(bacteria)
    if bacteria.memory.size - 1 > bacteria.actual_memory
      bacteria.actual_memory += 1
    else
      bacteria.actual_memory = 0
    end
  end

  def self.remember_hp(bacteria)
    bacteria.memory.push(bacteria.hp)
  end

  def self.remember_energy(bacteria)
    bacteria.memory.push(bacteria.energy)
  end

  def self.forget_actual_memoria(bacteria)
    bacteria.memory.delete_at(bacteria.actual_memory) 
    bacteria.actual_memory = 0
  end

  def self.forget_last_memoria(bacteria)
    bacteria.memory.pop
  end

  ####################################################
  ### HELPERS

  def self.print_brain(brain)
    string = []
    brain.each do |key, value|
      value.each do |val|
        string.push(key.to_s + ': ' + REACTIONS[val[0]].to_s + ' | ' + val[1].to_s)
      end
    end
    string
  end

  def self.return_babie(bacteria, place)
    energy = bacteria.energy / 2

    # There sometimes happens mutations

    seeds = [
      SEED.rand(20),
      SEED.rand(30)
    ]

    color = color_mutane(bacteria.color)
    brain = brain_mutane(bacteria.brain, seeds[0])
    organs = organs_mutane(bacteria.organs, seeds[1])

    mutated = false

    seeds.each do |seed|
      mutated = true if seed == 0
    end

    unless mutated
      name = bacteria.name
      discription = bacteria.discription
    end

    name ||= 'Unknown'
    discription ||= 'Unknown'

    Bacteria.new(color, place, energy, brain, bacteria.memory.clone, organs, name, discription)
  end

  def self.how_far_color(color1, color2)
    return 255 if color1.nil? || color2.nil?
    return 255 if color1.size != 7 || color2.size != 7 || color1[0] != '#' || color2[0] != '#'

    rgb1 = [
      color1[1..2].hex,
      color1[3..4].hex,
      color1[5..6].hex
    ]

    rgb2 = [
      color2[1..2].hex,
      color2[3..4].hex,
      color2[5..6].hex
    ]

    rgb00 = rgb1[0] - rgb2[0]
    rgb00 *= -1 if rgb00 < 0
    rgb01 = rgb1[1] - rgb2[1]
    rgb01 *= -1 if rgb01 < 0
    rgb02 = rgb1[2] - rgb2[2]
    rgb02 *= -1 if rgb02 < 0

    rgb00 + rgb01 + rgb02
  end

  def self.directions(places)
    return nil if places.size == 0

    dir = SEED.rand(places.size)

    places[dir]
  end

  def self.just_directions
    SEED.rand(8)
  end

  ######################################################
  ### MUTATORS

  def self.color_mutane(color)
    rgb = [
      color[1..2].hex,
      color[3..4].hex,
      color[5..6].hex
    ]

    seeded = SEED.rand(3)
    formed = SEED.rand(2)

    rgb[seeded] += if formed == 0
                     1
                   else
                     -1
                   end

    rgb[seeded] = 254 if rgb[seeded] > 254
    rgb[seeded] = 127 if rgb[seeded] < 127

    '#' + rgb[0].to_s(16).rjust(2, '0') + rgb[1].to_s(16).rjust(2, '0') + rgb[2].to_s(16).rjust(2, '0')
  end

  #### ORGANS MUTATORS ####

  def self.delete_organ(organs)
    return if organs.empty?

    organed = SEED.rand(organs.size)
    organs.keys[organed] = organs.keys[organed] - 1 unless organs.keys[organed] < 1

    organs
  end

  def self.add_organ(organs)
    organed = SEED.rand(ORGANS.size)
    organ = ORGANS[organed]

    unless organs[organ].nil?
      organs[organ] = organs[organ] + 1 || 0
    else
      organs[organ] = 0
    end

  end

  def self.organs_mutane(old_organs, seeded)
    return if ORGANS.size == 0

    organs = {}

    old_organs.each do |key, old_organ|
      organs[key] = old_organ.clone
    end

    return organs unless seeded == 0

    formed = SEED.rand(2)

    organs = Neiron.send(ORGAN_MUTATORS[formed], organs)

    organs
  end

  #### MUTATOR METHODS ####

  def self.delete_reaction(brain)
    return if brain.empty?

    neironed = SEED.rand(brain.size)
    neiron = brain.keys[neironed]
    reaction = SEED.rand(brain[neiron].size) unless brain[neiron].size == 0 
    
    brain[neiron].delete_at(brain[neiron].index(reaction) || brain[neiron].length)

    brain
  end

  def self.decrement_width(brain)
    return if brain.empty?

    neironed = SEED.rand(brain.size)
    neiron = brain.keys[neironed]
    reaction = SEED.rand(brain[neiron].size) unless brain[neiron].size == 0
    
    brain[neiron][reaction][1] += -1
    brain[neiron][reaction][1] = -100 if brain[neiron][reaction][1] < -100

    brain
  end

  def self.increment_width(brain)
    return if brain.empty?

    neironed = SEED.rand(brain.size)
    neiron = brain.keys[neironed]
    reaction = SEED.rand(brain[neiron].size) unless brain[neiron].size == 0
    
    brain[neiron][reaction][1] += 1

    brain
  end

  def self.delete_neiron(brain)
    return if brain.empty?
    
    neironed = SEED.rand(brain.size)
    neiron = brain.keys[neironed]

    brain.delete(neiron)

    brain
  end

  def self.new_neiron_reaction(brain)
    neironed = SEED.rand(TRIGGERS.size)
    neiron = TRIGGERS[neironed]

    unless brain[neiron].nil?
      brain[neiron].push([SEED.rand(REACTIONS.size), 0])
    else
      brain[neiron] = [[SEED.rand(REACTIONS.size), 0]]
    end

    brain
  end

  def self.brain_mutane(old_brain, seeded)
    brain = {}
    
    old_brain.each do |key, old_value|
      old_value.each do |old_reaction|
        unless brain[key].nil?
          brain[key].push(old_reaction.clone)
        else
          brain[key] = [old_reaction.clone]
        end
      end
    end

    return brain unless seeded == 0

    formed = SEED.rand(5)

    brain = Neiron.send(BRAIN_MUTATORS[formed], brain)

    brain
  end
end

###############################################################
#
#                           BACTERIA
#                        
###############################################################

class Bacteria
  attr_accessor :disappeared, :color, :current_cell, :energy, :brain, :corpse
  attr_accessor :sight, :hp, :name, :discription, :memory, :actual_memory, :organs

  def initialize(color, current_cell, energy, brain, memory, organs,
    name = 'Unknown', discription = 'Unknown')

    @color = color

    if current_cell != nil
      set_current_cell(current_cell)
    end

    @energy = energy
    @disappeared = false
    @corpse = false
    @brain = brain
    @sight = Neiron.just_directions
    @hp = 1
    @name = name
    @discription = discription
    @memory = memory
    @organs = organs
    @actual_memory = 0
  end

  def set_current_cell(current_cell)
    @current_cell = current_cell
    @current_cell.set_color(color)
    @current_cell.homie = self
  end

  def self.deserialize(file_name)
    file_name = 'saves/' + file_name
    return unless File.exist?(file_name)
    hash_as_string = nil
    File.open(file_name, 'r') { |f| hash_as_string = f.read }
    bacteria = eval(hash_as_string)

    color = bacteria[:color]
    energy = bacteria[:energy]
    memory = bacteria[:memory]
    brain = bacteria[:brain]
    organs = bacteria[:organs] || {}
    name = bacteria[:name]
    discription = bacteria[:discription]

    Bacteria.new(color, nil, energy, brain, memory, organs, name, discription)
  end

  def serialize(name, discription)
    @name = name
    @discription = discription

    save_hash = {
      name: @name,
      discription: @discription,
      color: @color,
      memory: @memory,
      organs: @organs,
      energy: @energy,
      brain: @brain
    }
    Dir.mkdir("saves") unless Dir.exist?("saves")
    File.open('saves/' + name, 'w') { |f| f.write save_hash.to_s}
  end

  def full_death
    @energy = 0
    @disappeared = true
  end

  #REFACTORY!
  def add_energy
    death if @energy <= 0

    return if corpse || disappeared || brain.empty?

    queue = []

    TRIGGERS.each do |neiron_name|
      queue.push(neiron_name) if Neiron.send(neiron_name, self) && !brain[neiron_name].nil?
    end

    return if queue.empty?

    reactions_queue = []

    queue.each do |neiron_name|
      brain[neiron_name].each do |reaction|
        reactions_queue.push(reaction)
      end
    end

    while reactions_queue.size > 1 do
      temp_r_queue = []

      reactions_queue.each do |reaction|
        temp_r_queue.push(reaction) if SEED.rand(200) < reaction[1] + 100
      end

      unless reactions_queue.size - temp_r_queue.size < 1
        temp_r_queue.each do |tmp_r| 
          reactions_queue.delete_at(reactions_queue.index(tmp_r) || reactions_queue.length) 
        end
      end
    end

    @energy -= 1
    Neiron.send(REACTIONS[reactions_queue[0][0]], self)
  end

  def death
    @corpse = true
    @current_cell.set_color(dead_color)
  end

  def dead_color
    rgb = [
      color[1..2].hex,
      color[3..4].hex,
      color[5..6].hex
    ]

    rgb[0] -= 127
    rgb[1] -= 127
    rgb[2] -= 127

    '#' + rgb[0].to_s(16).rjust(2, '0') + rgb[1].to_s(16).rjust(2, '0') + rgb[2].to_s(16).rjust(2, '0')
  end
end

chosen = nil
bacteria_buffer = nil

def coordinate_in_form(x, y, form_x, form_y, form_width, form_height)
  x > form_x && y > form_y && x < form_x + form_width && y < form_y + form_height
end

load_file_name = nil

on :mouse_down do |event|
  # Read the button event
  case event.button
  when :left
    x = (event.x / CELL_SIZE).to_i
    y = (event.y / CELL_SIZE).to_i

    if coordinate_in_form(event.x, event.y, save_button_x, save_button_y, save_button_width, save_button_height)
      
      return if chosen.nil?

      PAUSE = true

      Thread.new { p 'Type new bacteria name'
      name = gets.chomp
      p 'Type new bacteria discription'
      discription = gets.chomp
      chosen.serialize(name, discription)
      WORLD.add_save(name)
      Thread.new { clicked(save_button) } }

    elsif coordinate_in_form(event.x, event.y, load_menu_button_first_x, load_menu_button_first_y, load_menu_width, load_menu_full_height)
      

      selected = ((event.y - load_menu_button_first_y) / (load_menu_full_height / load_menu_count)).to_i
      load_file_name = WORLD.saves[selected]
      bacteria_buffer = Bacteria.deserialize(load_file_name)   
      chosen =   bacteria_buffer
      Thread.new { clicked(load_menu[selected]) }


    elsif bacteria_buffer != nil


      current_cell = WORLD.get_place(x, y)
      current_cell.homie = bacteria_buffer
      bacteria_buffer.set_current_cell current_cell
      WORLD.life.push(bacteria_buffer)
      bacteria_buffer = nil


    else


      chosen = WORLD.get_place(x, y).homie

      
    end
  end
end

def clear_unused_lines(used_lines)
  temp_used_lines = used_lines

  if used_lines < BRAINS_TEXTS.size
    (BRAINS_TEXTS.size - used_lines).times do
      BRAINS_TEXTS[temp_used_lines].text = ''
      temp_used_lines += 1
    end
  end
end

def add_line(text, used_lines)
  if BRAINS_TEXTS[used_lines].nil?
    BRAINS_TEXTS.push(Text.new(
      text,
      x: ws(1010), y: ws(BRAIN_START + used_lines * 20),
      size: ws(BRAIN_TEXT_SIZE),
      color: 'white'
    ))
  else
    BRAINS_TEXTS[used_lines].text = text
  end

  used_lines += 1
end

def set_bacteria_info(bacteria)
  BACTERIA_PREVIEW.color = bacteria.color
  NAME_TEXT.text = 'Name: ' + bacteria.name
  DISCRIPTION_TEXT.text = 'Discription: ' + bacteria.discription
  ENERGY_TEXT.text = 'Energy: ' + bacteria.energy.to_s
  HP_TEXT.text = 'HP: ' + bacteria.hp.to_s

  used_lines = 0
  Neiron.print_brain(bacteria.brain).each do |text|
    used_lines = add_line(text, used_lines)
  end

  used_lines = add_line(bacteria.organs.to_s, used_lines)
  
  used_lines = add_line(bacteria.memory.to_s, used_lines)

  clear_unused_lines(used_lines)
end

WORLD.map.each do |row|
  row.each do |cell|
    cell.cash_neigh
  end
end

default_bacteria = Bacteria.new(WORLD_COLOR, nil, 0, {}, [], [], 'Void', '-')

on :key_down do |event|
  if event.key == '1'
    WORLD.life.each do |ended|
      ended.full_death
    end
  elsif event.key == '2'
    first_brain = {
      nothing_happens: [[1, 10], [0, 0]],
    }

    # Place where we create our first bacteria
    #color, current_cell, energy, brain, memory, organs, name = 'Unknown', discription = 'Unknown'
    WORLD.life.push(Bacteria.new('#777777', WORLD.map[50][50], 50, first_brain, [], [], 'Adam', 'the First'))
  elsif event.key == 'p'
    PAUSE = !PAUSE
  elsif event.key == '4'
    i = 0
    WORLD.life.each do |ended|
      if i == 2
        ended.full_death
        i = 0
      end
      i += 1
    end
  end
end

update do
  unless PAUSE
    deads = []

    WORLD.life.each do |bactera|
      bactera.add_energy

      next unless bactera.disappeared

      deads.push(bactera)
      bactera.current_cell.set_color(WORLD_COLOR)
      bactera.current_cell.homie = nil
    end

    WORLD.life = WORLD.life - deads

    population_text.text = 'Time: ' + WORLD.sun.is_night
  end

  if !chosen.nil?
    set_bacteria_info(chosen)
  elsif chosen.nil?
    set_bacteria_info(default_bacteria)
  end

  WORLD.sun.next_tact
end

show

p 'Choose monitor:'
p '1. Laptop'
p '2. Square monitor'
monitor = gets.chomp.to_i
monitor = 2 if monitor > 2 || monitor < 1

WINDOW_SIZE_COO = 0.8 if monitor == 1
WINDOW_SIZE_COO = 1 if monitor == 2

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
DAY = 10
NIGHT = 0
SUN_TAX = 8
MAX_ORGANS_COUNT = 2
RIVER_TAX = false

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
  bite
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

# leaf - photosynthesis
# sucker - suck
# root - digest
# jaws - hunt
ORGANS = %i[
  leaf
  sucker
  root
  jaws
  biter
]

BRAIN_MUTATORS = %i[
  add_neiron
  delete_neiron
  increment_width
  decrement_width
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

# load_menu_titles
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
                   x: ws(1015), y: ws(705 + i * 22),
                   width: ws(170), height: ws(20),
                   color: '#c2c2c2'
                 ))
  LMT.push(
    Text.new(
      '',
      x: ws(1015), y: ws(705 + i * 22),
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
  'Description: -',
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

    Dir['saves/*'].each do |save|
      save.slice! 'saves/'
      add_save(save)
    end

    100.times do |j|
      @map.push([])
      100.times do |i|
        @map[j].push(Cell.new(Square.new(x: i * CELL_SIZE, y: j * CELL_SIZE, size: CELL_SIZE, color: WORLD_COLOR), i,
                              j))
      end
    end
  end

  def add_save(save)
    @saves.push(save)
    LMT[@saves.size - 1].text = save if @saves.size <= LMT.size
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
  attr_accessor :neighs, :homie, :sun_tax, :marked, :mark

  def initialize(body, x_id, y_id)
    @body = body
    @x_id = x_id
    @y_id = y_id
    @homie = nil
    @marked = false

    @sun_tax = if river_tax?
                 SUN_TAX
               else
                 0
               end
  end

  def river_tax?
    RIVER_TAX && ((@y_id > 5 && @y_id < 25) || (@x_id > 5 && @x_id < 25) || (@y_id > 65 && @y_id < 85) || (@x_id > 65 && @x_id < 88))
  end

  def mark_it
    @marked = true
    if @mark.nil?
      @mark = Square.new(x: @x_id * CELL_SIZE + 0.25 * CELL_SIZE, y: @y_id * CELL_SIZE + 0.25 * CELL_SIZE,
                         size: 0.5 * CELL_SIZE, color: 'white')
    else
      @mark.add
    end
  end

  def burst
    Sprite.new(
      'boom.png',
      clip_width: 127,
      time: 75,
      x: @x_id * CELL_SIZE + 0.25 * CELL_SIZE,
      y: @y_id * CELL_SIZE + 0.25 * CELL_SIZE
    ).play
  end

  def unmark_it
    @marked = false
    @mark.remove
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
    color = color.delete('-')
    @body.color = color
  end
end

WORLD = World.new

###############################################################
#
#                          Perceptron
#
###############################################################

class Perceptron
  # symbolyc trigger and symbolyc reaction
  attr_accessor :trigger, :reaction, :width

  def initialize(trigger, reaction, width)
    @trigger = trigger
    @reaction = reaction
    @width = width || 0
  end

  def initialize_clone(perceptron)
    @trigger = perceptron.trigger
    @reaction = perceptron.reaction
    @width = perceptron.width
  end

  def self.deserialize_from_hash(hash)
    trigger = hash[:trigger]
    reaction = hash[:reaction]
    width = hash[:width] || 0

    Perceptron.new(trigger, reaction, width)
  end

  def to_hash
    hash = {
      trigger: @trigger,
      reaction: @reaction,
      width: @width
    }
  end
end

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

  def self.nothing_happens(_bacteria)
    true
  end

  def self.is_day(_bacteria)
    !WORLD.sun.is_night
  end

  def self.is_night(_bacteria)
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

  # broken
  def self.burst(bacteria)
    # kill all alive in 3n3
    bacteria.current_cell.homies.each do |sad|
      sad.homie.death
    end

    bacteria.current_cell.burst

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

  # leaf - photosynthesis
  # sucker - suck
  # root - digest
  # jaws - hunt
  def self.suck(bacteria)
    return unless bacteria.have_organ?(:sucker)

    sight = bacteria.current_cell.sight_neigh(bacteria.sight)
    target = sight.homie if !sight.homie.nil? && !sight.homie.corpse

    return if target.nil?

    suck_count = bacteria.hp * HP_PRICE
    if suck_count >= target.energy
      bacteria.energy += suck_count
      target.energy -= suck_count
    else
      bacteria.energy += target.energy
      target.energy = 0
    end
  end

  def self.bite(bacteria)
    return unless bacteria.have_organ?(:biter)

    sight = bacteria.current_cell.sight_neigh(bacteria.sight)
    target = sight.homie unless sight.homie.nil?

    return if target.nil?

    bacteria.energy += HP_PRICE
    target.hp -= 1
    return unless target.hp == 0

    bacteria.energy += target.energy
    target.energy = 0
  end

  def self.digest(bacteria)
    return unless bacteria.have_organ?(:root)

    sight = bacteria.current_cell.sight_neigh(bacteria.sight)
    target = sight.homie if !sight.homie.nil? && sight.homie.corpse

    return if target.nil?

    bacteria.energy += target.hp * HP_PRICE
    target.energy = 0
    target.disappeared = true
  end

  def self.hunt(bacteria)
    return unless bacteria.have_organ?(:jaws)

    sight = bacteria.current_cell.sight_neigh(bacteria.sight)
    target = sight.homie if !sight.homie.nil? && !sight.homie.corpse

    return unless !target.nil? && (target.hp <= bacteria.hp)

    bacteria.energy += target.energy + target.hp * HP_PRICE
    target.full_death
  end

  def self.photosynthesis(bacteria)
    return unless bacteria.have_organ?(:leaf)

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

    brain.each do |perceptron|
      string.push(
        perceptron.trigger.to_s +
        ': ' + perceptron.reaction.to_s +
        ' | ' + perceptron.reaction.width
      )
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

    bacteria.is_wild -= 1 if mutated
    unless bacteria.is_wild < 0
      name = bacteria.name
      description = bacteria.description
    end

    name ||= 'Unknown'
    description ||= 'Unknown'

    Bacteria.new(color, place, energy, brain, bacteria.memory.clone, organs, name, description, bacteria.is_wild, 1)
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
    return if organs.nil?
    return if organs.empty?

    organed = SEED.rand(organs.size)
    organs.delete_at(organed)

    organs
  end

  def self.add_organ(organs)
    organs = [] if organs.nil?
    return if organs.count == MAX_ORGANS_COUNT

    organed = SEED.rand(ORGANS.size)
    organ = ORGANS[organed]

    organs.push(organ)

    organs
  end

  def self.organs_mutane(old_organs, seeded)
    return if ORGANS.size == 0

    organs = old_organs.clone

    return organs unless seeded == 0

    formed = SEED.rand(2)

    Neiron.send(ORGAN_MUTATORS[formed], organs)
  end

  #### MUTATOR METHODS ####

  def self.decrement_width(brain)
    return if brain.empty?

    seeded = SEED.rand(brain.size)
    perceptron = brain[seeded]

    perceptron.width += -1
    perceptron.width = -100 if perceptron.width < -100

    brain
  end

  def self.increment_width(brain)
    return if brain.empty?

    seeded = SEED.rand(brain.size)
    perceptron = brain[seeded]

    perceptron.width += 1

    brain
  end

  def self.delete_neiron(brain)
    return if brain.empty?

    seeded = SEED.rand(brain.size)
    perceptron = brain[seeded]

    brain.delete(perceptron)

    brain
  end

  def self.add_neiron(brain)
    seeded_trigger = SEED.rand(TRIGGERS.size)
    seeded_reaction = SEED.rand(REACTIONS.size)
    trigger = TRIGGERS[seeded_trigger]
    reaction = TRIGGERS[seeded_reaction]

    brain.push(Perceptron.new(trigger, reaction, 0))

    brain
  end

  def self.brain_mutane(old_brain, seeded)
    brain = []

    old_brain.each do |perceptron|
      brain.push(perceptron.clone)
    end

    return brain unless seeded == 0

    formed = SEED.rand(5)

    Neiron.send(BRAIN_MUTATORS[formed], brain)

    brain
  end
end
###############################################################
#
#                           BACTERIA
#
###############################################################

class Bacteria
  attr_accessor :disappeared, :color, :current_cell, :energy, :brain, :corpse, :sight, :hp, :name, :description,
                :memory, :actual_memory, :organs, :is_wild

  def initialize(color, current_cell, energy, brain, memory, organs,
                 name = 'Unknown', description = 'Unknown', is_wild, hp)

    @color = color

    set_current_cell(current_cell) unless current_cell.nil?

    @energy = energy
    @disappeared = false
    @corpse = false
    @brain = brain
    @sight = Neiron.just_directions
    @hp = hp
    @name = name
    @description = description
    @memory = memory
    @organs = organs
    @actual_memory = 0
    @is_wild = is_wild || 0
  end

  def have_organ?(organ_name)
    return false if organs.nil?

    organs.include?(organ_name)
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

    deserialized_brain = bacteria[:brain]
    brain = []

    deserialized_brain.each do |perceptron|
      brain.push(Perceptron.deserialize_from_hash(perceptron))
    end

    organs = bacteria[:organs] || []
    name = bacteria[:name]
    description = bacteria[:description] || 'Unknown'
    is_wild = 5
    hp = bacteria[:hp] || 1

    Bacteria.new(color, nil, energy, brain, memory, organs, name, description, is_wild, hp)
  end

  def serialize(name, description)
    @name = name
    @description = description

    save_hash = {
      name: @name,
      description: @description,
      color: @color,
      memory: @memory,
      organs: @organs,
      energy: @energy,
      brain: brain.each { |perceptron| perceptron.to_hash }
    }
    Dir.mkdir('saves') unless Dir.exist?('saves')
    File.open('saves/' + name, 'w') { |f| f.write save_hash.to_s }
  end

  ################################################
  # REFACTORY!
  def add_energy
    death if @energy <= 0

    return if corpse || disappeared || brain.empty?

    queue = []

    brain.each do |perceptron|
      queue.push(perceptron) if Neiron.send(perceptron.trigger, self)
    end

    return if queue.empty?

    while queue.size > 1
      temp_r_queue = []

      seeded = SEED.rand(200)
      queue.each do |perceptron|
        temp_r_queue.push(perceptron) if seeded > perceptron.width + 100
      end

      next if queue.size - temp_r_queue.size < 1

      temp_r_queue.each do |perceptron|
        queue.delete(perceptron)
      end
    end

    full_death if @energy >= 2000
    Neiron.send(perceptron.reaction, self)
  end
  ####################################################

  def full_death
    @energy = 0
    @disappeared = true
    @current_cell.unmark_it if @current_cell.marked
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
##########################################################################################################

chosen = nil
bacteria_buffer = nil

def coordinate_in_form(x, y, form_x, form_y, form_width, form_height)
  x > form_x && y > form_y && x < form_x + form_width && y < form_y + form_height
end

load_file_name = nil

@marked_list = []
@name_to_mark = ''

def clear_marks
  @marked_list.each do |to_unmark|
    to_unmark.unmark_it
  end

  @marked_list.clear
end

def mark_all_with_the_same_name(selected_cell)
  if selected_cell.homie.nil?
    clear_marks
    mark_only_this(selected_cell)
  elsif selected_cell.homie.name == 'Unknown'
    clear_marks
    mark_only_this(selected_cell)
  else
    return if @name_to_mark == selected_cell.homie.name

    clear_marks
    @name_to_mark = selected_cell.homie.name
  end
end

def mark_this(selected_cell)
  @marked_list.push(selected_cell)
  selected_cell.mark_it
end

def mark_only_this(selected_cell)
  @name_to_mark = ''
  mark_this(selected_cell)
end

on :mouse_down do |event|
  # Read the button event
  case event.button
  when :left
    x = (event.x / CELL_SIZE).to_i
    y = (event.y / CELL_SIZE).to_i

    if coordinate_in_form(event.x, event.y, save_button_x, save_button_y, save_button_width, save_button_height)

      return if chosen.nil?

      PAUSE = true

      Thread.new do
        p 'Type new bacteria name'
        name = gets.chomp
        p 'Type new bacteria description'
        description = gets.chomp
        chosen.serialize(name, description)
        WORLD.add_save(name)
        Thread.new { clicked(save_button) }
      end

    elsif coordinate_in_form(event.x, event.y, load_menu_button_first_x, load_menu_button_first_y, load_menu_width,
                             load_menu_full_height)

      selected = ((event.y - load_menu_button_first_y) / (load_menu_full_height / load_menu_count)).to_i
      load_file_name = WORLD.saves[selected]
      bacteria_buffer = Bacteria.deserialize(load_file_name)
      chosen =   bacteria_buffer
      Thread.new { clicked(load_menu[selected]) }

    elsif !bacteria_buffer.nil?

      current_cell = WORLD.get_place(x, y)
      current_cell.homie = bacteria_buffer
      bacteria_buffer.set_current_cell current_cell
      WORLD.life.push(bacteria_buffer)
      bacteria_buffer = nil

    else

      chosen = WORLD.get_place(x, y).homie
      mark_all_with_the_same_name(WORLD.get_place(x, y))

    end
  end
end

def clear_unused_lines(used_lines)
  temp_used_lines = used_lines

  return unless used_lines < BRAINS_TEXTS.size

  (BRAINS_TEXTS.size - used_lines).times do
    BRAINS_TEXTS[temp_used_lines].text = ''
    temp_used_lines += 1
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
  DISCRIPTION_TEXT.text = 'Description: ' + bacteria.description
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

default_bacteria = Bacteria.new(WORLD_COLOR, nil, 0, {}, [], [], 'Void', '-', 0, 0)

on :key_down do |event|
  if event.key == '1'
    WORLD.life.each do |ended|
      ended.full_death
    end
    PAUSE = false
  elsif event.key == '2'
    first_brain = [
      Perceptron.new(:nothing_happens, :photosynthesis, 10),
      Perceptron.new(:nothing_happens, :born, 0)
    ]

    # Place where we create our first bacteria
    # color, current_cell, energy, brain, memory, organs, name = 'Unknown', description = 'Unknown'
    WORLD.life.push(Bacteria.new('#777777', WORLD.map[50][50], 50, first_brain, [], ['leaf'], 'Adam', 'the First', 5,
                                 1))
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
      if !(@name_to_mark == '') && (@name_to_mark == bactera.name) && !bactera.current_cell.marked
        mark_this(bactera.current_cell)
      end
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

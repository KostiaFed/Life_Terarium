#### TODO: Finish serealization
####       Realize deserealization

require 'ruby2d'
require 'json'

set width: 1200, height: 990

### Control panel

show_bac = Square.new(x: 1010, y: 10, size: 180, color: '#aaaaaa')
brains_texts = []

save_button_x = 1010
save_button_y = 880
save_button_width = 180
save_button_height = 20

Rectangle.new(
  x: save_button_x, y: save_button_y,
  width: save_button_width, height: save_button_height,
  color: 'white'
)

Text.new(
  'SAVE',
  x: 1075, y: 878,
  size: 18,
  color: 'black'
)

photo_text = Text.new(
  'Photo count: 0',
  x: 1010, y: 960,
  size: 16,
  color: 'white'
)

corpse_text = Text.new(
  'Corpseaters count: 0',
  x: 1010, y: 940,
  size: 16,
  color: 'white'
)

meat_text = Text.new(
  'Meateaters count: 0',
  x: 1010, y: 920,
  size: 16,
  color: 'white'
)

population_text = Text.new(
  'World population: 0',
  x: 1010, y: 900,
  size: 16,
  color: 'white'
)

name_text = Text.new(
  'Name: -',
  x: 1010, y: 200,
  size: 20,
  color: 'white'
)

discription_text = Text.new(
  'Discription: -',
  x: 1010, y: 220,
  size: 20,
  color: 'white'
)

energy_text = Text.new(
  'Energy: 0',
  x: 1010, y: 240,
  size: 20,
  color: 'white'
)

eat_text = Text.new(
  'Eat type: -',
  x: 1010, y: 260,
  size: 20,
  color: 'white'
)

hp_text = Text.new(
  'HP: 0',
  x: 1010, y: 280,
  size: 20,
  color: 'white'
)

mother_period_text = Text.new(
  'Mother period: 0',
  x: 1010, y: 300,
  size: 20,
  color: 'white'
)

BRAIN_START = 320

###

WORLD_COLOR = '#3b3b3b'
SEED = Random.new
DAY = 4
NIGHT = 0

class Sun
  def initialize
    @ite = 0
  end

  def photon
    @ite += 1
    @ite = 0 if @ite == 2000
    return NIGHT if @ite > 1000

    DAY
  end
end

class World
  def initialize
    @sun = Sun.new
    @map = []
    @life = []

    100.times do |j|
      @map.push([])
      100.times do |i|
        @map[j].push(Cell.new(Square.new(x: i * 10, y: j * 10, size: 10, color: WORLD_COLOR), i, j))
      end
    end
  end

  def print_eat_types
    photo = 0
    corpse = 0
    meat = 0
    life.each do |b|
      next if b.corpse

      photo += 1 if b.eat_type == 'photo'
      corpse += 1 if b.eat_type == 'corpse'
      meat += 1 if b.eat_type == 'meat'
    end

    ['photo: ' + photo.to_s,
     'corpse: ' + corpse.to_s,
     'meat: ' + meat.to_s]
  end

  def get_place(x, y)
    y = 0 if y >= @map.size
    y = @map.size - 1 if y < 0
    x = 0 if x >= @map.size
    x = @map.size - 1 if x < 0

    @map[y][x]
  end

  attr_accessor :life, :map, :sun
end

class Neiron
  # Just to not use anonimous functions
  ### All events names there
  NEIRONES = %i[
    energy_enough
    energy_not_enough
    alone
    not_alone
    sight_like_me
    sight_alive
    sight_corpse
    isday
    isnight
    sight_free
    sight_meat_eat
    sight_corpse_eat
    sight_photo_eat
  ]
  ### COUNT OF REACTIONS
  REACTIONS = 7

  def self.switcher(key, bacteria, world)
    case key
    when 0
      born(bacteria, world)
    when 1
      burst(bacteria)
    when 2
      move(bacteria)
    when 3
      eat(bacteria, world)
    when 4
      change_sight(bacteria)
    when 5
      grow_hp(bacteria)
    when 6
      change_sight_to_next(bacteria)
    end
  end

  def self.text_switcher(key)
    case key
    when 0
      :born
    when 1
      :burst
    when 2
      :move
    when 3
      :eat
    when 4
      :change_sight
    when 5
      :grow_hp
    when 6
      :change_sight_to_next
    end
  end

  #### EVENTS (always return boolean)
  def self.energy_enough(bacteria)
    bacteria.energy >= bacteria.mother_period
  end

  def self.energy_not_enough(bacteria)
    bacteria.energy < bacteria.mother_period
  end

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

  def self.isday(world)
    world.sun.photon == DAY
  end

  def self.isnight(world)
    world.sun.photon == NIGHT
  end

  def self.sight_meat_eat(bacteria)
    sight = bacteria.current_cell.sight_neigh(bacteria.sight)
    !sight.homie.nil? ? sight.homie.eat_type == 'meat' : false
  end

  def self.sight_photo_eat(bacteria)
    sight = bacteria.current_cell.sight_neigh(bacteria.sight)
    !sight.homie.nil? ? sight.homie.eat_type == 'photo' : false
  end

  def self.sight_corpse_eat(bacteria)
    sight = bacteria.current_cell.sight_neigh(bacteria.sight)
    !sight.homie.nil? ? sight.homie.eat_type == 'corpse' : false
  end

  #### REACTIONS
  def self.change_sight(bacteria)
    bacteria.sight = Neiron.just_directions
  end

  def self.grow_hp(bacteria)
    return if bacteria.energy <= 10

    bacteria.hp += 1
    bacteria.energy -= 10
  end

  def self.born(bacteria, world)
    return if bacteria.energy < 10

    free = bacteria.current_cell.free
    return unless free.size > 1

    2.times do
      world.life.push(return_babie(bacteria, directions(free)))
      free = bacteria.current_cell.free
    end

    bacteria.full_death
  end

  def self.eat(bacteria, world)
    if bacteria.eat_type == 'photo'
      bacteria.energy += world.sun.photon
    elsif bacteria.eat_type == 'corpse'
      sight = bacteria.current_cell.sight_neigh(bacteria.sight)
      target = sight.homie if !sight.homie.nil? && sight.homie.corpse

      unless target.nil?
        bacteria.energy += target.hp * 25
        target.energy = 0
        target.disappeared = true
      end
    else
      sight = bacteria.current_cell.sight_neigh(bacteria.sight)
      target = sight.homie if !sight.homie.nil? && !sight.homie.corpse

      if !target.nil? && (target.hp <= bacteria.hp)
        bacteria.energy += target.energy
        target.full_death
      end
    end
  end

  def self.burst(bacteria)
    # kill all alive in 3n3
    bacteria.current_cell.homies.each do |sad|
      sad.homie.death
    end

    bacteria.death
  end

  def self.critical_burst(bacteria)
    # full kill all alive in 3n3
    bacteria.current_cell.homies.each do |sad|
      sad.homie.full_death
    end

    bacteria.full_death
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

    bacteria.energy -= 5
  end

  def self.change_sight_to_next(bacteria)
    bacteria.sight += 1
    bacteria.sight = 0 if bacteria.sight > 7
  end
  ### HELPERS

  def self.print_brain(brain)
    string = []
    brain.each do |key, value|
      string.push(key.to_s + ': ' + text_switcher(value[0]).to_s)
    end
    string
  end

  def self.return_babie(bacteria, place)
    color = color_mutane(bacteria.color)
    energy = bacteria.energy / 2
    mother_period = mother_period_mutane(bacteria.mother_period)
    brain = brain_mutane(bacteria.brain)
    eat_type = eat_type_mutane(bacteria.eat_type)

    Bacteria.new(color, place, energy, mother_period, brain, eat_type)
  end

  def self.how_far_color(color1, color2)
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

  ### MUTATORS

  ## need to refactory ##
  def self.mother_period_mutane(mother_period)
    seeded = SEED.rand(20)
    formed = SEED.rand(2)

    return mother_period unless seeded == 0

    mother_period += if formed == 0
                       10
                     else
                       -10
                     end

    # add scale from babies count
    mother_period = 10 if mother_period < 10

    mother_period
  end

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

  def self.eat_type_mutane(eat_type)
    seeded = SEED.rand(50)
    formed = SEED.rand(3)

    return eat_type unless seeded == 0

    if formed == 0
      'photo'
    elsif formed == 1
      'meat'
    else
      'corpse'
    end
  end

  def self.brain_mutane(old_brain)
    brain = old_brain.clone

    seeded = SEED.rand(25)
    return brain unless seeded == 0

    # add new neiron or delete or add/minus width
    formed = SEED.rand(4)

    neironed = SEED.rand(NEIRONES.size)

    # there we need const that = count of reactions
    value = [SEED.rand(REACTIONS), 0]
    neiron = NEIRONES[neironed]
    if formed == 0
      brain[neiron] = value
    elsif formed == 1
      brain.delete(neiron)
    elsif formed == 2
      brain[neiron][1] += 1 unless brain[neiron].nil?
    elsif formed == 3
      unless brain[neiron].nil?
        brain[neiron][1] -= 1
        brain[neiron][1] = -100 if brain[neiron][1] < -100
      end
    end

    brain
  end
end

###### Bio organism ######

class Bacteria
  attr_accessor :disappeared, :color, :current_cell, :mother_period, :energy, :brain, :corpse
  # photo corpse meat
  attr_accessor :eat_type, :sight, :hp, :name, :discription

  def initialize(color, current_cell, energy, mother_period, brain, eat_type)
    @color = color
    @current_cell = current_cell
    @current_cell.set_color(color)
    @current_cell.homie = self
    @energy = energy
    @disappeared = false
    @corpse = false
    @mother_period = mother_period
    @brain = brain
    @eat_type = eat_type
    @sight = Neiron.just_directions
    @hp = 1
    @name = 'Unknown'
    @discription = 'Unknown'
  end

  def self.deserialize(file_data)
    JSON.parse(file_data, object_class: Bacteria)
  end

  def serialize(name, discription)
    @name = name
    @discription = discription
    to_json
    p to_json
    File.open('save', to_json, mode: 'a')
  end

  def full_death
    @energy = 0
    @disappeared = true
  end

  def add_energy(world)
    @energy -= 1

    death if @energy <= 0

    return if corpse || disappeared || brain.empty?

    queue = []

    queue.push(:not_alone) if Neiron.not_alone(self) && !brain[:not_alone].nil?

    queue.push(:alone) if Neiron.alone(self) && !brain[:alone].nil?

    queue.push(:energy_enough) if Neiron.energy_enough(self) && !brain[:energy_enough].nil?

    queue.push(:energy_not_enough) if Neiron.energy_not_enough(self) && !brain[:energy_not_enough].nil?

    queue.push(:sight_like_me) if Neiron.sight_like_me(self) && !brain[:sight_like_me].nil?

    queue.push(:sight_corpse) if Neiron.sight_corpse(self) && !brain[:sight_corpse].nil?

    queue.push(:sight_alive) if Neiron.sight_alive(self) && !brain[:sight_alive].nil?

    queue.push(:sight_free) if Neiron.sight_free(self) && !brain[:sight_free].nil?

    queue.push(:isday) if Neiron.isday(world) && !brain[:isday].nil?

    queue.push(:isnight) if Neiron.isnight(world) && !brain[:isnight].nil?

    queue.push(:sight_meat_eat) if Neiron.sight_meat_eat(self) && !brain[:sight_meat_eat].nil?

    queue.push(:sight_photo_eat) if Neiron.sight_photo_eat(self) && !brain[:sight_photo_eat].nil?

    queue.push(:sight_corpse_eat) if Neiron.sight_corpse_eat(self) && !brain[:sight_corpse_eat].nil?

    return if queue.empty?

    width = -100

    queue.each do |n|
      width = brain[n][1] if brain[n][1] > width
    end

    last_queue = []
    queue.each do |n|
      last_queue.push(n) if brain[n][1] == width
    end

    Neiron.switcher(brain[last_queue[SEED.rand(last_queue.size)]][0], self, world)
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

################################################

class Cell
  attr_accessor :neighs, :homie

  def initialize(body, x_id, y_id)
    @body = body
    @x_id = x_id
    @y_id = y_id
    @homie = nil
  end

  def cash_neigh(world)
    y = get_y
    x = get_x

    @neighs = [
      # zero zero
      world.get_place(x, y + 1),
      world.get_place(x, y - 1),
      world.get_place(x + 1, y),
      world.get_place(x + 1, y + 1),
      world.get_place(x + 1, y - 1),
      world.get_place(x - 1, y),
      world.get_place(x - 1, y + 1),
      world.get_place(x - 1, y - 1)
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

world = World.new
world.map.each do |row|
  row.each do |cell|
    cell.cash_neigh(world)
  end
end

pause = false

on :key_down do |event|
  if event.key == '1'
    world.life.each do |ended|
      ended.full_death
    end
  elsif event.key == '2'
    first_brain = {
      energy_enough: [0, 5],
      energy_not_enough: [3, 0]
    }

    # Place where we create our first bacteria
    world.life.push(Bacteria.new('#777777', world.map[50][50], 50, 100, first_brain, 'photo'))
  elsif event.key == 'p'
    pause = !pause
  elsif event.key == '4'
    i = 0
    world.life.each do |ended|
      if i == 2
        ended.full_death
        i = 0
      end
      i += 1
    end
  end
end

chosen = nil

on :mouse_down do |event|
  # Read the button event
  case event.button
  when :left
    if event.x > save_button_x && event.y > save_button_y && event.x < save_button_x + save_button_width && event.y < save_button_y + save_button_height
      chosen.homie.serialize('Test',
                             'Test')
    end

    x = (event.x / 10).to_i
    y = (event.y / 10).to_i

    chosen = world.get_place(x, y)
  end
end

update do
  unless pause
    deads = []

    world.life.each do |bactera|
      bactera.add_energy(world)

      next unless bactera.disappeared

      deads.push(bactera)
      bactera.current_cell.set_color(WORLD_COLOR)
      bactera.current_cell.homie = nil
    end

    world.life = world.life - deads

    population_text.text = 'World population: ' + world.life.size.to_s
    eaters = world.print_eat_types

    photo_text.text = eaters[0]
    corpse_text.text = eaters[1]
    meat_text.text = eaters[2]
  end

  if !chosen.nil? && !chosen.homie.nil?
    show_bac.color = chosen.homie.color
    name_text.text = 'Name: ' + chosen.homie.name
    discription_text.text = 'Discription: ' + chosen.homie.discription
    energy_text.text = 'Energy: ' + chosen.homie.energy.to_s
    eat_text.text = 'Eat type: ' + chosen.homie.eat_type
    hp_text.text = 'HP: ' + chosen.homie.hp.to_s
    mother_period_text.text = 'Mother period: ' + chosen.homie.mother_period.to_s

    itee = 0
    Neiron.print_brain(chosen.homie.brain).each do |text|
      if brains_texts[itee].nil?
        brains_texts.push(Text.new(
                            text,
                            x: 1010, y: BRAIN_START + itee * 20,
                            size: 12,
                            color: 'white'
                          ))
      else
        brains_texts[itee].text = text
      end
      itee += 1
    end
    if itee < brains_texts.size
      (brains_texts.size - itee).times do
        brains_texts[itee].text = ''
        itee += 1
      end
    end
  end
end

show

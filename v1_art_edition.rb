require 'ruby2d'

WORLD_COLOR = '#3b3b3b'
SEED = Random.new

OFF_ART_MODE = true

class World
  def initialize
    @map = []
    @life = []

    100.times do |j|
      @map.push([])
      100.times do |i|
        @map[j].push(Cell.new(Square.new(x: i * 10, y: j * 10, size: 10, color: WORLD_COLOR), i, j))
      end
    end
  end

  def get_place(x, y)
    y = 0 if y >= @map.size
    y = @map.size - 1 if y < 0
    x = 0 if x >= @map.size
    x = @map.size - 1 if x < 0

    @map[y][x]
  end

  attr_reader :map
  attr_accessor :life
end

### PLACE WHERE WE CREATE REALLY CLEVER ONE ###

class Bacteria
  attr_accessor :old, :dead, :color

  def initialize(color, current_cell, energy)
    @color = color
    @current_cell = current_cell
    @current_cell.set_color(color)
    @current_cell.alive = true
    @energy = energy
    @old = 0
    @dead = false
  end

  def add_energy(buf, world)
    @energy += buf
    born(world) if @energy >= 100
    @old += 1
    death if old == 30 && OFF_ART_MODE
  end

  def death
    @dead = true
    @current_cell.set_color(WORLD_COLOR)
    @current_cell.alive = false
  end

  def born(world)
    free = @current_cell.free
    return unless free.size > 1

    world.life.push(Bacteria.new(color_mutane, directions(free), @energy / 50))
    world.life.push(Bacteria.new(color_mutane, directions(@current_cell.free), @energy / 50))
    death if OFF_ART_MODE
  end

  def color_mutane
    rgb = [
      color[1..2].hex,
      color[3..4].hex,
      color[5..6].hex
    ]

    seeded = SEED.rand(3)
    formed = SEED.rand(2)

    rgb[seeded] += if formed == 0
                     5
                   else
                     -5
                   end

    rgb[seeded] = 255 if rgb[seeded] > 255
    rgb[seeded] = 0 if rgb[seeded] < 0

    '#' + rgb[0].to_s(16).rjust(2, '0') + rgb[1].to_s(16).rjust(2, '0') + rgb[2].to_s(16).rjust(2, '0')
  end

  def directions(places)
    dir = SEED.rand(places.size)

    places[dir]
  end
end

################################################

class Cell
  attr_accessor :alive, :neighs

  def initialize(body, x_id, y_id)
    @body = body
    @x_id = x_id
    @y_id = y_id
    @alive = false
  end

  def cash_neigh(world)
    y = get_y
    x = get_x

    @neighs = [
      world.get_place(x + 1, y),
      world.get_place(x - 1, y),
      world.get_place(x, y + 1),
      world.get_place(x, y - 1),
      world.get_place(x + 1, y + 1),
      world.get_place(x + 1, y - 1),
      world.get_place(x - 1, y + 1),
      world.get_place(x - 1, y - 1)
    ]
  end

  def free
    free = []
    neighs.each do |neigh|
      free.push(neigh) if neigh.alive == false
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

set width: 990, height: 990

world = World.new
world.map.each do |row|
  row.each do |cell|
    cell.cash_neigh(world)
  end
end

# Place where we create our first bacteria
world.life.push(Bacteria.new('#6b6b6b', world.map[50][50], 50))

on :key_down do |event|
  OFF_ART_MODE = false if event.key == '1'
  OFF_ART_MODE = true if event.key == '2'
end

update do
  deads = []

  world.life.each do |bactera|
    bactera.add_energy(5, world)
    deads.push(bactera) if bactera.dead
  end

  world.life = world.life - deads
end

show

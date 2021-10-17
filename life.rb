require "bundler/setup"
require "gosu"
require "hasu"
require "pry"

at_exit do
  Game.run
end

class Game < Hasu::Window
  SEED = 63605486365338977498493769192985253342

  WIDTH = 800
  HEIGHT = 600
  SCALE = 5

  def initialize
    super(WIDTH, HEIGHT)
    self.caption = "Game of Life"
  end

  def reset
    Random.srand(SEED)
    @world = World.new(WIDTH / SCALE, HEIGHT / SCALE)
    @last_tick = Gosu.milliseconds
  end

  def update
    on_tick do
      @world = @world.map { |value, x, y|
        neighbours = @world.neighbours(x, y).sum

        if neighbours < 2 && value == 1
          0
        elsif neighbours <= 3 && value == 1
          1
        elsif neighbours > 3 && value == 1
          0
        elsif neighbours == 3 && value == 0
          1
        else
          0
        end
      }
    end
  end

  def on_tick
    if Gosu.milliseconds - @last_tick > 40
      yield
      @last_tick = Gosu.milliseconds
    end
  end

  def draw
    @world.each do |value, x, y|
      color = value == 0 ? Gosu::Color::WHITE : Gosu::Color::BLACK
      Gosu.draw_rect(x * SCALE, y * SCALE, SCALE, SCALE, color)
    end
  end
end

class World
  def initialize(width, height, grid = nil)
    @width, @height = width, height
    @grid = grid || Array.new(width) { Array.new(height) { rand > 0.1 ? 0 : 1 } }
  end

  def [](x,y)
    x = x % @width
    y = y % @height

    @grid[x][y]
  end

  def neighbours(x, y)
    [
      self[x - 1, y - 1],
      self[x, y - 1],
      self[x + 1, y - 1],

      self[x - 1, y],
      self[x + 1, y],

      self[x - 1, y + 1],
      self[x, y + 1],
      self[x + 1, y + 1],
    ]
  end

  def each
    @grid.each_with_index do |row, x|
      row.each_with_index do |value, y|
        yield(value, x, y)
      end
    end
  end

  def map
    new_grid = Array.new(@width) { Array.new(@height) }

    @grid.each_with_index do |row, x|
      row.each_with_index do |value, y|
        new_grid[x][y] = yield(value, x, y)
      rescue => error
        puts "Error on #{x},#{y}"
        # binding.pry
      end
    end

    World.new(@width, @height, new_grid)
  end
end

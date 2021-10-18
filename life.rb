require "bundler/setup"
require "gosu"
require "hasu"
require "pry"

at_exit do
  Game.run
end

class Game < Hasu::Window
  SEED = 63605486365338977498493769192985253342

  WIDTH = 640
  HEIGHT = 480
  SCALE = 10
  GRID_WIDTH = WIDTH / SCALE
  GRID_HEIGHT = HEIGHT / SCALE

  def initialize
    super(WIDTH, HEIGHT)
    self.caption = "Game of Life"
  end

  def reset
    # Random.srand(SEED)

    @world = World.new(GRID_WIDTH, GRID_HEIGHT)
    @last_tick = Gosu.milliseconds
    @drawing = false
    @running = true
    @grid = false
    @font = Gosu::Font.new(20)
  end

  def update
    @grid_x = (mouse_x / SCALE).floor
    @grid_y = (mouse_y / SCALE).floor

    if @drawing
      paint_cells(@drawing)
    elsif @running
      if Gosu.milliseconds - @last_tick > 40
        @last_tick = Gosu.milliseconds
        update_world
      end
    end
  end

  def paint_cells(value)
    if @grid_x != @last_grid_x || @grid_y != @last_grid_y
      @world[@grid_x, @grid_y] = value
    end

    @last_grid_x = @grid_x
    @last_grid_y = @grid_y
  end

  def update_world
    @world = @world.map { |value, x, y|
      neighbours = @world.neighbours(x, y)

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

  def draw
    draw_world
    draw_grid
    draw_mouse_pos
  end

  def draw_world
    @world.each do |value, x, y|
      if value == 0
        color = Gosu::Color::WHITE
      elsif @running
        color = Gosu::Color::BLACK
      else
        color = Gosu::Color::GRAY
      end

      Gosu.draw_rect(x * SCALE, y * SCALE, SCALE, SCALE, color, ZOrder::WORLD)
    end
  end

  GRID_SIZE = 10

  def draw_grid
    return unless @grid

    x_offset = (@grid_x - GRID_SIZE / 2) * SCALE
    y_offset = (@grid_y - GRID_SIZE / 2) * SCALE

    Gosu.translate(x_offset, y_offset) do
      (GRID_SIZE + 1).times do |n|
        Gosu.draw_line(
          n * SCALE, 0, Gosu::Color::GRAY,
          n * SCALE, GRID_SIZE * SCALE, Gosu::Color::GRAY,
          ZOrder::UI
        )
        Gosu.draw_line(
          0, n * SCALE, Gosu::Color::GRAY,
          GRID_SIZE * SCALE, n * SCALE, Gosu::Color::GRAY,
          ZOrder::UI
        )
      end
    end
  end

  def draw_mouse_pos
    # @font.draw_text("#{@grid_x}, #{@grid_y}", 10, 10, ZOrder::UI, 1.0, 1.0, Gosu::Color::RED)
    Gosu.draw_rect(@grid_x * SCALE, @grid_y * SCALE, SCALE, SCALE, Gosu::Color::RED, ZOrder::UI)
  end

  def button_down(id)
    case id
    when Gosu::KB_SPACE
      @running = !@running
    when Gosu::KB_ESCAPE
      close
    when Gosu::MS_LEFT
      @drawing = @world[@grid_x, @grid_y] == 1 ? 0 : 1
    end
  end

  def button_up(id)
    case id
    when Gosu::MS_LEFT
      @drawing = nil
    when Gosu::KB_C
      @running= false
      @world = World.new(GRID_WIDTH, GRID_HEIGHT)
    when Gosu::KB_R
      @world = World.random(GRID_WIDTH, GRID_HEIGHT)
    when Gosu::KB_G
      @grid = !@grid
    end
  end
end

module ZOrder
  WORLD = 0
  UI = 1
end

class World
  def self.random(width, height)
    grid = Array.new(width) { Array.new(height) { rand > 0.1 ? 0 : 1 } }
    new(width, height, grid)
  end

  def initialize(width, height, grid = nil)
    @width, @height = width, height
    @grid = grid || Array.new(width) { Array.new(height, 0) }
  end

  def [](x,y)
    x = x % @width
    y = y % @height

    @grid[x][y]
  end

  def []=(x, y, value)
    @grid[x][y] = value
  end

  def each
    @grid.each_with_index do |row, x|
      row.each_with_index do |value, y|
        yield(value, x, y)
      end
    end
  end

  def map
    new_grid = Array.new(@width) { Array.new(@height, 0) }

    @grid.each_with_index do |row, x|
      row.each_with_index do |value, y|
        new_grid[x][y] = yield(value, x, y)
      rescue => error
        puts "#{error} drawing #{x},#{y}"
        raise error
        # binding.pry
      end
    end

    World.new(@width, @height, new_grid)
  end

  def neighbours(x, y)
    self[x - 1, y - 1] + self[x, y - 1] + self[x + 1, y - 1] +
    self[x - 1, y] + self[x + 1, y] +
    self[x - 1, y + 1] + self[x, y + 1] + self[x + 1, y + 1]
  end
end

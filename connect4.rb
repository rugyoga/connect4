MAX=1000
class Connect4
  ROWS=6
  COLS=7
  EMPTY='*'
  FIRST='x'
  SECOND='O'

  def initialize
    @b = COLS.times.map{ |i| [] }
    @ms = []
  end

  def legal( c, r )
    0 <= c && c < COLS && 0 <= r && r < ROWS
  end 

  def build_line( c, r, c_delta, r_delta, p, op, items, open )
    c += c_delta
    r += r_delta
    while legal(c,r) && @b[c][r] == p
      items.send( op, [c, r] )
      c += c_delta
      r += r_delta
    end
    [items, open + (legal(c,r) && @b[c][r].nil? ? 1 : 0)]
  end
  
  def create_line( c, r, c_delta, r_delta, p )
    pos, open = build_line( c, r,  c_delta,  r_delta, p, :push,    [[c,r]], 0 )
    build_line( c, r, -c_delta, -r_delta, p, :unshift, pos, open )
  end
   
  def check_line( c, r, c_delta, r_delta, p )
    create_line( c, r, c_delta, r_delta, p ).first.length == 4
  end
  
  def won
    return false if @ms.length < 7
    c = @ms.last
    r = @b[c].length-1
    p = @b[c][r]
    return "W"  if check_line( c, r, -1,  0, p )
    return "SW" if check_line( c, r, -1, -1, p )
    return "SE" if check_line( c, r,  1, -1, p )
    return "S"  if check_line( c, r,  0, -1, p )
    false
  end
  
  def lines( c, r )
    p = @b[c][r]
    [[-1, 0], [-1, -1], [1, -1], [0, -1]].map{ |(x,y)| create_line( c, r, x, y, p ) }
  end
  
  def drawn
    @ms.length == ROWS*COLS
  end
  
  def moves
    @b.each_with_index.map{ |ps,i| ps.length < ROWS ? i : nil }.compact
  end

  def player( p )
    p.nil? ? EMPTY : (p ? FIRST : SECOND)
  end
  
  def display
    printf "\n\n"
    ROWS.times do |r|
      COLS.times do |c|
        printf player( @b[c][ROWS-r-1] )
      end
      printf "\n"
    end
  end
  
  def to_move
    @ms.length % 2 == 0
  end
  
  def last_moved
    !to_move
  end
  
  def make_move( c, p )
    @b[c].push( p )
    @ms.push( c )
  end
  
  def undo_move
    c = @ms.pop
    p = @b[c].pop
  end

  def eval
    score = 0
    @b.each_with_index do |ps, c|
      ps.each_with_index do |p, r|
        sum = lines( c, r ).map{ |(l,o)| l.length*o }.reduce(0,&:+) 
        score += p ? sum : -sum 
      end
    end
    score
  end

  def key
    @b
  end
end
  
class Random
  def initialize( game )
    @game = game
  end

  def pick
    @game.moves.sample
  end
end

class MinMax
  def initialize( game, depth )
    @game = game
    @depth = depth
  end

  def leaf( t )
    t.is_a?(Numeric) ? t : leaf(t.first.first)
  end
  
  def min_max( memo, depth )
    return (@game.last_moved ? MAX : -MAX) if @game.won
    return 0 if @game.drawn
    visited = memo[@game.key]
    return visited unless visited.nil?
    return memo[@game.key] = @game.eval if depth == 0
    p = @game.to_move
    values = []
    @game.moves.each do |c|
      @game.make_move( c, p ) 
      values << [min_max( memo, depth-1 ), c]
      @game.undo_move
    end
    values.sort_by!{ |(t,c)| leaf(t) }
    values.reverse! unless @game.last_moved
    memo[@game.key] = values
  end
  
  def pick
    min_max( {}, @depth ).first[1]
  end
end
  
class AlphaBeta
  def initialize( game, depth )
    @game = game
    @depth = depth
  end
  
  def alpha_beta( memo, depth, alpha, beta )
    return (@game.last_moved ? MAX : -MAX) if @game.won
    return 0 if @game.drawn
    visited = memo[@game.key]
    return visited unless visited.nil?
    return memo[@game.key] = @game.eval if depth == 0
    #return @game.eval if depth == 0
    p = @game.to_move
    if p
      v = -MAX
      @game.moves.each do |c|
        @game.make_move( c, p )
        v     = [v, alpha_beta( memo, depth-1, alpha, beta)].max
        alpha = [alpha, v].max
        @game.undo_move
        break if beta <= alpha
      end
      return v
    else
      v = MAX
      @game.moves.each do |c|
        @game.make_move( c, p )
        v     = [v, alpha_beta( memo, depth-1, alpha, beta)].min
        beta  = [beta, v].min
        @game.undo_move
        break if beta <= alpha
      end
      return v
    end
  end
  
  def pick
    memo = {}
    values = []
    p = @game.to_move
    @game.moves.each do |c|
      @game.make_move( c, p )
      values << [alpha_beta( memo, @depth, -MAX, MAX ), c]
      @game.undo_move
    end
    values.sort_by!(&:first)
    values.reverse! unless @game.last_moved
    values.first[1]
  end
end
  
depth=(ARGV[0] || "4").to_i
connect4 = Connect4.new
#player1 = Random.new( connect4 )
#player1 = MinMax.new( connect4, depth )
player1 = AlphaBeta.new( connect4, depth )
#player2 = Random.new( connect4 )
#player2 = MinMax.new( connect4, depth )
player2 = AlphaBeta.new( connect4, depth )
until (game_won = connect4.won) || connect4.drawn do
  p = connect4.to_move
  c = (p ? player1 : player2).pick
  connect4.make_move( c, p )
  connect4.display
  printf "#{connect4.player(p)} played column #{c}"
end
if game_won
  puts " and won in direction #{game_won}!"
else
  puts " and drew"
end

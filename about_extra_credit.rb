require File.expand_path(File.dirname(__FILE__) + '/edgecase')
# EXTRA CREDIT:
#
# Create a program that will play the Greed Game.
# Rules for the game are in GREED_RULES.TXT.
#
# You already have a DiceSet class and score function you can use.
# Write a player class and a Game class to complete the project.  This
# is a free form assignment, so approach it however you desire.


def score(dice)
  # You need to write this method
  set_of_numbers = Hash.new(0)
  dice.each do |item|
    sum = set_of_numbers[item]
    set_of_numbers[item] = sum+1
  end

  set_of_ones = set_of_numbers[1]
  score = 0
  score += 1000 * (set_of_ones / 3)
  remaining_ones = set_of_ones % 3
  score += 100 * remaining_ones
  #remove all the 1s since they already contributed to the score
  dice = dice.select{ |item| item != 1 }

  not_a_special_number = (1..6).select { |item| item != 1 }
  not_a_special_number.each do |item|
    triplets = (set_of_numbers[item] / 3)
    if triplets > 0
      score += item * 100 * triplets
      remove_scored_dice = triplets * 3
      #remove dices that already contributed to the score
      dice = dice.select{ |d|
        if item == d && remove_scored_dice > 0  
          remove_scored_dice -= 1
          false
        else
          true
        end 
      }
    end
  end

  score += 50 * (set_of_numbers[5] % 3)
  #remove all the 5s since they already contributed to the score
  dice = dice.select{ |item| item != 5 }
  return score
end

class RandomIntegerSequence
#   code ...
  attr_reader :values
  attr_reader :range

  def initialize(range)
    @range = range
  end

  def roll(nb_set)
    @values = []
    (1..nb_set).each do
      @values << range.begin + rand(range.end - range.begin + 1) 
    end
    return @values
  end
end

class GreedDiceSet < RandomIntegerSequence
  def initialize
    super((1..6))
  end
end

module Chooseable
  def roll_or_stay?
    raise RuntimeError, "method must be overriden in a subclass"
  end
end

class PlayerChoicesMockup < RandomIntegerSequence
  include Chooseable

  def initialize
    super((0..1))
  end

  def values
    @values.map { |i| (i==0) ? :roll_again : :stop }
  end

  def roll_or_stay?
    roll(1)
    values.first
  end
end

class GreedMatch

  attr_reader :players
  attr_reader :game_started
  attr_reader :current_player
  attr_reader :game_is_in_final_round
  attr_reader :game_completed

  def initialize
    @players = []
    @game_started = false
    @game_is_in_final_round = false
    @game_completed = false
  end 

  def add_new_player(player)
    raise RuntimeError, "game already started" if @game_started
    @players << player
  end

  def start_game
    raise RuntimeError, "game already started" if @game_started
    raise RuntimeError, "there are no players for this match" unless @players.size > 0
    @game_started = true
    @current_player = @players.first
  end

  def normal_player_round(player)
    @current_player = player
    dice_roll = GreedDiceSet.new.roll 5
    player_turn = PlayerTurn.new(player)
    roll_score = player_turn.add_roll dice_roll
    while roll_score > 0
      if player.roll_or_stay? == :roll_again
        dice_roll = GreedDiceSet.new.roll 5 if dice_roll.size == 0
        roll_score = player_turn.add_roll dice_roll
      else
        player.score += roll_score
        @game_is_in_final_round = true if !game_is_in_final_round && player.score > 3000
        break 
      end
    end
  end

  def next_round
    raise RuntimeError, "game finished" if @game_completed
    last_round = game_is_in_final_round
    for player in @players
      normal_player_round player
    end
    show_results if last_round
  end

  def show_scores
    higher = @players.first
    for player in @players
      
      higher = player if player.score > higher.score
    end
    return higher
  end

  def show_results
    winner = show_scores
    puts "winner is player #{winner.name}"
    @game_completed = true
    winner 
  end 
end



class Player
  attr_accessor :score
  attr_reader :name

  def initialize(name, match, chooseable)
    raise TypeError, "chooseable must implement Chooseable" unless chooseable.class.included_modules.include? Chooseable
    @name = name
    @match = match
    @chooseable = chooseable
    @score = 0
  end

  def roll_or_stay?
    @chooseable.roll_or_stay?
  end

end

class PlayerTurn

  attr_reader :preliminar_score
  attr_reader :player 

  def initialize(player)
    @player = player
    @preliminar_score = 0
  end

  def add_roll(dice_roll)
    roll_score = score(dice_roll)
    @preliminar_score += roll_score if player_is_in || roll_score >= 300 
    puts "player '#{player.name}': score: #{player.score} this roll: #{roll_score} this turn: #{preliminar_score}"
    preliminar_score
  end

private
  def player_is_in
    return @player.score + preliminar_score > 0
  end 
end



class AboutExtraCreditProject < EdgeCase::Koan

#score tests
  def test_score_of_an_empty_list_is_zero
    assert_equal 0, score([])
  end

  def test_score_of_a_single_roll_of_5_is_50
    assert_equal 50, score([5])
  end

  def test_score_of_a_single_roll_of_1_is_100
    assert_equal 100, score([1])
  end

  def test_score_of_multiple_1s_and_5s_is_the_sum_of_individual_scores
    assert_equal 300, score([1,5,5,1])
  end

  def test_score_of_single_2s_3s_4s_and_6s_are_zero
    assert_equal 0, score([2,3,4,6])
  end

  def test_score_of_a_triple_1_is_1000
    assert_equal 1000, score([1,1,1])
  end

  def test_score_of_other_triples_is_100x
    assert_equal 200, score([2,2,2])
    assert_equal 300, score([3,3,3])
    assert_equal 400, score([4,4,4])
    assert_equal 500, score([5,5,5])
    assert_equal 600, score([6,6,6])
  end

  def test_score_of_mixed_is_sum
    assert_equal 250, score([2,5,2,2,3])
    assert_equal 550, score([5,5,5,5])
  end

#diceset tests
  def test_can_create_a_dice_set
    dice = DiceSet.new
    assert_not_nil dice
  end

  def test_rolling_the_dice_returns_a_set_of_integers_between_1_and_6
    dice = DiceSet.new

    dice.roll(5)
    assert dice.values.is_a?(Array), "should be an array"
    assert_equal 5, dice.values.size
    dice.values.each do |value|
      assert value >= 1 && value <= 6, "value #{value} must be between 1 and 6"
    end
  end

  def test_dice_values_do_not_change_unless_explicitly_rolled
    dice = DiceSet.new
    dice.roll(5)
    first_time = dice.values
    second_time = dice.values
    assert_equal first_time, second_time
  end

  def test_dice_values_should_change_between_rolls
    dice = DiceSet.new

    dice.roll(5)
    first_time = dice.values

    dice.roll(5)
    second_time = dice.values

    assert_not_equal first_time, second_time,
      "Two rolls should not be equal"

    # THINK ABOUT IT:
    #
    # If the rolls are random, then it is possible (although not
    # likely) that two consecutive rolls are equal.  What would be a
    # better way to test this.
  end

  def test_you_can_roll_different_numbers_of_dice
    dice = DiceSet.new

    dice.roll(3)
    assert_equal 3, dice.values.size

    dice.roll(1)
    assert_equal 1, dice.values.size
  end

#greed game tests
  def test_create_a_greed_match
    match = GreedMatch.new
    p1 = Player.new("greg", match, PlayerChoicesMockup.new)
    match.add_new_player p1
    p2 = Player.new("John", match, PlayerChoicesMockup.new)
    match.add_new_player p2
    match.start_game
    assert_equal [p1,p2], match.players
    assert_equal true, match.game_started
    assert_equal p1, match.current_player

    winner = nil
    while !match.game_completed
      winner = match.next_round
    end
    assert_equal true, winner.score > 3000
  end

end

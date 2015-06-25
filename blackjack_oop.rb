require "pry"

MINIMUM_BET = 10
INITIAL_BALANCE = 200
BlACKJACK = 21
DEALER_MIN_TOTAL = 17

# display modules
module Display
  def draw_cards(cards)
    cards.each do |c|
    print " -----------"
    print "   "
  end 
  puts
  cards.each do |c| 
    s = c.suit

    print "|#{s}          |"
    print "  "
  end
  puts
  cards.each do |c|
    print "|           |"
    print "  "
  end
  puts
  cards.each do |c|
    print "|           |"
    print "  "
  end
  puts
  cards.each do |c|
    v = c.value
    if v.length == 1
      v += ' '
    end
    print "|     #{v}    |"
    print "  "
  end 
  puts
  cards.each do |c|
    print "|           |"
    print "  "
  end 
  puts
  cards.each do |c|
    print "|           |"
    print "  "
  end
  puts
  cards.each do |c|
    s = c.suit
    print "|          #{s}|"
    print "  "
  end 
  puts
  cards.each do |c|
    print " -----------"
    print "   "
  end
  puts
end

end
#classes 
class Card
  attr_reader :suit, :value 

  def initialize(s,v)
    @suit = s
    @value = v
  end
end

class Hand 
  include Display 

  attr_reader :cards, :total
  def initialize(cards = [])
    @cards = cards
  end

  def total
    total = 0
    cards.each do |card| 
      if card.value == 'A'
        total += 11
      elsif card.value.to_i == 0
        total += 10
      else
        total += card.value.to_i
      end
    end

    cards.select{|c| c.value == 'A'}.count.times do
      total -= 10 if total > BlACKJACK
    end
    total
  end

  def draw
    draw_cards(cards)
  end
end

class Deck 
  attr_reader :cards

  def initialize
    number_of_decks = [2,3,4,5].sample
    deck = []
    ['H', 'D', 'S', 'C'].each do |suit|
      ['2','3','4','5','6','7','8','9','10', 'J', 'Q', 'K','A'].each do |value|
        deck << Card.new(suit, value)
      end 
    end 
    @cards = deck * number_of_decks
    shuffle_deck
  end

  def shuffle_deck
    @cards.shuffle!
  end

  def deal(hand)
    initialize if cards.empty?
    hand.cards << @cards.pop
  end 
end

class Player
  attr_reader :name, :balance, :hands, :bet, :actions, :won

  def initialize(name = nil)
    @name = name
    @balance = 200
    @hands = [Hand.new]
    @bet = 0
    @actions = []
    @won = false
  end
  
  def get_name(player_number)
    system 'clear'
    puts "Player #{player_number}, what is your name?"
    @name = gets.chomp
  end 

  def place_bet
    begin 
      system 'clear'
      puts "#{name}, how much would you like to bet? You can bet as little as #{MINIMUM_BET} and as much as #{balance}"
      answer = gets.chomp.to_i
    end until answer >= 10 && answer <= balance
    @bet = answer 
  end

  def adjust_balance
    @balance += bet if won
    @balance -= bet unless won
  end

  def hit(deck)
    actions << "hit"
    deck.deal(hands[select_hand])
  end

  def select_hand
    if hands.count > 1
      begin 
        puts "Which hand would you like to hit?"
        answer = gets.chomp.to_i
      end until answer > 0 && answer <= hands.count
      return answer - 1
    end 
    0
  end 

  def double_down(deck)
    if actions.empty?
      actions << "double_down"
      @bet = bet * 2
      deck.deal(hands[0])
    end
  end

  def split(deck)
    card1 = hands[0].cards[0]
    card2 = hands[0].cards[1]

    @hands[0] = Hand.new([card1])
    @hands[1] = Hand.new([card2])

    actions << "split"
    @bet = bet * 2

    deck.deal(@hands[0])
    deck.deal(@hands[1])
  end

  def get_move
    begin 
      puts "#{name}, what would you like to do?"
      puts "(1) Hit"
      puts "(2) Stay"
      if 2 * bet <= balance && actions.empty?
        puts "(3) Double down" 
        puts "(4) Split" if hands[0].cards[0].value == hands[0].cards[1].value
      end
      move = gets.chomp.to_i
    end until move >= 1 && move < 5
    move
  end 

  def handle_move(move, deck)
    case move
    when 1
      hit(deck)
    when 2
      actions << "stay"
    when 3
      double_down(deck)
    when 4 
      split(deck)
    end
  end

  def move(deck)
    loop do 
      handle_move(get_move, deck)
      system 'clear'
      hands.each{|hand| hand.draw}
      break if actions.include?("stay") || total >= BlACKJACK || actions.include?("double_down")
    end
  end
  
  def has_won
    @won = true
  end 

  def reset
    actions.clear
    hands.clear
    @hands = [Hand.new]
    @won = false
  end 

  def total 
    best_total = hands[0].total
    hands.each do |hand|
      best_total = hand.total if best_total < hand.total && hand.total <= BlACKJACK
    end
    best_total
  end
end

class Dealer < Player
  def move(deck)
    while total < DEALER_MIN_TOTAL
      deck.deal(hands[0])
    end
  end 
end

class Game
  attr_accessor :players, :deck

  def initialize
    @players = []
    get_number_of_players.times do 
      players << Player.new
    end
    @deck = Deck.new
  end

  def play
    players.each_index {|player_index| players[player_index].get_name(player_index + 1)}
    players << Dealer.new("Dealer")
    loop do
      # place bets 
      place_bets
      # deal out hands 
      deal_out_hands

      # make moves
      players.each do |player|
        player.move(deck)
        show_cards_before_end
      end 
      show_all_cards
      # finish game 
      announce_winners(get_winners)
      settle_bets
      players.each{|player| player.reset}
      break unless play_again?
    end 
  end

  def place_bets
    players.each {|player| player.place_bet unless player.class == Dealer}
  end

  def deal_out_hands
    system 'clear'
    players.each do |player|
      deck.deal(player.hands[0])
      deck.deal(player.hands[0])
    end 
    show_cards_before_end
  end

  def show_cards_before_end
    system 'clear'
    players.each do |player|
      puts "#{player.name}'s cards:"
      player.hands.each {|hand| hand.draw unless player.class == Dealer }
      if player.class == Dealer
        face_up_card = player.hands[0].cards[0]
        hidden_card = Card.new("?","?")
        Hand.new([face_up_card, hidden_card]).draw
      end
    end
  end

  def show_all_cards
    system 'clear'
    players.each do |player|
      puts "#{player.name}'s cards:"
      player.hands.each {|hand| hand.draw} 
    end
  end

  def play_again?
    players_to_delete = []
    players.each do |player|
      if player.balance < MINIMUM_BET
        puts "I'm sorry #{player.name}, you don't have enough to meet the minimum bet. Come back later when you have more money."
        players_to_delete << player
      end
    end 
    players_to_delete.each{|player| players.delete(player)}

    return false if players.count < 2

    begin
      puts "Would you like to play another game? (y/n)"
      answer = gets.chomp.downcase
    end until %(y n).include?(answer)

    answer == "y"
  end

  def get_winners
    dealer = players[players.count - 1]
    winners = []
    players.each do |player|
      if (player.total > dealer.total && player.total <= 21) || (player.total <= 21 && dealer.total > 21)
        player.has_won
        winners.push(player)
      end
    end 
    winners
  end

  def get_number_of_players
    system "clear"
    begin
      puts "How many players are there?"
      answer = gets.chomp.to_i
    end until answer > 0 && answer <= 10
    answer
  end  

  def announce_winners(winners)
    if winners.empty?
      puts "Dealer beat everyone at the table."
    else 
      print_win = winners.count > 1 ? "win" : "wins"
      winners.each_with_index do |winner, i|
        first_winner = i == 0
        last_winner = i == winners.count - 1 && winners.count > 1
        print "#{winner.name}" if first_winner
        print ", #{winner.name}" unless first_winner || last_winner
        print " and #{winner.name}" if last_winner
      end
      puts " #{print_win}!"
    end 
  end

  def settle_bets
    players.each do |player|
      player.adjust_balance
    end
  end
end 

Game.new.play

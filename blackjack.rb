

INITIAL_BALANCE = 200
MINIMUM_BET = 10
BLACKJACK = 21
DEALER_MIN_TOTAL = 17


def new_deck
  suits = ['H', 'D', 'S', 'C']
  cards = ['2','3','4','5','6','7','8','9','10', 'J', 'Q', 'K','A']
  deck = suits.product(cards)
  deck.shuffle!
end 

def deal_cards(app)
  2.times do
    app[:curr_game][:player_cards] << app[:deck].pop
    app[:curr_game][:dealer_cards] << app[:deck].pop
  end 

  if calculate_total(app[:curr_game][:player_cards]) == BLACKJACK
    app[:curr_game][:winner] = 'player'
  end 
end

def show_cards(app)
  system 'clear'
  player_cards = app[:curr_game][:player_cards]
  dealer_cards = app[:curr_game][:dealer_cards]
  
  puts "Your cards: "
  draw_cards(player_cards)
  puts "Dealer's cards: "
  # Reveal 
  if app[:curr_game][:dealer_done]
    draw_cards(dealer_cards)
  else 
    draw_cards([dealer_cards[0], ["?","?"]])
  end
end

def dealers_move(app)
  cards = app[:curr_game][:dealer_cards]
  total = calculate_total(cards)
  while total < DEALER_MIN_TOTAL
    cards << app[:deck].pop
    total = calculate_total(cards)
  end

  if calculate_total(cards) > BLACKJACK
    app[:curr_game][:dealer_bust] = true
  end

  app[:curr_game][:dealer_done] = true
end

def welcome(app)
  system 'clear'
  puts "Welcome to the table. What is your name?"
  app[:player][:name] = gets.chomp
end

def get_bet(app)
  system 'clear'
  begin 
    puts "#{app[:player][:name]}, You have $#{app[:player][:balance]}. The minimum bet is $#{MINIMUM_BET}. How much would you like to wager?"
    bet = gets.chomp.to_i
  end until bet >= MINIMUM_BET && bet <= app[:player][:balance] 
  app[:curr_game][:bet] = bet
end 

def get_move(app)
  player_cards = app[:curr_game][:player_cards]
  begin 
    puts "What would you like to do?"
    puts "(1) Hit"
    puts "(2) Stay"
    if 2 * app[:curr_game][:bet] <= app[:player][:balance]
      puts "(3) Double down" if !app[:curr_game][:doubled_down] && player_cards.count == 2
      puts "(4) Split" if !app[:curr_game][:split] && splitable(player_cards)
    end
    move = gets.chomp.to_i
  end until move >= 1 && move < 5
  move
end

def players_move(app)
  loop do 
    move = get_move(app)
    handle_move(move, app)
    show_cards(app)
    break if app[:curr_game][:player_bust] || app[:curr_game][:stay] || app[:curr_game][:doubled_down]
  end 
end

def handle_move(move, app)
  player_cards = app[:curr_game][:player_cards]
  case move
    when 1
     player_cards << app[:deck].pop
      app[:curr_game][:player_bust] = true if calculate_total(player_cards) > BLACKJACK
    when 2
      app[:curr_game][:stay] = true
   when 3
      app[:curr_game][:doubled_down] = true 
      app[:curr_game][:bet] = 2 * app[:curr_game][:bet]
      player_cards << app[:deck].pop
      app[:curr_game][:player_bust] = true if calculate_total(player_cards) > BLACKJACK
    when 4
      player_cards << app[:deck].pop
      player_cards.unshift(app[:deck].pop)
      hand1 = [player_cards[0],player_cards[1]]
      hand2 = [player_cards[2],player_cards[3]]
      app[:curr_game][:split] = true
      app[:curr_game][:bet] = 2 * app[:curr_game][:bet]
      app[:curr_game][:player_bust] = true if calculate_total(hand1) > BLACKJACK || calculate_total(hand2) > BLACKJACK
    end
end


def splitable(cards)
  values = cards.map{|e| e[1]}
  values[0] == values[1]
end


def calculate_total(cards)
  values = cards.map{|e| e[1]}

  total = 0
  values.each do |value|
    if value == "A"
      total += 11
    elsif value.to_i == 0
      total += 10
    else
      total += value.to_i
    end
  end

  values.select{|e| e == "A"}.count.times do 
    total -= 10 if total > BLACKJACK
  end
  total 
end 

def there_is_winner(app)
  player_cards = app[:curr_game][:player_cards]
  dealer_cards = app[:curr_game][:dealer_cards]
  if calculate_total(player_cards) == BLACKJACK && player_cards.count == 2
    puts "You got blackjack! You win $#{app[:curr_game][:bet]}"
    app[:player][:balance] += app[:curr_game][:bet]
    app[:curr_game][:winner] = 'player'
    return true
  elsif calculate_total(dealer_cards) == BLACKJACK && dealer_cards.count == 2
    puts "Dealer got blackjack! You lose $#{app[:curr_game][:bet]}"
    app[:player][:balance] -= app[:curr_game][:bet]
    app[:curr_game][:winner] = 'dealer'
    return true
  elsif app[:curr_game][:player_bust]
    puts "You went bust! You lose $#{app[:curr_game][:bet]}"
    app[:player][:balance] -= app[:curr_game][:bet]
    app[:curr_game][:winner] = 'dealer'
    return true
  elsif app[:curr_game][:dealer_bust]
    puts "Dealer went bust. You win $#{app[:curr_game][:bet]}!"
    app[:player][:balance] += app[:curr_game][:bet]
    app[:curr_game][:winner] = 'player'
    return true
  elsif app[:curr_game][:split]
    hand1 = [player_cards[0],player_cards[1]]
    hand2 = [player_cards[2],player_cards[3]]
    if calculate_total(hand1) > calculate_total(dealer_cards) || calculate_total(hand2) > calculate_total(dealer_cards)
      puts "Your hand beat the dealer's! You win $#{app[:curr_game][:bet]}!"
      app[:player][:balance] += app[:curr_game][:bet]
      app[:curr_game][:winner] = 'player'
    else
      puts "Your hand didn't beat the dealer's! You lose $#{app[:curr_game][:bet]}."
      app[:player][:balance] -= app[:curr_game][:bet]
      app[:curr_game][:winner] = 'dealer'
    end 
    return true
  elsif app[:curr_game][:dealer_done]
    if calculate_total(player_cards) > calculate_total(dealer_cards)
      puts "Your hand beat the dealer's! You win $#{app[:curr_game][:bet]}!"
      app[:player][:balance] += app[:curr_game][:bet]
      app[:curr_game][:winner] = 'player'
    else
      puts "Your hand didn't beat the dealer's! You lose $#{app[:curr_game][:bet]}."
      app[:player][:balance] -= app[:curr_game][:bet]
      app[:curr_game][:winner] = 'dealer'
    end
    return true
  end 
  return false
end 

def draw_cards(cards)
  cards.each do |c|
    print " -----------"
    print "   "
  end 
  puts
  cards.each do |c| 
    s = c[0]

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
    v = c[1]
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
    s = c[0]
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

def draw_hidden_car
end

def new_game
  curr_game =  {
    :bet => MINIMUM_BET,
    :player_cards => [],
    :dealer_cards => [],
    :doubled_down => false,
    :split => false,
    :stay => false,
    :player_bust=> false,
    :done => false
  }
end 

def play_another(app)
  if app[:player][:balance] < MINIMUM_BET
    puts "I'm sorry #{app[:player][:name]}, you don't have enough to meet the minimum bet. Come back later when you have more money. Bye"
    return false
  end 

  begin
    puts "Would you like to play another game? (y/n)"
    answer = gets.chomp.downcase
  end until %(y n).include? answer

  return true if answer == "y"
  false 
end

app = {
  :player => {
    :name => '',
    :balance => INITIAL_BALANCE
  },
  :curr_game=> {
    :bet => MINIMUM_BET,
    :player_cards => [],
    :dealer_cards => [],
    :doubled_down => false,
    :split => false,
    :stay => false,
    :player_bust => false,
    :dealer_bust => false,
    :done => false
  },
  :history => [],
  :deck => new_deck
}



welcome(app)
loop do
  
  loop do
    get_bet(app)
    deal_cards(app)
    show_cards(app)
    players_move(app)
    dealers_move(app)
    show_cards(app)
    break if there_is_winner(app)
  end

  break if !play_another(app)

  app[:history] << app[:curr_game]
  app[:curr_game] = new_game
end



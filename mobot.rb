require 'cinch'
require "cinch/plugins/identify"
require 'yaml'


#Load config using YAML
config = YAML.load_file("config.yaml")


#Global database accessible by all threads, technically a problem, but honestly what are the chances?
$members = []
$missions = []

#Main bot definition
mobot = Cinch::Bot.new do
    

    #Holds threads created by methods - mostly timers
    threads = []


    #Should be called whenever the database is changed for any reason
    def update_db(cont)
        db = File.open('./database', 'w')
        db.write(Marshal.dump(cont))
        db.close
    end
    def update_missions(cont)
        db = File.open('./missions', 'w')
        db.write(Marshal.dump(cont))
        db.close
    end

    class Mission
        attr_accessor :name, :type, :reward, :start, :success, :failure

        def initialize(name, type, reward, start, success, failure)
            @name = name
            @type = type
            @reward = reward
            @start = start
            @success = success
            @failure = failure
        end

        def attempt(stats)
            responses = [@start]
            if @type == "DEX"
                if rand() > 0.3
                    responses.push(@success)
                    responses.push(@reward + ((stats[0] * 7) + (stats[3] * 2)))
                else
                    responses.push(@failure)
                    responses.push(0 - ((@reward).round - stats[3]))
                end
            end
            if @type == "STR"
                if rand() > 0.3
                    responses.push(@success)
                    responses.push(@reward + ((stats[1] * 7) + (stats[3] * 2)))
                else
                    responses.push(@failure)
                    responses.push(0 - ((@reward).round - stats[3]))
                end
            end
            if @type == "INT"
                if rand() > 0.3
                    responses.push(@success)
                    responses.push(@reward + ((stats[2] * 7) + (stats[3] * 2)))
                else
                    responses.push(@failure)
                    responses.push(0 - ((@reward).round - stats[3]))
                end
            end
            if @type == "LCK"
                if rand() > 0.3
                    responses.push(@success)
                    responses.push(@reward + (stats[3] * 9))
                else
                    responses.push(@failure)
                    responses.push(0 - ((@reward).round - stats[3]))
                end
            end
            responses
        end
    end

    #Class for each user
    class Member
        attr_accessor :name, :credits, :dex, :str, :int, :lck, :pvp, :mission, :daily, :crew, :crew_array, :crew_open
        

        #On initialization, only takes name by default
        def initialize(name, credits = 0, dex = 1, str = 1, int = 1, lck = 1)
            @name = name
            @credits = credits
            @daily = false
	        @dex = dex
	        @str = str
	        @int = int
	        @lck = lck
	        @pvp = false
            @mission = false
            @crew = '%NONE'
            @crew_array = []
            @crew_open = false
        end


        #Helper methods - allows easy management of currency
        def add_trivia(amount)
            @credits = @credits + amount * 2
        end

        def add_uno(amount)
            @credits = @credits + amount + 50
        end
        

        #Toggles per user daily variable - NOT responsible for threaded timing
        def daily_claim()
            if not @daily
                @daily = true
                @credits = @credits + 250
		        val = "Daily claimed!"
	        else
		        val = "You already claimed your daily!"
            end
	        val
        end


        #Helper method to return stats in an array
        def get_stats()
            val = [@dex, @str, @int, @lck]
	        val
        end


        #
        def robbed()
	        if rand() > 0.8
		        amount = rand() * @credits/2
		        amount = amount.round
		        @credits = @credits - amount
		        amount
	        else
		        0
	        end
	    end

	    def pvp()
	        @pvp = !@pvp
	        if @pvp
	    	    val = "Your PvP is now ON!"
	        else
	    	    val = "Your PvP is now OFF!"
	        end
	        val
	    end
	    def daily_reset()
	        @daily = false
	    end
        def mission_reset()
            @mission = false
        end
	    def buy(item, recipient, m)
	        if item == "kick"
                    if @credits > 999
	    	    @credits = @credits - 1000
	    	    m.channel.kick(recipient)
	    	    val = "User kicked!"
	    	else
	    	    val = "You need 1000 credits to kick someone!"
	    	end
	        end
	        if item == "devoice"
                    if @credits > 1999
	    	    @credits = @credits - 2000
	    	    m.channel.devoice(recipient)
	    	    val = "User devoiced!"
	    	else
	    	    val = "You need 2000 credits to devoice someone!"
	    	end
	        end
	        if item == "DEX"
	    	amount = 450 + 50 * @dex
	    	if @credits > amount - 1
	    	    @credits = @credits - amount
	    	    @dex = @dex + 1
	    	    val = "DEX upgraded! Your DEX is now #{@dex}!"
	    	else
	    	    val = "You need #{amount} credits to upgrade your DEX!"
	    	end
                end
	        if item == "INT"
	    	amount = 450 + 50 * @int
	    	if @credits > amount - 1
	    	    @credits = @credits - amount
	    	    @int = @int + 1
	    	    val = "INT upgraded! Your INT is now #{@int}!"
	    	else
	    	    val = "You need #{amount} credits to upgrade your INT!"
	    	end
                end
	        if item == "STR"
	    	amount = 450 + 50 * @str
	    	if @credits > amount - 1
	    	    @credits = @credits - amount
	    	    @str = @str + 1
	    	    val = "STR upgraded! Your STR is now #{@str}!"
	    	else
	    	    val = "You need #{amount} credits to upgrade your STR!"
	    	end
                end
	        if item == "LCK"
	    	amount = 450 + 50 * @lck
	    	if @credits > amount - 1
	    	    @credits = @credits - amount
	    	    @lck = @lck + 1
	    	    val = "LCK upgraded! Your LCK is now #{@lck}!"
	    	else
	    	    val = "You need #{amount} credits to upgrade your LCK!"
	    	end
                end
	        val
	    end
    end


    def get_user(user, mem)
        for i in mem
	        if i.name == user
		        return i
	        end
	    end
	    new = Member.new(user)
	    $members << new
	    update_db($members)
	    return new
    end

    begin
        $members = Marshal.load File.read('./database')
    rescue
	    puts "Failed to load database!"
    end
    
    #Initial Bot Config
    configure do |c|
        c.realname = config['config']['realname']
        c.user = config['config']['realname']
        c.server = config['config']['server']
        c.port = config['config']['port'].to_s
        c.nick = config['config']['nick'].to_s
        c.channels = config['config']['channels']
	    c.delay_joins = :identified
        c.plugins.plugins = [Cinch::Plugins::Identify]
	    c.plugins.options[Cinch::Plugins::Identify] = {
	    :password => config['config']['password'],
	    :type => :nickserv,
	}
    end
    
    $missions.push(Mission.new("Recover a starmap", "DEX", 60, "You are tasked with recovering a starmap from an infested derelict ship!", "You accidentally step on a strange spiderlike being on the way out and enrage the hive, only to sprint away with the starmap as the others swarm to eat their wounded.", "The ships security AI mistakes you for one of the infested crew and puts the sector on lockdown. It takes you over an hour and all your ammunition to burn your way through the exit.")) 
    $missions.push(Mission.new("Kill a cartel leader", "STR", 40, "A cartel leader has asked you to help them in an upcoming fight against their rivals!", "You fight side by side with the cartel for several hours until none of the rival cartel are left standing.", "Several minutes into the fray, the cartels leader is struck by a stray laser blast, and the leaderless forces scatter along with your chance of payment.")) 
    $missions.push(Mission.new("Thaw a cryotube", "INT", 50, "You find a stray cryogenic tube while cruising through space, and spend the day thawing it", "The occupant turns out to be dead, but was carrying a cache of valuable resources.", "You open the canister, and your crew starts coughing as the diseased contents pour out. You use over half your medical supplies treating it.")) 
    $missions.push(Mission.new("Mine an asteroid field", "LCK", 80, "You come across a field of rich asteroids and try to mine the valuable resources.", "You manage to top up your cargo bay with ore by skirting the edges of the field.", "As you're mining, a chunk of rock breaks off an asteroid and hits the collection arm of your ship, rendering it useless until repaired.")) 

    $members.each do |i|
        i.daily_reset
        i.mission_reset
    end

    Timer(300) {
        User('taylorswift').send(".bene")
    }

    on :message, /^JOIN (#.+)$/ do |m, target|
        Channel(target).join
    end

    on :message, /^SEND (#.+)/ do |m, args|
        lst = args.split(' ')
	contents = lst[1..lst.length].join(' ')
	Channel(lst[0]).send(contents)
    end

    on :message, /^MESSAGE (.+)/ do |m, args|
        lst = args.split(' ')
        User(lst[0]).send(lst[1..lst.length].join(' '))
    end

    on :message, ".daily" do |m|
	    usr = mobot.get_user(m.user.to_s, $members)
        if usr.daily == false
	        threads.push Thread.new {
		        sleep(86400)
		        usr.daily_reset
	        }
        end
	    m.reply usr.daily_claim
	    mobot.update_db($members)
    end

    on :message,  /^.credits/ do |m|
	lst = m.message.split(' ')
	if lst.length > 1
	    m.reply mobot.get_user(lst[1], $members).credits
        else
            m.reply mobot.get_user(m.user.to_s, $members).credits
    	end
    end

    on :message, ".attr" do |m|
        stats = mobot.get_user(m.user.to_s, $members).get_stats
        m.reply "DEX: #{stats[0].to_s} | STR: #{stats[1].to_s} | INT: #{stats[2].to_s} | LCK: #{stats[3].to_s}"
    end

    on :message, ".taytay" do |m|
	    m.reply(".money")
    end

    on :message, ".pvp" do |m|
        m.reply mobot.get_user(m.user.to_s, $members).pvp
    end

    on :message, ".mission" do |m|
        mission = $missions.sample
        user = mobot.get_user(m.user.to_s, $members)
        if user.mission == false
            result = mission.attempt(user.get_stats)
            reward = result[2]
            m.reply result[0]
            m.reply result[1]
            if (user.credits + reward) < 1
                neg = user.credits
                user.credits = 0
                m.reply "That mission lost you #{neg} credits! You now have 0 credits!"
            else
                user.credits = user.credits + reward
                current = user.credits
                if reward < 0
                    reward = reward.abs
                    m.reply "That mission lost you #{reward} credits! You now have #{current} credits!"
                else
                    m.reply "That mission gained you #{reward} credits! You now have #{current} credits!"
                end
            end
            user.mission = true
            mobot.update_db($members)
            sleep(180)
            user.mission = false
        else
            m.reply "You already went on a mission recently! Take a break for a minute or three."
        end
    end
        

    on :message, ".help" do |m|
        User(m.user.to_s).send("Hi! I'm mobot! I allow you to save up credits via playing games with other bots in irc such as UNOBot or Trivia, and eventually spend them to devoice or kick other $members, even if you don't have permission to do so. Try doing '.daily' to get started.")
	    User(m.user.to_s).send('Commands are as follows:')
	    User(m.user.to_s).send('.daily - Claims your daily 250 credits')
	    User(m.user.to_s).send('.credits - Shows your current balance')
	    User(m.user.to_s).send('.purchase {item} [recipient] - Purchases an item')
	    User(m.user.to_s).send('.store - Lists items for purchase')
	    User(m.user.to_s).send('.taytay - Shows current taylorswift balance')
	    User(m.user.to_s).send('.rob - Pay 20 credits to attempt to rob another user')
        User(m.user.to_s).send('.attr - Shows your current attributes')
        User(m.user.to_s).send('.mission - Attempt a mission')
        User(m.user.to_s).send('.pvp - Toggles your PvP status')
        User(m.user.to_s).send('.bet {amount} - Attempt to bet some credits - double or nothing!')
    end

    on :message, ".store" do |m|
        User(m.user.to_s).send('kick {recipient} - Kicks target user - 1000 credits')
        User(m.user.to_s).send('devoice {recipient} - Devoices target user - 2000 credits')
        User(m.user.to_s).send('DEX - Increases your Dexterity attribute - 500 + 50 for each previous upgrade')
        User(m.user.to_s).send('STR - Increases your Strength attribute - 500 + 50 for each previous upgrade')
        User(m.user.to_s).send('INT - Increases your Intelligence attribute - 500 + 50 for each previous upgrade')
        User(m.user.to_s).send('LCK - Increases your Luck attribute - 500 + 50 for each previous upgrade')
    end

    on :message do |m|
	    if m.user.to_s == "Trivia"
	        lst = m.message.split(' ')
            if lst[0] == "Winner:"
                mobot.get_user(lst[1].chop, $members).add_trivia(lst[lst.index("Points:")+1].chop.to_i)
		        mobot.update_db($members)
	        end
	    end
    end

    on :message do |m|
	    if m.user.to_s == "UNOBot"
	        lst = m.message.split(' ')
            if lst[1] == "gains"
	    	    mobot.get_user(m.user.to_s, $members).add_uno(lst[2].to_i)
	        end
	    end
       end

    on :message, /^.cmod (.+)/ do |m, arg|
        lst = arg.split(' ')
	    amount = lst[0]
	    recipient = lst[1]
	    if m.user.to_s == 'varzeki'
	        user = mobot.get_user(recipient, $members)
	        user.credits = user.credits + amount.to_i
	        m.reply "User credited!"
	        mobot.update_db($members)
	    else
	        m.reply "You don't have permission to do that!"
	    end
    end

    on :message, /^.crew (.+)/ do |m, arg|
        lst = arg.split(' ')
        user = mobot.get_user(m.user.to_s, $members)
        if lst[0] == 'start'
            if user.crew == "%NONE"
                user.crew = user.name
                user.crew_array = [user.name]
                m.reply "You started a crew!"
            else
                m.reply "You're already in a crew!"
            end
        end
        if lst[0] == 'join'
            if user.crew == "%NONE"
                user2 = mobot.get_user(lst[1], $members)
                if not user2.crew == user2.name
                    m.reply "That user isn't leading a crew!"
                else
                    if user2.crew_open == true
                        user2.crew_array.push(user.name)
                        user.crew = user2.name
                        cname = user2.name
                        m.reply "You just joined the crew of #{cname}!"
                    else
                        m.reply "That users crew is closed!"
                    end
                end
            else
                m.reply "You're already in a crew!"
            end
        end
    end


	
    on :message, /^.rob (.+)/ do |m, arg|
        lst = arg.split(' ')
	    robber = mobot.get_user(m.user.to_s, $members)
	    victim = mobot.get_user(lst[0], $members)
	    if robber.credits > 19 or robber == "uncleleech"
	        if robber == victim
		        m.reply "You're seriously trying to rob yourself? What a masochist!"
	        end
            amount = victim.robbed
	        robber.credits = robber.credits + amount - 20
            current = robber.credits
            if amount > 0
                m.reply "You successfully stole #{amount} credits! You now have #{current} credits!"
            else
                m.reply "You failed to steal anything! You now have #{current} credits!"
            end
	        mobot.update_db($members)
	    else
	        m.reply "It costs 20 credits to rob someone!"
	    end
    end

    on :message, /^.purchase (.+)/ do |m, arg|
        lst = arg.split(' ')
	    item = lst[0]
	    recipient = lst[1]
	    m.reply mobot.get_user(m.user.to_s, $members).buy(item, recipient, m)
	    mobot.update_db($members)
    end

    on :message, ".bots" do |m|
        m.reply "[Ruby] https://github.com/Varzeki/mobot | Try using .help for commands!"
    end

    on :message, ".migrate" do |m|
        m.reply "Migrating database..."
        new_db = []
        $members.each do |i|
            new_db.push(Member.new(i.name, i.credits, ni.dex, i.str, i.int, i.lck))
        end
        $members = new_db
        mobot.update_db($members)
        m.reply "Done!"
    end

    on :message, /^.bet (.+)/ do |m, arg|
        lst = arg.split(' ')
        user = mobot.get_user(m.user.to_s, $members)
        if lst[0].to_i > 1
            if user.credits - lst[0].to_i > -1
                if rand() > 0.6
                    user.credits = user.credits + lst[0].to_i
                    amount = user.credits
                    m.reply "Congratulations, you won! You now have #{amount} credits!"
                else
                    user.credits = user.credits - lst[0].to_i
                    amount = user.credits
                    m.reply "You lost! You now have #{amount} credits!"
                end
            end
        end
    end
end


#Set logging
mobot.loggers << Cinch::Logger::FormattedLogger.new(File.open("./mobot.log", "a"))
mobot.loggers.level = :debug
mobot.loggers.first.level = :info

#Start
mobot.start


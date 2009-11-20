module WarcraftArmory 
  
  # Load the XML Mappings from the supplied config.yml file.
  CONFIG = YAML.load_file("#{GEM_ROOT}/config/config.yml")["character"]
  CONFIG_ARENA = YAML.load_file("#{GEM_ROOT}/config/config_arena.yml")["arena_teams"]

  # Gives you access to Character information
  #
  # ==== Usage
  # * <tt>location</tt> - A symbol specifying your realm's location. E.g. <tt>:eu</tt> or <tt>:us</tt>
  # * <tt>realm</tt> - A symbol specifying your realm. E.g. <tt>:aszune</tt> or <tt>:bloodhoof</tt>
  # * <tt>character</tt> - A symbol specifying the character. E.g. <tt>:adries</tt> or <tt>:dwaria</tt>
  #
  # ==== Available Attributes
  # * <tt>name</tt> - The name of the character
  # * <tt>prefix</tt> - An optional prefix to the name. E.g. "Private ". Default: ""
  # * <tt>suffix</tt> - An optional suffix to the name. E.g. " the Explorer". Default: ""
  # * <tt>level</tt> - The character's current level. E.g. 48. Note that characters below level 10 are not available on the armory.
  # * <tt>faction</tt> - The name of the character's faction. E.g. "Alliance" or "Horde"
  # * <tt>faction_id</tt> - The internal (World of Warcraft) id for the faction.
  # * <tt>race</tt> - The name of the character's race. E.g. "Human" or "Night Elf"
  # * <tt>race_id</tt> - The internal (World of Warcraft) id for the race.
  # * <tt>class_name</tt> - The name of the character's class. E.g. "Mage" or "Warlock"
  # * <tt>class_id</tt> - The internal (World of Warcraft) id for the class.
  # * <tt>gender</tt> - The character's gender. E.g. "Male"
  # * <tt>gender_id</tt> - The internal (World of Warcraft) id for gender.
  # * <tt>points</tt> - Total number of the character's achievement points.
  # * <tt>last_modifiedat</tt> - A <tt>DateTime</tt> object with the date the armory data was last updated. 
  # * <tt>realm</tt> - The official realm name. E.g. "Aszune"
  # * <tt>battle_group</tt> - The battle group for this character. E.g. "Blackout"
  # * <tt>guild_name</tt> - The name of the character's guild. E.g. "Impact". Blank is no guild is available. 
  #
  # ==== Available helper methods
  # * <tt>full_name</tt> - Returns the full name of the character, including the <tt>prefix</tt> and <tt>suffix</tt>
  # * <tt>description</tt> - Gives the usual World of Warcraft description of the character. E.g. "Level 80 Night Elf Hunter"
  #
  # ==== Examples
  #   character = WarcraftArmory::Character.find(:eu, :aszune, :adries)
  #   # => <WarcraftArmory::Character>
  #
  #   character.name
  #   # => "Adries"
  #
  #   character.level
  #   # => 48
  #
  #   character.full_name
  #   # => "Adries the Explorer"
  #
  #   character.description
  #   # => "Level 48 Human Warrior"
  #
  class Character
    attr_accessor :locale
    
    CONFIG["attributes"].each_pair do |key, value|
      attr_accessor "#{key}".to_sym
    end

    CONFIG["attributes"].each_pair do |key, value|
      attr_accessor "#{key}".to_sym
    end

    # Returns the full name of the character, including the prefix and suffix.
    #
    #   character.full_name
    #   # => "Adries the Explorer"
    def full_name
      [prefix, name, suffix].join("")
    end
    
    # Returns a classic character description.
    #
    #   characer.description
    #   # => "Level 48 Human Warrior"    
    def description
      "Level #{level} #{race} #{class_name}"
    end

    def arena_teams
      load_arena_teams if !@arena_teams_hash
      @arena_teams_hash
    end

    def load_arena_teams
      result = {
        :twos   => WarcraftArmory::ArenaTeam.new,
        :threes => WarcraftArmory::ArenaTeam.new,
        :fives  => WarcraftArmory::ArenaTeam.new
      }
      url = WarcraftArmory::Base.generate_url(@locale, @realm, @name, CONFIG_ARENA["file"])
      doc = WarcraftArmory::Utils::Parser.parse_url(url)
      { :twos => 2, :threes => 3, :fives => 5 }.each do |team_type, size|
        CONFIG_ARENA["attributes"].each_pair do |key, code|
          if ((doc/"arenaTeam[@teamSize=#{size}]").length > 0)
            result[team_type].send("#{key}=".to_sym, eval(code.gsub(':size',size.to_s)))
          end
        end
      end
      @arena_teams_hash = result
    end
    
    # Finds a World of Warcraft character.
    # * <tt>location</tt> - A symbol specifying your realm's location. E.g. <tt>:eu</tt> or <tt>:us</tt>
    # * <tt>realm</tt> - A symbol specifying your realm. E.g. <tt>:aszune</tt> or <tt>:bloodhoof</tt>
    # * <tt>character</tt> - A symbol specifying the character. E.g. <tt>:adries</tt> or <tt>:dwaria</tt>
    #
    #  character = WarcraftArmory::Character.find(:eu, :aszune, :adries)
    #  # => <WarcraftArmory::Character>
    def self.find(location, realm, character)
      result = WarcraftArmory::Character.new
      # save the location as locale for fetching of other armory data
      result.locale = location
      
      url = WarcraftArmory::Base.generate_url(location, realm, character, CONFIG["file"])
      doc = WarcraftArmory::Utils::Parser.parse_url(url)
            
      CONFIG["attributes"].each_pair do |key, code|
        result.send("#{key}=".to_sym, eval(code))
      end
      
      return result
    end    
  end

  # Gives you access to Arena Team information
  #
  # ==== Available Attributes
  # * <tt>name</tt> - The name of the team
  # * <tt>rating</tt> - The current rating of the team, anywhere from 0 to 3000
  # * <tt>ranking</tt> - Battlegroup ranking for the team.
  # * <tt>season_games_played</tt> - Total games played by the team in the current arena season
  # * <tt>season_games_won</tt> - Total games won by the team in the current arena season
  # * <tt>last_season_ranking</tt> - Final ranking of the team from the previous arena season
  # * <tt>size</tt> - Number of members on the team.
  # * <tt>team_size</tt> - Team size bracket that this team belongs to, e.g. 2, 3, or 5
  # * <tt>battlegroup</tt> - String representation of the name of the battlegroup this team is on
  # * <tt>faction_id</tt> - The internal (World of Warcraft) id for the faction.
  # * <tt>faction</tt> - Faction that players on this arena team belong to, e.g. "Alliance" or "Horde"
  # * <tt>realm</tt> - Realm that this arena team is on
  # * <tt>created</tt> - When this team was created, as a timestamp stored in a string.
  #
  # ==== Available helper methods
  # * <tt>season_record</tt> - A formatted string of <tt>season_games_won</tt> and <tt>season_games_played</tt>
  # * <tt>season_win_percentage</tt> - A whole integer representation of number of games won divided by games played.
  #
  # ==== Examples
  #   character = WarcraftArmory::Character.find(:us, :whisperwind, :hightops)
  #   # => <WarcraftArmory::Character>
  #
  #   character.arena_teams
  #   # => { :twos => #<WarcraftArmory::ArenaTeam>,
  #   #      :threes => #<WarcraftArmory::ArenaTeam>,
  #   #      :fives => #<WarcraftArmory::ArenaTeam> }
  #
  #   character.arena_teams[:twos].rating
  #   # => 1204
  #
  #   character.arena_teams[:twos].ranking
  #   # => 6239
  #
  #   character.arena_teams[:twos].name
  #   # => "Orange Team"
  #
  class ArenaTeam
    CONFIG_ARENA["attributes"].each_pair do |key, value|
      attr_accessor "#{key}".to_sym
    end

    def season_record
      "#{season_games_won} / #{season_games_played}"
    end

    def season_win_percentage
      if season_games_played == 0
        return 0
      end
      return (season_games_won / season_games_played.to_f*100).to_i
    end
  end
end

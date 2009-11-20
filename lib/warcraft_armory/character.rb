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
      result.locale = location
      
      url = WarcraftArmory::Base.generate_url(location, realm, character, CONFIG["file"])
      doc = WarcraftArmory::Utils::Parser.parse_url(url)
            
      CONFIG["attributes"].each_pair do |key, code|
        result.send("#{key}=".to_sym, eval(code))
      end
      
      return result
    end    
  end

  class ArenaTeam
    attr_accessor :size, :members, :games_played

    CONFIG_ARENA["attributes"].each_pair do |key, value|
      attr_accessor "#{key}".to_sym
    end

    def season_record
      "#{season_games_won} / #{season_games_played}"
    end

    def season_win_percentage
      (season_games_won / season_games_played.to_f*100).to_i
    end
  end
end

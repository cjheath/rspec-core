module RSpec
  module Core
    module Twister
      # Do we have a ruby that can be twisted?
      def self.possible
        begin
          set_parse_func(nil)
          true
        rescue
          puts "It's not possible to twist in a version of Ruby that lacks set_parse_func"
          false
        end
      end

      def self.load_twisties twisties
        install_parse_func
        twisties.each do |twistie|
          if File.stat(twistie).directory?
            Dir[twistie+'/**.rb'].each do |file|
              load file
            end
          else
            load twistie
          end
        end
        uninstall_parse_func
      end

      def self.prepare twisties = []
        @twist_points = []  # Record what twist points are available
        @twist_at = nil     # Don't install any twists at first

        # Load the files with no twists, and record any new constants created:
        constant_baseline = Object.constants
        load_twisties twisties
        @twistie_constants = Object.constants - constant_baseline
        puts "Finished preparing to twist!"
        puts "Twisties define these constants which will be redefined each time: #{@twistie_constants.inspect}"
        puts "Your twisties contain #{@twist_points.size} twist points"
        puts "Let's twist!"+"!"*40

        @twist_points
      end

      def self.remove_twistie_constants
        @twistie_constants.each do |constant|
          Object.send(:remove_const, constant)
        end
      end

      def self.twist twist_points, twisties
        puts ">>>>> Here's a new twist on things, I'll reload your twisties <<<<<<"
        # Reload the twisties, applying the twist point
        remove_twistie_constants
        @twist_at = twist_points
        load_twisties twisties
        puts ">>>>> That's seriously twisted, man, lets do it! <<<<<"
      end

      def self.install_parse_func
        RUBY_PARSE_CONDITIONAL = 1
        RUBY_PARSE_LITERAL = 2
        set_parse_func(
          lambda do |flag, file, line, target|
            twist = [flag, file, line, target]
            unless @twist_at
              # puts "Recording new twist point #{twist.inspect}"
              @twist_points << twist
            end
            twist_at = @twist_at || []
            twist_it = twist_at.include?(twist)

            case flag
            when RUBY_PARSE_CONDITIONAL
              # Returning true causes the sense of the test to be reversed
              puts "Twisting #{file}:#{line} by reversing the sense of the #{target} conditional" if twist_it
              twist_it

            when RUBY_PARSE_LITERAL
              if twist_it
                # The value returned will be used instead
                print "Twisting #{target.inspect}"
                case target
                when Integer, Float
                  target = target*2+1
                when String
                  target = "TWISTED: "+target
                else
                  puts "Can't twist a #{target.class} literal"
                end
                puts " to #{target.inspect}"
              end
              target
            else
              puts "Twister: Unknown parser event!"
              target
            end
          end
        )
      end

      def self.uninstall_parse_func
        set_parse_func(nil)
      end

    end
  end
end

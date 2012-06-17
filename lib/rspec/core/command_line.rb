module RSpec
  module Core
    class CommandLine
      def initialize(options, configuration=RSpec::configuration, world=RSpec::world)
        if Array === options
          options = ConfigurationOptions.new(options)
          options.parse_options
        end
        @options       = options
        @configuration = configuration
        @world         = world
      end

      # Configures and runs a suite
      #
      # @param [IO] err
      # @param [IO] out
      def run(err, out)
        @configuration.error_stream = err
        @configuration.output_stream ||= out
        @options.configure(@configuration)
        if twisties = @configuration.twister and Twister.possible
          puts "Preparing to twist your codez..."
          @twist_points = Twister.prepare twisties

          # Run the first run: This is expected to come up clean before we twist it:
          @configuration.load_spec_files
          first_result = run1

          # Now, for each twist point, do a full run with that twist:
          @twist_points.each do |twist_point|
            Twister.twist [twist_point], twisties
            @configuration.reporter.reset
            run1 # :expect_new_failure => true
          end
          first_result
        else
          @configuration.load_spec_files
          run1
        end
      end

      def run1
        @world.announce_filters

        @configuration.reporter.report(@world.example_count, @configuration.randomize? ? @configuration.seed : nil) do |reporter|
          begin
            @configuration.run_hook(:before, :suite)
            @world.example_groups.ordered.map {|g| g.run(reporter)}.all? ? 0 : @configuration.failure_exit_code
          ensure
            @configuration.run_hook(:after, :suite)
          end
        end
      end

      # twisties is an array of files and/or directories which we need to analyse and prepare for twisting
      def prepare_reloadable twisties
        []  # Initially, there are no twist points
      end

      def reload twisties
        # REVISIT: Implement this
      end
    end
  end
end

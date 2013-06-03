module RSpec::Core
  class Reporter
    def initialize(*formatters)
      @formatters = formatters
      prepare
    end

    def prepare
      @example_count = @failure_count = @pending_count = 0
      @duration = @start = nil
      @terse_mode = false
    end

    def prepare_terse
      prepare
      @terse_mode = true
    end

    # @api
    # @overload report(count, &block)
    # @overload report(count, seed, &block)
    # @param [Integer] count the number of examples being run
    # @param [Integer] seed the seed used to randomize the spec run
    # @param [Block] block yields itself for further reporting.
    #
    # Initializes the report run and yields itself for further reporting. The
    # block is required, so that the reporter can manage cleaning up after the
    # run.
    #
    # ### Warning:
    #
    # The `seed` argument is an internal API and is not guaranteed to be
    # supported in the future.
    #
    # @example
    #
    #     reporter.report(group.examples.size) do |r|
    #       example_groups.map {|g| g.run(r) }
    #     end
    #
    def report(expected_example_count, seed=nil)
      start(expected_example_count)
      begin
        yield self
      ensure
        finish(seed)
      end
    end

    def start(expected_example_count)
      @start = Time.now
      notify :start, expected_example_count
    end

    def message(message)
      notify :message, message unless @terse_mode
    end

    def example_group_started(group)
      notify :example_group_started, group unless group.descendant_filtered_examples.empty? or @terse_mode
    end

    def example_group_finished(group)
      notify :example_group_finished, group unless group.descendant_filtered_examples.empty? or @terse_mode
    end

    def example_started(example)
      @example_count += 1
      notify :example_started, example unless @terse_mode
    end

    def example_passed(example)
      notify :example_passed, example unless @terse_mode
    end

    def example_failed(example)
      @failure_count += 1
      notify :example_failed, example unless @terse_mode
    end

    def example_pending(example)
      @pending_count += 1
      notify :example_pending, example unless @terse_mode
    end

    def finish(seed)
      begin
        stop
        notify :start_dump
        unless @terse_mode
          notify :dump_pending
          notify :dump_failures
        end
        notify :dump_summary, @duration, @example_count, @failure_count, @pending_count
        notify :seed, seed if seed
      ensure
        notify :close
      end
    end

    alias_method :abort, :finish

    def stop
      @duration = Time.now - @start if @start
      notify :stop
    end

    def notify(method, *args, &block)
      @formatters.each do |formatter|
        formatter.send method, *args, &block
      end
    end
  end
end

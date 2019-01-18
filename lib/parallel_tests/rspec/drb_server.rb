require 'drb/drb'
require 'drb/acl'

module ParallelTests
  module RSpec
    class DRbServer
      def self.run
        server = new
        server.start
        yield server
      ensure
        server.stop
      end

      attr_reader :example_count, :failure_count, :pending_count,
        :rerun_commands, :failure_messages, :pending_messages

      def initialize
        @example_count = 0
        @failure_count = 0
        @pending_count = 0
        @rerun_commands = []
        @failure_messages = []
        @pending_messages = []
        @semaphore = Mutex.new
      end

      def start
        # Only allow remote DRb requests from this machine.
        # DRb.install_acl ACL.new(%w[ deny all allow localhost allow 127.0.0.1 ])

        # We pass `nil` as the first arg to allow it to pick a DRb port.
        @drb = DRb.start_service("druby://localhost:9999", self)
      end

      def stop
        @drb&.stop_service
      end

      def drb_port
        @drb_port ||= Integer(@drb.uri[/\d+$/])
      end

      # only here to try and see what can be marshalled across drb
      # def add_failed_example(example)
      #   @failed_example = example
      # end

      def add_example_count(count)
        @semaphore.synchronize { @example_count += count }
      end

      def add_failure_count(count)
        @semaphore.synchronize { @failure_count += count }
      end

      def add_pending_count(count)
        @semaphore.synchronize { @pending_count += count }
      end

      def add_rerun_commands(commands)
        @semaphore.synchronize { @rerun_commands += commands }
      end

      def add_failure_messages(messages)
        @semaphore.synchronize { @failure_messages += messages }
      end

      def add_pending_messages(messages)
        @semaphore.synchronize { @pending_messages += messages }
      end

      def summarize_results
        [
          pluralize("example", example_count),
          pluralize("failure", failure_count),
          pending_count > 1 && "#{pending_count} pending"
        ].compact.join(", ")
      end

      private

      def pluralize(word, count)
        if count > 1
          "#{count} #{word}s"
        else
          "#{count} #{word}"
        end
      end
    end
  end
end

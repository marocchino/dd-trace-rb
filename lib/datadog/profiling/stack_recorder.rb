# typed: false

module Datadog
  module Profiling
    # Stores stack samples in a native libdatadog data structure and expose Ruby-level serialization APIs
    # Note that `record_sample` is only accessible from native code.
    # Methods prefixed with _native_ are implemented in `stack_recorder.c`
    class StackRecorder
      def initialize
        # This mutex works in addition to the fancy C-level mutexes we have in the native side (see the docs there).
        # It prevents multiple Ruby threads calling serialize at the same time -- something like
        # `10.times { Thread.new { stack_recorder.serialize } }`.
        # This isn't something we expect to happen normally, but because it would break the assumptions of the
        # C-level mutexes (that there is a single serializer thread), we add it here as an extra safeguard against it
        # accidentally happening.
        @no_concurrent_synchronize_mutex = Thread::Mutex.new
      end

      def serialize
        status, result = @no_concurrent_synchronize_mutex.synchronize { self.class._native_serialize(self) }

        if status == :ok
          start, finish, encoded_pprof = result

          Datadog.logger.debug { "Encoded profile covering #{start.iso8601} to #{finish.iso8601}" }

          [start, finish, encoded_pprof]
        else
          error_message = result

          Datadog.logger.error("Failed to serialize profiling data: #{error_message}")

          nil
        end
      end

      # Used only for Ruby 2.2 which doesn't have the native `rb_time_timespec_new` API; called from native code
      def self.ruby_time_from(timespec_seconds, timespec_nanoseconds)
        Time.at(0).utc + timespec_seconds + (timespec_nanoseconds.to_r / 1_000_000_000)
      end

      # This method exists only to enable testing Datadog::Profiling::StackRecorder behavior using RSpec.
      # It SHOULD NOT be used for other purposes.
      def active_slot
        self.class._native_active_slot(self)
      end

      # This method exists only to enable testing Datadog::Profiling::StackRecorder behavior using RSpec.
      # It SHOULD NOT be used for other purposes.
      def slot_one_mutex_locked?
        self.class._native_slot_one_mutex_locked?(self)
      end

      # This method exists only to enable testing Datadog::Profiling::StackRecorder behavior using RSpec.
      # It SHOULD NOT be used for other purposes.
      def slot_two_mutex_locked?
        self.class._native_slot_two_mutex_locked?(self)
      end
    end
  end
end

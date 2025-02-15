# typed: false

require_relative '../../../instrumentation/gateway'
require_relative '../../../reactive/operation'
require_relative '../reactive/request'
require_relative '../reactive/request_body'
require_relative '../reactive/response'
require_relative '../../../event'

module Datadog
  module AppSec
    module Contrib
      module Rack
        module Gateway
          # Watcher for Rack gateway events
          # rubocop:disable Metrics/ModuleLength
          module Watcher
            # rubocop:disable Metrics/AbcSize
            # rubocop:disable Metrics/MethodLength
            def self.watch
              Instrumentation.gateway.watch('rack.request') do |stack, request|
                block = false
                event = nil
                waf_context = request.env['datadog.waf.context']

                AppSec::Reactive::Operation.new('rack.request') do |op|
                  trace = active_trace
                  span = active_span

                  Rack::Reactive::Request.subscribe(op, waf_context) do |action, result, _block|
                    record = [:block, :monitor].include?(action)
                    if record
                      # TODO: should this hash be an Event instance instead?
                      event = {
                        waf_result: result,
                        trace: trace,
                        span: span,
                        request: request,
                        action: action
                      }

                      waf_context.events << event
                    end
                  end

                  _action, _result, block = Rack::Reactive::Request.publish(op, request)
                end

                next [nil, [[:block, event]]] if block

                ret, res = stack.call(request)

                if event
                  res ||= []
                  res << [:monitor, event]
                end

                [ret, res]
              end

              Instrumentation.gateway.watch('rack.response') do |stack, response|
                block = false
                event = nil
                waf_context = response.instance_eval { @waf_context }

                AppSec::Reactive::Operation.new('rack.response') do |op|
                  trace = active_trace
                  span = active_span

                  Rack::Reactive::Response.subscribe(op, waf_context) do |action, result, _block|
                    record = [:block, :monitor].include?(action)
                    if record
                      # TODO: should this hash be an Event instance instead?
                      event = {
                        waf_result: result,
                        trace: trace,
                        span: span,
                        response: response,
                        action: action
                      }

                      waf_context.events << event
                    end
                  end

                  _action, _result, block = Rack::Reactive::Response.publish(op, response)
                end

                next [nil, [[:block, event]]] if block

                ret, res = stack.call(response)

                if event
                  res ||= []
                  res << [:monitor, event]
                end

                [ret, res]
              end

              Instrumentation.gateway.watch('rack.request.body') do |stack, request|
                block = false
                event = nil
                waf_context = request.env['datadog.waf.context']

                AppSec::Reactive::Operation.new('rack.request.body') do |op|
                  trace = active_trace
                  span = active_span

                  Rack::Reactive::RequestBody.subscribe(op, waf_context) do |action, result, _block|
                    record = [:block, :monitor].include?(action)
                    if record
                      # TODO: should this hash be an Event instance instead?
                      event = {
                        waf_result: result,
                        trace: trace,
                        span: span,
                        request: request,
                        action: action
                      }

                      waf_context.events << event
                    end
                  end

                  _action, _result, block = Rack::Reactive::RequestBody.publish(op, request)
                end

                next [nil, [[:block, event]]] if block

                ret, res = stack.call(request)

                if event
                  res ||= []
                  res << [:monitor, event]
                end

                [ret, res]
              end
            end
            # rubocop:enable Metrics/MethodLength
            # rubocop:enable Metrics/AbcSize

            class << self
              private

              def active_trace
                # TODO: factor out tracing availability detection

                return unless defined?(Datadog::Tracing)

                Datadog::Tracing.active_trace
              end

              def active_span
                # TODO: factor out tracing availability detection

                return unless defined?(Datadog::Tracing)

                Datadog::Tracing.active_span
              end
            end
          end
          # rubocop:enable Metrics/ModuleLength
        end
      end
    end
  end
end

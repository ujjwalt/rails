require 'action_dispatch/routing/dsl/abstract_scope'

module ActionDispatch
  module Routing
    module DSL
      class Scope
      	include AbstractScope

        def method_missing(method, *args)
          @count ||= 0
          @count += 1
          msg = "#{@count}) Missing :#{method}"
          divider = "="*msg.length
          puts divider, msg, divider
        end

        def default_url_options=(options)
          @set.default_url_options = options
        end
        alias_method :default_url_options, :default_url_options=
      end
    end
  end
end

require 'action_dispatch/routing/dsl/scope/mount'
require 'action_dispatch/routing/dsl/scope/match'
require 'action_dispatch/routing/dsl/scope/http_helpers'
require 'action_dispatch/routing/dsl/scope/scoping'
require 'action_dispatch/routing/dsl/scope/concerns'

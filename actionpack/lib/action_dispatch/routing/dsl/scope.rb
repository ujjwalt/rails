require 'action_dispatch/routing/dsl/abstract_scope'

module ActionDispatch
  module Routing
    module DSL
      class Scope
      	include AbstractScope
      end
    end
  end
end

require 'action_dispatch/routing/dsl/scope/mount'
require 'action_dispatch/routing/dsl/scope/match'
require 'action_dispatch/routing/dsl/scope/http_helpers'
require 'action_dispatch/routing/dsl/scope/scoping'
require 'action_dispatch/routing/dsl/scope/concerns'

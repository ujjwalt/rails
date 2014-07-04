require 'action_dispatch/routing/dsl/abstract_scope'
require 'action_dispatch/routing/dsl/scope/mount'
require 'action_dispatch/routing/dsl/scope/match'
require 'action_dispatch/routing/dsl/scope/http_helpers'
require 'action_dispatch/routing/dsl/scope/scoping'
require 'action_dispatch/routing/dsl/scope/concerns'

module ActionDispatch
  module Routing
    module DSL
      class Scope < AbstractScope
      end
    end
  end
end

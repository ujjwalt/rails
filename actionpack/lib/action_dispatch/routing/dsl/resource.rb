module ActionDispatch
  module Routing
    module DSL
      class Resource < Scope
        # CANONICAL_ACTIONS holds all actions that does not need a prefix or
        # a path appended since they fit properly in their scope level.
        VALID_ON_OPTIONS  = [:new, :collection, :member]
        RESOURCE_OPTIONS  = [:as, :controller, :path, :only, :except, :param, :concerns]
        CANONICAL_ACTIONS = %w(index create new show update destroy)

        attr_reader :param

        def initialize(parent, resource, options)
          super
          @name = resource.to_s
          @path       = (options[:path] || @name).to_s
          @controller = (options[:controller] || @name).to_s
          @param      = (options[:param] || :id).to_sym

          declare_resourceful_routes
        end

        def name
          @path
        end

        def declare_resourceful_routes
          
        end
      end
    end
  end
end

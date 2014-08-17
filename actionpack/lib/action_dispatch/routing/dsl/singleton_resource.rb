require "action_dispatch/routing/dsl/resource"

module ActionDispatch
  module Routing
    module DSL
      class SingletonResource < Resource
        def initialize(parent, resource, options)
          super
          @as         = nil
          @controller = (options[:controller] || plural).to_s
          @as         = options[:as]
        end

        def default_actions
          [:show, :create, :update, :destroy, :new, :edit]
        end

        def plural
          @plural ||= name.to_s.pluralize
        end

        def singular
          @singular ||= name.to_s
        end

        alias :member_name :singular
        alias :collection_name :singular

        def member_scope
          @path
        end

        alias :nested_scope :member_scope
      end
    end
  end
end
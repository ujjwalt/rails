module ActionDispatch
  module Routing
    module DSL
      class SingletonResource < Scope
        VALID_ON_OPTIONS  = [:new, :collection, :member]
        RESOURCE_OPTIONS  = [:as, :controller, :path, :only, :except, :param, :concerns]
        CANONICAL_ACTIONS = %w(index create new show update destroy)
        RESOURCE_METHOD_SCOPES = [:collection, :member, :new]

        def initialize(parent, resource, options)
          super
          @name       = resource.to_s
          @path       = (@path || @name).to_s
          @controller = (@controller || @name.to_s.pluralize).to_s
        end

        def name
          @as || @name
        end

        def draw
          post '/', action: :create
          get '/new', action: :new
          get '/edit', action: :edit
          get '/', action: :show
          patch '/', action: :update
          put '/', action: :update
          delete '/', action: :destroy
        end

        def path_for_action(action, path) #:nodoc:
          if canonical_action?(action, path.blank?)
            self.path.to_s
          else
            super
          end
        end

        def canonical_action?(action, flag) #:nodoc:
          flag && CANONICAL_ACTIONS.include?(action.to_s)
        end

        def prefixed_name(name_prefix, prefix)
          if @parent.class != Scope
            [prefix, @parent.name, name]
          else
            [prefix, name]
          end
        end

        def member
          yield
        end

        def decomposed_match(path, options) # :nodoc:
          if on = options.delete(:on)
            send(on) { decomposed_match(path, options) }
          else
            member { add_route(path, options) }
          end
        end

        def name_for_action(as, action) #:nodoc:
          return nil unless as || action
          super
        end
      end
    end
  end
end

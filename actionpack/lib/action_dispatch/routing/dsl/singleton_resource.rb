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
          @controller = (@controller || @name).pluralize.to_s
        end

        def name
          as || @name
        end

        def draw
          post '/', action: :create, as: name
          get '/new', action: :new, as: "new_#{name}"
          get '/edit', action: :edit, as: "edit_#{name}"
          get '/', action: :show
          patch '/', action: :update
          put '/', action: :update
          delete '/', action: :destroy
        end
      end
    end
  end
end

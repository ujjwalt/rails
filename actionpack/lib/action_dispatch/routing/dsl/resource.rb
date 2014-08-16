require "action_dispatch/routing/dsl/singleton_resource"

module ActionDispatch
  module Routing
    module DSL
      class Resource < SingletonResource
        attr_reader :param

        def initialize(parent, resource, options)
          super
          @param      = (options[:param] || :id).to_sym
          @path = @path.pluralize
          @name = @name.singularize
        end

        def draw
          get '/', action: :index
          post '/', action: :create
          get '/new', action: :new
          get '/edit', action: :edit
          get "/:#{@param}", action: :show
          patch "/:#{@param}", action: :update
          put "/:#{@param}", action: :update
          delete "/:#{@param}", action: :destroy
        end

        def member
          param = ":#{name.singularize}_#{@param}"
          @path, old_path = "/#{@path}/#{param}", @path
          yield
          @path = old_path
        end

        def decomposed_match(path, options) # :nodoc:
          if on = options.delete(:on)
            send(on) { decomposed_match(path, options) }
          else
            add_route(path, options)
          end
        end

        def prefixed_name(name_prefix, prefix)
          if @parent.class != Scope
            [prefix, @parent.name, name]
          else
            if prefix.blank?
              if has_named_route?(name.pluralize)
                [name]
              else
                [name.pluralize]
              end
            else
              [prefix, name]
            end
          end
        end
      end
    end
  end
end

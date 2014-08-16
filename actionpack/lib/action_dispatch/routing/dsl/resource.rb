module ActionDispatch
  module Routing
    module DSL
      class Resource < Scope
        # CANONICAL_ACTIONS holds all actions that does not need a prefix or
        # a path appended since they fit properly in their scope level.
        VALID_ON_OPTIONS  = [:new, :collection, :member]
        RESOURCE_OPTIONS  = [:as, :controller, :path, :only, :except, :param, :concerns]
        CANONICAL_ACTIONS = %w(index create new show update destroy)
        RESOURCE_METHOD_SCOPES = [:collection, :member, :new]
        RESOURCE_SCOPES = [:resource, :resources]

        attr_reader :param

        def initialize(parent, resource, options)
          super
          # Set resource specific ivars
          @name = resource.to_s
          @controller ||= @name
          @param      = (options[:param] || :id).to_sym
          @shallow    = false
        end

        def default_actions
          [:index, :create, :new, :show, :update, :destroy, :edit]
        end

        def actions
          if only = @options[:only]
            Array(only).map(&:to_sym)
          elsif except = @options[:except]
            default_actions - Array(except).map(&:to_sym)
          else
            default_actions
          end
        end

        def name
          @as || @name
        end

        def plural
          @plural ||= name.to_s
        end

        def singular
          @singular ||= name.to_s.singularize
        end

        alias :member_name :singular

        # Checks for uncountable plurals, and appends "_index" if the plural
        # and singular form are the same.
        def collection_name
          singular == plural ? "#{plural}_index" : plural
        end

        def resource_scope
          { :controller => controller }
        end

        alias :collection_scope :path

        def member_scope
          "#{path}/:#{param}"
        end

        alias :shallow_scope :member_scope

        def new_scope(new_path)
          "#{path}/#{new_path}"
        end

        def nested_param
          :"#{singular}_#{param}"
        end

        def nested_scope
          "#{path}/:#{nested_param}"
        end

        def shallow=(value)
          @shallow = value
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

        def prefix_name_for_action(as, action) #:nodoc:
          if canonical_action?(action, @level)
            nil
          else
            super
          end
        end

        def name_for_action(as, action)
          return nil unless as || action
          super
        end

        def prefixed_name(prefix, name_prefix)
          case @level
          when :nested
            [name_prefix, prefix]
          when :collection
            [prefix, name_prefix, collection_name]
          when :new
            [prefix, :new, name_prefix, member_name]
          when :member
            [prefix, name_prefix, member_name]
          when :root
            [name_prefix, collection_name, prefix]
          else
            [name_prefix, member_name, prefix]
          end
        end

        def process_options(options)
          if options[:on] && !VALID_ON_OPTIONS.include?(options[:on])
            raise ArgumentError, "Unknown scope #{on.inspect} given to :on"
          end
          super
        end

############################################################################################

        def draw
          collection do
            get :index if actions.include?(:index)
            post :create if actions.include?(:create)
          end

          new do
            get :new
          end if actions.include?(:new)

          member do
            get :edit if actions.include?(:edit)
            get :show if actions.include?(:show)
            if actions.include?(:update)
              patch :update
              put   :update
            end
            delete :destroy if actions.include?(:destroy)
          end
        end

        def collection
          @level = :collection
          yield
          @level = nil
        end

        def new
          @level = :new
          @path, old_path = new_scope(action_path(:new)), @path
          yield
          @path = old_path
          @level = nil
        end

        def member
          @level = :member
          @path, old_path = member_scope, @path
          yield
          @path = old_path
          @level = nil
        end
      end
    end
  end
end

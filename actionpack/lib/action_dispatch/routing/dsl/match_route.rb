# MatchRoute is a special scope in the sense that it has some additonal options
# like :anchor, :to, :via and :format that are specific to routes
require 'action_dispatch/routing/dsl/scope'

module ActionDispatch
  module Routing
    module DSL
      class MatchRoute < Scope
        ROUTE_OPTIONS = [:anchor, :format, :to, :via]

        def initialize(*args)
          options_path = (args.extract_options || {})[:path]
          super # Let AbstractScope handle all stuff like setting ivar
          # Now handle route options

          # Set anchor to true by default unless a value is supplied
          @anchor = true unless options.key?(:anchor)

          # Assign options[:to] to @to and then proceed to set an approriate value if
          # it evaluates to false
          unless @to = options[:to]
            # If we have a controller and action then set 'to' to 'controller#action'
            # if it is nil
            if controller && action
              @to = "#{controller}##{action}"
            else
              # If @to is still nill then convert the path by assuming the entire
              # path to represent the controller and the last segment as action e.g.
              # match '/admin/controller/action'
              # is tanslated as match controller: 'admin/controller', action: 'action'
              #
              # But before we do that we need to check if the user specified an optional
              # format like (.:format)
              # If so then we need to consider the path without the optional parameter
              *controllers, action = @path.split('/')
              action = action.to_s.sub(/\(\.:format\)$/, '')
              @to = "#{controllers.select(&:present?).join('/')}##{action}"
            end
          end
          # Change all '-' to '_' in the to
          @to.tr!('-', '_')
        end
      end
    end
  end
end

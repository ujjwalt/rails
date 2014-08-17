module ActionDispatch
  module Routing
    module DSL
      class Resource < Scope
        def nested
          @path, old_path = nested_scope, @path
          yield
          @path = old_path
        end

        def resources(*resources)
          nested { super }
        end

        def resource(*resources)
          nested { super }
        end

        protected
          def nested_param
            :"#{singular}_#{param}"
          end

          def nested_scope
            "#{path}/:#{nested_param}"
          end

          def nested_options #:nodoc:
            options = { as: member_name }
            options[:constraints] = {
              nested_param => param_constraint
            } if param_constraint?

            options
          end

          def param_constraint? #:nodoc:
            constraints && param_constraint.is_a?(Regexp)
          end

          def param_constraint #:nodoc:
            constraints[param]
          end
      end
    end
  end
end

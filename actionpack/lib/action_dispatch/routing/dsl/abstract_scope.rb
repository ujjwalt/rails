require 'action_dispatch/routing/dsl/normalization'

module ActionDispatch
  module Routing
    module DSL
      module AbstractScope
        # Constants
        # =========
        URL_OPTIONS = [:protocol, :subdomain, :domain, :host, :port]
        SCOPE_OPTIONS = [:path, :shallow_path, :as, :shallow_prefix, :module,
                         :controller, :action, :path_names, :constraints,
                         :shallow, :blocks, :defaults, :options]

        # Accessors
        # =========
        attr_accessor :set
        attr_reader :controller, :action, :concerns, :parent

        def initialize(parent, *args)
          if parent
            @parent, @set, @concerns = parent, parent.set, parent.concerns
          else
            @parent, @concerns = nil, {}
          end

          # Extract options out of the variable arguments
          options = args.extract_options!.dup

          options[:path] = args.flatten.join('/') if args.any?
          options[:constraints] ||= {}

          if options[:constraints].is_a?(Hash)
            defaults = options[:constraints].select do
              |k, v| URL_OPTIONS.include?(k) && (v.is_a?(String) || v.is_a?(Fixnum))
            end

            (options[:defaults] ||= {}).reverse_merge!(defaults)
          else
            block, options[:constraints] = options[:constraints], {}
          end

          SCOPE_OPTIONS.each do |option|
            if option == :blocks
              value = block
            elsif option == :options
              value = options
            else
              value = options.delete(option) { |_option| {} if %w(defaults path_names constraints).include?(_option.to_s) }
            end

            # Set instance variables
            instance_variable_set(:"@#{option}", value || nil)
          end
        end

        def path
          parent_path = parent ? parent.path : nil
          merge_with_slash(parent_path, @path)
        end

        def shallow_path
          parent_shallow_path = parent ? parent.shallow_path : nil
          merge_with_slash(parent_shallow_path, @shallow_path)
        end

        def as
          parent_as = parent ? parent.as : nil
          merge_with_underscore(parent_as, @as)
        end

        def shallow_prefix
          parent_shallow_prefix = parent ? parent.shallow_prefix : nil
          merge_with_underscore(parent_shallow_prefix, @shallow_prefix)
        end

        def module
          if parent && parent.module
            if @module
              "#{parent.module}/#{@module}"
            else
              parent.module
            end
          else
            @module
          end
        end

        def path_names
          parent_path_names = parent ? parent.path_names : nil
          merge_hashes(parent_path_names, @path_names)
        end

        def shallow?
          @shallow
        end

        def blocks
          parent_blocks = parent ? parent.blocks : nil
          merged = parent_blocks ? parent_blocks.dup : []
          merged << @blocks if @blocks
          merged
        end

        def options
          parent_options = parent ? parent.options : nil
          merge_hashes(parent_options, @options)
        end

        protected
          def merge_with_slash(parent, child)
            self.class.normalize_path("#{parent}/#{child}")
          end

          def merge_with_underscore(parent, child)
            parent ? "#{parent}_#{child}" : child
          end

          def merge_hashes(parent, child)
            (parent || {}).except(*override_keys(child)).merge(child)
          end

          def override_keys(child) #:nodoc:
            child.key?(:only) || child.key?(:except) ? [:only, :except] : []
          end

          def defaults
            parent_defaults = parent ? parent.defaults : nil
            merge_hashes(parent_defaults, @defaults)
          end

          def constraints
            parent_constraints = parent ? parent.constraints : nil
            merge_hashes(parent_constraints, @constraints)
          end
      end
    end
  end
end

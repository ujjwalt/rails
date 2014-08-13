require 'action_dispatch/journey'
require 'active_support/concern'

module ActionDispatch
  module Routing
    module DSL
      module AbstractScope
        extend ActiveSupport::Concern

        included do |base|
          # Invokes Journey::Router::Utils.normalize_path and ensure that
          # (:locale) becomes (/:locale) instead of /(:locale). Except
          # for root cases, where the latter is the correct one.
          def base.normalize_path(path)
            path = Journey::Router::Utils.normalize_path(path)
            path.gsub!(%r{/(\(+)/?}, '\1/') unless path =~ %r{^/\(+[^)]+\)$}
            path
          end

          def base.normalize_name(name)
            normalize_path(name)[1..-1].tr("/", "_")
          end
        end
      end
    end
  end
end

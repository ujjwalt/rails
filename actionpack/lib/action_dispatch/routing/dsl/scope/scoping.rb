# You may wish to organize groups of controllers under a namespace.
# Most commonly, you might group a number of administrative controllers
# under an +admin+ namespace. You would place these controllers under
# the <tt>app/controllers/admin</tt> directory, and you can group them
# together in your router:
#
#   namespace "admin" do
#     resources :posts, :comments
#   end
#
# This will create a number of routes for each of the posts and comments
# controller. For <tt>Admin::PostsController</tt>, Rails will create:
#
#   GET       /admin/posts
#   GET       /admin/posts/new
#   POST      /admin/posts
#   GET       /admin/posts/1
#   GET       /admin/posts/1/edit
#   PATCH/PUT /admin/posts/1
#   DELETE    /admin/posts/1
#
# If you want to route /posts (without the prefix /admin) to
# <tt>Admin::PostsController</tt>, you could use
#
#   scope module: "admin" do
#     resources :posts
#   end
#
# or, for a single case
#
#   resources :posts, module: "admin"
#
# If you want to route /admin/posts to +PostsController+
# (without the <tt>Admin::</tt> module prefix), you could use
#
#   scope "/admin" do
#     resources :posts
#   end
#
# or, for a single case
#
#   resources :posts, path: "/admin/posts"
#
# In each of these cases, the named routes remain the same as if you did
# not use scope. In the last case, the following paths map to
# +PostsController+:
#
#   GET       /admin/posts
#   GET       /admin/posts/new
#   POST      /admin/posts
#   GET       /admin/posts/1
#   GET       /admin/posts/1/edit
#   PATCH/PUT /admin/posts/1
#   DELETE    /admin/posts/1

module ActionDispatch
  module Routing
    module DSL
      class Scope
        # Scopes a set of routes to the given default options.
        #
        # Take the following route definition as an example:
        #
        #   scope path: ":account_id", as: "account" do
        #     resources :projects
        #   end
        #
        # This generates helpers such as +account_projects_path+, just like +resources+ does.
        # The difference here being that the routes generated are like /:account_id/projects,
        # rather than /accounts/:account_id/projects.
        #
        # === Options
        #
        # Takes same options as <tt>Base#match</tt> and <tt>Resources#resources</tt>.
        #
        #   # route /posts (without the prefix /admin) to <tt>Admin::PostsController</tt>
        #   scope module: "admin" do
        #     resources :posts
        #   end
        #
        #   # prefix the posts resource's requests with '/admin'
        #   scope path: "/admin" do
        #     resources :posts
        #   end
        #
        #   # prefix the routing helper name: +sekret_posts_path+ instead of +posts_path+
        #   scope as: "sekret" do
        #     resources :posts
        #   end
        def scope(*args, &block)
          Scope.new(self, *args).instance_exec(&block)
          self
        end

        # Scopes routes to a specific controller
        #
        #   controller "food" do
        #     match "bacon", action: "bacon"
        #   end
        def controller(controller=nil, options={}, &block)
          return super() unless controller
          options[:controller] = controller
          scope(options, &block)
        end

        # Scopes routes to a specific namespace. For example:
        #
        #   namespace :admin do
        #     resources :posts
        #   end
        #
        # This generates the following routes:
        #
        #       admin_posts GET       /admin/posts(.:format)          admin/posts#index
        #       admin_posts POST      /admin/posts(.:format)          admin/posts#create
        #    new_admin_post GET       /admin/posts/new(.:format)      admin/posts#new
        #   edit_admin_post GET       /admin/posts/:id/edit(.:format) admin/posts#edit
        #        admin_post GET       /admin/posts/:id(.:format)      admin/posts#show
        #        admin_post PATCH/PUT /admin/posts/:id(.:format)      admin/posts#update
        #        admin_post DELETE    /admin/posts/:id(.:format)      admin/posts#destroy
        #
        # === Options
        #
        # The +:path+, +:as+, +:module+, +:shallow_path+ and +:shallow_prefix+
        # options all default to the name of the namespace.
        #
        # For options, see <tt>Base#match</tt>. For +:shallow_path+ option, see
        # <tt>Resources#resources</tt>.
        #
        #   # accessible through /sekret/posts rather than /admin/posts
        #   namespace :admin, path: "sekret" do
        #     resources :posts
        #   end
        #
        #   # maps to <tt>Sekret::PostsController</tt> rather than <tt>Admin::PostsController</tt>
        #   namespace :admin, module: "sekret" do
        #     resources :posts
        #   end
        #
        #   # generates +sekret_posts_path+ rather than +admin_posts_path+
        #   namespace :admin, as: "sekret" do
        #     resources :posts
        #   end
        def namespace(path, options = {}, &block)
          path = path.to_s

          defaults = {
            module:         path,
            path:           options.fetch(:path, path),
            as:             options.fetch(:as, path),
            shallow_path:   options.fetch(:path, path),
            shallow_prefix: options.fetch(:as, path)
          }

          scope(defaults.merge!(options), &block)
        end

        # === Parameter Restriction
        # Allows you to constrain the nested routes based on a set of rules.
        # For instance, in order to change the routes to allow for a dot character in the +id+ parameter:
        #
        #   constraints(id: /\d+\.\d+/) do
        #     resources :posts
        #   end
        #
        # Now routes such as +/posts/1+ will no longer be valid, but +/posts/1.1+ will be.
        # The +id+ parameter must match the constraint passed in for this example.
        #
        # You may use this to also restrict other parameters:
        #
        #   resources :posts do
        #     constraints(post_id: /\d+\.\d+/) do
        #       resources :comments
        #     end
        #   end
        #
        # === Restricting based on IP
        #
        # Routes can also be constrained to an IP or a certain range of IP addresses:
        #
        #   constraints(ip: /192\.168\.\d+\.\d+/) do
        #     resources :posts
        #   end
        #
        # Any user connecting from the 192.168.* range will be able to see this resource,
        # where as any user connecting outside of this range will be told there is no such route.
        #
        # === Dynamic request matching
        #
        # Requests to routes can be constrained based on specific criteria:
        #
        #    constraints(lambda { |req| req.env["HTTP_USER_AGENT"] =~ /iPhone/ }) do
        #      resources :iphones
        #    end
        #
        # You are able to move this logic out into a class if it is too complex for routes.
        # This class must have a +matches?+ method defined on it which either returns +true+
        # if the user should be given access to that route, or +false+ if the user should not.
        #
        #    class Iphone
        #      def self.matches?(request)
        #        request.env["HTTP_USER_AGENT"] =~ /iPhone/
        #      end
        #    end
        #
        # An expected place for this code would be +lib/constraints+.
        #
        # This class is then used like this:
        #
        #    constraints(Iphone) do
        #      resources :iphones
        #    end
        def constraints(constraints = nil, &block)
          return super() if constraints.nil?
          constraints ||= {}
          scope(:constraints => constraints, &block)
        end

        # Allows you to set default parameters for a route, such as this:
        #   defaults id: 'home' do
        #     match 'scoped_pages/(:id)', to: 'pages#show'
        #   end
        # Using this, the +:id+ parameter here will default to 'home'.
        def defaults(defaults = nil, &block)
          return super() if defaults.nil?
          defaults ||= {}
          scope(:defaults => defaults, &block)
        end
      end

    end
  end
end

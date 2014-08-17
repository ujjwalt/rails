require "action_dispatch/routing/dsl/resource"
require "action_dispatch/routing/dsl/singleton_resource"

# Resource routing allows you to quickly declare all of the common routes
# for a given resourceful controller. Instead of declaring separate routes
# for your +index+, +show+, +new+, +edit+, +create+, +update+ and +destroy+
# actions, a resourceful route declares them in a single line of code:
#
#  resources :photos
#
# Sometimes, you have a resource that clients always look up without
# referencing an ID. A common example, /profile always shows the profile of
# the currently logged in user. In this case, you can use a singular resource
# to map /profile (rather than /profile/:id) to the show action.
#
#  resource :profile
#
# It's common to have resources that are logically children of other
# resources:
#
#   resources :magazines do
#     resources :ads
#   end
#
# You may wish to organize groups of controllers under a namespace. Most
# commonly, you might group a number of administrative controllers under
# an +admin+ namespace. You would place these controllers under the
# <tt>app/controllers/admin</tt> directory, and you can group them together
# in your router:
#
#   namespace "admin" do
#     resources :posts, :comments
#   end
#
# By default the +:id+ parameter doesn't accept dots. If you need to
# use dots as part of the +:id+ parameter add a constraint which
# overrides this restriction, e.g:
#
#   resources :articles, id: /[^\/]+/
#
# This allows any character other than a slash as part of your +:id+.

module ActionDispatch
  module Routing
    module DSL
      class Scope
        # In Rails, a resourceful route provides a mapping between HTTP verbs
        # and URLs and controller actions. By convention, each action also maps
        # to particular CRUD operations in a database. A single entry in the
        # routing file, such as
        #
        #   resources :photos
        #
        # creates seven different routes in your application, all mapping to
        # the +Photos+ controller:
        #
        #   GET       /photos
        #   GET       /photos/new
        #   POST      /photos
        #   GET       /photos/:id
        #   GET       /photos/:id/edit
        #   PATCH/PUT /photos/:id
        #   DELETE    /photos/:id
        #
        # Resources can also be nested infinitely by using this block syntax:
        #
        #   resources :photos do
        #     resources :comments
        #   end
        #
        # This generates the following comments routes:
        #
        #   GET       /photos/:photo_id/comments
        #   GET       /photos/:photo_id/comments/new
        #   POST      /photos/:photo_id/comments
        #   GET       /photos/:photo_id/comments/:id
        #   GET       /photos/:photo_id/comments/:id/edit
        #   PATCH/PUT /photos/:photo_id/comments/:id
        #   DELETE    /photos/:photo_id/comments/:id
        #
        # === Options
        # Takes same options as <tt>Base#match</tt> as well as:
        #
        # [:path_names]
        #   Allows you to change the segment component of the +edit+ and +new+ actions.
        #   Actions not specified are not changed.
        #
        #     resources :posts, path_names: { new: "brand_new" }
        #
        #   The above example will now change /posts/new to /posts/brand_new
        #
        # [:path]
        #   Allows you to change the path prefix for the resource.
        #
        #     resources :posts, path: 'postings'
        #
        #   The resource and all segments will now route to /postings instead of /posts
        #
        # [:only]
        #   Only generate routes for the given actions.
        #
        #     resources :cows, only: :show
        #     resources :cows, only: [:show, :index]
        #
        # [:except]
        #   Generate all routes except for the given actions.
        #
        #     resources :cows, except: :show
        #     resources :cows, except: [:show, :index]
        #
        # [:shallow]
        #   Generates shallow routes for nested resource(s). When placed on a parent resource,
        #   generates shallow routes for all nested resources.
        #
        #     resources :posts, shallow: true do
        #       resources :comments
        #     end
        #
        #   Is the same as:
        #
        #     resources :posts do
        #       resources :comments, except: [:show, :edit, :update, :destroy]
        #     end
        #     resources :comments, only: [:show, :edit, :update, :destroy]
        #
        #   This allows URLs for resources that otherwise would be deeply nested such
        #   as a comment on a blog post like <tt>/posts/a-long-permalink/comments/1234</tt>
        #   to be shortened to just <tt>/comments/1234</tt>.
        #
        # [:shallow_path]
        #   Prefixes nested shallow routes with the specified path.
        #
        #     scope shallow_path: "sekret" do
        #       resources :posts do
        #         resources :comments, shallow: true
        #       end
        #     end
        #
        #   The +comments+ resource here will have the following routes generated for it:
        #
        #     post_comments    GET       /posts/:post_id/comments(.:format)
        #     post_comments    POST      /posts/:post_id/comments(.:format)
        #     new_post_comment GET       /posts/:post_id/comments/new(.:format)
        #     edit_comment     GET       /sekret/comments/:id/edit(.:format)
        #     comment          GET       /sekret/comments/:id(.:format)
        #     comment          PATCH/PUT /sekret/comments/:id(.:format)
        #     comment          DELETE    /sekret/comments/:id(.:format)
        #
        # [:shallow_prefix]
        #   Prefixes nested shallow route names with specified prefix.
        #
        #     scope shallow_prefix: "sekret" do
        #       resources :posts do
        #         resources :comments, shallow: true
        #       end
        #     end
        #
        #   The +comments+ resource here will have the following routes generated for it:
        #
        #     post_comments           GET       /posts/:post_id/comments(.:format)
        #     post_comments           POST      /posts/:post_id/comments(.:format)
        #     new_post_comment        GET       /posts/:post_id/comments/new(.:format)
        #     edit_sekret_comment     GET       /comments/:id/edit(.:format)
        #     sekret_comment          GET       /comments/:id(.:format)
        #     sekret_comment          PATCH/PUT /comments/:id(.:format)
        #     sekret_comment          DELETE    /comments/:id(.:format)
        #
        # [:format]
        #   Allows you to specify the default value for optional +format+
        #   segment or disable it by supplying +false+.
        #
        # === Examples
        #
        #   # routes call <tt>Admin::PostsController</tt>
        #   resources :posts, module: "admin"
        #
        #   # resource actions are at /admin/posts.
        #   resources :posts, path: "admin/posts"
        def resources(*resources, &block)
          common_behaviour_for Resource, *resources, &block
        end

        # Sometimes, you have a resource that clients always look up without
        # referencing an ID. A common example, /profile always shows the
        # profile of the currently logged in user. In this case, you can use
        # a singular resource to map /profile (rather than /profile/:id) to
        # the show action:
        #
        #   resource :profile
        #
        # creates six different routes in your application, all mapping to
        # the +Profiles+ controller (note that the controller is named after
        # the plural):
        #
        #   GET       /profile/new
        #   POST      /profile
        #   GET       /profile
        #   GET       /profile/edit
        #   PATCH/PUT /profile
        #   DELETE    /profile
        #
        # === Options
        # Takes same options as +resources+.
        def resource(*resources, &block)
          common_behaviour_for SingletonResource, *resources, &block
        end

        def prefix
          @parent.prefix if @parent
        end

        def resources_path_names(options)
          @path_names.merge!(options)
        end

        private
          def common_behaviour_for(klass, *resources, &block)
            options = resources.extract_options!.dup
            resources.each do |resource|
              new_resource = klass.new(self, resource, options)
              new_resource.instance_exec(&block) if block_given?
              new_resource.draw
            end
            self
          end
      end
    end
  end
end

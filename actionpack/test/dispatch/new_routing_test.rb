# encoding: UTF-8
require 'erb'
require 'abstract_unit'
require 'controller/fake_controllers'
require "byebug"

class TestRoutingMapper < ActionDispatch::IntegrationTest
  SprocketsApp = lambda { |env|
    [200, {"Content-Type" => "text/html"}, ["javascripts"]]
  }

  class IpRestrictor
    def self.matches?(request)
      request.ip =~ /192\.168\.1\.1\d\d/
    end
  end

  class YoutubeFavoritesRedirector
    def self.call(params, request)
      "http://www.youtube.com/watch?v=#{params[:youtube_id]}"
    end
  end

  def test_logout
    draw do
      controller :sessions do
        delete 'logout' => :destroy
      end
    end

    delete '/logout'
    assert_equal 'sessions#destroy', @response.body

    assert_equal '/logout', logout_path
    assert_equal '/logout', url_for(:controller => 'sessions', :action => 'destroy', :only_path => true)
  end

  def test_login
    draw do
      default_url_options :host => "rubyonrails.org"

      controller :sessions do
        get  'login' => :new
        post 'login' => :create
      end
    end

    get '/login'
    assert_equal 'sessions#new', @response.body
    assert_equal '/login', login_path

    post '/login'
    assert_equal 'sessions#create', @response.body

    assert_equal '/login', url_for(:controller => 'sessions', :action => 'create', :only_path => true)
    assert_equal '/login', url_for(:controller => 'sessions', :action => 'new', :only_path => true)

    assert_equal 'http://rubyonrails.org/login', url_for(:controller => 'sessions', :action => 'create')
    assert_equal 'http://rubyonrails.org/login', login_url
  end

  def test_login_redirect
    draw do
      get 'account/login', :to => redirect("/login")
    end

    get '/account/login'
    verify_redirect 'http://www.example.com/login'
  end

  def test_logout_redirect_without_to
    draw do
      get 'account/logout' => redirect("/logout"), :as => :logout_redirect
    end

    assert_equal '/account/logout', logout_redirect_path
    get '/account/logout'
    verify_redirect 'http://www.example.com/logout'
  end

  def test_namespace_redirect
    draw do
      namespace :private do
        root :to => redirect('/private/index')
        get "index", :to => 'private#index'
      end
    end

    get '/private'
    verify_redirect 'http://www.example.com/private/index'
  end

  def test_namespace_with_controller_segment
    assert_raise(ArgumentError) do
      draw do
        namespace :admin do
          get '/:controller(/:action(/:id(.:format)))'
        end
      end
    end
  end

  def test_namespace_without_controller_segment
    draw do
      namespace :admin do
        get 'hello/:controllers/:action'
      end
    end
    get '/admin/hello/foo/new'
    assert_equal 'foo', @request.params["controllers"]
  end

  def test_session_singleton_resource
    draw do
      resource :session do
        get :create
        post :reset
      end
    end

    get '/session'
    assert_equal 'sessions#create', @response.body
    assert_equal '/session', session_path

    post '/session'
    assert_equal 'sessions#create', @response.body

    put '/session'
    assert_equal 'sessions#update', @response.body

    delete '/session'
    assert_equal 'sessions#destroy', @response.body

    get '/session/new'
    assert_equal 'sessions#new', @response.body
    assert_equal '/session/new', new_session_path

    get '/session/edit'
    assert_equal 'sessions#edit', @response.body
    assert_equal '/session/edit', edit_session_path

    post '/session/reset'
    assert_equal 'sessions#reset', @response.body
    assert_equal '/session/reset', reset_session_path
  end

  def test_session_info_nested_singleton_resource
    draw do
      resource :session do
        resource :info
      end
    end

    get '/session/info'
    assert_equal 'infos#show', @response.body
    assert_equal '/session/info', session_info_path
  end

  def test_member_on_resource
    draw do
      resource :session do
        member do
          get :crush
        end
      end
    end

    get '/session/crush'
    assert_equal 'sessions#crush', @response.body
    assert_equal '/session/crush', crush_session_path
  end

  def test_redirect_modulo
    draw do
      get 'account/modulo/:name', :to => redirect("/%{name}s")
    end

    get '/account/modulo/name'
    verify_redirect 'http://www.example.com/names'
  end

  def test_redirect_proc
    draw do
      get 'account/proc/:name', :to => redirect {|params, req| "/#{params[:name].pluralize}" }
    end

    get '/account/proc/person'
    verify_redirect 'http://www.example.com/people'
  end

  def test_redirect_proc_with_request
    draw do
      get 'account/proc_req' => redirect {|params, req| "/#{req.method}" }
    end

    get '/account/proc_req'
    verify_redirect 'http://www.example.com/GET'
  end

  def test_redirect_hash_with_subdomain
    draw do
      get 'mobile', :to => redirect(:subdomain => 'mobile')
    end

    get '/mobile'
    verify_redirect 'http://mobile.example.com/mobile'
  end

  def test_redirect_hash_with_domain_and_path
    draw do
      get 'documentation', :to => redirect(:domain => 'example-documentation.com', :path => '')
    end

    get '/documentation'
    verify_redirect 'http://www.example-documentation.com'
  end

  def test_redirect_hash_with_path
    draw do
      get 'new_documentation', :to => redirect(:path => '/documentation/new')
    end

    get '/new_documentation'
    verify_redirect 'http://www.example.com/documentation/new'
  end

  def test_redirect_hash_with_host
    draw do
      get 'super_new_documentation', :to => redirect(:host => 'super-docs.com')
    end

    get '/super_new_documentation?section=top'
    verify_redirect 'http://super-docs.com/super_new_documentation?section=top'
  end

  def test_redirect_hash_path_substitution
    draw do
      get 'stores/:name', :to => redirect(:subdomain => 'stores', :path => '/%{name}')
    end

    get '/stores/iernest'
    verify_redirect 'http://stores.example.com/iernest'
  end

  def test_redirect_hash_path_substitution_with_catch_all
    draw do
      get 'stores/:name(*rest)', :to => redirect(:subdomain => 'stores', :path => '/%{name}%{rest}')
    end

    get '/stores/iernest/products'
    verify_redirect 'http://stores.example.com/iernest/products'
  end

  def test_redirect_class
    draw do
      get 'youtube_favorites/:youtube_id/:name', :to => redirect(YoutubeFavoritesRedirector)
    end

    get '/youtube_favorites/oHg5SJYRHA0/rick-rolld'
    verify_redirect 'http://www.youtube.com/watch?v=oHg5SJYRHA0'
  end

  def test_openid
    draw do
      match 'openid/login', :via => [:get, :post], :to => "openid#login"
    end

    get '/openid/login'
    assert_equal 'openid#login', @response.body

    post '/openid/login'
    assert_equal 'openid#login', @response.body
  end

  def test_bookmarks
    draw do
      scope "bookmark", :controller => "bookmarks", :as => :bookmark do
        get  :new, :path => "build"
        post :create, :path => "create", :as => ""
        put  :update
        get  :remove, :action => :destroy, :as => :remove
      end
    end

    get '/bookmark/build'
    assert_equal 'bookmarks#new', @response.body
    assert_equal '/bookmark/build', bookmark_new_path

    post '/bookmark/create'
    assert_equal 'bookmarks#create', @response.body
    assert_equal '/bookmark/create', bookmark_path

    put '/bookmark/update'
    assert_equal 'bookmarks#update', @response.body
    assert_equal '/bookmark/update', bookmark_update_path

    get '/bookmark/remove'
    assert_equal 'bookmarks#destroy', @response.body
    assert_equal '/bookmark/remove', bookmark_remove_path
  end

  def test_pagemarks
    draw do
      scope "pagemark", :controller => "pagemarks", :as => :pagemark do
        get  "new", :path => "build"
        post "create", :as => ""
        put  "update"
        get  "remove", :action => :destroy, :as => :remove
      end
    end

    get '/pagemark/build'
    assert_equal 'pagemarks#new', @response.body
    assert_equal '/pagemark/build', pagemark_new_path

    post '/pagemark/create'
    assert_equal 'pagemarks#create', @response.body
    assert_equal '/pagemark/create', pagemark_path

    put '/pagemark/update'
    assert_equal 'pagemarks#update', @response.body
    assert_equal '/pagemark/update', pagemark_update_path

    get '/pagemark/remove'
    assert_equal 'pagemarks#destroy', @response.body
    assert_equal '/pagemark/remove', pagemark_remove_path
  end

  def test_admin
    draw do
      constraints(:ip => /192\.168\.1\.\d\d\d/) do
        get 'admin' => "queenbee#index"
      end

      constraints ::TestRoutingMapper::IpRestrictor do
        get 'admin/accounts' => "queenbee#accounts"
      end

      get 'admin/passwords' => "queenbee#passwords", :constraints => ::TestRoutingMapper::IpRestrictor
    end

    get '/admin', {}, {'REMOTE_ADDR' => '192.168.1.100'}
    assert_equal 'queenbee#index', @response.body

    get '/admin', {}, {'REMOTE_ADDR' => '10.0.0.100'}
    assert_equal 'pass', @response.headers['X-Cascade']

    get '/admin/accounts', {}, {'REMOTE_ADDR' => '192.168.1.100'}
    assert_equal 'queenbee#accounts', @response.body

    get '/admin/accounts', {}, {'REMOTE_ADDR' => '10.0.0.100'}
    assert_equal 'pass', @response.headers['X-Cascade']

    get '/admin/passwords', {}, {'REMOTE_ADDR' => '192.168.1.100'}
    assert_equal 'queenbee#passwords', @response.body

    get '/admin/passwords', {}, {'REMOTE_ADDR' => '10.0.0.100'}
    assert_equal 'pass', @response.headers['X-Cascade']
  end

  def test_global
    draw do
      controller(:global) do
        get 'global/hide_notice'
        get 'global/export',      :action => :export, :as => :export_request
        get '/export/:id/:file',  :action => :export, :as => :export_download, :constraints => { :file => /.*/ }
        get 'global/:action'
      end
    end

    get '/global/dashboard'
    assert_equal 'global#dashboard', @response.body

    get '/global/export'
    assert_equal 'global#export', @response.body

    get '/global/hide_notice'
    assert_equal 'global#hide_notice', @response.body

    get '/export/123/foo.txt'
    assert_equal 'global#export', @response.body

    assert_equal '/global/export', export_request_path
    assert_equal '/global/hide_notice', global_hide_notice_path
    assert_equal '/export/123/foo.txt', export_download_path(:id => 123, :file => 'foo.txt')
  end

  def test_local
    draw do
      get "/local/:action", :controller => "local"
    end

    get '/local/dashboard'
    assert_equal 'local#dashboard', @response.body
  end

  # tests the use of dup in url_for
  def test_url_for_with_no_side_effects
    draw do
      get "/projects/status(.:format)"
    end

    # without dup, additional (and possibly unwanted) values will be present in the options (eg. :host)
    original_options = {:controller => 'projects', :action => 'status'}
    options = original_options.dup

    url_for options

    # verify that the options passed in have not changed from the original ones
    assert_equal original_options, options
  end

  def test_url_for_does_not_modify_controller
    draw do
      get "/projects/status(.:format)"
    end

    controller = '/projects'
    options = {:controller => controller, :action => 'status', :only_path => true}
    url = url_for(options)

    assert_equal '/projects/status', url
    assert_equal '/projects', controller
  end

  # tests the arguments modification free version of define_hash_access
  def test_named_route_with_no_side_effects
    draw do
      resources :customers do
        get "profile", :on => :member
      end
    end

    original_options = { :host => 'test.host' }
    options = original_options.dup

    profile_customer_url("customer_model", options)

    # verify that the options passed in have not changed from the original ones
    assert_equal original_options, options
  end

  def test_projects_status
    draw do
      get "/projects/status(.:format)"
    end

    assert_equal '/projects/status', url_for(:controller => 'projects', :action => 'status', :only_path => true)
    assert_equal '/projects/status.json', url_for(:controller => 'projects', :action => 'status', :format => 'json', :only_path => true)
  end

  def test_projects
    draw do
      resources :projects, :controller => :project
    end

    get '/projects'
    assert_equal 'project#index', @response.body
    assert_equal '/projects', projects_path

    post '/projects'
    assert_equal 'project#create', @response.body

    get '/projects.xml'
    assert_equal 'project#index', @response.body
    assert_equal '/projects.xml', projects_path(:format => 'xml')

    get '/projects/new'
    assert_equal 'project#new', @response.body
    assert_equal '/projects/new', new_project_path

    get '/projects/new.xml'
    assert_equal 'project#new', @response.body
    assert_equal '/projects/new.xml', new_project_path(:format => 'xml')

    get '/projects/1'
    assert_equal 'project#show', @response.body
    assert_equal '/projects/1', project_path(:id => '1')

    get '/projects/1.xml'
    assert_equal 'project#show', @response.body
    assert_equal '/projects/1.xml', project_path(:id => '1', :format => 'xml')

    get '/projects/1/edit'
    assert_equal 'project#edit', @response.body
    assert_equal '/projects/1/edit', edit_project_path(:id => '1')
  end

  def test_projects_with_post_action_and_new_path_on_collection
    draw do
      resources :projects, :controller => :project do
        post 'new', :action => 'new', :on => :collection, :as => :new
      end
    end

    post '/projects/new'
    assert_equal "project#new", @response.body
    assert_equal "/projects/new", new_projects_path
  end

  def test_projects_involvements
    draw do
      resources :projects, :controller => :project do
        resources :involvements, :attachments
      end
    end

    get '/projects/1/involvements'
    assert_equal 'involvements#index', @response.body
    assert_equal '/projects/1/involvements', project_involvements_path(:project_id => '1')

    get '/projects/1/involvements/new'
    assert_equal 'involvements#new', @response.body
    assert_equal '/projects/1/involvements/new', new_project_involvement_path(:project_id => '1')

    get '/projects/1/involvements/1'
    assert_equal 'involvements#show', @response.body
    assert_equal '/projects/1/involvements/1', project_involvement_path(:project_id => '1', :id => '1')

    put '/projects/1/involvements/1'
    assert_equal 'involvements#update', @response.body

    delete '/projects/1/involvements/1'
    assert_equal 'involvements#destroy', @response.body

    get '/projects/1/involvements/1/edit'
    assert_equal 'involvements#edit', @response.body
    assert_equal '/projects/1/involvements/1/edit', edit_project_involvement_path(:project_id => '1', :id => '1')
  end

  def test_projects_attachments
    draw do
      resources :projects, :controller => :project do
        resources :involvements, :attachments
      end
    end

    get '/projects/1/attachments'
    assert_equal 'attachments#index', @response.body
    assert_equal '/projects/1/attachments', project_attachments_path(:project_id => '1')
  end

  def test_projects_participants
    draw do
      resources :projects, :controller => :project do
        resources :participants do
          put :update_all, :on => :collection
        end
      end
    end

    get '/projects/1/participants'
    assert_equal 'participants#index', @response.body
    assert_equal '/projects/1/participants', project_participants_path(:project_id => '1')

    put '/projects/1/participants/update_all'
    assert_equal 'participants#update_all', @response.body
    assert_equal '/projects/1/participants/update_all', update_all_project_participants_path(:project_id => '1')
  end

  def test_projects_companies
    draw do
      resources :projects, :controller => :project do
        resources :companies do
          resources :people
          resource  :avatar, :controller => :avatar
        end
      end
    end

    get '/projects/1/companies'
    assert_equal 'companies#index', @response.body
    assert_equal '/projects/1/companies', project_companies_path(:project_id => '1')

    get '/projects/1/companies/1/people'
    assert_equal 'people#index', @response.body
    assert_equal '/projects/1/companies/1/people', project_company_people_path(:project_id => '1', :company_id => '1')

    get '/projects/1/companies/1/avatar'
    assert_equal 'avatar#show', @response.body
    assert_equal '/projects/1/companies/1/avatar', project_company_avatar_path(:project_id => '1', :company_id => '1')
  end

  private

  def draw(&block)
    self.class.stub_controllers do |routes|
      @app = routes
      @app.default_url_options = { host: 'www.example.com' }
      @app.draw(&block)
    end
  end

  def url_for(options = {})
    @app.url_helpers.url_for(options)
  end

  def method_missing(method, *args, &block)
    if method.to_s =~ /_(path|url)$/
      @app.url_helpers.send(method, *args, &block)
    else
      super
    end
  end

  def with_https
    old_https = https?
    https!
    yield
  ensure
    https!(old_https)
  end

  def verify_redirect(url, status=301)
    assert_equal status, @response.status
    assert_equal url, @response.headers['Location']
    assert_equal expected_redirect_body(url), @response.body
  end

  def expected_redirect_body(url)
    %(<html><body>You are being <a href="#{ERB::Util.h(url)}">redirected</a>.</body></html>)
  end
end

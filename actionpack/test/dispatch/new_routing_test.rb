# encoding: UTF-8
require 'erb'
require 'abstract_unit'
require 'controller/fake_controllers'

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

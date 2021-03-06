require "storytime/engine"
require "storytime/mysql_search_adapter"
require "storytime/mysql_fulltext_search_adapter"
require "storytime/postgres_search_adapter"
require "storytime/sqlite3_search_adapter"

module Storytime
  autoload :MysqlSearchAdapter,         'storytime/mysql_search_adapter'
  autoload :MysqlFulltextSearchAdapter, 'storytime/mysql_fulltext_search_adapter'
  autoload :PostgresSearchAdapter,      'storytime/postgres_search_adapter'
  autoload :Sqlite3SearchAdapter,       'storytime/sqlite3_search_adapter'
  autoload :PostNotifier,               'storytime/post_notifier'

  # Model to use for Storytime users.
  mattr_accessor :user_class
  @@user_class = 'User'

  # Path of Storytime's dashboard, relative to
  # Storytime's mount point within the host app.
  mattr_accessor :dashboard_namespace_path
  @@dashboard_namespace_path = "/storytime"

  # Path of Storytime's home page, relative to
  # Storytime's mount point within the host app.
  mattr_accessor :home_page_path
  @@home_page_path = "/"

  # Path used to sign users in. 
  mattr_accessor :login_path
  @@login_path = '/users/sign_in'

  # Path used to log users out. 
  mattr_accessor :logout_path
  @@logout_path = '/users/sign_out'

  # Method used for Storytime user logout path.
  mattr_accessor :logout_method
  @@logout_method = :delete

  # Enable file uploads through Carrierwave.
  mattr_accessor :enable_file_upload
  @@enable_file_upload = true

  # Character limit for Storytime::Post.title <= 255
  mattr_accessor :post_title_character_limit
  @@post_title_character_limit = 255

  # Character limit for Storytime::Post.excerpt
  mattr_accessor :post_excerpt_character_limit
  @@post_excerpt_character_limit = 500

  # Array of tags to allow from the Summernote WYSIWYG
  # Editor when editing Posts and custom post types.
  # An empty array, "", or nil setting will permit all tags.
  mattr_accessor :whitelisted_post_html_tags
  @@whitelisted_post_html_tags = []

  # Hook for handling post content sanitization.
  # Accepts either a Lambda or Proc which can be used to
  # handle how post content is sanitized (i.e. which tags,
  # HTML attributes to allow/disallow.
  mattr_accessor :post_sanitizer
  @@post_sanitizer = Proc.new do |draft_content|
    white_list_sanitizer = if Rails::VERSION::MINOR <= 1
      HTML::WhiteListSanitizer.new
    else
      Rails::Html::WhiteListSanitizer.new
    end

    attributes = %w(
      id class href style src title width height alt value 
      target rel align disabled
    )

    if Storytime.whitelisted_post_html_tags.blank?
      white_list_sanitizer.sanitize(draft_content, attributes: attributes)
    else
      white_list_sanitizer.sanitize(draft_content,
                                    tags: Storytime.whitelisted_post_html_tags,
                                    attributes: attributes)
    end
  end

  # Enable Disqus comments using your forum's shortname,
  # the unique identifier for your website as registered on Disqus.
  mattr_accessor :disqus_forum_shortname
  @@disqus_forum_shortname = ""

  # Enable Discourse comments using your discourse server,
  # Your discourse server must be configured for embedded comments.
  # NOTE:  include the '/' suffix at the end of the url
  # e.g. config.discourse_name = "http://forum.example.com"
  mattr_accessor :discourse_name
  @@discourse_name = ""

  # Email regex used to validate email format validity for subscriptions.
  mattr_accessor :email_regexp
  @@email_regexp = /\A[^@\s]+@([^@\s]+\.)+[^@\s]+\z/

  # Email address of the sender of subscription emails.
  mattr_accessor :subscription_email_from
  @@subscription_email_from = "no-reply@example.com"

  # Hook for handling notification delivery when publishing content.
  # Accepts either a Lambda or Proc which can be setup to schedule
  # a ActiveJob (Rails 4.2+).
  mattr_accessor :on_publish_with_notifications
  @@on_publish_with_notifications = nil

  # Search adapter to use for searching through Storytime Posts or
  # Post subclasses. Options for the search adapter include:
  # Storytime::PostgresSearchAdapter, Storytime::MysqlSearchAdapter,
  # Storytime::MysqlFulltextSearchAdapter, Storytime::Sqlite3SearchAdapter
  mattr_accessor :search_adapter
  @@search_adapter = ''

  class << self
    attr_accessor :layout, :media_storage, :s3_bucket, :post_types
    
    def configure
      self.post_types ||= []

      yield self
    end

    def user_class
      @@user_class.constantize
    end

    def user_class_underscore
      @@user_class.underscore
    end

    def user_class_underscore_all
      @@user_class.underscore.gsub('/', '_')
    end

    def user_class_symbol
      @@user_class.underscore.to_sym
    end

    def snippet(name)
      snippet = Storytime::Snippet.find_by(name: name)
      snippet.nil? ? "" : snippet.content.html_safe
    end

    def home_page_route_options
      site = Storytime::Site.first if ActiveRecord::Base.connection.table_exists? 'storytime_sites'

      if site
        if site.root_page_content == "page"
          { to: "pages#show", as: :storytime_root_post }
        else
          { to: "posts#index", as: :storytime_root_post }
        end
      else
        { to: "application#setup", as: :storytime_root }
      end
    end

    def post_index_path_options
      site = Storytime::Site.first if ActiveRecord::Base.connection.table_exists? 'storytime_sites'

      if site && site.root_page_content == "posts"
        { path: Storytime.home_page_path }
      else
        {}
      end
    end
  end
end

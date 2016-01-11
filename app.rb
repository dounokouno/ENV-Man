require 'sinatra'
require 'sinatra/reloader' if development?
require 'haml'
require 'i18n'
require 'i18n/backend/fallbacks'
require 'rack/contrib'
require 'socket'

set :haml, escape_html: true

before do
  I18n::Backend::Simple.send :include, I18n::Backend::Fallbacks
  I18n.load_path = Dir[File.join(settings.root, 'locales', '*.yml')]
  I18n.backend.load_translations
  I18n.default_locale = :en
  I18n.locale = env["HTTP_ACCEPT_LANGUAGE"][0,2] if env["HTTP_ACCEPT_LANGUAGE"]
end

get '/' do
  @locals = locals
  @envs = envs
  haml :home
end

get '/json' do
  require 'json'

  content_type 'application/json', charset: 'utf-8'
  envs[:values].to_h.to_json
end

get '/xml' do
  require 'active_support'
  require 'active_support/core_ext/hash/conversions'

  content_type 'application/xml', charset: 'utf-8'
  envs[:values].to_h.to_xml root: 'VALUABLES'
end

get '/plain_text' do
  @envs = envs[:values]

  content_type 'text/plain', charset: 'utf-8'
  haml :plain_text, layout: false
end

get '/plain_html' do
  @envs = envs[:values]
  haml :plain_html, layout: false
end

get '/about' do
  haml :about
end

get '/about_ja' do
  haml :about_ja
end

def envs
  hash = {}
  hash[:values] = {}
  hash[:browsers] = {}
  hash[:servers] = {}

  env.each do |key,value|
    if key =~ /[A-Z]/ && key !~ /password/i
      hash[:values][key] = value

      if key =~ /^HTTP_|^PATH_INFO$|^QUERY_STRING$|^REQUEST_|^SCRIPT_NAME$/
        hash[:browsers][key] = value
      else
        hash[:servers][key] = value
      end
    end
  end

  hash[:values] = hash[:values].sort
  hash[:browsers] = hash[:browsers].sort
  hash[:servers] = hash[:servers].sort

  hash
end

helpers do
  def t *args
    I18n.t *args
  end
end

def locals
  hash = {}
  hash[:locals] = {}
  hash[:locals]["HOSTNAME"] = Socket.gethostname
  hash[:locals]["LOCAL_IP"] = IPSocket.getaddress(Socket.gethostname)

  hash
end

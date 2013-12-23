##
##            DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
##                    Version 2, December 2004
## 
## Everyone is permitted to copy and distribute verbatim or modified
## copies of this license document, and changing it is allowed as long
## as the name is changed.
## 
##            DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
##   TERMS AND CONDITIONS FOR COPYING, DISTRIBUTION AND MODIFICATION
## 
##  0. You just DO WHAT THE FUCK YOU WANT TO.
##  1. DON'T FUCKING SHOUT THESE FUCKING PROFANITIES, FOR FUCK'S SAKE!

require 'rss'
require 'open-uri'
require 'yaml'
require 'fileutils'

class Descartes
  class FansubReleases
    include Cinch::Plugin
   

    def retrieve_posts(title)
      posts = []

      #retrieving the feeds
      get_fansub_urls().each {|fansub_name, url|
        begin
          open(url) do |rss|
            feed = RSS::Parser.parse(rss)
            feed.items.each do |item|
              posts << ({:item => item, :fansub_name => fansub_name}) if item.title.downcase.include? title
            end
          end
        rescue
          #probably the feed is malformed or not standard.
          #not warning the user at the moment.
        end
      }

      #ordering according to the publication date
      posts.sort! {|f_item, s_item| s_item[:item].pubDate - f_item[:item].pubDate}

      #returning 'em all
      return posts
    end

    def get_fansub_urls
      file = File.join File.dirname(__FILE__), 'files', 'fansub_rss_feeds.yml'
      FileUtils.touch file unless File.exists? file
      YAML.load_file(file) || {}
    end

    match /released( limit=[0-9]{1,2}){0,1} (.+)/,  method: :show_released
    #match /released\?( limit=[0-9]{1,2}){0,1} (.+)/, use_prefix: false, method: :show_released
    def show_released(m, limit, title)
      m.reply "Mi duole constatare che la biblioteca non abbia tomi." if get_fansub_urls().empty?
      if not limit
        limit = 3
      elsif limit.empty?
        limit = 3
      else
        limit = limit.match("[0-9]{1,2}")[0].to_i
        limit = 3 if limit == 0 #smartasses are everywhere!
      end 
      posts = retrieve_posts(title.downcase)
      posts = posts.slice(0, limit) #==> getting the first #limit posts
      posts.each do |post|
      	m.reply "[#{post[:fansub_name]}] #{post[:item].title} -> #{post[:item].link}"
      end 
    end

    match /released_by (.*)/, method: :show_released_by
    def show_released_by(m, fansubber)
    end

    match /fansub (list|show)/, method: :show_list
    def show_list(m)
       get_fansub_urls().each{ |name, url|
             m.reply "[#{name}] => #{url}" 
         }
    end

    match /fansub add (\w{1,}) (.*)/, method: :add_fansub
    def add_fansub(m, fansub_name, rss_url)
      urls              = get_fansub_urls()
      urls[fansub_name] = rss_url

      file = File.join File.dirname(__FILE__), 'files', 'fansub_rss_feeds.yml'
      File.open(file, ?w) { |f| f.write YAML.dump(urls) }

      m.reply "Ok, added fansub #{fansub_name}."
    end

    match /fansub remove (\w{1,})/,  method: :remove_fansub
    def remove_fansub(m, fansub_name)
      urls = get_fansub_urls
      urls.delete fansub_name

      file  = File.join File.dirname(__FILE__), 'files', 'fansub_rss_feeds.yml'
      File.open(file, ?w) { |f| f.write YAML.dump(urls) }

      m.reply "Ok, removed fansub #{fansub_name}."
    end


    match /fansub help/, method: :help
    def help(m)
       m.reply <<-HELP
fansub is a cool module for your anime necessities!
!released [limit=<1-99>] <title> ==> shows the list of releases for a given anime (output limited by optional parameter "limit")
!fansub add <fansubname> <RSS_feed> ==> adds the fansub to the sources Descartes will look into
!fansub remove <fansubname> ===> remove the fansub from the sources
!fansub show => lists the fansubs. an alias is !fansub list
       HELP
    end

  end
end

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
      posts = Array.new()

      #retrieving the feeds
      for fansub_name, url in get_fansub_urls()
        begin
          open(url) do |rss|
            feed = RSS::Parser.parse(rss)
            feed.items.each do |item|
              posts.push {:item => item, :fansub_name => fansub_name} if item.title.downcase.include? title
            end
          end
        rescue
          #probably the feed is malformed or not standard.
          #not warning the user at the moment.
        end
      end 

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

    match 'released? (.+)', :use_prefix =>false,  method: :show_released
    def show_released(m, title, limit = 3)
      posts = retrieve_posts(title.downcase)
      posts = posts.slice(0, limit+1) #==> getting the first #limit posts
      posts.each do |post|
      	m.reply "[#{post[:fansub_name]}] #{post[:item].title} -> #{post[:item].link}"
      end 
    end

    match /fansub add (\w{1,} (.*))/, method: :add_user
    def add_user(m, fansub_name, rss_url)
      urls              = get_fansub_urls
      urls[fansub_name] = rss_url

      file = File.join File.dirname(__FILE__), 'files', 'fansub_rss_feeds.yml'
      File.open(file, ?w) { |f| f.write YAML.dump(urls) }

      m.reply "Ok, added fansub #{fansub_name}."
    end

    match /fansub remove (\w{1,})/,  method: :remove_user
    def remove_user(m, fansub_name)
      urls = get_fansub_urls
      urls.delete fansub_name

      file  = File.join File.dirname(__FILE__), 'files', 'fansub_rss_feeds.yml'
      File.open(file, ?w) { |f| f.write YAML.dump(urls) }

      m.reply "Ok, removed fansub #{fansub_name}."
    end

  end
end

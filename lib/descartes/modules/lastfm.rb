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
##

require 'rockstar'
require 'yaml'
require 'fileutils'

class Descartes
  class LastFm
    include Cinch::Plugin

    def authenticate!
      Rockstar.lastfm = {
        :api_key    => 'bc15f325a6aa7dcc4e8d2df74ade7cdd',
        :api_secret => 'c055b169a789ce6491a1b016ff6ebb21'
      }
    end

    def get_lastfm_nicks_archive
      file = File.join File.dirname(__FILE__), 'files', 'lastfm_nicks.yml'
      FileUtils.touch file unless File.exists? file
      YAML.load_file(file) || {}
    end

    match 'lastsong', method: :last_played_song
    def last_played_song(m)
      authenticate!

      usernick   = m.user.nick
      lastfmnick = get_lastfm_nicks_archive[usernick]
      m.reply "Hey #{usernick}, I don't know your Last.fm nick. add it using '!lastfmuser add <lastfmnick>'." unless lastfmnick

      user  = Rockstar::User.new lastfmnick
      track = user.recent_tracks.first

      album = track.album.empty? ? "in #{track.album}" : 'in no known album'
      if track.now_playing?
        m.reply "#{lastfmnick} is listening to #{track.name} by #{track.artist} (#{album}) right now!"
      else
        m.reply "The last song #{lastfmnick} listened to is #{track.name} by #{track.artist} (#{album})."
      end
    end

    match /lastfmuser add (\w{1,15})/, method: :add_user
    def add_user(m, lastfmnick)
      nicks              = get_lastfm_nicks_archive
      nicks[m.user.nick] = lastfmnick

      file = File.join File.dirname(__FILE__), 'files', 'lastfm_nicks.yml'
      File.open(file, ?w) { |f| f.write YAML.dump(nicks) }

      m.reply "Ok, added user #{lastfmnick}."
    end

    match /lastfmuser remove (\w{1,15})/,  method: :remove_user
    def remove_user(m, lastfmnick)
      nicks = get_lastfm_nicks_archive
      nicks.delete lastfmnick

      file  = File.join File.dirname(__FILE__), 'files', 'lastfm_nicks.yml'
      File.open(file, ?w) { |f| f.write YAML.dump(nicks) }

      m.reply "Ok, removed user #{lastfmnick}."
    end

    match /lastfmuser show ([^\b]+)/, method: :show_relations
    def show_relations(m, usernicks)
      usernick_list = usernicks.split
      found         = false

      get_lastfm_nicks_archive.each { |usernick, lastfmnick|
        if usernick_list.include? usernick
          found = true                                    
          m.reply "#{usernick} is known as #{lastfmnick}."
        end
      }

      m.reply 'I don\'t know anthing, I know only what I know.' unless found
    end

  end
end

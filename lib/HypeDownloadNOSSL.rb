require 'rubygems'
require 'mechanize'
require 'logger'

log_file = "log.txt"
save_to = 'C:/Users/Samwise/Music/hypeTest/ledig/'

def clean_filename(filename)
  if (filename == nil)
    ""
  else
    filename = filename.gsub(/[^\w \- \(\)\.\']*/, "")
    filename.gsub(/\.\.\./, "")
  end
end
def prompt_int(prompt, default)
  prompt = prompt + " [#{default}]" if (default != nil)
  prompt += ": "
  while true
    print prompt
    val = gets.strip
    return default if (val == "" && default != nil)
    begin
      return Integer(val)
    rescue ArgumentError
      puts "Invalid integer, try again"
    end
  end
end

def prompt_string(prompt, default)
  prompt = prompt + " [#{default}]" if default != nil
  prompt = prompt + ": "
  while true
    print prompt
    val = gets.strip
    return default if (val == "" && default != nil)
    return val if val != ""
    puts "Invalid value, try again"
  end
end

start_page = prompt_int("Start with page", 1)
total_pages = prompt_int("Total pages to download", 1)
page_limit  = prompt_int("Songs per page", -1)
username = prompt_string("Username", username)
puts "We will download from page #{start_page} with total pages #{total_pages} with username #{username}"


agent = Mechanize.new

#not the ideal way - but getting lots of SSL errors on every soundcloud download
#http://stackoverflow.com/questions/8567973/why-does-accessing-a-ssl-site-with-mechanize-on-windows-fail-but-on-mac-work
agent.agent.http.verify_mode = OpenSSL::SSL::VERIFY_NONE

if File.exists?(log_file)
   File.delete(log_file)
end

agent.log = Logger.new(log_file)
=begin
page = agent.get('http://hypem.com/sirclesam/1')
song_list_str = page.search("#displayList-data").first.content
song_json = JSON.parse(song_list_str)
songs = song_json['tracks']
=end
songs = []

total_pages.times do |page_index|
  current_page = start_page + page_index
  url = "http://hypem.com/#{username}/#{current_page}"
  page = agent.get(url)
  song_list_str = page.search("#displayList-data").first.content
  song_json = JSON.parse(song_list_str)
  songs = song_json['tracks']

  puts "\n\nStarting on Page:#{current_page}\n\n"

  songs.each_with_index do |song,index|
    json_url = "http://hypem.com/serve/source/#{song['id']}/#{song['key']}"
    filename = "#{save_to}/#{clean_filename(song['artist'])} - #{clean_filename(song['song'])}.mp3"
    next if (File.exists?(filename))

    begin
      data_string = agent.get_file(json_url)
    rescue Exception => e
      puts "Exception #{e.message}\nwhile trying to fetch json for file #{song['song']}"
    end

    if (data_string != nil)
      data = JSON.parse(data_string)
      song_url = data["url"]
      puts " ************** Downloading song ******************"
      puts "\tartist: #{song['artist']}\n\ttitle: #{song['song']}\n\turl: #{song_url}\n\tfile: #{filename}"
      agent.pluggable_parser.default = Mechanize::Download
      begin
        agent.get(song_url).save(filename)

      rescue Exception => e
        puts "Exception #{e.message}\nwhile trying to fetch mp3 file for #{song['song']}"
      end
    end
  end
end

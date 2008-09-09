require 'rubygems'
require 'activesupport'
require 'open-uri'


module MTV
  class Error < StandardError; end
    
  class << self
    attr_accessor :base_url, :host, :protocol
  end

  self.host = "api.mtvnservices.com/1"
  self.protocol = "http"
  self.base_url = "#{protocol}://#{host}"
  
  class Base
    def initialize(values={})
      values.each { |k, v| send "#{k}=", v }
    end

    class << self
      def request path
        url = URI.escape "#{MTV.base_url}/#{path}"
        puts "Requesting url #{url}"
        open url
      end
    end
  end
  
  # This class represents a musical artist in MTV's database.
  class Artist < Base
    attr_accessor :name, :uid, :uri, :links, :updated

    def initialize(values={})
      super(values)
      self.uid = uri.gsub(MTV.base_url + "/artist", '').delete '/' if uri
    end
    
    # artist = Artist.search('In Flames')[2]
    # artist.browse => I Am Ghost, IB3, INXS, Ice Cube, ...
    def browse
      @browse ||= Artist.browse(uid.first)
    end

    # artist = Artist.search 'Frank Zappa'
    # artist.browse => Amon Amarth, Amorphis, Arch Enemy, Arcturus, Borknagar, ...
    def related
      @related ||= Artist.related(self)
    end
    
    class << self
      # Artist.browse 'x' => X, X-Clan, The X-Ecutioners, Xiren, Xscape, Xtreme, Xzibit
      def browse(letter='a')
        response = request "artist/browse/#{letter.to_s.first}/"
        parse_many response
      end
      
      # Artist.find 'beck'
      def find(name, options={})
        return name if name.is_a? Artist
        
        options.to_options!
        name = options[:name] || name
        
        response = request "artist/#{name}/"
        parse_one response
      end
      
      # Artist.related 'qtip'
      # Artist.related Artist.find('qtip')
      def related(artist)
        artist = find(artist)
        response = request "artist/#{artist.uid}/related/"
        parse_many response
      end
      
      # Artist.search 'beck', :max_results => 1, :start_index => 1
      def search(term=nil, options={})
        options.to_options!
        params = {}
        params[:'max-result']  = options[:max_result] || 1
        params[:'start-index'] = options[:start_index]
        term                   = options[:term] || term
        params.reject! { |k,v| !v }
        response = request "artist/search?#{term.to_query('term')}&#{params.to_param}"
        parse_many response.read
      end
      
      protected
      def parse_many(body)
        entries = Hash.from_xml(body)['feed']['entry']
        entries = [entries] unless entries.is_a? Array
        entries.map { |entry|
          instantiate entry
        }.reject { |artist| artist.name.nil? || artist.name.empty? }
      end
      
      def parse_one(body)
        entry = Hash.from_xml(body)['entry']
        raise Error, "That artist not found!" if entry['author']['name'].nil? || entry['author']['name'].empty?
        instantiate entry
      end
      
      def instantiate(entry={})
        Artist.new(:name => (entry['author']['name'] rescue nil),
                   :uri => (entry['author']['uri'] rescue nil),
                   :links => (entry['link'].map { |link| link['href'] } rescue nil),
                   :updated => (entry['updated'].to_datetime rescue nil))
      end
    end
  end

  # This class represents a music video in MTV's database.
  class Video < Base
    attr_accessor :name, :uid, :uri, :links, :updated

    def initialize(values={})
      super(values)
#      self.uid = uri.gsub(MTV.base_url + "/artist", '').delete '/' if uri
    end
    
    class << self
      # Video.find 'beck'
      def find(uid, options={})
        return uid if uid.is_a? Artist
        
        options.to_options!
        uid = options[:uid] || uid
        
        response = request "video/#{uid}/"
        parse_one response
      end
      
      # http://api.mtvnservices.com/1/video/search/[parameters]
      # Video.search 'beck', :max_results => 1, :start_index => 1
      def search(term=nil, options={})
        options.to_options!
        params = {}
        params[:'max-result']  = options[:max_result] || 1
        params[:'start-index'] = options[:start_index]
        term                   = options[:term] || term
        params.reject! { |k,v| !v }
        response = request "video/search?#{term.to_query('term')}&#{params.to_param}"
        parse_many response.read
      end
      
      protected
      def parse_many(body)
        entries = Hash.from_xml(body)['feed']['entry']
        entries = [entries] unless entries.is_a? Array
        entries.map { |entry|
          instantiate entry
        }.reject { |video| video.name.nil? || video.name.empty? }
      end
      
      def parse_one(body)
        entry = Hash.from_xml(body)['entry']
        raise Error, "That artist not found!" if entry['author']['name'].nil? || entry['author']['name'].empty?
        instantiate entry
      end
      
      def instantiate(entry={})
        puts "the entry is #{entry.inspect}"
        Video.new
        # TODO finish Video stuff
        # (:thumbnails => entry['thumbnail'],
        #           :player => entry['player'],
        #           :title => entry['title'].to_s,
        #           :published => entry['published'],
        #           :author => entry['author']['name'])
      end
    end
  end
  
  class Thumbnail
    attr_accessor :url, :width, :height
    def initialize(url, width, height)
      self.url = url
      self.width = width
      self.height = height
    end
  end

end


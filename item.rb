require 'twitter'

class Item

  attr_accessor :id
  attr_accessor :created_at
  attr_accessor :name
  attr_accessor :text
  attr_accessor :need_save
  attr_accessor :source
  attr_accessor :img_url

  def initialize(a, need_save)
    self.need_save = need_save
    if a.is_a?(Twitter::Tweet)
      self.source = "twitter"
      self.id = a.id
      self.created_at = a.created_at
      self.name = a.from_user
      self.text = a.full_text
    elsif a.is_a?(Hash)
      # :NOTE: 20130807 tgl: At this time, only Facebook uses a hash.
      self.source = "facebook"
      self.id = a['id']
      self.created_at = Time.parse(a['created_time'])
      self.name = a['from']['name']
      if a['message']
        self.text = a['message']
      elsif a['story']
        self.text = a['story']
      end
      self.img_url = a['picture']
    end
  end

  def source_img
    if source == "twitter"
      
    end
  end

  def name_html
    if source == "twitter"
      "<a href=\"https://twitter.com/#{name}\">@#{name}</a>"
    elsif source == "facebook"
      ids = self.id.split("_")
      "<a href=\"https://www.facebook.com/#{ids[0]}\">#{name}</a>"
    else
      "#{name}"
    end
  end

  def text_html
    s = text
  end

  def ugh
    #regexps
    url = /( |^)http:\/\/([^\s]*\.[^\s]*)( |$)/
    user = /@(\w+)/

    #replace @usernames with links to that user
    while s =~ user
        s.sub! "@#{$1}", "<a href='https://www.twitter.com/#{$1}' >#{$1}</a>"
    end

    #replace urls with links
    while s =~ url
        n = $2
        s.sub! /( |^)http:\/\/#{name}( |$)/, " <a href='http://#{n}' >#{n}</a> "
    end
    
    s    
  end

  def permalink
    if source == "twitter"
      "<a href=\"http://twitter.com/#{self.name}/status/#{self.id}\" target=\"_blank\"><img src=\"offsite.png\"/></a>"
    elsif source == "facebook"
      ids = self.id.split("_")
      "<a href=\"https://www.facebook.com/#{ids[0]}/posts/#{ids[1]}\" target=\"_blank\"><img src=\"offsite.png\"/></a>"
    else
      "#{name}"
    end

  end

  def store(auth_token)
    if need_save == true
      # :NOTE: 20130807 tgl: There's enough of these that we shouldn't
      # care if one occasionally fails.
      RestClient.post("#{ENV['KETOS_URL']}/item",
                      {
                        :token => auth_token,
                        :source => source,
                        :created_at => created_at,
                        :text => text
                      })
    end
  end
end



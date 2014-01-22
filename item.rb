require 'twitter'

class Item

  attr_accessor :id
  attr_accessor :created_at
  attr_accessor :name
  attr_accessor :text
  attr_accessor :need_save
  attr_accessor :source
  attr_accessor :img_url
  attr_accessor :post_url

  def initialize(a, need_save)
    self.need_save = need_save
    if a.is_a?(Twitter::Tweet)
      self.source = "twitter"
      self.id = a.id
      self.created_at = a.created_at
      self.name = a.from_user
      self.text = a.full_text
      puts "**** #{a.media}"
      if a.media.size > 0
        puts "**** we got one"
        puts "**** #{a.media[0]}"
        self.img_url = a.media[0].media_url
      end
    elsif a.is_a?(Hash)
      if a['created_time'].nil?
        self.source = "tumblr"
        self.id = a['id']
        self.created_at = Time.at(a['timestamp'])
        self.name = a['post_author']
        if a['type'] == "text"
          self.text = a['body']
        elsif a['type'] == "photo"
          self.text = a['caption']
        elsif a['type'] == "quote"
          self.text = a['text']
        end
        self.img_url = a['url']
        self.post_url = a['post_url']
      else
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

    #replace @usernames with links to that user
    user = /@(\w+)/
    while s =~ user
        s.sub! "@#{$1}", "<a href='https://www.twitter.com/#{$1}' >#{$1}</a>"
    end

    #replace urls with links
    url = /( |^)http:\/\/([^\s]*\.[^\s]*)( |$)/
    while s =~ url
      name = $2.gsub("\)", "").gsub("\(", "")
      s.sub! /( |^)http:\/\/#{name}( |$)/, " <a href='http://#{name}' >#{name}</a> "
    end
    
    s    
  end
  
  def img_html
    "<img src=\"#{self.img_url}\" />"
  end

  def permalink
    if source == "twitter"
      "<a href=\"http://twitter.com/#{self.name}/status/#{self.id}\" target=\"_blank\"><img src=\"offsite.png\"/></a>"
    elsif source == "tumblr"
      "<a href=\"#{self.post_url}\" target=\"_blank\"><img src=\"offsite.png\"/></a>"
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



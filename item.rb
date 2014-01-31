require 'twitter'

class Item

  attr_accessor :id
  attr_accessor :created_at
  attr_accessor :name
  attr_accessor :display_name
  attr_accessor :text
  attr_accessor :need_save
  attr_accessor :source
  attr_accessor :img_url
  attr_accessor :post_url
  attr_accessor :title
  
  def initialize(a, need_save)
    self.need_save = need_save
    if a.is_a?(Twitter::Tweet) 
      self.source = "twitter"
      self.id = a.id
      self.created_at = a.created_at
      self.name = a.user.screen_name
      self.display_name = a.user.name
      self.text = a.full_text
      if a.media.size > 0
        self.img_url = a.media[0].media_url
      end
    elsif a.is_a?(Hash)
      if a['created_time'].nil?
        puts "**** we got one"
        puts "**** #{a.inspect}"
        self.source = "tumblr"
        self.id = a['id']
        self.created_at = Time.at(a['timestamp'])
        self.title = a['source_title']
        self.name = a['blog_name']
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

  def header_html
    if source == "twitter"
      "<a href=\"#{name_url}\">
         <strong class=\"displayname\">#{display_name}</strong>
         <span>&rlm;</span>
         <span class=\"username\">
           <s>@</s><b>#{name}</b>
         </span>
       </a>"
    elsif source == "tumblr"
      s = "Source: <em>#{title}</em>" unless title.nil?
      "<a href=\"#{name_url}\">
         <strong class=\"displayname\">#{name}</strong>
         <span>&rlm;</span>
         <span class=\"title\">
           #{s}
         </span>
       </a>"
    else
      "<a href=\"#{name_url}\">
         <strong class=\"displayname\">#{name}</strong>
         <span>&rlm;</span>
         <span class=\"username\">
           &nbsp;
         </span>
       </a>"
    end
  end

  def name_url
    if source == "twitter"
      "https://twitter.com/#{name}"
    elsif source == "facebook"
      ids = self.id.split("_")
      "https://www.facebook.com/#{ids[0]}"
    elsif source == "tumblr"
      "http://#{name}.tumblr.com"
    else
      "#{name}"
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

  def time_since
    diff_seconds = (Time.now - created_at).round
    diff_minutes = (diff_seconds / 60).round
    diff_hours = (diff_minutes / 60).round
    diff_days = (diff_hours / 24).round
    diff_years = (diff_days / 365).round

    if diff_seconds < 60
      "#{diff_seconds.to_s.strip}s"
    elsif diff_minutes < 60
      "#{diff_minutes.to_s.strip}m"
    elsif diff_hours < 24
      "#{diff_hours.to_s.strip}h"
    elsif diff_days < 365
      "#{diff_days.to_s.strip}d"
    else
      "#{diff_years.to_s.strip}y"
    end
  end

  def time_html
    "<small class=\"time\"><a href=\"#{perma_url}\"><span>#{time_since}</span></a></small>"
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

  def perma_url
    if source == "twitter"
      "http://twitter.com/#{self.name}/status/#{self.id}"
    elsif source == "tumblr"
      "#{self.post_url}"
    elsif source == "facebook"
      ids = self.id.split("_")
      "https://www.facebook.com/#{ids[0]}/posts/#{ids[1]}"
    else
      "#{name}"
    end
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



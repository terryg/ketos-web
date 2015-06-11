require 'twitter'
require 'json'
require 'hashie'

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
	attr_accessor :type
	attr_accessor :link
  attr_accessor :profile_image_url

  def to_json(*a)
    {
      'id'            => self.id,
      'created_at'    => self.created_at,
      'name'          => self.name,
      'display_name'  => self.display_name,
      'text'          => self.text,
      'need_save'     => self.need_save,
      'source'        => self.source,
      'img_url'       => self.img_url,
      'post_url'      => self.post_url,
      'title'         => self.title,
			'type'          => self.type,
			'link'          => self.link,
      'profile_image_url' => self.profile_image_url
    }.to_json(*a)
  end
  
  def initialize(a, need_save)
    self.need_save = need_save
		if a.is_a?(Hashie::Mash)
			self.source = "instagram"
			self.id = a.id
			self.created_at = Time.at(a.created_time.to_i)
			self.name = a.user.username
			self.text = a.caption.text unless a.caption.nil?
			self.img_url = a.images.low_resolution.url
			self.post_url = a.link
		elsif a.is_a?(Twitter::Tweet) 
      self.source = "twitter"
			self.id = "#{a.id}"
      self.created_at = a.created_at
      self.name = a.user.screen_name
      self.display_name = a.user.name
      self.profile_image_url = a.user.profile_image_url_https;
      self.text = a.full_text
      if a.media.size > 0
        self.img_url = a.media[0].media_url
      end
    elsif a.is_a?(Hash)
      if a['created_time'].nil?
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
				# :NOTE: 20141014 tgl: Example of a shared video on facebook.
				#  {"id"=>"1547321120_10204708651426646", "from"=>{"id"=>"1547321120", "name"=>"Eric Kamila"}, "message"=>"Sit back and relax for this.", "picture"=
				#  >"https://fbexternal-a.akamaihd.net/safe_image.php?d=AQA7MvANluo0Kz1p&w=130&h=130&url=http%3A%2F%2Fi.vimeocdn.com%2Fvideo%2F469651458_1280x720.jpg", 
#"link"=>"http://vimeo.com/90429499", "source"=>"http://vimeo.com/moogaloop.swf?clip_id=90429499&autoplay=1", "name"=>"Water", "description"=>"a brief odysse
#y into the world that i cherish most. music: \"Shopping Malls\" by SJD https://www.facebook.com/pages/SJD/12793501823 filmed on a Red Epic,…", "icon"=>"http
#s://fbstatic-a.akamaihd.net/rsrc.php/v2/yj/r/v2OnaTyTQZE.gif", "actions"=>[{"name"=>"Comment", "link"=>"https://www.facebook.com/1547321120/posts/1020470865
#1426646"}, {"name"=>"Like", "link"=>"https://www.facebook.com/1547321120/posts/10204708651426646"}], "privacy"=>{"value"=>""}, "type"=>"video", "status_type
#"=>"shared_story", "created_time"=>"2014-10-15T03:35:34+0000", "updated_time"=>"2014-10-15T03:35:34+0000"}    

        self.source = "facebook"
        self.id = a['id']
        self.created_at = Time.parse(a['created_time'])
        self.name = a['from']['name']
        if a['message']
          self.text = a['message']
        elsif a['story']
          self.text = a['story']
        else
          self.text = ""
        end
        self.img_url = a['picture']
				self.type = a['type']
				if a['link'] and a['link'].match('/vimeo/')
          self.img_url = nil
					id = /[0-9]*$/.match(a['link'])
					self.link = "//player.vimeo.com/video/#{id}"
				end
      end
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



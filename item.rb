require 'twitter'

class Item

  attr_accessor :id
  attr_accessor :created_at
  attr_accessor :name
  attr_accessor :text
  attr_accessor :need_save
  attr_accessor :source

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
      self.text = a['message']
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



class User < ActiveRecord::Base
  include Clearance::User
  include Pacecar
  include Permalink

  is_gravtastic! :email, :default => "identicon"

  has_many :presentations
  has_many :tweets
  has_many :projects
  has_many :topics
  has_many :posts, :order => "posts.created_at desc"
  has_many :apps
  has_many :events
  has_one  :feed, :as => :feed_owner, :dependent => :destroy
  belongs_to :company
  
  named_scope :with_github, :conditions => "github IS NOT NULL and github != ''"
  named_scope :with_twitter, :conditions => "twitter IS NOT NULL and twitter != ''"
  
  accepts_nested_attributes_for :feed,
    :reject_if => proc { |attrs| attrs.nil? ||
                                 attrs.all? { |key, value| value.blank? } }

  attr_accessible :twitter, :github, :feed_attributes, :company_id, :company, :first_name, :last_name, :homepage, :linkedin, :about

  validates_format_of :twitter, :with => /^\w{1,15}$/, :allow_nil => true, :allow_blank => true
  before_validation :cleanout_twitter

  def to_s
    full_name || twitter || email_username
  end
  
  def full_name
    "#{first_name} #{last_name}" if first_name? or last_name?
  end
  
  def email_username
    email.split("@").first if email
  end

  # We gracefully degradate :-)
  def main_url
    homepage || linkedin || twitter_url || github_url || nil
  end

  def has_link?
    !!main_url
  end
  
  def twitter_url
    "http://twitter.com/#{twitter}" if twitter?
  end
  
  def github_url
    "http://github.com/#{github}" if github?
  end
  
  def owns_post?(post)
    post.user == self
  end
  
  def owns_project?(project)
    project.user == self
  end
  
  def owns_presentation?(presentation)
    presentation.user = self
  end
  
  def owns_topic?(topic)
    topic.user = self
  end
  
  def owns_event?(event)
    event.user == self
  end
  
  def owns_app?(app)
    app.user == self
  end

  private

    def cleanout_twitter
      if self.twitter
        self.twitter.gsub!(/^@/, '')
        if self.twitter =~ /^(https?:\/\/)?(www\.)?twitter\.com\/(\w+)$/
          self.twitter = $3
        end
      end
    end

end

module Storytime
  class Subscription < ActiveRecord::Base
    belongs_to :site

    scope :active, -> { where(subscribed: true) }

    validates_presence_of :email
    validates_format_of :email, with: Storytime.email_regexp
    validates :email, uniqueness: true

    before_create :generate_token

    def generate_token
      key = Rails.application.secrets.secret_key_base
      digest = OpenSSL::Digest.new('sha1')

      self.token = OpenSSL::HMAC.hexdigest(digest, key, self.email)
    end

    def unsubscribe!
      update_attributes(subscribed: false)
    end
  end
end

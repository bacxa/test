class User < ActiveRecord::Base
  has_many :microposts
  attr_accessor :remember_token, :activation_token, :reset_token
  before_save   :downcase_email
  before_create :create_activation_digest
  validates :name,  presence: true, length: { maximum: 50 }
  VALID_EMAIL_REGEX = /\A[\w+\-.]+@[a-z\d\-.]+\.[a-z]+\z/i
  validates :email, presence: true, length: { maximum: 255 },
                    format: { with: VALID_EMAIL_REGEX },
                    uniqueness: { case_sensitive: false }
  has_secure_password
  validates :password, presence: true, length: { minimum: 6 }, allow_nil: true
  scope :get_users,->(id){find_by(id: id)}

  PARAMS_PERMIT = [:name, :email, :password, :password_confirmation]

  # validate :must_be_point

  # Returns the hash digest of the given string. class method
  class << self
    def digest(string)
      cost = ActiveModel::SecurePassword.min_cost ? BCrypt::Engine::MIN_COST :
                                                    BCrypt::Engine.cost

      BCrypt::Password.create(string, cost: cost)
    end

    def new_token
      SecureRandom.urlsafe_base64
    end

    def remember
      self.remember_token = User.new_token
      update_attribute(:remember_digest, User.digest(remember_token))
    end

    # def authenticated?(remember_token)
    #   return false if remember_digest.nil?
    #   BCrypt::Password.new(remember_digest).is_password?(remember_token)
    # end
    def authenticated?(attribute, token)
      digest = send("#{attribute}_digest")
      return false if digest.nil?
      BCrypt::Password.new(digest).is_password?(token)
    end
  end

  def forget
    update_attribute(:remember_digest, nil)
  end

  def activate
    update_attribute(:activated,    true)
    update_attribute(:activated_at, Time.zone.now)
  end

   def send_activation_email
    UserMailer.account_activation(self).deliver_now
  end

  def create_reset_digest
    self.reset_token = User.new_token
    update_attribute(:reset_digest,  User.digest(reset_token))
    update_attribute(:reset_sent_at, Time.zone.now)
  end

  def send_password_reset_email
    UserMailer.password_reset(self).deliver_now
  end

  def password_reset_expired?
    reset_sent_at < 2.hours.ago
  end

  def feed
    Micropost.where("user_id = ?", id)
  end

  # def must_be_point
  #   # errors.add(:point, "Day khong phai la point") if point > 10 || point < 0
  #   return if point < 10 && point > 0

  #   errors.add(:point, "Day khong phai la point")
  # end

private

  # Converts email to all lower-case.
  def downcase_email
    self.email = email.downcase
  end

  # Creates and assigns the activation token and digest.
  def create_activation_digest
    self.activation_token  = User.new_token
    self.activation_digest = User.digest(activation_token)
  end

  # def password_regex
  #   return if password.blank? || password =~ /\A(?=.*\d)(?=.*[A-Z])(?=.*\W)[^ ]{7,}\z/

  #   errors.add :password, 'Password should have more than 7 characters including 1 uppercase letter, 1 number, 1 special character'
  # end

  # def validate_each(record, attribute, value)
  #   unless value =~ /\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\z/i
  #     record.errors[attribute] << (options[:message] || "wrong email address")
  #   end
  # end

  # def validate(record)
  #   unless record.name.starts_with? 'X'
  #     record.errors[:name] << 'Need a name starting with X please!'
  #   end
  # end

end

class User < AdminBase
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable

  def admin?
    false
  end

  def full_name
    first_name + ' ' + last_name
  end

  def db_username
    email.gsub(/[^a-z0-9 ]/i, '')
  end
end
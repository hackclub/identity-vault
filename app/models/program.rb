# == Schema Information
#
# Table name: oauth_applications
#
#  id                     :bigint           not null, primary key
#  active                 :boolean          default(TRUE)
#  confidential           :boolean          default(TRUE), not null
#  name                   :string           not null
#  program_key_bidx       :string
#  program_key_ciphertext :text
#  redirect_uri           :text             not null
#  scopes                 :string           default(""), not null
#  secret                 :string           not null
#  uid                    :string           not null
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#
# Indexes
#
#  index_oauth_applications_on_program_key_bidx  (program_key_bidx) UNIQUE
#  index_oauth_applications_on_uid               (uid) UNIQUE
#
class Program < ApplicationRecord
  self.table_name = "oauth_applications"

  include ::Doorkeeper::Orm::ActiveRecord::Mixins::Application

  AVAILABLE_SCOPES = [
    { name: "basic_info", description: "See basic information about you (email, name, verification status)" },
    { name: "legal_name", description: "See your legal name" },
    { name: "address", description: "View your mailing address(es)" },
    { name: "set_slack_id", description: "associate Slack IDs with identities" }
  ].freeze

  has_many :access_grants, class_name: "Doorkeeper::AccessGrant", foreign_key: :application_id, dependent: :delete_all
  has_many :identities, through: :access_grants, source: :resource_owner, source_type: "Identity"

  has_many :organizer_positions, class_name: "Backend::OrganizerPosition", foreign_key: :program_id, dependent: :destroy
  has_many :organizers, through: :organizer_positions, source: :backend_user, class_name: "Backend::User"

  validates :name, presence: true
  validates :uid, presence: true, uniqueness: true
  validates :secret, presence: true
  validates :redirect_uri, presence: true
  validates :scopes, presence: true

  before_validation :generate_uid, on: :create
  before_validation :generate_secret, on: :create
  before_validation :generate_program_key, on: :create

  has_encrypted :program_key
  blind_index :program_key

  def oauth_application = self

  # i forget why this is like this:
  alias_method :application_id, :id

  def description = nil
  def description? = false

  def description=(value)
  end

  # </forgetting why this is like this>

  def scopes_array
    return [] if scopes.blank?
    scopes.split(" ").reject(&:blank?)
  end

  def scopes_array=(array)
    self.scopes = Doorkeeper::OAuth::Scopes.from_array(Array(array).reject(&:blank?)).to_s
  end

  def has_scope?(scope_name) = scopes.include?(scope_name.to_s)

  def authorized_for_identity?(identity) = authorized_tokens.exists?(resource_owner: identity)

  private

  def generate_uid
    self.uid = SecureRandom.hex(16) if uid.blank?
  end

  def generate_secret
    self.secret = SecureRandom.hex(32) if secret.blank?
  end

  def generate_program_key
    self.program_key = "prgmk." + SecureRandom.hex(32) if program_key.blank?
  end
end

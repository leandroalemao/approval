module Approval
  class Request < ::ActiveRecord::Base
    self.table_name_prefix = "approval_".freeze

    class << self
      def define_user_association(user_class_name)
        with_options class_name: user_class_name.to_s do
          belongs_to :request_user
          belongs_to :respond_user, optional: true
        end
      end
    end

    with_options dependent: :destroy, inverse_of: :request do
      has_many :comments, class_name: "::Approval::Comment"
      has_many :items,    class_name: "::Approval::Item"
    end

    enum state: { pending: 0, cancelled: 1, approved: 2, rejected: 3 }

    scope :recently, -> { order(id: :desc) }

    with_options presence: true do
      validates :state
      validates :request_user
      validates :respond_user, unless: :pending?
      validates :comments
      validates :items
    end

    validates_associated :comments
    validates_associated :items

    validate :ensure_state_was_pending

    before_create do
      self.requested_at = Time.current
    end

    private

      def ensure_state_was_pending
        return unless persisted?
        errors.add(:base, :already_performed) if state_was != "pending"
      end
  end
end

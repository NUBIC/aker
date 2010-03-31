require 'bcsec'

module Bcsec
  class User
    ATTRIBUTES = :username, :first_name, :middle_name, :last_name,
      :title, :business_phone, :fax, :email, :address, :city, :state, :country,
      :nu_employee_id, :personnel_id, :portals, :group_memberships

    attr_accessor *ATTRIBUTES

    def initialize(username, portals=[])
      @username = username
      @portals = [*portals]
    end

    def may_access?(portal)
      portals.include?(portal.to_sym)
    end

    def full_name
      display_name_parts = [first_name, last_name].compact
      if display_name_parts.empty?
        username
      else
        display_name_parts.join(' ')
      end
    end
  end
end


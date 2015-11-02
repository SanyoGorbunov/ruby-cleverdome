
module RubyCleverdome
  class Constants
    def self.security_levels
      {
        :view => 100,
        :modify => 200,
        :reupload => 300,
        :delete => 400,
        :owner => 500,
        :admin => 1000
      }
    end

    def self.security_group_types
      {
        :application => 0,
        :supervisor => 1,
        :owner => 2,
        :client => 3,
        :custom => 4
      }
    end
  end
end
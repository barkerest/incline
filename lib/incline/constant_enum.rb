module Incline
  class ConstantEnum
    
    attr_reader :value, :name
    
    def initialize(value)
      raise ArgumentError, 'Invalid value' unless self.class.named?(value)
      @value = value
      @name = self.class.name_for(value)
    end
    
    def to_s
      name
    end
    
    
    
    def self.named?(value)
      !name_for(value).blank?
    end
    
    def self.name_for(value)
      names.key(value) || ''
    end
    
    private
    
    def self.names
      @names ||=
          begin
            ret = {}
            constants(false).each do |nm|
              ret[nm.to_s] = const_get(nm)
            end
            ret
          end
    end
    
  end
end
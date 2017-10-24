module Incline
  class BitEnum < ConstantEnum
    
    def self.name_for(value, set_nil = false)
      ret = values.select{|(v,k)| v == value}.map{|(v,k)| k}
      return ret unless ret.blank?
      
      ret = []
      
      values.each do |(v,k)|
        if v.power_of_2? && value >= v
          if set_nil
            ret << k || v.to_s
          else
            ret << k
          end
          value -= v
        end
      end
      
      if value > 0
        ret << set_nil ? value.to_s : nil
      end
      
      ret.sort
    end
    
    def self.named?(value)
      nm = name_for(value, false)
      return false if nm.blank?
      nm.select{|v| v.nil?}.blank?
    end
    
    def to_s
      self.class.name_for(value, true).join(' | ')
    end
    
    ##
    # Enable bit checking and bit setting/clearing.
    # 
    # For instance, with a constant FLAG_1, this enables :flag_1? and :flag_1=(true|false).
    def method_missing(m,*a,&b)
      name = m.to_s
      if name[-1] == '?'
        name = name[0...-1].upcase.to_sym
        if constants(false).include?(name)
          v = const_get(name)
          return (value & v) == v
        end
      elsif name[-1] == '='
        name = name[0...-1].upcase.to_sym
        if constants(false).include?(name)
          v = const_get(name)
          if a[0]
            value |= v
          else
            value &= ~v
          end
          @name = self.class.name_for(@value)
          return a[0]
        end
      end
      super m, *a, &b
    end
    
    private
    
    def self.values
      @values ||= 
          begin
            tmp = names.map{|k,v| [ v, k ]}.sort{|a,b| b[0] <=> a[0]}
            max_bit = tmp.first[0]
            unless max_bit.power_of_2?
              pow = 1
              while pow < max_bit
                pow <<= 1
              end
              max_bit = pow >> 1
            end
            
            while max_bit > 0
              unless tmp.index{|(v,k)| v == max_bit}
                tmp << [ max_bit, nil ]
              end
              max_bit >>= 1
            end
            
            tmp.sort{|a,b| b[0] <=> a[0]}
          end
    end
    
  end
end
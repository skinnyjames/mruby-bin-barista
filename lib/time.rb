class Time
  def self.parse(input)
    if input.upcase =~ /^(\d{4})-(\d{2})-(\d{2})T(\d{2}):(\d{2}):(\d{2})\.(\d+)Z/
      Time.utc($1.to_i, $2.to_i, $3.to_i, $4.to_i, $5.to_i, $6.to_i, $7.to_i)
    elsif input.upcase =~ /^(\d{4})-(\d{2})-(\d{2})T(\d{2}):(\d{2}):(\d{2})([+-]\d{2}:?\d{2})/
      year = $1.to_i
      month = $2.to_i
      day = $3.to_i
      hour = $4.to_i
      min = $5.to_i
      sec = $6.to_i
      utc_offset = $7
      offset = 0
      if utc_offset =~ /^-(\d{2}):?(\d{2})/
        offset = - $1.to_i * 60 * 60 + $2.to_i * 60
      elsif utc_offset =~ /^+(\d{2}):?(\d{2})/
        offset = $1.to_i * 60 * 60 + $2.to_i * 60
      end
      Time.new(year, month, day, hour, min, sec, offset)
    elsif input.upcase =~ /^(\d{4})-(\d{2})-(\d{2})\s+(\d{2}):(\d{2}):(\d{2})\s+([+-]\d{2}:?\d{2})/
      year = $1.to_i
      month = $2.to_i
      day = $3.to_i
      hour = $4.to_i
      min = $5.to_i
      sec = $6.to_i
      utc_offset = $7

      if utc_offset =~ /^-(\d{2}):?(\d{2})/
        offset = - $1.to_i * 60 * 60 + $2.to_i * 60
      elsif utc_offset =~ /^\+(\d{2}):?(\d{2})/
        offset = $1.to_i * 60 * 60 + $2.to_i * 60
      end

      # only interested in this scenario
      Time.mktime(year, month, day, hour, min, sec)
    elsif input.upcase =~ /^(\d{4})-(\d{2})-(\d{2})/
      # YYYY-MM-DD
      Time.local($1.to_i, $2.to_i, $3.to_i)
    elsif input.upcase =~ /^(\d{4})(\d{2})(\d{2})/
      # YYYYMMDD as a fallback
      Time.local($1.to_i, $2.to_i, $3.to_i)
    else
      raise ArgumentError, "Failed to parse: <#{input}>"
    end
  end
end
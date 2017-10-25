class ApplicationRecord < ActiveRecord::Base
  extend Enumerize

  self.abstract_class = true

  class << self
    # fixes .where(id: 11111111111111111111111111) - bigint
    # https://github.com/rails/rails/issues/20428
    def where(*args)
      id_key = args.size == 1 && args[0].is_a?(Hash) && args[0].key?(:id)

      if id_key && _fixable_ids?(args[0][:id])
        super(id: _fix_ids(args[0][:id]))
      else
        super
      end
    end

    def _fixable_ids? ids
      ids.is_a?(String) || ids.is_a?(Integer) || ids.is_a?(Array)
    end

    def _fix_ids ids
      if ids.is_a? Array
        ids.map { |id| _fix_id(id) }.compact
      else
        _fix_id ids
      end
    end

    def _fix_id id
      return id if id.is_a?(String) && !id.match?(/\A\d+/)

      int_id = id.is_a?(String) ? Integer(id) : id
      (1..2_147_483_647).cover?(int_id) ? int_id : nil
    end

    def boolean_attribute attribute_name
      define_method "#{attribute_name}?" do
        send "is_#{attribute_name}"
      end
    end

    def boolean_attributes *attribute_names
      attribute_names.each do |attribute_name|
        boolean_attribute attribute_name
      end
    end

    def wo_timestamp
      old = record_timestamps
      self.record_timestamps = false
      begin
        yield
      ensure
        self.record_timestamps = old
      end
    end

    def sanitize data
      connection.quote data
    end
  end
end

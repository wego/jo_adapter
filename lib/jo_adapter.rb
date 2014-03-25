require "jo_adapter/version"
require "active_support/all"
module JoAdapter
  extend ::ActiveSupport::Concern

  def self.fallback(locale, to)
    @fallback_map ||= {}
    @fallback_map[locale.to_s] = to
  end

  def self.fallback_for(locale)
    @fallback_map[locale.to_s] if @fallback_map
  end

  included do
    class_eval do
      def self.jo_i18n_accessor(*attributes)
        attributes.each do |attr|
          class_eval <<-STR, __FILE__, __LINE__ + 1
            jo_i18n :#{attr}
            def #{attr}_i18n=(val)
              return if val.nil?

              #{attr}_json_var = self.#{attr}_json.blank? ? {} : self.#{attr}_json

              locale = I18n.locale.to_s

              if val != #{attr}_json_var[locale]
                #{attr}_json_var[locale] = val
                self.#{attr} = #{attr}_json_var.to_json
              end

              val
            end
          STR
        end
      end

      def self.jo_i18n(*attributes)
        attributes.each do |attr|
          class_eval <<-STR, __FILE__, __LINE__ + 1
            jo :#{attr}
            def #{attr}_i18n(locale = I18n.locale, skip_fallback = nil)
              return nil if #{attr}.blank?
              locale = locale.to_s
              val = #{attr}_json[locale]
              unless val.present?
                skip_fallback = skip_fallback.to_s if skip_fallback
                locale = ::JoAdapter.fallback_for locale
                val = #{attr}_json[locale] unless skip_fallback == locale
                val = #{attr}_json['en'] if val.blank? && skip_fallback != 'en'
              end
              val
            end

            def #{attr}_en
              #{attr}_json['en'] unless #{attr}.blank?
            end
          STR
        end
      end

      def self.jo_writable(write_col, *attributes)
        class_eval <<-STR, __FILE__, __LINE__ + 1
            jo :#{write_col}
            def #{write_col}_write=(val)
              return if val.nil? || !val.is_a?(Hash)
              filtered_val = val.slice(*#{attributes.map(&:to_s)})
              self.#{write_col} = filtered_val.to_json
              val
            end
        STR
      end

      def self.jo_delegate(delg_col, *attributes)
        class_eval "jo :#{delg_col}", __FILE__, __LINE__ + 1

        attributes.each do |attr|
          class_eval <<-STR, __FILE__, __LINE__ + 1
            def #{attr}
              @#{attr}_cache ||= #{delg_col}_json['#{attr}'] unless #{delg_col}_json.blank?
            end
          STR
        end
      end

      def self.jo(*attributes)
        attributes.each do |attr|
          class_eval <<-STR, __FILE__, __LINE__ + 1
            def #{attr}_json
              @_#{attr}_json ||= (#{attr}.is_a?(Hash)) ? #{attr} : JSON.parse(#{attr}) unless #{attr}.blank?
            end
          STR
        end
      end
    end
  end
end

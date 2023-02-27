module Workarea
  module Details
    extend ActiveSupport::Concern

    included do
      field :details, type: Hash, default: {}, localize: true
      before_validation :clean_details
    end

    # Update details by replacing existing detail values with new
    # detail values. If a detail has been explicitly set to blank
    # in the new details, then that detail will be deleted.
    #
    # @param values [Hash] new details to replace existing details
    # @return [void]
    #
    def update_details(values)
      values ||= {}
      self.details ||= {}

      details.merge!(values)

      details.each do |name, value|
        details.delete(name) if value.blank?
      end
    end

    # Find a detail based on a name. Uses string
    # optionizing to determine whether the key
    # on the details hash matches. Used when looking
    # up options in view models.
    #
    # @param name [String]
    # @return anything
    #
    def fetch_detail(name)
      key = details.keys.detect do |tmp|
        tmp.to_s.optionize == name.to_s.optionize
      end

      return nil unless key.present?
      details[key]
    end

    # Determine whether this variant is a match to the
    # passed detail. Used when selecting variants
    # in view models.
    #
    # @param name [String]
    # @param value [String]
    #
    # @return [Boolean]
    #
    def matches_detail?(name, value)
      detail_value = fetch_detail(name)
      return false if detail_value.blank?

      if detail_value.respond_to?(:map)
        detail_value.map(&:to_s).map(&:optionize).include?(value.optionize)
      else
        detail_value.to_s.optionize == value.optionize
      end
    end

    # Determine whether this detail applies as an option for this variant
    #
    # @param name [String]
    # @return [Boolean]
    #
    def has_detail?(name)
      fetch_detail(name).present?
    end

    # Determine whether this variant is a match to the
    # all of the passed details.
    #
    # @param details [Hash]
    # @return [Boolean]
    #
    def matches_details?(details)
      details.all? do |key, value|
        Array.wrap(value).all? { |v| matches_detail?(key, v) }
      end
    end

    # Output all names of all details currently stored on this model. If
    # the model has been rehydrated from a raw +#as_document+ Hash of
    # parameters, this method also dives into the current +I18n.locale+.
    # On models generated by Mongoid or within the context of the
    # current application scope, this method will just read +#keys+ from
    # the details hash stored on the model.
    #
    # @return [Array<String>]
    def detail_names
      locale = I18n.locale.to_s
      hash = if details.keys.include?(locale)
        details[locale]
      else
        details
      end

      hash.keys
    end

    private

    def clean_details
      self.details = Catalog::CleanDetails.new(details).cleaned
    end
  end
end

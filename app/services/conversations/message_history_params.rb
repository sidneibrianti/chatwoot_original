class Conversations::MessageHistoryParams
  def initialize(params)
    @params = params
  end

  def integer(key, default:, maximum:)
    value = @params[key]
    return default if value.nil?

    invalid!(key) unless value.is_a?(String) && value.match?(/\A[1-9]\d*\z/) && value.to_i <= maximum
    value.to_i
  end

  def boolean(key, default:)
    value = @params[key]
    return default if value.nil?

    invalid!(key) unless %w[true false].include?(value)
    value == 'true'
  end

  def date(key)
    value = @params[key]
    return if value.nil?

    invalid!(key) unless value.is_a?(String) && value.match?(/\A\d{4}-\d{2}-\d{2}\z/)
    Date.iso8601(value)
  rescue Date::Error
    invalid!(key)
  end

  def query
    value = @params[:q]
    return '' if value.nil?

    invalid!(:q) unless value.is_a?(String) && value.length <= 500
    value.strip
  end

  def message_type
    value = @params[:message_type]
    return if value.nil?

    invalid!(:message_type) unless Message.message_types.key?(value)
    value
  end

  def invalid!(key)
    raise ActionController::ParameterMissing, key
  end
end

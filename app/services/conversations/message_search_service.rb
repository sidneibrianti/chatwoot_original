class Conversations::MessageSearchService
  attr_reader :meta

  def initialize(conversation:, user_context:, params:)
    @history = Conversations::HistoryScope.new(conversation: conversation, user_context: user_context)
    @options = Conversations::MessageHistoryParams.new(params)
  end

  def perform
    page = @options.integer(:page, default: 1, maximum: 10_000)
    per_page = @options.integer(:per_page, default: 20, maximum: 100)
    messages = filtered_messages
    count = messages.count
    @meta = { total_count: count, current_page: page, per_page: per_page, total_pages: (count.to_f / per_page).ceil }
    messages.reorder(created_at: :desc, id: :desc).offset((page - 1) * per_page).limit(per_page)
  end

  private

  def filtered_messages
    messages = @history.messages
    messages = messages.where(private: false) unless @options.boolean(:include_private, default: false)
    type = @options.message_type
    messages = messages.where(message_type: type) if type
    messages = filter_dates(messages)
    query = @options.query
    query.present? ? matching_text(messages, query) : messages
  end

  def filter_dates(messages)
    from = @options.date(:date_from)
    to = @options.date(:date_to)
    @options.invalid!(:date_to) if from && to && from > to
    messages = messages.where('messages.created_at >= ?', Time.zone.local(from.year, from.month, from.day)) if from
    if to
      next_day = to + 1
      messages = messages.where('messages.created_at < ?', Time.zone.local(next_day.year, next_day.month, next_day.day))
    end
    messages
  end

  def matching_text(messages, query)
    pattern = "%#{ActiveRecord::Base.sanitize_sql_like(query)}%"
    messages.where(<<~SQL.squish, pattern: pattern)
      messages.content ILIKE :pattern OR EXISTS (
        SELECT 1 FROM attachments
        WHERE attachments.message_id = messages.id
          AND attachments.meta ->> 'transcribed_text' ILIKE :pattern
      )
    SQL
  end
end

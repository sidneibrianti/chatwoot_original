class Api::V1::Accounts::Conversations::MessageContextController < Api::V1::Accounts::Conversations::BaseController
  def show
    options = Conversations::MessageHistoryParams.new(params)
    size = options.integer(:context_size, default: 20, maximum: 50)
    id = options.integer(:id, default: nil, maximum: MessageFinder::MESSAGE_ID_MAX)
    messages = Conversations::HistoryScope.new(conversation: @conversation, user_context: pundit_user)
                                          .messages(include_contact_conversations: false)
    @target = messages.find(id)
    older = context_window(messages, size, :desc)
    newer = context_window(messages, size, :asc)
    @has_more_before = older.length > size
    @has_more_after = newer.length > size
    @messages = older.first(size).reverse + [@target] + newer.first(size)
  end

  private

  def context_window(messages, size, direction)
    operator = direction == :asc ? '>' : '<'
    messages.where("(messages.created_at, messages.id) #{operator} (?, ?)", @target.created_at, @target.id)
            .reorder(created_at: direction, id: direction).limit(size + 1).to_a
  end
end

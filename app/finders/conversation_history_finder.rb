class ConversationHistoryFinder
  attr_reader :pagination

  def initialize(messages, params)
    @messages = messages
    @params = params
  end

  def perform
    after = cursor(:after)
    before = cursor(:before)
    scope = keyset_scope(after, before)
    limit = page_limit(after, before)
    direction = after ? :asc : :desc
    page = scope.reorder(created_at: direction, id: direction).limit(limit + 1).to_a
    has_more = page.length > limit
    page = page.first(limit)
    page.reverse! unless after
    @pagination = {
      has_more: has_more, before: page.first&.id, after: page.last&.id,
      direction: after ? 'after' : 'before'
    }
    page
  end

  private

  def page_limit(after, before)
    return 20 unless after

    before ? 1000 : 100
  end

  def keyset_scope(after, before)
    scope = @messages
    scope = scope.where('(messages.created_at, messages.id) >= (?, ?)', after.created_at, after.id) if after && before
    scope = scope.where('(messages.created_at, messages.id) > (?, ?)', after.created_at, after.id) if after && !before
    scope = scope.where('(messages.created_at, messages.id) < (?, ?)', before.created_at, before.id) if before
    scope
  end

  def cursor(key)
    return if @params[key].blank?

    id = Conversations::MessageHistoryParams.new(@params).integer(key, default: nil, maximum: MessageFinder::MESSAGE_ID_MAX)
    @messages.find(id)
  end
end

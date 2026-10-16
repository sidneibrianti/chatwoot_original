class Messages::InReplyToMessageBuilder
  pattr_initialize [:message!, :in_reply_to!, :in_reply_to_external_id!]

  delegate :conversation, to: :message

  def perform
    set_in_reply_to_attribute if @in_reply_to.present? || @in_reply_to_external_id.present?
  end

  private

  def set_in_reply_to_attribute
    reply = in_reply_to_message
    @message.content_attributes[:in_reply_to_external_id] = reply&.source_id
    @message.content_attributes[:in_reply_to] = reply&.id
    @message.content_attributes[:in_reply_to_conversation_id] = reply&.conversation&.display_id
  end

  def in_reply_to_message
    return conversation.messages.find_by(id: @in_reply_to) if @in_reply_to.present?

    return external_reply_message if @in_reply_to_external_id

    nil
  end

  def external_reply_message
    local_message = conversation.messages.find_by(source_id: @in_reply_to_external_id)
    return local_message if local_message || !conversation.account.feature_enabled?('conversation_history')

    conversation.account.messages.where(conversation_id: eligible_reply_conversations.select(:id)).find_by(source_id: @in_reply_to_external_id)
  end

  def eligible_reply_conversations
    siblings = conversation.account.conversations.where(
      contact_id: conversation.contact_id, inbox_id: conversation.inbox_id, contact_inbox_id: conversation.contact_inbox_id
    )
    # Provider callbacks are scoped by the contact's channel identity. Dashboard
    # requests additionally respect the acting agent's conversation permissions.
    if Current.user.is_a?(User) || Current.user.is_a?(AgentBot)
      context = { user: Current.user, account: conversation.account, account_user: Current.account_user }
      siblings = ConversationPolicy::HistoryScope.new(context, siblings).resolve
    end
    siblings
  end
end

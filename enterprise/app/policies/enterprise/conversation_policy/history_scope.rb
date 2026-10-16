module Enterprise::ConversationPolicy::HistoryScope
  def resolve
    conversations = super
    return conversations if account_user&.custom_role_id.blank?

    permissions = account_user.custom_role.permissions
    return conversations if permissions.include?('conversation_manage')

    permitted_conversations(conversations, permissions)
  end

  private

  def permitted_conversations(conversations, permissions)
    allowed = conversations.none
    assigned = conversations.where(assignee_id: user.id)
    if permissions.include?('conversation_unassigned_manage')
      allowed = allowed.or(conversations.where(assignee_id: nil, assignee_agent_bot_id: nil))
                       .or(assigned)
    end
    if permissions.include?('conversation_participating_manage')
      participating = ConversationParticipant.where(user_id: user.id).select(:conversation_id)
      allowed = allowed.or(assigned).or(conversations.where(id: participating))
    end
    allowed
  end
end

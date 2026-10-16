# History must match show? permissions, including access granted by a team.
class ConversationPolicy::HistoryScope < ApplicationPolicy::Scope
  def resolve
    conversations = scope.where(account_id: account.id)
    return conversations if account_user&.administrator? || user.is_a?(AgentBot)

    conversations.where(inbox_id: user.inboxes.where(account_id: account.id).select(:id))
                 .or(conversations.where(team_id: user.teams.where(account_id: account.id).select(:id)))
  end
end

ConversationPolicy::HistoryScope.prepend_mod_with('ConversationPolicy::HistoryScope')

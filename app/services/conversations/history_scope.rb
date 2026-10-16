class Conversations::HistoryScope
  def initialize(conversation:, user_context:)
    @conversation = conversation
    @user_context = user_context
  end

  def resolve(same_inbox: false, include_contact_conversations: true)
    conversations = @conversation.account.conversations.where(contact_id: @conversation.contact_id)
    conversations = conversations.where(inbox_id: @conversation.inbox_id) if same_inbox
    unless @conversation.account.feature_enabled?('conversation_history') && include_contact_conversations
      conversations = conversations.where(id: @conversation.id)
    end
    ConversationPolicy::HistoryScope.new(@user_context, conversations).resolve
  end

  def messages(**)
    @conversation.account.messages.where(conversation_id: resolve(**).select(:id))
                 .includes(:conversation, :sender, attachments: { file_attachment: :blob }, sender: { avatar_attachment: [:blob] })
  end
end

Conversations::HistoryScope.prepend_mod_with('Conversations::HistoryScope')

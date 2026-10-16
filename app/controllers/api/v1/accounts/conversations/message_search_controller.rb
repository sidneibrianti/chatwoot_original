class Api::V1::Accounts::Conversations::MessageSearchController < Api::V1::Accounts::Conversations::BaseController
  def index
    search = Conversations::MessageSearchService.new(conversation: @conversation, user_context: pundit_user, params: params)
    @messages = search.perform
    @meta = search.meta
  end
end

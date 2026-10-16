module Enterprise::Conversations::HistoryScope
  def messages(**)
    super.includes(call: [:contact, { inbox: :channel }])
  end
end

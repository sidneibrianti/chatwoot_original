// Use the UI locale and the browser timezone, like the rest of the timeline.
export const conversationHistoryTimestamp = (timestamp, locale) => {
  const parts = new Intl.DateTimeFormat(locale.replace(/_/g, '-'), {
    day: '2-digit',
    month: 'short',
    year: 'numeric',
    hour: '2-digit',
    minute: '2-digit',
    hourCycle: 'h23',
  }).formatToParts(new Date(timestamp * 1000));
  const values = Object.fromEntries(parts.map(part => [part.type, part.value]));
  return `${values.day} ${values.month} ${values.year} ${values.hour}:${values.minute}`;
};

// Separators are regenerated from the merged timeline, never stored as messages.
// Anchoring to a real message also gives interleaved segments distinct keys.
export const addConversationSeparators = entries => {
  let previousConversationId;
  return entries.flatMap(entry => {
    if (!entry.message) return [entry];
    const conversationId = entry.message.conversationId;
    if (conversationId === previousConversationId) return [entry];
    previousConversationId = conversationId;
    return [
      {
        key: `separator-${conversationId}-${entry.message.id}`,
        separator: entry.message,
      },
      entry,
    ];
  });
};

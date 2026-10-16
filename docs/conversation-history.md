# Conversation history

Conversation history is a Community feature controlled per account by
`conversation_history`. It has no license or premium-plan dependency and does
not create or merge conversations or messages.

## Activation

Reconcile the catalog through the existing configuration loader after deploying:

```sh
bundle exec rails runner 'ConfigLoader.new.process'
```

In **Super Admin → Accounts → Edit**, enable **Conversation History** for the
desired account. Alternatively:

```sh
bundle exec rails runner 'account = Account.find(ACCOUNT_ID); account.enable_features!("conversation_history")'
```

The catalog default is disabled. Existing accounts require explicit activation;
the configuration loader adds the default for future accounts without changing
existing account bits. The flag is appended to `feature_flags_ext_1` so existing
bit positions remain intact. No database migration is required.

## Dashboard behavior

- The timeline combines authorized conversations of the same contact and inbox.
  Email timelines remain individual.
- Conversation pills use the installation's primary color and identify each
  segment's public conversation number and anchor timestamp.
- The editor continues sending in the selected conversation. Historical messages
  offer **Open this conversation** before replying or retrying a message.
  Delete and translate use the message's origin conversation.
- The search button opens a responsive panel. Search covers the contact's
  authorized inboxes, including email, and has no implicit age cutoff. Filters
  include text, inclusive dates, message type and private notes (off by default).
  Stored audio transcriptions are searchable; this feature does not generate them.
- Search, contact and copilot panels are mutually exclusive through the existing
  sidebar controls and UI settings.
- Selecting a result opens its source conversation using the public conversation
  ID and loads a contiguous context window. Older/newer pages extend that window.

## API contracts

All endpoints require account authentication and conversation read permission.
The same history authorization scope respects inbox/team membership and
Enterprise custom-role restrictions. Widget and public API message readers keep
their individual-conversation scope.

### Timeline

`GET /api/v1/accounts/:account_id/conversations/:conversation_id/messages`

Dashboard requests explicitly send `include_contact_conversations=true` to
aggregate. `false` is transported explicitly. Aggregation requires the account
flag; omission does not aggregate. With the flag enabled, pagination uses
`(created_at, id)` keysets and resolves cursor IDs inside the authorized scope.
Backward pages contain up to 20 messages, forward pages 100 and bounded ranges
1,000. `meta.pagination` includes `has_more`, `direction`, `before` and `after`.
Separators are virtual presentation entries regenerated after page merges, never
API message IDs or persisted records.

### Search

`GET /api/v1/accounts/:account_id/conversations/:conversation_id/message_search`

Parameters: `q` (up to 500 characters), `date_from` / `date_to` (`YYYY-MM-DD`),
`message_type` (message enum name), `include_private` (`true`/`false`), `page`
(1–10,000), `per_page` (1–100, default 20). Dates use the application's timezone.
Invalid filters return 422. Responses contain `payload.messages` and
`meta.total_count`, `current_page`, `per_page`, `total_pages`. Without the account
flag, search is limited to the selected conversation.

### Context

`GET /api/v1/accounts/:account_id/conversations/:conversation_id/message_context/:id`

Only messages belonging to the authorized source conversation are returned.
`context_size` is 1–50 (default 20) on each side of the target. Responses contain
`payload.messages`, `payload.target_message_id`, `meta.has_more_before` and
`meta.has_more_after`. Every message's `conversation_id` is the public
`display_id`, consistently across timeline, search, context and message events.

## Deployment verification

Check with an account where internal conversation IDs differ from public IDs,
contacts with interleaved conversations, restricted inbox/team/custom roles,
and both desktop and narrow layouts. Verify widget/public API isolation and
existing campaign/history navigation. Use representative PostgreSQL data and
`EXPLAIN (ANALYZE, BUFFERS)` before deciding whether additional indexes are needed.

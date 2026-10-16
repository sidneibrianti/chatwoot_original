import { useRoute, useRouter } from 'vue-router';
import { frontendURL, conversationUrl } from 'dashboard/helper/URLHelper';
import { emitter } from 'shared/helpers/mitt';
import { BUS_EVENTS } from 'shared/constants/busEvents';

export function useMessageNavigation() {
  const route = useRoute();
  const router = useRouter();
  const openMessage = message => {
    const conversationId = message.conversation_id ?? message.conversationId;
    if (
      Number(route.params.conversation_id) === conversationId &&
      Number(route.query.messageId) === message.id
    ) {
      emitter.emit(BUS_EVENTS.SCROLL_TO_MESSAGE, {
        messageId: message.id,
        forceLoad: true,
      });
      return;
    }
    router.push({
      path: frontendURL(
        conversationUrl({
          accountId: route.params.accountId,
          id: conversationId,
        })
      ),
      query: { messageId: message.id },
    });
  };
  return { openMessage };
}

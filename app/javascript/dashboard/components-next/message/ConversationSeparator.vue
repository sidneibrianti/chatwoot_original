<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';
import { useMessageNavigation } from 'dashboard/composables/useMessageNavigation';
import { conversationHistoryTimestamp } from 'dashboard/helper/conversationHistoryHelper';

const props = defineProps({
  message: { type: Object, required: true },
});
const { locale } = useI18n();
const { openMessage } = useMessageNavigation();
const timestamp = computed(() =>
  conversationHistoryTimestamp(props.message.createdAt, locale.value)
);
</script>

<template>
  <li class="flex justify-center list-none my-4 min-w-0">
    <button
      type="button"
      class="rounded-full bg-n-brand text-white text-xs font-medium px-4 py-2 max-w-full text-center break-words"
      :title="$t('CONVERSATION.HISTORY.OPEN_CONVERSATION')"
      @click="openMessage(message)"
    >
      {{
        $t('CONVERSATION.HISTORY.SEPARATOR', {
          id: message.conversationId,
          timestamp,
        })
      }}
    </button>
  </li>
</template>

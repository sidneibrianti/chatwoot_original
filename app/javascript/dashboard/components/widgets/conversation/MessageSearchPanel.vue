<script setup>
import { computed, watch, onBeforeUnmount } from 'vue';
import { useStore } from 'vuex';
import { useI18n } from 'vue-i18n';
import { useDebounceFn } from '@vueuse/core';
import Button from 'dashboard/components-next/button/Button.vue';
import Spinner from 'dashboard/components-next/spinner/Spinner.vue';
import { useMessageNavigation } from 'dashboard/composables/useMessageNavigation';
import { useMessageFormatter } from 'shared/composables/useMessageFormatter';
import { conversationHistoryTimestamp } from 'dashboard/helper/conversationHistoryHelper';

const store = useStore();
const { locale } = useI18n();
const { openMessage } = useMessageNavigation();
const { getPlainText } = useMessageFormatter();
const SEARCH_DEBOUNCE_MS = 500;
const search = computed(() => store.state.conversationMessageSearch);
const conversationId = computed(() => store.getters.getSelectedChat.id);
const accountId = computed(() => store.getters.getCurrentAccountId);
const hasMore = computed(
  () => search.value.meta.current_page < search.value.meta.total_pages
);
const runSearch = (append = false) =>
  store.dispatch('conversationMessageSearch/search', {
    conversationId: conversationId.value,
    append,
  });
const scheduleSearch = useDebounceFn(() => {
  if (search.value.isOpen && conversationId.value) runSearch();
}, SEARCH_DEBOUNCE_MS);
const setFilter = (key, value) => {
  store.dispatch('conversationMessageSearch/updateFilters', {
    ...search.value.filters,
    [key]: value,
  });
  scheduleSearch();
};
const selectResult = (message, index) => {
  store.commit('conversationMessageSearch/setActiveIndex', index);
  openMessage(message);
};
const moveResult = direction => {
  const index = search.value.activeIndex + direction;
  if (index >= 0 && index < search.value.messages.length)
    selectResult(search.value.messages[index], index);
};
const resultParts = message => {
  const content =
    message.content ||
    message.attachments
      ?.map(attachment => attachment.transcribed_text || '')
      .join(' ') ||
    '';
  const text = getPlainText(content);
  const query = search.value.filters.q.trim();
  if (!query) return [{ text, match: false }];
  const parts = [];
  let start = 0;
  let index = text.toLocaleLowerCase().indexOf(query.toLocaleLowerCase());
  while (index >= 0) {
    parts.push({ text: text.slice(start, index), match: false });
    parts.push({ text: text.slice(index, index + query.length), match: true });
    start = index + query.length;
    index = text.toLocaleLowerCase().indexOf(query.toLocaleLowerCase(), start);
  }
  parts.push({ text: text.slice(start), match: false });
  return parts;
};
watch(
  [accountId, conversationId],
  () => {
    store.dispatch('conversationMessageSearch/reset');
    if (conversationId.value) runSearch();
  },
  { immediate: true }
);
onBeforeUnmount(() => store.dispatch('conversationMessageSearch/reset'));
</script>

<template>
  <aside
    class="flex flex-col flex-shrink-0 w-full lg:w-80 max-h-[60vh] lg:max-h-full overflow-y-auto lg:overflow-hidden border-s border-n-weak bg-n-surface-1 min-h-0"
  >
    <div class="flex items-center justify-between p-3 gap-2">
      <h3 class="text-sm font-medium m-0">
        {{ $t('CONVERSATION.SEARCH.TITLE') }}
      </h3>
      <Button
        ghost
        slate
        sm
        icon="i-lucide-x"
        :aria-label="$t('CONVERSATION.HISTORY.CLOSE')"
        @click="store.commit('conversationMessageSearch/close')"
      />
    </div>
    <div class="px-3 pb-3 flex flex-col gap-2">
      <p class="text-xs text-n-slate-11 m-0">
        {{ $t('CONVERSATION.HISTORY.SEARCH_SCOPE') }}
      </p>
      <input
        type="search"
        :value="search.filters.q"
        :placeholder="$t('CONVERSATION.SEARCH.PLACEHOLDER')"
        :aria-label="$t('CONVERSATION.SEARCH.TITLE')"
        @input="setFilter('q', $event.target.value)"
      />
      <div class="flex gap-2 min-w-0">
        <label class="text-xs min-w-0 flex-1">
          {{ $t('CONVERSATION.HISTORY.DATE_FROM') }}
          <input
            type="date"
            class="w-full min-w-0"
            :value="search.filters.date_from"
            @change="setFilter('date_from', $event.target.value)"
          />
        </label>
        <label class="text-xs min-w-0 flex-1">
          {{ $t('CONVERSATION.HISTORY.DATE_TO') }}
          <input
            type="date"
            class="w-full min-w-0"
            :value="search.filters.date_to"
            @change="setFilter('date_to', $event.target.value)"
          />
        </label>
      </div>
      <select
        :value="search.filters.message_type"
        :aria-label="$t('CONVERSATION.HISTORY.MESSAGE_TYPE')"
        @change="setFilter('message_type', $event.target.value)"
      >
        <option value="">{{ $t('CONVERSATION.HISTORY.ALL_TYPES') }}</option>
        <option value="incoming">
          {{ $t('CONVERSATION.HISTORY.INCOMING') }}
        </option>
        <option value="outgoing">
          {{ $t('CONVERSATION.HISTORY.OUTGOING') }}
        </option>
        <option value="activity">
          {{ $t('CONVERSATION.HISTORY.ACTIVITY') }}
        </option>
        <option value="template">
          {{ $t('CONVERSATION.HISTORY.TEMPLATE') }}
        </option>
      </select>
      <label class="flex items-center gap-2 text-xs">
        <input
          type="checkbox"
          :checked="search.filters.include_private"
          @change="setFilter('include_private', $event.target.checked)"
        />
        {{ $t('CONVERSATION.HISTORY.INCLUDE_PRIVATE') }}
      </label>
      <div class="flex items-center justify-between gap-2 text-xs">
        <span>{{
          $t('CONVERSATION.HISTORY.RESULT_COUNT', {
            count: search.meta.total_count || 0,
          })
        }}</span>
        <div class="flex gap-1">
          <Button
            ghost
            slate
            sm
            icon="i-lucide-chevron-up"
            :disabled="search.activeIndex <= 0"
            :aria-label="$t('CONVERSATION.HISTORY.PREVIOUS_RESULT')"
            @click="moveResult(-1)"
          />
          <Button
            ghost
            slate
            sm
            icon="i-lucide-chevron-down"
            :disabled="search.activeIndex >= search.messages.length - 1"
            :aria-label="$t('CONVERSATION.HISTORY.NEXT_RESULT')"
            @click="moveResult(1)"
          />
        </div>
      </div>
    </div>
    <div
      class="overflow-y-auto min-h-24 lg:min-h-0 flex-1 px-3 pb-3"
      aria-live="polite"
    >
      <p v-if="search.hasError" class="text-sm text-n-ruby-11">
        {{ $t('CONVERSATION.HISTORY.SEARCH_ERROR') }}
      </p>
      <p
        v-else-if="!search.isLoading && !search.messages.length"
        class="text-sm text-n-slate-11"
      >
        {{ $t('CONVERSATION.SEARCH.NO_MATCHING_RESULTS') }}
      </p>
      <button
        v-for="(message, index) in search.messages"
        :key="message.id"
        type="button"
        class="w-full text-start p-3 mb-2 rounded-lg border border-n-weak hover:bg-n-alpha-1"
        :class="{ 'bg-n-alpha-1': search.activeIndex === index }"
        @click="selectResult(message, index)"
      >
        <span class="block text-xs text-n-slate-11 mb-1">{{
          $t('CONVERSATION.HISTORY.SEPARATOR', {
            id: message.conversation_id,
            timestamp: conversationHistoryTimestamp(message.created_at, locale),
          })
        }}</span>
        <span class="block text-sm text-n-slate-12 break-words line-clamp-4">
          <template
            v-for="(part, partIndex) in resultParts(message)"
            :key="partIndex"
          >
            <mark v-if="part.match" class="bg-n-amber-4 text-n-slate-12">{{
              part.text
            }}</mark>
            <template v-else>{{ part.text }}</template>
          </template>
        </span>
      </button>
      <Spinner v-if="search.isLoading" class="mx-auto text-n-brand" />
      <Button
        v-if="hasMore"
        class="w-full"
        ghost
        sm
        :disabled="search.isLoading"
        :label="$t('CONVERSATION.HISTORY.LOAD_MORE')"
        @click="runSearch(true)"
      />
    </div>
  </aside>
</template>

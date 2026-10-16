import MessageApi from 'dashboard/api/inbox/message';
import { useAbortableRequest } from 'dashboard/composables/useAbortableRequest';

const request = useAbortableRequest();
const emptyFilters = () => ({
  q: '',
  date_from: '',
  date_to: '',
  message_type: '',
  include_private: false,
});

export default {
  namespaced: true,
  state: () => ({
    isOpen: false,
    messages: [],
    meta: {},
    filters: emptyFilters(),
    isLoading: false,
    hasError: false,
    activeIndex: -1,
  }),
  mutations: {
    toggle(state) {
      state.isOpen = !state.isOpen;
    },
    close(state) {
      state.isOpen = false;
    },
    reset(state) {
      state.messages = [];
      state.meta = {};
      state.filters = emptyFilters();
      state.isLoading = false;
      state.hasError = false;
      state.activeIndex = -1;
    },
    setFilters(state, filters) {
      state.filters = filters;
    },
    setLoading(state, value) {
      state.isLoading = value;
    },
    setError(state, value) {
      state.hasError = value;
    },
    setActiveIndex(state, value) {
      state.activeIndex = value;
    },
    setResults(state, { payload, meta, append }) {
      state.messages = append
        ? [...state.messages, ...payload.messages]
        : payload.messages;
      state.meta = meta;
      state.activeIndex = -1;
    },
  },
  actions: {
    updateFilters({ commit }, filters) {
      request.abort();
      commit('setFilters', filters);
      commit('setLoading', false);
      commit('setResults', {
        payload: { messages: [] },
        meta: {},
        append: false,
      });
    },
    reset({ commit }) {
      request.abort();
      commit('reset');
    },
    search({ commit, state }, { conversationId, append = false }) {
      return request.run(async signal => {
        commit('setLoading', true);
        commit('setError', false);
        const params = Object.fromEntries(
          Object.entries(state.filters).filter(([, value]) => value !== '')
        );
        params.page = append ? state.meta.current_page + 1 : 1;
        try {
          const { data } = await MessageApi.search(conversationId, params, {
            signal,
          });
          if (!signal.aborted) commit('setResults', { ...data, append });
        } catch (error) {
          if (!signal.aborted) commit('setError', true);
        } finally {
          if (!signal.aborted) commit('setLoading', false);
        }
      });
    },
  },
};

import Component from '@ember/component';
import { inject as service } from '@ember/service';

export default Component.extend({
  gameApi: service(),
  flashMessages: service(),

  spells: null,
  loading: true,
  loadingError: false,
  learning: false,

  init() {
    this._super(...arguments);
    this.set('spells', []);
  },

  didInsertElement() {
    this._super(...arguments);
    this.loadSpells();
  },

  loadSpells() {
    this.set('loading', true);
    this.set('loadingError', false);
    this.get('gameApi').requestOne('grimoireAvailable')
      .then((response) => {
        this.set('spells', response.spells || []);
        this.set('loading', false);
      })
      .catch((error) => {
        this.set('loadingError', true);
        this.set('loading', false);
        this.get('flashMessages').danger('Failed to load spells. Please try again.');
      });
  },

  actions: {
    learnSpell(spell) {
      this.set('learning', true);
      this.get('gameApi').requestOne('grimoireLearn', {
        spell_id: spell.id
      }).then((response) => {
        this.set('learning', false);
        if (response.error) {
          this.get('flashMessages').danger(response.error);
        } else {
          this.get('flashMessages').success(response.message);
          this.loadSpells();
        }
      })
      .catch((error) => {
        this.set('learning', false);
        this.get('flashMessages').danger('Failed to learn spell. Please try again.');
      });
    },

    retry() {
      this.loadSpells();
    }
  }
});

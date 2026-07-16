import Component from '@ember/component';
import { inject as service } from '@ember/service';

export default Component.extend({
  gameApi: service(),
  flashMessages: service(),

  spells: null,
  selectedSpell: null,
  loading: true,
  casting: false,

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
    this.get('gameApi').requestOne('grimoireSpells')
      .then((response) => {
        this.set('spells', response.spells || []);
        this.set('loading', false);
      });
  },

  actions: {
    selectSpell(spell) {
      this.set('selectedSpell', spell);
    },

    castSpell() {
      let spell = this.get('selectedSpell');
      if (!spell) { return; }
      this.set('casting', true);
      this.get('gameApi').requestOne('grimoireCast', {
        spell_id: spell.id,
        scene_id: this.get('sceneId')
      }).then((response) => {
        this.set('casting', false);
        if (response.error) {
          this.get('flashMessages').danger(response.error);
        } else {
          this.get('flashMessages').success(response.message);
          this.set('selectedSpell', null);
        }
      });
    }
  }
});

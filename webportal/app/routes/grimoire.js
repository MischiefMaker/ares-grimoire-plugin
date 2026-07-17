import Route from '@ember/routing/route';
import Controller from '@ember/controller';
import { inject as service } from '@ember/service';

const GrimoireController = Controller.extend({
  gameApi: service(),
  flashMessages: service(),
  isLearning: false,
  isCasting: false,

  actions: {
    learnSpell(spell) {
      if (!spell || this.get('isLearning')) { return; }
      this.set('isLearning', true);

      this.get('gameApi').requestOne('grimoireLearn', {
        spell_id: spell.id
      }).then((response) => {
        this.set('isLearning', false);
        if (response.error) {
          this.get('flashMessages').danger(response.error);
        } else {
          this.get('flashMessages').success(response.message);
          this.send('refreshGrimoire');
        }
      })
      .catch((error) => {
        this.set('isLearning', false);
        this.get('flashMessages').danger('Failed to learn spell. Please try again.');
      });
    },

    castSpell(spell) {
      if (!spell || this.get('isCasting')) { return; }
      this.set('isCasting', true);

      this.get('gameApi').requestOne('grimoireCast', {
        spell_id: spell.id
      }).then((response) => {
        this.set('isCasting', false);
        if (response.error) {
          this.get('flashMessages').danger(response.error);
        } else {
          this.get('flashMessages').success(response.message);
        }
      })
      .catch((error) => {
        this.set('isCasting', false);
        this.get('flashMessages').danger('Failed to cast spell. Please try again.');
      });
    },

    refreshGrimoire() {
      this.get('target').refresh();
    }
  }
});

export default Route.extend({
  gameApi: service(),
  flashMessages: service(),
  controller: GrimoireController,

  model: function() {
    let api = this.get('gameApi');
    return api.requestOne('grimoirePage')
      .catch((error) => {
        this.get('flashMessages').danger('Failed to load Grimoire. Please try again later.');
        return { learned: [], available: [] };
      });
  },

  setupController(controller, model) {
    this._super(controller, model);
    // Convert branches object to array for dropdown
    // This would normally come from the API, but branches are in config
    // For now, we'll get them from the grimoire component by exposing the configuration
    // The component has the branches available via inline data or we can fetch them
    controller.set('branches', [
      { key: 'ceremonial', name: 'Ceremonial Magic' },
      { key: 'hedge', name: 'Hedgecraft' },
      { key: 'forbidden', name: 'Forbidden Magic' }
    ]);
  }
});

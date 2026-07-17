import Route from '@ember/routing/route';
import Controller from '@ember/controller';
import { inject as service } from '@ember/service';

const GrimoireController = Controller.extend({
  gameApi: service(),
  flashMessages: service(),
  isLearning: false,
  isCasting: false,
  isStaff: false,
  allSpells: [],
  proposals: [],
  branches: [],

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
    },

    refreshStaffSpells() {
      let api = this.get('gameApi');
      api.requestOne('grimoireAllSpells')
        .then((response) => {
          if (response.spells) {
            this.set('allSpells', response.spells);
          }
        })
        .catch((error) => {
          this.get('flashMessages').danger('Failed to refresh spell list.');
        });
    },

    refreshStaffProposals() {
      let api = this.get('gameApi');
      api.requestOne('grimoireProposals')
        .then((response) => {
          if (response.proposals) {
            this.set('proposals', response.proposals);
          }
        })
        .catch((error) => {
          this.get('flashMessages').danger('Failed to refresh proposal list.');
        });
    }
  }
});

export default Route.extend({
  gameApi: service(),
  flashMessages: service(),
  controller: GrimoireController,

  model: function() {
    let api = this.get('gameApi');
    return Promise.all([
      api.requestOne('grimoirePage')
        .catch((error) => {
          this.get('flashMessages').danger('Failed to load Grimoire. Please try again later.');
          return { learned: [], available: [] };
        })
    ]);
  },

  setupController(controller, model) {
    let pageModel = model[0];
    this._super(controller, pageModel);

    let api = this.get('gameApi');

    // Fetch branches from server
    api.requestOne('grimoireBranches')
      .then((response) => {
        if (response.branches) {
          controller.set('branches', response.branches);
        }
      })
      .catch((error) => {
        this.get('flashMessages').danger('Failed to load branches.');
        controller.set('branches', []);
      });

    // Load staff data if user has permission
    api.requestOne('grimoireAllSpells')
      .then((response) => {
        if (response.spells) {
          controller.set('allSpells', response.spells);
          controller.set('isStaff', true);
        }
      })
      .catch((error) => {
        // User doesn't have staff permission or there was an error
        controller.set('isStaff', false);
      });

    api.requestOne('grimoireProposals')
      .then((response) => {
        if (response.proposals) {
          controller.set('proposals', response.proposals);
          controller.set('isStaff', true);
        }
      })
      .catch((error) => {
        // User doesn't have staff permission or there was an error
        controller.set('isStaff', false);
      });
  }
});

import Route from '@ember/routing/route';
import { inject as service } from '@ember/service';

export default Route.extend({
  gameApi: service(),
  flashMessages: service(),

  model: function() {
    let api = this.get('gameApi');
    return api.requestOne('grimoirePage')
      .catch((error) => {
        this.get('flashMessages').danger('Failed to load Grimoire. Please try again later.');
        return { learned: [], available: [] };
      });
  }
});

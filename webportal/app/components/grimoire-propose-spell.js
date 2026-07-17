import Component from '@ember/component';
import { inject as service } from '@ember/service';

export default Component.extend({
  gameApi: service(),
  flashMessages: service(),

  branches: [],
  selectedBranch: null,
  spellName: '',
  minimumSkill: '1',
  difficulty: '1',
  description: '',
  isSubmitting: false,

  init() {
    this._super(...arguments);
    // Get branches from Grimoire configuration via a handler or pass them in
    // For now, we'll fetch them from the page's data
  },

  actions: {
    submitProposal() {
      let branch = this.get('selectedBranch');
      let name = this.get('spellName');
      let minSkill = this.get('minimumSkill');
      let difficulty = this.get('difficulty');
      let description = this.get('description');

      if (!branch) {
        this.get('flashMessages').danger('Please select a branch.');
        return;
      }

      if (!name || name.trim() === '') {
        this.get('flashMessages').danger('Please enter a spell name.');
        return;
      }

      if (!minSkill || minSkill.trim() === '') {
        this.get('flashMessages').danger('Please enter minimum skill.');
        return;
      }

      if (!difficulty || difficulty.trim() === '') {
        this.get('flashMessages').danger('Please enter difficulty.');
        return;
      }

      if (!description || description.trim() === '') {
        this.get('flashMessages').danger('Please enter a description.');
        return;
      }

      // Validate numeric fields
      let minSkillNum = parseInt(minSkill);
      let difficultyNum = parseInt(difficulty);

      if (isNaN(minSkillNum) || minSkillNum < 0) {
        this.get('flashMessages').danger('Minimum skill must be a non-negative number.');
        return;
      }

      if (isNaN(difficultyNum) || difficultyNum < 0) {
        this.get('flashMessages').danger('Difficulty must be a non-negative number.');
        return;
      }

      this.set('isSubmitting', true);

      this.get('gameApi').requestOne('grimoirePropose', {
        branch_key: branch,
        name: name,
        minimum_skill: minSkillNum,
        difficulty: difficultyNum,
        description: description
      }).then((response) => {
        this.set('isSubmitting', false);
        if (response.error) {
          this.get('flashMessages').danger(response.error);
        } else {
          this.get('flashMessages').success(`Spell proposal submitted as Job #${response.job_id}. Staff will review your proposal.`);
          // Reset form
          this.setProperties({
            selectedBranch: null,
            spellName: '',
            minimumSkill: '1',
            difficulty: '1',
            description: ''
          });
        }
      })
      .catch((error) => {
        this.set('isSubmitting', false);
        this.get('flashMessages').danger('Failed to submit proposal. Please try again.');
      });
    },

    cancel() {
      this.setProperties({
        selectedBranch: null,
        spellName: '',
        minimumSkill: '1',
        difficulty: '1',
        description: ''
      });
    }
  }
});

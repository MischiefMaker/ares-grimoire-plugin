import Component from '@ember/component';
import { inject as service } from '@ember/service';

export default Component.extend({
  gameApi: service(),
  flashMessages: service(),

  allSpells: [],
  branches: [],
  showAddForm: false,
  editingSpell: null,
  isSubmitting: false,

  // Form fields
  formBranch: '',
  formName: '',
  formMinSkill: '1',
  formDifficulty: '1',
  formDescription: '',

  actions: {
    toggleAddForm() {
      if (!this.get('showAddForm')) {
        this.resetForm();
      }
      this.toggleProperty('showAddForm');
    },

    editSpell(spell) {
      this.setProperties({
        editingSpell: spell,
        formBranch: spell.branch_key,
        formName: spell.name,
        formMinSkill: spell.minimum_skill.toString(),
        formDifficulty: spell.difficulty.toString(),
        formDescription: spell.description
      });
    },

    cancelEdit() {
      this.setProperties({
        editingSpell: null
      });
      this.resetForm();
    },

    saveSpell() {
      if (this.get('editingSpell')) {
        this.send('updateSpell');
      } else {
        this.send('createSpell');
      }
    },

    createSpell() {
      let branch = this.get('formBranch');
      let name = this.get('formName');
      let minSkill = this.get('formMinSkill');
      let difficulty = this.get('formDifficulty');
      let description = this.get('formDescription');

      if (!this.validateForm(branch, name, minSkill, difficulty, description)) {
        return;
      }

      this.set('isSubmitting', true);

      this.get('gameApi').requestOne('grimoireAdd', {
        branch_key: branch,
        name: name,
        minimum_skill: parseInt(minSkill),
        difficulty: parseInt(difficulty),
        description: description
      }).then((response) => {
        this.set('isSubmitting', false);
        if (response.error) {
          this.get('flashMessages').danger(response.error);
        } else {
          this.get('flashMessages').success(`Spell '${name}' created.`);
          this.set('showAddForm', false);
          this.resetForm();
          this.send('refreshSpells');
        }
      })
      .catch((error) => {
        this.set('isSubmitting', false);
        this.get('flashMessages').danger('Failed to create spell.');
      });
    },

    updateSpell() {
      let spell = this.get('editingSpell');
      let name = this.get('formName');
      let minSkill = this.get('formMinSkill');
      let difficulty = this.get('formDifficulty');
      let description = this.get('formDescription');

      if (!this.validateForm(spell.branch_key, name, minSkill, difficulty, description)) {
        return;
      }

      this.set('isSubmitting', true);

      this.get('gameApi').requestOne('grimoireEdit', {
        spell_id: spell.id,
        name: name,
        minimum_skill: parseInt(minSkill),
        difficulty: parseInt(difficulty),
        description: description
      }).then((response) => {
        this.set('isSubmitting', false);
        if (response.error) {
          this.get('flashMessages').danger(response.error);
        } else {
          this.get('flashMessages').success(`Spell '${name}' updated.`);
          this.send('cancelEdit');
          this.send('refreshSpells');
        }
      })
      .catch((error) => {
        this.set('isSubmitting', false);
        this.get('flashMessages').danger('Failed to update spell.');
      });
    },

    deleteSpell(spell) {
      if (!confirm(`Delete spell '${spell.name}'? This cannot be undone.`)) {
        return;
      }

      this.set('isSubmitting', true);

      this.get('gameApi').requestOne('grimoireDelete', {
        spell_id: spell.id
      }).then((response) => {
        this.set('isSubmitting', false);
        if (response.error) {
          this.get('flashMessages').danger(response.error);
        } else {
          this.get('flashMessages').success(`Spell '${spell.name}' deleted.`);
          this.send('refreshSpells');
        }
      })
      .catch((error) => {
        this.set('isSubmitting', false);
        this.get('flashMessages').danger('Failed to delete spell.');
      });
    },

    refreshSpells() {
      this.get('onRefresh')();
    }
  },

  validateForm(branch, name, minSkill, difficulty, description) {
    if (!branch) {
      this.get('flashMessages').danger('Please select a branch.');
      return false;
    }
    if (!name || name.trim() === '') {
      this.get('flashMessages').danger('Please enter a spell name.');
      return false;
    }
    if (isNaN(parseInt(minSkill))) {
      this.get('flashMessages').danger('Minimum skill must be a number.');
      return false;
    }
    if (isNaN(parseInt(difficulty))) {
      this.get('flashMessages').danger('Difficulty must be a number.');
      return false;
    }
    if (!description || description.trim() === '') {
      this.get('flashMessages').danger('Please enter a description.');
      return false;
    }
    return true;
  },

  resetForm() {
    this.setProperties({
      formBranch: '',
      formName: '',
      formMinSkill: '1',
      formDifficulty: '1',
      formDescription: ''
    });
  }
});

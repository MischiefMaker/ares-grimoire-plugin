import Component from '@ember/component';
import { inject as service } from '@ember/service';

export default Component.extend({
  gameApi: service(),
  flashMessages: service(),

  proposals: [],
  showRejectForm: false,
  rejectingProposal: null,
  rejectReason: '',
  isSubmitting: false,

  actions: {
    approveProposal(proposal) {
      if (!confirm(`Approve spell '${proposal.name}' from ${proposal.proposed_by}?`)) {
        return;
      }

      this.set('isSubmitting', true);

      this.get('gameApi').requestOne('grimoireApprove', {
        job_id: proposal.job_id
      }).then((response) => {
        this.set('isSubmitting', false);
        if (response.error) {
          this.get('flashMessages').danger(response.error);
        } else {
          this.get('flashMessages').success(`Spell '${proposal.name}' approved and created.`);
          this.send('refreshProposals');
        }
      })
      .catch((error) => {
        this.set('isSubmitting', false);
        this.get('flashMessages').danger('Failed to approve proposal.');
      });
    },

    showRejectForm(proposal) {
      this.setProperties({
        showRejectForm: true,
        rejectingProposal: proposal,
        rejectReason: ''
      });
    },

    cancelReject() {
      this.setProperties({
        showRejectForm: false,
        rejectingProposal: null,
        rejectReason: ''
      });
    },

    submitReject() {
      let proposal = this.get('rejectingProposal');
      let reason = this.get('rejectReason');

      if (!reason || reason.trim() === '') {
        this.get('flashMessages').danger('Please provide a rejection reason.');
        return;
      }

      this.set('isSubmitting', true);

      this.get('gameApi').requestOne('grimoireReject', {
        job_id: proposal.job_id,
        reason: reason
      }).then((response) => {
        this.set('isSubmitting', false);
        if (response.error) {
          this.get('flashMessages').danger(response.error);
        } else {
          this.get('flashMessages').success(`Proposal rejected.`);
          this.send('cancelReject');
          this.send('refreshProposals');
        }
      })
      .catch((error) => {
        this.set('isSubmitting', false);
        this.get('flashMessages').danger('Failed to reject proposal.');
      });
    },

    refreshProposals() {
      this.get('onRefresh')();
    }
  }
});

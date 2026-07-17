# frozen_string_literal: true

module AresMUSH
  module Grimoire
    class GrimoireProposalRequestHandler
      def handle(request)
        enactor = request.enactor

        error = Website.check_login(request)
        return error if error

        request.log_request

        branch_key = request.args['branch_key']
        name = request.args['name']
        minimum_skill = request.args['minimum_skill']
        difficulty = request.args['difficulty']
        description = request.args['description']

        # Validate branch exists
        unless Grimoire.branches.key?(branch_key.to_s)
          return { error: t('grimoire.branch_not_found', branch: branch_key) }
        end

        # Call service method (same as MUSH command)
        job = GrimoireService.create_proposal(enactor, {
          branch_key: branch_key,
          name: name,
          minimum_skill: minimum_skill,
          difficulty: difficulty,
          description: description
        })

        if job
          { success: true, job_id: job.id, message: t('grimoire.proposal_submitted', job: job.id) }
        else
          { error: t('grimoire.proposal_failed') }
        end
      end
    end
  end
end

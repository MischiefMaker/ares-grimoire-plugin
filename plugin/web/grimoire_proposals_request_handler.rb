# frozen_string_literal: true

module AresMUSH
  module Grimoire
    class GrimoireProposalsRequestHandler
      def handle(request)
        enactor = request.enactor

        error = Website.check_login(request)
        return error if error

        # Check staff permission
        unless GrimoireApi.can_manage?(enactor)
          return { error: "Insufficient permissions." }
        end

        request.log_request

        # Get pending proposals from Jobs system
        category = Global.read_config('grimoire', 'jobs', 'spell_proposal_category') || Jobs.request_category
        pending_jobs = Job.find(status: "open", category: category).to_a.sort_by { |j| j.id.to_i }

        proposals = []
        pending_jobs.each do |job|
          proposal = SpellProposal.find(job_id: job.id.to_i).first
          if proposal
            proposals << {
              job_id: job.id,
              job_title: job.title,
              proposed_by: proposal.proposed_by ? proposal.proposed_by.name : "Unknown",
              branch: Grimoire.branch_display_name(proposal.branch_key),
              name: proposal.name,
              minimum_skill: proposal.minimum_skill,
              difficulty: proposal.difficulty,
              description: proposal.description
            }
          end
        end

        { proposals: proposals }
      end
    end
  end
end

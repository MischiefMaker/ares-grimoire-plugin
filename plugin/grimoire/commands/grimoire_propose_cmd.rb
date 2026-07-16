# frozen_string_literal: true

module AresMUSH
  module Grimoire
    class GrimoireProposeCmd
      include CommandHandler

      attr_accessor :branch, :name, :minimum_skill, :difficulty, :description

      def parse_args
        args = cmd.parse_args(ArgParser.arg1_equals_arg2)
        self.branch = trim_arg(args.arg1)
        rest = args.arg2 || ""
        parts = rest.split('/', 4)
        self.name = parts[0] ? parts[0].strip : ""
        self.minimum_skill = parts[1] ? parts[1].strip : ""
        self.difficulty = parts[2] ? parts[2].strip : ""
        self.description = parts[3] ? parts[3].strip : ""
      end

      def required_args
        [ self.branch, self.name, self.minimum_skill, self.difficulty, self.description ]
      end

      def handle
        unless Grimoire.branches.key?(self.branch)
          client.emit_failure t('grimoire.branch_not_found', branch: self.branch)
          return
        end
        job = GrimoireService.create_proposal(enactor, {
          branch_key: self.branch,
          name: self.name,
          minimum_skill: self.minimum_skill,
          difficulty: self.difficulty,
          description: self.description
        })
        if job
          client.emit_success t('grimoire.proposal_submitted', job: job.id)
        else
          client.emit_failure t('grimoire.proposal_failed')
        end
      end
    end
  end
end

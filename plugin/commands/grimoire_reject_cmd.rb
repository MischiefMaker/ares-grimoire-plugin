# frozen_string_literal: true

module AresMUSH
  module Grimoire
    class GrimoireRejectCmd
      include CommandHandler

      attr_accessor :job_id, :reason

      def parse_args
        args = cmd.parse_args(ArgParser.arg1_equals_arg2)
        self.job_id = trim_arg(args.arg1)
        self.reason = args.arg2
      end

      def required_args
        [ self.job_id, self.reason ]
      end

      def check_can_manage
        return t('grimoire.staff_only') unless GrimoireService.can_manage?(enactor)
        nil
      end

      def handle
        result = GrimoireService.reject_proposal(enactor, self.job_id, self.reason)
        if result[:success]
          client.emit_success result[:message]
        else
          client.emit_failure result[:message]
        end
      end
    end
  end
end

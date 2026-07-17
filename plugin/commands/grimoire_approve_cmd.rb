# frozen_string_literal: true

module AresMUSH
  module Grimoire
    class GrimoireApproveCmd
      include CommandHandler

      attr_accessor :job_id

      def parse_args
        self.job_id = trim_arg(cmd.args)
      end

      def required_args
        [ self.job_id ]
      end

      def check_can_manage
        return t('grimoire.staff_only') unless GrimoireService.can_manage?(enactor)
        nil
      end

      def handle
        result = GrimoireService.approve_proposal(enactor, self.job_id)
        if result[:success]
          client.emit_success result[:message]
        else
          client.emit_failure result[:message]
        end
      end
    end
  end
end

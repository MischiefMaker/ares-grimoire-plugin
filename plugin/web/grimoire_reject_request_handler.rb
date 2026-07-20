# frozen_string_literal: true

module AresMUSH
  module Grimoire
    class GrimoireRejectRequestHandler
      def handle(request)
        enactor = request.enactor

        error = Website.check_login(request)
        return error if error

        # Check staff permission
        unless GrimoireApi.can_manage?(enactor)
          return { error: t('grimoire.staff_only') }
        end

        request.log_request

        result = GrimoireApi.reject_proposal(enactor, request.args['job_id'], request.args['reason'])

        if result[:success]
          { success: true, message: result[:message] }
        else
          { error: result[:message] }
        end
      end
    end
  end
end

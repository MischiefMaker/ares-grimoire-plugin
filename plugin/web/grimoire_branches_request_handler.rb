# frozen_string_literal: true

module AresMUSH
  module Grimoire
    class GrimoireBranchesRequestHandler
      def handle(request)
        enactor = request.enactor

        error = Website.check_login(request)
        return error if error

        request.log_request

        branches = Grimoire.branches.map { |key, info|
          {
            key: key,
            name: info['name']
          }
        }

        { branches: branches }
      end
    end
  end
end

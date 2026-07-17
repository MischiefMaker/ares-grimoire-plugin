# frozen_string_literal: true

module AresMUSH
  module Grimoire
    class GrimoireDeleteCmd
      include CommandHandler

      attr_accessor :spell_id

      def parse_args
        self.spell_id = trim_arg(cmd.args)
      end

      def required_args
        [ self.spell_id ]
      end

      def check_can_manage
        return t('grimoire.staff_only') unless GrimoireService.can_manage?(enactor)
        nil
      end

      def handle
        result = GrimoireService.delete_spell(self.spell_id)
        if result[:success]
          client.emit_success t('grimoire.spell_deleted', id: self.spell_id)
        else
          client.emit_failure result[:message]
        end
      end
    end
  end
end

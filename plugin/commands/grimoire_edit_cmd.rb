# frozen_string_literal: true

module AresMUSH
  module Grimoire
    class GrimoireEditCmd
      include CommandHandler

      attr_accessor :spell_id, :name, :minimum_skill, :difficulty, :description

      def parse_args
        args = cmd.parse_args(ArgParser.arg1_equals_arg2)
        self.spell_id = trim_arg(args.arg1)
        rest = args.arg2 || ""
        parts = rest.split('/', 4)
        self.name = parts[0] ? parts[0].strip : ""
        self.minimum_skill = parts[1] ? parts[1].strip : ""
        self.difficulty = parts[2] ? parts[2].strip : ""
        self.description = parts[3] ? parts[3].strip : ""
      end

      def required_args
        [ self.spell_id, self.name, self.minimum_skill, self.difficulty, self.description ]
      end

      def check_can_manage
        return t('grimoire.staff_only') unless GrimoireApi.can_manage?(enactor)
        nil
      end

      def handle
        result = GrimoireApi.edit_spell(self.spell_id, {
          name: self.name,
          description: self.description,
          minimum_skill: self.minimum_skill,
          difficulty: self.difficulty
        })
        if result[:success]
          client.emit_success t('grimoire.spell_edited', id: self.spell_id)
        else
          client.emit_failure t('grimoire.spell_invalid', errors: result[:errors].join(', '))
        end
      end
    end
  end
end

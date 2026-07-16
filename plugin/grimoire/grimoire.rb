# frozen_string_literal: true

$:.unshift File.dirname(__FILE__)

require_relative 'models/spell'
require_relative 'models/spell_proposal'
require_relative 'models/character_spell_learned'
require_relative 'services/grimoire_service'
require_relative 'commands/grimoire_list_cmd'
require_relative 'commands/grimoire_learn_cmd'
require_relative 'commands/grimoire_cast_cmd'
require_relative 'commands/grimoire_propose_cmd'
require_relative 'commands/grimoire_add_cmd'
require_relative 'commands/grimoire_edit_cmd'
require_relative 'commands/grimoire_delete_cmd'
require_relative 'commands/grimoire_approve_cmd'
require_relative 'commands/grimoire_reject_cmd'
require_relative 'web/grimoire_page_request_handler'
require_relative 'web/grimoire_spells_request_handler'
require_relative 'web/grimoire_available_request_handler'
require_relative 'web/grimoire_learned_request_handler'
require_relative 'web/grimoire_learn_request_handler'
require_relative 'web/grimoire_cast_request_handler'

module AresMUSH
  module Grimoire
    def self.plugin_dir
      File.dirname(__FILE__)
    end

    def self.plugin_version
      "2.1"
    end

    def self.shortcuts
      Global.read_config("grimoire", "shortcuts") || {}
    end

    def self.get_cmd_handler(client, cmd, enactor)
      return nil unless cmd.root == "grimoire"
      case cmd.switch ? cmd.switch.downcase : nil
      when nil
        GrimoireListCmd
      when "learn"
        GrimoireLearnCmd
      when "cast"
        GrimoireCastCmd
      when "propose"
        GrimoireProposeCmd
      when "add"
        GrimoireAddCmd
      when "edit"
        GrimoireEditCmd
      when "delete"
        GrimoireDeleteCmd
      when "approve"
        GrimoireApproveCmd
      when "reject"
        GrimoireRejectCmd
      else
        nil
      end
    end

    def self.get_web_request_handler(request)
      case request.cmd
      when "grimoirePage"
        return GrimoirePageRequestHandler
      when "grimoireSpells"
        return GrimoireSpellsRequestHandler
      when "grimoireAvailable"
        return GrimoireAvailableRequestHandler
      when "grimoireLearned"
        return GrimoireLearnedRequestHandler
      when "grimoireLearn"
        return GrimoireLearnRequestHandler
      when "grimoireCast"
        return GrimoireCastRequestHandler
      end
      nil
    end

    def self.check_config
      branches = Global.read_config('grimoire', 'branches') || {}
      return "Grimoire: No branches configured." if branches.empty?
      branches.each do |key, info|
        return "Grimoire: Branch '#{key}' missing name." unless info['name']
        return "Grimoire: Branch '#{key}' missing fs3_skill." unless info['fs3_skill']
      end
      nil
    end

    def self.branches
      Global.read_config('grimoire', 'branches') || {}
    end

    def self.branch_display_name(key)
      info = branches[key.to_s]
      info && info['name'] ? info['name'] : key.to_s
    end

    def self.branch_skill(key)
      info = branches[key.to_s]
      info && info['fs3_skill'] ? info['fs3_skill'] : nil
    end

    def self.resolve_branch(name)
      return name.to_s if branches.key?(name.to_s)
      branches.each do |k, v|
        return k if v['name'].to_s.downcase == name.to_s.downcase
      end
      nil
    end
  end
end

# frozen_string_literal: true

module AresMUSH
  module Grimoire
    class GrimoireListCmd
      include CommandHandler

      attr_accessor :target

      def parse_args
        self.target = trim_arg(cmd.args)
      end

      def handle
        target.blank? ? list_all : show_item(self.target)
      end

      def list_all
        msg = "%xh%xc#{t('grimoire.title')}%xn\n%xh#{'-' * 40}%xn\n"

        known = GrimoireService.learned_spells(enactor)
        known_ids = build_id_lookup(known.map(&:id))

        msg += "%xh#{t('grimoire.learned_spells')}%xn\n"
        if known.empty?
          msg += "  #{t('grimoire.none_learned')}\n"
        else
          known.each { |s| msg += "  %xg##{s.id}%xn #{s.name}\n" }
        end

        msg += "\n%xh#{t('grimoire.available_spells')}%xn\n"
        branches = Grimoire.branches
        spells = GrimoireService.list_spells
        by_branch = spells.group_by { |s| s.branch_key.to_s }

        branch_ratings = {}
        branches.each_key do |key|
          skill = Grimoire.branch_skill(key)
          branch_ratings[key] = GrimoireService.fs3_rating(enactor, skill)
        end

        branches.each do |key, info|
          name = info['name'] || key
          msg += "\n%xh#{name}%xn\n"
          list = (by_branch[key.to_s] || []).sort_by { |s| s.name.downcase }
          if list.empty?
            msg += "  #{t('grimoire.no_spells')}\n"
          else
            list.each do |s|
              tag = if known_ids.key?(s.id.to_i)
                      "%xg#{t('grimoire.tag_learned')}%xn"
                    elsif branch_ratings[key].to_i >= s.minimum_skill.to_i
                      "%xc#{t('grimoire.tag_available')}%xn"
                    else
                      "%xr#{t('grimoire.tag_locked')}%xn"
                    end
              msg += "  ##{s.id} #{s.name} [#{tag}] (#{t('grimoire.min')}: #{s.minimum_skill}, #{t('grimoire.diff')}: #{s.difficulty})\n"
            end
          end
        end
        client.emit msg.chomp
      end

      def build_id_lookup(ids)
        lookup = {}
        ids.each { |id| lookup[id.to_i] = true }
        lookup
      end

      def show_item(arg)
        arg =~ /\A\d+\z/ ? show_spell(arg.to_i) : show_branch(arg)
      end

      def show_branch(arg)
        key = Grimoire.resolve_branch(arg)
        unless key
          client.emit_failure t('grimoire.branch_not_found', branch: arg)
          return
        end
        name = Grimoire.branch_display_name(key)
        spells = GrimoireService.list_by_branch(key)
        msg = "%xh%xc#{name}%xn (#{key})\n%xh#{'-' * 40}%xn\n"
        if spells.empty?
          msg += t('grimoire.no_spells')
        else
          spells.each { |s| msg += "  ##{s.id} #{s.name} (#{t('grimoire.min')}: #{s.minimum_skill}, #{t('grimoire.diff')}: #{s.difficulty})\n" }
        end
        client.emit msg.chomp
      end

      def show_spell(id)
        spell = GrimoireService.find_spell(id)
        unless spell
          client.emit_failure t('grimoire.spell_not_found', id: id)
          return
        end
        branch = Grimoire.branch_display_name(spell.branch_key)
        learned = GrimoireService.has_learned_spell?(enactor, spell.id)
        msg = "%xh%xc#{spell.name}%xn\n%xh#{'-' * 40}%xn\n"
        msg += "#{t('grimoire.branch_label')}: #{branch} (#{spell.branch_key})\n"
        msg += "#{t('grimoire.min')}: #{spell.minimum_skill}\n"
        msg += "#{t('grimoire.diff')}: #{spell.difficulty}\n"
        msg += "#{t('grimoire.description')}: #{spell.description}\n"
        msg += "#{t('grimoire.learned_status')}: #{learned ? t('grimoire.yes') : t('grimoire.no')}\n"
        client.emit msg.chomp
      end
    end
  end
end

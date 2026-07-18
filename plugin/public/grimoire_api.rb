# frozen_string_literal: true

module AresMUSH
  module Grimoire
    class GrimoireApi

      MAGIC_ABILITY = "Magic"

      # --- Permissions ---
      def self.can_manage?(character)
        return false unless character
        character.is_admin? || character.has_permission?(Grimoire.manage_permission)
      end

      # --- Queries ---
      def self.list_spells
        Spell.all.to_a.select { |s| s.approved }.sort_by { |s| s.name.downcase }
      end

      def self.list_by_branch(key)
        Spell.find(branch_key: key.to_s).to_a.select { |s| s.approved }.sort_by { |s| s.name.downcase }
      end

      def self.find_spell(id)
        return nil unless id
        Spell[id.to_i]
      rescue
        nil
      end

      def self.learned_spells(char)
        return [] unless char
        learned = CharacterSpellLearned.find(character_id: char.id).to_a
        return [] if learned.empty?
        id_lookup = build_id_lookup(learned.map { |l| l.spell_id.to_i })
        Spell.all.to_a.select { |s| id_lookup.key?(s.id.to_i) }.sort_by { |s| s.name.downcase }
      end

      def self.has_learned_spell?(char, spell_id)
        return false unless char && spell_id
        !CharacterSpellLearned.find(character_id: char.id, spell_id: spell_id.to_i).first.nil?
      end

      def self.available_spells(char)
        return list_spells unless char
        learned = CharacterSpellLearned.find(character_id: char.id).to_a
        id_lookup = build_id_lookup(learned.map { |l| l.spell_id.to_i })
        list_spells.reject { |s| id_lookup.key?(s.id.to_i) }
      end

      def self.castable_spells(char)
        learned_spells(char)
      end

      def self.build_id_lookup(ids)
        lookup = {}
        ids.each { |id| lookup[id.to_i] = true }
        lookup
      end

      # --- FS3 Helpers ---
      def self.fs3_rating(char, ability)
        return 0 if ability.nil?
        FS3Skills.ability_rating(char, ability).to_i
      end

      def self.fs3_xp(char)
        char.fs3_xp.to_i
      end

      def self.deduct_xp(char, amount)
        FS3Skills.modify_xp(char, -amount)
      end

      def self.calculate_learning_cost(spell)
        per_point = Global.read_config('grimoire', 'learning', 'xp_cost_per_skill_point') || 1
        spell.minimum_skill.to_i * per_point.to_i
      end

      def self.can_learn_spell?(char, spell)
        return false unless char && spell
        return false if has_learned_spell?(char, spell.id)
        skill = Grimoire.branch_skill(spell.branch_key)
        return false unless skill  # Branch skill not configured
        return false unless fs3_rating(char, skill) >= spell.minimum_skill.to_i
        fs3_xp(char) >= calculate_learning_cost(spell)
      end

      # --- Learning ---
      def self.learn_spell(char, spell_id)
        spell = find_spell(spell_id)
        return { success: false, message: t('grimoire.spell_not_found', id: spell_id) } unless spell

        if has_learned_spell?(char, spell.id)
          return { success: false, message: t('grimoire.already_learned', name: spell.name) }
        end

        skill = Grimoire.branch_skill(spell.branch_key)
        unless skill
          return { success: false, message: t('grimoire.invalid_branch', branch: spell.branch_key) }
        end

        rating = fs3_rating(char, skill)

        if rating < spell.minimum_skill.to_i
          return { success: false, message: t('grimoire.insufficient_skill_to_learn', name: spell.name, min: spell.minimum_skill, current: rating) }
        end

        cost = calculate_learning_cost(spell)
        xp = fs3_xp(char)

        if xp < cost
          return { success: false, message: t('grimoire.insufficient_xp', name: spell.name, cost: cost, current: xp) }
        end

        deduct_xp(char, cost)
        CharacterSpellLearned.create(character: char, spell: spell, xp_cost: cost)
        { success: true, message: t('grimoire.spell_learned', name: spell.name, cost: cost) }
      end

      # --- Casting ---
      def self.cast_spell(char, spell, opts = {})
        return { success: false, message: t('grimoire.spell_not_approved') } unless spell.approved
        unless has_learned_spell?(char, spell.id)
          return { success: false, message: t('grimoire.not_learned') }
        end

        skill = Grimoire.branch_skill(spell.branch_key)
        unless skill
          return { success: false, message: t('grimoire.invalid_branch', branch: spell.branch_key) }
        end

        rating = fs3_rating(char, skill)

        if rating < spell.minimum_skill.to_i
          return { success: false, message: t('grimoire.insufficient_skill', name: spell.name, min: spell.minimum_skill) }
        end

        # FS3 roll: branch skill + Magic ability rating - spell difficulty
        magic_rating = fs3_rating(char, MAGIC_ABILITY)
        if magic_rating == 0 && char
          # Magic ability doesn't exist or character doesn't have it configured
          return { success: false, message: t('grimoire.magic_ability_missing') }
        end

        modifier = magic_rating - spell.difficulty.to_i
        roll_params = FS3Skills::RollParams.new(skill, modifier)
        die_result = FS3Skills.roll_ability(char, roll_params)
        success_level = FS3Skills.get_success_level(die_result)
        success_title = FS3Skills.get_success_title(success_level)
        dice_str = FS3Skills.print_dice(die_result)

        message = build_cast_message(char, spell, success_level, success_title, dice_str, opts[:show_details])

        if opts[:scene_id] && opts[:scene_id].to_i > 0
          scene = begin; Scene[opts[:scene_id].to_i]; rescue; nil; end
          if scene
            Scenes.add_to_scene(scene, message, char)
          end
        end

        { success: true, message: message, success_level: success_level }
      end

      def self.build_cast_message(char, spell, success_level, success_title, dice_str, show_details)
        branch = Grimoire.branch_display_name(spell.branch_key)
        status = success_level > 0 ? "%xg#{success_title}%xn" : "%xr#{success_title}%xn"
        msg = t('grimoire.cast_announce', caster: char.name, spell: spell.name, branch: branch, status: status)
        msg += " " + t('grimoire.roll_details', details: dice_str) if show_details
        msg
      end

      # --- Spell CRUD ---
      def self.validate_spell_attrs(attrs, exclude_id = nil)
        errors = []
        errors << "Branch is not valid" unless Grimoire.branches.key?(attrs[:branch_key].to_s)
        errors << "Name is required" if attrs[:name].to_s.strip.empty?

        min_skill = attrs[:minimum_skill].to_i
        difficulty = attrs[:difficulty].to_i
        errors << "Minimum skill must be 0 or higher" if min_skill < 0
        errors << "Difficulty must be 0 or higher" if difficulty < 0

        unless attrs[:name].to_s.strip.empty? || attrs[:branch_key].to_s.empty?
          existing = Spell.find(branch_key: attrs[:branch_key].to_s, name: attrs[:name]).to_a
          existing = existing.reject { |s| s.id == exclude_id } if exclude_id
          errors << "A spell with that name already exists in this branch" unless existing.empty?
        end
        errors
      end

      def self.create_spell(attrs)
        errors = validate_spell_attrs(attrs)
        return { success: false, spell: nil, errors: errors } unless errors.empty?

        spell = Spell.create(
          branch_key: attrs[:branch_key].to_s,
          name: attrs[:name],
          description: attrs[:description],
          minimum_skill: attrs[:minimum_skill].to_i,
          difficulty: attrs[:difficulty].to_i,
          created_by: attrs[:created_by],
          approved: attrs.fetch(:approved, false)
        )
        { success: true, spell: spell, errors: [] }
      end

      def self.edit_spell(id, fields)
        spell = find_spell(id)
        return { success: false, errors: [t('grimoire.spell_not_found', id: id)] } unless spell

        unless fields[:name].to_s.strip.empty?
          existing = Spell.find(branch_key: spell.branch_key, name: fields[:name]).to_a
          existing = existing.reject { |s| s.id == spell.id }
          unless existing.empty?
            return { success: false, spell: spell, errors: ["A spell with that name already exists in this branch"] }
          end
        end

        spell.update(
          name: fields[:name],
          description: fields[:description],
          minimum_skill: fields[:minimum_skill].to_i,
          difficulty: fields[:difficulty].to_i
        )
        { success: true, spell: spell, errors: [] }
      end

      def self.delete_spell(id)
        spell = find_spell(id)
        return { success: false, message: t('grimoire.spell_not_found', id: id) } unless spell
        # before_delete hook handles CharacterSpellLearned cleanup
        spell.delete
        { success: true }
      end

      # --- Proposals ---
      def self.create_proposal(char, attrs)
        category = Global.read_config('grimoire', 'jobs', 'spell_proposal_category') || Jobs.request_category
        title = t('grimoire.proposal_title', name: attrs[:name])
        body = t('grimoire.proposal_body',
          branch: Grimoire.branch_display_name(attrs[:branch_key]),
          name: attrs[:name],
          desc: attrs[:description],
          min: attrs[:minimum_skill],
          diff: attrs[:difficulty],
          submitter: char.name)
        result = Jobs.create_job(category, title, body, char)
        if result[:job]
          SpellProposal.create(
            job_id: result[:job].id,
            branch_key: attrs[:branch_key].to_s,
            name: attrs[:name],
            description: attrs[:description],
            minimum_skill: attrs[:minimum_skill].to_i,
            difficulty: attrs[:difficulty].to_i,
            proposed_by: char
          )
          result[:job]
        else
          nil
        end
      end

      def self.find_proposal(job_id)
        SpellProposal.find(job_id: job_id.to_i).first
      end

      def self.approve_proposal(enactor, job_id)
        job = begin; Job[job_id.to_i]; rescue; nil; end
        return { success: false, message: t('grimoire.job_not_found', id: job_id) } unless job

        proposal = find_proposal(job_id)
        return { success: false, message: t('grimoire.not_a_proposal', id: job_id) } unless proposal

        # Prevent duplicate: check if spell already exists
        existing = Spell.find(branch_key: proposal.branch_key, name: proposal.name).first
        if existing
          return { success: false, message: t('grimoire.spell_already_exists', name: proposal.name) }
        end

        result = create_spell(
          branch_key: proposal.branch_key,
          name: proposal.name,
          description: proposal.description,
          minimum_skill: proposal.minimum_skill,
          difficulty: proposal.difficulty,
          created_by: proposal.proposed_by,
          approved: true
        )

        unless result[:success]
          return { success: false, message: t('grimoire.spell_invalid', errors: result[:errors].join(', ')) }
        end

        # Close the job with an approval comment via the Jobs API
        comment = t('grimoire.approved_comment', name: proposal.name, staff: enactor.name)
        Jobs.close_job(enactor, job, comment)

        spell_name = proposal.name
        proposal.delete

        { success: true, message: t('grimoire.proposal_approved', name: spell_name, job: job_id) }
      end

      def self.reject_proposal(enactor, job_id, reason)
        job = begin; Job[job_id.to_i]; rescue; nil; end
        return { success: false, message: t('grimoire.job_not_found', id: job_id) } unless job

        proposal = find_proposal(job_id)
        return { success: false, message: t('grimoire.not_a_proposal', id: job_id) } unless proposal

        # Close the job with the rejection reason via the Jobs API
        comment = t('grimoire.rejected_comment', reason: reason, staff: enactor.name)
        Jobs.close_job(enactor, job, comment)

        proposal.delete

        { success: true, message: t('grimoire.proposal_rejected', job: job_id) }
      end

      # --- Parsing ---
      def self.parse_spell_creation_args(str)
        return nil if str.nil? || str.strip.empty?
        m = str.strip.match(/\A(?<branch>[^=]+)=(?<rest>.+)\z/m)
        return nil unless m
        parts = m[:rest].split('/', 4)
        return nil unless parts.length == 4
        {
          branch_key: m[:branch].strip,
          name: parts[0].strip,
          minimum_skill: parts[1].strip,
          difficulty: parts[2].strip,
          description: parts[3].strip
        }
      end

      def self.parse_spell_edit_args(str)
        return nil if str.nil? || str.strip.empty?
        m = str.strip.match(/\A(?<id>\d+)\s*=\s*(?<rest>.+)\z/m)
        return nil unless m
        parts = m[:rest].split('/', 4)
        return nil unless parts.length == 4
        {
          id: m[:id].strip,
          name: parts[0].strip,
          minimum_skill: parts[1].strip,
          difficulty: parts[2].strip,
          description: parts[3].strip
        }
      end

      # --- JSON for Web ---
      def self.spell_json(spell)
        {
          id: spell.id,
          name: spell.name,
          branch: Grimoire.branch_display_name(spell.branch_key),
          branch_key: spell.branch_key,
          description: spell.description,
          minimum_skill: spell.minimum_skill,
          difficulty: spell.difficulty,
          created_by: spell.created_by ? spell.created_by.name : nil
        }
      end
    end
  end
end

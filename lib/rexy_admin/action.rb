# frozen_string_literal: true

# rubocop:disable AbcSize
# rubocop:disable MethodLength
# rubocop:disable PerceivedComplexity
# rubocop:disable CyclomaticComplexity
# rubocop:disable ModuleLength
# rubocop:disable HandleExceptions, BlockLength
# rubocop:disable EvalWithLocation, Eval
# rubocop:disable ParameterLists
# rubocop:disable Style/Next
# rubocop:disable BlockNesting

module RexyAdmin
  module Action
    def parasite_show(id)
      find_by_id(id)
    end

    def parasite_toggle_active(id)
      record = find_by_id(id)
      record.active = !record.active
      return 'OK' if record.save

      'FAIL'
    end

    def parasite_delete(id)
      record = find_by_id(id)
      return 'OK' if record&.destroy

      'FAIL'
    end

    def parasite_create(params = {})
      new_record = new(params)
      return 'OK' if new_record.save

      new_record.errors
    end

    def parasite_update(id, params = {})
      record = find_by_id(id)
      return 'OK' if record.update_attributes(params)

      record.errors
    end
  end
end

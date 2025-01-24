class BasePathForStateValidator < ActiveModel::Validator
  def validate(record)
    return unless record.state && record.base_path

    check_conflict(record)
  end

private

  def check_conflict(record)
    conflict = Queries::BasePathForState.conflict(record.id, record.state, record.base_path)
    if conflict
      record.errors.add(:base, "base path=#{record.base_path} conflicts with content_id=#{conflict[:content_id]}")
    end
  end
end

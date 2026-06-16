# frozen_string_literal: true

require "test_helper"
require "rpms_sql/sql_safety"

class RpmsSql::SqlSafetyTest < Minitest::Test
  # -- read-shape queries are permitted -------------------------------------

  def test_select_is_read_only
    assert RpmsSql::SqlSafety.read_only?("SELECT 1")
  end

  def test_select_lowercase_is_read_only
    assert RpmsSql::SqlSafety.read_only?("select 1")
  end

  def test_with_cte_is_read_only
    assert RpmsSql::SqlSafety.read_only?("WITH x AS (SELECT 1) SELECT * FROM x")
  end

  def test_explain_is_read_only
    assert RpmsSql::SqlSafety.read_only?("EXPLAIN SELECT 1")
  end

  def test_values_is_read_only
    assert RpmsSql::SqlSafety.read_only?("VALUES (1, 2, 3)")
  end

  def test_leading_whitespace_is_handled
    assert RpmsSql::SqlSafety.read_only?("   \n\t SELECT 1")
  end

  def test_line_comment_before_select_is_handled
    assert RpmsSql::SqlSafety.read_only?("-- comment\nSELECT 1")
  end

  def test_block_comment_before_select_is_handled
    assert RpmsSql::SqlSafety.read_only?("/* comment */ SELECT 1")
  end

  # -- write-shape queries are rejected -------------------------------------

  WRITE_KEYWORDS = %w[INSERT UPDATE DELETE MERGE REPLACE TRUNCATE
                     CREATE DROP ALTER GRANT REVOKE CALL DO COPY].freeze

  WRITE_KEYWORDS.each do |kw|
    define_method "test_#{kw.downcase}_is_not_read_only" do
      refute RpmsSql::SqlSafety.read_only?("#{kw} something")
    end
  end

  def test_lowercase_write_is_rejected
    refute RpmsSql::SqlSafety.read_only?("insert into x values (1)")
  end

  def test_smuggled_write_after_select_is_rejected
    refute RpmsSql::SqlSafety.read_only?("SELECT 1; UPDATE x SET y = 1")
  end

  def test_empty_string_is_rejected
    refute RpmsSql::SqlSafety.read_only?("")
  end

  def test_nil_is_rejected
    refute RpmsSql::SqlSafety.read_only?(nil)
  end

  def test_trailing_semicolon_on_select_is_allowed
    assert RpmsSql::SqlSafety.read_only?("SELECT 1;")
  end

  # -- assert_read_only! raises on violation --------------------------------

  def test_assert_read_only_raises_on_write
    err = assert_raises(RpmsSql::Client::ReadOnlyViolation) do
      RpmsSql::SqlSafety.assert_read_only!("UPDATE foo SET bar = 1")
    end
    assert_match(/read-only/i, err.message)
  end

  def test_assert_read_only_does_not_raise_on_select
    RpmsSql::SqlSafety.assert_read_only!("SELECT 1")
  end
end

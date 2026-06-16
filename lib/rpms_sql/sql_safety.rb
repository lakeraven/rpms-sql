# frozen_string_literal: true

require_relative "client"

module RpmsSql
  # Hard rule: rpms-sql is read-only forever.
  #
  # Writes against IRIS-projected RPMS tables bypass FileMan business logic
  # (triggers, cross-references, input transforms, audit, MailMan
  # notifications, package-specific business rules). Going through the
  # broker RPC path (rpms-rpc) is the only safe way to mutate RPMS data.
  # See README "What rpms-sql does NOT do" section.
  #
  # This module enforces the rule by classifying SQL strings into read-shape
  # (allowed) or write-shape (rejected as ReadOnlyViolation) before they
  # reach the broker. Belt-and-braces defense: the IRIS user the gem
  # connects as should also have SELECT-only grants at the database level.
  module SqlSafety
    READ_KEYWORDS = %w[SELECT WITH EXPLAIN SHOW VALUES TABLE].freeze

    def self.read_only?(sql)
      stripped = strip_comments_and_whitespace(sql)
      return false if stripped.empty?
      return false if multiple_statements?(stripped)

      first_word = stripped.split(/\s+/).first.to_s.upcase
      READ_KEYWORDS.include?(first_word)
    end

    def self.assert_read_only!(sql)
      return if read_only?(sql)

      raise Client::ReadOnlyViolation,
            "rpms-sql is read-only by policy; refusing to execute: #{sql.to_s[0, 80]}"
    end

    def self.strip_comments_and_whitespace(sql)
      return "" if sql.nil?

      stripped = sql.to_s.gsub(%r{/\*.*?\*/}m, " ").gsub(/--[^\n]*/, "")
      stripped.strip
    end

    def self.multiple_statements?(stripped)
      parts = stripped.split(";").map(&:strip).reject(&:empty?)
      parts.size > 1
    end
  end
end

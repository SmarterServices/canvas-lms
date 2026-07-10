# frozen_string_literal: true

#
# Copyright (C) 2024 - present Instructure, Inc.
#
# This file is part of Canvas.
#
# Canvas is free software: you can redistribute it and/or modify it under
# the terms of the GNU Affero General Public License as published by the Free
# Software Foundation, version 3 of the License.
#
# Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
# details.
#
# You should have received a copy of the GNU Affero General Public License along
# with this program. If not, see <http://www.gnu.org/licenses/>.
#

describe GraphQLScopeMapper do
  let(:known_resources) { TokenScopes.named_scopes.pluck(:resource).uniq }

  # The REST collection path segment of a scope string, e.g.
  # "url:GET|/api/v1/courses/:course_id/quizzes" => "quizzes".
  def terminal_segment(scope)
    scope.split("|", 2).last.split("/").reject { |s| s.empty? || s.start_with?(":") }.last
  end

  # Source-of-truth selection mirroring the mapper, for match_array checks.
  def scopes_with_segment(segment, verb)
    TokenScopes.named_scopes.filter_map do |s|
      next unless s[:verb] == verb && s[:path]

      s[:scope] if s[:path].split("/").reject { |x| x.empty? || x.start_with?(":") }.last == segment
    end
  end

  describe ".segment_for_type" do
    it "pluralizes conventionally named types" do
      expect(described_class.segment_for_type("User")).to eq "users"
      expect(described_class.segment_for_type("AssignmentGroup")).to eq "assignment_groups"
    end

    it "applies SEGMENT_OVERRIDES where the name does not pluralize to the path" do
      expect(described_class.segment_for_type("Discussion")).to eq "discussion_topics"
    end

    it "returns nil for a blank type name" do
      expect(described_class.segment_for_type(nil)).to be_nil
      expect(described_class.segment_for_type("")).to be_nil
    end
  end

  describe ".scopes_for_type" do
    it "maps conventionally named types to their collection's GET scopes" do
      %w[User Course Section Account].each do |type|
        scopes = described_class.scopes_for_type(type)
        expect(scopes).not_to be_empty
        expect(scopes).to all(start_with("url:GET|"))
        expect(scopes.map { |s| terminal_segment(s) }.uniq).to eq [type.underscore.pluralize]
      end
    end

    it "maps multi-word types" do
      scopes = described_class.scopes_for_type("AssignmentGroup")
      expect(scopes).to match_array(scopes_with_segment("assignment_groups", "GET"))
      expect(scopes).not_to be_empty
    end

    it "maps types served by namespaced controllers via the URL path" do
      # Quiz/Module are served by namespaced controllers (quizzes/quizzes_api,
      # context_modules_api) that a controller-name match would miss; path-based
      # matching still finds them.
      expect(described_class.scopes_for_type("Quiz"))
        .to include("url:GET|/api/v1/courses/:course_id/quizzes")
      expect(described_class.scopes_for_type("Module")).not_to be_empty
    end

    it "applies SEGMENT_OVERRIDES for types that do not pluralize to their path" do
      scopes = described_class.scopes_for_type("Discussion")
      expect(scopes).not_to be_empty
      expect(scopes).to match_array(scopes_with_segment("discussion_topics", "GET"))
    end

    it "returns exactly the scopes whose collection matches, and nothing else" do
      scopes = described_class.scopes_for_type("User")
      expect(scopes).to match_array(scopes_with_segment("users", "GET"))
    end

    it "does not leak scopes across unrelated types (fail-closed / solid)" do
      user = described_class.scopes_for_type("User")
      course = described_class.scopes_for_type("Course")
      account = described_class.scopes_for_type("Account")
      expect(user & course).to be_empty
      expect(user & account).to be_empty
      expect(course & account).to be_empty
    end

    it "honors the requested verb" do
      get_scopes = described_class.scopes_for_type("User", verb: "GET")
      post_scopes = described_class.scopes_for_type("User", verb: "POST")
      expect(get_scopes).to match_array(scopes_with_segment("users", "GET"))
      expect(post_scopes).to match_array(scopes_with_segment("users", "POST"))
      expect(get_scopes).not_to match_array(post_scopes)
    end

    it "returns an empty array for an unmapped type (deny-by-default)" do
      expect(described_class.scopes_for_type("CoursePermissions")).to eq []
      expect(described_class.scopes_for_type("NotARealType")).to eq []
    end

    it "returns an empty array for a blank type name" do
      expect(described_class.scopes_for_type(nil)).to eq []
      expect(described_class.scopes_for_type("")).to eq []
    end
  end

  describe ".resources_for_type" do
    it "returns the REST resources backing a mapped type" do
      resources = described_class.resources_for_type("User")
      expect(resources).not_to be_empty
      expect(resources).to include(:users)
    end

    it "only ever reports resources that actually exist in TokenScopes" do
      %w[User Course Section Account AssignmentGroup Discussion Quiz Module].each do |type|
        described_class.resources_for_type(type).each do |resource|
          expect(known_resources).to include(resource)
        end
      end
    end

    it "returns an empty array for unmapped or blank type names" do
      expect(described_class.resources_for_type("NotARealType")).to eq []
      expect(described_class.resources_for_type(nil)).to eq []
    end
  end
end

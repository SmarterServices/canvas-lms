# frozen_string_literal: true

#
# Copyright (C) 2019 Instructure, Inc.
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

require_relative "graphql_spec_helper"

describe "GraphQL Token Scoping" do
  before(:once) do
    teacher_in_course(active_all: true)
  end

  let(:users_get_scopes) { GraphQLScopeMapper.scopes_for_type("User", verb: "GET") }
  let(:courses_get_scopes) { GraphQLScopeMapper.scopes_for_type("Course", verb: "GET") }
  let(:sections_get_scopes) { GraphQLScopeMapper.scopes_for_type("Section", verb: "GET") }
  let(:users_scope) { users_get_scopes.first }
  let(:courses_scope) { courses_get_scopes.first }
  let(:sections_scope) { sections_get_scopes.first }

  let(:scoped_developer_key) do
    DeveloperKey.create!(
      require_scopes: true,
      name: "Test Scoped Developer Key",
      scopes: users_get_scopes | courses_get_scopes | sections_get_scopes
    )
  end
  let(:unscoped_developer_key) { DeveloperKey.create!(name: "Test Unscoped Developer Key") }
  let(:course_type) { GraphQLTypeTester.new(@course, current_user: @teacher) }
  let(:user_type) { GraphQLTypeTester.new(@teacher, current_user: @teacher) }
  let(:section_type) { GraphQLTypeTester.new(@course.default_section, current_user: @teacher) }

  it "does not affect requests with an unscoped developer key" do
    token = AccessToken.create!(developer_key: unscoped_developer_key)
    expect(
      course_type.resolve("_id", access_token: token)
    ).to eq @course.id.to_s
  end

  it "does not allow queries with a scoped developer key that lacks the required scope" do
    token = AccessToken.create!(developer_key: scoped_developer_key)
    expect do
      course_type.resolve("_id", access_token: token)
    end.to raise_error(/insufficient scopes/)
  end

  it "allows a mapped type when the token holds the mapped read scope" do
    token = AccessToken.create!(developer_key: scoped_developer_key, scopes: [users_scope])
    expect(
      user_type.resolve("_id", access_token: token)
    ).to eq @teacher.id.to_s
  end

  it "allows an auto-derived type when the token holds its read scope" do
    token = AccessToken.create!(developer_key: scoped_developer_key, scopes: [sections_scope])
    expect(
      section_type.resolve("_id", access_token: token)
    ).to eq @course.default_section.id.to_s
  end

  it "does not allow a mapped type when the token holds only a different resource's scope" do
    token = AccessToken.create!(developer_key: scoped_developer_key, scopes: [courses_scope])
    expect do
      user_type.resolve("_id", access_token: token)
    end.to raise_error(/insufficient scopes/)
  end

  it "denies a type that maps to no known resource, even with a valid scope (deny-by-default)" do
    # Build the key/token from the real mapping first, then force the type to
    # map to nothing so we exercise the fail-closed branch directly.
    token = AccessToken.create!(developer_key: scoped_developer_key, scopes: [users_scope])
    allow(GraphQLScopeMapper).to receive(:scopes_for_type).and_call_original
    allow(GraphQLScopeMapper).to receive(:scopes_for_type).with("User", verb: "GET").and_return([])
    expect do
      user_type.resolve("_id", access_token: token)
    end.to raise_error(/insufficient scopes/)
  end

  it "does not allow mutations with a scoped developer key" do
    token = AccessToken.create!(developer_key: scoped_developer_key)
    result = CanvasSchema.execute(<<~GQL, context: { current_user: @teacher, access_token: token })
      mutation {
        createAssignment(input: {courseId: "#{@course.id}", name: "asdf"}) {
          assignment { id }
        }
      }
    GQL
    expect(result.dig("errors", 0, "message")).to match(/insufficient scopes/)
    expect(result.dig("data", "createAssignment")).to be_nil
  end
end

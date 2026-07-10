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

# Maps GraphQL object type names (their +graphql_name+, e.g. "User", "Course")
# to the REST API "resource" that grants access to the equivalent data.
#
# The resource symbols correspond to the +:resource+ values produced by
# +TokenScopes.named_scopes+, which come from
# +ApiScopeMapper.lookup_resource(controller, action)+ -- i.e. the REST
# controller name (see +lib/base/api_scope_mapper_fallback.rb+). Using
# +TokenScopes.named_scopes+ as the source of truth lets us translate a mapped
# type into the concrete scope strings (e.g. "url:GET|/api/v1/users") a token
# would need to hold in order to read that resource over REST.
#
# Coverage is intentionally partial: only commonly used types are mapped. Any
# type that is not mapped is treated as forbidden by the caller
# (+AuthenticationMethods.graphql_type_authorized?+), i.e. enforcement fails
# closed / deny-by-default.
module GraphQLScopeMapper
  # GraphQL type name => REST resource symbol(s).
  TYPE_TO_RESOURCE = {
    "User" => :users,
    "Course" => :courses,
    "Enrollment" => :enrollments,
    "Account" => :accounts,
    "Assignment" => :assignments,
    "Submission" => :submissions,
    "Section" => :sections,
  }.freeze

  # Returns the REST resource symbol(s) mapped to the given GraphQL type name,
  # or an empty array when the type is not mapped.
  def self.resources_for_type(type_name)
    Array(TYPE_TO_RESOURCE[type_name])
  end

  # Returns the concrete REST scope strings (e.g. "url:GET|/api/v1/users") that
  # grant access to the resource(s) mapped to +type_name+ for the given HTTP
  # +verb+. Returns an empty array when the type is not mapped or no matching
  # scope exists.
  def self.scopes_for_type(type_name, verb: "GET")
    resources = resources_for_type(type_name)
    return [] if resources.empty?

    TokenScopes.named_scopes.filter_map do |scope|
      scope[:scope] if resources.include?(scope[:resource]) && scope[:verb] == verb
    end
  end
end

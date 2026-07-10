# frozen_string_literal: true

namespace :graphql do
  desc "Dump GraphQL schema and fragment types"
  task schema: :environment do
    Rails.root.join("schema.graphql").write(CanvasSchema.to_definition)

    possible_types_map = CanvasSchema.possible_types.select { |k, _| k.kind.abstract? }
                                                    .transform_keys(&:graphql_name)
                                                    .transform_values { |x| x.map(&:graphql_name).sort }
                                                    .sort_by { |k, _| k }.to_h

    Rails.root.join("ui/shared/apollo-v3/possibleTypes.json").write(JSON.pretty_generate(possible_types_map))
  end

  desc "Generate the GraphQL type => REST scope authorization reference doc"
  task scopes: :environment do
    object_types = CanvasSchema.types.values.select do |type|
      type.is_a?(Class) && type < Types::ApplicationObjectType
    end.sort_by(&:graphql_name)

    mapped = object_types.filter_map do |type|
      scopes = GraphQLScopeMapper.scopes_for_type(type.graphql_name, verb: "GET")
      [type.graphql_name, scopes.sort] unless scopes.empty?
    end
    unmapped = object_types.map(&:graphql_name) - mapped.map(&:first)

    lines = []
    lines << "GraphQL Type Scope Authorization"
    lines << "================================"
    lines << ""
    lines << "<!-- GENERATED FILE: do not edit by hand."
    lines << "     Regenerate with `bundle exec rake graphql:scopes`. -->"
    lines << ""
    lines << "When a developer key has `require_scopes` enabled, each GraphQL object"
    lines << "type is authorized against the REST API scopes below (see"
    lines << "[GraphQL API](graphql.html) for the rules). A token must hold at least one"
    lines << "of the listed `GET` scopes to read the type. Types not listed here map to"
    lines << "no scope and are denied (deny-by-default)."
    lines << ""
    lines << "This mapping is derived dynamically from `TokenScopes.named_scopes`, so it"
    lines << "reflects the routes present when it was generated."
    lines << ""
    lines << "## Authorized types"
    lines << ""
    mapped.each do |name, scopes|
      lines << "### #{name}"
      lines << ""
      scopes.each { |scope| lines << "- `#{scope}`" }
      lines << ""
    end
    lines << "## Types with no scope mapping (denied under require_scopes)"
    lines << ""
    lines << unmapped.map { |name| "`#{name}`" }.join(", ")
    lines << ""

    output = Rails.root.join("doc/api/graphql_type_scopes.md")
    output.write("#{lines.join("\n")}\n")
    puts "Wrote #{mapped.size} mapped types (#{unmapped.size} unmapped) to #{output}"
  end
end

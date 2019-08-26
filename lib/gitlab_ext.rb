

module Patches
  # Defines methods related to projects.
  # @see https://docs.gitlab.com/ce/api/projects.html
  module Projects

    # Gets a list of project users.
    #
    # @example
    #   Gitlab.project_usesrs(42)
    #   Gitlab.project_usesrs('gitlab')
    #
    # @param  [Integer, String] project The ID or path of a project.
    # @param  [Hash] options A customizable set of options.
    # @option options [Integer] :page The page number.
    # @option options [Integer] :per_page The number of results per page.
    # @return [Array<Gitlab::ObjectifiedHash>]
    def project_usesrs(project, options = {})
      get("/projects/#{url_encode project}/users", query: options)
    end
  end
end


Gitlab::Client.prepend(Patches::Projects)

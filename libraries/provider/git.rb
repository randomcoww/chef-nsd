class Chef
  class Provider
    class Git < Chef::Provider

      def git_reset
        git("reset", "--hard", target_revision, cwd: cwd)
      end
    end
  end
end

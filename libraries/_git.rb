class Chef
  class Provider
    class Git < Chef::Provider

      def git_reset
        git("reset", "--hard", target_revision, cwd: cwd)
      end

      def git_diff(rev1, rev2)
        git("diff", "--name-only", rev1, rev2, cwd: cwd).stdout
      end
    end
  end
end

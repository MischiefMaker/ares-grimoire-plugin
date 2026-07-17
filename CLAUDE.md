# Claude Code Project Instructions

## Git Workflow Requirement

After completing any code, documentation, configuration, or repository changes, **always commit the changes and push them to the configured GitHub remote** unless explicitly told not to.

**Do not leave completed work only in the local checkout.**

### Workflow for Every Task

Before finishing any task, follow these steps:

1. **Check status**: Run `git status`
2. **Review changes**: Look at the changed files to ensure they're appropriate
3. **Create commit**: Write an appropriate commit message describing the changes
4. **Commit locally**: `git commit -m "message"`
5. **Push to remote**: Push to the current branch
6. **Report**: Report the commit hash and push status

### Error Handling

- If push fails, clearly report the reason and the error message
- Do not claim the task is complete if push was unsuccessful
- Investigate and fix the cause before considering work done

### Example Flow

```bash
$ git status
On branch main
Changes not staged for commit:
  modified:   plugin/services/grimoire_service.rb
  new file:   plugin/web/new_handler.rb

$ git add -A
$ git commit -m "Fix spell validation in service layer"
[main a1b2c3d] Fix spell validation in service layer
 2 files changed, 15 insertions(+), 3 deletions(-)

$ git push origin main
Counting objects: 3, done.
Total 3 (delta 2), reused 0 (delta 0)
To github.com:user/ares-grimoire-plugin.git
   a1b2c3d..1e2f3g4 main -> main

✓ Pushed commit a1b2c3d to origin/main
```

### Why This Matters

- **Source of truth in GitHub**: The repository is authoritative, not the local checkout
- **Collaboration**: Other contributors see completed work immediately
- **Safety**: Remote backups prevent data loss
- **Clear status**: Everyone knows what's been done and committed
- **Auditability**: Git history shows what changed and when

### Exceptions

Push directly only when explicitly told not to. Otherwise, always push after committing.

---

**Permanent instruction for all Claude Code sessions on this repository.**

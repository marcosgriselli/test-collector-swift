import Foundation

extension EnvironmentValues {
  func runEnvironment(defaultKey: String = UUID().uuidString) -> RunEnvironment {
    let ciEnv = self.buildKite
      ?? self.gitHubActions
      ?? self.circleCi
      ?? self.xcodeCloud
      ?? self.generic(key: defaultKey)

    return RunEnvironment(
      ci: ciEnv?.ci,
      key: self.analyticsKey ?? ciEnv?.key ?? defaultKey,
      url: self.analyticsUrl ?? ciEnv?.url,
      branch: self.analyticsBranch ?? ciEnv?.branch,
      commitSha: self.analyticsSha ?? ciEnv?.commitSha,
      number: self.analyticsNumber ?? ciEnv?.number,
      jobId: self.analyticsJobId ?? ciEnv?.jobId,
      message: self.analyticsMessage ?? ciEnv?.message,
      debug: self.isAnalyticsDebugEnabled ? "true" : nil,
      version: TestCollector.version,
      collector: TestCollector.name
    )
  }

  private var buildKite: RunEnvironment? {
    guard let buildId = self.buildkiteBuildId else { return nil }

    logger?.debug("Successfully found Buildkite RunEnvironment")

    return RunEnvironment(
      ci: "buildkite",
      key: buildId,
      url: self.buildkiteBuildUrl,
      branch: self.buildkiteBranch,
      commitSha: self.buildkiteCommit,
      number: self.buildkiteBuildNumber,
      jobId: self.buildkiteJobId,
      message: self.buildkiteMessage
    )
  }

  private var circleCi: RunEnvironment? {
    guard
      let buildNumber = self.circleBuildNumber,
      let workFlowId = self.circleWorkflowId
    else { return nil }

    logger?.debug("Successfully found Circle CI RunEnvironment")

    return RunEnvironment(
      ci: "circleci",
      key: "\(workFlowId)-\(buildNumber)",
      url: self.circleBuildUrl,
      branch: self.circleBranch,
      commitSha: self.circleSha,
      number: buildNumber,
      message: "Build #\(buildNumber) on branch \(self.circleBranch ?? "[Unknown branch]")"
    )
  }

  private func generic(key: String) -> RunEnvironment? {
    guard self.ci != nil else { return nil }

    logger?.debug("Falling back to generic RunEnvironment")

    return RunEnvironment(
      ci: "generic",
      key: key
    )
  }

  private var gitHubActions: RunEnvironment? {
    guard
      let runNumber = self.gitHubRunNumber,
      let action = self.gitHubAction,
      let runAttempt = self.gitHubRunAttempt,
      let workflowName = self.githubWorkflowName,
      let startedBy = self.githubWorkflowStartedBy
    else { return nil }

    logger?.debug("Successfully found Github RunEnvironment")

    var url: String?
    if let repository = self.gitHubRepository, let runId = self.gitHubRunId {
      url = "https://github.com/\(repository)/actions/runs/\(runId)"
    }
    let message = "Run #\(runNumber) attempt #\(runAttempt) of \(workflowName), started by \(startedBy)"

    return RunEnvironment(
      ci: "github_actions",
      key: "\(action)-\(runNumber)-\(runAttempt)",
      url: url,
      branch: self.gitHubRef,
      commitSha: self.gitHubSha,
      number: runNumber,
      message: message
    )
  }

  private var xcodeCloud: RunEnvironment? {
    guard
      let commitHash = self.xcodeCommitSha,
      let buildNumber = self.xcodeBuildNumber,
      let buildID = self.xcodeBuildID,
      let workflowName = self.xcodeWorkflowName
    else { return nil }

    logger?.debug("Successfully found Xcode Cloud RunEnvironment")

    let message = "Build #\(buildNumber) of workflow: \(workflowName)"

    return RunEnvironment(
      ci: "xcodeCloud",
      key: buildID,
      url: xcodePullRequestURL,
      branch: xcodeBranch,
      commitSha: commitHash,
      number: buildNumber,
      message: message
    )
  }
}

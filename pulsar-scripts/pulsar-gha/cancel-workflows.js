const { Octokit } = require("@octokit/rest");
var fs = require('fs');

const octokit = new Octokit({ auth: "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" });


const owner = "apache"
const repo = "pulsar"

function rerunIfPending(run) {
    if (run.status === "in_progress" && run.conclusion === "failure") {
        octokit.rest.actions.reRunWorkflowFailedJobs({
            owner,
            repo,
            run_id: run.id,
          });
          console.log("triggered re-run for", run.id, "https://github.com/apache/pulsar/actions/runs/"+run.id)
    }
    
}

function cancelIfInStatus(run, statuses) {
    if (statuses.includes(run.status)) {
        octokit.rest.actions.cancelWorkflowRun({
            owner,
            repo,
            run_id: run.id,
          });
        console.log("cancelled run for", run.id, "https://github.com/apache/pulsar/actions/runs/"+run.id)
    }
    
}

async function downloadRuns(status) {
    let runs
    let page = 0
    const maxPage = 5
    let all = []
    do {
        const data = await octokit.rest.actions.listWorkflowRunsForRepo({
            owner,
            repo,
            per_page: 100,
            status: status,
            page:page++
        });
        
        console.log("download page #", page)
        runs = data.data.workflow_runs
        for (let r of runs) {
            cancelIfInStatus(r, [status])
        }
        if (page === maxPage) {
            break
        }
        
    } while (runs.length !== 0)
    return all
}
downloadRuns("queued")
import ballerina/http;
import ballerina/log;
import ballerina/time;

configurable int port = 9090;
configurable decimal requestTimeoutSeconds = 5.0;
configurable string githubStatusUrl = "https://www.githubstatus.com";
configurable string cloudflareStatusUrl = "https://www.cloudflarestatus.com";
configurable string npmStatusUrl = "https://status.npmjs.org";

final http:Client githubClient = check new (githubStatusUrl, {timeout: requestTimeoutSeconds});
final http:Client cloudflareClient = check new (cloudflareStatusUrl, {timeout: requestTimeoutSeconds});
final http:Client npmClient = check new (npmStatusUrl, {timeout: requestTimeoutSeconds});

// convert api status text to our status type
isolated function mapIndicator(string indicator) returns ServiceStatus {
    match indicator.toLowerAscii() {
        "minor" => {
            return "DEGRADED";
        }
        "major"|"critical" => {
            return "OUTAGE";
        }
        _ => {
            return "OPERATIONAL";
        }
    }
}

// call api and measure response time in ms
isolated function fetchStatus(http:Client clientEp, string serviceName) returns ServiceHealth {
    time:Utc tStart = time:utcNow();
    StatusPagePayload|error res = clientEp->get("/api/v2/status.json");
    time:Utc tEnd = time:utcNow();
    decimal latency = <decimal>(time:utcDiffSeconds(tEnd, tStart) * 1000.0);

    if res is error {
        log:printWarn(string `probe failed for ${serviceName}`, 'error = res);
        return {
            name: serviceName,
            status: "UNREACHABLE",
            details: "connection error or timeout",
            responseTimeMs: latency
        };
    }

    return {
        name: serviceName,
        status: mapIndicator(res.status.indicator),
        details: res.status.description,
        responseTimeMs: latency
    };
}

service /health on new http:Listener(port) {

    resource function get ping() returns json {
        return {status: "ok", timestamp: time:utcToString(time:utcNow())};
    }

    resource function get overview() returns SystemOverview {
        // check all 3 services at the same time
        worker wGithub returns ServiceHealth {
            return fetchStatus(githubClient, "GitHub");
        }
        worker wCloudflare returns ServiceHealth {
            return fetchStatus(cloudflareClient, "Cloudflare");
        }
        worker wNpm returns ServiceHealth {
            return fetchStatus(npmClient, "npm Registry");
        }

        // wait for all checks to finish
        ServiceHealth gh = wait wGithub;
        ServiceHealth cf = wait wCloudflare;
        ServiceHealth npm = wait wNpm;

        ServiceHealth[] checks = [gh, cf, npm];

        int healthy = 0;
        foreach ServiceHealth s in checks {
            if s.status == "OPERATIONAL" {
                healthy += 1;
            }
        }

        // if any service is down, mark as partial outage
        SystemStatus overall = "ALL_OPERATIONAL";
        if healthy == 0 {
            overall = "MAJOR_OUTAGE";
        } else if healthy < checks.length() {
            overall = "PARTIAL_OUTAGE";
        }

        return {
            overallStatus: overall,
            totalMonitored: checks.length(),
            healthyCount: healthy,
            timestamp: time:utcToString(time:utcNow()),
            services: checks
        };
    }
}
